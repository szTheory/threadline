---
phase: 208-identifier-foundation
plan: 04
subsystem: capture
status: complete
tags: [capture, naming, identifiers, sha256, stream_data, NAME-01, NAME-05]
requires: ["208-01", "208-02"]
provides:
  - "Threadline.Capture.Naming (@moduledoc false): hash12/1, pair/1, qualified/1, suffix/1, trigger_name/1, function_name/1, legacy_function_name/1, migration_name/2"
  - "Golden literal test that freezes the name format (8 D-05 rows plus the migration hashes 229374fb2418 and 4b1eb587a18a)"
  - "Seven StreamData properties that run in plain mix test (async, default 100 runs, no tags)"
affects:
  - "208-05 (gen.triggers takes trigger and migration names from Naming; rerun? is given the cut trigger name)"
  - "Phase 209 (per-table function emission switches to Naming.function_name/1; the orphan-safe drop uses legacy_function_name/1)"
tech-stack:
  added: []
  patterns:
    - "One pure module owns every derived identifier; lengths measured with byte_size"
    - "Regex source kept in a module attribute and compiled at call time, for OTP releases that refuse regexes in attributes"
    - "Property generators biased toward known collision shapes (_-split, case, 36-byte shared prefix, same table in two schemas)"
key-files:
  created:
    - lib/threadline/capture/naming.ex
    - test/threadline/capture/naming_test.exs
    - test/threadline/capture/naming_property_test.exs
  modified: []
key-decisions:
  - "migration_name/2 accepts only a non-empty table list and an ordinal >= 1 (guard clause). An empty list has no name under D-06, and gen.triggers never passes one"
  - "The P3 injectivity generator also draws one table under two schemas (public.t vs s.t, s1.t vs s2.t). A mutation check showed that without this bias P3 missed a 'legacy name for non-public tables' bug"
  - "The order property builds lists that always overflow (one 44-byte table plus at least one other) instead of filtering, which StreamData rejected as too many discards at small sizes"
requirements-completed: [NAME-05]
coverage:
  - deliverable: "Naming.hash12/trigger_name/function_name/legacy_function_name match the frozen golden rows"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/capture/naming_test.exs#golden names"
        status: pass
      - kind: command
        ref: "printf '%s' '<schema>.<table>' | shasum -a 256 | cut -c1-12 (all 11 inputs)"
        status: pass
  - deliverable: "Naming.migration_name/2: fitting names unchanged, overflow capped at 63 bytes with an order-free hash"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/capture/naming_test.exs#migration_name/2"
        status: pass
  - deliverable: "Boundary, adjacency, case and role-accurate error edges"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/capture/naming_test.exs#boundaries, adjacency and case, errors"
        status: pass
  - deliverable: "StreamData properties P1-P6 in default mix test"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/capture/naming_property_test.exs"
        status: pass
      - kind: test
        ref: "test/threadline/zero_skips_contract_test.exs"
        status: pass
      - kind: command
        ref: "mix test (full suite: 7 properties, 1898 tests, 0 failures, 1 excluded = existing :pgbouncer_topology)"
        status: pass
metrics:
  duration: "~6 min"
  completed: 2026-09-25
actuals:
  tokens: 5550
  tasks: 3
  commits: 5
plan_head_before: 5c9eb35feb8dde4821335fdc26ed9c5e67ffc66e
---

# Phase 208 Plan 04: Capture.Naming identifier foundation Summary

`Threadline.Capture.Naming` now derives every generated identifier in one pure module. hash12 is the first 12 lowercase hex characters of SHA-256 over `schema.table`. Trigger names are the legacy name cut to 63 bytes and are never hashed. A function name keeps its legacy form only for public tables of at most 36 bytes without a hash tail. Every other table gets a 23-byte stem plus hash12. Migration names that fit in 63 bytes are unchanged. Longer ones end in an order-free hash. A golden literal test and seven StreamData properties in plain `mix test` freeze the format.

## Golden hash recomputation (before freezing)

Each value was computed with `printf '%s' INPUT | shasum -a 256 | cut -c1-12` before it went into the test. All 11 matched the plan and CONTEXT D-05 exactly, so nothing had to halt.

| Input | shasum | Plan |
|-------|--------|------|
| public.posts | c6fcf4ae4927 | match |
| billing.invoices | 9bba11019407 | match |
| public.billing_invoices | ee2e817bbf91 | match |
| public.customer_subscription_line_items_archive | 3b9be56c3c45 | match |
| analytics_reporting.customer_lifetime_value_snapshots | 411cf9724315 | match |
| public.ledger_0123456789ab | 6095cae6be06 | match |
| public.Users | 3268e9c3e2ba | match |
| public.users | 14447575adab | match |
| a.b | 2e7336dc8eba | match |
| billing.invoices,public.customer_subscription_line_items_archive | 229374fb2418 | match |
| public. + 44 underscores | 4b1eb587a18a | match |

Byte counts for the derived names were also checked by hand against D-02, D-03 and D-06. They are `customer_subscription_l` (23), `analytics_reporting_cus` (23), `..._lifetime_value_sn` (63-byte trigger), `customer_subscription_line_ite` (30-byte readable) and `customer_subscription_line_i` (28 with `_2`).

## Performance

- Duration: about 6 min. Start 2026-09-25T13:56Z, end 2026-09-25T14:03Z.
- Tasks: 3. Files: 3 created.
- Property file runtime: 0.1 to 0.2 s at 100 runs per property.

## Accomplishments

- `naming.ex`: `hash12/1`, `pair/1` (strings are parsed through `StorageSchema.parse_table_identifier/1`; maps are trusted by a documented contract), `qualified/1`, `suffix/1`, `trigger_name/1`, `function_name/1`, `legacy_function_name/1` and `migration_name/2`. A prose comment block covers the SQL reproduction of hash12, why trigger names are never hashed, the three-case function-name injectivity argument (about 1.8e-7 at 10k tables) and the migration hash rule. It cites no phase numbers, decision IDs or file:line references.
- `naming_test.exs`: 29 tests. They cover the eight golden rows, input-form equivalence, `migration_name/2` (fitting, hashed, ordinal, 50 tables, duplicates, empty readable, underscore-only fitting, Users/users), trigger and function boundaries (46/47 and 36/37 bytes), the hash tail, adjacency, case and host-table errors ("70 bytes", never "storage schema").
- `naming_property_test.exs`: 7 properties. P1 is split into per-table and migration properties. P2 is determinism. P3 is function-name injectivity given distinct hash12. P4 is the trigger cut formula. P5 is the order-free migration hash. P6 is the hashed/legacy split. There are no tags and no max_runs, and the file is async.

## TDD cycle

- **Task 1 RED** `beabf8d8`: 11 tests, 11 failures on the undefined `Naming` module. **GREEN** `95cdd5a0`: 11/11 pass. The tracer gate re-ran the verify command, which stayed green, before any expansion.
- **Task 2 RED** `b68bf877`: 29 tests, 8 failures. All 8 are the `migration_name/2` tests. The edge tests passed already because they exercise Task 1 code. **GREEN** `4c4012be`: 29/29 pass.
- **Task 3** `4e1819a6` (test-only): the behaviour already existed, so a RED gate could not apply. Mutation checks stood in for it (see below).
- RED evidence was checked with `gsd-tools check tdd-red-evidence` and returned `RED_EVIDENCE_OK` for both RED gates. That checker parses TAP, so each record held a TAP transcription of the real ExUnit output: the `N) test NAME` failure lines plus the summary counts.
- There was no REFACTOR commit because no cleanup was needed.

### Mutation checks on the properties (temporary edits, source restored, diff empty)

| Mutation | Caught by |
|----------|-----------|
| Hash the table only, not `schema.table` | P3, P6 |
| Legacy function name for any table of 36 bytes or less, whatever its schema | P3, P6 (after the schema-only bias was added; P6 alone before) |
| Drop `Enum.sort()` from the migration hash | P5 |

## Task Commits

1. `beabf8d8` test(208-04): add failing golden-name tests for Capture.Naming
2. `95cdd5a0` feat(208-04): add Capture.Naming with hash12, trigger and function names
3. `b68bf877` test(208-04): add failing migration_name tests and naming edge cases
4. `4c4012be` feat(208-04): cap trigger migration names at 63 bytes with an order-free hash
5. `4e1819a6` test(208-04): add StreamData properties for Capture.Naming

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] P3 generator was blind to schema-only differences**
- Found during: Task 3, in a mutation check
- Issue: a "legacy function name for non-public tables" bug passed P3, because no biased generator drew one table under two schemas. That is the collision shape T-208-08 cares about.
- Fix: added `{public.t, s.t}` and `{s1.t, s2.t}` (schemas sharing a 36-byte prefix) to `pair_of_pairs_gen`.
- Files: test/threadline/capture/naming_property_test.exs. Commit `4e1819a6`.

**2. [Rule 1 - Bug] P5 filter discarded too many values**
- Found during: Task 3
- Issue: the `check all` overflow filter hit StreamData's too-many-discards error at small generation sizes.
- Fix: every generated list now starts with a 44-byte public table plus at least one more, so it always overflows. The test asserts the overflow instead of filtering on it.
- Files: test/threadline/capture/naming_property_test.exs. Commit `4e1819a6`.

**3. [Minor] Guard on migration_name/2**
- The function only accepts `tables != []` and `ordinal >= 1`. The plan leaves both unspecified, and an empty list has no meaningful D-06 name.

**4. [Formatting] `check all(...)` / `gen all(...)` carry parens**
- `.formatter.exs` does not import stream_data's `locals_without_parens`, so `mix format` adds parens. I left the formatter config alone, because `formatter_topology_contract_test.exs` guards it and the change is cosmetic.

**Total deviations:** 2 auto-fixed (1 missing-critical, 1 bug), 2 minor notes. **Impact:** the properties are stronger than the plan asked for. The frozen format is unchanged.

## Issues Encountered

None.

## Known Stubs

None.

## Next Phase Readiness

Plan 05 will route gen.triggers' trigger names and migration names through `Naming`, passing the cut name to `rerun?`. NAME-01 stays Pending until then. NAME-05 is complete.

## Self-Check: PASSED

- FOUND: lib/threadline/capture/naming.ex, test/threadline/capture/naming_test.exs, test/threadline/capture/naming_property_test.exs
- FOUND commits: beabf8d8, 95cdd5a0, b68bf877, 4c4012be, 4e1819a6
- Acceptance greps: all pass. `:crypto.hash(:sha256` = 1, md5/phash2 = 0, `@moduledoc false` = 1, `def migration_name` = 1, per-part camelize = 1, `use ExUnitProperties` = 1, `async: true` = 1, tags = 0, max_runs = 0, `^  property ` = 7.
- `mix test test/threadline/capture/` passes. Full `mix test` passes. `mix credo --strict` finds no issues in the three files. `mix format --check-formatted` passes. `mix compile --warnings-as-errors` passes.
