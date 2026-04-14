# TASK-008: Economy — 4-Currency Wallet & Transaction Ledger

---

## Section 1 — Header

| Field              | Value                                                                                    |
| ------------------ | ---------------------------------------------------------------------------------------- |
| **Task ID**        | TASK-008                                                                                 |
| **Title**          | Economy — 4-Currency Wallet & Transaction Ledger                                         |
| **Priority**       | 🟡 P1 — High (Unlocks Reward Pipeline)                                                  |
| **Tier**           | Tier 2 — Core Data Models                                                                |
| **Complexity**     | 5 points (Moderate)                                                                      |
| **Phase**          | Wave 2 — Data Models                                                                     |
| **Stream**         | 🔴 MCH (Mechanics) — Primary                                                            |
| **Cross-Stream**   | 🔵 VIS (currency display UI), ⚪ TCH (serialization, transaction logging)               |
| **GDD Reference**  | GDD-v2.md §4.4 (Loot & Economy)                                                         |
| **Milestone**      | M1 — Core Data Models                                                                    |
| **Dependencies**   | TASK-003 (Enums, Constants & Data Dictionary) — provides `Enums.Currency`, `GameConfig.CURRENCY_EARN_RATES` |
| **Dependents**     | TASK-016 (Expedition Reward Processor), TASK-017 (Core Loop Integration)                 |
| **Critical Path**  | ❌ No — but required before TASK-016 can begin reward distribution                       |
| **Estimated Hours**| 4–6 hours                                                                                |
| **Assignee**       | TBD                                                                                      |
| **Engine**         | Godot 4.6 — GDScript                                                                     |
| **Output Files**   | `src/models/wallet.gd`, `src/models/transaction_log.gd`, `tests/models/test_wallet.gd`, `tests/models/test_transaction_log.gd` |

---

## Section 2 — Description

### 2.1 — What This Task Produces

This task creates two pure-data RefCounted classes that form the financial backbone of Dungeon Seed's entire economy:

1. **`src/models/wallet.gd`** (`class_name Wallet`, `extends RefCounted`) — A four-currency wallet that holds the player's Gold, Essence, Fragments, and Artifacts balances. It provides type-safe credit, debit, multi-currency affordability checks, and atomic multi-currency transactions. Every balance mutation emits signals through the EventBus so UI and analytics systems can react in real time without polling.

2. **`src/models/transaction_log.gd`** (`class_name TransactionLog`, `extends RefCounted`) — A fixed-capacity circular buffer that records the last N financial transactions for debug inspection, UI history display, and economy analytics. Each entry captures a timestamp, transaction type string, currency enum value, signed amount, and resulting balance. The log provides O(1) append and O(n) retrieval for the most recent entries.

Together these two classes enforce the fundamental economic invariant: **no currency can go negative, no transaction can partially execute, and every balance change is recorded**. This is the double-entry bookkeeping of Dungeon Seed — the system that prevents the economy from silently corrupting itself.

### 2.2 — Why a Dedicated Wallet Model Matters

Without a centralized wallet abstraction, currency handling scatters across the codebase and produces the following failure modes:

- **Negative balance corruption**: A reward system credits 50 Gold, then a shop deducts 80 Gold. Without an atomic check-then-debit, the player ends up with −30 Gold. UI displays a nonsensical number, save files contain invalid state, and downstream systems that assume non-negative balances crash or produce undefined behavior.

- **Partial transaction inconsistency**: A crafting recipe costs 100 Gold + 5 Fragments. The system deducts Gold successfully, then discovers the player lacks Fragments. Now the player has lost Gold but received nothing. Rolling back requires manual compensation logic scattered across every purchase site. With an atomic `transact()` method, the entire operation succeeds or fails as a unit — no partial state.

- **Silent balance drift**: Without a transaction log, a balance goes from 500 to 200 between saves and nobody knows why. Was it a shop purchase? A crafting cost? A bug that double-charged? The transaction log provides forensic traceability for every balance change.

- **Signal coupling chaos**: If each system directly modifies a raw integer balance, there is no single point to emit a "balance changed" signal. UI elements poll on every frame, or miss updates entirely. A centralized wallet emits signals on every mutation, giving UI a clean reactive binding.

- **Serialization fragmentation**: Four separate integer variables scattered across different scripts must all be saved and loaded in sync. If one is missed, the save file is corrupt. A single `Wallet.to_dict()` / `Wallet.from_dict()` serializes the entire financial state atomically.

### 2.3 — Player Experience Impact

Players experience the wallet through every economic interaction in the game:

- **Earning currency after a dungeon run**: When an expedition completes (TASK-016), the Reward Processor calls `wallet.credit(Enums.Currency.GOLD, earned_gold)`. The wallet updates, emits a signal, and the HUD's gold counter animates from the old value to the new value. The player sees "Gold: 500 → 650" with a satisfying tick-up animation. If the wallet is buggy, the counter jumps, shows wrong values, or doesn't update at all.

- **Purchasing a seed upgrade**: The player opens the shop and sees "Upgrade: 200 Gold + 10 Essence". The shop calls `wallet.can_afford({Enums.Currency.GOLD: 200, Enums.Currency.ESSENCE: 10})`. If the player has enough, the purchase button is enabled. If not, it's greyed out with the deficient currency highlighted in red. On purchase, `wallet.transact()` atomically deducts both currencies and the upgrade is applied. If the wallet doesn't support multi-currency affordability checks, every shop item needs custom validation logic.

- **Viewing transaction history**: The player opens an economy panel and sees "Last 10 transactions: +50 Gold (room clear), −200 Gold (seed upgrade), +5 Essence (boss drop), ..." This history comes from `TransactionLog.get_recent(10)`. Without the log, this feature requires a separate tracking system bolted on after the fact.

- **Returning from idle**: The player closes the game and returns 4 hours later. Idle accumulation logic (future task) calls `wallet.credit()` for accumulated resources. The wallet handles the credit identically whether it comes from active play or idle accumulation — the abstraction doesn't care about the source.

- **Boss drops a rare Artifact**: A boss kill awards an Artifact (the rarest currency with earn rate 0 from normal rooms). `wallet.credit(Enums.Currency.ARTIFACTS, 1)` fires, the signal triggers a special celebration VFX, and the transaction log records "boss_drop: +1 Artifact". The player feels the weight of the reward because the system treats it with the same rigor as routine Gold.

### 2.4 — Economy Design: Faucets, Sinks, and the Wallet's Role

The GDD (§4.4) establishes a four-currency economy with distinct faucet/sink profiles:

| Currency   | Base Earn Rate | Primary Faucets                      | Primary Sinks                         | Design Intent                    |
| ---------- | -------------- | ------------------------------------ | ------------------------------------- | -------------------------------- |
| Gold       | 10 per room    | Room clears, idle accumulation       | Seed upgrades, shop purchases, hiring | Abundant soft currency           |
| Essence    | 2 per room     | Room clears, seed mutations          | Seed boosts, trait alterations        | Medium-scarcity growth currency  |
| Fragments  | 1 per room     | Room clears, salvaging equipment     | Crafting gear, equipment upgrades     | Scarce crafting material         |
| Artifacts  | 0 per room     | Boss kills, special events only      | Rare permanent bonuses                | Ultra-scarce premium drops       |

The `Wallet` class is the **single point of truth** for all four balances. Every faucet (room clears, boss drops, idle rewards, event grants) flows through `wallet.credit()`. Every sink (shop purchases, upgrades, crafting costs) flows through `wallet.debit()` or `wallet.transact()`. This architectural constraint means:

- **Economy analytics are trivially derivable**: Total Gold earned = sum of all `credit` entries in the transaction log for Gold. Total Gold spent = sum of all `debit` entries. Net flow = difference. No separate tracking system needed.
- **Balance validation is centralized**: The invariant "balance ≥ 0 for all currencies" is enforced in exactly one place. No downstream system can violate it.
- **Rate limiting and anti-exploit logic has a single attachment point**: If a future anti-cheat system needs to cap credits per minute, it wraps `wallet.credit()` — one function, not dozens of call sites.

### 2.5 — Technical Architecture

```
┌────────────────────────────────────────────────────────┐
│                     Wallet                             │
│                extends RefCounted                      │
│                class_name Wallet                       │
├────────────────────────────────────────────────────────┤
│  - _balances: Dictionary  {Currency: int}              │
│  - _log: TransactionLog                                │
├────────────────────────────────────────────────────────┤
│  + get_balance(currency: Enums.Currency) -> int        │
│  + can_afford(costs: Dictionary) -> bool               │
│  + credit(currency: Enums.Currency, amount: int) -> void│
│  + debit(currency: Enums.Currency, amount: int) -> bool│
│  + transact(costs: Dictionary, gains: Dictionary) -> bool│
│  + get_transaction_log() -> TransactionLog             │
│  + to_dict() -> Dictionary                             │
│  + from_dict(data: Dictionary) -> void                 │
│  + reset() -> void                                     │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│                  TransactionLog                        │
│                extends RefCounted                      │
│                class_name TransactionLog               │
├────────────────────────────────────────────────────────┤
│  - _entries: Array[Dictionary]                         │
│  - _max_entries: int                                   │
│  - _write_index: int                                   │
├────────────────────────────────────────────────────────┤
│  + record(type: String, currency: Enums.Currency,      │
│           amount: int, balance: int) -> void            │
│  + get_recent(count: int) -> Array[Dictionary]         │
│  + get_all() -> Array[Dictionary]                      │
│  + get_count() -> int                                  │
│  + clear() -> void                                     │
│  + to_dict() -> Dictionary                             │
│  + from_dict(data: Dictionary) -> void                 │
└────────────────────────────────────────────────────────┘
```

### 2.6 — System Interaction Map

```
         ┌──────────────────────────────────────┐
         │      TASK-003 (Enums + GameConfig)    │
         │  Enums.Currency  CURRENCY_EARN_RATES  │
         └────────────────┬─────────────────────┘
                          │ type + config dependency
                          ▼
         ┌──────────────────────────────────────┐
         │       TASK-008 (This Task)            │
         │   wallet.gd + transaction_log.gd      │
         └─┬──────────────┬──────────────────┬──┘
           │              │                  │
           ▼              ▼                  ▼
    TASK-016          TASK-017          Future UI
    Reward            Core Loop         Currency
    Processor         Integration       Display
    (credits          (transact for     (reacts to
     loot)            shop/upgrades)    signals)
```

### 2.7 — Signal Architecture

The `Wallet` class does **not** declare signals itself (it extends RefCounted, not Node). Instead, it calls static methods on the project's `EventBus` autoload (which will be established in a future infrastructure task). For TASK-008, the wallet calls `EventBus` signals if EventBus is available, with a safe guard pattern:

```
Wallet.credit() called
  → _balances[currency] += amount
  → _log.record("credit", currency, amount, new_balance)
  → EventBus.currency_changed.emit(currency, new_balance)  # if EventBus exists
  → EventBus.currency_gained.emit(currency, amount)         # if EventBus exists
```

Until EventBus is implemented, the wallet provides a local `changed` callback via a `Callable` property that downstream tests and systems can hook into. This decouples the wallet from the scene tree entirely.

### 2.8 — Transaction Atomicity

The `transact()` method is the most architecturally important method in the wallet. It handles multi-currency exchanges where a player pays multiple currencies and receives multiple currencies in a single operation. The atomicity guarantee is:

1. **Validate phase**: Check that every cost currency has sufficient balance. If any single currency is insufficient, return `false` immediately — no balances are modified.
2. **Debit phase**: Deduct all cost currencies. Since validation passed, all debits are guaranteed to succeed.
3. **Credit phase**: Add all gain currencies.
4. **Log phase**: Record one transaction entry per currency modified.

This all-or-nothing pattern prevents the "paid Gold but didn't get Essence" bug that plagues ad-hoc economy implementations.

### 2.9 — Transaction Log Design: Circular Buffer

The `TransactionLog` uses a circular buffer (ring buffer) pattern to bound memory usage:

- **Fixed capacity**: Default 100 entries. Configurable via constructor parameter.
- **O(1) append**: New entries overwrite the oldest when the buffer is full. No array resizing, no shifting.
- **O(n) retrieval**: `get_recent(count)` returns the most recent `count` entries in chronological order by reading backwards from the write pointer.
- **Serialization**: `to_dict()` exports only the populated entries (not the full buffer capacity) to minimize save file size.

Why a circular buffer instead of an unbounded array? Because the transaction log is per-session diagnostic data, not a permanent audit trail. A player who has completed 10,000 room clears does not need all 10,000 credit entries in memory. The most recent 100 provide sufficient debugging context and UI history.

### 2.10 — Development Cost

| Activity                                  | Estimated Time |
| ----------------------------------------- | -------------- |
| Implement `transaction_log.gd`            | 45 min         |
| Implement `wallet.gd`                     | 90 min         |
| Write GUT tests for `TransactionLog`      | 45 min         |
| Write GUT tests for `Wallet`              | 90 min         |
| Integration test: wallet + log together   | 30 min         |
| Code review & iteration                   | 30 min         |
| **Total**                                 | **~5.5 hours** |

### 2.11 — Constraints and Design Decisions

1. **RefCounted, not Node**: Both classes extend `RefCounted`. They have zero scene-tree coupling, zero `_process()` calls, zero signal declarations on themselves. They are pure data objects that can be instantiated in tests without a SceneTree.
2. **Dictionary keys are `Enums.Currency` integer values**: `_balances` is keyed by enum integers (`Enums.Currency.GOLD`, not `"GOLD"`). This provides type safety and O(1) hash lookup.
3. **Integer-only balances**: All currency amounts are `int`, not `float`. Floating-point arithmetic introduces rounding errors that accumulate over thousands of transactions. A player should never see "Gold: 99.99999" due to IEEE 754 drift. Integers are exact.
4. **No negative balances — ever**: `debit()` returns `false` if insufficient funds. `transact()` pre-validates all costs. There is no code path through which a balance can become negative.
5. **Immutable transaction entries**: Once recorded, a transaction log entry is never modified. The log is append-only. This makes it safe for UI iteration — no concurrent modification issues.
6. **EventBus coupling is guarded**: The wallet checks `Engine.has_singleton()` or uses `ClassDB.class_exists()` to detect EventBus availability. If EventBus is not registered, signal emission is silently skipped. This allows the wallet to function in unit tests without autoload infrastructure.
7. **`from_dict()` validates input**: Deserialized data is validated — unknown currency keys are ignored, non-integer values are rejected, and negative balances are clamped to zero. The wallet never trusts external data.

---

## Section 3 — Use Cases

### UC-001: Player Earns Gold From Room Clear

**Actor:** Player (via Expedition Reward Processor — TASK-016)
**Trigger:** Player's adventurer party clears a Combat room in a dungeon expedition.
**Precondition:** Wallet exists with current balance of Gold: 500.
**Flow:**
1. The Expedition Reward Processor calculates the Gold reward: `base_rate * difficulty_scale * seed_bonus = 10 * 1.5 * 1.2 = 18 Gold`.
2. Processor calls `wallet.credit(Enums.Currency.GOLD, 18)`.
3. Wallet adds 18 to the Gold balance: 500 + 18 = 518.
4. Wallet records a transaction log entry: `{ timestamp: 1234.56, type: "room_clear", currency: Enums.Currency.GOLD, amount: 18, balance_after: 518 }`.
5. Wallet emits `EventBus.currency_changed.emit(Enums.Currency.GOLD, 518)`.
6. Wallet emits `EventBus.currency_gained.emit(Enums.Currency.GOLD, 18)`.
7. The HUD's gold counter animates from 500 to 518.

**Postcondition:** Gold balance is 518. Transaction log contains the credit entry. UI reflects the new balance.

### UC-002: Player Purchases a Multi-Currency Upgrade

**Actor:** Player (via Shop/Upgrade UI — future task)
**Trigger:** Player clicks "Buy" on a seed mutation that costs 200 Gold + 15 Essence.
**Precondition:** Wallet balances: Gold: 518, Essence: 30, Fragments: 12, Artifacts: 1.
**Flow:**
1. Shop UI calls `wallet.can_afford({Enums.Currency.GOLD: 200, Enums.Currency.ESSENCE: 15})` → returns `true`.
2. Purchase button is enabled. Player clicks it.
3. Shop calls `wallet.transact({Enums.Currency.GOLD: 200, Enums.Currency.ESSENCE: 15}, {})`.
4. Wallet validates: Gold 518 ≥ 200 ✅, Essence 30 ≥ 15 ✅.
5. Wallet debits Gold: 518 − 200 = 318.
6. Wallet debits Essence: 30 − 15 = 15.
7. Wallet records two transaction log entries (one per currency debited).
8. Wallet emits `currency_changed` for both Gold and Essence.
9. Wallet returns `true`.
10. Shop applies the mutation to the seed.

**Postcondition:** Gold: 318, Essence: 15. Two transaction log entries recorded. Mutation applied.

### UC-003: Player Attempts Purchase With Insufficient Funds

**Actor:** Player (via Shop UI)
**Trigger:** Player tries to buy equipment costing 500 Gold + 20 Fragments.
**Precondition:** Wallet balances: Gold: 318, Essence: 15, Fragments: 12, Artifacts: 1.
**Flow:**
1. Shop UI calls `wallet.can_afford({Enums.Currency.GOLD: 500, Enums.Currency.FRAGMENTS: 20})` → returns `false`.
2. Purchase button is greyed out. Deficient currencies (Gold and Fragments) are highlighted in red.
3. If the player somehow bypasses the UI and calls `wallet.transact({Enums.Currency.GOLD: 500, Enums.Currency.FRAGMENTS: 20}, {})` directly:
4. Wallet validates: Gold 318 < 500 ❌ — validation fails immediately.
5. No balances are modified. No transaction log entries are created.
6. Wallet returns `false`.

**Postcondition:** All balances unchanged. No side effects. Player sees "insufficient funds" feedback.

### UC-004: Boss Drops a Rare Artifact

**Actor:** Player (via Boss Kill Reward — TASK-016)
**Trigger:** Player defeats a dungeon boss.
**Precondition:** Wallet balances: Gold: 318, Essence: 15, Fragments: 12, Artifacts: 1.
**Flow:**
1. Boss kill reward processor calculates loot: 100 Gold + 1 Artifact.
2. Processor calls `wallet.credit(Enums.Currency.GOLD, 100)`.
3. Wallet updates Gold: 318 + 100 = 418. Logs and emits.
4. Processor calls `wallet.credit(Enums.Currency.ARTIFACTS, 1)`.
5. Wallet updates Artifacts: 1 + 1 = 2. Logs and emits.
6. UI triggers special VFX for Artifact gain (reacts to `currency_gained` signal where currency is ARTIFACTS).

**Postcondition:** Gold: 418, Artifacts: 2. Two transaction log entries. Special UI celebration for Artifact.

### UC-005: Game Saves and Loads Wallet State

**Actor:** Save/Load system (TASK-009 or future)
**Trigger:** Player exits the game. Later, player relaunches.
**Flow:**
1. Save system calls `wallet.to_dict()`.
2. Wallet returns `{ "balances": { "0": 418, "1": 15, "2": 12, "3": 2 }, "log": { ... } }`.
3. System writes dictionary to save file as JSON.
4. On load, system reads JSON and calls `wallet.from_dict(data)`.
5. Wallet validates all keys are valid `Currency` enum integers.
6. Wallet validates all values are non-negative integers.
7. Wallet restores balances: Gold: 418, Essence: 15, Fragments: 12, Artifacts: 2.
8. Transaction log restores recent entries.

**Postcondition:** Wallet state is identical to pre-save state. Invalid data in save file is handled gracefully.

### UC-006: Developer Inspects Transaction History for Debugging

**Actor:** Developer (via debug console or in-game debug panel)
**Trigger:** QA reports "player lost 200 Gold and doesn't know why."
**Flow:**
1. Developer opens debug console and calls `wallet.get_transaction_log().get_recent(20)`.
2. Receives an array of the last 20 transactions, each with timestamp, type, currency, amount, and balance_after.
3. Developer scans the list: sees a `"shop_purchase"` entry for −200 Gold at timestamp 1534.7.
4. Cross-references with game event logs to confirm the player clicked "Buy" at that timestamp.
5. Bug resolved — the deduction was legitimate, player forgot they bought something.

**Postcondition:** Developer has full forensic visibility into balance changes without adding extra logging infrastructure.

---

## Section 4 — Glossary

| Term                          | Definition                                                                                                                                                          |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Wallet**                    | A pure-data RefCounted object that holds the player's currency balances and provides type-safe credit/debit/transact operations. Single source of truth for all four currency amounts. |
| **TransactionLog**            | A fixed-capacity circular buffer that records sequential transaction entries for debugging, UI display, and economy analytics. Append-only, bounded memory.          |
| **Currency**                  | One of four resource types in Dungeon Seed: Gold, Essence, Fragments, Artifacts. Defined in `Enums.Currency`. Each has distinct earn rates and spending sinks.       |
| **Gold**                      | Primary soft currency. Earned at 10 per room. Spent on seed upgrades, shop purchases, adventurer hiring. Abundant by design.                                         |
| **Essence**                   | Secondary growth currency. Earned at 2 per room. Spent on seed boosts and trait alterations. Medium scarcity.                                                        |
| **Fragments**                 | Crafting material currency. Earned at 1 per room. Spent on gear crafting and equipment upgrades. Scarce.                                                             |
| **Artifacts**                 | Ultra-rare premium currency. Earned at 0 per room (boss-only or event drops). Spent on rare permanent bonuses. Extremely scarce.                                     |
| **credit**                    | The operation of adding currency to a wallet balance. Always succeeds (amounts must be positive). Emits signals for UI reactivity.                                   |
| **debit**                     | The operation of subtracting currency from a wallet balance. Fails (returns false) if the balance would go negative. Never creates negative balances.                 |
| **transact**                  | An atomic multi-currency operation that debits costs and credits gains in a single all-or-nothing call. If any cost cannot be afforded, the entire transaction fails. |
| **atomic transaction**        | A transaction that either fully succeeds (all debits and credits applied) or fully fails (no state changes). No partial execution is possible.                       |
| **faucet**                    | An economy source that generates currency. Room clears, boss drops, idle rewards, and event grants are faucets. All faucets flow through `wallet.credit()`.          |
| **sink**                      | An economy drain that consumes currency. Shop purchases, upgrades, crafting costs, and hiring fees are sinks. All sinks flow through `wallet.debit()` or `transact()`.|
| **circular buffer**           | A fixed-size array where new entries overwrite the oldest when full. Used by TransactionLog to bound memory. Also called a ring buffer.                              |
| **balance invariant**         | The rule that no currency balance may ever be negative. Enforced by `debit()` and `transact()`. Validated by `from_dict()` on deserialization.                       |
| **transaction entry**         | A single record in the TransactionLog: `{ timestamp: float, type: String, currency: Enums.Currency, amount: int, balance_after: int }`.                             |
| **EventBus**                  | A global singleton autoload (future task) that provides named signals for cross-system communication. Wallet emits `currency_changed` and `currency_gained` through it.|
| **serialization round-trip**  | The process of converting an object to a Dictionary (`to_dict()`), then reconstructing it (`from_dict()`), and verifying the result is identical to the original.     |
| **RefCounted**                | Godot's default base class. Reference-counted, garbage-collected. No scene tree dependency. Wallet and TransactionLog both extend RefCounted.                        |
| **CURRENCY_EARN_RATES**       | A `const Dictionary` in `GameConfig` (TASK-003) mapping each `Enums.Currency` to its base earn rate per room clear. Gold=10, Essence=2, Fragments=1, Artifacts=0.   |
| **idempotent**                | An operation that produces the same result regardless of how many times it is applied. `from_dict()` is idempotent — calling it twice with the same data yields identical state. |
| **write pointer**             | The index in the circular buffer where the next entry will be written. Advances by 1 on each `record()` call and wraps around to 0 at capacity.                     |
| **GUT**                       | Godot Unit Testing framework. The standard test runner for Dungeon Seed. Test files extend `GutTest` and use `assert_eq`, `assert_true`, `assert_false`.            |

---

## Section 5 — Out of Scope

The following items are explicitly **NOT** part of TASK-008. They may be addressed in downstream tasks or are intentionally excluded from the current architecture.

| #  | Excluded Item                                          | Reason                                                                                                                   |
| -- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| 1  | Currency earning logic (room clear rewards)            | Belongs to TASK-016 (Expedition Reward Processor). Wallet only stores/mutates balances — it does not know where currency comes from. |
| 2  | Shop UI or purchase flow                               | Future UI task. The wallet provides `can_afford()` and `transact()` as primitives — it does not render buttons or dialogs. |
| 3  | Idle accumulation / offline rewards                    | Future core-loop task. Wallet credits are agnostic to whether the game was active or idle.                                |
| 4  | Currency display formatting ("1,200 Gold")             | UI responsibility. Wallet returns raw integers. Formatting with commas, abbreviations (1.2K), or icons is a display concern. |
| 5  | Animated currency counter / HUD tick-up                | Visual task (🔵 VIS stream). Wallet emits the signal; the HUD subscribes and animates.                                   |
| 6  | EventBus implementation                                | Infrastructure task. Wallet will call EventBus signals if the autoload exists, but does not create EventBus itself.       |
| 7  | Real-money (IAP) currency or premium store             | Out of scope per GDD — no pay-to-win. Artifacts are earned in-game only.                                                 |
| 8  | Multi-wallet support (e.g., per-adventurer wallets)    | GDD specifies a single player-level wallet. Per-adventurer inventories are a different system.                            |
| 9  | Currency exchange / conversion between types           | Not in GDD §4.4. Gold cannot be converted to Essence. Each currency has its own faucet/sink cycle.                       |
| 10 | Anti-cheat runtime enforcement (server validation)     | Dungeon Seed is single-player offline. Anti-cheat is limited to save-file validation hardening, not server authority.     |
| 11 | Achievement triggers based on currency milestones      | Future feature. Wallet does not know about achievements. An achievement system would subscribe to wallet signals.          |
| 12 | Currency cap / maximum balance limits                  | Not specified in GDD. Balances are unbounded positive integers for now. If needed, caps would be added to GameConfig.     |
| 13 | Tax, fee, or percentage-based deductions               | Not in current GDD. All costs are flat integer amounts. Percentage-based systems would require float logic.               |
| 14 | Undo / refund mechanics                                | Transactions are final. A refund would be implemented as a new credit transaction, not a rollback.                        |

---

## Section 6 — Functional Requirements

### wallet.gd Requirements

| ID     | Requirement                                                                                                                                       | GDD Ref | Testable |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | -------- |
| FR-001 | `wallet.gd` declares `class_name Wallet` at the top of the file.                                                                                 | —       | ✅       |
| FR-002 | `wallet.gd` declares `extends RefCounted` explicitly.                                                                                             | —       | ✅       |
| FR-003 | `Wallet` initializes `_balances` as a Dictionary with all four `Enums.Currency` values mapped to `0` on construction.                             | §4.4    | ✅       |
| FR-004 | `Wallet` holds a reference to a `TransactionLog` instance, created internally during `_init()`.                                                   | —       | ✅       |
| FR-005 | `get_balance(currency: Enums.Currency) -> int` returns the current balance for the specified currency.                                             | §4.4    | ✅       |
| FR-006 | `get_balance()` returns `0` for any valid currency that has not been credited.                                                                     | —       | ✅       |
| FR-007 | `can_afford(costs: Dictionary) -> bool` returns `true` if and only if every key in `costs` is a valid `Enums.Currency` and the corresponding balance is ≥ the cost value. | §4.4    | ✅       |
| FR-008 | `can_afford()` returns `true` for an empty `costs` dictionary (zero-cost operations are always affordable).                                        | —       | ✅       |
| FR-009 | `can_afford()` does not modify any balances — it is a pure read-only query.                                                                       | —       | ✅       |
| FR-010 | `credit(currency: Enums.Currency, amount: int) -> void` increases the specified currency balance by `amount`.                                      | §4.4    | ✅       |
| FR-011 | `credit()` asserts that `amount > 0`. Passing `amount <= 0` triggers an assertion failure in debug builds.                                         | —       | ✅       |
| FR-012 | `credit()` records a transaction log entry with type `"credit"`, the currency, the amount, and the new balance.                                    | —       | ✅       |
| FR-013 | `credit()` emits `EventBus.currency_changed` with the currency and new balance if EventBus is available.                                           | —       | ✅       |
| FR-014 | `credit()` emits `EventBus.currency_gained` with the currency and credited amount if EventBus is available.                                        | —       | ✅       |
| FR-015 | `debit(currency: Enums.Currency, amount: int) -> bool` subtracts `amount` from the specified currency balance if sufficient funds exist.            | §4.4    | ✅       |
| FR-016 | `debit()` returns `true` on success (balance was sufficient), `false` on failure (insufficient funds).                                             | —       | ✅       |
| FR-017 | `debit()` does not modify any balance when it returns `false`.                                                                                     | —       | ✅       |
| FR-018 | `debit()` asserts that `amount > 0`. Passing `amount <= 0` triggers an assertion failure in debug builds.                                          | —       | ✅       |
| FR-019 | `debit()` records a transaction log entry with type `"debit"` only on success.                                                                     | —       | ✅       |
| FR-020 | `debit()` emits `EventBus.currency_changed` with the currency and new balance on success if EventBus is available.                                  | —       | ✅       |
| FR-021 | `transact(costs: Dictionary, gains: Dictionary) -> bool` performs an atomic multi-currency transaction.                                             | §4.4    | ✅       |
| FR-022 | `transact()` validates all costs before modifying any balance. If any single cost exceeds its currency's balance, no changes occur and `false` is returned. | —       | ✅       |
| FR-023 | `transact()` applies all debits first, then all credits, only after validation passes.                                                             | —       | ✅       |
| FR-024 | `transact()` records one transaction log entry per currency modified (debits as `"transact_debit"`, credits as `"transact_credit"`).                | —       | ✅       |
| FR-025 | `transact()` with empty `costs` and non-empty `gains` always succeeds (pure grant).                                                                | —       | ✅       |
| FR-026 | `transact()` with non-empty `costs` and empty `gains` behaves as a multi-currency debit.                                                           | —       | ✅       |
| FR-027 | `to_dict() -> Dictionary` serializes the wallet state (balances and transaction log) into a plain Dictionary suitable for JSON export.              | —       | ✅       |
| FR-028 | `from_dict(data: Dictionary) -> void` restores wallet state from a Dictionary. Unknown currency keys are ignored. Non-integer values are rejected.  | —       | ✅       |
| FR-029 | `from_dict()` clamps negative balance values to `0`. The wallet never enters an invalid state from external data.                                   | —       | ✅       |
| FR-030 | `from_dict()` followed by `to_dict()` produces a Dictionary equal to the original input (round-trip consistency), assuming the input was valid.      | —       | ✅       |
| FR-031 | `reset() -> void` sets all four currency balances back to `0` and clears the transaction log.                                                      | —       | ✅       |
| FR-032 | `get_transaction_log() -> TransactionLog` returns the wallet's internal TransactionLog instance.                                                    | —       | ✅       |
| FR-033 | No balance may ever be negative after any public method call. This is the core invariant.                                                          | §4.4    | ✅       |
| FR-034 | `get_all_balances() -> Dictionary` returns a copy of the `_balances` dictionary (not a reference to the internal mutable state).                    | —       | ✅       |

### transaction_log.gd Requirements

| ID     | Requirement                                                                                                                                       | GDD Ref | Testable |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | -------- |
| FR-035 | `transaction_log.gd` declares `class_name TransactionLog` at the top of the file.                                                                 | —       | ✅       |
| FR-036 | `transaction_log.gd` declares `extends RefCounted` explicitly.                                                                                    | —       | ✅       |
| FR-037 | `TransactionLog` constructor accepts an optional `max_entries: int` parameter (default `100`).                                                     | —       | ✅       |
| FR-038 | `record(type: String, currency: Enums.Currency, amount: int, balance: int) -> void` appends a transaction entry to the log.                        | —       | ✅       |
| FR-039 | Each recorded entry is a Dictionary with exactly five keys: `timestamp`, `type`, `currency`, `amount`, `balance_after`.                            | —       | ✅       |
| FR-040 | `timestamp` is set to `Time.get_ticks_msec() / 1000.0` (seconds since engine start) at the moment of recording.                                   | —       | ✅       |
| FR-041 | When the log reaches `max_entries`, new entries overwrite the oldest entry (circular buffer behavior).                                              | —       | ✅       |
| FR-042 | `get_recent(count: int) -> Array[Dictionary]` returns the most recent `min(count, current_size)` entries in chronological order (oldest first).     | —       | ✅       |
| FR-043 | `get_recent()` returns a new Array — not a reference to internal storage. Callers cannot mutate the log by modifying the returned array.           | —       | ✅       |
| FR-044 | `get_all() -> Array[Dictionary]` returns all populated entries in chronological order.                                                              | —       | ✅       |
| FR-045 | `get_count() -> int` returns the total number of entries currently in the log (up to `max_entries`).                                                | —       | ✅       |
| FR-046 | `clear() -> void` removes all entries and resets the write pointer to zero.                                                                         | —       | ✅       |
| FR-047 | `to_dict() -> Dictionary` serializes only the populated entries (not empty buffer slots) plus the `max_entries` value.                              | —       | ✅       |
| FR-048 | `from_dict(data: Dictionary) -> void` restores log state from serialized data. Validates entry structure.                                           | —       | ✅       |

---

## Section 7 — Non-Functional Requirements

| ID      | Category        | Requirement                                                                                                                                        |
| ------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| NFR-001 | Performance     | `credit()`, `debit()`, and `get_balance()` execute in O(1) time — single Dictionary lookup plus arithmetic.                                        |
| NFR-002 | Performance     | `can_afford()` executes in O(k) time where k is the number of cost entries (typically 1–3). No allocation beyond iteration.                        |
| NFR-003 | Performance     | `transact()` executes in O(k) time where k is total cost + gain entries. Two passes: validation, then mutation.                                    |
| NFR-004 | Performance     | `TransactionLog.record()` executes in O(1) time — single array index write with no resizing or shifting.                                           |
| NFR-005 | Performance     | `TransactionLog.get_recent()` executes in O(n) time where n is the requested count. Returns a new Array (defensive copy).                          |
| NFR-006 | Memory          | `Wallet` memory footprint is under 1 KB excluding the transaction log. Four integer balances plus Dictionary overhead.                              |
| NFR-007 | Memory          | `TransactionLog` with default 100 entries uses under 50 KB of memory. Each entry is a 5-key Dictionary.                                            |
| NFR-008 | Memory          | No memory leaks — both classes are RefCounted with deterministic cleanup. No circular references.                                                   |
| NFR-009 | Type Safety     | Every variable, parameter, and return type uses explicit GDScript type hints (`: int`, `: bool`, `: Dictionary`, `: Enums.Currency`).               |
| NFR-010 | Type Safety     | All dictionary keys in `_balances` are `Enums.Currency` enum values, never raw integers or strings.                                                 |
| NFR-011 | Maintainability | Adding a fifth currency requires editing only `Enums.Currency` (TASK-003) and `Wallet._init()`. No other code changes in wallet.gd.                |
| NFR-012 | Maintainability | Both files are under 150 lines each with clear section separators between logical groups.                                                           |
| NFR-013 | Compatibility   | Both files compile without errors or warnings in Godot 4.6 with GDScript strict mode enabled.                                                      |
| NFR-014 | Compatibility   | Both files are usable via `class_name` without requiring autoload registration in project settings.                                                 |
| NFR-015 | Determinism     | All operations are deterministic. No `randf()`, no non-deterministic system calls. Identical inputs produce identical outputs.                       |
| NFR-016 | Testing         | GUT test suite achieves 100% method coverage and 100% branch coverage for both `Wallet` and `TransactionLog`.                                       |
| NFR-017 | Testing         | GUT test suite runs in under 500 ms total for all wallet and transaction log tests.                                                                 |
| NFR-018 | Serialization   | `to_dict()` output is JSON-compatible — no Godot-specific types (Color, Vector2) in the output. Only int, float, String, Dictionary, Array.        |
| NFR-019 | Code Quality    | Both files pass GDScript linter (`gdtoolkit`) with zero warnings using the project's `.gdlintrc` configuration.                                     |
| NFR-020 | Code Quality    | No circular dependencies — `transaction_log.gd` depends on nothing except `Enums`; `wallet.gd` depends on `transaction_log.gd` and `Enums`.        |

---

## Section 8 — Designer's Manual

### 8.1 — How to Create and Use a Wallet

The `Wallet` class is a pure-data object. You create it with `Wallet.new()`, use its methods to modify balances, and serialize it for save/load. There is no scene tree requirement.

**Creating a fresh wallet:**

```gdscript
var wallet: Wallet = Wallet.new()

# All balances start at zero
print(wallet.get_balance(Enums.Currency.GOLD))       # → 0
print(wallet.get_balance(Enums.Currency.ESSENCE))     # → 0
print(wallet.get_balance(Enums.Currency.FRAGMENTS))   # → 0
print(wallet.get_balance(Enums.Currency.ARTIFACTS))   # → 0
```

**Crediting currency (faucet operations):**

```gdscript
# Player clears a room and earns Gold
wallet.credit(Enums.Currency.GOLD, 50)
print(wallet.get_balance(Enums.Currency.GOLD))  # → 50

# Player clears another room
wallet.credit(Enums.Currency.GOLD, 30)
print(wallet.get_balance(Enums.Currency.GOLD))  # → 80

# Boss drops an Artifact
wallet.credit(Enums.Currency.ARTIFACTS, 1)
print(wallet.get_balance(Enums.Currency.ARTIFACTS))  # → 1
```

**Debiting currency (sink operations):**

```gdscript
# Player buys a seed upgrade for 60 Gold
var success: bool = wallet.debit(Enums.Currency.GOLD, 60)
print(success)  # → true
print(wallet.get_balance(Enums.Currency.GOLD))  # → 20

# Player tries to buy something for 100 Gold — insufficient!
var failed: bool = wallet.debit(Enums.Currency.GOLD, 100)
print(failed)  # → false
print(wallet.get_balance(Enums.Currency.GOLD))  # → 20 (unchanged)
```

**Checking affordability before showing UI:**

```gdscript
# Recipe costs 200 Gold + 10 Fragments
var recipe_cost: Dictionary = {
    Enums.Currency.GOLD: 200,
    Enums.Currency.FRAGMENTS: 10,
}

if wallet.can_afford(recipe_cost):
    buy_button.disabled = false
    buy_button.modulate = Color.WHITE
else:
    buy_button.disabled = true
    buy_button.modulate = Color(1, 1, 1, 0.5)
```

**Atomic multi-currency transactions:**

```gdscript
# Player crafts gear: pay 100 Gold + 5 Fragments, receive 2 Essence
var costs: Dictionary = {
    Enums.Currency.GOLD: 100,
    Enums.Currency.FRAGMENTS: 5,
}
var gains: Dictionary = {
    Enums.Currency.ESSENCE: 2,
}

var crafted: bool = wallet.transact(costs, gains)
if crafted:
    print("Crafting succeeded!")
else:
    print("Cannot afford crafting recipe.")
```

### 8.2 — How to Read Transaction History

```gdscript
# Get the most recent 5 transactions
var log: TransactionLog = wallet.get_transaction_log()
var recent: Array[Dictionary] = log.get_recent(5)

for entry: Dictionary in recent:
    var type_str: String = entry["type"]
    var currency_val: int = entry["currency"]
    var amount_val: int = entry["amount"]
    var balance_val: int = entry["balance_after"]
    var time_val: float = entry["timestamp"]
    print("[%.1f] %s: %d (balance: %d)" % [time_val, type_str, amount_val, balance_val])
```

**Example output:**

```
[12.3] credit: 50 (balance: 50)
[14.7] credit: 30 (balance: 80)
[22.1] debit: 60 (balance: 20)
[45.6] credit: 100 (balance: 120)
[48.2] transact_debit: 100 (balance: 20)
```

### 8.3 — How to Save and Load Wallet State

```gdscript
# Saving
var save_data: Dictionary = wallet.to_dict()
var json_string: String = JSON.stringify(save_data)
var file: FileAccess = FileAccess.open("user://save.json", FileAccess.WRITE)
file.store_string(json_string)
file.close()

# Loading
var load_file: FileAccess = FileAccess.open("user://save.json", FileAccess.READ)
var loaded_json: String = load_file.get_as_text()
load_file.close()
var parsed: Variant = JSON.parse_string(loaded_json)
if parsed is Dictionary:
    wallet.from_dict(parsed)
```

### 8.4 — How to Integrate With EventBus (Future)

When EventBus is implemented as a global autoload, the wallet automatically emits signals on balance changes. Your UI subscribes like this:

```gdscript
# In your HUD script's _ready():
func _ready() -> void:
    EventBus.currency_changed.connect(_on_currency_changed)
    EventBus.currency_gained.connect(_on_currency_gained)

func _on_currency_changed(currency: Enums.Currency, new_balance: int) -> void:
    match currency:
        Enums.Currency.GOLD:
            gold_label.text = str(new_balance)
        Enums.Currency.ESSENCE:
            essence_label.text = str(new_balance)
        Enums.Currency.FRAGMENTS:
            fragments_label.text = str(new_balance)
        Enums.Currency.ARTIFACTS:
            artifacts_label.text = str(new_balance)

func _on_currency_gained(currency: Enums.Currency, amount: int) -> void:
    # Trigger floating "+50 Gold" text animation
    spawn_currency_popup(currency, amount)
```

### 8.5 — How to Add a New Currency

If the GDD ever introduces a fifth currency (e.g., `GEMS`):

1. **Edit `enums.gd` (TASK-003)**: Add `GEMS` to `enum Currency`:
   ```gdscript
   enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS, GEMS }
   ```

2. **Edit `game_config.gd` (TASK-003)**: Add `GEMS` to `CURRENCY_EARN_RATES`:
   ```gdscript
   const CURRENCY_EARN_RATES: Dictionary = {
       Enums.Currency.GOLD: 10,
       Enums.Currency.ESSENCE: 2,
       Enums.Currency.FRAGMENTS: 1,
       Enums.Currency.ARTIFACTS: 0,
       Enums.Currency.GEMS: 5,
   }
   ```

3. **Edit `wallet.gd` `_init()` only**: Add the new currency to `_balances`:
   ```gdscript
   func _init() -> void:
       _balances = {
           Enums.Currency.GOLD: 0,
           Enums.Currency.ESSENCE: 0,
           Enums.Currency.FRAGMENTS: 0,
           Enums.Currency.ARTIFACTS: 0,
           Enums.Currency.GEMS: 0,
       }
       _log = TransactionLog.new()
   ```

4. **No other wallet code changes needed.** `credit()`, `debit()`, `transact()`, `can_afford()`, `to_dict()`, and `from_dict()` all operate on the dictionary generically — they don't hardcode specific currency names.

### 8.6 — How to Use the TransactionLog Standalone

The `TransactionLog` can be used independently of the `Wallet` for any system that needs a bounded event history:

```gdscript
var log: TransactionLog = TransactionLog.new(50)  # capacity of 50 entries

# Record custom events
log.record("quest_reward", Enums.Currency.GOLD, 200, 500)
log.record("shop_purchase", Enums.Currency.GOLD, -150, 350)
log.record("idle_bonus", Enums.Currency.ESSENCE, 10, 40)

# Retrieve recent entries
var recent: Array[Dictionary] = log.get_recent(2)
print(recent.size())  # → 2
print(recent[0]["type"])  # → "shop_purchase" (second most recent)
print(recent[1]["type"])  # → "idle_bonus" (most recent)
```

### 8.7 — Transaction Log Circular Buffer Behavior

When the log is full, new entries overwrite old ones:

```gdscript
var log: TransactionLog = TransactionLog.new(3)  # capacity 3

log.record("a", Enums.Currency.GOLD, 10, 10)  # slot 0
log.record("b", Enums.Currency.GOLD, 20, 30)  # slot 1
log.record("c", Enums.Currency.GOLD, 30, 60)  # slot 2 — buffer is now full

log.record("d", Enums.Currency.GOLD, 40, 100) # overwrites slot 0

var all_entries: Array[Dictionary] = log.get_all()
print(all_entries.size())  # → 3
print(all_entries[0]["type"])  # → "b" (oldest surviving)
print(all_entries[1]["type"])  # → "c"
print(all_entries[2]["type"])  # → "d" (newest)
```

### 8.8 — Common Patterns for Downstream Systems

**Pattern: Reward distribution with logging context**

```gdscript
# In TASK-016 Expedition Reward Processor:
func distribute_rewards(wallet: Wallet, rewards: Dictionary) -> void:
    for currency: int in rewards.keys():
        var amount: int = rewards[currency] as int
        if amount > 0:
            wallet.credit(currency as Enums.Currency, amount)
```

**Pattern: Multi-currency shop purchase**

```gdscript
# In a shop system:
func attempt_purchase(wallet: Wallet, item_cost: Dictionary, item_id: String) -> bool:
    if not wallet.can_afford(item_cost):
        return false
    var success: bool = wallet.transact(item_cost, {})
    if success:
        inventory.add_item(item_id)
    return success
```

**Pattern: Crafting with material conversion**

```gdscript
# In a crafting system:
func craft_item(wallet: Wallet, recipe: Dictionary) -> bool:
    var costs: Dictionary = recipe["costs"]
    var gains: Dictionary = recipe.get("gains", {})
    return wallet.transact(costs, gains)
```

---

## Section 9 — Assumptions

| #  | Assumption                                                                                                                                              | Risk if Wrong                                                                                     |
| -- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| 1  | TASK-003 is merged and `Enums.Currency` enum exists with values `GOLD=0`, `ESSENCE=1`, `FRAGMENTS=2`, `ARTIFACTS=3`.                                    | Wallet cannot declare typed currency parameters. Blocked entirely.                                |
| 2  | `GameConfig.CURRENCY_EARN_RATES` exists and maps all four currencies to non-negative integers.                                                          | Wallet works but downstream reward calculations lack base rate reference.                          |
| 3  | There are exactly four currencies in the initial release. No fifth currency is planned for Wave 2–3.                                                    | Wallet must be re-initialized. Low risk — the design supports N currencies generically.           |
| 4  | All currency amounts are integer values. No fractional currency (0.5 Gold) exists in the GDD.                                                           | Wallet uses `int` exclusively. Switching to `float` would require a full audit.                   |
| 5  | Currency balances have no upper cap. A player can accumulate 999,999,999 Gold without hitting a limit.                                                  | If caps are needed, a `MAX_BALANCE` dictionary in GameConfig and clamping logic must be added.     |
| 6  | The EventBus autoload may not exist yet when TASK-008 is implemented. Wallet must function without it.                                                  | If Wallet hard-depends on EventBus, unit tests fail. The guarded emission pattern mitigates this.  |
| 7  | Wallet is owned by a single player profile. There is no multi-player or shared wallet scenario.                                                         | Multi-wallet requires architectural changes to ownership and access control.                       |
| 8  | `Time.get_ticks_msec()` is available in all test and runtime contexts for transaction timestamps.                                                       | If unavailable, timestamps would be zero. Low risk — it's a Godot engine built-in.                |
| 9  | Transaction log capacity of 100 entries is sufficient for debugging and UI history.                                                                      | If analytics require full history, a separate persistent log system must be added.                 |
| 10 | Save/load serialization will use JSON-compatible Dictionaries. No custom binary formats.                                                                 | `to_dict()` / `from_dict()` would need adapters for binary serialization.                         |
| 11 | All downstream systems will use `wallet.credit()` and `wallet.debit()` exclusively. No system directly modifies `_balances`.                            | If a system bypasses the wallet API, balance invariants and logging are violated silently.         |
| 12 | GDScript `Dictionary` keys maintain insertion order in Godot 4.6 for serialization predictability.                                                      | If not, `to_dict()` output may differ between runs. Functionally identical but diff-unfriendly.   |
| 13 | Negative amounts in `credit()` and `debit()` are programmer errors, not valid use cases. Assertions are appropriate.                                    | If negative credits are needed (e.g., penalty), a separate method or parameter is required.        |
| 14 | The wallet is never accessed from multiple threads simultaneously. GDScript is single-threaded.                                                          | If threading is introduced, wallet needs mutex protection or a message-queue pattern.              |

---

## Section 10 — Security & Anti-Cheat Considerations

### Threat 1: Save File Manipulation — Inflated Balances

**Attack Vector:** Player opens the JSON save file in a text editor and changes `"0": 418` (Gold balance) to `"0": 999999999`. Relaunches the game and has unlimited Gold.

**Impact:** Trivializes all Gold sinks (shop purchases, upgrades, hiring). Destroys the intended progression pacing. Player skips the entire economic game loop.

**Exploit Difficulty:** Trivial — requires a text editor and 5 seconds of work. JSON is human-readable.

**Mitigation:**
- `from_dict()` validates that all balance values are non-negative integers. This prevents negative balances from save tampering but cannot prevent inflated values.
- **Primary mitigation (future):** Save file integrity check via HMAC or checksum. A hash of the wallet state is stored alongside the data. On load, the hash is recomputed and compared. Tampering invalidates the hash and the save is rejected or flagged.
- **Secondary mitigation (future):** Obfuscation of save data via base64 encoding or lightweight encryption. Raises the bar from "text editor" to "dedicated cheating tool."
- **TASK-008 scope:** Validate data types and non-negativity only. Full anti-tamper is a future infrastructure task.

### Threat 2: Save File Manipulation — Injected Currency Keys

**Attack Vector:** Player adds a non-existent currency key to the save file: `"99": 1000000`. On load, the wallet might allocate a balance for a currency that doesn't exist, causing undefined behavior in downstream systems.

**Impact:** Potential crashes when the fake currency key is passed to `Enums.Currency` match statements. Memory waste from storing unused entries.

**Exploit Difficulty:** Low — requires understanding JSON structure.

**Mitigation:**
- `from_dict()` iterates only over known `Enums.Currency` values (0–3). Any key not in the valid range is silently ignored and discarded.
- `_balances` is re-initialized from `Enums.Currency` values in `_init()`, so the internal dictionary never contains unexpected keys.
- Downstream systems access balances via `get_balance(Enums.Currency.GOLD)` — they never iterate raw dictionary keys.

### Threat 3: Transaction Log Poisoning

**Attack Vector:** Player modifies the transaction log in the save file to contain fraudulent entries — e.g., inserting fake "boss_drop: +100 Artifacts" entries to make their transaction history look legitimate.

**Impact:** Misleading debug/analytics data. If any system uses the transaction log for validation (e.g., "only allow Artifact spend if a boss_drop entry exists"), false entries could bypass checks.

**Exploit Difficulty:** Low — same as balance manipulation.

**Mitigation:**
- **Design rule:** The transaction log is diagnostic data only. No gameplay system should use it for authorization decisions. Balances are the source of truth, not the log.
- `from_dict()` validates entry structure (all five keys present, correct types) but cannot validate logical consistency.
- **Future mitigation:** Transaction log entries could include a running hash chain (each entry's hash includes the previous entry's hash). Tampering breaks the chain and the log is marked as untrusted.

### Threat 4: Memory Exhaustion via Transaction Log

**Attack Vector:** A modded client or a bug in a downstream system calls `wallet.credit()` in a tight loop (millions of times per frame), flooding the transaction log with entries.

**Impact:** If the transaction log is unbounded, memory grows without limit until the game crashes with an out-of-memory error.

**Exploit Difficulty:** Requires code modification (modded client) or triggering a bug. Not a typical player attack vector.

**Mitigation:**
- TransactionLog uses a circular buffer with a fixed capacity (default 100). Memory is bounded regardless of how many `record()` calls occur.
- The circular buffer overwrites oldest entries — no array growth, no memory allocation after initialization.
- Even if `record()` is called 1 million times, memory usage remains constant at `max_entries * entry_size`.

### Threat 5: Negative Amount Injection via API Misuse

**Attack Vector:** A downstream system (or modded script) calls `wallet.credit(Enums.Currency.GOLD, -500)`, effectively debiting 500 Gold through the credit pathway — bypassing the debit validation and logging.

**Impact:** Balance goes negative (violating the invariant) or silently loses value without proper debit logging. Transaction log records a "credit" of -500, which is nonsensical.

**Exploit Difficulty:** Requires code access or modding. Not a player-facing attack.

**Mitigation:**
- `credit()` includes `assert(amount > 0, "Credit amount must be positive")`. In debug builds, this crashes immediately with a clear error message.
- `debit()` includes the same assertion: `assert(amount > 0, "Debit amount must be positive")`.
- In release builds where assertions are stripped, the methods include runtime guards: `if amount <= 0: return` (for credit) or `if amount <= 0: return false` (for debit).
- This dual-layer defense (assert for dev, guard for release) prevents both accidental and intentional negative-amount injection.

---

## Section 11 — Best Practices

| #  | Practice                                                                                                                                                    |
| -- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | **Always use `can_afford()` before showing purchase UI**: Grey out buttons when the player lacks funds. Never let the player click "Buy" and then fail silently. |
| 2  | **Use `transact()` for multi-currency operations**: Never call `debit()` twice in sequence for a two-currency cost. If the second debit fails, you must manually roll back the first. `transact()` handles this atomically. |
| 3  | **Use `credit()` for all faucets**: Room rewards, boss drops, idle bonuses, event grants — every currency source flows through `wallet.credit()`. This ensures logging and signal emission. |
| 4  | **Never modify `_balances` directly**: Access is through public methods only. If you find yourself writing `wallet._balances[currency] += amount`, stop — use `wallet.credit()`. |
| 5  | **Type-hint all currency parameters**: Write `func award_gold(wallet: Wallet, amount: int) -> void`, not `func award_gold(wallet, amount)`. Type hints catch bugs at parse time. |
| 6  | **Use `Enums.Currency` enum values as dictionary keys**: Write `{Enums.Currency.GOLD: 200}`, not `{"GOLD": 200}` or `{0: 200}`. Enum keys provide autocomplete and type safety. |
| 7  | **Log transaction types descriptively**: Use `"room_clear"`, `"shop_purchase"`, `"boss_drop"`, `"idle_bonus"` — not `"credit"` or `"debit"`. The type string is your forensic trail. |
| 8  | **Test with exact amounts, not ranges**: Assert `wallet.get_balance(Enums.Currency.GOLD) == 518`, not `> 500`. Economy tests must be deterministic and exact. |
| 9  | **Serialize early, serialize often**: Call `to_dict()` after significant game events (expedition complete, purchase made) and write to save file. Don't rely on exit-time saving — the app may crash. |
| 10 | **Keep the transaction log read-only in UI**: The UI reads `get_recent()` for display. It never writes to the log. Only the wallet's `credit()`, `debit()`, and `transact()` write to the log. |
| 11 | **Test the circular buffer boundary**: Always test with `max_entries = 3` in unit tests to verify overwrite behavior. Testing with `max_entries = 100` hides buffer-full edge cases. |
| 12 | **Validate `from_dict()` defensively**: Assume save files are untrusted input. Check for missing keys, wrong types, negative values, and extra keys. Silently discard invalid data rather than crashing. |
| 13 | **Avoid floating-point currency**: If a future designer suggests "0.5 Essence per room", push back. Use integer math with scaling (5 Essence per 10 rooms) instead. Float drift is a real bug source. |
| 14 | **Emit signals after state change, not before**: The wallet updates `_balances` first, logs second, emits signals third. Subscribers see the new balance, not the old one. |
| 15 | **Don't duplicate affordability logic**: If you're writing `if player_gold >= cost` anywhere outside the wallet, you're duplicating `can_afford()`. Use the wallet method instead. |

---

## Section 12 — Troubleshooting

### Issue 1: `get_balance()` Returns 0 After `credit()` Was Called

**Symptom:** Developer calls `wallet.credit(Enums.Currency.GOLD, 100)` but `wallet.get_balance(Enums.Currency.GOLD)` still returns 0.

**Cause A:** The `currency` parameter passed to `credit()` and `get_balance()` are different values. For example, `credit()` was called with the raw integer `0` instead of `Enums.Currency.GOLD`, and the dictionary key lookup failed silently.

**Fix:** Always use the typed enum: `Enums.Currency.GOLD`, never raw integers. Verify with `print(typeof(currency))` that both calls use the same key type.

**Cause B:** A new `Wallet` instance was created between the `credit()` and `get_balance()` calls. Wallets are RefCounted — if the reference is lost, the object is garbage collected and a new one has zero balances.

**Fix:** Ensure the same wallet instance is passed to all systems. Store it in a persistent location (autoload, game state manager, or passed explicitly).

### Issue 2: `transact()` Returns False Even Though Balances Look Sufficient

**Symptom:** Player has 200 Gold displayed in the HUD, but `transact({Enums.Currency.GOLD: 200}, {})` returns `false`.

**Cause A:** The HUD is displaying a cached or animated value, not the actual balance. The real balance may have been debited by another system between the display update and the transaction attempt.

**Fix:** Always call `can_afford()` immediately before `transact()`. Do not rely on cached UI values for transaction decisions.

**Cause B:** The costs dictionary uses string keys (`{"GOLD": 200}`) instead of enum keys (`{Enums.Currency.GOLD: 200}`). The wallet's validation loop iterates over the dictionary keys and looks them up in `_balances` — if the key types don't match, the lookup returns `null` and validation fails.

**Fix:** Always use `Enums.Currency` enum values as dictionary keys. Add `print(costs)` to verify key types.

### Issue 3: Transaction Log Shows Entries in Wrong Order

**Symptom:** `get_recent(5)` returns entries that appear to be out of chronological order — newer entries appear before older ones.

**Cause:** The circular buffer's read logic has a bug in the index calculation when the buffer has wrapped around. The write pointer is ahead of the logical start, and the read must account for the wrap.

**Fix:** Verify the `get_recent()` implementation correctly computes the start index as `(_write_index - count + _max_entries) % _max_entries` and reads forward from there. Test with a capacity of 3 and 5+ writes to trigger wrapping.

### Issue 4: `from_dict()` Silently Drops Currency Balances

**Symptom:** After loading a save file, one or more currency balances are 0 instead of their saved values.

**Cause A:** The save file uses string keys (`"GOLD": 500`) but `from_dict()` expects integer keys matching `Enums.Currency` values (`0: 500`). The string keys don't match any valid currency and are discarded.

**Fix:** Ensure `to_dict()` uses integer keys (which it does by default when keyed by `Enums.Currency` values). If the save file was manually created with string keys, convert them.

**Cause B:** The JSON parser converts all numeric keys to strings. JSON specification does not support integer keys — `{"0": 500}` is a string-keyed dictionary after parsing. The `from_dict()` method must handle both integer and string key formats.

**Fix:** In `from_dict()`, convert string keys back to integers before looking up in `Enums.Currency`. The implementation should try `int(key)` for string keys.

### Issue 5: EventBus Signals Not Firing After credit() or debit()

**Symptom:** The HUD is connected to `EventBus.currency_changed` but never receives updates when the wallet changes.

**Cause A:** EventBus autoload is not registered in Project Settings → AutoLoad. The wallet's guard check (`Engine.has_singleton("EventBus")`) returns `false` and signal emission is skipped.

**Fix:** Register EventBus as an autoload. Or, if EventBus is not yet implemented, this is expected behavior — the wallet functions without it.

**Cause B:** The HUD connected to the signal in `_ready()` but the wallet was credited before the HUD entered the scene tree. Signals emitted before connection are lost.

**Fix:** After connecting to signals, immediately read the current balance from the wallet to initialize the display. Don't rely on signals for initial state — only for changes.

### Issue 6: Wallet Assertion Fails in Production Build

**Symptom:** In a debug build, `credit(Enums.Currency.GOLD, 0)` triggers an assertion failure (expected). In a release/production build, the assertion is stripped and the credit silently proceeds with amount 0, logging a useless entry.

**Cause:** GDScript `assert()` statements are removed in release builds for performance. The zero-amount credit passes the stripped assertion and executes.

**Fix:** The wallet uses a dual-layer defense: assertion for dev builds plus a runtime guard for release builds:
```gdscript
func credit(currency: Enums.Currency, amount: int) -> void:
    assert(amount > 0, "Credit amount must be positive")
    if amount <= 0:
        return
    # ... proceed with credit
```

### Issue 7: Memory Usage Grows Over Long Play Sessions

**Symptom:** After hours of play with many room clears, memory usage of the wallet system keeps increasing.

**Cause:** If the TransactionLog were using an unbounded `Array.append()` instead of a circular buffer, it would grow indefinitely.

**Fix:** Verify the TransactionLog uses the circular buffer pattern. `_entries` array is pre-allocated to `max_entries` size. `record()` writes at `_write_index % _max_entries` and does not append. Confirm with `print(log.get_count())` — it should never exceed `max_entries`.

---

## Section 13 — Acceptance Criteria

### Wallet — Initialization

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-001 | File `src/models/wallet.gd` exists with `class_name Wallet` and `extends RefCounted`.                                         | Code review     |
| AC-002 | A freshly created `Wallet.new()` has Gold balance of 0.                                                                        | GUT test        |
| AC-003 | A freshly created `Wallet.new()` has Essence balance of 0.                                                                     | GUT test        |
| AC-004 | A freshly created `Wallet.new()` has Fragments balance of 0.                                                                   | GUT test        |
| AC-005 | A freshly created `Wallet.new()` has Artifacts balance of 0.                                                                   | GUT test        |
| AC-006 | `get_all_balances()` returns a Dictionary with exactly 4 keys matching the 4 `Enums.Currency` values.                          | GUT test        |
| AC-007 | `get_all_balances()` returns a copy, not a reference to internal state. Modifying the returned dict does not affect the wallet. | GUT test        |

### Wallet — Credit Operations

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-008 | `credit(Enums.Currency.GOLD, 100)` increases Gold balance from 0 to 100.                                                      | GUT test        |
| AC-009 | Two successive `credit(Enums.Currency.GOLD, 50)` calls result in Gold balance of 100.                                          | GUT test        |
| AC-010 | `credit()` works for all four currency types independently.                                                                    | GUT test        |
| AC-011 | `credit()` records a transaction log entry with type `"credit"`.                                                               | GUT test        |
| AC-012 | `credit()` with amount 0 or negative triggers assertion in debug mode and is a no-op in release mode.                          | GUT test        |

### Wallet — Debit Operations

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-013 | `debit(Enums.Currency.GOLD, 30)` on a wallet with 100 Gold returns `true` and leaves balance at 70.                            | GUT test        |
| AC-014 | `debit(Enums.Currency.GOLD, 100)` on a wallet with 100 Gold returns `true` and leaves balance at 0 (exact debit).              | GUT test        |
| AC-015 | `debit(Enums.Currency.GOLD, 101)` on a wallet with 100 Gold returns `false` and leaves balance at 100 (unchanged).             | GUT test        |
| AC-016 | `debit()` works for all four currency types independently.                                                                     | GUT test        |
| AC-017 | `debit()` records a transaction log entry with type `"debit"` only on success.                                                 | GUT test        |
| AC-018 | Failed `debit()` does not record any transaction log entry.                                                                    | GUT test        |
| AC-019 | `debit()` with amount 0 or negative triggers assertion in debug mode and returns `false` in release mode.                      | GUT test        |

### Wallet — Affordability Check

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-020 | `can_afford({Enums.Currency.GOLD: 50})` returns `true` when Gold balance is 100.                                               | GUT test        |
| AC-021 | `can_afford({Enums.Currency.GOLD: 150})` returns `false` when Gold balance is 100.                                             | GUT test        |
| AC-022 | `can_afford({Enums.Currency.GOLD: 50, Enums.Currency.ESSENCE: 10})` returns `true` when Gold ≥ 50 and Essence ≥ 10.            | GUT test        |
| AC-023 | `can_afford({Enums.Currency.GOLD: 50, Enums.Currency.ESSENCE: 10})` returns `false` when Gold ≥ 50 but Essence < 10.           | GUT test        |
| AC-024 | `can_afford({})` returns `true` (empty cost is always affordable).                                                             | GUT test        |
| AC-025 | `can_afford()` does not modify any balance (pure read operation).                                                              | GUT test        |

### Wallet — Atomic Transactions

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-026 | `transact({Gold: 50, Essence: 10}, {})` returns `true` and deducts both when affordable.                                       | GUT test        |
| AC-027 | `transact({Gold: 50, Essence: 10}, {})` returns `false` and deducts nothing when Essence is insufficient.                      | GUT test        |
| AC-028 | `transact({Gold: 50}, {Essence: 5})` deducts 50 Gold and credits 5 Essence atomically.                                        | GUT test        |
| AC-029 | `transact({}, {Gold: 100})` succeeds unconditionally (pure grant, no costs).                                                   | GUT test        |
| AC-030 | Failed `transact()` leaves all four balances completely unchanged (atomicity guarantee).                                        | GUT test        |
| AC-031 | Successful `transact()` records one log entry per currency modified.                                                           | GUT test        |
| AC-032 | `transact()` with overlapping costs and gains (same currency in both) handles correctly: debits first, then credits.            | GUT test        |

### Wallet — Serialization

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-033 | `to_dict()` returns a Dictionary with a `"balances"` key containing all four currency balances.                                | GUT test        |
| AC-034 | `to_dict()` returns a Dictionary with a `"log"` key containing the serialized transaction log.                                 | GUT test        |
| AC-035 | `from_dict(wallet.to_dict())` produces a wallet with identical balances (round-trip test).                                     | GUT test        |
| AC-036 | `from_dict()` with missing currency keys sets those currencies to 0.                                                           | GUT test        |
| AC-037 | `from_dict()` with negative balance values clamps them to 0.                                                                   | GUT test        |
| AC-038 | `from_dict()` with unknown currency keys ignores them silently.                                                                | GUT test        |
| AC-039 | `reset()` sets all four balances to 0 and clears the transaction log.                                                          | GUT test        |

### TransactionLog — Core Operations

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-040 | File `src/models/transaction_log.gd` exists with `class_name TransactionLog` and `extends RefCounted`.                         | Code review     |
| AC-041 | `TransactionLog.new()` creates a log with default capacity of 100.                                                             | GUT test        |
| AC-042 | `TransactionLog.new(50)` creates a log with capacity of 50.                                                                    | GUT test        |
| AC-043 | `record()` creates an entry with exactly 5 keys: `timestamp`, `type`, `currency`, `amount`, `balance_after`.                   | GUT test        |
| AC-044 | `get_recent(3)` returns the 3 most recent entries in chronological order (oldest first in returned array).                      | GUT test        |
| AC-045 | `get_recent(N)` where N > current count returns all existing entries.                                                          | GUT test        |
| AC-046 | `get_count()` returns the number of entries (0 initially, increments with each record, caps at max_entries).                    | GUT test        |
| AC-047 | Circular buffer: after `max_entries + 2` records, `get_count()` equals `max_entries` (not `max_entries + 2`).                   | GUT test        |
| AC-048 | Circular buffer: oldest entries are overwritten when buffer is full.                                                            | GUT test        |
| AC-049 | `get_recent()` returns a new Array (defensive copy). Modifying it does not affect internal state.                               | GUT test        |
| AC-050 | `clear()` resets count to 0 and `get_all()` returns an empty array.                                                            | GUT test        |

### TransactionLog — Serialization

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-051 | `to_dict()` includes a `"max_entries"` key and an `"entries"` key.                                                             | GUT test        |
| AC-052 | `from_dict(log.to_dict())` produces a log with identical entries (round-trip test).                                             | GUT test        |
| AC-053 | `to_dict()` only includes populated entries, not empty buffer slots.                                                           | GUT test        |

---

## Section 14 — Testing Requirements

All tests use the GUT (Godot Unit Testing) framework. Test files are located at `tests/models/test_wallet.gd` and `tests/models/test_transaction_log.gd`.

### Test File 1: `tests/models/test_transaction_log.gd`

```gdscript
## tests/models/test_transaction_log.gd
## GUT test suite for TASK-008: TransactionLog circular buffer
## Covers: record, get_recent, get_all, get_count, clear, circular overwrite, serialization
extends GutTest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _log: TransactionLog


func before_each() -> void:
	_log = TransactionLog.new(5)


func after_each() -> void:
	_log = null


# ---------------------------------------------------------------------------
# Section A: Construction and Defaults
# ---------------------------------------------------------------------------

func test_default_capacity_is_100() -> void:
	var default_log: TransactionLog = TransactionLog.new()
	assert_eq(default_log._max_entries, 100, "Default capacity should be 100")


func test_custom_capacity() -> void:
	assert_eq(_log._max_entries, 5, "Custom capacity should be 5")


func test_initial_count_is_zero() -> void:
	assert_eq(_log.get_count(), 0, "Initial count should be 0")


func test_initial_get_all_is_empty() -> void:
	var entries: Array[Dictionary] = _log.get_all()
	assert_eq(entries.size(), 0, "Initial get_all should return empty array")


# ---------------------------------------------------------------------------
# Section B: Recording Entries
# ---------------------------------------------------------------------------

func test_record_single_entry() -> void:
	_log.record("credit", Enums.Currency.GOLD, 50, 50)
	assert_eq(_log.get_count(), 1, "Count should be 1 after one record")


func test_record_entry_has_five_keys() -> void:
	_log.record("credit", Enums.Currency.GOLD, 50, 50)
	var entries: Array[Dictionary] = _log.get_all()
	var entry: Dictionary = entries[0]
	assert_true(entry.has("timestamp"), "Entry must have timestamp")
	assert_true(entry.has("type"), "Entry must have type")
	assert_true(entry.has("currency"), "Entry must have currency")
	assert_true(entry.has("amount"), "Entry must have amount")
	assert_true(entry.has("balance_after"), "Entry must have balance_after")
	assert_eq(entry.size(), 5, "Entry must have exactly 5 keys")


func test_record_entry_values_are_correct() -> void:
	_log.record("debit", Enums.Currency.ESSENCE, 10, 40)
	var entries: Array[Dictionary] = _log.get_all()
	var entry: Dictionary = entries[0]
	assert_eq(entry["type"], "debit", "Type should be 'debit'")
	assert_eq(entry["currency"], Enums.Currency.ESSENCE, "Currency should be ESSENCE")
	assert_eq(entry["amount"], 10, "Amount should be 10")
	assert_eq(entry["balance_after"], 40, "Balance after should be 40")
	assert_true(entry["timestamp"] is float, "Timestamp should be a float")
	assert_true(entry["timestamp"] >= 0.0, "Timestamp should be non-negative")


func test_record_multiple_entries() -> void:
	_log.record("credit", Enums.Currency.GOLD, 10, 10)
	_log.record("credit", Enums.Currency.GOLD, 20, 30)
	_log.record("credit", Enums.Currency.GOLD, 30, 60)
	assert_eq(_log.get_count(), 3, "Count should be 3 after three records")


# ---------------------------------------------------------------------------
# Section C: get_recent()
# ---------------------------------------------------------------------------

func test_get_recent_returns_requested_count() -> void:
	_log.record("a", Enums.Currency.GOLD, 10, 10)
	_log.record("b", Enums.Currency.GOLD, 20, 30)
	_log.record("c", Enums.Currency.GOLD, 30, 60)
	var recent: Array[Dictionary] = _log.get_recent(2)
	assert_eq(recent.size(), 2, "Should return 2 entries")


func test_get_recent_returns_most_recent_entries() -> void:
	_log.record("a", Enums.Currency.GOLD, 10, 10)
	_log.record("b", Enums.Currency.GOLD, 20, 30)
	_log.record("c", Enums.Currency.GOLD, 30, 60)
	var recent: Array[Dictionary] = _log.get_recent(2)
	assert_eq(recent[0]["type"], "b", "First entry should be second-most-recent")
	assert_eq(recent[1]["type"], "c", "Second entry should be most recent")


func test_get_recent_chronological_order() -> void:
	_log.record("first", Enums.Currency.GOLD, 10, 10)
	_log.record("second", Enums.Currency.GOLD, 20, 30)
	_log.record("third", Enums.Currency.GOLD, 30, 60)
	var recent: Array[Dictionary] = _log.get_recent(3)
	assert_eq(recent[0]["type"], "first", "Oldest should be first")
	assert_eq(recent[1]["type"], "second", "Middle should be second")
	assert_eq(recent[2]["type"], "third", "Newest should be third")


func test_get_recent_more_than_available() -> void:
	_log.record("only", Enums.Currency.GOLD, 10, 10)
	var recent: Array[Dictionary] = _log.get_recent(50)
	assert_eq(recent.size(), 1, "Should return only 1 entry when only 1 exists")
	assert_eq(recent[0]["type"], "only", "Should return the only entry")


func test_get_recent_zero_count() -> void:
	_log.record("a", Enums.Currency.GOLD, 10, 10)
	var recent: Array[Dictionary] = _log.get_recent(0)
	assert_eq(recent.size(), 0, "Should return empty array for count 0")


func test_get_recent_returns_defensive_copy() -> void:
	_log.record("a", Enums.Currency.GOLD, 10, 10)
	var recent: Array[Dictionary] = _log.get_recent(1)
	recent.clear()
	assert_eq(_log.get_count(), 1, "Clearing returned array should not affect log")


# ---------------------------------------------------------------------------
# Section D: Circular Buffer Behavior
# ---------------------------------------------------------------------------

func test_circular_buffer_overwrite() -> void:
	_log.record("a", Enums.Currency.GOLD, 1, 1)
	_log.record("b", Enums.Currency.GOLD, 2, 3)
	_log.record("c", Enums.Currency.GOLD, 3, 6)
	_log.record("d", Enums.Currency.GOLD, 4, 10)
	_log.record("e", Enums.Currency.GOLD, 5, 15)
	# Buffer is now full (capacity 5)
	_log.record("f", Enums.Currency.GOLD, 6, 21)
	# "a" should be overwritten
	assert_eq(_log.get_count(), 5, "Count should not exceed max_entries")
	var all_entries: Array[Dictionary] = _log.get_all()
	assert_eq(all_entries[0]["type"], "b", "Oldest should be 'b' after overwrite")
	assert_eq(all_entries[4]["type"], "f", "Newest should be 'f'")


func test_circular_buffer_multiple_overwrites() -> void:
	_log.record("a", Enums.Currency.GOLD, 1, 1)
	_log.record("b", Enums.Currency.GOLD, 2, 3)
	_log.record("c", Enums.Currency.GOLD, 3, 6)
	_log.record("d", Enums.Currency.GOLD, 4, 10)
	_log.record("e", Enums.Currency.GOLD, 5, 15)
	_log.record("f", Enums.Currency.GOLD, 6, 21)
	_log.record("g", Enums.Currency.GOLD, 7, 28)
	_log.record("h", Enums.Currency.GOLD, 8, 36)
	# a, b, c should be overwritten
	var all_entries: Array[Dictionary] = _log.get_all()
	assert_eq(all_entries.size(), 5, "Should have exactly 5 entries")
	assert_eq(all_entries[0]["type"], "d", "Oldest surviving should be 'd'")
	assert_eq(all_entries[4]["type"], "h", "Newest should be 'h'")


func test_circular_buffer_get_recent_after_wrap() -> void:
	_log.record("a", Enums.Currency.GOLD, 1, 1)
	_log.record("b", Enums.Currency.GOLD, 2, 3)
	_log.record("c", Enums.Currency.GOLD, 3, 6)
	_log.record("d", Enums.Currency.GOLD, 4, 10)
	_log.record("e", Enums.Currency.GOLD, 5, 15)
	_log.record("f", Enums.Currency.GOLD, 6, 21)
	_log.record("g", Enums.Currency.GOLD, 7, 28)
	var recent: Array[Dictionary] = _log.get_recent(3)
	assert_eq(recent.size(), 3, "Should return 3 entries")
	assert_eq(recent[0]["type"], "e", "Oldest of recent 3 should be 'e'")
	assert_eq(recent[1]["type"], "f", "Middle should be 'f'")
	assert_eq(recent[2]["type"], "g", "Newest should be 'g'")


# ---------------------------------------------------------------------------
# Section E: get_all() and get_count()
# ---------------------------------------------------------------------------

func test_get_all_returns_all_entries_in_order() -> void:
	_log.record("x", Enums.Currency.ESSENCE, 1, 1)
	_log.record("y", Enums.Currency.FRAGMENTS, 2, 2)
	_log.record("z", Enums.Currency.ARTIFACTS, 3, 3)
	var all_entries: Array[Dictionary] = _log.get_all()
	assert_eq(all_entries.size(), 3, "Should have 3 entries")
	assert_eq(all_entries[0]["type"], "x", "First should be 'x'")
	assert_eq(all_entries[1]["type"], "y", "Second should be 'y'")
	assert_eq(all_entries[2]["type"], "z", "Third should be 'z'")


func test_get_count_increments_correctly() -> void:
	assert_eq(_log.get_count(), 0, "Initial count is 0")
	_log.record("a", Enums.Currency.GOLD, 1, 1)
	assert_eq(_log.get_count(), 1, "Count is 1 after 1 record")
	_log.record("b", Enums.Currency.GOLD, 2, 3)
	assert_eq(_log.get_count(), 2, "Count is 2 after 2 records")


func test_get_count_caps_at_max_entries() -> void:
	for i: int in range(10):
		_log.record("entry_%d" % i, Enums.Currency.GOLD, i, i)
	assert_eq(_log.get_count(), 5, "Count should cap at max_entries (5)")


# ---------------------------------------------------------------------------
# Section F: clear()
# ---------------------------------------------------------------------------

func test_clear_resets_count() -> void:
	_log.record("a", Enums.Currency.GOLD, 10, 10)
	_log.record("b", Enums.Currency.GOLD, 20, 30)
	_log.clear()
	assert_eq(_log.get_count(), 0, "Count should be 0 after clear")


func test_clear_empties_get_all() -> void:
	_log.record("a", Enums.Currency.GOLD, 10, 10)
	_log.clear()
	var all_entries: Array[Dictionary] = _log.get_all()
	assert_eq(all_entries.size(), 0, "get_all should return empty after clear")


func test_record_after_clear_works() -> void:
	_log.record("before", Enums.Currency.GOLD, 10, 10)
	_log.clear()
	_log.record("after", Enums.Currency.GOLD, 20, 20)
	assert_eq(_log.get_count(), 1, "Count should be 1 after clear + record")
	var all_entries: Array[Dictionary] = _log.get_all()
	assert_eq(all_entries[0]["type"], "after", "Entry should be the post-clear record")


# ---------------------------------------------------------------------------
# Section G: Serialization
# ---------------------------------------------------------------------------

func test_to_dict_has_required_keys() -> void:
	_log.record("a", Enums.Currency.GOLD, 10, 10)
	var data: Dictionary = _log.to_dict()
	assert_true(data.has("max_entries"), "Should have max_entries key")
	assert_true(data.has("entries"), "Should have entries key")


func test_to_dict_max_entries_value() -> void:
	var data: Dictionary = _log.to_dict()
	assert_eq(data["max_entries"], 5, "max_entries should be 5")


func test_to_dict_entries_count() -> void:
	_log.record("a", Enums.Currency.GOLD, 10, 10)
	_log.record("b", Enums.Currency.GOLD, 20, 30)
	var data: Dictionary = _log.to_dict()
	var entries: Array = data["entries"]
	assert_eq(entries.size(), 2, "Should serialize exactly 2 entries")


func test_to_dict_only_populated_entries() -> void:
	_log.record("only_one", Enums.Currency.GOLD, 10, 10)
	var data: Dictionary = _log.to_dict()
	var entries: Array = data["entries"]
	assert_eq(entries.size(), 1, "Should serialize only 1 entry, not full capacity")


func test_round_trip_serialization() -> void:
	_log.record("a", Enums.Currency.GOLD, 10, 10)
	_log.record("b", Enums.Currency.ESSENCE, 5, 5)
	_log.record("c", Enums.Currency.FRAGMENTS, 3, 3)
	var data: Dictionary = _log.to_dict()
	var restored_log: TransactionLog = TransactionLog.new()
	restored_log.from_dict(data)
	assert_eq(restored_log.get_count(), 3, "Restored log should have 3 entries")
	var original_all: Array[Dictionary] = _log.get_all()
	var restored_all: Array[Dictionary] = restored_log.get_all()
	for i: int in range(3):
		assert_eq(restored_all[i]["type"], original_all[i]["type"], "Entry %d type should match" % i)
		assert_eq(restored_all[i]["currency"], original_all[i]["currency"], "Entry %d currency should match" % i)
		assert_eq(restored_all[i]["amount"], original_all[i]["amount"], "Entry %d amount should match" % i)
		assert_eq(restored_all[i]["balance_after"], original_all[i]["balance_after"], "Entry %d balance should match" % i)


func test_round_trip_after_circular_overwrite() -> void:
	for i: int in range(8):
		_log.record("entry_%d" % i, Enums.Currency.GOLD, i + 1, (i + 1) * 10)
	var data: Dictionary = _log.to_dict()
	var restored_log: TransactionLog = TransactionLog.new()
	restored_log.from_dict(data)
	assert_eq(restored_log.get_count(), 5, "Restored log should have 5 entries (capacity)")
	var restored_all: Array[Dictionary] = restored_log.get_all()
	assert_eq(restored_all[0]["type"], "entry_3", "Oldest surviving should be entry_3")
	assert_eq(restored_all[4]["type"], "entry_7", "Newest should be entry_7")
```

### Test File 2: `tests/models/test_wallet.gd`

```gdscript
## tests/models/test_wallet.gd
## GUT test suite for TASK-008: Wallet 4-currency system
## Covers: initialization, credit, debit, can_afford, transact, serialization, reset
extends GutTest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _wallet: Wallet


func before_each() -> void:
	_wallet = Wallet.new()


func after_each() -> void:
	_wallet = null


# ---------------------------------------------------------------------------
# Section A: Initialization
# ---------------------------------------------------------------------------

func test_fresh_wallet_gold_is_zero() -> void:
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 0, "Fresh wallet Gold should be 0")


func test_fresh_wallet_essence_is_zero() -> void:
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 0, "Fresh wallet Essence should be 0")


func test_fresh_wallet_fragments_is_zero() -> void:
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 0, "Fresh wallet Fragments should be 0")


func test_fresh_wallet_artifacts_is_zero() -> void:
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 0, "Fresh wallet Artifacts should be 0")


func test_get_all_balances_has_four_keys() -> void:
	var balances: Dictionary = _wallet.get_all_balances()
	assert_eq(balances.size(), 4, "Should have exactly 4 currency entries")
	assert_true(balances.has(Enums.Currency.GOLD), "Should have GOLD key")
	assert_true(balances.has(Enums.Currency.ESSENCE), "Should have ESSENCE key")
	assert_true(balances.has(Enums.Currency.FRAGMENTS), "Should have FRAGMENTS key")
	assert_true(balances.has(Enums.Currency.ARTIFACTS), "Should have ARTIFACTS key")


func test_get_all_balances_returns_copy() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var balances: Dictionary = _wallet.get_all_balances()
	balances[Enums.Currency.GOLD] = 999
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Modifying copy should not affect wallet")


func test_wallet_has_transaction_log() -> void:
	var log: TransactionLog = _wallet.get_transaction_log()
	assert_not_null(log, "Wallet should have a TransactionLog")


# ---------------------------------------------------------------------------
# Section B: Credit Operations
# ---------------------------------------------------------------------------

func test_credit_gold_increases_balance() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Gold should be 100 after credit")


func test_credit_essence_increases_balance() -> void:
	_wallet.credit(Enums.Currency.ESSENCE, 25)
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 25, "Essence should be 25 after credit")


func test_credit_fragments_increases_balance() -> void:
	_wallet.credit(Enums.Currency.FRAGMENTS, 10)
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 10, "Fragments should be 10 after credit")


func test_credit_artifacts_increases_balance() -> void:
	_wallet.credit(Enums.Currency.ARTIFACTS, 1)
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 1, "Artifacts should be 1 after credit")


func test_credit_accumulates() -> void:
	_wallet.credit(Enums.Currency.GOLD, 50)
	_wallet.credit(Enums.Currency.GOLD, 30)
	_wallet.credit(Enums.Currency.GOLD, 20)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Gold should be 100 after 50+30+20")


func test_credit_does_not_affect_other_currencies() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 0, "Essence should be unaffected")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 0, "Fragments should be unaffected")
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 0, "Artifacts should be unaffected")


func test_credit_records_transaction() -> void:
	_wallet.credit(Enums.Currency.GOLD, 50)
	var log: TransactionLog = _wallet.get_transaction_log()
	var entries: Array[Dictionary] = log.get_recent(1)
	assert_eq(entries.size(), 1, "Should have 1 log entry")
	assert_eq(entries[0]["type"], "credit", "Entry type should be 'credit'")
	assert_eq(entries[0]["currency"], Enums.Currency.GOLD, "Entry currency should be GOLD")
	assert_eq(entries[0]["amount"], 50, "Entry amount should be 50")
	assert_eq(entries[0]["balance_after"], 50, "Entry balance_after should be 50")


func test_credit_large_amount() -> void:
	_wallet.credit(Enums.Currency.GOLD, 999999999)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 999999999, "Should handle large amounts")


# ---------------------------------------------------------------------------
# Section C: Debit Operations
# ---------------------------------------------------------------------------

func test_debit_succeeds_when_sufficient() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var result: bool = _wallet.debit(Enums.Currency.GOLD, 30)
	assert_true(result, "Debit should succeed with sufficient funds")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 70, "Gold should be 70 after 100-30")


func test_debit_exact_balance() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var result: bool = _wallet.debit(Enums.Currency.GOLD, 100)
	assert_true(result, "Debit of exact balance should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 0, "Gold should be 0 after exact debit")


func test_debit_fails_when_insufficient() -> void:
	_wallet.credit(Enums.Currency.GOLD, 50)
	var result: bool = _wallet.debit(Enums.Currency.GOLD, 100)
	assert_false(result, "Debit should fail with insufficient funds")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 50, "Gold should be unchanged after failed debit")


func test_debit_fails_on_zero_balance() -> void:
	var result: bool = _wallet.debit(Enums.Currency.GOLD, 1)
	assert_false(result, "Debit should fail on zero balance")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 0, "Gold should remain 0")


func test_debit_does_not_affect_other_currencies() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.ESSENCE, 50)
	_wallet.debit(Enums.Currency.GOLD, 30)
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 50, "Essence should be unaffected by Gold debit")


func test_debit_records_transaction_on_success() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.debit(Enums.Currency.GOLD, 40)
	var log: TransactionLog = _wallet.get_transaction_log()
	var entries: Array[Dictionary] = log.get_recent(2)
	assert_eq(entries[1]["type"], "debit", "Second entry should be 'debit'")
	assert_eq(entries[1]["amount"], 40, "Debit amount should be 40")
	assert_eq(entries[1]["balance_after"], 60, "Balance after should be 60")


func test_debit_does_not_record_on_failure() -> void:
	_wallet.debit(Enums.Currency.GOLD, 100)
	var log: TransactionLog = _wallet.get_transaction_log()
	assert_eq(log.get_count(), 0, "Failed debit should not create a log entry")


func test_debit_works_for_all_currencies() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.ESSENCE, 50)
	_wallet.credit(Enums.Currency.FRAGMENTS, 25)
	_wallet.credit(Enums.Currency.ARTIFACTS, 5)
	assert_true(_wallet.debit(Enums.Currency.GOLD, 10), "Gold debit should succeed")
	assert_true(_wallet.debit(Enums.Currency.ESSENCE, 10), "Essence debit should succeed")
	assert_true(_wallet.debit(Enums.Currency.FRAGMENTS, 10), "Fragments debit should succeed")
	assert_true(_wallet.debit(Enums.Currency.ARTIFACTS, 2), "Artifacts debit should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 90, "Gold should be 90")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 40, "Essence should be 40")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 15, "Fragments should be 15")
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 3, "Artifacts should be 3")


# ---------------------------------------------------------------------------
# Section D: can_afford()
# ---------------------------------------------------------------------------

func test_can_afford_single_currency_true() -> void:
	_wallet.credit(Enums.Currency.GOLD, 200)
	var result: bool = _wallet.can_afford({Enums.Currency.GOLD: 100})
	assert_true(result, "Should afford 100 Gold with 200 balance")


func test_can_afford_single_currency_exact() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var result: bool = _wallet.can_afford({Enums.Currency.GOLD: 100})
	assert_true(result, "Should afford exactly 100 Gold with 100 balance")


func test_can_afford_single_currency_false() -> void:
	_wallet.credit(Enums.Currency.GOLD, 50)
	var result: bool = _wallet.can_afford({Enums.Currency.GOLD: 100})
	assert_false(result, "Should not afford 100 Gold with 50 balance")


func test_can_afford_multi_currency_true() -> void:
	_wallet.credit(Enums.Currency.GOLD, 200)
	_wallet.credit(Enums.Currency.ESSENCE, 50)
	var costs: Dictionary = {Enums.Currency.GOLD: 100, Enums.Currency.ESSENCE: 30}
	assert_true(_wallet.can_afford(costs), "Should afford multi-currency cost")


func test_can_afford_multi_currency_one_short() -> void:
	_wallet.credit(Enums.Currency.GOLD, 200)
	_wallet.credit(Enums.Currency.ESSENCE, 10)
	var costs: Dictionary = {Enums.Currency.GOLD: 100, Enums.Currency.ESSENCE: 30}
	assert_false(_wallet.can_afford(costs), "Should not afford when one currency is short")


func test_can_afford_empty_costs_always_true() -> void:
	assert_true(_wallet.can_afford({}), "Empty costs should always be affordable")


func test_can_afford_does_not_modify_balances() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.can_afford({Enums.Currency.GOLD: 50})
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "can_afford should not change balance")


func test_can_afford_all_four_currencies() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.ESSENCE, 50)
	_wallet.credit(Enums.Currency.FRAGMENTS, 25)
	_wallet.credit(Enums.Currency.ARTIFACTS, 5)
	var costs: Dictionary = {
		Enums.Currency.GOLD: 100,
		Enums.Currency.ESSENCE: 50,
		Enums.Currency.FRAGMENTS: 25,
		Enums.Currency.ARTIFACTS: 5,
	}
	assert_true(_wallet.can_afford(costs), "Should afford exact match for all four currencies")


# ---------------------------------------------------------------------------
# Section E: Atomic Transactions
# ---------------------------------------------------------------------------

func test_transact_debit_only_succeeds() -> void:
	_wallet.credit(Enums.Currency.GOLD, 200)
	_wallet.credit(Enums.Currency.ESSENCE, 50)
	var costs: Dictionary = {Enums.Currency.GOLD: 100, Enums.Currency.ESSENCE: 20}
	var result: bool = _wallet.transact(costs, {})
	assert_true(result, "Transaction should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Gold should be 200-100=100")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 30, "Essence should be 50-20=30")


func test_transact_debit_and_credit() -> void:
	_wallet.credit(Enums.Currency.GOLD, 200)
	var costs: Dictionary = {Enums.Currency.GOLD: 100}
	var gains: Dictionary = {Enums.Currency.ESSENCE: 10}
	var result: bool = _wallet.transact(costs, gains)
	assert_true(result, "Transaction should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Gold should be 200-100=100")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 10, "Essence should be 0+10=10")


func test_transact_fails_atomically_no_partial_debit() -> void:
	_wallet.credit(Enums.Currency.GOLD, 200)
	_wallet.credit(Enums.Currency.ESSENCE, 5)
	var costs: Dictionary = {Enums.Currency.GOLD: 100, Enums.Currency.ESSENCE: 50}
	var result: bool = _wallet.transact(costs, {})
	assert_false(result, "Transaction should fail (Essence insufficient)")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 200, "Gold should be unchanged")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 5, "Essence should be unchanged")


func test_transact_pure_grant_always_succeeds() -> void:
	var result: bool = _wallet.transact({}, {Enums.Currency.GOLD: 500})
	assert_true(result, "Pure grant should always succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 500, "Gold should be 500")


func test_transact_records_log_entries() -> void:
	_wallet.credit(Enums.Currency.GOLD, 200)
	_wallet.transact(
		{Enums.Currency.GOLD: 50},
		{Enums.Currency.ESSENCE: 5},
	)
	var log: TransactionLog = _wallet.get_transaction_log()
	var recent: Array[Dictionary] = log.get_recent(3)
	# recent[0] = initial credit of 200 Gold
	# recent[1] = transact_debit of 50 Gold
	# recent[2] = transact_credit of 5 Essence
	assert_eq(recent[1]["type"], "transact_debit", "Should log transact_debit")
	assert_eq(recent[1]["currency"], Enums.Currency.GOLD, "Debit currency should be GOLD")
	assert_eq(recent[1]["amount"], 50, "Debit amount should be 50")
	assert_eq(recent[2]["type"], "transact_credit", "Should log transact_credit")
	assert_eq(recent[2]["currency"], Enums.Currency.ESSENCE, "Credit currency should be ESSENCE")
	assert_eq(recent[2]["amount"], 5, "Credit amount should be 5")


func test_transact_failed_does_not_log() -> void:
	_wallet.credit(Enums.Currency.GOLD, 10)
	var initial_count: int = _wallet.get_transaction_log().get_count()
	_wallet.transact({Enums.Currency.GOLD: 100}, {})
	assert_eq(_wallet.get_transaction_log().get_count(), initial_count, "Failed transact should not add log entries")


func test_transact_same_currency_in_costs_and_gains() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	var result: bool = _wallet.transact(
		{Enums.Currency.GOLD: 80},
		{Enums.Currency.GOLD: 50},
	)
	assert_true(result, "Should succeed: 100 >= 80 cost")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 70, "Gold should be 100-80+50=70")


func test_transact_all_four_currencies() -> void:
	_wallet.credit(Enums.Currency.GOLD, 1000)
	_wallet.credit(Enums.Currency.ESSENCE, 500)
	_wallet.credit(Enums.Currency.FRAGMENTS, 250)
	_wallet.credit(Enums.Currency.ARTIFACTS, 10)
	var costs: Dictionary = {
		Enums.Currency.GOLD: 200,
		Enums.Currency.ESSENCE: 100,
		Enums.Currency.FRAGMENTS: 50,
		Enums.Currency.ARTIFACTS: 2,
	}
	var gains: Dictionary = {
		Enums.Currency.GOLD: 10,
		Enums.Currency.ESSENCE: 5,
	}
	var result: bool = _wallet.transact(costs, gains)
	assert_true(result, "Four-currency transaction should succeed")
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 810, "Gold: 1000-200+10=810")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 405, "Essence: 500-100+5=405")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 200, "Fragments: 250-50=200")
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 8, "Artifacts: 10-2=8")


# ---------------------------------------------------------------------------
# Section F: Serialization
# ---------------------------------------------------------------------------

func test_to_dict_has_balances_key() -> void:
	var data: Dictionary = _wallet.to_dict()
	assert_true(data.has("balances"), "to_dict should have 'balances' key")


func test_to_dict_has_log_key() -> void:
	var data: Dictionary = _wallet.to_dict()
	assert_true(data.has("log"), "to_dict should have 'log' key")


func test_to_dict_balances_values() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.ESSENCE, 50)
	var data: Dictionary = _wallet.to_dict()
	var balances: Dictionary = data["balances"]
	assert_eq(balances[Enums.Currency.GOLD], 100, "Serialized Gold should be 100")
	assert_eq(balances[Enums.Currency.ESSENCE], 50, "Serialized Essence should be 50")
	assert_eq(balances[Enums.Currency.FRAGMENTS], 0, "Serialized Fragments should be 0")
	assert_eq(balances[Enums.Currency.ARTIFACTS], 0, "Serialized Artifacts should be 0")


func test_round_trip_preserves_balances() -> void:
	_wallet.credit(Enums.Currency.GOLD, 418)
	_wallet.credit(Enums.Currency.ESSENCE, 15)
	_wallet.credit(Enums.Currency.FRAGMENTS, 12)
	_wallet.credit(Enums.Currency.ARTIFACTS, 2)
	var data: Dictionary = _wallet.to_dict()
	var restored: Wallet = Wallet.new()
	restored.from_dict(data)
	assert_eq(restored.get_balance(Enums.Currency.GOLD), 418, "Restored Gold should be 418")
	assert_eq(restored.get_balance(Enums.Currency.ESSENCE), 15, "Restored Essence should be 15")
	assert_eq(restored.get_balance(Enums.Currency.FRAGMENTS), 12, "Restored Fragments should be 12")
	assert_eq(restored.get_balance(Enums.Currency.ARTIFACTS), 2, "Restored Artifacts should be 2")


func test_from_dict_missing_currency_defaults_to_zero() -> void:
	var data: Dictionary = {
		"balances": {Enums.Currency.GOLD: 100},
		"log": {"max_entries": 100, "entries": []},
	}
	_wallet.from_dict(data)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Gold should be 100")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 0, "Missing Essence should default to 0")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 0, "Missing Fragments should default to 0")
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 0, "Missing Artifacts should default to 0")


func test_from_dict_negative_balance_clamped_to_zero() -> void:
	var data: Dictionary = {
		"balances": {Enums.Currency.GOLD: -500, Enums.Currency.ESSENCE: 10},
		"log": {"max_entries": 100, "entries": []},
	}
	_wallet.from_dict(data)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 0, "Negative Gold should be clamped to 0")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 10, "Valid Essence should be preserved")


func test_from_dict_ignores_unknown_keys() -> void:
	var data: Dictionary = {
		"balances": {Enums.Currency.GOLD: 100, 99: 5000},
		"log": {"max_entries": 100, "entries": []},
	}
	_wallet.from_dict(data)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Gold should be 100")
	assert_eq(_wallet.get_all_balances().size(), 4, "Should still have exactly 4 currencies")


func test_from_dict_with_string_keys_from_json() -> void:
	var data: Dictionary = {
		"balances": {"0": 100, "1": 50, "2": 25, "3": 3},
		"log": {"max_entries": 100, "entries": []},
	}
	_wallet.from_dict(data)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Gold from string key '0' should be 100")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 50, "Essence from string key '1' should be 50")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 25, "Fragments from string key '2' should be 25")
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 3, "Artifacts from string key '3' should be 3")


# ---------------------------------------------------------------------------
# Section G: Reset
# ---------------------------------------------------------------------------

func test_reset_zeros_all_balances() -> void:
	_wallet.credit(Enums.Currency.GOLD, 500)
	_wallet.credit(Enums.Currency.ESSENCE, 200)
	_wallet.credit(Enums.Currency.FRAGMENTS, 100)
	_wallet.credit(Enums.Currency.ARTIFACTS, 10)
	_wallet.reset()
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 0, "Gold should be 0 after reset")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 0, "Essence should be 0 after reset")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 0, "Fragments should be 0 after reset")
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 0, "Artifacts should be 0 after reset")


func test_reset_clears_transaction_log() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.debit(Enums.Currency.GOLD, 50)
	_wallet.reset()
	assert_eq(_wallet.get_transaction_log().get_count(), 0, "Log should be empty after reset")


func test_wallet_works_after_reset() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.reset()
	_wallet.credit(Enums.Currency.GOLD, 200)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 200, "Gold should be 200 after reset + credit")
	assert_eq(_wallet.get_transaction_log().get_count(), 1, "Log should have 1 entry after reset + credit")


# ---------------------------------------------------------------------------
# Section H: Edge Cases and Invariants
# ---------------------------------------------------------------------------

func test_balance_never_negative_after_operations() -> void:
	_wallet.credit(Enums.Currency.GOLD, 10)
	_wallet.debit(Enums.Currency.GOLD, 5)
	_wallet.debit(Enums.Currency.GOLD, 5)
	_wallet.debit(Enums.Currency.GOLD, 1)  # should fail
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 0, "Balance should be 0, never negative")


func test_rapid_credit_debit_cycle() -> void:
	for i: int in range(100):
		_wallet.credit(Enums.Currency.GOLD, 10)
		_wallet.debit(Enums.Currency.GOLD, 5)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 500, "After 100 cycles of +10/-5, balance should be 500")


func test_multiple_currencies_independent() -> void:
	_wallet.credit(Enums.Currency.GOLD, 100)
	_wallet.credit(Enums.Currency.ESSENCE, 200)
	_wallet.debit(Enums.Currency.GOLD, 50)
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 50, "Gold should be 50")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 200, "Essence should be 200 (unaffected)")


func test_transact_with_empty_costs_and_empty_gains() -> void:
	var result: bool = _wallet.transact({}, {})
	assert_true(result, "Empty transact should succeed (no-op)")


func test_sequential_transactions() -> void:
	_wallet.credit(Enums.Currency.GOLD, 1000)
	_wallet.credit(Enums.Currency.ESSENCE, 100)
	_wallet.transact({Enums.Currency.GOLD: 200}, {Enums.Currency.ESSENCE: 10})
	_wallet.transact({Enums.Currency.GOLD: 300}, {Enums.Currency.FRAGMENTS: 5})
	_wallet.transact({Enums.Currency.ESSENCE: 50}, {Enums.Currency.ARTIFACTS: 1})
	assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 500, "Gold: 1000-200-300=500")
	assert_eq(_wallet.get_balance(Enums.Currency.ESSENCE), 60, "Essence: 100+10-50=60")
	assert_eq(_wallet.get_balance(Enums.Currency.FRAGMENTS), 5, "Fragments: 0+5=5")
	assert_eq(_wallet.get_balance(Enums.Currency.ARTIFACTS), 1, "Artifacts: 0+1=1")
```

---

## Section 15 — Playtesting Verification

These manual verification steps are performed by a human playtester in a running Godot 4.6 editor or exported build with a debug console available.

| #  | Verification Step                                                                                                                                                 | Expected Result                                                                                          |
| -- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| 1  | Create a `Wallet.new()` in the debug console and print all four balances.                                                                                         | All four balances print as `0`. No errors in the output log.                                              |
| 2  | Credit 100 Gold, 50 Essence, 25 Fragments, and 1 Artifact via the debug console. Print all balances.                                                              | Gold: 100, Essence: 50, Fragments: 25, Artifacts: 1.                                                     |
| 3  | Call `can_afford({Enums.Currency.GOLD: 80, Enums.Currency.ESSENCE: 60})` — Essence is insufficient.                                                               | Returns `false`. No balances change.                                                                      |
| 4  | Call `transact({Enums.Currency.GOLD: 50}, {Enums.Currency.ESSENCE: 5})`. Print Gold and Essence.                                                                  | Gold: 50, Essence: 55. Transaction succeeded.                                                             |
| 5  | Call `transact({Enums.Currency.GOLD: 200}, {})` — Gold is insufficient.                                                                                           | Returns `false`. Gold remains 50. All other balances unchanged.                                           |
| 6  | Print the last 5 transaction log entries via `get_transaction_log().get_recent(5)`.                                                                               | Shows credit entries for initial funding, a `transact_debit` for 50 Gold, and a `transact_credit` for 5 Essence. Timestamps are ascending. |
| 7  | Call `to_dict()`, then create a new wallet and `from_dict()` the data. Compare all balances.                                                                      | Restored wallet has identical balances to the original.                                                    |
| 8  | Call `reset()` and print all balances and transaction log count.                                                                                                  | All balances are 0. Log count is 0.                                                                       |
| 9  | Stress test: Credit Gold 1000 times in a loop, then debit 500 times. Verify final balance is `500 * credit_amount - 500 * debit_amount`.                         | Balance matches expected calculation. No performance stutter. Transaction log has max_entries entries.      |
| 10 | Manually edit a save file to set Gold balance to -999. Load with `from_dict()`. Print Gold balance.                                                               | Gold is clamped to 0. No crash, no error beyond expected validation.                                       |
| 11 | Manually edit a save file to add key `"99": 50000`. Load with `from_dict()`. Print `get_all_balances()`.                                                          | Only 4 valid currencies present. Unknown key `99` is silently discarded.                                   |
| 12 | If EventBus is available: connect to `currency_changed` signal, then credit Gold. Verify signal fires with correct currency and balance.                           | Signal fires once with `Enums.Currency.GOLD` and the new balance value.                                   |

---

## Section 16 — Implementation Prompt

The following is the complete GDScript implementation for both files. Copy these into the project verbatim.

### File 1: `src/models/transaction_log.gd`

```gdscript
## src/models/transaction_log.gd
## TASK-008: Transaction Log — bounded circular buffer for economy event history.
## Records the last N financial transactions for debugging, UI display, and analytics.
## Each entry: { timestamp, type, currency, amount, balance_after }
class_name TransactionLog
extends RefCounted


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const DEFAULT_MAX_ENTRIES: int = 100


# ---------------------------------------------------------------------------
# Internal State
# ---------------------------------------------------------------------------

var _entries: Array[Dictionary] = []
var _max_entries: int = DEFAULT_MAX_ENTRIES
var _write_index: int = 0
var _count: int = 0


# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

func _init(max_entries: int = DEFAULT_MAX_ENTRIES) -> void:
	_max_entries = maxi(max_entries, 1)
	_entries.resize(_max_entries)
	for i: int in range(_max_entries):
		_entries[i] = {}
	_write_index = 0
	_count = 0


# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------

## Append a transaction entry to the circular buffer.
## type: descriptive label ("credit", "debit", "transact_debit", "transact_credit", etc.)
## currency: the Enums.Currency value involved
## amount: the integer amount (always positive — the type indicates direction)
## balance: the balance AFTER the transaction was applied
func record(type: String, currency: Enums.Currency, amount: int, balance: int) -> void:
	var entry: Dictionary = {
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"type": type,
		"currency": currency,
		"amount": amount,
		"balance_after": balance,
	}
	_entries[_write_index] = entry
	_write_index = (_write_index + 1) % _max_entries
	_count = mini(_count + 1, _max_entries)


## Return the most recent `count` entries in chronological order (oldest first).
## Returns a defensive copy — callers cannot mutate internal state.
func get_recent(count: int) -> Array[Dictionary]:
	if count <= 0 or _count == 0:
		return [] as Array[Dictionary]
	var actual_count: int = mini(count, _count)
	var result: Array[Dictionary] = [] as Array[Dictionary]
	result.resize(actual_count)
	var start: int = (_write_index - actual_count + _max_entries) % _max_entries
	for i: int in range(actual_count):
		var index: int = (start + i) % _max_entries
		result[i] = _entries[index].duplicate()
	return result


## Return all populated entries in chronological order (oldest first).
func get_all() -> Array[Dictionary]:
	return get_recent(_count)


## Return the number of entries currently stored (capped at max_entries).
func get_count() -> int:
	return _count


## Remove all entries and reset the write pointer.
func clear() -> void:
	for i: int in range(_max_entries):
		_entries[i] = {}
	_write_index = 0
	_count = 0


## Serialize only the populated entries and capacity to a plain Dictionary.
func to_dict() -> Dictionary:
	var serialized_entries: Array[Dictionary] = get_all()
	return {
		"max_entries": _max_entries,
		"entries": serialized_entries,
	}


## Restore state from a serialized Dictionary. Validates entry structure.
func from_dict(data: Dictionary) -> void:
	if not data.has("max_entries") or not data.has("entries"):
		return
	var new_max: int = int(data["max_entries"])
	if new_max < 1:
		new_max = DEFAULT_MAX_ENTRIES
	_max_entries = new_max
	_entries.resize(_max_entries)
	for i: int in range(_max_entries):
		_entries[i] = {}
	_write_index = 0
	_count = 0
	var source_entries: Array = data["entries"]
	for entry_data: Variant in source_entries:
		if entry_data is Dictionary:
			var entry: Dictionary = entry_data as Dictionary
			if _is_valid_entry(entry):
				_entries[_write_index] = entry.duplicate()
				_write_index = (_write_index + 1) % _max_entries
				_count = mini(_count + 1, _max_entries)


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

func _is_valid_entry(entry: Dictionary) -> bool:
	if not entry.has("timestamp"):
		return false
	if not entry.has("type"):
		return false
	if not entry.has("currency"):
		return false
	if not entry.has("amount"):
		return false
	if not entry.has("balance_after"):
		return false
	if entry.size() != 5:
		return false
	if not (entry["timestamp"] is float or entry["timestamp"] is int):
		return false
	if not entry["type"] is String:
		return false
	if not (entry["amount"] is int or entry["amount"] is float):
		return false
	if not (entry["balance_after"] is int or entry["balance_after"] is float):
		return false
	return true
```

### File 2: `src/models/wallet.gd`

```gdscript
## src/models/wallet.gd
## TASK-008: 4-Currency Wallet — single source of truth for player economy.
## Holds Gold, Essence, Fragments, and Artifacts balances.
## Provides credit, debit, atomic multi-currency transact, affordability checks,
## and full serialization. All balance mutations are logged to TransactionLog.
class_name Wallet
extends RefCounted


# ---------------------------------------------------------------------------
# Internal State
# ---------------------------------------------------------------------------

var _balances: Dictionary = {}
var _log: TransactionLog = null


# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

func _init() -> void:
	_balances = {
		Enums.Currency.GOLD: 0,
		Enums.Currency.ESSENCE: 0,
		Enums.Currency.FRAGMENTS: 0,
		Enums.Currency.ARTIFACTS: 0,
	}
	_log = TransactionLog.new()


# ---------------------------------------------------------------------------
# Balance Queries
# ---------------------------------------------------------------------------

## Return the current balance for a specific currency.
func get_balance(currency: Enums.Currency) -> int:
	if _balances.has(currency):
		return _balances[currency] as int
	return 0


## Return a copy of all balances. Modifying the returned dict does not affect the wallet.
func get_all_balances() -> Dictionary:
	return _balances.duplicate()


## Check if the wallet can afford all costs in the dictionary.
## Keys: Enums.Currency values. Values: positive integer amounts.
## Returns true for an empty costs dictionary (zero-cost is always affordable).
func can_afford(costs: Dictionary) -> bool:
	for currency: Variant in costs.keys():
		var cost_amount: int = int(costs[currency])
		var current_balance: int = get_balance(currency as Enums.Currency)
		if current_balance < cost_amount:
			return false
	return true


# ---------------------------------------------------------------------------
# Balance Mutations
# ---------------------------------------------------------------------------

## Add funds to a specific currency. Amount must be positive.
## Records a transaction log entry and emits EventBus signals if available.
func credit(currency: Enums.Currency, amount: int) -> void:
	assert(amount > 0, "Credit amount must be positive, got: %d" % amount)
	if amount <= 0:
		return
	_balances[currency] = (_balances[currency] as int) + amount
	var new_balance: int = _balances[currency] as int
	_log.record("credit", currency, amount, new_balance)
	_emit_currency_changed(currency, new_balance)
	_emit_currency_gained(currency, amount)


## Subtract funds from a specific currency. Amount must be positive.
## Returns true on success, false if insufficient funds (no state change on failure).
func debit(currency: Enums.Currency, amount: int) -> bool:
	assert(amount > 0, "Debit amount must be positive, got: %d" % amount)
	if amount <= 0:
		return false
	var current_balance: int = _balances[currency] as int
	if current_balance < amount:
		return false
	_balances[currency] = current_balance - amount
	var new_balance: int = _balances[currency] as int
	_log.record("debit", currency, amount, new_balance)
	_emit_currency_changed(currency, new_balance)
	return true


## Atomic multi-currency transaction. Debits all costs, credits all gains.
## If any cost cannot be afforded, no changes occur (all-or-nothing).
## costs: { Enums.Currency: int } — currencies to deduct
## gains: { Enums.Currency: int } — currencies to add
## Returns true on success, false on failure (insufficient funds for any cost).
func transact(costs: Dictionary, gains: Dictionary) -> bool:
	# Phase 1: Validate all costs
	if not can_afford(costs):
		return false
	# Phase 2: Apply all debits
	for currency: Variant in costs.keys():
		var cost_amount: int = int(costs[currency])
		if cost_amount <= 0:
			continue
		var typed_currency: Enums.Currency = currency as Enums.Currency
		_balances[typed_currency] = (_balances[typed_currency] as int) - cost_amount
		var new_balance: int = _balances[typed_currency] as int
		_log.record("transact_debit", typed_currency, cost_amount, new_balance)
		_emit_currency_changed(typed_currency, new_balance)
	# Phase 3: Apply all credits
	for currency: Variant in gains.keys():
		var gain_amount: int = int(gains[currency])
		if gain_amount <= 0:
			continue
		var typed_currency: Enums.Currency = currency as Enums.Currency
		_balances[typed_currency] = (_balances[typed_currency] as int) + gain_amount
		var new_balance: int = _balances[typed_currency] as int
		_log.record("transact_credit", typed_currency, gain_amount, new_balance)
		_emit_currency_changed(typed_currency, new_balance)
		_emit_currency_gained(typed_currency, gain_amount)
	return true


# ---------------------------------------------------------------------------
# Transaction Log Access
# ---------------------------------------------------------------------------

## Return the wallet's internal TransactionLog instance.
func get_transaction_log() -> TransactionLog:
	return _log


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serialize the wallet state to a plain Dictionary suitable for JSON export.
func to_dict() -> Dictionary:
	var serialized_balances: Dictionary = {}
	for currency: Variant in _balances.keys():
		serialized_balances[currency] = _balances[currency]
	return {
		"balances": serialized_balances,
		"log": _log.to_dict(),
	}


## Restore wallet state from a serialized Dictionary.
## Validates data: unknown keys are ignored, negatives are clamped to 0.
func from_dict(data: Dictionary) -> void:
	if not data.has("balances"):
		return
	var loaded_balances: Dictionary = data["balances"]
	# Reset all balances to 0 first
	for currency: Variant in _balances.keys():
		_balances[currency] = 0
	# Restore valid currency balances
	var valid_currencies: Array = [
		Enums.Currency.GOLD,
		Enums.Currency.ESSENCE,
		Enums.Currency.FRAGMENTS,
		Enums.Currency.ARTIFACTS,
	]
	for currency: Enums.Currency in valid_currencies:
		var key_to_check: Variant = currency
		var found_value: Variant = null
		# Check for integer key (direct enum value)
		if loaded_balances.has(currency):
			found_value = loaded_balances[currency]
		# Check for string key (from JSON parsing)
		elif loaded_balances.has(str(int(currency))):
			found_value = loaded_balances[str(int(currency))]
		if found_value != null:
			var int_value: int = int(found_value)
			_balances[currency] = maxi(int_value, 0)
	# Restore transaction log
	if data.has("log") and data["log"] is Dictionary:
		_log.from_dict(data["log"])


## Reset all balances to zero and clear the transaction log.
func reset() -> void:
	for currency: Variant in _balances.keys():
		_balances[currency] = 0
	_log.clear()


# ---------------------------------------------------------------------------
# EventBus Integration (guarded — works without EventBus autoload)
# ---------------------------------------------------------------------------

func _emit_currency_changed(currency: Enums.Currency, new_balance: int) -> void:
	if Engine.has_singleton("EventBus"):
		var event_bus: Object = Engine.get_singleton("EventBus")
		if event_bus.has_signal("currency_changed"):
			event_bus.emit_signal("currency_changed", currency, new_balance)


func _emit_currency_gained(currency: Enums.Currency, amount: int) -> void:
	if Engine.has_singleton("EventBus"):
		var event_bus: Object = Engine.get_singleton("EventBus")
		if event_bus.has_signal("currency_gained"):
			event_bus.emit_signal("currency_gained", currency, amount)
```

### Integration Notes

**File placement:**
- `src/models/wallet.gd` — alongside other data models (`enums.gd`, `game_config.gd`)
- `src/models/transaction_log.gd` — same directory
- `tests/models/test_wallet.gd` — GUT test directory
- `tests/models/test_transaction_log.gd` — GUT test directory

**Dependencies (import order):**
1. `enums.gd` must be loaded first (provides `Enums.Currency`)
2. `transaction_log.gd` must be loaded before `wallet.gd` (wallet instantiates TransactionLog)
3. Both use `class_name` — no `preload()` required

**Godot project settings:** No autoload registration needed. Both classes are accessed via `class_name` static references (`Wallet.new()`, `TransactionLog.new()`).

**EventBus compatibility:** The wallet checks `Engine.has_singleton("EventBus")` before emitting. This returns `false` in unit tests and when EventBus is not yet implemented. Signal emission is silently skipped. When EventBus is added as an autoload in a future task, the wallet automatically begins emitting without any code changes.

**Running tests:**
```
# From Godot editor: Run GUT test suite
# Or via command line:
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/models -ginclude=test_wallet.gd,test_transaction_log.gd
```

---

*End of TASK-008 ticket. All 16 sections complete.*
