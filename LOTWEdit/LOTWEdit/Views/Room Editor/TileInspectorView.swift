//
//  TileInspectorView.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/6/25.
//

import SwiftUI

struct TileInspectorView: View {
    let tile: Room.TilePosition
    let room: Room
    @ObservedObject var romData: LOTWROMData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tile Info")
                .font(.headline)
            
            HStack {
                Text("Position:")
                Text("X: \(tile.x), Y: \(tile.y)")
                    .foregroundColor(.secondary)
            }
            
            let tileByte = room.getTile(x: tile.x, y: tile.y)
            let paletteIndex = (tileByte >> 6) & 0x03
            let metatileIndex = tileByte & 0x3F
            
            HStack {
                Text("Byte Value:")
                Text(String(format: "0x%02X", tileByte))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Metatile:")
                Text("\(metatileIndex)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Palette:")
                Text("\(paletteIndex)")
                    .foregroundColor(.secondary)
            }
            
            if paletteIndex < room.palettes.count {
                Text("Palette Colors:")
                    .font(.subheadline)
                HStack {
                    ForEach(0..<4) { index in
                        let colorByte = room.palettes[Int(paletteIndex)].colors[index]
                        Rectangle()
                            .fill(NESPalette.colorForIndex(colorByte))
                            .frame(width: 30, height: 30)
                            .border(Color.gray, width: 1)
                            .overlay(
                                Text(String(format: "%02X", colorByte))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            )
                    }
                }
            }
        }
    }
}
