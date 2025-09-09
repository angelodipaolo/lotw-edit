//
//  RoomCanvas.swift
//  LOTWEdit
//
//  Performance-optimized room canvas rendering
//

import SwiftUI
import CoreGraphics

struct RoomCanvas: View {
    let room: Room
    @ObservedObject var romData: LOTWROMData
    @Binding var selectedTile: Room.TilePosition?
    let zoomLevel: CGFloat
    let isEditMode: Bool
    @Binding var selectedBrushTile: UInt8
    @Binding var isPainting: Bool
    let showNESPreview: Bool
    let nesViewportX: Int
    
    @StateObject private var imageCache = MetatileImageCache()
    @State private var currentRoomId: Int = -1
    
    var body: some View {
        Canvas { context, size in
            // Render room tiles using cached images
            for y in 0..<12 {
                for x in 0..<64 {
                    let tileByte = room.getTile(x: x, y: y)
                    let paletteIndex = Int((tileByte >> 6) & 0x03)
                    let metatileIndex = Int(tileByte & 0x3F)
                    
                    let tileRect = CGRect(
                        x: CGFloat(x) * 16 * zoomLevel,
                        y: CGFloat(y) * 16 * zoomLevel,
                        width: 16 * zoomLevel,
                        height: 16 * zoomLevel
                    )
                    
                    // Use cached metatile image
                    if paletteIndex < room.palettes.count {
                        let palette = room.palettes[paletteIndex]
                        
                        if let cgImage = imageCache.getImage(
                            for: metatileIndex,
                            palette: palette,
                            paletteIndex: paletteIndex,
                            romData: romData,
                            room: room
                        ) {
                            context.draw(Image(cgImage, scale: 1.0, label: Text("")), in: tileRect)
                        } else {
                            // Fallback
                            context.fill(Path(tileRect), with: .color(.gray))
                        }
                    } else {
                        context.fill(Path(tileRect), with: .color(.gray))
                    }
                    
                    // Highlight selected tile
                    if selectedTile?.x == x && selectedTile?.y == y {
                        context.stroke(
                            Path(tileRect),
                            with: .color(.cyan),
                            lineWidth: 2
                        )
                    }
                }
            }
            
            // Draw object overlays in edit mode
            if isEditMode {
                drawObjectOverlays(context: context, zoomLevel: zoomLevel)
            }
            
            // Draw grid lines efficiently (only when zoomed)
            if zoomLevel >= 2 {
                drawGridLines(context: context, zoomLevel: zoomLevel)
            }
            
            // Draw NES preview overlay if enabled
            if showNESPreview {
                drawNESPreviewOverlay(context: context, viewportX: nesViewportX, zoomLevel: zoomLevel)
            }
        }
        .frame(
            width: 64 * 16 * zoomLevel,
            height: 12 * 16 * zoomLevel
        )
        .onTapGesture { location in
            handleTap(at: location)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDrag(value: value)
                }
                .onEnded { _ in
                    if isPainting {
                        isPainting = false
                        romData.undoManager.endGrouping()
                    }
                }
        )
        .onAppear {
            // Ensure CHR cache is built when view appears
            romData.buildCHRCacheForRoom(room)
            imageCache.clearCache()
            currentRoomId = room.id
        }
        .onChange(of: room.id) { _, newRoomId in
            // Build CHR cache when room changes
            if currentRoomId != newRoomId {
                romData.buildCHRCacheForRoom(room)
                imageCache.clearCache()
                currentRoomId = newRoomId
            }
        }
    }
    
    private func drawGridLines(context: GraphicsContext, zoomLevel: CGFloat) {
        // Draw all horizontal lines in one path
        var horizontalPath = Path()
        for y in 0...12 {
            horizontalPath.move(to: CGPoint(x: 0, y: CGFloat(y) * 16 * zoomLevel))
            horizontalPath.addLine(to: CGPoint(x: 64 * 16 * zoomLevel, y: CGFloat(y) * 16 * zoomLevel))
        }
        context.stroke(horizontalPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)
        
        // Draw all vertical lines in one path
        var verticalPath = Path()
        for x in 0...64 {
            verticalPath.move(to: CGPoint(x: CGFloat(x) * 16 * zoomLevel, y: 0))
            verticalPath.addLine(to: CGPoint(x: CGFloat(x) * 16 * zoomLevel, y: 12 * 16 * zoomLevel))
        }
        context.stroke(verticalPath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)
    }
    
    private func drawObjectOverlays(context: GraphicsContext, zoomLevel: CGFloat) {
        // Draw semi-transparent overlays for special tiles and secret walls
        for y in 0..<12 {
            for x in 0..<64 {
                let behavior = room.getMetatileBehavior(x: x, y: y)
                let tileRect = CGRect(
                    x: CGFloat(x) * 16 * zoomLevel,
                    y: CGFloat(y) * 16 * zoomLevel,
                    width: 16 * zoomLevel,
                    height: 16 * zoomLevel
                )
                
                // Draw behavior overlay for special tiles
                if behavior != .open && behavior != .solid {
                    context.fill(Path(tileRect), with: .color(behavior.overlayColor))
                    
                    // Draw icon if available and zoom is sufficient
                    if let icon = behavior.icon, zoomLevel >= 2 {
                        let fontSize = min(12 * zoomLevel, 24)
                        let iconPosition = CGPoint(
                            x: tileRect.midX,
                            y: tileRect.midY
                        )
                        context.draw(
                            Text(icon)
                                .font(.system(size: fontSize))
                                .foregroundColor(.white.opacity(0.8)),
                            at: iconPosition
                        )
                    }
                }
                
                // Highlight secret walls with a special border
                if room.isSecretTile(x: x, y: y) {
                    // Draw a dashed border to indicate secret wall
                    let secretPath = Path(tileRect)
                    context.stroke(
                        secretPath,
                        with: .color(.orange.opacity(0.6)),
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: [4, 2]
                        )
                    )
                }
            }
        }
    }
    
    private func drawNESPreviewOverlay(context: GraphicsContext, viewportX: Int, zoomLevel: CGFloat) {
        let viewportWidthInTiles = 16
        let roomWidthInTiles = 64
        let roomHeightInTiles = 12
        
        // Calculate pixel positions
        let viewportStartX = CGFloat(viewportX) * 16 * zoomLevel
        let viewportEndX = CGFloat(viewportX + viewportWidthInTiles) * 16 * zoomLevel
        let totalWidth = CGFloat(roomWidthInTiles) * 16 * zoomLevel
        let totalHeight = CGFloat(roomHeightInTiles) * 16 * zoomLevel
        
        // Draw semi-transparent overlay for left side (if any)
        if viewportX > 0 {
            let leftRect = CGRect(
                x: 0,
                y: 0,
                width: viewportStartX,
                height: totalHeight
            )
            context.fill(
                Path(leftRect),
                with: .color(.black.opacity(0.5))
            )
        }
        
        // Draw semi-transparent overlay for right side (if any)
        if viewportX + viewportWidthInTiles < roomWidthInTiles {
            let rightRect = CGRect(
                x: viewportEndX,
                y: 0,
                width: totalWidth - viewportEndX,
                height: totalHeight
            )
            context.fill(
                Path(rightRect),
                with: .color(.black.opacity(0.5))
            )
        }
        
        // Draw viewport border for clarity
        let viewportRect = CGRect(
            x: viewportStartX,
            y: 0,
            width: CGFloat(viewportWidthInTiles) * 16 * zoomLevel,
            height: totalHeight
        )
        context.stroke(
            Path(viewportRect),
            with: .color(.white.opacity(0.3)),
            lineWidth: 2
        )
    }
    
    private func handleTap(at location: CGPoint) {
        let x = Int(location.x / (16 * zoomLevel))
        let y = Int(location.y / (16 * zoomLevel))
        if x >= 0 && x < 64 && y >= 0 && y < 12 {
            if isEditMode {
                // Clear cache to force redraw with new tile
                imageCache.clearCache()
                romData.setRoomTile(roomId: room.id, x: x, y: y, tileValue: selectedBrushTile)
            } else {
                selectedTile = Room.TilePosition(x: x, y: y)
            }
        }
    }
    
    private func handleDrag(value: DragGesture.Value) {
        guard isEditMode else { return }
        
        let x = Int(value.location.x / (16 * zoomLevel))
        let y = Int(value.location.y / (16 * zoomLevel))
        
        if x >= 0 && x < 64 && y >= 0 && y < 12 {
            if !isPainting {
                isPainting = true
                // Clear cache at the start of drag painting
                imageCache.clearCache()
                romData.undoManager.beginGrouping(description: "Paint Tiles")
            }
            romData.setRoomTile(roomId: room.id, x: x, y: y, tileValue: selectedBrushTile)
        }
    }
}
