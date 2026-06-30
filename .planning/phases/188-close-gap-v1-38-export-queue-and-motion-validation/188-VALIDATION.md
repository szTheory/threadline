---
phase: 188
slug: close-gap-v1-38-export-queue-and-motion-validation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 188 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix 1.19.5; optional Playwright Test 1.60.0 for browser proof |
| **Config file** | `mix.exs`; optional browser config under `examples/threadline_phoenix/e2e` |
| **Quick run command** | `mix test test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/style_contract_test.exs` |
| **Full suite command** | `mix verify.test`; add `mix verify.example_browser` only if the Phase 188 UI-SPEC requires browser proof |
| **Estimated runtime** | ~120 seconds quick, project-dependent for full suite |

---

## Sampling Rate

- **After every task commit:** Run the narrow `mix test` command for the files touched by that task.
- **After every plan wave:** Run `mix verify.test`; add `mix verify.example_browser` only when browser motion proof is in scope.
- **Before `/gsd:verify-work`:** Full suite and targeted Phase 188 regressions must be green.
- **Max feedback latency:** ~120 seconds for targeted ExUnit sampling.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 188-01-01 | TBD | TBD | TIME-01 | T-188-01 | Queued export worker honors persisted date-bounded Timeline filters | integration | `mix test test/threadline/export/orchestrator_test.exs` | yes | pending |
| 188-01-02 | TBD | TBD | GOV-02 | T-188-02 | Worker parses query params through a fixed allowlist and does not mint atoms from job data | unit/integration | `mix test test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/exports/filter_params_test.exs` | yes | pending |
| 188-01-03 | TBD | TBD | A11Y-02 | T-188-03 | Keyboard-reachable queued export action creates a persisted job shape that completes after worker replay | LiveView + worker integration | `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/export/orchestrator_test.exs` | yes | pending |
| 188-02-01 | TBD | TBD | MOTION-01 | T-188-04 | `.tl-copy` cannot rely on implicit `transition-property: all` | source contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | yes | pending |
| 188-02-02 | TBD | TBD | MOTION-01 | T-188-04 | Browser computed style for `.tl-copy` is explicit when UI-SPEC requires runtime proof | browser | `mix verify.example_browser` | optional existing spec | pending |
| 188-03-01 | TBD | TBD | GOV-02 | - | Phase 186 summary metadata uses canonical `requirements-completed` when Phase 188 owns that doc repair | docs/source contract | `rg -n "requirements:" .planning/phases/186* .planning/summaries*` | planner lookup required | pending |
| 188-03-02 | TBD | TBD | CLOSE-01 | - | v1.38 audit no longer reports export queue or motion validation gaps | milestone audit | GSD milestone audit rerun | yes | pending |

---

## Wave 0 Requirements

- [ ] `test/threadline/export/orchestrator_test.exs` - red regression for persisted string `from`/`to` query params proving completed CSV rows honor the date window.
- [ ] `test/threadline/export/orchestrator_test.exs` - fail-closed regression for invalid persisted datetime params if the implementation raises or returns parser errors.
- [ ] `test/threadline/operator_surface/live/export_status_live_test.exs` - preserve canonical string param persistence for carried Timeline context.
- [ ] `test/threadline/operator_surface/style_contract_test.exs` - guard against implicit transition-all shorthand such as `transition: var(--tl-transition-fast)`.
- [ ] `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` - optional `.tl-copy` computed `transitionProperty` proof if required by UI-SPEC.
- [ ] Planning/doc summary metadata check for the audit's `GOV-02` frontmatter finding if this phase owns that cleanup.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final v1.38 audit classification | CLOSE-01 | GSD audit output is a planning closeout artifact, not only a unit-test result | Re-run the v1.38 milestone audit after implementation and confirm export queue and motion validation gaps are closed or intentionally reclassified. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for targeted ExUnit sampling
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
