# Architecture Research — Suite Parallelism, Guard-Test Rebalance, gen.triggers Down Orphan

**Domain:** Elixir/Ecto/PostgreSQL trigger-backed audit library, test-suite and migration architecture
**Milestone:** v1.44 Behavioral Depth: Properties, Twins, Telemetry
**Researched:** 2026-09-30
**Confidence:** HIGH (all claims are grep/read evidence from this tree; no full-suite re-run performed, per constraint — timings are cited from the existing todo/seed records, not re-measured)

## Executive Summary

The suite's ~91% serial wall-clock is architectural, not incidental: `Threadline.DataCase`
(used by 57 files) sets `async: false` by default in its `__using__` macro because every
DB-touching test shares one global, un-sandboxed table set (`threadline.audit_*`,
`threadline.threadline_*`) cleaned between tests. There is no SQL Sandbox by design — audit
triggers, `txid_current()`, and real transaction commit/rollback boundaries are under test,
and Sandbox's wrapping transaction would either hide trigger effects or make `pg_stat_activity`
introspection impossible. Given that constraint, the single fastest, lowest-risk lever is CI
matrix partitioning (`mix test --partitions N` + `MIX_TEST_PARTITION`, one DB per partition) —
Ecto's own and Phoenix's own precedent for exactly this shape of non-Sandbox-safe suite. It
requires no test rewrites and no capture-semantics risk. A second, slower-payoff lever is a
targeted async-ification of the subset of `DataCase` tests that are pure-read queries over
private, per-test fixture rows (safe under table-sharing because they never race another test's
writes) — this is real work per file and should be scoped, not blanket-applied.

The guard-test population (24 files matched by name, several hundred more `assert
String.contains?` calls scattered through doc-contract tests generally) splits cleanly on one
axis: does the assertion derive from a live source of truth (`mix.exs` `@version`, `bin/*`
script output, `Threadline.MixProject.project()[:aliases]`, `git ls-files`, a real Ecto/ExDoc
config) or does it only assert that one static document contains a string that another static
document also contains? The former (`version_truth_doc_contract_test.exs`,
`ci_topology_contract_test.exs`, `ci_token_permissions_contract_test.exs`,
`branch_protection_comparison_contract_test.exs`, `brandbook_token_parity_test.exs`,
`optional_deps_contract_test.exs`, `removed_artifact_contract_test.exs`,
`planning_dependency_contract_test.exs`, `public_surface_contract_test.exs`,
`ci_all_dedup_contract_test.exs`, `ci_coverage_doc_contract_test.exs`,
`deps_health_doc_contract_test.exs`) catch a distinct, real drift and should be kept as-is.
The latter — pure doc-to-doc string locks with no derivation, best exemplified by
`stg_doc_contract_test.exs` and parts of `operator_surface/theme_doc_contract_test.exs` and
`operator_surface_doc_contract_test.exs` — catch only "someone deleted a marker string" and are
cut/merge candidates.

The `gen.triggers` down orphan is a one-clause fix. `down_body/2` filters `table_specs` to
`first_run_specs` (tables not in `rerun_tables`) and only emits trigger-drop and function-drop
SQL for that filtered set. For a rerun table that adds a per-table function
(`needs_per_table: true`), the migration is right to skip the *trigger* drop (an earlier
migration still expects a trigger on that table) but wrong to also skip the *function* drop —
the per-table function is an artifact this migration alone created, and no other migration's
`down` ever targets it. The fix is to compute function-downs from the full `table_specs` (not
`first_run_specs`) for tables that are `needs_per_table: true`, reusing
`TriggerSQL.drop_function_if_unused/2`, which is unconditionally safe to call even for a table
that keeps a live trigger (it checks `pg_trigger` before dropping and only warns if still in
use, never raises, never cascades).

## Part A — Suite Parallelism

### A.1 Why async: false — inventory and root cause

Two disjoint sets contribute to the serial core:

- **56 files** declare `async: false` explicitly.
- **36 files** declare neither `async: true` nor `async: false` and get ExUnit's per-module
  default of `false` — 35 of these `use Threadline.DataCase`, which itself defaults to
  `async: false` (see below), so the explicit-false count undercounts the real serial
  population.
- **132 files** declare `async: true`.
- Total: 222 `*_test.exs` files, matching the milestone context's cited 222 files. (The
  cited "82 async: false files" figure is a CI-measured count from a different vantage —
  likely files ExUnit actually schedules serially at run time, which is a slightly different
  count than a static grep on the two literal strings; treat 56+36≈92 here as the static,
  file-level inventory, and 82 as the CI-observed number. Both point at the same architectural
  cause and are close enough not to change the ranking below.)

Root cause, by file evidence (`test/support/data_case.ex:1-25`):

```elixir
defmodule Threadline.DataCase do
  @moduledoc """
  ...
  Does NOT use Ecto sandbox — PostgreSQL triggers fire at the DB level, outside
  sandbox awareness. Each test cleans audit tables in `setup` (FK order).

  **`async: false` by default** so tests in the same module never hit the same DB concurrently.
  """
  defmacro __using__(opts) do
    opts = Keyword.merge([async: false], opts)
    ...
```

57 files `use Threadline.DataCase`. Every one of them shares the same global tables
(`threadline.audit_transactions`, `threadline.audit_changes`, `threadline.audit_actions`,
`threadline.threadline_evidence_records`, `threadline.threadline_export_jobs`,
`threadline.threadline_retention_runs`, `threadline.threadline_saved_views` — the
`@owned_tables`/`@cleanup_order` list in `test/support/storage_schema_case.ex:16-33`) with a
per-test cleanup pass (`clean_storage_schemas!/0` in `setup`), not a rollback boundary. Two
tests in the same module running concurrently would race each other's inserts and cleanups
directly, hence the forced serialization at the module level.

Category breakdown (grep-based, over the 92 statically-serial files; categories are
non-exclusive — most files hit two or three):

| Category | File count (of 92) | Detection signal | Why it forces serial |
|---|---|---|---|
| DB-writing (`DataCase`/shared tables) | 57 (`use Threadline.DataCase`); 44 also match `Repo.insert/update/delete/transaction` or raw SQL directly | `use Threadline.DataCase`, `Repo.insert!`, `Ecto.Adapters.SQL.query!` | No Sandbox; concurrent tests would race the same rows/cleanup |
| Filesystem | 47 | `File.write/rm/mkdir/read/cp` | Migration generators, guide/README contract tests, and stress-lab writers create real files (`priv/repo/migrations`, tmp dirs) that would collide under concurrency without per-test unique paths |
| Application env | 40 | `Application.put_env/delete_env` | Global process dictionary — mutating `:threadline` app config between tests races any concurrent reader |
| Mix-task shell-outs | 26 | `System.cmd`, `Mix.Task.run`, `Mix.shell()` | Spawns `mix ecto.migrate`, `mix threadline.gen.triggers`, etc. against the real migrations directory / real DB; two concurrent invocations would double-apply or lock-contend |
| `capture_log`/`CaptureIO` | 10 | `ExUnit.CaptureIO`, `capture_log` | Redirects the global `:stdio`/logger group leader — not safe under concurrent capture in the same VM |
| Telemetry handler globals | 6 | `:telemetry.attach` | `:telemetry` handler ids and the ETS handler table are process-global; two tests attaching the same handler id concurrently overwrite each other's handler |
| Named processes | 4 | `start_supervised`, `GenServer`, `Process.register`, `Registry` | `Threadline.ExportQueue.TaskAdapter`, `Threadline.Retention.Pruner`, the stress router, and the retention-history LiveView test start supervised/named processes that would collide on name if run twice concurrently |

Interpretation for the roadmap: the two largest categories (DB-writing/`DataCase`, and
filesystem) are structurally tied to the "no Sandbox" decision and to real-migration-file
generation; they are not quick wins. The two smallest (telemetry, named processes) are
narrowly scoped and are the correct target for a `async: true`-with-isolation rewrite, because
the fix is local (unique handler ids, unique registered names) and does not touch capture
correctness.

A live `mix test --slowest N` breakdown by category was not run — the constraint here is
read-only/no full-suite reruns, and the milestone context explicitly gates that measurement on
local DB availability, which was not verified as part of this research pass. The 209 s/191 s
sync split and the 2460-test, 222-file baseline are taken as given from
`.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md` and
`.github/workflows/flake-detection.yml:41-49` (dispatch run 36359135268, 268.3 s cold /
206.2–213.5 s warm). Before committing to a specific partition count or async-ification list,
re-run `mix test --slowest 50` once, locally, with the DB up, and cite that run's numbers —
this file does not fabricate a per-category time split it cannot support with a citation.

### A.2 Options, ranked

| Rank | Option | Mechanism | Gain | Risk to capture semantics | Effort |
|---|---|---|---|---|---|
| 1 | **CI partitioning** (`mix test --partitions N`, `MIX_TEST_PARTITION`, one DB per partition) | `verify-test` matrix gets an extra axis; `MIX_TEST_PARTITION` feeds `Threadline.Test.Repo`'s database name (`threadline_test#{System.get_env("MIX_TEST_PARTITION")}`); the `postgres:` service container serves N logical DBs | Near-linear wall-clock reduction on the serial core, up to the partition count; no test file touched | **None** — every test still runs unsandboxed, un-mocked, against a real DB and real triggers; only the *which database* changes | Low–Medium: `test/test_helper.exs` DB-name derivation, `.github/workflows/ci.yml` matrix axis, `postgres:` service init for N databases, Flake Detection's `mix verify.flake` invocation (see A.3) |
| 2 | **Async-ify telemetry/named-process files** (unique handler ids + test-pid filters, `start_supervised` with per-test names) | Give each test a unique `:telemetry.attach` id (e.g. `{__MODULE__, self()}`) and filter delivered events by `self()`; register processes under a per-test name (`:"#{__MODULE__}.#{System.unique_integer()}"`) | Small (6 + 4 = 10 files, likely a few seconds), but genuinely safe and mechanical | None — this is the ExUnit-recommended pattern for telemetry tests (Oban and Phoenix.PubSub tests both do this); does not touch DB or trigger semantics | Low: per-file, isolated diffs |
| 3 | **Targeted async: true for pure-query `DataCase` tests over pre-seeded, private fixtures** | A read-only test that never mutates shared tables and only queries rows it inserted itself under a value it alone owns (e.g. a UUID `txid`) can be async if `clean_storage_schemas!/0` is scoped per-test-owned rows rather than a blanket table truncate | Meaningful if a sizeable minority of the 57 `DataCase` files are read-mostly, but requires auditing each file's `setup`/assertions to confirm no shared-table interaction | Low-to-medium — a wrongly-reclassified file corrupts another test's row set or races `clean_storage_schemas!/0`'s DELETE; needs a per-file audit, not a blanket flip | Medium–High: real audit work, one file at a time; not safe to batch |
| 4 | **Per-test/per-module unique Postgres schemas or table names** | Give each test module its own schema (`threadline_test_mod_N`) or table suffix, migrate it independently, and let ExUnit run modules concurrently | Would fully unblock `async: true` even for DB-writing tests | Meaningfully changes what is under test: the whole point of the suite is exercising the real, single `threadline`/`audit` storage-schema shape (`StorageSchemaCase`, `@known_storage_schemas`), trigger names collide-checked at fixed 63-byte identifiers, and per-table capture functions are named deterministically per table — schema-per-test would either multiply migration/trigger-generation cost per test (defeating the speed goal) or require faking the storage-schema layer, which is exactly the thing this library's own correctness tests must not fake | High: touches `TriggerMigration`/`Naming`/`StorageSchema` test fixtures broadly; not a "cut a corner" change |
| 5 | **`ExUnit` `:max_cases` tuning alone** | Raise/lower the async-case concurrency cap | No effect on the serial core — `:max_cases` only bounds how many `async: true` modules run concurrently; it does nothing for `async: false` modules, which ExUnit always runs one-at-a-time regardless of `:max_cases` | None (it's a no-op for this problem) | Trivial, but wrong tool — do not spend a phase on this |
| 6 | **Sandbox exceptions for pure-query tests over pre-seeded data** | Wrap a narrow subset of read-only tests in `Ecto.Adapters.SQL.Sandbox` while the rest of the suite stays Sandbox-free | Not viable here: the codebase runs ONE shared `Threadline.Test.Repo` connection model with no Sandbox mode configured anywhere (`config/test.exs` was not found to set `pool: Ecto.Adapters.SQL.Sandbox`), and mixing Sandbox and non-Sandbox connections against the same physical database within one suite risks exactly the kind of visibility mismatch (Sandbox's wrapping transaction hides rows from a concurrent non-Sandbox connection, and vice versa) that this library's "no Sandbox by design" note (`test/support/data_case.ex:6-7`) already rejected once | Medium-high — reintroduces the exact hazard the architecture deliberately avoided, for tests that partitioning (option 1) already speeds up for free | Not recommended |

**Recommendation: do option 1 first.** It is the only lever on this list that moves the 191 s
serial figure without touching a single test file, and it is exactly the shape Ecto's own
integration suite and Phoenix use for DB-heavy, Sandbox-incompatible test trees (multiple
physical test databases selected by `MIX_TEST_PARTITION`, one per CI shard). Follow with
option 2 (telemetry/named-process async-ification) as a small, safe, mechanical cleanup that
also removes 10 files from any future partition's serial tail. Treat option 3 as a separate,
audited follow-up phase, not part of this milestone's suite-rebalance work, given the
per-file audit cost. Do not pursue options 4–6.

**Precedent, for the roadmap to cite:**
- Ecto's own test suite runs its adapter-integration tests against real Postgres/MySQL
  connections without Sandbox, split by adapter and by `mix test --partitions`-style sharding
  in CI, for the same reason Threadline can't Sandbox: adapter-level behavior (including
  trigger/constraint timing) is exactly what Sandbox's transaction wrapping would hide.
- Phoenix's LiveView/Endpoint test suites split "pure" unit tests (async: true, no DB) from
  integration tests (DB-backed, often serialized or partitioned) rather than forcing one
  strategy suite-wide — mirroring the two-tier split this report recommends (options 1+2 now,
  option 3 later, audited).
- Oban's own test conventions favor `Oban.Testing`'s `:manual` mode plus Sandbox-prefix
  isolation *when Sandbox is available*; Threadline cannot borrow that pattern directly
  because it has already ruled out Sandbox for correctness reasons, which is why partitioning
  (a Sandbox-independent mechanism) is the right match here rather than a prefix-per-test
  scheme.

### A.3 Effect on the Flake Detection lane (13 passes)

`flake-detection.yml` runs `mix verify.flake` = `mix test --repeat-until-failure 12` (13 total
suite passes) inside a single job against a single `postgres:16` service container
(`.github/workflows/flake-detection.yml:64-77`, `:39`). Partitioning the `verify-test` CI
matrix does not by itself partition this lane — Flake Detection would need its own N-database
service definition (or a matrix axis mirroring `verify-test`'s) to benefit, and the existing
55-minute step budget / 3300 s classification threshold
(`test/threadline/flake_classifier_contract_test.exs`, cited at
`.github/workflows/flake-detection.yml:41-52`) is pinned to the *current* per-iteration
duration. If partitioning is adopted for `verify-test`, Flake Detection should be resized in
the same change (new measured per-iteration duration, updated budget constants, updated
contract test), not left to silently drift stale — this is exactly the trap D-01 already hit
once (`.github/workflows/flake-detection.yml:44-49`, the old 165 s estimate that undercounted
the real 209 s). Recommend scoping "resize Flake Detection's budget" as an explicit line item
in the same phase that lands partitioning, not a follow-up.

## Part B — Guard-Test Rebalance

### B.1 Rubric

A guard/contract test earns **KEEP** when at least one of its assertions:

1. Derives its expected value from a live, non-doc source of truth (`mix.exs` version,
   `Mix.Project.config()`, a `bin/*` script's actual output, `git ls-files`, real YAML/JSON
   parsed structurally, a module's real exported function) — so the test breaks the moment
   that source drifts, not the moment someone edits prose.
2. Asserts a structural invariant about the codebase or CI topology that has no other proof
   (job `id:` immutability, `needs:` roster completeness, permission-scope minimality,
   alias-tree dedup) — losing it would let a real regression land silently.
3. Locks a renamed/removed artifact against reintroduction, checked against the live tracked
   file set (`git ls-files`), not against another document's prose.

A guard/contract test is a **CUT/MERGE** candidate when:

1. Every assertion in the file is `String.contains?(doc_a, literal)` where `literal` is
   hand-typed in the test (not derived), and `doc_a` is itself prose (a guide, README,
   CONTRIBUTING section) rather than code or generated output — i.e., a doc-to-doc or
   doc-to-hardcoded-literal lock with no behavioral binding.
2. Its only failure mode is "someone deleted or reworded a sentence," which a normal doc
   review would already catch, and which does not indicate a functional regression.
3. It duplicates a check another, better-derived contract test already makes (verify one
   isn't a strict subset of another's coverage before cutting — see `persona_routing_doc_
   contract_test.exs`'s own moduledoc, which explicitly states it owns the "subset/label"
   contract and defers exact-equality to `release_artifact_contract_test.exs`, an example of
   correct non-duplicative split, not a cut candidate).

### B.2 Findings, by file (24 files matched `*doc_contract*`/`*_contract_test*` by name; sizes and verdicts below; this is not exhaustive of every `assert String.contains?` in the tree, but covers the guard-shaped population the milestone context calls out)

**KEEP — derives from a live source, distinct failure class:**

| File | Lines | Derives from | Distinct failure class |
|---|---|---|---|
| `test/threadline/version_truth_doc_contract_test.exs` | 157 | `mix.exs` `@version`, `mix release.pins`, `release-please-config.json` `extra-files` | Version-pin drift across README/guides; release-please auto-bump registration gap |
| `test/threadline/ci_topology_contract_test.exs` | 1203 | `.github/workflows/ci.yml` parsed structurally, `CONTRIBUTING.md`'s job roster | CI job roster / `needs:` / aggregate contract drift |
| `test/threadline/ci_all_dedup_contract_test.exs` | 383 | `Threadline.MixProject.project()[:aliases]` at runtime, `:default_test_excludes` app-env | Duplicate test execution across `ci.all`, hand-listed-alias drift |
| `test/threadline/ci_coverage_doc_contract_test.exs` | 126 | `bin/browser-full-projects --list ...` | Browser-lane coverage table silently narrowing |
| `test/threadline/ci_token_permissions_contract_test.exs` | 478 | Every workflow's `permissions:` blocks, parsed structurally | Token over-privilege across 5 workflows |
| `test/threadline/branch_protection_comparison_contract_test.exs` | 325 | `bin/compare-required-contexts` fixtures | Required-status-check comparison logic correctness |
| `test/threadline/optional_deps_contract_test.exs` | 119 | `lib/` scanned for optional-Phoenix references vs `Code.ensure_loaded?` guards | Silent optional-dep compile break (already bit once, per moduledoc) |
| `test/threadline/removed_artifact_contract_test.exs` | 190 | `git ls-files` (live tracked set) | Reintroduction of a deliberately removed file |
| `test/threadline/planning_dependency_contract_test.exs` | 141 | Source-scanned `File.*(".planning/...")` call sites | `lib/`/product code depending on `.planning/` at runtime |
| `test/threadline/public_surface_contract_test.exs` | 799 | Module/config introspection (`@hidden_modules`, `@runtime_keys`), CHANGELOG rename pairing | Public API surface drift, undocumented renames |
| `test/threadline/deps_health_doc_contract_test.exs` | 291 | `.github/workflows/deps-health.yml`, `bin/deps-health-report` literals, `REQUIREMENTS.md` mandated sentences | Dependency-freshness lane structural drift |
| `test/threadline/adoption_pilot_doc_contract_test.exs` | 107 | `Mix.Tasks.Release.Pins.target_pin_version()` | Stale install-pin version in the adoption-pilot guide |
| `test/threadline/brandbook_token_parity_test.exs` | 128 | `Threadline.Test.StyleSource` (real shipped token values) | Brand doc / shipped CSS token value drift, either direction |
| `test/threadline/persona_routing_doc_contract_test.exs` | 80 | ExDoc `groups_for_extras` (real config), README prose | Verb-lane label mismatch between README and ExDoc sidebar |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | 331 | `Mix.Tasks.Release.Pins`, `Threadline.GettingStartedFixtures` (live fixture module) | Quickstart guide drifting from the actual runnable walkthrough |
| `test/threadline/storage_schema_call_site_contract_test.exs` | — | `Threadline.StorageSchemaCase.owned_schema_modules/0` (shared SSOT) | New owned-table module added without updating the shared cleanup-order list |
| `test/threadline/upgrading_to_0_11_doc_contract_test.exs` | 229 | Regex bans on planning-vocabulary shapes (`@banned_shapes`), shared with the release-archive scan | Internal GSD vocabulary leaking into a published upgrade guide |

**CUT/MERGE candidates — doc-to-doc string lock, no behavioral derivation:**

| File | Lines | Why it's a cut/merge candidate | Recommended disposition |
|---|---|---|---|
| `test/threadline/stg_doc_contract_test.exs` | 75 | All 3 tests are `String.contains?(doc, marker)` between CONTRIBUTING.md, `production-checklist.md`, and `adoption-pilot-backlog.md` — pure prose cross-reference, no code or generated value involved. Catches only "a marker string was deleted," which normal prose review already catches | **Merge** the cross-reference check into `adoption_pilot_doc_contract_test.exs` (which already owns real derivation for that guide) as one additional assertion, or **cut** entirely and rely on doc review; do not keep as a standalone file |
| `test/threadline/operator_surface/theme_doc_contract_test.exs` | 145 | Moduledoc self-describes as "Pure source-reading (File.read! + String.contains?)" with no derivation — a literal-pin lock on prose fragments, explicitly modeled after the same pattern as the file below | **Cut or fold** into `operator_surface_doc_contract_test.exs` as a labeled sub-block if the specific literals genuinely matter for D-04 daytime-recommendation history; otherwise cut |
| `test/threadline/operator_surface_doc_contract_test.exs` | 261 | Mixed file: some tests derive from `Mix.Tasks.Release.Pins` (keep), but others (e.g. "README routes the operator surface mount macro to its canonical owner": `assert String.contains?(readme, "threadline_operator_surface")`) are bare literal-in-doc checks with no macro/behavior binding | **Line-item split**, not a file-level cut: keep the Pins-derived assertions, cut or merge the bare-literal ones into a single "README mentions the macro name" smoke assertion (or delete — a broken macro reference would already fail `mix docs`/ExDoc link checking elsewhere) |

**Not independently audited this pass (flag for the roadmap, do not assume verdict):**
`test/threadline/ci_all_dedup_contract_test.exs` cousins not yet checked line-by-line for
internal tautologies (`test/threadline/operator_surface/coverage_doc_contract_test.exs`,
`test/threadline/operator_surface/policy_show_doc_contract_test.exs`,
`test/threadline/storage_schema_migration_contract_test.exs`,
`test/threadline/storage_schema_prefix_contract_test.exs`) — these were seen in the async:false
inventory (Part A) but not opened for content in this pass. Apply the B.1 rubric to each before
cutting or keeping; do not batch-cut on the strength of this report alone.

**Estimated scope for the roadmap:** roughly 2 files (150+145 lines) as clean cut/merge
candidates, plus a line-item split inside 1 more (`operator_surface_doc_contract_test.exs`,
~261 lines, only part of it weak), against a KEEP set of at least 17 files carrying real
drift-detection value. This is a small, low-risk trim — not a suite-reshaping effort — sized
at roughly one plan, not a phase.

## Part C — The `gen.triggers` Down Orphan

### C.1 Location

- `lib/mix/tasks/threadline.gen.triggers.ex:588-606` — `down_body/2`, the function that
  generates each trigger migration's `def down do ... end` body.
- `lib/threadline/capture/trigger_sql.ex:108-149` — `TriggerSQL.drop_function_if_unused/2`,
  the idempotent, usage-checked DROP the fix should reuse.
- `lib/threadline/mix/trigger_migration.ex` — `rerun?/2`/`covered_pairs/2`, which the task
  uses upstream to compute `rerun_tables` (not itself buggy; the bug is in how `down_body/2`
  consumes that classification).

### C.2 Root cause

`down_body/2` (`lib/mix/tasks/threadline.gen.triggers.ex:588-606`):

```elixir
defp down_body(table_specs, rerun_tables) do
  first_run_specs = Enum.reject(table_specs, fn {t, _} -> t in rerun_tables end)

  trigger_downs =
    Enum.map_join(first_run_specs, "\n\n", fn {t, _} ->
      execute_line(TriggerSQL.drop_trigger(t))
    end)

  function_downs =
    first_run_specs
    |> Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)
    |> Enum.map_join("\n\n", fn {t, _} ->
      execute_line(TriggerSQL.drop_function_if_unused(Naming.function_name(t)))
    end)
  ...
```

Both `trigger_downs` and `function_downs` are computed from the same filtered set,
`first_run_specs` — every table this migration reruns (i.e. every table an earlier migration
already installed a Threadline trigger for) is excluded from *both* lists.

Excluding a rerun table from `trigger_downs` is correct: the comment at line 585-587 explains
why — an earlier, still-applied migration expects a trigger to exist on that table, so this
migration's rollback must not drop it.

Excluding the same rerun table from `function_downs` is the bug. Consider the sequence the
milestone context names: an all-0.11 chain where migration 1 is a table's first trigger
install (default-mode, no per-table function — `needs_per_table: false`), and migration 2 is a
later rerun for the same table that adds redaction/exclusion, which requires a per-table
function (`needs_per_table: true`, creating `Naming.function_name(t)` fresh in migration 2's
`up`). Migration 2's `down_body` puts `t` in `rerun_tables`, so `t` is excluded from
`first_run_specs` entirely — meaning migration 2's `down` drops neither the trigger (correctly
deferred to migration 1) nor the per-table function it itself created (incorrectly deferred to
nobody). Migration 1's `down`, when it eventually runs under `:down, all: true`, does drop the
trigger for `t` (it is in migration 1's `first_run_specs` — migration 1 was the first to cover
`t`) — but migration 1 never created a per-table function for `t` (it was default-mode), so its
`function_downs` for `t` is empty by construction. No migration in the chain ever targets
migration 2's per-table function. After a full `:down, all: true`, the trigger for `t` is gone
(capture correctly stops) but `CREATE FUNCTION`-created per-table function from migration 2
remains in the database: orphaned, unreferenced, and undocumented by anything the rollback
printed.

### C.3 Fix shape

Split the function-down computation from the trigger-down computation. Trigger-downs stay
scoped to `first_run_specs` (unchanged — correct as-is). Function-downs should be computed
from the *full* `table_specs`, for any table where *this migration* is the one that set
`needs_per_table: true` (i.e., created that specific function name) — regardless of whether the
table is a rerun for trigger-ownership purposes:

```elixir
function_downs =
  table_specs
  |> Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)
  |> Enum.map_join("\n\n", fn {t, _} ->
    execute_line(TriggerSQL.drop_function_if_unused(Naming.function_name(t)))
  end)
```

This is safe under partial rollback for the same reason `retire_ups/1` (the `up`-side analog,
line 558-562) is already trusted to run unconditionally: `TriggerSQL.drop_function_if_unused/2`
is a `DO $$ ... $$` block that resolves the function via `to_regprocedure`, checks
`pg_trigger`/`pg_class`/`pg_namespace` for any live user, and only executes `DROP FUNCTION`
when there is none — otherwise it emits a `RAISE WARNING` naming every table still using it and
leaves the function alone (`lib/threadline/capture/trigger_sql.ex:130-147`). So:

- Rolling back only this migration (migration 2's `down` alone, not `:down, all: true`) while
  migration 1 (and its trigger, still pointed at migration 2's per-table function) is still
  applied: the guard sees the live trigger reference and *keeps* the function, printing a
  warning — no regression, no premature drop.
- Rolling back the full chain (`:down, all: true`, migration 2's `down` then migration 1's
  `down`): migration 1's `down` drops the trigger first... actually migrations roll back in
  reverse-version order, so migration 2's `down` runs before migration 1's. At that point the
  trigger (installed by migration 1, still live) still references the per-table function, so
  the guard correctly *keeps* it during migration 2's own down. Then migration 1's `down` drops
  the trigger. The per-table function is now unreferenced but nothing re-invokes
  `drop_function_if_unused` for it after that point — **this specific ordering still leaves a
  one-migration lag**: the function is orphaned one step later than the trigger, not zero
  steps later. Given `Ecto.Migrator.run(repo, :down, all: true)` runs every `down` in one
  transaction-or-sequence without a second pass, the guard's "check before drop" approach
  cannot retroactively clean up a function that became unused only *after* its own down ran.

  The correct resolution given that ordering constraint: emit the function-down call for a
  rerun+`needs_per_table` table in the **first-run migration's** `down`, not (only) the
  migration that created it — i.e., when migration 1's `down` runs (last, dropping the
  trigger), it should also attempt `drop_function_if_unused` for every per-table function any
  later rerun installed for that same table, since by the time migration 1's `down` executes,
  the trigger is being dropped and any later per-table function is now provably unused. This
  needs `down_body/2` to receive, for each first-run table, the set of "per-table function
  names installed by any migration in the chain for this table" — which is exactly what
  `TriggerMigration.covered_pairs/1`/`parse_triggers/1` are already built to recover by
  scanning prior migration sources (`lib/threadline/mix/trigger_migration.ex:120-149`). The
  practical shape: at generation time, in addition to emitting `drop_function_if_unused` for
  *this* migration's own newly-created per-table functions (guarded, so safe if this is not
  the last rollback step), also have the **first-run** migration's down emit
  `drop_function_if_unused` for the per-table function name(s) any rerun scan turned up for
  that table — both calls are individually safe (idempotent, usage-checked), so emitting the
  drop attempt from *both* ends of the chain is not a correctness risk, only insurance against
  the ordering gap identified above.

  A simpler, equally-correct alternative that avoids reasoning about migration ordering at
  all: a **catalog-driven drop** at rollback time is unnecessary — the migration doesn't need
  to enumerate every possible name if it drops by regexp/catalog scan. But per this library's
  own architectural constraint ("no CASCADE drops", explicit per-function DROP statements only,
  documented in `CLAUDE.md`), a catalog-driven `DROP FUNCTION` sweep across
  `pg_proc`/`information_schema.routines` by naming convention (`threadline_capture_%`) would
  be a bigger behavior change than this bug warrants and risks dropping a function a *host*
  application happens to have named similarly. **Recommend the two-sided idempotent-guard
  emission described above** (both the rerun migration's own down, for the partial-rollback
  case, and the first-run migration's down, for the full-chain case) over a catalog sweep.

### C.4 The test that proves it

A property test over rerun sequences, colocated with
`test/threadline/mix/trigger_migration_property_test.exs` (the existing property test for this
same module family) or as a new file
`test/threadline/mix/gen_triggers_down_orphan_property_test.exs`, using `StreamData`
(already a `mix.exs` test dep, `~> 1.4`) to generate:

1. A random sequence of 1–4 "runs" against the same table: each run is either the table's
   first trigger install (random `needs_per_table: true/false`) or a rerun (random
   `needs_per_table` change, e.g. toggling redaction on/off).
2. Generate each run's migration file for real via the task's own generation functions
   (`migration_content/3`, `down_body/2`), write it to a scratch migrations directory, and run
   `Ecto.Migrator.run(repo, :up, all: true)` then `Ecto.Migrator.run(repo, :down, all: true)`
   against the real test database (this fits the project's existing pattern —
   `test/threadline/capture/trigger_rerun_test.exs` already applies generated migration SQL
   against the real DB rather than mocking it).
3. **Invariant asserted:** after `:down, all: true`, `pg_proc` (scoped to the storage schema)
   contains **zero** Threadline-owned capture functions for that table — i.e.,
   `SELECT count(*) FROM pg_proc WHERE proname LIKE 'threadline_capture_%' AND ...` (or the
   equivalent `to_regprocedure` check `drop_function_if_unused` itself uses) returns 0 for
   every per-table function name any run in the sequence could have created, regardless of run
   order, run count, or which run created which name. This directly encodes "no orphan
   survives a full rollback" as a property over the input space the bug report names ("an
   all-0.11 chain: a first run, then a rerun that adds a per-table function for the same
   table"), rather than a single hand-picked regression case.
4. A companion, non-property regression test should still pin the exact two-migration sequence
   from the bug report (first run default-mode, rerun adds redaction) as a fast, deterministic
   CI case — properties are for the input-space coverage, not a replacement for the concrete
   repro.

## Sources

- `.planning/PROJECT.md` (Current Milestone: v1.44 section)
- `.planning/MILESTONE-GUIDE.txt` §8, §9, §9a
- `.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md`
- `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md`
- `.planning/milestones/v1.42-MILESTONE-AUDIT.md` (gen.triggers down orphan report)
- `test/test_helper.exs`
- `test/support/data_case.ex`
- `test/support/storage_schema_case.ex`
- `.github/workflows/ci.yml`
- `.github/workflows/flake-detection.yml`
- `lib/mix/tasks/threadline.gen.triggers.ex`
- `lib/threadline/mix/trigger_migration.ex`
- `lib/threadline/capture/trigger_sql.ex`
- `mix.exs`
- Grep inventory of `test/**/*_test.exs` (222 files; 56 `async: false`, 36 implicit-default,
  132 `async: true`) performed in this research pass
- File reads of 24 `*doc_contract*`/`*_contract_test*` files for Part B classification
- Web search on Oban testing conventions (Sandbox-prefix isolation), used only to confirm why
  that precedent does not directly transfer here (Threadline has already ruled out Sandbox)

---
*Architecture research for: Threadline v1.44 (suite parallelism, guard-test rebalance, gen.triggers down orphan)*
*Researched: 2026-09-30*
