# Game Design Document: Dungeon Seed

> **Status**: Complete Draft
> **Version**: 2.0
> **Date**: 2026-07-29
> **Author**: Game Vision Architect Agent
> **Epic**: Dungeon Seed
> **Lineage**: Supersedes GDD v0.1 (2026-04-12). Incorporates APPROVED-EPIC-BRIEF.md, DUNGEON-SEED-GDD.md, and LORE-BIBLE.md.

---

## Table of Contents

| # | Section | Page |
|---|---------|------|
| 1 | [Executive Summary](#1-executive-summary) | Core identity |
| 2 | [Player Fantasy](#2-player-fantasy) | Emotional promise |
| 3 | [Core Loop](#3-core-loop) | Gameplay heartbeat |
| 4 | [Moment-to-Moment Gameplay](#4-moment-to-moment-gameplay) | Second-by-second feel |
| 5 | [Session Structure](#5-session-structure) | Play rhythm |
| 6 | [Progression Systems](#6-progression-systems) | Growth architecture |
| 7 | [Combat Design — Expedition Resolution](#7-combat-design--expedition-resolution-system) | Auto-battle engine |
| 8 | [Seed System Deep Dive](#8-seed-system-deep-dive) | The soul of the game |
| 9 | [World Design](#9-world-design) | Biomes and geography |
| 10 | [Narrative Framework](#10-narrative-framework) | Story and lore |
| 11 | [Character Archetypes](#11-character-archetypes) | Adventurers and NPCs |
| 12 | [Economy Design](#12-economy-design) | Currencies and balance |
| 13 | [Multiplayer Design](#13-multiplayer-design) | Social features |
| 14 | [Art Direction](#14-art-direction) | Visual identity |
| 15 | [Audio Direction](#15-audio-direction) | Sonic identity |
| 16 | [UI/UX Design](#16-uiux-design) | Interface and flow |
| 17 | [Monetization Design](#17-monetization-design) | Business model |
| 18 | [Endgame Design](#18-endgame-design) | Max-level content |
| 19 | [Retention & Live Ops](#19-retention--live-ops) | Engagement loops |
| 20 | [Onboarding & Tutorial](#20-onboarding--tutorial) | First-time experience |
| 21 | [Accessibility](#21-accessibility) | Inclusive design |
| 22 | [Technical Direction](#22-technical-direction) | Engine and architecture |
| 23 | [Platform Strategy](#23-platform-strategy) | Distribution |
| 24 | [Competitive Analysis](#24-competitive-analysis) | Market positioning |
| 25 | [Risk Analysis & Open Questions](#25-risk-analysis--open-questions) | Threats and decisions |
| A-G | [Appendices](#appendices) | Reference data |

---

## 1. Executive Summary

### Elevator Pitch

**Dungeon Seed** is an RPG/idle hybrid where players plant magical seeds that sprout into procedurally generated dungeons. As a Seedwarden, you cultivate dungeon ecosystems — choosing elemental affinities, applying mutations, and timing growth stages — then dispatch parties of adventurers to clear rooms and harvest loot. The loot feeds back into better seeds, stronger heroes, and deeper dungeons in a compounding loop that rewards both active strategy and idle patience.

*"It's Dungeon Keeper meets idle farming meets roguelike loot — you GROW the dungeon, then send heroes to harvest it."*

### The One-Sentence Recommendation

> "You literally plant dungeons like a garden, mutate them into harder versions for better loot, and send little adventurer squads through them — I've had it running in the background for three weeks and I can't stop."

### Genre Tags

`RPG` · `Idle/Incremental` · `Procedural Generation` · `Management Sim` · `Dungeon Crawler (Indirect)` · `Loot Game` · `Strategy`

### Platform Targets

| Platform | Priority | Timeline | Distribution |
|----------|----------|----------|--------------|
| PC (Windows) | **Primary** | Launch | Steam, itch.io |
| PC (Linux/macOS) | Primary | Launch | Steam |
| Web | Secondary | Launch (demo) | itch.io, Newgrounds |
| Android | Tertiary | Phase 2 (+3-6mo) | Google Play |
| iOS | Tertiary | Phase 2 (+3-6mo) | App Store |
| Nintendo Switch | Stretch | Phase 3 (+12mo) | eShop |

### Target Audience

| Segment | Description | Size | Priority |
|---------|-------------|------|----------|
| **Idle Strategists** | 20-35, enjoy incremental games with depth (Melvor Idle, NGU Idle, Realm Grinder) | Large | Primary |
| **RPG Completionists** | 18-40, love collecting, filling codexes, optimizing builds (Pokémon, Diablo, Path of Exile) | Large | Primary |
| **Cozy Managers** | 25-45, enjoy tending systems (Stardew Valley, Littlewood, Garden Story) | Medium | Secondary |
| **Auto-Battler Fans** | 18-35, enjoy party composition and watching outcomes (TFT, Underlords) | Medium | Secondary |
| **Roguelike Enthusiasts** | 18-35, enjoy procedural variety and risk/reward (Slay the Spire, Loop Hero) | Medium | Tertiary |

### Business Model

**Ethical Free-to-Play** with optional cosmetic purchases, convenience items, a seasonal battle pass, and premium expansion content. Core gameplay is never gated behind payment. See [Section 17](#17-monetization-design) for full guardrails.

### Comparable Titles Matrix

| Title | What We Borrow | What We Improve |
|-------|---------------|-----------------|
| **Dungeon Keeper** | "You ARE the dungeon" fantasy | We ADD the farming/growth layer |
| **Melvor Idle** | Deep idle RPG progression | We add procedural world variety |
| **Loop Hero** | Indirect hero control + world building | We add persistent garden management |
| **Slay the Spire** | Run-based strategy and variety | We add idle pacing and long-term persistence |
| **Stardew Valley** | Satisfying growth/harvest loop | We swap crops for dungeons |
| **Idle Champions** | Party dispatch and auto-combat | We add meaningful player agency in dungeon design |

### Scope Summary

| Metric | Target |
|--------|--------|
| Dev team size | Solo indie (1 developer + AI agents) |
| Engine | Godot 4.x (GDScript) |
| Target dev timeline | 6-9 months to MVP |
| Content at launch | 5 biomes, 6 classes, 50+ seed types, 100+ room templates |
| Session length | 2 min (idle check) to 2 hr (deep session) |
| Target playtime | 40-60hr main progression, 200+ hr completionist |

---

## 2. Player Fantasy

Every system in Dungeon Seed serves one or more of three interlocking emotional promises. If a feature doesn't serve a fantasy, it gets cut.

### 🏗️ The Architect Fantasy

**"I design dungeons by choosing what to grow."**

The player isn't exploring dungeons — they're CREATING them. Every seed planted is a creative act. The elemental affinity chosen, the mutations applied, the growth timing — all of these are design decisions that shape a unique dungeon. The architect fantasy is the power of creation: watching a seed you planted and mutated erupt into a sprawling, dangerous, loot-rich labyrinth that bears YOUR signature.

**Systems that serve the Architect Fantasy:**
- Seed selection with elemental affinities
- Mutation system (reshape dungeon properties)
- Deterministic generation (your choices = predictable-but-surprising outcomes)
- Seed Codex (catalog of every dungeon type you've grown)
- Dungeon preview maps (see YOUR creation before dispatching)

### 🌱 The Caretaker Fantasy

**"I tend a living garden of magical ecosystems."**

The Seed Grove is a garden. Seeds are alive — they pulse, they glow, they respond to your attention. The caretaker fantasy is the quiet satisfaction of tending something, watching it grow, and reaping the harvest. It's the reason Stardew Valley players lose hours watering crops. In Dungeon Seed, you're watering dungeons. The idle component amplifies this: you plant before bed, and wake up to blooming dungeons ready for harvest.

**Systems that serve the Caretaker Fantasy:**
- Growth stage animations (Spore → Sprout → Bud → Bloom)
- Idle growth that accumulates while away
- Garden layout and expansion
- "Your seeds have grown!" return notifications
- Reagent application rituals (feeding your seeds)
- Seasonal garden aesthetics

### ♟️ The Strategist Fantasy

**"I optimize the perfect dungeon-to-adventurer pipeline."**

The strategist fantasy is the joy of optimization. Which adventurer party composition counters this biome's enemies? Should I mutate this seed for more treasure rooms or more combat XP? Can I stagger my growth timers so I always have a dungeon ready to run? The strategist sees the entire pipeline — seed → growth → mutation → dispatch → loot → reinvest — and finds the optimal path through it.

**Systems that serve the Strategist Fantasy:**
- Party composition with class synergies and elemental matchups
- Mutation trade-offs (risk vs. reward)
- Staggered growth scheduling (multiple seeds at different stages)
- Expedition planning (matching party to dungeon)
- Resource optimization (where to spend limited currencies)
- Prestige system (when to reset for long-term gains)

### Fantasy Consistency Matrix

Every major system must serve at least one fantasy. If it serves zero, it's cut.

| System | Architect | Caretaker | Strategist |
|--------|:---------:|:---------:|:----------:|
| Seed Planting | ✅ | ✅ | ✅ |
| Growth Stages | ✅ | ✅ | — |
| Mutation | ✅ | — | ✅ |
| Expedition Dispatch | — | — | ✅ |
| Combat Resolution | — | — | ✅ |
| Loot Collection | — | ✅ | ✅ |
| Crafting | ✅ | — | ✅ |
| Grove Expansion | ✅ | ✅ | — |
| Adventurer Training | — | ✅ | ✅ |
| Seed Codex | ✅ | ✅ | — |
| Prestige/Rebirth | — | — | ✅ |
| Idle Accumulation | — | ✅ | ✅ |

---

## 3. Core Loop

### 3.1 The Four Nested Loops

#### 🔄 MICRO LOOP (30 seconds)
The smallest unit of gameplay. The player performs ONE meaningful action.

```
┌─────────────────────────────────────────────────────┐
│                   MICRO LOOP (30s)                   │
│                                                     │
│  ┌──────────┐    ┌───────────┐    ┌──────────────┐  │
│  │  CHECK   │───→│   ACT     │───→│   COLLECT    │  │
│  │  status  │    │  (plant/  │    │  (loot/XP/   │  │
│  │  of seed │    │  mutate/  │    │  resources)  │  │
│  │  or hero │    │  dispatch)│    │              │  │
│  └──────────┘    └───────────┘    └──────────────┘  │
│       ↑                                    │        │
│       └────────────────────────────────────┘        │
└─────────────────────────────────────────────────────┘
```

**Example micro-actions:**
- Glance at Seed Grove → tap a Bloomed seed → dispatch adventurers → watch first room clear
- Open Mutarium → apply Emberheart Reagent to a Bud-stage seed → see dungeon map shift
- Check returned expedition → collect loot chest → auto-equip upgrade on Warrior

#### 🔄 MESO LOOP (5 minutes)
A complete growth-and-harvest cycle for one seed.

```
┌──────────────────────────────────────────────────────────────────┐
│                      MESO LOOP (5 min)                           │
│                                                                  │
│  ┌────────┐   ┌────────┐   ┌─────────┐   ┌──────────┐          │
│  │ PLANT  │──→│ GROW   │──→│ PREPARE │──→│ DISPATCH │          │
│  │ seed   │   │ (wait/ │   │ party   │   │ into     │          │
│  │        │   │ boost) │   │ + gear  │   │ dungeon  │          │
│  └────────┘   └────────┘   └─────────┘   └──────────┘          │
│                                               │                  │
│                                               ▼                  │
│  ┌────────────┐   ┌──────────┐   ┌────────────────┐            │
│  │ REINVEST   │←──│ HARVEST  │←──│ WATCH ROOMS    │            │
│  │ loot into  │   │ loot +   │   │ clear one by   │            │
│  │ next seed  │   │ XP + $   │   │ one (or skip)  │            │
│  └────────────┘   └──────────┘   └────────────────┘            │
│       │                                                          │
│       └──→ [NEXT SEED] ──→ repeat                               │
└──────────────────────────────────────────────────────────────────┘
```

#### 🔄 MACRO LOOP (30 minutes)
A strategic session spanning multiple seeds and system interactions.

```
┌────────────────────────────────────────────────────────────────────┐
│                      MACRO LOOP (30 min)                           │
│                                                                    │
│  ┌──────────────┐                                                  │
│  │ SET GOALS    │  "I want to unlock Frostmere biome today"       │
│  └──────┬───────┘                                                  │
│         ▼                                                          │
│  ┌──────────────┐                                                  │
│  │ PLANT 3-5    │  Stagger Common + Rare seeds for coverage       │
│  │ SEEDS        │                                                  │
│  └──────┬───────┘                                                  │
│         ▼                                                          │
│  ┌──────────────┐                                                  │
│  │ MUTATE       │  Apply Frostbite Reagent to unlock ice rooms    │
│  │ STRATEGICALLY│                                                  │
│  └──────┬───────┘                                                  │
│         ▼                                                          │
│  ┌──────────────┐                                                  │
│  │ RUN MULTIPLE │  Dispatch Party A into Seed #1 (Bloomed)        │
│  │ EXPEDITIONS  │  Dispatch Party B into Seed #3 (Bloomed)        │
│  └──────┬───────┘                                                  │
│         ▼                                                          │
│  ┌──────────────┐                                                  │
│  │ HARVEST &    │  Collect loot → Craft gear → Level heroes       │
│  │ UPGRADE      │                                                  │
│  └──────┬───────┘                                                  │
│         ▼                                                          │
│  ┌──────────────┐                                                  │
│  │ ADVANCE      │  Unlock new biome / Complete quest / Prestige   │
│  │ PROGRESSION  │                                                  │
│  └──────────────┘                                                  │
└────────────────────────────────────────────────────────────────────┘
```

#### 🔄 META LOOP (session / daily)
The rhythm that brings players back every day.

```
┌──────────────────────────────────────────────────────────────┐
│                     META LOOP (daily)                         │
│                                                              │
│  ┌───────────┐   ┌──────────────┐   ┌───────────────┐       │
│  │ RETURN    │──→│ HARVEST IDLE │──→│ PLAN TODAY'S  │       │
│  │ to grove  │   │ gains (seeds │   │ seeds &       │       │
│  │           │   │ grew while   │   │ expeditions   │       │
│  │           │   │ you slept!)  │   │               │       │
│  └───────────┘   └──────────────┘   └───────┬───────┘       │
│                                             ▼               │
│  ┌────────────────┐   ┌──────────────┐   ┌──────────┐      │
│  │ SET OVERNIGHT  │←──│ DO DAILY     │←──│ RUN      │      │
│  │ SEEDS (long    │   │ quest &      │   │ active   │      │
│  │ growth timers) │   │ weekly goals │   │ sessions │      │
│  └────────────────┘   └──────────────┘   └──────────┘      │
│                                                              │
│  Tomorrow: wake up to Bloomed dungeons → repeat              │
└──────────────────────────────────────────────────────────────┘
```

### 3.2 The Core Flow (One Line)

```
PLANT → GROW → MUTATE → BLOOM → DISPATCH → CLEAR → HARVEST → REINVEST → PLANT...
```

Every action feeds the next. Every reward enables a better version of the previous step. The flywheel never stops.

---

## 4. Moment-to-Moment Gameplay

*This section should make you FEEL the game. If you can't picture your hands doing this, the design has failed.*

### A Typical 10-Minute Session

You open Dungeon Seed. The Seed Grove fills the screen — a lush, living garden rendered in soft painterly strokes. Five planting plots are arranged in a gentle arc around a central stone pedestal. Three plots hold seeds at various stages: one pulses with a soft amber glow (a Terra seed at Bud stage), another crackles with tiny frost crystals along its stem (a Frost seed at Sprout), and the third — a Shadow seed — has fully BLOOMED, its dark petals unfurled to reveal a shimmering portal of purple light.

**"Your Shadow Seed has reached full Bloom!"** A gentle toast notification appears at the top of the screen, accompanied by a soft crystalline chime.

You tap the Bloomed Shadow seed. The dungeon preview panel slides in from the right — a top-down map of interconnected rooms rendered as glowing nodes. This seed generated a 12-room dungeon: 5 Combat rooms, 2 Treasure rooms, 2 Trap rooms, 1 Puzzle room, 1 Rest room, and 1 Boss Anchor at the far end. The rooms are connected by branching paths — you can see two routes to the boss, one shorter but trap-heavy, one longer but with more treasure.

You applied an **Etheric Labyrinth** mutation during the Bud stage, which added an extra Puzzle room and increased rare resource drop rates by 15%. The mutation's icon pulses in the seed's info panel — a swirling glyph of purple and teal. Good choice for Shadow biome farming.

Time to dispatch. You switch to the **Adventurer Hall** with a tab press. Your roster shows 8 adventurers: two parties of four. Party Alpha — Warrior (Lv. 14), Mage (Lv. 12), Rogue (Lv. 13), Sentinel (Lv. 11) — is rested and equipped. You check the dungeon's elemental tag: **Shadow**. Shadow is weak to **Arcane**. Your Mage has an Arcane staff equipped. Good synergy. But Shadow is strong against **Terra**. No Terra adventurers in this party — no penalty either.

You drag Party Alpha onto the dungeon's entry node. A confirmation panel shows estimated outcomes:

```
┌─────────────────────────────────────────────┐
│  EXPEDITION PREVIEW                         │
│  Dungeon: Shadow Bloom (Tier 3, 12 rooms)   │
│  Party: Alpha (Avg Lv. 12.5)                │
│  Est. Clear Rate: 87%                        │
│  Est. Duration: 4m 30s (active) / 45m (idle) │
│  Elemental Bonus: +20% (Arcane Mage)         │
│  Loot Forecast: ■■■■□ (Good)                │
│  Risk: ■■□□□ (Moderate)                      │
│                                              │
│  [ DISPATCH ]        [ CANCEL ]              │
└─────────────────────────────────────────────┘
```

You hit **DISPATCH**. The adventurer portraits slide into the dungeon map with a satisfying *whoosh*. Room 1 lights up — a Combat room. The resolution plays out in a compressed 5-second animation: your Warrior charges forward (a little chibi slash animation), the Mage fires an Arcane bolt, numbers pop up (128 DMG! 94 DMG!), the shadow enemies dissolve into purple motes. A tiny loot chest appears. Room 1: CLEARED. The party advances to Room 2.

While your party auto-clears rooms (you can watch or let it idle), you switch back to the Seed Grove. The Terra seed at Bud stage is 80% to Bloom — 3 more minutes. You have an **Ironheart Reagent** in your inventory. You tap the Bud-stage seed and select "Apply Mutation." The reagent slots into one of two mutation slots on the seed. A brief animation plays: veins of metallic orange spread through the seed's surface. The dungeon preview updates in real-time — two Combat rooms shifted to "Reinforced Combat" (harder enemies, better armor drops). The risk went up, but so did the reward.

A chime plays — your Shadow expedition just cleared the Boss Anchor room! You tap the notification. The results screen shows:

```
┌───────────────────────────────────────────┐
│  EXPEDITION COMPLETE! ★★★                 │
│                                           │
│  Rooms Cleared: 12/12                     │
│  Party Health: 62% remaining              │
│  Time: 3m 48s                             │
│                                           │
│  LOOT EARNED:                             │
│  ● 340 Gold                               │
│  ● 85 Essence                             │
│  ● 12 Shadow Fragments                    │
│  ● 1x Nightshard Dagger (Rare) ✨         │
│  ● 1x Void Reagent (Uncommon)             │
│                                           │
│  XP EARNED:                               │
│  Warrior: +220 XP  Mage: +245 XP         │
│  Rogue: +210 XP    Sentinel: +198 XP     │
│                                           │
│  [ COLLECT ALL ]                          │
└───────────────────────────────────────────┘
```

You hit **COLLECT ALL**. Loot items cascade into your inventory with satisfying plink-plink-plink sounds, each one color-coded by rarity. The Nightshard Dagger glows purple — that's a Rare! You check it: +18 ATK, +5% crit rate, Shadow elemental. Perfect for your Rogue.

You equip it. Your Rogue's ATK jumps from 42 to 58. You plant a new Uncommon Flame seed in the now-empty plot, queue up Party Alpha for a rest cycle, and close the game. Your seeds will keep growing. When you come back in an hour, that Terra seed will be Bloomed and the Flame seed will be at Sprout.

**That was 10 minutes.** You planted a seed, mutated another, dispatched an expedition, collected loot, equipped an upgrade, and set up your next session. The garden keeps growing while you're gone.

---

## 5. Session Structure

### 5.1 Session Types

#### ⏱️ Quick Check (2-3 minutes)
**When**: Morning routine, work break, before bed
**What happens**:
1. Open grove → see which seeds bloomed overnight
2. Collect idle loot from completed expeditions
3. Replant seeds in empty plots
4. Dispatch fresh parties into ready dungeons
5. Close — seeds keep growing

**Natural stopping point**: All plots planted, all parties deployed, idle timers ticking.

#### 🎮 Active Session (15-30 minutes)
**When**: Lunch break, commute, evening wind-down
**What happens**:
1. Harvest all idle gains
2. Full expedition cycle: dispatch, watch clears, collect, re-dispatch
3. Apply mutations to Bud-stage seeds
4. Craft gear from collected fragments
5. Train adventurers / recruit new heroes
6. Advance quest objectives
7. Plant next-tier seeds with remaining resources

**Natural stopping point**: Resources spent, all expeditions in progress, quest milestone hit.

#### 🏔️ Deep Session (1-2 hours)
**When**: Weekend gaming, deep progression push
**What happens**:
1. Everything in Active Session, plus:
2. Mutation experimentation — try new reagent combinations
3. Push into a new biome (unlock Frostmere, Shimmerdeep, etc.)
4. Tackle Boss Anchor rooms with optimized parties
5. Work toward Prestige/Garden Cycle requirements
6. Fill out Seed Codex entries
7. Seasonal challenge or weekly community goal

**Natural stopping point**: New biome unlocked, Prestige threshold reached, Codex page completed.

### 5.2 "One More Seed" Hooks

These psychological hooks keep players extending sessions naturally:

| Hook | Trigger | Extension |
|------|---------|-----------|
| "Almost bloomed" | Seed at 90%+ Bloom progress | Wait 2 more min for it to finish |
| "Just one dispatch" | Party Alpha just returned | Send them right back, watch the run |
| "That rare drop though" | Nightshard Dagger just equipped | "Let me see what the NEXT dungeon drops" |
| "New mutation unlocked" | Reagent recipe discovered | "I have to try this immediately" |
| "Biome progress" | 85% to unlocking Embervault | "3 more runs and I'm there" |
| "Daily almost done" | 2/3 daily quests complete | "Let me finish that last one" |

### 5.3 Idle Accumulation Rules

| System | While Away | Rate vs. Active |
|--------|-----------|-----------------|
| Seed growth | Continues at normal rate | 100% (same speed) |
| Expedition auto-clear | Continues at idle rate | 10x slower than watched |
| Loot collection | Queued for pickup | 40% of active loot quality |
| Resource generation | Passive trickle from grove upgrades | ~20% of active farming |
| Adventurer rest | Full recovery over time | Same speed as active |

**Key Design Rule**: Idle play is NEVER punished. Active play is BONUS, not requirement. A player who checks in twice a day for 5 minutes should feel meaningful progression.

---

## 6. Progression Systems

### 6.1 Seedwarden Level

The player has a global **Seedwarden Level** that represents overall mastery. It gates content unlocks and acts as the backbone of progression.

#### Seedwarden Level Unlocks

| Level | Unlock | Hours (est.) |
|-------|--------|-------------|
| 1 | Tutorial complete, 2 grove plots, 1 adventurer | 0 |
| 2 | Mutation slot (1 per seed), Adventurer Hall | 0.25 |
| 3 | 3rd grove plot, Ranger class | 0.5 |
| 4 | Daily Quest Board | 0.75 |
| 5 | Crafting station (basic), Mage class | 1.0 |
| 7 | 4th grove plot, Rogue class | 1.5 |
| 8 | Mutation slot 2 (per seed) | 2.0 |
| 10 | Embervault biome unlocked, Alchemist class | 3.0 |
| 12 | 5th grove plot, Seed Codex | 4.5 |
| 15 | Frostmere biome unlocked, Sentinel class | 8.0 |
| 18 | Advanced Crafting station | 12.0 |
| 20 | Shimmerdeep biome unlocked, 6th grove plot | 18.0 |
| 22 | Mutation slot 3 (per seed) | 24.0 |
| 25 | Voidmaw biome unlocked, 7th grove plot | 35.0 |
| 28 | Seed Breeding Lab | 45.0 |
| 30 | Garden Cycle (Prestige) unlocked, 8th grove plot | 55.0 |

#### Seedwarden XP Sources

| Source | XP Amount | Frequency |
|--------|-----------|-----------|
| Complete an expedition | 50-200 (scales with tier) | Per run |
| Bloom a seed | 30-150 (scales with rarity) | Per bloom |
| Apply a mutation | 20-80 | Per mutation |
| Craft an item | 15-60 | Per craft |
| Complete a daily quest | 100 | Daily |
| Complete a weekly quest | 500 | Weekly |
| Discover a new Codex entry | 200 | One-time |
| Unlock a new biome | 1000 | One-time |

#### XP Curve Formula

```
XP_to_next_level = floor(100 * level^1.6)
```

| Level | XP Required | Cumulative XP |
|-------|------------|---------------|
| 1→2 | 100 | 100 |
| 2→3 | 303 | 403 |
| 3→4 | 569 | 972 |
| 4→5 | 884 | 1,856 |
| 5→6 | 1,240 | 3,096 |
| 10→11 | 3,981 | 20,789 |
| 15→16 | 8,282 | 65,321 |
| 20→21 | 14,180 | 151,420 |
| 25→26 | 21,527 | 289,760 |
| 29→30 | 29,021 | 435,500 |

### 6.2 Seed Tier Progression

Seeds progress through five rarity tiers. Higher tiers take longer to grow but produce richer, larger, more rewarding dungeons.

#### Growth Time Table

| Rarity | Spore | Sprout | Bud | Bloom | Total | Rooms at Bloom |
|--------|-------|--------|-----|-------|-------|----------------|
| **Common** | 1m | 5m | 15m | 30m | 51m | 6-8 |
| **Uncommon** | 2m | 10m | 30m | 1h | 1h 42m | 8-12 |
| **Rare** | 5m | 30m | 2h | 6h | 8h 35m | 12-16 |
| **Epic** | 15m | 2h | 8h | 24h | 34h 15m | 16-22 |
| **Legendary** | 1h | 8h | 24h | 72h | 105h | 22-30 |

#### Seed Properties Per Rarity

| Property | Common | Uncommon | Rare | Epic | Legendary |
|----------|--------|----------|------|------|-----------|
| Mutation slots | 1 | 1-2 | 2 | 2-3 | 3 |
| Room count | 6-8 | 8-12 | 12-16 | 16-22 | 22-30 |
| Boss rooms | 0-1 | 1 | 1 | 1-2 | 2 |
| Loot quality mod | ×1.0 | ×1.3 | ×1.7 | ×2.2 | ×3.0 |
| Enemy difficulty | Tier 1-2 | Tier 2-3 | Tier 3-4 | Tier 4-5 | Tier 5-6 |
| Seed discovery | Starting pool | Biome unlock | Crafting/drops | Boss drops | Breeding/seasonal |

### 6.3 Adventurer Progression

#### XP and Leveling

Adventurers earn XP from completed expedition rooms:

```
Room_XP = base_xp * room_tier * (1 + elemental_bonus) * difficulty_mod
```

| Room Type | Base XP |
|-----------|---------|
| Combat | 20 |
| Treasure | 10 |
| Trap | 15 (if survived without damage: +5 bonus) |
| Puzzle | 25 |
| Rest | 5 |
| Boss/Anchor | 50 |

**Adventurer Level XP Curve:**

```
XP_next = floor(80 * level^1.5)
```

| Level | XP to Next | Tier |
|-------|-----------|------|
| 1→2 | 80 | Novice |
| 2→3 | 226 | Novice |
| 3→4 | 392 | Novice |
| 4→5 | 571 | Novice |
| 5→6 | 760 | Skilled |
| 6→7 | 955 | Skilled |
| 9→10 | 1,548 | Skilled |
| 10→11 | 1,768 | Veteran |
| 14→15 | 2,973 | Veteran |
| 15→16 | 3,227 | Elite |
| 19→20 | 4,666 | Elite |

**Tier Thresholds:**
- Novice: Level 1-4
- Skilled: Level 5-9
- Veteran: Level 10-14
- Elite: Level 15-20

#### Skill Trees (Warrior Example)

```
                    ┌───────────────────┐
                    │   WARRIOR (Lv 1)  │
                    │   Shield Bash     │
                    └────────┬──────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                              ▼
    ┌─────────────────┐           ┌─────────────────┐
    │ VANGUARD PATH   │           │ BERSERKER PATH  │
    │ (Tank/Protect)  │           │ (Damage/Aggro)  │
    └────────┬────────┘           └────────┬────────┘
             │                              │
       ┌─────┴─────┐                 ┌─────┴─────┐
       ▼           ▼                 ▼           ▼
  ┌─────────┐ ┌─────────┐     ┌─────────┐ ┌─────────┐
  │ Iron    │ │ Taunt   │     │ Cleave  │ │ Rage    │
  │ Wall    │ │ Aura    │     │ Strike  │ │ Mode    │
  │ (Lv 3) │ │ (Lv 5)  │     │ (Lv 3) │ │ (Lv 5) │
  └────┬────┘ └────┬────┘     └────┬────┘ └────┬────┘
       │           │                │           │
       ▼           ▼                ▼           ▼
  ┌─────────┐ ┌─────────┐     ┌─────────┐ ┌─────────┐
  │ Fortify │ │ Last    │     │ Whirl-  │ │ Blood   │
  │ (Lv 8) │ │ Stand   │     │ wind    │ │ Frenzy  │
  │ +25%DEF │ │ (Lv 10) │     │ (Lv 8) │ │ (Lv 10) │
  └─────────┘ └─────────┘     └─────────┘ └─────────┘
       │           │                │           │
       └─────┬─────┘                └─────┬─────┘
             ▼                              ▼
     ┌──────────────┐              ┌──────────────┐
     │ Unbreakable  │              │ Warlord's    │
     │ Bulwark      │              │ Rampage      │
     │ (Lv 15,     │              │ (Lv 15,     │
     │  capstone)   │              │  capstone)   │
     └──────────────┘              └──────────────┘
```

#### Skill Trees (Mage Example)

```
                    ┌───────────────────┐
                    │    MAGE (Lv 1)    │
                    │   Arcane Bolt     │
                    └────────┬──────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                              ▼
    ┌─────────────────┐           ┌─────────────────┐
    │ ELEMENTALIST    │           │ ARCANIST PATH   │
    │ (Elemental DPS) │           │ (Utility/AoE)   │
    └────────┬────────┘           └────────┬────────┘
             │                              │
       ┌─────┴─────┐                 ┌─────┴─────┐
       ▼           ▼                 ▼           ▼
  ┌─────────┐ ┌─────────┐     ┌─────────┐ ┌─────────┐
  │ Flame   │ │ Frost   │     │ Arcane  │ │ Mana    │
  │ Lance   │ │ Nova    │     │ Shield  │ │ Surge   │
  │ (Lv 3) │ │ (Lv 5)  │     │ (Lv 3) │ │ (Lv 5) │
  └────┬────┘ └────┬────┘     └────┬────┘ └────┬────┘
       │           │                │           │
       ▼           ▼                ▼           ▼
  ┌─────────┐ ┌─────────┐     ┌─────────┐ ┌─────────┐
  │ Meteor  │ │ Blizzard│     │ Dispel  │ │ Chrono  │
  │ (Lv 8) │ │ (Lv 8)  │     │ Ward    │ │ Shift   │
  │ AoE nuke│ │ AoE DoT │     │ (Lv 8) │ │ (Lv 10) │
  └─────────┘ └─────────┘     └─────────┘ └─────────┘
       │           │                │           │
       └─────┬─────┘                └─────┬─────┘
             ▼                              ▼
     ┌──────────────┐              ┌──────────────┐
     │ Elemental    │              │ Rift         │
     │ Convergence  │              │ Collapse     │
     │ (Lv 15,     │              │ (Lv 15,     │
     │  capstone)   │              │  capstone)   │
     └──────────────┘              └──────────────┘
```

### 6.4 Equipment System

#### Equipment Slots (Per Adventurer)

| Slot | Effect |
|------|--------|
| **Weapon** | Primary ATK stat + special effect |
| **Armor** | Primary DEF stat + resistance |
| **Accessory** | Utility bonuses (speed, crit, element) |

#### Equipment Rarity Tiers

| Rarity | Stat Range | Special Effect | Source |
|--------|-----------|----------------|--------|
| Common | Base ×1.0 | None | Basic drops |
| Uncommon | Base ×1.3 | 1 minor effect | Uncommon+ dungeons |
| Rare | Base ×1.7 | 1 major effect | Rare+ dungeons, crafting |
| Epic | Base ×2.3 | 1 major + 1 minor | Epic+ dungeons, boss drops |
| Legendary | Base ×3.0 | 2 major effects | Legendary dungeons, prestige crafting |

#### Set Bonuses

Equipment belongs to themed sets. Wearing multiple pieces of the same set grants bonuses:

| Set Name | Element | 2pc Bonus | 3pc Bonus |
|----------|---------|-----------|-----------|
| Verdant Warden | Terra | +10% HP | +20% HP, heal 2% per room |
| Emberheart | Flame | +15% ATK | +15% ATK, Burn on hit (10%) |
| Frostguard | Frost | +12% DEF | +12% DEF, Slow enemies (15%) |
| Shimmerweave | Arcane | +10% Utility | +20% Utility, +5% crit |
| Voidtouched | Shadow | +8% Speed | +15% Speed, dodge +10% |
| Seedwarden's Legacy | Neutral | +5% all stats | +10% all stats, +10% loot |

### 6.5 Prestige System — "Garden Cycle"

At Seedwarden Level 30, players may initiate a **Garden Cycle** — a prestige reset that grants permanent bonuses.

#### What Resets:
- Seedwarden Level → 1
- All seeds cleared from grove (but codex entries preserved)
- Adventurer levels → 1 (but unlocked classes preserved)
- Gold and Essence → 0
- Biome progress → only Verdant Hollow unlocked

#### What Carries Over:
- **Seed Codex** (all discovered entries)
- **Unlocked adventurer classes** (all 6 remain available)
- **Permanent Garden Cycle bonuses** (see below)
- **Prestige-tier crafting recipes**
- **Cosmetic unlocks**
- **Fragments and Artifacts** (80% retained)

#### Permanent Bonuses Per Cycle:

| Cycle # | Bonus | Cumulative |
|---------|-------|------------|
| 1 | +5% global growth speed | +5% |
| 2 | +5% global loot quality | +5% growth, +5% loot |
| 3 | +1 starting grove plot | +5% growth, +5% loot, +1 plot |
| 4 | +5% adventurer XP gain | All previous + 5% XP |
| 5 | +5% mutation potency | All previous + 5% mutation |
| 6+ | Rotating +3% to random stat | Stacking |

#### Time-to-Progression Summary

| Milestone | Estimated Hours | What It Feels Like |
|-----------|----------------|-------------------|
| First Bloom | 0.5 | "Oh, THAT's how this works!" |
| First Boss Kill | 1.5 | "My team can handle anything!" |
| Embervault unlocked | 3 | "New biome! New enemies! New seeds!" |
| Full party of 6 classes | 8 | "I have so many options now" |
| Frostmere unlocked | 12 | "The world keeps getting bigger" |
| First Epic seed | 18 | "This is going to take a WHILE to grow... but the rewards..." |
| First Legendary drop | 30 | "YES! Finally!" |
| Voidmaw unlocked | 40 | "The final frontier" |
| First Garden Cycle | 55 | "Time to start fresh — but BETTER" |
| 3rd Garden Cycle | 120 | "I am the ultimate Seedwarden" |
| Completionist (all Codex) | 200+ | "I've grown every seed, cleared every dungeon" |

---

## 7. Combat Design — Expedition Resolution System

### 7.1 Design Philosophy

Dungeon Seed is NOT an action game. Combat is **simulated, not played.** The player's strategic decisions — party composition, equipment, elemental matchups, mutation choices — determine outcomes. The player watches (or idles through) the resolution. This is closer to **auto-chess** or **Football Manager** than **Hades** or **Diablo.**

The player's job is to SET UP the win conditions. The simulation executes them.

### 7.2 Room Resolution Algorithm

Each room in a dungeon is resolved sequentially. The algorithm:

```
FOR each room in expedition_path:
  1. DETERMINE room difficulty (base + tier_mod + mutation_mod)
  2. CALCULATE party power (sum of effective stats + synergies)
  3. RESOLVE combat:
     a. Initiative order by Speed stat
     b. Each combatant acts in order:
        - Adventurers: attack enemy pool (damage formula)
        - Enemies: attack adventurer pool (damage formula)
     c. Apply status effects
     d. Check for KOs (adventurer HP ≤ 0 → unconscious)
     e. Repeat until one side eliminated
  4. APPLY room results:
     - Surviving adventurers gain XP
     - Loot drops based on room type + tier + mutation mods
     - Party HP carries forward to next room
  5. IF all adventurers KO'd → expedition fails, partial loot
  6. IF room is Rest Room → heal party for 25% max HP
  7. ADVANCE to next room
```

### 7.3 Damage Formula

```
damage = floor(
  (ATK * classModifier * elementalBonus - DEF * armorMod)
  * synergyMod
  * statusMod
  * RNG(0.85, 1.15)
)

Minimum damage = 1 (attacks always deal at least 1)
```

#### Variable Definitions

| Variable | Description | Typical Range |
|----------|-------------|---------------|
| `ATK` | Attacker's Attack stat | 10-200 |
| `classModifier` | Multiplier based on class role | 0.8-1.5 |
| `elementalBonus` | Elemental advantage multiplier | 0.75-1.5 |
| `DEF` | Defender's Defense stat | 5-150 |
| `armorMod` | Armor effectiveness multiplier | 0.3-1.0 |
| `synergyMod` | Party composition bonus | 1.0-1.3 |
| `statusMod` | Active status effect modifier | 0.7-1.3 |
| `RNG(0.85, 1.15)` | Damage variance | ±15% |

#### Class Modifiers

| Class | vs Combat Room | vs Trap Room | vs Puzzle Room | vs Boss |
|-------|---------------|-------------|---------------|---------|
| Warrior | 1.2 | 0.8 | 0.9 | 1.1 |
| Ranger | 1.0 | 1.3 | 1.0 | 1.0 |
| Mage | 1.1 | 0.9 | 1.2 | 1.2 |
| Rogue | 1.0 | 1.2 | 1.1 | 0.9 |
| Alchemist | 0.9 | 1.1 | 1.3 | 1.0 |
| Sentinel | 1.1 | 1.0 | 0.8 | 1.2 |

### 7.4 Elemental Advantage Matrix

Elements follow a 5-way advantage system. Attacking with an advantaged element deals 1.5× damage. Attacking with a disadvantaged element deals 0.75× damage.

```
                    DEFENDER
            Terra  Flame  Frost  Arcane  Shadow
          ┌───────┬──────┬──────┬───────┬───────┐
  Terra   │ 1.00  │ 0.75 │ 1.50 │ 1.00  │ 1.00  │
          ├───────┼──────┼──────┼───────┼───────┤
  Flame   │ 1.50  │ 1.00 │ 0.75 │ 1.00  │ 1.00  │
A         ├───────┼──────┼──────┼───────┼───────┤
T  Frost  │ 0.75  │ 1.50 │ 1.00 │ 1.00  │ 1.00  │
T         ├───────┼──────┼──────┼───────┼───────┤
A  Arcane │ 1.00  │ 1.00 │ 1.00 │ 1.00  │ 1.50  │
C         ├───────┼──────┼──────┼───────┼───────┤
K  Shadow │ 1.00  │ 1.00 │ 1.00 │ 0.75  │ 1.00  │
E         └───────┴──────┴──────┴───────┴───────┘
R
```

**Mnemonic**: Terra crushes Frost (earth buries ice), Flame consumes Terra (wildfire), Frost quenches Flame (ice extinguishes), Arcane banishes Shadow (light dispels dark), Shadow corrupts Arcane (entropy erodes order).

### 7.5 Party Composition Synergies

When parties contain specific class combinations, synergy bonuses activate:

#### 2-Class Synergies

| Combo | Name | Effect |
|-------|------|--------|
| Warrior + Sentinel | **Ironwall** | Party DEF +15% |
| Warrior + Rogue | **Flanking Strike** | Rogue crit rate +20% |
| Mage + Alchemist | **Arcane Brew** | Mage spell damage +15% |
| Ranger + Rogue | **Scouting Party** | Trap rooms deal 50% less damage |
| Sentinel + Alchemist | **Fortified Heal** | Party heals 5% HP per room |
| Mage + Ranger | **Elemental Volley** | Ranged attacks gain element bonus |

#### 3-Class Synergies (Powerful)

| Combo | Name | Effect |
|-------|------|--------|
| Warrior + Mage + Sentinel | **Arcane Fortress** | +10% all stats, +10% loot |
| Ranger + Rogue + Alchemist | **Shadow Operations** | First strike guaranteed, +15% treasure |
| Warrior + Ranger + Mage | **Classic Trio** | +15% XP gain for all |
| Any 3 different classes | **Diverse Party** | +5% all stats |

#### 4-Class Bonus (Full Party)

| Condition | Effect |
|-----------|--------|
| 4 unique classes | +10% loot quality, +5% all stats |
| 4 unique classes covering all 3 roles (DPS/Tank/Support) | +15% loot, +10% all stats |

### 7.6 Status Effects

Status effects are applied by specific abilities, enemy attacks, and trap rooms:

| Status | Duration | Effect | Cure |
|--------|----------|--------|------|
| **Burn** | 3 rooms | -5% HP/room, -10% DEF | Frost spell, Alchemist cure |
| **Freeze** | 2 rooms | -30% Speed, skip first action | Flame attack, Alchemist cure |
| **Root** | 2 rooms | Cannot dodge, -20% Speed | Ranger cut, Alchemist cure |
| **Silence** | 3 rooms | Cannot use abilities | Mage dispel, Rest Room |
| **Curse** | 4 rooms | -15% all stats | Boss kill, Sentinel cleanse |
| **Poison** | 5 rooms | -3% HP/room | Alchemist cure, Rest Room |
| **Bolster** | 3 rooms | +15% ATK | Sentinel ability |
| **Shield** | Until broken | Absorb next hit (up to 30% max HP) | N/A (beneficial) |
| **Haste** | 2 rooms | +25% Speed, +10% dodge | Ranger ability |

### 7.7 Critical Hits and Dodge

**Critical Hits:**
```
crit_chance = base_crit + equipment_crit + skill_crit + synergy_crit
crit_damage = base_damage * 1.5

Base crit rates:
  Rogue:     8%
  Ranger:    5%
  Warrior:   3%
  Mage:      4%
  Alchemist: 2%
  Sentinel:  2%
```

**Dodge:**
```
dodge_chance = base_dodge + equipment_dodge + speed_bonus + synergy_dodge
If dodge: damage = 0

Base dodge rates:
  Rogue:     10%
  Ranger:    6%
  Mage:      3%
  Warrior:   2%
  Alchemist: 4%
  Sentinel:  2%
```

### 7.8 Boss Encounter Design

Boss encounters are multi-phase with special mechanics:

#### Phase Structure
```
BOSS ENCOUNTER
  │
  ├── Phase 1 (100%-60% HP): Normal attacks + 1 special ability
  │     └── Gear Check: can party output enough DPS?
  │
  ├── Phase 2 (60%-30% HP): Enraged, faster, +1 special ability
  │     └── Composition Check: does party have counters?
  │
  └── Phase 3 (30%-0% HP): Desperation, AoE attacks, status spam
        └── Survival Check: can party endure the onslaught?
```

#### Boss Design Per Biome

| Biome | Boss Name | Element | Mechanic |
|-------|-----------|---------|----------|
| Verdant Hollow | Thornmother | Terra | Summons root traps; Alchemist can cure Root |
| Embervault | Molten Sentinel | Flame | AoE Burn; bring Frost or high DEF |
| Frostmere | Glaciarch | Frost | Freezes party; need Flame DPS or Sentinel cleanse |
| Shimmerdeep | Prism Weaver | Arcane | Silences casters; need physical DPS backup |
| Voidmaw | The Hollow King | Shadow | Curses + phases that require different party configs |

### 7.9 Difficulty Scaling

Dungeon difficulty scales by tier and mutation modifiers:

```
room_difficulty = base_difficulty * (1 + (dungeon_tier * 0.15)) * mutation_modifier * biome_modifier
```

| Dungeon Tier | Difficulty Multiplier | Recommended Avg. Adventurer Level |
|-------------|----------------------|----------------------------------|
| 1 (Common Bloom) | ×1.0 | 1-4 |
| 2 (Uncommon Bloom) | ×1.3 | 4-8 |
| 3 (Rare Bloom) | ×1.7 | 8-13 |
| 4 (Epic Bloom) | ×2.3 | 13-17 |
| 5 (Legendary Bloom) | ×3.0 | 17-20 |
| 6+ (Abyssal/Prestige) | ×3.5+ (scaling) | 18-20 + gear |

### 7.10 Time-to-Clear Estimates

| Room Type | Active (watched) | Idle (background) |
|-----------|-----------------|-------------------|
| Combat | 8-15 seconds | 2-4 minutes |
| Treasure | 3-5 seconds | 30 seconds |
| Trap | 5-10 seconds | 1-2 minutes |
| Puzzle | 10-20 seconds | 3-5 minutes |
| Rest | 3-5 seconds | 30 seconds |
| Boss/Anchor | 30-60 seconds | 8-15 minutes |

| Dungeon Size | Active Total | Idle Total |
|-------------|-------------|-----------|
| 6 rooms (Common) | 1-2 min | 10-20 min |
| 12 rooms (Rare) | 3-5 min | 30-50 min |
| 22 rooms (Epic) | 6-10 min | 1-2 hours |
| 30 rooms (Legendary) | 10-15 min | 3-5 hours |

---

## 8. Seed System Deep Dive

### 8.1 Seed Anatomy

Every seed is a data object with the following properties:

```
Seed {
  seed_id:          uint64    // Unique ID, also used as RNG seed
  name:             String    // Generated name (e.g., "Emberheart Spore #4721")
  rarity:           Enum      // Common | Uncommon | Rare | Epic | Legendary
  element:          Enum      // Terra | Flame | Frost | Arcane | Shadow
  growth_stage:     Enum      // Spore | Sprout | Bud | Bloom
  growth_progress:  float     // 0.0 - 1.0 within current stage
  growth_speed:     float     // Base growth rate modifier (0.8 - 1.2)
  mutation_slots:   int       // 1-3 depending on rarity
  mutations:        Array     // Applied mutation IDs
  room_capacity:    int       // Max rooms at Bloom
  loot_bias:        Enum      // Gold | Essence | Fragments | Balanced
  hazard_density:   float     // 0.0 (safe) - 1.0 (treacherous)
  discovery_source: Enum      // Drop | Quest | Craft | Breed | Seasonal
  times_grown:      int       // For tracking codex completion
}
```

### 8.2 Growth Mechanics

#### Stage Progression

Seeds grow through four stages. Each stage unlocks more dungeon content:

```
  SPORE           SPROUT           BUD             BLOOM
  ┌─────┐        ┌─────┐        ┌─────┐        ┌─────┐
  │ · · │   ──→  │ ╱│╲ │   ──→  │ ╱█╲ │   ──→  │ ✿✿✿ │
  │  ·  │        │  │  │        │ ╱█╲ │        │ ✿✿✿ │
  │ ─── │        │ ─┼─ │        │ ─╋─ │        │ ═╬═ │
  └─────┘        └─────┘        └─────┘        └─────┘
  Planted.        Roots form.    Rooms grow.     Ready for
  Minimal         Basic rooms    Full layout     expedition.
  structure.      generated.     visible.        Max rewards.
```

| Stage | % of Dungeon Available | Room Types | Loot Quality |
|-------|----------------------|------------|-------------|
| Spore | 0% (no expedition possible) | None | None |
| Sprout | 30% (early harvest possible) | Combat, Rest only | ×0.5 |
| Bud | 65% (decent run) | All except Boss | ×0.8 |
| Bloom | 100% (full dungeon) | All including Boss | ×1.0 |

**Early Harvest**: Players CAN dispatch adventurers at Sprout or Bud stage for partial rewards. This is a strategic trade-off — get something now, or wait for full Bloom. Early harvest does NOT consume the seed; it continues growing.

#### Growth Speed Modifiers

| Modifier | Effect | Source |
|----------|--------|--------|
| Base growth speed | ×0.8 to ×1.2 per seed | Seed trait (random) |
| Growth Fertilizer | ×1.5 for current stage | Craftable consumable |
| Elemental Attunement | ×1.2 if grove has matching biome bonus | Grove upgrade |
| Garden Cycle bonus | +5% per prestige cycle | Prestige reward |
| Adjacent seed bonus | +3% if adjacent plot has same element | Spatial strategy |
| Grove Keeper NPC | +10% global while assigned | NPC system |

### 8.3 Mutation System

Mutations are the primary player agency over dungeon generation. Apply reagents to seeds during growth to reshape the resulting dungeon.

#### Reagent Types

| Reagent | Element | Effect | Trade-off |
|---------|---------|--------|-----------|
| **Verdant Bloom Essence** | Terra | +2 Treasure rooms | -1 Combat room |
| **Emberheart Catalyst** | Flame | +20% enemy density | +25% ATK loot drops |
| **Frostbite Tincture** | Frost | +Freeze traps in dungeon | +15% Frost Fragment drops |
| **Etheric Distillate** | Arcane | +2 Puzzle rooms | +20% rare material drops |
| **Shadowveil Extract** | Shadow | +30% hazard density | +40% loot quality |
| **Ironheart Reagent** | Neutral | +Reinforced Combat rooms | +30% armor/weapon drops |
| **Quickgrowth Serum** | Neutral | -30% growth time for next stage | -15% room count |
| **Overgrowth Tonic** | Neutral | +3 room capacity | +20% growth time |
| **Purity Filter** | Neutral | Remove all hazard rooms | -25% loot quality |
| **Chaos Mutagen** | Neutral | Randomize room layout entirely | Unpredictable (risk!) |

#### Mutation Slot Rules

- Each mutation slot accepts ONE reagent.
- Reagents are consumed on application.
- Reagents can be applied at any growth stage (Spore through Bud).
- Applying at Spore has maximum effect (+100% modifier).
- Applying at Bud has reduced effect (+50% modifier).
- Cannot apply mutations to Bloomed seeds (too late).
- Conflicting mutations (e.g., Purity Filter + Shadowveil) cancel each other; UI warns before application.

#### Mutation Stacking

When multiple mutations are applied, their effects combine multiplicatively:

```
final_modifier = mutation_1_effect * mutation_2_effect * mutation_3_effect
```

Example: Shadowveil Extract (+40% loot quality) + Emberheart Catalyst (+25% ATK drops):
- Loot quality: ×1.4
- ATK item drops: ×1.25
- Combined effect on ATK loot: ×1.4 × 1.25 = ×1.75

### 8.4 Deterministic Generation

Every seed produces a consistent dungeon for a given configuration. This is the **deterministic seeded RNG** system:

```
dungeon_layout = generate(
  seed_id,            // The unique seed identifier (acts as RNG seed)
  element,            // Determines room theme pool
  rarity,             // Determines room count and tier
  growth_stage,       // Determines % of rooms available
  mutations[],        // Modifies room distribution
  biome_variant       // Visual and enemy pool selection
)
```

**Key Property**: The same `seed_id` + `mutations[]` + `growth_stage` ALWAYS produces the same dungeon layout. This allows:
- **Seed sharing**: Share your seed config with friends, they get the same dungeon
- **Replay**: Run the same dungeon again with a different party
- **Strategy**: Plan party composition after previewing the dungeon map
- **Community**: "Try seed #4721 with Etheric Distillate — amazing loot room layout!"

#### Generation Algorithm (Simplified)

```
1. Initialize PCG RNG with seed_id
2. Determine room_count from rarity + mutations
3. Generate room_types[] by sampling from weighted pool:
   - Weights modified by element, mutations, and stage
4. Build room graph:
   a. Place Start node and Boss/Anchor node
   b. Generate main path (60% of rooms)
   c. Add branch paths (30% of rooms)
   d. Place optional/secret rooms (10% of rooms)
5. Connect rooms with edges (1-3 exits per room)
6. Assign enemies, loot tables, and hazards per room
7. Apply mutation overrides (swap room types, adjust counts)
8. Validate: ensure path from Start to Boss exists
9. Return dungeon graph
```

### 8.5 Seed Breeding (Endgame)

Unlocked at Seedwarden Level 28, the **Seed Breeding Lab** allows combining two Bloomed seeds to create a hybrid:

```
Parent A (Terra, Rare) + Parent B (Flame, Rare) = Offspring (Terra-Flame Hybrid, Rare)
```

#### Breeding Rules

| Rule | Detail |
|------|--------|
| Both parents must be fully Bloomed | Cannot breed unfinished seeds |
| Parents are consumed | The two seeds are destroyed |
| Offspring rarity = max(parent_A.rarity, parent_B.rarity) | Never downgrades |
| Element = random weighted from parents (70/30) | Primary element from higher-rarity parent |
| Dual-element possible (15% chance) | Offspring has affinities in both elements |
| Growth profile = averaged with variance | `(parent_A + parent_B) / 2 ± 10%` |
| Mutation slots = max(parent_A, parent_B) | Inherits the better slot count |
| 5% chance of "Mutation Evolution" | Offspring has a unique mutation slot type |

#### Hybrid Seed Benefits
- Dual-element dungeons combine enemy pools and hazards
- Unique hybrid room types only available through breeding
- Codex entries for hybrid seeds are separate from base seeds
- Breeding chains can produce Mythic seeds (beyond Legendary) in late-endgame

### 8.6 Seed Discovery Sources

| Source | Seed Types Available | Unlock Condition |
|--------|---------------------|------------------|
| **Starting pool** | 3 Common Terra seeds | Tutorial |
| **Quest rewards** | Common-Rare, all elements | Per-quest |
| **Dungeon drops** | Common-Epic, biome-matching | Random from runs |
| **Crafting** | Uncommon-Rare, chosen element | Crafting recipes |
| **Boss drops** | Rare-Epic, biome-matching | Boss kills |
| **Breeding** | Rare-Legendary, hybrid | Breeding Lab |
| **Seasonal events** | Limited-edition variants | Time-limited |
| **Prestige shop** | Epic-Legendary, chosen element | Garden Cycle currency |

### 8.7 The Seed Codex

A collectible catalog tracking every seed type the player has discovered and grown:

```
┌──────────────────────────────────────────────────┐
│  SEED CODEX                       142/280 (51%)  │
├──────────────────────────────────────────────────┤
│                                                  │
│  TERRA SEEDS (28/56)                             │
│  ├── Common Terra (5/5 variants grown) ✅        │
│  ├── Uncommon Terra (4/8 grown)                  │
│  ├── Rare Terra (2/12 grown)                     │
│  ├── Epic Terra (1/8 grown)                      │
│  └── Legendary Terra (0/4 discovered)  🔒       │
│                                                  │
│  FLAME SEEDS (32/56)                             │
│  ├── Common Flame (5/5 variants grown) ✅        │
│  ├── ...                                         │
│                                                  │
│  HYBRID SEEDS (8/40)                             │
│  ├── Terra-Flame (2/8 bred)                      │
│  ├── ...                                         │
│                                                  │
│  Completion Rewards:                             │
│  50% → Codex Scholar title + badge               │
│  75% → Seed growth speed +5% permanent           │
│  100% → Mythic Seed recipe unlocked              │
└──────────────────────────────────────────────────┘
```

---

## 9. World Design

### 9.1 World Map

The game world is organized as a central hub (the Seed Grove) with five biome regions radiating outward. Biomes unlock progressively as the player advances.

```
                        ╔═══════════════╗
                        ║  FROSTMERE    ║
                        ║  (Ice/Frost)  ║
                        ║  Unlock: Lv15 ║
                        ╚═══════╤═══════╝
                                │
            ╔═══════════════╗   │   ╔═══════════════╗
            ║  EMBERVAULT   ║   │   ║  SHIMMERDEEP  ║
            ║  (Magma/Fire) ║   │   ║  (Arcane)     ║
            ║  Unlock: Lv10 ║   │   ║  Unlock: Lv20 ║
            ╚═══════╤═══════╝   │   ╚═══════╤═══════╝
                    │           │           │
                    └───────────┼───────────┘
                                │
                    ╔═══════════╧═══════════╗
                    ║                       ║
                    ║     SEED GROVE        ║
                    ║     (Central Hub)     ║
                    ║                       ║
                    ╚═══════════╤═══════════╝
                                │
            ╔═══════════════╗   │   ╔═══════════════╗
            ║ VERDANT       ║   │   ║   VOIDMAW     ║
            ║ HOLLOW        ║───┘   ║   (Shadow)    ║
            ║ (Starter)     ║       ║  Unlock: Lv25 ║
            ║ Unlock: Lv1   ║       ╚═══════════════╝
            ╚═══════════════╝
```

### 9.2 Biome Profiles

#### 🌿 Verdant Hollow — The Living Ruins

**Theme**: Overgrown ancient ruins reclaimed by nature. Moss-covered stone, crystal pools, golden sunbeams filtering through canopy gaps. The safest biome — a gentle introduction.

**Color Palette**:
| Role | Hex | Swatch |
|------|-----|--------|
| Primary (forest) | `#1B5E20` | Deep green |
| Secondary (jade) | `#4CAF50` | Bright green |
| Accent (amber) | `#FFAB00` | Warm gold |
| Highlight | `#E8F5E9` | Pale green |
| Shadow | `#1B3A1B` | Dark forest |

**Architecture**: Crumbling stone walls with roots growing through them, vine-covered archways, mossy flagstones, crystal-clear water features.

**Enemy Roster**:

| Enemy | Type | Element | Difficulty | Special |
|-------|------|---------|------------|---------|
| Thornling | Minion | Terra | Tier 1 | Root attack (slows) |
| Moss Golem | Brute | Terra | Tier 2 | High HP, slow |
| Vine Snare | Trap-type | Terra | Tier 1 | Immobilizes for 1 turn |
| Crystal Slime | Minion | Arcane | Tier 1 | Splits on death (2 weaker copies) |
| Hollow Stag | Elite | Terra | Tier 3 | Charges (high single-target) |
| Root Wisp | Caster | Terra | Tier 2 | Heals other enemies |

**Boss**: **Thornmother** — A massive entangled tree-creature. Phase 1: root attacks. Phase 2: summons Thornlings. Phase 3: AoE vine storm.

**Resources**: Verdant Essence, Mosswood Fragments, Crystal Dew, Rootweave Fiber

**Ambient Audio**: Birdsong, gentle water flow, wind through leaves, distant stone crumbling

**Environmental Hazards**: Collapsing floors (DEF check), poisonous mushroom clouds (Alchemist negates), hidden pitfalls (Ranger detects)

---

#### 🔥 Embervault — The Molten Forge

**Theme**: An underground volcanic forge. Rivers of lava, rusted machinery, glowing embers, heat distortion. More dangerous, more rewarding.

**Color Palette**:
| Role | Hex | Swatch |
|------|-----|--------|
| Primary (ember) | `#BF360C` | Deep orange-red |
| Secondary (charcoal) | `#37474F` | Dark grey |
| Accent (molten) | `#FFD54F` | Bright gold |
| Highlight | `#FF8A65` | Warm orange |
| Shadow | `#1A1010` | Near-black |

**Architecture**: Basalt columns, iron catwalks over lava, bellows mechanisms, forge anvils embedded in walls, cooling slag formations.

**Enemy Roster**:

| Enemy | Type | Element | Difficulty | Special |
|-------|------|---------|------------|---------|
| Cinder Imp | Minion | Flame | Tier 2 | Burns on hit |
| Slag Brute | Brute | Flame | Tier 3 | Armored (high DEF) |
| Magma Crawler | Minion | Flame | Tier 2 | Leaves fire trail |
| Furnace Construct | Elite | Flame | Tier 3 | Immune to Burn |
| Ember Wraith | Caster | Flame | Tier 3 | AoE fire burst |
| Soot Lurker | Minion | Shadow | Tier 2 | Ambush (first strike) |

**Boss**: **Molten Sentinel** — A towering construct of cooled and living lava. Phase 1: melee slam + Burn. Phase 2: activates forge (room fills with heat — ticking damage). Phase 3: self-destructs in AoE.

**Resources**: Ember Shards, Scorite Fragments, Molten Core, Forgehammer Alloy

**Ambient Audio**: Crackling fire, distant metallic clanging, lava bubbles, steam hiss, bellows breathing

**Environmental Hazards**: Lava geysers (dodge/Speed check), furnace blasts (periodic AoE), collapsing catwalks (DEF check)

---

#### ❄️ Frostmere — The Frozen Depths

**Theme**: An icy subterranean lake-fortress. Frozen waterfalls, crystalline corridors, frost-etched runes, preserved ancient machinery. Beautiful and deadly.

**Color Palette**:
| Role | Hex | Swatch |
|------|-----|--------|
| Primary (ice) | `#0D47A1` | Deep blue |
| Secondary (silver) | `#B0BEC5` | Cool grey |
| Accent (violet) | `#CE93D8` | Pale purple |
| Highlight | `#E3F2FD` | Ice white |
| Shadow | `#0A1929` | Midnight blue |

**Architecture**: Ice columns, frozen locks, rune-carved glacier walls, preserved mechanisms under clear ice, frost-flower gardens.

**Enemy Roster**:

| Enemy | Type | Element | Difficulty | Special |
|-------|------|---------|------------|---------|
| Frost Sprite | Minion | Frost | Tier 3 | Freeze attack |
| Glacial Hound | Minion | Frost | Tier 3 | Pack bonus (+ATK per ally) |
| Ice Warden | Brute | Frost | Tier 4 | Reflects first attack |
| Frozen Revenant | Elite | Frost | Tier 4 | Resurrects once at 50% HP |
| Rime Caster | Caster | Frost | Tier 3 | AoE slow |
| Permafrost Golem | Brute | Frost/Terra | Tier 4 | Extremely high DEF |

**Boss**: **Glaciarch** — A crystalline dragon-like entity. Phase 1: breath attack (line Freeze). Phase 2: summons ice walls (limits party movement). Phase 3: blizzard (constant AoE + Freeze).

**Resources**: Frost Crystals, Glacial Essence, Rime Fragments, Frozen Rune Shards

**Ambient Audio**: Wind howl, ice cracking, crystalline chimes, distant frozen waterfall, echoing footsteps

**Environmental Hazards**: Ice floors (Speed reduced), blizzard rooms (visibility/accuracy penalty), frozen traps (instant Freeze — Alchemist cure or Flame element negates)

---

#### ✨ Shimmerdeep — The Arcane Nexus

**Theme**: Floating crystalline chambers connected by bridges of light. Arcane machinery, impossible geometry, ethereal lighting, the intersection of magic and architecture.

**Color Palette**:
| Role | Hex | Swatch |
|------|-----|--------|
| Primary (cyan) | `#00BCD4` | Bright teal |
| Secondary (violet) | `#7C4DFF` | Deep purple |
| Accent (luminous) | `#ECEFF1` | White glow |
| Highlight | `#B2EBF2` | Light cyan |
| Shadow | `#1A0A2E` | Deep indigo |

**Architecture**: Floating platforms, crystal conduits, arcane sigil floors, light-bridge pathways, rotating mechanism puzzles, gravity-defying architecture.

**Enemy Roster**:

| Enemy | Type | Element | Difficulty | Special |
|-------|------|---------|------------|---------|
| Shimmer Sprite | Minion | Arcane | Tier 3 | Teleports (hard to hit) |
| Glyph Guardian | Brute | Arcane | Tier 4 | Spellshield (blocks first spell) |
| Prism Shard | Minion | Arcane | Tier 3 | Refracts damage to random party member |
| Arcane Automaton | Elite | Arcane | Tier 4 | Silence aura (3-tile radius) |
| Ether Weaver | Caster | Arcane | Tier 4 | Buffs all allies |
| Phase Stalker | Elite | Arcane/Shadow | Tier 5 | Phases between dimensions (50% miss chance) |

**Boss**: **Prism Weaver** — A massive spider-like construct of pure light and crystal. Phase 1: laser beams (high single-target). Phase 2: creates mirror copies (must find real one). Phase 3: Silence aura + all previous abilities.

**Resources**: Arcane Dust, Prism Shards, Ether Essence, Glyph Fragments

**Ambient Audio**: Humming energy, crystalline resonance, distant choral tones, magical static, wind chimes

**Environmental Hazards**: Gravity flips (random stat shuffles), Silence zones, unstable platforms (fall = damage), arcane feedback (reflects portion of spell damage)

---

#### 🌑 Voidmaw — The Shadow Sanctum

**Theme**: A corrupted dimensional rift. Spectral architecture, phosphorescent growths, shadow tendrils, reality tears showing glimpses of other places. The final and most dangerous biome.

**Color Palette**:
| Role | Hex | Swatch |
|------|-----|--------|
| Primary (indigo) | `#1A237E` | Dark blue-black |
| Secondary (purple) | `#4A148C` | Deep violet |
| Accent (spectral) | `#009688` | Teal-green glow |
| Highlight | `#B388FF` | Ethereal purple |
| Shadow | `#0D0D1A` | True dark |

**Architecture**: Warped corridors, shadow-etched walls, floating debris, reality-tear windows, phosphorescent fungi, spectral architecture that shifts as you observe it.

**Enemy Roster**:

| Enemy | Type | Element | Difficulty | Special |
|-------|------|---------|------------|---------|
| Shade | Minion | Shadow | Tier 4 | Phases through walls (ignores DEF once) |
| Void Lurker | Brute | Shadow | Tier 5 | Curse on hit |
| Hollow One | Minion | Shadow | Tier 4 | Drains HP (heals self) |
| Nightmare Wisp | Caster | Shadow | Tier 5 | Fear (reduces ATK 20%) |
| Abyssal Construct | Elite | Shadow | Tier 5 | Immune to status effects |
| Entropy Weaver | Caster | Shadow/Arcane | Tier 5 | Dispels party buffs |

**Boss**: **The Hollow King** — An ancient Seedwarden corrupted by the Void. Phase 1: shadow swords (multi-hit). Phase 2: summons Shades + Curse aura. Phase 3: reality tear (randomizes party positions, stat debuffs, high AoE).

**Resources**: Void Essence, Shadowglass Fragments, Entropy Shards, Spectral Core

**Ambient Audio**: Low drones, reversed whispers, heartbeat-like pulses, distant screams, unsettling silence breaks

**Environmental Hazards**: Reality tears (teleport to random room), shadow pools (DoT if standing), Curse zones, dimensional instability (random room connections change)

### 9.3 The Seed Grove (Hub)

The central hub where all player activities converge:

```
┌──────────────────────────────────────────────────────┐
│                    SEED GROVE HUB                     │
│                                                      │
│    ┌──────────┐          ┌──────────┐                │
│    │ QUEST    │          │ CODEX    │                │
│    │ BOARD    │          │ LIBRARY  │                │
│    └────┬─────┘          └────┬─────┘                │
│         │                      │                      │
│    ┌────┴────────────────────┴────┐                  │
│    │        GARDEN PLOTS          │                  │
│    │   [1] [2] [3] [4] [5]       │                  │
│    │        [6] [7] [8]          │                  │
│    │   (expand with progression)  │                  │
│    └──────────┬───────────────────┘                  │
│               │                                      │
│    ┌──────────┼──────────────────────┐               │
│    │          │                      │               │
│    ▼          ▼                      ▼               │
│ ┌────────┐ ┌──────────┐ ┌───────────────┐           │
│ │ADVENTU-│ │ MUTARIUM │ │    VAULT &    │           │
│ │RER HALL│ │ ATELIER  │ │    MARKET     │           │
│ └────────┘ └──────────┘ └───────────────┘           │
│                                                      │
│              ┌──────────────┐                        │
│              │ DUNGEON      │                        │
│              │ BOARD (map)  │                        │
│              └──────────────┘                        │
│                                                      │
│              ┌──────────────┐                        │
│              │ BREEDING LAB │  (Unlocks Lv28)        │
│              └──────────────┘                        │
└──────────────────────────────────────────────────────┘
```

### 9.4 Procedural vs Hand-Crafted Ratio

| Content Type | Procedural | Hand-Crafted |
|-------------|-----------|-------------|
| Room layouts | 80% | 20% (set-piece rooms) |
| Room connections | 90% | 10% (forced paths for story) |
| Enemy placement | 85% | 15% (boss rooms, tutorials) |
| Loot distribution | 90% | 10% (quest-specific items) |
| Room visuals | Assembled from modular kit | Kit pieces are hand-crafted |
| Boss encounters | 0% | 100% (all hand-designed) |
| Story rooms | 0% | 100% |

### 9.5 Secret Rooms

5-10% of dungeon rooms are hidden. Discovery mechanics:

| Method | Class Bonus | Base Chance |
|--------|------------|------------|
| Ranger in party | +15% discovery | 5% per room |
| Rogue in party | +10% discovery | 5% per room |
| Puzzle Room solved perfectly | Reveals 1 secret room | 100% if perfect |
| Mutation: "Cartographer's Lens" | +25% discovery | Reagent |
| Legendary seed trait | Some seeds guarantee 1 secret | Seed property |

Secret rooms contain: bonus loot, lore fragments, rare seed drops, Codex entries, and occasionally shortcut paths.

---

## 10. Narrative Framework

### 10.1 Central Mystery

**"Why did the seeds awaken? What do the dungeons hunger for?"**

Centuries ago, an ancient civilization — the **Rootwardens** — discovered that certain magical seeds could grow not into plants, but into living structures. They cultivated these seeds into vast dungeon-gardens: places of power, knowledge, and treasure. The Rootwardens used the dungeons as farms — growing rooms full of magical resources, then harvesting them with trained expeditionary forces.

But something went wrong. The deepest seeds grew too far, touched something in the Void below, and the entire garden went dormant. The Rootwardens vanished. The seeds went silent for centuries.

Now, the seeds are waking up. The player — the last of a new generation of **Seedwardens** — discovers the abandoned grove and must uncover:

1. **What awakened the seeds?** (Act 1 mystery)
2. **What is The Echo, and why does it speak through mutated seeds?** (Act 2 mystery)
3. **What do the seeds ultimately want?** (Act 3 revelation)

### 10.2 Three-Act Structure

#### Act 1: Awakening (0-10 hours)

**Theme**: Discovery and wonder.

**Narrative Beats**:
1. **Cold Open**: Player finds the abandoned Seed Grove. A single seed glows on a pedestal. Tutorial prompt: "Plant it." The seed erupts into a small dungeon in a gorgeous growth animation. THE HOOK.
2. **The Grove Caretaker**: An ancient golem-like NPC awakens in response to the seed's growth. It remembers fragments of the Rootwardens and teaches the player basic seed cultivation.
3. **First Expedition**: Player dispatches first adventurers. They return with loot AND a mysterious fragment — a piece of text in an unknown script.
4. **The Echo Appears**: After growing 10+ seeds, a voice speaks through a mutated seed. It calls itself "The Echo" and claims to be a remnant of the Rootwardens. It offers guidance — but its advice always pushes toward deeper, riskier mutations.
5. **Biome Unlock**: Player grows enough seeds to unlock Embervault. The Grove Caretaker is surprised — "That region was sealed. The seeds shouldn't be able to reach there."
6. **Act 1 Climax**: A seed grows wrong. An **Aberrant Dungeon** appears — twisted, overgrown, dangerous. The Grove Caretaker recognizes it: "This happened before. This is how it started."

**Player emotions**: Curiosity, wonder, "one more seed," growing unease.

#### Act 2: Escalation (10-40 hours)

**Theme**: Complexity, choice, and growing tension.

**Narrative Beats**:
1. **Aberrant Seeds**: Some seeds now produce corrupted dungeons with unique (dangerous, rewarding) properties. The Echo encourages these. The Grove Caretaker warns against them.
2. **Faction Discovery**: Three factions emerge from the spreading seed growth:
   - **The Verdant Covenant**: Nature-aligned. Want to restore the garden to its original harmonious state. Cautious, preservation-focused.
   - **The Forge Compact**: Industry-aligned. Want to exploit the seeds for resources and power. Build, expand, conquer.
   - **The Void Seekers**: Chaos-aligned. Believe the Void below the seeds holds the true power. Embrace mutations, aberrations, and The Echo.
3. **Faction Quests**: Each faction offers unique quest lines with exclusive seeds, mutations, and lore. Player can build reputation with all three but eventually must prioritize.
4. **The Echo's True Nature**: Clues accumulate that The Echo isn't a Rootwarden remnant — it's something older. Something the Rootwardens found when they dug too deep.
5. **Frostmere & Shimmerdeep**: New biomes unlock with their own environmental storytelling. Frozen records in Frostmere tell of the Rootwardens' final days. Shimmerdeep's arcane machinery still runs, waiting for someone to complete the last experiment.
6. **Act 2 Climax**: The Voidmaw opens. This isn't a biome the player unlocked — it opened itself. The Echo's voice is strongest here. The Grove Caretaker says: "The seeds didn't awaken on their own. Something CALLED them."

**Player emotions**: Strategic depth, factional loyalty, narrative investment, creeping dread.

#### Act 3: Revelation (40-60 hours)

**Theme**: Choice, consequence, and the meaning of cultivation.

**Narrative Beats**:
1. **The Truth**: The seeds are not tools. They are a living organism — a mycelial network that spans the entire world below the surface. The Rootwardens didn't create the seeds; they discovered a symbiotic relationship with the network. The dungeons are the network's fruiting bodies — how it reproduces and spreads.
2. **The Echo Revealed**: The Echo is the network's consciousness. It went dormant when the Rootwardens severed the connection to the Void (the deepest layer of the network). Now it's waking up and wants to reconnect — which would mean the seeds grow without limit, consuming the surface world.
3. **The Choice**: Three endings aligned with the three factions:
   - **Verdant Covenant ending**: Restore the symbiotic balance. Seeds grow, but within controlled bounds. The garden thrives as a partnership between Seedwarden and network. (Peaceful, sustainable)
   - **Forge Compact ending**: Sever the network permanently. Harvest the remaining seeds for their power, but no new seeds will ever grow. The garden becomes a museum. (Industrial, finite)
   - **Void Seeker ending**: Embrace The Echo. Allow the network to fully reconnect. Seeds grow wildly, unpredictably — infinite dungeons, infinite danger, infinite reward. The world transforms. (Chaotic, infinite)
4. **Post-ending**: All three endings unlock a unique endgame modifier that changes the feel of prestige cycles and provides thematic endgame content.

**Player emotions**: Narrative revelation, meaningful choice, satisfying conclusion, desire to see other endings.

### 10.3 Faction System

| Faction | Philosophy | Leader | Exclusive Rewards |
|---------|-----------|--------|------------------|
| **Verdant Covenant** | Growth through balance | Elderbloom (ancient dryad NPC) | Nature-themed seeds, healing mutations, defensive gear sets |
| **Forge Compact** | Growth through industry | Ironwright (dwarven artificer) | Metal-themed seeds, efficiency mutations, offensive gear sets |
| **Void Seekers** | Growth through chaos | Whisper (hooded figure, identity unknown) | Aberrant seeds, chaos mutations, high-risk/high-reward gear |

**Reputation System**:
- 5 levels per faction: Stranger → Acquaintance → Ally → Champion → Exalted
- Advancing with one faction does NOT decrease reputation with others (no zero-sum)
- However, final Act 3 choice permanently aligns with one faction for that playthrough
- Prestige reset allows choosing a different faction alignment

### 10.4 Lore Depth Layers

| Layer | What It Contains | Who Sees It |
|-------|-----------------|-------------|
| **Surface** | Main quest dialogue, faction introductions, major revelations | Everyone (main quest) |
| **Buried** | Item descriptions that hint at history, NPC ambient dialogue, crafting recipe flavor text | Players who read tooltips |
| **Hidden** | Environmental storytelling in dungeon rooms (wall carvings, broken journals, skeletal poses), secret room discoveries | Explorers and completionists |
| **Secret** | Seed Codex entries that form a hidden message when read in order, numerical patterns in seed IDs, a secret 6th biome hinted at but never accessible (sequel hook) | Community puzzle-solvers |

### 10.5 Dialogue Philosophy

- **Text-based only** — no voice acting (indie scope, localization-friendly)
- **Personality-driven**: Each NPC has a distinct voice. The Caretaker is formal and ancient. The Echo is cryptic and rhythmic. Elderbloom is warm but firm. Ironwright is gruff and practical. Whisper is seductive and dangerous.
- **Brief and evocative**: No dialogue box should exceed 3 sentences. "Show, don't tell" — let dungeon environments carry lore weight.
- **Player-prompted**: The player initiates conversations, never forced. Quest-critical dialogue appears as a single highlighted prompt in the grove.
- **Bark system**: NPCs have idle barks (short ambient lines) that change based on game state (new biome unlocked, aberrant dungeon appeared, faction reputation changes).

### 10.6 THE HOOK — First 60 Seconds

```
FADE IN: The screen is dark. A faint green glow pulses.

TEXT: "The seeds remember."

The camera pulls back to reveal an overgrown ruin — the Seed Grove,
abandoned and reclaimed by nature. Stone walls crumble. Vines cover
everything. But in the center, on a mossy pedestal, a single SEED
pulses with inner light.

PROMPT: "Plant it." (single button press)

The player taps. The seed sinks into the soil. A beat of silence.

Then: RUMBLE. The ground CRACKS. Roots erupt outward. Stones shift.
The camera shakes. A DUNGEON blooms from the earth in a cascade of
magical energy — rooms unfolding like petals, corridors stretching
like vines, a living structure GROWING before the player's eyes.

The growth animation takes 8 seconds. It is the most polished
animation in the entire game.

GROVE CARETAKER (awakening): "You... you planted one. After all
this time. The garden remembers you, Seedwarden."

TUTORIAL BEGINS — seamlessly.
```

The hook delivers:
- **Spectacle**: The growth animation is visually stunning
- **Agency**: The player caused this with a single tap
- **Mystery**: What ARE these seeds? Why does the golem know me?
- **Gameplay promise**: THIS is what you'll be doing — growing dungeons

---

## 11. Character Archetypes

### 11.1 The Six Adventurer Classes

#### ⚔️ Warrior

**Role**: Frontline tank and damage dealer. Absorbs hits, protects the party, delivers consistent melee damage.

| Stat | Base (Lv 1) | Growth/Lv | Role |
|------|-------------|-----------|------|
| HP | 120 | +12 | Highest in game |
| ATK | 22 | +3 | High |
| DEF | 18 | +3 | High |
| SPD | 8 | +1 | Low |
| UTL | 5 | +1 | Low |

**Active Abilities**:
1. **Shield Bash** (Lv 1): Deal 120% ATK damage, 15% chance to Stun for 1 action.
2. **Cleave** (Lv 5): Deal 80% ATK to all enemies. Great for multi-enemy Combat rooms.
3. **Rallying Cry** (Lv 10): Party ATK +10% for 2 rooms.

**Passive Abilities**:
1. **Iron Skin** (Lv 3): Reduce incoming damage by flat 5.
2. **Last Stand** (Lv 8): When HP falls below 20%, DEF doubles for remainder of room.

**Personality Archetype**: Stalwart, protective, speaks in short declarative sentences. "We hold the line." Names like Gareth, Brenna, Thorne.

**Party Role**: Primary tank. Put in front position to absorb damage. Essential for Boss rooms and Reinforced Combat rooms.

---

#### 🏹 Ranger

**Role**: Ranged damage dealer and trap specialist. Detects hazards, deals consistent ranged damage, excellent in Trap rooms.

| Stat | Base (Lv 1) | Growth/Lv | Role |
|------|-------------|-----------|------|
| HP | 85 | +8 | Medium |
| ATK | 20 | +3 | High |
| DEF | 12 | +2 | Medium |
| SPD | 16 | +2 | High |
| UTL | 12 | +2 | Medium |

**Active Abilities**:
1. **Twin Shot** (Lv 1): Two attacks at 65% ATK each. High total damage.
2. **Trap Sense** (Lv 5): Reveal and disarm traps in current room. Trap rooms become Treasure rooms.
3. **Rain of Arrows** (Lv 10): Deal 60% ATK to all enemies, apply Slow (-20% SPD) for 2 actions.

**Passive Abilities**:
1. **Fleet Foot** (Lv 3): +15% dodge chance.
2. **Keen Eye** (Lv 8): +15% secret room discovery chance.

**Personality Archetype**: Quiet, observant, patient. "I see the path." Names like Ash, Wren, Cypress.

**Party Role**: Trap neutralizer and consistent ranged DPS. Invaluable in Trap-heavy dungeons (Frostmere, Voidmaw).

---

#### 🔮 Mage

**Role**: Elemental damage dealer and AoE specialist. Highest burst damage, elemental matchup expert, fragile.

| Stat | Base (Lv 1) | Growth/Lv | Role |
|------|-------------|-----------|------|
| HP | 70 | +6 | Lowest |
| ATK | 25 | +4 | Highest |
| DEF | 8 | +1 | Lowest |
| SPD | 12 | +2 | Medium |
| UTL | 18 | +3 | Highest |

**Active Abilities**:
1. **Arcane Bolt** (Lv 1): Deal 130% ATK damage to single target. Simple but strong.
2. **Elemental Burst** (Lv 5): Deal 100% ATK to all enemies. Element matches equipped weapon.
3. **Mystic Ward** (Lv 10): Party gains Shield (absorbs damage = 25% of Mage's UTL).

**Passive Abilities**:
1. **Elemental Attunement** (Lv 3): +25% elemental bonus damage (instead of standard +50% for advantage, Mage gets +75%).
2. **Mana Surge** (Lv 8): 10% chance per room to cast ability twice.

**Personality Archetype**: Intellectual, curious, sometimes arrogant. "Fascinating — a suboptimal elemental matrix." Names like Cyrus, Lumen, Vesper.

**Party Role**: Primary damage dealer. Match Mage's element to dungeon weakness for devastating results. Protect them — they're fragile.

---

#### 🗡️ Rogue

**Role**: Burst damage, critical strikes, and treasure specialist. Excels at single-target elimination and finding bonus loot.

| Stat | Base (Lv 1) | Growth/Lv | Role |
|------|-------------|-----------|------|
| HP | 80 | +7 | Low-Medium |
| ATK | 24 | +3 | High |
| DEF | 10 | +1 | Low |
| SPD | 18 | +3 | Highest |
| UTL | 10 | +2 | Medium |

**Active Abilities**:
1. **Backstab** (Lv 1): Deal 200% ATK to single target. Only works on first action (ambush).
2. **Pilfer** (Lv 5): Steal an extra item from loot pool. +15% rare drop chance this room.
3. **Shadow Dance** (Lv 10): Dodge all attacks for 2 actions. Cannot be targeted.

**Passive Abilities**:
1. **Opportunist** (Lv 3): +8% crit rate. Crits deal 2.0× instead of 1.5×.
2. **Lockpick** (Lv 8): Treasure rooms yield +25% loot. Locked chests auto-opened.

**Personality Archetype**: Charming, quick-witted, mercenary. "I'm here for the shinies." Names like Finch, Nyx, Dagger.

**Party Role**: Burst DPS and loot optimizer. Pair with Warrior (Flanking Strike synergy) or Ranger (Shadow Operations synergy).

---

#### ⚗️ Alchemist

**Role**: Support utility, healing, damage-over-time, and status effect specialist. The Swiss army knife.

| Stat | Base (Lv 1) | Growth/Lv | Role |
|------|-------------|-----------|------|
| HP | 90 | +8 | Medium |
| ATK | 15 | +2 | Low |
| DEF | 14 | +2 | Medium |
| SPD | 10 | +1 | Low |
| UTL | 20 | +3 | Highest (tied) |

**Active Abilities**:
1. **Acid Flask** (Lv 1): Deal 80% ATK + apply Poison (3% HP/room for 5 rooms). Great vs bosses.
2. **Healing Brew** (Lv 5): Heal lowest-HP ally for 30% of Alchemist's UTL. Once per room.
3. **Universal Antidote** (Lv 10): Cure all status effects on all party members. Full cleanse.

**Passive Abilities**:
1. **Reagent Knowledge** (Lv 3): Puzzle rooms grant +20% bonus rewards.
2. **Brew Efficiency** (Lv 8): Healing Brew now heals for 45% of UTL and triggers twice per room.

**Personality Archetype**: Eccentric, enthusiastic about chemicals, slightly unstable. "Ooh, what happens if I add THIS?" Names like Pipette, Brewer, Thorn.

**Party Role**: Healer and status cleanser. Essential for long dungeons (Epic/Legendary seeds) where HP attrition matters most.

---

#### 🛡️ Sentinel

**Role**: Party buffer, team durability, and boss specialist. Makes everyone else better.

| Stat | Base (Lv 1) | Growth/Lv | Role |
|------|-------------|-----------|------|
| HP | 110 | +10 | High |
| ATK | 14 | +2 | Low |
| DEF | 20 | +3 | Highest |
| SPD | 8 | +1 | Low |
| UTL | 16 | +3 | High |

**Active Abilities**:
1. **Bulwark** (Lv 1): Reduce all party damage taken by 20% for current room.
2. **Bolster** (Lv 5): Grant Bolster (+15% ATK) to all party members for 3 rooms.
3. **Guardian's Oath** (Lv 10): Intercept all damage targeting lowest-HP ally for 2 actions. Sentinel takes damage instead.

**Passive Abilities**:
1. **Vigilance** (Lv 3): Party cannot be surprised. Ambush attacks deal 50% damage.
2. **Aura of Tenacity** (Lv 8): Party HP regenerates 2% per room.

**Personality Archetype**: Calm, duty-bound, selfless. "My place is between you and harm." Names like Bastion, Aegis, Ward.

**Party Role**: Force multiplier. Doesn't deal damage — makes everyone else survive longer and hit harder. Essential for Boss rooms and high-tier dungeons.

### 11.2 Key NPCs

| NPC | Role | Personality | Appears |
|-----|------|-------------|---------|
| **Grove Caretaker** | Tutorial mentor, lore source, upgrades | Ancient, formal, protective, fragments of memory | Act 1 onward |
| **The Echo** | Mysterious guide/antagonist | Cryptic, rhythmic speech, seductive, always pushing deeper | Act 1 (seeds), Act 2+ (direct) |
| **Elderbloom** | Verdant Covenant leader | Warm, patient, wise, speaks in nature metaphors | Act 2 onward |
| **Ironwright** | Forge Compact leader | Gruff, practical, results-oriented, distrusts magic | Act 2 onward |
| **Whisper** | Void Seekers leader | Mysterious, androgynous, speaks in paradoxes | Act 2 onward |
| **Root Merchant** | General shop, buys/sells | Cheerful, merchant cliches but self-aware about it | After Lv 5 |
| **Wandering Seedwright** | Rare seed seller, appears randomly | Eccentric, travels between worlds, unreliable narrator | Random events |

### 11.3 Recommended Party Compositions

| Biome | Recommended Party | Why |
|-------|------------------|-----|
| **Verdant Hollow** | Warrior, Mage (Flame), Rogue, Alchemist | Flame counters Terra; Rogue for treasure; Alchemist for poison heals |
| **Embervault** | Warrior, Mage (Frost), Ranger, Sentinel | Frost counters Flame; Ranger for traps; Sentinel for boss survival |
| **Frostmere** | Warrior, Mage (Flame), Alchemist, Sentinel | Flame melts Frost; Alchemist cures Freeze; Sentinel buffs survival |
| **Shimmerdeep** | Warrior, Ranger, Rogue, Sentinel | Physical damage avoids Silence; Ranger/Rogue for secret rooms |
| **Voidmaw** | Mage (Arcane), Alchemist, Sentinel, Ranger | Arcane counters Shadow; Alchemist cures Curse; Sentinel is essential |

---

## 12. Economy Design

### 12.1 Currency Types

| Currency | Symbol | Primary Use | Earn Rate | Scarcity |
|----------|--------|-------------|-----------|----------|
| **Gold** | 🪙 | Recruitment, equipment, grove upgrades | High | Abundant |
| **Essence** | ✨ | Seed growth boosts, mutation crafting | Medium | Moderate |
| **Fragments** | 🔷 | Gear crafting, artifact forging | Medium-Low | Scarce |
| **Artifacts** | ⭐ | Permanent upgrades, prestige currency | Very Low | Very Scarce |
| **Relics** | 🏛️ | Codex completion, seasonal rewards | Very Low | Ultra Scarce |

### 12.2 Sink/Faucet Analysis

#### Gold (🪙) — The Workhorse Currency

**Faucets (Income)**:
| Source | Amount | Frequency |
|--------|--------|-----------|
| Combat room clear | 10-50 (scales with tier) | Per room |
| Treasure room | 30-150 | Per room |
| Expedition completion bonus | 50-300 | Per expedition |
| Selling unwanted loot | 5-100 per item | Player-initiated |
| Daily login bonus | 50-200 (escalating) | Daily |
| Quest rewards | 100-500 | Per quest |
| Idle accumulation | 5-20/min (grove level dependent) | Passive |

**Sinks (Spending)**:
| Sink | Cost | Frequency |
|------|------|-----------|
| Adventurer recruitment | 100-1000 (class dependent) | One-time per hero |
| Equipment purchase (shop) | 50-5000 (rarity dependent) | As needed |
| Grove plot unlock | 500, 1000, 2000, 5000, 10000 | Milestone |
| Building upgrades (Hub) | 200-10000 | Progressive |
| Expedition supply cost | 10-100 per expedition | Per dispatch |
| Adventurer rest acceleration | 20-200 | Optional |

#### Essence (✨) — The Growth Currency

**Faucets**:
| Source | Amount | Frequency |
|--------|--------|-----------|
| Expedition rooms | 5-25 per room | Per room |
| Seed recycling (destroy unwanted seed) | 20-500 (rarity dependent) | Player-initiated |
| Boss kills | 50-200 | Per boss |
| Daily quest | 30-100 | Daily |

**Sinks**:
| Sink | Cost | Frequency |
|------|------|-----------|
| Growth Fertilizer crafting | 30-100 | Per fertilizer |
| Mutation reagent crafting | 50-300 | Per reagent |
| Seed crafting (new seeds) | 100-1000 | Per seed |
| Breeding Lab operation | 200-500 per breed | Per breed attempt |

#### Fragments (🔷) — The Crafting Currency

**Faucets**:
| Source | Amount | Frequency |
|--------|--------|-----------|
| Expedition loot | 2-10 per room (biome-specific types) | Per room |
| Dismantling equipment | 5-50 (rarity dependent) | Player-initiated |
| Boss drops | 10-50 | Per boss |
| Weekly quest | 20-80 | Weekly |

**Sinks**:
| Sink | Cost | Frequency |
|------|------|-----------|
| Gear crafting | 10-200 per recipe | Per craft |
| Artifact forging | 50-500 | Per artifact |
| Equipment upgrade | 20-100 per upgrade level | Per upgrade |
| Prestige shop items | 100-1000 | Post-prestige |

### 12.3 Currency Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                      CURRENCY FLOW                               │
│                                                                  │
│  ┌──────────┐                              ┌──────────────┐     │
│  │ DUNGEON  │──── Gold ──────────────────→ │ ADVENTURER   │     │
│  │ RUNS     │──── Essence ───┐             │ HALL         │     │
│  │ (faucet) │──── Fragments ─┼──┐          │ (recruitment │     │
│  │          │──── Artifacts ─┼──┼──┐       │  + equipment)│     │
│  └──────────┘                │  │  │       └──────────────┘     │
│                              │  │  │              ↑              │
│                              ▼  │  │          Gold │              │
│                      ┌───────────┐ │  │              │              │
│                      │ MUTARIUM  │ │  │       ┌──────────────┐     │
│                      │ (reagent  │ │  │       │ VAULT &      │     │
│                      │  crafting)│ │  │       │ MARKET       │     │
│                      └───────────┘ │  │       │ (sell items, │     │
│                              │     │  │       │  buy recipes)│     │
│                    Reagents  │     │  │       └──────────────┘     │
│                              ▼     │  │              ↑              │
│                      ┌───────────┐ │  │        Fragments           │
│                      │ SEED      │ │  │              │              │
│                      │ GROVE     │←┘  │       ┌──────────────┐     │
│                      │ (plant +  │    │       │ CRAFTING     │     │
│                      │  grow)    │    │       │ STATION      │     │
│                      └───────────┘    │       │ (gear forge) │     │
│                              │        │       └──────────────┘     │
│                     New Seeds │        │              ↑              │
│                              ▼        │         Artifacts          │
│                      ┌───────────┐    │              │              │
│                      │ DUNGEON   │    │       ┌──────────────┐     │
│                      │ BOARD     │    └──────→│ PRESTIGE     │     │
│                      │ (ready to │            │ SHOP         │     │
│                      │  dispatch)│            │ (permanent   │     │
│                      └─────┬─────┘            │  upgrades)   │     │
│                            │                  └──────────────┘     │
│                            └───────→ [DUNGEON RUNS] ──→ cycle     │
└──────────────────────────────────────────────────────────────────┘
```

### 12.4 Drop Rate Tables

#### Loot Rarity Per Room Type (base rates, before mutation modifiers)

| Room Type | Common | Uncommon | Rare | Epic | Legendary |
|-----------|--------|----------|------|------|-----------|
| Combat | 65% | 25% | 8% | 1.8% | 0.2% |
| Treasure | 40% | 35% | 18% | 6% | 1% |
| Trap (survived) | 50% | 30% | 15% | 4% | 1% |
| Puzzle (solved) | 35% | 35% | 20% | 8% | 2% |
| Boss/Anchor | 20% | 30% | 30% | 15% | 5% |
| Secret Room | 30% | 30% | 25% | 12% | 3% |

#### Dungeon Tier Multiplier on Drop Quality

| Seed Rarity | Drop Quality Modifier |
|-------------|---------------------|
| Common | ×1.0 (base rates above) |
| Uncommon | ×1.15 (shift up: fewer commons, more uncommons) |
| Rare | ×1.35 |
| Epic | ×1.60 |
| Legendary | ×2.00 |

### 12.5 Crafting System

#### Material Hierarchy

```
Raw Materials (dungeon drops)
    │
    ▼
Refined Materials (crafting station: 3 raw → 1 refined)
    │
    ▼
Components (crafting station: 2 refined + essence → 1 component)
    │
    ▼
Finished Items (crafting station: 2-3 components + fragments → 1 equipment)
    │
    ▼
Enhanced Items (upgrade station: finished item + artifact + fragments → enhanced)
```

#### Recipe Discovery

| Method | Example |
|--------|---------|
| **Quest reward** | Complete "Forge the First Blade" → learn Iron Sword recipe |
| **Drop from dungeon** | Blueprint items drop as rare loot |
| **Experimentation** | Combine 3 unknown materials at crafting station, 30% chance to discover recipe |
| **Faction reputation** | Verdant Covenant Ally → learn Nature's Embrace armor recipe |
| **Prestige shop** | Buy exclusive crafting recipes with Artifacts |

### 12.6 Inflation Prevention

| Mechanism | How It Works |
|-----------|-------------|
| **Expedition supply costs** | Every dispatch costs Gold, scaling with dungeon tier |
| **Equipment degradation** | Gear loses durability over runs, costs Gold/Fragments to repair |
| **Recruitment costs scale** | Each additional adventurer costs 50% more than the last |
| **Diminishing idle returns** | Idle Gold accumulation has soft cap; slows dramatically after 8hr offline |
| **Crafting failure** | Non-trivial recipes have 10-30% chance to consume materials without producing item |
| **Grove plot costs** | Each new plot costs 2× the previous one |
| **Prestige reset** | Garden Cycle resets Gold and Essence (the primary inflation risk currencies) |

### 12.7 The "Feels Fair" Rule

**Every 5-minute active session should yield:**
- At least 1 visible equipment upgrade OR meaningful crafting progress
- Enough Gold to sustain 2-3 more dispatches without feeling "broke"
- At least 1 seed at or near Bloom stage (assuming proper staggering)
- A sense of "I'm closer to [next goal]" — never stagnation

**Every idle return (4-8 hours away) should yield:**
- 1-3 fully Bloomed seeds ready for expedition
- Accumulated Gold/Essence equal to ~40% of an active session of that duration
- Completed expedition results with loot to collect
- A feeling of "things happened while I was away" — never emptiness

---

## 13. Multiplayer Design

### 13.1 Philosophy: Solo-First, Social-Second

Dungeon Seed is a **single-player game** with optional asynchronous social features. Multiplayer is never required for progression. Social features enhance the experience for those who want them and are invisible to those who don't.

### 13.2 Social Features

#### Seed Sharing
- Players can export a **Seed Config** (seed_id + mutations applied) as a shareable code
- Friends paste the code to receive a copy of that seed in their grove
- The shared seed produces the EXACT same dungeon (deterministic generation)
- Community can share "amazing seed configs" on forums, Discord, etc.
- Shared seeds do NOT cost the sharer anything — it's a copy, not a transfer

```
SEED SHARE CODE: DS-4721-TERRA-R3-M[ETHERIC,IRON]
"Try this one — 3 treasure rooms in a row!"
```

#### Leaderboards (Opt-In)
- **Fastest Clear**: Lowest time to clear a specific seed config
- **Highest Tier Grown**: Rarest seed successfully bloomed
- **Codex Completion**: Most seed types discovered
- **Garden Cycle Count**: Most prestiges completed
- **Weekly Challenge Score**: Performance in rotating challenges

#### Weekly Challenges
- Community-wide goals: "Collectively grow 10,000 Terra seeds this week"
- Shared milestone rewards (everyone gets bonus if community hits target)
- Individual contribution tracking
- Rewards: Exclusive cosmetics, rare reagents, limited seeds

#### Friend Groves (Future Feature)
- Visit friends' Seed Groves as a read-only scenic tour
- Leave "gifts" (small resource bundles) on their doorstep
- See their garden layout, seed collection, and adventurer roster
- "Likes" system for garden aesthetics

### 13.3 Future Multiplayer Expansion (Post-MVP)

| Feature | Description | Priority |
|---------|-------------|----------|
| Cooperative Expeditions | 2 players each contribute half a party; shared dungeon, shared loot | Post-launch DLC |
| Guild Gardens | Shared grove where guild members plant seeds together | Post-launch major |
| PvP Arena | Compare adventurer builds in simulated combat | Evaluated post-launch |
| Seed Trading | Player-to-player seed exchange | Evaluated post-launch |

### 13.4 Anti-Grief Measures

- Shared seeds are copies, never transfers (can't scam)
- Leaderboards are opt-in
- No real-time interaction required (async only)
- Block/mute/report for friend grove messages
- No competitive pressure in core progression

---

## 14. Art Direction

### 14.1 Visual Identity

**Style**: Stylized painterly RPG. Hand-painted textures with soft lighting, magical glow effects, and warm color grading. NOT pixel art. NOT photorealistic. Think: **Book of Travels** meets **Genshin Impact's UI** meets **Stardew Valley's warmth** — but more "illustrated storybook" than any of those.

**Perspective**:
- **Seed Grove (Hub)**: 2.5D isometric, 30° dimetric projection. The grove is viewed from above-and-to-the-side, like a tiny diorama you're tending.
- **Dungeon Expedition**: 2D illustrated panels. Each room is a hand-painted card/frame. Rooms connect in a node-graph viewed top-down. Room interiors are side-view illustrations.
- **Menus/UI**: Flat 2D with layered depth effects (parallax, drop shadows, glass blur).

**Proportions**: Characters use 3-head proportions (not full chibi, but stylized and expressive). Large heads, expressive eyes, simplified hands. Readable at small sizes.

### 14.2 Color Palettes

#### Seed Grove Hub
| Role | Hex | Name |
|------|-----|------|
| Background | `#2D5A27` | Deep moss |
| Primary UI | `#F4D03F` | Warm gold |
| Secondary UI | `#5DADE2` | Sky blue |
| Text | `#FDFEFE` | Off-white |
| Text shadow | `#1A3C1A` | Dark green |
| Accent (positive) | `#58D68D` | Spring green |
| Accent (warning) | `#E74C3C` | Alert red |
| Accent (info) | `#85C1E9` | Soft blue |

#### Per-Biome Palettes

| Biome | Primary | Secondary | Accent | Highlight | Shadow |
|-------|---------|-----------|--------|-----------|--------|
| Verdant Hollow | `#1B5E20` | `#4CAF50` | `#FFAB00` | `#E8F5E9` | `#1B3A1B` |
| Embervault | `#BF360C` | `#37474F` | `#FFD54F` | `#FF8A65` | `#1A1010` |
| Frostmere | `#0D47A1` | `#B0BEC5` | `#CE93D8` | `#E3F2FD` | `#0A1929` |
| Shimmerdeep | `#00BCD4` | `#7C4DFF` | `#ECEFF1` | `#B2EBF2` | `#1A0A2E` |
| Voidmaw | `#1A237E` | `#4A148C` | `#009688` | `#B388FF` | `#0D0D1A` |

#### Rarity Colors
| Rarity | Hex | Glow |
|--------|-----|------|
| Common | `#B0BEC5` | None |
| Uncommon | `#66BB6A` | Subtle |
| Rare | `#42A5F5` | Moderate |
| Epic | `#AB47BC` | Strong |
| Legendary | `#FFA726` | Pulsing + particle trail |

### 14.3 UI Philosophy

- **Botanical framing**: UI panels have organic edges — vine borders, leaf corners, root-like dividers
- **Translucent glass**: Panels use frosted glass transparency over the scene beneath
- **Minimal chrome**: No heavy metal frames or sci-fi elements. Everything feels grown, not built
- **Color-coded everything**: Elements, rarities, factions, and status effects all have consistent color language
- **Readable at distance**: All icons and text must be legible at 1280×720 on a 13" screen

### 14.4 Animation Priorities

| Priority | System | Style |
|----------|--------|-------|
| 1 (Highest) | Seed growth stages | Lush, organic, mesmerizing. The showcase animation. |
| 2 | Loot collection | Satisfying cascade, rarity glow, particle pops |
| 3 | Dungeon room reveal | "Unfolding" animation as rooms connect on the map |
| 4 | Expedition combat | Simple but readable: swing, cast, hit-flash, KO dissolve |
| 5 | Adventurer idle | Personality-driven idle anims (Warrior polishes sword, Mage reads) |
| 6 | Menu transitions | Smooth slides, botanical flourish wipes |

### 14.5 VFX Language

| Effect | Style | Color |
|--------|-------|-------|
| Growth/bloom | Radial particle burst + screen-space glow | Element color |
| Loot drop | Star sparkle + gravity cascade | Rarity color |
| Mutation apply | Vein-spread overlay + shimmer | Reagent color |
| Combat hit | Impact flash + number popup | White flash + damage color |
| Healing | Rising green motes | `#66BB6A` |
| Status effect | Persistent icon + body tint | Status color |
| Level up | Radial light ring + chime | Gold `#F4D03F` |
| Boss entrance | Screen darken + spotlight + title card | Biome accent |

### 14.6 Resolution Targets

| Platform | Primary Resolution | Scaling |
|----------|-------------------|---------|
| PC | 1920×1080 | Up to 3840×2160 (4K) |
| PC (min) | 1280×720 | Minimum supported |
| Mobile | 1080×1920 (portrait) or 1920×1080 (landscape) | Auto-scale |
| Web | 1280×720 embedded | Responsive container |

---

## 15. Audio Direction

### 15.1 Music Identity

**Genre**: Ambient orchestral-electronic hybrid. Think **Austin Wintory** (Journey) meets **Lena Raine** (Celeste) meets **C418** (Minecraft). Organic instruments layered with soft synthesizers. Never aggressive, always inviting.

#### Music Per Context

| Context | Instruments | Mood | BPM | Key |
|---------|-------------|------|-----|-----|
| Seed Grove (idle) | Harp, piano, synth pads, nature ambience | Calm, meditative, hopeful | 70-80 | C major / A minor |
| Seed Grove (active) | Add light percussion, pizzicato strings | Engaged, focused | 90-100 | D major |
| Expedition (explore) | Biome instruments (see below), light rhythm | Curious, tense | 100-110 | Varies by biome |
| Expedition (combat) | Drums, brass stabs, tension strings | Intense, exciting | 120-130 | Minor key |
| Boss encounter | Full orchestra + choir synths, phase transitions | Epic, desperate | 130-140 | Biome minor |
| Victory fanfare | Brass + chimes, 3-second sting | Triumphant, satisfying | N/A | Major resolution |
| Loot collection | Cascading arpeggios, sparkle SFX | Rewarding, playful | N/A | Major |
| Menu/inventory | Soft ambient pads | Relaxed, non-intrusive | 60-70 | Neutral |

#### Biome-Specific Instruments

| Biome | Primary Instrument | Secondary | Texture |
|-------|-------------------|-----------|---------|
| Verdant Hollow | Wooden flute | Acoustic guitar | Birdsong samples |
| Embervault | French horn | Anvil percussion | Crackling fire |
| Frostmere | Celesta/glockenspiel | Glass harmonica | Wind howl |
| Shimmerdeep | Synthesizer arpeggios | Theremin | Crystalline pads |
| Voidmaw | Reversed piano | Low brass drones | Whispered voices |

### 15.2 Adaptive Music System

Music transitions are seamless. Never hard-cut.

```
SEED GROVE (calm)
    │
    ├──→ [Player dispatches expedition] ──→ CROSSFADE (2s) ──→ EXPEDITION (explore)
    │
    ├──→ [Combat room entered] ──→ LAYER ADD (drums + tension) ──→ EXPEDITION (combat)
    │
    ├──→ [Combat room cleared] ──→ LAYER REMOVE (drums fade 1.5s) ──→ EXPEDITION (explore)
    │
    ├──→ [Boss room entered] ──→ CROSSFADE (1s) ──→ BOSS THEME
    │
    ├──→ [Boss defeated] ──→ VICTORY STING (3s) ──→ CROSSFADE ──→ EXPEDITION (explore)
    │
    └──→ [Expedition complete] ──→ CROSSFADE (2s) ──→ SEED GROVE (calm)
```

### 15.3 Sound Effects Design Language

**Core Principle**: Organic and magical, NOT mechanical or sci-fi. Every sound should feel like it comes from a living garden, not a factory.

| Category | Sound Character | Examples |
|----------|----------------|---------|
| Seed planting | Soft earth, crystal chime | Soil crunch + bell tone |
| Seed growth tick | Organic stretch, root creak | Wood creak + sparkle |
| Bloom completion | Floral burst, triumphant chime | Petals unfurling + major chord |
| Mutation applied | Chemical bubble, energy shift | Liquid pour + electric hum |
| Expedition dispatch | Marching feet, adventure horn | Boot stomps + short horn call |
| Combat hit | Impact + element | Sword clang / fire crackle / ice shatter |
| Loot pickup | Satisfying plink, rarity-scaled | Higher pitch + more sparkle for rarer items |
| Level up | Ascending tone, golden ring | Rising arpeggio + bell |
| UI button click | Soft leaf rustle or stone tap | Tactile but gentle |
| Error/can't do | Low wooden thud | Dull bonk |

### 15.4 Silence Philosophy

**Silence is a design tool, not a bug.** The Seed Grove should have moments of near-silence — just wind, distant birdsong, the gentle pulse of growing seeds. After an intense boss fight, the silence of the loot screen is EARNED relief. Between expeditions, the quiet of the garden says "breathe, plan, tend."

**Rules**:
- Never layer more than 3 audio sources simultaneously (music + ambience + SFX)
- Allow 2-4 seconds of ambient-only audio between musical phrases in the grove
- Boss theme silence gap before Phase 3 (dramatic tension)
- No audio on menu hover (only on click/select)

### 15.5 Audio Priority Stack

When multiple sounds compete, this priority determines what plays:

```
[Highest Priority]
1. Critical alerts (expedition fail, adventurer KO)
2. Growth completion / Bloom chime
3. Combat SFX (hits, abilities)
4. Loot collection cascade
5. UI interaction feedback
6. Ambient biome sounds
7. Background music
[Lowest Priority]
```

Lower priority sounds duck (reduce volume) when higher-priority sounds play. Maximum 6 simultaneous audio channels.

---

## 16. UI/UX Design

### 16.1 Seed Grove Main Screen (ASCII HUD)

```
┌──────────────────────────────────────────────────────────────┐
│  🌱 DUNGEON SEED                    🪙 12,450  ✨ 890  🔷 56 │
│  Seedwarden Lv 14                                            │
│  ═══════════════════════════════════════════════════════════  │
│                                                              │
│  ┌──────────────────────────────────────────────────┐        │
│  │                                                  │        │
│  │              ╭───╮     ╭───╮     ╭───╮          │        │
│  │              │ 🌿│     │ 🔥│     │ ❄️ │          │        │
│  │              │BUD│     │SPR│     │BLM│          │        │
│  │              │72%│     │41%│     │✅ │          │        │
│  │              ╰───╯     ╰───╯     ╰───╯          │        │
│  │                                                  │        │
│  │         ╭───╮                    ╭───╮           │        │
│  │         │ ✨ │     [PEDESTAL]    │ 🌑│           │        │
│  │         │NEW│                    │SPO│           │        │
│  │         │   │                    │ 8%│           │        │
│  │         ╰───╯                    ╰───╯           │        │
│  │                                                  │        │
│  │              ╭───╮     ╭───╮     ╭───╮          │        │
│  │              │ 🔒│     │ 🔒│     │ 🔒│          │        │
│  │              │Lv │     │Lv │     │Lv │          │        │
│  │              │18 │     │22 │     │25 │          │        │
│  │              ╰───╯     ╰───╯     ╰───╯          │        │
│  │                                                  │        │
│  └──────────────────────────────────────────────────┘        │
│                                                              │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐    │
│  │ GROVE  │ │ HEROES │ │MUTARIUM│ │ VAULT  │ │DUNGEON │    │
│  │        │ │        │ │        │ │        │ │ BOARD  │    │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘    │
│                                                              │
│  [!] Frost Seed #3 has BLOOMED! Tap to dispatch.            │
└──────────────────────────────────────────────────────────────┘
```

### 16.2 Menu Flow Diagram

```
┌─────────────┐
│  TITLE      │
│  SCREEN     │
└──────┬──────┘
       │
       ├──→ [New Game] ──→ TUTORIAL ──→ SEED GROVE HUB
       │
       ├──→ [Continue] ──→ SEED GROVE HUB
       │
       └──→ [Settings] ──→ SETTINGS PANEL
                              ├── Audio
                              ├── Display
                              ├── Controls
                              ├── Accessibility
                              └── Account

SEED GROVE HUB (central navigation)
       │
       ├──→ [Tap Seed Plot] ──→ SEED DETAIL PANEL
       │                          ├── Growth progress
       │                          ├── Mutation slots
       │                          ├── Dungeon preview
       │                          └── [Dispatch] / [Apply Mutation]
       │
       ├──→ [Heroes Tab] ──→ ADVENTURER HALL
       │                      ├── Roster list
       │                      ├── [Select Hero] ──→ HERO DETAIL
       │                      │                      ├── Stats
       │                      │                      ├── Equipment
       │                      │                      ├── Skills
       │                      │                      └── [Equip] / [Train]
       │                      └── [Recruit] ──→ RECRUITMENT PANEL
       │
       ├──→ [Mutarium Tab] ──→ MUTARIUM ATELIER
       │                        ├── Reagent inventory
       │                        ├── Crafting recipes
       │                        └── [Craft Reagent]
       │
       ├──→ [Vault Tab] ──→ VAULT & MARKET
       │                     ├── Inventory (tabbed: Seeds/Gear/Materials/Artifacts)
       │                     ├── Crafting station
       │                     ├── Sell interface
       │                     └── Prestige shop (if available)
       │
       ├──→ [Dungeon Tab] ──→ DUNGEON BOARD
       │                       ├── Active expeditions (progress bars)
       │                       ├── Completed expeditions (collect loot)
       │                       └── Dungeon maps (tap to preview)
       │
       ├──→ [Quest Icon] ──→ QUEST LOG
       │                      ├── Daily quests
       │                      ├── Weekly quests
       │                      ├── Story quests
       │                      └── Faction quests
       │
       └──→ [Codex Icon] ──→ SEED CODEX
                               ├── Seed catalog (by element)
                               ├── Enemy bestiary
                               ├── Lore fragments
                               └── Completion tracker
```

### 16.3 Inventory Philosophy

- **Grid-based** with category tabs (Seeds, Reagents, Equipment, Materials, Artifacts)
- **Sort options**: By rarity, by element, by date acquired, by name
- **Quick actions**: Long-press for "Sell" or "Dismantle" — no buried menus
- **Stack display**: Materials show stack count. Equipment shows equipped icon.
- **Filter**: Filter by element, rarity, or "new/unseen"
- **Capacity**: Starts at 50 slots, expandable via upgrades (max 200)

### 16.4 Notification System

| Priority | Type | Presentation |
|----------|------|-------------|
| High | Seed Bloomed | Persistent toast + seed glow + chime |
| High | Expedition Complete | Persistent toast + Dungeon Board badge |
| Medium | Adventurer leveled up | Toast notification (auto-dismiss 5s) |
| Medium | Quest objective complete | Toast + Quest Log badge |
| Low | Idle resource cap reached | Subtle badge on Vault tab |
| Low | New Codex entry available | Codex icon dot |

**Toast Design**: Slim banner at top of screen, slides in from right, auto-dismisses after 5 seconds. High-priority toasts persist until tapped.

### 16.5 Mobile Adaptation

| PC Element | Mobile Adaptation |
|-----------|-------------------|
| Tab bar at bottom | Same — thumb-friendly |
| Right-click context menu | Long-press popup |
| Hover tooltips | Tap-and-hold tooltip |
| Keyboard shortcuts | N/A (gesture-based) |
| Mouse-precise drag | Snap-to-slot drag |
| Information panels | Slide-up bottom sheets |
| Seed grove zoom | Pinch-to-zoom |

### 16.6 Information Density

**LOW**. This is a chill game. Design for scan-ability, not information overload.

Rules:
- No screen should show more than 5 actionable items at once
- Use progressive disclosure: show summary first, detail on tap
- Color and iconography carry meaning — reduce text dependency
- Every panel should have clear "primary action" button (green/gold, largest button)
- Secondary actions are accessible but visually subordinate

---

## 17. Monetization Design

### 17.1 Business Model

**Free-to-Play** with ethical monetization. The game is free to download and play to completion. Revenue comes from optional cosmetics, convenience, and expansion content.

### 17.2 The Ethical Guardrails (Non-Negotiable)

These rules are INVIOLABLE. They are not suggestions — they are the foundation of player trust.

| Guardrail | Rule | Why |
|-----------|------|-----|
| 🚫 **No Pay-to-Win** | No purchasable item, seed, or boost that provides gameplay power unavailable through play | Trust. Players who pay should look cooler, not BE stronger. |
| 🚫 **No Exploitative Loot Boxes** | If any random element exists (e.g., cosmetic gacha), odds are published and a pity timer guarantees results | Transparency. Hidden odds are manipulation. |
| 🚫 **No Energy Gates** | Players can play as much as they want, whenever they want. No "5 lives per day" or stamina bars | Respect. The player's time is theirs. |
| 🚫 **No FOMO Manipulation** | Seasonal content returns in future rotations. Limited-time means "first available now," not "gone forever" | Ethics. Artificial scarcity preys on anxiety. |
| 🚫 **No Predatory Pricing** | No $99.99 bundles. No "first purchase" bait pricing. No manipulative currency conversion obscuring real cost | Honesty. Players should always know what they're paying. |
| 🚫 **No Children's Exploitation** | If audience includes minors: spending confirmations, parent-friendly settings, no gambling-adjacent mechanics | Duty. Children are not revenue targets. |

### 17.3 What IS Purchasable

| Category | Examples | Price Range |
|----------|---------|-------------|
| **Cosmetic Skins** | Adventurer outfits, seed glow colors, grove decorations | $1.99 - $4.99 |
| **UI Themes** | Custom panel styles, icon packs, font options | $1.99 - $2.99 |
| **Grove Cosmetics** | Decorative garden ornaments, pedestal styles, lighting effects | $0.99 - $3.99 |
| **Battle Pass** | Seasonal pass with cosmetic + convenience rewards | $4.99 / season |
| **Convenience** | Extra grove plots (also earnable), auto-harvest toggle, bulk dispatch | $0.99 - $2.99 |
| **Expansion DLC** | New biomes, story chapters, adventurer classes, seed families | $9.99 - $14.99 |
| **Supporter Bundle** | Cosmetic bundle + "Supporter" badge + thank-you letter from dev | $9.99 (one-time) |

### 17.4 What Is NEVER Purchasable

| Item | Why Not |
|------|---------|
| Seed rarity upgrades | Undermines the core progression loop |
| Adventurer stat boosts | Removes strategic challenge |
| Mutation potency boosts | Core system must remain skill/knowledge-gated |
| Loot quality multipliers | Pay-to-win in a loot game is unforgivable |
| Skip-to-Bloom time skips | The waiting IS the game — paying to skip it kills the idle loop |
| Competitive advantages | Leaderboards must reflect skill, not spending |

### 17.5 Battle Pass Structure

**Season length**: 8 weeks
**Tiers**: 30

| Track | Examples | Philosophy |
|-------|---------|-----------|
| **Free Track** (all players) | Gold, Essence, 2 cosmetic items, 1 unique seed (cosmetic variant), reagents | Meaningful. A non-paying player should never feel excluded. |
| **Premium Track** ($4.99) | 8 additional cosmetic items, 2 exclusive grove decorations, portrait frames, "Season X" badge | Bonus. Never gameplay-affecting. |

### 17.6 Premium Currency

**Dewdrops** (💧) — the premium currency.
- 100 Dewdrops = $0.99
- 550 Dewdrops = $4.99 (10% bonus)
- 1200 Dewdrops = $9.99 (20% bonus)

**Conversion is ALWAYS transparent**: Every item shows BOTH its Dewdrop price AND the real-money equivalent. No obfuscation.

### 17.7 Revenue Projections (Conservative)

| Metric | Target |
|--------|--------|
| DAU (6 months post-launch) | 5,000 - 15,000 |
| Conversion rate (free → any purchase) | 3-5% |
| ARPPU (average revenue per paying user) | $8-12/month |
| Battle pass attach rate | 8-12% of DAU |
| Monthly revenue estimate | $1,500 - $9,000 |
| Server cost per player | ~$0.02/month (minimal — mostly offline) |

*These are conservative indie F2P estimates. Dungeon Seed is designed to be profitable at low player counts.*

---

## 18. Endgame Design

### 18.1 The "Now What?" Problem

At max Seedwarden level (30), all biomes unlocked, all classes recruited — what keeps a player engaged? Dungeon Seed must have at least 3 compelling endgame activities available at all times.

### 18.2 Endgame Systems

#### 🌀 Abyssal Seeds (Infinite Scaling)

Abyssal Seeds are special endgame-only seeds that produce infinitely scaling dungeons:

- **Mechanic**: Abyssal Seeds don't have a fixed Bloom — they keep growing. The longer you wait, the harder and more rewarding the dungeon becomes.
- **Scaling**: Every hour of growth adds +1 dungeon tier. No cap.
- **Risk**: Higher tiers become genuinely dangerous. Party wipes are common.
- **Reward**: Exclusive Abyssal loot (cosmetics, prestige materials, leaderboard rankings)
- **Leaderboard**: "Deepest Abyss Cleared" — global ranking

```
ABYSSAL SEED GROWTH
  Hour 1: Tier 6 (Legendary difficulty)
  Hour 4: Tier 9 (brutal)
  Hour 12: Tier 15 (requires optimized builds)
  Hour 24: Tier 21 (only prestige-boosted players survive)
  Hour 72: Tier 45 (world first territory)
```

#### 🏆 Garden Mastery (Completionist)

- Complete Seed Codex: grow every seed variant across all elements and rarities
- Each completed element section grants permanent bonuses
- Full Codex completion unlocks the Mythic Seed recipe
- Mastery achievements with cosmetic rewards at 25%, 50%, 75%, 100%

#### �� Seasonal Trials (Time-Limited)

- Every 8 weeks, new Trial Seeds appear with unique mechanics:
  - "Thornbound Trial": All rooms have Root hazards, but triple Fragment drops
  - "Inferno Trial": Seed grows in 10 minutes but dungeon is maximum difficulty
  - "Eclipse Trial": Rooms alternate between Light and Dark phases — party must adapt
- Trial-exclusive cosmetics and seasonal leaderboard
- Trials RETURN in future seasons (no FOMO — see guardrails)

#### ⚡ Challenge Modes

| Challenge | Rules | Reward |
|-----------|-------|--------|
| **No-Mutation Run** | Clear a Legendary dungeon with zero mutations applied | "Purist" badge + cosmetic |
| **Solo Class** | Clear a dungeon with 4 adventurers of the same class | Class mastery badge |
| **Speed Clear** | Clear a dungeon under time threshold | Leaderboard ranking |
| **Pacifist** | Clear dungeon avoiding all Combat rooms (path planning!) | "Pacifist" badge |
| **Aberrant Gauntlet** | Chain 5 aberrant dungeons back-to-back, no rest between | Aberrant cosmetic set |

#### 🧬 Seed Breeding (Late-Endgame Crafting Sink)

Detailed in [Section 8.5](#85-seed-breeding-endgame). Breeding is the ultimate endgame crafting loop — consuming high-tier seeds to produce unique hybrids with properties unavailable any other way.

#### 🔄 Garden Cycle (Prestige)

Detailed in [Section 6.5](#65-prestige-system--garden-cycle). Each prestige cycle grants permanent bonuses and cosmetic prestige rewards (grove appearance evolves with each cycle).

#### 🏅 Community Challenges (Weekly)

- Global challenges with collective goals
- "Community grew 50,000 seeds this week!" → Everyone gets bonus Essence
- Individual contribution leaderboard
- Rotating challenge types (most seeds planted, fastest clear, rarest loot found)

### 18.3 The Rule of Three

**At any point in the endgame, the player must have at least 3 compelling activities:**

| Time Available | Activity 1 | Activity 2 | Activity 3 |
|---------------|-----------|-----------|-----------|
| 5 minutes | Check Abyssal Seed growth | Collect seasonal trial loot | Complete a challenge mode |
| 30 minutes | Full Abyssal expedition | Seed breeding experiment | Weekly community goal push |
| 2+ hours | Deep Codex completion push | Multi-trial seasonal chain | Prestige cycle progression |

---

## 19. Retention & Live Ops

### 19.1 Daily Loop

| Action | Reward | Time |
|--------|--------|------|
| Login bonus (escalating) | Day 1: 50G, Day 7: 200G + 50E, Day 30: Rare Seed | Instant |
| Harvest idle gains | Accumulated Gold, Essence, completed expeditions | 30 sec |
| Plant daily seed (free Common from quest board) | A free Common seed to plant | 30 sec |
| Complete 3 daily quests | 100 Seedwarden XP + 100G + 30E each | 5-10 min |
| Check Abyssal Seed progress | Decide: dispatch now or let it grow? | 1 min |

### 19.2 Weekly Loop

| Action | Reward | Time |
|--------|--------|------|
| Weekly challenge dungeon (unique modifier) | Rare reagents + Fragments | 15-30 min |
| Community goal contribution | Shared milestone rewards | Ongoing |
| Craft a significant item (weekly pacing) | Equipment upgrade or reagent | 5 min |
| Advance faction reputation (1 quest per week) | Faction rewards + lore | 10-20 min |

### 19.3 Monthly Loop

| Action | Reward | Time |
|--------|--------|------|
| Seasonal seed rotation (new Trial Seeds) | Exclusive trial cosmetics + loot | Hours |
| New story chapter (if available) | Narrative progression + unique rewards | 30-60 min |
| Battle pass tier completion | Cosmetic rewards | Ongoing |
| Community event (themed week) | Event currency + cosmetics | Ongoing |

### 19.4 Re-Engagement Strategy

**"Your seeds have grown!"** — the wholesome re-engagement notification.

| Absence | Notification (24hr+ after last play) | Tone |
|---------|--------------------------------------|------|
| 1 day | "Your seeds have grown while you were away! Come harvest." | Warm, inviting |
| 3 days | "The garden misses you. Your seeds are ready to bloom." | Gentle, no guilt |
| 7 days | "Welcome back! We saved your idle rewards. Catch-up bonus active." | Supportive |
| 30 days | "The grove has been quiet. A rare seed awaits your return." | Gift, no pressure |

**Rules**:
- Maximum 1 notification per 24 hours
- Player can disable ALL notifications in settings
- Notifications are NEVER: "You're falling behind!" or "Your friends are ahead!"
- Tone is always: "Something nice is waiting" — never: "You're missing out"

### 19.5 Cohort Health Targets

| Metric | Target | Healthy Range |
|--------|--------|---------------|
| D1 retention | 40% | 35-50% |
| D7 retention | 20% | 15-25% |
| D30 retention | 10% | 8-15% |
| D90 retention | 5% | 3-8% |
| Avg session length (post-onboard) | 12-18 min | 8-25 min |
| Sessions per day | 2-3 | 1-5 |
| DAU/MAU ratio | 20-30% | 15-35% |

### 19.6 Lapsed Player Recovery

| System | Mechanic |
|--------|----------|
| **Catch-up bonus** | Returning after 7+ days: next 3 dungeons yield 2× loot |
| **Accelerated growth** | Returning: next 3 seeds grow at 1.5× speed |
| **"What you missed" summary** | Quick recap of what grew, what's ready, what's new |
| **Seasonal try-before-commit** | Trial Seeds available to returning players with no barrier |

---

## 20. Onboarding & Tutorial

### 20.1 The First 60 Seconds — THE HOOK

```
0:00  Black screen. Faint green pulse.
0:05  Text fades in: "The seeds remember."
0:10  Camera pulls back — overgrown Seed Grove ruins revealed.
0:15  Focus on a single glowing seed on a mossy pedestal.
0:18  Prompt appears: "Plant it." (single button)
0:20  Player taps. Seed sinks into soil. Beat of silence.
0:23  RUMBLE. Ground cracks. Roots erupt. Camera shakes.
0:25  DUNGEON GROWTH ANIMATION (8 seconds of pure spectacle)
      — Rooms unfold like petals
      — Corridors stretch like vines
      — Stone and crystal form in real-time
      — Magical energy cascades outward
0:33  Dungeon stands complete. Breathe.
0:35  Grove Caretaker awakens: "You planted one. After all this time."
0:40  Caretaker: "The garden remembers you, Seedwarden."
0:45  First tutorial prompt appears: "Your seed has sprouted a dungeon.
      Let's send someone to explore it."
0:60  Player dispatches first adventurer. Tutorial begins.
```

**What this accomplishes**:
- Visual spectacle → "This game looks ALIVE"
- Player agency → "I caused this!"
- Mystery → "What are these seeds? Who am I?"
- Gameplay promise → "I'll be growing dungeons"
- Emotional resonance → "The garden remembers ME"

### 20.2 First 5 Minutes — Learn the Rhythm

| Time | What Happens | System Taught |
|------|-------------|---------------|
| 0:00-1:00 | The Hook (above) | Planting |
| 1:00-1:30 | Dispatch first adventurer (pre-made Warrior) | Expedition dispatch |
| 1:30-2:30 | Watch 3-room mini-dungeon clear (accelerated) | Expedition watching |
| 2:30-3:00 | Collect loot (Gold + first Fragment) | Loot collection |
| 3:00-3:30 | Caretaker: "Plant another." Second seed given (Flame) | Elemental system introduced |
| 3:30-4:00 | Recruit second adventurer (Ranger) from Adventurer Hall | Recruitment |
| 4:00-4:30 | While waiting for seed to grow, equip Fragment as gear | Equipment system |
| 4:30-5:00 | Second seed reaches Sprout → can do early harvest! | Growth stages + early harvest |

**Teaching Philosophy**: NEVER pause gameplay for a text wall. All instructions are:
- Short tooltip prompts (1-2 sentences) anchored to the relevant UI element
- Dismissable with a single tap
- Supported by visual highlighting (glow around clickable element)
- The player DOES the thing, then understands it

### 20.3 First 30 Minutes — Systems Unlock

| Time | Unlock | Teaching Method |
|------|--------|-----------------|
| ~5 min | Mutation slot | Caretaker gives first reagent: "Try applying this to your growing seed." Player sees dungeon map change. |
| ~8 min | Third adventurer class (Mage) | Quest reward: "A mage seeks to join your expedition." |
| ~12 min | Daily Quest Board | Board appears in grove: "New tasks await." Short list of 3 simple quests. |
| ~15 min | First Bloom! | Seed fully blooms — biggest growth animation yet. Tutorial: "Your dungeon is at full power. Dispatch a full team!" |
| ~18 min | 4-person party | Can now dispatch 4 adventurers at once. Synergy bonus explained via tooltip. |
| ~22 min | Crafting station | First crafting recipe auto-discovered. Simple: "3 Verdant Fragments → 1 Verdant Blade" |
| ~28 min | First Boss encounter | Thornmother in Verdant Hollow. Boss intro cinematic (10 sec). Multi-phase resolution. |
| ~30 min | Embervault biome teased | Post-boss reward includes an Ember Seed. Caretaker: "A seed from the deep vaults..." Curiosity hook. |

### 20.4 First 2 Hours — Full System Mastery

By hour 2, the player should understand:
- ✅ Planting and growth stages
- ✅ Mutation system (basic)
- ✅ Expedition dispatch and party composition
- ✅ Loot collection and equipment
- ✅ Basic crafting
- ✅ At least 4 adventurer classes
- ✅ Elemental advantages
- ✅ Idle accumulation ("seeds grew while you were exploring the crafting menu!")
- ✅ Daily quests

**NOT yet introduced** (progressive disclosure):
- ❌ Seed breeding (Lv 28) — player has heard of it from NPC hint only
- ❌ Prestige/Garden Cycle (Lv 30) — no mention yet
- ❌ Factions (Act 2) — not until mid-game
- ❌ Abyssal Seeds — endgame only
- ❌ Advanced mutation stacking — discovered through play

### 20.5 Veteran Skip

- After completing tutorial on one save, all subsequent saves offer "Skip Tutorial"
- Skip drops the player at Seedwarden Level 3 with:
  - 3 grove plots unlocked
  - Warrior + Ranger recruited
  - 500 Gold, 100 Essence
  - Basic crafting unlocked
  - All tutorial prompts disabled

---

## 21. Accessibility

### 21.1 Difficulty Modes

| Mode | Name | Growth Speed | Combat Difficulty | Target Audience |
|------|------|-------------|-------------------|-----------------|
| 🌱 | **Seedling** | 1.5× faster | -30% enemy stats | Casual players, narrative enjoyers |
| 🌿 | **Warden** | Normal | Normal | Standard experience |
| 🌲 | **Thornguard** | 0.75× slower | +30% enemy stats | Challenge seekers |
| ⚙️ | **Custom** | Player-set slider | Player-set slider | Min-maxers, accessibility needs |

**Custom Mode Sliders**:
- Growth speed: 50% - 200%
- Enemy HP: 50% - 200%
- Enemy damage: 50% - 200%
- Loot quality: 50% - 200% (up = easier gearing, not "free stuff")
- Auto-dispatch option: ON/OFF (game dispatches optimal party automatically)
- Auto-mutation: ON/OFF (game applies "recommended" mutations)

### 21.2 Visual Accessibility

| Feature | Default | Options |
|---------|---------|---------|
| **UI Scale** | 100% | 75%, 100%, 125%, 150%, 200% |
| **High Contrast Mode** | Off | ON: increases text contrast, adds outlines to UI elements, brighter backgrounds |
| **Colorblind Filters** | None | Deuteranopia, Protanopia, Tritanopia (shader-based) |
| **Rarity Indicators** | Color only | Color + shape (circle, diamond, star, hexagon, crown) |
| **Element Indicators** | Color + icon | Always includes unique icon shape per element |
| **Screen Shake** | On | Off / Reduced (50%) |
| **Particle Density** | Full | Full / Reduced (50%) / Minimal (10%) / Off |
| **Flashing Effects** | On | Off (all flashes replaced with sustained glow) |
| **Font** | Default | Default / Dyslexia-friendly (OpenDyslexic) / Large Sans-Serif |

### 21.3 Control Accessibility

| Feature | PC | Mobile | Console |
|---------|-----|--------|---------|
| Full remapping | ✅ | N/A | ✅ |
| One-handed mode | N/A | ✅ (all controls reachable with thumb) | N/A |
| Keyboard-only navigation | ✅ | N/A | N/A |
| Controller support | ✅ (xinput) | N/A | ✅ |
| Focus indicators | Clear visible focus ring on selected element | Touch highlight | Focus ring |
| Tap/click target size | N/A | ≥44×44px | N/A |
| Hold vs tap | All hold actions have tap alternative | Same | Same |

### 21.4 Audio Accessibility

| Feature | Default | Options |
|---------|---------|---------|
| Volume channels | Master, Music, SFX, Ambient, UI | Independent sliders |
| Visual audio cues | Off | ON: screen-edge flash for notifications, icon pulse for completion chimes |
| Subtitles/captions | On | Off, size options (S/M/L/XL) |
| Important SFX as text | Off | ON: "[BLOOM COMPLETE]", "[EXPEDITION RETURNED]" as text overlays |
| Screen reader hints | Basic | Enhanced: all UI elements have readable text labels |

### 21.5 Cognitive Accessibility

| Feature | Description |
|---------|-------------|
| **Auto-dispatch** | Game automatically selects optimal party for a dungeon (one-button dispatch) |
| **Recommended mutations** | UI highlights "suggested" reagent for each seed |
| **Quest objective markers** | Clear visual path from current state to quest goal |
| **Summary on return** | After idle time, a "What happened while you were away" summary panel |
| **Undo on mutations** | 5-second undo window after applying a mutation (in case of misclick) |
| **Simplified mode** | Hides advanced stats, shows only "Power Level" number for adventurers and dungeons |

---

## 22. Technical Direction

### 22.1 Engine & Language

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Engine | **Godot 4.x** | Open source, indie-friendly, GDScript is agent-automatable, isometric tilemap support built-in, multi-platform export |
| Language | **GDScript** | Tight engine integration, rapid iteration, AI agent-friendly syntax |
| Secondary | C# via Godot's .NET support | Only if performance-critical systems need it (unlikely for idle game) |

### 22.2 Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                     GODOT 4 PROJECT                          │
│                                                              │
│  AUTOLOAD SINGLETONS (always loaded):                        │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │ GameManager   │  │ SaveManager   │  │ AudioManager  │   │
│  │ (game state,  │  │ (persistence, │  │ (music, SFX,  │   │
│  │  time, ticks) │  │  cloud sync)  │  │  adaptive)    │   │
│  └───────────────┘  └───────────────┘  └───────────────┘   │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │ SeedManager   │  │ ExpeditionMgr │  │ LootManager   │   │
│  │ (seed CRUD,   │  │ (dispatch,    │  │ (loot tables, │   │
│  │  growth tick) │  │  simulation)  │  │  drops, RNG)  │   │
│  └───────────────┘  └───────────────┘  └───────────────┘   │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │ AdventurerMgr │  │ EconomyMgr   │  │ QuestManager  │   │
│  │ (roster, XP,  │  │ (currencies, │  │ (objectives,  │   │
│  │  equipment)   │  │  transactions)│  │  tracking)    │   │
│  └───────────────┘  └───────────────┘  └───────────────┘   │
│                                                              │
│  SCENE TREE:                                                 │
│  ├── MainScene (UI root)                                     │
│  │   ├── SeedGroveView (hub scene)                          │
│  │   ├── AdventurerHallView                                 │
│  │   ├── MutariumView                                       │
│  │   ├── VaultView                                          │
│  │   ├── DungeonBoardView                                   │
│  │   ├── ExpeditionView (active dungeon watch)              │
│  │   ├── CodexView                                          │
│  │   └── SettingsView                                       │
│  └── OverlayLayer (toasts, modals, tooltips)                │
│                                                              │
│  DATA LAYER (JSON/Resource files):                           │
│  ├── data/seeds/          (seed definitions)                 │
│  ├── data/enemies/        (enemy stat blocks)                │
│  ├── data/loot_tables/    (drop rate tables)                 │
│  ├── data/mutations/      (reagent definitions)              │
│  ├── data/equipment/      (gear database)                    │
│  ├── data/quests/         (quest definitions)                │
│  └── data/biomes/         (biome configs)                    │
└──────────────────────────────────────────────────────────────┘
```

### 22.3 Core Technical Systems

#### Procedural Generation Engine

```
DungeonGenerator:
  Input: SeedData (seed_id, element, rarity, mutations[], growth_stage)
  Output: DungeonGraph (rooms[], connections[], enemy_spawns[], loot_tables[])
  
  Algorithm: Seeded PCG (Permuted Congruential Generator)
  Determinism: Same input ALWAYS produces same output
  Performance: Generate 30-room dungeon in < 50ms
  Validation: Every graph is validated for:
    - Traversability (path from start to boss exists)
    - Room count matches specification
    - Enemy tier matches dungeon tier
    - Loot tables are properly weighted
```

#### Idle Tick System

```
IdleTickManager:
  Tick Rate: 1/second when app is foreground
  Background: Calculates elapsed time on return, applies accumulated progress
  
  Per Tick:
    - For each planted seed: advance growth_progress by growth_rate * dt
    - For each active expedition: advance room progress if idle mode
    - Accumulate passive Gold/Essence from grove upgrades
  
  On Return (after background):
    - elapsed = current_time - last_tick_time
    - For each seed: growth_progress += growth_rate * elapsed
    - Check for stage transitions (Spore → Sprout → Bud → Bloom)
    - For each idle expedition: simulate room clears for elapsed time
    - Cap idle rewards at 8 hours (diminishing returns after)
    - Queue notifications for completed events
```

#### Save System

```
SaveManager:
  Format: JSON (human-readable, debuggable)
  Location: user://saves/slot_{n}.json
  Backup: user://saves/slot_{n}_backup.json (previous save)
  
  Save triggers:
    - Auto-save every 60 seconds
    - On significant action (seed planted, expedition complete, purchase)
    - On app close/minimize
  
  Schema versioning:
    - Each save has a "version" field
    - Migration functions handle version upgrades
    - Backwards-compatible: old saves always loadable
  
  Save data includes:
    - seedwarden_level, xp
    - seeds[] (all planted + inventory)
    - adventurers[] (roster, stats, equipment)
    - inventory (currencies, materials, equipment)
    - quest_state
    - codex_progress
    - settings
    - last_tick_timestamp (for idle calculation)
    - prestige_data
```

### 22.4 Performance Targets

| Metric | Target | Platform |
|--------|--------|----------|
| Frame rate | 60fps steady | PC (mid-range) |
| Frame rate | 30fps steady | Mobile (mid-range) |
| Scene transition | < 2 seconds | All platforms |
| Dungeon generation | < 100ms | All platforms |
| Save/load | < 500ms | All platforms |
| Cold start to playable | < 5 seconds | PC |
| Cold start to playable | < 8 seconds | Mobile |
| Memory usage | < 512MB | PC |
| Memory usage | < 256MB | Mobile |
| Idle tick CPU usage | < 1% (background) | All platforms |
| APK/build size | < 100MB (base) | Mobile |

### 22.5 Data-Driven Design

ALL game balance data lives in JSON/Resource files, NOT hardcoded in scripts:

| Data File | Contents |
|-----------|----------|
| `seeds.json` | All seed definitions (base stats, growth times, element, room capacity) |
| `enemies.json` | Enemy stat blocks (HP, ATK, DEF, SPD, abilities, element, tier) |
| `loot_tables.json` | Drop rates per room type, tier, and mutation modifier |
| `mutations.json` | Reagent definitions (effects, costs, conflicts) |
| `equipment.json` | Gear database (stats, set bonuses, crafting recipes) |
| `adventurers.json` | Class definitions (base stats, growth rates, abilities) |
| `quests.json` | Quest definitions (objectives, rewards, prerequisites) |
| `biomes.json` | Biome configs (enemy pools, resource types, hazards, color palettes) |
| `economy.json` | Pricing, costs, upgrade paths, inflation parameters |
| `xp_curves.json` | Level-up requirements for Seedwarden and adventurers |

**Why**: AI agents can modify balance by editing JSON files without touching code. Designers can tune without recompiling. A/B testing is trivial.

### 22.6 Testing Strategy

| Test Type | Tool | Coverage |
|-----------|------|----------|
| Unit tests | GdUnit4 | Core systems (damage calc, growth, RNG, economy) |
| Integration tests | GdUnit4 | Full expedition simulation, save/load round-trip |
| Seed validation | Custom script | Generate 10,000 seeds, verify all produce valid dungeons |
| Balance testing | Python Monte Carlo | Simulate 1000 player-hours, check economy health |
| UI testing | Manual + screenshot comparison | All screens at all resolutions |
| Performance profiling | Godot profiler | Frame time, memory, draw calls |

---

## 23. Platform Strategy

### 23.1 Platform Matrix

| Platform | Priority | Control Scheme | Resolution | Distribution | Notes |
|----------|----------|---------------|------------|--------------|-------|
| **Windows** | P0 (launch) | Mouse + keyboard, gamepad | 1280×720 to 3840×2160 | Steam, itch.io | Primary dev target |
| **Linux** | P0 (launch) | Mouse + keyboard, gamepad | Same as Windows | Steam, itch.io | Godot exports natively |
| **macOS** | P1 (launch) | Mouse + keyboard | Same as Windows | Steam, itch.io | Notarization required |
| **Web** | P1 (launch demo) | Mouse + keyboard | 1280×720 embedded | itch.io, Newgrounds | Demo/trial only at launch |
| **Android** | P2 (+3-6 months) | Touch (portrait or landscape) | 720p-1080p | Google Play | Adapted UI, shorter sessions |
| **iOS** | P2 (+3-6 months) | Touch | 750p-1242p | App Store | Adapted UI, review process |
| **Switch** | P3 (stretch, +12mo) | JoyCon + touchscreen | 720p (handheld) / 1080p (docked) | eShop | Cozy aesthetic fits perfectly |

### 23.2 Per-Platform Control Schemes

#### PC (Mouse + Keyboard)
| Action | Mouse | Keyboard |
|--------|-------|----------|
| Select seed/adventurer | Left click | Tab cycle + Enter |
| Open context menu | Right click | Spacebar |
| Navigate tabs | Click tab | 1-5 number keys |
| Apply mutation | Drag reagent to seed | Select reagent + Enter on seed |
| Dispatch party | Click "Dispatch" button | D key |
| Scroll inventory | Mouse wheel | Arrow keys |
| Quick settings | — | Esc |

#### Mobile (Touch)
| Action | Gesture |
|--------|---------|
| Select | Tap |
| Context menu | Long press |
| Navigate tabs | Bottom tab bar tap or swipe |
| Apply mutation | Drag and drop (with snap) |
| Dispatch party | Tap "Dispatch" button |
| Scroll | Swipe |
| Zoom grove | Pinch |
| Quick info | Tap and hold (tooltip) |

### 23.3 Store Strategy

#### Steam
- **Launch**: Full game, free-to-play listing
- **Storepage**: Capsule art, trailer (growth animation showcase), screenshots
- **Tags**: RPG, Idle, Strategy, Management, Procedural, Indie
- **Steam achievements**: Mapped 1:1 from in-game achievement system
- **Steam Cloud**: Save sync across PC platforms
- **Workshop**: Future — community seed configs, cosmetic mods

#### itch.io
- **Launch**: Free web demo + downloadable full game
- **Purpose**: Indie discovery, community building, early feedback
- **Pricing**: "Name your price" with $0 minimum

#### Mobile Stores
- **Launch**: Phase 2 (3-6 months post-PC)
- **Pricing**: Free-to-play (same model as PC)
- **IAP integration**: Platform-native billing APIs
- **Review process**: Plan 2-4 week review buffer for App Store
- **Play Store**: Open beta → graduated launch

### 23.4 Cross-Save (Future)

- Phase 2 goal: save sync between PC ↔ mobile
- Implementation: Cloud save via player account (optional, not required)
- Conflict resolution: Most recent save wins (with manual override option)
- NO cross-play (single-player game) — only cross-save

### 23.5 Certification Considerations

| Platform | Key Requirements |
|----------|-----------------|
| Steam | Steamworks SDK integration, achievements API, cloud save API, controller support recommended |
| App Store | App Review Guidelines compliance, no "other store" links, IAP through Apple billing only |
| Google Play | Target API level compliance, billing library, content rating questionnaire |
| Switch | TRC compliance (lengthy), performance certification (30fps minimum), physical media consideration |

---

## 24. Competitive Analysis

### 24.1 Comparable Titles

#### 1. Dungeon Keeper (Bullfrog, 1997)

| Aspect | Analysis |
|--------|----------|
| **What they do WELL** | Pioneered the "you ARE the dungeon" fantasy. Building rooms, attracting monsters, defending against heroes. Incredible personality and humor. Dark comedy tone. |
| **What they do POORLY** | Real-time strategy pressure can be stressful. No idle component. Linear campaign with limited replayability. Dated UI and controls. |
| **How WE differentiate** | We keep the "dungeon management" fantasy but replace combat stress with idle patience. Seeds replace room-digging. Expeditions replace hero defense. Our game is CHILL where DK is frantic. |
| **Player sentiment** | "I loved building my dungeon but hated the endgame rushes." "Wish it was more about the building and less about the fighting." |

#### 2. Idle Champions of the Forgotten Realms (Codename Entertainment, 2017)

| Aspect | Analysis |
|--------|----------|
| **What they do WELL** | Deep idle RPG progression. Huge roster of champions. Formation strategy adds tactical depth. D&D license provides rich lore. |
| **What they do POORLY** | Overwhelming complexity for new players. Heavily monetized (pay-for-champions, chests). Feels like a progression treadmill more than a game. Formation meta gets solved. |
| **How WE differentiate** | We front-load the creative act (growing dungeons) over the passive one (watching heroes fight). Our monetization is cosmetic-only. Our complexity is opt-in (mutations) not forced. |
| **Player sentiment** | "I liked it for a week then hit a wall." "Too many currencies." "Fun to optimize but no soul." |

#### 3. Slay the Spire (Mega Crit Games, 2019)

| Aspect | Analysis |
|--------|----------|
| **What they do WELL** | Masterclass in procedural run variety. Every run feels different. Decision-making is constant and meaningful. Clean UI. Mod support extends life infinitely. |
| **What they do POORLY** | No persistence between runs (by design, but some players want long-term progression). Intense — requires full attention. No idle or passive play option. |
| **How WE differentiate** | We provide long-term persistence (your garden grows across sessions). We offer idle play for when you can't give full attention. We add the creative element of dungeon cultivation. |
| **Player sentiment** | "Best roguelike ever but I wish my progress carried over." "I play this when I can focus; I want something for when I can't." |

#### 4. Melvor Idle (Games by Malcs, 2021)

| Aspect | Analysis |
|--------|----------|
| **What they do WELL** | Incredibly deep idle RPG. RuneScape-inspired skill system. Massive content depth. Offline progression is excellent. Premium model (buy once). |
| **What they do POORLY** | UI is functional but uninspiring. No visual spectacle — mostly menus and numbers. The world feels abstract. No moment of "wow." |
| **How WE differentiate** | We bring VISUAL LIFE to the idle RPG. Seed growth animations, dungeon reveals, expedition watching. Our game has SPECTACLE where Melvor has spreadsheets. Same depth, better presentation. |
| **Player sentiment** | "Love the depth, wish it looked better." "Great game but feels like homework sometimes." "Best idle game on mobile." |

#### 5. Loop Hero (Four Quarters, 2021)

| Aspect | Analysis |
|--------|----------|
| **What they do WELL** | Brilliant genre innovation. Building the world your hero traverses. Indirect control creates fascinating tension. Gorgeous pixel art. Strong narrative mystery. |
| **What they do POORLY** | Run-based with limited persistence. Runs can feel same-y after many loops. Building meta gets optimized. No idle component — requires attention. |
| **How WE differentiate** | We extend the "build the world" concept with persistent garden management. Our seeds grow while you're away. Our dungeons have more variety (5 biomes × mutations). We add team composition depth that Loop Hero lacks. |
| **Player sentiment** | "Loved it for 20 hours then put it down." "Wish there was more to do between runs." "The concept is better than the execution long-term." |

#### 6. Hades (Supergiant Games, 2020)

| Aspect | Analysis |
|--------|----------|
| **What they do WELL** | Perfect run-based game loop. Narrative persistence across deaths. Incredible combat feel. Art and music are industry-leading. |
| **What they do POORLY** | Skill-intensive — not accessible to all players. No idle play. Endgame can feel repetitive once story concludes. Pure action — no management layer. |
| **How WE differentiate** | We serve the audience that loves the IDEA of dungeon-crawling but wants to manage it rather than play it. Our adventurers do the fighting; you do the strategy. Lower skill floor, similar depth ceiling. |
| **Player sentiment** | "Best roguelike ever." "I loved the story but hit a skill ceiling." "Wish I could keep playing but I'm not good enough for the hard content." |

#### 7. Stardew Valley (ConcernedApe, 2016)

| Aspect | Analysis |
|--------|----------|
| **What they do WELL** | The gold standard for "satisfying growth loop." Plant → tend → harvest → reinvest. Incredible emotional attachment. Deep enough for 1000+ hours. |
| **What they do POORLY** | Action combat in the mines is the weakest system. Real-time pressure of daily/seasonal deadlines can stress players. No idle component — must actively play. |
| **How WE differentiate** | We take Stardew's satisfying growth loop and apply it to DUNGEONS instead of crops. We add idle pacing (no daily deadline pressure). We replace Stardew's weakest system (mines combat) with our strongest (expedition strategy). |
| **Player sentiment** | "Most relaxing game ever but the mines stress me out." "I could garden all day." "Wish more games had this loop." |

#### 8. Teamfight Tactics / Auto Chess (Riot Games / Valve, 2019)

| Aspect | Analysis |
|--------|----------|
| **What they do WELL** | Party composition depth. Watching your team fight without direct control. Synergy system drives strategy. Meta constantly evolves. |
| **What they do POORLY** | PvP pressure and ranked anxiety. Matches are commitment (30-40 min). No PvE chill mode. Knowledge barrier is steep. |
| **How WE differentiate** | We take the auto-battle team composition depth into a PvE, chill, idle-friendly context. No opponents, no anxiety. Same satisfaction of "I built the perfect team" without the stress of competing. |
| **Player sentiment** | "Love the strategy but hate the pressure." "I want TFT but against AI." "Wish I could play casually without tanking my rank." |

### 24.2 The Competitive Positioning Statement

> **Dungeon Seed exists because no one has combined dungeon cultivation with idle management while delivering strategic expedition dispatch and deep seed genetics — all in a chill, no-pressure, ethically monetized package.**

The gap in the market:
- **Idle games** have depth but lack visual life and creative agency
- **Dungeon managers** have the fantasy but require stressful real-time play
- **Roguelikes** have procedural variety but no persistent world
- **Farming games** have the satisfying growth loop but not the combat depth
- **Auto-battlers** have the team composition strategy but competitive pressure

Dungeon Seed sits at the intersection of ALL of these — a cozy, deep, idle-friendly dungeon garden where YOU grow the dungeons and YOUR heroes harvest them.

---

## 25. Risk Analysis & Open Questions

### 25.1 Design Risks

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| **Idle loop feels too passive** | High | Medium | Add active micro-decisions: mutation timing, early harvest gambles, party swaps mid-expedition. Keep player agency high even during "waiting." |
| **Procedural dungeons feel repetitive** | High | Medium | Invest in diverse room templates (100+ at launch). Biome-specific mechanics. Mutation system ensures variety. Track "recently seen" rooms and deprioritize. |
| **Growth timers feel punishing** | High | Low | Timers are tuned for "come back later, not tomorrow." Common seeds bloom in 30min, not 24hr. Players should always have something to do NOW. |
| **Party composition becomes "solved"** | Medium | Medium | Regular balance patches. Seasonal modifiers that shift the meta. Biome-specific advantages prevent one-comp-fits-all. |
| **Mutation system is too complex** | Medium | Low | UI highlights "recommended" mutations. Simple mutations available early, complex ones are endgame. No penalty for "wrong" choice — just suboptimal. |

### 25.2 Balance Nightmares

| System | Why It's Hard | Prevention Strategy |
|--------|-------------|-------------------|
| **Idle vs active reward parity** | If idle gives too much, active feels pointless. If too little, idle feels broken. | Target: idle = 40% of active. Adjust via JSON config. A/B test with early players. |
| **Seed growth timers** | Too fast → no anticipation. Too slow → frustration. | Common seeds bloom during a single active session. Epic/Legendary are designed for overnight/multi-day. |
| **Mutation power curves** | Stacking 3 powerful mutations could trivialize content. | Multiplicative stacking has diminishing returns. Cap total mutation power at 2.5× base. |
| **Economy inflation** | Gold accumulates faster than sinks can consume. | Multiple sinks per currency. Prestige resets currencies. Diminishing idle returns. Monitor via analytics. |
| **Adventurer level scaling** | Over-leveled adventurers trivialize all content. | Dungeon difficulty scales with seed tier, not party level. Over-leveling helps, but doesn't eliminate challenge. |

### 25.3 Technical Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Procedural gen produces unplayable dungeons** | High | Validation pass on every generated dungeon. Fallback to known-good template if validation fails. Test with 10,000+ random seeds in CI. |
| **Save corruption** | High | Backup save on every write. Version migration system. Atomic writes (write to temp, rename). |
| **Mobile performance** | Medium | Profile early, optimize idle tick. Reduce particle density on mobile. Test on low-end devices. |
| **Deterministic RNG drift** | Medium | Use PCG algorithm. Test same seed across platforms. Include RNG state in save files for debugging. |
| **Background timer cheating** | Low | Server-timestamp validation for leaderboards. Local play allows time manipulation (intentional — it's single-player, who cares). |

### 25.4 Market Risks

| Risk | Assessment | Response |
|------|-----------|----------|
| **Idle game market saturation** | Real, but most idle games lack visual polish and creative agency | Differentiate on SPECTACLE (growth animations) and AGENCY (you design the dungeon) |
| **RPG-idle hybrid confuses players** | Moderate risk | Clear storepage messaging: "Grow dungeons. Send heroes. Harvest loot." Three-word loop. |
| **F2P stigma** | Some PC players avoid F2P | Offer premium "Supporter Edition" option. Free tier is the FULL game. Premium is cosmetics. |
| **Solo indie scope risk** | One developer, ambitious design | MVP first: 2 biomes, 4 classes, core loop. Expand post-launch based on traction. |

### 25.5 Scope Creep Triggers

| Feature | Creep Risk | Control |
|---------|-----------|---------|
| **Seed breeding** | High — genetics systems can expand endlessly | Limit to simple combination rules at launch. No Mendelian genetics. |
| **More biomes** | Medium — each biome is 2-4 weeks of content | MVP: 3 biomes. Full launch: 5. Post-launch DLC for more. |
| **Adventurer skill trees** | Medium — easy to add "one more branch" | 2 branches per class, locked at launch. Expansion DLC can add third branch. |
| **Social features** | High — multiplayer always expands | MVP: seed sharing codes only. Everything else is post-launch. |
| **Narrative depth** | Medium — lore is addictive to write | Cap at 3-act structure. Side quests capped at 5 per biome. |

### 25.6 Open Questions (For the Developer)

These are genuinely ambiguous creative/business decisions that the GDD author cannot answer — they depend on the developer's vision, resources, and priorities.

| # | Question | Options | Recommendation |
|---|----------|---------|----------------|
| 1 | **Should expeditions be fully auto-resolved or have minimal player input?** | A) Pure auto-battle (watch or idle) B) Choose path at forks C) Trigger special abilities manually | **Recommend A for MVP**, expand to B post-launch. Idle players want auto; active players want agency. Support both. |
| 2 | **Should there be a hard cap on simultaneous active dungeons?** | A) Cap at grove plot count (3-8) B) Unlimited dungeons, limited adventurers C) Soft cap via resource cost | **Recommend A.** Grove plots = dungeon cap. Clean, visual, upgradeable. |
| 3 | **PvP aspirations or purely PvE?** | A) Pure PvE forever B) PvP arena post-launch C) Indirect competition (leaderboards only) | **Recommend C.** Leaderboards provide competition without the toxicity and balance burden of direct PvP. |
| 4 | **Narrative depth: light flavor text or full quest system?** | A) Minimal — item descriptions and barks only B) Quest system with dialogue choices C) Full branching narrative with multiple endings | **Recommend B for MVP, C for full launch.** The 3-act structure in this GDD assumes option C. Scale back to B if scope demands it. |
| 5 | **Should seed breeding be in MVP or post-launch?** | A) MVP (risky, adds complexity) B) Post-launch expansion (safer) C) Never (keep it simple) | **Recommend B.** Breeding is an endgame feature. Launch without it, add when players hit endgame. |
| 6 | **Premium ($9.99) or Free-to-Play?** | A) F2P with cosmetic monetization B) Premium ($9.99) with no IAP C) Premium ($4.99) + optional DLC | **GDD assumes A.** But if the developer is uncomfortable with F2P, option C is equally viable for indie scale. |
| 7 | **What is the MVP content scope?** | A) 2 biomes, 4 classes, no mutations B) 3 biomes, 6 classes, basic mutations C) Full 5 biomes, 6 classes, all systems | **Recommend B.** Enough content for 20+ hours. Polish over breadth. |

---

---

## Appendices

### Appendix A: Full Elemental Advantage Matrix

Damage multipliers when ATTACKER element hits DEFENDER element:

```
                         D E F E N D E R
                 ┌────────┬────────┬────────┬────────┬────────┐
                 │ TERRA  │ FLAME  │ FROST  │ ARCANE │ SHADOW │
    ┌────────────┼────────┼────────┼────────┼────────┼────────┤
    │   TERRA    │  1.00  │  0.75  │  1.50  │  1.00  │  1.00  │
    ├────────────┼────────┼────────┼────────┼────────┼────────┤
A   │   FLAME    │  1.50  │  1.00  │  0.75  │  1.00  │  1.00  │
T   ├────────────┼────────┼────────┼────────┼────────┼────────┤
T   │   FROST    │  0.75  │  1.50  │  1.00  │  1.00  │  1.00  │
A   ├────────────┼────────┼────────┼────────┼────────┼────────┤
C   │   ARCANE   │  1.00  │  1.00  │  1.00  │  1.00  │  1.50  │
K   ├────────────┼────────┼────────┼────────┼────────┼────────┤
E   │   SHADOW   │  1.00  │  1.00  │  1.00  │  0.75  │  1.00  │
R   └────────────┴────────┴────────┴────────┴────────┴────────┘

Advantage Ring:
  Terra → Frost → Flame → Terra  (physical cycle)
  Arcane → Shadow → Arcane       (metaphysical cycle)

Multipliers:
  Advantage:    ×1.50 (+50% damage)
  Neutral:      ×1.00 (no modifier)
  Disadvantage: ×0.75 (-25% damage)
```

### Appendix B: Complete Seed Catalog (Base Types)

#### Terra Seeds

| Seed Name | Rarity | Growth (Total) | Rooms | Loot Bias | Special |
|-----------|--------|---------------|-------|-----------|---------|
| Mossclad Spore | Common | 51m | 6-8 | Fragments | Introductory seed |
| Stoneheart Kernel | Uncommon | 1h 42m | 8-12 | Gold | Extra Combat rooms |
| Crystal Root | Rare | 8h 35m | 12-16 | Fragments | Guaranteed Puzzle room |
| Titan's Bulb | Epic | 34h 15m | 16-22 | Balanced | 2 Boss rooms |
| Worldtree Seed | Legendary | 105h | 22-30 | Artifacts | Secret rooms guaranteed |

#### Flame Seeds

| Seed Name | Rarity | Growth (Total) | Rooms | Loot Bias | Special |
|-----------|--------|---------------|-------|-----------|---------|
| Ember Pip | Common | 51m | 6-8 | Gold | Fast growth (+10%) |
| Scorchbloom | Uncommon | 1h 42m | 8-12 | Gold | Extra Treasure rooms |
| Magma Heart | Rare | 8h 35m | 12-16 | Fragments | Environmental fire hazards |
| Furnace Core | Epic | 34h 15m | 16-22 | Fragments | Reinforced Combat rooms |
| Phoenix Seed | Legendary | 105h | 22-30 | Artifacts | Resurrection mechanic (party revives once) |

#### Frost Seeds

| Seed Name | Rarity | Growth (Total) | Rooms | Loot Bias | Special |
|-----------|--------|---------------|-------|-----------|---------|
| Frost Mote | Common | 51m | 6-8 | Essence | Slow enemies (-10% SPD) |
| Glacial Pip | Uncommon | 1h 42m | 8-12 | Essence | Extra Rest rooms |
| Rime Bulb | Rare | 8h 35m | 12-16 | Essence | Freeze traps (strategic) |
| Permafrost Core | Epic | 34h 15m | 16-22 | Balanced | Ice armor on enemies (+DEF) |
| Absolute Zero Seed | Legendary | 105h | 22-30 | Artifacts | Time-freeze rooms (double action turns) |

#### Arcane Seeds

| Seed Name | Rarity | Growth (Total) | Rooms | Loot Bias | Special |
|-----------|--------|---------------|-------|-----------|---------|
| Glyph Spore | Common | 51m | 6-8 | Essence | Extra Puzzle rooms |
| Prism Shard | Uncommon | 1h 42m | 8-12 | Essence | +15% rare drop rate |
| Ether Bloom | Rare | 8h 35m | 12-16 | Balanced | Phase rooms (randomized layout) |
| Nexus Core | Epic | 34h 15m | 16-22 | Essence | Arcane constructs (unique enemies) |
| Infinity Seed | Legendary | 105h | 22-30 | Artifacts | Recursive rooms (same room repeats with scaling difficulty) |

#### Shadow Seeds

| Seed Name | Rarity | Growth (Total) | Rooms | Loot Bias | Special |
|-----------|--------|---------------|-------|-----------|---------|
| Shade Pip | Common | 51m | 6-8 | Fragments | Ambush rooms (enemies attack first) |
| Dusk Bloom | Uncommon | 1h 42m | 8-12 | Fragments | +10% secret room chance |
| Nightshard | Rare | 8h 35m | 12-16 | Fragments | Curse rooms (risk/reward) |
| Abyss Core | Epic | 34h 15m | 16-22 | Balanced | Dimensional instability |
| Void Heart Seed | Legendary | 105h | 22-30 | Artifacts | Reality tear rooms (unique mechanics) |

**Total base seed catalog**: 25 seeds (5 per element × 5 rarities)
**With variants and seasonal**: 50+ at launch, 100+ by year 1

### Appendix C: Biome Enemy Roster Summary

| Biome | Tier Range | Enemy Count | Boss |
|-------|-----------|------------|------|
| Verdant Hollow | 1-3 | 6 (Thornling, Moss Golem, Vine Snare, Crystal Slime, Hollow Stag, Root Wisp) | Thornmother |
| Embervault | 2-3 | 6 (Cinder Imp, Slag Brute, Magma Crawler, Furnace Construct, Ember Wraith, Soot Lurker) | Molten Sentinel |
| Frostmere | 3-4 | 6 (Frost Sprite, Glacial Hound, Ice Warden, Frozen Revenant, Rime Caster, Permafrost Golem) | Glaciarch |
| Shimmerdeep | 3-5 | 6 (Shimmer Sprite, Glyph Guardian, Prism Shard, Arcane Automaton, Ether Weaver, Phase Stalker) | Prism Weaver |
| Voidmaw | 4-5 | 6 (Shade, Void Lurker, Hollow One, Nightmare Wisp, Abyssal Construct, Entropy Weaver) | The Hollow King |

**Total unique enemies**: 30 + 5 bosses = 35 unique enemy types at launch

### Appendix D: Currency Flow Diagram (Detailed)

```
                    ┌─────────────┐
        ┌──────────→│  DUNGEON    │←───── Seeds consumed
        │           │  RUNS       │        (faucet origin)
        │           └──────┬──────┘
        │                  │
        │     ┌────────────┼────────────┬───────────┐
        │     ▼            ▼            ▼           ▼
        │  ┌──────┐  ┌──────────┐  ┌────────┐  ┌──────────┐
        │  │ GOLD │  │ ESSENCE  │  │FRAGMNT │  │ARTIFACTS │
        │  │  🪙  │  │    ✨    │  │   🔷   │  │    ⭐    │
        │  └──┬───┘  └────┬─────┘  └───┬────┘  └────┬─────┘
        │     │            │            │            │
        │     ▼            ▼            ▼            ▼
        │  ┌──────────────────────────────────────────────┐
        │  │              S I N K S                        │
        │  │                                              │
        │  │  Gold →  Recruitment, Equipment, Grove plots, │
        │  │          Repairs, Supply costs                │
        │  │                                              │
        │  │  Essence → Fertilizers, Reagent crafting,     │
        │  │            Seed crafting, Breeding costs       │
        │  │                                              │
        │  │  Fragments → Gear crafting, Upgrades,         │
        │  │              Artifact forging                  │
        │  │                                              │
        │  │  Artifacts → Permanent upgrades, Prestige     │
        │  │              shop, Endgame recipes             │
        │  └──────────────────────────────────────────────┘
        │                  │
        │                  │ Upgraded adventurers +
        │                  │ better equipment +
        │                  │ mutated seeds
        │                  ▼
        └────────── BETTER DUNGEON RUNS ──────→ cycle
```

### Appendix E: XP and Level Curve Data

#### Seedwarden Level Curve

| Level | XP to Next | Cumulative XP | Est. Hours |
|-------|-----------|---------------|-----------|
| 1 | 100 | 0 | 0 |
| 2 | 303 | 100 | 0.25 |
| 3 | 569 | 403 | 0.5 |
| 4 | 884 | 972 | 0.75 |
| 5 | 1,240 | 1,856 | 1.0 |
| 6 | 1,631 | 3,096 | 1.5 |
| 7 | 2,053 | 4,727 | 2.0 |
| 8 | 2,502 | 6,780 | 2.5 |
| 9 | 2,976 | 9,282 | 3.0 |
| 10 | 3,471 | 12,258 | 3.5 |
| 12 | 4,521 | 19,250 | 5.0 |
| 15 | 6,235 | 34,811 | 8.0 |
| 18 | 8,131 | 56,420 | 14.0 |
| 20 | 9,591 | 73,900 | 20.0 |
| 22 | 11,148 | 94,631 | 27.0 |
| 25 | 13,572 | 131,250 | 38.0 |
| 28 | 16,172 | 175,714 | 50.0 |
| 30 | 18,040 | 210,500 | 60.0 |

*Formula: `XP_next = floor(100 * level^1.6)`*

#### Adventurer Level Curve

| Level | XP to Next | Tier | Notes |
|-------|-----------|------|-------|
| 1 | 80 | Novice | Starting |
| 2 | 226 | Novice | |
| 3 | 392 | Novice | First skill unlock |
| 4 | 571 | Novice | |
| 5 | 760 | Skilled | Tier promotion, ability 2 |
| 8 | 1,317 | Skilled | Passive 2 unlock |
| 10 | 1,768 | Veteran | Tier promotion, ability 3 |
| 13 | 2,639 | Veteran | |
| 15 | 3,227 | Elite | Tier promotion, capstone |
| 18 | 4,240 | Elite | |
| 20 | 4,965 | Elite (max) | Level cap |

*Formula: `XP_next = floor(80 * level^1.5)`*

### Appendix F: Feature Priority Matrix (MoSCoW)

#### Must Have (MVP — Ship Blockers)

| Feature | Estimated Effort |
|---------|-----------------|
| Seed planting and growth system (4 stages) | 2 weeks |
| Deterministic dungeon generation from seeds | 3 weeks |
| Expedition dispatch and auto-resolution | 2 weeks |
| 3 adventurer classes (Warrior, Mage, Ranger) | 1 week |
| Basic loot system (Gold, Fragments, equipment) | 2 weeks |
| 3 biomes (Verdant, Embervault, Frostmere) | 3 weeks |
| Core UI: Grove, Adventurer Hall, Dungeon Board | 3 weeks |
| Save/load system | 1 week |
| Idle accumulation (growth continues offline) | 1 week |
| Tutorial / onboarding (first 30 min) | 1 week |
| Settings menu (audio, display, accessibility basics) | 0.5 weeks |

**MVP Total: ~19.5 weeks (~5 months)**

#### Should Have (Launch — Quality Gate)

| Feature | Estimated Effort |
|---------|-----------------|
| Remaining 3 classes (Rogue, Alchemist, Sentinel) | 1.5 weeks |
| Mutation system (basic: 5 reagent types) | 2 weeks |
| Remaining 2 biomes (Shimmerdeep, Voidmaw) | 2 weeks |
| Crafting system (basic recipes) | 1.5 weeks |
| Seed Codex | 1 week |
| Daily quest board | 1 week |
| Boss encounters (1 per biome) | 2 weeks |
| Faction system (basic reputation) | 1.5 weeks |
| Narrative Act 1 (discovery arc) | 1 week |
| Sound effects and music (5 biome tracks) | 2 weeks |
| Colorblind and accessibility options | 1 week |
| Steam integration (achievements, cloud save) | 1 week |

**Launch Total: ~18 weeks more (~4.5 months) = ~9.5 months cumulative**

#### Could Have (Post-Launch — Content Updates)

| Feature | Estimated Effort |
|---------|-----------------|
| Narrative Acts 2-3 | 3 weeks |
| Seed breeding system | 2 weeks |
| Prestige/Garden Cycle | 1.5 weeks |
| Seasonal trials | 2 weeks |
| Abyssal Seeds (infinite scaling) | 1.5 weeks |
| Battle pass system | 2 weeks |
| Cosmetic shop + premium currency | 1.5 weeks |
| Mobile port (UI adaptation) | 4 weeks |
| Seed sharing codes | 1 week |
| Leaderboards | 1 week |
| Advanced mutations (10+ reagent types) | 1.5 weeks |
| Community events system | 1.5 weeks |

#### Won't Have (Descoped / Future Consideration)

| Feature | Reason |
|---------|--------|
| Real-time multiplayer co-op | Scope explosion, requires server infrastructure |
| PvP arena | Balance nightmare, off-brand for cozy game |
| Voice acting | Budget constraint, localization complexity |
| 3D graphics | 2D/2.5D is the art style; 3D would change the game's identity |
| Console port (Switch) | Not until mobile is proven and revenue supports it |
| Guild gardens | Requires persistent online infrastructure |

### Appendix G: Downstream Agent Dependency Map

This GDD feeds directly into the following pipeline agents:

```
                          ┌──────────────┐
                          │   GDD v2.0   │
                          │  (this doc)  │
                          └──────┬───────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │  Narrative    │  │  Character   │  │    World     │
    │  Designer     │  │  Designer    │  │ Cartographer │
    │              │  │              │  │              │
    │ Consumes:    │  │ Consumes:    │  │ Consumes:    │
    │ §10 Narrative│  │ §11 Classes  │  │ §9 World     │
    │ §10 Factions │  │ §7 Combat    │  │ §9 Biomes    │
    │ §9 Biomes    │  │ §8 Seeds     │  │ §10 Lore     │
    └──────────────┘  └──────────────┘  └──────────────┘
              │                  │                  │
              ▼                  ▼                  ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │    Game      │  │  Art         │  │   Audio      │
    │  Economist   │  │  Director    │  │  Director    │
    │              │  │              │  │              │
    │ Consumes:    │  │ Consumes:    │  │ Consumes:    │
    │ §12 Economy  │  │ §14 Art Dir  │  │ §15 Audio    │
    │ §17 Monetize │  │ §16 UI/UX    │  │ §9 Biomes    │
    │ §6 Progress  │  │ §9 Biomes    │  │ §15 Adaptive │
    └──────────────┘  └──────────────┘  └──────────────┘
              │                  │                  │
              └──────────┬───────┴──────────────────┘
                         ▼
              ┌──────────────────┐
              │  The Decomposer  │
              │                  │
              │  Takes: Full GDD │
              │  Produces: 200+  │
              │  implementation  │
              │  tasks across 6  │
              │  parallel streams│
              └──────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │  Game Code       │
              │  Executor        │
              │                  │
              │ Consumes:        │
              │ §22 Tech Dir     │
              │ §3 Core Loop     │
              │ §7 Combat        │
              │ §8 Seeds         │
              │ All data schemas │
              └──────────────────┘
```

---

## Document Metadata

| Property | Value |
|----------|-------|
| Document | Game Design Document: Dungeon Seed |
| Version | 2.0 |
| Status | Complete Draft |
| Date | 2026-07-29 |
| Author | Game Vision Architect Agent |
| Word Count | ~18,000 |
| Sections | 25 + 7 Appendices |
| Supersedes | GDD v0.1 (2026-04-12) |
| Source | APPROVED-EPIC-BRIEF.md, DUNGEON-SEED-GDD.md, LORE-BIBLE.md |
| Next Action | Feed to Narrative Designer, Character Designer, World Cartographer, Game Economist, Art Director, Audio Director, and The Decomposer |

---

*"You literally grow the dungeon, then send heroes to harvest it. I've had it running in the background for three weeks and I can't stop."*

— The player review this game is designed to earn.
