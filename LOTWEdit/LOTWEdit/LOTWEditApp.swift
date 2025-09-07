//
//  LOTWEditApp.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/5/25.
//

import SwiftUI

@main
struct LOTWEditApp: App {
    @StateObject private var romData = LOTWROMData()
    
    var body: some Scene {
        WindowGroup {
            MainEditorView()
                .environmentObject(romData)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open ROM...") {
                    openROM()
                }
                .keyboardShortcut("O", modifiers: .command)
            }
            
            CommandGroup(replacing: .saveItem) {
                Button("Save ROM") {
                    saveROM()
                }
                .keyboardShortcut("S", modifiers: .command)
                .disabled(!romData.isLoaded)
                
                Button("Save ROM As...") {
                    saveROMAs()
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
                .disabled(!romData.isLoaded)
            }
        }
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
                showError(error)
            }
        }
    }
    
    func saveROM() {
        guard romData.isLoaded else { return }
        
        // If we have a file URL, save to it directly
        if let fileURL = romData.fileURL {
            do {
                try romData.saveROM(to: fileURL)
                showSaveSuccess()
            } catch {
                showError(error)
            }
        } else {
            // Otherwise use Save As
            saveROMAs()
        }
    }
    
    func saveROMAs() {
        guard romData.isLoaded else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "nes")!]
        panel.canCreateDirectories = true
        panel.title = "Save ROM File"
        panel.nameFieldStringValue = romData.fileName.isEmpty ? "modified.nes" : romData.fileName
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try romData.saveROM(to: url)
                romData.fileURL = url
                romData.fileName = url.lastPathComponent
                showSaveSuccess()
            } catch {
                showError(error)
            }
        }
    }
    
    func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showSaveSuccess() {
        // Optional: Show a subtle notification that save was successful
        // For now, we'll just clear the unsaved changes flag
        romData.hasUnsavedChanges = false
    }
}
