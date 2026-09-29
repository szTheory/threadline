---
phase: 217-repo-hygiene
plan: 06
subsystem: repo-hygiene guard
tags: [hygiene, ci-gate, gap-closure, HYG-02]
status: complete
gap_closure: true
requires: [217-01, 217-05]
provides: [family-6 single-segment detection, conditional planning label, explicit git check, full-family allowlist safety net]
affects: [bin/verify-repo-hygiene, test/threadline/repo_hygiene_guard_test.exs]
tech-stack:
  added: []
  patterns: [runtime-concatenated fixtures, red-then-green mutation control]
key-files:
  created: []
  modified:
    - bin/verify-repo-hygiene
    - test/threadline/repo_hygiene_guard_test.exs
    - .planning/phases/217-repo-hygiene/217-VERIFICATION.md
decisions:
  - "Family 6 drops the mandatory trailing dash: the user segment ends at the first byte outside [A-Za-z0-9._] or end of line, the same way the other families end"
  - "The git-on-PATH check runs before argument parsing, so --self-test also reports a missing git by name"
  - "The allowlist safety net permits home-relative (tilde) forms and the runner account only; every other detected home-prefix family is forbidden"
metrics:
  duration: ~10 min
  completed: 2026-09-27
requirements: [HYG-02]
actuals:
  tokens: 9000
  tasks: 2
  commits: 3
plan_head_before: b4f600b97b96b2e32865d1174bb72f5964dacab1
plan_head_after: ec5cdc2c
---

# Phase 217 Plan 06: Family-6 false negative (CR-01) plus WR-01, WR-03, IN-01 Summary

The Claude-encoded project-dir matcher now catches a single-segment token, where the user segment is the last component. This is proven red-then-green and pinned by a sixth self-test case. The same two files also get a conditional `(.planning/ absent)` label, an explicit `git not found on PATH` exit, and an allowlist safety net that covers every home-prefix family.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (docs pre-step) | Rewrite the CR-01 reproduction path to placeholder form | 1b14e204 | 217-VERIFICATION.md (1+/1-) |
| 1 (tracer) | Family-6 single-segment fix, red then green, self-test case (f) | 09817a77 | bin/verify-repo-hygiene, repo_hygiene_guard_test.exs |
| 2 | WR-01 label, IN-01 git check, WR-03 full-family safety net | ec5cdc2c | bin/verify-repo-hygiene, repo_hygiene_guard_test.exs |

## CR-01: before and after

- Before: `qr{(-\Q$users\E-[A-Za-z0-9._]+-)}`. The trailing dash was mandatory, so a single-segment `-Users-<user>` token at end of line, or followed by `/`, gave no HIT.
- After: `qr{(-\Q$users\E-[A-Za-z0-9._]+)}`. The token ends at `-`, `/`, a non-class byte (including `<`, so placeholders stay clean) or end of line.

### RED record (against the unmodified script)

`mix test test/threadline/repo_hygiene_guard_test.exs` gave `40 tests, 2 failures`:

1. `family 6 (Claude-encoded project dir) hits a single-segment token at end of line`: `match (=) failed`, left `{output, 1}`, right `{"verify-repo-hygiene: 1 tracked text file(s) clean; 0 allowlist entries used, 0 inert (.planning/ absent)\n", 0}`
2. `family 6 hits a single-segment token followed by a slash`: the same mismatch, exit 0 where 1 was expected

### GREEN

After the regex change, the file gave `40 tests, 0 failures`, and `--self-test` printed `verify-repo-hygiene self-test: ok (6 cases)`. The existing multi-segment family-6 test and the new placeholder negative (`-Users-<user>-<project>/memory`, exit 0, `clean`) both stay green.

## Task 2 results

- WR-01: the final line appends `planning_note`, which is set only when `planning_tracked` is empty. The real tree now ends `8 allowlist entries used, 0 inert` with no suffix.
- IN-01: `command -v git >/dev/null 2>&1 || die "git not found on PATH"` runs right after `export LC_ALL=C`. The test builds a PATH holding only `bash` and `dirname` symlinks and asserts exit 2 plus the message. It flunks if `git` is present in that dir.
- WR-03: `forbidden_home_literal?/1` covers macOS home, non-runner Linux home, Windows home (any drive letter, one or more backslashes), the Claude-encoded prefix, JSON-escaped macOS and Linux homes, and the per-user temp root with and without `/private`. Mutation control: when the helper was stubbed to return `false`, the control test failed (`expected a forbidden home literal: ...`, 1 failure). The file was restored byte-for-byte and the test went green again.

## Verification

- `mix test test/threadline/repo_hygiene_guard_test.exs test/threadline/repo_hygiene_contract_test.exs`: 50 tests, 0 failures (the guard file alone has 43 tests: 37 + 3 + 3)
- `bin/verify-repo-hygiene --self-test`: `ok (6 cases)`
- `bin/verify-repo-hygiene` on the real tree: exit 0, `3960 tracked text file(s) clean; 8 allowlist entries used, 0 inert`. The widened regex surfaced no new prose HIT beyond the VERIFICATION.md line handled in the docs pre-step.
- `git diff --quiet faa9c1d9 -- .github/repo-hygiene-allowlist.tsv`: unchanged. There is no new allowlist entry and no `.planning/` exemption.
- `mix verify.format` exit 0, and `mix verify.credo` found no issues
- A case-insensitive whole-word `git grep` for the current account name returns no file

## Deviations from Plan

None. The plan was executed as written.

## Threat Flags

None. No new surface; T-217-19, T-217-20 and T-217-22 are mitigated as planned.

## Self-Check: PASSED

Files found: bin/verify-repo-hygiene, test/threadline/repo_hygiene_guard_test.exs, 217-06-SUMMARY.md. Commits found: 1b14e204, 09817a77, ec5cdc2c, 2187b77c.
