# Phase 240: Connected investigation and recovery - Research

**Researched:** 2026-10-10  
**Domain:** Phoenix LiveView investigation flows, URL state, clipboard reliability, accessible motion  
**Confidence:** HIGH for existing application patterns; MEDIUM for external browser behavior (official documentation checked)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Row history and return paths

- **D-01:** Provide an explicit, predictable return destination for row-history and as-of views. Carry only a bounded, validated origin and supported committed investigation filters on existing URLs; preserve the transaction identity when history opened from a transaction drawer, and retain the selected `as_of` value in the row-history URL. Direct entry without a valid origin remains independently usable and returns to the default Timeline. Browser Back is a convenience, not the only return control.
- **D-02:** Query parameters are untrusted display/navigation state. Accept only the existing allowlisted query fields; never place host authorization scope, tenant identity, or accumulated cursor pages in the URL. Re-evaluate host authorization and scope on every route. Do not promise restoration of cursor pages.
- **D-03:** Keep failure states distinct. A missing or unavailable transaction remains authoritative: do not run child row-history/as-of reads after its parent is known unavailable. On direct row-history read failure, render a retryable unavailable state with the safe return action; do not mislabel it empty, denied, or not found. Preserve the existing distinctions among absent, pruned, and never-captured evidence.

#### Actor/correlation pivots and saved searches

- **D-04:** Preserve the current actor and correlation pivots to Timeline using the corresponding supported filters. Keep transactions, actions, actors, and execution contexts distinct; do not imply that an actor owns a transaction or that correlation identifies an incident.
- **D-05:** Keep named saved searches actor-owned under the existing `SavedView` behavior. Save and restore the committed, canonical supported query; unapplied draft edits are not included. Use “saved search” consistently for the user-facing concept.
- **D-06:** Share a search through a clearly named copyable canonical URL rather than sharing a saved-search record. Build it from the currently applied supported query, not unsubmitted filter edits. The URL shares the supported filter definition, not a fixed result set, cursor position, host scope, or access grant; results are recomputed and authorization/scope are enforced by the receiving host. Make that distinction clear in the interface. Do not add server persistence or a public sharing API.

#### Copy reliability

- **D-07:** Keep one document-level delegated click handler for copy controls, bound once so it works with fresh direct entry and repeated LiveView patches without duplicate handling. Start clipboard writes directly from the user's action. Use the Clipboard API when available; only confirm success after its promise resolves. If the API is unavailable, the existing legacy fallback may be attempted and success reported only if it confirms. If the API rejects or fallback fails, show accessible, actionable failure feedback and leave the authorized value selectable for manual copying.
- **D-08:** Never turn redacted, absent, omitted, or otherwise non-copyable evidence into a copy affordance. Do not put unauthorized full values in DOM attributes or feedback. Preserve focus and clean up any temporary selection element.

#### Motion and interaction

- **D-09:** Keep frequent actions immediate: keyboard activation, Escape dismissal, copy, actor/correlation pivots, saved-search application, filter changes, pagination, and as-of changes. Do not animate changing evidence values or stagger investigation rows.
- **D-10:** Use only brief, interruptible, tokenized spatial motion for occasional drawer changes when the existing lifecycle can safely distinguish pointer/touch from keyboard activation. If that cannot be done without new shared modality state or replay after LiveView patches, make the transition immediate. Respect reduced-motion settings while keeping state and copy feedback clear.

### the agent's Discretion

- Choose the narrow URL representation for the recognized origin and supported committed filters; reject unknown origins and fields and never accept arbitrary return URLs.
- Choose precise accessible status wording and test hooks for copy outcomes, provided success is factual and manual selection remains available after failure.
- Select the smallest owner/test slices for the drawer and state transitions; use current tokens and existing CSS/LiveView patterns and do not create a new motion system.
- Keep any query name or control copy concise, sentence case, and aligned with the Threadline Brand Book and existing operator language.

### Deferred Ideas (OUT OF SCOPE)

- New backend history capabilities, row-history pagination, composite-key routes, cursor-page restoration, public APIs/routes, authorization changes, and shared saved-search records.
- Copying uncommitted draft filters or implying that a shared query gives the recipient the same rows or permission.
- New dependencies, client frameworks, global input-modality state, broad motion redesign, and paid judging.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UII-04 | Operators can inspect supported row history and as-of evidence through both direct entry and the transaction drawer without losing the originating investigation context. | Reuse `RowHistoryLive` direct route and `TransactionLive` patched history state; add bounded origin/filter propagation and parent-outage guard while preserving `as_of`. |
| UII-05 | Operators can follow existing actor and correlation pivots to related activity and return with the investigation context intact. | Preserve existing `FilterParams` actor/correlation query contract and add validated return context at pivot links. |
| UII-06 | Operators can save, resume and share supported searches with coherent names and accurate restoration of the supported search state. | Keep `SavedView` actor ownership, save committed `filters_raw`, canonicalize with `FilterParams`, and copy a definition-only URL. |
| UIA-06 | Operators can copy supported values on fresh direct entry and after repeated LiveView patches, with truthful clipboard failure feedback and no duplicate event handling. | Extend the guarded document-level delegated listener, factual Promise/fallback result handling, and browser tests for direct entry, patches, cleanup, and failures. |
| UIA-07 | Operators receive purposeful, interruptible motion for meaningful state changes, while frequent actions remain immediate and reduced-motion preferences are respected. | Retain tokenized drawer motion only where input modality is already safe to identify; remove row staggering; test motion and reduced-motion states. |
</phase_requirements>

## Summary

Phase 240 is an operator-surface continuity and recovery phase, not a new audit-data capability. The implementation should extend existing LiveView URL state and the current host-scope pipeline. Row-history direct entry currently derives its close action as the default Timeline, while transaction history is already a same-LiveView patch that retains the transaction route. Add only a bounded recognized origin plus canonical supported filters to the direct route, preserve `as_of` through changes, and retain the transaction URL for drawer close. Parent transaction availability must gate child history reads; a DB outage must remain an unavailable state rather than becoming empty evidence or triggering a child query. [VERIFIED: `lib/threadline/operator_surface/live/row_history_live.ex:22-37`; `lib/threadline/operator_surface/live/transaction_live.ex:41-49,52-90`; 239-REVIEW.md, WR-03]

The safest shared source of URL state is the existing `Threadline.Query.FilterParams`: it has a compile-time key allowlist and canonical ordering, and `TimelineLive` derives its committed filter state from each parsed URL. Keep saved searches in the current actor-owned `SavedView` flow and copy a canonical URL made from committed filters. For copy behavior, retain the existing single delegated listener and make success depend on confirmed completion. For motion, current evidence rows and high-frequency changes should remain immediate; only a modest drawer transition is in scope, and only if modality can be safely identified without introducing shared state. [VERIFIED: `lib/threadline/query/filter_params.ex:16-24,61-79`; `lib/threadline/operator_surface/live/timeline_live.ex:84-115,229-246`; 240-CONTEXT.md D-05–D-10]

**Primary recommendation:** Plan small vertical slices around (1) safe route-context construction and recovery gating, (2) committed actor-owned search save/apply/share, and (3) delegated copy plus restrained drawer motion; test each with existing ExUnit and Playwright lanes. Add no package and do not expand public APIs or authorization surfaces.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route origin, filter, and `as_of` state | Frontend Server (SSR / LiveView) | Browser / Client | LiveView owns parsing and patches; URL is a bounded, shareable definition. Host scope stays server-owned. |
| Transaction and row-history availability | API / Backend | Frontend Server (SSR / LiveView) | Existing context reads remain scoped; the parent transaction state must prevent child reads when unavailable. |
| Saved search persistence and actor ownership | Database / Storage | API / Backend | The current `SavedView` schema persists actor reference and filter map; server queries gate reads and writes. |
| Clipboard interaction and confirmation | Browser / Client | Frontend Server (SSR / LiveView) | Browser API operation begins directly in user gesture; server-rendered copy affordances remain the authority for what is copyable. |
| Drawer transition and reduced motion | Browser / Client | Frontend Server (SSR / LiveView) | CSS handles only presentation; LiveView route state is authoritative and must remain functional without animation. |

## Standard Stack

### Core

| Library / pattern | Version | Purpose | Why it is standard here |
|---|---:|---|---|
| Elixir / Phoenix LiveView | Phoenix LiveView 1.2.11 locked; `~> 1.0` declared | URL-backed operator pages and patched drawers | This is the existing app contract; `handle_params` runs on route changes and patches. Do not upgrade for this phase. [VERIFIED: `mix.lock:34`; `mix.exs:97-100`] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#handle_params/3] |
| `Threadline.Query.FilterParams` | in-repo | Parse, validate, and canonicalize supported filter query state | Already bounds URL keys, prevents arbitrary atom creation, and supplies one canonical encoding. [VERIFIED: `lib/threadline/query/filter_params.ex:6-24,61-79`] |
| Existing `SavedView` / Ecto | in-repo | Actor-owned named search persistence | Already has actor reference, name, and filter map; no new persistence model is needed. [VERIFIED: `lib/threadline/governance/saved_view.ex:10-26`] |
| Existing delegated copy script and CSS tokens | in-repo | Clipboard feedback and drawer motion | Extending established lifecycle avoids duplicate hooks or a new motion system. [VERIFIED: `lib/threadline/operator_surface/script.ex:37-69` copy handler; `lib/threadline/operator_surface/style/08_overlays_motion.css:316-345` overlay rules] |

### Supporting

| Library / pattern | Purpose | When to use |
|---|---|---|
| ExUnit + LiveViewTest | Verify server-side route, scope, persistence, and recovery behavior | Use for every requirement that can be asserted without a real browser. |
| Playwright (`@playwright/test`, lockfile-installed) | Verify clipboard, focus, modality, direct entry, and responsive browser behavior | Use focused browser cases for APIs, patches, and accessibility; existing CI discovers these specs. [VERIFIED: `examples/threadline_phoenix/e2e/playwright.config.ts:22-24`; `ci.yml:1075-1077`] |
| Clipboard API `writeText` | User-initiated copy with asynchronous confirmation | Use when available; report success only after its promise resolves. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText] |
| CSS `prefers-reduced-motion` | Honor system motion preference | Use existing media-query/token patterns for non-essential drawer motion. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion] |

No dependencies are required or recommended for this phase. The Phoenix/LiveView dependencies are optional in the library package, so preserve that package boundary and keep example-app-only UI code behind its existing integration. [VERIFIED: `mix.exs:97-100`]

## Project Constraints (from AGENTS.md)

- Keep capture, semantics, and exploration/operations responsibilities separate; this phase belongs to exploration/operations and must not alter trigger-backed capture or action semantics.
- Preserve host-owned PostgreSQL trigger installation and server-owned host/tenant scope. Correct-by-default, SQL-native, and composable behavior are project constraints.
- Maintain domain language: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation` remain distinct concepts.
- Do not make Threadline a SIEM, event-sourcing system, pgAudit replacement, or data warehouse.
- Use named `mix verify.*` / `mix ci.*` entrypoints in docs and CI. Keep default tests honest; do not silently exclude suites. Preserve existing GitHub Actions job IDs and path-filter/main behavior.
- Keep README, guides, and example-app documentation aligned through doc-contract tests if a doc surface changes.
- Zero human verification by default: automate checks and agent review; reserve maintainer involvement for secrets, spend, push/publish, and scope decisions.
- Before later milestone selection/closure, read `.planning/MILESTONE-GUIDE.txt` with `.planning/MILESTONE-ARC.md`; operator-UI design work is parked until 1.0.0. This phase is already approved in the roadmap/context; do not broaden its scope.

## Architecture Patterns

### Flow and ownership

```text
Browser route / click
  → LiveView parses only bounded route/filter state
  → host plug and server context re-evaluate authorization + scope
  → parent transaction availability check
      ├─ unavailable / not found → render authoritative parent state; no child history read
      └─ available → scoped row-history / as-of query → preserve evidence distinctions
  → patch route or explicit safe return link

Committed Timeline URL
  → allowlisted canonical filter definition
  ├─ actor-owned SavedView persistence → later apply through same validated URL path
  └─ canonical copyable URL → recipient re-evaluates rows and authorization under own host
```

The URL is navigation and filter state only. Never derive authorization from it or place tenant/scope data and cursor pages in it. Phoenix LiveView documents that `handle_params` receives URL parameters after mount and after live patches; validate and authorize there before using values. Same-LiveView patches preserve the current LiveView lifecycle; cross-LiveView navigation should remain an explicit navigation boundary. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#handle_params/3; https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#push_patch/2]

### Bounded row-history return context

Use one narrow origin representation chosen by the planner, such as an allowlisted origin discriminator plus only the current canonical query fields. Construct the return path from a known route under the current surface root; never accept a return URL, host, or path supplied by the query. For transaction-origin history, the existing nested transaction route already carries the transaction identity, and drawer close patches back to its parent transaction URL. For direct row history, validate the origin and filter set; if invalid or absent, expose the default Timeline destination. Keep `as_of` in the row-history route while the selected snapshot changes. [VERIFIED: `lib/threadline/operator_surface/router.ex:81-84`; `lib/threadline/operator_surface/live/row_history_live.ex:22-37`; `lib/threadline/operator_surface/live/transaction_live.ex:52-90`; `lib/threadline/operator_surface/live/row_history_component.ex:78-89`]

Do not restore accumulated cursor pages. The current filter contract is an explicit string-keyed map; source lists are quoted here so downstream work can keep URL input bounded:

> `@filter_key_atoms %{`  
> `"from" => :from,`  
> `"to" => :to,`  
> `"table_schema" => :table_schema,`  
> `"table" => :table,`  
> `"actor_kind" => :actor_kind,`  
> `"actor_id" => :actor_id,`  
> `"correlation_id" => :correlation_id`  
> `}`  
> [VERIFIED: `lib/threadline/query/filter_params.ex:16-24`]

The canonical raw-key order is also explicitly defined:

> `@canonical_key_order ~w(from to table_schema table actor_kind actor_id correlation_id)`  
> [VERIFIED: `lib/threadline/query/filter_params.ex:61-79`]

Use this existing parser/canonicalizer on every route transition. The project’s prior art recommends LiveView-owned state, URL-owned shareable filters, same-LiveView patching, and server-side authorization/scope checks. [CITED: `prompts/prior-art/phoenix-liveview-best-practices-deep-research.md`; `prompts/prior-art/phoenix-best-practices.md`]

### Parent-gated outage recovery

The transaction mount handles `DBConnection.ConnectionError` by setting the transaction to unavailable. The rendering path must keep its row-history component inside the available-parent branch, so an outage cannot cause follow-on history/as-of calls. Add a regression case to the existing transaction LiveView test module for the history route with the same DB failure injection used by the base route. For direct history load errors, produce a retryable unavailable state and safe return link; do not broaden exception handling into a false “empty” or “not found” result. Preserve distinct existing outcomes for absent rows, pruned history, and never-captured evidence. [VERIFIED: `lib/threadline/operator_surface/live/transaction_live.ex:41-49,108-158`; `lib/threadline/operator_surface/live/row_history_component.ex:55-75`; `test/threadline/operator_surface/transaction_live_test.exs:814-883`; `239-REVIEW.md`, WR-03]

### Pivots and actor-owned saved searches

Retain the existing actor/correlation Timeline filter pivots. Add only safe return context where needed; do not conflate an actor with a transaction owner or a correlation with an incident. `TimelineLive.handle_params` establishes `filters_raw` from the committed URL, and its save handler writes that assigned state. Keep this contract: an unsaved form edit must not sneak into persistence or sharing. On apply, select from the current actor’s saved-view collection, canonicalize the stored supported filters, and patch the Timeline URL so the ordinary parser and host scope run again. Anonymous actors cannot create named views. Sharing should copy a canonical local path plus supported query definition; it must make no fixed-result, scope, cursor, or grant promise. [VERIFIED: `lib/threadline/operator_surface/live/timeline_live.ex:84-115,229-246`; `lib/threadline/governance/saved_view.ex:10-26`; `test/threadline/operator_surface/live/timeline_live_test.exs` actor-owned saved-view cases; `240-CONTEXT.md` D-04–D-06]

The existing schema declares these fields:

> `schema "threadline_saved_views" do`  
> `  field(:name, :string)`  
> `  field(:actor_ref, Threadline.Semantics.ActorRef)`  
> `  field(:filters, :map)`  
> `end`  
> [VERIFIED: `lib/threadline/governance/saved_view.ex:10-16`]

### Clipboard lifecycle

Keep one document-level delegated click listener with the existing one-time guard. Bind synchronously on fresh page entry, handle controls added by LiveView patches through delegation, and do not attach a second handler after repeated patches. Start `navigator.clipboard.writeText` directly from the click activation. Promise resolution is the success boundary; rejection is not success. If the API is missing, the existing legacy fallback may be tried; only its confirmed result may produce success. On failure, show a polite/assertive accessible actionable status consistent with severity, keep the exact authorized value selectable for manual copy, preserve focus/selection, and clean temporary nodes in all paths. The API is secure-context-limited and may reject with `NotAllowedError`; do not write the value into the feedback message. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText; `240-CONTEXT.md` D-07–D-08; VERIFIED: `lib/threadline/operator_surface/script.ex:37-69`]

Redacted, absent, omitted, or diagnostic-only evidence must not render a copy control. Existing UI display primitives and transaction diff rendering already gate redacted values and full-value copy attributes; keep that server-rendered boundary. [VERIFIED: `test/threadline/operator_surface/transaction_live_test.exs:611-779`; `lib/threadline/operator_surface/live/transaction_live.ex` diff rendering; `239-SECURITY.md` T-239-05]

### Purposeful reduced motion

Keep high-frequency filter, pagination, pivot, as-of, copy, keyboard, and Escape behavior immediate. Do not animate changed evidence or stagger rows. The current overlays CSS has a subview child stagger that conflicts with D-09; remove it or constrain it away from investigation evidence. A brief drawer transition is acceptable only if an existing lifecycle can reliably distinguish pointer/touch from keyboard. If no safe signal already exists, use immediate transitions; do not create global modality state or replay transition after patches. When motion remains, use existing tokens and honor `prefers-reduced-motion`; preserve clear open/closed state and copy feedback even when animation is suppressed. [VERIFIED: `lib/threadline/operator_surface/style/08_overlays_motion.css:316-345`; `240-CONTEXT.md` D-09–D-10] [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Query parsing/canonical URLs | A second filter parser or ad-hoc `URI.encode_query` key list | `FilterParams.parse/1`, `filters_raw_from_params/1`, and `canonical_query/1` | One canonical allowlist prevents untrusted key drift and keeps saved/apply/share state consistent. |
| Authorization and tenant scope | URL flags, origin params, or saved-view fields that choose scope | Existing host-provided scope and scoped context reads on every route | Scope is a server-owned security boundary. |
| Saved-search persistence | New share records, public endpoints, or alternate table | Existing actor-owned `SavedView` behavior | Locked scope calls for actor-owned named queries and URL sharing, not shared persistence. |
| Clipboard framework | A new clipboard dependency, hook per button, or duplicate patch hooks | One document-level delegated handler and browser Clipboard API | Delegation already supports patched DOM; the Promise gives a factual completion signal. |
| Motion system | New animation dependency, global input-modality store, or broad transition framework | Existing CSS tokens/media query; immediate transition if modality is ambiguous | The allowed interaction is narrow and CSS-only. |

## Common Pitfalls

### Treating origin as an arbitrary return URL

**What goes wrong:** A crafted query can redirect operators outside the app or carry scope-like data.  
**How to avoid:** Accept only a bounded origin discriminator and existing supported filters; reconstruct a local path under the known surface root. Default invalid/direct entry to Timeline. Reauthorize at route handling. [VERIFIED: CONTEXT D-01–D-02; `FilterParams` allowlist above]

### Losing as-of or transaction identity on close

**What goes wrong:** As-of selection disappears on update, or a transaction drawer closes to Timeline and breaks the originating investigation.  
**How to avoid:** Preserve `as_of` while patching row history; use the nested transaction history route for a drawer and its transaction route as close target. Direct entry has its own safe Timeline close path. [VERIFIED: `row_history_component.ex:78-89`; `transaction_live.ex:52-90`]

### Querying history after parent outage

**What goes wrong:** WR-03: transaction reads fail, but the history branch still renders and causes a second DB read; the child only rescues `ArgumentError`, so a connection error can crash the LiveView.  
**How to avoid:** Render child history only after parent availability is established. Add the direct history route to the connection-failure regression. [VERIFIED: `239-REVIEW.md` WR-03; `transaction_live.ex:41-49`; `row_history_component.ex:55-67`]

### Saving draft rather than committed search state

**What goes wrong:** A saved or copied URL does not match the visible applied results.  
**How to avoid:** Use `filters_raw` populated from `handle_params`; do not source from transient form assigns. Apply restores through the canonical route path and actor-owned view list. [VERIFIED: `timeline_live.ex:84-115,229-246`]

### Claiming clipboard success too early

**What goes wrong:** UI says “copied” after a rejected API write, a failed fallback, or unsupported permissions.  
**How to avoid:** Report only after API resolution or confirmed fallback. Keep manual selection and announce actionable failure. Existing browser test diagnostics explicitly note that permission denial is not proof of fallback failure. [CITED: MDN `writeText` above; VERIFIED: `operator-route-states.spec.ts:44-81`]

### Replaying animation after patch or animating evidence

**What goes wrong:** Frequent investigations feel delayed, values appear to change, or keyboard opens receive an unnecessary spatial transition.  
**How to avoid:** Keep evidence and common actions immediate; use a transition only when the existing lifecycle knows a safe pointer/touch origin; verify reduced motion and patch repeat behavior. [VERIFIED: Context D-09–D-10; `operator-motion.spec.ts:160-164,284-310`]

## Code Examples

Use the existing parser and canonicalizer rather than hand-building accepted fields:

```elixir
with {:ok, filters} <- FilterParams.parse(params),
     :ok <- safe_validate(filters) do
  {:noreply, load_filtered_page(socket, filters)}
else
  {:error, message} -> {:noreply, filter_error(socket, message)}
end
```

This is the current Timeline parameter-handling pattern. [VERIFIED: `lib/threadline/operator_surface/live/timeline_live.ex:109-116`]

The existing as-of event updates the history URL through a patch, which should remain the anchor for preserving `as_of` together with validated origin state:

```elixir
{:noreply, push_patch(socket, to: as_of_path(socket.assigns.history_path, as_of))}
```

[VERIFIED: `lib/threadline/operator_surface/live/row_history_component.ex:78-89`]

For copy feedback, follow the browser contract: invoke the Clipboard API from the user click, set success only in the resolution path, and route rejection/missing API to the bounded fallback or accessible failure path. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText]

## State of the Art

| Older / unsafe approach | Recommended current approach | Impact |
|---|---|---|
| Client-stored return URL or unrestricted query passthrough | Reconstruct a local path from bounded origin + existing filters; revalidate on every route | Avoids arbitrary navigation and preserves server authority. |
| “Copied” feedback immediately on click | Resolve Clipboard API Promise before success; fallback must also confirm | Truthful status matches browser outcome. |
| One clipboard hook per element or patch | One guarded document-level delegated listener | Fresh entry and repeated LiveView patching share one lifecycle. |
| Broad or row-by-row motion | Immediate frequent interactions; optional brief tokenized drawer motion; respect reduced-motion | Keeps investigation readable and responsive. |

`Document.execCommand()` is deprecated; it remains only as the already-approved best-effort fallback, not the primary mechanism. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand]

## Assumptions Log

No unverified package or architecture assumptions are recommended. Context7 was not available in this environment; Phoenix and browser behavior were checked against official HexDocs/MDN pages. Planning resolves the delegated origin representation to the bounded marker origin=timeline plus only existing supported committed query fields; no free-form path is accepted.

## Open Questions

1. **RESOLVED — Bounded row-history origin representation.** Use origin=timeline plus only supported committed query fields, consistent with D-01/D-02. Reconstruct the local destination from this recognized marker; never accept a free-form path. The transaction drawer route already retains identity, so do not duplicate it in query state.
2. **RESOLVED — Drawer motion policy.** Immediate motion is the default. Retain brief tokenized spatial motion only if an existing stable event/markup lifecycle safely identifies pointer/touch under D-10; otherwise the drawer stays immediate. Add no shared modality state.

## Environment Availability

| Dependency | Required By | Available | Version / state | Fallback |
|---|---|---:|---|---|
| Elixir / Mix | ExUnit and verification aliases | Yes | Elixir 1.17.3 / OTP 27 | — |
| Node / npm | Example Playwright lane | Yes | Node 22.14.0 / npm 11.1.0 | — |
| Playwright install | Browser E2E | Yes | `@playwright/test` 1.60.0 present | — |
| PostgreSQL | LiveView integration tests/example app | Available, version below project floor | Local server 14.17; project requires PostgreSQL 15+ per `.planning/PROJECT.md` | Use PostgreSQL 15+ (local service or available Docker 29.5.2). |

These are availability probes only; no test suite was run during research. The current PostgreSQL 14 instance is not a valid execution target for project verification.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit / Phoenix LiveViewTest; Playwright `@playwright/test` 1.60.0 for browser behavior |
| Config file | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| Quick run command | `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs` |
| Full ExUnit command | `mix verify.test` |
| Focused browser command | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-earned-flows.spec.ts operator-accessibility.spec.ts operator-route-states.spec.ts operator-motion.spec.ts` |
| CI browser lane | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium` |

The browser runner has desktop and mobile Chromium projects; reduced motion is globally configured, with motion tests explicitly exercising no-preference and reduce. CI runs the two voting projects in the existing browser job. Preserve its stable job identity. [VERIFIED: `playwright.config.ts:22-24` and reduced-motion config; `.github/workflows/ci.yml:1075-1077`; `mix.exs:144-149,262-265`]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| UII-04 | Direct and drawer row history preserve safe origin, transaction identity, and selected as-of; unavailable transaction suppresses child reads; direct failure has retry and return action | LiveView integration + browser flow | `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/transaction_live_test.exs`; focused Playwright command above | Yes; add WR-03 history-route regression and origin/as-of assertions. |
| UII-05 | Actor/correlation pivots keep supported filters and safe return context; scope is re-evaluated | LiveView integration + browser flow | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs`; focused Playwright command above | Yes; extend existing pivot tests. |
| UII-06 | Save/apply actor-owned committed canonical filters; sharing copies applied canonical query, not draft/saved record/scope | LiveView integration + browser flow | `mix test test/threadline/operator_surface/live/timeline_live_test.exs`; focused Playwright command above | Yes; extend saved-view and query restoration cases. |
| UIA-06 | Copy works on fresh direct entry and after repeated patch; no duplicate binding; API/fallback success and failure are truthful; focus/selection preserved | Browser integration + markup unit | Focused Playwright command above; `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/transaction_live_test.exs` | Yes; extend route-state clipboard instrumentation and UI redaction assertions. Existing denial probe explicitly does not prove failed fallback. |
| UIA-07 | Frequent actions and evidence updates stay immediate; occasional safe drawer motion is interruptible; reduced motion respected | Browser accessibility/motion | Focused Playwright command above | Yes; extend `operator-motion.spec.ts` and accessibility coverage; remove/guard row staggering. |

### Sampling Rate

- **Per implementation task:** Run the smallest affected ExUnit test file(s).
- **Per wave merge:** Run `mix verify.test` and focused Playwright specs for any browser-facing slice.
- **Phase gate:** Run `mix ci.all` on PostgreSQL 15+; CI independently discovers the normal desktop/mobile browser suite through `mix verify.example_browser`. Existing CI test partitioning uses `mix verify.test_partitioned`; the local canonical default remains full `mix verify.test`. [VERIFIED: `mix.exs:144-149,233-265`; `.github/workflows/ci.yml:1075-1077`]

### Wave 0 Gaps

- None for the test framework. Existing LiveView and Playwright infrastructure covers these behaviors. Add targeted assertions within current files rather than scaffolding another test framework or broad fixture suite.
- PostgreSQL 15+ must be available before claiming local integration/phase-gate verification; the probed PostgreSQL 14 instance is below the documented project floor.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control for this phase |
|---|---:|---|
| V2 Authentication | No new control | Host owns authentication; preserve existing mount pipeline. |
| V3 Session Management | No new control | No session/token change in scope. |
| V4 Access Control | Yes | Re-evaluate current host authorization and row scope on every route; actor-scope saved views on read/apply/write. |
| V5 Input Validation | Yes | Parse only the current allowlisted filter keys; validate bounded origin and `as_of`; reconstruct local return paths. |
| V6 Cryptography | No new control | No cryptographic mechanism or secret handling is added. |
| V8 Data Protection | Yes | Preserve redaction and copy eligibility; never put full unauthorized values in DOM attributes, feedback, or URL state. |
| V7 Error Handling and Logging | Yes | Distinguish unavailable, not-found, absent, pruned, and never-captured states without leaking exception or hidden evidence. |

OWASP ASVS groups these controls under architecture, access control, validation, data protection, and error handling; phase 239 already reviewed the UI scope at ASVS Level 1. [CITED: https://devguide.owasp.org/en/03-requirements/05-asvs/; VERIFIED: `239-SECURITY.md`]

### Known Threat Patterns for Phoenix LiveView

| Pattern | STRIDE | Standard mitigation |
|---|---|---|
| Forged `from`, filter, `as_of`, or origin query | Tampering / elevation of privilege | Treat route params as untrusted; allowlist fields, validate origin, reconstruct local return path, and query through current server scope. |
| Cross-actor saved-view ID | Spoofing / information disclosure | Resolve IDs only against the current actor-owned saved-view collection. |
| Parent outage triggers unsafely scoped child read | Denial of service / information disclosure | Gate child component/query behind successful parent availability. |
| Redacted value exposed by copy button or URL | Information disclosure | Server-render copy affordance only for authorized copyable values; omit full values from URL and feedback. |
| Misleading clipboard success | Integrity / operator error | Success follows only confirmed browser API or fallback completion; announce failure and preserve manual selection. |

## Sources

### Primary (HIGH confidence)

- In-repo Phase 240 locked decisions and deferred scope: `.planning/phases/240-connected-investigation-and-recovery/240-CONTEXT.md`.
- In-repo routing, query allowlist/canonicalization, LiveViews, saved-view schema, UI rendering, and tests listed inline above.
- In-repo Threadline domain model: `prompts/audit-lib-domain-model-reference.md`.
- In-repo OSS/Elixir conventions: `prompts/threadline-elixir-oss-dna.md` and `prompts/prior-art/phoenix-liveview-best-practices-deep-research.md`.
- Phase 239 UI and threat findings: `239-REVIEW.md`, `239-SECURITY.md`, and `239-UI-SPEC.md`.

### Official documentation (MEDIUM confidence)

- Phoenix LiveView `handle_params/3` and `push_patch/2`: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#handle_params/3 and https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#push_patch/2
- MDN Clipboard `writeText()`: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText
- MDN `prefers-reduced-motion`: https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
- MDN deprecated `Document.execCommand()`: https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand
- OWASP ASVS: https://devguide.owasp.org/en/03-requirements/05-asvs/

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read lockfile, package constraints, and existing app/test setup.
- Architecture: HIGH — source, phase context, 239 review/security, domain model, and project prior art agree.
- Pitfalls: HIGH — WR-03 and existing URL/copy/motion behaviors were confirmed in code and tests.
- External browser behavior: MEDIUM — official MDN/HexDocs documentation checked; Context7 provider was unavailable.

**Research date:** 2026-10-10  
**Planning resolutions:** Origin is bounded to origin=timeline plus supported committed fields; drawer motion is immediate unless an existing safe pointer/touch signal satisfies D-10. Both resolved decisions are reflected in Plans 240-01/240-04.  
**Valid until:** 2026-11-09 (stable architecture; recheck browser docs if implementation slips materially)
