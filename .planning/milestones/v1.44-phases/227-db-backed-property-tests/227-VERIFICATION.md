---
phase: 227-db-backed-property-tests
verified: 2026-10-01T00:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 227: DB-Backed Property Tests Verification Report

**Phase Goal:** A security reviewer can rely on redacted columns never reaching storage, diffs or exports, and an operator can rely on `as_of` reconstruction and retention cutoffs being exact (ROADMAP SC1-SC5).
**Verified:** 2026-10-01
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP SC1-SC5)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | Over generated captured values, a redacted column's plaintext never appears in the stored audit change, its ChangeDiff output, or its CSV/JSON export | VERIFIED | `test/threadline/capture/redaction_leak_property_test.exs` exists, imports `Threadline.Test.LeakOracle`/`RedactionLeakGenerators`, checks raw storage rows, three `ChangeDiff` variants, and five export surfaces (`to_csv_iodata/2`, `to_json_document/2` x2, `stream_export_rows/2` piped through `format_changes_iodata/3` x2) per 227-EVIDENCE.md D-10. Ran it locally: `3 properties, 114 tests, 0 failures`. Three independent mutation controls (`redaction_changed_from_mask`, `redaction_exclude_change_detect`, `redaction_update_path`) each killed 5/5 with reproduced seeds in 227-EVIDENCE.md, and the pre-D-13 inverted run shows the existing example suite missed the exclude-change-detect mutant (closing a real coverage gap) |
| SC2 | For generated row histories, `as_of` at each point equals a hand-written, in-order replay of that row's history | VERIFIED | Read `test/threadline/query/as_of_property_test.exs` directly: oracle is a string-keyed model folded from generated steps applied as real parameterised SQL, explicitly never from `data_after`/`history_query`/`as_of_query` (confirmed by direct read, matching code-reviewer's independent trace in 227-REVIEW.md). Five mutation controls (`as_of_le`, `as_of_order`, `as_of_delete`, `capture_clock`, `as_of_tiebreak`) in 227-EVIDENCE.md: four killed 5/5, one (`as_of_tiebreak`) honestly recorded as an expected survivor unreachable by real capture (0 ties in 9,001 probes), caught instead by a dedicated D-17 example test — not a gap, a documented design limit |
| SC3 | With generated timestamps clustered at the cutoff, `Retention.purge(dry_run: true)` selects exactly the rows strictly older than the cutoff; every row at or after it survives unchanged in content, not just count | VERIFIED | Read `test/threadline/retention/cutoff_property_test.exs`: expected sets come only from `DateTime.compare(captured_at, cutoff) == :lt` generated facts, never from `lib/`. Snapshot-and-compare of both storage-qualified tables (`::text` cast) enforces byte-identical survivors. Five mutation controls in 227-EVIDENCE.md all killed 5/5, including the real D-20 defect this property's own research probes found (`dry_run_result`'s transaction under-count) — fixed in `lib/threadline/retention.ex` (confirmed by direct read: the `c.captured_at >= ^cutoff` guard is present at the cited line), with a CHANGELOG entry and a regression example test |
| SC4 | Each property uses `DataCase` (async:false, no Sandbox), per-iteration unique-key cleanup, `max_runs <= 20`, passes under partitioned CI and a scaled Flake Detection run; VERIFICATION.md records a mutation control and failing seed for each | VERIFIED | All three property files use `Threadline.DataCase, async: false` + `PropertyRuns.db(20)` (confirmed by direct read). `test/threadline/property_scale_contract_test.exs` enforces the DataCase-must-use-`db/1` rule with its own mutation control. CI run `36929234558` (verified via `gh run view`, read-only: conclusion success, headSha `d61f2fc6` matches the cited commit) passed on the partitioned lanes. Flake Detection run `36930385324` (verified via `gh run view`, read-only: conclusion success, same headSha) completed 1 cold + 8 repeats, all green, at `THREADLINE_PROPERTY_SCALE=5`. 227-EVIDENCE.md records 13 total mutation controls (3 PROP-04 + 5 PROP-06 + 5 PROP-07) each with a diff, a seed, a shrunk counterexample, a kill rate and a green-after-restore line |
| SC5 | VERIFICATION.md reports suite wall clock before and after, against SUITE-01 and the phase-225 partitioned figure | VERIFIED | 227-EVIDENCE.md's "SC-5 wall clock" section cites `ci-job-timing.py` single-run output for before (`36903609149`) and after (`36929234558`) CI runs, plus SUITE-01's baseline (`36730596489`) and phase-225's partitioned runs (`36808706517`, `36810081717`) for reference — proxy total 14 matches the phase-225 partitioned figure, confirming no regression toward the pre-partitioning baseline of 20. Local per-file costs and whole-suite noisy figures are in `evidence/SC5-local.md`. Both files pass `check-citations.py` (re-ran it directly: exit 0 on each) |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/support/db_property.ex` | Shared DB-property harness (D-01/D-02) | VERIFIED | Exists, 7885 bytes; harness functions used by all three property files |
| `test/support/leak_oracle.ex` | PROP-04 three-layer leak detector (D-10) | VERIFIED | Exists, imported by `redaction_leak_property_test.exs` |
| `test/support/redaction_leak_generators.ex` | Canary/op-plan generators (D-08/D-09) | VERIFIED | Exists, imported by the PROP-04 property |
| `test/support/row_history_generators.ex` | PROP-06 step/batch generators (D-15) | VERIFIED | Exists, imported by the PROP-06 property |
| `test/support/retention_cutoff_generators.ex` | PROP-07 fixture generator (D-19) | VERIFIED | Exists, imported by the PROP-07 property |
| `test/threadline/capture/redaction_leak_property_test.exs` | PROP-04 property | VERIFIED | Exists, passes, non-trivial moduledoc and body (10K bytes) |
| `test/threadline/query/as_of_property_test.exs` | PROP-06 property | VERIFIED | Exists, passes, oracle independent of code under test |
| `test/threadline/retention/cutoff_property_test.exs` | PROP-07 property | VERIFIED | Exists, passes, oracle independent of code under test |
| `lib/threadline/retention.ex` (D-20 fix) | Dry-run transaction under-count fixed | VERIFIED | `c.captured_at >= ^cutoff` guard present in `dry_run_result/4` at the cited location; CHANGELOG entry present |
| `.planning/phases/227-db-backed-property-tests/tools/mutations/*.patch` (13 files) | Mutation control patches for D-12/D-16/D-21 | VERIFIED | All 13 patch files present on disk |
| `227-EVIDENCE.md` | SC4/SC5 evidence | VERIFIED | Present, passes `check-citations.py`, no home path/username found |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `redaction_leak_property_test.exs` | `Threadline.Test.LeakOracle` / `RedactionLeakGenerators` | `import` | WIRED | Confirmed by direct read of the test file header |
| `as_of_property_test.exs` | `Threadline.Query.as_of/4` | direct call under probes | WIRED | Confirmed by direct read; oracle built independently, then compared against `as_of` output |
| `cutoff_property_test.exs` | `Threadline.Retention.purge/1` | direct call (dry run + real) | WIRED | Confirmed by direct read |
| All three property test files | `Threadline.DataCase` + `PropertyRuns.db/1` | `use`/module attribute | WIRED | Confirmed by direct read of each file's header |
| `property_scale_contract_test.exs` | DataCase property files | static source scan | WIRED | Enforces `db/1` usage; has its own mutation control |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All three DB properties plus supporting example/contract/coverage tests pass | `mix test test/threadline/capture/redaction_leak_property_test.exs test/threadline/query/as_of_property_test.exs test/threadline/retention/cutoff_property_test.exs test/threadline/db_property_harness_test.exs test/threadline/property_generator_coverage_test.exs test/threadline/property_scale_contract_test.exs test/threadline/capture/trigger_redaction_test.exs test/threadline/query_test.exs test/threadline/retention_test.exs` | `3 properties, 114 tests, 0 failures` | PASS |
| D-20 fix present in `lib/` | direct `Read`/`grep` of `lib/threadline/retention.ex` | `c.captured_at >= ^cutoff` guard present in `dry_run_result/4` | PASS |
| CI run cited in EVIDENCE.md is real and green | `gh run view 36929234558 --json conclusion,headSha` | `conclusion: success, headSha: d61f2fc6...` | PASS |
| Flake Detection run cited in EVIDENCE.md is real and green | `gh run view 36930385324 --json conclusion,headSha` | `conclusion: success, headSha: d61f2fc6...` (same commit) | PASS |
| Evidence docs pass the citation-discipline checker | `python3 .../check-citations.py 227-EVIDENCE.md` and `evidence/SC5-local.md` | exit 0 on both | PASS |
| No debt markers in new/modified files | `grep -nE "TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER"` across the 9 new/modified support+test+lib files | no matches | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PROP-04 | 227-02 | Redacted column plaintext never reaches storage, diff or export | SATISFIED | `redaction_leak_property_test.exs` + `LeakOracle`, passes, 3 mutation controls killed 5/5 |
| PROP-06 | 227-03 | `as_of` equals an independent in-order replay | SATISFIED | `as_of_property_test.exs`, oracle verified independent, passes, 5 mutation controls (4 killed 5/5, 1 honestly recorded as unreachable-by-design) |
| PROP-07 | 227-04 | Retention cutoff boundary with `dry_run: true` matches a completed purge | SATISFIED | `cutoff_property_test.exs`, oracle verified independent, passes, 5 mutation controls killed 5/5, real D-20 defect found and fixed |

No orphaned requirements: REQUIREMENTS.md maps only PROP-04/PROP-06/PROP-07 to Phase 227, and all three are claimed in plan frontmatter (227-02/03/04/05) and satisfied above. `PROP-08` is already attributed to Phase 226 (not this phase). `TELE-03` is attributed to Phase 228 — its mention in 227-CONTEXT.md's canonical refs is forward-looking context (D-11 hook) only, not a Phase 227 deliverable, and REQUIREMENTS.md correctly lists it as Pending under Phase 228.

### Anti-Patterns Found

None. Scanned all new/modified support files, the three property test files, and `lib/threadline/retention.ex` for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` and stub patterns — no matches.

### Code Review Findings (227-REVIEW.md)

0 critical, 2 warnings, 2 info — none are blockers and none contradict the phase goal:
- WR-01: `purge_result/0` typespec missing the `:dry_run` key (pre-existing, adjacent to the D-20 fix, cosmetic)
- WR-02: `dry_run: true` silently ignores `:batch_size`/`:max_batches` (documented behavior, operator-UX sharp edge, not a correctness bug)
- IN-01/IN-02: documentation/comment suggestions, no code change required

These are legitimate quality follow-ups but do not block the phase goal (redaction never leaks; `as_of` and retention cutoffs are exact) — none of them represent a correctness gap in the properties or the D-20 fix itself, which the reviewer independently traced and found correct.

### Human Verification Required

None. All checks in this report were completed by re-running cited tests, reading the actual test/lib source, and checking cited CI/Flake Detection run ids read-only via `gh run view`.

### Gaps Summary

No gaps. All five ROADMAP success criteria are verified against actual, executable code (not SUMMARY narrative): the three DB-backed properties exist, pass, use independent oracles (confirmed by direct source read, corroborated by 227-REVIEW.md's independent trace), each has a recorded mutation control with a reproduced failing seed, the real D-20 retention defect the property research found is fixed in `lib/`, CI and Flake Detection runs cited in evidence are real and green (confirmed read-only via `gh run view`), and the wall-clock before/after reporting is present and passes the citation-discipline checker.

---

*Verified: 2026-10-01*
*Verifier: Claude (gsd-verifier)*
