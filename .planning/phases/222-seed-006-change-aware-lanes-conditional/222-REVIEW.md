---
phase: 222-seed-006-change-aware-lanes-conditional
reviewed: 2026-09-29T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py
  - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-allowlist.txt
  - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/collect-ci-runs.sh
  - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/summarize-ci.py
  - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py
  - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py
  - .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh
  - .planning/phases/222-seed-006-change-aware-lanes-conditional/222-DECISION.md
  - .planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md
findings:
  critical: 0
  warning: 3
  info: 1
  total: 4
status: issues_found
---

# Phase 222: Code Review Report

**Reviewed:** 2026-09-29
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

This phase ships no product code: it is phase-local measurement tooling (stdlib
Python + bash) plus the resulting decision record and seed closure. The four
"copy" tools (`inert-share.py`, `inert-allowlist.txt`, `summarize-ci.py`,
`check-citations.py`, `collect-ci-runs.sh`) were diffed against their 214/219
originals — the diffs are limited to path retargets and, for `inert-share.py`
and `check-citations.py`, additive new windows/modes and a widened phase-number
regex. `remeasure-222.py` and `verify-phase.sh` are new.

I re-ran every tool read-only against the committed `raw/` data:
`inert-share.py --self-test`, `remeasure-222.py --self-test`,
`check-citations.py --self-test`, `verify-phase.sh` (default mode, no
`--close`), and each of `inert-share.py --window {all,at-214,since-214,30d-now}
--last 20`, `remeasure-222.py minute-gate --window 30d-now`,
`remeasure-222.py ceiling --window 30d-now`, `remeasure-222.py skip-saving`.
Every number these commands print matches the corresponding figure in
`222-DECISION.md` exactly (n=49/40/9/28, k=1/1/0/0, denominator D=1553 billed
min, skip-saving=19 billed min, ceiling rows 0/6/15 of 28 at 0.0%/7.3%/18.4%,
verdict CLOSE). `grep` confirmed no write-capable `gh` invocation exists in any
tool, and no tracked file in the phase dir under review leaks a real
home-directory path or username. I found no defect that makes the BUILD/CLOSE
verdict itself wrong, vacuous, or unreproducible — the gate math
(`5*k>=n`, `10*saving>=D`, half-up `pct1`), the fail-closed classification, and
the window-boundary adjacency (`at-214` + `since-214` = `all`, confirmed
40+9=49) all check out. The findings below are quality/robustness issues in the
tooling, not verdict-correctness defects.

## Warnings

### WR-01: check-citations.py's widened phase-number exemption can mask a real uncited figure equal to 220/221/222

**File:** `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py:31`
**Issue:** The 214/219 original exempted only `\b21[4-9](?:-0\d)?\b` (phase numbers 214–219) from the "must be cited" rule. The 222 copy widens this to `\b(?:21[4-9]|22[0-2])(?:-0\d)?\b`, which also matches the bare standalone values `220`, `221`, and `222` — not just phase/plan citations like `222-01`. Because the exempt-token substitution runs before the "does any digit remain" check, a genuine uncited figure that happens to equal exactly `220`, `221`, or `222` (e.g. "saving was 220 billed min") would be silently stripped and the line would pass as cited even with no `run <id>` or backticked command anywhere on it. I confirmed via `grep` that no such collision currently exists in `222-DECISION.md` (all occurrences of 220–222 in that file are genuine phase references), so this has not produced a wrong PASS today, but the tool's job is exactly to catch this class of thing and the widened range measurably increases the false-exemption surface versus the file it was copied from.
**Fix:** Require the phase/plan token to be non-bare, e.g. only exempt when followed by a plan suffix or adjacent to a phase-referencing word, or narrow the regex back to matching `-0\d` suffixed forms only (`2\d\d-0\d`) and handle bare phase mentions (`Phase 222`, `220 D-07`) via a separate pattern anchored on the word "Phase" or a preceding dash-number context, so a bare `220`/`221`/`222` used as an actual measurement is never silently exempted.

### WR-02: `since-214` window header truncates the sub-day lower bound to a whole day, making the printed range look one day wider than it is

**File:** `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py:144`
**Issue:** `summarize()` builds the human-readable bounds string as `f"mergedAt {lo[:10]} to {hi[:10]}"` when both `lo` and `hi` are set. For the `since-214` window, `lo = "2026-09-26T17:21:10Z"`, so `lo[:10]` is `"2026-09-26"`. The printed header reads `window: since-214 (mergedAt 2026-09-26 to 2026-09-29; ...)`, which reads as an inclusive whole-day range starting 2026-09-26 — but the actual filter (`in_window`, which correctly uses the full timestamp) excludes all of 2026-09-26 except the last ~7 hours. A reader trusting the printed bounds (rather than re-deriving them from the docstring) would over-count the window by nearly a full day. The `at-214` window sidesteps this by using "on or before"/"on or after" phrasing for one-sided bounds, but the two-sided `since-214` case uses the ambiguous "to" phrasing with a sub-day boundary.
**Fix:** When `lo` (or `hi`) has a non-midnight time component, print the full timestamp instead of truncating to `[:10]` for that bound, e.g. `f"mergedAt {lo} to {hi[:10]}"`, or special-case `since-214`'s header to say "mergedAt after {lo}" explicitly.

### WR-03: Dead/redundant check in `run_out_contains` — the exact-line match can never change the outcome

**File:** `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh:60`
**Issue:** `elif ! grep -qxF -- "$needle" "$OUT" && ! grep -qF -- "$needle" "$OUT"; then fail ...`. `grep -qxF` (whole-line match) implies `grep -qF` (substring match) — any line that equals the needle exactly also contains it as a substring. So whenever the first `! grep -qxF` is false (i.e., the exact-line match succeeded), the second `! grep -qF` is necessarily also false, and the `&&` is redundant: the branch condition is logically equivalent to just `! grep -qF -- "$needle" "$OUT"`. This isn't a correctness bug (the gate still behaves as intended) but it's dead logic that suggests the author meant something different (e.g. wanted the exact-line check to be sufficient on its own as a stricter pass condition) and it will confuse a future maintainer trying to understand why both greps exist.
**Fix:** Drop the first `grep -qxF` clause, or if an exact-line requirement was actually intended for some callers, split into two functions (`run_out_equals` / `run_out_contains`) rather than combining both greps under one `&&`.

## Info

### IN-01: `verify-phase.sh`'s per-window determinism loop and citation self-tests are the only automated coverage for the new `--last N` and `at-214`/`since-214` windows; no test exercises a boundary PR merged in the same second as the `at-214` cutoff

**File:** `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py:57-63`
**Issue:** The `at-214`/`since-214` split is defined as "on or before 17:21:09Z" / "on or after 17:21:10Z" specifically to be disjoint-but-adjacent for the one dataset in hand. There's no unit test (in `inert-share.py --self-test` or elsewhere) asserting that two PRs merged in the exact same second would both land in the same window rather than being split across the boundary inconsistently — the current self-test only checks that the two bound constants themselves are ordered (`at214_hi < since214_lo`), not behavior on a same-second collision. Low risk since the windows are frozen constants derived from a real, already-observed PR set (not a live boundary), but worth a one-line self-test case if this tool is ever reused for a future phase's before/after split.
**Fix:** Add a self-test case with two synthetic PRs both merged at `"2026-09-26T17:21:09Z"`, asserting both are `in_window(..., "at-214")` and neither is `in_window(..., "since-214")`.

---

_Reviewed: 2026-09-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
