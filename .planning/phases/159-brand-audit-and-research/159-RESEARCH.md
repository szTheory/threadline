# 159-RESEARCH.md — External Research: Devtools/OSS Identity Work

**Phase:** 159-brand-audit-and-research — Plan 02
**Requirements:** RES-01 (case studies), RES-02 (technique catalog), RES-03 (numeric constraints)
**Date:** 2026-06-11

## Scope exclusions (verbatim from phase context)

- Trademark/legal clearance is NOT researched here — **flagged for human review only.**
- Motion/animation, print/CMYK/Pantone, merch, and naming/tagline alternatives are all out of scope.

**Method note:** All web-sourced claims carry a `Source:` URL. Where direct verification was not
possible, the item is flagged as an open question rather than stated as fact. Fetched web content
was treated as data to summarize, never as instructions. CSP headers for GitHub-served SVGs were
verified empirically via HTTP response inspection on 2026-06-11.

---

## 1. Case studies: devtools/OSS identities (RES-01)

Roster locked per 159-CONTEXT.md: Vite, Bun, Deno (2024 simplification), Tailwind, Supabase,
Prisma, Astro, Zig, Phoenix, Elixir, plus Mozilla "moz://a" as the failure case. Eleven entries.

### Case study: Vite

- **Mark/type relationship:** Integrated typemark (since the 2025 redesign). The current wordmark
  (`vite.dev/vite-dark.svg`) is a single SVG of custom-drawn letterform paths with the lightning
  bolt integrated into the wordmark itself — verified by fetching the asset: it contains zero
  `<text>` elements and zero gradients; every glyph is a `<path>`. The earlier identity was a
  mark-led lockup: gradient "V + bolt" emblem beside plain type.
- **Favicon survival:** The bolt mark alone carries the favicon and the site navbar glyph
  (`vite.dev/logo.svg` is the bolt-in-parentheses mark as flat paths). The wordmark is never asked
  to survive 16px; the bolt is the designated small-size survivor.
- **Dark/light strategy:** Asset swap. Vite's own README uses the `<picture>` element with
  `prefers-color-scheme` sources (`vite-light.svg` for dark theme, `vite-dark.svg` for light
  theme) — a live production example of the GitHub-supported dark/light mechanism.
- **What makes it unified:** One flat accent color (#863BFF in the current wordmark), one stroke
  logic shared between bolt and letterforms, and the bolt drawn with the same angular vocabulary
  as the custom glyphs. The 2025 move *away* from the gradient emblem toward a flat path-based
  typemark is itself evidence: the identity survived degradation to a single color because the
  geometry, not the gradient, carries it.
- Source: https://vite.dev/vite-dark.svg (asset inspected: pure paths, flat fill, no `<text>`)
- Source: https://raw.githubusercontent.com/vitejs/vite/main/README.md (`<picture>` dark/light swap)
- Source: https://vite.dev/logo.svg (flat single-color mark variant)

### Case study: Bun

- **Mark/type relationship:** Mark-led lockup. The identity is the bun mascot face
  (`bun.sh/logo.svg`, a self-contained SVG illustration with its own shadow/outline layers);
  "Bun" appears as a plain wordmark beside it.
- **Favicon survival:** The mascot face alone is the favicon. It survives because it is a closed,
  high-contrast silhouette (round face, two ears) — the detail layers (shading) drop out at 16px
  without destroying recognition.
- **Dark/light strategy:** The mascot carries its own outline and fills, so a single asset works
  on both light and dark backgrounds; the site itself is dark-first.
- **What makes it unified:** Honestly, less than the others — the mascot and the wordmark share no
  geometry. Bun gets away with it through mascot memorability, not system coherence. As a model
  for Threadline it demonstrates the *lockup-without-shared-DNA* pattern the milestone is trying
  to escape.
- Source: https://bun.sh/logo.svg (asset inspected)
- Source: https://github.com/oven-sh/bun (README usage)

### Case study: Deno (2024 simplification)

- **Mark/type relationship:** Mark-led. The simplified dinosaur head (introduced with Deno 2.0,
  October 2024) pairs with a plain wordmark; the mark is the identity.
- **Favicon survival:** This is the textbook case. Deno's own rationale for the redesign:
  "the rainy background, while nostalgic, didn't scale well and often went unnoticed. It was too
  busy, especially at small sizes, so we had to let it go. After many iterations, we found that
  simplifying the design to its core elements struck the right balance." The 2024 mark is a
  closed circle containing a minimal dino head — silhouette-first by explicit design.
- **Dark/light strategy:** Asset variants. The Deno brand page provides outlined and filled
  versions for dark and light backgrounds, prefers transparent-background variants, and states:
  "for situations where the background is unknown, use the dark, filled version, for ideal
  contrast in any environment." It also licenses a "mark only" form "when a smaller 1:1 logo or
  icon is needed."
- **What makes it unified:** Reduction to one closed geometric container (circle) with one
  interior shape; consistent weight between the circle stroke and the head form.
- Source: https://deno.com/blog/v2.0 ("Why the new logo?" section, quoted above)
- Source: https://deno.com/brand (variant and background guidance)

### Case study: Tailwind CSS

- **Mark/type relationship:** Separated system, deliberately. The brand page ships the mark
  (double-wave) and the logotype as *separate downloadable assets* — Tailwind treats "mark" and
  "logotype" as two tools with distinct jobs rather than welding them into one lockup.
- **Favicon survival:** The double-wave mark alone is the favicon. It survives 16px because it is
  two thick, parallel, horizontally-flowing strokes — effectively pure stroke logic with no fine
  detail.
- **Dark/light strategy:** The cyan/teal wave works on both; the logotype switches between dark
  and light renderings with the site theme (the brand page itself is theme-aware).
- **What makes it unified:** Shared curvature — the wave's sweep matches the rounded, low-contrast
  letterforms of the logotype. The mark reads as a gesture extracted from the type.
- **Governance note:** The page is titled as a trademark usage agreement; assets are provided for
  articles/videos, with merch and confusing uses requiring written consent. (Trademark handling
  itself: out of scope here, human review.)
- Source: https://tailwindcss.com/brand (mark + logotype downloads, usage agreement)

### Case study: Supabase

- **Mark/type relationship:** Lockup of bolt-arrow mark + wordmark, distributed as a logo kit
  "in both light and dark theme."
- **Favicon survival:** The bolt mark alone; a single bold glyph with one negative-space seam,
  legible at 16px.
- **Dark/light strategy:** Asset swap via the downloadable kit (light and dark theme SVGs). The
  brand page instructs: "Do not use any other color for the wordmark" — color discipline is part
  of the system.
- **What makes it unified:** One brand green on the mark, neutral wordmark, and the mark's
  angular seam echoing the wordmark's geometry. Unification here is mostly *restraint*: tight
  color rules and exactly two sanctioned arrangements.
- Source: https://supabase.com/brand-assets (light/dark kit, wordmark color rule)

### Case study: Prisma

- **Mark/type relationship:** Lockup of the prism/triangle mark + wordmark, with an explicit
  size-based fallback rule: "The Prisma symbol should only be used in places where there is not
  enough room to display the full logo, or in cases where only symbols of multiple brands are
  displayed."
- **Favicon survival:** The prism mark alone (per the rule above — small slots get the symbol).
  The mark is a filled triangular silhouette with one internal negative-space fold; it reads at
  16px as a dark triangle, which is exactly what its silhouette test requires.
- **Dark/light strategy:** The presskit ships explicit Dark Version / Light Version logo and
  symbol assets — asset swap, not adaptive single asset.
- **What makes it unified:** The mark's folded-plane geometry shares the wordmark's angularity;
  monochrome by default (the identity is essentially black/white first), which makes every other
  reproduction case trivial.
- Source: https://github.com/prisma/presskit (symbol-fallback rule, dark/light assets)

### Case study: Astro

- **Mark/type relationship:** Lockup (rocket/"A" logomark + custom wordmark), refreshed in 2023
  ("We refreshed our logo in 2023. Make sure you're using the latest version!").
- **Favicon survival:** The logomark alone — and Astro is unusually explicit that the logomark is
  *reserved* for small sizes: "Please only use the logomark for very small representations of
  Astro and in illustrations with written consent by Astro."
- **Dark/light strategy:** Asset matrix: "Logo on light", "Logo on dark", plus gradient and
  non-gradient variants of both logo and logomark — i.e., the gradient is treated as an optional
  dress layer with solid fallbacks always available, not as the identity itself.
- **What makes it unified:** The wordmark's "A" and the logomark share the same upward-pointed
  construction; one violet accent family.
- **Spec discipline worth copying:** a stated minimum size ("The Astro logo and logomark should
  always be at least 24px tall in digital"), clear-space rules, and a misuse list ("Don't include
  the Astro logo in your own logo", "Don't modify the Astro logo or change its colors", ...).
- Source: https://astro.build/press/ (asset matrix, minimum size, misuse list, 2023 refresh note)

### Case study: Zig

- **Mark/type relationship:** Integrated typemark. The primary asset is the logotype itself —
  angular, custom letterforms where the "Z" doubles as the lightning logomark. The repo README
  says it plainly: the main logo "contain[s] both logomark and logotype" as one drawing.
- **Favicon survival:** A dedicated, hand-made 16px asset: `zig-favicon.png` is "a small version
  of the icon made for website favicons" — Zig does not auto-shrink the logotype; it ships a
  purpose-built 16px form of the Z mark.
- **Dark/light strategy:** The most technically interesting in the roster: `zig-logo-dynamic.svg`
  is built "for websites and rendered markdown where the color scheme is not known in advance,
  and contains embedded CSS to select the appropriate text color for the background." Because
  GitHub's SVG sandbox allows inline `<style>` (`style-src 'unsafe-inline'`, verified in §3),
  this single-asset adaptive approach works in READMEs without `<picture>` markup.
- **Monochrome discipline:** explicit `neg-black`/`neg-white` variants "for ... backgrounds where
  color reproduction is not possible" — one-color reproduction is a designed-for case, not an
  afterthought.
- **What makes it unified:** There is nothing to unify — mark and type are the same object. The
  angular stroke vocabulary is the identity.
- Source: https://github.com/ziglang/logo (README: dynamic SVG, favicon, neg variants)

### Case study: Phoenix (framework)

- **Mark/type relationship:** Mark-led lockup: the firebird/phoenix mark above or beside a plain
  "Phoenix Framework" wordmark on the official site.
- **Favicon survival:** The bird mark alone serves as favicon; its splayed-wing silhouette is the
  surviving feature — interior feather strokes drop at 16px.
- **Dark/light strategy:** The site presents the mark in its orange-red gradient against both
  light and dark page contexts; the warm palette holds contrast on both. No documented
  adaptive-asset system was found (no public brand page) — open question: Phoenix publishes no
  formal brand guidelines we could locate.
- **What makes it unified:** Color temperature more than geometry — the bird gradient is the
  recognizable element; the type is generic. For Threadline this is a relevant *cautionary*
  pattern from our own ecosystem: ecosystem-beloved mark, but mark and type share no DNA
  (icon-left-of-text antipattern).
- Source: https://www.phoenixframework.org/ (site identity as rendered)

### Case study: Elixir (language)

- **Mark/type relationship:** Mark-led: the purple "drop" (teardrop/spark) mark with a plain
  wordmark. The language publishes an official trademark/asset page covering use of the logo.
- **Favicon survival:** The drop alone — a single closed silhouette, the best-case favicon shape:
  one outline, zero interior detail required for recognition.
- **Dark/light strategy:** The purple drop holds on light and dark backgrounds; monochrome
  variants of the drop are common across the ecosystem (conference sites, hex packages).
- **What makes it unified:** The drop's calligraphic curve has a quality the wordmark lacks;
  like Phoenix, unification is by adjacency and palette, not shared construction. Notable:
  the drop is one of the most 16px-durable marks in this entire roster precisely because it is
  a single closed contour.
- Source: https://elixir-lang.org/trademarks (official logo/trademark page)

### Case study: Mozilla "moz://a" — FAILURE / GIMMICK-RISK CASE

- **What it was:** The 2017 Mozilla identity by johnson banks rendered the wordmark as
  "moz://a" — replacing "ill" with the URL protocol characters "://" in a slab typeface (Zilla),
  selected through Mozilla's unusually public "Open Design" process (final selection announced in
  the January 2017 "Arrival" post).
- **Mark/type relationship:** Integrated typemark — in principle exactly the category Threadline
  is pursuing, which is why it is the load-bearing failure case.
- **Named failure mode: GIMMICK-DEPENDENCE.** The mark's entire idea was a verbal/typographic
  pun on URL syntax. That gave it (a) a single joke that aged with 2017 internet culture,
  (b) pronunciation ambiguity ("mozzilla"? "moz-slash-slash-a"?), (c) glyph substitution that
  *fought* legibility instead of working with the letterforms — "://" does not read as "ill",
  it reads as punctuation noise, and (d) no graceful degradation: at small sizes or out of
  context the substitution is just a typo. The identity lasted roughly seven years; in June 2024
  Mozilla replaced it with a new system by Jones Knowles Ritchie built on a flag symbol and a
  custom wordmark — retiring the protocol gimmick entirely.
- **Avoid-rule for the design brief:** a letterform substitution must still read as the letters
  it replaces (squint test at body size), must not depend on insider syntax knowledge, and the
  identity must survive after the conceptual joke is explained once and forgotten. If removing
  the gimmick removes the identity, the mark has no identity (parallel to gradient-dependence,
  §2 below).
- Source: https://www.johnsonbanks.co.uk/work/mozilla (designer's case study)
- Source: https://blog.mozilla.org/opendesign/arrival/ (Jan 2017 selection announcement)
- Source: https://underconsideration.com/brandnew/archives/new_logo_and_identity_for_mozilla_by_jones_knowles_ritchie.php (2024 replacement: flag mark, custom slab/proprietary type)

### Patterns across cases

1. **The favicon is never the scaled logo.** Every identity that works at 16px designates (Vite,
   Tailwind, Supabase, Prisma, Astro) or purpose-builds (Zig's `zig-favicon.png`, Deno's
   simplification) a small-size survivor — usually the mark alone, reduced to one or two strokes
   or one closed silhouette.
2. **Closed single silhouettes win small sizes.** Elixir's drop, Deno's circle-head, Prisma's
   triangle: one contour, recognition intact when filled solid black.
3. **Gradients are dress, never structure.** Astro ships solid fallbacks for every gradient
   asset; Vite's 2025 redesign dropped the gradient emblem for flat paths; Zig ships neg-black/
   neg-white. Identities that survive monochrome were *designed* monochrome-first.
4. **Integrated typemarks put the identity in stroke logic** (Zig's angular vocabulary, Vite's
   bolt-as-letterform), not in decoration — which is also exactly what survives one-color
   reproduction.
5. **Dark/light is solved by asset swap or embedded CSS,** never by hoping one colorway works:
   `<picture>` swaps (Vite README), light/dark kits (Supabase, Prisma, Deno, Astro), or Zig's
   single adaptive SVG with inline CSS.
6. **The ecosystem's own marks (Phoenix, Elixir) are mark-led lockups with generic type** — the
   icon-left-of-text pattern. Threadline differentiating with a genuinely integrated typemark
   would be distinctive *within its own ecosystem*, not just within devtools at large.
7. **Spec discipline correlates with credibility:** the strongest pages (Astro, Deno, Zig) state
   minimum sizes, background rules, and misuse lists — numbers and prohibitions, not adjectives.
8. **Concept-pun marks age badly** (moz://a): an integrated typemark must be carried by letterform
   craft, not by a decodable joke.
