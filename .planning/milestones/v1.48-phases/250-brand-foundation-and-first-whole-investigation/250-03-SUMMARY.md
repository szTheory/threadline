---
phase: 250-brand-foundation-and-first-whole-investigation
plan: "03"
subsystem: ui
tags: [phoenix, css, fonts, operator-surface, typography]
requires:
  - phase: 250-02
    provides: Approved Threadline brand assets and operator style foundation
provides:
  - Four exact approved WOFF2 faces embedded under Threadline-private aliases through the existing option boundary
  - Token-backed heading, body, label, metadata, identifier, and table typography roles
  - Updated source contracts and stylesheet byte locks for the intentional typography change
affects: [250-05-package-assets, 250-08-rendered-browser-proof]
actuals:
  tokens: null
  tasks: 2
  commits: 3
plan_head_before: 65c4cfbde68e5419f4a07150bc94afca24bee92c
plan_head_after: 138df52bfd6a8e4bb2ed514903d32e108ca1de2c
tech-stack:
  added: []
  patterns:
    - Compile-time WOFF2 embedding retains the existing opt-out and system fallback boundary
    - CSS source roles are asserted and rendered stylesheet bytes are pinned together
key-files:
  created:
    - test/threadline/operator_surface/fonts_test.exs
  modified:
    - lib/threadline/operator_surface/fonts.ex
    - lib/threadline/operator_surface/style/01_tokens.css
    - lib/threadline/operator_surface/style/04_controls.css
    - lib/threadline/operator_surface/style/07_find_detail.css
    - test/threadline/operator_surface/style_contract_test.exs
    - test/fixtures/style/operator_surface.css
    - test/threadline/operator_surface/style_byte_lock_test.exs
key-decisions:
  - Reused the compile-time embedder and existing false/default option instead of adding a font route or public configuration.
  - Kept private font aliases and system fallbacks in the shared base lane; light and System themes inherit those role tokens.
  - Kept browser-loaded font and computed-style proof assigned to Plan 250-08.
requirements-completed: ["ADM-10", "ADM-09", "ADM-17"]
coverage:
  - id: D1
    description: Four approved WOFF2 assets use exact bytes, private aliases, approved weight descriptors, and the existing default/opt-out behavior.
    verification:
      - kind: unit
        ref: test/threadline/operator_surface/fonts_test.exs#embeds exactly the approved WOFF2 bytes under private aliases and weights
        status: pass
      - kind: unit
        ref: test/threadline/operator_surface/fonts_test.exs#an absent embedding option emits the approved faces by default
        status: pass
      - kind: unit
        ref: test/threadline/operator_surface/fonts_test.exs#the existing false embedding option emits no faces
        status: pass
    human_judgment: false
  - id: D2
    description: Typography tokens and selector roles are source-checked, theme lanes inherit readable fallbacks, and the style-owned CSS plus full render are byte-locked.
    verification:
      - kind: unit
        ref: test/threadline/operator_surface/fonts_test.exs#type tokens and investigation selectors preserve approved roles and fallbacks
        status: pass
      - kind: unit
        ref: test/threadline/operator_surface/style_contract_test.exs#operator typography defaults stay readable and dense text is opt-in
        status: pass
      - kind: unit
        ref: test/threadline/operator_surface/style_byte_lock_test.exs#rendered output equals the fonts prefix plus the golden file
        status: pass
    human_judgment: false
duration: 28min
completed: 2026-11-12
status: complete
---

# Phase 250 Plan 03: Brand Foundation and First Whole Investigation Summary

**Four approved WOFF2 faces embed under private aliases with 12px labels, 13px metadata and identifiers, 16px body text, and 28px headings.**

## Performance

- **Duration:** 1704.8 seconds (managed launch through terminal exit)
- **Started:** 2026-11-12T14:10:27.684142Z
- **Completed:** 2026-11-12T14:38:52.497846Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Embedded the approved Familjen Grotesk variable, Geist variable, and IBM Plex Mono 400/500 faces using exact asset bytes, private aliases, and the existing compile-time option. The default and false opt-out behaviors remain covered.
- Updated shared typography tokens and the assigned control/detail selectors for heading, body, label, metadata, identifier, and table roles. Light and System lanes inherit the readable base font fallbacks.
- Updated focused style assertions, regenerated the documented CSS golden after reviewing the typography diff, and pinned the golden and full rendered output hashes together.

## Task Commits

1. **Task 1 RED: Add failing font role contract** - `218c7500` (`test`)
2. **Task 1 GREEN: Embed approved font roles** - `c9cfbf96` (`feat`)
3. **Task 2: Lock approved typography roles** - `138df52b` (`test`)

The RED run executed four tests and failed three source/role assertions as expected; the existing false-opt-out assertion passed. The GREEN implementation then passed the same focused font contract.

## Files Created/Modified

- `lib/threadline/operator_surface/fonts.ex` - Four compile-time approved faces, private family aliases, exact descriptors, and the retained default/opt-out behavior.
- `lib/threadline/operator_surface/style/01_tokens.css` - Private fallback chains and the approved role sizes, weights, and line heights.
- `lib/threadline/operator_surface/style/04_controls.css` - Heading, body, label, metadata, and control roles.
- `lib/threadline/operator_surface/style/07_find_detail.css` - Mono values/tables and detail typography roles.
- `test/threadline/operator_surface/fonts_test.exs` - Exact asset-byte, descriptor, option, role, and fallback contracts.
- `test/threadline/operator_surface/style_contract_test.exs` - Updated typography role and theme inheritance assertions while retaining responsive and control checks.
- `test/fixtures/style/operator_surface.css` - Intentional rendered CSS golden update.
- `test/threadline/operator_surface/style_byte_lock_test.exs` - Updated golden and full-render SHA-256 pins.

## Decisions Made

- Kept font embedding in the existing compile-time data-URI boundary. No runtime font route, public option, dependency, or remote fetch was added.
- Reused the common base font roles across dark, light, and System color lanes, with readable local/system fallbacks and no empty font values.
- Deferred package archive inclusion and browser-loaded/computed-font proof to Plans 250-05 and 250-08, respectively.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first formatter attempt on the new test failed on a sigil delimiter. The test source check was rewritten with `String.contains?/2`; formatting then passed.
- The first GREEN run exposed an unanchored test selector helper matching a longer selector. The helper was anchored to the exact selector, and the focused font tests passed.
- The first combined typography test run found two stale assertions for regular-weight labels and label-sized buttons. Assertions were updated to the approved strong label and 16px body roles; the responsive and hit-area checks remain.
- The documented golden generation completed, and the focused lock suite confirmed the regenerated fixture and both hash pins.

## Verification

- `mix verify.test test/threadline/operator_surface/fonts_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/style_byte_lock_test.exs test/threadline/brandbook_token_parity_test.exs` — 80 tests, 0 failures.
- `mix compile --warnings-as-errors` — passed.
- `mix verify.format` — passed.
- The pre-edit read-only `check-before` gate passed. The pair database materialization check after focused verification still matched its accepted snapshot. The ExUnit suite used the separate `p250tests` partition.
- The retained parent app continued serving from its distinct, unchanged source checkout. This plan did not restart it or claim browser-loaded fonts, computed roles, package inclusion, or fallback behavior under blocked font loading; those proofs remain with their assigned plans.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Font source bytes, option behavior, CSS role contracts, compile, format, and style byte locks are ready for the package and rendered-browser proofs in Plans 250-05 and 250-08. The parent owns phase state and independent review; no shared planning artifacts were edited.

---
*Phase: 250-brand-foundation-and-first-whole-investigation*
*Completed: 2026-11-12*

## Self-Check: PASSED

All created/modified key files exist; all three task commits are ancestors of the assigned branch HEAD. The plan-scoped evaluation resolver found three commits for `250-03`, and the task acceptance checks plus plan-level verification passed.

Parent reconciliation uses the complete managed invocation for elapsed time. Provider usage is retained in the process receipt; no scalar token estimate is asserted from source size.


## Final milestone traceability writeback

This plan's declared requirement contributions are now reflected in `requirements-completed`, following the independently passed phase goal and final34-requirement integration check/current candidate CI. Earlier empty completion fields were local contribution bookkeeping, not a new missing implementation. Historical results remain preserved; the bounded successor-impact verification owns current fingerprint freshness.
