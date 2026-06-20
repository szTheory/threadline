---
phase: 178-per-page-flow-stress-pass-all-11-pages
plan: 05
subsystem: operator-surface
tags: [operator-surface, page-02, footguns, fix-to-green, tier-a, tier-b, seed-005]
requires:
  - "lib/threadline/operator_surface/style.ex (footgun CSS source-of-truth; #1 scroll tokens, #6 spacing tokens, PAGE-03 justify-self)"
  - "lib/threadline/operator_surface/ui.ex (modal/drawer scrims, JS dismiss path, UI.shell reconnect banner)"
  - "test/threadline/operator_surface/style_contract_test.exs (Wave-0 RED #1/#6 source guards + contrast engine)"
  - "test/threadline/operator_surface/component_contract_test.exs (Wave-0 RED #4 scrim guard + #2/#5/#7/#8/#9)"
  - "examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts (Wave-0 Tier B scaffold)"
provides:
  - "All 11 footgun classes GREEN in Tier A (the #1/#4/#6 RED scaffolds fixed; the other 8 held green)"
  - ".tl-target-row desktop scroll-margin-top reconciliation (#1) inside the >=768px media layer"
  - ".tl-timeline-fact gap retokenized 2px -> var(--tl-space-1) (#6)"
  - "modal/drawer scrim phx-click click-outside dismiss markers (#4), CSP-safe via Phoenix.LiveView.JS"
  - "Finalized Tier B footgun sweep + the representative ~66-cell sample (63 dark + 21 light cells GREEN); two-tier honesty framing"
affects:
  - "lib/threadline/operator_surface/style.ex (+10/-2 lines: #1 desktop rule, #6 gap token)"
  - "lib/threadline/operator_surface/ui.ex (+14/-2: scrim phx-click on modal + drawer)"
  - "examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts (finalized; no scaffold markers)"
tech-stack:
  added: []
  patterns:
    - "Guard-first fix-to-green ratchet (D-05): the Wave-0 detector failed, the fix makes it pass, the detector stays permanent"
    - "Desktop media-layer scroll-margin reconciliation (scroll-padding-top == scroll-margin-top at the same header token)"
    - "Scrim click-outside dismiss wired via JS.exec(on_cancel) |> hide_modal/hide_drawer (no inline on*=)"
    - "Tier B representative sample on real /audit/* + stress matrix; routeWebSocket block for a held socket-drop"
key-files:
  created:
    - ".planning/phases/178-per-page-flow-stress-pass-all-11-pages/178-05-SUMMARY.md"
  modified:
    - "lib/threadline/operator_surface/style.ex"
    - "lib/threadline/operator_surface/ui.ex"
    - "examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts"
    - ".planning/REQUIREMENTS.md"
decisions:
  - "#1 fix is a single desktop-layer .tl-target-row rule reconciling scroll-margin-top to the DESKTOP --tl-header-height offset; the mobile/overscroll/100svh half was already green from Phase 177"
  - "#6 fix retokenizes the lone off-rhythm gap (.tl-timeline-fact 2px) onto var(--tl-space-1) (4px) — the smallest existing space token; no new token added"
  - "#4 fix adds phx-click to the scrim element invoking the same on_cancel + hide path as Esc/click-away; the scrim becomes a real click-outside affordance independent of the #3 focus mechanism"
  - "Tier B overlay cells drive the REAL prune-confirm modal (focusable content) rather than the stress modal (text-only, no focus target); scrim-click + Esc + hit-test prove the real operator overlay"
  - "Real socket-drop (D-13) asserts the dropped socket is DETECTED (phx lifecycle classes flip on [data-phx-main]) + clears on reconnect; the D-11 banner-reveal anchor (.threadline-ui.phx-*) does not match the real class-bearing ancestor — documented as a follow-up, not silently re-architected"
metrics:
  duration: "~95 min"
  completed: "2026-06-18"
  tasks: 3
  files_changed: 4
status: complete
---

# Phase 178 Plan 05: PAGE-02 footgun fix-to-green + Tier B finalization Summary

Turned the last three Wave-0 footgun RED scaffolds GREEN — #1 (desktop scroll-trap
reconciliation), #6 (off-rhythm spacing token), and #4 (scrim click-outside dismiss)
— bringing all 11 named footgun classes to GREEN across the operator surface, and
finalized the Tier B representative ~66-cell sample with the two-tier honesty framing.
The full operator_surface Tier A suite is now 591 tests / 0 failures (zero RED-by-design
scaffolds remaining); the Tier B sample is 63 cells GREEN on the dark lanes + 21 on the
light lane in a real Chromium engine. No new `--tl-*` token, no new dependency, no
public API, no inline `on*=` handler; capture & semantics layers byte-for-byte untouched;
the PAGE-03 `justify-self: center` rules from Plan 03 are preserved.

## What was built

**Task 1 — surface-wide footgun fixes (commit `e198d2c`, `style.ex`):**
- **#1 scroll-trap reconciliation:** added a `.tl-target-row { scroll-margin-top: calc(var(--tl-header-height) + var(--tl-space-4)); }` rule inside the `@media (min-width: 768px)` layer so a deep-linked anchored row clears the DESKTOP sticky topbar (matching the desktop `scroll-padding-top`), not just the mobile offset.
- **#6 spacing token:** retokenized `.tl-timeline-fact` `gap: 2px` → `gap: var(--tl-space-1)` (4px, the smallest existing space token) so the lone off-rhythm stressed-page child gap resolves through the `--tl-space-*` scale.
- Contrast (#10/#11), cursor (#5), disabled (#7) were already GREEN-confirming and untouched.

**Task 2 — overlay #4 scrim click-outside (commit `9413666`, `ui.ex`):**
- Added `phx-click={JS.exec(@on_cancel, "phx-remove") |> hide_modal(@id)}` to `.tl-modal-scrim` and the drawer equivalent to `.tl-drawer-scrim` — the scrim becomes a genuine click-outside dismiss affordance, wired via `Phoenix.LiveView.JS` (CSP-safe, no inline `on*=`), independent of the `#3` focus-entry / `phx-click-away`-on-content mechanism.

**Task 3 — Tier B finalization (commit `a3bc25d`, `operator-phase-178-uat.spec.ts`):**
- Un-`.fixme`'d the #1 scroll-trap and real socket-drop cells; **no scaffold markers remain**.
- Stated the two-tier honesty contract in the spec header (Tier A = full structural cartesian; Tier B = representative real-engine sample; a green suite ≠ all ~3,465 cells eyeballed).
- Added the overlay footgun sample on the **real prune-confirm modal** (`/audit/policy/retention`, focusable content): z-order hit-test (#2), keyboard-reachable focus (#3 real-engine half), Esc dismiss (#4 keyboard half), scrim click-outside dismiss (#4 click-outside half).
- Added active-state (#8 nav `aria-current` + non-color inset shadow), pager (#9 honest range caption + disabled-control reflection), disabled affordance (#5/#7 `not-allowed` cursor + real disabled), keyboard-only Tab-reach, and reduced-motion collapse cells.
- Real socket-drop (D-13) via `routeWebSocket` block: a genuinely dropped socket is **detected client-side** (phoenix lifecycle classes flip + clear on reconnect) — the gap a static fixture cannot simulate.
- NO pixel-diff. Registered on the `desktop-chromium-light` lane (D-02 dark+light).

## The 11 footgun classes — detector + fix ledger

| # | Footgun class | Tier A detector | Tier B | Fix in this plan? |
|---|---------------|-----------------|--------|-------------------|
| #1 | Scroll traps | `style_contract_test` desktop scroll-padding↔scroll-margin reconciliation | `/audit/*` sweep: desktop scroll container reserves topbar height | **REAL FIX** — added desktop `.tl-target-row` rule |
| #2 | Modal/drawer behind scrim / floats wrong | `component_contract_test` z-token ascending guard | prune-modal `elementFromPoint` hit-test above scrim | GREEN-confirming (held) |
| #3 | Focus not entering/restoring from overlays | `component_contract_test` `JS.focus_first`/`phx-mounted` presence | prune-modal keyboard-reachable focus target | GREEN-confirming (structural hooks present) |
| #4 | Escape/click-outside inconsistency | `component_contract_test` Esc binding (held) + scrim `phx-click` marker (RED→GREEN) | prune-modal Esc dismiss + scrim click-outside dismiss | **REAL FIX** — scrim `phx-click` added |
| #5 | Hover/focus on non-interactive | `style_contract_test` no `cursor:pointer` on non-interactive | disabled-control cursor cell | GREEN-confirming (held) |
| #6 | Misalignment / chopped padding / spacing | `style_contract_test` `--tl-space-*` source scan | `/audit/*` within-viewport sweep @320/1440 | **REAL FIX** — `.tl-timeline-fact` gap retokenized |
| #7 | Disabled-looks-enabled / enabled-looks-disabled | `component_contract_test` disabled affordance | `not-allowed` cursor + real `disabled` cell | GREEN-confirming (held) |
| #8 | Missing tab active-state | `component_contract_test` `aria-current` + non-color cue | nav active-state inset-shadow cell | GREEN-confirming (held) |
| #9 | Weird pagination | `component_contract_test` pager disable-at-edge/hide-at-zero | timeline pager honest range + disabled reflection | GREEN-confirming (held) |
| #10 | Unreadable dark/light text | `style_contract_test` `contrast_ratio/2` per-role AA | (covered by Tier A engine; Tier B spot-check via rendered lanes) | GREEN-confirming (held) |
| #11 | Same-color text-on-background | `style_contract_test` `contrast_ratio/2` composite AA | same | GREEN-confirming (held) |

Three real fixes (#1, #4, #6); eight GREEN-confirming permanent guards held. No detector regressed.

## RED → GREEN delta

| Assertion | Tier | Before (entering Plan 05) | After |
|-----------|------|---------------------------|-------|
| #1 desktop scroll reconciliation (`.tl-target-row` @>=768px) | A | RED | **GREEN** |
| #6 `.tl-timeline-fact` spacing token | A | RED | **GREEN** |
| #4 scrim click-outside dismiss marker (modal + drawer) | A | RED | **GREEN** |
| Full `test/threadline/operator_surface/` Tier A suite | A | 591 tests / 3 failures | **591 / 0** |
| Tier B representative sample (footgun sweep + ~66-cell) | B | scaffold (`test.fixme`) | **GREEN: 63 dark + 21 light** |

## Deviations from Plan

### Auto-fixed / scope-honest adjustments

**1. [Rule 1 — Bug, real-engine finding] The reconnect-banner reveal anchor (D-11) does not match the real phoenix class-bearing element.**
- **Found during:** Task 3 (running the real socket-drop spec).
- **Issue:** D-11 locked the connection-class anchor as `.threadline-ui.phx-loading` / `.threadline-ui.phx-error`, and the Tier A guard hard-codes that selector. The real-engine drop proves phoenix_live_view attaches its lifecycle classes (`phx-loading` / `phx-error` / `phx-client-error`) to the LiveView CONTAINER element `[data-phx-main]`, which in this app is a **parent** of `.threadline-ui`, not `.threadline-ui` itself. So the banner-reveal CSS keyed on `.threadline-ui.phx-*` never fires on a genuine socket drop — the exact gap the 177 inject-probe masked by manually adding the class to `.threadline-ui`.
- **Resolution (scope-honest, NOT silently re-architected):** Per Rule-4 discipline, I did **not** change the locked D-11 CSS / Tier A guard or the shell structure here — that re-anchoring is an architectural decision against a locked CONTEXT decision. Instead the Tier B socket-drop cell now asserts the **honest, observable contract** — the dropped socket IS detected client-side (lifecycle classes flip on `[data-phx-main]` and clear on reconnect), which is precisely what D-13 says a fixture cannot prove — and the banner-reveal-anchor mismatch is captured inline in the spec and here as a follow-up. The cell stays green without masking the gap.
- **Files:** `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` (commit `a3bc25d`).

**2. [Plan latitude — Tier B target selection] Overlay cells driven on the real prune modal, and #1/#9 measured structurally where no markup producer exists.**
- The plan's Task 3 listed overlay focus/Esc/scrim cells "on the stress story matrix." The stress modal (`group.modal-destructive.current`) content is text-only ("Modal Content") with **no focusable child**, so `JS.focus_first` has no target and Esc/focus assertions cannot pass against it. I drove #2/#3/#4 against the **real prune-confirm modal** (`/audit/policy/retention`) which has genuine focusable content (input + Cancel/Confirm) — a more honest operator overlay. Similarly, `.tl-target-row` (#1) is a pure CSS hook with no markup producer in the seeded surface, so the Tier B #1 cell proves the **computed desktop scroll-padding reserves the real topbar height** (real-engine confirmation of the reconciled offset) rather than scrolling to a non-existent anchored row; #9 proves the live timeline pager renders an honest range caption + disabled-control reflection. All within Task 3's "representative real-engine sample" mandate.

### Notes (within plan)
- The whole Tier B suite runs `reducedMotion: "reduce"` (playwright.config); the explicit reduced-motion cell proves the operator surface's `prefers-reduced-motion` rules actually collapse the overlay transition to `0.001s`, not merely that the lane is configured.
- The `test.skip(condition, …)` guards that earlier drafts used for data-dependent pager/disabled controls were **removed** — the cells now target deterministic surfaces, so no conditional skip (and no `test.fixme` scaffold) remains.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: reconnect-anchor-gap | lib/threadline/operator_surface/style.ex (`.threadline-ui.phx-loading/.phx-error` reveal selectors) | The reconnect-banner / `[data-tl-mutating]` reveal CSS is keyed on `.threadline-ui.phx-*`, but phoenix_live_view applies the lifecycle classes to the `[data-phx-main]` ancestor — so the banner does NOT reveal on a real socket drop. Needs a follow-up decision to re-anchor the reveal selector (and its Tier A guard + D-11) onto the actual class-bearing container without violating the no-`<body>` / no-`.phx-disconnected` invariant. Detected by the real socket-drop spec; documented rather than silently re-architected. |

## Verification

- `mix test test/threadline/operator_surface/` → **591 tests, 0 failures** (all 11 footgun detectors GREEN; PAGE-03 `justify-self` guards still GREEN — not regressed).
- `mix compile --warnings-as-errors` clean; `mix format --check-formatted` clean (whole tree); `mix credo --strict` → 2139 mods/funs, no issues.
- `mix test test/threadline/brandbook_token_parity_test.exs` → **4 tests, 0 failures** (zero new `--tl-*` token; the #6 fix composes the existing `--tl-space-1`).
- Tier B real Chromium (via `examples/threadline_phoenix/e2e/run-e2e.sh`): dark lanes (chromium + desktop-chromium + mobile-chromium) → **63 passed**; light lane (`THREADLINE_E2E_THEME=system`, `desktop-chromium-light`) → **21 passed**. No pixel-diff; no scaffold markers.
- Capture & semantics layers: `git diff --stat e198d2c^..HEAD -- lib/threadline/{audit,capture,semantics}` → empty (byte-for-byte untouched).
- This plan changed exactly 3 code/spec files (`style.ex` +10/-2, `ui.ex` +14/-2, the Tier B spec) plus `REQUIREMENTS.md`; PAGE-03 `justify-self: center` present on both `.tl-container` (style.ex:678) and `.tl-home` (style.ex:693).
- No inline `on*=` handler introduced; the scrim dismiss is wired via `Phoenix.LiveView.JS`.

## Self-Check: PASSED

- `lib/threadline/operator_surface/style.ex` — FOUND (#1 desktop `.tl-target-row` rule, #6 `var(--tl-space-1)` gap, both `justify-self: center` preserved)
- `lib/threadline/operator_surface/ui.ex` — FOUND (scrim `phx-click` on modal + drawer)
- `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` — FOUND (finalized, no `test.fixme`)
- Commit `e198d2c` (Task 1) — FOUND
- Commit `9413666` (Task 2) — FOUND
- Commit `a3bc25d` (Task 3) — FOUND
