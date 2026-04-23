# Plan 12-02 Summary: Mix task, integration tests, operator docs

## Outcome

- **`config/test.exs`**: `config :threadline, :trigger_capture, tables: %{"test_redaction_users" => [...]}` for CI and generator coverage.
- **`mix threadline.gen.triggers`**: loads `app.config`, reads `:trigger_capture`, validates redaction with `RedactionPolicy`, emits per-table SQL when `store_changed_from` **or** non-empty exclude/mask; **`--dry-run`** prints resolved policy lines without writing a migration.
- **`test/threadline/capture/trigger_redaction_test.exs`**: PostgreSQL integration tests for REDN-01 / REDN-02 (INSERT/UPDATE/DELETE).
- **README** + **`guides/domain-reference.md`**: operator semantics for exclude, mask, `MIX_ENV` parity, json/jsonb whole-value masking, Path B reminder.

## CI / hygiene fixes (same execution window)

To satisfy `mix ci.all` on this workspace:

- **`lib/threadline/verify/coverage_policy.ex`**: sort violations by kind (`:missing` before `:uncovered`) then table name — matches documented contract test.
- **`test/threadline/continuity_brownfield_test.exs`**: load PK via Ecto and update with `Repo.update_all/2` so UUID types match Postgrex encoding.
- **`.planning/phases/06-ci-on-github/06-VERIFICATION.md`**: restored from milestone archive for Nyquist doc-contract test.

## Commands

- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/capture/trigger_redaction_test.exs test/threadline/capture/trigger_changed_from_test.exs test/threadline/capture/trigger_test.exs` — pass
- `MIX_ENV=test mix threadline.gen.triggers --tables test_redaction_users --dry-run` — pass
- `DB_PORT=5433 MIX_ENV=test mix ci.all` — pass

## Self-Check

PASS — integration tests and full CI chain green with Docker Postgres on port **5433** (see `config/test.exs` defaults).

## Security / Path B

No `SET LOCAL` / `set_config` in trigger SQL builders; redaction remains static SQL. Review note: mask placeholder is validated in Elixir before embedding as a single-quoted literal.
