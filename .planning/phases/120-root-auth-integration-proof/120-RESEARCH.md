# Phase 120: Root Auth Integration Proof — Research

**Researched:** 2026-05-27
**Status:** Complete

## Question

What must Phase 120 implement so CI proves the Phase 119 phx.gen.auth cookbook without mutating `examples/threadline_phoenix` or adding `Threadline.Integrations.PhxGenAuth`?

## Summary

Phase 120 closes the proof gap with a **root-only** integration test file mirroring `sigra_test.exs` structure (host-shaped module functions + one `Threadline.Plug` smoke), guide/doc fixes in the same changeset, and extended `upgrade_path_doc_contract_test.exs`. Authorization proof uses **1-arity** `authorize_fn` via `ExportAuthPlug` and a conn assigns mirror — not LiveView mounts.

## Key Findings

### 1. Asymmetric lane pattern is established

| Lane | Proof location | Adapter in `lib/` |
|------|----------------|-------------------|
| sigra-reference | `test/threadline/integrations/sigra_test.exs` + example app | `Threadline.Integrations.Sigra` |
| phx-gen-auth-reference | `test/threadline/integrations/phx_gen_auth_integration_test.exs` only | None — test-local `PhxGenAuthReference.AuditActor` |

Copy `sigra_test.exs` describe layout; do **not** copy Sigra correlation tables or adapter calls.

### 2. authorize_fn arity bug in shipped guide

`guides/integrations/phx-gen-auth.md` lines 60–63 show **2-arity** `authorize_fn` clauses. Runtime and `ExportAuthPlug` invoke **1-arity** only (`authorize_fn.(mirror)`). Phase 120 must fix mount snippet to:

```elixir
authorize_fn: fn %{assigns: %{current_user: %{role: "admin"}}} -> :ok
authorize_fn: fn _ -> {:error, :unauthorized} end
```

Prove via `ExportAuthPlug` with `%{assigns: conn.assigns}` mirror pattern from `export_auth_plug_test.exs` lines 62–79.

### 3. Three-layer test split (do not duplicate)

| Layer | File | Owns |
|-------|------|------|
| Mechanism | `test/threadline/plug_test.exs` | Header precedence, unknown override keys, remote_ip |
| Operator interpreter | `test/threadline/operator_surface/export_auth_plug_test.exs` | Halt/grant matrix for authorize_fn |
| Lane cookbook | `test/threadline/integrations/phx_gen_auth_integration_test.exs` | Guide AuditActor + admin gate + one Plug smoke |

Reference semantics items **4–6** in phx guide → cite `plug_test.exs` in module `@moduledoc` only.

### 4. Matrix row placement and literals

Insert after `phoenix-surface`, before `sigra-reference`:

```
| phx-gen-auth-reference | reference | Host-generated session auth (mix phx.gen.auth or equivalent) + phoenix-surface optional deps | Root mix.lock Phoenix/LV/HTML/PubSub versions (no Sigra) | guides/integrations/phx-gen-auth.md, test/threadline/integrations/phx_gen_auth_integration_test.exs, mix verify.test, verify-test |
```

Must **not** claim `mix verify.example`, `examples/threadline_phoenix/*`, or `verify-compile-no-optional`.

### 5. Doc-contract extension scope

Extend existing `upgrade_path_doc_contract_test.exs` (~12–16 asserts). **Do not** add `phx_gen_auth_doc_contract_test.exs` (Phase 121). Add fourth lane detection string, matrix row prefix, proof anchors, `refute` "forthcoming" in both guides.

### 6. Fixtures

`test/support/phx_gen_auth_fixtures.ex` — nested plain maps, string user ids, `Plug.Test` + `assign(:current_scope, ...)`. No DB, no example-app structs.

## Recommended Plan Split

| Plan | Wave | Delivers |
|------|------|----------|
| 120-01 | 1 | Integration test + fixtures (AUTH-PROOF-01, AUTH-PROOF-02) |
| 120-02 | 2 | Guides, matrix row, doc contract, verify (AUTH-PROOF-03) |

## Risks

| Risk | Mitigation |
|------|------------|
| Duplicate plug_test coverage | D-120-04/10: single Plug smoke; cite plug_test for 4–6 |
| Guide↔test drift on 2-arity authorize | Fix guide in 120-02 same changeset as tests |
| Matrix over-claims example app | D-120-22 literals audit in doc contract |

## Validation Architecture

- **Quick:** `mix test test/threadline/integrations/phx_gen_auth_integration_test.exs`
- **Wave 1:** above + `mix test test/support/phx_gen_auth_fixtures.ex` (if standalone) or included in integration file
- **Wave 2 / full:** `mix verify.test` and `mix verify.doc_contract`
- **Sampling:** run integration file after each task in 120-01; full verify after 120-02

## RESEARCH COMPLETE
