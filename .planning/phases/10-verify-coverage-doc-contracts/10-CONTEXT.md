# Phase 10: Verify coverage & doc contracts - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **TOOL-01** (`mix threadline.verify_coverage`): human-readable trigger coverage report aligned with **`Threadline.Health.trigger_coverage/1`** for the same database state; **non-zero exit** when any **explicitly expected** audited table lacks a valid Threadline capture trigger. Ship **TOOL-03**: automated checks so **README** (and linked quickstart scope below) cannot silently drift from the **documented public** Threadline API. Wire both into **default contributor CI** so local `mix ci.all` and the Postgres-backed GitHub Actions job stay honest (roadmap SC3 / SC4).

**Out of phase:** backfill / continuity (**TOOL-02**, Phase 11); multi-schema `Health` extensions beyond what exists today (may note as follow-up only); optional JSON output for `verify_coverage` (defer unless planner needs it).

</domain>

<decisions>
## Implementation Decisions

### Expected audited tables (TOOL-01 policy)

- **D-01:** **`Threadline.Health.trigger_coverage/1` remains the only implementation of catalog truth** (same SQL, same `{:covered | :uncovered, table}` tuples, same telemetry path). **`mix threadline.verify_coverage` must not fork duplicate `pg_trigger` / `pg_tables` queries** — any new API is a **pure composition** over `trigger_coverage/1` results (optional filter/reduce in `lib/`, not a second query story).
- **D-02:** **“Expected audited tables” are an explicit host-supplied set** (idiomatic Elixir: like Oban queues / explicit Repo wiring), **not** “every `public` table must have a trigger.” That avoids the main footgun of treating join tables, Oban, caches, etc. as audit failures while staying honest for real business tables.
- **D-03:** **Primary mechanism: `Application` config** scoped to the host app (exact key path left to plan-phase — e.g. under the host app’s config namespace with a `:threadline` or `:verify` subsection). Support **`ignore_tables`** / small **escape hatches** only if needed for rare noise; document defaults clearly.
- **D-04:** **Fail closed for the gate:** if the Mix task is invoked for **verification** (default CI path) and the expected set is **missing or empty**, **exit non-zero with an actionable message** (via `Mix.raise` or equivalent) — do not silently treat “no config” as “all public tables.” This matches **correct-by-default** and REQUIREMENTS intent (“expected table list mechanism defined in Phase 10 plan”).
- **D-05:** **Alignment with Health (roadmap SC4):** pass/fail is computed **only** from tuples returned by `trigger_coverage/1` intersected with the configured expected set. Integration test: fixture DB → **same** tags for overlapping tables whether called from `iex` or the Mix task.
- **D-06:** **Schema scope:** until `Health` grows multi-schema options, verify inherits **`public` only** — document explicitly; do not imply coverage for non-`public` schemas.

### Mix task UX and exit semantics

- **D-07:** **Thin Mix task:** argv parsing, `Mix.Task.run("app.config")` / `app.start` (or equivalent) to load host repo, resolve **`:repo`**, call library API, format output, set exit. **No duplicated SQL.**
- **D-08:** **Default output:** human-readable **tabular layout + one-line summary** to **stdout** via `IO.puts` / `IO.write` (deterministic CI logs). **Respect `NO_COLOR`**; optional `--no-color` if useful for snapshots. **Optional `--format json`:** defer to a follow-up unless planner proves trivial — not required for Phase 10 closure.
- **D-09:** **Exit codes:** **`0`** = all expected tables `:covered`; **`1`** = at least one expected table `:uncovered` (audit failure); **invalid invocation / missing repo / bad config** → `Mix.raise` (non-zero, single class acceptable; optional distinct `2` only if trivial). **Logger** reserved for optional **`--verbose`**, not the default gate path.
- **D-10:** **Testing split:** unit tests for pure policy (expected ∩ tuples → violations); integration test with fixture repo / DB proving **non-zero exit** when an expected table lacks `threadline_audit_%` trigger (per roadmap SC1).

### Doc contract tests (TOOL-03)

- **D-11:** **Do not rely on `Code.string_to_quoted!/2` alone** — it catches syntax, not **renamed or removed APIs**. Primary enforcement: **compile-checked Elixir** under `test/` (or `examples/` compiled from tests) that mirrors README / quickstart **critical** paths so `mix test` fails on API drift.
- **D-12:** **Hybrid is intentional:** (a) **canonical snippet modules** compiled by the suite; (b) **`doctest` on `@moduledoc`** where `iex>` style fits public API; (c) **one minimal extra path** only if needed for Repo/config integration — avoid N example apps unless planner proves necessary.
- **D-13:** **“Public API” definition for drift checks:** modules meant for adopters = **documented in ExDoc without `@moduledoc false`**, plus any **explicit allowlist** in test helper if something must stay public but hidden from docs. **`groups_for_modules` in `mix.exs` is layout only**, not a visibility boundary — do not use it as the sole enforcement list.
- **D-14:** **README scope for TOOL-03:** **README.md** in full; **linked quickstart** = fenced Elixir in README that represents onboarding (and, if CONTRIBUTING duplicates critical API calls, keep **one** canonical source — prefer README + compile-checked mirror to avoid two-way drift).

### CI wiring and contributor honesty

- **D-15:** **New `mix verify.*` atoms** for discrete concerns, composed into **`ci.all`** — e.g. `verify.threadline` (runs `mix threadline.verify_coverage`) and `verify.doc_contract` (runs targeted test path or tag). **Extend** the existing `"ci.all"` alias chain to include them **after** `verify.test` (DB and migrations already established).
- **D-16:** **GitHub Actions:** run DB-dependent verification **inside the existing `verify-test` job** as **extra steps after** `mix verify.test`, reusing the **same Postgres service and `MIX_ENV=test`** — avoids a new required job id, duplicate containers, and “green locally / red in CI” from different graphs. **Do not** make Threadline-only gates Actions-only without a matching `mix` alias on the blessed full gate.
- **D-17:** **Nyquist / CI contract:** update **`test/threadline/phase06_nyquist_ci_contract_test.exs`** CI-02 literal to the **new canonical `ci.all` string** whenever the alias list changes — keeps “local parity” test true.
- **D-18:** **CONTRIBUTING:** document **full gate** = `MIX_ENV=test mix ci.all` (Postgres required) vs optional **quick slices** (`mix verify.format`, etc.). **README `**CI:**` paragraph:** briefly state that **`verify-test` includes the test suite and Threadline verification/doc-contract steps** so README stays aligned with Actions.

### Claude's Discretion

- **Exact config key names** and **whether `verify_coverage` accepts CLI overrides** (e.g. `--expect users,posts`) in addition to config — planner chooses consistent naming with existing `mix threadline.gen.triggers` / install tasks.
- **Exact markdown extraction strategy** if any README fence is mechanically cross-checked (prefer compile-first mirrors over fragile regex).
- **Optional `boundary` dependency** for structural “public vs internal” enforcement — nice-to-have, not a Phase 10 blocker if allowlist + `@moduledoc false` discipline suffices.

### Folded Todos

_None._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — TOOL-01, TOOL-03
- `.planning/ROADMAP.md` — Phase 10 goal and success criteria (fixture failure, log readability, CI default, Health alignment)
- `.planning/PROJECT.md` — v1.2 vision, OSS quality bar, `mix verify.*` / `mix ci.*` baseline

### Prior phase and research

- `.planning/phases/09-before-values-capture/09-CONTEXT.md` — D-07 compatibility note for future template/column warnings; Path B / no `SET_LOCAL` in capture path
- `.planning/research/SUMMARY.md` — maintainer tooling direction
- `.planning/research/PITFALLS.md` — doc tests that do not compile real snippets; doc drift class of pitfalls

### Implementation touchpoints

- `lib/threadline/health.ex` — `trigger_coverage/1` (single source of catalog truth)
- `mix.exs` — `aliases` / `ci.all` / `preferred_envs`
- `.github/workflows/ci.yml` — job id contract (`verify-test` + Postgres service)
- `test/threadline/phase06_nyquist_ci_contract_test.exs` — CI-02 local parity literal for `ci.all`
- `test/threadline/health_test.exs` — existing Health tests to extend for parity
- `README.md`, `CONTRIBUTING.md` — CI honesty and contributor docs

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Threadline.Health.trigger_coverage/1`** — returns covered/uncovered tuples; telemetry `:health, :checked`; exclude audit tables `@audit_tables`.
- **`mix.exs` `ci.all`** — today `verify.format` → `verify.credo` → `compile --warnings-as-errors` → `verify.test`; `preferred_envs: ["ci.all": :test]`.
- **`Threadline.Phase06NyquistCIContractTest`** — asserts exact `ci.all` string for CI-02 parity.

### Established patterns

- **Mix tasks** in `lib/mix/tasks/threadline.*` use `Mix.raise` for invalid use; follow same tone for configuration errors.
- **Integration tests** use test Repo + PostgreSQL per existing capture/health tests.

### Integration points

- **New Mix task** under `lib/mix/tasks/threadline/verify_coverage.ex` (or naming per existing task namespace).
- **Optional small module** next to `Threadline.Health` for pure “expected vs tuples” policy if it keeps `health.ex` focused.

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** discuss areas be researched in depth (subagents) and **one coherent recommendation set** — captured as D-01–D-18 above; emphasis on **least surprise**, **great DX**, **library-idiomatic** Elixir/Ecto patterns, and **parity with successful audit OSS** (explicit opt-in tables, not catalog-wide false positives).

</specifics>

<deferred>
## Deferred Ideas

- **JSON / machine-readable default** for `verify_coverage` — only if a concrete consumer appears.
- **`Health` multi-schema** — separate phase if product requires it.
- **`boundary` or Hex `files:` trimming** for hard API enforcement — evaluate after doc-contract MVP.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 10-verify-coverage-doc-contracts*
*Context gathered: 2026-04-23*
