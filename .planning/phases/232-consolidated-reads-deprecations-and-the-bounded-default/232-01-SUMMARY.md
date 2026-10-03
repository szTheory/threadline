---
phase: 232-consolidated-reads-deprecations-and-the-bounded-default
plan: 01
subsystem: api
tags: [elixir, ecto, pagination, keyset-cursor, api-contract]

requires:
  - phase: 231-facade-topology-and-the-capture-semantics-edge
    provides: hidden Threadline.Query/Investigation modules, ActionHydration, facade-only docs
provides:
  - Threadline.Page — the one paged-read return shape (entries, cursor, has_more)
  - Cursors.change_page/2 and Cursors.validate_page_cursor!/1 — exact has_more + :start/nil cursor rules
  - Threadline.Query.LegacyOpts.cursor/1 — nil-to-:start compat mapping for the soon-retired *_page helpers
  - timeline_page/2, row_history_page/4, actor_window_page/3, correlation_bundle_page/3 and the export
    stream/timeline LiveView all moved onto Threadline.Page
  - Threadline.Query.TimelinePage deleted with no shim
affects: [232-02-actor-history-page, 232-03, 232-06]

actuals:
  tokens: 9399
  tasks: 3
  commits: 5
  plan_head_before: 30016de76d182dfae02930fda3ea285ed5f045b6
  plan_head_after: 4ac083379414e58d1b955292ccbe05a00418fedf

tech-stack:
  added: []
  patterns:
    - "page_size + 1 fetch trimmed by Cursors.change_page/2 for exact has_more (copies the proven actor_history_trim/3 technique)"
    - "LegacyOpts.cursor/1 isolates the 0.12 nil-means-start compat mapping from the stricter new cursor rule"

key-files:
  created:
    - lib/threadline/page.ex
    - lib/threadline/query/legacy_opts.ex
    - test/threadline/page_test.exs
  modified:
    - lib/threadline/query.ex
    - lib/threadline/query/cursors.ex
    - lib/threadline/export.ex
    - lib/threadline/investigation.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline.ex
    - mix.exs
    - test/support/keyset_model.ex
    - test/threadline/query_test.exs
    - test/threadline/investigation_test.exs
    - test/threadline/query/cursors_property_test.exs
    - test/threadline/query/row_key_read_test.exs
    - test/threadline/readme_doc_contract_test.exs
    - test/threadline/public_surface_contract_test.exs
    - guides/getting-started-saas.md
    - CHANGELOG.md

key-decisions:
  - "Threadline.Query.TimelinePage => Threadline.Page registered in public_surface_contract_test.exs's @renamed_modules so the CHANGELOG's historical reference to the deleted module stays a known reference — same mechanism the project already uses for FilterParams/Scope"
  - "Pulled the public_surface_contract_test.exs @hidden_module_child_structs edit (plan's Task 3 action) forward so Task 2's own grep-based acceptance criterion (no TimelinePage references) could pass without leaving a known-failing intermediate state"

patterns-established:
  - "LegacyOpts module as the single place 0.12 nil-cursor compatibility lives, separate from the stricter D-07 rule on new call sites"

requirements-completed: []  # API-03 is shared with 232-02/03/06; requirements.ready-ids reported 0/1 ready — stays open until the last declaring plan finishes

coverage:
  - id: D1
    description: "timeline_page/2 returns %Threadline.Page{entries, cursor, has_more} with exact has_more on every boundary (5/2, 4/2 exact-multiple, 0 rows, ties, :start/nil cursor rules, uppercase UUID, full-walk-equals-timeline/2)"
    requirement: "API-03"
    verification:
      - kind: integration
        ref: "test/threadline/page_test.exs"
        status: pass
      - kind: integration
        ref: "test/threadline/query_test.exs#describe timeline_page/2"
        status: pass
    human_judgment: false
  - id: D2
    description: "row_history_page/4, actor_window_page/3, correlation_bundle_page/3 and export's stream_changes/2 all moved onto Threadline.Page; TimelinePage deleted with no shim"
    requirement: "API-03"
    verification:
      - kind: integration
        ref: "test/threadline/investigation_test.exs"
        status: pass
      - kind: integration
        ref: "test/threadline/export_test.exs#describe stream_changes/2"
        status: pass
      - kind: unit
        ref: "grep -rn TimelinePage lib test (only the historical @renamed_modules pin remains)"
        status: pass
    human_judgment: false
  - id: D3
    description: "cursors_property_test.exs timeline property asserts the D-08 fixed boundary (no empty page when n > 0, exactly [[]] when n == 0, page count == ceil(n/page_size))"
    requirement: "API-03"
    verification:
      - kind: integration
        ref: "test/threadline/query/cursors_property_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "Threadline.Page is a visible, documented, since-1.0.0 module grouped under Data Types; facade doc, guide line, and CHANGELOG describe the new shape"
    requirement: "API-03"
    verification:
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs"
        status: pass
      - kind: integration
        ref: "test/threadline/getting_started_saas_doc_contract_test.exs"
        status: pass
      - kind: integration
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false

duration: 65min
completed: 2026-10-03
status: complete
---

# Phase 232 Plan 01: Threadline.Page and the exact-has_more timeline/row-history pagers Summary

**`%Threadline.Page{entries, cursor, has_more}` replaces `Threadline.Query.TimelinePage` across every change-read pager, with `has_more` now exact via a `page_size + 1` keyset fetch.**

## Performance

- **Duration:** 65 min
- **Started:** 2026-10-03T17:09Z (approx, session start)
- **Completed:** 2026-10-03
- **Tasks:** 3
- **Files modified:** 19 (3 created, 16 modified)

## Accomplishments

- `Threadline.Page` — a new, documented (`since: "1.0.0"`), grouped struct (`entries`, `cursor`, `has_more`) that is now the one return shape for every change-read pager
- `Threadline.Query.Cursors.change_page/2` trims a `page_size + 1` keyset fetch into an exact-`has_more` page (D-08): a page that exactly fills `page_size` never falsely carries a cursor — fixes the old `timeline_page_next_cursor/2` boundary bug
- `Threadline.Query.Cursors.validate_page_cursor!/1` enforces D-07: `cursor: :start` (or an omitted key) begins a walk, `cursor: nil` raises `ArgumentError` naming `:start`
- `timeline_page/2`, `row_history_page/4`, `actor_window_page/3`, `correlation_bundle_page/3`, `Export.stream_changes/2`, and the operator timeline LiveView all moved onto `Threadline.Page`
- `Threadline.Query.TimelinePage` is deleted with no shim — a struct pattern match cannot be deprecated (D-05)
- New `Threadline.Query.LegacyOpts.cursor/1` isolates the 0.12 "absent/nil cursor means first page" compatibility mapping so the soon-retired `*_page` helpers keep working while every other paged read enforces the stricter D-07 rule
- `test/support/keyset_model.ex`'s `walk_timeline/2` now drives the real `Cursors.change_page/2` over a `page_size + 1` in-memory fetch, and `cursors_property_test.exs`'s timeline property asserts the fixed boundary (no empty page when `n > 0`, exactly `[[]]` when `n == 0`, page count `== ceil(n / page_size)`)
- `mix.exs`, the facade doc, the SaaS guide line, and `CHANGELOG.md`'s Unreleased Breaking changes all describe the new shape

## Task Commits

Each task was committed atomically (plus one post-task fix found via the full suite):

1. **Task 1 RED: add failing page_test.exs** - `96644d30` (test)
2. **Task 1 GREEN: timeline_page/2 returns Threadline.Page with exact has_more** - `4b636efa` (feat)
3. **Task 2: move row_history_page and the Investigation pagers onto Page; delete TimelinePage** - `30879d29` (feat)
4. **Task 3: registries, facade docs, guide line and CHANGELOG** - `4a0ad7a3` (docs)
5. **Post-task fix: strip planning vocabulary from lib/ comments** - `4ac08337` (fix)

**Plan metadata:** (this commit)

_No REFACTOR commit — GREEN was already minimal; the full-suite fix above was the only post-GREEN change._

## Files Created/Modified

- `lib/threadline/page.ex` - `%Threadline.Page{entries, cursor, has_more}` struct, `t/1`, `t/0`, `cursor/0`, `change_cursor/0`, `actor_cursor/0` types
- `lib/threadline/query/legacy_opts.ex` - `Threadline.Query.LegacyOpts.cursor/1`, the 0.12 nil→:start compat mapping
- `lib/threadline/query/cursors.ex` - `change_page/2`, `validate_page_cursor!/1`; deleted `timeline_page_next_cursor/2`
- `lib/threadline/query.ex` - `timeline_page/2` and `row_history_page/4` fetch `page_size + 1` and return `Threadline.Page`; `TimelinePage` module deleted
- `lib/threadline/export.ex` - `stream_changes/2` walks the new `Threadline.Page` shape
- `lib/threadline/investigation.ex` - `row_history_page/4`, `actor_window_page/3`, `correlation_bundle_page/3` route cursor through `LegacyOpts.cursor/1`; `linked_page/2` matches `%Threadline.Page{}`
- `lib/threadline/operator_surface/live/timeline_live.ex` - reads `page.cursor` instead of `page.next_cursor`
- `lib/threadline.ex` - `timeline_page/2` doc + `@spec` updated to `Threadline.Page.t(AuditChange.t())`
- `mix.exs` - "Data Types" group: `TimelinePage` removed, `Threadline.Page` added
- `test/threadline/page_test.exs` - new test file: struct shape, exact-boundary (5/2, 4/2), empty, ties, `:start`/`nil` cursor rules, UUID casing, full-walk-equals-`timeline/2`
- `test/support/keyset_model.ex` - `walk_timeline/2` drives `Cursors.change_page/2` over a `page_size + 1` fetch
- `test/threadline/query/cursors_property_test.exs` - timeline property asserts the D-08 fixed boundary
- `test/threadline/investigation_test.exs`, `test/threadline/query/row_key_read_test.exs`, `test/threadline/readme_doc_contract_test.exs` - `.cursor`/`.has_more`/`%Threadline.Page{}` throughout
- `test/threadline/public_surface_contract_test.exs` - `TimelinePage` removed from `@hidden_module_child_structs`; new `Threadline.Page` visibility/grouping/`since` test; `TimelinePage => Page` added to `@renamed_modules`
- `guides/getting-started-saas.md` - "continue with `first_page.cursor` while `first_page.has_more` is true"
- `CHANGELOG.md` - Unreleased Breaking changes documents the `TimelinePage` removal and the new shape

## Decisions Made

- Registered `Threadline.Query.TimelinePage => Threadline.Page` in `public_surface_contract_test.exs`'s `@renamed_modules` register rather than inventing new infrastructure — this is a straight deletion, not a rename, but the register's three assertions (old gone, new compiled, changelog still names the old one) are exactly what a documented breaking deletion needs, and the project already uses this exact mechanism for `FilterParams`/`Scope`.
- Pulled one line of Task 3's work (removing `TimelinePage` from `@hidden_module_child_structs`) forward into Task 2's commit, because Task 2's own acceptance criterion ("`grep -rn TimelinePage lib test` prints nothing") could not otherwise pass without it — the plan's task boundary put that file under Task 3 while Task 2's gate implicitly depended on it. No functional code moved; only that one list-entry removal.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Planning-vocabulary comments in lib/ rejected by release_artifact_contract_test.exs**

- **Found during:** a full `mix test` run after all three tasks' commits (not part of any task's own `<verify>` command, which only exercises the files named in that task)
- **Issue:** `lib/threadline/query/cursors.ex` and `lib/threadline/query/legacy_opts.ex` carried decision-id comments (`D-07`, `D-08`, `D-11`) explaining the cursor/legacy-opts rationale. `test/threadline/release_artifact_contract_test.exs` enforces the plan's own prohibition ("lib/ source and comments must not contain planning vocabulary") and failed on exactly those two files.
- **Fix:** Rewrote both comments as durable domain rationale with no decision-id references; behavior unchanged.
- **Files modified:** lib/threadline/query/cursors.ex, lib/threadline/query/legacy_opts.ex
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs test/threadline/source_size_contract_test.exs` — 37/0
- **Commit:** 4ac08337

---

**Total deviations:** 1 auto-fixed (1 bug). **Impact on plan:** No scope creep — the fix only removed planning vocabulary the plan's own prohibition forbids; no behavior changed.

## Issues Encountered

- **Pre-existing, out-of-scope failing test (not fixed, logged to deferred-items.md):** `test/threadline/audit_indexing_doc_contract_test.exs` expects the heading `## Timeline and Threadline.Query` in `guides/audit-indexing.md`, but the guide already reads `## Timeline and Threadline.timeline/2` since Phase 231's facade-hiding commit (`d1609504`), confirmed via `git show 30016de7:...` to predate this plan entirely. Neither file is in this plan's `files_modified` list. Logged to `.planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/deferred-items.md` per scope-boundary rules rather than fixed here.
- A `git stash` + `git checkout <old-commit> -- .` probe used mid-session to confirm the above pre-existing failure briefly reverted the working tree to the plan's start-of-phase state. Recovered immediately via `git checkout HEAD -- .` plus re-applying the stashed diff with `git apply` (not a `git stash` subcommand) — verified byte-for-byte against the stash's own diff, then re-ran the full affected test slice (303 tests, 0 failures) before continuing. No commit was lost; `.planning/config.json` was never staged or modified.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Threadline.Page` is live and is the template Plan 02 (`actor_history/2`) builds on for `Threadline.Query.ActorHistoryPage`'s equivalent move.
- API-03 stays open in REQUIREMENTS.md: it is shared with 232-02/03/06 (`requirements.ready-ids` reported 0/1 ready) and will flip to Complete when the last of those plans finishes.
- No blockers for 232-02.

---
*Phase: 232-consolidated-reads-deprecations-and-the-bounded-default*
*Completed: 2026-10-03*
