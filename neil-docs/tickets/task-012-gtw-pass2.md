# Title: Build planting/dispatch UI, dungeon rendering integration, and MVP polish

ID: task-012-gtw-pass2

## Objective
Ship the first-playable UI for planting and dispatch, render generated dungeons per theme, and apply polish to make the MVP feel complete and tutorial-friendly.

## Background
The MVP must present an end-to-end loop. This task integrates UI (Task 4), generator (Task 7), loop (Task 10), and progression (Task 11) into a playable experience consistent with the GDD hub screens and UX principles.

## Detailed Requirements
- Implement planting UI: seed slot grid, plant button, reagent quick-apply, growth timers, and ready notifications.
- Implement dispatch UI: party drag-and-drop, route preview, expected reward preview, run duration estimate.
- Integrate dungeon rendering: visualize generated graph with room icons and path highlighting.
- Provide onboarding flow and contextual tooltips to cover planting, reagents, dispatch, and harvesting.
- Polish UX: VFX for growth milestones, sound cues for ready state, micro-interactions for drag/drop.

## Acceptance Criteria
- [ ] Planting → growth timeline visible and responsive.
- [ ] Dispatch UI allows party assignment and shows reward estimates.
- [ ] Generated dungeon renders correctly and is navigable in preview mode.
- [ ] Basic tutorial completes within first 5 minutes guiding a player through a full loop.

## Security considerations
- Validate UI-submitted party configs to avoid duplicate hero assignment or overflow exploits.
- Ensure rendering previews do not execute arbitrary asset-loading code from untrusted sources.

## Performance targets
- Dispatch UI must remain interactive while previewing dungeons (<60fps impact negligible).
- Dungeon rendering in preview mode should be lightweight (icon + graph) and only instantiate full visuals on demand.

## UX notes
- Use clear affordances for drag-and-drop and provide confirmation before dispatch.
- Tutorial must reveal planting → dispatch → harvest path in under 5 minutes with minimal text.

## Edge cases
- Network-less play: ensure UI functions offline and queues actions locally.
- Party presets referencing removed heroes should degrade gracefully and notify the player.

## Data Contracts
- UI payload for dispatch preview (res://config/ui/dispatch_preview.schema.json).
- Tutorial progress contract for onboarding state.

## Integration points
- Uses DungeonInstance JSON from DungeonGenerator for rendering previews.
- Calls GameLoopManager APIs to schedule dispatch and listens to run result events.

## QA test plan
- Manual QA: playthrough of tutorial verifying first loop completes within 5 minutes.
- Automated UI tests for drag-drop party assignment and preview rendering.

## Metrics
- Tutorial completion rate.
- Time-to-first-harvest for new players.

## Rollback criteria
- If UI integration for planting/dispatch regresses core loop clarity or causes crashes, revert UI commits and disable advanced preview features until stable.

## Dependencies
- Depends on Tasks 4,7,10,11.

## Complexity estimate
- Fibonacci: 5 pts (Moderate/Foundation)

