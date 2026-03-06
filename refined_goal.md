# LifeForge – iOS Game Based on Conway's Game of Life

## Project Goal
Build a modern, addictive iOS game inspired by Conway's Game of Life (classic B3/S23 rules), but enhanced with progression, resource management, breeding mechanics, light proximity-based social features, and monetization hooks — while preserving the hypnotic, emergent beauty of cellular automata.

The game should feel like a living mathematical ecosystem that players "forge" and nurture.  
Target: Fully AI-generated codebase → eventual App Store release.  
UI framework: SwiftUI (primary)  
Rendering: SwiftUI Canvas for MVP, Metal later for performance & visual polish  
Minimum iOS version: 17+  
Dependencies: Minimal (ideally none at first; MultipeerConnectivity only for optional proximity later)

## Thematic Nomenclature (use consistently in code, UI strings, comments)
- Grid → EvoMatrix (toroidal / wrap-around by default)  
- Cells → VitaCells  
- Starting pattern / seed → VitaSeed  
- Detected pattern → Emergent Form  
- Breeding mini-grids → EvoChambers  
  - Entry → Seed Nursery  
  - Mid-tier → Pattern Forge  
  - Advanced → Symbiotic Crucible  
- Simulation step → EvoCycle  
- Earned resource → VitaEssence  
- Premium currency → EvoCrystals  
- Proximity multiplayer → Symbiotic Fusion  
- Unlocked power → VitaRelic  

## Core Gameplay Loop
1. Plant VitaSeeds (tap to place/toggle cells or load patterns)  
2. Run EvoCycles (manual step, slow auto, or spend VitaEssence for bursts)  
3. Watch population grow → detect Emergent Forms (gliders, oscillators, guns, etc.) → earn rewards  
4. Breed more complex / rare forms in side EvoChambers → release them to the main EvoMatrix  
5. Earn VitaEssence from births, form detections, daily login/streaks  
6. Spend VitaEssence on speed, breeding acceleration, chamber upgrades  
7. Progress through levels → unlock larger matrix, better chambers, new VitaRelics  
8. Optional: Symbiotic Fusion with nearby players (via MultipeerConnectivity)

## Key Mechanics (MVP priority)
- **EvoMatrix**: toroidal grid (start with 60–100 cells wide, zoomable/pannable)  
- **Simulation rules**: Standard Conway B3/S23  
- **VitaEssence economy**:  
  - Earn from: population growth, Emergent Form detections, daily streaks  
  - Spend on: fast-forward cycles, accelerate EvoChambers, premium actions  
- **EvoChambers**: 1–2 side mini-grids (smaller size, possibly different speeds/costs)  
- **Emergent Form detection**: Recognize at least gliders, blinkers, toads, lightweight spaceships, Gosper glider gun (stubbed or simple pattern matching at first)  
- **Basic UI layout**:  
  - Central EvoMatrix view  
  - Bottom controls: VitaEssence counter, step button, speed slider  
  - Slide-out or tab for Seed Nursery / Pattern Forge  
  - Top bar: level / streak / EvoCrystals  
- **Polish elements**: smooth birth/death animations, haptics on key events, subtle ambient sound hints

## Tech Preferences
- SwiftUI + Canvas for initial grid rendering (simple shapes / rectangles / circles for cells)  
- Later upgrade path: Metal for large grids, glows, particle trails  
- Use modern Swift: actors for simulation concurrency, @Observable for state  
- Save state with UserDefaults (grid snapshots, essence, progress)  
- Clean, well-commented code with meaningful names matching the theme

## Monetization (awareness only, not MVP critical)
Free core experience, patient play viable.  
Future IAP: VitaSeed packs, EvoCrystal bundles, ad removal, premium chambers.

Please use this full game concept to start building the initial Swift files for a minimal but runnable prototype.  
Focus on making it feel like LifeForge from the very first version — use the thematic names, include basic simulation, tap interaction, resource counter, and a simple auto-evolve loop.

Start generating code when you're ready.
