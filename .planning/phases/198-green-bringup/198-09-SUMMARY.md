---
phase: 198-green-bringup
plan: 09
subsystem: ci
tags: [phoenix, optional-deps, compile-guard, mix, elixir, contract-test]

# Dependency graph
requires:
  - phase: 198-green-bringup
    provides: gap-closure roadmap identifying the eight red CI jobs holding CI required down
provides:
  - "mix verify.compile_no_optional exits 0 — the library compiles with the nine optional deps absent"
  - "a derived-roster contract test that fails a future unguarded lib/ module in its own diff"
affects: [198-11, 198-12, 198-13, PR-26, GREEN-07]

# Actuals (#2632)
actuals:
  tokens: 30858
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "file-scope `if Code.ensure_loaded?(Phoenix.X) do ... end` guard on every lib/ module that references an optional Phoenix module at compile time"
    - "derived-roster contract test (Path.wildcard + regex classification) instead of a hand-maintained allowlist, so a new unguarded module fails mix test in its own diff"

key-files:
  created:
    - test/threadline/optional_deps_contract_test.exs
  modified:
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/operator_surface/controllers/theme_controller.ex

key-decisions:
  - "Reproduced the CI failure locally by removing the compiled Phoenix app dirs from _build/dev/lib before mix compile --no-optional-deps — confirmed the exact `module Phoenix.Component is not loaded` / `module Phoenix.Controller is not loaded` errors before applying the fix, and confirmed a clean exit after"
  - "Guard used file-scope `if Code.ensure_loaded?(Phoenix.Component) do ... end` (ui.ex) / `Phoenix.Controller` (theme_controller.ex), byte-identical idiom to the ~20 other already-guarded operator-surface modules; whole module body reindented one level, verified via mix format --check-formatted"
  - "Contract-test directive regex required the `m` (multiline) modifier — `^` in a non-multiline Elixir regex only anchors the start of the whole string, not each line, which initially made the roster match zero files (a RED-before-RED bug caught during the TDD RED demonstration, not shipped)"
  - "No new mix verify.* alias added for the contract test per plan instruction (Phase 204 plans to delete verify.doc_contract; a new alias would be collateral) — it runs under plain `mix test`"

requirements-completed: [GREEN-07]

coverage:
  - id: D1
    description: "mix verify.compile_no_optional exits 0 with ui.ex and theme_controller.ex guarded"
    requirement: "GREEN-07"
    verification:
      - kind: other
        ref: "mix verify.compile_no_optional (run locally after removing _build/dev/lib/phoenix* to force a true no-optional-deps compile)"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors (deps present)"
        status: pass
      - kind: other
        ref: "mix verify.format"
        status: pass
    human_judgment: false
  - id: D2
    description: "Derived-roster contract test fails a future unguarded lib/ module in its own diff"
    requirement: "GREEN-07"
    verification:
      - kind: unit
        ref: "test/threadline/optional_deps_contract_test.exs — 3 tests, 0 failures"
        status: pass
    human_judgment: false

# Metrics
duration: 55min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 09: Guard optional-Phoenix modules and lock the roster with a derived contract test Summary

**Wrapped the two unguarded `lib/` modules (`ui.ex`, `theme_controller.ex`) in the established `Code.ensure_loaded?` idiom and added a filesystem-derived contract test so the next unguarded optional-Phoenix reference fails `mix test` in its own diff instead of surfacing only in the "Compile without optional deps" CI lane.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-08-28T14:34:00Z (approx.)
- **Completed:** 2026-08-28T15:29:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 3 (2 modified, 1 created)

## Accomplishments

- `lib/threadline/operator_surface/ui.ex` (1683 lines) now opens with
  `if Code.ensure_loaded?(Phoenix.Component) do ... end`, byte-identical
  construct to `components/logo.ex:1`, whole module body reindented one
  level; `mix format` clean.
- `lib/threadline/operator_surface/controllers/theme_controller.ex` (91
  lines) now opens with `if Code.ensure_loaded?(Phoenix.Controller) do ...
  end`, matching `controllers/export_controller.ex:1`.
- `mix verify.compile_no_optional` — the exact command `ci.yml:155` runs —
  now exits 0. Verified with a true clean rebuild (removed the compiled
  Phoenix/LiveView/HTML/PubSub/Template app dirs from `_build/dev/lib`
  before invoking the alias, since a normal local `_build` already has
  Phoenix compiled and on the code path, which would otherwise mask the
  defect the plan describes).
- New `test/threadline/optional_deps_contract_test.exs`
  (`Threadline.OptionalDepsContractTest`, `async: true`) derives the
  roster of `lib/**/*.ex` files with a compile-time `use`/`import`/`require`
  of an optional Phoenix module (`Phoenix.Component`, `Phoenix.LiveView`,
  `Phoenix.Controller`, `Phoenix.HTML`, `Phoenix.PubSub`) via
  `Path.wildcard` + regex, asserts the roster non-empty, then asserts every
  roster member is guarded — set comparison via `Enum.reject`, not a count.
  A third test asserts `coverage/snapshot.ex` (moduledoc-only mention) is
  absent from the roster, proving the classifier doesn't over-match on
  prose.
- `lib/threadline/operator_surface/coverage/snapshot.ex` untouched
  (`git diff --exit-code` reports no changes).

## Task Commits

1. **Task 1: Guard the two unguarded optional-Phoenix modules** - `db217c54` (fix)
2. **Task 2: Derived-roster contract test so the next unguarded module fails in its own diff** - `6c047bda` (test)

_Note: Task 2 is `tdd="true"` at the task level, not a `type: tdd` plan. The
plan's own acceptance criteria call for demonstrating RED-then-GREEN inline
within the single task (unguard, confirm the test names the path, restore,
confirm green) rather than separate RED/GREEN/REFACTOR commits, since the
implementation (the guards) already existed from Task 1. One commit for the
test file matches that instruction._

## Files Created/Modified

- `lib/threadline/operator_surface/ui.ex` - file-scope `Code.ensure_loaded?(Phoenix.Component)` guard added; module body reindented one level, no public API change
- `lib/threadline/operator_surface/controllers/theme_controller.ex` - file-scope `Code.ensure_loaded?(Phoenix.Controller)` guard added; module body reindented one level, no public API change
- `test/threadline/optional_deps_contract_test.exs` - new `Threadline.OptionalDepsContractTest`, derived-roster guard-coverage contract

## Decisions Made

- Local reproduction of the CI defect required removing the already-compiled
  Phoenix/LiveView/HTML/PubSub/Template app directories from `_build/dev/lib`
  before running `mix compile --no-optional-deps`, because a normal
  `mix deps.get` + prior full compile leaves those optional apps compiled
  and on the Erlang code path regardless of the `--no-optional-deps` flag —
  `Code.ensure_loaded?/1` would report `true` even though the flag excludes
  them from the *current* app's declared dependency compilation. This
  matches how a genuinely fresh CI checkout (no `_build` at all) behaves
  and is the only way to faithfully reproduce and then disprove the defect
  locally.
- The contract test's classification regex needed the Elixir `m` (multiline)
  modifier on `^` — without it the anchor matches only the start of the
  whole file content, not each line, and the roster silently matched zero
  files. Caught during the plan's own required RED-phase demonstration
  (the "non-empty roster" test failed first, correctly, rather than the
  fully-formed unguarded-module test firing incorrectly) — not shipped.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix test test/threadline/operator_surface/` shows pre-existing
  environmental flakiness unrelated to this change: two consecutive runs on
  the **unmodified** original files (before Task 1's guard) produced 46 and
  then 47 failures respectively, with a different specific failing test each
  time (all `relation "audit_changes"/"audit_transactions" does not exist`
  Postgrex errors against the local Docker Postgres). This matches the
  project memory note on local test-DB flakiness. Baseline (pre-change,
  second run): 756 tests, 47 failures. Post-change (Task 1 guarded files,
  first run): 756 tests, 47 failures — same total count, one different
  individual test failing, consistent with pre-existing non-determinism
  rather than a regression introduced by the guard. No new failures
  attributable to this plan's changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `mix verify.compile_no_optional` — one of the eight red CI jobs holding
  `CI required` (and therefore GREEN-07 / PR #26) down — now passes locally
  with the exact command CI runs.
- The remaining seven red CI jobs from the Phase 198 gap-closure roadmap are
  out of this plan's scope; see `.planning/phases/198-green-bringup/` for
  the other 198-* gap-closure plans.
- No blockers for downstream 198-* plans; this plan's changes are isolated
  to `lib/threadline/operator_surface/{ui.ex,controllers/theme_controller.ex}`
  and the new test file — no public module, function, or arity changes.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
