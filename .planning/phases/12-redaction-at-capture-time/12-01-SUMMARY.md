# Plan 12-01 Summary: Trigger SQL + redaction policy

## Outcome

Implemented `Threadline.Capture.RedactionPolicy` (codegen-time validation) and extended `Threadline.Capture.TriggerSQL` with `:exclude`, `:mask`, and `:mask_placeholder` for the global and per-table capture functions. Legacy SQL when rules are empty matches pre–Phase 12 output. Per-table functions can be emitted with redaction **without** `store_changed_from` when only masking/excluding applies.

## Commits

- `feat(12-01): add RedactionPolicy for trigger redaction validation`
- `feat(12-01): add exclude/mask paths to TriggerSQL`

## Line counts (`trigger_sql.ex`)

- Before (git `HEAD` at start of execution): **253** lines
- After refactor + redaction paths: **553** lines (`wc -l lib/threadline/capture/trigger_sql.ex`)

Net growth is expected: new redacted SQL builders and per-table redaction branches; duplication between txn upsert and `audit_changes` insert is centralized via `transaction_capture_begin_sql/0`, `audit_change_insert_sql_global/0`, and `audit_change_insert_sql/0` for paths that share them.

## Self-Check

- `MIX_ENV=test mix compile` — pass
- `grep -nE 'set_config|\\bSET LOCAL\\b' lib/threadline/capture/trigger_sql.ex` — exit 1 (no matches)
- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/capture/trigger_changed_from_test.exs test/threadline/capture/trigger_test.exs` — pass
- `RedactionPolicy` overlap / placeholder acceptance commands from PLAN — pass

## Deviations

None.
