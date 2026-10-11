---
quick_id: 261011-bb8
plan: "01"
title: Make Phase 243 local evidence artifacts hygiene-safe
status: complete
requirements_completed: []
actuals:
  tokens: 13027
  tasks: 2
  commits: 2
task_commits:
  - f866871e
  - 0ab853b9
completed: 2026-10-11
---

# Phase 243 Local Evidence Artifact Hygiene Summary

Preserved the exact local Phase 243 custody receipts while removing them from Git tracking, made the tracked evidence prose portable, and retained the formatter-only Plan 03 test correction.

## Accomplishments

- Added exact `.gitignore` rules and removed only the candidate/preview receipt index entries. Both local files remain present with their original SHA-256 values: candidate `a466c6b73db571e09c584366ccaf154c75e34ba66a92800e641e06c621ac9010`; preview `0ac17d191359451e9faefd9888cfea8a692dc2b5eb9fe49a8812bb2a503adfdb`.
- Replaced machine-local cache and worktree paths in the Phase 243 Plan 02 summary and visual ledger with the approved `<home>/...` form, the tracked Phase 238 evidence index and repo-relative bundle, and a `$TMPDIR` preview-state command.
- Retained the existing formatting-only reflow in `test/threadline/e2e_preflight_contract_test.exs`; no assertion or expression behavior changed.

## Task Commits

1. Task 1, local receipt custody and portable evidence prose — `f866871e`.
2. Task 2, formatter-compliant preflight contract layout — `0ab853b9`.

The receipt JSON files were deleted from the Git index by the first commit; their local byte contents were not committed or edited.

## Verification

- `mix verify.repo_hygiene` — passed (4,794 tracked text files clean; 8 allowlist entries used, 0 inert).
- Candidate and preview receipt tests — 7 passed, 1 expected live-preview skip.
- Receipt existence, untracked status, exact ignore matching, and pre/post SHA-256 checks — passed.
- `mix format --check-formatted test/threadline/e2e_preflight_contract_test.exs` — passed.
- `mix test test/threadline/e2e_preflight_contract_test.exs` — 7 tests, 0 failures.
- `git diff --check -- test/threadline/e2e_preflight_contract_test.exs` — passed.
- GSD verifier — passed, 4/4 must-haves verified; see `261011-bb8-VERIFICATION.md`.

## Decisions and Scope

Phase 243 requirements UIV-02 and UIV-03 remain open. The old local receipts are custody inputs only; Plan 05 must refresh candidate and preview evidence after its final candidate HEAD. No snapshots, route guards, product behavior, requirements status, running preview, or external CI state changed.

## Issues Encountered

The initial sandboxed `git rm --cached` could not write the shared worktree index. Retrying that same two-path index-only operation with the authorized repository mutation succeeded; both receipt byte hashes remained unchanged.

## Self-Check: PASSED

Both task commits are ancestors of the current worktree HEAD, the local receipt files are present and ignored, and all focused checks listed above passed.
