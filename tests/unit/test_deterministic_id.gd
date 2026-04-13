extends Node

func _ready():
	print("[test_deterministic_id] starting")
	# Load the deterministic ID generator
	var gen_script := load("res://src/gdscript/utils/deterministic_id_impl.gd")
	if gen_script == null:
		push_error("Failed to load deterministic_id.gd")
		get_tree().quit()
	var gen = gen_script.new()
	var id = gen.generate("player123", 1672543200000, 1, "namespace")
	print("Generated ID:", id)
	# Basic checks
	if typeof(id) != TYPE_STRING:
		push_error("ID is not a string")
	# ensure the id contains 3 dashes (epoch, playerhex, counter, sig)
	if id.split("-").size() < 4:
		push_error("ID format unexpected: %s" % id)
	# Ensure headless test exits cleanly
	gen.free()
	get_tree().quit()

