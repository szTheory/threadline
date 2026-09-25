---
phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc
plan: 02
subsystem: capture
tags: [ecto, migrations, mix-task, postgres, triggers, gen.triggers]

requires:
  - phase: 207-01
    provides: "CREATE OR REPLACE TRIGGER SQL and TriggerSQL.drop_orphan_function_for_table/2 (no CASCADE)"
provides:
  - "Threadline.Mix.TriggerMigration (@moduledoc false): scan/1, resolve_name/2, rerun?/2"
  - "Threadline.Mix.MigrationVersion.existing/1: shared Ecto-rule discovery -> [{version, name, path}]"
  - "gen.triggers: collision-free numbered name + module on rerun; orphan per-table function drop in up; per-table down that keeps capture on for rerun tables, with comment + info line; ## Rerunning moduledoc"
  - "test/mix/tasks/threadline/gen_triggers_test.exs (file tier) and test/threadline/mix/trigger_migration_test.exs (unit)"
affects: [207-03, guides drift/rerun docs, CHANGELOG]

actuals:
  tokens: 6650
  tasks: 3
  commits: 3
plan_head_before: 68f1b075c27a7ae16a5e1b0c1644294c17577e17

tech-stack:
  added: []
  patterns:
    - "Name and module derived by one function from one parts list (suffixes ++ [ordinal]); candidate skipped if name OR module is taken"
    - "Host migration files read as text + regex only (never compiled/evaluated)"
    - "Per-table rollback decided from the migrations dir scanned before the new file is written"

key-files:
  created:
    - lib/threadline/mix/trigger_migration.ex
    - test/mix/tasks/threadline/gen_triggers_test.exs
    - test/threadline/mix/trigger_migration_test.exs
  modified:
    - lib/threadline/mix/migration_version.ex
    - lib/mix/tasks/threadline.gen.triggers.ex

key-decisions:
  - "Module built from the parts list (Macro.camelize per part), not by camelizing the final name, so AuditLog first-run output stays ThreadlineTriggersAuditLog (D-02 refinement as planned)"
  - "Rerun detection uses the trigger name with a (?![A-Za-z0-9_]) lookahead so posts_archive never marks posts as rerun; matches both quoted (current) and unquoted (legacy) trigger SQL"
  - "Rerun info line printed before the 'Run mix ecto.migrate' line"

patterns-established:
  - "gen_triggers_test.exs executes/2 helper: parse generated file with Code.string_to_quoted!/1 and collect execute SQL per def, then compare to TriggerSQL output (never hand-copied SQL)"

requirements-completed: [W1]

coverage:
  - id: D1
    description: "A rerun of gen.triggers writes a migration with a distinct Ecto name (_2, _3) and module (Posts2, Posts3); first-run name/module unchanged; legacy file and lookalike tables never collide"
    requirement: "W1"
    verification:
      - kind: integration
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs#describe rerun naming (7 tests)"
        status: pass
      - kind: unit
        ref: "test/threadline/mix/trigger_migration_test.exs#resolve_name/2, scan/1, MigrationVersion.existing/1"
        status: pass
      - kind: other
        ref: "probe: two runs of --tables posts into /Users/jon/.claude/jobs/77cf1bdd/tmp/207-02-probe"
        status: pass
    human_judgment: false
  - id: D2
    description: "Default-mode up drops the leftover per-table capture function right after the trigger, without CASCADE; per-table tables unchanged"
    requirement: "W1"
    verification:
      - kind: integration
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs#describe up body (2 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Per-table down: first-run tables keep today's drops; rerun tables keep capture on with an explanatory comment; mixed sets split per table; task prints an info line naming rerun tables"
    requirement: "W1"
    verification:
      - kind: integration
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs#describe down body (4 tests)"
        status: pass
      - kind: unit
        ref: "test/threadline/mix/trigger_migration_test.exs#rerun?/2 (4 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "gen.triggers moduledoc describes CREATE OR REPLACE TRIGGER and a ## Rerunning section (numbered names, orphan-drop NOTICE, rollback keeps capture on, unredacted caveat); docs build clean"
    requirement: "W1"
    verification:
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors; public_surface/code_walkthrough/release_artifact contract tests"
        status: pass
    human_judgment: true
    rationale: "Whether the prose reads clearly to an adopter is a judgment call; automated checks only prove the phrases exist and the docs build"

duration: 6min
completed: 2026-09-24
status: complete
---

# Phase 207 Plan 02: gen.triggers rerun naming, orphan drop, and per-table rollback Summary

**A rerun of `mix threadline.gen.triggers` now writes `threadline_triggers_posts_2` / `ThreadlineTriggersPosts2` (then `_3`, ...), picked from a text-only scan of the migrations dir. Its `up` re-points the trigger in place and drops any leftover per-table function without CASCADE. Its `down` leaves capture on for tables that already had a trigger migration and explains why in a comment.**

## Performance

- **Duration:** about 6 min
- **Started:** 2026-09-24T21:08:29Z
- **Completed:** 2026-09-24T21:14:03Z
- **Tasks:** 3
- **Files modified:** 5 (2 lib modified, 1 lib created, 2 test files created)

## Accomplishments
- Two pending runs of `--tables posts` no longer trip Ecto's `migration name threadline_triggers_posts is duplicated`. The name and module come from one parts list, and a candidate is skipped when either one is taken. A first run's name and module are byte-identical to before.
- New shared discovery `MigrationVersion.existing/1` (Ecto's rule: recursive `**/*.exs`, `Integer.parse(rootname)` then `"_" <> name`). `next/3` and the new resolver both use it.
- In default mode, `up` emits the non-cascading orphan drop after each table's `CREATE OR REPLACE TRIGGER`.
- `down` is now decided per table. Rerun tables get no drops and a comment block, first-run tables keep today's drops, and the task prints one line naming the rerun tables.
- Moduledoc: the `CREATE TRIGGER` sentence was replaced, and a `## Rerunning` section was added with the exact phrases plan 03 pins.

## Task Commits

1. **Task 1 (tracer): distinct name and module on rerun**: `1dc427aa` (fix)
2. **Task 2: orphan per-table function drop in up**: `a12ebddf` (fix)
3. **Task 3: per-table rollback + moduledoc**: `a32d97c0` (fix)

Each task kept the test-first order, but RED and GREEN went into one commit per task. The plan asked for green-per-commit staging and releasable `fix(gen.triggers): ...` subjects (D-13), so there are no separate `test(...)` commits. The RED proof is recorded below.

## RED proof

All RED runs used unmodified lib code for that task's behaviour. The ANSI-stripped output is saved in `/Users/jon/.claude/jobs/77cf1bdd/tmp/`.

**Task 1** (`207-02-t1-red.txt`): `36 tests, 15 failures`
- The first-run pins passed as designed: `first run keeps today's name and module`, and the `posts,org_memberships` and `AuditLog` variants.
- `a rerun gets a distinct Ecto name` failed with: `(Ecto.MigrationError) migrations can't be executed, migration name threadline_triggers_posts is duplicated — got ["threadline_triggers_posts", "threadline_triggers_posts"]`
- `a rerun gets a distinct module` failed with left `[ThreadlineTriggersPosts, ThreadlineTriggersPosts]`.
- `a legacy trigger migration already present` failed with left `"threadline_triggers_posts"` against right `"threadline_triggers_posts_2"`.
- `lookalike table names never collide` failed with: `migration name threadline_triggers_posts is duplicated — got ["threadline_triggers_posts", "threadline_triggers_posts_2", "threadline_triggers_posts"]`
- Every unit test failed with `UndefinedFunctionError`: TriggerMigration was not available, and `MigrationVersion.existing/1` was undefined.

**Task 2** (`207-02-t2-red.txt`): `38 tests, 2 failures`. All Task 1 cases stayed green.
- `default-mode up drops the orphan function after the trigger` failed: left held only the `CREATE OR REPLACE TRIGGER` statement, and right also expected `DROP FUNCTION IF EXISTS "public"."threadline_capture_changes_posts"()`.
- `per-table up keeps its function and gets no orphan drop` failed. The left list (3 elements) exactly matched the first 3 elements of the right list. The only thing missing was the posts orphan drop, so the RED came from the missing drop and not from an opts mismatch.

**Task 3** (`207-02-t3-red.txt`): `46 tests, 7 failures`. The first-run rollback case passed as the pin.
- All 4 `rerun?/2` unit tests failed with `UndefinedFunctionError`.
- `a rerun table's rollback leaves capture on` failed: left was `[DROP TRIGGER ... "threadline_audit_posts" ...]` against right `[]`.
- `mixed table sets split the rollback per table` failed: left dropped both posts and comments.
- `the task names rerun tables` failed: the output lacked "already have a Threadline trigger migration".

## Probe output (Task 3 Step D)

```
* creating priv/repo/migrations/20260924211348_threadline_triggers_posts.exs
Run `mix ecto.migrate` to install the triggers.
* creating priv/repo/migrations/20260924211349_threadline_triggers_posts_2.exs
These tables already have a Threadline trigger migration: posts. Rolling back the new migration keeps their capture on.
Run `mix ecto.migrate` to install the triggers.
1
defmodule ThreadlineTriggersPosts do
defmodule ThreadlineTriggersPosts2 do
```
`ls`: `20260924211348_threadline_triggers_posts.exs`, `20260924211349_threadline_triggers_posts_2.exs`. The `_2` file's `def down do` contains only the comment block.

## Verification

- Task 1/2 verify (`gen_triggers_test.exs test/threadline/mix/ install_test.exs`): 36, then 38, then 46 tests, 0 failures.
- Task 3 verify batch (adds `test/threadline/capture/` and the code_walkthrough, public_surface and release_artifact contract tests): 135 tests, 0 failures.
- Plan quick verify (`test/mix/tasks/threadline/ test/threadline/mix/ test/threadline/capture/`): 72 tests, 0 failures.
- These passed after every task: `mix compile --force --warnings-as-errors`, `mix format --check-formatted`, `mix credo --strict` on the touched files, and `MIX_ENV=dev mix docs --warnings-as-errors` (Task 3).
- Existing `migration_version_test.exs` and `install_test.exs` are untouched. The `examples/` and `priv/ci/` fixtures are untouched. No test runs Ecto.Migrator.

## Files Created/Modified
- `lib/threadline/mix/trigger_migration.ex`: new hidden module. `scan/1` reads the dir as text and regex-matches `defmodule`. `resolve_name/2` runs the ordinal loop. `rerun?/2` matches the trigger name with a lookahead.
- `lib/threadline/mix/migration_version.ex`: adds public `@doc false` `existing/1`; `existing_versions/1` now maps over it.
- `lib/mix/tasks/threadline.gen.triggers.ex`: resolved name and module, `migration_content/3`, orphan drop in `up`, per-table `down` with the rollback comment, rerun info line, and moduledoc rewrite.
- `test/mix/tasks/threadline/gen_triggers_test.exs`: file-tier cases in the describes "rerun naming", "up body" and "down body".
- `test/threadline/mix/trigger_migration_test.exs`: unit tests for resolve_name/2, scan/1 (including a no-eval sentinel file with a syntax error), rerun?/2 and MigrationVersion.existing/1.

## Decisions Made
- The module comes from the parts list: `"ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)`. This keeps `AuditLog` → `ThreadlineTriggersAuditLog`.
- The info line comes before the "Run `mix ecto.migrate`" line.
- The rollback comment avoids planning vocabulary and never names the table set's first-run tables. The test refutes a comment line naming `comments`.

## Deviations from Plan

None. The plan was executed as written. One wording note: the plan asks for a separate RED commit per task (tdd.md), but D-13 and green-per-commit staging put RED and GREEN in one commit per task. The RED proof above is the evidence. Plan-level TDD gate mode (`workflow.tdd_mode`) is not enabled in config.

## Deferred / Known Pitfall (out of scope, not fixed)

- **Suffix aliasing:** `support.tickets` and a public `support_tickets` both map to the suffix `support_tickets`. They therefore share the trigger name, the rerun-detection key and the per-table function name `threadline_capture_changes_support_tickets`. Detection errs toward "rerun", so capture stays on at rollback. The non-cascading orphan drop fails loudly if the other table's trigger still uses the function. This predates this phase and is left as is.

## Issues Encountered
None.

## User Setup Required
None. No external service configuration is required.

## Next Phase Readiness
- Plan 03 (guides, CHANGELOG, doc pin test) can read the `## Rerunning` moduledoc phrases through Code.fetch_docs. Each of these phrases sits unbroken on one source line: "replaces the trigger in place", "does not restore the earlier capture policy", "unredacted" and "mix threadline.policy.show".

---
*Phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc*
*Completed: 2026-09-24*

## Self-Check: PASSED
