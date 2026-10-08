# Phase 232: Consolidated Reads, Deprecations and the Bounded Default - Context

**Gathered:** 2026-10-03
**Status:** Ready for planning

<domain>
## Phase Boundary

An adopter reads a row's history through one function, `Threadline.row_history/3`, with keyword opts:

- By default the read is capped at 200 rows.
- The cursor path proves the read is complete.
- Truncation is observable through telemetry.

Every paged read returns one `%Threadline.Page{}` shape. Internal helpers drop out of the docs. Any adopter still on a retired name gets a working call and exactly one compiler warning naming the replacement.

Requirements: API-01, API-02, API-03, API-05, API-08 (ROADMAP Phase 232, SC1–SC5).

Out of scope:
- Lookup return shapes for `audit_transaction/2` and `transaction_context/2`. These belong to Phase 233 (API-06).
- `@spec` coverage beyond what deprecated delegates need. This is Phase 234.
- The stability guide. This is Phase 235.

</domain>

<decisions>
## Implementation Decisions

Research for these decisions came from four advisor researchers on 2026-10-03. The two choices marked HIGH-IMPACT were made by the maintainer. The maintainer also accepted the rest of the set as recommended.

### Element type of the consolidated row history (HIGH-IMPACT: maintainer decided)
- **D-01:** Each element of `Threadline.row_history/3` is a `%Threadline.Investigation.LinkedChange{audit_change, transaction, action}`. That is the shape `row_history/4`, `actor_window/3` and `correlation_bundle/3` already return.
  - The investigation family (`row_history`, `actor_window`, `correlation_bundle`) returns "change plus who and why".
  - `timeline/2` stays the raw `AuditChange` scan, with `timeline_query/1` as its escape hatch.
  - The `.action` hydration uses the Phase 231 internal helper (`Threadline.Query.hydrate_actions/3` / `preload_investigation_context/3`) and honors the storage-schema prefix.
  - Rationale: every call that worked on 0.12 keeps working. That includes today's short-arity `row_history(schema, id, repo: R)` calls, which already return `LinkedChange`. The rejected plain-`AuditChange` option would have broken those calls at runtime with no compiler warning.
  - **Reversibility:** one-way. The element type is frozen into the 1.0 contract and could only change in 2.0.
- **D-02:** `history/3` is deprecated. Its delegate preserves the 0.12 return of `[%AuditChange{}]` and its unbounded default, by delegating to a hidden raw-read function rather than unwrapping hydrated results.
  - Its spec is `[AuditChange.t()]`. This is a deliberate, documented exception to "spec matches the replacement's", because the replacement's element type differs.
  - Its parity test asserts `history(s, id, opts) == Enum.map(row_history(s, id, limit: :infinity, ...), & &1.audit_change)` (compared on ids/structs).
  - Record this exception in the plan so a reviewer does not read it as sloppiness.

### Bounded default and deprecated-name semantics
- **D-03:** `row_history/3` follows the maintainer-locked rules:
  - With no options, it returns at most 200 entries, newest first, as a bare list.
  - `limit: n` (a positive integer) or `limit: :infinity` overrides the cap.
  - `cursor:` (with optional `page_size:`) returns `%Threadline.Page{}`.
  - `:limit` together with `:cursor` raises `ArgumentError`.
  - Filter keys (`:from`, `:to`, `:repo`) are folded into the same opts list. The per-function key allowlist stays as validation logic, and unknown keys raise.
- **D-04:** Deprecated names keep their 0.12 behavior, including being unbounded.
  - `history/3`, `row_history/4` and their `Query`/`Investigation` equivalents pass `limit: :infinity` unless the caller supplied a limit. `history/3`'s old `limit: nil` also maps to `:infinity`.
  - Only the new name carries the 200 default.
  - Callers of the new short arities (`row_history/2,3`, which on 0.12 meant `(schema, id, filters)`) are now capped. This is the accepted cost of the locked default; telemetry and the CHANGELOG cover it.
  - **Reversibility:** costly. The behavior is pinned by parity tests and the 1.x deprecation promise.

### Unified `Threadline.Page` and cursor rules
- **D-05:** `%Threadline.Page{entries, cursor, has_more}` replaces `Threadline.Query.TimelinePage` and `Threadline.Query.ActorHistoryPage`. Both old modules are deleted with no shim; a struct pattern match cannot be deprecated.
  - Record the deletion under the CHANGELOG `Unreleased` breaking changes.
  - `Page` is a visible, documented module (`@doc since: "1.0.0"`).
  - **Reversibility:** one-way. It is the 1.0 return contract.
- **D-06:** Cursor values stay transparent maps: `%{captured_at: DateTime, id: uuid}` for change reads and `%{occurred_at: DateTime, id: uuid}` for `actor_history`.
  - Do not use opaque encoded tokens. This follows the SQL-native constraint.
  - Document microsecond precision (`utc_datetime_usec`) on the cursor type.
  - `page.cursor` is `nil` exactly when `has_more` is `false`.
- **D-07:** Starting a walk:
  - `cursor: :start` begins a walk.
  - `cursor: nil` raises `ArgumentError` on every paged read, with a message pointing at `:start`. Otherwise a loop that feeds the last page's `nil` cursor back in would silently restart from the beginning forever.
  - On always-paged functions (`timeline_page/2`, `actor_history/2`), omitting `:cursor` means start.
  - On cursor-triggered functions (`row_history/3`, `actor_window/3`, `correlation_bundle/3`), the presence of the `:cursor` key selects Page mode. Detect it with `Keyword.has_key?/2`, not `Keyword.get/2`.
- **D-08:** `has_more` is exact on every paged read. Fetch `page_size + 1` rows, drop the extra row, and set `has_more = fetched > page_size`. This copies the proven `actor_history` technique in `Threadline.Query.Cursors`.
  - It fixes today's `timeline_page_next_cursor/2` behavior, where a page that is exactly full returns a cursor even though no rows remain.
  - It is required by SC1: walking until `has_more: false` must equal the `limit: :infinity` result exactly.
  - Re-verify the walk loop in `lib/threadline/export.ex` (around line 334) and the operator timeline after the change.

### `actor_history/2` paging (HIGH-IMPACT: maintainer decided)
- **D-09:** `actor_history/2` stays always paged and returns `%Threadline.Page{}` (entries are `AuditTransaction`).
  - Its canonical options become `cursor:` (`:start`, a map for older records, or `{:before, map}` for newer records) and `page_size:` (default 50).
  - The legacy options `:after`, `:before` and `:limit` keep working. Each emits one runtime deprecation warning naming the replacement option, following the Phase 231 D-10 `preload: :action` precedent. Removal is no earlier than 2.0.
  - Passing both legacy and canonical cursor options raises `ArgumentError`.
  - For a backward walk, `page.cursor` is the cursor for continuing in the direction walked.
  - The operator UI's "newer" button builds `{:before, %{occurred_at, id}}` from the first entry. This is a forced call-site edit in `lib/threadline/operator_surface/live/actor_live.ex`; the UI stays parked otherwise.
  - The `@doc` states the return type first and cross-links `actor_window/3` (API-02).
  - **Reversibility:** one-way. The option vocabulary is frozen at 1.0.

### Option layout and the retired-name inventory
- **D-10:** Only `row_history` moves its filters into the options list.
  - `timeline/2`, `timeline_page/2`, `export_csv/2`, `export_json/2`, `actor_window/3` and `correlation_bundle/3` keep their `(…, filters, opts)` shape, matching the arities the success criteria name.
  - Cursor and paging options go in `opts`.
- **D-11:** Only `timeline/2` + `timeline_page/2` remain as a paired name (SC3). The other `_page` siblings retire into the `cursor:` option on their base function:

  | Retired (all arities) | Replacement | Notes |
  |---|---|---|
  | `Threadline.history/3` | `row_history/3` | D-02, D-04 |
  | `Threadline.row_history/4` (old `schema, id, filters, opts`) | `row_history/3` | delegate merges filters into opts and preserves unbounded |
  | `Threadline.row_history_page/2,3,4` | `row_history/3` with `cursor:` | the old `cursor: nil` first page maps to `:start` inside the delegate |
  | `Threadline.actor_window_page/1,2,3` | `actor_window/3` with `cursor:` | same nil→`:start` mapping |
  | `Threadline.correlation_bundle_page/1,2,3` | `correlation_bundle/3` with `cursor:` | same |
  | `Threadline.Query.history/3`, `Query.row_history/4`, `Query.row_history_page/*` | facade replacement | hidden module, own delegate |
  | `Threadline.Investigation.row_history/4`, `row_history_page/*`, `actor_window_page/*`, `correlation_bundle_page/*` | facade replacement | hidden module, own delegate |

  - Each retired name is `@deprecated "Use Threadline.<fun>/<arity> instead."` plus a one-line delegate. It keeps its own `@doc` (not `@doc false`) so ExDoc shows the deprecation badge.
  - Each gets a spec matching what it returns and a parity test against its replacement.
  - Replacements carry `@doc since: "1.0.0"`.
  - Deprecated delegates in the hidden `Query`/`Investigation` modules still warn: `@moduledoc false` does not suppress `@deprecated` (the researcher verified this).
  - **Reversibility:** costly. These names are kept through 1.x per the locked deprecation policy.
- **D-12:** Arity collision is a hard constraint, verified experimentally. `@deprecated` on a function defined with `\\` defaults applies to every arity those defaults generate.
  - The new function is defined as `def row_history(schema, id, opts \\ [])`, which owns /2 and /3.
  - The deprecated old shape is a separate clause at literal arity 4 with no defaults.
  - Retired names whose every arity retires (`*_page`) may keep their defaults; warning on every arity is the desired behavior there.
  - Planner: add a test or compile-warning check proving that `row_history/2,3` do NOT warn.
- **D-13:** Nothing in `lib/`, `test/` or the example app may call a deprecated name. `mix compile --warnings-as-errors` must stay clean for all three.
  - About 92 `history/3` call sites move, plus the facade `row_history/4` and `_page` callers.
  - Re-grep for direct `Threadline.Query.*`/`Threadline.Investigation.*` calls at the old arities.
  - Internal code may call hidden raw-read functions directly where `LinkedChange` hydration is not wanted. Example: `as_of_property_test.exs` needs plain `AuditChange`.

### Truncation telemetry
- **D-14:** `[:threadline, :row_history, :truncated]` fires only when the implicit default cap truncated, never for an explicit `limit: n`.
  - Detection is exact. The default path fetches 201 rows, fires only if the 201st existed, and returns 200.
  - This overrides research SUMMARY's `length(entries) == limit` suggestion. The maintainer locked only "fires when the cap is hit"; the exact rule avoids a false alarm when a row has exactly 200 changes and matches export's `split_truncated` precedent and D-08.
- **D-15:** Event shape:
  - measurements are `%{limit: 200}`;
  - metadata is `%{schema: schema_module}`, a module atom.
  - No table-name strings: the registry leak check (`assert_metadata_value_types!/2`) allows only atoms, booleans, integers, nil, references and lists of atoms.
  - No primary-key values, row values or actor data.
  - Register the event in `Threadline.Telemetry`'s `@events`, add a `drive_row_history_truncated!/0` to `drive_all!/0` in `test/threadline/telemetry_registry_contract_test.exs`, and document it in `guides/telemetry.md`'s event table.
- **D-16:** Internal readers that must opt out of the cap:
  - `lib/threadline/operator_surface/live/row_history_component.ex` passes `limit: :infinity`. This preserves the drawer's current behavior and is a forced edit only.
  - The baseline in `test/threadline/query/as_of_property_test.exs` uses an explicit unbounded read.
  - `as_of`, export, `incident_bundle` and retention do not read through history, so they are unaffected.
  - The SC2 test still proves export and `as_of` stay unbounded past 200 changes.

### Hiding internal names (API-05)
- **D-17:** The following get `@doc false`:
  - every `Threadline.Telemetry.emit_*`. Eight of them currently carry a real `@doc`, contradicting the module's own moduledoc;
  - `Threadline.Query.export_changes_query/1,2`.

  `history_query`, `row_history_query` and `as_of_query` are already hidden. `Threadline.Export.CSV` is already `moduledoc: false` through NimbleCSV.

  The SC5 test asserts generally that no module without a moduledoc appears in `Code.fetch_docs/1` output, not just `Export.CSV`.
- **D-18:** Extend the Phase 231 enforcement machinery rather than add new infrastructure:
  - add to `@hidden_modules`/hidden-function pins in `test/threadline/public_surface_contract_test.exs`;
  - widen `test/threadline/facade_only_references_contract_test.exs` with patterns for `Threadline.Telemetry.emit_*`, `Threadline.Query.export_changes_query`, and the deleted `TimelinePage`/`ActorHistoryPage` names, each with a non-vacuous fixture self-test.

  Grep guides, the README and the example app for every newly hidden or retired name, and rewrite each hit in the same change. The research scan found none for `emit_*`/`export_changes_query`; retired facade names do appear in guides.
- **D-19:** The `actor_history/2` and `actor_window/3` docs each state their return type first and cross-link each other, pinned by a doc-contract test (API-02).
  - A facade-naming test asserts that `timeline/2` + `timeline_page/2` is the only paired-name pattern among non-deprecated facade functions (SC3).

### Claude's Discretion
- The internal module layout: where the hidden raw-read function and legacy helpers live, and whether `Page` construction is centralized in `Cursors`.
- The exact deprecation-warning text and the runtime-warning mechanism for D-09's legacy options (`IO.warn` vs `Logger.warning`). Stay consistent with Phase 231 D-10.
- Plan and wave split, and the order of call-site migration.
- Test file names for the new contract tests.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked decisions
- `.planning/ROADMAP.md` § "Phase 232" — goal and SC1–SC5 (the acceptance bar)
- `.planning/REQUIREMENTS.md` — API-01, API-02, API-03, API-05, API-08, the "Maintainer decisions (2026-10-02)" header and "Settled by research"
- `.planning/research/SUMMARY.md` §1 (bounded default), §4 (deprecation wording), naming/return-shape bullets (~lines 220–240). Note: D-14 overrides its `length == limit` detection rule.
- `.planning/research/FEATURES.md` §1a–1c, §3 (Page struct proposal) — background only; D-05..D-11 supersede where they differ
- `.planning/research/ARCHITECTURE.md` lines 105–140 and 225–240 — enrichment chain and current return shapes

### Prior phase
- `.planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-CONTEXT.md` — D-05..D-10 (action hydration, `preload: :action` compat-warning precedent), D-11..D-13 (facade-only reference test)

### Project rules
- `CLAUDE.md` — three-layer architecture, SQL-native constraint, verification entrypoints
- `.planning/PROJECT.md` → Constraints → "Zero human verification by default"
- `prompts/audit-lib-domain-model-reference.md` — domain vocabulary

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Query.Cursors` (`lib/threadline/query/cursors.ex`) — `actor_history_page/4` / `actor_history_trim/3` already implement limit+1 exact has_more and bidirectional cursors. This is the template for D-08.
- `Threadline.Query.HistoryLimit` (`lib/threadline/query/history_limit.ex`) — the existing `:limit` validator/applier. Extend it with `:infinity` and the 200 default.
- `Threadline.Query.preload_investigation_context/3` + `ActionHydration.hydrate_actions/3` — the Phase 231 hydration path behind `LinkedChange`.
- `Threadline.Investigation.linked_changes/2` / `to_linked_changes/1` — builds `LinkedChange`.
- `Threadline.Export.split_truncated/2` — precedent for the limit+1 truncation probe.
- `test/threadline/telemetry_registry_contract_test.exs` — registry, key-set and value-type leak checks.
- `test/threadline/public_surface_contract_test.exs`, `test/threadline/facade_only_references_contract_test.exs` — the hiding and reference guards to extend.

### Established Patterns
- Bad options raise `ArgumentError` with specific messages, and there is no NimbleOptions (e.g. `Cursors.validate_timeline_cursor!/1`, `validate_helper_filters!/3`).
- Telemetry tests run `async: false`. The suite has no SQL Sandbox by design.
- Facade functions in `lib/threadline.ex` are one-line delegates into the hidden `Query`/`Investigation` modules.

### Integration Points
- `lib/threadline.ex` — the facade, where new and deprecated functions are defined.
- `lib/threadline/query.ex` (`TimelinePage` around line 17, `row_history`/`row_history_page` around 39–75, `timeline_page` around 296, `history` around 389, `actor_history` around 526) and `lib/threadline/query/actor_history_page.ex` (deleted).
- `lib/threadline/investigation.ex` — `row_history*`, `actor_window*`, `correlation_bundle*`, `linked_page/2`.
- `lib/threadline/export.ex` around line 334 — walks `timeline_page`.
- Operator UI forced edits: `operator_surface/live/{timeline_live,actor_live,row_history_component}.ex`.
- Example app: `examples/threadline_phoenix/` (lib, priv/scripts, README) — call-site migration.
- Guides that name retired functions: `guides/domain-reference.md`, `guides/how-threadline-works.md`, `guides/incident-playbook.md`, among others (re-grep).

</code_context>

<specifics>
## Specific Ideas

- The parity tests for deprecated delegates compare against the replacement on real Postgres with more than 200 changes on one row, so that the unbounded behavior preserved by D-04 is exercised.
- SC1 test: walk `cursor: :start` + `page_size:` until `has_more: false`. The concatenated entries must equal `limit: :infinity`. Include a case where the total is an exact multiple of `page_size`; this is the case D-08 fixes.
- Mutation controls (Phase 231 D-13 style), where cheap:
  - switching the truncation probe back to `length == limit` turns the exactly-200 test red;
  - re-adding `\\` defaults to the deprecated `row_history/4` turns the no-warning-on-/3 check red.

</specifics>

<deferred>
## Deferred Ideas

- A permanent compatibility reliance: old `row_history(schema, id, filters)` calls keep working silently because the old filter keys are valid new opts. If a future 1.x option key ever collides in meaning with a historical filter key, that becomes a silent break. Note this in the Phase 235 stability guide.
- Removing the legacy `actor_history` `:after`/`:before`/`:limit` options and all deprecated names is a 2.0 decision.
- Moving filters into the options list for `timeline`/`export_*`/`actor_window`/`correlation_bundle` was considered and not done for 1.0 (D-10).

</deferred>

---

*Phase: 232-consolidated-reads-deprecations-and-the-bounded-default*
*Context gathered: 2026-10-03*
