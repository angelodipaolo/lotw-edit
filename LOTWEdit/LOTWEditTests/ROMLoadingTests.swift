//
//  ROMLoadingTests.swift
//  LOTWEditTests
//
//  Created by Angelo Di Paolo on 9/6/25.
//

import XCTest
@testable import LOTWEdit

final class ROMLoadingTests: XCTestCase {
    
    func testROMFileLoading() throws {
        // Test with the actual LOTW.nes file
        let romPath = URL(fileURLWithPath: "/Users/angelo/devlocal/lotw-editor/LOTW.nes")
        
        let romFile = ROMFile()
        XCTAssertNoThrow(try romFile.loadROM(from: romPath))
        XCTAssertTrue(romFile.isValid)
        XCTAssertNotNil(romFile.data)
        
        // Verify header
        XCTAssertEqual(romFile.readByte(at: 0), 0x4E) // 'N'
        XCTAssertEqual(romFile.readByte(at: 1), 0x45) // 'E'
        XCTAssertEqual(romFile.readByte(at: 2), 0x53) // 'S'
        XCTAssertEqual(romFile.readByte(at: 3), 0x1A) // EOF
        
        // Verify mapper
        let mapper = ((romFile.readByte(at: 6)! >> 4) | (romFile.readByte(at: 7)! & 0xF0))
        XCTAssertEqual(mapper, 4) // MMC3
        
        // Verify PRG/CHR sizes
        XCTAssertEqual(romFile.prgRomSize, 131072) // 8 banks * 16KB
        XCTAssertEqual(romFile.chrRomSize, 65536)  // 8 banks * 8KB
    }
    
    func testROMDataLoading() throws {
        let romPath = URL(fileURLWithPath: "/Users/angelo/devlocal/lotw-editor/LOTW.nes")
        
        let romData = LOTWROMData()
        XCTAssertNoThrow(try romData.loadROM(from: romPath))
        XCTAssertTrue(romData.isLoaded)
        
        // Verify rooms loaded
        XCTAssertEqual(romData.rooms.count, 128)
        
        // Verify first room
        let room0 = romData.rooms[0]
        XCTAssertEqual(room0.id, 0)
        XCTAssertEqual(room0.terrain.count, 768)
        XCTAssertEqual(room0.enemies.count, 9)
        XCTAssertEqual(room0.palettes.count, 8)
        
        // Verify CHR tiles loaded
        XCTAssertEqual(romData.chrTiles.count, 4096) // 8 banks * 512 tiles
        
        // Verify metatiles loaded
        XCTAssertEqual(romData.metatiles.count, 1024) // 16 pages * 64 metatiles
    }
    
    func testCHRTileDecoding() throws {
        // Test CHR tile decoding with known pattern
        let testData: [UInt8] = [
            0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, // Plane 0: vertical stripes
            0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF  // Plane 1: vertical stripes offset
        ]
        
        let tile = CHRTile(data: testData)
        
        // Check first row should be: 2,2,0,0,2,2,0,0
        XCTAssertEqual(tile.pixels[0][0], 2)
        XCTAssertEqual(tile.pixels[0][1], 2)
        XCTAssertEqual(tile.pixels[0][2], 0)
        XCTAssertEqual(tile.pixels[0][3], 0)
        XCTAssertEqual(tile.pixels[0][4], 2)
        XCTAssertEqual(tile.pixels[0][5], 2)
        XCTAssertEqual(tile.pixels[0][6], 0)
        XCTAssertEqual(tile.pixels[0][7], 0)
    }
    
    func testRoomTileAccess() throws {
        let romPath = URL(fileURLWithPath: "/Users/angelo/devlocal/lotw-editor/LOTW.nes")
        
        let romData = LOTWROMData()
        try romData.loadROM(from: romPath)
        
        let room = romData.rooms[0]
        
        // Test tile access at various positions
        let tile00 = room.getTile(x: 0, y: 0)
        XCTAssertNotNil(tile00)
        
        // Test bounds
        let outOfBounds = room.getTile(x: 64, y: 12)
        XCTAssertEqual(outOfBounds, 0) // Should return 0 for out of bounds
        
        // Verify column-major indexing
        let tileAt5_3 = room.getTile(x: 5, y: 3)
        let expectedIndex = 5 * 12 + 3 // Column-major
        XCTAssertEqual(tileAt5_3, room.terrain[expectedIndex])
    }
    
    func testMetatileRetrieval() throws {
        let romPath = URL(fileURLWithPath: "/Users/angelo/devlocal/lotw-editor/LOTW.nes")
        
        let romData = LOTWROMData()
        try romData.loadROM(from: romPath)
        
        let room = romData.rooms[0]
        
        // Get a metatile for the room
        let metatile = romData.getMetatile(for: room, index: 0)
        XCTAssertNotNil(metatile)
        XCTAssertEqual(metatile?.tiles.count, 4) // 2x2 arrangement
    }
    
    func testPaletteColors() throws {
        // Test NES palette access
        let color0 = NESPalette.colorForIndex(0)
        XCTAssertNotNil(color0)
        
        let color63 = NESPalette.colorForIndex(63)
        XCTAssertNotNil(color63)
        
        // Test out of bounds
        let colorInvalid = NESPalette.colorForIndex(255)
        XCTAssertEqual(colorInvalid, .black) // Should return black for invalid
    }
}