---
phase: 192-ci-cd-measurement-and-efficiency-hardening
verified: 2026-07-02T00:00:00Z
status: passed
score: 16/16 must-haves verified
behavior_unverified: 0
overrides_applied: 1
overrides:
  - must_have: "Task 192-04-03 — D-17 throwaway min-lane resolution run on ubuntu-22.04 + D-19 branch-protection reconfig to the two matrix check names"
    reason: "Inherently external (a GitHub live-run resolution check + a repo-settings change); no in-repo code/test can perform it. Deferred at the operator's explicit decision (2026-07-02) to the moment these CI changes ship to public origin/main — local main is ~395 commits ahead of origin and all touch .planning/, so pushing now would leak private planning history, and the new matrix checks have never posted on GitHub, so requiring them now would brick all PRs. The two new check names are already locked in-repo by the D-26 contract test, and the deferral is durably tracked with a clear trigger in 192-SHIP-CHECKLIST.md."
    accepted_by: "maintainer (szTheory)"
    accepted_at: "2026-07-02T00:00:00Z"
---

# Phase 192: CI/CD Measurement and Efficiency Hardening Verification Report

**Phase Goal:** Baseline the CI/CD pipeline, then make low-risk improvements that improve feedback speed, determinism, and maintainer DX without weakening gates.
**Verified:** 2026-07-02
**Status:** passed (with the documented, ship-gated 192-04-03 deferral)
**Re-verification:** No — initial verification

## Goal Achievement

The in-repo goal is fully achieved. The pipeline was baselined read-only first (CI-01, zero
workflow edits — observer-effect ordering held), then four low-risk, independently-reversible,
gate-preserving improvements landed (CI-02 caching, CI-03 alignment/hygiene, CI-04 compatibility
lanes) and are durably locked by a green static-parse contract test plus a dep-floor guard. Every
one of the 27 locked decisions (D-01..D-27) that can be asserted in-repo is honored. The only
outstanding item is the inherently-external ship-time action pair (D-17/D-19), accepted as a
tracked deferral with a clear trigger.

### Observable Truths

| #  | Truth | Status | Evidence |
| -- | ----- | ------ | -------- |
| 1  | CI-01: `192-BASELINE.md` is a durable read-only artifact in Phase-189 shape (frontmatter `phase/artifact/audited/scope/requirements/status/source_precedence` + ranked D-03 table) with honest-unavailable rows carrying owner/date/superseding-pointer/reopen-trigger | VERIFIED | `192-BASELINE.md` read: 189-shaped frontmatter, 10-row ranked table w/ all 8 D-03 columns, billed-minutes + cache-hit-rate rows carry the four-field Nyquist-debt metadata (D-04) |
| 2  | CI-01: baselining introduced zero workflow edits (D-05 observer-effect) | VERIFIED | `git show --stat` of the three 192-01 commits: only `.planning/` files touched (192-BASELINE.md, aggregate-ci-baseline.sh, SUMMARY); no `.github/`, source, or test files |
| 3  | CI-02: `deps/` cache on the 8 root-deps ci.yml jobs + flake-detection `verify-flake`; NOT on verify-hex-evaluator / verify-release-shape | VERIFIED | ci.yml has 9 `actions/cache@v4` uses (8 `path: deps` + 1 Playwright); verify-hex-evaluator (nested project) and verify-release-shape (no setup-beam) have none; flake-detection.yml has 1 `deps` cache before its `mix deps.get` |
| 4  | CI-02: Playwright + npm caches scoped to the e2e lockfile via `cache-dependency-path` | VERIFIED | setup-node@v5 has `cache: npm` + `cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json`; Playwright cache `path: ~/.cache/ms-playwright` keyed on `hashFiles('examples/.../e2e/package-lock.json')` — never folded into the root mix.lock key (D-09) |
| 5  | CI-02: NO `_build` cache anywhere (D-10) | VERIFIED | `grep -c 'path: _build'` = 0 in ci.yml and flake-detection.yml; contract test `refute`s any `_build` cache path |
| 6  | CI-02: installs still run — caches change speed only (D-12) | VERIFIED | 8× `mix deps.get` remain in ci.yml; `npm ci` (run-e2e.sh:107) and `npx playwright install chromium` (run-e2e.sh:111) remain |
| 7  | CI-03: pgbouncer pinned to a real tag; no `:latest` in any workflow (D-22) | VERIFIED | ci.yml:301 `edoburu/pgbouncer:v1.25.2-p0`; scram/transaction env unchanged; `grep -rc ':latest' .github/workflows/*` = 0 across all four workflows |
| 8  | CI-03: ci.yml PR-scoped concurrency cancelling only superseded pull_request runs (D-23) | VERIFIED | ci.yml:22-24 `group: ${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: ${{ github.event_name == 'pull_request' }}`; contract test asserts the gated construction |
| 9  | CI-03: release.yml publish-scoped concurrency free of `run_id` (D-24) | VERIFIED | release.yml:283-285 `group: release-publish-${{ github.ref }}`, `cancel-in-progress: false` on `publish-hex`; no workflow-level group; no `run_id`; contract test refutes `run_id` |
| 10 | CI-03: CONTRIBUTING two lists reconciled without conflation (D-25/D-19) | VERIFIED | List 1 lists all 10 job keys (adds verify-hex-evaluator + verify-example-browser); List 2 stays an 8-entry subset with the old `Run test suite (verify-test)` replaced by `(min)`/`(current)` — old name absent |
| 11 | CI-04: verify-test min/current matrix posting `Run test suite (min)` / `(current)` (construction A, D-15/D-19) | VERIFIED | ci.yml:106-121 static `name: Run test suite` + base axis `lane: [min, current]` with `include:` carrying elixir/otp/pg/runner; contract test asserts construction + CONTRIBUTING composed names |
| 12 | CI-04: min lane gates the 4 heavier steps behind `if: matrix.lane == 'current'` (D-18) | VERIFIED | ci.yml: verify.threadline (165), createdb (169), verify.example (176), verify.doc_contract (180) each carry `if: matrix.lane == 'current'`; min lane runs deps.get → compile --warnings-as-errors → verify.test only |
| 13 | CI-04: `elixir: "~> 1.15"` floor NOT raised (D-14) | VERIFIED | mix.exs:32 unchanged `elixir: "~> 1.15"`; only a support-contract comment added directly above it |
| 14 | CI-04: README + mix.exs state the explicit min/current compatibility contract (D-13) | VERIFIED | README.md:13 "Supported versions: Elixir 1.15 floor / 1.17.3 current, OTP 26 min / 27 current, PostgreSQL 14 min / 16 current"; mix.exs:28-31 matching comment noting floor honored by CI min lane, not by raising the requirement |
| 15 | CI-04: dep-floor guard asserts no locked dep floors above Elixir 1.15 (D-16) | VERIFIED | `dep_floor_guard_test.exs` enumerates `deps/*/mix.exs`, `Version.match?("1.15.0", req)` per dep; runs green (no offenders) |
| 16 | CI-04: verify-compile-no-optional preserved as a standalone job (D-20) | VERIFIED | ci.yml:75 standalone `verify-compile-no-optional:` job (not folded into the matrix); contract test asserts it as a distinct job key |

**Score:** 16/16 truths verified (0 present-behavior-unverified). 1 override applied (external ship-gated D-17/D-19 action pair).

### Prohibitions (must-NOT checks — all held)

| Prohibition | Status | Evidence |
| ----------- | ------ | -------- |
| MUST NOT cache `_build` (masks --warnings-as-errors / MIX_ENV bleed) | HELD | `grep -c 'path: _build'` = 0; contract test refutes it |
| MUST NOT leave any `:latest` tag in a workflow | HELD | 0 across all four workflow files; contract test refutes `:latest` |
| MUST NOT raise the `~> 1.15` Elixir floor | HELD | mix.exs string unchanged; comment-only addition |
| MUST NOT weaken a gate / mask a warning / make local reproduction harder | HELD | deps.get / npm ci / playwright install still run; min lane keeps `--warnings-as-errors` + full `mix test`; heavier steps gated to current, never deleted; `mix ci.all` reproducibility preserved |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `192-BASELINE.md` | CI-01 read-only baseline (189 shape) | VERIFIED | Present, durable, in-repo; ranked table + honest-unavailable rows |
| `scripts/aggregate-ci-baseline.sh` | throwaway gh/jq aggregator under .planning/ only | VERIFIED | Present (7061 bytes); never referenced by any workflow |
| `.github/workflows/ci.yml` | matrix, concurrency, pin, deps/Playwright/npm caches | VERIFIED | All constructs present and correct |
| `.github/workflows/flake-detection.yml` | deps/ cache | VERIFIED | 1 deps cache before deps.get; no _build |
| `.github/workflows/release.yml` | publish-job concurrency | VERIFIED | release-publish-${{ github.ref }}, no run_id |
| `CONTRIBUTING.md` | List 1 8→10; List 2 rename | VERIFIED | Reconciled, subset preserved |
| `README.md` / `mix.exs` | compatibility contract | VERIFIED | Explicit min/current statement + comment; floor unchanged |
| `phase06_nyquist_ci_contract_test.exs` | D-26 additive assertions | VERIFIED | Extended; existing assertions intact |
| `dep_floor_guard_test.exs` | D-16 dep-floor guard | VERIFIED | New file; green |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Phase-192 contract + guard suite green | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs test/threadline/dep_floor_guard_test.exs` | 15 tests, 0 failures | ✓ PASS |
| Library compiles warnings-as-errors | `mix compile --warnings-as-errors` | Generated threadline app, clean | ✓ PASS |
| No `:latest` in any workflow | `grep -rc ':latest' .github/workflows/*.yml` | all 0 | ✓ PASS |
| ci.yml cache count (8 deps + 1 Playwright) | `grep -c 'actions/cache@v4' ci.yml` | 9 | ✓ PASS |
| No `_build` cache | `grep -c 'path: _build' ci.yml` | 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| CI-01 | 192-01 | Recorded CI baseline (critical path, setup cost, browser lane, cache state, flaky signal) | SATISFIED | 192-BASELINE.md (truths 1-2) |
| CI-02 | 192-02, 192-04 | Low-risk cache/setup improvements, no `_build`, no warning masking, no harder local repro | SATISFIED | truths 3-6, prohibitions |
| CI-03 | 192-02, 192-03, 192-04 | Pin, release concurrency, branch-protection docs, job names, `mix ci.*` alignment testable | SATISFIED | truths 7-10 |
| CI-04 | 192-02, 192-03, 192-04 | Explicit min/current compatibility policy + only the lanes that protect the contract | SATISFIED | truths 11-16 |

### Deferred / Ship-Gated Items (accepted, tracked — not gaps)

| Item | Trigger | Tracking | Status |
| ---- | ------- | -------- | ------ |
| Task 192-04-03: D-17 throwaway min-lane resolution run on ubuntu-22.04 + D-19 branch-protection reconfig to `Run test suite (min)`/`(current)` | The deliberate clean push/release that lands ci.yml's verify-test matrix on public `origin/main` | `192-SHIP-CHECKLIST.md` (durable, with step-by-step order + rationale); two new check names already locked in-repo by the D-26 contract test | Accepted deferral (override) — inherently external; cannot be asserted by any in-repo test |

### Out-of-Scope Observation (not a phase gap)

A full `mix test` run surfaces 81 failures. These are PRE-EXISTING and environmental — every one is
`(undefined_table) relation "audit_changes"/"audit_transactions"/"threadline_evidence_records"/"threadline_saved_views" does not exist`, a local test-DB `storage_schema`/search_path issue (Phase 190 territory; CI provisions the DB correctly). Confirmed identical (81) at the pre-192 commit and current HEAD, and none are in Phase-192-authored files (the phase-192 tests are 15/0). This is NOT a Phase-192 regression and does not affect this verdict.

### Anti-Patterns Found

None. No TBD/FIXME/XXX markers, stubs, or hollow implementations in the phase-authored files. The
aggregation script is intentionally a throwaway under `.planning/` and correctly never wired into CI.

### Gaps Summary

No in-repo gaps. All four requirements (CI-01..CI-04) are satisfied, all 16 observable truths are
verified with codebase evidence, all four prohibitions hold, and the phase's own contract + guard
tests are green. The single outstanding item (192-04-03) is an inherently-external, ship-gated
operational action pair (a GitHub live-run resolution check and a repo-settings branch-protection
change) that no in-repo artifact can perform; it is accepted as a tracked deferral with a clear
trigger and durable documentation in 192-SHIP-CHECKLIST.md, and its two new check names are already
locked in-repo by the D-26 contract test.

---

_Verified: 2026-07-02_
_Verifier: Claude (gsd-verifier)_
