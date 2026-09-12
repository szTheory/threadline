---
phase: 200-public-surface
plan: 01
subsystem: testing
tags: [exunit, exdoc, hex, markdown, github-community, public-api]
requires:
  - phase: 199-decouple
    provides: planning-independent verification patterns and Hex artifact boundary
provides:
  - source-derived public configuration, command, module, and documentation inventories
  - unpacked-Hex vocabulary scanner with positive controls and exact source-owner slices
  - 18-node guide graph and GitHub community-health contract boundaries
  - isolated regression for storage adapters that omit optional path/1
affects: [200-02, 200-03, 200-04, 200-05, 200-06, 200-07, 200-08, 200-09, 200-10, 200-11, 200-12, 200-13, 200-14, 200-15, 200-16, 200-17, 200-18]
actuals:
  tokens: 12834
  tasks: 3
  commits: 4
plan_head_before: bf9f6884120e8d2d7f25275932fd608681e3c734
tech-stack:
  added: []
  patterns: [source-derived exact inventories, bounded owner tags, shared negative fixtures, intentional red contracts]
key-files:
  created:
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/guide_graph_contract_test.exs
    - test/threadline/community_health_contract_test.exs
  modified:
    - test/threadline/release_artifact_contract_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
key-decisions:
  - "Public-surface gates derive their inventories from AST, compiled docs, Mix configuration, and the unpacked Hex artifact; explicit classifications must be exact, disjoint, and non-vacuous."
  - "Later Phase 200 work owns bounded red tags; aggregate public-document and archive scans remain deferred until every owner is green."
  - "The optional path/1 regression converts the current UndefinedFunctionError into an assertion value so RED proves the intended behavior gap rather than a fixture crash."
patterns-established:
  - "Bounded owner projection: every later plan receives a named nonempty tag that reuses the aggregate extractor or scanner."
  - "Planning independence: test fixtures and banned-shape definitions live in tracked test source and no runtime helper reads .planning/."
requirements-completed: [SURFACE-01, SURFACE-02, SURFACE-03, SURFACE-04, SURFACE-05, SURFACE-06, SURFACE-07, SURFACE-08, SURFACE-09, SURFACE-10, SURFACE-11]
coverage:
  - id: D1
    description: Source and unpacked-archive contracts expose exact public inventories with non-vacuity and injected-offender controls.
    requirement: SURFACE-01
    verification:
      - kind: integration
        ref: "mix test public_surface_contract_test.exs release_artifact_contract_test.exs --exclude phase200_red --exclude phase200_aggregate"
        status: pass
    human_judgment: false
  - id: D2
    description: Guide graph and community-health contracts provide shared negative fixtures plus scoped live red boundaries.
    requirement: SURFACE-06
    verification:
      - kind: unit
        ref: "mix test guide_graph_contract_test.exs community_health_contract_test.exs --exclude phase200_red"
        status: pass
    human_judgment: false
  - id: D3
    description: A conforming storage adapter without optional path/1 has a precise failing delivery regression while the existing controller suite remains green.
    requirement: SURFACE-07
    verification:
      - kind: integration
        ref: "export_controller_test.exs --only phase200_red (expected assertion failure names UndefinedFunctionError path/1); --exclude phase200_red passes 24 tests"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 01: Public-Surface Contract Baseline Summary

**Source-derived ExDoc, Hex archive, guide graph, community intake, and optional-storage-callback contracts now provide the executable red baseline for the public-surface phase.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-12T07:00:10Z
- **Completed:** 2026-09-12T07:12:02Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added AST-backed runtime-key and Mix-task discovery, compiled-doc visibility checks, exact six-group coverage, and bounded public-document reference owners.
- Extended the real unpacked-Hex harness to retain sorted entries plus readable UTF-8 content and detect phase, decision, requirement, and milestone vocabulary with positive controls.
- Added exact 18-node guide assignment, shared path/anchor resolution, canonical-procedure ownership, and safe GitHub community-health contracts.
- Captured the optional `path/1` contradiction with a behavior-conforming adapter and an assertion-level RED regression.

## Task Commits

1. **Task 1: Trace source facts through docs grouping and the built archive** — `b967e8d6`
2. **Task 2: Define guide-graph and community-health red contracts** — `6b338d08`
3. **Task 3: Lock the optional-storage-callback regression red** — `98758884`
4. **Task 1 follow-up: Bind module owners to exact cohorts** — `a44f7ff2`

## Files Created/Modified

- `test/threadline/public_surface_contract_test.exs` — source, compiled-doc, configuration, command, and public-reference contracts.
- `test/threadline/release_artifact_contract_test.exs` — readable unpacked artifact traversal and zero-allowlist vocabulary projections.
- `test/threadline/guide_graph_contract_test.exs` — intent lanes, Markdown path/anchor resolution, edges, and procedure ownership.
- `test/threadline/community_health_contract_test.exs` — issue-form, contributor, security, PR, and conduct intake boundaries.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` — no-`path/1` adapter and isolated RED delivery regression.

## Decisions Made

- Kept every later-plan failure behind its named `:phase200_red` owner tag and reserved `:phase200_aggregate` for the final full-corpus gates.
- Treated namespace-style references such as `Threadline.Integrations.*` as valid only when they are parents of real compiled modules; arbitrary nonexistent modules still fail.
- Kept binary skipping content-derived through `String.valid?/1`; no packaged path receives a scanner exemption.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Contract bug] Replaced representative visibility owners with exact plan-owned module cohorts**

- **Found during:** Final contract review after Task 3
- **Issue:** The first Task 1 implementation proved owner tags were nonempty but several tags selected only a representative module instead of their complete bounded cohort.
- **Fix:** Bound all seven visibility and public-reference tags to the exact modules owned by Plans 200-05 through 200-08.
- **Files modified:** `test/threadline/public_surface_contract_test.exs`
- **Verification:** Wave-0 public/archive command passes with 53 tests, 0 failures, 40 scoped exclusions.
- **Committed in:** `a44f7ff2`

**Total deviations:** 1 auto-fixed (Rule 1)

**Impact on plan:** The fix strengthened downstream ownership precision without changing runtime behavior or scope.

## Issues Encountered

- The plan's trailing `-x` is not a supported option in the pinned Mix 1.17.3 task runner (`-x : Unknown option`). Every specified selection was run with identical paths/tags and fail-fast shell behavior after removing only that unsupported flag.
- The repository's untracked `.tool-versions` is unrelated user state, so all verification commands used the plan's explicit ASDF Erlang/Elixir pins.

## TDD RED Evidence

- Target: `delivers remotely when a conforming storage adapter omits optional path/1`.
- Expected: a 302 response with the adapter's `download_url/2` location.
- Actual: the assertion received `{:missing_optional_callback, %UndefinedFunctionError{function: :path, arity: 1}}`.
- The existing controller suite remains green with the new test excluded: 24 tests, 0 failures, 1 intentional exclusion.
- GREEN is intentionally owned by Plan 200-03; this plan changes no runtime implementation.

## Issues Deferred by Design

- The scoped red tags identify current missing documentation, module visibility, guide links, community files, source vocabulary, and callback handling. Plans 200-02 through 200-18 own those closures.
- Full `:public_doc_references`, `:source_module_vocabulary`, and `:archive_vocabulary` remain final-only gates.

## User Setup Required

None.

## Next Phase Readiness

- Plan 200-02 can make the runtime-key and command reference tags green against the canonical configuration guide.
- Plan 200-03 has an isolated regression for the optional callback repair.
- Every later visibility, guide, contributor, source-vocabulary, and community plan has an explicit bounded owner tag.

## Self-Check: PASSED

- All five created/modified test files exist.
- All four task/follow-up commits exist in history.
- Wave-0 contracts pass: 67 tests, 0 failures, 51 scoped exclusions.
- Existing export-controller behavior passes: 24 tests, 0 failures, 1 intentional exclusion.
- Format, `git diff --check`, and planning-runtime-read scans pass.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
