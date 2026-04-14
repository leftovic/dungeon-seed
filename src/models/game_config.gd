## Centralized balance-tuning constants for Dungeon Seed.
## All values are const — no runtime mutation. Change values here to rebalance the game.
## Every downstream system reads from GameConfig instead of hardcoding numbers.
##
## Usage: GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON] -> 60
## No instantiation needed — access via class_name static reference.
class_name GameConfig


# ===========================================================================
# §4.1 — Seed System Constants
# ===========================================================================

## Base growth time in seconds for each seed rarity tier.
## Higher rarity seeds take longer to grow, rewarding patience.
## GDD Reference: §4.1 (Seed System — Growth Timers)
const BASE_GROWTH_SECONDS: Dictionary = {
	Enums.SeedRarity.COMMON: 60,
	Enums.SeedRarity.UNCOMMON: 120,
	Enums.SeedRarity.RARE: 300,
	Enums.SeedRarity.EPIC: 600,
	Enums.SeedRarity.LEGENDARY: 1200,
}

## Number of mutation slots available per seed rarity.
## More slots = more trait combinations = more powerful dungeon seeds.
## GDD Reference: §4.1 (Seed System — Mutation Slots)
const MUTATION_SLOTS: Dictionary = {
	Enums.SeedRarity.COMMON: 1,
	Enums.SeedRarity.UNCOMMON: 2,
	Enums.SeedRarity.RARE: 3,
	Enums.SeedRarity.EPIC: 4,
	Enums.SeedRarity.LEGENDARY: 5,
}

## Growth speed multiplier per seed phase.
## Later phases grow faster, rewarding players who nurture seeds through early stages.
## Multiplier is applied as a scaling factor: higher multiplier = faster growth.
## Values >= 1.0, monotonically increasing through phases.
## GDD Reference: §4.1 (Seed System — Phase Progression)
const PHASE_GROWTH_MULTIPLIERS: Dictionary = {
	Enums.SeedPhase.SPORE: 1.0,
	Enums.SeedPhase.SPROUT: 1.5,
	Enums.SeedPhase.BUD: 2.0,
	Enums.SeedPhase.BLOOM: 3.0,
}

## Human-readable display names for each element.
## Used in UI tooltips, seed descriptions, and lore text.
## GDD Reference: §4.1 (Seed System — Elemental Affinity)
const ELEMENT_NAMES: Dictionary = {
	Enums.Element.TERRA: "Terra",
	Enums.Element.FLAME: "Flame",
	Enums.Element.FROST: "Frost",
	Enums.Element.ARCANE: "Arcane",
	Enums.Element.SHADOW: "Shadow",
	Enums.Element.NONE: "None",
}


# ===========================================================================
# §4.2 — Dungeon System Constants
# ===========================================================================

## Difficulty scaling factor per room type.
## Combat and Boss rooms are harder; Treasure and Rest rooms are easier.
## Applied as a multiplier to base enemy stats and reward calculations.
## GDD Reference: §4.2 (Dungeon Generation — Room Difficulty)
const ROOM_DIFFICULTY_SCALE: Dictionary = {
	Enums.RoomType.COMBAT: 1.0,
	Enums.RoomType.TREASURE: 0.5,
	Enums.RoomType.TRAP: 0.8,
	Enums.RoomType.PUZZLE: 0.6,
	Enums.RoomType.REST: 0.0,
	Enums.RoomType.BOSS: 2.0,
}


# ===========================================================================
# §4.3 — Adventurer System Constants
# ===========================================================================

## XP thresholds for each adventurer level tier.
## An adventurer advances to a tier when their cumulative XP >= the threshold.
## Values are monotonically increasing. NOVICE starts at 0 (immediate).
## GDD Reference: §4.3 (Adventurer System — Level Tiers)
const XP_PER_TIER: Dictionary = {
	Enums.LevelTier.NOVICE: 0,
	Enums.LevelTier.SKILLED: 100,
	Enums.LevelTier.VETERAN: 350,
	Enums.LevelTier.ELITE: 750,
}

## Exponential XP scaling parameters for adventurer leveling.
## Formula: xp_to_next_level = BASE_XP * pow(GROWTH_RATE, level - 1)
## GDD Reference: §4.3 (Adventurer System — XP Curve)
const XP_CURVE: Dictionary = {
	"BASE_XP": 100,
	"GROWTH_RATE": 1.15,
}

## Canonical stat key names for adventurer stat dictionaries.
## GDD Reference: §4.3 (Adventurer System — Stats)
const STAT_KEYS: Array[String] = ["health", "attack", "defense", "speed", "utility"]

## Canonical equipment slot key names.
## GDD Reference: §4.3 (Adventurer System — Equipment)
const EQUIP_SLOT_KEYS: Array[String] = ["weapon", "armor", "accessory"]

## Base stat blocks per adventurer class.
## Each class has 5 stats: health, attack, defense, speed, utility.
## These are starting values at Novice tier — scaling is applied by downstream systems.
## GDD Reference: §4.3 (Adventurer System — Class Stats)
const BASE_STATS: Dictionary = {
	Enums.AdventurerClass.WARRIOR: {
		"health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5,
	},
	Enums.AdventurerClass.RANGER: {
		"health": 85, "attack": 14, "defense": 10, "speed": 15, "utility": 10,
	},
	Enums.AdventurerClass.MAGE: {
		"health": 70, "attack": 12, "defense": 8, "speed": 10, "utility": 20,
	},
	Enums.AdventurerClass.ROGUE: {
		"health": 75, "attack": 16, "defense": 8, "speed": 18, "utility": 12,
	},
	Enums.AdventurerClass.ALCHEMIST: {
		"health": 80, "attack": 10, "defense": 12, "speed": 10, "utility": 18,
	},
	Enums.AdventurerClass.SENTINEL: {
		"health": 130, "attack": 10, "defense": 20, "speed": 6, "utility": 8,
	},
}


# ===========================================================================
# §4.4 — Loot & Economy Constants
# ===========================================================================

## Base currency earned per room clear, before modifiers.
## These define the primary economic faucet rate.
## ARTIFACTS earn 0 at base — they are boss-only or event drops.
## GDD Reference: §4.4 (Loot & Economy — Currency Earn Rates)
const CURRENCY_EARN_RATES: Dictionary = {
	Enums.Currency.GOLD: 10,
	Enums.Currency.ESSENCE: 2,
	Enums.Currency.FRAGMENTS: 1,
	Enums.Currency.ARTIFACTS: 0,
}

## UI display colors per rarity tier (used for item names, borders, particles).
## Colors are designed for readability on dark backgrounds.
## GDD Reference: §4.4 (Loot & Economy — Rarity Visual Identity)
const RARITY_COLORS: Dictionary = {
	Enums.SeedRarity.COMMON: Color(0.78, 0.78, 0.78),
	Enums.SeedRarity.UNCOMMON: Color(0.18, 0.80, 0.25),
	Enums.SeedRarity.RARE: Color(0.25, 0.52, 0.96),
	Enums.SeedRarity.EPIC: Color(0.64, 0.21, 0.93),
	Enums.SeedRarity.LEGENDARY: Color(0.95, 0.77, 0.06),
}


# ===========================================================================
# Helper Methods
# ===========================================================================

## Returns the base stat dictionary for a given adventurer class.
## Returns a copy to prevent accidental mutation of the const source.
## Example: GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
##   -> { "health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5 }
static func get_base_stats(cls: Enums.AdventurerClass) -> Dictionary:
	if BASE_STATS.has(cls):
		return BASE_STATS[cls].duplicate()
	push_warning("Unknown AdventurerClass value: %d" % cls)
	return {}


## Returns the growth time in seconds for a given seed rarity.
## Example: GameConfig.get_growth_seconds(Enums.SeedRarity.RARE) -> 300
static func get_growth_seconds(rarity: Enums.SeedRarity) -> int:
	if BASE_GROWTH_SECONDS.has(rarity):
		return BASE_GROWTH_SECONDS[rarity]
	push_warning("Unknown SeedRarity value: %d" % rarity)
	return 0


## Returns the number of mutation slots for a given seed rarity.
## Example: GameConfig.get_mutation_slots(Enums.SeedRarity.EPIC) -> 4
static func get_mutation_slots(rarity: Enums.SeedRarity) -> int:
	if MUTATION_SLOTS.has(rarity):
		return MUTATION_SLOTS[rarity]
	push_warning("Unknown SeedRarity value: %d" % rarity)
	return 0


## Returns the XP threshold required to reach a given level tier.
## Example: GameConfig.get_xp_for_tier(Enums.LevelTier.VETERAN) -> 350
static func get_xp_for_tier(tier: Enums.LevelTier) -> int:
	if XP_PER_TIER.has(tier):
		return XP_PER_TIER[tier]
	push_warning("Unknown LevelTier value: %d" % tier)
	return 0


## Returns the UI display color for a given seed/item rarity.
## Example: GameConfig.get_rarity_color(Enums.SeedRarity.LEGENDARY) -> Color(0.95, 0.77, 0.06)
static func get_rarity_color(rarity: Enums.SeedRarity) -> Color:
	if RARITY_COLORS.has(rarity):
		return RARITY_COLORS[rarity]
	push_warning("Unknown SeedRarity value: %d" % rarity)
	return Color.WHITE


## Returns the room difficulty scale factor for a given room type.
## Example: GameConfig.get_room_difficulty(Enums.RoomType.BOSS) -> 2.0
static func get_room_difficulty(room_type: Enums.RoomType) -> float:
	if ROOM_DIFFICULTY_SCALE.has(room_type):
		return ROOM_DIFFICULTY_SCALE[room_type]
	push_warning("Unknown RoomType value: %d" % room_type)
	return 1.0


## Returns the phase growth multiplier for a given seed phase.
## Example: GameConfig.get_phase_multiplier(Enums.SeedPhase.BLOOM) -> 3.0
static func get_phase_multiplier(phase: Enums.SeedPhase) -> float:
	if PHASE_GROWTH_MULTIPLIERS.has(phase):
		return PHASE_GROWTH_MULTIPLIERS[phase]
	push_warning("Unknown SeedPhase value: %d" % phase)
	return 1.0
