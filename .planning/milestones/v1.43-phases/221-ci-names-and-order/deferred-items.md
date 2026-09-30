# Phase 221 deferred items

## From 221-01

- **`mix verify.credo` is red before this phase.** At the plan base (9ca43996), credo reports two
  `Function body is nested too deep (max depth is 2, was 3)` findings in
  `test/threadline/ci_workflow_parity_contract_test.exs`, in `every_lane_step_error/3` and
  `image_scan_units/1`. Neither function is touched by 221-01. Both came in with the 220 work (77ff2392,
  a039aff4, then the parsed-YAML rewrite d7d44fd1), none of which is on a remote branch yet. 221-01's own credo finding (`gate_step_errors/1` complexity 11)
  was fixed in a8a53c3f, so the plan adds no new credo findings. Fix before landing: the
  `verify-credo` CI lane runs the same check.

  **RESOLVED 2026-09-29 in 7ebb66ad** (orchestrator): extracted `lane_step_runs?/2` and `doc_scan_units/2`; `mix verify.credo` clean, contract files 72/0. The landing must cherry-pick 7ebb66ad right after d7d44fd1.
  status: acknowledged
