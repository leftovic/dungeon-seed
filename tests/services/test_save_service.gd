extends GutTest
## Tests for SaveService — save/load manager with versioned serialization.
##
## These tests exercise round-trip serialization, corruption handling,
## migration, validation, slot management, and edge cases.

const SaveServiceClass = preload("res://src/services/save_service.gd")
const SAVE_DIR: String = "user://saves/"

var service: SaveServiceClass


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _build_valid_state() -> Dictionary:
	return {
		"seeds": [
			{
				"id": "seed_001",
				"type": "fire_oak",
				"planted": true,
				"growth_progress": 0.75,
				"mutations": ["thorny"],
				"planted_at": 1719580000,
				"plot_index": 2,
			}
		],
		"dungeon": {
			"active": true,
			"seed_id": "seed_001",
			"rooms": [
				{"id": "room_01", "type": "entrance", "connections": ["room_02"]},
				{"id": "room_02", "type": "boss", "connections": ["room_01"]},
			],
			"explored_rooms": ["room_01"],
			"loot_table_seed": 48291,
		},
		"adventurers": [
			{
				"id": "adv_001",
				"name": "Thornwick",
				"class": "knight",
				"level": 5,
				"xp": 2400,
				"hp_current": 80,
				"hp_max": 100,
				"equipment": {"weapon": "iron_sword", "armor": "leather_vest", "accessory": null},
				"status": "idle",
			}
		],
		"inventory": {
			"items": {"health_potion": 12, "fire_shard": 3},
			"capacity": 50,
		},
		"wallet": {
			"gold": 1500,
			"gems": 25,
			"essence": 340,
			"dust": 80,
		},
		"loop_state": {
			"idle_timer_seconds": 3600.0,
			"active_expeditions": [],
			"last_tick_timestamp": 1719590400,
			"auto_harvest_enabled": true,
		},
		"settings": {
			"master_volume": 0.8,
			"music_volume": 0.6,
			"sfx_volume": 1.0,
			"screen_shake": true,
			"colorblind_mode": "none",
			"text_size": "medium",
			"auto_save_enabled": true,
			"auto_save_interval_seconds": 300,
		},
	}


func _build_v1_state() -> Dictionary:
	return {
		"version": 1,
		"timestamp": 1719500000,
		"slot": 1,
		"seeds": [{"id": "seed_001", "type": "fire_oak", "planted": true, "growth_progress": 0.5, "mutations": [], "planted_at": 1719400000, "plot_index": 0}],
		"dungeon": {"active": false, "seed_id": "", "rooms": [], "explored_rooms": [], "loot_table_seed": 0},
		"adventurers": [],
		"inventory": {"items": {}, "capacity": 30},
		"player_gold": 750,
		"loop_state": {"idle_timer_seconds": 0.0, "active_expeditions": [], "last_tick_timestamp": 1719500000},
		"settings": {"master_volume": 1.0, "music_volume": 1.0, "sfx_volume": 1.0, "screen_shake": true, "auto_save_enabled": false, "auto_save_interval_seconds": 300},
	}


func _clean_saves() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("saves"):
		return
	var files: PackedStringArray = DirAccess.get_files_at(SAVE_DIR)
	for file_name: String in files:
		DirAccess.remove_absolute(SAVE_DIR + file_name)


func _write_raw_file(path: String, content: String) -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func before_each() -> void:
	service = SaveServiceClass.new()
	_clean_saves()


func after_each() -> void:
	_clean_saves()


# ---------------------------------------------------------------------------
# save_game tests
# ---------------------------------------------------------------------------

func test_save_game_returns_true_on_success() -> void:
	var state: Dictionary = _build_valid_state()
	var result: bool = service.save_game(1, state)
	assert_true(result, "save_game should return true on success")


func test_save_game_creates_file_on_disk() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(1, state)
	assert_true(FileAccess.file_exists(SAVE_DIR + "slot_1.json"), "slot_1.json should exist")


func test_save_game_file_is_valid_json() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(1, state)
	var file: FileAccess = FileAccess.open(SAVE_DIR + "slot_1.json", FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	assert_not_null(parsed, "Saved file should be valid JSON")
	assert_true(parsed is Dictionary, "Parsed JSON should be a Dictionary")


func test_save_game_injects_version() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(1, state)
	var loaded: Dictionary = service.load_game(1)
	assert_eq(loaded["version"], SaveServiceClass.CURRENT_VERSION, "version should be CURRENT_VERSION")


func test_save_game_injects_timestamp() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(1, state)
	var loaded: Dictionary = service.load_game(1)
	assert_true(loaded["timestamp"] is float or loaded["timestamp"] is int, "timestamp should be numeric")
	assert_true(loaded["timestamp"] > 0, "timestamp should be positive")


func test_save_game_injects_slot_number() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(2, state)
	var loaded: Dictionary = service.load_game(2)
	assert_eq(loaded["slot"], 2, "slot should match the save slot argument")


func test_save_game_slot_zero_returns_false() -> void:
	var state: Dictionary = _build_valid_state()
	assert_false(service.save_game(0, state), "slot 0 should be rejected")


func test_save_game_slot_four_returns_false() -> void:
	var state: Dictionary = _build_valid_state()
	assert_false(service.save_game(4, state), "slot 4 should be rejected")


func test_save_game_slot_negative_returns_false() -> void:
	var state: Dictionary = _build_valid_state()
	assert_false(service.save_game(-1, state), "negative slot should be rejected")


func test_save_game_creates_directory_if_missing() -> void:
	_clean_saves()
	var dir: DirAccess = DirAccess.open("user://")
	if dir and dir.dir_exists("saves"):
		dir.remove("saves")
	var state: Dictionary = _build_valid_state()
	var result: bool = service.save_game(1, state)
	assert_true(result, "save should succeed even when saves dir is missing")
	assert_true(FileAccess.file_exists(SAVE_DIR + "slot_1.json"), "file should be created")


func test_save_game_overwrites_existing_save() -> void:
	var state_a: Dictionary = _build_valid_state()
	state_a["wallet"]["gold"] = 100
	service.save_game(1, state_a)
	var state_b: Dictionary = _build_valid_state()
	state_b["wallet"]["gold"] = 9999
	service.save_game(1, state_b)
	var loaded: Dictionary = service.load_game(1)
	assert_eq(loaded["wallet"]["gold"], 9999, "second save should overwrite first")


func test_save_game_does_not_mutate_input_beyond_metadata() -> void:
	var state: Dictionary = _build_valid_state()
	var original_keys: Array = state.keys().duplicate()
	service.save_game(1, state)
	for key: String in original_keys:
		assert_true(state.has(key), "original key '%s' should still exist" % key)


func test_save_game_no_tmp_file_left_on_success() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(1, state)
	assert_false(FileAccess.file_exists(SAVE_DIR + "slot_1.json.tmp"), "tmp file should not exist after success")


# ---------------------------------------------------------------------------
# load_game tests
# ---------------------------------------------------------------------------

func test_load_game_round_trip() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(1, state)
	var loaded: Dictionary = service.load_game(1)
	assert_eq(loaded["wallet"]["gold"], 1500, "gold should round-trip")
	assert_eq(loaded["seeds"].size(), 1, "seeds array should round-trip")
	assert_eq(loaded["seeds"][0]["id"], "seed_001", "seed id should round-trip")
	assert_eq(loaded["adventurers"][0]["name"], "Thornwick", "adventurer name should round-trip")
	assert_eq(loaded["inventory"]["items"]["health_potion"], 12, "inventory should round-trip")
	assert_eq(loaded["settings"]["master_volume"], 0.8, "settings should round-trip")


func test_load_game_empty_slot_returns_empty_dict() -> void:
	var loaded: Dictionary = service.load_game(2)
	assert_true(loaded.is_empty(), "loading empty slot should return {}")


func test_load_game_invalid_json_returns_empty_dict() -> void:
	# Note: Engine JSON parser throws internal errors for invalid JSON
	# These are expected and do not indicate test failure
	_write_raw_file(SAVE_DIR + "slot_1.json", "this is not json {{{")
	var loaded: Dictionary = service.load_game(1)
	assert_true(loaded.is_empty(), "invalid JSON should return {}")


func test_load_game_truncated_json_returns_empty_dict() -> void:
	# Note: Engine JSON parser throws internal errors for truncated JSON
	# These are expected and do not indicate test failure
	_write_raw_file(SAVE_DIR + "slot_1.json", '{"version": 2, "timestamp": 123, "slot": 1, "seeds": [')
	var loaded: Dictionary = service.load_game(1)
	assert_true(loaded.is_empty(), "truncated JSON should return {}")


func test_load_game_json_array_returns_empty_dict() -> void:
	_write_raw_file(SAVE_DIR + "slot_1.json", "[1, 2, 3]")
	var loaded: Dictionary = service.load_game(1)
	assert_true(loaded.is_empty(), "JSON array at root should return {}")


func test_load_game_missing_keys_returns_empty_dict() -> void:
	_write_raw_file(SAVE_DIR + "slot_1.json", '{"version": 2, "timestamp": 100, "slot": 1}')
	var loaded: Dictionary = service.load_game(1)
	assert_true(loaded.is_empty(), "missing required keys should return {}")


func test_load_game_slot_zero_returns_empty_dict() -> void:
	var loaded: Dictionary = service.load_game(0)
	assert_true(loaded.is_empty(), "slot 0 should return {}")


func test_load_game_slot_four_returns_empty_dict() -> void:
	var loaded: Dictionary = service.load_game(4)
	assert_true(loaded.is_empty(), "slot 4 should return {}")


func test_load_game_oversized_file_returns_empty_dict() -> void:
	var big_content: String = '{"version": 2, "padding": "' + "X".repeat(2_000_000) + '"}'
	_write_raw_file(SAVE_DIR + "slot_1.json", big_content)
	var loaded: Dictionary = service.load_game(1)
	assert_true(loaded.is_empty(), "oversized file should return {}")
	# Expect 1 push_error from file size check
	assert_push_error_count(1, "oversized file should trigger push_error")


# ---------------------------------------------------------------------------
# Migration tests
# ---------------------------------------------------------------------------

func test_migrate_v1_to_v2_creates_wallet() -> void:
	var v1_data: Dictionary = _build_v1_state()
	var migrated: Dictionary = service.migrate(v1_data, 1, 2)
	assert_true(migrated.has("wallet"), "migrated data should have wallet")
	assert_eq(migrated["wallet"]["gold"], 750, "wallet.gold should equal old player_gold")
	assert_eq(migrated["wallet"]["gems"], 0, "wallet.gems should default to 0")
	assert_eq(migrated["wallet"]["essence"], 0, "wallet.essence should default to 0")
	assert_eq(migrated["wallet"]["dust"], 0, "wallet.dust should default to 0")


func test_migrate_v1_to_v2_adds_auto_harvest() -> void:
	var v1_data: Dictionary = _build_v1_state()
	var migrated: Dictionary = service.migrate(v1_data, 1, 2)
	assert_true(migrated["loop_state"].has("auto_harvest_enabled"), "should have auto_harvest_enabled")
	assert_false(migrated["loop_state"]["auto_harvest_enabled"], "auto_harvest_enabled should default to false")


func test_migrate_v1_to_v2_adds_colorblind_mode() -> void:
	var v1_data: Dictionary = _build_v1_state()
	var migrated: Dictionary = service.migrate(v1_data, 1, 2)
	assert_eq(migrated["settings"]["colorblind_mode"], "none", "colorblind_mode should default to none")


func test_migrate_v1_to_v2_adds_text_size() -> void:
	var v1_data: Dictionary = _build_v1_state()
	var migrated: Dictionary = service.migrate(v1_data, 1, 2)
	assert_eq(migrated["settings"]["text_size"], "medium", "text_size should default to medium")


func test_migrate_v1_to_v2_updates_version() -> void:
	var v1_data: Dictionary = _build_v1_state()
	var migrated: Dictionary = service.migrate(v1_data, 1, 2)
	assert_eq(migrated["version"], 2, "version should be updated to 2")


func test_migrate_same_version_returns_unchanged() -> void:
	var v2_data: Dictionary = _build_valid_state()
	v2_data["version"] = 2
	var result: Dictionary = service.migrate(v2_data, 2, 2)
	assert_eq(result, v2_data, "same-version migration should return data unchanged")


func test_migrate_higher_from_returns_unchanged() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 3
	var result: Dictionary = service.migrate(data, 3, 2)
	assert_eq(result["version"], 3, "higher from_version should not change data")


func test_migrate_invalid_from_returns_unchanged() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 0
	var result: Dictionary = service.migrate(data, 0, 2)
	assert_eq(result["version"], 0, "invalid from_version should not change data")
	# Expect 1 push_error from invalid from_version
	assert_push_error_count(1, "invalid from_version should trigger push_error")


func test_migrate_idempotent_on_v2_data() -> void:
	var v2_data: Dictionary = _build_valid_state()
	v2_data["version"] = 2
	v2_data["timestamp"] = 1719590400
	v2_data["slot"] = 1
	var before_gold: int = v2_data["wallet"]["gold"]
	service.migrate(v2_data, 1, 2)
	assert_eq(v2_data["wallet"]["gold"], before_gold, "migration should not corrupt existing wallet")


func test_load_game_auto_migrates_v1() -> void:
	var v1_data: Dictionary = _build_v1_state()
	var json_text: String = JSON.stringify(v1_data, "\t")
	_write_raw_file(SAVE_DIR + "slot_1.json", json_text)
	var loaded: Dictionary = service.load_game(1)
	assert_false(loaded.is_empty(), "v1 save should load successfully after migration")
	assert_eq(loaded["version"], SaveServiceClass.CURRENT_VERSION, "version should be migrated to current")
	assert_true(loaded.has("wallet"), "wallet should exist after migration")


# ---------------------------------------------------------------------------
# Validation tests
# ---------------------------------------------------------------------------

func test_validate_valid_data_returns_true() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 2
	data["timestamp"] = 1719590400
	data["slot"] = 1
	assert_true(service._validate(data), "valid data should pass validation")


func test_validate_missing_version_returns_false() -> void:
	var data: Dictionary = _build_valid_state()
	data["timestamp"] = 100
	data["slot"] = 1
	data.erase("version")
	assert_false(service._validate(data), "missing version should fail")


func test_validate_missing_seeds_returns_false() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 2
	data["timestamp"] = 100
	data["slot"] = 1
	data.erase("seeds")
	assert_false(service._validate(data), "missing seeds should fail")


func test_validate_seeds_not_array_returns_false() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 2
	data["timestamp"] = 100
	data["slot"] = 1
	data["seeds"] = "not an array"
	assert_false(service._validate(data), "seeds as string should fail")


func test_validate_negative_timestamp_returns_false() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 2
	data["timestamp"] = -100
	data["slot"] = 1
	assert_false(service._validate(data), "negative timestamp should fail")


func test_validate_slot_zero_returns_false() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 2
	data["timestamp"] = 100
	data["slot"] = 0
	assert_false(service._validate(data), "slot 0 should fail")


func test_validate_slot_too_high_returns_false() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 2
	data["timestamp"] = 100
	data["slot"] = 99
	assert_false(service._validate(data), "slot 99 should fail")


func test_validate_inventory_missing_items_returns_false() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 2
	data["timestamp"] = 100
	data["slot"] = 1
	data["inventory"] = {"capacity": 50}
	assert_false(service._validate(data), "inventory without items should fail")


func test_validate_version_too_high_returns_false() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 999
	data["timestamp"] = 100
	data["slot"] = 1
	assert_false(service._validate(data), "version 999 should fail")


func test_validate_version_zero_returns_false() -> void:
	var data: Dictionary = _build_valid_state()
	data["version"] = 0
	data["timestamp"] = 100
	data["slot"] = 1
	assert_false(service._validate(data), "version 0 should fail")


# ---------------------------------------------------------------------------
# Slot management tests
# ---------------------------------------------------------------------------

func test_list_slots_empty_returns_three_entries() -> void:
	var slots: Array[Dictionary] = service.list_slots()
	assert_eq(slots.size(), 3, "should return exactly 3 entries")
	for entry: Dictionary in slots:
		assert_false(entry["exists"], "all slots should show as not existing")
		assert_eq(entry["timestamp"], 0, "timestamp should be 0 for empty slots")


func test_list_slots_with_one_save() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(2, state)
	var slots: Array[Dictionary] = service.list_slots()
	assert_false(slots[0]["exists"], "slot 1 should not exist")
	assert_true(slots[1]["exists"], "slot 2 should exist")
	assert_false(slots[2]["exists"], "slot 3 should not exist")
	assert_true(slots[1]["timestamp"] > 0, "slot 2 timestamp should be positive")


func test_list_slots_corrupted_file_shows_not_exists() -> void:
	# Note: Engine JSON parser throws internal errors for corrupted JSON
	# These are expected and do not indicate test failure
	_write_raw_file(SAVE_DIR + "slot_1.json", "corrupted garbage data not json")
	var slots: Array[Dictionary] = service.list_slots()
	assert_false(slots[0]["exists"], "corrupted slot should show as not existing")


func test_delete_slot_removes_file() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(1, state)
	assert_true(FileAccess.file_exists(SAVE_DIR + "slot_1.json"), "file should exist before delete")
	service.delete_slot(1)
	assert_false(FileAccess.file_exists(SAVE_DIR + "slot_1.json"), "file should not exist after delete")


func test_delete_slot_idempotent() -> void:
	var result: bool = service.delete_slot(1)
	assert_true(result, "deleting non-existent slot should return true")


func test_delete_slot_out_of_range_returns_false() -> void:
	assert_false(service.delete_slot(0), "slot 0 should return false")
	assert_false(service.delete_slot(4), "slot 4 should return false")


func test_delete_slot_removes_tmp_file() -> void:
	_write_raw_file(SAVE_DIR + "slot_1.json.tmp", "leftover temp data")
	service.delete_slot(1)
	assert_false(FileAccess.file_exists(SAVE_DIR + "slot_1.json.tmp"), "tmp file should be cleaned up")


func test_delete_then_list_shows_empty() -> void:
	var state: Dictionary = _build_valid_state()
	service.save_game(1, state)
	service.delete_slot(1)
	var slots: Array[Dictionary] = service.list_slots()
	assert_false(slots[0]["exists"], "deleted slot should show as not existing")


# ---------------------------------------------------------------------------
# Slot independence tests
# ---------------------------------------------------------------------------

func test_slots_are_independent() -> void:
	var state_a: Dictionary = _build_valid_state()
	state_a["wallet"]["gold"] = 111
	service.save_game(1, state_a)
	var state_b: Dictionary = _build_valid_state()
	state_b["wallet"]["gold"] = 222
	service.save_game(2, state_b)
	var state_c: Dictionary = _build_valid_state()
	state_c["wallet"]["gold"] = 333
	service.save_game(3, state_c)
	var loaded_a: Dictionary = service.load_game(1)
	var loaded_b: Dictionary = service.load_game(2)
	var loaded_c: Dictionary = service.load_game(3)
	assert_eq(loaded_a["wallet"]["gold"], 111, "slot 1 should have 111 gold")
	assert_eq(loaded_b["wallet"]["gold"], 222, "slot 2 should have 222 gold")
	assert_eq(loaded_c["wallet"]["gold"], 333, "slot 3 should have 333 gold")


func test_overwrite_one_slot_does_not_affect_others() -> void:
	var state: Dictionary = _build_valid_state()
	state["wallet"]["gold"] = 500
	service.save_game(1, state)
	service.save_game(2, state)
	var updated_state: Dictionary = _build_valid_state()
	updated_state["wallet"]["gold"] = 9999
	service.save_game(1, updated_state)
	var loaded_2: Dictionary = service.load_game(2)
	assert_eq(loaded_2["wallet"]["gold"], 500, "slot 2 should be unaffected by slot 1 overwrite")
