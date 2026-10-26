# Phase 228: Telemetry - Context

**Gathered:** 2026-10-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators can observe export and retention runs through documented `[:threadline, ...]` telemetry
events, and a compliance reviewer can confirm that no Threadline event (new or existing) carries
audited data, actor identifiers, correlation ids or free-text reasons (TELE-01..04, ROADMAP SC1-SC5).

In scope: export `:completed`/`:failed` execute events, the retention purge span plus per-batch
event, a central event registry with an allowlist contract, stripping the existing events that
break TELE-03, the `Threadline.Telemetry` moduledoc table, a new `guides/telemetry.md` with the
host-repo `[:my_app, :repo, :query]` recipe, and a telemetry surface in the PROP-04 redaction property.

Out of scope (ROADMAP SC5 / REQUIREMENTS anti-features): any `[:threadline, :query, ...]` event,
any Mix-task-specific event, operator UI changes, and changing the atom-valued measurements on
existing events (deferred to v1.45).

</domain>

<decisions>
## Implementation Decisions

Research: three parallel advisor researchers (export emission, retention span, contract/docs),
synthesized into one set. The maintainer was asked only the HIGH-IMPACT question (D-17) and chose
the recommended option; every other pick is the recommendation, per the standing
"research then recommend" default and the maintainer's "auto follow ur recs" instruction.

### Registry and emission: one module owns every event
- **D-01:** `Threadline.Telemetry` holds a module-attribute registry of every event: name,
  measurement keys, metadata keys, and the "when emitted" sentence used in docs. It is exposed
  through an internal `__events__/0` (`@doc false`), not a public `events/0`. A public attach-all
  helper is deferred: every future event would become an API change before 1.0 (PITFALLS Pitfall 10).
- **D-02:** Every emission goes through `@doc false` helper functions in `Threadline.Telemetry`,
  matching the existing `transaction_committed/2` style. `:telemetry.execute`/`:telemetry.span`
  may appear only in `lib/threadline/telemetry.ex`. The three operator-surface emitters
  (`operator_surface/auth.ex`, `theme_auth_plug.ex`, `export_auth_plug.ex`) move behind helpers.
- **D-03:** Helpers accept only integers, booleans, atoms and exception structs (from which they
  take the module). They never accept a binary, so TELE-03 holds in code and not just in review.

### Export events (TELE-01)
- **D-04:** Emit once per logical export, where the unit of work ends and the outcome is known,
  outside any DB transaction (Pitfall 8). The emitters are:
  - the eager `Threadline.Export.to_csv_iodata/2` and `to_json_document/2`, which also cover the
    Mix task and the operator-surface iodata download (count <= 5,000);
  - `Threadline.Export.Orchestrator.run/2`, after the transaction function returns (the async
    governance job, both Task and Oban adapters);
  - the operator-surface export controller's chunked path (`send_chunked_stream`), after its
    `reduce_while`.

  Nothing is emitted from `format_changes_iodata/3` (it runs once per chunk), `stream_changes/2`,
  `stream_export_rows/2`, `count_matching/2` or `csv_header/1`. The guide documents that adopters
  who build their own export on the stream primitives own that unit of work and should emit their
  own event.
- **D-05:** The `[:threadline, :export, :completed]` shape is measurements
  `%{duration: native, row_count: non_neg_integer}` and metadata
  `%{format: :csv | :json | :ndjson, truncated: boolean}`.
  - `duration` comes from `System.monotonic_time/0`, in native units like Ecto, Phoenix and Oban;
    the guide shows `unit: {:native, :millisecond}`.
  - `truncated` is metadata, not a 0/1 measurement.
  - `table` is dropped: exports span many tables, it would usually be nil, and it would expose
    schema names.
  - Format atoms use the user-facing vocabulary: `:wrapped`/`:json_wrapped` map to `:json`, and
    the async job is always `:csv`.
- **D-06:** The `[:threadline, :export, :failed]` shape is the same measurements (`row_count` = rows
  written before the failure, 0 for eager functions) plus metadata
  `%{format:, error_kind: atom, exception: module | nil}`.
  - `error_kind` is a closed set: `:exception | :client_closed | :storage_error | :transaction_failed`
    (the planner may narrow it to what the code can actually produce).
  - No `reason` string: Postgrex messages can echo constraint DETAIL values, and filter
    `ArgumentError`s interpolate filter values.
- **D-07:** The failure contracts don't change.
  - Eager functions `try/rescue`, emit `:failed`, then `reraise e, __STACKTRACE__`.
  - The orchestrator emits `:failed` on every `mark_failed` branch and still returns `{:error, _}`
    (the message stays in `export_jobs.error_message`).
  - The clock starts before filter validation, so a bad-filter raise is a `:failed` event.
  - A chunked download whose client disconnects (`{:error, :closed}`) is `:failed` with
    `error_kind: :client_closed`.
  - Export does not use `:telemetry.span/3`: its `:exception` metadata would carry the message and
    stacktrace (Pitfall 9).

### Retention events (TELE-02)
- **D-08:** The `[:threadline, :retention, :purge, :start | :stop | :exception]` span starts only
  after `purge/1`'s input checks (`:repo` fetch, `Policy.resolve!`, the `{:error, :disabled}` return,
  `resolve_cutoff/2`). It wraps only the `dry_run_result`/`run_with_tracking` branch, following
  Oban's convention that a job span opens only when work actually runs.
  - A disabled or misconfigured call emits nothing, and the guide says so.
  - `:exception` therefore means a runtime database failure.
  - The `purge/1` return contract is unchanged.
- **D-09:** Span shape:
  - Start and stop metadata are `%{dry_run: boolean}` only. `:telemetry` does not merge start
    metadata into stop, so it is passed again at `:stop`.
  - The span function returns
    `{result, Map.take(result, [:deleted_changes, :deleted_transactions, :batches_run]), %{dry_run: dry_run?}}`,
    so counts are measurements (for `sum()`/`counter()`) next to the automatic `duration`.
  - Cutoff, policy, repo and prefix are not included: they are high-cardinality or already known
    to the caller, and keys can be added later but not removed.
- **D-10:** One `[:threadline, :retention, :batch_purged]` per `purge_loop` step, emitted after that
  step's change `delete_all` and its full orphan drain have returned. Purge has no wrapping
  transaction, so the statements have already committed.
  - Measurements: `%{deleted_changes, deleted_transactions, duration: native}`; metadata `%{}`.
  - It fires for every step, including the final empty one, so the event count equals `batches_run`.
  - A dry run emits zero batch events.
  - The guide notes that if the caller wraps `purge/1` in its own transaction, batch events fire
    before that outer commit. For deleted-row totals it points to `batch_purged`, because the
    stop counts of a dry run are preview counts.
- **D-11:** The exception-path test calls `purge(repo: Repo, storage_schema: "<missing schema>")`
  with retention enabled. It uses the real database: no mocks, no global state, safe under
  async:false with no sandbox. It asserts `:start` then `:exception` (`kind: :error`), no `:stop`,
  and the re-raise. On `:exception` only, the span's built-in `kind/reason/stacktrace` metadata is
  a documented exemption in the allowlist, and the guide warns not to forward `reason` or
  `stacktrace` to metrics.

### Contract tests (TELE-03, SC3/SC4)
- **D-12:** Three tests guard the registry, following the repo's `*_contract_test.exs` style:
  1. **Runtime allowlist:** attach to every registry event, drive a real operation for each, and
     assert the observed measurement and metadata key sets equal the registry entry. An unlisted key
     turns it red; an event that never fires is also red.
  2. **Static scan:** `:telemetry.execute`/`:telemetry.span` appear only in
     `lib/threadline/telemetry.ex`.
  3. **Doc parity:** parse the `Threadline.Telemetry` moduledoc table and the `guides/telemetry.md`
     table and compare both to `__events__/0`, so the documented list is derived from the emitted
     set and not a hand-typed literal.
- **D-13:** Raising-handler test: attach a raising handler to the export events, `batch_purged`
  and the purge `:stop`.
  - Run an export and a purge; assert the normal result shapes; assert the handler is detached
    (`:telemetry.list_handlers/1`); optionally assert `[:telemetry, :handler, :failure]` fired.
  - Use `capture_log` and async:false.
  - `:telemetry` 1.4.2 detaches a failing handler from all of its events, including across
    `attach_many`. The guide warns about this (Pitfall 6).
- **D-14:** The PROP-04 telemetry observer goes in `test/threadline/capture/redaction_leak_property_test.exs`.
  - In `setup`, `attach_many` a uniquely-id'd, non-raising handler to `__events__/0` that sends
    `{event, measurements, metadata}` to the test pid, with an `on_exit` detach.
  - Each iteration drains the mailbox before `build_surfaces` and again after it (that step already
    runs the CSV/JSON/NDJSON exports), and appends
    `{"telemetry:" <> Enum.join(event, "."), inspect(meas) <> inspect(meta)}` to LeakOracle's
    surfaces. LeakOracle already reserves `telemetry:<event>` surface names.
  - A structural assertion requires at least one export event per iteration, so a detached
    handler can't pass vacuously.
  - No extra DB work, so `PropertyRuns.db(20)` is unchanged.

### Docs (TELE-04)
- **D-15:** Tables:
  - Both tables are hand-written markdown (readable to code readers and on HexDocs) and are kept
    honest by the D-12 parity test, not generated by interpolation.
  - The moduledoc's "five events" prose becomes a single table of every event, operator-surface
    events included, and links to the guide.
- **D-16:** `guides/telemetry.md`, in this order:
  1. The event table.
  2. One `attach_many` example per family: capture, health, export, retention, operator surface.
  3. A `telemetry_metrics` example (counter/summary, `unit: {:native, :millisecond}`, `tags: [:dry_run]`).
  4. A warning that handlers must not raise (detach-all plus the failure event).
  5. A cardinality warning: never tag on ids.
  6. The redaction side-door warning: never attach row data in your own handlers.
  7. The `[:my_app, :repo, :query]` recipe, which matches
     `metadata.source in ~w(audit_changes audit_transactions audit_actions)`.

  The recipe's caveats are verified by a test, not claimed:
  - `:source` is the bare table name with no prefix;
  - it is nil for raw SQL and subquery roots;
  - trigger-side capture never appears in repo telemetry;
  - never log `:params`, which are pre-redaction plaintext.

  Registration:
  - add the guide to `mix.exs` docs `extras` and to the `groups_for_extras` "operate" group;
  - update `test/threadline/guide_graph_contract_test.exs` (`@lanes` operate list, an inbound edge
    from a non-README guide such as `guides/operator-surface.md` or `guides/production-checklist.md`,
    and the guide count 19 → 20);
  - change `guides/operator-surface.md:185` to link to the new guide.

### Existing events that break TELE-03 (HIGH-IMPACT, maintainer decision)
- **D-17:** **Strip now** (maintainer choice, 2026-10-01). — **Reversibility:** one-way — removing
  published event fields breaks adopters' handlers, and re-adding identity fields later would
  reopen the TELE-03 leak.
  - `[:threadline, :operator_surface, :authorize]`, `[..., :export_authorize]` and
    `[..., :actor_ref_mismatch]` lose `actor_ref`, `session_actor_ref` and `scope_actor_ref`
    (`result`, `count` and `path` stay; `scope_keys` stays only if it holds no identity values,
    which the planner checks).
  - `[:threadline, :health, :checked, :error]` replaces `%{error: message}` with
    `%{exception: module}`.
  - Callers are updated, e.g. `test/threadline/operator_surface/auth_test.exs:116`, and
    `operator_surface/coverage/on_mount.ex` and `coverage_live.ex` for the health error.
  - Both go under CHANGELOG `### Breaking changes` for 0.12.0 (pre-1.0 minor bump), in adopter
    language with no planning vocabulary, each with what to change. TELE-03 then holds for every
    event.
- **D-18:** The atom-valued measurements stay as they are and are documented: `status` on
  `action.recorded` and `result` on the operator-surface events. They break the
  numbers-in-measurements convention but are not TELE-03 leaks. Moving them to metadata waits for
  the v1.45 contract milestone (deferred).

### Evidence and budget
- **D-19:** VERIFICATION reports the suite wall clock before and after (ROADMAP SC5), measured
  like 227 (local full `mix test`, and the partitioned CI figure if a run is granted). No new
  `[:threadline, :query, ...]` event and no Mix-task event; the D-12 static scan plus the registry
  make that checkable.

### Claude's Discretion
- Helper names and arities; exact registry data structure; how the doc-parity test parses tables.
- Which operator-surface fixtures drive the three auth events in the runtime allowlist test.
- Whether `error_kind` needs all four atoms or a subset the code can actually reach.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 228: goal and success criteria SC1-SC5 (locked)
- `.planning/REQUIREMENTS.md`: TELE-01..04, plus the anti-features table (`[:threadline, :query, ...]` rejected)

### Research
- `.planning/research/FEATURES.md` §A (lines 19-119): event table proposal. Superseded by D-05/D-06/D-09
  on `reason`, `table`, `truncated`, and counts-in-measurements.
- `.planning/research/PITFALLS.md` Pitfalls 5-10 (lines 74-160): PII leak, handler detach,
  cardinality, emit-after-commit, span exception tagging, one-way names.

### Code
- `lib/threadline/telemetry.ex`: current five events, helper style, moduledoc
- `lib/threadline/export.ex`, `lib/threadline/export/orchestrator.ex`,
  `lib/threadline/operator_surface/controllers/export_controller.ex`: export emitters (D-04)
- `lib/threadline/retention.ex`, `lib/mix/tasks/threadline.retention.purge.ex`: retention span (D-08..D-10)
- `lib/threadline/operator_surface/auth.ex`, `theme_auth_plug.ex`, `export_auth_plug.ex`: events to strip (D-17)
- `lib/threadline/operator_surface/coverage/on_mount.ex`, `coverage_live.ex`: health error emitters (D-17)
- `deps/telemetry/src/telemetry.erl`: execute handler-failure detach (~70-120), span (~350)

### Tests and contracts
- `test/threadline/capture/redaction_leak_property_test.exs`, `test/support/leak_oracle.ex`: PROP-04 observer (D-14)
- `test/threadline/retention_test.exs`, `test/threadline/operator_surface/auth_test.exs`
- `test/threadline/guide_graph_contract_test.exs`, `test/threadline/changelog_contract_test.exs`,
  `test/threadline/public_surface_contract_test.exs`: doc and surface contracts to update
- `.planning/phases/227-db-backed-property-tests/227-CONTEXT.md`: DbProperty harness and PropertyRuns.db budget

### Project quality bar
- `prompts/threadline-elixir-oss-dna.md`: doc contract tests, named verify entrypoints
- `CLAUDE.md`: three-layer architecture, domain language

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Telemetry` helper style (`transaction_committed/2`, health emitters): extend with
  export and retention helpers.
- `LeakOracle` already reserves `telemetry:<event>` surface names (D-14).
- The `*_doc_contract_test.exs` family: the pattern for the D-12 doc-parity test.

### Established Patterns
- Naming is `[:threadline, noun, verb_past_tense]` with sibling failure events (`health.checked.error`);
  export follows it with `:completed`/`:failed`.
- Execute-only, except for one span around the unit of work that can fail partway (retention purge).
- No SQL sandbox; DataCase tests are async:false; local Postgres is shared.
- Retention purge statements autocommit (no `Repo.transaction`), so per-step emission is after commit.

### Integration Points
- `mix.exs` docs `extras` and `groups_for_extras`; README guide index; `guides/operator-surface.md:185`.
- CHANGELOG `## Unreleased`: a Breaking changes entry (D-17) and an Added entry (new events and guide).

</code_context>

<specifics>
## Specific Ideas

- Treat event names and shapes as permanent once 0.12.0 ships (Hex can't unpublish). Keep metadata
  minimal, because keys can be added later but not removed.
- The FEATURES.md `reason: String.t()` on `:failed` is rejected (D-06): it is the redaction side door.

</specifics>

<deferred>
## Deferred Ideas

- A public `Threadline.Telemetry.events/0` for attach-all DX: revisit at the v1.45 contract milestone.
- Moving atom `status`/`result` measurements into metadata: v1.45 contract (D-18).
- A `[:threadline, :retention, :purge, :disabled]` event for "cron fired but disabled" alerting: additive later if asked.
- `surface: :api | :operator_surface | :job` metadata on export events: additive later.
- Stream-primitive (`stream_export_rows`) export events: additive later if adopters ask.
- A `retention_runs` row stays at `"running"` after a mid-run exception: a pre-existing behavior, not telemetry; candidate backlog item.

</deferred>

---

*Phase: 228-telemetry*
*Context gathered: 2026-10-01*
