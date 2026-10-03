---
phase: 224-capture-and-bench-fixes
verified: 2026-09-30T19:00:00Z
status: passed
score: 9/9 must-haves verified
covered_files: [".github/workflows/ci.yml", ".planning/phases/224-capture-and-bench-fixes/224-01-PLAN.md", ".planning/phases/224-capture-and-bench-fixes/224-01-SUMMARY.md", ".planning/phases/224-capture-and-bench-fixes/224-02-PLAN.md", ".planning/phases/224-capture-and-bench-fixes/224-02-SUMMARY.md", ".planning/phases/224-capture-and-bench-fixes/224-03-PLAN.md", ".planning/phases/224-capture-and-bench-fixes/224-03-SUMMARY.md", ".planning/phases/224-capture-and-bench-fixes/224-04-PLAN.md", ".planning/phases/224-capture-and-bench-fixes/224-04-SUMMARY.md", ".planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md", ".planning/phases/224-capture-and-bench-fixes/224-REVIEW-DISPOSITION.md", ".planning/phases/224-capture-and-bench-fixes/224-REVIEW.md", "CHANGELOG.md", "CONTRIBUTING.md", "bench/mix.exs", "examples/threadline_phoenix/priv/shape_fixtures/migrations/20260930173006_threadline_triggers_shape_code_keyed_shape_composi_f2f800f9eb80.exs", "guides/upgrading-to-0.11.md", "lib/mix/tasks/threadline.gen.triggers.ex", "mix.exs", "test/mix/tasks/threadline/gen_triggers_test.exs", "test/support/migration_harness.ex", "test/support/trigger_run_generators.ex", "test/threadline/capture/trigger_rerun_property_test.exs", "test/threadline/capture/trigger_rerun_test.exs", "test/threadline/ci_topology_contract_test.exs"]
covered_digest: "v2:sha256:a7d9e8a1b03d1ac777f2ef3c7f91ee06b18f465eee711bab9318794c3fb929ea"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 224: Capture and Bench Fixes Verification Report

**Phase Goal:** An adopter can roll back every generated capture migration, including per-table reruns, and be left with a clean `pg_proc`; a contributor can compile the bench project with a bare `mix compile`.
**Verified:** 2026-09-30
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Full rollback of a default-then-rerun trigger chain leaves `pg_proc` clean, using only `TriggerSQL.drop_function_if_unused/2`, no CASCADE (SC1) | ✓ VERIFIED | `down_body/2` (`lib/mix/tasks/threadline.gen.triggers.ex:595-613`) unconditionally emits the function drop from `first_run_specs` (no `needs_per_table` filter — confirmed by reading current source). Re-ran `mix test test/threadline/capture/trigger_rerun_test.exs test/mix/tasks/threadline/gen_triggers_test.exs` myself: 65 tests, 0 failures. `git diff dd780e68 -- lib/threadline/capture/trigger_sql.ex` empty (unchanged) |
| 2 | Deterministic regression pins the two-migration repro (partial + full-chain rollback), reverting the fix turns it red (SC2) | ✓ VERIFIED | `test/threadline/capture/trigger_rerun_test.exs` "rolling back a rerun chain" describes pass (re-run above). 224-EVIDENCE.md "CAPT-02 mutation controls" section records the `needs_per_table` re-insertion turning `trigger_rerun_test.exs` red with the exact orphaned-function assertion failure, then green after restore — evidence is concrete (diff, failing assertion output, restore confirmation), not a bare claim |
| 3 | A property over random 1-4-run rerun sequences (`max_runs` ≤ 20) asserts no orphaned function after full rollback, with its own mutation control (SC3) | ✓ VERIFIED | `test/threadline/capture/trigger_rerun_property_test.exs` re-run myself: `1 property, 0 failures`. `@max_runs 20` present. 224-EVIDENCE.md records the same mutation (`needs_per_table` re-added) turning the property red with a reproducible seed (554469 → `threadline_capture_changes_trp_5`), re-ran once to confirm reproducibility, then green after restore |
| 4 | `mix compile` in `bench/` succeeds with no `MIX_ENV` set via `preferred_envs`; an existing CI job runs it; removing `preferred_envs` fails it (SC4) | ✓ VERIFIED | Reproduced myself: `rm -rf bench/_build bench/deps && env -u MIX_ENV mix verify.bench_compile` exited 0 (bench compiled bare from a fully wiped state). `bench/mix.exs:7` has `def cli, do: [preferred_envs: [compile: :test, run: :test]]`. `.github/workflows/ci.yml` `verify-compile-no-optional` job runs `mix verify.bench_compile` as a new step after the existing compile step, same job id/name, no cache step added. `mix test test/threadline/ci_topology_contract_test.exs`: 22 tests, 0 failures (pins ordering + mutation controls) |
| 5 | VERIFICATION.md (this phase's evidence) reports suite wall clock before and after, measured against milestone base `dd780e68` (SC5) | ✓ VERIFIED | 224-EVIDENCE.md "## Suite wall clock (SUITE-06)" records local head-vs-base runs (2 each), the property's own solo cost, and cites CI run 36730596489 (push, `dd780e68`) with per-job durations for the "before" figure. The CI "after" figure is explicitly recorded as pending a maintainer push grant with the exact `gh run list`/`gh run view` commands to cite once the branch is pushed — this is a deferred, not-yet-actionable item (pushing needs a maintainer grant), not a gap against SC5's text, which only requires the before/after report with the base cited |
| 6 | The example shape fixture trigger migration is regenerated (not hand-edited) and matches what the generator produces today | ✓ VERIFIED | `mix test examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_migration_contract_test.exs`, run correctly via `cd examples/threadline_phoenix && mix test ...` (the example app's own project context, matching `verify_example/1` in `mix.exs`): 4 tests, 0 failures. (Running the same test file directly from the root project's `mix test` gives a false failure because the example app's per-table mask config is only resolved from the example app's own Mix project context — confirmed this is an invocation artifact, not a real defect, by reproducing the pass from the correct working directory and by manual byte-for-byte regeneration diff) |
| 7 | Upgrade guide's "Rolling back" section covers a pre-fix (0.11.2-or-earlier) rerun chain, reuses the existing pinned SQL sweep, corrects the "rolls back safely" claim (D-06) | ✓ VERIFIED | `guides/upgrading-to-0.11.md` "## Rolling back" section read directly: new paragraph covers the pre-fix rerun-chain case, points at the existing `<!-- threadline:rollback-cleanup-sql:start -->` block (only one marker pair present), never names `TriggerSQL`, and the final paragraph is now scoped ("only for a chain whose first migration was generated by 0.11.2 or earlier") rather than an unconditional safety claim. `mix test test/threadline/upgrading_to_0_11_doc_contract_test.exs test/threadline/upgrade_rollback_test.exs`: pass |
| 8 | CHANGELOG `Unreleased` carries a `### Fixed` entry for the rollback fix, linked to the guide, no planning vocabulary | ✓ VERIFIED | `CHANGELOG.md` lines 31-39 read directly: `### Fixed` entry describing the fix in adopter language, linking `guides/upgrading-to-0.11.md#rolling-back`. `mix test test/threadline/changelog_contract_test.exs`: pass |
| 9 | No generation-time detection of old migrations added; `git diff dd780e68 -- lib/` touches only `down_body/2`, the new comment helper, and the moduledoc (D-07) | ✓ VERIFIED | `git diff dd780e68 -- lib/` shows exactly one changed file (`lib/mix/tasks/threadline.gen.triggers.ex`) |

**Score:** 9/9 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/threadline.gen.triggers.ex` | `down_body/2` unconditional function drop, `first_run_drop_comment/1`, updated moduledoc | ✓ VERIFIED | Read directly; `needs_per_table` filter removed from `function_downs`; comment phrase `if this migration or a later rerun created one` present at line 623 |
| `test/support/migration_harness.ex` | `orphan_capture_functions/0` structural check | ✓ VERIFIED | Present, used by both the deterministic and property tests (re-run green) |
| `test/threadline/capture/trigger_rerun_test.exs` | rerun-chain rollback describe block | ✓ VERIFIED | Re-run green, 3 tests inside the describe block per SUMMARY |
| `test/mix/tasks/threadline/gen_triggers_test.exs` | updated down-body assertions, `@first_run_down_phrase` pin | ✓ VERIFIED | Re-run green as part of the 65-test run |
| example shape fixture migration | regenerated, matches generator output | ✓ VERIFIED | Confirmed via the example app's own `mix test` (see Truth 6) |
| `test/support/trigger_run_generators.ex` | `run_sequence/0` | ✓ VERIFIED | Present; used by the property test (re-run green) |
| `test/threadline/capture/trigger_rerun_property_test.exs` | `@max_runs 20` DB-backed property | ✓ VERIFIED | Re-run green |
| `bench/mix.exs` | `def cli` preferred_envs | ✓ VERIFIED | Read directly, line 7 |
| `mix.exs` | `verify.bench_compile` alias, `ci.all` entry | ✓ VERIFIED | Read directly, lines 183/236/272-281 |
| `.github/workflows/ci.yml` | bench bare-compile step | ✓ VERIFIED | Read directly, lines 188-208 |
| `CONTRIBUTING.md` | job-table row names `verify.bench_compile` | ✓ VERIFIED | Confirmed present (cited by IN-01 in code review as slightly imprecise phrasing, not missing) |
| `test/threadline/ci_topology_contract_test.exs` | `bench_compile_errors/3` classifier + mutations | ✓ VERIFIED | Re-run green, 22 tests |
| `guides/upgrading-to-0.11.md` | broadened Rolling back prose | ✓ VERIFIED | Read directly |
| `CHANGELOG.md` | Unreleased Fixed entry | ✓ VERIFIED | Read directly |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `down_body/2` | `TriggerSQL.drop_function_if_unused/2` | unconditional call on `Naming.function_name(t)` | ✓ WIRED | Confirmed at `lib/mix/tasks/threadline.gen.triggers.ex:607` |
| `trigger_rerun_property_test.exs` | `test/support/migration_harness.ex` | `Harness.orphan_capture_functions/0`, `generate!/2`, `migrate_up/1`, `migrate_down/1` | ✓ WIRED | Test passes, exercising the real functions (not stubbed) |
| `trigger_rerun_property_test.exs` | `test/support/trigger_run_generators.ex` | `import Threadline.Test.TriggerRunGenerators; run_sequence()` | ✓ WIRED | Test passes with generated sequences |
| `.github/workflows/ci.yml` `verify-compile-no-optional` | `mix verify.bench_compile` | new step after the existing compile step | ✓ WIRED | Confirmed by reading the workflow file and by the contract test |
| `CHANGELOG.md` Fixed entry | `guides/upgrading-to-0.11.md#rolling-back` | relative link | ✓ WIRED | Link text present, section exists with matching anchor text |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| First-run/rerun rollback regression + unit tests | `mix test test/threadline/capture/trigger_rerun_test.exs test/mix/tasks/threadline/gen_triggers_test.exs` | 65 tests, 0 failures | ✓ PASS |
| DB-backed rerun-sequence property | `mix test test/threadline/capture/trigger_rerun_property_test.exs` | 1 property, 0 failures | ✓ PASS |
| CI topology contract (bench wiring mutation controls) | `mix test test/threadline/ci_topology_contract_test.exs` | 22 tests, 0 failures | ✓ PASS |
| Bench bare compile from wiped state | `rm -rf bench/_build bench/deps && env -u MIX_ENV mix verify.bench_compile` | exit 0, `Generated bench app` | ✓ PASS |
| Example shape fixture regeneration contract | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/shape_fixtures_migration_contract_test.exs` | 4 tests, 0 failures | ✓ PASS |
| Docs/CHANGELOG contracts | `mix test test/threadline/changelog_contract_test.exs test/threadline/upgrading_to_0_11_doc_contract_test.exs test/threadline/upgrade_rollback_test.exs` | 20 tests, 0 failures | ✓ PASS |

`mix ci.all` was not re-run in full (already ran green per 224-EVIDENCE.md "## Phase gate", exit 0, `verify.test` 10 properties/2583 tests/0 failures/3 excluded, per project rules citing that evidence instead of re-running the whole chain). The targeted suites above were re-run directly by this verifier and independently confirm the phase-relevant slices.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CAPT-01 | 224-01, 224-04 | Clean rollback of rerun chains, no CASCADE | ✓ SATISFIED | Truths 1, 7 |
| CAPT-02 | 224-01, 224-02 | Deterministic + property mutation-controlled regression | ✓ SATISFIED | Truths 2, 3 |
| SUITE-05 | 224-03 | Bench bare-compile, proven in CI | ✓ SATISFIED | Truth 4 |
| SUITE-06 | 224-02, 224-04 (cross-cutting, maps to Phase 230 for milestone net check) | Per-phase suite wall clock before/after | ✓ SATISFIED | Truth 5 |

No orphaned requirements: `.planning/REQUIREMENTS.md` maps only CAPT-01, CAPT-02, and SUITE-05 to Phase 224, and all three are accounted for by plan frontmatter. SUITE-06 is explicitly cross-cutting per REQUIREMENTS.md's own note and is satisfied at the phase level by 224-04's evidence.

### Anti-Patterns Found

None. Grep for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` and placeholder-language patterns across all phase-modified files returned no matches.

### Code Review Findings (carried forward, non-blocking)

Two findings remain `open` in 224-REVIEW-DISPOSITION.md (recorded, not yet triaged by the maintainer):
- **WR-01** (warning): `verify-compile-no-optional` CI job's `timeout-minutes: 10` was not re-validated or re-measured after adding the bench dependency-fetching step. This does not affect local proof of SC4 (the bare-compile behavior is real and verified), but is a real CI-flake risk worth a maintainer decision (bump timeout vs. measure margin).
- **IN-01** (info): `CONTRIBUTING.md`'s "no `MIX_ENV`" phrasing is imprecise (the compile does run under `MIX_ENV=test`, internally resolved by `preferred_envs`; only the caller's shell has no `MIX_ENV` exported). Cosmetic.

Neither finding blocks phase-goal achievement — both are secondary-severity, already surfaced for the maintainer, and do not contradict any of the observable truths above.

### Human Verification Required

None.

### Gaps Summary

None. All 9 observable truths (roadmap success criteria plus the plan-level must-haves for the docs/changelog and no-scope-creep constraints) are verified directly against the current codebase and re-run tests, not merely from SUMMARY claims. One apparent test failure was investigated and resolved as a verifier-invocation artifact (running the example app's test file from the root project's `mix test` instead of `cd examples/threadline_phoenix && mix test`, matching how `verify_example/1` actually invokes it) — not a real defect.

---

_Verified: 2026-09-30_
_Verifier: Claude (gsd-verifier)_
