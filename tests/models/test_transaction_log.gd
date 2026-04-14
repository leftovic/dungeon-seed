## tests/models/test_transaction_log.gd
## GUT test suite for TASK-008: TransactionLog — Circular Buffer Transaction Logger
## Tests a fixed-capacity circular buffer recording financial transactions.
extends GutTest

const TransactionLog = preload("res://src/models/transaction_log.gd")

var _log: TransactionLog


# ---------------------------------------------------------------------------
# Section A — Construction & Initialization
# ---------------------------------------------------------------------------

func test_default_capacity_is_100() -> void:
	_log = TransactionLog.new()
	var serialized: Dictionary = _log.to_dict()
	assert_eq(serialized["max_entries"], 100, "Default capacity should be 100")


func test_custom_capacity() -> void:
	_log = TransactionLog.new(50)
	var serialized: Dictionary = _log.to_dict()
	assert_eq(serialized["max_entries"], 50, "Custom capacity should be 50")


func test_initial_count_is_zero() -> void:
	_log = TransactionLog.new()
	assert_eq(_log.get_count(), 0, "Fresh log should have count 0")


func test_initial_get_all_is_empty() -> void:
	_log = TransactionLog.new()
	var all_entries: Array[Dictionary] = _log.get_all()
	assert_eq(all_entries.size(), 0, "Fresh log should have no entries")


# ---------------------------------------------------------------------------
# Section B — Recording Entries
# ---------------------------------------------------------------------------

func test_record_single_entry() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	assert_eq(_log.get_count(), 1, "Should have 1 entry after recording")


func test_record_entry_has_five_keys() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	var entries: Array[Dictionary] = _log.get_all()
	var entry: Dictionary = entries[0]
	assert_true(entry.has("timestamp"), "Entry must have 'timestamp' key")
	assert_true(entry.has("type"), "Entry must have 'type' key")
	assert_true(entry.has("currency"), "Entry must have 'currency' key")
	assert_true(entry.has("amount"), "Entry must have 'amount' key")
	assert_true(entry.has("balance_after"), "Entry must have 'balance_after' key")


func test_record_entry_values_are_correct() -> void:
	_log = TransactionLog.new()
	_log.record("debit", Enums.Currency.ESSENCE, -50, 150)
	var entries: Array[Dictionary] = _log.get_all()
	var entry: Dictionary = entries[0]
	assert_eq(entry["type"], "debit", "Type should be 'debit'")
	assert_eq(entry["currency"], Enums.Currency.ESSENCE, "Currency should be ESSENCE")
	assert_eq(entry["amount"], -50, "Amount should be -50")
	assert_eq(entry["balance_after"], 150, "Balance should be 150")
	assert_typeof(entry["timestamp"], TYPE_FLOAT, "Timestamp should be a float")


func test_record_multiple_entries() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	_log.record("credit", Enums.Currency.GOLD, 50, 150)
	_log.record("debit", Enums.Currency.GOLD, -30, 120)
	assert_eq(_log.get_count(), 3, "Should have 3 entries")


# ---------------------------------------------------------------------------
# Section C — get_recent()
# ---------------------------------------------------------------------------

func test_get_recent_returns_requested_count() -> void:
	_log = TransactionLog.new()
	for i in range(10):
		_log.record("credit", Enums.Currency.GOLD, 10, 10 * (i + 1))
	var recent: Array[Dictionary] = _log.get_recent(5)
	assert_eq(recent.size(), 5, "get_recent(5) should return 5 entries")


func test_get_recent_returns_most_recent_entries() -> void:
	_log = TransactionLog.new()
	for i in range(10):
		_log.record("credit", Enums.Currency.GOLD, 10, 10 * (i + 1))
	var recent: Array[Dictionary] = _log.get_recent(3)
	# Most recent 3 should have balance_after: 80, 90, 100
	assert_eq(recent[0]["balance_after"], 80, "First of recent 3 should be 80")
	assert_eq(recent[1]["balance_after"], 90, "Second should be 90")
	assert_eq(recent[2]["balance_after"], 100, "Third should be 100")


func test_get_recent_chronological_order() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	_log.record("credit", Enums.Currency.GOLD, 50, 150)
	_log.record("debit", Enums.Currency.GOLD, -30, 120)
	var recent: Array[Dictionary] = _log.get_recent(3)
	# Should be in chronological order: 100 → 150 → 120
	assert_eq(recent[0]["balance_after"], 100)
	assert_eq(recent[1]["balance_after"], 150)
	assert_eq(recent[2]["balance_after"], 120)


func test_get_recent_more_than_available() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	_log.record("credit", Enums.Currency.GOLD, 50, 150)
	var recent: Array[Dictionary] = _log.get_recent(10)
	assert_eq(recent.size(), 2, "Should return only 2 entries when requesting 10 but only 2 exist")


func test_get_recent_zero_count() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	var recent: Array[Dictionary] = _log.get_recent(0)
	assert_eq(recent.size(), 0, "get_recent(0) should return empty array")


func test_get_recent_returns_defensive_copy() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	var recent: Array[Dictionary] = _log.get_recent(1)
	recent[0]["amount"] = 9999  # Try to modify returned entry
	var check: Array[Dictionary] = _log.get_recent(1)
	assert_eq(check[0]["amount"], 100, "Modifying returned entry should not affect internal state")


# ---------------------------------------------------------------------------
# Section D — Circular Buffer Wrapping
# ---------------------------------------------------------------------------

func test_circular_buffer_overwrite() -> void:
	_log = TransactionLog.new(3)  # Capacity 3
	_log.record("credit", Enums.Currency.GOLD, 10, 10)
	_log.record("credit", Enums.Currency.GOLD, 20, 30)
	_log.record("credit", Enums.Currency.GOLD, 30, 60)
	_log.record("credit", Enums.Currency.GOLD, 40, 100)  # Overwrites first entry
	assert_eq(_log.get_count(), 3, "Count should cap at max_entries")
	var all_entries: Array[Dictionary] = _log.get_all()
	assert_eq(all_entries[0]["balance_after"], 30, "Oldest entry should now be the second one")


func test_circular_buffer_multiple_overwrites() -> void:
	_log = TransactionLog.new(5)
	for i in range(10):
		_log.record("credit", Enums.Currency.GOLD, 10, 10 * (i + 1))
	assert_eq(_log.get_count(), 5, "Count should cap at 5")
	var recent: Array[Dictionary] = _log.get_recent(5)
	# Last 5 balances should be: 60, 70, 80, 90, 100
	assert_eq(recent[0]["balance_after"], 60)
	assert_eq(recent[4]["balance_after"], 100)


func test_circular_buffer_get_recent_after_wrap() -> void:
	_log = TransactionLog.new(4)
	for i in range(7):
		_log.record("credit", Enums.Currency.GOLD, 10, 10 * (i + 1))
	var recent: Array[Dictionary] = _log.get_recent(3)
	# Last 3 should be: 50, 60, 70
	assert_eq(recent[0]["balance_after"], 50)
	assert_eq(recent[2]["balance_after"], 70)


# ---------------------------------------------------------------------------
# Section E — get_all() / get_count()
# ---------------------------------------------------------------------------

func test_get_all_returns_all_entries_in_order() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 10, 10)
	_log.record("credit", Enums.Currency.GOLD, 20, 30)
	_log.record("credit", Enums.Currency.GOLD, 30, 60)
	var all_entries: Array[Dictionary] = _log.get_all()
	assert_eq(all_entries.size(), 3)
	assert_eq(all_entries[0]["balance_after"], 10)
	assert_eq(all_entries[1]["balance_after"], 30)
	assert_eq(all_entries[2]["balance_after"], 60)


func test_get_count_increments_correctly() -> void:
	_log = TransactionLog.new()
	assert_eq(_log.get_count(), 0)
	_log.record("credit", Enums.Currency.GOLD, 10, 10)
	assert_eq(_log.get_count(), 1)
	_log.record("credit", Enums.Currency.GOLD, 10, 20)
	assert_eq(_log.get_count(), 2)


func test_get_count_caps_at_max_entries() -> void:
	_log = TransactionLog.new(3)
	for i in range(10):
		_log.record("credit", Enums.Currency.GOLD, 10, 10 * (i + 1))
	assert_eq(_log.get_count(), 3, "Count should cap at max_entries")


# ---------------------------------------------------------------------------
# Section F — clear()
# ---------------------------------------------------------------------------

func test_clear_resets_count() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	_log.record("credit", Enums.Currency.GOLD, 50, 150)
	_log.clear()
	assert_eq(_log.get_count(), 0, "Count should be 0 after clear")


func test_clear_empties_get_all() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	_log.clear()
	var all_entries: Array[Dictionary] = _log.get_all()
	assert_eq(all_entries.size(), 0, "get_all() should return empty after clear")


func test_record_after_clear_works() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	_log.clear()
	_log.record("credit", Enums.Currency.ESSENCE, 50, 50)
	assert_eq(_log.get_count(), 1, "Should have 1 entry after clear and new record")
	var entries: Array[Dictionary] = _log.get_all()
	assert_eq(entries[0]["currency"], Enums.Currency.ESSENCE)


# ---------------------------------------------------------------------------
# Section G — Serialization (to_dict / from_dict)
# ---------------------------------------------------------------------------

func test_to_dict_has_required_keys() -> void:
	_log = TransactionLog.new()
	var data: Dictionary = _log.to_dict()
	assert_true(data.has("max_entries"), "to_dict() must have 'max_entries' key")
	assert_true(data.has("entries"), "to_dict() must have 'entries' key")


func test_to_dict_max_entries_value() -> void:
	_log = TransactionLog.new(75)
	var data: Dictionary = _log.to_dict()
	assert_eq(data["max_entries"], 75, "max_entries should match constructor value")


func test_to_dict_entries_count() -> void:
	_log = TransactionLog.new()
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	_log.record("credit", Enums.Currency.GOLD, 50, 150)
	var data: Dictionary = _log.to_dict()
	assert_eq(data["entries"].size(), 2, "entries array should have 2 elements")


func test_to_dict_only_populated_entries() -> void:
	_log = TransactionLog.new(10)
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	var data: Dictionary = _log.to_dict()
	# Should only have 1 entry, not all 10 slots
	assert_eq(data["entries"].size(), 1, "to_dict() should only export populated entries")


func test_round_trip_serialization() -> void:
	_log = TransactionLog.new(50)
	_log.record("credit", Enums.Currency.GOLD, 100, 100)
	_log.record("debit", Enums.Currency.ESSENCE, -25, 75)
	_log.record("credit", Enums.Currency.FRAGMENTS, 10, 10)

	var data: Dictionary = _log.to_dict()
	var restored: TransactionLog = TransactionLog.new()
	restored.from_dict(data)

	assert_eq(restored.get_count(), 3, "Restored log should have 3 entries")
	assert_eq(restored.to_dict()["max_entries"], 50, "Restored max_entries should be 50")

	var entries: Array[Dictionary] = restored.get_all()
	assert_eq(entries[0]["amount"], 100)
	assert_eq(entries[1]["currency"], Enums.Currency.ESSENCE)
	assert_eq(entries[2]["balance_after"], 10)


func test_round_trip_after_circular_overwrite() -> void:
	_log = TransactionLog.new(3)
	for i in range(5):
		_log.record("credit", Enums.Currency.GOLD, 10, 10 * (i + 1))

	var data: Dictionary = _log.to_dict()
	var restored: TransactionLog = TransactionLog.new()
	restored.from_dict(data)

	assert_eq(restored.get_count(), 3, "Restored should have 3 entries (max capacity)")
	var entries: Array[Dictionary] = restored.get_all()
	# Last 3 balances: 30, 40, 50
	assert_eq(entries[0]["balance_after"], 30)
	assert_eq(entries[2]["balance_after"], 50)
