---
phase: 251-complete-investigation-and-inspection-screens
plan: "01"
subsystem: ui
tags: [phoenix, timeline, filters, navigation, focus]
requires:
  - phase: 250
    provides: "Accepted shared brand shell and ordinary investigation"
provides:
  - "Fail-closed original UI/saved-filter validation with compatible shared parser"
  - "Truthful retained-context recovery and stable preferred overlay focus"
  - "Source-bound matched changed-state and mounted keyboard proof"
affects: ["251-02", "Phase253 inclusive integration"]
tech-stack:
  added: []
  patterns: ["Validate original intent before canonicalization", "Freeze runtime and separate test-source identity"]
key-files:
  created:
    - .planning/phases/251-complete-investigation-and-inspection-screens/251-PAIR-EVIDENCE.md
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/timeline_live/helpers.ex
    - lib/threadline/operator_surface/live/timeline_live/filters.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/live/row_history_live.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - lib/threadline/operator_surface/ui/overlay.ex
    - examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts
key-decisions:
  - "Keep unknown-key dropping in the shared parser; reject unsafe original UI intent before canonicalization"
  - "Distinguish direct default entry, exact retained context and disclosed context loss"
  - "Remove redundant queued focus handlers instead of adding an ineffective selector guard"
patterns-established:
  - "Exact nonzero retries-disabled mounted outcomes plus immutable matched capsule identities"
requirements-completed: ["ADM-15", "ADM-19"]
actuals:
  tokens: null
  executor_usage: null
  managed_executor_exit: 1
  parent_continuation_seconds_at_summary: 6623.81
  tasks: 3
status: complete
completed: 2026-11-12
coverage:
  - id: D-01-D-03
    description: "Timeline/saved original intent, explicit empty selection and retained navigation context"
    verification:
      - kind: integration
        ref: "253 selected ExUnit tests"
        status: pass
      - kind: browser
        ref: "251-PAIR-EVIDENCE.md"
        status: pass
    human_judgment: false
  - id: D-08-D-09
    description: "Existing owners, coupled negative controls and matched bounded proof"
    verification:
      - kind: integration
        ref: "32 Node cases and current source/rendered inventory contracts"
        status: pass
    human_judgment: false
---

# Plan01 — Valid search and truthful recovery

Original unsafe UI/saved intent is rejected before a broader read. Valid query meaning, bare default entry and explicit unconstrained selection remain distinct. Context loss is visible inside the actual detail/history surface; valid Close and breadcrumb returns preserve exact predicates. Invalid results say Not applied/Not queried rather than implying a successful empty search. Saved-view errors are visible in the active Filters drawer.

[Pair evidence](251-PAIR-EVIDENCE.md) records253 selected ExUnit passes,32 Node passes, exact two retries-disabled mounted passes, formatting/compilation and ten matched captures per half. Initial source-only focus success was superseded by the actual browser failure; the corrected removal passed both drawer and modal keyboard checks. No full-root repeat or hosted dispatch occurred.

## Deviations and lessons

The managed executor was interrupted after repeated intake/setup without tracked implementation edits; real exit1 and missing summary remain recorded. Parent completed the same manifest-owned worktree. Necessary existing filter presentation, in-drawer history notice and overlay owners were included after the first tracer exposed concrete gaps. No new API, dependency, schema, capture engine or route was added. The [retrospective](../../../research/2026-11-12-autonomous-run-retrospective.md) retains process/setup failures and required final lessons.

Requirements are partial contributions here; phase-wide ADM completion awaits independent verification. Plan02 continues malformed as-of input and existing Home/Actor flows; Plans03/04 retain Coverage/Redaction/Evidence and full phase review. No user action is required for routine continuation.

## Task commits

- `56bfaf9e38cbefc9513cbf2e3132a762b71b727e`
- `48539d05821a7e08e0527f6c649c366fa93a9714`
- `6880e6bc46feed72a33afdd3478ff6b996de24b3`

## Self-Check: PASSED

The named commits and local evidence/summary artifacts exist. The final source-bound gate receipts establish the selected checks; phase-wide independent acceptance remains pending.


## Final milestone traceability writeback

This plan's declared requirement contributions are now reflected in `requirements-completed`, following the independently passed phase goal and final34-requirement integration check/current candidate CI. Earlier empty completion fields were local contribution bookkeeping, not a new missing implementation. Historical results remain preserved; the bounded successor-impact verification owns current fingerprint freshness.
