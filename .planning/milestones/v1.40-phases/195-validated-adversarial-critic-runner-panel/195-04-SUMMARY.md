---
phase: 195-validated-adversarial-critic-runner-panel
plan: "04"
subsystem: critic_trust
tags: [krippendorff-alpha, inter-rater-agreement, trust-gate, rubric-hash, golden-set, pure-elixir]
dependency_graph:
  requires: [195-01, 195-02, 195-03]
  provides: [CRITIC-03, CRITIC-04]
  affects: [design-system-ledger.json, mix verify.critic_trust, ci.all]
tech_stack:
  added: [":crypto SHA-256 for rubric sha8 computation", "pure-Elixir Krippendorff alpha ordinal"]
  patterns: [TDD red-green, coincidence-matrix alpha formula, bootstrap CI, File.exists? vacuous guard]
key_files:
  created:
    - lib/threadline/critic_trust/krippendorff_alpha.ex
    - test/threadline/critic_trust/krippendorff_alpha_test.exs
  modified:
    - test/threadline/operator_surface/critic_trust_test.exs
decisions:
  - "[195-04-A] Krippendorff alpha computed via coincidence matrix (not correlation shortcut): Do/De
    with ordinal distance d²(v,v') = (range_sum - (n_lo+n_hi)/2)² — handles De=0, negative alpha,
    and insufficient data (<2 pairs) per RESEARCH Pattern 6 and PITFALL 7"
  - "[195-04-B] sha8 guard in critic_trust_test computes SHA-256 of raw rubric file bytes;
    normalised-content approach (placeholder substitution) enables self-consistent hashing
    when Plan-05 CLI stamps real hashes; vacuous while sha8=00000000"
  - "[195-04-C] bootstrap_ci/3 uses process RNG (seeded by caller) — no hidden seed in the
    module; tests seed with :rand.seed(:exsss, {42,0,0}) before each call for determinism"
metrics:
  duration: "11m"
  completed: "2026-07-03"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 5
  files_created: 2
status: complete
---

# Phase 195 Plan 04: Krippendorff Alpha Trust Gate Summary

Pure-Elixir Krippendorff's alpha (ordinal) module with bootstrap CI, plus the fully-expanded `verify.critic_trust` gate enforcing the per-lens trust bar, rubric-hash freshness, golden-set integrity, prefix-exemplar disjointness, and CRITIQUE.md freshness guards.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Krippendorff's alpha (ordinal) — TDD | `ddceb50d` | `lib/threadline/critic_trust/krippendorff_alpha.ex`, `test/threadline/critic_trust/krippendorff_alpha_test.exs` |
| 2 | Expand verify.critic_trust full gate | `cf0522c4` | `test/threadline/operator_surface/critic_trust_test.exs`, `mix.exs`, `lib/threadline/operator_surface/stress_fixtures.ex`, `test/threadline/operator_surface/refute_partition_test.exs` |

## What Was Built

### Task 1: Pure-Elixir Krippendorff's Alpha

`Threadline.CriticTrust.KrippendorffAlpha` implements the coincidence-matrix formulation of Krippendorff's alpha for two raters on ordinal data:

- **`compute/1`**: takes `[{r1_value, r2_value}]` pairs; builds the coincidence matrix; computes Do (observed) and De (expected) disagreement using the ordinal distance function `d²(v,v') = (range_sum - (n_lo+n_hi)/2)²`; returns `{:ok, alpha}` or `{:error, :insufficient_data}`.
- **`bootstrap_ci/3`**: resamples with replacement using the caller's seeded RNG, returns `{:ok, {lo, hi}}` at the 2.5th/97.5th percentiles.
- **Edge cases**: De=0 → `{:ok, 1.0}`; fewer than 2 pairs → `{:error, :insufficient_data}`; negative alpha returned as-is (never clamped — systematic-worse-than-chance is a valid signal, T-195-10).

10 TDD tests pass, including a known-value test (`-0.75` for 4 all-reversed pairs on a 3-point scale, verified by hand) and bootstrap determinism assertion.

### Task 2: Expanded verify.critic_trust

`critic_trust_test.exs` now contains 12 tests enforcing the full gate:

**Per-lens trust bar (expanded):**
- `alpha >= 0.67`, `n >= 20`, `raw_agreement >= 0.80`, `model_id == "claude-opus-4-8"` (all previously guarded)
- NEW: `golden_rubric_version` sha8 matches sha8 of current rubric disk bytes — auto-invalidation on rubric bump (T-195-11)

**Rubric-hash freshness guard (new):**
- Parses `<!-- lens: X | version: Y | sha8: H -->` header from each rubric
- When sha8 is a real hash (not `00000000` placeholder), verifies it equals sha8 computed from the normalised file content
- Vacuous while all rubrics have `sha8: 00000000` (Plan-05 CLI stamps real hashes)

**Held-out guard (new):**
- Asserts no `held_out_id` appears in golden-set `items`
- Held-out cells are the Phase-196 true-north slice; contamination would teach-to-the-test (FWD-2)

**Prefix-exemplar disjointness guard (new):**
- Parses pass-pole and fail-pole cell-ids from each rubric's `## Anchors` block
- Asserts pole cell-ids are disjoint from golden mid-range items and `held_out_ids` (T-195-12)
- Vacuous while golden-set is empty

**CRITIQUE.md freshness guard (new):**
- When `CRITIQUE.md` exists AND `.planning/critic-scores/` is non-empty, asserts one row per `(cell_id × persona)` is a substring
- Mirrors the `DESIGN-SYSTEM.md` freshness guard in `stress_ledger_test.exs`
- Vacuous until Plan-07 generates `CRITIQUE.md`

All 12 `verify.critic_trust` tests pass against current state (all lenses `validated:false`, empty golden-set, `00000000` placeholder sha8s). The gate will enforce the full bar as soon as any lens is validated.

## Verification Results

```
mix test test/threadline/critic_trust/krippendorff_alpha_test.exs
10 tests, 0 failures

mix verify.critic_trust
12 tests, 0 failures

mix verify.mechanical
18 tests, 0 failures
```

`mix ci.all` failures: the `verify.example` step fails on 8 pre-existing `demo_contract_test` failures related to the local PostgreSQL search_path environment issue (tracked in MEMORY.md as "~81 local mix test failures"). These failures exist on `main` before this plan and are not caused by any plan-04 changes.

## Deviations from Plan

**1. [Rule 3 - Format] Applied mix format to pre-existing files:**
- `lib/threadline/operator_surface/stress_fixtures.ex` — line-wrapping in tuple literal
- `mix.exs` — `IO.puts` line-wrapping
- `test/threadline/operator_surface/refute_partition_test.exs` — blank line additions

These were formatting drift introduced by the stash/unstash cycle during testing. All are whitespace-only changes with no logic impact.

**No other deviations.** Plan executed as designed.

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED: `test(195-04)` failing tests | N/A (module undefined = compilation RED) | PASS |
| GREEN: `feat(195-04)` implementation | `ddceb50d` | PASS |
| REFACTOR | Not needed | N/A |

## Known Stubs

None. All guards are correctly implemented. The guards are vacuous against the current committed state (validated:false, empty golden-set, 00000000 placeholder sha8s) — this is intentional and explicitly documented in each test.

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced. The rubric-hash guard and golden-set guards read `.planning/` and `examples/` files that are already in scope for the CI guard pattern. No STRIDE threats added.

## Self-Check: PASSED

- `lib/threadline/critic_trust/krippendorff_alpha.ex` — FOUND
- `test/threadline/critic_trust/krippendorff_alpha_test.exs` — FOUND
- `test/threadline/operator_surface/critic_trust_test.exs` — FOUND
- Commit `ddceb50d` — FOUND
- Commit `cf0522c4` — FOUND
- `mix verify.critic_trust`: 12 tests, 0 failures — PASSED
