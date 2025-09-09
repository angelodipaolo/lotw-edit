//
//  MetatileBehavior.swift
//  LOTWEdit
//
//  Defines the behavior types for metatiles based on their index
//

import SwiftUI

enum MetatileBehavior: String, CaseIterable {
    case ladder = "Ladder"
    case enter = "Enter/Portal"
    case lockedDoor = "Locked Door"
    case celina = "Celina Teleport"
    case shopSign = "Shop Sign"
    case innSign = "Inn Sign"
    case open = "Open Space"
    case spike = "Spike Trap"
    case solid = "Solid Wall"
    case movableBlock = "Movable Block"
    
    init(from metatileIndex: Int) {
        let index = metatileIndex & 0x3F  // Use only low 6 bits
        switch index {
        case 0: self = .ladder
        case 1: self = .enter
        case 2: self = .lockedDoor
        case 3: self = .celina
        case 4: self = .shopSign
        case 5: self = .innSign
        case 0x30: self = .spike
        case 0x3E: self = .movableBlock
        case 0x31...0x3D, 0x3F: self = .solid
        default: self = .open  // 6-47
        }
    }
    
    var overlayColor: Color {
        switch self {
        case .ladder: return Color(red: 0, green: 0x88/255.0, blue: 0).opacity(0.4)
        case .enter: return Color(red: 0, green: 1, blue: 0).opacity(0.4)
        case .lockedDoor: return Color(red: 0x88/255.0, green: 0, blue: 1).opacity(0.4)
        case .celina: return Color(red: 0, green: 1, blue: 1).opacity(0.4)
        case .shopSign: return Color(red: 0xCC/255.0, green: 1, blue: 0).opacity(0.4)
        case .innSign: return Color(red: 0, green: 1, blue: 0xCC/255.0).opacity(0.4)
        case .spike: return Color(red: 1, green: 0, blue: 0).opacity(0.4)
        case .movableBlock: return Color(red: 1, green: 0xDD/255.0, blue: 0).opacity(0.4)
        case .solid: return Color.white.opacity(0.2)
        case .open: return Color.clear
        }
    }
    
    var icon: String? {
        switch self {
        case .ladder: return "⊥"
        case .lockedDoor: return "🔒"
        case .shopSign: return "$"
        case .innSign: return "I"
        case .movableBlock: return "◈"
        case .spike: return "▲"
        case .enter: return "→"
        case .celina: return "C"
        default: return nil
        }
    }
    
    var description: String? {
        switch self {
        case .ladder: return "Can be climbed"
        case .enter: return "Entry/exit point"
        case .lockedDoor: return "Requires key to open"
        case .celina: return "Princess Celina teleport"
        case .shopSign: return "Marks shop entrance below"
        case .innSign: return "Marks inn entrance below"
        case .spike: return "Damages player on contact"
        case .movableBlock: return "Can be pushed or destroyed"
        case .solid: return "Impassable terrain"
        case .open: return "Walkable space"
        }
    }
}