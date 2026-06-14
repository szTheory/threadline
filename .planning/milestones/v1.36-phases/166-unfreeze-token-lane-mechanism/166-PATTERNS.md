# Phase 166 Patterns

**Phase:** 166 - unfreeze-token-lane-mechanism
**Created:** 2026-06-12

## Option Flow Pattern

- Source: `lib/threadline/operator_surface/router.ex`
- Existing pattern: macro reads literal keyword opts at compile time, stores booleans such as `has_auth_fn?`, and passes `unquote(opts)` to `Auth.on_mount/4`.
- Phase 166 use: validate `Keyword.get(opts, :theme, :dark)` in the macro, then let the existing `unquote(opts)` path carry the selected value to all LiveViews.

## Assign Pattern

- Source: `lib/threadline/operator_surface/auth.ex`
- Existing pattern: `Auth.on_mount/4` assigns repo, schemas, scope query, and capability booleans with `Phoenix.Component.assign/3`.
- Phase 166 use: assign `:threadline_theme` once before authorization returns. Use a normalized string so HEEx roots can render it directly.

## Root Markup Pattern

- Source roots: `lib/threadline/operator_surface/live/*.ex`
- Existing pattern: each LiveView begins render output with `<div class="threadline-ui">`.
- Phase 166 use: update exactly those ten roots to include `data-tl-theme={@threadline_theme}` while preserving existing class, children, and `<Threadline.OperatorSurface.Style.css />` placement.

## Source Contract Pattern

- Source: `test/threadline/operator_surface/style_contract_test.exs`
- Existing pattern: source-string tests protect CSS tokens, component sections, breakpoint rules, motion rules, and dark frozen values.
- Phase 166 use: replace only dark-only assertions with theme-aware assertions, keep dark frozen values and token-backed component-section tests.

## Test Pattern

- Source: `test/threadline/operator_surface/router_test.exs`
- Existing pattern: compile quoted routers and purge compiled modules.
- Phase 166 use: add compile tests for allowed and invalid `theme:` values using the same quoted-router pattern.

