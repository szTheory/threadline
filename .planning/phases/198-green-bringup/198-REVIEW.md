---
phase: 198-green-bringup
reviewed: 2026-08-28T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .github/workflows/ci.yml
  - test/threadline/storage_schema_call_site_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - CONTRIBUTING.md
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 198: Code Review Report — Gap-Closure Round 3

**Reviewed:** 2026-08-28
**Depth:** standard
**Files Reviewed:** 4 (diff `ec9e7fdd..HEAD`, plans 198-19 and 198-21)
**Status:** clean (0 Critical, 0 Warning, 0 Info)

This file supersedes only the **scope of the diff reviewed**; it does not
discard round 1 or round 2's findings, both of which are preserved verbatim
below. Round 3 (diff `ec9e7fdd..HEAD`) covers plan 198-19 (the ci.yml
`search_path` db-prep step + the call-site detector's CR-01/CR-02 fixes) and
plan 198-21 (the `ci-required` needs-roster contract test + CONTRIBUTING.md
roster doc). This review is scoped to exactly these four files, per the
orchestrator's instructions; the other 18 round-3 plans' files were not
reviewed here.

## Summary — Round 3

Round 2's two Critical findings against
`test/threadline/storage_schema_call_site_contract_test.exs` are **verified
closed** by this round's changes, not merely claimed closed:

- **CR-01** (fully-qualified `Threadline.Test.Repo.*` receivers invisible to
  the sweep): the negative lookbehind was narrowed from `(?<![\w.])` to
  `(?<![\w])` and the receiver alternation widened to
  `(?:[A-Z][A-Za-z0-9_]*\.)*Repo`. I hand-traced this regex against both the
  fix target (`Threadline.Test.Repo.delete_all(` — now matches, leftmost,
  starting at `Threadline`) and the original boundary case the lookbehind
  exists to protect (`MyRepo.` / `some_repo.` — still rejected, because the
  only position at which the literal `Repo`/`repo` token could start is
  preceded by a word character, which the lookbehind still excludes). I
  independently confirmed via `grep` that every real fully-qualified receiver
  in this codebase is written as `Threadline.Test.Repo.*` (never an aliased
  `TestRepo.*` form), so the chain-based fix covers the actual call shapes in
  use, not just the reviewed example.
- **CR-02** (`insert_all` absent from `@ecto_functions`): `insert_all` was
  added to the roster. I confirmed the two real `insert_all` call sites this
  was meant to protect
  (`test/threadline/operator_surface/live/timeline_live_test.exs:458` and
  `test/threadline/operator_surface/controllers/export_controller_test.exs:431`)
  both carry a `repo_opts`-derived argument, so the sweep does not newly
  flag live code, and the anchor-on-literal-`(`-directly-after-the-alternation
  design means the list's new ordering (`insert_all` ahead of `insert!`/
  `insert`) cannot mask a partial match either way — I verified this by
  tracing the backtracking behavior for `insert_all(` against an `insert`-
  first ordering by hand, not just trusting the code comment's claim.

I ran the full test file for both touched test modules directly rather than
trusting the round's own claims: `mix test
test/threadline/storage_schema_call_site_contract_test.exs
test/threadline/ci_topology_contract_test.exs` — 36 tests, 0 failures. I also
ran `mix format --check-formatted` against all four files (clean).

**`ci.yml`'s new db-prep step (plan 198-19).** The added
`ALTER DATABASE threadline_phoenix_test SET search_path TO "$user", public,
threadline;` step is scoped correctly against the project's hard invariant: I
grepped the file and confirmed exactly 3 `ALTER DATABASE` statements exist in
`ci.yml` (the pre-existing two in `verify-example-browser` and
`verify-capture`, plus this round's new one in `verify-test`'s `current`
lane), and all 3 name `threadline_phoenix_test` — never `threadline_test`.
The shell escaping (`\"\$user\"` inside a double-quoted `-c` argument, itself
inside a YAML `run: |` block) resolves correctly to the Postgres-standard
literal `"$user", public, threadline` (this is Postgres's own documented
`$user` search-path placeholder, conventionally written quoted — e.g. the
default `SHOW search_path` value is `"$user", public`). The new step is
correctly guarded by `if: matrix.lane == 'current'`, matching the guard on
the `mix verify.example` step that actually needs it; the `min` lane never
runs the Phoenix example and so never needs the extra database. GitHub
Actions `run:` steps execute under `bash -e` by default, so a genuine
`psql` failure (as opposed to the intentionally swallowed
"database already exists" case from `createdb ... || true`) still fails the
step loudly rather than being masked.

**`ci_topology_contract_test.exs`'s two new contracts (plan 198-21).** Both
new tests derive their expectation from source rather than hardcoding it, and
both have working non-vacuity floors, which I verified are not decorative:

- The roster-drift test's `ci_required_block/0` `flunk`s explicitly if the
  `  ci-required:\n` marker isn't found (not a silent `[]`), and
  `ci_required_needs/0` asserts `length(actual) >= 10` — a broken derive (a
  regex that stops matching) trips this floor rather than passing on an
  accidentally-empty list. I confirmed by inspection that the derive regex
  (`~r/    needs:\n((?:      - .+\n)+)/`) correctly bounds itself to the
  contiguous 6-space-indented `- job` lines directly under `needs:` and stops
  at the following 4-space-indented `runs-on:` line, so it does not
  accidentally slurp the later `steps:` list's own `- name:` bullet.
  Cross-checked the extracted 12-item list against `CONTRIBUTING.md`'s
  roster and against `ci.yml`'s literal `needs:` block — they match exactly
  in both directions, so `missing_from_docs` and `undocumented_extra` are
  both correctly `[]`.
- The ruleset-singleton test correctly reads `.github/rulesets/main.json`
  (confirmed: exactly one `required_status_checks` context, `"CI required"`)
  and cross-checks it byte-for-byte against `ci-required`'s emitted
  `name: CI required` in `ci.yml` — both literals match.
- The `allowed-skips`/`allowed-failures` laundering guard correctly strips
  YAML comment lines before pattern-matching, so the explanatory prose in the
  `ci-required` job's trailing comment block (which mentions `` `allowed-skips` ``
  in prose, not as a YAML key) does not produce a false positive on the
  as-yet-undocumented-decision check.

I found no new Critical, Warning, or Info issues in this round's diff. The
widened receiver regex's chain group (`(?:[A-Z][A-Za-z0-9_]*\.)*Repo`) is, in
principle, capable of matching a hypothetical unrelated `Foo.Bar.Repo.*`
receiver that isn't actually Threadline's aliased Repo — but this is an
inherent property of the pre-existing heuristic-by-literal-name design (the
original bare `Repo.` match had the identical risk), not something round 3
introduced or worsened, and I found no such case in the real tree via `grep`.
Not reported as a new finding.

---

## Round 2 Findings (preserved, both CLOSED by round 3)

_Reviewed: 2026-08-28T18:29:14Z — diff `74db148a..HEAD`, plans 14, 15, 17._

### CR-01: The call-site sweep's receiver regex cannot see `Threadline.Test.Repo.*` — the fully-qualified form used in 9 real test files (73 call sites)

**Status: FIXED** (198-19, verified round 3, 2026-08-28). The negative
lookbehind was narrowed to `(?<![\w])` and the receiver alternation widened
to `(?:(?:[A-Z][A-Za-z0-9_]*\.)*Repo|@repo|repo)`, exactly as this finding's
suggested fix specified. Locked in by new behaviour tests (`a fully-qualified
Threadline.Test.Repo receiver is detected the same as Repo`, plus the
word-glued-boundary regression tests for `MyRepo.`/`some_repo.`) and a
real-tree non-vacuity assertion (`Enum.any?(results, &Regex.match?(~r/\.Repo\./,
&1.snippet))`). Verified independently in this round by hand-tracing the
regex and by running the test suite (36 tests, 0 failures).

### CR-02: `Repo.insert_all/3` is entirely absent from `@ecto_functions` — unprefixed bulk inserts against owned schemas are invisible to the sweep

**Status: FIXED** (198-19, verified round 3, 2026-08-28). `insert_all` (and
`insert_or_update!`/`insert_or_update`, `stream`) were added to
`@ecto_functions`. Locked in by new behaviour tests covering an unprefixed
`repo.insert_all(...)` offense, an `@repo.insert_all(..., repo_opts())`
non-offense, and an explicit ordering-safety test proving `insert_all(` is
not mistaken for a partial `insert(` match. Verified independently in this
round against the two real `insert_all` call sites in the tree.

### IN-02: `expected_failure_context?`'s "unclosed `assert_raise`/`try do`" check uses a literal `"end"` substring match, not a syntactic scan

**Status: unchanged, out of scope for round 3.** `contains_unclosed?/3` was
not touched by this round's diff (`ec9e7fdd..HEAD`). Still recorded as an
Info-level hardening gap from round 2, not re-verified here.

---

## Round 1 Findings (preserved)

_Reviewed: 2026-08-28T14:52:19Z — diff `02e6070a..HEAD`, plans 08–13._
_All three round-1 findings were already dispositioned by the orchestrator
before round 2 began; reproduced verbatim below for the record, unchanged._

### WR-01: `is_integer()` in `bin/classify-flake-run` accepts malformed strings with an interior dash

**Status: FIXED** (orchestrator, 2026-08-28). `is_integer()` now accepts `-`
only in leading position; locked in by a new case in
`flake_classifier_contract_test.exs` covering `1-2`, `-1-2`, `-`, and `1 2`,
verified non-vacuous (red when the fix is reverted).

### WR-02: Evidence-bundle completeness check in `ci.yml` is one-directional

**Status: REJECTED as a false positive** (orchestrator, 2026-08-28).
Measured on the committed evidence: 372 JSON / 54 aria.yml, with 318 JSON
files legitimately having no `aria.yml` (aria.yml covers only story cells;
scorecards exist for many more subjects). A symmetric assertion would fail
`verify-capture` on its first run. The existing one-directional check is
correct as written. No change made.

### IN-01: `optional_deps_contract_test.exs`'s `guarded?/1` checks only the file's first line, not that the guard actually wraps the offending directive

**Status: ACCEPTED, no change** (orchestrator, 2026-08-28). Recorded, not
fixed; `mix verify.compile_no_optional` remains the authoritative guard.

---

_Reviewed: 2026-08-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
