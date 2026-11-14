# FLUTTER PROJECT SPEC: BLOCK ODYSSEY - PET EXPRESS (2.5D MOBILE PUZZLE)

## 1. TECH STACK & ARCHITECTURE RULES
- **Framework:** Flutter (Dart 3.x), Portrait Mobile Orientation locked (`SystemChrome.setPreferredOrientations`).
- **Rendering Engine:** Use high-performance `CustomPainter` driven by a single `Ticker` (`SingleTickerProviderStateMixin`) for the 2.5D game board, bus road, and Bezier jumping pets, combined with Flutter Widgets (`Stack`, `SafeArea`, `LayoutBuilder`) for HUD and Relic buttons.
- **Zero-Asset Dependency:** All 2.5D blocks, cute pet faces (Corgi, Cat, Duck, Rabbit, Fox), buses, wooden board, and hazards MUST be drawn procedurally using Flutter `Canvas` (`drawRRect`, `Path`, `LinearGradient`, `MaskFilter.blur`) so the app runs 100% out-of-the-box without broken external image assets.
- **Strict Decoupling:** Game logic (`lib/logic/`) must be pure Dart classes with zero `dart:ui` or `flutter/material.dart` imports, communicating with the View layer via a typed `GameEventBus` and an asynchronous `PriorityActionQueue`.

## 2. 2.5D VISUAL LAYOUT (MOBILE PORTRAIT 9:16 FLEXI-UPSCALE)
Inside `SafeArea` and `LayoutBuilder`, divide available height `H` into 4 zones:
- **Zone A - Top Bus Station (22% H):**
  - Curved road background with green park scenery and trees.
  - Top-right pill badge showing `Score` + Trophy icon.
  - **Active Bus** stopped at station (e.g., Red "Corgi Express" `3/4` with visible pet heads inside windows).
  - **Next Bus** queued on the right edge (e.g., Yellow "Cat Bus").
- **Zone B - Holding Dock (10% H):**
  - A 2.5D wooden park bench labeled `Holding Dock` with **5 distinct seat slots** right below the road.
- **Zone C - 2.5D 8x8 Wooden Board (48% H):**
  - Centered square wooden tray with recessed 3D inner shadow and $8 \times 8$ dark-brown grid slots.
  - **2.5D Pet Block Drawing Specification:**
    - Draw bottom 3D extrusion lip (`RRect` shifted down by `6px` in darker color) + top main `RRect` + cute vector pet face:
      - `PetColor.red` = Corgi (pointy ears, white snout blaze, cute nose).
      - `PetColor.yellow` = Cat (triangle ears, whiskers, happy eyes).
      - `PetColor.blue` = Duck (orange oval bill, top tuft).
      - `PetColor.green` = Rabbit (long upright ears, pink nose).
      - `PetColor.orange` = Fox (white cheek fur, pointy ears).
  - **Hazard Overlays:** `Stone` (cracked gray 2.5D rock), `Ice` (translucent cyan `RRect` with white diagonal gloss, 2 HP), `Bomb` (black sphere with burning fuse + turn counter badge), `Vine` (green thorny border).
- **Zone D - Control & Spawn Deck (20% H):**
  - Left Circular Skill Button: **Búa Rèn Lửa** (Hammer icon, charge badge, destroys $3 \times 3$ cells).
  - Center `Next` Tray: Rounded green dock holding 3 draggable polyomino shapes.
  - Right Circular Skill Button: **La Bàn Gió** (Compass icon, charge badge, rotates all 3 shapes in tray by 90°).

## 3. DETERMINISTIC 7-STEP PRIORITY ACTION QUEUE (DART ASYNC)
When a block is dropped on a valid $8 \times 8$ position, lock pointer input and run sequentially:
1. `placeBlock`: Commit polyomino cells to `GridMatrix`, trigger squash-and-stretch animation (`120ms`).
2. `evaluateLines`: Scan all 8 rows and 8 columns simultaneously for full lines.
3. `extractPassengers`: Collect all pets from cleared cells. **CRITICAL SORT:** Pets matching `activeBus.color` MUST be placed at the front of the list before off-color pets.
4. `boardAndDock`:
   - Spawn parabolic Bezier jump animations (`380ms`, `Curves.easeOutBack`) from grid cell to target.
   - Matching pets jump directly into `activeBus`. When `activeBus` reaches capacity, animate it driving left off-screen, slide `nextBus` in, and immediately board any matching pets waiting in `holdingDock`.
   - Non-matching pets jump into empty `holdingDock` slots (max 5).
5. `updateHazards`: Decrement Bomb timers (explode $3 \times 3$ into Stone/Ice if 0); spread Vines by 1 adjacent cell if no line was cleared for 2 consecutive turns.
6. `chargeRelics`: Add charges to `Búa Rèn Lửa` (every 3 lines cleared) and `La Bàn Gió` (every 2 buses departed).
7. `evaluateGameState`: Check Win (all target buses departed), Lose by Dock Jam (`holdingDock.length > 5`), or Lose by Grid Lock (no remaining shape in tray fits anywhere on $8 \times 8$ board, factoring in Mercy Rule). Unlock input.
## 5. RETENTION, HAPTICS, REVIVE & META-GAME ARCHITECTURE
- **Multi-Layered Haptics (`flutter/services.dart`):**
  - Grid cell hover change during drag: `HapticFeedback.selectionClick()`.
  - Valid block placement: `HapticFeedback.mediumImpact()`.
  - Line clear / Combo / Relic activation: `HapticFeedback.heavyImpact()`.
  - Pet boarding bus: `HapticFeedback.lightImpact()` synced with pentatonic note.
- **Win Streak System ("Super Bus Streak" - Tiers 0 to 3):**
  - Persisted in `SharedPreferences`. Increments on Level Win, resets to 0 on Level Quit/Lose (unless revived).
  - **Tier 1 (1 Win):** Start level with +1 pre-charged `La Bàn Gió`.
  - **Tier 2 (2 Wins):** Expand `HoldingDock` capacity from 5 to **6 slots** (renders a 6th golden VIP seat).
  - **Tier 3 (3+ Wins):** All Tier 1-2 buffs + the first `ActiveBus` of the level becomes a **Rainbow Express** (accepts ANY pet color) + 1 pre-charged `Búa Rèn Lửa`.
- **Pinch-Point Revive System (Dual Lose Recovery Modal):**
  - Before resetting Win Streak on Game Over, display a high-conversion `ReviveModal` showing the player's current Win Streak at risk:
    - **If Lost by Dock Overflow (`HoldingDock` jammed):** Offer *"Trực Thăng Giải Cứu"* (Clears 3 pets from `HoldingDock` immediately + permanently unlocks +1 VIP seat for the rest of the match).
    - **If Lost by Grid Lock (No valid 8x8 moves):** Offer *"Đội Cứu Hộ Khẩn Cấp"* (Clears the 2 most crowded rows on the $8 \times 8$ board + converts all 3 shapes in `Next` tray into $1 \times 1$ single pet blocks matching `ActiveBus.color`).
- **2.5D Pet Sanctuary (Idle Diorama Meta) & Bus Rush Race:**
  - Every departed bus adds rescued pets and Coins to player profile.
  - **Sanctuary Screen:** A procedural 2.5D park island where rescued Corgis, Cats, Ducks, Rabbits, and Foxes walk/hop around unlocked landmarks (*Quán Cà Phê Mèo*, *Bãi Biển Corgi*, *Hồ Vịt Vàng*) and generate passive Coins over time.
  - **Bus Rush Race (Micro-LiveOps):** A real-time race tracker widget (Player vs 4 adaptive bots) competing to be the first to dispatch 15 buses for a Grand Relic Chest.