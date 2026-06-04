---
phase: 139-orientation-hub-home-nav
verified: 2026-06-04T15:15:11Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 12/12
  gaps_closed:
    - "Mobile visual comfort check closed by true 375px viewport metrics, Playwright viewport assertions, and screenshot inspection."
    - "Home card copy persona-fit check closed by implementation/tests proving existing-action-only Find / Verify / Prove orientation and screenshot inspection."
  gaps_remaining: []
  regressions: []
---

# Phase 139: Orientation Hub (Home / Nav) Verification Report

**Phase Goal:** Make the Home start page and `surface_header` nav reflect the locked persona/JTBD IA -- consistent active states, grouping, and a mobile nav pattern; Home orients each persona to an obvious next action.
**Verified:** 2026-06-04T15:15:11Z
**Status:** passed
**Re-verification:** Yes -- after mobile viewport fix and human-needed evidence

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `surface_header` nav shows consistent active states and locked Find / Verify / Prove grouping. | VERIFIED | `surface_header.ex` renders grouped nav with `aria-current`; `surface_header_test.exs` asserts labels, feature flags, and exactly one active destination. |
| 2 | Header preserves Home brand link, skip link, scope chip, coverage badge, and feature-flag visibility. | VERIFIED | `surface_header.ex` preserves these assigns and DOM affordances; StartLive passes `scoped={not is_nil(assigns[:threadline_scope])}`. Scoped regression exists. |
| 3 | Exports is separated as the Prove handoff destination without new routes, APIs, schemas, migrations, JS nav state, or dependencies. | VERIFIED | `tl-topbar__nav-handoff` and `tl-home__prove-handoff` are present; `gsd-sdk query verify.schema-drift 139` reports `drift_detected: false`. |
| 4 | A mobile nav pattern works at 375px and every enabled destination remains reachable. | VERIFIED | CSS uses `.tl-topbar__nav { overflow-x: auto; }`; `/audit` now uses an operator root layout with viewport meta; Playwright asserts viewport meta plus `innerWidth` and root client width <= 375. Orchestrator evidence: true metrics all 375 and 9 Playwright tests, 0 failures. |
| 5 | Home remains a GDS-style orientation hub, not a dashboard or new workflow screen. | VERIFIED | `start_live.ex` renders headline, lede, cards, health row, and resume section; tests refute Phase 140 form/input/patch behavior. |
| 6 | Each persona has an obvious next existing action. | VERIFIED | Home cards link to Timeline, Coverage, Evidence, Redaction, Retention, and Exports only; no `/records`, `/correlations`, or `/row-history` Home links. |
| 7 | Home health is quiet when clear and severity-aware when unhealthy. | VERIFIED | `coverage_warning/1`, `exports_warning/1`, and `retention_warning/1` produce warning/danger signals; tests assert success, warning, and danger chips. |
| 8 | Home coverage health does not duplicate the topbar coverage badge count/role. | VERIFIED | Home coverage label is recovery/action copy: `Close coverage gaps before trusting Timeline answers`; tests refute duplicated numeric count in Home health. |
| 9 | Actor-owned saved views render as resume affordances and other actors' saved views do not leak. | VERIFIED | `fetch_saved_views/1` queries `SavedView` by `actor_ref`; tests insert current/other actor views and assert only current actor links render. |
| 10 | Saved-view links use canonical Timeline query encoding. | VERIFIED | `saved_view_path/2` calls `FilterParams.canonical_query/1`; LiveView tests assert canonical `/audit/timeline?...` links. |
| 11 | Browser UAT stays scoped to Phase 139 and does not broaden into Phase 142. | VERIFIED | E2E spec checks Home/nav, viewport meta, root overflow, and reachability only; no screenshot baselines or table/drawer/filter responsive assertions. |
| 12 | `POLISH-HOME` requirement is covered and Phase 140 / 142 boundaries are preserved. | VERIFIED | Plans declare `POLISH-HOME`; later roadmap phases own earned flows and broad responsive work, while Phase 139 source/specs stay scoped to Home/nav orientation. |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/operator_surface/components/surface_header.ex` | Feature-flag-aware grouped operator nav with active states and Exports handoff. | VERIFIED | Exists, substantive, wired through operator LiveViews. |
| `lib/threadline/operator_surface/live/start_live.ex` | Persona-oriented Home render, health severity, saved-view resume links. | VERIFIED | Exists, substantive, wired at `/audit`; data flows from existing assigns/repo queries. |
| `lib/threadline/operator_surface/style.ex` | Token-backed mobile nav and Home/resume/handoff primitives. | VERIFIED | CSS selectors present and guarded by style contracts. |
| `test/threadline/operator_surface/surface_header_test.exs` | Header IA, active-state, feature-flag, and preservation contracts. | VERIFIED | Included in local focused ExUnit pass. |
| `test/threadline/operator_surface/live/start_live_test.exs` | Home orientation, health, saved views, scope, and Phase 140 non-leakage tests. | VERIFIED | Included in local focused ExUnit pass. |
| `test/threadline/operator_surface/style_contract_test.exs` | CSS token/dark-only contracts. | VERIFIED | Included in local focused ExUnit pass. |
| `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` | Focused 375px Home/nav Playwright UAT. | VERIFIED | Substantive spec asserts Home orientation, nav reachability, no root overflow, viewport meta, and true mobile layout width. `gsd-sdk verify.artifacts` still reports missing literal pattern `operator-home-nav`, but manual review confirms equivalent focused suite title/assertions. |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | `/audit` authenticated operator pages include app root layout. | VERIFIED | `:operator_browser` pipeline sets `put_root_layout` to `Layouts.app`; `/audit` pipes through `:browser`, `:operator_browser`, and `:operator_auth`. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `SurfaceHeader` | operator screens | `current` atom / `aria-current` | VERIFIED | Component and tests prove one active destination, none for `:start`. |
| `StartLive` | `SurfaceHeader` | `Threadline.OperatorSurface.Components.SurfaceHeader.surface_header` | VERIFIED | Fully-qualified call present with preserved assigns and `current={:start}`. |
| `StartLive` | `FilterParams` | `FilterParams.canonical_query(view.filters || %{})` | VERIFIED | Canonical saved-view path helper present. |
| `StartLive` | `SavedView` | `from(v in SavedView, where: v.actor_ref == ^actor_ref)` | VERIFIED | Actor-owned query present and tested. |
| `/audit` route | app layout viewport meta | `:operator_browser` pipeline / `put_root_layout` | VERIFIED | Router sends `/audit` through app root layout, whose `<head>` includes `meta name="viewport"`. |
| Playwright spec | Header/Home DOM | `operator-nav-*`, grouped labels, headline/resume assertions | VERIFIED | Spec targets concrete test IDs and Home content. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `start_live.ex` | `@health` | Coverage assigns plus read-only `ExportJob` and `RetentionRun` repo queries | Yes | FLOWING |
| `start_live.ex` | `@saved_views` | `SavedView` repo query filtered by `actor_ref` | Yes | FLOWING |
| `surface_header.ex` | `@coverage`, feature flags, `@current`, `@scoped` | Operator router/on-mount assigns and StartLive/component callers | Yes | FLOWING |
| `operator-home-nav-mobile.spec.ts` | viewport dimensions | Browser DOM after `/audit` renders through app root layout | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Focused ExUnit contracts | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs` | 21 tests, 0 failures | PASS |
| Browser UAT availability | `curl --max-time 2 -fsS http://127.0.0.1:4002/users/log_in` | server unavailable in verifier process | SKIP |
| Browser UAT result | Orchestrator evidence: `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-home-nav-mobile.spec.ts` | 9 tests, 0 failures after viewport assertion | PASS |
| Schema drift | `gsd-sdk query verify.schema-drift 139` | `drift_detected: false` | PASS |
| Human visual evidence | Orchestrator screenshot `/tmp/threadline-phase-139-visual/home-true-375.png`; verifier inspected local PNG | Home cards stack, health chips wrap, saved-view chips fit, nav is a horizontal scroll strip, and no root overflow is visible | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Conventional probes | `find scripts -path '*/tests/probe-*.sh' -type f` | No phase probes found or declared | SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| `POLISH-HOME` | 139-01, 139-02, 139-03 | Home and `surface_header` nav reflect locked IA, active states, grouping, mobile nav, and GDS Home next actions. | SATISFIED | Code, ExUnit, style contracts, Playwright evidence, true mobile metrics, and screenshot inspection cover implementation and prior human-needed checks. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `lib/threadline/operator_surface/live/start_live.ex` | 84, 146, 147, 150 | Empty-list render conditions | Info | Legitimate all-clear / empty resume branches, not stubs; populated by data queries. |

### Manual Verification Closure

None. Prior human-needed items are closed by supplied orchestrator evidence and verifier screenshot inspection:

1. Mobile nav visual comfort: true 375px metrics and screenshot inspection show stacked Home cards, wrapped health chips, fitting saved-view chips, intentional nav scroll continuation, and no root overflow.
2. Home card copy persona fit: implementation and tests keep Find / Verify / Prove orientation pointed only at existing destinations and explicitly refute Phase 140 workflow controls/routes.

### Gaps Summary

No blocking implementation gaps found. No human verification items remain. Phase 139's Home/nav orientation goal is achieved and ready to proceed.

---

_Verified: 2026-06-04T15:15:11Z_
_Verifier: the agent (gsd-verifier)_
