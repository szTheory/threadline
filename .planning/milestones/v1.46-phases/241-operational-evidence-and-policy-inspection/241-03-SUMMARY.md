---
phase: 241-operational-evidence-and-policy-inspection
plan: "03"
subsystem: ui/operations
tags: [phoenix, liveview, policy, redaction, playwright]
provides:
  - missing-trigger drift regardless of configured policy cardinality
  - safe normalized policy disclosure and bounded current-deployment claims
  - retryable policy inspection outages without raw errors or stale match assurance
affects: [operator-policy, 243-integrated-verification-and-review-preview]
actuals:
  tasks: 2
  commits: 3
plan_head_before: cc5aa141092b909d66f866354ce743a53769bb5a
plan_head_after: 3bbe19ebf80661b20c167b06396b4584815e48d3
tech-stack:
  added: []
  patterns: [normalized policy projection, guarded read-only refresh, narrow connection-error recovery]
key-files:
  created: []
  modified:
    - lib/threadline/policy/redaction_presenter.ex
    - lib/threadline/operator_surface/live/policy_redaction_live.ex
    - test/threadline/policy/redaction_presenter_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
    - test/fixtures/operator_surface/route-inventory.json
    - test/fixtures/operator_surface/source-surface-checklist.json
key-decisions:
  - "Missing configured-table triggers are drift even when configured rules are empty."
  - "Unreadable existing triggers retain could_not_introspect; current inspection cannot establish historical or downstream redaction."
  - "A connection failure clears the prior comparison and retains schema and retry controls, without leaking exception messages."
requirements-completed: [UIO-04]
coverage:
  - id: D1
    description: "Missing triggers, unreadable deployed policy, confirmed matches, and unavailable reads remain distinct with safe output and retry."
    requirement: UIO-04
    verification:
      - kind: unit
        ref: "mix test test/threadline/policy/redaction_presenter_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs (31 tests, 0 failures)"
        status: pass
      - kind: automated_ui
        ref: "Redaction comparison and missing/unreadable deployment tests, desktop-chromium and mobile-chromium (4 passing cases within the 13-pass inspection run)"
        status: pass
    human_judgment: false
completed: 2026-10-10
status: complete
---

# Phase 241 Plan 03: Deployed Redaction Inspection Summary

Missing configured-table triggers remain actionable drift; unreadable deployment and unavailable reads cannot produce a match or all-clear result.

## Accomplishments

- Preserved the three existing statuses and drift-first ordering. Empty collections have distinct copy and require at least one inspected match before all-clear.
- Added a guarded `Refresh policy inspection` action and native keyboard disclosure. Normalized configured/deployed fields remain available on desktop and mobile; source, audit-sample and redacted-value canaries stay absent from text and attributes.
- Limited the claim to current deployed trigger definitions. It does not establish redaction of historical audit rows or downstream exports.
- Review found and repaired a connection-error gap across schema enumeration, validation and catalog reads. Failed refresh clears the previous comparison, retains the selected schema and retry, and never prints the private error. Successful retry rebuilds the report.

## Task Commits

1. **Task 1: Correct presenter and mounted policy behavior** - `5d7c81a2` (fix)
2. **Task 2: Verify desktop/mobile policy and control inventory** - `449b4399` (test; shared with Plan 04)
3. **Task 1: Recover policy inspection outages found during review** - `3bbe19eb` (fix)

## Verification

The final focused ExUnit command passed 31 tests. The targeted browser inspection run passed 13 cases with one intentional mobile skip for the desktop-only real-zoom instrument. Both redaction tests executed in both voting browser projects. TypeScript checking and the source/control-inventory contract checks passed. Final phase-wide CI is recorded separately in `241-VERIFICATION.md` and `241-CI-RECEIPT.json`.

## TDD and Recovery

Recovered the interrupted edits from session `01a11661-7527-7d81-a91e-9152783d392d`; its last browser run failed during Chromium startup. Fresh runs were used for completion. Two additional recovery regressions were observed failing before their fixes: forged refresh with disabled/invalid access, and schema/catalog connection failure. `241-03-RECOVERY-RED.json` records the observed failures; no pre-restart RED commit sequence is claimed.

## Decisions and Deviations

- The browser regressions for Plans 03/04 share one commit because both update the independently scanned control inventory. Existing inventory IDs and visual baselines remain unchanged.
- Corrected test locators for duplicate `Host schema` labels, whitespace in native disclosure text, responsive hidden headers and LiveView connection timing.
- Extracted the refresh component to meet the repository's function-size limit.
- Reused existing locked dependencies and cached Chromium with a temporary local runner. No package installation or public API change was introduced.

## Threat Flags

The new refresh event is guarded by host-enabled policy access and valid schema state; retries revalidate scope. This maps to T-241-03. Raw connection errors remain private, mapping to T-241-02. No unregistered attack surface was added.

## Next Phase Readiness

Policy inspection is ready for Phase 243 integrated candidate verification. Phase 242 export and retention work remains separate.
