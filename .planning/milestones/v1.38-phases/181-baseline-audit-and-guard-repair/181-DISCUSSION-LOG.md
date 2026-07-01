# Phase 181: Baseline audit and guard repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-26
**Phase:** 181-Baseline audit and guard repair
**Areas discussed:** Baseline evidence shape, guard repair boundary, audit matrix strictness, research/context record

---

## Baseline Evidence Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Audit packet | Page/JTBD matrix, screenshots, stale selectors, issue taxonomy, and guard disposition | yes |
| Screenshot inventory only | Fast visual baseline, but weak on selectors, routes, JTBD, a11y, and ledger drift | no |
| Selector/test cleanup list only | High maintainer DX but insufficient rendered truth | no |
| Broad narrative audit | Useful rationale but hard to verify and easy to stale | no |

**User's choice:** Discuss/consider all, research with subagents, and synthesize one recommendation set so the user does not need to decide piecemeal.

**Notes:** Research recommended a baseline audit packet as the only option that satisfies BASE-01, BASE-02, and BASE-03 together. Narrative audit may exist as rationale inside the packet but is not the packet shape.

---

## Guard Repair Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Strict audit-only | Inventory failures but avoid touching code/tests now | no |
| Bounded repair-now | Patch broken guardrails when they restore accepted invariants | yes |
| Page redesign now | Use baseline phase to improve IA/layout/copy directly | no |

**User's choice:** Favor the researched coherent recommendation with software architecture, DevOps/SRE, DX, and least-surprise lenses applied.

**Notes:** Repairs are allowed for stale selectors, source contracts, stress fixtures, ledger/projection freshness, screenshot allowlist references, and minimal additive semantic hooks. Page polish remains deferred to later phases.

---

## Audit Matrix Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Full pixel matrix | Page x path x theme x viewport screenshots in CI | no |
| Representative rendered slices | Full manifest/source contracts plus targeted Chromium checks | yes |
| CI allowlist only | Keep only the current small screenshot allowlist | no |
| Manual screenshot packet only | Human review without enforcement | no |

**User's choice:** Use a rigorous but pragmatic strategy that preserves trust without creating flake or review fatigue.

**Notes:** Research recommended Tier A source/CI contracts, Tier B representative rendered CI slices, and Tier C local/human screenshot packet. Full pixel matrix is reserved for local/nightly/adversarial sweeps when a page family stabilizes.

---

## Research/Context Record

| Option | Description | Selected |
|--------|-------------|----------|
| Compact context-decision record | Personas, JTBD, nouns/events/verbs, pillars, guardrails, canonical refs | yes |
| Deep strategy brief | Full research/persona spec and external comparison | no |
| Baseline matrix only | Actionable evidence, but not enough design/JTBD context | no |
| Pointer-only source index | Minimal duplication, but leaves ambiguity | no |

**User's choice:** Include prompts-subdir research where applicable, prefer current brandbook if newer, apply UI/UX/design/API/DX/persona lenses, and synthesize expert recommendations.

**Notes:** Context captures four personas, five JTBD, canonical domain nouns, UI verbs/events, design pillars, and specific guardrails for operator UX, brand, accessibility, performance, motion, and Phoenix/LiveView DX.

---

## Claude's Discretion

- User requested a one-shot researched recommendation set and explicitly delegated tradeoff synthesis.
- Subagents researched the four gray areas in parallel; final decisions were synthesized into `181-CONTEXT.md`.

## Deferred Ideas

- Storybook implementation, page IA/visual polish, Coverage flow redesign, detail/governance/export cleanup, and closeout verification stay in their roadmap phases.
- Public component API, root Storybook dependency, runtime destructive redaction, production stress/story route, Tailwind/shadcn migration, and capture/query/auth semantic changes remain out of scope.
