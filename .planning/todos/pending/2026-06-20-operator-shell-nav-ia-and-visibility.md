---
created: 2026-06-20T12:25:36Z
title: Operator shell nav IA and visibility
area: operator-surface
origin: User demo feedback after Phase 179/180 operator-surface review.
files:
  - lib/threadline/operator_surface/components/surface_header.ex
  - lib/threadline/operator_surface/ui.ex
  - lib/threadline/operator_surface/style.ex
  - test/threadline/operator_surface/surface_header_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
---

## Problem

The operator shell navigation was not removed, but it is too easy for a demo user to miss or read as
incidental. The current shell still renders `operator-nav-shell` with Overview, Timeline, Coverage,
Evidence, Redaction, Retention, Exports, and the theme picker. At mobile/base widths the native
`details` panel is hidden behind a generic `Menu` label; at tablet/desktop widths the panel becomes a
quiet left rail.

That technically works, but the user feedback shows a discoverability gap:

- A first-time operator may not connect `/audit` job cards to the persistent destinations.
- The mobile summary label `Menu` is too generic for a page that has both app-level and operator-level
  navigation concepts.
- The shell uses a `details` disclosure with navigation semantics, but it may not be perceived as a
  durable navigation landmark.
- Page-level cross-surface CTAs, such as Coverage's `Open timeline`, become tempting compensations
  when the nav is not obvious, which creates duplicate affordances.

## Solution

Keep the Phase 179 IA decision: task-led Home, domain-led shell nav. Do not copy the `/audit` job
cards wholesale into the sidebar, and do not churn route paths, current atoms, hrefs, or data-testids.

Improve discoverability and semantics instead:

- Preserve the stable shell destinations and grouping: Overview, Investigate/Timeline, Audit
  readiness/Coverage, Evidence and exports/Evidence, Redaction, Retention, Exports.
- Make the shell a stronger navigation landmark, for example with an explicit `nav` wrapper or
  equivalent semantics around the existing native disclosure.
- Rename the mobile disclosure from `Menu` to a more specific label such as `Audit navigation` or
  `Operator navigation`.
- Strengthen desktop/tablet visibility and active-state affordance without making the rail card-like
  or visually louder than the page's primary task.
- Keep CSP-clean native behavior; no inline handlers or custom nav JavaScript.
- Remove page-level cross-surface CTA duplication where the shell nav already owns the destination.

## Acceptance Criteria

- Every operator page renders exactly one operator shell nav when `base_path` is present.
- At desktop/tablet widths, the enabled nav destinations are visibly present and hit-testable without
  opening a disclosure.
- At mobile widths, the disclosure label clearly names operator/audit navigation and opens with pointer
  and keyboard interaction.
- Active page state remains obvious and accessible with `aria-current="page"` where appropriate.
- Feature-gated destinations continue to fail closed without leaving confusing empty groups.
- Existing route hrefs, current atoms, destination order, and data-testids remain stable unless a future
  phase explicitly scopes a breaking IA change.
