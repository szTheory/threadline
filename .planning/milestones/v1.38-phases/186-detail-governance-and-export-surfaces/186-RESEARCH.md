# Phase 186: Detail, governance, and export surfaces - Research

**Researched:** 2026-06-30
**Domain:** Phoenix LiveView operator UI detail, governance, export, and retention surfaces
**Confidence:** HIGH for local code state; MEDIUM for external framework/accessibility docs

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: `.planning/phases/186-detail-governance-and-export-surfaces/186-CONTEXT.md` [CITED: .planning/phases/186-detail-governance-and-export-surfaces/186-CONTEXT.md]

### Locked Decisions

#### Contract Authority And Scope

- **D-186-01:** `186-UI-SPEC.md` is the primary Phase 186 contract. Planning should start by diffing current target pages against it, not by asking new product/design questions.
- **D-186-02:** The phase should normalize existing pages to the private Threadline operator component system, not redesign the operator surface or create a new component family.
- **D-186-03:** Preserve route paths, stable `data-testid`s, feature gates, auth/export auth boundaries, optional Phoenix/LiveView dependency posture, scoped `data-tl-theme`, CSP-friendly behavior, and host-app-friendly library boundaries.
- **D-186-04:** Avoid new dependencies, Tailwind/shadcn, public component API, external icon packages, custom JS widgets, client-side routing, broad visual-regression expansion, and decorative animation.

#### Detail Surfaces

- **D-186-05:** Transaction, Row history, and Actor activity must share the same detail-page anatomy: `UI.shell/1`, compact `UI.page_header/1`, one object summary via `UI.detail_header/1` or equivalent, metadata through `UI.kv/1`, full-value refs via `UI.ref/1`, and scan-first row/action lists.
- **D-186-06:** Detail pages keep Timeline as the investigation nav context (`current={:timeline}`) and use breadcrumbs back to Timeline. Breadcrumbs must not create duplicate conflicting `aria-current="page"` state.
- **D-186-07:** Primary detail actions are investigation pivots only: `Open transaction`, `Open row history`, `Open timeline`, and `Review evidence` when feature-enabled and contextual.
- **D-186-08:** Row-history subviews should use `UI.drawer/1` where feasible. If existing subview markup remains, it must meet the same dialog, Escape/close, visible close, focus-in, and focus-return contract.
- **D-186-09:** Dense raw maps belong inside row-local details, drawers, or rows. Above the fold should show only useful object facts such as actor, correlation id, table, record id, selected/as-of time, window, count, and status.

#### Governance And Export Workflows

- **D-186-10:** Evidence, Exports, Redaction, and Retention must read as focused workflows, not dashboards or dense metadata dumps. Each page gets one summary/decision unit directly below the header that answers the page's main question.
- **D-186-11:** Avoid duplicate generic trust rails, repeated metric grids, and repeated cross-page CTAs. Coverage/Evidence/Timeline/Exports links are contextual and feature-gated.
- **D-186-12:** Exports answers what can be downloaded, what is processing, and how to reopen the source search. Jobs should be grouped by readiness/status and use honest recent-only captions.
- **D-186-13:** Evidence records remain grouped by subject with verdict chip, proof label, subject, copyable subject ref, recorded time, and only relevant actions. `Carry to Exports` appears only when exports are enabled and the Evidence request shape is valid.
- **D-186-14:** Redaction answers whether deployed trigger redaction matches configured policy. Do not add a runtime redaction destructive button or modal.
- **D-186-15:** Retention answers whether the retention window is healthy and what happens if an operator prunes now. A single visible page-level destructive action is enough; any row-menu prune must open the same policy-level modal and must not imply row-specific deletion.

#### Controls, Downloads, And Feature Gates

- **D-186-16:** Completed export downloads render as real focusable HTTP links. They must not have `aria-disabled="true"`, `tabindex="-1"`, or LiveView reconnect/mutating dimming when the controller can serve them while LiveView reconnects.
- **D-186-17:** Pending, running, failed, expired, unauthorized, or feature-gated jobs must not expose active fake download links. Use visible status text such as `Queued`, `Processing`, `Expired`, or `Failed`.
- **D-186-18:** `Queue Timeline export` is a native LiveView button visible only for valid context and exports-enabled state. It needs real unavailable/mutating affordances plus server-side enforcement.
- **D-186-19:** Feature-disabled routes render the existing unsupported view and remove the disabled nav/action surface through shell gates. Prefer omitting disabled feature links over showing inert links unless an explanation is needed.
- **D-186-20:** CSS dimming and `pointer-events: none` are affordance only. Disabled/unavailable behavior must use native `disabled`, removed `href`, `aria-disabled`, `tabindex="-1"`, and server/controller enforcement as appropriate for the element type.

#### Retention Destructive Flow

- **D-186-21:** Retention prune is the only destructive action in Phase 186. It must use the UI-SPEC labels and copy, including `Run retention prune`, `Prune retention window permanently?`, `Keep retention window`, and `Prune records permanently`.
- **D-186-22:** The destructive flow keeps server-side auth re-check, server-derived canonical policy name `default`, `Plug.Crypto.secure_compare/2`, audit-before-prune, fail-closed mismatch handling, runtime-unavailable handling, reconnect-safe mutating control affordance, and focus restoration.
- **D-186-23:** The mismatch flash copy is locked by UI-SPEC as `Could not prune - confirmation did not match.` If existing code uses different punctuation, planning should reconcile source and tests to the UI-SPEC.
- **D-186-24:** Runtime redaction destructive UI remains deferred; do not use the retention destructive pattern to sneak in a Redaction destructive flow.

#### State, Copy, Responsive, And Motion

- **D-186-25:** Use the UI-SPEC state lattice. Permission, source-down, redacted, pruned, stale, invalid context, failed export, and reconnecting states must not collapse into a generic empty or error message.
- **D-186-26:** Page copy must use Threadline nouns exactly: Timeline, transaction, row history, actor, correlation id, Evidence, Exports, Redaction, Retention, export job, retention run, policy name, and audit readiness.
- **D-186-27:** Color never carries status alone. Pair colors with text, icons, chips, status stripes, or role-specific copy.
- **D-186-28:** Responsive proof must cover the targeted Phase 186 surfaces at 320, 375, 768, 1024, and 1440 where the UI-SPEC calls it out, especially long refs, job cards, tables, drawers, and the retention modal.
- **D-186-29:** Motion stays inside existing 180ms modal/drawer opacity/transform utilities, copy success treatment, button active feedback, data-panel fade, and existing reduced-motion behavior. No new row/card keyframes or `transition: all`.

#### Verification Posture

- **D-186-30:** Verification should be targeted to Phase 186 contracts. Preserve or add focused source, LiveView, and Playwright proof for detail alignment, export/download links, feature gates, retention destructive flow, responsive behavior, and keyboard/accessibility paths.
- **D-186-31:** Do not expand the broad screenshot matrix. Use existing example browser lanes and classify unrelated broad-suite residuals honestly.
- **D-186-32:** Tests should prefer role/name/test-id locators, source/doc contracts, LiveView behavior assertions, direct controller/auth proof for downloads, and browser checks for focus, overflow, and reachable controls.

### the agent's Discretion

Downstream agents may choose exact plan count, wave ordering, helper names, private extraction boundaries, CSS selectors, test organization, and whether to amend existing tests or add a narrow Phase 186 spec, as long as they preserve the decisions above and implement the UI-SPEC faithfully.

### Deferred Ideas (OUT OF SCOPE)

- Runtime redaction destructive flow remains deferred to a future phase that explicitly scopes capture/storage semantics.
- Public component API remains deferred to `COMP-PUBLIC-01` or a future explicit milestone.
- Public Storybook/distribution remains deferred to `STORY-PUBLIC-01` or a future explicit milestone.
- Broad screenshot matrix expansion remains deferred; Phase 186 owns targeted proof only.
- Route churn, stable `data-testid` renames, auth/capture/query semantic changes, Tailwind/shadcn, and new UI dependencies remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DETAIL-01 | Transaction, row-history, actor pages use same detail-header, metadata, copy/ref, drawer, state patterns as cleaned Timeline. | Use existing `UI.shell`, `UI.page_header`, `UI.detail_header`, `UI.kv`, `UI.ref`, `UI.data_panel`, and `UI.drawer`; current Transaction/Row history/Actor gaps are mapped in this artifact. [CITED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| GOV-01 | Evidence, Exports, Redaction, Retention read as focused operator workflows not dense dumps. | Collapse page-level trust rails/repeated grids into one summary/decision unit per page, retaining existing record/job visual families. [CITED: 186-UI-SPEC.md] [VERIFIED: codebase grep] |
| GOV-02 | Export/download affordances, feature-gated controls, disabled states correct for pointer/keyboard/AT. | Correct completed export jobs to real HTTP links; keep unavailable jobs as status text; enforce feature gates in shell/router/controller tests. [CITED: 186-UI-SPEC.md] [VERIFIED: codebase grep] |
| GOV-03 | Retention destructive actions keep type-to-confirm, auth re-check, audit-the-action, reconnect-safe disabled state, focus restore, object/consequence copy; runtime redaction destructive remains deferred unless rescoped. | Server enforcement is already present; UI copy/focus/cancel label and row-menu semantics need alignment. [CITED: 186-CONTEXT.md] [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Preserve Threadline's three-layer split: capture/guarded data, semantic meaning, and exploration/operations; do not conflate those layers while polishing UI. [CITED: CLAUDE.md]
- Use domain nouns in code and copy: `action`, `actor`, `table`, `primary_key`, `metadata`, `redaction`, and `retention`; keep SQL/internal names out of operator-facing surfaces unless intentionally exposed as data. [CITED: CLAUDE.md]
- Use existing verification commands: `mix compile --warnings-as-errors`, `mix test`, `mix format`, `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. [CITED: CLAUDE.md]
- Keep Phoenix/LiveView optional at the root library boundary; `mix verify.compile_no_optional` exists to protect this posture. [CITED: CLAUDE.md] [VERIFIED: mix.exs]
- Do not change capture/query/auth semantics for this phase; Phase 186 is an operator-surface normalization pass. [CITED: 186-CONTEXT.md]
- No `AGENTS.md` exists in the repository root, so there are no additional AGENTS directives for this phase. [VERIFIED: shell]

## Summary

Phase 186 is a normalization pass over existing Phoenix LiveView operator pages, not a new product surface or dependency upgrade. The target pages already exist, and the private UI system already provides the required primitives for shell, page headers, detail headers, key/value metadata, refs, data panels, tables, modal, drawer, dropdown, fields, buttons, focus helpers, and scoped styling. [VERIFIED: codebase grep]

The highest-risk current deltas are concrete and implementation-relevant: completed export downloads are rendered as disabled/mutating links in `ExportStatusLive`; retention already has strong server enforcement but the modal copy/cancel label/mismatch punctuation need exact UI-SPEC alignment; governance pages still carry repeated trust-rail/metric-grid patterns; and detail pages need consistent object summaries through `UI.detail_header` or an equivalent page-local implementation. [VERIFIED: codebase grep] [CITED: 186-UI-SPEC.md]

**Primary recommendation:** Use the existing private `Threadline.OperatorSurface.UI` and `Presentation` stack, make vertical page-by-page amendments, and validate with targeted source, LiveView, controller/auth, copy/style contract, and existing Playwright lanes instead of adding new dependencies or broad screenshots. [VERIFIED: codebase grep] [CITED: 186-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Detail page anatomy for Transaction, Row history, and Actor activity | Frontend Server (Phoenix LiveView) | Browser / Client | LiveViews render the page structure, while browser focus/copy behavior depends on existing `UI.ref`, `UI.drawer`, and JS helpers. [VERIFIED: codebase grep] |
| Export download authorization and delivery | API / Backend | Frontend Server (Phoenix LiveView affordance only) | `ExportAuthPlug` authorizes the HTTP route and `ExportController.download/2` enforces job ownership/readiness; LiveView should only expose a correct link. [VERIFIED: codebase grep] |
| Export queue action | Frontend Server (Phoenix LiveView) | API / Backend | The queue button is a LiveView event, but handler code must continue rejecting forged/invalid contexts server-side. [VERIFIED: codebase grep] |
| Feature gates and unsupported routes | Frontend Server (router/on_mount/shell) | Browser / Client | Route gates, assigns, unsupported view, and shell nav gates determine whether a control exists; CSS/inert states are not the authority. [VERIFIED: codebase grep] |
| Retention destructive prune | API / Backend | Frontend Server (modal/form/focus) | Auth re-check, `Plug.Crypto.secure_compare/2`, audit-before-prune, and `Pruner.trigger/0` own safety; modal UI owns copy, confirmation input, focus, and reconnect-safe affordance. [VERIFIED: codebase grep] |
| Governance workflow summaries | Frontend Server (Phoenix LiveView) | Database / Storage | LiveViews present existing evidence/export/redaction/retention data as workflow decisions without changing underlying capture/query/storage semantics. [CITED: 186-CONTEXT.md] [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Root build, compile, ExUnit, aliases | Local runtime for all Phase 186 source and tests. [VERIFIED: local command] |
| Phoenix | 1.8.7 locked | Router, controller, ConnTest support in optional operator surface | Existing optional dependency used by operator routes/controllers; no new dependency is needed. [VERIFIED: mix deps] |
| Phoenix LiveView | 1.1.30 locked | Operator LiveViews, HEEx function components, JS focus helpers, LiveView tests | Official docs support function components with attrs/slots/global `phx-`/`aria-`/`data-` attrs and JS focus helpers; local code already uses them. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveView.JS.html] [VERIFIED: mix deps] |
| Phoenix.HTML | 4.3.0 locked | HEEx/link/form rendering support | Existing optional Phoenix HTML layer for operator templates. [VERIFIED: mix deps] |
| Ecto / Ecto.SQL | 3.13.5 locked | Test repo access and existing query/storage structs | Target tests seed and read existing audit/export/evidence/retention data without changing query semantics. [VERIFIED: mix deps] |
| Postgrex | 0.22.0 locked | Postgres adapter for tests and example app | Local Postgres is accepting connections on `/tmp:5432`. [VERIFIED: mix deps] [VERIFIED: local command] |
| Plug / Plug.Crypto | Plug 1.19.1, Plug.Crypto 2.1.1 locked | Export controller responses and retention secure compare | `Plug.Conn.send_file/4` and `Plug.Crypto.secure_compare/2` are already part of the implementation path. [CITED: https://plug.hexdocs.pm/1.19.1/Plug.Conn.html] [VERIFIED: mix deps] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Playwright `@playwright/test` | `^1.52.0` in example e2e package | Browser proof for mobile, focus, overflow, route transitions, and reachable controls | Use existing operator e2e specs for Phase 186-only proof, not broad screenshot expansion. [VERIFIED: examples/threadline_phoenix/e2e/package.json] [CITED: https://playwright.dev/docs/best-practices] |
| LazyHTML | 0.1.0 locked | HTML contract parsing in tests | Use for source/rendered HTML assertions where existing tests already parse markup. [VERIFIED: mix deps] |
| Credo | 1.7.18 locked | Static code quality gate | Run through existing `mix verify.credo` when implementation touches Elixir. [VERIFIED: mix deps] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Private `Threadline.OperatorSurface.UI` | Tailwind/shadcn or a new component family | Rejected by phase constraints; would violate no-new-deps and private component posture. [CITED: 186-CONTEXT.md] |
| `UI.drawer` / `UI.modal` focus helpers | Page-local custom overlay JS | Rejected for new work; existing UI helpers already encapsulate LiveView JS focus/push/pop behavior. [VERIFIED: codebase grep] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveView.JS.html] |
| HTTP export controller link | LiveView download mutation event | Rejected for completed downloads; direct download is already controller/auth-plug territory. [VERIFIED: codebase grep] |

**Installation:**

```bash
# No package install for Phase 186.
# Use existing locked Mix and example e2e dependencies.
```

**Version verification:**

```bash
mix deps | rg 'phoenix |phoenix_live_view|phoenix_html|plug |plug_crypto|ecto_sql|ecto |postgrex|jason|lazy_html|credo'
elixir --version
node --version
npm --version
```

## Package Legitimacy Audit

Phase 186 should install no new external packages. The package-legitimacy gate is therefore not applicable for new recommendations; all stack entries above are existing locked dependencies or existing local tooling. [CITED: 186-CONTEXT.md] [VERIFIED: mix deps]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | none | n/a | n/a | n/a | n/a | No new package installation recommended. [VERIFIED: codebase grep] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: codebase grep]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: codebase grep]

## Current Code State and Target Files

| Target | Current State | Planning Implication |
|--------|---------------|----------------------|
| [ui.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/ui.ex:238) | `page_header`, breadcrumbs, `ref`, `kv`, `detail_header`, `data_panel`, `modal`, `drawer`, and `shell` already exist. [VERIFIED: codebase grep] | Reuse these primitives; do not create public components or page-local replacements. |
| [presentation.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/presentation.ex:281) | Export readiness/action labels, ref truncation, and value-token helpers already exist. [VERIFIED: codebase grep] | Keep export job grouping/copy in `Presentation`; avoid duplicating readiness logic in LiveViews. |
| [transaction_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/transaction_live.ex:86) | Uses `UI.shell current={:timeline}`, breadcrumbs, copyable refs, row change list, and row-history subview, but object summary is still page-header metadata/hand-rolled states rather than `UI.detail_header`/state family. [VERIFIED: codebase grep] | Normalize Transaction first or alongside Row history because it hosts the row-history component. |
| [row_history_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/row_history_live.ex:35) and [row_history_component.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/row_history_component.ex:70) | Standalone page delegates to an old `tl-subview` dialog-like component; it has role/dialog markup but is not `UI.drawer`. [VERIFIED: codebase grep] | Prefer `UI.drawer`; if retaining old markup, add Escape/focus-return parity proof. |
| [actor_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/actor_live.ex:90) | Uses shell and state helpers but page H1/object summary do not match the locked `Actor activity` detail pattern. [VERIFIED: codebase grep] | Align with detail-header anatomy, metadata, refs, and investigation-only pivots. |
| [evidence_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/evidence_live.ex:55) | Records are grouped by subject and `Carry to Exports` is already gated by exports/request validity, but the page still has a trust rail and generic cross-page CTAs. [VERIFIED: codebase grep] | Keep subject grouping; collapse into the UI-SPEC workflow summary and contextual actions. |
| [export_status_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/export_status_live.ex:115) | Jobs are grouped and context panels exist, but completed download links currently include `data-tl-mutating`, `aria-disabled="true"`, and `tabindex="-1"`. [VERIFIED: codebase grep] | Highest-risk GOV-02 fix: real focusable HTTP links for completed jobs; status text for unavailable jobs. |
| [policy_redaction_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/policy_redaction_live.ex:55) | Redaction answers configured-vs-deployed status but still uses trust rail/summary-grid patterns and some row actions require feature-gate review. [VERIFIED: codebase grep] | Keep no runtime destructive UI; collapse to one workflow summary and contextual enabled links. |
| [retention_history_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/retention_history_live.ex:67) | Server-side prune flow already rechecks auth, compares canonical `default`, audits before pruning, and handles runtime unavailable; UI copy has em-dash mismatch flash and Cancel label. [VERIFIED: codebase grep] | Preserve backend safety; align exact UI-SPEC labels, focus, state components, and row-menu semantics. |
| [export_auth_plug.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/export_auth_plug.ex:67) and [controllers/export_controller.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/controllers/export_controller.ex:57) | Direct export download auth and job ownership/readiness enforcement already exist. [VERIFIED: codebase grep] | LiveView link changes must be paired with controller/auth tests, not replaced by UI-only checks. |
| [filter_params.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/exports/filter_params.ex:25) | Export/Timeline params use a fixed atom allowlist and `String.to_existing_atom/1` for actor kinds. [VERIFIED: codebase grep] | Preserve this filter parser for export context; do not hand-roll query parsing. |

## Architecture Patterns

### System Architecture Diagram

```text
Operator route request
  -> Router live_session / export HTTP scope [VERIFIED: codebase grep]
    -> Auth on_mount assigns actor, gates, scope, theme [VERIFIED: codebase grep]
      -> LiveView target page renders private UI components [VERIFIED: codebase grep]
        -> Detail pages: shell -> page_header -> detail_header -> row/action list -> optional drawer
        -> Governance pages: shell -> page_header -> one workflow summary -> grouped records/jobs/runs
        -> Export queue: LiveView button -> server validates context/gate -> ExportJob
        -> Completed download: HTTP link -> ExportAuthPlug -> ExportController -> file/redirect response
        -> Retention prune: modal form -> LiveView event -> auth re-check -> secure compare -> audit -> Pruner
```

### Recommended Project Structure

Phase 186 is a retune of existing files; no new app structure is required. [VERIFIED: codebase grep]

```text
lib/threadline/operator_surface/
├── ui.ex                         # private reusable page, state, overlay, form, and ref components
├── style.ex                      # scoped operator CSS contract
├── presentation.ex               # labels, refs, export readiness, value tokens
├── live/
│   ├── transaction_live.ex        # Transaction detail
│   ├── row_history_live.ex        # Standalone row history
│   ├── row_history_component.ex   # Row-history drawer/subview
│   ├── actor_live.ex              # Actor activity detail
│   ├── evidence_live.ex           # Evidence workflow
│   ├── export_status_live.ex      # Exports workflow
│   ├── policy_redaction_live.ex   # Redaction workflow
│   └── retention_history_live.ex  # Retention workflow/destructive modal
└── controllers/export_controller.ex # Direct HTTP export delivery
```

### Pattern 1: Detail Page Anatomy

**What:** Render one compact H1 page header for route context, then one `UI.detail_header` for object identity/metadata/actions. [CITED: 186-UI-SPEC.md] [VERIFIED: codebase grep]

**When to use:** Transaction, Row history, and Actor activity pages. [CITED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/ui.ex
<UI.page_header title="Transaction" />
<UI.detail_header title={"Transaction #{short_id}"}>
  <:metadata key="Actor"><UI.ref value={actor_ref} kind="actor" copy_label="Copy actor ref" /></:metadata>
  <:actions><.link navigate={timeline_path}>Open timeline</.link></:actions>
</UI.detail_header>
```

### Pattern 2: Export Affordance Split

**What:** Completed export jobs render real HTTP links; unavailable jobs render status text; queueing is a native LiveView button with mutating/server enforcement. [CITED: 186-UI-SPEC.md] [VERIFIED: codebase grep]

**When to use:** `ExportStatusLive` job actions and Timeline export context controls. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source target: lib/threadline/operator_surface/live/export_status_live.ex
if Presentation.export_downloadable?(job) do
  <.link href={"#{@base_path}/exports/download/#{job.id}"} class="tl-button tl-button--primary tl-button--compact">
    Download export
  </.link>
else
  <span class="tl-hint" role="status"><%= Presentation.export_action_label(job) %></span>
end
```

### Pattern 3: Destructive Retention Modal

**What:** Open via `JS.push_focus()`, focus the confirmation input through `data-tl-initial-focus`, submit through a visible form input, and close with focus restoration through `UI.modal`. [VERIFIED: codebase grep] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]

**When to use:** Retention prune only; runtime redaction destructive UI is deferred. [CITED: 186-CONTEXT.md]

**Example:**

```elixir
# Source target: lib/threadline/operator_surface/live/retention_history_live.ex
<button phx-click={JS.push_focus() |> JS.push("open_prune_modal")}>
  Run retention prune
</button>

<UI.modal id="prune-confirm" show={true} on_cancel={JS.push("close_prune_modal")}>
  <input name="confirm" aria-label="Policy name to confirm" data-tl-initial-focus />
  <button type="button" phx-click={JS.push("close_prune_modal")}>Keep retention window</button>
  <button type="submit" data-tl-mutating>Prune records permanently</button>
</UI.modal>
```

### Anti-Patterns to Avoid

- **Disabled completed download links:** Real completed downloads must not include `aria-disabled`, `tabindex="-1"`, or `data-tl-mutating`. [CITED: 186-UI-SPEC.md] [VERIFIED: codebase grep]
- **Trust rail repetition:** Evidence/Exports/Redaction/Retention should not keep duplicate generic rails or repeated CTAs after Phase 186. [CITED: 186-CONTEXT.md] [VERIFIED: codebase grep]
- **Overlay fork:** Do not add page-local overlay JS when `UI.modal` and `UI.drawer` already provide Escape/click-away/focus behavior. [VERIFIED: codebase grep] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveView.JS.html]
- **UI-only security:** Feature gates, export downloads, and retention prune must stay server/controller enforced; UI omission or dimming is not enough. [CITED: 186-CONTEXT.md] [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Copyable IDs/refs | Custom truncation/copy spans | `UI.ref` + `Presentation.ref` | Current helper binds full values to `title` and `data-tl-copy` while showing truncated text only when JS is enabled. [VERIFIED: codebase grep] |
| Detail metadata | Ad hoc `<dl>` fragments per page | `UI.kv` inside `UI.detail_header` | The component gives one consistent object summary pattern for DETAIL-01. [VERIFIED: codebase grep] [CITED: 186-UI-SPEC.md] |
| State rendering | Generic empty/error blocks | `UI.data_panel`, `UI.empty_state`, `UI.error_state`, `UI.loading_state`, `UI.stale_banner` | The state family preserves permission/unavailable/error/no-data distinctions. [VERIFIED: codebase grep] |
| Dialog/drawer behavior | Page-local overlay JS | `UI.modal` / `UI.drawer` | Existing helpers implement role/dialog markup, Escape, click-away, focus first/initial focus, and focus pop. [VERIFIED: codebase grep] |
| Export URL/filter parsing | Manual string parsing | `Threadline.OperatorSurface.Exports.FilterParams` | Existing parser uses allowlisted keys and `String.to_existing_atom/1` for actor kind. [VERIFIED: codebase grep] |
| Export delivery/auth | LiveView download mutation | `ExportAuthPlug` + `ExportController.download/2` | Controller path enforces actor ownership, readiness, expiration, headers, and file/redirect delivery. [VERIFIED: codebase grep] |
| Retention confirmation | JS confirm or plain equality | Server event with `Plug.Crypto.secure_compare/2` plus audit-before-prune | Existing server flow already fail-closes forged/mismatched confirmation and audits before pruning. [VERIFIED: codebase grep] |
| Icons | External icon package | `Threadline.OperatorSurface.Components.Icon` | Phase constraints forbid new icon dependencies and the internal icon module already exists. [CITED: 186-CONTEXT.md] [VERIFIED: codebase grep] |

**Key insight:** The hard parts of Phase 186 are not missing primitives; they are applying existing primitives consistently while preserving controller/auth/domain boundaries. [VERIFIED: codebase grep] [CITED: 186-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Completed exports look disabled

**What goes wrong:** Operators cannot tab to or activate a completed download because the link has `aria-disabled="true"` and `tabindex="-1"`. [VERIFIED: codebase grep]

**Why it happens:** The current markup applies the LiveView mutating-control pattern to an HTTP download link. [VERIFIED: codebase grep]

**How to avoid:** Render completed jobs as normal `<a href="/exports/download/{id}">Download export</a>` links, and keep unavailable jobs as non-link status text. [CITED: 186-UI-SPEC.md]

**Warning signs:** `data-tl-mutating`, `aria-disabled`, or `tabindex="-1"` on a completed export download link. [VERIFIED: codebase grep]

### Pitfall 2: Treating affordance visibility as authorization

**What goes wrong:** A hidden/disabled UI element is mistaken for the security boundary. [CITED: 186-CONTEXT.md]

**Why it happens:** Feature gates and export links are visible in LiveView, but direct downloads are served by controller routes. [VERIFIED: codebase grep]

**How to avoid:** Keep `ExportAuthPlug`, `ExportController`, queue handler, and retention handler tests in the Phase 186 proof set. [VERIFIED: codebase grep]

**Warning signs:** Tests only assert link visibility and do not cover 403/404/410/422 controller paths or forged LiveView events. [VERIFIED: codebase grep]

### Pitfall 3: Governance pages become dashboards

**What goes wrong:** Evidence/Exports/Redaction/Retention keep trust rails, summary grids, and generic CTAs that compete with the main workflow. [VERIFIED: codebase grep]

**Why it happens:** Earlier pages used trust rails before Phase 185 established a focused workflow verdict pattern. [CITED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]

**How to avoid:** One page-level summary/decision unit directly below the header, then grouped records/jobs/runs. [CITED: 186-CONTEXT.md]

**Warning signs:** More than one generic `Open timeline` or `Open exports` action above the data area. [VERIFIED: codebase grep]

### Pitfall 4: Detail pages keep metadata in the H1 header

**What goes wrong:** The page header becomes a dense metadata dump instead of a route/context header plus object summary. [VERIFIED: codebase grep]

**Why it happens:** Transaction and Actor currently put object metadata into or near `UI.page_header`. [VERIFIED: codebase grep]

**How to avoid:** Keep one H1 page title, then use `UI.detail_header` with `UI.kv` rows for object identity. [CITED: 186-UI-SPEC.md] [VERIFIED: codebase grep]

**Warning signs:** No `.tl-detail-header` on Transaction/Actor/Row history after implementation. [VERIFIED: codebase grep]

### Pitfall 5: Row-history drawer semantics only partially work

**What goes wrong:** The subview has dialog attributes but lacks the same Escape/focus-return contract as `UI.drawer`. [VERIFIED: codebase grep]

**Why it happens:** `RowHistoryComponent` uses older `tl-subview` markup instead of `UI.drawer`. [VERIFIED: codebase grep]

**How to avoid:** Convert to `UI.drawer` if feasible; otherwise add browser proof for visible close, focus entry, Escape close, and focus return. [CITED: 186-CONTEXT.md] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]

**Warning signs:** A row-history dialog has no `phx-window-keydown` Escape path or no focus restoration proof. [VERIFIED: codebase grep]

### Pitfall 6: Retention copy drifts by one word or punctuation mark

**What goes wrong:** The destructive flow fails the UI-SPEC/copy contract even though server enforcement is correct. [CITED: 186-UI-SPEC.md]

**Why it happens:** Existing code uses `Cancel` and `Could not prune — confirmation did not match.` while UI-SPEC locks `Keep retention window` and `Could not prune - confirmation did not match.` [VERIFIED: codebase grep] [CITED: 186-UI-SPEC.md]

**How to avoid:** Update source and tests together with exact string assertions. [CITED: 186-CONTEXT.md]

**Warning signs:** Tests use loose substring matching around the destructive modal. [VERIFIED: codebase grep]

### Pitfall 7: Feature-gated links remain inside enabled pages

**What goes wrong:** A page renders a link to Coverage/Evidence/Exports even when that destination is disabled. [CITED: 186-CONTEXT.md]

**Why it happens:** Shell navigation is gated, but page-local row/action links may not consistently check feature assigns. [VERIFIED: codebase grep]

**How to avoid:** Gate contextual links at their render site and prefer omission over inert links. [CITED: 186-CONTEXT.md]

**Warning signs:** `Check coverage`, `Review evidence`, or `Carry to Exports` renders without the corresponding feature gate. [VERIFIED: codebase grep]

### Pitfall 8: Broad browser proof hides the Phase 186 contract

**What goes wrong:** A large screenshot/e2e sweep catches unrelated churn but does not prove export links, retention focus, or detail anatomy. [CITED: 186-CONTEXT.md]

**Why it happens:** Existing e2e suite is broad enough to tempt blanket verification. [VERIFIED: codebase grep]

**How to avoid:** Amend existing focused specs with role/name assertions and only use Playwright where browser behavior matters: keyboard, focus, overflow, reconnect CSS, and route transitions. [CITED: https://playwright.dev/docs/best-practices] [CITED: 186-CONTEXT.md]

**Warning signs:** New screenshot snapshots or broad route matrices without source/LiveView/controller assertions. [CITED: 186-CONTEXT.md]

## Code Examples

Verified implementation patterns from local source and official docs:

### Component Composition With Attrs, Global Attributes, and Slots

Phoenix LiveView function components support declared attrs, slots, and global `phx-`/`aria-`/`data-` attrs; Threadline's `UI` module already uses that model. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] [VERIFIED: codebase grep]

```elixir
# Source: lib/threadline/operator_surface/ui.ex
attr(:title, :string, required: true)
slot :metadata do
  attr(:key, :string, required: true)
end
slot(:actions)
```

### Modal/Drawer Focus Helpers

LiveView JS provides focus helpers including `focus_first`, `focus`, `push_focus`, and `pop_focus`; Threadline's `UI.modal` and `UI.drawer` already compose those helpers. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveView.JS.html] [VERIFIED: codebase grep]

```elixir
# Source: lib/threadline/operator_surface/ui.ex
|> JS.focus_first(to: "##{id}-content")
|> JS.focus(to: "##{id} [data-tl-initial-focus]")
```

### LiveView Test Proof

LiveViewTest supports rendering components and asserting visible form interactions; retention tests should submit through actual visible inputs rather than bypassing form validation. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html]

```elixir
# Source pattern: Phoenix.LiveViewTest docs, applied to Phase 186 retention tests
view
|> form("#prune-confirm form", %{"confirm" => "default"})
|> render_submit()
```

### Direct Export Delivery

Plug's `send_file` is the correct local-file response primitive; Threadline's controller already sets content type/disposition/cache headers before calling it. [CITED: https://plug.hexdocs.pm/1.19.1/Plug.Conn.html] [VERIFIED: codebase grep]

```elixir
# Source: lib/threadline/operator_surface/controllers/export_controller.ex
conn
|> put_resp_header("cache-control", "no-store")
|> Plug.Conn.send_file(200, absolute_path)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Page-level trust rails and repeated CTA strips | One focused workflow verdict/summary with contextual actions | Phase 185 established this for Coverage; Phase 186 applies it to governance/export pages. [CITED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] | Reduces dense dashboard feel and aligns GOV-01. |
| Detail metadata embedded in page header | Compact H1 plus object-level `UI.detail_header` and `UI.kv` metadata | Phase 186 UI-SPEC locks this for detail surfaces. [CITED: 186-UI-SPEC.md] | Aligns Transaction, Row history, and Actor under one scan pattern. |
| LiveView mutating treatment applied broadly | Mutating buttons get reconnect affordance; HTTP download links stay focusable links | Phase 186 UI-SPEC locks completed export link semantics. [CITED: 186-UI-SPEC.md] | Fixes pointer/keyboard/AT behavior for GOV-02. |
| Custom/older subview overlays | `UI.modal` / `UI.drawer` for focus, Escape, click-away, and focus return | Phase 177 component substrate plus Phase 186 drawer decision. [VERIFIED: codebase grep] [CITED: 186-CONTEXT.md] | Reduces overlay drift and testing surface. |

**Deprecated/outdated:**

- Runtime redaction destructive UI remains out of scope and must not be introduced by copying retention prune patterns. [CITED: 186-CONTEXT.md]
- Broad screenshot matrix expansion remains out of scope; targeted browser lanes are sufficient when paired with source/LiveView/controller tests. [CITED: 186-CONTEXT.md]
- `aria-disabled`/`tabindex="-1"` on completed export downloads is explicitly outdated for Phase 186. [CITED: 186-UI-SPEC.md] [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| none | No `[ASSUMED]` claims are used in this research artifact. | All sections | None. |

## Resolved Planning Decisions

1. **RESOLVED: Row history uses `UI.drawer/1` by default, with tested parity fallback only if conversion is unsafe.**
   - Plan resolution: Executors should convert the row-history overlay to `UI.drawer/1` while preserving stable `data-testid`s, route encoding, visible close affordance, Escape behavior, focus entry, and focus return. If conversion proves unsafe during implementation, the old subview markup may remain only when LiveView/component or browser proof covers the same dialog, Escape, visible close, focus-in, and focus-return contract. [CITED: 186-UI-SPEC.md] [CITED: 186-CONTEXT.md] [VERIFIED: codebase grep]

2. **RESOLVED: Retention prefers a single visible page-level prune action.**
   - Plan resolution: The Retention page should expose one visible destructive action labelled `Run retention prune`. The row-menu prune implication should be removed or neutralized. If implementation proves a row-menu entry can remain without implying row-specific deletion, it must use the same `Run retention prune` label and open the same policy-level modal with the locked UI-SPEC copy. [CITED: 186-CONTEXT.md] [VERIFIED: codebase grep]

3. **RESOLVED: Actor kind parsing is hardened with an allowlist if the Actor page is touched.**
   - Plan resolution: Because Phase 186 touches Actor activity anatomy, `ActorLive` should replace unsafe unknown-kind fallback with a bounded allowlist/source helper and a narrow invalid-kind test. The parser must not create atoms from untrusted route input. [CITED: 186-CONTEXT.md] [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Root compile/tests | yes | 1.19.5 / Erlang OTP 28 | none needed. [VERIFIED: local command] |
| Mix | Root aliases and tests | yes | 1.19.5 | none needed. [VERIFIED: local command] |
| PostgreSQL | Ecto/LiveView/controller tests and example app | yes | psql 14.17; `pg_isready` accepting connections on `/tmp:5432` | none needed locally. [VERIFIED: local command] |
| Node.js | Example Playwright e2e | yes | v22.14.0 | none needed. [VERIFIED: local command] |
| npm | Example Playwright dependency install/run | yes | 11.1.0 | none needed. [VERIFIED: local command] |
| ripgrep | Planning/research/test discovery | yes | 15.1.0 | use shell alternatives if missing. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none detected for research/planning. [VERIFIED: local command]

**Missing dependencies with fallback:** none detected for research/planning. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest and Phoenix.ConnTest; Playwright for example browser proof. [VERIFIED: codebase grep] |
| Config file | Root `mix.exs`; example e2e config at `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/gating_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `mix verify.test`; phase gate can add `mix verify.example_browser -- operator-prove-mobile.spec.ts operator-accessibility.spec.ts operator-timeline-investigation-flow.spec.ts operator-features.spec.ts` for targeted browser proof. [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DETAIL-01 | Transaction uses H1 `Transaction`, object summary via detail header, copyable full refs, state family, and row-history pivot. | LiveView/source contract | `mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` | yes; amend existing. [VERIFIED: codebase grep] |
| DETAIL-01 | Row history standalone/subview exposes locked title/copy, dialog/drawer semantics, as-of field, Escape/close/focus-return proof, and no stable test-id churn. | LiveView + Playwright | `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs && mix verify.example_browser -- operator-accessibility.spec.ts` | yes; amend existing. [VERIFIED: codebase grep] |
| DETAIL-01 | Actor page uses H1 `Actor activity`, detail summary, `UI.kv` metadata, `UI.ref` transaction refs, and investigation-only actions. | LiveView + copy contract | `mix test test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/copy_contract_test.exs` | yes; amend existing. [VERIFIED: codebase grep] |
| GOV-01 | Evidence remains subject-grouped and shows only relevant actions, with `Carry to Exports` only when exports enabled/request valid. | LiveView + browser mobile | `mix test test/threadline/operator_surface/live/evidence_live_test.exs && mix verify.example_browser -- operator-prove-mobile.spec.ts` | yes; amend existing. [VERIFIED: codebase grep] |
| GOV-01 | Exports answers ready/preparing/attention/unavailable, uses honest recent-only caption, and removes duplicate trust rail/Open Timeline repetition. | LiveView + browser mobile | `mix test test/threadline/operator_surface/live/export_status_live_test.exs && mix verify.example_browser -- operator-prove-mobile.spec.ts` | yes; amend existing. [VERIFIED: codebase grep] |
| GOV-01 | Redaction remains configured-vs-deployed policy status with no runtime destructive flow. | LiveView + copy/style contract | `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` | yes; amend existing. [VERIFIED: codebase grep] |
| GOV-01 | Retention reads as a workflow around window health and prune consequence, not a dump of runs/metrics. | LiveView + browser mobile | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs && mix verify.example_browser -- operator-prove-mobile.spec.ts` | yes; amend existing. [VERIFIED: codebase grep] |
| GOV-02 | Completed export download links are focusable HTTP links and have no `aria-disabled`, `tabindex="-1"`, or `data-tl-mutating`; non-ready jobs expose no fake href. | LiveView + controller/auth | `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/export_auth_plug_test.exs` | yes; amend existing. [VERIFIED: codebase grep] |
| GOV-02 | Feature-gated actions/nav are omitted or routed to unsupported view, with pointer/keyboard/AT-correct disabled/unavailable states. | LiveView/source + Playwright | `mix test test/threadline/operator_surface/gating_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs && mix verify.example_browser -- operator-features.spec.ts` | yes; amend existing. [VERIFIED: codebase grep] |
| GOV-03 | Retention destructive flow keeps type-to-confirm, exact labels/copy, focus initial/restore, reconnect-safe submit affordance, mismatch hyphen copy, runtime-unavailable handling, auth re-check, secure compare, audit-before-prune, and no runtime redaction destructive UI. | LiveView + source/copy/style + Playwright | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs && mix verify.example_browser -- operator-accessibility.spec.ts operator-prove-mobile.spec.ts` | yes; amend existing. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the narrow LiveView/source/controller tests for the page touched. [CITED: 186-CONTEXT.md]
- **Per wave merge:** Run the combined quick command above plus `mix format --check-formatted` if Elixir files changed. [CITED: CLAUDE.md]
- **Phase gate:** Run `mix verify.test`; add targeted `mix verify.example_browser -- operator-prove-mobile.spec.ts operator-accessibility.spec.ts operator-timeline-investigation-flow.spec.ts operator-features.spec.ts` after UI behavior changes that require browser proof. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] Amend `test/threadline/operator_surface/live/export_status_live_test.exs` to assert completed download links have an href and lack `aria-disabled`, `tabindex`, and `data-tl-mutating`. [VERIFIED: codebase grep]
- [ ] Amend `test/threadline/operator_surface/live/retention_history_live_test.exs` and `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` for `Keep retention window` and mismatch copy `Could not prune - confirmation did not match.` [VERIFIED: codebase grep] [CITED: 186-UI-SPEC.md]
- [ ] Amend detail LiveView tests for `.tl-detail-header`/locked H1s on Transaction, Row history, and Actor. [VERIFIED: codebase grep] [CITED: 186-UI-SPEC.md]
- [ ] Amend governance tests to reject repeated trust rails and no-runtime-redaction destructive controls. [VERIFIED: codebase grep] [CITED: 186-CONTEXT.md]
- [ ] Add row-history Escape/focus-return browser assertion if `RowHistoryComponent` does not convert to `UI.drawer`. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] [VERIFIED: codebase grep]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement` to `false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Host-owned auth/on_mount assigns and `ExportAuthPlug`; Phase 186 must not weaken existing auth boundaries. [VERIFIED: codebase grep] |
| V3 Session Management | limited | Phase 186 does not change sessions; browser proof still exercises authenticated example routes through existing login. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Feature gates, unsupported view, scoped query assigns, export job actor ownership, and retention prune auth re-check. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | `FilterParams` allowlisted keys, valid export/evidence context, route params, and retention visible form submission. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | `Plug.Crypto.secure_compare/2` for retention confirmation; no hand-rolled crypto. [VERIFIED: codebase grep] |

### Known Threat Patterns for Phoenix LiveView Operator UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Export job IDOR through direct download | Elevation of Privilege / Information Disclosure | `ExportAuthPlug` plus `ExportController.download/2` actor ownership and readiness/expiration checks. [VERIFIED: codebase grep] |
| Forged LiveView export queue event | Tampering | Handler validates exports-enabled state and context before creating jobs. [VERIFIED: codebase grep] |
| Forged retention prune confirmation | Tampering / Elevation of Privilege | Server-derived canonical policy, `Plug.Crypto.secure_compare/2`, auth re-check, and audit-before-prune. [VERIFIED: codebase grep] |
| Atom table exhaustion from route/filter input | Denial of Service | Use allowlists and `String.to_existing_atom/1`; avoid unsafe atom creation if touching Actor parsing. [VERIFIED: codebase grep] |
| Disabled-looking active controls or active-looking unavailable controls | Spoofing / Tampering | Use native disabled/removed href/controller enforcement appropriate to element type; keep completed download links active and focusable. [CITED: 186-CONTEXT.md] |
| Modal marked `aria-modal` without modal behavior | Information Disclosure / UX integrity | Follow APG dialog contract: focus enters, Tab stays inside, Escape closes, visible close/cancel exists, focus returns. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/186-detail-governance-and-export-surfaces/186-CONTEXT.md` - Phase decisions, target files, test lanes, current code gaps. [CITED: local planning docs]
- `.planning/phases/186-detail-governance-and-export-surfaces/186-UI-SPEC.md` - Page anatomy, locked copy, state/control/accessibility/validation contracts. [CITED: local planning docs]
- `.planning/REQUIREMENTS.md` - DETAIL-01, GOV-01, GOV-02, GOV-03 and out-of-scope constraints. [CITED: local planning docs]
- `CLAUDE.md` - project constraints, commands, optional dependency posture, domain split. [CITED: local project docs]
- Target source files under `lib/threadline/operator_surface/**` - current implementation state, reusable primitives, gaps. [VERIFIED: codebase grep]
- Target tests under `test/threadline/operator_surface/**` and `examples/threadline_phoenix/e2e/tests/**` - validation lanes and existing coverage. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Phoenix LiveView 1.1.30 `Phoenix.Component` docs - function components, attrs, slots, global attributes. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]
- Phoenix LiveView 1.1.30 `Phoenix.LiveView.JS` docs - JS utilities, focus helpers, push/focus/pop focus behavior. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveView.JS.html]
- Phoenix LiveView 1.1.30 `Phoenix.LiveViewTest` docs - rendered component/live/form assertions. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html]
- Plug 1.19.1 `Plug.Conn` docs - `send_file` response behavior. [CITED: https://plug.hexdocs.pm/1.19.1/Plug.Conn.html]
- WAI-ARIA APG Dialog Modal Pattern - dialog keyboard/focus/name expectations. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]
- Playwright Best Practices - role/user-facing locators and resilient e2e tests. [CITED: https://playwright.dev/docs/best-practices]

### Tertiary (LOW confidence)

- None. No web-only or training-only claims are used as recommendations. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - existing locked dependencies and local versions were verified with `mix deps`, `elixir --version`, `node --version`, and `npm --version`. [VERIFIED: local command]
- Architecture: HIGH - target ownership is derived from existing router/auth/LiveView/controller/source boundaries. [VERIFIED: codebase grep]
- Pitfalls: HIGH - each major pitfall maps to current source, UI-SPEC decisions, or existing tests. [VERIFIED: codebase grep] [CITED: 186-UI-SPEC.md]
- External framework/a11y docs: MEDIUM - official docs were fetched through web fallback after the Context7 MCP provider was unavailable in this runtime. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]

**Research date:** 2026-06-30
**Valid until:** 2026-07-30 for local implementation guidance; re-check official docs if LiveView/Plug/Playwright versions change. [VERIFIED: mix deps]
