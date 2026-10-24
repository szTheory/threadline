---
phase: 226-pure-property-tests-and-run-budget
verified: 2026-10-01T18:10:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification: []
---

# Phase 226: Pure Property Tests and Run Budget Verification Report

**Phase Goal:** A reviewer can trust cursor paging, ChangeDiff, redaction-policy validation and export encoding across generated inputs, and the property suite's run time stays bounded and tunable.
**Verified:** 2026-10-01T18:10:00Z
**Status:** human_needed (one pending CI run; all other checks verified)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Cursor paging (timeline + actor-history) over generated tie-heavy lists: concatenated pages == full list, no dupes/gaps, checked against an independent ordering not the cursor's own sort | ✓ VERIFIED | `test/threadline/query/cursors_property_test.exs`, `test/support/cursor_generators.ex`, `test/support/keyset_model.ex` exist and are substantive (73/102/206 lines). `mix test test/threadline/query/cursors_property_test.exs test/threadline/query_test.exs` passes. `Threadline.Query.Cursors.actor_history_page/4` exists in `lib/threadline/query/cursors.ex` and is called from `query.ex` (D-01 refactor). Oracle is `Enum.sort_by(entries, &{&1.ts_usec, Ecto.UUID.dump!(&1.id)}, :desc)` — independent of the cursor's own code. |
| 2a | ChangeDiff matches an independently derived expectation across INSERT/UPDATE/DELETE x before_values | ✓ VERIFIED | `test/support/change_fact_generators.ex` builds ground-truth facts first, then the `%AuditChange{}`; `expected(fact)` never calls `ChangeDiff`. `test/threadline/change_diff_property_test.exs` compares with `===`. Ran green. Code review (226-REVIEW.md) independently confirmed the oracle is non-tautological. |
| 2b | Redaction-policy validation accepts every generated valid policy, rejects every generated invalid one | ✓ VERIFIED | `test/support/redaction_policy_generators.ex` (268 lines) builds valid policies by construction and invalid ones with one tagged defect each. `test/threadline/capture/redaction_policy_property_test.exs` ran green. D-18 fail-loudly fixes present in `lib/threadline/capture/redaction_policy.ex` and `lib/threadline/capture/trigger_capture_config.ex`. |
| 2c | Export CSV/JSON round-trip generated change maps without loss, checked by an independent decoder | ✓ VERIFIED | `test/support/strict_rfc4180.ex` (90 lines) is a hand-written decoder using no NimbleCSV; `test/threadline/export_property_test.exs` (351 lines) ran green, including the cross-format agreement property. D-17 bare-CR fix present in `lib/threadline/export/csv.ex` (custom `NimbleCSV.define` with `reserved: [",", "\"", "\r", "\n"]`), confirmed by code review as correctly scoped. |
| 3 | Each pure property is `async: true` with explicit `max_runs` 150-200; generators live in `test/support/`, named for their bias; `THREADLINE_PROPERTY_SCALE` multiplies runs on the weekly Flake Detection lane and a test pins the wiring | ✓ VERIFIED | `test/support/property_runs.ex` reads `System.get_env` inside `scale/0` (verified by reading the file — no module attribute holds the value). `test/threadline/property_scale_contract_test.exs` (453 lines) parses both workflow YAMLs and AST-scans every property file; ran green. `.github/workflows/flake-detection.yml` sets `THREADLINE_PROPERTY_SCALE: "5"` only on the `id: repeat` step; `ci.yml` contains no occurrence of the variable (grepped directly). |
| 4 | VERIFICATION.md records a mutation control for each of the four properties: invariant broken on purpose, property red, failing seed | ✓ VERIFIED | `226-EVIDENCE.md` records 7 mutation controls (cursor, cursor_sql [inverted], change_diff, redaction_policy trim, redaction_policy length, export datetime, export csv_join) each with diff, per-seed red output, kill rate and green-after-restore. Independently re-ran `tools/mutation-control.sh` against `export_csv_join.patch` at seed 1: reproduced the exact same failing test name and kill signature; `git diff --quiet -- lib` was clean both before and after. |
| 5 | VERIFICATION.md reports suite wall clock before and after | ✓ VERIFIED | `226-EVIDENCE.md` "SC-5 wall clock before and after" section reports local (new-files cost at scale 1 and scale 5, whole-suite base vs head, labelled "local, noisy") and CI (per-lane `ci-job-timing.py` before/after on runs 36820084560 -> 36887218675, with the `--compare` two-run limitation explained and worked around) and the Flake Detection re-derivation at scale 5 (runs 36888506162, 36897742852). |

**Score:** 6/6 roadmap success criteria (SC1-SC5, with SC2 split into three target claims above) verified by direct evidence, not SUMMARY narrative alone.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| PROP-01 | 226-02 | Cursor paging pure property, tie-heavy, no dupes/gaps | ✓ SATISFIED | `cursors_property_test.exs` + `query_test.exs` green; `Cursors.actor_history_page/4` wired |
| PROP-02 | 226-03 | ChangeDiff against independent oracle | ✓ SATISFIED | `change_diff_property_test.exs` green; oracle independence confirmed by review and by reading `change_fact_generators.ex` |
| PROP-03 | 226-01 | Redaction-policy validation accept/reject | ✓ SATISFIED | `redaction_policy_property_test.exs` green; D-18 fixes landed and tested |
| PROP-05 | 226-04 | Export round-trip via independent decoder | ✓ SATISFIED | `export_property_test.exs` green; `strict_rfc4180.ex` independent of NimbleCSV |
| PROP-08 | 226-05 | Run time bounded and tunable | ✓ SATISFIED | `property_scale_contract_test.exs` green; `PropertyRuns.scale/0` reads env at runtime; `flake-detection.yml` wired, `ci.yml` unaffected |

No orphaned requirements: REQUIREMENTS.md lines 16-23/95-102 list exactly PROP-01, 02, 03, 05, 08 for Phase 226, matching the plan frontmatter `requirements:` across 226-01..226-06. (PROP-04/06/07, if they exist, are not mapped to Phase 226 and were not checked here.)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/support/property_runs.ex` | `PropertyRuns` scale helper | ✓ VERIFIED | 49 lines, runtime env read confirmed by inspection |
| `test/support/cursor_generators.ex` | tie-heavy cursor generators | ✓ VERIFIED | 102 lines |
| `test/support/keyset_model.ex` | in-memory keyset model | ✓ VERIFIED | 206 lines |
| `test/support/change_fact_generators.ex` | fact-first ChangeDiff oracle | ✓ VERIFIED | 206 lines |
| `test/support/redaction_policy_generators.ex` | tagged valid/invalid policies | ✓ VERIFIED | 268 lines |
| `test/support/export_hostile_value_generators.ex` | hostile JSON-domain values | ✓ VERIFIED | 223 lines |
| `test/support/strict_rfc4180.ex` | independent CSV decoder | ✓ VERIFIED | 90 lines, no NimbleCSV import |
| `test/threadline/query/cursors_property_test.exs` | PROP-01 property | ✓ VERIFIED | 73 lines, green |
| `test/threadline/change_diff_property_test.exs` | PROP-02 property | ✓ VERIFIED | 224 lines, green |
| `test/threadline/capture/redaction_policy_property_test.exs` | PROP-03 property | ✓ VERIFIED | 149 lines, green |
| `test/threadline/export_property_test.exs` | PROP-05 property | ✓ VERIFIED | 351 lines, green |
| `test/threadline/property_scale_contract_test.exs` | PROP-08 contract | ✓ VERIFIED | 453 lines, green |
| `test/threadline/property_generator_coverage_test.exs` | D-22 coverage floors | ✓ VERIFIED | 221 lines, green |
| `lib/threadline/query/cursors.ex` | `actor_history_page/4` | ✓ VERIFIED | 179 lines, function present and called from `query.ex` |
| `lib/threadline/export/csv.ex` | custom RFC4180 (bare-CR fix) | ✓ VERIFIED | 16 lines, `reserved:` includes `\r`/`\n` |
| `lib/threadline/capture/redaction_policy.ex`, `trigger_capture_config.ex` | D-18 fail-loudly validation | ✓ VERIFIED | both present, `check_column_list!/3` now guards `exclude`/`mask`/`except_columns` (CR-01 fix) |
| `.github/workflows/flake-detection.yml` | scale 5 on `repeat` step, re-derived ceilings | ✓ VERIFIED | `env: THREADLINE_PROPERTY_SCALE: "5"` on `id: repeat`; budget comment cites runs 36888506162/36897742852 |
| `226-EVIDENCE.md` | SC-4/SC-5 evidence | ✓ VERIFIED | all sections present, passes `check-citations.py` with no output (clean) |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `query.ex` (actor_history/2, timeline paths) | `Cursors.actor_history_page/4` / `timeline_page_next_cursor/2` | direct call | ✓ WIRED | confirmed via plan truths + existing `query_test.exs` passing unchanged |
| `change_diff_property_test.exs` | `Threadline.ChangeDiff.from_audit_change/2` | `===` against `expected(fact)` | ✓ WIRED | oracle built from facts, not from calling ChangeDiff (grepped: `expected/1` has no reference to `ChangeDiff`) |
| `export_property_test.exs` | `Threadline.Export.format_changes_iodata/3` | strict decoder / Jason round-trip | ✓ WIRED | ran green |
| `flake-detection.yml` `repeat` step | `PropertyRuns.scale/0` | `THREADLINE_PROPERTY_SCALE` env | ✓ WIRED | `property_scale_contract_test.exs` parses the YAML and asserts this |
| `226-EVIDENCE.md` CI rows | `225/tools/ci-job-timing.py --compare` | same formula as phase 225 | ✓ WIRED | documented with the `--compare` limitation explained and worked around via two single-run invocations |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Targeted property + contract + DB-agreement files pass | `mix test test/threadline/query/cursors_property_test.exs test/threadline/change_diff_property_test.exs test/threadline/capture/redaction_policy_property_test.exs test/threadline/export_property_test.exs test/threadline/property_scale_contract_test.exs test/threadline/property_generator_coverage_test.exs test/threadline/query_test.exs test/threadline/capture/trigger_capture_config_test.exs test/threadline/strict_rfc4180_test.exs` | "18 properties, 134 tests, 0 failures" | ✓ PASS |
| Credo clean after CR-01/WR-02 fixes | `mix credo --strict` | "4700 mods/funs, found no issues" | ✓ PASS |
| `ci.yml` never sets the scale env | `grep THREADLINE_PROPERTY_SCALE .github/workflows/ci.yml` | no match | ✓ PASS |
| `except_columns:` non-list raises (CR-01 fix) | `grep -n except_columns test/threadline/capture/trigger_capture_config_test.exs` | regression test at line 232 asserting `ArgumentError` naming the table/key | ✓ PASS |
| Mutation control reproduces independently | `bash tools/mutation-control.sh export_csv_join.patch test/threadline/export_property_test.exs 1` | same failing test, kill rate 1/1, `git diff --quiet -- lib` clean before and after | ✓ PASS |
| Evidence doc citations are well-formed | `python3 225/tools/check-citations.py 226-EVIDENCE.md` | no output (pass) | ✓ PASS |

### Probe Execution

Not applicable — this phase has no `scripts/*/tests/probe-*.sh` convention; the mutation-control runner (`tools/mutation-control.sh`) serves the equivalent role and was independently re-run above.

### Anti-Patterns Found

No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER markers found in the phase's modified `lib/` or `test/support/` files during review of file contents above. No stub `return []`/`return nil`/empty-handler patterns found in the artifacts inspected. 226-REVIEW.md's own findings (CR-01, WR-01, WR-02, IN-01, IN-02) were all resolved or explicitly accepted with a cited rationale (WR-01: 200-run base is the locked D-07 decision, weekly lane runs at scale 5 = 1000 runs).

### Human Verification Required

### 1. In-progress CI run on the phase head

**Test:** Check the conclusion of `gh run view 36903609149` (ci.yml dispatched on commit d58ef5e9, milestone/v1.44).
**Expected:** All three lanes (min/current/latest) succeed, consistent with the already-completed post-226 run 36887218675 on commit b4200f44.
**Why human/orchestrator:** The run was still `in_progress` at verification time (confirmed via `gh run list`). No static check can substitute for a pending CI run's conclusion; the orchestrator said it would fill in the result once available. This is the only open item — it is not evidence of a gap, just an unresolved pending fact.

### Gaps Summary

No gaps found. Every ROADMAP success criterion (SC1-SC5) and every PLAN-level must-have truth checked against the codebase (artifact existence, substantive content, wiring, and in several cases independent re-execution of tests/mutation controls) holds. The one code-review finding with real correctness impact (CR-01, the `except_columns:` silent-drop gap) was fixed and is covered by a new regression test, independently confirmed here. The two accepted/fixed warnings (WR-01, WR-02) do not block the goal. The only open item is the in-progress `ci.yml` run 36903609149, which is a pending external fact rather than a codebase gap — hence `status: human_needed` rather than `gaps_found`.

---

_Verified: 2026-10-01T18:10:00Z_
_Verifier: Claude (gsd-verifier)_

## Resolution of the pending item

ci.yml run 36903609149 on `d58ef5e9` (`gh run view 36903609149`) concluded `success` with every job green, including the min/current/latest build-and-test lanes. The single pending item is resolved by that run; status set to `passed` (no human verification required).
