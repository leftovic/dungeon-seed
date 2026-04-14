## EventBus — Central signal bus for Dungeon Seed.
##
## All cross-system communication flows through this singleton.
## Signals map directly to the GDD core-loop transitions:
##   Plant Seed → Grow Dungeon → Monitor → Dispatch → Clear → Harvest → Upgrade → Unlock
##
## Usage:
##   EventBus.seed_planted.connect(_on_seed_planted)
##   EventBus.seed_planted.emit(&"oak_seed", 0)
##
## This autoload is registered FIRST in project.godot to guarantee
## availability when GameManager and all other systems initialize.
class_name EventBus
extends Node


# ─── Core Loop Signals ────────────────────────────────────────────────

## Emitted when a seed is placed into a grove slot.
## [param seed_id] The unique identifier of the seed being planted.
## [param slot_index] The zero-based index of the grove slot.
signal seed_planted(seed_id: StringName, slot_index: int)

## Emitted when a planted seed completes its growth cycle and the dungeon is ready.
## [param seed_id] The unique identifier of the matured seed.
## [param slot_index] The zero-based index of the grove slot.
signal seed_matured(seed_id: StringName, slot_index: int)

## Emitted when an adventuring party is dispatched into a dungeon.
## [param dungeon_id] The unique identifier of the target dungeon.
## [param party_ids] Array of adventurer IDs forming the party.
signal expedition_started(dungeon_id: StringName, party_ids: Array[StringName])

## Emitted when an expedition resolves (success or failure).
## [param dungeon_id] The unique identifier of the completed dungeon.
## [param success] Whether the party cleared the dungeon.
## [param turns_taken] Number of turns the expedition consumed.
signal expedition_completed(dungeon_id: StringName, success: bool, turns_taken: int)

## Emitted when the player gains loot from any source.
## [param item_id] The unique identifier of the gained item.
## [param quantity] The number of items gained.
## [param source] The origin of the loot (e.g., "dungeon_chest", "quest_reward").
signal loot_gained(item_id: StringName, quantity: int, source: StringName)

## Emitted when a new adventurer joins the player's roster.
## [param adventurer_id] The unique identifier of the recruited adventurer.
## [param class_type] The adventurer's class (e.g., "warrior", "mage", "healer").
signal adventurer_recruited(adventurer_id: StringName, class_type: StringName)
