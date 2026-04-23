---
status: passed
phase: "13"
verified_at: 2026-04-23
---

# Phase 13 verification (RETN-01 / RETN-02)

## Must-haves

| Requirement | Evidence |
|-------------|----------|
| RETN-01 — global retention window + validation | `lib/threadline/retention/policy.ex`, `config/test.exs` + `config/config.exs`, `guides/domain-reference.md` **Retention (Phase 13)**, README retention section. |
| RETN-02 — batched purge + Mix | `lib/threadline/retention.ex`, `lib/mix/tasks/threadline.retention.purge.ex`, `test/threadline/retention/purge_test.exs` (multi-batch + idempotency + orphan cleanup + `delete_empty_transactions: false`). |
| Referential behavior | Purge tests assert `audit_transactions` rows with zero children are removed when default is on; skipped when flag is false. |

## Automated checks

- `DB_PORT=5433 MIX_ENV=test mix ci.all` — pass (format, credo, compile `--warnings-as-errors`, full tests, `verify_coverage`, readme doc contract).

## Gaps

None identified for Phase 13 scope.
