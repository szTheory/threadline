---
phase: 187
slug: accessibility-motion-docs-and-adversarial-closeout
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 187 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Mix for source and doc contracts; Playwright Test for browser accessibility, motion, responsive, Storybook, stress, and screenshot proof |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/theme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs` |
| **Browser A11Y command** | `mix verify.example_browser -- operator-accessibility.spec.ts` |
| **Browser motion command** | `mix verify.example_browser -- operator-motion.spec.ts` |
| **Full suite command** | `mix ci.all`, with residual ownership classified if non-green |
| **Estimated runtime** | Targeted Mix slice should stay under 120 seconds locally; browser proof varies with example-app startup |

---

## Sampling Rate

- **After every task commit:** Run the narrow source/doc test for changed files, then the relevant Playwright file if browser behavior changed.
- **After every plan wave:** Run the quick source/doc command plus `mix verify.example_browser -- operator-accessibility.spec.ts operator-motion.spec.ts` when both accessibility and motion are touched.
- **Before `/gsd:verify-work`:** Run the targeted source/doc command, targeted browser accessibility/motion command, screenshot guard status command, and `mix ci.all` or classify broad residuals with owner and impact.
- **Max feedback latency:** No three consecutive task commits without automated verification; targeted Mix sampling target is under 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 187-W0-DOC-THEME | TBD | 1 | DOC-01 | T-187-01 | Runtime theme picker docs match the implemented server-posted `system|light|dark` form, CSRF, cookie/plug resolution, no JavaScript, and no `localStorage` | doc/source contract | `mix test test/threadline/operator_surface/theme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs` | yes | pending |
| 187-W0-A11Y | TBD | 1 | A11Y-01, A11Y-02 | T-187-02 | Custom widgets and native controls keep APG-shaped semantics, keyboard support, visible non-obscured focus, and focus restoration without claiming screen-reader certification | source + browser | `mix test test/threadline/operator_surface/component_contract_test.exs && mix verify.example_browser -- operator-accessibility.spec.ts` | yes | pending |
| 187-W0-MOTION | TBD | 1 | MOTION-01 | T-187-03 | Operator motion remains token-backed, transform/opacity-oriented, reduced-motion aware, and free of `transition: all`, unapproved keyframes, or animation dependencies | source + browser | `mix test test/threadline/operator_surface/style_contract_test.exs && mix verify.example_browser -- operator-motion.spec.ts` | yes | pending |
| 187-W0-SCREENSHOT | TBD | 1 | CLOSE-01 | T-187-04 | Screenshot status is reported from existing local-only screenshot and stress allowlist guards without expanding route/theme/viewport baselines | source + browser status | `mix verify.operator_stress && cd examples/threadline_phoenix/e2e && npx playwright test tests/operator-screenshot-regression.spec.ts --project=desktop-chromium --project=mobile-chromium` | yes | pending |
| 187-W0-CLOSEOUT | TBD | 2 | CLOSE-01 | T-187-05 | Verification and adversarial review artifacts record exact commands, results, proof limits, residual ownership, screenshot/Playwright status, and four-lens closeout review | artifact + command ledger | `rg -n "A11Y-01|A11Y-02|MOTION-01|DOC-01|CLOSE-01" .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-ADVERSARIAL-REVIEW.md` | no | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] Amend `test/threadline/operator_surface/theme_doc_contract_test.exs` to refute stale "no runtime theme toggle" docs and assert current server-posted picker literals.
- [ ] Repair `guides/operator-surface.md` so runtime theme picker, Storybook dev lane, stress route, mount/auth/export gates, Coverage selected-schema behavior, CSP expectations, and production exclusions match current source.
- [ ] Extend `operator-accessibility.spec.ts` or source contracts only if current proof misses a Phase 187 success criterion.
- [ ] Extend `operator-motion.spec.ts` or `style_contract_test.exs` only if current proof misses a Phase 187 success criterion.
- [ ] Create `187-VERIFICATION.md` after targeted commands run.
- [ ] Create `187-ADVERSARIAL-REVIEW.md` or an equivalent closeout artifact after proof exists.

Existing infrastructure covers the proof lanes; Wave 0 tightens docs truth and creates the final closeout artifacts.

---

## Manual-Only Verifications

Real assistive-technology UAT is manual-only and explicitly out of scope unless separately run. Phase 187 may record keyboard and accessibility-tree evidence, but must not claim real screen-reader certification.

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or explicit manual-only rationale.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency target is under 120 seconds for primary Mix sampling.
- [ ] `mix ci.all` is green or residual failures are classified in `187-VERIFICATION.md` with evidence they are inherited or outside Phase 187 scope.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 proof is green.

**Approval:** pending
