---
phase: 49-native-plug-context-overrides
plan: 49-02
subsystem: docs
tags: [guides, doc-contract, sigra, phoenix]
provides:
  - adopter-facing docs that describe additive-only Threadline.Plug context overrides
  - doc-contract tests locking placement, precedence, and failure behavior
affects: [PLUG-01, PLUG-02, ADOPT-03]
requirements-completed: [PLUG-01, PLUG-02]
tech-stack:
  added: []
  patterns: [docs as contract, direct router callback wiring]
key-files:
  created: []
  modified:
    - guides/integrations/sigra.md
    - guides/getting-started-saas.md
    - test/threadline/integrations/sigra_doc_contract_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs
key-decisions:
  - document actor_fn as the only actor-authority path
  - make placement, precedence, host-owned IP normalization, and raising behavior explicit
duration: 20min
completed: 2026-05-05
---

# Plan 49-02 summary

Aligned the Sigra and SaaS quickstart guides with the shipped **native `Threadline.Plug` host-wiring contract**, then locked the wording in focused doc-contract tests so additive-only override semantics cannot drift silently.

## Task commits

Executed in the existing dirty Phase 49 worktree without resetting unrelated in-flight changes.

## Self-check

PASSED — `mix test test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs`
