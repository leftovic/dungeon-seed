# rng_wrapper_impl.gd
# Deterministic RNG wrapper (clean copy)

extends Node
class_name RNGWrapperImpl

const MASK32 = 0xFFFFFFFF
const MASK63 = 0x7FFFFFFFFFFFFFFF

var s := [0, 0, 0, 0]

func _rotl32(x: int, k: int) -> int:
	return ((x << k) | (x >> (32 - k))) & MASK32

func _seed_from_bytes(d: PackedByteArray) -> void:
	var vals := []
	# Expect at least 16 bytes; pad with zeros if needed
	var bytes = d
	while bytes.size() < 16:
		bytes.append(0)
	for i in range(4):
		var v: int = 0
		for j in range(4):
			v = (v << 8) | int(bytes[i * 4 + j])
		vals.append(v & MASK32)
	s = vals

func seed(seed_val: int) -> void:
	var hc: HashingContext = HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(str(seed_val).to_utf8_buffer())
	var d: PackedByteArray = hc.finish()
	_seed_from_bytes(d)
	for i in range(4):
		if s[i] == 0:
			s[i] = 0x9E3779B7 & MASK32

func seed_from_string(inp: String) -> void:
	var hc: HashingContext = HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(inp.to_utf8_buffer())
	var d: PackedByteArray = hc.finish()
	_seed_from_bytes(d)
	for i in range(4):
		if s[i] == 0:
			s[i] = 0x9E3779B7 & MASK32

func next_u32() -> int:
	# xoshiro128** core
	var result = (_rotl32((s[0] * 5) & MASK32, 7) * 9) & MASK32
	var t = (s[1] << 9) & MASK32
	s[2] = s[2] ^ s[0]
	s[3] = s[3] ^ s[1]
	s[1] = s[1] ^ s[2]
	s[0] = s[0] ^ s[3]
	s[2] = s[2] ^ t
	s[3] = _rotl32(s[3], 11)
	return result

func next_u64() -> int:
	# Combine two 32-bit outputs to produce a 64-bit value
	var hi: int = next_u32()
	var lo: int = next_u32()
	var combined: int = ((hi << 32) | lo) & MASK63
	return combined

func randf() -> float:
	var u: int = next_u64()
	var frac_mask: int = (1 << 53) - 1
	var v: int = u & frac_mask
	return float(v) / float(frac_mask)

func randi(max_val: int) -> int:
	if max_val <= 0:
		return 0
	return int(next_u64() % max_val)

