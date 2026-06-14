# Phase 169: screenshots-example-docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 169-screenshots-example-docs
**Areas discussed:** Light lane naming, Light coverage scope, Docs surface + lock, Adopter recommendation
**Mode:** advisor (minimal_decisive tier — research-then-recommend; 4 parallel codebase research agents)

---

## Light lane naming & mechanism (recommendation locked, not voted)

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse 168 light project + keep `__default__`, add `__light__` | Widen `desktop-chromium-light` testMatch to the screenshots spec; emit `__light__` in the light lane; no rename of dark baselines | ✓ |
| Rename `__default__` → `__dark__` for symmetry | Churns 48 committed baselines + doc refs for zero functional gain | |

**Resolution:** Locked by recommendation (D-01, D-02). Research confirmed the Phase-168
plumbing (`desktop-chromium-light`, `THREADLINE_E2E_THEME=system`, `verify.example_browser_light`)
already exists and `__default__` is the dark lane across 48 committed baselines. User did not
override.

---

## Light coverage scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full screen set, desktop-only | All 12 durable screens in light @1280 (reuse single light project) + mirror the 5-screen regression guard; mobile-light deferred (168 proved layout mode-independent) | ✓ |
| Full parity (both viewports) | 12 screens × desktop(1280)+mobile(375); requires a new `mobile-chromium-light` project; ~+9.5MB local-only | |

**User's choice:** Full screen set, desktop-only.
**Notes:** "Both modes" in the success criterion = dark+light, not both viewports. Mobile-light
deferred to keep churn minimal.

---

## Docs surface & doc-contract lock

| Option | Description | Selected |
|--------|-------------|----------|
| Separate theme doc + new test | Keep canonical `operator-surface-mount` snippet dark-default/clean (no churn to the 3 existing snippet tests); document `theme:` in a new guide subsection + README pointer; lock with a new literal-pin doc-contract test; example app keeps `:system` via the env-gated e2e branch | ✓ |
| `theme: :system` in canonical snippet | Add `theme: :system` to the marked snippet — louder demo but requires updating getting-started-saas.md + example README and contradicts dark-as-default in the headline example | |

**User's choice:** Separate theme doc + new test.
**Notes:** The canonical adopter mount stays dark-default; the `theme:` literal is locked
additively (D-05).

---

## Adopter recommendation (recommendation locked, not voted)

| Option | Description | Selected |
|--------|-------------|----------|
| Lead with `theme: :system` as documented daytime-use recommendation | `:dark` default/brand-primary, `:system` auto-follows OS (pure CSS, no FOUC) for bright/daytime, `:light` forced; framed as readability/accessibility not medical | ✓ |

**Resolution:** Locked by recommendation (D-04). Research confirmed the implementation truth
(default `:dark`, `:system` = `@media (prefers-color-scheme)` OS-auto) and surfaced the settled
precedent phrasing in 165-LIGHT-MODE-RECOMMENDATION.md. User did not override.

---

## Claude's Discretion

- Exact suffix-selection mechanism (env check vs project-name check), light regression-guard
  reuse vs parameterized variant, heading/placement of the new guide "Theme" subsection,
  precise daytime wording, and the exact form of the new doc-contract test — all bounded by
  the locked decisions in CONTEXT.md.

## Deferred Ideas

- Mobile-light screenshot lane (`mobile-chromium-light`) — 168 proved layout mode-independent.
- Rename `__default__` → `__dark__` — deferred until a multi-mode-CI demand.
- Brandbook `tokens.json`/`tokens.css` parity + "UI theming posture" note — Phase 170.
- 3 reviewed-not-folded todos (coverage-schema-card-declutter, theme-picker-idiomatic-ui,
  transaction-page-left-push-desktop) — out of evidence/docs scope; same as 168's review.
