# D-46 Documentation and Typespec Review — 2026-10-06

**Verdict:** FAIL

Input reviewed: `.planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW-INPUT.md`  
SHA-256: `20a108be78b8d0c05256674f10e8dab14e7633a869ed0e972d91d7b0f3230ff2`

## Review coverage

I independently read the regenerated review dump and frozen rubric, then cross-checked the relevant current declarations, documentation, and executable contracts in `lib/` and `test/`. The dump has 82 complete visible function/macro headings, 52 complete moduledoc headings, and 149 public type headings. I counted each heading from the regenerated file, including the `Threadline.StorageSchema.role/0` type heading that has no rendered typedoc. The public callback inventory was recomputed from every `lib/**/*.ex` file and each declaration, shared type, and callback doc was inspected.

| Surface | Inventory | How checked |
|---|---:|---|
| Visible entries | 82 | Counted all complete generated function/macro headings; reviewed the generated entry summaries, full templates, options/filters, returns, examples, and specs against D-1–D-12 and S-1–S-5, cross-checking current source for the WR-specific contracts. |
| Moduledocs | 52 | Counted every generated moduledoc heading; checked the current ActorRef, IncidentChange, LinkedChange, LinkedTransaction, and other D-46 moduledoc source for M-1–M-3 and the entry-point/domain-summary rules. |
| Public types | 149 | Counted every complete generated type heading; checked declarations and typedocs against S-4/R1–R5 and S-5, including every D-56 alias and atom-key alternative. One public type heading violates S-4(e); see WR-02. |
| Public callbacks | 8 | Independently enumerated all `@callback` declarations: six in `lib/threadline/storage.ex`, two in `lib/threadline/export_queue.ex`. Read every callback signature and its source documentation. |
| Broad-type occurrences | 8 permanent allowances | Compared every generated ledger item with its current source declaration and typedoc: `scope_opt/0`, `scope_query_fn/0`, `Audit.transaction/3`, `Subject.validate/1`, `Page.t/0`, `ActorRef.from_map/1`, `ActorRef.identifiable?/1`, and `Storage.options/0`. Checked each against its R1, R2, or R4 basis and searched current `lib/` annotations for broad forms outside the ledger; remaining occurrences are private/hidden implementation contracts or documented JSON/adapter-owned forms under the rubric. |

## Focused source checks

- **D-56 aliases:** `ActorRef.actor_map/0`, `Subject.subject_descriptor/0`, and `Retention.Policy.config_map/0` all retain the narrowly allowed string-key map arm. Their typedocs name recognized keys and values, unknown-key handling, and mixed-key precedence/behavior. Current source matches those descriptions. The executable contracts in `test/threadline/semantics/actor_ref_test.exs`, `test/threadline/evidence/subject_test.exs`, and `test/threadline/retention/policy_test.exs` cover extra keys, mixed maps, precedence, and the relevant unknown/unrecognized cases. Subject's nested descriptor type and retention's `nil`/`false` atom window fallbacks now agree with their runtime contracts.
- **`Audit.transaction/3`:** The opening paragraph in `lib/threadline/audit.ex` states the `{:ok, result} | {:error, reason}` envelope and conditional audit-ID behavior. `attach_audit_transaction_id/3` leaves the result unchanged when no transaction ID exists; `envelope/2` merges the ID into maps and wraps non-map values. The type-variable spec preserves the caller-owned callback result and agrees with the opening contract.
- **Callbacks:** `Storage` documents success/error behavior for init, put, get, optional path, download URL, and delete. `ExportQueue` documents init and enqueue. `Storage.options/0` is explicitly adapter-defined as R4 requires.
- **Captured-data note:** the required exact note is present on captured-data-returning facade docs in `lib/threadline.ex`; current ChangeDiff and Export docs were also checked in `lib/threadline/change_diff.ex` and `lib/threadline/export.ex`.
- **Moduledocs:** ActorRef names all four adopter entry points and their uses. The D-46 struct moduledocs begin with domain summaries; in particular IncidentChange, LinkedChange, and LinkedTransaction each state what domain result they represent.

## WR dispositions

| WR | Status | Rubric | Evidence | Source paths |
|---|---|---|---|---|
| WR-01 | PASS | R2 | `ActorRef.from_map/1`, `ActorRef.identifiable?/1`, and `Subject.validate/1` accept arbitrary validator/predicate input; their public specs and docs describe validation/predicate behavior and the unsupported-value error. | `lib/threadline/semantics/actor_ref.ex`, `lib/threadline/evidence/subject.ex` |
| WR-02 | FAIL | S-4 | The regenerated dump contains `Threadline.StorageSchema.role/0` as a public type heading, while its source is declared with `@typedoc false`. This is an exported `@type`, not `@typep`, and therefore has no public typedoc as required by S-4(e). | `lib/threadline/storage_schema.ex` |
| WR-03 | PASS | R4 | `Storage.options/0` explicitly says adapter-defined; the six Storage and two ExportQueue callbacks each document their success/error contract in the defining behaviour module. | `lib/threadline/storage.ex`, `lib/threadline/export_queue.ex` |
| WR-04 | PASS | D-10 | The exact captured-data note appears on the required facade read/export entries and the current ChangeDiff and Export docs. | `lib/threadline.ex`, `lib/threadline/change_diff.ex`, `lib/threadline/export.ex` |
| WR-05 | PASS | D-2 | `Audit.transaction/3` opens with its success/error return and explains the conditional audit-ID merge for map values and wrapping for non-map values; the implementation has the corresponding unchanged/no-ID path. | `lib/threadline/audit.ex` |
| WR-06 | PASS | M-2 | ActorRef's moduledoc names `new/2`, `from_map/1`, `identifiable?/1`, and `to_map/1` and says when each is used. | `lib/threadline/semantics/actor_ref.ex` |
| WR-07 | PASS | M-1 | The IncidentChange, LinkedChange, and LinkedTransaction moduledocs begin with one-sentence summaries in domain language; the other reviewed D-46 struct summaries do as well. | `lib/threadline/investigation/incident_bundle.ex`, `lib/threadline/investigation/linked_change.ex` |

## Residual findings

- WR IDs: WR-02 | Rubric: S-4 | Path: lib/threadline/storage_schema.ex:82 | Evidence: the regenerated inventory exposes `Threadline.StorageSchema.role/0` as a public type, but source line 82 marks its only typedoc `false` and line 83 declares it with `@type`; this exported public type has no `@typedoc` content, violating S-4(e).

SPEC-02 remains Pending in `.planning/REQUIREMENTS.md`. Security sign-off remains pending in `.planning/phases/234-typespec-and-doc-completion-gate/234-SECURITY.md` (`status: draft`, `Approval: pending`).

## D-48 work constraints preserved

- never edit gate or pin files except to delete entries the plan fixed;
- never add `@doc false` outside D-07 without halting and reporting;
- never touch `.dialyzer_ignore.exs` or add `@dialyzer`;
- no `--no-verify` or `core.hooksPath`;
- never run `npx` for `@opengsd`;
- leave no background shells or poll loops;
- never `git add .planning/` wholesale;
- before committing planning prose, use the placeholder path forms and grep for the username.
