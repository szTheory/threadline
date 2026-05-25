---
phase: 89
slug: contract-lock-final-verification
status: verified_with_followup
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T07:45:00Z
---

# Phase 89 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 89 validates one truthful support-lane claim on the current tree. The main risks are overclaiming support-scoped row history / as-of, drifting named verification entrypoints away from what the repo actually proves, and silently leaving milestone authority files contradictory after the docs and tests are repaired.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Mix alias verification, CI-surface grep, and planning-artifact review |
| **Config file** | `config/test.exs`, `mix.exs`, `.github/workflows/ci.yml`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` |
| **Quick run command** | `mix verify.doc_contract` |
| **Root behavioral proof** | `MIX_ENV=test mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` |
| **Example-host proof** | `mix verify.example` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~15 seconds warm for targeted proof; full suite depends on formatting state |

---

## Sampling Rate

- After guide/example contract edits: run `mix verify.doc_contract`.
- After verification-surface edits: run the focused root operator-surface suite and `mix verify.example`.
- Before closeout artifacts: grep `mix.exs` and `.github/workflows/ci.yml`, then run `mix ci.all` once to record current-tree named-suite status honestly.
- Max feedback latency: < 15 seconds for the targeted proof commands used in this phase.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 89-01-01 | 01 | 1 | DOC-01 | T-89-01 / T-89-03 | Public contract text keeps lane breadth, host-owned auth/scope, and row-history truth aligned across the root guides. | doc-contract | `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 89-01-02 | 01 | 1 | DOC-01 | T-89-02 | The example remains a narrow `sigra-reference` proof path and does not silently claim support-scoped row history / as-of. | example doc-contract | `mix test test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 89-02-01 | 02 | 2 | DOC-02 | T-89-04 | Root behavioral proof covers the still-claimed support-lane surfaces, and the example host still proves the narrower support lane through its own app context. | focused integration | `MIX_ENV=test mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` then `mix verify.example` | ✅ | ✅ green |
| 89-02-02 | 02 | 2 | DOC-02 | T-89-05 | Named proof entrypoints and CI discoverability remain aligned with the contract-lane story. | alias / artifact | `mix verify.doc_contract` then `rg -n 'verify\\.doc_contract|verify\\.example|verify\\.test|ci\\.all' mix.exs && rg -n 'verify-test|verify-docs|verify-compile-no-optional' .github/workflows/ci.yml` | ✅ | ✅ green |
| 89-02-03 | 02 | 2 | DOC-02 | T-89-06 | Closeout records whether authoritative-surface drift exists instead of silently mutating milestone authority files. | artifact review | `rg -n 'row history|row-history|Start Phase 85|Execute Phase 85|support lane|support-safe claim' .planning/ROADMAP.md .planning/STATE.md .planning/PROJECT.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Commands Actually Used

1. `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1`
   Result: PASS
2. `mix verify.doc_contract`
   Result: PASS after adding `verify.doc_contract: :test` to `preferred_envs` and widening the alias to the full support-lane contract suite.
3. `MIX_ENV=test mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1`
   Result: PASS
4. `mix verify.example`
   Result: PASS
5. `rg -n 'verify\\.doc_contract|verify\\.example|verify\\.test|ci\\.all' mix.exs && rg -n 'verify-test|verify-docs|verify-compile-no-optional' .github/workflows/ci.yml`
   Result: PASS
6. `mix ci.all`
   Result: FAIL on `mix verify.format` because the working tree already contains unrelated unformatted local edits outside Phase 89 ownership (for example `test/threadline/operator_surface/live/timeline_live_test.exs`, `lib/threadline/operator_surface/unsupported.ex`, `test/threadline/retention/pruner_test.exs`, and several other files). This did not invalidate the targeted Phase 89 contract proof, but it means the dirty local tree is not currently full-suite clean.

---

## Wave 0 Requirements

- [x] Existing doc-contract and example verification infrastructure covers DOC-01 and DOC-02.
- [x] The phase records a truthful split between root-app proof and example-app proof rather than trying to compile example tests in the root app context.
- [x] The validation artifact no longer predeclares `89-03-01` as a routine execution row.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Authoritative-surface drift severity | DOC-01, DOC-02 | Whether the contradictions in `ROADMAP.md` and `STATE.md` require a dedicated reconciliation plan is a milestone-truth judgment, not just a grep result. | Compare the verified narrowed claim against `ROADMAP.md` line 19 and `STATE.md` lines 64-75. If those surfaces still contradict the current-tree contract, route to `89-03` instead of editing them during verification. |

---

## Authoritative-Surface Drift

- **Verdict:** detected
- **Contradictory files:** `.planning/ROADMAP.md`, `.planning/STATE.md`
- **Why:** `ROADMAP.md` still says row history / as-of “will be safely scoped via scope_query_fn, not disabled,” while the verified current-tree contract now narrows support-scoped row history / as-of out of the claimed lane. `STATE.md` still says “Execute Phase 85” / “Start Phase 85” and reports v1.21 progress as if the milestone had not executed.
- **Action:** `89-03` is required as a contingent milestone-surface reconciliation plan. This validation artifact intentionally does not mutate those authority files.

---

## Validation Sign-Off

- [x] All executed tasks have explicit automated verification coverage.
- [x] Sampling continuity stayed below the three-task Nyquist gap.
- [x] Actual closeout commands are recorded, including `mix verify.doc_contract`, `mix verify.example`, and `mix ci.all`.
- [x] `nyquist_compliant: true` set in frontmatter.
- [x] Authoritative-surface drift outcome recorded explicitly instead of being silently repaired in-plan.

**Approval:** finalized on 2026-05-25 for Plans `89-01` and `89-02`. A separate `89-03` follow-up is still required before Phase 89 can be considered fully closed.
