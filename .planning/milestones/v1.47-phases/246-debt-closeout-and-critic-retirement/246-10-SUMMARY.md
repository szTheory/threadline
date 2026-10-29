---
phase: 246-debt-closeout-and-critic-retirement
plan: 10
subsystem: testing
tags: [ci, playwright, doc-contract, removal-slice, browser-full]

requires:
  - phase: 246-08
    provides: "C7 spec-derived coverage phrase and CiCoverageDocContractTest"
provides:
  - "Removal slice C8 (e9a97139): honest route-capture scorecard wording, twin-aware derived phrase, regex denylist, block-scoped sources"
  - "Nine-slice landing recipe in 246-LANDING.md"
  - "R2-WR-01 / R2-WR-02 dispositions fixed"
affects: [247, landing, removal-squash]

actuals:
  tokens: 5936
  tasks: 3
  commits: 2
plan_head_before: b531d65d215e38b34c88f5e6cea229c8cb5365e8
plan_head_after: 62b137b141d66d2f5b2c199347ae4bb0468fd023

tech-stack:
  added: []
  patterns:
    - "False-claim denylist as {regex, sample} pairs, so every pattern carries its own mutation control"
    - "Doc sources scoped to the comment block that describes coverage, not the whole file"

key-files:
  created: []
  modified:
    - test/threadline/ci_coverage_doc_contract_test.exs
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - CONTRIBUTING.md
    - .github/workflows/browser-full.yml
    - .planning/phases/246-debt-closeout-and-critic-retirement/246-LANDING.md
    - .planning/phases/246-debt-closeout-and-critic-retirement/246-REVIEW-DISPOSITION.md

key-decisions:
  - "The fix ships as a new slice C8 rather than an amendment of C7, so the recorded C7 SHA f57237d6 stays valid"
  - "The degraded twin counts as a twin of a curated route, not a sixth route: phrase is '5 curated operator routes plus a degraded Timeline twin at 1280', derived from const ROUTES"
  - "The playwright scoped block skips only blank or bare '{' lines above name: \"route-capture\", so an unrelated comment higher up can never be picked up"

patterns-established:
  - "Each false-claim regex is paired with a sample sentence that trips exactly that one pattern"

requirements-completed: [DEBT-02]

coverage:
  - id: D1
    description: "playwright.config.ts route-capture comment says the curated 1280 smoke writes route-scorecards/ and that evidence mode runs the inventory tests"
    requirement: DEBT-02
    verification:
      - kind: unit
        ref: "test/threadline/ci_coverage_doc_contract_test.exs#every Browser-full coverage description matches what the spec runs (WR-01)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CiCoverageDocContractTest refuses four false-claim patterns, each with a mutation control; sources are block-scoped"
    requirement: DEBT-02
    verification:
      - kind: unit
        ref: "test/threadline/ci_coverage_doc_contract_test.exs#a false claim, a dropped phrase or a wrong route count turns the wording check red"
        status: pass
      - kind: unit
        ref: "test/threadline/ci_coverage_doc_contract_test.exs#only the scoped coverage comment counts, not the phrase elsewhere in the file (R2-WR-02)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Twin-aware spec-derived phrase stated in all three sources, with empty/zero and edge flunks"
    requirement: DEBT-02
    verification:
      - kind: unit
        ref: "test/threadline/ci_coverage_doc_contract_test.exs#the curated-route derive is non-vacuous and twin-aware"
        status: pass
    human_judgment: false
  - id: D4
    description: "Removal slice C8 committed green; landing recipe lists nine slices with 0 .planning/ paths each"
    verification:
      - kind: other
        ref: "CI=true mix ci.all (ephemeral postgres:16) exit 0"
        status: pass
      - kind: other
        ref: "bash: git log --grep='^Removal-Slice:' slice loop (n=9, 0 .planning/ paths)"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-10-26
status: complete
---

# Phase 246 Plan 10: Honest route-scorecard wording and exact curated-route count (slice C8) Summary

**The contract now refuses both scorecard-mode inversions and their paraphrases, using four regexes with one mutation control each, and checks only the comment block that describes coverage. All three sources state the spec-derived "5 curated operator routes plus a degraded Timeline twin at 1280". The change shipped as removal slice C8 (`e9a97139`).**

## Performance

- **Duration:** about 18 min
- **Started:** 2026-10-26T02:53:21Z
- **Completed:** 2026-10-26T03:11:02Z
- **Tasks:** 3
- **Files modified:** 6 (4 code/doc in C8, 2 `.planning/` in the docs commit)

## Accomplishments

- Fixed the residual of WR-01. The playwright.config.ts route-capture comment now says the curated 1280 render smoke, which runs outside evidence mode, writes `route-scorecards/`. Evidence mode runs the inventory-wide 1280/768/375 tests and writes per-width scorecards under its run root.
- R2-WR-02: `@false_claims` is now four case-insensitive regexes, each paired with a sample sentence that trips only that pattern: every/all inventory routes, three viewports, "in evidence mode, writes the route scorecards" and "scorecards run only in evidence mode". The two file sources are scoped. For browser-full.yml that is the `#` header block before the first `name:`. For playwright.config.ts it is the contiguous `//` block directly above `name: "route-capture"`.
- R2-WR-01: `curated_routes/1` and `curated_phrase/1` derive the phrase from the uncommented `const ROUTES` entries, with the `degrade: true` entry stated as a degraded twin. The derive flunks on zero curated routes, two or more twins, a twin of no curated route, or empty BREAKPOINTS.
- Updated 246-LANDING.md to a nine-slice recipe and marked R2-WR-01 and R2-WR-02 `fixed` (open rows went from 14 to 12).

## TDD evidence

- **Task 1 RED:** after the denylist became regexes, the live-tree test failed on the unedited config with exactly: `playwright.config.ts states the false claim \`scorecards run only in evidence mode\` (review WR-01 / R2-WR-02)` (6 tests, 1 failure). This is the planned assertion failing for the intended reason. GREEN after the comment rewrite: 6 tests, 0 failures.
- **Task 2 RED:** after the twin-aware derive and scoping, the live-tree test failed on all three sources: CONTRIBUTING.md `## CI Coverage`, the browser-full.yml header comment and the playwright.config.ts route-capture comment each `lacks the spec-derived phrase` (7 tests, 1 failure). GREEN after the three rewordings: 7 tests, 0 failures.
- The plan's commit design puts Tasks 1 and 2 in one green slice (C8), so there are no separate `test:` / `feat:` commits. The RED evidence above is recorded from the actual runs.

## Gate results (before C8 was committed)

- `mix format --check-formatted`: clean. `mix verify.credo`: found no issues. `bin/verify-repo-hygiene`: 4506 files clean. `verify-phase.sh --close`: all checks passed.
- Targeted contract set (6 files): 126 tests, 0 failures.
- `CI=true mix ci.all` on an ephemeral labelled postgres:16 (port 55716), exit 0:
  - lib: 32 properties, 3332 tests, 0 failures
  - example: 132 tests, 0 failures
  - Dialyzer: 0 errors
  - CI browser lane: 418 passed, 0 failed, 56 skipped
  - The container was removed afterwards; zero labelled containers remain.

## Task Commits

1. **Task 1: Tracer, refuse the inverted scorecard claim and fix the config comment.** Deliberately left uncommitted; it is part of C8.
2. **Task 2: Twin-aware phrase, block-scoped sources, rewordings, full gate.** `e9a97139` (chore, trailer `Removal-Slice: C8`; exactly the 4 files, 0 `.planning/` paths, nothing under e2e/tests or e2e/support).
3. **Task 3: Record C8 in LANDING, fix dispositions.** `62b137b1` (docs, 2 `.planning/` files, no Removal-Slice trailer).

## Files Created/Modified

- `test/threadline/ci_coverage_doc_contract_test.exs`: changes:
  - regex `{pattern, sample}` denylist
  - `curated_routes/1`, `curated_phrase/0,1`, `twin_label/1`, `scoped_source/2` (`route_count/1` removed)
  - new edge, scoping and dropped-twin controls
  - updated moduledoc
- `examples/threadline_phoenix/e2e/playwright.config.ts`: route-capture comment rewritten (comment lines only)
- `CONTRIBUTING.md`, `.github/workflows/browser-full.yml`: twin-aware coverage phrase
- `246-LANDING.md`: changes:
  - nine-slice table row 9 (C8)
  - C8 paragraph
  - "not contiguous" clause
  - cherry-pick line ends `e9a97139`
  - range-diff example `4b2c3f89^..e9a97139`
  - `(C7, C8)` annotation
  - counts eight to nine
- `246-REVIEW-DISPOSITION.md`: R2-WR-01 and R2-WR-02 `fixed` / `e9a97139`

Recount: the slice path union is 528, deletions are 479 and modified/added paths are 49, all unchanged. The per-slice `.planning/` loop printed 0 for all nine slices.

## Decisions Made

- The playwright block scoping skips only blank and bare `{` lines. If anything else sits between the comment and `name: "route-capture"`, the test flunks instead of reaching up to an unrelated comment.
- `assert [only] = claimed` in the mutation control proves that each sample sentence trips exactly one pattern, not just "some" pattern.

## Deviations from Plan

None in scope. One observation:

- The Task 3 slice-count `<automated>` one-liner exited 1 when run in the agent's default zsh. zsh does not word-split the unquoted `$slices`, so `$#` was 1. Under `bash -c` the same command printed n=9 and exited 0, and the separate reverse loop listed all nine slices with 0 `.planning/` paths. This is a shell-dialect artifact of the verify text, not a slice defect. No file was changed for it.

**Total deviations:** 0 auto-fixed.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Truth 10 should verify on re-verification. Next step: `/gsd-verify-work 246` (re-verification), then phase close.
- R2-IN-01 (the hand-written 1280/768/375 inventory widths) stays `open` by plan decision.

---
*Phase: 246-debt-closeout-and-critic-retirement*
*Completed: 2026-10-26*

## Self-Check: PASSED
