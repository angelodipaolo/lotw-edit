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
    @State private var currentRoomId: Int = -1
    @State private var showNESPreview: Bool = false
    @State private var nesViewportX: Int = 0  // 0 to 48 (64 - 16)
    
    var body: some View {
        HSplitView {
            // Main canvas with toolbar
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Toggle(isOn: $showNESPreview) {
                        Label("NES Preview", systemImage: "tv")
                    }
                    .toggleStyle(.button)
                    
                    if showNESPreview {
                        Divider()
                            .frame(height: 20)
                            .padding(.horizontal, 8)
                        
                        Text("Viewport:")
                        Slider(
                            value: Binding(
                                get: { Double(nesViewportX) },
                                set: { nesViewportX = Int($0) }
                            ),
                            in: 0...48,
                            step: 1
                        )
                        .frame(width: 200)
                        
                        Text("X: \(nesViewportX)")
                            .monospacedDigit()
                            .frame(width: 50)
                        
                        Text("\(nesViewportX)-\(nesViewportX + 16) / 64")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Quick position buttons
                        Button("Left") {
                            nesViewportX = 0
                        }
                        .buttonStyle(.borderless)
                        
                        Button("Center") {
                            nesViewportX = 24  // (64 - 16) / 2
                        }
                        .buttonStyle(.borderless)
                        
                        Button("Right") {
                            nesViewportX = 48
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Existing ScrollView content
                ScrollView([.horizontal, .vertical]) {
                    if let roomId = selectedRoom,
                       roomId < romData.rooms.count {
                        RoomCanvas(
                            room: romData.rooms[roomId],
                            romData: romData,
                            selectedTile: $selectedTile,
                            zoomLevel: zoomLevel,
                            isEditMode: isEditMode,
                            selectedBrushTile: $selectedBrushTile,
                            isPainting: $isPainting,
                            showNESPreview: showNESPreview,
                            nesViewportX: nesViewportX
                        )
                    } else {
                        Text("Select a room from the world map")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 200)
            }
            .onKeyPress(.leftArrow) {
                if showNESPreview && nesViewportX > 0 {
                    nesViewportX -= 1
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.rightArrow) {
                if showNESPreview && nesViewportX < 48 {
                    nesViewportX += 1
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(keys: ["p"]) { _ in
                showNESPreview.toggle()
                return .handled
            }
            roomInspector
        }
        .onChange(of: selectedRoom) { _, newRoomId in
            // Build CHR cache when selected room changes
            if let roomId = newRoomId,
               roomId < romData.rooms.count {
                let room = romData.rooms[roomId]
                romData.buildCHRCacheForRoom(room)
                currentRoomId = roomId
            }
        }
    }
    
    var roomInspector: some View {
        // Inspector panel
        ScrollView {
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
            .padding()
        }
//        .frame(minWidth: 200)
    }
}
