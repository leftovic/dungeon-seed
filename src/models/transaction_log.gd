class_name TransactionLog
extends RefCounted
## Fixed-capacity circular buffer recording financial transactions.
##
## Stores the last N transaction entries with O(1) append and O(n) retrieval.
## Each entry captures timestamp, type, currency, amount, and resulting balance.
## When capacity is reached, oldest entries are overwritten (circular buffer).
##
## Usage:
##   var log := TransactionLog.new(100)
##   log.record("credit", Enums.Currency.GOLD, 50, 150)
##   var recent: Array[Dictionary] = log.get_recent(10)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Default maximum number of entries the log can hold.
const DEFAULT_MAX_ENTRIES: int = 100


# ---------------------------------------------------------------------------
# Internal State
# ---------------------------------------------------------------------------

## Fixed-size array holding transaction entries. Size = _max_entries.
## Empty slots are represented by empty dictionaries {}.
var _entries: Array[Dictionary] = []

## Maximum capacity of the log. Cannot be changed after construction.
var _max_entries: int = DEFAULT_MAX_ENTRIES

## Current write position in the circular buffer (0 to _max_entries-1).
var _write_index: int = 0

## Number of populated entries (0 to _max_entries). Caps at _max_entries.
var _count: int = 0


# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

## Creates a new transaction log with the specified capacity.
##
## @param max_entries: Maximum number of entries to retain. Must be > 0.
func _init(max_entries: int = DEFAULT_MAX_ENTRIES) -> void:
	_max_entries = maxi(max_entries, 1)  # Enforce minimum capacity of 1
	_entries.resize(_max_entries)
	for i in range(_max_entries):
		_entries[i] = {}
	_write_index = 0
	_count = 0


# ---------------------------------------------------------------------------
# Public Methods — Recording
# ---------------------------------------------------------------------------

## Records a new transaction entry in the log.
##
## Creates an entry with 5 keys: timestamp, type, currency, amount, balance_after.
## Overwrites the oldest entry if the log is at capacity.
##
## @param type: Transaction type string (e.g., "credit", "debit", "shop_purchase").
## @param currency: The currency type affected (Enums.Currency enum value).
## @param amount: The signed amount of the transaction (+ for credit, - for debit).
## @param balance: The balance after this transaction was applied.
func record(type: String, currency: Enums.Currency, amount: int, balance: int) -> void:
	var entry: Dictionary = {
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"type": type,
		"currency": currency,
		"amount": amount,
		"balance_after": balance,
	}

	_entries[_write_index] = entry
	_write_index = (_write_index + 1) % _max_entries
	_count = mini(_count + 1, _max_entries)


# ---------------------------------------------------------------------------
# Public Methods — Retrieval
# ---------------------------------------------------------------------------

## Returns the N most recent transaction entries in chronological order.
##
## If count > available entries, returns all available entries.
## Returns defensive copies — modifying returned dictionaries does not affect the log.
##
## @param count: Number of recent entries to retrieve.
## @return: Array of transaction dictionaries, oldest to newest.
func get_recent(count: int) -> Array[Dictionary]:
	if count <= 0 or _count == 0:
		return []

	var actual_count: int = mini(count, _count)
	var result: Array[Dictionary] = []
	result.resize(actual_count)

	# Calculate starting position: go back actual_count entries from write_index
	var start_index: int = (_write_index - actual_count + _max_entries) % _max_entries

	for i in range(actual_count):
		var read_index: int = (start_index + i) % _max_entries
		result[i] = _entries[read_index].duplicate()

	return result


## Returns all populated entries in the log in chronological order (oldest to newest).
##
## @return: Array of all transaction dictionaries.
func get_all() -> Array[Dictionary]:
	return get_recent(_count)


## Returns the number of entries currently stored in the log.
##
## @return: Entry count (0 to _max_entries).
func get_count() -> int:
	return _count


# ---------------------------------------------------------------------------
# Public Methods — Clear
# ---------------------------------------------------------------------------

## Clears all entries from the log and resets the write pointer.
##
## After clear(), get_count() returns 0 and get_all() returns an empty array.
func clear() -> void:
	for i in range(_max_entries):
		_entries[i] = {}
	_write_index = 0
	_count = 0


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serializes the log to a Dictionary suitable for JSON/save.
##
## Only exports populated entries (not the full buffer capacity) to minimize save size.
##
## @return: Dictionary with keys "max_entries" and "entries".
func to_dict() -> Dictionary:
	var entries_array: Array = []
	var all_entries: Array[Dictionary] = get_all()
	for entry: Dictionary in all_entries:
		entries_array.append(entry)

	return {
		"max_entries": _max_entries,
		"entries": entries_array,
	}


## Reconstructs the log from a serialized Dictionary.
##
## Validates each entry for required keys and correct types.
## Invalid entries are skipped with a warning.
##
## @param data: Serialized Dictionary from to_dict().
func from_dict(data: Dictionary) -> void:
	# Restore max_entries
	var max_val: Variant = data.get("max_entries", DEFAULT_MAX_ENTRIES)
	var new_max: int = maxi(int(max_val), 1)

	# Reinitialize with the restored capacity
	_max_entries = new_max
	_entries.resize(_max_entries)
	for i in range(_max_entries):
		_entries[i] = {}
	_write_index = 0
	_count = 0

	# Restore entries
	var entries_val: Variant = data.get("entries", [])
	if entries_val is Array:
		var entries_data: Array = entries_val as Array
		for entry_val: Variant in entries_data:
			if entry_val is Dictionary:
				var entry: Dictionary = entry_val as Dictionary
				if _is_valid_entry(entry):
					# Replay the entry using record() to maintain circular buffer semantics
					record(
						entry.get("type", "") as String,
						entry.get("currency", 0) as Enums.Currency,
						entry.get("amount", 0) as int,
						entry.get("balance_after", 0) as int
					)
				else:
					push_warning("TransactionLog.from_dict: Invalid entry skipped")


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

## Validates that an entry dictionary has all required keys with correct types.
##
## @param entry: Dictionary to validate.
## @return: True if valid, false otherwise.
func _is_valid_entry(entry: Dictionary) -> bool:
	if not entry.has("timestamp"):
		return false
	if not entry.has("type"):
		return false
	if not entry.has("currency"):
		return false
	if not entry.has("amount"):
		return false
	if not entry.has("balance_after"):
		return false

	# Validate types
	var ts: Variant = entry["timestamp"]
	if not (ts is float or ts is int):
		return false

	var t: Variant = entry["type"]
	if not (t is String):
		return false

	var c: Variant = entry["currency"]
	if not (c is int):
		return false

	var a: Variant = entry["amount"]
	if not (a is int):
		return false

	var b: Variant = entry["balance_after"]
	if not (b is int):
		return false

	return true
