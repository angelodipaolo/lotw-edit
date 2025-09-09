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
            
            Divider()
            
            // Object/Behavior Information
            Text("Object Info")
                .font(.headline)
            
            let behavior = room.getMetatileBehavior(x: tile.x, y: tile.y)
            
            HStack {
                Text("Behavior:")
                Text(behavior.rawValue)
                    .foregroundColor(.secondary)
                    .bold()
            }
            
            if let description = behavior.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            // Secret wall information
            if room.isSecretTile(x: tile.x, y: tile.y) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("SECRET WALL", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption.bold())
                    
                    HStack {
                        Text("Becomes tile:")
                            .font(.caption)
                        Text("\(room.secretWallReplacementTile & 0x3F)")
                            .font(.caption.monospaced())
                            .foregroundColor(.orange)
                    }
                }
                .padding(4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
            }
            
            // Special properties based on behavior
            if behavior == .shopSign || behavior == .innSign {
                if behavior == .shopSign && room.shopData.count >= 4 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shop Items:")
                            .font(.caption.bold())
                        HStack {
                            Text("Item 1: \(room.shopData[0])")
                            Text("Price: \(room.shopData[1])G")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        HStack {
                            Text("Item 2: \(room.shopData[2])")
                            Text("Price: \(room.shopData[3])G")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                Text("Door entrance below this sign")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if behavior == .celina && room.teleportCoords.count >= 4 {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Teleport Destination:")
                        .font(.caption.bold())
                    HStack {
                        Text("Map: (\(room.teleportCoords[0]), \(room.teleportCoords[1]))")
                        Text("Pos: (\(room.teleportCoords[2]), \(room.teleportCoords[3]))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}
