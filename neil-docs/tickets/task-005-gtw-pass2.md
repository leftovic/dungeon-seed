# Title: Define audio and lore foundation

ID: task-005-gtw-pass2

## Objective
Capture the audio palette, key SFX/Music requirements, and the narrative primer (Seedwarden lore) so audio and narrative assets integrate with design and uplift player experience.

## Background
GDD provides general audio/VFX direction and narrative beats. This task produces concrete asset lists, mood boards, and short lore scripts for onboarding and seasonal framing.

## Detailed Requirements
- Produce an audio asset manifest: seed growth chime, mutation sound set, ready-dungeon cue, combat SFX placeholders, loot chime variants, ambient Grove music, expedition underscore.
- Provide brief lore primer (500–800 words) for onboarding and tooltips: Seedwarden origin, first biome story hooks, mutation lore.
- Deliver short audio mockups (placeholder OGGs) and VFX direction notes for particle intensity and timing.
- Define naming conventions and export settings (OGG Vorbis 44.1kHz, stereo for music, mono for SFX).

## Acceptance Criteria
- [ ] Asset manifest committed with file paths and rough durations.
- [ ] Lore primer approved by narrative lead and included in docs.
- [ ] Placeholder audio files present and play correctly in a basic audio test scene.

## Security considerations
- Ensure audio assets do not allow arbitrary code execution; validate file types and sizes.

## Performance targets
- Music crossfades must not cause audio hitches; target <50ms for bus switching.
- Keep SFX pool sizes limited (max concurrent SFX 32) to avoid audio saturation.

## UX notes
- Growth chimes and ready cues should be audible but not annoying; provide volume toggles and reduced audio option.
- Short lore bites should be skippable.

## Edge cases
- Missing audio should fallback to silent behavior and not block gameplay.
- Extremely long lore text should paginate in the UI.

## Data Contracts
- Audio manifest (res://config/audio/manifest.json) listing cue names and file paths.
- Lore text files under res://docs/lore/ with keys for UI integration.

## Integration points
- UI: seed growth cues and ready notifications.
- GameLoopManager: growth and expedition audio triggers.

## QA test plan
- Audio playback tests for each cue.
- Narrative QA: verify lore entries are referenced correctly and localized.

## Metrics
- Audio asset load times.
- Number of lore entries displayed in tutorial and their read rates.

## Rollback criteria
- If audio assets or lore direction conflict with brand or cause technical issues, revert to placeholder assets and lock content until approved.

## Dependencies
- Depends on Task 1; consumers: Task 12 and narrative integration.

## Complexity estimate
- Fibonacci: 5 pts (Foundation)

