## tests/models/test_wallet.gd
## GUT test suite for TASK-008: Wallet — 4-Currency Wallet with Atomic Transactions
## Tests the complete wallet system: balances, credit/debit, atomic transactions, and serialization.
extends GutTest

const Wallet = preload("res://src/models/wallet.gd")

var _wallet: Wallet


func before_each() -> void:
	_wallet = Wallet.new()


# ---------------------------------------------------------------------------
# Section A — Construction & Initialization
# ---------------------------------------------------------------------------

func test_fresh_wallet_all_balances_zero() -> void:
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 0, "Gold should start at 0")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 0, "Essence should start at 0")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 0, "Fragments should start at 0")
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 0, "Artifacts should start at 0")


func test_fresh_wallet_has_transaction_log() -> void:
	var log = _wallet.get_transaction_log()
	assert_not_null(log, "Wallet should have a transaction log")
	assert_eq(log.get_count(), 0, "Fresh wallet log should be empty")


# ---------------------------------------------------------------------------
# Section B — get_balance()
# ---------------------------------------------------------------------------

func test_get_balance_gold() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 500, "Gold balance should be 500")


func test_get_balance_essence() -> void:
	_wallet.credit(Enums.Currency.ESSENCE, 100)
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 100, "Essence balance should be 100")


func test_get_balance_fragments() -> void:
	_wallet.credit(Enums.Currency.FRAGMENTS, 25)
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 25, "Fragments balance should be 25")


func test_get_balance_artifacts() -> void:
	_wallet.credit(Enums.Currency.ARTIFACTS, 3)
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 3, "Artifacts balance should be 3")


func test_get_balance_after_multiple_credits() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.GOLD, 200)
	_wallet.credit(Enums.Currency.GOLD, 50)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 350, "Gold should accumulate to 350")


# ---------------------------------------------------------------------------
# Section C — credit()
# ---------------------------------------------------------------------------

func test_credit_gold_increases_balance() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Crediting 100 Gold should increase balance")


func test_credit_multiple_currencies() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	_wallet.credit(Enums.Currency.ESSENCE, 50)
	_wallet.credit(Enums.Currency.FRAGMENTS, 10)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 500)
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 50)
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 10)


func test_credit_zero_amount_is_noop() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.GOLD, 0)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Crediting 0 should not change balance")


func test_credit_negative_amount_rejected() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.GOLD, -50)  # Should be rejected
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Negative credit should be rejected")


func test_credit_records_transaction_log_entry() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var log = _wallet.get_transaction_log()
	assert_eq(log.get_count(), 1, "Log should have 1 entry after credit")
	var entries: Array[Dictionary] = log.get_all()
	assert_eq(entries[0]["type"], "credit")
	assert_eq(entries[0]["currency"], Enums.Currency.GOLD)
	assert_eq(entries[0]["amount"], 100)
	assert_eq(entries[0]["balance_after"], 100)


# ---------------------------------------------------------------------------
# Section D — debit()
# ---------------------------------------------------------------------------

func test_debit_decreases_balance() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	var success: bool = _wallet.debit(Enums.Currency.GOLD, 200)
	assert_true(success, "Debit should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 300, "Balance should be 300 after debit")


func test_debit_exact_balance() -> void:
	_wallet.credit(Enums.Currency.ESSENCE, 100)
	var success: bool = _wallet.debit(Enums.Currency.ESSENCE, 100)
	assert_true(success, "Debit of exact balance should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 0, "Balance should be 0")


func test_debit_insufficient_funds_fails() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var success: bool = _wallet.debit(Enums.Currency.GOLD, 200)
	assert_false(success, "Debit should fail when insufficient funds")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Balance should remain unchanged")


func test_debit_zero_balance_fails() -> void:
	var success: bool = _wallet.debit(Enums.Currency.GOLD, 50)
	assert_false(success, "Debit should fail on zero balance")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 0, "Balance should remain 0")


func test_debit_zero_amount_is_noop() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var success: bool = _wallet.debit(Enums.Currency.GOLD, 0)
	assert_true(success, "Debit of 0 should succeed (no-op)")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Balance unchanged after 0 debit")


func test_debit_negative_amount_rejected() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var success: bool = _wallet.debit(Enums.Currency.GOLD, -50)
	assert_false(success, "Negative debit should be rejected")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Balance should remain unchanged")


func test_debit_records_transaction_log_entry() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	_wallet.debit(Enums.Currency.GOLD, 200)
	var log = _wallet.get_transaction_log()
	assert_eq(log.get_count(), 2, "Log should have 2 entries (credit + debit)")
	var entries: Array[Dictionary] = log.get_all()
	assert_eq(entries[1]["type"], "debit")
	assert_eq(entries[1]["currency"], Enums.Currency.GOLD)
	assert_eq(entries[1]["amount"], -200)
	assert_eq(entries[1]["balance_after"], 300)


func test_debit_failed_does_not_log() -> void:
	_wallet.credit(Enums.Currency.GOLD, 50)
	_wallet.debit(Enums.Currency.GOLD, 100)  # Should fail
	var log = _wallet.get_transaction_log()
	assert_eq(log.get_count(), 1, "Failed debit should not create log entry")


# ---------------------------------------------------------------------------
# Section E — can_afford()
# ---------------------------------------------------------------------------

func test_can_afford_single_currency_sufficient() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	var costs: Dictionary = {Enums.Currency.GOLD: 300}
	assert_true(_wallet.can_afford(costs), "Should afford 300 Gold")


func test_can_afford_single_currency_insufficient() -> void:
	_wallet.credit(Enums.Currency.GOLD, 200)
	var costs: Dictionary = {Enums.Currency.GOLD: 300}
	assert_false(_wallet.can_afford(costs), "Should not afford 300 Gold")


func test_can_afford_multi_currency_sufficient() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	_wallet.credit(Enums.Currency.ESSENCE, 100)
	var costs: Dictionary = {Enums.Currency.GOLD: 200, Enums.Currency.ESSENCE: 50}
	assert_true(_wallet.can_afford(costs), "Should afford multi-currency cost")


func test_can_afford_multi_currency_one_insufficient() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	_wallet.credit(Enums.Currency.ESSENCE, 30)
	var costs: Dictionary = {Enums.Currency.GOLD: 200, Enums.Currency.ESSENCE: 50}
	assert_false(_wallet.can_afford(costs), "Should fail if any currency insufficient")


func test_can_afford_empty_costs() -> void:
	var costs: Dictionary = {}
	assert_true(_wallet.can_afford(costs), "Empty costs should always be affordable")


func test_can_afford_zero_cost_currency() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var costs: Dictionary = {Enums.Currency.GOLD: 0}
	assert_true(_wallet.can_afford(costs), "Zero cost should be affordable")


func test_can_afford_negative_cost_rejected() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var costs: Dictionary = {Enums.Currency.GOLD: -50}
	assert_false(_wallet.can_afford(costs), "Negative costs should be rejected")


# ---------------------------------------------------------------------------
# Section F — transact() Atomic Transactions
# ---------------------------------------------------------------------------

func test_transact_simple_debit() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	var costs: Dictionary = {Enums.Currency.GOLD: 200}
	var gains: Dictionary = {}
	var success: bool = _wallet.transact(costs, gains)
	assert_true(success, "Transaction should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 300, "Gold should be 300 after debit")


func test_transact_simple_credit() -> void:
	var costs: Dictionary = {}
	var gains: Dictionary = {Enums.Currency.ESSENCE: 50}
	var success: bool = _wallet.transact(costs, gains)
	assert_true(success, "Transaction should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 50, "Essence should be 50 after credit")


func test_transact_exchange_gold_for_essence() -> void:
	_wallet.credit(Enums.Currency.GOLD, 1000)
	var costs: Dictionary = {Enums.Currency.GOLD: 500}
	var gains: Dictionary = {Enums.Currency.ESSENCE: 100}
	var success: bool = _wallet.transact(costs, gains)
	assert_true(success, "Exchange should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 500, "Gold should be 500")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 100, "Essence should be 100")


func test_transact_multi_currency_cost() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	_wallet.credit(Enums.Currency.ESSENCE, 100)
	var costs: Dictionary = {Enums.Currency.GOLD: 200, Enums.Currency.ESSENCE: 50}
	var gains: Dictionary = {Enums.Currency.FRAGMENTS: 10}
	var success: bool = _wallet.transact(costs, gains)
	assert_true(success, "Multi-currency transaction should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 300)
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 50)
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 10)


func test_transact_insufficient_funds_all_or_nothing() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.ESSENCE, 100)
	var costs: Dictionary = {Enums.Currency.GOLD: 200, Enums.Currency.ESSENCE: 50}
	var gains: Dictionary = {Enums.Currency.FRAGMENTS: 10}
	var success: bool = _wallet.transact(costs, gains)
	assert_false(success, "Transaction should fail")
	# ATOMICITY: No balances should change
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Gold unchanged after failed transaction")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 100, "Essence unchanged")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 0, "Fragments unchanged")


func test_transact_empty_costs_and_gains() -> void:
	var costs: Dictionary = {}
	var gains: Dictionary = {}
	var success: bool = _wallet.transact(costs, gains)
	assert_true(success, "Empty transaction should succeed (no-op)")


func test_transact_logs_all_modified_currencies() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	var costs: Dictionary = {Enums.Currency.GOLD: 200}
	var gains: Dictionary = {Enums.Currency.ESSENCE: 50}
	_wallet.transact(costs, gains)
	var log = _wallet.get_transaction_log()
	# Initial credit (1) + transact debit (1) + transact credit (1) = 3
	assert_eq(log.get_count(), 3, "Should have 3 log entries")


func test_transact_failed_does_not_log() -> void:
	_wallet.credit(Enums.Currency.GOLD, 50)
	var initial_count: int = _wallet.get_transaction_log().get_count()
	var costs: Dictionary = {Enums.Currency.GOLD: 100}
	var gains: Dictionary = {Enums.Currency.ESSENCE: 50}
	_wallet.transact(costs, gains)  # Should fail
	assert_eq(_wallet.get_transaction_log().get_count(), initial_count, "Failed transaction should not log")


# ---------------------------------------------------------------------------
# Section G — reset()
# ---------------------------------------------------------------------------

func test_reset_zeros_all_balances() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	_wallet.credit(Enums.Currency.ESSENCE, 100)
	_wallet.reset()
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 0, "Gold should be 0 after reset")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 0, "Essence should be 0 after reset")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 0, "Fragments should be 0 after reset")
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 0, "Artifacts should be 0 after reset")


func test_reset_clears_transaction_log() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.debit(Enums.Currency.GOLD, 50)
	_wallet.reset()
	assert_eq(_wallet.get_transaction_log().get_count(), 0, "Log should be empty after reset")


# ---------------------------------------------------------------------------
# Section H — Serialization (to_dict / from_dict)
# ---------------------------------------------------------------------------

func test_to_dict_has_required_keys() -> void:
	var data: Dictionary = _wallet.to_dict()
	assert_true(data.has("balances"), "to_dict() must have 'balances' key")
	assert_true(data.has("log"), "to_dict() must have 'log' key")


func test_to_dict_balances_structure() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	_wallet.credit(Enums.Currency.ESSENCE, 100)
	var data: Dictionary = _wallet.to_dict()
	var balances: Dictionary = data["balances"]
	assert_eq(balances[Enums.Currency.GOLD], 500)
	assert_eq(balances[Enums.Currency.ESSENCE], 100)
	assert_eq(balances[Enums.Currency.FRAGMENTS], 0)
	assert_eq(balances[Enums.Currency.ARTIFACTS], 0)


func test_round_trip_serialization() -> void:
	_wallet.credit(Enums.Currency.GOLD, 1000)
	_wallet.credit(Enums.Currency.ESSENCE, 250)
	_wallet.credit(Enums.Currency.FRAGMENTS, 50)
	_wallet.credit(Enums.Currency.ARTIFACTS, 5)
	_wallet.debit(Enums.Currency.GOLD, 300)

	var data: Dictionary = _wallet.to_dict()
	var restored: Wallet = Wallet.new()
	restored.from_dict(data)

	assert_eq(restored.get_balance(Enums.Currency.GOLD), 700, "Gold should be 700 after restore")
	assert_eq(restored.get_balance(Enums.Currency.ESSENCE), 250)
	assert_eq(restored.get_balance(Enums.Currency.FRAGMENTS), 50)
	assert_eq(restored.get_balance(Enums.Currency.ARTIFACTS), 5)
	assert_eq(restored.get_transaction_log().get_count(), 5, "Log should have 5 entries")


func test_from_dict_handles_missing_currencies() -> void:
	var data: Dictionary = {
		"balances": {Enums.Currency.GOLD: 500},
		"log": {"max_entries": 100, "entries": []}
	}
	var restored: Wallet = Wallet.new()
	restored.from_dict(data)
	assert_eq(restored.get_balance(Enums.Currency.GOLD), 500)
	assert_eq(restored.get_balance(Enums.Currency.ESSENCE), 0, "Missing currencies default to 0")


func test_from_dict_clamps_negative_balances() -> void:
	var data: Dictionary = {
		"balances": {Enums.Currency.GOLD: -100},
		"log": {"max_entries": 100, "entries": []}
	}
	var restored: Wallet = Wallet.new()
	restored.from_dict(data)
	assert_eq(restored.get_balance(Enums.Currency.GOLD), 0, "Negative balance should clamp to 0")


func test_from_dict_restores_transaction_log() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.ESSENCE, 50)
	var data: Dictionary = _wallet.to_dict()
	var restored: Wallet = Wallet.new()
	restored.from_dict(data)
	assert_eq(restored.get_transaction_log().get_count(), 2, "Log should have 2 entries")


# ---------------------------------------------------------------------------
# Section I — Invariant: No Negative Balances
# ---------------------------------------------------------------------------

func test_invariant_balance_never_negative_after_failed_debit() -> void:
	_wallet.credit(Enums.Currency.GOLD, 50)
	_wallet.debit(Enums.Currency.GOLD, 100)  # Should fail
	assert_ge(_wallet.get_balance(Enums.Currency.GOLD), 0, "Balance must never go negative")


func test_invariant_balance_never_negative_after_failed_transact() -> void:
	_wallet.credit(Enums.Currency.GOLD, 50)
	var costs: Dictionary = {Enums.Currency.GOLD: 100}
	var gains: Dictionary = {Enums.Currency.ESSENCE: 50}
	_wallet.transact(costs, gains)  # Should fail
	assert_ge(_wallet.get_balance(Enums.Currency.GOLD), 0, "Balance must never go negative")
	assert_ge(_wallet.get_balance(Enums.Currency.ESSENCE), 0, "Essence must remain 0 (not credited)")


# ---------------------------------------------------------------------------
# Section J — Edge Cases
# ---------------------------------------------------------------------------

func test_credit_large_amount() -> void:
	_wallet.credit(Enums.Currency.GOLD, 999999999)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 999999999, "Should handle large amounts")


func test_transact_same_currency_cost_and_gain() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	var costs: Dictionary = {Enums.Currency.GOLD: 200}
	var gains: Dictionary = {Enums.Currency.GOLD: 100}
	var success: bool = _wallet.transact(costs, gains)
	assert_true(success, "Transaction should succeed")
	# Net: 500 - 200 + 100 = 400
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 400, "Should handle same-currency cost+gain")


func test_multiple_transactions_preserve_consistency() -> void:
	_wallet.credit(Enums.Currency.GOLD, 1000)
	for i in range(10):
		_wallet.debit(Enums.Currency.GOLD, 50)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 500, "Balance should be 500 after 10 debits of 50")
