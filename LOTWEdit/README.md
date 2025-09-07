# LOTW Editor - Legacy of the Wizard ROM Editor

A native macOS application for editing Legacy of the Wizard NES ROM files.

## Current Status - Milestone 1 Complete

### ✅ Implemented Features

- **ROM Loading**: Full iNES format validation with MMC3 mapper verification
- **CHR Tile Decoding**: Proper NES 2-bitplane CHR tile decoding  
- **Room Data Parsing**: Complete 1024-byte room structure parsing
- **World Map View**: Displays all 128 rooms in 4x32 grid
- **Room Editor View**: Detailed room display with metatiles
- **Tile Inspector**: Click tiles to see metatile index, palette, and color values

### 🎯 Verified Functionality

- ✅ Project builds without errors
- ✅ ROM file validation works (tested with LOTW.nes)
- ✅ CHR tile decoder produces correct 8x8 pixel arrays
- ✅ Room data parses correctly (768 terrain + 256 metadata bytes)
- ✅ All models and views are properly wired

## Building and Running

### Requirements
- macOS 14.5 or later
- Xcode 15 or later
- Legacy of the Wizard NES ROM file

### Build from Command Line
```bash
xcodebuild -project LOTWEdit.xcodeproj -scheme LOTWEdit build
```

### Run from Xcode
1. Open `LOTWEdit.xcodeproj` in Xcode
2. Press Cmd+R to build and run
3. Use File → Open ROM (Cmd+O) to load a LOTW ROM file

## Testing

A test ROM file is available at `/Users/angelo/devlocal/lotw-editor/LOTW.nes`

### Manual Testing Checklist

1. **Open ROM**: File → Open ROM → Select LOTW.nes
2. **World Map**: Should display 128 rooms in a 4x32 grid
3. **Room Selection**: Click any room in the world map
4. **Room Detail**: Selected room should display with proper graphics
5. **Tile Inspector**: Click tiles in the room view to see properties
6. **Zoom Control**: Adjust zoom slider to change room view scale

## Architecture

### Data Flow
1. ROM file loaded via `ROMFile.swift`
2. Data parsed by `LOTWROMData.swift` 
3. Rooms extracted with `Room.swift`
4. CHR tiles decoded via `CHRTile.swift`
5. Graphics rendered using NES palette from `NESPalette.swift`

### Key Components
- **Models**: ROM data structures and parsing logic
- **Views**: SwiftUI interface components
- **World Map**: Overview of all 128 game rooms
- **Room Editor**: Detailed view with tile-level editing

## Next Steps (Milestone 2)

- [ ] Implement undo/redo system
- [ ] Add tile placement/editing
- [ ] Create save functionality
- [ ] Add tile palette selector

## Known Issues

- Graphics rendering may need refinement for exact game accuracy
- Performance optimization needed for large-scale editing

## Development Notes

See `/Users/angelo/devlocal/lotw-editor/ai/plans/lotw-editor-implementation.md` for the complete implementation plan and technical details.