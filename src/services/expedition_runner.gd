extends RefCounted
## Deterministic room-by-room expedition resolver.
## Takes a party of adventurers through a dungeon graph, resolving each room.
## All randomness uses DeterministicRNG for reproducibility.

const MAX_COMBAT_ROUNDS: int = 50
const REST_HEAL_PERCENT: float = 0.30
const BETWEEN_ROOM_HEAL_PERCENT: float = 0.05
const BOSS_STAT_MULTIPLIER: float = 2.0
const CRIT_BASE_CHANCE: float = 0.05
const CRIT_MULTIPLIER: float = 1.5
const DAMAGE_VARIANCE_MIN: float = 0.9
const DAMAGE_VARIANCE_MAX: float = 1.1
const TRAP_DAMAGE_MULTIPLIER: int = 5
const PUZZLE_CHECK_THRESHOLD: float = 0.5
const BASE_XP_PER_ENEMY: int = 15
const ELITE_XP_MULTIPLIER: float = 2.5
const BOSS_XP_MULTIPLIER: float = 5.0
const ROOM_CLEAR_XP: int = 5

const ELEMENT_ADVANTAGE: Dictionary = {
	Enums.Element.TERRA: Enums.Element.FROST,
	Enums.Element.FROST: Enums.Element.FLAME,
	Enums.Element.FLAME: Enums.Element.TERRA,
	Enums.Element.ARCANE: Enums.Element.SHADOW,
	Enums.Element.SHADOW: Enums.Element.ARCANE,
}

const ARMOR_MULTIPLIERS: Dictionary = {
	Enums.AdventurerClass.WARRIOR: 1.0,
	Enums.AdventurerClass.SENTINEL: 1.0,
	Enums.AdventurerClass.RANGER: 0.7,
	Enums.AdventurerClass.ALCHEMIST: 0.7,
	Enums.AdventurerClass.MAGE: 0.4,
	Enums.AdventurerClass.ROGUE: 0.4,
}

const ENEMY_PREFIXES: Array[String] = [
	"Twisted", "Shadow", "Corrupted", "Wild", "Ancient",
	"Venomous", "Spectral", "Feral", "Cursed", "Enraged",
]

const ENEMY_TYPES: Array[String] = [
	"Slime", "Goblin", "Skeleton", "Wolf", "Spider",
	"Wraith", "Golem", "Imp", "Drake", "Bandit",
]


# ===========================================================================
# Public Methods
# ===========================================================================

func run_expedition(
	dungeon: DungeonData,
	party: Array,
	rng: DeterministicRNG,
	loot_engine: RefCounted
) -> Dictionary:
	if dungeon == null or party == null or party.is_empty():
		return _make_result(Enums.ExpeditionStatus.FAILED, 0, 0)

	if dungeon.rooms == null or dungeon.rooms.is_empty():
		return _make_result(Enums.ExpeditionStatus.FAILED, 0, 0)

	var path: Array[int] = dungeon.get_path_to_boss()
	if path.is_empty():
		# No boss or unreachable — traverse all rooms from entry
		path = [dungeon.entry_room_index]

	var party_state: Dictionary = _build_party_state(party)
	var total_loot: Array[Dictionary] = []
	var total_currency: Dictionary = {}
	var total_xp: int = 0
	var combat_log: Array[Dictionary] = []
	var rooms_cleared: int = 0

	for i in range(path.size()):
		var room_idx: int = path[i]
		var room: RoomData = dungeon.get_room(room_idx)
		if room == null:
			continue

		if i > 0:
			_apply_between_room_healing(party_state)

		var room_result: Dictionary = resolve_room(
			room, party_state, rng, loot_engine, dungeon.element
		)

		if room_result.get("cleared", false):
			rooms_cleared += 1
			room.is_cleared = true

		# Accumulate loot
		var room_loot: Variant = room_result.get("loot", [])
		if room_loot is Array:
			for item in room_loot:
				total_loot.append(item)

		# Accumulate currency
		var room_currency: Variant = room_result.get("currency", {})
		if room_currency is Dictionary:
			for key in room_currency:
				if total_currency.has(key):
					total_currency[key] = total_currency[key] + room_currency[key]
				else:
					total_currency[key] = room_currency[key]

		# Accumulate XP
		total_xp += room_result.get("xp", 0)

		# Accumulate combat log
		var room_log: Variant = room_result.get("combat_log", [])
		if room_log is Array and not room_log.is_empty():
			combat_log.append({
				"room_index": room_idx,
				"room_type": int(room.type),
				"events": room_log,
			})

		# Update party state from room result
		var result_hp: Variant = room_result.get("party_hp", {})
		if result_hp is Dictionary:
			for adv_id in result_hp:
				if party_state.has(adv_id):
					party_state[adv_id]["current_hp"] = result_hp[adv_id]

		var result_ko: Variant = room_result.get("ko_list", [])
		if result_ko is Array:
			for adv_id in result_ko:
				if party_state.has(adv_id):
					party_state[adv_id]["is_ko"] = true

		# Check party wipe
		if _is_party_wiped(party_state):
			break

	# Grant XP to surviving adventurers
	for adv_id in party_state:
		var entry: Dictionary = party_state[adv_id]
		if not entry.get("is_ko", false):
			var adv: AdventurerData = entry.get("adventurer")
			if adv != null and total_xp > 0:
				adv.gain_xp(total_xp)

	# Build final result
	var final_status: Enums.ExpeditionStatus
	if _is_party_wiped(party_state):
		final_status = Enums.ExpeditionStatus.FAILED
	else:
		final_status = Enums.ExpeditionStatus.COMPLETED

	var final_hp: Dictionary = {}
	var final_ko: Array[String] = []
	for adv_id in party_state:
		var entry: Dictionary = party_state[adv_id]
		final_hp[adv_id] = entry.get("current_hp", 0)
		if entry.get("is_ko", false):
			final_ko.append(adv_id)

	return {
		"status": final_status,
		"rooms_cleared": rooms_cleared,
		"total_rooms": path.size(),
		"loot": total_loot,
		"currency": total_currency,
		"xp_earned": total_xp,
		"combat_log": combat_log,
		"party_hp": final_hp,
		"adventurers_ko": final_ko,
	}


func resolve_room(
	room: RoomData,
	party_state: Dictionary,
	rng: DeterministicRNG,
	loot_engine: RefCounted,
	dungeon_element: Enums.Element
) -> Dictionary:
	var result: Dictionary = {
		"cleared": false,
		"loot": [] as Array[Dictionary],
		"currency": {},
		"xp": 0,
		"combat_log": [] as Array[Dictionary],
		"party_hp": _extract_hp(party_state),
		"ko_list": [] as Array[String],
	}

	match room.type:
		Enums.RoomType.ENTRANCE:
			result["cleared"] = true
			result["xp"] = ROOM_CLEAR_XP

		Enums.RoomType.COMBAT:
			_resolve_combat_room(room, party_state, rng, loot_engine, dungeon_element, result, false)

		Enums.RoomType.BOSS:
			_resolve_combat_room(room, party_state, rng, loot_engine, dungeon_element, result, true)

		Enums.RoomType.TREASURE:
			result["cleared"] = true
			result["currency"] = loot_engine.roll_currency(Enums.RoomType.TREASURE, room.difficulty, rng)
			if loot_engine.has_table("treasure"):
				result["loot"] = loot_engine.roll("treasure", rng, 1)
			result["xp"] = ROOM_CLEAR_XP

		Enums.RoomType.SECRET:
			result["cleared"] = true
			result["currency"] = loot_engine.roll_currency(Enums.RoomType.SECRET, room.difficulty, rng)
			if loot_engine.has_table("secret"):
				result["loot"] = loot_engine.roll("secret", rng, 2)
			elif loot_engine.has_table("treasure"):
				result["loot"] = loot_engine.roll("treasure", rng, 2)
			result["xp"] = ROOM_CLEAR_XP

		Enums.RoomType.REST:
			result["cleared"] = true
			_apply_rest_healing(party_state)
			result["party_hp"] = _extract_hp(party_state)
			result["xp"] = ROOM_CLEAR_XP

		Enums.RoomType.TRAP:
			result["cleared"] = true
			var trap_damage: int = room.difficulty * TRAP_DAMAGE_MULTIPLIER
			var log_entries: Array[Dictionary] = []
			for adv_id in party_state:
				var entry: Dictionary = party_state[adv_id]
				if entry.get("is_ko", false):
					continue
				var old_hp: int = entry.get("current_hp", 0)
				var new_hp: int = maxi(0, old_hp - trap_damage)
				entry["current_hp"] = new_hp
				entry["damage_taken"] = entry.get("damage_taken", 0) + trap_damage
				log_entries.append({
					"type": "trap_damage",
					"target": adv_id,
					"damage": trap_damage,
					"hp_remaining": new_hp,
				})
				if new_hp <= 0:
					entry["is_ko"] = true
					if not result["ko_list"].has(adv_id):
						result["ko_list"].append(adv_id)
			result["party_hp"] = _extract_hp(party_state)
			result["combat_log"] = log_entries
			result["currency"] = loot_engine.roll_currency(Enums.RoomType.TRAP, room.difficulty, rng)
			result["xp"] = ROOM_CLEAR_XP

		Enums.RoomType.PUZZLE:
			result["cleared"] = true
			var party_utility: float = _get_party_total_utility(party_state)
			var threshold: float = room.difficulty * 10.0 * PUZZLE_CHECK_THRESHOLD
			var log_entries: Array[Dictionary] = []
			if party_utility >= threshold:
				# Success
				result["currency"] = loot_engine.roll_currency(Enums.RoomType.PUZZLE, room.difficulty, rng)
				if loot_engine.has_table("puzzle"):
					result["loot"] = loot_engine.roll("puzzle", rng, 1)
				log_entries.append({"type": "puzzle_success", "utility": party_utility, "threshold": threshold})
			else:
				# Failure — minor damage
				var puzzle_damage: int = maxi(1, room.difficulty * 2)
				for adv_id in party_state:
					var entry: Dictionary = party_state[adv_id]
					if entry.get("is_ko", false):
						continue
					var old_hp: int = entry.get("current_hp", 0)
					var new_hp: int = maxi(0, old_hp - puzzle_damage)
					entry["current_hp"] = new_hp
					entry["damage_taken"] = entry.get("damage_taken", 0) + puzzle_damage
					if new_hp <= 0:
						entry["is_ko"] = true
						if not result["ko_list"].has(adv_id):
							result["ko_list"].append(adv_id)
				log_entries.append({"type": "puzzle_failure", "utility": party_utility, "threshold": threshold, "damage": puzzle_damage})
			result["party_hp"] = _extract_hp(party_state)
			result["combat_log"] = log_entries
			result["xp"] = ROOM_CLEAR_XP

	return result


func resolve_combat(
	party_state: Dictionary,
	enemies: Array[Dictionary],
	rng: DeterministicRNG,
	dungeon_element: Enums.Element
) -> Dictionary:
	var combat_log: Array[Dictionary] = []
	var rounds: int = 0
	var enemies_defeated: int = 0

	# Build combatant list
	var combatants: Array[Dictionary] = []

	for adv_id in party_state:
		var entry: Dictionary = party_state[adv_id]
		if entry.get("is_ko", false):
			continue
		var adv: AdventurerData = entry.get("adventurer")
		if adv == null:
			continue
		var eff_stats: Dictionary = adv.get_effective_stats()
		combatants.append({
			"id": adv_id,
			"is_party": true,
			"health": entry.get("current_hp", 0),
			"max_health": entry.get("max_hp", 0),
			"attack": eff_stats.get("attack", 1),
			"defense": eff_stats.get("defense", 0),
			"speed": eff_stats.get("speed", 0),
			"utility": eff_stats.get("utility", 0),
			"element": dungeon_element,
			"adventurer_class": adv.adventurer_class,
		})

	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		combatants.append({
			"id": "enemy_%d" % i,
			"is_party": false,
			"health": enemy.get("health", 1),
			"max_health": enemy.get("max_health", 1),
			"attack": enemy.get("attack", 1),
			"defense": enemy.get("defense", 0),
			"speed": enemy.get("speed", 0),
			"utility": 0,
			"element": enemy.get("element", Enums.Element.NONE),
			"name": enemy.get("name", "Enemy"),
			"is_elite": enemy.get("is_elite", false),
		})

	# Sort by initiative
	combatants = _sort_by_initiative(combatants, rng)

	var victory: bool = false
	var defeat: bool = false

	while rounds < MAX_COMBAT_ROUNDS and not victory and not defeat:
		rounds += 1
		var round_log: Array[Dictionary] = []

		for combatant in combatants:
			if combatant.get("health", 0) <= 0:
				continue

			# Pick target
			var targets: Array[Dictionary] = []
			for other in combatants:
				if other.get("health", 0) <= 0:
					continue
				if other.get("is_party", false) != combatant.get("is_party", false):
					targets.append(other)

			if targets.is_empty():
				break

			var target: Dictionary = targets[rng.randi(targets.size())]

			# Calculate damage
			var atk_element: Enums.Element
			if combatant.get("is_party", false):
				atk_element = dungeon_element
			else:
				atk_element = combatant.get("element", Enums.Element.NONE) as Enums.Element

			var def_element: Enums.Element
			if target.get("is_party", false):
				def_element = dungeon_element
			else:
				def_element = target.get("element", Enums.Element.NONE) as Enums.Element

			var damage: int = _calculate_damage(combatant, target, rng, atk_element, def_element)

			target["health"] = maxi(0, target.get("health", 0) - damage)

			var log_entry: Dictionary = {
				"attacker": combatant.get("id", ""),
				"target": target.get("id", ""),
				"damage": damage,
				"target_hp": target.get("health", 0),
			}

			round_log.append(log_entry)

			# Check KO
			if target.get("health", 0) <= 0:
				if target.get("is_party", false):
					var adv_id: String = target.get("id", "")
					if party_state.has(adv_id):
						party_state[adv_id]["is_ko"] = true
						party_state[adv_id]["current_hp"] = 0
				else:
					enemies_defeated += 1

			# Check victory/defeat
			var party_alive: bool = false
			var enemies_alive: bool = false
			for c in combatants:
				if c.get("health", 0) > 0:
					if c.get("is_party", false):
						party_alive = true
					else:
						enemies_alive = true

			if not enemies_alive:
				victory = true
				break
			if not party_alive:
				defeat = true
				break

		combat_log.append({"round": rounds, "events": round_log})

	# Sync party state HP from combatant data
	for combatant in combatants:
		if combatant.get("is_party", false):
			var adv_id: String = combatant.get("id", "")
			if party_state.has(adv_id):
				party_state[adv_id]["current_hp"] = maxi(0, combatant.get("health", 0))
				if combatant.get("health", 0) <= 0:
					party_state[adv_id]["is_ko"] = true

	var ko_list: Array[String] = []
	var hp_map: Dictionary = {}
	for adv_id in party_state:
		var entry: Dictionary = party_state[adv_id]
		hp_map[adv_id] = entry.get("current_hp", 0)
		if entry.get("is_ko", false):
			ko_list.append(adv_id)

	return {
		"victory": victory,
		"rounds": rounds,
		"combat_log": combat_log,
		"party_hp": hp_map,
		"ko_list": ko_list,
		"enemies_defeated": enemies_defeated,
	}


# ===========================================================================
# Private Helpers
# ===========================================================================

func _generate_enemies(
	room: RoomData,
	rng: DeterministicRNG,
	dungeon_element: Enums.Element
) -> Array[Dictionary]:
	var enemies: Array[Dictionary] = []
	var base_difficulty: int = maxi(1, room.difficulty)

	# Number of enemies: 1-3 for combat, more for harder rooms
	var enemy_count: int = clampi(1 + base_difficulty / 3, 1, 5)
	var is_boss: bool = room.type == Enums.RoomType.BOSS

	for i in range(enemy_count):
		var is_elite: bool = false
		if not is_boss:
			is_elite = rng.randf() < 0.15

		var stat_mult: float = 1.0 + (base_difficulty - 1) * 0.2
		if is_boss:
			stat_mult *= BOSS_STAT_MULTIPLIER
		if is_elite:
			stat_mult *= 1.5

		# Pick element: bias toward dungeon element
		var elem: Enums.Element
		if rng.randf() < 0.6:
			elem = dungeon_element
		else:
			elem = rng.randi(Enums.Element.NONE) as Enums.Element

		var health: int = maxi(1, roundi(30.0 * stat_mult))
		var attack: int = maxi(1, roundi(8.0 * stat_mult))
		var defense: int = maxi(0, roundi(4.0 * stat_mult))
		var speed: int = maxi(1, roundi(6.0 * stat_mult))

		var enemy_name: String = _generate_enemy_name(elem, is_elite or is_boss, rng)

		enemies.append({
			"name": enemy_name,
			"health": health,
			"max_health": health,
			"attack": attack,
			"defense": defense,
			"speed": speed,
			"element": elem,
			"is_elite": is_elite or is_boss,
		})

	return enemies


func _calculate_damage(
	attacker_stats: Dictionary,
	defender_stats: Dictionary,
	rng: DeterministicRNG,
	attacker_element: Enums.Element,
	defender_element: Enums.Element
) -> int:
	var atk: float = float(attacker_stats.get("attack", 1))
	var skill_mult: float = 1.0
	var elem_mod: float = _get_elemental_modifier(attacker_element, defender_element)
	var variance: float = DAMAGE_VARIANCE_MIN + rng.randf() * (DAMAGE_VARIANCE_MAX - DAMAGE_VARIANCE_MIN)

	var raw: float = atk * skill_mult * elem_mod * variance

	# Crit check
	var utility: float = float(attacker_stats.get("utility", 0))
	var crit_chance: float = CRIT_BASE_CHANCE + utility / 200.0
	if rng.randf() < crit_chance:
		raw *= CRIT_MULTIPLIER

	# Defense calculation
	var def_val: float = float(defender_stats.get("defense", 0))
	var armor_mult: float = 1.0

	if defender_stats.has("adventurer_class"):
		armor_mult = _get_armor_multiplier(defender_stats["adventurer_class"] as Enums.AdventurerClass)

	var damage: int = maxi(1, roundi(raw - def_val * armor_mult))
	return damage


func _get_elemental_modifier(
	attacker_element: Enums.Element,
	defender_element: Enums.Element
) -> float:
	if attacker_element == Enums.Element.NONE or defender_element == Enums.Element.NONE:
		return 1.0
	if attacker_element == defender_element:
		return 1.0
	if ELEMENT_ADVANTAGE.has(attacker_element) and ELEMENT_ADVANTAGE[attacker_element] == defender_element:
		return 1.5
	# Check if defender has advantage (disadvantage for attacker)
	if ELEMENT_ADVANTAGE.has(defender_element) and ELEMENT_ADVANTAGE[defender_element] == attacker_element:
		return 0.6
	return 1.0


func _get_armor_multiplier(adventurer_class: Enums.AdventurerClass) -> float:
	if ARMOR_MULTIPLIERS.has(adventurer_class):
		return ARMOR_MULTIPLIERS[adventurer_class]
	return 1.0


func _sort_by_initiative(
	combatants: Array[Dictionary],
	rng: DeterministicRNG
) -> Array[Dictionary]:
	# Custom sort: descending speed, then descending utility, then RNG tiebreak
	# Assign tiebreaker values upfront for determinism
	for c in combatants:
		c["_tiebreak"] = rng.randf()

	var sorted_list: Array[Dictionary] = combatants.duplicate()
	sorted_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_speed: int = a.get("speed", 0)
		var b_speed: int = b.get("speed", 0)
		if a_speed != b_speed:
			return a_speed > b_speed
		var a_util: int = a.get("utility", 0)
		var b_util: int = b.get("utility", 0)
		if a_util != b_util:
			return a_util > b_util
		return a.get("_tiebreak", 0.0) > b.get("_tiebreak", 0.0)
	)

	# Clean up tiebreak keys
	for c in sorted_list:
		if c.has("_tiebreak"):
			c.erase("_tiebreak")

	return sorted_list


func _apply_between_room_healing(party_state: Dictionary) -> void:
	for adv_id in party_state:
		var entry: Dictionary = party_state[adv_id]
		if entry.get("is_ko", false):
			continue
		var max_hp: int = entry.get("max_hp", 0)
		var current_hp: int = entry.get("current_hp", 0)
		var heal: int = maxi(1, roundi(float(max_hp) * BETWEEN_ROOM_HEAL_PERCENT))
		entry["current_hp"] = mini(max_hp, current_hp + heal)


func _apply_rest_healing(party_state: Dictionary) -> void:
	for adv_id in party_state:
		var entry: Dictionary = party_state[adv_id]
		if entry.get("is_ko", false):
			continue
		var max_hp: int = entry.get("max_hp", 0)
		var current_hp: int = entry.get("current_hp", 0)
		var heal: int = maxi(1, roundi(float(max_hp) * REST_HEAL_PERCENT))
		entry["current_hp"] = mini(max_hp, current_hp + heal)


func _generate_enemy_name(
	element: Enums.Element,
	is_elite: bool,
	rng: DeterministicRNG
) -> String:
	var prefix: String = ENEMY_PREFIXES[rng.randi(ENEMY_PREFIXES.size())]
	var base: String = ENEMY_TYPES[rng.randi(ENEMY_TYPES.size())]
	var elem_str: String = Enums.element_name(element)

	if is_elite:
		return "%s %s %s" % [elem_str, prefix, base]
	return "%s %s" % [prefix, base]


func _build_party_state(party: Array) -> Dictionary:
	var state: Dictionary = {}
	for adv in party:
		if adv == null:
			continue
		var a: AdventurerData = adv as AdventurerData
		if a == null:
			continue
		var eff: Dictionary = a.get_effective_stats()
		var hp: int = eff.get("health", 1)
		state[a.id] = {
			"adventurer": a,
			"current_hp": hp,
			"max_hp": hp,
			"is_ko": false,
			"damage_dealt": 0,
			"damage_taken": 0,
		}
	return state


func _extract_hp(party_state: Dictionary) -> Dictionary:
	var hp_map: Dictionary = {}
	for adv_id in party_state:
		hp_map[adv_id] = party_state[adv_id].get("current_hp", 0)
	return hp_map


func _is_party_wiped(party_state: Dictionary) -> bool:
	for adv_id in party_state:
		if not party_state[adv_id].get("is_ko", false):
			return false
	return true


func _get_party_total_utility(party_state: Dictionary) -> float:
	var total: float = 0.0
	for adv_id in party_state:
		var entry: Dictionary = party_state[adv_id]
		if entry.get("is_ko", false):
			continue
		var adv: AdventurerData = entry.get("adventurer")
		if adv != null:
			total += float(adv.get_effective_stats().get("utility", 0))
	return total


func _resolve_combat_room(
	room: RoomData,
	party_state: Dictionary,
	rng: DeterministicRNG,
	loot_engine: RefCounted,
	dungeon_element: Enums.Element,
	result: Dictionary,
	is_boss: bool
) -> void:
	var enemies: Array[Dictionary] = _generate_enemies(room, rng, dungeon_element)
	var combat_result: Dictionary = resolve_combat(party_state, enemies, rng, dungeon_element)

	result["combat_log"] = combat_result.get("combat_log", [])
	result["party_hp"] = combat_result.get("party_hp", {})
	result["ko_list"] = combat_result.get("ko_list", [])

	if combat_result.get("victory", false):
		result["cleared"] = true
		# XP from defeated enemies
		var xp: int = ROOM_CLEAR_XP
		for enemy in enemies:
			var base: int = BASE_XP_PER_ENEMY
			if is_boss:
				xp += roundi(base * BOSS_XP_MULTIPLIER)
			elif enemy.get("is_elite", false):
				xp += roundi(base * ELITE_XP_MULTIPLIER)
			else:
				xp += base
		result["xp"] = xp

		# Currency from room
		var room_type: Enums.RoomType = Enums.RoomType.BOSS if is_boss else Enums.RoomType.COMBAT
		result["currency"] = loot_engine.roll_currency(room_type, room.difficulty, rng)

		# Loot from boss/combat
		if is_boss and loot_engine.has_table("boss"):
			result["loot"] = loot_engine.roll("boss", rng, 2)
		elif loot_engine.has_table("combat"):
			result["loot"] = loot_engine.roll("combat", rng, 1)
	else:
		result["cleared"] = false


func _make_result(
	status: Enums.ExpeditionStatus,
	rooms_cleared: int,
	total_rooms: int
) -> Dictionary:
	return {
		"status": status,
		"rooms_cleared": rooms_cleared,
		"total_rooms": total_rooms,
		"loot": [] as Array[Dictionary],
		"currency": {},
		"xp_earned": 0,
		"combat_log": [] as Array[Dictionary],
		"party_hp": {},
		"adventurers_ko": [] as Array[String],
	}
