//
//  TilePaletteView.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/6/25.
//

import SwiftUI

struct TilePaletteView: View {
    @ObservedObject var romData: LOTWROMData
    @Binding var selectedTile: UInt8
    @Binding var selectedPalette: Int
    let room: Room
    
    private let tilesPerRow = 8
    private let tileSize: CGFloat = 32
    @State private var isCacheBuilt = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Tile Palette")
                    .font(.headline)
                Spacer()
                
                // Palette selector
                Picker("Palette", selection: $selectedPalette) {
                    ForEach(0..<4) { index in
                        Text("Palette \(index + 1)").tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            .padding(.horizontal)
            
            // Metatile grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(tileSize + 4)), count: tilesPerRow), spacing: 4) {
                    ForEach(0..<64) { metatileIndex in
                        MetatileThumbnail(
                            romData: romData,
                            room: room,
                            metatileIndex: UInt8(metatileIndex),
                            paletteIndex: selectedPalette,
                            isSelected: selectedTile == UInt8(metatileIndex | (selectedPalette << 6))
                        )
                        .frame(width: tileSize, height: tileSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(selectedTile == UInt8(metatileIndex | (selectedPalette << 6)) ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            // Combine metatile index with palette bits
                            selectedTile = UInt8(metatileIndex | (selectedPalette << 6))
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Selected tile info
            VStack(alignment: .leading, spacing: 5) {
                let metatileIndex = selectedTile & 0x3F
                let paletteIndex = Int((selectedTile >> 6) & 0x03)
                
                Text("Selected Tile")
                    .font(.headline)
                
                HStack {
                    MetatileThumbnail(
                        romData: romData,
                        room: room,
                        metatileIndex: metatileIndex,
                        paletteIndex: paletteIndex,
                        isSelected: false
                    )
                    .frame(width: 48, height: 48)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                    
                    VStack(alignment: .leading) {
                        Text("Metatile: $\(String(format: "%02X", metatileIndex))")
                            .font(.system(.caption, design: .monospaced))
                        Text("Palette: \(paletteIndex + 1)")
                            .font(.system(.caption, design: .monospaced))
                        Text("Byte: $\(String(format: "%02X", selectedTile))")
                            .font(.system(.caption, design: .monospaced))
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
        .onAppear {
            // Ensure CHR cache is built when the view appears
            if !isCacheBuilt {
                romData.buildCHRCacheForRoom(room)
                isCacheBuilt = true
            }
        }
        .onChange(of: room.id) { _ in
            // Rebuild cache if room changes
            romData.buildCHRCacheForRoom(room)
        }
    }
}

struct MetatileThumbnail: View {
    @ObservedObject var romData: LOTWROMData
    let room: Room
    let metatileIndex: UInt8
    let paletteIndex: Int
    let isSelected: Bool
    
    var body: some View {
        Canvas { context, size in
            // Ensure CHR cache is built
            romData.buildCHRCacheForRoom(room)
            
            // Get the metatile
            if let metatile = romData.getMetatile(for: room, index: Int(metatileIndex)) {
                let palette = room.palettes[paletteIndex]
                
                // Draw the 2x2 CHR tiles
                let halfSize = size.width / 2
                
                // Use correct positions: metatile.tiles is ordered as [TL, BL, TR, BR]
                let positions = [(0, 0), (0, 1), (1, 0), (1, 1)]  // TL, BL, TR, BR
                
                for (index, chrTileId) in metatile.tiles.enumerated() {
                    guard index < positions.count else { break }
                    let (x, y) = positions[index]
                    
                    let rect = CGRect(
                        x: CGFloat(x) * halfSize,
                        y: CGFloat(y) * halfSize,
                        width: halfSize,
                        height: halfSize
                    )
                    
                    // Get cached CHR tile with palette offset
                    if let chrTile = romData.getCachedCHRTile(tileId: Int(chrTileId), paletteIndex: paletteIndex) {
                        drawCHRTile(chrTile, palette: palette, in: rect, context: context)
                    } else {
                        // Fallback: draw solid color based on palette
                        context.fill(
                            Path(rect),
                            with: .color(NESPalette.colorForIndex(palette.colors[0]))
                        )
                    }
                }
            } else {
                // Draw placeholder
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color.gray.opacity(0.3))
                )
            }
        }
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
    
    func drawCHRTile(_ tile: CHRTile, palette: RoomPalette, in rect: CGRect, context: GraphicsContext) {
        let pixelWidth = rect.width / 8
        let pixelHeight = rect.height / 8
        
        for y in 0..<8 {
            for x in 0..<8 {
                let paletteIndex = tile.pixels[y][x]
                let color = palette.colors[Int(paletteIndex)]
                
                let pixelRect = CGRect(
                    x: rect.minX + CGFloat(x) * pixelWidth,
                    y: rect.minY + CGFloat(y) * pixelHeight,
                    width: pixelWidth,
                    height: pixelHeight
                )
                
                context.fill(
                    Path(pixelRect),
                    with: .color(NESPalette.colorForIndex(color))
                )
            }
        }
    }
}

#Preview {
    TilePaletteView(
        romData: LOTWROMData(),
        selectedTile: .constant(0),
        selectedPalette: .constant(0),
        room: Room(id: 0, data: Array(repeating: 0, count: 1024))
    )
    .frame(width: 300, height: 600)
}