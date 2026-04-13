import argparse
import json

class Xorshift64:
    def __init__(self, seed):
        self.x = seed & 0xffffffffffffffff
        if self.x == 0:
            self.x = 1
    def next_u64(self):
        x = self.x
        x ^= (x << 13) & 0xffffffffffffffff
        x ^= (x >> 7) & 0xffffffffffffffff
        x ^= (x << 17) & 0xffffffffffffffff
        self.x = x & 0xffffffffffffffff
        return self.x

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--seed', type=int, default=12345)
    p.add_argument('--count', type=int, default=10)
    p.add_argument('--out', type=str, default='tests/fixtures/rng/seed-0001.json')
    args = p.parse_args()
    rng = Xorshift64(args.seed)
    vecs = [rng.next_u64() for _ in range(args.count)]
    with open(args.out, 'w') as f:
        json.dump({'seed': args.seed, 'vectors': vecs}, f, indent=2)
