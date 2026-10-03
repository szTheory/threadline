# Phase 232: Consolidated Reads, Deprecations and the Bounded Default - Research

**Researched:** 2026-10-03
**Domain:** Elixir/Ecto read-API consolidation, keyset pagination, deprecation shims, telemetry
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Research for these decisions came from four advisor researchers on 2026-10-03. The two choices marked HIGH-IMPACT were made by the maintainer. The maintainer also accepted the rest of the set as recommended.

**Element type of the consolidated row history (HIGH-IMPACT: maintainer decided)**
- **D-01:** Each element of `Threadline.row_history/3` is a `%Threadline.Investigation.LinkedChange{audit_change, transaction, action}`. That is the shape `row_history/4`, `actor_window/3` and `correlation_bundle/3` already return. `timeline/2` stays the raw `AuditChange` scan, with `timeline_query/1` as its escape hatch. The `.action` hydration uses the Phase 231 internal helper (`Threadline.Query.hydrate_actions/3` / `preload_investigation_context/3`) and honors the storage-schema prefix. Rationale: every call that worked on 0.12 keeps working, including today's short-arity `row_history(schema, id, repo: R)` calls, which already return `LinkedChange`. **Reversibility:** one-way — frozen into the 1.0 contract.
- **D-02:** `history/3` is deprecated. Its delegate preserves the 0.12 return of `[%AuditChange{}]` and its unbounded default, by delegating to a hidden raw-read function rather than unwrapping hydrated results. Its spec is `[AuditChange.t()]` — a deliberate, documented exception to "spec matches the replacement's." Its parity test asserts `history(s, id, opts) == Enum.map(row_history(s, id, limit: :infinity, ...), & &1.audit_change)`.

**Bounded default and deprecated-name semantics**
- **D-03:** `row_history/3` follows the maintainer-locked rules: no options → at most 200 entries, newest first, bare list; `limit: n` or `limit: :infinity` overrides the cap; `cursor:` (+ optional `page_size:`) returns `%Threadline.Page{}`; `:limit` together with `:cursor` raises `ArgumentError`. Filter keys (`:from`, `:to`, `:repo`) fold into the same opts list; the per-function key allowlist stays as validation logic, unknown keys raise.
- **D-04:** Deprecated names keep their 0.12 behavior, including being unbounded. `history/3`, `row_history/4` and their `Query`/`Investigation` equivalents pass `limit: :infinity` unless the caller supplied a limit. `history/3`'s old `limit: nil` also maps to `:infinity`. Only the new name carries the 200 default. Callers of the new short arities (`row_history/2,3`) are now capped — the accepted cost of the locked default; telemetry and the CHANGELOG cover it. **Reversibility:** costly — pinned by parity tests and the 1.x deprecation promise.

**Unified `Threadline.Page` and cursor rules**
- **D-05:** `%Threadline.Page{entries, cursor, has_more}` replaces `Threadline.Query.TimelinePage` and `Threadline.Query.ActorHistoryPage`. Both old modules are deleted with no shim — a struct pattern match cannot be deprecated. Record the deletion under CHANGELOG `Unreleased` breaking changes. `Page` is a visible, documented module (`@doc since: "1.0.0"`). **Reversibility:** one-way — the 1.0 return contract.
- **D-06:** Cursor values stay transparent maps: `%{captured_at: DateTime, id: uuid}` for change reads, `%{occurred_at: DateTime, id: uuid}` for `actor_history`. No opaque encoded tokens (SQL-native constraint). Document microsecond precision (`utc_datetime_usec`) on the cursor type. `page.cursor` is `nil` exactly when `has_more` is `false`.
- **D-07:** `cursor: :start` begins a walk. `cursor: nil` raises `ArgumentError` on every paged read, pointing at `:start` — otherwise a loop feeding the last page's `nil` cursor back in would silently restart forever. On always-paged functions (`timeline_page/2`, `actor_history/2`), omitting `:cursor` means start. On cursor-triggered functions (`row_history/3`, `actor_window/3`, `correlation_bundle/3`), the presence of the `:cursor` key selects Page mode — detect with `Keyword.has_key?/2`, not `Keyword.get/2`.
- **D-08:** `has_more` is exact on every paged read: fetch `page_size + 1` rows, drop the extra, `has_more = fetched > page_size` — copying the proven `actor_history` technique in `Threadline.Query.Cursors`. Fixes today's `timeline_page_next_cursor/2`, where a page that is exactly full returns a cursor even though no rows remain. Required by SC1. Re-verify the walk loop in `lib/threadline/export.ex` (~line 334) and the operator timeline after the change.

**`actor_history/2` paging (HIGH-IMPACT: maintainer decided)**
- **D-09:** `actor_history/2` stays always paged and returns `%Threadline.Page{}` (entries are `AuditTransaction`). Canonical options become `cursor:` (`:start`, a map for older records, or `{:before, map}` for newer records) and `page_size:` (default 50). Legacy `:after`/`:before`/`:limit` keep working; each emits one runtime deprecation warning naming the replacement option (Phase 231 D-10 `preload: :action` precedent). Removal no earlier than 2.0. Passing both legacy and canonical cursor options raises `ArgumentError`. For a backward walk, `page.cursor` is the cursor for continuing in the direction walked. The operator UI's "newer" button builds `{:before, %{occurred_at, id}}` from the first entry — a forced call-site edit in `lib/threadline/operator_surface/live/actor_live.ex`. The `@doc` states the return type first and cross-links `actor_window/3` (API-02). **Reversibility:** one-way — the option vocabulary is frozen at 1.0.

**Option layout and the retired-name inventory**
- **D-10:** Only `row_history` moves its filters into the options list. `timeline/2`, `timeline_page/2`, `export_csv/2`, `export_json/2`, `actor_window/3` and `correlation_bundle/3` keep their `(…, filters, opts)` shape. Cursor and paging options go in `opts`.
- **D-11:** Only `timeline/2` + `timeline_page/2` remain as a paired name (SC3). The other `_page` siblings retire into the `cursor:` option on their base function:

  | Retired (all arities) | Replacement | Notes |
  |---|---|---|
  | `Threadline.history/3` | `row_history/3` | D-02, D-04 |
  | `Threadline.row_history/4` (old `schema, id, filters, opts`) | `row_history/3` | delegate merges filters into opts and preserves unbounded |
  | `Threadline.row_history_page/2,3,4` | `row_history/3` with `cursor:` | old `cursor: nil` first page maps to `:start` inside the delegate |
  | `Threadline.actor_window_page/1,2,3` | `actor_window/3` with `cursor:` | same nil→`:start` mapping |
  | `Threadline.correlation_bundle_page/1,2,3` | `correlation_bundle/3` with `cursor:` | same |
  | `Threadline.Query.history/3`, `Query.row_history/4`, `Query.row_history_page/*` | facade replacement | hidden module, own delegate |
  | `Threadline.Investigation.row_history/4`, `row_history_page/*`, `actor_window_page/*`, `correlation_bundle_page/*` | facade replacement | hidden module, own delegate |

  Each retired name is `@deprecated "Use Threadline.<fun>/<arity> instead."` plus a one-line delegate, with its own `@doc` (not `@doc false`) so ExDoc shows the badge. Each gets a spec matching what it returns and a parity test against its replacement. Replacements carry `@doc since: "1.0.0"`. Deprecated delegates in the hidden `Query`/`Investigation` modules still warn: `@moduledoc false` does not suppress `@deprecated` (verified experimentally). **Reversibility:** costly — kept through 1.x per the locked deprecation policy.
- **D-12:** Arity collision is a hard constraint, verified experimentally. `@deprecated` on a function defined with `\\` defaults applies to every arity those defaults generate. The new function is `def row_history(schema, id, opts \\ [])`, owning `/2` and `/3`. The deprecated old shape is a separate clause at literal arity 4 with no defaults. Retired names whose every arity retires (`*_page`) may keep their defaults — warning on every arity is desired there. Planner: add a test or compile-warning check proving `row_history/2,3` do NOT warn.
- **D-13:** Nothing in `lib/`, `test/` or the example app may call a deprecated name. `mix compile --warnings-as-errors` must stay clean for all three. About 92 `history/3` call sites move, plus the facade `row_history/4` and `_page` callers. Re-grep for direct `Threadline.Query.*`/`Threadline.Investigation.*` calls at the old arities. Internal code may call hidden raw-read functions directly where `LinkedChange` hydration is not wanted (e.g. `as_of_property_test.exs` needs plain `AuditChange`).

**Truncation telemetry**
- **D-14:** `[:threadline, :row_history, :truncated]` fires only when the implicit default cap truncated, never for an explicit `limit: n`. Detection is exact: the default path fetches 201 rows, fires only if the 201st existed, and returns 200. This overrides the research SUMMARY's `length(entries) == limit` suggestion — the maintainer locked only "fires when the cap is hit"; the exact rule avoids a false alarm when a row has exactly 200 changes.
- **D-15:** Event shape: measurements `%{limit: 200}`; metadata `%{schema: schema_module}` (a module atom). No table-name strings — the registry leak check (`assert_metadata_value_types!/2`) allows only atoms, booleans, integers, nil, references and lists of atoms. No primary-key values, row values or actor data. Register the event in `Threadline.Telemetry`'s `@events`, add a `drive_row_history_truncated!/0` to `drive_all!/0` in `test/threadline/telemetry_registry_contract_test.exs`, and document it in `guides/telemetry.md`'s event table.
- **D-16:** Internal readers that must opt out of the cap: `lib/threadline/operator_surface/live/row_history_component.ex` passes `limit: :infinity` (preserves the drawer's current behavior, forced edit only). The baseline in `test/threadline/query/as_of_property_test.exs` uses an explicit unbounded read. `as_of`, export, `incident_bundle` and retention do not read through history, so they are unaffected. The SC2 test still proves export and `as_of` stay unbounded past 200 changes.

**Hiding internal names (API-05)**
- **D-17:** `@doc false` for: every `Threadline.Telemetry.emit_*` (eight currently carry a real `@doc`, contradicting the module's own moduledoc); `Threadline.Query.export_changes_query/1,2`. `history_query`, `row_history_query` and `as_of_query` are already hidden. `Threadline.Export.CSV` is already `moduledoc: false` through NimbleCSV. The SC5 test asserts generally that no module without a moduledoc appears in `Code.fetch_docs/1` output, not just `Export.CSV`.
- **D-18:** Extend the Phase 231 enforcement machinery rather than add new infrastructure: add to `@hidden_modules`/hidden-function pins in `test/threadline/public_surface_contract_test.exs`; widen `test/threadline/facade_only_references_contract_test.exs` with patterns for `Threadline.Telemetry.emit_*`, `Threadline.Query.export_changes_query`, and the deleted `TimelinePage`/`ActorHistoryPage` names, each with a non-vacuous fixture self-test. Grep guides, the README and the example app for every newly hidden or retired name, and rewrite each hit in the same change. The research scan found none for `emit_*`/`export_changes_query`; retired facade names do appear in guides.
- **D-19:** The `actor_history/2` and `actor_window/3` docs each state their return type first and cross-link each other, pinned by a doc-contract test (API-02). A facade-naming test asserts that `timeline/2` + `timeline_page/2` is the only paired-name pattern among non-deprecated facade functions (SC3).

### Claude's Discretion
- The internal module layout: where the hidden raw-read function and legacy helpers live, and whether `Page` construction is centralized in `Cursors`.
- The exact deprecation-warning text and the runtime-warning mechanism for D-09's legacy options (`IO.warn` vs `Logger.warning`). Stay consistent with Phase 231 D-10.
- Plan and wave split, and the order of call-site migration.
- Test file names for the new contract tests.

### Deferred Ideas (OUT OF SCOPE)
- A permanent compatibility reliance: old `row_history(schema, id, filters)` calls keep working silently because the old filter keys are valid new opts. If a future 1.x option key ever collides in meaning with a historical filter key, that becomes a silent break. Note this in the Phase 235 stability guide.
- Removing the legacy `actor_history` `:after`/`:before`/`:limit` options and all deprecated names is a 2.0 decision.
- Moving filters into the options list for `timeline`/`export_*`/`actor_window`/`correlation_bundle` was considered and not done for 1.0 (D-10).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| API-01 | One function, `Threadline.row_history/3`, keyword opts; default 200-cap bare list; `limit:`/`cursor:` overrides; `ArgumentError` on `:limit`+`:cursor`; truncation telemetry; export/`as_of` stay unbounded; v1.44 history-reading properties updated | D-01–D-08, D-14–D-16; Architecture Patterns 1–2; Pitfall 2; Code Examples; Validation Architecture SC1/SC2 rows |
| API-02 | `actor_history/2` vs `actor_window/3` each state return type first and cross-link the other, pinned by a doc-contract test | D-09, D-19; Open Question 1 |
| API-03 | Every paged read returns `%Threadline.Page{entries, cursor, has_more}`, replacing `TimelinePage`/`ActorHistoryPage`; `timeline/2`+`timeline_page/2` the only paired name | D-05–D-08, D-11, D-19; Architecture Patterns 1; Pitfall 2; Assumption A3 |
| API-05 | `Telemetry.emit_*`, raw `*_query` builders (other than `timeline_query/1`), and moduledoc-less modules absent from docs; guides/README/example app grepped and rewritten | D-17–D-18; Pitfall 4; Sources (telemetry.ex, public_surface_contract_test.exs, facade_only_references_contract_test.exs) |
| API-08 | Each retired entry point is a one-line `@deprecated` delegate with a parity test and a matching spec; replacements carry `@doc since: "1.0.0"`; `mix compile --warnings-as-errors` clean for `lib/`, `test/`, example app | D-02, D-04, D-11–D-13; Pitfall 1, Pitfall 3, Pitfall 4; Validation Architecture SC4/D-12 rows |
</phase_requirements>

## Summary

Phase 232's locked decisions (D-01..D-19) were already produced by four advisor researchers and ratified by the maintainer in `232-CONTEXT.md` on 2026-10-03. This RESEARCH.md does not re-derive those decisions — it grounds them against the actual source tree (read this session) so the planner can cite exact line numbers, confirms the bugs/precedents the decisions depend on (the `timeline_page_next_cursor/2` off-by-one, the `actor_history` limit+1 template, the `emit_*` doc-visibility count, the `row_history_component.ex` forced edit), and fills in the sections `232-CONTEXT.md` does not cover (Validation Architecture test-command mapping, Package Legitimacy — N/A, a pitfalls catalogue specific to the arity-collision and deprecation-warning mechanics).

**Primary recommendation:** Follow `232-CONTEXT.md` D-01 through D-19 verbatim. The new `Threadline.row_history/3` is a brand-new 2-arg-default function (`def row_history(schema, id, opts \\ [])`) living in `lib/threadline.ex`, delegating into `Threadline.Investigation.row_history/4` (which itself now takes the 200-cap/`:limit`/`:cursor` logic) — it does NOT reuse today's `Threadline.row_history/4` arity, which is separately retired as a 4-arity, no-defaults clause. `Threadline.Page` is a new struct replacing `Threadline.Query.TimelinePage` and `Threadline.Query.ActorHistoryPage` (deleted with no shim, since a struct pattern match cannot be deprecated). Build the exact-`has_more` fix (`limit+1` fetch, drop the extra row) once, centrally, and have every paged read (`timeline_page/2`, `row_history/3` cursor mode, `actor_window/3` cursor mode, `correlation_bundle/3` cursor mode, `actor_history/2`) go through it — `Threadline.Query.Cursors.actor_history_trim/3` already implements this pattern and is the template.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bounded/paged row history read (`row_history/3`) | API / Backend (`Threadline` facade) | Database / Storage (keyset query) | Facade owns opt validation and the 200-row default; Postgres executes the `LIMIT`/keyset predicate |
| `%Threadline.Page{}` struct + cursor shape | API / Backend | — | Pure data contract, no I/O |
| Truncation telemetry | API / Backend | — | Emitted inside the facade's read path, consumed by host observability (out of tier) |
| Deprecated-name compatibility shims | API / Backend | — | One-line delegates; no new behavior, just routing |
| Doc visibility (`@doc false`, hidden modules) | API / Backend (ExDoc generation) | — | Compile-time/doc-build concern, not runtime |
| Operator UI forced call-site edits (`actor_live.ex`, `row_history_component.ex`) | Frontend Server (LiveView) | API / Backend (new facade signature) | LiveView only needs to call the new option names; no new UI capability is added |

## Standard Stack

No new external dependencies are introduced by this phase. All work is internal Elixir/Ecto code: new facade functions, a new struct, deprecation delegates, and telemetry/doc-contract test extensions. `stream_data ~> 1.4` (test-only, already a dependency per `mix.exs:114`) continues to back the property tests this phase must update (SC1/SC2, D-04).

### Alternatives Considered
Not applicable — `232-CONTEXT.md`'s Deferred/Discretion sections already record the structural alternatives considered and rejected by the maintainer's own advisor research (e.g., plain-`AuditChange` element type for `row_history/3`, rejected under D-01; moving filters into the options list for every read function, deferred under D-10/Deferred).

## Package Legitimacy Audit

Not applicable — this phase adds no new packages to `mix.exs`. `mix deps.get --check-locked` already passes on the current lockfile, and no new `{:foo, "~> x"}` line is proposed by any plan in this phase.

## Architecture Patterns

### System Architecture Diagram

```
Adopter call
    │
    ▼
Threadline.row_history/3  (lib/threadline.ex — new facade fn, def row_history(schema, id, opts \\ []))
    │
    ├─ opt validation: Keyword.has_key?(opts, :cursor) ⟺ Page mode  [D-07]
    │                   :limit + :cursor both present → ArgumentError  [SC1]
    │
    ▼
Threadline.Investigation.row_history/4  (hidden; filters folded from opts per D-03)
    │
    ├─ bare-list mode: HistoryLimit-style cap (200 default, :limit n, :limit :infinity)
    │                   → fires [:threadline, :row_history, :truncated] when the
    │                     201st-row probe confirms truncation  [D-14/D-15]
    │
    └─ Page mode: Threadline.Query.row_history/4 fetch page_size+1 rows,
                   drop the extra, has_more = fetched > page_size  [D-08]
    │
    ▼
Threadline.Query.ActionHydration.hydrate_actions/3  (existing Phase 231 hidden helper)
    │
    ▼
%Threadline.Investigation.LinkedChange{audit_change, transaction, action}  [D-01]
    │
    ▼
bare list (default/explicit-limit) OR %Threadline.Page{entries, cursor, has_more}  [D-03, D-05]
```

Deprecated-name call paths (`history/3`, `row_history/4` old shape, `*_page/2,3,4`) run a parallel path: a one-line `@deprecated` delegate in `lib/threadline.ex` (or the hidden `Query`/`Investigation` modules) that preserves the 0.12 unbounded default by calling `limit: :infinity` explicitly (D-04), then returns the 0.12 shape (`history/3`'s delegate unwraps to plain `AuditChange`, D-02).

### Recommended Project Structure

No new top-level files are required; this phase edits existing modules in place:

```
lib/threadline.ex                        # new row_history/3, Page-returning facade fns, @deprecated delegates
lib/threadline/page.ex                    # NEW — %Threadline.Page{entries, cursor, has_more}
lib/threadline/query.ex                   # TimelinePage deleted; row_history/4 split into new-shape + deprecated clause
lib/threadline/query/cursors.ex           # has_more fix generalized/reused (D-08); keep actor_history_trim/3 as template
lib/threadline/query/history_limit.ex     # extended with 200 default + :infinity (D-03) or superseded by a row_history-specific limiter
lib/threadline/investigation.ex           # row_history/4, actor_window/3, correlation_bundle/3 gain cursor-mode + Page return
lib/threadline/export.ex                  # alias Query.TimelinePage → Threadline.Page at the stream_changes/2 call site (line ~320-345)
lib/threadline/operator_surface/live/row_history_component.ex   # Threadline.history/3 → Threadline.row_history/3, limit: :infinity (forced edit, D-16)
lib/threadline/operator_surface/live/actor_live.ex               # :after/:before → :cursor/{:before, map} (forced edit, D-09)
test/threadline/row_history_test.exs (or similar)                # new SC1 bounded-default + cursor-walk tests
test/threadline/page_test.exs                                    # Page struct shape test
test/threadline/telemetry_registry_contract_test.exs              # extended: new event + drive_row_history_truncated!/0
test/threadline/public_surface_contract_test.exs                  # extended: @hidden_modules / hidden-function pins
test/threadline/facade_only_references_contract_test.exs          # extended: patterns for emit_*, export_changes_query, deleted Page names
```

### Pattern 1: Exact `has_more` via limit+1 (D-08)
**What:** Fetch `page_size + 1` rows ordered by the keyset tuple; if the (page_size+1)-th row exists, drop it and set `has_more: true`; otherwise `has_more: false`.
**When to use:** Every paged read in this phase (`timeline_page/2`, `row_history/3` cursor mode, `actor_window/3`/`correlation_bundle/3` cursor mode).
**Why it matters:** `Threadline.Query.Cursors.timeline_page_next_cursor/2` currently has the opposite, buggy rule — `[VERIFIED: lib/threadline/query/cursors.ex:173-178]`:
```elixir
def timeline_page_next_cursor(entries, page_size) when length(entries) < page_size, do: nil

def timeline_page_next_cursor(entries, _page_size) do
  last = List.last(entries)
  %{captured_at: last.captured_at, id: last.id}
end
```
This returns a (non-nil) cursor whenever `length(entries) == page_size`, even when no further rows exist — a page that lands exactly on a page boundary gets a dangling cursor. D-08 explicitly calls this out as the bug SC1's "exact multiple of page_size" test case exercises.
**Example (already-correct template, reuse its shape):** `[VERIFIED: lib/threadline/query/cursors.ex:74-107]`
```elixir
def actor_history_trim(entries, limit, reverse?) do
  has_more? = length(entries) > limit
  {trim_actor_history(entries, limit, has_more?, reverse?), has_more?}
end
```
and the fetch site that feeds it, `[VERIFIED: lib/threadline/query.ex:542-545]`:
```elixir
entries_raw =
  query
  |> limit(^(limit + 1))
  |> repo.all(storage_opts([], opts))
```

### Pattern 2: `Keyword.has_key?/2` to select Page mode, never `Keyword.get/2` (D-07)
**What:** On cursor-triggered functions (`row_history/3`, `actor_window/3`, `correlation_bundle/3`), the *presence* of the `:cursor` key — not its value — switches to Page mode.
**When to use:** Any options-parsing code that must distinguish "caller omitted `:cursor`" from "caller passed `cursor: nil`" (D-07: the latter must raise `ArgumentError`, not restart a walk silently).
**Why:** `Keyword.get(opts, :cursor)` returns `nil` both when the key is absent and when it's explicitly `nil` — collapsing the two cases a cursor-walk loop needs to distinguish between "start a walk" (`:start`) and "feed a page's own terminal `nil` cursor back in" (must raise).

### Pattern 3: `defdelegate`-preserving module split (precedent from 231-03)
**What:** When a hidden-module function needs new internal structure, split it into a sibling `@moduledoc false` submodule but keep the original name/arity reachable via `defdelegate`, so no call site or literal-source test assertion needs to change.
**When to use:** If `lib/threadline/query.ex` (currently 799 lines, `[VERIFIED: wc -l lib/threadline/query.ex]`) grows past the 800-line source-size contract limit again during this phase's `row_history`/Page work — which is likely, given this phase adds a new struct, a new limiter, and multiple deprecated delegates to the same file family. 231-03 hit exactly this regression and fixed it this way; plan for it proactively rather than discovering it at the phase gate (`[CITED: 231-03-SUMMARY.md Rule 1 blocking fix]`).
```elixir
# lib/threadline/query/action_hydration.ex (hidden submodule)
defmodule Threadline.Query.ActionHydration do
  @moduledoc false
  def hydrate_actions(items, repo, opts \\ []), do: ...
end

# lib/threadline/query.ex (keeps the name/arity call sites already use)
@doc false
defdelegate hydrate_actions(items, repo, opts \\ []), to: ActionHydration
```

### Anti-Patterns to Avoid
- **Reusing today's `row_history/4` arity for the new `row_history/3`:** D-12 is explicit — `@deprecated` on a function with `\\` defaults applies to *every* arity those defaults generate. The new `def row_history(schema, id, opts \\ [])` must be a clean, non-deprecated definition owning `/2` and `/3`; the retired 4-arity old-shape call is a **separate clause at literal arity 4 with no defaults**, so only it carries `@deprecated` and only it warns.
- **Detecting truncation by `length(entries) == limit`:** D-14 explicitly overrides the SUMMARY research's `length(entries) == limit` suggestion — it produces a false truncation alarm when a row has *exactly* 200 changes and nothing was actually dropped. Fetch 201, fire only if the 201st row existed, return 200 — the same limit+1 probe as Pattern 1, applied to detection rather than page-boundary cursors.
- **Letting the deprecated `history/3` delegate unwrap `LinkedChange`:** D-02 requires the delegate to preserve the 0.12 `[%AuditChange{}]` shape by delegating to a hidden *raw-read* function, not by calling the new `row_history/3` and mapping `.audit_change` off each result (that would still work functionally, but the parity test in D-02 specifically asserts `history(s, id, opts) == Enum.map(row_history(s, id, limit: :infinity, ...), & &1.audit_change)` — i.e. the delegate's *implementation* is allowed to differ from that equivalence as long as the test proves it, but a planner choosing to implement the delegate via unwrapping risks pulling in the full hydration cost for a shape that never needed it).
- **Forgetting the `@doc false` on deprecated delegates:** Each retired name needs its own `@doc` (not `@doc false`) so ExDoc shows the deprecation badge (D-11) — `@moduledoc false` on `Query`/`Investigation` does not suppress a function-level `@deprecated`+`@doc`, confirmed by the researcher per D-11's own note.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exact `has_more` on a keyset page | A custom "peek ahead" query or a second COUNT query | The `limit(^(limit + 1))` fetch-and-drop pattern already proven in `Threadline.Query.Cursors.actor_history_trim/3` (`[VERIFIED: lib/threadline/query/cursors.ex:74-107]`) | A second COUNT query doubles round-trips and can race with concurrent writes between the two queries; the limit+1 fetch is atomic and cheap |
| Truncation detection | Comparing `length(result) == configured_limit` | The same limit+1 probe, applied to the uncapped fetch (fetch 201, return 200, fire if the 201st existed) | D-14 — the naive equality check false-positives when the true row count exactly equals the cap |
| Options validation for `row_history/3` | NimbleOptions | Hand-rolled per-function key allowlist + `ArgumentError`, matching every other Threadline read function | Project constraint: "Options are flat and per-function, and the hand-rolled validators give more specific errors" (`REQUIREMENTS.md` Out of Scope table); NimbleOptions would add a dependency for no benefit here |
| Cursor encoding | An opaque base64/Phoenix.Token-encoded cursor | Transparent maps (`%{captured_at: DateTime, id: uuid}`) | D-06 — follows the project's SQL-native constraint (`CLAUDE.md` Key Design Constraints); an opaque token would hide the exact row the operator is paging from, breaking "operators query audit data with plain SQL" |

**Key insight:** Every "don't hand-roll" item in this phase has an existing, already-shipped implementation one module away (`Cursors`, `Export.split_truncated/2`, `HistoryLimit`). The work here is almost entirely *generalizing and relocating* proven logic behind a new public entry point, not inventing new algorithms — so the biggest planning risk is under-reusing (re-deriving the limit+1 pattern from scratch) rather than over-engineering.

## Runtime State Inventory

Not applicable — Phase 232 is a pure code/API-contract change (facade consolidation, deprecation shims, struct rename). It is not a rename/refactor/migration phase in the sense this section targets (no renamed identifiers propagate into stored data, live service config, OS-registered state, secrets, or build artifacts). The one struct deletion (`TimelinePage`/`ActorHistoryPage` → `Threadline.Page`) is a Elixir-source-level type change with no runtime/stored-data analog — Ecto schemas (`AuditChange`, `AuditTransaction`) and their columns are untouched (confirmed: D-05 "the DB foreign key and the `.action` key shape that callers see are unchanged" is Phase 231's API-07, already Complete, and this phase's own decisions never touch migrations or trigger SQL).

## Common Pitfalls

### Pitfall 1: Arity collision silently over-deprecating `row_history/2,3`
**What goes wrong:** If the new `row_history/3` and the retired `row_history/4` old-shape delegate are defined as clauses of the *same* function head with `\\` defaults, `@deprecated` tags every arity those defaults generate — so `row_history/2` and `/3` (the new, non-deprecated calls) would also emit the compiler warning.
**Why it happens:** Elixir's `@deprecated` attribute attaches to the function *name+arity set* generated by a single `def ... \\ ...` clause, not to one specific call pattern.
**How to avoid:** Define `row_history/3` as `def row_history(schema, id, opts \\ [])` (owns `/2` and `/3`, no `@deprecated`) and the old 4-arity shape as a *separate* function clause at literal arity 4 with no defaults, carrying its own `@deprecated`. D-12 names this as "a hard constraint, verified experimentally."
**Warning signs:** `mix compile --warnings-as-errors` fails on the new `/2`/`/3` call sites, naming them deprecated when they shouldn't be. The planner should add a test (or a compile-warning capture check, per D-12) proving `row_history/2,3` do NOT warn — this is a mutation control, not just a happy-path test.

### Pitfall 2: A page that lands exactly on a page boundary returns a phantom cursor
**What goes wrong:** Walking `cursor: :start` + `page_size:` until `has_more: false` never terminates correctly (or returns one page too many / loops) when the total row count is an exact multiple of `page_size`.
**Why it happens:** `timeline_page_next_cursor/2`'s existing `length(entries) < page_size` test (`[VERIFIED: lib/threadline/query/cursors.ex:173-178]`) treats "fetched exactly page_size rows" the same as "more rows exist," because it never fetches the lookahead row needed to tell the two cases apart.
**How to avoid:** Apply the limit+1 pattern (Pattern 1) everywhere a page is produced, not just in `actor_history`.
**Warning signs:** SC1's own spec names this exact case ("Include a case where the total is an exact multiple of `page_size`; this is the case D-08 fixes") — treat it as a required test, not an edge case to skip.

### Pitfall 3: Forgetting the forced internal-caller edits, breaking `mix compile --warnings-as-errors`
**What goes wrong:** `lib/threadline/operator_surface/live/row_history_component.ex:34` calls `Threadline.history(schema_module, assigns.record_id, opts)` today with no `:limit` in `opts` — `[VERIFIED: lib/threadline/operator_surface/live/row_history_component.ex:27-34]` (`opts = [repo: ..., scope: ..., scope_query_fn: ...]`, no `:limit` key). Once `history/3` is deprecated, this call site must move to `Threadline.row_history/3` with an *explicit* `limit: :infinity` — not just a mechanical rename — because the component's drawer UI currently sees the row's *entire* unbounded history (today's `history/3` default is unbounded) and the new `row_history/3` default is capped at 200.
**Why it happens:** The rename looks like a pure find-and-replace, but the two functions' *defaults* differ (unbounded vs. 200-capped), so a naive rename silently truncates the drawer's history view for any row with more than 200 changes.
**How to avoid:** Treat every internal caller migration as "does this caller need `limit: :infinity`, or was it relying on the pagination path?" — not a blind rename. D-16 already enumerates the two internal callers needing `limit: :infinity` (`row_history_component.ex`, `as_of_property_test.exs`'s baseline read) and the two paged-read callers needing a cursor walk (`export.ex`'s `stream_changes/2`, which already walks via `timeline_page/2`'s `Query.TimelinePage` and needs its alias updated to `Threadline.Page`, `[VERIFIED: lib/threadline/export.ex:320-343]`).
**Warning signs:** A green compile with a silently-regressed drawer UI (fewer rows shown than before) — this needs a behavioral test, not just a compile check, since `mix compile --warnings-as-errors` cannot catch a default-value regression.

### Pitfall 4: Deprecation warnings suppressed by `@moduledoc false`
**What goes wrong:** Assuming the hidden `Query`/`Investigation` modules' `@moduledoc false` also silences their functions' `@deprecated` compiler warnings, and skipping the delegate/warning work for retired names inside those modules.
**Why it happens:** `@moduledoc false` only affects documentation generation (ExDoc), not the compiler's deprecation-warning machinery, which is driven purely by `@deprecated` on the function itself.
**How to avoid:** D-11 states this was "verified experimentally" by the Phase 232 researcher — every retired name inside `Query`/`Investigation`, even though the modules are already hidden, still needs its own `@deprecated` attribute and still warns when called. Do not skip these just because the module is already invisible in docs.
**Warning signs:** A deprecated call inside a hidden module compiles silently with no warning — that is the bug, not the expected behavior.

## Code Examples

### D-08 template: limit+1 fetch, trim, and exact has_more
```elixir
# Source: lib/threadline/query/cursors.ex:74-107 (read this session, verbatim)
def actor_history_trim(entries, limit, reverse?) do
  has_more? = length(entries) > limit
  {trim_actor_history(entries, limit, has_more?, reverse?), has_more?}
end

defp trim_actor_history(entries, _limit, true, true),
  do: entries |> Enum.reverse() |> Enum.drop(1)

defp trim_actor_history(entries, limit, true, false), do: Enum.take(entries, limit)
defp trim_actor_history(entries, _limit, false, true), do: Enum.reverse(entries)
defp trim_actor_history(entries, _limit, false, false), do: entries
```

### D-14 template: exact-cap truncation detection (precedent, not yet applied to `row_history`)
```elixir
# Source: lib/threadline/export.ex:407-413 (read this session, verbatim)
defp split_truncated(rows, max_rows) do
  if length(rows) > max_rows do
    {true, Enum.take(rows, max_rows)}
  else
    {false, rows}
  end
end
```
Apply the same shape to `row_history/3`'s bare-list default path: fetch `limit: 201` internally, `{truncated?, entries} = split_truncated(rows, 200)`, emit `[:threadline, :row_history, :truncated]` only when `truncated?`.

### The cursor-key-presence check this phase must add (D-07)
```elixir
# Not yet in the tree — illustrative shape per D-07's locked rule.
if Keyword.has_key?(opts, :cursor) do
  cursor = Keyword.fetch!(opts, :cursor)
  if is_nil(cursor) do
    raise ArgumentError, "cursor: nil is invalid — pass cursor: :start to begin a walk"
  end
  # ... Page mode ...
else
  # ... bare-list mode, apply the 200/:limit/:infinity cap ...
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `Threadline.history/3`, `Threadline.row_history/4`, `*_page/2,3,4` as separate named entry points | `Threadline.row_history/3` with keyword opts selecting bare-list/limit/cursor mode | This phase (API-01/API-08) | One function to learn; old names keep working as `@deprecated` delegates through the 1.x line (no earlier than 2.0 removal, per `REQUIREMENTS.md` deprecation policy) |
| `Threadline.Query.TimelinePage` / `Threadline.Query.ActorHistoryPage` (two struct shapes) | `Threadline.Page{entries, cursor, has_more}` (one shape, all paged reads) | This phase (API-03) | Any pattern match on the old structs breaks at compile time — this is an intentional one-way break (D-05), not a deprecation, because a struct pattern match cannot carry a shim |
| `actor_history/2`'s `:after`/`:before`/`:limit` options | `:cursor` (`:start`, a map, or `{:before, map}`) + `:page_size` | This phase (D-09) | Legacy options keep working (runtime deprecation warning per call, following the Phase 231 `preload: :action` precedent at D-10), removal no earlier than 2.0 |

**Deprecated/outdated:**
- `Threadline.history/3`, `Threadline.row_history/4` (old shape), `Threadline.row_history_page/2,3,4`, `Threadline.actor_window_page/1,2,3`, `Threadline.correlation_bundle_page/1,2,3`, and the `Query`/`Investigation` equivalents of all of these — superseded by `row_history/3`'s cursor mode and the other base functions' `cursor:` option. See D-11's full retirement table in `232-CONTEXT.md`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The new `Threadline.Page` struct should live in a new file `lib/threadline/page.ex` rather than inside `lib/threadline.ex` or `lib/threadline/query/cursors.ex` | Recommended Project Structure | Low — this is explicitly left to planner/executor discretion in `232-CONTEXT.md` ("The internal module layout... is Claude's Discretion"); any choice that keeps `Page` a visible, documented module satisfies D-05 |
| A2 | `row_history/3`'s bare-list 200-row default and `:limit`/`:cursor` dispatch logic will live in a new or extended limiter module rather than directly inline in `lib/threadline/investigation.ex` | Recommended Project Structure | Low — same discretion scope; the existing `HistoryLimit` module (`lib/threadline/query/history_limit.ex`, 16 lines, `[VERIFIED]`) is a plausible extension point but the plan is free to introduce a sibling instead |
| A3 | `export.ex`'s `stream_changes/2` (currently pattern-matching `%Query.TimelinePage{}` at `[VERIFIED: lib/threadline/export.ex:320-343]`) needs a one-line alias update to `%Threadline.Page{}` and no deeper rework | Pitfall 3 / Project Structure | Medium — if `Threadline.Page`'s field names (`entries`/`cursor`/`has_more`) differ from `TimelinePage`'s (`entries`/`next_cursor`), this call site needs more than a rename; D-06 names the cursor field `cursor` (singular, replacing `next_cursor`), so the match pattern's field name must also change, not just the module name |

**If this table is empty:** N/A — three low/medium-risk layout assumptions are listed above; `232-CONTEXT.md`'s own decisions (D-01..D-19) are themselves either maintainer-ratified or explicitly marked Claude's Discretion, so none of the substantive API/behavior decisions are flagged `[ASSUMED]` here.

## Open Questions

1. **Does `Threadline.Page`'s `cursor` field replace `next_cursor` on every paged read, including `actor_history/2`'s bidirectional (`next_cursor`/`prev_cursor`) shape?**
   - What we know: D-05 says `Threadline.Page{entries, cursor, has_more}` replaces both `TimelinePage` (single `next_cursor`) and `ActorHistoryPage` (`next_cursor` + `prev_cursor`). D-09 says `actor_history/2`'s canonical options become `cursor:` + `page_size:`, with legacy `:after`/`:before` kept working, and "for a backward walk, `page.cursor` is the cursor for continuing in the direction walked" — implying a single `cursor` field serves both directions depending on which way the caller is walking.
   - What's unclear: Whether `actor_history/2` needs a second field (e.g. still exposing the *other* direction's cursor) or whether D-09's single-`cursor`-in-the-walked-direction design fully replaces the old bidirectional two-cursor shape with no loss of capability for a caller who wants to walk both ways from one page.
   - Recommendation: The planner should read `232-CONTEXT.md` D-09's exact wording as authoritative (single `cursor`, direction-dependent) and write a test exercising both forward and backward walks through `actor_history/2` early in the phase to confirm no capability gap, rather than treating this as settled.

2. **Where does the row_history-specific 200-default limiter live relative to `HistoryLimit`?**
   - What we know: `HistoryLimit` (`lib/threadline/query/history_limit.ex`) today validates/applies `history/3`'s unbounded-by-default `:limit`. D-03 needs a different default (200, not unbounded) plus an `:infinity` sentinel for the *new* `row_history/3`.
   - What's unclear: Whether `HistoryLimit` should grow a second entry point for the new default, or whether a sibling module avoids conflating two different default policies in one module's public API.
   - Recommendation: Left to planner discretion per `232-CONTEXT.md`; either choice is low-risk as long as `history/3`'s existing unbounded-by-default behavior (needed for D-04's deprecated-name parity) is not accidentally changed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | SC1/SC2 real-DB tests (walking >200 changes) | ✓ (assumed local dev DB per project CI) | — | — |
| Elixir / OTP | compile + test | ✓ | `~> 1.15` per `mix.exs:46` `[VERIFIED: mix.exs:46]` | — |
| `stream_data` | SC1/SC2 property-test updates | ✓ | `~> 1.4`, test-only `[VERIFIED: mix.exs:114]` | — |

No missing dependencies. This phase introduces no new tooling.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + `stream_data ~> 1.4` (property tests) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/threadline/<new_row_history_test>.exs` |
| Full suite command | `mix ci.all` (per `CLAUDE.md` canonical entrypoint) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| API-01 / SC1 | `row_history/3` no-opts caps at 200, newest-first, bare list; `limit: n`/`limit: :infinity` override; cursor-walk until `has_more: false` equals `:infinity` result exactly, incl. exact-multiple-of-page_size case; `:limit`+`:cursor` raises | unit/integration (real Postgres, >200 changes) | `mix test test/threadline/row_history_test.exs` (new file name at planner's discretion) | ❌ Wave 0 |
| API-01 / SC2 | `[:threadline, :row_history, :truncated]` fires only on true cap-hit (201st-row probe), registered in `Telemetry.__events__/0`, leak check on metadata value types, export/`as_of` stay unbounded past 200 | unit | `mix test test/threadline/telemetry_registry_contract_test.exs` (extended) + `mix test test/threadline/query/as_of_property_test.exs` | partial — file exists, extension is Wave 0 |
| API-01 / SC1 (v1.44 regression) | v1.44 history-reading properties pass `limit: :infinity` or walk the cursor and stay green | unit/property | `mix test test/threadline/query/as_of_property_test.exs` (and any other v1.44 property file reading history — grep `Query.history\|row_history` across `test/**/*property_test.exs`) | ✅ existing files, edits required |
| API-02 | `actor_history/2` / `actor_window/3` docs state return type first, cross-link each other | doc-contract unit | `mix test test/threadline/<new_or_extended_doc_contract_test>.exs` | ❌ Wave 0 (new assertion) |
| API-03 / SC3 | Every paged read returns `%Threadline.Page{entries, cursor, has_more}`; `TimelinePage`/`ActorHistoryPage` no longer exist; `timeline/2`+`timeline_page/2` is the only paired-name pattern | unit (facade-naming test) | `mix test test/threadline/page_test.exs` + `mix test test/threadline/<facade_naming_test>.exs` | ❌ Wave 0 |
| API-05 | `Telemetry.emit_*`, raw `*_query` builders (other than `timeline_query/1`), moduledoc-less modules absent from `Code.fetch_docs/1`; grep of guides/README/example app for hidden names | unit | `mix test test/threadline/public_surface_contract_test.exs` (extended) + `mix test test/threadline/facade_only_references_contract_test.exs` (extended) | ✅ existing files, extension required |
| API-08 / SC4 | Each retired entry point is a one-line `@deprecated` delegate with a parity test + matching spec; replacements carry `@doc since: "1.0.0"`; `mix compile --warnings-as-errors` clean for `lib/`, `test/`, example app | unit + compile check | `mix test test/threadline/<deprecation_parity_test>.exs` + `MIX_ENV=test mix compile --warnings-as-errors --force` + `mix verify.example` | ❌ Wave 0 (parity tests) |
| D-12 (arity collision) | `row_history/2,3` do NOT warn as deprecated; the retired 4-arity shape does | compile-warning capture | `mix compile --warnings-as-errors 2>&1` captured and asserted in a test, or `mix xref` / manual grep of compiler output | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the narrowest test file touched by that task (e.g. `mix test test/threadline/row_history_test.exs`)
- **Per wave merge:** `mix test --warnings-as-errors` (full ExUnit suite) + `mix verify.example`
- **Phase gate:** `mix ci.all` green before `/gsd-verify-work`, matching the Phase 231 precedent (`mix ci.all` browser lane baseline: 318 passed / 26 skipped, `[CITED: 231-03-SUMMARY.md]`)

### Wave 0 Gaps
- [ ] `test/threadline/row_history_test.exs` (or planner-chosen name) — covers API-01/SC1 bounded default, limit overrides, cursor walk, `ArgumentError` on `:limit`+`:cursor`
- [ ] A `Page` struct test — covers API-03/SC3 shape + `has_more`/`cursor` nil-iff-no-more invariant (D-06)
- [ ] A facade-naming test — covers SC3's "only `timeline/2`+`timeline_page/2` is a paired name" assertion (D-19)
- [ ] A deprecation parity-test suite — covers API-08/SC4, one test per retired entry point in D-11's table, run against real Postgres with >200 changes per D-04/D-16's unbounded-preservation requirement
- [ ] An arity-collision compile-warning test — covers D-12's "`row_history/2,3` do NOT warn" assertion
- [ ] Extensions (not new files) to `telemetry_registry_contract_test.exs` (new event + `drive_row_history_truncated!/0`), `public_surface_contract_test.exs` (new `@hidden_modules`/hidden-function entries), `facade_only_references_contract_test.exs` (new retired-name patterns)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Out of scope — this phase does not touch auth |
| V3 Session Management | no | Out of scope |
| V4 Access Control | no | `scope_query_fn`/`:scope` pass-through is unchanged by this phase; no new access-control surface |
| V5 Input Validation | yes | Hand-rolled `ArgumentError`-raising validators (existing project pattern, D-03/D-07) — no NimbleOptions, per project constraint |
| V6 Cryptography | no | Not applicable |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Telemetry metadata leaking row/actor values | Information Disclosure | D-15 locks the new truncation event's metadata to `%{schema: schema_module}` (a module atom only) and measurements to `%{limit: 200}`; the existing registry leak check (`assert_metadata_value_types!/2`) only allows atoms, booleans, integers, nil, references, and lists of atoms — no table-name strings, no PK values, no actor data |
| Deprecated-name call-site confusion masking a real behavior change | Tampering (of expected behavior, not data) | D-16's forced-edit audit of internal callers (`row_history_component.ex`) specifically guards against a default-value regression hiding behind a green compile (see Pitfall 3) |

## Sources

### Primary (HIGH confidence)
- `lib/threadline.ex` (read this session, full file, 329 lines) — current facade shape, all existing public read functions and their docs
- `lib/threadline/query.ex` (read this session, full file, 799 lines) — `TimelinePage`, `row_history/4`, `row_history_page/4`, `history/3`, `timeline_page/2`, `actor_history/2`
- `lib/threadline/investigation.ex` (read this session, full file, 236 lines) — `row_history/4`, `actor_window/3`, `correlation_bundle/3`, `linked_changes/2`, `to_linked_changes/1`
- `lib/threadline/query/cursors.ex` (read this session, full file, 179 lines) — `actor_history_trim/3` (D-08 template), `timeline_page_next_cursor/2` (the bug D-08 fixes)
- `lib/threadline/query/history_limit.ex` (read this session, full file, 16 lines) — existing `:limit` validator/applier to extend
- `lib/threadline/telemetry.ex` (read this session, full file, 382 lines) — `@events` registry shape, `__events__/0`, the 8 `emit_*` functions carrying a real `@doc` (D-17)
- `lib/threadline/export.ex` (`split_truncated/2` at lines 407-413; `stream_changes/2` at lines ~320-343, read this session) — truncation-probe and `TimelinePage`-walk precedents
- `lib/threadline/operator_surface/live/row_history_component.ex` (read this session, lines 1-60) — confirms the current `Threadline.history/3` call with no `:limit` key, grounding D-16's forced-edit claim
- `lib/threadline/operator_surface/live/actor_live.ex` (grepped this session) — confirms `:after`/`:before`/cursor assigns usage, grounding D-09's forced-edit claim
- `test/threadline/public_surface_contract_test.exs`, `test/threadline/facade_only_references_contract_test.exs`, `test/threadline/telemetry_registry_contract_test.exs` (read/grepped this session) — existing enforcement machinery this phase extends per D-18
- `.planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-CONTEXT.md` — the phase's locked decisions (D-01..D-19), maintainer-ratified 2026-10-03
- `.planning/REQUIREMENTS.md` — API-01, API-02, API-03, API-05, API-08 definitions and the project-wide deprecation policy

### Secondary (MEDIUM confidence)
- `.planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-03-SUMMARY.md` — the `ActionHydration` split precedent and the 800-line source-size regression this phase should plan around proactively

### Tertiary (LOW confidence)
None — every substantive claim above was grounded against a session read of the actual source or the maintainer-ratified CONTEXT.md.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all patterns reuse already-shipped code read this session
- Architecture: HIGH — every structural claim (D-01..D-19) is maintainer-ratified in `232-CONTEXT.md` and cross-checked against the live source tree
- Pitfalls: HIGH — each pitfall traces to either a verified existing bug (`timeline_page_next_cursor/2`) or an experimentally-verified language mechanic cited in `232-CONTEXT.md` (D-11, D-12)

**Research date:** 2026-10-03
**Valid until:** Until the phase's own plan is written (this is a one-shot internal refactor against a fixed code snapshot, not a fast-moving external ecosystem; treat as valid for the lifetime of Phase 232's execution)

---
*Phase: 232-consolidated-reads-deprecations-and-the-bounded-default*
*Research completed: 2026-10-03*
