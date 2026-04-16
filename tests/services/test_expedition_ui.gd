extends GutTest
## GUT test suite for TASK-019: Expedition Dispatch & Resolution UI.
## Covers: initialization, dungeon preview, party selection & validation,
## expedition result formatting, room log formatting, party power & difficulty.

const ExpeditionUIScript = preload("res://src/ui/expedition_ui.gd")
const AdventurerRosterScript = preload("res://src/services/adventurer_roster.gd")
const AdventurerDataScript = preload("res://src/models/adventurer_data.gd")


# ===========================================================================
# Helpers
# ===========================================================================

var _ui: RefCounted
var _roster: RefCounted


func before_each() -> void:
	_ui = ExpeditionUIScript.new()
	_roster = AdventurerRosterScript.new()


func _make_adventurer(
	id: String = "adv_001",
	adv_class: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR,
	display_name: String = "TestHero",
	level: int = 1,
	available: bool = true,
) -> AdventurerData:
	var adv := AdventurerDataScript.new()
	adv.id = id
	adv.display_name = display_name
	adv.adventurer_class = adv_class
	adv.level = level
	adv.initialize_base_stats()
	adv.is_available = available
	return adv


func _make_dungeon(
	room_types: Array = [],
	boss_index: int = -1,
	element: Enums.Element = Enums.Element.TERRA,
	difficulty: int = 3,
) -> DungeonData:
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_seed"
	dungeon.element = element
	dungeon.difficulty = difficulty
	dungeon.entry_room_index = 0

	for i in range(room_types.size()):
		var room := RoomData.new()
		room.index = i
		room.type = room_types[i] as Enums.RoomType
		room.difficulty = difficulty
		dungeon.rooms.append(room)

	# Chain rooms linearly with edges
	for i in range(room_types.size() - 1):
		dungeon.edges.append(Vector2i(i, i + 1))

	dungeon.boss_room_index = boss_index
	return dungeon


func _setup_initialized_ui() -> void:
	_ui.initialize(_roster)


func _add_available_adventurers(count: int = 3) -> Array[String]:
	var ids: Array[String] = []
	var classes: Array = [
		Enums.AdventurerClass.WARRIOR,
		Enums.AdventurerClass.MAGE,
		Enums.AdventurerClass.RANGER,
		Enums.AdventurerClass.ROGUE,
	]
	for i in range(count):
		var cls = classes[i % classes.size()]
		var adv = _make_adventurer(
			"adv_%03d" % (i + 1),
			cls,
			"Hero_%d" % (i + 1),
			i + 1,
			true,
		)
		_roster.add_adventurer(adv)
		ids.append(adv.id)
	return ids


func _make_expedition_result(
	status: Enums.ExpeditionStatus = Enums.ExpeditionStatus.COMPLETED,
	rooms_cleared: int = 8,
	total_rooms: int = 12,
	xp_earned: int = 150,
	currency: Dictionary = {},
	loot: Array = [],
	combat_log: Array = [],
	party_hp: Dictionary = {},
	adventurers_ko: Array = [],
) -> Dictionary:
	return {
		"status": status,
		"rooms_cleared": rooms_cleared,
		"total_rooms": total_rooms,
		"xp_earned": xp_earned,
		"currency": currency,
		"loot": loot,
		"combat_log": combat_log,
		"party_hp": party_hp,
		"adventurers_ko": adventurers_ko,
	}


# ===========================================================================
# §1: Initialization (~3 tests)
# ===========================================================================

func test_ui_instantiates() -> void:
	assert_not_null(_ui, "ExpeditionUI should instantiate")


func test_not_initialized_before_init() -> void:
	assert_false(_ui.is_initialized(), "Should not be initialized before calling initialize()")


func test_initialized_after_init() -> void:
	_setup_initialized_ui()
	assert_true(_ui.is_initialized(), "Should be initialized after calling initialize()")


# ===========================================================================
# §2: Dungeon Preview (~8 tests)
# ===========================================================================

func test_preview_null_dungeon_returns_defaults() -> void:
	_setup_initialized_ui()
	var preview: Dictionary = _ui.get_dungeon_preview(null)
	assert_eq(preview["room_count"], 0, "Null dungeon should have 0 rooms")
	assert_eq(preview["has_boss"], false)
	assert_eq(preview["has_secret"], false)


func test_preview_room_count() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon(
		[Enums.RoomType.ENTRANCE, Enums.RoomType.COMBAT, Enums.RoomType.COMBAT, Enums.RoomType.BOSS],
		3
	)
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	assert_eq(preview["room_count"], 4, "Should report 4 rooms")


func test_preview_element_display() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon(
		[Enums.RoomType.ENTRANCE, Enums.RoomType.COMBAT],
		-1, Enums.Element.FLAME, 2
	)
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	assert_eq(preview["element"], int(Enums.Element.FLAME), "Element should be FLAME int")
	assert_eq(preview["element_name"], "Flame", "Element name should be 'Flame'")


func test_preview_difficulty_skulls_low() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon([Enums.RoomType.ENTRANCE], -1, Enums.Element.NONE, 1)
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	assert_eq(preview["difficulty_rating"], 1, "Difficulty 1 should yield 1 skull")


func test_preview_difficulty_skulls_medium() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon([Enums.RoomType.ENTRANCE], -1, Enums.Element.NONE, 7)
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	assert_eq(preview["difficulty_rating"], 3, "Difficulty 7 should yield 3 skulls")


func test_preview_difficulty_skulls_max() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon([Enums.RoomType.ENTRANCE], -1, Enums.Element.NONE, 20)
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	assert_eq(preview["difficulty_rating"], 5, "Difficulty 20 should yield 5 skulls")


func test_preview_boss_detection() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon(
		[Enums.RoomType.ENTRANCE, Enums.RoomType.COMBAT, Enums.RoomType.BOSS],
		2
	)
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	assert_true(preview["has_boss"], "Should detect boss room")


func test_preview_secret_detection() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon(
		[Enums.RoomType.ENTRANCE, Enums.RoomType.SECRET, Enums.RoomType.COMBAT],
	)
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	assert_true(preview["has_secret"], "Should detect secret room")


func test_preview_room_type_counts() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon([
		Enums.RoomType.ENTRANCE,
		Enums.RoomType.COMBAT,
		Enums.RoomType.COMBAT,
		Enums.RoomType.TREASURE,
		Enums.RoomType.BOSS,
	], 4)
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	var types: Dictionary = preview["room_types"]
	assert_eq(types.get(int(Enums.RoomType.COMBAT), 0), 2, "Should count 2 combat rooms")
	assert_eq(types.get(int(Enums.RoomType.ENTRANCE), 0), 1, "Should count 1 entrance")
	assert_eq(types.get(int(Enums.RoomType.TREASURE), 0), 1, "Should count 1 treasure")
	assert_eq(types.get(int(Enums.RoomType.BOSS), 0), 1, "Should count 1 boss")


func test_preview_no_boss_no_secret() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon([Enums.RoomType.ENTRANCE, Enums.RoomType.COMBAT])
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	assert_false(preview["has_boss"], "Should not detect boss")
	assert_false(preview["has_secret"], "Should not detect secret")


# ===========================================================================
# §3: Party Selection & Validation (~10 tests)
# ===========================================================================

func test_available_party_empty_roster() -> void:
	_setup_initialized_ui()
	var available: Array = _ui.get_available_party()
	assert_eq(available.size(), 0, "Empty roster should return no available party members")


func test_available_party_returns_available_only() -> void:
	_setup_initialized_ui()
	var adv1 = _make_adventurer("a1", Enums.AdventurerClass.WARRIOR, "Kira", 3, true)
	var adv2 = _make_adventurer("a2", Enums.AdventurerClass.MAGE, "Alden", 2, false)
	var adv3 = _make_adventurer("a3", Enums.AdventurerClass.RANGER, "Sylvan", 4, true)
	_roster.add_adventurer(adv1)
	_roster.add_adventurer(adv2)
	_roster.add_adventurer(adv3)
	var available: Array = _ui.get_available_party()
	assert_eq(available.size(), 2, "Should return only 2 available adventurers")


func test_available_party_dict_format() -> void:
	_setup_initialized_ui()
	var adv = _make_adventurer("hero1", Enums.AdventurerClass.MAGE, "Lucian", 5, true)
	_roster.add_adventurer(adv)
	var available: Array = _ui.get_available_party()
	assert_eq(available.size(), 1)
	var entry: Dictionary = available[0]
	assert_eq(entry["id"], "hero1")
	assert_eq(entry["name"], "Lucian")
	assert_eq(entry["class"], int(Enums.AdventurerClass.MAGE))
	assert_eq(entry["class_name"], "Mage")
	assert_eq(entry["level"], 5)
	assert_true(entry.has("stats"), "Should include stats")


func test_available_party_no_roster() -> void:
	# Not initialized — _roster is null
	var available: Array = _ui.get_available_party()
	assert_eq(available.size(), 0, "No roster should return empty")


func test_validate_party_valid() -> void:
	_setup_initialized_ui()
	var ids = _add_available_adventurers(3)
	var result: Dictionary = _ui.validate_party(ids)
	assert_true(result["valid"], "Valid party should pass validation")
	assert_eq(result["message"], "Party ready for expedition")


func test_validate_party_empty() -> void:
	_setup_initialized_ui()
	var result: Dictionary = _ui.validate_party([])
	assert_false(result["valid"], "Empty party should fail")
	assert_true(result["message"].find("empty") >= 0, "Message should mention empty")


func test_validate_party_too_many() -> void:
	_setup_initialized_ui()
	var ids = _add_available_adventurers(4)
	ids.append("extra_fake_id")
	var result: Dictionary = _ui.validate_party(ids)
	assert_false(result["valid"], "Party of 5 should fail")
	assert_true(result["message"].find("exceed") >= 0, "Message should mention exceeding limit")


func test_validate_party_nonexistent_member() -> void:
	_setup_initialized_ui()
	_add_available_adventurers(2)
	var result: Dictionary = _ui.validate_party(["adv_001", "ghost_id"])
	assert_false(result["valid"], "Nonexistent member should fail")
	assert_true(result["message"].find("not found") >= 0, "Message should say 'not found'")


func test_validate_party_unavailable_member() -> void:
	_setup_initialized_ui()
	var avail = _make_adventurer("a1", Enums.AdventurerClass.WARRIOR, "Kira", 5, true)
	var unavail = _make_adventurer("a2", Enums.AdventurerClass.MAGE, "Alden", 3, false)
	_roster.add_adventurer(avail)
	_roster.add_adventurer(unavail)
	var result: Dictionary = _ui.validate_party(["a1", "a2"])
	assert_false(result["valid"], "Unavailable member should fail validation")
	assert_true(result["message"].find("unavailable") >= 0 or result["message"].find("Unavailable") >= 0,
		"Message should mention unavailability")


func test_validate_party_duplicate_ids() -> void:
	_setup_initialized_ui()
	_add_available_adventurers(2)
	var result: Dictionary = _ui.validate_party(["adv_001", "adv_001"])
	assert_false(result["valid"], "Duplicate IDs should fail")
	assert_true(result["message"].find("Duplicate") >= 0, "Message should mention duplicate")


func test_validate_party_single_member() -> void:
	_setup_initialized_ui()
	_add_available_adventurers(1)
	var result: Dictionary = _ui.validate_party(["adv_001"])
	assert_true(result["valid"], "Single member party should be valid")


func test_validate_party_max_size_exactly() -> void:
	_setup_initialized_ui()
	var ids = _add_available_adventurers(4)
	var result: Dictionary = _ui.validate_party(ids)
	assert_true(result["valid"], "4-member party should be valid (max)")


func test_validate_party_low_level_warning() -> void:
	_setup_initialized_ui()
	var adv = _make_adventurer("newbie", Enums.AdventurerClass.ROGUE, "Shade", 1, true)
	_roster.add_adventurer(adv)
	var result: Dictionary = _ui.validate_party(["newbie"])
	assert_true(result["valid"], "Low level should still be valid")
	assert_true(result["warnings"].size() > 0, "Should produce a warning for level 1")


# ===========================================================================
# §4: Expedition Result Formatting (~10 tests)
# ===========================================================================

func test_format_empty_result() -> void:
	_setup_initialized_ui()
	var formatted: Dictionary = _ui.format_expedition_result({})
	assert_eq(formatted["status"], "Unknown", "Empty result should show Unknown status")
	assert_eq(formatted["rooms_cleared"], "0/0")
	assert_eq(formatted["xp_earned"], 0)


func test_format_completed_result() -> void:
	_setup_initialized_ui()
	var result = _make_expedition_result(
		Enums.ExpeditionStatus.COMPLETED, 12, 12, 200
	)
	var formatted: Dictionary = _ui.format_expedition_result(result)
	assert_eq(formatted["status"], "Completed")
	assert_eq(formatted["rooms_cleared"], "12/12")
	assert_eq(formatted["xp_earned"], 200)


func test_format_failed_result() -> void:
	_setup_initialized_ui()
	var result = _make_expedition_result(
		Enums.ExpeditionStatus.FAILED, 5, 12, 80
	)
	var formatted: Dictionary = _ui.format_expedition_result(result)
	assert_eq(formatted["status"], "Failed")
	assert_eq(formatted["rooms_cleared"], "5/12")


func test_format_result_with_currency() -> void:
	_setup_initialized_ui()
	var result = _make_expedition_result(
		Enums.ExpeditionStatus.COMPLETED, 10, 10, 100,
		{ Enums.Currency.GOLD: 250, Enums.Currency.ESSENCE: 30 },
	)
	var formatted: Dictionary = _ui.format_expedition_result(result)
	assert_eq(formatted["gold_earned"], 250, "Should extract gold from currency dict")


func test_format_result_with_loot() -> void:
	_setup_initialized_ui()
	var loot: Array = [
		{ "item_id": "iron_sword", "quantity": 1 },
		{ "item_id": "health_potion", "quantity": 3 },
	]
	var result = _make_expedition_result(
		Enums.ExpeditionStatus.COMPLETED, 8, 10, 120,
		{}, loot,
	)
	var formatted: Dictionary = _ui.format_expedition_result(result)
	assert_eq(formatted["loot_items"].size(), 2, "Should format 2 loot items")
	assert_eq(formatted["loot_items"][0]["item_id"], "iron_sword")
	assert_eq(formatted["loot_items"][1]["quantity"], 3)


func test_format_result_party_status_alive() -> void:
	_setup_initialized_ui()
	var result = _make_expedition_result(
		Enums.ExpeditionStatus.COMPLETED, 10, 10, 100,
		{}, [], [],
		{ "warrior_1": 80, "mage_1": 45 },
		[],
	)
	var formatted: Dictionary = _ui.format_expedition_result(result)
	assert_eq(formatted["party_status"].size(), 2)
	assert_eq(formatted["party_status"][0]["status_text"], "Alive")


func test_format_result_party_status_ko() -> void:
	_setup_initialized_ui()
	var result = _make_expedition_result(
		Enums.ExpeditionStatus.FAILED, 5, 10, 60,
		{}, [], [],
		{ "warrior_1": 0, "mage_1": 0 },
		["warrior_1", "mage_1"],
	)
	var formatted: Dictionary = _ui.format_expedition_result(result)
	var ps: Array = formatted["party_status"]
	for entry in ps:
		var e: Dictionary = entry as Dictionary
		assert_true(e["is_ko"], "%s should be KO" % str(e["id"]))
		assert_eq(e["status_text"], "KO")


func test_format_result_partial_clear() -> void:
	_setup_initialized_ui()
	var result = _make_expedition_result(
		Enums.ExpeditionStatus.FAILED, 3, 8, 45,
	)
	var formatted: Dictionary = _ui.format_expedition_result(result)
	assert_eq(formatted["rooms_cleared"], "3/8")
	assert_eq(formatted["status"], "Failed")


func test_format_result_combat_log_creates_room_log() -> void:
	_setup_initialized_ui()
	var combat_log: Array = [
		{
			"room_index": 1,
			"room_type": int(Enums.RoomType.COMBAT),
			"events": [
				{ "attacker": "warrior_1", "target": "enemy_0", "damage": 25, "target_hp": 10 },
			],
		},
		{
			"room_index": 3,
			"room_type": int(Enums.RoomType.BOSS),
			"events": [
				{ "attacker": "warrior_1", "target": "enemy_0", "damage": 50, "target_hp": 0 },
			],
		},
	]
	var result = _make_expedition_result(
		Enums.ExpeditionStatus.COMPLETED, 6, 6, 150,
		{}, [], combat_log,
	)
	var formatted: Dictionary = _ui.format_expedition_result(result)
	assert_eq(formatted["room_log"].size(), 2, "Should produce 2 room log entries")
	assert_eq(formatted["room_log"][0]["room_type"], "Combat")
	assert_eq(formatted["room_log"][1]["room_type"], "Boss")


func test_format_result_zero_xp() -> void:
	_setup_initialized_ui()
	var result = _make_expedition_result(
		Enums.ExpeditionStatus.FAILED, 0, 5, 0,
	)
	var formatted: Dictionary = _ui.format_expedition_result(result)
	assert_eq(formatted["xp_earned"], 0)
	assert_eq(formatted["rooms_cleared"], "0/5")


# ===========================================================================
# §5: Room Log Formatting (~8 tests)
# ===========================================================================

func test_format_room_empty_dict() -> void:
	_setup_initialized_ui()
	var formatted: Dictionary = _ui.format_room_result({})
	assert_eq(formatted["room_type"], "Unknown")
	assert_eq(formatted["cleared"], false)
	assert_eq(formatted["damage_dealt"], 0)
	assert_eq(formatted["damage_taken"], 0)


func test_format_room_combat() -> void:
	_setup_initialized_ui()
	var room_result: Dictionary = {
		"room_type": int(Enums.RoomType.COMBAT),
		"room_index": 2,
		"cleared": true,
		"events": [
			{ "attacker": "warrior_1", "target": "enemy_0", "damage": 30, "target_hp": 5 },
			{ "attacker": "enemy_0", "target": "warrior_1", "damage": 10, "target_hp": 90 },
		],
		"loot": [{ "item_id": "iron_sword", "quantity": 1 }],
	}
	var formatted: Dictionary = _ui.format_room_result(room_result)
	assert_eq(formatted["room_type"], "Combat")
	assert_eq(formatted["room_number"], 2)
	assert_true(formatted["cleared"], "Combat room should be cleared")
	assert_eq(formatted["damage_dealt"], 30, "Party dealt 30 damage")
	assert_eq(formatted["damage_taken"], 10, "Party took 10 damage")
	assert_eq(formatted["loot"].size(), 1)
	assert_eq(formatted["events"].size(), 2)


func test_format_room_treasure() -> void:
	_setup_initialized_ui()
	var room_result: Dictionary = {
		"room_type": int(Enums.RoomType.TREASURE),
		"room_index": 4,
		"cleared": true,
		"events": [],
		"loot": [
			{ "item_id": "gold_ring", "quantity": 1 },
			{ "item_id": "gem", "quantity": 2 },
		],
	}
	var formatted: Dictionary = _ui.format_room_result(room_result)
	assert_eq(formatted["room_type"], "Treasure")
	assert_true(formatted["cleared"])
	assert_eq(formatted["loot"].size(), 2)
	assert_eq(formatted["damage_dealt"], 0, "No combat in treasure room")
	assert_eq(formatted["damage_taken"], 0, "No damage in treasure room")


func test_format_room_rest() -> void:
	_setup_initialized_ui()
	var room_result: Dictionary = {
		"room_type": int(Enums.RoomType.REST),
		"room_index": 3,
		"cleared": true,
		"events": [],
		"loot": [],
	}
	var formatted: Dictionary = _ui.format_room_result(room_result)
	assert_eq(formatted["room_type"], "Rest")
	assert_true(formatted["cleared"])
	assert_eq(formatted["damage_dealt"], 0)
	assert_eq(formatted["damage_taken"], 0)
	assert_eq(formatted["loot"].size(), 0)


func test_format_room_trap() -> void:
	_setup_initialized_ui()
	var room_result: Dictionary = {
		"room_type": int(Enums.RoomType.TRAP),
		"room_index": 5,
		"cleared": true,
		"events": [
			{ "type": "trap_damage", "target": "warrior_1", "damage": 15, "hp_remaining": 85 },
			{ "type": "trap_damage", "target": "mage_1", "damage": 15, "hp_remaining": 55 },
		],
		"loot": [],
	}
	var formatted: Dictionary = _ui.format_room_result(room_result)
	assert_eq(formatted["room_type"], "Trap")
	assert_eq(formatted["damage_taken"], 30, "Total trap damage should be 30")
	assert_eq(formatted["damage_dealt"], 0, "No damage dealt in trap room")
	assert_eq(formatted["events"].size(), 2)


func test_format_room_boss() -> void:
	_setup_initialized_ui()
	var room_result: Dictionary = {
		"room_type": int(Enums.RoomType.BOSS),
		"room_index": 9,
		"cleared": true,
		"events": [
			{ "attacker": "warrior_1", "target": "enemy_0", "damage": 80, "target_hp": 120 },
			{ "attacker": "enemy_0", "target": "warrior_1", "damage": 40, "target_hp": 60 },
			{ "attacker": "warrior_1", "target": "enemy_0", "damage": 120, "target_hp": 0 },
		],
		"loot": [{ "item_id": "legendary_blade", "quantity": 1 }],
	}
	var formatted: Dictionary = _ui.format_room_result(room_result)
	assert_eq(formatted["room_type"], "Boss")
	assert_eq(formatted["damage_dealt"], 200, "Party dealt 80+120=200")
	assert_eq(formatted["damage_taken"], 40, "Party took 40")
	assert_eq(formatted["loot"].size(), 1)
	assert_eq(formatted["events"].size(), 3)


func test_format_room_puzzle_success() -> void:
	_setup_initialized_ui()
	var room_result: Dictionary = {
		"room_type": int(Enums.RoomType.PUZZLE),
		"room_index": 6,
		"cleared": true,
		"events": [
			{ "type": "puzzle_success", "utility": 30, "threshold": 25.0 },
		],
		"loot": [{ "item_id": "puzzle_box", "quantity": 1 }],
	}
	var formatted: Dictionary = _ui.format_room_result(room_result)
	assert_eq(formatted["room_type"], "Puzzle")
	assert_true(formatted["cleared"])
	assert_eq(formatted["damage_taken"], 0, "No damage on puzzle success")
	assert_eq(formatted["events"].size(), 1)
	assert_true(formatted["events"][0].find("solved") >= 0, "Event should mention puzzle solved")


func test_format_room_puzzle_failure() -> void:
	_setup_initialized_ui()
	var room_result: Dictionary = {
		"room_type": int(Enums.RoomType.PUZZLE),
		"room_index": 6,
		"cleared": true,
		"events": [
			{ "type": "puzzle_failure", "utility": 10, "threshold": 25.0, "damage": 4 },
		],
		"loot": [],
	}
	var formatted: Dictionary = _ui.format_room_result(room_result)
	assert_eq(formatted["damage_taken"], 4, "Puzzle failure should record damage")
	assert_true(formatted["events"][0].find("failed") >= 0, "Event should mention puzzle failed")


# ===========================================================================
# §6: Party Power & Difficulty Comparison (~6 tests)
# ===========================================================================

func test_party_power_single_warrior() -> void:
	_setup_initialized_ui()
	var adv = _make_adventurer("w1", Enums.AdventurerClass.WARRIOR, "Kira", 1, true)
	var power: int = _ui.calculate_party_power([adv])
	assert_true(power > 0, "Power should be positive for a valid adventurer")


func test_party_power_increases_with_level() -> void:
	_setup_initialized_ui()
	var adv_low = _make_adventurer("w1", Enums.AdventurerClass.WARRIOR, "Kira", 1, true)
	var adv_high = _make_adventurer("w2", Enums.AdventurerClass.WARRIOR, "Thane", 10, true)
	var power_low: int = _ui.calculate_party_power([adv_low])
	var power_high: int = _ui.calculate_party_power([adv_high])
	assert_true(power_high > power_low, "Higher level should have more power")


func test_party_power_increases_with_party_size() -> void:
	_setup_initialized_ui()
	var adv1 = _make_adventurer("w1", Enums.AdventurerClass.WARRIOR, "Kira", 5, true)
	var adv2 = _make_adventurer("m1", Enums.AdventurerClass.MAGE, "Alden", 5, true)
	var power_solo: int = _ui.calculate_party_power([adv1])
	var power_duo: int = _ui.calculate_party_power([adv1, adv2])
	assert_true(power_duo > power_solo, "Two members should have more power than one")


func test_party_power_empty_array() -> void:
	_setup_initialized_ui()
	var power: int = _ui.calculate_party_power([])
	assert_eq(power, 0, "Empty party should have 0 power")


func test_difficulty_comparison_easy() -> void:
	_setup_initialized_ui()
	var result: Dictionary = _ui.get_difficulty_comparison(5000, 1)
	assert_eq(result["rating"], "Easy", "High power vs low difficulty should be Easy")
	assert_eq(result["color"], "green")


func test_difficulty_comparison_deadly() -> void:
	_setup_initialized_ui()
	var result: Dictionary = _ui.get_difficulty_comparison(10, 20)
	assert_eq(result["rating"], "Deadly", "Very low power vs high difficulty should be Deadly")
	assert_eq(result["color"], "red")


func test_difficulty_comparison_zero_difficulty() -> void:
	_setup_initialized_ui()
	var result: Dictionary = _ui.get_difficulty_comparison(100, 0)
	assert_eq(result["rating"], "Easy", "Zero difficulty should always be Easy")


func test_difficulty_comparison_hard() -> void:
	_setup_initialized_ui()
	# party_power=30, difficulty=1 → scaled_diff=50, ratio=0.6 → Hard (0.5-0.8)
	var result: Dictionary = _ui.get_difficulty_comparison(30, 1)
	assert_eq(result["rating"], "Hard")
	assert_eq(result["color"], "orange")


func test_difficulty_comparison_fair() -> void:
	_setup_initialized_ui()
	# party_power=45, difficulty=1 → scaled_diff=50, ratio=0.9 → Fair (0.8-1.2)
	var result: Dictionary = _ui.get_difficulty_comparison(45, 1)
	assert_eq(result["rating"], "Fair")
	assert_eq(result["color"], "yellow")


# ===========================================================================
# §7: Edge Cases & Robustness (~4 bonus tests)
# ===========================================================================

func test_validate_party_no_roster_initialized() -> void:
	# UI not initialized — roster is null
	var result: Dictionary = _ui.validate_party(["some_id"])
	assert_false(result["valid"], "Should fail without roster")
	assert_true(result["message"].find("Roster") >= 0 or result["message"].find("not initialized") >= 0)


func test_preview_dungeon_all_room_types() -> void:
	_setup_initialized_ui()
	var dungeon = _make_dungeon([
		Enums.RoomType.ENTRANCE,
		Enums.RoomType.COMBAT,
		Enums.RoomType.TREASURE,
		Enums.RoomType.TRAP,
		Enums.RoomType.PUZZLE,
		Enums.RoomType.REST,
		Enums.RoomType.BOSS,
		Enums.RoomType.SECRET,
	], 6)
	var preview: Dictionary = _ui.get_dungeon_preview(dungeon)
	assert_eq(preview["room_count"], 8, "Should have all 8 room types")
	assert_true(preview["has_boss"])
	assert_true(preview["has_secret"])
	var types: Dictionary = preview["room_types"]
	assert_eq(types.size(), 8, "Should have counts for all 8 room types")


func test_format_result_no_currency_key() -> void:
	_setup_initialized_ui()
	var result: Dictionary = {
		"status": Enums.ExpeditionStatus.COMPLETED,
		"rooms_cleared": 5,
		"total_rooms": 5,
		"xp_earned": 50,
		"loot": [],
		"combat_log": [],
		"party_hp": {},
		"adventurers_ko": [],
	}
	var formatted: Dictionary = _ui.format_expedition_result(result)
	assert_eq(formatted["gold_earned"], 0, "Missing currency should default to 0 gold")


func test_party_power_deterministic() -> void:
	_setup_initialized_ui()
	var adv = _make_adventurer("w1", Enums.AdventurerClass.WARRIOR, "Kira", 5, true)
	var power1: int = _ui.calculate_party_power([adv])
	var power2: int = _ui.calculate_party_power([adv])
	assert_eq(power1, power2, "Same input should produce same power")
