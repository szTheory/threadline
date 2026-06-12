# Phase 159 Brand Audit — Pressure-Test of the Existing `brandbook/`

- **Requirements:** AUD-01 (14-section pressure-test with verdicts and scorecard), AUD-02 (8-surface stress-test matrix against actual current assets)
- **Audited at:** 2026-06-12 (repo state as of commit cf0e8e2 era; `brandbook/` last touched 2026-06-05)
- **Scope:** every file in `brandbook/` (12 top-level files + 7 `examples/*.svg`), read-only — no brandbook or lib modification
- **Downstream:** the scorecard in section 3 is the BOOK-07 baseline Phase 162's `pressure-test.md` rerun must meet or beat; GAP-nn/UP-nn items in sections 5–6 are routable by Plan 03
- **Tone contract:** all killer, no filler. KEEP what is strong (voice, palette, tokens). Be candid about the logo system — that is what v1.35 exists to fix.

---

## Evidence Base

Hard evidence first. Every judgment in sections 1–14 traces back to file contents quoted or measured here.

### Asset Inventory

| File | Size | Format | Role |
|---|---|---|---|
| `brandbook/README.md` | 1.8 KB / 27 lines | Markdown | Folder guide, maintenance rules, best current defaults |
| `brandbook/brand-book.md` | 14.4 KB / 506 lines | Markdown | Source-of-truth brand guide: DNA, voice, color, type, logo rules, copy, blueprints |
| `brandbook/pressure-test.md` | 15.1 KB / 520 lines | Markdown | Prior self-assessed brand QA guide (the scorecard this audit supersedes) |
| `brandbook/index.html` | 33.4 KB / 481 lines | HTML | Static dark-theme brandbook viewer; consumes `tokens.css`, embeds all SVG assets via `<img>` |
| `brandbook/tokens.json` | 5.1 KB / 193 lines | JSON | Raw + semantic tokens: color (dark/light), type, spacing, radius, shadow, focus, code, callout, state |
| `brandbook/tokens.css` | 4.5 KB / 147 lines | CSS | Same tokens as custom properties; `.tl-theme-dark` / `.tl-theme-light` lanes |
| `brandbook/logo-primary.svg` | 1.3 KB / 19 lines | SVG | Primary dark lockup: gradient line mark + Geist `<text>` wordmark + mono `<text>` subtitle |
| `brandbook/logo-primary-light.svg` | 1.4 KB / 19 lines | SVG | Same lockup recolored for light surfaces (README/GitHub per its own `<desc>`) |
| `brandbook/logo-mark.svg` | 0.9 KB / 15 lines | SVG | Icon-only mark, 64×64: gradient curve, 2 tick lines at 42% opacity, 3 dots |
| `brandbook/logo-monochrome.svg` | 1.0 KB / 15 lines | SVG | "One-color" lockup — actually two inks plus an opacity tone (see Finding E5) |
| `brandbook/favicon.svg` | 0.7 KB / 10 lines | SVG | 64×64 rounded-square chip with compact curve + 3 dots, no text |
| `brandbook/social-card.svg` | 2.1 KB / 31 lines | SVG | 1200×630 og:image source with 4 `<text>` elements |
| `brandbook/examples/components.svg` | 2.9 KB / 30 lines | SVG | Buttons, badge, cards, callout, terminal block specimen (13 `<text>`) |
| `brandbook/examples/docs-page.svg` | 2.3 KB / 25 lines | SVG | Docs layout mock; embeds logo via external `<image href>` (13 `<text>`) |
| `brandbook/examples/landing-hero.svg` | 2.0 KB / 18 lines | SVG | Landing hero mock with thread linework (5 `<text>`) |
| `brandbook/examples/palette.svg` | 2.4 KB / 19 lines | SVG | Color swatch specimen (12 `<text>`) |
| `brandbook/examples/readme-header.svg` | 1.3 KB / 14 lines | SVG | README header mock; embeds logo via external `<image href>` (5 `<text>`) |
| `brandbook/examples/terminal.svg` | 1.2 KB / 15 lines | SVG | Terminal snippet style (6 `<text>`) |
| `brandbook/examples/typography.svg` | 1.6 KB / 13 lines | SVG | Type role specimen (7 `<text>`) |

### Finding E1 — The SVG `<text>` portability bug, demonstrated

Actual command output (`grep -n '<text' brandbook/*.svg brandbook/examples/*.svg`), trimmed here to the four logo-family assets — the full run matches 11 of the 13 SVGs (every SVG except `favicon.svg` and `logo-mark.svg`, which contain zero `<text>` elements) and is pasted in full in Appendix A:

```
brandbook/logo-primary.svg:17:  <text x="108" y="58" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="36" font-weight="600" letter-spacing="0">Threadline</text>
brandbook/logo-primary.svg:18:  <text x="111" y="78" fill="#8F9DB5" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="10" font-weight="500" letter-spacing="2.4">FOLLOW WHAT HAPPENED</text>
brandbook/logo-primary-light.svg:17:  <text x="108" y="58" fill="#0F1728" font-family="Geist, Inter, system-ui, sans-serif" font-size="36" font-weight="600" letter-spacing="0">Threadline</text>
brandbook/logo-primary-light.svg:18:  <text x="111" y="78" fill="#3B4762" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="10" font-weight="500" letter-spacing="2.4">FOLLOW WHAT HAPPENED</text>
brandbook/logo-monochrome.svg:13:  <text x="108" y="58" fill="#0F1728" font-family="Geist, Inter, system-ui, sans-serif" font-size="36" font-weight="600" letter-spacing="0">Threadline</text>
brandbook/logo-monochrome.svg:14:  <text x="111" y="78" fill="#3B4762" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="10" font-weight="500" letter-spacing="2.4">FOLLOW WHAT HAPPENED</text>
brandbook/social-card.svg:27:  <text x="96" y="162" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="78" font-weight="600">Threadline</text>
brandbook/social-card.svg:28:  <text x="102" y="220" fill="#4EDFD1" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="22" font-weight="500" letter-spacing="5">FOLLOW WHAT HAPPENED</text>
```

Per-file `<text>` counts (`grep -c '<text'`): logo-primary.svg **2**, logo-primary-light.svg **2**, logo-monochrome.svg **2**, social-card.svg **4**, components.svg 13, docs-page.svg 13, palette.svg 12, typography.svg 7, terminal.svg 6, landing-hero.svg 5, readme-header.svg 5, **favicon.svg 0, logo-mark.svg 0**.

**The mechanism, precisely.** GitHub serves repo-embedded SVGs through its Camo image proxy with a Content-Security-Policy of effectively `default-src 'none'; style-src 'unsafe-inline'`. Inside that sandbox the SVG cannot load external fonts, cannot fetch `@font-face` sources, and cannot reference any external resource at all. A `<text font-family="Geist, Inter, system-ui, sans-serif">` therefore renders in whatever the viewer's environment resolves for the generic fallback — Geist and IBM Plex Mono are never loaded. **The wordmark the user sees on GitHub is not the wordmark in the file.** Letterform widths, weight, and the carefully tuned `letter-spacing="2.4"` on the subtitle all shift with the substituted font; baseline math (x=108/y=58 vs. x=111/y=78) was tuned for Geist metrics and silently breaks.

**Affected surfaces:** GitHub README renders, any `<img>`-embedded context (HexDocs pages, third-party blogs, Slack unfurls of raw URLs), and any CI rasterization environment without the fonts installed. **Not affected:** a local browser with Geist/IBM Plex Mono installed, and `brandbook/index.html` viewed locally — which is precisely why the bug has gone unnoticed: the only place the brandbook is reviewed is the one place the fonts resolve.

### Finding E2 — The icon-left-of-text antipattern, named plainly

The actual structure of `brandbook/logo-primary.svg` is three unrelated elements in a row:

1. **The mark** (lines 10–16): a `<g transform="translate(12 14)">` containing a bezier squiggle (`M7 54C18 18 35 19 44 38C51 53 64 49 70 12`, gradient stroke, width 5.5), two horizontal tick lines at 45% opacity, and three dots (r=4.5) at the curve's endpoints and midpoint. It occupies roughly x ∈ [19, 86] of the 360-unit canvas.
2. **The wordmark** (line 17): plain Geist `<text x="108" y="58">Threadline</text>`.
3. **The subtitle** (line 18): mono `<text x="111" y="78">FOLLOW WHAT HAPPENED</text>`.

Mark and type share **no geometry whatsoever**: no stroke continues into a letterform, no letterform counter echoes the curve, no shared grid, no shared baseline logic — the text x-offsets (108 vs. 111) are eyeballed fudge, not system. There is a ~22-unit dead gutter between the mark's right edge and the text. Remove the squiggle and you have a perfectly serviceable type-only header; remove the text and you have an anonymous line-with-dots that could belong to any monitoring, analytics, or signal-processing tool. **Neither half carries the other.** This is the textbook clip-art-plus-label lockup — the exact pattern the v1.35 milestone exists to kill. The brand book's own visual-center statement ("a line that connects discrete points into an intelligible path") is a good idea that the lockup merely *adjacent-places* next to the name instead of *integrating* with it.

### Finding E3 — The baked-in subtitle antipattern

"FOLLOW WHAT HAPPENED" is hardcoded as a mono `<text>` element inside **all three** primary lockups — `logo-primary.svg:18`, `logo-primary-light.svg:18`, and `logo-monochrome.svg:14` (grep output above). This violates the v1.35 hard constraint that the primary lockup carries no subtitle (downstream requirement LOGO-03). The damage is concrete, not stylistic:

- At the brand book's own stated minimum primary width of **160px** (brand-book.md "Minimum size"), the 360-unit viewBox scales by 0.444, rendering the 10px subtitle at **~4.4px** — illegible on every display. The brand book's minimum-size rule and its own primary asset contradict each other.
- The tagline is locked into the vector, so every surface gets the slogan whether it fits or not; there is no subtitle-free primary asset at all.
- It doubles the `<text>`/font exposure from Finding E1: the subtitle's `letter-spacing="2.4"` on a 10px mono face is the single most font-metric-sensitive element in the system.

### Finding E4 — External `<image href>` references break on GitHub

`examples/readme-header.svg:6` and `examples/docs-page.svg:7` embed the logo via `<image href="../logo-monochrome.svg" .../>`. Under the same Camo/CSP sandbox from Finding E1, external resource loads inside an SVG are blocked — on GitHub these two example specimens render with a **blank rectangle where the logo should be**. The README-direction specimen, specifically built to model the GitHub surface, cannot itself render on GitHub.

### Finding E5 — The "monochrome" logo is not one color

`logo-monochrome.svg` self-describes as "One-color Threadline logo for constrained print, engraving, or small surfaces" (its `<desc>`, line 3). It actually uses: ink `#0F1728` (curve, dots, wordmark), a **second ink** `#3B4762` (subtitle, line 14), and tick lines at `stroke-opacity=".45"` (line 6) — an opacity-derived third tone. True single-color reproduction (vinyl cut, engraving, thermal print, one-plate offset) collapses the 45% ticks to full-strength or drops them, and promotes the subtitle to full ink. The asset has never been tested against the constraint named in its own description.

### Finding E6 — Favicon geometry at 16px, measured

`favicon.svg` is a 64×64 viewBox. At a literal 16px canvas the scale factor is 0.25:

- Main curve strokes: `stroke-width="5"` → **1.25px effective** — at or below the practical legibility floor (~1px absolute, 1.5–2px for clarity at 16px).
- Dots: `r="4"` → **2px diameter** specks.
- Container chip: `rx="14"` → 3.5px corner radius on a near-full-bleed dark square.
- The curve's internal features (the dip between x=35 and x=54 spans ~19×27 units) compress to **~4.7×6.8px**, rendered with a 1.25px stroke — antialiasing smears the crossing structure into a noisy tilde.
- The two-path trick (lines 5–6: the cyan path re-traces the second half of the blue path to fake a two-color split without a gradient) survives, but the color boundary lands mid-curve with no anchor.

The identity-bearing details of the mark family — tick lines, dot hierarchy, the precise wave — do not survive 16px. What survives is "a squiggle in a dark rounded square." Note also: the rounded-square container chip is itself the container-chip pattern the v1.35 design brief forbids for the mark family.

### Finding E7 — Gradient-dependence and the light-surface dot

`logo-mark.svg` carries its blue→cyan progression in a `linearGradient` stroke (lines 5–8); one-color collapse loses the directional "signal travels along the thread" meaning, leaving plain line art — gradient-dependence is a named antipattern in the Phase 159 research scope. Separately, the mark's third dot and tick lines are Fog `#D7DEEA` — near-white — which disappears on white/light surfaces (Hex.pm and HexDocs avatar/logo slots are light by default); the icon-only mark has no light-surface variant at all.

---

## Stress-Test Matrix (AUD-02)

Executed against the actual committed assets. Evidence is described analysis grounded in file contents (per CONTEXT.md discretion; Phase 162 owns final visual verification with screenshots).

| Surface | Asset tested | Behavior on this surface | Evidence | PASS/DEGRADED/FAIL | Severity |
|---|---|---|---|---|---|
| GitHub README render | `logo-primary-light.svg` (the asset README.md and its own `<desc>` designate for this surface) + `examples/readme-header.svg` | Camo/CSP sandbox loads no fonts: wordmark and subtitle fall back to generic sans/mono with wrong metrics (Finding E1); the readme-header specimen's `<image href="../logo-monochrome.svg">` is blocked entirely, leaving a blank logo region (Finding E4) | `logo-primary-light.svg:17-18` (`<text font-family="Geist…">`, `letter-spacing="2.4"`); `examples/readme-header.svg:6` (external `<image href>`) | FAIL | Critical |
| Hex.pm logo slot | `logo-mark.svg` (only icon-format asset besides favicon) | Hex.pm's package/org image surfaces are small and light-background; the mark's Fog `#D7DEEA` third dot and 42%-opacity ticks vanish on white, and the gradient stroke goes muddy below ~32px (Finding E7) | `logo-mark.svg:11-14` (Fog ticks at `stroke-opacity=".42"`, Fog dot `fill="#D7DEEA"`); no light-mode mark variant exists in the inventory | DEGRADED | Major |
| HexDocs logo slot | `logo-mark.svg` via ExDoc `logo:` option | ExDoc renders one logo file in the sidebar across both its light and dark themes (~48px); a single asset must survive both, and the Fog elements fail the light theme while the dark-tuned gradient is acceptable on dark — no theme-pair or adaptive asset exists | `logo-mark.svg` color analysis (E7); inventory shows no `logo-mark-light.svg` or `currentColor`-based variant | DEGRADED | Major |
| 16px favicon | `favicon.svg` | At 16px the 64-unit viewBox yields 1.25px strokes and 2px dots; internal curve features compress to ~5px and smear; the mark's identity reduces to an anonymous squiggle in a dark rounded chip — and the chip itself is the forbidden container pattern (Finding E6) | `favicon.svg:4-9` (`stroke-width="5"`, `r="4"`, `rx="14"` against viewBox 64); scale math 16/64 = 0.25 | FAIL | Critical |
| Dark mode | `logo-primary.svg` | On a font-capable dark surface the lockup works: Fog text on `#0B1020` is high-contrast, gradient stroke reads well; remaining defects are structural (E2 icon-left-of-text, E3 subtitle at small sizes), not dark-specific | `logo-primary.svg:11-18`; tokens.css `.tl-theme-dark` confirms surface palette alignment | PASS | Minor |
| Light mode | `logo-primary-light.svg` | The light variant is properly rebalanced (`#1557C0`/`#0F8F85` gradient, Ink text — genuinely good practice), but the system is a two-file split with **no documented switching mechanism** (`<picture>`/`prefers-color-scheme`/`#gh-dark-mode-only`); on any single-slot or auto-switching surface one mode breaks — e.g. the light file's `#0F1728` wordmark is invisible on dark | `logo-primary-light.svg:5-18`; brand-book.md "Usage" lists which file goes where but no embed snippet anywhere in brandbook/ | DEGRADED | Major |
| Monochrome | `logo-monochrome.svg` | Self-described one-color asset actually uses two inks plus a 45%-opacity tone; literal single-color reproduction collapses or drops the ticks and promotes the subtitle; `<text>` dependency persists (E1) so even the constrained-surface asset needs fonts | `logo-monochrome.svg:4-14` (Finding E5: `#0F1728` + `#3B4762` + `stroke-opacity=".45"`) | FAIL | Major |
| Social card | `social-card.svg` | og:image consumers (X/Twitter, LinkedIn, Slack, Discord) require raster — SVG is never fetched as a card, so this asset is source-only; no export script or PNG is committed, and rasterizing in any environment without Geist/IBM Plex Mono installed reproduces the font fallback (4 `<text>` elements incl. 78px wordmark and letter-spaced subtitle) | `social-card.svg:27-30`; brand-book.md "Generate only on demand: PNG social card exports" with no committed pipeline | DEGRADED | Major |

**Matrix summary:** 1 PASS, 4 DEGRADED, 3 FAIL across 8 surfaces. The two critical FAILs (GitHub README, 16px favicon) are the two highest-traffic surfaces an OSS library has.

---

## 1. Executive Judgment

The Threadline brand system is **half excellent, half structurally unsound — and the unsound half is the visible half.** The verbal identity (essence, voice, anti-traits, messaging discipline) and the token infrastructure (dual-format, semantically layered, operator-surface-aligned) are genuinely strong and should be preserved nearly untouched. The visual identity fails at its load-bearing points: the primary lockup is an icon-left-of-text juxtaposition with a baked-in subtitle (Findings E2, E3), every wordmark-bearing asset silently renders in the wrong typeface on GitHub (E1), the favicon does not survive 16px (E6), and the monochrome asset is not monochrome (E5). The prior self-assessment (`brandbook/pressure-test.md` Section 1: "ready for source-controlled use across … README/GitHub visuals") is contradicted by the stress-test matrix above — the system fails on GitHub, its primary surface. The correct posture for v1.35: keep the brand's center and verbal system; rebuild the mark/lockup family from scratch against numeric constraints.

**Verdict:** TIGHTEN — the executive claim of readiness must be narrowed to "verbal system and tokens ready; logo family not shippable on its two highest-traffic surfaces," as demonstrated by the matrix.

## 2. Brand DNA Extraction

The DNA is the strongest part of the book. "Threadline makes system history followable" is a real, ownable essence — specific to audit history, not generic trust language. The audience list is concrete (Phoenix/Ecto engineers, SRE, security, support, OSS evaluators), the emotional register ("calm in tense moments", "trustworthy because it is inspectable") is differentiated, and the anti-trait list (flashy, cute, cyberpunk, militarized, compliance-bureaucratic, generic SaaS) is unusually disciplined — most brand docs never say what they refuse to be. The visual metaphor ("a line that connects discrete points into an intelligible path") is correct and rich; the failure documented in E2 is that the current mark *illustrates* the metaphor next to the name instead of *embodying* it through the name. The DNA needs no rework — it needs a mark worthy of it. One sentence to carry into the design brief verbatim: "abstract nodes with no domain meaning" is already named as a never-feel — the current squiggle skirts dangerously close to violating its own DNA.

**Verdict:** KEEP — the essence, audience, tone, and anti-traits are specific, disciplined, and correct; the design brief should quote them, not rewrite them.

## 3. Pressure-Test Scorecard

Fifteen dimensions, scored 1–10 against the evidence base. **This table is the BOOK-07 baseline: Phase 162's pressure-test rerun must meet or beat every row and the total.** The existing `brandbook/pressure-test.md` Section 3 scorecard (self-assessed 7–9 across 15 friendlier dimensions, e.g. "Logo readiness 7") is recorded as prior art that this baseline supersedes — it scored governance and intent, never adversarial survival, and contained no portability, 16px, or monochrome dimension at all.

| # | Dimension | Score | Rationale |
|---|---|---|---|
| 1 | Distinctiveness | 4 / 10 | The metaphor is ownable but the executed mark is a generic line-with-dots that any monitoring tool could ship (E2). |
| 2 | Mark/type integration | 2 / 10 | Zero shared geometry between squiggle and wordmark; eyeballed x-offsets, dead gutter, removable halves (E2). |
| 3 | 16px survival | 3 / 10 | 1.25px effective strokes, 2px dots, smeared crossing — identity does not survive a literal 16px render (E6). |
| 4 | Monochrome survival | 3 / 10 | The "one-color" asset uses two inks plus a 45%-opacity tone and still depends on `<text>` (E5). |
| 5 | Dark/light versatility | 5 / 10 | A properly rebalanced light variant exists (credit), but no switching mechanism and no light icon mark (matrix rows 3, 6). |
| 6 | Portability (no font dependency) | 2 / 10 | 11 of 13 SVGs carry `<text>`; every lockup renders wrong on GitHub's font-less sandbox (E1). |
| 7 | Scalability | 4 / 10 | One favicon cut exists but no size-specific masters; hairline ticks and 45% opacity die below ~32px (E6, E7). |
| 8 | Voice | 9 / 10 | Calm-senior-engineer voice with say-this/not-this pairs and a banned-vocabulary list — concrete and enforceable. |
| 9 | Palette | 8 / 10 | Disciplined night-infrastructure system with dual-mode semantic roles and real hex discipline; gradient rules stated. |
| 10 | Typography | 8 / 10 | Geist + IBM Plex Mono, OFL-licensed in-repo, role table and tracking rules defined; fallback stacks correct. |
| 11 | Token rigor | 8 / 10 | JSON + CSS dual format, raw/semantic layering, dark/light lanes, explicit alignment with the operator-surface contract. |
| 12 | Application coverage | 7 / 10 | Seven example specimens plus landing/README blueprints; but the README specimen itself breaks on GitHub (E4). |
| 13 | Misuse guidance | 6 / 10 | Good textual do-not lists (no shields, no mascot, no rotation) but no visual misuse gallery and no numeric thresholds. |
| 14 | Consistency | 6 / 10 | Tokens and examples align well; the logo family self-contradicts (monochrome that isn't, min-size that kills its own subtitle, favicon chip vs. no-container rule). |
| 15 | Craft | 4 / 10 | Hand-tuned bezier without optical correction, fudged text offsets (108/111), favicon overdraw hack — competent scaffolding, not finished form. |

**Total: 79/150 — average 5.3.** The split is stark: the five verbal/system dimensions (8–11, 13) average 7.8; the seven mark-survival dimensions (1–7) average 3.3. That asymmetry *is* the v1.35 thesis.

**Verdict:** REWORK — the prior pressure-test.md scorecard measured intent rather than survival and must be superseded by this adversarial 15-dimension baseline for BOOK-07.

## 4. Stress Tests Across Real Surfaces

The executed 8-surface matrix is in the Evidence Base above (Stress-Test Matrix, AUD-02): **1 PASS, 4 DEGRADED, 3 FAIL.** Interpretation, surface by surface: the only clean pass is dark mode — the surface the assets were visibly designed on. Both critical FAILs are the highest-traffic surfaces an OSS library has: the GitHub README (font sandbox breaks the wordmark, CSP blanks the specimen logo) and the 16px favicon (geometry below the legibility floor). The DEGRADED rows share one root cause — the system was authored for a font-installed, dark, large-canvas viewing context and never tested outside it. By contrast, the prior `pressure-test.md` Section 4 lists 26 "surface stress tests" that are all advisory prose ("Favicon: test at 16px and 32px") — instructions to test, not tests. No row was ever executed against a file until this audit. The matrix replaces advice with results, and the three FAIL rows define the non-negotiable acceptance tests for Phase 161 candidates: must render correctly on GitHub with zero font dependency, must survive a literal 16px canvas, must survive literal one-color.

**Verdict:** REWORK — the prior stress-test section was untested advice; it must be replaced by this executed matrix and kept executable for the Phase 162 rerun.

## 5. Gaps and Risks by Severity

Every item is one routable sentence with a stable ID for Plan 03 routing. Severity: critical = breaks a primary surface or a v1.35 hard constraint; major = breaks a secondary surface or forces manual workarounds; minor = quality/consistency debt.

**Critical**

- **GAP-01** (critical): The primary lockup is icon-left-of-text with zero shared geometry between mark and wordmark, so the system has no integrated identity to deploy (E2).
- **GAP-02** (critical): The "FOLLOW WHAT HAPPENED" subtitle is baked into all three primary lockups, violating the no-subtitle-in-primary hard constraint and rendering at ~4.4px at the book's own 160px minimum width (E3).
- **GAP-03** (critical): Eleven of thirteen SVGs — including every wordmark-bearing lockup — depend on `<text font-family="Geist…">` that GitHub's font-less sandbox cannot satisfy, so the public wordmark is never the designed wordmark (E1).
- **GAP-04** (critical): The favicon's geometry (1.25px effective strokes, 2px dots at 16px) is below the legibility floor, so the mark fails the literal-16px hard constraint (E6).

**Major**

- **GAP-05** (major): `logo-monochrome.svg` is not one color (two inks plus a 45%-opacity tone plus `<text>`), so the system has no asset that survives literal single-color reproduction (E5).
- **GAP-06** (major): No dark/light switching mechanism is documented or committed (`<picture>`/`prefers-color-scheme` snippet), so every single-slot or auto-switching surface breaks one mode (matrix row 6).
- **GAP-07** (major): `examples/readme-header.svg` and `examples/docs-page.svg` embed the logo via external `<image href>` that GitHub's CSP blocks, so the README-direction specimen blanks its own logo on the surface it models (E4).
- **GAP-08** (major): `logo-mark.svg`'s Fog (#D7DEEA) dot and ticks vanish on white and no light icon variant exists, so the icon-only mark fails Hex.pm/HexDocs light slots (E7).
- **GAP-09** (major): The social card exists only as SVG with no committed raster export pipeline while og:image consumers require PNG/JPEG, so the sharing surface is unshippable as committed (matrix row 8).

**Minor**

- **GAP-10** (minor): The favicon relies on a rounded-rect container chip, the exact container pattern the v1.35 brief forbids for the mark family (E6).
- **GAP-11** (minor): The mark's blue→cyan meaning lives entirely in a gradient stroke, so one-color collapse loses the signal-direction idea — gradient-dependence as identity (E7).
- **GAP-12** (minor): Misuse guidance is text-only with no visual misuse gallery and no numeric small-size thresholds, so contributors cannot self-check violations (section 13 of scorecard).

**Verdict:** REWORK — the prior risk register named review-process risks but missed every structural defect above; this severity-ordered register replaces it.

## 6. Recommended Upgrades

One routable sentence each, stable IDs for Plan 03; severity inherited from the gap each upgrade resolves.

- **UP-01** (critical): Run the Phase 161 tournament across the four archetype lanes (3 integrated typemarks, 3 unified lockups, 1 monogram/mark-led, 1 wordmark-only) with each candidate required to name its motif strategy, resolving GAP-01.
- **UP-02** (critical): Ship every final wordmark-bearing asset with letterforms converted to outlined vector paths, keeping one editable-text source file per asset outside the deploy set, resolving GAP-03.
- **UP-03** (critical): Remove the subtitle from all primary lockups and carry the tagline only in surface copy (README text, social-card copy line), resolving GAP-02.
- **UP-04** (critical): Design a size-specific favicon/mark cut with ≥2px effective strokes at 16px, silhouette-first geometry, no container chip, and a stated detail floor, resolving GAP-04 and GAP-10.
- **UP-05** (major): Produce a true one-color monochrome master — single ink, no opacity tones, no text — and verify it by literal flatten-to-one-color test, resolving GAP-05 and GAP-11.
- **UP-06** (major): Commit a ready-to-paste GitHub README `<picture media="(prefers-color-scheme: dark)">` snippet plus per-surface asset assignments, resolving GAP-06.
- **UP-07** (major): Add a light-surface icon mark variant (or a `currentColor`-driven adaptive mark) for Hex.pm/HexDocs slots, resolving GAP-08.
- **UP-08** (major): Commit an on-demand raster export script (resvg/rsvg-convert with pinned font files from `priv/fonts/`) producing the og:image PNG deterministically, resolving GAP-09.
- **UP-09** (minor): Inline logo geometry into the example SVGs (no external `<image href>`) so specimens render on GitHub, resolving GAP-07.
- **UP-10** (minor): Add a visual misuse gallery and numeric small-size thresholds (min stroke px at 16/24/32) to the brand book, resolving GAP-12.
- **UP-11** (minor): Rebuild `pressure-test.md` on this audit's 15 adversarial dimensions so the Phase 162 rerun is comparable row-for-row against the BOOK-07 baseline.

**Verdict:** ADD — the existing book has no routable upgrade backlog; this itemized list is new surface area Plan 03 must route to v1.35 requirements or descope with a reason.

## 7. Design Token Spec

The token system is the best-engineered artifact in the directory. `tokens.json` provides raw palette, dark and light semantic lanes, typography (families with correct fallback stacks, a 9-step size scale, line-heights, weights, tracking), spacing, radius, borders, shadows, focus rings, code-block colors, callouts, and state tokens — and `tokens.css` mirrors it as custom properties with `.tl-theme-dark`/`.tl-theme-light` scopes and `color-scheme` declarations. The declared alignment with the operator-surface contract ("aligned with the operator surface token contract", tokens.json line 4) plus brandbook/README.md's explicit lane rule ("Treat `lib/threadline/operator_surface/style.ex` as the current product UI contract") is exactly the right governance: brand tokens for collateral, runtime tokens for product, divergence acknowledged rather than papered over. Two small debts, neither blocking: the JSON and CSS are hand-duplicated with no generation or sync check (drift risk the prior pressure-test already flagged), and motion tokens exist only in the CSS (`--tl-motion-fast` etc.), not the JSON. Nothing in v1.35's logo work requires touching this layer except recording any new brand colors the winning mark introduces.

**Verdict:** KEEP — dual-format, semantically layered, lane-disciplined tokens that downstream phases should consume as-is, with only additive changes if the new mark shifts the accent palette.

## 8. Logo and Mark System

This is the section that carries the REWORK weight, and the evidence is unambiguous. The system's six assets share four structural defects: (1) the lockup architecture itself is juxtaposition, not integration — GAP-01/E2; (2) the subtitle is welded into every primary — GAP-02/E3; (3) the wordmark is live `<text>` everywhere — GAP-03/E1; (4) nothing in the family survives its own stated constrained contexts: the monochrome isn't monochrome (GAP-05/E5), the favicon dies at 16px (GAP-04/E6), the icon mark dies on light surfaces (GAP-08/E7). The brand book's logo *rules* are partially salvageable — the asset roster shape (primary dark/light, icon mark, monochrome, favicon, social card) is the correct set of cuts; the misuse list (no mascot, no shields, no rotation, no glow) is sound; the clearspace rule is fine. What must not survive is the marks themselves and the minimum-size table that contradicts its own assets. The Phase 161 brief should treat the current squiggle as a named anti-example: its three dots, hairline ticks, and gradient stroke are each individually defensible and collectively unbuildable at small sizes. One genuine credit to carry forward: the dark/light *recoloring* discipline in `logo-primary-light.svg` (gradient rebalanced to `#1557C0`/`#0F8F85`, not just text swapped) shows the right instinct — the executor understood surfaces, the mark just isn't worth the care.

**Verdict:** REWORK — every mark and lockup must be regenerated against the numeric constraints (no subtitle, no container chip, 16px survival, one-color survival, zero font dependency); only the asset-roster shape and misuse rules carry forward.

## 9. Visual Examples and Screenshot Guidance

The seven `examples/*.svg` specimens are a genuinely good idea executed with one fatal and several minor flaws. Good: they cover the right surfaces (palette, typography, components, README header, docs page, landing hero, terminal), they are SVG-source-only per the artifact rules, they consistently apply the tokens (every hex in the specimens traces to tokens.json), and the prior book's table (pressure-test.md Section 9) documents purpose and export policy per file. Fatal: the two specimens that model external surfaces — `readme-header.svg` and `docs-page.svg` — embed the logo via external `<image href>` and therefore blank out on GitHub (GAP-07/E4), and all seven carry live `<text>` (61 elements across the set) so none renders with correct type off-machine (E1). Minor: the specimens will all need re-cutting once the new mark lands, so fixing them now would be churn — the right move is to regenerate them in Phase 162 with inlined geometry and outlined or system-font-declared text, and to add the one missing guidance line the current book lacks: specimens must be validated on the surface they model. "Do not create fake product screenshots unless they represent real Threadline behavior" (pressure-test.md Section 9) is a keeper rule.

**Verdict:** TIGHTEN — the specimen set and its rules are right but the rendering defects (external refs, live text) must be fixed when specimens are regenerated against the new mark in Phase 162.

## 10. Brand Voice and Microcopy

The strongest section in the book and one of the strongest voice systems this auditor has seen in an OSS repo. Concrete mechanisms, not adjectives: say-this/not-this pairs ("Capture changes, connect them to context, and follow the full history" vs. "Revolutionary audit intelligence for modern teams"); a banned-vocabulary list (provenance, governance, chain of custody, forensic-grade, seamless, next-generation) that targets exactly the failure modes of this category; writing rules that are testable ("Do not use exclamation marks in product copy"); and full microcopy patterns for error/empty/success/warning states that use real domain nouns and real mix tasks ("Rerun `mix threadline.gen.triggers --tables ticket_replies`, migrate, then check coverage again"). The voice is already load-bearing in the product: the calm-exact register matches the operator surface's actual copy conventions. The vocabulary list (action, change, transaction, actor, correlation, evidence…) doubles as domain-language enforcement aligned with CLAUDE.md's term discipline. Nothing here needs rework for v1.35; the design brief should mandate that logo candidates be *judged against* this voice (a mark that feels flashy or cute fails the anti-trait test regardless of craft).

**Verdict:** KEEP — the voice system is specific, enforceable, and aligned with the product's domain language; v1.35 should treat it as an acceptance criterion for visual candidates, not a thing to revise.

## 11. Landing Page and Docs Blueprint

Both blueprints are concrete and correctly scoped. The landing-page order (hero → problem → solution → install snippet → minimal example → benefits → how it works → use cases → "why not just" comparison → CTAs → footer) is the proven OSS-devtool arc, and the "why not just: logs, event sourcing, SIEM, database auditing" section is a differentiated move that matches the brand's inspectability promise. The README/docs order (opening promise → installation → quickstart → example → concepts → API → operator surface → recipes → troubleshooting → design rationale and non-goals → contribution → license) maps cleanly onto how Elixir libraries are actually evaluated, and "design rationale and non-goals" is a credibility section most libraries skip. The ready-to-use copy blocks (one-liner, 140-char, GitHub description, Hex description, README opening, hero/subhead, CTAs, feature blurbs) are publish-grade and consistent with the voice rules. Two boundaries to respect rather than fix: actual HexDocs theming and the landing build are explicitly deferred to future milestones (HEXDOCS-BRAND-01, LANDING-01 per CONTEXT.md), so this section needs no v1.35 work beyond swapping logo references once the new mark exists.

**Verdict:** KEEP — both blueprints and the ready-to-use copy are publish-grade and out of v1.35's blast radius except for mechanical asset-reference updates.

## 12. Repo-Ready Artifact Plan

The artifact governance is sound in philosophy and 80% complete in practice. Right: text-format-only discipline (HTML/MD/JSON/CSS/SVG), no font-binary duplication (fonts live once in `priv/fonts/`), no committed raster by default, generate-on-demand policy for PNG/PDF, manual-review triggers for trademark-sensitive changes and compliance claims, and the suggested-checks list (JSON parse, XML parse, folder size). Missing, and exposed by the matrix: the generate-on-demand policy has no generator — there is no committed export script, so "export social-card PNG when a platform requires it" is an instruction with no executable path and no font-pinning strategy (GAP-09), which is exactly how the `<text>` bug escapes to raster surfaces; and the plan is silent on the one artifact class v1.35 makes mandatory — outlined-path deploy assets paired with editable-text source masters (UP-02), which needs a stated home and naming convention (e.g. `src/` masters vs. deploy files). The suggested checks should also graduate from "suggested" to a `mix verify.*`-style entrypoint per this repo's CI DNA once Phase 162 regenerates assets, so brand regressions become testable.

**Verdict:** TIGHTEN — keep the format and review rules, add the missing executable export pipeline, the outlined/source dual-file convention, and CI-wired checks.

## 13. Prioritized Action Plan

The prior plan (pressure-test.md Section 13) fails as a plan precisely where the system fails as a system: its "do now" items include "Review favicon at 16px and 32px" and "Use `logo-primary-light.svg` for README" — the first was never done (this audit is that review, result: FAIL), and the second ships the `<text>` bug to GitHub as a recommendation. Its "defer" list buries "human wordmark refinement" at the bottom when the wordmark/lockup is the system's central defect. The plan also predates v1.35's hard constraints, so none of its priorities reflect them. The replacement priority order falls directly out of this audit's severity table: (1) Phase 159 Plans 02–03 — research and design brief encoding the numeric constraints; (2) Phase 161 — tournament across the four archetype lanes (UP-01) with the three FAIL rows of the matrix as elimination gates; (3) Phase 162 — asset regeneration (outlined paths UP-02, no subtitle UP-03, favicon cut UP-04, true monochrome UP-05, light mark UP-07), specimen re-cuts (UP-09), switching snippet (UP-06), export pipeline (UP-08), and the pressure-test rerun against the BOOK-07 baseline (UP-11). The old plan's "do not do" list (no mascot, no shields, no raster moodboards, no compliance claims without review) remains correct and carries forward unchanged.

**Verdict:** REWORK — the prior priorities recommended shipping the defects this audit demonstrates; replace with the severity-ordered v1.35 sequence above, keeping only the do-not list.

## 14. Final Quality Gate

The prior gate (pressure-test.md Section 14) asked eight good questions and then answered all of them itself with unevidenced "yes" — including "Could it survive dark mode, small sizes, docs pages, and social previews? Mostly yes" when the executed answer is 1 PASS / 4 DEGRADED / 3 FAIL. A quality gate that self-certifies is a rubber stamp. The questions themselves are worth keeping; what must change is that each gets a *testable* pass condition owned by Phase 162: "survives small sizes" becomes "renders identifiably at a literal 16px canvas with ≥2px effective strokes" (verifiable from geometry); "survives social previews" becomes "committed export script produces a pixel-correct PNG in a fontless container"; "can an engineer implement from this" becomes "README `<picture>` snippet copy-pastes and renders correctly in both GitHub themes"; "does it feel specific to Threadline" becomes the tournament's distinctiveness judgment recorded against named competitors. The gate must also bind to the BOOK-07 mechanism: Phase 162's rerun of this audit's 15-dimension scorecard must meet or beat 79/150 with no dimension regressing below its baseline row. Self-assessment is replaced by adversarial re-measurement — the same discipline this repo already applies to code via `mix verify.*`.

**Verdict:** TIGHTEN — keep the eight gate questions but convert every answer from self-certified prose into a testable condition bound to the BOOK-07 baseline rerun.

---

## Traceability

- **AUD-01:** satisfied by sections 1–14 (14 verdicts), the 15-dimension scorecard (section 3), and the explicit antipattern findings (E1–E3, sections 4, 5, 8).
- **AUD-02:** satisfied by the executed 8-surface Stress-Test Matrix (Evidence Base) interpreted in section 4.
- **BOOK-07 baseline:** section 3 scorecard, total 79/150 — supersedes `brandbook/pressure-test.md` Section 3.
- **Plan 03 routing surface:** GAP-01…GAP-12 (section 5), UP-01…UP-11 (section 6) — every REWORK/ADD finding above maps to at least one GAP/UP ID.
- **Out of scope, flagged for human review:** trademark/legal clearance of any new mark (per CONTEXT.md deferred list).

---

## Appendix A — Full `<text>` grep output

Complete, untrimmed output of `grep -n '<text' brandbook/*.svg brandbook/examples/*.svg` as run on 2026-06-12 against the committed assets. 73 matching lines across 11 of 13 SVGs; only `favicon.svg` and `logo-mark.svg` are text-free.

```
brandbook/logo-monochrome.svg:13:  <text x="108" y="58" fill="#0F1728" font-family="Geist, Inter, system-ui, sans-serif" font-size="36" font-weight="600" letter-spacing="0">Threadline</text>
brandbook/logo-monochrome.svg:14:  <text x="111" y="78" fill="#3B4762" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="10" font-weight="500" letter-spacing="2.4">FOLLOW WHAT HAPPENED</text>
brandbook/social-card.svg:27:  <text x="96" y="162" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="78" font-weight="600">Threadline</text>
brandbook/social-card.svg:28:  <text x="102" y="220" fill="#4EDFD1" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="22" font-weight="500" letter-spacing="5">FOLLOW WHAT HAPPENED</text>
brandbook/social-card.svg:29:  <text x="96" y="525" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="34" font-weight="500">Audit history for Phoenix, Ecto, and PostgreSQL.</text>
brandbook/social-card.svg:30:  <text x="96" y="572" fill="#A3AFC2" font-family="Geist, Inter, system-ui, sans-serif" font-size="24">Capture changes. Connect context. Explain the timeline.</text>
brandbook/logo-primary.svg:17:  <text x="108" y="58" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="36" font-weight="600" letter-spacing="0">Threadline</text>
brandbook/logo-primary.svg:18:  <text x="111" y="78" fill="#8F9DB5" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="10" font-weight="500" letter-spacing="2.4">FOLLOW WHAT HAPPENED</text>
brandbook/logo-primary-light.svg:17:  <text x="108" y="58" fill="#0F1728" font-family="Geist, Inter, system-ui, sans-serif" font-size="36" font-weight="600" letter-spacing="0">Threadline</text>
brandbook/logo-primary-light.svg:18:  <text x="111" y="78" fill="#3B4762" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="10" font-weight="500" letter-spacing="2.4">FOLLOW WHAT HAPPENED</text>
brandbook/examples/components.svg:5:  <text x="48" y="64" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="30" font-weight="600">Component primitives</text>
brandbook/examples/components.svg:7:    <rect width="190" height="44" rx="6" fill="#4F8CFF"/><text x="24" y="28" fill="#08101F" font-family="Geist, Inter, system-ui, sans-serif" font-size="15" font-weight="600">Read the docs</text>
brandbook/examples/components.svg:8:    <rect x="210" width="190" height="44" rx="6" fill="#141B2D" stroke="#2E3D5C"/><text x="234" y="28" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="15" font-weight="600">View on GitHub</text>
brandbook/examples/components.svg:9:    <rect x="420" width="96" height="28" rx="14" fill="rgba(78,223,209,.12)" stroke="rgba(78,223,209,.3)"/><text x="438" y="19" fill="#5AE0A2" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="12">proven</text>
brandbook/examples/components.svg:13:    <text x="24" y="36" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="18" font-weight="600">Context-rich history</text>
brandbook/examples/components.svg:14:    <text x="24" y="66" fill="#A3AFC2" font-family="Geist, Inter, system-ui, sans-serif" font-size="15">Connect changes to actor, action,</text>
brandbook/examples/components.svg:15:    <text x="24" y="88" fill="#A3AFC2" font-family="Geist, Inter, system-ui, sans-serif" font-size="15">request, job, and transaction.</text>
brandbook/examples/components.svg:20:    <text x="24" y="38" fill="#9AB9FF" font-family="Geist, Inter, system-ui, sans-serif" font-size="16" font-weight="600">Coverage needs attention</text>
brandbook/examples/components.svg:21:    <text x="24" y="68" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="15">Three expected tables are missing</text>
brandbook/examples/components.svg:22:    <text x="24" y="90" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="15">deployed triggers. Rerun the generator.</text>
brandbook/examples/components.svg:26:    <text x="24" y="38" fill="#4EDFD1" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="14">$ mix threadline.health.coverage</text>
brandbook/examples/components.svg:27:    <text x="24" y="72" fill="#D7DEEA" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="14">covered: posts, users</text>
brandbook/examples/components.svg:28:    <text x="24" y="104" fill="#FFD166" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="14">missing: ticket_replies</text>
brandbook/examples/palette.svg:5:  <text x="48" y="62" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="30" font-weight="600">Threadline palette</text>
brandbook/examples/palette.svg:6:  <text x="48" y="94" fill="#8F9DB5" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="12" letter-spacing="2">RAW COLORS AND PRACTICAL ROLES</text>
brandbook/examples/palette.svg:8:    <g transform="translate(48 132)"><rect width="132" height="96" rx="8" fill="#0B1020" stroke="#23304A"/><text y="124">Black</text><text y="144" fill="#8F9DB5">#0B1020</text></g>
brandbook/examples/palette.svg:9:    <g transform="translate(204 132)"><rect width="132" height="96" rx="8" fill="#141B2D" stroke="#23304A"/><text y="124">Graphite</text><text y="144" fill="#8F9DB5">#141B2D</text></g>
brandbook/examples/palette.svg:10:    <g transform="translate(360 132)"><rect width="132" height="96" rx="8" fill="#23304A"/><text y="124">Slate Line</text><text y="144" fill="#8F9DB5">#23304A</text></g>
brandbook/examples/palette.svg:11:    <g transform="translate(516 132)"><rect width="132" height="96" rx="8" fill="#D7DEEA"/><text y="124">Fog</text><text y="144" fill="#8F9DB5">#D7DEEA</text></g>
brandbook/examples/palette.svg:12:    <g transform="translate(672 132)"><rect width="132" height="96" rx="8" fill="#F7F9FC"/><text y="124">Paper</text><text y="144" fill="#8F9DB5">#F7F9FC</text></g>
brandbook/examples/palette.svg:13:    <g transform="translate(48 324)"><rect width="132" height="96" rx="8" fill="#4F8CFF"/><text y="124">Thread Blue</text><text y="144" fill="#8F9DB5">#4F8CFF</text></g>
brandbook/examples/palette.svg:14:    <g transform="translate(204 324)"><rect width="132" height="96" rx="8" fill="#4EDFD1"/><text y="124">Signal Cyan</text><text y="144" fill="#8F9DB5">#4EDFD1</text></g>
brandbook/examples/palette.svg:15:    <g transform="translate(360 324)"><rect width="132" height="96" rx="8" fill="#8A7CFF"/><text y="124">Iris</text><text y="144" fill="#8F9DB5">#8A7CFF</text></g>
brandbook/examples/palette.svg:16:    <g transform="translate(516 324)"><rect width="132" height="96" rx="8" fill="#FF8A5B"/><text y="124">Ember</text><text y="144" fill="#8F9DB5">#FF8A5B</text></g>
brandbook/examples/palette.svg:17:    <g transform="translate(672 324)"><rect width="132" height="96" rx="8" fill="#3FD08F"/><text y="124">Success</text><text y="144" fill="#8F9DB5">#3FD08F</text></g>
brandbook/examples/landing-hero.svg:11:  <text x="80" y="116" fill="#4EDFD1" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="15" letter-spacing="4">THREADLINE</text>
brandbook/examples/landing-hero.svg:12:  <text x="80" y="220" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="72" font-weight="600">Follow what happened.</text>
brandbook/examples/landing-hero.svg:13:  <text x="84" y="284" fill="#A3AFC2" font-family="Geist, Inter, system-ui, sans-serif" font-size="24">Audit history for Phoenix, Ecto, and PostgreSQL.</text>
brandbook/examples/landing-hero.svg:14:  <rect x="82" y="334" width="192" height="50" rx="6" fill="#4F8CFF"/><text x="111" y="366" fill="#08101F" font-family="Geist, Inter, system-ui, sans-serif" font-size="16" font-weight="600">Read the docs</text>
brandbook/examples/landing-hero.svg:15:  <rect x="292" y="334" width="170" height="50" rx="6" fill="#141B2D" stroke="#2E3D5C"/><text x="323" y="366" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="16" font-weight="600">GitHub</text>
brandbook/examples/docs-page.svg:9:    <text x="34" y="132" fill="#0F1728" font-weight="600">Start here</text>
brandbook/examples/docs-page.svg:10:    <text x="34" y="174" fill="#3B4762">Getting started</text>
brandbook/examples/docs-page.svg:11:    <text x="34" y="214" fill="#3B4762">How Threadline works</text>
brandbook/examples/docs-page.svg:12:    <text x="34" y="254" fill="#1557C0">Operator surface</text>
brandbook/examples/docs-page.svg:13:    <text x="34" y="294" fill="#3B4762">Integration contracts</text>
brandbook/examples/docs-page.svg:15:  <text x="328" y="106" fill="#0F1728" font-family="Geist, Inter, system-ui, sans-serif" font-size="42" font-weight="600">Operator surface</text>
brandbook/examples/docs-page.svg:16:  <text x="328" y="150" fill="#3B4762" font-family="Geist, Inter, system-ui, sans-serif" font-size="18">Mount a fail-closed audit console inside your Phoenix app.</text>
brandbook/examples/docs-page.svg:18:  <text x="360" y="250" fill="#4EDFD1" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="14">scope "/audit", MyAppWeb do</text>
brandbook/examples/docs-page.svg:19:  <text x="360" y="284" fill="#D7DEEA" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="14">  pipe_through [:browser, :require_authenticated_admin]</text>
brandbook/examples/docs-page.svg:20:  <text x="360" y="318" fill="#D7DEEA" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="14">  threadline_operator_surface "/"</text>
brandbook/examples/docs-page.svg:21:  <text x="360" y="352" fill="#4EDFD1" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="14">end</text>
brandbook/examples/docs-page.svg:23:  <text x="352" y="458" fill="#1557C0" font-family="Geist, Inter, system-ui, sans-serif" font-size="16" font-weight="600">Host-owned authorization</text>
brandbook/examples/docs-page.svg:24:  <text x="352" y="488" fill="#3B4762" font-family="Geist, Inter, system-ui, sans-serif" font-size="15">Threadline provides the surface. Your app decides who can see it.</text>
brandbook/examples/typography.svg:5:  <text x="56" y="88" fill="#0F1728" font-family="Geist, Inter, system-ui, sans-serif" font-size="56" font-weight="600">Follow what happened.</text>
brandbook/examples/typography.svg:6:  <text x="60" y="138" fill="#3B4762" font-family="Geist, Inter, system-ui, sans-serif" font-size="20">Geist carries the product voice: precise, readable, and calm.</text>
brandbook/examples/typography.svg:7:  <text x="60" y="204" fill="#73819C" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="13" font-weight="500" letter-spacing="2">METADATA AND CODE USE IBM PLEX MONO</text>
brandbook/examples/typography.svg:9:  <text x="88" y="280" fill="#8F9DB5" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="15">iex&gt; Threadline.timeline([table: "posts"], repo: MyApp.Repo)</text>
brandbook/examples/typography.svg:10:  <text x="88" y="318" fill="#4EDFD1" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="15">[%{action: :update, actor: "user:42", subject: "posts:9"}]</text>
brandbook/examples/typography.svg:11:  <text x="88" y="376" fill="#D7DEEA" font-family="Geist, Inter, system-ui, sans-serif" font-size="22" font-weight="600">Readable timelines beat raw audit noise.</text>
brandbook/examples/typography.svg:12:  <text x="88" y="405" fill="#A3AFC2" font-family="Geist, Inter, system-ui, sans-serif" font-size="16">Use mono for identifiers, request IDs, table names, and diffs. Do not set long prose in mono.</text>
brandbook/examples/readme-header.svg:7:  <text x="72" y="180" fill="#0F1728" font-family="Geist, Inter, system-ui, sans-serif" font-size="34" font-weight="600">Auditing for Phoenix.</text>
brandbook/examples/readme-header.svg:8:  <text x="72" y="224" fill="#3B4762" font-family="Geist, Inter, system-ui, sans-serif" font-size="18">Capture database changes, connect them to actions and request context, and follow the full history.</text>
brandbook/examples/readme-header.svg:10:    <rect x="72" y="270" width="116" height="28" rx="14" fill="#EEF3FA" stroke="#C9D3E2"/><text x="91" y="289" fill="#1557C0">Hex.pm</text>
brandbook/examples/readme-header.svg:11:    <rect x="200" y="270" width="124" height="28" rx="14" fill="#EEF3FA" stroke="#C9D3E2"/><text x="218" y="289" fill="#1557C0">HexDocs</text>
brandbook/examples/readme-header.svg:12:    <rect x="336" y="270" width="96" height="28" rx="14" fill="#EEF3FA" stroke="#C9D3E2"/><text x="357" y="289" fill="#136C47">CI</text>
brandbook/examples/terminal.svg:7:  <text x="56" y="34" fill="#8F9DB5" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="12" letter-spacing="2">TERMINAL / COPYABLE / LOW DRAMA</text>
brandbook/examples/terminal.svg:9:    <text x="86" y="132" fill="#4EDFD1">$ mix threadline.gen.triggers --tables posts</text>
brandbook/examples/terminal.svg:10:    <text x="86" y="172" fill="#D7DEEA">Generated migration for posts audit capture.</text>
brandbook/examples/terminal.svg:11:    <text x="86" y="212" fill="#4EDFD1">$ mix threadline.health.coverage</text>
brandbook/examples/terminal.svg:12:    <text x="86" y="252" fill="#5AE0A2">covered: posts</text>
brandbook/examples/terminal.svg:13:    <text x="86" y="292" fill="#8F9DB5">next: run mix ecto.migrate in the host app</text>
```

Note on the appendix evidence itself: `landing-hero.svg:11` shows the brand name set as letter-spaced mono `<text>` ("THREADLINE") — a fourth place the name is typeset live rather than drawn, reinforcing GAP-03; and `docs-page.svg:9-13` inherits `font-family` from a parent `<g>`, so even text without an inline `font-family` attribute is font-dependent.
