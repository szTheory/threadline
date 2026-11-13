---
phase: 251-complete-investigation-and-inspection-screens
plan: "02"
subsystem: ui
tags: [phoenix, snapshots, navigation, actor, evidence]
requires:
  - phase: 251-01
    provides: "Validated original filters and retained-context recovery"
provides:
  - "Explicit invalid historical intent without a substituted latest read"
  - "Exact blank/UTC/offset snapshot selection and preserved filter return"
  - "Mounted Home/nonhuman actor lifecycle and full-value controlled copy proof"
affects: ["251-03", "251-04", "Phase253 inclusive integration"]
tech-stack:
  added: []
  patterns: ["Invalid/default/valid snapshot classification", "Connected mounted controls before interaction", "Positive controls for no-read and no-person-link assertions"]
key-files:
  created:
    - .planning/phases/251-complete-investigation-and-inspection-screens/251-02-BOUNDARY-CONTINUATION.md
  modified:
    - lib/threadline/operator_surface/live/row_history_live.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/live/timeline_live/helpers.ex
    - examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts
    - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
key-decisions:
  - "Skip only the as-of fallback on invalid input; keep scoped history available for correction"
  - "Offer explicit latest recovery because a native datetime-local input cannot display malformed text"
  - "Preserve explicit empty from alongside other supported predicates in private UI helpers"
patterns-established:
  - "A rendered page is not connected LiveView proof; use the existing connection condition"
requirements-completed: []
actuals:
  tokens: null
  executor_usage: null
  managed_executor_exit: 1
  managed_executor_seconds: 496.14
  parent_continuation_seconds_at_summary: 2667.46
  tasks: 3
status: complete
completed: 2026-11-12
coverage:
  - id: D-01-D-04
    description: "Explicit snapshot intent, exact identity, scoped reads and retained navigation"
    verification:
      - kind: integration
        ref: "231 selected ExUnit tests"
        status: pass
      - kind: browser
        ref: "251-PAIR-EVIDENCE.md"
        status: pass
    human_judgment: false
  - id: D-08-D-09
    description: "Existing owners, independent source discovery and bounded matched proof"
    verification:
      - kind: integration
        ref: "32 Node cases and five exact first-attempt mounted cases"
        status: pass
    human_judgment: false
---

# Plan02 — Explicit snapshot selection and existing lifecycle proof

Invalid requested times no longer substitute a current snapshot. Clearing retains blank intent, valid offsets resolve to UTC, and existing Close/breadcrumb paths preserve original predicates and scope. Home and Actor production modules needed no changes. New tests prove long identities, kind-specific nonhuman collections, actual loaded absent/anonymous no-person-link negatives and exact controlled-copy bytes.

[Pair evidence](251-PAIR-EVIDENCE.md) records231 selected root passes,32 Node passes, five retries-disabled mounted passes, compile/format and four matched actual viewport captures per half. Stable proof-home-1/2, proof-actor-1/2, proof-row-2 and proof-drawer-1 now resolve to the exact Phase251 cases; declaration discovery and negative ownership/malformed controls remain intact.

## Remaining phase work

The existing375px history Close label wraps vertically. It was corrected in Plan03’s measured shared layout batch; independent phase UI review remains pending. Phase-wide independent source/security/UI/goal reviews remain pending; requirements-completed therefore stays empty. This summary completes the plan's behavioral and scoped proof work, not whole-phase visual or release acceptance. Continue Coverage, then Redaction/Evidence and the shared correction/review batch.

## Deviations and retained failures

The new executor again repeated unchanged intake and was deliberately interrupted with real exit1 and no summary. Parent continued the same GSD-created worktree. Remaining sequential plans reuse that isolated context, each retaining its own task/proof/summary boundaries and final independent phase review. No concurrent implementation worker or root-checkout implementation is introduced. The [bounded continuation](251-02-BOUNDARY-CONTINUATION.md) records the necessary empty-from helper owner.

Setup/selector/readiness failures are retained in the [pair evidence](251-PAIR-EVIDENCE.md) and [run retrospective](../../research/2026-11-12-autonomous-run-retrospective.md). The consumed full-repeat stop and all external/native/foreground limits remain effective. No user action is needed for routine continuation.

## Task commits

- `72f0faac` — standalone invalid/default selection and empty-from correction.
- `208ef0da` — transaction snapshot state and parsed focus identity.
- `88ba702636a63676147989c7b0d119ca7516ceaf` — Home/Actor proof, stable owners and connected controls.

## Self-Check: PASSED

Named commits and paired artifacts exist. Current production bytes match the startup-bound after source; exact final test-source hashes and successful receipts are reconciled. The narrow Close finding and independent phase review remain explicitly pending.
