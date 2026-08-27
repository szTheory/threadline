# `verify.mechanical` sensitivity probe (GREEN-03)

**Captured:** 2026-08-27
**Captured by:** Phase 198 Plan 01, Task 3
**Question (D-38):** is `MechanicalChecker` sensitive to rendered text content and to text
width, or only to tokens, contrast, and element geometry?
**Method:** executed experiment against synthetic scorecards in `/tmp/198-mechanical-probe/`.
Answered from evidence, not from reading the implementation. **No scorecard under
`.planning/scorecards/` was written, copied, moved, or restored** — see Prohibition check.

## Finding

**`MechanicalChecker` is NOT sensitive to rendered text content and is NOT sensitive to
text width.** It reacts only to design tokens, colour/contrast values, and element style
geometry (radius, shadow, motion, font-size, spacing) plus the MODE-B structural counts.
Changing every rendered text string in a scorecard produced a byte-identical result
(`control == text-content : true`); changing every text-width and bounding-box value
produced a byte-identical result (`control == text-width : true`). Both positive controls
fired in the same run, so the harness demonstrably has teeth.

The deeper reason, confirmed from the committed schema: **the scorecard format does not
capture rendered text or per-element width at all.** There is no `text`, `text_content`,
`innerText`, `width`, or `bounding_box` key anywhere in a committed scorecard. The probe
had to *invent* those fields to have anything to vary — and the checker ignored the
invented fields, exactly as it ignores everything outside the enumerated signal list below.
(`meta.viewport.width` does exist, but it is the browser viewport, not text width, and
`run/1` never reads `meta`.)

## Signals `run/1` actually extracts (derived from source, with line references)

All references are to `lib/threadline/operator_surface/mechanical_checker.ex`.

| # | Signal read | Read at | Used for |
|---|---|---|---|
| 1 | directory listing of `*.json`, minus files prefixed `route.` / `story.` | `:138-162` (`list_scorecards/1`) | which cells are in jurisdiction |
| 2 | `.planning/design-system-ledger.json` → `mechanical_floors` | `:164-169` (`load_floors/0`) | MODE-B ratchet floors |
| 3 | `cell_id` | `:182`, `:286`, `:432` | violation labelling |
| 4 | `tokens["--tl-color-bg"]` | `:183` (`check_wcag/1`) | page background for compositing |
| 5 | `color_pairs[].color` | `:191` (`wcag_violation/3`) | foreground colour |
| 6 | `color_pairs[].background_color` | `:193`, `:214-222` (`resolve_background/2`) | effective background |
| 7 | `color_pairs[].selector` | `:240`, `:246-251` (`ui_component?/1`) | 3.0 vs 4.5 threshold (tag only) |
| 8 | `color_pairs[].font_size` | `:254` (`large_text?/1`) | large-text 3.0 threshold |
| 9 | `color_pairs[].font_weight` | `:255`, `:259-267` (`bold?/1`) | large-text bold threshold |
| 10 | `element_styles[].selector` | `:307`, `:325`, `:342` | violation labelling (string, not measured) |
| 11 | `element_styles[].border_radius` | `:301-316` (`radius_violations/2`) | MODE-A radius token scale |
| 12 | `element_styles[].box_shadow` | `:318-333` (`shadow_violations/2`) | MODE-A shadow geometry signature |
| 13 | `element_styles[].transition_duration` | `:335-351` (`motion_violations/2`) | MODE-A motion token scale |
| 14 | `element_styles[].font_size` | `:353-377` (`font_size_violations/2`) | MODE-A font-size token scale |
| 15 | `element_styles[].margin_top/margin_bottom/padding_top/padding_bottom` | `:379-391` (`spacing_violations/2`) | MODE-A spacing token scale |
| 16 | `ledger_id`, `theme`, `breakpoint` | `:433-434` (`check_mode_b/2`) | floor lookup key `theme_bp` |
| 17 | `mode_b.type_size_count` | `:423` (`measure_mode_b/1`) | MODE-B ratchet |
| 18 | `mode_b.interactive_control_count` | `:424` | MODE-B ratchet |
| 19 | `mode_b.card_nesting_depth` | `:425` | MODE-B ratchet + ceiling 3 (`:34`, `:445`) |
| 20 | `mode_b.scroll_cost` | `:426` | MODE-B ratchet |
| 21 | `applied_colors[]` | `:427`, `:492-502` (`distinct_accent_hue_count/1`) | MODE-B distinct accent hue count |

Twenty-one signals. **None of them is rendered text. None of them is a text width or a
bounding box.** `selector` (rows 7, 10) is the only string content read, and it is used as
an identifier — `ui_component?/1` (`:246-251`) splits it on `.` and tests whether the tag
is one of `button input select textarea`; nothing measures its length or its characters.

## Probe design

Base: a copy of `.planning/scorecards/page.actor.happy__dark-1280.json`'s **structure**
(read only). Each variant differs from the control in **exactly one dimension**, verified
by a leaf-by-leaf JSON diff before running:

| Variant | Differing leaves vs control | What changed |
|---|---|---|
| `control` | — | baseline |
| `text-content` | 6 | `rendered_text`, `element_styles[].text_content`, `color_pairs[].text_content`: `"abcdef"` → `"日本語Å"` |
| `text-width` | 5 | `rendered_text_width`, `element_styles[].text_width`, `element_styles[].bounding_box.width`: `120.0` → `777.0` |
| `token` | 2 | `element_styles[0].border_radius` `"0px"` → `"7px"`; `element_styles[0].font_size` `"14px"` → `"17px"` |
| `geometry-positive` | 1 | `mode_b.scroll_cost` `18.803` → `10017.803` |
| `empty` | n/a | directory exists, contains zero files |
| `__absent__` | n/a | directory does not exist |

**Which notion of text difference the variant actually varied.** `"abcdef"` → `"日本語Å"`
differs in all three notions simultaneously, and each was measured:

| Notion | control | variant | differs? |
|---|---|---|---|
| Bytes (UTF-8) | 6 | 11 | yes |
| Code points | 6 | 4 | yes |
| Rendered/terminal width (columns) | 6 | 7 (3 wide CJK + 1 narrow) | yes |

Because the checker's result was byte-identical, **the checker reacted to none of the
three** — this is not a case of "it reacted to bytes but not code points". The verdict is
unconditional across every notion of text difference.

Invocation was `Threadline.OperatorSurface.MechanicalChecker.run(scorecard_dir: "…")` via
`mix run --no-start` on a one-off script at `/tmp/198-work/probe.exs`. `mix verify.mechanical`
was deliberately **not** used — it is hard-wired to the committed scorecard set.

## Results

| Variant | `run/1` return | Interpretation |
|---|---|---|
| control | `{:ok, []}` | baseline is clean |
| text-content | `{:ok, []}` | **identical to control** — text content is invisible to the checker |
| text-width | `{:ok, []}` | **identical to control** — text width is invisible to the checker |
| token (MODE-A positive control) | `{:error, [2 violations]}` | harness has teeth |
| geometry (MODE-B positive control) | `{:error, [1 violation]}` | harness has teeth on the ratchet path too |
| empty directory | `{:ok, []}` | zero scorecards is a clean pass, not an error |
| absent directory | `{:ok, []}` | `File.ls/1` failure falls through to `[]` (`:159-161`) |

Equality was asserted on the return values themselves, not merely on their shape:

```
control == text-content : true
control == text-width   : true
```

### Positive-control detail (proving the probe can detect a real violation)

```
--- token (MODE-A positive control) :: /tmp/198-mechanical-probe/token
RESULT: {:error, [2 violation(s)]}
  - mode A border_radius selector="p.tl-page__meta" observed="7px" expected="one of [3, 4, 6, 8, 12, 999] px"
  - mode A font_size selector="p.tl-page__meta" observed="17px" expected="one of [12, 13, 14, 15, 16, 20, 24, 32] px"

--- geometry (MODE-B positive control) :: /tmp/198-mechanical-probe/geometry-positive
RESULT: {:error, [1 violation(s)]}
  - mode B scroll_cost selector="#dark_1280" observed=10017.8 expected="<= floor 18.8"
```

### Empty-directory edge, stated explicitly

`MechanicalChecker.run(scorecard_dir: "/tmp/198-mechanical-probe/empty")` returns
**`{:ok, []}`** for a directory that exists and contains zero scorecards, and also
`{:ok, []}` for a directory that does not exist at all. This matches the documented intent
at `:77-79` ("an empty/absent scorecards directory is a clean 'nothing captured yet'
result") but it is worth recording as a hazard: **a misconfigured `:scorecard_dir` passes
silently.** The gate cannot distinguish "nothing is wrong" from "nothing was checked".

### `measure_mode_b/1` per variant (the MODE-B measurement SSOT)

```
control:           %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 18.803, "type_size_count" => 4}
text-content:      %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 18.803, "type_size_count" => 4}
text-width:        %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 18.803, "type_size_count" => 4}
token:             %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 18.803, "type_size_count" => 4}
geometry-positive: %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 10017.803, "type_size_count" => 4}
```

Only the geometry variant moves a measured value. Text content and text width leave every
MODE-B metric untouched.

## Sizing implication for Phase 201 Tier 2

**Copy changes are free with respect to the mechanical gate.** Phase 201 Tier 2 can rewrite
labels, headings, empty-state prose, button text, and microcopy across the operator surface
without producing a single mechanical violation and — critically — **without regenerating
any Tier-A scorecard**. The gate is blind to what the words say and to how wide they render.

Two consequences for sizing:

1. **The scorecard-regeneration cost that constrains this milestone does not apply to
   text-only work.** The forbidden-recapture constraint bites on token, colour, and
   geometry changes; a pure copy pass does not touch any of the 21 signals. Tier 2 copy
   work should be sized as ordinary editing, not as gated evidence work.

2. **The gate provides zero protection for text-driven regressions, and Phase 201 must
   not assume otherwise.** A copy change that overflows a container, truncates a label,
   wraps a nav item onto a second line, or pushes a button off-screen will pass
   `verify.mechanical` cleanly. Text width is not captured, so layout breakage caused by
   longer strings is invisible here. If Tier 2 changes copy in constrained containers, the
   safety net has to come from somewhere else — Playwright assertions, visual diff, or
   human review — and that cost belongs in Phase 201's estimate, not in the mechanical
   gate's.

Put plainly: the mechanical checker makes Tier 2 copy work **cheap to gate** and
**unprotected against layout consequences**. Both halves matter to the estimate.

## Prohibition check

No file under `.planning/scorecards/` was written, copied over, or restored. All probe
inputs were synthesized into `/tmp/198-mechanical-probe/`; the committed scorecard was read
only, to learn the schema shape.

```
$ git status --porcelain .planning/scorecards/
$ echo $?
0
```

Output was empty.

## Raw probe output

```text
=== MechanicalChecker.run(scorecard_dir: ...) probe ===
cwd: /Users/jon/projects/threadline/.claude/worktrees/agent-abe3be2844fee443c

--- control :: /tmp/198-mechanical-probe/control
RESULT: {:ok, []}

--- text-content :: /tmp/198-mechanical-probe/text-content
RESULT: {:ok, []}

--- text-width :: /tmp/198-mechanical-probe/text-width
RESULT: {:ok, []}

--- token (MODE-A positive control) :: /tmp/198-mechanical-probe/token
RESULT: {:error, [2 violation(s)]}
  - mode A border_radius selector="p.tl-page__meta" observed="7px" expected="one of [3, 4, 6, 8, 12, 999] px"
  - mode A font_size selector="p.tl-page__meta" observed="17px" expected="one of [12, 13, 14, 15, 16, 20, 24, 32] px"

--- geometry (MODE-B positive control) :: /tmp/198-mechanical-probe/geometry-positive
RESULT: {:error, [1 violation(s)]}
  - mode B scroll_cost selector="#dark_1280" observed=10017.8 expected="<= floor 18.8"

--- empty directory :: /tmp/198-mechanical-probe/empty
RESULT: {:ok, []}

--- absent directory :: /tmp/198-mechanical-probe/__absent__
RESULT: {:ok, []}

=== control vs text-content: byte-for-byte equality of the RESULT ===
control == text-content : true
control == text-width   : true

=== MODE-B measured values per variant (measure_mode_b/1) ===
control: %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 18.803, "type_size_count" => 4}
text-content: %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 18.803, "type_size_count" => 4}
text-width: %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 18.803, "type_size_count" => 4}
token: %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 18.803, "type_size_count" => 4}
geometry-positive: %{"card_nesting_depth" => 0, "distinct_accent_hue_count" => 1, "interactive_control_count" => 0, "scroll_cost" => 10017.803, "type_size_count" => 4}
```
