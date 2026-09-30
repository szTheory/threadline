---
phase: 217-repo-hygiene
plan: 07
subsystem: repo-hygiene guard
tags: [hygiene, ci-gate, gap-closure, HYG-01, HYG-02, docs-contract]
status: complete
gap_closure: true
requires: [217-06]
provides: [placeholder convention for path-shape prose, guard failure hint, colon-safe record parsing, fully dispositioned review]
affects: [CONTRIBUTING.md, bin/verify-repo-hygiene, test/threadline/repo_hygiene_guard_test.exs, test/threadline/repo_hygiene_contract_test.exs]
tech-stack:
  added: []
  patterns: [marker-delimited doc list pinned by a contract test that runs the real guard, NUL-to-SOH record transport in bash, right-anchored parsing]
key-files:
  created: []
  modified:
    - CONTRIBUTING.md
    - bin/verify-repo-hygiene
    - test/threadline/repo_hygiene_contract_test.exs
    - test/threadline/repo_hygiene_guard_test.exs
    - .planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md
decisions:
  - "Path shapes in docs and planning prose use an angle-bracket placeholder for the user or machine segment, never a concrete name; no exemption, suppression marker or allowlist widening"
  - "The guard prints a stderr hint naming CONTRIBUTING's 'Writing about machine-local paths' on any uncovered HIT; stdout is unchanged"
  - "git grep records travel NUL-delimited (translated to SOH) and HIT lines are parsed right-anchored, so colon-containing tracked filenames are scanned and scoped by full path (WR-02)"
  - "CONTRIBUTING's new section says 'tracked planning docs' instead of naming the planning directory, because an existing community-health contract forbids that literal in CONTRIBUTING"
metrics:
  duration: ~25 min
  completed: 2026-09-27
requirements: [HYG-01, HYG-02]
actuals:
  tokens: 16000
  tasks: 3
  commits: 3
plan_head_before: 97afea7123c013c059fa5cf1807a9468917aa1e1
plan_head_after: 1e5bbcc4ac4c2fc925503f480e0f4cd4d71d4cd0
---

# Phase 217 Plan 07: Placeholder convention, guard hint, colon-safe parsing Summary

Describing a machine-local path shape now has one documented form: an angle-bracket placeholder for the user or machine segment. A contract test runs the real guard in both directions to pin it. When the guard fails, it points at the convention. Colon-containing tracked filenames are now scanned (WR-02), and all five review findings are recorded `fixed`.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (tracer) | Placeholder convention: CONTRIBUTING section, guard hint, doc contract test | 16edbbd5 | CONTRIBUTING.md, bin/verify-repo-hygiene, repo_hygiene_contract_test.exs, repo_hygiene_guard_test.exs |
| 2 | WR-02: NUL/SOH-delimited records, right-anchored parsing, perl sort | 74279a7c | bin/verify-repo-hygiene, repo_hygiene_guard_test.exs |
| 3 | All five review dispositions set to `fixed`, phase-wide gates | 1e5bbcc4 | 217-REVIEW-DISPOSITION.md |

## The convention decision

This is a placeholder convention, not an exemption. The segment is written as `<user>`, `<home>`, `<xx>`, `<path>`, `<project>` or `<claude-projects-dir>`. `<` is outside every family's segment character class, so a placeholder never matches, and the guard stays strict for everything else. CONTRIBUTING.md now has `## Writing about machine-local paths` just before `## Pull requests`. It lists the 9 canonical forms between the `repo-hygiene-placeholders` markers.

Rejected alternatives:
1. Exempting the REVIEW and VERIFICATION files. These are the files that quote real diffs and tool output, so an exemption would blind the guard exactly where leaks are most likely.
2. An inline suppression marker. Any real leak could carry one.
3. Widening the allowlist. The allowlist is forbidden for home paths by design.

## RED records

### Task 1 (before the CONTRIBUTING section and hint existed)

`mix test test/threadline/repo_hygiene_contract_test.exs test/threadline/repo_hygiene_guard_test.exs` gave `55 tests, 5 failures`. All five new tests failed:
1. `concretized placeholder forms are HITs (non-vacuity control)`: flunked, marker missing
2. `every documented placeholder form passes the real guard`: flunked, marker missing
3. `the guard's failure hint names the CONTRIBUTING heading byte-for-byte`
4. `CONTRIBUTING documents the placeholder convention right before Pull requests`
5. `an uncovered HIT prints the placeholder-convention hint; a clean run does not`: `Assertion with =~ failed`

GREEN: `55 tests, 0 failures`. In the concretized control, 7 of the 9 forms HIT on exactly their own lines. The generic-home and Claude-projects-dir forms stay clean, as designed.

### Task 2 (against the Task 1 script)

`mix test test/threadline/repo_hygiene_guard_test.exs` gave `46 tests, 2 failures`:
1. `a hit in a colon-containing tracked filename is reported with its full path`: exit 0 with `1 tracked text file(s) clean` where exit 1 was expected. The line was skipped entirely, so this was a detection miss, not just a mis-scope.
2. `a file-scoped entry covers a hit in a colon-containing filename`: exit 1 with `UNUSED allowlist entry notes:draft.md ~/<path>/` where exit 0 was expected.

GREEN: `57 tests, 0 failures` across both files. The existing sorted-output, two-hits-per-line and allowlist-content tests were unmodified. A bash check confirmed that git grep's own exit status survives the `tr` pipe: a missing repo gives 128 (die path) and no match gives 1.

## Final gate results

- `mix test` (full default suite): `9 properties, 2380 tests, 0 failures, 2 excluded`
- `mix verify.format`: exit 0. `mix verify.credo`: no issues.
- `mix verify.repo_hygiene` / `bin/verify-repo-hygiene`: exit 0, `3961 tracked text file(s) clean; 8 allowlist entries used, 0 inert`. The used count (8) is the same as before Task 2.
- `bin/verify-repo-hygiene --self-test`: `ok (6 cases)`
- `git diff --quiet faa9c1d9 -- .github/repo-hygiene-allowlist.tsv`: unchanged, with no exemption and no suppression marker
- A case-insensitive whole-word `git grep` for the current account name lists no file
- All `CONTRIBUTING`-referencing doc contract tests (17 files): `194 tests, 0 failures`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CONTRIBUTING wording collided with an existing doc contract**
- **Found during:** Task 1
- **Issue:** `community_health_contract_test.exs` refutes the planning-directory literal anywhere in CONTRIBUTING.md ("CONTRIBUTING depends on internal planning history"). The plan's two mentions of that directory made it fail.
- **Fix:** The section now says "any tracked planning docs" and "any doc or planning file". The meaning is unchanged.
- **Files modified:** CONTRIBUTING.md
- **Commit:** 16edbbd5

## Known Stubs

None.

## Threat Flags

None. T-217-23 through T-217-26 were mitigated as planned, and no new surface was added.

## Self-Check: PASSED

Files found: CONTRIBUTING.md, bin/verify-repo-hygiene, repo_hygiene_contract_test.exs, repo_hygiene_guard_test.exs, 217-REVIEW-DISPOSITION.md. Commits found: 16edbbd5, 74279a7c, 1e5bbcc4.
