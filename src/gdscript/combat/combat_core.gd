extends Node
class_name CombatCore

# Simple deterministic combat formula and resolution
# damage = max(1, attack - defense) * (1 + crit_multiplier)
# crit chance handled externally; this core accepts flags

func calculate_damage(attack: int, defense: int, is_crit: bool=false, crit_mult: float=1.5) -> int:
	var base = attack - defense
	if base < 1:
		base = 1
	var dmg = float(base) * (is_crit ? crit_mult : 1.0)
	return int(max(1, round(dmg)))

func apply_damage(target_hp:int, damage:int) -> int:
	var nhp = target_hp - damage
	if nhp < 0:
		nhp = 0
	return nhp

func resolve_attack(attacker_attack:int, defender_defense:int, seed, crit_chance: float=0.1) -> Dictionary:
	# Deterministic crit roll using RNGWrapperImpl
	var rng = preload("res://src/gdscript/utils/rng_wrapper_impl.gd").new()
	if typeof(seed) == TYPE_STRING:
		rng.seed_from_string(seed)
	else:
		rng.seed(int(seed))
	var roll = rng.randf()
	var is_crit = roll < crit_chance
	var dmg = calculate_damage(attacker_attack, defender_defense, is_crit)
	rng.free()
	return {"damage": dmg, "is_crit": is_crit}
