# Phase 208: Identifier Foundation - Research

**Researched:** 2026-09-25
**Domain:** Elixir identifier derivation (PostgreSQL 63-byte limit), StreamData property testing, Mix task path resolution, release-please config
**Confidence:** HIGH (every in-repo claim was read this session; the golden hashes were recomputed with `:crypto`, `shasum` and PostgreSQL 14.17)

## Summary

This phase adds two internal modules and makes small changes to four existing files. `Threadline.Capture.Naming` is a pure `@moduledoc false` module that derives every generated identifier. `Threadline.Mix.MigrationsPath` is extracted from `install.ex`. The modified files are `storage_schema.ex`, `trigger_migration.ex`, `threadline.install.ex` and `threadline.gen.triggers.ex`. The phase also flips one key in `release-please-config.json`. CONTEXT.md locks every format decision, so this research checks those decisions against the code as it stands and lists what the executor will hit.

I independently recomputed all seven D-05 golden rows. `:crypto` gives the same hashes as `shasum -a 256`, and PostgreSQL 14.17's `left(encode(sha256(convert_to('billing.invoices','UTF8')),'hex'),12)` returns `9bba11019407`. The trigger and function names in D-05, and their byte counts (63 and 63), also check out.

Seven findings from the code change how the plan should be built:

1. **Derived names already fail today with the "storage schema" message.** `TriggerSQL` passes every trigger and function name through `StorageSchema.quote_ident/1` → `validate!/1`, and `validate!/1` rejects anything over 63 bytes with `"Threadline storage schema must be..."`. That is the NAME-01 defect.
2. **An existing test asserts `ArgumentError ~r/at most 63 bytes/`** from `Triggers.run` for an overflowing per-table function (`trigger_rerun_test.exs:217-223`). The D-10 `Mix.raise` wrap must cover only table parsing. Otherwise that test breaks in 208, although it belongs to 209.
3. **`gen.triggers` `run/1` is already 101 lines.** `source_size_contract_test.exs` caps functions at 120 lines, so the new option parsing and rescue must go into helper functions.
4. **D-06's shorthand `Macro.camelize(stem_without_prefix)` is not always the same as today's per-part camelize.** For suffixes `["a", "B"]` the two give different modules. Keep today's per-part camelize so module names stay unchanged.
5. **StreamData 1.4.0 requires `elixir: "~> 1.14"`.** The repo's `dep_floor_guard_test.exs` requires every locked dependency to admit Elixir 1.15.0, and 1.4.0 does.
6. **Adding `:crypto` changes `mix.exs`.** The CI Dialyzer PLT cache key hashes `mix.exs`, so CI takes a one-time PLT rebuild. Locally, run `mix dialyzer --plt` before `ci.all`.
7. **Packaged `lib/` text must not contain planning vocabulary** (`Phase 208`, `D-02`). The release artifact contract bans it.

**Primary recommendation:** Build `Naming` first as a pure module with golden and property tests. Add `StorageSchema.validate_identifier!/2` next. In 208, route **trigger names only** through `Naming.trigger_name/1`; this is byte-identical when the name fits and cut at 63 bytes when it overflows. Keep per-table **function** emission on the legacy name, validated with the `:derived` role so the error is accurate and remains an `ArgumentError`. Extract `MigrationsPath` and adopt it in both tasks. The REL-01 config flip goes first, as a `ci:` commit.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Hash primitive
- **D-01:** `Naming.hash12/1` = `:crypto.hash(:sha256, input) |> Base.encode16(case: :lower) |> binary_part(0, 12)`.
  - For a table, the input is `"<schema>.<table>"` built from the **parsed canonical pair**, after `StorageSchema.parse_table_identifier/1`: trimmed, with the `public` default applied. `posts` and `public.posts` therefore hash identically.
  - No case folding: exact bytes.
  - Operators can reproduce it in SQL with `left(encode(sha256(convert_to('billing.invoices','UTF8')),'hex'),12)`. The moduledoc/guide should show this.
  - Add `:crypto` to `extra_applications`.
  - Do not use MD5 (FIPS) or `:erlang.phash2` (a 2^27 range that SQL can't reproduce; keep it for advisory-lock keys only).
  - **Reversibility:** one-way. The digest is embedded as literal names in adopters' generated migrations, so changing it renames functions in the field.

#### Trigger names: never hashed
- **D-02:** Trigger name = `binary_part(legacy, 0, min(63, byte_size(legacy)))`, where `legacy = "threadline_audit_" <> suffix`.
  - `suffix` is today's `host_table_suffix`: `table` for `public`, `schema_table` otherwise.
  - Elixir performs the byte cut before SQL is emitted, so PostgreSQL issues no truncation NOTICE. Inputs are validated ASCII, so this is byte-identical to the name PostgreSQL already stored for 0.10.x installs, including overflowed ones.
  - This **supersedes** the milestone research's plan to hash overflowing trigger names. That plan would create a second trigger on long-name tables (every change captured twice) and break NAME-03.
  - PostgreSQL scopes trigger names per table (`tgrelid`, `tgname`), so they do not need to be unique across tables.
  - The `threadline_audit_%` prefix used by the Health query survives for every output.
  - Nothing may treat a trigger name as a table's identity. See D-11.
  - **Reversibility:** one-way. The names must match the triggers already in adopters' databases.

#### Per-table function names
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

#### Golden literal names (freeze the format)
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

#### Migration file/module names
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

#### Migrations path (CONF-02)
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

#### Host identifier errors
- **D-10:** Keep `ArgumentError`; do not add a new public exception type before 1.0. Add `StorageSchema.validate_identifier!(value, role)` with roles `:storage_schema | :host_schema | :host_table | :derived`.
  - `validate!/1` delegates with `:storage_schema`, and its existing message text is unchanged.
  - `parse_table_identifier/1` passes `:host_schema` / `:host_table`. This also fixes runtime callers (`continuity.ex`, `redaction_presenter.ex`).
  - Template: `Threadline <role label> <inspect(value)> (from <inspect(input)>) is <byte_size> bytes; it must be a PostgreSQL identifier matching ^[A-Za-z_][A-Za-z0-9_]*$ and at most 63 bytes`. Omit `(from …)` when the value equals the input. Use `byte_size`, never `String.length`.
  - `gen.triggers` wraps table parsing as `rescue e in ArgumentError -> Mix.raise("--tables: " <> Exception.message(e))`, so users see no stacktrace.
  - An overflowing *derived* name never raises: functions hash (D-03) and triggers cut (D-02).
  - Tests: a unit test on `parse_table_identifier/1` with a 70-byte table asserts `host table`, the value and `70 bytes`, and refutes `storage schema`. A Mix task test asserts `Mix.Error` with the same fragments.

#### Phase split with 209
- **D-11:** `TriggerMigration.rerun?/2` stays name-based in 208; only its input directory changes (D-09). The rewrite to match the quoted host table in the `ON` clause (plus the older unquoted form, and current and legacy trigger names) moves to Phase 209 with NAME-03.
  - The known 208-era false positive (`public.a_b` vs `a.b`) only yields a conservative "already has triggers" result.
  - Phase 209 must also stop treating trigger names as table identity anywhere (D-02).

#### Release config (REL-01)
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

### Deferred Ideas (OUT OF SCOPE)
- The `rerun?/2` rewrite (ON-clause host-table matching plus current and legacy trigger names) belongs to Phase 209 with NAME-03.
- Emitting hashed per-table function names and orphan-safe drops of old 0.10.x function names belongs to Phase 209.
- Full `ecto.gen.migration` parity (repeatable `-r`, fan-out to every repo) was rejected, because audit tables live in one repo.
- A structured `Threadline.InvalidIdentifierError` exception was rejected before 1.0. Revisit at the 1.0 API review.
- The umbrella-root fallback of `install` to `priv/repo/migrations` is pre-existing and out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NAME-01 | Every generated identifier is ≤ 63 bytes and never silently truncated by PostgreSQL. An invalid or oversized host identifier raises an error that names the derived identifier and its byte count, not "storage schema". | Current defect located: `validate!/1` message and `quote_ident/1` path (§Current Code Facts). `Naming` API and cut/hash rules (Pattern 1). `validate_identifier!/2` design (Pattern 3). Trigger-name routing in 208 (Pattern 4). Migration-name cap (Pattern 2). |
| NAME-05 | StreamData properties: ≤ 63 bytes, deterministic, injective under biased generators. A golden literal-name test freezes the format. | StreamData 1.4.0 verified (floor-compatible). Generator design and a property list (Pattern 5). Golden table recomputed (Code Examples). Warning that trigger-name injectivity must NOT be asserted (Pitfall 1). |
| CONF-02 | `gen.triggers` writes to the repo's configured migrations path, the same resolution `install` uses, and accepts `--migrations-path`. Rerun detection reads the same directory. | Extraction source (`install.ex:143-173`). Ecto precedent for `--migrations-path`. Stub-repo test strategy (Pattern 6). |
| REL-01 | `bump-minor-pre-major` is `true` before the first releasable commit of the milestone. | Current value `false` read at `release-please-config.json:4`. release-please semantics cited. No releasable commit exists yet on `main..HEAD` (verified). Ordering-check command given (Validation). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep the three layers separate. `Naming` belongs to the capture layer (`lib/threadline/capture/`). `MigrationsPath` is Mix plumbing (`lib/threadline/mix/`).
- The canonical verification entrypoints are `mix verify.format`, `mix verify.credo`, `mix verify.test` and `mix ci.all`.
- Honest default tests: never silently exclude suites from `mix test`. The properties run in plain `mix test`, with no tag. `zero_skips_contract_test.exs` forbids skip tags and any extra excludes.
- Stable CI job IDs: do not rename `id:` fields.
- Capture stays trigger-backed through host-owned Ecto migrations.
- SQL-native: operators must be able to reproduce hashed names in SQL. The expression was verified on PG 14.17.
- Zero human verification. All UAT is automated.
- `state.begin-phase` takes flags (`--phase 208 --name ... --plans N`) under gsd-core v1.14.0. Hand-check STATE.md afterwards.
- Never `git add .planning/`. Stage explicit paths only.
- Only `feat`/`fix`/`perf`/`deps` commits are releasable (release runbook memory). REL-01's commit must be `ci:` or `chore:`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Identifier derivation (trigger/function/migration names, hash12) | Capture layer, pure Elixir (`Threadline.Capture.Naming`) | Database: names become literals in DDL | Names are frozen into adopter migrations, so one owner is needed, with no I/O |
| Host identifier validation and role-accurate errors | `Threadline.StorageSchema` (public module) | Mix task (`Mix.raise` wrapping) | Already the parsing owner; runtime callers (`continuity.ex`, `redaction_presenter.ex`) inherit the fix |
| Migrations directory resolution | Mix plumbing (`Threadline.Mix.MigrationsPath`) | Host repo config (`:priv`, `ecto_repos`) | Generation-time only; never runs in the adopter's runtime |
| Rerun detection / name collision | `Threadline.Mix.TriggerMigration` | Filesystem scan | Unchanged in 208 except for the directory it reads and the name cap |
| Release version policy | CI/release config (`release-please-config.json`) | Contract test | Not code. Asserted by a test |

## Current Code Facts (read this session)

These are the exact current values that the plan changes or must preserve.

- **Identifier regex and the 63-byte limit.** `[VERIFIED: lib/threadline/storage_schema.ex:23-24]`
  ```
  @identifier ~r/^[A-Za-z_][A-Za-z0-9_]*$/
  @max_identifier_bytes 63
  ```
- **The misleading message**, which every identifier kind goes through today. `[VERIFIED: lib/threadline/storage_schema.ex:68-73]`
  ```
  "Threadline storage schema must be a non-empty PostgreSQL identifier " <>
    "matching #{@identifier.source} and at most #{@max_identifier_bytes} bytes, " <>
    "got: #{inspect(value)}"
  ```
  `validate!/1` handles `nil`, booleans, atoms (converted) and binaries (trimmed), and raises on anything else (lines 50-66). `validate_identifier!/2` must keep those non-binary clauses. You cannot take `byte_size` of `nil`, so the byte-count template needs a separate branch for non-binaries.
- **`parse_table_identifier/1`** trims the input, splits on `.`, applies `"public"` to a bare name and calls `validate!` on each segment. A shape error raises `"table must be NAME or SCHEMA.NAME, got: ..."`. `[VERIFIED: lib/threadline/storage_schema.ex:99-112]`
- **`host_table_suffix/1`** returns `table` if the schema is `"public"`, else `"#{schema}_#{table}"`. `[VERIFIED: lib/threadline/storage_schema.ex:121-129]`
- **`quote_ident/1`** is `~s("#{validate!(identifier)}")`, and `qualify/2` quotes both parts. `[VERIFIED: lib/threadline/storage_schema.ex:76-79]` Derived names reach `validate!` through this path. That is why an overflowing trigger or function name raises the "storage schema" text today.
- **Where names are built.** `[VERIFIED: lib/threadline/capture/trigger_sql.ex:141,153,162-164]`
  ```
  trigger_name = "threadline_audit_#{StorageSchema.host_table_suffix(table_name)}"   # 141 and 153
  "threadline_capture_changes_#{StorageSchema.host_table_suffix(table_name)}"        # 163
  ```
  `per_table_function_fits?/1` compares `byte_size(per_table_function_base(table_name)) <= @max_identifier_bytes`, where `@max_identifier_bytes 63` is at line 8. `[VERIFIED: trigger_sql.ex:8,108-110]`
- **Migration name and module today.** `[VERIFIED: lib/threadline/mix/trigger_migration.ex:57-70]`
  ```
  parts = if ordinal == 1, do: suffixes, else: suffixes ++ [Integer.to_string(ordinal)]
  name = "threadline_triggers_" <> Enum.join(parts, "_")
  module = "ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)
  ```
  This is **per-part** camelize, so see Pitfall 3. `rerun?/2` compiles `"threadline_audit_" <> Regex.escape(suffix) <> "(?![A-Za-z0-9_])"` (lines 80-83).
- **The hard-coded path in gen.triggers.** `path = "priv/repo/migrations"` `[VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex:159]`. The stale comment is at lines 162-166. The first table parse is `StorageSchema.threadline_table?/1` at **line 119** (not 118). The suffixes and `rerun?` calls are at lines 169-178. `run/1` spans lines 92-192 (101 lines).
- **Install's resolution to extract.** `[VERIFIED: lib/mix/tasks/threadline.install.ex:143-173]` It reads `Mix.Project.config()[:app]`, then `Application.get_env(app, :ecto_repos, [])`. The first repo's `repo.config()[:priv]` gives `Path.join(p, "migrations")`. With no `:priv` it uses `"priv/#{repo |> Module.split() |> List.last() |> Macro.underscore()}"` + `"migrations"`. `[]` → `"priv/repo/migrations"`. It ends with `rescue _ -> "priv/repo/migrations"`. `run(_args)` ignores its arguments today (line 35).
- **Test env repo config.** `config :threadline, ecto_repos: [Threadline.Test.Repo]` with no `:priv` key. `[VERIFIED: config/test.exs:49]` The default resolution in tests is therefore `priv/repo/migrations`, which is why the existing install and gen.triggers tests (`@migrations "priv/repo/migrations"`) keep passing after the extraction.
- **Release config.** `"bump-minor-pre-major": false,` and `"bump-patch-for-minor-pre-major": false,` `[VERIFIED: release-please-config.json:4-5]`
- **mix.exs.** `extra_applications: [:logger],` `[VERIFIED: mix.exs:76]`. No `stream_data` in `deps/0` (lines 84-118) or `mix.lock` (grep, no match). `:crypto` is not referenced anywhere in `lib/`; the only hashing is `:erlang.phash2` advisory-lock keys at `retention/pruner.ex:12` and `export/cleanup_task.ex:11`.
- **The Health prefix.** `WHERE t.tgname LIKE 'threadline_audit_%'` `[VERIFIED: lib/threadline/health.ex:103]`
- **Git state.** `main..HEAD` has 7 commits and none match `^(feat|fix|perf|deps)(\(..\))?!?:`. `[VERIFIED: git log, this session]` REL-01 can still be first.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:crypto` (OTP) | OTP 26/27 | `:crypto.hash(:sha256, _)` for `hash12/1` | FIPS-safe, and reproducible in PostgreSQL ≥ 11 via `sha256()` `[VERIFIED: PG 14.17 returned 9bba11019407]` |
| `Base` (Elixir stdlib) | 1.15+ | `Base.encode16(case: :lower)` | stdlib |
| `OptionParser` (stdlib) | 1.15+ | strict flags for both tasks | existing pattern at `gen.triggers.ex:95-103` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `stream_data` | `~> 1.4` (1.4.0, published 2026-07-14) | `ExUnitProperties` `check all` properties | test-only (`only: :test`) |

**Version verification:** hex.pm API, this session. `latest_stable_version` is `1.4.0`, and 1.4.0 declares `elixir: "~> 1.14"` with no runtime requirements and no retirement. 1.3.0 declares `~> 1.12`. `[VERIFIED: hex.pm API]` The v1.4.0 changelog says "Require Elixir 1.14+", adds a codepoints/graphemes string option, and makes `one_of/1` shrink toward earlier elements. It reports no changes to `check all`/`max_runs`. `[CITED: github.com/whatyouhide/stream_data/blob/main/CHANGELOG.md]` `Version.match?("1.15.0", "~> 1.14")` is true, so `dep_floor_guard_test.exs` stays green.

**Installation:**
```bash
# mix.exs deps: {:stream_data, "~> 1.4", only: :test}
# mix.exs application: extra_applications: [:logger, :crypto]
mix deps.get   # updates mix.lock; commit mix.lock with mix.exs
```

### Alternatives Considered
All alternatives were rejected in CONTEXT.md (MD5, `phash2`, `Ecto.Migrator.migrations_path/2`, `Mix.EctoSQL`). None are re-explored here.

## Package Legitimacy Audit

`gsd-tools package-legitimacy check` supports only npm, PyPI and crates (it errored on `--ecosystem hex`), so the check used the hex.pm API directly.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| stream_data | Hex | 1.0.0 released 2024-05-13; project older | 37.5M all-time, ~122k/week | github.com/whatyouhide/stream_data | OK (manual: established, maintained by an Elixir core-team member, no retirement) | Approved |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
Hex packages have no npm-style `postinstall`. `stream_data` is `only: :test`, so it never reaches adopters.

## Architecture Patterns

### System Architecture Diagram

```
 mix threadline.gen.triggers --tables T1,T2 [--repo R] [--migrations-path P]
        |
        v
 OptionParser(strict) --unknown--> Mix.raise
        |
        v
 parse --tables  --(ArgumentError, role :host_schema/:host_table)--> Mix.raise("--tables: ...")
        |   StorageSchema.parse_table_identifier/1 -> %{schema, table}
        v
 MigrationsPath.resolve(opts) ---> P | repo :priv/migrations | priv/<repo>/migrations | priv/repo/migrations
        |
        +--> MigrationVersion.next(path, 1)
        +--> TriggerMigration.scan(path) --> names/modules/sources
        |         |
        |         v
        |    TriggerMigration.resolve_name(tables, scan) --uses--> Naming.migration_name(pairs, ordinal)
        |                                                           (<=63 or readable_h12[_n])
        +--> TriggerMigration.rerun?(..., sources)   (name-based, unchanged logic)
        |
        v
 migration_content --> TriggerSQL.create_trigger/drop_trigger --uses--> Naming.trigger_name(pair)  (cut to 63)
                       TriggerSQL per-table function (legacy name in 208; validated with role :derived)
        |
        v
 file written under the resolved path

 mix threadline.install [--repo R] [--migrations-path P] --> same MigrationsPath.resolve --> 3 family files
```

### Recommended Project Structure
```
lib/threadline/capture/naming.ex            # NEW, @moduledoc false, pure
lib/threadline/mix/migrations_path.ex       # NEW, @moduledoc false
lib/threadline/storage_schema.ex            # MOD: validate_identifier!/2
lib/threadline/mix/trigger_migration.ex     # MOD: resolve_name via Naming (63-byte cap)
lib/threadline/capture/trigger_sql.ex       # MOD (minimal): trigger names via Naming; :derived validation
lib/mix/tasks/threadline.install.ex         # MOD: OptionParser + MigrationsPath
lib/mix/tasks/threadline.gen.triggers.ex    # MOD: flags, MigrationsPath, --tables rescue
test/threadline/capture/naming_test.exs            # golden literals + unit
test/threadline/capture/naming_property_test.exs   # StreamData properties (async: true)
test/threadline/mix/migrations_path_test.exs       # resolution precedence
test/threadline/release_please_config_contract_test.exs  # or extend changelog_contract_test.exs
```

### Pattern 1: Naming API (pure, parsed-pair in)
**What:** every function accepts a parsed pair `%{schema: s, table: t}`, or a raw string that it parses through `StorageSchema.parse_table_identifier/1`. Hashing always uses `"#{schema}.#{table}"` from the pair, never the raw CLI string.

```elixir
defmodule Threadline.Capture.Naming do
  @moduledoc false
  # Names are frozen into host migrations. Operators can reproduce hash12 in SQL:
  #   left(encode(sha256(convert_to('billing.invoices','UTF8')),'hex'),12)
  alias Threadline.StorageSchema

  @max 63
  @trigger_prefix "threadline_audit_"
  @function_prefix "threadline_capture_changes_"   # 27 bytes
  @migration_prefix "threadline_triggers_"         # 20 bytes
  @legacy_table_max 36                              # 27 + 36 = 63
  @stem_max 23                                      # 27 + 23 + 1 + 12 = 63
  @hash_tail ~r/_[0-9a-f]{12}\z/

  def hash12(input) when is_binary(input),
    do: :crypto.hash(:sha256, input) |> Base.encode16(case: :lower) |> binary_part(0, 12)

  def pair(%{schema: _, table: _} = p), do: p
  def pair(value) when is_binary(value), do: StorageSchema.parse_table_identifier(value)

  def qualified(p), do: (p = pair(p); p.schema <> "." <> p.table)
  def suffix(p), do: (p = pair(p); if p.schema == "public", do: p.table, else: p.schema <> "_" <> p.table)

  def trigger_name(p), do: cut(@trigger_prefix <> suffix(p), @max)
  def legacy_function_name(p), do: cut(@function_prefix <> suffix(p), @max)  # 0.10.x/0.9.x name as PG stored it

  def function_name(p) do
    p = pair(p)
    if p.schema == "public" and byte_size(p.table) <= @legacy_table_max and
         not Regex.match?(@hash_tail, p.table) do
      @function_prefix <> p.table
    else
      @function_prefix <> cut(suffix(p), @stem_max) <> "_" <> hash12(qualified(p))
    end
  end

  defp cut(s, n), do: binary_part(s, 0, min(n, byte_size(s)))
end
```
`[ASSUMED]`: the exact function names and the string-or-pair convenience are discretionary. The formulas follow D-01..D-03 verbatim, and the constants follow from the verified byte counts (the prefix is 27 bytes, confirmed with `byte_size`).

### Pattern 2: Migration name with ordinal (D-06)
`resolve_name/2` keeps its ordinal loop and collision check but gets `{name, module}` from `Naming.migration_name(pairs, ordinal)`. Change its first argument from `suffixes` to **raw tables or pairs**, because the hash needs qualified names. Plain strings such as `"posts"` and `"AuditLog"` parse to public pairs whose suffix is the same string, so the existing `trigger_migration_test.exs` cases (`["posts"]`, `["a","b"]`, `["AuditLog"]`) keep their expected output unchanged.

```elixir
def migration_name(pairs, ordinal) do
  pairs = Enum.map(pairs, &pair/1)
  suffixes = Enum.map(pairs, &suffix/1)
  ord_parts = if ordinal == 1, do: [], else: [Integer.to_string(ordinal)]
  candidate_parts = suffixes ++ ord_parts
  candidate = @migration_prefix <> Enum.join(candidate_parts, "_")

  if byte_size(candidate) <= @max do
    {candidate, module_for(candidate_parts)}                       # byte-identical to today
  else
    h = pairs |> Enum.map(&qualified/1) |> Enum.uniq() |> Enum.sort() |> Enum.join(",") |> hash12()
    ord = Enum.map_join(ord_parts, "", &("_" <> &1))
    room = @max - byte_size(@migration_prefix) - 13 - byte_size(ord)
    readable = suffixes |> Enum.join("_") |> cut(room) |> String.trim_trailing("_")
    {@migration_prefix <> readable <> "_" <> h <> ord, module_for([readable, h] ++ ord_parts)}
  end
end

defp module_for(parts), do: "ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)
```
These example values were computed this session with the formula above: `["customer_subscription_line_items_archive", "billing.invoices"]` → `threadline_triggers_customer_subscription_line_ite_229374fb2418` / `ThreadlineTriggersCustomerSubscriptionLineIte229374fb2418`, hash input `"billing.invoices,public.customer_subscription_line_items_archive"`. Ordinal 2 gives `threadline_triggers_customer_subscription_line_i_229374fb2418_2`. Fifty tables `table_number_1..50` give `threadline_triggers_table_number_1_table_number_2_2e49b0743172` (62 bytes). `[VERIFIED: elixir run this session]` The executor recomputes these before freezing them as golden literals.

An empty `readable` is possible (for example, tables made only of underscores), which gives `threadline_triggers__<h12>`. It is still valid; one unit test covers it.

### Pattern 3: Role-aware validation (D-10)
```elixir
@role_labels %{storage_schema: "storage schema", host_schema: "host schema",
               host_table: "host table", derived: "derived identifier"}

def validate!(value), do: validate_identifier!(value, :storage_schema)  # keep old message text byte-for-byte

@doc false
def validate_identifier!(value, role, input \\ nil)
# :storage_schema keeps invalid_identifier!/1's current message exactly.
# Other roles: "Threadline #{label} #{inspect(v)}#{from} is #{byte_size(v)} bytes; it must be a PostgreSQL
# identifier matching #{@identifier.source} and at most 63 bytes"
# Non-binary values (nil/true/other): same prefix without the byte count.
```
`parse_table_identifier/1` passes `:host_schema`/`:host_table` and the original `value` as `input`, which produces the `(from "…")` fragment. Mark `validate_identifier!` `@doc false`. `StorageSchema` has a public moduledoc, and a documented function would widen public API before 1.0. (This is at Claude's discretion.) The template already contains "and at most 63 bytes", so `~r/at most 63 bytes/` in `trigger_rerun_test.exs:218` still matches.

As an optional low-risk extra, `continuity.ex:89` and `redaction_presenter.ex:35` validate a *host* schema with `validate!/1` (which says "storage schema"). Switch them to `validate_identifier!(v, :host_schema)`.

### Pattern 4: What 208 emits (the 208/209 boundary)
- **Trigger names:** route `create_trigger_sql/2` and `drop_trigger/1` through `Naming.trigger_name/1`. The name is byte-identical whenever it fits (the golden rows prove this), and overflowing names are cut instead of raising, which satisfies "an overflowing derived name never raises" for triggers.
- **Per-table function names:** leave emission on the legacy `"threadline_capture_changes_" <> suffix` (Phase 209 switches to `Naming.function_name/1`). Before calling `StorageSchema.function/2`, validate the base with `validate_identifier!(base, :derived)`. The overflow error then names the derived identifier and its byte count and stays an `ArgumentError`.
- **`per_table_function_fits?/1`:** leave it as is. Phase 209 replaces it.

### Pattern 5: StreamData properties (NAME-05)
```elixir
defmodule Threadline.Capture.NamingPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias Threadline.Capture.Naming

  @first Enum.concat([?a..?z, ?A..?Z, [?_]])
  @rest Enum.concat([?a..?z, ?A..?Z, ?0..?9, [?_]])

  defp ident(max) do
    gen all h <- member_of(@first), t <- string(@rest, max_length: max - 1), do: <<h>> <> t
  end

  defp pair_gen do
    frequency([
      {3, gen(all t <- ident(63), do: %{schema: "public", table: t})},
      {3, gen(all s <- ident(63), t <- ident(63), do: %{schema: s, table: t})},
      {2, long_shared_prefix_pair()},   # 36-byte shared prefix + distinct tails
      {1, hash_tail_table()}            # public table ending _<12 hex>
    ])
  end
  # plus pair-of-pairs generators: `_`-split ({public,"a_b"} vs {"a","b"}), case ({t} vs {String.upcase(t)})
end
```
Properties to assert:
1. `trigger_name`, `function_name`, `legacy_function_name` and the migration name are each ≤ 63 bytes and match `~r/^[A-Za-z_][A-Za-z0-9_]*$/`. The migration **module** matches `~r/^[A-Z][A-Za-z0-9_]*$/` and is ≤ 63 bytes.
2. Determinism: calling twice gives equal output, and `"posts"` gives the same result as `"public.posts"`.
3. `function_name` injectivity: for `p1 != p2` with `hash12(qualified(p1)) != hash12(qualified(p2))`, the function names differ. Use biased pair-of-pairs generators so the `_`-split, case and shared-prefix collisions are actually exercised, not just random.
4. `trigger_name(p) == cut("threadline_audit_" <> suffix(p), 63)` and it starts with `"threadline_audit_"`, which preserves the Health `LIKE` prefix.
5. The migration hash is order-insensitive: `Enum.shuffle(pairs)` gives the same h12 tail when the name overflows.

Keep `max_runs` at the default of 100. Identifiers are at most 63 bytes, so the runtime is milliseconds. `[CITED: hexdocs ExUnitProperties/StreamData API; ASSUMED exact option names string/2 :max_length, member_of/1, frequency/1 — confirm with h StreamData.string at execution]`

### Pattern 6: MigrationsPath + testing with a stub repo
```elixir
defmodule Threadline.Mix.MigrationsPath do
  @moduledoc false
  def resolve(opts) do
    case Keyword.get_values(opts, :repo) do
      [_, _ | _] -> Mix.raise("--repo may be given once; Threadline audit tables live in one repo")
      _ -> :ok
    end
    cond do
      path = opts[:migrations_path] -> path
      name = opts[:repo] -> explicit_repo(Module.concat([name]))
      true -> default_repo_path()
    end
  end
  # explicit_repo: Code.ensure_loaded?/function_exported?(repo, :config, 0) else Mix.raise("could not load repo #{inspect(repo)}")
  # default_repo_path: the install.ex:143-173 body, including `rescue _ -> "priv/repo/migrations"`
end
```
Both tasks parse with `OptionParser.parse(args, strict: [..., migrations_path: :string, repo: :keep], aliases: [r: :repo])`. Using `:keep` lets a repeated `--repo` be detected rather than silently overwritten. The parse happens in the task, and `resolve/1` receives the keyword list.

Tests need no DB and no real Ecto repo. Define a stub in the test file:
```elixir
defmodule Threadline.TestSupport.CustomPrivRepo do
  def config, do: [priv: "priv/custom_repo"]
end
```
There are two cases. `--repo Threadline.TestSupport.CustomPrivRepo` exercises the explicit path. `Application.put_env(:threadline, :ecto_repos, [CustomPrivRepo])`, restored `on_exit`, exercises the realistic default path. The task tests are already `async: false`, which is required because `File.cd!` and app env are VM-wide. Ecto precedent: `ecto.gen.migration` accepts `--migrations-path` and otherwise uses `Path.join(source_repo_priv(repo), "migrations")`, where `source_repo_priv` is `config[:priv] || "priv/#{... Macro.underscore()}"`. `[VERIFIED: deps/ecto_sql 3.14.0 lib/mix/ecto_sql.ex:39-44, lib/mix/tasks/ecto.gen.migration.ex:70]`

### Anti-Patterns to Avoid
- **Hashing the raw CLI string.** Hash `qualified(pair)` only, after trimming and applying the default.
- **Wrapping the whole gen.triggers body in `rescue ArgumentError`.** That turns 209-owned `:derived` errors into `Mix.Error` and breaks `trigger_rerun_test.exs:217`.
- **Citing `file:line` in `lib/` comments.** `source_comment_location_contract_test.exs` forbids it; use `Module.function/arity`.
- **Planning vocabulary in `lib/` or CHANGELOG** (`Phase 208`, `D-02`, `phase_208`). `release_artifact_contract_test.exs` bans these shapes in packaged files.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stable short digest | a custom hash or `phash2` | `:crypto.hash(:sha256, _)` + `Base.encode16` | SQL-reproducible, FIPS-safe |
| Property generation and shrinking | loops over random strings | `ExUnitProperties`/`StreamData` | Shrinking produces minimal counterexamples |
| CLI flag parsing | manual `args` matching | `OptionParser` `strict:` + `:keep` | Existing pattern; catches unknown flags |
| Migration version picking | a timestamp | existing `MigrationVersion.next/2` | Already handles collisions and future dates |

## Common Pitfalls

### Pitfall 1: Asserting trigger-name injectivity
**What goes wrong:** a property "distinct pairs ⇒ distinct trigger names" fails immediately. `public.a_b` and `a.b` both give `threadline_audit_a_b`, and so do overflowing tables that share 46 bytes.
**Why:** D-02 deliberately keeps legacy trigger names, which are unique per table (`tgrelid`, `tgname`), not globally.
**How to avoid:** assert injectivity only for `function_name/1`, given distinct h12. For triggers, assert the exact cut formula.

### Pitfall 2: The existing long-name test expects an ArgumentError
`trigger_rerun_test.exs:217-223` asserts `assert_raise ArgumentError, ~r/at most 63 bytes/` from `Triggers.run` when a per-table function overflows. In 208, keep that path an `ArgumentError`: put the rescue around `--tables` parsing only, and keep the `:derived` template containing "at most 63 bytes". Phase 209 rewrites this test when functions hash.

### Pitfall 3: `Macro.camelize(stem)` vs per-part camelize
`Macro.camelize("a_B") == "A_B"` but `Macro.camelize("a") <> Macro.camelize("B") == "AB"`. `[VERIFIED: elixir run]` D-06 says the fitting stem is "unchanged from today", and today's module name is per-part (`trigger_migration.ex:62`). Keep per-part camelize for both branches (Pattern 2). For all current test inputs the two forms agree, so this is about exactness, not a test break.

### Pitfall 4: `run/1` crosses the 120-line function cap
`gen.triggers` `run/1` is lines 92-192 (101 lines). `source_size_contract_test.exs` enforces `@function_limit 120` and `@file_limit 800`, and allows no new exceptions. Move option parsing, table parsing and write-path logic into `defp`s.

### Pitfall 5: Dialyzer PLT churn from the mix.exs edit
The CI PLT key includes `hashFiles('mix.exs')` (`ci.yml:160`), so adding `:crypto` or `stream_data` causes a cache miss. That costs a rebuild, not a failure. Locally, a red `ci.all` at Dialyzer is usually a PLT miss: run `mix dialyzer --plt` (local-gate memory). Probe result this session: on Elixir 1.17.3, calling `:crypto` without listing it compiled with **no** warning under `--warnings-as-errors`. Listing it is therefore for correct runtime and app-tree inclusion (the locked D-01), not to silence a warning.

### Pitfall 6: rerun? misses newly cut trigger names
After Pattern 4, an overflowing table's migration contains the **cut** trigger name. `rerun?/2` builds the **uncut** `"threadline_audit_" <> suffix`, so a rerun of such a table is not detected, and its generated `down` would drop the trigger. In 0.10.x such tables could not be generated at all (`validate!` raised), so no existing adopter file is affected. Recommendation: have the call site pass the value that `Naming.trigger_name/1` matches. For example, `rerun?/2` takes the full trigger name, or matches the cut name OR the uncut legacy name. It stays name-based, so it is consistent with D-11. See Open Question 1.

### Pitfall 7: 0.9.x lowercased unquoted names (note for 209)
0.9.0 emitted `CREATE TRIGGER threadline_audit_#{table_name}` unquoted (`git show v0.9.0:lib/threadline/capture/trigger_sql.ex:145`), so PostgreSQL case-folded mixed-case names. From 0.10.0 on, names are quoted (commit a837aaca, first tagged v0.10.0). This does not affect 208's byte-identity claim for 0.10.x. Record it for 209's legacy matching.

### Pitfall 8: REL-01 ordering vs. squash landing
The branch lands on `main` as a squash PR, so on `main` the config flip and the `feat` changes arrive in the same commit. release-please reads the config at `main` HEAD when it runs, so `true` is in effect for the proposal either way. The ordering check on the milestone branch is the recorded evidence REL-01 asks for. Semantics: `bump-minor-pre-major` means "BREAKING CHANGE only bumps semver minor if version < 1.0.0", and `bump-patch-for-minor-pre-major` means "feat commits bump semver patch instead of minor if version < 1.0.0". `[CITED: github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]`

## Code Examples

### Golden table (recomputed this session)
The command below printed exactly the D-05 hashes. `shasum -a 256` gave `9bba11019407` for `billing.invoices`, and PostgreSQL 14.17 returned `9bba11019407` for `left(encode(sha256(convert_to('billing.invoices','UTF8')),'hex'),12)`. `[VERIFIED: elixir/shasum/psql this session]`
```
public.posts c6fcf4ae4927
billing.invoices 9bba11019407
public.billing_invoices ee2e817bbf91
public.customer_subscription_line_items_archive 3b9be56c3c45
analytics_reporting.customer_lifetime_value_snapshots 411cf9724315
public.ledger_0123456789ab 6095cae6be06
public.Users 3268e9c3e2ba
public.users 14447575adab
threadline_audit_customer_subscription_line_items_archive 57 | threadline_capture_changes_customer_subscription_l_3b9be56c3c45 63
threadline_audit_analytics_reporting_customer_lifetime_value_sn 70 | threadline_capture_changes_analytics_reporting_cus_411cf9724315 63
threadline_audit_billing_invoices 33 | threadline_capture_changes_billing_invoices_9bba11019407 56
```
(The number after each trigger name is the **uncut** legacy byte size.)

### Truncation evidence (why D-02 is byte-identical)
PG 14.17, `CREATE TABLE` with a 70-byte quoted name: `NOTICE: identifier "XXXX…" will be truncated to "XXXX…"` (63 bytes). This shows that truncation applies to quoted identifiers too. `[VERIFIED: psql this session]` "The system uses no more than NAMEDATALEN-1 bytes of an identifier" `[CITED: postgresql.org/docs/current/sql-syntax-lexical.html]`

### Release config contract test
```elixir
test "pre-1.0 breaking changes propose a minor, not 1.0.0" do
  parsed = "release-please-config.json" |> File.read!() |> Jason.decode!()
  assert parsed["bump-minor-pre-major"] == true
  assert parsed["bump-patch-for-minor-pre-major"] == false
end
```
Put this in `changelog_contract_test.exs`, which already decodes the config at line 152, or in a new small contract file.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Unquoted trigger names; PG truncates and case-folds | Quoted, validated ≤ 63 bytes (raises) | v0.10.0 (a837aaca) | Long names became un-generatable. 208 fixes this with a cut; 209 with hashing |
| `gen.triggers` writes to `priv/repo/migrations` | Repo-resolved path shared with `install` | this phase | Custom `:priv` adopters get migrations in the right directory |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Naming function names and the string-or-pair convenience (`pair/1`, `qualified/1`, `suffix/1`) | Pattern 1 | Low. Internal API, at Claude's discretion |
| A2 | StreamData API option names (`string/2 :max_length`, `member_of/1`, `frequency/1`, `gen all`) unchanged in 1.4 | Pattern 5 | Low. The changelog shows no API breaks; confirm with `h` at execution |
| A3 | `validate_identifier!/2` should be `@doc false` | Pattern 3 | Low. A docs choice |
| A4 | Recommending that 208 route trigger names (not function names) through Naming, plus the rerun? adjustment | Pattern 4 / Pitfall 6 | Medium. The planner may want to confirm it stays within D-11's "name-based" boundary |

## Open Questions (RESOLVED)

1. **RESOLVED — Should `rerun?/2` accept the cut trigger name in 208?** Yes. Adopted by Plan 05 Task 2: `rerun?` stays name-based (D-11) and is passed the cut name from `Naming.trigger_name/1`, with a 50-byte-table rerun test.
   - What we know: D-11 keeps `rerun?` name-based. After Pattern 4, overflowing tables emit cut names that the current regex would not match.
   - What's unclear: whether this counts as part of the 209 rewrite.
   - Recommendation: in 208, pass the cut name (from `Naming.trigger_name/1`) to `rerun?`, which stays name-based, and add one test with a 50-byte table rerun. The alternative is to leave trigger emission raising for overflow until 209, but that violates the "never storage schema" success criterion unless the error is re-labelled `:derived`.
2. **RESOLVED — Where do the SQL-reproduction docs go?** In 208, a source `#` comment block in `lib/threadline/capture/naming.ex` (Plan 04 Task 1) carries the `left(encode(sha256(...)),12)` reproduction for D-01's hash12. Adopter-facing text goes in the upgrade guide with REL-02 in Phase 213. `Naming` is `@moduledoc false`, so its moduledoc is not published. Recommendation: in 208, put a source comment in `naming.ex`. The adopter-facing text belongs in the upgrade guide (REL-02, Phase 213), because 208 emits no hashed name yet.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | everything | ✓ | 1.17.3 / OTP 27 (`.tool-versions`) | — |
| PostgreSQL | `mix test` (test_helper starts the repo and runs migrations even for pure tests) | ✓ | 14.17 on localhost:5432 | — |
| hex.pm network | `mix deps.get stream_data` | ✓ (API reachable) | — | — |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3) + StreamData 1.4 (`ExUnitProperties`) |
| Config file | `test/test_helper.exs` (excludes only `:pgbouncer_topology`) |
| Quick run command | `mix test test/threadline/capture/naming_test.exs test/threadline/capture/naming_property_test.exs test/threadline/mix/ test/threadline/storage_schema_test.exs` |
| Full suite command | `mix verify.test` (then `mix ci.all` at the phase gate) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NAME-01 | 70-byte host table → "host table", value, "70 bytes"; refutes "storage schema" | unit | `mix test test/threadline/storage_schema_test.exs` | ✅ (add cases) |
| NAME-01 | `gen.triggers --tables <70-byte>` raises `Mix.Error` with the same fragments | Mix task | `mix test test/mix/tasks/threadline/gen_triggers_test.exs` | ✅ (add case) |
| NAME-01 | Overflowing trigger name is cut to 63, not raised; fitting names unchanged | unit | `mix test test/threadline/capture/naming_test.exs` | ❌ Wave 0 |
| NAME-01 | Migration name/module ≤ 63, 50-table list, `Users`+`users` ordinal bump, reorder gives same h12 | unit | `mix test test/threadline/mix/trigger_migration_test.exs` | ✅ (add cases) |
| NAME-05 | Golden literal rows (D-05) + multi-table golden | unit | `mix test test/threadline/capture/naming_test.exs` | ❌ Wave 0 |
| NAME-05 | Properties: ≤63, regex, determinism, function injectivity given distinct h12, trigger cut formula | property | `mix test test/threadline/capture/naming_property_test.exs` | ❌ Wave 0 |
| CONF-02 | Resolution precedence (`--migrations-path` > `--repo` `:priv` > underscore > default; repeated `--repo` raises; unloadable `--repo` raises) | unit | `mix test test/threadline/mix/migrations_path_test.exs` | ❌ Wave 0 |
| CONF-02 | Both tasks write to `priv/custom_repo/migrations`; rerun detected there; `--migrations-path` beats `:priv`; unknown install flag raises | Mix task | `mix test test/mix/tasks/threadline/` | ✅ (add cases) |
| REL-01 | `bump-minor-pre-major == true`, patch-for-minor `false` | contract | `mix test test/threadline/changelog_contract_test.exs` (or the new file) | ✅/❌ |
| REL-01 | Config commit precedes every releasable commit | git check (recorded in VERIFICATION) | see below | n/a |

REL-01 ordering check (record the output in the phase verification):
```bash
git log --reverse --format='%h %s' main..milestone/v1.42 | awk '
  /release-please|bump-minor-pre-major/ && !cfg {cfg=NR; print "CONFIG " $0}
  /^[0-9a-f]+ (feat|fix|perf|deps)(\([^)]*\))?!?:/ && !rel {rel=NR; print "FIRST-RELEASABLE " $0}
  END { exit !(cfg && (!rel || cfg < rel)) }'
# More robust: locate the commit by file:
git log --reverse --format=%h main..milestone/v1.42 -- release-please-config.json | head -1
```

### Sampling Rate
- **Per task commit:** the quick run command (properties at 100 runs take well under a second).
- **Per wave merge:** `mix verify.test`
- **Phase gate:** `mix ci.all` green (run `mix dialyzer --plt` first if the PLT missed) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/threadline/capture/naming_test.exs`: golden rows and unit edges (empty readable, hash-tail exclusion, `Users`/`users`)
- [ ] `test/threadline/capture/naming_property_test.exs`: StreamData properties, `async: true`
- [ ] `test/threadline/mix/migrations_path_test.exs`: precedence, with a stub repo module
- [ ] Framework install: `{:stream_data, "~> 1.4", only: :test}` + `mix deps.get` (commit `mix.lock`)

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no (generation-time tooling) | — |
| V5 Input Validation | yes | `@identifier` regex + 63-byte check in `StorageSchema.validate_identifier!/2`, with every DDL identifier double-quoted via `quote_ident/1` |
| V6 Cryptography | yes (non-security use) | `:crypto` SHA-256, used as a naming digest, not a secret. No hand-rolled hashing |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL/DDL injection via `--tables` | Tampering | Regex validation before quoting; this phase keeps it and improves the message |
| Cross-table capture-function sharing (a redaction leak) through truncated names | Information disclosure | Format frozen here (D-03 hash); emission in 209. The property proves injectivity |
| Writing migrations to an unexpected directory | Tampering | Explicit precedence; no loading of `--repo` when `--migrations-path` is given |

## Sources

### Primary (HIGH confidence)
- In-repo reads this session: `lib/threadline/storage_schema.ex`, `lib/threadline/capture/trigger_sql.ex` (1-220), `lib/threadline/mix/trigger_migration.ex`, `lib/mix/tasks/threadline.install.ex`, `lib/mix/tasks/threadline.gen.triggers.ex`, `mix.exs` (48-125), `release-please-config.json`, `config/test.exs`, `test/threadline/{dep_floor_guard,source_size_contract,source_comment_location_contract,zero_skips_contract,public_surface_contract,layer_boundary_contract}_test.exs`, `test/threadline/capture/trigger_rerun_test.exs` (105-260), and the install/gen_triggers/trigger_migration/storage_schema tests
- `deps/ecto_sql` 3.14.0: `source_repo_priv/1` and `ecto.gen.migration --migrations-path`
- hex.pm API: stream_data releases and Elixir requirements
- Local probes: `:crypto` vs `shasum` vs PG 14.17 `sha256`; PG identifier truncation NOTICE; `Macro.camelize` edge cases; `:crypto` compile-warning probe

### Secondary (MEDIUM confidence)
- release-please manifest-releaser docs (`bump-minor-pre-major` semantics)
- stream_data CHANGELOG (v1.2 to v1.4)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. Versions and the floor were verified against hex.pm and the repo's floor guard.
- Architecture: HIGH. The decisions are locked, and the integration points were read line by line.
- Pitfalls: HIGH. Each is tied to a specific file/line or a probe run this session.

**Research date:** 2026-09-25
**Valid until:** 2026-10-25 (stable domain; recheck the stream_data version if planning slips)
