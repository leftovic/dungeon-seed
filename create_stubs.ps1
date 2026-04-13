# create_stubs.ps1 - run from repo root (Windows)
# Creates scaffold directories and placeholder files for MUST-FIX items.
# IMPORTANT: This script creates placeholders only. Populate real code and never commit secrets.

$dirs = @(
  "src\gdscript\utils",
  "src\core\identity",
  "src\core\rng",
  "src\Generators\Export",
  "src\Gateway\Telemetry",
  "tests\fixtures\rng",
  "tests\fixtures\id",
  "tests\fixtures\preview_mode",
  "tests\unit",
  "tests\integration",
  "tests\fixtures\keys",
  "neil-docs\schemas\task-002",
  "neil-docs\telemetry\schemas",
  "neil-docs\tickets",
  "neil-docs\config",
  "neil-docs\security",
  "neil-docs\telemetry\runbooks",
  "build\scripts",
  "build\manifests",
  "ci\workflows",
  "scripts\migrations",
  "tools\validation\reachability_harness",
  "artifacts\reports"
)
foreach ($d in $dirs) { if (-not (Test-Path -Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

$files = @{
  "src\gdscript\utils\deterministic_id.gd" = "# deterministic_id.gd - placeholder\n# Implement UUIDv5 + HMAC fallback here\n";
  "src\gdscript\utils\rng_wrapper.gd" = "# rng_wrapper.gd - placeholder\n# Implement seeded RNG wrapper here\n";
  "src\core\identity\DeterministicId.txt" = "Deterministic ID module placeholder";
  "src\core\rng\rng_wrapper.txt" = "RNG wrapper placeholder";
  "src\Generators\Export\DungeonJsonExporter.txt" = "Exporter placeholder";
  "src\Gateway\Telemetry\DeterministicId.txt" = "Telemetry deterministic id placeholder";
  "tests\fixtures\rng\seed-0001.json" = '{"seed":12345,"expected_sequence":[]}' ;
  "tests\fixtures\id\test-vector-uuidv5-1.json" = '{"namespace":"00000000-0000-0000-0000-000000000000","name":"entity:sample"}';
  "tests\fixtures\preview_mode\preview_vectors.json" = "{}";
  "tests\fixtures\keys\dev_hmac_key.pem" = "-----BEGIN TEST KEY-----\nTEST-KEY\n-----END TEST KEY-----";
  "tests\unit\test_deterministic_id.gd" = "# unit test placeholder for deterministic id\n";
  "tests\unit\test_rng_vectors.gd" = "# unit test placeholder for rng vectors\n";
  "neil-docs\schemas\task-002\save-manifest.schema.json" = "{}";
  "neil-docs\config\ID_NAMESPACE_UUID.txt" = "00000000-0000-0000-0000-000000000000";
  "neil-docs\security\HMAC-KEY-MIGRATION.md" = "# HMAC key migration notes - placeholder\n";
  "neil-docs\telemetry\event-taxonomy.md" = "# Event taxonomy placeholder\n";
  "neil-docs\telemetry\schemas\gateway.login.success.schema.json" = "{}";
  "build\scripts\create_builds.ps1" = "# create_builds placeholder\n";
  "build\manifests\BUILD-MANIFEST.json" = "{}";
  "ci\workflows\godot-headless-tests.yml" = "# CI workflow stub\n";
  "scripts\migrations\migrate_hmac_keys.py" = "# migrate_hmac_keys placeholder\n";
  "tools\validation\reachability_harness\README.md" = "Reachability harness placeholder\n";
  "neil-docs\tickets\task-001-gtw-reconciled.md" = "# task-001 reconciled placeholder"
}

foreach ($path in $files.Keys) {
  $content = $files[$path]
  if (-not (Test-Path -Path (Split-Path -Path $path -Parent))) { New-Item -ItemType Directory -Path (Split-Path -Path $path -Parent) -Force | Out-Null }
  Set-Content -Path $path -Value $content -Force
}

Write-Host "Scaffold complete. Review files, populate real code/fixtures, and run tests/CI as documented."