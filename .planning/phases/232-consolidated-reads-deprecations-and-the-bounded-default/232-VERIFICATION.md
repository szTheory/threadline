---
phase: 232-consolidated-reads-deprecations-and-the-bounded-default
verified: 2026-10-03T22:30:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-01-PLAN.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-01-SUMMARY.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-02-PLAN.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-02-SUMMARY.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-03-PLAN.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-03-SUMMARY.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-04-PLAN.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-04-SUMMARY.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-05-PLAN.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-05-SUMMARY.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-06-PLAN.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-06-SUMMARY.md"
  - "CHANGELOG.md"
  - "README.md"
  - "guides/audit-indexing.md"
  - "guides/brownfield-continuity.md"
  - "guides/domain-reference.md"
  - "guides/getting-started-saas.md"
  - "guides/how-threadline-works.md"
  - "guides/incident-playbook.md"
  - "guides/integration-contracts.md"
  - "guides/operator-surface.md"
  - "guides/production-checklist.md"
  - "guides/telemetry.md"
  - "guides/upgrade-path.md"
  - "guides/upgrading-to-0.11.md"
  - "lib/threadline.ex"
  - "lib/threadline/export.ex"
  - "lib/threadline/investigation.ex"
  - "lib/threadline/operator_surface/live/actor_live.ex"
  - "lib/threadline/operator_surface/live/row_history_component.ex"
  - "lib/threadline/operator_surface/live/timeline_live.ex"
  - "lib/threadline/page.ex"
  - "lib/threadline/query.ex"
  - "lib/threadline/query/cursors.ex"
  - "lib/threadline/query/history_limit.ex"
  - "lib/threadline/query/legacy_opts.ex"
  - "lib/threadline/query/row_reads.ex"
  - "lib/threadline/telemetry.ex"
  - "mix.exs"
covered_digest: "v1:sha256:b12f1bc2856fdca00ef8b202730e910399de7f5a4278276fc417bfce99aa7ce3"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 232: Consolidated Reads, Deprecations and the Bounded Default Verification Report

**Phase Goal:** An adopter reads a row's history through one function with keyword opts. By default it is bounded, the cursor path proves completeness, and truncation is observable. Every paged read returns one `Page` shape. Internal helpers are out of the docs. Any adopter still on a retired name gets a working call and one compiler warning naming the replacement.
**Verified:** 2026-10-03
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criteria) | Status | Evidence |
|---|-----------------------------------|--------|----------|
| 1 | SC1 — `Threadline.row_history/3` with no options returns exactly 200 changes newest-first as a bare list; `limit: n`/`limit: :infinity` override; cursor-walk == `limit: :infinity`; `:limit`+`:cursor` raises `ArgumentError` | ✓ VERIFIED | `lib/threadline/query/row_reads.ex` (`list/3`, `page/3`, `@default_limit 200`); `lib/threadline/investigation.ex:30-62` (opts-only `row_history/3`, `Keyword.has_key?(opts, :cursor)` dispatch, explicit `:limit`+`:cursor` → `ArgumentError`); exercised by `test/threadline/row_history_test.exs` (29 tests) — `mix test test/threadline/row_history_test.exs` 0 failures (ran in full-suite run below) |
| 2 | SC2 — `[:threadline, :row_history, :truncated]` fires on cap hit, registered + leak-checked, export/`as_of` stay unbounded, v1.44 properties green | ✓ VERIFIED | `lib/threadline/query/row_reads.ex:118-128` (`fetch_default/4`: fetches 201, drops extra, never `length == limit`); `lib/threadline/telemetry.ex:58,154,362-371` (registered in `@events`, metadata `%{schema: atom}` only); `test/threadline/telemetry_registry_contract_test.exs` drives `drive_row_history_truncated!/0` through the leak-checked `assert_metadata_value_types!/2`; `test/threadline/query/as_of_property_test.exs` (2 properties) read the unbounded baseline via `RowReads.audit_changes/3` with `limit: :infinity` explicit — full-suite run confirms 32 properties, 0 failures |
| 3 | SC3 — every paged read returns `%Threadline.Page{entries, cursor, has_more}`; `TimelinePage`/`ActorHistoryPage` deleted; `timeline/2`+`timeline_page/2` is the only paired name; `actor_history/2`/`actor_window/3` docs cross-link | ✓ VERIFIED | `lib/threadline/page.ex` (struct, `since: "1.0.0"`); `grep -rn TimelinePage\|ActorHistoryPage lib/ test/` shows only the intentional `@renamed_modules`/fixture-self-test references, no live module; `test/threadline/facade_naming_contract_test.exs` (`paired_names/1` returns exactly `[{:timeline, :timeline_page}]`, live mutation-controlled per 232-06-SUMMARY); `test/threadline/actor_reads_doc_contract_test.exs` pins the cross-link, mutation-controlled per 232-02-SUMMARY |
| 4 | SC4 — every retired entry point is a one-line `@deprecated` delegate with a parity test and a spec matching the replacement; replacements carry `@doc since: "1.0.0"`; `mix compile --warnings-as-errors` clean for `lib/`, `test/`, example | ✓ VERIFIED | `lib/threadline.ex` (5 `@deprecated` facade entries); `test/threadline/deprecation_parity_test.exs` (exact `__info__(:deprecated)` inventory + per-arity `@spec` + parity, all via `apply/3`); re-ran `mix compile --warnings-as-errors` (clean), `MIX_ENV=test mix compile --warnings-as-errors --force` (clean, 177 files), `mix verify.example` (130 tests, 0 failures) |
| 5 | SC5 — `Telemetry.emit_*`, non-`timeline_query` `*_query` builders, moduledoc-less modules absent from `Code.fetch_docs/1`; no hidden-name reference in guides/README/example | ✓ VERIFIED | `lib/threadline/telemetry.ex` (all 9 `emit_*` functions `@doc false`; `transaction_committed/2` stays documented); `lib/threadline/query.ex` (`export_changes_query/1,2` `@doc false`, `timeline_query/1` documented); `test/threadline/public_surface_contract_test.exs` + `test/threadline/facade_only_references_contract_test.exs` (hidden/retired-name scanners with fixture self-tests, no per-file exemption); `grep` over `test/ guides/ README.md examples/` for retired facade-call patterns returns only the scanner's own fixture literals |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/threadline/page.ex` | `%Threadline.Page{entries, cursor, has_more}`, documented, grouped | ✓ VERIFIED | Present, `@moduledoc since: "1.0.0"`, exercised by 137 targeted + full-suite tests |
| `lib/threadline/query/row_reads.ex` | Hidden `list/3`/`page/3`/`audit_changes/3` behind `row_history/3`/`history/3` | ✓ VERIFIED | Present, `@moduledoc false`, wired from `Investigation.row_history/3` and `Threadline.history/3` |
| `lib/threadline/query/legacy_opts.ex` | One normalizer per retired call shape (`cursor/1`, `actor_history/1`, `row_history/2`, `history/1`, `row_history_page/2`) | ✓ VERIFIED | Present, wired into `Query`/`Investigation`/`Threadline` deprecated delegates |
| `test/threadline/deprecation_parity_test.exs` | Exact `__info__(:deprecated)` inventory + parity | ✓ VERIFIED | Present, passing (27 tests per 232-04-SUMMARY; included in 2869-test full-suite green run) |
| `test/threadline/facade_naming_contract_test.exs` | `timeline`/`timeline_page` sole pair; since/deprecated metadata | ✓ VERIFIED | Present, passing, mutation-controlled per 232-06-SUMMARY |
| `test/threadline/facade_only_references_contract_test.exs` | Hidden + retired name scanners, no per-file exemption | ✓ VERIFIED | Present, passing; re-verified by direct grep over `test/ guides/ README.md examples/` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Threadline.row_history/3` | `Threadline.Query.RowReads.list/3` / `page/3` | `Keyword.has_key?(opts, :cursor)` dispatch | ✓ WIRED | Confirmed in `lib/threadline/investigation.ex:30-45` |
| `Threadline.history/3` (deprecated) | `Threadline.Query.RowReads.audit_changes/3` | one-line delegate | ✓ WIRED | Confirmed in `lib/threadline.ex`; parity proven in `deprecation_parity_test.exs` over a 250-change fixture |
| `RowReads.fetch_default/4` | `Threadline.Telemetry.emit_row_history_truncated/2` | fires only when 201-row fetch exceeds 200 | ✓ WIRED | Confirmed in `lib/threadline/query/row_reads.ex:118-128`; registered in `Threadline.Telemetry.@events` and `guides/telemetry.md` |
| `row_history_component.ex` (operator drawer) | `Threadline.row_history/3` with `limit: :infinity` | D-16 unbounded render | ✓ WIRED | Confirmed in 232-03-SUMMARY, exercised by `operator_surface/row_history_component_test.exs` (250-row render) |
| `actor_live.ex` next/prev-page | `Threadline.actor_history/2` `cursor:`/`page_size:` | forced LiveView edit | ✓ WIRED | Confirmed; CR-01 regression (duplicate re-fetch on scroll-up) found in code review and fixed in commit `fa5a6113`, verified by new regression test `Case 6` |

### Behavioral Spot-Checks / Full Verification Runs

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Full compile (prod) | `mix compile --warnings-as-errors` | exit 0, no warnings | ✓ PASS |
| Full compile (test) | `MIX_ENV=test mix compile --warnings-as-errors --force` | exit 0, 177 files, no warnings | ✓ PASS |
| Full test suite | `mix test --warnings-as-errors` | 32 properties, 2869 tests, **0 failures**, 3 excluded | ✓ PASS |
| Targeted phase tests | `mix test test/threadline/facade_naming_contract_test.exs test/threadline/page_test.exs test/threadline/row_history_test.exs test/threadline/deprecation_parity_test.exs test/threadline/actor_reads_doc_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/facade_only_references_contract_test.exs` | 137 tests, 0 failures | ✓ PASS |
| Docs build | `MIX_ENV=dev mix docs --warnings-as-errors` | exit 0 | ✓ PASS |
| Example app | `mix verify.example` | 130 tests, 0 failures | ✓ PASS |
| Retired-name grep (real scope) | `grep -rn 'Threadline\.(history\|row_history_page\|actor_window_page\|correlation_bundle_page)\(\|Query\.(history\|row_history\|row_history_page)\(\|Investigation\.(row_history_page\|actor_window_page\|correlation_bundle_page)\(' test/ guides/ README.md examples/threadline_phoenix` | only `facade_only_references_contract_test.exs`'s own fixture literals | ✓ PASS |
| Debt-marker scan | `grep -nE "TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER"` over the plan's modified `lib/` files | no matches | ✓ PASS |

Note: the orchestrator's context facts cited a post-review `mix test` showing 2869 tests/1 failure (`facade_only_references_contract_test.exs`, a retired-name reference in `guides/integration-contracts.md`'s WR-02 fix), closed by commit `3127d344`. This verifier independently re-ran the **full** `mix test --warnings-as-errors` suite once (not a partial/claimed re-run) after that fix and observed **2869 tests, 0 failures** — confirming the fix, not just trusting the SUMMARY/disposition narrative.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| API-01 | 232-03, 232-04, 232-05 | One `row_history/3` function, keyword opts, bounded default | ✓ SATISFIED | `lib/threadline/investigation.ex`, `row_reads.ex`; REQUIREMENTS.md marked Complete |
| API-02 | 232-02 | `actor_history/2` vs `actor_window/3` distinguishable by return type + cross-link | ✓ SATISFIED | `test/threadline/actor_reads_doc_contract_test.exs`; REQUIREMENTS.md marked Complete |
| API-03 | 232-01, 232-02, 232-03, 232-06 | Every paged read returns `%Threadline.Page{}`; `timeline`/`timeline_page` sole pair | ✓ SATISFIED | `lib/threadline/page.ex`; `facade_naming_contract_test.exs`; REQUIREMENTS.md marked Complete |
| API-05 | 232-06 | Internal helpers hidden from docs; guides/README/example grepped and rewritten | ✓ SATISFIED | `telemetry.ex`, `query.ex` `@doc false`; `facade_only_references_contract_test.exs`; REQUIREMENTS.md marked Complete |
| API-08 | 232-03, 232-04, 232-05, 232-06 | Retired name still works, one compiler deprecation warning naming the replacement | ✓ SATISFIED | `deprecation_parity_test.exs`; `mix compile --warnings-as-errors` clean; REQUIREMENTS.md marked Complete |

No orphaned requirements: `.planning/REQUIREMENTS.md`'s Traceability table maps exactly API-01, API-02, API-03, API-05, API-08 to Phase 232, matching the PLAN frontmatter's declared set across all six plans — nothing else is mapped to this phase.

### Anti-Patterns Found

None found. Scanned all `lib/` files modified by this phase (`page.ex`, `query.ex`, `investigation.ex`, `row_reads.ex`, `legacy_opts.ex`, `cursors.ex`, `telemetry.ex`, `threadline.ex`, `actor_live.ex`, `timeline_live.ex`, `row_history_component.ex`) for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`/empty-implementation patterns — zero matches.

### Code Review Follow-up (post-execution)

`232-REVIEW.md` found one critical (CR-01) and two warning-level (WR-01, WR-02) issues plus one skipped info-level (IN-01). All three in scope were fixed and independently re-verified here:
- **CR-01** (`actor_live.ex` next-page duplicate re-fetch on scroll-up): fixed `fa5a6113`, confirmed by `actor_live_test.exs` Case 6 regression test passing in the full-suite run.
- **WR-01** (explicit `limit: n` silently skips truncation telemetry by design): documented, `row_reads.ex:71-74` comment confirmed present.
- **WR-02** (shared `:surface` default between bounded/legacy read paths): documented in `query.ex` + `guides/integration-contracts.md`; the follow-up guide-wording fix (`3127d344`) that kept the retired name out of that guide is confirmed via the full-suite 0-failure run and the direct retired-name grep above.
- **IN-01**: explicitly skipped as out of fix-scope (info-level doc dedup); does not block phase goal achievement.

### Human Verification Required

None. All must-haves were verifiable programmatically — Postgres-backed integration tests, exact-inventory contract tests, and direct greps covered every success criterion.

### Gaps Summary

No gaps. All five ROADMAP success criteria are observably true in the codebase, backed by a full-suite re-run (2869 tests, 0 failures) performed independently by this verifier rather than taken from SUMMARY.md claims. Phase 231's own verification baseline (passed, 5/5) shows no regression risk carried into this check.

---

_Verified: 2026-10-03T22:30:00Z_
_Verifier: Claude (gsd-verifier)_
