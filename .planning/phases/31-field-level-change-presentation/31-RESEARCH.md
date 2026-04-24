# Phase 31 — Field-level change presentation — Research

**Question:** What do we need to know to plan **XPLO-01** / `Threadline.ChangeDiff` well?

---

## 1. Current capture truth (`AuditChange`)

- `op` is `"INSERT"`, `"UPDATE"`, or `"DELETE"` (string).
- `changed_fields` is populated for UPDATE semantics from triggers; **nil** on INSERT/DELETE paths in SQL (`trigger_sql.ex`).
- `changed_from` is **nil** when `store_changed_from` is off or when `changed_fields` is empty; otherwise a **sparse** JSON map (possibly `{}`) — never invent OLD values for columns not in the map.
- `data_after` is nil on DELETE; full snapshot on INSERT/UPDATE (subject to mask/exclude policy already reflected in persisted maps).
- `:mask` atom placeholder can appear in maps per redaction policy — diff must pass through unchanged.

---

## 2. Export parity reference (`Threadline.Export`)

- `change_map/1` is **private** (`defp`) and expects a **joined export row** (transaction fields, optional `aa_*` action columns).
- Public JSON export always uses **string keys**; `changed_from` defaults to `%{}` in the map when nil (`row.changed_from || %{}`).
- **Implication:** `format: :export_compat` (or `to_export_change_map/1`) from a bare `%AuditChange{}` must either:
  - expose a **new documented function** on `Threadline.Export` that builds the change slice from `%AuditChange{}` + optional transaction preload, or
  - duplicate only the **change-column** subset while documenting any fields that require a preload (e.g. nested `"transaction"` / `"action"`).
- CONTEXT D-2 locks **logical triple** `op`, `data_after`, `changed_fields`, `changed_from` for compat — prioritize matching those four plus stable ids (`id`, `transaction_id`, `table_schema`, `table_name`, `captured_at`, `table_pk`) as in export JSON.

---

## 3. API placement

- CONTEXT D-1: **`Threadline.ChangeDiff`** top-level module (sibling to `Query`, `Export`).
- Do **not** nest under `Threadline.Query` (reserved for Phase 32 listing).

---

## 4. JSON / Jason constraints

- Public API returns plain maps with **string keys** only (no structs in leaf positions that Jason would not encode the same as today’s export).
- Determinism: **`field_changes`** sorted lexicographically by `"name"` (UTF-8 byte order); any map keyed by field name sorted at build time.
- `schema_version: 1` at top level for the primary wire shape (distinct from export document `format_version`).

---

## 5. Epistemic edge cases (CONTEXT D-3, D-4)

- Row-level `before_values`: `"none"` | `"sparse"` (and reserved `"full"` for future).
- UPDATE + `before_values: "none"`: omit per-field `before` / `prior` keys entirely.
- UPDATE + sparse: missing key in `changed_from` for a column in `changed_fields` → per-field `prior_state: "omitted"` (exact string locked in tests/docs).
- INSERT default: empty or omitted `field_changes`; optional `expand_insert_fields: true` derives synthetic entries from `data_after` keys only — documented as derived.
- DELETE: no synthetic per-field removes; `data_after` nil.

---

## 6. Risks / footguns

- Iterating `Map.keys(data_after)` instead of **`changed_fields`** breaks `except_columns` honesty (D-5).
- Using `null` for both SQL null and “not captured” — forbidden by D-3; use omission vs `prior_state`.

---

## Validation Architecture

**Dimension 8 — Nyquist sampling for this phase**

| Dimension | How it is satisfied |
|-----------|----------------------|
| Automated regression | New **`test/threadline/change_diff_test.exs`** encodes golden map shapes (UPDATE none/sparse/full key present, INSERT default + expanded, DELETE, mask placeholder pass-through). |
| CI gate | `mix test test/threadline/change_diff_test.exs` on every task touching `change_diff.ex`; full `mix test` after wave 2. |
| Doc contract | ExDoc `@moduledoc` matrices; optional README one-liner only if other capability modules do the same for discoverability. |
| Manual | None required — behavior is pure functions of persisted structs. |

**Primary verification commands**

- Quick: `mix test test/threadline/change_diff_test.exs`
- Full: `mix compile --warnings-as-errors` && `mix test`

---

## RESEARCH COMPLETE

Findings above are sufficient to plan **`Threadline.ChangeDiff`**, export-compat surface, tests, and optional **`Threadline`** delegator without new capture SQL or migrations.
