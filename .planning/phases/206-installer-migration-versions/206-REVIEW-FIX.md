---
phase: 206-installer-migration-versions
fixed_at: 2026-09-24T00:00:00Z
review_path: /Users/jon/projects/threadline/.planning/phases/206-installer-migration-versions/206-REVIEW.md
iteration: 1
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 206: Code Review Fix Report

**Fixed at:** 2026-09-24
**Source review:** .planning/phases/206-installer-migration-versions/206-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 1 (fix_scope: critical_warning)
- Fixed: 1
- Skipped: 0 in scope (IN-01..IN-04 out of scope, listed below)

## Fixed Issues

### WR-01: The CHANGELOG workaround misses a gen.triggers migration that shares a version

**Files modified:** `CHANGELOG.md`
**Commit:** 7a154b8a
**Applied fix:** Rewrote the Unreleased "Required action" recovery paragraph. It now
tells the user to rename every Threadline migration that shares the duplicated
version, including any `_threadline_triggers_*.exs` migration from
`mix threadline.gen.triggers`. It says to keep the audit migration's prefix and give
the others distinct, later timestamps in the order audit, semantics, governance,
triggers, and notes that the triggers migration must run after the audit migration.
D-05 holds: the hidden migration-version module is not named in the CHANGELOG. The
paragraph is wrapped at 80 columns.

## Skipped Issues

### IN-01: Install checks only the top level for existing migrations, but versions are scanned recursively

**File:** `lib/mix/tasks/threadline.install.ex:175-181`
**Reason:** Out of scope (fix_scope: critical_warning; Info finding).
**Original issue:** `existing_migration?/2` uses `File.ls!` (top level only), but version scanning is recursive.

### IN-02: gen.triggers writes to a hard-coded path, so the install-then-triggers guarantee only holds for the default repo layout

**File:** `lib/mix/tasks/threadline.gen.triggers.ex:131-136`
**Reason:** Out of scope (fix_scope: critical_warning; Info finding).
**Original issue:** The comment overstates the guarantee when install and gen.triggers resolve different migration directories.

### IN-03: The CHANGELOG says every install shared a timestamp

**File:** `CHANGELOG.md:29-31`
**Reason:** Out of scope (fix_scope: critical_warning; Info finding).
**Original issue:** The wording implies every install produced duplicates; they only happened when writes fell in the same second.

### IN-04: The partial re-run test has a redundant assertion and does not check the version format

**File:** `test/mix/tasks/threadline/install_test.exs:209-210`
**Reason:** Out of scope (fix_scope: critical_warning; Info finding).
**Original issue:** A redundant `>` assertion, and the governance version is not checked as a valid 14-digit timestamp.

## Verification

- The edit and commit were made in an isolated worktree (`.claude/worktrees/rf-206-720-*`,
  temp branch `gsd-reviewfix/206-720`). The branch
  `fix/branch-protection-actions-capability` was then fast-forwarded to 7a154b8a. The
  worktree, the temp branch, and the recovery sentinel were removed.
- The tests ran in the **main checkout** after the fast-forward, so they can be reproduced
  from the current tree:
  `mix test test/mix/tasks/threadline/install_test.exs test/threadline/mix/migration_version_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/release_distribution_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/guide_graph_contract_test.exs`
  gave 104 tests and 0 failures. No test asserted on the old wording, and no test assertions were changed.

---

_Fixed: 2026-09-24_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
