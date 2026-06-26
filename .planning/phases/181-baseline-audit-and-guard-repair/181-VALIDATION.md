---
phase: 181
slug: baseline-audit-and-guard-repair
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-26
---

# Phase 181 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir 1.19.5; Playwright Test 1.60.0 |
| **Config file** | `mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_router_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Targeted source slice: under 60 seconds; full suite depends on example-app/E2E setup |

---

## Sampling Rate

- **After every task commit:** Run the targeted ExUnit slice for touched guard/source files, plus `rg` scans for stale selectors or retired contracts when docs/tests are edited.
- **After every plan wave:** Run the source-contract slice and the relevant targeted Playwright specs for any rendered `/audit` behavior touched in that wave.
- **Before `/gsd:verify-work`:** Run `mix ci.all`; if inherited residual failures remain, `181-VERIFICATION.md` must classify each residual and prove it is not caused by Phase 181.
- **Max feedback latency:** Keep task-level feedback under 60 seconds whenever possible; move slower browser evidence to wave or phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 181-W0-01 | 181-01 | 1 | BASE-01 | T-181-01 | Current `/audit` routes remain host-authenticated and audit packet identifies stale selectors/tests before polish starts | browser + docs | `OPERATOR_SCREENSHOT_DIR=.planning/phases/181-baseline-audit-and-guard-repair/screenshots ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshots.spec.ts` plus stale selector `rg` scans | E2E spec exists; packet docs pending | pending |
| 181-W0-02 | 181-02..181-05 | 1-4 | BASE-02 | T-181-02 | Ledger, stress registry, screenshot allowlist, route/source contracts, and projection docs do not lower ratchet scores or drop stories silently | unit + browser | `mix test test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_router_test.exs && mix verify.operator_stress` | yes | pending |
| 181-W0-03 | 181-01, 181-08 | 1, 7 | BASE-03 | T-181-03 | Storybook, stress route, nav IA, a11y, motion, and operator persona decisions are linked for later page phases | docs/source | `rg -n "PhoenixStorybook|/audit/__stress|APG|WCAG|operator JTBD|persona|motion" .planning/phases/181-baseline-audit-and-guard-repair/*.md` | context/research exist; final packet docs pending | pending |
| 181-W0-04 | 181-03, 181-06, 181-07, 181-08 | 2, 5-7 | BASE-01, BASE-02 | T-181-01..03 | Example-app E2E/snapshot changes satisfy the local Phoenix app precommit contract | example app | `cd examples/threadline_phoenix && mix precommit` | example app exists | pending |
| 181-GATE | 181-08 | final | BASE-01, BASE-02, BASE-03 | T-181-01..03 | Closeout does not hide broken rendered truth behind stale or ambiguous guards | full suite + evidence | `mix ci.all` or documented residual classification in `181-VERIFICATION.md` | full suite command exists | pending |

---

## Wave 0 Requirements

- [ ] `.planning/phases/181-baseline-audit-and-guard-repair/181-BASELINE-AUDIT.md` - page/JTBD matrix, visible issues, risk taxonomy, and later-phase owner.
- [ ] `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md` - screenshot lane inventory, viewport/theme evidence, local/CI distinction, and stale/missing baseline notes.
- [ ] `.planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md` - stale selector/test/source-contract findings, repairs, retired contracts, and rationale.
- [ ] `.planning/phases/181-baseline-audit-and-guard-repair/181-VERIFICATION.md` - BASE-01..03 closeout evidence and any residual CI classification.

Existing infrastructure covers the source-contract and E2E test harnesses; Wave 0 creates the phase packet artifacts that those harnesses will prove.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Current rendered truth packet review | BASE-01 | Browser automation can capture routes and screenshots, but issue taxonomy and later-phase ownership require human classification. | Review `181-BASELINE-AUDIT.md` against the Phase 181 page/JTBD matrix and confirm every `/audit` page has route/render evidence, issue taxonomy, and owner/disposition. |
| Screenshot promotion decision | BASE-01, BASE-02 | Phase 181 should inventory screenshots; committing PNG baselines is a stability/product decision. | Confirm `181-SCREENSHOT-INVENTORY.md` states which screenshots are local evidence, which are CI allowlist cells, and whether any generated PNGs are intentionally committed. |
| Accessibility proof boundary | BASE-03 | Automated role/name/focus checks cannot prove real assistive-technology UAT. | Confirm `181-VERIFICATION.md` distinguishes automated a11y evidence from deferred AT/user verification and links the Phase 180 a11y evidence where relevant. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or explicit manual-only rationale.
- [ ] Sampling continuity: no three consecutive implementation tasks can land without targeted source or rendered evidence.
- [ ] Wave 0 covers all missing packet artifacts.
- [ ] No watch-mode flags are used in verification commands.
- [ ] Task feedback latency stays under 60 seconds where possible.
- [ ] `mix ci.all` is green, or all residual failures are classified in `181-VERIFICATION.md` with evidence they are inherited and unrelated.

**Approval:** pending
