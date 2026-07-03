---
phase: 192-ci-cd-measurement-and-efficiency-hardening
plan: 03
subsystem: infra
tags: [github-actions, release, concurrency, hex, docs, compatibility, elixir, otp, postgresql]

# Dependency graph
requires:
  - phase: 192-ci-cd-measurement-and-efficiency-hardening
    provides: "Plan 01 ci.yml matrix + header job-key contract (10 keys), Plan 02 pgbouncer topology pin"
provides:
  - "release.yml publish-race serialization scoped to the publish-hex job (D-24) — release-please bookkeeping stays independent"
  - "CONTRIBUTING two-list repair: List 1 job-key table reconciled to all 10 ci.yml keys; List 2 branch-protection checks renamed to the verify-test matrix lanes"
  - "Explicit min/current version support contract (Elixir 1.15 floor / 1.17.3 current, OTP 26 min / 27 current, PostgreSQL 14 min / 16 current) in README + mix.exs comment, without raising the Elixir floor"
affects: [192-04, release, branch-protection, doc-contract-tests]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Job-level GitHub Actions concurrency (group release-publish-${{ github.ref }}) to serialize a single job without serializing the whole workflow"
    - "Compatibility floor honored by a CI min lane, documented as a promise in README + mix.exs comment, never by raising the requirement string"

key-files:
  created:
    - ".planning/phases/192-ci-cd-measurement-and-efficiency-hardening/192-03-SUMMARY.md"
  modified:
    - ".github/workflows/release.yml"
    - "CONTRIBUTING.md"
    - "README.md"
    - "mix.exs"

key-decisions:
  - "Removed the workflow-level run_id-embedding concurrency group (effective no-op) rather than leaving it, so it cannot be mistaken for real serialization; scoped serialization to publish-hex (D-24)"
  - "Added verify-hex-evaluator and verify-example-browser to List 1 in ci.yml header order (between verify-pgbouncer-topology and verify-docs) to match the authoritative 10-key contract"
  - "mix.exs elixir requirement string kept at ~> 1.15; contract expressed as a comment only (D-14)"

patterns-established:
  - "Doc/pipeline parity: List 1 mirrors the ci.yml header contract exactly; List 2 remains an intentional branch-protection subset"

requirements-completed: [CI-03, CI-04]

coverage:
  - id: D1
    description: "release.yml serializes only the publish-hex job via job-level concurrency (group release-publish-${{ github.ref }}, cancel-in-progress: false); no github.run_id; workflow-level group removed so release-please bookkeeping stays independent"
    requirement: "CI-03"
    verification:
      - kind: automated_ui
        ref: "grep 'group: release-publish-${{ github.ref }}' .github/workflows/release.yml (present under publish-hex); no run_id in the publish group"
        status: pass
      - kind: automated_ui
        ref: "Plan 04 contract test asserts publish concurrency is free of run_id (durable lock)"
        status: unknown
    human_judgment: false
  - id: D2
    description: "CONTRIBUTING List 1 lists all 10 ci.yml job keys; List 2 branch-protection checks renamed to 'Run test suite (min)' / 'Run test suite (current)' and remains a subset"
    requirement: "CI-03"
    verification:
      - kind: automated_ui
        ref: "grep verify-hex-evaluator / verify-example-browser / 'Run test suite (min)' / 'Run test suite (current)' in CONTRIBUTING.md; List 2 subset check confirms no leak of the extra keys"
        status: pass
    human_judgment: false
  - id: D3
    description: "README and a mix.exs comment state the explicit Elixir/OTP/PostgreSQL min/current support contract without raising elixir: ~> 1.15"
    requirement: "CI-04"
    verification:
      - kind: automated_ui
        ref: "grep 'Supported versions' README.md; awk confirms a comment sits directly above unchanged elixir: \"~> 1.15\" in mix.exs; git diff shows the requirement string unmodified"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-07-02
status: complete
---

# Phase 192 Plan 03: Release Concurrency & Doc/Version Alignment Summary

**Publish-job-scoped release concurrency (D-24), CONTRIBUTING two-list repair (List 1 8→10 job keys, List 2 verify-test matrix rename), and an explicit Elixir 1.15-floor/1.17.3-current support contract in README + mix.exs — floor unchanged.**

## Performance

- **Duration:** ~8 min
- **Completed:** 2026-07-02T21:22:14Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Scoped release publish-race serialization to the `publish-hex` job (`group: release-publish-${{ github.ref }}`, `cancel-in-progress: false`) and removed the workflow-level `run_id`-embedding no-op group, so the frequent release-please bookkeeping job never queues behind a long publish.
- Reconciled CONTRIBUTING List 1 (Stable job keys) to all 10 ci.yml job keys by adding `verify-hex-evaluator` and `verify-example-browser` in header order; renamed List 2 branch-protection check `Run test suite (verify-test)` to the two matrix names `Run test suite (min)` / `Run test suite (current)` while keeping List 2 an intentional subset.
- Made the version support contract explicit — README "Supported versions" line and a mix.exs comment (Elixir 1.15 floor / 1.17.3 current, OTP 26 min / 27 current, PostgreSQL 14 min / 16 current) — without touching the `elixir: "~> 1.15"` requirement string (D-14 honored).

## Task Commits

1. **Task 1: Scope release.yml concurrency to the publish job** - `d1b29c53` (fix)
2. **Task 2: Repair CONTRIBUTING two lists (List 1 8→10, List 2 verify-test rename)** - `5c5d4de7` (docs)
3. **Task 3: Make the compatibility contract explicit in README and mix.exs** - `5ca1ae19` (docs)

## Files Created/Modified
- `.github/workflows/release.yml` - Removed workflow-level no-op concurrency group; added job-level concurrency to `publish-hex`.
- `CONTRIBUTING.md` - List 1 job-key table 8→10; List 2 branch-protection rename to the matrix lanes.
- `README.md` - Added explicit "Supported versions" min/current contract line near the CI badge.
- `mix.exs` - Added a support-contract comment directly above the unchanged `elixir: "~> 1.15"`.

## Decisions Made
- Removed (rather than retained) the workflow-level `release-${{ github.event_name }}-${{ github.run_id }}` group. It was an effective no-op, and leaving it would invite the false belief that serialization already existed. Serialization now lives solely on `publish-hex`.
- Inserted the two new List 1 rows between `verify-pgbouncer-topology` and `verify-docs` to preserve the ci.yml header ordering, keeping the table a faithful mirror of the authoritative contract comment.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. (The GitHub branch-protection required-check *rename* to `Run test suite (min)` / `Run test suite (current)` is the human reconfiguration step owned by Plan 04 / D-19; this plan only documents the new names.)

## Next Phase Readiness
- Plan 04's contract test can now lock: publish concurrency free of `run_id`, List 1 ↔ ci.yml job-key parity, and the List 2 matrix check names.
- No blockers.

## Self-Check: PASSED

All modified files present; all three task commits (`d1b29c53`, `5c5d4de7`, `5ca1ae19`) present in git history.

---
*Phase: 192-ci-cd-measurement-and-efficiency-hardening*
*Completed: 2026-07-02*
