---
status: partial
phase: 57-optional-deps-and-module-gating
source: [57-VERIFICATION.md]
started: 2026-05-06T15:30:00Z
updated: 2026-05-06T15:30:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. GitHub Actions CI green for verify-compile-no-optional
expected: After pushing the phase 57 commits to GitHub, the new `verify-compile-no-optional` job runs alongside the existing seven jobs (verify-format, verify-credo, verify-test, verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape) and shows green. Cite the run URL.
result: [pending]

### 2. (Discretionary) Hexdocs preview module-presence/absence
expected: With optional Phoenix/LV deps installed, `mix docs` renders `Threadline.OperatorSurface` in `doc/index.html` with the "since 0.4.0" badge. With LV absent (e.g., temporarily removing optional deps from the lockfile), the module is absent. The automated `verify.compile_no_optional` already proves the BEAM vanishes; this is a secondary visual check, marked discretionary in VALIDATION.md.
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
