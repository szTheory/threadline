---
phase: 232-consolidated-reads-deprecations-and-the-bounded-default
verified: 2026-10-08T01:20:00Z
status: passed
score: 61/61 must-haves verified
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
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-CONTEXT.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-REGRESSION.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-REVIEW-DISPOSITION.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-REVIEW.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-SECURITY.md"
  - ".planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-VALIDATION.md"
  - "CHANGELOG.md"
  - "README.md"
  - "examples/threadline_phoenix/priv/scripts/incident_replay.exs"
  - "examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs"
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
  - "lib/threadline/not_found_error.ex"
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
  - "test/partition_weights.txt"
  - "test/support/keyset_model.ex"
  - "test/support/row_history.ex"
  - "test/threadline/actor_reads_doc_contract_test.exs"
  - "test/threadline/deprecation_parity_test.exs"
  - "test/threadline/facade_naming_contract_test.exs"
  - "test/threadline/facade_only_references_contract_test.exs"
  - "test/threadline/investigation_test.exs"
  - "test/threadline/page_test.exs"
  - "test/threadline/public_surface_contract_test.exs"
  - "test/threadline/query/as_of_property_test.exs"
  - "test/threadline/query/cursors_property_test.exs"
  - "test/threadline/query/row_key_read_test.exs"
  - "test/threadline/query_test.exs"
  - "test/threadline/readme_doc_contract_test.exs"
  - "test/threadline/row_history_test.exs"
  - "test/threadline/telemetry_registry_contract_test.exs"
covered_digest: "v3:sha256:a22528aad8c2f43d9a570421e75b6e882ca85b7833d02be4129f65343a9fec28"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 232: Consolidated Reads, Deprecations and the Bounded Default Verification Report

**Phase Goal:** An adopter reads a row's history through one function with keyword opts. By default it is bounded, the cursor path proves completeness, and truncation is observable. Every paged read returns one `Page` shape. Internal helpers are out of the docs. Any adopter still on a retired name gets a working call and one compiler warning naming the replacement.
**Verified:** 2026-10-08
**Status:** passed
**Re-verification:** No — the prior report had no `gaps:` section; this is a fresh goal-backward verification with a current-source fingerprint.

## Goal Achievement

### Observable Truths

The five roadmap success criteria are verified below and in the plan-contract matrix. The 64 plan truths contain two clear restatements (exact-boundary paging and the truncation boundary); after merging those and deduplicating the roadmap criteria, 62 distinct truths remain.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | **SC1 / API-01:** `row_history/3` accepts keyword opts; defaults to 200 newest-first linked changes as a bare list; explicit limits and `:infinity` work; cursor pages walk to the same full result; conflicting/invalid options raise. | ✓ VERIFIED | `RowReads.list/3` defaults to 200 and fetches one extra row; `Investigation.row_history/3` dispatches on `Keyword.has_key?/2`; `row_history_test.exs` exercises 250 rows, ordering, limit modes, cursor walks, exact multiples, and invalid options. The in-memory precision probe below also exercised the actual page cursor builder, validator, and continuation predicate. |
| 2 | **SC2 / API-01:** only an implicit cap that drops rows emits the registered truncation event with safe metadata; export, `as_of`, the row-history drawer, and migrated history properties remain unbounded. | ✓ VERIFIED | `row_reads.ex` fetches 201 rows then trims to 200; `telemetry.ex` registers the event and emits `%{limit: 200}` with only the schema atom; tests assert 200/201 and explicit-limit cases, leak-check metadata, 250-row export and `as_of`, and explicit unbounded baselines. |
| 3 | **SC3 / API-03:** every pager returns `Threadline.Page`; both retired page structs are gone; `timeline/2` + `timeline_page/2` are the only paired visible names; actor-read docs distinguish and cross-link return shapes. | ✓ VERIFIED | `Threadline.Page` is the shared struct; both old modules are absent; page, naming, public-surface, and actor-read doc contracts pin shape, names, visibility, and links. |
| 4 | **SC4 / API-08:** retired calls remain working one-line deprecated delegates with matching specs and replacement-specific warnings; replacement docs carry `since: "1.0.0"`; library, tests, and example compile clean with warnings as errors. | ✓ VERIFIED | Exact deprecation inventories, parity tests over 250 rows, option compatibility tests, and compile-time diagnostic assertions live in `deprecation_parity_test.exs` and `row_history_test.exs`; strict current-source compile and test commands passed. |
| 5 | **SC5 / API-05:** internal emitters/query builders and moduledoc-less modules are hidden from ExDoc, while permitted public escape hatches remain documented; guides, README, and example adopter surfaces contain no hidden or retired names. | ✓ VERIFIED | `public_surface_contract_test.exs` inspects `Code.fetch_docs/1`; `facade_only_references_contract_test.exs` runs non-vacuous fixture checks and scans all in-scope documentation/example paths without exclusions. Current docs build passes. |

### Plan-Level Contract Matrix

| Plan | Additional truths checked | Status and evidence |
|---|---|---|
| 232-01 | Visible documented `Page`; transparent change cursors; start/nil validation; exact page-size-plus-one boundary; export walks to completion; property model checks no trailing empty page; empty pages; stable ties; UUID normalization. | ✓ VERIFIED — source and Page properties/tests cover each case. The tagged precision truth was directly probed through actual production functions and is included in the probe table. |
| 232-02 | Actor-history Page content/order; forward/backward cursor semantics; legacy option warnings/conflicts; actor LiveView uses canonical cursor options; return-type-first docs and cross-links; forward/backward property; empty and tied timestamps. | ✓ VERIFIED — actor query, LiveView, doc-contract, query tests and keyset property are present and wired. The doc distinction backstop is exercised by the explicit contract test. |
| 232-03 | LinkedChange entries preserve transaction/action context and storage scope; bounded/unbounded behavior; exact cursor walk; input validation and option-presence dispatch; list/page behavior for actor-window and correlation-bundle; literal arity deprecation split; legacy /4 stays unbounded; replacement metadata/specs; truncation conditions/metadata; export/as-of/drawer behavior; row cursor precision. | ✓ VERIFIED — `row_reads.ex`, `investigation.ex`, telemetry registry and behavior tests establish each truth. Current strict suites and targeted test evidence are recorded below. |
| 232-04 | All retired names/arities remain documented deprecated delegates with precise specs and exact replacement messages; hidden Query/Investigation entries still warn; raw `history/3` stays AuditChange-shaped; 250-row parity and nil/newest limits hold; old pagers map legacy nil to start; library callers do not invoke deprecated delegates; replacement docs omit retired names. | ✓ VERIFIED — exact `__info__(:deprecated)` inventories, apply-based parity tests, spec checks, warning diagnostic checks and strict compilation. |
| 232-05 | Test/example callers are migrated; plain AuditChange property baselines are explicitly unbounded; shared test history helper is unbounded; old pager callers use cursor options; no test was removed to silence warnings. | ✓ VERIFIED — call-site scan, helper wiring, full root/property and example suites, and warning-free test/example compiles. |
| 232-06 | Telemetry emitters/query builders hidden; visible transaction event and timeline query retained; no undocumented modules; real-scope hidden/retired scanners and naming detector are non-vacuous; docs have no retired names; replacements carry `since`; full CI/docs/example/browser gate passes; adjacency and non-empty-scope controls work. | ✓ VERIFIED — source visibility and scanner tests plus strict docs/CI evidence. UTF-8 matching and diagnostic ordering were checked with read-only probes that extracted the actual regex and formatter AST from the test module. |

**Score:** 62/62 distinct truths verified (0 present, behavior-unverified; 0 insufficient-spec).

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/page.ex` | Public shared Page struct/types | ✓ VERIFIED | Substantive shape and docs; used by all pagers and pinned by page/public-surface tests. |
| `lib/threadline/query/cursors.ex` | Exact Page construction and cursor validation | ✓ VERIFIED | `page_size + 1` trim, exact `has_more`, cursor casting; called by timeline, row, and actor reads. |
| `lib/threadline/query/legacy_opts.ex` | Compatibility normalization/warnings | ✓ VERIFIED | Wired into retired entry points and actor reads; option tests exercise normalization. |
| `test/threadline/page_test.exs` | Page invariants | ✓ VERIFIED | Shape, boundary, empty, tie, UUID, and full-walk cases. |
| `test/threadline/actor_reads_doc_contract_test.exs` | API-02 doc contract | ✓ VERIFIED | Four assertions pin return type first and reciprocal links. |
| `lib/threadline/query/row_reads.ex` | Bounded/unbounded list and paged query layer | ✓ VERIFIED | Query-backed implementation, cap and event logic, scope-aware predicates. |
| `test/threadline/row_history_test.exs` | Row-history behavior contract | ✓ VERIFIED | 250-row cap and cursor walk, errors, deprecation, telemetry, export, and `as_of`. |
| `lib/threadline/telemetry.ex` | Registered truncation event and hidden emitter | ✓ VERIFIED | Emitter called only on actual truncation; allowlist/leak contract is wired. |
| `test/threadline/deprecation_parity_test.exs` | Legacy-call parity/inventory | ✓ VERIFIED | Exact inventory, result parity, specs/docs, and warning diagnostics. |
| `test/support/row_history.ex` | Unbounded whole-history test helper | ✓ VERIFIED | Calls facade with `limit: :infinity` and unwraps AuditChange values. |
| `test/threadline/facade_naming_contract_test.exs` | Single visible pairing and metadata | ✓ VERIFIED | Asserts sole `timeline` pair, `since` metadata, and non-vacuous fixture. |
| `test/threadline/facade_only_references_contract_test.exs` | Hidden/retired-name doc scanners | ✓ VERIFIED | Real docs/example scope and fixture controls; direct probes also cover regex and formatter edge cases. |
| `test/threadline/public_surface_contract_test.exs` | Hidden-doc visibility contract | ✓ VERIFIED | Checks emitters, query builders, hidden CSV module, and non-empty module inventory, including the current Plug exception implementation. |
| `lib/threadline/investigation.ex` | Public row read, dispatch, actor-window/correlation paging | ✓ VERIFIED | Delegates to RowReads and shared Page paths; scoped query link passes. |
| `lib/threadline.ex` | Facade APIs and deprecated delegates | ✓ VERIFIED | New API docs/types and retired-call delegates are present and exercised. |

### Key Link Verification

All 14 declared plan links are WIRED. The plan queries reported 15/15 artifacts and 14/14 links passing.

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `lib/threadline/query.ex` | `lib/threadline/query/cursors.ex` | timeline/row pager fetches `page_size + 1` and calls `change_page/2` | ✓ WIRED | Query verified. |
| `lib/threadline/export.ex` | `lib/threadline/page.ex` | export stream consumes Page and stops when `has_more: false` | ✓ WIRED | Query verified. |
| `lib/threadline/investigation.ex` | `lib/threadline/page.ex` | linked pages wrap Page entries as LinkedChange | ✓ WIRED | Query verified. |
| `lib/threadline/query.ex` | `lib/threadline/query/cursors.ex` | actor history builds a Page from extra-row fetch | ✓ WIRED | Query verified. |
| `lib/threadline/operator_surface/live/actor_live.ex` | `lib/threadline.ex` | prior-page event calls facade with `cursor: {:before, ...}` | ✓ WIRED | Query verified; integration/browser suites passed. |
| `lib/threadline.ex` | `lib/threadline/investigation.ex` | facade row-history delegate | ✓ WIRED | Query verified. |
| `lib/threadline/query/row_reads.ex` | `lib/threadline/telemetry.ex` | default-list cap event emitted only when probe row exists | ✓ WIRED | Query verified; telemetry test drives event and checks metadata. |
| `lib/threadline/query/row_reads.ex` | `lib/threadline/query.ex` | list/page share row-history query and scope | ✓ WIRED | Query verified. |
| `lib/threadline.ex` | `lib/threadline/query/row_reads.ex` | legacy history delegates to raw AuditChange reader through LegacyOpts | ✓ WIRED | Query verified; parity test covers 250 rows. |
| `test/threadline/deprecation_parity_test.exs` | `lib/threadline.ex` | `apply/3` exercises deprecated API and compares replacement result | ✓ WIRED | Query verified. |
| `test/support/row_history.ex` | `lib/threadline.ex` | helper inserts default `limit: :infinity` | ✓ WIRED | Query verified. |
| `test/threadline/query/as_of_property_test.exs` | `lib/threadline/query/row_reads.ex` | raw AuditChange baseline calls `audit_changes/3` | ✓ WIRED | Query verified. |
| `test/threadline/facade_only_references_contract_test.exs` | `guides/` and adopter docs | scope globs include guides, README and example sources | ✓ WIRED | Query verified; each configured scope is non-empty. |
| `lib/threadline/telemetry.ex` | `test/threadline/public_surface_contract_test.exs` | Code.fetch_docs assertions require internal emitters hidden | ✓ WIRED | Query verified. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| `Threadline.row_history/3` → `RowReads.list/3` / `page/3` | AuditChange rows and linked context | Ecto query through configured Repo, with row key, storage prefix and support scope; results are preloaded into LinkedChange | Yes | ✓ FLOWING |
| Paged row/timeline/actor reads | `Page.entries`, `cursor`, `has_more` | Real query fetches `page_size + 1`; Cursors trims entries and derives next cursor from the last returned entry | Yes | ✓ FLOWING |
| Row-history truncation | telemetry measurements/metadata | Runtime cap probe supplies fixed limit and schema module; no row values or actor IDs | Yes | ✓ FLOWING |
| Hidden/retired-name scanner | offender tuples | Reads actual UTF-8 file content from non-empty guide/README/example globs | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| 200 cap, limits, complete cursor walk, conflict errors, event boundary, export and `as_of` | `test/threadline/row_history_test.exs` in current full suite | Included in passing suite; test definitions assert 250-row and exact 200/201 behavior | ✓ PASS |
| Shared Page exact boundary, empty, ties, UUID validation, full walk | `test/threadline/page_test.exs` in current full suite | Included in passing suite | ✓ PASS |
| Retired calls preserve behavior and warn with replacement | `test/threadline/deprecation_parity_test.exs` and row-history compile diagnostic test | Included in focused/current full evidence | ✓ PASS |
| Cursor timestamp precision through output, validation, and continuation predicate | Read-only `mix run -e`: actual `Cursors.change_page/2`, `validate_page_cursor!/1`, and `maybe_after_timeline_cursor/2`; verified query AST binds `2026-10-07T12:34:56.123456Z` unchanged | Exit 0; exact microseconds retained | ✓ PASS |
| Hidden-name matching in UTF-8 file text | Read-only `mix run -e`: extracted actual `@hidden_name_regex` AST from `facade_only_references_contract_test.exs`, ran it on surrounding Greek, accented and emoji characters | Exit 0; exact ASCII hidden name matched | ✓ PASS |
| Diagnostic sort order | Read-only `mix run -e`: extracted actual private `format_offenders/1` AST, compiled it in-memory, and supplied unsorted paths/lines | Exit 0; result sorted by `{path, line}` | ✓ PASS |

### Probe Execution

Not applicable. This phase is an Elixir API/doc contract phase; no plan or success criterion declares a `probe-*.sh` probe.

### Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|---|---|---|---|---|
| API-01 | 232-03, 232-04, 232-05 | One keyword-options row-history read, bounded by default, complete cursor walk, observable truncation and unbounded export/as-of | ✓ SATISFIED | `row_reads.ex`, `investigation.ex`, row-history/telemetry/property tests, strict suite evidence. |
| API-02 | 232-02 | Actor transactions and cross-table changes are distinct documented reads | ✓ SATISFIED | `actor_reads_doc_contract_test.exs`, query and actor LiveView tests. |
| API-03 | 232-01, 232-02, 232-03, 232-06 | One Page shape and the only intentional facade page-name pairing | ✓ SATISFIED | `page.ex`, pager implementations, page/naming contract tests. |
| API-05 | 232-06 | Internal helpers hidden from adopter docs and scans | ✓ SATISFIED | `public_surface_contract_test.exs`, facade-only scanner, strict docs build. |
| API-08 | 232-03, 232-04, 232-05, 232-06 | Retired names work as warning delegates with parity and replacement guidance | ✓ SATISFIED | `deprecation_parity_test.exs`, warning diagnostic, warning-free internal compiles. |

No orphaned requirements: REQUIREMENTS.md maps only API-01, API-02, API-03, API-05 and API-08 to Phase 232, matching all six plans' requirement declarations.

### Test Quality Audit

| Test file | Linked requirements | Disabled tests | Circular expected values | Assertion strength | Verdict |
|---|---|---:|---|---|---|
| `row_history_test.exs` | API-01, API-08 | 0 | None found; expected row history is inserted independently | Value/behavior | ✓ PASS |
| `page_test.exs`, cursor properties | API-03, API-01 | 0 | None found; keyset model and database reads use independent fixtures | Value/property | ✓ PASS |
| `deprecation_parity_test.exs` | API-08 | 0 | None; compares legacy entry points with replacement results on DB fixtures | Value/behavior | ✓ PASS |
| actor, public surface, naming and facade-only contracts | API-02, API-03, API-05 | 0 | Fixture self-tests are explicit controls; production scope is also scanned | Value/behavior | ✓ PASS |

Disabled-test patterns: none found in the requirement-linked test files. Circular-test patterns: none found. The three `on_exit` matches from a broad substring scan are cleanup hooks, not disabled tests.

### Decision Coverage

All 19 trackable decisions in `232-CONTEXT.md` are honored by shipped artifacts (`check.decision-coverage-verify`: 19/19; non-blocking gate).

### Anti-Patterns Found

None in the reviewed phase source and contract-test files. The targeted scan found no `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, empty implementation, or console-only implementation patterns. No current code-review findings remain; `232-REVIEW-DISPOSITION.md` records 0 open of 5 findings. The security audit records all 19 planned threats closed, and validation records zero gaps.

### Validation Evidence

The current-source refresh reran the phase's core behavior and contract tests; the complete phase gate below is retained from the recorded phase regression evidence.

| Check | Result | Status |
|---|---|---|
| `mix ci.all` (phase regression record) | Exit 0: root 3,047 tests + 32 properties, 0 failures, 3 documented exclusions; example 132 tests, 0 failures; Dialyzer clean; browser 318 passed, 26 expected skips | ✓ PASS (recorded phase gate) |
| `mix test test/threadline/page_test.exs test/threadline/row_history_test.exs test/threadline/deprecation_parity_test.exs test/threadline/actor_reads_doc_contract_test.exs test/threadline/facade_naming_contract_test.exs test/threadline/facade_only_references_contract_test.exs test/threadline/public_surface_contract_test.exs` | 145 tests, 0 failures; includes the newly expanded hidden-moduledoc inventory | ✓ PASS (current refresh) |
| `mix compile --warnings-as-errors` | Exit 0 | ✓ PASS (current refresh) |
| Focused deprecation, facade naming and public-surface tests after current prose correction | 85 tests, 0 failures | ✓ PASS (recorded phase regression) |
| `mix verify.format` | Exit 0 | ✓ PASS |
| `MIX_ENV=dev mix docs --warnings-as-errors` | Exit 0 | ✓ PASS |
| Independent code review | Clean after correcting `row_history/4` filter precedence prose | ✓ PASS |
| Security review | 19/19 planned threats closed; 0 open | ✓ PASS |

### Human Verification Required

None. All three tagged backstop checks were resolved with direct, read-only executable probes; no maintainer judgment or external service is needed.

### Gaps Summary

No gaps. The current code satisfies all five roadmap success criteria and the merged plan contracts. The earlier report was stale because it predated the corrected `row_history/4` filter-precedence documentation and current validation evidence; the current source describes filters as preceding opts, matching the legacy implementation. The corrected prose changes no runtime behavior.

---

_Verified: 2026-10-08T01:20:00Z_
_Verifier: Codex (gsd-verifier)_
