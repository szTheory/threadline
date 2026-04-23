# Phase 12: Redaction at capture time - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>
## Phase Boundary

Teams can adopt auditing without storing raw secrets in `audit_changes` JSONB: **per-audited-table** exclude (keys absent from payloads) and mask (stable placeholder only, never raw) rules are consumed at **trigger generation** time so generated PL/pgSQL never persists excluded values or raw masked values in `data_after`, `changed_fields` (where applicable), or `changed_from` when enabled.

Out of scope for this phase: retention/purge (Phase 13), export (Phase 14), runtime policy tables in PostgreSQL, SIEM, app-layer-only redaction without trigger enforcement.

</domain>

<decisions>
## Implementation Decisions

### Configuration surface (Mix + host app)

- **D-01 — Canonical policy in application config:** The primary operator surface is **`config/*.exs`** under a single documented `config :threadline, …` key (exact key name left to plan — e.g. `:trigger_capture` or `:gen_triggers`). Structure is **data-only**: per-table entries listing **exclude** columns, **mask** columns, and existing knobs such as `store_changed_from` / `except_columns` alignment as unified in the plan. **No secrets** in config for substitution into SQL; only structural choices (column names, optional placeholder override string).

- **D-02 — Mix task remains the codegen entrypoint:** `mix threadline.gen.triggers` (or documented successor) **loads the host app config** (standard Mix project load) and emits migrations. Document **`MIX_ENV` parity** (CI vs local) so regenerated SQL matches expectations.

- **D-03 — CLI for scope and ergonomics, not a parallel policy language:** Keep **`--tables`** (required or as today) to declare **which tables** this migration generation run covers. Optional narrow flags: **`--dry-run` / print resolved policy** (stdout summary: table → exclude → mask) before writing files; avoid encoding full per-table matrices in bash long-term. **Quickstart / tiny apps** may use minimal examples in docs with small config snippets + one command.

- **D-04 — Optional dedicated policy file is deferred:** YAML/TOML checked-in policy is **not required for Phase 12**; if added later, it must normalize to the same internal shape as config and be documented as **one canonical source** (never ambiguous merge without `--strict`). Rationale: ship faster, match existing `:verify_coverage` config precedent, add file-based policy only if compliance explicitly needs non-Elixir diffs.

### Mask placeholder semantics

- **D-05 — Default placeholder is a library-defined constant:** Generated SQL uses a **single documented default token** (recommend literal form stable in JSONB, e.g. `"[REDACTED]"` or a namespaced string — pick one in plan and README). Same token for **all** masked columns unless overridden.

- **D-06 — Placeholder override only at codegen, validated in Elixir:** Host may override the default via **config** (not runtime DB lookup). Validation: max length, allowed character set, reject control characters; emit as **static quoted literal** inside `CREATE OR REPLACE FUNCTION`. **No** dynamic string assembly inside PL/pgSQL from GUC/env for the mask text.

- **D-07 — Per-table placeholder optional; per-column deferred:** Allow **optional per-table** placeholder override in config if low cost. **Do not** ship per-column placeholder variants in Phase 12 unless a plan explicitly pulls them in.

### Exclude, mask, and `changed_from`

- **D-08 — `exclude ∩ mask` is a hard error at codegen:** Intersection fails `mix threadline.gen.triggers` with a clear message listing columns. Semantics: **exclude** = key **absent** from all controlled JSONB payloads; **mask** = key **present** with placeholder only. No silent precedence.

- **D-09 — Redaction pipeline order:** For each relevant JSONB payload, **apply exclude first** (drop keys entirely), **then mask** listed keys among those remaining.

- **D-10 — Symmetry across `data_after` and `changed_from`:** Masking applies to values taken from **both `NEW` and `OLD`** wherever they appear in `audit_changes` (full-row `data_after`, sparse `changed_from`). Do **not** build `changed_from` from raw `to_jsonb(OLD)` and filter later unless a proof shows totality; prefer **per-key** redaction consistent with `changed_fields`.

- **D-11 — INSERT / UPDATE / DELETE parity:** **INSERT** and **UPDATE** `data_after` must be **post-processed** from `to_jsonb(NEW)` — never persist raw for excluded/masked columns (closes the gap where `--except-columns` today only affects `changed_fields` / `changed_from`, not full-row JSON). **DELETE** path unchanged (no row body beyond PK); document.

- **D-12 — Complex column types (json/jsonb):** Phase 12 treats masking of **json/jsonb** columns as **replace entire column value** with the placeholder (no deep redaction). Document explicitly; deep redaction is out of scope unless plan narrows otherwise.

### Trigger / function layout

- **D-13 — Per-table functions only when behavior is non-default:** Tables with **no** redaction rules and **no** `store_changed_from` continue to use the **global** `threadline_capture_changes()`. Any table with **exclude or mask rules** and/or **`store_changed_from`** gets a generated **`threadline_capture_changes_<table>()`** (same naming pattern as today) and triggers wired to it.

- **D-14 — Refactor toward shared SQL core (implementation strategy):** Reduce duplication between global and per-table bodies by factoring **invariant** logic (transaction upsert via `txid_current()`, `audit_changes` insert, read-only `current_setting('threadline.actor_ref', true)`) into **shared generated SQL** (helper `FUNCTION` or included fragment — exact shape in plan) so PgBouncer-safe behavior stays **single-reviewed**. Per-table wrappers supply **only** row JSON shaping (`data_after` / `changed_from` / `changed_fields` rules as literals). **No** `EXECUTE` / dynamic SQL for policy in v1.3.

- **D-15 — No new session writes in trigger path:** Redaction is pure computation on row images; **no** `SET LOCAL` / `set_config` writes from PL/pgSQL for redaction. Preserves Path B / roadmap success criterion 4.

### Documentation & testing expectations

- **D-16 — Operator docs:** README and/or `guides/domain-reference.md` document semantics (exclude vs mask, error on overlap, `changed_from` interaction, `MIX_ENV`, placeholder default, json column behavior).

- **D-17 — Testing alignment with roadmap:** Integration tests on PostgreSQL prove excluded keys absent from persisted payloads; masked columns show **only** the documented placeholder on INSERT/UPDATE/DELETE paths as scoped; tests cover `changed_from` when `--store-changed-from` is combined with mask.

### Claude's Discretion

- Exact config key atom (`:trigger_capture` vs `:gen_triggers` vs other), default placeholder string choice, and whether optional `--dry-run` ships in the same PR vs follow-up — planner picks **least churn** vs existing `:verify_coverage` naming.

### Folded Todos

_None._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — REDN-01, REDN-02
- `.planning/ROADMAP.md` — Phase 12 goal, success criteria (integration tests, docs, Path B safety)

### Capture architecture (locked)

- `.planning/milestones/v1.0-phases/01-capture-foundation/gate-01-01.md` — Path B decision (custom triggers, Carbonite gate outcome)
- `lib/threadline/capture/trigger_sql.ex` — Current global vs per-table function split, `except_columns` behavior, `to_jsonb(NEW)` / `OLD` usage
- `lib/mix/tasks/threadline.gen.triggers.ex` — Mix task flags and migration generation

### Operator and contributor docs

- `README.md` — `mix threadline.gen.triggers` quickstart, `--store-changed-from`, `--except-columns`
- `guides/domain-reference.md` — Domain semantics for operators (update with Phase 12 behavior)

### Prior art (external, for planner awareness)

- [Carbonite.Migrations.put_trigger_config/4](https://hexdocs.pm/carbonite/Carbonite.Migrations.html#put_trigger_config/4) — `excluded_columns`, `filtered_columns`, `store_changed_from` split (closest Elixir ecosystem analogue)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Threadline.Capture.TriggerSQL`** — `install_function/1`, `install_function_for_table/2`, `except_array_sql_fragment/1`, per-table function naming; extend or factor for redaction + optional shared core.
- **`Mix.Tasks.Threadline.Gen.Triggers`** — Option parsing, migration file generation, guard against auditing `audit_*` tables.

### Established patterns

- **Codegen-time literals** — Policy is baked into `CREATE OR REPLACE FUNCTION` SQL strings, not runtime Elixir in triggers.
- **Opt-in per-table** — `store_changed_from` already switches to per-table functions; redaction follows the same deployment axis.

### Integration points

- Host app **`config/*.exs`** — same layer as `config :threadline, :verify_coverage, expected_tables: [...]`.
- Generated files under host **`priv/repo/migrations/`**.

</code_context>

<specifics>
## Specific Ideas

Research synthesis (parallel review) emphasized: **git-reviewed migrations as system of record**; **config-as-policy** idiomatic next to existing Threadline config; **Carbonite-style** distinction between omitting columns vs replacing with a fixed token; **reject overlapping exclude/mask** to avoid silent leaks; **per-table functions only where needed** plus **shared SQL core** to limit duplication; **never mask only one of `data_after` / `changed_from`**.

</specifics>

<deferred>
## Deferred Ideas

- **Dedicated YAML/TOML policy file** — if compliance requests non-Elixir policy review; must normalize to one canonical merge story with `--strict`.
- **Per-column mask tokens** — only if a requirement explicitly demands distinct tokens per column at rest.
- **Carbonite-style “no audit row if only excluded columns changed”** — product decision separate from REDN; do not conflate with redaction unless roadmap adds it.
- **Deep redaction inside json/jsonb column values** — deferred past whole-value replacement.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 12-redaction-at-capture-time*  
*Context gathered: 2026-04-23*
