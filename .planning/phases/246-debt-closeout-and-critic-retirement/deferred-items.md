# Phase 246 · Deferred items

Out-of-scope findings from plan executors. They are logged here rather than with
`windows append` so the WINDOWS ledger stays at `open_count: 0`.

## 246-07 · `operator-screenshot-regression.spec.ts:101` fails standalone (pre-existing)

- **Found during:** the 246-07 D-24 gate, standalone `mix verify.example_browser`.
- **Symptom:** "global chrome and Home workflow launchers stay stable" fails on desktop and
  mobile. The Home page's full-page screenshot height no longer matches `home.png`:

  | tree | desktop height | mobile height |
  |------|----------------|---------------|
  | committed baseline | 1281 px | 2013 px |
  | origin/main `23178fb0` | 1274 px | 2048 px |
  | v1.47 HEAD | 1407 px | 2412 px |

- **Not caused by phase 246:** it fails identically before the slices (`614cb1fd`) and on
  origin/main. The browser lane's standalone failure set is therefore 10, not 8: the four
  known screenshot pairs plus `:101` × 2.
- **Disposition:** routed to SEED-008, which owns the screenshot baselines (the same route as
  WINDOWS W14–W17 and W62). Never regenerate baselines outside that work. The route is
  recorded as register row `UI-HOME-SHOT-101` (`246-DEBT-REGISTER.md`) and in SEED-008
  Scope, which now owns the 10-failure threshold; gap-closure plan 246-09 added both after
  verification found the route missing at its destination. The measured standalone gate is
  419 passed / 10 failed / 58 skipped. This is a documented deviation from 246-07's
  8-failure expectation, evidenced by the origin/main `23178fb0` heights above, and not an
  override.
