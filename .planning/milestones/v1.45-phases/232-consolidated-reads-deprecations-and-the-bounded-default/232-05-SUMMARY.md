---
phase: 232-consolidated-reads-deprecations-and-the-bounded-default
plan: 05
subsystem: api
tags: [elixir, ecto, deprecation, api-contract, testing]

requires:
  - phase: 232-consolidated-reads-deprecations-and-the-bounded-default
    provides: "Plan 04's exact-inventory @deprecated delegates on Threadline.history/3, row_history_page/4, actor_window_page/3, correlation_bundle_page/3 (facade, Query, Investigation), and Threadline.Query.RowReads.audit_changes/3"
provides:
  - "Threadline.Test.RowHistory.changes/3 -- the test-support helper every migrated main-suite test and example-app test now reads row history through (Threadline.row_history/3 forced to limit: :infinity)"
  - "Zero test/ or example-app callers of any retired read name outside deprecation_parity_test.exs's apply/3-only reach"
  - "mix test --warnings-as-errors and mix verify.example both clean (no deprecation warnings) across the whole repo"
affects: [232-06]

actuals:
  tokens: 12617
  tasks: 3
  commits: 3
  plan_head_before: ff4c662ded9bc8bb5301ae870d353aa4216e55b9
  plan_head_after: 4a2e50c7004b11efa5d78b007b91efd0ea481fd5

tech-stack:
  added: []
  patterns:
    - "Threadline.Test.RowHistory.changes/3: Keyword.put_new(opts, :limit, :infinity) before calling Threadline.row_history/3, then Enum.map(& &1.audit_change) -- gives migrated tests the old history/3 plain-%AuditChange{}, unbounded-by-default shape without reintroducing a deprecated call, while still letting a caller pass an explicit :limit through unchanged"
    - "Former *_page(schema, id, filters, opts) call sites become row_history/actor_window/correlation_bundle(schema_or_actor, filters_or_id, opts) with cursor: :start for the first page and cursor: page.cursor to continue -- filters fold into opts, matching D-10/D-11"
    - "row_history/3's :limit semantics are NOT a drop-in replacement for history/3's: limit: nil now raises (RowReads.list/3's Keyword.fetch/2 branch), and row-key matching (base_query/3) runs before :limit validation, the reverse of history/3's HistoryLimit-first order -- tests asserting those specific history/3 behaviors were rewritten to match row_history/3's actual behavior, not preserved"

key-files:
  created:
    - test/support/row_history.ex
  modified:
    - test/threadline/continuity_brownfield_test.exs
    - test/threadline/query_test.exs
    - test/threadline/investigation_test.exs
    - test/threadline/upgrade_backfill_test.exs
    - test/threadline/query/as_of_property_test.exs
    - test/threadline/query/row_key_composite_test.exs
    - test/threadline/query/row_key_legacy_test.exs
    - test/threadline/query/row_key_override_test.exs
    - test/threadline/query/row_key_read_test.exs
    - test/threadline/query/row_key_types_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs
    - guides/incident-playbook.md
    - test/threadline/incident_playbook_doc_contract_test.exs

key-decisions:
  - "query_test.exs's three history/3-specific :limit assertions (the nil==unbounded equivalence, the empty-history nil case, and the id-vs-limit validation order) were rewritten against row_history/3's real behavior rather than preserved as history/3-shaped assertions: limit: nil now raises ArgumentError, and row-key matching precedes :limit validation (reverse order from history/3). The deprecated history/3's own historical behavior stays pinned by Plan 04's deprecation_parity_test.exs, so no coverage was lost."
  - "guides/incident-playbook.md's 'Diagnosis (API)' snippet and its doc-contract test assertion were migrated from Threadline.history/3 to Threadline.row_history/3 + limit: :infinity + Enum.map(& &1.audit_change), even though neither file is in this plan's files_modified list -- the plan's own Task 2 <verify> grep (test/-wide, not scoped to files_modified) caught the guide-quoting test's string literal as a false call-site match, and the plan's own verification block requires that grep to print nothing (Rule 3 - blocking, same category as Plan 04's incident_replay.exs fix)."

patterns-established:
  - "A test-support module that forces limit: :infinity via Keyword.put_new/3 (not Keyword.put/3) is the reusable shape for 'give me the old unbounded history/3 behavior through the new bounded-by-default function' -- an explicit caller-supplied :limit (valid or invalid) still passes through untouched."

requirements-completed: [API-01, API-08]  # API-01 and API-08 were also declared by 232-04; this is the last plan declaring either, so requirements.ready-ids reports both ready now.

coverage:
  - id: D1
    description: "Threadline.Test.RowHistory.changes/3 reads row history unbounded through Threadline.row_history/3 (never calling the deprecated history/3), proven by continuity_brownfield_test.exs under --warnings-as-errors"
    requirement: "API-08"
    verification:
      - kind: unit
        ref: "test/threadline/continuity_brownfield_test.exs#history is empty at T0 until first audited write after trigger install"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every remaining main-suite test/ caller of history/3, Query.history/3, row_history_page/actor_window_page/correlation_bundle_page is rewritten onto row_history/3, RowReads.audit_changes/3, or the base function + cursor: -- the retired-name grep over test/ (outside deprecation_parity_test.exs) prints nothing"
    requirement: "API-08"
    verification:
      - kind: other
        ref: "bash -c '! grep -rnE \"Threadline\\.(history|row_history_page|actor_window_page|correlation_bundle_page)\\(|Query\\.(history|row_history|row_history_page)\\(|Investigation\\.(row_history_page|actor_window_page|correlation_bundle_page)\\(\" test | grep -v deprecation_parity_test'"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix compile --warnings-as-errors --force"
        status: pass
    human_judgment: false
  - id: D3
    description: "as_of_property_test.exs's :limit-prefix property reads the unbounded baseline via Threadline.Query.RowReads.audit_changes/3 with limit: :infinity explicit (never relying on any default), and the prefix case passes limit: n explicit -- the v1.44 history property stays green"
    requirement: "API-01"
    verification:
      - kind: other
        ref: "mix test test/threadline/query/as_of_property_test.exs (2 properties)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The example app's shape_fixtures_round_trip_test.exs no longer calls history/3 (9 call sites migrated to row_history/3 + limit: :infinity + Enum.map); mix verify.example exits 0 and the example-app retired-name grep prints nothing"
    requirement: "API-08"
    verification:
      - kind: other
        ref: "mix verify.example"
        status: pass
      - kind: other
        ref: "bash -c '! grep -rnE \"...\" examples/threadline_phoenix/lib examples/threadline_phoenix/test examples/threadline_phoenix/priv'"
        status: pass
    human_judgment: false
  - id: D5
    description: "Full mix test --warnings-as-errors stays green across the repo (no leftover deprecation warnings from any unmigrated test/ file), and mix verify.credo is clean"
    requirement: "API-01"
    verification:
      - kind: other
        ref: "mix test --warnings-as-errors (full suite)"
        status: pass
      - kind: other
        ref: "mix verify.credo"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-10-03
status: complete
---

# Phase 232 Plan 5: Migrate test/ and the example app off every retired read name Summary

**Every `test/` and example-app caller of `history/3`, `Query.history/3`, `row_history_page`, `actor_window_page`, and `correlation_bundle_page` now reads through the canonical `Threadline.row_history/3` (via a new `Threadline.Test.RowHistory` helper), `Threadline.Query.RowReads.audit_changes/3`, or `cursor:` paging on the base function -- `mix test --warnings-as-errors` and `mix verify.example` are both clean, and the only remaining retired-name references under `test/` are the intentional `apply/3` calls inside `deprecation_parity_test.exs`.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-10-03 (continuing directly after 232-04)
- **Completed:** 2026-10-03
- **Tasks:** 3
- **Files modified:** 14 (1 created, 13 modified)

## Accomplishments

- `test/support/row_history.ex` (new): `Threadline.Test.RowHistory.changes/3` -- forces `limit: :infinity` via `Keyword.put_new/3` before calling `Threadline.row_history/3`, then maps `LinkedChange` down to plain `AuditChange` via `& &1.audit_change`. This is the one helper every migrated test now reads unbounded row history through.
- `test/threadline/continuity_brownfield_test.exs` migrated end-to-end as the Task 1 tracer, proving the migration path under `--warnings-as-errors` before the bulk rewrite.
- `test/threadline/query_test.exs`: 25 `Threadline.history(` call sites rewritten to `RowHistory.changes(`; three tests specifically exercising `history/3`'s own `:limit` semantics were rewritten against `row_history/3`'s real (different) behavior -- `limit: nil` now asserts a raise instead of unbounded, and the id-vs-limit validation-order test now asserts the id-matching error fires first (reverse of `history/3`'s order).
- `test/threadline/upgrade_backfill_test.exs`, `test/threadline/query/row_key_types_test.exs`, `row_key_composite_test.exs`, `row_key_legacy_test.exs`, `row_key_override_test.exs`: all `Threadline.history(` call sites rewritten to `RowHistory.changes(`.
- `test/threadline/investigation_test.exs`: all `row_history_page/4`, `actor_window_page/3`, `correlation_bundle_page/3` call sites rewritten to their base function (`row_history/3`, `actor_window/3`, `correlation_bundle/3`) with `cursor: :start` for the first page and `cursor: page.cursor` to continue.
- `test/threadline/query/row_key_read_test.exs`: both `Threadline.history(` and `Threadline.row_history_page(` call sites migrated (the latter to `Threadline.row_history/3` + `cursor:`).
- `test/threadline/query/as_of_property_test.exs`: the `:limit`-prefix property now reads the unbounded baseline via `Threadline.Query.RowReads.audit_changes/3` with `limit: :infinity` explicit, and the prefix case with `limit: n` explicit -- the plain-`AuditChange` baseline the deprecated `Query.history/3` used to provide.
- `examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs`: all 9 `Threadline.history(` call sites replaced with `Threadline.row_history(..., limit: :infinity) |> Enum.map(& &1.audit_change)` (the example app has no access to the main suite's `test/support`).
- `guides/incident-playbook.md` + `test/threadline/incident_playbook_doc_contract_test.exs` (deviation, Rule 3): the guide's "Diagnosis (API)" snippet and the doc-contract test asserting it both named `Threadline.history/3`; migrated to `Threadline.row_history/3` + `limit: :infinity` + `Enum.map(& &1.audit_change)`.

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): add Threadline.Test.RowHistory and migrate continuity_brownfield_test** - `4d67fde1` (test)
2. **Task 2: migrate the remaining main-suite callers (history/3, Query.history/3, *_page)** - `f357e314` (test)
3. **Task 3: migrate the example app callers and close the warnings gate for the example** - `4a2e50c7` (test)

**Plan metadata:** (next commit)

## Files Created/Modified

- `test/support/row_history.ex` - new `Threadline.Test.RowHistory.changes/3`
- `test/threadline/continuity_brownfield_test.exs` - migrated off `Threadline.history/3`
- `test/threadline/query_test.exs` - 25 call sites migrated; 3 tests rewritten to `row_history/3`'s actual `:limit`/id-validation-order semantics
- `test/threadline/investigation_test.exs` - `*_page` call sites migrated to base function + `cursor:`
- `test/threadline/upgrade_backfill_test.exs` - call sites migrated
- `test/threadline/query/as_of_property_test.exs` - migrated to `RowReads.audit_changes/3`
- `test/threadline/query/row_key_composite_test.exs` - call sites + one `row_history_page` migrated
- `test/threadline/query/row_key_legacy_test.exs` - call sites migrated
- `test/threadline/query/row_key_override_test.exs` - call sites migrated
- `test/threadline/query/row_key_read_test.exs` - `history/3` and `row_history_page/4` call sites migrated
- `test/threadline/query/row_key_types_test.exs` - call sites migrated
- `examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs` - 9 call sites migrated
- `guides/incident-playbook.md` - "Diagnosis (API)" snippet migrated (deviation)
- `test/threadline/incident_playbook_doc_contract_test.exs` - assertion updated to match (deviation)

## Decisions Made

See `key-decisions` in the frontmatter: the three `query_test.exs` behavior-divergence rewrites, and the out-of-files_modified guide/doc-contract fix required by the plan's own verify gate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] guides/incident-playbook.md and its doc-contract test still named the now-deprecated `Threadline.history/3`, which the plan's own Task 2 retired-name grep (run over all of `test/`, not scoped to `files_modified`) caught as a false call-site match**

- **Found during:** Task 2's verification run (the plan's own grep gate over `test/`)
- **Issue:** `test/threadline/incident_playbook_doc_contract_test.exs` asserts `content =~ "Threadline.history("` against `guides/incident-playbook.md`'s "Diagnosis (API)" code snippet. Neither file is in this plan's `files_modified` list, but the plan's Task 2 `<verify>` block runs its retired-name grep over the whole `test/` tree (excluding only `deprecation_parity_test.exs` by name), so this string literal surfaced as a failing match and blocked the gate the plan itself requires to pass.
- **Fix:** Updated the guide's snippet from `Threadline.history(MyApp.User, user_id, repo: MyApp.Repo)` to `Threadline.row_history(MyApp.User, user_id, repo: MyApp.Repo, limit: :infinity) |> Enum.map(& &1.audit_change)`, and updated the doc-contract test's assertion from `"Threadline.history("` to `"Threadline.row_history("`.
- **Files modified:** guides/incident-playbook.md, test/threadline/incident_playbook_doc_contract_test.exs
- **Verification:** `mix test test/threadline/incident_playbook_doc_contract_test.exs` (8 tests, 0 failures); the full Task 2 retired-name grep over `test/` then prints nothing.
- **Committed in:** f357e314 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking). **Impact on plan:** The fix was a direct, necessary consequence of the plan's own verification requirement (the test/-wide grep gate), not scope creep -- no other guide or doc file was touched.

## Issues Encountered

None beyond the deviation above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `lib/`, `test/` and the example app are now all clean under `--warnings-as-errors`; the only remaining retired-name references anywhere under `test/` are the intentional `apply/3` calls in `deprecation_parity_test.exs` (Plan 04), which exist specifically to exercise the deprecated code paths without triggering a compile-time warning.
- D-13 (nothing internal calls a deprecated name) is now fully satisfied across `lib/`, `test/`, and the example app (SC4's internal-caller half).
- The v1.44 history properties (`as_of_property_test.exs`) stay green on an explicitly unbounded read (`limit: :infinity`), completing the v1.44-property half of SC2/API-01.
- API-01 and API-08 both flip to Complete in REQUIREMENTS.md with this plan (the last plan declaring either).
- No blockers for 232-06.

## Self-Check: PASSED

- Created/modified files verified on disk: `test/support/row_history.ex`, `test/threadline/continuity_brownfield_test.exs`, `test/threadline/query_test.exs`, `test/threadline/investigation_test.exs`, `test/threadline/upgrade_backfill_test.exs`, `test/threadline/query/as_of_property_test.exs`, `test/threadline/query/row_key_composite_test.exs`, `test/threadline/query/row_key_legacy_test.exs`, `test/threadline/query/row_key_override_test.exs`, `test/threadline/query/row_key_read_test.exs`, `test/threadline/query/row_key_types_test.exs`, `examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs`, `guides/incident-playbook.md`, `test/threadline/incident_playbook_doc_contract_test.exs`, this SUMMARY.
- Commits verified in `git log`: `4d67fde1`, `f357e314`, `4a2e50c7`.
- Re-ran the plan's `<verification>` block: `MIX_ENV=test mix compile --warnings-as-errors --force` exits 0; full `mix test --warnings-as-errors` (32 properties, 2856 tests, 1 pre-existing failure in `audit_indexing_doc_contract_test.exs` documented in this phase's `deferred-items.md`, unrelated to this plan); `mix verify.example` exits 0 (130 tests, 0 failures); the retired-name grep over `test/` (outside `deprecation_parity_test.exs`) and over `examples/threadline_phoenix/{lib,test,priv}` both print nothing; `mix verify.credo` clean (5073 mods/funs, no issues).
- Re-ran each task's own `<acceptance_criteria>` individually -- all pass: `test/support/row_history.ex` contains `limit, :infinity`; `continuity_brownfield_test.exs` has no `Threadline.history(` call; `query_test.exs` grep for `Threadline.history(` outside the parity test prints nothing; `as_of_property_test.exs` contains `RowReads.audit_changes(` and `limit: :infinity`; `examples/threadline_phoenix` grep for `Threadline.history(` prints nothing.

---
*Phase: 232-consolidated-reads-deprecations-and-the-bounded-default*
*Completed: 2026-10-03*
