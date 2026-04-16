extends RefCounted
## Core Loop Orchestrator — the cultivation cycle heartbeat.
##
## Coordinates the game's main loop: PLANT → GROW → EXPLORE → HARVEST → REINVEST.
## Bridges all game services into a cohesive runtime by:
##   1. Advancing idle growth timers via SeedGrove.tick()
##   2. Managing adventurer condition recovery (Injured → Fatigued → Healthy)
##   3. Orchestrating expedition launch: validate → generate → run → reward → consume
##   4. Triggering auto-saves at key moments (after planting, after expedition)
##
## All dependencies are injected via initialize(). No autoload references.
## @file src/services/core_loop.gd
## @task TASK-017


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Seconds for Injured → Fatigued recovery (30 minutes).
const INJURED_RECOVERY_SECONDS: float = 1800.0

## Seconds for Fatigued → Healthy recovery (15 minutes).
const FATIGUED_RECOVERY_SECONDS: float = 900.0

## Seconds for Exhausted → Fatigued recovery (30 minutes, same as injured).
const EXHAUSTED_RECOVERY_SECONDS: float = 1800.0

## Default auto-save slot. SaveService accepts slots 1–3.
const AUTO_SAVE_SLOT: int = 1


# ---------------------------------------------------------------------------
# Dependencies (injected via initialize)
# ---------------------------------------------------------------------------

var _seed_grove = null
var _dungeon_generator = null
var _expedition_runner = null
var _reward_processor = null
var _loot_engine = null
var _adventurer_roster = null
var _equipment_manager = null
var _wallet = null
var _inventory = null
var _save_service = null
var _rng = null

## True after initialize() has been called successfully.
var _initialized: bool = false

## Condition recovery tracker.
## Maps adventurer_id (String) → { "condition": String, "remaining": float }.
var _condition_timers: Dictionary = {}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Initialize the orchestrator with all dependency services.
## Config keys: seed_grove, dungeon_generator, expedition_runner,
## reward_processor, loot_engine, adventurer_roster, equipment_manager,
## wallet, inventory, save_service, rng.
func initialize(config: Dictionary) -> void:
	_seed_grove = config.get("seed_grove")
	_dungeon_generator = config.get("dungeon_generator")
	_expedition_runner = config.get("expedition_runner")
	_reward_processor = config.get("reward_processor")
	_loot_engine = config.get("loot_engine")
	_adventurer_roster = config.get("adventurer_roster")
	_equipment_manager = config.get("equipment_manager")
	_wallet = config.get("wallet")
	_inventory = config.get("inventory")
	_save_service = config.get("save_service")
	_rng = config.get("rng")
	_initialized = true


## Process idle ticks — call each frame or on reconnect for offline catch-up.
## Advances seed growth timers and adventurer condition recovery.
##
## Returns: { "seeds_advanced": Array, "conditions_updated": Array, "offline_rewards": Dictionary }
func process_tick(delta_seconds: float) -> Dictionary:
	var result: Dictionary = {
		"seeds_advanced": [],
		"conditions_updated": [],
		"offline_rewards": {},
	}

	if not _initialized or delta_seconds <= 0.0:
		return result

	# --- Advance seed growth ---
	if _seed_grove != null:
		var events = _seed_grove.tick(delta_seconds)
		result["seeds_advanced"] = events

	# --- Update condition recovery ---
	_process_condition_recovery(delta_seconds, result["conditions_updated"])

	return result


## Plant a seed in a grove slot.
## Validates slot range, occupancy, and seed validity before delegating to SeedGrove.
##
## Returns: { "success": bool, "message": String }
func plant_seed(slot: int, seed_data: RefCounted) -> Dictionary:
	if not _initialized:
		return {"success": false, "message": "Not initialized"}
	if seed_data == null:
		return {"success": false, "message": "Seed is null"}
	if _seed_grove == null:
		return {"success": false, "message": "No seed grove"}

	# Validate slot range
	if slot < 0 or slot >= _seed_grove.max_grove_slots:
		return {"success": false, "message": "Invalid slot: %d" % slot}

	# Check if this slot index is already occupied
	var planted = _seed_grove.get_planted_seeds()
	if slot < planted.size():
		return {"success": false, "message": "Slot %d is occupied" % slot}

	# Check grove capacity
	if _seed_grove.get_available_slots() <= 0:
		return {"success": false, "message": "No available grove slots"}

	# Add to grove inventory and plant
	_seed_grove.add_seed(seed_data)
	var ok: bool = _seed_grove.plant_seed(seed_data)
	if not ok:
		return {"success": false, "message": "Planting failed"}

	_auto_save()
	return {"success": true, "message": "Planted in slot %d" % slot}


## Launch an expedition from a bloom-ready seed.
## Full flow: validate → generate dungeon → run expedition → process rewards
##            → apply conditions → consume seed → auto-save.
##
## Returns: merged expedition result + reward summary + success/message keys.
func launch_expedition(slot: int, party_ids: Array) -> Dictionary:
	if not _initialized:
		return {"success": false, "message": "Not initialized"}

	# --- Validate seed ---
	if _seed_grove == null:
		return {"success": false, "message": "No seed grove"}

	var planted = _seed_grove.get_planted_seeds()
	if slot < 0 or slot >= planted.size():
		return {"success": false, "message": "No seed in slot %d" % slot}

	var seed_data = planted[slot]
	if seed_data.phase != Enums.SeedPhase.BLOOM:
		return {"success": false, "message": "Seed not at BLOOM phase"}

	# --- Validate party ---
	if party_ids.is_empty():
		return {"success": false, "message": "Party is empty"}

	# Check for duplicate IDs
	var seen_ids: Dictionary = {}
	for pid in party_ids:
		var pid_str: String = str(pid)
		if seen_ids.has(pid_str):
			return {"success": false, "message": "Duplicate party member: %s" % pid_str}
		seen_ids[pid_str] = true

	if _adventurer_roster == null:
		return {"success": false, "message": "No adventurer roster"}

	var party: Array = []
	for pid in party_ids:
		var pid_str: String = str(pid)
		var adv = _adventurer_roster.get_adventurer(pid_str)
		if adv == null:
			return {"success": false, "message": "Adventurer not found: %s" % pid_str}
		if not adv.is_available:
			return {"success": false, "message": "Adventurer unavailable: %s" % pid_str}
		party.append(adv)

	# --- Generate dungeon ---
	if _dungeon_generator == null:
		return {"success": false, "message": "No dungeon generator"}

	var dungeon = _dungeon_generator.generate(seed_data)
	if dungeon == null:
		return {"success": false, "message": "Dungeon generation failed"}

	# --- Run expedition ---
	if _expedition_runner == null:
		return {"success": false, "message": "No expedition runner"}

	var exp_result = _expedition_runner.run_expedition(dungeon, party, _rng, _loot_engine)
	if exp_result == null or exp_result.is_empty():
		return {"success": false, "message": "Expedition execution failed"}

	# --- Process rewards ---
	var reward_summary: Dictionary = {}
	if _reward_processor != null:
		reward_summary = _reward_processor.process_rewards(exp_result, party, _wallet, _inventory)

	# --- Apply post-expedition conditions ---
	_apply_post_expedition_conditions(reward_summary)

	# --- Consume the seed ---
	_seed_grove.remove_seed(seed_data.id)

	# --- Auto-save ---
	_auto_save()

	# --- Build merged result ---
	var merged: Dictionary = exp_result.duplicate(true)
	merged["reward_summary"] = reward_summary
	merged["success"] = true
	merged["message"] = "Expedition complete"
	return merged


## Get current game state summary.
## Aggregates grove, roster, wallet, and condition state.
func get_state_summary() -> Dictionary:
	if not _initialized:
		return {}

	var summary: Dictionary = {
		"grove_slots": [],
		"available_adventurers": [],
		"wallet_balances": {},
		"conditions": _condition_timers.duplicate(true),
	}

	# --- Grove slots ---
	if _seed_grove != null:
		var planted = _seed_grove.get_planted_seeds()
		for i in range(planted.size()):
			var s = planted[i]
			summary["grove_slots"].append({
				"slot": i,
				"seed_id": s.id,
				"phase": int(s.phase),
			})
		# Add empty slot placeholders up to max
		for i in range(planted.size(), _seed_grove.max_grove_slots):
			summary["grove_slots"].append({
				"slot": i,
				"seed_id": "",
				"phase": -1,
			})

	# --- Available adventurers ---
	if _adventurer_roster != null:
		for adv in _adventurer_roster.get_all_adventurers():
			if adv != null and adv.is_available:
				summary["available_adventurers"].append({
					"id": adv.id,
					"name": adv.display_name,
					"class": int(adv.adventurer_class),
					"level": adv.level,
				})

	# --- Wallet balances ---
	if _wallet != null:
		for c in [Enums.Currency.GOLD, Enums.Currency.ESSENCE,
				Enums.Currency.FRAGMENTS, Enums.Currency.ARTIFACTS]:
			summary["wallet_balances"][c] = _wallet.get_balance(c)

	return summary


## Returns the current condition string for an adventurer.
## Returns "healthy" if no recovery timer is active.
func get_condition(adventurer_id: String) -> String:
	if _condition_timers.has(adventurer_id):
		return _condition_timers[adventurer_id]["condition"]
	return "healthy"


## Returns remaining recovery seconds for an adventurer, or 0.0 if healthy.
func get_condition_remaining(adventurer_id: String) -> float:
	if _condition_timers.has(adventurer_id):
		return _condition_timers[adventurer_id]["remaining"]
	return 0.0


# ---------------------------------------------------------------------------
# Private — Condition Recovery
# ---------------------------------------------------------------------------

## Processes condition recovery timers with cascading.
## A large delta can push injured → fatigued → healthy in one call.
func _process_condition_recovery(delta: float, updates: Array) -> void:
	var ids_to_remove: Array = []

	for adv_id: String in _condition_timers.keys():
		var tracker: Dictionary = _condition_timers[adv_id]
		var remaining_delta: float = delta

		while remaining_delta > 0.0:
			if tracker["remaining"] <= remaining_delta:
				# Timer fully depleted — transition to next condition
				remaining_delta -= tracker["remaining"]
				var old_cond: String = tracker["condition"]

				if old_cond == "injured" or old_cond == "exhausted":
					# Transition to fatigued
					tracker["condition"] = "fatigued"
					tracker["remaining"] = FATIGUED_RECOVERY_SECONDS
					_set_adventurer_available(adv_id, true)
					updates.append({
						"adventurer_id": adv_id,
						"old_condition": old_cond,
						"new_condition": "fatigued",
					})
				elif old_cond == "fatigued":
					# Fully recovered
					ids_to_remove.append(adv_id)
					_set_adventurer_available(adv_id, true)
					updates.append({
						"adventurer_id": adv_id,
						"old_condition": "fatigued",
						"new_condition": "healthy",
					})
					break
				else:
					# Unknown condition — remove tracker
					ids_to_remove.append(adv_id)
					break
			else:
				# Partial depletion — reduce timer and stop
				tracker["remaining"] -= remaining_delta
				remaining_delta = 0.0

	for adv_id in ids_to_remove:
		_condition_timers.erase(adv_id)


## Sets is_available on an adventurer via the roster.
func _set_adventurer_available(adv_id: String, available: bool) -> void:
	if _adventurer_roster == null:
		return
	var adv = _adventurer_roster.get_adventurer(adv_id)
	if adv != null:
		adv.is_available = available


# ---------------------------------------------------------------------------
# Private — Post-Expedition Conditions
# ---------------------------------------------------------------------------

## Reads adventurer_conditions from reward summary and starts recovery timers.
## Fatigued adventurers remain available for expeditions.
func _apply_post_expedition_conditions(reward_summary: Dictionary) -> void:
	var conditions: Dictionary = reward_summary.get("adventurer_conditions", {})
	for adv_id: String in conditions:
		var cond: String = conditions[adv_id]
		match cond:
			"injured":
				_condition_timers[adv_id] = {
					"condition": "injured",
					"remaining": INJURED_RECOVERY_SECONDS,
				}
				_set_adventurer_available(adv_id, false)
			"exhausted":
				_condition_timers[adv_id] = {
					"condition": "exhausted",
					"remaining": EXHAUSTED_RECOVERY_SECONDS,
				}
				_set_adventurer_available(adv_id, false)
			"fatigued":
				_condition_timers[adv_id] = {
					"condition": "fatigued",
					"remaining": FATIGUED_RECOVERY_SECONDS,
				}
				# Fatigued adventurers can still launch expeditions
				_set_adventurer_available(adv_id, true)


# ---------------------------------------------------------------------------
# Private — Auto-Save
# ---------------------------------------------------------------------------

## Triggers an auto-save with the current game state.
func _auto_save() -> void:
	if _save_service == null:
		return
	var state: Dictionary = _build_game_state()
	_save_service.save_game(AUTO_SAVE_SLOT, state)


## Builds a serializable game state dictionary for the save system.
## Includes all required keys for SaveService validation.
func _build_game_state() -> Dictionary:
	var state: Dictionary = {
		"seeds": [],
		"dungeon": {},
		"adventurers": [],
		"inventory": {},
		"wallet": {},
		"loop_state": {
			"condition_timers": _condition_timers.duplicate(true),
		},
		"settings": {},
	}

	if _seed_grove != null:
		for seed_obj in _seed_grove.get_planted_seeds():
			if seed_obj != null and seed_obj.has_method("to_dict"):
				state["seeds"].append(seed_obj.to_dict())

	if _adventurer_roster != null:
		for adv in _adventurer_roster.get_all_adventurers():
			if adv != null and adv.has_method("to_dict"):
				state["adventurers"].append(adv.to_dict())

	if _inventory != null and _inventory.has_method("to_dict"):
		state["inventory"] = _inventory.to_dict()

	if _wallet != null and _wallet.has_method("to_dict"):
		state["wallet"] = _wallet.to_dict()

	return state
