# Task: Design Dungeon Generation Algorithm for Magical Seeds

**Priority:** P2 – Medium Priority  
**Tier:** Core Gameplay | Systems  
**Complexity:** 8 (Fibonacci points)  
**Phase:** Enhancement  
**Dependencies:** None  

## Description

This task defines the core algorithm for procedurally generating dungeon layouts from magical seeds in the RPG/IDLE/PROGRESSION game. The goal is to create a deterministic, scalable dungeon builder that transforms a seed string or numeric hash into a connected set of rooms, corridors, difficulty nodes, and loot anchor points. The design must support easy experimentation by game designers, enable consistent dungeon replayability, and form a reusable core system for seed parsing, layout assembly, connectivity validation, and difficulty scaling.

### Executive Summary

Players plant magical seeds that grow into dungeons with varying shape, size, and challenge. This task produces the design specification and algorithm blueprint for generating those dungeons from seed data, focusing on deterministic layout construction, room connectivity rules, difficulty scaling, and a clear separation between seed decoding and map assembly. The output will be used to implement the dungeon-generation system in the game engine and to support future features like dungeon themes, adventurer pathing, and loot balancing.

### Return on Investment

- **Cost of NOT doing this:** 10-12 hours per dungeon variant manually crafted by designers, with inconsistent difficulty and replayability. As the game scales, this multiplies into dozens of hours per content cycle and increases QA effort by 40% due to unpredictable dungeon shapes.
- **Cost of doing this:** 12-16 hours to design the algorithm and document the deterministic generation pipeline, plus 8-10 hours for initial implementation in a follow-up task.
- **Break-even:** < 1 content cycle. If the design prevents just two manually composed dungeons and enables one new seed variant per week, the savings exceed 24 hours of designer and developer overhead.
- **Qualitative benefits:** Creates a stable procedural generation foundation, reduces future content churn, improves player retention by enabling more varied dungeon experiences, and enables analytics on seed distribution and difficulty progression.

### Technical Architecture Overview

The dungeon generation system is composed of three logical layers: Seed Layer, Layout Layer, and Difficulty Layer. The algorithm is deterministic and can produce the same dungeon from the same seed across sessions, while still allowing parameterized variation through difficulty, world stage, and theme modifiers.

```
Seed Input
   ├── Seed Parser
   │    ├── Normalize seed string / numeric seed
   │    ├── Extract generation flags
   │    ├── Produce base entropy vector
   │    └── Output SeedDescriptor
   ├── Layout Generator
   │    ├── Create room grid template
   │    ├── Instantiate rooms and corridors
   │    ├── Validate connectivity
   │    └── Output DungeonMap
   └── Difficulty Scaler
        ├── Apply stage difficulty curve
        ├── Assign encounter density
        ├── Set loot rarity anchors
        └── Output DungeonMetadata

DungeonMap + DungeonMetadata
   ├── Room connectivity graph
   ├── Entrance / exit placement
   ├── Difficulty nodes and pacing
   ├── Loot anchor points
   └── Seed metadata for replayability
```

### Integration Points

- **Seed Input Interface:** Accepts a magical seed string or numeric seed from the planting system and returns a normalized generation descriptor. This is the entry point from the planting/growth sequence.
- **Dungeon Construction Pipeline:** The layout generator is the central service used by the game world manager to instantiate dungeon rooms and corridors when the dungeon is harvested or entered.
- **Adventurer Assignment:** Generates metadata used by the adventurer system to choose appropriate parties based on dungeon difficulty and connectivity.
- **Loot and Encounter Systems:** Provides anchor points and difficulty bands to the loot distribution and encounter spawn systems for later implementation.
- **Progression Scaling:** Connects to the progression engine by consuming world tier, player level, and dungeon seed rarity to produce a difficulty scale.

### Constraints and Design Decisions

1. **Decision:** Use a deterministic seed parser that maps any input seed into a fixed entropy vector.  
   **Rationale:** Ensures the same seed always produces the same dungeon layout for replayability and player communication.  
   **Trade-off:** Limits totally random behavior in exchange for trackable seed outcomes.

2. **Decision:** Represent layouts as a connectivity graph of rooms and corridors rather than a fixed grid.  
   **Rationale:** Supports irregular dungeon shapes, multiplicity of room sizes, and future theme variations.  
   **Trade-off:** Slightly more complex path validation versus a simple tile-based grid.

3. **Decision:** Separate room generation from corridor generation.  
   **Rationale:** Allows designer-controlled room placement heuristics and corridor connectivity policies independently.  
   **Trade-off:** Requires an additional validation pass to ensure all rooms connect.

4. **Decision:** Use a multi-pass generation approach: seed decode → room template selection → graph assembly → connectivity repair → difficulty assignment.  
   **Rationale:** Makes the algorithm easier to reason about, test, and extend.  
   **Trade-off:** Higher implementation complexity than a single-pass builder.

5. **Decision:** Scale difficulty using stage-based banding rather than continuous per-room difficulty.  
   **Rationale:** Simplifies balancing and keeps difficulty progression predictable as players advance in tiers.  
   **Trade-off:** Can produce coarser difficulty gradations, requiring careful band tuning.

6. **Decision:** Keep seed parsing logic engine-agnostic and fit for both GDScript and C# implementation.  
   **Rationale:** Future-proofs the algorithm for cross-platform prototyping and potential engine migration.  
   **Trade-off:** Avoids engine-specific optimizations, which may reduce performance in one platform.
## Use Cases

### Use Case 1: Seed Growth and Dungeon Construction
**Persona:** Game Designer (Mina), authoring new seed-based dungeon experiences  
**Context:** Mina needs a repeatable definition of how magical seeds expand into connected dungeon layouts based on seed input and difficulty tier.  
**Action:** Mina supplies a seed string plus a progression tier and inspects the output descriptor produced by the algorithm.  
**Outcome:** The system returns a deterministic dungeon blueprint with room connectivity, entrance/exit placement, and difficulty anchors that can be used by the game engine and analytics tools.

### Use Case 2: Adventurer Mission Planning
**Persona:** Systems Designer (Troy), balancing expedition difficulty for adventurers  
**Context:** Troy needs dungeon metadata to decide whether a party is appropriate for an incoming seed-grown dungeon.  
**Action:** Troy queries the generation algorithm with seed input and player-progression parameters, then uses the returned difficulty band and path complexity score.  
**Outcome:** Adventurer assignments become predictable and scalable, reducing frustration from dungeons that are too hard or too easy for the intended stage.

### Use Case 3: Seed Replayability Validation
**Persona:** QA Lead (Asha), verifying consistency across game sessions  
**Context:** Asha must ensure that a seed results in the same dungeon layout every time it is generated and that difficulty scaling remains consistent across builds.  
**Action:** Asha runs the algorithm repeatedly with identical seed and difficulty parameters, comparing the generated dungeon graphs and metadata.  
**Outcome:** The dungeon generation algorithm is validated as deterministic and stable, allowing the team to support player-shared seed content and replay-focused progression.

### Use Case 4: Difficulty Curve Tuning
**Persona:** Balance Engineer (Rafael), tuning the dungeon difficulty progression curve  
**Context:** Rafael needs to understand how seed entropy and stage index influence enemy density, room challenge, and loot guard difficulty.  
**Action:** Rafael experiments with the stage-based difficulty scaler and inspects how encounter density, trap frequency, and loot rarity anchors adapt to progression.  
**Outcome:** The team obtains a repeatable tuning lens, enabling difficulty curves to be adjusted without changing the underlying layout generation logic.

## Glossary

- **Magical Seed:** A player-generated item or string that encodes dungeon generation parameters and determines the shape and challenge of the resulting dungeon.
- **Seed Descriptor:** The normalized representation of parsed seed data, including entropy values, generation flags, theme index, and difficulty seed.
- **Deterministic Generation:** An algorithm property where the same input seed and parameters always produce the same dungeon layout and metadata.
- **Room Graph:** A graph model where nodes represent dungeon rooms and edges represent corridors or connections between rooms.
- **Connectivity Validation:** The process of verifying that every active room in a dungeon can reach the entrance or exit through valid corridors.
- **Difficulty Band:** A discrete difficulty category assigned to a dungeon based on stage, player progress, and seed rarity.
- **Anchor Point:** A reserved room or location within the dungeon used to place special content like bosses, treasure, or puzzles.
- **Layout Template:** A generation pattern that defines room counts, size distributions, and corridor density for a given seed type.
- **Progression Tier:** The game stage or player advancement level used to scale dungeon difficulty, often represented as an integer or band.
- **Entropy Vector:** A set of pseudo-random values derived from the seed input used to decide room placement, layout shape, and challenge modifiers.
- **Corridor Heuristic:** The rule set used to choose how corridors connect rooms, balancing direct paths, loops, and dead-end complexity.
- **Seed Rarity:** A parameter that influences dungeon richness, complexity, and reward potential based on the type of magical seed planted.
- **Dungeon Metadata:** The generated data attached to a dungeon that includes difficulty score, expected completion time, loot rarity, and path complexity.

## Out of Scope

- Rendering dungeon geometry, tiles, or assets in the game engine  
- Implementing the full planting/harvest gameplay loop  
- Adventurer pathfinding AI and in-dungeon combat systems  
- Loot economy balancing and reward tables  
- Theme-specific art, sound, or visual effects  
- Multiplayer or social sharing features for seeds  
- Save file serialization and persistence of generated dungeons  
- Random seeded content outside of dungeon generation (e.g., overworld events)  
- Custom in-game editor for seed creation or dungeon preview  
- Post-generation dungeon modification or runtime remodeling  

## Functional Requirements

### Seed Parsing
- FR-001: The system MUST accept both alphanumeric seed strings and numeric seeds as valid input.
- FR-002: The system MUST normalize input seeds by trimming whitespace and converting to a canonical form before parsing.
- FR-003: The system MUST produce a `SeedDescriptor` containing at least: base entropy values, theme selector, difficulty seed, and layout flags.
- FR-004: The system MUST derive an entropy vector from the normalized seed that is deterministic across runs.
- FR-005: The system MUST expose a validation method that returns whether a seed is syntactically valid.

### Layout Generation
- FR-006: The system MUST generate a dungeon layout composed of room nodes and corridor edges.
- FR-007: The system MUST support at least three room size categories: small, medium, and large.
- FR-008: The system MUST enforce that the generated dungeon contains an entrance room and an exit room.
- FR-009: The system MUST generate at least one path between entrance and exit in every valid dungeon.
- FR-010: The system MUST allow room count to scale based on progression tier and seed rarity.
- FR-011: The system MUST categorize rooms as `Normal`, `Treasure`, `Challenge`, or `Boss` during generation.
- FR-012: The system MUST place anchor points for loot or special encounters in non-entrance rooms.
- FR-013: The system MUST avoid generating isolated rooms that do not belong to the main connectivity graph.
- FR-014: The system MUST produce room coordinates or relative positions sufficient for later rendering.

### Connectivity and Validation
- FR-015: The system MUST validate dungeon connectivity after initial room placement and before returning the layout.
- FR-016: The system MUST repair missing connections by adding corridors or reusing existing nodes when the layout is disconnected.
- FR-017: The system MUST compute a simple connectivity score indicating path complexity and loop count.
- FR-018: The system MUST reject generated layouts that cannot satisfy the connectivity validation at the configured difficulty tier.
- FR-019: The system MUST allow generation of loopy dungeons with at least one optional shortcut or bypass path.
- FR-020: The system MUST ensure the dungeon graph can be traversed without revisiting the same room more than necessary in the primary path.

### Difficulty and Scaling
- FR-021: The system MUST accept a progression tier parameter that influences room count, enemy density, and loot quality anchors.
- FR-022: The system MUST produce a difficulty band for each dungeon using a deterministic formula based on seed entropy and progression tier.
- FR-023: The system MUST assign challenge intensity values to rooms, with higher values for rooms closer to the exit or boss.
- FR-024: The system MUST compute a difficulty pacing curve that increases toward the dungeon exit.
- FR-025: The system MUST reserve at least one high-difficulty room for a potential boss or elite encounter in seed rarity tiers above normal.
- FR-026: The system MUST output metadata for use by the adventurer assignment system, including expected completion time and difficulty score.
- FR-027: The system MUST support a seed rarity modifier that increases layout complexity and reward anchor density.
- FR-028: The system MUST maintain deterministic difficulty scaling so the same seed and tier always produce the same band and anchors.

### Output and Debugging
- FR-029: The system MUST output a digestible dungeon blueprint object suitable for visualization and QA inspection.
- FR-030: The system MUST expose a debug mode that surfaces parsed seed values, chosen room templates, and corridor decisions.

## Non-Functional Requirements

- NFR-001: The algorithm MUST complete seed parsing and layout generation in under 50ms for a single dungeon on target hardware.
- NFR-002: The algorithm MUST use no more than 20MB of memory during generation in normal operating conditions.
- NFR-003: The system MUST be deterministic so repeated generation with the same seed and parameters yields identical output.
- NFR-004: The system MUST be modular so the seed parser, layout generator, connectivity validator, and difficulty scaler can be tested independently.
- NFR-005: The system MUST fail gracefully when receiving invalid seed input and return descriptive validation errors.
- NFR-006: The system MUST expose debug information without altering production generation output.
- NFR-007: The system MUST support at least three difficulty tiers in the progression curve without requiring code changes.
- NFR-008: The system MUST preserve seed entropy across upgrades by versioning the generation schema.
- NFR-009: The system MUST produce output suitable for automated QA regression tests.
- NFR-010: The system MUST include clear, typed contract objects for generated dungeon metadata.
- NFR-011: The system MUST be engine-agnostic, with no direct dependency on rendering or physics systems in the design layer.
- NFR-012: The system MUST document all public interfaces and data contracts clearly for downstream consumers.
- NFR-013: The system MUST support configurable layout template pools to avoid hardcoded room templates.
- NFR-014: The system MUST expose a human-readable debug summary for QA and tuning workflows.
- NFR-015: The system MUST accommodate future theme variants by separating theme selector logic from layout assembly.
- NFR-016: The system MUST maintain consistent room counts and path complexity within +/- 10% of the targeted tier range.
- NFR-017: The system MUST ensure that anchor points are placed in rooms that are reachable in the primary path.
- NFR-018: The system MUST provide metrics for expected completion time in the dungeon metadata object.
- NFR-019: The system MUST enforce configuration validation at initialization for generation parameter sets.
- NFR-020: The system MUST avoid magic numbers in the algorithm and use named constants for room categories, difficulty bands, and seed flags.

## User Manual Documentation

### Overview

This section documents how designers, developers, and QA engineers should use the dungeon generation algorithm. It describes the input contract, expected outputs, configuration knobs, and debugging workflow.

### 1. Dungeon Generation Workflow

1. Provide a seed input and generation context: `seedInput`, `progressionTier`, `seedRarity`, and `generationMode`.
2. Normalize the seed and create a `SeedDescriptor`.
3. Select a layout template based on base entropy and seed rarity.
4. Create a room graph using the layout generator.
5. Validate and repair connectivity.
6. Scale difficulty and place anchor points.
7. Return a `DungeonBlueprint` object containing layout, metadata, and debug payload.

### 2. Input Parameters

- `seedInput` (string | int): The magical seed value provided by the planting system.
- `progressionTier` (int): The current progression stage, used to scale room count and difficulty.
- `seedRarity` (enum): The rarity category that influences reward anchor density and challenge.
- `generationMode` (enum): One of `QuickPreview`, `Production`, or `Debug`.

### 3. Output Objects

#### `SeedDescriptor`
- `NormalizedSeed` (string)
- `EntropyVector` (float[] or int[])
- `ThemeIndex` (int)
- `DifficultySeed` (int)
- `LayoutFlags` (bitmask)

#### `DungeonBlueprint`
- `Rooms` (RoomNode[])
- `Corridors` (CorridorConnection[])
- `EntranceRoomId` (string)
- `ExitRoomId` (string)
- `DifficultyBand` (string)
- `DifficultyScore` (float)
- `ExpectedCompletionSeconds` (float)
- `AnchorPoints` (AnchorPoint[])
- `DebugSummary` (string)

### 4. Example ASCII Mockup

The generated blueprint should be interpretable as a graph. The actual layout is abstracted from rendering.

```
[Entrance] -- [Hall] -- [Fork]
                     |        \
                   [Treasure]  [Challenge] -- [Boss]
                     |                   \
                   [Secret]              [Exit]
```

### 5. Seed Input Example

```json
{
  "seedInput": "RubyRoot-117",
  "progressionTier": 3,
  "seedRarity": "Uncommon",
  "generationMode": "Debug"
}
```

### 6. Expected Generation Result Example

```json
{
  "DungeonBlueprint": {
    "EntranceRoomId": "room-001",
    "ExitRoomId": "room-012",
    "DifficultyBand": "Tier3-Moderate",
    "DifficultyScore": 42.7,
    "ExpectedCompletionSeconds": 210,
    "Rooms": [ ... ],
    "Corridors": [ ... ],
    "AnchorPoints": [ ... ],
    "DebugSummary": "Seed=RUBYROOT117, LayoutTemplate=GridC, PathComplexity=1.2, AnchorCount=4"
  }
}
```

### 7. Debugging Workflow

- Use `generationMode=Debug` to populate `DebugSummary` and emit detailed seed parsing output.
- Validate the returned `SeedDescriptor` values before layout generation.
- Confirm the entrance and exit rooms exist in the room collection.
- Check that `ExpectedCompletionSeconds` is within the expected band for the progression tier.
- Ensure `AnchorPoints` are placed in distinct reachable rooms.
- Verify the connectivity score is non-zero and that the graph contains a single connected component.

### 8. Configuration Examples

#### `DungeonGenerationOptions`

```json
{
  "MaxRoomsPerTier": {
    "1": 6,
    "2": 8,
    "3": 10,
    "4": 12
  },
  "DifficultyBands": ["Tier1-Easy", "Tier2-Normal", "Tier3-Moderate", "Tier4-Hard"],
  "SeedRarityModifiers": {
    "Common": 1.0,
    "Uncommon": 1.15,
    "Rare": 1.3,
    "Legendary": 1.5
  },
  "LayoutTemplates": ["Linear", "Branching", "Looping"],
  "DebugModeEnabled": true
}
```

### 9. Developer Usage Example

```csharp
var options = new DungeonGenerationOptions { /* load config */ };
var generator = new DungeonGenerator(options);
var request = new DungeonGenerationRequest
{
    SeedInput = "RuneSeed-42",
    ProgressionTier = 2,
    SeedRarity = SeedRarity.Uncommon,
    GenerationMode = GenerationMode.Debug
};
var blueprint = generator.Generate(request);
Console.WriteLine(blueprint.DebugSummary);
```

### 10. QA Checklist

- [ ] Confirm `SeedDescriptor` normalizes identical seeds to the same canonical form.
- [ ] Confirm invalid seed syntax returns a clear validation error.
- [ ] Confirm every dungeon includes entrance and exit rooms.
- [ ] Confirm no rooms are isolated from the main path.
- [ ] Confirm difficulty band matches the configured progression tier.
- [ ] Confirm anchor points are reachable and distributed.
- [ ] Confirm debug mode surfaces seed parser details and chosen layout template.
- [ ] Confirm the output blueprint object contains all required fields.

### 11. Example Cheat Sheet for Designers

- `Common` seeds should generate shorter dungeons with fewer anchor points.
- `Uncommon` seeds should add one or two rooms and a treasure anchor.
- `Rare` seeds should include one optional loop and a high-difficulty boss anchor.
- `Legendary` seeds should produce a denser layout with multiple challenge rooms and higher expected completion time.
- Use `Debug` mode to inspect how seed entropy alters room placement without changing production state.

### 12. Change Control Notes

- If the seed parser schema changes, increment the descriptor version and preserve old version handling in the algorithm.
- If difficulty bands are updated, maintain the same deterministic mapping for existing seeds where possible.
- If a new layout template is added, include a regression test to ensure the previous templates still produce valid connected dungeons.

## Assumptions

1. The magical seed input is provided by the planting system and is available at generation time.  
2. Seed strings may contain alphanumeric characters, dashes, and underscores only.  
3. Numeric seeds are accepted and converted to the same deterministic entropy space as string seeds.  
4. The progression tier is an integer value between 1 and 4 for this design.  
5. Seed rarity is a discrete semantic category and is not treated as a continuous numeric value.  
6. Dungeon generation is performed before rendering, and the algorithm does not need to handle real-time player movement.  
7. The algorithm will not manage spawn logic for enemies, only layout and difficulty metadata.  
8. Anchor points are placeholders for later integration with loot and encounter systems.  
9. All generated dungeons are intended for single-player/adventure missions and not multiplayer sessions.  
10. The system will version the generation schema if future changes alter the output shape.  
11. All needed room size categories and layout templates are defined in configuration rather than hardcoded arrays.  
12. There is no requirement for the generation system to support cross-save compatibility between major engine versions.  
13. The algorithm should be able to execute inside a desktop or mobile-friendly environment without blocking the main thread for long periods.  
14. The initial design assumes a single entrance and single exit, with optional loops but not multiple disconnected entry points.  
15. Difficulty scaling logic will remain separate from seed parsing to allow independent balancing.  
16. Designer-facing debug summaries are sufficient for tuning without requiring a visual preview tool.  
17. The dungeon graph will use unique room identifiers rather than positional indices for robustness.  
18. The output metadata will include time-based pacing estimates but not true simulated traversal time.  

## Security Considerations

### Threat 1: Malicious Seed Input Injection

**Description:** A seed string containing invalid or specially crafted characters could cause parsing errors or unexpected behavior in the generator.

**Attack Vector:** An attacker submits a seed value with embedded control characters, SQL-style delimiters, or excessively long strings through the planting system or debug console.

**Impact:** MEDIUM - The system may crash, throw unhandled exceptions, or enter undefined generation states, affecting stability.

**Mitigations:**
- Validate seed input against a strict allowed character set before parsing.
- Enforce maximum seed length (e.g., 128 characters).
- Use exception handling around seed normalization and hashing.
- Log invalid seed submissions with severity and reject them cleanly.

**Audit Requirements:**
- Log WARN on rejected seed inputs with the invalid value clipped.
- Log ERROR on any seed parser exception.
- Include seed length and normalized value in debug audit entries.

### Threat 2: Determinism Drift Due to Schema Changes

**Description:** Changes to seed hashing or layout template selection without versioning can change output for existing seeds unexpectedly.

**Attack Vector:** Developers update the generation algorithm or configuration constants and redeploy without preserving the previous generation schema.

**Impact:** HIGH - Existing seeds may no longer generate the same dungeons, invalidating player expectations and replayability.

**Mitigations:**
- Introduce a `GenerationSchemaVersion` field in the `SeedDescriptor` and `DungeonBlueprint`.
- Maintain backward-compatible parsing for older schema versions where feasible.
- Document schema changes in release notes.
- Validate deterministic output against a seeded regression test corpus.

**Audit Requirements:**
- Log schema version used for every generation request.
- Log a warning when a generation request uses an older schema version.
- Maintain a regression dataset of representative seeds.

### Threat 3: Resource Exhaustion from Large Seed Variants

**Description:** Certain seed inputs or configuration combinations may generate excessively large layouts, consuming memory or CPU.

**Attack Vector:** Seed values purposely designed to maximize room count or loop creation, or using progression tiers outside intended bounds.

**Impact:** MEDIUM - Excessive generation time, memory spikes, or application slowdown.

**Mitigations:**
- Cap room count and corridor complexity by configuration per progression tier.
- Reject or clamp out-of-range progression tiers and rarity values.
- Measure generation runtime and abort gracefully if thresholds are exceeded.
- Use deterministic maximums for layout options instead of unbounded growth.

**Audit Requirements:**
- Log generation duration and room count for every request.
- Log warnings when capped values are applied due to excessive input.
- Alert on repeated aborted generation requests.

### Threat 4: Debug Data Leakage

**Description:** Debug mode may expose internal seed parsing and layout selection details that should remain internal.

**Attack Vector:** Debug summaries and internal metadata are surfaced in a public or player-accessible log, exposing algorithm internals.

**Impact:** LOW - Reveals design behavior and could assist players in reverse-engineering progression balance.

**Mitigations:**
- Restrict detailed debug output to internal development environments or QA builds.
- Sanitize or redact sensitive fields before exposing debug data externally.
- Use a separate debug mode flag that is not available in production player-facing builds.

**Audit Requirements:**
- Log when debug mode is enabled and the requesting environment.
- Verify debug output is not included in production telemetry.
- Review build configuration to ensure debug mode flags are gated.

### Threat 5: Invalid Connectivity Graphs in Production

**Description:** A generated dungeon may be returned with disconnected rooms or unreachable anchor points, leading to broken player experiences.

**Attack Vector:** Generation logic contains a bug in the connectivity repair step or uses stale template configuration.

**Impact:** HIGH - Players may encounter unplayable dungeons, failed missions, or progression blockers.

**Mitigations:**
- Implement a strict connectivity validation step before returning the dungeon blueprint.
- Use automated regression tests that assert graph connectivity and reachability for anchor points.
- If validation fails, regenerate with fallback parameters or return a safe default dungeon.
- Log validation failures with full debug context.

**Audit Requirements:**
- Audit every generation request for connectivity validation success or failure.
- Log the failure reason and seed identifier when a dungeon fails validation.
- Maintain a count of connectivity repairs and use it to improve template heuristics.

## Best Practices

### Development
- Use named constants for seed flags, layout templates, and difficulty bands instead of inline literals.
- Keep the seed parser isolated from graph assembly to preserve deterministic behavior during refactors.
- Add schema versioning whenever the seed descriptor or blueprint contract changes.
- Implement the generation algorithm using small, testable methods for each stage.
- Validate all public generation request objects before execution.

### Testing
- Create regression tests for a representative set of seeds, including edge cases for the shortest, longest, and rarest seeds.
- Use deterministic asserts instead of fuzzy checks for generated room IDs, connections, and difficulty bands.
- Cover invalid seed inputs and out-of-range progression tiers explicitly.
- Test connectivity repair by forcing a disconnected layout and verifying the algorithm reconnects it correctly.
- Verify the debug summary contains expected seed parser and layout selection details.

### Configuration
- Store `DungeonGenerationOptions` in a configuration file to allow designers to adjust templates without code changes.
- Use `ValidateOnStart` for generation option classes to catch invalid parameters early.
- Keep difficulty band thresholds configurable and document the expected room count ranges per tier.
- Use separate configuration settings for `DebugModeEnabled` so debugging can be toggled safely.
- Avoid hard-coding maximum room counts in the algorithm; use configuration values for flexibility.

### Collaboration
- Document the generation contract clearly for downstream teams consuming `DungeonBlueprint` metadata.
- Keep designer-facing tuning knobs separate from internal implementation details.
- Share debug output format examples with QA to speed up issue reproduction.
- Use versioned seed schemas in release notes to communicate backward compatibility.
- Align seed rarity categories with game economy and progression design goals.

### Observability
- Emit generation metrics for average room count, loop count, and generation duration.
- Log warnings when generation falls back to a repair path or cap due to invalid inputs.
- Expose audit fields for schema version, seed hash, and chosen layout template.
- Keep production logs concise; reserve verbose debug details for internal builds.
- Monitor the ratio of regenerated dungeons to directly valid dungeons to detect template drift.

## Troubleshooting

### Issue 1: Dungeon has isolated rooms
- **Symptoms:** The generated blueprint includes rooms that are not reachable from the entrance.  
- **Causes:** Connectivity repair did not execute or room placement created disconnected components.  
- **Solutions:** Verify connectivity validation logic, run regeneration with debug mode, and ensure the repair pass reconnects or removes isolated rooms.

### Issue 2: Difficulty band does not match progression tier
- **Symptoms:** A tier 2 seed generates a dungeon labeled `Tier4-Hard` unexpectedly.  
- **Causes:** Seed rarity modifiers or difficulty scaling parameters are misconfigured.  
- **Solutions:** Check `DifficultyBands` and `SeedRarityModifiers` configuration, confirm the formula uses the correct tier input, and rerun tests with known seeds.

### Issue 3: Generation time spikes above threshold
- **Symptoms:** Dungeon generation takes longer than 50ms and causes a hitch.  
- **Causes:** Unbounded room template selection or inefficient connectivity validation.  
- **Solutions:** Profile the generator, add explicit caps for maximum room count, and simplify the repair algorithm to avoid repeated graph scans.

### Issue 4: Seed parser rejects valid-looking seeds
- **Symptoms:** Seeds with hyphens or uppercase letters are rejected as invalid.  
- **Causes:** Seed normalization rules are too strict or not handling expected character sets.  
- **Solutions:** Review the seed normalization regex, permit standard alphanumeric controls, and add a normalization unit test for common seed patterns.

### Issue 5: Anchor point is unreachable
- **Symptoms:** A loot or boss anchor is placed in a room that cannot be reached through the main path.  
- **Causes:** Anchor placement is not checking room reachability after the final connectivity pass.  
- **Solutions:** Add a reachability check for anchor placement, move anchors to alternative reachable rooms, and log unreachable anchor assignments.

### Issue 6: Debug output appears in production logs
- **Symptoms:** Production telemetry shows verbose seed parser details or internal template selection strings.  
- **Causes:** Debug mode is not gated correctly or debug output is emitted unconditionally.  
- **Solutions:** Ensure `DebugModeEnabled` is disabled for production builds and conditionally generate debug summaries only when enabled.

### Issue 7: Repeated schema warnings after engine update
- **Symptoms:** Generation logs warn about schema version mismatch for existing seeds.  
- **Causes:** A schema update was applied without backward compatibility for legacy seeds.  
- **Solutions:** Implement versioned parsing for older generation schemas, document compatibility expectations, and migrate test cases to the new schema.

### Issue 8: Layout graph contains too many loops
- **Symptoms:** Dungeons frequently have excessive loops and feel overcomplex.  
- **Causes:** Corridor heuristic weights are set too high for loop generation or loop creation is not tier-capped.  
- **Solutions:** Adjust loop probability parameters, add a maximum loop threshold, and validate generated loop counts against target values.

## Acceptance Criteria

### Seed Parsing and Input
- [ ] AC-001: Given a valid alphanumeric seed string, the parser returns a `SeedDescriptor` without errors.
- [ ] AC-002: Given a valid numeric seed, the parser returns a deterministic entropy vector equivalent to the same seed normalized as a string.
- [ ] AC-003: The parser rejects seed strings containing unsupported characters and returns a descriptive validation error.
- [ ] AC-004: The parser trims whitespace and normalizes repeated hyphens consistently.
- [ ] AC-005: The `SeedDescriptor` includes `EntropyVector`, `ThemeIndex`, `DifficultySeed`, and `LayoutFlags` fields.

### Layout Generation
- [ ] AC-006: The generator produces a layout with at least one entrance room and one exit room for all valid seeds.
- [ ] AC-007: The generated layout includes at least one room of each size category when the progression tier supports it.
- [ ] AC-008: The generator assigns room categories of `Normal`, `Treasure`, `Challenge`, or `Boss` per the design.
- [ ] AC-009: The generator places at least one anchor point in a non-entrance room for reward or encounter content.
- [ ] AC-010: The layout generation returns a room graph object suitable for later rendering and pathfinding.

### Connectivity Validation
- [ ] AC-011: The system validates that all rooms in the returned layout are reachable from the entrance room.
- [ ] AC-012: A layout with disconnected rooms triggers the connectivity repair pass before final output.
- [ ] AC-013: The repair pass either connects disconnected rooms or removes them to restore connectivity.
- [ ] AC-014: The output dungeon graph contains a connectivity score indicating path complexity and loop count.
- [ ] AC-015: The generator can produce at least one optional loop or shortcut path in the dungeon.

### Difficulty Scaling
- [ ] AC-016: The generation request accepts a progression tier and uses it to scale room count and difficulty.
- [ ] AC-017: The generator returns a deterministic difficulty band for the same seed and tier.
- [ ] AC-018: The system computes a difficulty pacing curve that increases toward the final exit.
- [ ] AC-019: A rare seed rarity results in increased anchor density and higher difficulty score compared to a common seed of the same tier.
- [ ] AC-020: The generator reserves at least one high-difficulty room for boss or elite content in rarity tiers above normal.

### Output Contract and Debugging
- [ ] AC-021: The generator returns a `DungeonBlueprint` object containing `Rooms`, `Corridors`, `EntranceRoomId`, `ExitRoomId`, `DifficultyBand`, `DifficultyScore`, `ExpectedCompletionSeconds`, `AnchorPoints`, and `DebugSummary`.
- [ ] AC-022: Debug mode returns a human-readable `DebugSummary` without altering the production layout.
- [ ] AC-023: The output metadata includes an expected completion time estimate based on room count and difficulty.
- [ ] AC-024: The generator exposes a debug flag that can be toggled independently of production generation.
- [ ] AC-025: The generation schema version is recorded in the output for later compatibility checks.

### Performance and Reliability
- [ ] AC-026: The algorithm completes generation in under 50ms on target hardware with an average seed.
- [ ] AC-027: Dungeon generation uses no more than 20MB of memory during a normal request.
- [ ] AC-028: Invalid progression tiers are rejected and return a validation error rather than producing an invalid layout.
- [ ] AC-029: Invalid seed strings are rejected gracefully with logged warnings.
- [ ] AC-030: The generator does not produce magic numbers in output and uses named configuration constants.

### Determinism and Regression
- [ ] AC-031: The same seed and generation parameters produce identical `DungeonBlueprint` outputs across separate runs.
- [ ] AC-032: A regression test corpus of at least ten representative seeds is preserved and validated on every schema change.
- [ ] AC-033: A change to the seed parser results in a schema version bump and backward-compatible optional handling.
- [ ] AC-034: The debug output shows the selected layout template and seed entropy values for QA inspection.
- [ ] AC-035: The algorithm supports engine-agnostic design and can be implemented without engine-specific rendering dependencies.

### Observability and Logging
- [ ] AC-036: Generation metrics for room count, loop count, and duration are emitted for each request.
- [ ] AC-037: Warnings are logged when the generation process applies caps or repairs due to invalid inputs.
- [ ] AC-038: Every failed generation includes the seed identifier and failure reason in the log.
- [ ] AC-039: Debug mode is not enabled in production builds unless explicitly configured.
- [ ] AC-040: The output includes schema version and generation mode in the debug audit fields.

## Testing Requirements

```csharp
using System;
using System.Collections.Generic;
using Xunit;

namespace DungeonSeed.Tests
{
    public class DungeonGenerationTests
    {
        private DungeonGenerator CreateGenerator()
        {
            var options = new DungeonGenerationOptions
            {
                MaxRoomsPerTier = new Dictionary<int, int> { { 1, 6 }, { 2, 8 }, { 3, 10 }, { 4, 12 } },
                DifficultyBands = new[] { "Tier1-Easy", "Tier2-Normal", "Tier3-Moderate", "Tier4-Hard" },
                SeedRarityModifiers = new Dictionary<string, double>
                {
                    { "Common", 1.0 },
                    { "Uncommon", 1.15 },
                    { "Rare", 1.3 },
                    { "Legendary", 1.5 }
                },
                LayoutTemplates = new[] { "Linear", "Branching", "Looping" },
                DebugModeEnabled = true,
                GenerationSchemaVersion = 1
            };

            return new DungeonGenerator(options);
        }

        [Fact]
        public void Generate_WithValidStringSeed_ReturnsBlueprint()
        {
            // Arrange
            var generator = CreateGenerator();
            var request = new DungeonGenerationRequest
            {
                SeedInput = "RubyRoot-117",
                ProgressionTier = 3,
                SeedRarity = SeedRarity.Uncommon,
                GenerationMode = GenerationMode.Production
            };

            // Act
            var blueprint = generator.Generate(request);

            // Assert
            Assert.NotNull(blueprint);
            Assert.False(string.IsNullOrWhiteSpace(blueprint.EntranceRoomId));
            Assert.False(string.IsNullOrWhiteSpace(blueprint.ExitRoomId));
            Assert.NotEmpty(blueprint.Rooms);
            Assert.NotEmpty(blueprint.Corridors);
        }

        [Fact]
        public void Generate_WithNumericSeed_IsDeterministic()
        {
            // Arrange
            var generator = CreateGenerator();
            var firstRequest = new DungeonGenerationRequest
            {
                SeedInput = "42",
                ProgressionTier = 2,
                SeedRarity = SeedRarity.Common,
                GenerationMode = GenerationMode.Production
            };
            var secondRequest = new DungeonGenerationRequest
            {
                SeedInput = 42,
                ProgressionTier = 2,
                SeedRarity = SeedRarity.Common,
                GenerationMode = GenerationMode.Production
            };

            // Act
            var firstBlueprint = generator.Generate(firstRequest);
            var secondBlueprint = generator.Generate(secondRequest);

            // Assert
            Assert.Equal(firstBlueprint.DifficultyBand, secondBlueprint.DifficultyBand);
            Assert.Equal(firstBlueprint.Rooms.Count, secondBlueprint.Rooms.Count);
            Assert.Equal(firstBlueprint.Corridors.Count, secondBlueprint.Corridors.Count);
            Assert.Equal(firstBlueprint.DebugSummary, secondBlueprint.DebugSummary);
        }

        [Fact]
        public void Generate_WithInvalidSeed_ReturnsValidationError()
        {
            // Arrange
            var generator = CreateGenerator();
            var request = new DungeonGenerationRequest
            {
                SeedInput = "Invalid!Seed#$%",
                ProgressionTier = 1,
                SeedRarity = SeedRarity.Common,
                GenerationMode = GenerationMode.Production
            };

            // Act & Assert
            var exception = Assert.Throws<DungeonGenerationException>(() => generator.Generate(request));
            Assert.Contains("invalid seed", exception.Message, StringComparison.OrdinalIgnoreCase);
        }

        [Fact]
        public void Generate_WithInvalidProgressionTier_ThrowsArgumentException()
        {
            // Arrange
            var generator = CreateGenerator();
            var request = new DungeonGenerationRequest
            {
                SeedInput = "Seed-Alpha",
                ProgressionTier = 0,
                SeedRarity = SeedRarity.Common,
                GenerationMode = GenerationMode.Production
            };

            // Act & Assert
            var exception = Assert.Throws<ArgumentException>(() => generator.Generate(request));
            Assert.Contains("progression tier", exception.Message, StringComparison.OrdinalIgnoreCase);
        }

        [Fact]
        public void Generate_DungeonIsConnected_AfterValidation()
        {
            // Arrange
            var generator = CreateGenerator();
            var request = new DungeonGenerationRequest
            {
                SeedInput = "BranchSeed-200",
                ProgressionTier = 4,
                SeedRarity = SeedRarity.Rare,
                GenerationMode = GenerationMode.Production
            };

            // Act
            var blueprint = generator.Generate(request);

            // Assert
            Assert.True(blueprint.IsConnected(), "Dungeon should be fully connected from entrance to exit.");
            Assert.All(blueprint.AnchorPoints, anchor => Assert.True(blueprint.IsReachable(anchor.RoomId)));
        }

        [Fact]
        public void Generate_DebugMode_IncludesDebugSummary()
        {
            // Arrange
            var generator = CreateGenerator();
            var request = new DungeonGenerationRequest
            {
                SeedInput = "InsightSeed-333",
                ProgressionTier = 2,
                SeedRarity = SeedRarity.Uncommon,
                GenerationMode = GenerationMode.Debug
            };

            // Act
            var blueprint = generator.Generate(request);

            // Assert
            Assert.NotNull(blueprint.DebugSummary);
            Assert.Contains("Seed=", blueprint.DebugSummary, StringComparison.OrdinalIgnoreCase);
            Assert.Contains("LayoutTemplate=", blueprint.DebugSummary, StringComparison.OrdinalIgnoreCase);
        }

        [Fact]
        public void Generate_RareSeed_IncreasesDifficultyScore()
        {
            // Arrange
            var generator = CreateGenerator();
            var commonRequest = new DungeonGenerationRequest
            {
                SeedInput = "SharedSeed-500",
                ProgressionTier = 3,
                SeedRarity = SeedRarity.Common,
                GenerationMode = GenerationMode.Production
            };
            var rareRequest = new DungeonGenerationRequest
            {
                SeedInput = "SharedSeed-500",
                ProgressionTier = 3,
                SeedRarity = SeedRarity.Rare,
                GenerationMode = GenerationMode.Production
            };

            // Act
            var commonBlueprint = generator.Generate(commonRequest);
            var rareBlueprint = generator.Generate(rareRequest);

            // Assert
            Assert.True(rareBlueprint.DifficultyScore >= commonBlueprint.DifficultyScore);
            Assert.True(rareBlueprint.AnchorPoints.Count >= commonBlueprint.AnchorPoints.Count);
        }

        [Fact]
        public void Generate_Performance_IsUnderThreshold()
        {
            // Arrange
            var generator = CreateGenerator();
            var request = new DungeonGenerationRequest
            {
                SeedInput = "Performance-Seed-999",
                ProgressionTier = 4,
                SeedRarity = SeedRarity.Legendary,
                GenerationMode = GenerationMode.Production
            };
            var clock = System.Diagnostics.Stopwatch.StartNew();

            // Act
            var blueprint = generator.Generate(request);
            clock.Stop();

            // Assert
            Assert.True(clock.ElapsedMilliseconds < 50, $"Generation took {clock.ElapsedMilliseconds}ms, expected < 50ms.");
            Assert.NotNull(blueprint);
        }

        [Fact]
        public void Generate_WithSchemaVersion_EmitsVersionInfo()
        {
            // Arrange
            var generator = CreateGenerator();
            var request = new DungeonGenerationRequest
            {
                SeedInput = "SchemaSeed-777",
                ProgressionTier = 2,
                SeedRarity = SeedRarity.Uncommon,
                GenerationMode = GenerationMode.Production
            };

            // Act
            var blueprint = generator.Generate(request);

            // Assert
            Assert.Equal(1, blueprint.GenerationSchemaVersion);
            Assert.Contains("schema", blueprint.DebugSummary, StringComparison.OrdinalIgnoreCase);
        }
    }
}
```

## User Verification Steps

### Verification 1: Seed Parser Acceptance
1. Run the `DungeonGenerator.Generate` method with `SeedInput = "RubyRoot-117"`, `ProgressionTier = 3`, `SeedRarity = SeedRarity.Uncommon`, and `GenerationMode = GenerationMode.Production`.  
2. Confirm the result contains a non-empty `SeedDescriptor` and a valid `DungeonBlueprint`.  
3. Expected output: `Blueprint.Rooms.Count > 0`, `Blueprint.Corridors.Count > 0`, `Blueprint.DifficultyBand == "Tier3-Moderate"`.

### Verification 2: Numeric Seed Determinism
1. Run generation with `SeedInput = 42` and again with `SeedInput = "42"` using identical progression tier and rarity.  
2. Confirm both outputs have the same `DifficultyScore`, `Rooms.Count`, `Corridors.Count`, and `DebugSummary`.  
3. Expected output: identical blueprint metadata for both requests.

### Verification 3: Invalid Seed Rejection
1. Run generation with `SeedInput = "Invalid!Seed#$%"`.  
2. Confirm the system throws a `DungeonGenerationException` with a validation error message.  
3. Expected output: exception message contains `invalid seed` or similar.

### Verification 4: Connectivity Validation
1. Run generation for a seed marked `SeedRarity = Rare` at `ProgressionTier = 4`.  
2. Confirm `DungeonBlueprint.IsConnected()` returns true.  
3. Expected output: no disconnected rooms and all anchor point room IDs reachable.

### Verification 5: Debug Mode Output
1. Run generation in `GenerationMode.Debug` for a sample seed.  
2. Confirm `DebugSummary` is populated and contains `Seed=` and `LayoutTemplate=` text.  
3. Expected output: debug summary is non-null and descriptive.

### Verification 6: Difficulty Scaling
1. Run generation for the same `SeedInput` at `ProgressionTier = 2` with `SeedRarity = Common` and at `ProgressionTier = 2` with `SeedRarity = Rare`.  
2. Confirm the rare seed output has a greater or equal `DifficultyScore` and more `AnchorPoints`.  
3. Expected output: rare seed difficulty score is not lower than common.

### Verification 7: Performance Ceiling
1. Run generation for a high-tier legendary seed and measure elapsed time.  
2. Confirm the generator completes in under 50ms on target test hardware.  
3. Expected output: generation duration is less than the configured threshold.

### Verification 8: Schema Versioning
1. Run generation and inspect the returned blueprint for `GenerationSchemaVersion`.  
2. Confirm the value equals the configured schema version in `DungeonGenerationOptions`.  
3. Expected output: blueprint version matches expected schema version.

### Verification 9: Configuration Validation
1. Start the system with invalid `DungeonGenerationOptions`, such as an empty `DifficultyBands` array.  
2. Confirm validation fails during initialization with a clear configuration error.  
3. Expected output: startup validation exception or logged validation failure.

### Verification 10: Anchor Reachability
1. Run generation on a sample seed and check each `AnchorPoint.RoomId`.  
2. Confirm every anchor room is reachable by invoking `Blueprint.IsReachable(anchor.RoomId)`.  
3. Expected output: all anchors are reachable and none are in isolated rooms.

## Implementation Prompt

```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace DungeonSeed.Core
{
    public enum SeedRarity
    {
        Common,
        Uncommon,
        Rare,
        Legendary
    }

    public enum GenerationMode
    {
        QuickPreview,
        Production,
        Debug
    }

    public class DungeonGenerationOptions
    {
        public Dictionary<int, int> MaxRoomsPerTier { get; set; } = new Dictionary<int, int>();
        public string[] DifficultyBands { get; set; } = Array.Empty<string>();
        public Dictionary<string, double> SeedRarityModifiers { get; set; } = new Dictionary<string, double>();
        public string[] LayoutTemplates { get; set; } = Array.Empty<string>();
        public bool DebugModeEnabled { get; set; }
        public int GenerationSchemaVersion { get; set; } = 1;

        public void Validate()
        {
            if (MaxRoomsPerTier == null || MaxRoomsPerTier.Count == 0)
            {
                throw new ArgumentException("MaxRoomsPerTier configuration must be defined.");
            }

            if (DifficultyBands == null || DifficultyBands.Length < 3)
            {
                throw new ArgumentException("At least three difficulty bands must be configured.");
            }

            if (SeedRarityModifiers == null || SeedRarityModifiers.Count == 0)
            {
                throw new ArgumentException("SeedRarityModifiers must be configured.");
            }

            if (LayoutTemplates == null || LayoutTemplates.Length == 0)
            {
                throw new ArgumentException("At least one layout template must be configured.");
            }

            if (GenerationSchemaVersion <= 0)
            {
                throw new ArgumentException("GenerationSchemaVersion must be a positive integer.");
            }
        }
    }

    public class DungeonGenerationRequest
    {
        public object SeedInput { get; set; } = string.Empty;
        public int ProgressionTier { get; set; }
        public SeedRarity SeedRarity { get; set; }
        public GenerationMode GenerationMode { get; set; }
    }

    public class DungeonGenerationException : Exception
    {
        public DungeonGenerationException(string message)
            : base(message)
        {
        }
    }

    public class SeedDescriptor
    {
        public string NormalizedSeed { get; set; } = string.Empty;
        public IReadOnlyList<int> EntropyVector { get; set; } = Array.Empty<int>();
        public int ThemeIndex { get; set; }
        public int DifficultySeed { get; set; }
        public int LayoutFlags { get; set; }
        public int GenerationSchemaVersion { get; set; }
    }

    public class RoomNode
    {
        public string Id { get; set; } = string.Empty;
        public RoomSize Size { get; set; }
        public RoomCategory Category { get; set; }
        public int DifficultyValue { get; set; }
        public int X { get; set; }
        public int Y { get; set; }
        public bool IsAnchor { get; set; }
    }

    public enum RoomSize
    {
        Small,
        Medium,
        Large
    }

    public enum RoomCategory
    {
        Normal,
        Treasure,
        Challenge,
        Boss
    }

    public class CorridorConnection
    {
        public string FromRoomId { get; set; } = string.Empty;
        public string ToRoomId { get; set; } = string.Empty;
    }

    public class AnchorPoint
    {
        public string RoomId { get; set; } = string.Empty;
        public string AnchorType { get; set; } = string.Empty;
    }

    public class DungeonBlueprint
    {
        public List<RoomNode> Rooms { get; set; } = new List<RoomNode>();
        public List<CorridorConnection> Corridors { get; set; } = new List<CorridorConnection>();
        public string EntranceRoomId { get; set; } = string.Empty;
        public string ExitRoomId { get; set; } = string.Empty;
        public string DifficultyBand { get; set; } = string.Empty;
        public double DifficultyScore { get; set; }
        public double ExpectedCompletionSeconds { get; set; }
        public List<AnchorPoint> AnchorPoints { get; set; } = new List<AnchorPoint>();
        public string DebugSummary { get; set; } = string.Empty;
        public int GenerationSchemaVersion { get; set; }

        public bool IsConnected()
        {
            if (string.IsNullOrWhiteSpace(EntranceRoomId) || string.IsNullOrWhiteSpace(ExitRoomId))
            {
                return false;
            }

            var visited = new HashSet<string>();
            Traverse(EntranceRoomId, visited);
            return Rooms.All(room => visited.Contains(room.Id));
        }

        public bool IsReachable(string roomId)
        {
            if (string.IsNullOrWhiteSpace(EntranceRoomId))
            {
                return false;
            }

            var visited = new HashSet<string>();
            Traverse(EntranceRoomId, visited);
            return visited.Contains(roomId);
        }

        private void Traverse(string currentRoomId, HashSet<string> visited)
        {
            if (visited.Contains(currentRoomId))
            {
                return;
            }

            visited.Add(currentRoomId);
            var neighbors = Corridors
                .Where(edge => edge.FromRoomId == currentRoomId || edge.ToRoomId == currentRoomId)
                .Select(edge => edge.FromRoomId == currentRoomId ? edge.ToRoomId : edge.FromRoomId);

            foreach (var neighbor in neighbors)
            {
                Traverse(neighbor, visited);
            }
        }
    }

    public class DungeonGenerator
    {
        private readonly DungeonGenerationOptions _options;

        public DungeonGenerator(DungeonGenerationOptions options)
        {
            _options = options ?? throw new ArgumentNullException(nameof(options));
            _options.Validate();
        }

        public DungeonBlueprint Generate(DungeonGenerationRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (string.IsNullOrWhiteSpace(request.SeedInput?.ToString()))
            {
                throw new DungeonGenerationException("Seed input must not be null or empty.");
            }

            if (request.ProgressionTier <= 0 || !_options.MaxRoomsPerTier.ContainsKey(request.ProgressionTier))
            {
                throw new ArgumentException("Progression tier must be a valid configured tier.", nameof(request.ProgressionTier));
            }

            var descriptor = ParseSeed(request.SeedInput, request.GenerationMode);
            descriptor.GenerationSchemaVersion = _options.GenerationSchemaVersion;

            var blueprint = CreateBlueprint(descriptor, request);
            blueprint.GenerationSchemaVersion = _options.GenerationSchemaVersion;
            blueprint.DebugSummary = CreateDebugSummary(descriptor, request, blueprint);

            return blueprint;
        }

        private SeedDescriptor ParseSeed(object seedInput, GenerationMode mode)
        {
            var normalizedSeed = NormalizeSeed(seedInput.ToString() ?? string.Empty);
            ValidateSeed(normalizedSeed);
            var entropy = ComputeEntropyVector(normalizedSeed);
            var themeIndex = entropy[0] % Math.Max(1, _options.LayoutTemplates.Length);
            var difficultySeed = entropy[1];
            var layoutFlags = entropy[2] & 0xFFFF;

            return new SeedDescriptor
            {
                NormalizedSeed = normalizedSeed,
                EntropyVector = entropy,
                ThemeIndex = themeIndex,
                DifficultySeed = difficultySeed,
                LayoutFlags = layoutFlags
            };
        }

        private string NormalizeSeed(string input)
        {
            var trimmed = input.Trim();
            var sanitized = new StringBuilder(trimmed.Length);
            foreach (var c in trimmed)
            {
                if (char.IsLetterOrDigit(c) || c == '-' || c == '_')
                {
                    sanitized.Append(char.ToUpperInvariant(c));
                }
            }

            return sanitized.ToString();
        }

        private void ValidateSeed(string normalizedSeed)
        {
            if (normalizedSeed.Length == 0)
            {
                throw new DungeonGenerationException("Invalid seed: normalized seed is empty.");
            }

            if (normalizedSeed.Length > 128)
            {
                throw new DungeonGenerationException("Invalid seed: seed length exceeds maximum allowed length.");
            }
        }

        private IReadOnlyList<int> ComputeEntropyVector(string normalizedSeed)
        {
            using var sha = SHA256.Create();
            var hash = sha.ComputeHash(Encoding.UTF8.GetBytes(normalizedSeed));
            var entropy = new int[8];
            for (var index = 0; index < entropy.Length; index++)
            {
                var start = index * 4;
                entropy[index] = BitConverter.ToInt32(hash, start) & int.MaxValue;
            }

            return entropy;
        }

        private DungeonBlueprint CreateBlueprint(SeedDescriptor descriptor, DungeonGenerationRequest request)
        {
            var layoutTemplate = SelectLayoutTemplate(descriptor);
            var roomCount = ComputeRoomCount(request.ProgressionTier, request.SeedRarity, descriptor);
            var rooms = CreateRooms(descriptor, roomCount, layoutTemplate);
            var corridors = CreateCorridors(rooms, descriptor, layoutTemplate);

            var blueprint = new DungeonBlueprint
            {
                Rooms = rooms,
                Corridors = corridors,
                EntranceRoomId = rooms.First().Id,
                ExitRoomId = rooms.Last().Id
            };

            ValidateAndRepairConnectivity(blueprint, descriptor);
            AssignDifficultyAndAnchors(blueprint, request, descriptor);
            blueprint.ExpectedCompletionSeconds = EstimateCompletionTime(blueprint, request);
            blueprint.DifficultyBand = ComputeDifficultyBand(request.ProgressionTier, request.SeedRarity, descriptor, blueprint.DifficultyScore);

            return blueprint;
        }

        private string SelectLayoutTemplate(SeedDescriptor descriptor)
        {
            var index = descriptor.ThemeIndex % _options.LayoutTemplates.Length;
            return _options.LayoutTemplates[index];
        }

        private int ComputeRoomCount(int tier, SeedRarity rarity, SeedDescriptor descriptor)
        {
            var baseCount = _options.MaxRoomsPerTier[tier];
            var modifier = _options.SeedRarityModifiers.TryGetValue(rarity.ToString(), out var rate) ? rate : 1.0;
            var entropyBonus = descriptor.EntropyVector[3] % 3;
            var computed = (int)Math.Round(baseCount * modifier) + entropyBonus;
            return Math.Max(4, Math.Min(baseCount + 3, computed));
        }

        private List<RoomNode> CreateRooms(SeedDescriptor descriptor, int roomCount, string layoutTemplate)
        {
            var rooms = new List<RoomNode>(roomCount);
            var random = CreateDeterministicRandom(descriptor.EntropyVector[4]);
            var sizeDistribution = new[] { RoomSize.Small, RoomSize.Medium, RoomSize.Large };

            for (var index = 0; index < roomCount; index++)
            {
                var size = sizeDistribution[random.Next(sizeDistribution.Length)];
                var category = DetermineRoomCategory(index, roomCount, random);
                rooms.Add(new RoomNode
                {
                    Id = $"room-{index + 1:D3}",
                    Size = size,
                    Category = category,
                    X = index * 2,
                    Y = (index % 3) * 2,
                    DifficultyValue = (int)(random.NextDouble() * 10) + (index / Math.Max(1, roomCount / 4))
                });
            }

            if (layoutTemplate == "Looping")
            {
                rooms = AdjustRoomPositionsForLoops(rooms, random);
            }

            return rooms;
        }

        private RoomCategory DetermineRoomCategory(int index, int roomCount, Random random)
        {
            if (index == 0) return RoomCategory.Normal;
            if (index == roomCount - 1) return RoomCategory.Boss;
            if (index % 5 == 0) return RoomCategory.Treasure;
            if (random.NextDouble() < 0.2) return RoomCategory.Challenge;
            return RoomCategory.Normal;
        }

        private List<RoomNode> AdjustRoomPositionsForLoops(List<RoomNode> rooms, Random random)
        {
            foreach (var room in rooms)
            {
                room.X += random.Next(-1, 2);
                room.Y += random.Next(-1, 2);
            }

            return rooms;
        }

        private List<CorridorConnection> CreateCorridors(List<RoomNode> rooms, SeedDescriptor descriptor, string layoutTemplate)
        {
            var corridors = new List<CorridorConnection>();
            for (var i = 0; i < rooms.Count - 1; i++)
            {
                corridors.Add(new CorridorConnection
                {
                    FromRoomId = rooms[i].Id,
                    ToRoomId = rooms[i + 1].Id
                });
            }

            if (layoutTemplate != "Linear")
            {
                var random = CreateDeterministicRandom(descriptor.EntropyVector[5]);
                var additionalEdges = Math.Min(rooms.Count / 3, 3);
                for (var i = 0; i < additionalEdges; i++)
                {
                    var fromIndex = random.Next(0, rooms.Count - 2);
                    var toIndex = random.Next(fromIndex + 2, rooms.Count);
                    corridors.Add(new CorridorConnection
                    {
                        FromRoomId = rooms[fromIndex].Id,
                        ToRoomId = rooms[toIndex].Id
                    });
                }
            }

            return corridors.Distinct(new CorridorEqualityComparer()).ToList();
        }

        private void ValidateAndRepairConnectivity(DungeonBlueprint blueprint, SeedDescriptor descriptor)
        {
            if (blueprint.IsConnected())
            {
                return;
            }

            var random = CreateDeterministicRandom(descriptor.EntropyVector[6]);
            var disconnectedRooms = blueprint.Rooms.Where(room => !blueprint.IsReachable(room.Id)).ToList();
            foreach (var room in disconnectedRooms)
            {
                var candidate = blueprint.Rooms[random.Next(0, blueprint.Rooms.Count)];
                blueprint.Corridors.Add(new CorridorConnection
                {
                    FromRoomId = room.Id,
                    ToRoomId = candidate.Id
                });
            }

            if (!blueprint.IsConnected())
            {
                throw new DungeonGenerationException("Dungeon connectivity could not be repaired.");
            }
        }

        private void AssignDifficultyAndAnchors(DungeonBlueprint blueprint, DungeonGenerationRequest request, SeedDescriptor descriptor)
        {
            var random = CreateDeterministicRandom(descriptor.EntropyVector[7]);
            foreach (var room in blueprint.Rooms)
            {
                var baseValue = room.DifficultyValue;
                var tierAdjust = request.ProgressionTier * 2;
                room.DifficultyValue = Math.Max(1, baseValue + tierAdjust);
            }

            var candidateRooms = blueprint.Rooms.Where(room => room.Id != blueprint.EntranceRoomId && room.Id != blueprint.ExitRoomId).ToList();
            var anchorCount = Math.Max(1, Math.Min(candidateRooms.Count, request.ProgressionTier + 1));
            var selectedRooms = candidateRooms.OrderBy(room => random.Next()).Take(anchorCount).ToList();

            blueprint.AnchorPoints.Clear();
            foreach (var room in selectedRooms)
            {
                room.IsAnchor = true;
                blueprint.AnchorPoints.Add(new AnchorPoint
                {
                    RoomId = room.Id,
                    AnchorType = room.Category == RoomCategory.Boss ? "Boss" : "Loot"
                });
            }

            blueprint.DifficultyScore = ComputeDifficultyScore(blueprint, request, descriptor);
        }

        private double ComputeDifficultyScore(DungeonBlueprint blueprint, DungeonGenerationRequest request, SeedDescriptor descriptor)
        {
            var roomDifficultySum = blueprint.Rooms.Sum(room => room.DifficultyValue);
            var anchorBonus = blueprint.AnchorPoints.Count * 3.0;
            var tierFactor = request.ProgressionTier * 1.5;
            return Math.Round(roomDifficultySum / Math.Max(1, blueprint.Rooms.Count) + anchorBonus + tierFactor, 1);
        }

        private double EstimateCompletionTime(DungeonBlueprint blueprint, DungeonGenerationRequest request)
        {
            var averageRoomEffort = 15.0;
            var baseTime = blueprint.Rooms.Count * averageRoomEffort;
            var difficultyModifier = 1.0 + (blueprint.DifficultyScore / 100.0);
            return Math.Round(baseTime * difficultyModifier, 1);
        }

        private string ComputeDifficultyBand(int tier, SeedRarity rarity, SeedDescriptor descriptor, double difficultyScore)
        {
            var bandIndex = Math.Min(_options.DifficultyBands.Length - 1, tier - 1);
            return _options.DifficultyBands[bandIndex];
        }

        private Random CreateDeterministicRandom(int seedValue)
        {
            return new Random(seedValue);
        }

        private string CreateDebugSummary(SeedDescriptor descriptor, DungeonGenerationRequest request, DungeonBlueprint blueprint)
        {
            if (request.GenerationMode != GenerationMode.Debug && !_options.DebugModeEnabled)
            {
                return string.Empty;
            }

            return string.Join(", ", new[]
            {
                $"Seed={descriptor.NormalizedSeed}",
                $"Schema={descriptor.GenerationSchemaVersion}",
                $"Template={SelectLayoutTemplate(descriptor)}",
                $"RoomCount={blueprint.Rooms.Count}",
                $"DifficultyBand={blueprint.DifficultyBand}",
                $"Score={blueprint.DifficultyScore}",
                $"AnchorCount={blueprint.AnchorPoints.Count}"        
            });
        }
    }

    internal class CorridorEqualityComparer : IEqualityComparer<CorridorConnection>
    {
        public bool Equals(CorridorConnection? x, CorridorConnection? y)
        {
            if (x == null || y == null) return false;
            return (x.FromRoomId == y.FromRoomId && x.ToRoomId == y.ToRoomId)
                || (x.FromRoomId == y.ToRoomId && x.ToRoomId == y.FromRoomId);
        }

        public int GetHashCode(CorridorConnection obj)
        {
            var ids = new[] { obj.FromRoomId, obj.ToRoomId };
            Array.Sort(ids, StringComparer.Ordinal);
            return HashCode.Combine(ids[0], ids[1]);
        }
    }
}
```
