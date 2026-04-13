extends "res://tests/unit/test_base.gd"

func test_damage_formula_basic():
	var CombatCore = preload("res://src/gdscript/combat/combat_core.gd")
	var dmg = CombatCore.calculate_damage(10, 3)
	assert_eq(dmg, 7, "Damage should be attack - defense")

func test_damage_floor():
	var CombatCore = preload("res://src/gdscript/combat/combat_core.gd")
	var dmg = CombatCore.calculate_damage(2, 10)
	assert_eq(dmg, 1, "Damage floor should be 1")

func test_resolve_attack_deterministic():
	var CombatCore = preload("res://src/gdscript/combat/combat_core.gd")
	var res1 = CombatCore.resolve_attack(12, 4, "seed-abc", 0.0)
	var res2 = CombatCore.resolve_attack(12, 4, "seed-abc", 0.0)
	assert_eq(res1, res2, "Deterministic resolve should match for same seed and crit chance")

func test_resolve_attack_crit():
	var CombatCore = preload("res://src/gdscript/combat/combat_core.gd")
	var res = CombatCore.resolve_attack(20, 5, "seed-crit", 1.0)
	assert(res.is_crit == true)
	assert(res.damage > 0)
