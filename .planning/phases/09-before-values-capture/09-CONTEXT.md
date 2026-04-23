# Phase 9: Before-values capture - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Optional UPDATE **before-values** capture: when enabled per audited table at trigger-generation time, each UPDATE `AuditChange` persists a JSONB **`changed_from`** representing prior values for the change set; **INSERT** and **DELETE** rows keep **`changed_from` null** (BVAL-01). **`Threadline.history/3`** returns structs that include **`changed_from`** when populated, and **`nil`** when the feature is off or the column is null, without breaking existing callers (BVAL-02).

This phase does **not** deliver: product-level redaction/masking, retention, full-row `data_before` as a default, or behavior driven solely by runtime `config` without migration truth.

</domain>

<decisions>
## Implementation Decisions

### Before snapshot semantics (`changed_from` shape)

- **D-01:** **`changed_from` is a sparse JSONB map**: keys are the **columns that actually differed** on this UPDATE (the same set the trigger treats as changed — **one code path** with `changed_fields` / `IS DISTINCT FROM` logic). Values are the **prior scalar values** before the update. This is **not** a full `OLD` row snapshot by default.
- **D-02:** **SQL NULL in the prior value** is represented as explicit JSON **`null`** for that key when the column is in the change set (e.g. `{"notes": null}`). Keys must not “disappear” for columns listed in `changed_fields` — avoid conflating “not changed” with “was NULL.”
- **D-03:** **`data_after` remains the authoritative full post-image** (existing behavior). Operators compare **`changed_from` + `changed_fields` + `data_after`** for “from → to.” If a future milestone needs **one-shot full-row reify** from a single audit row, that is a **separate opt-in** (e.g. distinct column or flag), not the default `changed_from` semantics — avoids storage/PII blast radius on wide rows.

### Opt-in and source of truth (`store_changed_from`)

- **D-04:** **Schema vs behavior split:** `mix threadline.install` (and documented **upgrade** migrations) add **`changed_from jsonb NULL`** on `audit_changes` when missing — **library-wide, additive**, no per-table policy at install time.
- **D-05:** **`mix threadline.gen.triggers` is the authoritative per-table switch** for whether the installed trigger **writes** `changed_from` on UPDATE. Default for the flag is **`false`** (no before-values until explicitly enabled for that table’s generated migration). Emitted DDL is **option-aware** and **reviewable in git**.
- **D-06:** **Optional Mix config** may set **generator defaults only** (e.g. default for `--store-changed-from` in dev), **never** as the sole determinant of trigger behavior in PostgreSQL. If CLI flags and config disagree, **CLI / generated migration wins**.
- **D-07:** **Do not** use DB column DEFAULT or application-only config to imply capture of OLD — the **UPDATE branch of `threadline_capture_changes()`** (or table-specific variant emitted into migrations) encodes behavior. Phase 10’s **`verify_coverage`** may later warn on **column present vs function template mismatch**; not required for Phase 9 completion but compatible with this split.

### Public API and structs (BVAL-02)

- **D-08:** Add **`field :changed_from, :map`** (or the project’s established JSON type) on **`Threadline.Capture.AuditChange`**, backed by the nullable column. **No** separate return type for the default history path.
- **D-09:** Keep **`Threadline.history/3`** (`schema_module`, `id`, **`repo:`** required in opts) as the **only** public history entrypoint for this work — **do not** add `history/2` with implicit repo. **`Query.history/3`** must **not** use a `select` that omits `changed_from`** so the default path returns full `%AuditChange{}` rows including `nil` when appropriate.
- **D-10:** **No** `:with` / opt-in keyword to “include” `changed_from` — it is a first-class column, not an association. Reserve `opts` for real filters later (time bounds, etc.), not column toggles.

### Sensitive and heavy columns (v1.2 scope)

- **D-11:** **No** built-in pattern redaction or DLP in v1.2. **Do** ship a **generator-time escape hatch**: e.g. **`--except-columns col1,col2`** (name TBD in plan) on **`mix threadline.gen.triggers`** that bakes **omission of named columns** into the **generated trigger body** for building JSON snapshots (both the keys considered for `changed_from` and any related full-row reads — **single exclusion list**). Re-run/regenerate when schema adds new sensitive columns — same discipline as Logidze `--except` / PaperTrail `ignore`.
- **D-12:** **Document** that audit rows are **intentional duplicates** of base-table classification for any captured column; nested PII inside large `jsonb` columns is the **operator’s** responsibility if not excluded.

### Cross-cutting engineering

- **D-13:** **No `SET LOCAL`** (or new session coupling) in the capture path beyond **existing** GUC **read** for `actor_ref` — success criterion #4 from ROADMAP remains satisfied.
- **D-14:** **Trigger implementation** must compute **“which columns changed”** and **“prior values for those columns”** in one place so `changed_fields` and `changed_from` **cannot drift**.

### Claude's Discretion

- **Exact CLI flag names** (`--store-changed-from` vs `--before-values`, pluralization of `--except-columns`) and **PL/pgSQL implementation strategy** (`jsonb_each` diff vs explicit loop) — planner/researcher may choose consistent naming with existing `mix threadline.gen.triggers` style, subject to D04–D07 and D14.

### Folded Todos

_None._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — BVAL-01, BVAL-02 (before-values semantics and history API)
- `.planning/ROADMAP.md` — Phase 9 goal, success criteria (PostgreSQL tests, install path, `history`, no extra `SET LOCAL`)
- `.planning/PROJECT.md` — v1.2 vision, Path B capture, PgBouncer-safe constraints, out-of-scope redaction

### Capture contract and prior decisions

- `.planning/milestones/v1.0-phases/01-capture-foundation/gate-01-01.md` — Path B trigger choice, transaction-row semantics
- `.planning/milestones/v1.0-phases/01-capture-foundation/01-CONTEXT.md` — D-05/D-06 schema baseline, `audit_changes` columns
- `.planning/milestones/v1.0-phases/03-query-observability/03-CONTEXT.md` — `history/3`, explicit `repo:`, struct return shape

### Implementation touchpoints

- `lib/threadline/capture/trigger_sql.ex` — current `threadline_capture_changes()` body (extend or parameterize per generated migration)
- `lib/threadline/capture/audit_change.ex` — Ecto schema for `audit_changes`
- `lib/threadline/capture/migration.ex` — install DDL for `audit_changes`
- `lib/mix/tasks/threadline.gen.triggers.ex` — per-table trigger migrations
- `lib/threadline/query.ex` / `lib/threadline.ex` — `history/3` public API

### Research

- `.planning/research/SUMMARY.md` — architecture context referenced from roadmap

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Threadline.Capture.TriggerSQL`** — central place for `install_function/0`, `create_trigger/1`; Phase 9 likely adds **parameterized** SQL builders or **separate** function variants consumed by generated migrations (option-aware DDL per roadmap).
- **`Mix.Tasks.Threadline.Gen.Triggers`** — pattern for timestamped migration files and `execute` of inspected SQL strings — extend for **flags** that alter emitted SQL.
- **`Threadline.Capture.Migration`** / **`mix threadline.install`** — pattern for additive `audit_changes` columns in host migrations.

### Established patterns

- **Explicit `repo:`** on query APIs — carry forward; no implicit Repo.
- **Lists of structs, exceptions on DB errors** — unchanged for `history/3`.
- **JSONB maps** for `table_pk` and `data_after` — `changed_from` follows the same storage style.

### Integration points

- Host app **`mix ecto.migrate`** after install / gen.triggers — behavior must stay **migration-driven**, not runtime-config-driven.
- **Tests:** integration tests on PostgreSQL (per ROADMAP SC #1) assert UPDATE on/off, INSERT/DELETE null.

### Creative constraints

- Current trigger SQL **hardcodes** `'id'` for `table_pk` in examples — Phase 9 work should **not** widen that debt silently; planner should either **document** the limitation for composite PKs or align PK extraction with the **same** mechanism used for `changed_from` keys (follow-up if in scope for this phase).

</code_context>

<specifics>
## Specific Ideas

- **Ecosystem alignment:** Sparse `changed_from` keyed to the **changed set** matches **Carbonite**-style expectations and reduces surprise for Elixir adopters comparing libraries.
- **DX emphasis:** “**Install = column**, **gen.triggers = behavior**” is the one-sentence story for upgrades and support.

</specifics>

<deferred>
## Deferred Ideas

- **Full-row `OLD` snapshot** as a separate opt-in column or phase — only if product later demands one-shot reify without walking history; not default `changed_from`.
- **Runtime redaction / masking / DLP** — explicitly out of scope for v1.2 per `PROJECT.md`; generator `except` list is the only v1.2 mitigation.
- **`mix threadline.verify_coverage` warnings** for migration vs function template mismatch — Phase 10 (TOOL-01) territory; noted as compatible in D-07.

</deferred>

---

*Phase: 09-before-values-capture*
*Context gathered: 2026-04-23*
