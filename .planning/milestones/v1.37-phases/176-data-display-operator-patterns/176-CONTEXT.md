# Phase 176: Data display & operator patterns - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every `/audit` data surface (tables/lists/timeline/KV/charts/status/actions) read clearly under real (ugly) data, distinguish all empty/loading/error/stale/permission states, and flatten accidental nesting + table overuse system-wide. Delivers DATA-01..DATA-05.

**Critical reframe from discussion (mirrors Phase 175):** most of this phase is *fix-and-consolidate*, not greenfield. The pieces largely exist but have drifted: there are **five divergent "ugly value" rendering paths**, KV/diff cells render **untruncated with no copy**, `empty_state`/`error_state` already encode a named-family convention to extend, `dropdown/1` + `modal/1` already exist for actions, and the retention prune confirm is a **client-only `data-confirm`** with no server enforcement. The job is to converge these onto a small set of internal `Threadline.OperatorSurface.UI` components (extending the 173/174/175 pattern), kill the forensic footguns, and audit each unit in isolation on the stress route across viewports + states.

**In scope:** consolidate ugly-value rendering into one ref component; extract `UI.kv/1` + `UI.data_table/1` from class-soup; convert single-record "tables" to description lists; fix responsive collapse; build the full data-state family (loading/stale/no-data/permission/unavailable); per-row kebab actions + tiered destructive confirmation with server-side enforcement; flatten the coverage command shell + remove accidental nesting.

**Out of scope (not this phase):** component groups / meta-components (Phase 177); per-page/flow stress pass (Phase 178); microcopy/IA sweep (Phase 179 — copy here is decided alongside each component, not swept); accessibility verification & adversarial closeout (Phase 180 — we *build to* AA here, formal audit lands there); the keyset query/pagination engine (Phase 175, done — read-only); any public/host-facing component API (v1.31 freeze).

</domain>

<decisions>
## Implementation Decisions

### DATA-01 — Copy + truncation of ugly values
- **D-01:** **Consolidate five drifting ref paths into ONE.** Today `secondary_ref/2`, `value_token/1`, and three ad-hoc copy wirings diverge. Introduce a single private HEEx component (`<.tl_ref>` / name at discretion) backed by `Presentation.ref/2 → %{visible, title, full}`. The component is the call-site API; the helper is its unit-testable core.
- **D-02:** **`data-tl-copy` MUST bind `ref.full`** (the exact, complete value) — never `.title`, never the bare field. Today `transaction_live` copies `.title` and only works by load-bearing coincidence; if `secondary_ref` ever truncated `.title`, every copy button would silently copy a truncated value — the single worst forensic outcome. Put `data-tl-copy={ref.full}` on the `<code>` element too, so the no-JS fallback and any future click-the-value enhancement have a clean source.
- **D-03:** **Truncation is server-side, middle, tail-biased** (guarantee ≥ 8 chars of tail; add a `:tail_min` to `truncate_middle/2`). Rule per value type: UUID/correlation id → middle (`max ~34`); ARN / `table.row` / `type/id` ActorRef → tail-weighted middle; hash → middle (`~24`); file path → middle keeping the filename tail (`~42`); email → truncate localpart, **keep full domain**; URL → keep scheme+host head and last path segment tail; **ISO timestamp → never truncate** (show `human_time`, full ISO in `title`). Entropy/discriminator location dictates the form (GitHub SHA / Stripe prefix / AWS ARN lessons).
- **D-04:** **Route KV snapshot values and diff before/after cells through the same path.** This is the core DATA-01 gap: `value_token/1` returns untruncated text and KV/diff templates render it raw with no copy button — exactly where an operator grabs a value to paste into SQL. Truncate (longer `max ~56`) + add the gated copy affordance.
- **D-05:** **Kill the CSS double-truncation.** Remove `text-overflow: ellipsis` from `.tl-secondary-ref` (style.ex ~2498). It is inert today (no `white-space: nowrap`) but is a latent tail-clipper at 320px. Server middle-truncation is the *only* truncator; CSS's job is `overflow-wrap: anywhere` (wrap, never clip) so the preserved tail is always reachable on mobile.
- **D-06:** **CSP / no-JS posture (carried from D-175):** a library cannot mint a per-response nonce, so keep the embedded helper (`script.ex`) on by default with `operator_surface_embed_scripts: false` as the strict-adopter escape hatch, and keep `Script.enabled?()` gating each copy button (`:if=`). **Guarantee zero-JS recovery:** when scripts are disabled, render `ref.full` (not the truncated `visible`) in the `<code>` so select-all yields the exact value; the `title` tooltip is a supplement, not the only path (it's not selectable on touch).
- **D-07:** **`copy_label` is a `required` attr with no default** → shipping a generic "Copy" is a compile-time omission. Visible button text = "Copy"; the *aria-label* carries specificity ("Copy correlation id", "Copy transaction id", "Copy row id", "Copy file path", "Copy {table} capture command"). Keep the existing non-color-only `.tl-copy.is-copied::after { content: "Copied" }` chip + reduced-motion-safe pulse; add a `:focus-visible` ring; optional (recommended) visually-hidden `aria-live="polite"` region for SR confirmation. Microcopy: "Copy"/"Copied" (no exclamation), raw full value in `title`.

### DATA-01 + DATA-05 — Table overuse, responsive collapse, flatten nesting
- **D-08:** **Extract two internal function components** into `OperatorSurface.UI` (`@doc false`, full `attr`/`slot`, `--tl-*`-driven, zero public API):
  - **`UI.kv/1`** — wraps the existing correct `tl-kv` `<dl>` (lift from `row_history_component`), `:item` slot with required `key` attr. Makes "single-record → `<dl>`" the path of least resistance and retires `tl-param-list`/`tl-meta` span-soup.
  - **`UI.data_table/1`** — mirror CoreComponents `table/1` with a `:col` slot whose `label` feeds **both** `<th>` and each `<td data-label>` (structurally guarantees correct mobile labels). Must support `stream` (→ `phx-update="stream"` on `<tbody>`), `row_id`, `row_status` (→ existing `data-status` stripe), pass-through variant `class`, and always emit `tl-table tl-table--responsive` (responsive by default). `:action` slot hosts the kebab (see D-13).
- **D-09:** **Responsive mechanism = keep `data-label` + `::before` stacking exactly as-is.** **Add NO ARIA table roles** (`role="table"/"row"/"cell"`). This *overturns* the starting position: the repo keeps a real `<table>` and restyles it (`<tr>{display:block}` / `<td>{display:grid}`), so re-asserting grid roles makes AT announce "table, row, cell" over what is visually a stacked card — a regression. Native `<table>` + source-ordered label/value is WCAG 2.2 AA-compliant. **No sticky-first-column / extra horizontal-scroll fallback** — defer (none of the 3 tables need it: coverage 4 cols, retention 5, policy 2 data cols); `tl-table-wrap { overflow-x:auto }` remains for desktop overflow only.
- **D-10:** **Per-surface verdict (apply the rubric):**
  - **Keep as `<table>`:** Coverage (multi-row status comparison), Retention history (streamed runs × columns — drives `data_table` `stream:` support).
  - **Keep as a 2-column diff table — do NOT convert to KV (overturns the rubric):** Policy/Redaction is a per-key *Configured vs Deployed* comparison; a flat `<dl>` would destroy the comparison. Keep tabular; fix its broken collapse (`scope="row"` on the field `<th>`, ensure the field name renders when stacked).
  - **Convert to `UI.kv` `<dl>`:** Transaction metadata, Actor detail header (single-record attribute sets; retire `tl-param-list`/`tl-meta`).
  - **Already correct `<dl>` — leave + use as `UI.kv` source:** Row history snapshot.
  - **Keep as cards/list:** Timeline (streamed change cards), Evidence (`tl-record-card`), Exports (`tl-job` cards — normalize their per-job filter `tl-param-list` → `UI.kv`), Row-history timeline list.
- **D-11:** **DATA-05 flatten rule = "one card boundary per logical unit"** (brand-book.md:348 — "Cards: use only for individual repeated items, not page sections inside cards"). A bordered/elevated surface marks exactly one repeated item or one self-contained panel; page *sections* (header, summary band, command bar) are plain `<section>`/`<header>` with spacing + thin divider/rail.
- **D-12:** **Concrete coverage fix:** the real defect is *not* literal `card > card` — it is the success branch hand-rolling a page header (`tl-page__title/__lede/__meta`) inside a synthetic `tl-coverage-command` shell, while the error/empty branches use `UI.page_header`. Fix: (1) delete the hand-rolled header, use `UI.page_header` (title + `:lede` + `:actions` Refresh + last-checked `:meta`) in all three branches; (2) demote/remove the `tl-coverage-command` shell so its children (trust-rail, metric `tl-summary-grid`, remediation, table) become direct page-stack siblings spaced by `--tl-gap-stack`; (3) keep `tl-card--metric` tiles (legitimate repeated items); (4) delete the dead `tl-coverage-command__*` CSS. **Add a regression test** that `refute`s any card-family class nested under another card-family class per rendered page.

### DATA-03 — Data-state taxonomy
- **D-13:** **Extend the existing named-family convention; do NOT build a polymorphic `data_state variant=` mega-component.** `error_state` is already `empty_state variant="error"` — DATA-03 extends that decision, not reverses it. Add **`loading_state/1`** and **`stale_banner/1`** as named siblings; extend `empty_state`'s `variant` enum with **`no_data`, `permission`, `unavailable`**. Dividing line: content-replacing states share one shape → variants of `empty_state`; the two structurally-different states (loading, stale) earn their own functions.
- **D-14:** **`stale` is categorically separate — it PRECEDES still-rendered data**, never replaces it (the suspect last-good data must stay on screen as evidence). `stale_banner/1` is a `role="status"` strip above the data (the coverage page already proves this); it is **not** in the `AsyncResult` switch.
- **D-15:** **Per-state spec (role / icon-shape / heading / next-action microcopy):**
  - empty/first-run → `empty_state variant="never"`, `role=status`, history icon — "No audit history yet" / "Run `mix threadline.gen.triggers`, migrate, then make a change."
  - loading → `loading_state/1`, `role=status` + `aria-busy`, spinner + **text node** — "Loading audit changes…" (must always resolve to a terminal state).
  - error → `error_state/1`, `role=alert` + focus a `tabindex=-1` heading — "Could not load this timeline" / retry + check logs.
  - stale → `stale_banner/1`, `role=status`, refresh/warning shape — "Couldn't refresh — showing last known data from <timestamp>. Retry."
  - permission → `empty_state variant="permission"`, `role=alert` + focus rescue, lock/shield — "You don't have access to this audit data" / "needs `audit:read` … the data exists."
  - no-data → `empty_state variant="no_data"`, `role=status`, funnel — "No changes match these filters" / "Clear the filter or widen the time range."
  - unavailable → `empty_state variant="unavailable"`, `role=alert` if down / `role=status` if expected, cause-split icon — **down**: "temporarily unavailable, retry"; **redacted**: "withheld by policy — the record exists"; **pruned**: "removed under retention on <date>". **All three say: NOT a permissions issue.**
- **D-16:** **The three load-bearing forensic distinctions** are enforced in copy and must never collapse: permission = *"exists, you can't see it"* (cite `audit:read`); no-data = *"exists, your filter excluded it"* (widen); unavailable = *"NOT a permissions issue — down/redacted/pruned"*. This is the entire reason DATA-03 exists.
- **D-17:** **Dispatch via `assign_async` / `<.async_result>`** (idiomatic). Loading/failed/ok map cleanly, BUT the page author must branch **ok-empty into `empty` (first-run) vs `no_data` (filters active)** — `AsyncResult` can't make that call — and branch `:failed` reason into `permission` / `unavailable` / generic `error`. Preserve the server's typed reason (`:unauthorized`, `:source_down`, …) all the way to the view; don't let it collapse to "something went wrong." No-color-alone via distinct icon **shape** per state.

### DATA-04 — Row/bulk actions + destructive confirmation
- **D-18:** **Per-row kebab (`dropdown/1`) is the default placement.** Reuses the existing `role=menu`/`aria-haspopup`/CSP-proof component; touch-friendly; keyboard-operable. **Collapse to a single inline `button/1` only when a row has exactly one safe (T1) action.** Destructive items render **last, after a `divider/1`**, with a non-color-alone danger cue (icon/label + `tl-button--danger`). Retires the `tl-table--actionable` class-soup into a structured `:action` slot. Hover-reveal rejected (dies on touch).
- **D-19:** **No bulk multi-select on this surface.** The real jobs are per-object or policy-scoped (redact one value, prune per policy, export a slice); bulk select-all over irreversible redaction/prune is the worst possible blast radius. Mass prune already belongs to the deliberate T2 apply-policy → background pruner flow. A future additive "Export all N matching" can be added explicitly later — never bulk redact/prune.
- **D-20:** **Severity → confirmation tier rule:**
  - **T1 direct** (reversible/additive: generate export, evidence ops) → plain `phx-click` + `phx-disable-with` + success toast, no modal.
  - **T2 confirm modal** (reversible-but-wide: apply/activate retention policy) → `modal/1` naming the object + stating the consequence; **Cancel is `focus_first`**; the danger button label describes the consequence ("Activate — prunes records older than 90 days"), not "Continue".
  - **T3 type-to-confirm** (irreversible: **redact** an audit value, **prune now**) → `modal/1` + `<form phx-submit>`; operator types the object's **own variable identifier** (change id / policy name) — never a constant string like "DELETE" (a constant degenerates into ritual-without-thought).
- **D-21:** **T3 server-side enforcement is the load-bearing fix** (today's prune is client-only `data-confirm` with no server check — delete it). Every irreversible `handle_event`, independent of any client signal, must: (1) re-fetch the **canonical** token from the DB at action time and `Plug.Crypto.secure_compare` it against the typed value (never ship the token to the client to compare client-side); (2) re-check **authorization** in the event (`phx-value-id` is an untrusted claim, not a grant) and scope-filter the context query so a forged id fails closed; (3) **audit the destructive action itself** as an `AuditAction` (domain §9.3.4); (4) default path is refusal — fail closed on every mismatch. This is "correct by default / fail-closed," a stated Threadline value.

### DATA-02 — Claude's Discretion (not selected for discussion)
- **D-22:** Charts/metrics + no-color-alone + time/timezone handled at discretion: render time as **relative + absolute UTC** via the existing `presentation.ex` helpers (`human_time/2`, `exact_time/1`, `checked_label/1`) wrapped in semantic `<time datetime=…>` with the full ISO in `title` and timezone made explicit (UTC is the canonical audit truth). Metrics stay as `stat_tile`s; any chart (e.g. coverage %) is hand-rolled **inline SVG or CSS bar** — no chart library (zero-dep invariant) — and encodes meaning with label + shape/pattern, never color alone. Follow the brand no-color-alone rule and plainspoken voice.

### Claude's Discretion (cross-cutting)
- Exact component names (`tl_ref` vs `ref` vs `copyable`), the precise `kv`/`data_table` slot APIs, new `--tl-*` token names, icon glyph choices (reuse the `Icon` registry; add only what's missing — eye-off for redacted, plug/cloud-off for source-down), and component file location — match the existing `ui.ex` BEM + `--tl-*` idioms and the 173/174/175 conventions.

### Folded Todos
- **`coverage-schema-card-declutter` / "Coverage 'schema: public' card de-clutter"** — was tracked across 173/174 CONTEXTs; realized here as **D-11/D-12** (flatten the coverage command shell, "one card boundary per logical unit", system-wide nesting sweep + regression test). This is the named DATA-05 target.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — DATA-01..DATA-05; v1.37 invariants (no public API, zero new runtime deps, inline CSS, CSP-proof, WCAG 2.2 AA, mobile-first 320–1440, brand-token parity).
- `.planning/ROADMAP.md` §"Phase 176" — goal + 5 success criteria.

### Prior phase context (the convention this phase extends)
- `.planning/phases/175-navigation-app-shell-runtime-theme-picker/175-CONTEXT.md` — CSP-hardening thread, `page_header`/`pager` components, no-color-alone active-state pattern, embed-scripts posture.
- `.planning/phases/174-form-components/174-CONTEXT.md` — explicit `name/value/errors` props (no `to_form` coupling), native-HTML-first, `phoenix_html` stays optional.
- `.planning/phases/173-primitive-components-extract-audit-each-in-isolation/173-CONTEXT.md` — single `UI` module, strict `attr`/`slot`, internal-only (`@doc false`), stress-route isolation audit pattern.

### Domain & OSS DNA
- `prompts/audit-lib-domain-model-reference.md` — domain hierarchy (AuditTransaction → AuditChange; Actor/Correlation indices) the KV/diff/breadcrumb surfaces mirror; §5.7/§5.8 (authz for viewing, row-level access) ground the permission/redaction/unavailable states; §9.3/§9.4 establish redaction/prune irreversibility for the T3 tier.
- `prompts/threadline-elixir-oss-dna.md` — quality bar: contracts, deterministic tests, explicit composition, fail-closed, build-for-real-demand, no-public-API discipline.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem framing for the data-state trust requirements.

### Brand (CURRENT — prefer over `prompts/Threadline Brand Book.txt`)
- `brandbook/brand-book.md` — voice/microcopy (plainspoken, sentence case, no "!"), color semantics + **non-color-alone rule (~L297)**, button hierarchy (~L346), **cards rule (~L348: not page sections inside cards)**, microcopy (~L405-419), focus/hover, motion, 8px radius cap.
- `brandbook/tokens.json`, `brandbook/tokens.css` — the `--tl-*` token contract (dark + light/system lanes) all new component CSS must use.

### Ecosystem best-practice research
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — `assign_async`/`<.async_result>`, streams (`phx-update="stream"`), function-component + `attr`/`slot` idioms, server-side event validation.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md`, `.../ecto-best-practices-deep-research.md` — scope-filtered queries, fail-closed authorization.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (extend, don't rebuild)
- `lib/threadline/operator_surface/ui.ex` — `button/1` (L20), `divider/1` (L121), `spinner/1` (L131), `card/1` (L166), `page_header/1` (L202), `pager/1` (L282), `stat_tile/1` (L341), `empty_state/1` (L358, **has `variant`**), `error_state/1` (L377, thin wrapper), `alert/1` (L109), `modal/1` (L406, `focus_first`/`pop_focus`), `dropdown/1` (L629, `role=menu`/`aria-haspopup`). Add `kv/1`, `data_table/1`, `loading_state/1`, `stale_banner/1` + 3 `empty_state` variants here.
- `lib/threadline/operator_surface/presentation.ex` — `human_time/2`, `exact_time/1`, `checked_label/1` (time); `secondary_ref/2` (L229, → `ref/2` w/ `full`), `value_token/1` (L239, must gain truncation), `truncate_middle/2` (L65, add `:tail_min`).
- `lib/threadline/operator_surface/script.ex` — embedded copy helper, `enabled?/0`, `operator_surface_embed_scripts` flag (CSP escape hatch). Delegated `[data-tl-copy]` listener survives LiveView patches (`__tlCopyBound` guard).
- `lib/threadline/operator_surface/components/icon.ex` — icon registry (reuse `:history`, `:shield`, `:filter_x`, `:archive`, `:trash`, `:refresh`; add eye-off / source-down if missing).
- `lib/threadline/operator_surface/live/row_history_component.ex` — canonical `tl-kv` `<dl>` (L174) — source for `UI.kv` extraction.

### Established Patterns
- 173/174/175: extract class-soup → internal `UI` function components, `@doc false`, strict `attr`/`slot`, `--tl-*`-token-driven, audited in isolation on the `/audit/__stress` route (`stress_live.ex`, `stress_router.ex`, `stress_fixtures.ex`) across viewports + interaction states.
- `data-status` stripe convention (CSS already maps `data-status` → left stripe — zero new CSS for `row_status`).
- CSP-proof shell: no inline `on*=` handlers; copy via delegated listener; modals/menus via `Phoenix.LiveView.JS`.

### Integration Points
- 11 LiveViews under `lib/.../live/` consume the new components: coverage, retention_history, policy_redaction, transaction, actor, row_history(+component), timeline, evidence, export_status, start.
- `style.ex` (~3935 lines) holds all CSS: `.tl-secondary-ref` (~2490, remove ellipsis), `.tl-copy` (~3152), `tl-kv` (~3228), responsive collapse (~3488) + desktop restore (~3834), `tl-coverage-command__*` (~3336, delete after flatten), `tl-empty--*` state CSS.
- Server side: `handle_event` for redact (policy_redaction) and prune (retention_history L37) — add `current_scope` re-fetch + `secure_compare` + authz + audit-the-action.

</code_context>

<specifics>
## Specific Ideas

- Forensic non-negotiable: an operator must **always** recover the exact full value (copy *or* zero-JS select-all) — truncation is purely visual and must never lose the discriminating tail.
- Trust non-negotiable: "you can't see it" (permission) vs "nothing matched" (no-data) vs "down/redacted/pruned" (unavailable) must be unmistakable in copy and icon shape.
- Cross-ecosystem models to emulate: GitHub SHA copy (copy ≠ displayed), Stripe/Datadog/Honeycomb correlation-id copy + "data as of <timestamp>", GitHub/Rancher type-the-real-object-name to delete. Anti-patterns to avoid: copying the truncated string, end-ellipsis on tail-entropy ids, constant-string confirms, destructive adjacent to benign, k8s-dashboard "nothing to display" collapsing empty/permission/error.
- Looks right in dark/light/system with no hover/focus weirdness; reduced-motion-safe; plainspoken brand voice, sentence case, no exclamation.

</specifics>

<deferred>
## Deferred Ideas

- **Sticky-first-column / horizontal-scroll table fallback** — not needed by any current table (≤5 cols); build only when a genuinely wide table demands it (OSS-DNA build-for-real-demand). → future, if volume demands.
- **Bulk "Export all N matching"** — the only additive/reversible bulk candidate; add explicitly with a quantified affordance if a real operator need surfaces. → future phase, never bulk redact/prune.
- **Live-ticking relative timestamps** — would require JS; out of scope (server-rendered relative + absolute is sufficient and CSP-clean).

</deferred>

---

*Phase: 176-Data display & operator patterns*
*Context gathered: 2026-06-17*
