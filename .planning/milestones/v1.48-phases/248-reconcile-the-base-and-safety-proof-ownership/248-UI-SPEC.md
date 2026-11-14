---
phase: "248"
slug: "reconcile-the-base-and-safety-proof-ownership"
status: approved
reviewed_at: "2026-11-10T23:53:31Z"
shadcn_initialized: false
preset: none
created: "2026-11-10"
---

# Phase 248 — UI Design Contract

> This phase preserves the current Admin rendering and specifies the developer-facing mount migration diagnostic. It introduces no screen, styling, component, or runtime brand migration.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, Threadline-owned CSS tokens and Phoenix LiveView/HEEx components |
| Preset | Not applicable; shadcn is not initialized or used |
| Component library | Existing Threadline HEEx modules; no third-party component library |
| Icon library | Existing `Threadline.OperatorSurface.Components.Icon` inline SVG component |
| Font | Preserve the current runtime: Geist with Inter/system fallbacks and IBM Plex Mono with JetBrains Mono/system fallbacks. The approved Familjen Grotesk role is applied only with the coordinated Phase 250 runtime migration. |

### Phase 248 preservation contract

- Keep the current-main candidate and the retained `agent-241-01` checkout intact. Record `port`, `replace`, or `defer` for each retained product, documentation, and test edit; that record is not permission to bulk-copy the old diff.
- `brand/BRAND.md`, `brand/brand.json`, and `brand/assets/README.md` remain the approved identity and asset provenance. Their import does not mean the runtime has migrated.
- Preserve the current operator-surface CSS, fonts, logo rendering, dark/light behavior, routes, and existing component output in this phase. The token values below are baseline references only; do not restyle the UI or migrate runtime assets here.
- Keep old `brandbook/` consumers and `test/threadline/brandbook_token_parity_test.exs` until package, docs, components, and contracts migrate together in their owning later phases.
- The only UI-adjacent behavior specified here is the public mount's compile-time authorization diagnostic. Preserve `Threadline.OperatorSurface.Router`, `threadline_operator_surface/2`, route paths/helpers, option keys, callback return shapes, host-owned authentication, tenant scope, and query-scope threading. `pipe_through` remains host middleware and never proves authorization.
- A mount compiles with a usable one-argument `authorize_fn` or the exact literal `adopter_acknowledges_unauthenticated: true`. `nil`, `false`, arbitrary truthy acknowledgements, feature-specific authorizers, and a pipeline alone do not qualify. A statically recognizable wrong-arity callback fails at compile time; dynamically opaque callbacks retain fail-closed runtime behavior.
- No React, shadcn setup, speculative Fablebook adapter, new UI dependency, login/white-label API, or new rendered surface is in scope.

## Component Inventory

Enumerated by `rg --files lib/threadline/operator_surface/components -g '*.ex' | wc -l` — 4 components — `threadline@1.1.0` (local package version from `mix.exs`) — 2026-11-10.

Cross-check: `find lib/threadline/operator_surface/components -maxdepth 1 -type f -name '*.ex' | wc -l` — 4 files; counts agree. This is a non-exhaustive list of current known-good shared components, not a closed allowlist. Phase 248 adds none.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Icon | `Threadline.OperatorSurface.Components.Icon.icon/1` | Preserve the existing inline SVG icon vocabulary and output. |
| Logo | `Threadline.OperatorSurface.Components.Logo.compact/1` | Preserve current logo rendering; brand asset migration belongs to Phase 250. |
| SurfaceHeader | `Threadline.OperatorSurface.Components.SurfaceHeader.surface_header/1` | Preserve existing shared header and navigation output. |
| UnsupportedView | `Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view/1` | Preserve existing unsupported-view messaging and behavior. |

## Spacing Scale

Preservation reference from `lib/threadline/operator_surface/style/01_tokens.css`; do not add, remove, or remap spacing tokens in Phase 248.

| Token | Value | Usage |
|-------|-------|-------|
| `--tl-space-1` | 4px | Existing smallest token |
| `--tl-space-2` | 8px | Existing inline gap (`--tl-gap-inline`) |
| `--tl-space-3` | 12px | Existing compact spacing |
| `--tl-space-4` | 16px | Existing default stack gap (`--tl-gap-stack`) |
| `--tl-space-5` | 20px | Existing spacing step |
| `--tl-space-6` | 24px | Existing spacing step |
| `--tl-space-8` | 32px | Existing section gap (`--tl-gap-section`) |
| `--tl-space-10` | 40px | Existing spacing step |
| `--tl-space-12` | 48px | Existing spacing step |

Exceptions: retain existing component measurements as-is; no new spacing exception or 64px token is introduced.

## Typography

No typography changes are applicable because Phase 248 changes no rendered interface. These are preservation references, not a new type scale; keep the current CSS and embedded-font configuration unchanged.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body baseline | 16px (`--tl-font-size-body`) | 400 regular baseline | 1.5 |
| Label baseline | 14px (`--tl-font-size-label`) | Existing selector behavior; unchanged | 1.4 |
| Heading baseline | 20px (`--tl-font-size-heading`) | 600 strong baseline | 1.2 |
| Display baseline | 32px (`--tl-font-size-display`) | 600 strong baseline | 1.15 |

Other sizes, weights, and selector usage already in the stylesheet remain untouched and outside this four-size/two-weight snapshot. This phase does not add, remove, or reassign typography tokens. The approved `brand/` type roles are implemented with the coordinated Phase 250 migration.

## Color

No new color composition is applicable. Preserve both current theme lanes exactly; do not normalize them to a new 60/30/10 split in this prerequisite phase. The values below are existing runtime/source references, not new assignments.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (current dark baseline: 62%; light baseline: 64%) | Dark `#0B1020`; light `#F7F9FC` | Existing default dark surface and full light-theme background |
| Secondary (current dark baseline: 24%; light baseline: 22%) | Dark `#141B2D`; light `#FFFFFF` | Existing rows, cards, and panels |
| Accent (current dark/light baseline: 3%) | Dark `#4F8CFF`; light `#1557C0` | Existing links, focus rings, selection, and main button |
| Destructive | Dark `#FF8585`; light `#A33434` | Existing destructive semantics only |

Accent reserved for: the existing primary Thread Blue roles above; Signal Cyan only for correlation IDs; Iris only for code keywords and a selected saved view. Stitch Blue (`#4781E6`) is reserved for the logo thread, never text or controls. Insert, Update, Delete, and Redacted remain written words whose semantic colors reinforce, never replace, their labels.

## Copywriting Contract

There is no end-user CTA, changed empty state, or destructive action in Phase 248. Keep all existing Admin copy unchanged. The compile-time mount error is a developer diagnostic, not a runtime authorization screen.

| Element | Copy |
|---------|------|
| Primary CTA | Not applicable — no end-user interface change. |
| Empty state heading | Not applicable — no changed data surface. |
| Empty state body | Not applicable — preserve existing empty-state copy unchanged. |
| Error state | `CompileError` at the `threadline_operator_surface/2` call: “Threadline.OperatorSurface.Router.threadline_operator_surface/2 requires either a one-argument `authorize_fn` or the exact `adopter_acknowledges_unauthenticated: true` opt-out. `pipe_through` alone does not authorize access. Add `authorize_fn: &MyApp.Audit.authorize_operator/1`, or use the exact opt-out only when this surface is intentionally unauthenticated.” |
| Destructive confirmation | Not applicable — Phase 248 adds no destructive UI action. |

Migration guidance must keep the host pipeline and explain the two explicit choices: add a one-argument `authorize_fn` (successful returns remain `:ok`, `true`, or `{:ok, scope}`), or deliberately acknowledge a public surface with literal `adopter_acknowledges_unauthenticated: true`. Denials, callback exceptions, and invalid callback results remain denied. An invalid acknowledgement never opts out; without a valid authorizer, compilation fails. Do not imply that a pipeline name, export-only authorizer, or other feature-specific callback grants general access. Compile output must point to the mount call and contain no scoped audit data.

## UI Considerations

The deterministic probe detects loading, error and long-text considerations for the developer diagnostic. Autonomous review confirms the only changed surface is synchronous compiler output; no rendered Admin control changes. Each consideration has an explicit observable criterion below.

| Category | Element(s) | Status | Resolution / Reason |
| --- | --- | --- | --- |
| loading | E1: compile-time mount diagnostic | resolved; verification: explicit | Router compilation either succeeds or raises CompileError synchronously; Phase 248 introduces no browser loading state or asynchronous UI. Verify the compile matrix and no changed rendered templates. |
| error | E1: compile-time mount diagnostic | resolved; verification: explicit | Invalid mount raises CompileError at the mount call with authorize_fn and exact acknowledgement remedies, says pipe_through alone is insufficient, and includes no scoped audit values. Verify compile-error assertions. |
| long-text | E1: compile-time mount diagnostic | resolved; verification: explicit | Migration diagnostics retain the full authorize_fn and adopter_acknowledges_unauthenticated option names and call-site location without truncation; test those exact substrings. No changed rendered text requires a new reflow assertion. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | Not initialized; no registry use |
| Third-party registries | none | None declared or used |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved
