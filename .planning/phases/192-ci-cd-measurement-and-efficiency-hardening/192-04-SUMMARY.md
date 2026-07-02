---
phase: 192-ci-cd-measurement-and-efficiency-hardening
plan: 04
subsystem: ci-cd
tags: [ci, contract-test, dep-floor-guard, branch-protection, D-16, D-26, D-27]
requires:
  - 192-02 (matrix/caches/concurrency/pin already in ci.yml)
  - 192-03 (release publish concurrency free of run_id; CONTRIBUTING Lists 1 & 2)
provides:
  - Durable static-parse contract lock over the Wave-2 CI constructs (D-26)
  - Dep-floor guard failing loudly at the lock for any >1.15 Elixir floor (D-16)
affects:
  - test/threadline/phase06_nyquist_ci_contract_test.exs
  - test/threadline/dep_floor_guard_test.exs
tech-stack:
  added: []
  patterns:
    - async static-parse contract test (phase06) extended additively
    - fetched-deps inspection guard (separate file, reads deps/*/mix.exs)
key-files:
  created:
    - test/threadline/dep_floor_guard_test.exs
  modified:
    - test/threadline/phase06_nyquist_ci_contract_test.exs
decisions:
  - "D-26 assertions land AFTER Wave-2 edits: green-by-construction, no born-red test (D-27)"
  - "D-16 guard resolves both literal and @module-attribute elixir: requirement forms"
  - "Matrix-name assertion checks ci.yml CONSTRUCTION (static name + lane axis), not a runtime-composed literal"
metrics:
  duration: ~15m
  completed: 2026-07-02
status: in-progress
---

# Phase 192 Plan 04: Wave-3 Contract Lock & Dep-Floor Guard Summary

Extended the phase06 CI contract test with the D-26 alignment assertions and added
a D-16 dep-floor guard — both green-by-construction over the Wave-2/Wave-3 edits (D-27).
Tasks 01 and 02 are complete and committed; Task 03 is a human-gated checkpoint
(branch-protection reconfig + throwaway min-lane resolution run) and is **NOT** performed
by the executor.

## Status

| Task | Description | Status | Commit |
|------|-------------|--------|--------|
| 01 | Extend phase06 contract test (D-26 additive assertions) | ✅ complete | c11ff4c1 |
| 02 | Add dep-floor guard test (D-16) | ✅ complete | 7e47bf5c |
| 03 | Maintainer checklist: throwaway min-lane run (D-17) + branch-protection reconfig (D-19) | ⏸ **pending human** | — |

## What was built

### Task 01 — phase06 D-26 additive assertions (commit c11ff4c1)
Added six new `describe` blocks (8 new tests) to `phase06_nyquist_ci_contract_test.exs`,
all reusing the existing async static-parse `read_rel!` helper (no network):

- **Job-key parity** — parses the 10 `verify-*` keys from ci.yml `jobs:`, the ci.yml
  leading `#` header comment, and the CONTRIBUTING List 1 table, and asserts set-equality
  across all three (drift reports the offending symmetric difference).
- **verify-compile-no-optional** remains a standalone job key (not folded into the matrix).
- **No `:latest`** in any of the four workflow files (ci/release/flake-detection/hex-publish).
- **ci.yml PR concurrency** block present with `cancel-in-progress` gated on
  `github.event_name == 'pull_request'`.
- **release.yml publish concurrency** group present (`release-publish-…`) and free of `run_id`
  (scoped to the publish-hex group so the legitimate `run_id` uses in distribution-sync are
  not flagged).
- **verify-test matrix construction A** — asserts ci.yml declares the static
  `name: Run test suite` plus a base axis `lane: [min, current]` (NOT the runtime-composed
  literal), and that CONTRIBUTING List 2 carries `Run test suite (min)` / `(current)`.
- **Cache contract** — `actions/cache@v4` for `path: deps`, the e2e `cache-dependency-path`,
  and NO cache step whose `path:` is `_build`.

All existing phase06 assertions (job-key presence, main-only triggers, ci.all ordering,
README/CONTRIBUTING discovery) remain intact — extensions are strictly additive.
`mix test test/threadline/phase06_nyquist_ci_contract_test.exs` → 14 tests, 0 failures.

### Task 02 — dep-floor guard (commit 7e47bf5c)
New `test/threadline/dep_floor_guard_test.exs` (its own file, keeps phase06 pure
static-parse). Enumerates `Path.wildcard("deps/*/mix.exs")`, extracts each `elixir:`
requirement (resolving both the literal `"~> 1.x"` form and the
`@elixir_requirement`-attribute form used by e.g. Phoenix), and asserts
`Version.match?("1.15.0", req)` for each dep that declares one. Deps without an `elixir:`
key are skipped; an unfetched `deps/` tree flunks with a clear "run mix deps.get" message.
Verified: 34/36 locked deps declare an `elixir:` floor and all admit 1.15.0; a hypothetical
`~> 1.16` floor correctly returns `false` and would fail naming the dep.
`mix test test/threadline/dep_floor_guard_test.exs` → 1 test, 0 failures.

Combined: `mix test <both files>` → 15 tests, 0 failures.

## Deviations from Plan

None — plan executed exactly as written. Both tasks were green-by-construction against the
current tree (192-02/192-03 already made the asserted facts true), honoring D-27's
land-as-one-coherent-set / no-born-red rule.

## Task 03 — HUMAN-GATED (not performed)

Task 03 is `autonomous: false`, `checkpoint:human-verify` (gate=blocking). The two steps are
inherently external — a GitHub live-run resolution check and a repo-settings change — and
cannot be asserted by any in-repo test. Surfaced as a maintainer checklist in the checkpoint
return, **not** auto-approved. Plan and STATE reflect this plan as in-progress / checkpoint,
not complete.

## Known Stubs

None.

## Threat Flags

None — no new security surface introduced (test-only changes; the only tooling referenced,
`actions/cache@v4`, was added in Wave 2 and is GitHub-official).

## Self-Check: PASSED

- FOUND: test/threadline/phase06_nyquist_ci_contract_test.exs
- FOUND: test/threadline/dep_floor_guard_test.exs
- FOUND: .planning/phases/192-.../192-04-SUMMARY.md
- FOUND commit c11ff4c1 (Task 01), FOUND commit 7e47bf5c (Task 02)
