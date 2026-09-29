---
phase: 212-detection-and-adopter-twins
fixed_at: 2026-09-26T08:05:00Z
review_path: .planning/phases/212-detection-and-adopter-twins/212-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 1
skipped: 1
status: partial
---

# Phase 212: Code Review Fix Report

**Fixed at:** 2026-09-26T08:05:00Z
**Source review:** .planning/phases/212-detection-and-adopter-twins/212-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2 (WR-01, WR-02)
- Fixed: 1
- Skipped: 1

## Fixed Issues

### WR-01: `duplicate_capture_trigger`'s fix command is not fully qualified for a `public`-schema table

**Files modified:** `lib/threadline/health/trigger_findings.ex`, `test/threadline/health/trigger_findings_test.exs`
**Commit:** 0aa4178c
**Applied fix:** `duplicate_message/4` no longer derives its `--tables` argument from
`Naming.table_token/1` (which renders a bare table name for `public`). It now reuses the
existing `fix_command/2` helper, matching every other finding's fix-command construction
(`pk_drift_message/5`, `legacy_warning_message/1`) and satisfying D-14's "qualified form
everywhere, including `public`" requirement. The now-unused `Naming.table_token/1` call and
its `token` binding were removed from `duplicate_message/4`.

Added a new test, `"a public-schema table's duplicate finding uses the fully qualified fix
command"`, in the `duplicate_capture_trigger` describe block: it creates a duplicate-trigger
finding on a `public`-schema table and asserts the message contains
`mix threadline.gen.triggers --tables public.hlth_find_dup_public_t`. (The assertion locates
the specific finding by `code` and `table` rather than asserting a singleton list, because the
test DB's `public` schema already carries a pre-existing legacy-trigger fixture
(`threadline_ci_coverage_canary`) that also returns a finding when filtered to `schema:
"public"`.)

Verified: `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix credo
--strict` (both files), and the full `mix test test/threadline/health/trigger_findings_test.exs`
(23 tests, 0 failures) all pass. Full-suite and other gates re-run after both findings are
covered below.

## Skipped Issues

### WR-02: `Threadline.Query`'s doc edit removed the only pointer to the actual normalizer, without replacing it with an equally precise one

**File:** `lib/threadline/query.ex:380-384`
**Reason:** skipped — the finding's premise does not hold against the current source, so there
is nothing to fix without reintroducing the ExDoc autolink failure the prior phase-gate commit
(`acf5ca19`) deliberately avoided.

The finding claims `RowKey` "remains referenced by name in other parts of the same moduledoc
region that were not touched," making the anonymized wording at `history/3`'s doc
(`"internal row-key normalizer"`) inconsistent with the rest of the file. A full-repo search
(`grep -rn "RowKey" lib/`) shows the only occurrences of `RowKey` anywhere in `lib/` are the
`alias` declaration and the three `RowKey.match!/3` call sites (all executable code, not doc
prose) — there is no other docstring, moduledoc section, or `@doc` anywhere in `query.ex` (or
elsewhere in `lib/`) that names `RowKey` directly. `as_of/4`'s docstring, the nearest sibling
doc block, does not name any module either — it says only "raises the same `ArgumentError`
cases [as `history/3`]." So the current file is already internally consistent: `RowKey` is
named nowhere in public docs, and the wording at `history/3` is the only doc site describing
the normalizer.

Per the orchestrator's constraint for this finding: any fix must keep `MIX_ENV=dev mix docs
--warnings-as-errors` passing, and if the untouched parts of the moduledoc do not trigger
warnings (i.e., don't autolink), make wording consistent without reintroducing the autolink —
otherwise skip with rationale. Since there is no other prose reference to make consistent
*with*, no edit is needed or safely possible here: reintroducing `` `Threadline.Query.RowKey`
`` as a backtick-quoted module reference would autolink and fail
`MIX_ENV=dev mix docs --warnings-as-errors` (confirmed clean at 0aa4178c — `mix docs
--warnings-as-errors` ran successfully with the doc wording unchanged), exactly the failure
mode commit `acf5ca19` fixed. Recommend closing WR-02 as a documentation false-positive against
current `HEAD`, or re-triaging it as INFO if the reviewer wants the wording tightened in a
future pass without naming the module (e.g. "internal row-key normalizer (see
`Threadline.Query.RowKey`, `@moduledoc false`)" is still an autolink risk and was not attempted
here per the halt-on-hook-bypass constraint).

**Original issue:** The diff changed `` `Threadline.Query.RowKey.normalize!/2` `` to "via the
internal row-key normalizer" in `history/3`'s docstring, and the reviewer flagged this as
inconsistent with unspecified "other parts of the same moduledoc region" that allegedly still
name `RowKey`. No such other reference exists in the current source.

## Verification (full gate re-run after both findings processed)

All gates run in the main checkout (no worktree isolation was used for this fix pass, per the
orchestrator prompt's plain working-directory instructions — no `workflow.use_worktrees`
worktree-setup step was invoked).

- `mix compile --warnings-as-errors` — clean
- `mix format --check-formatted` — clean
- `mix credo --strict` — "3932 mods/funs, found no issues"
- `MIX_ENV=dev mix docs --warnings-as-errors` — clean (also confirms WR-02's skip rationale)
- `MIX_ENV=dev mix dialyzer` — "Total errors: 0, Skipped: 0, Unnecessary Skips: 0"
- `mix test` (full suite) — **9 properties, 2191 tests, 0 failures, 2 excluded**

No background test run left running.

---

_Fixed: 2026-09-26T08:05:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
