# Test runner that loads unit test scenes and ensures headless exit
extends Node

func _ready():
    call_deferred("_run_tests")

func _run_tests():
    var tests = ["res://tests/unit/test_deterministic_id.gd", "res://tests/unit/test_rng_vectors.gd"]
    for t in tests:
        print("Running: ", t)
        var scene = load(t).new()
        add_child(scene)
    # If tests don't quit themselves, quit now
    get_tree().quit()
