# Phase 159: brand-audit-and-research - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Approved milestone plan (`~/.claude/plans/have-to-compare-it-lexical-shore.md`), user decisions locked at plan approval

<domain>
## Phase Boundary

Produce a design brief grounded in (a) a senior-brand-designer pressure-test of the existing `brandbook/` and (b) external research on devtools/OSS identity work — so the Phase 161 tournament generates candidates from knowledge, not vibes. This phase writes analysis artifacts only (`AUDIT.md`, `RESEARCH.md`, `DESIGN-BRIEF.md` in the phase directory); it does not modify `brandbook/`, generate logos, or touch product code.

</domain>

<decisions>
## Implementation Decisions

### Audit (Plan A)
- Run the user's 14-section pressure-test framework against the existing `brandbook/` (brand-book.md, index.html, tokens.json/css, all logo SVGs, examples/*.svg, pressure-test.md). The 14 sections: executive judgment; brand DNA extraction; pressure-test scorecard (15 dimensions, 1–10); stress tests across real surfaces; gaps and risks by severity; recommended upgrades; design token spec; logo and mark system; visual examples/screenshot guidance; brand voice and microcopy; landing page and docs blueprint; repo-ready artifact plan; prioritized action plan; final quality gate.
- Every section gets a KEEP/TIGHTEN/REWORK/ADD/REMOVE verdict.
- Explicitly audit the current logo against: (1) the icon-left-of-text antipattern, (2) the baked-in "FOLLOW WHAT HAPPENED" subtitle in the primary lockup, (3) the SVG `<text>` portability bug (GitHub's SVG sandbox loads no fonts — wordmark silently falls back to generic sans).
- Stress-test matrix (AUD-02) executed against actual current assets: GitHub README render, Hex.pm, HexDocs, 16px favicon, dark mode, light mode, monochrome, social card.
- Do not flatter: preserve what is strong (voice, palette philosophy, tokens may be largely KEEP), be candid about the logo system.

### Research (Plan B)
- ≥8 devtools/OSS identity case studies with sources: Vite, Bun, Deno (2023+ simplification), Tailwind, Supabase, Prisma, Astro, Zig, Phoenix/Elixir's own marks; at least one failure/gimmick-risk case (e.g. Mozilla "moz://a"). Per case: mark/type relationship, favicon survival, dark/light strategy, what makes it feel unified.
- Integrated-typemark technique canon extracted as a reusable menu: negative space (FedEx), pattern-through-letterforms (IBM), continuous-line marks, ligature wordmarks, stroke continuation, counter replacement.
- Numeric small-size legibility thresholds for 16px favicons (minimum stroke weight relative to canvas, detail floor, silhouette-first tests) — testable constraints, not adjectives.
- Monochrome/one-color reproduction rules; gradient-dependence as a named antipattern.
- Rendering constraints of actual surfaces: GitHub README SVG sandbox behavior, `<picture>`/`#gh-dark-mode-only` dark-light tricks, Hex.pm/HexDocs logo slots.
- OSS brand book structure best practices (credible sections, misuse galleries).
- License-safe (OFL) typeface candidates beyond Geist for the free-exploration lanes.
- NOT researched: trademark/legal clearance (one-line flag for human review), motion/animation, print/CMYK/Pantone, merch, naming/tagline alternatives.

### Convergence (DESIGN-BRIEF.md)
- The round-1 generation contract: motif rules; hard constraints stated numerically (no subtitle in primary, no rectangular/rounded-rect container chips, must survive literal 16px and one-color rendering); degrees of freedom (OFL-safe typeface exploration and palette shifts allowed — fonts/colors are a seed, not a contract); the four archetype lanes (3 integrated typemarks, 3 unified lockups, 1 monogram/mark-led, 1 wordmark-only) each requiring a distinct named motif strategy.
- Every AUDIT.md REWORK/ADD item must be routed to a downstream v1.35 requirement or explicitly descoped with a reason.

### Structure
- Two parallel plans (audit + research are independent reads) converging in a third task/plan that writes DESIGN-BRIEF.md.
- All artifacts live in `.planning/phases/159-brand-audit-and-research/`.

### Claude's Discretion
- Exact ordering/format inside AUDIT.md and RESEARCH.md sections.
- Which additional case studies to include beyond the named set.
- How to capture stress-test evidence (described analysis vs. screenshots) — screenshots optional at this phase since Phase 162 owns final visual verification.

</decisions>

<specifics>
## Specific Ideas

- Current primary logo (`brandbook/logo-primary.svg`): squiggly line-with-dots mark at left + plain Geist `<text>` "Threadline" + mono `<text>` "FOLLOW WHAT HAPPENED" subtitle — this is the exact pattern the milestone exists to kill; the audit should name it plainly.
- Existing pressure-test.md scorecard becomes the baseline that Phase 162's rerun must meet or beat (BOOK-07).
- The user's original audit prompt emphasizes: "all killer no filler", "do not create churn for no reason", KEEP what is strong. Brand voice/positioning sections are believed strong; the logo system is the known weak point.

</specifics>

<deferred>
## Deferred Ideas

- Trademark/legal clearance — flagged for human review only.
- HexDocs/landing-page brand application — future milestones (HEXDOCS-BRAND-01, LANDING-01).

</deferred>

---

*Phase: 159-brand-audit-and-research*
*Context gathered: 2026-06-11*
