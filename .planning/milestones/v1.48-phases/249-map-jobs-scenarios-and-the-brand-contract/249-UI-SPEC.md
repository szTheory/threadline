---
phase: "249"
slug: "map-jobs-scenarios-and-the-brand-contract"
status: approved
shadcn_initialized: false
preset: none
created: "2026-11-11"
---

# Phase 249 — UI Design Contract

> Reference-only visual and interaction contract. Phase 249 maps existing Admin work, scenarios, brand roles, and proof ownership. It does not change rendered UI, runtime assets, fonts, colors, or behavior.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, project-owned Phoenix LiveView/HEEx |
| Preset | Not applicable |
| Component library | Existing `Threadline.OperatorSurface` production components; no external UI library |
| Icon library | Project-owned `Threadline.OperatorSurface.Components.Icon` |
| Font | Preserve current runtime font configuration in `lib/threadline/operator_surface/fonts.ex` and `lib/threadline/operator_surface/style/01_tokens.css`; approved brand-role migration is owned by Phase 250 |

PhoenixStorybook remains in the example/dev/test boundary. It is a catalog surface over shared production components, not a production route or replacement renderer. This phase adds no React, Fablebook, login, white-label, dependency, or public API contract.

## Component Inventory

Enumerated by `find lib/threadline/operator_surface/components -maxdepth 1 -type f -name '*.ex' -print | sort` — 4 components — `threadline@1.1.0` — 2026-11-11.

Cross-check: `ls lib/threadline/operator_surface/components/*.ex 2>/dev/null | wc -l` returned 4; no mismatch. This is the project-owned source inventory, not an installed third-party package allowlist. Route renderers are listed below and remain discoverable outside this short component list.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Icon | `Threadline.OperatorSurface.Components.Icon` | Existing shared icon renderer; preserve current behavior |
| Logo | `Threadline.OperatorSurface.Components.Logo` | Existing artwork renderer; preserve current artwork until Phase 250 migration |
| SurfaceHeader | `Threadline.OperatorSurface.Components.SurfaceHeader` | Shared header and theme interaction; existing contract remains unchanged |
| UnsupportedView | `Threadline.OperatorSurface.Components.UnsupportedView` | Explicit unsupported-state renderer; keep unsupported distinct from empty or unavailable |

## Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| Existing runtime scale | See `lib/threadline/operator_surface/style/01_tokens.css` | Reference only; preserve the current scale |

No new scale or spacing values are declared in Phase 249. Exceptions: none introduced; existing touch, focus, and responsive behavior remain owned by current source and proof references.

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | Existing runtime source | Existing runtime source | Unchanged |
| Label | Existing runtime source | Existing runtime source | Unchanged |
| Heading | Existing runtime source | Existing runtime source | Unchanged |
| Identifier | Existing runtime source | Existing runtime source | Unchanged |

This phase chooses no font sizes, weights, or line heights and copies no font token values. The approved font roles and supplied files remain authoritative in `brand/BRAND.md`, `brand/brand.json`, and `brand/assets/README.md`; Phase 250 owns runtime adoption and actual served-font acceptance, and Phase 253 owns package and license reconciliation.

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant | Existing runtime source; no new value declared | Preserve current surfaces; approved role mapping is a Phase 250 task |
| Secondary | Existing runtime source; no new value declared | Preserve current panels and navigation |
| Accent | Existing runtime source; no new value declared | Keep brand artwork, interactive controls, links, and focus as distinct source roles |
| Destructive | Existing runtime source; no new value declared | Preserve current destructive-state behavior and wording |

The approved stable contrast-role IDs are `body`, `descriptor`, `caption`, `application-copy`, `hero`, `link`, `focus`, and `artwork`, defined in `brand/brand.json`. Stitch Blue remains artwork-only; operation names remain words, with semantic colors as a secondary cue. This phase declares no 60/30/10 composition split and copies no color values or contrast ratios into a parallel registry. Phase 250 owns the role-to-runtime-token map and rendered checks; Phase 253 owns complete Admin acceptance.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | No new CTA copy. Preserve current text and map each supported action to its existing job, renderer, and proof owner. |
| Empty state heading | No new empty-state copy. Map each applicable existing empty state to its source and proof owner. |
| Empty state body | Preserve current next-step guidance; Phase 249 records the corresponding state and evidence owner without rewriting UI copy. |
| Error state | Preserve current error distinctions and recovery behavior. Map invalid, denied, failed, unavailable, and stale states to their source/proof or a reasoned disposition. |
| Destructive confirmation | No new destructive action or copy. Preserve existing Retention confirmation, cancellation, authorization, and mutation behavior; Phase 252 owns later rendered acceptance. |

For later visible language, use `Threadline Admin`, `audit trail library`, and the plain vocabulary in `brand/BRAND.md` and `brand/brand.json`. Keep UI wording distinct from compatible module, option, route, query, schema, and telemetry names. Do not imply capture, actor context, retention, or historical coverage beyond the actual supported data.

## Current Renderer, State, and Proof Map

Phase 249 extends `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` with the route/job/state/action to renderer and proof links. Reconcile `test/fixtures/operator_surface/route-inventory.json` as structural input; do not create a third registry. Proof references below are owners, not fresh execution receipts.

| Route or action | Existing renderer | Job and meaningful state coverage to map | Existing proof owner(s) |
|----------------|--------------------|-----------------------------------------|-------------------------|
| `GET /audit` | `StartLive` | Enter Timeline, row/correlation lookup, saved search; invalid lookup and degraded health | `operator-timeline-investigation-flow.spec.ts`; `operator-earned-flows.spec.ts` |
| `GET /audit/timeline` | `TimelineLive` | Filter, reset, paginate, save/apply/delete search, pivot, open transaction/history, copy, export; populated, pending, empty, invalid, query failure, unknown table | `operator-timeline-investigation-flow.spec.ts`; `operator-route-states.spec.ts` |
| `GET /audit/transactions/:id` | `TransactionLive` | Inspect action/context and row changes; not found or unavailable | `operator-transaction-evidence.spec.ts` |
| `GET /audit/transactions/:id/history/:table/:record_id` | `TransactionLive` | Open/close history drawer and retain focus/return context | `operator-earned-flows.spec.ts` |
| `GET /audit/rows/:table/:record_id` | `RowHistoryLive` and `RowHistoryComponent` | Direct record history, as-of selection, retry and return; unmapped table, failed read, deleted snapshot, before-audit-horizon snapshot | `operator-earned-flows.spec.ts` |
| `GET /audit/actors/:kind/:id` | `ActorLive` | Inspect human/system actor, set window, paginate, pivot; distinguish invalid/not-found, never-acted, and outside-window | `operator-route-states.spec.ts`; `operator-earned-flows.spec.ts` |
| `GET /audit/coverage` | `CoverageLive` | Select schema, refresh, inspect readiness, expand remediation, copy command, follow covered-table activity; invalid schema, stale/unavailable, empty, role-limited | `operator-coverage-readiness.spec.ts`; `operator-phase-135-uat.spec.ts` |
| `GET /audit/evidence` | `EvidenceLive` | Inspect subject/reference, open proof history, retry and carry context; invalid query, empty, unavailable, unsupported/denied | `operator-route-states.spec.ts` |
| `GET /audit/exports` | `ExportStatusLive` | Queue/refresh, inspect, download completed work, return to source search; loading, empty, preparing, ready, failed, expired/unavailable, invalid context | `operator-route-states.spec.ts`; `operator-accessibility.spec.ts`; export controller tests |
| `GET /audit/policy/redaction` | `PolicyRedactionLive` | Inspect configured/deployed details; match, drift, no policy, missing trigger, unreadable deployment, invalid schema | `operator-route-states.spec.ts` |
| `GET /audit/policy/retention` | `RetentionHistoryLive` | Refresh, open/cancel/confirm prune; loading, error, empty, loaded, busy/disabled, denied, mutation outcome | `operator-route-states.spec.ts`; `operator-features.spec.ts` |

Also map `POST /audit/theme` to the existing `ThemeController` and shared header, and map the CSV/JSON/NDJSON export responses plus `GET /audit/exports/download/:job_id` to their controller actions with no page renderer. Current owners include `operator-route-states.spec.ts` and `test/threadline/operator_surface/controllers/export_controller_test.exs`.

Static assets, embedded fonts, conditional PhoenixStorybook routes, example help-desk writes, and mailbox preview receive explicit shared-resource or dev/test-tool dispositions. They do not become invented user jobs. Keep host authentication, per-surface capability checks, and organization query scope as separate mapped facts; support-read access does not imply export, evidence, coverage, policy, or retention access. A Storybook render does not prove URL lifecycle, database persistence, authorization, download, or mutation behavior.

## Scenario Contract

| Scenario class | Contract |
|----------------|----------|
| Ordinary investigation | Use the stable fictional Acme #4521 Timeline-to-transaction-to-record-history story, with actor, correlation, redacted note, exact record identity, and return context. Preserve the fixed UTC anchor and correct the preceding calendar date in all seed, export, docs, and exact contracts. |
| Separate ordinary change | Keep Acme #4518 as a distinct later reply/close/delete story with the correct event ordering and separate closer/deleter identities. Keep Agent 2 an agent during its twelve-close window; place the separate earlier role-change example on Agent 3. Align Globex and ordinary filler to represented events. |
| Retention boundary | Offboarded Co remains the named mass-backdated boundary with its existing 90-day footprint, 60-day purge cutoff, other-organization preservation, and final empty scope. It is not normal chronology and does not introduce an account-departure lifecycle. |
| Stress/state cases | Keep existing named empty, failed, denied, boundary, long-content, Unicode, and duplicate-label fixtures separate from ordinary business data. Use existing fixture sources and dynamic test builders. |
| Reset behavior | `mix demo.reset` remains the single clean reset-and-seed command. Direct seed remains a separate in-place operation with repeated effects and no general idempotence claim. |

Keep business timestamps on writes before trigger capture; preserve the distinction between fictional event time and actual AuditAction recording time. Retain stable private UUID/persona/ticket/correlation/evidence identities and the distinction from ephemeral database primary keys. Phase 249 documents and corrects scenario data; it does not change the public clock API, runtime HelpDesk signatures, transaction boundaries, AuditContext, or renderer behavior.

## Approved Brand Crosswalk (Reference Only)

`brand/BRAND.md`, `brand/brand.json`, and `brand/assets/README.md` are authoritative. The following crosswalk belongs in the existing phase/journey inventory as source references and consumers; do not copy color/font values, hashes, contrast ratios, or create a brand registry.

| Brand source or role | Current consumer/job | Current proof or gap to record | Later acceptance owner |
|----------------------|----------------------|--------------------------------|------------------------|
| Name, voice, and domain vocabulary in `brand/BRAND.md` / `brand/brand.json` | Shared header, `Presentation`, all Admin jobs, guides and example docs | Existing copy and route checks are owners only; current wording is not proof of approved-brand adoption | Phase 250 first investigation; 251 remaining inspection; 252 operations; 253 docs/package reconciliation |
| Stable contrast IDs in `brand/brand.json` | Shared CSS tokens, header, controls, operation/status labels, values, timeline and detail renderers | `brandbook_token_parity_test.exs` still represents historical `brandbook/` authority and does not establish the approved role mapping | Phase 250 foundation mapping and rendered role checks; Phase 253 complete acceptance |
| Light/dark lockups and marks in `brand/assets/README.md` (`logo/threadline-lockup-*`, `logo/threadline-mark-*`) | `Components.Logo`, `SurfaceHeader`, shared shell | Existing logo/header contracts describe current artwork; they do not prove the supplied artwork or its theme variant | Phase 250 runtime use; Phase 253 packaged-asset proof |
| Light/dark favicon sources in `brand/assets/README.md` (`icon/favicon-*`) | Example Admin favicon and shared host layout | Existing static response proof identifies the current asset only | Phase 250 theme-correct asset use; Phase 253 package reconciliation |
| Supplied type and license files in `brand/assets/README.md` (`fonts/web/fonts.css`, supplied font files and licenses) | `Fonts`, shared CSS, headings, reading/table copy, IDs and code | Current embedded font and byte-lock evidence establish current runtime bytes, not the later approved role mapping | Phase 250 actual served-font/fallback proof; Phase 253 package and license proof |
| Dark, Light, and System behavior in `brand/BRAND.md` | Existing `ThemeController`, header, style selector, and shared route shell | Current theme-route tests remain behavior owners; no Phase 249 theme change or fresh visual claim | Phase 250 theme flow and rendered role proof; Phase 253 inclusive integration |
| Operation and value truth rules in `brand/BRAND.md` / `brand/brand.json` | `Presentation`, timeline, transaction, history, export, retention, and redaction jobs | Existing source/copy checks are references; preserve word plus semantic cue and keep null, missing, Redacted, left-out, and unavailable distinct | Phase 250 investigation; Phase 251 inspection; Phase 252 operations; Phase 253 complete reconciliation |

Phase 249 records stable role IDs and source asset paths with consuming jobs, shared owners, proof references/gaps, and later owners. It neither migrates these consumers nor closes ADM-08 onward by documentation alone. Preserve existing runtime artwork, fonts, colors, theme behavior, and parity contracts until their coordinated later migration.

## UI Considerations

Compiled probe over the three described mapping surfaces produced 22 applicable considerations. Autonomous kind review supplied the union of form, collection, navigation, control, media and static-content kinds as appropriate. These are explicit inventory acceptance criteria, not fresh rendered-UI receipts.

| Element | Category | Status | Verification | Acceptance criterion |
| --- | --- | --- | --- | --- |
| U1 | empty | resolved | explicit | Each applicable Admin route/job entry records absent/no-data behavior or a source-grounded not-applicable reason. |
| U1 | loading | resolved | explicit | Each applicable Admin route/job entry records in-flight behavior or a source-grounded not-applicable reason. |
| U1 | error | resolved | explicit | Each applicable Admin route/job entry records error/unavailable behavior and recovery proof or a source-grounded not-applicable reason. |
| U1 | populated | resolved | explicit | Each applicable Admin route/job entry links its representative ordinary source and proof owner. |
| U1 | partial | resolved | explicit | Each applicable Admin route/job entry records missing/partial-data meaning and proof owner or a source-grounded not-applicable reason. |
| U1 | overflow | resolved | explicit | Each applicable Admin route/job entry links its named long-content/boundary fixture and proof owner or a source-grounded not-applicable reason. |
| U1 | zero-one-many | resolved | explicit | Each applicable Admin route/job entry records applicable zero/one/many count states and proof owner or a source-grounded not-applicable reason. |
| U1 | long-text | resolved | explicit | Each applicable Admin route/job entry links named long-content/Unicode/duplicate-label data and proof owner or a source-grounded not-applicable reason. |
| U2 | empty | resolved | explicit | Each named ordinary or stress scenario records absent/no-data behavior or a source-grounded not-applicable reason. |
| U2 | loading | resolved | explicit | Each named ordinary or stress scenario records in-flight behavior or a source-grounded not-applicable reason. |
| U2 | error | resolved | explicit | Each named ordinary or stress scenario records error/unavailable behavior and recovery proof or a source-grounded not-applicable reason. |
| U2 | populated | resolved | explicit | Each named ordinary or stress scenario links its representative ordinary source and proof owner. |
| U2 | partial | resolved | explicit | Each named ordinary or stress scenario records missing/partial-data meaning and proof owner or a source-grounded not-applicable reason. |
| U2 | overflow | resolved | explicit | Each named ordinary or stress scenario links its named long-content/boundary fixture and proof owner or a source-grounded not-applicable reason. |
| U2 | zero-one-many | resolved | explicit | Each named ordinary or stress scenario records applicable zero/one/many count states and proof owner or a source-grounded not-applicable reason. |
| U2 | long-text | resolved | explicit | Each named ordinary or stress scenario links named long-content/Unicode/duplicate-label data and proof owner or a source-grounded not-applicable reason. |
| U3 | empty | resolved | explicit | Each mapped logo/font/brand-role consumer records absent/no-data behavior or a source-grounded not-applicable reason. |
| U3 | loading | resolved | explicit | Each mapped logo/font/brand-role consumer records in-flight behavior or a source-grounded not-applicable reason. |
| U3 | error | resolved | explicit | Each mapped logo/font/brand-role consumer records error/unavailable behavior and recovery proof or a source-grounded not-applicable reason. |
| U3 | populated | resolved | explicit | Each mapped logo/font/brand-role consumer links its representative ordinary source and proof owner. |
| U3 | overflow | resolved | explicit | Each mapped logo/font/brand-role consumer links its named long-content/boundary fixture and proof owner or a source-grounded not-applicable reason. |
| U3 | long-text | resolved | explicit | Each mapped logo/font/brand-role consumer links named long-content/Unicode/duplicate-label data and proof owner or a source-grounded not-applicable reason. |

U1 is the renderer/state/proof map; U2 is the scenario contract; U3 is the reference-only brand crosswalk. No new runtime media/loading/interaction behavior is implied; unsupported combinations require explicit reasons in the inventory. Later phases own fresh UI acceptance.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| No shadcn registry | None | Not applicable; project UI is hand-authored Phoenix LiveView/HEEx |
| Third-party registries | None | None declared; no registry blocks added |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** Independent UI checker approved all seven dimensions on 2026-11-11; compiled consideration resolution appended afterwards.
