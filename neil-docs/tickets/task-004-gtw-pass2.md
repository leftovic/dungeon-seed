# Title: Design UI/UX framework and visual themes

ID: task-004-gtw-pass2

## Objective
Define the UI architecture, reusable component library, hub flows, and visual theme guide for the first biome set so engineers and artists can implement consistent screens (Planting, Dashboard, Hall, Vault, Mutarium Atelier).

## Background
GDD describes Hub Screens and UX principles. This task formalizes layout rules, control patterns (mouse/touch), and visual tokens (colors, sizes, iconography) required for a coherent MVP.

## Detailed Requirements
- Define UI component library (Button, Toggle, ProgressBar, GridSlot, Tooltip) with theme tokens and responsive anchors.
- Provide hub flow wireframes for Seed Grove, Dashboard, Adventurer Hall, and Vault.
- Deliver icon set and color palette for rarity tiers and seed states (Spore→Bloom).
- Provide focus/navigation rules for keyboard/controller and touch targets for mobile.
- Export sample mockups and a style guide document.

## Acceptance Criteria
- [ ] Component library documented with usage examples.
- [ ] Wireframes and mockups uploaded to res://art/ui/ and linked in docs.
- [ ] Accessibility checklist (contrast, scalable text) verified for main screens.

## Security considerations
- UI resources must be sanitized for external content; ensure localization files are validated before parsing.

## Performance targets
- UI screens should render and respond at 60fps on reference PC; UI transitions under 200ms.
- Asset atlases optimized to minimize draw calls on hub screens.

## UX notes
- Use clear affordances for drag/drop and provide snap-to slots for party assignment.
- Maintain consistent visual language for rarity and seed state.

## Edge cases
- Very long localization strings should be ellipsized with a tooltip available.
- Controller focus must not be lost when UI stacks are opened.

## Data Contracts
- UI theme tokens file (res://config/ui/theme.tres)
- Component API docs for Button/ProgressBar/GridSlot components

## Integration points
- UI components consumed by Task 12 (planting/dispatch UI) and Task 1 SceneManager.
- Localization files consumed by narrative and audio systems.

## QA test plan
- Accessibility verification: contrast checker, scalable text tests.
- Interaction tests for drag-and-drop and keyboard/controller navigation.

## Metrics
- Task completion time in onboarding flow.
- Accessibility compliance checklist pass rate.

## Rollback criteria
- If UI components create accessibility regressions or block gameplay, revert to the previous UI theme and isolate breaking changes.

## Dependencies
- Depends on Task 1; consumers: Task 12.

## Complexity estimate
- Fibonacci: 5 pts (Foundation)

