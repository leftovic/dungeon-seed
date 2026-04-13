# Game Dev Workflow Pipelines

> **Auto-generated from** `workflow-pipelines.json` — do not edit directly
> **Schema:** game-dev-workflow-pipelines-v2
> **Total Pipelines:** 9

---
## Core Game Loop

> **ID:** `pipeline-1-core-game-loop` | **Layout:** sequential
> The main pipeline from pitch to ship

| Step | Agent | Consumes | Produces | Notes |
|------|-------|----------|----------|-------|
| 1 | **game vision architect** | game-pitch | GDD.md |  |
| 2 | **narrative designer** | GDD.md | lore-bible.md, character-bible.md |  |
| 3 | **character designer** | GDD.md, character-bible.md | character-sheets.json |  |
| 4 | **world cartographer** | GDD.md, lore-bible.md | world-map.json, biome-definitions.json |  |
| 5 | **game economist** | GDD.md, character-sheets.json | economy-model.json |  |
| 6 | **game art director** | GDD.md | style-guide.md |  |
| 7 | **game audio director** | GDD.md, biome-definitions.json | music-direction.md |  |
| 8 | **the decomposer** | GDD.md, all-bibles | decomposition.md |  |
| 9 | **the aggregator** | decomposition.md | master-task-matrix.json |  |
| 10 | **game ticket writer** | decomposition.md | tickets/ | 4-pass blind pipeline |
| 11 | **implementation plan builder** | tickets/ | plans/ |  |
| 12 | **game code executor** | plans/ | source-code |  |
| 13 | **playtest simulator** | game-build | playtest-report.json |  |
| 14 | **balance auditor** | playtest-report.json | balance-report.md |  |
| 14.5 | **game analytics designer** | playtest-report.json, balance-report.md, economy-model.json, source-code | analytics/EVENT-TAXONOMY.json, analytics/sdk/Analytics.gd, analytics/dashboards/, analytics/ANALYTICS-HEALTH-REPORT.md, analytics/PRIVACY-COMPLIANCE-AUDIT.md | telemetry instrumentation, dashboards, retention models, A/B framework, privacy compliance |
| 15 | **game build packaging specialist** | source-code, BUILD-MATRIX.md, PERFORMANCE-BUDGET.md, playtest-report.json, balance-report.md | BUILD-MANIFEST.json, builds/, ci/, PLATFORM-CERTIFICATION-CHECKLIST.md, BUILD-VALIDATION-REPORT.md | cross-platform export, packaging, CI/CD, store cert |
| 15.5 | **store submission specialist** | BUILD-MANIFEST.json, builds/, economy-model.json, screenshots/, trailers/, EULA.md, PRIVACY-POLICY.md | STORE-READINESS-SCORECARD.md, SUBMISSION-CHECKLIST.md, PRICING-MATRIX.json, RATING-PORTFOLIO.json, CROSS-STORE-CONSISTENCY.md, store-submissions/ | multi-platform store submission — Steam, Epic, itch.io, GOG, iOS, Android, console |
| 16 | **live ops designer** | economy-model.json, BUILD-MANIFEST.json | content-calendar.md |  |
| 17 | **patch update manager** | BUILD-MANIFEST.json, source-code, economy-model.json, content-calendar.md, SAVE-SCHEMA.json, MOD-API-REGISTRY.json | PATCH-MANIFEST.json, patches/, migrations/, CHANGELOG.md, ROLLBACK-PLAYBOOK.md, VERSION-HISTORY.json, UPDATE-HEALTH.md | post-launch: delta patches, save migration, hotfixes, DLC packaging, staged rollouts |

---

## Narrative Pipeline

> **ID:** `pipeline-2-narrative` | **Layout:** mixed
> Story, characters, quests, dialogue

| Step | Agent | Consumes | Produces | Notes |
|------|-------|----------|----------|-------|
| 1 | **narrative designer** | — | lore-bible.md |  |
| 2 | **character designer** | — | character-sheets.json |  |
| 3 | **dialogue engine builder** | — | dialogue-system |  |
| 4 | **game economist** | — | quest-rewards.json | quest reward calibration |

---

## Art Pipeline

> **ID:** `pipeline-3-art` | **Layout:** sequential
> Visual assets from style guide to scene

| Step | Agent | Consumes | Produces | Notes |
|------|-------|----------|----------|-------|
| 1 | **game art director** | — | style-guide.md |  |
| 2 | **procedural asset generator** | — | assets/ |  |
| 2.5 | **architecture interior sculptor** | style-guide.md, ASSET-MANIFEST.json, biome-definitions.json, building-briefs/ | building-kits/, interiors/, ARCHITECTURE-MANIFEST.json | parallel with asset-gen — building kits + furnished interiors |
| 3 | **beast creature sculptor** | style-guide.md, color-palette.json, enemy-bestiary.json, companion-profiles.json, fauna-tables.json, hitbox-configs.json | creature-models/, creature-rigs/, creature-sprites/, CREATURE-MANIFEST.json |  |
| 4 | **sprite animation generator** | ASSET-MANIFEST.json, CREATURE-MANIFEST.json, style-guide.md, hitbox-configs.json | spritesheets/, ANIMATION-MANIFEST.json, *.tres |  |
| 5 | **vfx designer** | style-guide.md, color-palette.json, combo-system.json, frame-data.json, CREATURE-MANIFEST.json | effects/, shaders/, VFX-MANIFEST.json |  |
| 6 | **ui hud builder** | style-guide.md, color-palette.json, ui-design-system.md, economy-model.json, dialogue-data-schema.json, 05-needs-system.json | ui/themes/game-theme.tres, ui/hud/, ui/menus/, UI-MANIFEST.json, UI-ACCESSIBILITY-REPORT.md |  |
| 7 | **scene compositor** | — | scenes/ |  |
| 7.5 | **cinematic director** | scenes/, style-guide.md, music-sync-cues.json, character-sheets.json, screenplay-scripts | cutscenes/, shot-lists/, storyboards/, camera-paths/, trailers/, CINEMATIC-MANIFEST.json, CINEMATIC-BUDGET-REPORT.md | cutscene choreography, trailers, cinematic transitions |
| 8 | **game art director** | — | art-audit-report.md | audit mode |

---

## Audio Pipeline

> **ID:** `pipeline-4-audio` | **Layout:** sequential
> Music, SFX, ambient soundscapes

| Step | Agent | Consumes | Produces | Notes |
|------|-------|----------|----------|-------|
| 1 | **game audio director** | — | sound-design-doc.md |  |
| 2 | **audio composer** | — | music/, sfx/, ambience/ |  |
| 3 | **game audio director** | — | audio-audit-report.md | audit mode |

---

## World Pipeline

> **ID:** `pipeline-5-world` | **Layout:** sequential
> Maps, biomes, procedural generation, ecosystems

| Step | Agent | Consumes | Produces | Notes |
|------|-------|----------|----------|-------|
| 1 | **world cartographer** | — | world-map.json, biome-definitions.json |  |
| 1.5 | **terrain environment sculptor** | world-map.json, biome-definitions.json, style-guide.md | heightmaps/, biome-splatmaps/, skybox/, weather-configs/ | Heightmaps, erosion, biome painting, skyboxes, weather particles, caves |
| 2 | **procedural asset generator** | — | biome-assets/ |  |
| 2.5 | **architecture interior sculptor** | biome-definitions.json, world-map.json, ASSET-MANIFEST.json, building-briefs/, dungeon-blueprints.json | building-kits/, dungeon-room-kits/, ARCHITECTURE-MANIFEST.json | settlement buildings + dungeon interiors for world population |
| 3 | **tilemap level designer** | world-map.json, biome-definitions.json, biome-assets/, ASSET-MANIFEST.json, ARCHITECTURE-MANIFEST.json, drop-tables.json | tilemaps/, spawn-data/, LEVEL-MANIFEST.json | procedural tilemap generation from zone specs + tile assets + building kits |
| 4 | **scene compositor** | tilemaps/, spawn-data/ | populated-scenes/ |  |
| 5 | **ai behavior designer** | spawn-data/ | ecosystem-sim-config.json |  |

---

## Economy & Balance Pipeline

> **ID:** `pipeline-6-economy-balance` | **Layout:** mixed
> Economy design, balance testing, convergence

| Step | Agent | Consumes | Produces | Notes |
|------|-------|----------|----------|-------|
| 1 | **game economist** | — | economy-model.json |  |
| 2 | **combat system builder** | — | damage-formulas.json |  |
| 3 | **balance auditor** | — | balance-report.md |  |
| 4 | **playtest simulator** | — | playtest-report.json |  |
| 5 | **game economist** | — | rebalanced-economy.json | fix pass |

---

## Distribution & Live Ops

> **ID:** `pipeline-7-distribution` | **Layout:** sequential
> Getting the game from 'it works' to 'it's on Steam' and keeping it alive post-launch

| Step | Agent | Consumes | Produces | Notes |
|------|-------|----------|----------|-------|
| 1 | **game build packaging specialist** | source-code, game-project | BUILD-MANIFEST.json, builds/ | Cross-platform builds: Win/Mac/Linux/Web/Android/iOS/Console |
| 2 | **demo showcase builder** | game-build | trailers/, press-kit/, screenshots/ | Marketing assets, store page materials |
| 3 | **localization manager** | source-code, dialogue-trees | translations/, locale-configs/ | i18n string extraction, translation coordination |
| 4 | **compliance officer** | game-build | RATING-PORTFOLIO.json, LEGAL-COMPLIANCE.md | ESRB/PEGI ratings, loot box regs, COPPA, GDPR |
| 5 | **store submission specialist** | builds/, trailers/, screenshots/, RATING-PORTFOLIO.json | store-submissions/, STORE-READINESS.md | Steam, Epic, itch.io, App Store, Play Store, console stores |
| 6 | **release manager** | builds/, store-submissions/ | RELEASE-NOTES.md, CHANGELOG.md | Launch coordination, go/no-go gates |
| 7 | **deployment strategist** | builds/ | infra-configs/, CDN-setup/ | Game servers, CDN, auto-scaling |
| 8 | **game analytics designer** | source-code | analytics/, dashboards/ | Telemetry, retention metrics, A/B testing |
| 9 | **live ops designer** | economy-model.json, game-build | content-calendar.md, season-pass/ | Season passes, events, battle pass |
| 10 | **patch update manager** | source-code, builds/ | patches/, CHANGELOG.md | Delta patches, save migration, hotfixes, DLC |
| 11 | **cost optimizer** | infra-configs/, analytics/ | COST-ANALYSIS.md | Hosting costs, CDN, server scaling optimization |
| 12 | **customer feedback synthesizer** | analytics/ | FEEDBACK-REPORT.md | Steam reviews, Discord, social media → actionable insights |
| 13 | **incident response planner** | infra-configs/ | RUNBOOKS.md, ESCALATION-MATRIX.md | Server outage, exploit, PR crisis response |

---

## Camera & Cinematics

> **ID:** `pipeline-8-camera-cinematics` | **Layout:** sequential
> Camera systems, cutscenes, and cinematic storytelling

| Step | Agent | Consumes | Produces | Notes |
|------|-------|----------|----------|-------|
| 1 | **camera system architect** | GDD.md, game-architecture | camera-configs/, CameraRig.gd | Follow cam, collision, VR comfort, screen shake |
| 2 | **cinematic director** | lore-bible.md, camera-configs/, character-sheets.json | cutscenes/, trailers/, storyboards/ | Shot composition, cutscene choreography, trailer assembly |

---

## Game Trope Addons (Optional Modules)

> **ID:** `pipeline-9-trope-addons` | **Layout:** parallel
> Pick which game features your game needs — each is independently activatable

| Step | Agent | Consumes | Produces | Notes |
|------|-------|----------|----------|-------|
| 1 | **crafting system builder** | economy-model.json | crafting/ | OPTIONAL: Recipes, workbenches, quality tiers |
| 1 | **housing base building designer** | architecture-assets | housing/ | OPTIONAL: Player housing, furniture, defense |
| 1 | **farming harvest specialist** | economy-model.json, weather-system | farming/ | OPTIONAL: Crops, seasons, livestock |
| 1 | **fishing system designer** | aquatic-assets, economy-model.json | fishing/ | OPTIONAL: Cast/reel minigame, 200+ fish species |
| 1 | **cooking alchemy system builder** | economy-model.json | cooking/ | OPTIONAL: Ingredient experimentation, buff potions |
| 1 | **mount vehicle system builder** | creature-assets, camera-configs/ | mounts/ | OPTIONAL: Riding, flying, racing |
| 1 | **guild social system builder** | multiplayer-system | guilds/ | OPTIONAL: Clans, ranks, shared storage |
| 1 | **achievement trophy system builder** | game-events | achievements/ | OPTIONAL: Platform trophies, completion tracking |
| 1 | **relationship romance builder** | dialogue-trees, character-sheets.json | relationships/ | OPTIONAL: NPC affinity, dating, marriage |
| 1 | **weather daynight cycle designer** | biome-definitions.json | weather/, day-night/ | OPTIONAL: Dynamic weather, seasonal changes, NPC schedules |
| 1 | **photo mode designer** | camera-configs/ | photo-mode/ | OPTIONAL: Free camera, filters, poses, sharing |
| 1 | **character customization builder** | humanoid-assets | customization/ | OPTIONAL: Character creator, transmog, dyes |
| 1 | **survival mechanics designer** | weather-system, economy-model.json | survival/ | OPTIONAL: Hunger, thirst, temperature, shelter |
| 1 | **taming breeding specialist** | creature-assets, economy-model.json | taming/ | OPTIONAL: Capture, genetics, breeding, evolution |
| 1 | **procedural quest generator** | world-map.json, economy-model.json | procedural-quests/ | OPTIONAL: Radiant quests, bounty boards |
| 1 | **trading economy builder** | economy-model.json | trading/ | OPTIONAL: Shops, auction house, player trading |
| 1 | **minigame framework builder** | game-code | minigames/ | OPTIONAL: Puzzle, rhythm, racing, card games |
| 1 | **pet companion system builder** | creature-assets, ai-behavior | pets/ | OPTIONAL: Pet bonding, evolution, companion AI |

---

*Source of truth: `workflow-pipelines.json`*

