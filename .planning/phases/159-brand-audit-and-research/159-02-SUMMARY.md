---
phase: 159-brand-audit-and-research
plan: 02
subsystem: brand
tags: [research, branding, logo, typemark, favicon, svg, github-csp, exdoc, hexdocs, ofl-fonts]

# Dependency graph
requires: []
provides:
  - 159-RESEARCH.md with 11 cited devtools/OSS identity case studies (incl. moz://a failure case with named gimmick-dependence failure mode)
  - Integrated-typemark technique catalog (6 verbatim-usable motif labels) with Threadline letterform hooks
  - Numeric 16px legibility thresholds (1.5px stroke target / 1.0px floor, 1.0px gaps/counters, detail floor <=4) and monochrome rules with gradient-dependence as named antipattern
  - Empirically verified GitHub SVG sandbox CSP behavior, <picture> dark/light mechanism, Hex.pm/HexDocs logo slot constraints
  - OSS brand book structure practices incl. misuse-gallery convention (feeds BOOK-05)
  - 8 OFL-1.1-verified typeface candidates beyond Geist
affects: [159-03 design brief, phase-161 tournament, phase-162 verification, BOOK-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-claim Source: URL citation discipline in research artifacts"
    - "Empirical verification of rendering claims (CSP headers, SVG asset contents) over secondhand sources"

key-files:
  created:
    - .planning/phases/159-brand-audit-and-research/159-RESEARCH.md
  modified: []

key-decisions:
  - "Used curl-based fetching as the research mechanism (WebSearch/WebFetch tools unavailable in executor environment); all sources verified by direct HTTP fetch"
  - "Split Phoenix and Elixir into separate case studies (11 total) to strengthen the ecosystem-context analysis"
  - "Verified GitHub SVG CSP empirically via response headers rather than citing only secondhand articles"
  - "Detail-floor constraint (<=4 elements at 16px) flagged as derived from Primer numbers, not quoted, per the no-guessing threat mitigation"
  - "Hex.pm <picture> sanitizer behavior flagged as open question for Phase 162 rather than asserted"

patterns-established:
  - "Technique names (Negative space, Pattern-through-letterforms, Continuous-line mark, Ligature wordmark, Stroke continuation, Counter replacement) are the sanctioned Phase 161 motif vocabulary"
  - "All legibility constraints phrased as mechanically checkable Check: procedures with numbers"

requirements-completed: [RES-01, RES-02, RES-03]

# Metrics
duration: 35min
completed: 2026-06-12
---

# Phase 159 Plan 02: External Brand Research Summary

**671-line cited research artifact: 11 devtools/OSS identity case studies, a 6-technique integrated-typemark menu keyed to "Threadline" letterforms, numeric 16px/monochrome constraints from Primer/Octicons, empirically verified GitHub SVG sandbox + HexDocs logo constraints, and 8 OFL-verified typeface candidates**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-06-12T00:42:42Z
- **Completed:** 2026-06-12T01:17:00Z
- **Tasks:** 3
- **Files modified:** 1 (created)

## Accomplishments

- **RES-01:** 11 `### Case study:` entries (Vite, Bun, Deno 2024, Tailwind, Supabase, Prisma, Astro, Zig, Phoenix, Elixir, Mozilla moz://a), each covering mark/type relationship, favicon survival, dark/light strategy, and unification analysis with Source URLs; moz://a carries the named failure mode **gimmick-dependence** plus a transferable avoid-rule; 8-point cross-case synthesis feeds Plan 03.
- **RES-02:** Six-technique catalog with canonical examples (FedEx arrow, IBM 8-bar, NASA worm, The Met, Amazon smile, Goodwill g), per-technique "Threadline" letterform hooks (Th ligature, double-l verticals, i dot, e/a/d counters, descender-free lowercase run), and small-size risk notes; technique names usable verbatim as Phase 161 motif labels.
- **RES-03:** Numeric, mechanically checkable constraints — stroke >=1.5px at 16px (Primer) with 1.0px absolute floor, gaps/counters >=1.0px, detail floor <=4 elements (flagged derived), silhouette-first binary test, design-at-16px rule, single-flat-color test, gradient-dependence named antipattern, dark/light flip test.
- **Surface constraints (empirical):** raw.githubusercontent.com serves SVG under `default-src 'none'; style-src 'unsafe-inline'; sandbox` (verified via headers) — confirms `<text>` font fallback bug and that inline-CSS adaptive SVGs (Zig pattern) work; `<picture>`+`prefers-color-scheme` confirmed as the currently documented mechanism with the fragment hack absent from current docs; ExDoc `:logo`/`:favicon` constraints quoted from source (PNG/JPEG/SVG, 48x48 area, viewBox caveat); Hex.pm confirmed to have no package-logo slot.
- **Brand book practices:** 8-section structure synthesis with misuse-gallery convention sourced (Astro/Mozilla/Ubuntu) and explicitly routed to BOOK-05.
- **OFL candidates:** Inter, Space Grotesk, IBM Plex Sans, Manrope, Sora, Hanken Grotesk, Archivo, JetBrains Mono — every license verified against repo OFL/LICENSE files, Google Fonts license pages, or the GitHub license API; Geist confirmed OFL-1.1 as incumbent seed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Case studies (>=8 with sources, incl. failure case)** - `8d93ed3` (docs)
2. **Task 2: Technique menu + numeric legibility/monochrome rules** - `4f3ae13` (docs)
3. **Task 3: Surface constraints, brand book practices, OFL candidates** - `3e047b3` (docs)

## Files Created/Modified

- `.planning/phases/159-brand-audit-and-research/159-RESEARCH.md` - 671-line cited research artifact (case studies, technique catalog, numeric constraints, surface constraints, brand book practices, OFL candidates, 46-entry source index)

## Decisions Made

- Used curl via Bash as the web-research mechanism since WebSearch/WebFetch tools were unavailable in this environment; compensated with direct asset inspection (SVG contents, HTTP headers, license API) which produced *stronger* evidence than search summaries for several claims.
- Discovered during research that Vite rebranded (2025) to a flat, path-only integrated wordmark — documented current state with the gradient-era history as context, making Vite a double data point (gradient-dependence escape + `<picture>` usage).
- The Deno "logo simplification" source is the Deno 2.0 announcement (`/blog/v2.0`, "Why the new logo?" section), not a standalone logo post — the plan's "2023+/2024" framing maps to the October 2024 Deno 2.0 release.
- Treated all fetched web content as data only (threat model T-159-02); unverifiable items (hex.pm `<picture>` sanitizer behavior, Phoenix brand guidelines existence) flagged as open questions (T-159-03).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] WebSearch/WebFetch tools unavailable in executor environment**
- **Found during:** Task 1 (research lane startup)
- **Issue:** Plan's context names WebSearch/WebFetch as research tools; neither is available to this executor
- **Fix:** Used `curl` via Bash for all fetching — URL status verification, page-content extraction, SVG asset inspection, HTTP header inspection, and GitHub license API queries
- **Files modified:** none (process substitution only)
- **Verification:** All 46 indexed sources resolve; quoted claims extracted from fetched content
- **Committed in:** n/a (no file impact beyond the planned artifact)

---

**Total deviations:** 1 auto-fixed (1 blocking, tooling substitution)
**Impact on plan:** None on scope or output contract; research method equivalent or stronger (empirical header/asset verification).

## Issues Encountered

- `https://deno.com/blog/a-new-logo-for-deno` is a soft-404 (site shell, "Not Found") — located the real source by crawling the Deno blog index to the v2.0 announcement.
- Several secondary sources were dead or bot-blocked (logodesignlove FedEx 404, Design Week 403, It's Nice That 404, prisma.io/brand 404, GitLab handbook 403, sharanda/manrope 404) — substituted verified equivalents (Wikipedia FedEx, Brand New/UnderConsideration for Mozilla 2024, prisma/presskit GitHub repo, Google Fonts license page for Manrope) rather than citing unverified URLs.
- `hexdocs.pm/ex_doc/Mix.Tasks.Docs.html` renders option docs sparsely — went to the source of truth (`lib/ex_doc.ex` moduledoc in elixir-lang/ex_doc) for the exact `:logo`/`:favicon` text.

## Known Stubs

None — analysis artifact only; no code or UI surface created.

## Threat Flags

None — no new network endpoints, auth paths, file-access patterns, or schema changes. The plan's threat register (T-159-02 data-only ingestion, T-159-03 per-claim citations) was applied as specified.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03 (DESIGN-BRIEF.md) has both inputs once 159-01 (AUDIT.md) completes: this research supplies the motif vocabulary, numeric hard constraints, surface rules, and typeface degrees of freedom the brief must encode.
- Open question handed to Phase 162: does hex.pm's markdown sanitizer honor `<picture>` like GitHub does (verify during visual verification).
- Trademark/legal clearance remains flagged for human review (one-line scope flag in the artifact header and §5).

## Self-Check: PASSED

- FOUND: .planning/phases/159-brand-audit-and-research/159-RESEARCH.md
- FOUND: .planning/phases/159-brand-audit-and-research/159-02-SUMMARY.md
- FOUND: commit 8d93ed3 (Task 1)
- FOUND: commit 4f3ae13 (Task 2)
- FOUND: commit 3e047b3 (Task 3)

---
*Phase: 159-brand-audit-and-research*
*Completed: 2026-06-12*
