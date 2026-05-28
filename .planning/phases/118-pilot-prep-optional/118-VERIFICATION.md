---
status: passed
phase: 118-pilot-prep-optional
verified: 2026-05-27
score: 2/2
---

# Phase 118 Verification Report

**Phase goal:** Lower friction for an external evaluator or pilot host without claiming maintainer STG attestation.

## Requirements Verified

| ID | Requirement | Status | Evidence |
|----|-------------|--------|----------|
| PILOT-01 | Adoption-pilot backlog verification pointers refreshed; no stale test counts; canonical `mix verify.*` entrypoints | ✓ | `guides/adoption-pilot-backlog.md` evidence pass (2026-05-27) lists eight-step `mix ci.all` chain; `rg -F '136 tests'` — no matches; `adoption_pilot_doc_contract_test.exs` refutes `136 tests` and `~r/\(\d+ tests/` |
| PILOT-02 | External evaluator one-pager states 0.6.0 packaging, host-owned boundaries, verify ladder; no STG attestation | ✓ | `guides/evaluating-threadline.md` (75 lines); README Start here + Documentation links; `evaluating_threadline_doc_contract_test.exs` locks entrypoints and refutes `~r/maintainer.*STG.*(attest|certif)/i` |

## Plan 118-01 Must-Haves

| Truth / artifact | Status | Evidence |
|------------------|--------|----------|
| Guide cites named `mix verify.*` matching `mix.exs`; no hardcoded test counts | ✓ | Eight aliases in evidence pass + in-repo parity row |
| Evidence pass and In-repo parity aligned with `mix ci.all` | ✓ | Same step list; CONTRIBUTING.md linked |
| Doc contract refutes stale counts | ✓ | `mix test test/threadline/adoption_pilot_doc_contract_test.exs` — 4 tests, 0 failures |

## Plan 118-02 Must-Haves

| Truth / artifact | Status | Evidence |
|------------------|--------|----------|
| `guides/evaluating-threadline.md` with 0.6.0 proof, host boundaries, verify ladder | ✓ | `rg -F 'mix ci.all'`, `mix verify.doc_contract`, `host-owned` — matches |
| README maps to evaluating guide (not HexDocs-only) | ✓ | `rg -F 'guides/evaluating-threadline.md' README.md` — 2 matches |
| ExDoc extra + `verify.doc_contract` includes evaluating contract | ✓ | `mix.exs` extras + alias string |
| No maintainer STG attestation phrasing | ✓ | Contract refute test passes |

## Automated Checks (2026-05-27)

```text
mix test test/threadline/adoption_pilot_doc_contract_test.exs
  → 4 tests, 0 failures

mix test test/threadline/evaluating_threadline_doc_contract_test.exs
  → 5 tests, 0 failures

mix verify.doc_contract
  → 79 tests, 0 failures

rg -F '136 tests' guides/adoption-pilot-backlog.md
  → no matches (exit 1)

wc -l guides/evaluating-threadline.md
  → 75 lines (within 60–140 acceptance band)
```

## Human Verification

None required — all must-haves verified via doc contracts and targeted tests.

## Gaps

None.
