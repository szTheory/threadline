---
phase: 50-direct-sigra-host-wiring
plan: 50-02
subsystem: docs
tags: [sigra, docs, readme, doc-contract]
provides:
  - example and integration docs that teach one canonical direct Sigra callback path
  - doc-contract tests locking the example README and Sigra guide against direct-wiring drift
affects: [SIGRA-04, SIGRA-05]
requirements-completed: [SIGRA-04, SIGRA-05]
tech-stack:
  added: []
  patterns: [docs as contract, canonical adapter naming]
key-files:
  created:
    - test/threadline/example_phoenix_readme_contract_test.exs
  modified:
    - examples/threadline_phoenix/README.md
    - guides/integrations/sigra.md
    - test/threadline/integrations/sigra_doc_contract_test.exs
key-decisions:
  - the README must name both direct Sigra callbacks explicitly
  - doc-contract coverage should fail if delegate-seam language or alternate names reappear
duration: 15min
completed: 2026-05-05
---

# Plan 50-02 summary

Aligned the Sigra guide and Phoenix example README around the shipped **direct callback contract**, then added a dedicated README contract test so the public host-wiring story cannot drift back toward an example-local seam.

## Task commits

Executed in the existing dirty Phase 50 worktree without resetting unrelated in-flight changes.

## Self-check

PASSED — `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs`
