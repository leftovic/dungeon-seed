extends RefCounted
## Processes expedition results into concrete game state changes.
## Takes raw expedition output and applies XP, loot, currency, and condition updates.
## Stateless service — all state objects passed as parameters.


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const KO_XP_PENALTY: float = 0.5
const FULL_CLEAR_XP_BONUS: float = 0.25
const FULL_CLEAR_GOLD_BONUS: float = 0.50
const EXHAUSTION_HP_THRESHOLD: float = 0.25
const MIN_XP_PER_ADVENTURER: int = 1


# ---------------------------------------------------------------------------
# Public — Main Entry Point
# ---------------------------------------------------------------------------

## Applies all rewards from an expedition result to the game state objects.
## Returns a summary dictionary of everything that changed.
func process_rewards(expedition_result: Dictionary, party: Array, wallet, inventory) -> Dictionary:
	if expedition_result.is_empty():
		return _empty_summary()

	var ko_list: Array = expedition_result.get("adventurers_ko", [])
	var total_xp: int = maxi(expedition_result.get("xp_earned", 0), 0)
	var currency_dict: Dictionary = expedition_result.get("currency", {})
	var loot_array: Array = expedition_result.get("loot", [])

	# Calculate completion bonus first so we can add it to totals
	var completion_bonus: Dictionary = calculate_completion_bonus(expedition_result)
	var bonus_xp: int = completion_bonus.get("bonus_xp", 0)
	var bonus_currency: Dictionary = completion_bonus.get("bonus_currency", {})

	# Distribute XP (base + bonus)
	var xp_results: Dictionary = distribute_xp(total_xp + bonus_xp, party, ko_list)

	# Build xp_per_adventurer and level_ups from xp_results
	var xp_per_adventurer: Dictionary = {}
	var level_ups: Dictionary = {}
	for adv_id: String in xp_results:
		var info: Dictionary = xp_results[adv_id]
		xp_per_adventurer[adv_id] = info.get("xp_received", 0)
		if info.get("leveled_up", false):
			level_ups[adv_id] = {
				"old_level": info.get("old_level", 1),
				"new_level": info.get("new_level", 1),
			}

	# Credit currency (base + bonus)
	var merged_currency: Dictionary = _merge_currency(currency_dict, bonus_currency)
	var currency_earned: Dictionary = credit_currency(merged_currency, wallet)

	# Distribute loot
	var items_received: Array = distribute_loot(loot_array, inventory)

	# Update conditions
	var adventurer_conditions: Dictionary = update_conditions(party, expedition_result)

	return {
		"xp_per_adventurer": xp_per_adventurer,
		"level_ups": level_ups,
		"currency_earned": currency_earned,
		"items_received": items_received,
		"adventurer_conditions": adventurer_conditions,
		"completion_bonus": completion_bonus,
	}


# ---------------------------------------------------------------------------
# Public — XP Distribution
# ---------------------------------------------------------------------------

## Splits XP among party. Surviving members get equal share, KO'd get 50%.
## Returns: {adv_id -> {xp_received, leveled_up, old_level, new_level}}
func distribute_xp(total_xp: int, party: Array, ko_list: Array) -> Dictionary:
	var results: Dictionary = {}

	if party.is_empty() or total_xp <= 0:
		for adv in party:
			if adv == null:
				continue
			results[adv.id] = {
				"xp_received": 0,
				"leveled_up": false,
				"old_level": adv.level,
				"new_level": adv.level,
			}
		return results

	# Calculate XP shares with KO penalty
	var shares: Dictionary = _calculate_xp_shares(total_xp, party, ko_list)

	for adv in party:
		if adv == null:
			continue
		var xp_amount: int = shares.get(adv.id, 0)
		var old_level: int = adv.level
		var leveled_up: bool = false
		if xp_amount > 0:
			leveled_up = adv.gain_xp(xp_amount)
		results[adv.id] = {
			"xp_received": xp_amount,
			"leveled_up": leveled_up,
			"old_level": old_level,
			"new_level": adv.level,
		}

	return results


# ---------------------------------------------------------------------------
# Public — Currency Credits
# ---------------------------------------------------------------------------

## Adds each currency type to wallet. Returns credited amounts.
func credit_currency(currency_dict: Dictionary, wallet) -> Dictionary:
	var credited: Dictionary = {}

	if currency_dict.is_empty() or wallet == null:
		return credited

	for currency_key: Variant in currency_dict:
		var amount: int = int(currency_dict[currency_key])
		if amount > 0:
			wallet.credit(currency_key as Enums.Currency, amount)
			credited[currency_key] = amount

	return credited


# ---------------------------------------------------------------------------
# Public — Loot Distribution
# ---------------------------------------------------------------------------

## Adds items to inventory. Returns list of items added.
func distribute_loot(loot_array: Array, inventory) -> Array:
	var items_added: Array = []

	if loot_array.is_empty() or inventory == null:
		return items_added

	for entry: Variant in loot_array:
		if not entry is Dictionary:
			continue
		var loot_entry: Dictionary = entry as Dictionary
		var item_id: String = str(loot_entry.get("item_id", ""))
		var qty: int = int(loot_entry.get("qty", 0))
		if item_id.is_empty() or qty <= 0:
			continue
		inventory.add_item(item_id, qty)
		items_added.append({"item_id": item_id, "qty": qty})

	return items_added


# ---------------------------------------------------------------------------
# Public — Condition Updates
# ---------------------------------------------------------------------------

## Updates adventurer conditions based on expedition outcome.
## Rules:
##   - Completed: all get Fatigued
##   - Failed: KO'd get Injured, survivors get Fatigued
##   - <25% max HP: Exhausted (overrides Fatigued but not Injured for KO'd)
##   - KO'd + low HP = Injured (worst condition wins)
func update_conditions(party: Array, expedition_result: Dictionary) -> Dictionary:
	var conditions: Dictionary = {}
	var status: int = int(expedition_result.get("status", Enums.ExpeditionStatus.FAILED))
	var ko_list: Array = expedition_result.get("adventurers_ko", [])
	var party_hp: Dictionary = expedition_result.get("party_hp", {})
	var is_completed: bool = (status == Enums.ExpeditionStatus.COMPLETED)

	for adv in party:
		if adv == null:
			continue
		var adv_id: String = adv.id
		var is_ko: bool = ko_list.has(adv_id)
		var max_hp: int = adv.stats.get("health", 1)
		var current_hp: int = int(party_hp.get(adv_id, max_hp))
		var hp_ratio: float = float(current_hp) / float(maxi(max_hp, 1))
		var is_low_hp: bool = hp_ratio < EXHAUSTION_HP_THRESHOLD

		var condition: String = "healthy"

		if is_ko:
			# KO'd always means Injured — worst condition
			condition = "injured"
			adv.is_available = false
		elif is_low_hp:
			# Very low HP = exhausted (worse than fatigued)
			condition = "exhausted"
			adv.is_available = false
		elif is_completed or not is_completed:
			# All non-KO, non-exhausted expedition participants are fatigued
			condition = "fatigued"
			adv.is_available = false

		conditions[adv_id] = condition

	return conditions


# ---------------------------------------------------------------------------
# Public — Completion Bonus
# ---------------------------------------------------------------------------

## Calculates bonus rewards for full dungeon clear.
## Full clear (all rooms): +25% bonus XP, +50% bonus gold
## Boss defeated (completed status): base completion recorded
func calculate_completion_bonus(expedition_result: Dictionary) -> Dictionary:
	var bonus: Dictionary = {
		"bonus_xp": 0,
		"bonus_currency": {},
	}

	if expedition_result.is_empty():
		return bonus

	var rooms_cleared: int = int(expedition_result.get("rooms_cleared", 0))
	var total_rooms: int = int(expedition_result.get("total_rooms", 0))
	var base_xp: int = maxi(int(expedition_result.get("xp_earned", 0)), 0)
	var currency_dict: Dictionary = expedition_result.get("currency", {})
	var status: int = int(expedition_result.get("status", Enums.ExpeditionStatus.FAILED))
	var is_full_clear: bool = total_rooms > 0 and rooms_cleared >= total_rooms

	if is_full_clear:
		bonus["bonus_xp"] = roundi(base_xp * FULL_CLEAR_XP_BONUS)
		var gold_amount: int = int(currency_dict.get(Enums.Currency.GOLD, 0))
		if gold_amount > 0:
			bonus["bonus_currency"][Enums.Currency.GOLD] = roundi(gold_amount * FULL_CLEAR_GOLD_BONUS)

	return bonus


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

func _calculate_xp_shares(total_xp: int, party: Array, ko_list: Array) -> Dictionary:
	var shares: Dictionary = {}
	if party.is_empty():
		return shares

	# Count effective shares: survivors = 1.0, KO'd = KO_XP_PENALTY
	var total_weight: float = 0.0
	var weights: Dictionary = {}
	for adv in party:
		if adv == null:
			continue
		var w: float = KO_XP_PENALTY if ko_list.has(adv.id) else 1.0
		weights[adv.id] = w
		total_weight += w

	if total_weight <= 0.0:
		return shares

	# Distribute proportionally, ensuring minimum
	var xp_per_weight: float = float(total_xp) / total_weight
	for adv in party:
		if adv == null:
			continue
		var raw_xp: int = roundi(xp_per_weight * weights[adv.id])
		shares[adv.id] = maxi(raw_xp, MIN_XP_PER_ADVENTURER)

	return shares


func _merge_currency(base: Dictionary, bonus: Dictionary) -> Dictionary:
	var merged: Dictionary = base.duplicate()
	for key: Variant in bonus:
		var existing: int = int(merged.get(key, 0))
		merged[key] = existing + int(bonus[key])
	return merged


func _empty_summary() -> Dictionary:
	return {
		"xp_per_adventurer": {},
		"level_ups": {},
		"currency_earned": {},
		"items_received": [],
		"adventurer_conditions": {},
		"completion_bonus": {"bonus_xp": 0, "bonus_currency": {}},
	}
