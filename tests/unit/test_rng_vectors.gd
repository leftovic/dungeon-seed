extends Node

func _ready():
	print("[test_rng_vectors] starting")
	var rng_script := load("res://src/gdscript/utils/rng_wrapper_impl.gd")
	if rng_script == null:
		push_error("Failed to load rng_wrapper.gd")
		get_tree().quit()
	var rng = rng_script.new()
	rng.seed(123456789)
	var a = rng.next_u64()
	var b = rng.next_u64()
	print("RNG outputs:", a, b)
	if a == b:
		push_error("RNG returned identical consecutive values")
	rng.free()
	get_tree().quit()

