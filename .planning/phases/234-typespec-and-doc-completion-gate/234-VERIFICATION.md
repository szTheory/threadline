---
phase: 234-typespec-and-doc-completion-gate
verified: 2026-10-05T17:23:26Z
status: gaps_found
score: 3/6 must-haves verified
next_action: "Gaps found. Plan the fixes, then re-run execute-phase before shipping."
next_command: "$gsd-plan-phase 234 --gaps"
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
  - lib/mix/tasks/threadline.gen.row_history_index.ex
  - lib/mix/tasks/threadline.incident.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/threadline.ex
  - lib/threadline/audit.ex
  - lib/threadline/capture/audit_change.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/change_diff.ex
  - lib/threadline/continuity.ex
  - lib/threadline/critic_trust/ledger_splice.ex
  - lib/threadline/evidence.ex
  - lib/threadline/evidence/proof.ex
  - lib/threadline/evidence/subject.ex
  - lib/threadline/export.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/export_queue.ex
  - lib/threadline/export_queue/task_adapter.ex
  - lib/threadline/governance/evidence_record.ex
  - lib/threadline/health.ex
  - lib/threadline/health/finding.ex
  - lib/threadline/health/legacy_key_findings.ex
  - lib/threadline/health/policy.ex
  - lib/threadline/health/trigger_findings.ex
  - lib/threadline/integrations/sigra.ex
  - lib/threadline/investigation.ex
  - lib/threadline/investigation/incident_bundle.ex
  - lib/threadline/investigation/linked_change.ex
  - lib/threadline/job.ex
  - lib/threadline/not_found_error.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/controllers/export_controller.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/row_history_component.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/page.ex
  - lib/threadline/query.ex
  - lib/threadline/query/cursors.ex
  - lib/threadline/query/export_reads.ex
  - lib/threadline/query/option_keys.ex
  - lib/threadline/query/transaction_lookup.ex
  - lib/threadline/retention.ex
  - lib/threadline/retention/policy.ex
  - lib/threadline/semantics/actor_ref.ex
  - lib/threadline/semantics/audit_action.ex
  - lib/threadline/semantics/audit_context.ex
  - lib/threadline/storage.ex
  - lib/threadline/storage/s3.ex
  - lib/threadline/storage_schema.ex
  - lib/threadline/telemetry.ex
  - lib/threadline/verify/coverage_policy.ex
covered_digest: "v2:sha256:00318001477f679d3bfb7c0641d0c10939f701ab38be7440df4a9f10ea493301"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Public specs, types, and documentation meet every applicable rule in the frozen Phase 234 rubric."
    status: failed
    reason: "The independent D-46 review verdict is FAIL. Two blocking type-contract findings and five rubric warnings remain; current source spot-checks confirm the validator inputs, broad map types, and captured-data documentation findings."
    artifacts:
      - path: .planning/phases/234-typespec-and-doc-completion-gate/234-D46-REVIEW.md
        issue: "WR-01 and WR-02 are blockers; WR-03 through WR-07 remain warnings. The review covers 226 visible entries, 52 moduledocs, and 8 public behavior callbacks."
    missing:
      - "WR-01: widen ActorRef.new/2 and Evidence.Subject.validate/1 and supported?/1 inputs to reflect values the validators and predicate actually accept; keep successful outputs narrowed and preserve rejected values in error results."
      - "WR-02: express the finite key/value contracts for ActorRef.actor_map/0, Evidence.Subject.subject_descriptor/0, and Retention.Policy.config_map/0 in valid Elixir typespecs, with typedocs matching guaranteed runtime keys."
      - "WR-03: add named, documented adapter-defined option and opaque adapter error types for Threadline.Storage and Threadline.ExportQueue callbacks; make each callback summary state complete success and error return shapes."
      - "WR-04: add the prescribed captured-column-values and authorization note to actor/correlation reads, as_of/4, transaction-context reads, audit_changes_for_transaction/2, ChangeDiff, and the history/row-history family."
      - "WR-05: name return shapes in first-paragraph summaries for Audit.transaction/3, record_action/2, Retention.purge/1, validators, and Continuity.assert_capture_ready!/2; document the missing-:repo KeyError on both Continuity helpers."
      - "WR-06: name ActorRef.new/2, from_map/1, identifiable?/1, and to_map/1 in the ActorRef moduledoc."
      - "WR-07: rewrite the listed touched moduledoc opening fragments as complete declarative domain summaries."
  - truth: "D-28 holds: no_return() appears only on private raise-only helpers, never on a public bang function."
    status: failed
    reason: "The exported Threadline.CriticTrust.RepositoryBoundary.task_error!/3 still has a no_return() spec and a public def. A focused contract probe failed once with [task_error!: 3]; the implementation file was outside Plan 234-06's amended scope."
    artifacts:
      - path: lib/threadline/critic_trust/repository_boundary.ex
        issue: "The spec at line 258 returns no_return(), and task_error!/3 is defined with def at line 259."
    missing:
      - "Resolve the exported bang helper's public/private boundary in scope, then re-run the D-28 focused contract probe and strict Dialyzer."
  - truth: "Phase 234 security review has no open high-severity threats and is signed off."
    status: partial
    reason: "234-SECURITY.md remains status: draft with threats_open: 1 and pending sign-off. Its T-234-01 high threat is still marked open; the D-46 captured-data omissions also leave T-234-06 open below the blocking threshold."
    artifacts:
      - path: .planning/phases/234-typespec-and-doc-completion-gate/234-SECURITY.md
        issue: "Security sign-off is incomplete; the threat ledger has not been reconciled to the completed gate evidence and D-46 findings."
    missing:
      - "Reconcile each open threat against current evidence and D-46 closure, then set the security artifact to verified with threats_open: 0 only when warranted."
decision_coverage:
  honored: 53
  total: 53
  not_honored: []
---

# Phase 234: Typespec and Doc Completion Gate — Verification

**Phase Goal:** Every public function an adopter can see has a `@doc` and an `@spec` that says something real. Coverage cannot regress, and the facade page reads by job rather than alphabetically.

**Verified:** 2026-10-05T17:23:26Z  
**Status:** gaps_found  
**Re-verification:** No previous verification report existed.

## Goal Achievement

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Every documented public function has a doc and spec; the coverage gate detects regressions. | VERIFIED | Ran the six central gate suites: 70 tests, 0 failures, 1 excluded. `doc_spec_coverage_contract_test.exs` exercises the live BEAM docs/spec universe and zero-gap ratchet. The phase's recorded `mix ci.all` also passed with 2,986 root tests and 130 example tests. |
| 2 | Public types/specs give adopters real information and pass the frozen rubric review. | FAILED | The fresh independent `234-D46-REVIEW.md` verdict is FAIL. It identifies blockers WR-01/WR-02 and warnings WR-03–WR-07. Current source confirms `ActorRef.new/2` accepts unsupported runtime inputs while its spec only accepts `actor_type()`, `Evidence.Subject.validate/1` and `supported?/1` have similarly narrow inputs, and map aliases admit broader key sets than their finite documented contracts. Captured-data notes and callback return summaries also remain incomplete. |
| 3 | Strict Dialyzer is green with zero ignore entries. | VERIFIED | Current `mix verify.dialyzer`: `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`. The central ignore/slice contract suites passed. |
| 4 | Every visible Threadline facade function belongs to one of the four required ExDoc groups. | VERIFIED | `facade_naming_contract_test.exs` passed as part of the 70-test gate run; `MIX_ENV=dev mix docs --warnings-as-errors` rebuilt the docs successfully. The test pins full membership and group ordering. |
| 5 | D-28 permits `no_return()` only on private raise-only helpers. | FAILED | `RepositoryBoundary.task_error!/3` is still exported (`def`) with `@spec ... :: no_return()` at `lib/threadline/critic_trust/repository_boundary.ex:258-259`. The validation audit records a focused contract probe failure for `[task_error!: 3]`. |
| 6 | The phase security gate is closed with no open high threats. | FAILED | `234-SECURITY.md` remains `status: draft`, `threats_open: 1`, and sign-off pending. T-234-01 is marked high/open; T-234-06 remains open for captured-data documentation omissions. |

**Score:** 3/6 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/threadline/doc_spec_coverage_contract_test.exs` | Zero-gap docs/spec regression gate with live BEAM inspection and mutation control | VERIFIED | Present, substantive; passed in current central suite. |
| `test/threadline/doc_rubric_contract_test.exs` | Mechanized rubric checks for types, docs, parity, and style | VERIFIED | Present, substantive; passed in current central suite. |
| `test/threadline/dialyzer_ignore_contract_test.exs` | Exact strict warning configuration and suppression prohibitions | VERIFIED | Passed in current central suite; `mix verify.dialyzer` reports zero errors. |
| `test/threadline/facade_naming_contract_test.exs` | Four facade groups and complete assignment | VERIFIED | Passed in current central suite; docs build succeeded. |
| `.planning/phases/234-typespec-and-doc-completion-gate/234-SPEC-RUBRIC.md` | Frozen D-46 reviewer standard | VERIFIED | Exists and is headed “Frozen at plan 234-01”; D-46 reports reading it and applying it across the generated surface. |
| `.planning/phases/234-typespec-and-doc-completion-gate/234-D46-REVIEW.md` | Independent review against the frozen rubric | FAILED | Complete review exists, but verdict FAIL and seven unresolved findings. |
| `lib/threadline/critic_trust/repository_boundary.ex` | D-28 no-return boundary | FAILED | Exported bang helper has `no_return()` spec. |
| `.planning/phases/234-typespec-and-doc-completion-gate/234-SECURITY.md` | Threat register closed and security sign-off recorded | FAILED | Draft, one high-severity open threat, sign-off pending. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|
| `doc_spec_coverage_contract_test.exs` | compiled `lib/` modules | `Code.fetch_docs/1` and `Code.Typespec.fetch_specs/1` | WIRED | Current live gate passed; its ratchet covers every visible documented module. |
| `facade_naming_contract_test.exs` | `Threadline` facade docs | `@doc group:` metadata and ExDoc output | WIRED | Gate passed; docs rebuilt without warnings. |
| `234-D46-REVIEW.md` | `234-SPEC-RUBRIC.md` + current source | independent per-entry review | WIRED, FAIL | Reviewer checked 226 generated entries, 52 moduledocs, and 8 public callbacks; several items fail the frozen rubric. |

## Data-Flow Trace (Level 4)

Not applicable: this phase's remaining contract concerns are static documentation and typespec claims. Its outputs do not render dynamic user data or add a runtime data path. Runtime scope/option behavior remains covered by the existing focused tests and full phase CI run.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Docs/spec live coverage, rubric, facade grouping, Dialyzer suppression, sealed slice, and facade size gates | `mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/facade_naming_contract_test.exs test/threadline/dialyzer_ignore_contract_test.exs test/threadline/dialyzer_slice_contract_test.exs test/threadline/source_size_contract_test.exs` | 70 tests, 0 failures, 1 excluded | PASS |
| Strict Dialyzer | `mix verify.dialyzer` | 0 errors, 0 skipped | PASS |
| Published documentation build | `MIX_ENV=dev mix docs --warnings-as-errors` | exit 0, generated HTML/Markdown/EPUB | PASS |
| D-28 exported bang-function prohibition | Focused contract probe recorded in `234-VALIDATION.md` | 1 test, 1 failure: `[task_error!: 3]` | FAIL |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| SPEC-01 | 234-01 through 234-06 | Every visible documented public function has a doc and spec, guarded against regression | SATISFIED | Current live coverage gate passed; requirements file marks complete. |
| SPEC-02 | 234-01 through 234-06 | Specs provide meaningful contracts and satisfy the frozen rubric | BLOCKED | D-46 verdict FAIL with WR-01/WR-02 blockers and WR-03–WR-07 warnings; D-28 also remains unresolved. Requirement remains pending in REQUIREMENTS.md. |
| SPEC-03 | 234-01, 234-02, 234-06 | Facade functions are grouped by job | SATISFIED | Current facade-group contract test passed and docs build succeeded; requirements file marks complete. |

No requirement mapped to Phase 234 is orphaned. The roadmap's later phases cover stability/adopter guides, support floor, and upgrade/release work; none explicitly accepts or closes the current D-46 or D-28 gaps, so they are not deferred.

## Decision Coverage

All trackable CONTEXT.md decisions are honored: 53/53 (`check.decision-coverage-verify`).

## Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---:|---|---|
| `doc_spec_coverage_contract_test.exs` | SPEC-01 | Yes | 0 in file | No circular expected-value generation found | Behavioral contract + exact live value set | PASS |
| `doc_rubric_contract_test.exs` | SPEC-02 | Yes | 0 in file | No circular expected-value generation found | Value-level rubric assertions | PASS as a gate; its scope does not enforce the omitted prose/type cases listed by D-46 |
| `facade_naming_contract_test.exs` | SPEC-03 | Yes | 0 in file | No circular expected-value generation found | Exact facade groups and ordering | PASS |
| `dialyzer_ignore_contract_test.exs`, `dialyzer_slice_contract_test.exs` | SPEC-02 | Yes | 0 in file | Not applicable | Configuration and live warning checks | PASS |

**Disabled tests on requirements:** none found in the central gate files.  
**Circular patterns detected:** none found.  
**Insufficient assertions:** the automated rubric tests do not establish D-46 prose informativeness; the independent reviewer supplied the missing judgment evidence and found the remaining gaps.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/threadline/critic_trust/repository_boundary.ex` | 258–259 | Exported bang helper specified as `no_return()` | BLOCKER | Violates explicit D-28 prohibition. |
| `lib/threadline/semantics/actor_ref.ex` | 30–31, 44–45 | Broad string-key map alias; validator input narrower than runtime | BLOCKER | D-46 WR-01/WR-02. |
| `lib/threadline/evidence/subject.ex` | 19–27, 36–45 | Broad descriptor map and validator/predicate inputs narrower than runtime | BLOCKER | D-46 WR-01/WR-02. |
| `lib/threadline/retention/policy.ex` | 30–34 | Generic atom/string keys merge fields with distinct constraints | BLOCKER | D-46 WR-02. |
| `lib/threadline/storage.ex`, `lib/threadline/export_queue.ex` | callbacks | Bare callback `term()` errors and/or bare `keyword()` adapter inputs; incomplete opening return summaries | WARNING | D-46 WR-03. |
| `lib/threadline.ex`, `lib/threadline/change_diff.ex` | captured-read docs | Missing/weak captured-column and authorization notes; several first-paragraph return gaps | WARNING | D-46 WR-04/WR-05. |
| `lib/threadline/semantics/actor_ref.ex` | 1–19 | Moduledoc does not name its four public entry points | WARNING | D-46 WR-06. |
| D-46-listed touched moduledocs | See review matrix | Opening summaries are fragments rather than declarative sentences | WARNING | D-46 WR-07. |

## Human Verification Required

None. The project sets zero human verification by default; prose/type quality was assigned to the independent D-46 agent review, which has completed and returned a failed verdict. The remaining work is concrete code, docs, and gate closure.

## Gaps Summary

Phase 234's coverage and grouping outcomes are implemented and their live gates pass. The phase is not complete: independent review found two blocking type-contract defects and five doc-rubric warnings; the D-28 exported `no_return()` exception remains; and the security artifact still has an open high threat and pending sign-off. SPEC-02 remains pending. The required next step is a focused gaps plan that includes the D-46 corrections and explicit D-28/security closure work; no later roadmap phase names these as deferred work.

## Canonical GSD Routing

- **Next action:** Gaps found. Plan the fixes, then re-run execute-phase before shipping.
- **Next command:** `$gsd-plan-phase 234 --gaps`

---

_Verified: 2026-10-05T17:23:26Z_  
_Verifier: the agent (gsd-verifier)_
