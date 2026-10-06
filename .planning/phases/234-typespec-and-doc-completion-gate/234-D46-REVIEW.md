# D-46 documentation and typespec review — 2026-10-06

**Verdict:** FAIL

Input reviewed: `.planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW-INPUT.md`  
SHA-256: `6aca795f242b9fbb5cd2361fe91d31e7f680d4dea93406f03a59df56f8fe159b`

## Review coverage

| Surface | Inventory | Inspection |
|---|---:|---|
| Visible entries | 82 function/macro headings | Counted every complete generated entry heading and reviewed its summary, body, filters/options/returns/examples, and rendered spec against D-1–D-12 and S-1–S-5. Cross-checked defining `lib/` documentation and specs, including the corrected `Audit.transaction/3` source. |
| Moduledocs | 52 headings | Counted and reviewed each generated module summary; checked the current moduledoc source for touched modules against M-1–M-3, domain language, entry-point guidance, and deprecated-pointer constraints. |
| Public types | 149 headings | Counted and reviewed all generated type headings, declarations, and typedocs against S-4/R1–R5 and S-5. Cross-checked the live declarations, including every D-56 map alias and all broad-type occurrences. |
| Public callbacks | 8 declarations | Independently enumerated `@callback` declarations under `lib/`: six in `lib/threadline/storage.ex` and two in `lib/threadline/export_queue.ex`. Read each callback doc, signature, and shared alias in source. |
| Broad-type occurrences | 8 permanent allowances | Reviewed the generated allowance ledger and source declarations for `scope_opt`, `scope_query_fn`, `Audit.transaction/3`, `Subject.validate/1`, `Page.t/0`, `ActorRef.from_map/1`, `ActorRef.identifiable?/1`, and `Storage.options/0`. Each has its stated R1, R2, or R4 basis. Other broad forms in `lib/` are private/hidden implementation contracts or documented adapter-owned data, outside the visible SPEC-02 allowance ledger. |

The input digest was independently computed from the current file and exactly matches the required SHA-256. `.planning/REQUIREMENTS.md` still has `- [ ] **SPEC-02**` and `| SPEC-02 | Phase 234 | Pending |`; `.planning/phases/234-typespec-and-doc-completion-gate/234-SECURITY.md` remains `status: draft` with `**Approval:** pending`.

## WR dispositions

| WR | Status | Rubric | Evidence | Source paths |
|---|---|---|---|---|
| WR-01 | PASS | R2, S-4 | `ActorRef.new/2` constrains supported actor types while `from_map/1` validates arbitrary decoded input; `Subject.validate/1` and `supported?/1` accept arbitrary validator input and preserve the unsupported value in the error. | `lib/threadline/semantics/actor_ref.ex`, `lib/threadline/evidence/subject.ex` |
| WR-02 | FAIL | S-4, D-56 | The three permitted string-key map cases document extra-key acceptance and key precedence, and Plan 16 tests exercise extra and mixed forms. Two contracts still exceed their declared value shapes: Subject recursively normalizes nested descriptors omitted from `subject_descriptor/0`, and retention accepts nil/false atom window values through `||` fallback while its atom-key types only allow positive integers. | `lib/threadline/evidence/subject.ex`, `lib/threadline/retention/policy.ex` |
| WR-03 | PASS | R4, D-2, D-6, S-4 | All six Storage callbacks and both ExportQueue callbacks have source docs describing success/error results; `options()` is explicitly adapter-defined, and the optional `path/1` contract is called out. | `lib/threadline/storage.ex`, `lib/threadline/export_queue.ex` |
| WR-04 | PASS | D-10 | The required captured-data note appears in the facade read docs and in the live `ChangeDiff` and `Export` source docs for captured row-value outputs. | `lib/threadline.ex`, `lib/threadline/change_diff.ex`, `lib/threadline/export.ex` |
| WR-05 | PASS | D-2, S-2 | The opening paragraph of `Audit.transaction/3` states `{:ok, result}` or `{:error, reason}` and accurately says that a captured audit ID is conditionally merged into map results or wraps a non-map result. Its source spec matches that envelope. | `lib/threadline/audit.ex` |
| WR-06 | PASS | M-2 | The ActorRef moduledoc names `new/2`, `from_map/1`, `identifiable?/1`, and `to_map/1`, with their respective use cases. | `lib/threadline/semantics/actor_ref.ex` |
| WR-07 | PASS | M-1, M-2 | The current moduledocs for NotFoundError, Page, Telemetry, IncidentBundle, IncidentChange, LinkedChange, and LinkedTransaction begin with domain summaries; Telemetry names the adopter entry point and distinguishes internal hooks. | `lib/threadline/not_found_error.ex`, `lib/threadline/page.ex`, `lib/threadline/telemetry.ex`, `lib/threadline/investigation/incident_bundle.ex`, `lib/threadline/investigation/linked_change.ex` |

## D-56 source and compatibility review

- `ActorRef.actor_map/0` documents the always-emitted string `"type"`, optional emitted `"id"`, value behavior for anonymous and directly constructed refs, ignored extra atom/string keys, and recognized-string-key precedence. `from_map/1` confirms those decoder rules. The executable tests in `test/threadline/semantics/actor_ref_test.exs` cover extra keys, mixed atom/string keys, and the unrecognized atom-only form.
- `Subject.subject_descriptor/0` documents recognized keys, their precedence, accepted atom/string values, ignored extras, mixed maps, and unknown-only behavior. `normalize/1` confirms clause order; `test/threadline/evidence/subject_test.exs` covers extra keys, precedence (including an invalid higher-priority value), nested normalization, and unchanged unknown-only errors. The recursive case also exposes the residual value-shape mismatch below.
- `Retention.Policy.config_map/0` documents all four key spellings, boolean and window value domains, ignored extras, and the distinct boolean/window fallback rules. `resolve!/1` implements those rules; `test/threadline/retention/policy_test.exs` covers extra keys, mixed maps, atom boolean precedence, invalid boolean handling, positive-window precedence, nil/false window fallback, and conflicts. Those nil/false accepted values expose the residual atom-type mismatch below.
- The `Audit.transaction/3` opening was checked in current source against its type variable and return spec; the conditional ID merge/wrap is accurately stated.

## Residual findings

- WR IDs: WR-02 | Rubric: S-4, D-56 | Path: lib/threadline/evidence/subject.ex:27 | Evidence: `normalize/1` recursively accepts a recognized descriptor value such as `%{subject: %{"name" => :retention_run}}` (also pinned by `test/threadline/evidence/subject_test.exs`), but `subject_descriptor/0` restricts both atom-key and string-key map values to `atom() | String.t()`, so the public descriptor type omits an accepted nested map value that its typedoc says is recursively normalized.
- WR IDs: WR-02 | Rubric: S-4, D-56 | Path: lib/threadline/retention/policy.ex:26 | Evidence: `resolve!/1` computes window values with `Map.get(opts, :keep_days) || Map.get(opts, "keep_days")` (and the corresponding max-age expression), so atom `nil` and `false` fall back and are accepted when a string value is present, as asserted by `test/threadline/retention/policy_test.exs`; `config_opt/0` and the atom-key arm of `config_map/0` only permit `pos_integer()` for those keys.

SPEC-02 and security sign-off remain pending.
