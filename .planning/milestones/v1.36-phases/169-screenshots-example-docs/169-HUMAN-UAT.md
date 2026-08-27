---
status: partial
phase: 169-screenshots-example-docs
source: [169-VERIFICATION.md]
started: 2026-06-14T00:00:00Z
updated: 2026-06-14T00:00:00Z
audit_acknowledged:
  milestone: v1.40
  at: 2026-08-27
  gap_snapshot: "partial::scenarios=1"
---

## Current Test

[awaiting human testing]

## Tests

### 1. Light-lane durable PNG emission (local-only, CI-skipped)

expected: Running `mix verify.example_browser_light` against the seeded demo app emits 12 `*__light__*1280*.png` durable screenshots (one per durable screen) plus the 5 light regression baselines auto-namespaced under `desktop-chromium-light`. The dark `__default__` baselines remain unchanged.
why_human: Requires a running seeded Phoenix demo app + Playwright browser render; the visual lane is local-only by design (CI-skipped per cf0e8e2), so only the wiring — not the rendered pixels — is statically verifiable. The wiring is fully verified in 169-VERIFICATION.md.
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
