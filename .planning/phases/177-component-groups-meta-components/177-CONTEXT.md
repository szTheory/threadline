# Phase 177: Component groups / meta-components - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Audit the recurring component *configurations* as cohesive units — intentional spacing/hierarchy, states aligned across children, motion clarifying transitions — holding together across narrow and wide layouts, verifiable on the `/audit/__stress` route at multiple viewports. Delivers GROUP-01, GROUP-02.

The ~12 configurations (GROUP-01's literal acceptance list): page-header+actions+breadcrumbs; toolbar+search+filters+sort; table+empty+loading+pagination; stat-cards+chart+table; detail-header+metadata+actions; modal-confirm+destructive; drawer+form; toast+state-update; tabs+subviews; empty+CTA; permission-denied; reconnect/offline-banner+disabled-actions.

**Critical reframe (mirrors 175/176):** this is *compose-and-audit*, not greenfield. The constituent primitives already exist in `OperatorSurface.UI` (`data_table`, `pager`, `page_header`, `stat_tile`, `kv`, `ref`, the empty/loading/error/stale state family, `modal`, `drawer`, `toast`, `tabs`, `dropdown`, `segmented_control`, `accordion`). A "group" is the **assembly rule** between them — gap rhythm, hierarchy, which state shows when, how siblings react, what moves. The job is to lock those rules: ship a tiny set of layout primitives, extract the 2–3 assemblies that recur *with coordination logic* into named meta-components, and audit all 12 configurations as units on the stress route.

**In scope:** `stack`/`cluster` layout primitives over the existing `--tl-space-*` scale; named meta-components `data_panel` (table+state+pager), `toolbar` (search+filters+sort), `detail_header` (title+metadata+actions); a `:breadcrumbs` slot on the existing `page_header`; cross-child state-coordination rules; group motion language; the reconnect/offline-banner+disabled-actions group via LiveView connection CSS hooks; map the 6 reserved baseline group stories onto the 12 configurations and add the missing 6 as group stress stories (tagged live vs reference-only).

**Out of scope (other phases):** per-page/flow stress pass (Phase 178 — PAGE-01..03); microcopy/IA sweep (Phase 179 — group copy is decided alongside each group, not swept); accessibility verification & adversarial closeout (Phase 180 — we *build to* AA here, formal audit lands there); any public/host-facing component API (v1.31 freeze); capture & semantics layers (untouched). No chart library and no new runtime deps (charts stay hand-rolled inline SVG/CSS bar per D-176-22).

</domain>

<decisions>
## Implementation Decisions

### GROUP — Realization mechanism
- **D-01:** **Hybrid, primitives-first.** Build a tiny set of layout/spacing primitives that pages compose explicitly, and extract a named meta-component ONLY for assemblies that recur verbatim with real coordination logic. Everything else is audited in-place as inline composition over the primitives. This honors "explicit composition" + "build for real demand" (OSS-DNA) over deep wrapper components, while still locking the high-recurrence assemblies. Overturns a pure "named component per configuration" reading of the requirement.
- **D-02:** **Layout primitives: `UI.stack/1` (vertical rhythm) + `UI.cluster/1` (horizontal grouping with wrap).** Both `@doc false`, strict `attr`/`slot`, `--tl-*`-driven, zero public API (the 173/174/175 pattern). They own the gap rhythm so "intentional spacing" stops being per-call-site class-soup. Map to the existing `--tl-space-*` scale (`tokens.css` L6–16); a small set of *semantic* gap tokens (stack / inline / section — see D-09) sits on top.
- **D-03:** **Named meta-components to extract (the ones with genuine coordination + recurrence):**
  - **`UI.data_panel/1`** — wraps `data_table` + the empty/loading/error/stale/no-data/permission/unavailable state family + `pager`, with the cross-child state-coordination (D-06) baked in. Highest-value extraction — it's where state-alignment bugs live. Recurs on coverage, retention, timeline.
  - **`UI.toolbar/1`** — search + filters + sort as a `cluster` with consistent wrap/spacing and disabled-coordination. Recurs on timeline / any filtered list.
  - **`UI.detail_header/1`** — title + metadata `kv` + actions for the transaction / actor / row-history detail pages (recurs 3×).
- **D-04:** **Do NOT make a new group for page-header+actions+breadcrumbs.** Add a **`:breadcrumbs` slot** (alongside the existing `:actions`) to the existing `UI.page_header/1`. One canonical header, not two.
- **D-05:** **Everything else stays inline composition** over `stack`/`cluster` (stat-cards+chart+table, modal+destructive, drawer+form, toast+state-update, tabs+subviews, empty+CTA, permission-denied, reconnect/offline). They are audited as units on the stress route but not extracted into wrappers — no real demand for a shared component, and they vary per page.

### GROUP — Scope & registry map
- **D-06b:** **Audit all 12 configurations as group stress stories** (GROUP-01 enumerates them as literal acceptance criteria). Map the 6 existing reserved baselines (`action-bar`, `filter-bar`, `kv-list`, `pagination`, `status-strip`, `timeline-list` in `stress_fixtures.ex` `@group_stories`) onto the 12 and add the missing ones. Build each from real-page markup where it exists; where a config isn't on a live page yet (e.g. drawer+form, tabs+subviews), the **stress story IS the canonical reference assembly**.
- **D-07:** **Tag each group story `live` vs `reference-only` in the ledger** so Phase 178 (page-stress) knows which groups are actually shipped on a real page vs which exist only as the stress reference. Reference-only groups still get audited for spacing/hierarchy/state/motion; they just don't have a page consumer yet.
- **D-08:** **Reconnect/offline-banner + disabled-actions group rides LiveView's built-in connection CSS hooks.** Use the framework's body classes (`.phx-loading`, `.phx-disconnected`, `.phx-error` / `.phx-client-error` / `.phx-server-error`) to drive a reconnect banner (`role="status"`) and disable mutating actions via pure CSS (descendant `pointer-events`/`opacity`/`aria-disabled`). Zero new JS, zero new deps, CSP-clean — it's the framework's own lifecycle, and unlike a mount-time `connected?/1` assign it catches a *dropped* socket mid-session. Chosen over a server `connected?`/heartbeat assign for exactly that reason.
- **D-08b:** **Chart piece stays hand-rolled inline** (carried from D-176-22): the stat-cards+chart+table group's chart is inline SVG / CSS bar, no chart library (zero-dep invariant), encoding meaning with label + shape/pattern (no color alone). NOT a new named component — it only recurs on coverage, so no real demand.

### GROUP-02 — Cross-child state coordination ("states aligned across children")
- **D-06:** **Scoped-by-state-class coordination** — siblings react by state *kind*, not uniformly:
  - **Content-replacing states (empty / no-data / error / loading):** swap ONLY the data region. The `page_header` (+ breadcrumbs) and `toolbar` stay for orientation, BUT the toolbar's filter/sort controls go **disabled** while loading and on hard error (a usable filter over a broken/loading table is the GROUP-02 failure to avoid).
  - **Resource-level permission / unavailable:** collapse the whole **panel body** to one message (you genuinely can't see anything), while the `page_header` stays so the operator still knows where they are.
  - **Stale:** a `role="status"` banner **above still-rendered data** — never replaces it (D-176-14; suspect last-good data stays on screen as evidence).
- **D-06c:** **The `data_panel` owns the focus-move on state transition**, per the per-state focus rules already locked in D-176-15 (error focuses a `tabindex=-1` heading; permission/unavailable focus a rescue element; loading/empty are `role=status`). Groups coordinate these — they do not reinvent the state taxonomy.
- **D-06d:** **Branching stays the page author's job** (D-176-17): ok-empty → `empty` (first-run) vs `no_data` (filters active); `:failed` reason → `permission` / `unavailable` / generic `error`. The group provides the *coordinated shell*; the typed server reason still flows through to pick the right state.

### GROUP-02 — Motion language ("motion clarifies state transitions")
- **D-10:** **What earns motion (everything else is instant):**
  1. **Overlay enter/exit** — modal (fade+scale), drawer (slide from its edge), toast (fade up), dropdown/popover (fade+small offset). Via `Phoenix.LiveView.JS` show/hide transitions (CSP-clean). This does the most orientation work.
  2. **Data-region state swap** — a short cross-fade (`--tl-motion-fast`) on the *region container* when it swaps happy↔loading↔empty↔error, so the change reads as intentional rather than a flicker. Opacity-only so it degrades cleanly.
  3. **Stale banner appear** — fade/slide in above live data when a refresh fails.
  4. **Tab / segmented switch** — animate the active indicator and/or a subview crossfade.
- **D-11:** **Motion constraints (carried from the existing `style.ex` motion block ~L3107–3117):** GPU-only (transform/opacity), reuse the motion tokens (`--tl-motion-fast` 120ms, `--tl-motion-base` 180ms, `--tl-ease-standard`), fire on mount. **Never animate high-frequency actions** — the timeline stream's per-row inserts stay un-animated (snappy paging beats an entrance flourish). The data-region swap (D-10.2) animates the **container on a state change** (low-frequency), NOT individual streamed rows.
- **D-12:** **Reduced-motion posture is already settled system-wide** — the `@media (prefers-reduced-motion: reduce)` blanket at `style.ex:3868` collapses all transitions/animations to ~1ms. New group motion inherits it automatically; no per-component reduced-motion handling needed beyond using transform/opacity + the motion tokens.

### Claude's Discretion (handle per existing conventions)
- **D-09:** **Spacing/hierarchy rhythm** — likely add a small set of *semantic* gap tokens (stack / inline / section) layered over the numeric `--tl-space-*` scale, consumed by `stack`/`cluster`. Exact token names and which numeric step each maps to: discretion, matching the `--tl-*` BEM idiom.
- **D-13:** **Per-group responsive reflow** — toolbar wrap order at narrow widths, action-bar → kebab collapse, stat-cards grid → stack, breadcrumb truncation/overflow. Reuse the existing responsive mechanisms (`data-label`/`::before` table stacking, `cluster` wrap); no ARIA table roles (D-176-09). Verify at 320/375/768/1024/1440 on the stress route.
- **D-14:** Exact component names/slot APIs for `stack`/`cluster`/`data_panel`/`toolbar`/`detail_header`, the `:breadcrumbs` slot shape on `page_header`, ledger tag field name for live/reference, new `--tl-*` token names, and file location — match the existing `ui.ex` `attr`/`slot` + `--tl-*` idioms and the 173/174/175/176 conventions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — GROUP-01, GROUP-02; v1.37 invariants (no public API, zero new runtime deps, inline CSS only, CSP-proof, WCAG 2.2 AA, mobile-first 320–1440, brand-token parity).
- `.planning/ROADMAP.md` §"Phase 177" — goal + 2 success criteria; milestone invariants block (inline assets only, capture/semantics untouched, fail-closed auth, brand voice).

### Prior phase context (the conventions this phase composes on top of)
- `.planning/phases/176-data-display-operator-patterns/176-CONTEXT.md` — **most load-bearing.** State taxonomy (empty/loading/error/stale/no-data/permission/unavailable), D-13/D-14/D-15/D-17 (state shapes, stale-precedes-data, per-state focus/role, async branching), `data_table`/`kv`/`pager`/`ref` extraction, D-22 charts-inline, "one card boundary per logical unit" (D-11/D-12). The data_panel meta-component composes these directly.
- `.planning/phases/175-navigation-app-shell-runtime-theme-picker/175-CONTEXT.md` — `page_header`/`pager` components, CSP-hardening + embed-scripts posture, no-color-alone active-state pattern.
- `.planning/phases/174-form-components/174-CONTEXT.md` — explicit `name/value/errors` props (drawer+form group), native-HTML-first, `phoenix_html` optional.
- `.planning/phases/173-primitive-components-extract-audit-each-in-isolation/173-CONTEXT.md` — single internal `UI` module, strict `attr`/`slot`, `@doc false`, stress-route isolation-audit pattern.

### Domain & OSS DNA
- `prompts/audit-lib-domain-model-reference.md` — domain hierarchy the detail-header/breadcrumb/kv groups mirror; §5.7/§5.8 (authz for viewing, row-level access) ground the permission/unavailable coordination; §9.3/§9.4 (redaction/prune irreversibility) ground the modal-confirm+destructive group's T3 tier.
- `prompts/threadline-elixir-oss-dna.md` — quality bar: explicit composition, build-for-real-demand, deterministic tests, fail-closed, no-public-API discipline (the basis for D-01 hybrid choice).

### Brand (CURRENT — prefer over `prompts/Threadline Brand Book.txt`)
- `brandbook/brand-book.md` — voice/microcopy (plainspoken, sentence case, no "!"), non-color-alone rule, button hierarchy, cards rule (~L348: not page sections inside cards), focus/hover, 8px radius cap.
- `brandbook/tokens.json`, `brandbook/tokens.css` — `--tl-space-*` scale (L6–16), `--tl-motion-fast/base` + `--tl-ease-standard` (L76–78); all new group CSS uses these (dark + light/system lanes).

### Ecosystem best-practice research
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — `Phoenix.LiveView.JS` show/hide transitions (group motion), `connected?/1` & connection lifecycle (offline group), `assign_async`/`<.async_result>` + streams, function-component composition + `attr`/`slot`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (extend/compose, don't rebuild)
- `lib/threadline/operator_surface/ui.ex` — constituents already present: `page_header/1` (L210 — add `:breadcrumbs` slot), `pager/1` (L291), `stat_tile/1` (L350), `kv/1` (L409), `data_table/1` (L446), `empty_state/1` (L489), `error_state/1` (L526), `loading_state/1` (L551), `stale_banner/1` (L570), `data_state/1` (L648), `modal/1` (L676), `drawer/1` (L746), `toast/1` (L814), `tabs/1` (L927), `segmented_control/1` (L945), `accordion/1` (L962), `dropdown/1` (L899), `divider/1` (L124). **Add here:** `stack/1`, `cluster/1`, `data_panel/1`, `toolbar/1`, `detail_header/1`.
- `lib/threadline/operator_surface/stress_fixtures.ex` — `@group_stories` (L65, 6 reserved baselines) → expand/remap to the 12 configurations; `reserved_story_maps(@group_stories, "group", 177)` (L243). Add live/reference tag to story maps.
- `lib/threadline/operator_surface/live/stress_live.ex` — category-filtered story browser + preview; groups render here for the viewport × state audit.
- `lib/threadline/operator_surface/presentation.ex` — `human_time/2`, `exact_time/1`, `ref/2` (truncation), reused inside detail_header/data_panel cells.

### Established Patterns
- 173–176: extract class-soup → internal `UI` function components, `@doc false`, strict `attr`/`slot`, `--tl-*`-token-driven, audited in isolation on `/audit/__stress` across viewports + interaction states.
- State taxonomy is named-family (D-176-13), NOT a polymorphic `variant=` mega-component — groups coordinate the existing family, they do not add a new one.
- Motion block in `style.ex` (~L3107): GPU-only, mount-fired, motion tokens, never animate high-frequency stream rows; reduced-motion blanket at L3868.
- `data-status` stripe convention; CSP-proof shell (no inline `on*=`; `Phoenix.LiveView.JS` for menus/modals/transitions; delegated copy listener).

### Integration Points
- 11 LiveViews under `lib/.../live/` are the group consumers: coverage, retention_history, policy_redaction, transaction, actor, row_history(+component), timeline, evidence, export_status, start (+ operator shell). Detail-header → transaction/actor/row-history; data_panel → coverage/retention/timeline; toolbar → timeline; offline group → all (shell level).
- `style.ex` (~3935 lines) holds all CSS: add `tl-stack`/`tl-cluster`/`tl-data-panel`/`tl-toolbar`/`tl-detail-header` + reconnect/offline rules keyed off `.phx-disconnected`/`.phx-error`; reuse motion tokens + reduced-motion blanket.
- LiveView connection lifecycle: body classes `.phx-loading`/`.phx-disconnected`/`.phx-client-error`/`.phx-server-error` drive the offline banner + action-disable purely in CSS.

</code_context>

<specifics>
## Specific Ideas

- A group is a *unit*: spacing/hierarchy intentional, states aligned across children, motion clarifying transitions, holds together 320→1440. The audit asks "does this configuration read as one coherent thing under ugly data at every viewport?" — not "does each child work in isolation" (that was 173–176).
- The single highest-value extraction is `data_panel` — it's the locus of state-alignment bugs (table errors while filters stay live; loading flicker; stale data silently replaced).
- Forensic/trust distinctions from 176 must survive composition: permission ("exists, you can't see it") vs no-data ("filter excluded it") vs unavailable ("down/redacted/pruned") must stay unmistakable even when a group collapses to one message.
- Motion is restraint-first: overlays + state-swaps + tab indicator move; high-frequency stream rows and layout reflow do not. Everything degrades to ~instant under reduced-motion via the existing blanket.

</specifics>

<deferred>
## Deferred Ideas

- **Fully building configs with no live page (drawer+form, tabs+subviews as shipped surfaces)** — built only as stress *reference* assemblies this phase (D-07); promote to a real page when a genuine operator need surfaces (build-for-real-demand).
- **A named `UI.chart` component** — deferred; chart stays hand-rolled inline (only recurs on coverage). Extract only if a second charted surface appears.
- **Group-level bulk actions / multi-select** — explicitly rejected for the data surface in D-176-19; not revisited here.
- **Per-group copy/microcopy sweep** — group copy is decided alongside each group; the systematic IA/microcopy pass is Phase 179.

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 177-Component groups / meta-components*
*Context gathered: 2026-06-18*
