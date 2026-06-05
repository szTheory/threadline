---
phase: 143-accessibility-consistency-sweep-regression
requirements: [POLISH-A11Y]
date: 2026-06-04
---

# Phase 143 Validation Plan

## Required Gates

1. Accessibility source contracts:
   - `mix test test/threadline/operator_surface/style_contract_test.exs`
2. Focused accessibility browser spec:
   - `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-accessibility.spec.ts`
3. Existing browser-suite repair:
   - affected specs from Plan 02
4. Screenshot final set:
   - `operator-screenshots.spec.ts`
   - 24 final PNGs or documented exceptions
5. Screenshot guard:
   - `operator-screenshot-regression.spec.ts`
6. Full gate:
   - `mix verify.example_browser`
7. Schema drift:
   - `gsd-sdk query verify.schema-drift 143`

## Blocking Rules

- `mix verify.example_browser` must be green before Phase 143 completes unless an external non-deterministic infrastructure failure is documented with a same-run focused pass.
- No generated `test-results` artifacts may be committed.
- No blanket focus removal, no blanket root overflow masking, and no new package install unless the plan explicitly justifies it.

