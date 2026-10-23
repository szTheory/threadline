# Phase 240: Connected investigation and recovery - Pattern Map

**Mapped:** 2026-10-10  
**Files analyzed:** 22 likely modified source and test files  
**Tracked file analogs:** 22 / 22; three new behaviors have no exact analog

Phase scope points to changes in existing LiveViews, private UI components, the delegated copy helper, motion CSS, and their current ExUnit/Playwright suites. No route, public API, schema, migration, dependency, or new client framework is implied. Confirm the final task file list against the plan before implementation; this map is intentionally limited to the likely integration points named in `240-CONTEXT.md` and `240-RESEARCH.md`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/live/row_history_live.ex` | LiveView/controller | request-response, URL state | same file; `transaction_live.ex` | exact |
| `lib/threadline/operator_surface/live/row_history_component.ex` | component | request-response, event-driven | same file; `transaction_live.ex` nested history integration | exact |
| `lib/threadline/operator_surface/live/transaction_live.ex` | LiveView/controller | request-response, event-driven | same file; `row_history_live.ex` | exact |
| `lib/threadline/operator_surface/live/timeline_live.ex` | LiveView/controller | request-response, URL state, CRUD | same file | exact |
| `lib/threadline/operator_surface/live/timeline_live/filters.ex` | component | request-response, event-driven | same file; `saved_views_group/1` | exact |
| `lib/threadline/operator_surface/live/timeline_live/helpers.ex` | utility | transform, URL construction | same file | exact |
| `lib/threadline/operator_surface/live/actor_live.ex` | LiveView/controller | request-response, pagination | same file | exact |
| `lib/threadline/query/filter_params.ex` | utility | transform, validation | same file | exact |
| `lib/threadline/governance/saved_view.ex` | model/schema | CRUD, validation | same file | exact |
| `lib/threadline/operator_surface/script.ex` | utility/client event handler | event-driven, clipboard I/O | same file | exact |
| `lib/threadline/operator_surface/ui/display.ex` | component | transform/render | same file | exact |
| `lib/threadline/operator_surface/style/08_overlays_motion.css` | style/config | render behavior | same file | exact |
| `test/threadline/operator_surface/live/row_history_live_test.exs` | test | request-response | same file | exact |
| `test/threadline/operator_surface/row_history_component_test.exs` | test | component render, scoped reads | same file | exact |
| `test/threadline/operator_surface/transaction_live_test.exs` | test | request-response | same file | exact |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | test | request-response, event-driven | same file | exact |
| `test/threadline/operator_surface/live/actor_live_test.exs` | test | request-response | same file | exact |
| `test/threadline/operator_surface/ui_test.exs` | test | component render | same file | exact |
| `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | test | end-to-end navigation | same file | exact |
| `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | test | end-to-end URL/clipboard states | same file | exact |
| `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` | test | end-to-end keyboard/focus | same file | exact |
| `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` | test | end-to-end rendered motion | same file | exact |

All analog paths above were checked with `git ls-files` in the authoritative worktree and are tracked source. The table describes the likely set, not a mandate to touch every file; prefer the smallest owner/test slices.

## Pattern Assignments

### Row history, origin, and transaction return paths

**Files:** `row_history_live.ex`, `row_history_component.ex`, `transaction_live.ex`  
**Analogs:** the three files listed above.

`RowHistoryLive.handle_params/3` is the direct-entry URL-state seam. It derives the surface root from the known row path and assigns normalized state and local destinations (tracked `row_history_live.ex:22-37`). Extend this seam to accept only a bounded origin discriminator and supported committed filter values. Reconstruct destinations below the derived surface root; never accept a caller-supplied absolute/relative return URL. Its `parse_as_of/1` is the current safe ISO-8601 parser (`row_history_live.ex:93-116`).

```elixir
parsed_uri = URI.parse(uri)
path = parsed_uri.path || ""
base_path = surface_root(path)
...
assign(socket,
  base_path: base_path,
  table: table,
  record_id: record_id,
  as_of: parse_as_of(params["as_of"]),
  history_path: row_history_path(base_path, table, record_id),
  close_path: "#{base_path}/timeline"
)
```

`RowHistoryComponent.update/2` applies host-provided `repo`, `scope`, and `scope_query_fn` to both history and snapshot reads (`row_history_component.ex:26-58`). Keep the read seam and explicit error rendering; origin state should affect navigation only, never authorization or scoped read options. **Gap:** it currently rescues `ArgumentError` only, so a direct row-history DB failure has no retryable-unavailable path. Add that bounded failure state and safe return action without swallowing arbitrary programmer errors. The `update-as-of` event validates with `DateTime.from_iso8601/1` and patches through one helper (`row_history_component.ex:78-89,183-185`). Extend that helper to retain validated origin/filter state alongside `as_of`, and use the same canonical query encoding for history links (`row_history_component.ex:132-140`).

```elixir
row_history_opts = [repo: assigns.repo, scope: assigns[:scope],
  scope_query_fn: assigns[:scope_query_fn], limit: :infinity]
...
{:noreply, push_patch(socket, to: as_of_path(socket.assigns.history_path, as_of))}
```

`TransactionLive.mount/3` calls `Threadline.incident_bundle/2` with the host scope seam and distinguishes `:not_found` from `DBConnection.ConnectionError` (`transaction_live.ex:16-49`). Preserve that parent result as authoritative: render/mount row-history children only while the transaction bundle is available. Its `handle_params/3` identifies the nested `:history` action and selected `as_of`; render passes `close_path={@base_path}` and scope assigns into the shared row-history component (`transaction_live.ex:52-90,178-193`). Row-history links are locally generated from the existing transaction path and single-key identity; slash-containing IDs are encoded as one segment (`transaction_live.ex:466-485`).

**Test pattern:** use LiveViewTest path assertions and rendered semantics in `row_history_live_test.exs:104-138,216-238`; component path/scope tests in `row_history_component_test.exs:53-115,164-200`; transaction link and parent failure/scope cases in `transaction_live_test.exs:400-476,814-910`. The direct-route test already asserts Timeline as a breadcrumb, and the component test asserts explicit close/history paths plus Escape and initial focus. Add cases for each bounded origin, invalid/unknown parameters, retained `as_of`, and unavailable-parent suppression; don't replace or collapse absent/pruned/unavailable distinctions.

### Timeline pivots, canonical query, saved searches, and URL sharing

**Files:** `timeline_live.ex`, `timeline_live/filters.ex`, `timeline_live/helpers.ex`, `actor_live.ex`, `query/filter_params.ex`, `governance/saved_view.ex`  
**Analogs:** each listed file; share URLs have no existing exact UI analog.

`TimelineLive.mount/3` gets current host scope and actor from socket assigns, and selects saved views by the current identifiable `ActorRef` (`timeline_live.ex:27-58`). `handle_params/3` restores filters from validated URL params, uses `FilterParams.parse/1`, then applies domain validation before loading results (`timeline_live.ex:84-116`). `save-view` persists `filters_raw` only after checking actor identity; `apply-view` rebuilds a canonical query and `push_patch`es it (`timeline_live.ex:229-278`). Keep this server-side ownership seam and route saved-search apply/share through the committed query; do not include current unsubmitted form edits.

```elixir
saved_views =
  if ActorRef.identifiable?(actor_ref) do
    repo.all(from(v in SavedView, where: v.actor_ref == ^actor_ref,
      order_by: [desc: v.inserted_at]), storage_opts(socket))
  else
    []
  end
```

`FilterParams` is the single allowlist and canonicalizer (`filter_params.ex:6-24,61-85`). Its canonical ordering drops unknown keys/blank values and normalizes anonymous actors. Use `canonical_query/1` for both saved searches and copyable search URLs; don't expand this generic filter allowlist to accept arbitrary `return_to`, scope, tenant, cursor, or origin URLs. The bounded row-history origin belongs in the row-history URL parser. `SavedView` requires name, actor_ref, and filters in its changeset (`saved_view.ex:18-27`); no schema change is needed for this phase.

```elixir
def canonical_query(%{} = raw) do
  raw
  |> normalize_anonymous()
  |> Enum.filter(fn {k, v} -> k in @canonical_key_order and is_binary(v) and v != "" end)
  |> Enum.sort_by(fn {k, _v} -> Enum.find_index(@canonical_key_order, &(&1 == k)) end)
  |> URI.encode_query()
end
```

`Filters.saved_views_group/1` gates the controls on `ActorRef.identifiable?(@actor_ref)` and renders apply/delete actions from `@saved_views` (`timeline_live/filters.ex:380-428`). Preserve the existing actor gate; replace the internal/user-facing “view” vocabulary consistently with “saved search.” `save-view` currently returns the unchanged socket on insert error and delete uses `delete!/2` (`timeline_live.ex:229-273`); add actionable operation feedback and keep failed operations visibly unapplied/undeleted. Put the Copy search URL control in this existing Timeline filter/action composition if it fits its information hierarchy. New URL sharing has no direct analog: build only the current applied canonical local URL with `FilterParams.canonical_query/1`; make the “receiving host recomputes results and enforces its own access and scope” explanation visible.

`Helpers.actor_path/2` and `correlation_path/2` turn known evidence into safe pivots by constructing supported local paths/params (`timeline_live/helpers.ex:22-56`). `safe_row_history_path/3` additionally requires a schema-mapped, routeable row key before exposing the link (`helpers.ex:71-83,141-149`). Keep these as link builders rather than treating a correlation as an incident or an actor as a transaction owner. `ActorLive.timeline_actor_path/2` demonstrates canonical actor filter encoding (`actor_live.ex:472-480`).

**Test pattern:** `timeline_live_test.exs:448-750` covers URL hydration, canonical `push_patch`, unknown key allowlisting, query restoration and actor normalization; `887-910` checks anonymous ownership; `1573-1594` covers actor-owned persistence; `1684-1707` verifies URL parameters cannot widen host scope; `1709-1750` covers saved-view lifecycle. Add tests that distinguish committed query from draft form values and verify copied URL query bytes/meaning without copying scope. Actor pivot/render contracts live in `actor_live_test.exs:154-192,450-492`.

### Clipboard behavior and safe display values

**Files:** `script.ex`, `ui/display.ex`, and where needed `transaction_live.ex`  
**Analogs:** `script.ex`, `display.ex`, and transaction diff value guards.

`OperatorSurface.Script` owns one document-level delegated handler and guards binding with `window.__tlCopyBound` (`script.ex:35-69`); this covers direct entry and patched elements without per-button hook rebinding. Keep clipboard invocation directly in the activation handler. Existing promise resolution calls `flash` only after a write or a successful legacy fallback, but failure currently has no actionable accessible UI and the temporary textarea is removed without restoring selection/focus. Extend this owner seam to report truthful success/failure, preserve focus and prior selection, and clean up temporary nodes in a `finally`-safe path. Never announce success from the immediate click handler.

```javascript
if (window.__tlCopyBound) return;
window.__tlCopyBound = true;
document.addEventListener("click", function (e) {
  var btn = e.target.closest("[data-tl-copy]");
  if (!btn) return;
  var text = btn.getAttribute("data-tl-copy");
  ...
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(flash, function () {
      if (fallbackCopy(text)) flash();
    });
  }
});
```

`UI.Display.ref/1` binds the exact full allowed value on its copy data attribute and hides the copy button when scripts are disabled; `UI.Display.value/1` removes a redacted token's title before rendering and only discloses authorized full values (`display.ex:154-202,219-231`). Match this component convention for any new status/control markup. Transaction diff actions use `diff_full/1` to suppress redacted, omitted, absent, and null sentinels (`transaction_live.ex:445-458`). Do not create a full-value DOM attribute or affordance for non-copyable evidence.

**Test pattern:** `ui_test.exs:704-762` asserts full-versus-truncated values and redaction canaries never reach title/details/copy attributes. Existing transaction tests `611-778` cover exact identifiers and copyable diff sentinels. Browser clipboard coverage is in `operator-route-states.spec.ts:42-82`, including fresh direct-entry and successful API completion. It currently documents that an observed permission-denied state can still succeed via legacy fallback and does **not** prove failed fallback or truthful failure feedback; add deterministic failure/fallback assertions and accessible recovery checks rather than treating that old probe as complete.

### Motion, keyboard, and focus

**Files:** `style/08_overlays_motion.css`, `operator-accessibility.spec.ts`, `operator-motion.spec.ts`  
**Analogs:** each listed file.

The stylesheet already uses shared motion tokens and compositor properties and has a documented rule to leave high-traffic Timeline paging immediate (`08_overlays_motion.css:309-319`). However, `.tl-subview__timeline > *` currently animates and staggers history rows (`326-346`), conflicting with D-09. Remove or narrowly neutralize this row reveal; do not add per-row stagger. Keep existing `.tl-copy.is-copied` signal/“Copied” styling only for confirmed success (`357-405`). Reuse overlay tokens, interruptible transform/opacity behavior, and the file's reduced-motion blanket; optional drawer motion is allowed only if current lifecycle already distinguishes pointer/touch safely. No new global modality tracking.

`operator-accessibility.spec.ts` tests row-history dialog semantics/visible focus and keyboard Escape/focus return across repeated LiveView patches (`717-763,1044-1074`). `operator-motion.spec.ts` provides computed-style assertions for row-history and reduced-motion states (`310-319,332-373`). Extend those patterns with immediate keyboard-origin drawer behavior, reduced motion, no row animation/stagger, and stable focus/recovery after copy failure. Don't claim pointer/touch origin recognition unless the browser test proves it.

## Shared Patterns

### Host authorization and scoped reads

**Sources:** `transaction_live.ex:16-49`, `row_history_component.ex:26-58`, `timeline_live.ex:27-58,598-608`, `row_history_component_test.exs:164-200`, `row_history_live_test.exs:312-342`.  
The host auth/mount seam owns current actor and scope. Every route/query carries the existing `repo`, `scope`, and `scope_query_fn`; URL query/origin values are display/navigation state only. Keep parent transaction unavailability authoritative and never issue its child history read after parent failure.

### URL state and canonicalization

**Sources:** `FilterParams.parse/1` and `canonical_query/1` (`filter_params.ex:26-85`), `TimelineLive.handle_params/3` (`timeline_live.ex:84-116`), `RowHistoryLive.handle_params/3` (`row_history_live.ex:22-37`), and `RowHistoryComponent.as_of_path/2` (`row_history_component.ex:78-89,183-185`).  
Validate with existing allowlists, reconstruct known local paths, and preserve only supported committed filters and `as_of`. Do not carry cursor pages, host scope, tenant identity, or arbitrary URLs.

### Honest evidence states and authorized values

**Sources:** `UI.Display.value/1` (`display.ex:219-231`), transaction `diff_full/1` (`transaction_live.ex:445-458`), `row_history_live_test.exs:141-200`, and `row_history_component_test.exs:117-162`.  
Render unavailable, empty, absent, pruned, never-captured, omitted, null, and redacted according to existing semantic tokens. Keep `AuditTransaction`, `AuditAction`, `ActorRef`, and `AuditContext` distinct; do not infer missing context.

### LiveView test and browser test conventions

**Sources:** the current feature test files in the classification table.  
LiveView tests use seeded repo records, `live/2`, `render_event`/`render_change`, rendered semantic assertions and `assert_patch`; scoped tests seed both visible and hidden records and assert hidden values never render. Browser tests use `@playwright/test`, route/discovery helpers, explicit LiveView connection waits, visible role/test-id assertions, and desktop/mobile projects. Extend existing suites rather than creating duplicate parallel fixture conventions.

## No Analog Found

| File/Behavior | Role | Data Flow | Reason |
|---------------|------|-----------|--------|
| Copy search URL control | component/action; request-response + clipboard I/O | No existing control copies a canonical *search definition*; existing `data-tl-copy` handles exact evidence references. Compose from the existing Timeline filter shell and `FilterParams.canonical_query/1`; state clearly that results/access are recomputed by the receiving host. |
| Explicit bounded row-history origin encoding | utility/URL state | Current direct row history closes to Timeline and transaction history closes to its parent, but there is no safe recognized-origin parameter. Add bounded parsing and local reconstruction at the row-history URL owner; do not accept arbitrary `return_to`. |
| Accessible clipboard failure/recovery feedback | component/client event state | Current implementation confirms only successful writes and provides no failure status/manual recovery behavior. Extend the existing delegated listener and private operator markup; keep manual-selectable authorized value. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/live/`, `lib/threadline/query/`, `lib/threadline/governance/`, `lib/threadline/operator_surface/ui/`, `lib/threadline/operator_surface/style/`, `test/threadline/operator_surface/`, `examples/threadline_phoenix/e2e/tests/`.  
**Tracked-source gate:** every analog named above was verified by `git ls-files`; no ignored runtime/plugin mirror paths are referenced.  
**Pattern extraction date:** 2026-10-10
