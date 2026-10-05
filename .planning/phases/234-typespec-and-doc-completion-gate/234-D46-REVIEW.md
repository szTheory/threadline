# Phase 234 D-46 Independent Rubric Review

**Verdict:** FAIL — the frozen completion rubric is not fully satisfied.
**Scope:** Source changes from `7f31cbb7` through `2eaea6df`, plus current working source.
**Input:** Frozen `234-SPEC-RUBRIC.md` and all of `234-REVIEW-INPUT.md` were read before examining current source. The generated input is stale relative to later source commits (for example, the current ActorRef map type was changed after input generation), so current source controls findings.
**Coverage:** 226 generated visible entries, 52 moduledocs, and 8 public behavior callbacks (the generated input omits callbacks). Each generated entry and moduledoc has one row below. The broad-type inventory follows the matrices.

## Prioritized findings

### WR-01 — BLOCKER: Public input specs reject values the validators handle

**Files:** `lib/threadline/semantics/actor_ref.ex:44`, `lib/threadline/evidence/subject.ex:36`

`ActorRef.new/2` returns `{:error, :unknown_actor_type}` for every unsupported input, but its public spec only accepts `actor_type()`; the documented error branch is therefore uncallable for a well-typed caller. `Evidence.Subject.validate/1` similarly normalizes arbitrary values and echoes unsupported values, while the spec restricts the input to `subject_descriptor()`. These violate the validator/predicate allowance R2 and make the public typespecs misrepresent runtime behavior.

**Fix:** Accept `term()` for validator inputs (or the broadest actual runtime input) and keep successful outputs narrowed to the supported types. Preserve the echoed value type on the error branch.

### WR-02 — BLOCKER: Public map types do not encode their finite key sets

**Files:** `lib/threadline/semantics/actor_ref.ex:30-31`, `lib/threadline/evidence/subject.ex:19-27`, `lib/threadline/retention/policy.ex:32-34`

`actor_map/0` accepts any non-empty string-keyed map rather than the guaranteed `"type"` and optional `"id"` keys. `subject_descriptor/0` accepts arbitrary string keys despite documenting only `"subject"` or `"name"`. `config_map/0` accepts arbitrary atom/string keys and merges the value domains for fields whose values have distinct constraints. All are finite-shape public contracts and fail S-4/D-25(a); the JSON-bound actor map also lacks the R-3 guarantees in its typedoc.

**Fix:** Spell the accepted keys explicitly, including atom and string key variants where supported. Give `actor_map/0` a typedoc stating its guaranteed keys and any additive-key promise, or use a named JSON type where the contract is intentionally open.

### WR-03 — WARNING: Adapter callbacks expose untyped options and error reasons

**Files:** `lib/threadline/export_queue.ex:39-47`, `lib/threadline/storage.ex:44-90`

The visible `Threadline.ExportQueue.init/1` and `enqueue/2` behavior callbacks use bare `keyword()`; no named option type and typedoc establishes that these are adapter-defined passthrough options as R-4 requires. Both queue and storage callbacks also expose bare `term()` error payloads without a named typedoc declaring the adapter-owned values opaque to Threadline (R-1).

**Fix:** Define and document an adapter-defined options type and an adapter-owned opaque error-reason type, then use those names in the callback signatures.

### WR-04 — WARNING: Several captured-row APIs omit or weaken the required data note

**File:** `lib/threadline.ex:230-430`, `lib/threadline.ex:630-740`, `lib/threadline.ex:850-930`, `lib/threadline.ex:1040-1145`, `lib/threadline/change_diff.ex:105-160`

The row-returning actor/correlation reads, `as_of/4`, `audit_changes_for_transaction/2`, and transaction-context reads omit the captured-data note. `history/3` and the row-history family say “captured values” rather than the rubric's required “column values”; `change_diff/2` says “captured values as stored” and omits the authorization sentence. This is D-10, including for APIs beyond the enumerated minimum because they return captured values.

**Fix:** Use the prescribed captured-data sentence consistently on each API that returns captured row values, including the `:scope_query_fn` authorization direction.

### WR-05 — WARNING: Side-effect/validator summaries omit return shapes

**Files:** `lib/threadline/audit.ex:93-104`, `lib/threadline.ex:750-805`, `lib/threadline/continuity.ex:30-90`, `lib/threadline/retention.ex:37-72`, `lib/threadline/evidence/subject.ex:28-42`, `lib/threadline/health/policy.ex:37-56`, `lib/threadline/retention/policy.ex:41-54`

The first paragraphs for `Audit.transaction/3`, `record_action/2`, `Retention.purge/1`, `Continuity.assert_capture_ready!/2`, and the validators describe an operation without naming the return value in the summary. The detailed specs/Returns sections do not repair D-2/S-2's first-paragraph requirement. Both `assert_capture_ready!/2` and `explain_cutover/1` fetch required `:repo` with `Keyword.fetch!/2`, so each raises `KeyError` when it is missing; neither function documents that raise (D-6).

**Fix:** State the success return and relevant error envelope in each opening paragraph; document `:ok` for validators and `KeyError` for the missing repo option in both continuity helpers.

### WR-06 — WARNING: The ActorRef moduledoc omits its public entry points

**File:** `lib/threadline/semantics/actor_ref.ex:1-19`

The module has four public functions, but its moduledoc describes the struct and actor categories without naming `new/2`, `from_map/1`, `identifiable?/1`, or `to_map/1`. This fails M-2.

**Fix:** Add one short paragraph explaining when to use the constructor, decoder, identity predicate, and serializer.

### WR-07 — WARNING: Touched moduledocs begin with fragments

**Files:** `lib/mix/tasks/threadline.continuity.ex:1-4`, `lib/threadline.ex:2-4`, `lib/threadline/continuity.ex:1-4`, `lib/threadline/change_diff.ex:1-3`, `lib/threadline/governance/evidence_record.ex:1-3`, `lib/threadline/investigation/incident_bundle.ex:1-3`, `lib/threadline/investigation/linked_change.ex:1-3`, `lib/threadline/integrations/sigra.ex:1-3`, `lib/threadline/not_found_error.ex:1-3`, `lib/threadline/operator_surface.ex:3-5`, `lib/threadline/page.ex:1-3`, `lib/threadline/retention.ex:1-4`, `lib/threadline/telemetry.ex:1-3`

These touched module summaries are noun or participle fragments rather than one-sentence domain summaries, failing M-1. The per-module table marks each affected moduledoc.

**Fix:** Rewrite each opening as a complete declarative sentence that names the module's domain entity or behavior.

### WR-08 — WARNING: Public type documentation contains an avoid-list term and one public type is undocumented

**File:** `lib/threadline/evidence.ex:45-51`

The Evidence typedocs use the rubric's avoid-list term `provenance` in narrative descriptions (D-8). `Threadline.StorageSchema.role/0` is explicitly hidden with `@typedoc false` and only appears in hidden specs, so it is excluded under R-5 and is not a finding.

**Fix:** Replace the narrative field name with “source context” while retaining literal API field references where necessary.

## Broad-type inventory

The R-rule column records the allowance for every visible broad `term()`, `map()`, or `keyword()` occurrence found in the current changed source. R5 entries are hidden implementation specs and are outside the public documentation/type surface.

| Surface | Occurrence | R-rule | Assessment |
|---|---|---|---|
| `Threadline.scope_opt/0` | `term()` in `{:scope, term()}` | R1 | Typedoc states caller-owned and opaque to Threadline. |
| `Threadline.scope_query_fn/0` | `term()` scope argument; `map()` for open `params` context | R1 | Typedoc describes opaque scope and open surface-specific params. |
| `Threadline.Audit.transaction/3` | callback result `result: term()`; `{:error, term()}` | R1 | Callback result and rollback reason are caller-owned/opaque. |
| `Threadline.Evidence.Subject.validate/1` | return payload `term()` | R2 | Validator echoes rejected subject value. Input spec is separately too narrow; see WR-01. |
| `Threadline.Semantics.ActorRef.from_map/1` | argument `term()` | R2 | Arbitrary JSON-decoded input validator. |
| `Threadline.Semantics.ActorRef.identifiable?/1` | argument `term()` | R2 | Predicate accepts arbitrary input. |
| `Threadline.Page.t/0` | entry parameter `term()` | R1 | Generic producer-selected entry type; `t(entry)` is preferred. |
| `Threadline.Storage.options/0` | `keyword()` | R4 | Named type and typedoc explicitly say adapter-defined. |
| `Threadline.Storage` callbacks `init/1`, `put/2`, `get/1`, `path/1`, `download_url/2`, `delete/1` | `term()` error payloads | R1 | Adapter owns the opaque error reason, but the typedoc-backed named type is missing. |
| `Threadline.ExportQueue.init/1`, `enqueue/2` | bare `keyword()` arguments; `term()` error payloads | R4 options; R1 errors | Adapter-defined behavior inputs lack a named type/typedoc; opaque adapter error reason types are also missing. |
| `Threadline.StorageSchema.validate_identifier!/3`, `invalid_identifier!/3` | `term()` argument | R5 | Hidden implementation specs, outside public SPEC-02 surface. |
| `Threadline.Health.coverage_by_schema/1` | `keyword()` | R5 | Hidden internal helper. |
| `Threadline.Investigation` read delegates (`row_history/*`, pagers, window/bundle pagers, transaction and incident lookups) | `term()` ids / `keyword()` options | R5 | Hidden helper module/specs; facade entries use named public types. |
| `Threadline.Query` read/query helpers (`row_history/*`, pagers, preload, timeline, history, as_of, actor-history, transaction reads) | `term()` ids / `keyword()` filters and options | R5 | Hidden query implementation specs. |
| `Threadline.Query.TransactionLookup` `scoped_row/4`, `fetch_row/2`, `fetch/2` | `term()` id/scope / `keyword()` options | R5 | Hidden implementation specs. |

## Entry-by-entry rubric matrix

One row is included for each visible function, macro, public type, and touched moduledoc in the generated input. Public callbacks omitted by the generated input are also represented.

| Module.fun/arity | Tier (F/floor) | Failed item IDs | Note |
|---|---|---|---|
| `Threadline.actor_history/2` | F | — | Pass |
| `Threadline.actor_window/3` | F | D-10 | Returns captured linked changes without the required captured-data note. |
| `Threadline.actor_window_page/3` | F | D-10 | Returns captured linked changes without the required captured-data note. |
| `Threadline.as_of/4` | F | D-10 | Returns the captured row snapshot without the required captured-data note. |
| `Threadline.audit_changes_for_transaction/2` | F | D-10 | The note omits the required phrase “column values”. |
| `Threadline.audit_transaction/2` | F | — | Pass |
| `Threadline.audit_transaction!/2` | F | — | Pass |
| `Threadline.change_diff/2` | F | D-10 | Its note omits the required authorization sentence and the prescribed captured-column wording. |
| `Threadline.correlation_bundle/3` | F | D-10 | Returns captured linked changes without the required captured-data note. |
| `Threadline.correlation_bundle_page/3` | F | D-10 | Returns captured linked changes without the required captured-data note. |
| `Threadline.export_csv/2` | F | — | Pass |
| `Threadline.export_json/2` | F | — | Pass |
| `Threadline.history/3` | F | D-10 | The note omits the required phrase “column values”. |
| `Threadline.incident_bundle/2` | F | — | Pass |
| `Threadline.incident_bundle!/2` | F | — | Pass |
| `Threadline.record_action/2` | F | D-2, S-2 | First paragraph says it records an AuditAction but not the documented {:ok, action} result. |
| `Threadline.row_history/3` | F | D-10 | The note omits the required phrase “column values”. |
| `Threadline.row_history/4` | F | D-10 | The note omits the required phrase “column values”. |
| `Threadline.row_history_page/4` | F | D-10 | The note omits the required phrase “column values”. |
| `Threadline.timeline/2` | F | — | Pass |
| `Threadline.timeline_page/2` | F | — | Pass |
| `Threadline.transaction_context/2` | F | D-10 | Returns linked captured changes without the required captured-data note. |
| `Threadline.transaction_context!/2` | F | D-10 | Returns linked captured changes without the required captured-data note. |
| `Threadline.correlation_bundle_page_opt/0` | floor | — | Pass |
| `Threadline.correlation_bundle_page_filter/0` | floor | — | Pass |
| `Threadline.actor_window_page_opt/0` | floor | — | Pass |
| `Threadline.actor_window_page_filter/0` | floor | — | Pass |
| `Threadline.row_history_page_opt/0` | floor | — | Pass |
| `Threadline.row_history_legacy_opt/0` | floor | — | Pass |
| `Threadline.row_history_filter/0` | floor | — | Pass |
| `Threadline.history_opt/0` | floor | — | Pass |
| `Threadline.change_diff_opt/0` | floor | — | Pass |
| `Threadline.audit_changes_opt/0` | floor | — | Pass |
| `Threadline.as_of_opt/0` | floor | — | Pass |
| `Threadline.record_action_opt/0` | floor | — | Pass |
| `Threadline.export_json_opt/0` | floor | — | Pass |
| `Threadline.export_csv_opt/0` | floor | — | Pass |
| `Threadline.window_opt/0` | floor | — | Pass |
| `Threadline.correlation_bundle_filter/0` | floor | — | Pass |
| `Threadline.actor_window_filter/0` | floor | — | Pass |
| `Threadline.actor_history_opt/0` | floor | — | Pass |
| `Threadline.timeline_page_opt/0` | floor | — | Pass |
| `Threadline.timeline_opt/0` | floor | — | Pass |
| `Threadline.timeline_filter/0` | floor | — | Pass |
| `Threadline.lookup_opt/0` | floor | — | Pass |
| `Threadline.row_history_opt/0` | floor | — | Pass |
| `Threadline.json_map/0` | floor | — | Pass |
| `Threadline.json_value/0` | floor | — | Pass |
| `Threadline.row_id/0` | floor | — | Pass |
| `Threadline.row_key_scalar/0` | floor | — | Pass |
| `Threadline.scope_opt/0` | floor | — | Pass |
| `Threadline.scope_query_fn/0` | floor | — | Pass |
| `Threadline.storage_schema_opt/0` | floor | — | Pass |
| `Threadline.repo_opt/0` | floor | — | Pass |
| `Threadline.Audit.transaction/3` | F | D-2 | First paragraph omits the {:ok, result}/{:error, reason} return envelope. |
| `Threadline.Audit.transaction_opt/0` | floor | — | Pass |
| `Threadline.Audit.action_opt/0` | floor | — | Pass |
| `Threadline.Capture.AuditChange.t/0` | floor | — | Pass |
| `Threadline.Capture.AuditTransaction.t/0` | floor | — | Pass |
| `Threadline.ChangeDiff.from_audit_change/2` | F | — | Pass |
| `Threadline.ChangeDiff.change_diff_result/0` | floor | — | Pass |
| `Threadline.Continuity.assert_capture_ready!/2` | F | D-2, D-6 | Summary omits :ok; missing required :repo raises KeyError, which the doc does not name. |
| `Threadline.Continuity.explain_cutover/1` | F | D-6 | Required `:repo` is fetched with `Keyword.fetch!/2`; the doc does not name the resulting `KeyError`. |
| `Threadline.Continuity.assert_capture_ready_opt/0` | floor | — | Pass |
| `Threadline.Continuity.explain_cutover_opt/0` | floor | — | Pass |
| `Threadline.Evidence.get_latest_subject_ref/3` | F | — | Pass |
| `Threadline.Evidence.list_history/2` | F | — | Pass |
| `Threadline.Evidence.list_latest_subject_refs/3` | F | — | Pass |
| `Threadline.Evidence.list_overview/2` | F | — | Pass |
| `Threadline.Evidence.list_subject_ref_history/4` | F | — | Pass |
| `Threadline.Evidence.record_export_delivery/3` | F | — | Pass |
| `Threadline.Evidence.record_redaction_policy/3` | F | — | Pass |
| `Threadline.Evidence.record_retention_policy/3` | F | — | Pass |
| `Threadline.Evidence.record_retention_run/3` | F | — | Pass |
| `Threadline.Evidence.record_support_scope_posture/3` | F | — | Pass |
| `Threadline.Evidence.record_trigger_coverage/3` | F | — | Pass |
| `Threadline.Evidence.invalid_subject_ref/0` | floor | — | Pass |
| `Threadline.Evidence.record_result/0` | floor | — | Pass |
| `Threadline.Evidence.get_latest_subject_ref_opt/0` | floor | — | Pass |
| `Threadline.Evidence.list_overview_opt/0` | floor | — | Pass |
| `Threadline.Evidence.list_latest_subject_refs_opt/0` | floor | — | Pass |
| `Threadline.Evidence.list_subject_ref_history_opt/0` | floor | — | Pass |
| `Threadline.Evidence.list_history_opt/0` | floor | — | Pass |
| `Threadline.Evidence.latest_filter/0` | floor | — | Pass |
| `Threadline.Evidence.subject_ref_history_filter/0` | floor | — | Pass |
| `Threadline.Evidence.history_filter/0` | floor | — | Pass |
| `Threadline.Evidence.support_scope_posture_attrs/0` | floor | — | Pass |
| `Threadline.Evidence.export_delivery_attrs/0` | floor | — | Pass |
| `Threadline.Evidence.retention_policy_attrs/0` | floor | — | Pass |
| `Threadline.Evidence.retention_run_attrs/0` | floor | — | Pass |
| `Threadline.Evidence.trigger_coverage_attrs/0` | floor | — | Pass |
| `Threadline.Evidence.redaction_policy_attrs_input/0` | floor | — | Pass |
| `Threadline.Evidence.redaction_policy_attr_key/0` | floor | — | Pass |
| `Threadline.Evidence.record_attrs/0` | floor | D-8 | Typedoc uses the avoid-list term “provenance” for the field; use a plain-language description or refer to the literal field outside narrative prose. |
| `Threadline.Evidence.redaction_policy_attrs/0` | floor | D-8 | Typedoc uses the avoid-list term “provenance” for the field; use a plain-language description or refer to the literal field outside narrative prose. |
| `Threadline.Evidence.redaction_policy_attr_value/0` | floor | — | Pass |
| `Threadline.Evidence.record_opt/0` | floor | — | Pass |
| `Threadline.Evidence.subject_ref/0` | floor | — | Pass |
| `Threadline.Evidence.subject_ref_value/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.proof_document/2` | F | — | Pass |
| `Threadline.Evidence.Proof.render_human/1` | F | — | Pass |
| `Threadline.Evidence.Proof.render_json/1` | F | — | Pass |
| `Threadline.Evidence.Proof.to_json_iodata/2` | F | — | Pass |
| `Threadline.Evidence.Proof.presented_record/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.evidence_record_input/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.proof_document/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.claim_kind/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.claim_status/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.proof_opt/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.proof_filter/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.proof_mode/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.proof_request/0` | floor | — | Pass |
| `Threadline.Evidence.Proof.proof_request_opt/0` | floor | — | Pass |
| `Threadline.Evidence.Subject.supported?/1` | F | S-4 | The predicate handles arbitrary values and returns false for them, but its input spec is limited to `subject_descriptor()` (R2). |
| `Threadline.Evidence.Subject.supported_subjects/0` | F | — | Pass |
| `Threadline.Evidence.Subject.validate/1` | F | D-2, S-2, S-4 | Docs omit the :ok/error shape; the spec excludes arbitrary invalid input accepted by this validator (R2). |
| `Threadline.Evidence.Subject.subject_descriptor/0` | floor | S-4 | The string-keyed map arm accepts every string key although only "subject" and "name" are supported. |
| `Threadline.Export.count_matching/2` | F | — | Pass |
| `Threadline.Export.csv_header/1` | F | — | Pass |
| `Threadline.Export.format_changes_iodata/3` | F | — | Pass |
| `Threadline.Export.stream_changes/2` | F | — | Pass |
| `Threadline.Export.stream_export_rows/2` | F | — | Pass |
| `Threadline.Export.to_csv_iodata/2` | F | — | Pass |
| `Threadline.Export.to_json_document/2` | F | — | Pass |
| `Threadline.Export.stream_changes_opt/0` | floor | — | Pass |
| `Threadline.Export.stream_export_rows_opt/0` | floor | — | Pass |
| `Threadline.Export.format_changes_opt/0` | floor | — | Pass |
| `Threadline.Export.csv_header_opt/0` | floor | — | Pass |
| `Threadline.Export.count_matching_opt/0` | floor | — | Pass |
| `Threadline.Export.export_row/0` | floor | — | Pass |
| `Threadline.Export.count_result/0` | floor | — | Pass |
| `Threadline.Export.export_result/0` | floor | — | Pass |
| `Threadline.Export.Orchestrator.run/2` | F | — | Pass |
| `Threadline.Export.Orchestrator.run_result/0` | floor | — | Pass |
| `Threadline.Export.Orchestrator.error_reason/0` | floor | — | Pass |
| `Threadline.Export.Orchestrator.run_opt/0` | floor | — | Pass |
| `Threadline.ExportQueue.job_id/0` | floor | — | Pass |
| `Threadline.ExportQueue.TaskAdapter.enqueue/2` | F | — | Pass |
| `Threadline.ExportQueue.TaskAdapter.enqueue_result/0` | floor | — | Pass |
| `Threadline.ExportQueue.TaskAdapter.enqueue_opt/0` | floor | — | Pass |
| `Threadline.Governance.EvidenceRecord.t/0` | floor | — | Pass |
| `Threadline.Health.legacy_key_findings/1` | F | — | Pass |
| `Threadline.Health.trigger_coverage/1` | F | — | Pass |
| `Threadline.Health.trigger_findings/1` | F | — | Pass |
| `Threadline.Health.trigger_coverage_opt/0` | floor | — | Pass |
| `Threadline.Health.legacy_key_findings_opt/0` | floor | — | Pass |
| `Threadline.Health.trigger_findings_opt/0` | floor | — | Pass |
| `Threadline.Health.schema_filter/0` | floor | — | Pass |
| `Threadline.Health.coverage_entry/0` | floor | — | Pass |
| `Threadline.Health.coverage_status/0` | floor | — | Pass |
| `Threadline.Health.Finding.t/0` | floor | — | Pass |
| `Threadline.Health.Finding.details/0` | floor | — | Pass |
| `Threadline.Health.Finding.code/0` | floor | — | Pass |
| `Threadline.Health.Finding.severity/0` | floor | — | Pass |
| `Threadline.Health.Policy.validate!/1` | F | D-2, S-2 | Docs omit the :ok success result stated by its spec. |
| `Threadline.Health.Policy.config/0` | floor | — | Pass |
| `Threadline.Health.Policy.config_opt/0` | floor | — | Pass |
| `Threadline.Integrations.Sigra.actor_fn/0` | F | — | Pass |
| `Threadline.Integrations.Sigra.actor_ref_from_conn/1` | F | — | Pass |
| `Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1` | F | — | Pass |
| `Threadline.Integrations.Sigra.audit_overrides/0` | floor | — | Pass |
| `Threadline.Investigation.IncidentBundle.t/0` | floor | — | Pass |
| `Threadline.Investigation.IncidentChange.t/0` | floor | — | Pass |
| `Threadline.Investigation.LinkedChange.t/0` | floor | — | Pass |
| `Threadline.Investigation.LinkedTransaction.t/0` | floor | — | Pass |
| `Threadline.Job.actor_ref_from_args/1` | F | — | Pass |
| `Threadline.Job.context_opts/2` | F | — | Pass |
| `Threadline.Job.context_opts_result/0` | floor | — | Pass |
| `Threadline.Job.context_opt/0` | floor | — | Pass |
| `Threadline.Job.actor_ref_result/0` | floor | — | Pass |
| `Threadline.Job.actor_ref_error/0` | floor | — | Pass |
| `Threadline.Job.job_args/0` | floor | — | Pass |
| `Threadline.NotFoundError.t/0` | floor | — | Pass |
| `Threadline.OperatorSurface.Auth.on_mount/4` | F | — | Pass |
| `Threadline.OperatorSurface.Auth.on_mount_session/0` | floor | — | Pass |
| `Threadline.OperatorSurface.Auth.on_mount_session_value/0` | floor | — | Pass |
| `Threadline.OperatorSurface.Auth.on_mount_params/0` | floor | — | Pass |
| `Threadline.OperatorSurface.Auth.on_mount_opt/0` | floor | — | Pass |
| `Threadline.OperatorSurface.Router.threadline_operator_surface/2` | F | — | Pass |
| `Threadline.Page.t/0` | floor | — | Pass |
| `Threadline.Page.t/1` | floor | — | Pass |
| `Threadline.Page.cursor/0` | floor | — | Pass |
| `Threadline.Page.actor_cursor/0` | floor | — | Pass |
| `Threadline.Page.change_cursor/0` | floor | — | Pass |
| `Threadline.Retention.purge/1` | F | D-2 | First paragraph describes deletion but omits the purge_result/error return shape. |
| `Threadline.Retention.purge_opt/0` | floor | — | Pass |
| `Threadline.Retention.purge_result/0` | floor | — | Pass |
| `Threadline.Retention.Policy.cutoff_utc_datetime_usec!/1` | F | — | Pass |
| `Threadline.Retention.Policy.resolve!/1` | F | — | Pass |
| `Threadline.Retention.Policy.validate_config!/1` | F | D-2, S-2 | Docs omit the :ok success result stated by its spec. |
| `Threadline.Retention.Policy.cutoff_opt/0` | floor | — | Pass |
| `Threadline.Retention.Policy.config/0` | floor | — | Pass |
| `Threadline.Retention.Policy.config_map/0` | floor | S-4 | The config has a fixed four-key inventory, but this type accepts arbitrary atom/string keys and conflates per-key value types. |
| `Threadline.Retention.Policy.config_opt/0` | floor | — | Pass |
| `Threadline.Retention.Policy.t/0` | floor | — | Pass |
| `Threadline.Semantics.ActorRef.from_map/1` | F | — | Pass |
| `Threadline.Semantics.ActorRef.identifiable?/1` | F | — | Pass |
| `Threadline.Semantics.ActorRef.new/2` | F | S-2, S-4 | Implementation returns :unknown_actor_type for unsupported values, but the spec restricts input to actor_type() and makes that error unreachable (R2). |
| `Threadline.Semantics.ActorRef.to_map/1` | F | — | Pass |
| `Threadline.Semantics.ActorRef.actor_map/0` | floor | S-4 | String.t() keys permit arbitrary keys and do not encode required "type" / optional "id" keys; the typedoc also fails to state this shape. |
| `Threadline.Semantics.ActorRef.t/0` | floor | — | Pass |
| `Threadline.Semantics.ActorRef.actor_type/0` | floor | — | Pass |
| `Threadline.Semantics.AuditAction.t/0` | floor | — | Pass |
| `Threadline.Semantics.AuditContext.t/0` | floor | — | Pass |
| `Threadline.Storage.options/0` | floor | — | Pass |
| `Threadline.Storage.content/0` | floor | — | Pass |
| `Threadline.Storage.file_id/0` | floor | — | Pass |
| `Threadline.StorageSchema.get/1` | F | — | Pass |
| `Threadline.StorageSchema.repo_opts/1` | F | — | Pass |
| `Threadline.StorageSchema.table/2` | F | — | Pass |
| `Threadline.StorageSchema.threadline_table?/1` | F | — | Pass |
| `Threadline.StorageSchema.validate!/1` | F | — | Pass |
| `Threadline.StorageSchema.role/0` | floor | — | `@typedoc false`; it is internal and used only by hidden specs (R5). |
| `Threadline.StorageSchema.repo_opts_result/0` | floor | — | Pass |
| `Threadline.StorageSchema.parsed_table_identifier/0` | floor | — | Pass |
| `Threadline.StorageSchema.identifier_input/0` | floor | — | Pass |
| `Threadline.Telemetry.transaction_committed/2` | F | — | Pass |
| `Threadline.Telemetry.transaction_value/0` | floor | — | Pass |
| `Threadline.Telemetry.transaction_committed_opt/0` | floor | — | Pass |
| `Threadline.Verify.CoveragePolicy.partition_findings/2` | F | — | Pass |
| `Threadline.Verify.CoveragePolicy.summary_counts/2` | F | — | Pass |
| `Threadline.Verify.CoveragePolicy.violations/2` | F | — | Pass |
| `Threadline.Verify.CoveragePolicy.partitioned_findings/0` | floor | — | Pass |
| `Threadline.Verify.CoveragePolicy.summary_result/0` | floor | — | Pass |
| `Threadline.Verify.CoveragePolicy.violation/0` | floor | — | Pass |
| `Threadline.Verify.CoveragePolicy.coverage_entry/0` | floor | — | Pass |
| `Threadline.Storage.init/1` | F | S-4 | See WR-03; callback option/error contracts need named adapter-defined types. |
| `Threadline.Storage.put/2` | F | S-4 | See WR-03; callback option/error contracts need named adapter-defined types. |
| `Threadline.Storage.get/1` | F | S-4 | See WR-03; adapter-owned error reason is bare term(). |
| `Threadline.Storage.path/1` | F | S-4 | See WR-03; adapter-owned error reason is bare term(). |
| `Threadline.Storage.download_url/2` | F | S-4 | See WR-03; callback option/error contracts need named adapter-defined types. |
| `Threadline.Storage.delete/1` | F | S-4 | See WR-03; adapter-owned error reason is bare term(). |
| `Threadline.ExportQueue.init/1` | F | S-4 | See WR-03; bare keyword() and term() callback boundaries lack named R-4/R-1 types. |
| `Threadline.ExportQueue.enqueue/2` | F | S-4 | See WR-03; bare keyword() and term() callback boundaries lack named R-4/R-1 types. |
| `Mix.Tasks.Threadline.Continuity.moduledoc` | F | M-1 | The opening is a noun-phrase fragment, not a complete sentence. |
| `Mix.Tasks.Threadline.Evidence.Show.moduledoc` | F | — | Pass |
| `Mix.Tasks.Threadline.Export.moduledoc` | F | — | Pass |
| `Mix.Tasks.Threadline.Gen.RowHistoryIndex.moduledoc` | F | — | Pass |
| `Mix.Tasks.Threadline.Gen.Triggers.moduledoc` | F | — | Pass |
| `Mix.Tasks.Threadline.Health.Coverage.moduledoc` | F | — | Pass |
| `Mix.Tasks.Threadline.Incident.moduledoc` | F | — | Pass |
| `Mix.Tasks.Threadline.Install.moduledoc` | F | — | Pass |
| `Mix.Tasks.Threadline.Policy.Show.moduledoc` | F | — | Pass |
| `Mix.Tasks.Threadline.Retention.Purge.moduledoc` | F | — | Pass |
| `Mix.Tasks.Threadline.VerifyCoverage.moduledoc` | F | — | Pass |
| `Threadline.moduledoc` | F | M-1 | “Audit platform for…” is a noun-phrase fragment, not a complete sentence. |
| `Threadline.Audit.moduledoc` | F | — | Pass |
| `Threadline.Capture.AuditChange.moduledoc` | F | — | Pass |
| `Threadline.Capture.AuditTransaction.moduledoc` | F | — | Pass |
| `Threadline.ChangeDiff.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Continuity.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Evidence.moduledoc` | F | — | Pass |
| `Threadline.Evidence.Proof.moduledoc` | F | — | Pass |
| `Threadline.Evidence.Subject.moduledoc` | F | — | Pass |
| `Threadline.Export.moduledoc` | F | — | Pass |
| `Threadline.Export.Orchestrator.moduledoc` | F | — | Pass |
| `Threadline.ExportQueue.moduledoc` | F | — | Pass |
| `Threadline.ExportQueue.Oban.moduledoc` | F | — | Pass |
| `Threadline.ExportQueue.TaskAdapter.moduledoc` | F | — | Pass |
| `Threadline.Governance.EvidenceRecord.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Health.moduledoc` | F | — | Pass |
| `Threadline.Health.Finding.moduledoc` | F | — | Pass |
| `Threadline.Health.Policy.moduledoc` | F | — | Pass |
| `Threadline.Integrations.Sigra.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Investigation.IncidentBundle.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Investigation.IncidentChange.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Investigation.LinkedChange.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Investigation.LinkedTransaction.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Job.moduledoc` | F | — | Pass |
| `Threadline.NotFoundError.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.OperatorSurface.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.OperatorSurface.Auth.moduledoc` | F | — | Pass |
| `Threadline.OperatorSurface.Router.moduledoc` | F | — | Pass |
| `Threadline.Page.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Plug.moduledoc` | F | — | Pass |
| `Threadline.Retention.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Retention.Policy.moduledoc` | F | — | Pass |
| `Threadline.Semantics.ActorRef.moduledoc` | F | M-2 | The module has four public functions but the moduledoc never names new/2, from_map/1, identifiable?/1, or to_map/1. |
| `Threadline.Semantics.AuditAction.moduledoc` | F | — | Pass |
| `Threadline.Semantics.AuditContext.moduledoc` | F | — | Pass |
| `Threadline.Storage.moduledoc` | F | — | Pass |
| `Threadline.Storage.Local.moduledoc` | F | — | Pass |
| `Threadline.Storage.S3.moduledoc` | F | — | Pass |
| `Threadline.StorageSchema.moduledoc` | F | — | Pass |
| `Threadline.Telemetry.moduledoc` | F | M-1 | The opening is a noun/participle fragment, not a complete one-sentence domain summary. |
| `Threadline.Verify.CoveragePolicy.moduledoc` | F | — | Pass |

## Hidden functions

Newly hidden in the phase diff: `Threadline.Evidence.Proof.present_record/1`, `Threadline.Evidence.Proof.record_claim_assessment/1`, `Threadline.StorageSchema.function/2`, `host_table_suffix/1`, `parse_table_identifier/1`, `qualified_host_table/1`, `qualify/2`, and `quote_ident/1`.

The generated input lists these eight as internal or newly hidden. Their move out of visible docs is consistent with the rubric's surface reduction; no independent defect was found in the hide decisions.

## Review limits

This is an independent rubric verdict, not a behavioral audit of PostgreSQL capture, query execution, or operator authorization internals. The source diff was used to verify whether the docs/typespecs match actual signatures, return branches, and visibility.
