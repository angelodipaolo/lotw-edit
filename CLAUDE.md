# CLAUDE.md

## Project Overview

Native macOS SwiftUI application for editing Legacy of the Wizard (LOTW) NES ROM files. This editor provides a modern interface for modifying game rooms with real-time rendering, undo/redo support, and performance-optimized graphics pipeline.

## Build Commands

```bash
# Build the project
xcodebuild -project LOTWEdit/LOTWEdit.xcodeproj -scheme LOTWEdit build

# Clean build
xcodebuild -project LOTWEdit/LOTWEdit.xcodeproj -scheme LOTWEdit clean

# Run tests
xcodebuild -project LOTWEdit/LOTWEdit.xcodeproj -scheme LOTWEdit test
```

## Architecture

### Core Data Flow
1. **ROM Loading**: `LOTWEditApp.swift:43-58` - NSOpenPanel file picker with .nes validation
2. **Data Parsing**: `LOTWROMData.swift:71-124` - Loads 128 rooms, 4096 CHR tiles, 1024 metatiles
3. **CHR Caching**: `LOTWROMData.swift:126-180` - Builds room-specific tile cache (2048 entries)
4. **Graphics Pipeline**: CHR tiles → Metatiles → CGImage cache → Canvas rendering
5. **Edit Operations**: `LOTWROMData.swift:306-415` - Tile editing with undo/redo support

### Key Components

**Models** (`LOTWEdit/LOTWEdit/Models/`)
- `ROMFile.swift` - Low-level ROM access with iNES header validation
- `LOTWROMData.swift` - Central ObservableObject coordinating all ROM data
- `Room.swift` - 64x12 tile grid (768 bytes) + 256 bytes metadata
- `CHRTile.swift` - 8x8 pixel decoding from NES 2-bitplane format
- `Metatile.swift` - 2x2 CHR tile groups forming 16x16 pixel blocks
- `CHRBank.swift` - Bank-based CHR tile organization (512 tiles per 8KB bank)
- `Enemy.swift` - 16-byte enemy data structure (9 per room)
- `NESPalette.swift` - Standard 64-color NES palette implementation
- `UndoManager.swift` - Sophisticated undo system with change grouping

**Views** (`LOTWEdit/LOTWEdit/Views/`)
- `MainEditorView.swift` - Primary split view interface
- `World Map/WorldMapView.swift` - 4x32 grid of all 128 rooms using Canvas
- `World Map/RoomPreviewCache.swift` - Thumbnail caching for world map
- `Room Editor/RoomEditorView.swift` - Detailed editor with zoom (1x-8x) and edit modes
- `Room Editor/RoomCanvas.swift` - High-performance Canvas-based room renderer
- `Room Editor/MetatileImageCache.swift` - CGImage caching system for metatiles
- `Room Editor/TileInspectorView.swift` - Displays tile properties and indices
- `Room Editor/TilePaletteView.swift` - Tile selection interface

### ROM Format Implementation
- **Mapper**: MMC3 (mapper 4) verification at `ROMFile.swift:41-45`
- **Banks**: 16 PRG banks (8KB each) + 8 CHR banks (8KB each)
- **Room Structure**: 1024 bytes total
  - `0x000-0x2FF`: Terrain data (64x12 bytes, column-major layout)
  - `0x300`: Metatile page index (0-15)
  - `0x301`: Enemy CHR page
  - `0x302-0x303`: Room CHR pages
  - `0x320-0x3BF`: Enemy data (9 enemies × 16 bytes)
  - `0x3E0-0x3FF`: Palette data (8 palettes × 4 colors)


## Current Implementation Status

### ✅ Fully Implemented
- ROM loading with iNES header validation
- Complete CHR tile decoding pipeline (4096 tiles from 8 banks)
- Room data parsing (128 rooms from banks 0-8)
- Metatile system (16 pages × 64 metatiles)
- World map view with all 128 rooms
- Room editor with paint mode and zoom controls
- Undo/redo system with change grouping
- Save functionality writing changes back to ROM
- Keyboard shortcuts (Cmd+Z/Shift+Cmd+Z for undo/redo)

### 🚧 Partially Implemented
- Tile selection and inspection UI
- Edit mode toggle with brush selection
- Drag-to-paint interface

### ⏳ Not Yet Implemented
- Enemy editor interface (models exist, no UI)
- Palette editor (data structures ready, no UI)
- Advanced room properties editing
- Batch operations and room copying

## Development References

### Documentation

- ROM map: ./ROMMAP.MD
