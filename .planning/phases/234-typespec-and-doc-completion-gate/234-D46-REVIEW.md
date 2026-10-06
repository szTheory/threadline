# D-46 documentation and typespec review — 2026-10-05

**Verdict:** FAIL

Input reviewed: `.planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW-INPUT.md`

SHA-256: `c6cf53651019e77f9e1e526953d6dd94a14eace01255b68881d59fc62d1115ad`

## Review coverage

| Surface | Inventory | Assessment |
|---|---:|---|
| Visible entries | 82 headings (81 functions, 1 macro) | Read each complete entry heading, documentation block, and emitted spec against D-1–D-12 and S-1–S-5. Cross-checked affected contract claims against live `lib/` definitions. |
| Moduledocs | 52 headings | Read each generated summary and checked touched module openings against M-1/M-2, plus the domain-language and deprecated-reference rules. Separately checked the five current moduledocs named in the dispatch. |
| Public types | 149 headings | Read each typedoc and declaration, including structs, option/result aliases, and JSON-bound types; checked typedoc presence and shape precision against R1–R5 and S-4/S-5. |
| Public callbacks | 8 live `@callback` declarations | Counted `@callback` declarations independently across `lib/**/*.ex` (6 in `lib/threadline/storage.ex`, 2 in `lib/threadline/export_queue.ex`) and checked each callback's typedoc, options/error aliases, and success/error summary against R4 and D-2/D-6/S-4. |
| Broad-type occurrences | 14 textual hits | Accounted for 10 spec/type occurrences (`term()` 8, `map()` 1, `keyword()` 1) and 4 inline callback-shape examples. Checked each against the permanent allowances and current source. The `term()`/`map()` scope contracts, validator inputs, generic page type, opaque transaction result/reason, and adapter-defined options have their stated R1/R2/R4 basis. The `Threadline.StorageSchema.role/0` heading has no user-facing typedoc, but live source marks it `@typedoc false` and uses it only in `@doc false` helper specs; that hidden-only occurrence is within R5. |

## WR dispositions

| WR | Status | Rubric | Evidence | Source paths |
|---|---|---|---|---|
| WR-01 | PASS | R2 | `ActorRef.new/2` uses `actor_type_input()` while preserving its narrow success and error union; `Evidence.Subject.validate/1` and `supported?/1` accept `subject_input()` and retain the validator error or boolean result. | `lib/threadline/semantics/actor_ref.ex`, `lib/threadline/evidence/subject.ex` |
| WR-02 | FAIL | S-4 | The three finite map aliases still allow string keys beyond their documented/runtime key sets; the retention string-key form also merges fields with distinct value domains. | `lib/threadline/semantics/actor_ref.ex`, `lib/threadline/evidence/subject.ex`, `lib/threadline/retention/policy.ex` |
| WR-03 | PASS | R4, D-2, D-6, S-4 | Both adapter behaviours use documented `options()` and `error_reason()` aliases; all eight callbacks describe their success and error returns, including optional `Storage.path/1`. | `lib/threadline/storage.ex`, `lib/threadline/export_queue.ex` |
| WR-04 | PASS | D-10 | The 13 listed facade/ChangeDiff row-value reads include the prescribed captured-column, trigger-time redaction, and `:scope_query_fn` note in the generated input; live facade and ChangeDiff docs agree. | `lib/threadline.ex`, `lib/threadline/change_diff.ex` |
| WR-05 | FAIL | D-2 | The validator, retention, record-action, and Continuity summaries state their return shape; `Audit.transaction/3`'s first paragraph describes execution but leaves its `{:ok, result} | {:error, reason}` envelope to the spec/module text. | `lib/threadline/audit.ex`, `lib/threadline.ex`, `lib/threadline/retention.ex`, `lib/threadline/continuity.ex` |
| WR-06 | PASS | M-2 | The ActorRef moduledoc names `new/2`, `from_map/1`, `identifiable?/1`, and `to_map/1`, and states when each is used. | `lib/threadline/semantics/actor_ref.ex` |
| WR-07 | PASS | M-1, M-2 | The five requested current openings are complete domain sentences; the Telemetry moduledoc also names its adopter entry point and distinguishes internal hooks. | `lib/threadline/not_found_error.ex`, `lib/threadline/page.ex`, `lib/threadline/telemetry.ex`, `lib/threadline/investigation/incident_bundle.ex`, `lib/threadline/investigation/linked_change.ex` |

## Residual findings

- WR IDs: WR-02 | Rubric: S-4 (R2) | Path: lib/threadline/semantics/actor_ref.ex | Evidence: `actor_map()` is `%{required(String.t()) => String.t()}`, which permits arbitrary string keys and does not guarantee the documented `"type"` key or the optional `"id"` key shape produced by `to_map/1`.
- WR IDs: WR-02 | Rubric: S-4 (R2) | Path: lib/threadline/evidence/subject.ex | Evidence: `subject_descriptor()` includes `%{optional(String.t()) => atom() | String.t()}`, which admits arbitrary string keys although `normalize/1` recognizes only `"subject"` and `"name"`.
- WR IDs: WR-02 | Rubric: S-4 (R2) | Path: lib/threadline/retention/policy.ex | Evidence: `config_map()` accepts any `String.t()` key and unions boolean/string/positive-integer values, rather than naming the four accepted string spellings and their per-field value domains.
- WR IDs: WR-05 | Rubric: D-2 | Path: lib/threadline/audit.ex | Evidence: `transaction/3`'s first paragraph begins “Runs `fun` inside `repo.transaction/1`” and gives no return shape; the `{:ok, result} | {:error, term()}` envelope appears only in the spec and later module-level detail.

SPEC-02 and security sign-off remain pending, as required for a FAIL verdict.
