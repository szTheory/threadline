# Threadline Brand Pressure Test

Adversarial QA for everything in `brandbook/`. Fifteen dimensions, each scored 1-10
against a testable pass condition, for a total out of **150**. Self-assessment is
banned: every score cites a mechanical output (a gate line, a grep result, a measured
geometry) or a direct-open render. Rerun the suite whenever any brand asset changes;
a score is only as current as its evidence.

## The mechanical suite

Run from the repository root. Every command must come back clean before any score below
is trusted.

```sh
# Hard-constraint gate (HC-1..6, tagging, hygiene, tagline isolation) — exit 0 required
node .planning/phases/162-brand-book-v2/tools/brand-gate.mjs brandbook

# Zero live text in any SVG (GitHub's sandbox never loads fonts)
grep -rln '<text' brandbook/ --include='*.svg'        # must return nothing

# Zero rect elements (container chips and plates are banned; the social-card
# background is a tagged path, not a rect)
grep -rln '<rect' brandbook/ --include='*.svg'        # must return nothing

# Tagline isolation — exactly two sanctioned files
grep -rln 'FOLLOW WHAT HAPPENED' brandbook/           # logo-primary-subtitle.svg + social-card.svg only

# No network reach from the book itself
grep -nE 'src="http|href="http' brandbook/index.html  # must return nothing

# Well-formed XML across every SVG
for f in brandbook/*.svg brandbook/examples/*.svg; do xmllint --noout "$f" || echo "BAD $f"; done

# Size budget: 300KB for the whole directory
find brandbook -type f ! -name '.DS_Store' -print0 | xargs -0 du -ck | tail -1

# Text-only formats, no binaries
git ls-files brandbook/ | grep -vE '[.](svg|html|css|json|md|mjs)$'   # must return nothing
```

For the render checks (dimensions 1, 3, 5, 12, 15), open the file directly in a
browser — `file://` is the honest surface; nothing may depend on a server or a
network — or screenshot it headlessly:

```sh
npx playwright screenshot --viewport-size=1440,900 --full-page \
  "file://$(pwd)/brandbook/index.html" /tmp/brandbook-desktop.png
# Favicon: embed favicon.svg via <img> at 16/32/64px on white and on #0B1020,
# capture once with --color-scheme=light and once with --color-scheme=dark.
```

## Scorecard

| # | Dimension | Score | Evidence in one line |
|---|---|---|---|
| 1 | Distinctiveness | 8 / 10 | The stitch arc is load-bearing: deleting it leaves visibly cut d/l stems, so the construction cannot be mistaken for a generic wordmark-plus-ornament |
| 2 | Mark/type integration | 9 / 10 | Arc stroke width (128 units) equals the measured stem width; both ascenders are cut at y=444 to receive it — mark and type share literal geometry |
| 3 | 16px survival | 8 / 10 | `favicon.svg` is drawn at `viewBox="0 0 16 16"`: gate lines `HC-4-stroke 1.70px at 16px canvas` and `HC-4-count 2 painted elements (<= 4)` PASS; identifiable at a literal 16px render |
| 4 | Monochrome survival | 9 / 10 | `logo-monochrome.svg` paint inventory is exactly `{currentColor, none}` — flatten-to-one-color is the identity operation; gate line `HC-5 single flat color: currentcolor` PASS |
| 5 | Dark/light versatility | 9 / 10 | Designed light rendition (Ink #0F1728 glyphs), scheme-invariant #4781E6 arc (5.0:1 dark, 3.78:1 light), committed `<picture>` snippet + live demo, scheme-flip favicon, currentColor mark |
| 6 | Portability (no font dependency) | 10 / 10 | `grep -rln '<text' brandbook/ --include='*.svg'` returns nothing; HC-6 PASS on all 10 SVGs — a fontless sandbox renders the identical letterforms by construction |
| 7 | Scalability | 8 / 10 | Size-specific cuts exist (16px favicon, 64px mark idiom, documented per-asset minimums); no hairlines, no opacity tiers, no sub-floor strokes anywhere in the family |
| 8 | Voice | 9 / 10 | Say-this/not-this pairs, a banned-vocabulary list, and testable writing rules in `brand-book.md`; every banned-word grep hit is the ban rule quoting itself or a not-this counter-example — none in real copy |
| 9 | Palette | 8 / 10 | Night-infrastructure tokens with dark/light semantic lanes; the two blues carry documented, non-overlapping jobs (#4F8CFF interface accent, #4781E6 the arc's ink) |
| 10 | Typography | 8 / 10 | Geist + IBM Plex Mono with OFL licensing in-repo, role table and tracking rules; deployed wordmarks are pure paths so the type system never depends on a viewer's fonts |
| 11 | Token rigor | 8 / 10 | `tokens.json` parses; JSON and CSS lanes carry identical values; raw/semantic layering intact; product-UI contract (`lib/threadline/operator_surface/style.ex`) untouched |
| 12 | Application coverage | 8 / 10 | Every committed specimen renders correctly on the surface it models (inlined geometry, zero `<image href>`, zero text); index.html covers component, palette, type, and terminal roles natively |
| 13 | Misuse guidance | 9 / 10 | Six rendered Don't specimens + one Do reference in index.html, with numeric thresholds (1.5px target / 1.0px floor strokes at 16px, ≥1.0px gaps, ≤4 elements, design-at-16px) |
| 14 | Consistency | 9 / 10 | No asset contradicts its own description: the monochrome is one color, the favicon has no chip, every minimum-size rule is satisfied by the asset it governs — enforced by the gate, not by promise |
| 15 | Craft | 8 / 10 | Geometry is derived, not eyeballed: arc width from measured stems, shared cut height, favicon drawn at its native canvas; every painted path carries a data-glyph/data-role tag |
| | **Total** | **128 / 150** | |

## The dimensions, with pass conditions

### 1. Distinctiveness

**Pass condition:** remove the motif from the primary lockup; if what remains is a
complete generic wordmark, the motif is decoration and the identity fails. The mark
must be structural — something a competitor could not bolt onto their own type.
**Check:** delete the `data-role="mark"` arc path from `logo-primary.svg` and render —
the d and l ascenders end in flat cuts at y=444, visibly incomplete.
**Score: 8/10.** The arc-through-the-word construction is ownable and the removal test
fails loudly. Two points held back: distinctiveness against named competitors is a
judgment only market exposure settles, and the base letterforms are an unmodified
Geist 600 beneath the cut.

### 2. Mark/type integration

**Pass condition:** mark and type share literal geometry — a stroke, counter, or grid
both halves depend on. Eyeballed adjacency fails.
**Check:** in `logo-primary.svg`, the arc stroke-width is 128 font units, equal to the
measured stem width of the Geist 600 glyphs it joins; both ascender stems are cut at
y=444 where the arc enters. The same numbers recur byte-identically in the light,
monochrome, subtitle, and social-card files.
**Score: 9/10.** Integration is arithmetical, not optical. The single held-back point:
the arc touches two letters; the remaining eight glyphs participate only through
shared metrics.

### 3. 16px survival

**Pass condition:** a dedicated artifact drawn at a 16px canvas — never larger art
shrunk — with strokes ≥1.5px (1.0px absolute floor), gaps ≥1.0px, ≤4 distinct
elements, and a silhouette identifiable without interior detail or color.
**Check:** `node .planning/phases/162-brand-book-v2/tools/brand-gate.mjs brandbook` —
the favicon rows must read `HC-4-stroke 1.70px at 16px canvas` and
`HC-4-count 2 painted elements (<= 4)`. Then render `favicon.svg` at a literal 16px
`<img>` on white and on #0B1020 and look at it.
**Score: 8/10.** Both gate lines PASS; the 16px render reads as one stitch through a
fabric line in both schemes. Not higher because at 16px the form is minimal by
necessity — it identifies, but the full lockup's character only returns at 24px+.

### 4. Monochrome survival

**Pass condition:** replace every fill and stroke with one flat color — no opacity
tiers, no gradients, no overlap-as-tone. The flattened mark must be structurally
identical to the original.
**Check:** `grep -oE '(fill|stroke)="[^"]*"' brandbook/logo-monochrome.svg | sort -u`
returns exactly `fill="currentColor"`, `fill="none"`, `stroke="currentColor"`; the
gate row reads `HC-5 single flat color: currentcolor`.
**Score: 9/10.** The master is already one color, so flattening changes nothing — the
strongest possible position. One point held back: in one-color reproduction the arc
loses its blue distinction from the stems and reads purely by shape, which works but
carries less of the identity.

### 5. Dark/light versatility

**Pass condition:** every single-slot or auto-switching surface gets a working asset:
an explicit designed pair for READMEs, an adaptive single asset for one-logo slots,
and a documented switching mechanism a consumer can paste.
**Check:** `logo-primary-light.svg` exists and passes HC-1 with Ink #0F1728 glyphs (a
designed rendition, not a recolor); `logo-mark.svg` strokes are `currentColor`;
`favicon.svg` carries an internal `prefers-color-scheme` flip; `index.html` commits the
escaped `<picture>` snippet and a live demo of it.
**Score: 9/10.** All four mechanisms are committed and render correctly under both
color schemes via direct file open. One point held back: the #4781E6 arc sits at
3.78:1 on white — above the 3:1 graphics floor and visually strong, but with less
margin than its 5.0:1 dark-surface footing.

### 6. Portability (no font dependency)

**Pass condition:** zero `<text>` elements anywhere in the SVG corpus; a sandbox that
loads no fonts renders letterforms identical to a font-installed machine.
**Check:** `grep -rln '<text' brandbook/ --include='*.svg'` returns nothing; the gate
reports HC-6 PASS for all 10 SVGs.
**Score: 10/10.** The condition is binary and met by construction: every glyph is an
outlined path, so there is nothing a fontless environment can substitute. Accessible
names travel in `aria-label`/`<desc>` metadata, which renders nowhere.

### 7. Scalability

**Pass condition:** the family covers its size range with size-specific cuts and
stated floors — no asset is asked to survive below the geometry it carries; nothing
relies on hairlines or opacity that dies small.
**Check:** `favicon.svg` (native 16px) and `logo-mark.svg` (the same idiom at 64px)
are separate drawings; minimums are documented per asset (120px wordmark-bearing
lockups, 180px subtitle lockup, 16px mark) in `brand-book.md` and `index.html`;
`grep -i 'opacity' brandbook/*.svg` returns nothing.
**Score: 8/10.** Every committed size has an artifact designed for it and the floors
are numeric. Held back: the range is covered at two anchor sizes plus the lockups;
intermediate marks (24/32px) reuse the 64px idiom rather than their own cuts — fine
in practice, less than a full size ramp.

### 8. Voice

**Pass condition:** the voice is enforceable, not aspirational: say-this/not-this
pairs, a banned-vocabulary list, and rules a reviewer can apply mechanically.
**Check:** `brand-book.md` carries the pairs, the writing rules, and full microcopy
patterns for error/empty/success/warning states;
`grep -inE 'provenance|governance|chain of custody|forensic-grade|seamless|next-generation' brandbook/brand-book.md brandbook/index.html`
returns only sanctioned mentions: the ban rule quoting the words it bans, and the
"not this" counter-example blockquote. Any hit in real copy fails.
**Score: 9/10.** Four matches, all inside the rule and its counter-example — none in
live copy — and the microcopy patterns use real domain nouns and real mix tasks. The
held-back point is permanent: prose quality beyond the mechanical rules still needs a
human reader.

### 9. Palette

**Pass condition:** a disciplined token-backed palette with dark and light semantic
lanes; every hex in any committed asset traces to a token or a documented decision;
no two colors hold the same job.
**Check:** every paint value in `brandbook/*.svg` is either `currentColor`, `none`, or
a hex documented in `tokens.json` (the arc's #4781E6 is the raw `stitch-blue` /
semantic `logo-arc` token); the two-blues rule is written down: #4F8CFF interface
accent, #4781E6 the arc's ink.
**Score: 8/10.** The lanes are intact and the one ambiguity a two-blue system invites
is explicitly resolved in both `brand-book.md` and `index.html`. Not higher: the
palette's breadth (five signature accents) is wider than current applications
exercise.

### 10. Typography

**Pass condition:** named faces with licenses in-repo, role assignments, tracking
rules — and no deployed asset that depends on those faces being installed.
**Check:** Geist and IBM Plex Mono (both OFL, in `priv/fonts/`) carry the roles;
`brand-book.md` states the role table and tracking numbers; the wordmark and tagline
ship as outlined paths (dimension 6's grep covers this mechanically).
**Score: 8/10.** The system is complete and the portability trap is closed by
construction. Held back: the type story rests on two faces' defaults — tracking and
the subtitle pitch are tuned, but no custom letterform work exists outside the cut
ascenders.

### 11. Token rigor

**Pass condition:** dual-format tokens (JSON + CSS) with raw/semantic layering and
dark/light lanes that carry identical values; brand tokens never leak into the
product-UI contract.
**Check:** `node -e "JSON.parse(require('fs').readFileSync('brandbook/tokens.json'))"`
exits 0; every custom property in `tokens.css` has a matching `tokens.json` entry;
`lib/threadline/operator_surface/style.ex` contains no brandbook-driven change.
**Score: 8/10.** Both formats parse, values match, and the product contract is
untouched. The known debt holds the score: JSON and CSS are hand-duplicated with no
generated sync check, so drift is prevented by review rather than tooling.

### 12. Application coverage

**Pass condition:** every committed specimen renders correctly on the surface it
models — a README specimen must survive GitHub's sandbox, a docs specimen must carry
its own geometry. A specimen that breaks on its own surface is worse than no specimen.
**Check:** `grep -rn '<image' brandbook/ --include='*.svg'` returns nothing (no
external embeds); both `examples/*.svg` pass HC-6 and HYGIENE; `index.html` shows
component, palette, terminal, and type applications natively in HTML/CSS plus the
social card and both specimens.
**Score: 8/10.** Coverage is honest: two SVG specimens that actually work, with the
prose-heavy roles carried by the book itself where live text is correct. Held back:
no committed specimen yet models Hex.pm or HexDocs chrome specifically — the adaptive
mark covers the slot, but no rendered example shows it there.

### 13. Misuse guidance

**Pass condition:** misuse is shown, not just told — rendered Don't specimens a
contributor can compare against, plus numeric small-size thresholds that make
"too small" checkable.
**Check:** `index.html`'s Misuse section renders one Do reference and six Don'ts
(container chip, icon bolted beside plain text, tagline as primary, gradient
dependence, stretch/squash, off-palette recolor) as inline SVG only —
`git ls-files brandbook/ | grep -i misuse` returns nothing, so no antipattern ships as
a reusable file; the thresholds panel states the 16px numbers.
**Score: 9/10.** Every killed pattern is visible and the thresholds are numeric. One
point held back: the gallery covers the six known failure modes; misuse taxonomies
grow with exposure, and the gallery must grow with them.

### 14. Consistency

**Pass condition:** no asset contradicts its own description or the book's rules:
the one-color asset is one color, stated minimums are satisfied by the assets they
govern, banned patterns appear nowhere outside the misuse gallery.
**Check:** the gate enforces this corpus-wide on every run — HC-1 (glyph inventory),
HC-2 (no chips/rects), HC-5 (mono purity), HC-6 (no text), BOOK-02 (tagline
isolation), TAGGING (every painted path classified). Current run:
`10 files reported, 0 FAIL, 0 WARN`.
**Score: 9/10.** Consistency is mechanically enforced rather than promised — the
strongest property a brand system can have. Held back one point because `index.html`'s
inline renders duplicate the asset geometry, and that duplication is kept honest by
review, not by the gate.

### 15. Craft

**Pass condition:** geometry is derived and reproducible — measured widths, shared
cut heights, native-canvas drawing — with no eyeballed offsets or overdraw hacks; the
book itself looks professional when opened directly.
**Check:** the integration numbers (dimension 2) are arithmetic; the favicon is drawn
at its deployment size; every painted path carries `data-glyph`/`data-role`; open
`index.html` via `file://` at desktop and phone widths — no broken images, no
overflow, no placeholder content.
**Score: 8/10.** The construction is systematic end-to-end and the direct-open render
holds up at 1440px and 390px. Two points held back: optical correction (overshoot,
arc-to-stem junction tuning) is minimal beyond the measured geometry, and craft above
"derived correctly" is exactly where a future revision can spend.

## Reading the total

**128 / 150.** The score stands only while the mechanical suite is green. Any FAIL
from the gate, any non-empty grep, or any budget overrun invalidates the scorecard
until the defect is fixed and the affected dimensions are re-scored against fresh
evidence.
