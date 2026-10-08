---
phase: 231-facade-topology-and-the-capture-semantics-edge
verified: 2026-10-08T01:21:44Z
status: passed
score: 32/32 must-haves verified
covered_files:
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-01-PLAN.md
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-01-SUMMARY.md
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-02-PLAN.md
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-02-SUMMARY.md
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-03-PLAN.md
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-03-SUMMARY.md
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-REVIEW-DISPOSITION.md
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-REVIEW.md
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-SECURITY.md
  - .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-VALIDATION.md
  - CHANGELOG.md
  - examples/threadline_phoenix/lib/threadline_phoenix/incident_replay_safety.ex
  - examples/threadline_phoenix/priv/scripts/incident_replay.exs
  - examples/threadline_phoenix/test/threadline_phoenix/incident_replay_safety_test.exs
  - guides/audit-indexing.md
  - guides/code-walkthrough.md
  - guides/domain-reference.md
  - guides/how-threadline-works.md
  - guides/production-checklist.md
  - lib/threadline.ex
  - lib/threadline/audit.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/export.ex
  - lib/threadline/investigation.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/query.ex
  - lib/threadline/query/action_hydration.ex
  - lib/threadline/retention.ex
  - lib/threadline/semantics/audit_action.ex
  - mix.exs
  - test/mix/tasks/threadline.incident_test.exs
  - test/threadline/capture_semantics_boundary_test.exs
  - test/threadline/facade_only_references_contract_test.exs
  - test/threadline/investigation_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/query/action_hydration_test.exs
  - test/threadline/query_test.exs
  - test/threadline/storage_schema_integration_test.exs
covered_digest: "v3:sha256:3a5fd280872cc788f3a1a53f0004997f5f6fb34ce30d82e9c6c5b0c4bb0ff783"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 5/5
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 231: Facade Topology and the Capture/Semantics Edge — Verification

**Phase Goal:** An adopter reading the docs finds one read API, `Threadline`, with `Threadline.Query.timeline_query/1` as the single Ecto-composition escape hatch. The capture-layer schemas no longer declare an association to the semantics layer, and every caller that reads `transaction.action` still gets the same shape.
**Verified:** 2026-10-08T01:21:44Z
**Status:** passed
**Re-verification:** The previous report had no `gaps:` section, so the required mode is initial verification; this refresh replaces its stale fingerprint with current evidence.

## Goal Achievement

### Observable Truths

The 32 plan-level truths below include the five roadmap success criteria; the plan details add specificity but do not change their scope.

| # | Plan commitment | Status | Evidence |
|---|---|---|---|
| 1 | D-05: capture schema has no `:action` association; `action_id` is explicit `:binary_id`, `action` virtual/nil, and `t()` is independent of `AuditAction.t()` | ✓ VERIFIED | `capture_semantics_boundary_test.exs` asserts associations, field types/default and compiled type; live schema source confirms. |
| 2 | D-06: `AuditAction` has no `:transactions` association | ✓ VERIFIED | `capture_semantics_boundary_test.exs` asserts `__schema__(:associations)`. |
| 3 | D-07: unhydrated `transaction.action` is nil and the Unreleased changelog documents it | ✓ VERIFIED | Boundary test asserts nil; `CHANGELOG.md` Unreleased highlights describes the behavior. |
| 4 | D-08: hidden hydrator accepts supported nil/transaction/change/list forms, batches unique non-nil IDs once, skips empty queries, and honors selected storage schema | ✓ VERIFIED | `ActionHydration.hydrate_actions/3` performs one `repo.all` against the selected schema; focused hydration suite covers forms, batching, deduplication, prefix isolation and unloaded-transaction error. |
| 5 | D-09: all internal action readers hydrate through the hidden helper rather than public deprecated preload | ✓ VERIFIED | `investigation.ex`, both LiveViews, and Query call the delegate; hydration/reader tests passed. |
| 6 | D-09/SC4: existing `.action` reads retain their shape | ✓ VERIFIED | Focused tests passed for investigation, transaction context, query, storage schema, timeline, transaction LiveView and incident task; `query_test.exs:1610` passed as a named behavioral check. |
| 7 | D-10: public action preload forms hydrate, warn once with replacements, and reject nested action keys before Ecto preload | ✓ VERIFIED | `query/action_hydration_test.exs` has active value, warning-count and `ArgumentError` tests for both transaction and change paths; all passed. |
| 8 | D-10: internal facade and LiveView reads do not emit the deprecation warning | ✓ VERIFIED | Dedicated stderr-capture test invokes the internal paths; passed in the focused suite. |
| 9 | D-13: association mutation control is recorded and the contract asserts the association absence | ✓ VERIFIED | Boundary test has direct `refute` assertions; 231-01 summary records the re-add-association red/restore/green mutation. |
| 10 | SC4: capture/install migrations, trigger SQL and `priv/` are unchanged from phase base | ✓ VERIFIED | `git diff --quiet 0e5eda11 HEAD -- lib/threadline/capture/migration.ex lib/threadline/semantics/migration.ex lib/threadline/capture/trigger_sql.ex priv` exited 0. |
| 11 | API-07 adjacency: shared action IDs hydrate to the same action with one query | ✓ VERIFIED | Hydration implementation deduplicates IDs; named test asserts shared IDs, one query and matching action values. |
| 12 | API-07 empty behavior: nil/list/transaction without action ID retain expected nil/empty values and avoid empty query | ✓ VERIFIED | Named hydration tests assert all three cases. |
| 13 | API-07 ordering: output length and order follow input | ✓ VERIFIED | Hydration maps zipped original items and tests assert the exact returned order. |
| 14 | D-01/D-02: Query and Investigation are hidden and omitted from Core API grouping | ✓ VERIFIED | `public_surface_contract_test.exs` pins hidden modules; `mix.exs` grouping omits them; the live docs build succeeded. |
| 15 | D-01: the sole code-autolink exception is `Threadline.Query.timeline_query/1` | ✓ VERIFIED | `mix.exs` sets that exact singleton; public-surface contract pins the skip lists. |
| 16 | D-02/SC1: Threadline moduledoc names the escape hatch and adds no facade delegate | ✓ VERIFIED | Live moduledoc contains the inline code reference; contract checks it and `function_exported?/3` is false. |
| 17 | D-03: facade docs avoid other hidden-module references and explain ordering/correlation inline | ✓ VERIFIED | Source inspection plus successful warnings-as-errors docs generation; public-surface contract and scanner tests passed. |
| 18 | D-04: `Threadline.timeline_query/1` is not exported | ✓ VERIFIED | Pinned by the public-surface contract test, which passed. |
| 19 | D-11/SC2: five named guides use the facade, and audit-indexing directs exports to the public CSV/JSON API | ✓ VERIFIED | Facade-only scanner covers guides; direct scan found no hidden function calls; its live-scope test passed. |
| 20 | SC5 docs gate builds with both modules hidden | ✓ VERIFIED | `MIX_ENV=dev mix docs --warnings-as-errors` exited 0 and generated ExDoc output. |
| 21 | Released hidden-module history remains in CHANGELOG and is the only undefined-reference warning exception | ✓ VERIFIED | Changelog history and exact `skip_undefined_reference_warnings_on` singleton are pinned by the public-surface test; docs gate passed. |
| 22 | D-12: scanner covers the stated adopter-facing doc/example scope, detects both reference forms, and allows only `timeline_query` | ✓ VERIFIED | Test source implements exact function-name matching and the scope tests passed. |
| 23 | D-12: CHANGELOG, example tests, `e2e/`, and `.planning/` are excluded | ✓ VERIFIED | Scanner’s `@scope_globs` enumerates only the declared globs; contract suite passed. |
| 24 | D-12: bare aliases fail with the extend-scanner diagnostic; struct-group aliases remain allowed | ✓ VERIFIED | Dedicated positive/negative fixture tests and real-scope alias test passed. |
| 25 | D-12: fixtures prove hidden references are caught and the exact escape hatch is allowed | ✓ VERIFIED | Fixture tests cover a hidden call, hidden inline reference, exact escape hatch and near-miss. |
| 26 | D-11: example incident replay uses a facade read and its app checks pass | ✓ VERIFIED | Script now calls `Threadline.row_history/4` (the later facade name replacing planned `Threadline.history/3`); root `mix verify.example` completed 132 tests with 0 failures. |
| 27 | D-13: scanner mutation control is recorded | ✓ VERIFIED | 231-03 summary records that adding a hidden guide call fails the real-scope test and restoring it passes. |
| 28 | SC5: compilation, example verification, and full CI gate are green | ✓ VERIFIED | `mix compile --warnings-as-errors` and `mix verify.example` passed locally; Phase 231 validation records `mix ci.all` green (3,047 tests, 0 failures), and the current release PR’s required CI checks are green. |
| 29 | API-04 edge: allowlist is exact, rejecting `timeline/2` and prefix near-misses | ✓ VERIFIED | Scanner fixture tests assert exact membership and the near-miss `timeline_query_x/1` is reported. |
| 30 | API-04 edge: every scanner glob must resolve to a file | ✓ VERIFIED | Per-glob non-empty assertions are present and passed. |
| 31 | API-04 edge: scanner offenders are deterministically sorted by path and line | ✓ VERIFIED | Sorting fixture asserts expected ordered tuples; passed. |
| 32 | API-04 edge: scanner is read-only and async-safe | ✓ VERIFIED | Scanner reads each in-scope path with `File.read!` and has `async: true`; full focused test run passed without shared writes. |

**Score:** 32/32 plan-level truths verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/query.ex` and `lib/threadline/query/action_hydration.ex` | Hidden `hydrate_actions/3` entry point and batched implementation | ✓ VERIFIED | Query uses `defdelegate` to the substantive hidden helper. The generic artifact matcher’s literal `def hydrate_actions(` check misses this correct delegate; the delegated helper is documented `@doc false`, wired, and tested. |
| `lib/threadline/capture/audit_transaction.ex` and `lib/threadline/semantics/audit_action.ex` | Association-free schemas retaining explicit ID/virtual field | ✓ VERIFIED | Live schema declarations and boundary tests confirm both sides. |
| `mix.exs`, `lib/threadline.ex`, `lib/threadline/investigation.ex` | Hidden modules and public facade documentation | ✓ VERIFIED | Exact docs config, facade text and hidden moduledocs are present; tests and docs build pass. |
| `test/threadline/capture_semantics_boundary_test.exs` | Association-absence boundary contract | ✓ VERIFIED | Six active tests, including schema/type and source-boundary checks, passed. |
| `test/threadline/query/action_hydration_test.exs` | Hydration, compatibility, storage and warning behavior | ✓ VERIFIED | Relevant suite passed as part of the 169-test focused run. |
| `test/threadline/public_surface_contract_test.exs` | Hidden-set and facade escape-hatch contract | ✓ VERIFIED | Relevant suite passed, including the current additional public-surface assertion. |
| `test/threadline/facade_only_references_contract_test.exs` | Non-vacuous facade-only documentation scanner | ✓ VERIFIED | Fixtures, nonempty scope checks, allowlist, alias guard and live scope all passed. |
| `examples/threadline_phoenix/priv/scripts/incident_replay.exs` | Example uses the public facade | ✓ VERIFIED | Uses `Threadline.row_history/4`, which is the later facade API; no hidden-module call remains. The plan matcher’s older `Threadline.history(` literal is stale. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `Threadline` moduledoc | `Threadline.Query.timeline_query/1` | Named inline escape hatch and pinned ExDoc skip | ✓ WIRED | Verified by live docs and contract test. |
| `Threadline.Query` | `Threadline.Query.ActionHydration` | Hidden delegate | ✓ WIRED | Direct source trace and hydration tests. |
| Investigation readers | Hydration helper | Hydrate after transaction/change preloads | ✓ WIRED | Source trace and reader tests. |
| Timeline and transaction LiveViews | Hydration helper | Explicit internal hydration; no deprecated preload | ✓ WIRED | Source trace, stderr-capture coverage and focused tests. |
| Hydration helper | `audit_actions` selected storage schema | `repo.all` over deduplicated `action_id` values with `storage_opts([], opts)` | ✓ WIRED | Real query and storage-prefix test confirm source and flow. |
| Facade-only scanner | Guides, README and example sources | Nonempty `Path.wildcard` scope plus line scans | ✓ WIRED | Current scope tests and zero-offender assertion passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| `ActionHydration.fetch_actions_by_id/3` | `actions_by_id` | Ecto query against `AuditAction`, filtered by transaction `action_id` values | Yes | ✓ FLOWING |
| Hydrated transaction | virtual `action` | `Map.get(actions_by_id, transaction.action_id)` | Yes; nil when no matching ID | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Capture/semantics boundary, facade docs, hydration, investigation, storage schema, LiveViews and incident reader | `mix test test/threadline/public_surface_contract_test.exs test/threadline/facade_only_references_contract_test.exs test/threadline/capture_semantics_boundary_test.exs test/threadline/query/action_hydration_test.exs test/threadline/investigation_test.exs test/threadline/storage_schema_integration_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/mix/tasks/threadline.incident_test.exs` | 169 tests, 0 failures | ✓ PASS |
| Raw/rich action result shape | `mix test test/threadline/query_test.exs:1610` | Named test passed; 73 other tests excluded | ✓ PASS |
| Warning-free compile and rendered docs | `mix compile --warnings-as-errors && MIX_ENV=dev mix docs --warnings-as-errors` | Both exited 0 | ✓ PASS |
| Example app compile/test gate | `mix verify.example` | 132 tests, 0 failures | ✓ PASS |

### Probe Execution

Not applicable: this library/API and documentation phase has no declared or conventional probe scripts.

### Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| API-04 | 231-02, 231-03 | Adopter docs expose one read API, with the named query escape hatch | ✓ SATISFIED | Hidden-module tests, exact doc-skip contract, docs generation and live facade-only scanner pass. |
| API-07 | 231-01, 231-03 | Capture schema has no compile-time dependency on semantic action association | ✓ SATISFIED | Both association tests, hydrator behavior and storage schema checks pass; migration/trigger diff is empty. |

No orphaned requirements: REQUIREMENTS.md maps API-04 and API-07 to Phase 231, and both appear in plan requirements.

### Decision Coverage

All 13 trackable CONTEXT.md decisions are honored by shipped artifacts (non-blocking decision gate).

### Test Quality Audit

| Test file | Linked requirement | Active | Skipped | Circular | Assertion strength | Verdict |
|---|---|---:|---:|---:|---|---|
| `capture_semantics_boundary_test.exs` | API-07 | Yes | 0 | No | Schema values and association absence | ✓ PASS |
| `query/action_hydration_test.exs` | API-07 | Yes | 0 | No | Returned values, query count, warning behavior | ✓ PASS |
| `public_surface_contract_test.exs` | API-04 | Yes | 0 | No | Live docs visibility, config and exported function | ✓ PASS |
| `facade_only_references_contract_test.exs` | API-04 | Yes | 0 | No | Live scope plus adversarial fixtures | ✓ PASS |
| Reader and storage integration tests | API-07 | Yes | 0 | No | Returned action values and selected schema | ✓ PASS |

No requirement-linked tests are disabled, circular or assertion-insufficient. The tests do not derive expected hydration results by invoking the implementation under test.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/threadline.ex` | 376 | “Sentinel placeholders” in a comment describing omitted/absent/null values | Info | Terminology only; no stub, unresolved `TODO`, `FIXME`, `XXX` or `TBD` was found in the scanned phase implementation/tests. |

### Human Verification Required

N/A — infrastructure/library and documentation phase; no user-facing interaction requires manual verification. All roadmap criteria are covered by executable contracts, schema/API checks, compilation and docs gates.

### Gaps Summary

No gaps. The public facade contract and capture/semantics boundary are present, wired and exercised. Two generic artifact pattern checks report stale literals: they expect `def hydrate_actions(` although Query correctly exports the tested function with `defdelegate`, and they expect the example’s former `Threadline.history(` although the current facade uses `Threadline.row_history/4`. Neither indicates missing implementation. Current compile, docs, focused regression and example gates pass.

---

_Verified: 2026-10-08T01:21:44Z_
_Verifier: the agent (gsd-verifier)_
