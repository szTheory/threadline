# Phase 185: coverage-and-audit-readiness - Research

**Researched:** 2026-06-29
**Domain:** Phoenix LiveView operator UI, audit coverage readiness, schema-scoped validation, ExUnit/Playwright regression proof
**Confidence:** HIGH for codebase and phase-scope findings; MEDIUM for official-doc ecosystem guidance

<user_constraints>
## User Constraints (from CONTEXT.md)

Provenance for this copied section: [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]

### Locked Decisions

### Readiness Hierarchy

- **D-185-01:** Coverage should render one primary selected-schema readiness verdict immediately after the page header. The verdict answers: "Can I rely on audit history for this schema right now?"
- **D-185-02:** Replace the current competing page-level readiness structures - separate trust rail, metric grid, and standalone remediation section - with one consolidated verdict summary. The page should not repeat "needs capture" across multiple page-level blocks.
- **D-185-03:** The verdict summary must include selected schema, checked-at metadata for that schema, covered count, missing/needs-capture count, expected-gap count, and the next action in one scannable unit.
- **D-185-04:** Use status semantics that avoid overclaiming. A schema with expected gaps and zero missing triggers may be "ready for tracked tables" or equivalent, not "all tables complete." A schema with missing triggers is "not ready" or equivalent for audit history reliance.
- **D-185-05:** Keep the table below the verdict as the row comparison and action surface. Tables are appropriate for comparing table name, status, source, and contextual actions; they should not carry the only primary page verdict.
- **D-185-06:** Do not build a dashboard-like metric surface in Phase 185. Trend/SLO dashboards may be useful later, but this phase is about one readiness answer, not metric inflation.
- **D-185-07:** Do not make Coverage table-first. Operators need the selected-schema verdict before they start row triage, especially on 320px/375px viewports.

### Remediation Actions

- **D-185-08:** Use a hybrid remediation model. The verdict summary gives one schema-level next step: fix rows marked `Needs capture`, apply the migration, run the coverage verifier, then refresh.
- **D-185-09:** Keep row-level `Add capture` disclosures for uncovered rows. Row-level placement is the safest place for table-specific command copy and avoids unsafe all-table commands.
- **D-185-10:** Row remediation copy should be CLI-first and exact for Elixir maintainer DX. It should prefer existing Threadline commands such as `mix threadline.gen.triggers --tables ...` and `mix threadline.verify_coverage`, with `--schema=NAME` when relevant.
- **D-185-11:** Command generation must stay conservative. If a table/schema identifier is unsafe, ambiguous, or non-public behavior cannot be expressed safely in the current command helper, show the precise follow-up guidance rather than fabricating a copyable command.
- **D-185-12:** Keep `View activity` only on covered rows as a contextual Timeline pivot. It should preserve non-public schema context with `table_schema=NAME&table=TABLE`; public schema links may omit `table_schema`.
- **D-185-13:** Do not render generic page-level Timeline CTAs from Coverage. Timeline handoff is contextual to covered rows; generic CTAs compete with the readiness/remediation job and can imply incomplete data is reliable.
- **D-185-14:** Expected-gap rows should be marked as intentionally excluded from readiness and should not render `Add capture`.

### Schema Workflow

- **D-185-15:** Use a native select/dropdown as the Phase 185 default schema control, populated from available non-system schemas. Include `public` and the current valid selected schema. Keep the current URL state contract: `/audit/coverage?schema=NAME`.
- **D-185-16:** Reject schema tabs. Tabs imply a small fixed set of panels, add APG/keyboard complexity, risk mobile overflow, and do not match dynamic tenant schemas.
- **D-185-17:** Reject a route-level schema inventory or `/coverage/:schema` route in Phase 185. Route paths are a stable operator contract, and the phase goal is one selected-schema readiness answer, not a schema catalog.
- **D-185-18:** Free-text schema entry with `<datalist>` is not the default. It may be revisited only if real adopter schemas are too numerous for a native select; the current phase should prefer constrained, accessible selection with pasted invalid URLs still handled robustly.
- **D-185-19:** Validation stays at the user-facing LiveView/Mix-task edge via `Threadline.Health.CoverageSchemas`, not inside `Threadline.Health.trigger_coverage/1`. Programmatic callers remain trusted; UI/CLI surfaces validate untrusted schema names.
- **D-185-20:** Invalid schema URLs preserve the rejected URL, show a clear page alert, keep the schema picker usable, and offer an explicit path back to `public`. They must not render stale `public` data as though it belongs to the invalid schema.
- **D-185-21:** `checked_at` means the selected schema's last successful coverage check. Manual refresh re-fetches that selected schema. If refresh fails after a prior success, keep last-good data visible, mark it stale, and do not overwrite the last-success timestamp with a failed-check timestamp.
- **D-185-22:** The surface header badge may continue to query `"public"` only, as currently documented. Multi-schema readiness is explicit on `/audit/coverage` and encoded in that page URL.

### Proof And Regression Scope

- **D-185-23:** Use a targeted Coverage state lattice for Phase 185 proof. The phase must prove COV-01 through COV-03 directly, not rely only on synthetic stress fixtures.
- **D-185-24:** Source/LiveView/doc proof should cover: default `?schema=public`; valid non-public schema; invalid schema; schema selection patch; selected-schema refresh; stale last-good warning; all-empty schema; covered rows with contextual `View activity`; uncovered rows with `Add capture`; expected-gap rows without remediation; and docs for schema selection, refresh, and non-public row links.
- **D-185-25:** Browser proof should stay narrow and user-observable: mobile readability/no horizontal overflow, native schema control reachability, row disclosure/copy layout, focus visibility, and non-public/public link behavior where browser proof adds confidence over LiveView tests.
- **D-185-26:** Do not create a broad route x theme x viewport screenshot matrix. Prior v1.38 decisions rejected broad screenshot churn; Playwright should assert behavior and layout affordances, not become a pixel-baseline expansion.
- **D-185-27:** Existing `/audit/__stress`, `StressFixtures`, `DESIGN-SYSTEM.md`, `.planning/design-system-ledger.json`, style contracts, and Phase 187 closeout remain the place for generic loading/error/permission/unavailable/theme/motion proof unless Phase 185 changes Coverage-specific CSS or state semantics.
- **D-185-28:** Tests should prefer behavior and user-facing contracts. Use role/name/test-id locators in browser tests, LiveView tests for URL/event/state behavior, and source/doc contracts for stable copy and docs anchors.

### Product, JTBD, And UX Posture

- **D-185-29:** Optimize Coverage for P1 incident responders, P2 support agents, P3 compliance/security reviewers, P4 audit/SRE operators, and P5 adopter developers. The common job is not "view coverage metrics"; it is "know whether audit history for this schema can be relied on, and fix the gap if it cannot."
- **D-185-30:** Apply the who/what/where/when/why lens:
  - Who: operators and maintainers with access to the mounted Coverage surface.
  - What: choose a schema, read the readiness verdict, inspect missing/covered/expected rows, copy or follow remediation, refresh, and pivot to Timeline only when coverage exists.
  - Where: `/audit/coverage`, with row-level handoff to `/audit/timeline`.
  - When: after deploys, before relying on Timeline during incidents, during support triage, during audit-readiness sweeps, and while validating a tenant/non-public schema.
  - Why: make capture drift impossible to miss without forcing operators to understand trigger internals first.
- **D-185-31:** Use canonical domain language: Coverage, audit readiness, selected schema, checked, tracked tables, covered, needs capture, expected gap, Add capture, verify coverage, refresh, View activity, Timeline, public schema, non-public schema.
- **D-185-32:** Hide backend implementation details unless they affect trust or next action. It is acceptable to mention missing triggers, schema scope, `mix threadline.gen.triggers`, `mix threadline.verify_coverage`, and stale last-good data. Avoid exposing raw catalog-query details, `pg_namespace`, internal polling implementation, or trigger SQL internals in primary UI copy.
- **D-185-33:** Preserve Threadline brand posture: calm in tense moments, exact without being cold, useful over impressive, dense but scannable, color as signal not decoration, accessible focus/hover/disabled states, dark/light/system support, and no decorative motion or gradient/orb treatment.
- **D-185-34:** Empty/error copy must state what happened, why if known, and the next action. Distinguish "schema not found," "no audited tables found for this schema," "coverage refresh failed but last-good data remains," and "coverage unavailable in this support lane."

### Architecture And Implementation Posture

- **D-185-35:** Stay inside the existing private Phoenix LiveView component system. Prefer private function components/helpers and `attr`/slot contracts where they reduce duplication; do not introduce LiveComponents for organization.
- **D-185-36:** Keep LiveView as orchestration/presentation. Validation of user-provided schema names belongs at the UI/CLI edge; `Threadline.Health.trigger_coverage/1`, `Coverage.Snapshot`, `Coverage.OnMount`, and existing health modules remain the domain/integration authority.
- **D-185-37:** Preserve existing route paths, `data-testid`s, feature gates, auth posture, optional Phoenix/LiveView dependency boundaries, theme contract, native controls, and CSP-friendly no-inline-handler posture.
- **D-185-38:** Do not add a dependency, Tailwind/shadcn migration, client-side router, custom select widget, custom command palette, localStorage behavior, visual-regression SaaS, or new public API for this phase.
- **D-185-39:** Use current assets before inventing new abstractions: `CoverageLive`, `Coverage.Snapshot`, `Coverage.OnMount`, `CoverageSchemas`, `Presentation.coverage_remediation/2`, `UI.page_header`, `UI.ref`/copy patterns if needed, `UI.empty_state`/alert patterns if suitable, `style.ex`, `coverage_live_test`, `coverage_doc_contract_test`, existing Playwright suites, and `/audit/__stress`.

### the agent's Discretion

The user explicitly asked for all gray areas to be considered with research-backed, cohesive recommendations. Downstream agents may choose exact helper names, CSS selectors, component extraction, plan count, task slicing, and test organization if they preserve the decisions above and keep Phase 185 scoped to Coverage audit readiness.

### Deferred Ideas (OUT OF SCOPE)

- Coverage trend/SLO dashboard, historical drift charts, or readiness over time are deferred. They would be a new monitoring capability, not Phase 185 page polish.
- Schema tabs are rejected for Phase 185 and deferred unless a future fixed-small-schema UX is explicitly scoped.
- A route-level schema inventory or `/coverage/:schema` route is deferred/rejected for Phase 185 because route paths are stable operator contracts.
- Free-text schema search/datalist remains a fallback idea only if real adopter schema counts make native select untenable.
- Broad visual screenshot matrix remains deferred; promoted screenshot cells need explicit future ownership.
- Generic page-level Timeline CTAs from Coverage are rejected. Timeline links remain contextual row actions.
- Timeline workflow polish remains Phase 184 and is already complete.
- Transaction, actor, row-history, Evidence, Exports, Redaction, and Retention workflow polish remains Phase 186.
- Accessibility/motion/docs/adversarial closeout remains Phase 187, though Phase 185 must preserve the relevant Coverage accessibility and docs contracts.
- Public component API, root Tailwind/shadcn migration, root PhoenixStorybook dependency, production Storybook/stress route, and runtime destructive redaction remain out of scope.
- No matching todo artifacts were found for Phase 185.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COV-01 | Coverage renders one primary readiness verdict for the selected schema, with schema scope and checked-at metadata visible and URL-addressable. | `CoverageLive.handle_params/3` already owns `?schema=NAME`, `Coverage.Snapshot` already exposes counts and `last_checked_at`, and LiveView docs support validating patch params in `handle_params/3`. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex] [VERIFIED: lib/threadline/operator_surface/coverage/snapshot.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| COV-02 | Coverage removes repeated readiness copy and duplicate cross-surface CTAs, leaving contextual row actions and one clear remediation path. | Current success markup still renders `tl-trust-rail`, `tl-summary-grid`, and `tl-remediation`; replacing those with one verdict is the key implementation slice. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:194] |
| COV-03 | Coverage schema selection, invalid-schema errors, non-public schema row links, refresh behavior, and docs remain correct and regression-guarded. | Existing tests cover public/invalid schema, schema patch, non-public `table_schema` links, refresh click, and doc contracts; Phase 185 should update and extend those tests instead of creating a parallel harness. [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs] [VERIFIED: test/threadline/operator_surface/coverage_doc_contract_test.exs] |
</phase_requirements>

## Summary

Phase 185 is a focused Coverage LiveView hierarchy and proof pass, not a capture-layer, route, auth, or package phase. The current implementation already has the necessary data and seams: selected schema URL state lives in `CoverageLive.handle_params/3`, schema validation is centralized in `Threadline.Health.CoverageSchemas`, row buckets and last-check metadata come from `Coverage.Snapshot`, and row remediation copy is centralized in `Presentation.coverage_remediation/2`. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex] [VERIFIED: lib/threadline/health/coverage_schemas.ex] [VERIFIED: lib/threadline/operator_surface/coverage/snapshot.ex] [VERIFIED: lib/threadline/operator_surface/presentation.ex]

The main planning risk is preserving COV-03 while deleting COV-02's repeated page-level structures. Today the success branch renders a trust rail, metric grid, and standalone remediation block before the table; tests and browser helpers currently assert some of that old structure. The plan should explicitly flip those assertions to the new single-verdict contract, then add narrow state-lattice coverage for public, non-public, invalid, empty, stale, covered, uncovered, and expected-gap cases. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:194] [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs:182] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:184]

Official docs support the chosen shape: LiveView `push_patch` plus `handle_params/3` is the documented seam for URL-backed state, Phoenix function components use `attr`/slot contracts for reusable UI, LiveView forms should use normal `phx-submit` semantics, and Playwright recommends resilient role/text/test-id locators for user-visible behavior. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] [CITED: https://hexdocs.pm/phoenix_live_view/form-bindings.html] [CITED: https://playwright.dev/docs/best-practices]

**Primary recommendation:** Build one private `CoverageLive` verdict helper/component, replace the trust rail/metric/remediation trio with it, convert schema entry from datalist input to native select, fix stale refresh timestamp semantics, and update LiveView/doc/source/browser tests in the existing Coverage lanes. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-UI-SPEC.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Selected-schema URL state | Frontend Server (LiveView) | Browser / Client | `CoverageLive.handle_params/3` and `push_patch/2` already own `?schema=NAME`; the browser only carries the URL and native form controls. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:38] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Schema validation | API / Backend edge | Database / Storage | User-provided schema names are validated through `CoverageSchemas.validate/2` with regex plus `pg_namespace` lookup before `trigger_coverage/1` receives them. [VERIFIED: lib/threadline/health/coverage_schemas.ex:27] |
| Coverage data authority | API / Backend | Database / Storage | `Threadline.Health.trigger_coverage/1` remains the domain integration source; Phase 185 must not change its programmatic contract. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] |
| Readiness verdict rendering | Frontend Server (LiveView) | Browser / Client | The verdict is derived from `Coverage.Snapshot` counts and rendered as server HTML with accessible text/status cues. [VERIFIED: lib/threadline/operator_surface/coverage/snapshot.ex:15] |
| Row remediation and Timeline pivots | Frontend Server (LiveView) | Browser / Client | `Presentation.coverage_remediation/2` generates conservative row guidance, while covered rows link to Timeline with public/non-public query parameters. [VERIFIED: lib/threadline/operator_surface/presentation.ex:436] [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:383] |
| Header coverage badge | Frontend Server (LiveView) | API / Backend | `Coverage.OnMount` fetches public-schema coverage for the shell badge and remains distinct from selected-schema page readiness. [VERIFIED: lib/threadline/operator_surface/coverage/on_mount.ex:113] |

## Project Constraints (from CLAUDE.md)

- Threadline is an Elixir/Phoenix/Ecto/PostgreSQL audit platform with capture, semantics, and exploration/operations layers that must not be conflated. [VERIFIED: CLAUDE.md]
- Phase 185 belongs to the exploration/operations layer: timelines, diffs, filters, exports, health checks, retention, redaction, coverage, and telemetry. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]
- Preserve domain terms such as `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation` in code/docs where relevant. [VERIFIED: CLAUDE.md]
- Use canonical verification entrypoints where practical: `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`; targeted phase proof may use narrower `mix test` and Playwright commands. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]
- Do not change capture semantics, auth boundaries, route paths, optional Phoenix/LiveView posture, feature gates, or public component APIs for this phase. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/REQUIREMENTS.md]
- No root `AGENTS.md` exists in `/Users/jon/projects/threadline`; the only discovered `AGENTS.md` is under `examples/threadline_phoenix/` and is not the working-directory project instruction file. [VERIFIED: rg --files -g 'AGENTS.md']
- No project-defined `.codex/skills`, `.agents/skills`, or `.claude/skills` directories were present in the workspace. [VERIFIED: find .codex/skills .agents/skills .claude/skills -name SKILL.md -maxdepth 3]
- No `.planning/graphs/graph.json` exists, so graph context was unavailable for this research. [VERIFIED: ls .planning/graphs/graph.json]

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Phoenix LiveView | locked `phoenix_live_view` 1.1.30; Hex latest checked 1.2.4 on 2026-06-29 | Server-rendered Coverage UI, LiveView events, URL patching, test helpers | Existing optional UI dependency; official docs support function components, `handle_params/3`, form bindings, and LiveViewTest. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| Phoenix | locked 1.8.7; Hex latest checked 1.8.8 on 2026-06-29 | Router/live_session/auth shell and security conventions | Existing optional dependency for mounted operator surface; route stability is locked. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix] [CITED: https://hexdocs.pm/phoenix/security.html] |
| Ecto SQL + Postgrex | `ecto_sql` 3.13.5; `postgrex` 0.22.0 | Schema validation lookup and trigger coverage catalog queries | Existing database access stack; CoverageSchemas uses parameterized `Ecto.Adapters.SQL.query!/3`. [VERIFIED: mix.lock] [VERIFIED: lib/threadline/health/coverage_schemas.ex:31] |
| Threadline private operator UI | repository local | `UI.page_header`, alerts/empty state primitives, CSS tokens, row disclosures | Phase locks private function components and forbids public API or component library migration. [VERIFIED: lib/threadline/operator_surface/ui.ex] [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] |
| Coverage domain helpers | repository local | `CoverageLive`, `Coverage.Snapshot`, `Coverage.OnMount`, `CoverageSchemas`, `Presentation.coverage_remediation/2` | Existing seams already encode selected-schema state, counts, validation, polling, and remediation. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExUnit + Phoenix.LiveViewTest | bundled with Elixir/Mix 1.19.5 and LiveView 1.1.30 | Behavior tests for schema URL state, rendered copy, row actions, refresh, and stale state | Primary proof for COV-01 through COV-03 because it exercises LiveView state without browser flake. [VERIFIED: elixir --version] [VERIFIED: mix --version] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| `lazy_html` | locked 0.1.11 | HTML parsing assertions in tests | Use only where source/string assertions are too brittle; it is already test-only. [VERIFIED: mix.lock] [VERIFIED: mix hex.info lazy_html] |
| Playwright `@playwright/test` | installed 1.60.0; npm latest checked 1.61.1 modified 2026-06-29; no `scripts.postinstall` found | Existing example-app browser proof for mobile readability, focus, no-overflow, row disclosure layout | Use a narrow Coverage browser path; do not expand screenshot matrices. [VERIFIED: examples/threadline_phoenix/e2e/package.json] [VERIFIED: npm list @playwright/test --depth=0] [VERIFIED: npm view @playwright/test version time.modified dist-tags.latest] [CITED: https://playwright.dev/docs/best-practices] |
| `mix threadline.verify_coverage` | repository local | Operator remediation verifier command | Verdict copy should name this command, with `--schema=NAME` for non-public schemas. [VERIFIED: lib/mix/tasks/threadline.verify_coverage.ex:17] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native `<select>` | `<input list="...">` datalist/free text | Datalist exists today, but Phase 185 rejects it as the default because invalid entry is not the primary workflow and native select is simpler to validate/access. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:312] [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] |
| Private function helper/component | LiveComponent | LiveComponent would add lifecycle/organization overhead without state isolation needs; Phase 185 locks private function components/helpers. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| Existing ExUnit/Playwright lanes | New visual regression service | Phase 185 explicitly forbids visual-regression SaaS and broad screenshot matrices. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] |

**Installation:**

```bash
# No new packages. Use the existing Mix and e2e dependencies.
mix deps.get
cd examples/threadline_phoenix/e2e && npm install
```

**Version verification:** Versions were checked from `mix.lock`, `mix deps`, `mix hex.info`, `npm list @playwright/test --depth=0`, and `npm view @playwright/test version time.modified dist-tags.latest`. [VERIFIED: command output]

## Package Legitimacy Audit

No external package installation is recommended for Phase 185, so the package legitimacy gate is not required. Existing package evidence was taken from lockfiles/installed dependency output, and `@playwright/test` was additionally checked for latest version and postinstall script because the browser lane is npm-based. [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/e2e/package.json] [VERIFIED: npm view @playwright/test scripts.postinstall]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None to install | n/a | n/a | n/a | n/a | n/a | No package changes |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Operator request
  -> /audit/coverage?schema=NAME
  -> Router live_session
  -> Auth on_mount checks host-owned coverage access
  -> Coverage.OnMount fetches public-schema badge data
  -> CoverageLive.handle_params/3 reads selected schema
      -> valid schema?
          yes -> CoverageSchemas.validate/2 -> trigger_coverage(repo, schema)
                 -> Coverage.Snapshot counts + last_checked_at
                 -> page header + alert/stale banner if needed
                 -> one selected-schema readiness verdict
                 -> row comparison table
                    -> uncovered row: Add capture disclosure
                    -> expected gap row: Excluded from readiness
                    -> covered row: View activity link
          no  -> preserve rejected URL value
                 -> error alert + usable schema picker + Use public schema path
```

### Recommended Project Structure

```text
lib/threadline/operator_surface/
|-- live/coverage_live.ex          # Selected-schema URL state, verdict rendering, row actions
|-- coverage/snapshot.ex           # Counts, buckets, last successful check metadata
|-- coverage/on_mount.ex           # Public-schema shell badge polling and last-good behavior
|-- presentation.ex                # Remediation copy/command safety helpers
|-- ui.ex                          # Private function components to reuse before adding helpers
`-- style.ex                       # Token-backed Coverage CSS and responsive layout contracts

test/threadline/operator_surface/
|-- live/coverage_live_test.exs    # Primary state-lattice proof
|-- coverage_doc_contract_test.exs # Docs/source literal and safety contracts
|-- style_contract_test.exs        # CSS deletion/addition guards
`-- coverage/on_mount_test.exs     # Header public-schema polling guard

examples/threadline_phoenix/e2e/tests/
`-- operator-responsive-mobile-first.spec.ts  # Narrow mobile/no-overflow proof lane
```

### Pattern 1: URL-Backed Schema State

**What:** Keep schema selection shareable via `/audit/coverage?schema=NAME`; submit the native form to `select-schema`, then `push_patch/2`, then validate/load in `handle_params/3`. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:70] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

**When to use:** Use for the selected schema because it is user-facing, shareable, and directly covered by COV-01/COV-03. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: project pattern + Phoenix LiveView live-navigation docs
def handle_event("select-schema", %{"schema" => schema}, socket) do
  schema = normalize_schema_choice(schema)
  {:noreply, push_patch(socket, to: coverage_path(socket.assigns.base_path, schema))}
end

def handle_params(%{"schema" => schema}, _uri, socket) do
  case CoverageSchemas.validate(resolve_repo(socket), schema) do
    {:ok, schema} -> {:noreply, fetch_coverage_for_schema(socket, schema)}
    {:error, message} -> {:noreply, assign_invalid_schema(socket, schema, message)}
  end
end
```

### Pattern 2: One Verdict, Table Second

**What:** Derive a single verdict from `Snapshot` counts and render it immediately after the page header; keep the table for row comparison and contextual actions only. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-UI-SPEC.md]

**When to use:** Use in the normal valid-schema branch, including ready, not-ready, expected-gap, stale, and empty variants. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]

**Example:**

```elixir
# Source: project UI-SPEC and Snapshot fields
defp readiness(%Snapshot{uncovered_count: missing}) when missing > 0, do: :not_ready
defp readiness(%Snapshot{expected_uncovered_count: expected}) when expected > 0, do: :ready_for_tracked
defp readiness(%Snapshot{}), do: :ready
```

### Pattern 3: Last-Good Stale State

**What:** On refresh failure after prior success, keep the previous snapshot visible, set an error/stale marker, and keep `last_checked_at` as the last successful check. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]

**Why:** Current `fetch_coverage_for_schema/2` rescue sets `last_checked_at` to the failed-check time, which conflicts with D-185-21. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:351]

**Example:**

```elixir
# Source: D-185-21 and existing Coverage.OnMount last-good policy
rescue
  e ->
    previous = socket.assigns[:coverage_for_schema] || Snapshot.empty()
    assign(socket, :coverage_for_schema, %{previous | error: Exception.message(e)})
end
```

### Pattern 4: Contextual Row Actions

**What:** Render `Add capture` only on uncovered rows, `Excluded from readiness` on expected gaps, and `View activity` only on covered rows. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:236]

**Why:** Row-level placement avoids unsafe all-table commands and keeps Timeline handoff tied to rows where coverage exists. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]

### Anti-Patterns to Avoid

- **Metric inflation:** Do not keep the trust rail plus metric grid plus remediation block; that duplicates the readiness signal Phase 185 exists to collapse. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:194]
- **Stale invalid fallback:** Do not show last public coverage for an invalid schema URL; preserve the rejected value and show recovery. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]
- **Unsafe command synthesis:** Do not fabricate copyable shell commands for non-public or unsafe identifiers. [VERIFIED: lib/threadline/operator_surface/presentation.ex:445]
- **Browser-only proof:** Do not rely on Playwright for state lattice coverage that LiveView tests can cover faster and more deterministically. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema picker | Custom combobox, tabs, client router, localStorage | Native `<select>` in existing `schema_form` | Phase locks native controls, URL state, and no client router/localStorage. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] |
| Readiness data model | New domain struct or persistent readiness table | Existing `Coverage.Snapshot` fields | Snapshot already has counts, buckets, timestamp, and error. [VERIFIED: lib/threadline/operator_surface/coverage/snapshot.ex:15] |
| Schema validation | Regex/SQL inline in LiveView | `Threadline.Health.CoverageSchemas` | Centralized edge validation prevents drift with Mix tasks. [VERIFIED: lib/threadline/health/coverage_schemas.ex] |
| Remediation copy | Per-row string interpolation in template | `Presentation.coverage_remediation/2` plus new small helpers if needed | Existing helper already encodes command safety and follow-up. [VERIFIED: lib/threadline/operator_surface/presentation.ex:436] |
| Disclosure behavior | Custom JS accordion | Native `<details>/<summary>` | APG documents disclosure keyboard expectations; native elements preserve built-in browser behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/] |
| Mobile proof | Screenshot matrix | Existing Playwright behavior/no-overflow tests | Phase explicitly rejects broad screenshot churn. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] |

**Key insight:** The hard part is not building new data plumbing; it is deleting duplicate readiness surfaces while preserving schema-specific trust semantics, last-good behavior, and row-context actions. [VERIFIED: codebase grep and Phase 185 context]

## Common Pitfalls

### Pitfall 1: Failed Refresh Overwrites Last Success

**What goes wrong:** A failed selected-schema refresh updates `last_checked_at`, making failed data look freshly checked. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:351]  
**Why it happens:** Current rescue builds `%{previous | error: message, last_checked_at: now}`. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:351]  
**How to avoid:** Preserve the previous timestamp and set only the stale/error marker. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]  
**Warning signs:** Tests assert stale warning copy but do not assert that `last_checked_at` remains unchanged.

### Pitfall 2: Invalid Schema Renders Stale Public Data

**What goes wrong:** Operators see an invalid URL error but also see public data, implying it belongs to the rejected schema. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]  
**Why it happens:** `mount/3` initializes `coverage_for_schema` from public shell coverage before params validate. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:25]  
**How to avoid:** In the form-error branch, do not render table/verdict for the previous schema; show alert, picker, and Use public schema recovery. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-UI-SPEC.md]

### Pitfall 3: Expected Gaps Overclaim Readiness

**What goes wrong:** Copy says "all tables complete" when expected gaps exist. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]  
**Why it happens:** A binary covered/uncovered model ignores the `expected_uncovered_count` bucket. [VERIFIED: lib/threadline/operator_surface/coverage/snapshot.ex:17]  
**How to avoid:** Use "ready for tracked tables" when expected gaps remain and zero missing triggers exist. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-UI-SPEC.md]

### Pitfall 4: Source Tests Preserve Old IA

**What goes wrong:** The implementation can be correct but tests still require `tl-summary-grid`, metric tiles, or separate remediation. [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs:216]  
**Why it happens:** Prior Phase 176 tests locked the flattened but still multi-block Coverage structure. [VERIFIED: .planning/STATE.md]  
**How to avoid:** Pair source changes with assertion flips in the same plan slice. [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs]

### Pitfall 5: Browser Tests Depend on Deleted CSS

**What goes wrong:** Playwright helpers query `tl-trust-rail` and `tl-summary-grid`, so deleting the old blocks causes intended UI changes to fail browser proof. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:168]  
**Why it happens:** Layout measurements were written around old page structure. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:184]  
**How to avoid:** Retarget browser proof to the verdict region, native schema control, row disclosure layout, focus, and no horizontal overflow. [CITED: https://playwright.dev/docs/best-practices]

## Code Examples

Verified patterns from official sources and local code:

### Native Schema Select

```elixir
# Source: Phase 185 UI-SPEC + LiveView form bindings docs
defp schema_form(assigns) do
  ~H"""
  <form phx-submit="select-schema" class="tl-schema-picker" aria-label="Coverage schema">
    <label class="tl-schema-picker__label" for="coverage-schema">Schema</label>
    <select id="coverage-schema" name="schema" class="tl-control tl-schema-picker__control">
      <option :for={schema <- schema_options(@available_schemas, @schema)} value={schema} selected={schema == @schema}>
        <%= schema %>
      </option>
    </select>
    <button type="submit" class="tl-button tl-button--secondary">Apply schema</button>
  </form>
  """
end
```

### Verdict Derivation

```elixir
# Source: Coverage.Snapshot fields + Phase 185 UI-SPEC
defp verdict(%Snapshot{covered_count: 0, uncovered_count: 0, expected_uncovered_count: 0}), do: :empty
defp verdict(%Snapshot{uncovered_count: count}) when count > 0, do: :not_ready
defp verdict(%Snapshot{expected_uncovered_count: count}) when count > 0, do: :ready_for_tracked
defp verdict(%Snapshot{}), do: :ready
```

### LiveView Test for Schema Patch

```elixir
# Source: Phoenix.LiveViewTest docs and existing coverage_live_test pattern
{:ok, view, _html} = live(conn, "/audit/coverage")

view
|> form("form[aria-label='Coverage schema']", %{"schema" => "public"})
|> render_submit()

assert_patch(view, "/audit/coverage?schema=public")
```

### Playwright Mobile Proof

```typescript
// Source: Playwright best practices plus existing no-overflow helper
await expect(page.getByRole("region", { name: "Selected schema readiness" })).toBeVisible();
await expect(page.getByLabel("Schema")).toBeVisible();
await expect(page.getByTestId("coverage-table")).toBeVisible();
await expectNoHorizontalOverflow(page);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| LiveView URL state handled ad hoc | Use `push_patch`/`handle_params` for shareable state and validate params before assigning | LiveView docs current as of v1.2.4; project locked v1.1.30 | Phase 185 should keep `?schema=NAME` rather than add routes or client state. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [VERIFIED: mix.lock] |
| Custom JS controls for disclosure/select | Prefer native controls unless a real widget need exists | Project decisions from Phases 174/183/185 | Native select and details/summary keep keyboard behavior and reduce APG burden. [VERIFIED: .planning/STATE.md] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/] |
| Broad visual screenshot matrices | Narrow behavior/layout browser proof with role/text/test-id locators | v1.38 decisions in Phases 181-185 | Coverage proof should not expand screenshot ownership. [VERIFIED: .planning/STATE.md] [CITED: https://playwright.dev/docs/best-practices] |
| ASVS 4.x references without version | ASVS stable 5.0.0 is current per OWASP site | OWASP page lists v5.0.0 release on 2025-05-30 | Security mapping should cite current ASVS generically and avoid claiming formal compliance. [CITED: https://owasp.org/www-project-application-security-verification-standard/] |

**Deprecated/outdated:**
- `tl-trust-rail` as a separate page-level readiness rail for Coverage is outdated for Phase 185 because the locked requirement is one consolidated selected-schema verdict. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:194] [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]
- Free-text datalist schema entry is outdated as the default Phase 185 control; native select is locked. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex:312] [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-UI-SPEC.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact helper/function names shown in Code Examples are illustrative planner guidance, not locked API names. [ASSUMED] | Code Examples | Low; implementation can choose different private names while preserving behavior. |

## Open Questions (RESOLVED)

1. **Should browser proof include non-public schema links, or should LiveView tests own that entirely?**
   - What we know: LiveView tests already create `tenant_demo`, render `/audit/coverage?schema=tenant_demo`, and assert `table_schema=tenant_demo`. [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs:317]
   - Resolved decision: LiveView tests own non-public schema link correctness because they can deterministically create non-public schema state. Browser proof owns mobile readability, native schema control reachability, focus traversal, row disclosure/copy layout, no horizontal overflow, and public-schema link behavior. Do not require browser non-public schema data unless a deterministic fixture already exists. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix/ExUnit implementation and tests | yes | 1.19.5 | none needed [VERIFIED: elixir --version] |
| Erlang/OTP | Elixir runtime | yes | OTP 28 / ERTS 16.3 | none needed [VERIFIED: elixir --version] |
| Mix | Dependencies and test commands | yes | 1.19.5 | none needed [VERIFIED: mix --version] |
| PostgreSQL local service | Coverage/schema tests | yes | psql 14.17; `pg_isready` accepting connections | If unavailable, planner must run DB setup before tests. [VERIFIED: psql --version] [VERIFIED: pg_isready] |
| Node.js | Example e2e test runner | yes | 22.14.0 | none needed [VERIFIED: node --version] |
| npm | Example e2e dependencies | yes | 11.1.0 | none needed [VERIFIED: npm --version] |
| Playwright | Mobile/browser proof | yes | `@playwright/test` 1.60.0 installed | Use LiveView tests for state proof if browser lane is unavailable. [VERIFIED: npm list @playwright/test --depth=0] |
| Context7 CLI/MCP | Preferred docs lookup | no | n/a | Official docs were fetched via websearch/web open. [VERIFIED: command -v ctx7] |

**Missing dependencies with no fallback:** none for implementation. [VERIFIED: environment probes]

**Missing dependencies with fallback:**
- Context7 unavailable; official docs were fetched directly through web tooling and cached through the GSD research store. [VERIFIED: command -v ctx7] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Mix with Phoenix.LiveViewTest; Playwright `@playwright/test` 1.60.0 for example browser proof. [VERIFIED: mix.exs] [VERIFIED: npm list @playwright/test --depth=0] |
| Config file | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: mix.exs] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] |
| Quick run command | `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` |
| Full suite command | `mix verify.test`; browser lane `mix verify.example_browser` when UI changes need e2e proof. [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| COV-01 | Primary selected-schema readiness verdict, URL-addressable schema, checked metadata | LiveView/source | `mix test test/threadline/operator_surface/live/coverage_live_test.exs` | yes, extend [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs] |
| COV-02 | Remove repeated readiness copy and generic Timeline CTA; keep contextual row actions | LiveView/source/style | `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/style_contract_test.exs` | yes, update assertions [VERIFIED: test/threadline/operator_surface/style_contract_test.exs] |
| COV-03 | Schema select, invalid schema, non-public row links, refresh/stale, docs | LiveView/doc/browser | `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` | yes, extend [VERIFIED: targeted test run: 46 tests, 0 failures] |
| COV-03 | Mobile readability/no horizontal overflow/schema control reachability | Playwright | Closeout proof: `mix verify.example_browser_light tests/operator-coverage-readiness.spec.ts` after fast Mix sampling | yes, add/admit [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts] |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs`
- **Per wave merge:** add `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/coverage/on_mount_test.exs`
- **Phase gate:** targeted Mix slice remains primary sampling; run the narrow Playwright Coverage/mobile lane as closeout proof, then run `mix verify.test` before `$gsd-verify-work` when local residuals allow. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/live/coverage_live_test.exs` - add/flip assertions for one verdict, native select, stale timestamp preservation, empty schema copy, and invalid-schema recovery.
- [ ] `test/threadline/operator_surface/coverage_doc_contract_test.exs` - update docs/source literals for selected-schema readiness, refresh, and non-public row links.
- [ ] `test/threadline/operator_surface/style_contract_test.exs` - retire `tl-trust-rail`/standalone remediation CSS if deleted; add `tl-coverage-verdict` token-backed/mobile rules if introduced.
- [ ] `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` - add narrow closeout browser proof for the verdict region, schema select, mobile overflow, focus traversal, row disclosure/copy layout, and public-schema link behavior; admit it to the existing light/system lane.

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth | Preserve host-owned `coverage_authorize_fn`; no auth model changes. [VERIFIED: lib/threadline/operator_surface/router.ex:43] |
| V3 Session Management | no new session state | Preserve existing LiveView/session and avoid localStorage/client-only state. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] |
| V4 Access Control | yes | Keep route/auth posture and coverage gate fail-closed; unsupported view must not imply permissions when lane unavailable. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs:105] |
| V5 Input Validation | yes | Validate schema URL/form input through `CoverageSchemas`, use parameterized SQL, and avoid atom creation from input. [VERIFIED: lib/threadline/health/coverage_schemas.ex:27] [VERIFIED: test/threadline/operator_surface/coverage_doc_contract_test.exs:206] |
| V6 Cryptography | no new crypto | Do not add crypto or token handling; rely on existing Phoenix/Plug session/CSRF posture. [CITED: https://hexdocs.pm/phoenix/security.html] |

OWASP ASVS is a verification standard for web application security controls and current OWASP project page lists stable ASVS 5.0.0; this phase should map relevant controls without claiming formal ASVS compliance. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Known Threat Patterns for Phoenix LiveView Coverage

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Schema parameter tampering | Tampering | Validate at the LiveView/Mix edge with conservative regex plus `pg_namespace` lookup; preserve invalid value only as escaped UI copy. [VERIFIED: lib/threadline/health/coverage_schemas.ex] |
| SQL injection through schema name | Tampering | Use parameterized `Ecto.Adapters.SQL.query!/3`, never interpolated `nspname`/`schemaname`. [VERIFIED: lib/threadline/health/coverage_schemas.ex:31] [VERIFIED: test/threadline/operator_surface/coverage_doc_contract_test.exs:229] |
| XSS through schema/table names | Tampering | Render through HEEx interpolation and avoid raw HTML; schema errors must remain escaped. [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs:281] |
| Incomplete audit data presented as reliable | Spoofing / Information Disclosure | Use "not ready" and stale warnings; remove generic Timeline CTAs unless row is covered. [VERIFIED: .planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md] |
| Unsafe shell-command copy | Elevation / Tampering | Copy commands only for safe public identifiers; show conservative follow-up otherwise. [VERIFIED: lib/threadline/operator_surface/presentation.ex:445] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md` - locked implementation, UX, proof, and out-of-scope decisions. [VERIFIED: file read]
- `.planning/phases/185-coverage-and-audit-readiness/185-UI-SPEC.md` - visual, copy, responsive, interaction, and accessibility contract. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - COV requirements, success criteria, project invariants, and prior phase state. [VERIFIED: file read]
- `CLAUDE.md` - project architecture, domain language, and verification conventions. [VERIFIED: file read]
- `brandbook/brand-book.md` - Threadline brand, voice, color, typography, and UI posture. [VERIFIED: file read]
- `lib/threadline/operator_surface/live/coverage_live.ex` - selected-schema LiveView owner and current old readiness blocks. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/coverage/snapshot.ex`, `coverage/on_mount.ex`, `health/coverage_schemas.ex`, `operator_surface/presentation.ex`, `operator_surface/ui.ex`, `operator_surface/style.ex` - reusable implementation seams. [VERIFIED: codebase grep]
- `test/threadline/operator_surface/live/coverage_live_test.exs`, `coverage_doc_contract_test.exs`, `style_contract_test.exs`, and e2e specs - existing proof lanes. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html - function components, `attr`, global attrs, slots. [CITED: official docs]
- https://hexdocs.pm/phoenix_live_view/live-navigation.html - `push_patch`/`handle_params` URL-backed state. [CITED: official docs]
- https://hexdocs.pm/phoenix_live_view/form-bindings.html - `phx-submit` form behavior. [CITED: official docs]
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html - `render_submit`, form validation warning, LiveView test helpers. [CITED: official docs]
- https://hexdocs.pm/phoenix/security.html - Phoenix security and CSRF/user-controlled content guidance. [CITED: official docs]
- https://playwright.dev/docs/best-practices - role/text/test-id locators and user-facing browser test guidance. [CITED: official docs]
- https://www.w3.org/TR/WCAG22/ - use of color, focus, labels, target size, reflow/accessibility criteria. [CITED: W3C]
- https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/ - disclosure keyboard and aria semantics. [CITED: W3C WAI]
- https://carbondesignsystem.com/components/data-table/usage/ and https://carbondesignsystem.com/patterns/empty-states-pattern/ - operational data table/empty state precedents. [CITED: Carbon Design System]
- https://owasp.org/www-project-application-security-verification-standard/ - ASVS purpose and current stable version reference. [CITED: OWASP]

### Tertiary (LOW confidence)

- None used as authoritative findings; one implementation naming example is marked `[ASSUMED]` in the Assumptions Log.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and constraints are from lockfiles, `mix deps`, `mix hex.info`, npm commands, and project files. [VERIFIED: command output]
- Architecture: HIGH - derived from existing Coverage modules/tests and locked phase context. [VERIFIED: codebase grep]
- Pitfalls: HIGH for codebase pitfalls, MEDIUM where supported by official web docs. [VERIFIED: codebase grep] [CITED: official docs]

**Research date:** 2026-06-29  
**Valid until:** 2026-07-29 for codebase/phase decisions; 2026-07-06 for package/latest-version observations because Phoenix LiveView and Playwright changed recently. [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: npm view @playwright/test version time.modified dist-tags.latest]
