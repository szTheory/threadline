# Phase 14: Export (CSV & JSON) - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>
## Phase Boundary

Support and ops obtain **CSV** and **JSON** representations of a **filtered** set of audit rows (minimum **`AuditChange`**), via a **documented public API**, with filter semantics **aligned with** `Threadline.Query.timeline/2`. README / guide must link export from `Threadline.Query` / timeline workflows per roadmap success criteria.

Out of scope: LiveView UI, SIEM connectors, arbitrary caller-supplied `Ecto.Query` as the **primary** v1.3 public contract, stdin-JSON filter CLI (may be a later phase), post-hoc redaction of stored audit JSON.

</domain>

<decisions>
## Implementation Decisions

### Filter contract & query parity (EXPO “same logical filter”)

- **D-01 — Public export mirrors `timeline/2`:** CSV and JSON entrypoints accept the **same** `filters` keyword list and `opts` as `Threadline.Query.timeline/2`, including **identical `:repo` resolution** (`Keyword.get(opts, :repo) || Keyword.fetch!(filters, :repo)`). Call sites that already drive a timeline can pass the same arguments to export.

- **D-02 — One internal query pipeline:** Implement (or extract) a **single private** function that builds the `Ecto.Query` for timeline filters — used by both `timeline/2` and export. No duplicated filter logic between query and export modules.

- **D-03 — Strict filters at the boundary:** Unknown or unsupported filter keys → **`ArgumentError`** with a message listing **allowed keys** (do not silently ignore). Aligns with “correct by default” and avoids false confidence on empty exports.

- **D-04 — No raw `Ecto.Query` as the v1.3 public export input:** Defer `export_from_query/2`-style APIs until a later phase unless planning proves a narrow, documented escape hatch is unavoidable. Prior art (Carbonite-style composition) is valuable later; Phase 14 optimizes for **one blessed filter vocabulary** and property-testable parity with `timeline/2`.

### Row shapes, encodings, and JSON stability

- **D-05 — CSV is “hybrid” and schema-stable:** Fixed columns: identity and sort-friendly scalars (`id`, `transaction_id`, `table_schema`, `table_name`, `op`, `captured_at` as **ISO 8601 UTC strings**) plus **JSON-encoded string columns** for structured payloads (`table_pk`, `data_after`, `changed_fields`, `changed_from`, and **transaction context** — see D-07). **Do not** explode `data_after` into dynamic per-column headers (unstable across tables and releases).

- **D-06 — JSON file uses a versioned wrapper:** Top-level object: `format_version` (integer, start at **1**), `generated_at` (ISO 8601 UTC), `changes` (array of change objects). Enables forward-compatible metadata without breaking tools that ignore unknown keys.

- **D-07 — Embed slim transaction context per change:** Use a **single query** with `JOIN` to `audit_transactions` (same pattern as `filter_by_actor` in `Query`). Each change object includes a nested **`transaction`** map (or equivalent fixed key) with at least `id`, `occurred_at`, `actor_ref`, `source` — enough for ops scripts without N+1 fetches. Accept duplicate txn fields across rows in the same DB transaction.

- **D-08 — NDJSON for large / pipeline consumers:** Offer an optional **newline-delimited JSON** mode (one JSON object per line) using the **same per-change map keys** as elements of `changes[]`, for log/ETL tooling and agents. Document that NDJSON is not a single JSON array document.

- **D-09 — Encoding rules:** **Jason** for JSON; **proper CSV writing** (e.g. **NimbleCSV** or equivalent) so commas, quotes, and newlines in JSON cells are RFC-safe. All datetimes in exports as **ISO 8601 UTC strings** for grep and interoperability.

- **D-10 — Tests assert semantics, not raw JSON bytes:** Prefer decode-then-map equality (or key subsets) over string equality for golden tests — avoids brittle key ordering across OTP/Jason versions.

### Large exports, memory, and streaming

- **D-11 — Safe-by-default bounded export:** Default path uses a **documented maximum row count** (implementation picks constant; document in README). Use `limit: max + 1` (or equivalent) to detect **truncation** and return **explicit metadata** (`truncated?: true`, `returned_count`, `max_rows`) so operators never mistake a cap for completeness. This is the primary answer to roadmap “large row count strategy” in the happy API.

- **D-12 — Streaming for power users = keyset pagination, not long-lived `Repo.stream` as the only story:** Expose a **`Stream.t()`** (or cursor-based API) built from **short transactions** / **keyset pages** on `(captured_at, id)` or documented stable ordering matching timeline order (`captured_at` desc — planner must define ascending cursor for export stability). Default page size conservative (order of **500–2000** rows). Document pool and timeout implications.

- **D-13 — Advanced `Repo.stream` documented, not the default:** If documented, require **`Repo.transaction`**, `timeout: :infinity` (with warnings), and **Oban/cron** contexts — not naive long-lived HTTP responses. Chunked HTTP / signed URLs remain **app** concerns; the library documents the footguns (Plug/proxy timeouts, pool starvation).

- **D-14 — JSONB size dominates memory:** Document that exporting full `data_after` for wide rows is expensive; optional **column omission / “metadata-only” profiles** are Claude’s discretion in plan if they simplify CSV for spreadsheets without blocking EXPO.

### Operator surfaces & DX

- **D-15 — Canonical implementation is a public module API** (e.g. `Threadline.Export.*` — exact module naming left to plan): All behavior integration-tested here; functions return **`{:ok, ...}` / `{:error, ...}`** or raise consistently with `Query` (pick one pattern in plan and apply uniformly).

- **D-16 — Thin Mix task mirrors Phase 13:** Ship **`mix threadline.export`** (final name in plan) that: loads **`app.config`**, resolves **`repo:`** the same way as `mix threadline.retention.purge`, parses argv (`--output`, format, filter flags mirroring timeline options, `--limit` / truncation behavior), and **delegates** to the public module. **No** logic that exists only in the task.

- **D-17 — Read-only but still explicit:** Export does not mutate audit data; a **`--dry-run` / row-count preview** (or default stdout banner with row count before bytes) is recommended for operator confidence — exact flags in plan. **No** stdin-JSON filter mode in v1.3 unless scope explicitly expands (defer per D-04 scope).

- **D-18 — Discoverability:** HexDocs and README tie text: “**Same filters as `Threadline.timeline/2`**” with cross-links; satisfy roadmap success criterion linking export from **`Threadline.Query` / timeline** workflows.

### Claude's Discretion

- Exact module/function names (`csv` vs `to_csv`, IO device vs `iodata`), default `max_rows`, NDJSON flag naming, whether `transaction` is nested vs flat keys in JSON, optional “minimal CSV” profile without large JSON columns, and whether `Repo.stream`-based helper ships in v1.3 or is doc-only.

### Folded Todos

_None._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — EXPO-01, EXPO-02
- `.planning/ROADMAP.md` — Phase 14 goal and success criteria (CSV/JSON APIs, tests, README linkage)

### Query contract (filter parity)

- `lib/threadline/query.ex` — `timeline/2` filters (`:table`, `:actor_ref`, `:from`, `:to`), join pattern for actor, `captured_at` bounds
- `lib/threadline.ex` — Public delegators to `Query`

### Schemas (export row shape)

- `lib/threadline/capture/audit_change.ex` — Fields: `table_pk`, `data_after`, `changed_fields`, `changed_from`, `op`, `captured_at`, etc.
- `lib/threadline/capture/audit_transaction.ex` — `actor_ref`, `occurred_at`, `source`, `txid`, `meta`

### Prior phase operator patterns

- `.planning/phases/13-retention-batched-purge/13-CONTEXT.md` — Mix + public API split, explicit `repo`, prod discipline, structured return values

### Domain & capture constraints

- `guides/domain-reference.md` — Audit model, operator semantics
- `.planning/PROJECT.md` — Path B / PgBouncer-safe capture, SQL-native audit, API-first ops story

### Prior export boundary

- `.planning/phases/12-redaction-at-capture-time/12-CONTEXT.md` — Export deferred to Phase 14; redaction already shapes stored JSON

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Threadline.Query.timeline/2`** — Authoritative filter set and ordering (`captured_at` desc); private helpers `filter_by_table`, `filter_by_actor`, `filter_by_from`, `filter_by_to` — export should reuse or share this pipeline.
- **`Threadline.Query.actor_history/2`** — Pattern for actor JSON containment on `AuditTransaction`.
- **Schemas** — `AuditChange` / `AuditTransaction` field names should map 1:1 into documented export columns.

### Established patterns

- **Explicit `repo:`** everywhere in `Threadline.Query` — export must not introduce implicit repo lookup.
- **Phase 13** — `Threadline.Retention.purge/1` + thin Mix task + Oban guidance; export should feel like the same operator family.

### Integration points

- Host apps: Oban workers, `mix run -e`, cron, and future HTTP download endpoints call the **public export module**; Mix task is for human/cron discoverability.
- **Tests:** PostgreSQL integration tests proving CSV + JSON happy paths, empty result set, and truncation / edge per roadmap.

</code_context>

<specifics>
## Specific Ideas

- User requested **research-backed, ecosystem-informed** decisions in one pass: filter parity with **`timeline/2`**, hybrid CSV + versioned JSON wrapper + optional NDJSON, **bounded default** with explicit truncation, **keyset-style streaming** over unbounded in-process loads, **public API + thin Mix task** aligned with retention, **strict filter keys**, **joined transaction context** to avoid N+1, **Jason + real CSV writer**, semantic (not byte) equality in tests.

</specifics>

<deferred>
## Deferred Ideas

- **Public `timeline_query/1` returning `Ecto.Query.t`** — Useful for Carbonite-style power users; not required for EXPO if D-02 internal pipeline is sufficient.
- **Caller-supplied `Ecto.Query` export API** — Deferred to avoid dual filter semantics (see D-04).
- **Stdin JSON filter specs for Mix** — Deferred (D-17); argv mirrors timeline first.
- **Dynamic CSV column explosion from `data_after` keys** — Explicitly out of scope (D-05).

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 14-export-csv-json*  
*Context gathered: 2026-04-23*
