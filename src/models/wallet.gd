class_name Wallet
extends RefCounted
## 4-currency wallet with atomic transaction support and transaction logging.
##
## Manages Gold, Essence, Fragments, and Artifacts balances with the following guarantees:
## - No balance can ever become negative
## - Multi-currency transactions are atomic (all-or-nothing)
## - Every balance mutation is logged
## - Serialization is round-trip consistent
##
## Usage:
##   var wallet := Wallet.new()
##   wallet.credit(Enums.Currency.GOLD, 100)
##   if wallet.can_afford({Enums.Currency.GOLD: 50}):
##       wallet.debit(Enums.Currency.GOLD, 50)
##
##   # Atomic multi-currency exchange
##   var costs := {Enums.Currency.GOLD: 200, Enums.Currency.ESSENCE: 15}
##   var gains := {Enums.Currency.FRAGMENTS: 10}
##   if wallet.transact(costs, gains):
##       print("Purchase successful!")


# ---------------------------------------------------------------------------
# Internal State
# ---------------------------------------------------------------------------

## Dictionary mapping Enums.Currency integer values to integer balances.
## Keys: Enums.Currency.GOLD, ESSENCE, FRAGMENTS, ARTIFACTS (0, 1, 2, 3).
## Values: Non-negative integers representing current balances.
var _balances: Dictionary = {}

## Transaction log recording all balance mutations.
var _log: TransactionLog = null


# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

## Creates a new wallet with all balances initialized to zero.
##
## @param log_capacity: Maximum transaction log entries. Default 100.
func _init(log_capacity: int = 100) -> void:
	# Initialize all four currency balances to zero
	_balances[Enums.Currency.GOLD] = 0
	_balances[Enums.Currency.ESSENCE] = 0
	_balances[Enums.Currency.FRAGMENTS] = 0
	_balances[Enums.Currency.ARTIFACTS] = 0

	# Create transaction log
	_log = TransactionLog.new(log_capacity)


# ---------------------------------------------------------------------------
# Public Methods — Balance Queries
# ---------------------------------------------------------------------------

## Returns the current balance of the specified currency.
##
## @param currency: The currency to query (Enums.Currency enum value).
## @return: Non-negative integer balance.
func get_balance(currency: Enums.Currency) -> int:
	return _balances.get(currency, 0)


## Returns the transaction log for debugging and UI display.
##
## @return: The TransactionLog instance.
func get_transaction_log() -> TransactionLog:
	return _log


# ---------------------------------------------------------------------------
# Public Methods — Single-Currency Operations
# ---------------------------------------------------------------------------

## Credits (adds) currency to the wallet.
##
## Guards: Rejects negative or zero amounts (no-op).
## Side effects: Updates balance, records log entry.
##
## @param currency: The currency to credit.
## @param amount: Amount to add. Must be > 0.
func credit(currency: Enums.Currency, amount: int) -> void:
	# Guard: reject invalid amounts
	if amount <= 0:
		return

	# Update balance
	_balances[currency] = _balances[currency] + amount

	# Record transaction
	_log.record("credit", currency, amount, _balances[currency])


## Debits (subtracts) currency from the wallet.
##
## Guards: Rejects if insufficient funds, negative amounts, or zero amounts.
## Side effects: Updates balance and records log entry only on success.
##
## @param currency: The currency to debit.
## @param amount: Amount to subtract. Must be > 0.
## @return: True if debit succeeded, false if insufficient funds or invalid amount.
func debit(currency: Enums.Currency, amount: int) -> bool:
	# Guard: reject invalid amounts
	if amount <= 0:
		return amount == 0  # 0 is a no-op success, negative is failure

	# Guard: insufficient funds
	if _balances[currency] < amount:
		return false

	# Update balance
	_balances[currency] = _balances[currency] - amount

	# Record transaction (negative amount for debit)
	_log.record("debit", currency, -amount, _balances[currency])

	return true


# ---------------------------------------------------------------------------
# Public Methods — Multi-Currency Operations
# ---------------------------------------------------------------------------

## Checks if the wallet has sufficient funds for a multi-currency cost.
##
## @param costs: Dictionary mapping Enums.Currency to integer amounts.
## @return: True if ALL currencies have sufficient balance, false otherwise.
func can_afford(costs: Dictionary) -> bool:
	for currency_key: Variant in costs.keys():
		var currency: Enums.Currency = currency_key as Enums.Currency
		var required: int = costs[currency_key] as int

		# Reject negative costs
		if required < 0:
			return false

		# Check balance
		if _balances[currency] < required:
			return false

	return true


## Executes an atomic multi-currency transaction.
##
## Atomicity guarantee: Either ALL costs are deducted and ALL gains are credited,
## or NOTHING changes. No partial transactions.
##
## Phases:
##   1. Validate: Check all costs can be afforded
##   2. Debit: Subtract all costs
##   3. Credit: Add all gains
##   4. Log: Record one entry per modified currency
##
## @param costs: Dictionary of currencies to deduct.
## @param gains: Dictionary of currencies to add.
## @return: True if transaction succeeded, false if insufficient funds.
func transact(costs: Dictionary, gains: Dictionary) -> bool:
	# Phase 1: Validate all costs
	if not can_afford(costs):
		return false

	# Phase 2: Debit all costs
	for currency_key: Variant in costs.keys():
		var currency: Enums.Currency = currency_key as Enums.Currency
		var amount: int = costs[currency_key] as int

		if amount > 0:
			_balances[currency] = _balances[currency] - amount
			_log.record("debit", currency, -amount, _balances[currency])

	# Phase 3: Credit all gains
	for currency_key: Variant in gains.keys():
		var currency: Enums.Currency = currency_key as Enums.Currency
		var amount: int = gains[currency_key] as int

		if amount > 0:
			_balances[currency] = _balances[currency] + amount
			_log.record("credit", currency, amount, _balances[currency])

	return true


# ---------------------------------------------------------------------------
# Public Methods — Utility
# ---------------------------------------------------------------------------

## Resets the wallet to initial state: all balances zero, log cleared.
##
## Use for new game or full economy reset.
func reset() -> void:
	_balances[Enums.Currency.GOLD] = 0
	_balances[Enums.Currency.ESSENCE] = 0
	_balances[Enums.Currency.FRAGMENTS] = 0
	_balances[Enums.Currency.ARTIFACTS] = 0
	_log.clear()


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serializes the wallet to a Dictionary suitable for JSON/save.
##
## @return: Dictionary with keys "balances" and "log".
func to_dict() -> Dictionary:
	return {
		"balances": _balances.duplicate(),
		"log": _log.to_dict(),
	}


## Reconstructs the wallet from a serialized Dictionary.
##
## Validates and clamps balances to non-negative integers.
## Missing currencies default to 0.
##
## @param data: Serialized Dictionary from to_dict().
func from_dict(data: Dictionary) -> void:
	# Restore balances with validation
	var balances_val: Variant = data.get("balances", {})
	if balances_val is Dictionary:
		var balances_data: Dictionary = balances_val as Dictionary

		for currency_val: int in [
			int(Enums.Currency.GOLD),
			int(Enums.Currency.ESSENCE),
			int(Enums.Currency.FRAGMENTS),
			int(Enums.Currency.ARTIFACTS)
		]:
			var currency: Enums.Currency = currency_val as Enums.Currency
			var amount: int = balances_data.get(currency, 0) as int
			# Clamp to non-negative
			_balances[currency] = maxi(amount, 0)
	else:
		# Invalid data: reset to zero
		reset()
		return

	# Restore transaction log
	var log_val: Variant = data.get("log", {})
	if log_val is Dictionary:
		_log.from_dict(log_val as Dictionary)
	else:
		_log.clear()
