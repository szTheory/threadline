# Plan 13-01 Summary: Retention policy, config & operator docs (RETN-01)

## Outcome

Added `Threadline.Retention.Policy` with `validate_config!/1`, `resolve!/1`, and `cutoff_utc_datetime_usec!/1` for a global `:keep_days` / `:max_age_seconds` window, `enabled`, and `delete_empty_transactions`. Wired `config :threadline, :retention` for test and non-test envs. Documented `captured_at` semantics vs `Threadline.Query.timeline/2` and purge in `guides/domain-reference.md` and README.

## Commits

- `feat(13-01): add retention policy module, config, and operator docs (RETN-01)`

## Self-Check

- `MIX_ENV=test mix compile --warnings-as-errors` — pass
- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/retention/policy_test.exs` — pass
- `MIX_ENV=test mix run -e 'Application.ensure_all_started(:threadline); Threadline.Retention.Policy.validate_config!(Application.get_env(:threadline, :retention))'` — pass

## Deviations

None.
