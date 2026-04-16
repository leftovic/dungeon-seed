extends RefCounted
## Expedition UI logic controller — headless, testable, no scene tree.
##
## Provides data formatting for the Expedition Board (party selection,
## dungeon preview, difficulty comparison) and Expedition Log (room-by-room
## result playback, loot summary, party status).
##
## Consumes: AdventurerRoster, DungeonData, expedition result dicts.
## Consumed by: future Expedition Board / Expedition Log UI scenes.

const AdventurerRosterScript = preload("res://src/services/adventurer_roster.gd")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Minimum and maximum party size for expedition dispatch.
const MIN_PARTY_SIZE: int = 1
const MAX_PARTY_SIZE: int = 4

## Difficulty skull thresholds — dungeon difficulty mapped to 1-5 skull rating.
## Index 0 unused; thresholds[i] = minimum difficulty for i skulls.
const SKULL_THRESHOLDS: Array[int] = [0, 1, 4, 7, 10, 14]

## Power-to-difficulty ratio thresholds for comparison ratings.
const RATING_DEADLY_THRESHOLD: float = 0.5
const RATING_HARD_THRESHOLD: float = 0.8
const RATING_FAIR_THRESHOLD: float = 1.2

## Human-readable names for room types, keyed by Enums.RoomType int values.
const ROOM_TYPE_NAMES: Dictionary = {
	Enums.RoomType.ENTRANCE: "Entrance",
	Enums.RoomType.COMBAT: "Combat",
	Enums.RoomType.TREASURE: "Treasure",
	Enums.RoomType.TRAP: "Trap",
	Enums.RoomType.PUZZLE: "Puzzle",
	Enums.RoomType.REST: "Rest",
	Enums.RoomType.BOSS: "Boss",
	Enums.RoomType.SECRET: "Secret",
}

## Human-readable names for expedition statuses.
const STATUS_NAMES: Dictionary = {
	Enums.ExpeditionStatus.PREPARING: "Preparing",
	Enums.ExpeditionStatus.IN_PROGRESS: "In Progress",
	Enums.ExpeditionStatus.COMPLETED: "Completed",
	Enums.ExpeditionStatus.FAILED: "Failed",
}

## Stat keys used for party power calculation.
const POWER_STAT_KEYS: Array[String] = ["health", "attack", "defense", "speed"]

## Per-stat weight in the power formula.
const POWER_WEIGHTS: Dictionary = {
	"health": 1.0,
	"attack": 3.0,
	"defense": 2.0,
	"speed": 1.5,
}

## Level multiplier for power scaling.
const POWER_LEVEL_MULTIPLIER: float = 1.5


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _roster: RefCounted = null
var _initialized: bool = false


# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

## Initialize with service references. Must be called before other methods.
func initialize(roster: RefCounted) -> void:
	_roster = roster
	_initialized = true


## Returns true if initialize() has been called with a valid roster.
func is_initialized() -> bool:
	return _initialized and _roster != null


# ---------------------------------------------------------------------------
# Dungeon Preview
# ---------------------------------------------------------------------------

## Generate dungeon preview data for the Expedition Board display.
## Returns a dictionary with room_count, element, difficulty_rating (1-5 skulls),
## room_types breakdown, has_boss, has_secret flags.
func get_dungeon_preview(dungeon: RefCounted) -> Dictionary:
	var result: Dictionary = {
		"room_count": 0,
		"element": Enums.Element.NONE,
		"element_name": "None",
		"difficulty_rating": 1,
		"difficulty_raw": 0,
		"room_types": {},
		"has_boss": false,
		"has_secret": false,
	}

	if dungeon == null:
		return result

	var dun: DungeonData = dungeon as DungeonData
	if dun == null:
		return result

	result["room_count"] = dun.get_room_count()
	result["element"] = int(dun.element)
	result["element_name"] = Enums.element_name(dun.element)
	result["difficulty_raw"] = dun.difficulty
	result["difficulty_rating"] = _difficulty_to_skulls(dun.difficulty)

	# Count room types, detect boss/secret
	var type_counts: Dictionary = {}
	for room in dun.rooms:
		var r: RoomData = room as RoomData
		if r == null:
			continue
		var rt: int = int(r.type)
		if type_counts.has(rt):
			type_counts[rt] = type_counts[rt] + 1
		else:
			type_counts[rt] = 1
		if r.type == Enums.RoomType.BOSS:
			result["has_boss"] = true
		if r.type == Enums.RoomType.SECRET:
			result["has_secret"] = true

	result["room_types"] = type_counts
	return result


# ---------------------------------------------------------------------------
# Party Selection
# ---------------------------------------------------------------------------

## Get available party members for selection from the roster.
## Returns an array of display-ready dictionaries.
func get_available_party() -> Array:
	if _roster == null:
		return []

	var all_adventurers: Array = _roster.get_all_adventurers()
	var available: Array = []

	for adv_variant in all_adventurers:
		var adv: AdventurerData = adv_variant as AdventurerData
		if adv == null:
			continue
		if not adv.is_available:
			continue
		available.append(_format_adventurer(adv))

	return available


## Validate a party selection by ID array.
## Returns { "valid": bool, "message": String, "warnings": Array }.
func validate_party(party_ids: Array) -> Dictionary:
	var result: Dictionary = {
		"valid": false,
		"message": "",
		"warnings": [] as Array[String],
	}

	# Check roster is set
	if _roster == null:
		result["message"] = "Roster not initialized"
		return result

	# Check empty party
	if party_ids.is_empty():
		result["message"] = "Party cannot be empty"
		return result

	# Check max size
	if party_ids.size() > MAX_PARTY_SIZE:
		result["message"] = "Party cannot exceed %d members" % MAX_PARTY_SIZE
		return result

	# Check each member
	var seen_ids: Dictionary = {}
	var warnings: Array = []

	for id_variant in party_ids:
		var id_str: String = str(id_variant)

		# Duplicate check
		if seen_ids.has(id_str):
			result["message"] = "Duplicate adventurer: %s" % id_str
			return result
		seen_ids[id_str] = true

		# Existence check
		var adv: AdventurerData = _roster.get_adventurer(id_str)
		if adv == null:
			result["message"] = "Adventurer not found: %s" % id_str
			return result

		# Availability check (covers exhausted/injured/deployed)
		if not adv.is_available:
			result["message"] = "Adventurer unavailable: %s" % adv.display_name
			return result

		# Level-based warnings
		if adv.level <= 1:
			warnings.append("%s is still level 1 — consider leveling first" % adv.display_name)

	result["valid"] = true
	result["message"] = "Party ready for expedition"
	result["warnings"] = warnings
	return result


# ---------------------------------------------------------------------------
# Expedition Result Formatting
# ---------------------------------------------------------------------------

## Format a full expedition result dict (from ExpeditionRunner) for display.
func format_expedition_result(result: Dictionary) -> Dictionary:
	var formatted: Dictionary = {
		"status": "Unknown",
		"rooms_cleared": "0/0",
		"xp_earned": 0,
		"gold_earned": 0,
		"loot_items": [] as Array[Dictionary],
		"room_log": [] as Array[Dictionary],
		"party_status": [] as Array[Dictionary],
	}

	if result.is_empty():
		return formatted

	# Status
	var raw_status: Variant = result.get("status", Enums.ExpeditionStatus.FAILED)
	if raw_status is int:
		formatted["status"] = STATUS_NAMES.get(raw_status, "Unknown")
	else:
		formatted["status"] = STATUS_NAMES.get(int(raw_status), "Unknown")

	# Room progress
	var cleared: int = int(result.get("rooms_cleared", 0))
	var total: int = int(result.get("total_rooms", 0))
	formatted["rooms_cleared"] = "%d/%d" % [cleared, total]

	# XP
	formatted["xp_earned"] = int(result.get("xp_earned", 0))

	# Gold from currency dict
	var currency: Variant = result.get("currency", {})
	if currency is Dictionary:
		formatted["gold_earned"] = int(currency.get(Enums.Currency.GOLD, 0))

	# Loot items
	var loot: Variant = result.get("loot", [])
	if loot is Array:
		var formatted_loot: Array = []
		for item in loot:
			if item is Dictionary:
				formatted_loot.append({
					"item_id": str(item.get("item_id", "")),
					"quantity": int(item.get("quantity", 1)),
				})
		formatted["loot_items"] = formatted_loot

	# Room log from combat_log
	var combat_log: Variant = result.get("combat_log", [])
	if combat_log is Array:
		var room_log: Array = []
		var room_number: int = 0
		for entry in combat_log:
			if entry is Dictionary:
				room_number += 1
				room_log.append(_format_combat_log_entry(entry, room_number))
		formatted["room_log"] = room_log

	# Party status
	var party_hp: Variant = result.get("party_hp", {})
	var ko_list: Variant = result.get("adventurers_ko", [])
	if party_hp is Dictionary:
		var party_status: Array = []
		for adv_id in party_hp:
			var hp: int = int(party_hp[adv_id])
			var is_ko: bool = false
			if ko_list is Array:
				is_ko = ko_list.has(str(adv_id))
			var status_text: String = "KO" if is_ko else "Alive"
			party_status.append({
				"id": str(adv_id),
				"hp_remaining": hp,
				"is_ko": is_ko,
				"status_text": status_text,
			})
		formatted["party_status"] = party_status

	return formatted


## Format a single room result entry for the expedition log.
## Accepts a room result dict as returned by ExpeditionRunner.resolve_room().
func format_room_result(room_result: Dictionary) -> Dictionary:
	var formatted: Dictionary = {
		"room_type": "Unknown",
		"room_number": 0,
		"cleared": false,
		"damage_dealt": 0,
		"damage_taken": 0,
		"loot": [] as Array[Dictionary],
		"events": [] as Array[String],
	}

	if room_result.is_empty():
		return formatted

	# Room type
	var raw_type: Variant = room_result.get("room_type", -1)
	if raw_type is int and ROOM_TYPE_NAMES.has(raw_type):
		formatted["room_type"] = ROOM_TYPE_NAMES[raw_type]

	# Room number
	formatted["room_number"] = int(room_result.get("room_index", 0))

	# Cleared
	formatted["cleared"] = bool(room_result.get("cleared", false))

	# Parse events from combat log to extract damage totals
	var events_list: Variant = room_result.get("events", [])
	var total_damage_dealt: int = 0
	var total_damage_taken: int = 0
	var event_strings: Array = []

	if events_list is Array:
		for event in events_list:
			if not event is Dictionary:
				continue
			var ev: Dictionary = event as Dictionary
			var ev_type: String = str(ev.get("type", ""))

			if ev_type == "trap_damage":
				var dmg: int = int(ev.get("damage", 0))
				total_damage_taken += dmg
				event_strings.append("Trap hit %s for %d damage" % [
					str(ev.get("target", "?")), dmg
				])
			elif ev_type == "puzzle_success":
				event_strings.append("Puzzle solved (utility: %d)" % int(ev.get("utility", 0)))
			elif ev_type == "puzzle_failure":
				var dmg: int = int(ev.get("damage", 0))
				total_damage_taken += dmg
				event_strings.append("Puzzle failed — %d damage to party" % dmg)
			else:
				# Standard combat log entry
				var attacker: String = str(ev.get("attacker", ""))
				var target: String = str(ev.get("target", ""))
				var damage: int = int(ev.get("damage", 0))
				var is_party_attack: bool = not attacker.begins_with("enemy_")
				if is_party_attack:
					total_damage_dealt += damage
				else:
					total_damage_taken += damage
				event_strings.append("%s attacks %s for %d damage" % [
					attacker, target, damage
				])

	formatted["damage_dealt"] = total_damage_dealt
	formatted["damage_taken"] = total_damage_taken
	formatted["events"] = event_strings

	# Loot
	var loot: Variant = room_result.get("loot", [])
	if loot is Array:
		var loot_formatted: Array = []
		for item in loot:
			if item is Dictionary:
				loot_formatted.append({
					"item_id": str(item.get("item_id", "")),
					"quantity": int(item.get("quantity", 1)),
				})
		formatted["loot"] = loot_formatted

	return formatted


# ---------------------------------------------------------------------------
# Party Power & Difficulty Comparison
# ---------------------------------------------------------------------------

## Calculate party power rating from an array of AdventurerData instances.
## Formula: sum of (weighted stats × level multiplier) for each member.
func calculate_party_power(party: Array) -> int:
	var total_power: float = 0.0

	for adv_variant in party:
		var adv: AdventurerData = adv_variant as AdventurerData
		if adv == null:
			continue
		var stats: Dictionary = adv.get_effective_stats()
		var stat_sum: float = 0.0
		for key in POWER_STAT_KEYS:
			var weight: float = POWER_WEIGHTS.get(key, 1.0)
			stat_sum += float(stats.get(key, 0)) * weight
		var level_bonus: float = 1.0 + (adv.level - 1) * (POWER_LEVEL_MULTIPLIER - 1.0) / 9.0
		total_power += stat_sum * level_bonus

	return roundi(total_power)


## Get difficulty comparison text and color based on party power vs dungeon difficulty.
## Returns { "rating": String, "color": String }.
func get_difficulty_comparison(party_power: int, dungeon_difficulty: int) -> Dictionary:
	if dungeon_difficulty <= 0:
		return { "rating": "Easy", "color": "green" }

	# Scale dungeon difficulty to a comparable range
	# Power is in the hundreds, difficulty is 1-20ish, so scale difficulty up
	var scaled_difficulty: float = float(dungeon_difficulty) * 50.0
	var ratio: float = float(party_power) / scaled_difficulty if scaled_difficulty > 0.0 else 99.0

	if ratio < RATING_DEADLY_THRESHOLD:
		return { "rating": "Deadly", "color": "red" }
	elif ratio < RATING_HARD_THRESHOLD:
		return { "rating": "Hard", "color": "orange" }
	elif ratio < RATING_FAIR_THRESHOLD:
		return { "rating": "Fair", "color": "yellow" }
	else:
		return { "rating": "Easy", "color": "green" }


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

## Convert raw dungeon difficulty int to a 1-5 skull rating.
func _difficulty_to_skulls(difficulty: int) -> int:
	for i in range(SKULL_THRESHOLDS.size() - 1, 0, -1):
		if difficulty >= SKULL_THRESHOLDS[i]:
			return i
	return 1


## Format a single adventurer as a display-ready dictionary.
func _format_adventurer(adv: AdventurerData) -> Dictionary:
	return {
		"id": adv.id,
		"name": adv.display_name,
		"class": int(adv.adventurer_class),
		"class_name": Enums.adventurer_class_name(adv.adventurer_class),
		"level": adv.level,
		"is_available": adv.is_available,
		"stats": adv.get_effective_stats(),
	}


## Format a combat_log entry (from expedition result) into a room log entry.
func _format_combat_log_entry(entry: Dictionary, room_number: int) -> Dictionary:
	var room_type_int: int = int(entry.get("room_type", -1))
	var room_type_name: String = ROOM_TYPE_NAMES.get(room_type_int, "Unknown")

	var events: Variant = entry.get("events", [])
	var total_dealt: int = 0
	var total_taken: int = 0
	var event_strings: Array = []

	if events is Array:
		for ev in events:
			if not ev is Dictionary:
				continue
			var ev_dict: Dictionary = ev as Dictionary
			var ev_type: String = str(ev_dict.get("type", ""))
			if ev_type == "trap_damage":
				var dmg: int = int(ev_dict.get("damage", 0))
				total_taken += dmg
				event_strings.append("Trap: %d damage to %s" % [dmg, str(ev_dict.get("target", "?"))])
			elif ev_type == "puzzle_success":
				event_strings.append("Puzzle solved")
			elif ev_type == "puzzle_failure":
				total_taken += int(ev_dict.get("damage", 0))
				event_strings.append("Puzzle failed")
			else:
				var attacker: String = str(ev_dict.get("attacker", ""))
				var damage: int = int(ev_dict.get("damage", 0))
				if not attacker.begins_with("enemy_"):
					total_dealt += damage
				else:
					total_taken += damage
				event_strings.append("%s → %s: %d dmg" % [
					attacker, str(ev_dict.get("target", "?")), damage
				])

	return {
		"room_type": room_type_name,
		"room_number": room_number,
		"room_index": int(entry.get("room_index", 0)),
		"damage_dealt": total_dealt,
		"damage_taken": total_taken,
		"events": event_strings,
	}
