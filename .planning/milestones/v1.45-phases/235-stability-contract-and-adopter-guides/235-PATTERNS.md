# Phase 235: Stability Contract and Adopter Guides - Pattern Map

**Mapped:** 2026-10-06  
**Files analyzed:** 14 likely targets (some names remain at planner discretion)  
**Analogs found:** 13 / 14 (one new live-catalog responsibility has no close analog)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `guides/stability.md` (locked filename) | documentation | none | `guides/upgrade-path.md` | role-match |
| `guides/supported-tables.md` (proposed) | documentation | none | `guides/upgrade-path.md` | role-match |
| `guides/redaction.md` (proposed) | documentation | none | `guides/production-checklist.md`; `guides/incident-playbook.md` | partial |
| `lib/threadline/capture/primary_key_sql.ex` | utility (SQL generator) | transform | same file's detected/override trigger blocks | exact |
| `lib/threadline/capture/audit_change.ex` | model | none | same module's current moduledoc/type/schema | exact |
| `lib/threadline/capture/audit_transaction.ex` | model | none | same module's current moduledoc/type/schema | exact |
| `lib/threadline/semantics/audit_action.ex` | model | none | same module's current moduledoc/type/schema | exact |
| `test/threadline/capture/trigger_migrate_time_errors_test.exs` | test | request-response (migration) | same test module; `trigger_pk_override_test.exs` | exact |
| New migration-time redaction regression test (likely extend above) | test | request-response (migration) | `trigger_migrate_time_errors_test.exs` | exact |
| New storage catalog contract test (path open) | test | batch / database read | `storage_schema_migration_contract_test.exs` | partial |
| New public API and persisted-field contract test(s) (path open) | test | transform / request-response | `public_surface_contract_test.exs`; `telemetry_registry_contract_test.exs` | role-match |
| New guide claim contract test(s) (path open) | test | file I/O | `semver_adopter_doc_contract_test.exs`; `guide_graph_contract_test.exs` | exact |
| `test/threadline/guide_graph_contract_test.exs` | test | file I/O | same test | exact |
| `mix.exs` (ExDoc extras for new guides) | config | none | `guide_graph_contract_test.exs` assertions over `MixProject.project()[:docs][:extras]` | role-match |

Guide filenames other than `guides/stability.md`, and whether the contract assertions are split or grouped, are intentionally left open in CONTEXT.md. Keep the proposed shape/redaction filenames consistent with the three reader jobs. The generated trigger guard belongs in `PrimaryKeySQL`'s migration SQL path, not `TriggerCaptureConfig.load/1`, because the latter has no catalog connection.

## Pattern Assignments

### `lib/threadline/capture/primary_key_sql.ex` (utility, transform)

**Analog:** `lib/threadline/capture/primary_key_sql.ex` (tracked source; same SQL-generation seam)

The two branches each resolve the selected relation to `tbl` and insert validation before trigger DDL. Follow the same helper-and-interpolation arrangement, adding a separate configured-column existence check rather than extending the existing primary-key redaction guard.

**Relation/catalog and safe value pattern** (lines 209-259, 425-433):

```elixir
      tbl        regclass := to_regclass('#{host_table}');
      declared   text[] := #{declared_literal};
      missing    text;
...
      SELECT d
        INTO missing
        FROM unnest(declared) AS d
       WHERE NOT EXISTS (
             SELECT 1 FROM pg_attribute a
              WHERE a.attrelid = tbl AND a.attname = d AND a.attnum > 0 AND NOT a.attisdropped
           )
       LIMIT 1;

      IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'threadline: primary_key: column % of #{qualified} does not exist', missing;
      END IF;
```

Configured strings use SQL value literals with embedded single quotes doubled (lines 425-433). The new check should use `tbl`, exact `attname`, `attnum > 0`, and `NOT attisdropped`; run it for both detected-key and `primary_key:` branches, before `EXECUTE format(...)`. Keep `:mask` and `:exclude` distinct in actionable errors. The current branch-specific `redaction_check_sql/2` only prevents redacting primary-key columns (lines 400-423); it does not establish arbitrary column existence.

### `test/threadline/capture/trigger_migrate_time_errors_test.exs` (test, request-response)

**Analog:** same module; `test/threadline/capture/trigger_pk_override_test.exs` is the companion for override-path migration cases.

This is the strongest direct analog: it provisions real PostgreSQL fixtures, generates the host-owned migration with `MigrationHarness`, applies it, checks actionable PostgreSQL errors, verifies no trigger/schema-migration row remains, and proves host writes still work.

**Migration refusal and rollback pattern** (`trigger_migrate_time_errors_test.exs`, lines 105-140):

```elixir
file = Harness.generate!(tmp, ["--tables", "posts_tags"])

error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

assert error.postgres.message =~ ~r/^threadline:/
assert error.postgres.message =~ "public.posts_tags"
assert error.postgres.message =~ "primary_key:"
assert error.postgres.hint =~ "config/config.exs"

assert Harness.threadline_triggers("public", "posts_tags") == []
refute_schema_migrations_row(file)

Repo.query!("INSERT INTO posts_tags (post_id, tag_id) VALUES (1, 2)")
assert capture_rows("public", "posts_tags") == []
```

Reuse the non-async DataCase + temporary migration harness lifecycle (`trigger_migrate_time_errors_test.exs`, lines 12-70). Add both invalid option paths, at least one `primary_key:` override branch case, and a successful valid-column control. For the control, apply the migration, confirm the trigger, perform a write, and assert current redaction semantics. Do not test only emitted SQL; D-06 requires proof of transactional rollback and no partial trigger/function/migration record.

### Storage and public contract tests (new test path(s) open)

**Analogs:** `test/threadline/storage_schema_migration_contract_test.exs`; `test/threadline/public_surface_contract_test.exs`; `test/threadline/telemetry_registry_contract_test.exs` (all tracked).

`StorageSchemaMigrationContractTest` pins generated migration structure with explicit assertions (`storage_schema_migration_contract_test.exs`, lines 20-33); it is useful for public DDL and schema quoting, but it is not a live PostgreSQL catalog assertion. For D-03, query the live catalog and assert named required `(table, column, type, nullable)` facts plus required shipped indexes. Treat required sets as deliberate pins while allowing additive database objects.

**Existing explicit public-contract style** (`public_surface_contract_test.exs`, lines 186-218):

```elixir
reads = source_env_reads()
assert MapSet.size(reads.literal) > 0
assert :ecto_repos in reads.literal
assert reads.literal == MapSet.new(@runtime_keys), runtime_key_diff(reads.literal)

reference = read_public!("guides/configuration-and-commands.md")
mentioned = extract_references(reference).keys |> MapSet.new()
assert mentioned == reads.literal, runtime_key_diff(mentioned)
```

This is the closest pattern for literal pins on exports, health codes, Mix task flags, operator-surface options/routes, `threadline.actor_ref`, and trigger-function naming. For stable Ecto fields, use the module's named expected subset and verify it is contained in `module.__schema__(:fields)`; do not assert equality with the entire schema. `TelemetryRegistryContractTest` shows a runtime set assertion with actionable diffs (`telemetry_registry_contract_test.exs`, lines 205-227). Avoid deriving the expected values solely from the implementation being protected.

### `guides/stability.md`, table-shapes guide, and redaction guide (documentation)

**Analogs:** `guides/upgrade-path.md` (tracked), plus the guide contract pattern in `test/threadline/semver_adopter_doc_contract_test.exs`.

The upgrade guide answers adopter compatibility questions with named statuses, evidence paths, concise conditions, and distinct support terms (`upgrade-path.md`, lines 36-48, 50-68). Reuse its answer-first structure and short cross-links. For table shapes, put support status and all prerequisites/caveats in one small matrix; do not hide `primary_key:` index rules, supported key types, partition leaf behavior, or unlogged durability in distant prose. The redaction guide should attach each proof to its tested data path and timing, and list residual plaintext locations explicitly. `RedactionLeakPropertyTest`'s module docs distinguish captured storage/diffs/exports from the global installer path (`redaction_leak_property_test.exs`, lines 20-42); preserve that boundary.

**Guide claim contract pattern** (`semver_adopter_doc_contract_test.exs`, lines 4-21):

```elixir
@adopter_paths [
  "README.md",
  "guides/getting-started-saas.md",
  "guides/how-threadline-works.md",
  "guides/upgrade-path.md",
  "guides/adoption-pilot-backlog.md"
]

test "adopter-band docs avoid internal v1.2x milestone labels" do
  for path <- @adopter_paths do
    doc = File.read!(path)
    refute Regex.match?(@milestone_pattern, doc)
  end
end
```

Use focused, named tests for the claims that should fail on drift rather than snapshots of whole prose. Include links to the exact implementation/test evidence. New guide files also need `mix.exs` ExDoc extras and guide graph assignment; `guide_graph_contract_test.exs` lines 73-95 checks on-disk guides against configured extras and graph membership.

### `lib/threadline/capture/audit_change.ex`, `audit_transaction.ex`, `semantics/audit_action.ex` (models)

**Analog:** each module's existing moduledoc, `@type t`, and Ecto schema. For example, `audit_change.ex` lines 12-24 names the current documented fields; lines 48-61 give the full type. Mirror that in the other two modules. D-02 requires the docs-selected stable subset to remain explicit while `t` and schema fields can grow. Pin the selected subset in a contract against `__schema__(:fields)`; additive fields remain permitted. Describe JSONB maps as additive key/shape contracts, not byte-stable serialized JSON.

## Shared Patterns

### Generated migration validation

**Source:** `lib/threadline/capture/primary_key_sql.ex`, lines 120-126 and 209-215. Both paths resolve a schema-qualified host relation to `tbl` (`regclass`) before querying PostgreSQL catalogs. Put the new name-membership checks in both branches before trigger installation; use catalog values rather than configured names as SQL identifiers.

### Focused contract assertions

**Sources:** `test/threadline/public_surface_contract_test.exs`, lines 188-218; `test/threadline/guide_graph_contract_test.exs`, lines 73-95. Make each contract attributable: literal expected public names, live catalog facts for physical schema, exact doc claims/links for prose, and relevant mutation controls where removal or rename is a meaningful failure. Keep catalog facts separate from API allowlists.

### Claim-level proof in adopter docs

**Sources:** `guides/upgrade-path.md`, lines 36-68; `test/threadline/capture/redaction_leak_property_test.exs`, lines 20-42. Use Threadline domain nouns. Qualify capture/redaction promises by generated per-table path, covered surface, and rollout timing. Existing installed host triggers and previously captured rows are not repaired by library source updates. Do not claim health-check validation for column existence.

## No Analog Found

| File / responsibility | Role | Data Flow | Reason |
|-----------------------|------|-----------|--------|
| New live PostgreSQL catalog contract for `audit_transactions`, `audit_changes`, and `audit_actions` | test | batch / database read | Existing storage migration contract checks generated SQL, not live catalog columns/types/nullability/indexes. Use it only as style guidance; the live catalog check is a new responsibility. |

## Metadata

**Analog search scope:** `lib/threadline/capture/`, `lib/threadline/semantics/`, `test/threadline/`, `test/threadline/capture/`, `guides/`, and `mix.exs`.  
**Tracked-source gate:** every analog listed above was checked with `git ls-files`; all are tracked files.  
**Pattern extraction date:** 2026-10-06
