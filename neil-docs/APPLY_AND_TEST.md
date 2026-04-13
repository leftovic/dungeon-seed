Apply and Test Guide

1. Prerequisites
   - Git installed locally
   - Godot (matching project version) installed locally and on PATH
   - Python 3 installed

2. Apply patches (per-task branches recommended)
   For each patch in neil-docs/impl-task-001.patch .. impl-task-012.patch:
     git checkout -b impl-task-00N
     git apply --stat neil-docs/impl-task-00N.patch
     git apply neil-docs/impl-task-00N.patch
     git add -A
     git commit -m "impl(task-00N): apply reconciled ticket changes"
     git push origin impl-task-00N
     Open PR from impl-task-00N

3. Run local scaffolding (optional)
   powershell -ExecutionPolicy Bypass -File .\create_stubs.ps1
   python .\tools\generate_vectors.py --seed 12345 --count 10 --out .\tests\fixtures\rng\seed-0001.json

4. Run headless tests locally
   "C:\Path\To\Godot\Godot.exe" --headless --path . --script res://tests/unit/test_runner.gd

5. CI Integration (high level)
   - Add Godot headless install step to CI image
   - Add HMAC_KEY secret to repository secrets (do not commit)
   - Ensure project.godot exists and test paths resolve

Notes
- Clean original stubs in src/gdscript/utils/ if you prefer a single authoritative implementation file.
- Do NOT commit production HMAC keys. Use KMS/secret manager integration.
