# Architecture Research — v1.14 "Drop-in Production Adopter Slice"

**Project:** Threadline
**Milestone:** v1.14
**Researched:** 2026-04-25
**Scope:** SIGRA, PERF, INCIDENT, RELEASE, ADOPT — integration with existing architecture
**Confidence:** HIGH (all findings grounded in repo files; no new core surface required)

## Executive summary

v1.14 is **additive, not architectural**. Every category lands as new files under
existing extension points or as new top-level dirs (`bench/`) that do not touch
the three existing layers (`capture/`, `semantics/`, exploration/ops). The only
public-API addition is one module (`Threadline.Integrations.Sigra`) plus its
namespace; everything else is guides, scripts, harness, and packaging.

Recommendations:

- **SIGRA:** Tier 2 (in-tree) with a runtime `Code.ensure_loaded?/1` guard so Sigra stays an *optional* dep — Threadline's `mix.exs` does **not** add `:sigra` to `deps/0`. Existing example app gets **extended** (do not fork a second example).
- **PERF:** New `bench/` dir owned by `mix verify.bench`. Explicitly **not** wired into `mix ci.all` — needs a sized DB, must stay maintainer-runnable on demand.
- **INCIDENT:** Pure docs + one `priv/scripts/incident_replay.exs` in the example app. Locked by a new doc-contract test alongside the existing five.
- **RELEASE:** Last phase. Bumps `@version`, refreshes CHANGELOG, README install snippet, ExDoc extras, and adds a new `Integrations` group to `groups_for_modules`.
- **ADOPT:** New guide alongside `production-checklist.md`; refresh of `adoption-pilot-backlog.md` to demonstrate one fully-walked maintainer column. Cross-links only — no code.

Build-order constraint: **RELEASE depends on all four others.** ADOPT can run
in parallel with PERF/INCIDENT. Within SIGRA: 01 (adapter) → 02 (example
wiring) → 03 (guide + doc contract).

---

## 1. SIGRA — `Threadline.Integrations.Sigra`

### Decision: Tier 2 (in-tree, optional dep)

Tier 1 (docs only) under-delivers on the milestone goal of "drop-in" — every
adopter would copy near-identical glue. Tier 3 (separate Hex package) is
premature at ~80–150 LOC; it adds a release matrix without shipped adoption
pressure. Tier 2 is the load-bearing choice: one module, one test file, one
guide, locked behind a runtime guard.

### File layout (NEW)

| Path | Status | Purpose |
|---|---|---|
| `lib/threadline/integrations/sigra.ex` | NEW | Adapter module. `Code.ensure_loaded?(Sigra.Session)` guard at runtime. Public functions return `nil` when Sigra not available. |
| `test/threadline/integrations/sigra_test.exs` | NEW | Unit tests with `Sigra.Session` / `Scope` test doubles (NOT a hard dep on `:sigra` for the test suite — use a `defmodule` shim under `test/support/`). |
| `test/support/sigra_test_doubles.ex` | NEW | `defmodule Sigra.Session` / `Scope` test stubs guarded so they only define when the real module is absent. Lets the unit tests exercise the adapter without adding `:sigra` to library deps. |
| `guides/integrations/sigra.md` | NEW | Integration guide — `~> 0.3` install snippet, copy-pasteable Plug wiring, impersonation note, anonymous-fallback rule. |
| `test/threadline/integrations/sigra_doc_contract_test.exs` | NEW | Doc-contract test locking the literal `actor_fn:` line and module names in the guide and example wiring. |

### File layout (MODIFIED)

| Path | Why |
|---|---|
| `mix.exs` (`docs/0` → `extras`, `groups_for_modules`) | Add `guides/integrations/sigra.md` to extras; add new "Integrations" group surfacing `Threadline.Integrations.Sigra`. |
| `mix.exs` (`docs/0` → `groups_for_extras`) | Add `Integrations: ~r{^guides/integrations/}` regex group. |
| `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` | Replace Phase 23 `service_account` stub with a Sigra-aware path *guarded by `Code.ensure_loaded?(Sigra.Session)`* so the example still runs without `:sigra` installed. |
| `examples/threadline_phoenix/mix.exs` | Add `{:sigra, "~> 0.2", optional: true}` (or pin actual version) — example app *may* declare it; library does not. |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (or `endpoint.ex`) | Wire `Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1` on `:api`. |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` | Extend (or add a sibling `posts_sigra_audit_path_test.exs`) to assert the actor mapping when a Sigra-shaped `current_scope` is present. |
| `README.md` | One-paragraph cross-link to `guides/integrations/sigra.md`; doc-contract `test/threadline/readme_doc_contract_test.exs` extended to assert that link literal. |

### Public surface (locked)

```elixir
defmodule Threadline.Integrations.Sigra do
  @moduledoc """
  Optional adapter mapping a Sigra-authenticated `Plug.Conn` to a Threadline
  `ActorRef` and `AuditContext` overrides.

  Sigra stays unaware of Threadline. This module is loaded only if
  `Sigra.Session` is available; absent that, all functions return `nil`.
  """

  alias Threadline.Semantics.ActorRef

  @doc """
  Extracts an `ActorRef` from `conn.assigns.current_scope`. Returns `nil` if
  Sigra is not loaded, the scope is missing, or no resolvable actor exists.

  Suitable for `plug Threadline.Plug, actor_fn: &__MODULE__.actor_ref_from_conn/1`.
  """
  @spec actor_ref_from_conn(Plug.Conn.t()) :: ActorRef.t() | nil
  def actor_ref_from_conn(conn)

  @doc """
  Returns a keyword list of `AuditContext` overrides derived from the Sigra
  session — currently only `:correlation_id` (defaulted from `session.id` when
  the `x-correlation-id` header is absent). Empty list when Sigra not loaded.
  """
  @spec audit_context_overrides_from_conn(Plug.Conn.t()) :: keyword()
  def audit_context_overrides_from_conn(conn)

  @doc """
  Convenience factory: returns the `&actor_ref_from_conn/1` capture for use as
  the `:actor_fn` option on `Threadline.Plug`. Exists so adopters write
  `plug Threadline.Plug, actor_fn: Threadline.Integrations.Sigra.actor_fn()`.
  """
  @spec actor_fn() :: (Plug.Conn.t() -> ActorRef.t() | nil)
  def actor_fn, do: &__MODULE__.actor_ref_from_conn/1
end
```

### Optional-deps guard pattern (locked)

Use a **module-load probe at function-call time**, not a compile-time
`if Code.ensure_loaded?/1`. Compile-time probes are unreliable because Mix
compilation order does not guarantee dep modules are loaded when Threadline
compiles.

```elixir
# lib/threadline/integrations/sigra.ex (sketch)
defp sigra_loaded? do
  Code.ensure_loaded?(Sigra.Session)
end

def actor_ref_from_conn(conn) do
  if sigra_loaded?() do
    do_extract(conn)
  else
    nil
  end
end
```

This pattern is consistent with how other Elixir libraries handle optional
peer deps (e.g. `Phoenix.LiveView` checking for `Phoenix.PubSub`). It does **not**
require `Application.ensure_all_started/1` and survives release pruning.

The library's own `mix.exs` does **NOT** add `:sigra` to `deps/0`. The example
app's `mix.exs` adds `{:sigra, ..., optional: true}` so the runnable demo
exercises the real path.

### Test strategy

`test/support/sigra_test_doubles.ex` defines minimal `Sigra.Session` and
`Sigra.Scope` modules (only the fields the adapter reads) **only when the real
modules are not loaded**:

```elixir
unless Code.ensure_loaded?(Sigra.Session) do
  defmodule Sigra.Session do
    defstruct [:id, :user_id, :type, :ip, :user_agent, :impersonator_user_id]
  end
end
```

This keeps Threadline's library suite hermetic (no real `:sigra` dep) while
still exercising the live code path. The example app, which *does* depend on
`:sigra`, exercises the real-module path in its ConnCase test.

### Open design questions deferred to spec phase

The six questions from `.planning/research/sigra-integration-context.md`
(impersonation representation, org scope, `session.id` → `correlation_id`,
telemetry vs Plug-only, API-token mapping, anonymous fallback) are **not
resolved here** — they belong to `/gsd-spec-phase sigra-integration-adapter`
inside SIGRA-01. This document only locks file layout and integration
points so the roadmapper can phase the work.

### Second example app? — NO

Recommendation: **extend the existing `examples/threadline_phoenix/` app, do
not fork a `examples/threadline_phoenix_sigra/`.**

Reasons:
1. `mix verify.example` already runs the full example suite in `ci.all`. A
   second app means doubling that surface (deps install, ecto setup, test
   run) on every CI run — measurable wall-clock cost for low marginal value.
2. The Phase 23 `audit_actor.ex` stub was always intended to be replaced by
   real auth. Replacing it with a Sigra-aware function (guarded so the demo
   still runs without `:sigra`) is exactly the originally-anticipated path.
3. Two examples create a "which one is canonical?" question for adopters.
   One canonical example with a comment block showing the "if you don't use
   Sigra, here is what `audit_actor.ex` looks like" alternative is clearer.

---

## 2. PERF — Benchmark harness

### Decision: New top-level `bench/` dir; separate `mix verify.bench` alias; **not** in `ci.all`

The harness needs a sized PostgreSQL with millions of `audit_changes` rows.
That is incompatible with the existing GitHub Actions runners that use a
default-sized Postgres service. Wiring it into `ci.all` would either (a) skip
silently — violating the "honest default tests" rule from the OSS DNA — or
(b) timeout/OOM on every PR.

Solution: a **maintainer-on-demand** alias `mix verify.bench` that loads a
config-driven seeded dataset and prints reproducible numbers. Published numbers
land in `guides/performance.md` as prose tables; raw outputs are NOT committed
(they vary per host) but the harness emits a JSON file under `bench/results/`
that the maintainer cites in the guide and pastes into CHANGELOG narrative.

### File layout (NEW)

| Path | Status | Purpose |
|---|---|---|
| `bench/README.md` | NEW | "How to run the harness, what hardware was used for published numbers, how to interpret the JSON output." Cross-link to `guides/performance.md`. |
| `bench/audit_capture_bench.exs` | NEW | Benchee-shaped script measuring INSERT/UPDATE/DELETE write paths *with* triggers attached vs. baseline (no triggers). Output: ops/sec, p50/p95/p99 latency. |
| `bench/timeline_query_bench.exs` | NEW | Benchee script measuring `Threadline.Query.timeline/2` and `audit_changes_for_transaction/2` over an N-row dataset with the recommended index set vs. without. |
| `bench/scripts/seed_audit_changes.exs` | NEW | Idempotent seeder: writes N audit transactions × M changes per transaction. Driven by env vars (`THREADLINE_BENCH_TX_COUNT`, etc.). Uses `Threadline.Test.Repo` (already on the test compile path) to reuse existing migrations. |
| `bench/scripts/teardown.exs` | NEW | Truncates audit tables; same Repo. |
| `bench/results/.gitkeep` | NEW | Placeholder so `bench/results/` exists; actual JSON outputs are gitignored. |
| `guides/performance.md` | NEW | Published baseline numbers, recommended index set (cross-link to `audit-indexing.md`), PgBouncer transaction-mode confirmation, host hardware/version footnote, "your numbers will vary" disclaimer. |
| `test/threadline/performance_doc_contract_test.exs` | NEW | Doc-contract test locking the published number table headings and structure (NOT the numbers themselves — those drift legitimately). |

### File layout (MODIFIED)

| Path | Why |
|---|---|
| `mix.exs` (`aliases/0`) | Add `"verify.bench": &verify_bench/1` (or shell-out alias). Pattern matches the existing `verify_example/1` private function. |
| `mix.exs` (`docs/0` → `extras`) | Add `guides/performance.md`. |
| `mix.exs` (`docs/0` → `groups_for_extras`) | `Reference: ~r{^guides/}` already matches; no change needed. |
| `mix.exs` (`deps/0`) | Add `{:benchee, "~> 1.3", only: [:dev, :test], runtime: false}`. |
| `.gitignore` | Add `bench/results/*.json` so generated outputs don't pollute the repo. |
| `CHANGELOG.md` | (RELEASE phase) Quote the published baselines from `guides/performance.md`. |
| `README.md` | One pointer in the documentation list to `guides/performance.md`. Locked by `readme_doc_contract_test.exs`. |
| `guides/audit-indexing.md` | Cross-link to `guides/performance.md` baseline numbers; noting which index choices the published numbers used. |
| `CONTRIBUTING.md` | Section "Running the benchmark harness" — `mix verify.bench` invocation, env vars, expected runtime. |

### Why NOT in `mix ci.all`

The existing `ci.all` pipeline (see `mix.exs:69-78`) is:
```
verify.format → verify.credo → compile --warnings-as-errors →
verify.test → verify.threadline → verify.example → verify.doc_contract
```

Each step finishes in seconds-to-low-minutes. `verify.bench` against a
seeded million-row dataset takes 5–30+ minutes. Adding it to `ci.all`:
- Violates the OSS DNA "stable CI job IDs + named entrypoints" by forcing
  bench machinery into the standard PR check.
- Forces every contributor to install Benchee and seed a heavy DB just to
  run the basic test suite.
- Trains contributors to skip `ci.all` entirely.

**Locked rule:** `mix verify.bench` is a separate alias maintainers run on
demand. CI runs it on `main` only via a dedicated workflow job (or it
remains entirely off-CI for v1.14 — the published numbers are a maintainer
artifact, not a CI gate).

### Optional CI integration (defer to RELEASE phase)

A dedicated workflow `bench.yml` triggered by `workflow_dispatch` and on
`v0.*` tags can run `mix verify.bench` against a larger Postgres instance.
This is **out of scope for v1.14** — the milestone goal is "publish
numbers", not "automate publishing on every release". Tracked as a v1.15+
follow-up if adoption pressure warrants.

### Where the published numbers live

`guides/performance.md` contains prose tables, e.g.:

| Operation | Median (ms) | p95 (ms) | Throughput (ops/sec) |
|---|---|---|---|
| INSERT row + trigger fires (with `actor_ref` GUC set) | … | … | … |
| `Threadline.Query.timeline/2` — 1M rows, 30-day window, indexed | … | … | … |

The doc-contract test asserts the **table structure** and **specific row
labels** (so future drift on naming fails CI), but not the numeric values
(which drift legitimately when re-baselined). Numbers in the table are
filled by the maintainer running `mix verify.bench` and pasting from the
JSON output — the JSON itself is not committed.

---

## 3. INCIDENT — `guides/incident-playbook.md`

### Decision: Pure docs + one example-app replay script

The "incident playbook" is a recipe book, not new capture or query
semantics. Five canonical incidents, each documented as a deterministic
recipe over the existing `Threadline.Query` / `Threadline.Export` /
`Threadline.as_of` / `Threadline.audit_changes_for_transaction` surface.
The example-app replay script reproduces one or two of them end-to-end
against the seeded fixtures already shipped in `priv/repo/seeds.exs`.

### File layout (NEW)

| Path | Status | Purpose |
|---|---|---|
| `guides/incident-playbook.md` | NEW | Five numbered incidents, each with the locked structure below. |
| `test/threadline/incident_playbook_doc_contract_test.exs` | NEW | Doc-contract test asserting the five `## N. Incident: <name>` headings and the four required subsections per incident (see structure below). |
| `examples/threadline_phoenix/priv/scripts/incident_replay.exs` | NEW | Runnable script: reads a slug from argv, replays one of the canonical incidents end-to-end (HTTP write → Oban job → corrupted state → recovery via `Threadline.history` + `as_of` + `audit_changes_for_transaction`). |
| `examples/threadline_phoenix/test/threadline_phoenix_web/incident_replay_script_test.exs` | NEW | Smoke test: invokes the script via `Mix.shell().cmd/2` against the test DB; asserts non-zero rows in expected output. |

### File layout (MODIFIED)

| Path | Why |
|---|---|
| `mix.exs` (`docs/0` → `extras`) | Add `guides/incident-playbook.md`. |
| `examples/threadline_phoenix/README.md` | Add "Incident replay script" subsection pointing at `priv/scripts/incident_replay.exs`. Locked by extension to existing example doc-contract test. |
| `examples/threadline_phoenix/priv/repo/seeds.exs` | Possibly extend to seed the fixtures the replay script needs (deterministic post slugs, known correlation IDs). |
| `examples/threadline_phoenix/test/test_helper.exs` | (Possibly) ensure seeds are loaded for the replay-script smoke test. |
| `guides/production-checklist.md` | Add cross-link "When something goes wrong: see [incident-playbook.md](incident-playbook.md)". |
| `guides/domain-reference.md` | Cross-link from "Support incident queries" section to the playbook. |
| `README.md` | Documentation list entry. Locked by `readme_doc_contract_test.exs`. |

### Locked structure for each incident

Each of the five incidents in `guides/incident-playbook.md` follows this
**fixed** structure (locked by the doc-contract test):

```markdown
## N. Incident: <one-line name>

**Scenario.** Three-to-five-line plain-language description of what
operations sees: symptom, time window, affected entity.

**Diagnosis (API).** Copy-pasteable Elixir snippet using public
Threadline functions (`Threadline.timeline/2`, `Threadline.history/3`,
`Threadline.as_of/4`, `Threadline.audit_changes_for_transaction/2`,
`Threadline.actor_history/2`, `Threadline.export_json/2`).

**Diagnosis (raw SQL).** The same answer expressed as a SELECT against
`audit_transactions` / `audit_changes` / `audit_actions` directly —
verbatim queryable in psql.

**Expected output.** A truncated example showing what the operator sees
(JSON or table). Numbers are illustrative; structure is locked.

**Recovery / next step.** What the operator does with the answer
(rollback, file ticket with which fields, retention-window note).
```

### The five canonical incidents

Recommended (subject to refinement during the phase):

1. **"Who changed this row, when?"** — Single-row history scoped by PK.
2. **"What did this user touch in the last hour?"** — Actor window across tables.
3. **"Show me everything tied to this support ticket."** — Correlation-ID bundle.
4. **"What did this row look like at 2 AM yesterday?"** — As-of point-in-time reconstruction.
5. **"Job 12345 corrupted state — show me its full transaction."** — Single audit-transaction drilldown via `audit_changes_for_transaction`.

These map 1:1 to the existing five "Support incident queries" in
`guides/domain-reference.md` plus the Time Travel addition (incident #4
is new — uses `as_of/4` shipped in v1.12). The playbook is the
**operator-facing rendering** of those queries with copy-paste recipes,
expected output, and recovery steps.

### Replay script layout (locked)

```elixir
# examples/threadline_phoenix/priv/scripts/incident_replay.exs
#
# Run: mix run priv/scripts/incident_replay.exs --incident=row-history --slug=demo-1
#
# Replays one of the five canonical incidents from guides/incident-playbook.md
# end-to-end against the example app's seeded data.

# 1. Parse argv (--incident, --slug)
# 2. Optionally trigger fresh writes (HTTP simulation via Plug.Test or Oban worker enqueue)
# 3. Run the diagnostic API call
# 4. Print the result as JSON to stdout
# 5. Exit 0 on success, non-zero on assertion failure
```

The smoke test (`incident_replay_script_test.exs`) shells out to
`mix run priv/scripts/incident_replay.exs --incident=row-history --slug=...`
and asserts the JSON output has the expected shape. This guards against
silent breakage of the published recipes.

---

## 4. RELEASE — `threadline 0.3.0`

### Decision: Last phase. Consolidates SIGRA + PERF + INCIDENT + ADOPT.

Release is **always last** in a feature milestone — it depends on
everything else being in `main`. The 0.2.x → 0.3.0 narrative is a
function of what shipped above it.

### File layout (NEW)

None for the release itself. The release phase produces a `v0.3.0` tag and
a Hex publish event; no new files beyond what feeder phases created.

### File layout (MODIFIED)

| Path | Change |
|---|---|
| `mix.exs` `@version` | `"0.2.0"` → `"0.3.0"`. Triggers `doc_source_ref/0` to compute `"v0.3.0"`. |
| `CHANGELOG.md` | New `## [0.3.0] - 2026-MM-DD` section. Promote `## [Unreleased]` content. New entries for SIGRA / PERF / INCIDENT / ADOPT. Quote PERF baseline numbers in narrative. |
| `README.md` install snippet | `{:threadline, "~> 0.2"}` → `{:threadline, "~> 0.3"}`. Locked by `readme_doc_contract_test.exs` (the test must be updated as part of this phase). |
| `examples/threadline_phoenix/README.md` | Mirror the install snippet update if it cites `~> 0.2` anywhere. Locked by `readme_doc_contract_test.exs`. |
| `mix.exs` (`docs/0` → `groups_for_modules`) | Add new `Integrations` group. |
| `mix.exs` (`docs/0` → `extras`) | Confirm new guides (`integrations/sigra.md`, `performance.md`, `incident-playbook.md`, `getting-started-saas.md`) are present in the list. |
| `mix.exs` (`docs/0` → `groups_for_extras`) | Add `Integrations: ~r{^guides/integrations/}` so the Sigra guide groups under "Integrations" rather than "Reference". |
| `.github/workflows/hex-publish.yml` | Confirm tag-trigger path matches `v0.3.0`; no change needed if existing pattern is `v*`. |

### `groups_for_modules` shape (locked)

The existing groups in `mix.exs:130-160` get a new entry inserted between
"Integration" and "Schemas":

```elixir
groups_for_modules: [
  "Core API": [
    Threadline,
    Threadline.Export,
    Threadline.Retention,
    Threadline.Retention.Policy,
    Threadline.Semantics.ActorRef,
    Threadline.Semantics.AuditContext
  ],
  Integration: [
    Threadline.Plug,
    Threadline.Job,
    Threadline.Health,
    Threadline.Continuity,
    Threadline.Telemetry
  ],
  Integrations: [
    # New in 0.3.0 — host-auth adapters; safe to extend with Pow, phx_gen_auth, etc.
    Threadline.Integrations.Sigra
  ],
  Schemas: [
    Threadline.Semantics.AuditAction,
    Threadline.Capture.AuditTransaction,
    Threadline.Capture.AuditChange
  ],
  "Mix Tasks": [
    # ... existing entries ...
  ]
]
```

Naming note: existing group is "Integration" (singular — `Threadline.Plug`
itself, the wiring contract). New group is "Integrations" (plural —
auth-source adapters under `Threadline.Integrations.*`). The plural form
signals "this list grows" and keeps the existing singular semantically
intact.

### `groups_for_extras` shape (locked)

```elixir
groups_for_extras: [
  Overview: ~r/README/,
  Integrations: ~r{^guides/integrations/},   # NEW — surfaces sigra.md
  Reference: ~r{^guides/},                    # existing
  Project: ~r/(CONTRIBUTING|CHANGELOG)/
]
```

Order matters: ExDoc takes the first regex match. Putting `Integrations`
before `Reference` is what makes `guides/integrations/sigra.md` group
correctly.

### Upgrade narrative (CHANGELOG.md)

The 0.2 → 0.3 section MUST include:
- **Added:** `Threadline.Integrations.Sigra` (with one-line guard explanation: optional dep, `nil` when Sigra not loaded).
- **Added:** `guides/incident-playbook.md`, `guides/performance.md`, `guides/getting-started-saas.md`, `guides/integrations/sigra.md`.
- **Added:** `bench/` harness + `mix verify.bench` alias.
- **Performance:** baseline numbers from `guides/performance.md` (quoted as a small table).
- **Changed:** `groups_for_modules` reorganized — `Integrations` group introduced. **Not** breaking; existing modules unmoved.
- **Upgrade notes:** Bump to `~> 0.3`. **No code changes required** for adopters not using Sigra. Sigra adopters: replace custom `actor_fn` with `&Threadline.Integrations.Sigra.actor_ref_from_conn/1`.

This is a **non-breaking minor** under 0.x convention but warrants the
0.3 bump because it adds a public namespace (`Threadline.Integrations.*`).

---

## 5. ADOPT — SaaS getting-started + maintainer-walked STG column

### Decision: New guide adjacent to `production-checklist.md`; refresh `adoption-pilot-backlog.md`

ADOPT is the entry-point doc — "I am a SaaS team, I have 30 minutes, get me
to a green audit-write." It cross-links to PERF (when adopters ask "how
fast is this?"), SIGRA (when their auth is Sigra-shaped), INCIDENT (when
they ask "what does ops look like?"), and the existing brownfield-continuity
guide.

The `adoption-pilot-backlog.md` STG column refresh **explicitly clarifies**
the column is **maintainer/CI evidence, not third-party attestation** — per
the v1.6 framing locked into the guide already. v1.14's job is to fill
**one** column completely as a worked example, not to attest to external
deployments.

### File layout (NEW)

| Path | Status | Purpose |
|---|---|---|
| `guides/getting-started-saas.md` | NEW | 30-minute SaaS quickstart. Sections: install, gen.triggers for one table, wire `Threadline.Plug`, write something, run a timeline query, see one incident playbook recipe, link to production-checklist. |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | NEW | Doc-contract test locking the section headings + the install snippet `~> 0.3`. |

### File layout (MODIFIED)

| Path | Why |
|---|---|
| `guides/adoption-pilot-backlog.md` | Fill one column of the STG matrix completely with maintainer-walked / CI-class evidence. Add explicit one-paragraph clarifier at the top of the STG section: **"This column is maintainer-walked CI evidence, not third-party attestation; integrators fork and supply their own evidence in their own forks/PRs."** |
| `mix.exs` (`docs/0` → `extras`) | Add `guides/getting-started-saas.md`. |
| `README.md` | Documentation list entry; "Start here for SaaS adopters" pointer. Locked by `readme_doc_contract_test.exs`. |
| `guides/production-checklist.md` | Cross-link at top: "First time here? Read [getting-started-saas.md](getting-started-saas.md) first." |
| `guides/brownfield-continuity.md` | Cross-link from intro: "If you are starting fresh, see [getting-started-saas.md](getting-started-saas.md)." |
| `test/threadline/stg_doc_contract_test.exs` | Extend to assert the new "maintainer-walked" clarifier paragraph literal. |

### Cross-link contract (locked)

`guides/getting-started-saas.md` MUST link to:
- `guides/production-checklist.md` (next step after the 30-minute quickstart)
- `guides/integrations/sigra.md` (if your auth is Sigra; otherwise see the example `audit_actor.ex`)
- `guides/incident-playbook.md` (when something goes wrong)
- `guides/performance.md` (how fast is this in production?)
- `guides/brownfield-continuity.md` (existing data and the "honest gap")
- `guides/adoption-pilot-backlog.md` (when you go to staging)

Each cross-link is locked by the doc-contract test at the literal-URL level.

---

## Build order & dependency graph

```
                            ┌─────────────────┐
                            │   PHASE 1: SIGRA│
                            │                 │
        ┌───────────────────┤  SIGRA-01       │
        │                   │  spec + adapter │ ──┐
        │                   └─────────────────┘   │
        │                            │            │
        │                            ▼            │
        │                   ┌─────────────────┐   │
        │                   │  SIGRA-02       │   │
        │                   │  example wiring │   │
        │                   └─────────────────┘   │
        │                            │            │
        │                            ▼            │
        │                   ┌─────────────────┐   │
        │                   │  SIGRA-03       │   │
        │                   │  guide + doc-   │   │
        │                   │  contract test  │   │
        │                   └─────────────────┘   │
        │                            │            │
        ▼                            │            ▼
┌─────────────────┐                  │   ┌─────────────────┐
│ PHASE 2: ADOPT  │                  │   │ PHASE 3: PERF   │
│                 │                  │   │                 │
│ ADOPT-01        │ ◀── parallel ────┼── │ PERF-01 harness │
│ getting-started │                  │   │ PERF-02 guide   │
│                 │                  │   │                 │
│ ADOPT-02        │                  │   └─────────────────┘
│ STG matrix col  │                  │            │
└─────────────────┘                  │            │
        │                            │            │
        │                ┌───────────┴────┐       │
        │                ▼                ▼       │
        │       ┌─────────────────┐               │
        │       │ PHASE 4:        │               │
        │       │ INCIDENT        │               │
        │       │                 │               │
        │       │ INCIDENT-01     │               │
        │       │ playbook + 5    │               │
        │       │ recipes         │               │
        │       │                 │               │
        │       │ INCIDENT-02     │               │
        │       │ replay script + │               │
        │       │ smoke test      │               │
        │       └─────────────────┘               │
        │                │                        │
        └────────────────┼────────────────────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ PHASE 5:        │
                │ RELEASE         │
                │                 │
                │ REL-01 mix.exs  │
                │   bump + ExDoc  │
                │   group refresh │
                │                 │
                │ REL-02 CHANGELOG│
                │   + README +    │
                │   tag + publish │
                └─────────────────┘
```

### Dependency rules (locked)

1. **SIGRA-01 → SIGRA-02 → SIGRA-03** (sequential within the SIGRA phase).
   The adapter must exist before the example can wire it; the example must
   exist before the guide can document end-to-end.

2. **PERF and ADOPT can run in parallel** (no shared files). PERF touches
   `bench/`, `mix.exs`, `guides/performance.md`. ADOPT touches
   `guides/getting-started-saas.md`, `guides/adoption-pilot-backlog.md`.
   Different file sets.

3. **INCIDENT depends on nothing structurally** but is **best landed
   after SIGRA** so its recipes can reference the Sigra-wired example app.
   If SIGRA slips, INCIDENT can use the existing Phase 23 stub actor —
   the recipes are not Sigra-specific.

4. **RELEASE blocks on everything else.** It bumps `@version` to `0.3.0`,
   updates `~> 0.3` snippets in README, refreshes `groups_for_modules` to
   surface `Threadline.Integrations.Sigra` (only valid if SIGRA-01
   landed), and quotes PERF numbers in CHANGELOG (only valid if PERF-02
   landed).

5. **Each phase is self-contained for `mix ci.all`.** Every phase's PR
   must leave `ci.all` green. The PERF harness alias `verify.bench` is
   the only exception to "everything goes through ci.all" — by design.

### Recommended phase numbering

Per `STATE.md`, phase numbering continues from 43. v1.14 starts at Phase 44:

| Phase # | Name | Requirements |
|---|---|---|
| 44 | Sigra integration adapter | SIGRA-01, 02, 03 |
| 45 | SaaS adopter onramp | ADOPT-01, 02 |
| 46 | Benchmark harness & published baselines | PERF-01, 02 |
| 47 | Incident playbook & replay script | INCIDENT-01, 02 |
| 48 | Threadline 0.3.0 release | REL-01, 02 |

Phases 45 and 46 can run in parallel branches; 47 sequences after 44; 48
sequences last after 44, 45, 46, 47 all merge to `main`.

---

## Files: NEW vs MODIFIED matrix

### NEW files (consolidated)

| Path | Phase | Purpose |
|---|---|---|
| `lib/threadline/integrations/sigra.ex` | 44 (SIGRA) | Adapter module |
| `test/threadline/integrations/sigra_test.exs` | 44 | Adapter unit tests |
| `test/support/sigra_test_doubles.ex` | 44 | Sigra struct shims for tests (when real dep absent) |
| `guides/integrations/sigra.md` | 44 | Sigra integration guide |
| `test/threadline/integrations/sigra_doc_contract_test.exs` | 44 | Doc contract for sigra guide |
| `guides/getting-started-saas.md` | 45 (ADOPT) | 30-minute SaaS quickstart |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | 45 | Doc contract for SaaS quickstart |
| `bench/README.md` | 46 (PERF) | Harness usage |
| `bench/audit_capture_bench.exs` | 46 | Capture-path benchmark |
| `bench/timeline_query_bench.exs` | 46 | Query-path benchmark |
| `bench/scripts/seed_audit_changes.exs` | 46 | Seeder |
| `bench/scripts/teardown.exs` | 46 | Truncate helper |
| `bench/results/.gitkeep` | 46 | Output dir placeholder |
| `guides/performance.md` | 46 | Published baselines + index recommendations |
| `test/threadline/performance_doc_contract_test.exs` | 46 | Doc contract for performance guide |
| `guides/incident-playbook.md` | 47 (INCIDENT) | 5-incident operator playbook |
| `test/threadline/incident_playbook_doc_contract_test.exs` | 47 | Doc contract for playbook |
| `examples/threadline_phoenix/priv/scripts/incident_replay.exs` | 47 | Runnable replay script |
| `examples/threadline_phoenix/test/threadline_phoenix_web/incident_replay_script_test.exs` | 47 | Replay-script smoke test |

### MODIFIED files (consolidated)

| Path | Phases that touch it | Change summary |
|---|---|---|
| `mix.exs` | 44, 45, 46, 47, 48 | New extras, new module groups, new aliases (`verify.bench`), version bump, Benchee dep |
| `README.md` | 44, 45, 46, 47, 48 | New documentation-list entries; install snippet `~> 0.2` → `~> 0.3` |
| `test/threadline/readme_doc_contract_test.exs` | 44, 45, 46, 47, 48 | Lock new README literals; update `~> 0.3` |
| `CHANGELOG.md` | 48 | 0.3.0 section consolidating all four feeder phases |
| `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` | 44 | Replace stub with Sigra-aware (guarded) extraction |
| `examples/threadline_phoenix/mix.exs` | 44 | Add `{:sigra, "~> 0.2", optional: true}` |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | 44 | Wire `actor_fn:` to `Threadline.Integrations.Sigra` |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` | 44 | Assert Sigra-derived actor mapping |
| `examples/threadline_phoenix/README.md` | 44, 47, 48 | Document Sigra path; replay script section; install snippet `~> 0.3` |
| `examples/threadline_phoenix/priv/repo/seeds.exs` | 47 | Deterministic fixtures the replay script depends on |
| `guides/production-checklist.md` | 45, 47 | Cross-links to getting-started-saas + incident-playbook |
| `guides/adoption-pilot-backlog.md` | 45 | Fill one STG column completely; add maintainer-walked clarifier paragraph |
| `guides/audit-indexing.md` | 46 | Cross-link to performance baselines |
| `guides/brownfield-continuity.md` | 45 | Cross-link to getting-started-saas |
| `guides/domain-reference.md` | 47 | Cross-link from "Support incident queries" to playbook |
| `test/threadline/stg_doc_contract_test.exs` | 45 | Lock the new clarifier paragraph |
| `CONTRIBUTING.md` | 46 | "Running the benchmark harness" section |
| `.gitignore` | 46 | Add `bench/results/*.json` |

---

## Integration with existing architecture

### Capture layer — UNTOUCHED

No changes to `lib/threadline/capture/`. Triggers, transaction grouping,
`txid_current()`-based `AuditTransaction.txid`, and the `threadline.actor_ref`
GUC contract are all stable. SIGRA delivers an `ActorRef` *into* the existing
GUC bridge; it does not change the bridge.

### Semantics layer — UNTOUCHED public surface

`ActorRef` stays at 6 closed types. `AuditContext` keeps its 4 fields
(`actor_ref`, `request_id`, `correlation_id`, `remote_ip`).

The six open design questions (impersonation, org scope, session.id, telemetry,
API tokens, anonymous) **may** force semantics-layer changes during the
SIGRA-01 spec phase. If they do, that work is contained to:

- `lib/threadline/semantics/audit_context.ex` (potentially: new optional fields)
- `lib/threadline/semantics/actor_ref.ex` (only if a new actor type is
  unavoidable — high bar; preference is to encode in `:id` or extend
  `AuditContext` instead)

The architecture document **does not pre-commit** these changes — it only
lists them as the contained blast radius if SIGRA-01 spec concludes one
is needed. Default expectation: SIGRA-01 ships without semantics-layer
changes.

### Exploration / ops layer — UNTOUCHED

INCIDENT-01 recipes call existing `Threadline.Query` / `Threadline.Export`
/ `Threadline.as_of` / `Threadline.history` / `Threadline.actor_history`
/ `Threadline.audit_changes_for_transaction` functions. No new public API.

PERF-01 measures performance of existing functions; it does not introduce
new ones. Recommended index sets in `guides/performance.md` cross-link to
the existing `guides/audit-indexing.md` — the PERF guide does **not**
duplicate or supersede the indexing cookbook.

### Plug surface (`Threadline.Plug`) — UNTOUCHED

`:actor_fn` callback signature `(Plug.Conn.t() -> ActorRef.t() | nil)`
is the entire SIGRA integration contract. No new options, no new
callbacks. Adopters write:

```elixir
plug Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1
```

If the SIGRA-01 spec phase concludes that `:correlation_id` should be
populated from `session.id` when `x-correlation-id` is absent, that
might motivate a `:context_overrides_fn` option on `Threadline.Plug`.
**Locked rule:** that decision belongs to SIGRA-01's spec phase. If it
adds a Plug option, it goes through the standard Threadline-core change
process (deprecation-aware, doc-contract-locked). It is **not**
pre-committed here.

---

## Confidence assessment

| Area | Confidence | Why |
|---|---|---|
| File layout (NEW/MODIFIED) | HIGH | Every path is grounded in existing repo conventions verified by directory listing |
| Optional-deps guard pattern | HIGH | `Code.ensure_loaded?/1` runtime probe is standard Elixir idiom; verified ergonomics in Threadline's own code style |
| `mix verify.bench` separation from `ci.all` | HIGH | OSS DNA explicitly forbids silent test exclusions in `ci.all`; sized-DB benchmarks are incompatible with PR-time CI |
| `groups_for_modules` shape | HIGH | Direct extension of existing pattern at `mix.exs:130-160`; no novel ExDoc behavior |
| Build order (RELEASE last) | HIGH | Standard release-engineering pattern; aligns with v1.4 / v1.10 / v1.13 sequencing in this repo |
| INCIDENT structure (5 sections per incident) | MEDIUM | Recommended structure based on the existing five-question pattern in `domain-reference.md`; final structure may refine during INCIDENT-01 |
| Whether to extend the existing example app vs. fork | MEDIUM | Strong recommendation here ("extend, do not fork") but reasonable people could disagree; decision should land in SIGRA-01 spec phase if there's any push-back |
| Six SIGRA design questions resolution | LOW | Deliberately unresolved here; defer to `/gsd-spec-phase sigra-integration-adapter` |

---

## Sources

- `lib/threadline/plug.ex` (lines 1–94) — `:actor_fn` callback contract
- `lib/threadline/semantics/actor_ref.ex` (lines 1–130) — 6 closed actor types
- `lib/threadline/semantics/audit_context.ex` (lines 1–20) — 4-field struct
- `lib/threadline.ex` (lines 1–175) — public API surface (delegators)
- `mix.exs` (lines 60–162) — aliases, ExDoc config, `groups_for_modules`
- `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` — Phase 23 stub
- `examples/threadline_phoenix/mix.exs` — example deps (path-dep on threadline)
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` — incident-JSON path pattern
- `guides/production-checklist.md` (header + §1–§7) — checklist shape
- `guides/adoption-pilot-backlog.md` (lines 1–100) — STG matrix shape and existing maintainer-walked clarifier
- `.planning/research/sigra-integration-context.md` — three-tier menu, six open questions, locked architectural framing
- `.planning/seeds/SEED-001-sigra-integration-adapter.md` — promoted seed; trigger conditions met
- `.planning/STATE.md` — v1.14 milestone state, phase numbering continues from 43
- `.planning/PROJECT.md` (lines 19–28, 171–178) — v1.14 milestone scope and active requirements
