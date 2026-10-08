---
phase: 237-upgrade-guide-and-1-0-0
plan: 03
subsystem: release
tags: [semver, changelog, release-please, candidate, postgres]
requires:
  - phase: 237-upgrade-guide-and-1-0-0
    provides: Upgrade guide and release automation contracts from plans 237-01 and 237-02
provides:
  - Exact v1.44-to-source-tip breaking-footer inventory reconciled with human release notes
  - Dated complete 1.0.0 human changelog with a fresh Unreleased staging heading
  - Persistent single-commit candidate on fetched GitHub main, with passing local rehearsal and CI
affects: [release, upgrade-guide, changelog, CI]
actuals:
  tokens: 7292
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [candidate-mode release rehearsal, exact-SHA source-range audit]
key-files:
  created:
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-VERIFICATION.md
  modified:
    - CHANGELOG.md
    - guides/upgrading-to-1.0.md
    - test/threadline/upgrading_to_1_0_doc_contract_test.exs
    - test/threadline/version_truth_doc_contract_test.exs
    - test/threadline/guide_graph_contract_test.exs
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/doc_spec_coverage_contract_test.exs
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-01-PLAN.md
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-02-PLAN.md
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-03-PLAN.md
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-04-PLAN.md
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-05-PLAN.md
key-decisions:
  - "Keep the complete human-authored 1.0.0 changelog dated 2026-10-07, with a new unbracketed Unreleased staging heading above it."
  - "Use the local v1.44 tag only for the milestone footer audit; build the isolated squash candidate on a separately fetched GitHub main SHA."
  - "Treat candidate rehearsal and ci.all as local evidence only; no external release action is granted."
patterns-established:
  - "Record release proofs against immutable source, base, and candidate SHAs."
  - "Use task-local caches for isolated release rehearsals and browser verification."
requirements-completed: [REL-01, REL-02]
coverage:
  - id: D1
    description: Exact milestone breaking-footer audit reconciled with the human 1.0 changelog and upgrade guide.
    requirement: REL-02
    verification:
      - kind: other
        ref: "git log 4ae4557ddde83d70eb1781db984cb287dfa18b1b..6227ad959d30b62f08b957ecc50b146ce4fdf62c --grep='BREAKING CHANGE' --format='%H %B'"
        status: pass
    human_judgment: false
  - id: D2
    description: Isolated 1.0.0 candidate has one Release-As footer and passes strict rehearsal followed by full local CI.
    requirement: REL-01
    verification:
      - kind: other
        ref: "THREADLINE_BUMP_REHEARSAL_MODE=candidate mix verify.bump_rehearsal at d7d5ec7666f5042c943cf66e1a76a65fd9bfd66a"
        status: pass
      - kind: integration
        ref: "mix ci.all at d7d5ec7666f5042c943cf66e1a76a65fd9bfd66a"
        status: pass
    human_judgment: false
plan_head_before: e839079c94c4a0752082594f26bfd9c1b2d9e620
plan_head_after: 04a7fac979719d466c7c3f5fae4cae232d4aeeaa
duration: 1h 2m
completed: 2026-10-07
status: complete
---

# Phase 237 Plan 03: Release audit and candidate summary

The complete human 1.0.0 changelog reconciles all 11 matching commits in the exact v1.44-to-source-tip audit. Before the Plan 237-04 grant checkpoint, the isolated candidate was refreshed to current source and canonical main, then passed strict artifact rehearsal and full local CI at `d7d5ec7`.

## Performance

- **Duration:** 1 hour 2 minutes
- **Started:** 2026-10-07T20:35:00Z
- **Completed:** 2026-10-07T21:37:00Z
- **Tasks:** 2 plan tasks completed
- **Files modified:** 12

## Accomplishments

- Dated the complete human-owned 1.0.0 changelog and retained a fresh Unreleased staging heading above it; kept the 0.12 prerequisites in their existing release section.
- Audited the immutable `v1.44` base through source tip `6227ad9`, mapping 11 matching commits and 12 footer consequences to release and guide IDs.
- Built and refreshed a persistent isolated one-squash candidate on fetched canonical `main` `0d6f36f`, retaining its shipped 0.12.0 manifest/generated notes. The current candidate is `d7d5ec7` on `candidate/threadline-1.0.0-final5`.
- Passed the strict 1.0.0 artifact rehearsal and then `mix ci.all` at `d7d5ec7`; the artifact checksum, tree comparison, browser lane, and support pins are recorded in `237-VERIFICATION.md`.

## Task Commits

1. **Task 1: Reconcile changelog and support transition** — `27902915` (docs), `e18c9a9a` (fix)
2. **Task 2: Build and verify isolated candidate** — `1cef0367` (fix), `8321d1aa` (docs), `04a7fac9` (fix)

**Plan metadata:** recorded separately after this summary and phase tracking.

## Decisions Made

- The date `2026-10-07` is the intended human release date for the closed 1.0.0 changelog shape.
- `v1.44` is the correct exclusive range base for the milestone audit; the candidate landing base is the independently fetched GitHub `main` SHA.
- Candidate and local CI success do not authorize push, PR, merge, tagging, live Release Please, or production-Hex publication.

## Deviations from Plan

### Auto-fixed Issues

1. **Release rehearsal exposed the 0.12-to-1.0 upgrade-path contract edge.** The candidate rehearsal first failed because the version truth contract derived an invalid prior version after the package version changed. The contract now derives the previous release minor from the human changelog, and the guide records the `0.12.x -> 1.0.x` transition. Commit: `e18c9a9a`.
2. **Credo found an over-nested routing check in the guide graph contract.** Flattened the check and retained its behavior. Commit: `1cef0367`.
3. **Candidate repo hygiene found concrete home-directory paths in the Phase 237 plans.** Replaced them with the repository's documented portable `<user>` placeholder, then reran hygiene successfully. Commit: `8321d1aa`.
4. **Full CI found guide/changelog contracts that had not followed the dated release shape.** Removed internal and retired API names from adopter-facing prose, registered the new guide in its ownership inventory, and made the hidden-surface contract inspect the dated 1.0.0 section. Focused contracts passed before the candidate rebuild. Commit: `04a7fac9`.

The first sandboxed full-CI attempts also exposed local-only cache and Chromium process permissions. Hex, npm, Playwright browser, and Dialyzer PLT data were isolated under `/private/tmp`; the final full `mix ci.all` run used host process permissions and passed. These environment adjustments did not alter the candidate tree.

## Self-Check: PASSED

- `237-VERIFICATION.md` records the refreshed source tip `6227ad9`, candidate SHA `d7d5ec7`, and successful candidate-bound checks.
- Source commits `27902915`, `e18c9a9a`, `1cef0367`, `8321d1aa`, and `04a7fac9` are ancestors of the plan head.
- The candidate remains available in isolated task-local storage on `candidate/threadline-1.0.0-final5`; its clean HEAD is one `feat!` commit above the freshly fetched main base.
