# Phase 228: Telemetry - Research

**Researched:** 2026-10-01
**Domain:** `:telemetry` instrumentation for an Elixir/Ecto/PostgreSQL audit library (export, retention, operator-surface auth), plus doc-contract tests and a redaction-leak property extension
**Confidence:** HIGH — every claim below is either read directly from this repo's code/tests this session, or from `deps/telemetry/src/telemetry.erl` (the vendored dependency, pinned `telemetry 1.4.2` in `mix.lock:43`). No new external packages are introduced by this phase.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

D-01..D-19, verbatim from `.planning/phases/228-telemetry/228-CONTEXT.md`:

- **D-01:** `Threadline.Telemetry` holds a module-attribute registry of every event: name, measurement keys, metadata keys, and the "when emitted" sentence used in docs. It is exposed through an internal `__events__/0` (`@doc false`), not a public `events/0`. A public attach-all helper is deferred: every future event would become an API change before 1.0 (PITFALLS Pitfall 10).
- **D-02:** Every emission goes through `@doc false` helper functions in `Threadline.Telemetry`, matching the existing `transaction_committed/2` style. `:telemetry.execute`/`:telemetry.span` may appear only in `lib/threadline/telemetry.ex`. The three operator-surface emitters (`operator_surface/auth.ex`, `theme_auth_plug.ex`, `export_auth_plug.ex`) move behind helpers.
- **D-03:** Helpers accept only integers, booleans, atoms and exception structs (from which they take the module). They never accept a binary, so TELE-03 holds in code and not just in review.
- **D-04:** Emit once per logical export, where the unit of work ends and the outcome is known, outside any DB transaction (Pitfall 8). The emitters are the eager `Threadline.Export.to_csv_iodata/2` and `to_json_document/2`; `Threadline.Export.Orchestrator.run/2`, after the transaction function returns; the operator-surface export controller's chunked path (`send_chunked_stream`), after its `reduce_while`. Nothing is emitted from `format_changes_iodata/3`, `stream_changes/2`, `stream_export_rows/2`, `count_matching/2` or `csv_header/1`. The guide documents that adopters who build their own export on the stream primitives own that unit of work.
- **D-05:** The `[:threadline, :export, :completed]` shape is measurements `%{duration: native, row_count: non_neg_integer}` and metadata `%{format: :csv | :json | :ndjson, truncated: boolean}`. `duration` from `System.monotonic_time/0`, native units. `truncated` is metadata, not a 0/1 measurement. `table` is dropped. Format atoms use the user-facing vocabulary: `:wrapped`/`:json_wrapped` map to `:json`; the async job is always `:csv`.
- **D-06:** The `[:threadline, :export, :failed]` shape is the same measurements (`row_count` = rows written before failure, 0 for eager functions) plus metadata `%{format:, error_kind: atom, exception: module | nil}`. `error_kind` is a closed set: `:exception | :client_closed | :storage_error | :transaction_failed` (planner may narrow to what the code can actually produce). No `reason` string.
- **D-07:** The failure contracts don't change. Eager functions `try/rescue`, emit `:failed`, then `reraise e, __STACKTRACE__`. The orchestrator emits `:failed` on every `mark_failed` branch and still returns `{:error, _}`. The clock starts before filter validation. A chunked download whose client disconnects (`{:error, :closed}`) is `:failed` with `error_kind: :client_closed`. Export does not use `:telemetry.span/3` (Pitfall 9).
- **D-08:** The `[:threadline, :retention, :purge, :start | :stop | :exception]` span starts only after `purge/1`'s input checks (`:repo` fetch, `Policy.resolve!`, the `{:error, :disabled}` return, `resolve_cutoff/2`). It wraps only the `dry_run_result`/`run_with_tracking` branch. A disabled or misconfigured call emits nothing. `:exception` means a runtime database failure. The `purge/1` return contract is unchanged.
- **D-09:** Span shape: start/stop metadata are `%{dry_run: boolean}` only (passed again at `:stop` since `:telemetry` does not merge start metadata into stop). The span function returns `{result, Map.take(result, [:deleted_changes, :deleted_transactions, :batches_run]), %{dry_run: dry_run?}}`. Cutoff, policy, repo and prefix are not included.
- **D-10:** One `[:threadline, :retention, :batch_purged]` per `purge_loop` step, emitted after that step's change `delete_all` and its full orphan drain have returned. Measurements: `%{deleted_changes, deleted_transactions, duration: native}`; metadata `%{}`. Fires for every step including the final empty one. A dry run emits zero batch events. The guide notes batch events fire before an outer caller-wrapped transaction commits; for deleted-row totals the guide points to `batch_purged` since dry-run stop counts are preview counts.
- **D-11:** The exception-path test calls `purge(repo: Repo, storage_schema: "<missing schema>")` with retention enabled; real database, no mocks, safe under async:false with no sandbox. Asserts `:start` then `:exception` (`kind: :error`), no `:stop`, and the re-raise. `kind/reason/stacktrace` metadata on `:exception` is a documented exemption in the allowlist; the guide warns not to forward `reason`/`stacktrace` to metrics.
- **D-12:** Three contract tests, following `*_contract_test.exs` style: (1) runtime allowlist — attach to every registry event, drive a real operation for each, assert observed keys equal the registry entry; an unlisted key or a never-fired event turns it red. (2) static scan — `:telemetry.execute`/`:telemetry.span` appear only in `lib/threadline/telemetry.ex`. (3) doc parity — parse the moduledoc table and `guides/telemetry.md`'s table, compare both to `__events__/0`.
- **D-13:** Raising-handler test: attach a raising handler to the export events, `batch_purged` and the purge `:stop`. Run an export and a purge; assert normal result shapes; assert the handler is detached (`:telemetry.list_handlers/1`); optionally assert `[:telemetry, :handler, :failure]` fired. Use `capture_log` and async:false. `:telemetry` 1.4.2 detaches a failing handler from all of its events, including across `attach_many`; the guide warns about this (Pitfall 6).
- **D-14:** The PROP-04 telemetry observer goes in `test/threadline/capture/redaction_leak_property_test.exs`. In `setup`, `attach_many` a uniquely-id'd, non-raising handler to `__events__/0` that sends `{event, measurements, metadata}` to the test pid, with an `on_exit` detach. Each iteration drains the mailbox before and after `build_surfaces`, and appends `{"telemetry:" <> Enum.join(event, "."), inspect(meas) <> inspect(meta)}` to LeakOracle's surfaces. A structural assertion requires at least one export event per iteration. No extra DB work, `PropertyRuns.db(20)` unchanged.
- **D-15:** Both tables (moduledoc + guide) are hand-written markdown, kept honest by the D-12 parity test, not generated by interpolation. The moduledoc's "five events" prose becomes a single table of every event, operator-surface events included, linking to the guide.
- **D-16:** `guides/telemetry.md`, in order: (1) event table, (2) one `attach_many` example per family (capture, health, export, retention, operator surface), (3) a `telemetry_metrics` example, (4) a warning handlers must not raise, (5) a cardinality warning, (6) the redaction side-door warning, (7) the `[:my_app, :repo, :query]` recipe matching `metadata.source in ~w(audit_changes audit_transactions audit_actions)`, with verified caveats (`:source` is the bare table name with no prefix; nil for raw SQL/subquery roots; trigger-side capture never appears in repo telemetry; never log `:params`). Registration: add to `mix.exs` docs `extras` and `groups_for_extras` "operate" group; update `guide_graph_contract_test.exs` (`@lanes` operate list, an inbound edge from a non-README guide, guide count 19→20); change `guides/operator-surface.md:185` to link to the new guide.
- **D-17 (HIGH-IMPACT, maintainer decision 2026-10-01):** Strip now — one-way reversibility. `[:threadline, :operator_surface, :authorize]`, `[..., :export_authorize]` and `[..., :actor_ref_mismatch]` lose `actor_ref`, `session_actor_ref` and `scope_actor_ref` (`result`, `count` and `path` stay; `scope_keys` stays only if it holds no identity values, which the planner checks). `[:threadline, :health, :checked, :error]` replaces `%{error: message}` with `%{exception: module}`. Callers are updated (`test/threadline/operator_surface/auth_test.exs:116`, `operator_surface/coverage/on_mount.ex` and `coverage_live.ex` for the health error). Both go under CHANGELOG `### Breaking changes` for 0.12.0, in adopter language, each with what to change.
- **D-18:** The atom-valued measurements stay as they are and are documented: `status` on `action.recorded` and `result` on the operator-surface events. They break the numbers-in-measurements convention but are not TELE-03 leaks. Moving them to metadata waits for v1.45 (deferred).
- **D-19:** VERIFICATION reports the suite wall clock before and after (ROADMAP SC5), measured like 227 (local full `mix test`, and the partitioned CI figure if a run is granted). No new `[:threadline, :query, ...]` event and no Mix-task event; the D-12 static scan plus the registry make that checkable.

### Claude's Discretion

- Helper names and arities; exact registry data structure; how the doc-parity test parses tables.
- Which operator-surface fixtures drive the three auth events in the runtime allowlist test.
- Whether `error_kind` needs all four atoms or a subset the code can actually reach.

### Deferred Ideas (OUT OF SCOPE)

- A public `Threadline.Telemetry.events/0` for attach-all DX: revisit at the v1.45 contract milestone.
- Moving atom `status`/`result` measurements into metadata: v1.45 contract (D-18).
- A `[:threadline, :retention, :purge, :disabled]` event for "cron fired but disabled" alerting: additive later if asked.
- `surface: :api | :operator_surface | :job` metadata on export events: additive later.
- Stream-primitive (`stream_export_rows`) export events: additive later if adopters ask.
- A `retention_runs` row stays at `"running"` after a mid-run exception: a pre-existing behavior, not telemetry; candidate backlog item.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TELE-01 | An operator can attach to `[:threadline, :export, :completed]` and `[:threadline, :export, :failed]`, which carry a row count, a duration and a format. Both are emitted after the export finishes, on both outcome branches. | Pattern 2 (exact emission call sites per function, including the `send_chunked_stream` outcome-tracking gap that needs a code change, not just a telemetry call); Open Question 3 on `row_count` accumulation in the Orchestrator |
| TELE-02 | An operator can observe retention purges through a `:telemetry.span/3` on `[:threadline, :retention, :purge, :start \| :stop \| :exception]`, plus a `[:threadline, :retention, :batch_purged]` event per batch that carries the rows deleted. | Pattern 3 (span-opens-late boundary verified against `retention.ex:53-84`; `:telemetry.span/3` mechanics verified against the vendored erl source; per-step batch emission point verified against `purge_loop/7`) |
| TELE-03 | No Threadline telemetry event carries row values, actor identifiers, correlation ids or free-text reasons. An allowlist test pins every event's keys. A test handler attached during the redaction property never observes plaintext. A raising handler does not break the instrumented operation. | Pattern 4 (D-12.1 allowlist test shape); Common Pitfalls 5/6/7; Breaking-Change Blast Radius section (exact D-17 call sites and the tests that must change); D-13's handler-detach semantics verified against `telemetry.erl:110-111,196-218` |
| TELE-04 | An adopter can find every event in one place: an event table in the `Threadline.Telemetry` moduledoc and a new `guides/telemetry.md`. The guide includes the host-repo `[:my_app, :repo, :query]` recipe. | Pattern 4 (doc-parity precedent); Code Examples' `[:my_app, :repo, :query]` recipe (verified `:source` semantics against `ecto_sql`'s `sql.ex` and this repo's own schema declarations); Breaking-Change Blast Radius's doc-prose table (exact lines in `guides/operator-surface.md` and `lib/threadline/telemetry.ex` needing correction); `guide_graph_contract_test.exs`'s exact 19→20 mechanics |

</phase_requirements>

## Summary

Phase 228 is almost entirely decided already: `228-CONTEXT.md` D-01..D-19 lock every event shape, emission site, and doc change. This research file's job is to verify each locked decision against the actual code and to surface the concrete edit list the planner needs — exact line-level call sites, exact test assertions that break, and exact contract-test shapes that gate the work.

The central finding: **nothing here needs a new library**. `:telemetry` 1.4.2 is already a transitive dependency (via `telemetry_metrics`/Phoenix/Ecto); `Threadline.Telemetry` already exists with five events and the `@doc false` helper convention this phase extends. The work is (1) four new helper functions for export/retention, (2) editing three existing helpers' signatures and four existing call sites to strip identity fields (D-17, a breaking change), (3) three new contract tests plus one raising-handler test, (4) one new guide plus a doc-parity test, and (5) a PROP-04 property-test extension that attaches a telemetry observer (D-14) — the extension point for this already exists and is explicitly documented as reserved in `test/support/leak_oracle.ex`.

**Primary recommendation:** Follow CONTEXT.md D-01..D-19 exactly; this file exists to pin the exact call sites, the exact breaking test assertions, and the exact contract-test mechanics so the planner does not have to re-derive them.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Event emission (execute/span) | Capture/Semantics boundary — but implemented as a cross-cutting library concern | — | `Threadline.Telemetry` is not one of the three domain layers; it is observability plumbing that every layer calls into (D-02: all `:telemetry.execute`/`:telemetry.span` calls live in this one module) |
| Export completion/failure observability | Exploration/operations layer | — | Export is squarely an exploration-layer concern (CLAUDE.md); the new events observe its outcome, they don't change its data model |
| Retention purge span + batch events | Exploration/operations layer | — | Retention is explicitly named in CLAUDE.md's exploration/operations layer list |
| Operator-surface auth event stripping | Exploration/operations layer (operator UI) | — | `operator_surface/auth.ex`, `theme_auth_plug.ex`, `export_auth_plug.ex` are operator-surface (UI) code, already past 1.0 freeze concerns are irrelevant pre-1.0 but the breaking-change discipline still applies |
| Doc contracts (moduledoc table, guide, parity test) | N/A (docs/test infrastructure) | — | Follows the existing `*_doc_contract_test.exs` / `guide_graph_contract_test.exs` family already present in `test/threadline/` |
| Redaction-property telemetry observer | Capture layer (property under test) + test infrastructure | — | PROP-04 property lives in `test/threadline/capture/`; the observer is test-only, attached in `setup`, not library code |

This phase does not touch the Capture layer's trigger-backed persistence, nor does it introduce a `[:threadline, :query, ...]` event (explicitly out of scope per REQUIREMENTS.md's anti-features table and ROADMAP SC5).

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | 1.4.2 [VERIFIED: mix.lock:43] | Event execute/span primitives | Already a transitive dependency; Ecto, Oban, Phoenix, Finch, Broadway all use it as the de facto Elixir observability contract |

No new dependency is added by this phase. `telemetry_metrics` is referenced only in guide prose (an example recipe for adopters), not added as a project dependency — confirm this stays true at plan time (it is not currently a `mix.exs` dep; the guide's example is illustrative code adopters would add to their own app).

### Supporting

None. This phase is pure library code + tests + docs on top of the existing `:telemetry` dependency.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:telemetry.execute/3` on export's eager functions | `:telemetry.span/3` | Rejected by D-07: export's public contract is `{:ok, _} | {:error, _}` via `try/rescue` + `reraise`, not exception-propagating; `span/3`'s exception metadata would also leak message/stacktrace (PITFALLS Pitfall 9) |
| `:telemetry.execute/3` for retention purge | A second execute-only event pair (no span) | Rejected: retention purge is the one genuine bounded unit-of-work with a real mid-run exception risk (database failure mid-batch), matching Oban's `[:oban, :job, :start\|:stop\|:exception]` precedent — `research/FEATURES.md:41-51` |

**Installation:** none required — `:telemetry` is already resolved via existing deps.

## Package Legitimacy Audit

Not applicable. This phase adds zero new external packages (npm, pip, cargo, or Hex). `:telemetry` is an existing, already-vetted transitive dependency pinned in `mix.lock`.

## Architecture Patterns

### System Architecture Diagram

```
                      ┌─────────────────────────────┐
                      │   Threadline.Telemetry       │
                      │   (@doc false helpers;       │
                      │   ONLY module calling        │
                      │   :telemetry.execute/span)   │
                      └──────────────┬───────────────┘
                                     │ helper calls
         ┌───────────────────────────┼───────────────────────────┐
         │                           │                           │
┌────────▼─────────┐      ┌──────────▼──────────┐      ┌─────────▼──────────┐
│ Export emitters   │      │ Retention emitters   │      │ Operator-surface    │
│ (D-04)            │      │ (D-08..D-10)          │      │ auth emitters       │
│                   │      │                       │      │ (existing, D-17     │
│ to_csv_iodata/2   │      │ purge/1 wraps         │      │ strips identity)    │
│ to_json_document/2│      │ dry_run_result or     │      │                     │
│ Orchestrator.run/2│      │ run_with_tracking in  │      │ auth.ex, theme_auth │
│ (after txn fn      │      │ a span AFTER input   │      │ _plug.ex,           │
│ returns)           │      │ checks pass          │      │ export_auth_plug.ex │
│ export_controller's│      │                       │      │                     │
│ send_chunked_stream│      │ purge_loop emits      │      │                     │
│ (after reduce_while)│      │ batch_purged per step │      │                     │
└────────┬──────────┘      └──────────┬──────────────┘      └─────────┬───────────┘
         │                           │                                │
         └───────────────┬───────────┴────────────────┬──────────────┘
                          │                            │
                 ┌────────▼─────────┐        ┌─────────▼──────────┐
                 │ Attached handlers │        │ PROP-04 property's  │
                 │ (adopter code,    │        │ test observer       │
                 │ CI contract tests,│        │ (D-14): appends     │
                 │ guide recipe)     │        │ telemetry:<event>   │
                 │                   │        │ surfaces to         │
                 │                   │        │ LeakOracle          │
                 └───────────────────┘        └──────────────────────┘
```

A reader can trace: a request/job calls `Threadline.Export.to_csv_iodata/2` → the function's `try/rescue` either returns `{:ok, _}` (success path) or re-raises after calling `Threadline.Telemetry.emit_export_failed/_` (failure path) → whichever branch executes calls into `Threadline.Telemetry`, the sole module touching `:telemetry.execute`/`:telemetry.span` (D-02, enforced by a static-scan contract test, D-12.2) → attached handlers (adopter code or the PROP-04 test observer) receive the event.

### Recommended Project Structure

No new files beyond:
```
lib/threadline/telemetry.ex                              # extended with new helpers (D-01..D-03)
guides/telemetry.md                                      # new guide (D-16)
test/threadline/telemetry_registry_contract_test.exs      # D-12 (name at planner's discretion)
test/threadline/telemetry_raising_handler_test.exs        # D-13 (name at planner's discretion)
test/threadline/capture/redaction_leak_property_test.exs  # extended, not new (D-14)
```

### Pattern 1: Central registry + `@doc false` helpers (D-01, D-02)

**What:** `Threadline.Telemetry` holds a module-attribute registry of every event (name, measurement keys, metadata keys, "when emitted" sentence). An internal `__events__/0` (tagged `@doc false`) exposes it for contract tests; no public `events/0` ships this phase (deferred — a public attach-all helper would make every future event an API change pre-1.0, per Pitfall 10 reasoning already recorded in D-01).

**When to use:** Any new telemetry event in this codebase, starting now.

**Example (existing style to extend), `lib/threadline/telemetry.ex:56-64`:**
```elixir
# Source: lib/threadline/telemetry.ex:56-64 (read this session)
def transaction_committed(_transaction, opts \\ []) do
  table_count = Keyword.get(opts, :table_count, 0)
  :telemetry.execute([:threadline, :transaction, :committed], %{table_count: table_count}, %{})
end

@doc false
def emit_action_recorded(status) do
  :telemetry.execute([:threadline, :action, :recorded], %{status: status}, %{})
end
```
New export/retention helpers follow this `@doc false` shape exactly.

### Pattern 2: Execute-only on both outcome branches, after the unit of work ends (D-04..D-07)

**What:** Export emits `:completed`/`:failed` via plain `:telemetry.execute/3` calls on each branch — never `:telemetry.span/3` — because export's public contract is `{:ok, _}` via normal return, or an exception via `reraise`, never a span-shaped `{:error, _}` return from inside the span function.

**Exact emission call sites, verified this session:**

| Site | File:line | Current shape | What changes |
|------|-----------|----------------|---------------|
| `to_csv_iodata/2` | `lib/threadline/export.ex:71-103` | No `try/rescue`; raises propagate from `Query.validate_timeline_filters!/1` or `repo.all/2` with no telemetry | Wrap in `try/rescue`, emit `:completed` after success (just before `{:ok, %{...}}` return) and `:failed` + `reraise` in the rescue clause. Clock starts at function entry (before filter validation), so a bad-filter raise is `:failed` (D-07) |
| `to_json_document/2` | `lib/threadline/export.ex:114-154` | Same shape as above | Same treatment |
| `Orchestrator.run/2` → `run_job/3` | `lib/threadline/export/orchestrator.ex:53-74` | `try/rescue` already exists; `mark_failed/4` is called on 4 distinct branches (`handle_transaction_result/4`'s three clauses at lines 101-138, plus the outer `rescue` at line 69-73) plus `compensate_failed_finalization/6` (line 252-272) | Emit `:completed` only on the true success path (inside `handle_transaction_result({:ok, :written}, ...)` after `persist_export`/`finalize_stored_export` succeeds — i.e. after `completion_fn` returns `{:ok, _job}`, line 234); emit `:failed` on **every** `mark_failed` call site (D-07: "on every `mark_failed` branch") — that is 5 call-through paths: `run_job`'s rescue (line 71), `handle_transaction_result/4`'s 3 failure clauses (lines 116, 123, 130-135), and `compensate_failed_finalization/6`'s two branches (lines 255, 262) |
| `export_controller.ex`'s chunked path | `lib/threadline/operator_surface/controllers/export_controller.ex:231-256` | `send_chunked_stream/4`'s `reduce_while` at lines 244-252 **does not currently distinguish** a clean finish from `{:error, :closed}` from `{:error, _other}` — all three collapse to the same `{conn, _first_batch?}` accumulator shape with no outcome signal threaded out | **Code change needed, not just telemetry wiring**: the `reduce_while` accumulator must track outcome (`:ok`, `:client_closed`, or `{:error, reason}`) so the function can emit `:completed` after a clean finish and `:failed` with `error_kind: :client_closed` specifically on the `{:error, :closed}` branch (D-04, D-06). This is the one site where D-04's "the operator-surface export controller's chunked path" instruction requires an actual logic change, not only an added emit call |

**Shape (D-05, D-06 — verbatim from CONTEXT, now cross-checked against the code above for feasibility):**
- `[:threadline, :export, :completed]` — measurements `%{duration: native, row_count: non_neg_integer}`, metadata `%{format: :csv | :json | :ndjson, truncated: boolean}`.
  - `duration` via `System.monotonic_time/0` deltas (native units, matching Ecto/Phoenix/Oban convention — this is a convention claim, not independently verified in this session, tag `[ASSUMED]` pending cross-check against an Ecto telemetry doc at plan time if precision matters).
  - `row_count` for the eager functions is `returned_count` from the `{:ok, %{returned_count: n, truncated: t}}` result already computed at `lib/threadline/export.ex:100` / `:151`. For the Orchestrator and the chunked controller path, `row_count` must be accumulated across the streamed chunks (Orchestrator: count rows written to the temp file in `write_temp_csv/3`, `lib/threadline/export/orchestrator.ex:77-99`; controller: count rows across `Stream.chunk_every(@chunk_batch_size)` batches in `send_chunked_stream/4`).
  - `format` atoms: `:wrapped`/`:json_wrapped` map to `:json`; the async job (Orchestrator) is always `:csv` (it only ever writes CSV, confirmed at `orchestrator.ex:81,91`).
- `[:threadline, :export, :failed]` — measurements `%{row_count}` (rows written before failure; `0` for eager functions since they fail before any streaming accumulation), metadata `%{format:, error_kind: atom, exception: module | nil}`.
  - `error_kind` candidates: `:exception` (a raise), `:client_closed` (chunked download client disconnect), `:storage_error` (Orchestrator's `{:storage_error, reason}` compensation path, `orchestrator.ex:162-166`), `:transaction_failed` (Orchestrator's `{:error, reason}` from `ctx.transaction_fn`, `orchestrator.ex:121-125`). D-18 leaves it to the planner to narrow this set to what the code can actually produce — the eager functions (`to_csv_iodata/2`, `to_json_document/2`) can only ever produce `:exception`; the chunked controller path can only ever produce `:exception` or `:client_closed`; only the Orchestrator can produce all four.

### Pattern 3: One span around the unit of work that can fail partway (D-08, D-09, D-11)

**What:** `[:threadline, :retention, :purge, :start | :stop | :exception]` via `:telemetry.span/3`, opened only after `purge/1`'s input checks pass.

**Verified span-opens-late boundary, `lib/threadline/retention.ex:53-84`:**
```elixir
# Source: lib/threadline/retention.ex:53-84 (read this session)
def purge(opts) when is_list(opts) do
  repo = Keyword.fetch!(opts, :repo)              # raises KeyError before any span — not purge/1's return contract, a hard crash
  ...
  policy = Policy.resolve!(retention_kw)           # raises before any span
  if policy.enabled != true do
    {:error, :disabled}                            # returns before any span — a disabled call emits NOTHING (D-08)
  else
    policy_cutoff = Policy.cutoff_utc_datetime_usec!()
    cutoff = resolve_cutoff(Keyword.get(opts, :cutoff), policy_cutoff)  # may raise ArgumentError before any span
    if dry_run? do
      dry_run_result(repo, cutoff, policy, storage_opts)   # ← span wraps THIS call (D-08)
    else
      run_with_tracking(...)                               # ← span wraps THIS call (D-08)
    end
  end
end
```
This confirms D-08's claim precisely: the span must wrap only the `dry_run_result/4` or `run_with_tracking/7` call, nested inside the `if policy.enabled != true` / `if dry_run?` branching — not the whole `purge/1` body.

**Span's `:telemetry` mechanics, verified against the vendored dependency, `deps/telemetry/src/telemetry.erl:349-369`:**
```erlang
% Source: deps/telemetry/src/telemetry.erl:349-369 (read this session)
span(EventPrefix, StartMetadata, SpanFunction) ->
    ...
    execute(EventPrefix ++ [start], #{...}, merge_ctx(StartMetadata, DefaultCtx)),
    try SpanFunction() of
      {Result, StopMetadata} -> ... execute(EventPrefix ++ [stop], Measurements, merge_ctx(StopMetadata, DefaultCtx)), Result;
      {Result, ExtraMeasurements, StopMetadata} -> ... execute(EventPrefix ++ [stop], Measurements, merge_ctx(StopMetadata, DefaultCtx)), Result
    catch
        Class:Reason:Stacktrace ->
            execute(EventPrefix ++ [exception], #{...}, merge_ctx(StartMetadata#{kind => Class, reason => Reason, stacktrace => Stacktrace}, DefaultCtx)),
            erlang:raise(Class, Reason, Stacktrace)
    end.
```
This **confirms three things D-09/D-11 depend on**:
1. **`StartMetadata` is NOT automatically merged into the `:stop` event** — only `StopMetadata` (from the span function's return tuple) is used at `:stop`. This is exactly D-09's claim ("`:telemetry` does not merge start metadata into stop, so it is passed again at `:stop`") — `[VERIFIED: deps/telemetry/src/telemetry.erl:349-369]`.
2. **The 3-tuple return `{Result, ExtraMeasurements, StopMetadata}` is a supported span-function return shape** — this is exactly what D-09 specifies: `{result, Map.take(result, [...]), %{dry_run: dry_run?}}`.
3. **On `:exception`, the metadata is `StartMetadata` merged with `kind`/`reason`/`stacktrace`** — not `StopMetadata`. This confirms D-11's claim that `kind`/`reason`/`stacktrace` is a "documented exemption" baked into `:telemetry` itself, not something Threadline's code adds, and confirms the guide must warn specifically against forwarding `reason`/`stacktrace` (they can contain interpolated DB error text, the Pitfall 5/9 concern).

**Handler-failure detach semantics, verified for D-13, `deps/telemetry/src/telemetry.erl:110-111, 196-218`:**
```erlang
% Source: deps/telemetry/src/telemetry.erl:110-111 (doc comment, read this session)
% "failure of the handler on any of these invocations will detach it from
% all the events in EventNames (the same applies to manual detaching using detach/1)."
```
and the actual detach + failure-event emission at lines 196-218 (`do_execute/4`): a raising handler is detached (line 205-ish) and `[telemetry, handler, failure]` fires (line 213). This is attached via `attach_many/4`, so **one raising handler attached to multiple events (export `:completed`+`:failed`, `batch_purged`, purge `:stop`, as D-13 specifies) is detached from ALL of them on its first failure**, not just the one event that triggered the failure. `[VERIFIED: deps/telemetry/src/telemetry.erl:110-111,196-218]` — matches `telemetry 1.4.2` per `mix.lock:43`.

**Per-step batch emission (D-10), verified against `purge_loop/7`, `lib/threadline/retention.ex:173-215`:**
```elixir
# Source: lib/threadline/retention.ex:173-207 (read this session)
Enum.reduce_while(1..max_batches, {0, 0, 0}, fn idx, {tc, tt, _} ->
  n1 = delete_change_batch(repo, cutoff, batch_size, storage_opts)     # delete_all, line 176
  n2 = if delete_empty?, do: drain_orphan_batches(...), else: 0        # full orphan drain, line 178-183
  ...
  cond do
    n1 == 0 and n2 == 0 -> {:halt, {tc, tt, idx}}
    ...
  end
end)
```
This confirms D-10: the right emission point for `[:threadline, :retention, :batch_purged]` is right after `n1`/`n2` are computed each iteration (after that step's full delete + orphan drain have both returned), with `idx` naturally giving `batches_run` equal to the event count including the terminating empty step (D-10's "it fires for every step, including the final empty one"). Confirmed: `purge/1` has no wrapping `Repo.transaction` at any level — `delete_change_batch/4` and `drain_orphans/4` each call `repo.delete_all/2` directly, no transaction wrapper — so every batch's statements have already autocommitted by the time the event would fire (D-10's claim, matches CLAUDE.md's "harder to miss capture than to enable it" correctness-by-default spirit applied here to not double-counting on retry).

### Pattern 4: Doc-parity contract test (D-12.3) — existing precedent

**What:** Parse the `Threadline.Telemetry` moduledoc table and `guides/telemetry.md`'s table, compare both against `__events__/0`.

**Precedent to follow:** `test/threadline/guide_graph_contract_test.exs` already has a `markdown_edges/1`-style Markdown parser (line 247) used for a different purpose (link graph, not table parsing), but it establishes the "parse committed Markdown, assert against a live source" pattern this repo already trusts. The `*_doc_contract_test.exs` family (e.g. `exports_doc_contract_test.exs`) is the more direct precedent for "assert doc prose/code block matches a runtime value."

### Anti-Patterns to Avoid

- **Emitting inside a DB transaction:** Already called out and avoided by design — `purge/1` has no enclosing transaction (confirmed above), and the export eager functions are not run inside `Repo.transaction`. The Orchestrator's `write_temp_csv/3` DOES run inside `ctx.transaction_fn.(...)` (`orchestrator.ex:61-66`) — the `:completed` emission must happen strictly after `handle_transaction_result({:ok, :written}, ...)` confirms the transaction returned `{:ok, _}` AND after `finalize_stored_export` succeeds, never inside `write_temp_csv/3` itself.
- **Using `:telemetry.span/3` for `{:ok,_}|{:error,_}`-contract functions:** Avoided per D-07/D-09 (export never spans; only retention purge spans, and purge's own contract is already a plain return, not exception-based — D-11 confirms the exception path is a genuine, un-caught database failure, not purge's normal `{:error, :disabled}` return).
- **Hand-typed literal doc tables with no parity check:** Avoided by D-12.3's doc-parity test, mirroring the project's existing allergy to "guard tests that only compare prose to a hand-typed literal" (SUITE-04, this same milestone).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Query-level observability for Threadline's own SQL | A `[:threadline, :query, ...]` event | Document the host's own `[:my_app, :repo, :query]` event filtered by `metadata.source` | Explicitly rejected as duplicative in REQUIREMENTS.md's anti-features table and `research/FEATURES.md:62-73`; the host's Ecto repo already emits this at equal or higher fidelity for zero new code |
| Paired start/stop/exception events | Hand-written `:telemetry.execute(start)` / `execute(stop)` / `try/rescue` boilerplate | `:telemetry.span/3` (for retention purge only) | `:telemetry.span/3` already handles the start/stop/exception triad correctly including re-raise semantics (verified above); hand-rolling it would risk missing the re-raise or double-emitting on handler failure |
| Handler-crash isolation | A custom supervised handler wrapper | Document the existing `:telemetry` 1.4.2 detach-on-failure behavior (D-13) | `:telemetry` itself already guarantees detach-on-raise and emits `[telemetry, handler, failure]`; building supervision around it is out of scope and out of Threadline's control (Pitfall 6) |

**Key insight:** every "don't hand-roll" item here is already correctly avoided by the locked decisions in CONTEXT.md — the research confirms there is no better-than-`:telemetry.span/3` primitive for retention, and no value in a parallel query event.

## Breaking-Change Blast Radius (D-17) — exact call sites and test fallout

This is the one area CONTEXT.md flags as HIGH-IMPACT and maintainer-decided (strip now). Verified blast radius, this session:

### `[:threadline, :operator_surface, :authorize]` — THREE distinct emission sites, not one

| Call site | File:line | Current metadata |
|---|---|---|
| LiveView `on_mount` | `lib/threadline/operator_surface/auth.ex:92-102` (`emit_telemetry/3`) | `%{path: "", actor_ref: actor_ref, scope_keys: scope_keys}` — `path` is **hardcoded to `""`** here (pre-existing quirk, not part of this phase's scope, but worth flagging to the planner since it means `path` metadata from the LiveView auth path is currently useless) |
| `ThemeAuthPlug` | `lib/threadline/operator_surface/theme_auth_plug.ex:75-86` | `%{path: conn.request_path \|\| "", actor_ref: ..., scope_keys: ...}` — here `path` IS populated from the real request path |
| `ExportAuthPlug` | `lib/threadline/operator_surface/export_auth_plug.ex:69-80` | `%{path: "", actor_ref: ..., scope_keys: ...}` — same hardcoded-`""` quirk as `auth.ex` |

All three must drop `actor_ref` (D-17). `scope_keys` is `Map.keys(scope) |> Enum.sort()` in every case — i.e. it is a list of atom **keys** of the host's opaque scope map, never values, so it does not itself carry identity data **unless a host chose an identity value as a map key** (not a value) — e.g. `%{"user-123" => true}`, which would be an unusual scope shape. The planner should document this nuance in the guide rather than treat `scope_keys` as unconditionally safe for every possible host scope shape; for the realistic shapes seen in this codebase's own tests (`%{user_id: 123, role: "admin"}`, `%{actor_ref: actor}`), `scope_keys` is safe (D-17's own caveat: "stays only if it holds no identity values, which the planner checks" — checked here: safe for all scope shapes exercised in this repo's test suite, `[VERIFIED: test/threadline/operator_surface/auth_test.exs:65-77,134-147]`, `[VERIFIED: test/threadline/operator_surface/theme_auth_plug_test.exs:33-52]`).

### Tests that break and must be updated (exact assertions found)

| File | Breaking assertion | Fix needed |
|---|---|---|
| `test/threadline/operator_surface/auth_test.exs:116-117` | `assert_receive {..., %{result: :error, count: 1}, %{actor_ref: ^actor_ref}}` (on `export_authorize` event) | Pattern must drop `actor_ref`; this event keeps `result` and `count`, so change to `%{result: :error, count: 1}, _metadata` or assert metadata is `%{}` |
| `test/threadline/operator_surface/theme_auth_plug_test.exs:51-52` | `assert_received {..., %{result: :granted}, %{actor_ref: "user:support"}}` | Pattern must drop the `actor_ref` metadata match entirely — this test's PURPOSE (proving `authorize_fn`'s returned scope becomes `threadline_scope`) is still provable via the `conn_out.assigns.threadline_scope` assertion two lines above; the telemetry assertion should switch to asserting `scope_keys: [:actor_ref]` instead |
| `test/threadline/operator_surface/export_auth_plug_test.exs` (8 occurrences, lines 25,36,51,85,103,117,189) | Multiple `assert_received {..., %{result: ...}, %{path: "..."}}` style patterns — **most of these only match on `path`, not `actor_ref`**, verified by grep; only patterns that explicitly destructure `actor_ref` need changes. Re-check each at plan time; do not assume all 8 need edits | Grep each site individually before editing — some may already be safe |
| `test/threadline/operator_surface/auth_test.exs` actor_ref_mismatch test (lines 92-96) | Asserts `metadata.session_actor_ref` / `metadata.scope_actor_ref` on `[:threadline, :operator_surface, :actor_ref_mismatch]` | D-17 strips these too (per CONTEXT: "lose `actor_ref`, `session_actor_ref` and `scope_actor_ref`") — this test needs a structural rewrite, not just a pattern tweak, since the entire point of the event becomes unobservable in its current test shape unless replaced with a non-identity signal (e.g. just `count: 1` with no metadata, or a boolean flag). **This needs a planning decision**: if `session_actor_ref`/`scope_actor_ref` are stripped entirely, the event degenerates to "a mismatch happened" with no diagnostic value at all — flag this as an open question below |
| `test/threadline/operator_surface/exports_doc_contract_test.exs:145-148,300-302` | Asserts the LiveView and `ExportAuthPlug` source text both reference `"actor_ref"` and emit the "SAME" authorize event — a source-text assertion about the word `actor_ref`, not a telemetry metadata assertion | Verify at plan time whether this test's `actor_ref` references are about the telemetry metadata key specifically (which would need updating) or about the unrelated `FilterParams`/`ActorRef` URL-key collapsing logic (which is untouched by this phase) — the grep context (`test/threadline/operator_surface/exports_doc_contract_test.exs:145-148`) suggests the latter (URL key collapsing), likely unaffected |

### Doc prose that must be updated

| File:line | Current text | Required change |
|---|---|---|
| `guides/operator-surface.md:185` | `` Telemetry event `[:threadline, :operator_surface, :authorize]` is emitted with the outcome (`:granted`, `:denied`, or `:error`). `` | D-16 says: change this line to link to the new `guides/telemetry.md` instead of (or in addition to) restating the event name inline |
| `guides/operator-surface.md:486` | `` `[:threadline, :health, :checked, :error]` fires on poll failure with metadata `%{error: message}`; alert on this for sustained drift. `` | Must change `%{error: message}` to `%{exception: module}` to match D-17's health-error shape change |
| `lib/threadline/telemetry.ex:22-25` (moduledoc) | `` `[:threadline, :health, :checked, :error]` — ... Metadata: `%{error: message}`. `` | Same correction, in the moduledoc table this phase is also rewriting into a full table per D-15 |
| `guides/production-checklist.md:30` | References `[:threadline, :health, :checked, :error]` generically for alerting, no metadata shape stated | No change needed — does not reference the old shape |

### `emit_health_checked_error/1` signature change (D-17 + D-03)

Current: `def emit_health_checked_error(error_message) when is_binary(error_message)` at `lib/threadline/telemetry.ex:93-99`, emitting `%{error: error_message}`.

Per D-03 ("Helpers accept only integers, booleans, atoms and exception structs, from which they take the module") this becomes something like `def emit_health_checked_error(exception) when is_exception(exception)`, emitting `%{exception: exception.__struct__}`.

**All three call sites must change their call shape**, not just the helper:

| Call site | File:line | Current call | Required call |
|---|---|---|---|
| `Threadline.OperatorSurface.Coverage.OnMount.assign_initial_coverage/1` | `lib/threadline/operator_surface/coverage/on_mount.ex:80-84` | `message = Exception.message(e); Threadline.Telemetry.emit_health_checked_error(message)` | `Threadline.Telemetry.emit_health_checked_error(e)` — but `message` is still needed for the `:threadline_coverage_error` assign (line 87), so keep computing `Exception.message(e)` separately for the assign, just change the telemetry call's argument |
| Same module, `refresh_coverage/1` | `lib/threadline/operator_surface/coverage/on_mount.ex:102-109` | Same pattern | Same fix |
| `Threadline.OperatorSurface.CoverageLive.fetch_coverage_for_schema/2` | `lib/threadline/operator_surface/live/coverage_live.ex:394-397` | Same pattern | Same fix |

## Common Pitfalls

(Cross-checked against `.planning/research/PITFALLS.md` Pitfalls 5-10; all are already addressed by CONTEXT.md's decisions. Listed here for the planner's verification-step reference, with the specific D-number that resolves each.)

### Pitfall 5: Redaction bypass via telemetry metadata
**What goes wrong:** A handler that logs metadata wholesale exposes PII if any metadata value is row-derived.
**Resolved by:** D-03 (helpers only accept integers/booleans/atoms/exception structs — never binaries) and D-06 (no `reason` string on `:failed`, only a closed `error_kind` atom set).
**Verification:** D-14's PROP-04 extension attaches a handler during the redaction property and asserts no canary plaintext appears in any `telemetry:<event>` surface — this is the acceptance check PITFALLS.md calls for.

### Pitfall 6: Raising handler silently detaches, losing ALL future observability
**What goes wrong:** confirmed above via `deps/telemetry/src/telemetry.erl:110-111` — detach-all, not detach-one.
**Resolved by:** D-13's raising-handler test, which must assert detachment via `:telemetry.list_handlers/1` (not just infer it), and the guide warning (D-16 step 4).

### Pitfall 7: Cardinality explosion from tagging on identity
**Resolved by:** D-05/D-09/D-10 metadata shapes contain no actor/correlation/job ids; D-16's guide includes an explicit cardinality warning (step 5).

### Pitfall 8: Double-emitting inside a transaction / before commit
**Resolved by:** D-04 (emit after the transaction function returns, never inside it) and the verified absence of any wrapping transaction in `purge_loop/7`.

### Pitfall 9: `:telemetry.span/3` leaking stacktrace/message or changing a function's `{:ok,_}|{:error,_}` contract
**Resolved by:** D-07 (export never spans) and D-11 (the one span used — retention purge — has an exception path that is a genuine uncaught DB failure, not a function whose contract was `{:error, _}`; `purge/1`'s own return contract is explicitly unchanged per D-08's final bullet).

### Pitfall 10: One-way event names/shapes
**Resolved by:** treating this as the last pre-1.0 chance to fix shapes (D-17's one-way reversibility note), and the doc-parity test (D-12.3) that keeps the documented contract honest going forward.

## Code Examples

### Attaching to the retention span (for the guide, D-16 step 2)

```elixir
# Illustrative — matches the :telemetry.span/3 contract verified at
# deps/telemetry/src/telemetry.erl:349-369
:telemetry.attach_many(
  "my-app-retention",
  [
    [:threadline, :retention, :purge, :start],
    [:threadline, :retention, :purge, :stop],
    [:threadline, :retention, :purge, :exception],
    [:threadline, :retention, :batch_purged]
  ],
  &MyApp.Instrumentation.handle_retention_event/4,
  nil
)
```

### The `[:my_app, :repo, :query]` recipe (D-16 step 7) — verified mechanics

```elixir
# Source: verified against deps/ecto_sql/lib/ecto/adapters/sql.ex:699-704 (read this session)
# `:source` is set only when the query's first binding source is a binary
# table name (defp put_source/2, guarded `when is_binary(elem(elem(sources, 0), 0))`).
# A raw `Repo.query!/2` call or a query rooted in a subquery does not go
# through this path, so `:source` is absent/nil for those.
:telemetry.attach(
  "my-app-threadline-queries",
  [:my_app, :repo, :query],
  fn _event, measurements, metadata, _config ->
    if metadata.source in ~w(audit_changes audit_transactions audit_actions) do
      MyApp.Metrics.record_query(metadata.source, measurements.query_time)
    end
  end,
  nil
)
```
`:source` is the **bare, unprefixed** table name — confirmed by reading the schema declarations directly: `` schema "audit_changes" `` at `lib/threadline/capture/audit_change.ex:49` and `` schema "audit_transactions" `` at `lib/threadline/capture/audit_transaction.ex:50` (storage-schema prefixing is applied separately via `prefix:` options, not baked into the schema source name). `audit_actions`'s schema source is confirmed the same way at `lib/threadline/semantics/audit_action.ex:35`. **The guide's caveats (D-16) are therefore all verified, not merely claimed**:
- `:source` is the bare table name with no prefix — `[VERIFIED: lib/threadline/capture/audit_change.ex:49, lib/threadline/capture/audit_transaction.ex:50, lib/threadline/semantics/audit_action.ex:35, deps/ecto_sql/lib/ecto/adapters/sql.ex:699-704]`.
- `:source` is nil for raw SQL (e.g. this repo's own `Repo.query!/2` calls in `LeakOracle`, `redaction_leak_property_test.exs`) and for subquery-rooted queries (e.g. `Export.count_matching/2`'s capped-count path, `lib/threadline/export.ex:196-199`, which wraps a subquery) — `[VERIFIED: deps/ecto_sql/lib/ecto/adapters/sql.ex:699-704]` (the `is_binary` guard on `elem(elem(sources,0),0)` fails for a subquery-shaped sources tuple).
- Trigger-side capture never appears in repo telemetry — `[ASSUMED]`, consistent with the architecture (triggers run inside PostgreSQL itself, not through any Ecto query the host's `Repo` would emit telemetry for) but not independently re-derived this session beyond the general trigger-backed capture model in CLAUDE.md.
- Never log `:params` — `[ASSUMED]` based on the general Ecto convention that query params are pre-redaction plaintext bind values; not re-derived from `sql.ex` this session but consistent with the Ecto telemetry docs' own warning (cited at `research/PITFALLS.md:107` from training knowledge, not re-fetched this session — tag as `[CITED: training knowledge of Ecto telemetry docs, not re-verified via Context7/web this session]`).

### D-12.1's runtime allowlist test shape (new, following `attach_telemetry!/1` precedent)

```elixir
# Illustrative shape, following the existing attach_telemetry!/1 helper at
# test/support/telemetry_helpers.ex:48-66 (read this session)
test "every registered event's observed keys equal its registry entry" do
  events = Threadline.Telemetry.__events__() |> Enum.map(& &1.name)
  ref = Threadline.TelemetryHelpers.attach_telemetry!(events)

  # ... drive one real operation per event family (export success/failure,
  # retention purge start/stop/exception, batch_purged, operator-surface
  # authorize/export_authorize/actor_ref_mismatch) ...

  for %{name: name, measurements: expected_m, metadata: expected_md} <- Threadline.Telemetry.__events__() do
    assert_receive {^name, ^ref, measurements, metadata}
    assert MapSet.new(Map.keys(measurements)) == MapSet.new(expected_m)
    assert MapSet.new(Map.keys(metadata)) == MapSet.new(expected_md)
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `[:threadline, :operator_surface, :authorize]` carrying `actor_ref` | Same event, identity fields stripped | This phase (0.12.0, pre-1.0) | Breaking for any adopter handler pattern-matching `actor_ref` out of this event's metadata — documented in CHANGELOG `### Breaking changes` per D-17 |
| `[:threadline, :health, :checked, :error]` metadata `%{error: message}` | `%{exception: module}` | This phase | Same breaking-change treatment |
| Five documented events | Nine-plus documented events (5 existing + export completed/failed + retention start/stop/exception + batch_purged) in one moduledoc table + a new guide | This phase | Additive observability surface; the shapes themselves become one-way once 0.12.0 ships (Hex can't unpublish) |

**Deprecated/outdated:** None — this phase does not deprecate any event name, only two metadata shapes (handled as a breaking change, not a deprecation, since there is no pre-1.0 deprecation window convention established in this codebase).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `duration` native-unit convention "matches Ecto/Phoenix/Oban" | Pattern 2, export shape | Low — this is prose framing for the guide, not a code behavior; `System.monotonic_time/0` native units are correct regardless of whether other libraries are cited accurately |
| A2 | Trigger-side capture never appears in host repo telemetry | Code Examples, `[:repo, :query]` recipe | Low — if wrong, the guide's caveat list in D-16 needs a correction, but this doesn't affect any code path in this phase |
| A3 | `:params` in Ecto's `[:repo, :query]` metadata are pre-redaction plaintext bind values (the "never log `:params`" warning) | Code Examples | Medium — if the guide's warning is wrong in detail, it under- or over-states a real risk to adopters; worth a quick confirmation against Ecto's own docs at plan/build time rather than shipping purely on training-knowledge framing |
| A4 | `actor_ref_mismatch`'s stripped-down shape (losing `session_actor_ref`/`scope_actor_ref`) still has diagnostic value as a plain `count: 1` signal | Breaking-Change Blast Radius | Medium — if the maintainer disagrees, the event may need a non-identity diagnostic substitute (e.g. a boolean "actors differ" flag is already all `count: 1` conveys) rather than shipping a near-value-less event; flagged as an Open Question below, not silently assumed away |

## Open Questions

1. **Does `[:threadline, :operator_surface, :actor_ref_mismatch]` retain any value once both identity fields are stripped?**
   - What we know: D-17 explicitly includes this event in the strip list, keeping only `count: 1` (verified it's the only non-identity key currently emitted, `lib/threadline/operator_surface/auth.ex:160-169`).
   - What's unclear: whether a bare count-of-mismatches-this-process event is worth keeping at all, versus being folded into a boolean on the `authorize` event, or just removed.
   - Recommendation: keep it as specified (D-17 is a locked maintainer decision) but flag in the guide that the event is now a pure incidence counter with no diagnostic payload — don't pretend it still helps debug which actors disagreed.

2. **`export_auth_plug_test.exs`'s 8 `assert_received` sites — exact subset needing edits.**
   - What we know: all 8 pattern-match on `[:threadline, :operator_surface, :authorize]`; most visibly destructure only `%{path: "..."}`, not `actor_ref`.
   - What's unclear: without reading every one of the 8 call sites' full context (not done exhaustively this session — time-boxed to the two most load-bearing ones), it's possible 1-2 more assert on `actor_ref` indirectly (e.g. via a bound variable from an earlier `{:ok, scope}` setup).
   - Recommendation: the planner's task for this file should re-grep `actor_ref` specifically within `export_auth_plug_test.exs` before editing, rather than assuming the two confirmed-safe patterns generalize to all 8.

3. **Does the Orchestrator's `row_count` accumulation (for `:completed`/`:failed`) need a new counter threaded through `write_temp_csv/3`, or can it be derived post-hoc?**
   - What we know: `write_temp_csv/3` streams via `Export.stream_export_rows/2 |> Stream.chunk_every(1000) |> Enum.each(...)` with no running count kept (`orchestrator.ex:85-93`).
   - What's unclear: whether to add an accumulator inside `Enum.each` (requires switching to `Enum.reduce` or a `Process` dictionary-free counter) or to count rows by re-reading the temp file's line count after the fact (CSV-specific, fragile).
   - Recommendation: switch `Enum.each` to `Enum.reduce(0, fn chunk, acc -> ...; acc + length(chunk) end)` — mechanical, no behavior change to the write path itself.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | All DB-backed tests (retention, PROP-04 extension) | ✓ | accepting connections on `/tmp:5432` [VERIFIED: `pg_isready`] | — |
| Elixir/OTP toolchain | `mix test`, `mix ci.all` | ✓ | Elixir 1.17.3-otp-27 pinned via `.tool-versions` [VERIFIED: `.tool-versions`, `elixir --version`] | — |
| `:telemetry` 1.4.2 | All telemetry emission/tests | ✓ | 1.4.2 [VERIFIED: `mix.lock:43`], vendored source readable at `deps/telemetry/src/telemetry.erl` | — |

No missing dependencies. No external service calls are introduced by this phase.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in), `telemetry` 1.4.2 for event mechanics under test |
| Config file | `test/test_helper.exs`; partition weights at `test/partition_weights.txt` (auto-regenerated by `bin/ci-test-partitions --write-weights`; a stale/missing entry for new test files only affects partition balance, never correctness — confirmed by the file's own header comment) |
| Quick run command | `mix test test/threadline/telemetry_registry_contract_test.exs test/threadline/telemetry_raising_handler_test.exs` (filenames at planner's discretion per D-12/D-13) |
| Full suite command | `mix ci.all` (per CLAUDE.md's canonical entrypoints) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TELE-01 | `[:threadline, :export, :completed]`/`:failed` carry row count, duration, format; both outcome branches tested | unit | `mix test test/threadline/export_test.exs` (extended) + a new telemetry assertion in the Orchestrator and controller test files | ✅ existing files extended, ❌ new assertions |
| TELE-02 | Retention span (`start/stop/exception`) + `batch_purged` per batch | unit (DB-backed, no Sandbox, matches existing `retention_test.exs` style: `async: false`) | `mix test test/threadline/retention_test.exs` (extended) | ✅ existing file extended |
| TELE-03 | Allowlist test, raising-handler test, PROP-04 observer never sees plaintext | unit + property | `mix test test/threadline/telemetry_registry_contract_test.exs test/threadline/telemetry_raising_handler_test.exs test/threadline/capture/redaction_leak_property_test.exs` | ❌ Wave 0 (two new files), ✅ existing property file extended |
| TELE-04 | Moduledoc table + `guides/telemetry.md` derived from `__events__/0`, not hand-typed | unit (doc-parity) | `mix test test/threadline/telemetry_registry_contract_test.exs` (the doc-parity assertion can live in the same file as D-12.1/D-12.2, or a separate file — planner's call) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the specific new/extended test file(s) for that task.
- **Per wave merge:** `mix test` (full local suite — this repo's convention per CLAUDE.md's "Honest default tests").
- **Phase gate:** `mix ci.all` green, plus `bin/verify-repo-hygiene` clean (CLAUDE.md convention).

### Wave 0 Gaps
- [ ] `test/threadline/telemetry_registry_contract_test.exs` (or equivalent name) — covers TELE-03 (allowlist, D-12.1), TELE-03 static scan (D-12.2), TELE-04 doc parity (D-12.3)
- [ ] `test/threadline/telemetry_raising_handler_test.exs` (or equivalent name) — covers TELE-03's raising-handler requirement (D-13)
- [ ] No new shared fixtures needed — `test/support/telemetry_helpers.ex`'s `attach_telemetry!/1` and `test/support/leak_oracle.ex`'s reserved `telemetry:<event>` surface convention already cover this phase's needs
- [ ] Framework install: none — `:telemetry` already present

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | This phase does not change authentication; it changes what authentication OUTCOME telemetry reveals |
| V3 Session Management | No | Unaffected |
| V4 Access Control | Indirectly (TELE-03) | The `authorize`/`export_authorize`/`actor_ref_mismatch` events observe access-control OUTCOMES; D-17 ensures the observability channel doesn't leak the identity that access control is protecting |
| V5 Input Validation | No | Not applicable — telemetry helpers validate their own input types (D-03: integers/booleans/atoms/exception structs only), which is a defensive-coding control, not user input validation |
| V6 Cryptography | No | Not applicable |
| V7 Error Handling and Logging (not in the V2-V6 list requested, but directly relevant) | Yes | TELE-03's entire purpose is exactly ASVS's logging-sensitive-data concern: ensure error/outcome telemetry never logs identity, correlation, or row data — the `error_kind` closed-atom-set pattern (D-06) and the `exception: module`-not-`message` pattern (D-17) are the standard control here |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Information disclosure via observability side-channel (telemetry metadata carrying PII/identity that bypasses the redaction/access-control boundary) | Information Disclosure | D-03's closed input-type allowlist on telemetry helpers; D-06's no-`reason`-string rule; D-17's strip of `actor_ref`/`session_actor_ref`/`scope_actor_ref`/raw error messages; D-14's property-test observer proving no plaintext crosses this channel |
| Denial of observability via handler crash (an adopter's broken handler silently going dark with no re-attach) | Denial of Service (of the monitoring function, not the audited system itself) | D-13's raising-handler test + guide warning (D-16 step 4); this is a documented `:telemetry` library limitation, not something Threadline's code can fully close — correctly scoped as "document, don't engineer around" |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/228-telemetry/228-CONTEXT.md` — locked decisions D-01..D-19, read this session
- `lib/threadline/telemetry.ex` — existing events, helper style, moduledoc (read in full this session)
- `lib/threadline/export.ex`, `lib/threadline/export/orchestrator.ex`, `lib/threadline/operator_surface/controllers/export_controller.ex` — export emission sites (read in full this session)
- `lib/threadline/retention.ex`, `lib/mix/tasks/threadline.retention.purge.ex` — retention span sites (read in full this session)
- `lib/threadline/operator_surface/auth.ex`, `theme_auth_plug.ex`, `export_auth_plug.ex`, `operator_surface/coverage/on_mount.ex`, `operator_surface/live/coverage_live.ex` — events to strip (read in full this session)
- `deps/telemetry/src/telemetry.erl` — execute/span/detach mechanics, lines 110-111, 196-218, 349-396 (read this session)
- `deps/ecto_sql/lib/ecto/adapters/sql.ex` — `:source` metadata derivation, lines 699-704, 972-992 (read this session)
- `mix.lock:43` — `:telemetry` version pin
- `test/support/telemetry_helpers.ex`, `test/support/leak_oracle.ex`, `test/support/property_runs.ex` — existing test infrastructure (read in full/part this session)
- `test/threadline/capture/redaction_leak_property_test.exs` — PROP-04 property to extend (read in full this session)
- `test/threadline/operator_surface/auth_test.exs`, `theme_auth_plug_test.exs`, `export_auth_plug_test.exs` (partial grep + targeted reads) — breaking-change test fallout
- `test/threadline/guide_graph_contract_test.exs` (partial read, lines 1-120, 190-210, 247) — doc-contract precedent and the exact "19→20 guides" mechanics
- `test/threadline/changelog_contract_test.exs` (partial read) — CHANGELOG structural contract
- `mix.exs` (lines 570-625) — `docs` extras/groups_for_extras configuration
- `guides/operator-surface.md` (lines 175-195, 486), `guides/production-checklist.md` (line 30), `guides/integration-contracts.md` (lines 265-290), `README.md` (lines 21-29, 130-160) — doc blast radius
- `CHANGELOG.md` (lines 1-45) — existing `## Unreleased — highlights` / `### Breaking changes` section to append to
- `.planning/config.json` — `nyquist_validation: true`, no `security_enforcement: false` override

### Secondary (MEDIUM confidence)
- `.planning/research/FEATURES.md` §A (lines 19-119) — original event-shape proposal, superseded in several details by CONTEXT.md's D-05/D-06/D-09 (noted explicitly in CONTEXT.md's canonical_refs)
- `.planning/research/PITFALLS.md` Pitfalls 5-10 (lines 74-158) — risk analysis, cross-checked against code this session and found consistent

### Tertiary (LOW confidence)
- Ecto telemetry docs' `:params` warning (A3 in Assumptions Log) — training-knowledge framing, not re-fetched via web/Context7 this session; low-stakes (affects guide prose only, not code)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, existing `:telemetry` version pinned and read directly
- Architecture (emission sites, span mechanics, breaking-change blast radius): HIGH — every call site cited was read this session with line numbers; the chunked-controller code gap (Pattern 2 table) was discovered by reading the actual `reduce_while` logic, not inferred
- Pitfalls: HIGH — all six PITFALLS.md items cross-checked against actual code and found either already resolved by CONTEXT.md decisions or confirmed via the vendored `:telemetry` source
- Doc/contract-test mechanics (D-12, D-16): HIGH — the exact `guide_graph_contract_test.exs` assertion that forces "19→20" was read directly, as was the `mix.exs` extras/groups_for_extras block

**Research date:** 2026-10-01
**Valid until:** 30 days (stable domain — no fast-moving external dependency; the only expiry risk is if `:telemetry` is upgraded past 1.4.2 before this phase lands, which would need the span/detach mechanics re-verified)
