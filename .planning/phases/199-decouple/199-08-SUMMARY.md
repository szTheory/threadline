---
phase: 199-decouple
plan: "08"
subsystem: testing
tags: [fixtures, git-mv, sha256, hex, exunit, evidence]
requires:
  - phase: 199-02
    provides: Central Elixir fixture-root authority
  - phase: 199-03
    provides: Central TypeScript fixture and generated-output authorities
  - phase: 199-05
    provides: Refute readers isolated behind prepared roots
  - phase: 199-06
    provides: Critic measure and synth readers isolated behind prepared roots
  - phase: 199-07
    provides: Synthetic Git-index manifest and corpus integrity oracle
  - phase: 199-10
    provides: Clean-checkout and package-boundary prerequisites
provides:
  - Byte-identical test ownership for all 427 tracked operator-surface evidence entries
  - Live tracked-only SHA-256 manifest with non-vacuous ledger, golden, synthetic, refute, scorecard, and ARIA joins
  - Actual Hex archive inspection proving repository evidence remains private
affects: [199-13, 199-14, operator-surface-evidence, release-contract]
actuals:
  tokens: 61355
  tasks: 2
  commits: 4
plan_head_before: a8f9b83898a2a24afc922da5177ab51be6cd181c
tech-stack:
  added: []
  patterns: [Git-index-derived fixture manifests, suffix-aware live evidence joins, unpacked Hex archive contracts]
key-files:
  created:
    - test/fixtures/operator_surface/manifest.sha256
    - test/fixtures/operator_surface/README.md
  modified:
    - test/support/operator_surface_fixtures.ex
    - examples/threadline_phoenix/e2e/support/operator-surface-paths.ts
    - lib/mix/tasks/critic.measure.ex
    - lib/mix/tasks/critic.synth.ex
    - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
key-decisions:
  - "The immutable evidence root is test/fixtures/operator_surface; generated critic output remains ignored and outside manifest authority."
  - "Live ledger joins accept mechanical-floor base IDs through explicit __variant matching, while veto-ordering intentionally requires only its polished scorecard family."
  - "Hex privacy is proven from an unpacked artifact's real file list rather than inferred solely from mix.exs configuration."
patterns-established:
  - "Corpus migration proof: compare sorted relative path/SHA-256 rows from the Git index before and after literal git mv operations."
  - "Release privacy proof: build and unpack the consumer artifact, assert required shipped files, then reject private repository prefixes."
requirements-completed: [DECOUPLE-01, DECOUPLE-02]
coverage:
  - id: D1
    description: "Exactly 427 tracked evidence entries moved through the five declared roots with unchanged bytes and no tracked originals remaining."
    requirement: DECOUPLE-02
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/operator_surface_fixture_contract_test.exs#live repository corpus matches its tracked manifest and validates non-vacuously"
        status: pass
      - kind: other
        ref: "git diff --name-status -M100% plan_head_before..9de9d968 and manifest SHA-256 comparison"
        status: pass
    human_judgment: false
  - id: D2
    description: "Elixir, TypeScript, CI, and documentation authorities use the test-owned corpus while executable old-path literals are absent."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "116 focused ExUnit tests and npm --prefix examples/threadline_phoenix/e2e run test:paths"
        status: pass
      - kind: other
        ref: "old corpus literal sweep excluding byte-preserved immutable evidence payloads"
        status: pass
    human_judgment: false
  - id: D3
    description: "The actual 138-entry Hex artifact retains shipped library code and excludes both test fixtures and planning data."
    requirement: DECOUPLE-02
    verification:
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs#built Hex archive excludes repository evidence"
        status: pass
      - kind: other
        ref: "mix hex.build plus contents.tar.gz entry inspection"
        status: pass
    human_judgment: false
duration: 20 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 08: Operator Evidence Corpus Migration Summary

**All 427 tracked operator-surface evidence entries now live byte-identically under test ownership, with coherent readers and an actual-package exclusion gate.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-09-11T15:08:31Z
- **Completed:** 2026-09-11T15:28:00Z
- **Tasks:** 2
- **Files modified:** 446

## Accomplishments

- Performed the five literal `git mv` operations and proved 427 `R100` renames against a 427-row pre/post Git-index manifest with digest `a9001204c850d15d4a3fe78534bc460284e30c85206e4810277ce537f2ca5967`.
- Flipped every prepared Elixir and TypeScript authority plus direct CI/documentation consumers in the same commit; 116 focused ExUnit tests and 11 Node path tests pass.
- Bound the synthetic integrity oracle to the live corpus, including non-empty mechanical, synthetic, refute, scorecard, and ARIA relationships without hardcoding the live count.
- Built and inspected the actual 138-entry Hex package, proving it includes `lib/threadline.ex` and excludes both `.planning/` and `test/fixtures/`.

## Task Commits

Each task followed its own RED → GREEN cycle:

1. **Task 1 RED: failing live corpus manifest contract** — `7682afed` (`test`)
2. **Task 1 GREEN: atomic corpus move and authority flip** — `9de9d968` (`feat`)
3. **Task 2 RED: failing actual Hex archive contract** — `b4b0273b` (`test`)
4. **Task 2 GREEN: unpacked archive inspection** — `2ee77479` (`feat`)

No refactor commit was needed; both GREEN implementations remained narrow and cohesive.

## Files Created/Modified

- `test/fixtures/operator_surface/` — test-owned ledger, scorecards, golden sets, refute set, critic-score skeleton, deterministic manifest, and ownership guidance.
- `test/support/operator_surface_fixtures.ex` — canonical Elixir fixture root.
- `examples/threadline_phoenix/e2e/support/operator-surface-paths.ts` — canonical TypeScript fixture root.
- `lib/mix/tasks/critic.measure.ex` and `lib/mix/tasks/critic.synth.ex` — test-owned evidence defaults and separated generated-output default.
- `.github/workflows/ci.yml`, `CONTRIBUTING.md`, and `DESIGN-SYSTEM.md` — coherent automation and operator guidance.
- `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs` — live manifest, structure, and cross-reference enforcement.
- `test/threadline/release_artifact_contract_test.exs` — actual unpacked Hex archive privacy contract.

## Decisions Made

- Kept the manifest strictly Git-index-derived. The tracked critic-score skeleton participates, but ignored generated scores cannot change manifest bytes.
- Treated an empty human golden queue as valid while requiring the synthetic set, mechanical floor set, refute set, and scorecard set to be non-empty.
- Resolved ledger base IDs through `__variant` scorecard families and modeled the veto-ordering refute class without inventing a flawed artifact that intentionally does not exist.
- Verified package privacy from real built contents while preserving the existing explicit package allowlist.

## TDD Gate Compliance

- **Task 1 RED:** `RED_EVIDENCE_OK`; the named live contract failed because the destination contained no tracked evidence before migration.
- **Task 1 GREEN:** 108 focused Elixir tests and 11 Node path tests passed; the automated tracer feedback gate reran both suites successfully before Task 2.
- **Task 2 RED:** `RED_EVIDENCE_OK`; the named archive contract failed on an intentionally empty pre-implementation entry list.
- **Task 2 GREEN:** the named archive test passed, then 13 combined fixture/release tests and `mix hex.build` passed.
- **Final order:** `test → feat → test → feat`, verified from Git history.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created the exact destination parent for the critic-score skeleton**

- **Found during:** Task 1 corpus move
- **Issue:** The fifth literal `git mv` found `test/fixtures/operator_surface/critic-scores/` absent after the four directory moves.
- **Fix:** Created only that destination directory and reran the unchanged fifth literal move.
- **Files modified:** `test/fixtures/operator_surface/critic-scores/.gitkeep`
- **Verification:** The final diff recognizes the skeleton and all other evidence as part of exactly 427 `R100` renames.
- **Committed in:** `9de9d968`

**2. [Rule 1 - Bug] Matched the live corpus's established schemas without weakening non-vacuity**

- **Found during:** Task 1 GREEN verification
- **Issue:** The synthetic validator expected `required_scorecards`, a non-empty human golden queue, exact scorecard IDs, and two artifacts for every refute class; the live ledger instead uses `mechanical_floors`, the human queue is intentionally empty, scorecards use `__variant` suffixes, and veto-ordering intentionally lacks a flawed artifact.
- **Fix:** Required a non-empty synthetic set, sourced ledger references from mechanical floors, matched explicit variant families, and applied the documented veto-ordering exception.
- **Files modified:** `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs`
- **Verification:** The live contract and all 116 focused tests pass with non-vacuous joins.
- **Committed in:** `9de9d968`

**3. [Rule 3 - Blocking] Replaced the unsupported `mix test -x` option**

- **Found during:** Task 1 verification
- **Issue:** Installed Mix rejects the plan's trailing `-x` as an unknown option before discovering tests.
- **Fix:** Used the supported `--max-failures 1` fail-fast option for targeted RED/GREEN and final verification runs.
- **Files modified:** None; execution-command correction only.
- **Verification:** Final focused run executed 116 tests with zero failures.
- **Committed in:** No source change required.

**4. [Rule 1 - Bug] Restored pre-existing untracked outputs after directory moves**

- **Found during:** Task 1 pre-commit preservation audit
- **Issue:** Directory-level `git mv` correctly moved tracked entries but also relocated pre-existing untracked refute transcripts and six ignored scorecards in the working tree.
- **Fix:** Moved those exact untracked artifacts back to their original `.planning/refute/` and `.planning/scorecards/` paths before committing; none entered the immutable corpus or Git index.
- **Files modified:** No tracked files; user/runtime outputs were restored byte-for-byte to their original locations.
- **Verification:** Destination status contains no unexpected untracked evidence, and the original untracked paths remain present.
- **Committed in:** No commit; preservation correction only.

---

**Total deviations:** 4 auto-fixed (2 blocking execution corrections, 2 correctness fixes).
**Impact on plan:** All fixes preserved the declared five-move topology, byte identity, non-vacuous validation, and user-owned runtime artifacts without expanding product scope.

## Issues Encountered

- The repository-local untracked `.tool-versions` does not select Elixir/OTP, so verification used the already-installed `ASDF_ELIXIR_VERSION=1.19.5-otp-27` and `ASDF_ERLANG_VERSION=27.3.4.15` without modifying the user-owned file.
- Immutable scorecard payloads retain historical `.planning/scorecards/...` provenance strings by the explicit byte-preservation requirement. The executable/configuration sweep excludes those payload bytes and reports no live old-path reader.

## Known Stubs

None. Stub-pattern hits in touched reader files are existing collection initializers, validation comparisons, and documented hash-test placeholders; no shipped path receives empty or mock evidence.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 199-13 and 199-14 can now verify documentation/closure and final dependency-boundary independence against the test-owned corpus.
- No corpus, reader, package, test, or user-setup blocker remains.

## Self-Check: PASSED

- Summary, ownership README, and tracked manifest exist.
- All four RED/GREEN task commits exist and the persisted plan ledger measures four production commits.
- Git reports exactly 427 byte-identical renames and zero tracked entries beneath the five original corpus roots.
- Final focused verification passes with 116 ExUnit tests, 11 Node path tests, and a 138-entry evidence-free Hex archive.
- No goal-blocking stub, skipped test, unrun verification, or unmodeled threat surface remains.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
