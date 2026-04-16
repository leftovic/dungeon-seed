class_name LootTables
extends RefCounted
## Pre-built loot table definitions for all dungeon room contexts.
##
## Provides 7 const tables used by LootTableEngine:
##   combat_common, combat_rare, treasure_common, treasure_rare,
##   boss_loot, trap_consolation, puzzle_reward
##
## Each entry: { "item_id": String, "weight": int, "min_qty": int, "max_qty": int }
## Depends on: None (pure data)


## Common combat encounter drops — mostly consumables and basic materials.
const COMBAT_COMMON: Array[Dictionary] = [
	{"item_id": "health_herb", "weight": 30, "min_qty": 1, "max_qty": 3},
	{"item_id": "mana_shard", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "iron_scrap", "weight": 25, "min_qty": 1, "max_qty": 4},
	{"item_id": "leather_strip", "weight": 15, "min_qty": 1, "max_qty": 2},
	{"item_id": "bone_fragment", "weight": 10, "min_qty": 1, "max_qty": 3},
]


## Rare combat encounter drops — equipment and uncommon materials.
const COMBAT_RARE: Array[Dictionary] = [
	{"item_id": "steel_ingot", "weight": 25, "min_qty": 1, "max_qty": 2},
	{"item_id": "enchanted_dust", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "combat_badge", "weight": 15, "min_qty": 1, "max_qty": 1},
	{"item_id": "rare_herb", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "gem_shard", "weight": 10, "min_qty": 1, "max_qty": 1},
	{"item_id": "warrior_ring", "weight": 10, "min_qty": 1, "max_qty": 1},
]


## Common treasure room drops — currency items and basic valuables.
const TREASURE_COMMON: Array[Dictionary] = [
	{"item_id": "gold_pouch", "weight": 30, "min_qty": 1, "max_qty": 3},
	{"item_id": "silver_coin", "weight": 25, "min_qty": 2, "max_qty": 5},
	{"item_id": "gem_chip", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "trinket", "weight": 15, "min_qty": 1, "max_qty": 1},
	{"item_id": "silk_cloth", "weight": 10, "min_qty": 1, "max_qty": 2},
]


## Rare treasure room drops — high-value items and equipment.
const TREASURE_RARE: Array[Dictionary] = [
	{"item_id": "gold_bar", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "precious_gem", "weight": 15, "min_qty": 1, "max_qty": 1},
	{"item_id": "ancient_scroll", "weight": 15, "min_qty": 1, "max_qty": 1},
	{"item_id": "enchanted_amulet", "weight": 10, "min_qty": 1, "max_qty": 1},
	{"item_id": "rare_material", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "treasure_map", "weight": 10, "min_qty": 1, "max_qty": 1},
	{"item_id": "legendary_shard", "weight": 5, "min_qty": 1, "max_qty": 1},
	{"item_id": "crown_fragment", "weight": 5, "min_qty": 1, "max_qty": 1},
]


## Boss encounter drops — guaranteed high-value rewards.
const BOSS_LOOT: Array[Dictionary] = [
	{"item_id": "boss_trophy", "weight": 25, "min_qty": 1, "max_qty": 1},
	{"item_id": "epic_material", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "boss_essence", "weight": 20, "min_qty": 1, "max_qty": 3},
	{"item_id": "legendary_fragment", "weight": 15, "min_qty": 1, "max_qty": 1},
	{"item_id": "rare_equipment", "weight": 10, "min_qty": 1, "max_qty": 1},
	{"item_id": "mythic_shard", "weight": 5, "min_qty": 1, "max_qty": 1},
	{"item_id": "boss_key", "weight": 5, "min_qty": 1, "max_qty": 1},
]


## Trap room consolation drops — small rewards for surviving traps.
const TRAP_CONSOLATION: Array[Dictionary] = [
	{"item_id": "health_herb", "weight": 35, "min_qty": 1, "max_qty": 2},
	{"item_id": "antidote", "weight": 25, "min_qty": 1, "max_qty": 1},
	{"item_id": "trap_component", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "bone_fragment", "weight": 15, "min_qty": 1, "max_qty": 2},
	{"item_id": "salvage_scrap", "weight": 5, "min_qty": 1, "max_qty": 1},
]


## Puzzle room reward drops — knowledge-themed and magical items.
const PUZZLE_REWARD: Array[Dictionary] = [
	{"item_id": "knowledge_tome", "weight": 25, "min_qty": 1, "max_qty": 1},
	{"item_id": "mana_crystal", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "enchanted_dust", "weight": 20, "min_qty": 1, "max_qty": 2},
	{"item_id": "puzzle_token", "weight": 15, "min_qty": 1, "max_qty": 1},
	{"item_id": "ancient_scroll", "weight": 10, "min_qty": 1, "max_qty": 1},
	{"item_id": "arcane_focus", "weight": 10, "min_qty": 1, "max_qty": 1},
]


## Returns all table definitions as a dictionary mapping table_id -> entries.
## Useful for bulk-registering all tables with LootTableEngine.
static func get_all_tables() -> Dictionary:
	return {
		"combat_common": COMBAT_COMMON,
		"combat_rare": COMBAT_RARE,
		"treasure_common": TREASURE_COMMON,
		"treasure_rare": TREASURE_RARE,
		"boss_loot": BOSS_LOOT,
		"trap_consolation": TRAP_CONSOLATION,
		"puzzle_reward": PUZZLE_REWARD,
	}


## Registers all pre-built tables with the given LootTableEngine.
static func register_all(engine: RefCounted) -> void:
	var tables: Dictionary = get_all_tables()
	for table_id: String in tables:
		engine.register_table(table_id, tables[table_id])
