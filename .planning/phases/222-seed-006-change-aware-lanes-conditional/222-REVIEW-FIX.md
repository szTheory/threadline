---
phase: 222-seed-006-change-aware-lanes-conditional
fixed_at: 2026-09-29T00:00:00Z
review_path: .planning/phases/222-seed-006-change-aware-lanes-conditional/222-REVIEW.md
iteration: 2
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 222: Code Review Fix Report

**Fixed at:** 2026-09-29
**Source review:** .planning/phases/222-seed-006-change-aware-lanes-conditional/222-REVIEW.md
**Iteration:** 2

**Summary:**
- Findings in scope: 4 (WR-01, WR-02, WR-03, IN-01)
- Fixed: 4
- Skipped: 0

## Fixed Issues

### WR-01: check-citations.py's widened phase-number exemption can mask a real uncited figure equal to 220/221/222

**Files modified:** `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py`
**Commit:** 763be9f8
**Applied fix:** Replaced the single broad `\b(?:21[4-9]|22[0-2])(?:-0\d)?\b` exemption (which stripped a *bare* 220/221/222 unconditionally) with three narrower exemptions: (1) plan-suffixed forms only (`222-01`), (2) the word "phase" immediately before the number (case-insensitive, matches the file's actual lowercase usage), and (3) a phase number immediately followed by a requirement/decision ID (`220 D-07`). A bare occurrence like "saving was 220 billed min" with no other citation on the line is no longer silently exempted. Updated the module docstring to describe the narrower rule.

Verification: `python3 tools/check-citations.py --self-test` still passes both fixtures (cited.md exit 0, uncited.md exit 1); a synthetic check of the exact false-collision scenario described in the finding (`Saving was 220 billed min, no citation here.`) now correctly fails with exit 1 (previously would have passed as cited); the real check against `222-DECISION.md` (which is where the actual "phase 214"/"220 D-07" wording lives) still passes with the narrowed regex, and this is exercised by `verify-phase.sh --close` check 12. No figure in `222-DECISION.md` changed.

### WR-02: `since-214` window header truncates the sub-day lower bound to a whole day, making the printed range look one day wider than it is

**Files modified:** `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py`
**Commit:** c5030688
**Applied fix:** In `summarize()`'s two-sided bounds branch, print the full ISO timestamp for any bound that is not exactly midnight (`lo`, `...T00:00:00Z`) or exactly end-of-day (`hi`, `...T23:59:59Z`), instead of unconditionally truncating both to `[:10]`. `since-214`'s header now reads `window: since-214 (mergedAt 2026-09-26T17:21:10Z to 2026-09-29; ...)` instead of the misleading `mergedAt 2026-09-26 to 2026-09-29`. This is display-only: `in_window()` (the actual filter) already used the full timestamp, so no PR classification, count, or `222-DECISION.md` figure changes — confirmed by `inert-share.py --self-test` and by `verify-phase.sh`'s adjacency check (`n(at-214)=40 + n(since-214)=9 = n(all)=49`, unchanged) and determinism check, both still passing.

### WR-03: Dead/redundant check in `run_out_contains` — the exact-line match can never change the outcome

**Files modified:** `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh`
**Commit:** 45a34847
**Applied fix:** Dropped the redundant `! grep -qxF -- "$needle" "$OUT" &&` clause — `grep -qxF` (whole-line match) is a strict subset of `grep -qF` (substring match), so the clause could never change the branch outcome. The substring check alone (`! grep -qF -- "$needle" "$OUT"`) is the tool's actual documented contract ("output must contain needle").

### IN-01: `verify-phase.sh`'s per-window determinism loop and citation self-tests are the only automated coverage for the new `--last N` and `at-214`/`since-214` windows; no test exercises a boundary PR merged in the same second as the `at-214` cutoff

**Files modified:** `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py`
**Commit:** 2b5c2272
**Applied fix:** Added two self-test cases to `inert-share.py --self-test`: (1) two synthetic PRs both merged at `"2026-09-26T17:21:09Z"` (the `at-214` cutoff second), asserting both are `in_window(..., "at-214")` and neither is `in_window(..., "since-214")`; (2) a synthetic PR merged one second later at `"2026-09-26T17:21:10Z"` (the `since-214` lower bound), asserting it lands only in `since-214` and not `at-214`. This directly exercises the boundary behavior the finding flagged as untested — a same-second collision at the cutoff would now fail the self-test rather than passing silently.

Verification: `python3 tools/inert-share.py --self-test` passes all 11 cases including the two new boundary checks; `verify-phase.sh` (default and `--close`) both still pass all checks, exit 0. No figure in `222-DECISION.md` changed — this fix only adds test coverage in `inert-share.py`, it does not touch classification logic, output formatting, or any measured window's PR set.

## Skipped Issues

None — all in-scope findings were fixed.

## Verification

Ran the phase's own verification harness directly in the main checkout on `milestone/v1.43` (iteration 2; `workflow.use_worktrees` handling not applicable — worked directly on the branch as instructed), after the IN-01 fix was applied and committed:

```
python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --self-test
bash .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh
bash .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh --close
```

Self-test: all 11 cases PASS. `verify-phase.sh`: all 13 (default mode) / 19 (`--close` mode) checks PASS, exit 0. No network or `gh` access was needed or used — the harness is fully offline (committed `raw/` data, git diff against a local commit, no live GitHub calls).

Iteration 1's WR-01/WR-02/WR-03 verification (run inside an isolated fix worktree based on `milestone/v1.43` at commit `58807820`) is preserved above unchanged; iteration 2's IN-01 verification ran in the main checkout per the current run's instructions.

No figure cited in `222-DECISION.md` changed as a result of any fix across both iterations (WR-01 and WR-03 change classification logic and gate wording only in ways that keep existing PASS/FAIL outcomes byte-identical on today's data; WR-02 is display-only per its own finding; IN-01 adds self-test coverage only).

---

_Fixed: 2026-09-29_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
