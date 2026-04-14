## Unit tests for the EventBus autoload singleton.
## Verifies all six core-loop signals are declared, typed, and emittable.
extends GutTest


func test_event_bus_is_node() -> void:
	var bus := EventBus.new()
	assert_is(bus, Node, "EventBus must extend Node")
	bus.free()


func test_seed_planted_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("seed_planted"), "EventBus must have seed_planted signal")
	bus.free()


func test_seed_matured_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("seed_matured"), "EventBus must have seed_matured signal")
	bus.free()


func test_expedition_started_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("expedition_started"), "EventBus must have expedition_started signal")
	bus.free()


func test_expedition_completed_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("expedition_completed"), "EventBus must have expedition_completed signal")
	bus.free()


func test_loot_gained_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("loot_gained"), "EventBus must have loot_gained signal")
	bus.free()


func test_adventurer_recruited_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("adventurer_recruited"), "EventBus must have adventurer_recruited signal")
	bus.free()


func test_seed_planted_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.seed_planted.emit(&"oak_seed", 0)
	assert_signal_emitted(bus, "seed_planted")
	bus.queue_free()


func test_seed_matured_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.seed_matured.emit(&"oak_seed", 0)
	assert_signal_emitted(bus, "seed_matured")
	bus.queue_free()


func test_expedition_started_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	var party: Array[StringName] = [&"warrior_01", &"mage_01"]
	bus.expedition_started.emit(&"forest_dungeon", party)
	assert_signal_emitted(bus, "expedition_started")
	bus.queue_free()


func test_expedition_completed_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.expedition_completed.emit(&"forest_dungeon", true, 42)
	assert_signal_emitted(bus, "expedition_completed")
	bus.queue_free()


func test_loot_gained_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.loot_gained.emit(&"iron_ore", 5, &"dungeon_chest")
	assert_signal_emitted(bus, "loot_gained")
	bus.queue_free()


func test_adventurer_recruited_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.adventurer_recruited.emit(&"hero_001", &"warrior")
	assert_signal_emitted(bus, "adventurer_recruited")
	bus.queue_free()
