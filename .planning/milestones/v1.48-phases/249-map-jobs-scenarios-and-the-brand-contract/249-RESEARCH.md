# Phase 249: Map jobs, scenarios and the brand contract — Research

**Researched:** 2026-11-11  
**Domain:** Phoenix Admin route/proof inventory and example-seed chronology  
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked Decisions

### One semantic inventory and truthful proof kinds
- Extend `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`; reconcile the existing structural `test/fixtures/operator_surface/route-inventory.json`. Create no third registry. Preserve voting identities and nonvoting reasons.
- Map all eleven LiveView patterns, theme POST, three export representations and completed-job download. Assets, embedded fonts, conditional Storybook and example tools receive explicit non-job/tool dispositions rather than invented routes.
- Connect jobs, meaningful states and unique supported interactions to production renderers, source/proof locators and ownership. Separate source contracts, LiveView lifecycle, database, mounted browser, accessibility and visual proof. Existing test references are proof owners, not fresh execution receipts.
- Describe host authentication, per-surface capabilities and organization query scope separately. Support read access does not grant export, evidence, coverage, policy or retention capabilities.

### Ordinary scenario correctness belongs in this phase
- Preserve the fixed Wednesday May 27 2026 12:00Z epoch, stable UUIDv5/persona/ticket/correlation/evidence keys and ephemeral database primary-key distinction. Correct the preceding calendar Tuesday to May 26 14:30Z across manifest, exports, docs and exact contracts.
- Stamp existing business timestamp fields before writes are captured by triggers, through small seed-internal changeset helpers. Keep foundation/base inserts at epoch minus 21 days and capture one run clock for current-window examples. Post-hoc audit clock changes cannot repair captured row JSON.
- Acme #4521 closes at Tuesday 14:30Z with matching ticket/reply snapshots. #4518 replies and closes one hour later, then deletes its reply two hours after the anchor; retain both transaction IDs and closer/deleter distinction.
- Keep agent2 as an agent during its twelve-close window, stamp each close at its own event, and move the separate earlier role-change specimen to existing agent3. Align Globex, ordinary Acme/Globex filler, and current-window timestamps with their represented events.
- Keep AuditAction.inserted_at as actual recording time and AuditContext unchanged. Fictional transaction occurrence time and physical recording time remain distinct. Preserve public schemas, runtime HelpDesk signatures and transaction boundaries.
- Offboarded Co remains the named mass-backdated retention boundary, not an ordinary chronology example. Preserve its 90-day footprint, 60-day purge cutoff, other-organization preservation and final purged-empty scope; add no account departure lifecycle.

### Reset and fixture selection
- `mix demo.reset` is the one clean setup command: it already truncates and seeds. Remove duplicate seeding from the runner, docs and command contracts together; retain guards and advisory locking.
- Direct seed remains a separate in-place operation with repeated effects, without a general idempotence claim.
- Identify ordinary #4521 investigation, separate #4518 reply deletion, Globex and Offboarded Co, and named empty, failed, denied, boundary, long-content, Unicode and duplicate-label cases using existing fixture sources. Preserve dynamic per-test builders.
- Carry SEED-008 findings explicitly: drawer/title overlap to 251/253, dense typography to 250/253, Redaction empty copy to 251/253. Historical screenshot failures remain provenance until reviewed replacements; no blind regeneration or paid critic. Degraded Timeline is an evidence state, not a new route.

### Brand reference and compatibility boundary
- `brand/BRAND.md`, `brand/brand.json` and `brand/assets/README.md` remain authoritative. Map stable role IDs and asset paths to consumers/jobs/proof gaps/later owners without copying token constants, hashes, ratios or creating a separate registry.
- Runtime assets, fonts, colors and existing parity contracts migrate together under later owners, beginning in 250. This phase cannot close ADM-08 onward through documentation alone.
- Keep PhoenixStorybook in the example dev/test boundary and use production Phoenix LiveView/HEEx components. Preserve module, option, route, query, schema and telemetry names while later visible vocabulary follows the approved identity.
- No new dependency, public capability, login/white-label API, React implementation, speculative Fablebook adapter, version bump, hosted dispatch or publication is authorized.

### the agent's Discretion
- Choose compact internal inventory fields and focused contracts at the boundary that observes each claim. Reuse existing research and useful checks; avoid exhaustive theme/viewport cross-products or new CI jobs.
- Required local builds, tests, independent review, fixes and bounded retests are authorized. Use GSD-negotiated executor isolation, background managed checks, current-source evidence and explicit limitations. Existing specific full-repeat/no-retry limits persist.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADM-05 | Every existing Admin route, job, meaningful state and unique supported action is mapped to its owning shared renderer and executable proof or a reasoned unsupported/not-applicable disposition. | Extend the semantic journey inventory; reconcile it to the independently discovered route/control inventory and classify access, proof kind, or non-job disposition. [VERIFIED: .planning/REQUIREMENTS.md:19] |
| ADM-06 | Ordinary fictional help-desk scenarios have internally consistent organizations, actors, records, actions, transactions, chronology and return paths while retaining stable private fixture identities. | Stamp row fields before trigger snapshots; assert event ordering and snapshot timestamps while retaining seed identifiers. [VERIFIED: .planning/REQUIREMENTS.md:20] |
| ADM-07 | Normal examples are separate from named empty, failed, denied, boundary, long-content, Unicode and duplicate-label cases; existing calendar/reset drift and relevant SEED-008 findings receive explicit dispositions. | Reuse named Storybook stress cases, correct the calendar/reset contract, and record the SEED-008 owners without migrating UI. [VERIFIED: .planning/REQUIREMENTS.md:21] |
</phase_requirements>

## Summary

Phase 249 is a traceability and example-data correctness phase. Extend the existing semantic journey inventory and reconcile it to the structural route inventory; do not add another registry. Implement the ordinary seed calendar, reset, and write-time chronology corrections in the Phoenix example. Keep the approved brand crosswalk referential only; runtime branding and fresh whole-job browser/visual acceptance start in Phase 250. [VERIFIED: .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md:10-12,18-42; .planning/ROADMAP.md:66-77]

At pre-implementation research time, sources supported the private scouts’ key recommendations. Compared with 0b36bfc0, relevant changes are limited to the router’s private authorization-callback normalization refactor and the E2E clipboard test’s explicit LiveView-connected wait; the route declarations and demo seed sources remain the basis for the proposed work. The route map then lacked semantic route-to-job-to-proof ownership, and post-capture timestamp rewriting left business-row snapshots inconsistent; implementation outcomes are recorded in the plan summaries. [VERIFIED: git diff 0b36bfc0 -- lib/threadline/operator_surface/router.ex examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts; lib/threadline/operator_surface/router.ex:68-141; examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/temporal.ex:13-29; lib/threadline/capture/trigger_sql.ex:327-380]

**Primary recommendation:** make one compact semantic inventory with proof ownership and access/scope distinctions; repair timestamps at the original seed write, retain post-write audit-clock alignment, and keep fixture, brand, and proof scope within the approved Phase 249 boundary.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Admin page jobs and LiveView URL lifecycle | Frontend Server (SSR) | API / Backend | Phoenix router declarations select shared LiveView renderers; lifecycle and URL transitions need LiveView proof. [VERIFIED: lib/threadline/operator_surface/router.ex:68-89] |
| Theme preference and export/download HTTP actions | API / Backend | Frontend Server (SSR) | These are sibling HTTP handlers with their own authorization path, separate from LiveView sessions. [VERIFIED: lib/threadline/operator_surface/router.ex:92-141] |
| Authentication, capability and organization query scope | API / Backend | Database / Storage | The example host owns authentication and surface policy; query transforms must fail closed for unrecognized scopes. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:111-170] |
| Example scenarios and captured row history | Database / Storage | API / Backend | PostgreSQL triggers snapshot original row values; seed correctness must be established at write time. [VERIFIED: lib/threadline/capture/trigger_sql.ex:327-380] |
| Approved brand-to-renderer reference map | CDN / Static (future runtime owner) | Frontend Server (SSR) | Phase 249 records role/asset consumers and proof gaps; runtime asset integration is a later phase. [VERIFIED: .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md:38-42] |

## Project Constraints (from AGENTS.md)

- Keep Capture, Semantics, and Exploration/operations responsibilities distinct; use the project terms AuditTransaction, AuditChange, AuditAction, AuditContext, ActorRef, and Correlation consistently. [VERIFIED: AGENTS.md:9-28]
- Preserve the trigger-backed capture boundary and host-owned Ecto migrations. [VERIFIED: AGENTS.md:78-86]
- Use named verification entrypoints and keep default test coverage honest; do not weaken or silently exclude suites. [VERIFIED: AGENTS.md:49-76]
- Automate routine verification, keep evidence tied to source/fixture/conditions, and use bounded checks rather than inventing new recurring CI. [VERIFIED: AGENTS.md:88-113; .planning/conventions/research-verification-and-efficiency.md:23-64]
- Keep the signed-off brand sources authoritative, preserve old brand references until coordinated migration, and keep PhoenixStorybook in the example dev/test boundary with production LiveView/HEEx components. [VERIFIED: AGENTS.md:84-111; .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md:38-42]
- Preserve public module, option, route, query, schema and telemetry names; do not add login or white-label APIs, React, or a speculative Fablebook adapter. [VERIFIED: .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md:38-42]

## Standard Stack

No new packages are needed or authorized for this phase. Use the current example stack and existing proof suites. [VERIFIED: .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md:38-42]

| Component | Declared version / role | Purpose |
|-----------|-------------------------|---------|
| Elixir | Example constraint is `~> 1.15`; local Elixir 1.17.3 with OTP 27 | Seed implementation and ExUnit contracts. [VERIFIED: examples/threadline_phoenix/mix.exs:4-9; local elixir --version] |
| Phoenix / LiveView | `~> 1.8.5` / `~> 1.0` | Existing router, shared production renderers, and LiveView lifecycle. [VERIFIED: examples/threadline_phoenix/mix.exs:62-81] |
| Ecto SQL / Postgrex | `~> 3.13` / `>= 0.0.0` | Example persistence, fixture writes, and database contracts. [VERIFIED: examples/threadline_phoenix/mix.exs:62-81] |
| PhoenixStorybook | `~> 1.2.0`, dev/test only | Existing component states and stress examples; not a mounted-route proof. [VERIFIED: examples/threadline_phoenix/mix.exs:79-81] |
| ExUnit and Node test runner | Existing Mix test task and `tsx --test` | Focused database contracts and route-inventory contract. [VERIFIED: examples/threadline_phoenix/mix.exs:91-99; examples/threadline_phoenix/e2e/package.json:5-10] |

**Package Legitimacy Audit:** Not applicable. The phase adds no external package.

## Architecture Patterns

### Semantic route and proof inventory

Keep `test/fixtures/operator_surface/route-inventory.json` structural and enrich `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` with job/state/action, production renderer or explicit no-renderer disposition, proof locator and proof kind, access/scope owner, and brand role references where useful. The route-evidence test independently checks eleven router paths; the existing inventory tests do not yet establish complete semantic linkage. [VERIFIED: examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts:7-20; examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts:71-84]

The library router declares eleven LiveView paths, including two transaction routes rendered by TransactionLive, plus theme POST and four export GET handlers. Keep these as route/action entries, not invented page renderers. Classify static assets, embedded fonts, conditional Storybook and example-only tools as support/tool entries. [VERIFIED: lib/threadline/operator_surface/router.ex:68-141; examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:365-378]

Map host authentication, per-surface capability, and organization scope separately. The example permits organization-scoped support reads while export, evidence, coverage, and policy callbacks are admin-only; the test suite has allowed/denied scope examples. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:111-170; examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs:42-100]

### Seed writes before capture

The current helper records transaction IDs for later audit timestamp rewriting; the trigger captures the business row during the original INSERT/UPDATE. Add only seed-internal timestamp stamping to each original row changeset, before Repo writes, and keep the existing timestamp map for transaction/change clocks. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex:12-17; examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/temporal.ex:13-29; lib/threadline/capture/trigger_sql.ex:347-380]

The ticket schema declares `field(:closed_at, :utc_datetime)` and `timestamps(type: :utc_datetime)`. Ecto defines its generated timestamp fields as `:inserted_at` and `:updated_at`, and exposes put_change/3. Stamp those schema fields through a small internal helper before the trigger snapshot; align domain fields such as closed_at to the same represented event. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix/help_desk/ticket.ex:9-23; deps/ecto/lib/ecto/schema.ex:2114-2145; deps/ecto/lib/ecto/changeset.ex:1963-1971]

    changeset
    |> Ecto.Changeset.put_change(:inserted_at, event_at)
    |> Ecto.Changeset.put_change(:updated_at, event_at)

Compute one run clock for current-window fixtures and derive event times before writes. For each multi-transaction story, retain both transaction IDs and assert insert/update/delete partial order as well as snapshot field values. Do not use AuditAction recording time as the fictional event time. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex:93-134,228-318,358-393; .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md:24-30]

### Calendar, reset, and fixture selection

Keep the fixed epoch; the current manifest literally sets `@demo_epoch ~U[2026-05-27 12:00:00Z]` and `@demo_last_tuesday ~U[2026-05-20 14:30:00Z]`. Correct the prior-calendar-Tuesday anchor to the locked May 26 14:30Z value and update docs, export CSV date and exact contracts together. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex:62-63; intended correction: .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md:24-26]

Reset already truncates then seeds. Make `mix demo.reset` the sole clean setup recipe and remove the duplicate `mix demo.seed` from the runner/docs/contracts. Keep the production guard and advisory lock; direct seed remains an in-place operation and the current “does not raise” repeat test is not an idempotence guarantee. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex:125-139; examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:235-242; examples/threadline_phoenix/e2e/run-e2e.sh:432-434]

### Brand crosswalk

Reference role IDs to consumers and later proof owners without copying token values or ratios. Approved IDs are `body, descriptor, caption, application-copy, hero, link, focus, artwork`; map text/metadata to shared page renderers, interaction roles to link/focus proofs, and artwork to the shared shell/logo owner. [VERIFIED: brand/BRAND.md:5; brand/brand.json:280-424]

Reference supplied asset paths in `brand/assets/README.md` rather than creating an asset registry. The light/dark lockups and favicon belong to the shared shell; the supplied font files and licenses belong to the later runtime/package migration. Phase 249 records the links only; Phase 250 begins rendering work and Phase 253 owns broader package/docs reconciliation. [VERIFIED: brand/assets/README.md:5-45; .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md:38-42]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route/job/state registry | A third route, fixture or visual catalog | Existing structural route fixture plus semantic journey inventory | Keeps route declarations distinct from jobs and proof ownership. [VERIFIED: 249-CONTEXT.md:18-22] |
| Time virtualization | Public clock option, process-global clock or post-hoc row repair | Seed-only changeset timestamp helper plus existing audit timestamp map | Trigger snapshots happen at the original write. [VERIFIED: trigger_sql.ex:347-380; seed/temporal.ex:13-29] |
| Brand token/asset registry | Duplicated constants, hashes, ratios or asset index | References to approved brand sources | Those files remain authoritative and later runtime owners verify rendering. [VERIFIED: 249-CONTEXT.md:38-42] |
| Auth and organization scope | UI-only access labels or new auth API | Existing host callbacks and scoped query function, documented separately | Support read access does not confer other surface capabilities. [VERIFIED: example router.ex:111-170] |

## Common Pitfalls

- **Treating the old Wednesday anchor as Tuesday:** keep the epoch and correct the anchor, docs, CSV and exact assertions together. Current values are quoted above. [VERIFIED: manifest.ex:62-63]
- **Backdating only audit rows:** trigger snapshots keep the original inserted/updated/closed timestamps; fix them before writes and test AuditChange snapshots as well as final rows. [VERIFIED: trigger_sql.ex:347-380; seed/temporal.ex:13-29]
- **Calling direct seed idempotent:** its current repeat contract checks only that it does not raise; clean recovery is reset. [VERIFIED: demo_contract_test.exs:235-242; reset.ex:125-139]
- **Calling the 4518 story a reply-delete only:** current code records a reply-and-close semantic action but passes open status and discards the insert transaction ID. Make the story status and insert-before-delete ordering truthful while retaining closer/deleter distinction. [VERIFIED: seed/anchors.ex:93-134]
- **Calling all inventory proofs equivalent:** source contracts, database behavior, mounted lifecycle, accessibility, and visual evidence establish different things. Existing references are not fresh run receipts. [VERIFIED: 249-CONTEXT.md:18-22; .planning/conventions/research-verification-and-efficiency.md:41-64]
- **Changing retention brackets while fixing chronology:** preserve the strict 21 < 60 < 90 ordering and the purged-empty Offboarded Co boundary. [VERIFIED: seed/retention_tail.ex:14-20,32-64,159-180]

## State of the Art

No framework or dependency change is part of this phase. Continue Phoenix LiveView/HEEx and PhoenixStorybook at the example dev/test boundary; the approved context explicitly defers Fablebook until a deliberate adoption decision. [VERIFIED: 249-CONTEXT.md:38-42]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | No unresolved assumption identified; implementation schema details remain within the agent’s discretion and must not create another registry. | Architecture Patterns | Planner should keep the inventory change compact and test the semantic links. |

## Open Questions

No maintainer decision is needed for planning. Existing product, compatibility, security and phase boundaries are locked in CONTEXT.md. [VERIFIED: 249-CONTEXT.md:15-46]

## Environment Availability

No app or test suite was run. These are preflight observations only; do not start a service from this research. [VERIFIED: local version/path probes]

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix / OTP | Example seed and ExUnit contracts | Yes | Elixir 1.17.3 / Mix 1.17.3 / OTP 27 | Use the approved CI toolchain if support-policy preflight requires it. |
| PostgreSQL client/server | Seed snapshot and reset contracts | Client present; local endpoint accepted connections | psql 14.17; server version/capacity not checked | Complete task-owned DB capacity and support-floor preflight before tests; do not start or alter a shared server here. |
| Example Mix dependencies | Example ExUnit contracts | Missing at research time | — | Resolve existing lockfile dependencies during approved implementation setup. |
| Node/npm | Inventory contract | Yes | Node 22.14.0 / npm 10.9.2 | — |
| E2E Node modules / Playwright browser cache | Focused TypeScript inventory test; mounted browser proof belongs later | Missing at research time | — | Install from the existing lockfile only if the focused inventory test is executed; Phase 249 does not need a browser run. |

## Validation Architecture

Nyquist validation is enabled in project configuration. Keep proofs at their observable boundary, use managed background checks with logs/exit status for any authorized run, and record invocation failures before retries. No tests, apps, database services, or long checks were run for this research. [VERIFIED: .planning/config.json; AGENTS.md:58-68]

| Req ID | Behavior to prove | Focused proof |
|--------|-------------------|---------------|
| ADM-05 | Semantic inventory covers route/job/state/action and links each to renderer, proof kind, and access/scope or explicit disposition. | Extend the existing route/journey inventory contract; focused command from the E2E directory: `./node_modules/.bin/tsx --test support/operator-route-evidence.test.ts`. Also retain the root source-coverage contract: `mix test test/threadline/operator_surface/operator_evidence_contract_test.exs`. |
| ADM-06 | Seeded stories preserve identities and actor distinctions; business fields in captured snapshots agree with event clocks and multi-step events are ordered. | Add focused assertions in the existing example demo contract, querying AuditChange snapshots and AuditTransaction occurrence times. Run the single example ExUnit file only after environment preflight. |
| ADM-07 | Calendar and reset docs/contracts agree; ordinary and named stress fixtures remain separate; retention guard/purge behavior survives. | Focused manifest, reset, demo-contract and retention-tail contracts. Keep the production reset guard, advisory lock, strict purge invariant, other-organization survival, and final empty scope. |

**Snapshot partial orders to assert:** setup/base rows at S precede ordinary actor events; #4521 row/reply snapshots match its close event; #4518 reply-and-close precedes deletion; each agent2 close snapshot matches its own event while its role remains agent and the earlier role-change belongs to agent3; Globex, current-window and Acme/Globex filler timestamps match their represented event. Assert both final business rows and trigger snapshots, not only the post-backfill audit clocks. [VERIFIED: 249-CONTEXT.md:24-30; seed/anchors.ex:63-184; trigger_sql.ex:347-380]

**No-repeat and run limits:** retain existing reset guard/lock and retention/purge tests. Do not add a second seed to clean setup or call the current “does not raise” test an idempotence proof. Previous full-repeat grants are consumed; this research does not authorize a full flake, canonical, or browser run.

## Security Domain

The route inventory is security-relevant because access differs by surface and organization. ASVS 5.0.0 is the current OWASP stable release; its chapter mapping differs from older V-number summaries. Applicable categories for this mapping phase are V1 Encoding and Sanitization (query/path and rendered content boundaries), V2 Validation and Business Logic (validated state and operation ordering), V3 Web Frontend Security, V4 API and Web Service (theme/export handlers), V5 File Handling (completed export downloads), V6 Authentication, V7 Session Management, and V8 Authorization (function- and data-level permissions). No cryptographic implementation is changed; do not add a V11 cryptography task based on this phase. [CITED: https://asvs.owasp.org/; https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.csv]

| Threat pattern | Standard mitigation to preserve |
|----------------|---------------------------------|
| Cross-organization record access | Keep host scope query filtering and scoped-not-found behavior. [VERIFIED: example router.ex:152-170; operator_surface_test.exs:42-60] |
| Surface capability confusion | Record host authentication, LiveView authorization, and HTTP export/evidence/coverage/policy authorization separately. [VERIFIED: router.ex:111-150; lib/threadline/operator_surface/router.ex:92-141] |
| Query or return-context tampering | Point to existing validated query and return-path contracts; do not treat a static story as lifecycle proof. [VERIFIED: operator-journey-inventory.json:4-38; 249-CONTEXT.md:18-22] |

## Sources

### Primary

- Current route declarations and host auth/scope: `lib/threadline/operator_surface/router.ex`; `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`.
- Current seed/capture behavior and contracts: `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/`; `lib/threadline/capture/trigger_sql.ex`; focused ExUnit and route-evidence tests cited above.
- Approved phase boundary and requirements: `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md`, `.planning/REQUIREMENTS.md`, and `.planning/ROADMAP.md`.
- Approved identity and assets: `brand/BRAND.md`, `brand/brand.json`, and `brand/assets/README.md`.

### External primary

- OWASP ASVS 5.0.0 overview and release details: https://asvs.owasp.org/
- OWASP ASVS 5.0.0 category/requirement source: https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.csv

## Metadata

**Confidence breakdown:** Standard stack HIGH (current project declaration); architecture HIGH (current router, host policy and trigger sources); pitfalls HIGH (current seed and contract sources).  
**Research date:** 2026-11-11  
**Valid until:** 2026-12-11 for stable in-repo structure; recheck current source before planning or execution.
