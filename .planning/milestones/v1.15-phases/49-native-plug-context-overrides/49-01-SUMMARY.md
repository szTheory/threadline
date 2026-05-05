---
phase: 49-native-plug-context-overrides
plan: 49-01
subsystem: api
tags: [plug, audit_context, sigra]
provides:
  - narrowed Threadline.Plug override allowlist for additive request metadata
  - nil-only supplement semantics for request_id and correlation_id
  - unit and Sigra integration coverage for precedence and validation
affects: [PLUG-01, PLUG-02, SIGRA-04]
requirements-completed: [PLUG-01, PLUG-02]
tech-stack:
  added: []
  patterns: [baseline-first audit context extraction, fill-only request metadata overrides]
key-files:
  created: []
  modified:
    - lib/threadline/plug.ex
    - test/threadline/plug_test.exs
    - test/threadline/integrations/sigra_test.exs
key-decisions:
  - context_overrides_fn may set only request_id and correlation_id
  - header- and conn-derived baseline values remain authoritative over callback output
duration: 25min
completed: 2026-05-05
---

# Plan 49-01 summary

Tightened **`Threadline.Plug`** so `context_overrides_fn` is a narrow additive hook for `request_id` and `correlation_id` only, with deterministic `ArgumentError` failures for forbidden keys and non-map returns.

## Task commits

Executed in the existing dirty Phase 49 worktree without resetting unrelated in-flight changes.

## Self-check

PASSED — `mix test test/threadline/plug_test.exs`
PASSED — `mix test test/threadline/integrations/sigra_test.exs`
