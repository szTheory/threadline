---
status: resolved
mode: shift-left
phase: 67-drift-aware-redaction-admin-mix-task-parity
source:
  - 67-01-SUMMARY.md
  - 67-02-SUMMARY.md
  - 67-03-SUMMARY.md
  - 67-04-SUMMARY.md
  - 67-05-SUMMARY.md
started: 2026-05-07T20:08:34Z
updated: 2026-05-07T20:14:44Z
human_steps_required: 0
automation_deferred: []
---

## Current Test

[testing complete]

## Tests

### 1. Shared redaction reconciliation stays fail-closed and ordered
expected: Shared policy reconciliation normalizes configured policy, classifies deployed triggers as drift, could-not-introspect, or config-matches-deployed, and keeps the canonical drift-first ordering without exposing sample values.
result: pass
automated_via:
  - mix test test/threadline/policy/redaction_presenter_test.exs test/threadline/policy/redaction_presenter_catalog_test.exs
  - mix verify.compile_no_optional

### 2. `mix threadline.policy.show` exposes the operator drift report
expected: Running `mix threadline.policy.show` prints the summary line plus aligned drift table and detail blocks, while `mix threadline.policy.show --json` emits the stable summary-plus-tables machine contract.
result: pass
automated_via:
  - mix test test/threadline/operator_surface/policy_show_mix_test.exs

### 3. `/audit/policy/redaction` renders the same drift facts in LiveView
expected: The operator page mounts at `/audit/policy/redaction`, renders the locked section order Drift detected -> Could not introspect -> Config matches deployed, preserves alphabetical row ordering inside each section, and never renders sample values.
result: pass
automated_via:
  - mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs
  - mix verify.compile_no_optional

### 4. Docs and contract tests stay aligned with the shipped route and commands
expected: The route, status labels, JSON enums, rerun guidance, no-sample-values language, and public docs remain aligned with `/audit/policy/redaction` and `mix threadline.policy.show`.
result: pass
automated_via:
  - mix test test/threadline/operator_surface/policy_show_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs

### 5. Phase 67 release gate is green
expected: `mix ci.all` completes successfully so the phase satisfies its declared pre-verify gate before being marked verified.
result: pass
automated_via:
  - mix ci.all

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "`mix ci.all` completes successfully so the phase satisfies its declared pre-verify gate before being marked verified."
  status: resolved
  reason: "Plan 67-05 reformatted the diagnosed files and `mix ci.all` now exits 0."
  severity: resolved
  test: 5
  root_cause: "Committed Phase 67 source and test files had formatter drift, so the repo's first release gate failed before the rest of the suite could run."
  artifacts:
    - path: "lib/mix/tasks/threadline.policy.show.ex"
      issue: "Formatting drift resolved"
    - path: "lib/threadline/policy/redaction_presenter.ex"
      issue: "Formatting drift resolved"
    - path: "lib/threadline/capture/trigger_capture_config.ex"
      issue: "Formatting drift resolved"
    - path: "test/threadline/operator_surface/policy_show_doc_contract_test.exs"
      issue: "Formatting drift resolved"
    - path: "test/threadline/operator_surface/policy_show_mix_test.exs"
      issue: "Formatting drift resolved"
    - path: "test/threadline/policy/redaction_presenter_test.exs"
      issue: "Formatting drift resolved"
  missing:
    - "None."
