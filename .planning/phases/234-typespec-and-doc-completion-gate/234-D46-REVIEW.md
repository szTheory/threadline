# D-46 Documentation and Typespec Review — 2026-10-06

**Verdict:** PASS

Input reviewed: `.planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW-INPUT.md`  
SHA-256: `e341c89282ceca06f738754985c2aaff4af24e2c9b2ed7efb792a8dc70fd6cb8`

## Review coverage and methodology

I independently counted the generated headings in the hash-identified review input and checked each compiled visible function or macro, each moduledoc, and each public type against the frozen rubric and D-56 amendment. I traced every source-level @callback under `lib/` independently, then checked its signature and documentation. For broad types, I reconciled each occurrence in the generated permanent-allowance ledger with its current source declaration and R1/R2/R4 rationale, checked the D-56 finite-map exceptions and their atom-key alternatives, and searched current `lib/` sources for additional broad forms in the public surface. The inventory and source evidence follow.

| Surface | Count | Review method |
|---|---:|---|
| Visible function/macro entries | 82 | Counted all `### ... (function|macro)` headings in the generated input; checked summaries, sibling links, filters/options, errors/raises, return shapes, examples, specs, and applicable D-1–D-12/S-1–S-5 rules against the current facade/module source. The count meets D-55's `>= 82` floor. |
| Moduledocs | 52 | Counted all generated module headings; reviewed one-sentence opening summaries, entry-point coverage for modules with three or more public functions, domain language, voice, and stability promises against M-1–M-3. |
| Public types | 149 | Counted all `(@type)` headings; checked each typedoc and the public spec references against S-4/S-5 and R1–R5, including structs, finite unions, options, JSON-bound shapes, the three D-56 map aliases, and every atom-key alternative. |
| Public callbacks | 8 | Independently enumerated six callbacks in `lib/threadline/storage.ex` and two in `lib/threadline/export_queue.ex`; checked each callback's source docs and success/error contract. |
| Broad-type occurrences | 8 permanent public allowances | Matched all eight ledger entries to live source and their specific R1, R2, or R4 reason; checked other public broad forms against R1–R5, including named JSON-map output/input types and private/hidden boundaries. No unlisted public broad-type mismatch was found. |

## Focused current-source checks

- **WR-01 / R2 — validator and predicate inputs:** `ActorRef.from_map/1` and `identifiable?/1` accept arbitrary input and return results describing validity/identifiability; `Evidence.Subject.validate/1` reports the unsupported input in its error. Their public docs and specs identify those behaviors. The broad input types therefore meet R2.
- **WR-02 / S-4 — public role type:** `Threadline.StorageSchema.role/0` is visible in the regenerated public type inventory. Its current `@typedoc` in `lib/threadline/storage_schema.ex` names and explains all five accepted roles: `:storage_schema`, `:host_schema`, `:host_table`, `:derived`, and `:primary_key_column`. The type is documented and the five-role union remains finite.
- **WR-03 / R4 — adapter callbacks:** `Threadline.Storage.options/0` describes keyword options as adapter-defined and passed through without Threadline interpreting their keys. `Threadline.ExportQueue.options/0` delegates to that type and repeats the adapter-defined contract. All eight public callbacks state their result contracts; the optional `path/1` behavior is identified.
- **WR-04 / D-10 — captured-data note:** The required note is present on facade timeline, row-history, incident-bundle, change-diff, and export docs, as well as the dedicated `Threadline.ChangeDiff` and `Threadline.Export` docs. It retains the rubric's exact captured-values/redaction/read-authorization statement.
- **WR-05 / D-2 — transaction return summary:** `Threadline.Audit.transaction/3` opens by naming its `{:ok, result}` / `{:error, reason}` return envelope and says when the audit transaction ID is merged into map results or wraps non-map results. The current `attach_audit_transaction_id/3` and `envelope/2` implement those cases; the no-ID path returns the original result.
- **WR-06 / M-2 — ActorRef entry points:** The `Threadline.Semantics.ActorRef` moduledoc names `new/2`, `from_map/1`, `identifiable?/1`, and `to_map/1`, and describes when to use each.
- **WR-07 / M-1 — investigation struct summaries:** `IncidentChange`, `LinkedChange`, and `LinkedTransaction` each start with a one-sentence domain-language moduledoc summary in their defining source files.
- **Corrected `record_action/2` example:** `lib/threadline.ex` matches `{:ok, actor}` from `Threadline.Semantics.ActorRef.new(:user, "u-42")` and passes that validated ActorRef to `record_action/2`; the DataCase test exercises that value through successful persistence and checks the compiled docs mention the constructor.
- **`Job.context_opts/2` runtime/doc agreement:** `lib/threadline/job.ex` states that other `extra` keys are retained by the helper and ignored by `record_action/2`, and that `context_opt()` describes supported options. Runtime `build_attrs/3` reads the supported record-action keys, while `context_opts/2` uses `Keyword.merge/2` and thus retains extras. Current job and action tests pin extra-key retention, known-key override, and a successful insert through the helper with an extra key.
- **D-22 / Phase 231 D-05 capture boundary:** `AuditTransaction.t.action` is `struct() | nil`, while its typedoc still describes the hydrated `AuditAction` value before hydration. The existing executable boundary test inspects the compiled type and parses the nonempty `lib/threadline/capture/**/*.ex` source set for aliased or fully qualified `AuditAction.t()` references in AST; current capture source contains no such type reference. No capture-to-semantics association was added.
- **D-55 and D-07 preservation:** The visible entry inventory is exactly 82, meeting the approved floor. The eight D-07 transitions remain exactly `Evidence.Proof.present_record/1`, `Evidence.Proof.record_claim_assessment/1`, `StorageSchema.quote_ident/1`, `StorageSchema.qualify/2`, `StorageSchema.function/2`, `StorageSchema.parse_table_identifier/1`, `StorageSchema.qualified_host_table/1`, and `StorageSchema.host_table_suffix/1`. The current coverage contract pins these exact keys, checks the complete live-hidden set against the pin, and checks the eight new pins' Unreleased entries.

## WR dispositions

| WR | Status | Rubric | Evidence |
|---|---|---|---|
| WR-01 | PASS | R2 | Arbitrary-input validator and predicate specs report validity and unsupported values as R2 permits. |
| WR-02 | PASS | S-4 | `StorageSchema.role/0` has a non-empty typedoc naming all five identifier roles and its documented finite union. |
| WR-03 | PASS | R4 | Storage options are adapter-defined and uninterpreted; each of the eight public callbacks documents its result behavior. |
| WR-04 | PASS | D-10 | The required captured-data note appears across the facade read/export families and dedicated change-diff/export entries. |
| WR-05 | PASS | D-2 | The transaction summary names the return envelope and conditional ID merge/wrap, matching the current helper clauses. |
| WR-06 | PASS | M-2 | ActorRef's moduledoc names all four public entry points and their uses. |
| WR-07 | PASS | M-1 | IncidentChange, LinkedChange, and LinkedTransaction open with domain-language one-sentence summaries. |

SPEC-02 remains Pending in `.planning/REQUIREMENTS.md`; security approval remains pending in `.planning/phases/234-typespec-and-doc-completion-gate/234-SECURITY.md`. This review does not change either status. The unrelated persistent mobile E2E failure reported for `mix ci.all` is a separate Plan 20 gate status and is not a D-46 rubric finding.

<!-- d46-pass-evidence:start -->
{
  "review_date": "2026-10-06",
  "reviewer_agent_id": "/root/execute_234_20/fresh_d46_review_23420",
  "executor_agent_id": "/root/execute_234_20",
  "independence_evidence": "Fresh independent review by /root/execute_234_20/fresh_d46_review_23420, separately dispatched and independent of executor /root/execute_234_20; I counted the current input and checked the current source myself.",
  "review_input_sha256": "e341c89282ceca06f738754985c2aaff4af24e2c9b2ed7efb792a8dc70fd6cb8",
  "reviewed_surfaces": [
    "visible_entries",
    "moduledocs",
    "public_types",
    "public_callbacks",
    "broad_type_occurrences"
  ],
  "inventory": {
    "visible_entries": 82,
    "moduledocs": 52,
    "public_types": 149,
    "public_callbacks": 8
  },
  "wr_dispositions": {
    "WR-01": {
      "status": "PASS",
      "evidence": "ActorRef validators and Subject.validate/1 accept broad input, return validity results, and preserve unsupported values in errors as R2 permits.",
      "rubric_items": ["R2"],
      "paths": ["lib/threadline/semantics/actor_ref.ex", "lib/threadline/evidence/subject.ex"]
    },
    "WR-02": {
      "status": "PASS",
      "evidence": "StorageSchema.role/0 has a public typedoc naming the five storage, host, derived, and primary-key identifier roles above its finite union.",
      "rubric_items": ["S-4"],
      "paths": ["lib/threadline/storage_schema.ex"]
    },
    "WR-03": {
      "status": "PASS",
      "evidence": "Storage options are explicitly adapter-defined and uninterpreted, and all eight public callbacks document their success, error, and optional behavior.",
      "rubric_items": ["R4"],
      "paths": ["lib/threadline/storage.ex", "lib/threadline/export_queue.ex"]
    },
    "WR-04": {
      "status": "PASS",
      "evidence": "The required captured-value, trigger-time redaction, and scoped-read note appears on all required facade families and dedicated diff/export docs.",
      "rubric_items": ["D-10"],
      "paths": ["lib/threadline.ex", "lib/threadline/change_diff.ex", "lib/threadline/export.ex"]
    },
    "WR-05": {
      "status": "PASS",
      "evidence": "Audit.transaction/3 states its success/error envelope and conditional audit ID merge/wrap, matching attach_audit_transaction_id/3 and envelope/2.",
      "rubric_items": ["D-2"],
      "paths": ["lib/threadline/audit.ex"]
    },
    "WR-06": {
      "status": "PASS",
      "evidence": "ActorRef's moduledoc names new/2, from_map/1, identifiable?/1, and to_map/1 and tells callers the purpose of each entry point.",
      "rubric_items": ["M-2"],
      "paths": ["lib/threadline/semantics/actor_ref.ex"]
    },
    "WR-07": {
      "status": "PASS",
      "evidence": "IncidentChange, LinkedChange, and LinkedTransaction each begin with a one-sentence domain-language summary in current moduledocs.",
      "rubric_items": ["M-1"],
      "paths": ["lib/threadline/investigation/incident_bundle.ex", "lib/threadline/investigation/linked_change.ex"]
    }
  }
}
<!-- d46-pass-evidence:end -->

## Phase 234 Plan 13 handoff

Accepted the fresh independent PASS dated 2026-10-06 for review input SHA-256 `e341c89282ceca06f738754985c2aaff4af24e2c9b2ed7efb792a8dc70fd6cb8`. SPEC-02 remains Pending because Plan 20's required `mix ci.all` gate failed in the unrelated mobile E2E lane; no requirement or security sign-off is inferred from this review alone.
