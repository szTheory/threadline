---
phase: "249"
slug: "map-jobs-scenarios-and-the-brand-contract"
status: planned
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-11"
---

# Phase 249 — Validation Strategy

## Test Infrastructure

Use existing ExUnit database/demo contracts and Node/tsx inventory contracts. Root and example formatting/compilation checks cover their owning edits. This phase's full affected group consists of the inventory tests plus example manifest, reset, demo and affected walkthrough contracts; it is not the full canonical/browser/flake matrix.

Quick commands (run in the stated directory):

- Root: `mix test test/threadline/operator_surface/operator_evidence_contract_test.exs`
- Example E2E: `./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts`
- Example: `mix test test/threadline_phoenix/demo_manifest_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs`
- Example DB group: `mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo_reset_test.exs test/threadline_phoenix/demo/advisory_lock_pinning_test.exs test/threadline_phoenix/demo/retention_tail_env_contract_test.exs test/threadline_phoenix_web/walkthrough_happy_path_test.exs test/threadline_phoenix_web/walkthrough_evidence_test.exs`
- Example documentation group: `mix test test/threadline_phoenix/demo_manifest_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs test/threadline_phoenix/walkthrough_doc_contract_test.exs`
- Root owning build checks: `mix verify.format` and `mix compile --warnings-as-errors`.
- Example owning build checks: `mix format --check-formatted` and `mix compile --warnings-as-errors` from `examples/threadline_phoenix`.
- Shell recipe syntax from root: `bash -n examples/threadline_phoenix/e2e/run-e2e.sh`.

All listed paths were confirmed tracked. Commands are authored checks, not executed receipts. Run each task's smaller command while editing; run the complete affected groups once against the final assembled source, repeating only after relevant changes/failures. These groups are not a fresh canonical/browser/flake matrix.

## Sampling Rate

After each meaningful source change run its focused boundary check; after each plan run the complete affected group for that plan. Repeat only after relevant edits or failures. Capture real exit status and logs in background managed sessions. Check environment, locks, formatting and current stop before any explicitly limited invocation. No full-repeat grant is renewed by this phase.

## Per-Task Verification Map

| Task | Requirement | Automated command (directory) | Proof boundary / failure | Status |
| --- | --- | --- | --- | --- |
| 249-01-01 | ADM-05 | `./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts` (example E2E) | Real #4521 source→route→renderer→proof chain; removed link/invalid locator/voting drift fails | Pending |
| 249-01-02 | ADM-05 | Same Node command; `mix test test/threadline/operator_surface/operator_evidence_contract_test.exs` (root) | Independent eleven LiveView + five HTTP declarations, all U1 criteria, auth/capability/org scope and structural mutations; missing/duplicate/wrong access fails | Pending |
| 249-02-01 | ADM-06/07 | `mix test test/threadline_phoenix/demo_manifest_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs` (example) | Exact fixed epoch, actual Tuesday, private identities and documented filter; date/weekday mismatch fails | Pending |
| 249-02-02 | ADM-06/07 | `mix test test/threadline_phoenix/walkthrough_doc_contract_test.exs test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix_web/walkthrough_happy_path_test.exs test/threadline_phoenix_web/walkthrough_evidence_test.exs` (example) | Actual generated export bytes, exact walk dates and supported ConnCase incident/return paths; stale date/flow fails | Pending |
| 249-02-03 | ADM-07 | `mix test test/threadline_phoenix/demo_manifest_contract_test.exs test/threadline_phoenix/demo_reset_test.exs test/threadline_phoenix/demo/advisory_lock_pinning_test.exs` (example); `bash -n examples/threadline_phoenix/e2e/run-e2e.sh` (root) | One reset; duplicate-seed mutation; production refusal and lock pinning; syntax or safeguard failure blocks | Pending |
| 249-03-01 | ADM-06 | `mix test test/threadline_phoenix/demo_contract_test.exs` (example) | #4521 original trigger snapshots and final rows at S/L, redaction and physical action recording time; disagreement fails | Pending |
| 249-03-02 | ADM-06 | Same focused demo contract (example) | Setup/base S, #4518 both ordered TXs/actors, twelve exact agent2 events and agent3 role specimen; missing premise/order/actor fails | Pending |
| 249-03-03 | ADM-06/07 | `mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo/retention_tail_env_contract_test.exs test/threadline_phoenix/demo_manifest_test.exs` (example) | Globex/current/filler snapshots, one run clock, second precision, 90d/60d/other-org/purged-empty; violated invariant fails | Pending |
| 249-04-01 | ADM-05/06/07 | Same Node command (example E2E); `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` (example) | Ordinary selection source→inventory→docs/proofs; stress substitution or missing return/source fails | Pending |
| 249-04-02 | ADM-05/06/07 | Same Node command (example E2E); root operator_evidence_contract command | All U2/U3 criteria, named selections, brand role/asset refs and later owners; omitted/malformed/duplicate-identity control fails | Pending |

Every `<automated>` in the plans is immediately followed by its observable `fails_when`. Independent automated-agent review writes `249-MAPPING-REVIEW.md` after final source and checks, answering the eight criteria fixed in Plan 04. It judges semantic correctness and claim/receipt consistency beyond the structural contracts; no human attestation or new wired prohibition descriptor is implied.

## Wave 0 Requirements

Existing infrastructure is sufficient. First establish a newly verified supported GSD executor-worktree binding; the parent checkout alone does not prove it. Dependencies are absent in this checkout: restore only the tracked root/example Mix locks and E2E package-lock using verified cache, with no new package or lock changes. Record supported Elixir/OTP/PostgreSQL versions and capacity; use task-owned loopback PostgreSQL via DB_HOST/DB_PORT and unique MIX_TEST_PARTITION, preserving shared services. Manage background checks with logs and actual exits. Unset THREADLINE_OPERATOR_EVIDENCE_MODE and THREADLINE_OPERATOR_PREVIEW_REQUIRED before root static checks, preventing entry into live/browser proof. Stop owned PostgreSQL after owned clients finish before a user pause. Pre-suite failures still count as invocations.

Add meaningful assertions inside existing boundary tests; no generic seed framework, parallel registry or runner is needed. Each tracer's first move adds its failing contract, then proves the complete thin path before expansion. Current-source focused checks and bounded corrective retests are authorized; prior full-repeat grants remain consumed, and no new full flake/canonical/browser invocation or indirect substitute is part of this phase. Preserve all specific no-retry/resource stops. No push, hosted dispatch, version, release or publication.

## Manual-Only Verifications

None. Routine behavior is automated; independent agent review covers reference/copy judgment. Static mappings do not close later fresh visual/browser/accessibility acceptance.

## Validation Sign-Off

- [ ] Every plan task has a runnable automated check and explicit failure signal.
- [ ] Exact command paths and required environment are checked before dispatch.
- [ ] Snapshot assertions observe original writes rather than only post-hoc audit clocks.
- [ ] Missing/duplicate route and semantic identities are rejected without weakening voting rules.
- [ ] Reset guard, locking, retention cutoff and other-org preservation remain covered.
- [ ] Current-source receipts establish the affected group without claiming a fresh full matrix.

**Approval:** Task mapping is complete; execution evidence and independent review remain pending. No source or runtime check was executed during planning.
