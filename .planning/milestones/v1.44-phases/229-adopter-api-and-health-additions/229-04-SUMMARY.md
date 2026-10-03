---
phase: 229-adopter-api-and-health-additions
plan: 04
subsystem: cli
tags: [mix-task, health, trigger-coverage, postgres, jsonb, telemetry]

# Dependency graph
requires:
  - phase: 229-03
    provides: "mix threadline.health.coverage --strict, the OptionParser strict spec and mutual-exclusion raise pattern this plan widens"
provides:
  - "mix threadline.health.coverage --all-schemas (HLTH-02)"
  - "@doc false Threadline.Health.classify/3"
  - "@doc false Threadline.Health.coverage_by_schema/1"
  - "@doc false Threadline.Health.CoverageSchemas.all_tables/1"
  - "the --all-schemas JSON envelope (schemas/summary) and SCHEMA-column table renderer"
  - "phase 229's after suite wall clock (D-28), completing evidence/SC5-wallclock.md"
affects: [230-rebalance-net-suite-check-and-0-12-0]

# Actuals (#2632)
actuals:
  tokens: 12900
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Two batched catalog queries (tables, covering triggers) across every reportable schema instead of a per-schema loop, classified through one shared pure function so --schema and --all-schemas agree by construction"
    - "Extension-member schema exclusion via pg_depend (classid = 'pg_namespace'::regclass, deptype = 'e'), never pg_extension's own schema column, which would wrongly drop public"
    - "Jason.OrderedObject for a JSON envelope whose key order must survive encoding past 32 keys, where a plain map falls back to hash order"

key-files:
  created: []
  modified:
    - lib/threadline/health.ex
    - lib/threadline/health/coverage_schemas.ex
    - lib/mix/tasks/threadline.health.coverage.ex
    - lib/threadline/health/legacy_key_findings.ex
    - test/threadline/operator_surface/coverage_mix_test.exs
    - test/threadline/operator_surface/coverage_doc_contract_test.exs
    - test/threadline/health_test.exs
    - guides/domain-reference.md
    - guides/operator-surface.md
    - guides/configuration-and-commands.md
    - CHANGELOG.md
    - .planning/phases/229-adopter-api-and-health-additions/evidence/SC5-wallclock.md

key-decisions:
  - "Dropped a precondition test asserting citext sits in public's pg_extension — true only on the original research DB, not on a freshly-migrated partitioned-CI database; the real exclusion behavior stays fully proven by the ALTER EXTENSION plpgsql ADD SCHEMA fixture, which needs no specific extension pre-installed"
  - "Fixed a pre-existing Dialyzer :unmatched_returns finding in plan 02's legacy_key_findings.ex (binding the transaction-local SET statement_timeout query's return to _) after confirming via a PLT rebuild that it was a real finding, not a cache-miss false positive"
  - "A schema is 'reported' under --all-schemas when it has at least one coverage row or at least one finding; this single predicate drives the JSON envelope, the table renderer, and the strict gate's union, so the three never disagree"

requirements-completed: [HLTH-02]

coverage:
  - id: D1
    description: "mix threadline.health.coverage --all-schemas reports every reportable schema in one batched catalog snapshot (two queries total, never a per-schema loop), as a schema-keyed table (leading SCHEMA column, per-schema rollup, grand total) or a JSON envelope ({\"schemas\": {...}, \"summary\": {...}}) whose schemas values are byte-identical to --schema=NAME --json's output for that schema"
    requirement: "HLTH-02"
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 tracer) the golden test: schemas.public from --all-schemas --json equals --schema=public --json"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 tracer) the summary object has exactly the six locked keys"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 edges) table format: SCHEMA-leading header, rollup, and the across-K-schemas summary"
        status: pass
    human_judgment: false
  - id: D2
    description: "--schema and --all-schemas raise Mix.Error with the exact mutual-exclusion message before the repo starts, in either flag order, including an explicit --schema=public"
    requirement: "HLTH-02"
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 tracer) --schema=public plus --all-schemas raises the exact mutual-exclusion message"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 tracer) --all-schemas plus --schema=x (either flag order) raises the exact mutual-exclusion message"
        status: pass
    human_judgment: false
  - id: D3
    description: "Schema enumeration excludes extension-member schemas via pg_depend (proven with a real ALTER EXTENSION plpgsql ADD SCHEMA fixture) while keeping public; a schema with zero reportable tables and zero findings is omitted, but a schema with a finding and zero coverage rows (union) still appears; same-named tables in different schemas are reported separately (adjacency); a quoted mixed-case schema name is reported verbatim with keys in sorted order; 33+ schemas round-trip byte-identically across two consecutive runs"
    requirement: "HLTH-02"
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 edges) extension-member schema is excluded from both JSON and table output; public is present"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 edges) omission: a schema with only an excluded audit-table name and no finding is absent"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 edges) union: a schema with zero coverage rows but an :error finding still appears"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 edges) adjacency: hcov_adj_a.items and hcov_adj_b.items each appear under their own schema"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 edges) encoding/ordering: a quoted mixed-case schema appears verbatim and keys stay sorted"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 edges) determinism: two consecutive --all-schemas --json runs are byte-identical with sorted keys"
        status: pass
    human_judgment: false
  - id: D4
    description: "--all-schemas emits exactly one [:threadline, :health, :checked] telemetry event per run with grand totals matching the JSON summary; --strict --all-schemas exits 1 when any reported schema has an :error finding and never gates on uncovered tables or warnings in any schema"
    requirement: "HLTH-02"
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 edges) telemetry: --all-schemas emits exactly one [:threadline, :health, :checked] event with grand totals"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_mix_test.exs#--all-schemas (HLTH-02 edges) strict union: --strict --all-schemas exits 1 when any reported schema has an :error finding"
        status: pass
    human_judgment: false
  - id: D5
    description: "classify/3 is a pure, directly-unit-tested extraction shared by trigger_coverage/1 and coverage_by_schema/1, and trigger_coverage/1's public result for public is unchanged after the extraction"
    requirement: "HLTH-02"
    verification:
      - kind: unit
        ref: "test/threadline/health_test.exs#classify/3 — extracted per-table classifier (HLTH-02)"
        status: pass
      - kind: unit
        ref: "test/threadline/health_test.exs#trigger_coverage/1 result for public is unchanged after the classify/3 extraction"
        status: pass
    human_judgment: false
  - id: D6
    description: "The flag, envelope, omission/union rule, extension-schema exclusion and mutual exclusion are documented in the task moduledoc, domain-reference.md, operator-surface.md and configuration-and-commands.md; the pinned OptionParser spec literal is updated; CHANGELOG Unreleased gains one --all-schemas Added bullet with no Breaking changes entry"
    requirement: "HLTH-02"
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/coverage_doc_contract_test.exs#--all-schemas docs (229-04 HLTH-02)"
        status: pass
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D7
    description: "evidence/SC5-wallclock.md's After section is complete (three mix test runs + median, one verify.test_partitioned run, this plan's own test cost, a comparison against the before section and the phase-225 baseline) and mix ci.all is green, closing the phase"
    requirement: "HLTH-02"
    verification:
      - kind: other
        ref: "mix ci.all exit 0 at 493fa333 (local run, logged in this SUMMARY's Issues Encountered)"
        status: pass
    human_judgment: false

duration: ~1h45m
completed: 2026-10-02
status: complete
---

# Phase 229 Plan 04: `mix threadline.health.coverage --all-schemas` Summary

**`--all-schemas` reports every reportable PostgreSQL schema's trigger coverage in one batched two-query catalog snapshot — a schema-keyed table or a `{"schemas": {...}, "summary": {...}}` JSON envelope whose per-schema payload is byte-identical to `--schema=NAME --json` — excludes extension-member schemas via `pg_depend`, and closes phase 229 with the after suite wall clock and a green `mix ci.all`.**

## Performance

- **Duration:** ~1h45m
- **Started:** 2026-10-02T13:10:00-04:00 (approx.)
- **Completed:** 2026-10-02T15:10:10-04:00
- **Tasks:** 3 completed (plus 2 small gate-closing fixes)
- **Files modified:** 12

## Accomplishments
- `Threadline.Health.classify/3` (`@doc false`) extracts the pure per-table classification `trigger_coverage/1` already used; `trigger_coverage/1` now calls it, so its public result is unchanged (pinned by a direct equivalence test)
- `Threadline.Health.coverage_by_schema/1` (`@doc false`) drives every reportable schema from exactly two batched catalog queries — one for tables (`CoverageSchemas.all_tables/1`), one for covering triggers across schemas — never a per-schema loop, and emits `[:threadline, :health, :checked]` exactly once with grand totals
- `CoverageSchemas.all_tables/1` excludes extension-member schemas via `pg_depend` (`classid = 'pg_namespace'::regclass`, `deptype = 'e'`), proven against a real `ALTER EXTENSION plpgsql ADD SCHEMA` fixture, never filtering on `pg_extension`'s own schema column (which would wrongly drop `public`)
- `mix threadline.health.coverage --all-schemas`: a SCHEMA-column table (leading `SCHEMA` column, per-schema rollup, `Coverage: ... across K schemas` grand total) or, with `--json`, an envelope `{"schemas": {"<name>": <exact single-schema payload>, ...}, "summary": {...}}` encoded via `Jason.OrderedObject` so schema keys stay sorted past 32 keys; raises `Mix.Error` with the exact mutual-exclusion message when combined with `--schema` (either order, including an explicit `--schema=public`), before the repo starts
- Full HLTH-02 edge matrix proven on real PostgreSQL: adjacency (same-named tables in two schemas reported separately), omission (a schema with only an excluded audit-table name and no finding is absent), union (a schema with zero coverage rows but a finding still appears), encoding/ordering (a quoted mixed-case schema name verbatim, sorted key order), determinism (33 extra schemas, two consecutive `--all-schemas --json` runs byte-identical), exactly one telemetry event with grand totals, and `--strict --all-schemas` gating the union of every reported schema's `:error` findings
- Documentation (task moduledoc, `domain-reference.md`, `operator-surface.md`, `configuration-and-commands.md`) and the pinned `OptionParser` spec literal updated; CHANGELOG `### Added` gains one `--all-schemas` bullet, no Breaking changes entry
- `evidence/SC5-wallclock.md`'s "After" section completed: three `mix test` runs (median 171.9s) and one `mix verify.test_partitioned` run (90s total, 4 partitions), this plan's own test cost (`--slowest-modules`), and a comparison against the before section and the phase-225 partitioned baseline; `mix ci.all` green

## Task Commits

1. **Task 1: Tracer — --all-schemas --json end-to-end through classify/3, the batched catalog helpers and the envelope, with mutual exclusion** - `4563c437` (feat)
2. **Task 2: SCHEMA-column table and rollup, extension-member fixture, omission and union rules, one telemetry event, strict union, ordering and determinism** - `4868db5e` (test)
3. **Task 3: Docs, doc contracts and CHANGELOG for --all-schemas** - `1bbedade` (docs)
4. **Gate-closing fix: drop the environment-dependent citext precondition test** - `9943c6ec` (fix)
5. **Gate-closing fix: bind legacy_key_findings/1's SET statement_timeout return value (Dialyzer)** - `493fa333` (fix)
6. **Plan metadata: record the after wall-clock and the green mix ci.all gate** - `fc6d43ad` (docs)

_Task 2 carried `tdd="true"`; the full table renderer and envelope logic were already in place from Task 1's commit, so Task 2's lib diff was limited to the renderer's SCHEMA-column header (shipped with Task 1) plus the edge-case fixtures and tests themselves — no additional lib changes were needed to make the behavior-block tests pass on the first run._

## Files Created/Modified
- `lib/threadline/health.ex` — `classify/3` (`@doc false`), `coverage_by_schema/1` (`@doc false`), batched `fetch_threadline_covered_tables/2` shared by both the single-schema and all-schemas paths
- `lib/threadline/health/coverage_schemas.ex` — `all_tables/1` (`@doc false`) with the `pg_depend` extension-member exclusion
- `lib/mix/tasks/threadline.health.coverage.ex` — `--all-schemas` flag, mutual-exclusion raise, `run_all_schemas/3`, `render_json_all_schemas/2`, `render_table_all_schemas/2`, `render_rollup/4`, `schema_payload/3` (pure, shared with the default `--json` path)
- `lib/threadline/health/legacy_key_findings.ex` — bound an unmatched `SET statement_timeout` query return (Dialyzer fix, pre-existing from plan 02)
- `test/threadline/operator_surface/coverage_mix_test.exs` — the `--all-schemas` tracer tests and the full HLTH-02 edge matrix (extension fixture, omission/union, adjacency, encoding/ordering, determinism, telemetry, strict union)
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` — updated pinned `OptionParser` spec literal, `--all-schemas` doc-contract assertions
- `test/threadline/health_test.exs` — `classify/3` unit tests, `trigger_coverage/1`-unchanged equivalence test
- `guides/domain-reference.md`, `guides/operator-surface.md`, `guides/configuration-and-commands.md` — `--all-schemas` documentation
- `CHANGELOG.md` — `### Added` bullet for `--all-schemas`
- `.planning/phases/229-adopter-api-and-health-additions/evidence/SC5-wallclock.md` — after wall clock

## Decisions Made
- Dropped a precondition test that asserted `citext` sits in `public`'s `pg_extension` — true only on the original research database, not on a freshly-migrated partitioned-CI database (`mix verify.test_partitioned` partition 2 failed on it while plain `mix test`'s accumulated local DB passed). The real exclusion behavior this precondition was meant to support stays fully proven by the `ALTER EXTENSION plpgsql ADD SCHEMA hcov_ext` fixture test, which needs no specific extension pre-installed — any extension works, including `plpgsql` itself.
- Fixed a pre-existing Dialyzer `:unmatched_returns` finding in plan 02's `legacy_key_findings.ex` (the transaction-local `SET statement_timeout` query's return value was unmatched). Confirmed it was a genuine finding, not a PLT-cache-miss false positive, by rebuilding the PLT (`mix dialyzer --plt`) and re-running before touching any code, per the project's documented Dialyzer-red triage order.
- A schema is "reported" under `--all-schemas` exactly when it has at least one coverage row or at least one finding — one predicate drives the JSON envelope's `reported_schemas` list, the table renderer's header rows, and the strict gate's union, so the three outputs can never disagree about which schemas appear.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Environment-dependent precondition test failed under `mix verify.test_partitioned`**
- **Found during:** Task 3's gate close, running `mix verify.test_partitioned`
- **Issue:** `test "precondition: public hosts an extension (citext) in the live catalog"` asserted `SELECT count(*) FROM pg_extension WHERE extnamespace = 'public'::regnamespace >= 1`, which held on the plan-authoring session's accumulated local test DB but not on the partitioned runner's freshly-migrated database.
- **Fix:** Removed the test. The behavior it was meant to support (extension-member schema exclusion) is independently and fully proven by the real `ALTER EXTENSION plpgsql ADD SCHEMA hcov_ext` fixture test, which creates its own extension membership and needs no specific extension pre-installed.
- **Files modified:** `test/threadline/operator_surface/coverage_mix_test.exs`
- **Verification:** `mix test test/threadline/operator_surface/coverage_mix_test.exs` and a full `mix verify.test_partitioned` run both green afterward
- **Committed in:** `9943c6ec`

**2. [Rule 1 - Bug] Pre-existing Dialyzer `:unmatched_returns` finding in plan 02's code**
- **Found during:** Task 3's gate close, running `mix ci.all`
- **Issue:** `lib/threadline/health/legacy_key_findings.ex`'s transaction-local `SET statement_timeout` query result was unmatched; Dialyzer's `:unmatched_returns` check flagged it. Pre-existing since plan 02, surfaced only now because `mix ci.all` had not been run end-to-end since.
- **Fix:** Bound the query result to `_`. No behavior change. Verified the PLT was current (`mix dialyzer --plt`) before concluding this was a real finding, per the project's documented Dialyzer-red triage order.
- **Files modified:** `lib/threadline/health/legacy_key_findings.ex`
- **Verification:** `MIX_ENV=dev mix verify.dialyzer` clean; `mix verify.credo` clean; `mix test test/threadline/health/` green
- **Committed in:** `493fa333`

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs found while closing the phase gate, neither a product-code regression this plan introduced)
**Impact on plan:** No scope creep; both fixes are minimal and were required to get `mix ci.all` green, which is this plan's own closing gate.

## Issues Encountered
- The after-measurement had to be re-taken once: the first three `mix test` runs plus `mix verify.test_partitioned` were measured at `9943c6ec`, but `mix ci.all`'s Dialyzer step then found the `legacy_key_findings.ex` issue above, requiring a further commit (`493fa333`). The measurement was re-run cleanly at `493fa333` with `git status --porcelain -- lib test` empty, per D-28's instruction to measure "with all phase code committed."
- Local whole-suite `mix test` wall clock was noisy across the three final runs (157.1s–308.3s on an otherwise unchanged tree), consistent with a shared, non-dedicated development machine; `evidence/SC5-wallclock.md` records this honestly rather than cherry-picking the fastest run, and leans on the per-file `--slowest-modules` figure (1.8s for 109 tests) as the more reliable per-test cost signal for this plan's own additions.
- `mix ci.all`'s Playwright/browser lane ran as part of the full gate (318 passed, 26 skipped) — unrelated to this plan's Elixir-only changes but confirmed green as part of the whole-gate requirement.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Phase 229 (Adopter API and Health Additions) is now fully executed: all four plans complete (`:limit`, `legacy_key_findings/1` + HLTH-04 docs, `--strict`, `--all-schemas`), `mix ci.all` green at `493fa333`, `evidence/SC5-wallclock.md` has both Before and After sections. ROADMAP success criteria SC4 (`--all-schemas` half) and SC5 (wall-clock half) are met. Next: phase 229 verification, then phase 230 (Rebalance, Net-Suite Check and 0.12.0).

---
*Phase: 229-adopter-api-and-health-additions*
*Completed: 2026-10-02*

## Self-Check: PASSED

- All 12 modified files found on disk
- Commits `4563c437`, `4868db5e`, `1bbedade`, `9943c6ec`, `493fa333`, `fc6d43ad` all found in `git log --oneline --all`
