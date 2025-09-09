//
//  Room.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/5/25.
//

import Foundation

struct Room: Identifiable {
    struct TilePosition: Equatable {
        let x: Int
        let y: Int
    }

    let id: Int  // Room number 0-127
    var terrain: [UInt8]  // 768 bytes (64x12)
    var metatilePage: UInt8
    var enemyCHRPage: UInt8
    var secretTiles: UInt16
    var chrPages: [UInt8]
    var treasureChests: [UInt8]
    var musicTrack: UInt8
    var teleportCoords: [UInt8]
    var shopData: [UInt8]
    var characterFlags: UInt8
    var enemies: [Enemy]
    var palettes: [RoomPalette]
    
    init(id: Int, data: [UInt8]) {
        self.id = id
        
        // Ensure we have enough data
        guard data.count >= 1024 else {
            // Initialize with empty/default values
            self.terrain = Array(repeating: 0, count: 768)
            self.metatilePage = 0
            self.enemyCHRPage = 0
            self.secretTiles = 0
            self.chrPages = [0, 0]
            self.treasureChests = [0, 0, 0, 0]
            self.musicTrack = 0
            self.teleportCoords = [0, 0, 0, 0]
            self.shopData = [0, 0, 0, 0]
            self.characterFlags = 0
            self.enemies = []
            self.palettes = []
            return
        }
        
        // Parse terrain data (first 768 bytes)
        self.terrain = Array(data[0..<768])
        
        // Parse room metadata
        self.metatilePage = data[0x300]
        self.enemyCHRPage = data[0x301]
        self.secretTiles = UInt16(data[0x302]) | (UInt16(data[0x303]) << 8)
        self.chrPages = [data[0x305], data[0x306]]
        self.treasureChests = Array(data[0x307..<0x30B])
        self.musicTrack = data[0x30B]
        self.teleportCoords = Array(data[0x30C..<0x310])
        self.shopData = Array(data[0x310..<0x314])
        self.characterFlags = data[0x314]
        
        // Parse enemies (9 enemies, 16 bytes each)
        self.enemies = []
        for i in 0..<9 {
            let offset = 0x320 + (i * 16)
            if offset + 16 <= data.count {
                let enemyData = Array(data[offset..<offset + 16])
                enemies.append(Enemy(data: enemyData))
            }
        }
        
        // Parse palettes (8 palettes, 4 colors each)
        self.palettes = []
        for i in 0..<8 {
            let offset = 0x3E0 + (i * 4)
            if offset + 4 <= data.count {
                let paletteData = Array(data[offset..<offset + 4])
                palettes.append(RoomPalette(data: paletteData))
            }
        }
    }
    
    func getTile(x: Int, y: Int) -> UInt8 {
        guard x >= 0 && x < 64 && y >= 0 && y < 12 else { return 0 }
        return terrain[x * 12 + y]  // Column-major indexing to match ROM format
    }
    
    mutating func setTile(x: Int, y: Int, value: UInt8) {
        guard x >= 0 && x < 64 && y >= 0 && y < 12 else { return }
        terrain[x * 12 + y] = value  // Column-major indexing to match ROM format
    }
    
    // MARK: - Metatile Behavior
    
    func getMetatileBehavior(x: Int, y: Int) -> MetatileBehavior {
        let tile = getTile(x: x, y: y)
        let metatileIndex = Int(tile & 0x3F)
        return MetatileBehavior(from: metatileIndex)
    }
    
    // MARK: - Secret Walls
    
    var secretWallTileIndex: UInt8 {
        return UInt8(secretTiles & 0xFF)  // Low byte - which tile appears solid but isn't
    }
    
    var secretWallReplacementTile: UInt8 {
        return UInt8((secretTiles >> 8) & 0xFF)  // High byte - what it becomes when touched
    }
    
    func isSecretTile(x: Int, y: Int) -> Bool {
        let tile = getTile(x: x, y: y)
        let tileIndex = tile & 0x3F
        return tileIndex == secretWallTileIndex && secretWallTileIndex != 0
    }
    
    // Note: Block replacement tile is at offset $304 but not currently parsed
    // This would be added as: var blockReplacementTile: UInt8
}
