---
status: passed
phase: "12"
verified_at: 2026-04-23
---

# Phase 12 verification (REDN-01 / REDN-02)

## Must-haves

| Requirement | Evidence |
|-------------|----------|
| REDN-01 / REDN-02 integration | `test/threadline/capture/trigger_redaction_test.exs` exercises PostgreSQL: excluded keys absent from `data_after`, masked values equal `[REDACTED]`, `changed_from` uses placeholder for masked column on UPDATE, DELETE leaves `data_after` null. |
| Mix codegen surface | `lib/mix/tasks/threadline.gen.triggers.ex` calls `Mix.Task.run("app.config", [])`, reads `:trigger_capture`, validates with `RedactionPolicy`, supports `--dry-run`. |
| Operator docs | README “Redaction at capture” section and `guides/domain-reference.md` “Redaction at capture” subsection document `exclude`, `mask`, overlap error, `MIX_ENV` parity, json/jsonb whole-value masking, and `trigger_capture`. |
| Path B | `grep` acceptance: no `SET LOCAL` / `set_config` in `lib/threadline/capture/trigger_sql.ex`. |

## Automated checks

- `DB_PORT=5433 MIX_ENV=test mix ci.all` — pass (format, credo, compile --warnings-as-errors, full test suite, verify_coverage, readme doc contract).

## Gaps

None identified for Phase 12 scope.
