---
phase: 208-identifier-foundation
plan: 05
subsystem: mix-tasks
status: complete
tags: [mix, gen.triggers, migrations-path, identifiers, naming, CONF-02, NAME-01]
requires:
  - phase: 208-02
    provides: "StorageSchema.validate_identifier!/3 with role labels (:host_table, :host_schema, :derived)"
  - phase: 208-03
    provides: "Threadline.Mix.MigrationsPath.resolve/1 and the CustomPrivRepo/NoPrivRepo test stubs"
  - phase: 208-04
    provides: "Threadline.Capture.Naming.trigger_name/1 and migration_name/2"
provides:
  - "mix threadline.gen.triggers resolves its directory with MigrationsPath.resolve/1 and accepts --migrations-path and --repo/-r"
  - "Trigger names come from Naming.trigger_name/1: byte-identical when they fit, cut to 63 bytes otherwise"
  - "TriggerMigration.resolve_name/2 takes tables or parsed pairs and delegates to Naming.migration_name/2"
  - "TriggerMigration.rerun?/2 matches the full trigger name, including a cut one"
  - "A bad --tables value raises a Mix.Error starting with \"--tables: \" that names the host table and its byte count"
affects: ["209 (per-table function-name emission, orphan-safe drops, ON-clause rerun matcher)"]
tech-stack:
  added: []
  patterns: ["function-level rescue scoped to user input only; derived-name failures stay ArgumentError"]
key-files:
  created: []
  modified:
    - lib/mix/tasks/threadline.gen.triggers.ex
    - lib/threadline/mix/trigger_migration.ex
    - lib/threadline/capture/trigger_sql.ex
    - test/mix/tasks/threadline/gen_triggers_test.exs
    - test/threadline/mix/trigger_migration_test.exs
    - CHANGELOG.md
key-decisions:
  - "write_migration!/3 takes zipped {raw_table, pair} tuples so the user sees raw table strings in the rerun message while naming uses the parsed pairs"
  - "The Threadline-own-tables guard still calls StorageSchema.threadline_table?/1 on raw strings; it runs after parse_tables!/1, so it can no longer raise"
  - "CHANGELOG: the gen.triggers directory change is listed under Required action (only for repos with :priv or not named Repo); the trigger-name cut and the --tables error are under Changed"
requirements-completed: [CONF-02, NAME-01]
coverage:
  - id: D1
    description: "gen.triggers writes to and detects reruns in the resolved migrations directory (custom :priv, --repo, -r, --migrations-path, repeated --repo)"
    requirement: CONF-02
    verification:
      - kind: unit
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs describe \"migrations directory\""
        status: pass
  - id: D2
    description: "Trigger and migration names routed through Capture.Naming; an overflowing default-mode table generates with the 63-byte cut name and its rerun is detected"
    requirement: NAME-01
    verification:
      - kind: unit
        ref: "test/threadline/mix/trigger_migration_test.exs (resolve_name/2, rerun?/2); test/mix/tasks/threadline/gen_triggers_test.exs describe \"trigger names\""
        status: pass
      - kind: unit
        ref: "test/threadline/capture/trigger_rerun_test.exs (per-table overflow still ArgumentError ~r/at most 63 bytes/)"
        status: pass
  - id: D3
    description: "Role-accurate --tables Mix error for oversized, invalid and three-part names; no file written"
    requirement: NAME-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs describe \"--tables validation\""
        status: pass
  - id: D4
    description: "Moduledoc and CHANGELOG describe the flags, the directory change and the default-mode-only trigger-name cut"
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs, test/threadline/release_artifact_contract_test.exs, gen_triggers_test rerun documentation"
        status: pass
  - id: D5
    description: "Phase gate"
    verification:
      - kind: other
        ref: "mix ci.all (after mix dialyzer --plt)"
        status: pass
metrics:
  duration: "~12 min"
  completed: 2026-09-25
actuals:
  tokens: 5700
  tasks: 3
  commits: 5
plan_head_before: 045e4a2917bcc76c6574be6169605badbf5277ba
---

# Phase 208 Plan 05: gen.triggers on the identifier foundation Summary

`mix threadline.gen.triggers` now writes its migrations to the same directory as `mix threadline.install` and looks for reruns there. That directory comes from `MigrationsPath.resolve/1` and can be set with `--migrations-path` or `--repo`/`-r`. Trigger and migration names now come from `Capture.Naming`. In default capture mode, a table whose trigger name would pass 63 bytes now generates with the name cut to 63 bytes instead of failing, and a later rerun for that table is detected. A bad `--tables` value now stops with a Mix error that names the host table and its byte count, with no stack trace.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (tracer) | gen.triggers resolved migrations directory, flags, run/1 split | a1dbb42c | lib/mix/tasks/threadline.gen.triggers.ex, test/mix/tasks/threadline/gen_triggers_test.exs |
| 2 (RED) | Failing Naming-based naming / rerun tests | c3a9a1e2 | test/threadline/mix/trigger_migration_test.exs, test/mix/tasks/threadline/gen_triggers_test.exs |
| 2 (GREEN) | Trigger/migration names via Naming; :derived validation; rerun? by full name | 5901b4bf | lib/threadline/mix/trigger_migration.ex, lib/threadline/capture/trigger_sql.ex, lib/mix/tasks/threadline.gen.triggers.ex |
| 3 (RED) | Failing --tables error tests | 5264aa2e | test/mix/tasks/threadline/gen_triggers_test.exs |
| 3 (GREEN) | parse_tables!/1 rescue, moduledoc, CHANGELOG | 8726eeb6 | lib/mix/tasks/threadline.gen.triggers.ex, CHANGELOG.md |

## Verification

- Task 1 verify (gen_triggers + source_size_contract): 38 tests, 0 failures. Tracer gate: the automated verify was re-run and passed before expanding.
- Task 2 RED: 6 expected failures. `resolve_name` failed on pairs and the 50-table set, the `rerun?` call sites failed because they now pass the full name, and gen.triggers raised the old "storage schema" ArgumentError on the 50-byte table. GREEN: 7 properties, 99 tests, 0 failures across trigger_migration, gen_triggers and `test/threadline/capture/`. `trigger_rerun_test.exs`: 9 tests, 0 failures, and the per-table `~r/at most 63 bytes/` ArgumentError is unchanged.
- Task 3 RED: 3 expected failures. GREEN: 61 tests, 0 failures (gen_triggers, trigger_rerun, changelog and release-artifact contracts).
- Acceptance greps all return the expected counts. `MigrationsPath.resolve(opts)` = 1, `"priv/repo/migrations"` = 0, the stale install comment = 0, `repo: :keep` = 1, `priv/custom_repo/migrations` = 4 in tests, `Naming.migration_name` = 1, `Naming.trigger_name` in trigger_sql = 2, `:derived` = 1, the legacy interpolation = 0, `rerun?(Naming.trigger_name` = 1, the `Mix.raise("--tables: "...` line = 1, `rescue` = 1, and `--migrations-path` in the task = 2 or more. CHANGELOG Unreleased and the moduledoc both contain "default capture mode" and "--store-changed-from".
- **`mix ci.all`: EXIT 0.** `mix dialyzer --plt` ran first because of the plan 01 mix.exs change: 27 modules were added to the PLT. The run covered verify.format, verify.credo, `compile --warnings-as-errors`, xref cycles, compile without optional deps, and verify.test with 7 properties, 1912 tests, 0 failures and 1 excluded. It also covered verify.threadline, verify.example (117 tests, 0 failures), and Dialyzer with "Total errors: 0" and "done (passed successfully)". The Playwright lane inside the run reported 318 passed, 26 skipped and 0 failed.
- **REL-01 ordering check.** `git log --reverse --format='%h %s' main..HEAD` has 35 commits. The `ci(release)` commit comes before every releasable subject:

  ```
  11:28beadd9 ci(release): propose minor bumps for breaking changes before 1.0
  16:31dfcc2c fix(208-02): name the host identifier role, value and byte count in errors
  17:07c8c677 fix(208-02): report host schema errors as host schema in runtime callers
  20:166a4f45 feat(208-03): resolve install's migrations directory through a shared resolver
  21:e0d319ef feat(208-03): test the migrations-path precedence and document install's flags
  ```

  The numbers are positions in the branch log. No feat, fix, perf or deps commit comes before position 11.

## Deviations from Plan

**1. `priv/custom_repo/migrations` inlined as a literal in the tests.** The first draft used a module attribute, so the acceptance grep (literal in at least two assertions) counted only 1. The literal is now inlined; test behavior is unchanged.

**2. Comment reworded so the `rescue` grep stays exact.** The comment above `parse_tables!/1` said "rescued", which would have made `grep -c rescue` print 2. It now says "becomes a Mix error".

**3. The Users/users `resolve_name` test was never red.** Current camelization already produced `ThreadlineTriggersUsers` for both names, so the test pins existing behavior. The other new tests failed first, as the plan expected.

No Rule 1-4 deviations. No files outside the plan's `files_modified` were changed.

## Known Stubs

None.

## Flagged Assumption (carried from the plan)

For CONF-02: if an adopter has a repo with a custom `:priv` and earlier generated trigger migrations into `priv/repo/migrations`, `mix ecto.migrate` never ran those files. This plan does not move or rescan them, and rerun detection reads only the resolved directory. The CHANGELOG Required action tells such adopters to move or regenerate those files.

## Handoff to Phase 209

- The `:derived` `StorageSchema.validate_identifier!/2` raise on the per-table function base in `TriggerSQL.per_table_function_name/2` is an interim D-10 deviation. Phase 209 must replace it with `Naming.function_name/1` emission (NAME-02).
- Phase 209 must retire `TriggerSQL.per_table_function_base/1` and `TriggerSQL.per_table_function_fits?/1`.
- Phase 209 must update the per-table-mode rejection sentence added in this plan to the `mix threadline.gen.triggers` moduledoc ("## Long table names") and to CHANGELOG.md "## Unreleased — highlights" → "### Changed". Both say tables using redaction or `--store-changed-from` are still rejected "until a later release".
- `TriggerMigration.rerun?/2` stays name-based: it matches the full trigger name, including one cut to 63 bytes. The ON-clause matcher (D-11, T-208-14) is still open for 209.

## Self-Check: PASSED

- All six modified files exist.
- Commits a1dbb42c, c3a9a1e2, 5901b4bf, 5264aa2e and 8726eeb6 are in `git log`. `git rev-list --count 045e4a29..HEAD` = 5.
