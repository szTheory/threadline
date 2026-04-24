---
status: passed
phase: 25-correlation-aware-timeline-export
verified: 2026-04-24
---

# Phase 25 verification

## Automated

- `mix format --check-formatted` — pass
- `mix compile --warnings-as-errors` — pass
- `DB_PORT=5433 mix test` — pass (152 tests, 1 excluded)

## Must-haves (from plans)

| Criterion | Evidence |
|-----------|----------|
| `:correlation_id` in allowed filter keys; unknown keys raise | `validate_timeline_filters!/1` tests + existing unknown-key tests |
| Strict join when filter set | `LOOP-01` query test: only linked transaction rows |
| Default path no extra join in `timeline_query` | `Keyword.get(..., :correlation_id) == nil` branch |
| Export JSON `action` when linked | `export_test.exs` JSON parity + `action` assertions |
| JSON timeline↔export parity with `:correlation_id` | `LOOP-01` describe in `export_test.exs` |
| CSV default unchanged; extended opt-in | Existing CSV column count test; new 13-column extended test |
| CHANGELOG Unreleased | LOOP-01 bullets added |

## Human verification

None required for this phase (library-only; operators validate via tests and docs).
