class_name AdventurerData
extends RefCounted
## Core data model for a single adventurer in Dungeon Seed.
##
## Pure data container — no scene tree dependency, no signals, no UI.
## Consumed by TASK-013 (Roster), TASK-014 (Equipment), TASK-015 (Expedition).
## GDD Reference: §4.3 — Adventurer System


# ---------------------------------------------------------------------------
# Properties
# ---------------------------------------------------------------------------

## Unique identifier for this adventurer instance.
var id: String = ""

## Player-visible display name.
var display_name: String = ""

## Combat class archetype. Determines base stat distribution.
var adventurer_class: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR

## Current level (1+). Increases when XP meets threshold.
var level: int = 1

## XP within current level. Resets to remainder after level-up.
var xp: int = 0

## Base stat block: { health, attack, defense, speed, utility }.
## Empty by default — call initialize_base_stats() after setting class.
var stats: Dictionary = {}

## Equipment slots. String keys for JSON readability.
var equipment: Dictionary = { "weapon": null, "armor": null, "accessory": null }

## Whether this adventurer is available for expedition dispatch.
var is_available: bool = true


# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

## Copies base stats from GameConfig for the current adventurer_class.
## Must be called after setting adventurer_class.
## Falls back to WARRIOR stats if class is unrecognized.
func initialize_base_stats() -> void:
	if GameConfig.BASE_STATS.has(adventurer_class):
		stats = GameConfig.BASE_STATS[adventurer_class].duplicate(true)
	else:
		push_error("Unknown AdventurerClass: %d — falling back to WARRIOR" % int(adventurer_class))
		stats = GameConfig.BASE_STATS[Enums.AdventurerClass.WARRIOR].duplicate(true)


# ---------------------------------------------------------------------------
# XP & Leveling
# ---------------------------------------------------------------------------

## Returns the XP required to advance from the current level to the next.
## Uses exponential curve: BASE_XP * pow(GROWTH_RATE, level - 1).
func xp_to_next_level() -> int:
	return roundi(GameConfig.XP_CURVE["BASE_XP"] * pow(GameConfig.XP_CURVE["GROWTH_RATE"], level - 1))


## Adds XP and processes level-ups. Returns true if at least one level-up occurred.
## Rejects zero and negative amounts.
func gain_xp(amount: int) -> bool:
	if amount <= 0:
		return false
	xp += amount
	var leveled_up: bool = false
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		leveled_up = true
	return leveled_up


# ---------------------------------------------------------------------------
# Level Tier
# ---------------------------------------------------------------------------

## Returns the level tier based on current level.
## Uses literal boundaries per ticket Section 8.5 (DEV-005).
func get_level_tier() -> Enums.LevelTier:
	if level >= 16:
		return Enums.LevelTier.ELITE
	elif level >= 11:
		return Enums.LevelTier.VETERAN
	elif level >= 6:
		return Enums.LevelTier.SKILLED
	else:
		return Enums.LevelTier.NOVICE


# ---------------------------------------------------------------------------
# Stat Query
# ---------------------------------------------------------------------------

## Returns effective stats as a deep copy of base stats.
## Placeholder — TASK-014 will add equipment bonuses.
func get_effective_stats() -> Dictionary:
	return stats.duplicate(true)


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serializes this adventurer to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"adventurer_class": int(adventurer_class),
		"level": level,
		"xp": xp,
		"stats": stats.duplicate(true),
		"equipment": equipment.duplicate(true),
		"is_available": is_available,
	}


## Reconstructs an AdventurerData from a serialized Dictionary.
## Uses defensive get() with defaults for all fields. Handles missing/invalid data.
static func from_dict(data: Dictionary) -> AdventurerData:
	var adv := AdventurerData.new()

	# Identity
	adv.id = str(data.get("id", ""))
	adv.display_name = str(data.get("display_name", ""))

	# Class — validate range, default to WARRIOR on invalid
	var raw_class: int = int(data.get("adventurer_class", 0))
	if raw_class < 0 or raw_class >= Enums.AdventurerClass.size():
		push_error("Invalid adventurer_class value: %d — defaulting to WARRIOR" % raw_class)
		raw_class = 0
	adv.adventurer_class = raw_class as Enums.AdventurerClass

	# Level — clamp to >= 1
	adv.level = maxi(int(data.get("level", 1)), 1)

	# XP — clamp to >= 0
	adv.xp = maxi(int(data.get("xp", 0)), 0)

	# Stats — restore from dict with validation against base stats
	var raw_stats: Variant = data.get("stats", {})
	if raw_stats is Dictionary:
		var source: Dictionary = raw_stats as Dictionary
		var base: Dictionary = GameConfig.BASE_STATS.get(adv.adventurer_class, {})
		adv.stats = {}
		for key: String in GameConfig.STAT_KEYS:
			if source.has(key):
				adv.stats[key] = int(source[key])
			elif base.has(key):
				adv.stats[key] = int(base[key])
			else:
				adv.stats[key] = 0
	else:
		adv.initialize_base_stats()

	# Equipment — only read canonical slot keys
	var raw_equip: Variant = data.get("equipment", {})
	adv.equipment = { "weapon": null, "armor": null, "accessory": null }
	if raw_equip is Dictionary:
		var equip_source: Dictionary = raw_equip as Dictionary
		for key: String in GameConfig.EQUIP_SLOT_KEYS:
			if equip_source.has(key):
				adv.equipment[key] = equip_source[key]

	# Availability
	adv.is_available = bool(data.get("is_available", true))

	return adv
