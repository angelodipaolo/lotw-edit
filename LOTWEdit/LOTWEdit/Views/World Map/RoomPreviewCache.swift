//
//  RoomPreviewCache.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/6/25.
//

import SwiftUI

// Cache for pre-rendered room preview images
class RoomPreviewCache: ObservableObject {
    private var cache: [Int: CGImage] = [:]
    private let cacheQueue = DispatchQueue(label: "room.preview.cache", attributes: .concurrent)
    private let scale: CGFloat = 2
    
    func getImage(for room: Room, romData: LOTWROMData) -> CGImage? {
        let key = room.id
        
        // Check cache first
        return cacheQueue.sync {
            if let cached = cache[key] {
                return cached
            }
            
            // Generate and cache the image
            if let image = renderRoomPreview(room: room, romData: romData) {
                cacheQueue.async(flags: .barrier) {
                    self.cache[key] = image
                }
                return image
            }
            return nil
        }
    }
    
    func invalidateRoom(_ roomId: Int) {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeValue(forKey: roomId)
        }
    }
    
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    private func renderRoomPreview(room: Room, romData: LOTWROMData) -> CGImage? {
        // Create a bitmap context for the room preview (64x12 at scale)
        let width = Int(64 * scale)
        let height = Int(12 * scale)
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
        
        // Build CHR cache once for this room
        romData.buildCHRCacheForRoom(room)
        
        // Render room tiles
        for y in 0..<12 {
            for x in 0..<64 {
                let tileByte = room.getTile(x: x, y: y)
                let paletteIndex = Int((tileByte >> 6) & 0x03)
                let metatileIndex = Int(tileByte & 0x3F)
                
                // Get the color for this tile
                var color: Color = .gray
                
                if romData.getMetatile(for: room, index: metatileIndex) != nil,
                   paletteIndex < room.palettes.count {
                    let palette = room.palettes[paletteIndex]
                    // Use the main color from the palette for preview
                    let colorIndex = palette.colors.count > 1 ? palette.colors[1] : palette.colors[0]
                    color = NESPalette.colorForIndex(colorIndex)
                } else {
                    // Fallback to grayscale based on tile value
                    let brightness = Double(metatileIndex) / 64.0
                    color = Color(white: brightness)
                }
                
                // Fill the tile rectangle
                context.setFillColor(color.cgColor!)
                context.fill(CGRect(
                    x: Int(CGFloat(x) * scale),
                    y: Int(CGFloat(y) * scale),
                    width: Int(scale),
                    height: Int(scale)
                ))
            }
        }
        
        return context.makeImage()
    }
}
