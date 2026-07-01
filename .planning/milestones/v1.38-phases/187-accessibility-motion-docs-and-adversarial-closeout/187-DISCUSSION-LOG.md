# Phase 187: Accessibility, motion, docs, and adversarial closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-30
**Phase:** 187-accessibility-motion-docs-and-adversarial-closeout
**Areas discussed:** Keyboard and APG proof envelope, Motion governance and reduced-motion proof, Operator docs truth source, Visual QA and screenshot boundary, Adversarial closeout evidence

---

## Keyboard and APG proof envelope

| Option | Description | Selected |
|--------|-------------|----------|
| Targeted keyboard/APG/accessibility-tree proof | Use existing Playwright/source contracts to prove keyboard operation, non-obscured focus, focus restoration, APG/native semantics, role/name structure, and accessibility-tree snapshots across primary flows. | ✓ |
| Add a broad axe scan or new dependency | Add generic automated accessibility scanning as a new proof layer. | |
| Claim real screen-reader certification | Treat browser accessibility-tree and keyboard proof as screen-reader certification. | |

**User's choice:** `[auto]` selected targeted keyboard/APG/accessibility-tree proof.
**Notes:** Current project posture already rejects real assistive-technology claims without actual UAT. Native controls remain native.

---

## Motion governance and reduced-motion proof

| Option | Description | Selected |
|--------|-------------|----------|
| Source contracts plus computed-style browser proof | Keep `style_contract_test.exs`, motion inventory, and `operator-motion.spec.ts` as the authority for tokenized motion and reduced-motion behavior. | ✓ |
| Manual visual review only | Verify motion subjectively during closeout. | |
| Introduce new animation patterns | Add new keyframes, page-specific animation, or motion dependencies. | |

**User's choice:** `[auto]` selected source contracts plus computed-style browser proof.
**Notes:** This preserves the existing no-`transition: all`, approved-keyframe, reduced-motion, and no-animation-library contracts.

---

## Operator docs truth source

| Option | Description | Selected |
|--------|-------------|----------|
| Repair docs to source truth | Align docs to current router/header implementation and tests, including the runtime server-posted theme picker. | ✓ |
| Preserve older mount-option-only theme prose | Leave docs saying there is no runtime theme toggle despite current source. | |
| Broad rewrite of all docs | Rework operator docs wholesale. | |

**User's choice:** `[auto]` selected repair docs to source truth.
**Notes:** `guides/operator-surface.md` currently conflicts with source on runtime theme behavior. Source has native `theme` radios and `Apply theme` posting to `/theme` with CSRF, cookie/plug resolution, no JS, and no localStorage.

---

## Visual QA and screenshot boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded screenshot status plus behavior proof | Report existing screenshot/stress guard status and use role/focus/overflow/theme/reduced-motion assertions elsewhere. | ✓ |
| Expand route x theme x viewport screenshots | Add a broad visual regression matrix for final closeout. | |
| Skip screenshot status | Rely only on source/browser behavior tests. | |

**User's choice:** `[auto]` selected bounded screenshot status plus behavior proof.
**Notes:** Existing screenshot baselines are local-only and platform-sensitive; stress screenshots stay ledger/allowlist-owned.

---

## Adversarial closeout evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Targeted verification plus residual ownership and adversarial review | Record commands, results, residual failures, Playwright/screenshot status, and four-lens adversarial review. | ✓ |
| Require every broad suite to be green before documenting closeout | Treat inherited broad-suite residuals as blockers regardless of phase ownership. | |
| Context-only closeout | Write the context and skip verification artifacts. | |

**User's choice:** `[auto]` selected targeted verification plus residual ownership and adversarial review.
**Notes:** The closeout should be explicit about what passed, what failed, and who owns any residuals.

## Claude's Discretion

- Exact plan count and task slicing.
- Whether to amend existing tests or add narrow Phase 187 tests.
- The exact closeout artifact shape, as long as it records verification evidence, screenshot/Playwright status, residual ownership, and adversarial review.

## Deferred Ideas

- Real assistive-technology UAT unless explicitly run.
- Broad screenshot matrix expansion.
- Public component API or public Storybook distribution.
- Runtime destructive redaction.
- New UI, motion, or accessibility scanning dependencies unless later explicitly scoped.
