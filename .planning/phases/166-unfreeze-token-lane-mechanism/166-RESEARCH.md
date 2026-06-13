# Phase 166 Research - Mechanism and Contract Notes

**Researched:** 2026-06-12
**Status:** Complete
**Sources:** Repo inspection plus v1.35 Phase 165 research artifacts

## Summary

Threadline already has the right seam for Phase 166: router options flow into `Auth.on_mount/4`, and every operator LiveView renders a `.threadline-ui` root that consumes the single `--tl-*` token block in `Style.css/1`. The implementation should assign one normalized theme string during on_mount, render it as `data-tl-theme`, and add scoped CSS token overrides. The only non-tokenized color outside the token block is the active shell-nav inset rgba; Phase 166 should add a token for it.

## Implementation Facts

- `Threadline.OperatorSurface.Router.threadline_operator_surface/2` already validates other compile-time mount conditions and passes the literal `opts` to `Auth.on_mount/4`.
- `Threadline.OperatorSurface.Auth.on_mount/4` already assigns multiple `threadline_*` values that every LiveView can read.
- The ten root LiveViews each use literal `<div class="threadline-ui">`; there is no shared root layout.
- `Style.css/1` keeps the dark token block before component CSS, so a light override block can be inserted immediately after the base `.threadline-ui` declaration.
- `style_contract_test.exs` is the source contract and must change in the same wave as `style.ex`.

## Validation Architecture

Phase 166 validation should prove:

- Macro compile validation: `theme: :dark`, `:light`, and `:system` compile; invalid values raise `CompileError` naming `:dark | :light | :system`.
- Render proof: a default mount renders `data-tl-theme="dark"` and a `theme: :system` mount renders `data-tl-theme="system"` in the first LiveView HTML.
- CSS proof: source contains `.threadline-ui[data-tl-theme="light"]`, `.threadline-ui[data-tl-theme="system"]`, scoped `@media (prefers-color-scheme: light)`, `color-scheme: light`, and no `theme-toggle`.
- Token proof: every existing color-bearing token has a light value; `--tl-color-accent-inset` exists in both lanes; the hardcoded active-nav rgba no longer appears outside token declarations.
- Regression proof: `mix compile --warnings-as-errors` and focused operator-surface tests pass before any broader test run.

## Risks

- Contract ordering risk: adding `color-scheme: light` before amending `style_contract_test.exs` will intentionally fail existing tests.
- Dirty worktree risk: many source files are already modified in an unrelated lane, including files Phase 166 will later touch.
- Contrast risk: Phase 168 owns full AA mirror tests, so Phase 166 should avoid over-claiming accessibility completion beyond scoped mechanism assertions.

---

## RESEARCH COMPLETE
