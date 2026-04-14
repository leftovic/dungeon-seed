class_name DungeonData
extends RefCounted
## A procedurally generated dungeon represented as a connected graph.
##
## Rooms are stored as an indexed array. Edges are stored as Vector2i pairs
## with canonical ordering (a < b). Provides graph traversal operations,
## validation, and JSON-compatible serialization.


## The seed identifier that produced this dungeon.
var seed_id: String = ""

## All rooms in the dungeon, indexed by position in this array.
var rooms: Array[RoomData] = []

## Undirected edges connecting rooms. Each Vector2i(a, b) has a < b.
var edges: Array[Vector2i] = []

## Index of the room where expeditions begin.
var entry_room_index: int = 0

## Index of the boss room, or -1 if no boss exists.
var boss_room_index: int = -1

## The elemental affinity inherited from the seed.
var element: Enums.Element = Enums.Element.NONE

## Global difficulty baseline computed from seed rarity and phase.
var difficulty: int = 1

## Maximum room count accepted by from_dict() to prevent memory abuse.
const MAX_ROOM_COUNT: int = 100

## Maximum edge count accepted by from_dict() to prevent memory abuse.
const MAX_EDGE_COUNT: int = 500


## Returns all room indices directly connected to the given room via edges.
## Returns an empty array if room_index is out of bounds.
func get_adjacent(room_index: int) -> Array[int]:
	var result: Array[int] = []
	if room_index < 0 or room_index >= rooms.size():
		return result
	for edge in edges:
		if edge.x == room_index:
			result.append(edge.y)
		elif edge.y == room_index:
			result.append(edge.x)
	return result


## Returns the shortest path from entry_room_index to boss_room_index
## as an ordered array of room indices (including both endpoints).
## Returns an empty array if there is no boss room or the boss is unreachable.
func get_path_to_boss() -> Array[int]:
	if boss_room_index < 0 or boss_room_index >= rooms.size():
		return []
	if entry_room_index == boss_room_index:
		return [entry_room_index]
	# BFS
	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[int] = []
	queue.append(entry_room_index)
	visited[entry_room_index] = true
	var found: bool = false
	while queue.size() > 0:
		var current: int = queue[0]
		queue.remove_at(0)
		if current == boss_room_index:
			found = true
			break
		var neighbors: Array[int] = get_adjacent(current)
		for neighbor in neighbors:
			if not visited.has(neighbor):
				visited[neighbor] = true
				parent[neighbor] = current
				queue.append(neighbor)
	if not found:
		return []
	# Reconstruct path from boss back to entry
	var path: Array[int] = []
	var step: int = boss_room_index
	while step != entry_room_index:
		path.append(step)
		step = parent[step]
	path.append(entry_room_index)
	path.reverse()
	return path


## Returns indices of all rooms that have not been cleared.
func get_uncleared_rooms() -> Array[int]:
	var result: Array[int] = []
	for i in range(rooms.size()):
		if not rooms[i].is_cleared:
			result.append(i)
	return result


## Returns true only when every room in the dungeon has been cleared.
func is_fully_cleared() -> bool:
	for room in rooms:
		if not room.is_cleared:
			return false
	return true


## Returns the RoomData at the given index, or null if out of bounds.
func get_room(idx: int) -> RoomData:
	if idx < 0 or idx >= rooms.size():
		return null
	return rooms[idx]


## Returns the total number of rooms.
func get_room_count() -> int:
	return rooms.size()


## Returns the total number of edges.
func get_edge_count() -> int:
	return edges.size()


## Returns true if a boss room is designated and its index is valid.
func has_boss_room() -> bool:
	return boss_room_index >= 0 and boss_room_index < rooms.size()


## Validates all graph invariants. Returns true if the dungeon is well-formed.
## Checks: non-empty rooms, valid entry/boss indices, valid edges, canonical
## ordering, no duplicates, no self-loops, connectivity, boss reachability.
func validate() -> bool:
	# At least one room
	if rooms.size() == 0:
		return false
	# Entry room index valid
	if entry_room_index < 0 or entry_room_index >= rooms.size():
		return false
	# Boss room index valid or sentinel
	if boss_room_index != -1:
		if boss_room_index < 0 or boss_room_index >= rooms.size():
			return false
	# Edge validation
	var seen_edges: Dictionary = {}
	for edge in edges:
		# Self-loop check
		if edge.x == edge.y:
			return false
		# Canonical ordering check
		if edge.x >= edge.y:
			return false
		# Bounds check
		if edge.x < 0 or edge.y >= rooms.size():
			return false
		# Duplicate check
		var key: Vector2i = edge
		if seen_edges.has(key):
			return false
		seen_edges[key] = true
	# Connectivity check — BFS from entry must reach all rooms
	var visited: Dictionary = {}
	var queue: Array[int] = []
	queue.append(entry_room_index)
	visited[entry_room_index] = true
	while queue.size() > 0:
		var current: int = queue[0]
		queue.remove_at(0)
		var neighbors: Array[int] = get_adjacent(current)
		for neighbor in neighbors:
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	if visited.size() != rooms.size():
		return false
	# Boss reachability (already guaranteed by full connectivity, but explicit check)
	if boss_room_index >= 0 and not visited.has(boss_room_index):
		return false
	return true


## Serializes the entire dungeon to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
	var rooms_array: Array = []
	for room in rooms:
		rooms_array.append(room.to_dict())
	var edges_array: Array = []
	for edge in edges:
		edges_array.append([edge.x, edge.y])
	return {
		"seed_id": seed_id,
		"rooms": rooms_array,
		"edges": edges_array,
		"entry_room_index": entry_room_index,
		"boss_room_index": boss_room_index,
		"element": int(element),
		"difficulty": difficulty,
	}


## Constructs a DungeonData from a Dictionary. Uses safe defaults for missing keys.
## Caps room count at MAX_ROOM_COUNT and edge count at MAX_EDGE_COUNT.
static func from_dict(data: Dictionary) -> DungeonData:
	var dungeon := DungeonData.new()
	dungeon.seed_id = str(data.get("seed_id", ""))
	dungeon.entry_room_index = int(data.get("entry_room_index", 0))
	dungeon.boss_room_index = int(data.get("boss_room_index", -1))
	dungeon.element = int(data.get("element", 0)) as Enums.Element
	dungeon.difficulty = int(data.get("difficulty", 1))
	# Deserialize rooms with cap
	var raw_rooms: Variant = data.get("rooms", [])
	if raw_rooms is Array:
		var count: int = mini(raw_rooms.size(), MAX_ROOM_COUNT)
		for i in range(count):
			var room_val: Variant = raw_rooms[i]
			if room_val is Dictionary:
				dungeon.rooms.append(RoomData.from_dict(room_val))
			else:
				dungeon.rooms.append(RoomData.new())
	# Deserialize edges with cap
	var raw_edges: Variant = data.get("edges", [])
	if raw_edges is Array:
		var count: int = mini(raw_edges.size(), MAX_EDGE_COUNT)
		for i in range(count):
			var edge_val: Variant = raw_edges[i]
			if edge_val is Array and edge_val.size() >= 2:
				dungeon.edges.append(Vector2i(int(edge_val[0]), int(edge_val[1])))
	return dungeon
