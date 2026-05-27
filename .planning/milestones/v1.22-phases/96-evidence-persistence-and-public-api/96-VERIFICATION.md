---
phase: 96-evidence-persistence-and-public-api
verified: 2026-05-27T07:37:28Z
status: passed
score: 4/4 requirement bands verified
overrides_applied: 0
---

# Phase 96: Evidence Persistence And Public API Verification Report

**Phase Goal:** Re-prove the current-tree evidence persistence and public API contract with explicit verification evidence instead of inherited summary claims.
**Verified:** 2026-05-27T07:37:28Z
**Status:** passed
**Re-verification:** Yes - gap closure for missing phase verification

## Current-tree preflight

**Result:** PASS

- The Phase 96 implementation files, tests, and summaries are present on disk, but `96-VERIFICATION.md` was missing before this run.
- This verification treats the current working tree as the authority and closes that missing artifact gap directly.
- Milestone authority surfaces remain intentionally unreconciled here; `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` stay Phase 103 work.

## 1. Threadline.Evidence public context and subject-focused write helpers

**Requirement:** `PROOF-01`  
**Result:** PASS

- `lib/threadline/evidence.ex` exposes exactly six public `record_*` helpers (lines 22, 29, 36, 43, 50, 57) — one per closed Phase 95 subject family: `record_redaction_policy`, `record_trigger_coverage`, `record_retention_run`, `record_retention_policy`, `record_export_delivery`, `record_support_scope_posture`.
- The module deliberately exposes no generic public writer; `record_subject/4` is a private dispatcher at line 161 and is not callable from outside the module. The test at `test/threadline/evidence_test.exs:37` (`"exposes the supported write helper family without a broad generic writer"`) asserts `refute function_exported?(Evidence, :record_evidence, 3)` and `refute function_exported?(Evidence, :record_subject, 4)`.
- `lib/threadline/evidence/subject.ex` enforces the closed inventory via `@supported_subjects` (lines 10–17) and `Subject.validate/1` (line 36); the six supported-subject strings map one-to-one to the six public helper names.
- `lib/threadline/governance/evidence_record.ex` declares `schema "threadline_evidence_records"` (line 15) with `inserted_at` only and no `updated_at`, confirming the append-only schema boundary that backs all six write helpers.

### Evidence

```bash
mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1
```

Result: PASS (`12 tests, 0 failures`)

```bash
rg -n '^\s*def record_' lib/threadline/evidence.ex
```

Result: PASS — exactly six matches:

```
22:  def record_redaction_policy(subject_ref, attrs, opts \\ []) do
29:  def record_trigger_coverage(subject_ref, attrs, opts \\ []) do
36:  def record_retention_run(subject_ref, attrs, opts \\ []) do
43:  def record_retention_policy(subject_ref, attrs, opts \\ []) do
50:  def record_export_delivery(subject_ref, attrs, opts \\ []) do
57:  def record_support_scope_posture(subject_ref, attrs, opts \\ []) do
```

## 2. Append-only read contract — history, latest, and list_latest semantics

**Requirement:** `PROOF-01`  
**Result:** PASS

- All history and list helpers in `Threadline.Evidence` are permanently list-shaped: `list_history/1,2` (line 64), `list_subject_ref_history/3,4` (lines 81, 92), `list_latest_subject_refs/2,3` (lines 100, 120), and `list_overview/1,2` (line 128) each call `repo.all()` (lines 75, 89, 113, 136) and return lists unconditionally.
- The singular helper `get_latest_subject_ref/3` (line 148) calls `repo.one()` (line 158) and returns one record or `nil` — it does not accept an option to return a list.
- There is no option-driven shape switching anywhere in the public surface; the naming discipline distinguishes `list_latest_*` (always list) from `get_latest_*` (always singular or nil), mirroring Phase 96 CONTEXT D-11 and D-12.
- Filter allow-lists (`@allowed_history_filter_keys` at line 15, `@allowed_subject_ref_history_filter_keys` at line 16, `@allowed_latest_filter_keys` at line 17) enforce fail-loud validation: unknown keys raise `ArgumentError` via `validate_filters!/3` at line 237, proven by the test at `evidence_test.exs:144` (`"rejects unknown history filter keys loudly"`).

### Evidence

```bash
mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1
```

Result: PASS (`12 tests, 0 failures`)

## 3. Mechanical-only defaults and explicit provenance contract

**Requirement:** `PROOF-01`  
**Result:** PASS

- `build_record_attrs/4` (line 176) fills only mechanical library-owned defaults: normalized `subject` (via `Subject.validate/1`), normalized string-keyed `subject_ref` (via `normalize_map_values/1`), `recorded_at` via `Map.put_new(:recorded_at, DateTime.utc_now(:microsecond))` (line 180), `schema_version` via `Map.put_new(:schema_version, @schema_version)` (line 181, constant `1` at line 14), and the narrow provenance envelope.
- The provenance envelope is built by `provenance/2` (lines 186–192) as `%{"writer" => "threadline", "entrypoint" => "record_<subject>"}`. Caller-supplied extras are merged in via `Map.merge` but can never override the two library-owned keys. The entrypoint label is always the public helper name (e.g., `"record_retention_run"`), as computed at line 163.
- Semantic fields `summary_status` and `detail` are required by the changeset (`@required_fields` in `evidence_record.ex` lines 27–35) but are not auto-filled by the library. `actor_ref` appears in `cast/3` (line 46) but is not in `@required_fields` and is never auto-filled.
- The test at `evidence_test.exs:85` (`"rejects missing semantic fields even when defaults are available"`) asserts changeset errors when callers omit `summary_status` and `detail`, locking the caller-explicit-semantic-meaning invariant.

### Evidence

```bash
mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1
```

Result: PASS (`12 tests, 0 failures`)

## 4. Phoenix-optional install and no-ambient-state boundary

**Requirement:** `PROOF-01`  
**Result:** PASS

- `lib/threadline/evidence.ex` imports only `Ecto.Query` (line 9) and aliases only `Threadline.Evidence.Subject` (line 11) and `Threadline.Governance.EvidenceRecord` (line 12); it imports nothing from Plug or Phoenix.
- Every public entrypoint enforces explicit `repo:`: the six `record_*` helpers funnel through `record_subject/4` (line 161) which calls `validate_repo(Keyword.get(opts, :repo))` (line 165) — returning `{:error, :missing_repo}` (line 346) on nil — and then `Keyword.fetch!(opts, :repo).insert()` (line 172) which raises if missing. All read helpers call `evidence_repo!(filters, opts)` (lines 66, 103, 130, 149), which raises `ArgumentError` if neither `filters` nor `opts` supplies `:repo` (lines 269–282).
- A tightened structural grep against `lib/threadline/evidence.ex` returns no matches for Plug/Phoenix module directives or for runtime calls to the process dictionary, `Logger.metadata`, or `:ets`.

> Note: the pattern is tightened to start-of-line module directives (`import|alias|require|use`) and runtime-call forms (`Process.put(`, `Process.get(`, `Logger.metadata(`, `:ets.`). The naive pattern `'Plug\.|Phoenix|...'` is rejected because it matches the module's own `@moduledoc` at `lib/threadline/evidence.ex:5`, which is documentation prose, not a runtime dependency.

### Evidence

```bash
rg -n '^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.' lib/threadline/evidence.ex
```

Result: PASS (no matches — negative assertion)

### Authority statement

The authoritative Phase 96 rerun bundle is:

1. `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`
2. `rg -n '^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.' lib/threadline/evidence.ex`
3. `rg -n '^\s*def record_' lib/threadline/evidence.ex`

`mix verify.test` is intentionally not the authority for Phase 96. The Phase 96-02 summary records a pre-existing alias-drift failure in `test/threadline/ci_topology_contract_test.exs` that is outside Phase 96 ownership; Phase 99 owns the named-alias topology, and commit `b636c17` ("fix(99-02): update ci.all topology contract to expanded doc_contract alias") is the most recent fix on that surface. Phase 101 disclaims rather than reopens that scope.

## Requirement closure

| Requirement | Status | Why it closes on the current tree |
| --- | --- | --- |
| `PROOF-01` | ✓ SATISFIED | Threadline still exposes a Phoenix-optional `Threadline.Evidence` public context with subject-focused create helpers for the closed Phase 95 subject set, append-only history reads, and list-vs-singular latest projections, with all defaults remaining mechanical and no ambient runtime state in the read or write path. |

## Not closed here

- `.planning/REQUIREMENTS.md` remains intentionally unreconciled in this phase.
- `.planning/ROADMAP.md` remains intentionally unreconciled in this phase.
- `.planning/STATE.md` remains intentionally unreconciled in this phase.
- Phase 101 closes the missing Phase 96 verification and validation chain only; milestone authority-surface reconciliation remains Phase 103 work.
