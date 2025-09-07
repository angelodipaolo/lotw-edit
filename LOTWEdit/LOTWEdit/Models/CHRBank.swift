//
//  CHRBank.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/6/25.
//

import Foundation

class CHRBank: ObservableObject {
    @Published var tiles: [CHRTile] = []
    private let tilesPerBank = 256
    private let bytesPerTile = 16
    
    func loadFromROM(_ rom: ROMFile, bankIndex: Int) {
        let chrStart = headerSize + rom.prgRomSize // After header and PRG-ROM
        let bankOffset = chrStart + (bankIndex * 8192)
        
        tiles.removeAll()
        
        for tileIndex in 0..<tilesPerBank {
            let tileOffset = bankOffset + (tileIndex * bytesPerTile)
            if let tileData = rom.readBytes(from: tileOffset, count: bytesPerTile) {
                tiles.append(CHRTile(data: tileData))
            } else {
                tiles.append(CHRTile()) // Empty tile if read fails
            }
        }
    }
    
    private let headerSize = 16
}
