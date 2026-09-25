# Phase 199 Dialyzer First-Run Triage

## Seal

- Status: **HALTED — warning-origin cap exceeded; re-plan/re-slice Phase 199 before any warning-origin source edit.**
- Raw command: `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.19.5-otp-27 MIX_ENV=dev mix dialyzer --format ignore_file_strict --ignore-exit-status`
- Raw formatter companion: `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.19.5-otp-27 MIX_ENV=dev mix dialyzer --no-check --format raw --ignore-exit-status`
- Toolchain: Elixir 1.19.5, Erlang/OTP 27.3.4.15, Mix 1.19.5, Dialyxir 1.4.8, `MIX_ENV=dev`.
- PLT scope: project/dependency application tree plus explicit `mix`, `ex_unit`, `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub`, `oban`, `ex_aws`, `ex_aws_s3`, `hackney`, and `sweet_xml` applications.
- Warning flags: Dialyxir default `unknown`, plus `unmatched_returns` and `extra_return`.
- Raw output SHA-256: `12c1164ae38a943a738b339d2758e866c51b284444480585e80d5d591169c3e6`
- Raw formatter output SHA-256: `ccc5d50efd8978fd8ea4b23303582e4d61e77253750afd44c0e8dccab8ec6498`
- Config SHA-256 at analysis: `67facf46612807ffdf1e8a359ddf292d19d22bc79a1d15b7a1bf14598307b68e`
- Lock SHA-256 at analysis: `ef6dc7822126bc4a34e983019dff0a4e5fb39e95bcc4f1a1d9e08fe8b2819041`
- Initial warning count: `40`
- Strict formatter entries: `29` (11 duplicate file/description renderings were collapsed by that formatter; the raw-format ledger below retains all 40 occurrences).
- Sealed distinct warning-origin source count: `22`
- Allowed maximum: `14`
- Warning-origin source edits after seal: `0`

The first analysis crossed the plan's hard stop by eight distinct source files. No warning is approved for suppression, no ignore ceiling is established, and no warning-origin source file may be edited under Plan 199-13. The successor plan must re-slice the 22-file set before implementation.

## Sealed Warning-Origin Source Set

<!-- warning-origins:start -->
- `lib/mix/tasks/critic.measure.ex`
- `lib/mix/tasks/critic.synth.ex`
- `lib/threadline/change_diff.ex`
- `lib/threadline/continuity.ex`
- `lib/threadline/critic_trust/measure.ex`
- `lib/threadline/export.ex`
- `lib/threadline/export/orchestrator.ex`
- `lib/threadline/integrations/sigra.ex`
- `lib/threadline/investigation/incident_bundle.ex`
- `lib/threadline/investigation/linked_change.ex`
- `lib/threadline/operator_surface/auth.ex`
- `lib/threadline/operator_surface/live/coverage_live.ex`
- `lib/threadline/operator_surface/live/export_status_live.ex`
- `lib/threadline/operator_surface/live/retention_history_live.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `lib/threadline/operator_surface/live/transaction_live.ex`
- `lib/threadline/operator_surface/presentation.ex`
- `lib/threadline/plug.ex`
- `lib/threadline/policy/redaction_presenter.ex`
- `lib/threadline/query.ex`
- `lib/threadline/query/actor_history_page.ex`
- `lib/threadline/storage/local.ex`
<!-- warning-origins:end -->

## Complete Raw Warning Ledger

Every raw warning occurrence is listed exactly once. `re-plan` is a stop disposition, not an ignore approval.

| ID | Exact origin | Warning class | Disposition |
|---|---|---|---|
| W01 | `lib/mix/tasks/critic.measure.ex:372` | `warn_return_no_exit` | re-plan |
| W02 | `lib/mix/tasks/critic.synth.ex:204` | `warn_return_no_exit` | re-plan |
| W03 | `lib/threadline/change_diff.ex:84` | `warn_unknown` | re-plan |
| W04 | `lib/threadline/continuity.ex:70` | `warn_umatched_return` | re-plan |
| W05 | `lib/threadline/critic_trust/measure.ex:94` | `warn_umatched_return` | re-plan |
| W06 | `lib/threadline/export.ex:220` | `warn_contract_extra_return` | re-plan |
| W07 | `lib/threadline/export.ex:256` | `warn_contract_extra_return` | re-plan |
| W08 | `lib/threadline/export/orchestrator.ex:57` | `warn_umatched_return` | re-plan |
| W09 | `lib/threadline/export/orchestrator.ex:70` | `warn_umatched_return` | re-plan |
| W10 | `lib/threadline/export/orchestrator.ex:47` | `warn_umatched_return` | re-plan |
| W11 | `lib/threadline/integrations/sigra.ex:18` | `warn_unknown` | re-plan |
| W12 | `lib/threadline/integrations/sigra.ex:58` | `warn_unknown` | re-plan |
| W13 | `lib/threadline/integrations/sigra.ex:193` | `warn_matching` | re-plan |
| W14 | `lib/threadline/investigation/incident_bundle.ex:30` | `warn_unknown` | re-plan |
| W15 | `lib/threadline/investigation/incident_bundle.ex:31` | `warn_unknown` | re-plan |
| W16 | `lib/threadline/investigation/linked_change.ex:13` | `warn_unknown` | re-plan |
| W17 | `lib/threadline/investigation/linked_change.ex:14` | `warn_unknown` | re-plan |
| W18 | `lib/threadline/investigation/linked_change.ex:15` | `warn_unknown` | re-plan |
| W19 | `lib/threadline/investigation/linked_change.ex:31` | `warn_unknown` | re-plan |
| W20 | `lib/threadline/investigation/linked_change.ex:32` | `warn_unknown` | re-plan |
| W21 | `lib/threadline/operator_surface/auth.ex:139` | `warn_matching` | re-plan |
| W22 | `lib/threadline/operator_surface/live/coverage_live.ex:103` | `warn_umatched_return` | re-plan |
| W23 | `lib/threadline/operator_surface/live/export_status_live.ex:27` | `warn_umatched_return` | re-plan |
| W24 | `lib/threadline/operator_surface/live/retention_history_live.ex:35` | `warn_umatched_return` | re-plan |
| W25 | `lib/threadline/operator_surface/live/timeline_live.ex:1297` | `warn_matching` | re-plan |
| W26 | `lib/threadline/operator_surface/live/transaction_live.ex:379` | `warn_matching` | re-plan |
| W27 | `lib/threadline/operator_surface/presentation.ex:136` | `warn_matching` | re-plan |
| W28 | `lib/threadline/operator_surface/presentation.ex:147` | `warn_matching` | re-plan |
| W29 | `lib/threadline/operator_surface/presentation.ex:166` | `warn_matching` | re-plan |
| W30 | `lib/threadline/plug.ex:108` | `warn_matching` | re-plan |
| W31 | `lib/threadline/plug.ex:114` | `warn_matching` | re-plan |
| W32 | `lib/threadline/policy/redaction_presenter.ex:489` | `warn_matching` | re-plan |
| W33 | `lib/threadline/query.ex:53` | `warn_unknown` | re-plan |
| W34 | `lib/threadline/query.ex:64` | `warn_unknown` | re-plan |
| W35 | `lib/threadline/query.ex:105` | `warn_unknown` | re-plan |
| W36 | `lib/threadline/query.ex:105` | `warn_unknown` | re-plan |
| W37 | `lib/threadline/query.ex:116` | `warn_unknown` | re-plan |
| W38 | `lib/threadline/query.ex:651` | `warn_unknown` | re-plan |
| W39 | `lib/threadline/query/actor_history_page.ex:13` | `warn_unknown` | re-plan |
| W40 | `lib/threadline/storage/local.ex:68` | `warn_matching` | re-plan |

## Gate Result

The positive-control contract accepts 14 distinct exact paths and rejects a 15th. The live set contains 22. Therefore Plan 199-13 cannot proceed to warning fixes, strict suppressions, an ignore ceiling, Task 2, or a green analyzer result. Re-plan/re-slice Phase 199 using this sealed source set; preserve this artifact as the immutable first-run receipt.
