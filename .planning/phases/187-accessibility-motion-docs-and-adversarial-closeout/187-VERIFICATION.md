---
phase: 187-accessibility-motion-docs-and-adversarial-closeout
artifact: verification
verified: 2026-06-30T16:00:22Z
status: passed-with-classified-residuals
requirements:
  - A11Y-01
  - A11Y-02
  - MOTION-01
  - DOC-01
  - CLOSE-01
---

# Phase 187 Verification

## Verdict

Phase 187 targeted proof is complete with classified residuals.

The source/doc contracts, accessibility and motion browser proof, and stress/ledger guard are green. The standalone local screenshot regression command is non-green because all 10 desktop/mobile cells timed out in `beforeEach` while waiting for `#login_form` Email. `mix ci.all` is non-green in the example-app verification slice because inherited demo-seed/walkthrough/evidence tests fail; root credo, root ExUnit, and the coverage canary are green.

No screenshot baselines were updated, no masks were weakened, no tests were skipped or relabeled, no dependencies were added, and no real assistive-technology certification is claimed.

## Tiered Proof

| Tier | Evidence | Proves | Does Not Prove |
|------|----------|--------|----------------|
| Tier A: Source/doc contracts | `mix test test/threadline/operator_surface/theme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` | Runtime theme docs, Storybook/stress/export/CSP/private-component docs, Coverage docs, APG/native source contracts, motion/style/reduced-motion source contracts. | Browser rendering, screenshot stability, real screen-reader behavior. |
| Tier B: Rendered browser proof | `mix verify.example_browser -- operator-accessibility.spec.ts operator-motion.spec.ts` | Keyboard reachability, visible non-obscured focus samples, role/name state, accessibility-tree samples, default and reduced-motion computed style behavior across Chromium, desktop Chromium, and mobile Chromium. | Every possible host app, operating system, browser, data row, or real assistive-technology workflow. |
| Tier C: Stress and bounded visual status | `mix verify.operator_stress` and the standalone screenshot command listed below | Stress route auth/rendering/viewport/ledger allowlist status; screenshot command status for existing local-only cells. | Broad route x theme x viewport visual certification. The standalone screenshot command did not produce a visual diff result in this run because login setup timed out. |
| Tier D: Broad CI | `mix ci.all` | Root static checks and root ExUnit are green; broad example-app residuals are visible and classified. | A green full-repo release gate, because example-app residuals remain non-green. |

## Command Ledger

| # | Command | Result | Owner / Scope / Next Action |
|---|---------|--------|-----------------------------|
| 1 | `mix test test/threadline/operator_surface/theme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` | PASS. ExUnit seed `861367`; 131 tests, 0 failures; excluded `pgbouncer_topology: true`. | Phase 187 targeted source/doc proof. No action. |
| 2 | `mix verify.example_browser -- operator-accessibility.spec.ts operator-motion.spec.ts` | PASS. Playwright ran 51 tests: 51 passed in 50.1s across `chromium`, `desktop-chromium`, and `mobile-chromium`. Command printed an expired Hex auth-session warning and existing dependency advisory output before continuing. | Phase 187 targeted browser proof. No Phase 187 action. Expired Hex auth and dependency advisories are inherited environment/dependency-maintenance notices, not introduced by this plan. |
| 3 | `mix verify.operator_stress` | PASS with expected skips. Playwright ran 51 tests: 42 passed, 9 skipped in 17.0s. The skipped cells were project/packet-gated stress screenshot cells; desktop ledger-owned screenshots passed, and the bounded allowlist test passed. Command printed the same expired Hex auth-session warning and existing dependency advisory output before continuing. | Phase 187 stress/status proof. No action. |
| 4 | `cd examples/threadline_phoenix/e2e && npx playwright test tests/operator-screenshot-regression.spec.ts --project=desktop-chromium --project=mobile-chromium` | FAIL. 10 failed, 0 passed. Every desktop/mobile cell timed out after 120000ms in `test.beforeEach` while `locator('#login_form').getByLabel('Email').fill(...)` waited for the login form. Affected cells: Home workflow launchers, dense Timeline, row-history drawer, Exports readiness, and Retention safety on both desktop and mobile. | Classified residual: local screenshot-regression execution residual, not accepted visual diff or baseline churn. Scope: existing local-only screenshot command/bootstrap path. Impact: standalone screenshot cells did not prove visual stability in this run. Next action: rerun through the intended e2e bootstrap path or repair the standalone command/server readiness before accepting screenshot stability; do not update baselines or masks based on this run. |
| 5 | `mix ci.all` | FAIL. Root credo clean; root ExUnit seed `296849` finished 1184 tests, 0 failures, 1 excluded; coverage canary reported `threadline_ci_coverage_canary` covered. Example-app verification then failed: 109 tests, 9 failures; `mix ci.all` exited via `** (Mix) verify.example failed (2)`. | Classified residual: inherited example demo-seed/walkthrough/evidence residual, outside Phase 187 proof-artifact scope. Impact: broad CI is not green. Next action: separate demo-seed/walkthrough repair phase if broad CI closure is required. |

## Requirement Closure

| Requirement | Status | Evidence | Residual / Proof Limit |
|-------------|--------|----------|------------------------|
| A11Y-01 | Complete | Plan 187-02 commit `c32277ca` added source and rendered proof for APG/custom-control gaps. Command #1 passed `component_contract_test.exs`; command #2 passed `operator-accessibility.spec.ts` across Chromium, desktop Chromium, and mobile Chromium. | Automated APG/role/name/focus/accessibility-tree proof only. No real screen-reader certification. |
| A11Y-02 | Complete | Plan 187-02 verified keyboard-only paths, non-obscured focus, focus restoration, Coverage/theme picker reachability, Exports controls, row-history drawer dialog semantics, and stress widgets through `operator-accessibility.spec.ts`; command #2 passed. | Sampled browser automation does not prove every host integration or real AT announcement path. |
| MOTION-01 | Complete | Plan 187-02 verified `style_contract_test.exs` and `operator-motion.spec.ts` without source motion changes. Command #1 passed style contracts; command #2 passed default and reduced-motion Playwright checks. | Does not prove subjective animation preference; proves tokenized and reduced-motion behavior in the existing browser lane. |
| DOC-01 | Complete | Plan 187-01 commits `8c19f7e9` and `23d71d77` repaired `guides/operator-surface.md` and doc contracts for runtime theme picker, Storybook dev lane, stress route, auth/export gates, Coverage docs, CSP, production exclusions, and private-component boundaries. Command #1 passed all DOC-01 doc/source tests. | Docs truth is source-contract backed for pinned topics; broad docs outside the operator-surface contract were not re-audited. |
| CLOSE-01 | Complete with classified residuals | This artifact records exact command strings/results, Playwright and screenshot status, residual owner/impact/scope/next action, proof limits, and source-boundary confirmation. `187-ADVERSARIAL-REVIEW.md` covers the required four lenses. | Broad CI and the standalone screenshot command are non-green; closure is evidence/residual complete, not a claim that every broad gate is green. |

## Screenshot And Playwright Status

| Guard | Status | Details |
|-------|--------|---------|
| `operator-accessibility.spec.ts` | PASS | Included in command #2; 30 accessibility tests per Plan 187-02 summary, and part of 51 total tests in the combined browser run. Covers role/name/focus, keyboard reachability, non-color status labels, and accessibility-tree evidence. |
| `operator-motion.spec.ts` | PASS | Included in command #2; 21 motion tests per Plan 187-02 summary, and part of 51 total tests in the combined browser run. Covers default and reduced-motion computed behavior. |
| `operator-stress.spec.ts` via `mix verify.operator_stress` | PASS with expected skips | Command #3 passed 42 and skipped 9. Desktop ledger-owned screenshots passed; generic/mobile screenshot cells and selected Tier C packet remained skipped by the existing test gating. |
| `operator-screenshot-regression.spec.ts` standalone desktop/mobile command | FAIL | Command #4 failed all 10 local-only screenshot cells before screenshot comparison, at login setup. No baseline mismatch was accepted, and no baseline was updated. |

## Residual Classification

| Residual | Owner | Impact | Scope | Next Action |
|----------|-------|--------|-------|-------------|
| Standalone screenshot regression command timed out waiting for the login form on all desktop/mobile cells. | Local e2e screenshot command/bootstrap owner. | Existing local-only visual cells did not produce screenshot comparison evidence in this run. This blocks claiming screenshot stability from command #4. | Outside Phase 187 artifact-writing work; no Phase 187 source change touched screenshot tests, route paths, login form, or baselines. | Rerun with the intended server/bootstrap path or repair standalone readiness. Do not update baselines, masks, projects, or skips until semantic guards pass. |
| `mix ci.all` example-app failures: one `threadline.evidence.show` setup timeout, multiple missing demo-seed audit rows, missing `Export expired` copy, and walkthrough/demo-contract seed mismatches. | Demo-seed/walkthrough/evidence owner. | Broad CI remains non-green; release readiness cannot be inferred from Phase 187 targeted proof alone. | Inherited residual already consistent with prior Phase 181/182/183/180 residual history; outside this proof-only plan's files and prohibitions. | Separate demo-seed/walkthrough repair phase if broad CI green is required. |
| Expired Hex auth-session warning during browser/stress/example commands. | Local developer environment. | Non-blocking for public unchanged deps in these runs; private resource requests would fail if needed. | Environment notice, not a Phase 187 product/auth gate. | Re-authenticate with Hex outside this plan if private package access is needed. |
| Existing dependency advisory output for unchanged packages during dependency resolution. | Dependency maintenance/security triage owner. | Security posture warning for existing dependency set; commands continued. | Not introduced by Phase 187; package changes are prohibited in this plan. | Handle through a dedicated dependency/security upgrade plan. |

## Source Boundary Confirmation

Phase 187 Plan 03 created planning evidence only. It did not change schemas, packages, route paths, stable `data-testid`s, auth/export/capture/query semantics, public component APIs, Tailwind/shadcn posture, production Storybook/stress routes, screenshot baselines, or Playwright masks.

Files intentionally created by Plan 03:

- `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md`
- `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-ADVERSARIAL-REVIEW.md`

## Proof Limits

- Automated accessibility-tree snapshots, role/name assertions, keyboard operation, focus visibility, and source contracts do not equal NVDA, VoiceOver, JAWS, Narrator, TalkBack, or human assistive-technology UAT.
- The screenshot status is reported honestly: stress/ledger status passed, while the standalone local screenshot regression command failed before comparison. No real visual stability claim is made from that failed command.
- `mix ci.all` is not green. Phase 187 closes CLOSE-01 by recording the exact broad CI residuals and ownership, not by treating broad CI as passed.
- Dependency advisory output was observed but not remediated because package changes are outside this plan.

## Evidence Sources

- `187-01-SUMMARY.md`: DOC-01 source truth and doc-contract evidence, task commits `8c19f7e9` and `23d71d77`.
- `187-02-SUMMARY.md`: A11Y-01, A11Y-02, and MOTION-01 proof closure, task commit `c32277ca`.
- `180-VERIFICATION.md`: prior closeout shape for tiered proof, command ledger, residual classification, and AT proof limits.
- `186-VERIFICATION.md`: current v1.38 targeted verification shape and residual honesty.

---

Verified: 2026-06-30T16:00:22Z
