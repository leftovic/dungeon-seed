# Game Design Document: Dungeon Seed

> **Status**: Draft
> **Version**: 0.1
> **Date**: 2026-04-12
> **Author**: Dungeon Seed Design Team
> **Epic**: Dungeon Seed

---

## 1. Overview

Dungeon Seed is a hybrid RPG/idle/progression game where players act as a mystical gardener of ruin and reward. Instead of exploring static dungeons, players cultivate magical seeds that sprout into living, procedurally generated dungeons. Over time, these dungeons mature, absorb ambient magic, and become suitable for adventurers to enter, clear rooms, and harvest loot.

The player is a Seedwarden who balances long-term growth, dungeon mutation strategies, and adventurer expedition planning. Success comes from constructing a cadence of dungeon growth and runs, unlocking more powerful seed types, and building a roster of specialist heroes.

### Platform Targets
- **Primary**: PC
- **Secondary**: Mobile follow-up
- **Stretch**: Console

### Engine
- **Godot 4.x**

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
4. Watch rooms clear, loot spawn, and resources accumulate.
5. Return to hub and spend rewards to upgrade seeds or characters.

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

Seeds are the primary progression pillars. Each seed is a living progression asset with:
- **Rarity tier**: Common, Uncommon, Rare, Epic, Legendary.
- **Elemental affinity**: Terra, Flame, Frost, Arcane, Shadow.
- **Growth profile**: speed, density, mutation potential.
- **Dungeon traits**: room variety, hazard frequency, loot bias.

#### Seed Properties
- **Growth Time**: seconds/minutes required to reach each maturity stage.
- **Dungeon Capacity**: number of rooms unlocked as the seed matures.
- **Mutation Slots**: available reagent slots for modifiers.
- **Loot Bias**: preferred drop types (crafting, gold, artifacts).

#### Seed Maturation
Seeds progress through phases:
1. **Spore**: freshly planted, limited dungeon structure.
2. **Sprout**: initial room count and basic enemies.
3. **Bud**: access to better rooms and loot.
4. **Bloom**: full dungeon size with high-value rewards.

Players can influence maturation with:
- **Boosters**: temporary speed increases.
- **Reagents**: seed mutagens that alter dungeon output.
- **Environmental conditions**: biome-specific bonuses.

### 4.2 Dungeon Generation

Dungeons are procedurally generated from seed data. Generation is deterministic per seed instance, allowing replay of known structures when desired.

#### Dungeon Parameters
- **Seed tier** determines base size and scaling.
- **Affinity** selects theme, hazard type, and enemy pool.
- **Mutation config** changes room distribution and rewards.
- **Growth phase** unlocks new room types.

#### Room Types
- **Combat Room**: standard enemy encounters.
- **Treasure Room**: guaranteed loot and resource pickups.
- **Trap Room**: hazards that require avoidance or remedy.
- **Puzzle Room**: simple mechanical challenges for bonus rewards.
- **Rest Room**: passive regeneration and minor buffs.
- **Boss/Anchor Room**: marks the dungeon’s key reward node.

Room composition is guided by seed traits:
- High density seeds yield more combat rooms.
- Treasure-focused seeds add more treasure and rest rooms.
- Arcane or shadow affinities increase hazard and puzzle content.

#### Dungeon Flow
- Dungeons are built as a connected graph of rooms.
- Players choose an entry, then a path of rooms to resolve.
- Exploration is semi-abstract: players send teams through rooms with results resolved per room.
- Completed runs grant loot and experience based on rooms cleared, damage taken, and objectives met.

### 4.3 Adventurer System

Adventurers are the active agents sent into dungeons.

#### Classes
- **Warrior**: high health and defense, excels in front-line combat.
- **Ranger**: ranged damage and trap detection.
- **Mage**: area damage and elemental control.
- **Rogue**: evasion, critical strikes, and treasure bonuses.
- **Alchemist**: support damage over time and potion utility.
- **Sentinel**: tank and party buffer.

#### Stats
- **Health**: durability in a run.
- **Attack**: raw damage.
- **Defense**: damage reduction.
- **Speed**: action order and room traversal efficiency.
- **Utility**: ability power for special effects.

#### Progression
- XP gained from dungeon runs.
- Level tiers: Novice, Skilled, Veteran, Elite.
- Unlockable abilities at thresholds.
- Equipment slots: weapon, armor, accessory.
- Class synergy bonuses for curated party compositions.

#### Roles
- **Scout**: reveals hazards, increases treasure chance.
- **Support**: buff/debuff specialist.
- **Carry**: high single-target damage.
- **Guardian**: protects the party.

### 4.4 Loot & Economy

Loot fuels both seed and adventurer progression.

#### Currency Types
- **Gold**: base currency for upgrades and hire costs.
- **Essence**: used for seed boosts and trait alterations.
- **Fragments**: crafting components for gear.
- **Artifacts**: rare items granting permanent bonuses.

#### Loot Rarity
- **Common**: basic crafting materials and gold.
- **Uncommon**: improved materials, low-tier gear.
- **Rare**: advanced components and class-specific items.
- **Epic**: powerful artifacts and gear.
- **Legendary**: unique rewards and seed modifiers.

#### Economy Rules
- Rewards scale with dungeon difficulty and seed maturity.
- Idle rewards accumulate while players are away, but active runs yield higher bonus returns.
- Upgrades and mutation reagents provide meaningful sinks.
- The system avoids pay-to-win by keeping progression gated by time, effort, and strategic choices rather than purchasable power spikes.

### 4.5 Mutation & Growth Strategy

Mutations provide a mid-to-late game optimization layer.

#### Mutation Paths
Example paths:
- **Blooming Spires**: more treasure rooms, fewer traps.
- **Ironheart Ruins**: denser combat, higher armor enemy rewards.
- **Etheric Labyrinth**: more arcane hazards, rare resource drops.

#### Trade-offs
Each mutation offers design trade-offs:
- Speed vs reward quality.
- Safety vs risk/reward.
- Loot specialization vs general utility.

#### Growth Strategy
Players manage a garden of seeds with staggered growth windows.
- Some seeds mature quickly with low rewards.
- Others require longer growth but yield richer dungeons.
- Proper timing allows continuous adventurer deployment with minimal downtime.

### 4.6 Prestige & Mastery

Late-game systems reward long-term engagement.

#### Garden Mastery
- Complete collections of seeds and elemental affinities.
- Earn bonuses for maintaining optimized growth cycles.

#### Endless Dungeon Tiers
- Repeatable runs with scaling difficulty and reward multipliers.
- Provide a high-end loop after the main seed tiers are unlocked.

#### Seasonal Trials
- Temporary seeds with unique challenge rules.
- Offer exclusive rewards and leaderboard-style mastery.

---

## 5. Interface & Player Experience

### Core Screens
- **Seed Grove**: planting beds, active dungeon progress, seed inventory.
- **Dungeon Board**: active dungeon status, room previews, expedition controls.
- **Adventurer Hall**: roster, recruitment, training, equipment.
- **Mutarium Atelier**: mutation crafting and reagent management.
- **Vault**: inventory, crafting, resource conversion.
- **Quest/Challenge Panel**: objectives, seasonal tasks, milestones.

### UX Principles
- Keep information clear and scannable.
- Use color and iconography to distinguish seed states, dungeon readiness, and loot rarity.
- Provide one-click actions for common routines (plant next seed, dispatch best squad).
- Offer clear feedback when growth completes or quests are ready.
- Avoid overwhelming new players with too many systems at once.

### Onboarding
- A short tutorial introduces:
  - planting the first seed,
  - watching growth,
  - dispatching a starter team,
  - collecting first loot,
  - investing in a second seed.
- Tutorial should demonstrate the unique seed-to-dungeon mechanic early.

### Accessibility
- Scalable UI text and high-contrast mode.
- Reduced-motion option for growth and menu animations.
- Clear audio/visual cues for important state changes.
- Button navigation should support mouse, keyboard, and touch.

---

## 6. World & Narrative

### Setting
The world contains a forgotten garden of ruin-seeds left by an ancient civilization. These seeds sprout dungeons instead of plants, and the magic within them can restore balance or corrupt the land if neglected.

### Player Role
The player is a Seedwarden: a caretaker of both the garden and the heroes it feeds. Their job is to coax dangerous dungeons into maturity, send expeditions, and use the recovered magic to rebuild the world.

### Story Beats
1. **Awakening**: discover the Seed Grove and plant the first seed.
2. **Exploration**: learn the rhythm of growth, runs, and resource loops.
3. **Discovery**: unlock new biomes and learn the lore of the ancient gardeners.
4. **Mastery**: mutate seeds strategically, optimize your garden, and tackle seasonal trials.
5. **Revelation**: uncover why the dungeons returned and what the seeds truly hunger for.

### Lore Themes
- Nature reclaimed by magic.
- Creation and decay as a cycle.
- Balance between nurture and danger.
- Growth as both a resource and a risk.

---

## 7. Art & Audio Direction

### Visual Style
- Stylized low-poly / painterly RPG aesthetics.
- Soft lighting, magical glows, and deliberate color themes.
- Character designs should feel charming and expressive.
- Dungeons should have coherent themes per affinity while preserving a handcrafted feel.

### Dungeon Biome Themes
- **Verdant Grotto**: moss, crystal pools, sunlit ruins.
- **Ember Hollow**: magma flows, rusted metal, glowing embers.
- **Frostspire Keep**: ice, frost sigils, frozen machinery.
- **Aetherium Ruins**: floating stones, arcane glyphs, ethereal light.
- **Nightshade Vault**: shadow, phosphorescence, spectral architecture.

### Audio
- **Music**: ambient orchestral-electronic hybrid with adaptive intensity.
- **Seed effects**: soft chimes, root whispers, growth pulses.
- **Dungeon ambience**: theme-specific loops that feel alive without fatigue.
- **Combat/action**: distinct SFX per class and hazard.
- **Loot feedback**: satisfying plings and chimes tied to rarity.

---

## 8. Success Metrics

### Design Success
- Players understand and enjoy the seed-to-dungeon loop.
- Progression feels meaningful without becoming grindy.
- Dungeon runs are rewarding even when done idly.
- Seed mutation choices feel strategic and impactful.

### Engagement Metrics
- Average session length after onboarding.
- Retention for return visits after idle progress.
- Number of planted seeds per session.
- Frequency of dungeon dispatches versus growth boost usage.

### Balance Metrics
- Resource spend versus reward pacing.
- Loot rarity match to upgrade demand.
- Adventurer survivability across dungeon tiers.
- Idle reward pickup versus active run reward ratio.

---

## 9. Implementation Notes

### Priority Systems
1. Seed growth and dungeon generation.
2. Adventurer roster and expedition mechanics.
3. Loot economy and upgrade loops.
4. UI flows for planting, dispatching, and reward collection.
5. Mutation and mastery systems for long-term retention.

### Risk Areas
- Procedural dungeon variety may feel repetitive without enough room types.
- Idle reward pacing can easily feel too slow or too fast.
- Seed mutation trade-offs must be clear and worth the player's investment.

### Future Extensions
- Multiplayer garden trading or co-op expeditions.
- Seasonal or timed event seeds.
- Guild-style challenge leaderboard system.
- Deeper story campaign mode beyond the seed garden.

---

## 10. References
- `neil-docs/epics/dungeon-seed/APPROVED-EPIC-BRIEF.md`
- `neil-docs/epics/dungeon-seed/DECOMPOSITION.md`
- `GAME-DEV-VISION.md`
