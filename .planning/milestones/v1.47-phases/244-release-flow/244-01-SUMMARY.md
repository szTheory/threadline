---
phase: 244-release-flow
plan: 01
subsystem: release
tags: [release-please, changelog, github-actions, bash, perl]
status: complete

requires: []
provides:
  - "bin/date-release-changelog: Unreleased -> [X.Y.Z] - DATE rename with re-seed (--root/--date/--check)"
  - "sync-release-pr-pins step that dates the CHANGELOG and stages it"
  - "release-please-config.json always-update: true"
  - "changelog_dating_errors/1 and regenerate_errors/2 contracts with mutation controls"
affects: [244-02, 244-07, release-flow, CONTRIBUTING release docs]

actuals:
  tokens: 8100
  tasks: 2
  commits: 5
plan_head_before: cefab76b056bec1d3167473b590a5986330e5fd7
plan_head_after: 7b60aab8954b62885571ef656bb5fa783406ddc1

tech-stack:
  added: []
  patterns:
    - "perl -CSD with the em dash written as \\x{2014} (no -Mutf8); values via $ENV{} only"
    - "temp copy beside the file, post-write self-check, then mv"

key-files:
  created:
    - bin/date-release-changelog
    - test/threadline/date_release_changelog_test.exs
  modified:
    - .github/workflows/release.yml
    - release-please-config.json
    - test/threadline/release_control_plane_contract_test.exs
    - test/partition_weights.txt

key-decisions:
  - "date-release-changelog writes the em dash as \\x{2014} under perl -CSD rather than -Mutf8"
  - "A placeholder-only Unreleased block with the [VER] heading already present is a no-op (exit 0); with prose AND the dated heading it refuses (exit 1)"
  - "Sync push step stages README.md guides/ CHANGELOG.md; commit subject is chore(release): sync install pins and date the changelog"

requirements-completed: [REL-01, REL-02]

coverage:
  - id: D1
    description: "bin/date-release-changelog renames and re-seeds the Unreleased block; output passes bin/verify-release-shape"
    requirement: REL-01
    verification:
      - kind: unit
        ref: "test/threadline/date_release_changelog_test.exs (21 tests)"
        status: pass
  - id: D2
    description: "sync-release-pr-pins runs the date step after mix release.pins --check, tokenless, and stages CHANGELOG.md"
    requirement: REL-01
    verification:
      - kind: unit
        ref: "test/threadline/release_control_plane_contract_test.exs#the sync job dates the CHANGELOG before it commits (REL-01) + rule=date-* controls"
        status: pass
  - id: D3
    description: "always-update: true; PAT token and prs_created gate pinned"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "test/threadline/release_control_plane_contract_test.exs#release-please regenerates the open release PR with the PAT (REL-02) + rule=always-update/pat-token/sync-on-prs-created controls"
        status: pass
      - kind: other
        ref: "observed always-update refresh run (assumption A1) — plan 244-07"
        status: unknown

duration: 25min
completed: 2026-10-25
---

# Phase 244 Plan 01: Release branch dates its own CHANGELOG Summary

The release branch now dates its own CHANGELOG. `bin/date-release-changelog` (bash plus a `perl -CSD` rewrite) turns the landing PR's `## Unreleased — highlights` prose into `## [X.Y.Z] - DATE`, taking the date from release-please's generated heading, and re-seeds the standing block above it. `sync-release-pr-pins` runs the script and stages CHANGELOG.md. A top-level `"always-update": true` makes release-please regenerate the stale release PR with the PAT. Contract rules with mutation controls keep all of this in place.

## Accomplishments

- **Script** `bin/date-release-changelog` (mode 100755, shellcheck clean). Flags `--root`, `--date`, `--check`. Exit codes: 0 dated or nothing to do, 1 refused, 2 usage or validation error. Date precedence is `--date`, then the first `## [VER](...) (DATE)` heading in CHANGELOG-GENERATED.md, then UTC today. Version and date are checked against regexes and reach perl only through `$ENV{}` (T-244-01). The rewrite goes to a temp copy and is moved into place only after a self-check passes.
- **Workflow:** the new step `Date the CHANGELOG from the Unreleased block` runs `bin/date-release-changelog` right after `mix release.pins --check`. It has no env and no token. The push step stages `README.md guides/ CHANGELOG.md`, with a new commit subject. The `run: mix release.pins` line, the `PUSH_TOKEN` binding (still 1), the `if:` and the concurrency block are byte-identical.
- **Config:** `"always-update": true` sits directly after `"release-type"`. CHANGELOG.md is still not named.
- **Contracts:** `changelog_dating_errors/1` has rules `date-step`, `date-order`, `date-staged` and `date-no-token`. `regenerate_errors/2` has rules `always-update` (also covers the false, removed and string `"true"` cases), `pat-token` and `sync-on-prs-created`. Each rule has a mutation control, and there is a not-vacuous test.

## Task Commits

1. Task 1 RED: `74d631a5` test(244-01): add failing tests for release-branch changelog dating
2. Task 1 GREEN: `50d08552` feat(244-01): date the CHANGELOG on the release branch
3. Task 2 RED: `f7e0c4a8` test(244-01): add failing REL-02 regeneration contract
4. Task 2 GREEN: `38b6c318` feat(244-01): regenerate the stale release PR with always-update
5. Refactor: `7b60aab8` refactor(244-01): split changelog_dating_errors under credo complexity

## TDD Gate Compliance

- Task 1: RED `74d631a5` had 27 failures, from the missing script (`:enoent`) and the missing workflow step. GREEN `50d08552` brought them to 0.
- Task 2: RED `f7e0c4a8` had 4 failures, all from the missing `always-update` key. The pat-token and prs_created controls already passed against the live tree, as expected. GREEN `38b6c318` brought them to 0.
- Tracer gate: auto mode. The `<verify>` was re-run end to end and passed before Task 2 started.

## Verification

- The plan's verification set (date_release_changelog, release_control_plane, changelog, version_truth, upgrading_to_1_0, upgrade_path, ci_workflow_parity, ci_topology, ci_token_permissions): 169 tests, 0 failures.
- `mix verify.format` and `mix verify.credo` are clean (credo was clean after the refactor commit).
- `bin/verify-temp-leaks test/threadline/date_release_changelog_test.exs`: 21 tests, 0 leaks. The tests use `@moduletag :tmp_dir`.
- Manual check: on a copy of the live CHANGELOG with prose injected, the output read correctly and a second run was a no-op. `bin/date-release-changelog --check` on the live tree (1.1.0, already dated) exits 0.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Partition weight row for the new test file**
- **Found during:** Task 1
- **Issue:** `ci_topology_contract_test.exs` requires a weight in `test/partition_weights.txt` for every test file.
- **Fix:** Hand-inserted the row `800 test/threadline/date_release_changelog_test.exs` (measured at about 0.8s) in sorted position, without regenerating the whole file.
- **Commit:** `50d08552`

**2. [Rule 1 - Quality gate] Credo cyclomatic complexity in changelog_dating_errors/1**
- **Fix:** Extracted an `in_order?/2` helper. Behaviour is unchanged and the mutation controls still pass.
- **Commit:** `7b60aab8`

**3. Test files use `@moduletag :tmp_dir` instead of a System.tmp_dir! tmp_root** (HYG-03 temp-leak convention). The intent of the plan is unchanged.

**4. The push step's no-op echo** now reads "Install pins and CHANGELOG already match @version — nothing to push." No test pins this text.

## Deferred Issues

- `bin/verify-repo-hygiene` flags a pre-existing home-relative path in `244-RESEARCH.md:129`. It is out of scope and logged in `deferred-items.md`. It will turn local `mix ci.all` red until it is rewritten.

## Known Stubs

None.

## Self-Check: PASSED
