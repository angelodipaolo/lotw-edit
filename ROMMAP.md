# Legacy of the Wizard – ROM Map

Download from [Data Crystal](https://datacrystal.tcrf.net/wiki/Legacy_of_the_Wizard/ROM_map)

## Contents

- [1. PRG Banks](#prg-banks)  
- [2. Map Format](#map-format)  
  - [2.1 Tiles](#tiles)  
  - [2.2 Music](#music)  
  - [2.3 Items](#items)  
  - [2.4 Enemies](#enemies)  
  - [2.5 Other](#other)  
  - [2.6 Dragon](#dragon)  
- [3. Title Screen](#title-screen)  
- [4. Credits](#credits)  

## PRG Banks

- 8 KB MMC3 banks:
  - $0–8 – $00000–$1FFFF: Level maps  
  - $9–9 – $12000–$13FFF: Metatile sets, dragon map  
  - $A–B – $14000–$17FFF: Music, unused title screen  
  - $C–D – $18000–$1FFFF: Music, title screen, code, credits  
  - $E–F – $1C000–$1FFFF: Fixed upper bank, code  

## Map Format

- Each 1 KB of PRG in the map banks represents a single 4‑screen map in the dungeon.
- Structure of each map’s bytes:
  ```
  $000–2FF – 64 columns of 12 tiles each  
  $300 – Metatile Page  
  $301 – Enemy CHR (PPU $1400)  
  $302 – Secret Wall Tile  
  $303 – Secret Wall Replacement  
  $304 – Block Replacement  
  $305 – Terrain CHR 0 (PPU $0000)  
  $306 – Terrain CHR 1 (PPU $0800)  
  $307 – Treasure Active (1 = active)  
  $308 – Treasure X (grid 0–63)  
  $309 – Treasure Y (pixel 0–191)  
  $30A – Treasure Contents (0–23)  
  $30B – Music track (0–15)  
  $30C – Celina Teleport Map X (0–3)  
  $30D – Celina Teleport May (sic) Y (0–17)  
  $30E – Celina Teleport Player X (grid 0–63)  
  $30F – Celina Teleport Player Y (pixel 0–191)  
  $310 – Shop Item 0 (0–15)  
  $311 – Shop Price 0  
  $312 – Shop Item 1  
  $313 – Shop Price 1  
  $314 – Demo Bitfield  
  $315 – Music Control Bitfield  
  $316 – Unused*  
  $320–3AF – 9 × 16-byte enemy data entries:  
     $3X0 – First Sprite Index  
     $3X1 – Draw Attribute  
     $3X2 – Position X (grid 0–63)  
     $3X3 – Position Y (0–191)  
     $3X4 – Hit Points  
     $3X5 – Damage  
     $3X6 – Death Sprite Index  
     $3X7 – Animation Style  
     $3X8 – Behaviour (0–8)  
     $3X9 – Speed  
  $3E0–3FF – Palette  
  ```
- All unlisted bytes are always filled with 0.

### Tiles

- Map grid: one byte per tile  
- High 2 bits: palette selection  
- Low 6 bits: metatile index from the metatile page  
- Metatile functions:
  - $00 – Ladder  
  - $01 – Shop or Inn door (requires sign above to function)  
  - $02 – Locked door  
  - $03 – Celina portrait  
  - $04 – Shop sign  
  - $05 – Inn sign  
  - $06–2F – Open space  
  - $30 – Spike  
  - $31–3D – Solid  
  - $3E – Movable block  
  - $3F – Solid  
- Metatile pages are in bank 9. Each page has 64 entries (4 bytes each), representing two columns of terrain CHR.
- Secret tile: replaced when touched; new tile applies new palette  
- Replacement use cases:
  - Open→Open: player falls through  
  - Solid→Open: pushable block/movable  
  - Inn→Shop: touching sign converts inn to shop  
- Block replacement: tile under blocks/locked doors when moved/destroyed  
- Metatile pages $05, $08, $0A, $0B appear unused—possibly leftovers  

### Music

- Music track mapping:
  - 0 – Dungeon  
  - 1 – Xemn  
  - 2 – Meyna  
  - 3 – Lyll  
  - 4 – Pochi  
  - 5 – Dragon  
  - 6 – Inn  
  - 7 – Shop  
  - 8 – Death  
  - 9 – Title  
  - 10 – Credits  
  - 11 – Boss  
  - 12 – Home  
- Music Control Bitfield: prevents switching music if currently playing track is in bitfield (only for first 8 tracks). Bits correspond to tracks in order.

### Items

- Shop items (matching inventory screen order):
  0 – Wings  
  1 – Armour  
  2 – Mattock  
  3 – Glove  
  4 – Rod  
  5 – Power Shoes  
  6 – Jump Boots  
  7 – Key Stick  
  8 – Power Knuckle  
  9 – Winged Rod  
  10 – Shield  
  11 – Magic Potion  
  12 – Elixer  
  13 – Crystal Ball  
  14 – Crown  
  15 – Dragonslayer  

- Treasure items (8 extra):
  - 0 – Bread  
  - 1 – Magic  
  - 2 – Gold  
  - 3 – Poison  
  - 4 – Key  
  - 5 – Ring  
  - 6 – Cross  
  - 7 – Scroll  
  - 8+ – Same as shop if subtract 8 (e.g., 8 → wings, etc.)

### Enemies

- Each map always contains 9 enemies (cannot be removed) — can be made inactive/offscreen  
- Sprite index: NES tall-sprite index (commonly $41, $51, $61, $71)  
- Draw attribute: NES sprite attribute byte; low 2 bits = palette; bit 5 = draw behind background and immune until touched  
- Enemies persist even at 0 HP — they die when HP drops below 0  
- Animation styles:
  - 0 – always sprite 0, flip horizontally  
  - 1 – switch between sprites 0 and 1  
  - 2 – like 1, but use sprite 2 when moving vertically (flipped)  
  - 3 – cycle sprites 0 → 1 → 2 → 3  
- Behaviour types (0–8):
  - 0 – Wander, jump  
  - 1 – Fly in a line  
  - 2 – Walk on ground  
  - 3 – Follow player, jump  
  - 4 – Fly toward player  
  - 5 – Ceiling crawl  
  - 6 – Sleeping lion/mimic  
  - 7 – Fly random line  
  - 8 – Boss projectile  
- Bosses: consist of 4 enemy slots; first slot’s HP and damage are used. Some bosses remain at high HP (esp. >99) and the life bar doesn't visibly drop until below 99.

### Other

- Demo Bitfield: controls which family members appear in random title-screen demo (bits 0–4 correspond to Xemn, Meyna, Roas, Lyll, Pochi)  
- Unused field $316: non-zero in only two maps; likely unused. In shops, $315 and $316 influence offscreen tile drawing, probably vestigial  
- Inn uses wrong metatile page $1F instead of the one specified; appears with the home interior  

### Dragon

- Stored as a special map in bank 9, starting at PRG $13800  
- Contains 4 dragon renderings as tiles; metatile pages $10–17 allow selection between 8 different dragon images  

## Title Screen

- Spans banks $C and $D at PRG $19EC9  
- First 1 KB: NES nametable  
- Next 32 bytes: NES palette  
- Final 2 bytes: two CHR pages for background  
- Unused alternate title screen at PRG $17BCA; appears unfinished with no valid CHR page  

## Credits

- Stored at PRG $1B79C (Legacy of the Wizard) or $1B7AA (Dragon Slayer IV)  
- Plain ASCII text; newlines marked by byte $0D; followed by zero padding  

*(Last edited on 24 January 2024)*
