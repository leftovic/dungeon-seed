# Dungeon Seed — Game Design Document v3.0

**Genre:** Deterministic Dungeon-Crawl RPG / Idle Hybrid  
**Engine:** Godot 4.x (GDScript)  
**Platform:** PC (primary), Mobile (post-MVP), Console (stretch)  
**Scope:** Solo Indie MVP → Expandable  
**Last Updated:** 2025-07-17  
**Status:** Authoritative — all downstream design, art, audio, and engineering agents consume this document.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Core Fantasy & Pillars](#2-core-fantasy--pillars)
3. [Core Gameplay Loop](#3-core-gameplay-loop)
4. [The Seed System](#4-the-seed-system)
5. [Expedition System](#5-expedition-system)
6. [Adventurer System](#6-adventurer-system)
7. [Guild & Meta-Progression](#7-guild--meta-progression)
8. [Economy & Resources](#8-economy--resources)
9. [Combat System](#9-combat-system)
10. [Items & Equipment](#10-items--equipment)
11. [UI/UX Design](#11-uiux-design)
12. [Narrative & World](#12-narrative--world)
13. [Art Direction & Audio](#13-art-direction--audio)
14. [Technical Architecture](#14-technical-architecture)
15. [MVP Scope & Success Metrics](#15-mvp-scope--success-metrics)

---

## 1. Executive Summary

### 1.1 Elevator Pitch

You are a **Seedwarden** — the last practitioner of an ancient art that grows living dungeons from magical seeds. Plant a seed, nurture its growth through elemental soil, watch a twisting labyrinth sprout from the earth, then dispatch a party of adventurers to clear its rooms and harvest its treasures. Every seed is unique. Every dungeon is alive. Every harvest feeds the next planting.

**Dungeon Seed** is a single-player deterministic dungeon-crawl RPG/idle hybrid where the strategic loop of *planting → growing → exploring → harvesting → replanting* replaces traditional dungeon grinding with a satisfying cultivation cadence. The same seed always produces the same dungeon — enabling community sharing, strategy guides, and reproducible challenge runs. Active play rewards tactical party composition and pre-battle preparation; idle play rewards patience as seeds grow and adventurers recover between sessions.

### 1.2 Genre Tags

`Deterministic Dungeon Crawl` · `RPG` · `Idle/Incremental` · `Strategy` · `Procedural Generation` · `Seed-Sharing` · `Auto-Battle` · `Meta-Progression`

### 1.3 Platform & Distribution

| Platform | Priority | Notes |
|----------|----------|-------|
| **PC (Windows)** | MVP | Primary target. Keyboard + mouse. Steam distribution. |
| **PC (macOS, Linux)** | Post-MVP | Godot exports natively. Low-effort port. |
| **Mobile (iOS, Android)** | Post-MVP Phase 2 | Touch UI adaptation required. Session design already mobile-friendly. |
| **Console (Switch)** | Stretch Goal | Chibi-adjacent aesthetic and session structure fit Switch audience. |
| **Web** | Consideration | Godot HTML5 export for demo/trial acquisition funnel. |

### 1.4 Target Audience

| Segment | Description | Comparable Titles |
|---------|-------------|-------------------|
| **Primary** | Idle/incremental players who want meaningful strategic depth | Melvor Idle, Legends of IdleOn, Soda Dungeon, Realm Grinder |
| **Secondary** | Roguelite fans who enjoy seed-based generation and meta-progression | Hades, Slay the Spire, Dead Cells, Into the Breach |
| **Tertiary** | Cozy-game-adjacent players drawn to cultivation/gardening aesthetic | Stardew Valley, Moonstone Island, Garden Story |
| **Quaternary** | Theorycraft/optimizer players who love deterministic puzzle-solving | Opus Magnum, Factorio, Zachtronics games |

### 1.5 Business Model

**MVP:** Premium purchase ($9.99–$14.99 USD). No microtransactions. All content earnable through gameplay.

**Post-MVP consideration:** If free-to-play is adopted, strict ethical guardrails apply (see §8.7). No pay-to-win. No energy gates. No exploitative loot boxes. Cosmetic-only premium currency.

### 1.6 Unique Selling Proposition

> *"Grow the dungeon. Plan the raid. Share the seed."*

No other game combines:
1. **Seed-as-level-generator** — the player *cultivates* the content they consume.
2. **Deterministic procedural generation** — same seed + same conditions = identical dungeon, enabling community seed-sharing and strategy guides.
3. **Dual engagement model** — equally satisfying as an active tactical RPG or a background idle game.
4. **Abstract dungeon graph** — dungeons are node-and-edge graphs, not spatial tilemaps, enabling clean auto-resolution and strategic room-by-room decision making.
5. **Mutation-driven variety** — a single seed species can produce radically different dungeons based on cultivation choices.
6. **No execution skill required** — strategy-heavy, execution-free design accessible to all dexterity levels.

### 1.7 Session Structure

| Session Type | Duration | Primary Activity |
|---|---|---|
| **Quick Check** | 1–3 min | Collect idle rewards, replant seeds, check adventurer recovery status, queue training. |
| **Active Session** | 15–45 min | Plan party composition, equip gear, run 2–4 dungeon expeditions, manage economy, craft upgrades. |
| **Deep Session** | 45–120 min | Experiment with mutation chains, optimize build synergies, push high-Vigor seeds, farm specific bosses for targeted loot. |

**Natural stopping points** exist after every Cultivation Cycle: seeds are planted (come back when grown), adventurers are recovering (come back when healed), equipment is being crafted (come back when ready). There is always a reason to return but never a penalty for stepping away.

### 1.8 Comparable Titles & Differentiation

| Title | What It Does Well | What It Does Poorly | How Dungeon Seed Differentiates |
|-------|-------------------|---------------------|-------------------------------|
| **Soda Dungeon 2** | Simple idle dungeon crawling, satisfying prestige loop | Combat lacks depth, party composition doesn't matter much | Seed system adds strategic layer; deterministic seeds enable community sharing |
| **Melvor Idle** | Deep RPG systems in idle format, skill-based progression | No visual dungeon exploration, can feel spreadsheet-like | Visual expedition playback with juicy combat feedback; cultivation aesthetic |
| **Slay the Spire** | Excellent seed-based roguelite, deep strategic decisions | No idle component, no persistent progression between runs | Idle growth between runs; persistent adventurer/guild progression |
| **Hades** | Brilliant meta-progression, compelling narrative, satisfying combat | Requires real-time dexterity, less accessible | Auto-battle removes dexterity barrier; strategy-before-execution design |
| **Moonstone Island** | Cozy creature-collection + dungeon crawling, charming aesthetic | Dungeon depth limited, creature battling underdeveloped | Deeper dungeon generation, mutation-driven variety, deterministic replay |
| **Loop Hero** | Innovative "build the dungeon as you play" concept, idle-adjacent | Limited direct control, card-based building can feel random | Direct cultivation control, deeper party management, clearer strategic agency |
| **Darkest Dungeon** | Party management excellence, meaningful consequences, atmospheric | Punishing permadeath can frustrate, RNG-heavy combat outcomes | No permadeath (adventurers recover), deterministic outcomes reduce frustration |

**Positioning Statement:** Dungeon Seed exists because no other game lets you *grow* a deterministic dungeon from a shareable seed, send a tactically-composed party to auto-clear it, and then reinvest the rewards into growing harder dungeons — all while the next crop of seeds matures in the background.

---

## 2. Core Fantasy & Pillars

### 2.1 The Player Fantasies

Dungeon Seed delivers three interlocking player fantasies. Every system, mechanic, UI screen, and piece of content must serve at least one of these fantasies. If a proposed feature doesn't serve any fantasy, it gets cut.

#### 🌱 The Architect of Adventure
> *"I shape a forest of living dungeons with every seed I plant."*

The player is not a passive consumer of procedurally generated content — they are the *cultivator*. They choose which seeds to plant, which mutations to accept, which soil amendments to apply. The dungeon they explore is one they grew. This ownership creates a fundamentally different relationship with procedural content: it's *your* dungeon, not a random one the game threw at you.

**Systems that serve this fantasy:** Seed selection, mutation decisions, soil amendments, growth timing, seed sharing, Seed Vault collection.

#### ⚔️ The Strategic Commander
> *"Victory is won before the first sword swings."*

The player is a general, not a soldier. They never press "attack" — they compose the party, select the equipment, choose the elemental matchups, assign tactical directives, and then watch their preparation either triumph or fail. The satisfaction comes from seeing a plan come together (or diagnosing why it didn't). This is chess, not Street Fighter.

**Systems that serve this fantasy:** Party composition, equipment loadout, elemental matchups, tactical directives, combat replay analysis, skill selection.

#### 🏡 The Patient Cultivator
> *"Time away is time well spent. My garden grows while I sleep."*

The idle mechanics aren't a compromise — they're core to the fantasy. The player is a gardener. Gardeners plant, tend, wait, and harvest. The waiting IS the gameplay. When the player returns and sees their seeds have bloomed, their adventurers have healed, and their coffers have grown, they feel the satisfaction of a harvest. Active play is always more efficient, but idle play is never wasted.

**Systems that serve this fantasy:** Seed growth timers, adventurer recovery, passive resource generation, Training Hall, Welcome Back screen, guild hall idle bonuses.

### 2.2 Design Pillars

These five pillars are non-negotiable. Every feature, system, and UI decision must serve at least one pillar. If a proposed feature conflicts with a pillar, **the pillar wins**.

| # | Pillar | Description | Violation Example |
|---|--------|-------------|-------------------|
| 1 | **Cultivate, Don't Grind** | The core loop is *growing* something, not endlessly repeating content. Every action feeds forward into the next cycle. Progression should feel like tending a garden, not running a treadmill. | ❌ Requiring 50 identical dungeon runs to unlock the next tier. ✅ Each dungeon run yields materials that grow better seeds for the next run. |
| 2 | **Every Seed Tells a Story** | Procedural generation must produce dungeons that feel hand-crafted. Each seed's elemental affinity, mutation history, and growth stage create a dungeon with a legible identity — not random noise. A player should be able to describe "that Embervault seed with the Perilous + Bountiful mutations" to another player and both know exactly what to expect. | ❌ Rooms assembled from random tiles with no thematic coherence. ✅ Biome templates + authored room compositions + mutation modifiers creating recognizable dungeon personalities. |
| 3 | **Strategy Before the Battle** | Combat is auto-resolved, but victory is determined by decisions made *before* the fight: party composition, equipment loadout, elemental matchups, consumable selection. The player is a general, not a soldier. The game rewards preparation, not reflexes. | ❌ Adding a "dodge" button during auto-battle. ✅ Adding a tactical directive that changes how the AI prioritizes targets. |
| 4 | **Respect the Player's Time** | Idle mechanics reward players who step away; they never punish players who stay. Active play must always be more efficient than idle play, but idle play must never feel like wasted time. There are **no artificial energy gates**, no stamina systems, no wait-to-play timers. The condition system provides natural pacing without hard gates. | ❌ "You've run out of energy. Wait 4 hours or pay $1." ✅ "Your Warrior is Fatigued (−10% stats). You can send them anyway or swap in your backup." |
| 5 | **Depth Through Interaction** | Individual systems (seeds, adventurers, loot, economy) are intentionally simple in isolation. Depth emerges from how they *interact* — an Arcane-mutated seed produces a dungeon that rewards Mage-heavy parties using Shimmerdeep loot with elemental matchup bonuses, creating emergent strategy without overwhelming complexity in any single system. | ❌ A 50-node skill tree per adventurer class. ✅ 8–10 skills per class that combine with elemental matchups, party composition, and equipment synergies to create hundreds of effective builds. |

### 2.3 Anti-Pillars (What This Game Is NOT)

| Not This | Because | Instead |
|----------|---------|---------|
| Not a real-time action game | Pillar 3: Strategy Before the Battle. No dexterity test. | Auto-resolved combat driven by pre-expedition decisions. |
| Not a roguelike with permadeath | We want players to invest in adventurers emotionally and strategically. Permadeath discourages that investment. | Adventurers are **never** permanently lost. They are "recalled" with injuries that require recovery time. Equipment is never lost. |
| Not a spatial tilemap dungeon | Abstract graph enables cleaner auto-resolution and strategic decision-making without pathfinding complexity. | Dungeons are **node-and-edge graphs**: rooms are nodes, connections are edges. The player sees room nodes, not tile grids. |
| Not a "numbers go up" clicker | Pillar 1: Cultivate, Don't Grind. Each cycle should feel meaningfully different. | Mutation-driven dungeon variety + deterministic seeds + party composition strategy create real decisions each cycle. |
| Not a competitive PvP game | The audience is primarily solo strategy/idle players. | Community seed-sharing is the social mechanic. Leaderboards (post-MVP) for time/efficiency on shared seeds. |

---

## 3. Core Gameplay Loop

### 3.1 The Cultivation Cycle

The game is structured around a repeating macro-loop called the **Cultivation Cycle**. This is the heartbeat of Dungeon Seed — every session begins and ends within this cycle.

```
┌──────────────────────────────────────────────────────────────────────┐
│                       THE CULTIVATION CYCLE                          │
│                                                                      │
│   ┌────────┐    ┌────────┐    ┌──────────┐    ┌──────────┐          │
│   │ 1.PLANT├───►│ 2.GROW ├───►│3.EXPLORE ├───►│4.HARVEST │          │
│   └───┬────┘    └────────┘    └──────────┘    └─────┬────┘          │
│       │                                             │                │
│       │          ┌────────────┐                      │                │
│       └──────────┤ 5.REINVEST ◄─────────────────────┘                │
│                  └────────────┘                                       │
│                                                                      │
│   Duration: 1 full cycle ≈ 2–4 hours (with idle growth)             │
│             or ≈ 45–90 min (with active acceleration)                │
└──────────────────────────────────────────────────────────────────────┘
```

#### Phase 1 — PLANT (1–2 minutes)

Select a seed from your Seed Vault. Choose an available Garden Plot (1–5 unlockable slots). Optionally apply **Soil Amendments** — elemental composts to shift affinity, Vigor tonics to increase difficulty/reward, mutation catalysts to influence upcoming mutations. Commit the seed to the soil.

**Player decisions:**
- Which seed species/rarity to plant (risk/reward tradeoff)
- Which plot to use (plots can have upgrades that affect growth)
- Whether to apply soil amendments (spend resources now for better dungeon later)
- Timing — staggering seed planting so blooms don't all arrive simultaneously

#### Phase 2 — GROW (10–100 minutes real-time, or accelerated)

The seed advances through four growth stages: **Spore → Sprout → Bud → Bloom**. Each stage transition takes progressively longer (see §4.4). Growth continues while offline — this is the primary idle mechanic.

At each stage transition, a **mutation roll** occurs. The player can:
- **Accept** the mutation (free)
- **Reject** and reroll (costs Verdant Essence)
- **Redirect** to a specific mutation category (costs a rare Catalyst item)

**Player decisions:**
- Whether to spend Verdant Essence to accelerate growth
- Whether to accept, reject, or redirect mutations at each stage gate
- Whether to apply additional soil amendments mid-growth

#### Phase 3 — EXPLORE (5–15 minutes active, or skip)

Select a Bloom-stage dungeon and assemble an adventurer party (1–4 members). Review the dungeon's elemental affinity, estimated difficulty, room count, and mutation-influenced properties. Equip gear, assign consumables, select skills, and set **Tactical Directives** (high-level AI orders). Launch the expedition.

The dungeon is represented as an **abstract graph** of room nodes connected by edges. The party auto-resolves each room sequentially along the critical path, with optional branch rooms explorable based on party composition (e.g., high-PER parties discover secret rooms). The player watches the auto-battle playback at 1×, 2×, 4× speed, or skips entirely.

**Player decisions:**
- Party composition (which 1–4 adventurers, considering class synergies, elemental matchups, condition status)
- Equipment loadout per adventurer
- Skill selection per adventurer
- Consumable assignment (potions, scrolls)
- Tactical directives (targeting priority, mana conservation, retreat threshold)
- Whether to attempt optional branch rooms or stick to the critical path

#### Phase 4 — HARVEST (1–2 minutes)

After the expedition (win or lose), collect rewards: equipment drops, crafting materials, Gold, Verdant Essence, and sometimes new seeds. Partially cleared dungeons yield partial rewards proportional to rooms completed. Boss rooms yield bonus loot.

**Important:** The seed is consumed on exploration regardless of outcome. This creates meaningful tension — you're spending your cultivated seed every time you explore. Failed preparation means a wasted seed, not just wasted time.

**Loot distribution:**
- Gold: from combat encounters and treasure rooms
- Verdant Essence: from all dungeon activities (scaled by Vigor)
- Crafting Materials: from combat drops and treasure chests
- Equipment: from treasure chests and boss kills
- Seeds: rare drops (~8% base, increased by Fertile mutation)
- Guild Favor: from expedition completion (see §7)

#### Phase 5 — REINVEST (2–5 minutes)

Spend earned resources to:
- Buy or upgrade equipment at the Workshop
- Recruit or train adventurers at the Tavern
- Purchase seeds or amendments at the Shop
- Upgrade guild hall facilities for permanent bonuses
- Plant the next seed — the cycle begins again

**Design intent:** Every Reinvest phase should present 2–3 meaningful competing uses for the player's resources. "I have 500 Gold — do I craft that Rare sword, recruit a backup Alchemist, or buy a high-Vigor seed?" This tension drives engagement.

### 3.2 Nested Loop Structure

The Cultivation Cycle nests smaller engagement loops:

```
┌─ META LOOP (session-to-session) ─────────────────────────────────────┐
│ Login → Collect idle rewards → Run 1–3 Cultivation Cycles →          │
│ Advance guild upgrades → Set up next idle batch → Logout             │
│                                                                       │
│  ┌─ MACRO LOOP (30–60 min: one Cultivation Cycle) ──────────────────┐│
│  │ Plant → Grow → Explore → Harvest → Reinvest                      ││
│  │                                                                    ││
│  │  ┌─ MESO LOOP (5–15 min: one Expedition) ────────────────────────┐││
│  │  │ Assemble party → Set directives → Launch → Watch/Skip →       │││
│  │  │ Collect loot → Evaluate results → Adjust for next run         │││
│  │  │                                                                │││
│  │  │  ┌─ MICRO LOOP (30–60 sec: one Room) ─────────────────────────┐│││
│  │  │  │ Enter room → Auto-battle resolves → Loot drops →           ││││
│  │  │  │ HP/MP updated → Advance to next room                       ││││
│  │  │  └─────────────────────────────────────────────────────────────┘│││
│  │  └────────────────────────────────────────────────────────────────┘││
│  └────────────────────────────────────────────────────────────────────┘│
└───────────────────────────────────────────────────────────────────────┘
```

### 3.3 Moment-to-Moment Gameplay

Here is what playing Dungeon Seed *feels* like second by second:

> You open the game. The Welcome Back screen tells you: your Embervault Rare seed has reached Bloom stage (ready!), your Verdant Common is still at Bud (47 minutes left), and the Bountiful mutation was auto-accepted while you were away. Your Warrior Kira has recovered from her injuries. You earned 180 Gold and 48 Verdant Essence passively.
>
> You tap "Continue" and land on the Garden screen. The Embervault seed pulses with molten orange light — it's ready. You tap it and the Expedition Board opens, showing the dungeon preview: 14 rooms, Flame affinity, Vigor 42, Bountiful mutation (+treasure), difficulty rating 2/5 skulls.
>
> Time to assemble a party. You drag Kira (Warrior, Frost affinity — advantaged against Flame!) into slot 1. Thane (Ranger, Terra) goes in slot 2 for DPS. Lira (Mage, Frost) in slot 3 — she'll deal ×1.5 damage to everything in here. You consider slot 4: your Alchemist is still Fatigued. You could send her at −10% stats, or go with three. Three is enough for 2-skull difficulty. You set the directive to "Focus Fire" and assign two Health Potions to Kira (she'll be tanking).
>
> "Embark." The expedition launches. Room 1: Entrance — a lore inscription about ancient forges. Room 2: Combat — two Magma Slimes. Kira taunts, Lira hits with Frost Blast for ×1.5 damage. Both slimes down in 2 rounds. Room 3: Treasure — a chest containing an Uncommon Iron Helm (+5 DEF). Nice. Room 4: Combat — a Forge Drone and an Ember Wraith. Thane snipes the Wraith while Kira holds the Drone. Lira's Arcane Storm cleans up. Floating damage numbers, satisfying impact sounds.
>
> Room 7: Rest room — the party heals at a campfire. Room 11: the boss room. Pyrax the Forgelord. Phase 1: Kira taunts, taking heavy hits. Lira's Frost damage is devastating. Phase 2 at 50% HP: Pyrax floods the room with lava — party-wide fire damage each turn. Thane is getting low. Kira pops Shield Wall. Phase 3 at 25%: Pyrax enrages, ATK up. It's close — Kira is at 12% HP. Lira lands the killing blow with a critical Frost Blast.
>
> Victory fanfare. Loot screen: a Rare Emberforged Axe (Flame ATK +15%), 340 Gold, 85 Verdant Essence, 12 Iron Ore, 3 Flame Essence, and — wait — a new seed! An Uncommon Embervault seed, Vigor 35. The party earned 1,240 XP each.
>
> Back at the Garden. You equip the Emberforged Axe on Thane (the Ranger can use axes? No — it's for Warriors. You equip it on Kira. Now she deals Flame damage with her basic attacks. That'll be less useful in Flame dungeons but devastating in Shadow ones). You plant the new Embervault seed in plot 2. You spend 200 Gold on a Frost Compost from the shop — you'll apply it to your next Verdant seed to shift its affinity toward Frost, which will produce Frost-element enemies that Kira can now shred with her Flame axe.
>
> You check the Verdant seed in plot 3. Still 47 minutes to Bloom. You assign Thane to the Training Hall. You close the game. The garden grows while you sleep.

### 3.4 Engagement Cadence & Stopping Points

The game is designed around **natural stopping points**. After each Cultivation Cycle, the player has a clean break:

| State | Message to Player | Emotional Tone |
|-------|-------------------|----------------|
| Seeds growing | "Your Arcane seed reaches Bud in 28 minutes" | Anticipation — something to look forward to |
| Adventurers recovering | "Kira will be Healthy in 32 minutes" | Relief — she earned her rest |
| Equipment crafting | "Frostweave Robe completes in 15 minutes" | Delayed gratification |
| Training in progress | "Thane is gaining XP in the Training Hall" | Passive progress |

**Rule:** There is always a reason to return. There is never a penalty for absence. The game *invites* return; it does not *demand* it.

### 3.5 Win/Loss Philosophy

There is no singular win condition. The game is open-ended with milestone-based progression:

**Short-term goals** (per session): Clear a specific dungeon, complete an expedition without casualties, craft a Rare item, evolve a seed to Bloom with a specific mutation chain.

**Medium-term goals** (per week): Unlock a new biome, reach Adventurer Level 25, breed a triple-mutated seed, upgrade all guild facilities to Tier 2.

**Long-term goals** (per month+): Complete the Seed Codex (all species/mutations discovered), clear a Voidmaw Bloom at Vigor 100, earn all Seedwarden Titles, max out all guild hall facilities.

**Loss is never permanent.** A failed expedition costs:
- The seed (consumed regardless of outcome) — this is the meaningful cost
- Consumables used during the run
- Adventurer condition degradation (Fatigued → Injured → Exhausted)

A failed expedition does **not** cost:
- Equipment (never lost, never broken)
- Adventurer lives (no permadeath — they are "recalled" to the guild hall with injuries)
- Progression (XP is still awarded for rooms cleared before failure)
- Partial loot (rewards from rooms cleared before failure are kept)

---

## 4. The Seed System

### 4.1 Overview

Seeds are the foundational resource of Dungeon Seed. Each seed is a self-contained deterministic blueprint for a procedurally generated dungeon. The player's primary strategic agency comes from selecting, cultivating, mutating, and timing the exploration of seeds.

**The core innovation:** Because dungeon generation is fully deterministic, a seed's properties fully describe the resulting dungeon. The same seed + same species + same affinity + same mutations = identical dungeon layout, identical enemy placements, identical loot tables. This enables community seed-sharing, strategy guides, and reproducible playtesting.

### 4.2 Deterministic RNG Architecture

Every seed carries a `generation_seed` — a `uint64` value that serves as the master key for all procedural generation. This value initializes a **seeded Random Number Generator** (Godot's `RandomNumberGenerator` class) that drives every random decision in dungeon generation.

**Critical implementation rule:** No procedural generation code may use Godot's global `randi()` or `randf()`. All RNG must flow through an explicitly-seeded `RandomNumberGenerator` instance derived from the `generation_seed`. This guarantees determinism across platforms and sessions.

```
Generation Pipeline (all deterministic from generation_seed):

generation_seed (uint64)
  ├─► Room count & layout graph
  ├─► Room type assignments (combat, treasure, rest, boss, secret)
  ├─► Enemy compositions per combat room
  ├─► Loot table rolls per treasure room & combat drop
  ├─► Trap placements and types
  ├─► Boss variant selection
  ├─► Secret room locations and discovery thresholds
  └─► Environmental hazard parameters
```

**Seed Code Display:** The uint64 generation_seed is displayed to the player as a shareable **8-character alphanumeric code** using a restricted character set:

```
Format: XXXX-XXXX
Character set: 0-9, A-Z excluding O, I, L (avoids ambiguity) = 33 characters
Total combinations: 33^8 ≈ 1.4 trillion unique codes
Example: KXVN-84PQ → maps to uint64 8837291047362 → deterministic dungeon

Codes are case-insensitive. The hyphen is cosmetic (optional in input).
```

### 4.3 Seed Properties

Every seed has the following properties:

| Property | Type | Description | Affects Generation? |
|----------|------|-------------|---------------------|
| **Species** | Enum | Determines base biome: Verdant Hollow, Embervault, Frostmere, Shimmerdeep, Voidmaw | Yes — sets enemy pool, trap pool, visual theme, ambient audio |
| **Affinity** | Element | Primary elemental alignment: Terra, Flame, Frost, Arcane, Shadow. Matches species by default but shiftable via soil amendments. | Yes — determines enemy elemental alignment (80% match affinity, 20% off-element) |
| **Generation Seed** | uint64 | The deterministic RNG master seed. Displayed as 8-char code. | Yes — the master key for all procedural decisions |
| **Growth Stage** | Enum | Current lifecycle: Spore, Sprout, Bud, Bloom | No — only Bloom seeds generate dungeons |
| **Mutations** | Array[Mutation] | 0–3 mutations acquired during growth stages | Yes — modifies dungeon parameters (room count, enemy density, loot, etc.) |
| **Vigor** | int (1–100) | Quality/difficulty rating. Higher = harder but more rewarding. | Yes — scales room count, enemy density, enemy stats, loot quality |
| **Rarity** | Enum | Common, Uncommon, Rare, Epic, Legendary | Determines mutation slot count and base Vigor range |

### 4.4 Elemental Affinity System

Five elements form an advantage cycle (rock-paper-scissors-plus pentagon):

```
         Terra
        /     \
       /       \
    Shadow ─── Flame
      |    ×    |
      |  /   \  |
    Arcane ─── Frost
```

**Advantage Cycle (clockwise):** Terra → Frost → Flame → Shadow → Arcane → Terra

| Attacker → Defender | Damage Modifier |
|---------------------|-----------------|
| Advantage (e.g., Terra → Frost) | ×1.5 |
| Disadvantage (e.g., Frost → Terra) | ×0.6 |
| Neutral (all other pairings) | ×1.0 |

| Element | Color Palette | Thematic Identity | Biome | Shape Icon |
|---------|--------------|-------------------|-------|------------|
| **Terra** | Emerald, brown, gold | Growth, stability, nature | Verdant Hollow | Circle ● |
| **Flame** | Crimson, orange, charcoal | Destruction, forging, heat | Embervault | Triangle ▲ |
| **Frost** | Ice blue, white, silver | Preservation, stillness, cold | Frostmere | Diamond ◆ |
| **Arcane** | Violet, cyan, iridescent | Knowledge, instability, magic | Shimmerdeep | Star ★ |
| **Shadow** | Deep purple, black, pale green | Corruption, stealth, void | Voidmaw | Hexagon ⬡ |

**Design rationale for shapes:** Element information must never rely on color alone (Accessibility Pillar). Every element has a unique shape icon used alongside color throughout all UI.

### 4.5 Growth Stages

Seeds progress through four growth stages. Each stage transition is a strategic decision point.

| Stage | Base Duration | Cumulative | Mutation Roll? | Player Actions |
|-------|-------------|------------|----------------|----------------|
| **Spore** | Instant | 0 min | No | Seed exists in Vault. Can be inspected, shared, planted. |
| **Sprout** | 10 min | 10 min | Yes (1st roll) | Plant in Garden Plot. Timer begins. Can apply soil amendments. |
| **Bud** | 30 min | 40 min | Yes (2nd roll) | Can apply additional amendments. Can accelerate with Essence. |
| **Bloom** | 60 min | 100 min | Yes (3rd roll) | Dungeon fully generated. Ready for expedition. No time pressure — Bloom seeds don't decay. |

**Total base growth time:** ~100 minutes (1 hr 40 min) from planting to Bloom.

**Growth Acceleration:**
- Spending Verdant Essence reduces timers (cost scales with seed rarity)
- Upgraded garden plots reduce base growth time by up to 40%
- Temporal Fertilizer amendment: −25% growth time for next stage
- Combined maximum: a seed can reach Bloom in ~36 minutes of active investment

**Offline Growth:** Seeds continue growing while the game is closed. Growth timers use UTC system clock with drift detection to prevent clock manipulation. Seeds will **not** advance past Bloom while offline — a Bloom seed waits patiently for the player. No decay. No pressure.

**Queued Offline Mutations:** If a seed passes a stage transition while offline, the mutation is auto-accepted using the "most balanced" heuristic (no extreme risk/reward mutations are auto-selected). The player can undo the last auto-mutation for free within 5 minutes of returning.

### 4.6 Mutation System

At each stage transition (Spore→Sprout, Sprout→Bud, Bud→Bloom), the seed undergoes a **mutation roll**. The mutation is procedurally selected based on:

1. Seed species (biome-specific mutation weights)
2. Current elemental affinity
3. Applied soil amendments
4. Existing mutations (some chain: e.g., Bountiful → Bountiful upgrades to "Overflowing")
5. Deterministic roll (generation_seed + stage_index)

#### Mutation Categories

| Category | Dungeon Effect | Risk/Reward Profile | Example |
|----------|---------------|---------------------|---------|
| **Bountiful** | +Loot quantity, +Chest frequency, +Gold drops | Low risk, moderate reward | "Rooms shimmer with gold dust. +2 treasure rooms, +20% Gold." |
| **Perilous** | +Enemy difficulty, +Elite spawn rate, +XP/loot quality | High risk, high reward | "The dungeon bristles with danger. +15% elite chance, +25% loot rarity." |
| **Labyrinthine** | +Room count, +Branching paths, +Secret rooms | Moderate risk, exploration reward | "Corridors twist and multiply. +30% rooms, +1 secret room." |
| **Elemental Surge** | Shifts dungeon affinity, +Elemental enemy density | Matchup dependent | "Frost energy seeps through the walls. Affinity shifts toward Frost." |
| **Temporal** | Modifies growth timers (faster/slower next stage) | Meta-efficiency | "Time ripples around the seed. Next growth stage −40% duration." |
| **Parasitic** | +Boss difficulty, −Room count, +Boss loot multiplier | Boss-rush style | "The dungeon contracts around its heart. −40% rooms, boss ×1.5 stats and loot." |
| **Fertile** | +Chance to drop new seeds from dungeon | Low combat value, high meta-value | "Life energy pulses within. Seed drop rate +17% (base 8% → 25%)." |
| **Chaotic** | Randomizes one existing property | Wild card | "Reality warps. One dungeon parameter is randomized." |

#### Mutation Slot Limits

| Seed Rarity | Max Mutations | Base Vigor Range |
|-------------|--------------|------------------|
| Common | 1 | 1–30 |
| Uncommon | 1 | 15–50 |
| Rare | 2 | 30–70 |
| Epic | 2 | 50–90 |
| Legendary | 3 | 70–100 |

#### Mutation Player Actions

| Action | Cost | Effect |
|--------|------|--------|
| **Accept** | Free | Take the offered mutation. Fills a mutation slot. |
| **Reject & Reroll** | Verdant Essence (scales with rarity: 20/40/80/150/300) | Reject the offered mutation and roll a new one from the remaining pool. One reroll per stage. |
| **Redirect** | Catalyst item (rare dungeon drop) | Force the mutation into a specific *category* (but not a specific mutation within that category). Catalysts are element-coded. |
| **Shield** | Seed Shield item (crafted) | Prevent the mutation entirely. The slot remains open for the next stage. |

### 4.7 Soil Amendments

Soil amendments are consumable items applied to a seed before or during growth to influence development.

| Amendment | Effect | Acquisition |
|-----------|--------|-------------|
| **Elemental Compost (×5 types)** | Shifts seed affinity toward target element by 1 tier | Crafted from elemental drops |
| **Vigor Tonic** | +10 Vigor (caps at rarity max) | Purchased from Shop (Gold) |
| **Mutation Catalyst (×8 types)** | Forces next mutation into a specific category | Rare dungeon drops |
| **Temporal Fertilizer** | −25% growth time for next stage | Crafted from Temporal materials |
| **Seed Shield** | Prevents next mutation (preserves current state) | Crafted from rare materials |
| **Purity Extract** | Removes one existing mutation, freeing the slot | Boss drops (Rare+) |

### 4.8 Seed Acquisition

Seeds are obtained through:

| Source | Rarity Range | Rate | Notes |
|--------|-------------|------|-------|
| **Expedition Drops** | Common–Rare (biome-matched) | ~8% base, ~25% with Fertile mutation | Primary renewable source |
| **Shop Purchase** | Common–Rare | 3–5 seeds/day, rotating | Costs Gold or Seed Tokens |
| **Achievement Rewards** | Specific rarity/species | On milestone completion | Guaranteed species and minimum Vigor |
| **Seed Breeding** (post-MVP) | Blended from parents | Combines two consumed seeds | Produces seed with mixed properties |
| **Starting Seeds** | Common, Vigor 10 | 1 per element at game start | Ensures every player can begin immediately |
| **Guild Favor Exchange** | Uncommon–Epic | Costs Guild Favor currency | Higher-quality seeds for invested players |

### 4.9 Seed Sharing

Because generation is deterministic, a seed's 8-character code + species + affinity + mutation list fully describes the resulting dungeon. Players can share codes externally (forums, Discord, social media, Reddit).

**Importing a shared seed:**
- Enter the code on the Seed Vault's "Import" screen
- Creates a copy of that seed in the player's vault
- Costs Gold (scales with rarity)
- Limited to 3 imports per day (prevents trivializing progression)
- Imported seeds display a 🔗 icon indicating they are community-sourced

**Community integration (post-MVP):** In-game seed board where players can rate and share seeds tagged with difficulty, loot highlights, and recommended party compositions.

---

## 5. Expedition System

### 5.1 Overview

Expeditions are the active gameplay core of Dungeon Seed. The player sends an adventurer party into a Bloom-stage dungeon to clear rooms, defeat enemies, and harvest loot. Expeditions auto-resolve — the player's strategic decisions are made *before* launching, and execution is handled by the AI.

### 5.2 Dungeon as Abstract Graph

**Critical design decision:** Dungeons in Dungeon Seed are **abstract node-and-edge graphs**, NOT spatial tilemaps. Each room is a node. Each connection between rooms is an edge. The player sees a graph visualization (think: node map, not Zelda dungeon), and the party traverses nodes in sequence.

```
Example Dungeon Graph (Vigor 42, 14 rooms, Bountiful mutation):

  [Entrance]──[Combat]──[Combat]──[Treasure]──[Rest]
                  │                               │
              [Combat]──[Secret]              [Combat]
                  │                               │
              [Treasure]                     [Combat]──[Combat]──[Boss: Pyrax]
                                                 │
                                             [Treasure]──[Rest]

  Critical Path: Entrance → C → C → T → Rest → C → C → C → Boss (9 rooms)
  Optional Branches: 5 rooms (2 treasure, 1 secret, 1 combat, 1 rest)
  Total: 14 rooms
```

**Design rationale for abstract graph:**
1. **No pathfinding complexity** — party moves node-to-node, not tile-to-tile
2. **Clean auto-resolution** — each node is a self-contained encounter
3. **Strategic clarity** — the player sees the entire dungeon structure upfront (or progressively reveals it, based on party PER)
4. **Performance** — no spatial rendering, no tilemap memory, no collision detection
5. **Deterministic reproducibility** — graph topology is trivially serializable and shareable
6. **Mobile-friendly** — node-tap navigation works naturally on touch screens

### 5.3 Dungeon Generation Pipeline

All generation is deterministic from the seed's properties:

```
Step 1: Initialize RNG ← generation_seed
Step 2: Calculate dungeon parameters ← Vigor + Mutations + Biome
Step 3: Generate room graph ← Modified BSP → graph connectivity
Step 4: Assign room types ← Entrance, Combat, Treasure, Puzzle, Rest, Boss, Secret
Step 5: Apply biome template ← Enemy pool, trap pool, visual theme
Step 6: Place encounters ← Enemy compositions per combat room
Step 7: Place loot ← Chest contents, drop tables, hidden stashes
Step 8: Place traps & hazards ← Biome-specific environmental effects
Step 9: Apply mutation modifiers ← Re-roll rooms, add/remove content
Step 10: Validate critical path ← Ensure dungeon is completable
Step 11: Output: DungeonData resource (serializable, deterministic)
```

### 5.4 Dungeon Parameters (Vigor-Scaled)

| Parameter | Vigor 1 | Vigor 25 | Vigor 50 | Vigor 75 | Vigor 100 | Mutation Modifiers |
|-----------|---------|----------|----------|----------|-----------|-------------------|
| **Room Count** | 5–7 | 8–11 | 12–16 | 16–22 | 20–28 | Labyrinthine +30%, Parasitic −40% |
| **Branching Factor** | 0.1 (linear) | 0.2 | 0.3 (some branches) | 0.4 | 0.5 (many branches) | Labyrinthine +0.2 |
| **Enemy Density** | 0.4 (40% rooms have combat) | 0.5 | 0.65 | 0.75 | 0.85 | Perilous +0.15 |
| **Treasure Density** | 0.2 | 0.25 | 0.3 | 0.33 | 0.35 | Bountiful +0.15 |
| **Trap Density** | 0.1 | 0.15 | 0.2 | 0.25 | 0.3 | (none) |
| **Elite Chance** | 2% per enemy | 5% | 8% | 12% | 15% | Perilous +10% |
| **Boss Count** | 1 | 1 | 1 | 1 | 1–2 | Parasitic: guaranteed 1 at ×1.5 stats |
| **Secret Rooms** | 0 | 0 | 0–1 | 1–2 | 1–3 | Labyrinthine +1 |
| **Loot Quality Mult** | ×0.5 | ×0.75 | ×1.0 | ×1.25 | ×1.5 | Bountiful +0.2 |

### 5.5 Room Types

| Room Type | % of Rooms | Content | On Critical Path? | Graph Representation |
|-----------|------------|---------|-------------------|---------------------|
| **Entrance** | 1/dungeon | Starting room. No enemies. Contains lore inscription about the dungeon's seed origin. | Always first | 🚪 |
| **Combat** | 40–60% | 1–4 enemy groups. Elemental alignment matches dungeon affinity ±1 shift. | Yes | ⚔️ |
| **Treasure** | 10–20% | 1–3 chests (may be trapped). Contains equipment, materials, Gold. | Preferred on branches | 💰 |
| **Rest** | 2/dungeon | Partial HP/MP recovery (30% HP, 20% MP). Campfire aesthetic. No enemies. | Yes (placed at ~40% and ~70% of critical path) | 🔥 |
| **Boss** | 1–2/dungeon | Powerful enemy/group. Enhanced loot table. Dungeon completion flag. | Always last on critical path | 💀 |
| **Secret** | 0–3/dungeon | Hidden rooms requiring high PER or specific party composition to discover. Premium loot. | Never (always branch) | ❓ |
| **Puzzle** | 5–10% (post-MVP) | Skill check against party stats. Rewards bypass or bonus loot. | Optional | 🧩 |

### 5.6 Room Discovery & Fog of War

The dungeon graph is **partially hidden** at expedition start:

- **Entrance and all rooms on the critical path** are always visible (the player can see the general length and room types of the main route).
- **Branch rooms** are hidden until the party reaches an adjacent node. A party member's PER stat determines discovery radius:
  - PER < 10: Can only see rooms directly adjacent to current room
  - PER 10–20: Can see 2 rooms ahead on branches
  - PER 20+: Full branch visibility from any connected node
- **Secret rooms** require a PER check to discover (threshold varies by dungeon Vigor). Rogues' Lockpick skill and Rangers' Scout skill provide bonuses to secret room discovery.

### 5.7 Encounter Composition

Each combat room contains 1–4 enemy **slots** filled from biome-specific composition tables:

| Vigor Tier | Tier Name | Enemy Count | Elite Chance | Composition Rule |
|------------|-----------|-------------|--------------|-----------------|
| 1–25 | Seedling | 1–2 | 2% | Single type per room. Simple encounters. |
| 26–50 | Growing | 2–3 | 8% | Up to 2 types. Synergy pairings possible. |
| 51–75 | Mature | 2–4 | 12% | Mixed compositions. At least 1 support enemy. |
| 76–100 | Ancient | 3–4 | 15% | Designed compositions with tank/DPS/support roles. |

**Enemy Synergy (Vigor 26+):** At higher tiers, enemies are placed in intentional compositions. Example: a Frost Weaver (applies Slow debuff) paired with a Glacial Bear (+50% damage to slowed targets). These synergies are defined in authored per-biome composition tables — not randomly assembled.

### 5.8 Biome Definitions

Each biome is a thematic template applied to the dungeon graph. Biomes determine visual assets, enemy pools, trap types, environmental hazards, and ambient audio.

#### 5.8.1 Verdant Hollow (Terra) — MVP BIOME

- **Theme:** Overgrown underground gardens, root-covered walls, bioluminescent mushrooms, mossy stone, underground streams.
- **Enemy Pool:** Fungal Crawler (swarm, poison), Vine Lasher (ranged, root), Bark Golem (tank, high DEF), Thorn Sentinel (DPS, bleed), **Elder Treant** (boss — summons minions, AoE root).
- **Traps:** Spore clouds (Poison DoT), Vine snares (Root/immobilize), Pitfall traps (damage + skip next room).
- **Environmental Hazard:** *Toxic Bloom* — periodically releases spore clouds affecting all connected rooms. Party-wide Poison tick if lingering.
- **Loot Affinity:** Terra-element materials, nature-themed equipment, Verdant Essence bonus (+15%).

#### 5.8.2 Embervault (Flame) — Post-MVP

- **Theme:** Volcanic forge complex, rivers of magma, blackened stone, forge anvils, heat shimmer.
- **Enemy Pool:** Magma Slime (AoE splash), Forge Drone (armor buff allies), Ember Wraith (high ATK, low HP), Infernal Smith (healer/buffer), **Pyrax the Forgelord** (boss — phase 2 floods room with lava).
- **Traps:** Lava geysers (burst damage), Heat vents (gradual HP drain per turn in room), Exploding barrels (AoE on trigger).
- **Environmental Hazard:** *Rising Heat* — each room visited increases ambient fire damage by +2% (cumulative). Encourages fast, efficient clears.
- **Loot Affinity:** Flame-element materials, weapon-focused drops, forging materials.

#### 5.8.3 Frostmere (Frost) — Post-MVP

- **Theme:** Frozen underground lake, ice caverns, crystalline formations, snowdrift corridors.
- **Enemy Pool:** Ice Shard (swarm), Frost Weaver (Slow debuff), Glacial Bear (bonus vs Slowed), Cryomancer (AoE Freeze), **Frostmere Hydra** (boss — multiple heads, rewards multi-target attackers).
- **Traps:** Black ice floors (displacement), Icicle drops (ceiling trigger), Freezing mist (Slow debuff).
- **Environmental Hazard:** *Encroaching Frost* — unvisited rooms slowly "freeze," increasing enemy DEF by +10% per unvisited turn. Punishes backtracking.
- **Loot Affinity:** Frost-element materials, defensive/armor drops, preservation materials.

#### 5.8.4 Shimmerdeep (Arcane) — Post-MVP

- **Theme:** Reality-warped caverns, floating platforms, prismatic crystals, arcane circuit patterns.
- **Enemy Pool:** Mana Wisp (swarm, mana drain), Mirror Mimic (copies party member stats), Arcane Construct (high HP, Silence), Phase Stalker (teleports, high crit), **The Paradox** (boss — phase shifts change its element each phase).
- **Traps:** Teleport tiles (random room displacement), Mana drain fields (reduce party MP), Illusion walls (false paths on graph).
- **Environmental Hazard:** *Arcane Instability* — room connections may shift between visits, changing available paths. Graph edges can rewire (deterministically from seed).
- **Loot Affinity:** Arcane-element materials, accessory/trinket drops, enchanting materials.

#### 5.8.5 Voidmaw (Shadow) — Post-MVP

- **Theme:** Abyssal darkness, corroded stone, organic walls, whispering echoes, reality tears.
- **Enemy Pool:** Shadow Creeper (stealth, backstab), Void Leech (HP drain), Hollow Knight (high DEF, Silence), Abyssal Weaver (AoE debuffs), **Maw of the Void** (boss — darkness zone mechanic, party accuracy reduced).
- **Traps:** Darkness zones (−50% accuracy), Corruption pools (stacking debuff), Soul anchors (prevent retreat from room).
- **Environmental Hazard:** *Creeping Void* — a darkness "fog" advances from the entrance, making cleared rooms dangerous to revisit. Graph nodes behind the party become hostile.
- **Loot Affinity:** Shadow-element materials, high-risk/high-value drops, mutation catalysts.

### 5.9 Boss Encounters

Each biome has one primary boss and one variant boss (variant unlocked by specific mutations). Bosses have:

**Phase System:**
- 2–3 phases at HP thresholds: 75%, 50%, 25%
- Phase transitions grant a momentary shield (absorbs fixed damage)
- New phases may: summon minions, change element, gain new abilities, increase stats, alter battlefield conditions

**Boss AI:** Hand-authored per boss (not generated from generic tables). Each boss tests different party compositions:

| Boss | Biome | Test | Counter |
|------|-------|------|---------|
| **Elder Treant** | Verdant Hollow | Summons minions each phase → overwhelms parties without AoE | Bring Mage/Ranger for AoE damage |
| **Pyrax the Forgelord** | Embervault | Phase 2 lava flood → party-wide Flame damage/turn | Bring Frost-element attackers + Alchemist healer |
| **Frostmere Hydra** | Frostmere | Multiple heads → single-target DPS insufficient | Bring multi-target attackers (Rain of Arrows, Arcane Storm) |
| **The Paradox** | Shimmerdeep | Changes element each phase → static elemental strategy fails | Bring Mage with element-flex or diverse party elements |
| **Maw of the Void** | Voidmaw | Darkness zone → −50% accuracy → DPS check | Bring high-PER party + Sentinel Purify for debuff removal |

**Boss Loot:** Guaranteed Rare+ drop, chance for Epic/Legendary, always drops 1 crafting material unique to that boss (used in Legendary recipes).

### 5.10 Difficulty Rating

Dungeon difficulty is calculated deterministically and displayed to the player before launching:

```
EffectiveDifficulty = (Vigor × BiomeDifficultyMultiplier) + MutationDifficultySum

BiomeDifficultyMultiplier:
  Verdant Hollow: 1.0   (baseline)
  Embervault:     1.1   (fire damage pressure)
  Frostmere:      1.05  (crowd control heavy)
  Shimmerdeep:    1.15  (unpredictable)
  Voidmaw:        1.3   (maximum challenge)

MutationDifficulty values:
  Perilous:       +15
  Parasitic:      +10
  Elemental Surge: +5
  Labyrinthine:    +3
  Bountiful:       0
  Temporal:        0
  Fertile:         0
  Chaotic:        +5 (unpredictability)
```

**Skull Rating (player-facing):** The EffectiveDifficulty is compared against the player's current party power to produce a 1–5 skull rating:

| Skulls | Meaning | Party Power vs Difficulty |
|--------|---------|-------------------------|
| ☠ | Trivial | Party power > 150% of difficulty |
| ☠☠ | Easy | Party power 120–150% |
| ☠☠☠ | Fair | Party power 80–120% |
| ☠☠☠☠ | Hard | Party power 50–80% |
| ☠☠☠☠☠ | Deadly | Party power < 50% |

### 5.11 Expedition Flow

```
Pre-Expedition:
  1. Select Bloom-stage dungeon from Garden
  2. View dungeon preview (biome, affinity, Vigor, mutations, room count, skull rating)
  3. Assemble party (1–4 adventurers, drag from roster)
  4. Review/adjust equipment, skills, consumables per adventurer
  5. Set Tactical Directives (see §9.4)
  6. Confirm: "Embark" (point of no return — seed will be consumed)

During Expedition:
  7. Party enters Entrance room (lore inscription)
  8. Party traverses graph node by node along critical path
  9. At each branch point: AI decides whether to explore branch (based on party condition, directive, PER)
  10. Combat rooms: auto-battle resolves (see §9)
  11. Treasure rooms: loot collected automatically
  12. Rest rooms: party heals (30% HP, 20% MP)
  13. Secret rooms: PER check determines discovery
  14. Boss room: enhanced combat encounter
  15. Player can watch at 1×/2×/4× speed or Skip (instant resolve)

Post-Expedition:
  16. Results screen: rooms cleared, enemies defeated, loot collected, XP earned
  17. Per-adventurer breakdown: damage dealt, damage taken, skills used, MVP badge
  18. Loot preview with rarity reveals (animated for Rare+)
  19. Seed consumed (regardless of win/loss)
  20. Adventurer conditions updated (Healthy → Fatigued/Injured/Exhausted)
  21. Return to Garden
```

### 5.12 Retreat Mechanics

The player can set a **Retreat Threshold** (unlocked at Seedwarden Level 7) — an HP percentage at which the party automatically retreats from the dungeon:

- Default: 0% (never retreat — fight until victory or total party KO)
- Configurable: 10%, 25%, 50%, 75%
- On retreat: expedition ends immediately. Party keeps loot from rooms cleared so far. Adventurers receive Fatigued condition (not Injured/Exhausted). The seed is still consumed.

**Design rationale:** Retreat lets cautious players preserve adventurer condition at the cost of forfeiting remaining dungeon loot. It's a meaningful risk/reward choice: push deeper for better loot, or retreat early to keep your party healthy for the next run.

### 5.13 Expedition Consumables

Before launching, the player can assign consumables to party members:

| Consumable | Effect | Trigger | Source |
|------------|--------|---------|--------|
| **Health Potion** | Restore 30% HP | When HP < 40% | Crafted, Shop |
| **Mana Potion** | Restore 50% MP | When MP < 30% | Crafted, Shop |
| **Antidote** | Cure Poison/Burn status | On status application | Crafted |
| **Smoke Bomb** | Party-wide evasion +50% for 1 turn | When 2+ party members < 50% HP | Boss drops |
| **Elemental Scroll (×5)** | Deal elemental damage to all enemies (one use) | Player-configured priority | Crafted from elemental materials |
| **Scout's Lantern** | Reveal all hidden rooms for this expedition | On expedition start | Crafted, Rare drop |

Each adventurer can carry **2 consumable slots**. Consumables are consumed even on failed expeditions (a meaningful cost of failure).

---

## 6. Adventurer System

### 6.1 Overview

Adventurers are the player's agents in the dungeon. The player never directly controls an adventurer in real time — instead, they recruit, equip, level, and direct adventurers who then auto-resolve encounters based on their stats, equipment, skills, and the player's tactical directives.

**No permadeath — ever.** Adventurers who are knocked out during an expedition are "recalled" to the guild hall with injuries. They require recovery time (real-time, ticks offline) but are never permanently lost. Equipment is never lost or damaged. This is a non-negotiable design decision: players must feel safe investing time and resources into their adventurers.

### 6.2 Adventurer Properties

| Property | Type | Description |
|----------|------|-------------|
| **Name** | String | Procedurally generated from culture-themed name tables. Player can rename at any time. |
| **Class** | Enum | One of 6 classes (see §6.3). Permanent — chosen at recruitment. |
| **Level** | int (1–50) | Current experience level. Determines base stat scaling and skill slot count. |
| **XP** | int | Experience toward next level. Earned from expeditions and Training Hall. |
| **Stats** | StatBlock | HP, MP, ATK, DEF, SPD, PER (see §6.4). |
| **Equipment** | EquipmentLoadout | Weapon, Armor, Accessory slots (see §10). |
| **Skills** | Array[Skill] | 3–5 active/passive skills depending on class and level (see §6.5). |
| **Affinity** | Element | Innate elemental lean. Affects damage dealt/taken by ±10%. Randomized at recruitment. |
| **Condition** | Enum | Healthy, Fatigued, Injured, Exhausted. Affects stat multipliers and requires recovery time. |
| **Morale** | int (0–100) | Affects crit chance and retreat threshold. Rises with victories (+5), falls with defeats (−10), KOs (−20). Recovers +2/hour passively. |

### 6.3 Classes

Six adventurer classes, designed for distinct party roles. Each class has a clear identity, unique utility, and at least one scenario where they are the optimal choice.

#### 6.3.1 Warrior — Frontline Tank / Melee DPS

| Aspect | Detail |
|--------|--------|
| **Role** | Absorbs damage, protects squishier members. Essential in high-enemy-count rooms. |
| **Stat Focus** | HP +++, ATK ++, DEF ++, SPD +, MP −, PER − |
| **Weapon Types** | Swords, Axes, Hammers |
| **Armor Type** | Heavy |
| **Key Skills** | **Cleave** (AoE melee, 1.2× ATK to all enemies), **Shield Wall** (party DEF +20% for 3 turns), **Taunt** (force all enemies to target Warrior for 2 turns), **Berserker Rage** (ATK +40%, DEF −20% for 3 turns) |
| **Unique Utility** | Taunt redirects boss attacks away from fragile party members. Shield Wall stacks with Sentinel's Barrier. |
| **Best Against** | High enemy count rooms, bosses with single-target heavy attacks |
| **Weak Against** | Magic-heavy enemies (low MP, no magic resist), AoE bypasses taunt |

#### 6.3.2 Ranger — Ranged DPS / Utility

| Aspect | Detail |
|--------|--------|
| **Role** | High single-target damage. Scout and Trap Sense provide dungeon utility beyond combat. |
| **Stat Focus** | ATK ++, SPD +++, PER ++, HP +, DEF −, MP − |
| **Weapon Types** | Bows, Crossbows |
| **Armor Type** | Medium |
| **Key Skills** | **Snipe** (single-target 2.0× ATK), **Rain of Arrows** (AoE 0.8× ATK to all), **Trap Sense** (reveal and disarm traps in current + adjacent rooms), **Scout** (reveal all rooms connected to current room, including secrets) |
| **Unique Utility** | Scout reveals branch rooms and secrets before committing. Trap Sense prevents trap damage entirely. |
| **Best Against** | Dungeons with many traps, secret-heavy layouts (Labyrinthine seeds) |
| **Weak Against** | Sustained fights (no self-heal, medium armor), magic-heavy enemies |

#### 6.3.3 Mage — Elemental DPS / AoE Specialist

| Aspect | Detail |
|--------|--------|
| **Role** | Exploits elemental weaknesses. Strongest AoE damage. Fragile — needs protection. |
| **Stat Focus** | MP +++, ATK ++ (magic), SPD +, HP −, DEF −, PER + |
| **Weapon Types** | Staves, Wands, Tomes |
| **Armor Type** | Light (Robes) |
| **Key Skills** | **Elemental Blast** (single-target 1.8× ATK, element based on weapon), **Arcane Storm** (AoE 1.0× ATK, element based on equipped tome), **Mana Shield** (convert MP to HP temporarily: 1 MP absorbs 2 damage), **Enchant Weapon** (buff an ally's attacks with Mage's element for 3 turns) |
| **Unique Utility** | Elemental flexibility via weapon swaps. Enchant Weapon lets physical attackers exploit elemental weaknesses. |
| **Best Against** | Dungeons where party has elemental advantage (×1.5 on every spell) |
| **Weak Against** | Silence effects, mana drain traps, sustained physical damage |

#### 6.3.4 Rogue — Burst DPS / Secret Discovery

| Aspect | Detail |
|--------|--------|
| **Role** | Highest burst damage in the game. Critical for Secret Room discovery and locked chests. |
| **Stat Focus** | SPD +++, ATK ++, PER ++, HP +, DEF −, MP − |
| **Weapon Types** | Daggers, Short Swords |
| **Armor Type** | Light |
| **Key Skills** | **Backstab** (single-target 2.5× ATK, only usable from Stealth — guaranteed crit), **Smoke Bomb** (party evasion +40% for 2 turns, Rogue enters Stealth), **Lockpick** (open locked chests/doors without keys, +15% loot quality from chests), **Shadow Step** (enter Stealth, guaranteed first strike next combat round) |
| **Unique Utility** | Lockpick opens bonus loot in treasure rooms. High PER + Stealth enables Secret Room discovery. Backstab from Stealth is the highest single-target damage in the game. |
| **Best Against** | Treasure-heavy dungeons (Bountiful mutation), boss encounters (burst phases) |
| **Weak Against** | AoE damage (can't dodge it), swarm encounters (single-target focused) |

#### 6.3.5 Alchemist — Support / Healer / Buffer

| Aspect | Detail |
|--------|--------|
| **Role** | Only reliable in-combat healer. Elixir buffs stack with equipment. Transmute provides resource efficiency. |
| **Stat Focus** | MP ++, PER ++, HP ++, DEF +, ATK −, SPD + |
| **Weapon Types** | Flasks, Slings |
| **Armor Type** | Medium |
| **Key Skills** | **Healing Draught** (single-target heal: 25% of target's max HP), **Elixir Toss** (AoE buff to party: +15% ATK or +15% DEF for 3 turns, varies by equipped flask), **Acid Splash** (enemy DEF −25% for 3 turns), **Transmute** (convert 1 dungeon material drop into a consumable mid-run: iron ore → health potion, etc.) |
| **Unique Utility** | Healing Draught is the only reliable in-combat healing. Transmute converts unwanted material drops into useful consumables. |
| **Best Against** | Extended dungeon runs (sustain), boss fights (healing through phases) |
| **Weak Against** | Speed — lowest DPS class. If enemies outpace healing, party still falls. |

#### 6.3.6 Sentinel — Defensive Support / Anti-Magic Tank

| Aspect | Detail |
|--------|--------|
| **Role** | Superior magical defense. Complements Warrior's physical tanking. Debuff removal. |
| **Stat Focus** | DEF +++, HP ++, MP +, PER +, ATK −, SPD − |
| **Weapon Types** | Shields, Maces |
| **Armor Type** | Heavy |
| **Key Skills** | **Barrier** (party-wide damage reduction: all incoming damage −25% for 2 turns), **Purify** (remove all debuffs from one ally, +10% HP heal), **Holy Ward** (reflect 30% of magic damage taken back to attacker for 3 turns), **Fortify** (increase party DEF by +15% for the entire next room — persists between combats) |
| **Unique Utility** | Purify is the only debuff removal in the game. Fortify persists between rooms — unique among all skills. Holy Ward punishes magic-heavy enemies. |
| **Best Against** | Arcane/Shadow dungeons (magic-heavy enemies, debuff-heavy encounters) |
| **Weak Against** | Physical brute-force enemies (Warrior is better), speed-sensitive encounters |

### 6.4 Stat Definitions

| Stat | Abbr | Function | Visible to Player? |
|------|------|----------|-------------------|
| **Hit Points** | HP | Health pool. Adventurer is knocked out at 0 HP. Partially recovers at Rest rooms. | Yes — bar display |
| **Mana Points** | MP | Resource for skill usage. Regenerates 5% between rooms. | Yes — bar display |
| **Attack** | ATK | Outgoing damage (physical for melee/ranged, magical for spells based on weapon type). | Yes — number |
| **Defense** | DEF | Reduces incoming damage. Physical and magical defense combined into one stat (MVP simplicity). | Yes — number |
| **Speed** | SPD | Turn order in combat. Higher SPD acts first. Also affects evasion chance: `evasion% = SPD / 4` (cap 25%). | Yes — number |
| **Perception** | PER | Trap detection, secret room discovery, critical hit chance: `crit% = 5 + (PER / 10)` (cap 25%). | Yes — number |

**Stat Growth per Level:**

Each level grants stat points allocated automatically according to class growth rates. No manual stat allocation in MVP (simplicity).

```
EffectiveStat = (BaseStat + (Level × ClassGrowthRate)) × EquipmentMultiplier × ConditionMultiplier × MoraleModifier
```

| Class | HP/lvl | MP/lvl | ATK/lvl | DEF/lvl | SPD/lvl | PER/lvl |
|-------|--------|--------|---------|---------|---------|---------|
| Warrior | 12 | 2 | 4 | 4 | 2 | 1 |
| Ranger | 6 | 2 | 4 | 2 | 5 | 4 |
| Mage | 4 | 6 | 4 | 1 | 2 | 3 |
| Rogue | 6 | 2 | 4 | 1 | 5 | 5 |
| Alchemist | 8 | 5 | 2 | 3 | 2 | 4 |
| Sentinel | 10 | 3 | 2 | 5 | 1 | 3 |

**Base Stats (Level 1):**

| Class | HP | MP | ATK | DEF | SPD | PER |
|-------|----|----|-----|-----|-----|-----|
| Warrior | 80 | 15 | 18 | 16 | 10 | 6 |
| Ranger | 50 | 15 | 16 | 10 | 20 | 14 |
| Mage | 40 | 40 | 18 | 6 | 10 | 12 |
| Rogue | 50 | 15 | 16 | 6 | 22 | 18 |
| Alchemist | 60 | 35 | 10 | 12 | 10 | 14 |
| Sentinel | 70 | 20 | 10 | 20 | 6 | 12 |

### 6.5 Skill System

Each class has a skill tree of 8–10 skills, of which 3–5 can be equipped at any time:

| Level Range | Skill Slots Available |
|-------------|----------------------|
| 1–10 | 3 |
| 11–25 | 4 |
| 26–50 | 5 |

**Skill Unlock Schedule (per class):** New skills unlock at levels 1, 5, 10, 15, 20, 30, 40, 50. Skills can be freely swapped outside of expeditions. Skills have MP costs, cooldowns (measured in combat turns), and some have synergy bonuses when paired with specific other skills or party members.

**Skill Synergies (examples):**
- Warrior's Taunt + Sentinel's Barrier = "Iron Fortress" (additional +10% DEF when both active)
- Mage's Enchant Weapon + Rogue's Backstab = Backstab deals enchanted element damage (double advantage if matched)
- Alchemist's Acid Splash + Ranger's Snipe = Snipe deals bonus damage to DEF-debuffed targets (+25%)

### 6.6 Adventurer Recruitment

| Aspect | Detail |
|--------|--------|
| **Location** | Tavern screen → Recruitment tab |
| **Available Recruits** | 3 adventurers displayed, randomized class/affinity/stats |
| **Refresh** | Daily auto-refresh. Manual refresh costs 50 Gold. |
| **Recruitment Cost** | Scales with recruit level: Level 1 = 100 Gold, Level 5 = 250 Gold. New recruits range Level 1–5. |
| **Roster Limit** | Starts at 6 (one per class). Expandable to 8/10/12 via guild upgrades. |
| **Affinity** | Randomized at recruitment. Player can spend 100 Gold to reroll affinity once per recruit. |

**Higher-Level Recruits:** After Seedwarden Level 5, recruits can appear at Level 5–10. After Level 10, up to Level 15. This provides a catch-up mechanic for new class recruitment in mid-game.

### 6.7 Condition System (No Permadeath)

After an expedition, adventurers accumulate fatigue based on performance:

| Condition | Stat Multiplier | Recovery Time | Cause |
|-----------|----------------|---------------|-------|
| **Healthy** | ×1.0 | — | Default state. Ready for expedition. |
| **Fatigued** | ×0.9 (−10%) | 15 min | Completed a full dungeon or retreated early. |
| **Injured** | ×0.75 (−25%) | 45 min | Knocked out (0 HP) during expedition. |
| **Exhausted** | ×0.6 (−40%) | 90 min | Knocked out AND expedition failed (total party wipe). |

**Key rules:**
- Recovery timers run in real time, **including offline**. This is the Cultivator fantasy — patience heals.
- The Tavern's "Rest" upgrade (guild hall facility) reduces recovery time by up to 30%.
- Adventurers CAN be sent on expeditions while Fatigued/Injured/Exhausted — they just have reduced stats. This preserves player agency: "I *can* send my Injured warrior, but should I?"
- No Condition worse than Exhausted exists. No permadeath. No retirement. No permanent stat loss.

**Design rationale:** The condition system encourages maintaining a **deep roster** rather than running the same 4 adventurers forever. When your A-team is recovering, your B-team gets their chance. This drives recruitment, leveling breadth, and equipment diversity.

### 6.8 Party Composition

Parties consist of 1–4 adventurers. Common compositions:

| Composition | Strengths | Weaknesses | Ideal For |
|-------------|-----------|------------|-----------|
| **Warrior + Ranger + Mage + Alchemist** | Balanced: tank + DPS + AoE + heal | Low PER (miss secrets), no debuff removal | General purpose, first clears |
| **Warrior + Rogue + Ranger + Mage** | High DPS, great exploration (PER) | No healer — risky on long dungeons | Short, high-Vigor dungeons |
| **Warrior + Sentinel + Mage + Alchemist** | Extremely durable, magic-resistant | Low DPS — slow clears | Shimmerdeep / Voidmaw biomes |
| **Rogue + Ranger + Rogue + Mage** | Maximum burst DPS, max PER | Glass cannon — no tank, no heal | Speed-farming low-Vigor seeds |
| **Warrior + Alchemist + Sentinel + Mage** | Unkillable — double tank + heal + DPS | Slow, may timeout on high room counts | Boss farming |

**Solo Expeditions:** Sending a single adventurer is allowed (useful for very low-Vigor dungeons or challenge runs). XP is not split — solo adventurers gain full XP.

---

## 7. Guild & Meta-Progression

### 7.1 Overview

The **Guild Hall** is the player's persistent home base — a physical space that grows and improves over time. It represents the Seedwarden's operations center and houses all facilities (Tavern, Workshop, Garden, Shop, Vault). Guild Hall upgrades provide permanent bonuses that persist across all expeditions and Cultivation Cycles.

The Guild Hall is the meta-progression backbone. While adventurer levels and equipment represent within-run power, guild upgrades represent *permanent, systemic improvements* that make everything the player does more efficient over time.

### 7.2 Guild Hall Facilities

Each facility can be upgraded through multiple tiers. Upgrades cost Gold, Materials, and sometimes Guild Favor. Higher tiers take real-time to construct (another idle element).

#### 7.2.1 The Garden (Seed Growth)

| Tier | Unlock | Cost | Bonus |
|------|--------|------|-------|
| 1 | Start | Free | 1 Garden Plot. Base growth timers. |
| 2 | Seedwarden Lvl 2 | 500 Gold, 200 Materials | 2 Garden Plots. Growth speed +10%. |
| 3 | Seedwarden Lvl 6 | 2,000 Gold, 800 Materials | 3 Garden Plots. Growth speed +20%. |
| 4 | Seedwarden Lvl 9 | 5,000 Gold, 2,000 Materials | 4 Garden Plots. Growth speed +30%. |
| 5 | Seedwarden Lvl 15 | 15,000 Gold, 5,000 Materials | 5 Garden Plots (max). Growth speed +40%. Passive Essence trickle +50%. |

#### 7.2.2 The Tavern (Adventurer Management)

| Tier | Unlock | Cost | Bonus |
|------|--------|------|-------|
| 1 | Start | Free | Recruit adventurers. Roster limit 6. Recovery at base rate. |
| 2 | Seedwarden Lvl 2 | 400 Gold, 150 Materials | Training Hall unlocked (idle XP). Recovery speed +10%. |
| 3 | Seedwarden Lvl 5 | 1,500 Gold, 600 Materials | Roster limit 8. Training Hall XP rate +25%. Recovery speed +20%. |
| 4 | Seedwarden Lvl 12 | 4,000 Gold, 1,500 Materials | Roster limit 10. Higher-level recruits available. Recovery speed +25%. |
| 5 | Seedwarden Lvl 20 | 12,000 Gold, 4,000 Materials | Roster limit 12 (max). Training Hall XP rate +50%. Recovery speed +30%. |

#### 7.2.3 The Workshop (Crafting & Equipment)

| Tier | Unlock | Cost | Bonus |
|------|--------|------|-------|
| 1 | Start | Free | Craft and Salvage functions only. Common–Uncommon recipes. |
| 2 | Seedwarden Lvl 4 | 800 Gold, 300 Materials | Upgrade function unlocked. Rare recipes. Salvage return +10%. |
| 3 | Seedwarden Lvl 8 | 3,000 Gold, 1,200 Materials | Reforge function unlocked. Epic recipes. Crafting cost −10%. |
| 4 | Seedwarden Lvl 10 | 6,000 Gold, 2,500 Materials | Enchant function unlocked. Legendary recipes available. |
| 5 | Seedwarden Lvl 18 | 15,000 Gold, 5,000 Materials | Masterwork crafting (guaranteed max stat rolls). Crafting cost −20%. Salvage return +25%. |

#### 7.2.4 The Vault (Storage & Collection)

| Tier | Unlock | Cost | Bonus |
|------|--------|------|-------|
| 1 | Start | Free | Seed Vault (50 seed capacity). Equipment inventory (100 items). |
| 2 | Seedwarden Lvl 3 | 600 Gold, 200 Materials | Seed Vault +25 capacity. Equipment +50 capacity. Seed Codex unlocked. |
| 3 | Seedwarden Lvl 7 | 2,500 Gold, 1,000 Materials | Seed Vault +25. Equipment +50. Loot log (track all drops historically). |
| 4 | Seedwarden Lvl 14 | 8,000 Gold, 3,000 Materials | Seed Vault +50 (150 total). Equipment +100 (300 total). Auto-salvage rules (configurable). |

#### 7.2.5 The Seed Merchant (Shop)

| Tier | Unlock | Cost | Bonus |
|------|--------|------|-------|
| 1 | Start | Free | Basic shop: Common seeds, basic amendments, basic materials. Daily refresh. |
| 2 | Seedwarden Lvl 3 | 500 Gold | Uncommon seeds available. Consumables tab. |
| 3 | Seedwarden Lvl 6 | 2,000 Gold, 500 Materials | Rare seeds available. Weekly Specials tab (rare catalysts, epic seeds). |
| 4 | Seedwarden Lvl 10 | 5,000 Gold, 1,500 Materials | Epic seeds available (Seed Token cost). Discounted daily rotation (+1 item). |

### 7.3 Seedwarden Level (Meta-Progression Track)

The **Seedwarden Level** is the player's overall progression, earned from all activities. It gates feature unlocks, facility upgrades, and biome access.

| Seedwarden Level | Unlocks |
|-----------------|---------|
| 1 | Base game: Garden (1 plot), Tavern, Workshop (Craft/Salvage), Shop, basic directives |
| 2 | Garden Tier 2 (2 plots), Tavern Tier 2 (Training Hall), Tactical Directives: Focus Fire, Spread Damage |
| 3 | Flame seeds unlocked, All-Out Attack / Defensive Stance directives, Vault Tier 2, Shop Tier 2 |
| 4 | Workshop Tier 2 (Upgrade function) |
| 5 | Frost seeds, Priority: Elites / Priority: Healers directives, Tavern Tier 3 (8-slot roster) |
| 6 | Garden Tier 3 (3 plots), Shop Tier 3 |
| 7 | Retreat Threshold directive, Vault Tier 3 |
| 8 | Arcane seeds, Workshop Tier 3 (Reforge function) |
| 9 | Garden Tier 4 (4 plots) |
| 10 | Element Match directive, Workshop Tier 4 (Enchant function), Shop Tier 4 |
| 12 | Shadow seeds, Tavern Tier 4 (10-slot roster) |
| 14 | Vault Tier 4 |
| 15 | Garden Tier 5 (5 plots, max). Seed Altar (breeding, post-MVP). |
| 18 | Workshop Tier 5 (Masterwork crafting) |
| 20 | Tavern Tier 5 (12-slot roster, max) |
| 25 | Prestige Mode unlock (post-MVP — reset for permanent bonuses) |

**Seedwarden XP Sources:**

| Activity | XP Earned | Notes |
|----------|-----------|-------|
| Complete expedition (victory) | 50 × Dungeon Vigor | Primary XP source |
| Complete expedition (defeat) | 20 × rooms cleared | Partial credit for effort |
| Grow seed to Bloom | 30 × Seed Rarity multiplier | Rewards patient cultivation |
| Craft equipment | 15 × Equipment rarity multiplier | Rewards Workshop engagement |
| Discover secret room | 50 flat | Rewards exploration |
| Clear dungeon with 0 KOs | +25% expedition XP bonus | Rewards clean play |
| Achievement milestone | Varies (100–500) | One-time bonuses |

### 7.4 Guild Favor Currency

**Guild Favor** is the fourth currency (alongside Gold, Verdant Essence, and Materials). It represents the player's overall standing and investment in the guild system.

| Aspect | Detail |
|--------|--------|
| **Earn Rate** | Awarded on expedition completion (5 + Vigor/10, rounded), daily login bonus (+10), achievement milestones |
| **Primary Sinks** | Guild facility upgrades (high tiers), premium seed purchases, cosmetic unlocks |
| **Design Intent** | Long-term engagement currency. Accumulates slowly, spent on impactful permanent upgrades. A player who has played for 2 months should have noticeably more guild upgrades than a 2-week player. |
| **Not purchasable** | Guild Favor cannot be bought with real money. Period. |

### 7.5 Idle / Offline Systems

Idle mechanics exist to **reward** players who step away, not to **require** them to. Active play is always 2–3× more efficient.

#### 7.5.1 Seed Growth (Primary Idle)

Seeds grow in real time, including offline. Growth timers use UTC system clock with drift detection.

- On return: elapsed time calculated, seeds advanced, queued mutations presented
- Growth cap: seeds stop at Bloom. No decay, no pressure, no "you missed it"
- Offline mutation handling: auto-accepted using balanced heuristic, undoable for 5 min on return

#### 7.5.2 Adventurer Training (Secondary Idle)

Adventurers not in a party can be assigned to the Training Hall (Tavern Tier 2+):

| Aspect | Value |
|--------|-------|
| XP rate | ~25% of active expedition XP/hour (diminishing after Level 30) |
| Training cap | 8 hours of accumulated XP. Beyond 8h offline, training pauses. |
| Condition recovery | Always ticks in real time, even without Training Hall |

#### 7.5.3 Resource Trickle (Tertiary Idle)

The Garden generates passive income based on planted seeds:

| Resource | Rate | Condition |
|----------|------|-----------|
| Gold | 5/hour per planted seed (any stage) | Always active |
| Verdant Essence | 2/hour per Bloom-stage seed | Only Bloom seeds |
| Trickle cap | 12 hours of accumulated resources | Prevents infinite accumulation |

#### 7.5.4 Welcome Back Screen

When the player returns after absence, a summary screen displays:

```
┌──────────────────────────────────────────┐
│           WELCOME BACK, SEEDWARDEN       │
│          You were away for 6h 23m        │
│                                          │
│  🌱 Seeds:                               │
│    · Embervault Rare → Bloom (ready!)    │
│    · Verdant Common → Bud (47 min left)  │
│    · Mutation accepted: Bountiful        │
│                                          │
│  ⚔️ Adventurers:                         │
│    · Kira (Warrior) recovered: Healthy   │
│    · Thane (Ranger) trained: +2,340 XP   │
│                                          │
│  💰 Resources:                            │
│    · +180 Gold                           │
│    · +48 Verdant Essence                 │
│    · +10 Guild Favor (daily bonus)       │
│                                          │
│            [Continue →]                  │
└──────────────────────────────────────────┘
```

**Design intent:** The Welcome Back screen makes the player feel time away was productive, creating immediate decision points and a sense of progress.

### 7.6 Prestige System (Post-MVP)

At Seedwarden Level 25, the player can activate **Prestige Mode**:

- Reset: Seedwarden Level, adventurer levels, seed collection, equipment, currencies
- Keep: Guild Facility tiers (permanent), unlocked biomes, Seed Codex discoveries, cosmetics
- Gain: +5% permanent bonus to all resource earnings per prestige level (stacking)
- Gain: Prestige-exclusive cosmetic badges and titles
- Max prestige: 10 (total +50% permanent bonus)

**Design rationale:** Prestige provides endgame replayability for players who exhaust all other content. The kept items (facilities, biomes) ensure subsequent prestige runs are faster, creating a satisfying power curve.

---

## 8. Economy & Resources

### 8.1 Currency Overview

Dungeon Seed uses four currencies, each with a distinct earn rate, sink profile, and design purpose:

| Currency | Icon | Earn Rate | Primary Sources | Primary Sinks | Design Intent |
|----------|------|-----------|-----------------|---------------|---------------|
| **Gold** | 🪙 | High (every activity) | Combat drops, treasure rooms, idle trickle, salvage | Equipment, recruitment, shop, crafting fees, amendments | General-purpose lubricant. Always needed, never hoarded excessively. The player should always have something to spend Gold on. |
| **Verdant Essence** | 🌿 | Medium (expeditions + idle) | Expedition rewards (scaled by Vigor), Bloom seed idle trickle | Seed growth acceleration, soil amendments, mutation rerolls | Growth-cycle currency. Creates a meaningful tension: spend Essence to accelerate growth, or save it for better soil amendments? |
| **Materials** | ⚒️ | Medium (combat drops + salvage) | Combat drops, treasure chests, salvaging equipment | Crafting equipment, guild facility upgrades, consumable creation | Physical resources. Multiple subtypes (Iron Ore, Monster Hide, Arcane Dust, Elemental Essences, Boss Trophies). Collected through play, spent at Workshop. |
| **Guild Favor** | ⭐ | Low (slow accumulation) | Expedition completion, daily login, achievements, rare milestones | Guild facility high-tier upgrades, premium seeds, cosmetics | Long-term engagement currency. A player who has played 2 months should have meaningfully more Favor than a 2-week player. **Cannot be purchased with real money.** |

### 8.2 Material Subtypes

Materials are not a single currency — they are a family of crafting resources, each with specific sources and uses:

| Material | Source | Used For | Drop Frequency |
|----------|--------|----------|----------------|
| **Iron Ore** | Common combat drops (all biomes) | Base material for weapons and armor | High — most common material |
| **Monster Hide** | Combat drops (beast-type enemies) | Armor crafting (Medium/Light) | Medium |
| **Arcane Dust** | Treasure chest loot, salvaging equipment | Accessory crafting, enchanting | Medium-Low |
| **Terra Essence** | Verdant Hollow drops | Terra-element equipment, Terra compost | Biome-specific |
| **Flame Essence** | Embervault drops | Flame-element equipment, Flame compost | Biome-specific |
| **Frost Essence** | Frostmere drops | Frost-element equipment, Frost compost | Biome-specific |
| **Arcane Essence** | Shimmerdeep drops | Arcane-element equipment, Arcane compost | Biome-specific |
| **Shadow Essence** | Voidmaw drops | Shadow-element equipment, Shadow compost | Biome-specific |
| **Boss Trophy** | Boss kills (guaranteed 1 per boss) | Legendary recipe components | Rare — 1 per expedition max |
| **Reforge Stone** | Boss drops (25% chance) | Stat rerolling at Workshop | Rare |
| **Enchanting Shard** | Shimmerdeep-biome specific drops | Element modification at Workshop | Rare |
| **Temporal Residue** | Time-related mutation drops | Temporal Fertilizer crafting | Rare |

### 8.3 Faucet/Sink Balance

```
FAUCETS (Currency Inflow)              SINKS (Currency Outflow)
═══════════════════════                ════════════════════════

GOLD:                                  GOLD:
├─ Combat room drops (5–50 per room)   ├─ Equipment crafting (100–5,000)
├─ Treasure room chests (50–500)       ├─ Equipment upgrading (200–2,000)
├─ Expedition completion bonus         ├─ Adventurer recruitment (100–500)
├─ Salvaging equipment (~40% return)   ├─ Shop purchases (variable)
├─ Idle trickle (5/hr per seed)        ├─ Seed purchase (50–5,000)
└─ Daily login bonus (50)             ├─ Reroll adventurer affinity (100)
                                       ├─ Manual tavern refresh (50)
                                       └─ Soil amendment purchase

VERDANT ESSENCE:                       VERDANT ESSENCE:
├─ Expedition rewards (scaled by       ├─ Growth acceleration (10–100/stage)
│  Vigor: ~2 × Vigor per expedition)   ├─ Mutation reroll (20–300 by rarity)
├─ Idle trickle (2/hr per Bloom seed)  ├─ Soil amendment crafting
└─ Verdant Hollow bonus (+15%)         └─ (Future: Seed breeding)

MATERIALS:                             MATERIALS:
├─ Combat drops (1–3 per combat room)  ├─ Equipment crafting
├─ Treasure chests                     ├─ Guild facility upgrades
├─ Boss guaranteed trophy              ├─ Consumable crafting
├─ Salvaging equipment                 ├─ Soil amendment crafting
└─ Shop purchase (Gold → Materials)    └─ (Future: Seed breeding)

GUILD FAVOR:                           GUILD FAVOR:
├─ Expedition completion (5+Vigor/10)  ├─ High-tier facility upgrades
├─ Daily login bonus (+10)             ├─ Premium seed purchases
├─ Achievement milestones (50–500)     ├─ Cosmetic unlocks
└─ First-clear bonuses                 └─ (Future: Prestige currency)
```

### 8.4 Economy Design Principles

1. **No premium/real-money currency in MVP.** The game is a one-time purchase. All currencies are earnable through gameplay. Guild Favor can NEVER be purchasable.

2. **Gold should feel abundant but never enough.** Multiple competing sinks (equipment, recruitment, shop, crafting, amendments) prevent hoarding. Target: player accumulates ~500 Gold/hour of active play, spends ~400 Gold/hour. Net Gold should slowly grow but never pile up uselessly.

3. **Verdant Essence creates meaningful choices.** Spending Essence to accelerate growth means less Essence for mutation rerolls. This tension is intentional and creates the "should I rush this seed or save for a better reroll?" dilemma.

4. **Materials drive exploration diversity.** Each biome drops biome-specific essences. Players who want Flame equipment must run Embervault dungeons. This drives biome engagement breadth, not just depth.

5. **Guild Favor is aspirational.** Earning enough Favor for a Tier 5 facility upgrade should take ~2 weeks of regular play. This drives long-term engagement without frustration. Favor can never feel like a gate — it's a reward for sustained investment.

6. **Every session feels rewarding.** Even a "bad" expedition (low Vigor, Common seed) should yield enough Gold and Materials to feel worthwhile. The minimum useful expedition should take 5 minutes and yield materials for at least one crafting action.

### 8.5 Economy Pacing Targets

| Milestone | Expected Timeline | Required Resources | Key Unlock |
|-----------|-------------------|-------------------|------------|
| First Bloom dungeon cleared | 30 min | Starting seed + Gold | Core loop validated |
| First Rare equipment crafted | 2 hours | ~1,000 Gold, 50 Iron Ore | Meaningful gear upgrade |
| Second biome unlocked (Flame) | 4–6 hours | Seedwarden Lvl 3 | New content, new elements |
| Full 4-person party equipped Rare | 8–12 hours | ~5,000 Gold, 200 Materials | Mid-game power spike |
| First Epic equipment | 15–20 hours | Boss Trophies, 3,000 Gold | Late-game gear chase |
| Third biome unlocked (Frost) | 12–15 hours | Seedwarden Lvl 5 | Strategic variety |
| First Legendary equipment | 30–40 hours | Multiple Boss Trophies, 10,000+ Gold | Endgame prestige |
| All biomes unlocked | 25–35 hours | Seedwarden Lvl 12 | Full content access |
| Guild Hall fully maxed | 60–80 hours | Massive Gold, Materials, Favor | True endgame |

### 8.6 The Shop

The **Seed Merchant** is a rotating shop with daily and weekly restocking:

| Tab | Stock | Currency | Refresh |
|-----|-------|----------|---------|
| **Seeds** | 3–5 seeds (Common–Rare, or Epic at Shop Tier 4) | Gold (Common–Uncommon), Seed Tokens (Rare+) | Daily |
| **Amendments** | 5–8 soil amendments (elemental composts, tonics) | Gold | Daily |
| **Materials** | Basic crafting materials (Iron Ore, Monster Hide, Arcane Dust) | Gold | Always available |
| **Consumables** | Health Potions, Mana Potions, Antidotes, Scrolls | Gold | Always available |
| **Specials** | 1 rotating special item (Epic seed, rare catalyst, Reforge Stone) | Guild Favor / Seed Tokens | Weekly |

**Pricing examples:**
- Common seed: 100 Gold
- Uncommon seed: 500 Gold
- Rare seed: 3 Seed Tokens
- Vigor Tonic: 200 Gold
- Health Potion: 50 Gold
- Elemental Compost: 150 Gold

### 8.7 Monetization Guardrails (Ethical Framework)

If F2P is adopted post-MVP, these guardrails are **non-negotiable**:

| Rule | Rationale |
|------|-----------|
| **No pay-to-win.** All gameplay-affecting content must be earnable through play. | Pillar 4: Respect the Player's Time. Paying should never bypass the game. |
| **No energy/stamina gates.** | Pillar 4. The condition system provides natural pacing. Artificial gates violate our design. |
| **No randomized loot boxes for gameplay stats.** | Transparent odds or no random purchases at all. |
| **Guild Favor cannot be purchased.** | It represents time invested, not money spent. |
| **Cosmetic-only premium purchases.** | Skins for adventurers, garden decorations, seed packet visuals, UI themes. |
| **Battle pass free track must be meaningful.** | The free track must provide real resources, not scraps. |
| **Seasonal content returns.** | Missed content rotates back. No permanent FOMO. |
| **Transparent pricing.** | No obscured currency exchange rates. If something costs $5, show $5. |

---

## 9. Combat System

### 9.1 Design Philosophy

Combat in Dungeon Seed is **auto-resolved** — the player makes no real-time decisions during battle. All strategic agency occurs **before** the expedition launches: party selection, equipment loadout, skill selection, consumable assignment, and tactical directives.

The battle plays out as an animated sequence the player can watch at 1×, 2×, or 4× speed, or skip entirely for instant resolution. The goal: make *preparation* feel strategic and *execution* feel satisfying to watch, without requiring twitch reflexes or real-time attention.

**Why auto-battle?**
1. **Accessibility:** No dexterity requirement. Playable by everyone.
2. **Idle compatibility:** Players who skip battles still engage via preparation.
3. **Determinism:** Auto-battle + seeded RNG = reproducible outcomes. Same inputs = same fight.
4. **Strategy focus:** Moves the decision-making to party composition, not button timing.

### 9.2 Deterministic Combat Resolution

**Critical rule:** Combat is deterministic given the same inputs. The fight's random number stream is derived from the dungeon's generation_seed + room_index. This means:

- Same seed + same party + same equipment + same skills + same directives + same room = **identical combat outcome every time**
- This enables: strategy guides ("bring Frost Mage to room 7 of seed KXVN-84PQ for guaranteed crit chain"), community optimization, bug reproducibility
- The `Random(0.9, 1.1)` damage variance in the formula is seeded, not truly random

### 9.3 Combat Flow

Each combat room resolves as follows:

```
1. INITIATIVE: Sort all combatants (party + enemies) by SPD.
   Ties broken by: PER (higher first), then deterministic from room seed.

2. ROUND LOOP (repeats until win or loss):
   a. Active combatant selects action via AI priority system (see §9.4).
   b. Action resolves:
      - Damage calculated (see §9.5)
      - Healing applied
      - Buffs/debuffs applied with duration tracking
      - Status effects tick (Poison, Burn, etc.)
   c. Check for KOs:
      - Adventurer at 0 HP → knocked out for remainder of dungeon
      - Enemy at 0 HP → removed, loot roll triggered
   d. Check for victory (all enemies defeated) or defeat (all party KO'd)
   e. Next combatant in initiative order.

3. BETWEEN ROOMS:
   - MP regeneration: +5% max MP per adventurer
   - Consumable triggers (if conditions met)
   - Buff durations carry between rooms (unless specified otherwise)
   - Sentinel's Fortify persists into next room (unique)

4. RESOLUTION:
   - Victory: Loot rolls, XP distribution, advance to next room
   - Defeat: Expedition ends. Partial rewards based on rooms cleared.
```

### 9.4 Tactical Directives

Before launching an expedition, the player sets **Tactical Directives** — high-level AI orders that modify adventurer behavior. Directives are unlocked via Seedwarden Level progression.

| Directive | Effect on AI | Unlock |
|-----------|-------------|--------|
| **Focus Fire** | All DPS prioritize the same target (highest threat first). Reduces spread. | Start |
| **Spread Damage** | DPS spread attacks across all enemies. Good for AoE-weak parties. | Start |
| **Conserve Mana** | Casters use basic attacks when MP < 50%. Preserves MP for later rooms. | Start |
| **All-Out Attack** | Ignore defensive skills; maximize DPS output. Risky but fast. | Seedwarden Lvl 3 |
| **Defensive Stance** | Tanks always use defensive skills; DPS focuses squishy enemies first. | Seedwarden Lvl 3 |
| **Priority: Elites** | Target Elite enemies first (they deal most damage). | Seedwarden Lvl 5 |
| **Priority: Healers** | Target enemy support/healer units first. | Seedwarden Lvl 5 |
| **Retreat Threshold** | Set HP% at which party retreats. Default: 0% (never). | Seedwarden Lvl 7 |
| **Element Match** | Mages always use the element targeting enemy weakness, even if lower raw damage. | Seedwarden Lvl 10 |

**Multiple directives can be active simultaneously** (e.g., Focus Fire + Priority: Elites + Element Match). Conflicting directives (Focus Fire vs. Spread Damage) cannot be selected together.

### 9.5 Damage Formula

```gdscript
# Core damage calculation (deterministic)
func calculate_damage(attacker, defender, skill, rng: RandomNumberGenerator) -> int:
    var raw = attacker.ATK * skill.multiplier * get_elemental_modifier(attacker.element, defender.element)
    var variance = rng.randf_range(0.9, 1.1)  # Seeded RNG — deterministic
    raw *= variance

    var armor_mult = get_armor_multiplier(defender.armor_type)
    var damage = max(1, int(raw - (defender.DEF * armor_mult)))

    # Critical hit check
    var crit_chance = 0.05 + (attacker.PER / 200.0) + get_morale_crit_bonus(attacker.morale)
    if rng.randf() < crit_chance:
        damage = int(damage * get_crit_multiplier(attacker, skill))

    return damage
```

**Elemental Modifier:**

| Matchup | Modifier |
|---------|----------|
| Advantage (e.g., Terra → Frost) | ×1.5 |
| Neutral | ×1.0 |
| Disadvantage (e.g., Frost → Terra) | ×0.6 |

**Armor Multiplier (applied to DEF):**

| Armor Type | DEF Effectiveness |
|------------|------------------|
| Heavy (Warrior, Sentinel) | ×1.0 (full DEF value) |
| Medium (Ranger, Alchemist) | ×0.7 |
| Light (Mage, Rogue) | ×0.4 |

**Critical Hit:**

| Aspect | Value |
|--------|-------|
| Base crit chance | 5% |
| PER bonus | +PER/200 (e.g., PER 20 = +10%) |
| Morale bonus | +0 at Morale 50, +5% at Morale 100, −5% at Morale 0 |
| Crit multiplier | ×1.5 (base), ×2.0 (Rogue's Backstab from Stealth) |

### 9.6 Action Selection AI

Adventurers select actions based on a priority system influenced by class role and active Tactical Directives:

| Class | Priority 1 (Urgent) | Priority 2 (Tactical) | Priority 3 (Default) |
|-------|---------------------|----------------------|---------------------|
| **Warrior** | Taunt (if any ally < 50% HP) | Cleave (if 3+ enemies alive) | Basic Attack (highest ATK enemy) |
| **Ranger** | Snipe (lowest HP enemy, for finishing) | Rain of Arrows (if 3+ enemies) | Basic Attack (highest damage target) |
| **Mage** | Elemental Blast (enemy weak to Mage's element) | Arcane Storm (if 3+ enemies) | Enchant Weapon (buff highest-ATK ally) |
| **Rogue** | Backstab (if in Stealth → guaranteed crit) | Shadow Step (if not in Stealth) | Basic Attack (lowest HP enemy) |
| **Alchemist** | Healing Draught (any ally < 40% HP) | Elixir Toss (buff party if no one hurt) | Acid Splash (highest DEF enemy) |
| **Sentinel** | Barrier (if party avg HP < 60%) | Purify (if any ally has debuff) | Holy Ward (if magic-heavy enemies) |

**Directive overrides:** Active directives modify these priorities. E.g., "All-Out Attack" suppresses Warrior's Taunt and Sentinel's Barrier priorities in favor of offensive skills.

### 9.7 Status Effects

| Status | Effect | Duration | Common Sources |
|--------|--------|----------|----------------|
| **Poisoned** | −5% max HP per turn | 3 turns | Spore traps, Fungal Crawlers, Vine Lashers |
| **Burning** | −8% max HP per turn, −10% DEF | 2 turns | Flame enemies, lava traps, Embervault hazards |
| **Frozen** | SPD halved, 25% chance to skip turn entirely | 2 turns | Frost enemies, ice traps, Frostmere hazards |
| **Silenced** | Cannot use MP-costing skills (basic attack only) | 2 turns | Arcane enemies, mana drain traps |
| **Blinded** | −50% accuracy (50% chance attacks miss) | 2 turns | Shadow enemies, darkness zones, Voidmaw hazards |
| **Rooted** | Cannot change target, −50% evasion | 2 turns | Vine Lashers, Vine snare traps |
| **Slowed** | SPD −50%, cannot act first in round | 3 turns | Frost Weavers, Freezing mist traps |
| **Shielded** | Absorb X damage before HP loss | Until depleted | Sentinel's Barrier, Mage's Mana Shield |
| **Empowered** | +25% ATK | 3 turns | Alchemist's Elixir, Berserker Rage |
| **Weakened** | −25% ATK | 3 turns | Acid Splash, certain boss abilities |
| **Fortified** | +15% DEF, persists between rooms | 1 room | Sentinel's Fortify (unique) |

**Debuff stacking:** Multiple different debuffs can affect the same target simultaneously. The same debuff does **not** stack — reapplication refreshes duration instead.

**Debuff removal:** Only Sentinel's Purify and Antidote consumable can remove debuffs. Alchemist's Healing Draught does not remove debuffs (it only heals HP).

### 9.8 Boss Combat

Boss encounters follow the same system with added **Phase Mechanics**:

| Phase Trigger | Effect |
|---------------|--------|
| Boss reaches 75% HP | Phase 2: Boss gains a shield (absorbs damage = 10% max HP). May gain new ability. |
| Boss reaches 50% HP | Phase 3: Boss gains shield. May summon minions, change element, or modify battlefield. |
| Boss reaches 25% HP | Final Phase: Boss enrages (+30% ATK, +20% SPD). Last stand. |

**Boss AI is hand-authored** (not generated from generic tables). Each boss has unique ability patterns that test specific party compositions. See §5.9 for per-boss breakdowns.

### 9.9 Time-to-Kill Targets

| Enemy Type | Target TTK | Assumes |
|------------|-----------|---------|
| Trash mob (single, same Vigor) | 1–2 rounds | Appropriately leveled party |
| Standard combat room (2–3 enemies) | 3–5 rounds | Balanced party composition |
| Elite enemy | 4–6 rounds | Focused fire from full party |
| Boss (full fight) | 15–25 rounds (3–5 phases) | Prepared party with healer |
| Full dungeon (Vigor 50, 14 rooms) | ~8 minutes at 1× speed | Watching playback, not skipping |

### 9.10 Combat Feedback & Juiciness

Even though combat is auto-resolved, watching it should feel **satisfying**:

| Feedback Element | Implementation |
|-----------------|----------------|
| **Floating damage numbers** | Pop up on hit, sized by damage magnitude, colored by element. Critical hits are larger + star icon. |
| **Skill name flash** | Brief text overlay when a named skill activates ("BACKSTAB!", "ARCANE STORM!") |
| **HP bar animation** | Smooth decrease with a delayed "ghost" bar showing recent damage |
| **Screen shake** | Subtle shake on critical hits and boss phase transitions. Toggleable (accessibility). |
| **Element trail** | Colored particle trail matching attack element |
| **KO animation** | Defeated enemy fades with element-colored dissolution. Adventurer KO shows dramatic stumble + recall flash. |
| **Boss phase transition** | Full-screen energy surge + camera zoom + new phase ability reveal |
| **Victory fanfare** | 5-second triumphant brass + string swell. Loot cascade. |
| **Speed controls** | 1×, 2×, 4×, Skip (instant). Speed setting persists across rooms. |

---

## 10. Items & Equipment

### 10.1 Equipment Slots

Each adventurer has three equipment slots:

| Slot | Types | Class Restrictions | Stat Focus |
|------|-------|--------------------|-----------|
| **Weapon** | Swords, Axes, Hammers, Bows, Crossbows, Staves, Wands, Tomes, Daggers, Short Swords, Flasks, Slings, Shields, Maces | Class-specific (see §6.3) | ATK, elemental damage, crit chance, skill modifiers |
| **Armor** | Heavy Armor, Medium Armor, Light Robes | Class-restricted by weight | DEF, HP, resistances, condition recovery |
| **Accessory** | Rings, Amulets, Trinkets | Universal — any class | Mixed stats, unique passives, utility effects |

### 10.2 Rarity Tiers

| Tier | Color | Stat Range | Bonus Properties | Drop Rate (Bloom, Vigor 50) | Crafting Tier Required |
|------|-------|-----------|------------------|-----------------------------|----------------------|
| **Common** | ⬜ White | 80–100% of base | None | 55% | Workshop Tier 1 |
| **Uncommon** | 🟩 Green | 100–115% of base | 1 minor bonus | 25% | Workshop Tier 1 |
| **Rare** | 🟦 Blue | 115–135% of base | 1 major OR 2 minor bonuses | 12% | Workshop Tier 2 |
| **Epic** | 🟪 Purple | 135–160% of base | 1 major + 1 minor, may have unique passive | 6% | Workshop Tier 3 |
| **Legendary** | 🟨 Gold | 160–200% of base | 2 major + unique passive. Named item with lore text. | 2% | Workshop Tier 4 |

### 10.3 Equipment Properties

**Base Stats:** Determined by item type and item level. A Level 20 Iron Sword has a fixed base ATK value; rarity multiplies this.

**Item Level:** Maps to Vigor tiers:

| Vigor Tier | Equipment Level Range | Tier Name |
|------------|----------------------|-----------|
| 1–25 | 1–10 | Novice |
| 26–50 | 11–20 | Journeyman |
| 51–75 | 21–35 | Expert |
| 76–100 | 36–50 | Master |

**Bonus Stats:** Randomly rolled from a pool appropriate to the slot (deterministic from dungeon seed):

| Bonus Type | Examples | Found On |
|------------|----------|----------|
| **Minor** | +5 HP, +2 SPD, +3% ATK, +2 PER | Uncommon+ |
| **Major** | +5% ATK and DEF, +15% elemental damage, +10% crit chance, status resist | Rare+ |
| **Unique Passive** | Named effects with significant gameplay impact (see below) | Epic/Legendary only |

### 10.4 Unique Passives (Epic/Legendary)

| Passive Name | Slot | Effect | Source |
|-------------|------|--------|--------|
| *Thorn Mail* | Armor | Reflect 10% of physical damage taken back to attacker | Crafted (Epic) |
| *Vampiric Edge* | Weapon | Heal wielder for 5% of damage dealt | Boss drop |
| *Cloak of Shadows* | Accessory | +20% evasion in Shadow-element dungeons | Voidmaw boss |
| *Resonance Crystal* | Accessory | +10% damage for each party member sharing your element | Shimmerdeep boss |
| *Evergreen Ward* | Armor | Regenerate 2% max HP per round | Verdant Hollow boss |
| *Pyroclasm* | Weapon | Critical hits apply Burning status to all enemies | Embervault boss |
| *Frostbite Grip* | Weapon | Attacks have 15% chance to apply Frozen | Frostmere boss |
| *Void Siphon* | Accessory | Gain +5% ATK for each debuff on any enemy (stacking) | Voidmaw boss |
| *Seedwarden's Resolve* | Accessory | Party-wide: +5% all stats if all members are Healthy | Legendary craft |
| *Harvest Moon* | Accessory | +25% Gold and Material drops from treasure rooms | Legendary craft |

### 10.5 Set Bonuses (Post-MVP)

Equipment sets provide bonuses when multiple pieces from the same set are equipped on one adventurer:

| Set Name | Element | 2-Piece Bonus | 3-Piece Bonus | Source |
|----------|---------|---------------|---------------|--------|
| **Verdant Guardian** | Terra | +10% HP | +20% DEF in Verdant Hollow | Verdant Hollow drops |
| **Emberforged** | Flame | +10% ATK | Critical hits deal Flame AoE splash | Embervault drops |
| **Frostmere's Embrace** | Frost | +15% Frost damage | Frozen enemies take +25% damage from all sources | Frostmere drops |
| **Shimmerweave** | Arcane | +15% MP | Skills cost −20% MP | Shimmerdeep drops |
| **Voidtouched** | Shadow | +10% Evasion | Stealth lasts +1 turn, Backstab damage +15% | Voidmaw drops |

### 10.6 Crafting System

The Workshop allows players to craft, upgrade, reforge, salvage, and enchant equipment.

| Action | Inputs | Output | Workshop Tier Required | Notes |
|--------|--------|--------|----------------------|-------|
| **Craft** | Materials + Elemental Essence + Gold | New equipment (rarity depends on material quality + recipe) | Tier 1 | Recipes unlocked via drops and progression |
| **Upgrade** | Equipment + Materials + Gold | +1 Item Level (up to +5 above base) | Tier 2 | Each upgrade costs progressively more. Max +5. |
| **Reforge** | Equipment + Reforge Stone + Gold | Reroll all bonus stats (keep base stats and rarity) | Tier 3 | Reforge Stones from boss drops |
| **Salvage** | Equipment | Materials + partial Gold return (~40% of craft cost) | Tier 1 | Returns biome-appropriate materials |
| **Enchant** | Equipment + Enchanting Shard + Gold | Add or replace elemental affinity on equipment | Tier 4 | Enchanting Shards from Shimmerdeep |

**Crafting Recipe Structure:**
```
[Base Material × quantity] + [Elemental Essence × quantity] + [Gold cost] → [Equipment Item]

Example:
  Iron Ore ×10 + Terra Essence ×3 + 500 Gold → Verdant Longsword (Rare, Terra, Weapon)
  Monster Hide ×8 + Flame Essence ×5 + 800 Gold → Emberscale Mail (Rare, Flame, Armor)
  Arcane Dust ×6 + Frost Essence ×2 + 300 Gold → Frostspark Ring (Uncommon, Frost, Accessory)
```

**Recipe Discovery:**
- Common/Uncommon recipes: available from Workshop Tier 1
- Rare recipes: unlocked via Workshop Tier 2 + specific material discovery
- Epic recipes: unlocked via Workshop Tier 3 + Boss Trophy
- Legendary recipes: unlocked via Workshop Tier 4 + specific Boss Trophy + rare drop

### 10.7 MVP Item Budget

| Category | Count | Details |
|----------|-------|---------|
| Weapons | 6 types × 1 per rarity tier (C/U/R) = 18 | One weapon per class, 3 rarity tiers |
| Armor | 3 types (H/M/L) × 3 rarities = 9 | Heavy, Medium, Light |
| Accessories | 3 types × 3 rarities = 9 | Ring, Amulet, Trinket |
| Consumables | 6 types | Health/Mana Potions, Antidote, Smoke Bomb, Elemental Scroll, Scout's Lantern |
| Materials | 8 types | Iron Ore, Monster Hide, Arcane Dust, Terra Essence, + 4 reserved biome essences |
| **Total unique items** | **~40** | Sufficient for 10–15 hours of meaningful loot progression |

---

## 11. UI/UX Design

### 11.1 Design Philosophy

The UI must serve two modes: **active management** (making decisions, planning expeditions, crafting) and **passive monitoring** (watching expeditions, checking timers, collecting resources). The interface should feel like a **gardener's workshop** — warm, organic, and tactile — not a spreadsheet.

**UX Priorities:**
1. **One-tap access** to the most common actions (collect resources, launch expedition, plant seed)
2. **Glanceable status** — timers, party health, seed stages visible at a glance on the main screen
3. **No hidden mechanics** — every system's rules accessible via tooltips, tutorials, or Codex
4. **Keyboard-friendly** on PC. Touch-friendly on mobile (post-MVP). No hover-dependent mechanics.
5. **Consistent navigation** — back button always in the same position, screen transitions always animated

### 11.2 Screen Map

```
                    ┌──────────────┐
                    │  TITLE SCREEN │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │   THE GARDEN  │ ◄─── Primary Hub (always return here)
                    │  (Main Screen)│
                    └──┬──┬──┬──┬──┘
                       │  │  │  │
          ┌────────────┘  │  │  └────────────┐
          │               │  │               │
  ┌───────▼──────┐ ┌─────▼──▼─────┐ ┌───────▼──────┐
  │  SEED VAULT  │ │  EXPEDITION  │ │   TAVERN     │
  │  (Collection)│ │    BOARD     │ │ (Adventurers)│
  └──────────────┘ │  (Planning)  │ └──────────────┘
                   └──────┬───────┘
                          │
                   ┌──────▼───────┐
                   │  EXPEDITION  │
                   │    LOG       │ ◄─── Auto-Battle Playback
                   └──────┬───────┘
                          │
                   ┌──────▼───────┐
                   │   RESULTS    │
                   │   SCREEN     │
                   └──────────────┘

  Also accessible from Garden nav bar:
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │   WORKSHOP   │  │    SHOP      │  │   SETTINGS   │  │    CODEX     │
  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

### 11.3 Key Screen Descriptions

#### The Garden (Main Hub)
- **Layout:** Visual representation of garden plots (1–5), each showing a planted seed with growth stage animation.
- **Info Displayed:** Seed species icon, elemental affinity color + shape icon, growth stage label, timer countdown, mutation indicators.
- **Actions:** Tap a plot to plant/inspect/harvest. Bottom nav bar for all other screens.
- **Ambient:** Gentle particle effects (floating spores, light rays, elemental wisps) matching planted seed elements.
- **Resource Bar:** Always-visible bar at top showing Gold, Verdant Essence, Materials, Guild Favor.

#### Seed Vault
- **Layout:** Scrollable grid of owned seeds. Filterable by species, element, rarity, Vigor.
- **Seed Card:** Species, rarity border color, Vigor number, element icon + shape, mutation slots (filled/empty).
- **Actions:** Select → view details, plant, share code, or delete.
- **Sharing:** "Share Code" button copies 8-char code to clipboard.

#### Expedition Board
- **Layout:** Left panel: available Bloom dungeons. Right panel: party assembly (4 slots).
- **Dungeon Preview:** Biome art, skull rating, room count, element affinity, mutation badges, expected loot tier.
- **Party Assembly:** Drag adventurers from roster into slots. Per-adventurer equipment/skill/consumable editing. Condition indicators on each portrait.
- **Directive Panel:** Collapsible panel for setting tactical directives (checkbox toggles).
- **Launch:** Prominent "Embark" button with confirmation dialog showing party power vs. difficulty comparison.

#### Expedition Log (Battle Playback)
- **Layout:** Room-by-room progression as a graph visualization. Current room highlighted. Party moves node-to-node.
- **Battle View:** Adventurer sprites vs. enemy sprites. Floating damage numbers. Skill name flashes. HP/MP bars.
- **Speed Controls:** 1×, 2×, 4×, Skip. Persistent across rooms.
- **Room Summary Cards:** After each room: loot gained, HP remaining, notable events ("Kira found a secret room!").

#### Tavern
- **Roster View:** Grid of adventurers. Portrait, class icon, level, condition indicator, affinity shape.
- **Adventurer Detail:** Full stat sheet, equipment (clickable to swap), skills (drag to reorder), XP bar, condition timer.
- **Recruitment Tab:** Available recruits with stat preview. Cost and "Recruit" button.
- **Training Hall:** Assign idle adventurers. Shows XP/hour rate and accumulated offline XP.

#### Workshop
- **Tabs:** Craft, Upgrade, Reforge, Salvage, Enchant (tabs unlock with Workshop tier).
- **Crafting:** Recipe list (discovered only). Material requirements with owned/needed counts. One-tap craft.
- **Upgrade:** Select equipment → preview current/next level stats → confirm with cost.
- **Salvage:** Drag equipment to salvage bin. Preview return materials.

#### Shop
- **Tabs:** Seeds, Amendments, Materials, Consumables, Specials.
- **Item Display:** Icon, name, stats/description, price (with currency icon), buy button. Sold-out items grayed.
- **Refresh Timer:** Time until next daily/weekly refresh.

### 11.4 HUD (Expedition Playback)

| Element | Position | Content |
|---------|----------|---------|
| **Party HP/MP Bars** | Top-left, vertical stack | Per-adventurer HP/MP with portrait, condition icon, buff/debuff icons |
| **Enemy HP Bars** | Top-right, vertical stack | Per-enemy HP with type icon, element shape, elite badge if applicable |
| **Room Progress** | Bottom-center | Miniature graph showing rooms cleared/remaining, current position |
| **Speed Control** | Bottom-right | 1×, 2×, 4×, Skip buttons |
| **Loot Feed** | Right edge, scrolling | Items acquired, XP gained, currency earned (auto-clears after 5s) |
| **Status Effects** | Below HP bars | Active buff/debuff icons with remaining turn count |
| **Turn Order** | Top-center | Initiative order showing next 4 actors |

### 11.5 Input Mapping (PC)

| Action | Mouse | Keyboard |
|--------|-------|----------|
| Navigate menus | Click | Arrow keys + Enter |
| Plant/Inspect seed | Click plot | Number keys (1–5) for plots |
| Open screens | Click nav button | Hotkeys: G=Garden, T=Tavern, W=Workshop, S=Shop, V=Vault, X=Codex |
| Cycle screens | — | Tab / Shift+Tab |
| Speed control | Click button | 1/2/3/4 keys during expedition |
| Drag equipment/adventurer | Click-drag | Arrow keys to select, Enter to assign |
| Tooltip | Hover | Focus + Shift (hold) |
| Back/Close | Click back button | Escape |

### 11.6 Accessibility Features

| Feature | Description | Priority |
|---------|-------------|----------|
| **Colorblind Modes** | Deuteranopia, Protanopia, Tritanopia simulation filters. Elements use shape + color (never color alone). | P0 |
| **High Contrast Mode** | Increased UI contrast ratios. Outlines on interactive elements. Darkened backgrounds behind text. | P0 |
| **Text Scaling** | 3-step: Normal, Large, Extra Large. All layouts accommodate max text size. | P0 |
| **Full Keyboard Navigation** | Every screen navigable. Clear focus indicators. Tab order follows visual layout. | P0 |
| **Screen Reader Hints** | Accessible names/descriptions on all interactive elements. Focus order = logical reading order. | P1 |
| **Reduced Motion** | Disables particles, screen shake, animated transitions. Static indicators instead. | P1 |
| **Icon Labels** | Option to show text labels under all icons (items, skills, elements). | P1 |
| **Separate Volume Sliders** | Music, SFX, Ambient — independently adjustable 0–100%. | P0 |
| **Visual Audio Cues** | Critical audio events have corresponding visual indicators (text flash, icon pulse). | P0 |
| **Mono Audio** | Downmix stereo to mono for single-ear listening. | P1 |
| **Customizable Keybinds** | All keyboard shortcuts rebindable. | P1 |
| **Auto-Collect** | Option to automatically collect idle resources without navigating to Garden. | P1 |
| **One-Click Expedition** | "Quick Expedition" repeats last party composition + directives. | P1 |
| **Tutorial System** | Guided first-run tutorial. Non-intrusive, dismissible, replayable from Settings. | P0 |
| **Codex/Help** | In-game encyclopedia. Context-sensitive "?" buttons on every screen. | P0 |
| **Tooltips** | Hover/long-press on all interactive elements. Shows function and key stats. | P0 |

---

## 12. Narrative & World

### 12.1 World Concept

The game takes place in the **Rootreach** — a mystic underground realm where ancient seeds grow not flora, but living dungeons that pulse with elemental power. Millennia ago, a civilization called the **Seedwardens** tended these dungeon-gardens, harvesting their treasures to maintain balance between the five elemental forces. Then the Seedwardens vanished. The gardens went wild. Dungeons sprouted unchecked, feral and dangerous.

The player is the **last awakened Seedwarden**, called back by a fragment of ancient magic (the first seed). Their mission: rebuild the garden, tame the wild dungeons, recruit adventurers brave enough to delve into them, and uncover why the original Seedwardens disappeared.

### 12.2 The Narrative Hook (First 60 Seconds)

> The screen fades in on a ruined garden. Stone plots cracked and overgrown. A single seed pulses with green light in the center — the only living thing. Text appears: *"The garden remembers you."*
>
> The player taps the seed. It sprouts instantly — roots cracking through stone, a miniature dungeon unfurling like a time-lapse flower. An inscription appears on the entrance: *"The first door opens from within."*
>
> A lone adventurer appears at the garden's edge — a Warrior, battered and lost. She approaches the dungeon entrance. *"I've been searching for this place. We all have."*
>
> The player sends her in. She clears three rooms. Returns with a handful of gold, a worn sword, and a second seed — this one flickering with ember-orange light. The garden trembles. A second plot repairs itself.
>
> *"The garden is growing again. The Rootreach stirs."*

### 12.3 Lore Depth Layers

Lore is delivered through four layers of increasing discovery effort:

| Layer | Content | Delivery | Audience |
|-------|---------|----------|----------|
| **Surface** | Main narrative: rebuild the garden, recruit adventurers, grow stronger | Dungeon entrance inscriptions, adventurer dialogue barks, Welcome Back screen flavor text | Everyone — passive absorption |
| **Buried** | Faction histories, elemental origin stories, Seedwarden culture | Item descriptions, Codex entries (unlocked by finding items/discovering rooms), biome-specific lore stones | Engaged players — optional reading |
| **Hidden** | The truth about why the Seedwardens vanished, the Voidmaw's origin, the nature of the seeds | Secret room inscriptions, Legendary item lore text, specific mutation chain discoveries | Explorers and completionists |
| **Secret** | Community-discoverable ARG-style revelations: seed codes that spell messages, hidden room sequences that tell a story, metadata in generation algorithms | Pattern recognition across seed codes, community collaboration | Community — the deepest layer |

### 12.4 Factions & Elemental Cultures

Each biome is associated with a lost elemental culture, pieces of which the player uncovers through exploration:

| Faction | Element | Biome | Core Belief | Fate |
|---------|---------|-------|-------------|------|
| **The Green Covenant** | Terra | Verdant Hollow | "Growth is the purpose." Believed dungeons were living organisms to be nurtured. | Overrun by their own creations — the garden grew beyond their control. |
| **The Ember Forge** | Flame | Embervault | "All things are tempered by fire." Used dungeons as crucibles to forge weapons and warriors. | Consumed by the heat they worshipped — Embervault's Rising Heat is their legacy. |
| **The Still Mirror** | Frost | Frostmere | "In stillness, truth." Sought to freeze dungeons at peak perfection, preserving them forever. | Succeeded too well — Frostmere is perfectly preserved, including its dangers. |
| **The Prism Assembly** | Arcane | Shimmerdeep | "Reality is negotiable." Experimented with dungeon reality, warping space and time. | Experimented too far — Shimmerdeep's Arcane Instability is their failed experiment. |
| **The Hollow** | Shadow | Voidmaw | "What lies beyond the last door?" Delved too deep, seeking the source of all dungeon power. | Found it. What they found unmade them. The Voidmaw is what's left. |

### 12.5 Environmental Storytelling

Each biome tells its faction's story through:

- **Entrance inscriptions:** Every dungeon starts with a lore fragment on the Entrance room wall
- **Room details:** Combat rooms have background flavor text ("Scorch marks on the walls suggest this forge was abandoned mid-strike")
- **Boss dialogue:** Boss encounters have brief text barks during phase transitions ("The Treant groans — not in pain, but in recognition")
- **Treasure descriptions:** Rare+ items have flavor text connecting them to the faction ("This blade was quenched in the Forgelord's own heart")
- **Secret room revelations:** Secret rooms contain the deepest lore fragments, often contradicting surface-level narratives

### 12.6 The Central Mystery

**Surface narrative:** The Seedwardens vanished. The garden went wild. You're rebuilding it.

**Hidden truth (revealed through Voidmaw exploration):** The Seedwardens didn't vanish. They *became* the seeds. Each seed planted is a fragment of a Seedwarden's consciousness. Every dungeon is a Seedwarden's memory, dreaming of the world that was. The Voidmaw is where the last Seedwardens went looking for answers — and what answered.

**Design rationale:** This mystery provides emotional weight to the seed cultivation mechanic. Once the player learns the truth, planting a seed feels different — it's not just growing a dungeon, it's awakening a memory. This transforms the late-game experience without changing any mechanics.

### 12.7 Adventurer Characterization

Adventurers are not blank slates — they have procedurally generated personality traits that affect their dialogue barks:

| Trait | Dialogue Examples | Mechanical Effect |
|-------|-------------------|-------------------|
| **Bold** | "Into the breach!" / "Is that all?" | +5 base Morale |
| **Cautious** | "Let's be careful..." / "I don't like the look of this." | +10% trap detection |
| **Scholarly** | "Fascinating architecture." / "The inscription speaks of..." | +5% secret room discovery |
| **Greedy** | "I smell gold!" / "This had better be worth it." | +5% treasure room loot |
| **Loyal** | "I'll protect you." / "We stand together." | +5% party-wide Morale on victory |

Traits are assigned at recruitment (one trait per adventurer) and provide small mechanical bonuses alongside flavor. They make adventurers feel like *individuals* rather than interchangeable stat blocks.

---

## 13. Art Direction & Audio

### 13.1 Visual Identity

**Style:** Hand-painted 2D with subtle parallax depth. Think **Darkest Dungeon** crossed with **Stardew Valley** — detailed and atmospheric but warm and approachable. Not chibi. Not photorealistic. A "storybook illustration" quality where each frame could hang on a wall.

**Rendering:** Godot 4's 2D renderer with CanvasLayer-based compositing. No 3D assets in MVP. All sprites are pre-rendered 2D.

**Resolution:** 1920×1080 native. Art assets authored at 2× (3840×2160) for future 4K support. Pixel-scaled down for lower resolutions with nearest-neighbor for crisp edges.

### 13.2 Color Philosophy

The game uses a **biome-driven palette system** with a warm, earthy hub palette:

| Context | Dominant Colors (Hex Examples) | Mood |
|---------|-------------------------------|------|
| **UI & Hub (Garden, Tavern, Workshop)** | Warm earth: `#5C4033` (dark brown), `#F5E6CC` (cream), `#4A7C59` (forest green), `#D4A853` (amber gold) | Safety, comfort, home |
| **Verdant Hollow** | `#2D6A4F` (deep green), `#52B788` (moss), `#D4A853` (gold), `#3A86C8` (bioluminescent blue) | Lush, mysterious, alive |
| **Embervault** | `#9B2226` (crimson), `#BB3E03` (ember), `#333333` (charcoal), `#E9A319` (molten gold) | Industrial, foreboding, hot |
| **Frostmere** | `#A8DADC` (ice blue), `#F1FAEE` (white), `#C0C0C0` (silver), `#B8A9C9` (pale lavender) | Crystalline, isolated, serene |
| **Shimmerdeep** | `#7B2CBF` (violet), `#4CC9F0` (cyan), `#F72585` (iridescent pink), `#E0AAFF` (light arcane) | Ethereal, disorienting, wondrous |
| **Voidmaw** | `#2B0040` (deep purple), `#0D1B2A` (near-black), `#90BE6D` (sickly green), `#4A8FE7` (spectral teal) | Dread, unease, the abyss |

**Rule:** Each biome must be instantly identifiable from a single screenshot by its palette alone.

### 13.3 Character Art

- **Adventurers:** Consistent style, distinct silhouettes per class (recognizable at 32px). 4 skin tones, 4 hair colors per class. ~12 animation frames per adventurer: Idle (2), Attack (3), Skill Cast (3), Hit Reaction (2), KO (2).
- **Enemies:** Biome-themed creature designs. Silhouette-first — identifiable as small sprites. ~8 frames per enemy. Bosses are 2× adventurer size with 16 frames.
- **Seedwarden (Player):** Not visible during gameplay. Portrait on Welcome Back and Settings. 6 customizable portraits.

### 13.4 Environment Art

- **Garden Hub:** Isometric-adjacent overhead view. Dirt plots, stone paths, hanging lanterns, tool shed. Seeds animate: Spores pulse, Sprouts sway, Buds glow, Blooms shimmer with element particles.
- **Dungeon Rooms:** Since dungeons are abstract graphs (not tilemaps), room art is **per-room-type background illustrations**: 5 biomes × 4 room variations = 20 backgrounds. Side-view 2D. Foreground elements provide parallax.
- **Graph Visualization:** The dungeon graph itself uses clean, stylized node icons per room type connected by organic vine/root-styled edges. Element-colored. Clear, readable, beautiful.

### 13.5 UI Art

- **Style:** Organic frames — wood, stone, vine motifs. Buttons look carved or polished. No sharp modern rectangles.
- **Icons:** 32×32 and 64×64. Clean linework, flat color fills. Element shapes always visible.
- **Fonts:** Two typefaces: a serif display font for headers (fantasy-themed) and clean sans-serif for body text (readability).
- **Rarity Borders:** Cards have rarity-colored border glow (White → Green → Blue → Purple → Gold). Animated shimmer for Epic/Legendary.

### 13.6 Animation Budget (MVP)

| Asset Category | Count | Priority |
|---------------|-------|----------|
| Adventurer sprites (6 classes × 12 frames) | 72 frames | P0 |
| Enemy sprites (Verdant Hollow: 5 types × 8 frames) | 40 frames | P0 |
| Boss sprite (Elder Treant × 16 frames) | 16 frames | P0 |
| Seed sprites (Terra × 4 stages × 2 frames) | 8 frames | P0 |
| Dungeon backgrounds (Verdant Hollow × 4 variations) | 4 backgrounds | P0 |
| Garden hub art | 1 scene + 5 plot states | P0 |
| UI elements (buttons, panels, frames, icons) | ~150 assets | P0 |
| Item icons | ~40 icons (MVP item budget) | P1 |
| Portraits (adventurer × 6 classes + 6 player) | ~12 portraits | P1 |
| Particle effects (element-coded combat + growth) | ~10 systems | P1 |
| Graph node icons (room types) | ~8 icons | P0 |

### 13.7 Musical Identity

**Style:** Acoustic-organic instrumentation blended with subtle atmospheric synthesis. Primary instruments: plucked strings (lute, guitar), woodwinds (flute, ocarina), light percussion (hand drums, chimes), pad synthesizers for atmospheric depth.

**Tone:** Hopeful and meditative during hub/garden. Tense and rhythmic during expeditions. Triumphant on victory. Somber but not oppressive on defeat.

### 13.8 Music Architecture

| Context | Tempo | Key Instruments | Loop Length |
|---------|-------|-----------------|-------------|
| **Title Screen** | 60 BPM (slow) | Solo flute, reverb pad, wind FX | 2 min |
| **The Garden (Hub)** | 80 BPM (relaxed) | Fingerpicked acoustic guitar, chimes, birdsong | 3 min |
| **Tavern / Workshop / Shop** | 100 BPM (medium) | Lute, hand drum, fiddle, crowd murmur | 2.5 min |
| **Expedition — Exploration** | Variable (biome) | Biome-specific (see below) | 3 min |
| **Expedition — Combat** | 130 BPM (fast) | Drums, staccato strings, brass stabs | 1.5 min |
| **Boss Combat** | 140 BPM (intense) | Full ensemble, choir hits, heavy percussion | 2 min |
| **Victory Fanfare** | — | Brass + strings swell | 5 sec |
| **Defeat Sting** | — | Solo cello, descending | 5 sec |
| **Welcome Back** | Slow | Music box + pad | 15 sec |

### 13.9 Biome Music Variants

| Biome | Signature Sound | Mood |
|-------|----------------|------|
| **Verdant Hollow** | Wooden flute, rainforest ambience, trickling water | Lush, mysterious, alive |
| **Embervault** | Anvil strikes, bass drone, crackling fire, war horns | Industrial, foreboding, hot |
| **Frostmere** | Glass chimes, celesta, whistling wind, ice cracking | Crystalline, isolated, serene |
| **Shimmerdeep** | Processed synth arpeggios, reversed reverb, theremin | Ethereal, disorienting, wondrous |
| **Voidmaw** | Sub-bass rumble, whispered voices, dissonant strings | Dread, unease, the abyss |

### 13.10 Sound Effects

**UI SFX:**
- Button press: soft wooden "click"
- Menu open/close: page turn / wood creak
- Currency received: coin jingle (scaled by amount)
- Seed planted: soil pat + sparkle
- Growth stage transition: organic bloom + elemental chime
- Mutation roll: dice-like tumble + reveal sting

**Combat SFX:**
- Melee hit: impact scaled by weapon type (slash, blunt, pierce)
- Ranged hit: whoosh + impact
- Magic cast: element-coded swirl (fire crackle, ice crystallize, arcane hum, shadow whisper, earth rumble)
- Critical hit: exaggerated version + screen flash
- KO: thud + fade
- Boss phase transition: roar/energy surge + music transition

**Ambient:**
- Garden: birdsong, gentle wind, water drip, insect buzz
- Dungeon: biome-specific (dripping water, distant rumble, ice creaking, magical hum, whispers)

### 13.11 MVP Audio Budget

| Category | Count | Priority |
|----------|-------|----------|
| Music tracks (hub + Verdant exploration + combat + boss) | 4 tracks | P0 |
| Victory/Defeat stings | 2 tracks | P0 |
| UI SFX | ~20 sounds | P0 |
| Combat SFX | ~30 sounds | P0 |
| Garden ambient loop | 1 loop | P0 |
| Verdant Hollow ambient loop | 1 loop | P1 |
| Growth/mutation/crafting SFX | ~10 sounds | P1 |

---

## 14. Technical Architecture

### 14.1 Engine & Language

| Aspect | Specification | Rationale |
|--------|--------------|-----------|
| **Engine** | Godot 4.x (latest stable at dev start) | Open source, CLI-automatable, 2D-native, GDScript agent-friendly |
| **Language** | GDScript exclusively (MVP) | Fastest iteration, Godot-native, no interop overhead |
| **Target FPS** | 60 FPS | Auto-battle playback and UI must be smooth |
| **Min Spec** | GTX 1060 / Ryzen 5 3600 equivalent | Mid-range PC. Game is 2D — should run on potato hardware. |
| **Resolution** | 1920×1080 native, 1280×720 minimum | 16:9 aspect ratio |

### 14.2 Project Structure

```
dungeon-seed/
├── project.godot
├── src/
│   ├── autoloads/            # Singleton managers
│   │   ├── game_state.gd     # Master game state (serializable)
│   │   ├── save_manager.gd   # Save/load, backup, versioning
│   │   ├── audio_manager.gd  # Music, SFX, ambient management
│   │   ├── rng_manager.gd    # Deterministic RNG factory
│   │   └── event_bus.gd      # Signal-based decoupled communication
│   ├── models/               # Data classes (Resources)
│   │   ├── seed_data.gd      # Seed properties, mutations, affinity
│   │   ├── adventurer_data.gd # Adventurer stats, skills, condition
│   │   ├── dungeon_data.gd   # Generated dungeon graph
│   │   ├── equipment_data.gd # Item properties, bonuses, passives
│   │   ├── room_data.gd      # Room content: encounters, loot, traps
│   │   └── combat_result.gd  # Per-room combat outcome
│   ├── systems/              # Core game logic (no UI dependency)
│   │   ├── dungeon_generator.gd    # Seed → DungeonData (deterministic)
│   │   ├── combat_resolver.gd      # Party + Room → CombatResult (deterministic)
│   │   ├── expedition_runner.gd    # Orchestrates room-by-room traversal
│   │   ├── loot_roller.gd          # Deterministic loot generation
│   │   ├── growth_manager.gd       # Seed growth timers, mutations
│   │   ├── economy_manager.gd      # Currency transactions, validation
│   │   ├── crafting_manager.gd     # Recipe resolution, material tracking
│   │   └── idle_calculator.gd      # Offline reward computation
│   ├── ui/                   # Scene-based UI
│   │   ├── garden/           # Main hub scene
│   │   ├── expedition_board/ # Party assembly scene
│   │   ├── expedition_log/   # Battle playback scene
│   │   ├── tavern/           # Adventurer management
│   │   ├── workshop/         # Crafting/upgrade
│   │   ├── shop/             # Store
│   │   ├── seed_vault/       # Collection
│   │   ├── settings/         # Options, accessibility
│   │   └── shared/           # Reusable UI components (buttons, panels, cards)
│   └── data/                 # Static game data
│       ├── enemies/          # .tres per enemy type
│       ├── items/            # .tres per item definition
│       ├── skills/           # .tres per skill
│       ├── recipes/          # .tres per crafting recipe
│       ├── biomes/           # .tres per biome template
│       └── compositions/     # .tres per enemy composition table
├── assets/
│   ├── sprites/
│   ├── backgrounds/
│   ├── ui/
│   ├── audio/
│   │   ├── music/
│   │   ├── sfx/
│   │   └── ambient/
│   └── particles/
├── tests/                    # GdUnit4 test suites
│   ├── test_dungeon_generator.gd
│   ├── test_combat_resolver.gd
│   ├── test_loot_roller.gd
│   ├── test_growth_manager.gd
│   └── test_economy_manager.gd
└── addons/
    └── gdunit4/              # Testing framework
```

### 14.3 Autoload Singletons

| Autoload | Responsibility | Persists Across Scenes? |
|----------|---------------|------------------------|
| **GameState** | Master state object. Holds all player data: seeds, adventurers, equipment, currencies, guild levels, settings. Serializable to JSON. | Yes |
| **SaveManager** | Save/load to disk. Versioned saves with backward compatibility. Auto-save on major actions. Backup previous save before writing. | Yes |
| **AudioManager** | Music playback with crossfade transitions. SFX with pooling. Ambient layering. Volume control per category. | Yes |
| **RngManager** | Factory for creating seeded `RandomNumberGenerator` instances. Ensures no code uses global `randi()`. | Yes |
| **EventBus** | Signal-based pub/sub for decoupled communication. Screens subscribe to events without direct references. | Yes |

### 14.4 Abstract Dungeon Graph — NOT Tilemap

**This is a critical architectural decision.** Dungeons are represented as a graph data structure, not a spatial tilemap.

```gdscript
# Core dungeon data model
class_name DungeonData extends Resource

@export var generation_seed: int         # uint64 master seed
@export var species: StringName          # Biome identifier
@export var affinity: StringName         # Element
@export var vigor: int                   # 1-100
@export var mutations: Array[MutationData]

@export var rooms: Array[RoomData]       # All rooms (nodes)
@export var connections: Array[Vector2i] # Edges: [room_a_index, room_b_index]
@export var critical_path: Array[int]    # Ordered room indices for main path
@export var entrance_index: int          # Starting room
@export var boss_index: int              # Final room

# RoomData contains: type (combat/treasure/rest/boss/secret),
# encounter (enemies), loot_table, traps, lore_text, discovery_threshold
```

**Why not tilemap?**
1. No spatial rendering needed — the dungeon is a graph shown as a node diagram
2. Auto-battle doesn't need pathfinding or collision
3. Graph topology is trivially serializable for save/share
4. Deterministic generation is simpler on graphs than spatial layouts
5. Mobile-friendly — no tile rendering performance concerns
6. Cleaner separation of game logic from presentation

### 14.5 Deterministic RNG Implementation

```gdscript
# All procedural generation MUST use this pattern:
class_name RngManager extends Node

func create_dungeon_rng(generation_seed: int) -> RandomNumberGenerator:
    var rng = RandomNumberGenerator.new()
    rng.seed = generation_seed
    return rng

func create_combat_rng(generation_seed: int, room_index: int) -> RandomNumberGenerator:
    var rng = RandomNumberGenerator.new()
    rng.seed = generation_seed ^ (room_index * 7919)  # Prime-based room isolation
    return rng

func create_loot_rng(generation_seed: int, room_index: int) -> RandomNumberGenerator:
    var rng = RandomNumberGenerator.new()
    rng.seed = generation_seed ^ (room_index * 6151) ^ 0xDEADBEEF
    return rng

# RULE: Global randi() and randf() are PROHIBITED.
# All randomness flows through explicitly-seeded RNG instances.
# This guarantees: same inputs → same outputs, always.
```

### 14.6 Save System

| Aspect | Specification |
|--------|--------------|
| **Format** | JSON (human-readable, debuggable, diff-able) |
| **Location** | `user://saves/` directory (Godot's platform-appropriate user data path) |
| **Slots** | 1 save slot (MVP). Auto-save on every major action (seed plant, expedition complete, craft, purchase). |
| **Backup** | On every save, copy previous save to `save_backup.json`. On corruption detection, offer restore from backup. |
| **Versioning** | Save file includes a `version` field. SaveManager implements migration functions for each version increment. Backward compatible — old saves always loadable. |
| **Clock Handling** | UTC timestamps for all time-based calculations. On save: record `DateTime.now_utc()`. On load: compare saved timestamp to current UTC. Delta = offline time for idle calculations. |
| **Anti-Exploit** | Drift detection: if elapsed time > wall time since last save by more than 10%, cap idle rewards at expected wall time. Prevents clock manipulation. |
| **Save Size** | Estimated ~50–200KB for a mature save (hundreds of items, dozens of seeds, 12 adventurers). JSON is verbose but compressible. |

### 14.7 Scene Management

```
Scene Transitions:
  SceneTree.change_scene_to_packed() for major screen transitions.
  Autoload singletons persist across transitions.
  Tween-based fade transitions (0.3s crossfade) for polish.

Scene Hierarchy:
  Root
  ├── GameState (autoload)
  ├── SaveManager (autoload)
  ├── AudioManager (autoload)
  ├── RngManager (autoload)
  ├── EventBus (autoload)
  └── CurrentScene (changes)
      ├── GardenScene
      │   ├── GardenPlots (1-5)
      │   ├── ResourceBar
      │   └── NavBar
      ├── ExpeditionBoardScene
      │   ├── DungeonPreview
      │   ├── PartyAssembly
      │   └── DirectivePanel
      ├── ExpeditionLogScene
      │   ├── DungeonGraphView
      │   ├── BattlePlayback
      │   └── SpeedControls
      └── ... (Tavern, Workshop, Shop, Vault, Settings)
```

### 14.8 Data Architecture

| Data Type | Storage | Format | Example |
|-----------|---------|--------|---------|
| **Static data** (enemies, items, skills, recipes, biomes) | `.tres` Resource files in `src/data/` | Godot Resource | `enemies/fungal_crawler.tres` |
| **Dynamic player data** (inventory, adventurers, seeds, currencies) | GameState autoload → serialized to JSON on save | JSON | `save_slot_1.json` |
| **Configuration** (settings, keybinds, accessibility) | Separate JSON in `user://settings.json` | JSON | Volume levels, colorblind mode, text size |

**Static data is defined in `.tres` files** for Godot-native loading, editor-friendly authoring, and type safety. Dynamic data uses JSON for human-readability and version migration.

### 14.9 Testing Strategy

| Test Type | Tool | Coverage Target |
|-----------|------|----------------|
| **Unit tests** | GdUnit4 | All systems/ classes: dungeon generator, combat resolver, loot roller, economy |
| **Determinism tests** | GdUnit4 | Verify same seed → same dungeon, same combat, same loot (run 100× per test) |
| **Economy simulation** | Custom script | Simulate 100 Cultivation Cycles per progression tier, verify currency balance |
| **Save compatibility** | GdUnit4 | Load saves from every previous version, verify migration succeeds |
| **Integration** | Manual + GdUnit4 | Full Cultivation Cycle end-to-end |

### 14.10 Build Targets

| Platform | Export | Notes |
|----------|--------|-------|
| **Windows** | MVP | Godot native export. x86_64. |
| **macOS** | Post-MVP | Godot native. Notarization required. |
| **Linux** | Post-MVP | Godot native. AppImage. |
| **Web (HTML5)** | Consideration | Demo/trial build. Godot HTML5 export. |
| **Mobile (iOS/Android)** | Post-MVP Phase 2 | Touch UI rework required. |

---

## 15. MVP Scope & Success Metrics

### 15.1 MVP Goal

Ship a **playable, complete Cultivation Cycle** with one biome (Verdant Hollow) and enough depth to sustain **10–15 hours** of engaged play. The MVP proves the core loop is fun. Content breadth (additional biomes, advanced features) follows in post-MVP updates.

### 15.2 MVP Feature Matrix

| System | MVP Scope | Post-MVP Additions |
|--------|-----------|-------------------|
| **Seed System** | Terra element only. All 4 growth stages. 4 mutation types (Bountiful, Perilous, Labyrinthine, Fertile). Common–Rare rarity. Seed sharing (import/export codes). | All 5 elements, all 8 mutation types, Epic/Legendary rarity, Seed Breeding, community seed board. |
| **Dungeon Generation** | Verdant Hollow biome only. 5–16 rooms. Abstract graph generation. Room types: Entrance, Combat, Treasure, Rest, Boss. | All 5 biomes, Secret/Puzzle rooms, boss variants, environmental hazards, graph rewiring (Shimmerdeep). |
| **Adventurer System** | All 6 classes. Levels 1–25. 3 skill slots. Condition system (Healthy/Fatigued/Injured/Exhausted). Roster limit 6. Personality traits. | Levels 26–50, 4–5 skill slots, Roster expansion (8/10/12), advanced skills, skill synergy system. |
| **Combat** | Auto-battle with AI priority system. 3 Tactical Directives (Focus Fire, Spread Damage, Conserve Mana). Elemental advantage (Terra only = simplified). Status effects: Poisoned, Rooted, Shielded, Empowered, Weakened. | Full directive set (9 directives), all elemental interactions, all status effects, boss phases, combat replay. |
| **Items & Equipment** | Common–Rare tiers. Weapon + Armor slots. ~40 unique items. Crafting: Craft + Salvage only. | Epic/Legendary tiers, Accessory slot, Upgrade/Reforge/Enchant, unique passives, set bonuses. |
| **Economy** | Gold + Verdant Essence + Materials (3 subtypes) + Guild Favor. Basic shop. | Full material diversity (12 types), Seed Tokens, full shop rotation, Specials tab. |
| **Guild Hall** | Garden (Tier 1–2), Tavern (Tier 1–2), Workshop (Tier 1), Vault (Tier 1), Shop (Tier 1). | Full 5-tier progression for all facilities, Prestige system. |
| **Idle Mechanics** | Seed growth offline. Condition recovery offline. Resource trickle. Welcome Back screen. | Training Hall, advanced idle upgrades, extended caps. |
| **Progression** | Seedwarden Levels 1–5. Adventurer levels 1–25. Equipment levels 1–10. | Full Seedwarden track (25 levels), Level 50 cap, Prestige mode. |
| **UI** | Garden, Expedition Board, Expedition Log, Tavern (Recruit + Roster), Workshop (Craft/Salvage), Shop, Settings. | Seed Vault (advanced filters), Codex, Achievement screen, Mutation Mastery, Training Hall UI. |
| **Art** | Verdant Hollow biome art. 6 adventurer classes. 5 enemy types + 1 boss (Elder Treant). Seed sprites (Terra × 4 stages). Core UI. | All biome art, full enemy roster, portraits, particle polish, additional bosses. |
| **Audio** | Garden music, Verdant Hollow exploration track, combat track, victory/defeat stings, core UI SFX (~20), combat SFX (~30). | All biome tracks, boss music, full ambient loops, complete SFX library. |
| **Accessibility** | Element shapes (never color alone). Text scaling (3 sizes). Full keyboard navigation. Separate volume sliders. Tutorial. Tooltips. | Full colorblind mode filters, High contrast, Screen reader hints, Reduced motion, Codex, Relaxed Mode. |
| **Platform** | PC (Windows). Windowed + Fullscreen. | macOS, Linux, Mobile (iOS/Android), Web demo. |

### 15.3 MVP Milestone Plan

| Milestone | Content | Target Duration | Exit Criteria |
|-----------|---------|----------------|---------------|
| **M0: Prototype** | Seed growth timer → generates room list → party auto-clears rooms → loot display. No art. Placeholder UI. | 2 weeks | Core loop feels fun with boxes and numbers. "Just one more cycle" feeling validated. |
| **M1: Core Loop** | Full Cultivation Cycle with programmer art. Abstract graph dungeon gen. Auto-battle with damage formula. Equipment equipping. Deterministic RNG verified. | 4 weeks | Same seed → same dungeon → same combat outcome. All 5 phases of Cultivation Cycle playable. |
| **M2: Content Pass** | Verdant Hollow art/audio. 6 classes with skills (3 per class). 5 enemy types + Elder Treant boss. Crafting (Craft + Salvage). Shop. 40 items. | 6 weeks | One full biome playable with real art. 2–3 hours of non-repetitive content. |
| **M3: Polish & Idle** | Idle systems (offline growth, recovery, trickle). Welcome Back flow. Condition system. Save/load with versioning. Tutorial. Settings screen. Guild Favor. | 4 weeks | Player can close game, return 6 hours later, and see meaningful offline progress. Save file works correctly across sessions. |
| **M4: Accessibility & QA** | Element shapes on all UI. Text scaling. Keyboard navigation. Bug fixing. Balance pass (economy simulation, difficulty curve). | 3 weeks | All P0 accessibility features pass. Economy simulates 100 cycles without breaking. No game-breaking bugs. |
| **M5: Release Prep** | Store page. Trailer capture. Build optimization. Final testing. Seed sharing flow tested. | 2 weeks | Build runs at 60fps on min-spec. Store page live. Trailer captured. |
| **Total Estimated MVP** | | **~21 weeks (~5 months)** | |

### 15.4 Kill Criteria

The project should be **re-evaluated** (not necessarily killed, but honestly assessed) if:

1. **M0 prototype fails to be fun** — if the core loop (plant → wait → explore → loot → replant) doesn't create a "just one more cycle" feeling with zero polish, the concept needs fundamental redesign. Art cannot save a boring loop.

2. **Art production exceeds 50% of total development time** — indicates scope is too large for solo development. Resolution: reduce to 3 enemy types for MVP, commission art for bosses, or adopt a simpler art style.

3. **Playtesters consistently skip battles AND ignore loot** — both the auto-battle system and the loot loop are failing simultaneously. These are the moment-to-moment engagement hooks. If both fail, the game is a timer app.

4. **Deterministic RNG breaks** — if seed-sharing doesn't produce identical dungeons across platforms/sessions, the core USP is invalid. This must be verified at M1 before investing in content.

### 15.5 Success Metrics (KPIs)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Core loop engagement** | 70%+ of playtesters complete 3+ Cultivation Cycles in first session | Playtest observation + telemetry |
| **Session length** | Average 20–30 min per active session | In-game timer |
| **Return rate** | 50%+ of players return within 24 hours of first session | Session timestamp delta |
| **Idle engagement** | 60%+ of returning players interact with Welcome Back content before navigating away | UI event tracking |
| **Seed sharing** | 20%+ of players share at least one seed code | Share button click tracking |
| **Battle engagement** | 40%+ of expeditions are watched (not skipped) | Speed control + skip tracking |
| **Equipment engagement** | Average player changes equipment at least once per 2 expeditions | Equipment swap event tracking |
| **Economy health** | No player accumulates >10,000 Gold with nothing to spend it on before hour 15 | Economy simulation + telemetry |
| **Accessibility** | All P0 features pass manual audit | QA checklist |
| **Performance** | 60fps sustained on min-spec hardware | Profiling tool |

### 15.6 Post-MVP Content Roadmap

| Phase | Content | Estimated Duration |
|-------|---------|-------------------|
| **Phase 1: Biome Expansion** | Embervault (Flame) + Frostmere (Frost) biomes. Epic rarity. Workshop Tiers 2–3. Seedwarden Levels 6–10. 2 new bosses. | 6–8 weeks |
| **Phase 2: Depth** | Shimmerdeep (Arcane) + Voidmaw (Shadow) biomes. Legendary rarity. Accessory slot. Full Workshop. Set bonuses. All directives. | 8–10 weeks |
| **Phase 3: Endgame** | Prestige system. Seed Breeding. Endless Dungeon mode. Achievement system. Codex completion. Challenge seeds. | 6–8 weeks |
| **Phase 4: Platform** | macOS + Linux builds. Mobile touch UI adaptation. Web demo build. Cross-save consideration. | 4–6 weeks |
| **Phase 5: Live** | Seasonal seeds. Community seed board. Daily challenge seeds. Leaderboards. | Ongoing |

### 15.7 Open Questions

| # | Question | Decision Point | Default Assumption |
|---|----------|---------------|-------------------|
| Q1 | Should seed growth timers be adjustable per-player (casual vs. hardcore)? | M1 playtesting | No — single balanced timeline, acceleratable with resources. |
| Q2 | Should adventurers have permadeath as an optional hardcore mode? | Post-MVP | No — injuries only. Permadeath is a post-MVP toggle if demanded. |
| Q3 | What is the final monetization model? | Pre-release business planning | Premium purchase ($9.99–$14.99). No microtransactions in MVP. |
| Q4 | Should the Seed Vault have a capacity limit? | M2 economy testing | Soft limit (50 seeds MVP, expandable). If hoarding is a problem, add pressure. |
| Q5 | Should dungeon expeditions have an energy/stamina system? | M0 | **No.** Pillar 4 (Respect the Player's Time) prohibits artificial gating. |
| Q6 | How does difficulty scale for plateaued players? | M3 balance pass | Crafting + leveling provide catch-up. No dead ends. |
| Q7 | Should there be daily challenge seeds? | Post-MVP | Not in MVP. Post-MVP: daily seed (same for all players, leaderboard). |
| Q8 | Should the dungeon graph support non-linear traversal (player choice of path)? | M1 | MVP: AI follows critical path + explores branches based on PER/directive. Post-MVP: player chooses path at branch points. |

---

## Appendix A: Glossary

| Term | Definition |
|------|-----------|
| **Seedwarden** | The player character — a cultivator of magical dungeon seeds. |
| **Cultivation Cycle** | One complete loop of Plant → Grow → Explore → Harvest → Reinvest. |
| **Vigor** | A seed's quality/difficulty rating (1–100). Higher Vigor = harder dungeon, better rewards. |
| **Generation Seed** | The deterministic RNG seed (uint64) used for all procedural generation within a dungeon. |
| **Bloom** | The final growth stage of a seed; the stage at which the dungeon is ready to explore. |
| **Tactical Directive** | A pre-set strategic order given to the adventurer party before an expedition. |
| **Soil Amendment** | A consumable item applied to a growing seed to modify its properties. |
| **Mutation** | A modification acquired during seed growth that alters the resulting dungeon. |
| **Verdant Essence** | Green currency earned from expeditions, used for seed growth and amendments. |
| **Guild Favor** | Long-term engagement currency earned from expeditions and milestones, used for guild upgrades. |
| **Condition** | An adventurer's physical state (Healthy/Fatigued/Injured/Exhausted). |
| **Abstract Graph** | Dungeon representation as nodes (rooms) and edges (connections), NOT a spatial tilemap. |
| **Critical Path** | The shortest route from Entrance to Boss room; the mandatory traversal path. |
| **Seed Code** | 8-character alphanumeric string (e.g., KXVN-84PQ) representing a seed's generation_seed, shareable between players. |

## Appendix B: Elemental Advantage Quick Reference

```
Attacker → Defender    Modifier    Shape Icons
──────────────────────────────────────────────
Terra    → Frost       ×1.5        ● → ◆
Frost    → Flame       ×1.5        ◆ → ▲
Flame    → Shadow      ×1.5        ▲ → ⬡
Shadow   → Arcane      ×1.5        ⬡ → ★
Arcane   → Terra       ×1.5        ★ → ●

Terra    → Arcane      ×0.6        ● → ★
Arcane   → Shadow      ×0.6        ★ → ⬡
Shadow   → Flame       ×0.6        ⬡ → ▲
Flame    → Frost       ×0.6        ▲ → ◆
Frost    → Terra       ×0.6        ◆ → ●

All other pairings     ×1.0
```

## Appendix C: Downstream Agent Dependency Map

This GDD feeds the following downstream agents in the game development pipeline:

| Agent | Sections Consumed | Primary Purpose |
|-------|-------------------|-----------------|
| **Narrative Designer** | §12, §5.8, §4.4 | Lore bible, faction histories, environmental storytelling scripts |
| **Character Designer** | §6, §5.8, §12.7 | Adventurer stat sheets, enemy profiles, boss design docs |
| **World Cartographer** | §5.2–5.8, §12.4 | Biome design, dungeon graph topology, room type distribution |
| **Game Economist** | §8, §10.6, §7.2 | Economy balance model, drop tables, currency simulation |
| **Art Director** | §13.1–13.6 | Style guide, color palettes, asset specifications |
| **Audio Director** | §13.7–13.11 | Music direction, SFX taxonomy, adaptive audio rules |
| **Game Architecture Planner** | §14 | Technical architecture, scene tree, data model |
| **Game Code Executor** | §14, §9.5, §5.3 | GDScript implementation, combat resolver, dungeon generator |
| **The Decomposer** | All sections | Task decomposition into ~200+ implementable tickets |

---

*End of Document — Dungeon Seed GDD v3.0*

*This document is the authoritative source for all game design decisions. All downstream agents, tickets, and implementation plans derive from this GDD. If a downstream artifact conflicts with this GDD, this GDD wins.*
