---
phase: 166-unfreeze-token-lane-mechanism
status: planned
created: 2026-06-12
---

# Phase 166 Validation Strategy

## Required Proofs

1. Compile validation proof:
   - `mix test test/threadline/operator_surface/router_test.exs`
   - Invalid `theme: :sepia` raises `CompileError` with `:dark | :light | :system`.

2. Dead-render theme proof:
   - Focused LiveView test for default mount contains `data-tl-theme="dark"`.
   - Focused LiveView test for `theme: :system` contains `data-tl-theme="system"`.

3. Style contract proof:
   - `mix test test/threadline/operator_surface/style_contract_test.exs`
   - Contract asserts dark base, light lane, system media lane, retained `theme-toggle` ban, and tokenized active nav inset.

4. Integration proof:
   - `mix compile --warnings-as-errors`
   - `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/style_contract_test.exs`

## Deferred Proofs

- Full WCAG AA light mirror belongs to Phase 168.
- Screenshot `__light__` baselines and example-app `theme: :system` belong to Phase 169.
- Brandbook token parity belongs to Phase 170.

