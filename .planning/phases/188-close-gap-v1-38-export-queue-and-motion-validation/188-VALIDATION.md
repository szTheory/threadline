---
phase: 188
slug: close-gap-v1-38-export-queue-and-motion-validation
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-30
completed: 2026-06-30T20:41:37Z
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
| 188-01-01 | 188-01 | Wave 1 | TIME-01 | T-188-01 | Queued export worker honors persisted date-bounded Timeline filters | integration | `mix test test/threadline/export/orchestrator_test.exs` | yes | complete |
| 188-01-02 | 188-01 | Wave 1 | GOV-02 | T-188-02 | Worker parses query params through a fixed allowlist and does not mint atoms from job data | unit/integration | `mix test test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/exports/filter_params_test.exs` | yes | complete |
| 188-01-03 | 188-01 | Wave 1 | A11Y-02 | T-188-03 | Keyboard-reachable queued export action creates a persisted job shape that completes after worker replay | LiveView + worker integration | `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/export/orchestrator_test.exs` | yes | complete |
| 188-02-01 | 188-02 | Wave 1 | MOTION-01 | T-188-04 | `.tl-copy` cannot rely on implicit `transition-property: all` | source contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | yes | complete |
| 188-02-02 | 188-02 | Wave 1 | MOTION-01 | T-188-04 | Browser computed style for `.tl-copy` is explicit when UI-SPEC requires runtime proof | browser | `mix verify.example_browser` | optional existing spec | not required - source proof accepted |
| 188-03-01 | 188-03 | Wave 2 | GOV-02 | - | Phase 186 summary metadata uses canonical `requirements-completed` when Phase 188 owns that doc repair | docs/source contract | `node -e 'const fs=require("fs"); for (const f of process.argv.slice(1)) { const parts=fs.readFileSync(f,"utf8").split(/^---\\n/m); const fm=parts[1] || ""; if (!fm.includes("requirements-completed:")) throw new Error("missing requirements-completed "+f); if (!fm.includes("GOV-02")) throw new Error("missing GOV-02 "+f); if (/^requirements:/m.test(fm)) throw new Error("noncanonical requirements key "+f); }' .planning/phases/186-detail-governance-and-export-surfaces/186-04-SUMMARY.md .planning/phases/186-detail-governance-and-export-surfaces/186-05-SUMMARY.md` | yes | complete |
| 188-03-02 | 188-03 | Wave 2 | CLOSE-01 | - | v1.38 audit no longer reports export queue or motion validation gaps | milestone audit/equivalent classification | `.planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-VERIFICATION.md` and `.planning/v1.38-MILESTONE-AUDIT.md` | yes | complete |

---

## Wave 0 Requirements

- [x] `test/threadline/export/orchestrator_test.exs` - red regression for persisted string `from`/`to` query params proving completed CSV rows honor the date window.
- [x] `test/threadline/export/orchestrator_test.exs` - fail-closed regression for invalid persisted datetime params if the implementation raises or returns parser errors.
- [x] `test/threadline/operator_surface/live/export_status_live_test.exs` - preserve canonical string param persistence for carried Timeline context.
- [x] `test/threadline/operator_surface/style_contract_test.exs` - guard against implicit transition-all shorthand such as `transition: var(--tl-transition-fast)`.
- [x] `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` - optional `.tl-copy` computed `transitionProperty` proof if required by UI-SPEC. Source proof was accepted, so no browser proof was added or required.
- [x] Planning/doc summary metadata check for the audit's `GOV-02` frontmatter finding if this phase owns that cleanup.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final v1.38 audit classification | CLOSE-01 | GSD audit output is a planning closeout artifact, not only a unit-test result | Equivalent post-fix classification recorded in `188-VERIFICATION.md` and `.planning/v1.38-MILESTONE-AUDIT.md`; export queue and motion validation gaps are closed, unrelated residuals remain visible. |

## Completion Evidence

| Command | Result |
|---|---|
| `mix test test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/style_contract_test.exs` | PASS - 92 tests, 0 failures |
| `mix verify.test` | PASS - 1197 tests, 0 failures, 1 excluded |
| Phase 186 frontmatter node check from 188-03 Task 1 | PASS |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s for targeted ExUnit sampling
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
