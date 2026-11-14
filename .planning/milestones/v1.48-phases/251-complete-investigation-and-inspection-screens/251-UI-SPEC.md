---
phase: "251"
slug: "complete-investigation-and-inspection-screens"
status: approved
reviewed_at: "2026-11-12"
shadcn_initialized: false
preset: none
created: "2026-11-12"
---

# Phase 251 — UI Design Contract

> Visual and interaction contract for the remaining investigation and read-only inspection jobs. Phase 250's approved Admin foundation is authoritative; this phase adds only the navigation, snapshot, selected-schema, redaction, and evidence states listed below.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — repository-owned Phoenix LiveView/HEEx components and scoped CSS tokens |
| Preset | Not applicable; no shadcn preset |
| Component library | Custom Phoenix components (`Phoenix.Component`); no third-party UI component library |
| Icon library | `Threadline.OperatorSurface.Components.Icon` (inline SVG) |
| Font | Threadline-private aliases for Familjen Grotesk, Geist, and IBM Plex Mono; local WOFF2 only |

Continue to use `.threadline-ui` CSS variables and `brand/brand.json` as the runtime token sources. Use only the supplied paired SVG artwork and preserve its geometry, colors, and minimum sizes. Phoenix LiveView/HEEx is the approved implementation; do not introduce React, Fablebook, a registry, an adapter, or a dependency.

---

## Component Inventory

Enumerated by `rg --files lib/threadline/operator_surface/components lib/threadline/operator_surface/ui | wc -l` — 10 components — `threadline@1.1.0` — 2026-11-12.

Cross-check: `find lib/threadline/operator_surface/components lib/threadline/operator_surface/ui -type f -name '*.ex' | wc -l` — 10 source files. No mismatch.

This is a non-exhaustive inventory of project-owned modules, not a closed allowlist.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Icon | `Threadline.OperatorSurface.Components.Icon` | Existing semantic inline icons for links, copy controls, and state feedback. |
| Logo | `Threadline.OperatorSurface.Components.Logo` | Supplied compile-time light/dark lockup; accessible home link name is `Threadline Admin home`. |
| SurfaceHeader | `Threadline.OperatorSurface.Components.SurfaceHeader` | Shell, route navigation, and native immediate theme selection. |
| UnsupportedView | `Threadline.OperatorSurface.Components.UnsupportedView` | Existing safe fallback for unsupported or unavailable feature routes. |
| Actions | `Threadline.OperatorSurface.UI.Actions` | Existing action links and controls; keep labels visible and specific. |
| Data | `Threadline.OperatorSurface.UI.Data` | Existing loading, empty, stale, and unavailable states; preserve typed distinctions. |
| Display | `Threadline.OperatorSurface.UI.Display` | Exact values, timestamps, identifiers, and copy controls. |
| Form | `Threadline.OperatorSurface.UI.Form` | Existing accessible filters, schema controls, and as-of inputs. |
| Overlay | `Threadline.OperatorSurface.UI.Overlay` | Existing drawers and confirmation modal behavior. |
| Page | `Threadline.OperatorSurface.UI.Page` | Existing page/detail headers, shell, and breadcrumbs. |

Route owners outside the inventory directories remain the existing `StartLive`, `TimelineLive`, `ActorLive`, `TransactionLive`, `RowHistoryLive`/`RowHistoryComponent`, `CoverageLive`, `PolicyRedactionLive`, and `EvidenceLive` modules.

---

## Spacing Scale

Keep the approved 8-point rhythm using 4px increments. Preserve existing dense-control geometry; do not introduce new spacing values.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gaps and tight inline alignment. |
| sm | 8px | Compact controls and row-internal spacing. |
| md | 16px | Standard control padding and panel content. |
| lg | 24px | Between related content groups. |
| xl | 32px | Between page sections. |
| 2xl | 48px | Major page breaks. |
| 3xl | 64px | Outer page-level separation. |

Exceptions: retain existing 12px, 20px, and 40px values where dense tables and controls already use them. Keep text controls 40px high and icon-only controls at a 44px minimum hit area.

---

## Typography

Use only the two approved interface weights: 400 regular and 600 semibold. Use the private font aliases and locally served licensed WOFF2 files from Phase 250.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body / control text | 16px Geist | 400 | 1.55 |
| Dense metadata / IDs | 13px Geist or IBM Plex Mono | 400 | 1.4 Geist; 1.5 Mono |
| Label / column label | 12px Geist | 600 | 1.2; 0.12em tracking and uppercase only at this size |
| Page / section heading | 28px Familjen Grotesk | 600 | 1.2; sentence case |

Use tabular numerals for times and counts. Render database table, field, and identifier values in IBM Plex Mono. Keep complete IDs available to assistive technology and copy controls; when the visible value is shortened, middle-elide it without wrapping. Do not use the brand's 32px display token in this dense Admin work. Preserve the host font opt-out and system fallback.

---

## Color

Retain the approved Phase 250 color hierarchy. The dominant ground is about 60% of the page; secondary panels are about 30%; accent is reserved for a few signals and occupies a small actual fraction of the rendered surface.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (about 60%) | Dark: Threadline Black `#0B1020` (62%). Light: Paper `#F7F9FC` (64%). | Page ground; dark remains the default. |
| Secondary (about 30%) | Dark: Graphite `#141B2D` (24%). Light: Card White `#FFFFFF` (22%). | Data rows, cards, and panels; preserve separation from the page ground. |
| Text | Dark: Fog `#D7DEEA`; light: Ink `#0F1728`. | Primary reading and content text. |
| Accent (about 10% maximum) | Dark: Thread Blue `#4F8CFF`; light: Thread Blue Deep `#1557C0`. | Brand links, visible focus, selected state, and the primary action edge only. |
| Dividers | Dark: Slate Line `#23304A`; light: Hairline `#C9D3E2`. | Separate rows and groups; never sole control boundary or text color. |
| Destructive | Dark danger `#FF8585`; light danger `#A33434`. | Existing saved-search deletion confirmation only. |

Accent reserved for: brand links, visible focus rings, selected state, and the primary action edge. Do not use blue as a broad fill or decorative wash. Signal Cyan is reserved for correlation identifiers; Iris remains for selected saved views/code keywords. Stitch Blue `#4781E6` is logo-thread artwork only. Keep operation and Redacted words visible independent of their semantic colors, using the exact Phase 250 pairs. Preserve all eight stable brand contrast IDs and a visible 2px focus ring in the correct theme lane.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary investigation CTA | `Open transaction` on a matching Timeline result. Preserve the specific existing Home actions `Open row history` and `Open the timeline`; schema controls use `Apply schema`, and policy refresh uses `Refresh policy inspection`. |
| Timeline empty state | Heading: `No changes match these filters`. Body: `Try a wider date range or adjust the filters, then apply again.` |
| Coverage empty state | `No tables found in schema {schema} during this inspection. Other schemas were not inspected.` Do not pair this with global all-captured or completeness claims. |
| Redaction empty state | Heading: `No configured policy to compare`. Body: `No configured redaction policies were found for this inspection.` Do not show empty-section “no drift,” “all introspected,” or matching-policy claims when no policy is configured. |
| Evidence empty state | Heading: `No Threadline evidence for this selection`. Keep the existing request-specific next step and distinguish no match from unavailable. |
| Invalid explicit snapshot time | `This snapshot time is invalid. Enter a valid date and time, or clear the field to view the latest snapshot.` Keep the invalid request visibly invalid; do not render latest/current as the requested snapshot. |
| Unsupported Timeline filters | `These Timeline filters are not supported. Update the filters before applying them.` Do not broaden to an unfiltered read. |
| Invalid retained return context | `Some Timeline filters could not be restored. Return to Timeline to choose filters before continuing.` The route remains host-scoped and does not claim that filters survived. |
| Coverage read failure | `Coverage could not be read for schema {schema}. Retry the inspection. No coverage result is confirmed.` Keep same-schema stale data separately labeled with its last successful inspection time. |
| Redaction inspection error | `Policy inspection is unavailable for schema {schema}. Retry the inspection before treating policy as matched.` Do not render raw SQL, database diagnostics, or exception text. |
| Evidence read failure | `Evidence is unavailable for this selection. Retry the read; no empty result is implied.` Keep the existing visible `Retry` action. |
| Saved-search delete confirmation | Existing modal: `Delete saved search “{name}”? This removes it from your saved searches.` Actions: `Keep saved search` and `Delete search`. Preserve the explicit confirmation step. |
| Destructive actions | Existing saved-search deletion only; preserve the modal above. No new destructive operation is in scope. |

For every state, keep `not audited`, `expected gap`, `not inspected`, host-denied, feature-unavailable, and read-unavailable as distinct facts. Redaction uses `Left out` for excluded/not-recorded fields and `Redacted` for a stored replacement; show the replacement value. Use calm, direct copy and avoid claims of completeness, authenticated provenance, tamper-proofing, immutability, or compliance.

---

## Phase Interaction Contract

### Navigation and history jobs

1. Keep Phase 250's canonical URL-backed valid filters, explicit `from=` unconstrained intent, path/table identity, direct-entry defaults, valid local return URLs, and host-supplied scope. Host scope never comes from query parameters. A bare direct Timeline visit's existing default window remains distinct from a deliberate unconstrained Apply.
2. Apply unsupported-only Timeline query input and malformed saved-view filters at the existing UI/saved-view boundaries. Keep `FilterParams.parse/1`'s shared unknown-key-dropping compatibility and atom safety unchanged. A UI/saved-view filter set that cannot be validated gets visible correction copy and must not turn into an unfiltered read. Revalidate stored values before canonicalization or Apply.
3. When a retained return context is invalid, use the existing safe bare-Timeline recovery and show the context-loss message above. Keep the valid context byte-for-byte semantically exact. An unknown origin never adds authority or scope.
4. Keep Home lookup limited to the existing record and correlation jobs. Keep actor/correlation pivots on their supported routes. Preserve nonhuman `ActorRef` kinds; absent/anonymous actors have no person link. Do not add actor lookup, a new API, or a composite-key destination.
5. Missing or blank `as_of` keeps its current latest/default behavior. A malformed nonempty `as_of` has an explicit invalid state on both standalone row history and transaction-origin history. Clearing the existing date/time field keeps the blank/default intent. Valid offset/UTC timestamps retain their exact meaning. Keep deleted-record and before-audit-horizon results distinct and preserve the complete record identity and validated return context.
6. Keep the established `Open transaction`, `Open row history`, `Copy row id`, and existing close/return actions and keyboard behavior. Copying an identifier uses the exact full value, keeps focus on its control, and uses the existing truthful pending/success/failure feedback; this phase does not prove native clipboard permissions or contents.

### Selected-schema inspection jobs

1. **Coverage:** Every successful result, empty state, badge, and remediation refers to the selected schema and current inspection. An empty result or only expected gaps never says all tables are captured. A missing-trigger row says it is not audited; expected gaps remain a separate state. Explicitly say other schemas were not inspected. Keep a successful custom-schema refresh and the shared header aligned to the same selected/current snapshot, or show a truthful unavailable/not-inspected state.
2. **Coverage errors:** Keep host denial as the existing auth-hook halt/redirect, not an empty page. Keep feature unavailable as the existing unsupported-feature view, selected-schema read failure as unavailable, same-schema last-good rows as stale with their timestamp, and changed-schema failure from reusing rows from the old schema. Keep invalid-schema remediation within the supported schema picker.
3. **Redaction:** Compare configured policy with the currently deployed trigger definition only. Show the selected schema, configured and deployed source meaning, and successful inspection time. Zero configured policies mean there is no policy to compare, never an all-clear. Show `Left out` versus `Redacted` and the configured replacement. Keep missing-trigger drift, unreadable deployed policy, unavailable read, and feature-unavailable states distinct. This page does not establish how historical rows or exports were redacted.
4. **Evidence:** Keep subject/reference scope, latest projection, append-only snapshot history, no-match, and unavailable states as they are. Label `recorded_at` as the snapshot's recorded time. Add only a bounded, view-private `Recorded provenance` summary: identify the known Threadline writer/subject-entrypoint pair only on an exact match; for custom or unknown metadata show that recorded provenance is present without rendering its values. State that this is caller-overridable recorded metadata, not verified or authenticated identity. Never render arbitrary provenance/detail maps, actor IDs, or canary values. Do not label Evidence as row history or overall capture completeness.

### Layout, focus, and density

Keep the shared shell quiet and let the selected facts, result rows, policy comparison, or evidence records lead. Filters and schema selectors remain visibly subordinate. Use the existing UI Page/Data/Display/Form/Actions/Overlay compositions; do not add an alternate page shell or generic state engine. Keep operation, availability, and scope meaning in visible text as well as color. Preserve native form/LiveView behavior, visible 2px focus, keyboard order, and actual focus return through the existing controls. Error and recovery copy remains adjacent to the affected data or form.

## UI Considerations

Applicable state considerations resolved by the installed UI probe: 48 resolved (explicit), 0 backstop, 0 unresolved, 0 unclassified. These are planning criteria, not runtime verification results.

| Element | Category | Status | Verification | Resolution |
|---------|----------|--------|--------------|------------|
| N1 | empty | resolved | explicit | An empty supported Timeline query preserves explicit unconstrained from= intent, while a bare visit retains its default window; empty saved-view lists remain usable. |
| N1 | loading | resolved | explicit | During existing filter or saved-view submission, committed results are not relabeled as pending input; preserve existing native pending and typed read feedback without inventing an async backend. |
| N1 | error | resolved | explicit | Unsupported-only UI queries and malformed saved filters show correction copy before a broader read; keep shared parser allowlist compatibility, safe deletion recovery and host scope intact. |
| N1 | populated | resolved | explicit | A valid saved or direct query restores its supported values and result identity through apply, reload, back/forward and UI return on the actual mounted host route. |
| N1 | partial | resolved | explicit | Missing optional predicates remain absent, valid surviving predicates stay exact, and discarded invalid retained context is explicitly disclosed before safe recovery. |
| N1 | overflow | resolved | explicit | Filter controls, saved-view names and results remain reachable within existing responsive form/table boundaries without page overflow or hidden actions. |
| N1 | zero-one-many | resolved | explicit | Zero, one and many saved views or Timeline results retain accurate empty/count and row semantics without implying one action per row change. |
| N1 | long-text | resolved | explicit | Long allowed filter and saved-view values retain their full submitted/stored meaning; accessible names and correction text wrap without clipping. |
| N2 | empty | resolved | explicit | Blank existing Home record/correlation lookups show their supported validation or empty state; absent or anonymous actor information never fabricates a person link. |
| N2 | loading | resolved | explicit | Home navigation and actor/correlation reads retain their existing connected/pending behavior without invented optimistic records or a new loading lifecycle. |
| N2 | error | resolved | explicit | Invalid Home lookup identity or unavailable actor/correlation reads retain safe scoped recovery and do not navigate to invented actor or composite-key destinations. |
| N2 | populated | resolved | explicit | Existing Home record/correlation lookups and identifiable nonhuman ActorRef pivots reach the intended scoped history with exact kind/id and query context. |
| N2 | partial | resolved | explicit | Absent optional actor/context values retain honest unknown/anonymous distinctions without invented identity or authenticated-person claims. |
| N2 | overflow | resolved | explicit | Home lookup controls, actor/correlation links and resulting history remain reachable at narrow widths without losing their full accessible labels. |
| N2 | zero-one-many | resolved | explicit | Actor/correlation result collections preserve correct zero, one and many-row states and existing navigation without conflating actions, requests and database transactions. |
| N2 | long-text | resolved | explicit | Long supported record/correlation/ActorRef values keep their complete route/copy identity despite visual middle elision; no new actor lookup is introduced. |
| N3 | empty | resolved | explicit | Missing or blank as_of retains latest/default intent, and genuinely empty history remains distinct from unavailable data and a valid before-audit-horizon snapshot. |
| N3 | loading | resolved | explicit | History snapshot rendering retains its existing typed loading/connected boundary without replacing missing data with an invented snapshot or new asynchronous backend. |
| N3 | error | resolved | explicit | Malformed nonempty as_of shows an invalid-snapshot state in both history routes and never silently renders latest as the requested snapshot; clearing the field retains blank/default intent. |
| N3 | populated | resolved | explicit | Valid UTC/offset as_of renders the exact supported record snapshot, full record ID and current validated return context through standalone and transaction-origin history. |
| N3 | partial | resolved | explicit | Deleted-record, before-audit-horizon, null, omitted, left-out, redacted and unavailable snapshot meanings stay distinct and do not imply that a row never existed. |
| N3 | overflow | resolved | explicit | History titles and controls clear the actual app bar, long values stay within the drawer/table scroll boundary, and close/return actions remain reachable. |
| N3 | zero-one-many | resolved | explicit | History with zero, one or multiple captured changes preserves accurate timeline order/count and snapshot selection without new composite-key navigation. |
| N3 | long-text | resolved | explicit | Long field/table/value text remains readable; visual ID elision never changes full accessible/copy values or exact validated return predicates. |
| I1 | empty | resolved | explicit | An empty selected-schema read uses the scoped Coverage copy and explicitly leaves other schemas uninspected; zero or expected-only rows never imply global completeness. |
| I1 | loading | resolved | explicit | Existing schema Apply/refresh feedback remains truthful; last successful facts retain their actual schema/time rather than being presented as a completed new inspection. |
| I1 | error | resolved | explicit | Invalid schema, host denial, feature unavailability, first-read failure and changed-schema failure remain distinct; a failed new-schema read never reuses the prior schema result as current. |
| I1 | populated | resolved | explicit | Coverage rows, counts, remediation and shared header describe the same successful current selected-schema snapshot, including after manual refresh. |
| I1 | partial | resolved | explicit | Expected gaps stay separate from missing/incomplete capture, same-schema last-good results are marked stale with their actual inspection time, and other schemas remain not inspected. |
| I1 | overflow | resolved | explicit | Schema selection, status text and schema-specific remediation/copy controls remain within the responsive page and retain keyboard reachability. |
| I1 | zero-one-many | resolved | explicit | Coverage zero, one and many-table summaries accurately reflect the actual inspected scope, with no global all-captured claim for empty or expected-only results. |
| I1 | long-text | resolved | explicit | Long schema/table names and generated remediation remain readable and copy-complete without clipping, raw error disclosure or an all-schema default. |
| I2 | empty | resolved | explicit | All zero-configured-policy sections consistently use the Redaction empty meaning; none simultaneously claims no drift, full introspection or matched deployment. |
| I2 | loading | resolved | explicit | Existing policy refresh feedback identifies an in-progress inspection without claiming that new configured/deployed results or inspection time are already current. |
| I2 | error | resolved | explicit | Missing deployed trigger remains drift, unreadable definition remains could-not-inspect, and unexpected read/schema failures use safe unavailable copy with recovery and no raw diagnostics. |
| I2 | populated | resolved | explicit | Configured and deployed columns show the selected schema, actual successful inspection time/source and clear Left out versus Redacted/replacement meanings. |
| I2 | partial | resolved | explicit | Unreadable or mismatched deployed policy stays distinct from a match and from empty configuration; stale facts never masquerade as a successful current inspection. |
| I2 | overflow | resolved | explicit | Policy comparison, schema controls and refresh/recovery actions remain readable and reachable in existing responsive table/control boundaries. |
| I2 | zero-one-many | resolved | explicit | Zero, one and many policy rows retain accurate scoped count/layout semantics without inferring historical-row or downstream-export correctness. |
| I2 | long-text | resolved | explicit | Long schema/table/field and replacement labels wrap safely; raw trigger SQL, exception diagnostics and stored-value canaries remain undisplayed. |
| I3 | empty | resolved | explicit | No-match Evidence uses the selection-specific empty state rather than no-activity, denial, failed read or overall capture-completeness claims. |
| I3 | loading | resolved | explicit | Existing Evidence selection/read feedback remains truthful and does not label pending or stale content as a completed new snapshot read. |
| I3 | error | resolved | explicit | Unavailable reads retain subject/reference and supported Retry recovery without turning an outage into an empty result; host denial and disabled capability remain separate. |
| I3 | populated | resolved | explicit | Evidence retains subject/reference, latest projection versus append-only history, verdict and explicitly labeled snapshot recording time with bounded recorded provenance. |
| I3 | partial | resolved | explicit | Only the exact expected writer/subject-entrypoint pair is recognized as recorded metadata; custom/unknown provenance is summarized without values or authenticated-origin claims. |
| I3 | overflow | resolved | explicit | Subject/reference selection, record cards, copy and Retry controls remain within responsive boundaries with full accessible reference values. |
| I3 | zero-one-many | resolved | explicit | Zero, one and many operational snapshots keep accurate latest/history and verdict meaning without relabeling them as row record history. |
| I3 | long-text | resolved | explicit | Long references remain complete in copy/accessibility while arbitrary provenance/detail maps, actor IDs and canary values remain hidden regardless of length. |

---

## Proof Contract

Keep evidence tied to the actual changed route, source, scenario, served assets, fixture/data identity, clock, theme, browser, viewport, and exact nonzero first-attempt case set. Each changed visible state needs a small matched before/after capture at its real route/scenario plus behavior and accessibility proof. Reuse Phase 250 material only where the source and claim are unchanged; its #4521 journey is not proof for the remaining Phase 251 jobs.

| Claim | Evidence boundary and existing owners |
|-------|--------------------------------------|
| Static copy, composition, state labels, hidden metadata, and stable locator/inventory mapping | Current HEEx source plus existing rendered-output/source-surface/route inventory contracts. Update `operator-journey-inventory.json`, `route-inventory.json`, `source-surface-checklist.json`, semantic locators, signatures, and negative controls together when their markup changes. Storybook proves static composition only. |
| URL filters, saved-view validation, Home/actor pivots, host scope, direct/reload/back/return routes, and invalid `as_of` on both history routes | Existing ExUnit route/component owners: `filter_params_test.exs`, `timeline_live_test.exs`, `start_live_test.exs`, `actor_live_test.exs`, `transaction_live_test.exs`, `row_history_live_test.exs`, and `row_history_component_test.exs`; mounted browser owners: `operator-earned-flows.spec.ts`, `operator-route-states.spec.ts`, and `operator-timeline-investigation-flow.spec.ts`. Add negative controls for unknown-only filters, malformed saved/retained context, absent/anonymous actor links, and invalid nonempty `as_of`. |
| Selected-schema Coverage states and current header/badge; redaction source/time/error semantics; bounded Evidence projection and privacy | Existing `coverage_live_test.exs`, `policy_redaction_live_test.exs`, and `evidence_live_test.exs`; mounted owners `operator-coverage-readiness.spec.ts`, `operator-route-states.spec.ts`, and `operator-features.spec.ts`. Keep empty/expected-only, same-schema stale, changed-schema failure, missing-trigger versus unreadable definition, safe unexpected error, no-match versus outage, exact provenance pair, and hidden-map/actor/detail canaries separate. |
| Rendered layout, keyboard path, and visible recovery at changed boundaries | Small route-specific matched captures plus behavior/accessibility assertions on the named browser owners. Keep current source and served asset identity tied to both halves. No focus theft, native clipboard/permission claim, broad zoom/error-pixel matrix, or new browser runner; Phase 253 retains those broader checks. |

These are proof requirements, not claims that tests or browser checks have run during UI research. Static rendering does not establish mounted authorization or a database read; a source receipt does not establish browser accessibility or visual layout.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None; custom Phoenix components only | None | Not applicable — no third-party component registry or block is used. |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: FLAG — existing generic Retry refinement remains deferred to Phase 253
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** Independent UI checker approved all seven dimensions on 2026-11-12, including bounded final confirmation of the Coverage empty copy, retained-context notice, and actual 48-item explicit UI probe writeback. Existing generic Retry copy remains a nonblocking Phase 253 refinement. This approves the planning contract, not runtime behavior or pixels.

---

## Sources

- `.planning/REQUIREMENTS.md` — ADM-15/18/19/20/21/22 and phase boundary.
- `.planning/ROADMAP.md` and `.planning/STATE.md` — current Phase 251 goal, requirements, and order.
- `.planning/phases/251-complete-investigation-and-inspection-screens/251-CONTEXT.md` and `251-RESEARCH.md` — locked decisions D-01–D-09 and accepted implementation/evidence guidance.
- `.planning/research/2026-11-12-phase251/navigation.md`, `inspection.md`, and `adversarial.md` — current-source findings and proof owners; these are research, not test receipts.
- `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-UI-SPEC.md` — accepted visual tokens, shared components, accessibility and whole-journey foundation.
- `brand/BRAND.md`, `brand/brand.json`, and `brand/assets/README.md` — approved identity, semantic color and type roles, fonts, and supplied artwork.
- `lib/threadline/operator_surface/style/01_tokens.css` and `lib/threadline/operator_surface/ui/` — current runtime tokens and shared component owners.
- Existing route owners: `lib/threadline/operator_surface/live/` — actual Timeline, history, Coverage, Redaction, and Evidence copy/actions/state boundaries.

## Snapshot recovery clarification during Plan02

A malformed nonempty time renders the approved invalid-time alert without a substituted snapshot. Since a native datetime-local field cannot display malformed text, the alert also offers “View latest snapshot” through the existing history route with as_of removed. This is explicit default selection using existing navigation, not a new route/API/query key. Valid field clearing has the same blank intent; Close, retained filters, scope and path identity are preserved. Independent phase-wide UI review confirms the final state.
