---
phase: 217-repo-hygiene
plan: 04
subsystem: repo-hygiene
tags: [scrub, git-grep, perl, prefix-rewrite, prior-art, planning-docs]

requires:
  - phase: 217-01
    provides: "bin/verify-repo-hygiene guard (7 pattern families, scoped allowlist), whose report drives this plan's exact scrub file lists"
provides:
  - "Public commit (3 files: 2 prompts/prior-art/ notes + 1 sigra field-guide email) with every home-relative and machine-local path prefix rewritten to a fixed placeholder"
  - ".planning/-only commit (316 files) with the same prefix rewrite applied to the guard's full .planning/ HIT list"
  - "A local tree where bin/verify-repo-hygiene exits 0 with zero HIT lines and zero UNUSED allowlist entries"
affects: [217-05-wire-guard-into-ci]

actuals:
  tokens: 166930
  tasks: 2
  commits: 2
  plan_head_before: 2b2fcce511a3667f9ee0f7f92c7c39d70b48f965
  plan_head_after: ddcea1c85315a409adfab65ffe677013f75f1812

tech-stack:
  added: []
  patterns:
    - "Guard-report-derived file lists (HIT lines split on .planning/ prefix), never a hand-maintained list"
    - "perl -pi rewrite driven by -p's own implicit while(<>)+print loop — NOT a script-owned while(<>) loop, which double-consumes stdin against -p's implicit loop (rediscovered here; same class of bug as 217-01-SUMMARY.md's perl -ne deviation)"
    - "NUL-safe xargs -0 staging with a pre-commit staged-set-equals-derived-list assertion"

key-files:
  created: []
  modified:
    - prompts/prior-art/SOURCE-CANONICAL.md
    - prompts/prior-art/accrue-planning-notes.md
    - "prompts/prior-art/from-sigra/Auth Domain Language — A Field Guide.md"
    - .planning/STATE.md (representative; 316 total .planning/ files in the second commit)
    - .planning/phases/217-repo-hygiene/217-RESEARCH.md (representative)

key-decisions:
  - "Public list P (2 files) and the field-guide's whole-word-username hit (1 file) landed together as Task 1's 3-file commit, matching the plan's stated public-safe scope exactly — no more, no fewer."
  - "The .planning/ HIT list L was re-derived fresh at Task 2 execution time (316 files) rather than reused from Task 1's report or the 217-01 census (317), honoring the plan's 'moving target, re-derive at execution' instruction; 316 sits inside the plan's 250-400 tolerance band."
  - "Field-guide email local part (real username -> 'user') was a manual single-word edit, not part of the R1-R7 perl pass, since it is not one of the guard's 7 pattern families — it is required by HYG-02's separate 'no real username anywhere' clause."

requirements-completed: [HYG-01]

coverage:
  - id: D1
    description: "bin/verify-repo-hygiene exits 0 on the full local tree (.planning/ present), zero HIT lines, zero UNUSED allowlist entries"
    requirement: "HYG-01"
    verification:
      - kind: integration
        ref: "bin/verify-repo-hygiene (run after both commits)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Public scrub commit touches only 3 non-.planning/ files; .planning/ scrub commit touches only .planning/ paths"
    requirement: "HYG-01"
    verification:
      - kind: integration
        ref: "git show --name-only --format= <sha> per commit, both directions asserted"
        status: pass
    human_judgment: false
  - id: D3
    description: "Rewrites are prefix-only: equal added/deleted numstat counts, exact line-count preservation across all 316+3 files, idempotent second pass"
    requirement: "HYG-01"
    verification:
      - kind: unit
        ref: "git diff --numstat per file (awk equal-count check), per-file wc -l before/after, second R1-R7 pass diff-stat identity"
        status: pass
    human_judgment: false
  - id: D4
    description: "No whole-word username occurrence remains anywhere in the tracked tree after both commits"
    requirement: "HYG-01"
    verification:
      - kind: integration
        ref: "git grep -l -I -w -i \"$(id -un)\" (full tree, post both commits)"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-09-27
status: complete
---

# Phase 217 Plan 4: Forward Scrub of Machine-Local Paths Summary

**Two forward, prefix-only commits (3 public prior-art files, then 316 `.planning/` files) rewrite every guard-flagged home/tilde/temp-root path to a fixed placeholder, taking `bin/verify-repo-hygiene` from red to a clean 0-exit with zero unused allowlist entries.**

## Performance

- **Duration:** ~35 min
- **Tasks:** 2
- **Files:** 3 (public commit) + 316 (`.planning/` commit) = 319 files touched, 0 created

## Accomplishments

- Public commit (`380981a6`): rewrote seven home-relative sibling-repo paths (two source-repo names under a research prompts directory) to the `<home>/` placeholder in the two `prompts/prior-art/` notes (R3), and replaced the sigra field guide's example JWT-claim email local part (the real username) with a neutral placeholder per HYG-02's "no real username anywhere" clause.
- `.planning/` commit (`ddcea1c8`): applied the same R1-R7 prefix rewrite to all 316 files the guard's fresh report flagged under `.planning/` — macOS home, home-relative, and macOS per-user temp-root prefixes, each collapsed to a fixed placeholder token. Every file's added/deleted line counts are equal, every file's total line count is unchanged, and a second pass over the same list changes nothing.
- `bin/verify-repo-hygiene` now exits 0 on the full local tree: `3952 tracked text file(s) clean; 8 allowlist entries used, 0 inert`.
- `git grep -l -I -w -i "$(id -un)"` over the whole tracked tree prints nothing after both commits.
- `mix test test/threadline/repo_hygiene_guard_test.exs` — 37 tests, 0 failures (guard itself unchanged by this plan).

## Task Commits

1. **Task 1 (tracer): public scrub commit** - `380981a6` (docs) — 3 files, 8 insertions / 8 deletions
2. **Task 2: `.planning/` scrub commit** - `ddcea1c8` (docs) — 316 files, 930 insertions / 930 deletions

## Files Created/Modified

- `prompts/prior-art/SOURCE-CANONICAL.md` — 1 tilde-path rewrite
- `prompts/prior-art/accrue-planning-notes.md` — 6 tilde-path rewrites
- `prompts/prior-art/from-sigra/Auth Domain Language — A Field Guide.md` — 1 example-email local-part edit
- 316 `.planning/` files (representatives: `.planning/STATE.md`, `.planning/phases/217-repo-hygiene/217-RESEARCH.md`) — prefix rewrites per the guard's HIT report

## Decisions Made

- P and the field-guide hit were committed together as Task 1's exact 3-file list, matching the plan's stated public-safe boundary.
- L was re-derived fresh at Task 2's execution time (316 files, not reused from a stale count) — inside the plan's 250-400 tolerance.
- The field-guide's email-local-part edit was done as a targeted manual edit outside the R1-R7 perl pass, since it isn't one of the guard's 7 pattern families.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The rewrite script's own `while(<>)` loop double-consumed stdin against `perl -pi`'s implicit loop**
- **Found during:** Task 2, first integrity check (numstat equality) on the applied rewrite
- **Issue:** The initial R1-R7 perl script wrapped its substitutions in its own `while (<>) { ...; print; }` body, invoked via `perl -i -p tmp/hyg-rewrite.pl <files>`. The `-p` flag already supplies an implicit `while(<>){...} continue { print }` loop, so the script's inner `while(<>)` read a *second* line from the same handle inside each outer iteration, silently dropping every file's first line (`.planning/STATE.md`'s YAML frontmatter `---` delimiter, in the caught case) and desynchronizing print counts. This is the same class of defect as the `perl -ne` deviation recorded in `217-01-SUMMARY.md` (double-consumed stdin against an explicit inner read loop).
- **Fix:** Restored all 316 files via `git checkout --` (files were still tracked-clean, so the revert was lossless), then rewrote the script to contain only the bare substitution statements with no `while`/`print` wrapper, letting `-p`'s own implicit loop drive iteration and auto-print.
- **Files modified:** none in the repo — the defect and fix were confined to the throwaway `tmp/hyg-rewrite.pl` script, deleted at the end of Task 2 per the plan's cleanup step. No tracked file was left in a corrupted state.
- **Verification:** Re-ran the fixed script on an isolated `---\nhello\n` fixture and on `.planning/STATE.md` directly, confirming line-count and content preservation before re-applying to the full 316-file list; then all of Task 2's integrity checks (numstat, JSON re-parse, idempotent second pass, per-file line-count diff, guard, username grep) passed clean.
- **Committed in:** `ddcea1c8` (the corrected rewrite is what's committed; the broken intermediate state was never staged or committed)

---

**Total deviations:** 1 auto-fixed (1 bug, Rule 1)
**Impact on plan:** Caught before staging or committing — the broken intermediate rewrite never reached git's index. No scope creep; the fix only touched the throwaway scrub script.

## Issues Encountered

None beyond the deviation above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `bin/verify-repo-hygiene` exits 0 on the local tree with `.planning/` present, zero HIT lines, zero UNUSED allowlist entries — the clean baseline plan 217-05 needs before wiring the guard into CI.
- No history was rewritten; both scrub commits are forward, ordinary commits on `milestone/v1.43`.
- `.planning/config.json` was neither edited nor staged by this plan (confirmed ` M` unstaged before and after both commits).
- No blockers.

---
*Phase: 217-repo-hygiene*
*Completed: 2026-09-27*

## Self-Check: PASSED

- `prompts/prior-art/SOURCE-CANONICAL.md`, `prompts/prior-art/accrue-planning-notes.md`, `prompts/prior-art/from-sigra/Auth Domain Language — A Field Guide.md`, and this SUMMARY all found on disk.
- Commits `380981a6`, `ddcea1c8`, `05962639`, `3d1cee75` all found in `git log --oneline --all`.
- `bin/verify-repo-hygiene` — exit 0, `3953 tracked text file(s) clean; 8 allowlist entries used, 0 inert`.
- `git grep -l -I -w -i "$(id -un)"` — prints nothing.
- `mix test test/threadline/repo_hygiene_guard_test.exs` — 37 tests, 0 failures.
- `commits: 2` measured via `git rev-list --count 2b2fcce5..ddcea1c8` (ledger-based, matches `actuals.commits`).
