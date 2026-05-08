---
phase: 70
plan: "70-02"
subsystem: docs
tags:
  - support-matrix
  - sigra
  - auth-boundary
  - doc-contract
provides:
  - INTEG-02
  - COMPAT-03
key_files:
  created:
    - .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-02-SUMMARY.md
  modified:
    - guides/upgrade-path.md
    - guides/integrations/sigra.md
    - test/threadline/upgrade_path_doc_contract_test.exs
    - test/threadline/integrations/sigra_doc_contract_test.exs
decisions:
  - Make root-lane proof and example-lane proof explicit in the upgrade matrix instead of letting the two blur together.
  - Keep `{:sigra, "~> 0.2", optional: true}` framed as a host install shape, not as blanket compatibility for every Sigra `0.2.x` host.
  - State the request-capture auth split, `authorize_fn`, and `export_authorize_fn` split directly in the Sigra guide so `/audit` and export auth stay clearly host-owned.
---

# Phase 70 Plan 70-02 Summary

Tightened the lane/proof docs so the root `phoenix-surface` evidence and the
example `sigra-reference` evidence are now spelled out separately, while the
Sigra guide stays concrete, soft-loaded, and request-capture-only.

## Completed Tasks

| Task | Outcome |
| --- | --- |
| 1 | Updated `guides/upgrade-path.md` to tie `phoenix-surface` proof to root `mix.exs`, root `mix.lock`, root CI, and root doc-contract coverage, and to tie `sigra-reference` proof to the example app lockfile, README, guide, and `mix verify.example`. |
| 2 | Added the explicit caveat that `{:sigra, "~> 0.2", optional: true}` is a host install shape rather than a blanket compatibility promise. |
| 3 | Extended `guides/integrations/sigra.md` and its contract test with the request-capture-only wording plus the host-owned `authorize_fn` / `export_authorize_fn` split. |

## Verification

- `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs --max-failures 1`
  Result: passed.
- `mix verify.compile_no_optional`
  Result: passed.

## Deviations from Plan

None. The slice executed as planned.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check

PASSED
