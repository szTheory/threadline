---
phase: 250-brand-foundation-and-first-whole-investigation
plan: "02"
subsystem: ui
tags: [admin, brand, phoenix-liveview, css, accessibility]
requires:
  - phase: 250
    provides: parent-accepted before evidence and the prepared private test boundary
provides:
  - Approved semantic color roles in the existing Admin token lanes
  - Compile-time dark/light supplied SVGs in the shared Phoenix header
  - Source, theme, semantic-color, and CSS byte-lock assertions
affects: [Phase 250 remaining plans]
actuals:
  tokens: 10159
  tasks: 3
  commits: 3
  plan_head_before: c76107c91b6e75aaf826d9cc2948c542fd31a75b
  plan_head_after: 0e00942b9d097f09d054e63d5e9d66ffcc0dced8
tech-stack:
  added: []
  patterns:
    - Compile-time @external_resource embedding for repository-owned SVG markup
    - Semantic palette assertions remain independent of CSS byte locks
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/components/logo.ex
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/operator_surface/style/01_tokens.css
    - lib/threadline/operator_surface/style/02_base_shell.css
    - lib/threadline/operator_surface/style/07_find_detail.css
    - test/fixtures/style/operator_surface.css
    - test/threadline/brandbook_token_parity_test.exs
    - test/threadline/operator_surface/style_byte_lock_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/operator_surface/surface_header_test.exs
key-decisions:
  - Keep approved contrast roles in existing functional --tl-* variables, with no runtime role registry.
  - Embed only the supplied dark/light SVG sources; hide decorative SVGs from assistive technology and retain the existing home destination.
requirements-completed: []
coverage:
  - id: D1
    description: Existing Admin semantic tokens match approved dark/light role pairs and keep operation, artwork, link, focus, and control roles distinct.
    requirement: ADM-08
    verification:
      - kind: unit
        ref: mix verify.test test/threadline/brandbook_token_parity_test.exs test/threadline/operator_surface/style_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: The shared header uses exact supplied dark/light spool paths, theme swaps, and the named Admin home link.
    requirement: ADM-09
    verification:
      - kind: unit
        ref: mix verify.test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/surface_header_csp_test.exs test/threadline/operator_surface/style_contract_test.exs
        status: pass
    human_judgment: true
    rationale: Browser proof of effective theme appearance and measured rendered size is reserved for Phase 250 Plan 08.
  - id: D3
    description: Approved CSS output is byte-locked while semantic and supplied-source assertions remain independent.
    requirement: ADM-16
    verification:
      - kind: unit
        ref: mix verify.test test/threadline/operator_surface/style_byte_lock_test.exs test/threadline/brandbook_token_parity_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/style_contract_test.exs
        status: pass
      - kind: other
        ref: mix verify.format
        status: pass
    human_judgment: false
duration: null
completed: 2026-11-12
status: complete
---

# Phase 250 Plan 02: Brand foundation and first whole investigation Summary

**Approved Admin semantic colors and source-exact dark/light spool lockups in the shared Phoenix header**

## Performance

- **Duration:** Not measured by this continuation worker; parent process receipt owns elapsed-time reconciliation.
- **Started:** Not available from the continuation receipt.
- **Completed:** 2026-11-12
- **Tasks:** 3
- **Files modified:** 10 source, test, and fixture files.

## Accomplishments

- Mapped the approved eight contrast roles and distinct operation/control/artwork colors to the existing dark, light, and System token lanes.
- Replaced the hand-drawn logo with compile-time embeds of the supplied dark/light SVGs; preserved their viewBox, path geometry, and fill bytes, kept `/audit`, and named the link “Threadline Admin home.”
- Updated the CSS fixture and both hashes after source and semantic tests passed.

## Task Commits

1. **Task 1: Apply approved functional roles and exact contrast pairs** — `d2f15d2a` (`feat(250-02)`).
2. **Task 2: Inline the supplied spool pair and name the home link** — `f7a2614d` (`feat(250-02)`).
3. **Task 3: Reconcile style byte locks** — `0e00942b` (`test(250-02)`).

## Files Created/Modified

- `01_tokens.css`, `07_find_detail.css` — approved role values and Redacted value styling.
- `logo.ex`, `surface_header.ex`, `02_base_shell.css` — trusted supplied pair, accessible home name, scoped theme selection.
- `brandbook_token_parity_test.exs`, `style_contract_test.exs`, `surface_header_test.exs` — palette mutations, source-exact SVG, header, sizing, theme, and CSP contracts.
- `operator_surface.css`, `style_byte_lock_test.exs` — intentional CSS fixture and paired SHA-256 pins.

## Decisions Made

- Kept semantic roles in existing functional CSS variables and used the supplied source artwork without recoloring or redrawing.
- Decorative SVGs are hidden from assistive technology so the existing home link is announced once.
- No phase-level requirement was marked complete: this plan contributes to ADM-08/09/12/16, while full docs/assets coverage, end-to-end value semantics, and rendered appearance remain wider Phase 250 work.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Apply the Redacted operation palette to value styling**
- **Found during:** Task 1.
- **Issue:** `.tl-value--redacted` still used generic warning colors, so the approved Redacted operation pair was not applied to all relevant UI.
- **Fix:** Switched its background and text to the dedicated Redacted semantic tokens.
- **Files modified:** `lib/threadline/operator_surface/style/07_find_detail.css`.
- **Verification:** Palette and style-contract checks passed in the Task 1 run; later semantic and byte-lock suite also passed.
- **Committed in:** `d2f15d2a`.

**Total deviations:** 1 auto-fixed (Rule 2). **Impact:** Required to apply the approved operation meaning consistently; no scope expansion.

## Issues Encountered

- The first check-before launch exited without a result (`zsh: nice(5) failed`); the managed rerun completed and reported candidate integrity true. Parent acceptance was established by the already verified intake; the check-before `parentAcceptance:false` field only reports that the integrity command is not the reviewer.
- Task 1’s first palette test run exposed inherited base-lane values and a stale operation-color expectation; assertions were corrected, then 60 focused tests passed.
- Task 2’s first formatter run found a mismatched list delimiter in the new test, which was corrected. Its first test run had 8 failures because module attributes were read as HEEx assigns; assigning the compile-time SVG strings fixed this, and the rerun passed 65 tests.
- Two commit preflights rejected locally mistyped expected branch/HEAD values before staging. Correct values were checked against this exact worktree, then the normal-hook commits succeeded.
- The final Task 3 focused suite passed 84 tests; `mix verify.format` passed. The Impeccable source detector returned no findings.

## User Setup Required

None.

## Next Phase Readiness

The source, semantic oracles, and CSS byte lock are committed. No browser capture was performed for this plan. Plan 08 still owns rendered contrast, measured logo dimensions, and dark/light/System appearance proof; the parent owns that phase-level review and application lifecycle.

## Self-Check: PASSED

- All 10 modified files exist and the three task commits are ancestors of the plan head.
- The plan-scoped commit resolver found all three production commits on this branch.
- Required focused acceptance checks passed: Task 1 palette/style tests and accepted before-integrity check; Task 2 header/CSP/theme checks; Task 3 semantic/source/byte-lock tests and format.
- Working tree was clean before this summary was created.
