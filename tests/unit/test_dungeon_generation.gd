extends "res://tests/unit/test_base.gd"

# Test deterministic dungeon generation
func test_dungeon_determinism():
	var DungeonGenerator = preload("res://src/gdscript/dungeon/dungeon_generator.gd")
	var width = 80
	var height = 60
	var room_count = 6
	var seed = "seed-123"
	var dungeon1 = DungeonGenerator.generate(width, height, room_count, seed)
	var dungeon2 = DungeonGenerator.generate(width, height, room_count, seed)
	assert_eq(dungeon1, dungeon2, "Same seed should produce identical dungeons")

func test_dungeon_variance():
	var DungeonGenerator = preload("res://src/gdscript/dungeon/dungeon_generator.gd")
	var width = 80
	var height = 60
	var room_count = 6
	var seed1 = "seed-123"
	var seed2 = "seed-456"
	var dungeon1 = DungeonGenerator.generate(width, height, room_count, seed1)
	var dungeon2 = DungeonGenerator.generate(width, height, room_count, seed2)
	assert_ne(dungeon1, dungeon2, "Different seeds should produce different dungeons")
