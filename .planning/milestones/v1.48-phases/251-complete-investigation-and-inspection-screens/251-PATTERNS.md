# Phase 251: Complete investigation and inspection screens — Pattern Map

**Handoff:** Mapper was interrupted before terminal return; parent inspected the retained complete-looking memo. Treat analogs as source guidance to confirm, not independent approval or test evidence.

**Mapped:** 2026-11-12  
**Files classified:** 28 potential owners (9 runtime, 10 ExUnit, 5 browser, 4 inventory/contract)  
**Analogs found:** 25 / 28; 3 have no close analog

This map follows the accepted two-group scope: navigation/history and selected-schema inspection. These are existing files and proof owners; it proposes no new route, query/API, dependency, backend query layer, runner, or UI abstraction. The inventory IDs remain stable. Candidates named as owners may need test or locator updates without a runtime source edit.

## File Classification

| New/Modified File Candidate | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/operator_surface/live/timeline_live.ex` | controller | request-response, CRUD (saved searches) | `lib/threadline/operator_surface/live/transaction_live.ex` | role-match |
| `lib/threadline/operator_surface/live/timeline_live/helpers.ex` | utility | transform, request-response | `lib/threadline/query/filter_params.ex` | exact |
| `lib/threadline/operator_surface/live/transaction_live.ex` | controller | request-response | `lib/threadline/operator_surface/live/row_history_live.ex` | exact |
| `lib/threadline/operator_surface/live/row_history_live.ex` | controller | request-response | `lib/threadline/operator_surface/live/transaction_live.ex` | exact |
| `lib/threadline/operator_surface/live/row_history_component.ex` | component | request-response, read-only DB I/O | `lib/threadline/operator_surface/live/evidence_live.ex` | role-match |
| `lib/threadline/operator_surface/live/coverage_live.ex` | controller | request-response, selected-schema DB read | `lib/threadline/operator_surface/live/policy_redaction_live.ex` | exact |
| `lib/threadline/operator_surface/components/surface_header.ex` | component | request-response, shared status display | — | no close analog |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | controller | request-response, selected-schema DB read | `lib/threadline/operator_surface/live/coverage_live.ex` | exact |
| `lib/threadline/operator_surface/live/evidence_live.ex` | controller | request-response, subject-scoped DB read | `lib/threadline/operator_surface/live/coverage_live.ex` | role-match |
| `test/threadline/query/filter_params_test.exs` | test | transform | `test/threadline/operator_surface/live/timeline_live_test.exs` | role-match |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | test | request-response, CRUD | `test/threadline/operator_surface/transaction_live_test.exs` | role-match |
| `test/threadline/operator_surface/live/start_live_test.exs` | test | request-response | `test/threadline/operator_surface/live/actor_live_test.exs` | exact |
| `test/threadline/operator_surface/live/actor_live_test.exs` | test | request-response | `test/threadline/operator_surface/live/start_live_test.exs` | exact |
| `test/threadline/operator_surface/live/row_history_live_test.exs` | test | request-response | `test/threadline/operator_surface/transaction_live_test.exs` | exact |
| `test/threadline/operator_surface/transaction_live_test.exs` | test | request-response | `test/threadline/operator_surface/live/row_history_live_test.exs` | exact |
| `test/threadline/operator_surface/row_history_component_test.exs` | test | request-response, DB read | `test/threadline/operator_surface/live/evidence_live_test.exs` | role-match |
| `test/threadline/operator_surface/live/coverage_live_test.exs` | test | request-response, DB read | `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | exact |
| `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | test | request-response, DB read | `test/threadline/operator_surface/live/coverage_live_test.exs` | exact |
| `test/threadline/operator_surface/live/evidence_live_test.exs` | test | request-response, DB read | `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | role-match |
| `test/threadline/operator_surface/rendered_output_contract_test.exs` | test | transform/render contract | — | no close analog |
| `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | test | request-response, browser route lifecycle | `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | test | request-response, browser route lifecycle | `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` | test | request-response, browser history | `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` | test | request-response, browser schema read | `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | role-match |
| `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts` | test | request-response, browser feature state | `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | role-match |
| `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` | config | transform / stable locator inventory | `test/fixtures/operator_surface/route-inventory.json` | role-match |
| `test/fixtures/operator_surface/route-inventory.json` | config | transform / route inventory | `test/fixtures/operator_surface/source-surface-checklist.json` | role-match |
| `test/fixtures/operator_surface/source-surface-checklist.json` | config | transform / source locator inventory | — | no close analog |

The inventory and contract files are conditional on markup or source-anchor changes. Keep `proof-home-1/2`, `proof-route-timeline-4`, `proof-actor-1/2`, `proof-row-2`, `proof-drawer-1`, `job.acme-4521-investigation`, `job.operator-actor-inspection`, `route.coverage`, `job.operator-coverage-readiness`, `route.redaction`, `job.operator-redaction-inspection`, `route.evidence`, and `job.operator-evidence-review` unchanged. `filter_params.ex` remains a shared allowlist/parser contract: implement fail-closed UI handling at Timeline/saved-view boundaries, not by changing the parser's unknown-key behavior.

## Pattern Assignments

### Navigation and history: Timeline, retained context, and `as_of`

**Analogs:** `lib/threadline/operator_surface/live/timeline_live.ex`, `lib/threadline/operator_surface/live/timeline_live/helpers.ex`, `lib/threadline/operator_surface/live/transaction_live.ex`, `lib/threadline/operator_surface/live/row_history_live.ex`

Use the existing LiveView `handle_params/3` lifecycle, canonical URL helpers, `assign/3`, and `push_patch/2`. Timeline parses and validates before querying, and its invalid branch clears result state instead of broadening the read:

```elixir
filters_raw = FilterParams.filters_raw_from_params(params)
filter_query = build_canonical_query(filters_raw)

with {:ok, filters} <- FilterParams.parse(params),
     :ok <- safe_validate(filters) do
  {:noreply, load_filtered_page(socket, filters)}
else
  {:error, message} -> {:noreply, filter_error(socket, message)}
end
```
— `timeline_live.ex:117-138`

`filter_error/2` preserves the submitted query for correction while clearing cursor, counts, and streamed rows (`timeline_live.ex:142-159`). Saved-view apply must revalidate stored values at this boundary before canonicalization; the current path canonicalizes directly (`timeline_live.ex:313-330`). Do not change `FilterParams.parse/1`'s allowlist/unknown-key-dropping compatibility (`filter_params.ex:87-97`).

The retained Timeline context helper accepts only `origin=timeline`, reparses and validates, then reconstructs canonical filter context; malformed state returns `:error`:

```elixir
def timeline_filter_query(%{} = params) do
  if params["origin"] == "timeline" do
    filters_raw = FilterParams.filters_raw_from_params(params)
    preserve_empty_from? = Map.has_key?(params, "from") and params["from"] == ""
    validated_filter_query(filters_raw, preserve_empty_from?)
  else
    :error
  end
end
```
— `timeline_live/helpers.ex:130-141`; validation and empty-`from` preservation are at `:153-167`.

When the context is discarded, keep the existing safe bare-Timeline recovery and add visible loss copy at the existing route. Preserve host scope from socket assigns; never recover scope from URL params. Home and Actor remain the existing record/correlation lookups and `{kind,id}` pivots. Keep absent/anonymous actors unlinked and preserve identifiable nonhuman kinds.

`RowHistoryLive` and nested `TransactionLive` already pass route identity, return paths, and host scope into the shared history component (`row_history_live.ex:23-45,83-97`; `transaction_live.ex:77-100`). Their current malformed-time branches map nonempty invalid `as_of` to `nil` (`row_history_live.ex:102-112`; `transaction_live.ex:81-88`). Do not copy that fallback: `RowHistoryComponent.update/2` interprets `nil` as the newest captured time (or current time when empty) (`row_history_component.ex:42-61`). Add an explicit invalid-snapshot state for malformed nonempty values on both entry paths while preserving missing/blank defaults, valid offsets, deleted-record, and before-horizon results.

### Selected-schema Coverage and shared status

**Analogs:** `lib/threadline/operator_surface/live/coverage_live.ex`, `lib/threadline/operator_surface/live/policy_redaction_live.ex`, `lib/threadline/operator_surface/components/surface_header.ex`

Coverage is the closest existing pattern for schema selection plus explicit availability states. `handle_params/3` reads the route's selected schema only when the host feature is enabled (`coverage_live.ex:40-50`); its template distinguishes unavailable, stale last-good, and empty results (`:123-160`). Failed reads preserve prior rows only when the schema matches. Successful and failed snapshots must both update the page and shared header from the same selected-schema result (`:415-455`).

```elixir
case {previous_schema, previous} do
  {^schema, %Snapshot{last_checked_at: %DateTime{}} = last_good} ->
    %{last_good | error: message}
  _ ->
    %{Snapshot.empty(nil) | error: message}
end
```
— `coverage_live.ex:436-447`

`SurfaceHeader` currently says “All tables captured” whenever uncovered count is zero (`surface_header.ex:32-45`); do not use that for an empty or expected-only selected-schema result. Keep the header selected/current and scoped, or show a truthful unavailable/not-inspected state. Preserve auth-hook denial, disabled-feature, invalid-schema, first-read, same-schema stale, and changed-schema failures as distinct states.

### Redaction comparison and safe read errors

**Analog:** `lib/threadline/operator_surface/live/coverage_live.ex` for schema selection/read states; `lib/threadline/policy/redaction_presenter.ex` for status projection.

Keep the existing private LiveView and presenter boundary. `RedactionPresenter` classifies missing deployed triggers as drift, unparseable/multiple definitions as could-not-inspect, and parsed configuration as match or drift (`redaction_presenter.ex:109-188`). Keep raw trigger SQL out of the view. Follow Coverage's selected-schema error and stale patterns. Render every zero-policy section as no configured policy to compare, add the selected schema and successful inspection time/source, and use “Left out” / “Redacted” with the configured replacement. Normalize unexpected read/schema errors to safe unavailable copy before rendering; do not expose exception text or SQL.

### Evidence projection and metadata boundary

**Analogs:** `lib/threadline/operator_surface/live/evidence_live.ex` (read states and allowlisted row projection), `lib/threadline/evidence.ex` (recorded metadata ownership).

The existing page keeps latest projection/history, no-match, unavailable/retry, and scope claims separate (`evidence_live.ex:124-149,327-369`). Extend its private `build_row/1` allowlist for the constant “Recorded provenance” summary and an explicit recorded-time label; do not render arbitrary record maps. Existing source makes provenance caller-overridable:

```elixir
%{"writer" => "threadline", "entrypoint" => entrypoint}
|> Map.merge(normalize_optional_map(extra))
```
— `evidence.ex:529-560`

Recognize only the exact expected writer/subject-entrypoint pair. Any custom/unknown provenance should display presence without values. State that this is recorded, self-reported metadata, not authenticated identity. Continue suppressing provenance/detail maps, actor IDs, and canaries.

## Existing Test and Browser Patterns

- Extend existing ExUnit owners from the research list; keep DB-backed fixtures and route helpers local to each owning suite. `coverage_live_test.exs:300-389` demonstrates separate assertions for first-read unavailable, same-schema stale, and changed-schema failure. Retain those distinctions when adding empty/expected-only/header negatives.
- `policy_redaction_live_test.exs:223-306` compares rendered sections to presenter output and asserts SQL, secret, and value canaries are absent. Pair every new allowed provenance summary with hidden-map/actor/detail negative assertions in `evidence_live_test.exs` (existing scoped/no-match/read-retry structure: `:342-412,475-504`).
- Keep route-specific ExUnit coverage in `timeline_live_test.exs`, `row_history_live_test.exs`, `transaction_live_test.exs`, `row_history_component_test.exs`, `start_live_test.exs`, `actor_live_test.exs`, and `filter_params_test.exs`. Assert that UI unknown-only and malformed saved/retained queries fail closed while the shared parser still drops unknown keys. Verify malformed nonempty `as_of` on both history routes; keep blank/default and valid UTC/offset cases.
- Browser analog `operator-route-states.spec.ts:1058-1115` verifies mounted Evidence reference continuity through history, the claim boundary, and absence of unapproved detail; use the same live-route and DOM-surface approach for new provenance behavior. Use `operator-earned-flows.spec.ts` for existing whole-task/history edges, `operator-timeline-investigation-flow.spec.ts` for browser Back/Forward, `operator-coverage-readiness.spec.ts` for selected-schema/keyboard behavior, and route states/features owners for inspection states. Do not substitute Phase 250's #4521 journey for new claims.
- Update `operator-journey-inventory.json`, `route-inventory.json`, and `source-surface-checklist.json` together with changed markup/signatures/locators; retain IDs and negative controls. `rendered_output_contract_test.exs` remains the current static rendered-surface contract owner. Storybook proves static composition only.

## Shared Patterns

### Host scope and feature gates

**Sources:** `timeline_live.ex:31-35`, `row_history_live.ex:93-96`, `coverage_live.ex:47-50`, `evidence_live.ex:38-58`.

Take repo, scope, scope query callback, and feature flags from host-populated assigns. Route/query values can select supported filters or schemas, but cannot grant authorization or expand scope.

### Error and empty-state meanings

Use explicit state flags/typed outcomes already used by each page. “Unavailable” is not empty; stale rows are labeled with their last successful time; empty results describe only the selected subject/schema. Render status in text and use existing `UI.Page`, `UI.Data`, `UI.Display`, `UI.Form`, `UI.Actions` compositions.

### Evidence proof boundary

Extend named ExUnit and browser owners only for the changed source and actual route. Bind matched captures to source, served assets, scenario/fixture, clock, browser, theme, and viewport. Storybook/source assertions do not establish mounted authorization, DB results, accessibility, or visual layout. No tests or browser checks were run during pattern mapping.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/threadline/operator_surface/components/surface_header.ex` | component | shared status display | No other shared operator header component models a selected-schema summary; adapt its existing badge in place. |
| `test/threadline/operator_surface/rendered_output_contract_test.exs` | test | transform/render contract | The existing test is the owning contract; no separate parallel renderer contract was identified. |
| `test/fixtures/operator_surface/source-surface-checklist.json` | config | source locator inventory | This is the source-anchor inventory authority, not a feature configuration with a separate analog. |

## Metadata

**Analog search scope:** accepted Phase 251 source owners and their named ExUnit/browser/inventory owners only.  
**Tracked-source gate:** all named source and fixture analog paths were checked with `git ls-files`; no ignored runtime mirror is used.  
**Pattern extraction date:** 2026-11-12
