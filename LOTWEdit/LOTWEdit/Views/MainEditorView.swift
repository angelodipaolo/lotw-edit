//
//  MainEditorView.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/5/25.
//

import SwiftUI

struct MainEditorView: View {
    @EnvironmentObject var romData: LOTWROMData
    @State private var selectedRoom: Int?
    @State private var worldMapHeight: CGFloat = 300
    
    var body: some View {
        if romData.isLoaded {
            VSplitView {
                // World map at top
                VStack(alignment: .leading) {
                    HStack {
                        Text("World Map")
                            .font(.headline)
                        Spacer()
                        Text(romData.fileName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    
                    WorldMapView(
                        romData: romData,
                        selectedRoom: $selectedRoom
                    )
                }
                .frame(height: worldMapHeight)
                
                // Room editor below
                RoomEditorView(
                    romData: romData,
                    selectedRoom: $selectedRoom
                )
            }
        } else {
            WelcomeView()
        }
    }
}

struct WelcomeView: View {
    @EnvironmentObject var romData: LOTWROMData
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Legacy of the Wizard ROM Editor")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Open a ROM file to begin editing")
                .foregroundColor(.secondary)
            
            Button(action: openROM) {
                Label("Open ROM File...", systemImage: "folder.open")
                    .frame(width: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Supported Files:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Legacy of the Wizard (US NES)")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Dragon Slayer IV (Japanese Famicom)")
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    func openROM() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "nes")!]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.title = "Select Legacy of the Wizard ROM"
        panel.message = "Choose a Legacy of the Wizard NES ROM file"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try romData.loadROM(from: url)
            } catch {
                // Show error alert
                let alert = NSAlert()
                alert.messageText = "Failed to Load ROM"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}

#Preview {
    MainEditorView()
        .environmentObject(LOTWROMData())
}
