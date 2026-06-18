---
phase: 178-per-page-flow-stress-pass-all-11-pages
verified: 2026-06-18T19:58:01Z
status: gaps_found
score: 11/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Per D-10/D-11, reconnect_banner is keyed off .threadline-ui.phx-loading/.phx-error and reveals on a genuine LiveView socket drop (the 'reconnect' stress dimension of PAGE-01 + SEED-005 closure)"
    status: failed
    reason: >
      The banner is mounted exactly once in the shared shell (structurally GREEN), but the
      reveal CSS is keyed off `.threadline-ui.phx-loading`/`.threadline-ui.phx-error` while
      phoenix_live_view attaches its lifecycle classes (phx-loading/phx-error/phx-client-error)
      to the `[data-phx-main]` container — which is a PARENT of `.threadline-ui`, NOT
      `.threadline-ui` itself. The real socket-drop Tier B spec (178-05, commit a3bc25d)
      proved this in a real Chromium engine. Consequence: on a genuine disconnect the
      reconnect banner does NOT reveal AND the `[data-tl-mutating]` dimming (opacity:.55 +
      pointer-events:none on the prune/save/delete controls) does NOT engage — the exact
      affordance the reconnect dimension is supposed to deliver. D-11 ("the LiveView
      render-root IS .threadline-ui ... no parent indirection") is factually wrong for this
      app; the Tier A guard hard-codes that wrong selector and asserts only that the string
      is present in the stylesheet, so it stays GREEN while masking the behavioral failure.
      Server-side prune enforcement (authorize_prune + Plug.Crypto.secure_compare + fail-closed)
      is byte-for-byte intact, so this is a UX/affordance gap, not a security hole.
    artifacts:
      - path: "lib/threadline/operator_surface/style.ex"
        issue: "reconnect-banner + [data-tl-mutating] reveal CSS (~style.ex:3411-3426) keyed on .threadline-ui.phx-loading/.phx-error, which never matches the real class-bearing [data-phx-main] ancestor"
      - path: "test/threadline/operator_surface/component_contract_test.exs"
        issue: "the reconnect Tier A guard (~line 287) asserts the literal selector STRING is present in source, not that it matches the rendered DOM — a string-presence guard that cannot catch the wrong-anchor bug (selector-presence != selector-correctness)"
    missing:
      - "Re-anchor the reveal selector (and its Tier A guard + the locked D-11 CONTEXT decision) onto the actual class-bearing container ([data-phx-main] / the LiveView root), WITHOUT regressing the no-<body> / no-.phx-disconnected invariant (D-11)"
      - "A Tier B assertion that the banner actually becomes visible (and a [data-tl-mutating] control actually computes opacity:0.55 / pointer-events:none) on a real drop — not merely that the drop is detected on [data-phx-main]"
human_verification:
  - test: "Open /audit/policy/retention, open the prune-confirm modal, then drop the live socket (window.liveSocket.disconnect() or block the /live/websocket route). Observe the reconnect banner and the prune button."
    expected: "Reconnect banner should become visible and the prune button should visibly dim (opacity ~0.55) and stop accepting clicks until reconnect. CURRENTLY: neither fires, because the reveal CSS is keyed off .threadline-ui (wrong) instead of [data-phx-main]."
    why_human: "Requires a running LiveView server and a genuine socket drop; the Tier A suite asserts only that the (wrong) selector string exists in the stylesheet and cannot observe whether it matches the live DOM."
---

# Phase 178: Per-page & flow stress pass (all 11 pages) Verification Report

**Phase Goal:** Stress every operator page across all paths, themes, viewports, keyboard, reduced-motion, and reconnect; eliminate the named footgun classes and fix the desktop centering bug.
**Verified:** 2026-06-18T19:58:01Z
**Status:** gaps_found
**Re-verification:** No — initial verification (prior run dropped before writing)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | PAGE-03: `.tl-container` carries `justify-self: center` keeping `max-width:1000px` | ✓ VERIFIED | style.ex:675-678 (`max-width:1000px` + `justify-self:center`); 178-03 turned the Wave-0 RED guard GREEN |
| 2 | PAGE-03 latent twin: `.tl-home` ALSO carries `justify-self: center` | ✓ VERIFIED | style.ex:689-693 (`max-width:1000px` + `justify-self:center`); Home twin not dropped |
| 3 | PAGE-03 Tier A `justify-self` guards GREEN (both selectors) | ✓ VERIFIED | style_contract_test.exs has 9 `justify-self` assertions; full suite 591/0 |
| 4 | PAGE-02: all 11 named footgun classes have a permanent detector and are GREEN | ✓ VERIFIED | 178-05 ledger (#1 scroll, #4 scrim, #6 spacing real-fixed; #2/#3/#5/#7/#8/#9/#10/#11 held); 25 footgun-keyword assertions in style_contract_test; suite 591/0 |
| 5 | PAGE-02: WCAG 2.2 AA per-role contrast (>=4.5) dark + light | ✓ VERIFIED | contrast_ratio/2 + composite/2 guards in style_contract_test; Tier B 63 dark + 21 light GREEN (178-05) |
| 6 | PAGE-01: 11 reserved page entries become fixture-backed 7-path CURRENT stories | ✓ VERIFIED | ledger: 0 `page.*.reserved` remain; 11 pages × 7 paths present; stress_fixtures.ex page_cell_identity builds them; stress_fixtures_test 12/0, stress_ledger_test 10/0 |
| 7 | PAGE-01: scores ratcheted upward-only toward 90; baselines raised | ✓ VERIFIED | stress_ledger_test ratchet/locked-ids GREEN (178-04); baselines home.happy/timeline.empty raised |
| 8 | PAGE-01: ledger ↔ stress_fixtures ↔ DESIGN-SYSTEM.md parity (story_id/fixture_key) | ✓ VERIFIED | story_id hyphen vs fixture_key underscore is INTENTIONAL (stress_fixtures.ex:461-462 `page_fixture_subject`); projection-freshness assertion GREEN |
| 9 | PAGE-01: two-tier honesty contract explicit (Tier A cartesian; Tier B ~66-cell sample) | ✓ VERIFIED | spec header states it (operator-phase-178-uat.spec.ts:8-21); 178-05 framing |
| 10 | SEED-005: one @doc false shared shell routes all 11 LiveViews; banner mounted once above #tl-main inside .threadline-ui | ✓ VERIFIED | ui.ex:1140 `def shell` (@doc false:1094); 12 live/*.ex route through it; reconnect_banner at ui.ex:1160 above `<main id="tl-main">`:1161 |
| 11 | SEED-005/D-12: data-tl-mutating wired per scope; prune server-side enforcement byte-for-byte unchanged | ✓ VERIFIED | prune/save/delete buttons bare `data-tl-mutating`; download links + `aria-disabled`/`tabindex=-1`; NONE on policy_redaction or no-op stubs; authorize_prune + secure_compare + fail-closed intact (retention_history_live.ex:67-90) |
| 12 | D-10/D-11/D-13: reconnect banner reveals on a GENUINE socket drop (the 'reconnect' stress dimension) | ✗ FAILED | Reveal CSS keyed on `.threadline-ui.phx-*` (style.ex:3411-3426) but phoenix attaches lifecycle classes to the `[data-phx-main]` PARENT — proven by the real socket-drop Tier B spec (178-05). Banner + `[data-tl-mutating]` dimming do NOT fire on a real drop. See Gaps. |

**Score:** 11/12 truths verified (0 present, behavior-unverified; 1 FAILED with affirmative real-engine evidence)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/threadline/operator_surface/style.ex` | justify-self centering + footgun CSS + reconnect CSS | ⚠️ partial | Centering & footgun fixes VERIFIED; reconnect/`data-tl-mutating` reveal selector is mis-anchored (gap) |
| `lib/threadline/operator_surface/ui.ex` | `def shell` shared chrome + reconnect_banner once | ✓ VERIFIED | ui.ex:1140 shell, :1160 banner; @doc false; all 11 route through it |
| `lib/threadline/operator_surface/stress_fixtures.ex` | 11×7 fixture-backed page stories | ✓ VERIFIED | page_cell_identity / page_data; 84 story+fixture keys (12×7) |
| `.planning/design-system-ledger.json` | 11 pages reserved→current, ratcheted | ✓ VERIFIED | 0 reserved page entries; scores ratcheted |
| `DESIGN-SYSTEM.md` | refreshed Pages projection in parity | ✓ VERIFIED | projection-freshness assertion GREEN (stress_ledger_test) |
| `examples/.../operator-phase-178-uat.spec.ts` | centering + footgun + real socket-drop Tier B | ✓ VERIFIED (as authored) | No scaffold markers; honestly documents the reconnect-anchor finding in-cell |
| `test/.../style_contract_test.exs` | justify-self + footgun + contrast guards | ✓ VERIFIED | 9 justify-self + 25 footgun-keyword assertions |
| `test/.../component_contract_test.exs` | reconnect-mount + overlay/pager/disabled | ⚠️ partial | Mount contract GREEN; the reconnect reveal guard only checks selector-STRING presence, not DOM match |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| style_contract_test.exs | style.ex | `justify-self.*center` source assertion | ✓ WIRED |
| live/*.ex (×11) | ui.ex | `UI.shell` chrome render | ✓ WIRED |
| ui.ex reconnect_banner | style.ex | `.threadline-ui.phx-*` reveal CSS | ✗ NOT_WIRED at runtime — selector targets wrong DOM node (see gap) |
| stress_fixtures.ex | design-system-ledger.json | story_id/fixture_key parity | ✓ WIRED |
| design-system-ledger.json | DESIGN-SYSTEM.md | projection freshness | ✓ WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Tier A operator_surface suite | `mix test test/threadline/operator_surface/` | 591 tests, 0 failures | ✓ PASS |
| Brand-token parity (zero new --tl-*) | `mix test .../brandbook_token_parity_test.exs` | 4 tests, 0 failures | ✓ PASS |
| Centering present in source | grep style.ex:675-693 | both `.tl-container` + `.tl-home` justify-self:center | ✓ PASS |
| Capture/semantics untouched | `git diff --stat ... -- lib/threadline/{audit,capture,semantics}` | empty | ✓ PASS |
| Reconnect banner reveals on real drop | real socket-drop Tier B (D-13) | banner does NOT reveal; only [data-phx-main] class flip detected | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| PAGE-01 | 178-01, 178-02, 178-04 | ⚠️ MOSTLY SATISFIED | 11 pages fixture-backed across 7 paths × themes × viewports (static substrate); but the "× LiveView reconnect" dimension of the criterion is the failing reconnect-reveal path |
| PAGE-02 | 178-01, 178-05 | ✓ SATISFIED | All 11 footgun classes GREEN (Tier A 591/0 + Tier B sample) |
| PAGE-03 | 178-01, 178-03 | ✓ SATISFIED | `.tl-container` + `.tl-home` justify-self:center; Tier A GREEN + Tier B centering geometry PASS |

REQUIREMENTS.md note: PAGE-01 and PAGE-03 are still marked `[ ]` / `Pending` in REQUIREMENTS.md (lines 53/55/127/129); PAGE-02 marked Complete. PAGE-03 evidence is fully satisfied (recommend flipping to Complete on gap closure); PAGE-01's reconnect dimension is what the gap blocks.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| style.ex | ~3411-3426 | Reveal CSS keyed on a selector (`.threadline-ui.phx-*`) that never matches the real class-bearing DOM node | 🛑 Blocker | Reconnect banner + mutating-control dimming silently inert on a genuine socket drop |
| component_contract_test.exs | ~287 | String-presence guard (`assert src =~ ".threadline-ui.phx-loading ..."`) standing in for behavioral verification | ⚠️ Warning | A passing guard that cannot detect the wrong-anchor bug — green Tier A masks the real failure |

No TBD/FIXME/XXX debt markers found in phase-modified files. No new `--tl-*` token, no new dependency, no inline `on*=` handler. CSP-proof (scrim dismiss via Phoenix.LiveView.JS). No pixel-diff baselines. Phase-179 microcopy not pre-empted.

### Human Verification Required

**1. Reconnect banner / mutating-control dimming on a genuine socket drop**

**Test:** Open `/audit/policy/retention`, open the prune-confirm modal, then drop the live socket (`window.liveSocket.disconnect()` or block the `/live/websocket` route). Observe the reconnect banner and the prune button.
**Expected:** Reconnect banner should become visible and the prune button should visibly dim (opacity ~0.55) and stop accepting clicks until reconnect.
**Actual (per 178-05 real-engine spec):** Neither fires — the reveal CSS is keyed off `.threadline-ui` but phoenix flips lifecycle classes on the `[data-phx-main]` ancestor.
**Why human:** Requires a running LiveView server and a genuine socket drop; the Tier A suite only asserts the (wrong) selector string is present in the stylesheet.

### Gaps Summary

The phase delivers 11 of 12 must-haves cleanly: PAGE-03 desktop centering is fixed grid-natively on both `.tl-container` and its latent `.tl-home` twin; all 11 footgun classes carry permanent GREEN detectors (Tier A 591/0, Tier B sample green on dark + light); all 11 reserved page entries are converted to fixture-backed 7-path stories with ratcheted scores and full ledger↔fixtures↔DESIGN-SYSTEM.md parity; the SEED-005 shared shell mounts the reconnect banner exactly once across all 11 LiveViews with `data-tl-mutating` correctly scoped to genuine state-changers; and every v1.37 invariant holds (zero new token, zero new dep, CSP-proof, capture/semantics byte-for-byte untouched).

The single blocking gap is the **reconnect stress dimension** itself. D-11 locked the connection-class anchor as `.threadline-ui.phx-loading`/`.phx-error` on the premise that `.threadline-ui` IS the LiveView render-root with no parent indirection. The real socket-drop Tier B spec (the deliberate purpose of D-13, replacing the 177 inject-probe that masked exactly this) proved that premise false: phoenix attaches its lifecycle classes to the `[data-phx-main]` ancestor, so on a genuine disconnect neither the reconnect banner nor the `[data-tl-mutating]` dimming engages. The 178-05 executor handled this with discipline — it did not silently re-architect a locked CONTEXT decision, recorded a threat flag, and kept the Tier B cell honest — but the result is that the "reconnect" dimension of the phase goal and of PAGE-01's success criterion is not actually delivered, and the Tier A guard is a string-presence check that cannot catch it. Server-side prune enforcement is intact, so this is an affordance/UX gap rather than a security regression. Closure requires re-anchoring the reveal selector (and its Tier A guard + D-11) onto the real class-bearing container without reintroducing the forbidden `<body>` / `.phx-disconnected` anchors, plus a Tier B assertion that the banner actually reveals on a real drop.

This gap is NOT deferrable to a later phase: Phase 179 (microcopy/IA) and Phase 180 (a11y/motion/idempotency-matrix/adversarial-signoff) do not name the reconnect reveal selector; the idempotency-guardrail goal in 180 is matrix expansion, not this re-anchoring.

---

_Verified: 2026-06-18T19:58:01Z_
_Verifier: Claude (gsd-verifier)_
