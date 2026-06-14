---
phase: 170-brand-alignment-closeout
reviewed: 2026-06-14T16:30:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - brandbook/brand-book.md
  - brandbook/pressure-test.md
  - brandbook/tokens.css
  - brandbook/tokens.json
  - test/threadline/brandbook_token_parity_test.exs
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 170: Code Review Report

**Reviewed:** 2026-06-14T16:30:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The phase reconciles the brandbook token artifacts (`tokens.json`, `tokens.css`) to the
shipped `style.ex` source of truth and adds `brandbook_token_parity_test.exs` as a CI
gate against drift. I verified the parsing logic, ran the suite (7 tests, 0 failures),
traced each of the 18 parity tokens to non-nil matching values on all four lanes
(style.ex dark/light, tokens.json dark/light) plus the tokens.css cross-check, and
recomputed the WCAG contrast claims in `brand-book.md` (Stitch Blue 5.0:1 on Threadline
Black, 3.78:1 on white — both accurate).

The light-block parsing is correct: `style_light_tokens` anchors on the exact
`[data-tl-theme="light"] {` selector (which appears once — the descendant rules
`[data-tl-theme="light"] .tl-table {` do not match because of the ` .tl-table` infix)
and trims before the first `@media`, correctly excluding the identical-valued
`[data-tl-theme="system"]` block. Pitfall 3 is genuinely avoided.

The central defect: the brandbook claims one dark warning-text color in the
parity-guarded semantic lane (`#F6C86B`, matching `style.ex`) but a different,
pre-alignment value (`#FFD166`) in three locations the gate does not reach — the raw
token block, the callout block, and the `brand-book.md` prose. The "single source of
truth" is contradicted by the same files that claim to mirror it, and the guard rail has
a hole exactly where the drift landed. No blockers; the rest are robustness gaps in the
gate's design.

## Warnings

### WR-01: Parity assertions pass vacuously when both sides are nil

**File:** `test/threadline/brandbook_token_parity_test.exs:98-104, 113-119`
**Issue:** The parity assertion is `assert style_val == brand_val`, where both values come
from `Map.get/2` (returns `nil` on miss). If a token in `@parity_intersection` is ever
renamed in BOTH `style.ex` and the brandbook, or a name typo is introduced into the
`@parity_intersection` list, both lookups return `nil` and `nil == nil` passes — the gate
silently stops protecting that token. The keystone test's stated purpose is "fails CI on
any future drift," but a coordinated rename or a list typo evades it. All 18 tokens
currently resolve non-nil on all four lanes, so this is latent, not live.
**Fix:** Assert presence before equality:
```elixir
for name <- @parity_intersection do
  style_val = Map.get(style_dark, name)
  brand_val = Map.get(brand_dark, name)

  assert style_val != nil,
         "dark --tl-color-#{name} missing from style.ex — parity intersection is stale"
  assert brand_val != nil,
         "dark #{name} missing from brandbook semantic.dark — parity intersection is stale"
  assert style_val == brand_val, "..."
end
```

### WR-02: tokens.json warning palette is internally inconsistent with the shipped value

**File:** `brandbook/tokens.json:28, 174` (raw `warning-dark-text` and `callout.warning.text`)
**Issue:** `semantic.dark.warning-text` is `#F6C86B` (line 52 — correctly mirrors
`style.ex:95` and passes the parity gate), but `raw.color.warning-dark-text` (line 28) and
`callout.warning.text` (line 174) are still `#FFD166`, the pre-alignment value. The shipped
operator surface has no `#FFD166` anywhere; `style.ex:95-96` uses `#F6C86B`. The brandbook
thus claims two different "dark warning text" colors at once. The parity test covers neither
`raw.*` nor `callout.*`, so this drift is invisible to CI — exactly the class of silent
regression the phase set out to eliminate, left in a corner the gate doesn't reach.
**Fix:** Update both `raw.color.warning-dark-text` and `callout.warning.text` to `#F6C86B`:
```json
"warning-dark-text": "#F6C86B",
...
"warning": { "bg": "rgba(243, 185, 76, 0.16)", "border": "rgba(255, 209, 102, 0.50)", "text": "#F6C86B" }
```

### WR-03: brand-book.md prose states the stale dark warning-text value

**File:** `brandbook/brand-book.md:289`
**Issue:** The Semantic colors section reads
`- Warning: \`#F3B94C\`, with dark-surface text \`#FFD166\`.` The shipped dark-surface
warning text is `#F6C86B` (`style.ex:95`, mirrored at `tokens.json:52` / `tokens.css:100`).
The prose is the human-readable contract a designer reads first, and it now contradicts the
shipped UI and the semantic token lane. The parity test asserts several `brand-book.md`
literals (UI theming posture, THEME-TOGGLE-01, the config triad) but asserts no semantic
color hex, so this prose drift is invisible to CI. Same root cause as WR-02.
**Fix:**
```markdown
- Warning: `#F3B94C`, with dark-surface text `#F6C86B`.
```
Confirm `#F3B94C` (the base warning) is still current against `style.ex` while editing.

### WR-04: code and callout token groups are unguarded by any parity/cross-file test

**File:** `brandbook/tokens.json:148-181`, `brandbook/tokens.css:103-114`
**Issue:** `style.ex` defines no `--tl-code-*` or `--tl-callout-*` custom properties
(confirmed: zero matches). The brandbook's `code` and `callout` groups therefore have no
source-of-truth anchor, and the parity test only checks the 18 semantic color tokens — it
never compares `code`/`callout` between `tokens.json` and `tokens.css`. These
hand-duplicated values can drift freely; WR-02 is a concrete instance already present in
this gap. Additionally the formats are asymmetric: `tokens.json` carries callout `text` and
code `prompt`/`keyword`/`string` keys that have NO `--tl-*` counterpart in `tokens.css`, so
even a CSS-vs-JSON diff would not surface the stale callout text.
**Fix:** Extend the secondary cross-file test to assert `code`/`callout` parity between
`tokens.json` and `tokens.css`, emit the missing CSS custom properties so the formats are
genuinely 1:1, or document in `excluded_from_brand_scope._notes` that these groups are
brand-only and intentionally outside the mechanical gate.

### WR-05: Destructuring `[_, x | _] = String.split(...)` raises MatchError instead of a guided failure

**File:** `test/threadline/brandbook_token_parity_test.exs:61, 73-74, 87`
**Issue:** Each parser pattern-matches on `String.split/2`. If a future refactor renames or
removes `[data-tl-theme="light"] {`, the `.tl-theme-dark,` selector, or removes
`[data-tl-theme` from `style.ex`, the match `[_, after_light | _] = ...` raises a bare
`MatchError` (split returns a single-element list). For a keystone governance test the
failure should explain the contract that broke, not surface as an opaque pattern-match error
a contributor must reverse-engineer.
**Fix:** Validate the anchor exists before splitting:
```elixir
defp style_light_tokens do
  src = style_source()
  assert String.contains?(src, ~s([data-tl-theme="light"] {)),
         "style.ex no longer carries the [data-tl-theme=\"light\"] block — light parity anchor lost"
  ...
end
```
This also hardens WR-01's stale-intersection scenario.

## Info

### IN-01: Light-block parse depends on `@media` ordering, undocumented as a hard invariant

**File:** `test/threadline/brandbook_token_parity_test.exs:72-76`
**Issue:** `style_light_tokens` trims `after_light` at the first `@media`. This is correct
only because the light color block (`style.ex:188-237`) contains no `@media` and the first
`@media` in the file (line 240) follows it. The inline comment explains the `system`-block
rationale but not that "the light block must contain zero `@media` and must precede the first
`@media`" is the load-bearing invariant. A future `@media` nested inside the light block
(e.g. a `prefers-reduced-motion` tweak) would silently truncate the parsed token set,
re-enabling WR-01's vacuous pass for the dropped tokens.
**Fix:** Add a one-line assertion or comment pinning the invariant (e.g. assert the parsed
light map size equals the count of `--tl-color-` declarations in the block, or note "light
color block must stay `@media`-free").

### IN-02: tokens.css carries `-raw`-suffixed aliases that shadow semantic names

**File:** `brandbook/tokens.css:41-42, 44`
**Issue:** `:root, .tl-brand` defines `--tl-color-surface-raised-raw`,
`--tl-color-surface-hover-raw`, `--tl-color-border-strong-raw`. These are suffixed to avoid
colliding with the semantic `--tl-color-surface-raised` etc., and `css_block_tokens` only
scans the `.tl-theme-dark,` / `.tl-theme-light {` blocks, so they are not parsed. No bug
today, but the naming is a footgun: a future edit dropping the `-raw` suffix would inject a
second, palette-level definition of a semantic token into the brand stylesheet with no test
to catch it.
**Fix:** Add a comment above the raw palette block explaining the `-raw` suffix is
intentional collision-avoidance.

### IN-03: Doc-contract assertions use substring matching that can pass on incidental text

**File:** `test/threadline/brandbook_token_parity_test.exs:165-194`
**Issue:** The `brand-book.md` / `pressure-test.md` contract tests use `String.contains?` for
short literals like `"dimension #5"`, `"dark-primary"`, `"UI theming posture"`. These match
anywhere in the document, including prose that incidentally mentions the phrase, so a test
can pass even if the intended subsection were deleted but the words survive elsewhere.
Lower-stakes than the token gate (doc-presence smoke checks), but the assertions verify "the
string exists somewhere," not "the section exists."
**Fix:** Anchor to the heading form where it matters (e.g. `"### UI theming posture"` is
already used on line 168 — apply the same heading-anchored style to weaker checks like
`"dimension #5"` where feasible).

### IN-04: Pressure-test scorecard asserts token rigor 9/10 on a now-falsified premise

**File:** `brandbook/pressure-test.md:69, 207-226`
**Issue:** Dimension 11 states "JSON and CSS lanes carry identical values" and "drift is
caught automatically, not by review." By the scorecard's own rule ("a score is only as
current as its evidence"), the WR-02/WR-03 drift and the WR-04 CSS/JSON asymmetry falsify
those claims for everything outside the 18-token intersection. The 9/10 is not adversarially
earned for the raw/callout/code lanes — the dimension overstates the guarantee's scope.
**Fix:** After fixing WR-02/03/04, either scope the dimension-11 wording to the curated
semantic intersection or extend the mechanical gate to the raw/callout/code lanes before
reasserting 9/10, and re-cite fresh evidence per the suite's own rule.

---

_Reviewed: 2026-06-14T16:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
