class_name AdventurerRoster
extends RefCounted
## Manages the global collection of all recruited adventurers and party composition.
##
## Pure service layer — no scene tree dependency, no UI.
## Consumed by GameManager, Expedition Dispatch, Tavern UI (future).
## GDD Reference: §6 Adventurer System


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Maximum number of adventurers in a single expedition party.
const MAX_PARTY_SIZE: int = 4

## Default maximum roster capacity. Can be overridden via max_roster_size property.
const DEFAULT_MAX_ROSTER_SIZE: int = 20

## Class-specific name pools for procedural name generation (8 per class).
const NAME_TABLES: Dictionary = {
	Enums.AdventurerClass.WARRIOR: ["Kira", "Thane", "Bjorn", "Asha", "Rorik", "Freya", "Magnus", "Elara"],
	Enums.AdventurerClass.RANGER: ["Sylvan", "Talon", "Mira", "Fenris", "Lyra", "Hawk", "Vesper", "Ashen"],
	Enums.AdventurerClass.MAGE: ["Alden", "Seraphine", "Lucian", "Nyx", "Cassian", "Vespera", "Theron", "Isolde"],
	Enums.AdventurerClass.ROGUE: ["Shade", "Vex", "Sable", "Rook", "Whisper", "Ember", "Sly", "Onyx"],
	Enums.AdventurerClass.ALCHEMIST: ["Caelum", "Briar", "Sage", "Orion", "Ivy", "Flint", "Willow", "Cinder"],
	Enums.AdventurerClass.SENTINEL: ["Valorin", "Bastian", "Aegis", "Serena", "Ward", "Fortuna", "Citadel", "Haven"],
}

## Short class name codes for ID generation.
const CLASS_SHORT_NAMES: Dictionary = {
	Enums.AdventurerClass.WARRIOR: "war",
	Enums.AdventurerClass.RANGER: "ran",
	Enums.AdventurerClass.MAGE: "mag",
	Enums.AdventurerClass.ROGUE: "rog",
	Enums.AdventurerClass.ALCHEMIST: "alc",
	Enums.AdventurerClass.SENTINEL: "sen",
}

## Roman numeral suffixes for duplicate name deduplication.
const _ROMAN_NUMERALS: Array[String] = [
	"", " II", " III", " IV", " V", " VI", " VII", " VIII", " IX", " X",
	" XI", " XII", " XIII", " XIV", " XV", " XVI", " XVII", " XVIII", " XIX", " XX",
]


# ---------------------------------------------------------------------------
# Properties
# ---------------------------------------------------------------------------

## Dictionary mapping adventurer ID (String) to AdventurerData instances.
var _adventurers: Dictionary = {}

## Array of adventurer IDs forming the current expedition party (max 4).
var _current_party: Array[String] = []

## Maximum number of adventurers that can be in the roster.
var max_roster_size: int = DEFAULT_MAX_ROSTER_SIZE

## Auto-incrementing counter for unique ID generation.
var _next_id_counter: int = 1


# ---------------------------------------------------------------------------
# Roster Management
# ---------------------------------------------------------------------------

## Adds a pre-built AdventurerData to the roster.
## Returns true if added successfully, false if roster full or ID already exists.
func add_adventurer(adventurer: AdventurerData) -> bool:
	if adventurer == null:
		return false
	if adventurer.id == "":
		return false
	if _adventurers.has(adventurer.id):
		return false
	if _adventurers.size() >= max_roster_size:
		return false
	_adventurers[adventurer.id] = adventurer
	return true


## Removes an adventurer from the roster by ID.
## Also removes from current party if present.
## Returns true if the adventurer existed and was removed, false otherwise.
func remove_adventurer(id: String) -> bool:
	if not _adventurers.has(id):
		return false
	_adventurers.erase(id)
	# Remove from party if present
	var party_idx: int = _current_party.find(id)
	if party_idx >= 0:
		_current_party.remove_at(party_idx)
	return true


## Returns the AdventurerData for the given ID, or null if not found.
func get_adventurer(id: String) -> AdventurerData:
	return _adventurers.get(id, null)


## Returns true if an adventurer with the given ID exists in the roster.
func has_adventurer(id: String) -> bool:
	return _adventurers.has(id)


## Returns all adventurers in the roster as an array.
func get_all_adventurers() -> Array:
	return _adventurers.values()


## Returns the current number of adventurers in the roster.
func get_roster_size() -> int:
	return _adventurers.size()


# ---------------------------------------------------------------------------
# Recruitment
# ---------------------------------------------------------------------------

## Recruits a new adventurer with a procedurally generated name and starting stats.
##
## Uses the provided RNG for name and class selection. If class_override is provided
## (>= 0), that class is used; otherwise a random class is selected.
## Returns the adventurer's ID, or "" if the roster is full.
func recruit_adventurer(rng: DeterministicRNG, class_override: int = -1) -> String:
	if _adventurers.size() >= max_roster_size:
		return ""

	# Determine class
	var adv_class: Enums.AdventurerClass
	if class_override >= 0 and class_override < Enums.AdventurerClass.size():
		adv_class = class_override as Enums.AdventurerClass
	else:
		adv_class = rng.randi(Enums.AdventurerClass.size()) as Enums.AdventurerClass

	# Generate ID
	var adv_id: String = _generate_id(adv_class)

	# Generate procedural name with deduplication
	var display_name: String = _generate_name(rng, adv_class)

	# Create AdventurerData
	var adv := AdventurerData.new()
	adv.id = adv_id
	adv.display_name = display_name
	adv.adventurer_class = adv_class
	adv.level = 1
	adv.xp = 0
	adv.initialize_base_stats()
	adv.is_available = true

	_adventurers[adv_id] = adv
	return adv_id


# ---------------------------------------------------------------------------
# Party Composition
# ---------------------------------------------------------------------------

## Assembles a party from the given adventurer IDs.
## Validates composition rules, then stores the party if valid.
## Returns OK on success, or an error code on failure.
func assemble_party(adventurer_ids: Array) -> int:
	var err: int = validate_party(adventurer_ids)
	if err != OK:
		return err
	_current_party.clear()
	for id: String in adventurer_ids:
		_current_party.append(id)
	return OK


## Validates a party composition against all rules.
## Returns OK if valid, or an appropriate error code.
func validate_party(adventurer_ids: Array) -> int:
	# Check size bounds
	if adventurer_ids.size() == 0:
		return ERR_INVALID_PARAMETER
	if adventurer_ids.size() > MAX_PARTY_SIZE:
		return ERR_INVALID_PARAMETER

	var seen: Dictionary = {}
	for id: Variant in adventurer_ids:
		var id_str: String = str(id)

		# Check for duplicates
		if seen.has(id_str):
			return ERR_ALREADY_EXISTS
		seen[id_str] = true

		# Check existence
		if not _adventurers.has(id_str):
			return ERR_DOES_NOT_EXIST

		# Check deployability
		var adv: AdventurerData = _adventurers[id_str]
		if not adv.is_available:
			return ERR_UNAVAILABLE

	return OK


## Returns the current party as an array of AdventurerData instances.
## Filters out IDs that no longer exist in the roster.
func get_party() -> Array:
	var result: Array = []
	for id: String in _current_party:
		var adv: AdventurerData = _adventurers.get(id, null)
		if adv != null:
			result.append(adv)
	return result


## Returns a copy of the current party ID array.
func get_party_ids() -> Array[String]:
	return _current_party.duplicate()


## Returns the number of adventurers in the current party.
func get_party_size() -> int:
	return _current_party.size()


## Clears the current party.
func clear_party() -> void:
	_current_party.clear()


# ---------------------------------------------------------------------------
# Name Generation (Private)
# ---------------------------------------------------------------------------

## Generates a procedural name for an adventurer of the given class.
## Handles duplicate names by appending Roman numeral suffixes.
func _generate_name(rng: DeterministicRNG, adventurer_class: Enums.AdventurerClass) -> String:
	var names: Array = NAME_TABLES.get(adventurer_class, ["Unknown"])
	var base_name: String = names[rng.randi(names.size())]

	# Count how many times this base name already exists in the roster
	var count: int = _count_name_occurrences(base_name)

	if count == 0:
		return base_name

	# Append Roman numeral suffix
	if count < _ROMAN_NUMERALS.size():
		return base_name + _ROMAN_NUMERALS[count]
	return base_name + " " + str(count + 1)


## Counts how many existing adventurers share the given base name.
## Strips any existing Roman numeral suffix for comparison.
func _count_name_occurrences(base_name: String) -> int:
	var count: int = 0
	for adv: AdventurerData in _adventurers.values():
		var existing_base: String = _strip_numeral_suffix(adv.display_name)
		if existing_base == base_name:
			count += 1
	return count


## Strips a Roman numeral suffix (e.g., " II", " III") from a name.
func _strip_numeral_suffix(name: String) -> String:
	for i in range(_ROMAN_NUMERALS.size() - 1, 0, -1):
		if name.ends_with(_ROMAN_NUMERALS[i]):
			return name.substr(0, name.length() - _ROMAN_NUMERALS[i].length())
	return name


# ---------------------------------------------------------------------------
# ID Generation (Private)
# ---------------------------------------------------------------------------

## Generates a unique adventurer ID in the format "adv_<class>_<counter>".
func _generate_id(adventurer_class: Enums.AdventurerClass) -> String:
	var short: String = CLASS_SHORT_NAMES.get(adventurer_class, "unk")
	var id: String = "adv_%s_%03d" % [short, _next_id_counter]
	_next_id_counter += 1
	return id


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serializes the entire roster to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
	var adv_dict: Dictionary = {}
	for id: String in _adventurers:
		adv_dict[id] = _adventurers[id].to_dict()

	var party_strings: Array = []
	for id: String in _current_party:
		party_strings.append(id)

	return {
		"adventurers": adv_dict,
		"current_party": party_strings,
		"max_roster_size": max_roster_size,
		"next_id_counter": _next_id_counter,
	}


## Reconstructs the roster from a serialized Dictionary.
## Handles missing/corrupt data gracefully.
func from_dict(data: Dictionary) -> void:
	_adventurers.clear()
	_current_party.clear()

	# Restore max roster size
	max_roster_size = int(data.get("max_roster_size", DEFAULT_MAX_ROSTER_SIZE))

	# Restore ID counter
	_next_id_counter = int(data.get("next_id_counter", 1))
	if _next_id_counter < 1:
		_next_id_counter = 1

	# Restore adventurers
	var raw_adventurers: Variant = data.get("adventurers", {})
	if raw_adventurers is Dictionary:
		var adv_data: Dictionary = raw_adventurers as Dictionary
		for key: Variant in adv_data.keys():
			var entry: Variant = adv_data[key]
			if entry is Dictionary:
				var adv: AdventurerData = AdventurerData.from_dict(entry as Dictionary)
				if adv.id != "":
					_adventurers[adv.id] = adv

	# Restore current party (only IDs that exist in the restored roster)
	var raw_party: Variant = data.get("current_party", [])
	if raw_party is Array:
		for id_val: Variant in raw_party:
			var id_str: String = str(id_val)
			if _adventurers.has(id_str):
				_current_party.append(id_str)
