---
phase: 44
slug: sigra-integration-adapter
status: active
nyquist_compliant: true
wave_0_complete: true
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
| T1 | 01 | 1 | SIGRA-01 / Req 1, 2 | — | adapter loads without `:sigra` | unit | `mix compile --warnings-as-errors` | ✅ | ✅ green |
| T2 | 01 | 1 | SIGRA-01 / Req 6 | — | anonymous → nil (3-conn baseline) | unit | `mix test test/threadline/integrations/sigra_test.exs` | ✅ | ✅ green |
| T3 | 01 | 2 | SIGRA-01 / Req 3 | — | impersonation → admin actor | unit | `mix test test/threadline/integrations/sigra_test.exs` | ✅ | ✅ green |
| T4 | 01 | 2 | SIGRA-01 / Req 4, 5 | — | API-token → service_account; org suffix | unit | `mix test test/threadline/integrations/sigra_test.exs` | ✅ | ✅ green |
| T5 | 01 | 2 | SIGRA-01 / Req 7 | — | header wins; correlation_id formats | unit | `mix test test/threadline/integrations/sigra_test.exs` | ✅ | ✅ green |
| T6 | 02 | 3 | SIGRA-02 / Req 8 | — | example app HTTP/Oban/correlation paths green | integration | `cd examples/threadline_phoenix && mix test` | ✅ | ✅ green |
| T7 | 03 | 3 | SIGRA-03 / Req 9 | — | guide literals locked (install + Plug + 6 outcomes + 4 corr formats + soft-dep) | doc-contract | `mix test test/threadline/integrations/sigra_doc_contract_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/support/sigra_test_doubles.ex` — defstruct shims for Sigra.Session / Sigra.Scope / Sigra.APIToken (D-01..D-05); guarded by `unless Code.ensure_loaded?(Sigra.Session)`
- [x] `test/threadline/integrations/sigra_test.exs` — adapter unit test scaffolding with 4-shape × 2-env fixture matrix
- [x] `test/threadline/integrations/sigra_doc_contract_test.exs` — doc-contract test scaffolding (`use ExUnit.Case, async: true` per D-13)
- [x] `guides/integrations/sigra.md` — guide skeleton (5 sections: install, Plug wire-up, 6 outcomes, 4 correlation_id formats, soft-dep contract)
- [x] `lib/threadline/integrations/sigra.ex` — adapter module skeleton with three public functions (Code.ensure_loaded? gate)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Soft-dep evaporation when `:sigra` IS installed | Req 2 | Library suite test runs without `:sigra` in deps; verifying the "doubles evaporate" path requires running the example app's own `mix test` (which DOES have `:sigra` installed) | `cd examples/threadline_phoenix && mix deps.get && mix test` — confirms doubles file is bypassed when `Code.ensure_loaded?(Sigra.Session)` is true |
| Doc-contract drift detection | Req 9 | Verify the test FAILS on intentional mutation (negative case) | Mutate one locked literal in `guides/integrations/sigra.md` (e.g., change "sigra-session:" → "sigra-sess:"), run `mix test test/threadline/integrations/sigra_doc_contract_test.exs`, confirm RED, revert |

---

## STRIDE Threat Register

This is the canonical threat registry for Phase 44. All `T-44-XX` references in
`44-01-PLAN.md`, `44-02-PLAN.md`, and `44-03-PLAN.md` `<threat_model>` blocks
resolve against this table. Threat IDs are stable and non-colliding.

| ID | Category | Threat | Mitigation | Plans citing |
|----|----------|--------|-----------|--------------|
| T-44-01 | DoS / availability | Adapter raises when `:sigra` is absent | `Code.ensure_loaded?(Sigra.Session)` single gate; 3-conn-shape baseline test | 01 |
| T-44-02 | Audit integrity | Impersonation actor leaks impersonated user_id into `ActorRef.id` (audit row attributes write to wrong principal) | Q1 lock — admin id in ActorRef; impersonated user_id in correlation_id only | 01 |
| T-44-03 | Audit integrity | API-token request mis-attributed as `:user` | D-08 detection order; session-wins-over-token arbitration | 01 |
| T-44-04 | Information disclosure | `x-correlation-id` header from untrusted client overrides Sigra-derived correlation | INTENTIONAL per Req 7 (header wins). Trust boundary documented in guide | 02, 03 |
| T-44-05 | Privilege escalation | Test doubles loaded in production due to misconfigured `elixirc_paths` | `unless Code.ensure_loaded?(Sigra.Session)` mutual exclusion + `elixirc_paths(:test)` only | 01 |
| T-44-06 | Tampering / supply-chain | Doc-contract guide drift produces wrong install snippet (e.g., adopters wire `{:sigra,...}` into Threadline library mix.exs) | Doc-contract test asserts install snippet placement language | 03 |
| T-44-07 | Tampering / supply-chain | Library `mix.exs` accidentally gains `:sigra` (even as `optional: true`), polluting Threadline's transitive dependency surface for hosts that don't run Sigra | `grep -E '\{:sigra' mix.exs` returns 0 invariant; asserted in Plans 01, 02, 03 (defense in depth) | 01, 02, 03 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated checks green on 2026-05-01; formal phase completion still blocked by cleanliness gate.
