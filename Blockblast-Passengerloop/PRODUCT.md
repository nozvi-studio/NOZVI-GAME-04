# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack
Flutter (Dart 3.x), CustomPainter 2.5D procedural canvas engine, SharedPreferences, Audioplayers

## Users
Casual mobile gamers seeking satisfying spatial puzzle-solving blended with charming kawaii pet collection and progression. Players typically engage in short 3-10 minute sessions on mobile phones during commutes, breaks, or leisure.

## Product Purpose
Block Odyssey: Pet Express combines 8x8 block puzzle mechanics (Block Blast style) with an active bus passenger queue management loop (Bus Jam style). Players place polyomino blocks representing adorable pets onto an 8x8 board; clearing complete lines sends the freed pets hopping via parabolic Bezier curves onto color-matching buses, freeing up space to maintain win streaks and progress through 200 saga levels.

## Positioning
Unlike conventional single-loop block puzzle games (e.g. Block Blast, Tetris) or static bus parking games (e.g. Bus Jam), Block Odyssey connects line-clearing directly to public transit logistics: clearing lines doesn't merely score points—it extracts color-coded passengers, routes matching pets onto departing express buses, and demands strategic management of a 5-seat Holding Dock before gridlock occurs.

## Operating Context
- Form Factor: Mobile portrait 9:16 aspect ratio (responsive flexi-upscale from 360x780 to modern tablets).
- Touch Ergonomics: Single-thumb or index-finger drag with negative touch Y-offset (-70dp) so player fingers never obscure block shapes while placing on the grid.
- Offline Capability: 100% playable offline without mandatory network connection; all 2.5D graphics rendered procedurally via Canvas without external sprite sheet downloads.

## Capabilities and Constraints
- 4 Fixed Vertical Screen Zones: Top Bus Station (Zone A, 22%), Holding Dock 5/6 seats (Zone B, 10%), 8x8 2.5D Wooden Game Board (Zone C, 48%), and Bottom Tray with 3 shape slots & Relic action buttons (Zone D, 20%).
- 5 Pet Species & Colors: Red Corgi, Yellow Cat, Blue Duck, Green Rabbit, Orange Fox.
- Special Grid Hazards: 2-layer Ice blocks, countdown Bomb blocks, expanding Vine tiles, Stone obstacles.
- Strategic Relics: Hammer of Fire (clears 3x3 area) and Compass of Wind (rotates tray blocks 90°).
- Progression Meta: 200-level Saga Map, 3-Star victory ratings, Super Bus Win Streak bonuses (VIP seats, Rainbow Express buses), Pet Sanctuary Idle Island, and Bus Rush Race mode.
- Non-negotiable constraint: Global physics and core board rules remain locked; 60fps Ticker-driven idle breathing and blinking animations run continuously.

## Brand Commitments
- Visual Aesthetic: "Kawaii Toy Diorama" — tactile 2.5D wooden board, rich volumetric blocks with shadow lips, vibrant cheerful palette (warm green park, amber wood, pastel pet faces), no flat generic vector colors.
- Audio Identity: Pentatonic scale sound effects with musical harmony feedback on line combos and pet boarding.
- Tone: Wholesome, friendly, rewarding, zero punitive stress.

## Evidence on Hand
- `d:\ASOL-Casual Game\Blockblast-Passengerloop\AGENT_SPEC.md`: Full game specifications and 7-step sequence execution rules.
- Fully operational Flutter codebase with 24 passing unit and widget tests across 360x780 mobile viewports.
- Procedural `Kawaii25DRenderer` and `CommercialGameController`.

## Product Principles
1. Tactile Toy Fidelity: Every interactive element feels like a polished wooden toy or glossy jelly block with physical weight, soft shadows, and subtle responsive bounce.
2. Immediate Visual Cause-and-Effect: Placing blocks, clearing lines, and passenger boarding must feature distinct, uninterrupted animation steps with parabolic flight curves.
3. Accessible Mobile-First Ergonomics: 100% one-hand reachable controls, touch offset during block dragging, and zero UI overflow on compact screens.
4. Generous Rewarding Progression: Combos, win streaks, and 3-star victories shower tactile coins, stars, and unlockable sanctuary habitats.

## Accessibility & Inclusion
- High color-contrast pairing for pet block faces (distinct facial silhouettes: Corgi pointy ears, Cat whiskers, Duck beak, Rabbit long ears, Fox snout) ensuring colorblind accessibility beyond color alone.
- Haptic feedback with subtle vibration clicks on grid cell hover, medium impact on placement, and heavy impact on line blast.
- Motion toggle and sound volume controls in pause modal.

