---
phase: 247-ci-critical-path-and-suite-lanes
plan: 11
subsystem: ci
tags: [github-actions, matrix, contract-tests, mutation-controls, fan-in]
status: complete

requires:
  - "247-10 (browser E2E split into matrix legs + receipt fan-in, @needs_exemptions, @composed_name_jobs)"
  - "247-12 (D-11 partition balance; covered by this plan's ci.all gate)"
provides:
  - "rule=matrix-projects: the verify-example-browser matrix project list equals inventory votingProjects, in order"
  - "rule=leg-artifact-name: every leg upload-artifact name carries ${{ matrix.project }} (4 uploads read)"
  - "rule=receipt-unconditional, rule=receipt-needs, rule=matrix-fail-fast over parsed ci.yml"
  - "exact-list needs exemption controls: a second or different receipt need, or a leg gaining needs, reports rule=order-needs"
  - "composed_check_names/2 takes an ordered axis list; a project + shard matrix composes `(desktop-chromium, 1)` (D-08 fallback readiness, RESEARCH A4 assumed)"
affects: ["247-13 (Land B2: these rules ride the landing; the first live split runs check RESEARCH A4 only if the shard fallback is ever needed)"]

actuals:
  tokens: 4700     # chars/4 over the realized diff (git diff 7a83cc01..3613a9f4, 18621 chars)
  tasks: 2
  commits: 1
plan_head_before: 7a83cc011cd5cd74595506e6313ded9b717e8afe
plan_head_after: 3613a9f4e07520baa802691d694c1f395f333fe3

tech-stack:
  added: []
  patterns:
    - "Matrix composition is a product over an ordered axis list (first axis outermost). An exclude row must name exactly the axes and an include row must name every axis; any other shape composes nothing (fail closed)"
    - "Each new rule is a pure checker returning rule names, with a control table that refutes `mutated == input` before asserting the rule fires"

key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-11-SUMMARY.md
  modified:
    - test/threadline/browser_journey_evidence_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs

key-decisions:
  - "247-11: receipt-unconditional checks both ends of the gate. The receipt has no job-level `if:`, and ci-required keeps `if: always()`, needs the receipt and has no `allowed-skips` anywhere. A skipped receipt therefore reaches alls-green as a skip and fails it (T-247-22)."
  - "247-11: matrix axis values may be strings or integers (GitHub posts `shard: [1, 2]` as `1`, `2`). Single-axis composition is unchanged for the live string-valued matrices."
  - "247-11: axis order comes from the caller (the matrix's YAML key order), because the map reader cannot see key order. The two-axis naming `(desktop-chromium, 1)` stays an assumption (RESEARCH A4) until a live shard run shows it."

patterns-established:
  - "split_leg_errors/2 (evidence test) and browser_split_errors/1 (parity test) are pure over ci.yml text plus the decoded inventory, so mutation controls need no file writes"

requirements-completed: []  # CI-02 completes after the live split runs in 247-13

coverage:
  - id: D1
    description: "Mutation-controlled split assertions (D-07, D-07a, D-08 fallback helper)"
    requirement: CI-02
    verification:
      - kind: unit
        ref: "mix test browser_journey_evidence_contract_test.exs + ci_workflow_parity_contract_test.exs on ephemeral postgres:16: 62 tests, 0 failures (5 new tests, 13 mutation controls, 2 positive controls)"
        status: pass
      - kind: lint
        ref: "mix format --check-formatted; mix credo --strict on both files (no issues); bin/verify-repo-hygiene exit 0"
        status: pass
  - id: D2
    description: "Full local phase gate on the split + 247-12 rebalance"
    requirement: CI-02
    verification:
      - kind: integration
        ref: "DB_HOST=127.0.0.1 CI=true mix ci.all on ephemeral postgres:16, exit 0: 32 properties, 3376 tests, 0 failures, 3 excluded; 132 tests, 0 failures; 17 tests, 0 failures, 16 excluded; Dialyzer Total errors: 0; Playwright 418 passed, 56 skipped"
        status: pass

metrics:
  duration: "~35 min"
  completed: 2026-10-26
---

# Phase 247 Plan 11: Mutation-controlled browser split assertions and the full ci.all gate Summary

The contracts now stop the CI-02 split from silently losing a project leg, gaining a stray `needs`, sharing an artifact name across legs, failing fast, or letting a skipped receipt read green. Every new rule has a mutation control that fires it. `CI=true mix ci.all` is green on an ephemeral postgres:16.

## What changed

**`browser_journey_evidence_contract_test.exs`, new describe "CI-02 browser matrix legs"**
- `split_leg_errors/2` is pure over ci.yml text and the decoded inventory:
  - `rule=matrix-projects`: `jobs.verify-example-browser.strategy.matrix.project` equals the inventory `votingProjects`, in order, and the list is non-empty.
  - `rule=leg-artifact-name`: every `actions/upload-artifact@` step in the leg job has a `with.name` that contains `${{ matrix.project }}`. The live test also requires exactly 4 uploads (executed, discovered, timings, diagnostics), so the rule cannot pass with nothing to check.
- Controls, each refuting a no-op first and requiring valid YAML:
  - `mobile-chromium` dropped from the matrix.
  - The matrix reordered.
  - `route-capture` added to the inventory side.
  - The diagnostics artifact name stripped of the project.
  - The executed-report artifact name stripped of the project.

**`ci_workflow_parity_contract_test.exs`**
- `browser_split_errors/1`:
  - `rule=receipt-unconditional`: the receipt has no job-level `if:`, and ci-required has `if: always()`, lists the receipt in `needs` and has no `allowed-skips`.
  - `rule=receipt-needs`: the receipt's `needs`, read through `List.wrap`, equals `@needs_exemptions["verify-example-browser-receipt"]`.
  - `rule=matrix-fail-fast`: the legs' `strategy.fail-fast` is exactly `false`.
- Live test:
  - The exemption map is exactly `%{"verify-example-browser-receipt" => ["verify-example-browser"]}`, a single entry.
  - `ci_order_errors/1` is clean.
  - Positive control: a flow-list `needs: [verify-example-browser]` stays green.
- Mutation controls (8):
  - The receipt gains `if: success()`, or gains `if: ${{ always() }}`. Both trip receipt-unconditional.
  - ci-required drops the receipt need. Trips receipt-unconditional.
  - The receipt needs `[verify-example-browser, verify-test]`, or needs `verify-test`. Both trip receipt-needs and `job=verify-example-browser-receipt rule=order-needs`.
  - A leg gains `needs: verify-format`. Trips `job=verify-example-browser rule=order-needs`.
  - `fail-fast: true`, or `fail-fast` removed (GitHub then defaults it to true). Both trip matrix-fail-fast.
- `composed_check_names/2` accepts one axis or an ordered axis list, and `posted_lanes/2` builds the product. Unit case (no ci.yml change):
  - A `project` + `shard: [1, 2]` matrix composes `Example app browser E2E (desktop-chromium, 1)` … `(mobile-chromium, 2)`.
  - The single axis `project` over that matrix composes nothing.
  - A full exclude row removes one combination.
  - A partial exclude row fails closed.
  - The live job composes `@verify_example_browser_check_names` in both forms.

## Task 2: full gate

`DB_HOST=127.0.0.1 DB_PORT=<ephemeral> CI=true mix ci.all` ran on `postgres:16` with label `dev.threadline.plan=247-11`. It exited 0, and the plan's verify command (ANSI-stripped) passed. Decisive lines:

```
...strict: passed (0 warning(s) not gated)
32 properties, 3376 tests, 0 failures, 3 excluded
132 tests, 0 failures
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
17 tests, 0 failures, 16 excluded
  418 passed (5.6m)
  56 skipped
```

There was no Dialyzer PLT miss and no missing Playwright CLI. The gate found no ci.yml defect, so ci.yml is unchanged and Task 2 has no commit. The container was removed afterwards.

## Deviations from Plan

None. The plan executed as written. The planned grep baselines of 0 were stale for one check: 247-10 had already added the literal `"verify-example-browser-receipt" => ["verify-example-browser"]`, so that grep reads 1 from the start. This plan adds the exact-list mutation controls that make the literal binding.

## Known Stubs

None.

## Threat Flags

None. T-247-22 (skipped fan-in reads green) and T-247-28 (matrix drift, cross-leg artifact overwrite) are now mitigated by the mutation-controlled rules receipt-unconditional, matrix-projects and leg-artifact-name.

## Next

247-13: Land B2 (first live split runs).

## Self-Check: PASSED
- FOUND: test/threadline/browser_journey_evidence_contract_test.exs (`rule=matrix-projects` x4, `leg-artifact-name` x4)
- FOUND: test/threadline/ci_workflow_parity_contract_test.exs (`receipt-unconditional` x5, exemption literal x1)
- FOUND: commit 3613a9f4 on HEAD
