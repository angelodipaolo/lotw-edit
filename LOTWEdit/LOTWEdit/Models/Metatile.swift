//
//  Metatile.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/6/25.
//

struct Metatile {
    let tiles: [UInt8] // 4 CHR tile indices (top-left, bottom-left, top-right, bottom-right)
    
    init(tiles: [UInt8]) {
        if tiles.count >= 4 {
            self.tiles = Array(tiles[0..<4])
        } else {
            self.tiles = [0, 0, 0, 0]
        }
    }
    
    init() {
        self.tiles = [0, 0, 0, 0]
    }
}
