---
phase: 167
slug: component-retune
artifact: light-review
reviewed_at: 2026-06-13
modes_reviewed: [light]   # light = live-reviewed; dark = unchanged frozen baseline; system = value-identical to light (dual-branch guarded by D-07a)
---

# Phase 167 — Light-Lane Review (LIGHT-REVIEW.md)

> **This is the committed human-judgment artifact (D-08).** The set of `override-needed`
> rows below is the *proven fail-list* that drives which override tasks Plan 167-02 authors
> (confirm-strict, D-03).

**Review coverage (honest record):**
- **`:light`** — reviewed **live** at `http://localhost:4010/audit` (router `theme: :light`, admin session, `mix demo.seed` data). The reviewer walked Home, Coverage, Timeline, and a Transaction/diff surface.
- **`:dark`** — the unchanged frozen baseline. This phase edits no dark token or base rule; dark byte-stability is enforced by the frozen-hex contract assertions. Not separately re-eyeballed because nothing in dark changed.
- **`:system`** — value-identical to `:light` (the `@media (prefers-color-scheme: light) [data-tl-theme="system"]` branch resolves the same token values as the light lane). Every authored override is mirrored into the system branch and the D-07(a) dual-branch contract assertion guarantees parity.

**Method:** the 9 glass/scrim families + 3 data-viz surfaces were dispositioned from the live light render plus computed-CSS pre-screen (`#5`/`#6` drawer effects pre-screened from the Phase-166 designed tokens, not live-eyeballed — see notes). Two **tint-rider** failures surfaced that fall outside the 9-family set and are recorded under "Additional findings".

---

## (a) Dark-Effect Families (COMP-01) — 9 families

| # | Family | Source anchor | Designed light intent (from UI-SPEC) | Disposition | Notes |
|---|--------|---------------|--------------------------------------|-------------|-------|
| 1 | Glass: topbar | `.tl-topbar` `style.ex:384` | Frosted light glass legibly distinct from the white page | **pass** | FLAGGED — reviewed: white topbar carries a bottom hairline (`border` + tint) → reads as chrome distinct from page. Blur subtle on white but the border carries separation. |
| 2 | Glass: shell-nav | `.tl-shell-nav` `style.ex:470` | Sticky nav band reads as chrome distinct from page | **pass** | Left nav reads as chrome (FIND/VERIFY/PROVE sections legible). |
| 3 | Glass: toolbar | `.tl-toolbar` `style.ex:966` | Raised glass card with a real light shadow | **pass** | Shadow-subtle visible on white. |
| 4 | Glass: coverage-command + subview header | `.tl-coverage-command` `style.ex:3047`, `.tl-subview__header` `style.ex:2748` | Command panel reads as focal raised surface; drawer header sticky frosted chrome | **pass** | Reads as focal raised surface. (The reviewer's "focal but ugly" = border/shadow loudness + nesting clutter → tracked as item C, a separate de-clutter seed, not a #4 light-intent failure.) |
| 5 | Drawer scrim | `.tl-subview-backdrop` `style.ex:2722` | Light ink scrim must dim/recede the page behind the drawer | **pass** (pre-screen) | FLAGGED — **not live-confirmed.** Drawer is the `Open row history` overlay; at desktop the scrim (`rgba(15,23,40,0.42)`) shows around a right-anchored drawer. Pre-screened from the Phase-166 token; **flag-later candidate** if it reads weak at desktop width. |
| 6 | Drawer shadow | `.tl-subview` box-shadow `style.ex:2740` | Drawer casts a believable light edge shadow | **pass** (pre-screen) | **Not live-confirmed.** `--tl-shadow-raised 0 18px 48px rgba(15,23,40,0.24)` is a reasonable edge shadow on white; flag-later if flat. |
| 7 | Focus glow | `--tl-focus-ring` `style.ex:156` + `:focus-visible` `style.ex:322` | Visible 3px ring on white, no dark-tuned bloom | **pass** (pre-screen) | Light ring `0 0 0 3px rgba(21,87,192,0.22), 0 0 0 1px #1557C0` — solid blue, clearly perceptible. Non-text contrast formally proven in Phase 168. |
| 8 | Home-card signature effects | `.tl-home__card--primary` `style.ex:681` + `::before` `style.ex:692` | Accent wash + teal signal line read as subtle luminous accent | **pass** | FLAGGED — reviewed: teal `#0F8F85` thread line reads as a deliberate top-edge signal on the primary card; accent wash perceptible. Slightly faint but reads as designed. |
| 9 | Shell-nav active inset | `.tl-shell-nav__item--active` `style.ex:588` | Active-nav inset hairline visible against white | **pass** | Active item (Overview/Coverage) clearly selected: `accent-soft` bg + `accent-border` + inset. |

**Families result: all 9 pass.** (#5/#6 pass on pre-screen, flagged not-live-confirmed.)

---

## (b) Data-Viz Surfaces (COMP-02)

| Surface | Criterion (from UI-SPEC) | Outcome | Notes |
|---------|--------------------------|---------|-------|
| Coverage matrix / command | Status pills/metrics legible at dense sizes | **pass** *(but see A)* | Metric numbers (6/8/1) large + legible. The red "8 need capture" / "Needs capture" **pill legibility** is the tint-rider failure → item **A** below. |
| Coverage matrix / command | Covered/uncovered/partial distinguishable by tint **AND** non-color cue | **pass** | Metric cards carry a left status rail (green Captured / red Needs-capture) + text label — non-color cue present. |
| Coverage matrix / command | Raised command panel reads as focal, not flat | **pass** | Reads focal. (Loudness/clutter → item C seed, not a light-intent fail.) |
| Coverage matrix / command | Small mono metadata readable on `#FFFFFF` | **pass** | "Checked just now", mono table names (`audit_events`) legible. |
| Coverage matrix / command | **Row hover polarity (added finding)** | **override-needed** | Item **B**. `.tl-table` rows default to `surface-raised #EEF3FA` (tinted) and go `surface #FFFFFF` (white) on hover — backwards on white. Hover should *add* tint, not remove it. Light-lane `.tl-table` override. |
| Timeline | Status-rail stripes (`inset 3px`) visible on white | **pass** | Rails read. Timeline rows do **not** use `.tl-table`, so fix B doesn't touch them. |
| Timeline | "Thread" reading survives — rails + dividers don't vanish | **pass** | Dividers (`border #C9D3E2`) read on white. |
| Timeline | Dense rows keep row-to-row separation | **pass** | Separation holds. |
| Timeline | Tabular-nums timestamps legible | **pass** | Legible. |
| Diff views | Before/after values distinguishable | **pass** | Change card fields distinguishable. |
| Diff views | `#FFFFFF` diff panel + `border` reads as a contained block | **pass** | Reads as contained block. |
| Diff views | Mono diff text at body/label size legible | **pass** | Mono values (id, uuid, timestamps) legible. |
| Diff views | `→` arrow (`muted #3B4762`) visible but not louder than values | **pass** | (Arrow shows on update diffs; INSERT view reviewed had none — token is muted, fine.) |
| Diff views | Add/remove/change semantics by tint + non-color cue | **pass** *(REDACTED chip → A)* | Op badge (INSERT green) + label carry semantics. The amber `[REDACTED]` chip legibility is item **A**. |

---

## Additional findings (tint-rider failures — outside the 9 families)

The UI-SPEC Tint-Rider Verification Contract lists status chips/alerts as **confirm-only**. The live
review **proved one rider family fails** on white, which the contract permits to override once proven:

- **A — Status-tint pills too weak on white (danger + warning).** `override-needed`.
  Danger pill: text `#A33434` on bg `rgba(163,52,52,0.10)`; warning pill: text `#7A5400` on bg
  `rgba(122,84,0,0.12)`. The 10–12% washes nearly vanish on white — pills read as subtle text, not as
  deliberate status. Fix is **strengthening the shared light-lane status-tint TOKENS** (bg/border
  alpha) at the lane root — uniform across all riders, **no per-component rider selector** (TOKEN-02
  safe). Hue/text hex unchanged (a hue change would be a D-05 halt).

---

## Fail-list (the input Plan 167-02 consumes)

- **9 families needing overrides:** none — all pass (confirm-strict; #5/#6 pass on pre-screen).
- **Data-viz needing overrides:** **B** — coverage `.tl-table` row hover polarity (white default → tinted hover), light + system branches.
- **Tint-rider needing overrides:** **A** — danger + warning status-tint token strength (shared light-lane `*-bg`/`*-border` alpha), light + system branches.
- **FLAGGED for user decision (new token / not derivable from the 45-token lane):** none. A and B are alpha/value tuning of existing tokens (D-04 autonomous). No new hue or primitive required.
- **Deferred (out of 167's value-lane scope, captured as seeds):** C-structure (coverage card nesting de-clutter), E (transaction left-push at desktop — theme-independent layout bug), D (dark/light/system picker — blocked by `[165-01]` theme-toggle ban; already `THEME-TOGGLE-01`).
