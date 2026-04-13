# Game Design Document: Dungeon Seed

> **Status**: Draft
> **Version**: 0.1
> **Date**: 2026-04-12
> **Author**: Dungeon Seed Design Team
> **Epic**: Dungeon Seed

---

## 1. Overview

Dungeon Seed is an RPG/idle hybrid where players plant magical seeds that sprout into living, procedurally generated dungeons. Instead of exploring static halls, the player cultivates dungeon ecosystems, waits for them to mature, and then dispatches adventurers to clear rooms and harvest loot.

Players take on the role of a Seedwarden who balances growth, mutation, expedition planning, and reward optimization. The core progression loop is built around planting seeds, growing dungeons, sending heroes into those dungeons, and reinvesting loot into new seeds and stronger adventurers.

### Platform Targets
- **Primary**: PC
- **Secondary**: Mobile follow-up
- **Stretch**: Console

### Engine
- **Recommended**: Godot 4.x

### Core Player Promise
- I shape and tend living dungeons.
- I decide when they are ready and which heroes should explore them.
- I reap rare loot and use it to make the next season of growth stronger.

---

## 2. Core Gameplay Loops

### Micro Loop (30 seconds)
1. Inspect a seed or dungeon progress tile.
2. Apply a growth boost, mutation reagent, or speed-up resource.
3. Dispatch adventurers into a ready dungeon.
4. Watch rooms clear, loot appear, and resources accumulate.
5. Return to hub and spend rewards to upgrade seeds, equipment, or heroes.

### Meso Loop (5 minutes)
1. Plant new seeds and assign growth strategies.
2. Review active dungeons, harvest idle gains, and collect progress rewards.
3. Recruit or train adventurers for upcoming runs.
4. Send multiple teams into parallel dungeons.
5. Allocate loot to unlock new seeds, mutations, and equipment.

### Macro Loop (30+ minutes)
1. Advance through seed tiers and unlock new biomes.
2. Expand the Seed Grove and adventurer hall.
3. Discover mutation recipes and optimize growth cycles.
4. Complete seasonal objectives and challenge trials.
5. Repeat with more exotic seeds and richer loot rewards.

### Loop Summary
```
Plant Seed → Grow Dungeon → Monitor Progress → Dispatch Adventurers → Clear Rooms → Harvest Loot → Upgrade Seeds/Adventurers → Unlock New Seeds
```

---

## 3. Player Goals

### Short-Term Goals
- Plant the next available seed.
- Complete a dungeon run.
- Acquire a new loot type or crafting material.
- Unlock a new adventurer class.
- Use a limited booster to speed growth.

### Mid-Term Goals
- Build a rotation of dungeons that mature in staggered windows.
- Fully upgrade a seed mutation path.
- Assemble a specialist adventurer squad for high-value runs.
- Unlock a new dungeon biome.
- Establish a stable resource loop for crafting and upgrading.

### Long-Term Goals
- Master all seed archetypes and dungeon forms.
- Maximize adventurer levels and gear.
- Complete the highest-tier seasonal and challenge dungeons.
- Collect exotic loot, legendary items, and rare seed variants.
- Optimize the garden for continuous idle progression.

---

## 4. Systems Design

### 4.1 Seed System

Seeds are the primary progression assets. Each seed is alive and carries metadata that shapes the dungeon it grows into.

#### Seed Attributes
- **Rarity tier**: Common, Uncommon, Rare, Epic, Legendary.
- **Elemental affinity**: Terra, Flame, Frost, Arcane, Shadow.
- **Growth profile**: speed, density, mutation potential.
- **Base dungeon traits**: room variety, hazard frequency, loot bias.
- **Capacity**: total potential room count as it matures.
- **Maturation stages**: Spore, Sprout, Bud, Bloom.

#### Growth Mechanics
- Seeds mature over time while planted.
- Players may accelerate growth with boosters or reagents.
- Higher-tier seeds take longer to mature but yield richer dungeons.
- Growth can be paused, shifted, or rerouted with mutation reagents.

#### Mutation Mechanics
- Mutation reagents change dungeon composition and reward types.
- Each seed has mutation slots for modifiers such as:
  - increased treasure density,
  - more traps,
  - rarer artifact drops,
  - faster growth,
  - elemental reward bias.
- Mutations create trade-offs: improved quality vs increased risk, speed vs capacity.

### 4.2 Dungeon Generation

Dungeons are generated procedurally from seed metadata and mutation state. Each seed instance produces a consistent structure for a given growth path.

#### Generation Inputs
- Seed tier and affinity.
- Mutation configuration.
- Current maturity stage.
- Biome theme.
- Random variation seed.

#### Room Types
- **Combat Room**: enemy encounters, experience, and loot.
- **Treasure Room**: guaranteed rewards and crafting resources.
- **Trap Room**: damage or penalties unless countered.
- **Puzzle Room**: mini-challenges with bonus rewards.
- **Rest Room**: recovery and temporary buffs.
- **Boss Room**: high-value encounter at the end of a dungeon.

#### Structure
- Dungeons are represented as connected room graphs.
- Players choose a path through core and branching rooms.
- Difficulty and reward scale with room count and hazard density.
- Some rooms may require specific adventurer roles to unlock bonuses.

### 4.3 Adventurer System

Adventurers are the heroes the player assigns to clear dungeons.

#### Classes
- **Warrior**: tanky melee frontliner.
- **Ranger**: ranged damage and trap detection.
- **Mage**: area damage and elemental control.
- **Rogue**: evasion, critical strikes, and treasure bonuses.
- **Alchemist**: support damage over time and healing utility.
- **Sentinel**: party buffer and team durability.

#### Stats
- **Health**: durability.
- **Attack**: damage output.
- **Defense**: damage reduction.
- **Speed**: action order and traversal efficiency.
- **Utility**: special ability power.

#### Progression
- Adventurers earn XP from successful runs.
- Level tiers unlock abilities and equipment slots.
- Players can upgrade gear, unlock passive bonuses, and specialize roles.
- Synergy bonuses reward balanced party compositions.

### 4.4 Loot & Economy

Loot is the currency of progression and customization.

#### Reward Types
- **Gold**: used for base upgrades and recruitment.
- **Essence**: powers seed boosts, growth reagents, and mutation crafting.
- **Fragments**: crafting components for gear and artifacts.
- **Artifacts**: rare items granting permanent bonuses.
- **Relics**: unlock additional seed lore and seasonal rewards.

#### Economy Principles
- Idle rewards accumulate while players are away.
- Active runs provide bonus loot and higher-tier drops.
- Resources must be spent on upgrades, reagents, and new seed unlocks.
- The game avoids premium gating of core progression.

### 4.5 Growth Strategy

Players coordinate multiple seeds to create a staggered growth schedule.
- Fast seeds fill short-term needs.
- Slow high-tier seeds unlock richer rewards.
- Optimal play uses boosters and mutations to align dungeon readiness with adventurer availability.

### 4.6 Prestige & Mastery

Late-game systems keep the loop engaging.

#### Garden Mastery
- Collect full affinity sets and unlock bonuses.
- Earn passive growth speed, increased loot chance, or reduced reagent cost.

#### Endless Tiers
- Repeatable challenge dungeons with scaling difficulty.
- Offer high-end rewards and mastery milestones.

#### Seasonal Trials
- Timed seed variants with unique mechanics.
- Limited rewards encourage experimentation and replay.

---

## 5. Interface & Player Experience

### Hub Screens
- **Seed Grove**: main planting and growth view.
- **Dungeon Dashboard**: active dungeons, status bars, and ready-to-run alerts.
- **Adventurer Hall**: recruit, equip, level up heroes.
- **Mutarium Atelier**: manage reagents, mutations, and growth modifiers.
- **Vault**: inventory, crafting, and resource conversion.

### Interaction Model
- Click/tap to select seeds, adventurers, or dungeons.
- Drag to assign heroes into expedition slots.
- Context-sensitive panels display stats, bonuses, and tooltip explanations.
- Progress bars and timers show growth, cooldowns, and expedition duration.

### UX Principles
- Keep the player informed without overwhelming them.
- Use clear visual hierarchy for ready-to-run dungeons and urgent actions.
- Reward player actions with satisfying VFX and feedback.
- Make progression accessible with a gentle onboarding curve.

### Control Scheme
- **PC**: mouse-driven UI with optional keyboard shortcuts.
- **Mobile**: touch-friendly buttons, swipe tabs, and pinch-to-zoom hub views.
- **Console stretch**: controller navigation with clear focus indicators.

---

## 6. Progression & Balance

### Tiered Unlocks
- Unlock new seed tiers by spending resources and completing core dungeon runs.
- New biomes and room types appear as the player advances.
- Adventurer classes are introduced gradually with tutorial missions.

### Difficulty Curve
- Early game focuses on learning growth and dispatch mechanics.
- Mid game introduces mutations, party specialization, and higher room complexity.
- Late game challenges the player with risk/reward decisions and scarce premium resources.

### Balance Priorities
- Ensure each seed tier feels distinct and worthwhile.
- Avoid overpowered mutagens that trivialize earlier content.
- Make adventurer team choice meaningful for room bonuses.
- Design loot curves so players feel steady progression without runaway inflation.

---

## 7. Narrative & Worldbuilding

### Story Premise
A forgotten garden of living ruins has reawakened. As a Seedwarden, the player must cultivate ancient seeds, restore balance to the realm, and uncover the source of the returning dungeons.

### Key Themes
- Nature reclaiming ruin.
- Magic and decay entwined.
- The symbiosis of creation and exploration.
- Careful stewardship over raw power.

### Narrative Beats
- **Intro**: discover the Seed Grove and learn basic planting.
- **Growth**: unlock the first dungeon and send adventurers into the wild.
- **Mutation**: learn to shape dungeon destiny with reagents.
- **Challenge**: face seasonal trials and deeper secrets.
- **Mastery**: gather rare seeds, complete the garden, and unlock the highest-tier dungeons.

---

## 8. Audio & VFX Direction

### Music
- Ambient, mystical soundscapes in the Seed Grove.
- Tense, rhythmic themes during dungeon expeditions.
- Layered tracks that evolve with seed maturity and biome.

### Sound Design
- Soft chimes and growth hums when seeds progress.
- Combat impacts, spell flares, and loot chimes during runs.
- Distinct audio cues for ready dungeons, low health, and completed expeditions.

### Visual Effects
- Magical glow around growing seeds.
- Particle bursts for mutations and harvests.
- Clear telegraphing for traps, boss rooms, and special rewards.

---

## 9. Monetization & Retention (Design Guardrails)

### Monetization Philosophy
- Core gameplay remains fully playable without pay-to-win.
- Monetization may focus on convenience, cosmetics, and expansion content.
- Premium items should not break progression balance.

### Potential Revenue Paths
- Cosmetic seed skins or hub decorations.
- Quality-of-life boosters with soft limits.
- Expansion seeds, seasonal content, or battle pass-style progression.

### Retention Drivers
- Daily quests and planted seed streaks.
- Seasonal trials and rotating challenge seeds.
- Collection goals for seed affinities and adventurer mastery.

---

## 10. Accessibility & Quality

### Accessibility Goals
- Scalable text and UI sizes.
- High contrast UI mode.
- Clear iconography and colorblind-safe palettes.
- Optional reduced animation settings.

### Quality Goals
- Responsive UI and readable progression feedback.
- Smooth transitions between hub and expedition views.
- Stable save and resume behavior for idle progression.
- Clear tooltips and tutorial guidance.

---

## 11. Technical Considerations

### Core Tech
- Godot 4.x for cross-platform authoring.
- Scripted procedural generation for dungeon graphs.
- Data-driven seed and mutation definitions.
- Save system that persists seed growth, adventurer state, and inventory.

### Performance Targets
- Fast hub load and scene transitions.
- Efficient idle progression updates without heavy CPU use.
- Scalable dungeon simulation for multiple active expeditions.

### Risks
- Procedural generation may produce uninteresting or unfair dungeons if not tuned.
- Balancing seed growth, loot economy, and adventurer progression is complex.
- Idle and active reward pacing must feel satisfying for different player rhythms.

---

## 12. Open Questions
- Should dungeon runs be simulated entirely in the background or partially visualized?
- How many active dungeons can the player manage simultaneously in MVP?
- What is the best limit for premium boosters to avoid pay-to-win feelings?
- Will the game include explicit hero permadeath, or will adventurers always recover?
- Should seasonal trials be time-gated content or permanent challenge modes?
