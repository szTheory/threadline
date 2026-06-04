---
phase: 141-motion-micro-animation
planned: 2026-06-04
status: planning-validation
nyquist_compliant: true
wave_0_complete: false
plans: 3
waves: 3
requirements: [POLISH-MOTION]
---

# Phase 141 Planning Validation

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit source-contract tests plus Playwright Test through the example app E2E workspace |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/style_contract_test.exs` |
| **Browser UAT command** | `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-motion.spec.ts` |
| **Estimated runtime** | Source-contract target should be fast; browser target depends on the example app server on port 4002 |

## Sampling Rate

- **After every task commit:** Run the task's `<verify><automated>` commands.
- **After every wave:** Run `mix test test/threadline/operator_surface/style_contract_test.exs`.
- **After Plan 141-03:** Run the focused `operator-motion.spec.ts` Playwright command with the example app available on `127.0.0.1:4002`.
- **Before `$gsd-verify-work`:** Source-contract tests and focused browser UAT must be green, or the summary must record explicit environment unavailability.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 141-01-01 | 141-01 | 1 | POLISH-MOTION | file/source | `test -f .planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` and `rg -n "M-[0-9]{2}|selector_or_keyframe|persona_jtbd|reduced_motion|tl-thread-draw|prefers-reduced-motion" .planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` | no - created by task | pending |
| 141-01-02 | 141-01 | 1 | POLISH-MOTION | ExUnit source-contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | yes - extended by task | pending |
| 141-02-01 | 141-02 | 2 | POLISH-MOTION | ExUnit source-contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | yes | pending |
| 141-02-02 | 141-02 | 2 | POLISH-MOTION | ExUnit + forbidden-pattern scan | `mix test test/threadline/operator_surface/style_contract_test.exs` and inverted `rg` forbidden-pattern scan against `lib/threadline/operator_surface/style.ex` | yes | pending |
| 141-03-01 | 141-03 | 3 | POLISH-MOTION | spec source smoke | `test -f examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` and `rg -n "reducedMotion|no-preference|animationName|animationDuration|transitionDuration|tl-thread-draw" examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` | no - created by task | pending |
| 141-03-02 | 141-03 | 3 | POLISH-MOTION | ExUnit + Playwright browser UAT | `mix test test/threadline/operator_surface/style_contract_test.exs` and `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-motion.spec.ts` | spec from 141-03-01 | pending |

## Wave 0 Requirements

No separate Wave 0 plan is required. Missing validation artifacts are created before their full gates:

- `141-MOTION-INVENTORY.md` is created in `141-01` Task 1 before inventory-reading source-contract tests run in Task 2.
- Motion-specific additions to `style_contract_test.exs` are created in `141-01` Task 2 before CSS drift correction in `141-02`.
- `operator-motion.spec.ts` is created in `141-03` Task 1 before the focused browser UAT gate in Task 2.

## Phase Requirement to Test Map

| Req ID | Behavior | Primary Plans | Automated Proof |
|--------|----------|---------------|-----------------|
| POLISH-MOTION | Inventory maps every shipped animation/non-trivial transition to trigger, JTBD/persona, token, rationale, frequency, and reduced-motion behavior | 141-01, 141-02 | `mix test test/threadline/operator_surface/style_contract_test.exs` |
| POLISH-MOTION | Motion uses locked `120ms`, `180ms`, `240ms`, `40ms`, `8px`, and `16px` token scale plus allowed keyframes/thread-draw motif | 141-01, 141-02, 141-03 | Source-contract tests plus default-motion computed-style browser assertions |
| POLISH-MOTION | `prefers-reduced-motion` covers every animated/transitioned surface | 141-01, 141-02, 141-03 | Source-contract reduced-motion checks plus focused Playwright reduced-motion assertions |
| POLISH-MOTION | No gratuitous motion, new animation libraries, screenshot baselines, or Phase 142/143 scope creep | 141-01, 141-02, 141-03 | Source-contract tests, inverted forbidden-pattern scan, and focused browser scope |

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Research-backed rationale quality | POLISH-MOTION | Tests can require non-empty rationale and source anchors, but a human should confirm the rationale is operational rather than decorative | Review `141-MOTION-INVENTORY.md`; every row should tie to trigger, persona/JTBD, token, and reduced-motion outcome. |

## Validation Sign-Off

- [x] All tasks have an automated verify command or a same-plan prerequisite that creates the file first.
- [x] Sampling continuity: no three consecutive implementation tasks lack automated verification.
- [x] Wave 0 gaps are covered by task-local creation before dependent gates.
- [x] No watch-mode flags.
- [x] Feedback latency is bounded to focused ExUnit checks plus one focused browser spec after the example app is available.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** planner-bound 2026-06-04; checker to confirm.
