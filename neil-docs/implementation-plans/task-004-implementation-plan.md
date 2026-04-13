# Task 004 — Design UI/UX framework and visual themes
Short description
- Define UI architecture, reusable components, and theme tokens for the first biomes and MVP screens.

Acceptance criteria
- [ ] UI component library (buttons, panels, toast system) defined under `game/ui/`
- [ ] Theme token file `game/ui/theme.json` exists (colors, fonts, rarity palettes)
- [ ] Prototype planting and dispatch screens in scenes with placeholder art
- [ ] Accessible defaults (high-contrast and text scaling) present

Phased implementation
- Phase 0: Design doc
  - [ ] Create `game/design/ui-guide.md` with screen flows and wireframes
- Phase 1: Component library
  - [ ] Implement `game/ui/components/Button.tscn`, `Panel.tscn`, `Toast.tscn`
  - Tests: UI component instantiation unit tests
- Phase 2: Prototype screens
  - [ ] Scenes: planting/dispatch prototypes wired with placeholder data
  - Tests: UIBinding_works_for_sample_seed
- Phase 3: Theme & accessibility
  - [ ] Expose `game/ui/theme.json` and runtime theme switch API
  - CI: run UI instantiation tests in headless mode (node-tree checks)

Dependencies
- Task 1 (project), Task 3 (interfaces) for data-binding contracts

Deliverables & artifacts
- game/design/ui-guide.md
- game/ui/components/*.tscn
- game/ui/theme.json
- test/ui/ComponentTests.gd

Estimated complexity & risks
- Complexity: 5 points
- Risk: Designer-engine mismatch; mitigation: early playbook and wireframe sign-off.

Deterministic ID & RNG guidance
- Not generator-critical; but UI must display deterministic IDs consistently. Use DetId library.

TODOs for Game Code Executor
- Implement theme.json loader and runtime application
- Implement placeholder screens and ensure they are instantiable by automated UI smoke tests
- Expected outputs: screenshots saved to `artifacts/ui-prototypes/` (for visual review)

CI checks
- Headless instantiation of UI scenes
- Accessibility token checks (contrast ratio)
