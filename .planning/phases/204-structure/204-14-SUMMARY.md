---
phase: 204-structure
plan: 14
subsystem: test-support
tags: [refactor, tests, operator-surface, templates, contract]
status: complete

requires:
  - phase: 204-structure
    provides: "shared operator-surface test templates + nine live test migrations (204-13)"
provides:
  - "export_controller, exports_mix_parity, breadcrumb, card_nesting_regression, copy_contract, gating, rendered_output_contract, skip_link, and transaction_live tests run on the shared templates"
  - "Threadline.OperatorSurface.ExportsMixParityTest.{Router, Endpoint}: the parity test no longer loads or starts ExportControllerTest.Endpoint"
  - "test/threadline/test_structure_contract_test.exs: Threadline.TestStructureContractTest with @endpoint_allowlist, @router_allowlist, and a pure validate/3"
affects: [204-15, STRUCT-05]

actuals:
  tokens: 11550     # chars/4 over the realized diff 1c695d22..79271c37 (46202 chars)
  tasks: 3
  commits: 11       # MEASURED: git rev-list --count 1c695d22..HEAD before the SUMMARY commit
plan_head_before: 1c695d2241d16840a99f4b224eaf1f846b9d53ac

tech-stack:
  added: []
  patterns:
    - "Structure contract as a pure validate(files, endpoint_allowlist, router_allowlist) over {path, source} pairs; detector tests feed synthetic sources, the real-tree test feeds the live scan"
    - "Synthetic `use` lines are built by string concatenation so the contract file never matches its own scan"

key-files:
  created:
    - test/threadline/test_structure_contract_test.exs
  modified:
    - test/threadline/operator_surface/controllers/export_controller_test.exs
    - test/threadline/operator_surface/exports_mix_parity_test.exs
    - test/threadline/operator_surface/breadcrumb_test.exs
    - test/threadline/operator_surface/card_nesting_regression_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/gating_test.exs
    - test/threadline/operator_surface/rendered_output_contract_test.exs
    - test/threadline/operator_surface/skip_link_test.exs
    - test/threadline/operator_surface/transaction_live_test.exs

key-decisions:
  - "No template option was added. export_controller's routers used to skip fetch_live_flash and put_root_layout. The template adds both. The export controller never renders a template or reads flash, so this changes nothing, and all 28 tests pass."
  - "Export test modules import only `start_endpoint!: 1` from Threadline.OperatorSurfaceCase instead of `use`-ing it. They do not use Phoenix.LiveViewTest, and they keep their existing `import Phoenix.ConnTest` and `@endpoint` lines."
  - "Per-endpoint salts, cookie keys, and secret_key_base values (x/y/d/a, b, c, g, r) collapsed to the template constants. A grep found no test that asserts on them."
  - "The copy_contract and rendered_output_contract `<title>` variants collapsed to the shared \"Test\" title. No assertion or fixture reads the title, and both files keep their test counts with 0 failures, so the HALT clause was not triggered."
  - "Task 3 used test(204-14) for both the RED and GREEN commits because the plan scopes every commit as test(204-14) and the contract lives in a test file."

requirements-completed: [STRUCT-05]

coverage:
  - id: D1
    description: "Export controller variant on the templates; exports_mix_parity decoupled and runs alone"
    requirement: STRUCT-05
    verification:
      - kind: unit
        ref: "mix test export_controller_test + exports_mix_parity_test → 31 tests, 0 failures; exports_mix_parity_test alone --seed 0 → 3 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Seven page-level test files migrated with unchanged counts"
    requirement: STRUCT-05
    verification:
      - kind: unit
        ref: "per-file mix test before/after (table in body)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Structure contract with reasoned, stale-checked allowlist"
    requirement: STRUCT-05
    verification:
      - kind: unit
        ref: "mix test test/threadline/test_structure_contract_test.exs → 7 tests, 0 failures (RED run: 4 detector failures with a stub validate/3); full mix test 1776 tests, 0 failures"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-09-24
---

# Phase 204 Plan 14: Remaining Template Migrations and Test Structure Contract Summary

**The last nine operator-surface test files now use the shared templates. exports_mix_parity_test has its own endpoint and no longer borrows `ExportControllerTest.Endpoint`. `Threadline.TestStructureContractTest` fails the suite on any hand-rolled `use Phoenix.Endpoint` or `use Phoenix.Router` that is not covered by a reasoned, stale-checked allowlist entry.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-09-24T03:15:38Z
- **Completed:** 2026-09-24T03:21:12Z
- **Tasks:** 3
- **Files modified:** 10 (1 created)

## Test counts per file

| File | Before | After | Notes |
|---|---|---|---|
| controllers/export_controller_test.exs | 28 | 28 | 4 endpoints (`parsers: [:urlencoded, :json], json_decoder: Jason`), 4 routers (`accepts: ["html", "csv", "json"]`) |
| exports_mix_parity_test.exs (run alone) | 31 | 3 | The old 31 included the 28 export tests pulled in by `Code.require_file`. The file's own test count is 3 before and after. Run together, the two files still total 31. |
| breadcrumb_test.exs | 2 | 2 | |
| card_nesting_regression_test.exs | 2 | 2 | `# Structural debt:` sites untouched (204-15) |
| copy_contract_test.exs | 13 | 13 | `<title>Copy contract</title>` → shared "Test" |
| gating_test.exs | 3 | 3 | ExportsDisabledEndpoint `parsers: false` |
| rendered_output_contract_test.exs | 9 | 9 | `<title>Rendered output contract</title>` → shared "Test"; structural-debt sites untouched |
| skip_link_test.exs | 10 | 10 | |
| transaction_live_test.exs | 14 | 14 | 2 endpoints, 2 routers |
| test_structure_contract_test.exs | (new) | 7 | |

Every "after" run had 0 failures. Full suite: **1776 tests, 0 failures, 1 excluded**. That is 1769 at the plan base plus the 7 new contract tests.

## Final allowlist

`@endpoint_allowlist`:
- `test/threadline/operator_surface/stress_router_test.exs`: mounts the stress surface with its own macro (`threadline_operator_surface_stress`) and `live_session :threadline_stress`, and compiles throwaway routers, so its endpoints do not fit the shared template.

`@router_allowlist`:
- `test/threadline/operator_surface/router_test.exs`: throwaway routers built with `Code.compile_quoted` are the subject under test.
- `test/threadline/operator_surface/stress_router_test.exs`: same reason as above.
- `test/support/stress_router_prod_compile.exs`: runs under `MIX_ENV=prod mix run --no-start`, where test/support is not compiled.

Neither 204-13 nor 204-14 recorded a HALT entry.

## Task Commits

1. **Task 1 (tracer):** `d885a65b` export_controller, `a8255aa3` exports_mix_parity. Tracer gate: both verify commands were re-run and passed before expansion (31/0 together, 3/0 alone with `--seed 0`).
2. **Task 2:** `c3c44880` breadcrumb, `f74fd7cb` card_nesting_regression, `4acc87e4` copy_contract, `2e6aee31` gating, `47e43e32` rendered_output_contract, `06cefc82` skip_link, `c59f4ef1` transaction_live
3. **Task 3 (TDD):** `10dbfc92` RED (stub `validate/3`, 7 tests / 4 detector failures), `79271c37` GREEN (7 tests, 0 failures)

## Acceptance criteria

- Task 1: `grep -c ExportControllerTest exports_mix_parity_test.exs` = 0. `use Phoenix.Endpoint` count in export_controller_test = 0. `parsers: [:urlencoded, :json]` count = 4. PASS
- Task 2: `grep -l 'use Phoenix.Endpoint'` over the seven files prints nothing. `grep -c 'parsers: false' gating_test.exs` = 1. PASS
- Task 3: `router_test.exs` is present in the contract, and every reason is a non-empty string (checked by a test). `grep -rlE '^\s*use Phoenix\.Endpoint' test` lists only `test/support/operator_surface_case.ex` and `test/threadline/operator_surface/stress_router_test.exs`. PASS

## Plan-level verification

- `mix test`: 1776 tests, 0 failures, 1 excluded (exit 0).
- The `no configuration found for otp_app :threadline and module ...ExportControllerTest.Endpoint` warning that 204-13 reported no longer appears in the full-suite log.
- `MIX_ENV=test mix verify.compile_no_optional`: exit 0. `mix credo --strict` (repo-wide): exit 0. `mix compile --force --warnings-as-errors`: exit 0. `mix format --check-formatted`: exit 0.
- The browser lane was not run. Only test files changed, so no rendered lib output moved (D-00b).

## Deviations from Plan

None. The plan was executed as written. The 204-13 script `/tmp/p13/migrate.py` migrated six of the seven Task 2 files unchanged. Gating was hand-migrated because its endpoint has no Plug.Parsers, and export_controller was hand-migrated because it uses the csv/json variant.

## TDD Gate Compliance

RED `10dbfc92` precedes GREEN `79271c37`. Both commits use the `test(204-14)` type because the plan scopes every commit that way and the contract lives in a test file. No REFACTOR commit was needed.

## Known Stubs

None.

## Threat Flags

None. T-204-30 was mitigated: per-file counts were compared, every gating and export case was kept, and `parsers: false` keeps the gating endpoint without Plug.Parsers. T-204-31 was mitigated: every allowlist entry carries a reason and is stale-checked by `validate/3`.

## Next Phase Readiness

- 204-15 can drain the `# Structural debt:` sites in rendered_output_contract_test and card_nesting_regression_test. This plan did not touch them.

---
*Phase: 204-structure*
*Completed: 2026-09-24*
