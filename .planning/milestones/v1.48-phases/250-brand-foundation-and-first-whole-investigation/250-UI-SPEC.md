---
phase: "250"
slug: "brand-foundation-and-first-whole-investigation"
status: approved
shadcn_initialized: false
preset: none
created: "2026-11-12"
---

# Phase 250 — UI Design Contract

> Visual and interaction contract for the bounded Threadline Admin brand foundation and one ordinary Timeline → transaction → record-history investigation.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — repository-owned Phoenix LiveView/HEEx components and scoped CSS tokens |
| Preset | Not applicable; no shadcn preset |
| Component library | Custom Phoenix components (`Phoenix.Component`); no third-party UI component library |
| Icon library | `Threadline.OperatorSurface.Components.Icon` (inline SVG) |
| Font | Threadline-private aliases for Familjen Grotesk, Geist, and IBM Plex Mono; local WOFF2 only |

Runtime design values remain owned by the scoped `.threadline-ui` CSS variables and are checked against `brand/brand.json`. Do not add a parallel runtime token registry. Use the supplied paired SVG files at compile time and preserve their geometry and colors.

## Component Inventory

Enumerated by `rg --files lib/threadline/operator_surface/components lib/threadline/operator_surface/ui | wc -l` — 10 components — `threadline@1.1.0` — 2026-11-12.

Cross-check: `find lib/threadline/operator_surface/components lib/threadline/operator_surface/ui -type f -name '*.ex' | wc -l` — 10 source files.

This is a non-exhaustive inventory of project-owned modules, not a closed allowlist.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Icon | `Threadline.OperatorSurface.Components.Icon` | Existing semantic inline icons for links, copy controls, and state feedback. |
| Logo | `Threadline.OperatorSurface.Components.Logo` | Supplied compile-time light/dark lockup; accessible home link name is `Threadline Admin home`. |
| SurfaceHeader | `Threadline.OperatorSurface.Components.SurfaceHeader` | Shell, route navigation, and native immediate theme selection. |
| UnsupportedView | `Threadline.OperatorSurface.Components.UnsupportedView` | Existing safe fallback view for unsupported surface routes. |
| Actions | `Threadline.OperatorSurface.UI.Actions` | Existing action links and controls; keep labels visible and specific. |
| Data | `Threadline.OperatorSurface.UI.Data` | Existing loading, empty, and error states; use their typed distinctions. |
| Display | `Threadline.OperatorSurface.UI.Display` | Existing exact-value, timestamp, and identifier presentation/copy controls. |
| Form | `Threadline.OperatorSurface.UI.Form` | Existing accessible filter and as-of inputs. |
| Overlay | `Threadline.OperatorSurface.UI.Overlay` | Existing drawer behavior for row history. |
| Page | `Threadline.OperatorSurface.UI.Page` | Existing page/detail headers and breadcrumbs for Timeline and Transaction. |

Relevant route owners outside those two inventoried directories remain `Threadline.OperatorSurface.Live.TimelineLive`, `TransactionLive`, `RowHistoryLive`, and `RowHistoryComponent`.

## Spacing Scale

Use the 8-point rhythm with declared values in 4px increments:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gaps and tight inline alignment. |
| sm | 8px | Compact control and row-internal spacing. |
| md | 16px | Standard control padding and panel content. |
| lg | 24px | Between related content groups. |
| xl | 32px | Between page sections. |
| 2xl | 48px | Major page breaks. |
| 3xl | 64px | Outer page-level separation. |

Exceptions: preserve existing 12px, 20px, and 40px tokens only where existing dense-table and control geometry already uses them; do not introduce new spacing values. Keep existing 40px text-control height. Icon-only controls retain a 44px minimum hit area.

## Typography

Use only 400 and 600 for the interface text contract. Use private font-family aliases so embedded `@font-face` names do not collide with host fonts. Serve the approved four WOFF2 files locally and include all three OFL texts; do not fetch fonts remotely. Preserve `operator_surface_embed_fonts`, its default, and `false` → no embedded faces with host-system fallback.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body / control text | 16px Geist | 400 | 1.55 |
| Dense metadata / IDs | 13px Geist or IBM Plex Mono | 400 | 1.4 (Geist); 1.5 (Mono) |
| Label / column label | 12px Geist | 600 | 1.2; 0.12em tracking, uppercase only at this size |
| Admin page / section heading | 28px Familjen Grotesk | 600 | 1.2; sentence case |

Do not use the 56px brand display size inside this dense Admin slice. Use tabular numerals for times and counts. Every identifier, database table name, and field name uses IBM Plex Mono; visually shorten long IDs in the middle only, keep the full value available to assistive technology and the copy control, and never wrap an ID. The supplied Plex Mono 500 face remains part of the exact asset set; neutral IDs in this flow render at 400 so emphasis never changes their identity. Retain the existing 12px label and 13px dense metadata/identifier roles as intentional brand-approved compatibility and legibility sizes; do not broaden this slice into a blanket type-size increase.

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant surface | Dark: Threadline Black `#0B1020` (62%). Light: Paper `#F7F9FC` (64%). | Page ground; dark remains the default. |
| Secondary surface | Dark: Graphite `#141B2D` (24%). Light: Card White `#FFFFFF` (22%). | Data rows, cards, and panels. Keep page-ground and panel roles distinct. |
| Text | Dark: Fog `#D7DEEA` (8%). Light: Ink `#0F1728` (8%). | Primary reading and content text. |
| Accent / link | Dark: Thread Blue `#4F8CFF` (3%). Light: Thread Blue Deep `#1557C0` (3%). | Links, focus rings, selected state, and the primary action edge only. Do not use as the primary action fill. |
| Dividers | Dark: Slate Line `#23304A` (3%). Light: Hairline `#C9D3E2` (3%). | Divide groups and rows; never use as text or the sole control boundary. |
| Destructive | No destructive user action is in this read-only phase. | The `Delete` operation is a historical operation label with its own semantic colors, not a destructive control. |

Accent reserved for: brand links, visible focus rings, selected state, and the primary action edge only. Do not use Thread Blue / Thread Blue Deep as a broad fill or decorative wash. Signal Cyan is reserved for correlation IDs (`#0B6F67` light, `#4EDFD1` dark). Iris is reserved for selected saved views and code keywords and is not used as a generic status. Do not use Stitch Blue `#4781E6` for UI text, links, or controls; it is fixed logo-thread artwork only. Light control edges use Control Edge `#76849F`, dark control edges use Steel `#73819C`; Hairline and Slate Line divide content and never serve as the only control boundary.

Preserve the eight stable contrast IDs from `brand/brand.json` in both lanes:

| ID | Light text on ground | Dark text on ground | Minimum |
|----|----------------------|--------------------|---------|
| `body` | `#0F1728` on `#F7F9FC` | `#D7DEEA` on `#0B1020` | 4.5:1 |
| `descriptor` | `#56647E` on `#F7F9FC` | `#A3AFC2` on `#0B1020` | 4.5:1 |
| `caption` | `#56647E` on `#FFFFFF` | `#A3AFC2` on `#141B2D` | 4.5:1 |
| `application-copy` | `#0F1728` on `#FFFFFF` | `#D7DEEA` on `#141B2D` | 4.5:1 |
| `hero` | `#1557C0` on `#F7F9FC` | `#4F8CFF` on `#0B1020` | 3:1 |
| `link` | `#1557C0` on `#FFFFFF` | `#4F8CFF` on `#141B2D` | 4.5:1 |
| `focus` | `#1557C0` on `#F7F9FC` | `#4F8CFF` on `#0B1020` | 3:1 |
| `artwork` | `#4781E6` on `#F7F9FC` | `#4781E6` on `#0B1020` | 3:1 for graphics |

Use a visible 2px focus ring in the lane's focus color. The brand's operation words stay visible independently of color; use the supplied text/chip pairs: Insert `#136C47` / `#DDF2E8` light and `#5AE0A2` / `#10332B` dark; Update `#1557C0` / `#DDE9FB` light and `#8DB4FF` / `#14284F` dark; Delete `#A33434` / `#F9E1E1` light and `#FF8585` / `#3A1B23` dark; Redacted `#8A5512` / `#FBEFD2` light and `#F6C86B` / `#3A2A0A` dark. Operation color backs up its word and never replaces it.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | `Open transaction` |
| Empty state heading | `No changes match these filters` |
| Empty state body | `Try a wider date range or adjust the filters, then apply again.` |
| Transaction with no captured row changes | `No row-level changes captured.` Follow with: `A database transaction was found, but row-level changes were not captured. Check audit readiness for this table, then return to Timeline.` |
| Error state | Transaction not found: `No transaction is available at this ID. It may not exist or may be outside the records available to your current scope. Return to Timeline and check the transaction id.` Transaction unavailable: `The transaction could not be loaded. Retry or return to Timeline.` Row history from Timeline: `Row history is unavailable. Retry row history or return to Timeline.` Transaction-origin drawer: `Row history is unavailable. Retry row history or return to the transaction.` The recovery destination follows the actual existing parent route. Generic data failure: `Could not load audit data. Retry, then check logs.` |
| Copy pending / success / failure | `Copying…` → `Copied.`; on failure: `Copy failed. Select the value and copy it manually.` |
| Destructive confirmation | None; this investigation is read-only and includes no destructive user action. |

Keep the brand's plain terms: `Threadline Admin`, `audit trail library`, `Timeline`, `Transaction`, `record history`, `change`, `actor`, `table`, and `UTC`. Avoid assurance claims such as `tamper-proof`, `immutable`, or `compliant`. Preserve public module, option, schema, telemetry, URL, query-key, filename, anchor, and technical guide names.

## Phase Interaction Contract

### Visual hierarchy and layout guardrails

Within the existing `.threadline-ui` shell and page layout, the applied Timeline result set is the primary visual anchor. Give the matching result and its transaction action the strongest content hierarchy. Keep filters visibly subordinate as query controls and keep persistent shell/navigation quieter than the result. Preserve the existing header, filter, table, and detail layouts; make only the component-level brand updates required for this journey. Do not broaden the phase into a general Admin rebuild.

### Investigation journey

1. Enter Timeline with `table=ticket_replies&correlation_id=walk-acme-4521-close` plus any applicable committed `from` and `to` predicates. Keep URL predicates and visible filter values in agreement.
2. Find the actual matching row and follow its `Open transaction` link. Select by correlation and applicable date predicates, assert the expected action, and resolve generated IDs from that row; never assume a UUID format or choose the first unrelated row.
3. In the transaction, show the semantic action separately from the audit transaction and its changes. For this ordinary Acme #4521 story, the action is `ticket_replied_and_closed`; two table changes belong to one database transaction; show the actor as the actual rendered `user/<Manifest closer UUID>`. Do not imply every actor is a user or that the transaction is the request/action.
4. Show exact neutral values: ticket `status` open → closed; `closed_at` null → `2026-05-26T14:30:00Z`; public reply `Thanks — we're closing this out.`; internal note `[REDACTED]`; no secret canary. Display the event time as `May 26, 2026, 2:30 PM UTC`. Keep action insertion/recording time distinct from this event time.
5. Open the reply record's history through the existing host route. Use the shared `Presentation` / `UI.Display` owners for value, timestamp, actor, and identifier meaning. `Redacted` means replaced before persistence; a left-out value was excluded/not recorded; `null` is present and empty; omitted/absent snapshot keys remain distinct from deliberate exclusion; unavailable means a read failed. Keep exceptional missing, excluded, unavailable, and accepted-versus-completed fixtures separate from this ordinary story.
6. The complete reply-record identifier is available to keyboard users. Activate its existing Copy control by keyboard; send the exact complete ID to the deferred clipboard double. While its promise is pending show `Copying…`; after resolution show `Copied.`; on rejection show the failure copy above. Keep focus on the Copy control and wait for LiveView connection after navigation/patch before interacting. This proves the API argument and feedback contract, not native clipboard contents or permissions.
7. Return to Timeline through the existing validated local return route. Restore the original URL predicates and visible filters, including table and correlation plus any committed dates.

### Theme selection and keyboard focus

Default the surface to dark. Render a `Theme` fieldset/legend containing `System`, `Light`, and `Dark`; each is a native submit button that POSTs its existing value immediately. Expose the chosen button with `aria-pressed=true` and a visible selected mark; the other two expose `aria-pressed=false`. Keep CSRF, session/cookie persistence, the validated return path, server-side allowlisting, keyboard activation, and focus intact. Remove the separate `Apply theme` confirmation. `System` follows `prefers-color-scheme`; both effective lanes use their matching lockup and token values. The home lockup link's accessible name is `Threadline Admin home`; keep the supplied lockup at least 96px wide and the mark at least 16px.

Use the existing visual focus behavior for every link, button, filter, and copy control. Never move focus on clipboard status changes. Keyboard traversal follows page order: shell navigation and theme controls, filters, Timeline result, transaction detail/history, then the restored Timeline link. Keep the existing object-bearing accessible name `Copy row id` and visible label `Copy` on the reply identifier control. No interaction relies on color alone.

### Owned documentation and icon scope

Use the approved theme-paired lockups in the README's existing paired image at a rendered width of at least 96px. In ExDoc, use `brand/assets/icon/favicon.svg` and the existing head/body hooks to switch between the approved lockups when the installed `body.dark` theme changes; override the installed 48px image cap so the lockup remains at least 96px wide. Use the supplied device-scheme-aware favicon bytes only at the existing example Admin path `/images/threadline-admin-favicon.svg`; preserve the demo home/login `/favicon.ico`. The favicon follows device color scheme independently of the app's theme. Package only the three directly owned SVGs, four approved WOFF2 subsets, and their three OFL licenses for this phase; do not add a public asset route or ship the whole brand tree.

## UI Considerations

Executed installed UI probe over six authored surface descriptions with explicit kind unions (agent confirmation under --auto). All38 considerations have explicit acceptance criteria; this is specification completeness, not completed runtime verification. Planner must lift every criterion and bind actual automated evidence.

| Element | Category | Status | Acceptance criterion |
|---|---|---|---|
| E1 | empty | resolved / explicit | Empty Timeline filters remain usable and apply an unconstrained supported query; no empty input fabricates a captured value. |
| E1 | loading | resolved / explicit | During a filter request, the displayed committed query is not relabeled as the pending query; connection/loading status is announced using the existing shared state boundary. |
| E1 | error | resolved / explicit | A failed filter read is unavailable with recovery, not a successful zero-result search. |
| E1 | partial | resolved / explicit | Optional absent date/table/correlation predicates stay absent; surviving committed predicates round-trip unchanged. |
| E1 | overflow | resolved / explicit | Long filter values stay within the responsive form and no control is clipped or hidden. |
| E1 | long-text | resolved / explicit | Long correlation/table input remains editable and its complete submitted value is preserved. |
| E2 | empty | resolved / explicit | Zero matching Timeline results show the Copywriting Contract empty heading/body with filter recovery. |
| E2 | loading | resolved / explicit | Timeline loading keeps pending versus committed result identity distinct and uses an accessible status rather than fabricated rows. |
| E2 | error | resolved / explicit | Timeline read failure uses the shared unavailable/error state with recovery and is not labeled empty. |
| E2 | populated | resolved / explicit | The correlated ordinary result identifies the actual #4521 transaction and opens it through the mounted host route. |
| E2 | partial | resolved / explicit | A result lacking optional actor/context metadata remains navigable without inventing identity or request semantics. |
| E2 | overflow | resolved / explicit | Results retain their existing responsive table scroll boundary and do not overflow the page shell. |
| E2 | zero-one-many | resolved / explicit | Zero, one and multiple Timeline results retain their correct empty/singular/plural count and usable row spacing. |
| E2 | long-text | resolved / explicit | Long result metadata is bounded visually while the actual identifiers and destination routes remain unchanged. |
| E3 | empty | resolved / explicit | A found transaction with zero captured row changes differs from a missing transaction; empty row history remains distinct from an unavailable read. |
| E3 | loading | resolved / explicit | Transaction/history loading does not replace missing values with invented snapshots and retains accessible existing loading behavior. |
| E3 | error | resolved / explicit | Not-found and unavailable transaction/history reads keep distinct recovery copy per Copywriting Contract. |
| E3 | populated | resolved / explicit | The #4521 transaction presents one semantic action and two table changes with exact status/closed_at/reply/redaction, actual actor and UTC event time. |
| E3 | partial | resolved / explicit | Null, redacted, omitted/absent snapshot keys, excluded fields and unavailable reads remain distinct through shared Presentation/UI.Display. |
| E3 | overflow | resolved / explicit | Long exact value text wraps within its value container; responsive rows preserve access to all columns. |
| E3 | zero-one-many | resolved / explicit | Transaction/history zero, one and multiple captured changes retain accurate counts without implying one action per change. |
| E3 | long-text | resolved / explicit | Long field/table/value content remains readable and full unchanged IDs remain available despite middle elision. |
| E4 | empty | resolved / explicit | Absent stored theme defaults to dark and the server always exposes the three supported System/Light/Dark choices. |
| E4 | loading | resolved / explicit | Each theme choice submits immediately through the native form; no second Apply confirmation or premature client-only persisted state is introduced. |
| E4 | error | resolved / explicit | Invalid theme/unsafe return/CSRF failure is rejected through existing server validation; no successful preference change is claimed. |
| E4 | partial | resolved / explicit | System follows effective device scheme while the stored selection remains System; explicit Light/Dark overrides stay distinct. |
| E4 | overflow | resolved / explicit | Shell navigation and theme choices remain reachable without page overflow or clipped selected/focus state. |
| E4 | long-text | resolved / explicit | Navigation labels keep visible meaning and theme buttons retain complete accessible names and keyboard activation. |
| E5 | loading | resolved / explicit | Keyboard activation passes the exact full reached record ID to the controlled Clipboard API double and shows Copying until its promise resolves. |
| E5 | error | resolved / explicit | Rejected clipboard and failed fallback show the contract manual-recovery copy with no false success, no focus movement and no hidden textarea leak. |
| E5 | overflow | resolved / explicit | Copy feedback remains inside its container without overlapping or obscuring the triggering button. |
| E5 | long-text | resolved / explicit | A long record ID is copied complete and unchanged; visual elision never shortens the API argument, and focus remains on the control. |
| E6 | empty | resolved / explicit | With embedded fonts disabled no font-face payload is served and system fallback remains usable; an asset absence must not produce an empty accessible home link. |
| E6 | loading | resolved / explicit | Local font loading permits readable fallback and no remote request; supplied lockup remains correctly sized during loading. |
| E6 | error | resolved / explicit | Blocked/absent embedded fonts retain readable system fallback and no remote fallback; owned logo/favicon failures are observable rather than described as a proof pass. |
| E6 | populated | resolved / explicit | Served lockups match supplied SVG geometry/colors and minimum96px width; served four WOFF2 bytes, face weights and all3licenses match approved sources and docs pair follows theme. |
| E6 | overflow | resolved / explicit | Admin/docs lockups remain at least96px wide without clipping; icon mark minimum16px and responsive shell stay usable. |
| E6 | long-text | resolved / explicit | Private font aliases do not collide with generic host family names; accessible home/link text stays complete while the visual artwork stays supplied. |

The matched baseline/after evidence obligation remains D-09/D-10: source/served assets, same materialized target/IDs/times/fingerprint, shell/header, browser conditions and measured zoom or unverified. No reset between halves, native clipboard, foreground activation or claim of rendered proof from source checks.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None; custom Phoenix components only | None | Not applicable — no third-party component registry or block is used. |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: FLAG — standalone Retry should name its target; contextual sentence may supply it.
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** Independent typed checker approved after focused corrections, 2026-11-12. Six dimensions PASS; Copywriting advisory above remains non-blocking. No runtime or rendered-acceptance claim.

## Sources

- `.planning/ROADMAP.md` — Phase 250 goal and success criteria.
- `.planning/REQUIREMENTS.md` — ADM-08–14 and ADM-16–17.
- `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md` — locked decisions D-01–D-15.
- `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-RESEARCH.md` — current component seams, copy/state owners, proof boundaries, and package scope.
- `brand/BRAND.md`, `brand/brand.json`, `brand/tokens.json`, and `brand/assets/README.md` — approved voice, token roles, font roles, artwork and asset map.
- `lib/threadline/operator_surface/style/01_tokens.css`, `lib/threadline/operator_surface/components/`, and `lib/threadline/operator_surface/ui/` — existing runtime token and component owners.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` and `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` — existing mounted journey and feedback proofs.
