# Phase 209: Collision-Free Emission - Research

**Researched:** 2026-09-25
**Domain:** Generated PostgreSQL trigger/function DDL (Elixir Mix generator), migration-safety SQL, ExUnit/telemetry test infrastructure
**Confidence:** HIGH (every in-repo claim was read this session; the key PG behaviours were re-run on local PG 14.17; the full suite was probed with a temporary 42622 handler)

## Summary

CONTEXT.md already fixes the design (D-01..D-11). This research covers what the planner still needs: the exact call sites, how the test harness actually runs generated SQL, the historical SQL that fixtures must copy byte for byte, whether the NoticeGuard is feasible, and six concrete risks. It found no evidence against any locked decision. It found two things the planner must correct in the CONTEXT `<specifics>` and one gap in D-04. They are listed first under Common Pitfalls:

1. **The combined-regeneration assertion in `<specifics>` is wrong for this naming scheme.** The spec says: "combined `--tables billing_invoices,billing.invoices` … the legacy function is gone (`to_regprocedure` is NULL)". But `public.billing_invoices` is public and at most 36 bytes, so `Naming.function_name` gives it the legacy name `threadline_capture_changes_billing_invoices`, the same name as the old shared function. In the combined run that function is **rewritten with public's rules and kept**, and `billing.invoices` moves to `…_billing_invoices_9bba11019407`. The right assertion: each function has exactly one trigger user, and the legacy-named body contains only public's mask.
2. **The retire set must exclude every function name that this migration's triggers now use, not only the table's own name.** Read literally, D-04 would retire `legacy_function_name(billing.invoices)` in the combined run. That is public's live function, so the D-01 block would print a misleading `WARNING … kept … because triggers on public.billing_invoices still use it` in a migration that is correct. Also, retire blocks must run **after every trigger re-point**. Today the orphan drop is interleaved after each trigger (`gen.triggers.ex:307-314`). With two tables on one shared name, the first table's drop would then see the second table as a user and keep an orphan.
3. **D-01's `string_agg(… ORDER BY 1)` does not sort.** Inside an aggregate, `1` is a constant, not a column position. On PG 14.17 it returned catalog order (`public.billing_invoices, billing.invoices, zz.aa`), whereas `ORDER BY n.nspname, c.relname` gave `billing.invoices, public.billing_invoices, zz.aa`. This fix stays within the D-01 shape: use the explicit keys so the WARNING text is deterministic and tests can assert it.

The rest confirms D-09 and D-10. Postgrex puts NOTICEs on `%Postgrex.Result{messages: [%{code: "42622", message: …}]}`. `client_min_messages` is `notice` in the test DB. The repo's telemetry event is `[:threadline, :test, :repo, :query]`, and ecto_sql emits it even with `log: false`. Today's suite (1924 tests) produces **exactly two** 42622 hits, both from a deliberate overlong `CREATE FUNCTION` in `trigger_rerun_test.exs`. That test has to change when the guard lands. `Ecto.Migrator.up/4` runs migrations in a `Task.async`, so a guard keyed strictly by `self()` cannot drain migration-originated hits from the test process. Keying by the root of `$callers` fixes that.

**Primary recommendation:** Land the NoticeGuard and its controls first, together with the fix to the two deliberate truncations. Next rewrite `rerun?`, which is pure unit work. Then move `TriggerSQL` onto `Naming` and add the DO-block builders. Then do migration assembly (retire, guard, advisory, comment). Prove SC1 to SC3 with a new real-PG test module that **compiles each generated migration and runs it through `Ecto.Migrator.up/4` and `down/4`**. That path is the only one that proves transaction atomicity (D-05) and WARNING logging (D-01) the way an adopter sees them. Work in the main checkout, one plan after another: worktrees have no `deps/` or `_build`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Per-table function name derivation | Generator (Elixir, `Threadline.Capture.Naming`) | — | Pure, frozen format from 208. TriggerSQL must delegate, never concatenate. |
| Function/trigger DDL text | Generator (`Threadline.Capture.TriggerSQL`) | — | Frozen literal SQL written into host migrations. |
| Orphan-safe drop, post-condition guard | Database (inline `DO` blocks at migrate time) | Generator emits them | Only the DB knows `pg_trigger.tgfoid` fan-in at migrate time. The static scan is advisory only. |
| Migration assembly (order, retire set, down, comments) | Generator (`Mix.Tasks.Threadline.Gen.Triggers`) | — | Owns ordering: functions, then triggers, then guard, then retire. |
| Rerun detection | Generator (`Threadline.Mix.TriggerMigration`, text-only regex) | — | Never compiles host files (Anti-Pattern 4). |
| Truncation-NOTICE guard | Test infrastructure (`test/support`, `test_helper.exs`) | — | Suite-level. Not shipped. |
| Atomic rollback of a failed guard | Database + Ecto migrator (DDL transaction) | — | Ecto wraps each migration in one transaction by default. |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Orphan-safe function drop (SC3, NAME-04)
- **D-01:** Every generated migration drops a capture function through **one frozen, readable inline `DO` block per function**. The shape:
  ```sql
  -- threadline: drop this capture function only if no trigger still uses it
  DO $$
  DECLARE
    fn    regprocedure := to_regprocedure('"<storage_schema>"."<name>"()');
    users text;
  BEGIN
    IF fn IS NULL THEN RETURN; END IF;
    SELECT string_agg(format('%I.%I', n.nspname, c.relname), ', ' ORDER BY 1) INTO users
      FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE t.tgfoid = fn;
    IF users IS NULL THEN
      EXECUTE format('DROP FUNCTION %s', fn);
    ELSE
      RAISE WARNING 'threadline: kept % because triggers on % still use it; regenerate triggers for those tables', fn, users;
    END IF;
  END $$;
  ```
  - The drop is `DROP FUNCTION` without `CASCADE`, so it defaults to RESTRICT. PG re-checks dependencies when the drop runs. The worst race is therefore a loud `2BP01`, never a removed trigger. No `LOCK` is needed.
  - Use `RAISE WARNING`, not `NOTICE`. `ecto_sql` logs DDL WARNINGs during `mix ecto.migrate` and `ecto.rollback` where adopters see them. NOTICE is logged at `:info` and is easily missed.
  - When the function is still referenced, keep it and warn. **Never raise from this block**, because a shared legacy name is a legitimate state during an upgrade.
  - Always emit the `to_regprocedure` literal with fully **quoted** schema and name. A mixed-case storage schema resolves only when quoted.
  - The generator must check `byte_size <= 63` on every function-name literal before emitting it, using `StorageSchema.validate_identifier!(…, :derived)` or an equivalent. `to_regprocedure` silently cuts an overlong name with **no NOTICE** and can then match a different function (verified on PG 14.17).
  - **Reversibility:** one-way. The SQL is frozen into adopters' migrations.
- **D-02:** Remove `CASCADE` from every generated statement, including `down`.
  - `TriggerSQL.drop_function_for_table/2` loses `CASCADE`. `down` now runs `DROP TRIGGER IF EXISTS …` and then the D-01 block, only for functions this migration first created.
  - Delete `per_table_function_fits?/1` and the skip in `gen.triggers`'s `orphan_function_drop/1`. The `tgfoid` check replaces them.
  - Suggested helper name: `TriggerSQL.drop_function_if_unused/…`. The exact name is at Claude's discretion.
- **D-03:** The pattern follows the milestone research. It is Pattern 4 / Anti-Pattern 3 in `.planning/research/ARCHITECTURE.md`, with one change: `down` never uses `CASCADE` either.
  - An installed SQL helper function was rejected. 0.10.x installs lack it, it would couple frozen migrations to install order, and it hides the logic from operators, against the SQL-native constraint.
  - A plain RESTRICT drop, which is today's behaviour, was also rejected. It fails `up` in the shared-legacy case and blocks the fix.

#### Retiring 0.10.x function names and sibling exposure (SC1, NAME-02)
- **D-04:** `up` runs in this order for each table, in the migration's single DDL transaction:
  1. `CREATE OR REPLACE FUNCTION <Naming.function_name(pair)>` for tables in per-table mode.
  2. `CREATE OR REPLACE TRIGGER "<Naming.trigger_name>" … ON "schema"."table"`, pointing at the new per-table function or at the global one.
  3. Retire each distinct old name through the D-01 block, only when it differs from what the trigger now uses. The old names are:
     - `Naming.legacy_function_name(pair)`, which is the 0.10.x name cut to 63 bytes;
     - the table's current per-table name, when the table moved to the global function.

  Regenerating a table **never** touches the old shared function's body. A moved table gets its own new hashed function. Verified on PG 14.17.
  - **Reversibility:** one-way. Frozen migration SQL.
- **D-05 (maintainer-approved, HIGH-IMPACT):** add a **post-condition guard** DO block for each per-table function the migration wrote. It runs after all of the migration's triggers are re-pointed.
  - If any trigger whose `tgfoid` is that function sits on a table other than its owner (`to_regclass('"schema"."table"')`), the guard runs `RAISE EXCEPTION`.
  - The `HINT` carries the exact fix, for example `mix threadline.gen.triggers --tables billing_invoices,billing.invoices`, or "regenerate billing.invoices first".
  - The migration then applies nothing, because it is one atomic transaction.
  - The two cases differ on purpose:
    - Regenerating only the **moved** table (e.g. `billing.invoices` → hashed) is a strict improvement. It passes, and D-01 warns that `public.billing_invoices` is still on the legacy function.
    - Regenerating only the table that **keeps** the legacy name (e.g. `public.billing_invoices`) would rewrite the shared body and move `billing.invoices` onto public's rules. That is exactly what NAME-02 forbids, so it raises.
    - Safe orders: both tables in one command, or the moved table first.
    - Long names that share a 36-byte prefix both move to hashed names, so they can only warn, never raise.
  - The maintainer accepted that this can fail a deploy. CI migrates a fresh DB, so it hits the failure before production.
  - **Reversibility:** one-way. Frozen migration SQL, and it is adopter-visible deploy behaviour.
- **D-06:** Add an advisory warning in `gen.triggers` at generation time.
  - Reuse the D-08 `ON`-clause parse over `scan.sources`.
  - If an earlier migration covers a table **outside** `--tables` that has the same `legacy_function_name` as a table being generated, print a `Mix.shell` warning suggesting both tables in one command.
  - It is advisory only, not a gate: hand-written SQL escapes a static scan, and D-05 is the real gate.
- **D-07:** `down`, for tables this migration regenerated (reruns), keeps the trigger and the new function, as today.
  - Extend `rerun_rollback_comment` to say the migration retired `<old>`, that rolling back does not recreate it, and that the trigger keeps using `<new>`.
  - For tables installed for the first time, `down` runs `DROP TRIGGER IF EXISTS`, then the D-01 block for the new function.

#### Rerun detection (SC2, NAME-03)
- **D-08:** Change `TriggerMigration.rerun?` to `rerun?(%{schema: s, table: t}, sources)`. It never compares a trigger name to the target, which fulfils 208 D-02/D-11. Contract:
  1. **Normalize each source.** Turn `\"` into `"`, and turn `\n`, `\t` and `\r` escapes into spaces. Every release wrote `execute #{inspect(sql)}`. None wrote runtime `TriggerSQL` calls.
  2. **Scan `CREATE` statements only.** Case-insensitive:
     `\bCREATE\s+(?:OR\s+REPLACE\s+)?(?:CONSTRAINT\s+)?TRIGGER\s+(ID)\s+(?:AFTER|BEFORE|INSTEAD\s+OF)\b[^;]{0,300}?\bON\s+(ID)(?:\s*\.\s*(ID))?`
     where `ID = "(?:[^"]|"")+"|[A-Za-z_][A-Za-z0-9_$]*`.
  3. **Normalize identifiers.** For a quoted identifier, strip the quotes, turn `""` into `"`, and keep the exact case. Lowercase an unquoted one, as PG does.
  4. **Identify Threadline triggers by prefix only.** The normalized trigger name must start with `threadline_audit_`.
  5. **Match on the `ON` clause.**
     - A qualified `ON` matches only on exact `{schema, table}` equality.
     - An unqualified `ON`, which appears only in pre-0.10 files, matches on `table` for **any** target schema. That errs conservative.
  - **Rulings:**
    - Ignore `DROP` statements.
    - A `CREATE` in either `up` or `down` counts.
    - A hand-renamed trigger without the prefix does not match. That is harmless, because the new `down` drops only the current name `ON` this table.
    - Ambiguity always resolves toward "rerun": rollback keeps a trigger and never drops live capture.
  - This fixes both 208 hand-offs: the 46-byte shared-prefix false positive, and `public.a_b` vs `a.b`. It also removes the old uncut-name false negative.
  - **Historical forms to freeze in fixtures:**

    | Releases | Up statement |
    |---|---|
    | 0.1.0-0.9.0 | unquoted `CREATE TRIGGER threadline_audit_posts … ON posts` |
    | 0.10.0-0.10.1 | quoted `CREATE TRIGGER "…" … ON "public"."posts"` |
    | 0.10.2 | quoted `CREATE OR REPLACE TRIGGER "…" … ON "public"."posts"` |

  - **Reversibility:** reversible. It is internal, and generation-time only.

#### Truncation NOTICE guard (SC4)
- **D-09:** Add a test-support module `Threadline.Test.NoticeGuard` in `test/support/`, attached in `test/test_helper.exs` **before** `Ecto.Migrator.run`.
  - It attaches to the repo's `[:threadline, :test, :repo, :query]` telemetry event and reads `metadata.result = {:ok, %Postgrex.Result{messages: …}}`.
  - It keeps only messages whose `code == "42622"` (name_too_long). It never matches the English message text, which depends on `lc_messages`.
  - Hits go into a public `:duplicate_bag` ETS table keyed by `self()`.
  - The handler body is wrapped in a rescue, because telemetry silently detaches a handler that raises.
  - `ExUnit.after_suite(&NoticeGuard.verify!/1)` prints the hits. If there are any hits, **or the handler is no longer attached**, it registers `System.at_exit(fn _ -> exit({:shutdown, 1}) end)`, which makes the suite exit non-zero.
  - **Do not build it on Logger.** Verified facts:
    - Postgrex never logs notices (postgrex 0.22.4).
    - `ecto_sql` 3.14.0 logs them only for migration DDL, at `:info`.
    - `config/test.exs` sets the Logger level to `:warning`.
    - PostgreSQL cannot promote a NOTICE to an ERROR.
- **D-10:** Positive and negative controls:
  - An async test runs `Repo.query!("SELECT 1 AS <64×c>")` and asserts that `NoticeGuard.take()` returns exactly one hit, then clears it. `take/1` removes only the calling process's entries.
  - A 63-byte alias asserts `take() == []`.
  - A contract test runs `mix test` with an env flag (for example `THREADLINE_TRUNCATION_GUARD_CANARY=1`) whose canary test leaves a hit un-drained, and asserts a non-zero exit. This follows the existing `THREADLINE_VERIFY_COVERAGE_FAILURE_TEST` pattern.
  - `test_helper` asserts `SHOW client_min_messages` is `notice`, because at `warning` or higher `messages` comes back empty.
- **D-11:** A second, static layer: a generated-SQL assertion that every identifier `gen.triggers` emits is ≤ 63 bytes, and that no emitted SQL matches `~r/CASCADE/i` on a capture function. SC4 itself is met by D-09.

### Claude's Discretion
- Exact helper names in `TriggerSQL`, such as the drop-if-unused and post-condition-guard builders, and how they are split across modules.
- The exact wording of the WARNING and the HINT. The wording must say the sibling's rules "may" be another table's, because the migration cannot know what the current body contains.
- Test file layout, and whether the three historical fixtures live in one module or several.
- Whether the post-condition guard is one DO block per function or one per migration, provided that it runs after every re-point and names the offending tables.

### Deferred Ideas (OUT OF SCOPE)
- **Phase 212:**
  - A `:shared_capture_function` health finding: a per-table function used by more than one trigger.
  - A finding for more than one Threadline trigger on a table.
  - These catch adopters who upgrade the dependency but never regenerate. 209 adds no health code.
- **Phase 212/213:** a pre-0.10 unqualified `ON posts` run under a non-public `search_path` put `threadline_audit_posts` on `app.posts`. Regenerating `app.posts` would add a second trigger, `threadline_audit_app_posts`. This is a NAME-03 hazard for the upgrade guide and for health detection, not something the matcher can solve.
- **Phase 213 upgrade guide:**
  - Regenerate every per-table-mode table in one command, and name the collision pairs.
  - A CHANGELOG security note, including that rows already leaked stay in `audit_changes`.
- **Phase 213 (critical):** 0.10.x trigger migrations have a frozen `down` of `DROP FUNCTION IF EXISTS threadline_capture_changes_<x>() CASCADE`.
  - Rolling one back after the upgrade can cascade-drop a sibling's live trigger.
  - The guide must say not to roll back pre-0.11 trigger migrations, or to remove `CASCADE` from their `down` first.
  - 213's `ecto.rollback --all` round-trip test must use a 0.10 fixture edited that way.
- The example app's hand-edited pre-0.10 trigger migrations, one with `CASCADE` in `down`, are Phase 212's twin-regeneration work. Leave them unless a 209 test needs them.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NAME-02 | Two audited tables never share a per-table capture function (same-named across schemas, and long names sharing 36 bytes); each applies only its own redaction rules. | Call-site inventory (TriggerSQL → `Naming.function_name/1`); D-04 retire-set correction (Pitfall 2); D-05 guard verified on PG 14.17; real-PG harness via `Ecto.Migrator.up/4`; corrected combined-run assertion (Pitfall 1). |
| NAME-03 | Regenerating over a 0.10.x install never creates a second Threadline trigger; fitting trigger names stay byte-identical. | Historical SQL recovered from `v0.9.0`/`v0.10.0`/`v0.10.2`; D-08 regex prototyped against all three forms (output below); `Naming.trigger_name` == PG-stored name, so `CREATE OR REPLACE TRIGGER` replaces in place. |
| NAME-04 | Cleanup never drops/disables another table's trigger; no `CASCADE`; drop only when no `tgfoid` references it. | CASCADE sites inventoried (`trigger_sql.ex:97`, `gen.triggers.ex:326-331`); D-01 block re-run on PG 14.17 (keeps + WARNING); ecto_sql maps WARNING → `:warn` (verified in deps source). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Three-layer separation: this phase is **capture layer only**. No health, `policy.show`, or exploration code. Those are 212.
- Capture uses generated PG triggers installed through host-owned Ecto migrations. Keep that boundary: no installed helper SQL function (also D-03).
- SQL-native: operators must be able to read the DO blocks. Keep them inline and commented.
- Named verification entrypoints: cite `mix verify.test` and `mix ci.all`, not ad-hoc commands, in plans and summaries.
- Honest default tests: do **not** exclude anything new from `mix test`. `test/threadline/zero_skips_contract_test.exs` asserts that the ExUnit exclude list is exactly `[pgbouncer_topology: true]` and that no test file carries a skip tag [VERIFIED: test/threadline/zero_skips_contract_test.exs:64-79, quote: `else: [{@topology_tag, true}]` with `@topology_tag :pgbouncer_topology`]. The NoticeGuard canary therefore **cannot** be an excluded tag (see Pattern 5).
- Zero human verification: every SC maps to an automated test (Validation Architecture below).
- No planning vocabulary (phase numbers, requirement IDs, `D-xx`) in `lib/`, guides, HexDocs, CHANGELOG, or releasable commit subjects. Note that 208 used `fix(208-02): …` subjects. Use a product scope such as `fix(capture): …` for releasable commits. `source_size_contract_test.exs` also checks `~r/Phase \d|STRUCT-\d|\bD-\d{2}\b/` in exception reasons [VERIFIED: test/threadline/source_size_contract_test.exs:47].
- `lib/` file limit 800 lines, function limit 120 lines [VERIFIED: test/threadline/source_size_contract_test.exs:43-44, quote: `@file_limit 800`, `@function_limit 120`]. `trigger_sql.ex` is 561 lines and `gen.triggers.ex` 382 today. `migration_content/3` will grow, so split it into helpers.
- Local gate gotchas (memory): `.tool-versions` must pin erlang and elixir (it is untracked but present). A `ci.all` red at Dialyzer means a PLT cache miss (`mix dialyzer --plt`). The browser lane has exactly 8 pre-existing screenshot failures; they are not regressions. Never `git add .planning/` wholesale.

## Standard Stack

No new dependencies. Everything needed is already locked in `mix.lock`:

| Library | Version (mix.lock) | Use in this phase |
|---------|-------------------|-------------------|
| ecto_sql | 3.14.0 [VERIFIED: mix.lock:10] | `Ecto.Migrator.up/4`/`down/4` in real-PG tests; DDL WARNING logging |
| postgrex | 0.22.4 [VERIFIED: mix.lock:39] | `%Postgrex.Result{messages: …}` for the NoticeGuard; `Postgrex.Error` carries `hint` |
| telemetry | 1.4.2 [VERIFIED: mix.lock:43] | `:telemetry.attach/4` for the NoticeGuard |
| stream_data | 1.4.0 [VERIFIED: mix.lock:41] | the `rerun?` property from CONTEXT specifics |
| PostgreSQL | 14 (min) / 16 (current) in the CI matrix [VERIFIED: .github/workflows/ci.yml:294-308, `pg: "14"`, `pg: "16"`, `image: postgres:${{ matrix.pg }}`] | `CREATE OR REPLACE TRIGGER` needs 14+ |

## Package Legitimacy Audit

Not applicable. This phase installs **no** external packages. All libraries above are already in `mix.lock`.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Current Code: Every Call Site That Must Change

### `lib/threadline/capture/trigger_sql.ex` [VERIFIED: read this session]
| Line | Today | Change |
|------|-------|--------|
| 94-98 | `def drop_function_for_table(table_name, opts \\ [])` → `"DROP FUNCTION IF EXISTS #{name}() CASCADE"` | Remove `CASCADE` (D-02). Keep it as a plain RESTRICT drop for test cleanup and manual use. Six test files call it in `setup`/`on_exit` after `drop_trigger`, so RESTRICT is safe there (see "Existing tests that break"). |
| 100-110 | `def per_table_function_fits?(table_name)` | Delete (D-02). |
| 112-115 | `def drop_orphan_function_for_table/2` → `"DROP FUNCTION IF EXISTS " <> … <> "()"` | Delete. Replace with a DO-block builder, e.g. `drop_function_if_unused(function_name, opts)` that takes a **name**, not a table, because the retire set names legacy functions no table currently owns. |
| 158-170 | `defp per_table_function_name/2` → `per_table_function_base` → `StorageSchema.validate_identifier!(:derived)` → `StorageSchema.function(opts)`; `per_table_function_base` = `"threadline_capture_changes_#{StorageSchema.host_table_suffix(table_name)}"` | Route through `Naming.function_name(table)`, then `StorageSchema.function(opts)`. This ends the interim `:derived` raise (208-VERIFICATION "Known interim deviation"). |
| 41, 94, 101-106, 112, 121 | Docs naming `threadline_capture_changes_<table>()`, "or with CASCADE", the 63-byte skip | Rewrite the docs. Do not promise the `<table>` shape, because hashed names exist. |

The `Naming` values to delegate to [VERIFIED: lib/threadline/capture/naming.ex:44,50,52,100,104-105,109-115]: `@function_prefix "threadline_capture_changes_"`, `@legacy_table_max 36`, `@stem_max 23`, `def trigger_name(table), do: cut(@trigger_prefix <> suffix(table), @max_identifier_bytes)`, `def legacy_function_name(table), do: cut(@function_prefix <> suffix(table), @max_identifier_bytes)`, and `function_name/1` returning `@function_prefix <> pair.table` (legacy) or `@function_prefix <> cut(suffix(pair), @stem_max) <> "_" <> hash12(qualified(pair))`.

Golden values the tests will need [VERIFIED: test/threadline/capture/naming_test.exs:14-29, quote: `"threadline_capture_changes_billing_invoices_9bba11019407"`, `"threadline_capture_changes_billing_invoices"`, `"threadline_capture_changes_customer_subscription_l_3b9be56c3c45"`]. `support.tickets` hashes to `0a670b783726` (recomputed with `shasum -a 256` this session), so its function becomes `threadline_capture_changes_support_tickets_0a670b783726`.

### `lib/mix/tasks/threadline.gen.triggers.ex` [VERIFIED: read with line numbers]
| Line | Today | Change |
|------|-------|--------|
| 17-29 | moduledoc: "per-table functions `threadline_capture_changes_<table>()`" | Reword. Hashed names exist. |
| 49-54 | moduledoc: "harmless NOTICE that the function does not exist. The drop is skipped when … longer than PostgreSQL's 63-byte identifier limit" | Rewrite. The DO block returns silently when the function is absent, never drops a function that is still in use, and prints a WARNING naming the tables. Add the migrate-time error and its safe orders (D-05). |
| 84-92 | "Long table names … In per-table mode … such a table is still rejected … until a later release" | Rewrite. Per-table mode now works for long and non-public tables via hashed function names. |
| 196-202 | comment: "A derived name that does not fit, such as a per-table function name, stays an ArgumentError." | Stale after `Naming`. Update it. |
| 219-222 | `TriggerMigration.rerun?(Naming.trigger_name(pair), scan.sources)` | `TriggerMigration.rerun?(pair, scan.sources)` (D-08), plus a D-06 advisory from the same parse. |
| 290-356 | `migration_content/3` | New order: function ups → trigger ups → guard block(s) → retire block(s). Down: trigger drops → D-01 blocks for new functions. Retire-set rules in Pitfall 2. Split it into helpers to stay under the 120-line function limit. |
| 307-314 | per-table trigger emission, and default-mode `create_trigger(t) <> orphan_function_drop(t)` **interleaved** | Stop interleaving. All retire blocks go after all triggers (Pitfall 2). |
| 326-331 | `function_downs` via `TriggerSQL.drop_function_for_table(t)` (the CASCADE text) | The D-01 block for `Naming.function_name(t)`. |
| 358-364 | `orphan_function_drop/1` using `per_table_function_fits?` | Delete. |
| 366-381 | `rerun_rollback_comment/1` | Extend per D-07. Keep the three `@generated_down_phrases` strings (see below). |

### `lib/threadline/mix/trigger_migration.ex` [VERIFIED: lines 85-95]
`@max_identifier_bytes 63` and `def rerun?(trigger_name, sources)` (name + boundary regex). Replace with the D-08 parser. Recommended split: a public-in-module `parse_triggers(sources) :: [%{trigger: String.t(), schema: String.t() | nil, table: String.t()}]` (with `nil` schema for an unqualified `ON`), and `rerun?/2` built on it. D-06 then reuses `parse_triggers/1`, treating a `nil` schema as `public` for the legacy-name comparison.

### Other `lib/` consumers: no change needed
- `lib/threadline/policy/redaction_presenter.ex:213` checks only the prefix, `defp validate_function_name("threadline_capture_changes" <> _), do: :ok`, and reads `pg_trigger ⋈ pg_proc` by `tgfoid` (lines 77-94). Hashed names pass [VERIFIED: read this session].
- No other `lib/` file builds `threadline_capture_changes_<x>`. A grep shows only doc mentions in `audit_change.ex:34`, `install.ex:33` and `threadline.ex:70`, which name the global function or speak generically.

### Tests that assert old behaviour and will break (must be updated in the same plan as the change)
| File | Lines | What breaks |
|------|-------|-------------|
| `test/threadline/capture/trigger_sql_storage_schema_test.exs` | 38-55 | Expects `"threadline"."threadline_capture_changes_support_tickets"` (now `…_support_tickets_0a670b783726`), and calls `drop_orphan_function_for_table`. |
| `test/threadline/capture/trigger_rerun_test.exs` | 81-111 | Calls `drop_orphan_function_for_table` (deleted). "The orphan drop refuses to cascade" becomes a DO-block keeps-and-warns test. |
| same | 196-227 | "leaves the per-table function alone": both tables move to the global function, the shared name has no users, so it **is now dropped** (count 0). "refused before writing" (`assert_raise ArgumentError, ~r/at most 63 bytes/`) must flip to "generates hashed functions". This is the natural red-first NAME-02 long-pair test. |
| same | 231-243 | `install_legacy_per_table_trigger!` runs `CREATE FUNCTION … threadline_capture_changes_customer_subscription_billing_events_2025()` (67 bytes). This is **one of the two 42622 hits in today's suite** and will trip the NoticeGuard. Either create it with the pre-cut 63-byte name (what PG stored), or drain it with `NoticeGuard.take/0` and assert the expected hit. |
| `test/mix/tasks/threadline/gen_triggers_test.exs` | 458-504 | Asserts `sqls == [create_trigger("posts"), drop_orphan_function_for_table("posts")]` and the literal `DROP FUNCTION IF EXISTS "public"."threadline_capture_changes_posts"()`. |
| same | 507-527 | Asserts `down == [drop_trigger, TriggerSQL.drop_function_for_table("test_redaction_users")]`. That becomes a DO block. |
| `test/threadline/mix/trigger_migration_test.exs` | 156-210 | Every `rerun?/2` test uses the trigger-name signature. |
| `test/threadline/operator_surface/policy_show_mix_test.exs` | 40-43, 62-64, 102-105, 240-244 | Cleans up with `drop_trigger` then `drop_function_for_table`. That still works without CASCADE because the trigger is dropped first. `support.tickets` switches to the hashed name through TriggerSQL on both sides, so it stays consistent. |
| `trigger_redaction_test.exs`, `trigger_changed_from_test.exs` | setup/on_exit | Same drop-trigger-first order. Safe. |

The doc-contract phrases shared with guides must survive the D-07 comment rewrite [VERIFIED: test/mix/tasks/threadline/gen_triggers_test.exs:20-30]: `@rerun_doc_phrases ["replaces the trigger in place", "does not restore the earlier capture policy", "unredacted", "mix threadline.policy.show"]` and `@generated_down_phrases ["does not restore the earlier capture policy", "unredacted", "mix threadline.policy.show"]`. The test also checks `guides/production-checklist.md` and `guides/domain-reference.md`, which need no change unless the moduledoc wording they mirror changes.

`code_walkthrough_doc_contract_test.exs` anchors only `"StorageSchema.threadline_table?"` in gen.triggers [VERIFIED: :12-14]. The walkthrough excerpt of `needs_per_table = …` (guides/code-walkthrough.md:69-71) is not an anchor, but keep that line textually unchanged anyway.

## Historical SQL (for byte-faithful fixtures)

Recovered with `git show <tag>:<path>`. Tags: `v0.9.0` = 7378b75a, `v0.10.0` = 3d148435, `v0.10.2` = ee137e51. `v0.10.0` and `v0.10.1` have **no** diff in `trigger_sql.ex`, `gen.triggers.ex` or `storage_schema.ex` (`git diff v0.10.0 v0.10.1 --stat` printed nothing) [VERIFIED: git this session].

**v0.9.0** (`trigger_sql.ex:132-156`): no storage schema, nothing quoted, nothing validated:
```elixir
# create_trigger_sql/2
CREATE TRIGGER threadline_audit_#{table_name}
AFTER INSERT OR UPDATE OR DELETE ON #{table_name}
FOR EACH ROW EXECUTE FUNCTION #{function_invocation}
# default invocation: "threadline_capture_changes()"; per-table: "threadline_capture_changes_#{table_name}()"
# drop_trigger: "DROP TRIGGER IF EXISTS threadline_audit_#{table_name} ON #{table_name}"
# drop_function_for_table: "DROP FUNCTION IF EXISTS #{name}() CASCADE"
```
The in-repo fixture `priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs` is exactly this form: `execute "CREATE TRIGGER threadline_audit_posts\nAFTER INSERT OR UPDATE OR DELETE ON posts\nFOR EACH ROW EXECUTE FUNCTION threadline_capture_changes()\n"` [VERIFIED: read this session]. v0.9.0 `migration_content/1` emits function ups, trigger ups, then a down of all trigger drops followed by `drop_function_for_table` (CASCADE) for per-table tables. It has no rerun logic.

**v0.10.0 / v0.10.1** (`trigger_sql.ex:103-137`):
```elixir
trigger_name = "threadline_audit_#{StorageSchema.host_table_suffix(table_name)}"
host_table = StorageSchema.qualified_host_table(table_name)
"""
CREATE TRIGGER #{StorageSchema.quote_ident(trigger_name)}
AFTER INSERT OR UPDATE OR DELETE ON #{host_table}
FOR EACH ROW EXECUTE FUNCTION #{function_invocation}
"""
# per-table fn: StorageSchema.function("threadline_capture_changes_#{host_table_suffix(t)}", opts)  -> "\"<storage>\".\"threadline_capture_changes_<suffix>\""
# drop_function_for_table: "DROP FUNCTION IF EXISTS #{name}() CASCADE"
```
`quote_ident` already validated at most 63 bytes in 0.10.0 [VERIFIED: `git show v0.10.0:lib/threadline/storage_schema.ex:57`, quote: `if Regex.match?(@identifier, value) and byte_size(value) <= @max_identifier_bytes do`]. **Consequence:** a 0.10.x install cannot contain a >63-byte trigger or function name. The long-shared-prefix collision therefore exists only in **0.9-era** installs, where PG truncated the name. In 0.10.x the only function collision is the `public.a_b` vs `a.b` suffix collision (`billing_invoices`). Choose fixture forms to match: long-pair fixtures in 0.9 form, schema-pair fixtures in 0.10 form.

**v0.10.2** (`trigger_sql.ex:126-163`, `gen.triggers.ex` `migration_content/3`): the same as 0.10.0 but with `CREATE OR REPLACE TRIGGER`. The default-mode up gets `orphan_function_drop` (`DROP FUNCTION IF EXISTS "<storage>"."threadline_capture_changes_<suffix>"()`, skipped when it does not fit). Rerun tables are left out of `down` and get `rerun_rollback_comment`. The per-table down is still `… CASCADE`.

Rendered as the migration file writes it (`execute #{inspect(sql)}`), a 0.10.2 default-mode `up` for `public.posts` under storage `public` is:
```elixir
    execute "CREATE OR REPLACE TRIGGER \"threadline_audit_posts\"\nAFTER INSERT OR UPDATE OR DELETE ON \"public\".\"posts\"\nFOR EACH ROW EXECUTE FUNCTION \"public\".\"threadline_capture_changes\"()\n"

    execute "DROP FUNCTION IF EXISTS \"public\".\"threadline_capture_changes_posts\"()"
```
This was derived from the recovered templates. The trailing `\n` comes from the heredoc.

**Fixture placement recommendation** (discretion):
- `test/support/legacy_trigger_sql.ex`, e.g. `Threadline.Test.LegacyTriggerSQL`. Put the three historical renderers in it as **copied** template code, not calls into current `TriggerSQL`, parameterized by `{schema, table, storage_schema}`. Its moduledoc cites the release tags. Then a change to current code can never silently change a fixture.
- `test/fixtures/legacy_trigger_migrations/` for literal `.exs` migration texts used by the `rerun?` unit tests and the `mix threadline.gen.triggers` scan tests. `.exs` files under `test/fixtures` that are **not** named `*_test.exs` are never loaded by `mix test`. Mix loads `*_test.exs` under `test/` by default [VERIFIED: Elixir 1.17.3 `mix/tasks/test.ex:596`, quote: `test_pattern = project[:test_pattern] || "*_test.exs"`].
- **Storage schema in real-PG fixtures:** the test DB's storage schema is `"threadline"` [VERIFIED: config/test.exs:50, quote: `config :threadline, storage_schema: "threadline"`], and the audit tables live there. The stale-DB tripwire in `test_helper.exs` fails the suite if `public.audit_*` exists. So:
  - Render 0.10.x fixtures with `storage_schema = "threadline"`. That is faithful: 0.10 wrote whatever schema was configured.
  - 0.9 per-table functions are unqualified and resolve through `search_path`, and their bodies write to unqualified `audit_changes`. They cannot be byte-faithful capture bodies here. Keep the 0.9 **trigger** statement byte-faithful, and create the 0.9 function as a stub or with the current body under the legacy name in the storage schema. Existing tests already do this: `trigger_rerun_test.exs:231-243`.

## Architecture Patterns

### System Architecture Diagram

```
 mix threadline.gen.triggers --tables A,B
        │
        ▼
 parse --tables ──► Naming.pair/1 ──► per table: trigger_name, function_name, legacy_function_name
        │
        ▼
 TriggerMigration.scan(path) ──► parse_triggers(sources) [ON-clause regex, CREATE only]
        │                               │
        │                ┌──────────────┴───────────────┐
        │                ▼                              ▼
        │        rerun?(pair) per table        advisory (D-06): covered table outside
        │        (drives down + comment)       --tables with same legacy_function_name
        │                                        ──► Mix.shell().error warning
        ▼
 migration_content:
   up:   [CREATE OR REPLACE FUNCTION f(A) …]  (per-table tables)
         [CREATE OR REPLACE TRIGGER …ON A → f(A)|global]   (all tables)
         [GUARD DO: for each f written, any tgfoid user ≠ owner? → RAISE EXCEPTION + HINT]
         [RETIRE DO (D-01) for each old name ∉ names-now-in-use] (deduped)
   down: [DROP TRIGGER IF EXISTS … ON A]  (first-run tables only)
         [D-01 DO for f(A)]               (first-run per-table tables only)
         [# comment: rerun tables keep capture; retired <old>; not recreated]
        │
        ▼
 host runs mix ecto.migrate ── one DDL transaction per migration ──►
   guard raises ⇒ whole migration rolls back (nothing applied)
   retire keeps a shared fn ⇒ WARNING logged by ecto_sql at :warn
```

### Recommended Project Structure (changes only)
```
lib/threadline/capture/trigger_sql.ex        # names via Naming; DO-block builders (or a sibling module if >800 lines)
lib/threadline/mix/trigger_migration.ex      # parse_triggers/1 + rerun?/2 (pair)
lib/mix/tasks/threadline.gen.triggers.ex     # assembly: order, retire set, guard, advisory, comment
test/support/notice_guard.ex                 # Threadline.Test.NoticeGuard
test/support/legacy_trigger_sql.ex           # frozen 0.9 / 0.10.0 / 0.10.2 renderers
test/support/notice_guard_canary.exs         # canary run only by an explicit path (see Pattern 5)
test/fixtures/legacy_trigger_migrations/*.exs  # literal historical migration texts (not *_test.exs)
test/threadline/capture/notice_guard_test.exs          # positive/negative controls + canary contract
test/threadline/capture/collision_free_emission_test.exs  # real-PG SC1/SC2/SC3 via Ecto.Migrator
```

### Pattern 1: Run a generated migration the way an adopter does
**What:** Generate into a tmp dir, compile the file, run `Ecto.Migrator.up/4`, then `down/4`.
**Why this path, not the existing `apply_up!/1`:** `trigger_rerun_test.exs` parses `execute` strings and runs each with `Repo.query!` [VERIFIED: trigger_rerun_test.exs:281-298]. That gives no transaction, so a D-05 raise halfway through leaves partial DDL. It also never passes through ecto_sql's DDL-log path, so the D-01 WARNING never reaches Logger. `Ecto.Migrator` wraps the migration in one DDL transaction and runs it in a `Task.async` [VERIFIED: deps/ecto_sql/lib/ecto/migrator.ex:341-343, quote: `|> Task.async()` / `|> Task.await(:infinity)`]. It then logs every returned message at its mapped level [VERIFIED: deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:1424-1452, quote: `defp ddl_log_level("WARNING"), do: :warn`, `defp ddl_log_level("NOTICE"), do: :info`]. It logs only when the migration's `log` option is not `false` [VERIFIED: deps/ecto_sql/lib/ecto/migration/runner.ex:347-360, quote: `defp ddl_log(_level, false, _msg, _metadata), do: :ok`].
**Example:**
```elixir
# Sketch — names/paths are illustrative [ASSUMED shape; APIs verified above]
[{module, _}] = Code.compile_file(file)
version = file |> Path.basename() |> Integer.parse() |> elem(0)

log =
  ExUnit.CaptureLog.capture_log([level: :warning], fn ->
    assert :ok = Ecto.Migrator.up(Repo, version, module)
  end)

assert log =~ "threadline: kept"            # D-01 WARNING reached Logger

on_exit(fn ->
  Repo.query!("DELETE FROM schema_migrations WHERE version = $1", [version])
  :code.purge(module); :code.delete(module)   # avoid "redefining module" across tests
end)
```
- Module names repeat across tests (`ThreadlineTriggersBillingInvoices`), so purge them in `on_exit`.
- A failing `up` raises the `Postgrex.Error`. Its message includes `hint:` [VERIFIED: deps/postgrex/lib/postgrex/error.ex:6,45-51, quote: `@metadata [:table, :column, :constraint, :hint]`], so `assert_raise Postgrex.Error, ~r/hint: .*--tables/`.
- `Ecto.Migrator.down(Repo, version, module)` exercises the real rollback for SC2 and SC3.
- The test module must be `async: false`: `DataCase` defaults to it, and the repo has `pool_size: 2` [VERIFIED: config/test.exs:11].
- The unit-level shape assertions can keep the existing `executes(file, :up | :down)` parser in `gen_triggers_test.exs:97-114`.

### Pattern 2: Retire-set computation (the D-04 refinement)
```elixir
# [ASSUMED sketch — helper names at discretion]
in_use = MapSet.new(specs, fn {t, spec} -> if spec.needs_per_table, do: Naming.function_name(t), else: :global end)
retire =
  specs
  |> Enum.flat_map(fn {t, spec} ->
    [Naming.legacy_function_name(t) | if(spec.needs_per_table, do: [], else: [Naming.function_name(t)])]
  end)
  |> Enum.uniq()
  |> Enum.reject(&MapSet.member?(in_use, &1))
```
- Emit the retire blocks **after** all trigger statements and after the guard.
- Validate every name at most 63 bytes before emitting (D-01). `legacy_function_name` is already cut to 63.
- The global name `threadline_capture_changes` can never be in the retire set, because every candidate has the `_` suffix.

### Pattern 3: Post-condition guard (D-05). Verified on PG 14.17 this session
```sql
DO $$
DECLARE
  fn     regprocedure := to_regprocedure('"threadline"."threadline_capture_changes_billing_invoices"()');
  owner  regclass     := to_regclass('"public"."billing_invoices"');
  others text;
BEGIN
  SELECT string_agg(format('%I.%I', n.nspname, c.relname), ', ' ORDER BY n.nspname, c.relname) INTO others
    FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE t.tgfoid = fn AND t.tgrelid <> owner;
  IF others IS NOT NULL THEN
    RAISE EXCEPTION 'threadline: … triggers on % also use it and may now apply another table''s redaction rules', others
      USING HINT = 'mix threadline.gen.triggers --tables billing_invoices,billing.invoices';
  END IF;
END $$;
```
On PG 14.17 this raised `ERROR: … HINT: regenerate those tables in the same command: mix threadline.gen.triggers --tables billing_invoices,billing.invoices`. After `ROLLBACK` both triggers still pointed at the original function [VERIFIED: local psql run]. Two notes:
- The `regclass`/`regprocedure` text output drops `public.` when `public` is on `search_path`. Build the names in messages with `format('%I.%I', …)` or with generator-emitted literals, never `owner::text`.
- Build the HINT's `--tables` list from the **offending** tables, rendered as the adopter would type them (bare for `public`, `schema.table` otherwise), plus the owner. The generator knows the owner but not the other tables, so either compute that list in SQL from `others` or use a generic HINT that names the command form. This is at Claude's discretion.

### Pattern 4: `rerun?` parser. Prototyped this session against all three historical forms
Running the D-08 regex (Elixir, `Regex.compile!(…, "i")`) over normalized sources gave:
```
0.9    CREATE TRIGGER threadline_audit_posts … ON posts              -> ["threadline_audit_posts", "posts"]
0.10.0 CREATE TRIGGER "threadline_audit_billing_invoices" … ON "billing"."invoices" -> [trigger, "billing", "invoices"]
0.10.2 CREATE OR REPLACE TRIGGER "threadline_audit_Users" … ON "public"."Users"    -> [trigger, "public", "Users"]
lower  create trigger threadline_audit_Posts … on Posts               -> ["threadline_audit_posts", "posts"]  (unquoted → lowercased)
DROP TRIGGER IF EXISTS threadline_audit_posts ON posts               -> no match (DROP ignored)
```
[VERIFIED: /tmp prototype run with elixir 1.17.3]. `Regex.scan(..., capture: :all_but_first)` returns two captures for an unqualified `ON` and three for a qualified one. Branch on the length.

### Pattern 5: NoticeGuard and its canary. Feasibility confirmed
- **Event:** `Threadline.Test.Repo` is `use Ecto.Repo, otp_app: :threadline` with no `telemetry_prefix` [VERIFIED: test/support/repo.ex; grep shows no `telemetry_prefix` in config/test]. Ecto derives `[:threadline, :test, :repo]` + `:query` [CITED: Ecto.Repo docs, default telemetry prefix is the underscored module name]. ecto_sql emits the event **before** checking `log:`, so `log: false` queries are still seen [VERIFIED: deps/ecto_sql/lib/ecto/adapters/sql.ex:1314-1316, quote: `if event_name = Keyword.get(opts, :telemetry_event, event_name) do :telemetry.execute(event_name, measurements, metadata)`]. Migration DDL goes through `Ecto.Adapters.SQL.execute_ddl` → `query!` [VERIFIED: sql.ex:1237-1246], so it is covered too.
- **Message shape:** a temporary handler matching `%Postgrex.Result{messages: msgs}` with `%{code: "42622"}` caught real hits [VERIFIED: full-suite probe; the helper was restored and `git status` is clean].
- **Today's baseline:** `mix test` gave `7 properties, 1924 tests, 0 failures, 1 excluded` in 145.6 s. It produced **exactly 2** 42622 hits, both `CREATE FUNCTION "threadline".threadline_capture_changes_customer_subscription_billing_events_2025()` from `trigger_rerun_test.exs` (two tests call `install_legacy_per_table_trigger!`) [VERIFIED: probe output]. `SHOW client_min_messages` = `notice` [VERIFIED: probe + psql].
- **Keying:** D-09 keys by `self()`. `Ecto.Migrator` runs migrations in `Task.async`, so hits from a migration test land under the Task's pid, and the test's `take/0` cannot drain them. **Recommend keying by `List.last(Process.get(:"$callers", [])) || self()`.** `Task.async` sets `$callers`, so hits are attributed to the originating test process. This is a discretion-level refinement that keeps D-09's intent. `[ASSUMED]`: that `$callers` propagates through Ecto's Task. Standard Task semantics, not probed.
- **Canary without an exclude tag:** the zero-skips contract forbids a new exclude. Mix accepts an explicit file path regardless of `test_pattern` [VERIFIED: Elixir 1.17.3 `mix/utils.ex:249-257`, quote: `{:ok, :regular} -> [path]`]. So put the canary at a path that is **not** `*_test.exs` and not compiled, for example `test/support/notice_guard_canary.exs`. `test/support/stress_router_prod_compile.exs` sets the precedent for a `.exs` in `test/support` [VERIFIED: test_structure_contract_test.exs:41-43]. The contract test runs `System.cmd("mix", ["test", "test/support/notice_guard_canary.exs"], env: [{"MIX_ENV","test"}, {"THREADLINE_TRUNCATION_GUARD_CANARY","1"}], stderr_to_stdout: true)` and asserts a non-zero exit and that the output names `42622` or the identifier. It copies `verify_coverage_task_test.exs:14-54` (`cmd_env/1` merging `System.get_env()`). The canary body can also require the env flag, so it is harmless if run by hand.
- **`at_exit` inside `ci.all`:** `ci.all` runs several aliases in one VM [VERIFIED: mix.exs:190-197]. A guard failure registered with `System.at_exit` makes the **VM exit** non-zero, but only after the remaining `ci.all` steps run. `verify!` prints the hits right away, so the failure is still visible. Note this in the plan. `mix verify.test` on its own exits non-zero immediately at VM end.
- **Coverage limits** (document in the moduledoc): the guard sees only queries through `Threadline.Test.Repo`. It does not see raw `Postgrex.start_link` sessions (`async_helpers.ex` advisory locks), nested `mix` processes, or the example app's repo.

### Anti-Patterns to Avoid
- **Interleaving retire drops after each trigger.** Retire only after all triggers are re-pointed (Pitfall 2).
- **Asserting on `regprocedure::text` in tests.** It depends on `search_path`. The test storage schema `threadline` is not on the path, so it renders qualified, while `public` renders bare. Match on the bare function name.
- **Compiling or evaluating host migrations in `rerun?`.** Keep it text-only (existing moduledoc contract, `trigger_migration.ex:9-13`).
- **A Logger-based NOTICE guard** (D-09 facts; config `level: :warning` [VERIFIED: config/test.exs:85]).
- **Using `take/0` to hide a real product truncation.** Drain only in tests that deliberately reproduce pre-0.10 truncation, and assert the exact hit.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Running a generated migration transactionally in tests | `Repo.transaction` + `Enum.each(&Repo.query!/1)` | `Ecto.Migrator.up/4` / `down/4` | It is the adopter's real path: DDL transaction, WARNING logging, `schema_migrations`. |
| Identifier quoting in DO bodies | Elixir string interpolation of names into `EXECUTE` | `format('%I.%I')`, and `format('DROP FUNCTION %s', fn)` with a `regprocedure` | `regprocedure` output is already safely quoted. |
| Function existence and overload resolution | `pg_proc` name lookup by `proname` | `to_regprocedure('"s"."n"()')` | Resolves the exact zero-arg signature and returns NULL instead of raising. |
| Name derivation | New string concatenation in `TriggerSQL` | `Naming.function_name/1`, `legacy_function_name/1`, `trigger_name/1` | 208 froze these. Duplicates were a 208 review finding. |
| Shell capture in Mix task tests | Custom IO capture | `Mix.shell(Mix.Shell.Process)` + `receive {:mix_shell, :error, [msg]}` | Existing pattern (`gen_triggers_test.exs:33-70`). Note that `drain_shell/1` there only collects `:info`, so the D-06 advisory test must collect `:error`. |

## Runtime State Inventory

This is a behaviour change to generated SQL, not a rename. It is recorded because the SQL is frozen into adopter databases:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Adopter DBs hold per-table functions under 0.10.x names, and 0.9-era truncated names. The test DB holds whatever earlier test runs left behind (tests clean up in `on_exit`). | No data migration in 209. The retire DO blocks handle old functions at migrate time. |
| Live service config | None. Verified: capture config lives in `config :threadline, :trigger_capture` (code), not in a service. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | New test-only env flag `THREADLINE_TRUNCATION_GUARD_CANARY` (name at discretion). | Add it to `config/test.exs` only if needed. The canary can read `System.get_env` directly. |
| Build artifacts | Frozen fixtures in `priv/ci/hex_evaluator/.../20260424080642_threadline_triggers_posts.exs` and `examples/threadline_phoenix/priv/repo/migrations/*threadline_triggers*.exs` (pre-0.10 form) | Leave them (deferred to 212). The hex_evaluator fixture is read by `gen_triggers_test.exs:233-247` and must still be detected as a rerun under the new `rerun?` (unqualified `ON posts` → matches `public.posts`). |

## Common Pitfalls

### Pitfall 1: The combined-run assertion in CONTEXT `<specifics>` cannot hold
**What goes wrong:** The test asserts that `to_regprocedure(legacy)` is NULL after `--tables billing_invoices,billing.invoices`, and fails.
**Why:** `Naming.function_name("public.billing_invoices") == "threadline_capture_changes_billing_invoices"` [VERIFIED: naming_test.exs:18], which is the legacy shared name. Public keeps it, and its body is rewritten with public's rules.
**How to avoid:** Assert instead:
- each table's `tgfoid` is its own `Naming.function_name`;
- no capture function has more than one trigger user;
- inserts into each table apply only that table's mask;
- `pg_get_functiondef` of the legacy-named function contains public's masked column and not billing's.

### Pitfall 2: The retire set and its placement
**What goes wrong:** (a) A combined migration prints a spurious "kept … because public.billing_invoices still uses it" WARNING. (b) Two default-mode tables on a 0.9 shared truncated function each get an interleaved drop. The first drop sees the second table as a user, so the orphan is never dropped.
**How to avoid:** Place all retire blocks after all triggers and dedupe them. Exclude any name that a trigger in this migration now uses. Test both cases.
**Warning signs:** A WARNING in a combined-run test, or `shared_function_count == 1` after both tables moved to the global function.

### Pitfall 3: D-01 `ORDER BY 1` is a no-op inside `string_agg`
**Evidence:** PG 14.17: `ORDER BY 1` gave `public.billing_invoices, billing.invoices, zz.aa`, and `ORDER BY n.nspname, c.relname` gave `billing.invoices, public.billing_invoices, zz.aa` [VERIFIED: local psql].
**How to avoid:** Emit `ORDER BY n.nspname, c.relname` (or `ORDER BY 1`'s intended key written out). This is a correction within the D-01 shape. Flag it to the maintainer only if the shape text itself is treated as frozen. It has not shipped yet, so it is free to fix now.

### Pitfall 4: Deliberate truncation in existing tests will trip the new guard
Today's suite produces two 42622 hits (Pattern 5). The NoticeGuard plan must fix `trigger_rerun_test.exs:231-243` in the same commit, or the suite goes red when the guard lands. Byte-faithful 0.9 fixtures with uncut long names (SC1 long pair, SC2 0.9 form) produce 42622 **by design**. Drain them with `NoticeGuard.take/0` and assert the expected identifiers. That needs `$callers` keying if the fixture runs through `Ecto.Migrator`. Alternatively run fixtures with `Repo.query!` from the test process.

### Pitfall 5: `inspect/1` escaping of DO blocks inside `execute "…"`
`inspect/1` escapes `"` as `\"` and newlines as `\n`. It leaves `$` alone. It escapes `#{` as `\#{`, but the DO bodies contain no `#{`. The generated `.exs` therefore round-trips through `Code.string_to_quoted!` (used by the `executes/2` test helper). Three follow-ons:
- `rerun?` normalization (`\"` → `"`) will also see the DO text. The DO blocks contain `DROP FUNCTION` but no `CREATE … TRIGGER`, so they cannot produce a false match. Add a regression test in which the D-01 and guard blocks are present in a scanned source.
- Keep `'` doubled inside RAISE format strings (`another table''s`).
- Do not use `$$` inside function bodies. They use `$threadline_trigger$` [VERIFIED: trigger_sql.ex heredocs], so nesting is safe.

### Pitfall 6: `to_regprocedure` and overlong literals
`to_regprocedure` truncates silently: on PG 14.17 a 70-byte name returned NULL and printed **no** NOTICE [VERIFIED: local psql]. The guard would therefore not catch it. The generator must call `StorageSchema.validate_identifier!(name, :derived)` on every name placed in a literal (D-01). D-11's static test asserts that every `"…"` identifier in the generated SQL is at most 63 bytes.

### Pitfall 7: 0.9-era fixtures versus the test storage schema
See "Historical SQL". Unqualified 0.9 function references resolve to `public`, while D-01 looks in `"threadline"`. A 0.9-form fixture must create its legacy function **in the storage schema** for retire and guard to see it, which matches the default `public` storage of real 0.9 installs. Otherwise the test silently proves nothing.

### Pitfall 8: Worktree dispatch cannot run Elixir tests
The config has `workflow.use_worktrees: true` [VERIFIED: .planning/config.json]. Memory says worktrees lack `deps/` and `_build`, and a stale `.gsd/dispatch-isolation-sentinel.json` blocks sequential dispatch. Every plan here needs real PG and the full suite, so dispatch sequentially in the main checkout and re-record the sentinel as `none`. The dispatch prompt must forbid moving protected files or bypassing hooks (memory: executor precondition workarounds).

### Pitfall 9: The canary spawns a nested `mix test`
It costs the full `test_helper` boot, about 5-10 s [ASSUMED]. It runs under `MIX_ENV=test` in the same checkout. The existing `verify_coverage_task_test.exs` does the same, so the pattern is proven here. Keep the contract test `async: false`.

## Code Examples

### D-01 block (with the ORDER BY fix). Re-run on PG 14.17 this session
```sql
-- threadline: drop this capture function only if no trigger still uses it
DO $$
DECLARE
  fn    regprocedure := to_regprocedure('"threadline"."threadline_capture_changes_billing_invoices"()');
  users text;
BEGIN
  IF fn IS NULL THEN RETURN; END IF;
  SELECT string_agg(format('%I.%I', n.nspname, c.relname), ', ' ORDER BY n.nspname, c.relname) INTO users
    FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE t.tgfoid = fn;
  IF users IS NULL THEN
    EXECUTE format('DROP FUNCTION %s', fn);
  ELSE
    RAISE WARNING 'threadline: kept % because triggers on % still use it; regenerate triggers for those tables', fn, users;
  END IF;
END $$;
```
Observed: `WARNING:  threadline: kept threadline_capture_changes_billing_invoices() because triggers on public.billing_invoices, billing.invoices, zz.aa still use it` (with `ORDER BY 1`, hence unsorted) [VERIFIED: local psql, function in `public`].

### NoticeGuard skeleton
```elixir
# test/support/notice_guard.ex — [ASSUMED sketch; event/shape verified in Pattern 5]
defmodule Threadline.Test.NoticeGuard do
  @moduledoc false
  @table :threadline_notice_guard
  @handler "threadline-notice-guard"
  @event [:threadline, :test, :repo, :query]

  def attach! do
    :ets.new(@table, [:public, :named_table, :duplicate_bag])
    :ok = :telemetry.attach(@handler, @event, &__MODULE__.handle/4, nil)
  end

  def handle(_event, _measure, meta, _cfg) do
    with {:ok, %Postgrex.Result{messages: msgs}} when is_list(msgs) <- meta.result do
      for %{code: "42622"} = m <- msgs, do: :ets.insert(@table, {owner(), m, meta.query})
    end
  rescue
    _ -> :ok
  end

  defp owner, do: List.last(Process.get(:"$callers", [])) || self()

  def take(pid \\ self()), do: :ets.take(@table, pid) |> Enum.map(fn {_, m, q} -> {m, q} end)

  def verify!(_result) do
    hits = :ets.tab2list(@table)
    attached? = Enum.any?(:telemetry.list_handlers(@event), &(&1.id == @handler))
    # print hits; if hits != [] or not attached?, System.at_exit(fn _ -> exit({:shutdown, 1}) end)
  end
end
```
`test_helper.exs` order: after `repo.start_link()`, call `NoticeGuard.attach!()`, then assert `SHOW client_min_messages` = `notice`, then `ExUnit.after_suite(&NoticeGuard.verify!/1)`, then `Ecto.Migrator.run` [VERIFIED: current order `ExUnit.start()` line 1, `Ecto.Migrator.run` line 38]. `after_suite` must be registered after `ExUnit.start()`. The guard must also be skipped or adjusted under `THREADLINE_PGBOUNCER_TOPOLOGY=1`, where the helper skips migrations and the topology lane may differ. Check that path.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `threadline_capture_changes_<suffix>` for every per-table table | `Naming.function_name`: legacy for public tables of at most 36 bytes, hashed otherwise | 208 froze the format; 209 emits it | Non-public and long tables get their own functions |
| `DROP FUNCTION … CASCADE` in down; RESTRICT orphan drop skipped over 63 bytes | D-01 DO block; no CASCADE anywhere | 209 | A rollback can never remove another table's trigger |
| `rerun?(trigger_name, sources)` by name prefix | `rerun?(pair, sources)` by `ON` clause | 209 | Fixes the 46-byte prefix and `a_b` vs `a.b` false positives |

**Superseded research note:** ARCHITECTURE.md line 203 ("For names over 63 bytes, `DROP TRIGGER IF EXISTS <legacy truncated name>`") is **not needed**. 208 made `Naming.trigger_name` equal the PG-stored name (the legacy name cut to 63), so `CREATE OR REPLACE TRIGGER` replaces it in place. The only exception is the deferred `search_path` case.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `$callers` propagates into ecto_sql's `Task.async` migration process, so `$callers` keying attributes hits to the test pid | Pattern 5 | Low. If not, drain fixture hits by running the fixture SQL with `Repo.query!` in the test process. |
| A2 | Ecto's default telemetry prefix for `Threadline.Test.Repo` is `[:threadline, :test, :repo]` | Pattern 5 | Low. The full-suite probe attached to exactly this event and received hits, which is empirical confirmation. |
| A3 | The nested canary `mix test` takes about 5-10 s | Pitfall 9 | Cost only. |
| A4 | PG 16 behaves like PG 14.17 for `to_regprocedure`, `DO`, and `RAISE … USING HINT` | Patterns 3/5 | Low. The CI matrix runs both. Only 14.17 was available locally (Docker could run `postgres:16` if needed). |
| A5 | `System.at_exit` + `exit({:shutdown, 1})` from an `after_suite` callback yields a non-zero `mix test` exit | Pattern 5 | Medium. D-10's canary contract test proves or disproves it automatically, so it is self-verifying. |

## Open Questions (RESOLVED)

1. **HINT content for the guard.** The generator knows the owner table, but only the DB knows the other users. Recommendation: compute the offending `--tables` list inside the DO block from `others`, rendering public tables bare, and join it with the owner. The HINT is then copy-pasteable. The wording is at discretion.
   - **RESOLVED (as recommended):** plan 04 Task 1. `function_owner_guard/2` computes `retables` inside the DO block (bare `relname` for public, `schema.table` otherwise, sorted by schema then table) and the HINT gives `mix threadline.gen.triggers --tables <owner token>,<retables>`, plus the alternative of regenerating those tables first.
2. **Guard under `THREADLINE_PGBOUNCER_TOPOLOGY=1`.** `test_helper` skips migrations there. Decide whether the guard attaches in that lane. Recommendation: attach it, and skip only the `client_min_messages` assertion if PgBouncer changes it. Verify the lane with `mix verify.topology` if it is run locally.
   - **RESOLVED (as recommended):** plan 01. `NoticeGuard.attach!/0` and the `after_suite` check run in both lanes. Only the `SHOW client_min_messages` boot assertion is skipped under `THREADLINE_PGBOUNCER_TOPOLOGY=1`. The ExUnit exclude list stays `[pgbouncer_topology: true]`.
3. **CHANGELOG.** CONTEXT gives the security note to 213. The moduledoc changes (per-table long names now work, and the migrate-time error) are adopter-visible. Recommendation: keep 209 CHANGELOG-free per CONTEXT, but make sure 213's entry covers the migrate-time error and the WARNING.
   - **RESOLVED (diverges from the recommendation, in part):** 209 edits the CHANGELOG, but only the non-security sentence (plan 05 Task 1). The 208 hand-off left a sentence in `## Unreleased` / `### Changed` saying that tables with redaction rules or `--store-changed-from` are still rejected for long or non-public names. Once plan 03 ships, that sentence is false. Leaving it would put a wrong statement in the next release notes. Plan 05 therefore replaces it with the shipped behavior (hashed per-table names) and adds one sentence: drops happen only when no trigger still uses the function, and never cascade. The security advisory note, the leaked-rows disclosure, and the upgrade-guide text all stay with 213, per CONTEXT "Not in this phase". 213's entry must still cover the migrate-time error and the WARNING.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (local) | All real-PG tests | ✓ | 14.17 (Homebrew) | — |
| PostgreSQL 16 | CI matrix parity | ✗ locally (✓ in CI) | — | Docker `postgres:16` if a local check is wanted |
| Elixir / OTP | build and test | ✓ | 1.17.3 / OTP 27 (`.tool-versions`: erlang 27.3.4.15, elixir 1.17.3-otp-27) | — |
| Docker | optional | ✓ | running | — |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3) + StreamData 1.4.0, real PostgreSQL, no SQL Sandbox (by design, `test/support/data_case.ex`) |
| Config file | `test/test_helper.exs`, `config/test.exs` |
| Quick run command | `mix test test/threadline/capture/ test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs` |
| Full suite command | `mix verify.test` (≈146 s today); phase gate `mix ci.all` |

### Phase Requirements → Test Map
| Req / SC / D | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NAME-02 / SC1 | `public.billing_invoices` and `billing.invoices` get distinct functions; each insert applies only its own mask (per-table mode, generated via task, run via `Ecto.Migrator.up`) | real-PG integration | `mix test test/threadline/capture/collision_free_emission_test.exs` | ❌ Wave 0 |
| NAME-02 / SC1 | Two public tables sharing 36 bytes get distinct hashed functions and own-rules-only masking (flip of `trigger_rerun_test.exs:216-227`) | real-PG | `mix test test/threadline/capture/trigger_rerun_test.exs` | ✅ (update) |
| D-05 | Regenerating only the legacy-keeping table raises with HINT; `pg_get_functiondef(legacy)` and both `tgfoid` unchanged; nothing applied | real-PG via Migrator | `mix test test/threadline/capture/collision_free_emission_test.exs` | ❌ Wave 0 |
| D-05 / D-01 | Moved table first: passes, WARNING logged (captured at `:warning`), legacy fn kept for public | real-PG via Migrator + `capture_log` | same | ❌ Wave 0 |
| D-04 (Pitfall 1/2) | Combined run: one trigger user per function, no spurious WARNING, bodies carry own rules | real-PG | same | ❌ Wave 0 |
| NAME-03 / SC2 | For each historical form (0.9 unquoted, 0.10.0 quoted CREATE, 0.10.2 CREATE OR REPLACE): regenerate → exactly 1 `threadline_audit_%` row per table in `pg_trigger`, name byte-identical; `down` leaves 1 enabled (`tgenabled = 'O'`) | real-PG | same (or `trigger_rerun_test.exs`) | ❌ Wave 0 |
| NAME-03 / D-08 | `rerun?` unit cases: 46-byte shared prefix, `public.a_b` vs `a.b`, unquoted `ON Posts`, DROP ignored, DO-block text ignored, three historical fixtures, round-trip with current `TriggerSQL.create_trigger` | unit (async) | `mix test test/threadline/mix/trigger_migration_test.exs` | ✅ (rewrite) |
| NAME-03 / D-08 | StreamData: `rerun?(p, [gen(p)])` and not `rerun?(q, [gen(p)])` for `q ≠ p` | property (async, bounded) | same | ✅ (add) |
| NAME-03 | hex_evaluator 0.9 fixture still detected as rerun | Mix task | `mix test test/mix/tasks/threadline/gen_triggers_test.exs` | ✅ |
| NAME-04 / SC3 | Rolling back one table's first-run migration leaves every other table's trigger present and enabled; shared function kept with WARNING | real-PG via `Ecto.Migrator.down` | `mix test test/threadline/capture/collision_free_emission_test.exs` | ❌ Wave 0 |
| NAME-04 / SC3 / D-11 | No generated SQL matches `~r/CASCADE/i`; every quoted identifier ≤ 63 bytes (over a matrix: default/per-table × public/non-public × short/long × first-run/rerun) | unit on generated file | `mix test test/mix/tasks/threadline/gen_triggers_test.exs` | ✅ (add) |
| D-06 | Advisory `Mix.shell().error` names the sibling table when an earlier migration covers a same-legacy-name table outside `--tables` | Mix task | same | ✅ (add) |
| D-07 | Rerun down comment names retired `<old>` and `<new>`; shared phrases still present | Mix task | same (`rerun documentation` describe) | ✅ (extend) |
| SC4 / D-09 / D-10 | Positive control: 64-byte alias → exactly one hit via `take/0`; 63-byte → `[]` | unit (async) | `mix test test/threadline/capture/notice_guard_test.exs` | ❌ Wave 0 |
| SC4 / D-10 | Canary: nested `mix test test/support/notice_guard_canary.exs` with env flag exits non-zero | contract (System.cmd) | same | ❌ Wave 0 |
| SC4 / D-10 | `SHOW client_min_messages` = `notice` asserted at boot | boot assertion | `mix verify.test` | ❌ Wave 0 |
| Invariant | No planning vocabulary in changed `lib/` / docs | grep review | `! grep -nE 'Phase [0-9]|NAME-0|\bD-[0-9]{2}\b' lib/threadline/capture/trigger_sql.ex lib/mix/tasks/threadline.gen.triggers.ex lib/threadline/mix/trigger_migration.ex` | n/a |

### Sampling Rate
- **Per task commit:** the quick run command above (≈ a few seconds; the capture/mix dirs ran 168 tests in 0.5 s in 208, while real-PG files add seconds).
- **Per wave merge:** `mix verify.test`.
- **Phase gate:** `mix ci.all` green in the main checkout. The browser lane counts only if run: it has exactly 8 pre-existing screenshot failures, and a 9th is a regression.

### Wave 0 Gaps
- [ ] `test/support/notice_guard.ex`: the guard module, plus the `test/test_helper.exs` attach, `after_suite` and `client_min_messages` assertion.
- [ ] `test/support/notice_guard_canary.exs`: the canary, run only by explicit path.
- [ ] `test/threadline/capture/notice_guard_test.exs`: the controls and the canary contract.
- [ ] Fix `trigger_rerun_test.exs:231-243`'s deliberate 67-byte `CREATE FUNCTION`, **in the same commit** as the guard.
- [ ] `test/support/legacy_trigger_sql.ex` and/or `test/fixtures/legacy_trigger_migrations/`: frozen 0.9 / 0.10.0 / 0.10.2 forms.
- [ ] `test/threadline/capture/collision_free_emission_test.exs`: the real-PG SC1-SC3 harness via `Ecto.Migrator.up/down` (Pattern 1).

## Security Domain

`security_enforcement` is absent from `.planning/config.json`, so it is treated as enabled.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | indirect | Isolation of redaction policy per table (a table must not run another's `mask`/`exclude`). This is the security fix. |
| V5 Input Validation | yes | `StorageSchema.validate_identifier!/2` on every identifier and every derived literal (≤ 63 bytes, `^[A-Za-z_][A-Za-z0-9_]*$`); `format('%I')` in DO blocks |
| V6 Cryptography | no | SHA-256 in `Naming.hash12` is naming only, not a security control |
| V8 Data Protection | yes | Masking/exclusion must apply per table; leaked historic rows are 213's note |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-table function sharing → one table's rows captured under another's (weaker) redaction | Information disclosure | Distinct `Naming.function_name`; D-05 guard aborts a migration that would leave a sibling on a rewritten body |
| `DROP … CASCADE` removing a sibling's trigger → silent capture loss (audit evasion) | Repudiation / Tampering | D-01 RESTRICT drop only when there are no `tgfoid` users; no CASCADE anywhere (D-11 static assertion) |
| Identifier truncation making a literal resolve to another object | Tampering | Generator validates ≤ 63 bytes; NoticeGuard fails the suite on 42622 |
| SQL injection via table names in generated DDL | Tampering | Identifier regex validation before quoting; names never come from runtime input, only the `--tables` CLI and config |

## Sources

### Primary (HIGH confidence)
- Repo source read this session: `lib/threadline/capture/{naming,trigger_sql}.ex`, `lib/threadline/storage_schema.ex`, `lib/threadline/mix/trigger_migration.ex`, `lib/mix/tasks/threadline.gen.triggers.ex`, `lib/threadline/policy/redaction_presenter.ex`, `test/test_helper.exs`, `test/support/{repo,data_case,async_helpers,storage_schema_case}.ex`, the listed test files, `config/test.exs`, `mix.exs`, `.github/workflows/ci.yml`.
- `git show v0.9.0|v0.10.0|v0.10.2:<trigger_sql.ex, gen.triggers.ex, storage_schema.ex>`.
- deps source: `ecto_sql` 3.14.0 (`migrator.ex`, `migration/runner.ex`, `adapters/sql.ex`, `adapters/postgres/connection.ex`), `postgrex` 0.22.4 (`error.ex`, `result.ex`), Elixir 1.17.3 `mix/tasks/test.ex`, `mix/utils.ex`.
- Live experiments: local PG 14.17 (D-01 block, `ORDER BY 1`, guard + HINT + rollback, `to_regprocedure` silent truncation); full-suite 42622 probe (1924 tests, 2 hits); D-08 regex prototype.

### Secondary (MEDIUM confidence)
- Ecto.Repo default telemetry prefix convention (confirmed empirically by the probe).

### Tertiary (LOW confidence)
- None used for decisions.

## Metadata

**Confidence breakdown:**
- Call-site inventory: HIGH. Every file was read, and greps are cross-checked.
- Historical SQL: HIGH, recovered from tags.
- Test infrastructure / NoticeGuard feasibility: HIGH. Proven by a real full-suite probe. `$callers` keying is MEDIUM (A1).
- D-01/D-05 PG behaviour: HIGH on 14.17. PG 16 is assumed and covered by CI.

**Research date:** 2026-09-25
**Valid until:** 2026-10-25 (stable internal code; revalidate if 210 lands first or deps are bumped)
