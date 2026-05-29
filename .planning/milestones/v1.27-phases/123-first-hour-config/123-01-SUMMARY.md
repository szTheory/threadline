---
phase: 123-first-hour-config
plan: 01
subsystem: docs
tags: [ecto_repos, getting-started, doc-contract, mix-tasks]

# Dependency graph
requires:
  - phase: 122-release-distribution-truth
    provides: Hex 0.6.0 distribution truth for evaluators
provides:
  - "### Configure Threadline" subsection in getting-started with config :threadline, ecto_repos literal
  - Doc-contract test locking ecto_repos placement before §3, §7, and sigra fence
affects:
  - 123-02-PLAN
  - production-checklist cross-link (CFG-03)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Doc-contract ordering assertions via :binary.match index comparisons"

key-files:
  created: []
  modified:
    - guides/getting-started-saas.md
    - test/threadline/getting_started_saas_doc_contract_test.exs

key-decisions:
  - "Insert ecto_repos guidance as §2 subsection only — no top-level heading renumber"
  - "Dual-key split prose: host :ecto_repos for install, :threadline ecto_repos for Mix/operator fallbacks"

patterns-established:
  - "CFG-02 placement lock: literal must precede §3, §7, and getting-started-sigra-reference-fence"

requirements-completed: [CFG-01, CFG-02]

# Metrics
duration: 5min
completed: 2026-05-28
---

# Phase 123 Plan 01: First-Hour ecto_repos in Getting-Started Summary

**Getting-started §2 now documents `config :threadline, ecto_repos: [MyApp.Repo]` before install schema, with doc-contract ordering lock**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-28T17:15:00Z
- **Completed:** 2026-05-28T17:20:46Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `### Configure Threadline` subsection after `mix deps.get` and before `## 3. Install the audit schema`
- Explained dual-key split: host `config :my_app, ecto_repos` for `mix threadline.install` vs `config :threadline, ecto_repos` for Mix tasks and operator fallbacks
- Added doc-contract test asserting literal placement before §3, §7, and sigra optional fence

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Configure Threadline subsection to getting-started** - `7b929a1` (feat)
2. **Task 2: Lock CFG-02 in getting_started_saas_doc_contract_test.exs** - `6e32dab` (test)

**Plan metadata:** pending (this commit)

## Files Created/Modified

- `guides/getting-started-saas.md` - §2 Configure Threadline subsection with ecto_repos literal and rationale
- `test/threadline/getting_started_saas_doc_contract_test.exs` - Ordering lock for ecto_repos placement

## Decisions Made

- Inserted under §2 only; did not renumber §1–§9 top-level headings (per threat model T-123-03)
- Multi-repo guidance limited to footnote prose pointing at production-checklist (per D-08)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for **123-02-PLAN** (production-checklist cross-link for CFG-03)
- `mix verify.doc_contract` green (90 tests, 0 failures)

## Self-Check: PASSED

- Task 1 grep acceptance: PASS
- Task 1 literal before §3 index check: PASS (1581 < 2269)
- Task 2 `mix test test/threadline/getting_started_saas_doc_contract_test.exs`: PASS (5 tests, 0 failures)
- Plan verification `mix verify.doc_contract`: PASS (90 tests, 0 failures)

---
*Phase: 123-first-hour-config*
*Completed: 2026-05-28*
