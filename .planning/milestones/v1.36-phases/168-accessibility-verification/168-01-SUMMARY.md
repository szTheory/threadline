---
phase: 168-accessibility-verification
plan: 01
subsystem: testing
tags: [wcag, accessibility, contrast, css-tokens, style-contract, exunit, operator-surface]

# Dependency graph
requires:
  - phase: 166-light-token-lane
    provides: 45-token dual-lane (light root + system @media branch) in style.ex
  - phase: 167-component-retune
    provides: strengthened light *-bg/*-border tint alphas (item A) + coverage-hover polarity flip (item B)
  - phase: 143-accessibility-baseline
    provides: dark-surface AA contrast test + WCAG luminance/contrast math + focus-visible guard
provides:
  - Alpha-aware color_tokens/1 parser (parses rgba(...) into {r,g,b,a}; opaque #RRGGBB unchanged)
  - composite/2 per-mode compositing helper (round(src*a + base*(1-a)) -> #RRGGBB) + hex_to_rgb/1
  - system_lane_block!/1 extracting the [data-tl-theme="system"] block through the @media wrapper
  - Light + system AA contrast mirror incl. composited status-text-on-tint rows
  - Focus-ring non-text 3:1 contract per mode with halo composited-and-reported (never load-bearing)
  - Per-mode interaction-state source assertions (hover/active/selected/disabled + coverage-hover flip)
  - D-04 disabled-text (muted-soft) exemption documented in-code (WCAG 1.4.3)
affects: [168-02-e2e-light-affordance, 169-appearance-proof, accessibility, style-contract]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Alpha-aware compositing parser bolted onto the unchanged WCAG luminance pipeline"
    - "Per-mode opaque-base compositing (base named by caller, never assumed single)"
    - "@media-wrapper-aware block extraction (system_lane_block!/1 mirroring media_section/2)"
    - "Source-first dual-lane contrast mirror parameterized over {light, system} maps"

key-files:
  created: []
  modified:
    - test/threadline/operator_surface/style_contract_test.exs

key-decisions:
  - "Extended color_tokens/1 in place (alpha-aware) rather than adding a sibling parser; added composite/2 + hex_to_rgb/1"
  - "No D-02 tune fired — every composited tint and focus edge passes on arrival (Phase 167 already strengthened the tints); style.ex untouched by this plan"
  - "Applied the D-04 disabled-text exemption for muted-soft (WCAG 1.4.3): measured to a >=3.0 legibility floor, value unchanged (#73819C), because a 4.5:1 tune collapses the disabled vs active-muted read"

patterns-established:
  - "Composite translucent CSS tokens over a per-mode opaque base before feeding the existing relative_luminance/1"
  - "Focus halo is composited-and-reported only; the opaque 1px border-focus edge carries the 3:1 pass"

requirements-completed: [A11Y-01, A11Y-02]

# Metrics
duration: 25min
completed: 2026-06-14
---

# Phase 168 Plan 01: Accessibility Verification (source-first) Summary

**Alpha-aware compositing parser + light/system AA contrast mirror (incl. composited status-text-on-tint rows) + per-mode focus-ring 3:1 and interaction-state contracts, all proven by `style_contract_test.exs` reading `style.ex` directly — with the dark phase-143 contract byte-stable.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-06-14
- **Tasks:** 3 (all TDD)
- **Files modified:** 1 (test only; style.ex not edited — no D-02 fired)

## Accomplishments
- Closed the parser gap that silently dropped every `rgba(...)` token: `color_tokens/1` now returns `{r,g,b,a}` for translucent tints while opaque `#RRGGBB` passes straight through; `composite/2` blends a tuple over a caller-named per-mode opaque base into `#RRGGBB` that feeds the unchanged WCAG luminance pipeline verbatim.
- Mirrored the dark contrast contract across BOTH the `[data-tl-theme="light"]` (top-level) and `[data-tl-theme="system"]` (`@media`-wrapped) token maps — every UI-SPEC text/background pair at 4.5:1, including the composited status-text-on-its-own-tint rows the hex-only parser could never see (info/warning/success/danger over `*-bg` composited on surface; accent over accent-soft composited on surface-raised).
- Asserted the opaque 1px `border-focus` edge clears non-text 3:1 against surface AND surface-raised in both lanes, with the 3px translucent halo composited-and-reported (and explicitly refuted from reaching 3:1 alone, ~1.4:1) so a low-alpha halo can never mask a focus failure.
- Asserted per-mode interaction-state deltas (hover surface ≠ rest, active/selected accent-soft + non-color cues, disabled muted-soft) and the presence of the Phase-167 coverage-hover polarity flip override in both lanes; added an explicit dark byte-stability guard naming the frozen dark focus-ring catalog and re-refuting the theme-toggle ban.

## Task Commits

Each task was committed atomically (TDD: RED folded into the first feat/test commit per task):

1. **Task 1: Alpha-aware parser + per-mode composite helper** - `7c6c5e5` (test)
2. **Task 2: Light + system AA contrast mirror incl. composited tints** - `f3eb8dc` (feat)
3. **Task 3: Focus-ring 3:1 + per-mode interaction states + dark byte-stability** - `fde6d8d` (feat)

_Note: each commit staged ONLY `style_contract_test.exs` by explicit path; no nav-overhaul-lane file and no `style.ex` were staged._

## Files Created/Modified
- `test/threadline/operator_surface/style_contract_test.exs` - Added alpha-aware `color_tokens/1` + `parse_color_value/1` + `normalize_alpha/1`, `composite/2`, `hex_to_rgb/1`, `system_lane_block!/1`; added the light+system contrast mirror test, the focus-ring 3:1 test, the interaction-state test, and the dark byte-stability guard test (5 new tests; 27 -> 31 in-file tests... net 31 in suite).

## Decisions Made
- **Parser placement:** extended `color_tokens/1` in place (RESEARCH/UI-SPEC permit either) rather than a sibling parser — keeps a single token-parse path that both the dark and light mirrors share.
- **No D-02 tune:** the formal math surfaced NO sub-threshold composited pair — all status-text-on-tint rows and both focus edges already clear their thresholds (Phase 167 item A strengthened the tints). Green-on-arrival was the expected outcome (Pitfall 5); `style.ex` was therefore not edited.
- **D-04 disabled exemption applied:** light `--tl-color-muted-soft: #73819C` measures 3.93:1 on surface (#FFFFFF) and 3.52:1 on surface-raised (#EEF3FA) — both below 4.5:1. The smallest uniform lane-root darkening that reaches 4.5:1 on surface-raised is ~`#636F85`, which is perceptually adjacent to the ACTIVE secondary text `--tl-color-muted` (#3B4762) and would break the "disabled looks disabled" affordance. Per D-04 the disabled rows ONLY are downgraded to "exempt — documented" at a >=3.0 legibility floor with an in-code WCAG 1.4.3 (inactive controls) citation; the token value is unchanged. No other row is exemptable.

## Deviations from Plan

None - plan executed exactly as written. (The D-04 exemption is an explicitly-bounded planned fallback, not an unplanned deviation; D-02 did not fire and D-03 did not trigger — no new hue, primitive, or non-lane-derivable value was required.)

## Issues Encountered
- `gsd-sdk state.record-metric` required NAMED args (`--phase/--plan/--duration/...`) on this SDK version, not positional; re-invoked with flags. (The CLAUDE.md positional-args caution is specific to `state.begin-phase`; record-metric's handler parses named args.) Non-fatal.
- `gsd-sdk state.record-session` reported "No session fields found in STATE.md" (format quirk); the Last-activity line was updated directly instead. Non-fatal.

## User Setup Required
None - no external service configuration required. This plan is pure ExUnit source assertions over a trusted in-repo file (no packages, no routes, no secrets).

## Next Phase Readiness
- **A11Y-01 closed source-side:** light + system AA contrast mirror with alpha-aware/compositing parsing is green; every text-bearing token clears 4.5:1 in both modes incl. composited status-on-tint; the dark phase-143 test stays byte-stable.
- **A11Y-02 part 1 closed source-side:** the 1px border-focus edge clears 3:1 vs surface and surface-raised in both modes; halo composited-and-reported; `:focus-visible` restore guard holds per mode; per-mode interaction states asserted.
- **Remaining for A11Y-02 part 2 (plan 168-02):** the Playwright `operator-accessibility.spec.ts` affordance re-run under the light branch (D-01 reconciliation needed — the example mount defaults `theme: :dark`, so `colorScheme: "light"` alone renders the dark lane; prefer env-gated `:system` or a dedicated test route per RESEARCH Pitfall 1).

## Self-Check: PASSED
- File exists: `test/threadline/operator_surface/style_contract_test.exs` (FOUND)
- File exists: `.planning/phases/168-accessibility-verification/168-01-SUMMARY.md` (this file)
- Commit `7c6c5e5` (FOUND), `f3eb8dc` (FOUND), `fde6d8d` (FOUND)
- `mix test test/threadline/operator_surface/style_contract_test.exs` -> 31 tests, 0 failures
- `mix format --check-formatted` clean; `mix compile --warnings-as-errors` clean
- No nav-overhaul-lane file staged or committed by this plan; `style.ex` not edited (no D-02)

---
*Phase: 168-accessibility-verification*
*Completed: 2026-06-14*
