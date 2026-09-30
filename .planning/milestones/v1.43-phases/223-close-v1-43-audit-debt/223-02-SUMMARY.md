---
phase: 223-close-v1-43-audit-debt
plan: 02
subsystem: repo-hygiene-guard
tags: [ci, security, bash, contract-test]
status: complete
dependency-graph:
  requires: []
  provides:
    - "bin/verify-repo-hygiene: anchored family 8 (Linux-encoded Claude project dirs), left-anchored family 6, literal_too_broad structural check, newline pre-scan, --self-test ok (10 cases)"
    - "test/threadline/repo_hygiene_guard_test.exs: family-8 tests, TitleCase/drive-form family-6 tests, 11 too-broad-literal tests, 2 positive controls, newline-path test, case-label non-vacuity cross-check"
    - "CONTRIBUTING.md: `-home-<user>-<project>` placeholder bullet"
  affects:
    - bin/verify-repo-hygiene
    - test/threadline/repo_hygiene_guard_test.exs
    - CONTRIBUTING.md
tech-stack:
  added: []
  patterns:
    - "every new fixture literal built by string concatenation (bash and Elixir), so the guard's own source and test file never contain a matchable literal"
    - "data-driven `for {label, literal} <- @too_broad_literals` guard-test block, one generated test per too-broad literal"
    - "non-vacuity cross-check: count the script's own case-label comments via regex and assert the count matches the self-test summary"
key-files:
  created: []
  modified:
    - bin/verify-repo-hygiene
    - test/threadline/repo_hygiene_guard_test.exs
    - CONTRIBUTING.md
decisions:
  - "D-14's locked two-branch anchor `(?:(?<![A-Za-z0-9._-])|(?<=[A-Za-z]-))` was used verbatim; the review's third branch (?<=[A-Za-z]--) was omitted per the plan's discretion note — the drive form's two bytes before the token are a letter and a single dash, already covered by the second branch, proven by the drive-form guard test"
  - "literal_too_broad roots are built by concatenation from _word_users/_word_home, never as literals, matching the matcher's own convention"
  - "the newline pre-scan runs git ls-files -z through `perl -0 -ne 'exit 1 if /\\n/'`, exiting 2 via `die` before the tree scan starts"
metrics:
  duration: "~50min"
  completed: 2026-09-29
actuals:
  tokens: 5066
  tasks: 3
  commits: 3
  plan_head_before: c20a7eff621ab0c218b36db13621c648d7555fcd
  plan_head_after: 635de44768ff3228fc1c317a1b9edec69ce346e3
---

# Phase 223 Plan 02: Close phase 217 round-2 review findings in `bin/verify-repo-hygiene` Summary

Fixed all four remaining round-2 findings (R2-WR-01..04) directly in the repo-hygiene guard
itself, each backed by a self-test case and/or guard test, keeping the self-test count honest
at `ok (10 cases)` and the real tree clean throughout.

## What was built

**Task 1 (`ci(223-02)`, commit `354dde9a`, R2-WR-04/D-16):**
- Added anchored family 8 to `MATCHER_PROGRAM`:
  `qr{(?<![A-Za-z0-9._-])(-\Q$home\E-[A-Za-z0-9._]+)}`, directly after family 6. A pre-scan
  (`git ls-files -z | xargs -0 perl -ne ...`) confirmed 0 hits on the tracked tree before and
  after, matching the plan's measured 0 anchored / 539 unanchored false positives.
- Added the family-8 line to the header's family list and boundary paragraph, self-test case
  (g') (summary → `ok (7 cases)`), the CONTRIBUTING placeholder bullet
  `` `-home-<user>-<project>` ``, and three guard tests (one HIT, one placeholder negative, one
  mid-word negative proving the anchor). The CONTRIBUTING bullet's `<user>`/`<project>`
  concretization is auto-covered by the existing "concretized placeholder forms are HITs"
  contract test — no test-file edit was needed for that control.

**Task 2 (`ci(223-02)`, commit `e99e172c`, R2-WR-02/D-14):**
- RED: wrote five family-6 guard tests first (TitleCase negative, space/slash/drive-form/
  start-of-line positives) against the unanchored regex; the TitleCase test failed exactly as
  expected (`HIT a.md:1: -<user>-Guide`, a real match, not an INVALID_RED crash).
- GREEN: replaced family 6 with the locked two-branch anchor
  `(?:(?<![A-Za-z0-9._-])|(?<=[A-Za-z]-))(-\Q$users\E-[A-Za-z0-9._]+)`. All five new tests then
  passed, plus every pre-existing family-6 test (single-segment token, slash-followed token,
  placeholder negative).
- Rewrote the header boundary paragraph: family 6 now needs a boundary byte or the
  `<letter>-dash` pair; only family 3 needs no boundary at all. One header wording ("e.g.
  `C--<user>-...`") accidentally reintroduced a matchable Claude-encoded-style token and was caught
  immediately by the guard's own real-tree scan; rewritten to prose with no literal.
- Added self-test case (g) (summary → `ok (8 cases)`).

**Task 3 (`ci(223-02)`, commit `635de447`, R2-WR-01 + R2-WR-03/D-13, D-15, D-19):**
- RED: added 11 data-driven too-broad-literal guard tests (`/`, `\`, `~`, `~/`, `/var/folders`,
  `/Users`, `/Users/`, `/home`, `/home/`, the JSON-escaped form, the dash form) plus a newline-
  path test, all failing against the not-yet-added checks (12 intentional failures — the two
  positive-control tests, written against the target end state, passed immediately as expected).
- GREEN: added `literal_too_broad()` (checks whether any of 9 family roots, built by
  concatenation, starts with the candidate literal) wired into the `problem` elif chain right
  after "empty literal"; added the D-15 newline pre-scan
  (`git -C "$root" ls-files -z | perl -0 -ne 'exit 1 if /\n/'`) between the allowlist-error exit
  block and the tree scan, `die`-ing with a `newline` reason on a hit.
- Narrowed the header's colon-safety paragraph and the exit-2 list to name both new config
  errors.
- Added self-test cases (h) (a lone `/` allowlist literal) and (i) (a tracked filename built
  with a real embedded newline via `printf 'a\nb.md'`, allowlist scoped to the post-newline
  `b.md` fragment — proven not to cover the hit). Summary → `ok (10 cases)`.
- Added the non-vacuity cross-check test: regex-counts the script's own
  `^    # \(([a-z]'?)\) ` case-label comments and asserts exactly 10, matching the case letters
  a, b, c, d, e, f, g', g, h, i.
- One test-writing mistake was self-caught by the real-tree guard run: an early draft of the
  "scoped cache literal" positive-control test used a literal home path
  (a home-relative cache path and a fake tilde-home fixture) directly in the test name and a comment, which the guard's
  own scan flagged as a HIT in the test file. Rewritten to build the literal by concatenation
  and construct a fixture whose tracked hit exactly matches the covering literal, removing the
  literal from prose entirely.

## Verification

- `bin/verify-repo-hygiene --self-test`: `verify-repo-hygiene self-test: ok (10 cases)`.
- `bin/verify-repo-hygiene`: `4242 tracked text file(s) clean; 8 allowlist entries used, 0
  inert` — same 8 allowlist entries as plan 01's baseline; no allowlist entry added.
- `mix test test/threadline/repo_hygiene_guard_test.exs test/threadline/repo_hygiene_contract_test.exs`:
  80 tests, 0 failures (up from 60 before this plan).
- `mix compile --warnings-as-errors`: clean.
- `mix credo --strict` on the changed test file: no issues.
- `mix format --check-formatted test/threadline/repo_hygiene_guard_test.exs`: clean, after
  every task.
- All plan acceptance-criteria greps (case counts, family markers, `literal_too_broad`
  occurrences, `ls-files -z`, "ten cases"/"six cases" presence, `git diff --stat 787da941 --
  .github/repo-hygiene-allowlist.tsv` empty) confirmed after each task.
- `git show --name-only --format=` on each of the three commits lists exactly the files the
  plan named for that task.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - bug] Header prose reintroduced a matchable `-Users-` literal (Task 2)**
- **Found during:** Task 2, real-tree verification after the header rewrite.
- **Issue:** The boundary-paragraph rewrite used the concrete example
  a concrete drive-form example to illustrate the shape, which was itself a family-6 HIT on the
  guard's own source.
- **Fix:** Rewrote the sentence to describe the shape in prose ("a drive letter is immediately
  followed by a second dash before the token") with no literal token.
- **Files modified:** `bin/verify-repo-hygiene`.
- **Commit:** `e99e172c` (folded into the task commit; caught before commit).

**2. [Rule 1 - bug] A guard test's own name/comment leaked a literal home path (Task 3)**
- **Found during:** Task 3, real-tree verification after adding the too-broad-literal tests.
- **Issue:** The positive-control test "a scoped tool-install cache literal with a matching hit"
  wrote the literal path directly in its test name and a following comment, and its assertion
  (`exits 1`, an uncovered hit) didn't even match the misleading `exits 0` in the title — the
  test as drafted proved the wrong thing.
- **Fix:** Rebuilt the literal by concatenation (`"~" <> "/" <> "." <> "cache"`), renamed the
  test to describe the shape generically ("a scoped tool-install cache literal"), and
  constructed the fixture so its tracked HIT exactly matches the covering literal + `/x`,
  correctly asserting `exits 0` with `1 allowlist entry used`.
- **Files modified:** `test/threadline/repo_hygiene_guard_test.exs`.
- **Commit:** `635de447` (folded into the task commit; caught before commit).

No architectural deviations (Rule 4). No auth gates. No package installs. D-23's halt clause
was never triggered — the real tree stayed clean after every edit, no allowlist entry was
added, and the two literal-leak deviations above were self-corrected before the guard's own
scan or the assertion mismatch could pass unnoticed.

## Known Stubs

None.

## Threat Flags

None — this plan implements the threat mitigations named in its own `<threat_model>`
(T-223-05..09); it introduces no new unmitigated surface. T-223-09 (an executor weakening the
gate) did not occur: every edit strengthened detection, and the two self-caught deviations
above were fixed by removing literals from prose, never by narrowing a family or adding an
allowlist entry.

## Self-Check: PASSED

- `bin/verify-repo-hygiene` exists and self-tests `ok (10 cases)` — FOUND.
- `test/threadline/repo_hygiene_guard_test.exs` exists, 80 tests pass — FOUND.
- `CONTRIBUTING.md` contains the `-home-<user>-<project>` bullet — FOUND.
- Commit `354dde9a` — FOUND (`git log --oneline --all | grep 354dde9a`).
- Commit `e99e172c` — FOUND (`git log --oneline --all | grep e99e172c`).
- Commit `635de447` — FOUND (`git log --oneline --all | grep 635de447`).
- `bin/verify-repo-hygiene` on the real tree: clean, `8 allowlist entries used, 0 inert`
  (4242 tracked files before this SUMMARY was staged, 4243 after) — confirmed on the final tree.
