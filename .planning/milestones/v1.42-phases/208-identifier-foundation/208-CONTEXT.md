# Phase 208: Identifier Foundation - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers one pure, property-tested module, `Threadline.Capture.Naming` (`@moduledoc false`). It derives every generated identifier:
- trigger names;
- per-table capture function names;
- legacy (0.10.x) names;
- trigger-migration file and module names.

Every derived name is valid, deterministic and at most 63 bytes. Names that must be unique across tables are unique. The phase also covers:
- `mix threadline.gen.triggers` writes migrations to, and detects reruns in, the same migrations path that `mix threadline.install` uses (CONF-02);
- invalid or oversized host identifiers raise a role-accurate error, never "storage schema";
- `release-please-config.json` flips to `bump-minor-pre-major: true` (REL-01).

Requirements: NAME-01, NAME-05, CONF-02, REL-01.

**Not in this phase:**
- emitting the new function names into generated SQL;
- orphan-safe drops;
- rewriting the rerun matcher.

Those belong to Phase 209 (NAME-02/03/04). Phase 208 freezes the format that 209 consumes.

</domain>

<decisions>
## Implementation Decisions

### Hash primitive
- **D-01:** `Naming.hash12/1` = `:crypto.hash(:sha256, input) |> Base.encode16(case: :lower) |> binary_part(0, 12)`.
  - For a table, the input is `"<schema>.<table>"` built from the **parsed canonical pair**, after `StorageSchema.parse_table_identifier/1`: trimmed, with the `public` default applied. `posts` and `public.posts` therefore hash identically.
  - No case folding: exact bytes.
  - Operators can reproduce it in SQL with `left(encode(sha256(convert_to('billing.invoices','UTF8')),'hex'),12)`. The moduledoc/guide should show this.
  - Add `:crypto` to `extra_applications`.
  - Do not use MD5 (FIPS) or `:erlang.phash2` (a 2^27 range that SQL can't reproduce; keep it for advisory-lock keys only).
  - **Reversibility:** one-way. The digest is embedded as literal names in adopters' generated migrations, so changing it renames functions in the field.

### Trigger names: never hashed
- **D-02:** Trigger name = `binary_part(legacy, 0, min(63, byte_size(legacy)))`, where `legacy = "threadline_audit_" <> suffix`.
  - `suffix` is today's `host_table_suffix`: `table` for `public`, `schema_table` otherwise.
  - Elixir performs the byte cut before SQL is emitted, so PostgreSQL issues no truncation NOTICE. Inputs are validated ASCII, so this is byte-identical to the name PostgreSQL already stored for 0.10.x installs, including overflowed ones.
  - This **supersedes** the milestone research's plan to hash overflowing trigger names. That plan would create a second trigger on long-name tables (every change captured twice) and break NAME-03.
  - PostgreSQL scopes trigger names per table (`tgrelid`, `tgname`), so they do not need to be unique across tables.
  - The `threadline_audit_%` prefix used by the Health query survives for every output.
  - Nothing may treat a trigger name as a table's identity. See D-11.
  - **Reversibility:** one-way. The names must match the triggers already in adopters' databases.

### Per-table function names
- **D-03:** Keep the legacy name `threadline_capture_changes_<table>` only when **all** of these hold:
  - the schema is `public`;
  - `byte_size(table) <= 36`;
  - the table does not match `~r/_[0-9a-f]{12}\z/`.

  Otherwise use `"threadline_capture_changes_" <> cut(suffix, 23) <> "_" <> hash12`, which is at most 63 bytes.
  - The stem is `schema_table` (the legacy suffix) cut to 23 bytes, so grepping `pg_proc` or `pg_trigger` for `billing_invoices` finds both objects.
  - Do not strip a trailing `_` from the stem.
  - As a result, every non-public per-table function and every overflowing public one moves to a hashed name. Only per-table mode is affected (redaction or `--store-changed-from`). Phase 209's orphan-safe drop retires the old names, which are the untruncated legacy names cut to 63 bytes.
  - **Reversibility:** one-way. The format is frozen into adopters' migrations.
- **D-04 (injectivity argument, to be encoded in tests and docs):**
  - Legacy vs legacy is distinct because public table names are distinct.
  - Hashed vs hashed: the 13-byte tail parses unambiguously, so two names collide only on an h12 collision. The odds are about 1.8e-7 at 10k tables (48 bits).
  - Legacy vs hashed is excluded by the `_<12hex>` rule.
  - The StreamData property asserts injectivity **given distinct h12**. The docs state the odds.

### Golden literal names (freeze the format)
- **D-05:** The golden test must include at least these rows (hashes verified with both `shasum` and `:crypto`):

| Input | h12 | Trigger | Function |
|---|---|---|---|
| `public.posts` | `c6fcf4ae4927` | `threadline_audit_posts` | `threadline_capture_changes_posts` |
| `billing.invoices` | `9bba11019407` | `threadline_audit_billing_invoices` | `threadline_capture_changes_billing_invoices_9bba11019407` |
| `public.billing_invoices` | `ee2e817bbf91` | `threadline_audit_billing_invoices` | `threadline_capture_changes_billing_invoices` |
| `public.customer_subscription_line_items_archive` | `3b9be56c3c45` | `threadline_audit_customer_subscription_line_items_archive` | `threadline_capture_changes_customer_subscription_l_3b9be56c3c45` |
| `analytics_reporting.customer_lifetime_value_snapshots` | `411cf9724315` | `threadline_audit_analytics_reporting_customer_lifetime_value_sn` (63, cut from 70) | `threadline_capture_changes_analytics_reporting_cus_411cf9724315` |
| `public.ledger_0123456789ab` (excluded) | `6095cae6be06` | `threadline_audit_ledger_0123456789ab` | `threadline_capture_changes_ledger_0123456789ab_6095cae6be06` |
| `public.Users` / `public.users` | `3268e9c3e2ba` / `14447575adab` | `threadline_audit_Users` / `threadline_audit_users` | legacy, kept distinct by quoting |

  The executor must recompute these hashes rather than trust them blindly. If one disagrees, stop and report; do not silently update the golden.

### Migration file/module names
- **D-06:** NAME-01 caps these at **63 bytes**, not 255.
  - The candidate stem is `"threadline_triggers_" <> Enum.join(suffixes ++ [ordinal if > 1], "_")`, unchanged from today. If it is at most 63 bytes, use it as is.
  - Otherwise use `"threadline_triggers_" <> readable <> "_" <> h12 <> ord`, where:
    - `h12 = Naming.hash12(Enum.join(Enum.sort(Enum.uniq(qualified)), ","))` over `"schema.table"` strings (public spelled `public.x`);
    - `readable` is the joined suffixes, byte-cut so the total stays at most 63 bytes, with any trailing `_` trimmed;
    - `ord` is `""` or `"_<n>"`, placed after the hash.
  - Module = `"ThreadlineTriggers" <> Macro.camelize(stem_without_prefix)`.
  - Collision checking against the scanned `names` and `modules` is unchanged.
- **D-07:** Case-insensitive filesystems need no downcasing logic. Every file carries a unique 14-digit version prefix, and the only clash (`Macro.camelize("Users") == Macro.camelize("users")`) is on the module name, which the existing ordinal bump resolves. Add a regression test for `Users` + `users`.
  - Other tests: a golden literal for a long multi-table list; a 50-table list yields a stem of at most 63 bytes; reordering tables gives the same h12.

### Migrations path (CONF-02)
- **D-08:** Extract `Threadline.Mix.MigrationsPath.resolve(opts)` from `lib/mix/tasks/threadline.install.ex` (about lines 143-173). Both `install` and `gen.triggers` use it.
  - Precedence:
    1. `--migrations-path P`, used exactly as given, relative to `File.cwd!()`. The repo is never loaded.
    2. The repo: `--repo`/`-r` via `Module.concat([value])`, otherwise the first entry of `ecto_repos`. If its `config()[:priv]` is set, use `Path.join(priv, "migrations")`.
    3. `priv/<Macro.underscore(last alias)>/migrations`.
    4. With no repo configured, `priv/repo/migrations`.
  - Keep install's existing rescue fallback to `priv/repo/migrations` on default-lookup failure, so behavior does not change in 208.
  - An explicit `--repo` that fails to load raises `Mix.raise` naming the module.
  - Resolve the path in-house. Do not call the private `Mix.EctoSQL` or `Ecto.Migrator.migrations_path/2` (it points into `_build/`).
- **D-09:** Both tasks accept `--migrations-path` and `--repo`/`-r` through strict `OptionParser`.
  - `--repo` is single-valued. A repeat raises `"--repo may be given once; Threadline audit tables live in one repo"`.
  - `install` now rejects unknown flags; today it ignores its arguments. This is an accepted behavior change: note it in the CHANGELOG and moduledoc.
  - Umbrellas: run from the child app directory, and say so in the moduledoc.
  - `gen.triggers` passes the one resolved path to `MigrationVersion.next`, `TriggerMigration.scan` and `rerun?`. Delete the stale comment at `gen.triggers.ex` 162-166.
  - Tests:
    - a repo with non-default `:priv` (`priv/custom_repo`): both tasks write there, and rerun detection finds an earlier file there;
    - `--migrations-path` beats `:priv`;
    - an unknown flag on `install` raises.

### Host identifier errors
- **D-10:** Keep `ArgumentError`; do not add a new public exception type before 1.0. Add `StorageSchema.validate_identifier!(value, role)` with roles `:storage_schema | :host_schema | :host_table | :derived`.
  - `validate!/1` delegates with `:storage_schema`, and its existing message text is unchanged.
  - `parse_table_identifier/1` passes `:host_schema` / `:host_table`. This also fixes runtime callers (`continuity.ex`, `redaction_presenter.ex`).
  - Template: `Threadline <role label> <inspect(value)> (from <inspect(input)>) is <byte_size> bytes; it must be a PostgreSQL identifier matching ^[A-Za-z_][A-Za-z0-9_]*$ and at most 63 bytes`. Omit `(from …)` when the value equals the input. Use `byte_size`, never `String.length`.
  - `gen.triggers` wraps table parsing as `rescue e in ArgumentError -> Mix.raise("--tables: " <> Exception.message(e))`, so users see no stacktrace.
  - An overflowing *derived* name never raises: functions hash (D-03) and triggers cut (D-02).
  - Tests: a unit test on `parse_table_identifier/1` with a 70-byte table asserts `host table`, the value and `70 bytes`, and refutes `storage schema`. A Mix task test asserts `Mix.Error` with the same fragments.

### Phase split with 209
- **D-11:** `TriggerMigration.rerun?/2` stays name-based in 208; only its input directory changes (D-09). The rewrite to match the quoted host table in the `ON` clause (plus the older unquoted form, and current and legacy trigger names) moves to Phase 209 with NAME-03.
  - The known 208-era false positive (`public.a_b` vs `a.b`) only yields a conservative "already has triggers" result.
  - Phase 209 must also stop treating trigger names as table identity anywhere (D-02).

### Release config (REL-01)
- **D-12:** The maintainer chose to set `bump-minor-pre-major: true`; `bump-patch-for-minor-pre-major` stays `false`.
  - This is the **first commit of Phase 208**, a non-releasable `ci:` or `chore:` commit that precedes every `feat`/`fix`/`perf`/`deps` commit on `milestone/v1.42`.
  - Add a config contract test asserting the key. Record the `git log` ordering check in the phase verification.
  - **Reversibility:** costly. It governs every release proposal up the ladder to 1.0.0.

### Claude's Discretion
- StreamData:
  - `{:stream_data, "~> 1.4", only: :test}`;
  - properties are `async: true` at the default of 100 runs and live in plain `mix test`, with no exclusion tag;
  - generators are biased toward `_`-split pairs (`public.a_b` vs `a.b`), case pairs and 36-byte shared prefixes, per NAME-05.
- The internal API shape of `Naming`: function names such as `trigger_name/1`, `function_name/1`, `legacy_function_name/1`, `migration_name/2`, `hash12/1`.
- Whether `StorageSchema.host_table_suffix/1` stays public: it stays, documented as the legacy suffix.
- Test file layout.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and requirements
- `.planning/ROADMAP.md` § Phase 208: goal, success criteria 1-4, research flag
- `.planning/REQUIREMENTS.md`: NAME-01, NAME-05, CONF-02, REL-01, plus NAME-02/03/04 (Phase 209, which consumes this format)

### Milestone research
- `.planning/research/SUMMARY.md`: decision table rows 2 (hash width), 3 (which names hash; **trigger half superseded by D-02**) and 6 (release version); § Phase 208
- `.planning/research/STACK.md` §3 (identifier derivation, sha256, 63-byte truncation) and §4 (`gen.triggers` migrations path; do not use `Ecto.Migrator.migrations_path/2`)
- `.planning/research/ARCHITECTURE.md`: the `Threadline.Capture.Naming` and `Threadline.Mix.MigrationsPath` component rows and the file layout
- `.planning/research/PITFALLS.md`: Pitfall 9 (case handling) and the rename double-trigger pitfall

### Project conventions
- `prompts/threadline-elixir-oss-dna.md`: honest default tests, named verification entrypoints
- `.planning/MILESTONE-GUIDE.txt`: the quality and release bar for this milestone

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StorageSchema.parse_table_identifier/1`, `host_table_suffix/1`, `validate!/1`, `quote_ident/1` (`lib/threadline/storage_schema.ex:50-130`): canonical parsing and the legacy suffix. `Naming` builds on them.
- `install.ex` `migrations_path/0` (`lib/mix/tasks/threadline.install.ex:143-173`): the correct resolution logic to extract.
- `TriggerMigration.scan/1` and `resolve_name/2` (`lib/threadline/mix/trigger_migration.ex:28-70`): the ordinal-bump collision logic stays; the name is capped via `Naming`.
- `TriggerSQL.per_table_function_fits?/1` and `@max_identifier_bytes` (`lib/threadline/capture/trigger_sql.ex:100-117`): existing 63-byte awareness to fold into `Naming`.

### Established Patterns
- Name concatenation is currently scattered: `trigger_sql.ex:141,153,163` and `trigger_migration.ex:61-62,81`. All of these should route through `Naming`, but *emitting* new function names is Phase 209's job, so 208 may leave emission call sites producing today's output as long as trigger names stay byte-identical.
- `Threadline.Health` finds triggers with `tgname LIKE 'threadline_audit_%'` (`lib/threadline/health.ex:~103`). Prefixes must be preserved.

### Integration Points
- `lib/mix/tasks/threadline.gen.triggers.ex:94-190`: the hardcoded `"priv/repo/migrations"` at about line 159, and table parsing at about line 118 (the `Mix.raise` wrap).
- `release-please-config.json`: `bump-minor-pre-major` is currently `false`.
- `mix.exs`: the `stream_data` test dependency and `:crypto` in `extra_applications`.

</code_context>

<specifics>
## Specific Ideas

- Operators must be able to reproduce any hashed name with plain SQL (`sha256`, available since PostgreSQL 11). This fits the "SQL-native" design constraint.
- Research holes to carry into planning:
  - hash the parsed pair, never the raw CLI string;
  - the 48-bit hash is probabilistic, so the property is scoped accordingly;
  - Phase 209's orphan-safe drop needs the old 0.10.x function names (untruncated legacy cut to 63).

</specifics>

<deferred>
## Deferred Ideas

- The `rerun?/2` rewrite (ON-clause host-table matching plus current and legacy trigger names) belongs to Phase 209 with NAME-03.
- Emitting hashed per-table function names and orphan-safe drops of old 0.10.x function names belongs to Phase 209.
- Full `ecto.gen.migration` parity (repeatable `-r`, fan-out to every repo) was rejected, because audit tables live in one repo.
- A structured `Threadline.InvalidIdentifierError` exception was rejected before 1.0. Revisit at the 1.0 API review.
- The umbrella-root fallback of `install` to `priv/repo/migrations` is pre-existing and out of scope.

</deferred>

---

*Phase: 208-identifier-foundation*
*Context gathered: 2026-09-25*
