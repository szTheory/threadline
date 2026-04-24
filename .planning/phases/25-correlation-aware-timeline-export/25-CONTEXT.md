# Phase 25: Correlation-aware timeline & export - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement **LOOP-01**: optional **`:correlation_id`** (string) on **`Threadline.Query.timeline/2`**, **`timeline_query/1`**, **`export_changes_query/1`**, and **`Threadline.Export`** entrypoints, with **`validate_timeline_filters!/1`** and **CHANGELOG** updates, plus integration tests proving timeline and export agree when the filter is set. Unset filter preserves current behavior. Out of scope: support playbooks (phase 26), example app correlation path (phase 27), LiveView, new capture semantics.

</domain>

<decisions>
## Implementation Decisions

### D-1 — Semantics when `:correlation_id` is present (`action_id` null)

- **Strict semantic correlation only:** When `:correlation_id` is set, include only `audit_changes` whose joined **`audit_transactions`** row has a **non-null `action_id`** and that action’s **`audit_actions.correlation_id`** equals the validated filter value (after normalization rules in D-2).
- **Implementation shape:** Prefer **conditional** `inner_join` (or equivalent **`exists`** subquery) to **`AuditAction`** on `transaction.action_id == action.id` and `action.correlation_id == ^cid`, applied **only** when the filter is present — do not add joins on the default path.
- **Rationale:** Matches locked LOOP-01 wording, aligns with OpenTelemetry-style “no span link = not in trace,” avoids false positives from capture-only rows, SQL is explainable to operators and compliance readers.
- **Explicit non-goal:** Do **not** add a second mode (e.g. “include orphans”) on the same `:correlation_id` keyword; if ever needed, use a **separate**, loudly named option in a future phase.

### D-2 — `:correlation_id` value validation (DX + least surprise)

- **Types:** Allow **`nil`/absent** (no filter). If the key is present, value must be **`binary()`**; otherwise **`ArgumentError`** with a clear message (consistent with strict unknown-key behavior).
- **Normalize:** Apply **`String.trim/1`** (UTF-8 codepoints). Do **not** apply Unicode NFC/NFD unless the product later normalizes at write time everywhere (out of scope).
- **Empty after trim:** **`ArgumentError`** — message states that omitting the key disables the filter. **Do not** coerce empty/whitespace-only to “no filter” (avoids accidental full result sets and matches “bad input fails fast”).
- **Max length:** **256 UTF-8 bytes** after trim; over limit → **`ArgumentError`**. Document in moduledoc / CHANGELOG (Stripe-adjacent bound, index-friendly).

### D-3 — Export payload (JSON vs CSV)

- **JSON (`to_json_document` / `change_map` pipeline):** Add **additive** fields when the transaction is linked to an action: at minimum **`correlation_id`** and **`action_id`** (string UUIDs as elsewhere). Prefer nesting under a small **`action`** object (or extend **`transaction`** consistently) — pick one shape in implementation and document it; goal is **`jq`**-friendly self-describing rows without re-running the query to see why a row matched.
- **CSV (default):** Keep **existing column order and names** unchanged for default **`to_csv_iodata/2`** so pipelines and strict positional consumers stay stable.
- **CSV (extended):** Add **`include_action_metadata: true`** (or `:csv_profile :extended` — planner chooses one name) that appends **trailing** columns, e.g. **`correlation_id`**, **`action_id`**, documented order. Default remains minimal.
- **Semver note:** JSON additive keys → document as non-breaking for tolerant clients; CSV extended profile → treat as **minor** API surface in CHANGELOG if not behind a major bump.

### D-4 — Tests and CHANGELOG

- **`validate_timeline_filters!/1`:** One focused test: **`:correlation_id`** is accepted when valid; unknown keys still raise with the existing error style.
- **Timeline ↔ export parity:** One integration test mirroring existing **“filter parity with `timeline/2`”** style: same `filters` including **`:correlation_id`**, assert **sorted change ids** from **`timeline/2`** match ids decoded from **`Export.to_json_document/2`** (JSON avoids CSV quoting/column-order coupling for **filter semantics**).
- **CSV:** Rely on existing CSV tests for format/truncation; add **one** case that uses **`:correlation_id`** with **extended CSV** (or default CSV if extended ships later) so the filter is exercised on the CSV path without duplicating full parity in both formats.
- **Avoid:** Golden-file snapshots of full export bytes; avoid **`Ecto.Query` struct equality** for this feature.
- **CHANGELOG:** Document new allowed filter key, validation rules, SQL-level semantics (link via `action_id`), and JSON/CSV behavior.

### D-5 — Operator messaging (docs / errors)

- When a filtered query returns **no rows**, document that this means **no changes linked to an `AuditAction` with that correlation** — not “invalid correlation id” unless validation failed first.

### Claude's Discretion

- **`exists` vs `join`** for the action correlation predicate (choose by query plan clarity and duplication risk with future joins).
- Exact **nested JSON field names** (`action` vs flat keys) as long as docs and tests stay consistent.
- Whether **extended CSV** is a keyword on **`to_csv_iodata`** vs a separate helper — either is fine if documented.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap

- `.planning/REQUIREMENTS.md` — **LOOP-01** (authoritative acceptance text for `:correlation_id`, timeline, export, validation, tests).
- `.planning/ROADMAP.md` — Phase 25 success criteria (v1.8 section).

### Domain & public API

- `prompts/audit-lib-domain-model-reference.md` — **AuditAction**, **AuditTransaction**, capture vs semantics boundary.
- `lib/threadline/query.ex` — `validate_timeline_filters!/1`, `timeline_query/1`, `timeline/2`, `export_changes_query/1`.
- `lib/threadline/export.ex` — `to_csv_iodata/2`, `to_json_document/2`, `stream_changes/2`, `count_matching/2` (all must share the same filter pipeline after LOOP-01).
- `lib/threadline/semantics/audit_action.ex` — `correlation_id`, association to transactions.
- `lib/threadline/capture/audit_transaction.ex` — optional `action_id`.

### Correlation ingress (context for tests/docs only; not expanded scope)

- `lib/threadline/plug.ex` — `x-correlation-id` → opts pattern.
- `lib/threadline/job.ex` — correlation from Oban args.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`timeline_query/1`** — Single pipeline for `timeline/2`, `export_changes_query/1`, `Export.count_matching/1`, `Export.stream_changes/2`; extend here (plus validation list) so all surfaces stay aligned.
- **`AuditAction` / `AuditTransaction` schemas** — FK and fields already model the join LOOP-01 needs.

### Established patterns

- **Strict filter keys** — Unknown keys raise **`ArgumentError`** with allowed-key list; new key must be added to `@allowed_timeline_filter_keys` and docs in lockstep.
- **`:repo` resolution** — `timeline_repo!/2`; keep correlation in **`filters`** (not a separate global) for parity with other dimensions.

### Integration points

- Tests likely use **`Threadline.Test.Repo`**, **`DataCase`**, and existing audit insert helpers — follow trigger-aware setup from neighboring timeline/export tests.

</code_context>

<specifics>
## Specific Ideas

- Research synthesis (2026-04-24): Prior art (OTel trace membership, CloudTrail self-describing events, strict vs silent empty correlation filters) supports **strict join semantics**, **reject empty correlation after trim**, **additive JSON identifiers**, **opt-in extended CSV**, and **JSON-first parity test** between timeline and export.

</specifics>

<deferred>
## Deferred Ideas

- **Separate query mode** (“include capture without action”) — new capability; not LOOP-01.
- **Unicode normalization** of correlation strings — only if write path normalizes consistently across apps.
- **Full CSV+JSON duplicated parity matrices** — unnecessary unless implementation diverges.

### Reviewed Todos (not folded)

- None from `todo.match-phase` for phase 25.

</deferred>

---

*Phase: 25-correlation-aware-timeline-export*
*Context gathered: 2026-04-24*
