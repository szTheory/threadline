---
phase: 206-installer-migration-versions
plan: 01
subsystem: installer
tags: [mix-task, migrations, ecto, installer, regression-tests]
status: complete
requires: []
provides:
  - Threadline.Mix.MigrationVersion.next/3 (hidden helper, N strictly increasing migration versions for a path)
  - install run/1 computing versions once, before any write
  - three-branch storage-schema advice (fresh / partial / none)
affects:
  - lib/mix/tasks/threadline.install.ex
  - lib/mix/tasks/threadline.gen.triggers.ex
tech-stack:
  added: []
  patterns:
    - "Rails next_migration_number: base = max(now, highest existing + 1s), NaiveDateTime.add stepping"
key-files:
  created:
    - lib/threadline/mix/migration_version.ex
    - test/threadline/mix/migration_version_test.exs
  modified:
    - lib/mix/tasks/threadline.install.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - test/mix/tasks/threadline/install_test.exs
decisions:
  - "Migration versions come from one hidden helper, Threadline.Mix.MigrationVersion.next/3, called once per install run (count up front) and once per gen.triggers write"
  - "Dedicated-schema advice prints only when every family was written; a partial re-run gets a keep-public note; the unreachable existing-installs paragraph is removed"
metrics:
  duration: "~4 min"
  completed: 2026-09-24
  tasks: 3
  files: 5
actuals:
  tokens: 5171
  tasks: 3
  commits: 3
plan_head_before: 00022f156b232b368e306cfa567cdad875d9da85
---

# Phase 206 Plan 01: Installer Migration Versions Summary

`mix threadline.install` and `mix threadline.gen.triggers` now take their migration versions from one hidden helper that starts after the highest existing version (or now, whichever is later) and steps calendar-correctly, so a fresh `mix ecto.migrate` no longer raises "migration version <N> is duplicated"; the dedicated-schema advice now reaches only fresh installs.

## RED proof

All five regression cases were written first and run against the unmodified code (`git diff -- lib/` empty at the time). Output saved ANSI-stripped to `/Users/jon/.claude/jobs/77cf1bdd/tmp/206-01-red.txt`:

```
1) test migration versions a fresh install writes three distinct versions in family order
   `mix ecto.migrate` would raise (Ecto.MigrationError) migrations can't be executed, migration version 20260924174427 is duplicated — got ["20260924174427", "20260924174427", "20260924174427"]
2) test storage-schema advice a partial re-run versions the missing migration last and is told to keep `public`
   Assertion with > failed
3) test install then gen.triggers the trigger migration is versioned after the three install migrations
   `mix ecto.migrate` would raise (Ecto.MigrationError) migrations can't be executed, migration version 20260924174427 is duplicated — got ["20260924174427", "20260924174427", "20260924174427", "20260924174427"]
4) test migration versions every version is above a future-dated host migration, with the date carried
   version 20260924174427 does not sort after the existing host migration 20991231235959
5) test storage-schema advice fresh-install advice has no paragraph about existing installs
   code: refute output =~ "Existing installs need no action"
9 tests, 5 failures
```

After holding cases 3, 3b and 4 outside `test/`: `6 tests, 2 failures` (cases 1 and 2 RED).

Task 2 re-proof (advice block restored, before touching lib/): `8 tests, 2 failures`. Both advice cases failed: 3b on the existing-installs paragraph, 3 on `refute output =~ "No \`:storage_schema\` is configured"`.

Task 3 re-proof (gen.triggers block restored, before touching lib/): `9 tests, 1 failure`, with versions `["20260924174627", "20260924174628", "20260924174629", "20260924174627"]`. Install was already fixed, and gen.triggers repeated its first second.

## Commits

| Task | Commit | Subject | Install test file at commit |
|------|--------|---------|-----------------------------|
| 1 | 9395632a | fix(install): give each generated migration a distinct version | 6 tests, 0 failures |
| 2 | b620057e | fix(install): give dedicated-schema advice only on a fresh install | 8 tests, 0 failures |
| 3 | 2d6cf376 | fix(gen.triggers): version the trigger migration after existing migrations | 9 tests, 0 failures (+ 8 helper tests: 17 tests, 0 failures) |

## Verification

- `mix test test/mix/tasks/threadline/install_test.exs test/threadline/mix/migration_version_test.exs` gives 17 tests, 0 failures, with no excluded suffix.
- Every task passed `mix compile --force --warnings-as-errors`, `mix format --check-formatted` and `mix credo --strict` on its files with no issues. `mix verify.xref_cycles` reported "No cycles found".
- Grep for planning vocabulary in the three lib files: no matches. No `defp timestamp`/`defp pad` is left under lib/mix/tasks/. The `StorageSchema.threadline_table?` anchor count is unchanged (1).
- Neither test file references Ecto.Migrator.
- Committed-blob checks: T1 blob has only "migration versions". T2 blob has the advice describe but not gen.triggers. T3 blob has gen.triggers. The T2 and T3 test diffs remove no lines.
- The full default suite is not run here. Plan 02 Task 2 runs it at the phase gate, as planned.

## Deviations from Plan

**1. [Rule 3 - Blocking] Holding-file header comments reworded**
- **Found during:** Task 1 acceptance.
- **Issue:** Header comments of the form `# describe "..."` made the held file grep to 2 per describe name, but the acceptance check expects exactly 1.
- **Fix:** Reworded them to `# held block: <name>`. Each block still has a comment naming it.
- **Files modified:** the tmp holding file only (not committed; deleted in Task 3).

Otherwise the plan ran as written. `recommend_storage_schema/1` derives `written` from the results list itself, and two small private helpers (`recommend_dedicated_schema/1`, `keep_public_schema/0`) hold the two heredocs.

## Deferred (out of scope, not fixed)

- `mix threadline.gen.triggers` hard-codes `priv/repo/migrations`, while install resolves the repo's configured migrations dir.
- `guides/production-checklist.md:14` states a stale `threadline` default for storage_schema.

## Known Stubs

None.

## Threat Flags

None. No new surface: the helper only lists and parses filenames in the migrations dir.

## Self-Check: PASSED

- FOUND: lib/threadline/mix/migration_version.ex, test/threadline/mix/migration_version_test.exs
- FOUND commits: 9395632a, b620057e, 2d6cf376
