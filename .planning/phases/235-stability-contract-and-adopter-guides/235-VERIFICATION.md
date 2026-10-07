---
phase: 235-stability-contract-and-adopter-guides
verified: 2026-10-07T02:58:28Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - .planning/phases/235-stability-contract-and-adopter-guides/235-01-PLAN.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-01-SUMMARY.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-02-PLAN.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-02-SUMMARY.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-03-PLAN.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-03-SUMMARY.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-04-PLAN.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-04-SUMMARY.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-05-PLAN.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-05-SUMMARY.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-REVIEW-DISPOSITION.md
  - .planning/phases/235-stability-contract-and-adopter-guides/235-VALIDATION.md
  - .planning/phases/235-stability-contract-and-adopter-guides/REVIEW.md
  - guides/getting-started-saas.md
  - guides/redaction.md
  - guides/stability.md
  - guides/supported-tables.md
  - lib/mix/tasks/threadline.gen.triggers.ex
  - lib/threadline/capture/audit_change.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/capture/primary_key_sql.ex
  - lib/threadline/semantics/audit_action.ex
  - mix.exs
  - test/mix/tasks/threadline/gen_triggers_test.exs
  - test/threadline/capture/public_sql_contract_test.exs
  - test/threadline/capture/redaction_leak_property_test.exs
  - test/threadline/capture/trigger_migrate_time_errors_test.exs
  - test/threadline/doc_rubric_contract_test.exs
  - test/threadline/doc_spec_coverage_contract_test.exs
  - test/threadline/export_public_contract_test.exs
  - test/threadline/guide_graph_contract_test.exs
  - test/threadline/guides/redaction_contract_test.exs
  - test/threadline/guides/stability_contract_test.exs
  - test/threadline/guides/table_shapes_contract_test.exs
  - test/threadline/public_options_contract_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/schema_fields_contract_test.exs
  - test/threadline/storage_catalog_contract_test.exs
covered_digest: "v3:sha256:a65ccde897012bfe1d7a9fea894c18cf1dc3372e7bfc68e856d2d35f93859ea7"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 5/5 must-haves verified
  gaps_closed: []
  gaps_remaining: []
  regressions: []
  final_inputs_rechecked:
    - "test/threadline/guides/redaction_contract_test.exs"
    - ".planning/phases/235-stability-contract-and-adopter-guides/REVIEW.md"
    - ".planning/phases/235-stability-contract-and-adopter-guides/235-REVIEW-DISPOSITION.md"
    - ".planning/phases/235-stability-contract-and-adopter-guides/235-VALIDATION.md"
    - ".planning/phases/235-stability-contract-and-adopter-guides/235-05-SUMMARY.md"
unverified_prohibition_count: 5
unverified_prohibition_note: "Five flagged groups summarize nine unresolved judgment-tier clauses from the five plans. Each is a non-authoritative read-only review; human review is recommended."
unverified_prohibitions:
  - group: "Redaction scope, rollout, and bypass boundaries (235-01; two clauses)"
    verdict: "unverified-prohibition — human review recommended"
    observation: "Non-authoritative read-only review observed no current violation. The guide explicitly limits evidence to generated per-table paths, describes host migration rollout and prior-row limits, and names global installer/direct create_trigger paths as outside this proof."
    uncertainty: "Redaction output-property evidence and generated-migration column-validation evidence are distinct proofs; neither establishes equivalent behavior for the global installer or direct create_trigger path."
  - group: "Stability API boundary and supported-table conditions (235-02; two clauses)"
    verdict: "unverified-prohibition — human review recommended"
    observation: "Non-authoritative read-only review observed no current violation. The stability guide excludes rendered HTML/CSS/LiveView internals from API; the table matrix states install conditions and the unlogged-table crash-durability caveat."
    uncertainty: "The contract pins prose and source conditions, but semantic interpretation by adopters remains a judgment call."
  - group: "Storage catalog and SQL-name independence (235-03; two clauses)"
    verdict: "unverified-prohibition — human review recommended"
    observation: "Non-authoritative read-only review observed no current violation. The storage assertion queries installed PostgreSQL catalogs and compares facts with test-local literals; public SQL tests use literal GUC/function names and inspect production call sites."
    uncertainty: "The catalog mutation control is synthetic while the principal catalog assertion queries live PostgreSQL; source-use checks assume the current static declaration patterns."
  - group: "Public-set expected-value independence (235-04; one clause)"
    verdict: "unverified-prohibition — human review recommended"
    observation: "Non-authoritative read-only review observed no current violation. CSV/JSON shapes, Finding codes, task flags, router options, and routes have explicit test-local expected sets, with observed export output and mutation controls."
    uncertainty: "Some actual inventories are extracted from current source declarations, so the review does not independently validate future source forms that no longer match those extraction patterns."
  - group: "Stable field subsets and JSONB promise limits (235-05; two clauses)"
    verdict: "unverified-prohibition — human review recommended"
    observation: "Non-authoritative read-only review observed no current violation. Schema tests compare literal selected subsets to Ecto fields; moduledocs limit JSONB promises to additive keys/shapes and disclaim byte stability, key order, and rewrites of existing rows."
    uncertainty: "The test proves field presence and pinned wording; it cannot settle every reader's interpretation of the documented compatibility boundary."
decision_coverage:
  honored: 9
  total: 9
  not_honored: []
human_verification: []
---

# Phase 235: Stability Contract and Adopter Guides Verification Report

**Phase Goal:** An adopter or security reviewer can read exactly what 1.x promises, which tables Threadline supports, and what redaction does and does not guarantee. Every one of those statements is held in place by a test that fails CI on drift.
**Verified:** 2026-10-07T02:58:28Z
**Status:** passed, with 5 flagged prohibition groups (human review recommended)
**Re-verification:** Yes — final-input check after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The stability guide states the 1.x API/database/operator/type-spec/backport promises and tests pin each statement. | ✓ VERIFIED | `guides/stability.md` states the compatibility clauses. `stability_contract_test.exs` now pins additive tables, columns, indexes, the 0.12.x line, and six months after 0.12.0; the removal mutation control remains. The focused rerun passed. |
| 2 | Live schema and literal SQL tests pin audit tables, fields, indexes, actor GUC, and trigger-function naming. | ✓ VERIFIED | `storage_catalog_contract_test.exs` queries installed PostgreSQL `pg_catalog` and compares literal facts. `public_sql_contract_test.exs` pins literal names, generated SQL, and production call sites. Existing passing contract was regression-checked for file presence and substantive assertions; the orchestrator reports the final full CI gate passed. |
| 3 | Additive-only contracts pin export shapes, Finding codes, Mix flags, and operator options/routes. | ✓ VERIFIED | `export_public_contract_test.exs` exercises CSV/JSON output against literals; `public_options_contract_test.exs` inventories task flags, router options, and route templates against literal sets. Both retain mutation controls. Existing passing contracts were regression-checked and are included in the reported final CI gate. |
| 4 | The three Ecto schemas publish stable field subsets and additive JSONB shape promises guarded against schema drift. | ✓ VERIFIED | `schema_fields_contract_test.exs` compares literal subsets with `__schema__(:fields)`, checks moduledoc claims and additive JSONB limits, permits unpromised fields, and tests removed-field mutations. |
| 5 | Supported-table and redaction guides are accurate, discoverable, and held by document contracts. | ✓ VERIFIED | `table_shapes_contract_test.exs` pins eligibility conditions and caveats to implementation; guide graph registers and links the guides. The updated redaction contract uses exact bounded-sentence allowlists, rejects broader absolute/compound forms, validates repository-local evidence links, and checks claim/evidence pairing. The focused re-run passed. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Re-verification

The two carried gaps remain closed. The stability contract asserts the additive-only table/column/index list and the exact 0.12.x six-month period after 0.12.0. The final redaction contract tightens the prior fix with adversarial sentence variants, exact bounded claim allowlists, and repository-identity checks for evidence links. The focused stability/redaction run passed again after those changes. The supplied final `mix ci.all` evidence passed, and no regression was identified. No later phase specifically owns either former gap; both are closed here.

### Autonomous Judgment-Tier Prohibition Review

This phase is configured with `mode: yolo`. The five flags below summarize all nine unresolved judgment-tier clauses carried in the plans. Each verdict is explicitly **non-authoritative**: a read-only review observed no current violation, while the listed uncertainty remains. These flags are not silently treated as proven. The autonomous workflow records “complete with 5 flagged prohibitions”; no manual UAT step is fabricated.

| Group | Non-authoritative observation | Remaining uncertainty | Flag |
|---|---|---|---|
| Redaction scope, rollout, and bypass boundaries | Guide states the generated per-table scope, host migration rollout, prior-row limit, and uncovered global/direct paths. | Output-property and migration-validation evidence prove different properties; global/direct behavior remains outside the proof. | unverified-prohibition — human review recommended |
| Stability API boundary and table conditions | Guide excludes rendered internals from API and documents table install conditions and crash durability caveat. | Semantic interpretation remains judgment-tier. | unverified-prohibition — human review recommended |
| Storage catalog and SQL-name independence | Live catalog facts are compared with literals; SQL names and production uses are pinned. | Mutation control is synthetic; static source scans assume current declaration patterns. | unverified-prohibition — human review recommended |
| Public-set expected-value independence | Export values and public sets are compared with explicit test-local pins and mutation controls. | Source inventory extraction assumes current source declaration patterns. | unverified-prohibition — human review recommended |
| Stable field subsets and JSONB promise limits | Literal subsets, documented limits, and removal controls are present. | Tests cannot settle every interpretation of the wording. | unverified-prohibition — human review recommended |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `guides/stability.md` and `test/threadline/guides/stability_contract_test.exs` | 1.x compatibility policy and drift gate | ✓ VERIFIED | Substantive claims include the corrected additive database object list and exact backport window; focused contract passes. |
| `guides/supported-tables.md` and `test/threadline/guides/table_shapes_contract_test.exs` | Pre-install table eligibility matrix | ✓ VERIFIED | Conditions, unsupported shapes, and durability caveats are asserted and connected to source predicates. |
| `guides/redaction.md` and `test/threadline/guides/redaction_contract_test.exs` | Evidence-linked redaction threat guide | ✓ VERIFIED | Per-row guarantee/evidence checks, residual plaintext locations, rollout boundaries, absolute-term checks, and mutation checks are present. |
| `lib/threadline/capture/primary_key_sql.ex` and migration regression | Generated migration configured-column guard | ✓ VERIFIED | Both detected-key and override branches validate configured columns before trigger DDL; PostgreSQL regression is part of the reported full CI run. |
| Storage, public SQL, export, options, schema, and guide-graph contracts | Compatibility drift gates | ✓ VERIFIED | Tests contain literal pins, live/observed inputs where required, and named mutation controls; all are covered by the reported final CI gate. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `primary_key_sql.ex` | `trigger_migrate_time_errors_test.exs` | Generated host migration and PostgreSQL harness | WIRED | Manually traced generator → SQL → MigrationHarness; the generic CLI heuristic cannot see this runtime harness link. |
| `guides/redaction.md` | `redaction_leak_property_test.exs` | Claim-level evidence links | WIRED | Guide links the test and scopes it to generated per-table capture. |
| New guides | `mix.exs` / `guide_graph_contract_test.exs` | ExDoc Adopt lane and guide graph | WIRED | ExDoc extras and guide graph/landing registration are present. |
| `guides/stability.md` | `stability_contract_test.exs` | Required claim assertions | WIRED | Guide loaded and checked against all literal required claims; gap-closure assertions passed. |
| `guides/supported-tables.md` | `primary_key_sql.ex` | Eligibility and type/index predicates | WIRED | Contract checks source predicates and table-shape claims. |
| `storage_catalog_contract_test.exs` | PostgreSQL `pg_catalog` | DataCase Repo queries | WIRED | Queries actual configured storage schema, columns, types, nullability, and indexes. |
| `public_sql_contract_test.exs` | SQL naming and GUC production sources | Literal names and source-use checks | WIRED | Calls naming functions, checks generated SQL and production call-site inventories. |
| `export_public_contract_test.exs` | Export and health producers | Database fixtures and observed output | WIRED | Executes CSV/JSON exports and compares output and Finding producer codes with literals. |
| `public_options_contract_test.exs` | Mix task/router sources | Inventory and macro/route scans | WIRED | Compares shipped task/flag, macro option, and route sets to literal pins. |
| `schema_fields_contract_test.exs` | Three Ecto schemas | `__schema__(:fields)` and `Code.fetch_docs/1` | WIRED | Checks actual schema fields and compiled moduledocs against literal subsets and claims. |

### Data-Flow Trace (Level 4)

No rendered dynamic UI data is part of this documentation/contract phase. The migration, storage, export, and redaction contracts trace to PostgreSQL queries, generated SQL, or observed public function output rather than static return stubs.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Stability and redaction gap-closure document contracts | `mix verify.test test/threadline/guides/stability_contract_test.exs test/threadline/guides/redaction_contract_test.exs` | 5 tests, 0 failures | ✓ PASS |
| Full final phase/workspace gates | `mix ci.all` (final CI evidence supplied for this revision) | Repo hygiene 4,651 clean/8 used/0 inert; root 3,047 tests, 0 failures, 3 excluded; example 130/0; Dialyzer passed; slice 17/0/16 excluded; browser 318 passed/26 skipped | ✓ PASS |

### Probe Execution

Not applicable. No phase-declared or conventional `scripts/*/tests/probe-*.sh` probe is associated with this documentation and contract phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| CONTRACT-01 | 235-02 | 1.x stability guide and claim-level drift gate | SATISFIED | Corrected literal claim set passes focused test. |
| CONTRACT-02 | 235-03 | Installed schema columns/types/nullability and indexes | SATISFIED | Live `pg_catalog` query compared with independent literal sets. |
| CONTRACT-03 | 235-03 | Actor GUC and trigger-function naming contract | SATISFIED | Literal output names and production call-site contract. |
| CONTRACT-04 | 235-04 | Export, Finding, task, router option/route allowlists | SATISFIED | Observed exports and literal expected sets with mutation controls. |
| CONTRACT-05 | 235-05 | Stable Ecto field subsets and additive captured-data promises | SATISFIED | Schema metadata and moduledoc contract. |
| DOCS-01 | 235-02 | Supported-table eligibility guide and implementation-linked contract | SATISFIED | Table matrix claims checked against code and evidence. |
| DOCS-02 | 235-01 | Redaction threat model, limits, evidence, and claim drift gate | SATISFIED | Updated absolute scanner and per-guarantee evidence pairing pass. |

No orphaned phase requirements were found. Later phase 236 and 237 goals do not cover either carried gap; both are closed in this phase.

### Test Quality Audit

| Test File | Linked Requirement | Active | Circular | Assertion Level | Verdict |
|---|---|---:|---|---|---|
| `trigger_migrate_time_errors_test.exs` | DOCS-02 | Yes | No | PostgreSQL behavior and rollback | PASS |
| `redaction_leak_property_test.exs` | DOCS-02 | Yes | No | Property/behavior across storage and exports | PASS |
| `redaction_contract_test.exs` | DOCS-02 | Yes | No | Document value, row pairing, mutation controls | PASS |
| `stability_contract_test.exs` | CONTRACT-01 | Yes | No | Required claims and mutation control | PASS |
| `table_shapes_contract_test.exs` | DOCS-01 | Yes | No | Required claims, source predicates, mutation | PASS |
| `storage_catalog_contract_test.exs` | CONTRACT-02 | Yes | No | Live catalog values and mutation control | PASS |
| `public_sql_contract_test.exs` | CONTRACT-03 | Yes | No | Literal values and source call sites | PASS |
| `export_public_contract_test.exs` | CONTRACT-04 | Yes | No | Observed output and literal code/key sets | PASS |
| `public_options_contract_test.exs` | CONTRACT-04 | Yes | No | Literal sets and source inventory | PASS |
| `schema_fields_contract_test.exs` | CONTRACT-05 | Yes | No | Schema metadata and documentation mutations | PASS |

No disabled requirement-linked tests were found. Mutation controls use in-memory altered inputs rather than writing generated expected values from the implementation under test.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No unresolved `TBD`, `FIXME`, or `XXX` debt marker and no implementation stub found in phase artifacts. A grep hit for “placeholder” occurs only in `doc_rubric_contract_test.exs`, where the test names the condition it detects. | — | No blocker. |

### Human Verification Required

None. This is an autonomous `yolo` run with no user-facing runtime flow requiring manual UAT. The five judgment-tier groups remain explicitly flagged above as **unverified-prohibition — human review recommended**; their read-only verdicts are non-authoritative and not counted as proof.

### Gaps Summary

No blocking gaps remain. The two prior document-contract failures are closed and the focused regression passed again against the final redaction contract. The roadmap contract is verified at 5/5. Final full CI passed on the current inputs. Five grouped judgment-tier prohibition flags remain visible (summarizing nine plan clauses), with their limits stated above; autonomous completion is therefore reported as complete with 5 flagged prohibitions.

### Decision Coverage

All 9 of 9 trackable CONTEXT.md decisions are honored by shipped artifacts; none were unhonored. This gate is warning-only and does not affect the phase status.

---

_Verified: 2026-10-07T02:58:28Z_  
_Verifier: the agent (gsd-verifier)_
