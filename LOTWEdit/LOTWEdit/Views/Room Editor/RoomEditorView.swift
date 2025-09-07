//
//  RoomEditorView.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/5/25.
//

import SwiftUI

struct RoomEditorView: View {
    @ObservedObject var romData: LOTWROMData
    @Binding var selectedRoom: Int?
    @State private var selectedTile: Room.TilePosition?
    @State private var zoomLevel: CGFloat = 2
    @State private var selectedBrushTile: UInt8 = 0
    @State private var selectedPalette: Int = 0
    @State private var isEditMode: Bool = false
    @State private var isPainting: Bool = false
    
    var body: some View {
        HSplitView {
            // Main canvas
            ScrollView([.horizontal, .vertical]) {
                if let roomId = selectedRoom,
                   roomId < romData.rooms.count {
                    RoomCanvas(
                        room: romData.rooms[roomId],
                        romData: romData,
                        selectedTile: $selectedTile,
                        zoomLevel: zoomLevel,
                        isEditMode: isEditMode,
                        selectedBrushTile: selectedBrushTile,
                        isPainting: $isPainting
                    )
                } else {
                    Text("Select a room from the world map")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400)
            
            // Inspector panel
            VStack(alignment: .leading) {
                // Header with edit mode toggle
                HStack {
                    Text("Room Inspector")
                        .font(.headline)
                    Spacer()
                    Toggle("Edit", isOn: $isEditMode)
                        .toggleStyle(SwitchToggleStyle())
                }
                .padding(.bottom, 5)
                
                if let roomId = selectedRoom {
                    Text("Room #\(roomId)")
                        .font(.subheadline)
                    
                    Divider()
                    
                    if isEditMode {
                        // Tile palette for editing
                        if let room = romData.rooms[safe: roomId] {
                            TilePaletteView(
                                romData: romData,
                                selectedTile: $selectedBrushTile,
                                selectedPalette: $selectedPalette,
                                room: room
                            )
                            .frame(maxHeight: 400)
                        }
                    } else if let tile = selectedTile {
                        // Tile inspector for viewing
                        TileInspectorView(
                            tile: tile,
                            room: romData.rooms[roomId],
                            romData: romData
                        )
                    }
                }
                
                Divider()
                
                // Zoom control
                HStack {
                    Text("Zoom:")
                    Slider(value: $zoomLevel, in: 1...8, step: 1)
                    Text("\(Int(zoomLevel))x")
                }
                .padding(.vertical, 5)
                
                // Undo/Redo buttons when in edit mode
                if isEditMode {
                    HStack {
                        Button(action: { romData.undo() }) {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                        }
                        .disabled(!romData.undoManager.canUndo)
                        .keyboardShortcut("z", modifiers: .command)
                        
                        Button(action: { romData.redo() }) {
                            Label("Redo", systemImage: "arrow.uturn.forward")
                        }
                        .disabled(!romData.undoManager.canRedo)
                        .keyboardShortcut("z", modifiers: [.command, .shift])
                    }
                    .padding(.vertical, 5)
                }
                
                // Debug info
                if let roomId = selectedRoom, roomId < romData.rooms.count {
                    let room = romData.rooms[roomId]
                    Text("Debug: Metatile Page: \(room.metatilePage)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("CHR Pages: \(room.chrPages[0]), \(room.chrPages[1])")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(width: 300)
            .padding()
        }
    }
}
