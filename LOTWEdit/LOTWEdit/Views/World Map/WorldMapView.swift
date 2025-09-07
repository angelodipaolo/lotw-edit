//
//  WorldMapView.swift
//  LOTWEdit
//
//  Performance-optimized world map rendering with room image caching
//

import SwiftUI
import CoreGraphics

struct WorldMapView: View {
    @ObservedObject var romData: LOTWROMData
    @Binding var selectedRoom: Int?
    
    @StateObject private var previewCache = RoomPreviewCache()
    
    let columns = 4
    let rows = 18
    let roomWidth: CGFloat = 64
    let roomHeight: CGFloat = 12
    let scale: CGFloat = 2  // Display scale
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Canvas { context, size in
                // Render all room previews using cached images
                for roomId in 0..<72 {  // LOTW has 72 rooms
                    // Calculate position in 4 rows × 18 columns layout
                    let row = roomId / columns    // Which row (0-3)
                    let col = roomId % columns    // Which column (0-17)
                    
                    let rect = CGRect(
                        x: CGFloat(col) * roomWidth * scale,
                        y: CGFloat(row) * roomHeight * scale,
                        width: roomWidth * scale,
                        height: roomHeight * scale
                    )
                    
                    // Draw room preview using cached image
                    if roomId < romData.rooms.count {
                        if let cgImage = previewCache.getImage(
                            for: romData.rooms[roomId],
                            romData: romData
                        ) {
                            context.draw(
                                Image(cgImage, scale: 1.0, label: Text("")),
                                in: rect
                            )
                        } else {
                            // Fallback to simple fill
                            context.fill(Path(rect), with: .color(.gray.opacity(0.3)))
                        }
                    }
                    
                    // Draw room border
                    context.stroke(
                        Path(rect),
                        with: .color(.gray.opacity(0.5)),
                        lineWidth: 0.5
                    )
                    
                    // Highlight selected room
                    if selectedRoom == roomId {
                        context.stroke(
                            Path(rect),
                            with: .color(.yellow),
                            lineWidth: 2
                        )
                    }
                }
            }
            .frame(
                width: CGFloat(columns) * roomWidth * scale,
                height: CGFloat(rows) * roomHeight * scale
            )
            .onTapGesture { location in
                let col = Int(location.x / (roomWidth * scale))
                let row = Int(location.y / (roomHeight * scale))
                let roomId = row * columns + col
                if roomId >= 0 && roomId < 72 {
                    selectedRoom = roomId
                }
            }
        }
        .background(Color.black)
        .onReceive(romData.objectWillChange) { _ in
            // Clear cache when ROM data changes
            previewCache.clearCache()
        }
    }
}
