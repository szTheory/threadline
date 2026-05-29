---
phase: 128-readme-phx-gen-auth-mount-parity
plan: 01
subsystem: testing
tags: [readme, doc-contract, ecto_repos, triggers, quick-start]

requires:
  - phase: 123-first-hour-ecto-repos
    provides: getting-started §2 ecto_repos SSOT and CFG doc-contract pattern
provides:
  - README Quick Start renumbered 1–6 with Configure Threadline step before install
  - posts-only trigger registration with getting-started and production-checklist cross-links
  - section_slice-scoped README doc-contract locks for ecto_repos ordering and trigger SSOT
affects:
  - 128-02-phx-gen-auth-mount
  - phase-129-walkthrough-truth

tech-stack:
  added: []
  patterns:
    - "section_slice/3 scoping for README Quick Start doc-contract tests"
    - "literal_idx ordering lock before mix threadline.install"

key-files:
  created: []
  modified:
    - README.md
    - test/threadline/readme_doc_contract_test.exs

key-decisions:
  - "README Quick Start uses posts-only triggers with SSOT cross-links instead of users,posts,comments fiction"
  - "ecto_repos config step placed before install without claiming mix threadline.install validates Threadline repo wiring"

patterns-established:
  - "Quick Start doc-contract tests scoped via section_slice between ## Quick Start and ## Operator Surface"

requirements-completed: [README-01, README-02, TRIG-01]

duration: 8min
completed: 2026-05-28
---

# Phase 128 Plan 01: README Quick Start Parity Summary

**README Quick Start renumbered to six steps with explicit `ecto_repos` config before install, posts-only triggers, and section_slice doc-contract locks**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-28T21:14:10Z
- **Completed:** 2026-05-28T21:16:20Z
- **Tasks:** 4
- **Files modified:** 2

## Accomplishments

- Added **Configure Threadline** as Quick Start step 2 with literal `config :threadline, ecto_repos: [MyApp.Repo]` and getting-started §2 cross-link before `mix threadline.install`
- Replaced multi-table trigger fiction (`users,posts,comments`) with `mix threadline.gen.triggers --tables posts` plus getting-started §4 and production-checklist §1 cross-links
- Extended `readme_doc_contract_test.exs` with `section_slice/3` and two Quick Start slice locks for ecto_repos ordering and trigger SSOT

## Task Commits

Each task was committed atomically:

1. **Task 1: Renumber README Quick Start with Configure Threadline + posts triggers** - `fb6e65e` (docs)
2. **Task 2: Add section_slice helper to readme doc contract test** - `d419b3b` (test)
3. **Task 3: Doc-contract locks for README ecto_repos ordering (README-02)** - `e4ea920` (test)
4. **Task 4: Doc-contract locks for README trigger SSOT (TRIG-01)** - `85cd57a` (test)

**Plan metadata:** `93b8c8b` (docs: complete plan)

## Files Created/Modified

- `README.md` - Quick Start expanded to 6 steps with ecto_repos config and posts-only triggers
- `test/threadline/readme_doc_contract_test.exs` - section_slice helper plus two Quick Start slice contract tests

## Decisions Made

- Quick Start trigger step uses posts-only command aligned with getting-started §4 SSOT; full table inventory deferred to production-checklist §1
- ecto_repos step documents Threadline repo resolution without claiming install validates wiring (matches getting-started §2 posture)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Quality] Use module attributes in new tests to avoid unused-attribute warnings**
- **Found during:** Task 4 (trigger SSOT test commit)
- **Issue:** `@quick_start_start` / `@quick_start_end` triggered compiler warnings when tests used string literals
- **Fix:** Updated both new tests to call `section_slice(readme, @quick_start_start, @quick_start_end)`
- **Files modified:** `test/threadline/readme_doc_contract_test.exs`
- **Verification:** `mix test test/threadline/readme_doc_contract_test.exs` — 20 tests, 0 failures, no warnings
- **Committed in:** `85cd57a` (Task 4 commit)

---

**Total deviations:** 1 auto-fixed (1 quality/warnings)
**Impact on plan:** No scope change; equivalent test behavior with cleaner compile output.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- README-01, README-02, TRIG-01 satisfied; ready for **128-02-PLAN.md** (phx-gen-auth mount parity: AUTH-MOUNT-01, AUTH-MOUNT-02)
- `mix test test/threadline/readme_doc_contract_test.exs` green (20 tests)

## Self-Check: PASSED

- `[x]` SUMMARY at `.planning/phases/128-readme-phx-gen-auth-mount-parity/128-01-SUMMARY.md`
- `[x]` Task commits: fb6e65e, d419b3b, e4ea920, 85cd57a
- `[x]` `mix test test/threadline/readme_doc_contract_test.exs` — 20 tests, 0 failures
- `[x]` grep README for Configure Threadline / ecto_repos / gen.triggers --tables posts — all match
- `[x]` Quick Start slice refutes `users,posts,comments`

---
*Phase: 128-readme-phx-gen-auth-mount-parity*
*Completed: 2026-05-28*
