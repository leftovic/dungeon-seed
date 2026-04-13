# Task 005 — Define audio and lore foundation
Short description
- Establish audio palette, lore bibles, and minimal audio hooks for planting/growth/harvest events.

Acceptance criteria
- [ ] `game/audio/audio_manifest.json` with named cues for plant/grow/dispatch/explore/loot
- [ ] Lore bible `neil-docs/epics/dungeon-seed/lore.md` with core world pillars and Seedwarden hook
- [ ] Sample SFX stubs integrated with events and verified in headless test (no audio output required, event emission only)

Phased implementation
- Phase 0: Lore & audio manifest
  - [ ] Create lore.md and audio_manifest.json
- Phase 1: Event hook integration
  - [ ] Implement `AudioManager.gd` with `play_cue(name)`
  - Tests: AudioCue_Emitted_On_PlantEvent (verify event emitted)
- Phase 2: Placeholder assets & integration
  - [ ] Add placeholder .wav files (small, CC0 or generated)
  - CI: asset quality and size check

Dependencies
- Task 1 (project), Task 4 (UI)

Deliverables & artifacts
- neil-docs/epics/dungeon-seed/lore.md
- game/audio/audio_manifest.json
- game/scripts/AudioManager.gd
- test/audio/AudioTests.gd

Estimated complexity & risks
- Complexity: 5 points
- Risk: Asset licensing — ensure CC0 or internal assets only.

Deterministic ID & RNG guidance
- Not applicable.

TODOs for Game Code Executor
- Implement AudioManager.gd and event stubs; expected outputs are event logs in `artifacts/audio-events.log`.

CI checks
- Secret scan for licensed assets
- Asset size limits
