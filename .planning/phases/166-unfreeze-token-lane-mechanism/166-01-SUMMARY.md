---
phase: 166-unfreeze-token-lane-mechanism
plan: 01
subsystem: operator-surface
tags: [operator-surface, theme, light-mode, css-tokens, source-contract]

requires:
  - phase: 165-light-mode-strategy
    provides: "Approved [165-01] strategy: host-configured dark/light/system theme lane"
provides:
  - "Compile-validated `theme: :dark | :light | :system` router option, defaulting to `:dark`"
  - "Server-rendered `data-tl-theme` on all ten operator LiveView roots"
  - "Additive light/system CSS token lanes with token-backed shell-nav active inset"
  - "Source contract amended from dark-only to dark-primary with governed light/system support"
  - "[165-01] STATE ledger entry superseding [136-01]"
affects: [v1.36]

requirements-completed: [THEME-01, THEME-02, THEME-03, THEME-04, TOKEN-01, TOKEN-02, TOKEN-03]

duration: 65min
completed: 2026-06-13
---

# Plan 166-01 Summary - Atomic unfreeze token lane mechanism

## Outcome

Phase 166's single plan is implemented. The operator surface now accepts a compile-validated host `theme:` option, carries the normalized theme through `on_mount/4`, renders it on every LiveView root as `data-tl-theme`, and has additive light/system token lanes in `style.ex`. Dark remains the default and base lane.

The source contract was amended in the same implementation wave as the CSS lane. The `theme-toggle` ban remains in force.

## Commits

- `78eb716` - Task 1: add operator surface theme validation.
- `a72488b` - Task 2: render operator surface theme attributes.
- `4715dac` - Tasks 3 and 4: add light/system token lanes and amend source contract.
- `1c32dab` - Task 5: record [165-01] decision in STATE.

## What Changed

- `Threadline.OperatorSurface.Router.threadline_operator_surface/2` documents and validates `theme: :dark | :light | :system`, default `:dark`; invalid literals raise `CompileError` with `Threadline Operator Surface theme must be one of :dark | :light | :system`.
- `Threadline.OperatorSurface.Auth.on_mount/4` assigns `:threadline_theme` as `"dark"`, `"light"`, or `"system"`.
- All ten operator LiveView roots render `data-tl-theme={@threadline_theme}`.
- `style.ex` keeps the dark base token block and adds:
  - `.threadline-ui[data-tl-theme="light"]`
  - `@media (prefers-color-scheme: light) { .threadline-ui[data-tl-theme="system"] { ... } }`
  - scoped `color-scheme: light;` inside the governed light/system lanes
  - `--tl-color-accent-inset` in dark and light/system lanes
- `style_contract_test.exs` now asserts dark-primary plus governed light/system support, keeps token purity and hex bans, keeps the `theme-toggle` ban, and verifies the active nav inset uses `var(--tl-color-accent-inset)`.
- `.planning/STATE.md` records the superseding decision:

```text
[165-01] supersedes [136-01]: dark remains default and brand-primary; light/system are supported via host `theme:` config; no runtime theme toggle in v1; the `theme-toggle` ban remains.
```

## Verification

- `mix test test/threadline/operator_surface/router_test.exs` - passed, 7 tests, 0 failures.
- `mix test test/threadline/operator_surface/live/start_live_test.exs` - passed, 16 tests, 0 failures.
- `mix test test/threadline/operator_surface/style_contract_test.exs` - passed, 23 tests, 0 failures.
- `mix compile --warnings-as-errors` - passed; compiled 13 files and generated the `threadline` app.
- `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/live/start_live_test.exs` - passed, 46 tests, 0 failures.
- `rg -n 'theme-toggle' lib/threadline/operator_surface/style.ex` - no matches.
- `rg -n '<div class="threadline-ui">' lib/threadline/operator_surface/live` - no matches.
- `rg -n 'data-tl-theme=\{@threadline_theme\}' lib/threadline/operator_surface/live` - 10 matches, one per operator LiveView root.
- `rg -n 'data-tl-theme="light"|data-tl-theme="system"|prefers-color-scheme: light|color-scheme: light|--tl-color-accent-inset' lib/threadline/operator_surface/style.ex` - confirmed dark accent inset, light lane, system media lane, scoped light color-scheme, and tokenized shell-nav active inset.

## Deviation

Tasks 3 and 4 were committed together in `4715dac` instead of separate commits. This was intentional: `style.ex` and `style_contract_test.exs` are contract-coupled, and the plan required the light/system CSS lane and source-contract amendment to land in the same wave so the contract never goes red between commits.

## Notes

- The unrelated uncommitted nav-overhaul lane remained unstaged and unreverted.
- No JavaScript, localStorage, head script, cookie, or runtime theme toggle was added.
- Full light AA mirror coverage remains Phase 168.
- Screenshot `__light__` baselines, example `theme: :system`, and docs remain Phase 169.
- Brandbook token parity remains Phase 170.

## Self-Check

PASSED. The plan's seven requirements are represented in `requirements-completed`, the focused verification suite is green, and the exact [165-01] decision text is recorded in STATE.
