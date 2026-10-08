---
phase: 233-lookup-return-shapes
verified: 2026-10-08T01:24:08Z
status: passed
score: 3/3 roadmap truths verified
covered_files:
  - ".planning/phases/233-lookup-return-shapes/233-01-PLAN.md"
  - ".planning/phases/233-lookup-return-shapes/233-01-SUMMARY.md"
  - ".planning/phases/233-lookup-return-shapes/233-02-PLAN.md"
  - ".planning/phases/233-lookup-return-shapes/233-02-SUMMARY.md"
  - ".planning/phases/233-lookup-return-shapes/233-03-PLAN.md"
  - ".planning/phases/233-lookup-return-shapes/233-03-SUMMARY.md"
  - ".planning/phases/233-lookup-return-shapes/233-04-PLAN.md"
  - ".planning/phases/233-lookup-return-shapes/233-04-SUMMARY.md"
  - "CHANGELOG.md"
  - "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex"
  - "guides/code-walkthrough.md"
  - "guides/integration-contracts.md"
  - "lib/threadline.ex"
  - "lib/threadline/investigation.ex"
  - "lib/threadline/not_found_error.ex"
  - "lib/threadline/operator_surface/live/transaction_live.ex"
  - "lib/threadline/query/scope.ex"
  - "lib/threadline/query/transaction_lookup.ex"
  - "test/threadline/investigation_test.exs"
  - "test/threadline/lookup_return_shapes_contract_test.exs"
  - "test/threadline/not_found_error_test.exs"
  - "test/threadline/operator_surface/transaction_live_test.exs"
  - "test/threadline/public_surface_contract_test.exs"
  - "test/threadline/query/scope_fail_closed_test.exs"
  - "test/threadline/transaction_lookup_test.exs"
covered_digest: "v3:sha256:2bc33e8dea09f9464ddd26d844025e856ddfd2599c174cb188964957233a1b01"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 3/3 roadmap success criteria
  gaps_closed: []
  gaps_remaining: []
  regressions: []
  freshness_refresh:
    - "Re-ran Phase 233's seven-file focused contract/integration suite: 138 tests, 0 failures."
    - "Ran mix compile --warnings-as-errors and mix format --check-formatted; both exited 0."
    - "Rechecked current source, requirement mapping, artifact/key-link contracts, and decision coverage."
advisory: []
unverified_prohibition_count: 8
unverified_prohibition_note: "Eight unresolved judgment-tier clauses across four plans received non-authoritative read-only review. No current violation was observed; human review is recommended."
unverified_prohibitions:
  - group: "NotFoundError privacy and storage-schema error transparency (233-01; two clauses)"
    verdict: "unverified-prohibition — human review recommended"
    observation: "The exception message uses only resource and caller id; scoped and missing lookups share :not_found; storage-schema errors are not rescued. Tests and source support the stated intent."
    uncertainty: "These clauses are judgment-tier and have no independent test-tier enforcement declaration."
  - group: "Absence representation and operator-surface scope (233-02; two clauses)"
    verdict: "unverified-prohibition — human review recommended"
    observation: "A missing transaction maps to {:error, :not_found}; the operator LiveView call-site diff passes only the expected lookup options."
    uncertainty: "The judgment about limiting operator UI changes and absence semantics is not an independent test-tier prohibition gate."
  - group: "Deprecated return compatibility and API-scope boundaries (233-03; two clauses)"
    verdict: "unverified-prohibition — human review recommended"
    observation: "The deprecated Query API still returns row-or-nil and has parity coverage; no as_of!/4 export or Evidence lookup reshaping is present."
    uncertainty: "These are judgment-tier clauses; source and tests provide evidence but not a dedicated negative enforcement gate for every boundary."
  - group: "Fail-closed scope and error-message privacy (233-04; two clauses)"
    verdict: "unverified-prohibition — human review recommended"
    observation: "Scope.apply/2 raises for a non-nil scope without a valid callback and does not interpolate the scope value; the scoped-read matrix includes leak-safety assertions."
    uncertainty: "These clauses remain judgment-tier even though related positive behavior is covered by tests."
decision_coverage:
  honored: 22
  total: 22
  not_honored: []
human_verification: []
---

# Phase 233: Lookup Return Shapes — Verification Report

**Phase Goal:** An adopter handles a missing transaction the same way on every single-subject lookup: a tagged tuple by default and a raising `!` sibling when absence is a bug.
**Verified:** 2026-10-08T01:24:08Z
**Status:** passed, with 4 flagged judgment-tier prohibition groups (human review recommended)
**Evidence refresh:** Yes — the previous report passed with no gaps; this refresh independently checked current code and reran focused tests.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | `Threadline.audit_transaction/2` and `Threadline.transaction_context/2` return `{:ok, _}` for present rows and `{:error, :not_found}` for missing rows, matching `incident_bundle/2`; both cases are tested. | ✓ VERIFIED | `lib/threadline.ex:952-962` delegates the row lookup to `TransactionLookup.fetch_row/2` and maps `:not_found` to the tagged error; `lib/threadline/investigation.ex:172-188` and `:195-215` share `TransactionLookup.fetch/2`. The focused 138-test run passed; integration tests assert present and missing outcomes for all three plain lookups. |
| 2 | `audit_transaction!/2` and `transaction_context!/2` return bare values for present rows and raise `Threadline.NotFoundError` for absence; both cases are tested. | ✓ VERIFIED | `lib/threadline.ex:990-1001` and `:1066-1077` unwrap the plain result and raise `NotFoundError` only for `:not_found`. `test/threadline/transaction_lookup_test.exs` covers present/missing bang cases; `test/threadline/not_found_error_test.exs` checks exception message and Plug 404/actions. Focused tests passed. |
| 3 | Internal callers use the new return shapes, the Unreleased breaking-changes entry documents the migration, and the CI gate is green. | ✓ VERIFIED | Source search found no internal `Threadline.Query.audit_transaction/2` calls outside the deprecated implementation; production callers pattern-match the tuple or call the new facade. The Unreleased changelog documents the tuple, bang siblings, option restrictions, and required adopter actions. Local focused tests, warnings-as-errors compilation, and format check passed. The merged PR #80 record supplied by the orchestrator reports all 16 required CI checks green, including test/example/browser lanes. The local `mix ci.all` refresh reached the full suite but was environment-restricted by Git/Hex/npm cache writes; this does not contradict the merged CI result. |

**Score:** 3/3 roadmap truths verified (0 present, behavior-unverified).

### Autonomous Judgment-Tier Prohibition Review

The four plans contain eight unresolved `verification: judgment` prohibitions. This autonomous pass records non-authoritative, read-only findings: no current violation was observed, but the checks are not proof and human review is recommended. They remain prominent flags rather than being silently counted as test-backed evidence. No manual UAT is needed for this infrastructure/API phase.

| Group | Non-authoritative observation | Remaining uncertainty | Flag |
|---|---|---|---|
| NotFoundError privacy and storage-schema error transparency | Exception content is limited to resource and caller id; storage errors are not converted to absence. Related tests and code agree. | Judgment-tier wording has no dedicated test-tier prohibition enforcement. | unverified-prohibition — human review recommended |
| Absence representation and operator-surface scope | Missing rows use `:not_found`; the LiveView uses the facade with only allowed lookup options. | Limiting UI scope and interpreting absence remain judgment-tier. | unverified-prohibition — human review recommended |
| Deprecated return compatibility and API-scope boundaries | Deprecated query parity is tested; no `as_of!/4` export or evidence lookup reshaping was found. | No dedicated negative gate enforces each judgment boundary. | unverified-prohibition — human review recommended |
| Fail-closed scope and error-message privacy | Invalid scope configuration raises; the error avoids scope values; scoped-read tests include leak-safety assertions. | Plan clauses remain judgment-tier despite related positive test coverage. | unverified-prohibition — human review recommended |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/query/transaction_lookup.ex` | Shared row-first fetch and scope application | ✓ VERIFIED | `fetch_row/2`, `fetch/2`, and `scoped_row/4` perform real Ecto queries through the configured repo and fixed scope surfaces. The hidden fetch is used by the facade and investigation functions. |
| `lib/threadline/not_found_error.ex` | Public exception and Plug mapping | ✓ VERIFIED | Substantive exception module; message uses only resource and id; `Plug.Exception` maps to 404 with no actions. |
| `lib/threadline/query/scope.ex` | Fail-closed scope semantics | ✓ VERIFIED | Rejects non-nil scope without a callback and callbacks of wrong arity; nil scope remains explicitly unscoped. |
| `test/threadline/transaction_lookup_test.exs` and `test/threadline/investigation_test.exs` | Lookup result and error behavior | ✓ VERIFIED | Real Repo-backed integration assertions cover present, absent, malformed IDs, bang siblings, scope filtering, and zero-change transactions. |
| `test/threadline/not_found_error_test.exs` | Exception contract | ✓ VERIFIED | Checks exception struct/message and Plug status/actions. |
| `test/threadline/lookup_return_shapes_contract_test.exs` | Lookup-family public-doc/spec contract | ✓ VERIFIED | Contract enumerates the three lookups, their bangs, return specs/docs, and the `as_of/4` exemption. |
| `test/threadline/query/scope_fail_closed_test.exs` | Scoped-read failure matrix | ✓ VERIFIED | Active matrix exercises fail-closed behavior across query and operator surfaces, including sensitive error text. |
| `CHANGELOG.md`, guides, and example router | Adopter migration contract and current examples | ✓ VERIFIED | Breaking-change section is under Unreleased; guide and example call sites document/use the tuple and bang shapes. |

Artifact tooling returned 13/13 plan artifacts present and substantive. `verify.key-links` returned 7/7 declared links verified across four plans. Source inspection confirms those links are actual calls rather than name-only matches.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `Threadline.audit_transaction/2` | `TransactionLookup.fetch_row/2` | Facade call maps `:not_found` to `{:error, :not_found}` | WIRED | Direct implementation at `lib/threadline.ex:952-962`. |
| `TransactionLookup.fetch_row/2` | `Query.Scope.apply/2` | `Query.maybe_apply_scope` with `:transaction_header` and transaction id params | WIRED | Source path constructs and executes the scoped query. |
| Investigation lookups | `TransactionLookup.fetch/2` | `transaction_context/2` and `incident_bundle/2` use shared row-first fetch | WIRED | Direct calls at `lib/threadline/investigation.ex:178` and `:201`. |
| `TransactionLookup.fetch/2` | Changes query | Applies scope with `surface: :transaction`, then executes `repo.all/1` and associates the fetched row | WIRED | Real database query; no static fallback. |
| Deprecated `Query.audit_transaction/2` | `TransactionLookup.scoped_row/4` | Preserves row-or-nil behavior via shared scoped query | WIRED | Parity contract and source call are present. |
| `TransactionLive` | `Threadline.incident_bundle/2` | Mount uses facade and consumes tagged result | WIRED | Caller no longer passes reserved `:surface`/`:params` options. |
| Public lookup docs/specs | `lookup_return_shapes_contract_test.exs` | Compiled docs and typespecs checked via `Code.fetch_docs/1` and Typespec APIs | WIRED | Contract test reads compiled module metadata. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces real data | Status |
|---|---|---|---|---|
| `Threadline.audit_transaction/2` | Audit transaction row | Ecto query through caller's Repo and configured storage schema | Yes; fetched row is returned/hydrated, not a literal fallback | ✓ FLOWING |
| `transaction_context/2` / `incident_bundle/2` | Row and visible changes | Shared row query plus scoped changes query through Repo | Yes; changes are selected, ordered, and returned with the hydrated transaction | ✓ FLOWING |
| `TransactionLive` | Incident bundle/not-found state | Facade result branch | Yes; renders the actual lookup result | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Present/missing plain lookups, bangs, scope behavior, docs contract, exception, LiveView and deprecation parity | `mix test test/threadline/not_found_error_test.exs test/threadline/lookup_return_shapes_contract_test.exs test/threadline/query/scope_fail_closed_test.exs test/threadline/transaction_lookup_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/deprecation_parity_test.exs` | 138 tests, 0 failures | ✓ PASS |
| Warning-free compile | `mix compile --warnings-as-errors` | Exit 0 | ✓ PASS |
| Formatting | `mix format --check-formatted` | Exit 0 | ✓ PASS |
| Merged release-distribution CI | PR #80 merge SHA `edb5138f350f7719778b01a9a85fba49391df32f` | Orchestrator reports 16 required checks green | ✓ PASS |

### Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion strength | Verdict |
|---|---|---:|---:|---|---|---|
| `transaction_lookup_test.exs` | API-06 | Yes | No linked tests found disabled | No expected values generated by the implementation | Value and multi-step behavior | ✓ PASS |
| `investigation_test.exs` | API-06 | Yes | No linked tests found disabled | No | Value and integration behavior | ✓ PASS |
| `not_found_error_test.exs` | API-06 | Yes | No linked tests found disabled | No | Exact message and status values | ✓ PASS |
| `lookup_return_shapes_contract_test.exs` | API-06 | Yes | No linked tests found disabled | No | Public docs/spec inventory and drift assertions | ✓ PASS |
| `scope_fail_closed_test.exs` | API-06 | Yes | No linked tests found disabled | No | Error/scope behavior across call surfaces | ✓ PASS |
| `operator_surface/transaction_live_test.exs` | API-06 | Yes | No linked tests found disabled | No | LiveView outcome | ✓ PASS |

No circular expected-value generation or insufficient API-06 assertions were found in the linked tests.

### Decision Coverage

The decision-coverage gate reports all trackable CONTEXT decisions honored: **22/22**, with no unhonored entries.

### Probe Execution

Not applicable. Phase 233 is an API/code phase; no plan or success criterion declares a probe, and it is not a migration/tooling phase.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| API-06 | 233-01 through 233-04 | Single-subject transaction lookups share tuple results and raising `!` siblings, with present/missing cases tested | ✓ SATISFIED | All three roadmap criteria verified; four plans declare API-06 and no additional Phase 233 requirement is mapped in `.planning/REQUIREMENTS.md`. |

### Anti-Patterns Found

No blocker debt markers, placeholder implementations, or orphaned lookup artifacts found in the changed source, test, guide, or example files. The previous code-review warning WR-01 (malformed id is resolved before checking `:repo`) remains a narrow API-error precedence concern; it does not contradict API-06's documented malformed-binary result or the roadmap criteria. No new defect was reproduced in the focused run.

### Human Verification Required

None. This is an autonomous infrastructure/API phase with no user-facing runtime flow requiring manual UAT. The four judgment-tier groups above remain explicitly flagged as **unverified-prohibition — human review recommended**; the read-only findings are non-authoritative and are not counted as test-backed proof.

### Gaps Summary

No blocking gaps. The current implementation, integration tests, docs contract, and caller migration satisfy all three roadmap success criteria. The focused suite passed 138 tests; warnings-as-errors compilation and formatting passed. Merged PR #80 CI was reported green. Eight plan prohibitions remain flagged for recommended human review but do not block this autonomous closeout.

---

_Verified: 2026-10-08T01:24:08Z_
_Verifier: the agent (gsd-verifier)_
