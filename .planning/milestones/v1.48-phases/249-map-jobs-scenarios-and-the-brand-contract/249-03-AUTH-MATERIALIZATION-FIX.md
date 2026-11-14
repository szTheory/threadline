# Plan 249-03 corrective continuation: Sigra user materialization

## Correction

The accepted scenario-delivery boundary keeps Sigra user registration and confirmation as host fixture materialization. The original plan's Task 2 wording had broadened setup timestamp stamping to users, including `password_changed_at`, even though these rows are not registered for Threadline audit capture. This is a parent planning correction; it does not waive fixture correctness or change public scope.

Restored the original `upsert_users/1`, `upsert_extra_users/2`, `upsert_user!/3` and `maybe_confirm!/1` behavior from the pre-plan source: registration changeset, `Repo.insert!`, then conditional confirmation; existing users are confirmed only when `confirmed_at` is nil. Normal Sigra/application timestamps are retained for registration, password changes and confirmation. Seed setup S remains on audited organization, membership and agent rows, and all previously implemented business timestamp, actor, assignee, transaction and snapshot fixes remain intact.

## Regression proof

The contract test now asserts the 12 expected user emails and stable IDs, nonempty users, and nonnil confirmation. For each user's `inserted_at`, `updated_at`, `confirmed_at` and `password_changed_at`, it checks the real setup interval from the existing `seed_started_at`/`seed_finished_at` context keys. Bounds are normalized to the schema's second precision: floor the start to a second and use the next second after the floored end as the exclusive upper bound. It authenticates the seeded admin through the existing `Accounts.get_user_by_email_and_password/2` API. User rows are not expected to have Threadline capture records.

The red control ran before restoring source and failed because a user timestamp compared before the reset-window start (`DateTime.compare/2` returned `:lt`). After the fix, the targeted test passed. The test retains the original setup S assertions for audited business rows and all other chronology, actor, partial-order, filler, export, retention and redaction assertions.

## Verification and environment

Prepared example environment; no dependency installation or database recreation was needed. Test DB: `threadline_phoenix_testp24903`, PostgreSQL server `15.17 (Homebrew)`, `max_connections=100`. Runtime: Elixir `1.17.3`, Erlang/OTP `27`; local `pg_config` reports client tools `PostgreSQL 14.17 (Homebrew)`. Lock identities at verification time:

| File | `git hash-object` |
|---|---|
| `mix.lock` | `895c7a84d4c524198522ed55363fb77b9809a724` |
| `examples/threadline_phoenix/mix.lock` | `0acab236223ff789c5bd183c02b67bb115bbb3c4` |
| `examples/threadline_phoenix/e2e/package-lock.json` | `7d2c0874b7b311084ce1a41b3da75e8b368f5834` |

| Invocation | Result |
|---|---|
| `mix test test/threadline_phoenix/demo_contract_test.exs:230` before source fix | Expected red: exit 2; the selected test failed on a user timestamp before the real reset window. |
| `mix test test/threadline_phoenix/demo_contract_test.exs:230` after source fix | Pass: selected test, 0 failures. |
| `mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo/retention_tail_env_contract_test.exs test/threadline_phoenix/demo_manifest_test.exs test/threadline_phoenix_web/walkthrough_happy_path_test.exs test/threadline_phoenix_web/walkthrough_evidence_test.exs` | Pass: 41 tests, 0 failures. ExUnit emitted existing shape-fixture module redefinition warnings. |
| `mix format --check-formatted` | Pass. |
| `mix compile --warnings-as-errors` | Pass. |

An initial default-sandbox Git staging attempt was denied while creating the shared worktree index lock; it staged nothing. The same two authorized source/test paths were then committed with normal hooks after the scoped Git operation was approved by the automatic sandbox reviewer. No ignored files were force-added.

## Limits

These are local example checks only. No root-wide/canonical suite, full repeat, browser run, hosted CI, release, push or publication was run. The parent retains responsibility for reconciling the terminal managed-executor usage/timing receipt and any parent-owned phase metadata.
