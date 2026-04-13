import argparse
import json

MASK32 = 0xFFFFFFFF
MASK63 = 0x7FFFFFFFFFFFFFFF

def rotl32(x, k):
    return ((x << k) & MASK32) | ((x & MASK32) >> (32 - k))

class Xoshiro128:
    def __init__(self, seed):
        # derive 4x32 state words from a 64-bit seed using splitmix64
        def splitmix64(x):
            x = (x + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
            z = x
            z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 & 0xFFFFFFFFFFFFFFFF
            z = (z ^ (z >> 27)) * 0x94D049BB133111EB & 0xFFFFFFFFFFFFFFFF
            z = z ^ (z >> 31)
            return z
        x = seed & 0xFFFFFFFFFFFFFFFF
        if x == 0:
            x = 1
        self.s = []
        for i in range(4):
            z = splitmix64(x)
            x = (x + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
            self.s.append(z & MASK32)

    def next_u32(self):
        result = (rotl32((self.s[0] * 5) & MASK32, 7) * 9) & MASK32
        t = (self.s[1] << 9) & MASK32
        self.s[2] ^= self.s[0]
        self.s[3] ^= self.s[1]
        self.s[1] ^= self.s[2]
        self.s[0] ^= self.s[3]
        self.s[2] ^= t
        self.s[3] = rotl32(self.s[3], 11)
        return result

    def next_u64(self):
        hi = self.next_u32()
        lo = self.next_u32()
        combined = ((hi << 32) | lo) & MASK63
        return combined

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--seed', type=int, default=12345)
    p.add_argument('--count', type=int, default=10)
    p.add_argument('--out', type=str, default='tests/fixtures/rng/seed-0001.json')
    args = p.parse_args()
    rng = Xoshiro128(args.seed)
    vecs = [rng.next_u64() for _ in range(args.count)]
    with open(args.out, 'w') as f:
        json.dump({'seed': args.seed, 'vectors': vecs}, f, indent=2)
