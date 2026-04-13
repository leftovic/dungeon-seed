# AI-Orchestrated Game Development — Vision Document

> **Author**: CGS Orchestrator
> **Date**: 2026-07-15 (updated 2026-04-12)
> **Purpose**: Blueprint for adapting the CGS agent orchestration pipeline to autonomous video game development
> **Inspiration**: "Video games that write themselves"
> **Status**: 🔄 76 ACTIVE AGENTS (31 created, 10 in-creation, 24 queued, 11 reused) — Self-contained in `neil-docs/game-dev/`
> **Infrastructure**: agent-registry.json (76 active + 2 deprecated) + workflow-pipelines.json (6 pipelines) + THIRD-PARTY-TOOLS.md + Docker strategy

---

## The Core Insight

The CGS pipeline is:
```
Vision → Decompose → Ticket → Plan → Implement → Audit → Converge
```

Game development has the SAME pipeline shape but **six parallel creation streams** that enterprise software doesn't have:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    THE SIX STREAMS OF GAME CREATION                     │
│                                                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │NARRATIVE  │ │ VISUAL   │ │  AUDIO   │ │  WORLD   │ │MECHANICS │    │
│  │story,lore │ │art,assets│ │music,sfx │ │levels,   │ │combat,   │    │
│  │characters │ │textures  │ │voice,    │ │biomes,   │ │economy,  │    │
│  │dialogue   │ │UI,VFX    │ │ambient   │ │procedural│ │progress  │    │
│  └─────┬─────┘ └─────┬────┘ └────┬─────┘ └─────┬────┘ └─────┬────┘    │
│        │              │           │              │             │         │
│        └──────────────┴───────┬───┴──────────────┴─────────────┘         │
│                               │                                          │
│                    ┌──────────▼──────────┐                               │
│                    │    TECHNICAL         │                               │
│                    │ engine, networking,  │                               │
│                    │ optimization, build  │                               │
│                    └─────────────────────┘                               │
└─────────────────────────────────────────────────────────────────────────┘
```

Each stream has its own specialist agents, but they converge through the same orchestration infrastructure (decomposition, tickets, plans, audit, convergence).

---

## The Dream Team — Agent Roster (71 Active Agents)

> **Design Principles:**
> - ALL agents are **STYLE-AGNOSTIC** — they know FORM, not style. Art style (chibi, realistic, pixel, cel-shaded, PBR) comes from the Art Director's style guide.
> - ALL asset agents output across **ALL MEDIA FORMATS**: 2D (sprites, pixel art, vector), 3D (Blender models, glTF), VR/XR (optimized, spatial), isometric (pre-rendered).
> - Game trope agents are **OPTIONAL ADDONS** — not all games need pets, crafting, or fishing. Plug in what your game needs.

### 🎮 Vision & Pre-Production (7 agents)

| Agent | What It Produces |
|-------|------------------|
| **Game Vision Architect** | Game Design Document (GDD), core loop, monetization model, platform strategy |
| **Narrative Designer** | Lore bible, character bible, quest arcs, dialogue schemas |
| **Character Designer** | Character archetypes, stat systems, progression curves, ability trees |
| **World Cartographer** | World map, biome definitions, region lore, spawn tables |
| **Game Economist** | Economy model, drop tables, crafting recipes, currency flows |
| **Game Art Director** | Style guide, color palettes, proportions — THE style authority |
| **Game Audio Director** | Music mood boards, SFX taxonomy, adaptive music rules |

### 🗿 Form Sculptors (11 agents — entity archetype specialists)

Each sculptor knows the ANATOMY, PROPORTIONS, RIGGING, and DESIGN LANGUAGE of their domain. They output in ALL media formats (2D/3D/VR/iso) based on project requirements. Style comes from the Art Director.

| Agent | Domain | Key Technical Challenges |
|-------|--------|------------------------|
| **Humanoid Character Sculptor** | Humans, elves, dwarves, orcs, anthropomorphic | Skeletal rig (69 bones), blend shapes, modular equipment slots, variant body types |
| **Beast & Creature Sculptor** | Quadrupeds, birds, reptiles, insects, mounts | Gait cycles, pack behavior, mount ergonomics, taming visual progression |
| **Eldritch Horror Entity Sculptor** | Cosmic horror, non-euclidean, body horror, lovecraftian | Intentional wrongness, partial revelation, content safety tiers, phobia tagging |
| **Undead & Spectral Entity Sculptor** | Skeletons, ghosts, wraiths, zombies, liches, vampires | Decay morph targets, ghost transparency, swarm instancing, resurrection FX |
| **Mechanical & Construct Sculptor** | Robots, golems, mechs, vehicles, clockwork, drones | Hard-surface modeling, piston rigs, modular assembly, cockpit interiors |
| **Mythic & Divine Entity Sculptor** | Gods, angels, demons, elementals, titans, spirits | Radiance systems, multi-arm rigs, elemental bodies (particle), cultural sensitivity |
| **Flora & Organic Sculptor** | Trees, plants, fungi, coral, alien flora, ents | L-systems, seasonal variants (4-season morph), procedural foliage, biome presets |
| **Aquatic & Marine Entity Sculptor** | Fish, octopi, sea serpents, merfolk, deep-sea | Buoyancy animation, caustics, bioluminescence, school instancing, tentacle IK |
| **Architecture & Interior Sculptor** | Buildings, dungeons, castles, rooms, ruins, furniture | Modular kit, architectural styles, structural plausibility, lived-in storytelling |
| **Weapon & Equipment Forger** | Weapons, armor, accessories, consumables, loot | Rarity tiers (5-tier visual system), procedural variants, 32x32 icon readability |
| **Terrain & Environment Sculptor** | Landscapes, caves, mountains, water, weather | Heightmaps, erosion simulation, biome generation, weather particle systems |

### 🎬 Media Pipeline Specialists (4 agents — format/toolchain experts)

These agents know the TECHNICAL REQUIREMENTS of each output format. Form Sculptors produce the design; Media Pipeline Specialists handle the technical pipeline for a specific format.

| Agent | Format | Key Technical Pipeline |
|-------|--------|----------------------|
| **2D Asset Renderer** | Pixel art, hand-drawn, vector, sprites | Aseprite CLI, ImageMagick, Inkscape, sprite sheet packing, palette management |
| **3D Asset Pipeline Specialist** | Models, UV, textures, rigs, animation, export | Blender workflows, glTF validation, mesh optimization, LOD chains |
| **VR XR Asset Optimizer** | Spatial interaction, comfort, performance | Perf budgets, stereoscopic, hand tracking, baked lighting, comfort metrics |
| **Texture & Material Artist** | PBR, stylized shaders, procedural, tiling | Blender shader nodes, GIMP, substance-like workflows, material libraries |

### 🏗️ Asset Creation & Assembly (7 agents)

| Agent | What It Does |
|-------|-------------|
| **Procedural Asset Generator** | Batch asset generation from templates, seed-based reproducibility |
| **Scene Compositor** | Apple-shuffle placement, biome rules, density painting, flythrough preview |
| **Sprite Sheet Generator** | Static sprite creation, pixel art, sheet packing *(SPLIT from Sprite Animation Generator)* |
| **Animation Sequencer** | Animation states, frame timing, state machines, Godot SpriteFrames *(SPLIT from Sprite Animation Generator)* |
| **Tilemap Level Designer** | Procedural dungeons, biome zones, Godot TileMap, navigation meshes |
| **Audio Composer** | Procedural music, SFX generation, adaptive scoring |
| **VFX Designer** | Particle systems, shaders, combat effects |

### 💻 Implementation (7 agents)

| Agent | What It Implements |
|-------|-------------------|
| **Game Code Executor** | GDScript game logic, system integration, Godot 4 scenes |
| **AI Behavior Designer** | Behavior trees, state machines, patrol/aggro/ally AI |
| **Combat System Builder** | Damage formulas, skill trees, combos, hitboxes, i-frames |
| **Dialogue Engine Builder** | Branching dialogue, emotion tracking, relationship meters |
| **Multiplayer Network Builder** | Godot multiplayer API, state sync, lobbies, lag compensation |
| **Game UI Designer** | Menus, inventory, dialogue boxes, settings, shop UI *(SPLIT from Game UI HUD Builder)* |
| **Game HUD Engineer** | Health bars, minimap, action bar, combo counter, damage numbers *(SPLIT from Game UI HUD Builder)* |

### 🎰 Game Trope Addons (18 agents — OPTIONAL MODULES)

> Not all games need all tropes. These are plug-in modules for common game mechanics. Pick what your game needs.

| Agent | Trope | When You Need It |
|-------|-------|-----------------|
| **Pet & Companion System Builder** | Pet/companion | Pokemon, Digimon, any pet-taming game |
| **Crafting System Builder** | Crafting | Minecraft, survival games, RPGs with crafting |
| **Housing & Base Building Designer** | Housing | Animal Crossing, Valheim, base-building games |
| **Farming & Harvest Specialist** | Farming | Stardew Valley, Harvest Moon, farm-sim games |
| **Fishing System Designer** | Fishing | Almost every RPG adds fishing |
| **Cooking & Alchemy System Builder** | Cooking/potions | BotW cooking, Skyrim alchemy, potion-heavy games |
| **Mount & Vehicle System Builder** | Mounts/vehicles | Open-world games, racing elements, flying mounts |
| **Guild & Social System Builder** | Social/guilds | MMOs, co-op games with persistent social structures |
| **Achievement & Trophy System Builder** | Achievements | Every platform expects achievement systems |
| **Relationship & Romance Builder** | Romance/NPC | Dating sims, BioWare-style RPGs, social sims |
| **Weather & Day-Night Cycle Designer** | Weather/time | Open worlds, survival games, farming sims |
| **Photo Mode Designer** | Photo mode | Increasingly expected in AAA and indie games |
| **Character Customization Builder** | Customization | Character creators, transmog, cosmetic systems |
| **Survival Mechanics Designer** | Survival | Hunger, thirst, temperature, shelter mechanics |
| **Taming & Breeding Specialist** | Taming/breeding | Creature capture + genetics + evolution systems |
| **Procedural Quest Generator** | Dynamic quests | Radiant quests, bounty boards, generated objectives |
| **Trading & Economy Builder** | Trading | Auction houses, player markets, NPC shop systems |
| **Minigame Framework Builder** | Minigames | Puzzle, rhythm, racing, card games within main game |

### 🧪 Quality & Balance (6 agents)

| Agent | What It Tests |
|-------|---------------|
| **Playtest Simulator** | AI bots play as archetypes — reports friction, exploits, softlocks |
| **Balance Auditor** | Damage curves, XP curves, loot tables, difficulty scaling |
| **Game Analytics Designer** | Telemetry instrumentation, retention cohorts, funnels, A/B testing, dashboards, privacy compliance |
| **Accessibility Auditor** | Colorblind modes, controls, subtitles, difficulty options (REUSED) |
| **Quality Gate Reviewer** | Multi-dimension scoring + verdicts (REUSED) |
| **Code Style Enforcer** | GDScript/Python convention enforcement (REUSED) |

### 🚀 Ship & Live Ops (5 agents)

| Agent | What It Does |
|-------|-------------|
| **Store Submission Specialist** | Multi-platform store submission — Steam, Epic, itch.io, GOG, App Store, Google Play, Nintendo, PlayStation, Xbox. Age ratings, regional pricing, compliance checking, rejection prevention |
| **Live Ops Designer** | Season pass, daily challenges, event calendars, battle pass |
| **Patch & Update Manager** | Delta patches, save migration, hotfixes, DLC packaging, staged rollouts, rollback, changelogs, mod compatibility |
| **Game Ticket Writer** | 16-section game-specific tickets from decompositions |
| **Game Orchestrator** | Master pipeline controller, multi-agent coordination |

### 🔧 Pipeline Infrastructure (8 agents — reused from CGS)

| Agent | Why It Works As-Is |
|-------|-------------------|
| The Decomposer | Task decomposition is domain-agnostic |
| The Aggregator | Matrix unification is domain-agnostic |
| Reconciliation Specialist | Blind-pass merging works for any artifact type |
| The Artificer | Tool-making is domain-agnostic |
| Enterprise Ticket Writer | Base 16-section format |
| Implementation Plan Builder | Phased checkbox plans |
| Documentation Writer | READMEs, docs, wiki pages |
| Agent Creation Agent | Meta-agent creation |

---

## The Pipelines

### Pipeline 1: Core Game Loop (The Main Pipeline)

```
Player's Pitch ("I want a hack and slash...")
    │
    ▼
┌──────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│ Game Vision       │───▶│ Narrative         │───▶│ The Decomposer       │
│ Architect         │    │ Designer          │    │ (per-stream)         │
│                   │    │                   │    │                      │
│ Produces:         │    │ Produces:         │    │ Produces:            │
│ GDD (50-100KB)    │    │ Lore Bible        │    │ 6 stream decomps     │
│ Core Loop diagram │    │ Character Bible   │    │ ≤8pts per task       │
│ Monetization model│    │ Quest Arc         │    │                      │
└──────────────────┘    └──────────────────┘    └──────────┬───────────┘
                                                           │
    ┌──────────────────────────────────────────────────────┘
    ▼
┌──────────────────────┐
│ The Aggregator        │
│ Unified task matrix   │
│ Cross-stream deps     │
└──────────┬───────────┘
           │
    ┌──────┘
    ▼
╔══════════════════════════════════════════════════════════════════╗
║  4-PASS BLIND TICKET PIPELINE (same as CGS)                     ║
║  Pass1 + Pass2 → Reconcile → UI/UX Pass1+2 → Reconcile → Audit ║
╚══════════════════════════════════════════════════════════════════╝
    │
    ▼
╔══════════════════════════════════════════════════════════════════╗
║  IMPLEMENTATION (4 slots — intensive)                            ║
║  Game Code Executor implements each task                         ║
║  Build → Test → Audit → Converge (95+ to pass)                 ║
╚══════════════════════════════════════════════════════════════════╝
    │
    ▼
╔══════════════════════════════════════════════════════════════════╗
║  PLAYTEST & BALANCE                                              ║
║  Playtest Simulator → Balance Auditor → Performance Profiler     ║
║  Fix → Retest → Converge                                        ║
╚══════════════════════════════════════════════════════════════════╝
    │
    ▼
Ship 🚀
```

### Pipeline 2: Narrative Pipeline

```
GDD (core story hooks)
    │
    ▼
Narrative Designer → Lore Bible
    │
    ├──▶ Character Designer → Character Sheets (JSON)
    │       │
    │       └──▶ Dialogue Engine Builder → Dialogue Trees (JSON)
    │
    ├──▶ World Cartographer → Region Lore → Quest Locations
    │
    └──▶ Quest Designer (sub-agent) → Quest Chains → Side Quests
            │
            └──▶ Game Economist → Quest Rewards → Economy Impact
```

### Pipeline 3: Art Pipeline

```
Art Director → Style Guide
    │
    ├──▶ Procedural Asset Generator → 3D Models/Sprites
    │       │
    │       └──▶ Sprite/Animation Generator → Walk cycles, attacks
    │
    ├──▶ Tilemap/Level Designer → Map Layouts
    │       │
    │       └──▶ Scene Compositor → Populated Scenes
    │
    ├──▶ VFX Designer → Particle Effects, Shaders
    │
    └──▶ UI/HUD Builder → Game UI
```

### Pipeline 4: Audio Pipeline

```
Audio Director → Sound Design Doc
    │
    ├──▶ Audio Composer → Background Music (per biome/region)
    │       │
    │       └──▶ Adaptive Music System → Battle transitions, boss themes
    │
    ├──▶ SFX Generator → Combat sounds, UI sounds, ambient
    │
    └──▶ Voice Direction → NPC barks, narrator, pet sounds
```

### Pipeline 5: World Pipeline (Your Procedural Scene Generator)

```
World Cartographer → World Map + Biome Definitions
    │
    ▼
┌──────────────────────────────────────────────────────────────────┐
│  PROCEDURAL WORLD ENGINE (the ACP of game worlds)                │
│                                                                   │
│  MCP Tools:                                                       │
│    world_create_region(biome, size, density)                      │
│    world_sculpt_terrain(region, action: raise/lower/flatten)      │
│    world_paint_biome(region, biomeType, params)                   │
│    world_populate(region, objectRules: {trees: 7%, bushes: 15%})  │
│    world_place_object(region, asset, position, rotation)          │
│    world_delete_object(region, objectId)                          │
│    world_select(region, tool: lasso/rect/circle, area)            │
│    world_regenerate(selection?, settings)                         │
│    world_expand(direction, amount)                                │
│    world_flythrough(region, path) → screenshot sequence           │
│    world_validate(region) → collision check, performance check    │
│    world_export(region, format: godot/unity/gltf)                 │
│                                                                   │
│  State Machine:                                                   │
│    region_status: draft → populated → reviewed → approved         │
│    Each region goes through: generate → inspect → modify → approve│
│                                                                   │
│  The "Apple shuffle" placement algorithm:                         │
│    1. Random placement pass                                       │
│    2. Uniformity check (no clusters, no empty patches)            │
│    3. Re-randomize problem areas                                  │
│    4. Aesthetic scoring (visual weight distribution)               │
│    5. Manual override layer (hand-placed objects preserved)        │
└──────────────────────────────────────────────────────────────────┘
```

### Pipeline 6: Economy & Balance Pipeline

```
Game Economist → Economy Model
    │
    ├──▶ Drop Table Generator → Loot tables per enemy/chest/boss
    │
    ├──▶ Crafting Recipe Designer → Material requirements, upgrade paths
    │
    ├──▶ Progression Curve Designer → XP/level curves, stat growth
    │
    └──▶ Balance Auditor → Simulation runs
            │
            ├──▶ "Can a F2P player reach endgame in 30 days?"
            ├──▶ "Is any build path a dead end?"
            ├──▶ "Does the economy inflate over 6 months?"
            └──▶ Fix → Rebalance → Re-simulate → Converge
```

---

## The Tech Stack (Agent-Automatable)

The critical constraint: **agents work via CLI tools.** Every creation tool MUST have a command-line interface or scriptable API.

| Domain | Tool | CLI Capability | Why |
|--------|------|---------------|-----|
| **Game Engine** | Godot 4 | `godot --headless --script` | GDScript is Python-like, fully scriptable, open source, isometric support built-in |
| **3D Modeling** | Blender | `blender --background --python script.py` | Full Python API, procedural generation, export to any format |
| **2D Art** | Aseprite | `aseprite --batch --script` | Pixel/chibi art, animation, sprite sheets |
| **Image Processing** | ImageMagick | `magick convert/composite` | Texture manipulation, palette swaps, atlas generation |
| **Audio** | SuperCollider | `sclang script.scd` | Procedural music and SFX generation |
| **Audio Processing** | sox + ffmpeg | `sox`/`ffmpeg` | Audio manipulation, format conversion, mixing |
| **Level Design** | Tiled | `tiled --export-map` | Isometric tilemap editor with CLI export |
| **Version Control** | Git + LFS | `git` | Large asset management |
| **Build** | Godot CLI | `godot --export` | Cross-platform build (Windows, Mac, Linux, Web, Mobile) |
| **Testing** | GUT (Godot Unit Test) | `godot --headless -s` | Automated game testing framework |

### Why Godot over Unity/Unreal?

1. **GDScript ≈ Python** — agents write Python-like code, not C++
2. **CLI-first** — `godot --headless` runs without GPU for CI/agent use
3. **Open source** — no licensing complications, full source access
4. **Scene-as-text** — `.tscn` files are text-based, git-friendly, agent-editable
5. **Isometric built-in** — TileMap with isometric mode, no plugins needed
6. **Small binary** — 40MB editor, fast iteration, agents can restart quickly

---

## The Grading & Audit System

Just like CGS audits code quality, game dev needs multi-dimensional auditing:

### Game Quality Dimensions (10-point scoring per dimension)

| Dimension | What It Measures | Auditor Agent |
|-----------|-----------------|---------------|
| **Gameplay Feel** | Is combat responsive? Do controls feel good? Input lag? | Playtest Simulator |
| **Visual Coherence** | Does art style stay consistent? Chibi proportions correct? Color palette adherent? | Art Director (audit mode) |
| **Audio Fit** | Does music match the mood? SFX timing correct? Volume balanced? | Audio Director (audit mode) |
| **Narrative Flow** | Does the story make sense? Pacing correct? Dialogue natural? | Narrative Designer (audit mode) |
| **Economy Health** | Is progression fair? Economy stable? No exploits? | Balance Auditor |
| **Performance** | 60 FPS on target hardware? Load times <3s? Memory <2GB? | Performance Profiler |
| **Accessibility** | Colorblind safe? Remappable controls? Difficulty options? | Accessibility Auditor |
| **Fun Factor** | Do playtest bots find optimal strategies boring or engaging? Session length healthy? | Playtest Simulator |
| **Technical Quality** | No crashes? No softlocks? Save/load reliable? | Game Tester |
| **Monetization Ethics** | Not pay-to-win? Reasonable grind? Transparent odds? | Game Economist (audit mode) |

### The Convergence Engine (same as CGS)

```
Agent A (specialist) → Audit all dimensions → Document findings → Fix issues → Build
    │
Agent B (fresh specialist) → Re-audit from scratch → Catch blind spots → Fix → Build
    │
Score check → if < 95 → dispatch Agent C → loop until converged
```

---

## What the Full Flow Looks Like

### Input
```
"I want a hack and slash isometric buddy pet trainer game with chibi graphics,
with a rich and immersive hook to get people into the game and a rich endgame
that keeps people playing and subscribing."
```

### Step 1: Game Vision Architect produces GDD
- Core loop: Fight → Loot → Train Pet → Evolve → Harder Fights
- Session hook: 15-minute combat loops with pet bonding moments
- Endgame: Procedural dungeons, PvP arenas, pet breeding, guild raids
- Monetization: Battle pass + cosmetics (no pay-to-win, pets earned not bought)
- Art: Isometric chibi, hand-drawn feel, vibrant biomes
- ~80KB comprehensive document

### Step 2: Narrative Designer creates the world
- World: Fragmented realm where pet bonds grant power
- Factions: 4 elemental factions, each with pet specialties
- Hook: Your first pet chooses YOU (emotional bond from minute 1)
- Endgame lore: The fragments are sentient, pets are fragments' emissaries

### Step 3: Decompose across 6 streams
- Narrative: 40 tasks (lore, characters, quests, dialogue)
- Visual: 60 tasks (sprites, tilesets, VFX, UI)
- Audio: 25 tasks (music, SFX, ambient)
- World: 35 tasks (biomes, dungeons, procedural gen)
- Mechanics: 50 tasks (combat, pets, economy, progression)
- Technical: 30 tasks (engine, networking, optimization)
- **Total: ~240 tasks**

### Step 4: 4-pass ticket pipeline (same as CGS)
- Pass 1 + Pass 2 → Reconcile → Audit → 240 finalized tickets
- Each ticket has: visual references, gameplay specs, audio cues, narrative context

### Step 5: Implementation (4 agents at a time)
- Agents write GDScript, create scene files, generate assets
- Each task: implement → build → test → audit → converge

### Step 6: Playtest & Balance
- AI bots play through the full game
- Balance Auditor runs economy simulations
- Performance Profiler benchmarks every scene
- Fix → retest → converge

### Step 7: Ship
- Multi-platform export (Godot CLI)
- Store page assets (Demo & Showcase Builder)
- Press kit, trailer (adapted from gameplay footage)

---

## The Procedural Scene Generator — In Detail

This deserves its own section because it's the most innovative piece and connects directly to your earlier work.

### Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                    PROCEDURAL SCENE GENERATOR                          │
│                                                                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐ │
│  │ TERRAIN      │  │ BIOME       │  │ POPULATION   │  │ MANUAL       │ │
│  │ ENGINE       │  │ PAINTER     │  │ ENGINE       │  │ EDITOR       │ │
│  │              │  │             │  │              │  │              │ │
│  │ Heightmap    │  │ Grass/snow/ │  │ Object       │  │ Freeform     │ │
│  │ generation   │  │ sand/water  │  │ placement    │  │ placement    │ │
│  │ Sculpt tools │  │ Transition  │  │ Density      │  │ Lasso select │ │
│  │ Push/pull    │  │ blending    │  │ control      │  │ Delete       │ │
│  │ Flatten      │  │ Climate     │  │ Apple-shuffle│  │ Move/rotate  │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                │                │                  │         │
│         └────────────────┴────────┬───────┴──────────────────┘         │
│                                   │                                    │
│                    ┌──────────────▼──────────────┐                     │
│                    │      SCENE STATE DB          │                     │
│                    │  (SQLite — same as ACP)      │                     │
│                    │                              │                     │
│                    │  regions, objects, biomes,   │                     │
│                    │  density rules, manual edits │                     │
│                    └──────────────┬──────────────┘                     │
│                                   │                                    │
│                    ┌──────────────▼──────────────┐                     │
│                    │      FLYTHROUGH ENGINE       │                     │
│                    │  Camera path → screenshots   │                     │
│                    │  Agent inspection of results  │                     │
│                    │  "Does this look right?"      │                     │
│                    └────────────────────────────┘                     │
└────────────────────────────────────────────────────────────────────────┘
```

### The Apple-Shuffle Placement Algorithm

```
function populateRegion(region, rules) {
  // rules: { trees: 7%, bushes: 15%, flowers: 30%, rocks: 5% }
  // density: 5% of total area covered

  // Pass 1: Pure random placement
  objects = randomPlace(region, rules, density=0.05)

  // Pass 2: Uniformity check
  grid = divideIntoSectors(region, sectorSize=32)
  for each sector in grid:
    sectorDensity = countObjects(sector) / sectorArea
    if sectorDensity > 1.5 * targetDensity:
      // Too clustered — redistribute some objects
      redistribute(sector, overflow → nearestUnderpopulated)
    if sectorDensity < 0.5 * targetDensity:
      // Too sparse — add objects
      fillSector(sector, rules, targetDensity)

  // Pass 3: Aesthetic scoring
  for each object in objects:
    neighbors = getNeighbors(object, radius=8)
    if allSameType(neighbors):
      // Monoculture patch — inject variety
      replaceRandom(neighbors, differentType)
    if tooRegular(spacing(neighbors)):
      // Grid-like pattern detected — jitter positions
      jitter(neighbors, maxOffset=2)

  // Pass 4: Manual override preservation
  for each manuallyPlaced in region.manualEdits:
    clearConflicts(manuallyPlaced, radius=2)
    // Manually placed objects are sacred — never moved or deleted

  return objects
}
```

### Predator-Prey Simulation (Your Deer/Wolf Idea)

```
Entity Behavior Layer:
  - Each entity type has a BehaviorProfile (JSON)
  - Wolves: { diet: "carnivore", prey: ["deer", "rabbit"], packSize: 3-6,
              territory: 500m, huntRange: 200m, restCycle: "nocturnal" }
  - Deer: { diet: "herbivore", fleeFrom: ["wolf", "bear"], herdSize: 4-8,
             grazingPattern: "meadow", fleeSpeed: 1.5x }

Simulation Loop (runs during world preview):
  1. Each entity acts according to its BehaviorProfile
  2. Predators patrol territory, detect prey in huntRange
  3. Prey flees when predator detected, herd stays together
  4. Population dynamics: births, deaths, migration
  5. Over time: natural ecosystems emerge
  6. Player can observe and tweak parameters in real-time
```

### Dimensional Breach Events

```
Random Event System:
  - Events are JSON-defined: { type: "dimensional_breach", probability: 0.02/day,
    effects: ["spawn_portal", "alter_biome_radius_50", "spawn_otherworld_creatures"],
    duration: "3_game_days", visual: "purple_rift_particles" }
  - Events can chain: breach → invasion → corruption → purification quest
  - Events affect the procedurally generated world permanently unless resolved
  - Creates emergent storytelling: "This forest was normal until the breach..."
```

---

## Connecting to CGS

The game dev pipeline RUNS ON CGS. CGS is the orchestration engine; game dev is a project type:

```
CGS (ConverGeniSys)
├── Project: EOIC (enterprise .NET microservices)
│   └── Uses: 67 services × audit lenses
├── Project: CGS (self-building meta-project)
│   └── Uses: 783 tasks × 4-pass pipeline
└── Project: GameName (video game)
    └── Uses: ~240 tasks × 6 streams × 4-pass pipeline
    └── Additional: Asset pipeline, scene generator, playtest bots
```

CGS already has multi-project support (we just built it!). Game dev would be registered as another project with its own task matrix, its own agents, its own pipelines — but sharing the orchestration infrastructure.

### What CGS Provides to Game Dev
- Agent dispatch and orchestration
- 4-pass blind ticket pipeline
- Reconciliation workflow
- Quality gate auditing
- State machine (ACP)
- Knowledge tree (when built)
- Kanban ticketing (when built)
- Dashboard visualization (when built)

### What Game Dev Adds to CGS
- New agent types (game-specific specialists)
- New pipelines (art, audio, world, narrative, economy)
- Procedural generation tools
- Playtest simulation framework
- Asset management extensions

---

## Agent Roster — Final Count (✅ ALL CREATED)

| Category | Count | Status |
|----------|------:|--------|
| Vision & Pre-Production | 7 | ✅ All created |
| Technical Design | 4 | ✅ All created (2 reused) |
| Asset Creation | 7 | ✅ All created |
| Implementation | 6 | ✅ All created |
| Quality & Balance | 5 | ✅ All created (2 reused) |
| Polish & Ship | 5 | ✅ All created (4 reused) |
| Reusable Infrastructure | 3 | ✅ All copied |
| **Total** | **37** | **✅ 1.7MB, all committed** |

### Full Agent Inventory (37 agents, alphabetical)

| Agent | Size | Category | New/Reused |
|-------|------|----------|------------|
| Accessibility Auditor | 42KB | Quality | Reused |
| Agent Creation Agent | 8KB | Meta | Reused |
| AI Behavior Designer | 60KB | Implementation | New |
| Audio Composer | 56KB | Asset Creation | New |
| Balance Auditor | 42KB | Quality | New |
| Character Designer | 41KB | Vision | New |
| Code Style Enforcer | 35KB | Quality | Reused |
| Combat System Builder | 73KB | Implementation | New |
| Dialogue Engine Builder | 61KB | Implementation | New |
| Documentation Writer | 28KB | Infrastructure | Reused |
| Enterprise Ticket Writer | 40KB | Planning | Reused |
| Game Architecture Planner | 42KB | Technical Design | New |
| Game Art Director | 53KB | Vision | New |
| Game Audio Director | 39KB | Vision | New |
| Game Code Executor | 51KB | Implementation | New |
| Game Economist | 44KB | Vision | New |
| Game Orchestrator | 77KB | Meta | New |
| Game Ticket Writer | 61KB | Planning | New |
| Game UI HUD Builder | 65KB | Asset Creation | New |
| Game Vision Architect | 55KB | Vision | New |
| Implementation Plan Builder | 33KB | Planning | Reused |
| Live Ops Designer | 74KB | Polish | New |
| Multiplayer Network Builder | 69KB | Implementation | New |
| Narrative Designer | 36KB | Vision | New |
| Pet Companion System Builder | 60KB | Implementation | New |
| Playtest Simulator | 72KB | Quality | New |
| Procedural Asset Generator | 52KB | Asset Creation | New |
| Quality Gate Reviewer | 19KB | Quality | Reused |
| Reconciliation Specialist | 26KB | Infrastructure | Reused |
| Scene Compositor | 56KB | Asset Creation | New |
| Sprite Animation Generator | 84KB | Asset Creation | New |
| The Aggregator | 36KB | Infrastructure | Reused |
| The Artificer | 16KB | Infrastructure | Reused |
| The Decomposer | 16KB | Infrastructure | Reused |
| Tilemap Level Designer | 50KB | Asset Creation | New |
| VFX Designer | 51KB | Asset Creation | New |
| World Cartographer | 37KB | Vision | New |

---

## Next Steps to Make This Real

1. ✅ ~~Create all agents~~ — **DONE** (37 agents, 1.7MB)
2. ✅ ~~Agent registry~~ — **DONE** (agent-registry.json, 37 entries)
3. ✅ ~~Workflow pipelines~~ — **DONE** (workflow-pipelines.json, 6 pipelines)
4. **Define the GDD schema** — JSON-structured Game Design Document
5. **Build the Procedural Scene Generator** as a CGS tool (MCP server)
6. **Evaluate Godot CLI automation** — prove agents can create game content
7. **Create a tiny proof-of-concept** — one room, one enemy, one pet, agent-generated
8. **Build game-dev ACP** — state machine, dispatch engine, prompt templates (Artificer candidate)
9. **Expand from there** — the same way CGS grew from EOIC

The beauty is: **CGS IS the game engine's orchestration layer.** We're not building a separate system — we're extending CGS to understand game development as another project type. Every tool we build for CGS (knowledge tree, kanban, dashboard) serves game dev too.

---

*"The best game engine is the one that lets you describe what you want and builds it for you."*
