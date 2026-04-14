extends GutTest
## Unit tests for DungeonData graph data model.


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_room(idx: int, room_type: Enums.RoomType) -> RoomData:
	var room := RoomData.new()
	room.index = idx
	room.type = room_type
	room.position = Vector2(float(idx) * 3.0, 0.0)
	room.size = Vector2(2.0, 2.0)
	room.difficulty = idx + 1
	room.loot_bias = Enums.Currency.GOLD
	return room


func _make_linear_dungeon(room_count: int, boss_index: int) -> DungeonData:
	## Creates a linear chain: 0-1-2-...-n with optional boss.
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_linear"
	dungeon.element = Enums.Element.FLAME
	dungeon.difficulty = 5
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = boss_index
	for i in range(room_count):
		var rtype: Enums.RoomType = Enums.RoomType.BOSS if i == boss_index else Enums.RoomType.COMBAT
		dungeon.rooms.append(_make_room(i, rtype))
	for i in range(room_count - 1):
		dungeon.edges.append(Vector2i(i, i + 1))
	return dungeon


func _make_branching_dungeon() -> DungeonData:
	## Creates a graph:
	##   0 -- 1 -- 3 (boss)
	##   |         |
	##   2 --------+
	## Shortest path 0->3 is [0, 1, 3] (length 2), not [0, 2, 3] (also length 2, but BFS finds 0-1-3 first).
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_branch"
	dungeon.element = Enums.Element.FROST
	dungeon.difficulty = 3
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = 3
	for i in range(4):
		var rtype: Enums.RoomType = Enums.RoomType.BOSS if i == 3 else Enums.RoomType.COMBAT
		dungeon.rooms.append(_make_room(i, rtype))
	dungeon.edges = [
		Vector2i(0, 1),
		Vector2i(0, 2),
		Vector2i(1, 3),
		Vector2i(2, 3),
	]
	return dungeon


func _make_star_dungeon() -> DungeonData:
	## Room 0 in center, connected to rooms 1..4. Boss at 4.
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_star"
	dungeon.element = Enums.Element.TERRA
	dungeon.difficulty = 4
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = 4
	for i in range(5):
		var rtype: Enums.RoomType = Enums.RoomType.BOSS if i == 4 else Enums.RoomType.COMBAT
		dungeon.rooms.append(_make_room(i, rtype))
	for i in range(1, 5):
		dungeon.edges.append(Vector2i(0, i))
	return dungeon


func _make_single_room_dungeon() -> DungeonData:
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_single"
	dungeon.element = Enums.Element.NONE
	dungeon.difficulty = 1
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = -1
	dungeon.rooms.append(_make_room(0, Enums.RoomType.COMBAT))
	return dungeon


func _make_large_dungeon(count: int) -> DungeonData:
	## Creates a chain of `count` rooms for stress testing.
	return _make_linear_dungeon(count, count - 1)


# ---------------------------------------------------------------------------
# Default Construction
# ---------------------------------------------------------------------------

func test_default_seed_id() -> void:
	var d := DungeonData.new()
	assert_eq(d.seed_id, "")


func test_default_rooms() -> void:
	var d := DungeonData.new()
	assert_eq(d.rooms.size(), 0)


func test_default_edges() -> void:
	var d := DungeonData.new()
	assert_eq(d.edges.size(), 0)


func test_default_entry_room_index() -> void:
	var d := DungeonData.new()
	assert_eq(d.entry_room_index, 0)


func test_default_boss_room_index() -> void:
	var d := DungeonData.new()
	assert_eq(d.boss_room_index, -1)


func test_default_element() -> void:
	var d := DungeonData.new()
	assert_eq(d.element, Enums.Element.NONE)


func test_default_difficulty() -> void:
	var d := DungeonData.new()
	assert_eq(d.difficulty, 1)


# ---------------------------------------------------------------------------
# get_room / get_room_count / get_edge_count / has_boss_room
# ---------------------------------------------------------------------------

func test_get_room_valid() -> void:
	var d := _make_linear_dungeon(3, 2)
	var room: RoomData = d.get_room(1)
	assert_not_null(room)
	assert_eq(room.index, 1)


func test_get_room_out_of_bounds_negative() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_null(d.get_room(-1))


func test_get_room_out_of_bounds_large() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_null(d.get_room(3))


func test_get_room_count() -> void:
	var d := _make_linear_dungeon(5, 4)
	assert_eq(d.get_room_count(), 5)


func test_get_edge_count() -> void:
	var d := _make_linear_dungeon(5, 4)
	assert_eq(d.get_edge_count(), 4)


func test_has_boss_room_true() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_true(d.has_boss_room())


func test_has_boss_room_false() -> void:
	var d := _make_single_room_dungeon()
	assert_false(d.has_boss_room())


# ---------------------------------------------------------------------------
# get_adjacent
# ---------------------------------------------------------------------------

func test_adjacent_linear_start() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(0)
	assert_eq(adj.size(), 1)
	assert_has(adj, 1)


func test_adjacent_linear_middle() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(1)
	assert_eq(adj.size(), 2)
	assert_has(adj, 0)
	assert_has(adj, 2)


func test_adjacent_linear_end() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(2)
	assert_eq(adj.size(), 1)
	assert_has(adj, 1)


func test_adjacent_star_center() -> void:
	var d := _make_star_dungeon()
	var adj: Array[int] = d.get_adjacent(0)
	assert_eq(adj.size(), 4)
	assert_has(adj, 1)
	assert_has(adj, 2)
	assert_has(adj, 3)
	assert_has(adj, 4)


func test_adjacent_star_leaf() -> void:
	var d := _make_star_dungeon()
	var adj: Array[int] = d.get_adjacent(3)
	assert_eq(adj.size(), 1)
	assert_has(adj, 0)


func test_adjacent_out_of_bounds_negative() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(-1)
	assert_eq(adj.size(), 0)


func test_adjacent_out_of_bounds_large() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(99)
	assert_eq(adj.size(), 0)


func test_adjacent_single_room() -> void:
	var d := _make_single_room_dungeon()
	var adj: Array[int] = d.get_adjacent(0)
	assert_eq(adj.size(), 0)


# ---------------------------------------------------------------------------
# get_path_to_boss
# ---------------------------------------------------------------------------

func test_path_to_boss_linear() -> void:
	var d := _make_linear_dungeon(3, 2)
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0, 1, 2])


func test_path_to_boss_star_direct() -> void:
	var d := _make_star_dungeon()
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0, 4])


func test_path_to_boss_branching_shortest() -> void:
	var d := _make_branching_dungeon()
	var path: Array[int] = d.get_path_to_boss()
	# Both [0,1,3] and [0,2,3] are length 2; BFS finds one of them.
	assert_eq(path.size(), 3, "Shortest path should be length 3 (3 nodes)")
	assert_eq(path[0], 0, "Path starts at entry")
	assert_eq(path[path.size() - 1], 3, "Path ends at boss")


func test_path_to_boss_no_boss() -> void:
	var d := _make_single_room_dungeon()
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [])


func test_path_to_boss_single_room_boss() -> void:
	var d := _make_single_room_dungeon()
	d.boss_room_index = 0
	d.rooms[0].type = Enums.RoomType.BOSS
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0])


func test_path_to_boss_five_room_chain() -> void:
	var d := _make_linear_dungeon(5, 4)
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0, 1, 2, 3, 4])


# ---------------------------------------------------------------------------
# get_uncleared_rooms / is_fully_cleared
# ---------------------------------------------------------------------------

func test_uncleared_all_rooms_initially() -> void:
	var d := _make_linear_dungeon(3, 2)
	var uncleared: Array[int] = d.get_uncleared_rooms()
	assert_eq(uncleared.size(), 3)


func test_uncleared_after_partial_clear() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.rooms[0].is_cleared = true
	d.rooms[1].is_cleared = true
	var uncleared: Array[int] = d.get_uncleared_rooms()
	assert_eq(uncleared.size(), 1)
	assert_has(uncleared, 2)


func test_uncleared_all_cleared() -> void:
	var d := _make_linear_dungeon(3, 2)
	for room in d.rooms:
		room.is_cleared = true
	var uncleared: Array[int] = d.get_uncleared_rooms()
	assert_eq(uncleared.size(), 0)


func test_is_fully_cleared_false() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_false(d.is_fully_cleared())


func test_is_fully_cleared_partial() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.rooms[0].is_cleared = true
	d.rooms[1].is_cleared = true
	assert_false(d.is_fully_cleared())


func test_is_fully_cleared_true() -> void:
	var d := _make_linear_dungeon(3, 2)
	for room in d.rooms:
		room.is_cleared = true
	assert_true(d.is_fully_cleared())


func test_is_fully_cleared_single_room() -> void:
	var d := _make_single_room_dungeon()
	assert_false(d.is_fully_cleared())
	d.rooms[0].is_cleared = true
	assert_true(d.is_fully_cleared())


# ---------------------------------------------------------------------------
# validate — positive cases
# ---------------------------------------------------------------------------

func test_validate_linear_dungeon() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_true(d.validate())


func test_validate_branching_dungeon() -> void:
	var d := _make_branching_dungeon()
	assert_true(d.validate())


func test_validate_star_dungeon() -> void:
	var d := _make_star_dungeon()
	assert_true(d.validate())


func test_validate_single_room() -> void:
	var d := _make_single_room_dungeon()
	assert_true(d.validate())


func test_validate_no_boss() -> void:
	var d := _make_linear_dungeon(3, -1)
	# Override: no boss room, all rooms COMBAT
	d.boss_room_index = -1
	for room in d.rooms:
		room.type = Enums.RoomType.COMBAT
	assert_true(d.validate())


# ---------------------------------------------------------------------------
# validate — negative cases
# ---------------------------------------------------------------------------

func test_validate_empty_rooms() -> void:
	var d := DungeonData.new()
	assert_false(d.validate())


func test_validate_entry_out_of_bounds() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.entry_room_index = 10
	assert_false(d.validate())


func test_validate_boss_out_of_bounds() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.boss_room_index = 10
	assert_false(d.validate())


func test_validate_edge_out_of_bounds() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.edges.append(Vector2i(1, 99))
	assert_false(d.validate())


func test_validate_non_canonical_edge() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.edges.append(Vector2i(2, 0))  # 2 > 0, non-canonical
	assert_false(d.validate())


func test_validate_duplicate_edge() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.edges.append(Vector2i(0, 1))  # duplicate of existing edge
	assert_false(d.validate())


func test_validate_self_loop() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.edges.append(Vector2i(1, 1))  # self-loop (also non-canonical since not a < b)
	assert_false(d.validate())


func test_validate_disconnected_graph() -> void:
	var d := DungeonData.new()
	d.seed_id = "test_disconnected"
	d.entry_room_index = 0
	d.boss_room_index = -1
	d.rooms.append(_make_room(0, Enums.RoomType.COMBAT))
	d.rooms.append(_make_room(1, Enums.RoomType.COMBAT))
	# No edges — rooms are disconnected
	assert_false(d.validate())


# ---------------------------------------------------------------------------
# Serialization — DungeonData
# ---------------------------------------------------------------------------

func test_dd_to_dict_has_all_keys() -> void:
	var d := _make_linear_dungeon(3, 2)
	var data: Dictionary = d.to_dict()
	assert_has(data, "seed_id")
	assert_has(data, "rooms")
	assert_has(data, "edges")
	assert_has(data, "entry_room_index")
	assert_has(data, "boss_room_index")
	assert_has(data, "element")
	assert_has(data, "difficulty")


func test_to_dict_rooms_is_array() -> void:
	var d := _make_linear_dungeon(3, 2)
	var data: Dictionary = d.to_dict()
	assert_typeof(data["rooms"], TYPE_ARRAY)
	assert_eq(data["rooms"].size(), 3)


func test_to_dict_edges_format() -> void:
	var d := _make_linear_dungeon(3, 2)
	var data: Dictionary = d.to_dict()
	assert_typeof(data["edges"], TYPE_ARRAY)
	assert_eq(data["edges"].size(), 2)
	assert_eq(data["edges"][0], [0, 1])
	assert_eq(data["edges"][1], [1, 2])


func test_to_dict_element_is_int() -> void:
	var d := _make_linear_dungeon(3, 2)
	var data: Dictionary = d.to_dict()
	assert_typeof(data["element"], TYPE_INT)


func test_round_trip_linear() -> void:
	var original := _make_linear_dungeon(3, 2)
	var restored := DungeonData.from_dict(original.to_dict())
	assert_true(restored.validate(), "Restored dungeon should be valid")
	assert_eq(restored.seed_id, original.seed_id)
	assert_eq(restored.rooms.size(), original.rooms.size())
	assert_eq(restored.edges.size(), original.edges.size())
	assert_eq(restored.entry_room_index, original.entry_room_index)
	assert_eq(restored.boss_room_index, original.boss_room_index)
	assert_eq(restored.element, original.element)
	assert_eq(restored.difficulty, original.difficulty)


func test_round_trip_preserves_room_data() -> void:
	var original := _make_linear_dungeon(3, 2)
	original.rooms[1].is_cleared = true
	original.rooms[1].metadata = {"key": "value"}
	var restored := DungeonData.from_dict(original.to_dict())
	assert_true(restored.rooms[1].is_cleared)
	assert_eq(restored.rooms[1].metadata["key"], "value")


func test_round_trip_preserves_edges() -> void:
	var original := _make_branching_dungeon()
	var restored := DungeonData.from_dict(original.to_dict())
	assert_eq(restored.edges.size(), original.edges.size())
	for i in range(original.edges.size()):
		assert_eq(restored.edges[i], original.edges[i])


func test_round_trip_preserves_positions() -> void:
	var original := _make_linear_dungeon(3, 2)
	original.rooms[0].position = Vector2(1.5, -2.7)
	var restored := DungeonData.from_dict(original.to_dict())
	assert_almost_eq(restored.rooms[0].position.x, 1.5, 0.001)
	assert_almost_eq(restored.rooms[0].position.y, -2.7, 0.001)


func test_from_dict_empty() -> void:
	var restored := DungeonData.from_dict({})
	assert_not_null(restored, "from_dict({}) should not return null")
	assert_eq(restored.seed_id, "")
	assert_eq(restored.rooms.size(), 0)


func test_from_dict_caps_room_count() -> void:
	var data: Dictionary = {
		"seed_id": "overflow_test",
		"rooms": [],
		"edges": [],
		"entry_room_index": 0,
		"boss_room_index": -1,
		"element": 0,
		"difficulty": 1,
	}
	for i in range(150):
		data["rooms"].append({"index": i})
	var restored := DungeonData.from_dict(data)
	assert_true(restored.rooms.size() <= 100, "Room count should be capped at 100")


# ---------------------------------------------------------------------------
# Edge Cases
# ---------------------------------------------------------------------------

func test_single_room_boss_dungeon() -> void:
	var d := _make_single_room_dungeon()
	d.boss_room_index = 0
	d.rooms[0].type = Enums.RoomType.BOSS
	assert_true(d.validate())
	assert_true(d.has_boss_room())
	assert_eq(d.get_path_to_boss(), [0])


func test_fully_connected_four_rooms() -> void:
	var d := DungeonData.new()
	d.seed_id = "full_four"
	d.entry_room_index = 0
	d.boss_room_index = 3
	for i in range(4):
		var rtype: Enums.RoomType = Enums.RoomType.BOSS if i == 3 else Enums.RoomType.COMBAT
		d.rooms.append(_make_room(i, rtype))
	d.edges = [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 3),
	]
	assert_true(d.validate())
	var adj: Array[int] = d.get_adjacent(0)
	assert_eq(adj.size(), 3)
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0, 3])  # Direct connection


func test_large_dungeon_25_rooms() -> void:
	var d := _make_large_dungeon(25)
	assert_true(d.validate())
	assert_eq(d.get_room_count(), 25)
	assert_eq(d.get_edge_count(), 24)
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path.size(), 25)
	assert_eq(path[0], 0)
	assert_eq(path[24], 24)


func test_clearing_rooms_does_not_affect_graph() -> void:
	var d := _make_linear_dungeon(3, 2)
	for room in d.rooms:
		room.is_cleared = true
	assert_true(d.validate())
	assert_eq(d.get_adjacent(1).size(), 2)
	assert_eq(d.get_path_to_boss(), [0, 1, 2])
