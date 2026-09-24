# Phase 207: Trigger Migration Rerun and Storage-Schema Default Docs - Research

**Researched:** 2026-09-24
**Domain:** Elixir Mix task codegen (Ecto migrations), PostgreSQL trigger DDL, doc-contract tests
**Confidence:** HIGH (every load-bearing claim was read in-repo or probed against real PostgreSQL 14 and 16 this session)

## Summary

The rerun bug is real, and it breaks in two different ways depending on the database. I reproduced it this session. Two runs of `mix threadline.gen.triggers --tables posts` in a temp dir wrote `20260924202610_threadline_triggers_posts.exs` and `20260924202611_threadline_triggers_posts.exs`. Both files contain `defmodule ThreadlineTriggersPosts do` and the same bare `CREATE TRIGGER "threadline_audit_posts"`. **New finding the CONTEXT does not state:** in the pinned ecto_sql 3.14.0, the duplicate-name check runs only over the *pending* migrations (`ensure_no_duplication!(pending)`, `deps/ecto_sql/lib/ecto/migrator.ex:456`). So on a database that has already applied the first trigger migration (production, a long-lived dev DB), only the rerun is pending. Ecto does not complain, and the migration fails in PostgreSQL with `trigger "threadline_audit_posts" for relation "posts" already exists`. The Ecto `migration name … is duplicated` error fires only when both files are pending together: a fresh or CI test database, `mix ecto.reset`, or a rollback across both files. The CHANGELOG must say which error shows up where (D-13).

All locked decisions are implementable as written. Three findings refine them:
1. **A fourth wrong-default site.** `guides/domain-reference.md:311` says the storage schema is "usually `threadline` unless you configured `storage_schema: "public"`". The D-11 guard (prototyped below) goes RED on it. It must be fixed with the other three, or the guard cannot pass.
2. **Camelizing the whole final name changes first-run output for tables whose names start with an uppercase letter.** `Macro.camelize("threadline_triggers_AuditLog")` is `ThreadlineTriggers_AuditLog`, but today's module is `ThreadlineTriggersAuditLog`. Build the module from the same *parts* as the name (`"ThreadlineTriggers" <> Enum.map_join(suffixes ++ ordinal, "", &Macro.camelize/1)`). This keeps D-02's "name and module cannot diverge" (both come from one function over one parts list) and keeps first-run output byte-identical for every valid identifier.
3. **`Threadline.Capture.TriggerSQL` is `@moduledoc false`** (`lib/threadline/capture/trigger_sql.ex:2`). It is hidden from HexDocs and has been unlisted since 0.10.0 (CHANGELOG.md:178). It is still *reachable*: the example app's hand-written migration calls `TriggerSQL.install_function`. D-03's "costly reversibility" still holds because adopter-committed migration files contain its output. Do not name it in backticks in the CHANGELOG or the guides.

**Primary recommendation:** Put the new pure logic (name/module resolver and rerun-table detector) in a small hidden module next to `Threadline.Mix.MigrationVersion`, sharing one migration-file discovery function. Add `CREATE OR REPLACE TRIGGER` and a non-CASCADE `drop_orphan_function_for_table/2` to `TriggerSQL`. Keep `gen.triggers` as the thin assembler. Prove each change RED first with the file tier (new `test/mix/tasks/threadline/gen_triggers_test.exs`), the DB tier (new sibling `test/threadline/capture/trigger_rerun_test.exs`), and the widened doc guard in `test/threadline/storage_schema_test.exs`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

The user accepted the full recommended set in one shot ("what's your rec? let's
go with that"). Three parallel advisor researchers settled the areas as one
consistent set.

#### Rerun naming (W1, name + module)
- **D-01:** Add an ordinal only when the name is taken. After
  `MigrationVersion.next/2`, collect every migration name already in the
  migrations dir, the way Ecto extracts it: `Integer.parse(Path.rootname(base))`
  gives `{int, "_" <> name}` (`deps/ecto_sql/lib/ecto/migrator.ex:675-695`).
  Walk the same recursive `**/*.exs` set that `MigrationVersion` scans. If
  `threadline_triggers_<suffix>` is free, use it unchanged, so first-run output
  stays byte-identical. Otherwise try `_2`, `_3`, ... until one is free.
- **D-02:** Derive the module by camelizing the **final** name, so the name and
  the module cannot diverge. A candidate is "taken" if **either** its name
  **or** its camelized module already exists in the dir. Camelizing collides
  on real inputs: table `posts_2` vs a rerun of `posts` + `_2` both give
  `ThreadlineTriggersPosts2`, and `[a_b]` vs `[a, b]` both give
  `ThreadlineTriggersAB`. Pick the next free candidate with a loop. Never parse
  a trailing ordinal back out of an existing name.
- Rejected: always embedding the version in the name and module. It churns
  first-run output for every adopter, the example apps, and any adopter
  tooling, and it lengthens names that are already long.

#### Rerun SQL (up)
- **D-03:** `create_trigger_sql` emits `CREATE OR REPLACE TRIGGER` on **every**
  run, not only on reruns. PostgreSQL 14 is the floor (`README.md:102`) and CI's
  `min` lane runs PG 14 (`.github/workflows/ci.yml` ~283-294), so this is safe
  and is tested at the floor. It swaps the trigger in one statement with no
  capture gap, even if a host sets `@disable_ddl_transaction`. The per-table
  `CREATE OR REPLACE FUNCTION`s still come first, then the triggers.
  — **Reversibility:** costly — `Threadline.Capture.TriggerSQL.create_trigger/3`
  is on the public surface (`test/threadline/public_surface_contract_test.exs` ~660),
  so its output text is a published contract.
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

#### Rerun rollback (down)
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

#### Regression tests (prove RED before the fix)
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

#### Docs (W2 + rerun truth)
- **D-10:** Correct all three wrong-default sites:
  `guides/audit-indexing.md:7`, `guides/production-checklist.md:14`, and
  `guides/how-threadline-works.md:94`. Match the voice of the correct sites
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

#### Release
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

### Deferred Ideas (OUT OF SCOPE)
- **W3:** gen.triggers hardcodes `priv/repo/migrations` (`gen.triggers.ex:131`) while install resolves the repo's `:priv`. With a custom `:priv`, the trigger migration lands where the repo never migrates. Same file, different bug. Candidate for a later phase.
- **W4 release-note noise:** handled only as the commit-subject guidance in D-13. The broader squash-on-landing decision stays with the milestone.
- Storing earlier trigger definitions so a rerun's `down` can truly restore the prior policy (the hair_trigger / fx `revert_to_version` model). This is a new capability and out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

No REQ-IDs. This phase closes tech debt W1 and W2 from the `.planning/v1.41-MILESTONE-AUDIT.md` second re-audit (lines 35, 41, 90, 153-154). The CONTEXT decisions are the contract.

| ID | Description | Research Support |
|----|-------------|------------------|
| W1 | Rerunning gen.triggers for tables that already have a trigger migration produces a migration Ecto accepts and applies; second-run regression test | Name/module resolver (Q1), OR REPLACE semantics verified on PG 14.23 and 16.14 (Q2), orphan drop target (Q3), rerun detector (Q4), test harness (Q5), Ecto pending-only duplicate check (Summary) |
| W2 | Every guide states the real `storage_schema` default (`public`) | Four wrong sites enumerated, guard regex prototyped against the live tree (Q6) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep the three-layer split. This phase touches only the **capture layer** (trigger DDL generation plus the Mix codegen) and docs. Trigger name `threadline_audit_<suffix>` must not change. The catalog readers depend on `LIKE 'threadline_audit_%'`.
- Capture uses generated PostgreSQL triggers installed through **host-owned Ecto migrations**. Preserve that boundary: no runtime DDL, and never run `Ecto.Migrator` from the task.
- Domain language: AuditChange, AuditTransaction, and so on. Do not invent new terms in guide text.
- Verification entrypoints are `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. Cite them in plans.
- Honest default tests: never exclude or skip tests. `test/threadline/zero_skips_contract_test.exs` enforces this. The DB tier runs in plain `mix test`.
- Doc contract tests keep README, guides, and the example README aligned. Check them before editing (done below, Q7).
- Local-memory gotchas that apply: never `git add .planning/` wholesale; run `mix` with the asdf env vars (Q9); a Dialyzer red in `ci.all` usually means a stale PLT (`mix dialyzer --plt`).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Migration name/module collision resolution | Mix codegen (`lib/threadline/mix/*`, hidden) | `Mix.Tasks.Threadline.Gen.Triggers` | Pure filesystem-scan logic, unit-testable, and shares Ecto's discovery rule with `MigrationVersion` |
| Rerun-table detection | Mix codegen (hidden helper) | — | Reads host migration sources at generation time. No DB access, because the task runs without a repo connection |
| Trigger DDL (`CREATE OR REPLACE TRIGGER`, non-CASCADE orphan drop) | Capture SQL (`Threadline.Capture.TriggerSQL`) | — | CLAUDE.md: "Generated SQL flows through `TriggerSQL`. The Mix task only assembles `execute` lines." |
| Applying DDL | Database (host `mix ecto.migrate`) | — | Host-owned migrations are the capture boundary |
| Drift and coverage introspection | Database catalogs (`pg_trigger`/`pg_proc`) read by `Health` and `RedactionPresenter` | — | Unchanged. Reads catalogs, not DDL text (verified, Q2) |
| Default-schema truth in docs | Guides + doc-contract test | `Threadline.StorageSchema.get([])` | The test ties prose to the code default |

## Standard Stack

No new dependencies. Everything used is already in the tree.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ecto_sql | 3.14.0 [VERIFIED: mix.lock:10] | The migration-discovery and duplicate rules we mirror | It is the migrator the adopter runs |
| PostgreSQL | floor 14, current 16 [VERIFIED: README.md:102 "PostgreSQL **14 min / 16 current**"; .github/workflows/ci.yml:291-299 `pg: "14"` (min) / `pg: "16"` (current)] | `CREATE OR REPLACE TRIGGER` (PG ≥ 14) | Floor is enforced by the CI `min` lane |
| Elixir | floor 1.15 (CI min lane), 1.17.3 current [VERIFIED: ci.yml:292-298] | `Macro.camelize/1`, `Code.string_to_quoted/2`, `Regex` | All available in 1.15. Do not use newer stdlib (e.g. `Enum.sum_by` is 1.18) |

**Installation:** none.

## Package Legitimacy Audit

Not applicable. This phase installs no external packages.

## Architecture Patterns

### System Architecture Diagram

```
mix threadline.gen.triggers --tables T1,T2 [--store-changed-from]
        │
        ▼
 parse opts + TriggerCaptureConfig.load  ──►  table_specs [{t, %{needs_per_table, opts}}]
        │
        ▼
 scan priv/repo/migrations/**/*.exs  (ONE discovery fn, Ecto's rule)
        │            │                         │
        │            ├─► existing versions ──► MigrationVersion.next/2 ──► version
        │            ├─► existing names + defmodule aliases ──► resolve_name(suffixes)
        │            │        base free? ──yes──► threadline_triggers_<suffix>, ThreadlineTriggers<Parts>
        │            │               └─no──► try _2, _3 … until name AND module both free
        │            └─► sources ──► rerun?(t): any file matches threadline_audit_<suffix>(?!\w)
        ▼
 migration_content(table_specs, module, rerun_set)
   up:   CREATE OR REPLACE FUNCTION (per-table tables)
         CREATE OR REPLACE TRIGGER  (every table)
         DROP FUNCTION IF EXISTS <storage>.threadline_capture_changes_<suffix>()  (default-mode tables, no CASCADE)
   down: first-run tables → DROP TRIGGER IF EXISTS …; DROP FUNCTION … CASCADE (per-table only)
         rerun tables     → comment only (capture stays on; drift view flags a removed-redaction rollback)
        ▼
 create_file(<version>_<name>.exs)  ──►  host runs mix ecto.migrate
```

### Recommended Project Structure
```
lib/threadline/mix/
├── migration_version.ex     # expose the shared discovery fn (e.g. existing/1 → [{version, name, path}])
└── trigger_migration.ex     # NEW, @moduledoc false: resolve_name/2, rerun_tables/2 (pure)
lib/threadline/capture/trigger_sql.ex   # OR REPLACE + drop_orphan_function_for_table/2
lib/mix/tasks/threadline.gen.triggers.ex # assembler only
test/mix/tasks/threadline/gen_triggers_test.exs   # NEW, file tier (D-08)
test/threadline/mix/trigger_migration_test.exs    # NEW (optional), pure unit tests of resolver/detector
test/threadline/capture/trigger_rerun_test.exs    # NEW, DB tier (D-09)
```
A new sibling file for the DB tier is recommended over adding to `trigger_test.exs`. That module's `setup_all` installs a shared trigger on `test_audit_target` and TRUNCATEs per test, and the rerun cases need their own trigger lifecycle per test.

### Pattern 1: One discovery function, Ecto's exact extraction (Q1)

Ecto's rule, verbatim [VERIFIED: deps/ecto_sql/lib/ecto/migrator.ex:660-699]:
```elixir
Path.join([directory, "**", "*.{ex,exs}"])
|> Path.wildcard()
|> Enum.map(&extract_migration_info/1)
...
  defp extract_migration_info(file) do
    base = Path.basename(file)

    case Integer.parse(Path.rootname(base)) do
      {integer, "_" <> name} ->
        if Path.extname(base) == ".ex" do
          ...
          nil
        else
          {integer, name, file}
```
`.ex` files return `nil` (warned and ignored), so scanning only `**/*.exs` gives the same set. `MigrationVersion` already does this [VERIFIED: lib/threadline/mix/migration_version.ex:60-70]:
```elixir
  defp existing_versions(path) do
    [path, "**", "*.exs"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.flat_map(fn file ->
      case Integer.parse(Path.basename(file, ".exs")) do
        {version, "_" <> _} -> [version]
        _ -> []
      end
    end)
  end
```
**Recommendation:** refactor this into a public `@doc false` function in `MigrationVersion`, e.g. `existing(path) :: [{integer, String.t(), Path.t()}]`. `existing_versions/1` becomes `Enum.map(existing(path), &elem(&1, 0))`, and the new resolver consumes the same list. That is "walk the same recursive `**/*.exs` set" (D-01) by construction, not by copy. `Path.basename(file, ".exs")` equals Ecto's `Path.rootname(base)` for `.exs` files.

The duplicate check that the names must satisfy, verbatim [VERIFIED: migrator.ex:708-720]:
```elixir
  defp ensure_no_duplication!([{version, name, _} | t]) do
    cond do
      List.keyfind(t, version, 0) ->
        raise Ecto.MigrationError,
              "migrations can't be executed, migration version #{version} is duplicated"

      List.keyfind(t, name, 1) ->
        raise Ecto.MigrationError,
              "migrations can't be executed, migration name #{name} is duplicated"
```
It is called only on the pending list [VERIFIED: migrator.ex:427-457, `ensure_no_duplication!(pending)`; `pending_in_direction(versions, source, :up)` filters `version not in versions` at 647-651]. Resolve against **all** names in the dir anyway (D-01). A fresh DB makes every file pending.

### Pattern 2: Name and module from one parts list (D-01/D-02, refinement)

```elixir
# Source: derived this session; probe output below
def resolve_name(suffixes, existing) do  # existing: %{names: MapSet, modules: MapSet}
  Stream.iterate(1, &(&1 + 1))
  |> Enum.find_value(fn n ->
    parts = if n == 1, do: suffixes, else: suffixes ++ [Integer.to_string(n)]
    name = "threadline_triggers_" <> Enum.join(parts, "_")
    module = "ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)
    if name in existing.names or module in existing.modules, do: nil, else: {name, module}
  end)
end
```
Why parts rather than `Macro.camelize(final_name)`: a probe this session compared today's module with camelizing the whole name:
```
["posts"]        current=ThreadlineTriggersPosts   derived=ThreadlineTriggersPosts SAME
["posts_2"]      current=ThreadlineTriggersPosts2  derived=ThreadlineTriggersPosts2 SAME
["a_b"] / ["a","b"]  both ThreadlineTriggersAB SAME
["AuditLog"]     current=ThreadlineTriggersAuditLog derived=ThreadlineTriggers_AuditLog DIFF
```
`"AuditLog"` is a valid table identifier (`StorageSchema` accepts `~r/^[A-Za-z_][A-Za-z0-9_]*$/`, lib/threadline/storage_schema.ex:23). For every lowercase-initial table the two forms are identical. `Macro.camelize("2") == "2"`, so the ordinal part yields `…Posts2`, exactly D-02's example. D-02's intent holds: one function derives both from one list, so they cannot diverge. Its literal wording ("camelizing the final name") would change first-run output for uppercase-initial tables. **Planner: adopt the parts form and note it as a D-02 refinement.** It does not reopen D-02.

The `n == 1` base must equal today's name exactly. Today's code is [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex:140-141 and 236-237]:
```elixir
      table_suffix = Enum.map_join(tables, "_", &StorageSchema.host_table_suffix/1)
      file = Path.join(path, "#{version}_threadline_triggers_#{table_suffix}.exs")
...
    module_name =
      "ThreadlineTriggers#{Enum.map_join(tables, "", &(StorageSchema.host_table_suffix(&1) |> Macro.camelize()))}"
```
So `suffixes = Enum.map(tables, &StorageSchema.host_table_suffix/1)`.

### Pattern 3: Reading existing `defmodule` aliases (Q1)

**Use a regex over the source, not `Code.string_to_quoted!` and never `Code.compile_file`/`eval`.**
```elixir
@defmodule ~r/^\s*defmodule\s+([A-Z][A-Za-z0-9_.]*)\s+do\b/m
modules = for [_, m] <- Regex.scan(@defmodule, source), into: MapSet.new(), do: m
```
Reasons:
- Host migration dirs hold hundreds of arbitrary host files. `string_to_quoted!` raises on any unparseable file, and the non-bang form needs an AST walk to find nested modules. Compiling executes host code at generation time.
- A regex false positive (a `defmodule` in a heredoc or comment) only skips a candidate to the next ordinal. That is conservative and harmless.
- Host migrations are usually `MyApp.Repo.Migrations.X`. Compare the full alias string; Threadline's are top-level (`ThreadlineTriggersPosts`).

In **tests**, use `Code.string_to_quoted!/1` on the generated file to extract the module (D-08 case 2), because we control that file:
```elixir
{:defmodule, _, [{:__aliases__, _, parts}, _]} = file |> File.read!() |> Code.string_to_quoted!()
Module.concat(parts)
```

### Pattern 4: Rerun-table detection (Q4)

Trigger name source [VERIFIED: lib/threadline/capture/trigger_sql.ex:117-133]:
```elixir
  defp create_trigger_sql(table_name, function_invocation) do
    trigger_name = "threadline_audit_#{StorageSchema.host_table_suffix(table_name)}"
```
How the name appears in generated files (the task writes `execute #{inspect(sql)}`, gen.triggers.ex:207/219/224):
- current releases: `execute "CREATE TRIGGER \"threadline_audit_posts\"\nAFTER …` (reproduced this session)
- legacy (0.1.0-era format, still committed): `execute "CREATE TRIGGER threadline_audit_posts\nAFTER …"` [VERIFIED: priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs:5]

In both, the name is followed by a non-word character (`\` from the escaped quote or `\n`). Detector:
```elixir
def rerun?(suffix, sources) do
  re = Regex.compile!("threadline_audit_" <> Regex.escape(suffix) <> "(?![A-Za-z0-9_])")
  Enum.any?(sources, &Regex.match?(re, &1))
end
```
The negative lookahead is required. Plain `String.contains?` would treat `posts` as a rerun whenever `threadline_audit_posts_archive` exists.

Schema-qualified tables: `host_table_suffix("support.tickets") == "support_tickets"` [VERIFIED: storage_schema.ex:121-129 and storage_schema_test.exs:120]. Detection and naming both use `host_table_suffix`, so they agree. Known pre-existing aliasing: public `support_tickets` and `support.tickets` share the suffix. Detection then errs toward "rerun" (conservative: `down` keeps capture on). The per-table function name also collides. That aliasing predates this phase and is out of scope; record it as a pitfall.

### Pattern 5: SQL changes in TriggerSQL (Q2, Q3)

```elixir
  defp create_trigger_sql(table_name, function_invocation) do
    ...
    """
    CREATE OR REPLACE TRIGGER #{StorageSchema.quote_ident(trigger_name)}
    AFTER INSERT OR UPDATE OR DELETE ON #{host_table}
    FOR EACH ROW EXECUTE FUNCTION #{function_invocation}
    """
  end

  @doc "Returns SQL to drop a per-table capture function only if nothing depends on it (no CASCADE)."
  def drop_orphan_function_for_table(table_name, opts \\ []) do
    "DROP FUNCTION IF EXISTS #{per_table_function_name(table_name, opts)}()"
  end
```
Orphan-drop target [VERIFIED: trigger_sql.ex:135-138]:
```elixir
  defp per_table_function_name(table_name, opts) do
    function_name = "threadline_capture_changes_#{StorageSchema.host_table_suffix(table_name)}"
    StorageSchema.function(function_name, opts)
  end
```
and `StorageSchema.function/2` is `qualify(get(opts), name)` → `"<storage_schema>"."<name>"` (storage_schema.ex:90-92). The function therefore lives in the **Threadline storage schema**, not the host table's schema. For `support.tickets` with default config: `"public"."threadline_capture_changes_support_tickets"`; with `storage_schema: "threadline"`: `"threadline"."threadline_capture_changes_support_tickets"`. The existing assertion at trigger_sql_storage_schema_test.exs:44-45 already pins this shape for the CASCADE variant. gen.triggers passes no opts (`TriggerSQL.create_trigger(t)` at :217), so both helpers resolve the app-env schema at generation time. Keep that: pass no opts to the new helper either.

Emission order in `up` for a default-mode table: `CREATE OR REPLACE TRIGGER …` **then** `DROP FUNCTION IF EXISTS …()`. The drop must follow the trigger re-point, because PostgreSQL refuses a non-CASCADE drop while a trigger still references the function (probe below).

### Pattern 6: Rerun `down` template

Today's `down` joins `trigger_downs` and `function_downs` (gen.triggers.ex:222-247). Filter both by `t not in rerun_set` and add the comment block when `rerun_set != []`. If every table is a rerun, `def down do` contains only comments. That is valid Elixir: an Ecto migration whose `down` issues no commands is fine. The comment text is packaged source and must pass the vocabulary scan (Pitfall 5).

### Anti-Patterns to Avoid
- **Parsing an ordinal back out of an existing name** (forbidden by D-02). Always generate candidates forward and test membership.
- **`String.contains?` for rerun detection.** Prefix collision (`posts` vs `posts_archive`).
- **`Code.compile_file`/`Code.eval_file` of host migrations** to learn module names. This executes host code and redefines modules in the task VM.
- **Using `drop_function_for_table/2` for the orphan cleanup.** It appends `CASCADE` (trigger_sql.ex:92-95) and would silently drop a trigger that still uses the function.
- **Running `Ecto.Migrator` in tests** (206 D-10; shared DB, no sandbox).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Migration discovery | A second glob with its own parse | `MigrationVersion` discovery fn (made public `@doc false`) | Two scanners drift. Ecto's rule is `Integer.parse(rootname)` + `"_" <> name` |
| Identifier quoting in new SQL | String interpolation of raw table names | `StorageSchema.quote_ident/1`, `qualify/2`, `per_table_function_name/2` | Validates against `~r/^[A-Za-z_][A-Za-z0-9_]*$/` and ≤63 bytes |
| Atomic trigger swap | `DROP TRIGGER` + `CREATE TRIGGER` | `CREATE OR REPLACE TRIGGER` (PG ≥ 14) | No capture gap, one statement (rejected alternative in D-05) |
| Module-name camelization | Custom capitalizer | `Macro.camelize/1` per part | Must equal today's output byte-for-byte |

## Runtime State Inventory

Not a rename phase, but generated code lands in adopter repos. The one relevant category:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Adopter DBs' `schema_migrations` rows for already-applied trigger migrations; these are unaffected | None. New migrations get new versions and names |
| Live service config | None. Verified: no external service stores trigger DDL | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | Committed trigger migrations in `examples/threadline_phoenix/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs`, `…20260527154557_threadline_triggers_organizations_…exs`, `priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs` (bare `CREATE TRIGGER`, unquoted names) | **Do not regenerate** (CONTEXT). They stay valid. Use the hex_evaluator file as the realistic legacy fixture for D-08 case 3 |
| Library's own migrations | `priv/repo/migrations/20260423120000_threadline_verify_coverage_canary.exs:17` calls `TriggerSQL.create_trigger/1` at migrate time; `priv/ci/topology_bootstrap.exs:36` too | None. OR REPLACE makes both idempotent. Applied rows are not re-run |

## Common Pitfalls

### Pitfall 1: Believing the Ecto duplicate-name error is the only failure
**What goes wrong:** Tests or CHANGELOG say only "Ecto refuses duplicate names".
**Why it happens:** ecto_sql checks duplicates only among pending migrations (migrator.ex:456). On a DB where the first migration is applied, the rerun alone is pending and fails in PostgreSQL instead.
**How to avoid:** The DB tier (D-09.1) proves the PG half, and the file tier (D-08.1/2) proves the Ecto half. The CHANGELOG names both errors and when each appears.

### Pitfall 2: First-run output drift
**What goes wrong:** Changing module derivation or name joining alters first-run file names or modules.
**How to avoid:** Pin with a test that `--tables posts` into an empty dir yields `*_threadline_triggers_posts.exs` + `defmodule ThreadlineTriggersPosts`, and a multi-table case `posts,org_memberships` → `ThreadlineTriggersPostsOrgMemberships`. Note: file *contents* do change on first run (OR REPLACE per D-03, orphan drop per D-05). Only the name and module are byte-stable.

### Pitfall 3: Orphan drop ordered before the trigger re-point
**What goes wrong:** `DROP FUNCTION … ()` (no CASCADE) before `CREATE OR REPLACE TRIGGER` fails with `cannot drop function … because other objects depend on it`.
**How to avoid:** Emit the drop after that table's trigger statement. Covered by D-09.3.

### Pitfall 4: Suffix aliasing across schemas
**What goes wrong:** `support.tickets` and public `support_tickets` share `threadline_capture_changes_support_tickets` (pre-existing). The non-CASCADE orphan drop for one fails loudly while the other's trigger uses it.
**How to avoid:** This is D-05's intended loud failure. Document it in the pitfall list only; fixing suffix aliasing is out of scope.

### Pitfall 5: Planning vocabulary leaking into packaged source or CHANGELOG
**What goes wrong:** `test/threadline/release_artifact_contract_test.exs` fails. It bans these shapes in packaged files [VERIFIED: release_artifact_contract_test.exs:7-14]:
```elixir
    {:phase_prose, ~r/\bPhase\s+\d+(?:\.\d+)?\b/i},
    {:phase_identifier, ~r/\bphase[_-]?\d+(?:[_-][a-z0-9_]+)?\b/i},
    {:decision_id, ~r/\bD-\d{2,}\b/},
    {:requirement_id,
     ~r/\b(?:ADOPT|COMP|CRITIC|DATA|GREEN|GROUP|MECH|NAV|PROOF|SURFACE|WR)-\d{2,}\b/},
    {:milestone_literal, ~r/\bv1\.(?:3[4-9]|4[01])\b/}
```
**How to avoid:** No `D-06`, `Phase 207` or `v1.41` in lib comments, the generated migration comment, guides, or CHANGELOG. Tests may use them, but prefer durable wording anyway.

### Pitfall 6: Hidden modules in backticks
`Threadline.Capture.TriggerSQL` and `Threadline.Mix.*` are `@moduledoc false`. Backticking them in CHANGELOG, guides or the gen.triggers moduledoc triggers ExDoc autolink warnings, which fail `mix docs --warnings-as-errors`. Also `test/threadline/code_walkthrough_doc_contract_test.exs:72-83` refutes `"Threadline.Capture.TriggerSQL"` in `guides/how-threadline-works.md` and `guides/code-walkthrough.md`, even without backticks.

### Pitfall 7: Test env storage schema
`config/test.exs:50` sets `config :threadline, storage_schema: "threadline"`. File-tier tests that assert SQL text must pin the schema (`Application.delete_env` → `public`, or `put_env "threadline"`) and restore it, as install_test does (lines 15-37). `config/test.exs:62-69` also configures `test_redaction_users` with exclude/mask/store_changed_from, so `--tables test_redaction_users` exercises per-table mode without CLI flags.

### Pitfall 8: `regproc` rendering depends on search_path
`tgfoid::regproc` prints `threadline.threadline_capture_changes_x` or the bare name depending on `search_path`. Assert on `pg_proc.proname` + `pg_namespace.nspname` via joins, or on `tgfoid = to_regprocedure($1)::oid`. Do not string-compare `regproc` output.

## Code Examples

### D-09 DB tier skeleton (sibling file)
```elixir
# Pattern source: test/threadline/capture/trigger_changed_from_test.exs:1-35, trigger_test.exs:6-24
defmodule Threadline.Capture.TriggerRerunTest do
  use Threadline.DataCase   # async: false by default; setup cleans storage schemas

  alias Threadline.Capture.{AuditChange, TriggerSQL}

  @table "test_trigger_rerun_target"

  setup do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS #{@table} (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL, value integer)
    """)
    on_exit(fn ->
      Repo.query!(TriggerSQL.drop_trigger(@table))
      Repo.query!(TriggerSQL.drop_function_for_table(@table))
      Repo.query!("DROP TABLE IF EXISTS #{@table}")
    end)
    :ok
  end

  defp trigger_function do
    %{rows: [[nsp, fn_name]]} =
      Repo.query!("""
      SELECT n.nspname, p.proname FROM pg_trigger t
      JOIN pg_proc p ON p.oid = t.tgfoid JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE t.tgrelid = $1::regclass AND t.tgname = $2 AND NOT t.tgisinternal
      """, [@table, "threadline_audit_" <> @table])
    {nsp, fn_name}
  end

  test "installing the trigger twice succeeds" do
    Repo.query!(TriggerSQL.create_trigger(@table))
    Repo.query!(TriggerSQL.create_trigger(@table))   # RED today: already exists
    assert {_, "threadline_capture_changes"} = trigger_function()
  end
  # case 2: default → install_function_for_table(@table, store_changed_from: true)
  #         → create_trigger(@table, :per_table); assert proname == "threadline_capture_changes_" <> @table;
  #         INSERT, clear audit rows with repo_opts(), UPDATE, assert [change] = Repo.all(AuditChange, repo_opts())
  #         and change.changed_from != nil
  # case 3: per-table → create_trigger(@table) → drop_orphan_function_for_table(@table);
  #         assert Repo.query!("SELECT to_regprocedure($1)", [~s("threadline"."threadline_capture_changes_#{@table}"())]).rows == [[nil]]
  #         and trigger_function() == {"threadline", "threadline_capture_changes"}
end
```
Every `Repo.all/delete_all` on an audit schema needs `repo_opts()`. `test/threadline/storage_schema_call_site_contract_test.exs` statically rejects unprefixed call sites. A test-only table in `public` needs no prefix.

### D-08 file tier skeleton
```elixir
# Pattern source: test/mix/tasks/threadline/install_test.exs:1-66
defmodule Mix.Tasks.Threadline.GenTriggersTest do
  use ExUnit.Case, async: false
  alias Mix.Tasks.Threadline.Gen.Triggers
  @migrations "priv/repo/migrations"
  # setup: copy install_test.exs:15-37 verbatim (shell, storage_schema restore, tmp dir)
  defp run_triggers(tmp, args), do: (File.cd!(tmp, fn -> Triggers.run(args) end); drain_shell([]))
  defp trigger_files(tmp), do: Path.wildcard(Path.join([tmp, @migrations, "**", "*_threadline_triggers_*.exs"])) |> Enum.sort()
  defp ecto_name(file) do
    {_, "_" <> name} = file |> Path.basename() |> Path.rootname() |> Integer.parse()
    name
  end
  defp module_of(file) do
    {:defmodule, _, [{:__aliases__, _, parts}, _]} = file |> File.read!() |> Code.string_to_quoted!()
    Module.concat(parts)
  end
  defp down_body(file), do: file |> File.read!() |> String.split("def down do") |> List.last()
end
```
For case 3, `File.cp!("priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs", Path.join([tmp, @migrations, "20260424080642_threadline_triggers_posts.exs"]))`. It is a real legacy artifact with `defmodule ThreadlineTriggersPosts` and the unquoted `CREATE TRIGGER threadline_audit_posts`. Do this *before* `File.cd!`, because the path is relative to the repo root.

### D-11 guard (prototyped against the live tree this session)
```elixir
# Scope each line to storage-schema talk, then capture any default-claim value.
@scope ~r/storage[ _]schema/i
@id "`\"?([A-Za-z_][A-Za-z0-9_]*)\"?`"
@claims [
  Regex.compile!("\\bdefaults?\\s+(?:to\\s+)?(?:the host.s\\s+)?" <> @id, "i"),
  Regex.compile!("\\(default\\s+" <> @id),
  Regex.compile!(@id <> "\\s+(?:\\(the default\\)|by default)", "i"),
  Regex.compile!("\\busually\\s+" <> @id, "i")
]
# files: Path.wildcard("guides/**/*.md") ++ ["README.md"]; assert every captured value == StorageSchema.get([])
```
Prototype output on today's tree:
```
guides/audit-indexing.md:7 -> threadline WRONG
guides/domain-reference.md:311 -> threadline WRONG
guides/getting-started-saas.md:63 -> public ok
guides/how-threadline-works.md:94 -> threadline WRONG
guides/production-checklist.md:14 -> threadline WRONG   (matched twice)
guides/upgrade-path.md:89 -> public ok
guides/upgrade-path.md:121 -> public ok
guides/upgrade-path.md:125 -> public ok
guides/upgrade-path.md:129 -> public ok
```
It does not trip on `storage_schema: "threadline"` examples (getting-started 44/55, readme contract), on `schema: "public"` Health defaults, or on the code-walkthrough SQL that uses `threadline.audit_transactions`. Make it non-vacuous two ways, following the release_artifact "matcher rejects every representative offender" pattern:
1. A pure matcher test runs the claim function on the four known-bad sentences (must flag) and on the known-good sentences (must pass).
2. The real-tree scan asserts it found at least 3 correct claims, e.g. `getting-started-saas.md:63`, `upgrade-path.md:121`, `upgrade-path.md:129`, so a regex that silently stops matching fails.

Put it in the existing `describe "default storage schema (D-01)"` block of `test/threadline/storage_schema_test.exs`, which already clears the env so `StorageSchema.get([])` is the code default.

## Q2 Detail: Callers, Catalog Readers, PG Semantics

**Every caller of `TriggerSQL.create_trigger`** (grep this session): lib only `lib/mix/tasks/threadline.gen.triggers.ex:216-217`. Tests: `continuity_brownfield_test.exs:39,55`, `audit_transaction_test.exs:20`, `health_test.exs:180`, `verify_coverage_task_test.exs:147`, `capture/trigger_test.exs:17`, `capture/trigger_sql_storage_schema_test.exs:23,31`, `capture/trigger_context_test.exs:16`, `capture/trigger_changed_from_test.exs:39,89,121`, `capture/trigger_redaction_test.exs:51`, `operator_surface/policy_show_mix_test.exs:74,87,97,237`, `operator_surface/live/coverage_live_test.exs:429`, `operator_surface/live/policy_redaction_live_test.exs:342,387`, `policy/redaction_presenter_catalog_test.exs:56`, `test/support/storage_schema_case.ex:149`. Priv: `priv/ci/topology_bootstrap.exs:36`, `priv/repo/migrations/20260423120000_threadline_verify_coverage_canary.exs:17`. All execute the SQL. OR REPLACE is a strict superset, so none should break. Several (`trigger_changed_from_test.exs` setup) currently drop before re-creating; they keep working.

**Exact-text assertions on `CREATE TRIGGER`:** only `test/threadline/capture/trigger_sql_storage_schema_test.exs:25`, which reads `assert sql =~ ~S|CREATE TRIGGER "threadline_audit_support_tickets"|`. Update it to `CREATE OR REPLACE TRIGGER`. Line 44-45 (`DROP FUNCTION IF EXISTS "threadline"."threadline_capture_changes_support_tickets"()` via `=~`) still matches the CASCADE variant; add a sibling assertion that the orphan helper yields the same text **without** ` CASCADE`. Other hits are not assertions on TriggerSQL output: `policy_redaction_live_test.exs:358` is a hand-written literal, the committed example migrations are data, and the moduledoc at gen.triggers.ex:13 is prose to update.

**Catalog-only introspection** [VERIFIED: read this session]: `RedactionPresenter.fetch_deployed/2` (redaction_presenter.ex:76-104) selects from `pg_trigger t JOIN pg_class c … JOIN pg_proc p ON t.tgfoid = p.oid … WHERE t.tgname LIKE 'threadline_audit_%'`. `Health.fetch_threadline_covered_tables/2` (health.ex:97-108) selects `pg_trigger … WHERE t.tgname LIKE 'threadline_audit_%'`. `mix threadline.verify_coverage` calls `Threadline.Health.trigger_coverage(repo: repo, schema: schema)` (lib/mix/tasks/threadline.verify_coverage.ex:54). No lib code uses `pg_get_triggerdef` or parses DDL text. Because the presenter follows `tgfoid`, an orphaned per-table function (before D-05 drops it) is invisible to drift detection. The drop is hygiene, not correctness for the viewer.

**PostgreSQL semantics** [CITED: https://www.postgresql.org/docs/14/sql-createtrigger.html]: "CREATE OR REPLACE TRIGGER will either create a new trigger, or replace an existing trigger." "All other properties are replaced." "Currently, the `OR REPLACE` option is not supported for constraint triggers." "Replacing an existing trigger within a transaction that has already performed updating actions on the trigger's table is not recommended." None of these bite: Threadline triggers are plain `AFTER … FOR EACH ROW` triggers, and migrations do not write the audited table first.

**Probe, PostgreSQL 14.23 (throwaway `postgres:14-alpine` container) [VERIFIED: live probe]:**
```
CREATE TRIGGER
ERROR:  trigger "threadline_audit_t" for relation "t" already exists
CREATE TRIGGER                       <- CREATE OR REPLACE TRIGGER … f2()
 threadline_audit_t | f2             <- tgfoid::regproc after replace
DROP FUNCTION                        <- non-CASCADE drop of the now-orphaned f1 succeeds
ERROR:  cannot drop function f2() because other objects depend on it
ERROR:  CREATE OR REPLACE CONSTRAINT TRIGGER is not supported
```
The same results were reproduced on the local PostgreSQL 16.14 (port 5433). The PG error text for the CHANGELOG is exactly `trigger "threadline_audit_<suffix>" for relation "<table>" already exists`. The relation is printed **unqualified** (e.g. `"t"`, not `"probe207"."t"`).

**CI min lane** [VERIFIED: .github/workflows/ci.yml:283-299]: `lane: min` → `elixir: "1.15"`, `otp: "26"`, `pg: "14"`, `runner: "ubuntu-22.04"`, running `mix verify.test` (line 355). New DB-tier tests run at the floor automatically.

## Q7 Detail: Doc-Contract Tests Touching the Edited Text

| File edited | Contract tests reading it | Assertions near the edited lines? |
|---|---|---|
| `guides/production-checklist.md` (lines 14, 45) | `production_checklist_doc_contract_test.exs` | No. Asserts `## Host repo wiring (prerequisite)`, `config :threadline, ecto_repos: [MyApp.Repo]`, `getting-started-saas.md#configure-threadline`, `resolve_repo!/0`, and ordering before `## 1. Capture and triggers`. **Keep the `## 1. Capture and triggers` heading**: `domain-reference.md:217` links `#1-capture-and-triggers` |
| `guides/domain-reference.md` (52-53, 311) | `operator_surface/policy_show_doc_contract_test.exs:76-88` | Asserts line-240 literals only (`mix threadline.policy.show --schema=NAME`, `…--schema=support`, "`--schema=NAME` selects the audited host schema", "does not change Threadline's storage schema"). Do not touch line 240 |
| `guides/audit-indexing.md` (7) | `audit_indexing_doc_contract_test.exs` | No. Asserts marker `<!-- IDX-02-AUDIT-INDEXING -->`, headings (`## Installed defaults` …), and links to `domain-reference.md`/`production-checklist.md` |
| `guides/how-threadline-works.md` (94) | `how_threadline_works_doc_contract_test.exs`, `code_walkthrough_doc_contract_test.exs` | No text assertion on 94. Keep 4 mermaid blocks. **Must not contain** `Threadline.Capture.TriggerSQL` (code_walkthrough_doc_contract_test.exs:72-83; how_threadline_works…:76) |
| `lib/mix/tasks/threadline.gen.triggers.ex` | `code_walkthrough_doc_contract_test.exs:12-14` | Source must keep the anchor `StorageSchema.threadline_table?` (unchanged code). `public_surface_contract_test.exs` keeps Gen.Triggers in the visible Mix Tasks group |
| `lib/threadline/policy/redaction_presenter.ex` hints | `policy_show_doc_contract_test.exs:94-95`, `redaction_presenter_test.exs:180`, `policy_show_mix_test.exs:131` | Exact `Rerun \`mix threadline.gen.triggers\` and apply the migration.` Not in D-12 scope; **do not edit** |
| `guides/operator-surface.md:423-424`, `README.md:105` | coverage/readme contracts | Also say "rerun gen.triggers". Not in D-12 scope; the drift hint stays true after the fix. Leave them unless the planner wants parity (no contract blocks a light edit) |
| README | `guide_graph_contract_test.exs:107-121` | Do **not** add a bash/elixir fence containing `mix threadline.gen.triggers` to README (the sequence owner is getting-started only) |

## Q8 Detail: History and CHANGELOG

- `git log -S'_threadline_triggers_' -- lib/mix/tasks/threadline.gen.triggers.ex` → first commit `27553946 2026-04-22 feat: scaffold capture infrastructure with trigger-backed audit schema`. `git show v0.1.0:…` has `file = Path.join(path, "#{timestamp()}_threadline_triggers_#{table_suffix}.exs")`, `module_name = "ThreadlineTriggers#{…Macro.camelize/1…}"`, and in trigger_sql.ex `CREATE TRIGGER threadline_audit_#{table_name}`. `git show v0.10.1:…` has the same name pattern (line 134), the same module derivation (235), and `CREATE TRIGGER` (trigger_sql.ex:122). **Affected: every release 0.1.0 through 0.10.1** [VERIFIED: git]. Tags: v0.1.0, 0.2.0, 0.4.0 … 0.10.0, 0.10.1.
- Structure to append to [VERIFIED: CHANGELOG.md:19-66]: `## Unreleased — highlights` → boilerplate paragraph → 206 prose paragraph → `### Breaking changes` (None.) → `### Required action` → `### Fixed` (three bullets, the second already about gen.triggers versions). **Recommendation:** do not add a second set of `###` headings. Add a second prose paragraph after the 206 paragraph (the rerun bug in upgrader terms). Append a paragraph under `### Required action` ("None, unless … delete the rerun migration that failed and regenerate it"). Append bullets under `### Fixed`: the rerun (both errors, when each appears), rollback behaviour, and "guides now state the `public` default: audit-indexing, production-checklist, how-threadline-works, domain-reference". Keep Breaking changes "None."
- `test/threadline/changelog_contract_test.exs` constrains only the **newest dated** entry (prose first; `### Breaking changes|Required action` before `### Added|Changed|Fixed…`; no generated commit-link bullets) and bans bracketed `[Unreleased]`. The Unreleased block is unconstrained today, but it becomes the 0.10.2 entry at release, so keep that order. `release_artifact_contract_test.exs` scans CHANGELOG for planning vocabulary (Pitfall 5).
- Don't backtick `Threadline.Capture.TriggerSQL` (hidden; CHANGELOG.md:178 already names it un-backticked).

## Q9 Detail: Working Local Commands

Confirmed this session. `mix test` of the four relevant files gave `29 tests, 0 failures` in 0.3 s with:
```bash
bash -c 'cd /Users/jon/projects/threadline && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/threadline/storage_schema_test.exs test/mix/tasks/threadline/install_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/capture/trigger_test.exs'
```
Local DB: container `threadline-postgres-1`, image `postgres:16`, `127.0.0.1:5433->5432`. Phase gate, taken verbatim from the 206 plans that passed:
```bash
bash -c 'cd /Users/jon/projects/threadline && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test'
bash -c 'cd /Users/jon/projects/threadline && ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix verify.format && ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix verify.credo && ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=dev mix verify.dialyzer && ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix verify.xref_cycles && ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=dev mix docs --warnings-as-errors'
```
Plus `mix compile --force --warnings-as-errors` after lib edits. The file-level repro used this session (useful as a manual probe):
```bash
bash -c 'P=/tmp/207-probe; rm -rf "$P" && mkdir -p "$P" && cd /Users/jon/projects/threadline && MIX_ENV=test DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix run --no-start -e "Application.delete_env(:threadline, :storage_schema); File.cd!(\"$P\", fn -> Mix.Tasks.Threadline.Gen.Triggers.run([\"--tables\", \"posts\"]); Mix.Tasks.Threadline.Gen.Triggers.run([\"--tables\", \"posts\"]) end)" && ls $P/priv/repo/migrations'
```
Today this yields two `…_threadline_triggers_posts.exs` files, both `defmodule ThreadlineTriggersPosts`. After the fix, the second must be `…_threadline_triggers_posts_2.exs` / `ThreadlineTriggersPosts2`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `DROP TRIGGER IF EXISTS` + `CREATE TRIGGER` to redefine | `CREATE OR REPLACE TRIGGER` | PostgreSQL 14 [ASSUMED: first release with OR REPLACE for triggers; consistent with PG 14 docs having it and the D-03/D-05 reasoning; not separately probed on PG 13] | Atomic swap, no capture gap. Safe because Threadline's floor is 14 |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `OR REPLACE` for triggers first appeared in PG 14 (no probe on PG 13) | State of the Art | None for this phase. The floor is 14 and was probed live |
| A2 | Adopters on other ecto_sql versions have the same pending-only duplicate check | Summary / CHANGELOG wording | Low. Phrase the CHANGELOG as "on a database that has not applied …" rather than naming the ecto_sql internals |
| A3 | No adopter hand-edits generated migrations in a way that removes the `threadline_audit_<suffix>` literal while keeping the trigger | Pattern 4 | Low. Detection would call the table "first-run" and `down` would drop the trigger, which matches today's behaviour |

## Open Questions (RESOLVED)

All four questions carried a recommendation, and the plans adopt each one.

1. **D-02 wording vs uppercase-initial tables.**
   - What we know: `Macro.camelize` of the whole name differs from today for `AuditLog`-style tables (probe above).
   - Recommendation: use the parts form (Pattern 2). It satisfies D-02's intent and the "first-run byte-identical" specific. Not a user question.
   - RESOLVED: adopted in plan 207-02 (Task 1 Step D, `Threadline.Mix.TriggerMigration.resolve_name/2` builds the module from the name parts).
2. **Fourth wrong-default site (`guides/domain-reference.md:311`).**
   - What we know: the D-11 guard catches it, so D-10's list is incomplete.
   - Recommendation: fix it in the same doc task. Suggested text: "usually `public` unless you configured a dedicated `storage_schema` such as `"threadline"`".
   - RESOLVED: adopted in plan 207-03 Task 1 Step B (fourth site fixed; the guard's positive control covers it).
3. **NOTICE on first run.** `DROP FUNCTION IF EXISTS` on a nonexistent function emits a PostgreSQL NOTICE (`… does not exist, skipping`). D-05 accepted "harmless on a first run". Mention it in the moduledoc so adopters are not surprised. No decision change.
   - RESOLVED: adopted in plan 207-02 Task 3 Step C (`## Rerunning` moduledoc names the first-run NOTICE).
4. **Should the task print a line when it detects rerun tables?** This is discretion. Recommendation: one info line naming the rerun tables and that `down` keeps capture on. Tests can assert it via `drain_shell`.
   - RESOLVED: adopted in plan 207-02 Task 3 Step B (one info line naming the rerun tables).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (local test DB) | DB tier D-09 | ✓ | 16.14 on 127.0.0.1:5433 (`threadline-postgres-1`) | — |
| PostgreSQL 14 | floor behaviour | ✓ (image `postgres:14-alpine` present; CI min lane authoritative) | 14.23 probed | CI `min` lane |
| Erlang/Elixir via asdf | all mix commands | ✓ | 27.3.x / 1.17.3-otp-27 (`.tool-versions` untracked, pins erlang 27.3.4.15) | — |
| psql client | manual probes only | ✓ | /opt/homebrew/bin/psql | — |

No missing dependencies.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3 local; 1.15 on CI min) |
| Config file | `test/test_helper.exs` (excludes only `pgbouncer_topology`) |
| Quick run command | `bash -c 'cd /Users/jon/projects/threadline && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/capture/trigger_rerun_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/storage_schema_test.exs test/threadline/mix/'` |
| Contract batch | add `test/mix/tasks/threadline/install_test.exs test/threadline/changelog_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/code_walkthrough_doc_contract_test.exs test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/audit_indexing_doc_contract_test.exs test/threadline/production_checklist_doc_contract_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs` |
| Full suite command | `bash -c 'cd /Users/jon/projects/threadline && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test'` |

### Decision → Test Map
| Decision | Behavior | Type | Test (file :: case) | RED today? | Exists? |
|---|---|---|---|---|---|
| D-01 | 2× `--tables posts` → distinct Ecto names, increasing 14-digit versions | file | gen_triggers_test :: "rerun gets a distinct Ecto name" | ✅ RED (both `threadline_triggers_posts`) | ❌ Wave 0 |
| D-01 | first run into empty dir keeps `threadline_triggers_posts` / `ThreadlineTriggersPosts`; multi-table name unchanged | file | gen_triggers_test :: "first run output name is unchanged" | green (pin) | ❌ |
| D-02 | 2× runs → distinct `defmodule` (via `Code.string_to_quoted!`) | file | gen_triggers_test :: "rerun gets a distinct module" | ✅ RED | ❌ |
| D-02 | lookalikes: table `posts_2` then `posts` rerun; `a_b` then `a,b` → no name or module clash | file | gen_triggers_test :: "lookalike names" | ✅ RED (`a_b` vs `a,b` both `threadline_triggers_a_b`) | ❌ |
| D-01/D-02 | legacy hex_evaluator file present → new run picks `_2` | file | gen_triggers_test :: "legacy migration present" | ✅ RED | ❌ |
| D-01/D-02 | resolver/detector pure logic (existing names/modules sets; lookahead boundary `posts` vs `posts_archive`) | unit | test/threadline/mix/trigger_migration_test.exs | n/a (new fn) | ❌ |
| D-03 | SQL text is `CREATE OR REPLACE TRIGGER "threadline_audit_support_tickets"` | unit | trigger_sql_storage_schema_test.exs:25 (update) | ✅ RED after edit-first | ✅ (edit) |
| D-03 | applying `create_trigger/1` twice succeeds | DB | trigger_rerun_test :: case 1 | ✅ RED (`already exists`) | ❌ |
| D-03 | rerun to per-table re-points `tgfoid`; UPDATE records `changed_from` | DB | trigger_rerun_test :: case 2 | ✅ RED | ❌ |
| D-04 | drift view and coverage still read the swapped trigger | DB | existing `policy_show_mix_test.exs`, `redaction_presenter_catalog_test.exs`, `health_test.exs` (full suite) | green (regression net) | ✅ |
| D-05 | default-mode `up` has `DROP FUNCTION IF EXISTS "<s>"."threadline_capture_changes_<t>"()` after the trigger, no `CASCADE` | file + unit | gen_triggers_test :: "orphan drop follows trigger"; trigger_sql_storage_schema_test :: new orphan-helper assertion (`refute =~ "CASCADE"`) | ✅ RED | ❌ |
| D-05 | per-table → default switch removes the orphan function, trigger now on global fn | DB | trigger_rerun_test :: case 3 | ✅ RED (helper absent → UndefinedFunctionError) | ❌ |
| D-06 | rerun table's `down` has no DROP TRIGGER/FUNCTION; first-run table keeps them; mixed set (`posts,users` then `posts,comments`) | file | gen_triggers_test :: "down per table" | ✅ RED | ❌ |
| D-06/D-07 | generated comment present (capture stays on; removed-redaction rollback continues unredacted; drift view flags it) | file | gen_triggers_test :: same case, `=~` on stable phrases | ✅ RED | ❌ |
| D-10/D-11 | no guide or README claims a non-`public` default; matcher flags 4 known offenders; ≥3 real correct claims found | unit (doc) | storage_schema_test.exs :: new tests in "default storage schema" describe | ✅ RED (4 sites) | ✅ (extend) |
| D-12 | rerun text updated in production-checklist:45, domain-reference:52-53, moduledoc | doc | optional `=~` assertion on "replaces the trigger in place" in gen_triggers_test or a doc contract | n/a | ❌ optional |
| D-13 | CHANGELOG shape/vocabulary | contract | changelog_contract_test, release_artifact_contract_test | green (guard) | ✅ |

### RED-first protocol
Write each new test first and run the quick command, expecting failure with the specific message: two identical names, `already exists`, `UndefinedFunctionError` for the orphan helper, and the guard listing the four guide lines. Record the RED output in the plan SUMMARY, then implement. For the `trigger_sql_storage_schema_test.exs:25` edit, change the assertion before the SQL.

### Sampling Rate
- **Per task commit:** quick run command
- **Per wave merge:** contract batch + quick
- **Phase gate:** full suite + format/credo/dialyzer/xref/docs gate (Q9) green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/mix/tasks/threadline/gen_triggers_test.exs`: D-01/D-02/D-05/D-06/D-07
- [ ] `test/threadline/capture/trigger_rerun_test.exs`: D-03/D-05 DB tier
- [ ] `test/threadline/mix/trigger_migration_test.exs` (optional): pure resolver/detector
- [ ] Extend `test/threadline/storage_schema_test.exs`: D-11 guard
- No framework install needed

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Table names pass `StorageSchema.parse_table_identifier/1` → `validate!/1` (`~r/^[A-Za-z_][A-Za-z0-9_]*$/`, ≤63 bytes). All new SQL goes through `quote_ident`/`per_table_function_name`. Use `Regex.escape/1` on the suffix in the detector |
| V6 Cryptography | no | — |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL identifier injection via `--tables` | Tampering | Existing validation + quoting; new helper reuses `per_table_function_name/2` |
| Code execution by reading host migrations | Elevation | Regex scan only. Never `Code.compile_file`/`eval` host files |
| Silent capture loss on rollback | Repudiation (audit gap) | D-06: rerun `down` keeps capture on. Non-CASCADE drop fails loudly instead of cascading into a trigger (D-05) |
| Fail-open redaction after rolling back a redaction-removing rerun | Information disclosure | Accepted (D-07). The drift view flags it. Documented in the generated comment and the guides |

## Sources

### Primary (HIGH confidence)
- In-repo files read this session: `lib/mix/tasks/threadline.gen.triggers.ex`, `lib/threadline/capture/trigger_sql.ex`, `lib/threadline/storage_schema.ex`, `lib/threadline/mix/migration_version.ex`, `lib/threadline/policy/redaction_presenter.ex:60-110`, `lib/threadline/health.ex:85-125`, `deps/ecto_sql/lib/ecto/migrator.ex:425-760`, `test/mix/tasks/threadline/install_test.exs`, `test/threadline/capture/{trigger_test,trigger_changed_from_test,trigger_sql_storage_schema_test}.exs`, `test/threadline/storage_schema_test.exs`, `test/support/data_case.ex`, `test/threadline/{changelog,release_artifact,public_surface,code_walkthrough_doc,production_checklist_doc,audit_indexing_doc,guide_graph}_contract_test.exs`, `CHANGELOG.md:1-80,170-185`, `config/test.exs:50-69`, `.github/workflows/ci.yml:276-360`, `README.md:98-106`
- Live probes: PostgreSQL 14.23 (throwaway container) and 16.14 (local) for OR REPLACE and non-CASCADE drop semantics; gen.triggers double-run repro; camelize comparison; D-11 regex prototype over `guides/**/*.md` + README
- git: `git log -S`, `git show v0.1.0:` / `v0.10.1:` of gen.triggers and trigger_sql

### Secondary (MEDIUM confidence)
- PostgreSQL 14 CREATE TRIGGER docs: https://www.postgresql.org/docs/14/sql-createtrigger.html

### Tertiary (LOW confidence)
- None load-bearing. (The research-plan/cache seam was not used; all findings come from the codebase, git, or live probes.)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. No new deps; versions read from mix.lock/ci.yml
- Architecture: HIGH. Every decision mapped to verified code lines; resolver and detector semantics probed
- Pitfalls: HIGH. The Ecto pending-only check, the camelize divergence, and the fourth doc site were all found by reading or probing, not assumed

**Research date:** 2026-09-24
**Valid until:** 2026-10-24 (stable; re-check if ecto_sql is bumped)
