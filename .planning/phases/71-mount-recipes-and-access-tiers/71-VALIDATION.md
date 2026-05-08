---
phase: 71
slug: mount-recipes-and-access-tiers
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
updated: 2026-05-08T15:25:00Z
---

# Phase 71 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 71 is docs-first with focused auth-contract proof. The main risk is teaching a broader or weaker access story than the code actually enforces, so validation centers on doc-contract tests plus the two existing auth transport test files.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit doc-contract tests, focused auth tests, and Mix alias verification |
| **Config file** | `mix.exs`; `test/test_helper.exs`; `.github/workflows/ci.yml` |
| **Quick run command** | `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~10-25 seconds on a warm cache |
| **Estimated runtime — full** | ~90-150 seconds on a warm cache |

---

## Sampling Rate

- **After every task commit:** run the task-scoped command from the verification map below.
- **After Wave 1:** run the full focused Phase 71 doc/auth suite plus `mix verify.compile_no_optional`.
- **After Wave 2 / before phase verification:** run `mix ci.all`.
- **Max per-task feedback target:** 25 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 71-01-01 | 01 | 1 | INTEG-03, ADOPT-08 | T-71-01 / T-71-02 / T-71-03 | Canonical operator-surface guide teaches one admin-first mount recipe, support variation with `exports: false`, export transport split, and parity table. | doc-contract/readback | `mix test test/threadline/operator_surface_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 71-01-02 | 01 | 1 | INTEG-03 | T-71-01 / T-71-03 | Integration-contract guide teaches one shared `%{assigns: assigns}` callback, opaque host-owned scope, and advanced-only `export_authorize_fn`. | doc-contract/readback | `mix test test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 71-02-01 | 02 | 1 | ADOPT-08 | T-71-05 / T-71-06 | Quickstart and Sigra guide keep one canonical runbook path, inline parity mapping, and host-owned `/audit` auth posture. | doc-contract/readback | `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 71-02-02 | 02 | 1 | INTEG-03, ADOPT-08 | T-71-04 / T-71-05 / T-71-06 | Example router and README prove the shared callback shape and support-read-only variation without a second route tree. | doc-contract + source-read | `mix test test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 71-03-01 | 03 | 2 | ADOPT-08 | T-71-07 | Doc-contract suite locks `exports: false`, `%{assigns: assigns}`, inline fallbacks, export split wording, and anti-overclaim assertions. | focused contract suite | `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 71-03-02 | 03 | 2 | INTEG-03 | T-71-08 / T-71-09 | Shared callback works across LiveView auth and export fallback; support-style scope maps stay opaque; explicit support-export opt-in via `export_authorize_fn` is proven. | auth + scoped-flow tests | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/71-mount-recipes-and-access-tiers/71-RESEARCH.md`
- [x] `.planning/phases/71-mount-recipes-and-access-tiers/71-PATTERNS.md`
- [x] `.planning/phases/71-mount-recipes-and-access-tiers/71-VALIDATION.md`

Wave 0 planning resolutions:

- [x] Canonical doc placement resolved: `guides/operator-surface.md` is the primary runbook.
- [x] Scope-honesty boundary resolved: docs must not promise universal scope-aware narrowing.
- [x] Support-export opt-in proof is required if `export_authorize_fn` is taught concretely.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review of parity table and recipe ordering | ADOPT-08 | Ordering and emphasis matter even when literals are contract-tested | Confirm admin appears before support-read-only, capture-only fallback callouts sit next to matching workflows, and no second support route tree is implied. |

---

## Validation Sign-Off

- [x] All planned tasks have explicit automated verification coverage.
- [x] Sampling continuity: no wave ends without a focused automated suite.
- [x] Wave 0 artifacts required for planning are present.
- [x] No watch-mode or manual-only commands are required for the phase gate.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-08 after the post-Phase-73 proof surface passed and `71-VERIFICATION.md` was recorded.

**Final Notes:**

- `71-VERIFICATION.md` now exists and records the repaired tree, exact commands, and requirement coverage.
- The old LiveView-only fallback in the example router was retired during Phase 73; the Phase 71 validation record now reflects the repaired shared-callback contract instead of the stale pre-fix state.
