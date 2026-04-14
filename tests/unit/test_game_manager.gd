## Unit tests for the GameManager autoload singleton.
## Verifies lifecycle methods, initialization state, and service placeholders.
extends GutTest


func test_game_manager_is_node() -> void:
	var gm := GameManager.new()
	assert_is(gm, Node, "GameManager must extend Node")
	gm.free()


func test_not_initialized_by_default() -> void:
	var gm := GameManager.new()
	assert_false(gm.is_initialized(), "GameManager must not be initialized by default")
	gm.free()


func test_initialize_sets_flag() -> void:
	var gm := GameManager.new()
	add_child(gm)
	gm.initialize()
	assert_true(gm.is_initialized(), "initialize() must set _initialized to true")
	gm.queue_free()


func test_initialize_emits_signal() -> void:
	var gm := GameManager.new()
	add_child(gm)
	watch_signals(gm)
	gm.initialize()
	assert_signal_emitted(gm, "game_initialized")
	gm.queue_free()


func test_shutdown_clears_flag() -> void:
	var gm := GameManager.new()
	add_child(gm)
	gm.initialize()
	gm.shutdown()
	assert_false(gm.is_initialized(), "shutdown() must set _initialized to false")
	gm.queue_free()


func test_shutdown_emits_signal() -> void:
	var gm := GameManager.new()
	add_child(gm)
	watch_signals(gm)
	gm.initialize()
	gm.shutdown()
	assert_signal_emitted(gm, "game_shutdown")
	gm.queue_free()


func test_service_properties_default_to_null() -> void:
	var gm := GameManager.new()
	assert_null(gm.seed_grove, "seed_grove must default to null")
	assert_null(gm.roster, "roster must default to null")
	assert_null(gm.wallet, "wallet must default to null")
	assert_null(gm.loop_controller, "loop_controller must default to null")
	gm.free()


func test_double_initialize_is_safe() -> void:
	var gm := GameManager.new()
	add_child(gm)
	gm.initialize()
	gm.initialize()
	assert_true(gm.is_initialized(), "Double initialize must not break state")
	gm.queue_free()


func test_shutdown_without_initialize_is_safe() -> void:
	var gm := GameManager.new()
	add_child(gm)
	gm.shutdown()
	assert_false(gm.is_initialized(), "Shutdown without init must not break state")
	gm.queue_free()
