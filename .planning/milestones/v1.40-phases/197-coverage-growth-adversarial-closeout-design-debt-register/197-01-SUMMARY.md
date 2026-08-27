---
phase: 197-coverage-growth-adversarial-closeout-design-debt-register
plan: 01
subsystem: e2e-critic-tooling
tags: [verdict-cache, forward-only-gate, before-pole, oq-3, proof-02]
requires: []
provides:
  - screenshot-keyed verdict cache (5-part key, sha8 of PNG bytes)
  - before-pole overwrite guard in critic:score (guardBeforePole, --fresh-before escape)
affects:
  - 197-02..04 paid gate iterations (before/after evidence can no longer be silently faked)
tech-stack:
  added: []
  patterns:
    - cache-key auto-invalidation extended (rubric_hash idiom replicated for screenshot_hash)
    - VOID-with-instruction refusal message (gate.ts house style copied to score command)
key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/critic/cache.ts
    - examples/threadline_phoenix/e2e/critic/gate.ts
    - examples/threadline_phoenix/e2e/critic/run.ts
    - examples/threadline_phoenix/e2e/critic/panel.ts
decisions:
  - "Before-pole guard exempts --golden/--synthetic and refute.* runs so mix critic.measure (divergence step 4) keeps working — the guard protects gate poles only"
  - "Guard uses existing score files as the stamp (no separate .pole-stamp sentinel file) — the pole's presence IS the stamp; simpler and cannot drift"
  - "CONTRIBUTING runbook left unchanged: it never documented a manual cache-bust rm step, and its score→edit→gate sequencing already matches the new guard; the memory-level manual rm stays as belt-and-braces for one more phase"
metrics:
  duration: ~15 min
  completed: 2026-08-26
status: complete
actuals:
  tokens: 4048
  tasks: 2
  commits: 1
---

# Phase 197 Plan 01: Loop-Measurement Hardening Summary

Screenshot-sha8-keyed verdict cache + before-pole overwrite guard close both 196-06 measurement defects, proven by a full gate dry-run (exit 0, 7/7 pipeline steps) and behavioral refusal/escape tests.

## Task Commits

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (tracer) | Screenshot-keyed cache + before-pole guard, proven by gate dry-run | 4fd68cea | cache.ts, gate.ts, run.ts, panel.ts |
| 2 | Regression sweep — deterministic guards and repo hygiene unaffected | (no file changes — verification only) | — |

## What Was Built

**Debt #1 — screenshot-keyed cache (T-197-01, cache.ts):**
- `cacheKey` extended to a 5-part `__`-joined key: `{cell_id}__{dimension}__{rubric_hash}__{model_id}__{screenshot_hash}` — exactly the rubric_hash auto-invalidation idiom, now applied to the PNG bytes.
- New exported helper `sha8OfFile(path)` (first 8 hex chars of sha256 over file bytes).
- `CachedVerdict` gains `screenshot_hash`; `lookupCache`/`writeCache` signatures thread it through.
- Old 4-part entries simply MISS under the new key (different filename); the existing corrupt-entry degrade-to-miss path needed no migration code.
- Callers updated: `run.ts` computes a per-cell sha8 from the scorecard's `artifacts.screenshot` (null → cache bypassed, real error surfaces via `loadBundle`); `panel.ts` computes it from the already-loaded bundle.

**Debt #2 — before-pole overwrite guard (T-197-02, gate.ts + run.ts):**
- `guardBeforePole(pairs, freshBefore)` exported from gate.ts: an existing `.planning/critic-scores/<cell>/<lens>/` pole with score files blocks a plain `critic:score` run.
- Refusal message copies the gate's VOID-with-instruction house style: names the cell/lens, states the pole exists, and names `npm run critic:gate -- --page <page> --lens <lens>` as the ONLY post-edit scoring command.
- `--fresh-before` flag deliberately deletes the old pole to start a brand-new iteration (documented in the CLI usage text).
- Exemptions: `--golden`/`--synthetic` oracle runs and `refute.*` cells — trust measurement (`mix critic.measure`, the gate's own divergence step) is not a gate pole and must keep re-scoring freely.
- The gate's existing missing-before VOID path (`rankReeval`) is untouched.

## Verification Evidence

- `npm run critic:gate -- --page route.actor --lens density --dry-run` → exit 0, all 7 pipeline steps printed, no key required (run twice: pre-commit and as the tracer feedback gate post-commit).
- Behavioral: writeCache + lookupCache with same hash → HIT; with a different (re-captured) hash → MISS.
- Behavioral: fake pole under `page.actor.happy__dark-1280/density` → `critic:score` REFUSED (exit 1) with the gate-only instruction; `guardBeforePole(..., true)` deleted the pole (`cleared: ["page.actor.happy__dark-1280/density"]`). All test artifacts removed.
- `npx tsc --noEmit -p .` clean (e2e tsconfig).
- `mix verify.mechanical` — 18 tests, 0 failures.
- `mix verify.critic_trust` — 22 tests, 0 failures.
- `mix verify.doc_contract` — 130 tests, 1 failure: the pre-existing V123Charter baseline (PROJECT.md milestone-framing assertion, tracked since 195-10; PATTERNS §Verification cadence explicitly carries this baseline). Not introduced or touched by this plan (commit diff is 4 e2e TS files only).
- `mix compile --warnings-as-errors` + `mix format --check-formatted` — clean.
- `git status --porcelain .planning/scorecards .planning/design-system-ledger.json` — empty (no floor/ledger/scorecard drift).
- `git diff --name-only HEAD~1` — only the 4 e2e critic TS files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] panel.ts cache call sites updated (file not in plan's files_modified)**
- **Found during:** Task 1
- **Issue:** `panel.ts` is the third `lookupCache`/`writeCache` caller; leaving it on the 4-arg signature would break the typecheck and produce `undefined`-keyed cache entries at runtime.
- **Fix:** compute `sha8OfFile(resolve(bundle.repoRoot, bundle.scorecard.artifacts.screenshot))` in `scoreOneDimension` and thread it through both call sites — same pattern as run.ts. (The plan's own action text says "update every caller".)
- **Files modified:** examples/threadline_phoenix/e2e/critic/panel.ts
- **Commit:** 4fd68cea

**2. [Rule 3 - Blocking] Worktree dependency install**
- **Found during:** Task 1 verify / Task 2
- **Issue:** the fresh worktree had no `node_modules` (e2e) and no fetched hex deps, so the dry-run and `mix verify.*` could not run.
- **Fix:** `npm ci` (lockfile-only, zero new packages — matches threat register T-197-03 "zero packages added") and `mix deps.get`. No lockfile or mix.lock changes.

### Documented Non-Change

- **CONTRIBUTING.md runbook left as-is (Task 2 decision):** the "Forward-only gate — run one iteration" runbook never documented the manual `rm .planning/critic-verdict-cache/...` cache-bust, and its step sequencing (score before edit → gate after edit) already describes exactly what the new guard now enforces. Per the plan's stated preference, the memory-level manual cache-bust habit stays as belt-and-braces for one more phase. No doc change → no `forward_only_gate_doc_contract_test.exs` lockstep change.

## Known Baseline (pre-existing, not owned by this plan)

- `mix verify.doc_contract`: 1 failing V123Charter assertion (PROJECT.md milestone framing) — part of the 3-module doc-contract baseline (V123Charter/FormlessPages/Phase06Nyquist) tracked since 195-10. Phase-gate expectation per 197-PATTERNS is "green except the pre-existing 3-module baseline".

## Known Stubs

None — no stubs, placeholders, or unwired data paths introduced.

## Threat Flags

None — no new surface beyond the plan's threat model; both `mitigate` dispositions (T-197-01, T-197-02) are implemented in commit 4fd68cea.

## Self-Check: PASSED

- examples/threadline_phoenix/e2e/critic/cache.ts — FOUND
- examples/threadline_phoenix/e2e/critic/gate.ts — FOUND
- examples/threadline_phoenix/e2e/critic/run.ts — FOUND
- examples/threadline_phoenix/e2e/critic/panel.ts — FOUND
- Commit 4fd68cea — FOUND in git log
