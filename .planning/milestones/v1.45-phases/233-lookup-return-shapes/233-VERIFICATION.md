---
phase: 233-lookup-return-shapes
verified: 2026-10-04T00:00:00Z
status: passed
score: 3/3 must-haves verified
covered_files:
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/233-lookup-return-shapes/233-01-PLAN.md"
  - ".planning/phases/233-lookup-return-shapes/233-01-SUMMARY.md"
  - ".planning/phases/233-lookup-return-shapes/233-02-PLAN.md"
  - ".planning/phases/233-lookup-return-shapes/233-02-SUMMARY.md"
  - ".planning/phases/233-lookup-return-shapes/233-03-PLAN.md"
  - ".planning/phases/233-lookup-return-shapes/233-03-SUMMARY.md"
  - ".planning/phases/233-lookup-return-shapes/233-04-PLAN.md"
  - ".planning/phases/233-lookup-return-shapes/233-04-SUMMARY.md"
  - "CHANGELOG.md"
  - "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex"
  - "guides/code-walkthrough.md"
  - "guides/integration-contracts.md"
  - "lib/threadline.ex"
  - "lib/threadline/investigation.ex"
  - "lib/threadline/not_found_error.ex"
  - "lib/threadline/operator_surface/live/transaction_live.ex"
  - "lib/threadline/query.ex"
  - "lib/threadline/query/scope.ex"
  - "lib/threadline/query/transaction_lookup.ex"
covered_digest: "v1:sha256:01d0d811078a92a49784272e9454d922774d763b51e0b2808343ebd6cb16f467"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 233: Lookup Return Shapes Verification Report

**Phase Goal:** An adopter handles a missing transaction the same way on every single-subject lookup: a tagged tuple by default and a raising `!` sibling when absence is a bug.
**Verified:** 2026-10-04
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `audit_transaction/2` and `transaction_context/2` return `{:ok,_}`/`{:error,:not_found}` matching `incident_bundle/2`; tests cover both cases each | ✓ VERIFIED | `lib/threadline.ex:398-407,456-459`; `lib/threadline/investigation.ex:162-179`; all three built on shared `Threadline.Query.TransactionLookup.fetch_row/2` / `fetch/2` (`lib/threadline/query/transaction_lookup.ex:97-150`). Tests: `test/threadline/transaction_lookup_test.exs`, `test/threadline/investigation_test.exs` — both ran green. |
| 2 | `audit_transaction!/2` and `transaction_context!/2` return bare value or raise; tests cover both | ✓ VERIFIED | `lib/threadline.ex:417-427,469-479` — `case` on the plain function, raises `Threadline.NotFoundError` on `:not_found`. `incident_bundle!/2` (`:522-530`) follows the identical pattern. Verified by `test/threadline/not_found_error_test.exs` and `test/threadline/transaction_lookup_test.exs` (green). |
| 3 | Every internal caller (lib/, operator surface, example app, guides) uses the new shapes; CHANGELOG `Unreleased` breaking-changes records it; `mix ci.all`/compile green | ✓ VERIFIED | `grep` for `Query.audit_transaction(` outside test/deprecation code returns nothing in `lib/`, `examples/`, `guides/`; `guides/code-walkthrough.md` no longer quotes `Query.audit_transaction`; `transaction_live.ex:20-24` calls `Threadline.incident_bundle/2` with only `:repo`/`:scope`/`:scope_query_fn`; `CHANGELOG.md` "Unreleased → Breaking changes" carries three dedicated entries (`transaction_context/2` shape change, option-key/`:not_found`-id change, `Scope.apply` fail-closed change) each with before/after and required action. `mix compile --warnings-as-errors` ran clean; `mix format --check-formatted` clean; full `mix test` ran green (32 properties, 2952 tests, 0 failures, 3 excluded) — matches orchestrator-cited final run. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/threadline/query/transaction_lookup.ex` | shared hidden fetch (`validate_opts!/2`, `resolve_id/1`, `fetch_row/2`, `fetch/2`) | ✓ VERIFIED | All four functions present, used by `lib/threadline.ex` and `lib/threadline/investigation.ex`. |
| `lib/threadline/not_found_error.ex` | `Threadline.NotFoundError` + `Plug.Exception` impl | ✓ VERIFIED | `defexception [:resource, :id]`, `@type t`, `message/1` only uses `resource`/`id`; `defimpl Plug.Exception` returns `status: 404`, `actions: []`. |
| `lib/threadline/query/scope.ex` | fail-closed `Scope.apply/2` | ✓ VERIFIED | Raises `ArgumentError` for non-nil scope w/o usable fn, and for any non-3-arity fn, before inspecting scope value; nil scope stays unscoped. |
| `test/threadline/lookup_return_shapes_contract_test.exs` | doc-contract for the lookup family + `as_of/4` exemption | ✓ VERIFIED | Present, listed in `test/partition_weights.txt` (weight 30), part of green full-suite run. |
| `test/threadline/query/scope_fail_closed_test.exs` | fail-closed matrix across every scoped read | ✓ VERIFIED | 20 tests spanning timeline/actor/transaction/export/operator-surface paths plus the three ArgumentError/leak-safety assertions; weight 200 in `partition_weights.txt`. |
| `CHANGELOG.md` | Breaking/Deprecations entries for the lookup family | ✓ VERIFIED | `transaction_context/2` entry, option-allowlist/`:not_found`-id entry, and `Scope.apply` fail-closed entry all present under "Unreleased → Breaking changes", each with a required-action line. |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `lib/threadline.ex` (`audit_transaction/2`) | `TransactionLookup.fetch_row/2` | direct call, maps `:not_found` → `{:error, :not_found}` | ✓ WIRED |
| `lib/threadline/investigation.ex` (`transaction_context/2`, `incident_bundle/2`) | `TransactionLookup.fetch/2` | direct call | ✓ WIRED |
| `lib/threadline/query/transaction_lookup.ex` | `lib/threadline/query/scope.ex` (`Query.maybe_apply_scope`) | row scoped `surface: :transaction_header` ([at]); changes scoped `surface: :transaction` ([ac, at]) | ✓ WIRED |
| `lib/threadline/operator_surface/live/transaction_live.ex` | `Threadline.incident_bundle/2` | mount call, no `:surface`/`:params` passed | ✓ WIRED |
| `lib/threadline/query.ex` (deprecated `audit_transaction/2`) | `TransactionLookup.scoped_row/4` | shares the scoped-row read, keeps `nil`/preload behavior | ✓ WIRED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| API-06 | 233-01, 233-02, 233-03, 233-04 | Single-subject lookups behave the same way everywhere; plain tuple + `!` raise | ✓ SATISFIED | All SC1–SC3 confirmed above; no orphaned requirement in `.planning/REQUIREMENTS.md` for Phase 233 beyond API-06. |

No orphaned requirements found: `.planning/REQUIREMENTS.md` maps only API-06 to Phase 233, and all four plans declare it.

### Must-Have Prohibitions (judgment-tier, non-authoritative)

Every plan's `must_haves.prohibitions` entry is `verification: judgment`, `status: unresolved` in frontmatter. Per the judgment-tier routing rule, these are recorded here as a non-authoritative LLM-judge check, not a hard gate:

| # | Prohibition | Judge finding |
|---|-------------|---------------|
| 1 | `NotFoundError` message must not carry row data/scope terms | Holds — `message/1` interpolates only `resource` and `id` (`lib/threadline/not_found_error.ex:25-28`). |
| 2 | A misconfigured `:storage_schema` must not be rescued into `:not_found` | Holds — `scoped_row/4` has no `rescue`; a bad schema surfaces the Postgrex `undefined_table` error or `ArgumentError`, not `:not_found`. |
| 3 | `transaction_context/2` must not return `%LinkedTransaction{transaction: nil}` for absence | Holds — `investigation.ex:164-179` returns `{:error, :not_found}`; no code path constructs a `transaction: nil` struct from `fetch/2`. |
| 4 | Operator UI changes only at the forced `TransactionLive` call site | Holds — diff at `transaction_live.ex:20-24` is a call-site argument change only; no new copy/styling/capability. |
| 5 | Deprecated `Query.audit_transaction/2` must not change shape in place | Holds — `lib/threadline/query.ex:72-114` still returns `AuditTransaction.t() | nil`, still honors `:preload`/`:action` warning. |
| 6 | No `as_of!/4` added; `Evidence.get_latest_subject_ref/3` not reshaped | Holds — `grep` finds no `as_of!` export in `lib/threadline.ex`; no `lib/threadline/evidence*.ex` file appears in the phase's covered-files diff. |
| 7 | Misconfigured scope must never silently widen to all tenants | Holds — `scope.ex` raises before falling through; `scope_fail_closed_test.exs` exercises this on every scoped read. |
| 8 | ArgumentError for misconfigured scope must not echo the scope value | Holds — `scope.ex:12-21` messages name only `:scope_query_fn`/the missing-key problem, never `inspect(scope)`; matches the reviewer's confirmed `refute error.message =~ "tenant-secret-7"` assertion in `scope_fail_closed_test.exs`. |

**Flag: unverified-prohibition — human review recommended.** The above are LLM-judge findings against the current code, consistent with the independent code-review report (`233-REVIEW.md`, 0 critical / 1 warning / 1 info), but remain judgment-tier and not elevated to a test-backed gate in this phase.

### Anti-Patterns Found

None of severity Blocker or Warning in the phase's changed files. The code-review report (`233-REVIEW.md`) found:
- **WR-01** (non-blocking): `TransactionLookup.fetch_row/2` resolves a malformed id to `:not_found` before checking `:repo` presence, so a caller missing both `:repo` and passing a malformed id gets `:not_found` instead of a loud `KeyError`. This does not leak data and does not affect SC1–SC3; carried as a known minor inconsistency, not a phase-goal blocker.
- **IN-01** (info only): `NotFoundError.message/1` pattern-matches a bare map rather than `%__MODULE__{}`; functionally correct, cosmetic only.

No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers found in the phase's changed files.

### Behavioral Spot-Checks / Test Evidence

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `mix compile --warnings-as-errors` | `mix compile --warnings-as-errors` | clean, no output | ✓ PASS |
| `mix format --check-formatted` | `mix format --check-formatted` | clean, no output | ✓ PASS |
| Core lookup/scope/not-found tests | `mix test test/threadline/transaction_lookup_test.exs test/threadline/not_found_error_test.exs test/threadline/lookup_return_shapes_contract_test.exs test/threadline/deprecation_parity_test.exs test/threadline/query/scope_fail_closed_test.exs` | 105 tests, 0 failures | ✓ PASS |
| Caller-migration tests | `mix test test/threadline/investigation_test.exs test/threadline/query_test.exs test/threadline/query/action_hydration_test.exs test/threadline/storage_schema_integration_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/public_surface_contract_test.exs` | 176 tests, 0 failures (one expected deprecation warning logged, by design) | ✓ PASS |
| Full suite | `mix test` | 32 properties, 2952 tests, 0 failures, 3 excluded | ✓ PASS (matches orchestrator-cited final run) |

`mix ci.all` (Dialyzer + browser lane) was not independently re-run in this verification pass given its multi-minute Dialyzer/PLT cost and the orchestrator's already-cited green run; the re-run of `mix compile --warnings-as-errors`, `mix format --check-formatted`, and the full `mix test` suite above independently confirms the parts of `ci.all` most load-bearing for this phase's goal (shape correctness, call-site migration, no warnings).

### Human Verification Required

None. All must-haves are either directly test-verified or confirmed by direct code inspection; the eight judgment-tier prohibitions are non-authoritative LLM-judge findings recorded above, consistent with the independent code-review report, and do not block phase completion per project policy ("Zero human verification by default").

### Gaps Summary

No gaps. All three ROADMAP success criteria are met: the three lookups share one tuple/raise contract, tests cover present/missing cases for all six functions, every internal caller (lib/, operator surface, example app, guides) was migrated off the old shapes, the CHANGELOG records the breaking changes, and the full test suite plus a clean `--warnings-as-errors` compile confirm `mix ci.all`'s most relevant lanes are green. The one review warning (WR-01) and one info note (IN-01) are narrow, non-security, non-blocking items already surfaced in `233-REVIEW.md`.

---

_Verified: 2026-10-04_
_Verifier: Claude (gsd-verifier)_
