---
phase: 121-adopter-doc-neutrality
plan: 02
subsystem: docs
tags: [phoenix, auth, readme, evaluating, doc-contract, phx-gen-auth, sigra]

requires:
  - phase: 121-01
    provides: getting-started auth neutrality and four-lane upgrade-path vocabulary
provides:
  - README four-lane Start here with grouped phx/Sigra reference auth links
  - Evaluating guide phx-gen-auth reference lane and host-owned auth proof split
  - phx_gen_auth_doc_contract_test.exs ADOPT-AUTH-03 locks (~17 asserts)
  - Extended readme and evaluating doc contracts for ADOPT-AUTH-02
affects: [121-03, adoption-pilot-backlog]

tech-stack:
  added: []
  patterns:
    - "Four-lane README discovery with peer optional reference auth bullets"
    - "Integration guide doc contracts mirror sigra ownership at smaller assert scale"

key-files:
  created:
    - test/threadline/integrations/phx_gen_auth_doc_contract_test.exs
  modified:
    - README.md
    - guides/evaluating-threadline.md
    - test/threadline/readme_doc_contract_test.exs
    - test/threadline/evaluating_threadline_doc_contract_test.exs
    - mix.exs

key-decisions:
  - "Grouped Phoenix auth reference lanes in README Start here instead of isolated Sigra bullet"
  - "Evaluating guide labels Track A as sigra-reference and splits host vs maintainer auth proof"

patterns-established:
  - "phx_gen_auth_doc_contract_test follows sigra contract structure at ~12-18 assert scale"

requirements-completed: [ADOPT-AUTH-02, ADOPT-AUTH-03]

duration: 1min
completed: 2026-05-28
---

# Phase 121 Plan 02: README/Evaluator Discovery & phx Doc Contract Summary

**Four-lane README Start here, evaluator phx-gen-auth neutrality, and ADOPT-AUTH-03 doc-contract gate for the phx.gen.auth integration guide.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-28T11:28:11Z
- **Completed:** 2026-05-28T11:28:39Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- README Start here lists four lanes and groups phx.gen.auth + Sigra as optional reference auth integrations
- Evaluating guide links phx-gen-auth reference lane, labels Track A as sigra-reference, and states host vs maintainer auth proof split
- New `phx_gen_auth_doc_contract_test.exs` locks guide markers, host-owned literals, proof paths, and Sigra adapter refutes
- `mix verify.doc_contract` includes phx integration doc contract (86 tests green)

## Task Commits

Each task was committed atomically:

1. **Task 1: README four-lane discovery** - `6f8869d` (docs)
2. **Task 2: Evaluating guide neutrality + doc contracts for README/evaluator** - `1f08504` (docs)
3. **Task 3: Create phx_gen_auth_doc_contract_test and register in mix.exs** - `f190982` (test)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified

- `README.md` - Four-lane matrix, grouped Phoenix auth reference bullet, Documentation section phx before Sigra
- `guides/evaluating-threadline.md` - phx-gen-auth link, neutrality sentence, sigra-reference Track A label
- `test/threadline/readme_doc_contract_test.exs` - Four-lane and grouped auth asserts; refute Using Sigra
- `test/threadline/evaluating_threadline_doc_contract_test.exs` - ADOPT-AUTH-02 neutrality test
- `test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` - ADOPT-AUTH-03 guide locks (17 asserts)
- `mix.exs` - phx_gen_auth_doc_contract_test in verify.doc_contract alias

## Decisions Made

- Grouped phx + Sigra under one Start here bullet per D-121-14 rather than separate Sigra-first bullet
- Sigra Documentation link annotated "(reference lane)" per D-121-15

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 121-03 (if planned) can extend sigra doc contract or adoption-pilot neutrality
- `mix verify.doc_contract` green (86 tests, 0 failures)
- `upgrade_path_doc_contract_test.exs` matrix asserts unchanged (no duplication in phx contract)

## Self-Check: PASSED

- `grep -F 'phx-gen-auth-reference' README.md` — PASS
- `grep -F 'Phoenix auth (reference lanes, pick one)' README.md` — PASS
- `mix test test/threadline/readme_doc_contract_test.exs test/threadline/evaluating_threadline_doc_contract_test.exs` — PASS (24 tests)
- `mix test test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` — PASS (3 tests, 17 asserts)
- `mix verify.doc_contract` — PASS (86 tests, 0 failures)
- `grep 'phx_gen_auth_doc_contract_test.exs' mix.exs` — PASS

---
*Phase: 121-adopter-doc-neutrality*
*Completed: 2026-05-28*
