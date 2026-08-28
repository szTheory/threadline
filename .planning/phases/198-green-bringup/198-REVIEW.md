---
phase: 198-green-bringup
reviewed: 2026-08-28T18:29:14Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - test/support/storage_schema_case.ex
  - test/threadline/pgbouncer_topology_test.exs
  - test/threadline/storage_schema_call_site_contract_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
findings:
  critical: 2
  warning: 1
  info: 1
  total: 4
status: issues_found
---

# Phase 198: Code Review Report — Gap-Closure Round 2 (Plans 14, 15, 17)

**Reviewed:** 2026-08-28T18:29:14Z
**Depth:** standard
**Files Reviewed:** 6 (diff `74db148a..HEAD`)
**Status:** issues_found (2 Critical, 1 Warning, 1 Info)

This file supersedes only the **scope of the diff reviewed**; it does not
discard round 1's findings. Round 1 (diff `02e6070a..HEAD` at the time,
covering plans 08–13) is preserved verbatim below under "Round 1 Findings
(preserved)", including the orchestrator's disposition on each. Round 2's
new findings (plans 14, 15, 17) follow immediately under "Round 2 Findings
(new)".

## Summary — Round 2

This round reviewed the PgBouncer-topology port + a new static call-site
sweep (198-14), the retirement of an ambient-dependency shell-out in
`stress_router_test.exs` (198-15), and the diagnosis-then-fix of two rotted
Playwright assertions (198-17).

**198-15 and 198-17 hold up.** The ambient shell-out removal is genuinely
replaced by a named, teeth-proven successor guard already inside
`ci-required`; the rewritten `toContainText("public")` assertions target the
correct DOM region (`<section aria-label="Selected schema readiness">`,
`coverage_live.ex:279-304`) and are provably non-vacuous for the branch of
`verdict_heading/2` these tests actually exercise (confirmed by reading
`coverage_live.ex`: the schema `<select>` lives in a separate `schema_form/1`
section outside the asserted container, so the new assertion cannot pass by
picking up the dropdown's own `<option value="public">` text).

**198-14's new static sweep does not deliver the guarantee its own moduledoc
and SUMMARY claim.** The moduledoc states "There is no permitted-file
collection, no opt-out source marker, and no skipped-path constant" and the
198-14-SUMMARY claims "any future Threadline-owned schema call site added
anywhere under `test/` ... is caught." Both claims are false as written: the
detector's receiver-matching regex and its Ecto-function roster each have a
provable, reproducible blind spot that lets a real call-site shape slip
through with **zero detection, no failure, no visible signal** — precisely
the "matches nothing, silently" failure mode the review brief warns is worse
than no guard. See CR-01 and CR-02 below, both reproduced against the real
tree, not hypothetical.

## Round 2 Findings (new)

### CR-01: The call-site sweep's receiver regex cannot see `Threadline.Test.Repo.*` — the fully-qualified form used in 9 real test files (73 call sites)

**File:** `test/threadline/storage_schema_call_site_contract_test.exs:56-66` (the
`@call_regex` definition, in particular the `(?<![\w.])` negative lookbehind
in front of the `Repo|@repo|repo` receiver alternation)

**Issue:** The negative lookbehind is meant to stop `MyRepo.insert(` or
`some_repo.insert(` from matching mid-identifier. It also, as an unintended
side effect, blocks the receiver whenever `Repo` is preceded by a `.` from a
fully-qualified module path — e.g. `Threadline.Test.Repo.delete_all(...)`,
which is the receiver form actually used at 73 call sites across 9 real
files in this codebase (`row_history_component_test.exs`,
`transaction_live_test.exs`, `copy_contract_test.exs`,
`breadcrumb_test.exs`, and 5 others — confirmed by
`grep -rn "Threadline\.Test\.Repo\." test/`).

Reproduced directly against the detector's own compiled regex:

```elixir
iex> Regex.scan(~r/(?<![\w.])(?:Repo|@repo|repo)\.(?:insert!|insert|delete_all)\(/x,
...>   "Threadline.Test.Repo.delete_all(AuditChange)")
[]
iex> Regex.scan(same_regex, "Repo.delete_all(AuditChange)")
[["Repo.delete_all("]]
```

Every one of those 73 call sites is invisible to `scan_call_sites/2` —
neither `in_scope` nor `offense`, regardless of whether it carries
`repo_opts()`. Today they all happen to carry `repo_opts()` (or the older
`storage_opts` binding), so there is no live defect. But the sweep's entire
premise — a run-independent, file-blind, tag-blind static net that catches
*any future* unprefixed owned-schema call anywhere in `test/` — is false for
this receiver shape. A future contributor who writes
`Threadline.Test.Repo.delete_all(AuditChange)` with no `repo_opts()` inside
any of these 9 files (or a new one using the same fully-qualified style) will
get a green `mix test test/threadline/storage_schema_call_site_contract_test.exs`
and a real, silent, undetected regression — the exact class of bug
`pgbouncer_topology_test.exs` demonstrated actually reaches production
undetected. The `in_scope_count > 0` non-vacuity assertion at the bottom of
the "real tree sweep" test does not catch this, because it only proves the
detector matches *something* (208 sites via the aliased `Repo.`/`repo.`
forms), not that it matches *everything* real.

**Fix:** Drop the `.` from the excluded lookbehind class so a receiver
preceded by another identifier segment (`Test.Repo`) is still recognized,
while still rejecting a receiver that is itself part of a longer identifier
(`MyRepo`, `some_repo`):

```elixir
@call_regex ~r/
  (?<![\w])
  (?:(?:[A-Z][A-Za-z0-9_]*\.)*Repo|@repo|repo)
  \.
  (?:#{Enum.join(@ecto_functions, "|")})
  \(
/x
```
i.e. permit an arbitrary chain of `CamelCase.` segments before the literal
`Repo`, and only require that `Repo`/`@repo`/`repo` itself isn't glued to a
preceding word character (blocking `MyRepo.` while allowing `Test.Repo.` and
`Threadline.Test.Repo.`). Add a behaviour test asserting
`Threadline.Test.Repo.delete_all(AuditChange)` is `in_scope: true,
offense: true`, and a real-tree assertion that `in_scope_count` after the fix
increases by at least 73 (or assert the fully-qualified form is represented
at all, e.g. via a fixture drawn from an actual file in the roster) so this
regression class has its own teeth going forward.

### CR-02: `Repo.insert_all/3` is entirely absent from `@ecto_functions` — unprefixed bulk inserts against owned schemas are invisible to the sweep

**File:** `test/threadline/storage_schema_call_site_contract_test.exs:38-52`
(`@ecto_functions` list)

**Issue:** `insert_all` is not in the roster, and — because the call regex
requires the function-name alternation to be immediately followed by a
literal `(` — the `insert` alternative present in the list cannot partially
match `insert_all(` either (the character after `insert` is `_`, not `(`).
Confirmed against the two real `insert_all` call sites in the tree:

```
test/threadline/operator_surface/live/timeline_live_test.exs:458:
  repo.insert_all(Threadline.Capture.AuditChange, chunk, storage_opts)
test/threadline/operator_surface/controllers/export_controller_test.exs:431:
  @repo.insert_all(AuditChange, chunk, repo_opts())
```

Both currently carry a correct opts argument, so there is no live defect
today — but the sweep produces **zero matches** at either line (verified by
running the detector's own `@call_regex` against both lines), meaning a
future unprefixed `Repo.insert_all(AuditChange, entries)` anywhere in
`test/` — including a straightforward copy-paste of one of these two
existing call sites with the trailing opts argument dropped — passes the
sweep silently. `insert_or_update`/`insert_or_update!` and `Repo.stream/2`
are likewise absent from the roster (not currently used against owned
schemas, but equally invisible if they ever are).

**Fix:** Add the missing Ecto.Repo callback names to `@ecto_functions`:
```elixir
@ecto_functions ~w(
  insert_all
  insert_or_update! insert_or_update
  insert! insert
  update! update
  delete_all update_all
  delete! delete
  all
  stream
  one! one
  get_by! get_by
  get! get
  aggregate
  exists?
  reload! reload
  preload
)
```
Add a behaviour-test fixture proving `repo.insert_all(AuditChange, [...])`
with no opts is detected as `in_scope: true, offense: true`, matching the
existing coverage pattern for every other function name.

## Info

### IN-02: `expected_failure_context?`'s "unclosed `assert_raise`/`try do`" check uses a literal `"end"` substring match, not a syntactic scan

**File:** `test/threadline/storage_schema_call_site_contract_test.exs:170-192`
**Issue:** `contains_unclosed?/3` decides whether a call site sits inside an
open `assert_raise` lambda or `try do` block by checking whether the literal
substring `"end"` appears anywhere in the text between the last
`assert_raise`/`try do` occurrence and the call site — not by tracking `do`/
`end` nesting depth. Because Elixir syntactically requires every
`assert_raise ... fn -> ... end` and `try do ... rescue ... end` to close
with a literal `end` token, this is hard to trigger in practice with today's
code (confirmed: the real-tree sweep is 0 offenses, and the exemption's own
behaviour tests, including the "does not leak past its own end" case, all
pass). But the check is substring-based, not token-based: an intervening
word merely *containing* `end` as a substring (`append`, `depends`,
`extended`, a comment mentioning "backend") between an `assert_raise` and an
unrelated later call within the 300-byte window would cause
`contains_unclosed?` to report "closed" when it structurally isn't, in
either direction depending on phrasing. This is a robustness gap in a
detector whose stated design goal is "no escape hatch," not a currently
demonstrated false result.

**Fix:** Match `\bend\b` (word-boundary) rather than a bare substring, or
better, track `do`/`fn`/`end` balance the same way `walk_balanced/4` already
tracks paren balance, so the exemption is syntactic rather than lexical.
Not blocking — no false result reproduced against real code — but worth
hardening given the phase's own "no escape hatch" bar.

---

## Round 1 Findings (preserved)

_Reviewed: 2026-08-28T14:52:19Z — diff `02e6070a..HEAD`, plans 08–13._
_All three round-1 findings were already dispositioned by the orchestrator
before round 2 began; reproduced verbatim below for the record, unchanged._

### WR-01: `is_integer()` in `bin/classify-flake-run` accepts malformed strings with an interior dash

**File:** `bin/classify-flake-run:53-61`
**Issue:** The POSIX integer-validation helper's character-class check
(`*[!0-9-]*`) allows `-` anywhere in the string, and the subsequent `-*`
case only special-cases strings that *start* with `-`; anything else falls
through to the final `*)` arm and is accepted (`EXIT_CODE="1-2"` was
classified `flaky`). Not reachable in the wired workflow today (`EXIT_CODE`
and `headers_raw` are always clean digit strings), but a real defect in a
function whose stated purpose is being the last line of defense against
malformed input.

**Status: FIXED** (orchestrator, 2026-08-28). `is_integer()` now accepts `-`
only in leading position; locked in by a new case in
`flake_classifier_contract_test.exs` covering `1-2`, `-1-2`, `-`, and `1 2`,
verified non-vacuous (red when the fix is reverted).

### WR-02: Evidence-bundle completeness check in `ci.yml` is one-directional

**File:** `.github/workflows/ci.yml` (verify-capture, "Assert complete
evidence bundle" step)
**Issue:** Proposed making the check symmetric (every scorecard JSON must
have a matching `aria.yml`), on the premise that an orphan JSON scorecard
would go undetected.

**Status: REJECTED as a false positive** (orchestrator, 2026-08-28).
Measured on the committed evidence: 372 JSON / 54 aria.yml, with 318 JSON
files legitimately having no `aria.yml` (aria.yml covers only story cells;
scorecards exist for many more subjects). A symmetric assertion would fail
`verify-capture` on its first run. The existing one-directional check is
correct as written. No change made.

### IN-01: `optional_deps_contract_test.exs`'s `guarded?/1` checks only the file's first line, not that the guard actually wraps the offending directive

**File:** `test/threadline/optional_deps_contract_test.exs:76-81`
**Issue:** `guarded?/1` asserts the file's first non-blank line starts with
`"if Code.ensure_loaded?("` textually, without proving the guard's argument
matches the module actually referenced or that the guard's `end` encloses
the directive. Safe in practice today because a mismatch would fail to
compile, and `mix verify.compile_no_optional` is the real backstop.

**Status: ACCEPTED, no change** (orchestrator, 2026-08-28). Recorded, not
fixed; `mix verify.compile_no_optional` remains the authoritative guard.

---

_Reviewed: 2026-08-28T18:29:14Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
