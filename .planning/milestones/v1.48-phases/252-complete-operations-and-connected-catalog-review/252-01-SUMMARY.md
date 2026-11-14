---
phase: 252-complete-operations-and-connected-catalog-review
plan: "01"
subsystem: ui
tags: [phoenix, retention, authorization, preview, exact-pid]
requires:
  - phase: 251
    provides: "Accepted investigation/inspection source and brand shell"
provides:
  - "Read-only Retention estimate with safe pending/error/zero/disabled-cleanup states"
  - "Original-PID/repo/schema/sleep guarded worker acceptance and captured-target audit"
  - "Deterministic revocation/cancel/restart/policy-read races and current declaration mappings"
affects: ["252-02", "252-03", "Phase253 migration notes"]
tech-stack:
  added: []
  patterns: ["Reauthorize after asynchronous reads before disclosing counts", "Guard the original worker target without name relookup"]
key-files:
  created: [.planning/phases/252-complete-operations-and-connected-catalog-review/252-PAIR-EVIDENCE.md]
  modified:
    - lib/threadline/retention/pruner.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - test/threadline/retention/pruner_test.exs
    - test/threadline/retention_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/fixtures/operator_surface/route-inventory.json
    - test/fixtures/operator_surface/source-surface-checklist.json
    - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
    - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
key-decisions:
  - "Keep trigger/0 compatible and add only undocumented worker coordination"
  - "Hold successful preview only on the server; validate current policy/target and authorization before disclosure and before audit"
  - "No production source pollution to satisfy generic inventory scanning"
patterns-established:
  - "Block real query completion to test revocation during each sequential count"
  - "Include the actual independent declaration owner when source controls change"
requirements-completed: []
actuals:
  tokens: null
  executor_usage: null
  managed_executor_exit: 1
  parent_continuation_seconds_at_summary: 1139.87
  tasks: 3
status: complete
completed: 2026-11-13
coverage:
  - id: D-02-D-05
    description: "Transient honest estimate, exact target and deliberate server-held confirmation"
    verification:
      - kind: integration
        ref: "69 selected tests and one property; actual logs reconciled in pair evidence"
        status: pass
    human_judgment: false
  - id: D-07-D-09
    description: "Bound unchanged baseline, supported checkout and coupled independent mappings"
    verification:
      - kind: integration
        ref: "34 source/rendered contracts and33 Node cases; four before captures"
        status: pass
    human_judgment: false
---

# Plan01 — Preview before pruning the exact store

Authorized operators can read an honest transient estimate, then deliberately confirm against the same captured worker PID/repo/schema/options. The original preview stays server-held; invalid/forged, denied, failed, canceled, restarted or changed-policy paths cannot establish confirmation or retarget a worker. Sequential counts carry actual generated UTC time and an explicit estimate/batch/cutoff caveat; disabled cleanup is not represented as zero eligible. Audit writes use the validated target before guarded acceptance. Existing trigger/0 behavior, public APIs, configuration, storage schema and locks are unchanged.

[Evidence](252-PAIR-EVIDENCE.md) retains source/runtime/data/tool custody, four before scenes, the fail-first matching tracer, selected runs and failures. Current source/domain/LiveView sampling passed69 tests and one property, four inventory/rendered owners passed34 cases, and the semantic/CI Node owners passed33 with no skipped/canceled cases. Compilation with warnings-as-errors and affected formatting passed. Source is not yet browser-reviewed after these changes; Plan03 owns mounted/reconnect/after proof, and Plan04 owns independent reviews/goal acceptance. ADM-24 is not marked wholly complete here.

## Task commits

- Task1: `2bdfa123` — read-only preview, same-target coordination, typed audit/run tracer and bound baseline.
- Task2: `331f5039` — count meanings, actual no-write checks, deterministic revoke/cancel/restart/policy races, target/failure controls and existing non-vacuous mutation negatives.
- Task3: `fa20eed2` — actual changed controls/semantic anchors, negative mapping and carried251 checklist reconciliation.

## Deviations and lessons

The executor repeated roughly five minutes of unchanged intake without tracked edits/captures. Its exit1 and log remain preserved; the parent continued the same supported GSD checkout. Do not repeat that intake for Plan02/03. The source checklist owner was missing from the planned test selection; adding it exposed carried251 declarations/removals as well as the current Retention changes. These mapping defects were fixed without altering production behavior or discarding IDs. Existing earlier acceptance remains historical with this coverage limitation, not a new current declaration pass.

One docs-update command failed from a doubled relative checkout path while a later command masked its exit and committed the already-tested source. The record was repaired; subsequent multi-step commands use set-e and explicit roots. No comparable speedup, token usage, full-root result, native clipboard outcome or hosted acceptance is inferred. Keep the retained [retrospective](../../../research/2026-11-12-autonomous-run-retrospective.md) in progress through the actual end.

## Threat flags and limits

Independent security review is pending. No risk was accepted. This plan's descriptorless estimate-transparency prohibition remains flagged-unverified in the engine; real count/copy behavior is separately tested. No native clipboard/foreground/full-root repeat/hosted action was performed. Package1.1.0 and PhoenixStorybook1.2.0 remain unchanged. Worker death after a successful audit can leave an audited request without a run; guarded dispatch never retargets a replacement. Phase253 owns broad inclusive/docs/package/canonical readiness.

## Self-check

All three task commits exist on this GSD branch, current source contracts and meaningful negatives passed, and before evidence remains retained. This is Plan01 completion only; no phase or milestone completion is claimed.
