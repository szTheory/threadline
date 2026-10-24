---
phase: 232-consolidated-reads-deprecations-and-the-bounded-default
plan: 04
subsystem: api
tags: [elixir, ecto, deprecation, api-contract, typespec, exdoc]

requires:
  - phase: 232-consolidated-reads-deprecations-and-the-bounded-default
    provides: "Plan 03's Threadline.row_history/3 (bounded default + cursor paging), Threadline.Query.RowReads.list/3 and page/3, Threadline.Query.LegacyOpts.cursor/1 and row_history/2, the D-12 arity-split deprecated row_history/4 on Threadline/Investigation"
provides:
  - "Threadline.Query.RowReads.audit_changes/3 -- the hidden raw read behind the deprecated history/3 (unbounded by default, plain AuditChange, HistoryLimit-validated :limit)"
  - "Threadline.Query.HistoryLimit accepts :infinity (validate!/1, apply/2)"
  - "Threadline.Query.LegacyOpts.history/1 and row_history_page/2"
  - "Threadline.history/3 and Threadline.Query.history/3 as one-line @deprecated delegates onto RowReads.audit_changes/3"
  - "Threadline.row_history_page/4, actor_window_page/3, correlation_bundle_page/3 (facade) as one-line @deprecated delegates onto their canonical base function with LegacyOpts"
  - "Threadline.Query.row_history/4 and row_history_page/4 now carry @deprecated and route through RowReads"
  - "Threadline.Investigation.row_history_page/4, actor_window_page/3, correlation_bundle_page/3 now carry @deprecated + per-arity @spec"
  - "test/threadline/deprecation_parity_test.exs -- exact __info__(:deprecated) inventory, per-arity @spec presence, visible @doc + deprecated metadata presence, and behavioral parity for every retired entry point, all reached only through apply/3"
affects: [232-05, 232-06]

actuals:
  tokens: 11643
  tasks: 2
  commits: 4
  plan_head_before: c545f37e01662ac177742d7c68394fa62580952c
  plan_head_after: 24d7e91b94ebdbf6d02d78b111cb97a954ae1bc5

tech-stack:
  added: []
  patterns:
    - "Multiple @spec attributes (one per arity) before a single def with \\ defaults -- Code.Typespec.fetch_specs/1 does NOT auto-generate reduced-arity specs for default-arg functions, so each retiring arity (row_history_page/2,3,4, actor_window_page/1,2,3, correlation_bundle_page/1,2,3, Query.row_history/2,3,4) needed its own explicit @spec line"
    - "Code.fetch_docs/1 registers exactly ONE docs_v1 entry per default-arg function, keyed at its highest arity, with a `defaults: N` metadata count naming how many lower arities it also documents -- a doc-presence check for a lower arity must search entries at-or-above it and subtract `defaults`, not look for an exact-arity match"
    - "LegacyOpts.row_history_page/2 extends the Plan 01/03 LegacyOpts one-function-per-retired-shape convention: validates the retired filter vocabulary, merges filters into opts, then reuses cursor/1 for the nil->:start mapping"

key-files:
  created: []
  modified:
    - lib/threadline.ex
    - lib/threadline/query.ex
    - lib/threadline/investigation.ex
    - lib/threadline/query/row_reads.ex
    - lib/threadline/query/legacy_opts.ex
    - lib/threadline/query/history_limit.ex
    - test/threadline/deprecation_parity_test.exs
    - test/threadline/query_test.exs
    - examples/threadline_phoenix/priv/scripts/incident_replay.exs
    - CHANGELOG.md

key-decisions:
  - "Investigation.row_history/4's deprecation message corrected from \"Use Threadline.Investigation.row_history/3 instead.\" to \"Use Threadline.row_history/3 instead.\" -- the plan's D-11 messages always name the PUBLIC Threadline replacement, never the hidden module's own name, since Investigation/Query are @moduledoc false and an adopter should never be pointed at them"
  - "Facade *_page delegates (row_history_page/4, actor_window_page/3, correlation_bundle_page/3) now call the facade's OWN base function (row_history/3, actor_window/3, correlation_bundle/3) instead of the now-deprecated Investigation.*_page -- D-13 forbids a delegate calling another deprecated function, and this also collapses to exactly one cursor-mode implementation per read family"
  - "HistoryLimit's error message widened to name :infinity (\"must be a positive integer or :infinity, got: ...\") rather than leaving the old text and silently accepting an undocumented extra value"

patterns-established:
  - "Deprecated multi-arity *_page functions: one @spec per retiring arity, @deprecated naming the single public replacement, and a one-line body that reroutes through a non-deprecated base + a LegacyOpts helper -- the same shape for all three families (row_history_page, actor_window_page, correlation_bundle_page) across all three modules (Threadline, Query, Investigation)"

requirements-completed: [API-08, API-01]  # shared with 232-05/06 (API-08) and 232-05 (API-01); requirements.ready-ids reports them not-yet-ready until the last declaring plan finishes

coverage:
  - id: D1
    description: "Threadline.history/3 and Threadline.Query.history/3 are deprecated one-line delegates onto Threadline.Query.RowReads.audit_changes/3, keeping the 0.12 unbounded default and plain AuditChange shape, proven over a 250-change row via apply/3 (never a direct call)"
    requirement: "API-08"
    verification:
      - kind: integration
        ref: "test/threadline/deprecation_parity_test.exs#describe history/3 (deprecated, D-02, D-04)"
        status: pass
    human_judgment: false
  - id: D2
    description: "row_history_page/2,3,4 (Threadline, Query, Investigation), actor_window_page/1,2,3, and correlation_bundle_page/1,2,3 are all deprecated one-line delegates onto their canonical base function with the nil/absent :cursor -> :start mapping preserved, proven first-page and two-exact-page-walk parity against the base function over 250-row/250-change fixtures"
    requirement: "API-08"
    verification:
      - kind: integration
        ref: "test/threadline/deprecation_parity_test.exs#describe row_history_page family (deprecated, D-04, D-11)"
        status: pass
      - kind: integration
        ref: "test/threadline/deprecation_parity_test.exs#describe actor_window_page family (deprecated, D-04, D-11)"
        status: pass
      - kind: integration
        ref: "test/threadline/deprecation_parity_test.exs#describe correlation_bundle_page family (deprecated, D-04, D-11)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Threadline.__info__(:deprecated), Threadline.Query.__info__(:deprecated) and Threadline.Investigation.__info__(:deprecated) each equal the exact expected {{name, arity}, message} inventory -- an added or dropped deprecation on any of the three modules turns this red"
    requirement: "API-08"
    verification:
      - kind: integration
        ref: "test/threadline/deprecation_parity_test.exs#describe exact deprecated inventories (D-11, API-08)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every deprecated {name, arity} on all three modules has a @spec (Code.Typespec.fetch_specs/1) and a visible @doc (not @doc false) carrying :deprecated metadata (Code.fetch_docs/1), so ExDoc shows the deprecation badge"
    requirement: "API-08"
    verification:
      - kind: integration
        ref: "test/threadline/deprecation_parity_test.exs#describe spec and doc presence on every deprecated entry point (D-11)"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D5
    description: "mix compile --warnings-as-errors and MIX_ENV=test mix compile --warnings-as-errors --force both stay clean -- nothing in lib/ or test/support calls a deprecated name -- while the full mix test suite stays green (2856 tests, 1 pre-existing deferred failure unrelated to this plan) and mix verify.example exits 0 (the example app's incident_replay.exs script no longer calls the now-deprecated history/3)"
    requirement: "API-01"
    verification:
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix compile --warnings-as-errors --force"
        status: pass
      - kind: other
        ref: "mix test (full suite)"
        status: pass
      - kind: other
        ref: "mix verify.example"
        status: pass
    human_judgment: false

duration: ~1h10min
completed: 2026-10-03
status: complete
---

# Phase 232 Plan 4: Deprecate every retired read entry point onto the consolidated reads, with an exact-inventory parity test Summary

**Every retired Threadline read entry point -- `history/3`, `row_history/4`, and all three `*_page` families across `Threadline`, `Query`, and `Investigation` -- is now a specced, documented, one-line `@deprecated` delegate onto its canonical replacement, proven by a new parity test suite that pins the exact `__info__(:deprecated)` inventory on all three modules.**

## Performance

- **Duration:** ~1h10min
- **Started:** 2026-10-03 (continuing directly after 232-03)
- **Completed:** 2026-10-03
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- `Threadline.Query.RowReads.audit_changes/3` (hidden): the 0.12 `history/3` body moved verbatim -- `Keyword.fetch!(:repo)`, `HistoryLimit.validate!`, `Query.history_query/3`, `repo.all` -- unbounded by default, returning plain `%AuditChange{}`
- `Threadline.Query.HistoryLimit` accepts `:infinity` in both `validate!/1` and `apply/2`; its error message now names `:infinity` as an accepted value
- `Threadline.Query.LegacyOpts.history/1` maps an absent or `nil` `:limit` to `:infinity`; `LegacyOpts.row_history_page/2` validates the retired filter vocabulary, merges filters into opts, and reuses `cursor/1` for the `nil` -> `:start` mapping
- `Threadline.history/3` and `Threadline.Query.history/3` are now one-line `@deprecated "Use Threadline.row_history/3 instead."` delegates onto `RowReads.audit_changes/3`, each keeping a visible `@doc` and a `@spec` returning `[AuditChange.t()]` -- the documented exception to the replacement's `LinkedChange` element type (D-02)
- `Threadline.row_history_page/4`, `actor_window_page/3`, `correlation_bundle_page/3` (facade) are now one-line `@deprecated` delegates calling the facade's own base function (`row_history/3`, `actor_window/3`, `correlation_bundle/3`) via `LegacyOpts.row_history_page/2` or `LegacyOpts.cursor/1`, each with per-arity `@spec` and a visible `@doc`
- `Threadline.Query.row_history/4` and `row_history_page/4` now carry `@deprecated "Use Threadline.row_history/3 instead."` and route through `RowReads.list/3` / `RowReads.page/3`
- `Threadline.Investigation.row_history/4`'s message is corrected to name the public `Threadline.row_history/3` (not the hidden module's own name); `row_history_page/4`, `actor_window_page/3`, `correlation_bundle_page/3` gain `@deprecated` and per-arity `@spec` (no body change -- they already routed through the local base function)
- The `Threadline` moduledoc's "Reading audit data" list now names only the non-deprecated read functions, with one sentence pointing at the deprecated delegates
- `test/threadline/deprecation_parity_test.exs`: one parity test per retired entry point over 250-row/250-change fixtures, the exact `__info__(:deprecated)` inventory for all three modules, `Code.Typespec.fetch_specs/1` presence for every deprecated `{name, arity}`, and `Code.fetch_docs/1` visible-doc + `:deprecated`-metadata presence -- every retired name reached only through `apply/3`
- `CHANGELOG.md` Unreleased Deprecations: bullets for `history/3`, `row_history_page`, `actor_window_page`, `correlation_bundle_page`

## Task Commits

Each task was committed as a RED/GREEN pair (both tasks `tdd="true"`):

1. **Task 1 RED: add failing deprecation-parity tests for history/3** - `5ff6b038` (test)
2. **Task 1 GREEN: deprecate history/3 onto RowReads.audit_changes/3** - `83c8175d` (feat)
3. **Task 2 RED: add failing parity tests for the remaining retired names** - `fd3090dd` (test)
4. **Task 2 GREEN: deprecate the remaining retired names, pin the exact inventory** - `24d7e91b` (feat)

**Plan metadata:** (next commit)

_No REFACTOR commits -- each task's GREEN implementation stayed minimal. Both GREEN commits also carry their deviation fixes (see below) rather than separate commits, since the deviations surfaced during the same GREEN cycle's verification run, before the commit was made._

## Files Created/Modified

- `lib/threadline/query/row_reads.ex` - new `audit_changes/3` (hidden raw read behind the deprecated `history/3`)
- `lib/threadline/query/history_limit.ex` - `validate!/1`/`apply/2` accept `:infinity`
- `lib/threadline/query/legacy_opts.ex` - new `history/1` and `row_history_page/2`
- `lib/threadline.ex` - `history/3` deprecated onto `RowReads.audit_changes/3`; `row_history_page/4`, `actor_window_page/3`, `correlation_bundle_page/3` deprecated onto their base function; moduledoc rewritten
- `lib/threadline/query.ex` - `history/3` deprecated onto `RowReads.audit_changes/3` (doc trimmed to keep the file at 762 lines); `row_history/4` and `row_history_page/4` now carry `@deprecated` and route through `RowReads`
- `lib/threadline/investigation.ex` - `row_history/4`'s message corrected; `row_history_page/4`, `actor_window_page/3`, `correlation_bundle_page/3` gain `@deprecated` + per-arity `@spec`
- `test/threadline/deprecation_parity_test.exs` - new file (`Threadline.DeprecationParityTest`): exact inventories, spec/doc presence, parity for every retired entry point
- `test/threadline/query_test.exs` - 7 `assert_raise` message assertions updated for `HistoryLimit`'s widened error text (deviation)
- `examples/threadline_phoenix/priv/scripts/incident_replay.exs` - `Threadline.history/3` call replaced with `Threadline.row_history/3` + `limit: :infinity` (deviation)
- `CHANGELOG.md` - Unreleased Deprecations: four new bullets

## Decisions Made

See `key-decisions` in the frontmatter: the Investigation message correction, rerouting facade `*_page` delegates onto their own base function instead of the now-deprecated Investigation `*_page`, and widening `HistoryLimit`'s error message to name `:infinity`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `HistoryLimit`'s widened error message broke three pinned `assert_raise` messages in `query_test.exs`**

- **Found during:** Task 1's GREEN verification (`mix test`)
- **Issue:** `HistoryLimit.validate!/1`'s error message changed from `":limit must be a positive integer, got: ..."` to `":limit must be a positive integer or :infinity, got: ..."` (needed so the new `:infinity` acceptance is self-documenting). Three tests in `test/threadline/query_test.exs` pinned the old exact string across 7 `assert_raise` call sites.
- **Fix:** Updated all 7 `assert_raise` message strings in `test/threadline/query_test.exs` to the new text.
- **Files modified:** test/threadline/query_test.exs
- **Verification:** `mix test test/threadline/query_test.exs` (101 tests, 0 failures)
- **Committed in:** 24d7e91b (Task 2 GREEN commit)

**2. [Rule 3 - Blocking] The example app's `incident_replay.exs` script called the newly-deprecated `Threadline.history/3`, and its compiler deprecation-warning text polluted the script's own JSON stdout, breaking `mix verify.example`**

- **Found during:** Task 2's GREEN verification (`mix verify.example`)
- **Issue:** `priv/scripts/incident_replay.exs` called `Threadline.history(Post, ..., repo: Repo)`, now deprecated. The deprecation warning's multi-line stacktrace text was captured as part of the script's stdout by `incident_replay_smoke_test.exs`, which expects each output line to be a JSON document -- `Jason.decode` failed on the warning text, failing 3 example-app tests and `mix verify.example` itself. The plan's own `<verification>` block requires `mix verify.example` to exit 0, so this is in scope (not deferred to Plan 05, which only covers `test/`-tree callers).
- **Fix:** Replaced the call with `Threadline.row_history(Post, ..., repo: Repo, limit: :infinity)`; the script only used `length(changes)`, which is identical for the `LinkedChange` list `row_history/3` returns.
- **Files modified:** examples/threadline_phoenix/priv/scripts/incident_replay.exs
- **Verification:** `mix verify.example` (130 tests, 0 failures, exit 0)
- **Committed in:** 24d7e91b (Task 2 GREEN commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking). **Impact on plan:** Both fixes were necessary consequences of this plan's own deprecations surfacing in code the plan's `<verification>` block already requires to stay green; no scope creep into Plan 05's test-tree migration (the example app's own `test/` files calling `Threadline.history/3` were left untouched, as planned).

## Issues Encountered

None beyond the two deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Every retired entry point across `Threadline`, `Threadline.Query` and `Threadline.Investigation` is now `@deprecated` with a spec, a visible doc, and a parity test; `lib/` and `test/support` compile clean under `--warnings-as-errors`.
- Plan 05 picks up the `test/` and example-app call-site migration (the deprecation warnings `mix test` currently tolerates as non-fatal) and extends the `--warnings-as-errors` gate to those trees.
- API-01 and API-08 stay open in REQUIREMENTS.md: API-01 is shared with 232-05 and API-08 with 232-05/06 (`requirements.ready-ids` reports them not-yet-ready); both will flip to Complete when their last declaring plan finishes.
- No blockers for 232-05.

## Self-Check: PASSED

- Created/modified files verified on disk: `lib/threadline/query/row_reads.ex`, `lib/threadline/query/legacy_opts.ex`, `lib/threadline/query/history_limit.ex`, `lib/threadline.ex`, `lib/threadline/query.ex`, `lib/threadline/investigation.ex`, `test/threadline/deprecation_parity_test.exs`, `test/threadline/query_test.exs`, `examples/threadline_phoenix/priv/scripts/incident_replay.exs`, `CHANGELOG.md`, this SUMMARY.
- Commits verified in `git log`: `5ff6b038`, `83c8175d`, `fd3090dd`, `24d7e91b`.
- Re-ran the plan's `<verification>` block: `mix test test/threadline/deprecation_parity_test.exs` (27 tests, 0 failures); `mix compile --warnings-as-errors` and `MIX_ENV=test mix compile --warnings-as-errors --force` both exit 0; full `mix test` (32 properties, 2856 tests, 1 pre-existing deferred failure, 0 attributable to this plan); `mix verify.example` (130 tests, 0 failures, exit 0); `mix verify.credo` (no issues); `MIX_ENV=dev mix docs --warnings-as-errors` (clean).
- Re-ran both tasks' own `<acceptance_criteria>` grep/test checks individually -- all pass: `grep -c "@deprecated"` is 5/3/4 on `lib/threadline.ex`/`lib/threadline/query.ex`/`lib/threadline/investigation.ex`; the moduledoc names `row_history/3` and none of the retired names; `test/threadline/deprecation_parity_test.exs` contains `apply(Threadline, :history,` and asserts `__info__(:deprecated)` plus `Code.Typespec.fetch_specs`.

---
*Phase: 232-consolidated-reads-deprecations-and-the-bounded-default*
*Completed: 2026-10-03*
