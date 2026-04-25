---
phase: 31-field-level-change-presentation
status: passed
verified: 2026-04-24
---

# Phase 31 verification

## Goal (from roadmap)

**XPLO-01** — deterministic JSON-friendly presentation for `%AuditChange{}`, INSERT/UPDATE/DELETE + documented `changed_from` absence, unit tests for representative shapes.

## must_haves (from plans)

| Item | Evidence |
|------|----------|
| 31-01 `ChangeDiff` + docs | `lib/threadline/change_diff.ex` — `@moduledoc` matrix, `before_values` / `prior_state`, export relationship, `from_audit_change/2`, `:export_compat` |
| 31-02 tests + Jason | `test/threadline/change_diff_test.exs` — per-op `Jason.encode!/1`, sparse `prior_state`, mask `:mask`, lexicographic order, INSERT expand, DELETE, delegator |
| Threadline delegator | `lib/threadline.ex` — `defdelegate change_diff/2` |

## Automated checks

- `mix format`
- `mix compile --warnings-as-errors`
- `DB_PORT=5433 mix ci.all` — 166 + 7 tests, 0 failures (per project CI entrypoint)

## human_verification

None required (library + unit tests only).

## Gaps

None.
