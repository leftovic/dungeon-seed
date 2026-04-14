class_name SaveService
extends RefCounted
## Manages saving and loading game state to JSON files on disk.
##
## Supports multiple save slots, version-tagged manifests with forward
## migration, structural validation, and atomic writes to prevent corruption.
## This service is stateless — it holds no cached data between calls.


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## The current save manifest schema version. Increment when the format changes.
const CURRENT_VERSION: int = 2

## Maximum number of save slots available to the player.
const MAX_SLOTS: int = 3

## Directory path under user:// where save files are stored.
const SAVE_DIR: String = "user://saves/"

## Maximum allowed save file size in bytes (1 MB). Files larger than this
## are rejected to prevent out-of-memory conditions from malicious or
## corrupted files.
const MAX_SAVE_SIZE_BYTES: int = 1_048_576

## Required top-level keys in a valid save manifest.
const REQUIRED_KEYS: Array[String] = [
	"version",
	"timestamp",
	"slot",
	"seeds",
	"dungeon",
	"adventurers",
	"inventory",
	"wallet",
	"loop_state",
	"settings",
]


# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------

## Serializes [param game_state] to JSON and writes it to the specified
## [param slot] (1 through MAX_SLOTS). Injects version, timestamp, and slot
## metadata before writing. Returns [code]true[/code] on success,
## [code]false[/code] on any failure.
func save_game(slot: int, game_state: Dictionary) -> bool:
	if not _is_valid_slot(slot):
		push_warning("SaveService: save_game(%d) failed — slot out of range [1, %d]" % [slot, MAX_SLOTS])
		return false

	# Ensure save directory exists
	if not _ensure_save_directory():
		push_error("SaveService: save_game(%d) failed — cannot create save directory" % slot)
		return false

	# Inject metadata
	game_state["version"] = CURRENT_VERSION
	game_state["timestamp"] = int(Time.get_unix_time_from_system())
	game_state["slot"] = slot

	# Serialize to JSON
	var json_text: String = JSON.stringify(game_state, "\t")
	if json_text.is_empty():
		push_error("SaveService: save_game(%d) failed — JSON.stringify returned empty string" % slot)
		return false

	# Atomic write: write to temp file first, then rename
	var temp_path: String = _get_temp_path(slot)
	var final_path: String = _get_slot_path(slot)

	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: save_game(%d) failed — cannot open temp file: %s" % [slot, temp_path])
		return false

	file.store_string(json_text)
	file.close()

	# Rename temp to final (atomic on most filesystems)
	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir == null:
		push_error("SaveService: save_game(%d) failed — cannot open save directory for rename" % slot)
		_remove_file(temp_path)
		return false

	# Remove existing final file if present (rename may fail if target exists on some OS)
	if FileAccess.file_exists(final_path):
		dir.remove(_file_name_from_path(final_path))

	var rename_error: int = dir.rename(_file_name_from_path(temp_path), _file_name_from_path(final_path))
	if rename_error != OK:
		push_error("SaveService: save_game(%d) failed — rename error code %d" % [slot, rename_error])
		_remove_file(temp_path)
		return false

	return true


## Loads and deserializes the save file from the specified [param slot].
## Returns the game state Dictionary on success, or an empty Dictionary
## on any failure (missing file, corrupted data, validation failure).
## Automatically migrates old save versions to CURRENT_VERSION.
func load_game(slot: int) -> Dictionary:
	if not _is_valid_slot(slot):
		push_warning("SaveService: load_game(%d) failed — slot out of range [1, %d]" % [slot, MAX_SLOTS])
		return {}

	var path: String = _get_slot_path(slot)

	if not FileAccess.file_exists(path):
		return {}

	# File size guard
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveService: load_game(%d) failed — cannot open file" % slot)
		return {}

	var file_size: int = file.get_length()
	if file_size > MAX_SAVE_SIZE_BYTES:
		push_error("SaveService: load_game(%d) failed — file size %d exceeds limit %d" % [slot, file_size, MAX_SAVE_SIZE_BYTES])
		file.close()
		return {}

	var text: String = file.get_as_text()
	file.close()

	# Parse JSON
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_warning("SaveService: load_game(%d) failed — JSON parse returned null (corrupted file)" % slot)
		return {}

	if not (parsed is Dictionary):
		push_warning("SaveService: load_game(%d) failed — parsed JSON is not a Dictionary" % slot)
		return {}

	var data: Dictionary = parsed as Dictionary

	# Migration
	var file_version: int = data.get("version", 0)
	if file_version > 0 and file_version < CURRENT_VERSION:
		data = migrate(data, file_version, CURRENT_VERSION)

	# Validation
	if not _validate(data):
		push_warning("SaveService: load_game(%d) failed — validation failed after load/migration" % slot)
		return {}

	return data


## Returns metadata for all save slots. Each entry contains:
## [code]slot[/code] (int), [code]timestamp[/code] (int), and
## [code]exists[/code] (bool). Always returns exactly MAX_SLOTS entries.
func list_slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i: int in range(1, MAX_SLOTS + 1):
		var entry: Dictionary = {"slot": i, "timestamp": 0, "exists": false}
		var path: String = _get_slot_path(i)

		if FileAccess.file_exists(path):
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file != null:
				var text: String = file.get_as_text()
				file.close()
				var parsed: Variant = JSON.parse_string(text)
				if parsed != null and parsed is Dictionary:
					var dict: Dictionary = parsed as Dictionary
					if dict.has("timestamp"):
						entry["timestamp"] = dict.get("timestamp", 0)
						entry["exists"] = true

		result.append(entry)
	return result


## Deletes the save file for the specified [param slot]. Returns
## [code]true[/code] if the file was removed or did not exist (idempotent).
## Returns [code]false[/code] for invalid slot numbers or if removal fails.
func delete_slot(slot: int) -> bool:
	if not _is_valid_slot(slot):
		push_warning("SaveService: delete_slot(%d) failed — slot out of range [1, %d]" % [slot, MAX_SLOTS])
		return false

	var final_path: String = _get_slot_path(slot)
	var temp_path: String = _get_temp_path(slot)

	# Remove main file
	_remove_file(final_path)

	# Remove temp file if leftover
	_remove_file(temp_path)

	# Success means "file is gone" — true even if it didn't exist
	return not FileAccess.file_exists(final_path)


## Applies sequential version-step migrations to [param data] from
## [param from_version] to [param to_version]. Each step is a dedicated
## private method. Returns the migrated Dictionary.
func migrate(data: Dictionary, from_version: int, to_version: int) -> Dictionary:
	if from_version < 1:
		push_error("SaveService: migrate() — invalid from_version %d" % from_version)
		return data

	if to_version > CURRENT_VERSION:
		push_error("SaveService: migrate() — invalid to_version %d (CURRENT_VERSION is %d)" % [to_version, CURRENT_VERSION])
		return data

	if from_version >= to_version:
		return data

	var current: Dictionary = data
	var version_cursor: int = from_version

	while version_cursor < to_version:
		match version_cursor:
			1:
				current = _migrate_v1_to_v2(current)
			_:
				push_error("SaveService: migrate() — no migration defined for v%d to v%d" % [version_cursor, version_cursor + 1])
				return current
		version_cursor += 1

	return current


## Validates the structural integrity of a save manifest Dictionary.
## Checks that all required top-level keys exist and have correct types.
## Returns [code]true[/code] if valid, [code]false[/code] otherwise.
func _validate(data: Dictionary) -> bool:
	# Check all required keys exist
	for key: String in REQUIRED_KEYS:
		if not data.has(key):
			push_warning("SaveService: _validate() failed — missing required key '%s'" % key)
			return false

	# version: int in [1, CURRENT_VERSION]
	var version: Variant = data["version"]
	if not (version is int or version is float):
		push_warning("SaveService: _validate() failed — 'version' is not numeric")
		return false
	var version_int: int = int(version)
	if version_int < 1 or version_int > CURRENT_VERSION:
		push_warning("SaveService: _validate() failed — 'version' %d out of range [1, %d]" % [version_int, CURRENT_VERSION])
		return false

	# timestamp: positive int
	var timestamp: Variant = data["timestamp"]
	if not (timestamp is int or timestamp is float):
		push_warning("SaveService: _validate() failed — 'timestamp' is not numeric")
		return false
	if int(timestamp) <= 0:
		push_warning("SaveService: _validate() failed — 'timestamp' %d is not positive" % int(timestamp))
		return false

	# slot: int in [1, MAX_SLOTS]
	var slot_val: Variant = data["slot"]
	if not (slot_val is int or slot_val is float):
		push_warning("SaveService: _validate() failed — 'slot' is not numeric")
		return false
	var slot_int: int = int(slot_val)
	if slot_int < 1 or slot_int > MAX_SLOTS:
		push_warning("SaveService: _validate() failed — 'slot' %d out of range [1, %d]" % [slot_int, MAX_SLOTS])
		return false

	# seeds: Array
	if not (data["seeds"] is Array):
		push_warning("SaveService: _validate() failed — 'seeds' is not an Array")
		return false

	# adventurers: Array
	if not (data["adventurers"] is Array):
		push_warning("SaveService: _validate() failed — 'adventurers' is not an Array")
		return false

	# dungeon: Dictionary
	if not (data["dungeon"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'dungeon' is not a Dictionary")
		return false

	# inventory: Dictionary with 'items' key
	if not (data["inventory"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'inventory' is not a Dictionary")
		return false
	var inventory: Dictionary = data["inventory"] as Dictionary
	if not inventory.has("items"):
		push_warning("SaveService: _validate() failed — 'inventory' missing 'items' key")
		return false

	# wallet: Dictionary
	if not (data["wallet"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'wallet' is not a Dictionary")
		return false

	# loop_state: Dictionary
	if not (data["loop_state"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'loop_state' is not a Dictionary")
		return false

	# settings: Dictionary
	if not (data["settings"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'settings' is not a Dictionary")
		return false

	return true


# ---------------------------------------------------------------------------
# Migration Methods
# ---------------------------------------------------------------------------

## Migrates a v1 save manifest to v2.
## Changes:
##   - Restructures player_gold (int) into wallet Dictionary
##   - Adds loop_state.auto_harvest_enabled (default false)
##   - Adds settings.colorblind_mode (default "none")
##   - Adds settings.text_size (default "medium")
func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	# Restructure player_gold into wallet
	if not data.has("wallet") or not (data["wallet"] is Dictionary):
		var old_gold: int = data.get("player_gold", 0)
		data["wallet"] = {
			"gold": old_gold,
			"gems": 0,
			"essence": 0,
			"dust": 0,
		}
	# Remove old field if present
	if data.has("player_gold"):
		data.erase("player_gold")

	# Add auto_harvest_enabled to loop_state
	if data.has("loop_state") and data["loop_state"] is Dictionary:
		var loop_state: Dictionary = data["loop_state"] as Dictionary
		if not loop_state.has("auto_harvest_enabled"):
			loop_state["auto_harvest_enabled"] = false

	# Add colorblind_mode and text_size to settings
	if data.has("settings") and data["settings"] is Dictionary:
		var settings: Dictionary = data["settings"] as Dictionary
		if not settings.has("colorblind_mode"):
			settings["colorblind_mode"] = "none"
		if not settings.has("text_size"):
			settings["text_size"] = "medium"

	# Update version
	data["version"] = 2

	return data


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

## Returns the file path for a given save slot.
func _get_slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_" + str(slot) + ".json"


## Returns the temporary file path for a given save slot (used for atomic writes).
func _get_temp_path(slot: int) -> String:
	return _get_slot_path(slot) + ".tmp"


## Returns whether the given slot number is in the valid range [1, MAX_SLOTS].
func _is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= MAX_SLOTS


## Ensures the save directory exists. Returns true on success.
func _ensure_save_directory() -> bool:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return false
	if not dir.dir_exists("saves"):
		var err: int = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			return false
	return true


## Removes a file at the given path if it exists. Silent no-op if missing.
func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var dir_path: String = path.get_base_dir()
		var file_name: String = path.get_file()
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir != null:
			dir.remove(file_name)


## Extracts the file name from a full path for DirAccess operations.
func _file_name_from_path(path: String) -> String:
	return path.get_file()
