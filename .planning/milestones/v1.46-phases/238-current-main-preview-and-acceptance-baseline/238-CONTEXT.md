# Phase 238: Current-main preview and acceptance baseline — Context

**Captured:** 2026-10-08
**Status:** Ready for planning
**Provenance:** Carried forward from the maintainer's approved v1.46 scope, requirements and roadmap, PRODUCT.md, Impeccable initialization, and UI-MILESTONE-PREFLIGHT.md. This records existing decisions; no new discovery interview or approval is required. The maintainer explicitly invoked `$gsd-plan-phase 238` after approving the roadmap and has authorized following researched recommendations.

<domain>
## Phase Boundary

Deliver UIB-01 and UIB-02: a safely seeded, reproducible current-main preview and source-bound captures for all eleven operator routes, plus an exhaustive acceptance inventory and ranked findings/dispositions before UI fixes. This is baseline evidence and implementation preparation. Refinement belongs to Phases 239–242; integrated candidate verification belongs to 243.
</domain>

<decisions>
## Implementation Decisions

### Source and evidence identity
- **D-01:** Preserve the dirty planning checkout and all unrelated edits. Later execution must establish an isolated current-main context using the supported workflow, carrying the approved planning, PRODUCT.md and Impeccable context. Do not run source implementation from the stale milestone/v1.44 branch, switch/reset this checkout, or silently treat a missing isolation adapter as permission to do so.
- **D-02:** Record the actual source SHA, relevant diff, served-asset identity, safe fixture identity and capture conditions for the baseline. Historical screenshots and source candidates are leads, not reproduced visual defects. Refresh main at execution; the preflight SHA is historical evidence, not a permanent pin.

### Baseline completeness and review
- **D-03:** Inventory all eleven existing routes, shared primitives, unique controls and material states. Every item needs a ranked rendered finding or explicit evidence-linked coverage disposition; do not silently drop inaccessible states or claim a source-only check proves rendered behavior.
- **D-04:** Include full-shell captures and representative desktop, intermediate and narrow/mobile widths; Light, Dark and System; actual 200% browser zoom; keyboard/touch focus; pending/empty/failed/denied/completed and offline/reconnect conditions where applicable. Use a bounded, risk-based matrix and explicit limitations rather than an unbounded Cartesian product.
- **D-05:** Review with agent judgment plus repeatable checks. Normal verification must not overwrite reference baselines. No paid critic revival, new paid API loop, or routine maintainer UAT; a source/asset mismatch blocks visual classification. Keep proof honest about browser and capability limits.

### Product and scope contracts
- **D-06:** Engineers and support/on-call operators have equal UI priority. Use familiar investigation/operations flows, canonical domain nouns, readable hierarchy, exact evidence access and the existing Threadline identity and private Phoenix/HEEx primitives. Impeccable is code-first; purposeful Kowalski motion guidance informs later refinements. Do not rerun initialization or prescribe an unseen redesign during this baseline phase.
- **D-07:** Preserve public 1.x APIs, routes, host authentication/authorization, tenant scope, redaction and Phoenix optionality. Do not expand backend capabilities, create a public component package or migrate frameworks. Preview fixtures must be synthetic/local and must not touch user or production data.
- **D-08:** Link findings to the owning approved phases and preserve existing acceptance conditions across journeys. Source candidates from preflight must be confirmed or explicitly dispositioned. No push, publication, new spend or release grant is implied by this planning request.

### the agent's Discretion
- Select the smallest reusable existing preview/capture tooling and fixture strategy after inspecting current main.
- Choose evidence formats, bounded capture ordering, risk rankings and local verification commands, provided completeness and provenance remain checkable.
- Use existing project checks and regression infrastructure; add only baseline tooling/contracts needed to prevent stale evidence or silent omissions.
</decisions>

<specifics>
## Specific Inputs

- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` (UIB-01, UIB-02).
- `PRODUCT.md`, `.impeccable/config.json`, `.impeccable/live/config.json`.
- `.planning/UI-MILESTONE-PREFLIGHT.md` and `.planning/research/SUMMARY.md` contain completed sibling research and the current UI scope. Adjacent v1.45 API research is historical, not fresh UI scope.
- `prompts/audit-lib-domain-model-reference.md`, `prompts/threadline-elixir-oss-dna.md`, `prompts/Threadline Brand Book.txt`.
- Route mount `/audit`: home, timeline, transaction, direct row history, transaction row-history drawer, actor, coverage, evidence, exports, redaction policy, retention policy. Theme/export endpoint seams belong in the inventory.
- Anticipate Scrypath's post-closeout focus/highlight, loading-feedback/hook, cascade and navigation issues; Accrue/Mailglass's actual-zoom, identity, CI-discovery and baseline-overwrite lessons. Evidence and maturity qualifiers are in the preflight; do not label unfinished sibling work as shipped.
</specifics>

<deferred>
## Deferred Ideas

- Visual fixes and token/component/copy refinements before baseline capture and classification.
- New backend capabilities, rebranding, framework changes, paid judging and a new release.
- Unsupported browser/device claims without evidence; composite-key row exploration and unbounded-history backend changes.
</deferred>
