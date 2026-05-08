---
phase: 70
slug: sigra-phoenix-reference-integration-refresh
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
completed: 2026-05-08
---

# Phase 70 — Validation

> Validation contract for Phase 70 planning.
> This phase refreshes the Sigra/Phoenix reference lane, root/example package wording, and proof-lock coverage without broadening support claims or changing the soft-dependency boundary.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit source-reading contract tests, Mix alias verification, and example-app verification |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/mix.exs`; `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/readme_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Moderate; dominated by `mix verify.example` inside `mix ci.all` |

## Requirement Mapping

| Requirement | Executed Coverage | Evidence Surface |
|-------------|------------------|------------------|
| INTEG-02 | `70-02` keeps `Threadline.Integrations.Sigra` as the small soft-loaded callback pair and locks the request-capture-only contract in docs/tests. | `guides/integrations/sigra.md`; `test/threadline/integrations/sigra_doc_contract_test.exs`; `mix verify.compile_no_optional` |
| COMPAT-03 | `70-01`, `70-02`, and `70-03` refresh root docs, lane/proof docs, and the example README so package wording, support caveats, and exact proof pins match current root/example reality. | `README.md`; `guides/getting-started-saas.md`; `guides/operator-surface.md`; `guides/upgrade-path.md`; `examples/threadline_phoenix/README.md`; focused doc-contract tests |
| ADOPT-09 | `70-01` and `70-03` keep one canonical surface-first path while naming capture-only parity at the relevant operator steps and preserving the example as runnable proof. | `guides/getting-started-saas.md`; `guides/operator-surface.md`; `examples/threadline_phoenix/README.md`; `mix verify.example` |

## Validation Outcome

- The planned phase shape is coherent and stays inside the locked context: three execution plans, all in Wave 1, with no file collisions and no broadened support matrix.
- Generic/root package wording is intentionally included in scope because the phase goal explicitly includes package wording and the repo still contains stale `threadline ~> 0.3` snippets.
- Exact Phoenix/Sigra proof pins remain confined to the support/example proof surfaces; generic install docs stay on root package/range posture.

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 70-01 | 01 | 1 | COMPAT-03, ADOPT-09 | T-70-01..03 | Generic docs use current root package posture, keep proof pins out, and preserve capture-only parity reminders. | source-reading + grep | `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs --max-failures 1` | ✅ | complete |
| 70-02 | 02 | 1 | INTEG-02, COMPAT-03 | T-70-04..06 | Lane/proof docs separate root proof from example proof and keep Sigra request-capture-only with host-owned surface/export auth. | source-reading + compile gate | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs --max-failures 1 && mix verify.compile_no_optional` | ✅ | complete |
| 70-03 | 03 | 1 | ADOPT-09, COMPAT-03, INTEG-02 | T-70-07..09 | Example README stays a narrow proof artifact with current pins, host-owned `/audit` auth wording, and parity reminders. | source-reading + example verification | `mix test test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1 && mix verify.example` | ✅ | complete |

## Wave 0 Requirements

- [x] `.planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md`
- [x] `.planning/phases/70-sigra-phoenix-reference-integration-refresh/70-RESEARCH.md`
- [x] `.planning/phases/70-sigra-phoenix-reference-integration-refresh/70-PATTERNS.md`
- [x] `.planning/phases/70-sigra-phoenix-reference-integration-refresh/70-VALIDATION.md`

Wave 0 is complete. The planning artifact set now includes the required Nyquist validation contract.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Support wording still reads honest rather than marketing-broadened | COMPAT-03 | Literal tests can miss tone drift that still overstates support. | Review `guides/upgrade-path.md`, `guides/integrations/sigra.md`, and `examples/threadline_phoenix/README.md` after execution and confirm they still distinguish `supported`, `reference`, and `unclaimed`. |
| Surface-first docs still keep capture-only parity without becoming dual-track onboarding | ADOPT-09 | Human review is needed to judge narrative emphasis, not just presence of command literals. | Review `guides/getting-started-saas.md` and `examples/threadline_phoenix/README.md` after execution and confirm `/audit` remains the primary path while parity reminders stay attached to the same operator tasks. |

## Validation Sign-Off

- [x] Nyquist validation artifact exists for Phase 70.
- [x] The plan set covers every mapped requirement.
- [x] Verification steps are assigned to the same slice that changes the relevant contract wording.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** completed on 2026-05-08 after the focused Phase 70 suite, `mix verify.compile_no_optional`, `mix verify.example`, and `mix ci.all` all passed on the final tree.
