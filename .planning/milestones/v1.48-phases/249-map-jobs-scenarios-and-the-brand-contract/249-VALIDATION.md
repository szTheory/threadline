---
phase: "249"
slug: "map-jobs-scenarios-and-the-brand-contract"
status: validated
nyquist_compliant: true
wave_0_complete: true
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

All listed paths were confirmed tracked. The commands are reusable recipes; executed source-bound receipts are linked below. Run each task's smaller command while editing; run the complete affected groups once against the final assembled source, repeating only after relevant changes/failures. These groups are not a fresh canonical/browser/flake matrix.

## Sampling Rate

After each meaningful source change run its focused boundary check; after each plan run the complete affected group for that plan. Repeat only after relevant edits or failures. Capture real exit status and logs in background managed sessions. Check environment, locks, formatting and current stop before any explicitly limited invocation. No full-repeat grant is renewed by this phase.

## Per-Task Verification Map

| Task | Requirement | Automated command (directory) | Proof boundary / failure | Status |
| --- | --- | --- | --- | --- |
| 249-01-01 | ADM-05 | `./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts` (example E2E) | Real #4521 source→route→renderer→proof chain; removed link/invalid locator/voting drift fails | Passed |
| 249-01-02 | ADM-05 | Same Node command; `mix test test/threadline/operator_surface/operator_evidence_contract_test.exs` (root) | Independent eleven LiveView + five HTTP declarations, all U1 criteria, auth/capability/org scope and structural mutations; missing/duplicate/wrong access fails | Passed |
| 249-02-01 | ADM-06/07 | `mix test test/threadline_phoenix/demo_manifest_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs` (example) | Exact fixed epoch, actual Tuesday, private identities and documented filter; date/weekday mismatch fails | Passed |
| 249-02-02 | ADM-06/07 | `mix test test/threadline_phoenix/walkthrough_doc_contract_test.exs test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix_web/walkthrough_happy_path_test.exs test/threadline_phoenix_web/walkthrough_evidence_test.exs` (example) | Actual generated export bytes, exact walk dates and supported ConnCase incident/return paths; stale date/flow fails | Passed |
| 249-02-03 | ADM-07 | `mix test test/threadline_phoenix/demo_manifest_contract_test.exs test/threadline_phoenix/demo_reset_test.exs test/threadline_phoenix/demo/advisory_lock_pinning_test.exs` (example); `bash -n examples/threadline_phoenix/e2e/run-e2e.sh` (root) | One reset; duplicate-seed mutation; production refusal and lock pinning; syntax or safeguard failure blocks | Passed |
| 249-03-01 | ADM-06 | `mix test test/threadline_phoenix/demo_contract_test.exs` (example) | #4521 original trigger snapshots and final rows at S/L, redaction and physical action recording time; disagreement fails | Passed |
| 249-03-02 | ADM-06 | Same focused demo contract (example) | Setup/base S, #4518 both ordered TXs/actors, twelve exact agent2 events and agent3 role specimen; missing premise/order/actor fails | Passed |
| 249-03-03 | ADM-06/07 | `mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo/retention_tail_env_contract_test.exs test/threadline_phoenix/demo_manifest_test.exs` (example) | Globex/current/filler snapshots, one run clock, second precision, 90d/60d/other-org/purged-empty; violated invariant fails | Passed |
| 249-04-01 | ADM-05/06/07 | Same Node command (example E2E); `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` (example) | Ordinary selection source→inventory→docs/proofs; stress substitution or missing return/source fails | Passed |
| 249-04-02 | ADM-05/06/07 | Same Node command (example E2E); root operator_evidence_contract command | All U2/U3 criteria, named selections, brand role/asset refs and later owners; omitted/malformed/duplicate-identity control fails | Passed |

Every `<automated>` in the plans is immediately followed by its observable `fails_when`. Independent automated-agent review writes `249-MAPPING-REVIEW.md` after final source and checks, answering the eight criteria fixed in Plan 04. It judges semantic correctness and claim/receipt consistency beyond the structural contracts; no human attestation or new wired prohibition descriptor is implied.

## Wave 0 Requirements

Existing infrastructure proved sufficient. All four executors had actual GSD-created and verified bindings and are now merged/removed; the parent checkout was never substituted for executor binding. The initially absent dependencies were restored from tracked locks and verified cache, then privately cloned for isolated writes without package/lock changes. Record supported Elixir/OTP/PostgreSQL versions and capacity; use task-owned loopback PostgreSQL via DB_HOST/DB_PORT and unique MIX_TEST_PARTITION, preserving shared services. Manage background checks with logs and actual exits. Unset THREADLINE_OPERATOR_EVIDENCE_MODE and THREADLINE_OPERATOR_PREVIEW_REQUIRED before root static checks, preventing entry into live/browser proof. Stop owned PostgreSQL after owned clients finish before a user pause. Pre-suite failures still count as invocations.

Add meaningful assertions inside existing boundary tests; no generic seed framework, parallel registry or runner is needed. Each tracer's first move adds its failing contract, then proves the complete thin path before expansion. Current-source focused checks and bounded corrective retests are authorized; prior full-repeat grants remain consumed, and no new full flake/canonical/browser invocation or indirect substitute is part of this phase. Preserve all specific no-retry/resource stops. No push, hosted dispatch, version, release or publication.

## Manual-Only Verifications

None. Routine behavior is automated; independent agent review covers reference/copy judgment. Static mappings do not close later fresh visual/browser/accessibility acceptance.

## Validation Sign-Off

- [x] Every plan task has a runnable automated check and explicit failure signal.
- [x] Exact command paths and required environment are checked before dispatch.
- [x] Snapshot assertions observe original writes rather than only post-hoc audit clocks.
- [x] Missing/duplicate route and semantic identities are rejected without weakening voting rules.
- [x] Reset guard, locking, retention cutoff and other-org preservation remain covered.
- [x] Current-source receipts establish the affected group without claiming a fresh full matrix.

**Approval:** Automated validation completed 2026-11-12 for all ten task boundaries. No manual-only verification or new tests were needed in this validation pass. Phase goal verification remains pending; this is not a hosted, browser, visual or human-comprehension receipt.


## Executed evidence and limits

- [Wave3 assembled proof](249-WAVE3-RECEIPT.json): then-current 30-test Node inventory group and 66-test example seed/document/reset/walkthrough group pass. The initial single assertion formatting failure was corrected; fresh example format passes, and the full Elixir AST of the formatted test is identical. Subsequent Node-only fixes are covered by the current formal review and fix receipt below; no runtime or seed production change followed the original mapping review.
- [Remaining final affected proof](249-FINAL-AFFECTED-RECEIPT.json): named root format, warning-free compile, root inventory contract, example advisory-lock contract and E2E shell syntax all pass on the assembled source. The example production source is unchanged from Plan03's warning-free compile; its passing receipt is retained in [Plan03 summary](249-03-SUMMARY.md) and [Wave2 identity receipt](249-WAVE2-RECEIPT.json).
- [Independent source/claim judgment](249-MAPPING-REVIEW.md): all eight rubric questions addressed; source-state and comparison-baseline findings are corrected and independently closed. Its current record explicitly supersedes the premature M01 closure and consolidates duplicate populated-proof findings.
- Task commands are shared group checks, not ten distinct invocations. Plan summaries preserve red controls and per-invocation causes. Domain contracts observe original trigger snapshots, physical recording time, actors/partial order, real generated CSV, the real reset guard and backend lock identity.
- The ADM06 edge-engine taxonomy row stays unclassified/flagged-unverified. Named chronology and uncertainty claims have automated DB contracts plus bounded independent judgment; this validation does not fabricate a general classifier descriptor or human attestation. Descriptorless prohibition flags remain non-authoritative.
- No full canonical/root-wide repeat, browser, fresh rendered accessibility/visual acceptance, hosted CI or publication was run. Later rendered/runtime-brand acceptance remains with phases250–253. All explicit repeat/resource and external authority limits persist.

## Validation Audit 2026-11-12

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Current source after formal review fixes

The [current fix receipt](249-REVIEW-FIX-RECEIPT.json) supersedes the older 30-test Node mapping result with 32 passing tests and explicit active/archive/archive-priority/traceability-change controls on b7e6c6f4. Missing both known sources fails explicitly. [Formal independent review](249-REVIEW.md) confirms all three warnings fixed; [disposition](249-REVIEW-DISPOSITION.md) has zero open findings. Original seed/runtime source is unchanged, so 66-test example and root/lock/build evidence remains applicable within its recorded scope. No project-aware TypeScript typecheck or fresh rendered acceptance is claimed.

## Prior-phase regression

The [bounded regression receipt](249-REGRESSION-RECEIPT.json) records 122 passing tests on the assembled source: six selected Phase248 mount/HTTP/public/doc/discovery contracts plus the current independent inventory seam. The named scoped Mix entrypoint ran within the configured 600-second default; the generic non-Mix resolver was not misreported as a tested pass. No full-suite or old repeat grant was used.
