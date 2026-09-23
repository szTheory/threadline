# Configuration and command reference

Use this page when you need the exact application configuration Threadline
reads. These settings are global to the `:threadline` application; pass
operation-specific options directly to a public function when that function
offers them.

The reference separates literal application keys from adapter-module options.
That distinction matters: literal keys select Threadline behavior, while a
configured adapter owns the options stored under its module name.

## Runtime configuration

The following fourteen keys are Threadline's supported application-environment
contract. An omitted key has the default or absence behavior stated here.

| Key | Purpose and accepted shape | Default or absence behavior | Primary owner |
| --- | --- | --- | --- |
| `config :threadline, ecto_repos: [MyApp.Repo]` | A non-empty list of Ecto repository modules. The first repository is the fallback used by Threadline's runtime and Mix tasks; explicit `repo:` options still take precedence where offered. | `[]`; repository-dependent runtime children are not started, and commands that require a repository raise with setup guidance. | `Threadline` and [Getting Started](getting-started-saas.md) |
| `config :threadline, retention: [...]` | A keyword list for the global retention policy and its supervised pruner. Set `enabled: true` and exactly one positive `keep_days:` or `max_age_seconds:` value before destructive purge is allowed. `delete_empty_transactions:` defaults to `true`; runtime scheduling accepts `interval_ms:` and `sleep_ms:`. | `[]`; scheduled pruning is disabled and `Threadline.Retention.purge/1` returns `{:error, :disabled}`. When enabled, the pruner interval is 60 minutes and its between-batch sleep is 50 ms unless overridden. | `Threadline.Retention.Policy`, `Threadline.Retention`, and [Production Checklist](production-checklist.md) |
| `config :threadline, exports: [...]` | A keyword list for export lifecycle timing. `retention_ttl_hours:` controls terminal export expiry; `cleanup_interval_ms:` controls cleanup cadence; `stale_running_cutoff_hours:` controls when an abandoned running export is marked failed. | `[]`; terminal exports expire after 168 hours, cleanup runs every 60 minutes, and running jobs are considered abandoned after 24 hours. | `Threadline.Export` and [Operator Surface](operator-surface.md) |
| `config :threadline, trigger_capture: [...]` | A keyword list or map whose `tables:` map configures capture-time `exclude:`, `mask:`, `mask_placeholder:`, `store_changed_from:`, and `except_columns:` rules per host table. Redaction is applied when trigger SQL is generated, not dynamically on each write. | Missing configuration normalizes to an empty table map, so trigger generation uses no per-table capture overrides. | [Domain Reference](domain-reference.md) and [Getting Started](getting-started-saas.md) |
| `config :threadline, verify_coverage: [...]` | A keyword list with a non-empty `expected_tables:` list of table-name strings. It defines the positive list checked by the coverage verification task. | Missing, malformed, or empty configuration causes the verification task to raise instead of passing vacuously. | `Threadline.Verify.CoveragePolicy` and [Production Checklist](production-checklist.md) |
| `config :threadline, storage_adapter: MyApp.AuditStorage` | A module implementing `Threadline.Storage`. Threadline validates the adapter at application startup and uses it for background export persistence and delivery. | `Threadline.Storage.Local`. | `Threadline.Storage`; adapter details are documented under [Adapter-module options](#adapter-module-options) |
| `config :threadline, health: [...]` | A keyword list accepted by `Threadline.Health.Policy`: `expected_uncovered_tables:` adds intentionally uncovered tables and `audit_anyway:` removes names from that set. Both values are duplicate-free lists of strings. | `[]`; only Threadline's built-in `schema_migrations` expected-uncovered baseline applies. | `Threadline.Health`, `Threadline.Health.Policy`, and [Operator Surface](operator-surface.md) |
| `config :threadline, coverage_poll_ms: 30_000` | A positive integer number of milliseconds between trigger-coverage refreshes in the mounted operator surface. | `30_000`. | [Operator Surface](operator-surface.md) |
| `config :threadline, operator_surface_embed_fonts: false` | A boolean controlling whether the operator surface embeds its bundled webfonts as data URIs. | `true`; bundled fonts are embedded. `false` uses the documented system-font fallback chains. | [Operator Surface](operator-surface.md) |
| `config :threadline, export_status_poll_ms: 5_000` | A positive integer number of milliseconds between background-export status refreshes in the mounted operator surface. | `5_000`. | [Operator Surface](operator-surface.md) |
| `config :threadline, export_queue_adapter: MyApp.AuditExportQueue` | A module implementing `Threadline.ExportQueue`. Threadline validates it at application startup and uses it to enqueue background exports. | `Threadline.ExportQueue.TaskAdapter`. | `Threadline.ExportQueue`; adapter details are documented under [Adapter-module options](#adapter-module-options) |
| `config :threadline, retention_poll_ms: 5_000` | A positive integer number of milliseconds between retention-history refreshes in the mounted operator surface. | `5_000`. | [Operator Surface](operator-surface.md) |
| `config :threadline, operator_surface_embed_scripts: false` | A boolean controlling the operator surface's inline, dependency-free copy helper. | `true`; the copy helper is embedded. `false` removes the script and presents identifiers for native text selection. | [Operator Surface](operator-surface.md) |
| `config :threadline, storage_schema: "audit"` | A PostgreSQL identifier naming the schema that stores Threadline-owned tables and functions. Strings and atoms are accepted after identifier validation. | `"threadline"`. Use `"public"` only as an explicit host choice. | `Threadline.StorageSchema` and [Getting Started](getting-started-saas.md) |

## Advanced operator polling

The three polling keys control browser-facing LiveView refreshes only:

```elixir
config :threadline, coverage_poll_ms: 30_000
config :threadline, export_status_poll_ms: 5_000
config :threadline, retention_poll_ms: 5_000
```

Set each to a positive integer number of milliseconds. These values do not
change retention-pruner cadence, export cleanup cadence, or queue execution.
Those schedules live in the `:retention` and `:exports` keyword lists described
above. Polling test hooks and socket assigns are internal implementation details,
not router mount options.

## Adapter-module options

After selecting an adapter with `:storage_adapter` or `:export_queue_adapter`,
Threadline reads a keyword list stored under that adapter module. This is a
separate dynamic key class, not another literal atom key.

For example, the built-in S3 adapter requires a bucket:

```elixir
config :threadline, storage_adapter: Threadline.Storage.S3
config :threadline, Threadline.Storage.S3, bucket: "my-audit-exports"
```

The built-in Oban queue adapter accepts `:oban_name`, `:queue`, and
`:worker_mod` options:

```elixir
config :threadline, export_queue_adapter: Threadline.ExportQueue.Oban

config :threadline, Threadline.ExportQueue.Oban,
  oban_name: Oban,
  queue: :threadline_exports
```

A custom adapter owns and documents its own keyword options. Threadline passes
those options to the adapter's `init/1` callback during application startup.
Use the public `Threadline.Storage` and `Threadline.ExportQueue` behaviours as
the implementation contracts; do not depend on another adapter's private
options.

## Commands available to host projects

Adding Threadline as a dependency makes these ten Mix tasks available to the
host project. Run them from the host project's root so they load its
configuration and dependencies.

| Command | Use it to | Implementation owner |
| --- | --- | --- |
| `mix threadline.install` | Generate the migration that creates Threadline's audit schema. | `Mix.Tasks.Threadline.Install` |
| `mix threadline.gen.triggers` | Generate an Ecto migration that installs capture triggers on selected host tables. | `Mix.Tasks.Threadline.Gen.Triggers` |
| `mix threadline.verify_coverage` | Fail a CI or deployment check when a table in `:verify_coverage` is missing or uncovered. | `Mix.Tasks.Threadline.VerifyCoverage` |
| `mix threadline.health.coverage` | View trigger coverage, as a table or JSON, without turning uncovered tables into a failing policy gate. | `Mix.Tasks.Threadline.Health.Coverage` |
| `mix threadline.continuity` | Inspect and establish the explicit starting boundary for capture in an existing database. | `Mix.Tasks.Threadline.Continuity` |
| `mix threadline.retention.purge` | Preview or execute the configured batched retention purge. Preview before using `--execute`. | `Mix.Tasks.Threadline.Retention.Purge` |
| `mix threadline.export` | Export captured audit rows to CSV or JSON using the same filter vocabulary as the timeline API. | `Mix.Tasks.Threadline.Export` |
| `mix threadline.incident` | Show the changes and context linked to one audit transaction, in human-readable or JSON form. | `Mix.Tasks.Threadline.Incident` |
| `mix threadline.evidence.show` | Show the latest or historical Threadline evidence records and proof classifications. | `Mix.Tasks.Threadline.Evidence.Show` |
| `mix threadline.policy.show` | Compare configured capture redaction with the trigger policy deployed in PostgreSQL. | `Mix.Tasks.Threadline.Policy.Show` |

These tasks are the supported command interface for adopters. Their module
pages and the linked guides define their options and safety boundaries.

## Commands for this repository

Mix aliases belong to the project that defines them. Therefore none of the
aliases below is installed into a host application when it adds Threadline as a
dependency. They are supported contributor commands only when working in the
Threadline repository.

| Repository alias | Repository purpose |
| --- | --- |
| `mix verify.format` | Check the formatter-owned source tree. |
| `mix verify.credo` | Run the repository's Credo policy. |
| `mix verify.dialyzer` | Run the configured Dialyzer analysis without rebuilding the PLT. |
| `mix verify.test` | Run the root ExUnit suite. |
| `mix verify.threadline` | Run the configured positive-list trigger-coverage gate. |
| `mix verify.doc_contract` | Run public documentation contract tests. |
| `mix verify.release` | Validate the clean, taggable release shape, documentation, and Hex archive. |
| `mix verify.topology` | Invoke the repository-only PgBouncer topology task. |
| `mix verify.example` | Compile and test the Phoenix reference application. |
| `mix verify.example_browser` | Run the reference application's voting browser projects. |
| `mix verify.example_browser_light` | Run the focused light/system-theme browser lane. |
| `mix verify.operator_stress` | Run the operator-surface stress browser specification. |
| `mix verify.mechanical` | Check deterministic operator-surface mechanical constraints. |
| `mix verify.critic_trust` | Check the committed, deterministic critic-trust evidence without calling an LLM. |
| `mix verify.hex_evaluator` | Compile, migrate, and test the isolated Hex evaluator. |
| `mix verify.bench` | Run the repository benchmark scripts. |
| `mix verify.compile_no_optional` | Compile without optional dependencies and treat warnings as errors. |
| `mix verify.xref_cycles` | Fail if any compile-connected cycle exists between modules. |
| `mix verify.flake` | Re-run tests with fresh seeds until a failure appears or the repeat limit is reached. |
| `mix test.setup` | Prepare example dependencies, then run the root test setup path. |
| `mix test.reset` | Recreate the root test database before running setup. |
| `mix ci.all` | Run the complete local equivalent of the required CI gates. |

**mix threadline.verify_topology** is also repository-only. It requires the
repository's PgBouncer test topology and is not part of the adopter command
contract.

## Maintainer-only commands

The following tools are shipped from source today but are not supported adopter
or contributor interfaces. They operate on maintainer evidence, local
credentials, or a repository-specific capture corpus:

- **mix critic.measure**
- **mix critic.synth**
- `mix verify.ui_critique`
- `mix verify.capture`
- `mix verify.operator_component_contracts`

There are no additional internal Mix tasks or aliases in the current source
inventory. Adding a task or alias requires placing it in exactly one of these
classes and updating this reference.

## Next steps

- [Adopt Threadline through the canonical first-hour path](getting-started-saas.md).
- [Configure and operate the mounted audit surface](operator-surface.md).
- [Review the production-readiness checklist](production-checklist.md).
