---
phase: 200-public-surface
plan: 13
subsystem: documentation
tags: [contributors, developer-experience, troubleshooting, docker, capture]
requires:
  - phase: 200-public-surface
    provides: canonical documentation owners, exact guide graph, and public-reference contracts
provides:
  - newcomer-first communication, setup, focused-test, full-gate, and pull-request route
  - exact missing-audit-table symptom, immediate cause, and canonical recovery link
  - repository guidance aligned with the shipped PostgreSQL trigger capture mechanism
affects: [200-14, contributors, release-documentation]
actuals:
  tokens: 3423
  tasks: 2
  commits: 2
plan_head_before: 511d2fca5edf4289bcec31e4ff20fd610c08bbd7
tech-stack:
  added: []
  patterns: [newcomer-first contributor flow, canonical procedure ownership, searchable exact-error routing]
key-files:
  created: []
  modified:
    - CONTRIBUTING.md
    - CLAUDE.md
key-decisions:
  - "Ordinary contributors see the complete issue-to-PR path before specialized test and maintainer reference material."
  - "CONTRIBUTING describes the missing audit table's immediate local-state cause but delegates recovery commands and destructive-volume warnings to Local Docker DX."
  - "Repository guidance treats generated PostgreSQL triggers installed through host-owned Ecto migrations as the shipped capture boundary."
patterns-established:
  - "Newcomer route first: communication, setup, focused tests, the full repository gate, and pull-request submission precede maintainer machinery."
  - "Exact symptom plus descriptive deep link: searchable errors live near the user journey while one canonical guide owns repair procedures."
requirements-completed: [SURFACE-06, SURFACE-08, SURFACE-10]
coverage:
  - id: D1
    description: "A first-time contributor can route, set up, run focused tests and the full gate, and submit a pull request without credentials or planning history."
    requirement: SURFACE-10
    verification:
      - kind: integration
        ref: "test/threadline/community_health_contract_test.exs --only contributor_flow"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_contribute"
        status: pass
      - kind: integration
        ref: "test/threadline/guide_graph_contract_test.exs test/threadline/persona_routing_doc_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact missing-audit-table failure is searchable, explains the local database cause, links to the canonical repair owner, and repository guidance states the shipped capture mechanism."
    requirement: SURFACE-08
    verification:
      - kind: integration
        ref: "test/threadline/community_health_contract_test.exs --only contributor_troubleshooting"
        status: pass
      - kind: integration
        ref: "test/threadline/guide_graph_contract_test.exs"
        status: pass
      - kind: other
        ref: "mix format --check-formatted CONTRIBUTING.md CLAUDE.md"
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 13: Newcomer Contribution and Database Repair Summary

**Contributors now get a credential-free issue-to-PR path and a searchable missing-table diagnosis that leads to the single Docker recovery owner.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-12T11:59:52Z
- **Completed:** 2026-09-12T12:04:52Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Reordered CONTRIBUTING around communication, repository setup, focused tests, `mix ci.all`, and pull-request submission before specialized and maintainer-only material.
- Removed internal planning identifiers and private test-module references from the contributor-facing document while preserving useful advanced reference material.
- Added the exact `(undefined_table) relation "audit_changes" does not exist` symptom, explained the stale or unmigrated local database cause, and linked to Local Docker DX rather than copying its lifecycle procedure.
- Replaced the obsolete capture-mechanism placeholder in CLAUDE.md with the shipped PostgreSQL-trigger and host-migration boundary.

## Task Commits

1. **Task 1: Put the newcomer contribution flow before maintainer machinery** — `d580bdb8` (docs)
2. **Task 2: Make the exact database failure searchable and correct stale capture guidance** — `5b39e4c3` (docs)

## Files Created/Modified

- `CONTRIBUTING.md` — newcomer route, canonical setup links, planning-independent maintainer reference, and exact database troubleshooting entry.
- `CLAUDE.md` — current trigger-backed capture mechanism and migration ownership statement.

## Decisions Made

- Kept focused repository test commands in CONTRIBUTING because they are contributor jobs, while routing Docker lifecycle, ports, cleanup, and stale-volume recovery to Local Docker DX.
- Kept specialized critic, CI-topology, staging, and release information after the ordinary contribution path; these sections are explicitly non-prerequisites.
- Described the missing relation as a local schema/check-out mismatch and kept the canonical lifecycle procedure in the Docker guide so its destructive-reset warning cannot be separated from the commands.

## Deviations from Plan

None - plan execution changed only the two owned documentation files.

## Issues Encountered

- The plan's trailing `-x` argument is unsupported by the pinned Mix 1.17.3 runner. As in prior public-surface plans, the same focused test selections were run without that invalid option; every selection was nonempty and green.
- Repository-wide `mix verify.format` is currently blocked by a pre-existing formatting defect at `lib/threadline/operator_surface/mechanical_checker.ex:729`, introduced by Plan 200-16. This plan did not modify that unrelated file. Both owned files pass `mix format --check-formatted CONTRIBUTING.md CLAUDE.md`, and the repository-wide blocker is recorded in `.planning/WINDOWS.md` for phase closeout.

## Known Stubs

None.

## Threat Flags

None. This plan changes documentation only and adds no endpoint, authorization path, schema, file-access primitive, or runtime trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 200-14 can validate the finished newcomer and archive surfaces without interpreting internal planning history.
- The pre-existing formatter defect in the Plan 200-16 mechanical-checker prose must be corrected before the final repository-wide format gate can pass.

## Self-Check: PASSED

- Both modified files exist, and task commits `d580bdb8` and `5b39e4c3` exist after the persisted `plan_head_before`.
- The measured task-commit count is 2 and the realized diff is 13,690 characters (3,423 estimate-scale tokens).
- Contributor-flow, exact-error, public-reference, exact guide-graph, persona-routing, and owned-file format checks are nonempty and green.
- CONTRIBUTING contains no `.planning/` path, phase number, decision identifier, or requirement identifier.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
