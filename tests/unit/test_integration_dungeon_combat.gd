extends "res://tests/unit/test_base.gd"

func test_encounter_determinism():
	var DungeonGenerator = preload("res://src/gdscript/dungeon/dungeon_generator.gd")
	var CombatCore = preload("res://src/gdscript/combat/combat_core.gd")
	# Generate dungeon and place two actors deterministically
	var dungeon = DungeonGenerator.generate(50, 40, 4, "enc-seed")
	# Place actor A in first room center, B in second room center
	var r1 = dungeon.rooms[0]
	var r2 = dungeon.rooms[1]
	var a_pos = {"x": r1.x + int(r1.w/2), "y": r1.y + int(r1.h/2)}
	var b_pos = {"x": r2.x + int(r2.w/2), "y": r2.y + int(r2.h/2)}
	# Actor stats
	var a_attack = 10
	var a_hp = 30
	var b_def = 2
	var b_hp = 20
	# Resolve an attack from A->B with deterministic seed
	var res1 = CombatCore.resolve_attack(a_attack, b_def, "enc-seed-action", 0.1)
	var b_hp_after = CombatCore.apply_damage(b_hp, res1.damage)
	# Repeat with same seed should yield same result
	var res2 = CombatCore.resolve_attack(a_attack, b_def, "enc-seed-action", 0.1)
	var b_hp_after2 = CombatCore.apply_damage(b_hp, res2.damage)
	assert_eq(res1, res2, "Combat resolution should be deterministic for same seed")
	assert_eq(b_hp_after, b_hp_after2, "HP after damage should match for same seed")
