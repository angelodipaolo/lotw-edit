//
//  CHRTile.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/5/25.
//

import Foundation
import SwiftUI

struct CHRTile {
    let pixels: [[UInt8]] // 8x8 grid of palette indices (0-3)
    
    init(data: [UInt8]) {
        var pixelGrid = Array(repeating: Array(repeating: UInt8(0), count: 8), count: 8)
        
        // NES CHR uses 2 bitplanes
        for y in 0..<8 {
            let plane0 = data[y]
            let plane1 = data[y + 8]
            
            for x in 0..<8 {
                let bit0 = (plane0 >> (7 - x)) & 1
                let bit1 = (plane1 >> (7 - x)) & 1
                pixelGrid[y][x] = (bit1 << 1) | bit0
            }
        }
        
        self.pixels = pixelGrid
    }
    
    init() {
        self.pixels = Array(repeating: Array(repeating: UInt8(0), count: 8), count: 8)
    }
}
