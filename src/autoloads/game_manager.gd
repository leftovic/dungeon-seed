## GameManager — Lifecycle-managing singleton for Dungeon Seed.
##
## Holds references to all active domain services and provides orderly
## initialize/shutdown sequencing. Services are registered as typed
## nullable properties that downstream tasks will populate.
##
## Usage:
##   GameManager.initialize()       # Call from main scene _ready()
##   GameManager.is_initialized()   # Check before accessing services
##   GameManager.shutdown()         # Call on game exit
##
## IMPORTANT: initialize() is NOT called in _ready(). The main scene
## or a bootstrap script must call it explicitly. This allows test
## harnesses and menus to exist without full game state.
class_name GameManager
extends Node


# ─── Signals ──────────────────────────────────────────────────────────

## Emitted after all services have been initialized and the game is ready.
signal game_initialized

## Emitted after all services have been shut down cleanly.
signal game_shutdown


# ─── Service References ───────────────────────────────────────────────
## These are typed as RefCounted (the common base for non-Node services).
## Downstream tasks will replace the type annotations with concrete types.

## Reference to the SeedGrove service (manages seed collection and planting).
var seed_grove: RefCounted = null

## Reference to the Roster service (manages adventurer team).
var roster: RefCounted = null

## Reference to the Wallet service (manages currencies and resources).
var wallet: RefCounted = null

## Reference to the LoopController service (manages the core game loop).
var loop_controller: RefCounted = null


# ─── Private State ────────────────────────────────────────────────────

## Whether initialize() has been called successfully.
var _initialized: bool = false


# ─── Lifecycle ────────────────────────────────────────────────────────

## Returns whether the GameManager has been initialized.
func is_initialized() -> bool:
	return _initialized


## Initializes all game services in the correct order.
## Call this from the main scene's _ready() or a bootstrap script.
## Safe to call multiple times — subsequent calls are no-ops.
func initialize() -> void:
	if _initialized:
		push_warning("GameManager.initialize() called but already initialized. Ignoring.")
		return

	# Future: instantiate and wire up services here.
	# seed_grove = SeedGroveService.new()
	# roster = RosterService.new()
	# wallet = WalletService.new()
	# loop_controller = LoopControllerService.new()

	_initialized = true
	game_initialized.emit()
	print("[GameManager] Initialized.")


## Shuts down all game services in reverse order.
## Call this on game exit or when returning to the title screen.
## Safe to call without prior initialize() — will no-op gracefully.
func shutdown() -> void:
	if not _initialized:
		push_warning("GameManager.shutdown() called but not initialized. Ignoring.")
		return

	# Future: tear down services in reverse order.
	# loop_controller = null
	# wallet = null
	# roster = null
	# seed_grove = null

	_initialized = false
	game_shutdown.emit()
	print("[GameManager] Shut down.")
