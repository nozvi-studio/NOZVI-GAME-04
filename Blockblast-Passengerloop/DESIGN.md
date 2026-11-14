---
name: "Block Odyssey: Pet Express"
description: "2.5D Mobile Puzzle Toy Diorama combining 8x8 block clearing with bus passenger logistics"
colors:
  park-grass-start: "#88D45E"
  park-grass-end: "#5BB344"
  board-wood-outer: "#6D4226"
  board-wood-rim: "#9E633A"
  board-wood-highlight: "#C48354"
  board-grid-well: "#4A2E1B"
  board-cell-empty: "#3B2314"
  board-cell-border: "#6B442A"
  corgi-red: "#FF6B5B"
  corgi-red-end: "#E84538"
  corgi-red-dark: "#A82419"
  cat-yellow: "#FFD84D"
  cat-yellow-end: "#F5B727"
  cat-yellow-dark: "#B87D0E"
  duck-blue: "#4FC3F7"
  duck-blue-end: "#1E90FF"
  duck-blue-dark: "#0D5CA8"
  rabbit-green: "#81E659"
  rabbit-green-end: "#4BC226"
  rabbit-green-dark: "#2D8512"
  fox-orange: "#FF9D42"
  fox-orange-end: "#E86F17"
  fox-orange-dark: "#9E4105"
  bus-road-surface: "#455A64"
  bus-road-border: "#263238"
  bus-road-marking: "#FFD84D"
  bus-window-tint: "#B3E5FC"
  dock-wood-bench: "#D7CCC8"
  dock-seat-slot: "#8D6E63"
  relic-fire-glow: "#FF3D00"
  relic-wind-glow: "#00E5FF"
  hud-coin-gold: "#FFD700"
  hud-gem-ruby: "#E91E63"
typography:
  display:
    fontFamily: "-apple-system, Roboto, BlinkMacSystemFont, sans-serif"
    fontSize: "32px"
    fontWeight: 900
    lineHeight: 1.1
    letterSpacing: "0.5px"
  headline:
    fontFamily: "-apple-system, Roboto, BlinkMacSystemFont, sans-serif"
    fontSize: "24px"
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: "0px"
  title:
    fontFamily: "-apple-system, Roboto, BlinkMacSystemFont, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "0px"
  body:
    fontFamily: "-apple-system, Roboto, BlinkMacSystemFont, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "0px"
  label:
    fontFamily: "-apple-system, Roboto, BlinkMacSystemFont, sans-serif"
    fontSize: "12px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0.5px"
rounded:
  sm: "6px"
  md: "10px"
  lg: "16px"
  xl: "24px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
components:
  relic-fab:
    backgroundColor: "{colors.board-wood-outer}"
    textColor: "#FFFFFF"
    rounded: "{rounded.full}"
    size: "56px"
  tray-slot:
    backgroundColor: "{colors.board-cell-empty}"
    rounded: "{rounded.md}"
    padding: "8px"
  pill-badge:
    backgroundColor: "{colors.bus-road-border}"
    textColor: "#FFFFFF"
    rounded: "{rounded.full}"
    padding: "4px 12px"
---

# Design System: Block Odyssey: Pet Express

## Overview

**Creative North Star: "The Handcrafted Kawaii Toy Diorama"**

Block Odyssey: Pet Express exists in a warm, miniature tactile world. The interface evokes a handcrafted wooden puzzle tray placed on the lush grass of a sunny public park, complete with miniature toy buses rolling along a curving asphalt lane and glossy animal puzzle pieces that breathe and blink with gentle, living character. Every element communicates physical mass, polished edges, and tactile delight rather than flat digital minimalism.

The visual system rejects harsh sterile grays, flat unshaded polygons, and generic vector emoji faces. Instead, it commits to a warm, organic palette of sun-drenched lawn greens, rich teak woodgrain, and appetizing pastel candy tones for its five signature pet characters (Corgi, Cat, Duck, Rabbit, Fox). Depth is never an afterthought; it is established through procedural 2.5D extrusion rims, glossy specular arcs, and soft contact shadows rendered natively via Flutter's `Canvas`.

**Key Characteristics:**
- **Warm Miniature Tactility:** Thick beveled wooden board borders, recessed inner shadows, and chunky extrusion lips on every block.
- **Organic Character Vitality:** 60fps procedural breathing, rhythmic blinking, and parabolic Bezier jumping arcs give life to inanimate blocks.
- **Zero-Asset Procedural Autonomy:** 100% vector-drawn on Flutter Canvas (`drawRRect`, `Path`, `LinearGradient`), ensuring pixel-perfect fidelity across any screen DPI without download latency.
- **Ergonomic Touch Clarity:** Negative touch Y-offset (`-70dp`) guarantees that the player's dragging thumb never obscures block geometry.

---

## Colors

The palette balances warm earthen wood tones with cheerful, highly-saturated toy pigments. Each pet color features three distinct tonal values: an illuminated top gradient start, an anchor primary tone, and a darkened extrusion lip.

### Primary Pet Hues
- **Corgi Red** (`#FF6B5B` top, `#E84538` base, `#A82419` lip): Radiant coral-red representing lively energetic puppies. Paired with soft pink cheek blush (`#FF9E99`).
- **Cat Yellow** (`#FFD84D` top, `#F5B727` base, `#B87D0E` lip): Golden sunny amber representing cheerful curious kittens. Paired with peach blush (`#FF8A80`).
- **Duck Blue** (`#4FC3F7` top, `#1E90FF` base, `#0D5CA8` lip): Crystal sky blue representing bubbly water birds. Paired with bright orange bill accents (`#FF9800`).
- **Rabbit Green** (`#81E659` top, `#4BC226` base, `#2D8512` lip): Vivid spring mint representing nimble garden bunnies. Paired with soft rose inner ears (`#FFB2C1`).
- **Fox Orange** (`#FF9D42` top, `#E86F17` base, `#9E4105` lip): Rich apricot orange representing clever woodland foxes. Paired with warm cream cheeks (`#FFF5EB`).

### Environmental & Structural Tones
- **Sunny Park Meadow** (`#88D45E` top to `#5BB344` bottom): Fullscreen background linear gradient providing an uplifting, natural game setting.
- **Teak Board Frame** (`#6D4226` base, `#9E633A` rim, `#C48354` highlight): Multi-layered beveled wood rim creating physical boundary and immersion.
- **Recessed Grid Well** (`#4A2E1B` shadow, `#3B2314` cell fill, `#6B442A` cell border): Dark concave tray where empty slots appear carved directly into the wood.
- **Asphalt Express Lane** (`#455A64` roadbed, `#263238` curb, `#FFD84D` dashed stripe): Miniature highway running across Zone A.
- **Holding Dock Wood Bench** (`#D7CCC8` seat slat, `#8D6E63` groove): Weathered park bench anchoring 5 (up to 6 VIP) passenger waiting slots.

### Named Rules
**The Volumetric Contrast Rule.** Every pet block and toy bus MUST render a bottom extrusion lip shifted `6px` vertically in its assigned dark tonal shade (`darkColor`). Flat un-extruded shapes are strictly forbidden on the game board.

**The Silhouette Redundancy Rule.** Colors must never be the sole differentiator of pet species. Every pet block must carry a distinctive vector silhouette (Corgi pointed triangular ears with white blaze; Cat rounded whisker triangles; Duck orange oval bill; Rabbit elongated vertical ears; Fox angular cheek tufts) to guarantee universal colorblind accessibility.

---

## Typography

**Display & Headline Font:** Native System Sans-Serif (SF Pro on iOS, Roboto on Android) with maximum bold weights (`FontWeight.w900` / `FontWeight.w800`) and slight tracking.

**Body & Label Font:** Native System Sans-Serif with medium/bold weights (`FontWeight.w600` / `FontWeight.w700`).

**Character:** Bold, rounded, and celebratory. Numeric score counters and combo multipliers leap forward with drop-shadowed white numerals and golden metallic badges.

### Hierarchy
- **Display** (Heavy `w900`, `32px`, `1.1` line height): Combo callouts (`COMBO x3!`), victory banners, star ratings.
- **Headline** (Extra-bold `w800`, `24px`, `1.2` line height): Screen titles, modal headers (`Level Complete!`, `Paused`).
- **Title** (Bold `w700`, `18px`, `1.3` line height): Section headings, bus name headers (`Corgi Express`), quest card titles.
- **Body** (Medium `w500`, `14px`, `1.4` line height): Level objectives, dialog messages, tutorial instructions.
- **Label** (Bold `w700`, `12px`, `0.5px` tracking, uppercase): Passenger counters (`3/4`), button labels (`SKIP`, `REVIVE`, `SHOP`).

### Named Rules
**The Floating Value Rule.** Floating score popups (`+150`, `FEVER!`) MUST render with a `2px` dark stroke (`#263238`) or heavy blur shadow to preserve legibility over diverse board colors during rapid combos.

---

## Layout

**Spatial Model: The 4-Zone Fixed Ratio Architecture (Portrait 9:16 Flexi-Upscale)**
Inside Flutter's `SafeArea` and `LayoutBuilder`, total available height $H$ is apportioned into four non-overlapping functional zones:

1. **Zone A - Top Bus Station (22% H):**
   - Curving asphalt highway across top with dashed center stripe.
   - Active Bus docked on left, with window counters (`3/4`) and passenger heads visible inside.
   - Queued Bus waiting on the right edge.
   - Top-right HUD Pill displaying current score and trophy icon.

2. **Zone B - Holding Dock (10% H):**
   - 2.5D wooden park bench centered horizontally with 5 distinct seat slots (expands to 6 with VIP Streak Level 2).
   - Overflow pinch point: full dock locks gameplay and triggers revive danger modal.

3. **Zone C - 8x8 Wooden Board Tray (48% H):**
   - Centered square board with 8x8 cells. Cell size $S = \min(\text{width} - 32, 0.48H) / 8$.
   - Procedural rendering of empty slots, placed blocks, special hazards (Ice, Bomb, Vine, Stone), and line blast highlights.

4. **Zone D - Next Tray & Relics (20% H):**
   - Horizontal tray hosting 3 polyomino slots scaled at `0.62x` rest scale.
   - Flanked by two circular Relic skill buttons: Hammer of Fire (bottom-left) and Compass of Wind (bottom-right).

### Ergonomic Touch Offset
- When dragging a polyomino block from Zone D onto Zone C, an offset of `touchOffsetY = -70.0dp` is automatically applied. The block floats directly above the finger contact point so the player has 100% unobstructed visibility of grid alignment.

---

## Elevation & Depth

Depth in Block Odyssey is structural and tactile. Surfaces never rely on arbitrary fuzzy Photoshop dropshadows; depth is forged through geometric extrusion:

- **Toy 2.5D Lip:** Every cell has a top face and a bottom lip shifted down by `6px`. When drawn, the lip is painted first with `darkColor`, followed by the top face with `topGradientStart -> topGradientEnd`.
- **Specular Highlight Arc:** Across the top 30% of each block, an elliptical arc is drawn with `Colors.white.withOpacity(0.3)` to evoke glossy molded plastic or polished lacquered wood.
- **Board Outer Shadow:** The 8x8 tray casts a directional soft shadow (`Offset(0, 10)`, `blurRadius: 18`, `Color(0x55000000)`).
- **Recessed Well Inner Shadow:** The interior playable grid features an inner top shadow simulating a sunken recess into the wooden chassis.

---

## Shapes

- **Grid Cells & Pet Blocks:** `RRect.fromRectAndRadius` with `Radius.circular(10.0)` for blocks, `6.0` for empty grid cells.
- **Wooden Board Chassis:** Outer beveled `RRect` with `Radius.circular(16.0)`.
- **Bus Chassis:** Asymmetrical vehicle contour with rounded front cowl (`18.0`), flat rear gate (`6.0`), and rounded rectangular glass windows (`6.0`).
- **Relic Buttons:** Perfect circles (`Radius.circular(9999.0)`), diameter `56dp`, with pulsating radial glow during ready state.
- **Modals & Dialogs:** `Radius.circular(24.0)` heavy corner radii with smooth internal padding.

---

## Components

### 2.5D Pet Block
- **Shape:** Rounded rectangle `10px` radius, `6px` bottom lip.
- **Facial Features:** Vector eyes with white specular catchlights, pink oval blush patches, species-specific ear/beak vectors.
- **Breathing Animation:** 60fps Ticker subtly oscillates vertical scale by $\pm 2.5\%$ with a 3.5-second sine cycle. Periodic natural eye blinks every 4–6 seconds.

### Express Bus
- **Chassis:** 2.5D extruded body colored to match target pet color (or 6-color rainbow gradient for `Rainbow Express`).
- **Windows:** 3 transparent blue glass panes (`#B3E5FC`) showing silhouettes of boarded pets.
- **Capacity Badge:** Contrasting dark pill with yellow numeric text (`3/4`).
- **Departure Motion:** On full capacity, bus shakes with engine rumble for 200ms, then accelerates rightward with easing curve (`Curves.easeInBack`).

### Holding Dock
- **Bench:** Weathered wooden plank with rounded ends and brass screw heads.
- **Slots:** 5 sunken circular depressions. Pets sitting here display slight anxious swaying, waiting for a matching bus to pull up.

### Relic Action Buttons
- **Hammer of Fire:** Circular button with flame icon; turns vibrant orange-red (`#FF3D00`) when charged (3 lines cleared). Triggers glowing crosshair targeting overlay.
- **Compass of Wind:** Circular button with wind spiral icon; turns electric cyan (`#00E5FF`) when charged (2 buses departed). Rotates all 3 tray blocks $90^\circ$ clockwise with spring animation.

### In-Game Modals (Pause, Victory, Revive)
- **Container:** Dark scrim backdrop (`rgba(0,0,0,0.65)` with backdrop filter blur `10px`), central card with wooden border and 24dp corner radius.
- **Buttons:** Chunky 3D buttons with bottom bevels, responsive depression on tap.

---

## Do's and Don'ts

### Do:
- **Do** maintain the 6px extrusion lip on every placed and dragging block to preserve the 2.5D toy diorama aesthetic.
- **Do** apply `touchOffsetY = -70.0dp` during block drag operations to prevent touch occlusion.
- **Do** draw facial silhouettes distinctly so colorblind players can identify pet types without relying on color.
- **Do** execute passenger extraction and boarding via smooth parabolic Bezier curves with pentatonic chime SFX.
- **Do** keep all interactive buttons at $\ge 48 \times 48\text{dp}$ touch target sizes on mobile.

### Don't:
- **Don't** introduce flat unshaded single-color vectors into the game board.
- **Don't** use external raster bitmap assets (`.png`, `.jpg`) for blocks or buses; all assets must be procedurally generated via Canvas.
- **Don't** allow board cells or HUD text to overflow on compact mobile viewports (minimum target $360 \times 780\text{dp}$).
- **Don't** interrupt the 7-step ActionQueue execution sequence while blocks are placing or lines are clearing.

