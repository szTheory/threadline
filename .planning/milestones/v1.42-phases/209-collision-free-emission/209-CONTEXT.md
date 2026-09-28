# Phase 209: Collision-Free Emission - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This is the security fix. After this phase:
- no audited table can run another table's capture function or redaction rules;
- regenerating, dropping or rolling back one table's capture never removes, disables or silently rewrites another table's capture.

Requirements: NAME-02, NAME-03, NAME-04. The success criteria are in `.planning/ROADMAP.md` § Phase 209:
- **SC1:** distinct per-table functions and own-rules-only masking on real PG;
- **SC2:** a 0.10.x regeneration leaves exactly one trigger per table, with names byte-identical;
- **SC3:** no `CASCADE`, and a function is dropped only when no `tgfoid` still references it;
- **SC4:** the suite fails on any identifier-truncation NOTICE, and a positive control proves it.

**Delivers:**
- `TriggerSQL` takes every per-table function name from `Threadline.Capture.Naming`, as frozen in 208 D-03. This ends the interim raise on derived-name overflow noted in 208-VERIFICATION.
- An orphan-safe drop replaces every cascading or unconditional drop.
- The 0.10.x function name is retired when a table's function name changes.
- A migrate-time guard stops one table's migration from moving another table onto its rules.
- `TriggerMigration.rerun?` is rewritten to match on the `ON` clause.
- A suite-level truncation-NOTICE guard.

**Not in this phase:**
- PK-agnostic capture and `TG_ARGV`. That is Phase 210.
- Health or `policy.show` findings. Phase 212 owns them; 209 adds no health code.
- The upgrade guide and the CHANGELOG security note. Phase 213 owns them.

</domain>

<decisions>
## Implementation Decisions

### Orphan-safe function drop (SC3, NAME-04)
- **D-01:** Every generated migration drops a capture function through **one frozen, readable inline `DO` block per function**. The shape:
  ```sql
  -- threadline: drop this capture function only if no trigger still uses it
  DO $$
  DECLARE
    fn    regprocedure := to_regprocedure('"<storage_schema>"."<name>"()');
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

### Retiring 0.10.x function names and sibling exposure (SC1, NAME-02)
- **D-04:** `up` runs in this order for each table, in the migration's single DDL transaction:
  1. `CREATE OR REPLACE FUNCTION <Naming.function_name(pair)>` for tables in per-table mode.
  2. `CREATE OR REPLACE TRIGGER "<Naming.trigger_name>" … ON "schema"."table"`, pointing at the new per-table function or at the global one.
  3. Retire each distinct old name through the D-01 block, only when it differs from what the trigger now uses. The old names are:
     - `Naming.legacy_function_name(pair)`, which is the 0.10.x name cut to 63 bytes;
     - the table's current per-table name, when the table moved to the global function.

  - **Refinement from research (verified on PG 14.17):** the retire list must **leave out every function that any trigger re-pointed in this migration now uses**. Otherwise a correct combined run prints a misleading "kept… still use it" WARNING.
  - **Refinement from research:** all retire blocks run **after every trigger re-point in the migration**, not interleaved per table. Today `gen.triggers.ex` interleaves the orphan drop after each trigger. With two tables on one shared name, the first drop would see the second table and leave an orphan behind.
  - The D-05 guard also runs after every re-point.

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

### Rerun detection (SC2, NAME-03)
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

### Truncation NOTICE guard (SC4)
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
- The NoticeGuard key: research recommends keying hits by the root of `$callers` rather than `self()`, because `Ecto.Migrator` runs migrations in `Task.async`. Either key is acceptable if a test can drain the hits its own migration caused.
- The canary may not be an excluded tag: `zero_skips_contract_test` allows only `pgbouncer_topology`. Run a non-`*_test.exs` file by explicit path in a nested `mix test`.
- The deliberate 67-byte `CREATE FUNCTION` in `test/threadline/capture/trigger_rerun_test.exs` (about lines 231-243) trips the guard today. It must change in the same commit that lands the guard.
- Whether the HINT lists the other tables, computed inside the DO block, or is generic. It must always carry the fix command form.
- Real-PG migration tests should compile each generated migration and run it through `Ecto.Migrator.up/4` and `down/4`. The statement-by-statement `apply_up!` helper runs outside a transaction and cannot prove D-05's atomicity.
- Whether the post-condition guard is one DO block per function or one per migration, provided that it runs after every re-point and names the offending tables.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and requirements
- `.planning/ROADMAP.md` § Phase 209: goal, SC1-SC4, and the cross-cutting invariants (red first, zero human verification, no planning vocabulary in shipped artifacts, no per-row catalog lookup)
- `.planning/REQUIREMENTS.md`: NAME-02, NAME-03, NAME-04

### Prior phase (the frozen format this phase emits)
- `.planning/phases/208-identifier-foundation/208-CONTEXT.md`: D-01 to D-04 (hash, trigger names never hashed, per-table function rule, injectivity) and D-11 (the rerun rewrite handed to 209)
- `.planning/phases/208-identifier-foundation/208-REVIEW.md` and `208-REVIEW-FIX.md`: the 46-byte shared-prefix rerun case, and `TriggerSQL`'s duplicate function-name builder, which must delegate to `Naming`
- `.planning/phases/208-identifier-foundation/208-VERIFICATION.md`: the interim deviation (a per-table function raises `:derived` on overflow) that 209 closes

### Milestone research
- `.planning/research/SUMMARY.md` § Phase 209 and the Reconciled Decisions table
- `.planning/research/ARCHITECTURE.md`: Pattern 4 (orphan-safe cleanup) and Anti-Pattern 3 (`CASCADE`)
- `.planning/research/PITFALLS.md`: Pitfall 1 (function collisions and `CASCADE`) and Pitfall 2 (rename double trigger)

### Project conventions
- `prompts/threadline-elixir-oss-dna.md`: honest default tests and named verification entrypoints
- `.planning/MILESTONE-GUIDE.txt`: quality and release bar

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/threadline/capture/naming.ex`: `function_name/1`, `legacy_function_name/1`, `trigger_name/1`, `pair/1`, `qualified/1`. These are the only sources of names.
- `lib/threadline/storage_schema.ex`: `quote_ident/1`, `qualified_host_table/1`, `function/2` (storage-schema qualification) and `validate_identifier!/2`.
- `lib/threadline/policy/redaction_presenter.ex:88` already joins `pg_trigger.tgfoid` to `pg_proc`. It never derives function names, so the rename needs no change there.

### Established Patterns
- Migrations are frozen literal SQL written via `execute #{inspect(sql)}` in `gen.triggers.ex` `migration_content/3`.
- Rerun tables are left out of `down`, so rollback keeps capture on. `rerun_rollback_comment/1` explains this in the generated file.
- Test env: no SQL Sandbox by design, and `async_helpers`. Telemetry-handler tests are `async: false`.

### Integration Points
- `lib/threadline/capture/trigger_sql.ex`:
  - `per_table_function_name/2` and `per_table_function_base/1` must route through `Naming.function_name/1`;
  - `drop_function_for_table/2` has the `CASCADE`, at about line 97;
  - `drop_orphan_function_for_table/2` and `per_table_function_fits?/1` are to be replaced or deleted.
- `lib/mix/tasks/threadline.gen.triggers.ex`: `write_migration!/3` (the rerun call), `migration_content/3`, `orphan_function_drop/1` and `rerun_rollback_comment/1`.
- `lib/threadline/mix/trigger_migration.ex`: the `rerun?/2` signature and body.
- `test/test_helper.exs` and `test/support/`: the NoticeGuard attach and `after_suite`.
- Frozen legacy fixtures in the repo:
  - `priv/ci/hex_evaluator/.../20260424080642_threadline_triggers_posts.exs`, pre-0.10 form;
  - two `examples/threadline_phoenix/.../*threadline_triggers*.exs` files, pre-0.10 form. They were hand-edited, and one has `DROP FUNCTION … CASCADE` in its `down`.

</code_context>

<specifics>
## Specific Ideas

- **Real-PG test: moved table first.**
  - Fixture: frozen 0.10.x SQL with `public.billing_invoices` and `billing.invoices` on the shared legacy function, whose body masks one column.
  - Run a migration that regenerates only `billing.invoices`. Assert:
    - its `tgfoid` is its hashed function;
    - its insert applies its own mask;
    - the legacy function still exists, with public's trigger on it;
    - a WARNING naming `public.billing_invoices` was logged.
  - Then roll back. Assert both tables still have exactly one enabled Threadline trigger (`tgenabled = 'O'`).
- **Real-PG test: legacy-keeping table only.**
  - Same fixture. Regenerate only `public.billing_invoices`. Assert:
    - the migration raises with the HINT;
    - `pg_get_functiondef(legacy)` is unchanged;
    - both `tgfoid` values are unchanged.
  - Then a combined `--tables billing_invoices,billing.invoices` migration succeeds. Assert:
    - each table applies only its own mask;
    - every per-table function has exactly one trigger using it (`tgfoid`);
    - the legacy-named function `threadline_capture_changes_billing_invoices` still exists. It is `public.billing_invoices`'s own legacy name, since the table is public and ≤36 bytes. Its body now carries only public's rules, and `billing.invoices` is on its hashed function;
    - no WARNING is logged (the retire list excluded functions still in use);
    - `pg_trigger` shows one Threadline trigger per table.
- **SC1 long pair:** two public names sharing their first 36 bytes get distinct hashed functions, and each applies only its own rules.
- **SC2 fixture:**
  - Freeze all three historical forms from D-08. Regenerate and count `pg_trigger` rows per table (exactly 1).
  - Roll back the new migration and assert one enabled trigger remains.
  - For the 46-byte pair, rolling back B's migration leaves A's trigger.
- **Round-trip:** `rerun?` matches the SQL the current `TriggerSQL.create_trigger` produces, so a future change to the emitted form fails CI.
- **`rerun?` unit cases:**
  - the 46-byte shared prefix: refute B and assert A, with B's `down` containing `DROP TRIGGER IF EXISTS "<cut>" ON "public"."<B>"`;
  - `public.a_b` vs `a.b`;
  - unquoted `ON Posts`, which matches `public.posts` but not `public.Posts`;
  - a StreamData property that `rerun?(p, [gen(p)])` holds and `rerun?(q, [gen(p)])` does not for `q ≠ p`.

</specifics>

<deferred>
## Deferred Ideas

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

</deferred>

---

*Phase: 209-collision-free-emission*
*Context gathered: 2026-09-25*
