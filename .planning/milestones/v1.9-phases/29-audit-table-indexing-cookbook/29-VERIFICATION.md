---
phase: 29-audit-table-indexing-cookbook
status: passed
verified: 2026-04-24
---

# Phase 29 verification

## Goal (from roadmap)

Dedicated **audit indexing** cookbook (IDX-01) aligned with timeline, export, correlation, and retention access patterns, plus **doc contract** coverage (IDX-02) so spine anchors cannot drift silently.

## must_haves (from plans)

| Item | Evidence |
|------|----------|
| IDX-01 cookbook + navigation | `guides/audit-indexing.md` — marker `IDX-02-AUDIT-INDEXING`, installed default index names matching migrations, table primers, access-pattern H2s, join semantics (inner vs left), `Threadline.Retention`, `mix.exs` `extras`, links from `guides/domain-reference.md` and `guides/production-checklist.md` |
| IDX-02 doc contract | `test/threadline/audit_indexing_doc_contract_test.exs` — marker + spine headings + `domain-reference.md` / `production-checklist.md` strings |

## Automated checks

- `mix format`
- `mix compile --warnings-as-errors`
- `DB_PORT=5433 MIX_ENV=test mix test` — 156 tests, 0 failures (includes new doc contract module)

## human_verification

None required (documentation + contract tests only).

## Gaps

None.
