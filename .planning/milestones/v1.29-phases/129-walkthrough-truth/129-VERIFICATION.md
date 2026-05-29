---
phase: 129-walkthrough-truth
status: passed
verified: 2026-05-28
score: 8/8
---

# Phase 129 Verification

**Goal:** Maintainers walking `WALKTHROUGH.md` on a clean clone do not hit cwd lies or misleading row-history URLs.

## Must-haves

| ID | Criterion | Status | Evidence |
|----|-----------|--------|----------|
| WALK-01 | Optional verify uses `mix threadline.verify_coverage` from example cwd; §0 documents walk vs root | passed | WALKTHROUGH.md §0, WALK-01-02, WALK-04-03; contract tests |
| WALK-02 | Do steps navigation-first; tables label shorthand; §0 Row history URLs SSOT | passed | WALKTHROUGH.md edits; contract Do-slice refutes |
| WALK-03 | Doc-contract locks verify cwd and row-history truth | passed | `walkthrough_doc_contract_test.exs` — 8 tests green |

## Automated checks

- `cd examples/threadline_phoenix && mix test test/threadline_phoenix/walkthrough_doc_contract_test.exs` — 8 tests, 0 failures
- `mix verify.example` — 61 tests, 0 failures
- `grep mix verify.threadline examples/threadline_phoenix/WALKTHROUGH.md` — no matches

## Human verification

None required.

## Gaps

None.
