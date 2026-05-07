# Phase 64: Raw Timeline Browse & Filter Form - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

A new LiveView under the existing `threadline_operator_surface` mount that lets operators browse and filter the raw audit timeline using the same `Threadline.Query.timeline/2` filter vocabulary the API and `mix threadline.export` already share. URL-as-state via `live_patch`, native HTML form widgets only (no JS framework, no Tailwind, no `live_select` dep), `phx-viewport-bottom` infinite scroll matching the v1.17 TransactionLive / ActorLive pattern. Read-only. No exports buttons in this phase — those land in Phase 65.

</domain>

<decisions>
## Implementation Decisions

### Route + Surface Navigation

- **D-01: New LiveView mounts at the surface root** (the `threadline_operator_surface` mount path itself, e.g. `/audit`). Not at `/audit/timeline`, not at `/audit/changes`. Convention follows Oban Web, LiveDashboard, Hangfire, Sidekiq Web, Sentry org root, GitHub `/audit-log` — the firehose timeline IS the landing page. Adopters paste one URL into Slack / README / doc-contract test, never moves when Phases 66/67 add `/audit/coverage` and `/audit/policy/redaction` siblings.
- **D-02: Add a small inline "← Timeline" back-link** to the existing `.threadline-ui` header on `TransactionLive` and `ActorLive`. No nav-bar component, no shared layout abstraction in v1.18. Defer the real top nav (Timeline / Coverage / Redaction tabs) to Phase 66 when the second sibling actually exists and IA is no longer hypothetical.

### Filter Form Interaction Model

- **D-03: Sticky top toolbar with right-aligned action cluster.** Filter inputs flow on the left; `[Clear all] [Apply]` on the right. Phase 65 will append `[Download CSV] [Download JSON]` to the same cluster — same shape ("operate on the current filter set"), same visual anchor.
- **D-04: Explicit Apply submit** — not auto-apply. `<form phx-submit="apply">` so Enter-anywhere-in-form fires it; `[Apply]` button is the visible affordance. No `phx-change`-driven URL patches on every keystroke. `phx-debounce="blur"` defensively on text inputs. Stable form `id="timeline-filters"` for focus preservation. One submit = one `push_patch` = one history entry, so `live_patch` back/forward navigates filter-history (BROWSE-03), not keystroke-history.
- **D-05: Single "Clear all" link** that patches to the bare mount path (which re-defaults to "last 24h"). No per-pill chips — Threadline has fixed structured keys, not Oban Web's autocomplete query DSL.

### Filter Input Shapes

- **D-06: `:table` filter is `<input list="audited-tables">` + `<datalist>`** populated at mount from `Threadline.Health.trigger_coverage/1` *covered* tables only (never the uncovered list — the read-only ceiling holds, the form must not become a discovery vector for unaudited tables; that surface lives on `/audit/coverage` in Phase 66). Free-text + native browser autocomplete, zero JS. Stale URLs round-trip and degrade to a server-side "no audited table named X — known: posts, comments, users" hint instead of being silently dropped to "All tables".
- **D-07: `:actor_ref` is two flat inputs** — `<select name="filter[actor_kind]">` populated from the fixed `Threadline.Semantics.ActorRef` enum (`user`, `admin`, `service_account`, `job`, `system`, `anonymous`) plus an "Any kind" first option, and `<input type="text" name="filter[actor_id]">`. Two URL params: `actor_kind=` + `actor_id=`. Mirrors the struct 1:1 — no `kind:id` colon-DSL that would break when adopters use colons in their IDs (URNs, integration tokens). When `actor_kind=anonymous`, the id field disables and is stripped on submit (server constructs `ActorRef.new(:anonymous, nil)`).
- **D-08: `:correlation_id` is a plain `<input type="text">`** with `phx-debounce="300"`, `maxlength="256"`, `aria-label="correlation id"`, and a small `<small>` hint: *"request_id, job_id, or integration token. Up to 256 chars."* No `pattern=` constraint — the lib intentionally leaves the format adopter-defined.
- **D-09: `from` / `to` are native `<input type="datetime-local">`** per BROWSE-03 (already locked); inputs render in browser-local time, the LiveView normalizes to UTC `DateTime` before passing to `validate_timeline_filters!/1`.
- **D-10: Validation reuses `Threadline.Query.validate_timeline_filters!/1` verbatim.** UI errors are caught from a `try/rescue ArgumentError` wrapper so the message strings stay literal — the BROWSE-04 doc-contract test pins both ARIA labels and the filter key list against the same allowlist (`@allowed_timeline_filter_keys` in `lib/threadline/query.ex:36`).

### Pagination + Cursor

- **D-11: Infinite scroll via `phx-viewport-bottom` / `phx-viewport-top` + `Phoenix.LiveView.Stream`**, matching the existing `TransactionLive` and `ActorLive` pattern (lib/threadline/operator_surface/live/transaction_live.ex:91-95, actor_live.ex:80-86). Cursor lives in socket assigns. The URL contains **filter state only** — never cursor / scroll / page state.
- **D-12: Page size `50`** passed explicitly at the LiveView call site (`Threadline.Query.timeline_page(filters, page_size: 50, ...)`). The lib's `@default_timeline_page_size = 1000` (lib/threadline/query.ex:36) stays as-is for API/export callers — only the LiveView needs a smaller window. No URL knob, no UI control.
- **D-13: Tombstone safety** — with no cursor in the URL, a 6-month-old pasted URL re-resolves from "now" backward through the filter window. Retention purges produce a clean empty-state, never a silent stuck-on-empty-cursor failure.
- **D-14: On filter change, stream resets** with `stream(:changes, page.entries, reset: true)` and the cursor in assigns clears.

### Canonical URL Contract (locked here for Phase 65 to reuse verbatim)

```
# Default first mount (no params → last 24h applied server-side)
/audit?from=<now-24h>&to=<now>

# Full filter set
/audit?from=2026-05-01T00:00&to=2026-05-06T23:59&table=posts
       &actor_kind=user&actor_id=42&correlation_id=req_abc123

# Anonymous filter (id stripped on submit)
/audit?actor_kind=anonymous

# Stale table → 200 + empty state + "known tables: …" hint
/audit?table=old_name

# Phase 65 will reuse identical params for the export endpoint
GET /audit/exports/changes.csv?from=…&to=…&table=…
```

Empty params are omitted from the canonical query string (paste-friendly URLs). The URL key allowlist matches `validate_timeline_filters!/1` exactly: `from`, `to`, `table`, `actor_kind`, `actor_id`, `correlation_id`. (`actor_kind` + `actor_id` collapse to a single `:actor_ref` keyword before validation.)

### Claude's Discretion

- Exact CSS class names and visual styling under `Threadline.OperatorSurface.Style` — follow the existing `.threadline-ui` namespace + CSS-variable convention; researcher / planner may extend variables as needed.
- Exact wording of empty-state copy ("No changes match these filters in the selected window."), the unknown-table hint, and the correlation-id help text — keep terse, match the existing tone in TransactionLive / ActorLive empty states.
- Stream DOM ids and `phx-update="stream"` boilerplate.
- Exact ARIA labels — must be locked by the doc-contract test (BROWSE-04), but the planner picks the literals and the test asserts them.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contracts and milestone scope
- `.planning/ROADMAP.md` §"Phase 64: Raw Timeline Browse & Filter Form" — phase goal + 4 success criteria + sequencing rationale (Phase 64 must come first; Phase 65 re-validates against the same filter literal).
- `.planning/REQUIREMENTS.md` §"Raw timeline browse + filter form (BROWSE)" — BROWSE-01..04 verbatim. Also see "Out of Scope (explicit exclusions for v1.18)" — read-only ceiling, no runtime policy edits, no saved views.
- `.planning/PROJECT.md` §"Current Milestone: v1.18" — strategic framing.
- `.planning/STATE.md` §"Accumulated Context > Decisions" — v1.18 scoping rationale, Oban Web filter-pills anchor, optional-Phoenix-deps invariant.

### Library APIs that the LiveView must call (and not duplicate)
- `lib/threadline/query.ex:36` — `@allowed_timeline_filter_keys` literal that BROWSE-04 doc-contract test asserts parity against.
- `lib/threadline/query.ex:130-155` — `validate_timeline_filters!/1`. UI must reuse this exactly; no UI-only filter dialect.
- `lib/threadline/query.ex:174-198` — `validate_correlation_id_filter!/1` rules (binary, ≤256 bytes after trim, non-empty).
- `lib/threadline/query.ex:282-318` — `timeline_page/2` (cursor + page_size keyset paging contract).
- `lib/threadline/semantics/actor_ref.ex:1-80` — `Threadline.Semantics.ActorRef.new/2` and the fixed kind enum (`user / admin / service_account / job / system / anonymous`); `:anonymous` is the only kind allowed nil id.
- `lib/threadline/health.ex:26` — `Threadline.Health.trigger_coverage/1`. Phase 64 calls it at mount to populate the `<datalist>` for the table filter (covered tables only).

### v1.17 surface artifacts the new LiveView must integrate with
- `lib/threadline/operator_surface/router.ex:1-50` — `threadline_operator_surface` mount macro; new `live("/", TimelineLive, :index)` route lands here. Note the `Code.ensure_loaded?(Phoenix.LiveView)` file-scope gating (Sentry idiom — required pattern for the new LV file too).
- `lib/threadline/operator_surface/live/transaction_live.ex:91-95` — viewport-bottom infinite-scroll pattern to reuse.
- `lib/threadline/operator_surface/live/actor_live.ex:80-86,101-138` — `set-window` event + viewport hooks + cursor-in-assigns pattern; closest existing analog. Add small "← Timeline" back-link in render/2.
- `lib/threadline/operator_surface/style.ex` — `.threadline-ui` CSS namespace + CSS-variable convention. Extend, don't replace.
- `lib/threadline/operator_surface/auth.ex` — `:authorize_fn`-returned scope that the new LiveView must thread into `Threadline.Query.timeline_page/2` calls per the v1.17 auth contract.

### Verification + CI invariants
- `mix verify.compile_no_optional` alias (Phase 57) — must stay green. The new LiveView file MUST be wrapped in `if Code.ensure_loaded?(Phoenix.LiveView) do … end` at file scope.
- BROWSE-04 doc-contract test — to be added in this phase. Assert: route literal, form ARIA labels, filter key list parity with `@allowed_timeline_filter_keys`.

### Idiomatic peer projects (consult during planning if patterns are unclear)
- Oban Web — sticky toolbar + filter pills (we adapt, don't copy: no DSL chips here).
- LiveDashboard — `phx-viewport`-style infinite list patterns.
- Sentry — explicit-Apply form, key:value search-bar shape.
- GitHub Audit Log — landing-page-is-firehose convention; "Clear" link.
- CloudTrail Lookup events — sticky toolbar with right-aligned action cluster.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Query.timeline_page/2` — already returns `%TimelinePage{entries, next_cursor}` keyset page; LiveView calls it directly.
- `Threadline.Query.validate_timeline_filters!/1` — single source of truth for filter validation. UI wraps it in `try/rescue ArgumentError` to render inline errors.
- `Threadline.Health.trigger_coverage/1` — supplies `<datalist>` options for the table filter (covered tables only).
- `Threadline.Semantics.ActorRef.new/2` — converts UI `actor_kind` + `actor_id` into the `%ActorRef{}` for `validate_timeline_filters!/1`.
- `Threadline.OperatorSurface.Style.css/1` — CSS-variable themed `.threadline-ui` namespace; extend with toolbar / form / pill styles.
- `Phoenix.LiveView.Stream` — already used in TransactionLive / ActorLive for incremental rendering.
- `phx-viewport-bottom` / `phx-viewport-top` — already wired in TransactionLive / ActorLive; copy the pattern.
- `live_patch` / `push_patch` — already used in TransactionLive (history sub-view); reuse for filter changes.

### Established Patterns
- **File-scope gating**: every operator-surface module starts with `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule … end end`. New LV file MUST follow this. `mix verify.compile_no_optional` enforces it in CI.
- **CSS isolation**: every render block opens with `<div class="threadline-ui"><Threadline.OperatorSurface.Style.css /> …`. Do not introduce a layout component; do not introduce Tailwind utility classes.
- **Repo resolution**: `socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()` — same shape as TransactionLive line 6-7 and ActorLive line 6-7.
- **Auth scope threading**: `:authorize_fn`-returned scope is set on socket assigns by `Threadline.OperatorSurface.Auth` on_mount; investigation queries receive it through the helper layer. New LiveView reads it the same way.
- **Empty-state markup**: `<div class="empty-state"><p>…</p></div>` — terse copy, neutral tone (see existing `TransactionLive` line 78-80, `ActorLive` line 73-77).

### Integration Points
- New file: `lib/threadline/operator_surface/live/timeline_live.ex` (the LiveView itself, file-scope gated).
- New file: `test/threadline/operator_surface/live/timeline_live_test.exs` (mount + filter-apply + URL round-trip).
- New file: `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` (BROWSE-04: route literal, ARIA labels, filter key parity).
- Extend: `lib/threadline/operator_surface/router.ex` — add `live("/", TimelineLive, :index)` inside the existing `live_session :threadline` block.
- Extend: `lib/threadline/operator_surface/style.ex` — toolbar / form / button-cluster CSS.
- Extend: `lib/threadline/operator_surface/live/transaction_live.ex` + `actor_live.ex` — add inline "← Timeline" back-link to the header (1-2 line edit each).

</code_context>

<specifics>
## Specific Ideas

- **Idiomatic anchor**: Oban Web filter pills (called out in STATE.md and v1.18 scoping). Adapted, not copied — Threadline has fixed structured keys, not a DSL, so the form-with-action-cluster shape carries the spirit (visible filter state, primary actions on the right) without the chip ceremony.
- **Default time window**: "last 24h" applied server-side at first mount (no params). Operator can override by editing the datetime-local inputs and clicking Apply.
- **URL contract** is locked verbatim above (see "Canonical URL Contract"). Phase 65 export endpoint reuses it exactly — same params, same `validate_timeline_filters!/1`, same actor_kind+actor_id collapse to `actor_ref:`.
- **Sticky toolbar layout** sketched at:
  ```
  +------------------------------------------------------------------+
  | <form id="timeline-filters" phx-submit="apply" role="search">    |
  |   From [datetime-local]  To [datetime-local]                     |
  |   Table [input + datalist]  Actor kind [select] Actor id [text]  |
  |   Correlation id [text]                                          |
  |                                            [Clear all] [Apply]   |
  | </form>                                                          |
  +------------------------------------------------------------------+
  | <div phx-update="stream" phx-viewport-bottom="next-page"> rows … |
  ```
- **Phase 65 forward-compat**: the action cluster will gain `[Download CSV] [Download JSON]` to the right of `[Apply]`, sharing the same `phx-submit` semantics (operate on the currently-rendered filter set).

</specifics>

<deferred>
## Deferred Ideas

- **Real top nav bar (Timeline / Coverage / Redaction tabs)** — defer to Phase 66 when the second sibling route actually exists. Inline back-link covers Phase 64 needs without locking IA prematurely.
- **Saved views** (named filter combos with owner/visibility/sharing) — already deferred to v1.19+ in REQUIREMENTS.md "Future Requirements"; URL bookmarks cover the persistence story for free.
- **Per-filter chip UI / "x" remove on each pill** — not needed; the form fields themselves are the visible filter state, "Clear all" is the only reset gesture.
- **`page_size` URL knob (`?page_size=25|50|100`)** — not needed at v1.18; viewport infinite scroll obviates it. Revisit if real adopters report dense-feed pain.
- **Cursor in URL / "Copy this view" snapshot button** — not needed; Phase 65 export covers "save these exact rows" durably (CSV/JSON of the filter set).
- **Numbered offset pagination** — out of scope, never landing (offset + audit data + Postgres = pathological at scale; lib has no offset API).
- **Kind-only actor filter (`actor_kind=user` with no id) for non-anonymous kinds** — would require a `Threadline.Semantics.ActorRef` API expansion (today rejects nil id for non-anonymous); out of Phase 64 scope. Revisit when an adopter reports the need.
- **Phase 66 integration of `:schema` arg into the table `<datalist>`** — when `Threadline.Health.trigger_coverage/1` gains `:schema`, render qualified names (`schema.table`) and accept both `table` and `schema.table` URL inputs. Scoped to Phase 66.
- **Auto-refresh / "newer events" badge on the timeline LV** — not needed at v1.18; explicit reload covers it. Revisit only if real adopter pain reports it.

### Reviewed Todos (not folded)
None — no `.planning/todos/` matches surfaced for Phase 64.

</deferred>

---

*Phase: 64-raw-timeline-browse-and-filter-form*
*Context gathered: 2026-05-06*
