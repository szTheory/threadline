# Phase 142: Responsive / Mobile-First - Validation Plan

**Created:** 2026-06-04
**Requirement:** POLISH-RESPONSIVE
**Status:** planned

## Validation Architecture

Phase 142 uses two validation layers:

- **Source contracts:** ExUnit checks in `test/threadline/operator_surface/style_contract_test.exs` lock breakpoint tokens, standards-compliant media-query literals, shared responsive primitives, and forbidden root overflow masking.
- **Browser matrix:** Playwright checks in `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` prove the route matrix at 375 / 768 / 1280 with computed root overflow and reachability checks, without screenshots.

## Nyquist Coverage

| Plan | Task | Wave | Automated Command | Purpose |
|------|------|------|-------------------|---------|
| 142-01 | Task 1 | 1 | `mix test test/threadline/operator_surface/style_contract_test.exs` | Red/green breakpoint source contract. |
| 142-01 | Task 2 | 1 | `mix test test/threadline/operator_surface/style_contract_test.exs` | Breakpoint tokens and media literals pass source contracts. |
| 142-01 | Task 2 | 1 | `rg -n "@media \\(min-width: (481|721)px\\)|@media \\(min-width: var\\(--tl-breakpoint" lib/threadline/operator_surface/style.ex && exit 1 || exit 0` | Retired breakpoint and invalid CSS-variable media-query gate. |
| 142-02 | Task 1 | 2 | `mix test test/threadline/operator_surface/style_contract_test.exs` | Shared responsive primitive source contracts. |
| 142-02 | Task 2 | 2 | `mix test test/threadline/operator_surface/style_contract_test.exs` | CSS primitive remediation passes contracts. |
| 142-02 | Task 2 | 2 | `rg -n "body[^}]*overflow-x:\\s*hidden|html[^}]*overflow-x:\\s*hidden|\\.threadline-ui[^}]*overflow-x:\\s*hidden" lib/threadline/operator_surface/style.ex && exit 1 || exit 0` | Root overflow masking gate. |
| 142-03 | Task 1 | 3 | `test -f examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | Browser matrix artifact exists. |
| 142-03 | Task 1 | 3 | `rg -n "375|768|1280|scrollWidth|clientWidth|tl-table--responsive|tl-toolbar__form|tl-subview|operator-nav" examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | Static source-contract gate for matrix scope. |
| 142-03 | Task 2 | 3 | `mix test test/threadline/operator_surface/style_contract_test.exs` | Source contracts stay green before browser proof. |
| 142-03 | Task 2 | 3 | `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-responsive-mobile-first.spec.ts` | Focused 375 / 768 / 1280 browser acceptance matrix. |
| 142-03 | Task 2 | 3 | `rg -n "body[^}]*overflow-x:\\s*hidden|html[^}]*overflow-x:\\s*hidden|\\.threadline-ui[^}]*overflow-x:\\s*hidden" lib/threadline/operator_surface/style.ex && exit 1 || exit 0` | Root overflow masking remains forbidden after browser fixes. |
| 142-03 | Task 3 | 3 | `mix verify.example_browser` | Phase-level browser gate and exception log. |

## Source-Contract Gates

- Breakpoint declarations must include the 375 / 768 / 1280 scale.
- `@media (min-width: 481px)`, `@media (min-width: 721px)`, and `@media (min-width: var(--tl-breakpoint...))` must fail.
- `.tl-table--responsive`, `.tl-toolbar__form`, `.tl-subview`, and `.tl-topbar__nav` must keep the shared mobile-first contracts.
- `body`, `html`, and `.threadline-ui` must not use blanket `overflow-x: hidden` as a masking fix.

## Browser Gates

The focused Playwright matrix must cover:

- Viewports: `375 x 812`, `768 x 900`, `1280 x 900`.
- Routes: `/audit`, `/audit/timeline`, `/audit/coverage`, discovered `/audit/transactions/:id`, discovered `/audit/rows/:table/:record_id`, `/audit/actors/service_account/zendesk-sync`, `/audit/evidence`, `/audit/policy/redaction`, `/audit/policy/retention`, `/audit/exports`.
- Assertions: `#tl-main`, `operator-header`, topbar nav reachability, route-specific controls, table/card behavior, drawer/subview fit, and `document.documentElement.scrollWidth - document.documentElement.clientWidth <= 1`.

## Scope Fences

- No screenshot baselines or screenshot-diff infrastructure.
- No broad accessibility/focus audit.
- No new routes, workflows, packages, Playwright projects, seed changes, or production-code edits outside the Phase 142 plan files.
- No edits to unrelated Phase 136/137 artifacts.
