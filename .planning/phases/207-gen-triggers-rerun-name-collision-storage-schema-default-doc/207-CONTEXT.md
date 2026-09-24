# Phase 207: Trigger Migration Rerun and Storage-Schema Default Docs - Context

**Gathered:** 2026-09-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the documented drift remediation work end to end: rerunning
`mix threadline.gen.triggers` for tables that already have a trigger migration
must produce a migration that `mix ecto.migrate` accepts **and applies**. The
drift guides prescribe this rerun (`guides/production-checklist.md:45`,
`guides/domain-reference.md:52-53`). Add a second-run regression test. Also
make every guide state the real `storage_schema` default, which is `public`.

Source: `.planning/v1.41-MILESTONE-AUDIT.md`, second re-audit, items W1 and W2.
Both are pre-existing adopter-facing bugs, not regressions from phase 206.

**Discovered during discussion. This widens W1 but stays inside the phase
goal ("a migration Ecto accepts, as the guides instruct"):**
1. **The rerun has a second, deeper break.** `lib/threadline/capture/trigger_sql.ex:117-126`
   emits a bare `CREATE TRIGGER`. A rerun migration with a unique name would
   still fail at migrate time with `trigger "threadline_audit_<t>" ... already exists`.
   Fixing only the name does not satisfy the goal.
2. **The module name collides too.** Both runs define `ThreadlineTriggers<Tables>`
   (`lib/mix/tasks/threadline.gen.triggers.ex:236-237`), not just the same Ecto name.
3. **A third (and, per research, a fourth: `guides/domain-reference.md:311`) guide states the wrong default.** `guides/how-threadline-works.md:94`
   ("The storage schema defaults to `threadline`") is wrong, in addition to
   the two sites the audit named.

</domain>

<decisions>
## Implementation Decisions

The user accepted the full recommended set in one shot ("what's your rec? let's
go with that"). Three parallel advisor researchers settled the areas as one
consistent set.

### Rerun naming (W1, name + module)
- **D-01:** Add an ordinal only when the name is taken. After
  `MigrationVersion.next/2`, collect every migration name already in the
  migrations dir, the way Ecto extracts it: `Integer.parse(Path.rootname(base))`
  gives `{int, "_" <> name}` (`deps/ecto_sql/lib/ecto/migrator.ex:675-695`).
  Walk the same recursive `**/*.exs` set that `MigrationVersion` scans. If
  `threadline_triggers_<suffix>` is free, use it unchanged, so first-run output
  stays byte-identical. Otherwise try `_2`, `_3`, ... until one is free.
- **D-02:** Build the module from the **same parts list** as the final name, so
  the two cannot diverge: `"ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)`,
  where the parts are the table suffixes plus any ordinal. (Research refinement: camelizing
  the whole joined name would change today's module for mixed-case tables, e.g. `AuditLog`
  → `ThreadlineTriggers_AuditLog`, which breaks D-01's byte-identical first run.) A candidate is "taken" if **either** its name
  **or** its camelized module already exists in the dir. Camelizing collides
  on real inputs: table `posts_2` vs a rerun of `posts` + `_2` both give
  `ThreadlineTriggersPosts2`, and `[a_b]` vs `[a, b]` both give
  `ThreadlineTriggersAB`. Pick the next free candidate with a loop. Never parse
  a trailing ordinal back out of an existing name.
- Rejected: always embedding the version in the name and module. It churns
  first-run output for every adopter, the example apps, and any adopter
  tooling, and it lengthens names that are already long.

### Rerun SQL (up)
- **D-03:** `create_trigger_sql` emits `CREATE OR REPLACE TRIGGER` on **every**
  run, not only on reruns. PostgreSQL 14 is the floor (`README.md:102`) and CI's
  `min` lane runs PG 14 (`.github/workflows/ci.yml` ~283-294), so this is safe
  and is tested at the floor. It swaps the trigger in one statement with no
  capture gap, even if a host sets `@disable_ddl_transaction`. The per-table
  `CREATE OR REPLACE FUNCTION`s still come first, then the triggers.
  — **Reversibility:** costly — the emitted SQL is frozen into adopters' committed
  migration files. (Research correction: `TriggerSQL` is `@moduledoc false`, so it is
  not on the HexDocs surface; do not name it in backticks in CHANGELOG/guides.)
- **D-04:** Deployed-policy introspection is unaffected. It reads catalogs
  (`pg_trigger` joined to `pg_proc.prosrc`, `lib/threadline/policy/redaction_presenter.ex:77-93`,
  `lib/threadline/health.ex:98-108`), not DDL text. The planner must still
  verify this and update the one exact-text assertion
  (`test/threadline/capture/trigger_sql_storage_schema_test.exs:25`) plus the
  gen.triggers moduledoc (line 13, which says "`CREATE TRIGGER` statements").
- **D-05:** Orphan function cleanup. For each table generated in `:default`
  (global function) mode, `up` emits
  `DROP FUNCTION IF EXISTS <schema>.threadline_capture_changes_<t>()` **after**
  that table's `CREATE OR REPLACE TRIGGER`, **without CASCADE**. Use a new
  helper, not `drop_function_for_table/2`, which does CASCADE. If anything
  unexpected still depends on the function, the migration fails loudly instead
  of cascading into a trigger. The drop is idempotent and harmless on a first run.
- Rejected: `DROP TRIGGER IF EXISTS` + `CREATE TRIGGER`. It leaves a capture
  gap outside a transaction, emits NOTICE noise, and a migration reading "drop
  the audit trigger" looks alarming. It is only worth it if the PG floor ever
  drops below 14.

### Rerun rollback (down)
- **D-06:** Decide per table. A table is a **rerun** if any existing migration
  file in the dir already references `threadline_audit_<t>`. This covers a
  rerun with a different table set, e.g. first `posts,users` then `posts`.
  - **First-run table:** keep today's `down`: drop the trigger, then drop the
    per-table function.
  - **Rerun table:** `down` does **not** drop the trigger or functions. The
    generated migration carries a comment saying that rolling back a rerun does
    not restore the earlier capture policy, that capture stays on, and that
    removing capture needs an explicit migration or a rollback of the original
    one. Rolling back the original afterwards still works, because its drops
    are `IF EXISTS`.
  — **Reversibility:** costly — this is written into adopters' migration files.
  Once shipped, changing it only affects newly generated migrations.
- **D-07:** Acknowledged fail-open edge case. If a rerun that **removed**
  redaction is rolled back, capture continues unredacted. The redaction drift
  view (`/audit/policy/redaction`, `mix threadline.policy.show`) flags the
  mismatch. Name this case in the generated comment and in the guide text from D-10.
- Rejected: raising in `down` (an irreversible migration). It is honest, but it
  blocks `mix ecto.rollback --step N` chains for everyone. Also rejected:
  today's behaviour, which silently leaves the table uncaptured while the
  original migration is still recorded as applied.

### Regression tests (prove RED before the fix)
- **D-08:** A file-level tier in a **new** `test/mix/tasks/threadline/gen_triggers_test.exs`
  (`async: false`). Reuse the tmp-dir, `Mix.Shell.Process`, and
  `storage_schema`-restore setup from `test/mix/tasks/threadline/install_test.exs`.
  Cases:
  1. Two runs of `--tables posts` give distinct Ecto names (extracted with
     Ecto's rule) and distinct, increasing versions.
  2. Two runs give distinct `defmodule` modules (via `Code.string_to_quoted!`,
     or compile and purge).
  3. A legacy `*_threadline_triggers_posts.exs` already in the dir before the
     first post-upgrade run causes no collision.
  4. The lookalike-name cases from D-02 (`posts_2`; `a_b` vs `a,b`).
  5. The rerun `down` omits the drops for a rerun table and keeps them for a
     first-run table, including the mixed table-set case.
  - Do **not** run `Ecto.Migrator` against the generated dir (206 D-10: shared
    test DB, no SQL sandbox by design; `ensure_no_duplication!/1` is `defp`).
- **D-09:** A DB tier in `test/threadline/capture/trigger_test.exs` or a sibling
  file. Follow its `DataCase` scratch-table pattern (`CREATE TABLE IF NOT EXISTS`,
  a unique table name, `on_exit` drops the trigger and table). Cases:
  1. Applying `create_trigger/1` twice succeeds. This is RED today with
     "already exists".
  2. The rerun's function wins: install the default trigger, then the per-table
     function (`store_changed_from: true`), then `create_trigger(t, :per_table)`.
     Assert `pg_trigger.tgfoid::regproc` is the per-table function and that an
     UPDATE records `changed_from`.
  3. Switching back to default mode removes the orphaned per-table function.
  - These run on the PG 14 min lane through `mix verify.test`, with no extra
    wiring needed.

### Docs (W2 + rerun truth)
- **D-10:** Correct all **four** wrong-default sites:
  `guides/audit-indexing.md:7`, `guides/production-checklist.md:14`,
  `guides/how-threadline-works.md:94`, and `guides/domain-reference.md:311`
  ("usually `threadline` unless you configured `storage_schema: \"public\"`").
  Research found the fourth; the D-11 guard flags exactly these four. Match the voice of the correct sites
  (`guides/getting-started-saas.md:63`,
  `guides/configuration-and-commands.md:32`): `public` by default, and a
  dedicated schema such as `"threadline"` is an opt-in chosen before install.
  Drop the confusing "explicit `public` for the historical footprint" phrasing.
- **D-11:** Widen the existing doc/default tie in
  `test/threadline/storage_schema_test.exs:36` ("the configuration reference
  states the default the code actually resolves"). Today it checks only
  `guides/configuration-and-commands.md`, which is why three stragglers
  survived 0.10.1. Add a guard over `guides/*.md` (and `README.md`) that
  rejects claims that the default is anything other than `StorageSchema.get([])`
  (e.g. "`threadline` by default", "default `threadline`", "defaults to
  `threadline`"). The guard must not trip on the legitimate opt-in example
  `storage_schema: "threadline"`. Prove it RED against the current three sites.
- **D-12:** Update the rerun instructions in `guides/production-checklist.md:45`,
  `guides/domain-reference.md:52-53`, and the gen.triggers moduledoc. They
  should say that a rerun writes a new migration that replaces the trigger in
  place, and state what rolling it back does (D-06/D-07). Check the doc-contract
  tests (`test/threadline/*doc_contract*`) for any assertion on the text being
  changed before editing.

### Release
- **D-13:** Use conventional `fix(gen.triggers): …` commits, so this ships in
  0.10.2 together with 206's unreleased installer fix. The `CREATE OR REPLACE`
  output change in `create_trigger/3` is a strict superset of the old behaviour
  (it is identical on a table without the trigger), so it is a fix, not a
  breaking change. Hand-write an entry in `CHANGELOG.md` under
  "Unreleased — highlights", next to the 206 entry, in its template and voice:
  - Breaking changes: none.
  - Required action: none. Adopters who hit the error delete the unappliable
    rerun migration and regenerate it on 0.10.2.
  - Fixed: quote both exact errors so a search lands here:
    `(Ecto.MigrationError) migrations can't be executed, migration name threadline_triggers_<tables> is duplicated`
    (`deps/ecto_sql/lib/ecto/migrator.ex:714-716`) and PostgreSQL's
    `trigger "threadline_audit_<t>" for relation "<t>" already exists`. State
    which releases are affected. The planner verifies from git history since
    when gen.triggers has used this naming.
  - Mention the three corrected guides.
  - Do not name `@moduledoc false` modules in backticks (206 D-05: ExDoc
    autolink warnings fail `mix docs --warnings-as-errors`).
  - Avoid a string of `fix(207): IN-0x` review-fix subjects (audit W4
    release-note noise). Use scoped subjects, or plan to squash.

### Claude's Discretion
- The exact helper names and signatures: the name-collision resolver, the
  non-CASCADE function drop, and the rerun-table detector.
- The exact wording of the generated rollback comment, the guide text, and the
  CHANGELOG entry, within the meaning locked above.
- Whether the DB tier goes in `trigger_test.exs` or a new sibling file.
- How to split the work into plans and commits.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit source
- `.planning/v1.41-MILESTONE-AUDIT.md` — items W1 (line ~35, ~90, ~153) and W2 (line ~41, ~154); W3/W4 context
- `.planning/ROADMAP.md` §"Phase 207" (line ~922) — goal and context bullets

### Precedent (phase 206, same bug class)
- `.planning/phases/206-installer-migration-versions/206-CONTEXT.md` — D-04 shared version helper, D-05 CHANGELOG/ExDoc rule, D-09/D-10 test harness and no-Migrator rule, D-11/D-12 release + CHANGELOG template
- `lib/threadline/mix/migration_version.ex` — the version helper; its recursive `**/*.exs` scan is the discovery rule to reuse

### Code under change
- `lib/mix/tasks/threadline.gen.triggers.ex` — filename (139-141), module (236-237), migration body (201-262), moduledoc (13)
- `lib/threadline/capture/trigger_sql.ex` — `create_trigger_sql` (117-126), `drop_trigger` (129-133), `drop_function_for_table` CASCADE (92-94)
- `deps/ecto_sql/lib/ecto/migrator.ex` — name extraction (675-695), `ensure_no_duplication!` (707-720)
- `lib/threadline/policy/redaction_presenter.ex:77-93`, `lib/threadline/health.ex:98-108` — catalog-based introspection (must keep working)
- `lib/threadline/storage_schema.ex:22` — `@default "public"`

### Tests
- `test/mix/tasks/threadline/install_test.exs` — tmp-dir harness; "install then gen.triggers" describe (~237-252); glob at 241
- `test/threadline/capture/trigger_test.exs` — DataCase scratch-table pattern
- `test/threadline/capture/trigger_sql_storage_schema_test.exs:25` — exact `CREATE TRIGGER` text assertion to update
- `test/threadline/storage_schema_test.exs:36-56` — existing documented-default tie (to widen)
- `test/threadline/public_surface_contract_test.exs` ~660 — `TriggerSQL` is public
- `test/threadline/*doc_contract*` — check before editing guide text

### Docs
- `guides/audit-indexing.md:7`, `guides/production-checklist.md:14`, `guides/how-threadline-works.md:94` — wrong default
- `guides/getting-started-saas.md:63`, `guides/configuration-and-commands.md:32`, `guides/upgrade-path.md:121-129` — correct wording to match
- `guides/production-checklist.md:45`, `guides/domain-reference.md:52-53` — rerun prescription
- `CHANGELOG.md` §"Unreleased — highlights" (line ~20) — where the entry goes
- `README.md:102` — PG 14 floor
- PostgreSQL 14 `CREATE TRIGGER` docs (`OR REPLACE`): https://www.postgresql.org/docs/14/sql-createtrigger.html

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Mix.MigrationVersion.next/2`: versions are already unique and increasing; only the name and module are not.
- The tmp-dir + `Mix.Shell.Process` harness and the `prefixes`/`assert_valid_increasing!` helpers in `install_test.exs`.
- `StorageSchema.host_table_suffix/1`, `StorageSchema.function/2`, and `StorageSchema.quote_ident/1` for building names and schema-qualified SQL.

### Established Patterns
- Generated SQL flows through `TriggerSQL`. The Mix task only assembles `execute` lines.
- `DROP ... IF EXISTS` in `down`. Per-table functions use `CREATE OR REPLACE FUNCTION`.
- Doc-contract tests keep guides aligned with code (CLAUDE.md "Doc contract tests").
- RED-before-fix is required for regression tests (206 precedent).

### Integration Points
- The redaction drift view and `Health.trigger_coverage` read `pg_trigger`/`pg_proc`. Trigger name `threadline_audit_<suffix>` must stay unchanged.
- The example apps' committed trigger migrations (`examples/*/priv/repo/migrations/*_threadline_triggers_*.exs`) must stay valid and are not regenerated.

</code_context>

<specifics>
## Specific Ideas

- The user wants one decisive recommendation, not menus (standing preference). Future ambiguity inside this scope: pick per the locked meaning above.
- First-run output must stay byte-identical (the D-01 name). Only reruns change shape.

</specifics>

<deferred>
## Deferred Ideas

- **W3:** gen.triggers hardcodes `priv/repo/migrations` (`gen.triggers.ex:131`) while install resolves the repo's `:priv`. With a custom `:priv`, the trigger migration lands where the repo never migrates. Same file, different bug. Candidate for a later phase.
- **W4 release-note noise:** handled only as the commit-subject guidance in D-13. The broader squash-on-landing decision stays with the milestone.
- Storing earlier trigger definitions so a rerun's `down` can truly restore the prior policy (the hair_trigger / fx `revert_to_version` model). This is a new capability and out of scope.

</deferred>

---

*Phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc*
*Context gathered: 2026-09-24*
