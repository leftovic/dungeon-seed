## Unit tests for DeterministicRNG (TASK-002).
## Covers: determinism, bounds, edge cases, distribution, shuffle, pick, weighted_pick.
##
## Note: Uses preload() to reference DeterministicRNG to avoid class_name
## resolution ordering issues during GUT test collection.
extends GutTest

const RNGScript := preload("res://src/models/rng.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_rng(seed_val: int = 42) -> RefCounted:
	var rng: RefCounted = RNGScript.new()
	rng.seed_int(seed_val)
	return rng

func _make_rng_str(seed_str: String = "FIRE-42") -> RefCounted:
	var rng: RefCounted = RNGScript.new()
	rng.seed_string(seed_str)
	return rng

# ---------------------------------------------------------------------------
# Section A: Instantiation & Class Structure
# ---------------------------------------------------------------------------

func test_extends_ref_counted() -> void:
	var rng: RefCounted = RNGScript.new()
	assert_true(rng is RefCounted, "DeterministicRNG must extend RefCounted")

func test_is_not_node() -> void:
	var rng: Variant = RNGScript.new()
	assert_false(rng is Node, "DeterministicRNG must NOT extend Node")

func test_instantiation_without_scene_tree() -> void:
	var rng: RefCounted = RNGScript.new()
	assert_not_null(rng, "Should instantiate without scene tree")

# ---------------------------------------------------------------------------
# Section B: Seeding
# ---------------------------------------------------------------------------

func test_seed_int_determinism() -> void:
	var a: RefCounted = _make_rng(42)
	var b: RefCounted = _make_rng(42)
	for i in range(1000):
		assert_eq(a.next_int(), b.next_int(),
			"Two instances with same int seed must produce identical sequences at index %d" % i)

func test_seed_string_determinism() -> void:
	var a: RefCounted = _make_rng_str("FIRE-42")
	var b: RefCounted = _make_rng_str("FIRE-42")
	for i in range(1000):
		assert_eq(a.next_int(), b.next_int(),
			"Two instances with same string seed must produce identical sequences at index %d" % i)

func test_seed_int_zero_guard() -> void:
	var rng: RefCounted = _make_rng(0)
	var values: Array[int] = []
	for i in range(10):
		values.append(rng.next_int())
	# With zero guard, state becomes 1, so we should get non-zero and varying values
	var unique: Dictionary = {}
	for v in values:
		unique[v] = true
	assert_gt(unique.size(), 1, "Zero seed must not produce stuck sequence (got %d unique values)" % unique.size())

func test_reseed_resets_sequence() -> void:
	var rng: RefCounted = RNGScript.new()
	rng.seed_int(42)
	var first_run: Array[int] = []
	for i in range(5):
		first_run.append(rng.next_int())
	rng.seed_int(42)
	var second_run: Array[int] = []
	for i in range(5):
		second_run.append(rng.next_int())
	assert_eq(first_run, second_run, "Re-seeding with same value must reset sequence")

func test_different_seeds_different_sequences() -> void:
	var a: RefCounted = _make_rng(42)
	var b: RefCounted = _make_rng(99)
	var match_count: int = 0
	for i in range(100):
		if a.next_int() == b.next_int():
			match_count += 1
	assert_lt(match_count, 5, "Different seeds should produce mostly different values")

func test_different_string_seeds_different_sequences() -> void:
	var a: RefCounted = _make_rng_str("FIRE-42")
	var b: RefCounted = _make_rng_str("ICE-99")
	var match_count: int = 0
	for i in range(100):
		if a.next_int() == b.next_int():
			match_count += 1
	assert_lt(match_count, 5, "Different string seeds should produce mostly different values")

# ---------------------------------------------------------------------------
# Section B2: Hardcoded Test Vectors (AC-003, AC-004)
# ---------------------------------------------------------------------------

func test_seed_int_known_vector() -> void:
	var rng: RefCounted = _make_rng(42)
	var expected: Array[int] = [
		620241905386665794,
		1566258436636488355,
		3550780404650452178,
		8464459097379017928,
		1710211875670464698,
		7943305522655851255,
		2522163688295927527,
		5361532952505838762,
		972328815649197360,
		6306284809447681201,
	]
	for i in range(expected.size()):
		var actual: int = rng.next_int()
		assert_eq(actual, expected[i],
			"seed_int(42) next_int()[%d]: expected %d, got %d" % [i, expected[i], actual])

func test_seed_string_known_vector() -> void:
	var rng: RefCounted = _make_rng_str("FIRE-42")
	var expected: Array[int] = [
		7239256415472327821,
		2212067844919420961,
		4835060072245509658,
		6819840240286055128,
		4984536746944521921,
		6484876506533742032,
		2731468740175570616,
		7491040561996635424,
		9079271182136377363,
		5725102609458634546,
	]
	for i in range(expected.size()):
		var actual: int = rng.next_int()
		assert_eq(actual, expected[i],
			"seed_string('FIRE-42') next_int()[%d]: expected %d, got %d" % [i, expected[i], actual])

# ---------------------------------------------------------------------------
# Section C: next_int()
# ---------------------------------------------------------------------------

func test_next_int_non_negative() -> void:
	var rng: RefCounted = _make_rng(12345)
	for i in range(100000):
		var val: int = rng.next_int()
		if val < 0:
			fail_test("next_int() returned negative value %d at iteration %d" % [val, i])
			return
	pass_test("All 100,000 next_int() values were non-negative")

# ---------------------------------------------------------------------------
# Section D: randf()
# ---------------------------------------------------------------------------

func test_randf_bounds() -> void:
	var rng: RefCounted = _make_rng(777)
	for i in range(100000):
		var val: float = rng.randf()
		if val < 0.0 or val >= 1.0:
			fail_test("randf() returned %f at iteration %d (must be [0.0, 1.0))" % [val, i])
			return
	pass_test("All 100,000 randf() values in [0.0, 1.0)")

func test_randf_determinism() -> void:
	var a: RefCounted = _make_rng(42)
	var b: RefCounted = _make_rng(42)
	for i in range(1000):
		assert_eq(a.randf(), b.randf(), "randf() must be deterministic at index %d" % i)

# ---------------------------------------------------------------------------
# Section E: randi()
# ---------------------------------------------------------------------------

func test_randi_bounds() -> void:
	var rng: RefCounted = _make_rng(42)
	var seen: Dictionary = {}
	for i in range(10000):
		var val: int = rng.randi(10)
		if val < 0 or val >= 10:
			fail_test("randi(10) returned %d at iteration %d" % [val, i])
			return
		seen[val] = true
	assert_eq(seen.size(), 10, "randi(10) should produce all values 0-9 over 10,000 calls")

func test_randi_zero() -> void:
	var rng: RefCounted = _make_rng(42)
	assert_eq(rng.randi(0), 0, "randi(0) must return 0")

func test_randi_negative() -> void:
	var rng: RefCounted = _make_rng(42)
	assert_eq(rng.randi(-5), 0, "randi(-5) must return 0")

# ---------------------------------------------------------------------------
# Section F: randi_range()
# ---------------------------------------------------------------------------

func test_randi_range_bounds() -> void:
	var rng: RefCounted = _make_rng(42)
	var seen: Dictionary = {}
	for i in range(10000):
		var val: int = rng.randi_range(3, 7)
		if val < 3 or val > 7:
			fail_test("randi_range(3,7) returned %d at iteration %d" % [val, i])
			return
		seen[val] = true
	assert_eq(seen.size(), 5, "randi_range(3,7) should produce all values 3-7")

func test_randi_range_equal() -> void:
	var rng: RefCounted = _make_rng(42)
	for i in range(100):
		assert_eq(rng.randi_range(5, 5), 5, "randi_range(5,5) must always return 5")

func test_randi_range_swapped() -> void:
	var rng_a: RefCounted = _make_rng(42)
	var rng_b: RefCounted = _make_rng(42)
	for i in range(100):
		var val_a: int = rng_a.randi_range(3, 7)
		var val_b: int = rng_b.randi_range(7, 3)
		assert_eq(val_a, val_b, "randi_range must auto-swap min/max")

# ---------------------------------------------------------------------------
# Section G: shuffle()
# ---------------------------------------------------------------------------

func test_shuffle_in_place() -> void:
	var rng: RefCounted = _make_rng(42)
	var arr: Array = [1, 2, 3, 4, 5]
	var returned: Array = rng.shuffle(arr)
	assert_true(arr is Array, "shuffle must return an Array")
	# Verify same reference by checking mutation is reflected
	assert_eq(returned, arr, "shuffle must return the same array reference")

func test_shuffle_determinism() -> void:
	var a: RefCounted = _make_rng(42)
	var b: RefCounted = _make_rng(42)
	var arr_a: Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var arr_b: Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	a.shuffle(arr_a)
	b.shuffle(arr_b)
	assert_eq(arr_a, arr_b, "Same seed must produce same shuffle")

func test_shuffle_empty() -> void:
	var rng: RefCounted = _make_rng(42)
	var arr: Array = []
	var returned: Array = rng.shuffle(arr)
	assert_eq(returned.size(), 0, "Shuffling empty array should return empty array")

func test_shuffle_single() -> void:
	var rng: RefCounted = _make_rng(42)
	var arr: Array = [42]
	rng.shuffle(arr)
	assert_eq(arr, [42], "Shuffling single-element array should preserve it")

func test_shuffle_preserves_elements() -> void:
	var rng: RefCounted = _make_rng(42)
	var arr: Array = [1, 2, 3, 4, 5]
	rng.shuffle(arr)
	arr.sort()
	assert_eq(arr, [1, 2, 3, 4, 5], "Shuffle must not add or remove elements")

# ---------------------------------------------------------------------------
# Section H: pick()
# ---------------------------------------------------------------------------

func test_pick_determinism() -> void:
	var a: RefCounted = _make_rng(42)
	var b: RefCounted = _make_rng(42)
	var arr: Array = ["alpha", "beta", "gamma", "delta"]
	for i in range(100):
		assert_eq(a.pick(arr), b.pick(arr), "pick() must be deterministic at index %d" % i)

func test_pick_empty() -> void:
	var rng: RefCounted = _make_rng(42)
	assert_null(rng.pick([]), "pick([]) must return null")

func test_pick_single() -> void:
	var rng: RefCounted = _make_rng(42)
	assert_eq(rng.pick([99]), 99, "pick([99]) must return 99")

func test_pick_coverage() -> void:
	var seen: Dictionary = {}
	var items: Array = ["a", "b", "c"]
	for seed_val in range(1000):
		var rng: RefCounted = _make_rng(seed_val)
		var chosen: Variant = rng.pick(items)
		seen[chosen] = true
	assert_eq(seen.size(), 3, "pick() should eventually select every element")

# ---------------------------------------------------------------------------
# Section I: weighted_pick()
# ---------------------------------------------------------------------------

func test_weighted_pick_deterministic_weight() -> void:
	var rng: RefCounted = _make_rng(42)
	var items: Array = ["A", "B", "C"]
	var weights: Array[float] = [1.0, 0.0, 0.0]
	for i in range(1000):
		assert_eq(rng.weighted_pick(items, weights), "A",
			"Weight [1,0,0] must always select 'A'")

func test_weighted_pick_last_item() -> void:
	var rng: RefCounted = _make_rng(42)
	var items: Array = ["A", "B", "C"]
	var weights: Array[float] = [0.0, 0.0, 1.0]
	for i in range(1000):
		assert_eq(rng.weighted_pick(items, weights), "C",
			"Weight [0,0,1] must always select 'C'")

func test_weighted_pick_empty_items() -> void:
	var rng: RefCounted = _make_rng(42)
	assert_null(rng.weighted_pick([], []), "Empty items must return null")

func test_weighted_pick_empty_weights() -> void:
	var rng: RefCounted = _make_rng(42)
	assert_null(rng.weighted_pick(["A"], []), "Empty weights must return null")

func test_weighted_pick_all_zero_weights() -> void:
	var rng: RefCounted = _make_rng(42)
	assert_null(rng.weighted_pick(["A", "B"], [0.0, 0.0]),
		"All-zero weights must return null")

func test_weighted_pick_distribution() -> void:
	var rng: RefCounted = _make_rng(42)
	var items: Array = ["common", "rare"]
	var weights: Array[float] = [0.9, 0.1]
	var counts: Dictionary = {"common": 0, "rare": 0}
	for i in range(10000):
		var result: Variant = rng.weighted_pick(items, weights)
		counts[result] += 1
	# With 90/10 split over 10,000 trials, common should be ~9000 +/- 300
	assert_gt(counts["common"], 8000, "Common should appear >8000 times (got %d)" % counts["common"])
	assert_lt(counts["common"], 9800, "Common should appear <9800 times (got %d)" % counts["common"])
	assert_gt(counts["rare"], 200, "Rare should appear >200 times (got %d)" % counts["rare"])

func test_weighted_pick_determinism() -> void:
	var a: RefCounted = _make_rng(42)
	var b: RefCounted = _make_rng(42)
	var items: Array = ["X", "Y", "Z"]
	var weights: Array[float] = [0.5, 0.3, 0.2]
	for i in range(1000):
		assert_eq(
			a.weighted_pick(items, weights),
			b.weighted_pick(items, weights),
			"weighted_pick must be deterministic at index %d" % i)

func test_weighted_pick_negative_weights() -> void:
	var rng: RefCounted = _make_rng(42)
	var items: Array = ["A", "B", "C"]
	var weights: Array[float] = [-1.0, 0.0, 1.0]
	for i in range(100):
		assert_eq(rng.weighted_pick(items, weights), "C",
			"Negative weights should be ignored — only 'C' has positive weight")

func test_weighted_pick_size_mismatch() -> void:
	var rng: RefCounted = _make_rng(42)
	assert_null(rng.weighted_pick(["A", "B", "C"], [1.0, 2.0]),
		"Mismatched items/weights sizes must return null")
	assert_null(rng.weighted_pick(["A"], [1.0, 2.0, 3.0]),
		"Mismatched items/weights sizes must return null (items < weights)")

# ---------------------------------------------------------------------------
# Section J: Performance (optional, non-blocking)
# ---------------------------------------------------------------------------

func test_next_int_throughput() -> void:
	var rng: RefCounted = _make_rng(42)
	var start: int = Time.get_ticks_msec()
	for i in range(1000000):
		rng.next_int()
	var elapsed: int = Time.get_ticks_msec() - start
	# 1M calls should complete in under 2 seconds even on slow hardware
	assert_lt(elapsed, 2000,
		"1M next_int() calls took %d ms (target: <2000 ms)" % elapsed)
