---
phase: 234-typespec-and-doc-completion-gate
plan: 03
subsystem: api
tags: [elixir, typespecs, ex_doc, dialyzer, evidence]
requires:
  - phase: 234
    provides: Exact documentation/specification ratchets and frozen rubric
provides:
  - Fully typed EvidenceRecord schema and documented Evidence read/write APIs
  - Evidence filter-key parity and default-argument read APIs
  - Documented Proof entry points and recorded hidden helper breaking change
affects: [234-04, 234-05, 234-06, 235]
actuals:
  tasks: 3
  commits: 2
tech-stack:
  added: []
  patterns:
    - Schema-backed evidence uses a complete hand-written struct type rather than term fields
    - Filter-key parity is exposed through a hidden module helper backed by existing allowlists
key-files:
  created:
    - .planning/phases/234-typespec-and-doc-completion-gate/234-03-SUMMARY.md
  modified:
    - lib/threadline/evidence.ex
    - lib/threadline/evidence/proof.ex
    - lib/threadline/evidence/subject.ex
    - lib/threadline/governance/evidence_record.ex
    - CHANGELOG.md
    - test/threadline/doc_spec_coverage_contract_test.exs
    - test/threadline/doc_rubric_contract_test.exs
key-decisions:
  - "Keep Evidence options open where runtime validation is open, while checking validated filters against existing allowlists."
  - "Hide only Proof.present_record/1 and record_claim_assessment/1; retain their specs and callable implementations."
  - "Combine Tasks 2 and 3 in one commit so the BREAKING CHANGE footer accompanies the hidden helpers."
requirements-completed: [SPEC-01, SPEC-02]
coverage:
  - id: EVIDENCE-CONTRACTS
    description: "Evidence and Evidence.Subject entry points have named types, informative docs, and matching filter contracts."
    requirement: SPEC-01
    verification:
      - kind: unit
        ref: "mix test test/threadline/evidence_test.exs test/threadline/evidence test/threadline/evidence_cli_doc_contract_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs"
        status: pass
      - kind: other
        ref: "mix verify.example; mix verify.credo; mix verify.dialyzer"
        status: pass
    human_judgment: false
  - id: PROOF-DOCS-AND-BREAKING-CHANGE
    description: "Four Proof entry points are documented and typed; two internal helpers are hidden and named in the Unreleased breaking-change record."
    requirement: SPEC-01
    verification:
      - kind: unit
        ref: "mix test test/threadline/evidence/proof_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/public_surface_contract_test.exs"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors; mix compile --warnings-as-errors; mix verify.format; mix verify.dialyzer"
        status: pass
    human_judgment: false
  - id: EVIDENCE-RECORD-TYPE
    description: "EvidenceRecord.t() covers every schema field with concrete field types."
    requirement: SPEC-02
    verification:
      - kind: other
        ref: "mix verify.dialyzer (0 errors)"
        status: pass
    human_judgment: false
duration: not recorded
completed: 2026-10-04
status: complete
---

# Phase 234 Plan 03: Evidence API Contracts

**Evidence records and reads now have named, rubric-checked types and docs, while two internal Proof helpers leave the documented API.**

## Accomplishments

- Added a complete `EvidenceRecord.t()` listing all schema fields and typed the redaction-policy writer against its actual return shape.
- Added named Evidence attrs, filter, and option types; documented and typed all Evidence entry points; exposed `__filter_keys__/1` over existing runtime allowlists.
- Collapsed the equivalent subject-reference read arities into default-argument definitions and documented `Evidence.Subject.supported_subjects/0`.
- Documented the four Proof entry points and marked only `present_record/1` and `record_claim_assessment/1` as undocumented helpers. Added their grouped Unreleased breaking-change note.
- Removed fixed coverage/rubric pins and updated the gate's coverage counts and visible threshold.

## Task Commits

1. **Task 1: Type and document the redaction evidence writer** — `a7b2efad`
2. **Tasks 2 and 3: Evidence/Proof contracts and grouped breaking-change record** — `bc404584`

The second commit combines Tasks 2 and 3 so the commit hiding the two helpers carries the required `BREAKING CHANGE:` footer.

## Verification

- Focused Evidence, CLI, docs-contract, and rubric tests: 47 tests, 0 failures.
- Proof, docs-contract, changelog, and public-surface tests: 78 tests, 0 failures.
- `mix verify.example`: 130 tests, 0 failures.
- `mix verify.credo`: passed.
- `MIX_ENV=dev mix docs --warnings-as-errors`: passed.
- `mix compile --warnings-as-errors`: passed.
- `mix verify.format`: passed.
- `mix verify.dialyzer`: 0 errors.
- Grep-before-hide check found no guide, README, or example references to either hidden helper.

## Deviations from Plan

### Auto-fixed Issues

**1. Scoped the unknown-key rubric assertion to its own documentation heading.**
- **Found during:** Tasks 2 and 3 rubric verification.
- **Issue:** The checker searched the whole function doc and treated a filter rule as an option rule for APIs with filters and open-ended options.
- **Fix:** Scoped the assertion to the `Unknown keys raise` section so it evaluates the intended option contract.
- **Files modified:** `test/threadline/doc_rubric_contract_test.exs`.
- **Verification:** Focused rubric tests and the Evidence/Proof contract suites passed.
- **Committed in:** `bc404584`.

**Total deviations:** 1 auto-fixed checker correction.
**Impact on plan:** The rubric now distinguishes validated filters from open options without changing the intended Evidence API.

## Issues Encountered

The example-app suite emitted two existing shape-fixture migration redefinition warnings after its 130 tests passed; it exited successfully. No implementation or verification failure remained.

## User Setup Required

None.

## Next Plan Readiness

Ready for `234-04-PLAN.md`; the Evidence family now meets the phase's documentation and typespec gate. Plans 234-04 through 234-06 remain.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-04*
