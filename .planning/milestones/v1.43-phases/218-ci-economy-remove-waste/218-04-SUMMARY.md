---
phase: 218-ci-economy-remove-waste
plan: 04
subsystem: ci
status: complete
tags: [ci, github-actions, contract-tests, econ-06, roster]
requires: ["218-03"]
provides:
  - "13-job ci-required roster: verify-mechanical, verify-docs and verify-hex-package removed"
  - "verify-capture without the trailing mix verify.mechanical step"
  - "CONTRIBUTING `### Removed CI proofs and what still catches them` (4 still-caught-by bullets)"
  - "topology tests: removed CI proofs stay justified and dominated / dominating proofs for removed jobs stay in force (dominance_errors/2)"
affects: ["218-05", "218-08", "221", "222"]
tech-stack:
  added: []
  patterns:
    - "removal-justification pin: a `# Removed: <id>` comment in ci.yml plus a CONTRIBUTING `still caught by` bullet, both asserted with mutation controls"
    - "dominance pin: the dominating proof's command strings, needs membership, unconditional run and trigger set asserted from source"
key-files:
  created:
    - .planning/phases/218-ci-economy-remove-waste/deferred-items.md
  modified:
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - mix.exs
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
    - guides/upgrade-path.md
    - test/threadline/upgrade_path_doc_contract_test.exs
    - scripts/ci/README.md
decisions:
  - "D-10 re-check: verify-docs DOMINATED by verify-bump-rehearsal; verify-hex-package DOMINATED by verify-bump-rehearsal + verify-hex-evaluator; all on push to main, pull_request to main and workflow_dispatch, no job-level if:"
  - "Removing verify-docs couples the ExDoc proof to verify-bump-rehearsal: a future change-aware skip of that job (Phase 222 / SEED-006) also skips the docs proof"
  - "Parity-test beam-step controls retargeted from verify-docs to verify-credo (single file-fed setup-beam step)"
metrics:
  duration: "~8 min wall (453 s), including one 151 s full-suite run"
  completed: 2026-09-27
actuals:
  tokens: 10061
  tasks: 3
  commits: 4
plan_head_before: ccbb8ae7e957a2bdf515bd16738f897d7e4da7c8
plan_head_after: b87b4b4eb9ef1513b9733399889fc415777f4f06
---

# Phase 218 Plan 04: Remove dominated CI proofs Summary

Three CI jobs (`verify-mechanical`, `verify-docs`, `verify-hex-package`) and `verify-capture`'s trailing `mix verify.mechanical` step are gone. `ci-required` now needs 13 jobs, down from 16. Each removal has a `still caught by` bullet in CONTRIBUTING and a `# Removed:` comment in ci.yml. Contract pins, each with mutation controls, keep the proofs that now catch those failures from lapsing silently.

## D-10 dominance verdicts (re-checked this session)

Trigger set for ci.yml: `push: branches: [main]`, `pull_request: branches: [main]`, `workflow_dispatch`, with no `paths:`. The only job-level `if:` in ci.yml belongs to `ci-required` (`if: always()`). Neither dominator has one.

- `verify-docs`: **DOMINATED by `verify-bump-rehearsal` on push to main, pull_request to main and workflow_dispatch.**
  - The job runs `mix verify.bump_rehearsal`.
  - `bin/verify-bump-rehearsal` runs the `mix verify.release at $NEXT` gate. A failed gate sets `GATE_STATUS=1`, and the script ends with `exit 1`.
  - `verify_release/1` runs `"MIX_ENV=dev mix docs --warnings-as-errors"`. That is stricter than the old job's plain `mix docs`.
  - The docs build is skipped only when an earlier rehearsal gate has already failed the job. That is fail-fast, not a masked pass.
- `verify-hex-package`: **DOMINATED by `verify-bump-rehearsal` and `verify-hex-evaluator` on push to main, pull_request to main and workflow_dispatch.**
  - `verify_release/1` runs `"mix hex.build"`.
  - `mix verify.hex_evaluator` defaults to `System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "rehearsal")`. ci.yml never sets that variable; only release.yml sets it to `published`.
  - `bin/with-rehearsal-registry` runs `mix hex.build` on this tree. The fixture resolves the result from the rehearsal registry, then runs `mix compile --warnings-as-errors` and `mix test`, and those tests alias `Threadline.*` modules. A tarball without a usable `lib/` cannot compile.
  - `release.yml`'s `hex.build` was rejected as a dominator because it runs on release only.
- `verify-mechanical` (D-09, always removed): still caught by `verify-test` in both lanes. `mechanical_checker_test.exs` is `use ExUnit.Case, async: true` with no tag, so it is in the default suite.

## Branch protection (read-only)

`bin/verify-branch-protection` (exit 0):

```
OK: required contexts are exactly [CI required]
Branch protection OK for szTheory/threadline@main: required contexts are exactly [CI required], that name has been emitted 1 time(s) on head 2a75a795ae2f2d33411112a4a4d4efbbc297183f, and no classic protection is stacking.
```

`gh api repos/szTheory/threadline/branches/main/protection/required_status_checks` returned:

```
{"message":"Branch not protected",...,"status":"404"}
```

So there is no classic protection, and no removed job name is a required status check. `.github/rulesets/main.json` is untouched and still requires only `CI required`, which stays byte-exact.

## What was built

- **Task 1 (tracer, 2e92899a)**
  - Removed `verify-capture`'s `Assert mechanical checker clean over real evidence` step and rewrote the header comment.
  - Left a `# Removed:` comment in its place.
  - Fixed two mix.exs comments. The `verify.mechanical` alias is byte-identical.
  - Added the CONTRIBUTING section `### Removed CI proofs and what still catches them` directly after the job table.
  - Added the topology test "removed CI proofs stay justified and dominated". It pins:
    - the byte-stable step exists;
    - no `mix verify.mechanical` runs in `verify-capture`;
    - `mechanical_checker_test.exs` carries no default-excluded tag (read from the `:default_test_excludes` app env, plus the two gate names);
    - the capture bullet is present.
  - Mutation controls: step re-added, byte-stable step deleted, bullet dropped, `@moduletag :pgbouncer_topology` injected.
- **Task 2 (a1984da2 RED, eb292459 GREEN)**
  - Added `dominance_errors/2` and the test "dominating proofs for removed jobs stay in force". It pins:
    - both `verify_release/1` strings;
    - both dominators in `ci-required` `needs:`, not skip-listed, with no job-level `if:`;
    - `verify-bump-rehearsal` runs `mix verify.bump_rehearsal`, and `verify-hex-evaluator` runs `mix verify.hex_evaluator`;
    - the evaluator's rehearsal default, and that ci.yml never sets the mode;
    - the ci.yml trigger set, with no `paths:`.
  - 9 mutation controls: docs dropped, hex.build dropped, default mode changed, each dominator dropped from needs, a job-level `if:` on each dominator, mode forced to published in ci.yml, pull_request trigger dropped.
- **Task 3 (b87b4b4e, one roster commit, 7 files)**
  - Removed the three job blocks, their header roster entries and their `needs:` entries.
  - Changed "sixteen" to "thirteen" (twice).
  - Added `# Removed:` comments where the jobs were.
  - CONTRIBUTING: removed the three ids from the roster list, the job table and the Branch protection list, and added a `CI required`-only sentence. Added three more `still caught by` bullets, including the ExDoc coupling note.
  - Retargeted the topology `verify-docs` assert to `verify-bump-rehearsal`, and extended `removed_proof_errors` with `removed_job_checks/2`. For each id this checks: absent from job keys, header and needs; the `# Removed: <id>` comment is present; a bullet names it. New controls: each bullet dropped, `verify-docs` re-added to needs, a `# Removed:` comment dropped.
  - Parity test: setup-beam literal 14 changed to 11 (recounted: 11 uncommented steps, 10 file-fed plus 1 matrix-fed), and the controls retargeted to `verify-credo`.
  - `guides/upgrade-path.md` and its contract test now name `verify-bump-rehearsal`.
  - `scripts/ci/README.md` now has one `act -j verify-bump-rehearsal` recipe. It says the job needs a Postgres service, which matches the job's real `services:`. The `verify-release-shape` recipe is kept.

## TDD evidence (Task 2)

**RED** (a1984da2): `dominance_errors/2` was a stub returning `[]`. The live assertion passed, and the first mutation control failed:

```
  1) test dominating proofs for removed jobs stay in force (Threadline.CiTopologyContractTest)
     test/threadline/ci_topology_contract_test.exs:919
     ExDoc build dropped from verify.release mutation must make the dominance contract fail
     code: for {control, mutated} <- mix_controls do
21 tests, 1 failure
```

**GREEN** (eb292459): `21 tests, 0 failures`.

`gsd-tools check tdd-red-evidence` returned `INVALID_RED (invalid_record)` because its parser reads TAP and Surefire output, not ExUnit. The raw ExUnit failure above is the RED evidence: the target test failed on its own assertion for the planned behavior.

These pins describe behaviour that already holds (nothing had been removed yet), so the only honest RED is a vacuous helper that its own mutation controls reject.

## Verification run

- `actionlint -shellcheck=`: clean after each task.
- Task 1 verify (topology, parity, mechanical_checker): `71 tests, 0 failures`.
- Task 2 verify: `21 tests, 0 failures`; `bin/verify-branch-protection` exit 0.
- Task 3 verify (parity, topology, release_control_plane, upgrade_path_doc, ci_coverage_doc, critic_iteration_runbook_doc): `74 tests, 0 failures`.
- `mix verify.repo_hygiene`: `3978 tracked text file(s) clean`.
- `mix verify.format` and `mix verify.credo`: clean (`found no issues`).
- Doc-hygiene `git grep -nw` for the removed ids outside `.planning/`, `test/` and `CHANGELOG.md`: rc 0, with zero lines lacking `# Removed:` or `still caught by`.
- Full default `mix test` after the roster commit: `9 properties, 2406 tests, 0 failures, 3 excluded`.
- Acceptance greps:
  - removed job keys: 0;
  - `name: CI required`: 1;
  - `ci-required` `- verify-` entries: 13;
  - `still caught by` in CONTRIBUTING: 4;
  - `act -j verify-(docs|hex-package|mechanical)`: 0;
  - `act -j verify-bump-rehearsal`: 1;
  - Task 1 and Task 3 exact file sets: OK.
- Ordering edge: the roster, `needs:`, CONTRIBUTING list and table diffs are deletions only. Surviving ids keep their order.

## Deviations from Plan

1. **[Plan acceptance pattern] `grep -c '"verify.mechanical":' mix.exs` prints 2, not 1.** The second match is the pre-existing `preferred_envs` entry `"verify.mechanical": :test` (mix.exs line 23), which was there before this plan. The alias line itself is unchanged (the Task 1 exact-alias grep prints 1).
2. **[Rule 2 - doc truth] mix.exs `verify.mechanical` alias comment.** It said "A focused maintainer and CI-job command". With the job gone, it now says the test file runs in `verify.test`, `ci.all` and the verify-test CI job. This is a comment-only change in Task 1's commit; the alias list is byte-identical.
3. **[TDD] Task 2 split into RED and GREEN commits**, per the repo's TDD rule. The plan named one commit. The GREEN commit carries the plan's message, and both commits touch only the test file.
4. **Extra controls beyond the plan's minimum:**
   - `@moduletag` injection into the checker test;
   - a `# Removed:` comment dropped;
   - a removed id re-added to needs;
   - the pull_request trigger dropped;
   - a job-level `if:` on `verify-bump-rehearsal`;
   - evaluator mode forced in ci.yml.
5. **Deferred, not fixed:** CONTRIBUTING `## Branch protection (maintainers)` still lists six per-job checks under "require these checks", next to the new `CI required`-only sentence. Logged in `deferred-items.md`.

## Hand-offs

- **Push/CI confirmation** is the maintainer's call. The first CI run after landing is the first live proof that the 13-job roster goes green and saves the removed jobs' runner time (about 87 s + 75 s + 16 s plus setup). 218-08 should cite that run for ECON-07.
- No GitHub writes were made. The only `gh` calls were read-only GETs (`bin/verify-branch-protection` and the classic-protection GET).
- Phase 222 (SEED-006): any change-aware skip of `verify-bump-rehearsal` now also skips the ExDoc and hex.build proofs.

## Known Stubs

None.

## Threat Flags

None. The change only removes surface. T-218-07 is mitigated by the dominance pins, three-way roster parity, the byte-exact `CI required` and the read-only protection check, with no `allowed-skips`, `paths:` or `continue-on-error` added. T-218-08 is mitigated by the bullets and comments, which are asserted with controls.

## Self-Check: PASSED

- FOUND: every modified file listed in key-files
- FOUND commits: 2e92899a (Task 1), a1984da2 (Task 2 RED), eb292459 (Task 2 GREEN), b87b4b4e (Task 3)
