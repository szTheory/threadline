# Phase 247 B6 escalation — prediction stage (D-29/D-30)

The D-29 pre-registration gate in `247-B6-PREDICTION.md` computed **FAIL**, so under P7 the B6 attempt stops before any hosted spend. No push, PR or cohort ran, and Plan 33 halts at its precondition. One maintainer scope decision is needed (D-30).

## What failed

- **Component (a), the replay, is false.** At 8 s per claim, two lanes have runs above 1.08:
  - min: run 40450801580 (B4), 1.101163;
  - latest: runs 40436597341 (B3) 1.106776, 40449332597 (B4) 1.106514, 40692111621 (B5) 1.099813 and 40695763585 (B5) 1.086137.

  The current lane, the one that misses CI-03, passes with a worst of 1.063714. At 4 s per claim, which is informational only, the worst values are 1.049 on current, 1.069 on min and 1.098 on latest.
- **Component (b), the CI-02 margin, is true.** The predicted median is 491.8 s, against a 510 s ceiling.

## Standing, unchanged by this stage

- CI-02 PASS on B5: a 457 s median over five attempt-1 successes at main 824c2851.
- CI-03 MISS on B5: the current lane measured 1.17, 1.17 and 1.09; min and latest pass.
- CI-01 and CI-04 continuity holds.
- The tail-queue implementation (247-30/31) and the replay tool (247-32) are committed on `milestone/v1.47` only. They are not on main, and nothing was pushed.

## Recommendation

**Option 1: accept CI-03 as unmet-but-bounded, with a measured-trigger seed.** The JSON block below gives the rationale, the options and the evidence hashes.

Research note: this executor ran without a subagent fan-out. The recommendation rests on 247-B6-REMEDY-RESEARCH.md (three researcher clusters), the committed replay, and D-29/D-30. If the maintainer wants an independent fan-out before deciding, the next step is `/gsd-discuss-phase 247`.

<!-- B6-ESCALATION-JSON-BEGIN -->
{
  "schema": "threadline.phase247-b6-escalation/1",
  "stage": "prediction",
  "recorded": "2026-10-28",
  "reason": {
    "failed_components": ["replay_worst_le_1_08"],
    "gate_components": {"replay_worst_le_1_08": false, "ci02_predicted_le_510": true},
    "gate_max_ratio": 1.08,
    "overhead_ms": 8000,
    "worst_8000": {"current": 1.063714, "min": 1.101163, "latest": 1.106776},
    "runs_above_1_08": [
      {"lane": "min", "run": 40450801580, "cohort": "B4", "queue_ratio_8000": 1.101163},
      {"lane": "latest", "run": 40436597341, "cohort": "B3", "queue_ratio_8000": 1.106776},
      {"lane": "latest", "run": 40449332597, "cohort": "B4", "queue_ratio_8000": 1.106514},
      {"lane": "latest", "run": 40692111621, "cohort": "B5", "queue_ratio_8000": 1.099813},
      {"lane": "latest", "run": 40695763585, "cohort": "B5", "queue_ratio_8000": 1.086137}
    ],
    "predicted_ci02_median_s": 491.8,
    "ci02_gate_s": 510,
    "summary": "The all-lane K=12 tail queue at 8 s per claim replays above 1.08 on min (1 run) and latest (4 runs); the current lane passes at <= 1.064. The CI-02 component holds (491.8 s <= 510 s)."
  },
  "evidence": {
    "prediction": ".planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-PREDICTION.md",
    "prediction_sha256": "33fbbc3f4737e72929269e447a086ca99ef2444161a41d11137f5be804cefe09",
    "pre_registration_commit": "6a1e8a16b3ba550d225e4c42036448ea2631dab0",
    "runner_sha256": "cec42f3a4703c7902a5a6ba78d4fd5f4f2c38568c58fda93d1a8ac00573f1f9e",
    "tool_sha256": "91f91b13510f5027b6e7d3a4726b8092b1f44732d99881277a7c89ee76301dcb",
    "frozen_replay_sha256": "5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1",
    "tool": ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/tail_queue_replay.py",
    "tsv_count": 168,
    "unavailable": []
  },
  "options": [
    "1. accept CI-03 as unmet-but-bounded with a measured-trigger seed: verify phase 247 at 3/4 with CI-03 recorded MISS at its B5 measurement (current 1.17/1.17/1.09; min and latest pass) and CI-02 PASS (457 s); seed the remedy with a measured reopen trigger (for example a main CI-02 median above 510 s, or a current-lane median ratio above 1.20 over a measured cohort); keep the tail-queue commits out of any landing branch (they were never measured on CI) and name them, the replay tool and the preflight evaluator as the seed's ready candidate",
    "2. authorize a new, separately pre-registered cohort that enables the tail queue on the current lane only (K=12 on current, K=0 on min and latest, which already pass under the static assignment): it needs a runner change, a new plan, a new pre-registration and a hosted budget grant; the lane subset would be chosen after seeing these per-lane replays, so it is a disclosed post-hoc fork outside D-30's 'B6 is final'",
    "3. re-gate the existing all-lane tail queue at a looser replay bound (for example the CI-03 limit 1.15, which every replay meets) and run B6 as planned: this loosens a pre-registered gate after seeing the numbers, which voids the D-29 pre-registration (T-247-77) and is not recommended",
    "4. descope CI-03 from v1.47 entirely and move partition balance to a later milestone (v1.50 Measured performance), parking the tail-queue code on milestone/v1.47"
  ],
  "recommendation": {
    "option": 1,
    "choice": "accept CI-03 as unmet-but-bounded with a measured-trigger seed",
    "rationale": "The pre-registered rule did its job. It could not show that the all-lane tail queue keeps min and latest within 1.08 at 8 s per claim, so the B6 cohort must not spend. Every alternative that would still run a cohort chooses a lane subset (option 2) or a threshold (option 3) after seeing these numbers. That is the forking path D-29 exists to prevent, and D-30 already ruled out a B7. The miss is bounded and small in practice. CI-02, the critical-path gate that CI-03 serves, passes at a 457 s median, 83 s under 540. The current lane overshoots 1.15 by 0.01-0.02 in four of five B5 runs. The model's own per-run error (about +/-0.05-0.13) is as large as the gap between the 1.08 gate and the 1.15 limit, so no replay-only argument can rescue the attempt. A seed with a measured trigger keeps the remedy ready without spending hosted runs on an unregistered variant: the tail queue, the hash-pinned replay tool and the P8 preflight evaluator are all committed and self-tested. If the maintainer wants a remedy now anyway, option 2 is the strongest runner-up. It is the only variant whose replay clears 1.08 (current worst 1.064), but it needs its own pre-registration, which must disclose that the lane subset was chosen after this replay, and a fresh hosted budget grant."
  },
  "spent_hosted_runs": 0,
  "plan_33": "NOT RUN: halts at its precondition (gate FAIL)"
}
<!-- B6-ESCALATION-JSON-END -->

## Resolution — D-32 (append-only)

This section is appended after the escalation above. No earlier byte of this file changed.

- **Decision.** The maintainer chose option 2 on 2026-10-28: a separately pre-registered tail queue on the current lane only. It is recorded as D-32 in 247-CONTEXT.md, with the preflight bound amended by D-33 and the self-test cap measurement by D-34.
- **Plans.** Plans 247-34..36 carry it out:
  - 247-34 changes the runner: `lane_tail_k()` gives current 12, min 0 and latest 0. Its local proof is 247-B6-LOCAL-2.md.
  - 247-35 is the second pre-registration.
  - 247-36 lands the change, runs the preflight and runs the final B6 cohort.
- **Superseded.** 247-33 is superseded by 247-36 and was never run.
- **Records.** The second pre-registration is `247-B6-PREDICTION-2.md`. The round-1 prediction, 247-B6-PREDICTION.md, stays byte-unchanged (sha256 33fbbc3f4737e72929269e447a086ca99ef2444161a41d11137f5be804cefe09).
- **Final fallback.** If this round has any gate FAIL, preflight NO_GO, or CI-02/CI-03 miss, the outcome falls back to option 1 as final: CI-03 (or CI-02) is accepted as unmet-but-bounded, with a measured-trigger seed. There is no further round.

<!-- B6-ESCALATION-RESOLUTION-JSON-BEGIN -->
{
  "schema": "threadline.phase247-b6-escalation-resolution/1",
  "decision": "D-32",
  "chosen_option": 2,
  "decided": "2026-10-28",
  "plans": ["247-34", "247-35", "247-36"],
  "superseded": "247-33",
  "final_fallback_option": 1,
  "round1_prediction_sha256": "33fbbc3f4737e72929269e447a086ca99ef2444161a41d11137f5be804cefe09"
}
<!-- B6-ESCALATION-RESOLUTION-JSON-END -->

## D-32 round outcome (append-only)

This section is appended after the D-32 resolution above. No earlier byte of this file changed. Plan 247-37 derived the path mechanically from 247-LANDING.md, the absence of 247-B6-ESCALATION-2.md and the B6-GATE-JSON in 247-MEASUREMENT.md.

- **Path S (success).** Record: none, because no `247-B6-ESCALATION-2.md` exists on this path. B6 squash SHA: 11234b01defc09d0c4cf269925a976b954910eab (PR #99). The preflight was GO, CI-02 PASS (median 461 s) and CI-03 PASS (first three: current 1.06/1.02/1.02, min 1.06/1.07/1.06, latest 1.09/1.05/1.09). The option-1 fallback was not taken, no SEED-009 was written, and there is no further round.
