# Phase 25 — Technical research (LOOP-01)

**Question:** What do we need to know to plan correlation-aware timeline and export well?

## Current architecture

- **`Threadline.Query.timeline_query/1`** is the single composition root: `AuditChange` → `inner_join` `AuditTransaction` on `transaction_id`, then private filters (`filter_by_table`, `filter_by_actor`, `filter_by_from`, `filter_by_to`), then `order_by` on `captured_at`, `id`.
- **`validate_timeline_filters!/1`** iterates all pairs and only allows keys in `@allowed_timeline_filter_keys` (`:repo`, `:table`, `:actor_ref`, `:from`, `:to`). Extending this list and the `@moduledoc` table is mandatory for LOOP-01.
- **`export_changes_query/1`** calls `validate_timeline_filters!/1`, then `timeline_query/1`, then `select([ac, at], %{...})`. Any new join must keep **two bindings** in `select` unless the select tuple is intentionally extended (LOOP-01 JSON additive fields are handled in **`Threadline.Export`**, not in the SQL map row — the selected columns today are only `ac` + `at` fields).
- **`Threadline.Export`**: `to_csv_iodata/2`, `to_json_document/2`, `count_matching/2`, `stream_changes/2` all call `validate_timeline_filters!` + `timeline_repo!` and use `timeline_query` or `export_changes_query` — parity is preserved if **`timeline_query`** alone encodes correlation semantics.
- **Schemas:** `AuditTransaction` has optional `action_id` → `AuditAction`. `AuditAction` has `correlation_id` string field. Strict semantics (CONTEXT D-1): only rows where `action_id` is non-null **and** `audit_actions.correlation_id` matches filter — implemented as **`inner_join`** to `AuditAction` **only when** `:correlation_id` filter is present (no join on default path).

## Ecto patterns

- **Conditional join:** After building the filtered base query, branch on normalized correlation string: either return base or pipe `join(:inner, [ac, at], aa in AuditAction, on: at.action_id == aa.id and aa.correlation_id == ^cid)`. Bindings in downstream `select([ac, at], ...)`, `select([ac], ...)`, and `select([ac, _at], ac)` remain valid with a third binding present (use `_aa` or omit in select list).
- **Alternative `exists`:** Subquery on `AuditAction` correlated by `at.action_id` — fewer columns in join list but harder to read; CONTEXT allows planner/executor discretion.

## Validation (D-2)

- Absent or `nil` value for `:correlation_id` → no filter (key may be omitted; if key present with `nil`, treat as no filter **or** raise — CONTEXT says “If the key is present, value must be **binary()**” — so **`:correlation_id` absent** or **present with binary** only; `nil` with key present likely should raise for consistency with “strict types”. Re-read CONTEXT: "Allow **nil/absent** (no filter). If the key is present, value must be **binary()**" — so key present + nil → **ArgumentError**. Good.
- Trim with `String.trim/1`; empty after trim → `ArgumentError`; max **256 UTF-8 bytes** after trim → `ArgumentError`.

## Export surface (D-3)

- **`change_map/1`** today nests `transaction` object. Additive: nest **`action`** with at least `"correlation_id"` and `"id"` (action UUID as string) when `action_id` on transaction links to an action — requires **loading** action fields. **Gap:** `export_changes_query` select map does not include `action_id` or action columns; executor must either extend the select map (e.g. `action_correlation_id`, `action_uuid` as optional fields) or use a preload — **preferred:** extend `export_changes_query` select with optional fields from join when correlation filter is used **only** — actually JSON should show action metadata whenever the transaction has an action, not only when filtering. CONTEXT D-3: "when the transaction is linked to an action" — so always include in JSON when linked, which means the export query needs to **left_join** or subquery action for **payload** independent of filter. **Careful:** D-1 says inner_join **only when filter present** for filtering semantics; for **JSON enrichment** we may need a **left join** to `AuditAction` for read path when we want action on every row. That could double-join if filter also adds inner join.

**Resolution for planning:** Use a single **`left_join`** to `AuditAction` on `at.action_id == aa.id` for **payload** (nullable action fields in select), and for **filtering** when `:correlation_id` set, add `where(not is_nil(aa.id) and aa.correlation_id == ^cid)` — but left join + where on correlation reproduces inner join for matched rows. Simpler: **when filter set:** `inner_join` `AuditAction` with correlation predicate (excludes null action_id). **When filter unset:** no join for filter — for JSON fields, **`left_join`** `AuditAction` on `at.action_id == aa.id` so `change_map` can emit `action` object when `aa.id` not nil. Two joins to same table is awkward.

**Cleaner approach:** Always **`left_join`** `AuditAction` as `aa` on `at.action_id == aa.id` (one join). Filtering: when `:correlation_id` present, add `where(not is_nil(at.action_id) and aa.correlation_id == ^normalized)` — rows without action or wrong correlation drop out. When absent, no extra `where` on `aa`. This preserves "no join on default path" **only if** we interpret CONTEXT literally — CONTEXT D-1 says "Prefer **conditional** inner_join ... applied **only** when the filter is present — **do not add joins on the default path**."

So **strict reading:** no `AuditAction` join when filter absent → export select cannot include action columns without a second code path. CONTEXT D-3 still wants JSON additive fields when linked. That implies **`export_changes_query` must add a join** when we need action columns for JSON, OR **`change_map`** does not get action fields unless we add join only to export query path.

**Practical split (for plans):**

1. **`timeline_query`:** conditional **`inner_join`** `AuditAction` only when `:correlation_id` filter present (matches D-1, no join default path).
2. **`export_changes_query`:** must extend select for `tx_*` + action fields — use **`left_join`** `AuditAction` **only in `export_changes_query`** chain (starts from `timeline_query` — if `timeline_query` has no join, `export_changes_query` adds `left_join` for payload). But then `export_changes_query` = `timeline_query` |> maybe_left_join_action |> select — filter parity: **`timeline_query` without correlation** vs **export with left join** could change row multiplicity? `left_join` one-to-one on `action_id` is at most one action per transaction → no row duplication.

**Filter parity risk:** `timeline/2` uses `timeline_query` only; `export_changes_query` adds `left_join` for columns only — if `left_join` does not add `where`, row set identical. Good.

**Implementation order:** Plan task: implement `timeline_query` correlation branch first; then `export_changes_query` overlays `left_join` + extended select + `change_map` update; CSV extended flag.

## Testing

- Mirror **`ExportTest` "filter parity with timeline/2"`** with `:correlation_id` and fixtures: two transactions — one with `action_id` + `AuditAction` with correlation `"cid-a"`, one without or different correlation; insert changes; assert timeline ids == JSON export ids sorted.
- **`QueryTest`** DX-03 block: add valid `:correlation_id`, unknown key unchanged, empty string raises, overlong raises.
- **CSV:** one test with correlation filter + **`include_action_metadata: true`** (or chosen API name) asserting extra columns appended.

## Prior art (brief)

- OpenTelemetry trace membership: no span link → not in trace → aligns with strict inner join for filter-only path.
- Operator empty-result semantics: document “no rows” ≠ invalid id (D-5).

---

## Validation Architecture

This phase is **ExUnit**-driven Elixir library work. Automated verification is **`mix test`** scoped to affected modules plus **`mix compile --warnings-as-errors`** and **`mix format --check-formatted`** as project gates.

**Dimensions covered:**

1. **Unit / integration:** `Threadline.Query` validation and filtered timeline counts; `Threadline.Export` JSON/CSV paths.
2. **Regression:** Existing “filter parity” test pattern extended for `:correlation_id`.
3. **Docs:** CHANGELOG + moduledoc allowed-keys list grep-able in acceptance criteria.

**Sampling strategy:** After each logical task, run `mix test test/threadline/query_test.exs test/threadline/export_test.exs` from repo root; before phase close, full `mix test` (or `mix verify.test` if that is the project alias).

---

## RESEARCH COMPLETE

Findings are sufficient for `25-VALIDATION.md`, `25-PATTERNS.md`, and split plans **25-01** (query + validation + timeline semantics + CHANGELOG skeleton) and **25-02** (export payloads + CSV extended + integration tests).
