---
phase: 217-repo-hygiene
reviewed: 2026-09-27T20:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - CONTRIBUTING.md
  - bin/verify-repo-hygiene
  - test/threadline/repo_hygiene_contract_test.exs
  - test/threadline/repo_hygiene_guard_test.exs
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 217: Code Review Report (re-review after 217-06 / 217-07)

**Reviewed:** 2026-09-27T20:00:00Z
**Depth:** standard (incremental, diff `b09da7dc..HEAD`)
**Files Reviewed:** 4
**Status:** issues_found

## Summary

This is an incremental re-review of the gap-closure work in plans 217-06 and 217-07. The
guard runs clean on the real tree (`3962 tracked text file(s) clean; 8 allowlist entries
used, 0 inert`), `--self-test` passes all 6 cases, and both test files pass (57 tests, 0
failures).

How each prior finding stands:

| Prior finding | Verdict | Evidence |
|---|---|---|
| CR-01 (family 6 missed single-segment token) | **Fixed** | Regex is now `-<Users>-[A-Za-z0-9._]+` with no trailing `-`. Self-test case (f) and two new guard tests (end of line, followed by `/`) go red. |
| WR-01 (`(.planning/ absent)` always printed) | **Fixed** | `planning_note` is now conditional (script lines 555-558). A test covers both branches. |
| WR-02 (colon filenames broke parsing) | **Fixed for colons**, still incomplete | `git grep -z` records go through SOH, and HIT lines are parsed from the right. Colon paths now work (two tests). Filenames containing a newline still mis-scope; see WR-03 below. |
| WR-03 (allowlist safety net covered 2 of 7 families) | **Partially fixed** | `forbidden_home_literal?/1` now matches the direct prefix of all 7 families. It still misses a literal that is an ancestor of a home directory; see WR-01 below. |
| IN-01 (missing git reported as "not a git work tree") | **Fixed** | A `command -v git` check now runs before any mode. A test with a PATH that has no git proves the named message and exit 2. |

The fixes introduced or exposed four new warnings. The most important one: the widened
safety net can still be bypassed by an allowlist literal that is a parent of the home
directory. The widened family-6 regex also has no boundary, so it now flags ordinary
TitleCase kebab words.

## Warnings

### WR-01: `forbidden_home_literal?/1` passes ancestor-prefix literals that blanket-cover every home directory

**File:** `test/threadline/repo_hygiene_guard_test.exs:620-638` (interacts with `bin/verify-repo-hygiene:421-444`)
**Issue:** When a literal does not end in `/`, `token_covered_by_literal` covers any token
that is the literal plus `/` plus anything. So a literal set to just the macOS home root,
with no trailing slash (`/<Users>`), covers every macOS home token. A literal of bare `/`
covers every family 1, 2 and 5 token. A literal of a single backslash covers every
JSON-escaped family 7 token. I confirmed the behavior in a scratch fixture:

- An allowlist of `.` plus the bare `/` literal turned a tree containing a macOS home, a
  Linux home and a `/var/folders/<xx>/` path into
  `1 tracked text file(s) clean; 1 allowlist entry used`, with exit 0.
- An allowlist of `.` plus the bare macOS home root covered the macOS home hit.

`forbidden_home_literal?/1` only tests `String.starts_with?(literal, "/<Users>/")` and the
other trailing-slash prefixes. None of these literals starts with such a prefix, so the
"never allowlists a person's home directory" test passes for all of them. This is the same
class of gap as the original WR-03, one level up.
**Fix:** Also reject any literal that is a prefix of a family root. The best place for
this is the script's structural validation (exit 2), so it holds even without the test
suite:
```elixir
roots = [
  "/" <> @users_word <> "/", "/" <> @home_word <> "/", "-" <> @users_word <> "-",
  "\\/" <> @users_word <> "\\/", "\\/" <> @home_word <> "\\/",
  "/var/folders/", "/private/var/folders/"
]
ancestor? = Enum.any?(roots, &(String.starts_with?(&1, literal <> "/") or String.starts_with?(&1, literal)))
ancestor? or linux_home? or ...
```
In the script, return a `literal is too broad` config error when
`"$literal/"` or `"$literal"` is a prefix of any family root. Add the synthetic literals
`/`, `/<Users>`, `/<home>`, `/var/folders` and a single backslash to the test's `flagged`
list.

### WR-02: Widened family-6 regex has no left boundary and flags ordinary TitleCase kebab words

**File:** `bin/verify-repo-hygiene:280`
**Issue:** Dropping the trailing `-` (the CR-01 fix) makes family 6 match
`-<Users>-` followed by one or more `[A-Za-z0-9._]` bytes anywhere in a line, with no
lookbehind. Ordinary text such as `Admin-<Users>-Guide`, `Manage-<Users>-Page`, or a
TitleCase CSS or test id is now a HIT. In a scratch fixture, a line reading "Admin", dash,
the capitalized home word, dash, "Guide" exited 1. Before the fix this token needed a
second dash after the segment, so it was much less likely to match by accident.
CONTRIBUTING.md now says the allowlist is "never for prose". A contributor who hits this
has no sanctioned escape hatch except rewording. No such text is in the tree today, but
the gate turns red when one is added.
**Fix:** Require the shape Claude actually produces. An encoded project dir starts at a
path boundary (start of line, `/`, whitespace, a quote or backtick) or follows a drive
prefix (`C-` or `C--`). Anchor the match accordingly:
```perl
qr{(?:(?<![A-Za-z0-9._-])|(?<=[A-Za-z]-)|(?<=[A-Za-z]--))(-\Q$users\E-[A-Za-z0-9._]+)},
```
Add a negative guard test for a mid-word TitleCase kebab token. Keep the CR-01 positives,
which are a token after `/` and a token after a space.

### WR-03: A newline in a tracked filename still mis-scopes the hit, and a phantom scope can cover it

**File:** `bin/verify-repo-hygiene:15-17, 387-398`
**Issue:** `git grep -z` terminates records with `\n` and prints the raw filename. A
tracked filename that contains a newline therefore splits into two records, and the perl
matcher sees only the part after the newline as the path. In a scratch fixture, a file
named `no<LF>te.md` with a home-path hit was reported as `HIT te.md:1: ...`.
An allowlist entry scoped to `te.md`, a file that does not exist, then covered that hit
and the run exited 0 except for other findings. The header comment says "a colon or other
punctuation in a tracked path is safe: it is scanned and scoped by its full path", which
overclaims. The allowlist validator also never checks that a file-path scope names a
tracked path.
**Fix:** Pick one:
- Fail closed on any tracked path containing `\n`. Before the scan, check
  `git ls-files -z | tr '\0' '\n'` against `git ls-files -z` for record-count mismatch,
  or run `git ls-files -z | perl -0ne 'exit 1 if /\n/'`.
- Read `git grep -z` output in perl with a record parser that consumes `path\0lineno\0`
  and then the content up to `\n`, instead of splitting on newline first.

Either way, narrow the header comment to what is actually guaranteed.

### WR-04: CONTRIBUTING claims every Claude-encoded project path is a HIT, but Linux-encoded dirs are not detected

**File:** `CONTRIBUTING.md:90-93`; `bin/verify-repo-hygiene:81-83, 280`
**Issue:** The new section says "Any concrete user or machine segment in a home
directory, a per-user temp root, or a Claude-encoded project path is a HIT". Family 6
only matches the macOS/Windows home word. On Linux, including CI runners and Linux
contributors, Claude encodes a Linux home project as `-<home>-<name>-<project>`. No
family matches that shape, so a pasted Linux Claude-projects path gets through silently.
The gap existed before this diff, but the new doc text now promises coverage that the
guard does not provide.
**Fix:** Choose one of these:
- Add a Linux variant of family 6, `-\Q$home\E-[A-Za-z0-9._]+`, anchored at a path
  boundary as in WR-02. That anchor is mandatory here, because `-home-` is a far more
  common kebab fragment. Add the matching `-<home>-<user>-<project>` placeholder form and
  a guard test.
- Or scope the CONTRIBUTING sentence explicitly to the macOS/Windows encoding.

## Info

### IN-01: The contract test for the failure hint passes even if the hint is deleted

**File:** `test/threadline/repo_hygiene_contract_test.exs:399-408`
**Issue:** The test asserts that `bin/verify-repo-hygiene` contains the string
"Writing about machine-local paths". The script's header comment (line 44) also contains
that string, so deleting the `printf` at line 537 would not fail this test. The
behavioral guard test at `repo_hygiene_guard_test.exs:496-508` does cover the hint, so
there is no coverage hole. This test is just close to vacuous.
**Fix:** Assert on the `printf` line specifically, for example
`~r/printf .*Writing about machine-local paths.*>&2/`. Or delete this test and rely on the
behavioral one.

### IN-02: "No file or directory is exempt from the scan" contradicts the allowlist self-exclusion

**File:** `CONTRIBUTING.md:119-121`
**Issue:** The allowlist file is excluded from the tree scan by an `:(exclude)` pathspec
(script lines 252-261). Only its comment lines and reason fields are scanned, not its
literal fields. The CONTRIBUTING sentence is absolute.
**Fix:** Change the sentence to "no file or directory is exempt from the scan other than
the allowlist's own literal column".

---

_Reviewed: 2026-09-27T20:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
