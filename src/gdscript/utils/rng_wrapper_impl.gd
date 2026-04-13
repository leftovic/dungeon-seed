# rng_wrapper_impl.gd
# Deterministic RNG wrapper (clean copy)

extends Node
class_name RNGWrapperImpl

var _state: int = 0

func seed(seed_val: int) -> void:
	_state = seed_val & 0xFFFFFFFFFFFFFFFF
	if _state == 0:
		_state = 0xDEADBEEFCAFEBABE

func seed_from_string(s: String) -> void:
	var hc: HashingContext = HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(s.to_utf8())
	var d: PackedByteArray = hc.finish()
	var val: int = 0
	for i in range(0, min(8, d.size())):
		val = (val << 8) | int(d[i])
	_state = val & 0xFFFFFFFFFFFFFFFF
	if _state == 0:
		_state = 0xFEEDFACECAFEBABE

func next_u64() -> int:
	var x: int = _state
	x ^= (x << 13) & 0xFFFFFFFFFFFFFFFF
	x ^= (x >> 7)
	x ^= (x << 17) & 0xFFFFFFFFFFFFFFFF
	_state = x & 0xFFFFFFFFFFFFFFFF
	var res: int = (_state * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF
	return res

func randf() -> float:
	var u: int = next_u64()
	var frac_mask: int = (1 << 53) - 1
	var v: int = u & frac_mask
	return float(v) / float(frac_mask)

func randi(max_val: int) -> int:
	if max_val <= 0:
		return 0
	return int(next_u64() % max_val)
