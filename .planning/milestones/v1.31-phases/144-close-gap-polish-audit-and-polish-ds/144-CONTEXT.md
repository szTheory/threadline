# Phase 144: close-gap-polish-audit-and-polish-ds - Context

**Gathered:** 2026-06-04T20:44:59Z
**Status:** Ready for planning
**Mode:** advisor research across all gray areas, with local prompt corpus review

<domain>
## Phase Boundary

Phase 144 closes the two remaining v1.31 milestone audit blockers:

- `POLISH-AUDIT`: baseline audit artifacts exist, but the owning Phase 134 ledger and verification record are missing.
- `POLISH-DS`: Phase 136 completed only the dark token/interaction contrast foundation; the design-system catalog, primitive consolidation, and token freeze remain incomplete.

This phase is trust and traceability closure for the already-built v1.31 operator surface. It must not add new operator features, routes, backend queries, schema changes, demo-app business logic, Tailwind/build tooling, light mode, a theme toggle, or speculative earned flows.

</domain>

<decisions>
## Implementation Decisions

### Baseline Audit Ledger Closure

- **D-01:** Close `POLISH-AUDIT` through an explicit Phase 144 closure/errata record that verifies the existing Phase 134-labeled baseline artifacts against the original Phase 134 success criteria.
- **D-02:** Do not fabricate a missing Phase 134 execution history. If any Phase 134 backfill artifact is created, it must be labeled as reconstructed/verified during Phase 144, not as original in-time phase work.
- **D-03:** Preserve the original roadmap intent that Phase 134 produced the baseline for downstream phases. Do not rewrite history so the baseline concept appears to have originated in Phase 144.
- **D-04:** Bind the closure record to concrete evidence: `v1.31-UI-AUDIT.md`, the 24 baseline screenshots, the 24 final screenshots, `143-SCREENSHOT-DIFF.md`, `143-AUDIT-CLOSURE.md`, and the milestone audit gap.
- **D-05:** Update requirement/roadmap/state traceability only enough to make the closure legible: `POLISH-AUDIT` is satisfied by Phase 144 verification of Phase 134 baseline artifacts.

### Design-System Freeze Contract

- **D-06:** Close `POLISH-DS` with source-first final consolidation followed by documentation and freeze, not documentation-only freeze of accidental drift.
- **D-07:** Keep the architecture aligned with the existing Phoenix-optional mounted operator surface: BEM `.tl-*` classes and `--tl-*` tokens in `lib/threadline/operator_surface/style.ex`; no Tailwind, no build step, no light/system theme, no external design-system dependency.
- **D-08:** Finish the missing design-system source of truth at `.planning/milestones/v1.31-DESIGN-SYSTEM.md`. It must catalog canonical, deprecated, and consolidated `.tl-*` classes; token scales; status/verdict/operation color semantics; action hierarchy; empty/error states; table/responsive rules; copy affordances; drawer/subview patterns; motion; focus/accessibility rules; and anti-patterns.
- **D-09:** The token freeze must be explicit and test-backed. Strengthen `test/threadline/operator_surface/style_contract_test.exs` with narrow source contracts for the frozen token/class catalog rather than broad brittle screenshot/prose assertions.
- **D-10:** Final source consolidation should be narrow and compatibility-preserving. Prefer consolidating status/verdict/chip roles, value/KV/diff/copy primitives, and docs/tests over introducing a public Phoenix component API.
- **D-11:** A formal reusable component API is deferred. Phoenix function components with attrs/slots are idiomatic when reusable markup becomes public API, but Phase 144 should not turn the mounted `/audit` surface into a general UI component library.

### Ecosystem And Prompt-Corpus Guidance

- **D-12:** Treat verification as a product surface. Three-source traceability should align: requirements checkbox, verification record, and summary/frontmatter evidence.
- **D-13:** Keep Threadline native to Phoenix/Ecto/PostgreSQL: explicit docs, SQL-readable operator language, stable `mix verify.*` entrypoints, and example-app/browser proof over hidden ceremony.
- **D-14:** Preserve the Threadline brand promise: "follow what happened." The close-gap artifacts should make baseline evidence, design-system contracts, and final UI deltas followable without maintainer memory.
- **D-15:** Use persona/JTBD artifacts to explain why existing primitives and flows are frozen, not to add new flows. Phase 140 already shipped the earned flow set.
- **D-16:** Accessible dark-first behavior is part of the design system. The catalog must encode contrast, focus-visible, ARIA/non-color status encoding, reduced motion, and least-surprise hover/focus/disabled states as normative rules.

### Folded Todos

- **Capture direct demo and UI polish** (`2026-06-01-capture-direct-demo-and-ui-polish.md`) is folded as context only. The relevant baseline is now the v1.31 polish milestone and Phase 144 should reconcile remaining audit/design-system deltas without widening product scope.

### the agent's Discretion

Downstream planner may choose exact plan slicing, but should bias to:

- one audit-ledger closure slice for `POLISH-AUDIT`;
- one design-system source/catalog/freeze slice for `POLISH-DS`;
- one verification/metadata slice that reruns the milestone audit and updates requirement status cleanly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 144 And Milestone Gate

- `.planning/ROADMAP.md` - Phase 144 entry and original Phase 134 / Phase 136 success criteria.
- `.planning/REQUIREMENTS.md` - `POLISH-AUDIT` and `POLISH-DS` requirement status.
- `.planning/STATE.md` - current milestone position and accumulated decisions.
- `.planning/v1.31-MILESTONE-AUDIT.md` - blocking gap report that created Phase 144.

### Baseline Audit Closure

- `.planning/milestones/v1.31-UI-AUDIT.md` - Phase 134 baseline audit, state matrix, finding IDs, ownership map.
- `.planning/milestones/v1.31-screenshots/baseline/` - 24 durable baseline PNGs.
- `.planning/milestones/v1.31-screenshots/final/` - 24 durable final PNGs.
- `.planning/phases/143-accessibility-consistency-sweep-regression/143-SCREENSHOT-DIFF.md` - baseline-to-final delta explanation.
- `.planning/phases/143-accessibility-consistency-sweep-regression/143-AUDIT-CLOSURE.md` - finding-by-finding closure registry.
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` - durable screenshot capture matrix.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` - screenshot regression guard.

### Design System Closure

- `.planning/phases/136-design-system-hardening/136-CONTEXT.md` - original Phase 136 boundary and remaining work.
- `.planning/phases/136-design-system-hardening/136-UI-SPEC.md` - design-system contract including catalog/freeze expectations.
- `.planning/phases/136-design-system-hardening/136-VERIFICATION.md` - partial verification and missing criteria.
- `.planning/phases/136-design-system-hardening/136-01-SUMMARY.md` - completed dark token/interaction contrast foundation and remaining work.
- `lib/threadline/operator_surface/style.ex` - current token and `.tl-*` primitive source of truth.
- `test/threadline/operator_surface/style_contract_test.exs` - existing source-contract test pattern.
- `lib/threadline/operator_surface/presentation.ex` - shared presentation helpers used by polished screens.
- `lib/threadline/operator_surface/components/surface_header.ex` - nav/status primitive usage.
- `lib/threadline/operator_surface/live/*.ex` - operator LiveViews that consume `.tl-*` primitives.

### Prior Phase Contracts To Preserve

- `.planning/phases/137-prove-cluster-polish/137-VERIFICATION.md` - Prove cluster primitive usage and browser proof.
- `.planning/phases/138-find-cluster-polish/138-VERIFICATION.md` - Find cluster primitive usage and browser proof.
- `.planning/phases/139-orientation-hub-home-nav/139-VERIFICATION.md` - Home/nav IA proof.
- `.planning/phases/140-earned-new-flows/140-VERIFICATION.md` - earned-flow proof; do not add EF6.
- `.planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` - frozen motion inventory.
- `.planning/phases/142-responsive-mobile-first/142-VERIFICATION.md` - responsive matrix proof.
- `.planning/phases/143-accessibility-consistency-sweep-regression/143-VERIFICATION.md` - accessibility and regression proof.
- `.planning/milestones/v1.31-PERSONAS-IA.md` - persona/JTBD/earned-flow IDs.

### Prompt Corpus Inputs

- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` - audit-platform product strategy and ecosystem lessons.
- `prompts/threadline-elixir-oss-dna.md` - verification, docs/contracts, examples, and milestone hygiene principles.
- `prompts/Threadline Brand Book.txt` - dark-first brand, voice, and "follow what happened" positioning.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - native Phoenix/Ecto/Plug architecture and state-placement lessons.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` - LiveView UI architecture, function-component guidance, URL state, streams, forms, testing.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` - OSS library DX, explicit APIs, docs, option contracts, supervision ergonomics.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/threadline/operator_surface/style.ex`: owns dark-first `--tl-*` tokens, `.tl-*` class families, motion/reduced-motion rules, responsive table/card behavior, focus ring, control sizing, and shared button/chip/empty/table/copy/drawer primitives.
- `test/threadline/operator_surface/style_contract_test.exs`: already verifies dark-only behavior, token seams, motion inventory, responsive breakpoints, accessibility/status chip properties, and primitive drift. This is the right place for Phase 144 freeze contracts.
- `lib/threadline/operator_surface/presentation.ex`: centralizes display helpers such as refs, status labels, value treatment, and remediation copy. Use this for source consolidation before adding new CSS families.
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts`: captures durable screenshot matrices when `OPERATOR_SCREENSHOT_DIR` is set.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts`: current lightweight screenshot guard, already aligned with Phase 143.

### Established Patterns

- Operator UI is embedded in the library, Phoenix-optional, and scoped under `.threadline-ui`; keep compile/runtime boundaries compatible with capture-only adopters.
- UI state that users share or revisit belongs in URLs where already established; Phase 144 should not replace this with server-only state.
- Tests should prefer source contracts and focused behavior/browser checks over broad brittle visual snapshots.
- Dark-first brand is locked. Improvements happen through tokens, contrast, and primitive rules, not theme expansion.
- Copy affordances use existing dependency-free `[data-tl-copy]` and `.tl-copy` behavior.

### Integration Points

- Phase 144 planning should update planning artifacts, design-system docs, narrow source contracts, and only the smallest necessary CSS/presentation call sites.
- Verification should rerun the focused source contracts and the relevant browser/screenshot guard, then rerun the milestone audit.
- Requirement closure must update traceability artifacts without erasing the true chronology of missing Phase 134 ledger work.

</code_context>

<specifics>
## Specific Ideas

- Recommended cohesive path: "Phase 144 verifies the baseline, completes the design-system source of truth, freezes the tokens/classes, and reruns the milestone audit."
- `POLISH-AUDIT` should be closed by explicit provenance, not retroactive fiction.
- `POLISH-DS` should be closed by source-first consolidation plus catalog/freeze, not by documentation-only acceptance of drift.
- UX/design-system emphasis: conventional components, visible hover/focus/disabled states, accessible non-color status encoding, calm dark-first brand, precise microcopy, no flashy redesign.
- DX emphasis: future maintainers should know what `.tl-*` classes are canonical, which are deprecated/consolidated, which tokens are frozen, and which verification command catches drift.

</specifics>

<deferred>
## Deferred Ideas

- A formal public Phoenix component API for Threadline operator primitives. Useful later if the UI primitives become a host-facing extension surface, but too broad for Phase 144.
- Light/system theme support. Explicitly out of scope for v1.31 and contrary to the locked dark-first brand.
- New earned flows beyond EF1-EF5. Existing Phase 140 flow set remains authoritative.
- Broader true-empty/scoped seed variants (`F-205`) and snapshot delta-highlighting (`F-1004`) remain future product enhancements, not blockers for this close-gap phase.

</deferred>

---

*Phase: 144-close-gap-polish-audit-and-polish-ds*
*Context gathered: 2026-06-04T20:44:59Z*
