# Phase 183: Shell navigation and Home orientation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-28
**Phase:** 183-shell-navigation-and-home-orientation
**Areas discussed:** Implementation posture, Browser proof shape, Phase boundary, Planner discretion

---

## Implementation Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve and retune existing shell/Home substrate | Keep `UI.shell/1`, `SurfaceHeader.surface_header/1`, `StartLive`, scoped `.threadline-ui` CSS, native controls, route paths, feature gates, and test IDs. Retune only what is needed to satisfy UI-SPEC. | yes |
| Small private extraction inside current boundary | Allow private helper extraction only when it removes real duplication and preserves selectors, copy, routes, and no-public-API posture. | conditional |
| Larger internal shell/Home restructure | Rework markup/component structure more broadly if the current shell cannot satisfy perception/accessibility requirements. | no |
| New UI dependency / Tailwind / shadcn-style migration | Add a new component/tooling stack for shell/Home. | no |

**User's choice:** Discuss all areas and produce a one-shot, research-backed recommendation set with subagents.

**Notes:** Subagent research converged on preserving and retuning the existing Phoenix LiveView shell/Home implementation. The current code already has the semantic spine required by the UI-SPEC: shared private shell, topbar, native mobile disclosure, grouped nav, active state, native theme radios, Home task cards, system health, EF1 row-history launcher, EF4 correlation launcher, and saved views. Larger restructure and new UI dependencies were rejected as out of scope and inconsistent with the library boundary.

---

## Browser Proof Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Extend existing source, LiveView, and Playwright suites | Build on existing source contracts, LiveView tests, copy/style contracts, and browser UAT. | yes |
| Add a narrow Phase 183 browser supplement | Add a focused browser spec only if existing suites miss UI-SPEC perception cells. | conditional |
| New broad CI screenshot lane/matrix | Add route x theme x viewport screenshot baseline coverage for Phase 183. | no |

**User's choice:** Discuss all areas and produce a coherent recommendation.

**Notes:** Subagent research recommended layered verification. Current suites already cover grouped shell IA, Home task launcher behavior, native mobile nav, skip link, focus, overflow, earned flows, copy contracts, and responsive route checks. The recommended addition, if needed, is a narrow browser supplement for missing 320/375/768/1024/1280 perception cells and light/system assertions. Broad screenshots were rejected due flake, maintenance, and Phase 181/182 precedent.

---

## Phase Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Representative adjacent navigation tests only | Visit adjacent operator pages to prove global shell consistency, current state, focus, overflow, feature gates, route transition, and theme behavior. | yes |
| Shell-blocker exception policy | Permit adjacent-page edits only when a shell invariant fails on that route and the fix is shell-level or wrapper-level. | conditional |
| Broad adjacent page polish in Phase 183 | Polish Timeline/Coverage/detail/governance/export content while testing shell. | no |

**User's choice:** Discuss all areas and produce a recommendation that keeps the set coherent with project goals.

**Notes:** Subagent research recommended preserving the roadmap sequence. Phase 183 may navigate adjacent pages to prove the shared shell works globally, but content/workflow polish remains owned by Phases 184-186. The only exception is a strict shell blocker such as hidden nav, wrong `aria-current`, focus obscured by shell chrome, shell-caused overflow, feature-gate mismatch, or theme/topbar mismatch.

---

## Planner Discretion

| Option | Description | Selected |
|--------|-------------|----------|
| Exact task/file/test split in CONTEXT.md | Lock detailed task plan and file split inside context. | no |
| Constraints/outcomes only | Keep context broad and let planning infer details. | no |
| Hybrid: lock outcomes plus named surfaces, leave sequencing to planner | Lock user decisions, outcomes, canonical refs, code/test surfaces, footguns, and no-reask constraints; leave waves/tasks/helper extraction to `gsd-plan-phase`. | yes |

**User's choice:** User asked for recommendations so they do not have to think through individual choices.

**Notes:** Subagent research recommended the hybrid. CONTEXT.md now locks outcomes, decisions, refs, code surfaces, verification posture, and scope fences, while leaving executable plan decomposition to the planner. This prevents re-asking user decisions without turning context into a brittle pseudo-plan.

---

## Claude's Discretion

- User delegated all four areas to subagent-backed one-shot recommendations.
- Claude selected the coherent recommendation set after comparing local code, UI-SPEC, prior contexts, prompt corpus, brandbook, and external ecosystem references.
- Exact plan count, task wave order, private helper names, and test-file split remain planner discretion.

## Deferred Ideas

- Public component API.
- Root Tailwind/shadcn or external UI dependency migration.
- Broad screenshot matrix or visual-regression SaaS.
- Timeline, Coverage, detail, governance, export, accessibility, motion, and docs polish beyond Phase 183's shell/Home boundary.
