# Title: Set up Godot project with basic scenes

ID: task-001-gtw-pass2

## Objective
Establish a Godot 4.x project scaffold, a minimal playable bootstrap scene, and folder conventions to enable rapid iteration by engineering and design. Validate project opens, runs, and provides runtime hooks for later systems (Seed Grove, Dungeon Dashboard, Adventurer Hall, Vault).

## Background
Per the GDD, Godot 4.x is the recommended engine and a clean project baseline is required before any system work. This task removes startup risk (R-001) and sets up input mappings, project settings, and a simple Scene Manager to host later modules.

## Detailed Requirements
- Create Godot 4.x project with consistent folder layout: scenes/, scripts/, assets/{sprites,sfx,music}, config/, tests/.
- Main scene (res://scenes/main.tscn) with SceneManager autoload singleton.
- Input map configured: select, drag, confirm, cancel, quick-assign.
- Basic Seed Grove placeholder scene and a minimal Dashboard scene with navigation.
- CI-friendly project settings (export templates noted, project.godot checked-in, .import settings consistent).
- A smoke test that runs the project headlessly and ensures no parsing/runtime errors.

## Acceptance Criteria
- [ ] Project opens in Godot 4.x with no parse errors.
- [ ] SceneManager autoload registered and documented.
- [ ] Input actions present and documented in README.
- [ ] Smoke test passes in CI and exits cleanly.

## Security considerations
- Ensure project does not include hardcoded secrets.
- Enforce integrity for downloaded assets (if any) and validate user-generated inputs.
- Anti-manipulation: basic telemetry for unexpected scene loads or modified script hashes during CI.

## Performance targets
- Main menu and hub scenes load under 1.5s on target PC spec.
- Editor and runtime should avoid heavy allocations during frame; smoke test must show steady 60fps idle on dev PC.

## UX notes
- Keep initial screens minimal; surface the Seed Grove as the first entry point.
- Provide clear primary CTA (Plant Seed) and unobtrusive tooltips for first run.

## Edge cases
- Missing resources gracefully degrade to placeholders.
- Project settings mismatches should show a clear error with recovery steps.

## Data Contracts
- res://config/schemas/project_manifest.tres — project metadata.
- res://config/schemas/scene_registry.json — main scenes and autoloads.
- README includes expected project.godot settings.

## Integration points
- SceneManager autoload consumed by UI and GameLoopManager (later tasks).
- SaveManager hooks for quick-save will be added by persistence task.

## QA test plan
- CI smoke test: open Godot in headless mode and run scene load sanity checks.
- Manual QA: verify navigation between Seed Grove and Dashboard on first run.

## Metrics
- CI smoke test pass/fail.
- Time-to-first-scene on target PC.

## Rollback criteria
- If project scaffold causes CI failures or blocks downstream work, revert the commit that introduced breaking project.godot settings.
- If chosen engine version causes incompatibilities, revert to prior stable branch and open an escalation ticket.

## Dependencies
- None (foundation task). Downstream: Tasks 2,3,4,5.

## Complexity estimate
- Fibonacci: 5 pts (Foundation)

