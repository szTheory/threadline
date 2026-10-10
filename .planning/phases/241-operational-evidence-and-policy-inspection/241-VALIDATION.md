---
phase: "241"
slug: "operational-evidence-and-policy-inspection"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 241 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit for core and mounted LiveView behavior; Playwright for example-app browser flows |
| **Config file** | Root aliases in `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/presentation_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~120 seconds for a focused ExUnit group; ~600 seconds for the complete CI lane including browser projects |

---

## Sampling Rate

- **After every task commit:** Run the task's focused ExUnit command, or the targeted browser spec for rendered behavior.
- **After every plan wave:** Run `mix ci.all`.
- **Before `$gsd-verify-work`:** `mix ci.all` must be green.
- **Max feedback latency:** 120 seconds for focused ExUnit checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 241-01-01 | 01 | 1 | UIO-02 | T-241-01, T-241-03 | A failed schema read is unavailable, stale rows retain their timestamp, and remediation commands cannot be formed from unsafe identifiers. | LiveView + presentation unit | `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/presentation_test.exs` | ✅ | ⬜ pending |
| 241-01-02 | 01 | 1 | UIO-02 | T-241-01 | Coverage remediation remains schema-qualified and scoped on desktop/mobile. | Browser | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-coverage-readiness.spec.ts` | ✅ | ⬜ pending |
| 241-02-01 | 02 | 1 | UIO-03 | T-241-02, T-241-03 | No matching evidence, disabled access, and failed reads remain distinct; arbitrary host maps and overbroad completeness claims stay out of the UI. | LiveView unit | `mix test test/threadline/operator_surface/live/evidence_live_test.exs` | ✅ | ⬜ pending |
| 241-02-02 | 02 | 1 | UIO-03 | T-241-02 | Latest-to-history navigation retains the selected subject/reference and the rendered state remains truthful. | Browser | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-route-states.spec.ts` | ✅ | ⬜ pending |
| 241-03-01 | 03 | 1 | UIO-04 | T-241-02, T-241-03 | Missing configured-table triggers are drift even for empty policy; parser failures remain distinct and canaries do not appear in presenter or rendered output. | Presenter + LiveView unit | `mix test test/threadline/policy/redaction_presenter_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs` | ✅ | ⬜ pending |
| 241-03-02 | 03 | 1 | UIO-04 | T-241-02 | Deployed-policy states and safe disclosures render without raw SQL, audit samples, or redacted values. | Browser | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-route-states.spec.ts` | ✅ | ⬜ pending |
| 241-04-01 | 04 | 1 | UIO-02, UIO-03, UIO-04 | T-241-02 | Responsive, theme, keyboard, visible-focus, touch, and reduced-motion behavior remains usable on affected routes. | Browser accessibility | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-accessibility.spec.ts` | ✅ | ⬜ pending |
| 241-04-02 | 04 | 1 | UIO-02, UIO-03, UIO-04 | T-241-02 | Actual 200% zoom preserves complete values and primary controls. | Browser zoom | `mix verify.example_browser --project=desktop-chromium operator-zoom-proof.spec.ts` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- Existing ExUnit fixtures and Phoenix LiveView test support cover all three route families; add the missing regression cases in the corresponding focused suites.
- Existing Playwright projects cover desktop and mobile Chromium; no test framework or package installation is needed.
- Initial-read failure vs confirmed-empty for coverage; schema-qualified safe command plus unsafe-identifier manual fallback.
- Successful evidence no-match vs read failure and disabled access, with subject/reference history preserved.
- Empty configured redaction policy plus missing-trigger drift, rendered canary absence, and no false all-clear.

---

## Manual-Only Verifications

All phase behaviors have automated verification. The existing desktop zoom-proof browser suite covers actual 200% zoom; record any environment-specific browser limitation as an evidence gap.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for focused suites
- [ ] `nyquist_compliant: true` set in frontmatter after validation

**Approval:** pending
