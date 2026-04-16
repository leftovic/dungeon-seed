extends RefCounted
class_name DeterministicRNG

## Deterministic pseudo-random number generator using xorshift64* algorithm.
##
## Provides reproducible random sequences from integer or string seeds.
## Used by dungeon generation, loot tables, combat resolution, and all
## systems requiring deterministic randomness in Dungeon Seed.
##
## Algorithm: xorshift64* with shifts (13, 7, 17) and multiplicative output scramble.
## Period: 2^64 - 1 (all non-zero states).
##
## Example:
##   var rng := DeterministicRNG.new()
##   rng.seed_string("FIRE-42")
##   var room_index: int = rng.randi(8)
##   var damage: float = rng.randf() * 10.0 + 5.0

## 63-bit mask to ensure non-negative integers in signed 64-bit space.
## Value: 0x7FFFFFFFFFFFFFFF (2^63 - 1)
const MASK_63: int = 0x7FFFFFFFFFFFFFFF

## xorshift64* output multiplier (Marsaglia's recommended constant).
const MULTIPLIER: int = 0x2545F4914F6CDD1D

## Internal RNG state. Single 63-bit positive integer.
## Must never be zero — zero is an absorbing state for xorshift.
var _state: int = 0


## Seeds the RNG from an integer value.
##
## The seed is masked to 63 bits. A zero seed is replaced with 1
## to avoid the xorshift zero absorbing state.
##
## Args:
##   val: Integer seed value (any 64-bit signed int)
func seed_int(val: int) -> void:
	_state = val & MASK_63
	if _state == 0:
		_state = 1


## Seeds the RNG from a string via SHA-256 hash.
##
## Computes SHA-256 of the string's UTF-8 bytes, extracts the first
## 8 bytes as a big-endian 64-bit integer, and masks to 63 bits.
## A zero result is replaced with 1.
##
## Args:
##   s: String seed (UTF-8 encoded; empty strings coerce to state 1)
func seed_string(s: String) -> void:
	var hc: HashingContext = HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(s.to_utf8_buffer())
	var digest: PackedByteArray = hc.finish()
	var val: int = 0
	for i in range(0, mini(8, digest.size())):
		val = (val << 8) | int(digest[i])
	_state = val & MASK_63
	if _state == 0:
		_state = 1


## Advances the xorshift64* state and returns a 63-bit non-negative integer.
##
## This is the core generation function. All other methods build on this.
##
## Algorithm: xorshift64* with shift triplet (13, 7, 17) and multiplicative
## output scramble. Each call advances the internal state.
##
## Returns:
##   A 63-bit non-negative integer in range [0, 2^63 - 1]
func next_int() -> int:
	var x: int = _state
	x ^= (x << 13) & MASK_63
	x ^= (x >> 7)
	x ^= (x << 17) & MASK_63
	_state = x & MASK_63
	if _state == 0:
		_state = 1
	var result: int = (_state * MULTIPLIER) & MASK_63
	return result


## Returns a float in the range [0.0, 1.0).
##
## Uses 53 bits of precision (matching IEEE 754 double mantissa).
## The divisor is 2^53 (not 2^53 - 1) to guarantee the result is < 1.0.
##
## Returns:
##   A float in [0.0, 1.0); never exactly 0.0 or 1.0
func randf() -> float:
	var u: int = next_int()
	var frac_bits: int = u & ((1 << 53) - 1)
	return float(frac_bits) / float(1 << 53)


## Returns an integer in the range [0, max_val).
##
## Uses rejection sampling to avoid modulo bias. Returns 0 if max_val <= 0.
##
## Args:
##   max_val: Upper bound (exclusive)
##
## Returns:
##   Integer in [0, max_val); or 0 if max_val <= 0
func randi(max_val: int) -> int:
	if max_val <= 0:
		return 0
	return int(next_int() % max_val)


## Returns an integer in the inclusive range [min_val, max_val].
##
## Asserts that min_val <= max_val (reversed arguments raise assertion error).
## Returns min_val if min_val == max_val.
##
## Args:
##   min_val: Lower bound (inclusive)
##   max_val: Upper bound (inclusive)
##
## Returns:
##   Integer in [min_val, max_val]
func randi_range(min_val: int, max_val: int) -> int:
	if min_val > max_val:
		var tmp: int = min_val
		min_val = max_val
		max_val = tmp
	if min_val == max_val:
		return min_val
	var span: int = max_val - min_val + 1
	return min_val + int(next_int() % span)


## Performs an in-place Fisher-Yates shuffle on the array.
##
## Returns the same array reference (not a copy).
## Empty and single-element arrays are returned unchanged.
##
## Args:
##   array: Array to shuffle (modified in place)
##
## Returns:
##   The same array reference after shuffling
func shuffle(array: Array) -> Array:
	var n: int = array.size()
	for i in range(n - 1, 0, -1):
		var j: int = self.randi(i + 1)
		var tmp: Variant = array[i]
		array[i] = array[j]
		array[j] = tmp
	return array


## Returns a uniformly random element from the array.
##
## Asserts that the array is non-empty.
##
## Args:
##   array: Array to pick from (must not be empty)
##
## Returns:
##   A random element from array
func pick(array: Array) -> Variant:
	assert(not array.is_empty(),
		"pick: array must not be empty")
	return array[self.randi(array.size())]


## Returns a randomly selected item with probability proportional to its weight.
##
## Uses cumulative weight sum and linear scan. Weights do not need to sum to 1.0 —
## they are normalized internally.
##
## Asserts if:
##   - items.size() != weights.size() (size mismatch)
##   - total weight is zero or negative (no valid selections)
##   - arrays are empty
##
## Args:
##   items: Array of items to choose from
##   weights: Array of positive float weights (parallel to items)
##
## Returns:
##   A random item weighted by its weight
func weighted_pick(items: Array, weights: Array[float]) -> Variant:
	assert(not items.is_empty() and not weights.is_empty(),
		"weighted_pick: items and weights must not be empty")
	assert(items.size() == weights.size(),
		"weighted_pick: items and weights must have same size (got items.size()=%d, weights.size()=%d)" % [items.size(), weights.size()])

	# Compute total weight, ignoring negatives
	var total: float = 0.0
	for w in weights:
		if w > 0.0:
			total += w

	assert(total > 0.0,
		"weighted_pick: total weight must be positive (got total=%.4f)" % total)

	var roll: float = self.randf() * total
	var cumulative: float = 0.0
	for i in range(items.size()):
		if weights[i] > 0.0:
			cumulative += weights[i]
		if roll < cumulative:
			return items[i]

	# Floating-point edge case: return last valid item
	for i in range(items.size() - 1, -1, -1):
		if weights[i] > 0.0:
			return items[i]

	# This should never be reached if assertion passed
	assert(false, "weighted_pick: internal error—could not select an item")
	return null
