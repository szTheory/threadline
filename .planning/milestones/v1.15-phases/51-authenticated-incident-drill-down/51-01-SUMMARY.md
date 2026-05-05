---
phase: 51-authenticated-incident-drill-down
plan: 51-01
subsystem: incident-api
tags: [incident, phoenix, auth, tests]
provides:
  - endpoint-local authenticated drill-down baseline in the Phoenix example app
  - request-path proof for authenticated success, anonymous 401, and authenticated malformed-id 400
affects: [INCIDENT-03]
requirements-completed: [INCIDENT-03]
tech-stack:
  added: []
  patterns: [endpoint-local auth guard, normalized audit_context actor check, router-path proof]
key-files:
  created: []
  modified:
    - examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs
key-decisions:
  - authenticated malformed ids stay on the existing 400 branch instead of being folded into new authz semantics
  - the real Sigra-shaped router path remains the golden proof surface for incident drill-down
duration: 10min
completed: 2026-05-05
---

# Plan 51-01 summary

Kept the existing endpoint-local incident auth baseline and finished the missing request-path proof so authenticated callers still see the established success payload while anonymous and malformed-id requests stay on their exact `401` and `400` contracts.

## Task commits

Executed in the existing dirty Phase 51 worktree without resetting unrelated in-flight changes.

## Self-check

PASSED — `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs`
