---
phase: 231-facade-topology-and-the-capture-semantics-edge
verified: 2026-10-07T12:25:55Z
status: passed
score: 5/5 must-haves verified
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
covered_digest: "v3:sha256:8603c5b99f5b67b203f81feeaf346e525c1ccdf55fd308c5b2217b003abec8b6"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 231: Facade Topology and the Capture/Semantics Edge Verification Report

**Phase Goal:** An adopter reading the docs finds one read API, `Threadline`, with `Threadline.Query.timeline_query/1` as the single Ecto-composition escape hatch. The capture-layer schemas no longer declare an association to the semantics layer, and every caller that reads `transaction.action` still gets the same shape.
**Verified:** 2026-10-07
**Status:** passed
**Re-verification:** No — the previous report had no `gaps:` section, so this was an initial verification against the current roadmap contract.

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion) | Status | Evidence |
|---|---|---|---|
| 1 | `Threadline.Query` and `Threadline.Investigation` are hidden, pinned by the public-surface test, and the `Threadline` moduledoc names `Threadline.Query.timeline_query/1` as the escape hatch. | ✓ VERIFIED | `mix run` returned `:hidden` for both modules. The live facade moduledoc contains the escape-hatch text, and `function_exported?(Threadline, :timeline_query, 1)` is false. `test/threadline/public_surface_contract_test.exs` pins these contracts and passed in the focused run. |
| 2 | The named guides use facade calls; no hidden-module function calls remain outside the `timeline_query/1` escape hatch, and the doc-contract scanner guards guides, README and example sources. | ✓ VERIFIED | `test/threadline/facade_only_references_contract_test.exs` passed in the focused run. It has non-empty scope checks, fixture tests for hidden-call patterns and the exact escape-hatch allowlist. The focused test run also passed `MIX_ENV=dev mix docs --warnings-as-errors` with both modules hidden. The bare `Threadline.Query` phrase in an audit-indexing heading is not a function call and is not prohibited by the SC. |
| 3 | Neither capture nor semantics schema declares an Ecto association to the other. | ✓ VERIFIED | Live schema introspection returned `AuditTransaction.__schema__(:associations) == [:changes]` and `AuditAction.__schema__(:associations) == []`. `test/threadline/capture_semantics_boundary_test.exs` asserts both association absences and passed. |
| 4 | Existing `transaction.action` reads keep their hydrated shape; `action_id`, its FK, migrations and trigger SQL remain unchanged. | ✓ VERIFIED | Focused tests passed for hydration, investigation, storage-schema integration, timeline and transaction LiveViews, and incident reads (169 tests total). `ActionHydration` queries persisted `AuditAction` rows by distinct non-nil `action_id`, uses caller storage options, and writes the result to the virtual field; tests cover shared IDs, order, nil and association-backed call sites. `git diff --quiet 0e5eda11 HEAD -- lib/threadline/capture/migration.ex lib/threadline/semantics/migration.ex lib/threadline/capture/trigger_sql.ex priv` exited 0. |
| 5 | Compile is warning-free and the CI gate is green. | ✓ VERIFIED | Independently ran `mix compile --warnings-as-errors` (exit 0) and `MIX_ENV=dev mix docs --warnings-as-errors` (exit 0). The focused regression command passed 169 tests, 0 failures. The current canonical `mix verify.test` run recorded in `231-VALIDATION.md` passed 32 properties and 3,047 tests with 0 failures and 3 excluded; the phase's `mix ci.all` gate is recorded green in `231-03-SUMMARY.md`. |

**Score:** 5/5 roadmap truths verified (0 present-but-behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline.ex`, `mix.exs` | Facade-only read API docs and hidden-module configuration | ✓ VERIFIED | Moduledoc names the escape hatch; ExDoc skip list is exactly the pinned `timeline_query/1` entry. Public-surface contract passed. |
| `lib/threadline/query/action_hydration.ex` | Hidden batched hydration for the virtual `action` field | ✓ VERIFIED | Substantive implementation queries `AuditAction` by IDs, honors storage options, maps results back to input order, handles nil and preloaded changes. Called by Query and investigation/LiveView call sites. |
| `lib/threadline/capture/audit_transaction.ex`, `lib/threadline/semantics/audit_action.ex` | Association-free capture/semantics schemas retaining the explicit identifier and virtual field | ✓ VERIFIED | Source and live schema introspection confirm no cross-layer association; `action_id` remains `:binary_id`; virtual `action` defaults to nil. |
| `test/threadline/capture_semantics_boundary_test.exs`, `test/threadline/facade_only_references_contract_test.exs`, `test/threadline/query/action_hydration_test.exs` | Contract and behavioral regression checks | ✓ VERIFIED | All passed as part of the focused run. The scanner has fixture coverage and scope non-vacuity checks; hydration tests exercise returned values and query behavior. |
| `examples/threadline_phoenix/priv/scripts/incident_replay.exs` and safety helper | Facade read and restricted disposable-database guard | ✓ VERIFIED | Script delegates to `disposable_database?/1`; the guard accepts only exact dev/test names and anchored test partition suffixes. `mix test test/threadline_phoenix/incident_replay_safety_test.exs` in the example app passed 2 tests. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `Threadline` moduledoc | `Threadline.Query.timeline_query/1` | Documented escape hatch, exact ExDoc skip-list pin | ✓ WIRED | Live docs contain the reference; public-surface test checks docs and absence of a facade delegate. |
| `Threadline.Query` readers | `Threadline.Query.ActionHydration` | Query delegates hydration; investigation and LiveView reads call the helper after loading transactions | ✓ WIRED | Source paths use `hydrate_actions/3`; related reader tests passed. |
| `ActionHydration` | `audit_actions` in selected storage schema | `repo.all` query by deduplicated `action_id` with `storage_opts([], opts)` | ✓ WIRED | Source performs a real query and maps fetched actions to each original transaction/change; storage-schema integration test passed. |
| Facade-only scanner | Guides, READMEs and example source | `Path.wildcard` plus call-pattern and alias scans | ✓ WIRED | Contract test passed; exact allowlist and non-empty globs are checked. |
| Incident replay script | Disposable database predicate | Calls `ThreadlinePhoenix.IncidentReplaySafety.disposable_database?/1` before scenario execution | ✓ WIRED | Current source and its two focused example tests confirm the guard behavior. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `ActionHydration.hydrate_actions/3` | `actions_by_id` | `repo.all` Ecto query against `AuditAction`, filtered by `action_id` values from loaded transactions | Yes | ✓ FLOWING |
| Hydrated transaction/change | virtual `action` | `Map.get(actions_by_id, transaction.action_id)` applied to the original structs | Yes | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Public surface, facade-only documentation, association boundary, hydration and existing action readers | `mix test test/threadline/public_surface_contract_test.exs test/threadline/facade_only_references_contract_test.exs test/threadline/capture_semantics_boundary_test.exs test/threadline/query/action_hydration_test.exs test/threadline/investigation_test.exs test/threadline/storage_schema_integration_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/transaction_live_test.exs test/mix/tasks/threadline.incident_test.exs` | 169 tests, 0 failures | ✓ PASS |
| Example replay database-name guard | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/incident_replay_safety_test.exs` | 2 tests, 0 failures | ✓ PASS |
| Compile and rendered docs | `mix compile --warnings-as-errors && MIX_ENV=dev mix docs --warnings-as-errors` | Both commands exited 0 | ✓ PASS |

## Probe Execution

Not applicable. This is a library/API and documentation phase; no phase-declared or conventional probe scripts apply.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| API-04 | 231-02, 231-03 | The adopter's docs contain one read API. | ✓ SATISFIED | Hidden module introspection, facade escape-hatch contract, docs build and facade-only scanner passed. |
| API-07 | 231-01, 231-03 | The capture layer no longer depends on the semantics layer at compile time. | ✓ SATISFIED | Both schema association lists are clear; action hydration tests and existing reader tests passed; migration/trigger diff is empty. |

No orphaned requirements: `REQUIREMENTS.md` maps API-04 and API-07 to Phase 231, and the plans declare both.

## Current Review Findings

The current `231-REVIEW.md` reports one warning, WR-01: malformed non-nil `actor_ref` values are accepted by `Threadline.Audit` validation and can raise inside the transaction callback. This is outside Phase 231's API-04/API-07 success criteria, so it is recorded as a non-blocking advisory rather than a phase gap or human-verification item. The disposition and current re-review mark CR-01 and WR-02 fixed in `b8e77ebb`; source and tests confirm the replay safety guard and corrected association documentation. Earlier advisory text is not carried forward as current findings.

## Anti-Patterns Found

No unresolved debt markers or implementation stubs were found in the phase implementation and tests. The word “placeholder” appears in prose and fixture names as intended and is not an implementation stub.

## Human Verification Required

None. The roadmap criteria are covered by executable contract tests, live module/schema introspection, diff checks, compile and docs gates, and the recorded regression gate.

## Gaps Summary

No gaps. All five roadmap success criteria and both mapped requirements are verified against the live source and tests. The remaining WR-01 code-review warning concerns invalid actor-ref input and does not violate this phase's stated goal. CR-01 and WR-02 were fixed in `b8e77ebb` and confirmed on re-review.

---

_Verified: 2026-10-07T12:25:55Z_
_Verifier: the agent (gsd-verifier)_
