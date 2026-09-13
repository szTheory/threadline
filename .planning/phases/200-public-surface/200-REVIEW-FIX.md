---
phase: 200-public-surface
fixed_at: 2026-09-13T03:58:15Z
review_path: .planning/phases/200-public-surface/200-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 200: Code Review Fix Report

**Fixed at:** 2026-09-13T03:58:15Z
**Source review:** `.planning/phases/200-public-surface/200-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Background exports upload a temporary pathname to remote storage instead of CSV content

**Files modified:** `lib/threadline/export/orchestrator.ex`, `test/threadline/export/orchestrator_test.exs`
**Commit:** 6e7dd0fb
**Status:** fixed: requires human verification
**Applied fix:** Read the completed temporary export and passed its CSV bytes through the portable `Storage.put/2` content contract. The existing Local adapter continues to write those bytes through its contained-path protections. A remote-shaped adapter regression proves the uploaded body begins with the canonical CSV header, contains an exported audit row, and is not a temporary pathname.

### CR-02: Anonymous ownership lets one anonymous session access every anonymous export

**Files modified:** `lib/threadline/semantics/actor_ref.ex`, `lib/threadline/governance/export_job.ex`, `lib/threadline/operator_surface/live/timeline_live.ex`, `lib/threadline/operator_surface/live/export_status_live.ex`, `lib/threadline/operator_surface/controllers/export_controller.ex`, `test/threadline/semantics/actor_ref_test.exs`, `test/threadline/operator_surface/live/timeline_live_test.exs`, `test/threadline/operator_surface/live/export_status_live_test.exs`, `test/threadline/operator_surface/controllers/export_controller_test.exs`
**Commit:** 1ce75557
**Status:** fixed: requires human verification
**Applied fix:** Added a shared stable-identity predicate and required a non-anonymous actor with a non-empty ID for operator job changesets, background queue handlers and affordances, job listing, and downloads. Independent anonymous-session regressions prove anonymous users cannot queue or list anonymous-owned jobs; a controller regression proves legacy anonymous-owned exports return 404.

## Verification

Verification ran in the isolated review-fix worktree, using the main checkout's installed dependency/build caches and the explicitly requested Elixir/Erlang versions. The verified commits were then fast-forwarded into the main checkout.

- `mix compile --warnings-as-errors` — passed.
- Five focused ExUnit modules were run one module per invocation because the repository uses shared non-sandboxed database/LiveView state — 134 tests, 0 failures.
- `git diff HEAD~2..HEAD --check` — passed.
- The isolated worktree was clean before transactional cleanup; the temporary branch was fast-forwarded and removed successfully.

## Skipped Issues

None.

---

_Fixed: 2026-09-13T03:58:15Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
