//
//  LOTWROMData.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/5/25.
//

import Foundation
import SwiftUI

class LOTWROMData: ObservableObject {
    @Published var rom: ROMFile?
    @Published var rooms: [Room] = []
    @Published var chrTiles: [CHRTile] = []
    @Published var metatiles: [Metatile] = []
    @Published var isLoaded = false
    @Published var fileName: String = ""
    @Published var fileURL: URL?
    @Published var undoManager = ROMUndoManager()
    @Published var hasUnsavedChanges = false
    
    // CHR cache for room-specific tiles with palette offsets
    private var chrCache: [CHRTile] = []
    
    private let roomSize = 1024
    private let roomCount = 128
    private let headerSize = 16
    
    func loadROM(from url: URL) throws {
        let romFile = ROMFile()
        try romFile.loadROM(from: url)
        self.rom = romFile
        self.fileName = url.lastPathComponent
        self.fileURL = url
        
        // Load all rooms from banks 0-8
        loadRooms()
        
        // Load CHR tiles
        loadCHRTiles()
        
        // Load metatiles from bank 9
        loadMetatiles()
        
        // Debug: Print some info about what we loaded
        print("ROM loaded: \(fileName)")
        print("Rooms: \(rooms.count)")
        print("CHR tiles: \(chrTiles.count)")
        print("Metatiles: \(metatiles.count)")
        if !rooms.isEmpty {
            let room0 = rooms[0]
            print("Room 0 - metatilePage: \(room0.metatilePage), chrPages: \(room0.chrPages)")
            
            // Debug first few metatiles
            for i in 0..<4 {
                if let metatile = getMetatile(for: room0, index: i) {
                    print("Metatile \(i): CHR tiles \(metatile.tiles)")
                }
            }
            
            // Debug first terrain byte
            let firstTile = room0.getTile(x: 0, y: 0)
            let palette = (firstTile >> 6) & 0x03
            let metatileIdx = firstTile & 0x3F
            print("First terrain byte: 0x\(String(format: "%02X", firstTile)) -> palette=\(palette), metatile=\(metatileIdx)")
        }
        
        isLoaded = true
    }
    
    private func loadRooms() {
        guard let rom = rom else { return }
        
        rooms.removeAll()
        
        // Rooms are stored in banks 0-8
        // Each bank is 8KB (8192 bytes) and contains 8 rooms (1024 bytes each)
        // Total: 9 banks * 8 rooms = 72 rooms (but LOTW has 128 rooms)
        // Actually, checking the research: first 9 banks contain level maps
        
        for roomId in 0..<roomCount {
            // Calculate which bank and offset within that bank
            let bank = roomId / 8  // 8 rooms per bank
            let roomInBank = roomId % 8
            
            // Calculate absolute offset in ROM
            // Banks start after header + PRG banks
            let bankOffset = headerSize + (bank * 8192)
            let roomOffset = bankOffset + (roomInBank * roomSize)
            
            if let roomData = rom.readBytes(from: roomOffset, count: roomSize) {
                rooms.append(Room(id: roomId, data: roomData))
            } else {
                // If we can't read the room, add an empty one
                rooms.append(Room(id: roomId, data: []))
            }
        }
    }
    
    private func loadCHRTiles() {
        guard let rom = rom else { return }
        
        chrTiles.removeAll()
        
        // CHR ROM starts after header + PRG ROM
        let chrStart = headerSize + rom.prgRomSize
        
        // Load all CHR banks (LOTW uses 8 CHR banks)
        // Each CHR bank is 8KB (512 tiles * 16 bytes per tile)
        let banksToLoad = min(8, rom.chrRomSize / 8192)  // Load up to 8 banks
        let tilesPerBank = 512  // FIXED: Was 256, should be 512
        let bytesPerTile = 16
        
        for bank in 0..<banksToLoad {
            for tileIndex in 0..<tilesPerBank {
                let tileOffset = chrStart + (bank * 8192) + (tileIndex * bytesPerTile)
                if let tileData = rom.readBytes(from: tileOffset, count: bytesPerTile) {
                    chrTiles.append(CHRTile(data: tileData))
                } else {
                    chrTiles.append(CHRTile())
                }
            }
        }
    }
    
    // Build CHR cache for a specific room with palette offsets
    func buildCHRCacheForRoom(_ room: Room) {
        // Clear the cache and prepare for 2048 tiles (512 tiles per palette * 4 palettes)
        chrCache = Array(repeating: CHRTile(), count: 2048)
        
        // Get the CHR pages for this room
        let chrPage0 = Int(room.chrPages[0] & 0xFE)  // Even page (& ~1)
        let chrPage1 = Int(room.chrPages[1] & 0xFE)  // Even page (& ~1)
        
        // Map CHR pages - LOTW uses specific CHR page layout:
        // Slots 0-1: Room CHR page 0 (even and odd)
        // Slots 2-3: Room CHR page 1 (even and odd)
        // Slots 4-7: Fixed pages for enemies/items
        let chrPageSlots = [
            chrPage0,                    // Slot 0: Room CHR page 0 (even)
            chrPage0 + 1,                // Slot 1: Room CHR page 0 (odd)
            chrPage1,                    // Slot 2: Room CHR page 1 (even)
            chrPage1 + 1,                // Slot 3: Room CHR page 1 (odd)
            0x3A,                        // Slot 4: Fixed Roas page
            Int(room.enemyCHRPage),      // Slot 5: Enemy CHR page from room data
            0x3E,                        // Slot 6: Fixed items page 0
            0x3F                         // Slot 7: Fixed items page 1
        ]
        
        // Build cache with palette offsets
        // Each palette gets a 512-tile section in the cache
        // Within each palette section, tiles are arranged by slots (8 slots * 64 tiles = 512)
        for palette in 0..<4 {
            for slot in 0..<8 {
                let chrPageIndex = chrPageSlots[slot]
                let tilesPerPage = 64
                
                // Copy tiles from the CHR ROM page to the cache slot
                for tileInPage in 0..<tilesPerPage {
                    // Source: CHR ROM tile from the appropriate page
                    let sourceTileIndex = (chrPageIndex * tilesPerPage) + tileInPage
                    // Destination: slot position in cache + palette offset
                    let destTileIndex = (slot * tilesPerPage) + tileInPage + (palette * 512)
                    
                    if sourceTileIndex < chrTiles.count {
                        chrCache[destTileIndex] = chrTiles[sourceTileIndex]
                    }
                }
            }
        }
    }
    
    // Get a CHR tile from the cache with palette offset
    func getCachedCHRTile(tileId: Int, paletteIndex: Int) -> CHRTile? {
        let cacheIndex = tileId + (paletteIndex * 512)
        guard cacheIndex >= 0 && cacheIndex < chrCache.count else {
            return nil
        }
        return chrCache[cacheIndex]
    }
    
    private func loadMetatiles() {
        guard let rom = rom else { return }
        
        metatiles.removeAll()
        
        // LOTW stores metatile sets in bank 9
        // Bank 9 starts at: header + (9 banks * 8192 bytes/bank)
        let baseOffset = headerSize + (9 * 8192)  // This equals 73744
        
        // Load all possible metatile pages
        // Each page is 256 bytes (64 metatiles * 4 bytes each)
        // We'll load up to 16 pages to be safe
        let pagesCount = 16
        let metatileCount = 64
        let bytesPerMetatile = 4
        
        for pageIndex in 0..<pagesCount {
            for metatileIndex in 0..<metatileCount {
                let offset = baseOffset + (pageIndex * 256) + (metatileIndex * bytesPerMetatile)
                if let metatileData = rom.readBytes(from: offset, count: bytesPerMetatile) {
                    metatiles.append(Metatile(tiles: metatileData))
                } else {
                    metatiles.append(Metatile())
                }
            }
        }
    }
    
    func getMetatile(for room: Room, index: Int) -> Metatile? {
        // Each room uses a specific metatile page
        // Each page has 64 metatiles
        let pageOffset = Int(room.metatilePage) * 64
        let metatileIndex = pageOffset + (index & 0x3F)
        
        guard metatileIndex < metatiles.count else { return nil }
        return metatiles[metatileIndex]
    }
    
    func saveROM(to url: URL) throws {
        guard let rom = rom else {
            throw ROMError.noDataToSave
        }
        
        // Write room data back to ROM
        for room in rooms {
            saveRoom(room)
        }
        
        // Save the ROM file
        try rom.saveROM(to: url)
    }
    
    private func saveRoom(_ room: Room) {
        guard let rom = rom else { return }
        
        // Calculate room offset
        let bank = room.id / 8
        let roomInBank = room.id % 8
        let bankOffset = headerSize + (bank * 8192)
        let roomOffset = bankOffset + (roomInBank * roomSize)
        
        // Build room data
        var roomData: [UInt8] = []
        
        // Add terrain data (768 bytes)
        roomData.append(contentsOf: room.terrain)
        
        // Add padding to reach metadata offset
        while roomData.count < 0x300 {
            roomData.append(0)
        }
        
        // Add room metadata
        roomData.append(room.metatilePage)           // 0x300
        roomData.append(room.enemyCHRPage)          // 0x301
        roomData.append(UInt8(room.secretTiles & 0xFF))       // 0x302
        roomData.append(UInt8(room.secretTiles >> 8))         // 0x303
        roomData.append(0)                          // 0x304 (padding)
        roomData.append(contentsOf: room.chrPages)  // 0x305-306
        roomData.append(contentsOf: room.treasureChests) // 0x307-30A
        roomData.append(room.musicTrack)            // 0x30B
        roomData.append(contentsOf: room.teleportCoords) // 0x30C-30F
        roomData.append(contentsOf: room.shopData)  // 0x310-313
        roomData.append(room.characterFlags)        // 0x314
        
        // Add padding to reach enemy data offset
        while roomData.count < 0x320 {
            roomData.append(0)
        }
        
        // Add enemy data (9 enemies, 16 bytes each)
        for enemy in room.enemies {
            roomData.append(enemy.spriteIndex)
            roomData.append(enemy.drawAttribute)
            roomData.append(enemy.posX)
            roomData.append(enemy.posY)
            roomData.append(enemy.hitPoints)
            roomData.append(enemy.damage)
            roomData.append(enemy.deathSprite)
            roomData.append(enemy.animationStyle)
            roomData.append(enemy.behaviorType)
            roomData.append(enemy.speed)
            roomData.append(contentsOf: enemy.additionalData)
        }
        
        // Add padding to reach palette data offset
        while roomData.count < 0x3E0 {
            roomData.append(0)
        }
        
        // Add palette data (8 palettes, 4 colors each)
        for palette in room.palettes {
            roomData.append(contentsOf: palette.colors)
        }
        
        // Pad to full room size
        while roomData.count < roomSize {
            roomData.append(0)
        }
        
        // Write back to ROM
        rom.writeBytes(at: roomOffset, values: Array(roomData.prefix(roomSize)))
    }
    
    // MARK: - Tile Editing
    
    /// Set a tile in a room with undo support
    func setRoomTile(roomId: Int, x: Int, y: Int, tileValue: UInt8) {
        guard roomId >= 0 && roomId < rooms.count,
              x >= 0 && x < 64 && y >= 0 && y < 12,
              let rom = rom else { return }
        
        // Update in-memory room data
        let index = x * 12 + y  // Column-major indexing
        let oldValue = rooms[roomId].terrain[index]
        
        if oldValue == tileValue { return } // No change needed
        
        rooms[roomId].terrain[index] = tileValue
        
        // Calculate ROM offset for this tile
        let roomOffset = headerSize + (roomSize * roomId)
        let tileOffset = roomOffset + index
        
        // Record change for undo and write to ROM
        undoManager.beginGrouping(description: "Edit Tile")
        rom.writeByteWithUndo(tileValue, at: tileOffset, undoManager: undoManager, description: "Tile at (\(x), \(y))")
        undoManager.endGrouping()
        
        hasUnsavedChanges = true
        objectWillChange.send()
    }
    
    /// Set multiple tiles with undo support (for painting/filling)
    func setRoomTiles(roomId: Int, tiles: [(x: Int, y: Int, value: UInt8)]) {
        guard roomId >= 0 && roomId < rooms.count,
              let rom = rom else { return }
        
        undoManager.beginGrouping(description: "Edit Multiple Tiles")
        
        for tile in tiles {
            guard tile.x >= 0 && tile.x < 64 && tile.y >= 0 && tile.y < 12 else { continue }
            
            let index = tile.x * 12 + tile.y
            let oldValue = rooms[roomId].terrain[index]
            
            if oldValue != tile.value {
                rooms[roomId].terrain[index] = tile.value
                
                let roomOffset = headerSize + (roomSize * roomId)
                let tileOffset = roomOffset + index
                
                rom.writeByteWithUndo(tile.value, at: tileOffset, undoManager: undoManager)
            }
        }
        
        undoManager.endGrouping()
        hasUnsavedChanges = true
        objectWillChange.send()
    }
    
    /// Perform undo operation
    func undo() {
        guard let rom = rom else { return }
        
        if undoManager.undo(applyTo: rom) {
            // Reload affected room data from ROM
            reloadRoomsFromROM()
            objectWillChange.send()
        }
    }
    
    /// Perform redo operation
    func redo() {
        guard let rom = rom else { return }
        
        if undoManager.redo(applyTo: rom) {
            // Reload affected room data from ROM
            reloadRoomsFromROM()
            objectWillChange.send()
        }
    }
    
    /// Reload room data from ROM after undo/redo
    private func reloadRoomsFromROM() {
        guard let rom = rom else { return }
        
        rooms.removeAll()
        for roomId in 0..<roomCount {
            let offset = headerSize + (roomSize * roomId)
            if let roomData = rom.readBytes(from: offset, count: roomSize) {
                rooms.append(Room(id: roomId, data: roomData))
            }
        }
    }
    
    /// Save ROM with current changes
    func saveROM(to url: URL? = nil) throws {
        guard let rom = rom else { throw LOTWROMError.notLoaded }
        
        let saveURL: URL
        if let url = url {
            saveURL = url
        } else if let fileURL = fileURL {
            saveURL = fileURL
        } else {
            throw LOTWROMError.noSaveLocation
        }
        
        try rom.saveROM(to: saveURL)
        
        hasUnsavedChanges = false
        // Don't clear history on save - keep it for continued editing
    }
}

enum LOTWROMError: LocalizedError {
    case notLoaded
    case noSaveLocation
    
    var errorDescription: String? {
        switch self {
        case .notLoaded:
            return "No ROM file is loaded"
        case .noSaveLocation:
            return "No save location specified"
        }
    }
}
