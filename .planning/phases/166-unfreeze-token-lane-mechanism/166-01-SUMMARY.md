---
phase: 166-unfreeze-token-lane-mechanism
plan: 01
subsystem: ui
tags: [operator-surface, theme, light-mode, css-tokens, source-contract]
requires: []
provides:
  - "Compile-validated theme: :dark | :light | :system host option"
  - "Server-rendered data-tl-theme attributes on operator LiveView roots"
  - "Additive light and scoped system CSS token lanes"
  - "Source contract amended for dark-default theme lanes"
affects: [operator-surface, v1.36-light-mode, component-retune, accessibility-verification]
tech-stack:
  added: []
  patterns:
    - "Router opts carry compile-validated theme selection into Auth.on_mount/4"
    - "Dark remains the base .threadline-ui lane; light/system are scoped token overrides"
key-files:
  created:
    - .planning/phases/166-unfreeze-token-lane-mechanism/166-01-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/operator_surface/auth.ex
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/live/start_live.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/evidence_live.ex
    - lib/threadline/operator_surface/live/coverage_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/live/policy_redaction_live.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - lib/threadline/operator_surface/live/row_history_live.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/live/actor_live.ex
    - test/threadline/operator_surface/router_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/operator_surface/live/actor_live_test.exs
    - test/threadline/operator_surface/live/start_live_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - .planning/STATE.md
key-decisions:
  - "[165-01] supersedes [136-01]: dark remains default and brand-primary; light/system are supported via host `theme:` config; no runtime theme toggle in v1; the `theme-toggle` ban remains."
patterns-established:
  - "Theme values are literal atoms validated in the router macro and normalized once in Auth.on_mount/4."
  - "System mode uses only scoped CSS under @media (prefers-color-scheme: light)."
requirements-completed: [THEME-01, THEME-02, THEME-03, THEME-04, TOKEN-01, TOKEN-02, TOKEN-03]
duration: 22 min
completed: 2026-06-13
---

# Phase 166 Plan 01: Unfreeze Token Lane Mechanism Summary

**Host-configured operator-surface theme lanes with first-paint data attributes, additive light/system CSS tokens, and source-first contract coverage**

## Performance

- **Duration:** 22 min
- **Started:** 2026-06-13T01:16:44Z
- **Completed:** 2026-06-13T01:39:15Z
- **Tasks:** 5
- **Files modified:** 19

## Accomplishments

- Added `theme: :dark | :light | :system` to `threadline_operator_surface/2`, defaulting to `:dark` and raising a compile-time `CompileError` for invalid literals with the required allowed-value text.
- Assigned a normalized `@threadline_theme` during `Threadline.OperatorSurface.Auth.on_mount/4` and rendered `data-tl-theme` on all ten operator LiveView roots.
- Added the Phase 166 light lane plus scoped `:system` media lane in `style.ex`, including light status tints, glass/shadow/focus values, and `--tl-color-accent-inset`.
- Amended `style_contract_test.exs` so dark remains the base lane, light/system are governed assertions, and `theme-toggle` remains banned.
- Recorded `[165-01]` in `STATE.md` as superseding `[136-01]`.
- Closed the required code-review critical findings by making export authorization callback exceptions fail closed and removing ActorLive atom creation from URL actor kinds.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add compile-validated theme option to the router macro** - `c64379e` (`feat`)
2. **Task 2: Assign normalized theme and render data-tl-theme on all roots** - `e730f2f` (`feat`)
3. **Task 3: Add light/system token lanes and tokenize active nav inset** - `78b90c9` (`feat`)
4. **Task 4: Amend source contracts in the same wave** - `b5533c1` (`test`)
5. **Task 5: Record [165-01] and run focused verification** - `0cfd98a` (`docs`)

**Code review remediation:** `76a7f51` (`fix`) closed CR-01 and CR-02 from the required code review gate.

## Verification

- `mix compile --warnings-as-errors` - PASS.
- `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/live/start_live_test.exs` - PASS, 44 tests, 0 failures.
- `mix test test/threadline/operator_surface/live/actor_live_test.exs` - PASS, 10 tests, 0 failures.
- `mix test test/threadline/operator_surface/live/timeline_live_test.exs` - PASS, 35 tests, 0 failures.
- `mix test test/threadline/operator_surface/router_test.exs` - PASS, 7 tests, 0 failures.
- `mix test test/threadline/operator_surface/live/start_live_test.exs` - PASS, 15 tests, 0 failures.
- `mix test test/threadline/operator_surface/style_contract_test.exs` - PASS, 22 tests, 0 failures.
- `rg -n 'theme-toggle' lib/threadline/operator_surface/style.ex` - PASS, no matches.
- `rg -n '<div class="threadline-ui">' lib/threadline/operator_surface/live` - PASS, no matches.
- `rg -n 'data-tl-theme=\{@threadline_theme\}' lib/threadline/operator_surface/live` - PASS, 10 root occurrences.
- `rg -n 'String\.to_atom\b' lib/threadline/operator_surface/live/actor_live.ex` - PASS, no matches.
- `rg -n '\[165-01\] supersedes \[136-01\]' .planning/STATE.md` - PASS.

## Files Created/Modified

- `lib/threadline/operator_surface/router.ex` - Documents and compile-validates the public `theme:` mount option.
- `lib/threadline/operator_surface/auth.ex` - Normalizes and assigns `:threadline_theme`.
- `lib/threadline/operator_surface/live/*.ex` - Renders `data-tl-theme={@threadline_theme}` on all ten root surfaces.
- `lib/threadline/operator_surface/style.ex` - Adds light/system token lanes and tokenizes the active shell-nav inset.
- `test/threadline/operator_surface/router_test.exs` - Covers valid `:system` and invalid `:sepia` compile behavior.
- `test/threadline/operator_surface/live/actor_live_test.exs` - Covers ActorLive atom-safety source contract.
- `test/threadline/operator_surface/live/start_live_test.exs` - Covers default dark and configured system first HTML.
- `test/threadline/operator_surface/live/timeline_live_test.exs` - Covers export authorization exception fail-closed behavior.
- `test/threadline/operator_surface/style_contract_test.exs` - Replaces dark-only refutes with theme-aware source assertions.
- `.planning/STATE.md` - Records `[165-01]` and phase execution state.

## Decisions Made

- `[165-01] supersedes [136-01]: dark remains default and brand-primary; light/system are supported via host `theme:` config; no runtime theme toggle in v1; the `theme-toggle` ban remains.`

## Deviations from Plan

The implementation tasks executed exactly as planned. The required code review gate then found two pre-existing critical issues in files Phase 166 had touched; both were fixed as follow-up remediation in `76a7f51`.

### Auto-fixed Issues

**1. [Rule 1 - Security] Export authorization callback exceptions failed open**
- **Found during:** Code review gate after Task 5
- **Issue:** `exports_enabled_for_socket?/3` returned `true` when `export_authorize_fn` raised, enabling export affordances after host authorization failed unexpectedly.
- **Fix:** Changed the rescue path to return `false`.
- **Files modified:** `lib/threadline/operator_surface/auth.ex`, `test/threadline/operator_surface/live/timeline_live_test.exs`
- **Verification:** `mix test test/threadline/operator_surface/live/timeline_live_test.exs`
- **Committed in:** `76a7f51`

**2. [Rule 1 - Security] ActorLive created atoms from untrusted route input**
- **Found during:** Code review gate after Task 5
- **Issue:** Unknown `/actors/:kind/:id` values fell back to `String.to_atom/1`, permanently growing the BEAM atom table.
- **Fix:** Route kind parsing now uses `String.to_existing_atom/1` only and maps unknown kinds to the existing invalid-actor branch.
- **Files modified:** `lib/threadline/operator_surface/live/actor_live.ex`, `test/threadline/operator_surface/live/actor_live_test.exs`
- **Verification:** `mix test test/threadline/operator_surface/live/actor_live_test.exs`; `rg -n 'String\.to_atom\b' lib/threadline/operator_surface/live/actor_live.ex`
- **Committed in:** `76a7f51`

---

**Total deviations:** 2 auto-fixed security issues.
**Impact on plan:** Both fixes were in Phase 166-touched files and reduced risk without changing the public theme mechanism.

## Issues Encountered

- The isolated manual worktree did not have dependencies installed initially, so the first `mix test` command failed before tests ran. `mix deps.get` resolved this in the worktree; no source changes were required.
- `mix compile --warnings-as-errors` emitted an upstream `sweet_xml` dependency warning while compiling dependencies, but the command exited 0 and project compilation passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 167 can retune component-level light treatments on top of the now-real mechanism. The planned human gate remains: review the rendered light surface before spending retune effort.

## Self-Check: PASSED

- All five plan tasks are committed.
- Summary exists at `.planning/phases/166-unfreeze-token-lane-mechanism/166-01-SUMMARY.md`.
- Key modified files exist on disk.
- Focused compile, test, source grep, and decision checks passed.

---
*Phase: 166-unfreeze-token-lane-mechanism*
*Completed: 2026-06-13*
