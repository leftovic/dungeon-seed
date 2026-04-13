CI Secrets required for Godot headless tests

Add these secrets to the repository (Settings -> Secrets & variables -> Actions):

- GODOT_CHECKSUM
  - Description: Optional. SHA256 checksum for the Godot headless binary file. If provided, the CI will verify the checksum after download.
  - How to generate: sha256sum Godot_v4.6.1-stable_linux_headless.64 | awk '{print $1}'

- HMAC_KEY
  - Description: Optional. HMAC key used for deterministic ID signing (if moving from pure SHA to HMAC in production). Store as base64 or hex per your policy.
  - How to use: The application should read the key from env var or Actions secret and use it for HMAC-SHA256 when generating production IDs.

- GODOT_CACHE_TOKEN (optional)
  - Description: If you use a private cache or mirror for Godot binaries, put credentials here and update the workflow to use them.

Notes:
- Keep HMAC_KEY secret; rotate periodically and add key-rotation docs before changing production behavior.
- If GODOT_CHECKSUM is not provided, CI will skip checksum verification (still download and run). Recommended to supply checksum for security.
