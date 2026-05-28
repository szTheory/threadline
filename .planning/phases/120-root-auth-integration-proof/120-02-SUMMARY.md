---
phase: 120-root-auth-integration-proof
plan: 02
subsystem: docs
tags: [phx-gen-auth, upgrade-path, doc-contract]

requires:
  - phase: 120-01
    provides: phx_gen_auth_integration_test.exs proof path
provides:
  - Fourth compatibility matrix row and four-lane doc-contract locks (AUTH-PROOF-03)
affects: []

key-files:
  created: []
  modified:
    - guides/integrations/phx-gen-auth.md
    - guides/upgrade-path.md
    - test/threadline/upgrade_path_doc_contract_test.exs
    - test/threadline/v1_23_charter_doc_contract_test.exs

requirements-completed: [AUTH-PROOF-03]

completed: 2026-05-27
---

# Phase 120 Plan 02 Summary

**Guide and upgrade-path now cite root integration tests; doc-contract locks enforce four named lanes with honest proof anchors.**

## Accomplishments

- Fixed 1-arity `authorize_fn` in phx-gen-auth guide; retired forthcoming deferrals
- Added `phx-gen-auth-reference` matrix row before `sigra-reference`
- Extended `upgrade_path_doc_contract_test` for phx lane detection and guide proof literals
- Updated v1.26 charter doc-contract assertions (milestone drift unblock for `mix verify.test`)
