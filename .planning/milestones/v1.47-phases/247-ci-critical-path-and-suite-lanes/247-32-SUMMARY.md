---
phase: 247-ci-critical-path-and-suite-lanes
plan: 32
subsystem: ci-partitioning
status: complete
tags: [ci, tail-queue, pre-registration, D-29, D-30, D-31, CI-02, CI-03, replay, preflight, escalation]
requires:
  - phase: 247-31
    provides: "contract-pinned TAIL_QUEUE_K=12 runner (runner_sha256 cec42f3a...), 247-B6-LOCAL.md self-test medians and local overheads"
provides:
  - "tools/tail_queue_replay.py: fetch (digest, frozen and PINNED_TSV_SHA256 verified, 168 pins), replay (P1-P5 from the runner's own static sets and tail-queue.tsv, boot-inclusive), predict (P6/P10 gate), preflight (P8 GO/NO_GO), --self-test (47 checks)"
  - "247-B6-PREDICTION.md B6-PREDICTION-JSON (threadline.phase247-b6-prediction/1): gate FAIL, ci03_expectation EXPECTED_MISS, predicted CI-02 491.8 s"
  - "247-B6-ESCALATION.md B6-ESCALATION-JSON (threadline.phase247-b6-escalation/1): stage prediction, 0 hosted runs, options 1-4, recommendation option 1"
  - "R3-IN-05 fixed in 247-REVIEW-DISPOSITION.md (open 2 -> 1)"
affects: ["247-33 (NOT RUN; precondition requires gate PASS)", "247 verification", "maintainer CI-03 scope decision"]
actuals:
  tokens: 35400
  tasks: 2
  commits: 3
plan_head_before: cfa2181eaf4322199b88aeb8c0fea5ee26cc1668
plan_head_after: 1f1ede4822c8727be51399cc78f598b18da52612
tech-stack:
  added: []
  patterns:
    - "Pre-registration as code: the TQ-PREREG block is extracted from the plan at the pre-registration commit and must equal the current plan; the verdict is computed by a committed tool from one replay per overhead point"
    - "Three-layer input pinning: API zip digest, frozen manifest, in-tool PINNED_TSV_SHA256 printed once by --print-pins and then enforced"
    - "Preflight log parsing scoped to the `##[group]Run mix verify.test_partitioned` step, so self-test output can never count"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/tail_queue_replay.py
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-PREDICTION.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-ESCALATION.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-32-SUMMARY.md
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW-DISPOSITION.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
decisions:
  - "D-29 gate computed FAIL on component (a): worst 8 s/claim replay current 1.063714, min 1.101163, latest 1.106776 (> 1.08); component (b) true (predicted CI-02 491.8 s <= 510)"
  - "Per P7: no push, PR or cohort; Plan 33 NOT RUN; escalation recommends accepting CI-03 as unmet-but-bounded with a measured-trigger seed"
metrics:
  duration: "~13 min"
  started: 2026-10-28T18:15:56Z
  completed: 2026-10-28T18:29:00Z
---

# Phase 247 Plan 32: B6 tail-queue pre-registration Summary

**A hash-pinned, stdlib-only replay of the runner's own K=12 tail queue over 168 B3–B5 timing TSVs gave a pre-registered gate verdict of FAIL. The current lane replays at ≤ 1.064, but min (1.101) and latest (1.107) exceed 1.08 at 8 s per claim. B6 therefore stops with zero hosted spend, and an escalation is recorded.**

## Outcome

| Item | Value |
|---|---|
| Gate | **FAIL** |
| `gate_components` | `replay_worst_le_1_08: false`, `ci02_predicted_le_510: true` |
| Worst replay at 8 s (per lane) | current 1.063714, min 1.101163, latest 1.106776 |
| Runs above 1.08 | min 40450801580 (B4) 1.101; latest 40436597341 (B3) 1.107, 40449332597 (B4) 1.107, 40692111621 (B5) 1.100, 40695763585 (B5) 1.086 |
| Worst at 4 s (informational) | current 1.049, min 1.069, latest 1.098 |
| P10 predicted CI-02 median | 457 + 19.837 + 15 = **491.8 s** (≤ 510; `ci02_expectation` EXPECTED_PASS) |
| `ci03_expectation` | EXPECTED_MISS |
| Hosted runs spent | 0 |
| Pre-registration commit | 6a1e8a16 (TQ-PREREG unchanged in the current plan) |
| runner_sha256 / tool_sha256 | cec42f3a… / 91f91b13… |

The escalation (`247-B6-ESCALATION.md`) recommends option 1: accept CI-03 as unmet-but-bounded, with a measured-trigger seed. CI-02 already passes at a 457 s median. The current lane overshoots 1.15 by 0.01–0.02. The model's per-run error is about ±0.05–0.13, as wide as the gap between the gate and the limit. The runner-up, option 2, is a separately pre-registered tail queue on the current lane only. That option would need its own budget grant and a disclosure that its lane subset was chosen after this replay.

## Tasks

| Task | Commit | Result |
|---|---|---|
| 1 (tracer): build `tail_queue_replay.py`, pin TSVs, single-run tracer | b25c3c29, 3508bd6a | Self-test passes (47 checks). The fetch checked 42 zips against their digests, 84 TSVs against the frozen pins and 168 against the in-tool pins, with 0 unavailable. Tracer: current lane, run 40692111621 → queue 1.050945, measured 1.17, K=12. test/ and bin/ untouched. R3-IN-05 is fixed (`open:` 1). Task 1 `<verify>` re-run end to end: pass. |
| 2: one replay at 8000 ms and one at 4000 ms, prediction, FAIL branch | 1f1ede48 | Prediction and escalation committed. ROADMAP ticks 247-32 and marks 247-33 NOT RUN. REQUIREMENTS and STATE were hand-edited (no CI-0x marked complete). Task 2 `<verify>`, a fresh fetch and replay reproducing every ratio within 0.0005: pass. |

## Deviations from Plan

### Auto-added

**1. [Rule 2 - Correctness] Added a `predict` subcommand to the tool.**
- **Found during:** Task 1.
- **Why:** The orchestrator requires that "the gate outcome is whatever the committed tool computes." The plan listed only fetch, replay, preflight and `--self-test`, which would have left the P6/P10 arithmetic to an uncommitted script.
- **What it does:** `predict` reads the two full replays, the fetch record and 247-B6-LOCAL.md. It checks the TQ-PREREG block at the pre-registration commit against the current plan, and it emits the whole prediction JSON. The gate arithmetic (`gate_of`) is pure and covered by self-test cases (PASS, a FAIL at 1.081, a FAIL at 510.1 s).
- **Files:** `tools/tail_queue_replay.py`. **Commit:** b25c3c29.

**2. [Rule 2 - Correctness] Scoped preflight parsing to the `Run tests` step.**
- **What:** P8 parsing reads only the lines between `##[group]Run mix verify.test_partitioned` and the next `##[group]Run ` line. Within that section it requires exactly one `| max/min |` row and exactly one well-formed `tail queue K=` line.
- **Why:** This ensures the "Prove the gate goes red" self-test step can never contribute claim or ratio lines. The step marker was confirmed against a real B5 job log (read-only) before coding.
- **Fail-closed rule:** a malformed claim line, a missing step, an `n/a` ratio or K ≠ 12 gives NO_GO.
- **Commit:** b25c3c29.

**3. [Rule 1 - Bug] Fixed two defects in the tool before its first commit.**
- **Unicode escapes:** the Write tool turned the BOM and Arabic-Indic digit escape sequences (backslash-u feff, 0663 and 0665) into literal characters. They were restored to ASCII escapes, and the tool is pure ASCII.
- **fetch's empty-directory check:** the check rejected the verify's own `>"$d/fetch.json"` redirect. It now rejects existing directories only.

### Not deviations

- The gate FAIL is the pre-registered outcome, not a plan failure. K, overhead, runs, the model and the thresholds were not changed after the numbers appeared.
- The `state.*` handlers were not called. STATE.md, ROADMAP.md and REQUIREMENTS.md were hand-edited and hand-checked, per CLAUDE.md and the plan's FAIL branch. `completed_plans` went from 55 to 56 of 58.
- The research-then-recommend fan-out was not available to this executor (no subagent tool). The escalation's recommendation rests on 247-B6-REMEDY-RESEARCH.md and the committed replay, and says so.

## Known Stubs

None.

## Next

A maintainer CI-03 scope decision on `247-B6-ESCALATION.md` (options 1–4; option 1 recommended). Plan 33 does not run. Phase 247 verification follows the decision.

## Self-Check: PASSED

- FOUND: tools/tail_queue_replay.py, 247-B6-PREDICTION.md, 247-B6-ESCALATION.md
- FOUND commits: b25c3c29, 3508bd6a, 1f1ede48 (all ancestors of HEAD)
- Both task `<verify>` blocks passed verbatim. Repo hygiene is green.
