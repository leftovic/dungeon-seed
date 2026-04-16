class_name RoomData
extends RefCounted
## A single room node in a dungeon graph.
##
## Carries type, spatial layout, difficulty, loot weighting, clearance state,
## and an extensible metadata dictionary. Owned by DungeonData.


## The index of this room in the parent DungeonData.rooms array.
var index: int = 0

## The functional type of this room (combat, treasure, trap, etc.).
var type: Enums.RoomType = Enums.RoomType.COMBAT

## Abstract 2D position for map layout. Not pixel coordinates.
var position: Vector2 = Vector2.ZERO

## Abstract 2D dimensions for map layout.
var size: Vector2 = Vector2(1.0, 1.0)

## Encounter difficulty rating. Higher means harder enemies/traps.
var difficulty: int = 1

## Currency weight distribution for this room's drops. Maps Enums.Currency -> float weight.
var loot_bias: Dictionary = {}

## Whether this room has been completed during the current expedition.
var is_cleared: bool = false

## Extensible room-specific data (trap config, puzzle ID, boss phases, etc.).
var metadata: Dictionary = {}


## Returns true if this room is a standard combat encounter.
func is_combat() -> bool:
	return type == Enums.RoomType.COMBAT


## Returns true if this room is the dungeon boss.
func is_boss() -> bool:
	return type == Enums.RoomType.BOSS


## Returns true if this room is a rest/recovery room.
func is_rest() -> bool:
	return type == Enums.RoomType.REST


## Serializes this room to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
	return {
		"index": index,
		"type": int(type),
		"position": {"x": position.x, "y": position.y},
		"size": {"x": size.x, "y": size.y},
		"difficulty": difficulty,
		"loot_bias": loot_bias.duplicate(),
		"is_cleared": is_cleared,
		"metadata": metadata.duplicate(true),
	}


## Constructs a RoomData from a Dictionary. Uses safe defaults for missing keys.
static func from_dict(data: Dictionary) -> RoomData:
	var room := RoomData.new()
	room.index = int(data.get("index", 0))
	room.type = int(data.get("type", 0)) as Enums.RoomType
	var pos_data: Variant = data.get("position", {})
	if pos_data is Dictionary:
		room.position = Vector2(
			float(pos_data.get("x", 0.0)),
			float(pos_data.get("y", 0.0))
		)
	var size_data: Variant = data.get("size", {})
	if size_data is Dictionary:
		room.size = Vector2(
			float(size_data.get("x", 1.0)),
			float(size_data.get("y", 1.0))
		)
	room.difficulty = int(data.get("difficulty", 1))
	var bias_val: Variant = data.get("loot_bias", {})
	if bias_val is Dictionary:
		room.loot_bias = (bias_val as Dictionary).duplicate()
	else:
		room.loot_bias = {}
	room.is_cleared = bool(data.get("is_cleared", false))
	var meta_val: Variant = data.get("metadata", {})
	if meta_val is Dictionary:
		room.metadata = (meta_val as Dictionary).duplicate(true)
	else:
		room.metadata = {}
	return room
