---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
artifact: adversarial-review
created: 2026-06-20
status: passed
requirement: MOTION-02
---

# Phase 180 Adversarial Review

## D-12 Lens Review

| Lens | Review | Result |
|------|--------|--------|
| Aesthetics vs usability | Motion, focus, screenshots, contrast-adjacent semantics, and copy-state checks now favor operator task clarity over decorative churn. Screenshot baselines were refreshed only after the current rendered states and seeded discovery passed. | Pass |
| Dependency/architecture weight | No accessibility, axe, animation, or screenshot dependency was added. Evidence stays in existing ExUnit and Playwright harnesses. | Pass |
| Host integration friction | `examples/threadline_phoenix/config/test.exs` now disables LiveView origin checks only in test so dynamic e2e ports work. No production host contract changed. | Pass |
| Inaccessible custom behavior | Dialogs, drawers, dropdowns, tabs, comboboxes, alerts, statuses, focus entry, and focus restoration are covered by role/name/focus and ARIA snapshot checks. | Pass with bounded AT caveat |
| Generic-template drift | The stress route remains authenticated/dev-test-only and story/ledger driven. `coverage-schema-card-declutter` remains regression-only and did not reopen coverage layout scope. | Pass |
| Screenshot-only quality | Screenshot baselines are not the sole proof. Source contracts, semantic Playwright assertions, keyboard/focus checks, accessibility-tree snapshots, APG contracts, and stress/ledger tests all passed. | Pass |
| Route/API stability | Phase 178 route and socket/drop overlay checks passed inside the full browser matrix. Screenshot guard discovery was updated to current seeded `ticket_replies` rows instead of stale #4521 correlation assumptions. | Pass |
| Residual CI ownership | Current non-green `mix ci.all` failures are inherited Phase 179 doc/demo-seed failures. Phase 180-owned retention test failures were fixed and verified. | Pass |

## Findings

No blocking Phase 180-owned issue remains.

The main proof boundary is accessibility: Playwright's browser accessibility tree is a useful automation target, but it is not equivalent to NVDA, VoiceOver, JAWS, Narrator, TalkBack, or a human assistive-technology workflow.

## Follow-Through

- Keep `operator-accessibility.spec.ts` as the rendered accessibility and accessibility-tree evidence harness.
- Keep `operator-screenshot-regression.spec.ts` local/platform-sensitive; update baselines only when the current rendered surface has already passed semantic guards.
- Keep the inherited demo seed failures in the residual bucket until a demo-seed phase owns them.
