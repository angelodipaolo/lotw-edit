//
//  NESPalette.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/5/25.
//

import SwiftUI

struct NESPalette {
    // Standard NES palette colors (64 colors)
    // Using 2C02 PPU palette values
    static let colors: [Color] = [
        // 0x00-0x0F
        Color(red: 0.333, green: 0.333, blue: 0.333), // 0x00 - Gray
        Color(red: 0.000, green: 0.114, blue: 0.416), // 0x01 - Dark Blue
        Color(red: 0.000, green: 0.047, blue: 0.573), // 0x02 - Dark Blue
        Color(red: 0.176, green: 0.000, blue: 0.573), // 0x03 - Dark Purple
        Color(red: 0.373, green: 0.000, blue: 0.471), // 0x04 - Purple
        Color(red: 0.471, green: 0.000, blue: 0.271), // 0x05 - Dark Red
        Color(red: 0.471, green: 0.000, blue: 0.000), // 0x06 - Red
        Color(red: 0.416, green: 0.071, blue: 0.000), // 0x07 - Brown
        Color(red: 0.318, green: 0.157, blue: 0.000), // 0x08 - Orange
        Color(red: 0.157, green: 0.220, blue: 0.000), // 0x09 - Dark Green
        Color(red: 0.000, green: 0.267, blue: 0.000), // 0x0A - Green
        Color(red: 0.000, green: 0.267, blue: 0.047), // 0x0B - Green
        Color(red: 0.000, green: 0.243, blue: 0.220), // 0x0C - Teal
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x0D - Black
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x0E - Black
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x0F - Black
        
        // 0x10-0x1F
        Color(red: 0.541, green: 0.541, blue: 0.541), // 0x10 - Light Gray
        Color(red: 0.000, green: 0.341, blue: 0.733), // 0x11 - Blue
        Color(red: 0.094, green: 0.220, blue: 0.914), // 0x12 - Blue
        Color(red: 0.376, green: 0.094, blue: 0.914), // 0x13 - Purple
        Color(red: 0.573, green: 0.047, blue: 0.816), // 0x14 - Purple
        Color(red: 0.718, green: 0.047, blue: 0.569), // 0x15 - Magenta
        Color(red: 0.718, green: 0.094, blue: 0.271), // 0x16 - Red
        Color(red: 0.659, green: 0.220, blue: 0.000), // 0x17 - Orange
        Color(red: 0.514, green: 0.341, blue: 0.000), // 0x18 - Orange
        Color(red: 0.318, green: 0.420, blue: 0.000), // 0x19 - Yellow-Green
        Color(red: 0.094, green: 0.471, blue: 0.000), // 0x1A - Green
        Color(red: 0.000, green: 0.471, blue: 0.094), // 0x1B - Green
        Color(red: 0.000, green: 0.443, blue: 0.376), // 0x1C - Cyan
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x1D - Black
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x1E - Black
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x1F - Black
        
        // 0x20-0x2F
        Color(red: 1.000, green: 1.000, blue: 1.000), // 0x20 - White
        Color(red: 0.212, green: 0.635, blue: 1.000), // 0x21 - Light Blue
        Color(red: 0.420, green: 0.514, blue: 1.000), // 0x22 - Light Blue
        Color(red: 0.678, green: 0.420, blue: 1.000), // 0x23 - Light Purple
        Color(red: 0.878, green: 0.376, blue: 1.000), // 0x24 - Light Purple
        Color(red: 1.000, green: 0.376, blue: 0.902), // 0x25 - Pink
        Color(red: 1.000, green: 0.420, blue: 0.631), // 0x26 - Light Red
        Color(red: 1.000, green: 0.518, blue: 0.341), // 0x27 - Light Orange
        Color(red: 0.902, green: 0.635, blue: 0.094), // 0x28 - Yellow
        Color(red: 0.678, green: 0.718, blue: 0.094), // 0x29 - Light Green
        Color(red: 0.420, green: 0.773, blue: 0.157), // 0x2A - Light Green
        Color(red: 0.267, green: 0.773, blue: 0.420), // 0x2B - Light Green
        Color(red: 0.267, green: 0.741, blue: 0.678), // 0x2C - Light Cyan
        Color(red: 0.267, green: 0.267, blue: 0.267), // 0x2D - Dark Gray
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x2E - Black
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x2F - Black
        
        // 0x30-0x3F
        Color(red: 1.000, green: 1.000, blue: 1.000), // 0x30 - White
        Color(red: 0.643, green: 0.831, blue: 1.000), // 0x31 - Pale Blue
        Color(red: 0.757, green: 0.773, blue: 1.000), // 0x32 - Pale Blue
        Color(red: 0.871, green: 0.741, blue: 1.000), // 0x33 - Pale Purple
        Color(red: 0.957, green: 0.718, blue: 1.000), // 0x34 - Pale Purple
        Color(red: 1.000, green: 0.718, blue: 0.957), // 0x35 - Pale Pink
        Color(red: 1.000, green: 0.741, blue: 0.843), // 0x36 - Pale Red
        Color(red: 1.000, green: 0.773, blue: 0.718), // 0x37 - Pale Orange
        Color(red: 0.957, green: 0.831, blue: 0.569), // 0x38 - Pale Yellow
        Color(red: 0.843, green: 0.871, blue: 0.569), // 0x39 - Pale Green
        Color(red: 0.741, green: 0.894, blue: 0.604), // 0x3A - Pale Green
        Color(red: 0.663, green: 0.894, blue: 0.741), // 0x3B - Pale Green
        Color(red: 0.663, green: 0.878, blue: 0.871), // 0x3C - Pale Cyan
        Color(red: 0.663, green: 0.663, blue: 0.663), // 0x3D - Light Gray
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x3E - Black
        Color(red: 0.000, green: 0.000, blue: 0.000), // 0x3F - Black
    ]
    
    static func colorForIndex(_ index: UInt8) -> Color {
        guard index < colors.count else { return .black }
        return colors[Int(index)]
    }
}

struct RoomPalette {
    let colors: [UInt8] // 4 color indices into NES palette
    
    init(data: [UInt8]) {
        if data.count >= 4 {
            self.colors = Array(data[0..<4])
        } else {
            self.colors = [0x0F, 0x0F, 0x0F, 0x0F] // Default to black
        }
    }
    
    init() {
        self.colors = [0x0F, 0x0F, 0x0F, 0x0F]
    }
    
    func colorAt(_ index: Int) -> Color {
        guard index < colors.count else { return .black }
        return NESPalette.colorForIndex(colors[index])
    }
}