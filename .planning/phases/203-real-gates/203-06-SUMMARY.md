---
phase: 203-real-gates
plan: 06
subsystem: code-quality
status: complete
tags: [credo, dialyzer, typespecs, gate-02, gate-05]
requires: [203-05]
provides:
  - "lib/ has no mechanical Credo findings under full defaults (only Nesting, CyclomaticComplexity and the deferred Logger finding remain)"
  - "Public types Threadline.Capture.AuditChange.t/0, Threadline.Capture.AuditTransaction.t/0, Threadline.Semantics.ActorRef.t/0"
  - "Lib half of GATE-05: no comment in lib/ cites a file.ex:NN location"
affects: [203-07, 203-09, 203-10]
tech-stack:
  added: []
  patterns:
    - "Struct specs use Module.t() backed by @typedoc + @type t :: %__MODULE__{}"
    - "Function-level implicit rescue instead of a try block wrapping the whole body"
key-files:
  created: []
  modified:
    - lib/threadline/capture/audit_change.ex
    - lib/threadline/capture/audit_transaction.ex
    - lib/threadline/semantics/actor_ref.ex
    - lib/threadline/query.ex
    - lib/threadline/change_diff.ex
    - lib/threadline/integrations/sigra.ex
    - lib/mix/tasks/critic.measure.ex
    - lib/mix/tasks/critic.synth.ex
    - lib/mix/tasks/threadline.evidence.show.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - lib/mix/tasks/threadline.policy.show.ex
    - lib/threadline.ex
    - lib/threadline/application.ex
    - lib/threadline/audit.ex
    - lib/threadline/capture/trigger_sql.ex
    - lib/threadline/export_queue/oban.ex
    - lib/threadline/query/filter_params.ex
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - lib/threadline/operator_surface/live/coverage_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - lib/threadline/operator_surface/live/start_live.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/mechanical_checker.ex
    - lib/threadline/operator_surface/presentation.ex
    - lib/threadline/operator_surface/session_plug.ex
    - lib/threadline/policy/redaction_presenter.ex
decisions:
  - "D-09: retention.ex MissedMetadataKeyInLoggerConfig is resolved by the check's metadata_keys: param in .credo.exs (Plan 10), not by Logger config in config/*.exs"
  - "Minimal @type t :: %__MODULE__{} form for the three new public struct types; typedocs use domain language only"
metrics:
  duration: "~8 min"
  completed: 2026-09-23
plan_base: 671112d10f79dcce4e96d5dfb9f747aa20ac0b33
plan_head_before: 671112d10f79dcce4e96d5dfb9f747aa20ac0b33
actuals:
  tokens: 8400
  tasks: 2
  commits: 28
---

# Phase 203 Plan 06: Lib Mechanical Credo Sweep Summary

Every mechanical Credo finding in lib/ is fixed in place: 57 findings over 28 files, one `refactor` commit per file. The fixes are 8 SpecWithStruct (backed by three new public `t()` struct types), 12 MapJoin, 10 RedundantWithClauseResult, 6 PreferImplicitTry and 21 others. The two stale `file.ex:NN` comments that fall under GATE-05 are now symbol references. Dialyzer stays at 0, and the Nesting and CyclomaticComplexity findings are exactly the same set as before.

Plan base SHA: `671112d10f79dcce4e96d5dfb9f747aa20ac0b33` (also in `.git/gsd-203-06-base`).

## lib/ histogram (Credo full defaults, `--strict`)

| Check | Before | After |
|---|---|---|
| SpecWithStruct | 8 | 0 |
| MapJoin | 12 | 0 |
| RedundantWithClauseResult | 10 | 0 |
| PreferImplicitTry | 6 | 0 |
| AliasOrder | 5 | 0 |
| NegatedConditionsWithElse | 5 | 0 |
| CondStatements | 3 | 0 |
| ExpensiveEmptyEnumCheck | 2 | 0 |
| RejectReject | 2 | 0 |
| ParenthesesOnZeroArityDefs | 1 | 0 |
| WithSingleClause | 1 | 0 |
| MissedMetadataKeyInLoggerConfig | 1 | 1 (deferred to Plan 10, D-09) |
| Nesting (lib) | 19 | 19 |
| CyclomaticComplexity (lib) | 15 | 15 |

Across the whole tree, Nesting is 30 and CyclomaticComplexity is 16, both unchanged. A `filename check scope` diff of the structural findings before and after shows no differences.

The whole-tree non-structural findings left for Plan 07 (test/) are AliasOrder 4, MaxLineLength 1, PreferImplicitTry 1, StringSigils 4, FilterFilter 2, MapJoin 6, RedundantWithClauseResult 1, UnlessWithElse 1 and ExpensiveEmptyEnumCheck 4.

## D-09 Logger decision

`lib/threadline/retention.ex`'s `MissedMetadataKeyInLoggerConfig` finding is left alone. It will be resolved in Plan 10 with the check's `metadata_keys:` param in `.credo.exs`. No Logger config goes into any `config/*.exs`. There are two reasons:
1. A library must not prescribe Logger config for its host. Hosts never load a dependency's `config/*.exs`, so the config would be dead there, and the gate would be passing on a promise the library cannot keep.
2. The CI `verify-credo` job runs in MIX_ENV=dev, while `ci.all` runs in test. Env-specific Logger config would pass in one place and fail in the other. The `.credo.exs` param does not depend on the env.

A fail-closed check confirmed this: `git diff --quiet $BASE HEAD -- lib/threadline/retention.ex config/` exits 0.

## Tasks

| Task | Name | Commits |
|---|---|---|
| 1 | Add @type t to three structs and resolve SpecWithStruct and the other findings in those six files | f73f0ae9, 02317082, bba48f2d, 2569f012, a5cb75a6, a8fdcc51 |
| 2 | Resolve the remaining lib mechanical findings and rewrite the two stale location comments | d351c714 … 2414bd6a (22 commits) |

## GATE-05 comment rewrites

- `timeline_live.ex` mount: "For :ok / true returns, the assign is absent. (auth.ex:21-27)" was also wrong on the facts, because Auth assigns `nil` for `:ok` and `true`. It now reads: "the scope assign is nil unless the operator's :authorize_fn returns {:ok, scope} (see `Threadline.OperatorSurface.Auth`)". This was checked against auth.ex lines 30-69.
- `export_controller.ex`: "(lifted from timeline_live.ex:366-373)" now reads "(mirrors `TimelineLive.safe_validate/1`)".
- `grep -rnE "#.*\b[A-Za-z0-9_./-]+\.exs?:[0-9]+" lib` prints nothing.

## Commits (`.git-blame-ignore-revs` candidate set)

- f73f0ae9 refactor(203-06): add @type t to Threadline.Capture.AuditChange
- 02317082 refactor(203-06): add @type t to Threadline.Capture.AuditTransaction
- bba48f2d refactor(203-06): add @type t to Threadline.Semantics.ActorRef
- 2569f012 refactor(203-06): resolve SpecWithStruct, CondStatements findings in lib/threadline/query.ex
- a5cb75a6 refactor(203-06): resolve SpecWithStruct findings in lib/threadline/change_diff.ex
- a8fdcc51 refactor(203-06): resolve SpecWithStruct findings in lib/threadline/integrations/sigra.ex
- d351c714 refactor(203-06): resolve ExpensiveEmptyEnumCheck, RedundantWithClauseResult findings in lib/mix/tasks/critic.measure.ex
- f71339a0 refactor(203-06): resolve RedundantWithClauseResult findings in lib/mix/tasks/critic.synth.ex
- 58a2961b refactor(203-06): resolve MapJoin findings in lib/mix/tasks/threadline.evidence.show.ex
- a08e0daa refactor(203-06): resolve MapJoin findings in lib/mix/tasks/threadline.gen.triggers.ex
- ada260f2 refactor(203-06): resolve MapJoin findings in lib/mix/tasks/threadline.policy.show.ex
- aa6835d6 refactor(203-06): resolve AliasOrder findings in lib/threadline.ex
- 06c8a155 refactor(203-06): resolve RedundantWithClauseResult findings in lib/threadline/application.ex
- 0663f317 refactor(203-06): resolve RedundantWithClauseResult findings in lib/threadline/audit.ex
- 1874ae19 refactor(203-06): resolve ParenthesesOnZeroArityDefs, MapJoin findings in lib/threadline/capture/trigger_sql.ex
- 25b98ba9 refactor(203-06): resolve RedundantWithClauseResult findings in lib/threadline/export_queue/oban.ex
- d8d6b48d refactor(203-06): resolve RedundantWithClauseResult, PreferImplicitTry findings in lib/threadline/query/filter_params.ex
- 9ece59ab refactor(203-06): resolve PreferImplicitTry findings in lib/threadline/operator_surface/controllers/export_controller.ex
- b711fcfa refactor(203-06): resolve AliasOrder findings in lib/threadline/operator_surface/live/coverage_live.ex
- f8664624 refactor(203-06): resolve AliasOrder, NegatedConditionsWithElse, PreferImplicitTry findings in lib/threadline/operator_surface/live/export_status_live.ex
- 16dac822 refactor(203-06): resolve AliasOrder, NegatedConditionsWithElse, ExpensiveEmptyEnumCheck findings in lib/threadline/operator_surface/live/retention_history_live.ex
- 2139baf8 refactor(203-06): resolve AliasOrder findings in lib/threadline/operator_surface/live/start_live.ex
- 0906d8d7 refactor(203-06): resolve CondStatements, MapJoin, PreferImplicitTry findings in lib/threadline/operator_surface/live/timeline_live.ex
- 6cf8c112 refactor(203-06): resolve MapJoin findings in lib/threadline/operator_surface/live/transaction_live.ex
- 86572545 refactor(203-06): resolve RedundantWithClauseResult, RejectReject findings in lib/threadline/operator_surface/mechanical_checker.ex
- bbad1706 refactor(203-06): resolve MapJoin findings in lib/threadline/operator_surface/presentation.ex
- 3be71d5c refactor(203-06): resolve PreferImplicitTry findings in lib/threadline/operator_surface/session_plug.ex
- 2414bd6a refactor(203-06): resolve WithSingleClause findings in lib/threadline/policy/redaction_presenter.ex

## Verification

- `MIX_ENV=dev mix dialyzer --no-check`: `Total errors: 0`. The PLT was warm, so no rebuild was needed. `.dialyzer_ignore.exs` is still `[]`.
- Task 1 tests (query, change_diff, integrations, dialyzer_ignore_contract, public_surface_contract, semantics): 183 + 27 tests, 0 failures. `test/threadline/semantics` exists. It ran in the combined command, and again on its own (27 tests).
- Task 2 tests (operator_surface, capture, query, test/mix, export_queue, policy, audit_transaction_test, audit_doc_contract_test): 895 tests, 0 failures.
- `mix test` (full suite, DB_PORT=5433): 1699 tests, 0 failures, 1 excluded. The clean_checkout timeout flake did not appear.
- `mix compile --force --warnings-as-errors`: clean. `mix verify.format`: exit 0.
- Task 2 jq gate: `true`. Task 1 SpecWithStruct gate: 0 findings.
- `grep -rnE "credo:(disable|enable)" lib`: no output.
- `threadline.gen.triggers` has no unit test for the generated migration body. So `migration_content/1` was compiled from both the pre-change and post-change source under different module names and compared on mixed shared and per-table specs. The output is byte-identical: 6248 bytes and 385 bytes.
- The browser lane (`mix verify.example_browser`) was not run. No edit changes rendered markup. `format_count/1` and `pk_label/1` produce the same strings, and the full suite, including its rendered-output contracts, passed.

## Deviations from Plan

None that change scope. Notes:
- The actor_ref.ex PreferImplicitTry fix and the query.ex CondStatements fix went into those files' Task 1 commits, as Task 1 (b) directs ("fix every other finding ... in these six files"). The actor_ref commit keeps the plan's "add @type t" subject, and its body names PreferImplicitTry.
- NegatedConditionsWithElse swaps (`if not x` → `if x`, 5 sites) remove one unreachable crash path. `not nil` would raise, while `if nil` takes the disabled branch. `Threadline.OperatorSurface.Auth` always assigns a boolean to `:threadline_exports_enabled` and `:threadline_policy_enabled`, so no observable behavior changes.
- No flatter form was needed anywhere. WithSingleClause→case in redaction_presenter.ex did not raise Nesting (the structural set is identical).

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: all 28 modified lib files. FOUND: all 28 commits (`git rev-list --count 671112d1..HEAD` = 28 before this docs commit).
