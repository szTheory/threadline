---
phase: 234-typespec-and-doc-completion-gate
plan: 22
subsystem: api
tags: [elixir, typespecs, telemetry, ex-doc, dialyzer]
status: complete

requires:
  - phase: 234-typespec-and-doc-completion-gate
    provides: Public API contracts, D-56 string-key map exception, and D-07 eager export telemetry boundary
provides:
  - Job context inputs and outputs agree at runtime and in compiled public types
  - Eager export validation errors emit one documented failure event and preserve the original exception
  - Fresh independent D-46 PASS bound to the regenerated current-source review input
affects: [SPEC-02, phase-234-api-docs]

actuals:
  tokens: 11938
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - Runtime job context validation and named public result types share one bounded option domain.
    - Eager validation failures emit telemetry before preserving and reraising the original exception.
    - D-56 string-key map types admit arbitrary ignored values where runtime accepts them.

key-files:
  created:
    - .planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW-INPUT.md
    - .planning/phases/234-typespec-and-doc-completion-gate/234-D46-REVIEW.md
  modified:
    - lib/threadline/job.ex
    - lib/threadline/export.ex
    - lib/threadline/telemetry.ex
    - lib/threadline/retention/policy.ex
    - guides/integration-contracts.md
    - guides/telemetry.md
    - .planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW-DISPOSITION.md
    - .planning/phases/234-typespec-and-doc-completion-gate/deferred-items.md

key-decisions:
  - "Keep SPEC-02 Pending until phase re-verification passes."
  - "Preserve D-55's 82-entry floor and D-07's exact eight hidden pins."
  - "Apply the narrow D-56 string-key value correction found by independent review."

requirements-completed: []
coverage:
  - id: D1
    description: Job context validation, normalized IDs, and compiled public types agree.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: test/threadline/job_test.exs and test/threadline/semantics/audit_action_test.exs
        status: pass
      - kind: other
        ref: mix verify.dialyzer
        status: pass
    human_judgment: false
  - id: D2
    description: Eager facade and direct export validation failures emit one documented failure event.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: test/threadline/export_test.exs and test/threadline/telemetry_doc_contract_test.exs
        status: pass
      - kind: other
        ref: mix ci.all
        status: pass
    human_judgment: false
  - id: D3
    description: Current public docs and types pass a fresh independent D-46 review.
    requirement: SPEC-02
    verification:
      - kind: other
        ref: .planning/phases/234-typespec-and-doc-completion-gate/234-D46-REVIEW.md and Plan 13 report-integrity verifier
        status: pass
    human_judgment: false

commits: 4
plan_head_before: 3c22d3fddbe963e76a424b78c46b5c9d250e2e09
plan_head_after: 59bd1d69463ff27a4cabd25686a4b0bee2bc5474
duration: 30min
completed: 2026-10-06
---

# Phase 234 Plan 22: Current-Surface Contract Gap Closure Summary

**Job ID types and validation now match runtime behavior, eager export validation emits one safe failure event, and fresh D-46 review passes against current source.**

## Accomplishments

- Normalized integer job and correlation IDs, rejected malformed IDs and unsupported extras, and aligned `Job.context_opts/2` runtime values with its compiled public types.
- Added exactly-once `:failed` telemetry for eager facade and direct Export validation raises while preserving the original exception. Updated both public telemetry tables and the registry description.
- Regenerated the current-source review dump and obtained a fresh independent D-46 PASS. The report is bound to SHA-256 `37b2d18cf85a0a5b391c9ff44e12c51791b3874f14df5e338f5ecb3fc735345e`, with 82 visible entries, 52 moduledocs, 149 public types, and 8 public callbacks.
- Fixed the D-56 retention string-key type mismatch found during independent review: unknown string-key values are accepted by the public map type as runtime already permits. Added a compiled-type contract assertion.
- Kept SPEC-02 Pending for phase re-verification; Phase 234 remains In Progress.

## Task Commits

1. Task 1 — normalize and validate job context IDs: `0ea306bf`.
2. Task 2 — emit telemetry for eager export validation failures: `8fb37232`.
3. Task 3 — align eager export telemetry contract: `9db8275b`.
4. Independent-review D-56 correction: `59bd1d69`.

## Verification

- Focused job, action, export, telemetry, rubric, and coverage checks passed as recorded during task execution; the final D-56 correction checks passed with 29 tests and 0 failures.
- Fresh reviewer checks passed with 127 tests and 0 failures.
- `mix verify.dialyzer` — 0 errors, 0 skipped, 0 unnecessary skips.
- `MIX_ENV=dev mix docs --warnings-as-errors` — passed.
- `GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null mix ci.all` — passed: 3,016 root tests (0 failures, 3 excluded), 130 example tests (0 failures), strict Dialyzer (0 errors), live Dialyzer (17 tests, 0 failures), npm audit (0 vulnerabilities), and Playwright (318 passed, 26 skipped).
- Root Git clone contract — 9/9 passed under the same Git-config isolation.
- Plan 13 current-input D-46 integrity verifier — passed, including sole PASS, exact input hash, independent reviewer identity, inventory, and all seven evidence-backed dispositions.
- D-55 remains at 82 visible entries; D-07 retains its exact eight hidden pins.

## Code Review Disposition

The three warnings in `234-REVIEW.md` are fixed and recorded separately from the earlier and fresh D-46 WR-01 through WR-07 findings in `234-REVIEW-DISPOSITION.md`:

- Code-review WR-01 and WR-02: fixed in `0ea306bf`, with runtime and compiled-type assertions.
- Code-review WR-03: fixed in `8fb37232` and documented in `9db8275b`; export event tests and canonical CI pass.

## Deviation from Plan

**[Rule 1 - Bug] Aligned the D-56 retention config map type with ignored runtime values.**

- **Found during:** Task 3 independent D-46 review.
- **Issue:** The public string-key map type excluded `%{"unknown" => :ignored}`, which `resolve!/1` accepts and ignores.
- **Fix:** Widened only the D-56 string-key map value to `term()` and pinned the compiled type. The atom-key alternative remains finite.
- **Files modified:** `lib/threadline/retention/policy.ex`, `test/threadline/retention/policy_test.exs`, `test/threadline/doc_rubric_contract_test.exs`.
- **Verification:** Focused 29-test run, strict Dialyzer, warning-free docs, full canonical CI, and fresh independent D-46 PASS.
- **Commit:** `59bd1d69`.

## Issues Encountered

The first canonical CI run could not create Playwright's cache lock in the sandbox and stopped before browser tests. The canonical run was repeated with browser-cache access and passed all lanes. This environment flakiness is recorded as resolved in `deferred-items.md`.

## Next Phase Readiness

Plan 22 is complete. Run phase re-verification before changing SPEC-02 from Pending or marking Phase 234 complete.

## Self-Check: PASSED

The summary and D-46 report exist, and all four task commit hashes are ancestors of HEAD. The review-input hash and sole PASS were verified by Plan 13's report-integrity check.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-06*
