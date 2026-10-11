## Home task hierarchy and Timeline query/history

| Option | Pros | Cons | Complexity | Recommendation |
|---|---|---|---|---|
| Task-first Home; primary Timeline filters plus an advanced drawer; explicit Apply | Keeps lookup jobs visible; leaves the common search path prominent; separates draft filters from the committed query | The drawer adds a step for less common filters; draft changes need a clear “not applied” cue | Home, filter component, styles and tests; responsive overflow and stale-scope truth | Rec if first-time support and engineering investigation should share a familiar entry point |
| All lookup jobs and Timeline filters visible | Makes controls easy to discover; reduces disclosure and drawer interaction | More competing actions and a denser narrow-screen layout; raises overflow risk | Home and Timeline layout plus responsive tests; focus and 200% zoom | Rec if expert operators need frequent access to every filter and the layout remains readable |
| Search-first Home with filters applied as they change | Fast feedback for simple searches; fewer submit steps | Every edit may trigger queries and browser-history changes; harder to distinguish draft from committed state | Form event and URL behavior changes; query load, history and pending-state risks | Rec if searches are low-latency and operators prefer live refinement |

**Recommendation:** Keep the task-first Home and the current primary-plus-advanced filter structure. Refine labels and direct lookup descriptions, and fix the observed narrow long-filter overflow. Treat the URL as the committed, shareable query: explicit Apply should create one history entry; reload and back/forward should restore the query and rerun it. Make draft edits visibly distinct from the applied result scope. Keep cursor paging incremental and bound to that committed query; do not imply the current cursor position is restored by reload. Tenant authorization scope must remain server-owned and must never be encoded into the URL. During pending reads, results must stay associated with their applied query or be cleared until the new query completes; errors, empty results and pending results must remain distinct. This follows Phoenix LiveView’s `push_patch`/`handle_params` model and its documented async loading and failure states ([LiveView navigation and async operations](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html)).

Source and test anchors:

- Home task hierarchy and lookup forms: `live/start_live.ex:139–159, 168–189, 200–259, 267–304`; existing hierarchy and form assertions in `test/.../live/start_live_test.exs:177–210, 362`.
- Timeline URL parsing, canonicalization and safe key allowlist: `live/timeline_live.ex:83–116`; `query/filter_params.ex:16–24, 35–79, 89–97`.
- Filter controls and explicit Apply: `live/timeline_live/filters.ex:26–114, 229–285`; active filters remain summarized while advanced fields are disclosed in the drawer at `filters.ex:213–225`.
- Current cursor paging is in-memory and appends to the stream: `live/timeline_live.ex:325–346, 397–411, 448–456`. Query history restoration is covered by `test/.../live/timeline_live_test.exs:403–427, 649–719`; explicit-Apply-only and cursor rendering by `:533–569`; advanced-filter visibility by `:920–949`.
- Accepted rendered defect: Phase 238 `238-UI-REVIEW.md` “S1” and `238-BASELINE-FINDINGS.md` `state.timeline.empty-long` confirm whole-page overflow at 375 CSS px for a long correlation filter. The same baseline records a held query reaching a real pending then empty state; it does **not** establish a stale-result relabeling defect.
- Copy judgment: `start_live.ex:172–174` overstates that every change has action/context; Phase 238 UI review identifies this as source/rendered judgment, not a newly reproduced browser failure. Normalize the Coverage label drift called out at `start_live.ex:216–225`.

The Home and query work depends on the shared responsive, theme, and focus treatment: coordinate filter sizing and long-chip wrapping with the shared layout/tokens, keep drawer keyboard dismissal and focus return intact, and verify the journey in Light, Dark and System at narrow/intermediate/desktop widths and actual 200% zoom. Transaction evidence should retain the distinction among AuditTransaction, AuditChange, AuditAction, ActorRef and AuditContext; `live/transaction_live.ex:163–207` already presents transaction, actor, action, correlation and captured time separately. No major unresolved decision emerged. Paging the cursor position in browser history would be a separate behavioral expansion beyond the current requirement; the recommendation keeps the query restorable and paging incremental.

## Clarifications for downstream use

“Applied query” means the operator-selected filter set used to fetch the visible Timeline result set. It is URL-backed by the existing allowlist (`from`, `to`, `table_schema`, `table`, `actor_kind`, `actor_id`, `correlation_id`) and can include user-selected schema/table, actor, correlation and time-window scope. It is separate from the host authorization scope: Threadline receives that from host auth assigns (for example `threadline_scope` and related query functions), uses it in server-side reads, and must continue to enforce it regardless of URL params. Do not assume the user query has no scope filters in the URL; do not serialize or trust the host authorization scope as a URL filter.

The form already has explicit Apply and no `phx-change` (`filters.ex:40`; `test/.../timeline_live_test.exs:533–538`). Browser-edited field values are an implicit local draft until submit; the displayed active-filter summary is server-backed applied state. Making that distinction clearer is a copy/presentation refinement and can be done without adding persistent LiveView draft state. An explicit dirty/“not applied” indicator is optional; tracking it would add new UI state (client-side JS or a form-change event/assign) and should not be treated as an existing capability or necessary to preserve URL-backed behavior.

## Exact source and test paths

All source observations refer only to `the retained current-main worktree`.

- `lib/threadline/operator_surface/live/start_live.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `lib/threadline/operator_surface/live/timeline_live/filters.ex`
- `lib/threadline/operator_surface/live/timeline_live/helpers.ex`
- `lib/threadline/operator_surface/live/transaction_live.ex`
- `lib/threadline/query/filter_params.ex`
- `lib/threadline/operator_surface/style/03_page_home.css`
- `lib/threadline/operator_surface/style/04_controls.css`
- `lib/threadline/operator_surface/style/07_find_detail.css`
- `lib/threadline/operator_surface/style/09_responsive.css`
- `test/threadline/operator_surface/live/start_live_test.exs`
- `test/threadline/operator_surface/live/timeline_live_test.exs`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/research/SUMMARY.md`
- `.planning/UI-MILESTONE-PREFLIGHT.md`
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-HANDOFF.md`
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-BASELINE-FINDINGS.md`
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-UI-REVIEW.md`
- `prompts/audit-lib-domain-model-reference.md`
- `prompts/threadline-elixir-oss-dna.md`
- `prompts/Threadline Brand Book.txt`

## Primary documentation source

- Phoenix LiveView official reference, current v1.2.12, covering `push_patch`, `handle_params`, async state, task caveats and cancellation: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html
- Phoenix LiveView component reference for `async_result`: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html
- Phoenix official overview of LiveView lifecycle and event/form bindings: https://phoenix.hexdocs.pm/live_view.html

Context7 MCP was not exposed in this agent environment and `ctx7` CLI was not installed; current official Phoenix/LiveView documentation was used for the required primary-source verification.
