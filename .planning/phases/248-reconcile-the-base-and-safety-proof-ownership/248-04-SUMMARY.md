---
phase: 248-reconcile-the-base-and-safety-proof-ownership
plan: "04"
subsystem: ci, testing
tags: [github-actions, playwright, exunit, flake-detection]
requires:
  - phase: "248-02"
    provides: Explicit operator mount authorization policy and route behavior used by final integration checks
  - phase: "248-03"
    provides: Reconciled lockfiles and all-lock advisory evidence
provides:
  - Pinned Node and locked E2E setup before the existing verify-flake repeat
  - A scoped regression and source-bound local setup, repeat, canonical, and review evidence
affects: [ADM-01, ADM-02, ADM-03, ADM-04, phase-249]
actuals:
  tokens: 47899.0
  tasks: 3
  commits: 17
  plan_head_before: 0b36bfc0baff94e27dc0a4f40ca189c982901409
  plan_head_after: ce0c2e30d0b7401b3b35df21dcd986ad9ed8cafb
tech-stack:
  added: []
  patterns:
    - Reuse the pinned setup-node action and npm ci under the existing workflow gate
key-files:
  created:
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-PLAIN-REPEAT-RECEIPT.json
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-04-HISTORY.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-SUITE-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-WORKFLOW-REVIEW.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-CLIPBOARD-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-PUBLIC-SURFACE-FIX.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-POSTFIX-REPEAT-RECEIPT.json
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-FILE-PRESSURE-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-INVENTORY-REPEAT-RECEIPT.json
  modified:
    - .github/workflows/flake-detection.yml
    - test/threadline/browser_journey_evidence_contract_test.exs
    - test/threadline/code_walkthrough_doc_contract_test.exs
    - guides/code-walkthrough.md
    - lib/threadline/operator_surface/router.ex
    - release-please-config.json
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-CANDIDATE-BASELINE.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-VALIDATION.md
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/repo_contract_scope_contract_test.exs
    - test/threadline/storage_schema_call_site_contract_test.exs
    - test/threadline/formatter_topology_contract_test.exs
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-04-PLAN.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-SUITE-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-CANDIDATE-BASELINE.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-VALIDATION.md
key-decisions:
  - "Keep all failed full-repeat receipts as failures; do not infer nine-run acceptance."
  - "Reduce measured repeated file operations locally while preserving each contract's fixtures and checks."
  - "Use task-local npm/browser caches and the authorized Git metadata context for local verification."
  - "Keep hosted CI, issue closure, scheduled dependency-health evidence, and REL-01 separate from local results."
requirements-completed: [ADM-01, ADM-02, ADM-03, ADM-04]
coverage:
  - id: D1
    description: "The existing verify-flake job installs its pinned Node runtime and locked E2E packages before repeats, guarded by the existing run decision."
    requirement: ADM-04
    verification:
      - kind: integration
        ref: "mix test test/threadline/browser_journey_evidence_contract_test.exs --seed 876664"
        status: pass
    human_judgment: false
  - id: D2
    description: "The attributed missing-CLI failure and one corrected bounded repeat are recorded with real exit, elapsed, log, and classifier evidence."
    requirement: ADM-04
    verification:
      - kind: other
        ref: ".planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-SUITE-PROOF.md#bounded-corrected-repeat"
        status: fail
    human_judgment: false
  - id: D3
    description: "The assembled candidate passes canonical local integration and preserved-inventory validation, with an independent review report attached."
    verification:
      - kind: integration
        ref: "mix ci.all"
        status: pass
      - kind: other
        ref: "python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-inventory --self-test"
        status: pass
      - kind: other
        ref: ".planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-WORKFLOW-REVIEW.md"
        status: pass
    human_judgment: false
duration: "1h 44m"
completed: 2026-11-11
status: complete
---

## Current accepted plain-repeat proof — 2026-11-11

The single approved **plain nine-run invocation passed** on source `7fa5d51de301c1a935c6ba71b7a7054ed3875f21` (reviewed code `ce0c2e30d0b7401b3b35df21dcd986ad9ed8cafb`), unchanged throughout: suite / capture / wrapper exits 0, classifier `pass`, nine headers and nine clean summaries. Each suite reports 32 properties, 3,400 tests, 0 failures and 3 configured exclusions. Shell elapsed 3,045 seconds; wrapper elapsed 3,044.85 seconds, within the 3,300-second limit. Scale 5, max-cases 36, fresh per-suite seeds, original timeouts/assertions and normal formatter/classifier were preserved; no private observer was loaded. [Exact passing receipt](248-PLAIN-REPEAT-RECEIPT.json).

This resolves Plan248-04's missing plain-repeat proof; its implementation tasks are complete. The earlier failures, invalid intermediate fixture coverage and source-bound canonical/browser limits remain preserved. Passing this local repeat does not prove an exclusive cause or permanent absence of flakes, and does not establish a fresh canonical/browser run or the complete CI toolchain matrix. Task-owned PostgreSQL 15.17 is stopped after terminal and zero remaining clients; shared services were untouched.

The orchestrator now reconciles the worktree through GSD and runs the required validation, security, UI-preservation, code-review/disposition and goal-verification sequence. Phase248 and formal requirement closure remain pending the goal verifier. No further full repeat, hosted write, push, publication, version change or risk waiver is inferred; no user action is needed for the remaining authorized checks.

## Accomplishments

- Added pinned Node and locked E2E setup under the existing verify-flake gate, with regression coverage and unchanged classifier/job/trigger policy.
- Corrected guide/router pipeline examples and bounded test-fixture pressure defects; preserved production formatter inputs, fixture premises, negative controls and existing suite settings.
- Produced the required source-bound plain repeat pass, with independent source review and scoped automated control proofs.

## Verification and evidence

The current repeated suite includes the affected repository, formatter, storage, discovery and mounted-route contracts. Focused format/Credo and private control-mutant evidence remain in [248-OVERLAP-PROOF.md](248-OVERLAP-PROOF.md); its independent [review](248-OVERLAP-REVIEW.md) covers 33 source identities with no active findings. The guide and tagged-negative-fixture defects remain resolved in unchanged source. The earlier canonical alias exit0, browser retry and scoped clipboard proof retain their exact historical source/coverage limits; they are not relabeled as a current full canonical pass.

## Commits and deviations

The original atomic tasks, subsequent local corrections and historical evidence bindings are preserved in [248-04-HISTORY.md](248-04-HISTORY.md). Current corrective code is `ce0c2e30d0b7401b3b35df21dcd986ad9ed8cafb`; later candidate revisions changed only phase metadata. Local fixes did not change package version, dependency declarations, production visual assets, exclusions, assertions, timeout or concurrency policy. The synthetic overlap mutation now targets the exact representative rather than recursively scanning unrelated dependency/build paths.

## Threat Flags

The authored threat register still applies. The repeat resource/evidence threats now have a passing bounded receipt with true exits, immutable source and original classifier. No new runtime threat, accepted risk or public security exception is introduced by the fixture-only corrections. Formal security disposition follows before phase closure.

## User Setup Required

None for the remaining local review and verification. External push/dispatch/issue/release actions retain their separate authority boundary.

## Next Phase Readiness

Plan248-04 is complete at the implementation/proof level. Merge/reconcile only through the recorded GSD worktree adapter, then finish mandatory phase post-gates and foreground goal verification. Do not call `phase.complete 248` until `verification.status` is `passed`; only then continue the originally authorized phases249–253. No new run grant is required merely for these already-authorized review/bookkeeping steps.

## Self-Check

Verified nine clean suites, true suite/capture/wrapper exits0, classifierpass, unchanged source, preserved33/22 identities and stopped owned PostgreSQL. All prior failed receipts remain failures. Phase-level completion is still pending formal verification.
