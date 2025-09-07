//
//  UndoManager.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/6/25.
//

import Foundation

/// Represents a single change to ROM data
struct ROMChange {
    let offset: Int
    let oldValue: UInt8
    let newValue: UInt8
    let description: String
    let timestamp: Date
    
    init(offset: Int, oldValue: UInt8, newValue: UInt8, description: String = "") {
        self.offset = offset
        self.oldValue = oldValue
        self.newValue = newValue
        self.description = description
        self.timestamp = Date()
    }
}

/// Groups multiple changes into a single undoable operation
struct ChangeGroup {
    let changes: [ROMChange]
    let description: String
    let timestamp: Date
    
    init(changes: [ROMChange], description: String) {
        self.changes = changes
        self.description = description
        self.timestamp = Date()
    }
}

/// Manages undo/redo operations for ROM editing
class ROMUndoManager: ObservableObject {
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    @Published var undoDescription: String = ""
    @Published var redoDescription: String = ""
    
    private var undoStack: [ChangeGroup] = []
    private var redoStack: [ChangeGroup] = []
    private var currentGroup: [ROMChange] = []
    private var isGrouping: Bool = false
    private var groupDescription: String = ""
    
    private let maxStackSize = 100 // Limit memory usage
    
    // MARK: - Group Operations
    
    /// Begin grouping changes for a single undoable operation
    func beginGrouping(description: String) {
        guard !isGrouping else { return }
        isGrouping = true
        groupDescription = description
        currentGroup.removeAll()
    }
    
    /// End grouping and push to undo stack
    func endGrouping() {
        guard isGrouping else { return }
        isGrouping = false
        
        if !currentGroup.isEmpty {
            let group = ChangeGroup(changes: currentGroup, description: groupDescription)
            pushToUndoStack(group)
            currentGroup.removeAll()
        }
        
        groupDescription = ""
    }
    
    /// Cancel current grouping without saving
    func cancelGrouping() {
        isGrouping = false
        currentGroup.removeAll()
        groupDescription = ""
    }
    
    // MARK: - Recording Changes
    
    /// Record a single byte change
    func recordChange(offset: Int, oldValue: UInt8, newValue: UInt8, description: String = "") {
        let change = ROMChange(offset: offset, oldValue: oldValue, newValue: newValue, description: description)
        
        if isGrouping {
            currentGroup.append(change)
        } else {
            // Single change, create a group with one item
            let group = ChangeGroup(changes: [change], description: description.isEmpty ? "Edit" : description)
            pushToUndoStack(group)
        }
    }
    
    /// Record multiple byte changes
    func recordChanges(offset: Int, oldValues: [UInt8], newValues: [UInt8], description: String) {
        guard oldValues.count == newValues.count else { return }
        
        var changes: [ROMChange] = []
        for i in 0..<oldValues.count {
            if oldValues[i] != newValues[i] {
                changes.append(ROMChange(
                    offset: offset + i,
                    oldValue: oldValues[i],
                    newValue: newValues[i],
                    description: ""
                ))
            }
        }
        
        if changes.isEmpty { return }
        
        if isGrouping {
            currentGroup.append(contentsOf: changes)
        } else {
            let group = ChangeGroup(changes: changes, description: description)
            pushToUndoStack(group)
        }
    }
    
    // MARK: - Undo/Redo Operations
    
    /// Perform undo operation
    func undo(applyTo romFile: ROMFile) -> Bool {
        guard canUndo, let group = undoStack.popLast() else { return false }
        
        // Apply all changes in reverse order
        for change in group.changes.reversed() {
            romFile.writeByte(at: change.offset, value: change.oldValue)
        }
        
        // Push to redo stack
        redoStack.append(group)
        if redoStack.count > maxStackSize {
            redoStack.removeFirst()
        }
        
        updatePublishedProperties()
        return true
    }
    
    /// Perform redo operation
    func redo(applyTo romFile: ROMFile) -> Bool {
        guard canRedo, let group = redoStack.popLast() else { return false }
        
        // Apply all changes in forward order
        for change in group.changes {
            romFile.writeByte(at: change.offset, value: change.newValue)
        }
        
        // Push back to undo stack
        undoStack.append(group)
        
        updatePublishedProperties()
        return true
    }
    
    // MARK: - Stack Management
    
    /// Clear all undo/redo history
    func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
        currentGroup.removeAll()
        isGrouping = false
        groupDescription = ""
        updatePublishedProperties()
    }
    
    /// Get description of what will be undone
    func getUndoDescription() -> String {
        return undoStack.last?.description ?? ""
    }
    
    /// Get description of what will be redone
    func getRedoDescription() -> String {
        return redoStack.last?.description ?? ""
    }
    
    /// Get count of operations in undo stack
    var undoCount: Int {
        return undoStack.count
    }
    
    /// Get count of operations in redo stack
    var redoCount: Int {
        return redoStack.count
    }
    
    // MARK: - Private Helpers
    
    private func pushToUndoStack(_ group: ChangeGroup) {
        undoStack.append(group)
        
        // Clear redo stack when new changes are made
        redoStack.removeAll()
        
        // Limit stack size to prevent memory issues
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
        
        updatePublishedProperties()
    }
    
    private func updatePublishedProperties() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
        undoDescription = getUndoDescription()
        redoDescription = getRedoDescription()
    }
}

// MARK: - Convenience Extensions

extension ROMFile {
    /// Write a byte and record the change for undo
    func writeByteWithUndo(_ value: UInt8, at offset: Int, undoManager: ROMUndoManager, description: String = "") {
        guard let oldValue = readByte(at: offset) else { return }
        
        if oldValue != value {
            writeByte(at: offset, value: value)
            undoManager.recordChange(offset: offset, oldValue: oldValue, newValue: value, description: description)
        }
    }
    
    /// Write multiple bytes and record changes for undo
    func writeBytesWithUndo(_ values: [UInt8], at offset: Int, undoManager: ROMUndoManager, description: String) {
        guard let oldValues = readBytes(from: offset, count: values.count) else { return }
        
        writeBytes(at: offset, values: values)
        undoManager.recordChanges(offset: offset, oldValues: oldValues, newValues: values, description: description)
    }
}