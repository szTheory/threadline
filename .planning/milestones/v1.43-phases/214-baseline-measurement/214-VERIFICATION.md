---
phase: 214-baseline-measurement
verified: 2026-09-26T20:30:00Z
status: passed
score: 32/32 must-haves verified (4/4 roadmap success criteria; 2/2 goal clauses; 23/23 plan 01-03 truths; 4/4 additional plan 04 truths; 214-04 truth 1 is deduplicated into G2)
covered_files:
  - .planning/PROJECT.md
  - .planning/REQUIREMENTS.md
  - .planning/phases/214-baseline-measurement/214-01-PLAN.md
  - .planning/phases/214-baseline-measurement/214-01-SUMMARY.md
  - .planning/phases/214-baseline-measurement/214-02-PLAN.md
  - .planning/phases/214-baseline-measurement/214-02-SUMMARY.md
  - .planning/phases/214-baseline-measurement/214-03-PLAN.md
  - .planning/phases/214-baseline-measurement/214-03-SUMMARY.md
  - .planning/phases/214-baseline-measurement/214-04-PLAN.md
  - .planning/phases/214-baseline-measurement/214-04-SUMMARY.md
  - .planning/phases/214-baseline-measurement/214-BASELINE.md
  - .planning/phases/214-baseline-measurement/raw/base02/facts.json
  - .planning/phases/214-baseline-measurement/tools/check-baseline-complete.py
  - .planning/phases/214-baseline-measurement/tools/check-citations.py
  - .planning/phases/214-baseline-measurement/tools/check-project-baseline.sh
  - .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh
  - .planning/phases/214-baseline-measurement/tools/fixtures/project-bad-streak.md
  - .planning/phases/214-baseline-measurement/tools/fixtures/project-stale-wall.md
  - .planning/phases/214-baseline-measurement/tools/inert-allowlist.txt
  - .planning/phases/214-baseline-measurement/tools/inert-share.py
  - .planning/phases/214-baseline-measurement/tools/measure-base02.sh
  - .planning/phases/214-baseline-measurement/tools/measure-local.sh
  - .planning/phases/214-baseline-measurement/tools/summarize-ci.py
  - .planning/phases/214-baseline-measurement/tools/verify-phase.sh
covered_digest: "v1:sha256:ab44cda69aa7ae5adc5a2918f6aecc5ea03d767d57fb01806d7df74f29a14da3"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 27/28
  gaps_closed:
    - "PROJECT.md's baseline matches measured fact (phase goal clause G2): the CI wall-time bullet now states PR 10.5 min (run 34758417725), push 10.7 min (run 34755997103), Browser-full 18.0 min per push (run 35780709940) and 14.5 min nightly (run 34932091760), and check-project-baseline.sh enforces it from facts.json"
  gaps_remaining: []
  regressions: []
prohibitions_flagged:
  # Plans 01-03: carried forward from the initial verification. The files they cover are unchanged since (plans, BASELINE, raw/ci) or changed additively only (facts.json, checker, gate).
  - statement: "MUST NOT perform any write-capable GitHub operation to obtain or refresh a measurement (214-01, 214-03)"
    verification: judgment
    llm_judge_verdict: held
    note: "Re-checked: verify-phase.sh write-verb grep PASS at HEAD. The new 214-04 step_wall makes no gh/curl call (the only 'gh' in added lines is the comment 'makes no gh call'). Non-authoritative."
  - statement: "MUST NOT present a research-carried, estimated or extrapolated number as re-measured (214-01, 214-03)"
    verification: judgment
    llm_judge_verdict: held
    note: "214-BASELINE.md unchanged since the initial verification. Non-authoritative."
  - statement: "MUST NOT write the maintainer's local username or an absolute or home-relative machine path into any new phase artifact (214-01, 214-02)"
    verification: judgment
    llm_judge_verdict: held-for-executor-artifacts
    note: "Same as the initial verification (PLAN-file template refs are planner-authored and counted in the 387 figure). The 214-04 added lines contain no machine path (grep over `git diff 28238181 HEAD` '+' lines: no match). Non-authoritative."
  - statement: "MUST NOT soften a measured fact to match the roadmap's wording (214-02)"
    verification: judgment
    llm_judge_verdict: held
    note: "Unchanged. Non-authoritative."
  - statement: "MUST NOT edit PROJECT.md Out of Scope or any section other than the Current Milestone baseline block (214-02)"
    verification: judgment
    llm_judge_verdict: held
    note: "Out of Scope re-extracted and diffed against ff8e53e9: identical (16 lines). Non-authoritative."
  - statement: "MUST NOT leave the local Dialyzer PLT or test DB changed (214-02)"
    verification: judgment
    llm_judge_verdict: held
    note: "Unchanged since the initial verification. Non-authoritative."
  - statement: "MUST NOT classify a path as inert by assumption (214-03)"
    verification: judgment
    llm_judge_verdict: held
    note: "inert-allowlist.txt and inert-share.py unchanged; self-test PASS in the gate. Non-authoritative."
  # Plan 04 prohibitions: evaluated fresh.
  - statement: "MUST NOT edit PROJECT.md outside the `## Current Milestone` baseline block; `### Out of Scope` stays byte-identical to ff8e53e9 and exactly one line of PROJECT.md changes (214-04)"
    verification: judgment
    llm_judge_verdict: held
    note: "`git diff 28238181 HEAD -- .planning/PROJECT.md` is a single -1/+1 hunk, and the changed line is the CI wall-time bullet inside the baseline block. PROJECT.md has no working-tree changes. Out of Scope diff against ff8e53e9 is empty. Non-authoritative."
  - statement: "MUST NOT perform any write-capable GitHub operation or any network call; wall-time values come from the committed raw/ci data offline (214-04)"
    verification: judgment
    llm_judge_verdict: held
    note: "Read step_wall: it runs four summarize-ci.py commands over raw/ci plus an inline python parser, then merge_facts. There is no gh, curl or wget. The verifier re-ran `measure-base02.sh wall` (facts.json backed up first): exit 0, sha fb3a1005 before and after, byte-identical, raw/ci untouched. Non-authoritative."
  - statement: "MUST NOT present an estimated, rounded-by-hand or research-carried number as measured; every wall-time figure is the summarize-ci.py p50 with its run ID (214-04)"
    verification: judgment
    llm_judge_verdict: held
    note: "The verifier re-ran the four summarize-ci.py commands: p50 629 s (run 34758417725), 640 s (run 34755997103), 18.0 min (run 35780709940), 14.5 min (run 34932091760). The minute conversion uses the same half-up tenths rule as summarize-ci.py fmt_min: 629 -> 10.5, 640 -> 10.7. The same values appear in 214-BASELINE.md lines 106-107, 248 and 253. Non-authoritative."
  - statement: "MUST NOT write a machine-local path or username into any new or modified artifact (facts.json commands are repo-relative) (214-04)"
    verification: judgment
    llm_judge_verdict: held
    note: "The new facts.json .commands values all start with `python3 .planning/...` or `bash .planning/...`. The machine-path grep over added lines found nothing. Non-authoritative."
  - statement: "MUST NOT change product code; MUST NOT modify plans 214-01..03 or 214-BASELINE.md (214-04)"
    verification: judgment
    llm_judge_verdict: held
    note: "`git diff --quiet ff8e53e9 -- mix.exs mix.lock bench/mix.lock examples/threadline_phoenix/mix.lock .github test lib` exits 0. `git diff --stat 28238181 HEAD` over the 214-01..03 PLANs, 214-BASELINE.md and raw/ci is empty. Non-authoritative."
---

# Phase 214: Baseline Measurement Verification Report

**Phase Goal:** The maintainer and every later phase can cite a re-measured, run-ID-backed CI baseline, and PROJECT.md's baseline matches measured fact
**Verified:** 2026-09-26 (re-verification)
**Status:** passed
**Re-verification:** Yes, after gap closure (plan 214-04, commits 313db847, 6d494efc, edc7f666)

## Goal Achievement

### Roadmap success criteria and goal clauses

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | The baseline doc covers per-job p50/p95 over ≥10 PR and ≥10 push runs, runner-minutes, critical path, Flake Detection and Browser-full cost, slowest 25, isolated `:live_dialyzer` cost and inert-path share | ✓ VERIFIED (regression check) | 214-BASELINE.md and raw/ci are unchanged since the initial verification (`git diff --stat 28238181 HEAD` is empty). `check-baseline-complete.py` passes on the doc and in its self-test in the gate. |
| SC2 | Every number cites a run ID or a reproducible command, and an automated check finds no uncited figure | ✓ VERIFIED (regression check) | `check-citations.py` passes on the doc and in its self-test in the gate. The doc is unchanged. |
| SC3 | PROJECT.md baseline states the corrected streak and 180-min timeout, the advisories, the path count, "tmp_dir hygiene" and the xref disposition | ✓ VERIFIED (regression check) | Only the wall-time line changed. `check-project-baseline.sh` exits 0 on PROJECT.md. It still asserts every earlier fact, and every pre-existing facts.json key and value is unchanged: `($new * $old) == $new` is true and no key was removed. |
| SC4 | Out of Scope still permits the spike-gated newest lane and records the pin-honesty justification | ✓ VERIFIED (regression check) | The `### Out of Scope` extract is byte-identical to ff8e53e9 (16 lines, empty diff). The checker's clause assertions pass. |
| G1 | Goal clause: the maintainer and later phases can cite the baseline through one re-runnable gate | ✓ VERIFIED | `bash .planning/phases/214-baseline-measurement/tools/verify-phase.sh` prints 12 PASS lines and exits 0 in 0.9 s, with no network. |
| G2 | Goal clause: "PROJECT.md's baseline matches measured fact" | ✓ VERIFIED (gap closed) | PROJECT.md line 29 now reads "PR 10.5 min (run 34758417725), push 10.7 min (run 34755997103). Browser-full: 18.0 min on every push to main (run 35780709940) plus 14.5 min nightly (run 34932091760)". The verifier regenerated all four values with summarize-ci.py, and they match 214-BASELINE.md sections 2 and 5 (lines 106, 107, 248, 253). The pre-phase "~9 min" / "~17 min" wording is gone, and the checker enforces both the new values and the absence of the old wording. |

### Plan must-have truths

| Plan | Truths | Status | Evidence |
|------|--------|--------|----------|
| 214-01 | 8 | 8/8 ✓ (regression check) | summarize-ci.py and the check scripts are unchanged. `jobs --min 10` passes for PR and push in the gate. |
| 214-02 | 9 | 9/9 ✓ (regression check) | facts.json changed additively only. The checker changed additively only (a new wall section; the earlier assertions are byte-unchanged). The bad-streak fixture still fails on `flake_fast_fail_first` / `flake_fast_fail_streak` only. |
| 214-03 | 6 | 6/6 ✓ (regression check) | inert-share.py and the allowlist are unchanged; the self-test passes. |
| 214-04 #1 | PROJECT.md states the four measured wall-time p50s with run IDs; the approximate bullet is gone | ✓ VERIFIED | Same as G2 above (deduplicated). |
| 214-04 #2 | facts.json holds the four p50 values and run IDs, derived offline by `measure-base02.sh wall`, with commands recorded, and no pre-existing key changed | ✓ VERIFIED | facts.json has 10 new keys (`ci_wall_{pr,push}_p50_{s,min,run}`, `browser_full_{push,schedule}_p50_{min,run}`), 10 `.commands` entries and `wall_regenerate`. The verifier re-ran the step: exit 0 and a byte-identical facts.json (sha fb3a1005 both times), so it is idempotent and reproduces the committed values. The step fails closed if it matches zero p50 rows or more than one. |
| 214-04 #3 | The checker asserts the four value+run-ID literals from facts.json via jq and guards against the stale wording | ✓ VERIFIED | `check-project-baseline.sh` builds each wall `expect` with `fact .ci_wall_*`; there are no hard-coded numbers. The `stale_wall_wording` loop covers "PR ~9 min" and "~17 min on every push". Mutation `PR 10.4 min` → `MISSING: ci_wall_pr_p50`, exit 1. Mutation `push ~10 min` + `~14 min nightly` → `MISSING: ci_wall_push_p50` and `MISSING: browser_full_schedule_p50`, exit 1. |
| 214-04 #4 | The stale-wall fixture fails with `stale_wall_wording` and `ci_wall_pr_p50` and no non-wall label; bad-streak fails only on flake labels | ✓ VERIFIED | The stale fixture's output is exactly: the 4 wall labels plus 2 `stale_wall_wording` lines, exit 1, and no other label. Bad-streak output is exactly `flake_fast_fail_first` and `flake_fast_fail_streak`, exit 1. |
| 214-04 #5 | verify-phase.sh exits 0 and asserts each negative fixture fails for its named reason | ✓ VERIFIED | `run_fails_with` requires a non-zero exit AND a `grep -F` match on the reason. Bad-streak is asserted on `MISSING: flake_fast_fail_first` and stale-wall on `MISSING: stale_wall_wording:`. The old `run_fails` is removed. The gate exits 0. |

**Score:** 32/32 truths verified (0 present-but-behavior-unverified). The checker and fixture truths are behavioral, and they were exercised by running the scripts on fixtures and mutated copies, not by presence checks alone.

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `214-BASELINE.md` | ✓ VERIFIED | Unchanged since the initial verification; the gate passes |
| `tools/measure-base02.sh` (`wall` step) | ✓ VERIFIED | Offline, fails closed, idempotent, commands repo-relative |
| `raw/base02/facts.json` | ✓ VERIFIED | Additive wall keys; the values regenerate exactly |
| `tools/check-project-baseline.sh` | ✓ VERIFIED | Wall section plus stale-wording guard, all values read from facts.json |
| `tools/fixtures/project-stale-wall.md` | ✓ VERIFIED | Single-cause negative fixture (only the wall bullet reverted) |
| `tools/fixtures/project-bad-streak.md` | ✓ VERIFIED | Wall bullet updated, so it now fails on flake labels only |
| `tools/verify-phase.sh` | ✓ VERIFIED | 12 checks, reason-asserting negative tests, exit 0 |
| `.planning/PROJECT.md` | ✓ VERIFIED | All six baseline facts match measurement; Out of Scope unchanged |
| Other plan 01-03 tools | ✓ VERIFIED | Unchanged; exercised by the gate |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| raw/ci (manifest + runs) | raw/base02/facts.json | `measure-base02.sh wall` → summarize-ci.py → merge_facts | ✓ WIRED (re-run reproduced the file byte for byte) |
| raw/base02/facts.json | PROJECT.md Current Milestone region | check-project-baseline.sh `expect` built with jq | ✓ WIRED (the mutations fail with the named labels) |
| verify-phase.sh | checker + both negative fixtures | `run` / `run_fails_with` | ✓ WIRED |
| Plan 01-03 links (collector → manifest, summarizer → doc, checkers → doc, allowlist → section 6) | | | ✓ WIRED (regression: files unchanged, gate green) |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| PROJECT.md wall bullet | 4 p50s + run IDs | facts.json ← summarize-ci.py over committed raw/ci job timestamps | Yes (regenerated) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase gate | `bash .../tools/verify-phase.sh` | 12 PASS, exit 0 | ✓ PASS |
| Wall p50s regenerate | `summarize-ci.py wall` (PR, push) and `workflow-cost` (browser-full push, schedule) | 629 s / 640 s / 18.0 min / 14.5 min with the cited run IDs | ✓ PASS |
| Facts regenerate offline, idempotent | `measure-base02.sh wall` (facts.json backed up and restored) | exit 0, identical sha fb3a1005 | ✓ PASS |
| Pre-existing facts intact | jq merge-equality against `28238181:facts.json` | true; no keys removed | ✓ PASS |
| Stale-wall fixture | `check-project-baseline.sh fixtures/project-stale-wall.md` | 4 wall MISSING + 2 stale_wall_wording, exit 1 | ✓ PASS |
| Bad-streak fixture | `check-project-baseline.sh fixtures/project-bad-streak.md` | only flake_fast_fail_first/_streak, exit 1 | ✓ PASS |
| Drift mutations | sed-mutated PROJECT.md copies in mktemp | named MISSING labels, exit 1 | ✓ PASS |
| Out of Scope identity | awk extract diff vs ff8e53e9 | identical | ✓ PASS |
| PROJECT.md one-line change | `git diff 28238181 HEAD -- .planning/PROJECT.md` | single -1/+1 hunk (wall bullet) | ✓ PASS |
| No product code | `git diff --quiet ff8e53e9 -- mix.exs mix.lock bench/mix.lock examples/threadline_phoenix/mix.lock .github test lib` | exit 0 | ✓ PASS |
| Commits exist | `git show --stat 313db847 6d494efc edc7f666` | 3 commits; file lists match 214-04 SUMMARY key-files | ✓ PASS |

### Probe Execution

The phase declares no `probe-*.sh`, so Step 7c was skipped. The phase gate `verify-phase.sh` ran instead (above).

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| BASE-01 | 214-01, 214-02, 214-03 | ✓ SATISFIED | SC1 and SC2 hold; the doc is unchanged and the gate is green. |
| BASE-02 | 214-02, 214-03, 214-04 | ✓ SATISFIED | All five enumerated sub-items still hold. The headline "PROJECT.md's baseline matches re-measured fact" now holds too, because the wall-time bullet is corrected and enforced (G2 closed). |

REQUIREMENTS.md maps only BASE-01 and BASE-02 to Phase 214, and plans claim both. There are no orphans. Note: the traceability table (REQUIREMENTS.md lines 154-155) still reads "Gaps Found" for both IDs, and the checkboxes are unticked. The orchestrator should update those after this verification. That is tracking state, not a goal gap.

### Anti-Patterns / Review Notes

| Finding | Severity | Why |
|---------|----------|-----|
| Debt markers in 214-04 added lines | none | No TBD/FIXME/XXX/TODO/HACK |
| The stale-wall gate asserts one reason (`stale_wall_wording`), not also `ci_wall_pr_p50` | ℹ️ Info | The plan truth only asks for a named reason. The verifier confirmed by hand that the fixture emits both and no non-wall label. |
| The stale-wording guard lists 2 of the 4 old phrases ("PR ~9 min", "~17 min on every push") | ℹ️ Info | The other two ("push ~10 min", "~14 min nightly") are still caught by the value+run-ID `expect` lines (mutation proof above). |
| Earlier REVIEW findings (WR-01..17) | ℹ️ Info (latent) | Unchanged from the initial verification; none is triggered by today's data. The existing 214-REVIEW.md predates 214-04. |
| WR-11 path count includes the phase's own PLAN files | ⚠️ Warning (carried) | Unchanged; Phase 217 should exclude or scrub them. Not a goal gap. |

### Human Verification Required

None. Every check was automated, per the project's zero-human-verification rule. The judgment-tier prohibitions are recorded in `prohibitions_flagged` as non-authoritative LLM-judge verdicts, and none was judged violated.

### Gaps Summary

Gap G2 is closed. PROJECT.md's `## Current Milestone` baseline now states the measured CI wall-time p50s with run IDs, and those values match 214-BASELINE.md sections 2 and 5 and regenerate from the committed raw/ci data. They are derived into facts.json by an offline, idempotent step and enforced by check-project-baseline.sh through value assertions and a stale-wording guard. A single-cause negative fixture proves the guard fires, and the gate asserts it fails for the named reason. None of the 27 previously verified truths regressed. The phase goal is achieved.

---

_Verified: 2026-09-26_
_Verifier: Claude (gsd-verifier)_
