---
phase: 44
slug: sigra-integration-adapter
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-01
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `mix.exs` + `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/threadline/integrations/` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~30 seconds (integrations subset); ~3 min full |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/integrations/`
- **After every plan wave:** Run `mix verify.test`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green (format + credo + test)
- **Max feedback latency:** 30 seconds (per-task)

---

## Per-Task Verification Map

To be filled by gsd-planner per-plan. Expected coverage:

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | 01 | 1 | SIGRA-01 / Req 1, 2 | — | adapter loads without `:sigra` | unit | `mix compile --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | SIGRA-01 / Req 6 | — | anonymous → nil (3-conn baseline) | unit | `mix test test/threadline/integrations/sigra_test.exs` | ❌ W0 | ⬜ pending |
| TBD | 01 | 2 | SIGRA-01 / Req 3 | — | impersonation → admin actor | unit | `mix test test/threadline/integrations/sigra_test.exs` | ❌ W0 | ⬜ pending |
| TBD | 01 | 2 | SIGRA-01 / Req 4, 5 | — | API-token → service_account; org suffix | unit | `mix test test/threadline/integrations/sigra_test.exs` | ❌ W0 | ⬜ pending |
| TBD | 01 | 2 | SIGRA-01 / Req 7 | — | header wins; correlation_id formats | unit | `mix test test/threadline/integrations/sigra_test.exs` | ❌ W0 | ⬜ pending |
| TBD | 02 | 3 | SIGRA-02 / Req 8 | — | example app HTTP/Oban/correlation paths green | integration | `cd examples/threadline_phoenix && mix test` | ❌ W0 | ⬜ pending |
| TBD | 03 | 3 | SIGRA-03 / Req 9 | — | guide literals locked (install + Plug + 6 outcomes + 4 corr formats + soft-dep) | doc-contract | `mix test test/threadline/integrations/sigra_doc_contract_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/sigra_test_doubles.ex` — defstruct shims for Sigra.Session / Sigra.Scope / Sigra.APIToken (D-01..D-05); guarded by `unless Code.ensure_loaded?(Sigra.Session)`
- [ ] `test/threadline/integrations/sigra_test.exs` — adapter unit test scaffolding with 4-shape × 2-env fixture matrix
- [ ] `test/threadline/integrations/sigra_doc_contract_test.exs` — doc-contract test scaffolding (`use ExUnit.Case, async: true` per D-13)
- [ ] `guides/integrations/sigra.md` — guide skeleton (5 sections: install, Plug wire-up, 6 outcomes, 4 correlation_id formats, soft-dep contract)
- [ ] `lib/threadline/integrations/sigra.ex` — adapter module skeleton with three public functions (Code.ensure_loaded? gate)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Soft-dep evaporation when `:sigra` IS installed | Req 2 | Library suite test runs without `:sigra` in deps; verifying the "doubles evaporate" path requires running the example app's own `mix test` (which DOES have `:sigra` installed) | `cd examples/threadline_phoenix && mix deps.get && mix test` — confirms doubles file is bypassed when `Code.ensure_loaded?(Sigra.Session)` is true |
| Doc-contract drift detection | Req 9 | Verify the test FAILS on intentional mutation (negative case) | Mutate one locked literal in `guides/integrations/sigra.md` (e.g., change "sigra-session:" → "sigra-sess:"), run `mix test test/threadline/integrations/sigra_doc_contract_test.exs`, confirm RED, revert |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
