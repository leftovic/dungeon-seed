extends Node

class_name DeterministicIDClean

static func canonicalize(name: String) -> String:
	var s = name.strip_edges().to_lower()
	# collapse internal whitespace
	s = s.replace("\n", " ").replace("\r", " ")
	s = s.strip_edges()
	return s

static func id_for(namespace: String, name: String) -> String:
	var n = canonicalize(namespace)
	var m = canonicalize(name)
	var input = "%s:%s".format(n, m)
	# Use SHA256 for deterministic, human-opaque id
	var hash = Crypto.digest(Crypto.HASH_SHA256, input.to_utf8())
	return "ds-" + hash.hex_encode()

# For production: replace with HMAC-SHA256 using a key from KMS/CI secrets (do not commit keys)
