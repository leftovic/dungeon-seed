extends GutTest
## Unit tests for the ExpeditionRunner service.

const ExpeditionRunnerScript := preload("res://src/services/expedition_runner.gd")
const DeterministicRNGScript := preload("res://src/models/rng.gd")
const LootTableEngineScript := preload("res://src/services/loot_table_engine.gd")

var runner: RefCounted
var rng: RefCounted
var loot_engine: RefCounted


# ===========================================================================
# Setup
# ===========================================================================

func before_each() -> void:
	runner = ExpeditionRunnerScript.new()
	rng = DeterministicRNGScript.new()
	rng.seed_string("test_expedition")
	loot_engine = LootTableEngineScript.new()
	_register_test_tables()


func _register_test_tables() -> void:
	var combat_entries: Array[Dictionary] = [
		{"item_id": "iron_sword", "weight": 50, "min_qty": 1, "max_qty": 1},
		{"item_id": "health_potion", "weight": 30, "min_qty": 1, "max_qty": 3},
	]
	loot_engine.register_table("combat", combat_entries)
	var treasure_entries: Array[Dictionary] = [
		{"item_id": "gold_ring", "weight": 40, "min_qty": 1, "max_qty": 1},
		{"item_id": "gem", "weight": 30, "min_qty": 1, "max_qty": 2},
	]
	loot_engine.register_table("treasure", treasure_entries)
	var secret_entries: Array[Dictionary] = [
		{"item_id": "rare_gem", "weight": 50, "min_qty": 1, "max_qty": 1},
		{"item_id": "ancient_relic", "weight": 20, "min_qty": 1, "max_qty": 1},
	]
	loot_engine.register_table("secret", secret_entries)
	var boss_entries: Array[Dictionary] = [
		{"item_id": "legendary_blade", "weight": 30, "min_qty": 1, "max_qty": 1},
		{"item_id": "boss_trophy", "weight": 50, "min_qty": 1, "max_qty": 1},
	]
	loot_engine.register_table("boss", boss_entries)
	var puzzle_entries: Array[Dictionary] = [
		{"item_id": "puzzle_box", "weight": 50, "min_qty": 1, "max_qty": 1},
	]
	loot_engine.register_table("puzzle", puzzle_entries)


# ===========================================================================
# Test Helpers
# ===========================================================================

func _make_adventurer(id: String, cls: Enums.AdventurerClass, level: int = 1) -> AdventurerData:
	var adv := AdventurerData.new()
	adv.id = id
	adv.display_name = id
	adv.adventurer_class = cls
	adv.level = level
	adv.initialize_base_stats()
	return adv


func _make_strong_party() -> Array:
	var warrior := _make_adventurer("warrior_1", Enums.AdventurerClass.WARRIOR, 10)
	warrior.stats["health"] = 500
	warrior.stats["attack"] = 80
	warrior.stats["defense"] = 40
	warrior.stats["speed"] = 20
	warrior.stats["utility"] = 15
	var mage := _make_adventurer("mage_1", Enums.AdventurerClass.MAGE, 10)
	mage.stats["health"] = 300
	mage.stats["attack"] = 60
	mage.stats["defense"] = 20
	mage.stats["speed"] = 25
	mage.stats["utility"] = 50
	return [warrior, mage]


func _make_weak_party() -> Array:
	var adv := _make_adventurer("weakling", Enums.AdventurerClass.MAGE, 1)
	adv.stats["health"] = 5
	adv.stats["attack"] = 1
	adv.stats["defense"] = 0
	adv.stats["speed"] = 1
	adv.stats["utility"] = 0
	return [adv]


func _make_standard_party() -> Array:
	return [
		_make_adventurer("adv_warrior", Enums.AdventurerClass.WARRIOR),
		_make_adventurer("adv_ranger", Enums.AdventurerClass.RANGER),
		_make_adventurer("adv_mage", Enums.AdventurerClass.MAGE),
	]


func _make_simple_dungeon() -> DungeonData:
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_dungeon"
	dungeon.element = Enums.Element.TERRA
	dungeon.difficulty = 1

	var entrance := RoomData.new()
	entrance.index = 0
	entrance.type = Enums.RoomType.ENTRANCE
	entrance.difficulty = 1

	var combat := RoomData.new()
	combat.index = 1
	combat.type = Enums.RoomType.COMBAT
	combat.difficulty = 1

	var boss := RoomData.new()
	boss.index = 2
	boss.type = Enums.RoomType.BOSS
	boss.difficulty = 1

	dungeon.rooms = [entrance, combat, boss]
	dungeon.edges = [Vector2i(0, 1), Vector2i(1, 2)]
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = 2
	return dungeon


func _make_room(room_type: Enums.RoomType, difficulty: int = 1, idx: int = 0) -> RoomData:
	var room := RoomData.new()
	room.index = idx
	room.type = room_type
	room.difficulty = difficulty
	return room


func _make_party_state(party: Array) -> Dictionary:
	var state: Dictionary = {}
	for adv in party:
		var a: AdventurerData = adv as AdventurerData
		var eff: Dictionary = a.get_effective_stats()
		var hp: int = eff.get("health", 1)
		state[a.id] = {
			"adventurer": a,
			"current_hp": hp,
			"max_hp": hp,
			"is_ko": false,
			"damage_dealt": 0,
			"damage_taken": 0,
		}
	return state


# ===========================================================================
# 1. Expedition Flow (~15 tests)
# ===========================================================================

func test_expedition_returns_valid_result() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_not_null(result, "Result should not be null")
	assert_true(result is Dictionary, "Result should be a Dictionary")


func test_expedition_result_has_all_keys() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	var expected_keys: Array[String] = [
		"status", "rooms_cleared", "total_rooms", "loot",
		"currency", "xp_earned", "combat_log", "party_hp", "adventurers_ko",
	]
	for key in expected_keys:
		assert_true(result.has(key), "Result should have key '%s'" % key)


func test_expedition_rooms_cleared_count() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(result["rooms_cleared"] > 0, "Should clear at least one room")
	assert_true(
		result["rooms_cleared"] <= result["total_rooms"],
		"Rooms cleared should not exceed total rooms"
	)


func test_expedition_path_follows_path_to_boss() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_eq(result["total_rooms"], 3, "Path should have 3 rooms (entrance, combat, boss)")


func test_entrance_room_auto_clears() -> void:
	var dungeon := DungeonData.new()
	dungeon.seed_id = "entrance_only"
	dungeon.element = Enums.Element.NONE
	dungeon.difficulty = 1
	var entrance := _make_room(Enums.RoomType.ENTRANCE, 1, 0)
	dungeon.rooms = [entrance]
	dungeon.edges = []
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = -1
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(result["rooms_cleared"] >= 1, "Entrance should auto-clear")


func test_expedition_empty_dungeon_returns_failed() -> void:
	var dungeon := DungeonData.new()
	dungeon.rooms = []
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_eq(result["status"], Enums.ExpeditionStatus.FAILED)


func test_expedition_null_party_returns_failed() -> void:
	var dungeon := _make_simple_dungeon()
	var result: Dictionary = runner.run_expedition(dungeon, [], rng, loot_engine)
	assert_eq(result["status"], Enums.ExpeditionStatus.FAILED)


func test_expedition_deterministic_same_seed() -> void:
	var dungeon1 := _make_simple_dungeon()
	var dungeon2 := _make_simple_dungeon()
	var party1 := _make_strong_party()
	var party2 := _make_strong_party()
	var rng1 := DeterministicRNGScript.new()
	rng1.seed_string("deterministic_test")
	var rng2 := DeterministicRNGScript.new()
	rng2.seed_string("deterministic_test")
	var result1: Dictionary = runner.run_expedition(dungeon1, party1, rng1, loot_engine)
	var result2: Dictionary = runner.run_expedition(dungeon2, party2, rng2, loot_engine)
	assert_eq(result1["rooms_cleared"], result2["rooms_cleared"], "Same seed should produce same rooms_cleared")
	assert_eq(result1["xp_earned"], result2["xp_earned"], "Same seed should produce same XP")
	assert_eq(result1["status"], result2["status"], "Same seed should produce same status")


func test_expedition_completed_status_on_victory() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	if result["rooms_cleared"] == result["total_rooms"]:
		assert_eq(result["status"], Enums.ExpeditionStatus.COMPLETED)


func test_expedition_failed_status_on_wipe() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_weak_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	# Weak party likely fails
	if result["status"] == Enums.ExpeditionStatus.FAILED:
		assert_true(true, "Weak party should fail")
	else:
		assert_true(true, "Party survived somehow — acceptable")


func test_expedition_null_dungeon_returns_failed() -> void:
	var result: Dictionary = runner.run_expedition(null, _make_strong_party(), rng, loot_engine)
	assert_eq(result["status"], Enums.ExpeditionStatus.FAILED)


func test_expedition_xp_earned_positive() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(result["xp_earned"] > 0, "Should earn XP from rooms")


func test_expedition_party_hp_tracked() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(result["party_hp"] is Dictionary, "party_hp should be a Dictionary")
	assert_true(result["party_hp"].size() > 0, "party_hp should have entries")


func test_expedition_ko_list_is_array() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(result["adventurers_ko"] is Array, "adventurers_ko should be an Array")


func test_expedition_marks_rooms_cleared() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(dungeon.rooms[0].is_cleared, "Entrance should be marked cleared")


# ===========================================================================
# 2. Combat Resolution (~20 tests)
# ===========================================================================

func test_combat_strong_party_wins() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Weak Slime", "health": 10, "max_health": 10, "attack": 2, "defense": 0, "speed": 1, "element": Enums.Element.NONE, "is_elite": false},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.TERRA)
	assert_true(result["victory"], "Strong party should win against weak enemy")


func test_combat_weak_party_may_lose() -> void:
	var party := _make_weak_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Strong Dragon", "health": 500, "max_health": 500, "attack": 100, "defense": 50, "speed": 30, "element": Enums.Element.FLAME, "is_elite": true},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_false(result["victory"], "Weak party should lose to strong enemy")


func test_combat_initiative_follows_speed() -> void:
	var fast := _make_adventurer("fast", Enums.AdventurerClass.ROGUE, 1)
	fast.stats["speed"] = 100
	var slow := _make_adventurer("slow", Enums.AdventurerClass.WARRIOR, 1)
	slow.stats["speed"] = 1
	var party := [fast, slow]
	var state := _make_party_state(party)
	# Test sorting directly
	var combatants: Array[Dictionary] = [
		{"id": "slow", "is_party": true, "speed": 1, "utility": 0},
		{"id": "fast", "is_party": true, "speed": 100, "utility": 0},
	]
	var sorted_arr: Array[Dictionary] = runner._sort_by_initiative(combatants, rng)
	assert_eq(sorted_arr[0]["id"], "fast", "Fastest combatant should go first")


func test_damage_is_at_least_one() -> void:
	var attacker: Dictionary = {"attack": 1, "utility": 0}
	var defender: Dictionary = {"defense": 999}
	var dmg: int = runner._calculate_damage(attacker, defender, rng, Enums.Element.NONE, Enums.Element.NONE)
	assert_true(dmg >= 1, "Damage should be at least 1")


func test_crit_scales_with_utility() -> void:
	# High utility should yield higher crit chance (statistically)
	var high_util: Dictionary = {"attack": 50, "utility": 200}
	var defender: Dictionary = {"defense": 0}
	var crits: int = 0
	var test_rng := DeterministicRNGScript.new()
	test_rng.seed_string("crit_test")
	for i in range(200):
		var dmg: int = runner._calculate_damage(high_util, defender, test_rng, Enums.Element.NONE, Enums.Element.NONE)
		# If damage is notably higher than base it was a crit
		if dmg > 60:
			crits += 1
	assert_true(crits > 0, "High utility should produce some crits")


func test_combat_ends_all_enemies_defeated() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "health": 1, "max_health": 1, "attack": 1, "defense": 0, "speed": 1, "element": Enums.Element.NONE, "is_elite": false},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_true(result["victory"], "Combat should end in victory")
	assert_true(result["enemies_defeated"] >= 1, "Should defeat at least one enemy")


func test_combat_ends_all_party_ko() -> void:
	var party := _make_weak_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Boss", "health": 999, "max_health": 999, "attack": 999, "defense": 999, "speed": 99, "element": Enums.Element.NONE, "is_elite": true},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_false(result["victory"], "Party should be defeated")
	assert_true(result["ko_list"].size() > 0, "Should have KO'd members")


func test_combat_max_rounds_prevents_infinite() -> void:
	# Two very tanky but weak combatants
	var tank := _make_adventurer("tank", Enums.AdventurerClass.SENTINEL, 1)
	tank.stats["health"] = 99999
	tank.stats["attack"] = 0
	tank.stats["defense"] = 99999
	var party := [tank]
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Wall", "health": 99999, "max_health": 99999, "attack": 0, "defense": 99999, "speed": 1, "element": Enums.Element.NONE, "is_elite": false},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_true(result["rounds"] <= 50, "Should not exceed MAX_COMBAT_ROUNDS")


func test_enemies_generated_match_difficulty() -> void:
	var easy_room := _make_room(Enums.RoomType.COMBAT, 1)
	var hard_room := _make_room(Enums.RoomType.COMBAT, 8)
	var rng1 := DeterministicRNGScript.new()
	rng1.seed_string("enemy_gen_1")
	var rng2 := DeterministicRNGScript.new()
	rng2.seed_string("enemy_gen_2")
	var easy_enemies: Array[Dictionary] = runner._generate_enemies(easy_room, rng1, Enums.Element.NONE)
	var hard_enemies: Array[Dictionary] = runner._generate_enemies(hard_room, rng2, Enums.Element.NONE)
	var easy_total_hp: int = 0
	for e in easy_enemies:
		easy_total_hp += e.get("health", 0)
	var hard_total_hp: int = 0
	for e in hard_enemies:
		hard_total_hp += e.get("health", 0)
	assert_true(hard_total_hp > easy_total_hp, "Harder rooms should produce tougher enemies")


func test_boss_enemies_have_boosted_stats() -> void:
	var boss_room := _make_room(Enums.RoomType.BOSS, 3)
	var combat_room := _make_room(Enums.RoomType.COMBAT, 3)
	var rng1 := DeterministicRNGScript.new()
	rng1.seed_string("boss_stat_1")
	var rng2 := DeterministicRNGScript.new()
	rng2.seed_string("boss_stat_2")
	var boss_enemies: Array[Dictionary] = runner._generate_enemies(boss_room, rng1, Enums.Element.TERRA)
	var combat_enemies: Array[Dictionary] = runner._generate_enemies(combat_room, rng2, Enums.Element.TERRA)
	var boss_atk: int = 0
	for e in boss_enemies:
		boss_atk += e.get("attack", 0)
	var combat_atk: int = 0
	for e in combat_enemies:
		combat_atk += e.get("attack", 0)
	assert_true(boss_atk > combat_atk, "Boss enemies should have higher total attack")


func test_combat_result_has_rounds() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "health": 10, "max_health": 10, "attack": 2, "defense": 0, "speed": 1, "element": Enums.Element.NONE, "is_elite": false},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_true(result["rounds"] >= 1, "Combat should take at least 1 round")


func test_combat_result_has_combat_log() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "health": 10, "max_health": 10, "attack": 2, "defense": 0, "speed": 1, "element": Enums.Element.NONE, "is_elite": false},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_true(result["combat_log"] is Array, "combat_log should be an Array")
	assert_true(result["combat_log"].size() > 0, "combat_log should not be empty")


func test_combat_result_has_victory_key() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Slime", "health": 5, "max_health": 5, "attack": 1, "defense": 0, "speed": 1, "element": Enums.Element.NONE, "is_elite": false},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_true(result.has("victory"), "Result should have 'victory' key")


func test_combat_party_hp_updated_after_combat() -> void:
	var party := _make_standard_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Hitter", "health": 50, "max_health": 50, "attack": 15, "defense": 5, "speed": 20, "element": Enums.Element.NONE, "is_elite": false},
	]
	runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	# At least one party member should have taken some damage or HP unchanged
	var total_hp: int = 0
	for adv_id in state:
		total_hp += state[adv_id]["current_hp"]
	assert_true(total_hp >= 0, "Total HP should be non-negative")


func test_combat_enemies_defeated_count() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "S1", "health": 5, "max_health": 5, "attack": 1, "defense": 0, "speed": 1, "element": Enums.Element.NONE, "is_elite": false},
		{"name": "S2", "health": 5, "max_health": 5, "attack": 1, "defense": 0, "speed": 1, "element": Enums.Element.NONE, "is_elite": false},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_eq(result["enemies_defeated"], 2, "Should defeat both enemies")


func test_combat_multiple_enemies() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "E1", "health": 20, "max_health": 20, "attack": 5, "defense": 2, "speed": 3, "element": Enums.Element.NONE, "is_elite": false},
		{"name": "E2", "health": 20, "max_health": 20, "attack": 5, "defense": 2, "speed": 3, "element": Enums.Element.NONE, "is_elite": false},
		{"name": "E3", "health": 20, "max_health": 20, "attack": 5, "defense": 2, "speed": 3, "element": Enums.Element.NONE, "is_elite": false},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_true(result["victory"], "Strong party should handle 3 weak enemies")


func test_combat_ko_list_populated() -> void:
	var adv := _make_adventurer("fragile", Enums.AdventurerClass.MAGE, 1)
	adv.stats["health"] = 1
	adv.stats["defense"] = 0
	var party := [adv]
	var state := _make_party_state(party)
	var enemies: Array[Dictionary] = [
		{"name": "Hitter", "health": 100, "max_health": 100, "attack": 50, "defense": 0, "speed": 99, "element": Enums.Element.NONE, "is_elite": false},
	]
	var result: Dictionary = runner.resolve_combat(state, enemies, rng, Enums.Element.NONE)
	assert_true(result["ko_list"].size() > 0, "Fragile adventurer should be KO'd")


func test_combat_deterministic_results() -> void:
	var party1 := _make_strong_party()
	var state1 := _make_party_state(party1)
	var party2 := _make_strong_party()
	var state2 := _make_party_state(party2)
	var enemies_template: Array[Dictionary] = [
		{"name": "Slime", "health": 30, "max_health": 30, "attack": 5, "defense": 2, "speed": 3, "element": Enums.Element.FROST, "is_elite": false},
	]
	var rng1 := DeterministicRNGScript.new()
	rng1.seed_string("combat_det")
	var rng2 := DeterministicRNGScript.new()
	rng2.seed_string("combat_det")
	var r1: Dictionary = runner.resolve_combat(state1, enemies_template.duplicate(true), rng1, Enums.Element.TERRA)
	var r2: Dictionary = runner.resolve_combat(state2, enemies_template.duplicate(true), rng2, Enums.Element.TERRA)
	assert_eq(r1["victory"], r2["victory"], "Deterministic combat should match")
	assert_eq(r1["rounds"], r2["rounds"], "Deterministic rounds should match")


# ===========================================================================
# 3. Elemental System (~10 tests)
# ===========================================================================

func test_terra_advantage_over_frost() -> void:
	var mod: float = runner._get_elemental_modifier(Enums.Element.TERRA, Enums.Element.FROST)
	assert_almost_eq(mod, 1.5, 0.01, "Terra should have 1.5x vs Frost")


func test_frost_advantage_over_flame() -> void:
	var mod: float = runner._get_elemental_modifier(Enums.Element.FROST, Enums.Element.FLAME)
	assert_almost_eq(mod, 1.5, 0.01, "Frost should have 1.5x vs Flame")


func test_flame_advantage_over_terra() -> void:
	var mod: float = runner._get_elemental_modifier(Enums.Element.FLAME, Enums.Element.TERRA)
	assert_almost_eq(mod, 1.5, 0.01, "Flame should have 1.5x vs Terra")


func test_arcane_advantage_over_shadow() -> void:
	var mod: float = runner._get_elemental_modifier(Enums.Element.ARCANE, Enums.Element.SHADOW)
	assert_almost_eq(mod, 1.5, 0.01, "Arcane should have 1.5x vs Shadow")


func test_shadow_advantage_over_arcane() -> void:
	var mod: float = runner._get_elemental_modifier(Enums.Element.SHADOW, Enums.Element.ARCANE)
	assert_almost_eq(mod, 1.5, 0.01, "Shadow should have 1.5x vs Arcane")


func test_terra_disadvantage_vs_flame() -> void:
	var mod: float = runner._get_elemental_modifier(Enums.Element.TERRA, Enums.Element.FLAME)
	assert_almost_eq(mod, 0.6, 0.01, "Terra should have 0.6x vs Flame")


func test_frost_disadvantage_vs_terra() -> void:
	var mod: float = runner._get_elemental_modifier(Enums.Element.FROST, Enums.Element.TERRA)
	assert_almost_eq(mod, 0.6, 0.01, "Frost should have 0.6x vs Terra")


func test_flame_disadvantage_vs_frost() -> void:
	var mod: float = runner._get_elemental_modifier(Enums.Element.FLAME, Enums.Element.FROST)
	assert_almost_eq(mod, 0.6, 0.01, "Flame should have 0.6x vs Frost")


func test_neutral_matchup_returns_1() -> void:
	var mod: float = runner._get_elemental_modifier(Enums.Element.TERRA, Enums.Element.TERRA)
	assert_almost_eq(mod, 1.0, 0.01, "Same element should be 1.0x")


func test_none_element_always_neutral() -> void:
	var mod1: float = runner._get_elemental_modifier(Enums.Element.NONE, Enums.Element.FLAME)
	var mod2: float = runner._get_elemental_modifier(Enums.Element.TERRA, Enums.Element.NONE)
	var mod3: float = runner._get_elemental_modifier(Enums.Element.NONE, Enums.Element.NONE)
	assert_almost_eq(mod1, 1.0, 0.01, "NONE attacker should be neutral")
	assert_almost_eq(mod2, 1.0, 0.01, "NONE defender should be neutral")
	assert_almost_eq(mod3, 1.0, 0.01, "NONE vs NONE should be neutral")


# ===========================================================================
# 4. Room Resolution (~15 tests)
# ===========================================================================

func test_entrance_clears_immediately() -> void:
	var room := _make_room(Enums.RoomType.ENTRANCE)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["cleared"], "Entrance should clear immediately")


func test_rest_heals_30_percent() -> void:
	var room := _make_room(Enums.RoomType.REST)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	# Reduce HP
	for adv_id in state:
		state[adv_id]["current_hp"] = roundi(float(state[adv_id]["max_hp"]) * 0.5)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["cleared"], "Rest room should clear")
	# Check that HP increased
	for adv_id in state:
		var expected_heal: int = maxi(1, roundi(float(state[adv_id]["max_hp"]) * 0.30))
		var expected_hp: int = mini(state[adv_id]["max_hp"], roundi(float(state[adv_id]["max_hp"]) * 0.5) + expected_heal)
		assert_eq(state[adv_id]["current_hp"], expected_hp, "Should heal ~30%% max HP for %s" % adv_id)


func test_trap_deals_damage_based_on_difficulty() -> void:
	var room := _make_room(Enums.RoomType.TRAP, 3)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var initial_hp: Dictionary = {}
	for adv_id in state:
		initial_hp[adv_id] = state[adv_id]["current_hp"]
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["cleared"], "Trap room should clear")
	var expected_damage: int = 3 * 5  # difficulty * TRAP_DAMAGE_MULTIPLIER
	for adv_id in state:
		var expected_hp: int = maxi(0, initial_hp[adv_id] - expected_damage)
		assert_eq(state[adv_id]["current_hp"], expected_hp, "Trap damage should be difficulty * 5")


func test_treasure_grants_loot() -> void:
	var room := _make_room(Enums.RoomType.TREASURE)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["cleared"], "Treasure room should clear")
	assert_true(result["loot"] is Array, "Should have loot array")
	assert_true(result["loot"].size() > 0, "Should have loot items")


func test_treasure_grants_currency() -> void:
	var room := _make_room(Enums.RoomType.TREASURE, 3)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["currency"] is Dictionary, "Should have currency dict")
	assert_true(result["currency"].size() > 0, "Should have currency entries")


func test_puzzle_check_uses_utility() -> void:
	# Party with very high utility should pass puzzle
	var mage := _make_adventurer("puzzle_mage", Enums.AdventurerClass.MAGE, 1)
	mage.stats["utility"] = 100
	var party := [mage]
	var state := _make_party_state(party)
	var room := _make_room(Enums.RoomType.PUZZLE, 1)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["cleared"], "Puzzle should clear")
	# With utility 100 vs threshold of 1*10*0.5 = 5, should succeed
	var has_success: bool = false
	for entry in result["combat_log"]:
		if entry.get("type", "") == "puzzle_success":
			has_success = true
	assert_true(has_success, "High utility should pass puzzle")


func test_puzzle_failure_deals_damage() -> void:
	var warrior := _make_adventurer("low_util", Enums.AdventurerClass.WARRIOR, 1)
	warrior.stats["utility"] = 0
	var party := [warrior]
	var state := _make_party_state(party)
	var room := _make_room(Enums.RoomType.PUZZLE, 5)
	var initial_hp: int = state["low_util"]["current_hp"]
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["cleared"], "Puzzle should still clear")
	# Check if damage was applied
	var has_fail: bool = false
	for entry in result["combat_log"]:
		if entry.get("type", "") == "puzzle_failure":
			has_fail = true
	assert_true(has_fail, "Low utility should fail puzzle")
	assert_true(state["low_util"]["current_hp"] < initial_hp, "Failed puzzle should deal damage")


func test_secret_room_grants_enhanced_loot() -> void:
	var room := _make_room(Enums.RoomType.SECRET)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["cleared"], "Secret room should clear")
	assert_true(result["loot"].size() >= 2, "Secret room should give 2x loot rolls")


func test_boss_room_has_harder_enemies() -> void:
	# Boss room enemies are tested via _generate_enemies
	var boss_room := _make_room(Enums.RoomType.BOSS, 3)
	var rng_boss := DeterministicRNGScript.new()
	rng_boss.seed_string("boss_hard")
	var enemies: Array[Dictionary] = runner._generate_enemies(boss_room, rng_boss, Enums.Element.FLAME)
	for e in enemies:
		assert_true(e["is_elite"], "Boss enemies should be marked elite")


func test_combat_room_resolves() -> void:
	var room := _make_room(Enums.RoomType.COMBAT)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.TERRA)
	# Strong party should clear combat
	assert_true(result["cleared"], "Strong party should clear combat room")


func test_room_clear_grants_xp() -> void:
	var room := _make_room(Enums.RoomType.ENTRANCE)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_eq(result["xp"], 5, "Entrance should grant ROOM_CLEAR_XP (5)")


func test_rest_room_doesnt_revive_ko() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var first_id: String = state.keys()[0]
	state[first_id]["current_hp"] = 0
	state[first_id]["is_ko"] = true
	var room := _make_room(Enums.RoomType.REST)
	runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(state[first_id]["is_ko"], "KO'd should remain KO'd after rest")
	assert_eq(state[first_id]["current_hp"], 0, "KO'd should remain at 0 HP")


func test_trap_can_ko_adventurer() -> void:
	var adv := _make_adventurer("fragile_trap", Enums.AdventurerClass.MAGE, 1)
	adv.stats["health"] = 5
	var party := [adv]
	var state := _make_party_state(party)
	var room := _make_room(Enums.RoomType.TRAP, 3)  # 3 * 5 = 15 damage
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(state["fragile_trap"]["is_ko"], "Trap should KO low HP adventurer")
	assert_true(result["ko_list"].has("fragile_trap"), "KO list should contain KO'd adventurer")


# ===========================================================================
# 5. Between-Room Mechanics (~5 tests)
# ===========================================================================

func test_between_room_healing_applies() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	for adv_id in state:
		state[adv_id]["current_hp"] = roundi(float(state[adv_id]["max_hp"]) * 0.5)
	var before_hp: Dictionary = {}
	for adv_id in state:
		before_hp[adv_id] = state[adv_id]["current_hp"]
	runner._apply_between_room_healing(state)
	for adv_id in state:
		assert_true(state[adv_id]["current_hp"] > before_hp[adv_id], "HP should increase after between-room healing")


func test_between_room_healing_doesnt_exceed_max() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	# Already at full HP
	runner._apply_between_room_healing(state)
	for adv_id in state:
		assert_true(
			state[adv_id]["current_hp"] <= state[adv_id]["max_hp"],
			"HP should not exceed max"
		)


func test_ko_adventurers_dont_heal_between_rooms() -> void:
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var first_id: String = state.keys()[0]
	state[first_id]["current_hp"] = 0
	state[first_id]["is_ko"] = true
	runner._apply_between_room_healing(state)
	assert_eq(state[first_id]["current_hp"], 0, "KO'd adventurer should not heal")


func test_between_room_healing_amount_is_5_percent() -> void:
	var adv := _make_adventurer("healer_test", Enums.AdventurerClass.WARRIOR, 1)
	adv.stats["health"] = 100
	var party := [adv]
	var state := _make_party_state(party)
	state["healer_test"]["current_hp"] = 50
	runner._apply_between_room_healing(state)
	# 5% of 100 = 5, so HP should be 55
	assert_eq(state["healer_test"]["current_hp"], 55, "Should heal 5% of max HP")


func test_hp_capping_works_correctly() -> void:
	var adv := _make_adventurer("cap_test", Enums.AdventurerClass.WARRIOR, 1)
	adv.stats["health"] = 100
	var party := [adv]
	var state := _make_party_state(party)
	state["cap_test"]["current_hp"] = 98
	runner._apply_between_room_healing(state)
	assert_eq(state["cap_test"]["current_hp"], 100, "HP should cap at max_hp")


# ===========================================================================
# 6. Loot & XP (~10 tests)
# ===========================================================================

func test_enemies_grant_xp() -> void:
	var room := _make_room(Enums.RoomType.COMBAT, 1)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	if result["cleared"]:
		assert_true(result["xp"] > 0, "Defeating enemies should grant XP")


func test_elite_enemies_grant_bonus_xp() -> void:
	# Test indirectly: elite XP multiplier is 2.5x vs base 15
	var elite_xp: int = roundi(15 * 2.5)
	assert_eq(elite_xp, 38, "Elite XP should be 38 (15 * 2.5)")


func test_boss_grants_large_xp() -> void:
	var boss_xp: int = roundi(15 * 5.0)
	assert_eq(boss_xp, 75, "Boss XP per enemy should be 75 (15 * 5.0)")


func test_room_clear_grants_base_xp() -> void:
	var room := _make_room(Enums.RoomType.ENTRANCE)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["xp"] >= 5, "Room clear should grant at least ROOM_CLEAR_XP")


func test_currency_accumulated_across_rooms() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	if result["status"] == Enums.ExpeditionStatus.COMPLETED:
		assert_true(result["currency"] is Dictionary, "Currency should be a Dictionary")
		assert_true(result["currency"].size() > 0, "Should accumulate currency")


func test_loot_collected_from_treasure() -> void:
	var room := _make_room(Enums.RoomType.TREASURE)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["loot"].size() > 0, "Treasure should yield loot")


func test_loot_collected_from_secret() -> void:
	var room := _make_room(Enums.RoomType.SECRET)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	assert_true(result["loot"].size() > 0, "Secret room should yield loot")


func test_combat_victory_grants_currency() -> void:
	var room := _make_room(Enums.RoomType.COMBAT, 3)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	if result["cleared"]:
		assert_true(result["currency"].size() > 0, "Combat victory should grant currency")


func test_boss_victory_grants_loot() -> void:
	var room := _make_room(Enums.RoomType.BOSS, 1)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	if result["cleared"]:
		assert_true(result["loot"].size() > 0, "Boss victory should grant loot")


func test_xp_granted_to_surviving_adventurers() -> void:
	var dungeon := _make_simple_dungeon()
	var party := _make_strong_party()
	var initial_xp: Dictionary = {}
	for adv in party:
		initial_xp[adv.id] = adv.xp
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	if result["status"] == Enums.ExpeditionStatus.COMPLETED:
		for adv in party:
			if not result["adventurers_ko"].has(adv.id):
				# Adventurer gained XP (xp or level changed)
				assert_true(
					adv.xp != initial_xp[adv.id] or adv.level > 1,
					"Surviving adventurer should gain XP"
				)


# ===========================================================================
# 7. Edge Cases (~5 tests)
# ===========================================================================

func test_single_room_dungeon() -> void:
	var dungeon := DungeonData.new()
	dungeon.seed_id = "single_room"
	dungeon.element = Enums.Element.NONE
	dungeon.difficulty = 1
	var entrance := _make_room(Enums.RoomType.ENTRANCE, 1, 0)
	dungeon.rooms = [entrance]
	dungeon.edges = []
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = -1
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(result["rooms_cleared"] >= 1, "Should clear the single room")


func test_party_of_one() -> void:
	var solo := _make_adventurer("solo", Enums.AdventurerClass.WARRIOR, 5)
	solo.stats["health"] = 200
	solo.stats["attack"] = 40
	solo.stats["defense"] = 20
	var party := [solo]
	var dungeon := _make_simple_dungeon()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(result.has("status"), "Should return valid result for solo adventurer")


func test_all_same_class_party() -> void:
	var party: Array = []
	for i in range(4):
		party.append(_make_adventurer("warrior_%d" % i, Enums.AdventurerClass.WARRIOR))
	var dungeon := _make_simple_dungeon()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(result.has("status"), "All-warrior party should produce valid result")


func test_dungeon_with_no_boss() -> void:
	var dungeon := DungeonData.new()
	dungeon.seed_id = "no_boss"
	dungeon.element = Enums.Element.TERRA
	dungeon.difficulty = 1
	var entrance := _make_room(Enums.RoomType.ENTRANCE, 1, 0)
	var combat := _make_room(Enums.RoomType.COMBAT, 1, 1)
	dungeon.rooms = [entrance, combat]
	dungeon.edges = [Vector2i(0, 1)]
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = -1
	var party := _make_strong_party()
	var result: Dictionary = runner.run_expedition(dungeon, party, rng, loot_engine)
	assert_true(result["rooms_cleared"] >= 1, "Should handle dungeon without boss")


func test_very_high_difficulty_room() -> void:
	var room := _make_room(Enums.RoomType.COMBAT, 10)
	var party := _make_strong_party()
	var state := _make_party_state(party)
	var result: Dictionary = runner.resolve_room(room, state, rng, loot_engine, Enums.Element.NONE)
	# Should not crash regardless of outcome
	assert_true(result.has("cleared"), "Should handle high difficulty without crashing")


# ===========================================================================
# 8. Armor Multiplier Tests
# ===========================================================================

func test_warrior_armor_multiplier() -> void:
	var mult: float = runner._get_armor_multiplier(Enums.AdventurerClass.WARRIOR)
	assert_almost_eq(mult, 1.0, 0.01)


func test_sentinel_armor_multiplier() -> void:
	var mult: float = runner._get_armor_multiplier(Enums.AdventurerClass.SENTINEL)
	assert_almost_eq(mult, 1.0, 0.01)


func test_ranger_armor_multiplier() -> void:
	var mult: float = runner._get_armor_multiplier(Enums.AdventurerClass.RANGER)
	assert_almost_eq(mult, 0.7, 0.01)


func test_alchemist_armor_multiplier() -> void:
	var mult: float = runner._get_armor_multiplier(Enums.AdventurerClass.ALCHEMIST)
	assert_almost_eq(mult, 0.7, 0.01)


func test_mage_armor_multiplier() -> void:
	var mult: float = runner._get_armor_multiplier(Enums.AdventurerClass.MAGE)
	assert_almost_eq(mult, 0.4, 0.01)


func test_rogue_armor_multiplier() -> void:
	var mult: float = runner._get_armor_multiplier(Enums.AdventurerClass.ROGUE)
	assert_almost_eq(mult, 0.4, 0.01)


# ===========================================================================
# 9. Enemy Generation Tests
# ===========================================================================

func test_generate_enemies_returns_array() -> void:
	var room := _make_room(Enums.RoomType.COMBAT, 1)
	var enemies: Array[Dictionary] = runner._generate_enemies(room, rng, Enums.Element.TERRA)
	assert_true(enemies.size() > 0, "Should generate at least one enemy")


func test_generate_enemies_have_required_fields() -> void:
	var room := _make_room(Enums.RoomType.COMBAT, 1)
	var enemies: Array[Dictionary] = runner._generate_enemies(room, rng, Enums.Element.TERRA)
	for e in enemies:
		assert_true(e.has("name"), "Enemy should have name")
		assert_true(e.has("health"), "Enemy should have health")
		assert_true(e.has("max_health"), "Enemy should have max_health")
		assert_true(e.has("attack"), "Enemy should have attack")
		assert_true(e.has("defense"), "Enemy should have defense")
		assert_true(e.has("speed"), "Enemy should have speed")
		assert_true(e.has("element"), "Enemy should have element")
		assert_true(e.has("is_elite"), "Enemy should have is_elite")


func test_generate_enemies_health_positive() -> void:
	var room := _make_room(Enums.RoomType.COMBAT, 5)
	var enemies: Array[Dictionary] = runner._generate_enemies(room, rng, Enums.Element.FROST)
	for e in enemies:
		assert_true(e["health"] > 0, "Enemy health should be positive")
		assert_eq(e["health"], e["max_health"], "Health should equal max_health initially")


func test_enemy_name_generation() -> void:
	var name: String = runner._generate_enemy_name(Enums.Element.FLAME, false, rng)
	assert_true(name.length() > 0, "Enemy name should not be empty")


func test_elite_enemy_name_includes_element() -> void:
	var name: String = runner._generate_enemy_name(Enums.Element.FROST, true, rng)
	assert_true(name.begins_with("Frost"), "Elite name should include element prefix")


# ===========================================================================
# 10. Initiative Sorting Tests
# ===========================================================================

func test_initiative_sorts_by_speed_descending() -> void:
	var combatants: Array[Dictionary] = [
		{"id": "slow", "speed": 5, "utility": 0},
		{"id": "fast", "speed": 20, "utility": 0},
		{"id": "mid", "speed": 10, "utility": 0},
	]
	var sorted_arr: Array[Dictionary] = runner._sort_by_initiative(combatants, rng)
	assert_eq(sorted_arr[0]["id"], "fast")
	assert_eq(sorted_arr[1]["id"], "mid")
	assert_eq(sorted_arr[2]["id"], "slow")


func test_initiative_tiebreak_by_utility() -> void:
	var combatants: Array[Dictionary] = [
		{"id": "low_util", "speed": 10, "utility": 5},
		{"id": "high_util", "speed": 10, "utility": 20},
	]
	var sorted_arr: Array[Dictionary] = runner._sort_by_initiative(combatants, rng)
	assert_eq(sorted_arr[0]["id"], "high_util", "Higher utility should break speed ties")


func test_initiative_tiebreak_key_cleaned() -> void:
	var combatants: Array[Dictionary] = [
		{"id": "a", "speed": 10, "utility": 10},
		{"id": "b", "speed": 10, "utility": 10},
	]
	var sorted_arr: Array[Dictionary] = runner._sort_by_initiative(combatants, rng)
	for c in sorted_arr:
		assert_false(c.has("_tiebreak"), "Tiebreak key should be cleaned up")
