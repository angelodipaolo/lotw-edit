//
//  ArrayExtensions.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/6/25.
//

import Foundation

extension Array {
    /// Safe array subscript that returns nil if index is out of bounds
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

extension Collection {
    /// Safe collection subscript that returns nil if index is out of bounds
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}