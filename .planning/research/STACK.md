# Stack Research — Threadline v1.14 ("Drop-in Production Adopter Slice")

**Domain:** Elixir / Phoenix / Ecto / PostgreSQL audit library — subsequent milestone, additions only
**Researched:** 2026-04-25
**Author:** GSD project researcher (spawned by `/gsd-new-milestone` Phase 6)
**Overall confidence:** HIGH for benchmarking + ExDoc + Sigra (Hex-verified versions); MEDIUM for incident-replay tooling shape (no canonical 2026 pattern); HIGH for "what NOT to add."

## Summary

Threadline is mature: capture, semantics, exploration, retention, export, continuity, redaction, and as-of reconstruction have all shipped through v0.2.0. The library's runtime dep set (`ecto_sql`, `postgrex`, `jason`, `nimble_csv`, `plug`, `telemetry`) is **stable and should not change** in v1.14. Every v1.14 capability — SIGRA, PERF, INCIDENT, RELEASE, ADOPT — can land **without adding a single new runtime dep** to the published Hex package.

The only **new** dependencies are:

1. **`benchee` ~> 1.5** — `only: :dev`, never compiled into the Hex artifact, for the new `bench/` harness (PERF-01).
2. **(Optional) `benchee_html` ~> 1.0** and/or **`benchee_markdown` ~> 0.3** — `only: :dev`, formatter plugins for publishing baselines into `guides/performance.md` (PERF-02).

Everything else — Sigra adapter, incident playbook, ExDoc 0.40 upgrade, SaaS quickstart guide — is either a docs change, a guarded `Code.ensure_loaded?/1` integration that consumes Sigra **only when present at compile time in the host**, or a `mix.exs` `:files` / `extras` adjustment.

The dominant risk is **accidentally widening the dep surface** to please the Sigra integration ("just add `{:sigra, optional: true}` to deps"). Don't. The locked architectural framing in `.planning/research/sigra-integration-context.md` is explicit: Threadline must remain auth-agnostic; the adapter must be loadable but the core library must not require Sigra to compile or run.

---

## Recommended Additions (per v1.14 category)

### 1. SIGRA — Threadline ↔ Sigra integration adapter

**New runtime deps:** **none**.

**Why:** Sigra is the host's auth library, not Threadline's. Adding `{:sigra, "~> 0.2", optional: true}` to Threadline's `mix.exs` would (a) make Threadline auth-aware in violation of the locked architectural framing (`sigra-integration-context.md` §"Architectural framing (locked)"), (b) couple Threadline's release cadence to Sigra's API stability, and (c) signal incorrectly to adopters that Sigra is privileged among auth libraries (Pow, `phx.gen.auth`, custom).

**What to do instead — guarded module pattern:**

```elixir
# lib/threadline/integrations/sigra.ex
defmodule Threadline.Integrations.Sigra do
  @moduledoc """
  Optional adapter that maps Sigra-authenticated request state into
  `Threadline.Semantics.ActorRef` and `AuditContext`.

  This module compiles unconditionally but its behavior depends on
  whether the host has `:sigra` in its own `mix.exs`. The module reads
  fields off `conn.assigns.current_scope` and `conn.private[:sigra_session]`
  by **convention**, not by depending on Sigra structs. This keeps
  Threadline auth-agnostic.
  """
  # ... functions that read conn.assigns.current_scope shape only
end
```

The module references Sigra **shapes** (`%{user: _, active_organization: _, ...}`) but never `Sigra.Session.t()` types. Tests use a stub scope struct in-tree (no Sigra dep in Threadline's `mix.exs`). The `examples/threadline_phoenix/` app may add `{:sigra, "~> 0.2"}` to **its own** `mix.exs` to demonstrate end-to-end wiring (analogous to how it already adds `phoenix`, `oban`, etc.).

**Sigra version pin (current 2026):** Latest published Sigra is **`v0.2.5`** (2026-04-25, [hex.pm/packages/sigra](https://hex.pm/packages/sigra)). The example app should pin `{:sigra, "~> 0.2"}` to allow patch updates without forcing matrix recompiles.

**Plug version:** Threadline already depends on `{:plug, "~> 1.15"}`. Latest Plug is **`v1.19.1`** (2026-12-09). `~> 1.15` accepts 1.15.x, 1.16.x, 1.17.x, 1.18.x, 1.19.x. **No change needed** — the existing constraint already covers all current Plug.

**Confidence:** HIGH — versions Hex-verified; architectural framing already locked in `.planning/research/sigra-integration-context.md`.

---

### 2. PERF — Reproducible benchmark harness in `bench/`

**New dev-only deps:**

```elixir
# in mix.exs deps/0
{:benchee, "~> 1.5", only: :dev, runtime: false},
# Optional (formatter plugins for publishing tables/HTML to guides/performance.md):
{:benchee_html, "~> 1.0", only: :dev, runtime: false},
{:benchee_markdown, "~> 0.3", only: :dev, runtime: false},
```

**Versions verified against Hex (2026-04-25):**

| Library | Latest | Released | Notes |
|---|---|---|---|
| `benchee` | **1.5.0** | 2025-10-21 | Canonical Elixir benchmarking lib; `measure_function_call_overhead: true` is default; supports `before_scenario` / `after_scenario` / `before_each` / `after_each` hooks ([hex.pm/packages/benchee](https://hex.pm/packages/benchee), [GitHub](https://github.com/bencheeorg/benchee)) |
| `benchee_html` | **1.0.1** | 2023-12-27 | Stable; produces interactive HTML reports ([hex.pm/packages/benchee_html](https://hex.pm/packages/benchee_html)) |
| `benchee_markdown` | **0.3.3** | 2024-01-07 | Produces markdown tables ideal for `guides/performance.md` baselines ([hex.pm/packages/benchee_markdown](https://hex.pm/packages/benchee_markdown)) |

**Why Benchee, not alternatives:**
- **Benchee** is the de-facto standard in the Elixir ecosystem; Phoenix, Ecto, Oban, and Carbonite all use it. ([AppSignal benchmarking guide](https://blog.appsignal.com/2022/09/06/benchmark-your-elixir-apps-performance-with-benchee.html), [Elixir School](https://elixirschool.com/en/lessons/misc/benchee))
- Built-in statistics (mean, median, stddev, ips) match what Threadline needs to publish in `guides/performance.md`.
- Hooks separate setup from measurement — exactly what's needed when the unit under test is "INSERT into `posts` table with audit trigger attached" vs "INSERT without trigger."
- Plugin formatter ecosystem (HTML, Markdown, CSV, JSON) keeps published baselines version-controlled and reviewable.

**Alternatives considered and rejected:**
- **`:timer.tc/1` raw measurement** — no warmup, no statistical analysis, no IPS. Acceptable for ad-hoc one-shots but fails the "reproducible baseline" bar PERF-01 sets.
- **`elixirbench`** ([github.com/spawnfest/elixirbench](https://github.com/spawnfest/elixirbench)) — long-running benchmark runner; designed for cross-version regression CI of language/runtime, not application benchmarks. Overkill for v1.14.
- **`benchfella`** — predates Benchee, no longer actively maintained. Don't use.
- **`pg_bench`** (PostgreSQL's own) — measures the database, not the Elixir-driven trigger overhead path. Keep as a complementary tool inside the harness scripts (called via `System.cmd/3`) but not a Mix dep.

**PostgreSQL trigger overhead measurement strategy:**

The harness should publish three kinds of numbers, each grounded in shipped APIs:

1. **Trigger write overhead** — wall time and IPS for `Repo.insert/update/delete` on an audited row vs. an unaudited row with identical schema. Run with `before_scenario` truncating both tables; use `after_scenario` to clean up. Drives the "trigger costs ~X% per write" headline number.
2. **Timeline / export read plans** — capture `EXPLAIN (ANALYZE, BUFFERS)` output for `Threadline.Query.timeline/2`, `Threadline.Query.audit_changes_for_transaction/2`, and `Threadline.Export.export_changes_query/1` against a 1M-row `audit_changes` corpus. Use `Ecto.Adapters.SQL.query!/3` with `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` and pipe the JSON into the harness output. ([PostgreSQL EXPLAIN docs](https://www.postgresql.org/docs/current/sql-explain.html), [PostgresAI on BUFFERS](https://postgres.ai/blog/20220106-explain-analyze-needs-buffers-to-improve-the-postgres-query-optimization-process))
3. **Retention purge cost** — IPS and wall time for `Threadline.Retention.purge/1` against a corpus seeded with N audit transactions, varying the `:batch_size` option (already shipped per `Threadline.Retention.Policy`).

**`EXPLAIN (ANALYZE, BUFFERS)` — explicitly YES, capture it:** The harness should record these plans into a versioned text file under `bench/baselines/`. Reasons:
- BUFFERS reveals whether the trigger path is shared-buffer hit vs disk-read — critical for predicting behavior on cold caches. (PostgreSQL 18 EXPLAIN docs, [use-the-index-luke.com on EXPLAIN](https://use-the-index-luke.com/sql/explain-plan/postgresql/getting-an-execution-plan))
- Plans evolve across PG point releases; checking diffs in PRs catches regressions early.
- Operators reading `guides/performance.md` need plans to validate against their own `EXPLAIN` output. Numbers without plans are fortune-cookies.
- `pg_stat_statements` is **complementary** — operators can use it on their host; we don't bundle it into the harness because it requires a `shared_preload_libraries` change and adds setup friction. Document it in `guides/performance.md` as the next step after running the local harness.

**Fixture-data generation — recommendation:**

Use **plain Elixir + raw SQL `INSERT INTO ... SELECT generate_series(...)`**, not a fixture library. Reasons:

| Approach | Why not (for `bench/`) |
|---|---|
| `:stream_data` ~> 1.3 | Property-based test data generator; great for invariant tests, but slow and overkill for "I need 1M rows of plausible audit data fast." Not the right tool. ([hex.pm/packages/stream_data](https://hex.pm/packages/stream_data) — v1.3.0, 2026-03-09) |
| `:ex_machina` ~> 2.8 | Factory pattern for tests; one-row-at-a-time via `Ecto.Repo.insert` is far too slow for 1M rows. ([hex.pm/packages/ex_machina](https://hex.pm/packages/ex_machina) — v2.8.0, 2024-06-25, no recent activity) |
| `:faker` ~> 0.18 | Realistic strings/names — useful for ADOPT-01 SaaS quickstart seed data, **not** for benchmark fixtures (variance harms benchmark stability). ([hex.pm/packages/faker](https://hex.pm/packages/faker) — v0.18.0, 2024-02-29) |
| **Raw SQL `INSERT ... SELECT generate_series(...)`** | **Recommended.** Fastest possible seeding, deterministic (use a fixed seed in `random()`), no extra Mix deps, runs at PG speed not BEAM speed. The harness should ship a single SQL script `bench/fixtures/seed_audit_corpus.sql` plus a `Mix.Task` wrapper. |

**Keeping the harness out of the published Hex package:**

Two complementary mechanisms — use **both**:

1. **`mix.exs` `:files`** — already explicitly enumerates `lib`, `guides`, `.formatter.exs`, `mix.exs`, `README.md`, `LICENSE`, `CHANGELOG.md`, `CONTRIBUTING.md`. **Do not add `bench` to this list.** Hex builds the package only from `:files`; anything outside is invisible to Hex consumers. (See current `mix.exs:106`.)
2. **`only: :dev` on Benchee deps** — deps marked `only: :dev` are not resolved when downstream apps `mix deps.get`. This prevents Threadline-using apps from accidentally pulling Benchee transitively even if `bench/` somehow got included.

The combination is belt-and-suspenders: the package **cannot** ship `bench/` content, and even if it did, Benchee would not be installed in dependent apps.

**Recommended `bench/` layout (informational, not a dep choice):**

```
bench/
  README.md                       # how to run + what each script measures
  baselines/                      # checked-in EXPLAIN plans + Benchee output
    timeline_query_2026_04.md
    trigger_overhead_2026_04.md
  fixtures/
    seed_audit_corpus.sql         # raw SQL for 1M-row corpus
  scripts/
    trigger_overhead.exs          # Benchee.run measuring write paths
    timeline_query.exs            # Benchee.run measuring read paths
    retention_purge.exs           # Benchee.run measuring purge batches
    explain_capture.exs           # writes EXPLAIN (ANALYZE, BUFFERS) JSON
```

Run via `mix run bench/scripts/trigger_overhead.exs` — no new alias required (a `mix bench` alias is fine but optional).

**Confidence:** HIGH — Benchee version Hex-verified, EXPLAIN methodology grounded in PG docs, fixture choice grounded in dep landscape (no library currently competes with raw SQL for 1M-row seeding speed in Elixir).

---

### 3. INCIDENT — `guides/incident-playbook.md` + incident-replay script

**New deps:** **none**.

**Why:** Every primitive needed for the five canonical incidents is already shipped:

| Incident type | Tooling already shipped (no new dep needed) |
|---|---|
| "Who changed this row?" | `Threadline.Query.history/3`, `Threadline.audit_changes_for_transaction/2`, `Threadline.change_diff/2` |
| "What did this user do during their session?" | `Threadline.Query.actor_history/2`, `:correlation_id` filter on `timeline/2` |
| "Reconstruct the row at time T" | `Threadline.as_of/4` (map-first + opt-in `:cast`) |
| "Export evidence for a specific transaction" | `Threadline.Export.export_json/2`, `mix threadline.export`, jq snippets |
| "Verify trigger coverage hasn't drifted" | `Threadline.Health.trigger_coverage/1`, `mix threadline.verify_coverage` |

**`Postgrex.Notifications` for live tail — DO NOT ADD as a v1.14 capability.** The user's prompt asks whether to consider it; the answer is **no for this milestone**:
- Threadline's existing capture path uses standard triggers, not `pg_notify` triggers. Adding LISTEN/NOTIFY would be a new capture-layer feature, not an incident-playbook tool, and v1.14 is "documentation + harness," not new capture semantics.
- `Postgrex` already ships `Postgrex.Notifications` (latest Postgrex **v0.22.0**, 2026-01-10, [hex.pm/packages/postgrex](https://hex.pm/packages/postgrex)) and Threadline's `~> 0.17` constraint allows it. If a future milestone wants live-tail, the dependency is already there — no need to mention it in v1.14.
- Live tail is a SIEM/observability adjacency; per `PROJECT.md` Out of Scope, Threadline is "not a SIEM." Adding a tail tool here muddies the boundary.

**Incident-replay script in the example app:**

The script lives at `examples/threadline_phoenix/scripts/incident_replay.exs` (or as a `Mix.Task` under the example app — preferred for discoverability via `mix help`). It uses **only** APIs already public on `Threadline.*` plus standard library (`Jason`, `IO`). No new dep on the library or example side.

**`Mix.Task` vs plain `.exs`:** Recommend **`Mix.Task`** in the example app (`mix incident.replay`) because:
- Discoverable via `mix help`.
- Sets up the application/repo correctly via `Mix.Task.run("app.start", [])`.
- Existing example app conventions (the `mix verify.example` alias, the `posts_audit_path_test.exs`) already favor task-shaped entrypoints.

**SQL view templates and jq snippets:** ship as **inline code blocks** in `guides/incident-playbook.md`, copy-pasteable. No new tooling needed. The existing `LOOP-04-SUPPORT-INCIDENT-QUERIES` pattern from v1.8 is the model — extend that contract. Doc-contract test (`test/threadline/incident_playbook_doc_contract_test.exs`) locks the literals.

**Confidence:** HIGH on "no new deps needed"; MEDIUM on the precise five incidents (that's INCIDENT-01's job — the playbook authoring is part of the milestone, not part of stack research).

---

### 4. RELEASE — `threadline 0.3.0` packaging + ExDoc upgrade

**Dep changes:**

```elixir
# Bump only:
{:ex_doc, "~> 0.40", only: :dev, runtime: false},  # was "~> 0.34"
```

**Why bump ExDoc:** Latest is **`v0.40.1`** (2026-01-31, [hex.pm/packages/ex_doc](https://hex.pm/packages/ex_doc)). Between 0.34 and 0.40, ExDoc gained:
- 20-30x faster doc generation via parallelized module retriever (v0.37.0).
- Markdown formatter (v0.40.0).
- Auto-generated `llms.txt` for AI-consumable docs (v0.40.0).
- `:group` metadata option for sidebar grouping at the function level (v0.36.0).
- `:default_group_for_doc` configuration (v0.36.0).
- `extras` validation strictening (v0.39.0).

**Breaking change relevant to Threadline:** v0.40.0 changed the `:assets` option to require a map instead of a string. Threadline's current `mix.exs` does **not** set `:assets`, so this does not affect us. (Verified by reading `mix.exs:110-161`.)

**No breaking changes for `groups_for_modules` or `groups_for_extras`** between 0.34 and 0.40 — Threadline's existing `docs/0` config (lines 110-161) keeps working as-is.

**ExDoc `extras` additions for v1.14 (in `mix.exs`):**

```elixir
extras: [
  "README.md",
  "guides/domain-reference.md",
  "guides/brownfield-continuity.md",
  "guides/production-checklist.md",
  "guides/adoption-pilot-backlog.md",
  "guides/audit-indexing.md",
  "guides/performance.md",          # NEW (PERF-02)
  "guides/incident-playbook.md",    # NEW (INCIDENT-01)
  "guides/getting-started-saas.md", # NEW (ADOPT-01)
  "guides/sigra-integration.md",    # NEW (SIGRA-03)
  "CONTRIBUTING.md",
  "CHANGELOG.md"
]
```

**`groups_for_extras` should add a "Tutorials" / "Operations" split** to keep the sidebar legible:

```elixir
groups_for_extras: [
  Overview: ~r/README/,
  "Getting started": ~r{getting-started},
  Reference: ~r{^guides/(domain-reference|audit-indexing|sigra-integration)},
  Operations: ~r{^guides/(production-checklist|incident-playbook|performance|brownfield|adoption-pilot)},
  Project: ~r/(CONTRIBUTING|CHANGELOG)/
]
```

**`groups_for_modules`** — no new modules need a group beyond what already exists, **except** the new `Threadline.Integrations.Sigra` module. Add:

```elixir
groups_for_modules: [
  "Core API": [...],
  Integration: [
    Threadline.Plug,
    Threadline.Job,
    Threadline.Health,
    Threadline.Continuity,
    Threadline.Telemetry,
    Threadline.Integrations.Sigra,    # NEW (SIGRA-01)
  ],
  Schemas: [...],
  "Mix Tasks": [...]
]
```

**`:tags` (module metadata):** ExDoc 0.40 supports `tags` as a list of atoms in module metadata. **Do not add `:tags`** in v1.14 — none of the five current categories need them, the sidebar grouping covers organization, and adding `:tags` would create an inconsistent annotation pattern (some modules tagged, most not). Defer until there's a concrete reader-facing need.

**Hex `:files` changes:** The current `:files` line is:

```elixir
files: ~w(lib guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)
```

`guides` is already enumerated as a directory — **new guides land under `guides/` automatically**. No `:files` change needed for SIGRA-03, INCIDENT-01, PERF-02, or ADOPT-01.

**Do NOT add `bench` to `:files`.** (See PERF section above.)

**CHANGELOG conventions for 0.x bumps:**

Threadline's existing CHANGELOG follows Keep a Changelog conventions (Added / Changed / Fixed / Removed). For 0.2.0 → 0.3.0:

- This is a **minor** bump within 0.x — semver pre-1.0 allows breaking changes here, but **none are planned** in v1.14 (all v1.14 features are additive).
- Use the dated 0.3.0 section heading as the existing 0.2.0 section does.
- "Upgrade notes from 0.2.x → 0.3.0" subsection — required by REL-02. Even if there are no breaking API changes, integrators want to see "no migration needed; here's what's new" stated explicitly.
- Ship the dated tag `v0.3.0` on `origin` (matches the existing `v0.1.0` / `v0.2.0` precedent).

**Publishing:** Per `PROJECT.md` Out of Scope, automated CI publish stays deferred — interactive `mix hex.publish` remains the documented maintainer path. No new tooling here.

**Confidence:** HIGH — ExDoc version Hex-verified; changelog/files/groups patterns grounded in current `mix.exs` and ExDoc 0.40 changelog.

---

### 5. ADOPT — `guides/getting-started-saas.md` 30-minute SaaS quickstart

**New deps:** **none**.

**Why:** This is a documentation deliverable. The 30-minute quickstart walks through:
- `mix threadline.install` (already shipped)
- `mix threadline.gen.triggers` (already shipped)
- `Threadline.Plug` wiring (already shipped)
- `record_action/2` (already shipped)
- One incident query from the new `guides/incident-playbook.md`

All shipped. The only "stack" question is whether to recommend `:faker` for the SaaS quickstart's seed-data step — answer: **no**. Keep seed data inline in the guide as plain literal values. Adding `:faker` to the example app's `mix.exs` would (a) drag a dep in for cosmetic reasons, (b) make the quickstart less reproducible (faker output varies across versions), and (c) violate "minimum surface area for a 30-minute quickstart."

**Doc-contract test:** Add `test/threadline/getting_started_saas_doc_contract_test.exs` following the existing `readme_doc_contract_test.exs` and `audit_indexing_doc_contract_test.exs` pattern. Locks the quickstart literals so future drift fails CI. No new dep — uses `ExUnit` only.

**Confidence:** HIGH.

---

## Integration Points

### `mix.exs` deps section (final shape after v1.14)

```elixir
defp deps do
  [
    # Runtime — UNCHANGED
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:jason, "~> 1.4"},
    {:nimble_csv, "~> 1.2"},
    {:plug, "~> 1.15"},
    {:telemetry, "~> 1.2"},

    # Dev/test — UNCHANGED
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

    # Dev — BUMPED
    {:ex_doc, "~> 0.40", only: :dev, runtime: false},

    # Dev — NEW (PERF-01/02 only)
    {:benchee, "~> 1.5", only: :dev, runtime: false},
    {:benchee_html, "~> 1.0", only: :dev, runtime: false},      # optional, for HTML reports
    {:benchee_markdown, "~> 0.3", only: :dev, runtime: false}   # optional, for guides/ tables
  ]
end
```

**Rationale per change:**
- `:ex_doc` `~> 0.34` → `~> 0.40`: required for the v0.3.0 release narrative (Markdown formatter, llms.txt, faster doc generation). Verified non-breaking for current Threadline `docs/0` config.
- `:benchee` family: PERF-01 cannot ship without it. All three are `only: :dev, runtime: false` — they do not appear in the Hex package's `mix.exs` deps when downstream apps resolve.

**Rationale for what is NOT changed:**
- `{:plug, "~> 1.15"}` — already covers Plug 1.19.1.
- `{:postgrex, "~> 0.17"}` — already covers Postgrex 0.22.0; `Postgrex.Notifications` is available if a future milestone wants it.
- No `{:sigra, ...}` — locked architectural framing forbids hard or "optional" Sigra dep at the library level.

### `mix.exs` `:files` (Hex package contents)

**No change.** Current line correctly enumerates `lib`, `guides`, etc. New guides under `guides/` are auto-included. `bench/` is correctly absent.

### `mix.exs` `cli/0` `preferred_envs`

**No change required.** Benchee scripts run via `mix run bench/scripts/*.exs`, which uses `Mix.env() == :dev` by default. If we later add a `mix bench` alias, register it in `preferred_envs: [bench: :dev]`.

### `mix.exs` aliases / CI integration

**Do NOT add `bench` to `mix ci.all`.** Benchmarks are slow, non-deterministic on CI runners, and have flaky absolute numbers — they belong to the maintainer-run baseline workflow, not the green/red CI gate. The OSS DNA explicitly warns against silent test exclusions, but benchmarks are not tests; they are reports. Run them locally on a controlled machine and check the resulting baseline files into `bench/baselines/` so reviewers can diff.

A nominal `mix bench` alias is fine:

```elixir
# in aliases/0
"bench.trigger_overhead": ["run bench/scripts/trigger_overhead.exs"],
"bench.timeline": ["run bench/scripts/timeline_query.exs"],
"bench.purge": ["run bench/scripts/retention_purge.exs"]
```

These show up in `mix help` and document themselves. Don't roll them into `ci.all`.

### ExDoc config (`mix.exs` `docs/0`)

Three additive changes in `docs/0`:
1. Add four new `extras` entries (see RELEASE section above).
2. Add new `groups_for_extras` rules for "Getting started" and "Operations" splits.
3. Add `Threadline.Integrations.Sigra` to the `Integration` row of `groups_for_modules`.

### CONTRIBUTING.md

Document the `bench/` workflow:
- How to seed the corpus (`mix run bench/fixtures/seed_audit_corpus.sql` via `Ecto.Adapters.SQL.query!/3` wrapper, or psql directly).
- How to capture EXPLAIN plans and check them into `bench/baselines/`.
- Why benchmarks are not in `ci.all`.

The OSS DNA pattern from `prompts/threadline-elixir-oss-dna.md` §1 ("Verification is a product surface") applies here in a softened form — benchmarks aren't verification, but they still need named entrypoints (`mix bench.*`) cited in CONTRIBUTING.

---

## What NOT to Add

This section enforces the v0.x scope guardrails. Each item below was considered and rejected with reason.

| Don't add | Why not |
|---|---|
| **`{:sigra, ...}` as a runtime dep** (even with `optional: true`) | Violates locked architectural framing in `.planning/research/sigra-integration-context.md`: "Threadline must remain auth-agnostic." Sigra is one possible auth source, not privileged. Adapter must read `conn.assigns.current_scope` by **convention**, not depend on Sigra structs. |
| **`{:benchee, ...}` as a runtime dep** | Benchmark harness must not appear in the Hex artifact's transitive deps. `only: :dev` plus excluding `bench/` from `:files` is the correct pattern. |
| **WAL/CDC libraries** (`broadway`, `walex`, `cainophile`, custom logical replication consumers) | `PROJECT.md` constraint: "No WAL/CDC as primary backend — logical replication adds operational surface area incompatible with Threadline's 'batteries-included' promise at v0.x." Path B (custom triggers) is the closed decision. WAL is not a v1.14 question. |
| **`:carbonite` for capture comparison** | Path B is the closed capture decision (see archived `gate-01-01.md` and `PROJECT.md` Key Decisions). Don't even add it to `bench/` for "comparison" — that's a future milestone if at all. |
| **`Postgrex.Notifications` as a v1.14 incident-playbook tool** | Postgrex already ships it; if a future milestone wants live-tail, it's already there. v1.14 incident-playbook is doc + replay script, not new live-streaming surface. |
| **`:phoenix_pubsub` for incident-replay broadcast** | Same reasoning: Threadline core stays Phoenix-agnostic. The example app already depends on Phoenix; nothing in v1.14 requires Threadline core to know about Phoenix.PubSub. |
| **`:tags` module metadata in ExDoc 0.40** | Adds inconsistent annotation pattern; sidebar grouping already covers organization. Defer until a concrete reader-facing need surfaces. |
| **`:assets` map config in ExDoc 0.40** | Threadline doesn't ship custom CSS / JS / images for docs. Adding `:assets` for cosmetic reasons widens the maintenance surface. Skip. |
| **`:ex_machina` for benchmark fixtures** | Per-row `Repo.insert` is too slow for 1M-row seeding. Raw SQL `INSERT ... SELECT generate_series(...)` is 100-1000x faster. |
| **`:stream_data` for benchmark fixtures** | Property-based generator, not a bulk-fixture tool. Wrong shape for the problem. (Could be useful later for invariant tests on `as_of/4` or `change_diff/2`, but not v1.14.) |
| **`:faker` in the SaaS quickstart** | Drag-in for cosmetic reasons; varies across versions; hurts reproducibility of the 30-minute quickstart. Use literal seed values inline in the guide. |
| **`:dialyxir` / `:sobelow` / `:doctor`** | Existing `mix.exs` does enable Dialyzer plt apps but doesn't depend on `:dialyxir`. v1.14 doesn't add a new lint or security pass; defer to a future "OSS hygiene" milestone if appetite arises. |
| **Automated `mix hex.publish` from CI** | `PROJECT.md` Out of Scope: "Interactive `mix hex.publish` remains the documented maintainer path for early releases." Don't add a tag-triggered publish action in v1.14. |
| **`bench` directory in `mix.exs` `:files`** | Would balloon the Hex package size, expose harness internals to consumers, and require benchmark deps to compile. Keep `bench/` out. |
| **A `Threadline.Bench` module under `lib/`** | Putting benchmark helpers under `lib/` would compile them into the Hex artifact. If shared helpers are needed across `bench/scripts/*.exs`, put them in `bench/lib/` and load via `Code.require_file/1` from each script. |
| **A new "telemetry events for incidents" event family** | v1.14 is doc + harness; no new telemetry semantics. Existing `:telemetry` events from v1.9 OPS-01/02 cover what the playbook needs. |
| **Phoenix LiveView for the incident-replay script** | `PROJECT.md` Out of Scope: "LiveView operator UI — deferred until capture + semantics prove out." The replay script is a `Mix.Task`, period. |

---

## Version Compatibility Notes

| Constraint | Verified compatible | Source |
|---|---|---|
| `elixir: "~> 1.15"` | Elixir 1.15, 1.16, 1.17, 1.18 (and likely 1.19 — Mix v1.19.5 is current per [hexdocs](https://hexdocs.pm/mix/Mix.Tasks.Deps.html)). No change needed for v1.14. | Mix docs |
| `ecto_sql: "~> 3.10"` | Latest is 3.13 (per the example app's pin); `~> 3.10` accepts it. No change. | Example app `mix.exs` |
| `postgrex: "~> 0.17"` | Latest is 0.22.0. Constraint accepts. `Postgrex.Notifications` ships in current versions. | [hex.pm/packages/postgrex](https://hex.pm/packages/postgrex) |
| `plug: "~> 1.15"` | Latest is 1.19.1. Constraint accepts. | [hex.pm/packages/plug](https://hex.pm/packages/plug) |
| `jason: "~> 1.4"` | Stable; no compatibility issues with Postgrex/Ecto/ExDoc. | Existing `mix.exs` |
| `benchee: "~> 1.5"` | Compatible with Elixir 1.15+ per Benchee's own `mix.exs` `~> 1.13` constraint. | [GitHub bencheeorg/benchee](https://github.com/bencheeorg/benchee) |
| `ex_doc: "~> 0.40"` | Compatible with Elixir 1.15+. v0.40.1 released 2026-01-31. | [hex.pm/packages/ex_doc](https://hex.pm/packages/ex_doc) |
| `sigra: "~> 0.2"` (in **example app only**) | v0.2.5 latest. Compatible with Phoenix 1.8+, Ecto 3.x. | [hex.pm/packages/sigra](https://hex.pm/packages/sigra) |

---

## Open Questions (for the spec / discuss / plan phases)

These are stack-adjacent questions the spec phase should resolve. They are not blockers for the milestone roadmap.

1. **Benchee runtime vs. once-published baseline.** Should `bench/baselines/` files be regenerated and checked in on every PR (CI-driven, slow, flaky-prone), on every release tag (manual, lower frequency, easier to keep clean), or never auto-regenerated (purely maintainer-driven)? **Suggested answer for v1.14:** maintainer-driven on releases, never CI-driven. Document the workflow in CONTRIBUTING.md.

2. **`benchee_html` vs. `benchee_markdown` — ship both, or pick one?** HTML reports are richer; Markdown reports are review-friendly in PRs and can be embedded directly in `guides/performance.md`. **Suggested answer:** ship both `only: :dev`. They are tiny additions and serve different audiences. If sized down to one, prefer `benchee_markdown`.

3. **Sigra adapter — Tier 1 (docs only) vs. Tier 2 (in-tree module).** The locked context note menu offers three tiers; the seed says "Medium / one phase, likely Tier 1." The downstream consumer (roadmap creator) reads this STACK.md to size SIGRA phases. **Stack-research recommendation:** Tier 2, because SIGRA-01 in the requirements explicitly names `Threadline.Integrations.Sigra` as the in-tree module. Tier 2 with `Code.ensure_loaded?/1` guards is the cleanest, and doesn't preclude a future Tier 3 `threadline_sigra` Hex package.

4. **Incident-replay script: `Mix.Task` in the example app vs. a top-level `bin/replay-incident` shell wrapper.** Both work. **Suggested:** `Mix.Task` for ecosystem-idiomatic discoverability via `mix help`.

5. **`guides/performance.md` baseline numbers — what hardware / PG version?** Document the rig used (e.g., "M2 Pro / PG 16.3 / fsync=on / shared_buffers=128MB / Ecto.Adapters.Postgres pool_size=10") prominently at the top of the guide. Without this provenance, numbers are misleading. **Spec phase decides** the canonical rig spec.

6. **`Postgrex.Notifications` mention in `guides/incident-playbook.md`.** Even though we're not adding a new dep, the playbook could mention LISTEN/NOTIFY as "if you need live-tail, here's a sketch using the Postgrex.Notifications module that ships with Postgrex." This is a documentation choice, not a stack choice. **Suggested:** mention briefly with one paragraph + cross-link to Postgrex docs; don't ship a worked example because that creeps toward live-tail-as-a-feature.

---

## Sources

- [hex.pm/packages/benchee](https://hex.pm/packages/benchee) — verified Benchee v1.5.0 (2025-10-21)
- [hex.pm/packages/ex_doc](https://hex.pm/packages/ex_doc) — verified ExDoc v0.40.1 (2026-01-31)
- [hex.pm/packages/sigra](https://hex.pm/packages/sigra) — verified Sigra v0.2.5 (2026-04-25)
- [hex.pm/packages/postgrex](https://hex.pm/packages/postgrex) — verified Postgrex v0.22.0 (2026-01-10)
- [hex.pm/packages/plug](https://hex.pm/packages/plug) — verified Plug v1.19.1 (2025-12-09)
- [hex.pm/packages/stream_data](https://hex.pm/packages/stream_data) — verified StreamData v1.3.0 (2026-03-09)
- [hex.pm/packages/ex_machina](https://hex.pm/packages/ex_machina) — verified ex_machina v2.8.0 (2024-06-25)
- [hex.pm/packages/faker](https://hex.pm/packages/faker) — verified Faker v0.18.0 (2024-02-29)
- [hex.pm/packages/benchee_html](https://hex.pm/packages/benchee_html) — verified v1.0.1 (2023-12-27)
- [hex.pm/packages/benchee_markdown](https://hex.pm/packages/benchee_markdown) — verified v0.3.3 (2024-01-07)
- [GitHub bencheeorg/benchee](https://github.com/bencheeorg/benchee) — Benchee hooks and formatter API
- [hexdocs.pm/ex_doc/changelog.html](https://hexdocs.pm/ex_doc/changelog.html) — ExDoc 0.34 → 0.40 changelog (no breaking changes for groups_for_modules / extras; `:assets` requires map in 0.40 — Threadline does not use this option)
- [PostgreSQL EXPLAIN docs (current)](https://www.postgresql.org/docs/current/sql-explain.html) — EXPLAIN (ANALYZE, BUFFERS) syntax and overhead
- [PostgresAI on EXPLAIN BUFFERS](https://postgres.ai/blog/20220106-explain-analyze-needs-buffers-to-improve-the-postgres-query-optimization-process) — why BUFFERS is mandatory for plan capture
- [use-the-index-luke.com on EXPLAIN](https://use-the-index-luke.com/sql/explain-plan/postgresql/getting-an-execution-plan) — operator-facing EXPLAIN guidance
- [AppSignal: Benchmark Your Elixir App with Benchee](https://blog.appsignal.com/2022/09/06/benchmark-your-elixir-apps-performance-with-benchee.html) — Benchee patterns for application benchmarks
- [hexdocs.pm/postgrex/Postgrex.Notifications](https://hexdocs.pm/postgrex/Postgrex.Notifications.html) — LISTEN/NOTIFY API (relevant only as "available if needed, not added in v1.14")
- `.planning/research/sigra-integration-context.md` — locked architectural framing for Sigra integration
- `.planning/seeds/SEED-001-sigra-integration-adapter.md` — three-tier menu and trigger conditions
- `prompts/threadline-elixir-oss-dna.md` — engineering DNA: named verify entrypoints, doc contracts, stable CI job IDs
- `mix.exs` (current) — verified runtime deps, `:files`, `docs/0` config
- `examples/threadline_phoenix/mix.exs` — verified example pins (Phoenix 1.8.5, Ecto 3.13, Bandit 1.5, Oban 2.19) — establishes that the example app is the right place for any Sigra `mix.exs` entry, not the library itself

---

*Stack research for: Threadline v1.14 — "Drop-in Production Adopter Slice"*
*Researched: 2026-04-25*
*Confidence: HIGH on dep versions and "what NOT to add"; HIGH on integration points; MEDIUM on incident-replay shape (a spec-phase decision, not a stack decision).*
