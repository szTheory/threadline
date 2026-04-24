---
phase: 29-audit-table-indexing-cookbook
status: clean
reviewed: 2026-04-24
---

# Phase 29 code review (advisory)

## Scope

- `guides/audit-indexing.md` — new cookbook
- `guides/domain-reference.md` — integrator-owned indexing pointer
- `guides/production-checklist.md` — retention-section link
- `mix.exs` — ExDoc extra
- `test/threadline/audit_indexing_doc_contract_test.exs` — IDX-02 anchors

## Findings

- **Accuracy:** Index names and DDL sources match `Threadline.Capture.Migration` / `Threadline.Semantics.Migration`; timeline vs `export_changes_query/1` join story matches `Threadline.Query` moduledocs and implementation (inner correlation path, left join when correlation absent for export).
- **Safety:** Optional DDL fenced block is explicitly non-mandatory with `CREATE INDEX CONCURRENTLY` guidance; no invented shipped index names.
- **Contracts:** Test surface matches 29-CONTEXT D-4 (headings + marker + cross-link paths, not full paragraph matrix).

## Recommendation

Ship as-is.
