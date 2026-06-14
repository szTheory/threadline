# Phase 168: accessibility-verification - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 4 (1 primary extend, 1 conditional extend, 2 e2e wiring)
**Analogs found:** 4 / 4 (every new pattern is an in-file or sibling-file extension — no greenfield)

> Verification/enforcement phase. There are **no new files**. Every deliverable extends an
> existing file by mirroring a pattern that already lives in that same file (or its immediate
> sibling). The analog for each new assertion is almost always **in the file being edited** —
> the executor's job is to copy structure, not invent it. All excerpts below are anchored to
> file:line so the planner cites them verbatim.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/threadline/operator_surface/style_contract_test.exs` (EXTEND) | test (source-first contract) | transform (CSS source → parse → composite → WCAG math → assert) | **same file** — `phase 143` dark contrast test `:653-686`; `color_tokens/1` `:1058-1062`; WCAG math `:1064-1091`; `selector_block!`/`media_section` `:1010-1056` | exact (in-file mirror) |
| `lib/threadline/operator_surface/style.ex` (CONDITIONAL — only if D-02 fires) | config (CSS design tokens) | transform (token → rendered surface) | **same file** — Phase-167 item-A coverage-hover dual-branch override `:299-315`; light root `:188-237`; system branch `:240-289` | exact (in-file dual-branch) |
| `examples/threadline_phoenix/e2e/playwright.config.ts` (EXTEND — add light project) | config (test harness) | event-driven (browser project matrix) | **same file** — existing `projects[]` + `use` block `:13-26` | exact (in-file project clone) |
| `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` (RE-RUN, likely verbatim) | test (e2e affordance) | request-response (browser assertions) | **same file** — `expectFocused` `:18-24`, affordance set `:100-245` | exact (verbatim re-run) |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (CONDITIONAL — Pitfall-1 wiring) | route | request-response | **same file** — operator mount `:171-188`; theme threading analog in `auth.ex:14,177-179` | role-match |

---

## Pattern Assignments

### `test/threadline/operator_surface/style_contract_test.exs` (test, transform) — PRIMARY DELIVERABLE

**Analog: this same file.** Three existing in-file patterns are extended; one (the WCAG math) is REUSED unchanged.

#### A. The dark contrast test to mirror (lines 653-686)

The light mirror is a structural copy of this block, run twice more (once per light + system token map). Copy the `backgrounds`/`text_token` loop shape verbatim; swap the extracted block and add the composited-tint rows.

```elixir
# style_contract_test.exs:653-686 — the structure the light/system mirror copies
test "phase 143 accessibility tokens meet dark-surface contrast baseline" do
  src = File.read!(@style_path)

  tokens =
    src
    |> selector_block!(".threadline-ui")        # <-- light mirror swaps this selector
    |> color_tokens()                            # <-- alpha-aware version (see C)

  backgrounds = [
    "--tl-color-bg", "--tl-color-surface",
    "--tl-color-surface-raised", "--tl-color-surface-hover"
  ]

  for text_token <- [
        "--tl-color-text", "--tl-color-muted", "--tl-color-muted-soft",
        "--tl-color-info-text", "--tl-color-warning-text",
        "--tl-color-success-text", "--tl-color-danger",
        "--tl-color-accent-strong"
      ],
      background_token <- backgrounds do
    assert contrast_ratio(tokens[text_token], tokens[background_token]) >= 4.5,
           "#{text_token} must meet AA contrast on #{background_token}"
  end

  assert contrast_ratio(tokens["--tl-color-accent"], tokens["--tl-color-surface-raised"]) >= 4.5,
         "base accent links must meet AA contrast on raised surfaces"
end
```

**Mirror instructions for the executor:**
- Light root block extracted via `selector_block!(src, ~s|.threadline-ui[data-tl-theme="light"]|)` — this selector is top-level and extracts cleanly (Pitfall 2 does NOT apply to the light block).
- System block CANNOT use a bare `selector_block!` (Pitfall 2 — see helper D). Split on `"@media (prefers-color-scheme: light) {"` first, then `selector_block!` the inner `[data-tl-theme="system"]` selector inside that slice.
- Add the SPEC's composited-tint rows (`*-text` over `*-bg composited`) that the dark test's loop does not have — these are the rows the hex-only parser silently drops today.

#### B. WCAG math — REUSE UNCHANGED (lines 1064-1091)

Do NOT re-derive. The luminance/contrast pipeline already exists and is WCAG-2.1-correct (sRGB threshold `0.03928`, coefficients `0.2126/0.7152/0.0722`). The new compositing step feeds an opaque hex string into `contrast_ratio/2` exactly as the dark test does.

```elixir
# style_contract_test.exs:1064-1091 — REUSE AS-IS; the new parser feeds this
defp contrast_ratio(foreground, background) do
  fg = relative_luminance(foreground)
  bg = relative_luminance(background)
  lighter = max(fg, bg)
  darker = min(fg, bg)
  (lighter + 0.05) / (darker + 0.05)
end

defp relative_luminance("#" <> hex) do
  [r, g, b] =
    hex |> String.graphemes() |> Enum.chunk_every(2)
    |> Enum.map(fn pair ->
      pair |> Enum.join() |> String.to_integer(16) |> Kernel./(255) |> linear_channel()
    end)
  0.2126 * r + 0.7152 * g + 0.0722 * b
end

defp linear_channel(channel) when channel <= 0.03928, do: channel / 12.92
defp linear_channel(channel), do: :math.pow((channel + 0.055) / 1.055, 2.4)
```

> `relative_luminance/1` pattern-matches `"#" <> hex` — it already requires opaque hex input.
> The compositing step (below) must produce a `"#RRGGBB"` string so this matches without change.

#### C. The parser chokepoint to make alpha-aware (lines 1058-1062) — THE TECHNICAL HEART

Extract verbatim; this is the single function to extend (or add a sibling beside). Today its regex matches `#RRGGBB` ONLY and silently drops every `rgba(...)`.

```elixir
# style_contract_test.exs:1058-1062 — HEX-ONLY; drops every rgba(...) token
defp color_tokens(src) do
  ~r/(--tl-color-[a-z-]+):\s*(#[0-9a-fA-F]{6});/
  |> Regex.scan(src)
  |> Map.new(fn [_match, token, hex] -> {token, hex} end)
end
```

**Extension contract (from RESEARCH `:237-248` + SPEC `:106-118`):**
- Also match `rgba\(\s*(\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\s*\)` (and `#RRGGBBAA` if any appear — none do today, A3).
- Return `{r,g,b,a}` for translucent tokens; composite to opaque hex against a **caller-named, per-mode** opaque base BEFORE handing to `contrast_ratio/2`.
- Per-mode base table (RESEARCH `:121-128`): status `*-bg` tints → `surface` (`#FFFFFF` light / `#141B2D` dark); `accent-soft`/`accent-wash` → `surface-raised` (`#EEF3FA` light / `#1B253A` dark); page washes → `bg`. Never assume one base across modes (Pitfall 3).

**Composite helper shape to ADD (RESEARCH `:130-142`, verify exact arithmetic in test):**
```elixir
defp composite({r, g, b, a}, base_hex) do
  {br, bg, bb} = hex_to_rgb(base_hex)
  blend = fn s, base -> round(s * a + base * (1 - a)) end
  "#" <> Enum.map_join([{r, br}, {g, bg}, {b, bb}], "", fn {s, base} ->
    blend.(s, base) |> Integer.to_string(16) |> String.pad_leading(2, "0")
  end)
end
# Opaque hex passes through unchanged; result feeds contrast_ratio/2 verbatim.
```

#### D. Block-extraction helpers (lines 1010-1056) — the `@media`-wrapper limitation

`selector_block!` / `selector_block_pattern/2` use a non-nested `[^}]*` matcher (stops at the FIRST `}`). The light root extracts cleanly; the system branch is wrapped in `@media`, so use the `media_section/2` split precedent.

```elixir
# style_contract_test.exs:1045-1056 — non-nested matcher (the Pitfall-2 limitation)
defp selector_block!(section, selector) do
  pattern = selector_block_pattern(selector)
  case Regex.run(pattern, section) do
    [block] -> block
    _ -> flunk("missing selector #{selector}")
  end
end

defp selector_block_pattern(selector, declaration_pattern \\ ~r/[^}]*/) do
  ~r/#{Regex.escape(selector)}\s*\{[^}]*#{Regex.source(declaration_pattern)}[^}]*\}/s
end
```

```elixir
# style_contract_test.exs:1010-1019 — media_section/2: the @media-split precedent to mirror
defp media_section(src, width) do
  src
  |> String.split("@media (min-width: #{width}) {")
  |> Enum.at(1)
  |> String.split(next_media_boundary(width))
  |> List.first()
end
```

**For the system block:** split on `"@media (prefers-color-scheme: light) {"`, take the inner slice, then `selector_block!` the `[data-tl-theme="system"]` selector within it — exactly the `media_section/2` shape above adapted to the `prefers-color-scheme` wrapper.

#### E. Focus-ring 3:1 + behavioral guard (lines 688-735) — A11Y-02 part 1

The behavioral `:focus-visible` guard already exists and stays intact (and is now understood to hold per mode — the ring token is theme-swapped, the selector list is shared). Copy this structure for the per-mode focus assertions; ADD the numeric 3:1 contrast assertion on the opaque 1px `border-focus` edge (compose-and-report the 3px halo, never let it carry the pass).

```elixir
# style_contract_test.exs:688-714 — the focus guard to keep + extend per mode
test "phase 143 focus-visible and non-color status contracts stay locked" do
  src = File.read!(@style_path)
  assert String.contains?(src, "--tl-focus-ring:")

  for selector <- [
        ".threadline-ui button:focus-visible",
        ".threadline-ui [role=\"button\"]:focus-visible",
        ".threadline-ui input:focus-visible",
        ".threadline-ui select:focus-visible",
        ".threadline-ui a:focus-visible",
        ".threadline-ui summary:focus-visible"
      ] do
    assert String.contains?(src, selector), "missing focus-visible selector #{selector}"
  end

  focus_block =
    src
    |> String.split(".threadline-ui button:focus-visible,")
    |> Enum.at(1) |> String.split("}") |> List.first()

  assert String.contains?(focus_block, "box-shadow: var(--tl-focus-ring);")

  refute Regex.match?(~r/\.threadline-ui\s+\*\s*\{[^}]*outline:\s*none/s, src),
         "blanket focus outline removal is forbidden"
  # ... non-color chip-marker assertions follow (:716-734) — keep intact
end
```

**3:1 edge source values (RESEARCH `:259-266`):** the 1px solid edge = `--tl-color-border-focus` (`#7FA9FF` dark / `#1557C0` light); assert `>= 3.0` against `surface` AND `surface-raised` per mode (controls sit on both). Reuse `contrast_ratio/2` from B.

#### F. Theme-aware / theme-toggle-ban guards (lines 8-30) — KEEP INTACT (do not duplicate)

These seven theme-aware assertions + the `theme-toggle` ban are a hard constraint (must stay green, byte-stable). Do NOT re-author; the new light mirror sits alongside them.

```elixir
# style_contract_test.exs:8-30 — must remain passing unchanged (Hard Constraint 2)
assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="light"]|)
assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="system"]|)
assert String.contains?(src, "@media (prefers-color-scheme: light)")
# ...
refute String.contains?(src, "theme-toggle")
```

---

### `lib/threadline/operator_surface/style.ex` (config, transform) — CONDITIONAL (only if D-02 fires)

**Analog: this same file.** Touch ONLY if the mirror surfaces a sub-threshold pair. Any fix is a **uniform lane-root alpha tune across BOTH branches** — the Phase-167 item-B coverage-hover dual-branch override is the exact edit-discipline template.

#### A. Dual-branch override template (lines 299-315) — the edit discipline to copy

```elixir
# style.ex:299-315 — Phase 167 (B): every light override edits BOTH branches in one task
.threadline-ui[data-tl-theme="light"] .tl-table {
  background: var(--tl-color-surface);
}
.threadline-ui[data-tl-theme="light"] .tl-table--actionable tbody tr:hover {
  background: var(--tl-color-surface-hover);
}

@media (prefers-color-scheme: light) {
  .threadline-ui[data-tl-theme="system"] .tl-table {
    background: var(--tl-color-surface);
  }
  .threadline-ui[data-tl-theme="system"] .tl-table--actionable tbody tr:hover {
    background: var(--tl-color-surface-hover);
  }
}
```

> This is a *selector override* precedent. A D-02 contrast fix is NOT a selector override — it is a
> token-value/alpha edit at the **lane root** (the `*-bg`/`*-border` alpha, strengthened uniformly).
> Use the per-component override ONLY as proof of the dual-branch discipline: whatever you change in
> the `light` root you change identically in the `system` root, in the same task.

#### B. Light root + mirrored system branch (lines 188-237, 240-289) — where a D-02 alpha tune lands

The two blocks are **byte-identical in token values today** (A2, verified). A D-02 tune edits the matching `rgba` alpha in both. The known-weak tint tokens (already fixed by Phase 167 item A; do NOT re-litigate — Pitfall 5):

```css
/* style.ex:216-228 (light root) — mirrored verbatim at :268-280 (system branch) */
--tl-color-danger: #A33434;
--tl-color-danger-bg: rgba(163, 52, 52, 0.10);     /* composite over #FFFFFF before measuring danger text */
--tl-color-danger-border: rgba(163, 52, 52, 0.28); /* focus/border riders tune together with -bg */
--tl-color-warning-bg: rgba(122, 84, 0, 0.12);
--tl-color-warning-text: #8A5512;
--tl-color-success-bg: rgba(19, 108, 71, 0.12);
--tl-color-success-text: #136C47;
--tl-color-info-bg: rgba(21, 87, 192, 0.10);
--tl-color-info-text: #1557C0;
--tl-color-border-focus: #1557C0;                  /* :200 / :252 — the 3:1 focus edge */
--tl-focus-ring: 0 0 0 3px rgba(21, 87, 192, 0.22), 0 0 0 1px var(--tl-color-border-focus); /* :236 / :288 */
```

**Halt boundary (D-03):** strengthening an existing `rgba` alpha = autonomous (D-02). A new hue, new primitive, or any value not derivable from these 45 tokens = FLAG + PAUSE.

---

### `examples/threadline_phoenix/e2e/playwright.config.ts` (config, event-driven) — EXTEND

**Analog: this same file.** Add a light-lane project by cloning an existing project entry and adding `colorScheme: "light"` to its `use`. The `use` block and `projects[]` array are the pattern.

```typescript
// playwright.config.ts:13-26 — clone a project, add colorScheme: "light"
use: {
  baseURL,
  trace: "retain-on-failure",
  screenshot: "only-on-failure",
  reducedMotion: "reduce",   // colorScheme: "light" is a sibling first-class `use` option
},
projects: [
  { name: "chromium", use: { ...devices["Desktop Chrome"] } },
  { name: "desktop-chromium", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
  { name: "mobile-chromium", use: { ...devices["Pixel 5"] } },
  // ADD (D-01): a light-lane project, e.g.
  // { name: "light-chromium", use: { ...devices["Desktop Chrome"], colorScheme: "light" } },
],
```

> Decision D-01 may instead env-gate (Pitfall-1 option 3): a second project sets `colorScheme: "light"`
> AND the served mount resolves `:system` via env. The clone-a-project shape above is identical either way.

---

### `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` (test, request-response) — RE-RUN VERBATIM

**Analog: this same file.** D-01 + SPEC require the SAME affordance set under the light branch. Do not author new assertions — the existing ones are the contract.

```typescript
// operator-accessibility.spec.ts:18-24 — the focus affordance the light re-run must still pass
async function expectFocused(locator: Locator) {
  await expect(locator).toBeFocused();
  const boxShadow = await locator.evaluate(
    (element) => window.getComputedStyle(element).boxShadow,
  );
  expect(boxShadow).not.toBe("none");   // focus ring resolves non-none in BOTH lanes
}
```

**The full affordance set the light re-run must hold (anchored):**
| Affordance | Line anchor |
|------------|-------------|
| Focus `box-shadow` non-`none` | `:18-24` (`expectFocused`) |
| No horizontal overflow | `:26-33` (`expectNoHorizontalOverflow`), asserted `:175,211,245` |
| Nav `aria-current="page"` | `:100,133` |
| Retention `data-confirm` | `:169` |
| Dialog `aria-modal="true"` | `:199` |
| Chip/verdict border non-`0px`/non-`none` | `:226-231` |
| `login()` flow (reused) | `:9-16` |

---

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (route) — CONDITIONAL (Pitfall-1 wiring)

**Analog: this same file (the operator mount) + the theme contract in `auth.ex`.** RESEARCH Pitfall 1 (HIGH-IMPACT): the example mount passes **no** `theme:`, so `Auth.on_mount` defaults `:dark`, and `colorScheme: "light"` alone renders the DARK lane (the `[data-tl-theme="system"]` light branch only activates when mounted with `theme: :system`).

```elixir
# examples/.../router.ex:174-187 — the operator mount with NO `theme:` opt (defaults :dark)
threadline_operator_surface("/",
  actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
  authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
  # ... (no theme: key) ...
  repo: ThreadlinePhoenix.Repo
)
```

```elixir
# lib/.../auth.ex:14 + :177-179 — the default + normalizer the planner must reckon with
theme = Keyword.get(opts, :theme, :dark) |> normalize_theme()
# ...
defp normalize_theme(:light), do: "light"
defp normalize_theme(:system), do: "system"
defp normalize_theme(_theme), do: "dark"
```

**Planner decision (lowest-friction, RESEARCH `:186-190`):** options are (1) flip mount to `:system` — risks bleed into Phase 169; (2) dedicated test-only `:system` route behind the same `:operator_browser`/`:operator_auth` pipeline; (3) env-gate the mount theme (`THREADLINE_E2E_THEME`) so existing dark runs stay dark. **RESEARCH recommends option 3 or 2** to preserve the dark e2e default. This is a D-01 reconciliation, NOT a D-03 halt.

---

## Shared Patterns

### Source-first contract amendment (166 D-05 same-wave rule)
**Source:** the relationship between `style.ex` and `style_contract_test.exs`.
**Apply to:** any D-02 token tune.
Because the test reads `style.ex` as a raw string, a token edit and its new/updated assertion land in the **same task/wave**. Never edit a token without updating its assertion in the same change.

### Dual-branch additive discipline (166/167)
**Source:** `style.ex:299-315` (coverage-hover override) and the byte-identical `:188-237` / `:240-289` blocks.
**Apply to:** every light-lane CSS edit and every light mirror assertion.
Edit BOTH `[data-tl-theme="light"]` and `@media (prefers-color-scheme: light) [data-tl-theme="system"]`. The mirror test asserts BOTH maps.

### Alpha-aware compositing (NEW this phase — the one genuinely new logic)
**Source:** extends `relative_luminance/1` (`style_contract_test.exs:1073`) via a new `composite/2` helper.
**Apply to:** every translucent (`rgba`) token before luminance math.
`effective = round(src*a + base*(1-a))` per channel, over the **per-mode** opaque base. Opaque hex passes through unchanged. Never composite the wrong base (Pitfall 3) or let the translucent halo mask a focus failure.

### Block extraction (`selector_block!` + `media_section` precedent)
**Source:** `style_contract_test.exs:1010-1056`.
**Apply to:** every light/system token map read.
Light root extracts cleanly; the system branch needs the `@media`-split (`media_section/2` shape) first (Pitfall 2).

---

## No Analog Found

None. Every deliverable has an in-file (or immediate-sibling) analog. The single piece of genuinely new logic — the `rgba` parse + `composite/2` step — bolts onto the existing, unchanged luminance pipeline; its shape is given in RESEARCH `:130-142` and assigned above (`color_tokens/1` section C).

---

## Metadata

**Analog search scope:** the four target files plus `lib/threadline/operator_surface/auth.ex` and the example `router.ex` (Pitfall-1 reconciliation). No broader codebase scan needed — this is a bounded extend/re-run phase.
**Files scanned:** 6 (read directly this session).
**Pattern extraction date:** 2026-06-13
**Caution:** do NOT touch the uncommitted nav-overhaul lane (~29 files, 3 known failures). Scope `mix test` to `test/threadline/operator_surface/style_contract_test.exs`.
