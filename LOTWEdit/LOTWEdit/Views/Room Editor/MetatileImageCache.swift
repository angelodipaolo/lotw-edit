//
//  MetatileImageCache.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/6/25.
//

import SwiftUI

// Cache for pre-rendered metatile images
class MetatileImageCache: ObservableObject {
    private var cache: [String: CGImage] = [:]
    private let cacheQueue = DispatchQueue(label: "metatile.cache", attributes: .concurrent)
    
    func getImage(for metatileIndex: Int, palette: RoomPalette, paletteIndex: Int, romData: LOTWROMData, room: Room) -> CGImage? {
        let key = "\(room.id)-\(metatileIndex)-\(paletteIndex)"
        
        // Check cache first
        return cacheQueue.sync {
            if let cached = cache[key] {
                return cached
            }
            
            // Generate and cache the image
            if let image = renderMetatileImage(metatileIndex: metatileIndex, palette: palette, paletteIndex: paletteIndex, romData: romData, room: room) {
                cacheQueue.async(flags: .barrier) {
                    self.cache[key] = image
                }
                return image
            }
            return nil
        }
    }
    
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    private func renderMetatileImage(metatileIndex: Int, palette: RoomPalette, paletteIndex: Int, romData: LOTWROMData, room: Room) -> CGImage? {
        // Create a 16x16 bitmap context
        let width = 16
        let height = 16
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else { return nil }
        
        // Get metatile data
        guard let metatile = romData.getMetatile(for: room, index: metatileIndex) else { return nil }
        
        // Draw each quadrant
        let positions = [(0, 0), (0, 1), (1, 0), (1, 1)]  // TL, BL, TR, BR
        
        for (index, chrTileId) in metatile.tiles.enumerated() {
            guard index < positions.count else { break }
            let (quadX, quadY) = positions[index]
            
            if let chrTile = romData.getCachedCHRTile(tileId: Int(chrTileId), paletteIndex: paletteIndex) {
                // Draw CHR tile pixels directly to the context
                for y in 0..<8 {
                    for x in 0..<8 {
                        let paletteIdx = chrTile.pixels[y][x]
                        let colorIndex = paletteIdx < palette.colors.count ? palette.colors[Int(paletteIdx)] : 0x0F
                        let color = NESPalette.colorForIndex(colorIndex)
                        
                        context.setFillColor(color.cgColor!)
                        context.fill(CGRect(
                            x: quadX * 8 + x,
                            y: (1 - quadY) * 8 + (7 - y),  // Flip both quadrant position and pixel position
                            width: 1,
                            height: 1
                        ))
                    }
                }
            }
        }
        
        return context.makeImage()
    }
}
