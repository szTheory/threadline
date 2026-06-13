---
phase: 167-component-retune
plan: 02
status: built-verified-uncommitted
completed_at: 2026-06-13
requirements: [COMP-01, COMP-02]
source_committed: false
---

# Plan 167-02 Summary — light overrides + status-chip redesign

## What was built (in `lib/threadline/operator_surface/style.ex`, verified live both modes)

### B — Coverage row hover polarity (COMP-02, data-viz)
Additive dual-branch override (`[data-tl-theme="light"]` + `@media (prefers-color-scheme: light)
[data-tl-theme="system"]`): `.tl-table` defaults to `--tl-color-surface` (white) and
`.tl-table--actionable tbody tr:hover` → `--tl-color-surface-hover` (tinted). Fixes the inverted
polarity (tinted default → white hover) that read backwards on white. Row separation preserved by
the per-cell `border-bottom`; timeline rows don't use `.tl-table` so they're untouched. Dark base
unchanged.

### A — Status-chip "signal node" redesign (COMP-01, decision **D-09**, cross-mode)
The light status pills read as ugly through ~6 live iterations (strengthen-alpha → soften+amber →
Option Y faint-fill → no-pill → **T1 neutral chip + dot**). Root causes the user identified, in order:
muddy tone-on-tone fills → fills-as-blobs → naked text looked unstyled → **dot glow** smudge → brown
warning dot. Final treatment, authored in the **shared base `.tl-chip` rules** (both modes):
- Status chips keep the **standard neutral chip chrome** (surface fill + 1px gray `--tl-color-border`
  + readable `--tl-color-text`) — identical to the Evidence/Redaction buttons — and reduce color to a
  single **dot**.
- The dot is **decoupled** from `currentColor` to `var(--tl-chip-dot)` (each modifier sets it), is
  **flat/solid** (the dark-tuned glow `box-shadow` was removed — it read as a smudge on white), and
  uses a **dedicated `--tl-color-warning-dot`** token (light `#CA8A04` clean amber, dark `#F6C86B`
  gold) so the warning dot isn't the dark-brown `--tl-color-warning-text` (which must stay AA-as-text).
- Because it's a base-rule change, it **retires the chip from dark byte-stability** (D-09) — dark
  chips change from colored-tonal to neutral-chrome + luminous dot. **User signed off both `:light`
  and `:dark` live.** No per-theme `[data-tl-theme="light"]` chip selector, so TOKEN-02 / D-07(b)
  stays clean. Status `*-bg`/`*-border` tokens reverted toward Phase-166 (now only feed alerts).

### Contract test (`style_contract_test.exs`) — re-baselined, **25/25 green**
- Updated the phase 143/144 chip assertions to the new contract (status chip = `color:` +
  `--tl-chip-dot:`, chrome inherited from base); dot marker now `background: var(--tl-chip-dot)`.
- D-07(b) tint-rider class-qualified-absence kept (green). D-07(a) refocused: B `.tl-table`
  dual-branch + the chip dot decoupling + `--tl-color-warning-dot` per-theme presence.
- Frozen-hex dark catalog + `theme-toggle` ban untouched and green.

## Verification
- `mix test …/style_contract_test.exs` → **25 tests, 0 failures.**
- Dark base byte-stable (frozen-hex assertions green; dark danger/warning bg unchanged).
- Live: `:light` and `:dark` on `:4010` — chips read as clean neutral chips + crisp colored dot;
  coverage rows white→tinted hover. Both modes user-approved.

## ⚠ Source NOT committed (deliberate — entanglement)
`style.ex` and `style_contract_test.exs` were **already carrying the uncommitted nav-overhaul lane**
at session start (`style.ex`: ~660 of 678 changed lines are nav-overhaul, ~16 are 167; the test:
~170 of 248 are nav-overhaul). A whole-file `git add` would bundle the nav-overhaul work into a
"feat(167)" commit, and interactive patch-staging isn't available here. **Per user decision, the 167
source is left in the working tree** to ship together with the nav-overhaul lane for v1.36. Only the
clean `.planning` artifacts (this summary, `LIGHT-REVIEW.md`, the 3 deferral todos) are committed.

## Deferred (todos planted in `.planning/todos/pending/`)
- `theme-picker-idiomatic-ui.md` — user explicitly requested a dark/light/system picker; demand
  signal for `THEME-TOGGLE-01` (blocked by `[165-01]` ban; not built in 167).
- `transaction-page-left-push-desktop.md` — theme-independent layout bug (item E); check if it's a
  nav-overhaul-lane regression first.
- `coverage-schema-card-declutter.md` — structural nesting de-clutter (item C); value-only softening
  was in 167 remit, the structural fix is deferred.

## Cleanup done
Reverted the two local render-setup edits (`examples/.../config/dev.exs` PORT tweak,
`examples/.../router.ex` `theme:` opt) — example-app/nav-overhaul lane untouched by this work.
Dev server stopped.

## Self-Check: PASSED (build + verify); commit intentionally deferred (see ⚠ above).
