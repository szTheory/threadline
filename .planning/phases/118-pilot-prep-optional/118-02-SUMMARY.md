---
phase: 118-pilot-prep-optional
plan: 02
subsystem: docs
tags: [pilot-prep, evaluating-guide, readme, exdoc, doc-contract]

requires:
  - phase: 118-pilot-prep-optional
    provides: PILOT-01 verify ladder prose alignment in adoption-pilot backlog
provides:
  - External evaluator one-pager at guides/evaluating-threadline.md
  - README Start here + Documentation discovery for evaluating guide
  - ExDoc extra and verify.doc_contract wiring for evaluating contract test
affects:
  - External pilot hosts and Hex evaluators

key-files:
  created:
    - guides/evaluating-threadline.md
    - test/threadline/evaluating_threadline_doc_contract_test.exs
  modified:
    - README.md
    - mix.exs
    - test/threadline/readme_doc_contract_test.exs

key-decisions:
  - "Thin evaluating guide (~75 lines); README map link only — no new Evaluating band"
  - "Non-claims avoid maintainer+STG+attest regex while stating integrator-owned STG realism"

requirements-completed: [PILOT-02]

duration: 15min
completed: 2026-05-27
---

# Phase 118 Plan 02 Summary

**Evaluator one-pager links 0.6.0 packaging, host-owned boundaries, verify ladder, and STG template pointers; README and ExDoc expose it without maintainer STG attestation phrasing.**

## Self-Check: PASSED

- `mix verify.doc_contract` — 79 tests, 0 failures
- `guides/evaluating-threadline.md` — 75 lines (within 60–140 acceptance band)
