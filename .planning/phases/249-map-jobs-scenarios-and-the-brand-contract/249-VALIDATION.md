---
phase: "249"
slug: "map-jobs-scenarios-and-the-brand-contract"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-11"
---

# Phase 249 — Validation Strategy

## Test Infrastructure

Use existing ExUnit database/demo contracts and Node/tsx inventory contracts. Root and example formatting/compilation checks cover their owning edits. This phase's full affected group consists of the inventory tests plus example manifest, reset, demo and affected walkthrough contracts; it is not the full canonical/browser/flake matrix.

Quick commands (run in the stated directory):

- Root: `mix test test/threadline/operator_surface/operator_evidence_contract_test.exs`
- Example E2E: `./node_modules/.bin/tsx --test support/operator-route-evidence.test.ts support/operator-ci-evidence.test.ts`
- Example: `mix test test/threadline_phoenix/demo_manifest_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs`
- Example DB group: planner must verify exact tracked paths for demo contract/reset/affected walkthrough tests before authoring commands. Use task-owned supported PostgreSQL with existing host/port controls, not shared configuration changes.

## Sampling Rate

After each meaningful source change run its focused boundary check; after each plan run the complete affected group for that plan. Repeat only after relevant edits or failures. Capture real exit status and logs in background managed sessions. Check environment, locks, formatting and current stop before any explicitly limited invocation. No full-repeat grant is renewed by this phase.

## Per-Task Verification Map

The planner will replace provisional rows with actual plan/task IDs and verified commands, preserving these proof boundaries.

| Task | Requirement | Secure behavior | Test type | Proof boundary | Status |
| --- | --- | --- | --- | --- | --- |
| Inventory tracer and expansion | ADM-05 | Distinct auth/capability/org scope; explicit route/action coverage | Source/Node contract | Existing structural fixture versus semantic map; renderer/proof/state references and negative controls | Pending |
| Seed chronology tracer and expansion | ADM-06 | No public clock/API/schema changes or collapsed transaction boundaries | Example DB integration | Original trigger snapshots and final rows, stable IDs, multi-step order, actor distinction | Pending |
| Calendar/reset/state fixture reconciliation | ADM-07 | Reset guard/lock and retention cutoff/other-org preservation | Example contract/DB | Manifest/export/docs alignment, one reset, ordinary versus named stress, retained purged-empty boundary | Pending |

## Wave 0 Requirements

Existing infrastructure is sufficient. Resolve only locked dependencies/cache/toolchain and task-owned PostgreSQL preflight before execution. Add meaningful assertions to existing boundary tests; do not create a generic seed framework, parallel registry or unnecessary test runner. Any newly required proof file must be named by the planner and created before its command is consumed.

## Manual-Only Verifications

None. Routine behavior is automated; independent agent review covers reference/copy judgment. Static mappings do not close later fresh visual/browser/accessibility acceptance.

## Validation Sign-Off

- [ ] Every plan task has a runnable automated check and explicit failure signal.
- [ ] Exact command paths and required environment are checked before dispatch.
- [ ] Snapshot assertions observe original writes rather than only post-hoc audit clocks.
- [ ] Missing/duplicate route and semantic identities are rejected without weakening voting rules.
- [ ] Reset guard, locking, retention cutoff and other-org preservation remain covered.
- [ ] Current-source receipts establish the affected group without claiming a fresh full matrix.

**Approval:** Pending plan mapping and execution evidence.
