extends GutTest
## Unit tests for RoomData data model.


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_room(idx: int, room_type: Enums.RoomType, pos: Vector2, sz: Vector2,
		diff: int, bias: Enums.Currency, cleared: bool,
		meta: Dictionary) -> RoomData:
	var room := RoomData.new()
	room.index = idx
	room.type = room_type
	room.position = pos
	room.size = sz
	room.difficulty = diff
	room.loot_bias = bias
	room.is_cleared = cleared
	room.metadata = meta
	return room


func _make_default_room() -> RoomData:
	return RoomData.new()


# ---------------------------------------------------------------------------
# Default Construction
# ---------------------------------------------------------------------------

func test_default_index() -> void:
	var room := _make_default_room()
	assert_eq(room.index, 0, "Default index should be 0")


func test_default_type() -> void:
	var room := _make_default_room()
	assert_eq(room.type, Enums.RoomType.COMBAT, "Default type should be COMBAT")


func test_default_position() -> void:
	var room := _make_default_room()
	assert_eq(room.position, Vector2.ZERO, "Default position should be ZERO")


func test_default_size() -> void:
	var room := _make_default_room()
	assert_eq(room.size, Vector2(1.0, 1.0), "Default size should be (1,1)")


func test_default_difficulty() -> void:
	var room := _make_default_room()
	assert_eq(room.difficulty, 1, "Default difficulty should be 1")


func test_default_loot_bias() -> void:
	var room := _make_default_room()
	assert_eq(room.loot_bias, Enums.Currency.GOLD, "Default loot_bias should be GOLD")


func test_default_is_cleared() -> void:
	var room := _make_default_room()
	assert_false(room.is_cleared, "Default is_cleared should be false")


func test_default_metadata() -> void:
	var room := _make_default_room()
	assert_eq(room.metadata, {}, "Default metadata should be empty dict")


# ---------------------------------------------------------------------------
# Property Assignment
# ---------------------------------------------------------------------------

func test_set_index() -> void:
	var room := _make_default_room()
	room.index = 7
	assert_eq(room.index, 7)


func test_set_type() -> void:
	var room := _make_default_room()
	room.type = Enums.RoomType.BOSS
	assert_eq(room.type, Enums.RoomType.BOSS)


func test_set_position() -> void:
	var room := _make_default_room()
	room.position = Vector2(10.5, -3.2)
	assert_almost_eq(room.position.x, 10.5, 0.001)
	assert_almost_eq(room.position.y, -3.2, 0.001)


func test_set_size() -> void:
	var room := _make_default_room()
	room.size = Vector2(4.0, 3.0)
	assert_eq(room.size, Vector2(4.0, 3.0))


func test_set_difficulty() -> void:
	var room := _make_default_room()
	room.difficulty = 10
	assert_eq(room.difficulty, 10)


func test_set_loot_bias() -> void:
	var room := _make_default_room()
	room.loot_bias = Enums.Currency.ESSENCE
	assert_eq(room.loot_bias, Enums.Currency.ESSENCE)


func test_set_is_cleared() -> void:
	var room := _make_default_room()
	room.is_cleared = true
	assert_true(room.is_cleared)


func test_set_metadata() -> void:
	var room := _make_default_room()
	room.metadata = {"trap_type": "spike", "damage": 15}
	assert_eq(room.metadata["trap_type"], "spike")
	assert_eq(room.metadata["damage"], 15)


# ---------------------------------------------------------------------------
# Convenience Methods
# ---------------------------------------------------------------------------

func test_is_combat_true() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_true(room.is_combat())


func test_is_combat_false_for_boss() -> void:
	var room := _make_room(0, Enums.RoomType.BOSS, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_false(room.is_combat())


func test_is_boss_true() -> void:
	var room := _make_room(0, Enums.RoomType.BOSS, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_true(room.is_boss())


func test_is_boss_false_for_combat() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_false(room.is_boss())


func test_is_rest_true() -> void:
	var room := _make_room(0, Enums.RoomType.REST, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_true(room.is_rest())


func test_is_rest_false_for_trap() -> void:
	var room := _make_room(0, Enums.RoomType.TRAP, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_false(room.is_rest())


# ---------------------------------------------------------------------------
# Serialization — to_dict
# ---------------------------------------------------------------------------

func test_to_dict_has_all_keys() -> void:
	var room := _make_default_room()
	var d: Dictionary = room.to_dict()
	assert_has(d, "index")
	assert_has(d, "type")
	assert_has(d, "position")
	assert_has(d, "size")
	assert_has(d, "difficulty")
	assert_has(d, "loot_bias")
	assert_has(d, "is_cleared")
	assert_has(d, "metadata")


func test_to_dict_type_is_int() -> void:
	var room := _make_room(0, Enums.RoomType.TREASURE, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	var d: Dictionary = room.to_dict()
	assert_typeof(d["type"], TYPE_INT)


func test_to_dict_position_is_dict() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2(5.5, 3.2), Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	var d: Dictionary = room.to_dict()
	assert_typeof(d["position"], TYPE_DICTIONARY)
	assert_almost_eq(float(d["position"]["x"]), 5.5, 0.001)
	assert_almost_eq(float(d["position"]["y"]), 3.2, 0.001)


func test_to_dict_size_is_dict() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2.ZERO, Vector2(2.0, 3.0), 1, Enums.Currency.GOLD, false, {})
	var d: Dictionary = room.to_dict()
	assert_typeof(d["size"], TYPE_DICTIONARY)
	assert_almost_eq(float(d["size"]["x"]), 2.0, 0.001)
	assert_almost_eq(float(d["size"]["y"]), 3.0, 0.001)


func test_to_dict_loot_bias_is_int() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.ESSENCE, false, {})
	var d: Dictionary = room.to_dict()
	assert_typeof(d["loot_bias"], TYPE_INT)


func test_to_dict_metadata_preserved() -> void:
	var meta := {"boss_id": "flame_warden", "phases": [1, 2, 3]}
	var room := _make_room(0, Enums.RoomType.BOSS, Vector2.ZERO, Vector2.ONE, 8, Enums.Currency.FRAGMENTS, false, meta)
	var d: Dictionary = room.to_dict()
	assert_eq(d["metadata"]["boss_id"], "flame_warden")
	assert_eq(d["metadata"]["phases"], [1, 2, 3])


# ---------------------------------------------------------------------------
# Serialization — from_dict Round-Trip
# ---------------------------------------------------------------------------

func test_round_trip_default() -> void:
	var original := _make_default_room()
	var restored := RoomData.from_dict(original.to_dict())
	assert_eq(restored.index, original.index)
	assert_eq(restored.type, original.type)
	assert_eq(restored.position, original.position)
	assert_eq(restored.size, original.size)
	assert_eq(restored.difficulty, original.difficulty)
	assert_eq(restored.loot_bias, original.loot_bias)
	assert_eq(restored.is_cleared, original.is_cleared)
	assert_eq(restored.metadata, original.metadata)


func test_round_trip_custom() -> void:
	var original := _make_room(5, Enums.RoomType.PUZZLE, Vector2(10.0, -5.0),
		Vector2(3.0, 2.0), 7, Enums.Currency.ESSENCE, true,
		{"puzzle_id": "slider_01", "time_limit": 30.0})
	var restored := RoomData.from_dict(original.to_dict())
	assert_eq(restored.index, 5)
	assert_eq(restored.type, Enums.RoomType.PUZZLE)
	assert_almost_eq(restored.position.x, 10.0, 0.001)
	assert_almost_eq(restored.position.y, -5.0, 0.001)
	assert_almost_eq(restored.size.x, 3.0, 0.001)
	assert_almost_eq(restored.size.y, 2.0, 0.001)
	assert_eq(restored.difficulty, 7)
	assert_eq(restored.loot_bias, Enums.Currency.ESSENCE)
	assert_true(restored.is_cleared)
	assert_eq(restored.metadata["puzzle_id"], "slider_01")
	assert_almost_eq(float(restored.metadata["time_limit"]), 30.0, 0.001)


func test_from_dict_empty_dict() -> void:
	var restored := RoomData.from_dict({})
	assert_not_null(restored, "from_dict({}) should not return null")
	assert_eq(restored.index, 0)
	assert_eq(restored.type, Enums.RoomType.COMBAT)
	assert_false(restored.is_cleared)
