# deterministic_id_impl.gd
# Deterministic ID generator (alternate implementation file)

extends Node
class_name DeterministicIdImpl

func generate(player_id: String, epoch_ms: int, counter: int, namespace: String = "") -> String:
	var input_str := "%d-%s-%d-%s" % [epoch_ms, player_id, counter, namespace]
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(input_str.to_utf8())
	var d := hc.finish()
	var hex_str := ""
	for b in d:
		hex_str += "%02x" % b
	var player_hash := hex_str.substr(0,6)
	var sig := hex_str.substr(0,12)
	var counter_str := "%08d" % counter
	return "%d-%s-%s-%s" % [epoch_ms, player_hash, counter_str, sig]
