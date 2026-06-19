# Phase 179: Microcopy & Information-Architecture Sweep - Research

**Researched:** 2026-06-19
**Domain:** Phoenix LiveView operator-surface microcopy, IA, state-copy contracts, and GOV.UK-style progressive disclosure
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

The following locked decisions and deferred items are copied from `.planning/phases/179-microcopy-information-architecture-sweep/179-CONTEXT.md`. [VERIFIED: local docs]

### Locked Decisions

## Implementation Decisions

### Navigation and task language
- **D-01:** Use a hybrid IA: **task-led Home, domain-led shell nav**. Keep routes, URL shapes, LiveView modules, and `current` atoms stable. Update visible labels only. Home should speak in user jobs, e.g. "Find what changed", "Check audit readiness", and "Use evidence and exports". The shell nav should use durable buckets: `Overview`, `Investigate` (Timeline), `Audit readiness` (Coverage), and `Evidence & exports` (Evidence, Redaction, Retention, Exports). Keep individual destination nouns visible so Redaction/Retention do not disappear under the group heading.
- **D-02:** Retire broad `Find / Verify / Prove` as the shell's primary grouping language. `Prove` overclaims when it covers redaction, retention, and exports; `Verify` is ambiguous outside the coverage page. Reserve `Proven`, `Inferred`, and `Unsupported` for evidence verdicts, not global IA promises.
- **D-03:** Preserve the Overview entry and page routes. The IA sweep must not break existing Playwright route/nav tests or adopter bookmarks. If tests assert old group labels, update those assertions in the same change as the shell copy.

### Domain terminology rules
- **D-04:** Use **hybrid layered vocabulary**. Visible UI copy uses plain operator nouns; exact Threadline model names appear where precision helps: advanced details, docs, tooltips/titles, ARIA labels, code-ish field labels, error details, and first-use explanatory copy. Avoid leaking CamelCase into primary headings/buttons.
- **D-05:** Apply this glossary consistently:
  - `AuditTransaction` -> "transaction" or "database transaction"; never imply it is the same as a request.
  - `AuditChange` -> "change" or "row-level change"; use "captured change" when capture guarantee matters.
  - `AuditAction` -> "action" or "semantic action"; distinguish it from row changes.
  - `ActorRef` -> "actor" in normal UI; "actor reference" in validation/tooltips/errors when the reference shape matters.
  - `Correlation` -> "correlation id"; explain as the thread that connects request/job/integration activity.
  - row history/as-of -> "Row history" and "Snapshot as of".
  - redaction drift -> "Redaction drift detected".
  - retention window -> always include permanent deletion / pruning consequence when action or trust depends on it.
  - evidence proof -> "Evidence" in navigation and overview; "proof history" only for the append-only evidence detail/history view.
- **D-06:** Keep all visible copy sentence case except fixed domain/code tokens and operation badges (`INSERT`, `UPDATE`, `DELETE`). Replace title-case leaks such as "Invalid Actor Reference", "Action Denied", "Unsupported View", and hyphenated alert titles like "Transaction Not Found - ..." with brand-compliant sentence-case copy.

### State, validation, warning, success, and destructive copy
- **D-07:** Use **controlled templates with page-specific domain slots**. Do not build a global copy DSL. Keep repeated state grammar in existing internal components/helpers (`UI.data_state/1`, `UI.empty_state/1`, `UI.error_state/1`, `UI.stale_banner/1`, `Unsupported.descriptor/1`, `Presentation.status_label/1`) and leave page-specific wording near the LiveView that owns the workflow.
- **D-08:** Required copy templates:
  - Validation error: "Enter/select/fix {field label}..." and keep the field label language aligned with the error text.
  - Error: "Could not {load/queue/export/prune} {object}. {Known cause if safe}. {Next action}."
  - Empty first-run: "No {object} yet. {How this becomes populated}."
  - No-data from filters: "No {objects} match these filters. Clear {filter} or widen {time range}."
  - Permission: "You do not have access to this {object}. The {object} exists; your account needs `{capability}`."
  - Unavailable: "{Object} is temporarily unavailable. This is not a permissions issue. Retry, then check {surface/logs}."
  - Redacted/pruned unavailable: state what happened and explicitly say it is not permissions.
  - Stale: "Could not refresh - showing last known {object} from {timestamp}. Retry."
  - Warning: "{Risk} detected. {Consequence}. {Fix before relying on {surface}}."
  - Success/status: "{Object/action} {queued/started/completed}. {Where to follow it or what stays linked}."
  - Destructive modal: "{Action} {object} permanently? This permanently {consequence}. Type `{object identifier}` to confirm." Button label names the consequence, not generic "Continue".
- **D-09:** ARIA roles follow severity, not color. Use `role="alert"` for immediate errors and permission/unavailable states that require attention. Use `role="status"` for loading, stale, success, neutral progress, and routine empty/no-data states. Validation summaries should receive focus and link to affected controls when form validation spans multiple fields.
- **D-10:** Keep exact-value copy affordances strict from Phase 176: displayed/truncated values can be short, but copy targets and zero-JS fallback must expose the full value. This is part of microcopy because "Copy" must never imply a truncated forensic value.

### Progressive disclosure and density
- **D-11:** Use a **layered context budget**. Keep one-line page ledes when they change operator judgment; keep trust rails only where risk/governance is central (Coverage, Evidence, Redaction, Retention, Exports handoff). Dense investigation paths such as Timeline should put filters/results/actions first and demote explanatory legends below the working surface.
- **D-12:** Remove or compress repeated journey prose that competes with primary work. The Timeline legend (`FIND / EXPLAIN / PACKAGE`) is a candidate for sentence-case compression or removal after its value is covered by Home and utility actions. Do not use all-caps instructional prose except operation badges.
- **D-13:** Do not add a user-selectable novice/expert or help/density mode in this phase. That adds state, URL/reconnect semantics, copy variants, and test matrix breadth without current adopter evidence.
- **D-14:** Disclosures must be recoverable and least-surprise. Advanced filter disclosure can open based on active URL params; shareable/recoverable view state stays in URL via `patch` / `handle_params`. Do not hide destructive consequences, permission/no-data/unavailable distinctions, or copyable full IDs inside optional disclosure.

### Implementation and verification posture
- **D-15:** No route churn, dependency churn, public API, or LiveComponent extraction for copy organization. Prefer existing function components, `attr`/`slot` declarations, and small helpers in current modules.
- **D-16:** Add copy-contract coverage rather than relying on screenshots. Planners should include tests that scan rendered operator pages and/or source for: banned vague words, exclamation marks, title-case state headings, old `Find / Verify / Prove` group labels if replaced, exact glossary mappings, ARIA role mismatches for state copy, and the absence of visible CamelCase in primary UI.
- **D-17:** Stress-route evidence should include copy states. If Phase 178 page stories already render the relevant paths, update those stories and ledger/projection only as needed to reflect copy/IA state, not to add new UI capabilities.

### Reviewed Todos
- **coverage-schema-card-declutter** was matched at low confidence for Phase 179 but is already folded into and completed by Phase 176 DATA-05. Do not fold it into this phase.

### the agent's Discretion

None found in `179-CONTEXT.md`. [VERIFIED: local docs]

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Persistent novice/expert help or density mode - defer until real adopter research proves the split is needed.
- Full i18n or externalized copy registry - defer; not needed for this internal operator surface and would add architecture weight.
- New operator capabilities, new filters, new export workflows, or new evidence/retention/redaction features - defer to separate phases if needed.
- Formal accessibility/motion/adversarial closeout - Phase 180.

### Reviewed Todos (not folded)
- `coverage-schema-card-declutter.md` - already realized by Phase 176 DATA-05; no Phase 179 action.

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COPY-01 | All UI copy follows the brand voice and avoids banned vocabulary; error/empty/success/warning/destructive copy follows the documented patterns. [VERIFIED: `.planning/REQUIREMENTS.md`] | Use brandbook voice rules, D-07/D-08 state templates, and copy-contract tests scanning rendered output for banned phrases, exclamation marks, title-case state leaks, and generic state copy. [VERIFIED: local docs] |
| COPY-02 | Domain language is used consistently across headings/tabs/filters/buttons/alerts. [VERIFIED: `.planning/REQUIREMENTS.md`] | Apply the Phase 179 glossary to shell/Home, LiveView page copy, `Presentation`, `Unsupported`, and stress fixtures; keep exact model names only in advanced/tooling/error contexts. [VERIFIED: local docs] |
| COPY-03 | IA follows least-surprise and progressive disclosure while preserving power-user efficiency. [VERIFIED: `.planning/REQUIREMENTS.md`] | Preserve routes/current atoms/URL params/copyable IDs; relabel only visible IA; keep Timeline dense; remove or compress repeated Timeline journey prose; test mobile nav and e2e earned flows. [VERIFIED: codebase grep] |

</phase_requirements>

## Summary

Phase 179 is a copy/IA sweep over a stable Phoenix LiveView operator surface, not a feature phase: Phase 178 completed the 11-page stress pass, shared shell adoption, and reconnect selector correction. [VERIFIED: `.planning/phases/178-per-page-flow-stress-pass-all-11-pages/178-VERIFICATION.md`] The implementation should concentrate on visible labels, state copy, domain terminology, and validation guards while preserving routes, LiveView modules, `current` atoms, URL-driven state, full-value copy targets, and dense power-user workflows. [VERIFIED: `179-CONTEXT.md`]

The highest-risk hotspots are already visible in code and tests: shell groups still render `Find`, `Verify`, and `Prove`; Home cards mirror those labels; Timeline still has an all-caps `FIND / EXPLAIN / PACKAGE` legend; unsupported/error states contain title-case leaks; Evidence and Exports use broad "proof" language outside the allowed append-only history context; and tests assert several old labels. [VERIFIED: codebase grep] GOV.UK guidance supports this phase's least-surprise posture: UI copy should be short and direct, key words should come first, links should clearly describe destinations, details/disclosures should only hide information some users need, and validation errors should be field-linked and focused. [CITED: https://www.gov.uk/service-manual/design/writing-for-user-interfaces] [CITED: https://design-system.service.gov.uk/components/details/] [CITED: https://design-system.service.gov.uk/patterns/validation/]

**Primary recommendation:** Plan this as a guard-first editorial refactor: add copy-contract tests, relabel shell/Home IA without route churn, normalize state/error/domain copy through existing helpers, update Evidence/Exports proof terminology, preserve dense Timeline utilities, then update targeted ExUnit and Playwright tests. [VERIFIED: codebase grep]

## Project Constraints

`AGENTS.md` is not present at the repository root, so no additional project-specific agent directives were found. [VERIFIED: `ls AGENTS.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Shell IA and route-visible navigation labels | Browser / Client rendering in LiveView templates | Frontend Server (LiveView render) | Labels are rendered in `SurfaceHeader.surface_header/1`; routes and `current` atoms stay stable while visible copy changes. [VERIFIED: `lib/threadline/operator_surface/components/surface_header.ex`] |
| Home task-card IA | Browser / Client rendering in `StartLive` | API / Backend for saved views/export counts | The Home page text and task grouping live in `start_live.ex`; data counts are already supplied by existing repo queries. [VERIFIED: `lib/threadline/operator_surface/live/start_live.ex`] |
| State, validation, empty, warning, success, destructive copy | Frontend Server (LiveView/components) | Browser for focus/ARIA behavior | Repeated state grammar lives in `UI.data_state/1`, `UI.error_summary/1`, `Unsupported.descriptor/1`, and page LiveViews; validation summary focus is a browser-facing behavior. [VERIFIED: `lib/threadline/operator_surface/ui.ex`] |
| Domain terminology | Frontend Server (presentation helpers and LiveViews) | Database / Storage only as source data | Labels are generated by `Presentation` helpers and LiveView templates; no database schema or capture semantics change is in scope. [VERIFIED: `lib/threadline/operator_surface/presentation.ex`] |
| Progressive disclosure and power-user efficiency | Browser / Client rendered controls | Frontend Server URL state | Timeline advanced filters already open from active URL params, and export/evidence handoff state is URL-driven; Phase 179 should preserve those mechanics. [VERIFIED: `lib/threadline/operator_surface/live/timeline_live.ex`] |
| Copy-contract verification | Test tier | Browser e2e for rendered accessibility | ExUnit can scan component/page render output; Playwright should verify mobile nav, accessible names, and earned-flow labels after relabeling. [VERIFIED: test tree scan] |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Compile, run ExUnit, and execute project aliases. [VERIFIED: `elixir --version`, `mix --version`] | Existing project test and CI commands are Mix aliases, including `mix ci.all`. [VERIFIED: `mix.exs`] |
| Phoenix LiveView / LiveViewTest | Existing project dependency | Render and assert LiveView UI copy and navigation behavior. [VERIFIED: test imports] | Current operator-surface tests use `Phoenix.LiveViewTest` for rendered copy contracts. [VERIFIED: `test/threadline/operator_surface/surface_header_test.exs`] |
| Playwright | 1.60.0 locally via `npx playwright --version` | Browser validation for mobile nav, accessible names, dense surfaces, and earned flows. [VERIFIED: local command] | Existing e2e suite is Playwright with mobile and desktop projects. [VERIFIED: `examples/threadline_phoenix/e2e/playwright.config.ts`] |
| Existing operator helpers | Current codebase | Shared copy and rendering primitives: `UI.page_header/1`, `UI.data_state/1`, `UI.error_summary/1`, `UI.ref/1`, `Unsupported.descriptor/1`, `Presentation.status_label/1`. [VERIFIED: codebase grep] | Locked D-07/D-15 require controlled templates in existing helpers, not new copy architecture. [VERIFIED: `179-CONTEXT.md`] |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `lazy_html` | `~> 0.1.0` in `mix.exs` | Parse/render HTML in tests where string assertions are too brittle. [VERIFIED: `mix.exs`] | Use for copy-contract tests that need visible text extraction or role/link checks without broad regex false positives. [VERIFIED: test dependency scan] |
| `examples/threadline_phoenix/e2e/run-e2e.sh` | Project script | Starts/seeds example Phoenix app and runs Playwright. [VERIFIED: `examples/threadline_phoenix/e2e/run-e2e.sh`] | Use for browser proof after shell/Home/Evidence/Exports labels change. [VERIFIED: local script scan] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing helpers and page-local copy | New global copy DSL or CMS | Rejected by D-07/D-15; it would add architecture and state for an internal operator surface. [VERIFIED: `179-CONTEXT.md`] |
| Rendered ExUnit copy contracts | Screenshot-only verification | Rejected by D-16 because screenshots are weak for banned words, exact glossary terms, ARIA roles, and hidden copy. [VERIFIED: `179-CONTEXT.md`] |
| Route-preserving relabel | New route groups or renamed atoms | Rejected by D-01/D-03 because adopter bookmarks and tests depend on current routes and `current` atoms. [VERIFIED: `179-CONTEXT.md`] |

**Installation:** No new install command is recommended; Phase 179 should add zero runtime dependencies and no new test packages. [VERIFIED: `.planning/REQUIREMENTS.md`]

```bash
# No package installation for Phase 179.
```

**Version verification:** Local runtime probes returned Elixir 1.19.5, Mix 1.19.5, Node v22.14.0, npm 11.1.0, and Playwright 1.60.0. [VERIFIED: local commands]

## Package Legitimacy Audit

No external packages are recommended or installed for Phase 179, so the Package Legitimacy Gate is not applicable. [VERIFIED: `.planning/REQUIREMENTS.md`] Package removals due to `[SLOP]`: none. Packages flagged `[SUS]`: none.

## Architecture Patterns

### System Architecture Diagram

```text
Operator opens /audit route
  -> Phoenix router / existing LiveView module
  -> UI.shell/1 wraps page and SurfaceHeader.surface_header/1 renders shell IA
  -> Page LiveView renders page-local headings, ledes, filters, actions, states
  -> Presentation / Unsupported / UI helpers normalize repeated labels and state grammar
  -> Browser sees visible copy, ARIA roles/names, disclosures, copy buttons
  -> ExUnit rendered-copy contracts + Playwright mobile/e2e flows verify copy and IA

Decision points:
  - Is copy repeated state grammar? Use UI/Unsupported/Presentation helper.
  - Is copy workflow-specific? Keep near owning LiveView.
  - Is exact model precision required? Allow CamelCase only in advanced/tooling/error contexts.
  - Is disclosure optional? Keep advanced URL state recoverable and never hide destructive/permission/full-ID facts.
```

### Recommended Project Structure

```text
lib/threadline/operator_surface/
├── components/surface_header.ex      # Shell IA visible labels only; preserve hrefs/current atoms.
├── ui.ex                             # Repeated page/state/error/ref/validation templates.
├── presentation.ex                   # Shared status, operation, filter, export, and coverage labels.
├── unsupported.ex                    # Unsupported/denied descriptors.
├── components/unsupported_view.ex    # Shared unsupported view rendering.
├── live/*.ex                         # Page-owned headings, ledes, trust rails, task/action copy.
└── stress_fixtures.ex                # Stress story labels and copy-state evidence when rendered.

test/threadline/operator_surface/
├── copy_contract_test.exs            # Recommended Wave 0 guard for banned vocabulary/glossary/case.
├── surface_header_test.exs           # Shell IA labels and preserved nav contracts.
├── ui_test.exs                       # State, validation, role, and copy helper contracts.
└── live/*_test.exs                   # Page-level rendered copy.

examples/threadline_phoenix/e2e/tests/
├── operator-home-nav-mobile.spec.ts  # Mobile shell/Home IA.
├── operator-prove-mobile.spec.ts     # Rename/retarget Evidence & exports cluster checks.
├── operator-earned-flows.spec.ts     # Timeline/Evidence handoff copy and routes.
└── operator-accessibility.spec.ts    # Accessible names and focus-sensitive labels.
```

### Pattern 1: Guard-First Copy Contracts

**What:** Add rendered/source copy guards before relabeling so failures identify the exact vocabulary leak. [VERIFIED: `179-CONTEXT.md`]

**When to use:** Use for banned vocabulary, exclamation marks, title-case state leaks, broad `Find / Verify / Prove` labels, forbidden CamelCase in primary UI, and severity role checks. [VERIFIED: `179-CONTEXT.md`]

**Example:**

```elixir
# Source: local project pattern from style/doc contract tests.
test "operator primary UI avoids retired IA labels" do
  html = render_surface()

  refute html =~ ~r/>\s*(Find|Verify|Prove)\s*</
  assert html =~ "Investigate"
  assert html =~ "Audit readiness"
  assert html =~ "Evidence & exports"
end
```

### Pattern 2: Copy Changes Stay Near the Owner

**What:** Put shared state grammar in `UI`, `Unsupported`, or `Presentation`, and keep workflow-specific copy in the owning LiveView. [VERIFIED: `179-CONTEXT.md`]

**When to use:** Use helpers for repeated empty/error/status variants; use page modules for Timeline filters, Evidence context, retention prune warnings, and page ledes. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/ui.ex and unsupported.ex
<UI.data_state state={:permission} object="evidence record" capability="threadline:evidence:read" />

# Page-specific wording remains local where workflow semantics are clearest.
<:lede>Changes captured together in one database transaction.</:lede>
```

### Pattern 3: URL State Is the Progressive Disclosure Contract

**What:** Disclosures may hide advanced controls only when the same state remains recoverable through URL params and `handle_params`. [VERIFIED: `timeline_live.ex`]

**When to use:** Preserve Timeline advanced filters, Evidence history mode, Exports handoff params, and row-history as-of links. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/live/timeline_live.ex
<details open={@advanced_filters_active?}>
  ...
</details>
```

### Anti-Patterns to Avoid

- **New copy DSL:** D-07/D-15 reject a global copy architecture; use existing helpers and page-local wording. [VERIFIED: `179-CONTEXT.md`]
- **Route or atom rename:** D-01/D-03 require visible-label-only IA changes; keep paths, modules, and `current` atoms stable. [VERIFIED: `179-CONTEXT.md`]
- **Source-only grep with no rendered coverage:** Source scans catch leaks but can false-positive comments/tests; pair with rendered ExUnit and Playwright checks. [VERIFIED: codebase grep]
- **Hiding critical facts in disclosures:** D-14 forbids hiding destructive consequences, permission/no-data/unavailable distinctions, or full IDs. [VERIFIED: `179-CONTEXT.md`]
- **Broad "proof" language outside allowed contexts:** D-02/D-05 reserve proof terms for evidence verdict/history contexts, not global IA or export handoff labels. [VERIFIED: `179-CONTEXT.md`]

## Current Copy / IA Hotspots

| Cluster | Files | Current Finding | Phase 179 Action |
|---------|-------|-----------------|------------------|
| Shell IA | `lib/threadline/operator_surface/components/surface_header.ex:57` | Shell groups render `Find`, `Verify`, and `Prove`; tests assert those labels. [VERIFIED: codebase grep] | Relabel to `Investigate`, `Audit readiness`, and `Evidence & exports`; preserve `Overview`, links, `data-testid`s, route paths, and `current` atoms. [VERIFIED: `179-CONTEXT.md`] |
| Home task cards | `lib/threadline/operator_surface/live/start_live.ex:152` | Home cards mirror `Find / Verify / Prove`, including `Prove and export`; comments also contain retired labels. [VERIFIED: codebase grep] | Use D-01 task jobs: `Find what changed`, `Check audit readiness`, `Use evidence and exports`; update comments or avoid source-scan false positives. [VERIFIED: `179-CONTEXT.md`] |
| Shell/Home tests | `test/threadline/operator_surface/surface_header_test.exs:34`, `start_live_test.exs:262`, `operator-home-nav-mobile.spec.ts:109` | ExUnit and Playwright assert old IA labels. [VERIFIED: codebase grep] | Update assertions in the same slice as relabeling so route tests continue proving stable paths. [VERIFIED: `179-CONTEXT.md`] |
| Timeline dense workflow | `lib/threadline/operator_surface/live/timeline_live.ex:447` | Timeline still renders all-caps `FIND / EXPLAIN / PACKAGE` journey prose after filters/results/actions. [VERIFIED: codebase grep] | Remove or compress to sentence case; keep filters/results/actions first and preserve advanced-filter URL behavior. [VERIFIED: `179-CONTEXT.md`] |
| Unsupported/denied states | `unsupported.ex:4`, `unsupported.ex:48`, `unsupported_view.ex:8` | Shared descriptors contain `Unsupported View` and `Action Denied`. [VERIFIED: codebase grep] | Replace with sentence-case, object-specific copy through `Unsupported.descriptor/1` and `UnsupportedView`. [VERIFIED: `179-CONTEXT.md`] |
| Transaction and actor errors | `transaction_live.ex:102`, `actor_live.ex:106` | Rendered state copy contains `Transaction Not Found - ...` and `Invalid Actor Reference`. [VERIFIED: codebase grep] | Convert to sentence-case D-08 templates and route through existing state/error helpers where practical. [VERIFIED: `179-CONTEXT.md`] |
| Generic state copy | `ui.ex:681`, `ui.ex:822`, `ui.ex:827`, `row_history_component.ex:206` | Shared UI includes generic `Could not load this data`, `Nothing here yet`, and `Unable to render this snapshot.` [VERIFIED: codebase grep] | Slot object-specific copy and use D-08 state grammar; keep role mapping aligned with severity. [VERIFIED: `179-CONTEXT.md`] |
| Evidence overview | `evidence_live.ex:68`, `evidence_live.ex:78`, `evidence_live.ex:134` | Evidence overview/trust rail uses broad `prove`, `Proof chain`, and `proof state`. [VERIFIED: codebase grep] | Use `Evidence` in navigation/overview and keep `Open proof history` only for append-only detail/history. [VERIFIED: `179-CONTEXT.md`] |
| Exports evidence handoff | `export_status_live.ex:202`, `export_status_live.ex:204`, `export_status_live.ex:215`, `export_status_live.ex:546` | Exports labels say `Evidence proof context`, `Proof handoff`, `Reopen Evidence proof`, and `Unsupported Evidence proof context parameter`. [VERIFIED: codebase grep] | Rename to evidence context/handoff language unless the link specifically opens proof history. [VERIFIED: `179-CONTEXT.md`] |
| Redaction/retention trust rails | `policy_redaction_live.ex:94`, `retention_history_live.ex:81`, `retention_history_live.ex:240` | Redaction says `latest proof record`; retention success/status/table labels have copy-contract opportunities. [VERIFIED: codebase grep] | Use evidence-record language, add follow-up location to success copy, and enforce sentence-case table labels where visible. [VERIFIED: `179-CONTEXT.md`] |
| Stress route | `stress_fixtures.ex:44`, `stress_fixtures.ex:92`, `stress_live.ex:88` | Stress story labels include unsupported/status scenarios and page-state copy that can expose final wording. [VERIFIED: codebase grep] | Update only if rendered stories or ledger/projection evidence changes; do not add capabilities. [VERIFIED: `179-CONTEXT.md`] |

## Recommended Plan Slices

1. **Wave 0 copy-contract guards.** Add `test/threadline/operator_surface/copy_contract_test.exs` or equivalent focused tests before copy edits: scan rendered shell/Home/pages for banned vocabulary, exclamation marks, retired IA labels, forbidden CamelCase in primary UI, title-case state leaks, glossary mismatches, and ARIA role mismatches. [VERIFIED: `179-CONTEXT.md`]
2. **Shell and Home IA relabel.** Update `surface_header.ex` and `start_live.ex` visible labels only; preserve `href`s, `data-testid`s, `current` atoms, LiveView modules, and routes; update `surface_header_test.exs`, `start_live_test.exs`, and `operator-home-nav-mobile.spec.ts`. [VERIFIED: codebase grep]
3. **State/error/unsupported template normalization.** Fix `Unsupported.descriptor/1`, `UnsupportedView`, `UI.data_state/1`, `TransactionLive`, `ActorLive`, and `RowHistoryComponent` copy using D-08 templates and severity roles. [VERIFIED: codebase grep]
4. **Domain terminology sweep.** Normalize Evidence, Exports, Redaction, Retention, Coverage, Actor, Transaction, and Row history copy; keep `Proven/Inferred/Unsupported` verdict labels and `Open proof history` only where allowed. [VERIFIED: `179-CONTEXT.md`]
5. **Progressive-disclosure cleanup.** Remove or compress Timeline's all-caps legend; keep advanced details open when active params exist; preserve direct links, copyable refs, and dense utility actions. [VERIFIED: `timeline_live.ex`]
6. **Stress and browser evidence.** Refresh stress story labels/projection only when rendered copy changed, then run targeted ExUnit and Playwright suites that cover shell/Home, Evidence/Exports handoff, accessibility labels, and stress route rendering. [VERIFIED: Phase 178 summaries]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Copy organization | Global copy registry, DSL, CMS, or i18n layer | Existing `UI`, `Unsupported`, `Presentation`, and page-local templates | D-07/D-15 explicitly reject new copy architecture for this phase. [VERIFIED: `179-CONTEXT.md`] |
| Navigation grouping | New routes, route aliases, renamed atoms, or new LiveViews | Visible label changes in `SurfaceHeader.surface_header/1` | Routes/bookmarks/tests must remain stable. [VERIFIED: `179-CONTEXT.md`] |
| State components | New LiveComponents for copy variants | Existing function components with attrs/slots | Current codebase pattern and D-15 prefer function components and small helpers. [VERIFIED: codebase grep] |
| Accessibility validation | Visual review or screenshots only | Rendered ExUnit + Playwright role/name/focus checks | GOV.UK validation guidance requires linked/focused errors, and D-16 requires copy-contract tests. [CITED: https://design-system.service.gov.uk/patterns/validation/] |
| Clipboard/copy behavior | Shortened copy target or JS-only affordance | Existing `UI.ref/1` with full `data-tl-copy` | Phase 176 exact-value guarantee requires full copy targets. [VERIFIED: `179-CONTEXT.md`] |

**Key insight:** The hard part is not writing better strings; it is preventing copy drift from reintroducing overclaims, vague state copy, route-breaking IA labels, and truncated forensic values after the sweep. [VERIFIED: codebase grep]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Saved views store user-provided names and filter/query state; they do not store shell group labels. [VERIFIED: `start_live.ex`, `timeline_live.ex`] | No migration. Do not rewrite user-created saved view names; preserve URL/filter semantics. [VERIFIED: codebase grep] |
| Live service config | No external live service configuration was found for shell labels or page IA in the provided files. [VERIFIED: repository scan] | None. Keep routes stable so any external bookmarks continue working. [VERIFIED: `179-CONTEXT.md`] |
| OS-registered state | No OS-level registrations are implicated by UI copy relabeling. [VERIFIED: phase scope] | None. [VERIFIED: phase scope] |
| Secrets/env vars | No secret or env var names are implicated by visible copy/IA relabeling. [VERIFIED: phase scope] | None. [VERIFIED: phase scope] |
| Build artifacts | Stress ledger/projection files may embed story labels or rendered copy evidence when stress stories are changed. [VERIFIED: `stress_fixtures.ex`, `stress_ledger_test.exs`] | Refresh only if Phase 179 changes rendered stress stories; do not treat this as a data migration. [VERIFIED: `179-CONTEXT.md`] |

**Nothing found in category:** Runtime user-data migration is not required; this phase is visible-copy relabeling plus test updates. [VERIFIED: phase scope]

## Common Pitfalls

### Pitfall 1: Relabeling Routes Instead of Labels

**What goes wrong:** A task changes paths, `current` atoms, test IDs, or module names while replacing `Find / Verify / Prove`. [VERIFIED: `179-CONTEXT.md`]

**Why it happens:** The old group words are mixed into test descriptions, IDs, CSS comments, and visible labels. [VERIFIED: codebase grep]

**How to avoid:** Treat route and atom stability as acceptance criteria; visible labels can change, structural identifiers should remain unless a test-only description is clearly safe to rename. [VERIFIED: `179-CONTEXT.md`]

**Warning signs:** Playwright route/nav tests fail on `href`, `aria-current`, `data-testid`, or URL assertions rather than text assertions. [VERIFIED: e2e test scan]

### Pitfall 2: Overbroad Source Scans

**What goes wrong:** A banned-word test fails on comments, test names, CSS historical comments, or allowed model names rather than user-visible copy. [VERIFIED: codebase grep]

**Why it happens:** Source contains legitimate `ActorRef`, `AuditTransaction`, CSS comments, and test descriptions. [VERIFIED: codebase grep]

**How to avoid:** Prefer rendered HTML scans for primary UI copy; source scans should use explicit file scopes and allowlists for code tokens, tests, comments, and advanced/tooling contexts. [VERIFIED: local test patterns]

**Warning signs:** A copy-contract test reports `ActorRef` from `session_plug.ex` or test setup instead of a visible heading/button/alert. [VERIFIED: codebase grep]

### Pitfall 3: Removing Power-User Affordances While Simplifying Copy

**What goes wrong:** Progressive-disclosure cleanup removes direct filters, export links, copy buttons, or full-value targets. [VERIFIED: Phase 176/179 context]

**Why it happens:** Editorial simplification can be mistaken for feature simplification. [VERIFIED: `179-CONTEXT.md`]

**How to avoid:** Keep dense Timeline controls, `data-tl-copy`, direct links, and URL-state behavior; only remove redundant explanatory prose. [VERIFIED: codebase grep]

**Warning signs:** Tests for `data-tl-copy`, `Copy correlation id`, carried query params, or earned-flow links start failing. [VERIFIED: `timeline_live_test.exs`, e2e scan]

### Pitfall 4: Treating Permission, No-Data, Unavailable, Redacted, and Pruned as One Empty State

**What goes wrong:** Copy says "nothing found" when an object exists but access is denied, temporarily unavailable, redacted, or pruned. [VERIFIED: `179-CONTEXT.md`]

**Why it happens:** Generic `empty_state` copy is convenient but loses audit truth. [VERIFIED: `ui.ex`]

**How to avoid:** Use D-08 templates and role severity; keep permission/unavailable/redacted/pruned states distinct in `UI.data_state/1` and page copy. [VERIFIED: `179-CONTEXT.md`]

**Warning signs:** A page renders `Nothing here yet` or `Could not load this data` without naming the object or cause. [VERIFIED: codebase grep]

## Code Examples

### Rendered Copy Guard

```elixir
# Source: existing ExUnit + LiveViewTest style in test/threadline/operator_surface/*_test.exs
test "state headings are sentence case and object-specific" do
  html = render_error_state()

  refute html =~ "Unsupported View"
  refute html =~ "Action Denied"
  refute html =~ "Invalid Actor Reference"
  assert html =~ "Unsupported view"
  assert html =~ "You do not have access"
end
```

### Role-Severity Guard

```elixir
# Source: Phase 179 D-09 and UI.error_summary/1 pattern
test "permission and unavailable states use alert while routine empty states use status" do
  assert render_state(:permission) =~ ~s(role="alert")
  assert render_state(:unavailable_down) =~ ~s(role="alert")
  assert render_state(:no_data) =~ ~s(role="status")
  assert render_state(:empty) =~ ~s(role="status")
end
```

### Full Copy Target Guard

```elixir
# Source: Phase 176 exact-copy guarantee carried by UI.ref/1
test "correlation copy target keeps the full value" do
  full = "corr_" <> String.duplicate("abcdef1234567890", 8)
  html = render_ref(full)

  assert html =~ ~s(data-tl-copy="#{full}")
  assert html =~ ~s(aria-label="Copy correlation id")
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad shell buckets like `Find / Verify / Prove` | Task-led Home and domain-led shell groups | Locked for Phase 179 on 2026-06-19 [VERIFIED: `179-CONTEXT.md`] | Avoids overpromising and keeps durable destination nouns visible. [VERIFIED: `179-CONTEXT.md`] |
| All-caps instructional journey prose | Short sentence-case labels with work surface first | GOV.UK UI writing guidance favors short, direct UI copy and key words first. [CITED: https://www.gov.uk/service-manual/design/writing-for-user-interfaces] | Timeline can stay dense while explanatory text stops competing with filters/results/actions. [VERIFIED: `179-CONTEXT.md`] |
| Optional details hiding important facts | Details only for information some users need | GOV.UK details guidance warns against hiding information most users need. [CITED: https://design-system.service.gov.uk/components/details/] | Destructive consequences, permission/no-data distinctions, and full IDs must stay visible. [VERIFIED: `179-CONTEXT.md`] |
| Generic validation/error copy | Field-linked errors and focused summaries for multi-field validation | GOV.UK validation guidance recommends returning users to the page, using a summary, and linking to fields. [CITED: https://design-system.service.gov.uk/patterns/validation/] | `UI.error_summary/1` should remain linked and gain/retain focus behavior where multi-field validation appears. [VERIFIED: `ui.ex`] |

**Deprecated/outdated:**

- `Find / Verify / Prove` as shell group language is deprecated for Phase 179 and should not appear as primary group labels after the sweep. [VERIFIED: `179-CONTEXT.md`]
- `Unsupported View`, `Action Denied`, `Invalid Actor Reference`, and `Transaction Not Found - ...` are explicit title-case leaks to replace. [VERIFIED: `179-CONTEXT.md`]
- `proof` language is deprecated in global IA and overview/handoff labels; keep it only for evidence verdict/history contexts specified by D-02/D-05. [VERIFIED: `179-CONTEXT.md`]

## Assumptions Log

All substantive recommendations in this research are based on local project files, codebase scans, local tool probes, or cited official GOV.UK documentation. [VERIFIED: local docs] No `[ASSUMED]` claims are intentionally used.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | No assumed claims logged. | — | — |

## Open Questions

1. **Should source scans include comments and test descriptions?**
   - What we know: Comments/tests currently contain retired terms such as `Find`, `Verify`, `Prove`, and test names like "operator Prove cluster". [VERIFIED: codebase grep]
   - What's unclear: Whether the final copy-contract should ban these terms only in rendered UI or also in source comments/test names. [VERIFIED: codebase grep]
   - Recommendation: Rendered UI must be strict; source scans should either exclude comments/tests or explicitly update historical labels in touched files to avoid noisy failures. [VERIFIED: local test patterns]

2. **Should `Proof` remain in CSS/test vocabulary unrelated to Evidence history?**
   - What we know: The codebase contains `phone-proof`, CSP-proof, and motion rationale uses of proof outside user-visible Evidence copy. [VERIFIED: codebase grep]
   - What's unclear: Whether Phase 179 copy-contract should flag only rendered operator UI or all source text. [VERIFIED: codebase grep]
   - Recommendation: Ban broad proof language in rendered IA/overview/handoff copy, but allow non-UI technical phrases and `Open proof history`. [VERIFIED: `179-CONTEXT.md`]

3. **Should `UI.error_summary/1` focus behavior be added in this phase?**
   - What we know: The component renders linked error summaries, and D-09 says validation summaries should receive focus when validation spans fields. [VERIFIED: `ui.ex`] [VERIFIED: `179-CONTEXT.md`]
   - What's unclear: Whether current forms already focus summaries through external JS or LiveView hooks. [VERIFIED: codebase grep]
   - Recommendation: Planner should include a small verification task for linked/focused multi-field validation summaries if existing behavior is absent. [CITED: https://design-system.service.gov.uk/patterns/validation/]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit, Mix aliases, LiveView render tests | yes | 1.19.5 | None needed. [VERIFIED: local command] |
| Mix | `mix test`, `mix ci.all`, project aliases | yes | 1.19.5 | None needed. [VERIFIED: local command] |
| Node.js | Playwright e2e runner | yes | v22.14.0 | None needed. [VERIFIED: local command] |
| npm | Playwright package script | yes | 11.1.0 | None needed. [VERIFIED: local command] |
| Playwright | Browser validation | yes | 1.60.0 via `npx playwright --version` | Use ExUnit-only for quick local iterations, but phase gate should include targeted e2e. [VERIFIED: local command] |
| Knowledge graph | Optional semantic discovery | no | `.planning/graphs/graph.json` absent | Continue with source scans and local docs. [VERIFIED: local command] |

**Missing dependencies with no fallback:** None found for planning/validation. [VERIFIED: local probes]

**Missing dependencies with fallback:** Knowledge graph is absent; source/document scans were used instead. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix LiveViewTest for Tier A; Playwright 1.60.0 for Tier B browser validation. [VERIFIED: local commands and tests] |
| Config file | `mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: codebase scan] |
| Quick run command | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs` [VERIFIED: test tree scan] |
| Full suite command | `mix ci.all` [VERIFIED: `mix.exs`] |
| Targeted browser command | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-home-nav-mobile.spec.ts tests/operator-prove-mobile.spec.ts tests/operator-earned-flows.spec.ts tests/operator-accessibility.spec.ts tests/operator-stress.spec.ts` [VERIFIED: e2e tree scan] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| COPY-01 | Brand voice, banned vocabulary, state-copy templates, no exclamation marks/title-case leaks | Unit/render contract | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/ui_test.exs` | `copy_contract_test.exs` missing; `ui_test.exs` exists. [VERIFIED: test tree scan] |
| COPY-02 | Glossary-consistent domain language across primary UI and page states | Unit/render contract | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/live` | New guard missing; LiveView tests exist. [VERIFIED: test tree scan] |
| COPY-03 | Stable routes, progressive disclosure, dense workflows, accessible nav labels | ExUnit + Playwright | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/timeline_live_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-home-nav-mobile.spec.ts tests/operator-earned-flows.spec.ts` | Existing tests present; assertions need copy updates. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the relevant ExUnit subset for the touched cluster; for shared helpers include `ui_test.exs`, `surface_header_test.exs`, and affected `live/*_test.exs`. [VERIFIED: test tree scan]
- **Per wave merge:** Run `mix test test/threadline/operator_surface` and targeted Playwright specs for changed shell/Home/Evidence/Exports labels. [VERIFIED: test tree scan]
- **Phase gate:** Run `mix ci.all`; run the targeted browser command above if `mix ci.all` does not surface the exact changed specs in a useful failure loop. [VERIFIED: `mix.exs`]

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/copy_contract_test.exs` — covers COPY-01/COPY-02/COPY-03 guard rails for banned vocabulary, title-case leaks, retired IA labels, rendered CamelCase, role mismatches, and exact-copy affordance invariants. [VERIFIED: missing file scan]
- [ ] Update existing assertions in `surface_header_test.exs`, `start_live_test.exs`, `evidence_live_test.exs`, `export_status_live_test.exs`, `retention_history_live_test.exs`, `policy_redaction_live_test.exs`, and Playwright specs that assert old labels. [VERIFIED: codebase grep]
- [ ] Verify or add focus behavior for multi-field `UI.error_summary/1` if current rendered behavior does not focus summaries. [VERIFIED: `ui.ex`] [CITED: https://design-system.service.gov.uk/patterns/validation/]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct change | Do not change auth/session plumbing; actor references remain existing code paths. [VERIFIED: phase scope] |
| V3 Session Management | no direct change | Preserve LiveView/session behavior and routes; no new session state for copy modes. [VERIFIED: `179-CONTEXT.md`] |
| V4 Access Control | yes, copy clarity | Keep permission copy distinct from no-data/unavailable states; do not imply restricted data is absent. [VERIFIED: `179-CONTEXT.md`] |
| V5 Input Validation | yes | Use linked field errors, D-08 validation text, and `UI.error_summary/1` focus/link behavior. [VERIFIED: `ui.ex`] [CITED: https://design-system.service.gov.uk/patterns/validation/] |
| V6 Cryptography | no direct change | No cryptography changes; preserve exact copy of IDs/refs without truncating copy target. [VERIFIED: `179-CONTEXT.md`] |

### Known Threat Patterns for Phoenix LiveView Operator Copy

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Permission copy says "nothing found" for restricted objects | Information disclosure / Repudiation | Use permission-specific copy that states the object exists but the account lacks a capability, without leaking sensitive details beyond the existing contract. [VERIFIED: `179-CONTEXT.md`] |
| Copy target truncates forensic IDs | Repudiation / Tampering | Keep `data-tl-copy` full-value guarantees from `UI.ref/1`; tests must assert full copy values. [VERIFIED: `ui.ex`] |
| Destructive prune copy becomes generic | Tampering / Repudiation | Preserve type-to-confirm and permanent-deletion language in `retention_history_live.ex`. [VERIFIED: codebase grep] |
| Route/URL churn breaks bookmarked audit workflows | Denial of service | Preserve routes, URL shapes, `patch`/`handle_params`, and e2e route assertions. [VERIFIED: `179-CONTEXT.md`] |
| Validation summaries are not focusable or field-linked | Usability/accessibility failure affecting secure operation | Use linked summaries and focus behavior for multi-field errors. [CITED: https://design-system.service.gov.uk/patterns/validation/] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/179-microcopy-information-architecture-sweep/179-CONTEXT.md` - locked Phase 179 decisions, glossary, templates, verification posture. [VERIFIED: local docs]
- `.planning/REQUIREMENTS.md` - COPY-01, COPY-02, COPY-03 and v1.37 invariants. [VERIFIED: local docs]
- `.planning/phases/178-per-page-flow-stress-pass-all-11-pages/178-VERIFICATION.md` and summaries - Phase 178 completion and corrected reconnect selector context. [VERIFIED: local docs]
- `brandbook/brand-book.md` - Threadline voice, banned vocabulary, microcopy patterns, and copy rules. [VERIFIED: local docs]
- `prompts/audit-lib-domain-model-reference.md` - audit-domain nouns and semantics boundaries. [VERIFIED: local docs]
- `lib/threadline/operator_surface/**/*` and `test/threadline/operator_surface/**/*` - current implementation and assertions. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- GOV.UK UI writing guidance - short/direct UI copy, important words first, clear links, single descriptive H1. [CITED: https://www.gov.uk/service-manual/design/writing-for-user-interfaces]
- GOV.UK Design System details guidance - details only for information some users need; do not hide information most users need. [CITED: https://design-system.service.gov.uk/components/details/]
- GOV.UK validation guidance - error summaries, field-linked messages, and focus behavior. [CITED: https://design-system.service.gov.uk/patterns/validation/]
- GOV.UK error-message and error-summary docs - specific, consistent field errors and top-of-page summaries. [CITED: https://design-system.service.gov.uk/components/error-message/] [CITED: https://design-system.service.gov.uk/components/error-summary/]
- GOV.UK accessibility testing guidance - automated checks alone do not cover all accessibility issues. [CITED: https://www.gov.uk/service-manual/helping-people-to-use-your-service/testing-for-accessibility]

### Tertiary (LOW confidence)

- None used for core recommendations. [VERIFIED: local docs]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - current versions and commands were probed locally, and no new package install is recommended. [VERIFIED: local commands]
- Architecture: HIGH - driven by locked Phase 179 decisions and current code structure. [VERIFIED: `179-CONTEXT.md`, codebase grep]
- Pitfalls: HIGH - based on concrete grep hits in source/tests plus locked constraints. [VERIFIED: codebase grep]
- GOV.UK lens: MEDIUM/HIGH - official GOV.UK docs were read directly, but implementation details must still be adapted to Threadline rather than copied visually. [CITED: gov.uk official docs]

**Research seam note:** The local `gsd-tools` bridge exposed `query init.phase-op` but did not expose the `query research-plan` or `classify-confidence` handlers in this environment, so external documentation was checked directly and source confidence was assigned from local verification plus official documentation. [VERIFIED: local command]

**Research date:** 2026-06-19

**Valid until:** 2026-07-19 for project-local copy/IA findings; re-check official GOV.UK guidance if planning slips beyond that date. [VERIFIED: current date]
