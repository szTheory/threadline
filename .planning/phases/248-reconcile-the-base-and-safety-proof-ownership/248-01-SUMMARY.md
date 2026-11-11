---
phase: 248-reconcile-the-base-and-safety-proof-ownership
plan: "01"
subsystem: infra
tags: [candidate-preservation, provenance, isolation, python]
requires: []
provides:
  - Preserved candidate and approved brand provenance with actual executor fork/cwd evidence
  - Complete retained-edit dispositions with implementation and proof owners
  - Read-only phase-local preservation validator with negative controls
affects: [phase-249, phase-250, phase-251, phase-252, phase-253]
actuals:
  tokens: 10904
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [GSD-managed isolated execution, phase-local read-only evidence checks]
key-files:
  created:
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-CANDIDATE-BASELINE.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-ISOLATION.json
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py
  modified: []
key-decisions:
  - Keep the retained UI candidate untouched and disposition each edit for its owning phase.
  - Preserve actual executor provenance separately from later inventory-only validation.
patterns-established:
  - Use inventory-only mode after the first executor worktree has been cleaned up.
requirements-completed: [ADM-01]
coverage:
  - id: D1
    description: Real GSD fork and executor binding match the reviewed candidate and approved source.
    requirement: ADM-01
    verification:
      - kind: other
        ref: python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-tracer
        status: pass
    human_judgment: false
  - id: D2
    description: Every retained edit has a unique disposition and source identity while the old checkout stays unchanged.
    requirement: ADM-01
    verification:
      - kind: other
        ref: python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check --self-test
        status: pass
      - kind: other
        ref: python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-inventory --self-test
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-11-10
status: complete
---

# Phase 248 Plan 01 Summary

**The current-main candidate has measured executor provenance and a complete preserved-edit disposition inventory without copying the old UI patch.**

## Accomplishments

- Recorded actual GSD adapter creation, expected/observed fork, worker and cwd identity; approved brand-source blobs remain unchanged.
- Reconciled all 31 retained product/docs/test edits with distinct implementation/proof owners and four upstream overlap safeguards. The original checkout's status and binary patch fingerprints remain unchanged.
- Added a standard-library-only, read-only phase validator. It rejects missing/extra/duplicate/reordered rows, empty dispositions and incorrect blob identities. Inventory-only mode preserves historical provenance without pretending a later executor has the first executor's cwd.
- Kept the mount, advisory and affected-suite proof ledger pending for the owning plans.

## Task Commits

1. **Task 1: Trace isolated candidate and approved brand provenance** - `05a340074daef5b183d1a88ee594fb5ad78d28c1`.
2. **Task 2: Reconcile retained edits and proof owners** - `b5a96713e453fb8d048ac16a32cdd69b885a4002`.

## Verification

The orchestrator reran `--check-tracer` on the tracer snapshot before its commit, then `--check --self-test` and `--check-inventory --self-test` after restoring the full inventory. All passed. All six negative controls reject corrupted inventories; genuine inventory passes. Diff whitespace and machine-local-home-path checks passed. No Mix, database or browser suite was run for this preservation-only plan.

## Deviations and Recovery

The executor's workspace sandbox denied shared Git-index writes. It returned a concrete checkpoint with three verified uncommitted files and no summary. The orchestrator handled the already-authorized local Git operations: it committed a freshly validated tracer snapshot, restored and revalidated the full inventory, then committed the second task. The worker had prepared both tasks before this handoff; no work was discarded. This summary closes that transport/permission boundary rather than dispatching duplicate implementation.

The first validator attempt located the receipt under the OS-specific temporary directory instead of the supplied receipt path. That local lookup was corrected and the affected checks rerun before acceptance. A trailing blank line caught by staged whitespace validation was corrected before the tracer commit.

## Remaining Boundaries

ADM-02–04 remain pending. Product authorization, vulnerable locks and the repeat-suite workflow are unchanged. Existing live issue/hosted CI/release receipts remain open; this plan claims only preservation and local executor provenance. Current public artifacts use relative worktree IDs and hashes, while private local paths remain in ephemeral launch records.

## Self-Check: PASSED

All three planned artifacts exist. Both task commits are reachable on the isolated executor branch. Fresh tracer, full inventory and negative-control checks passed; the preserved checkout remains unchanged. Shared STATE.md and ROADMAP.md were not modified by this plan.
