---
phase: 229-adopter-api-and-health-additions
verified: 2026-10-02T00:00:00Z
status: passed
score: 11/11 must-haves verified
covered_files:
  - .planning/phases/229-adopter-api-and-health-additions/229-01-PLAN.md
  - .planning/phases/229-adopter-api-and-health-additions/229-01-SUMMARY.md
  - .planning/phases/229-adopter-api-and-health-additions/229-02-PLAN.md
  - .planning/phases/229-adopter-api-and-health-additions/229-02-SUMMARY.md
  - .planning/phases/229-adopter-api-and-health-additions/229-03-PLAN.md
  - .planning/phases/229-adopter-api-and-health-additions/229-03-SUMMARY.md
  - .planning/phases/229-adopter-api-and-health-additions/229-04-PLAN.md
  - .planning/phases/229-adopter-api-and-health-additions/229-04-SUMMARY.md
  - .planning/phases/229-adopter-api-and-health-additions/229-CONTEXT.md
  - .planning/phases/229-adopter-api-and-health-additions/229-REVIEW.md
  - .planning/phases/229-adopter-api-and-health-additions/229-VALIDATION.md
  - .planning/phases/229-adopter-api-and-health-additions/evidence/SC5-wallclock.md
  - CHANGELOG.md
  - guides/configuration-and-commands.md
  - guides/domain-reference.md
  - guides/operator-surface.md
  - guides/production-checklist.md
  - lib/mix/tasks/threadline.health.coverage.ex
  - lib/threadline.ex
  - lib/threadline/health.ex
  - lib/threadline/health/coverage_schemas.ex
  - lib/threadline/health/finding.ex
  - lib/threadline/health/legacy_key_findings.ex
  - lib/threadline/query.ex
  - lib/threadline/query/history_limit.ex
  - test/partition_colocate.txt
  - test/threadline/health/legacy_key_findings_test.exs
  - test/threadline/health_findings_doc_contract_test.exs
  - test/threadline/health_test.exs
  - test/threadline/operator_surface/coverage_doc_contract_test.exs
  - test/threadline/operator_surface/coverage_mix_test.exs
  - test/threadline/query/as_of_property_test.exs
  - test/threadline/query_test.exs
  - test/threadline/upgrade_backfill_test.exs
covered_digest: "v2:sha256:dc28d64c82cec832f2d4210d6f606c69fb2f610958cd0e0a0da73f9bb0f12236"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 229: Adopter API and Health Additions Verification Report

**Phase Goal:** A developer can cap `history/3` results without a breaking change, and a CI pipeline can gate on capture-coverage health across every schema
**Verified:** 2026-10-02
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion) | Status | Evidence |
|---|---|---|---|
| 1 | `history/3` with `limit: n` returns at most `n` changes, newest first, `captured_at desc, id desc` tiebreak; `0`/negative/non-integer raise `ArgumentError`; docs point to `row_history_page/4` | ✓ VERIFIED | `lib/threadline/query/history_limit.ex` (`validate!/1`, `apply/2`), wired into `history/3` (`lib/threadline/query.ex:402-423`) before `RowKey.match!`. `test/threadline/query_test.exs:472-679` re-run: 64 tests, 0 failures. Docs: `lib/threadline.ex:98-100`, `lib/threadline/query.ex:371` both point to `row_history_page/4`. |
| 2 | A test proves `history/3` without `:limit` returns the same list as before; CHANGELOG states additive/default-unchanged | ✓ VERIFIED | `test/threadline/query_test.exs:534-551` (`nil_limited == oracle_ids`, independent oracle, not tautological no-limit-vs-nil). `test/threadline/query/as_of_property_test.exs` property re-run: 2 properties, 0 failures. `CHANGELOG.md` "Added" section: "It is additive and the default is unchanged (unbounded)." |
| 3 | `mix threadline.health.coverage --strict` exits nonzero on any `:error`-severity finding, composes with `--json`; severity × strict/non-strict matrix proves non-strict exit codes unchanged | ✓ VERIFIED | `lib/mix/tasks/threadline.health.coverage.ex:225-239` (`apply_strict_gate/1`, `exit({:shutdown, 1})` only on `severity == :error`). D-09 matrix in `test/threadline/operator_surface/coverage_mix_test.exs` (schema=clean/warning/error × strict=true/false × json=true/false, all 12 cells present) re-run: 47 tests, 0 failures, including "schema=error strict=true ... outcome=exit 1" and all non-strict cells "outcome=ok". |
| 4 | `--all-schemas` produces schema-keyed report (table + JSON), rejected alongside `--schema=NAME`; pre-0.11 fixture produces `:unresolved_legacy_keys` warning with per-table counts + guide link; `--strict` does not fail on it | ✓ VERIFIED | `lib/mix/tasks/threadline.health.coverage.ex:182-200,465-529` (envelope JSON, table rollup); mutual exclusion at `:127-132`. `test/threadline/upgrade_backfill_test.exs` (0.10.2 frozen trigger fixture) re-run clean: 86 tests total (incl. `legacy_key_findings_test.exs`, `health_test.exs`, doc-contract tests), 0 failures. Message format confirmed in `lib/threadline/health/legacy_key_findings.ex:158-165` (links to `guides/upgrading-to-0.11.md#step-6-...`). Matrix test `"the warning schema's findings include unresolved_legacy_keys and --strict passes"` passed. |
| 5 | Docs state malformed `:trigger_capture` config raises rather than producing a finding; VERIFICATION.md reports suite wall clock before/after vs phase-225 baseline | ✓ VERIFIED | `guides/configuration-and-commands.md:22`: "Malformed configuration raises `ArgumentError` ...; it is never reported as a health finding." Echoed in `lib/threadline/health/finding.ex:35-36`. Pinned by a doc-contract test. `evidence/SC5-wallclock.md` present with before (median 186.2s, `c99742d8`) / after (median 171.9s, `493fa333`) `mix test` wall-clock, a `mix verify.test_partitioned` run, and explicit comparison against the phase-225 CI baseline (`225-BASELINE.md`, run 36730596489). |

**Score:** 5/5 ROADMAP success criteria verified. All 6 requirement-level must-haves (QRY-01, QRY-02, HLTH-01, HLTH-02, HLTH-03, HLTH-04) map onto the above and are independently confirmed below.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/query/history_limit.ex` | `:limit` validator + LIMIT applier | ✓ VERIFIED | Exists, substantive (`validate!/1` rejects non-positive-integer/non-nil; `apply/2` applies `limit/2`), wired into `history_query/3` after both `order_by`s (D-02). |
| `lib/threadline/query.ex` (`history/3`) | Validates before DB access | ✓ VERIFIED | `HistoryLimit.validate!/1` called before `history_query/3` → `RowKey.match!`; confirmed by `"history/3 :limit validation precedes row-key matching"` test passing with a garbage id + invalid limit. |
| `lib/mix/tasks/threadline.health.coverage.ex` | `--strict`, `--all-schemas`, invalid-switch rejection | ✓ VERIFIED | All three implemented and exercised; see Observable Truths 3-4 and WR-01 note below. |
| `lib/threadline/health/legacy_key_findings.ex` | `legacy_key_findings/1` public probe | ✓ VERIFIED | Public via `Threadline.Health.legacy_key_findings/1` (`lib/threadline/health.ex:102`), per-table capped probe (D-19), transaction-local `statement_timeout` (D-20), excludes storage-own tables and unrecoverable rows (D-21/D-22). |
| `lib/threadline/health/finding.ex` | `:unresolved_legacy_keys` code + fail-fast doc line | ✓ VERIFIED | Code added to the union; moduledoc states the fail-fast behavior (D-24/D-25). |
| `CHANGELOG.md` | One Unreleased section covering all additions + the Fixed entry | ✓ VERIFIED | "Added" lists `:limit`, `--strict`, `--all-schemas`, `legacy_key_findings/1`; unknown-switch rejection present (D-16/D-27). |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `Threadline.history/3` | `HistoryLimit.validate!/1` | direct call before `history_query/3` | WIRED | `lib/threadline/query.ex:404` |
| `history_query/3` | `HistoryLimit.apply/2` | pipe after `order_by` | WIRED | `lib/threadline/query.ex:422` |
| `mix threadline.health.coverage` | `Threadline.Health.legacy_key_findings/1` | `legacy_findings_or_hint/2` → concatenated with `trigger_findings/1` | WIRED | `lib/mix/tasks/threadline.health.coverage.ex:159-161,186,208-223` |
| `--all-schemas` | `Threadline.Health.coverage_by_schema/1` | `run_all_schemas/3` | WIRED | `lib/mix/tasks/threadline.health.coverage.ex:182-183`; golden test confirms `.schemas.public` byte-equals `--schema=public --json`. |
| `--strict` | `apply_strict_gate/1` | called from both `run_single_schema/4` and `run_all_schemas/3` | WIRED | Confirmed by the D-09 matrix and the HLTH-02 "strict union" test. |

### Behavioral Spot-Checks / Re-run Tests

| Behavior | Command | Result | Status |
|---|---|---|---|
| `history/3` limit cap, boundary, rejection, precedence | `mix test test/threadline/query_test.exs` | 64 tests, 0 failures | ✓ PASS |
| `:limit` independent-oracle property | `mix test test/threadline/query/as_of_property_test.exs` | 2 properties, 0 failures | ✓ PASS |
| `--strict`/`--all-schemas`/matrix/mutual-exclusion/extension-schema/telemetry | `mix test test/threadline/operator_surface/coverage_mix_test.exs` | 47 tests, 0 failures | ✓ PASS |
| legacy-key findings, health, upgrade-backfill fixture, doc-contract pins | `mix test test/threadline/health/legacy_key_findings_test.exs test/threadline/health_test.exs test/threadline/upgrade_backfill_test.exs test/threadline/health_findings_doc_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` | 86 tests, 0 failures | ✓ PASS |
| Full suite at HEAD (orchestrator-observed, cited not re-run to avoid concurrent-Postgres conflict) | `mix test` | 32 properties, 2767 tests, 0 failures, 3 excluded, 138.7s | ✓ PASS (cited) |
| Debt-marker scan on all phase-touched `lib/` files | `grep -nE "TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER"` | no matches | ✓ PASS |

Full `mix test` was not independently re-run (orchestrator's run is cited per the "do not run two `mix test` concurrently" rule and to avoid redundant full-suite cost); every narrower file-scoped and module-scoped re-run above was executed fresh in this verification pass and is 0 failures throughout.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| QRY-01 | 229-01 | `limit: n` on `history/3`, boundary + rejection semantics, docs point to `row_history_page/4` | ✓ SATISFIED | Observable Truth 1 |
| QRY-02 | 229-01 | No-limit-unchanged test + CHANGELOG additive wording | ✓ SATISFIED | Observable Truth 2 |
| HLTH-01 | 229-03 | `--strict` nonzero exit on `:error` findings, composes with `--json`, matrix proves non-strict unchanged | ✓ SATISFIED | Observable Truth 3 |
| HLTH-02 | 229-04 | `--all-schemas` schema-keyed report, mutually exclusive with `--schema` | ✓ SATISFIED | Observable Truth 4 |
| HLTH-03 | 229-02, 229-03 | `:unresolved_legacy_keys` warning, per-table counts, guide link, never fails `--strict` | ✓ SATISFIED | Observable Truth 4 |
| HLTH-04 | 229-02 | Docs: malformed `:trigger_capture` raises, not a finding | ✓ SATISFIED | Observable Truth 5 |

No orphaned requirements: `.planning/REQUIREMENTS.md`'s Phase 229 row lists exactly QRY-01, QRY-02, HLTH-01, HLTH-02, HLTH-03, HLTH-04, and all six are claimed across the four plans' `requirements:` frontmatter with no gaps.

### Anti-Patterns Found

None blocking. `229-REVIEW.md` (code review, standing artifact) found 0 critical, 1 warning, 1 info:

- **WR-01** (warning): `mix threadline.health.coverage`'s `OptionParser.parse/2` discards the positional-argument list (`_`), so a typo that drops the leading `--` (e.g. `mix threadline.health.coverage --strict schema=public`) silently runs against the default `"public"` schema instead of raising, rather than being caught by D-16's "unknown or invalid switch" raise. **Judgment on whether this undermines a success criterion:** it does not. SC3's contract is "`--strict` exits nonzero on any `:error`-severity finding, composes with `--json`" — true regardless of this gap, because the task still runs correctly against whichever schema it resolves to (just possibly the wrong one on a very specific typo shape: a flag-looking token missing `--`). SC4's contract ("`--all-schemas` ... is rejected alongside `--schema=NAME`") is unaffected — that rejection path uses `Keyword.has_key?`, not positional-arg handling. This is a narrower residual of D-16 (which the review confirms *is* fully delivered: `--stict`, `--all-schema`, and a value-less `--schema` all now raise, confirmed by re-running the coverage_mix_test.exs suite) rather than a failure of D-16 itself. Not a blocker; recorded for a future follow-up, not re-litigated here since the phase's locked decisions (D-16) did not scope positional-argument handling.
- **IN-01** (info): schema-identifier regex duplicated between `CoverageSchemas` and the mix task. Cosmetic/maintainability only; no behavioral impact.

### Human Verification Required

None. All five ROADMAP success criteria and all six requirement IDs are mechanically verifiable (code presence, wiring, and automated test re-runs) per this project's "zero human verification by default" standing rule, and all re-run tests passed cleanly with no behavior-dependent truths left unexercised.

### Gaps Summary

No gaps. All 5 ROADMAP success criteria and all 6 requirement IDs (QRY-01, QRY-02, HLTH-01, HLTH-02, HLTH-03, HLTH-04) are verified against actual, re-run, passing code — not SUMMARY.md narrative. The one code-review warning (WR-01) is a narrow, non-blocking residual gap in CLI argument validation that does not undermine any locked success criterion, and is documented above with reasoning rather than silently dropped.

---

_Verified: 2026-10-02_
_Verifier: Claude (gsd-verifier)_
