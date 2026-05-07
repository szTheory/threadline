---
phase: 67
plan: 03
subsystem: operator-surface-policy-redaction
tags:
  - elixir
  - threadline
  - liveview
  - operator-surface
  - policy
  - redaction
requires:
  - 67-01
provides:
  - "Threadline.OperatorSurface.Live.PolicyRedactionLive drift-first operator page"
  - "Router /policy/redaction sibling LiveView route under threadline_operator_surface/2"
  - "Additive .threadline-ui policy redaction section/detail styling"
  - "LiveView integration coverage for presenter parity, section ordering, safe copy, and no-sample-values output"
affects:
  - "67-04 doc-contract and adoption docs can now pin the new route and locked operator copy"
tech-stack:
  added: []
  patterns:
    - "File-scope `Code.ensure_loaded?(Phoenix.LiveView)` gate on the new LiveView"
    - "Presenter-driven section rendering from `Threadline.Policy.RedactionPresenter.build/1`"
    - "Native `<details>` disclosure for local-only row expansion with no URL contract"
    - "Phoenix.LiveView integration test fixture using real PostgreSQL trigger functions for drift/match/introspection states"
key-files:
  created:
    - "lib/threadline/operator_surface/live/policy_redaction_live.ex"
    - "test/threadline/operator_surface/live/policy_redaction_live_test.exs"
  modified:
    - "lib/threadline/operator_surface/router.ex"
    - "lib/threadline/operator_surface/style.ex"
decisions:
  - "Used native `<details>` rows instead of LiveView-managed toggle params to keep disclosure strictly local UI state."
  - "Kept the page fact source entirely in `Threadline.Policy.RedactionPresenter` so row ordering, counts, hints, and warnings stay in parity with the Mix-facing surface."
metrics:
  duration: ~25 min
  completed: 2026-05-07T00:00:00Z
  tasks: 2
  files: 5
---

# Phase 67 Plan 03: Policy Redaction Operator Surface Summary

Phase 67 Plan 03 ships the read-only operator page at `/audit/policy/redaction` as a sibling to the existing coverage surface. `Threadline.OperatorSurface.Live.PolicyRedactionLive` stays file-scope gated, loads one shared `Threadline.Policy.RedactionPresenter` report at mount, renders the locked section order `Drift detected`, `Could not introspect`, `Config matches deployed`, and uses native `<details>` disclosures so operators can inspect exact configured/deployed `exclude`, `mask`, and mask-placeholder facts without introducing any URL state. The row copy stays on the operator-safe status/hint wording defined in Phase 67 context, and the page never renders sample values.

`router.ex` now wires `live("/policy/redaction", PolicyRedactionLive, :index)` under the existing operator-surface scope. `style.ex` adds only namespaced `.threadline-ui` redaction-page rules for section headers, low-noise matching rows, warnings, and the detail table. The LiveView integration suite exercises a real catalog-backed fixture spanning drift, introspection failure, and matching rows, then asserts section ordering, alphabetical row ordering within sections, presenter parity, exact detail rendering, and the no-sample-values invariant.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

| Command | Result |
| --- | --- |
| `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs` | passed |
| `mix verify.compile_no_optional` | passed |

## Tasks → Commits

| Task | Commit | Notes |
| --- | --- | --- |
| Task 1 | `43f5629` | Added `PolicyRedactionLive`, route wiring, and additive surface styles |
| Task 2 | `afc6443` | Added catalog-backed LiveView integration test coverage |

## Known Stubs

None.

## Self-Check: PASSED

- `lib/threadline/operator_surface/live/policy_redaction_live.ex` exists.
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs` exists.
- Commits `43f5629` and `afc6443` exist in git history.
