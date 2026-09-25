---
phase: 204-structure
plan: 02
subsystem: testing
tags: [mix-aliases, ci, contract-test, bump-rehearsal, exunit]

requires:
  - phase: 204-structure
    provides: 204-01 byte lock and size gate (green baseline the de-dup must not disturb)
provides:
  - ci.all with exactly one test-running step (verify.test)
  - Threadline.CiAllDedupContractTest runtime alias-tree guard with a synthetic self-test
  - bin/verify-bump-rehearsal doc-contract set derived by filename, with a 30-file floor
  - public_surface_contract_test retired-alias register (CHANGELOG-only exemption)
affects: [204-03, 204-04, 204-05, 204-06, 204-07, 204-08, 204-09, 204-10, 204-11, 204-12, 204-13, 204-14, 204-15]

actuals:
  tokens: 10356
  tasks: 3
  commits: 3
plan_head_before: f1512b8550a0e58e94f4ec621e43c586a66e6742

tech-stack:
  added: []
  patterns:
    - "Runtime alias-tree expansion: string aliases recurse, `cmd … mix TASK` recurses on TASK, function captures are opaque leaves, cycles raise"
    - "Retired names in guards are assembled by concatenation so a repo-wide grep for the name stays honest"
    - "History registers: a name deleted after release is accepted in CHANGELOG.md only, and the register asserts both halves (gone from code, still in the changelog)"

key-files:
  created:
    - test/threadline/ci_all_dedup_contract_test.exs
  modified:
    - mix.exs
    - .github/workflows/ci.yml
    - .github/workflows/release.yml
    - bin/verify-bump-rehearsal
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/threadline/adoption_pilot_doc_contract_test.exs
    - test/threadline/evaluating_threadline_doc_contract_test.exs
    - test/threadline/ci_coverage_doc_contract_test.exs
    - test/threadline/public_surface_contract_test.exs
    - CONTRIBUTING.md
    - guides/configuration-and-commands.md
    - guides/evaluating-threadline.md
    - guides/adoption-pilot-backlog.md
    - examples/threadline_phoenix/e2e/critic/scorecard.ts

key-decisions:
  - "The dedup guard compares alias names as strings (no String.to_atom), so synthetic self-test trees need no dynamic atoms and Credo's UnsafeToAtom stays quiet"
  - "The deleted alias stays nameable in released CHANGELOG history through a @retired_aliases register in public_surface_contract_test, mirroring the existing @renamed_modules register"
  - "Guide ci.all step lists now end '… → mix verify.example, then Dialyzer and the browser lane', so the list is no longer silently incomplete"

patterns-established:
  - "A deleted public alias goes into @retired_aliases in the same commit that removes it, if CHANGELOG history names it"

requirements-completed: [STRUCT-06]

coverage:
  - id: D1
    description: "ci.all has exactly one test-running step; the retired alias is absent; no alias hand-lists two or more .exs files; ci.all is non-empty and contains verify.test (runtime alias-tree guard)"
    requirement: STRUCT-06
    verification:
      - kind: unit
        ref: "test/threadline/ci_all_dedup_contract_test.exs (14 tests incl. synthetic self-test)"
        status: pass
      - kind: other
        ref: "DB_PORT=5433 MIX_ENV=test mix ci.all (exit 0, 469 s; one library suite run of 1762 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Doc contract tests step is gone from job verify-test and no job id changed"
    requirement: STRUCT-06
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs, test/threadline/ci_workflow_parity_contract_test.exs"
        status: pass
      - kind: other
        ref: "Task 1 ci.yml key-line diff check (run under bash)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Bump rehearsal derives the doc-contract set by filename inside the throwaway clone, refuses to run below 30 files, and is green at the next version"
    requirement: STRUCT-06
    verification:
      - kind: other
        ref: "mix verify.bump_rehearsal (33 files, 265 tests, 0 failures at 0.10.0; tree identity: MATCH; 'Bump rehearsal OK')"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every tracked doc and doc-contract statement about ci.all and the retired alias is true; no tracked file outside CHANGELOG.md and the planning directory names the retired alias"
    requirement: STRUCT-06
    verification:
      - kind: unit
        ref: "33 derived doc-contract files + ci_all_dedup + ci_topology + ci_workflow_parity + public_surface (349 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "git grep -n 'verify.doc_contract' -- . ':!CHANGELOG.md' ':!.planning' → no output (exit 1)"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-09-23
status: complete
---

# Phase 204 Plan 02: ci.all de-duplication Summary

**`ci.all` now runs test files exactly once, through `verify.test`. The hand-listed doc-contract alias is gone (it listed 21 files; 33 exist), and a runtime alias-tree guard keeps it that way. The bump rehearsal now finds its doc-contract files by name: 33 files, all green at 0.10.0.**

## Performance

- **Duration:** about 35 min
- **Started:** 2026-09-23T17:03:59Z
- **Completed:** 2026-09-23T17:39:31Z
- **Tasks:** 3/3
- **Files modified:** 16 (1 created). The gitignored `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` was also edited locally but is not tracked.
- **Plan base:** `f1512b8550a0e58e94f4ec621e43c586a66e6742`

## Accomplishments

- **mix.exs:** deleted the `verify.doc_contract` alias and its preferred env. `verify.critic_trust` and `verify.mechanical` are no longer `ci.all` steps, but both aliases remain, and their comments now say their test files already run in `verify.test`. `ci.all` keeps its order: format, credo, strict compile, xref cycles, no-optional compile, verify.test, verify.threadline, verify.example, Dialyzer, then the browser lane.
- **`Threadline.CiAllDedupContractTest`** (14 tests, async) reads `Threadline.MixProject.project()[:aliases]` at runtime and expands the alias tree. It checks four things: (a) the retired alias is absent; (b) exactly one `ci.all` step, `verify.test`, expands to a `test` command; (c) no alias runs `test` on two or more explicit `.exs` paths; (d) `ci.all` is non-empty and contains `verify.test`. The synthetic self-test confirms it rejects: two test steps (both chains named), a test step hidden behind `cmd env … mix TASK`, a wrong single test step, a multi-path alias, a reappearing retired alias, an empty or missing `ci.all`, and an alias cycle (raises). It also confirms function captures are treated as opaque.
- **ci.yml:** deleted the `Doc contract tests` step from `verify-test` and changed no job id. The rehearsal job comments now describe the derived set.
- **bin/verify-bump-rehearsal:** new `derived_doc_contract_tests` gate, labelled "doc-contract tests (derived by filename) at $NEXT". It builds its list with `find … | sort` and a `while IFS= read -r` loop (no `mapfile`), fails below 30 files with the count in the message, then runs `mix test "${DC_FILES[@]}"`.
- **Local rehearsal:** **33 doc-contract files, 265 tests, 0 failures** at 0.10.0. `verify.release` passed 38 tests. Output included `tree identity: MATCH` and "Bump rehearsal OK" (about 65 s). The 12 files that had drifted out of the alias ran at NEXT for the first time and all passed, so there were **no born-red defects**.
- **Docs:** CONTRIBUTING, the three guides, release.yml, scorecard.ts, and the pinned doc-contract tests now describe the post-change topology accurately.
- **`MIX_ENV=test mix ci.all`:** exit 0 in **469 s**. It ran one library suite (1762 tests, 0 failures, 1 excluded), the example app (117 tests, 0 failures), Dialyzer (0 errors), and the CI-mode browser lane (318 passed, 26 skipped).

## Task Commits

1. **Task 1 (tracer): delete the alias and ci.all re-runs, add the guard, drop the CI step:** `2483ffdf` (refactor)
2. **Task 2: derive the bump-rehearsal set by filename with a 30-file floor:** `2f906d27` (refactor)
3. **Task 3: make every doc and doc-contract statement true:** `7a563e93` (docs)

## Files Created/Modified

- `test/threadline/ci_all_dedup_contract_test.exs`: the runtime alias-tree guard (new)
- `mix.exs`: alias, preferred env, and ci.all changes; comments
- `.github/workflows/ci.yml`: step deleted, comments rewritten
- `.github/workflows/release.yml`: the sync-PR body now says "Merge after CI (`mix verify.test`) is green on this PR."
- `bin/verify-bump-rehearsal`: the derived-list gate and the OK summary line
- `test/threadline/ci_topology_contract_test.exs`, `ci_workflow_parity_contract_test.exs`: removed the alias-content and ordering assertions; added a refute on `"mix " <> @retired_alias` in ci.yml
- `test/threadline/public_surface_contract_test.exs`: `@retired_aliases` register (CHANGELOG-only exemption plus a paired assertion)
- `test/threadline/{adoption_pilot,evaluating_threadline}_doc_contract_test.exs`: now pin `mix verify.test`
- `test/threadline/ci_coverage_doc_contract_test.exs`: moduledoc changed to past tense, without the joined alias name
- `CONTRIBUTING.md`, `guides/configuration-and-commands.md`, `guides/evaluating-threadline.md`, `guides/adoption-pilot-backlog.md`, `examples/threadline_phoenix/e2e/critic/scorecard.ts`: prose

## Decisions Made

- The guard compares names as strings instead of building atoms. This keeps the self-test free of `String.to_atom`, which Credo's `UnsafeToAtom` would flag.
- CHANGELOG history keeps naming the deleted alias (D-25). The public-surface gate gets a `@retired_aliases` register that mirrors `@renamed_modules`: the name is exempt in CHANGELOG.md only, and a paired test fails if the alias comes back or the changelog stops naming it.
- The guides' ci.all chain now ends "…, then Dialyzer and the browser lane" rather than implying the chain stops at `verify.example`. The "nine steps" count became "eight named steps".

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] public_surface_contract_test rejected the retired alias in CHANGELOG history**
- **Found during:** Task 3
- **Issue:** Once the alias was deleted, `PublicSurfaceContractTest` reported `CHANGELOG.md contains unknown public references: aliases: [verify.doc_contract]`. Deleting CHANGELOG history is forbidden (D-25), and the plan did not list this file.
- **Fix:** Added a `@retired_aliases` register. The name is assembled by concatenation, so the repo-wide grep stays honest. The register is accepted for the CHANGELOG subject only, and a test asserts the alias is gone from mix.exs and still named in the changelog.
- **Files modified:** test/threadline/public_surface_contract_test.exs
- **Verification:** public_surface passes (38 tests, 0 failures) and so does the full suite (1762 tests, 0 failures)
- **Committed in:** 7a563e93

**2. [Rule 3 - Blocking] The prompts file is gitignored**
- **Found during:** Task 3
- **Issue:** `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` is gitignored and untracked, so it could not be committed. It is also outside the `git grep` scope.
- **Fix:** Edited it locally so it reads truthfully. I did not force-add it.
- **Committed in:** not committed (ignored path)

**3. [Note] Intermediate commits 2483ffdf and 2f906d27 have a red public_surface_contract_test**
- The guides and CHANGELOG still named the alias until Task 3. The plan orders the doc updates into Task 3, so the gap is intentional. It is closed at 7a563e93, and the whole suite is green there.

**4. [Note] The Task 1 ci.yml key-line check needs bash**
- Under the agent's zsh the pipeline returned 1. Run with `bash -c`, the same command returned 0. The diff contains only the step deletion and comment lines.

---

**Total deviations:** 2 auto-fixed (both blocking), plus 2 notes
**Impact on plan:** None on scope. No contract test was reduced, and no job id changed.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- STRUCT-06 is done. Later plans that add or rename a doc-contract file need no alias edit, because both `mix test` discovery and the rehearsal pick it up by filename.
- If a later plan deletes a public Mix alias that CHANGELOG names, it must add the name to `@retired_aliases` in the same commit.

## Self-Check: PASSED

- `test/threadline/ci_all_dedup_contract_test.exs` exists.
- Commits `2483ffdf`, `2f906d27`, and `7a563e93` exist. `git rev-list --count f1512b85..HEAD` returned 3 before this SUMMARY commit.
- All acceptance criteria were re-run and pass. `grep -c verify.doc_contract` returns 0 for mix.exs and bin/verify-bump-rehearsal. The critic_trust and mechanical alias greps return 1 each. `Doc contract tests` appears 0 times in ci.yml. The concatenation guard appears once in each of the two guard files. `folded into ci.all` appears 0 times in mix.exs. The scorecard.ts phrase appears 0 times. `mix verify.test` appears once in release.yml.

---
*Phase: 204-structure*
*Completed: 2026-09-23*
