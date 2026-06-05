# Requirements: Threadline v1.32 Brand System Foundation

**Defined:** 2026-06-05
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why - without the developer having to remember to opt in.

## v1.32 Requirements

### Brand Strategy And Audit

- [x] **BRAND-AUDIT-01**: The existing brand book, prior research, README positioning, operator-surface token system, and the reverted one-shot brandbook commit are critically audited before final assets are accepted. Completed in Phase 145.
- [ ] **BRAND-DNA-01**: The milestone captures Threadline's brand essence, audience, technical promise, visual metaphor, voice principles, anti-traits, and OSS/Elixir ecosystem fit in durable source docs.

### Implementation-Ready Brand System

- [ ] **BRAND-TOKENS-01**: Token artifacts define raw palette values and semantic roles for dark, light, interaction states, status states, code blocks, callouts, focus, typography, spacing, radius, borders, and modest elevation.
- [ ] **BRAND-LOGO-01**: Logo and mark SVG assets are simple, editable, accessible, monochrome-capable, transparent-background-safe, and usable at small sizes.
- [ ] **BRAND-HTML-01**: The static HTML brandbook is complete, navigable, responsive, and usable directly from the repository without a build step or network dependency.
- [ ] **BRAND-EXAMPLES-01**: The brandbook includes only useful source-controlled visual specimens: palette, typography, components, README header, docs page, landing hero, terminal style, and social preview.

### Voice, Repo Hygiene, And Verification

- [ ] **BRAND-VOICE-01**: The brand system includes ready-to-use technical copy and UX microcopy examples for README/docs/marketing/error/success/warning/release surfaces without hype or compliance overreach.
- [ ] **BRAND-REPO-01**: All brand artifacts live under `brandbook/`, remain text/SVG-first, avoid duplicate font binaries and large raster assets, and document what should and should not be committed.
- [ ] **BRAND-QA-01**: Verification records cover JSON parsing, SVG XML parsing, browser rendering at desktop and mobile sizes, representative WCAG AA contrast pairs, image load state, file-size budget, and clean source-control boundaries.

## Out of Scope

| Feature | Reason |
|---------|--------|
| README rewrite or HexDocs rollout | The user selected "brand system only"; docs rollout should be a later milestone using the finished system. |
| Runtime operator surface UI changes | v1.31 already froze the operator surface token contract; this milestone may reference it but must not mutate product UI. |
| Marketing site implementation | The user selected "brand system only"; a site rollout would require separate IA, content, hosting, and browser QA scope. |
| PNG/PDF export batches | SVG/HTML/Markdown/JSON/CSS are the source artifacts; raster exports should be generated only for a specific downstream channel. |
| Trademark/legal clearance | Human review is required for legal/trademark risk; the milestone can only flag the need. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRAND-AUDIT-01 | Phase 145 | Complete |
| BRAND-DNA-01 | Phase 146 | Pending |
| BRAND-TOKENS-01 | Phase 147 | Pending |
| BRAND-LOGO-01 | Phase 147 | Pending |
| BRAND-HTML-01 | Phase 148 | Pending |
| BRAND-EXAMPLES-01 | Phase 148 | Pending |
| BRAND-VOICE-01 | Phase 146 | Pending |
| BRAND-REPO-01 | Phase 148 | Pending |
| BRAND-QA-01 | Phase 149 | Pending |

**Coverage:**
- v1.32 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-06-05*
*Last updated: 2026-06-05 after v1.32 milestone start*
