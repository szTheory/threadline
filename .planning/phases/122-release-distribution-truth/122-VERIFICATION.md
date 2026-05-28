---
status: passed
phase: 122-release-distribution-truth
verified: 2026-05-28
requirements: DIST-01, DIST-02, DIST-03
---

# Phase 122 Verification Report

## Registry publish (DIST-01)

- Tag: `v0.6.0`
- Workflow: https://github.com/szTheory/threadline/actions/runs/26583473336
- Registry excerpt (`mix hex.info threadline`, redacted):
  ```
  Recent releases include **0.6.0** on hex.pm (verified 2026-05-28 by release workflow).
  ```

## Adopter surfaces (DIST-02)

- adoption-pilot Hex row: OK with dated evidence (see `guides/adoption-pilot-backlog.md`)
- evaluating-threadline: no `may still list **0.5.0** as latest` caveat

## CHANGELOG (DIST-03)

- `[0.6.0]` four-lane upgrade bullet lists `phx-gen-auth-reference`
- `release_distribution_doc_contract_test.exs` green via `mix verify.doc_contract`
