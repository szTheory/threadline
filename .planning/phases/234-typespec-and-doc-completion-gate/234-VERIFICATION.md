---
phase: 234-typespec-and-doc-completion-gate
verified: 2026-10-06T16:35:48Z
status: gaps_found
score: 6/8 must-haves verified
covered_files:
  - .planning/phases/234-typespec-and-doc-completion-gate/234-01-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-01-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-02-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-02-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-03-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-03-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-04-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-04-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-05-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-05-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-06-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-06-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-07-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-07-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-08-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-08-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-09-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-09-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-10-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-10-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-11-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-11-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-12-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-12-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-13-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-13-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-14-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-14-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-15-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-15-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-16-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-16-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-17-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-17-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-18-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-18-SUMMARY.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-19-PLAN.md
  - .planning/phases/234-typespec-and-doc-completion-gate/234-19-SUMMARY.md
  - lib/mix/tasks/critic.measure.ex
  - lib/threadline.ex
  - lib/threadline/audit.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/critic_trust/repository_boundary.ex
  - lib/threadline/evidence/subject.ex
  - lib/threadline/job.ex
  - lib/threadline/retention/policy.ex
  - lib/threadline/semantics/actor_ref.ex
  - lib/threadline/storage_schema.ex
  - test/threadline/capture_semantics_boundary_test.exs
  - test/threadline/doc_spec_coverage_contract_test.exs
  - test/threadline/facade_naming_contract_test.exs
  - test/threadline/job_test.exs
  - test/threadline/option_allowlist_test.exs
  - test/threadline/semantics/actor_ref_test.exs
covered_digest: "v3:sha256:3316cb8eb2b416b5f716735ae4aa9a7c7b299d7619bfa5b89ef48b63cde69cc2"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/6
  gaps_closed:
    - "D-28: no_return() is restricted to private raise-only helpers."
    - "Phase security sign-off has no open high-severity threats."
  gaps_remaining:
    - "Public specs, types, and documentation meet every applicable rule in the frozen Phase 234 rubric."
  regressions: []
gaps:
  - truth: "Public specs, types, and documentation meet every applicable rule in the frozen Phase 234 rubric."
    status: failed
    reason: "The fresh D-46 review reports PASS, but current source contradicts two public documentation claims: record_action/2's example builds an ActorRef with an unsupported string type, and Job.context_opts/2 says extra keys are validated even though record_action/2 drops unknown keys."
    artifacts:
      - path: lib/threadline.ex
        issue: "The example passes type: \"user\" to ActorRef, whose declared actor_type is an atom union and whose record_action validation rejects this value."
      - path: lib/threadline/job.ex
        issue: "The docs claim arbitrary extra option keys are validated by record_action/2; context_opts/2 retains them, while build_attrs/3 only consumes known keys."
    missing:
      - "Use ActorRef.new/2 in the record_action/2 example and show a successful validated actor."
      - "Correct context_opts/2's extra-key claim to describe the actual pass-through/ignored-key behavior, or implement and specify validation."
  - truth: "D-22/231 D-05: AuditTransaction's virtual action field is typed struct() | nil; capture-layer files do not reference AuditAction.t()."
    status: failed
    reason: "The explicit Plan 234-05 must-have remains false: current AuditTransaction.t references Threadline.Semantics.AuditAction.t() directly. The boundary test checks associations and virtual fields but does not assert this type-level layer boundary."
    artifacts:
      - path: lib/threadline/capture/audit_transaction.ex
        issue: "Line 63 declares action: Threadline.Semantics.AuditAction.t() | nil, contrary to the locked capture/semantics boundary and the Plan 05 artifact contract."
      - path: test/threadline/capture_semantics_boundary_test.exs
        issue: "Current assertions cover Ecto associations and fields, not the forbidden type reference."
    missing:
      - "Restore the specified generic struct() | nil capture-layer type and add an executable source/typespec boundary assertion."
deferred: []
behavior_unverified: 0
---

# Phase 234: Typespec and Doc Completion Gate — Verification Report

**Phase Goal:** Every public function an adopter can see has a `@doc` and an `@spec` that says something real. Coverage cannot regress, and the facade page reads by job rather than alphabetically.

**Verified:** 2026-10-06T16:35:48Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The live docs/spec coverage gate detects missing annotations and cannot regress below the locked non-vacuity floor. | ✓ VERIFIED | `test/threadline/doc_spec_coverage_contract_test.exs` inspects the live BEAM Docs and Typespec chunks, asserts no gaps, pins at least 50 documented modules and at least 82 visible function/macro entries, includes `Threadline.timeline/2`, and compares hidden entries to its exact pin. Plan 13's independent inventory measured 82 entries and 52 moduledocs; Plan 15 records fresh `mix ci.all` after the final implementation changes. |
| 2 | Public specs, types, and docs satisfy the frozen D-46 rubric and state real contracts. | ✗ FAILED | The current independent D-46 report is a hash-validated PASS, but source spot-checks find two false public doc claims: `Threadline.record_action/2`'s example passes `type: "user"`, while ActorRef accepts atom `:user` and the validator rejects the example; `Threadline.Job.context_opts/2` says extra keys are validated by `record_action/2`, but unknown keys are silently dropped by `build_attrs/3`. See gaps. |
| 3 | Strict Dialyzer is green with zero ignore entries. | ✓ VERIFIED | Plan 15's fresh `mix ci.all` records strict Dialyzer with 0 errors; the current `.dialyzer_ignore.exs` and ignore contract are included in the run and the review reports no public broad-type exception outside the rubric ledger. |
| 4 | Every visible `Threadline` facade function has one of the four job groups, and the facade page is ordered by those groups. | ✓ VERIFIED | `lib/threadline.ex` carries the group metadata; `test/threadline/facade_naming_contract_test.exs` asserts complete assignment and ordering. Plan 15's fresh full CI passed, and the Plan 13 review inventory includes the current facade entries. |
| 5 | D-28 allows `no_return()` only on private raise-only helpers. | ✓ VERIFIED | Current `RepositoryBoundary.task_error!/3` is `defp`; both `task_error!/3` helpers in the touched Mix task modules are private. The D-28 compiled probe and four-path test are recorded as passing in Plans 12 and 15; public bang specs found by source scan contain no `no_return()`. |
| 6 | Phase security sign-off has no open high-severity threats. | ✓ VERIFIED | `234-SECURITY.md` is `status: verified` with `threats_open: 0`; T-234-26 and the high-severity D-46/coverage/captured-data items are closed with linked evidence. T-234-08 and T-234-13 remain explicitly open at low severity, below the signed-off high-threat threshold. |
| 7 | AuditTransaction's virtual `action` field stays generic at the capture boundary and does not reference `AuditAction.t()`. | ✗ FAILED | Current `lib/threadline/capture/audit_transaction.ex:63` names `Threadline.Semantics.AuditAction.t()`. Plan 234-05 requires `struct() | nil`, and Plan 15 explicitly says to re-evaluate T-234-13 against this boundary. The current boundary test only checks associations/virtual fields and misses the type reference. |
| 8 | D-55's floor remains at least 82 visible function/macro entries and D-07's eight newly hidden helpers are unchanged. | ✓ VERIFIED | The live contract retains `assert length(checked) >= 82`; `@newly_hidden_keys` contains exactly the eight reviewed D-07 transitions (six StorageSchema helpers and two Evidence.Proof helpers), and the exact-set hidden pin is checked against current compiled Docs. The independent D-46 inventory measured 82 visible entries. |

**Score:** 6/8 must-haves verified (0 behavior-unverified)

### Re-verification

The earlier D-28 and security gaps are closed. The earlier SPEC-02 gap remains: the independent rubric PASS did not catch two concrete, current-source mismatches in public docs. The separate Plan 05 capture-layer type constraint also remains unmet.

### Deferred Items

None. No later phase's roadmap goal or success criterion explicitly covers these gaps.

### Advisory (New Scope, Unevidenced)

None. Phase 234 UI review findings concern existing operator-surface visuals and are unrelated to this docs/types goal. The current code-review report's row-history option and eager-export telemetry findings are noted below as non-blocking review warnings; they are outside the failed must-haves recorded here.

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/threadline/doc_spec_coverage_contract_test.exs` | Live BEAM docs/spec gate, >=82 floor, mutation control, hidden pin | VERIFIED | Source contains live Docs/Typespec inspection, missing-annotation assertion, >=82 floor, timeline sentinel, and exact 8-entry D-07 transition list checked against current hidden entries. |
| `test/threadline/facade_naming_contract_test.exs` | Complete four-group facade contract | VERIFIED | Present and substantive; validates all visible facade entries and ordering. |
| `lib/threadline/capture/audit_transaction.ex` | Hand-typed transaction struct with generic hydrated action field | FAILED | Substantive type exists, but `action` references `AuditAction.t()` contrary to the Plan 05 must-have. |
| `lib/threadline/critic_trust/repository_boundary.ex` | D-28 private raise helper | VERIFIED | `task_error!/3` is `defp`; the prior public `no_return()` gap is fixed. |
| `.planning/phases/234-typespec-and-doc-completion-gate/234-D46-REVIEW.md` | Independent frozen-rubric review | PRESENT; SOURCE SPOT-CHECK OVERRIDES | Report has one PASS and a current input-hash/inventory integrity check passes. Independent current-source spot-check nevertheless falsifies the two doc claims in truth 2. |
| `.planning/phases/234-typespec-and-doc-completion-gate/234-SECURITY.md` | Evidence-linked security sign-off | VERIFIED | `status: verified`; zero open high-severity threats. Two low-severity items remain explicitly open. |
| Plan 05 artifact `AuditTransaction.t` action shape | `struct() | nil`, no cross-layer type dependency | FAILED | `verify.artifacts` reports the old literal pattern `struct() | nil` missing; current source inspection confirms this is a real contract mismatch, not merely a stale checker pattern. |

Plan artifact checks: 60/61 passed across the 19 plans. Plan 05's one missing pattern is the current capture-layer type mismatch above. The plan key-link matcher reports expected false negatives for test and planning-document links because it searches for the target path inside the source file; the relevant source-to-test and report-evidence links were checked against live assertions and generated evidence. Separately, Plan 05's D-05 must-have fails on current source.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `Threadline.DocContract` | compiled Threadline modules | live `Code.fetch_docs/1` and `Code.Typespec.fetch_specs/1` inspection | WIRED | The regression test calls `DocContract.universe/0` and `gaps/3`; the suite result is included in Plan 15's fresh CI evidence. |
| `Threadline` facade | ExDoc groups | `@doc group:` metadata plus facade contract | WIRED | Current source has the four group names; the test checks every visible function and group ordering. |
| ActorRef/Subject/Retention contracts | compatibility tests | runtime alias normalization and mixed-key cases | WIRED | Current focused tests cover their documented input behavior; D-46's input-bound review inventories the current source and typedocs. |
| capture `AuditTransaction.action` type | semantics `AuditAction.t()` | public typespec reference | FAILED | The direct reference exists at `audit_transaction.ex:63` despite Plan 05 and the capture/semantics boundary requirement forbidding it. |
| D-46 reviewer | regenerated review input | SHA-256 plus complete surface inventory | WIRED | Re-ran Plan 13's exact report-integrity verifier; exit 0. It confirms report/input integrity, but does not prevent the current-source omissions identified in truth 2. |

## Data-Flow Trace (Level 4)

Not applicable. The deliverables are compile-time docs, typespecs, and gates; this phase adds no rendered data path.

## Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Regression gates after final implementation changes | Plan 15's recorded fresh `mix ci.all` | Root tests 3,006/0; example tests 130/0; strict Dialyzer 0 errors; Playwright 318 passed, 26 intentional skips | PASS (recorded evidence) |
| Coverage floor and hidden-entry ratchet | Current source assertions plus Plan 13 independent inventory | `>=82` sentinel, exact hidden-set comparison; 82 visible entries / 52 moduledocs | PASS |
| D-28 public/private boundary | Current source scan plus recorded compiled probe | Helpers private; no public bang `no_return()` spec | PASS |
| D-05 capture-layer type boundary | Current source inspection | `AuditAction.t()` reference is present in capture type | FAIL |

No new test suite was run in this verification turn; the supplied Plan 15 full-CI evidence is used for regression coverage, while the phase contract was independently checked against current source and tests.

## Probe Execution

Not applicable. The phase has no declared or conventional migration/tooling probe.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| SPEC-01 | 234-01 through 234-06, gap closures | Every visible public function has docs/specs; gate prevents regressions | SATISFIED | Live BEAM coverage gate, >=82 floor, mutation control, exact D-07 hidden pin, and post-change full CI evidence. |
| SPEC-02 | All plans; especially 234-05, 234-07 through 234-18 | Specs and docs give adopters real information and satisfy the frozen rubric | BLOCKED | Fresh D-46 PASS is hash-valid, but source contradicts the `record_action/2` example and `Job.context_opts/2` extra-key claim; capture type also violates Plan 05's boundary. |
| SPEC-03 | 234-01 through 234-06 and 234-15 | Every facade function is grouped by job | SATISFIED | Current group metadata, complete facade test, and recorded fresh full CI. |

No Phase 234 requirement is orphaned. `REQUIREMENTS.md` currently marks SPEC-02 Complete, which conflicts with the current-source findings; that status should be reopened only as part of the gap-closure decision/workflow.

## Test Quality Audit

| Test File | Linked Requirement | Active | Assertion strength | Verdict |
|---|---|---:|---|---|
| `test/threadline/doc_spec_coverage_contract_test.exs` | SPEC-01 | Yes | Live Docs/spec values, exact zero-gap and hidden-set assertions, mutation fixture | PASS |
| `test/threadline/facade_naming_contract_test.exs` | SPEC-03 | Yes | Exact visible membership and group ordering | PASS |
| `test/threadline/capture_semantics_boundary_test.exs` | SPEC-02 / D-05 | Yes | Checks schema association and virtual-field shape, but not typespec dependency | INSUFFICIENT for D-05 |
| `test/threadline/semantics/actor_ref_test.exs`, `test/threadline/job_test.exs` | SPEC-02 | Yes | Runtime inputs/outputs; no assertion that the public examples/docs agree | INSUFFICIENT for the two source mismatches |

The fresh full CI result is accepted as phase regression evidence per the verification handoff. The missing assertions above explain why green CI did not establish the remaining documentation and layer-boundary truths.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/threadline.ex` | 293 | Public success example supplies string `"user"` for atom-only `ActorRef.type` | BLOCKER | Copying the documented example produces an invalid actor and contradicts the claimed successful call. |
| `lib/threadline/job.ex` | 97 | Docs claim unknown extra keys are validated, but implementation only reads known keys | BLOCKER | Adopter-facing documentation describes behavior that does not occur. |
| `lib/threadline/capture/audit_transaction.ex` | 63 | Capture-layer type imports semantics-layer type | BLOCKER | Violates the explicit D-05 capture/semantics boundary and Plan 05 contract. |
| `lib/threadline/query/option_keys.ex` | 5–15 | `:row_history` rejects the prior `:surface` option | WARNING | Current code-review report flags compatibility/changelog impact. The phase plan intentionally closes the public allowlist for caller-controlled surface labels; no phase-gap attribution is made here. |
| `lib/threadline/export.ex` | 151–153 | Eager option validation precedes failure telemetry rescue | WARNING | Current code-review report flags telemetry behavior outside the must-haves closed by this verification. |

Debt-marker/stub scan across implementation and test files named in all phase summaries found no unreferenced `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, or empty implementation pattern.

## Advisory (New Scope, Unevidenced)

None. The code-review warnings above are recorded as warnings; they do not add unverified blockers to the carried-forward contract. The UI review's color, typography, and stress-demo findings concern pre-existing operator-surface presentation and are outside Phase 234's typespec/documentation goal.

## Human Verification Required

None. This is a documentation/typespec foundation phase; the failures are deterministically visible in source and do not require manual UAT.

## Gaps Summary

The D-28 helper visibility issue and security sign-off gap are closed. Coverage, the >=82 D-55 floor, D-07's eight hidden-helper transitions, strict Dialyzer, and facade grouping are supported by current source and the fresh recorded CI run. Phase 234 is still incomplete: the public `record_action/2` example and `Job.context_opts/2` documentation contradict runtime behavior, and `AuditTransaction.t` crosses the locked capture-to-semantics type boundary. These are two grouped SPEC-02/D-05 closure items; correct the docs and type boundary, add narrow contract assertions, then rerun the focused gates, strict Dialyzer/docs, fresh `mix ci.all`, and phase verification.

---

_Verified: 2026-10-06T16:35:48Z_
_Verifier: the agent (gsd-verifier)_
