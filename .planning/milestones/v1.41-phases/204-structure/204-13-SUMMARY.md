---
phase: 204-structure
plan: 13
subsystem: test-support
tags: [refactor, tests, operator-surface, templates, liveview]
status: complete

requires:
  - phase: 204-structure
    provides: "lib banner-free, credo register 12 (204-12)"
provides:
  - "test/support/operator_surface_case.ex: Threadline.OperatorSurfaceTest.Layouts, .Router (__using__: accepts, browser_plugs), .Endpoint (__using__: router, parsers, json_decoder, signing_salt), Threadline.OperatorSurfaceCase (__using__: endpoint; start_endpoint!/2)"
  - "The nine live/*_live_test.exs files run on the shared templates with no `use Phoenix.Endpoint` / `use Phoenix.Router` of their own"
affects: [204-14, test-structure-contract, STRUCT-05]

actuals:
  tokens: 13700     # chars/4 over the realized diff b5bc5e4a..25bf630c (54812 chars)
  tasks: 3
  commits: 9        # MEASURED: git rev-list --count b5bc5e4a..HEAD before the SUMMARY commit
plan_head_before: b5bc5e4a643dd69263cc9652001d0457ee99a677

tech-stack:
  added: []
  patterns:
    - "Test endpoint/router templates as plain __using__ macros; each file keeps its own scope + threadline_operator_surface mount and helper defs after the use line"
    - "start_endpoint!/2 puts the endpoint env before start_supervised! and restores the prior env (or deletes it) in on_exit"

key-files:
  created:
    - test/support/operator_surface_case.ex
  modified:
    - test/threadline/operator_surface/live/actor_live_test.exs
    - test/threadline/operator_surface/live/coverage_live_test.exs
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/operator_surface/live/row_history_live_test.exs
    - test/threadline/operator_surface/live/start_live_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs

key-decisions:
  - "The session cookie key is `\"_\" <> String.replace(Macro.underscore(__MODULE__), \"/\", \"_\")`. It is derived from Macro.underscore as D-16 says, with `/` replaced because `/` is not a valid cookie-name character. No test asserts a cookie key."
  - "`parsers: false` leaves Plug.Parsers out at macro-expansion time (the plug AST is built outside the quote), so the gating variant 204-14 needs is behavior-identical."
  - "The shared Layouts always define render(\"500.html\", _). Three files (evidence, export_status, policy_redaction) had a Layouts without it; their render_errors view now has a working 500 template. No test reaches that path."
  - "timeline ActorRouter's `:put_test_actor` now runs after put_root_layout instead of before it (the template adds browser_plugs after the layout, per the plan). put_test_actor only assigns :current_user, and put_root_layout only sets a private, so the order does not matter; timeline's 53 tests pass."
  - "The mechanical migration was done by one script (/tmp/p13/migrate.py) that asserts on exact boilerplate shapes, so any non-standard endpoint or pipeline would have failed loudly instead of being rewritten. All nine files matched the default variant."

requirements-completed: []
requirements-advanced: [STRUCT-05]  # the remaining 8 migrations and the structure contract land in 204-14

coverage:
  - id: D1
    description: "Shared operator-surface test templates in test/support, guarded by Code.ensure_loaded?(Phoenix.LiveView), each module with a @moduledoc"
    requirement: STRUCT-05
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix verify.compile_no_optional exit 0; mix compile --force --warnings-as-errors exit 0; mix credo --strict exit 0 (repo-wide)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Nine LiveView test files migrated with unchanged per-file test counts and no failures"
    requirement: STRUCT-05
    verification:
      - kind: unit
        ref: "per-file mix test before/after (table in body); mix test test/threadline/operator_surface/live 190 tests, 0 failures; full mix test 1769 tests, 0 failures (1 excluded), same as the plan base"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-09-24
---

# Phase 204 Plan 13: Shared Operator-Surface Test Templates Summary

**`test/support/operator_surface_case.ex` now provides the Layouts, Router, and Endpoint templates plus `Threadline.OperatorSurfaceCase.start_endpoint!/2`. All nine `live/*_live_test.exs` files use them. Each file keeps its own module names, mount paths and options, router helper functions, and `async:` flag, and every file has the same test count as before.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-24T03:07:39Z
- **Completed:** 2026-09-24T03:14:01Z
- **Tasks:** 3
- **Files modified:** 10 (1 created)

## Test counts per migrated file

| File | Before | After | Endpoints | Routers | async |
|---|---|---|---|---|---|
| actor_live_test.exs | 13 | 13 | 2 | 2 | false (unchanged) |
| coverage_live_test.exs | 22 | 22 | 1 | 1 | false (unchanged) |
| evidence_live_test.exs | 13 | 13 | 1 | 1 | false (unchanged) |
| export_status_live_test.exs | 27 | 27 | 1 | 1 | false (unchanged) |
| policy_redaction_live_test.exs | 10 | 10 | 1 | 1 | false (unchanged) |
| retention_history_live_test.exs | 23 | 23 | 1 | 1 | false (unchanged) |
| row_history_live_test.exs | 8 | 8 | 2 | 2 | false (unchanged) |
| start_live_test.exs | 21 | 21 | 3 | 3 | false (unchanged) |
| timeline_live_test.exs | 53 | 53 | 5 | 5 | false (unchanged) |
| **live/ total** | **190** | **190** | 17 | 17 | |

Every "after" run had 0 failures. The full suite had 1769 tests, 0 failures (1 excluded) after the last commit, the same count as at the plan base (204-12's final run).

## Task Commits

1. **Task 1 (tracer): templates + actor_live_test**, `7e043f6a`. Tracer gate: the task verify (actor test 13/0, verify.compile_no_optional, credo on both files) passed before any expansion.
2. **Task 2:** `39991b07` coverage, `375b9e95` evidence, `2969acc4` export_status, `84949920` policy_redaction
3. **Task 3:** `f52b7a85` retention_history, `fc09c30d` row_history, `cf1b577f` start, `25bf630c` timeline

## Acceptance criteria

- Task 1: `grep -c 'use Phoenix.Endpoint'` actor = 0; `@moduledoc """` count = 4; first line is the LiveView guard; `def scope_operator_query` count = 2. PASS
- Task 2: `grep -l 'use Phoenix.Endpoint'` over the four files prints nothing; credo --strict on the four exits 0. PASS
- Task 3: no live test file defines `use Phoenix.Endpoint` (count 0); `use Phoenix.Router` count 0 in every live file; `browser_plugs: [:put_test_actor]` count = 1 in timeline; full suite 1769/0. PASS

## Plan-level verification

- `mix test`: 1769 tests, 0 failures, 1 excluded.
- `MIX_ENV=test mix verify.compile_no_optional`: exit 0.
- `mix compile --force --warnings-as-errors`: exit 0. `mix format --check-formatted`: exit 0.
- `mix credo --strict` (repo-wide): exit 0.
- The browser lane was not run. This plan changes only test files, so no rendered lib output moved (D-00b).

## Deviations from Plan

None. The plan was executed as written.

Notes:
- The full-suite log has one line: `[warning] no configuration found for otp_app :threadline and module Threadline.OperatorSurface.ExportControllerTest.Endpoint`. It comes from `exports_mix_parity_test` starting `ExportControllerTest.Endpoint`, which this plan did not touch. That borrowed-endpoint coupling is the one D-17 assigns to 204-14. I did not re-run the base to prove the line existed before this plan, but neither file involved changed here.
- The HALT clause was not needed. Every file migrated without changing an assertion.

## Known Stubs

None.

## Threat Flags

None. T-204-28 was mitigated as planned: router helper functions stayed in each file and test counts were compared per file. T-204-29 was also mitigated: `start_endpoint!/2` puts the env before start, restores it in `on_exit`, and endpoint names stay unique per file.

## Next Phase Readiness

- 204-14 can migrate the remaining eight files. Use `parsers: [:urlencoded, :json], json_decoder: Jason, accepts: [...]` for export_controller and `parsers: false` for gating's ExportsDisabledEndpoint. After that, add the structure contract.

---
*Phase: 204-structure*
*Completed: 2026-09-24*

## Self-Check: PASSED

- test/support/operator_surface_case.ex exists. All nine commits (7e043f6a, 39991b07, 375b9e95, 2969acc4, 84949920, f52b7a85, fc09c30d, cf1b577f, 25bf630c) exist on the branch.
