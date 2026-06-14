---
phase: 170-brand-alignment-closeout
reviewed: 2026-06-14T16:02:35Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - test/threadline/brandbook_token_parity_test.exs
  - brandbook/tokens.json
  - brandbook/tokens.css
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 170: Code Review Report

**Reviewed:** 2026-06-14T16:02:35Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

The phase reconciles the brandbook token artifacts (`tokens.json`, `tokens.css`) to
the shipped `style.ex` source of truth and adds `brandbook_token_parity_test.exs` as a
CI gate against drift. I verified the parsing logic, ran the suite (7 tests, 0 failures),
and traced each of the 18 parity tokens to non-nil values on all four lanes (style.ex
dark/light, tokens.json dark/light) plus the secondary tokens.css cross-check.

The light-block parsing is **correct**: `style_light_tokens` anchors on the exact
`[data-tl-theme="light"] {` selector (which appears exactly once — the descendant rules
`[data-tl-theme="light"] .tl-table {` do not match because of the ` .tl-table` infix)
and trims before the first `@media`, correctly excluding the identical-valued
`[data-tl-theme="system"]` block. Pitfall 3 is genuinely avoided. The dark-block parsing
correctly captures the unscoped `.threadline-ui { ... }` base block before the first
`[data-tl-theme` selector.

No blockers. The findings are robustness/brittleness gaps in the gate's design and one
real token-data inconsistency in `tokens.json` that the gate does not cover.

## Warnings

### WR-01: Parity assertions pass vacuously when both sides are nil

**File:** `test/threadline/brandbook_token_parity_test.exs:98-104, 113-119`
**Issue:** The parity assertion is `assert style_val == brand_val`, where both values come
from `Map.get/2` (returns `nil` on miss). If a token in `@parity_intersection` is ever
renamed in BOTH `style.ex` and the brandbook, or if a name typo is introduced into the
`@parity_intersection` list, both lookups return `nil` and `nil == nil` passes — the gate
silently stops protecting that token. The whole point of the keystone test is "fails CI on
any future drift," but a coordinated rename or a list typo evades it. I confirmed all 18
tokens currently resolve non-nil on all four lanes, so this is latent, not live.
**Fix:** Assert presence before equality, e.g.:
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

### WR-02: `tokens.json` warning palette is internally inconsistent with the shipped value

**File:** `brandbook/tokens.json:28, 174-175` (and `raw.color.warning-dark-text:28`)
**Issue:** `semantic.dark.warning-text` is `#F6C86B` (correctly mirrors `style.ex:95` and
passes the parity gate), but `raw.color.warning-dark-text` (line 28) and
`callout.warning.text` (line 174) are still `#FFD166` — the pre-alignment value. The
shipped operator surface has no `#FFD166` anywhere; `style.ex:95-96` uses `#F6C86B`. So the
brandbook simultaneously claims two different "dark warning text" colors. The parity test
does NOT cover `raw.*` or `callout.*`, so this drift is invisible to CI. This is exactly the
class of silent regression the phase set out to eliminate, left in a corner the gate
doesn't reach.
**Fix:** Update `tokens.json` `raw.color.warning-dark-text` and `callout.warning.text` to
`#F6C86B` to match the reconciled semantic value (and the shipped `--tl-color-warning-text`),
or confirm intent and add a comment. If callouts are meant to be brand-only and may diverge,
say so explicitly in `excluded_from_brand_scope._notes`.

### WR-03: `code` and `callout` token groups are unguarded by any parity/cross-file test

**File:** `brandbook/tokens.json:148-180`, `brandbook/tokens.css:103-114`
**Issue:** `style.ex` defines no `--tl-code-*` or `--tl-callout-*` custom properties at all
(confirmed: zero matches in the source). The brandbook's `code` and `callout` groups
therefore have no source-of-truth anchor, and the parity test only checks the 18 semantic
color tokens — it never compares `code`/`callout` between `tokens.json` and `tokens.css`.
These hand-duplicated values can drift freely. WR-02 is a concrete instance already present
in this exact gap. The `tokens.css` callout/code values I checked happen to match
`tokens.json` today, but nothing enforces it.
**Fix:** Either extend the secondary cross-file test to assert `code`/`callout` parity
between `tokens.json` and `tokens.css`, or document in `excluded_from_brand_scope._notes`
that these groups are brand-only and intentionally outside the mechanical gate.

### WR-04: Destructuring `[_, x | _] = String.split(...)` raises MatchError instead of a guided failure

**File:** `test/threadline/brandbook_token_parity_test.exs:61, 73-74, 87`
**Issue:** Each parser uses pattern-match destructuring on `String.split/2`. If a future
refactor renames or removes the `[data-tl-theme="light"] {` selector, the `.tl-theme-dark,`
selector, or causes `style.ex` to no longer contain `[data-tl-theme`, the match
`[_, after_light | _] = ...` raises a bare `MatchError` (split returns a single-element
list). For a keystone governance test the failure should explain the contract that broke,
not surface as an opaque pattern-match error that a contributor must reverse-engineer.
**Fix:** Validate the anchor exists before splitting, e.g.:
```elixir
defp style_light_tokens do
  src = style_source()
  assert String.contains?(src, ~s([data-tl-theme="light"] {)),
         "style.ex no longer carries the [data-tl-theme=\"light\"] block — light parity anchor lost"
  ...
end
```
(or wrap the split result in a `case` with a custom-message failure). This also hardens
WR-01's stale-intersection scenario.

## Info

### IN-01: Light-block parse depends on `@media` ordering, undocumented as a hard invariant

**File:** `test/threadline/brandbook_token_parity_test.exs:72-76`
**Issue:** `style_light_tokens` trims `after_light` at the first `@media`. This is correct
only because the light color block (`style.ex:188-237`) contains no `@media` and the first
`@media` in the file (line 239) follows it. The inline comment explains the `system`-block
rationale but not that "the light block must contain zero `@media` and must precede the
first `@media`" is the load-bearing invariant. A future `@media` nested inside the light
block (e.g., a `prefers-reduced-motion` tweak) would silently truncate the parsed token set,
re-enabling the WR-01 vacuous-pass for the dropped tokens.
**Fix:** Add a one-line assertion or comment pinning the invariant, e.g. assert the parsed
light map size equals the count of `--tl-color-` declarations between the selector and the
next selector, or note "light color block must stay `@media`-free."

### IN-02: `tokens.css` carries `-raw`-suffixed aliases that shadow semantic names

**File:** `brandbook/tokens.css:41-42, 44`
**Issue:** `:root, .tl-brand` defines `--tl-color-surface-raised-raw`, `--tl-color-surface-hover-raw`,
`--tl-color-border-strong-raw`. These are deliberately suffixed to avoid colliding with the
semantic `--tl-color-surface-raised` etc., and the test's `css_block_tokens` only scans the
`.tl-theme-dark,` / `.tl-theme-light {` blocks, so they are not parsed. No bug today, but the
naming is a footgun: a future edit that drops the `-raw` suffix would inject a second,
palette-level definition of a semantic token into the brand stylesheet with no test to catch
it. Worth a comment noting the suffix is intentional collision-avoidance.
**Fix:** Add a comment in `tokens.css` above the raw palette block explaining the `-raw`
suffix convention.

### IN-03: Doc-contract assertions use substring matching that can pass on incidental text

**File:** `test/threadline/brandbook_token_parity_test.exs:165-194`
**Issue:** The `brand-book.md` / `pressure-test.md` contract tests use `String.contains?`
for short literals like `"dimension #5"`, `"dark-primary"`, `"UI theming posture"`. These
match anywhere in the document, including prose that happens to mention the phrase, so the
test can pass even if the intended subsection were deleted but the words survive elsewhere.
Lower-stakes than the token gate (these are doc-presence smoke checks), but worth noting the
assertions verify "the string exists somewhere," not "the section exists."
**Fix:** Anchor to the heading form where it matters (e.g. `"### UI theming posture"` is
already used on line 168 — apply the same heading-anchored style to the weaker checks like
`"dimension #5"` where feasible).

---

_Reviewed: 2026-06-14T16:02:35Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
