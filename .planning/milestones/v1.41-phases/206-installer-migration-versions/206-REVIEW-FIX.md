---
phase: 206-installer-migration-versions
fixed_at: 2026-09-24T00:00:00Z
review_path: /Users/jon/projects/threadline/.planning/phases/206-installer-migration-versions/206-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 206: Code Review Fix Report

**Fixed at:** 2026-09-24
**Source review:** .planning/phases/206-installer-migration-versions/206-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (fix_scope: all)
- Fixed: 5 (WR-01 in an earlier `--fix` run, IN-01 to IN-04 in this run)
- Skipped: 0

## Fixed Issues

### WR-01: The CHANGELOG workaround misses a gen.triggers migration that shares a version

**Files modified:** `CHANGELOG.md`
**Commit:** 7a154b8a (earlier `--fix` run, fix_scope critical_warning; not re-applied here)
**Applied fix:** Rewrote the Unreleased "Required action" recovery paragraph. It now
tells the user to rename every Threadline migration that shares the duplicated
version, including any `_threadline_triggers_*.exs` migration. The audit migration
keeps its prefix, and the others get distinct, later timestamps in the order audit,
semantics, governance, triggers. D-05 holds.

### IN-01: Install checks only the top level for existing migrations, but versions are scanned recursively

**Files modified:** `lib/mix/tasks/threadline.install.ex`, `test/mix/tasks/threadline/install_test.exs`
**Commit:** 68b8ec49
**Applied fix:** `existing_migration?/2` now uses
`Path.wildcard(Path.join([path, "**", "*" <> suffix])) != []`. This is recursive,
like Ecto's migrator and `MigrationVersion.existing_versions/1`. The old
`rescue _ -> false` was removed because `Path.wildcard/1` returns `[]` for a
missing directory and does not raise. Added a regression test: an audit migration
seeded under `priv/repo/migrations/archive/` is not written again, and the semantics
and governance migrations get versions `20991231235959` and after. The test's `seed/2`
helper now creates the parent directory of the seeded file so it can seed into a
subdirectory. The new test fails on the old code (10 tests, 1 failure) and passes
with the fix.

### IN-02: gen.triggers writes to a hard-coded path, so the install-then-triggers guarantee only holds for the default repo layout

**Files modified:** `lib/mix/tasks/threadline.gen.triggers.ex`
**Commit:** 28daa013
**Applied fix:** The minimal fix, applied as the orchestrator preferred: the comment
now says the guarantee holds "when both write here". It notes that install resolves
the repo's own migrations path, so with a custom `:priv`, or a repo module not named
`Repo`, install writes to a different directory. gen.triggers still uses the
hard-coded path; making it resolve the path the way install does is left as a
possible follow-up. This change is a comment only.

### IN-03: The CHANGELOG says every install shared a timestamp

**Files modified:** `CHANGELOG.md`
**Commit:** c0b4f4cf
**Applied fix:** The Unreleased highlight now says that since 0.1.0 the installer
computed each migration's version from the current second. As a result, the audit
and semantics migrations shared a version whenever both were written in the same
second, and the governance migration (written since 0.6.0) could share it too. This
matches WR-01's "every Threadline migration that shares the duplicated version". The
hidden module is not named (D-05). Lines are wrapped at 80 columns or fewer.

### IN-04: The partial re-run test has a redundant assertion and does not check the version format

**Files modified:** `test/mix/tasks/threadline/install_test.exs`
**Commit:** f5ab4932
**Applied fix:** Replaced the two `>` assertions with
`assert governance == "21000101000000"` and `assert_valid_increasing!([governance])`.

## Verification

- The edits and commits were made in an isolated worktree
  (`.claude/worktrees/rf-206-22406-*`, temp branch `gsd-reviewfix/206-22406`). Each
  fix was checked there before it was committed. The worktree used the main
  checkout's `deps` through `MIX_DEPS_PATH`, and a copy of `_build` in a throwaway
  `MIX_BUILD_ROOT` under `/tmp`, so the main `_build` was never touched.
- Then `fix/branch-protection-actions-capability` was fast-forwarded to c0b4f4cf.
  The worktree, the temp branch, the recovery sentinel, and the `/tmp` build root
  were removed.
- The final gates ran in the **main checkout** after the fast-forward, so they can be
  reproduced from the current tree:
  - `mix compile --warnings-as-errors` exited 0.
  - `mix format --check-formatted` exited 0.
  - `mix test test/mix/tasks/threadline/install_test.exs test/threadline/mix/migration_version_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/release_distribution_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs` gave 105 tests and 0 failures.
  - This covers the install tests, the migration_version tests, every test that
    runs gen.triggers (`Triggers.run`, which lives in install_test), and every test
    under `test/` that references CHANGELOG.md.

---

_Fixed: 2026-09-24_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
