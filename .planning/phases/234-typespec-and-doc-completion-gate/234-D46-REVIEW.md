# D-46 Documentation and Typespec Review — 2026-10-06

**Verdict:** PASS

## Scope and method

I freshly reviewed the regenerated `.planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW-INPUT.md` against the complete frozen `.planning/phases/234-typespec-and-doc-completion-gate/234-SPEC-RUBRIC.md`, applying only approved amendment D-56. The review-input SHA-256 is `37b2d18cf85a0a5b391c9ff44e12c51791b3874f14df5e338f5ecb3fc735345e`.

I counted every generated visible-entry, moduledoc, and public-type heading and reviewed all 82 visible function/macro entries, 52 moduledocs, and 149 public type entries. I searched every `lib/**/*.ex` file and independently counted and inspected all eight `@callback` declarations. I checked the visible docs and their specs against D-1–D-12, public type and spec relationships against S-1–S-5 and R1–R5, moduledocs against M-1–M-3, and every broad-type occurrence against its named R1, R2, R3, R4, R5, or D-56 route. No unexplained broad type or public spec reference to a private/hidden type remains. The eight pre-existing broad-type allowances remain justified; the additional visible `Retention.Policy.config_map/0` string-key arm is the narrow D-56 exception for ignored values.

The visible-entry pass checked the docs and specs for their caller-visible return, sibling guidance, complete options and filters, unknown-key and error behavior, examples, captured-data notes, and spec shape. This included the former D-2/D-4/D-5/D-6/D-7 gaps listed in the rubric. The moduledoc pass checked one-sentence domain summaries, named entry points for multi-function modules, and stability-language boundaries. The public-type pass checked typedocs, finite shapes, JSON-bound types, option types, broad forms, and every use by public specs. The callback pass checked their typedocs, argument/result docs, and adapter-owned option/error boundaries.

The D-56 aliases now describe recognized keys, per-key values, ignored extras, and mixed-key precedence; runtime behavior remains pinned by executable tests. In particular, `Retention.Policy.config_map/0` has the string-key arm `%{optional(String.t()) => term()}`, so arbitrary values for ignored string keys are accepted by the public type as they are by `resolve!/1`. The current typedoc for `StorageSchema.role/0` names all five identifier roles and is visible in the regenerated public-type inventory, satisfying S-4(e).

`Job.context_opts/2` matches its runtime and compiled type contracts: JSON string-key argument maps are typed through `job_args/0`; allowed `extra` options are validated against `context_opt/0`; integer job/correlation IDs from either source become strings, while strings and `nil` are preserved; extras override extracted IDs; unsupported keys, invalid values, and non-keyword extras raise `ArgumentError`; and `context_opts_result/0` includes the normalized ID tuples. The facade eager exports validate filters/options inside their rescue boundaries, and direct `Export.to_csv_iodata/2` and `to_json_document/2` validate eager options inside their own boundaries. On validation failure these paths emit one zero-row `:failed` event and reraise the original exception before delegation; tests cover CSV/JSON/NDJSON paths and successful completion behavior. `Audit.transaction/3`'s opening return summary matches its conditional audit-ID merge for map results and wrapper for non-map results when a captured transaction row exists.

The focused checks passed:

- `mix test test/threadline/doc_rubric_contract_test.exs test/threadline/retention/policy_test.exs test/threadline/job_test.exs test/threadline/export_test.exs` — 75 tests, 0 failures.
- `mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/public_surface_contract_test.exs` — 52 tests, 0 failures. The contracts retain D-55's `>= 82` visible-entry floor and the exact eight D-07 newly hidden entries.

## Inventory and preserved pins

| Surface | Count | Review evidence |
| --- | ---: | --- |
| Visible function/macro entries | 82 | Complete generated heading inventory; meets D-55's `>= 82` floor. |
| Moduledocs | 52 | Complete generated module-heading inventory; checked against M-1–M-3. |
| Public types | 149 | Complete generated type-heading inventory; checked for typedocs, shapes, broad forms, and public-spec use. |
| Public callbacks | 8 | Independently counted and inspected across all `lib/**/*.ex` files. |
| Broad-type occurrences | 9 | Eight R1/R2/R4 allowances plus the single D-56 `config_map/0` exception; no unexplained visible occurrence. |

D-07 retains exactly these eight newly hidden entries: `Threadline.Evidence.Proof.present_record/1`, `Threadline.Evidence.Proof.record_claim_assessment/1`, `Threadline.StorageSchema.quote_ident/1`, `Threadline.StorageSchema.qualify/2`, `Threadline.StorageSchema.function/2`, `Threadline.StorageSchema.parse_table_identifier/1`, `Threadline.StorageSchema.qualified_host_table/1`, and `Threadline.StorageSchema.host_table_suffix/1`. The public-surface contract also confirms the 23 pre-existing hidden entries and exact 31-entry total hidden pin.

## WR dispositions

- **WR-01 — PASS (R2):** `ActorRef.from_map/1` documents arbitrary decoded input and its finite error outcomes; `Evidence.Subject.validate/1` documents arbitrary input and echoes unsupported normalized/original values. Their public specs preserve those results. Paths: `lib/threadline/semantics/actor_ref.ex`, `lib/threadline/evidence/subject.ex`.
- **WR-02 — PASS (S-4):** Public named types and typedocs satisfy the shape and visibility rules. `StorageSchema.role/0`'s visible typedoc names `:storage_schema`, `:host_schema`, `:host_table`, `:derived`, and `:primary_key_column`. `Retention.Policy.config_map/0` documents the recognized keys and precedence, and its string-key arm now admits arbitrary values for ignored keys as runtime resolution does. Paths: `lib/threadline/storage_schema.ex`, `lib/threadline/retention/policy.ex`.
- **WR-03 — PASS (R4):** `Storage.options/0` and the `ExportQueue.options/0` alias explicitly identify adapter-defined keyword options passed through without interpretation; all eight callback contracts name their results and the adapter-owned error boundary. Paths: `lib/threadline/storage.ex`, `lib/threadline/export_queue.ex`.
- **WR-04 — PASS (D-10):** Required captured-data notes are present on timeline/history, incident, diff, facade export, and direct export documentation. Paths: `lib/threadline.ex`, `lib/threadline/change_diff.ex`, `lib/threadline/export.ex`.
- **WR-05 — PASS (D-2):** Side-effect summaries name caller-visible results or the recorded subject; `Audit.transaction/3` states its tuple result and conditional audit-ID envelope. Paths: `lib/threadline/audit.ex`, `lib/threadline/evidence.ex`, `lib/threadline/export.ex`.
- **WR-06 — PASS (M-2):** Multi-entry module summaries identify their public entry points and use, including the facade and the storage-schema and evidence modules; struct modules use the rubric's concise-summary allowance. Paths: `lib/threadline.ex`, `lib/threadline/storage_schema.ex`, `lib/threadline/evidence.ex`.
- **WR-07 — PASS (M-1):** `Evidence.Proof` starts with a domain-language summary identifying the proof document and its primary public entry points. Path: `lib/threadline/evidence/proof.ex`.

SPEC-02 remains Pending in `.planning/REQUIREMENTS.md`; this review makes no status-file changes.

<!-- d46-pass-evidence:start -->
{
  "review_date": "2026-10-06",
  "reviewer_agent_id": "d46_final_234_22_20261006",
  "executor_agent_id": "finish_234_22_d46",
  "independence_evidence": "Fresh independent reviewer d46_final_234_22_20261006 was dispatched independently of executor finish_234_22_d46 and conducted a separate current-source audit.",
  "review_input_sha256": "37b2d18cf85a0a5b391c9ff44e12c51791b3874f14df5e338f5ecb3fc735345e",
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
      "evidence": "ActorRef.from_map/1 documents arbitrary decoded input with finite errors, and Evidence.Subject.validate/1 documents arbitrary input with the unsupported normalized or original value in its error tuple.",
      "rubric_items": ["R2"],
      "paths": ["lib/threadline/semantics/actor_ref.ex", "lib/threadline/evidence/subject.ex"]
    },
    "WR-02": {
      "status": "PASS",
      "evidence": "StorageSchema.role/0 typedoc names all five identifier roles, and Retention.Policy.config_map/0 documents recognized keys/precedence while its string-key arm admits arbitrary values for ignored keys via term().",
      "rubric_items": ["S-4"],
      "paths": ["lib/threadline/storage_schema.ex", "lib/threadline/retention/policy.ex"]
    },
    "WR-03": {
      "status": "PASS",
      "evidence": "Storage.options/0 and ExportQueue.options/0 explicitly describe adapter-defined pass-through options; all eight callbacks have documented return and opaque adapter-error contracts.",
      "rubric_items": ["R4"],
      "paths": ["lib/threadline/storage.ex", "lib/threadline/export_queue.ex"]
    },
    "WR-04": {
      "status": "PASS",
      "evidence": "The required captured-data note is present on facade timeline/history, incident, diff, and eager/stream export docs, including both direct eager export functions.",
      "rubric_items": ["D-10"],
      "paths": ["lib/threadline.ex", "lib/threadline/change_diff.ex", "lib/threadline/export.ex"]
    },
    "WR-05": {
      "status": "PASS",
      "evidence": "Side-effecting summaries state their result or recorded subject; Audit.transaction/3 specifically documents conditional audit_transaction_id merging for map results and wrapping for non-map results.",
      "rubric_items": ["D-2"],
      "paths": ["lib/threadline/audit.ex", "lib/threadline/evidence.ex", "lib/threadline/export.ex"]
    },
    "WR-06": {
      "status": "PASS",
      "evidence": "Multi-entry facade, storage-schema, and evidence moduledocs name their entry points and use; struct modules follow the rubric's concise-summary allowance.",
      "rubric_items": ["M-2"],
      "paths": ["lib/threadline.ex", "lib/threadline/storage_schema.ex", "lib/threadline/evidence.ex"]
    },
    "WR-07": {
      "status": "PASS",
      "evidence": "Evidence.Proof moduledoc opens with a domain summary identifying its proof document and its primary public entry points.",
      "rubric_items": ["M-1"],
      "paths": ["lib/threadline/evidence/proof.ex"]
    }
  }
}
<!-- d46-pass-evidence:end -->
