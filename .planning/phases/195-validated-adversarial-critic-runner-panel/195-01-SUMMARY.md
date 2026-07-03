---
phase: 195-validated-adversarial-critic-runner-panel
plan: "01"
subsystem: critic-runner-build-spine
tags:
  - critic-runner
  - mix-aliases
  - e2e-toolchain
  - trust-gate
  - skeleton
dependency_graph:
  requires: []
  provides:
    - verify.ui_critique (local-only, RUNNER-04)
    - verify.critic_trust (ci.all, CRITIC-03)
    - e2e/critic toolchain (devDependencies)
    - critic_trust block in design-system-ledger.json
    - golden-set.json skeleton
    - critic_trust_test.exs (pure-Elixir, green)
  affects:
    - mix.exs (aliases + preferred_envs + ci.all)
    - CONTRIBUTING.md (doc-contract lock)
    - .gitignore (critic-scores/ + verdict-cache)
    - .planning/design-system-ledger.json
tech_stack:
  added:
    - "@anthropic-ai/sdk ^0.110.0 (e2e devDependency only — RUNNER-05)"
    - "tsx ^4.19.2 (e2e devDependency — TS runner for critic CLI)"
    - "typescript ^5.7.3 (e2e devDependency)"
    - "zod ^3.24.2 (e2e devDependency)"
  patterns:
    - "Local-only mix alias with env-var no-op (mirrors verify.flake precedent)"
    - "Pure-Elixir ci.all trust gate (mirrors verify.mechanical precedent)"
    - "Committed skeleton JSON with validated:false lenses (ratchet-safe seed)"
key_files:
  created:
    - examples/threadline_phoenix/e2e/tsconfig.json
    - test/threadline/operator_surface/critic_trust_test.exs
    - .planning/golden/golden-set.json
    - .planning/golden/rounds/.gitkeep
    - .planning/critic-scores/.gitkeep
  modified:
    - examples/threadline_phoenix/e2e/package.json
    - examples/threadline_phoenix/e2e/package-lock.json
    - .gitignore
    - mix.exs
    - CONTRIBUTING.md
    - .planning/design-system-ledger.json
    - test/threadline/operator_surface/stress_ledger_test.exs
decisions:
  - "verify.ui_critique is local-only (excludes from ci.all) matching verify.flake precedent; exits 0 with skip message when ANTHROPIC_API_KEY is absent (RUNNER-04)"
  - "verify.critic_trust is pure-Elixir in ci.all before verify.mechanical (fast, no LLM, fail-fast)"
  - "All 6 critic lenses seed validated:false; trust bar checks vacuously pass on empty skeleton until Plan 04 promotes them"
  - "critic-scores/ tree is gitignored (nondeterministic LLM output); .gitkeep tracks dir structure"
  - ".planning/golden/ is NOT gitignored (committed oracle)"
metrics:
  duration: "4m"
  completed_date: "2026-07-03"
  tasks: 3
  files_modified: 11
status: complete
---

# Phase 195 Plan 01: Build Spine and Named Entrypoints Summary

Critic runner build spine, named entrypoints, and committed skeletons for the whole Phase 195. The foundation is green and self-consistent: `ci.all` is green, the local-only no-op contract is proven, and the no-root-dependency invariant is maintained.

## What Was Built

**Build spine:** Added `@anthropic-ai/sdk`, `zod`, `typescript`, and `tsx` to `examples/threadline_phoenix/e2e/package.json` as devDependencies (never in root `mix.exs`). Created `tsconfig.json` for the ESM Node critic CLI project. Added four `critic:*` npm scripts (`score`, `validate`, `label`, `rubric`) that invoke `tsx critic/run.ts` — these script names exist now so `verify.ui_critique` can reference them; `run.ts` itself lands in Plan 05.

**Named entrypoints:** Added two mix aliases to `mix.exs`:
- `verify.critic_trust` — pure-Elixir single-file test (CRITIC-03 trust gate), added to `ci.all` before `verify.mechanical` (fail-fast, no LLM, no network)
- `verify.ui_critique` — local-only adversarial critic runner, excluded from `ci.all`; exits 0 with a skip message when `ANTHROPIC_API_KEY` is absent (RUNNER-04 no-op)

**Committed skeletons:** Added `critic_trust` block to `design-system-ledger.json` with 6 frozen lenses (all `validated:false`). Created `golden-set.json` empty skeleton, `golden/rounds/.gitkeep`, and `critic-scores/.gitkeep`. Updated `.gitignore` to exclude `critic-scores/*` (nondeterministic LLM output) and `critic-verdict-cache/` while keeping `.gitkeep` tracked.

**Trust guard:** Created `test/threadline/operator_surface/critic_trust_test.exs` — pure-Elixir, `async: true`, 9 tests all green. Asserts: `critic_trust` block shape, 6 frozen lenses, required field set per lens, statistical trust bar (vacuously passes with all `validated:false`), golden-set.json structure, scorecard/critic-scores separation, CRITIQUE.md forbidden terms (File.exists? guard for absence). TODO markers left for Plan 04/07.

**Doc-contract lock:** Added "Local-only critic (verify.ui_critique)" section to CONTRIBUTING.md (mirrors "Deterministic tests" verify.flake note) as the committed doc-contract target.

## Deviations from Plan

### Auto-fixed Issues

None.

### Minor Adjustments

**1. [Rule 1 - Bug] Removed unused helpers from critic_trust_test.exs**
- **Found during:** Task 3 verification
- **Issue:** Initial draft included `sorted_keys/1` and `_sorted_keys/1` helpers that caused compiler warnings (`function is unused`) which would fail `mix compile --warnings-as-errors` in `ci.all`
- **Fix:** Removed both unused helpers; all test logic uses only `ledger/0` and `golden_set/0`
- **Files modified:** `test/threadline/operator_surface/critic_trust_test.exs`
- **Commit:** f2ca21f4

## Verification Results

- `ANTHROPIC_API_KEY="" mix verify.ui_critique` exits 0 with skip message (RUNNER-04 no-op confirmed)
- `mix verify.compile_no_optional` green — root threadline gains no runtime dependency (RUNNER-05 confirmed)
- `mix verify.critic_trust` green — 9 tests, 0 failures
- `mix test test/threadline/operator_surface/stress_ledger_test.exs` green — 16 tests, 0 failures (critic_trust added to @top_level_keys)
- `mix compile --warnings-as-errors` clean
- `@anthropic-ai/sdk`, `zod`, `typescript`, `tsx` present in e2e devDependencies only (no runtime dependencies block)

## Known Stubs

- `critic/run.ts` is referenced by the `critic:*` npm scripts but does not exist yet — lands in Plan 05. The scripts are declared now so `verify.ui_critique` can reference them without the file needing to exist (the alias only shells out when `ANTHROPIC_API_KEY` is set).
- `CRITIQUE.md` does not exist yet — lands in Plan 07 when `report.ts` generates it. The freshness guard in `critic_trust_test.exs` uses `File.exists?` so absence is a vacuous pass.
- All 6 critic lenses have `validated: false` — promoted by Plan 04 when the real Krippendorff α gate lands.

## Threat Flags

None. All threat mitigations from the plan's threat register are implemented:
- T-195-01 (ANTHROPIC_API_KEY disclosure): key read from env only; alias no-ops when absent; `.planning/critic-scores/` gitignored; no key value in any committed file
- T-195-02 (critic_trust tamper): `verify.critic_trust` in `ci.all`; all lenses seed `validated:false`
- T-195-03 (root dependency surface): SDK is e2e devDependency only; `verify.compile_no_optional` green

## Self-Check: PASSED

Files exist:
- FOUND: examples/threadline_phoenix/e2e/tsconfig.json
- FOUND: test/threadline/operator_surface/critic_trust_test.exs
- FOUND: .planning/golden/golden-set.json
- FOUND: .planning/golden/rounds/.gitkeep
- FOUND: .planning/critic-scores/.gitkeep

Commits exist:
- a018fc58: feat(195-01): add critic toolchain to e2e devDependencies + tsconfig + gitignore
- 04bb6b5e: feat(195-01): add verify.ui_critique (local-only) and verify.critic_trust (ci.all) mix aliases
- f2ca21f4: feat(195-01): seed critic_trust skeleton, golden-set.json, and green pure-Elixir guard stub
