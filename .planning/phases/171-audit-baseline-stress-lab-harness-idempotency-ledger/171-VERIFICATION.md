---
phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
verified: 2026-06-14T22:53:48Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
---

# Phase 171: Audit Baseline, Stress-Lab Harness & Idempotency Ledger Verification Report

**Phase Goal:** Stand up the idempotency harness that every later phase ratchets against -- the canonical render surface, the living inventory, the scored ledger, and the ugly-data fixtures.  
**Verified:** 2026-06-14T22:53:48Z  
**Status:** passed  
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Dev/test-only `/audit/__stress` route renders fixture-backed component, group, state, and page inventory across the declared state/theme/viewport matrix and is prod-gated. | VERIFIED | `StressRouter.threadline_operator_surface_stress/2` raises for `:prod`, supports `:omit` for example prod compilation, and mounts `StressLive` in `live_session :threadline_stress` with `Auth` and `Coverage.OnMount` hooks. Example router mounts `/audit/__stress` twice under authenticated `/audit` theme branches. `stress_router_test.exs` covers route presence, unauthenticated redirect, prod macro failure, safe params, story listing, and direct story rendering. |
| 2 | `DESIGN-SYSTEM.md` v2 inventories foundations, primitives, form controls, groups/meta-components, pages, known footguns, and future reserved cases with current status. | VERIFIED | `DESIGN-SYSTEM.md` has required deterministic sections and rows projected from `.planning/design-system-ledger.json`. `stress_ledger_test.exs` verifies every ledger row appears in the markdown projection. |
| 3 | JSON ledger is canonical, sorted, schema-checked, and records per-item quality scores with a ratchet rule. | VERIFIED | `.planning/design-system-ledger.json` has 50 sorted entries, `ratchet.locked_ids` and `ratchet.minimum_scores` cover all 50, and `stress_ledger_test.exs` enforces schema, sorted IDs, `current_score >= ratchet_score` unless explicit reset, locked IDs, minimum scores, and fresh markdown projection. |
| 4 | Screenshot regression guard is ledger-owned and bounded to the first deterministic CI allowlist. | VERIFIED | Ledger `screenshot_allowlist.ci` contains exactly three dark/1024 entries; `operator-stress.spec.ts` reads the ledger, asserts baseline files exist, runs screenshots only on `desktop-chromium`, uses `maxDiffPixelRatio: 0.01`, and masks volatile selectors. All three PNG baselines exist. |
| 5 | Reusable ugly-data fixture library covers DS-04 matrix and uses stable synthetic IDs without DB/example-seed dependency. | VERIFIED | `StressFixtures.required_cases/0` covers empty, one, many, long IDs/strings, non-ASCII, high/zero counts, null fields, severity, permission-denied, stale, reconnecting, timezone, and pagination boundaries. Source avoids `Repo.`, `Ecto.Query`, `ThreadlinePhoenix`, `String.to_atom`, Storybook, and Tailwind. |
| 6 | Fixture stories and ledger entries round-trip; no ledger-only hidden inventory exists. | VERIFIED | Local spot check reported `stories=50 entries=50 ci_allowlist=3 missing_round_trips=0`. `stress_ledger_test.exs` and `stress_router_test.exs` verify every fixture story has a ledger row, every ledger story resolves through `StressFixtures.by_id/1`, and every listed story renders a preview or reserved placeholder. |
| 7 | Browser semantic checks prove auth, shell/theme reuse, safe params, reserved cases, and no horizontal overflow across UI-SPEC viewports. | VERIFIED | `operator-stress.spec.ts` covers unauthenticated redirect, authenticated shell, `.threadline-ui[data-tl-theme]`, `#tl-main`, stress metadata, category current state, bad params, reserved Phase 175/176/178 copy, and 320/375/768/1024/1440 overflow. Recent orchestrator evidence shows `mix verify.operator_stress` and light/system stress lane passed. |
| 8 | No external visual service, Storybook dependency, public `stress: true` API, or new package registry enters the harness. | VERIFIED | Source scans found no `stress: true` in public router surfaces and no `PhoenixStorybook`, `Tailwind`, `Chromatic`, `Percy`, `Applitools`, Storybook package references, or package-registry references in phase-owned harness artifacts. |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/operator_surface/stress_fixtures.ex` | Pure `Threadline.OperatorSurface.StressFixtures` registry | VERIFIED | Exports `all/0`, `by_id/1`, `categories/0`, `required_cases/0`, `theme_modes/0`, `viewports/0`, `assigns_for/1`; synthetic static data only. |
| `test/threadline/operator_surface/stress_fixtures_test.exs` | DS-04 matrix and adapter drift contract | VERIFIED | Verifies matrix, stable IDs, reserved future-owned cases, synthetic-only source, component adapter smoke checks, and inventory story coverage. |
| `.planning/design-system-ledger.json` | Canonical machine-readable audit ledger | VERIFIED | 50 sorted entries, required schema, ratchet metadata, locked/minimum scores, fixture story IDs, and screenshot allowlist. |
| `DESIGN-SYSTEM.md` | Human-readable deterministic inventory projection | VERIFIED | Contains required v2 inventory sections and fresh rows for every ledger entry. |
| `test/threadline/operator_surface/stress_ledger_test.exs` | Ledger schema, ratchet, allowlist, and projection tests | VERIFIED | Enforces schema/order/ratchet/freshness/fixture round-trip/external-service exclusions. |
| `lib/threadline/operator_surface/stress_router.ex` | Internal dev/test stress route macro | VERIFIED | Separate macro, prod failure path, example `:omit` path, auth/coverage `on_mount`, `:threadline_stress` session. |
| `lib/threadline/operator_surface/live/stress_live.ex` | Authenticated stress lab LiveView | VERIFIED | Reads ledger, resolves fixtures, renders shell/header/theme, story list, metrics, score, target, screenshot status, preview, and safe filters. |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | Example `/audit/__stress` mount | VERIFIED | Mounted inside authenticated `/audit` scope in both theme branches; no public `stress: true` option. |
| `test/threadline/operator_surface/stress_router_test.exs` | Route, auth, prod gate, and param normalization tests | VERIFIED | Covers route compile, prod gate, real prod macro script, auth redirect, theme query, filter-scoped story selection, safe bad params, and ledger story rendering. |
| `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` | Stress route semantic and screenshot Playwright guard | VERIFIED | Covers browser semantics, viewports, reserved cases, ledger screenshot allowlist, and bounded screenshot assertions. |
| `examples/threadline_phoenix/e2e/playwright.config.ts` | Light/system project includes stress spec | VERIFIED | `desktop-chromium-light` includes `operator-(accessibility|screenshots|screenshot-regression|stress).spec.ts`. |
| `mix.exs` | Focused `verify.operator_stress` browser alias | VERIFIED | Alias dispatches to `verify_example_browser(["operator-stress.spec.ts" | args])`. |
| `operator-stress.spec.ts-snapshots/*.png` | Three first CI screenshot baselines | VERIFIED | All three ledger-owned baseline PNG files exist. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `StressFixtures.all/0` | DS-04 required ugly-data matrix | `required_cases` and coverage tests | WIRED | `stress_fixtures_test.exs` asserts exact cases and union coverage. |
| `StressFixtures.all/0` | `.planning/design-system-ledger.json` | story/ledger/fixture round-trip | WIRED | `stress_ledger_test.exs` checks each story `ledger_id`, `story_id`, and `fixture_key`; spot check found 0 missing round-trips. |
| `stress_fixtures_test.exs` | existing components | `render_component` adapter smoke | WIRED | Tests render `SurfaceHeader.surface_header/1` and `UnsupportedView.unsupported_view/1`. |
| Example router | `StressRouter.threadline_operator_surface_stress/2` | authenticated `/audit` scope | WIRED | Two `/__stress` mounts inside `/audit` authenticated scope; route tests confirm `/audit` and `/audit/__stress`. |
| `StressLive` | `StressFixtures` | story lookup and assigns adapter | WIRED | `StressLive` uses `StressFixtures.categories/0`, `theme_modes/0`, `viewports/0`, `by_id/1`, and `assigns_for/1`. |
| `StressLive` | `.planning/design-system-ledger.json` | ledger score and screenshot status lookup | WIRED | `StressLive` reads the ledger file, lists ledger-backed stories, and renders current/target score plus screenshot status. |
| `operator-stress.spec.ts` | `/audit/__stress` | authenticated browser navigation | WIRED | Browser spec navigates unauthenticated and authenticated paths and checks shell/theme/story/preview behavior. |
| `operator-stress.spec.ts` | `.planning/design-system-ledger.json` | filesystem-read screenshot allowlist | WIRED | Browser spec reads the JSON ledger and asserts exact CI allowlist and baseline existence. |
| `.planning/design-system-ledger.json` | snapshot files | `baseline_ref` entries | WIRED | Three CI allowlist `baseline_ref` values match existing PNG files. |

Note: `gsd-sdk query verify.key-links` returned false negatives for module-name and basename sources such as `Threadline.OperatorSurface.StressFixtures.all/0` and `operator-stress.spec.ts`; these links were manually traced in source and tests above.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `StressLive` | `ledger_entries` | `.planning/design-system-ledger.json` via `File.read!` + `Jason.decode!` | Yes -- 50 ledger entries | FLOWING |
| `StressLive` | `stories` | Ledger `story_id`s resolved through `StressFixtures.by_id/1` | Yes -- 50 fixture stories | FLOWING |
| `StressLive` | `selected_entry` / score fields | matching ledger row for selected story | Yes -- renders `current_score`, `target_score`, and screenshot status | FLOWING |
| `operator-stress.spec.ts` | `expectedCiScreenshots` / `ledger().screenshot_allowlist.ci` | `.planning/design-system-ledger.json` plus snapshot files | Yes -- exact three CI entries and files exist | FLOWING |
| `DESIGN-SYSTEM.md` | inventory rows | `.planning/design-system-ledger.json` | Yes -- freshness test checks every ledger row | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase ExUnit contracts pass | `mix test test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_router_test.exs` | 33 tests, 0 failures | PASS |
| Fixture/ledger round-trip is complete | `mix run --no-start -e ...` | `stories=50 entries=50 ci_allowlist=3 missing_round_trips=0` | PASS |
| Ledger IDs sorted and ratchet metadata populated | `node -e ...` | `ids_sorted=true`, `locked_ids=50`, `minimum_scores=50`, three CI refs | PASS |
| Schema drift check | `gsd-sdk query verify.schema-drift 171 --raw` | `drift_detected: false`, `blocking: false` | PASS |
| Browser stress lane | Recent orchestrator evidence: `mix verify.operator_stress` | 39 passed, 6 intentional non-desktop screenshot skips | PASS |
| Light/system stress lane | Recent orchestrator evidence: `THREADLINE_E2E_THEME=system mix verify.example_browser_light -- operator-stress.spec.ts` | 12 passed, 3 intentional screenshot skips | PASS |

### Probe Execution

No phase probes were declared and no conventional `scripts/*/tests/probe-*.sh` files were found. Step 7c: SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| DS-01 | 171-03, 171-04 | Dev/test-only `/audit/__stress` renders component/group/page fixtures across state/theme/viewport matrix; prod-gated and authenticated. | SATISFIED | Stress router macro, example mount, LiveView rendering, route/auth/prod tests, and Playwright semantic viewport/theme/auth checks. |
| DS-02 | 171-02, 171-03 | `DESIGN-SYSTEM.md` v2 inventories foundations, primitives, form controls, groups/meta-components, and pages with status. | SATISFIED | Markdown projection contains required sections and row freshness is checked against the JSON ledger. |
| DS-03 | 171-02, 171-04 | Idempotent audit ledger with per-item score, ratchet rule, and test/screenshot guards. | SATISFIED | JSON ledger contains score/target/ratchet metadata; ExUnit blocks score regressions/deletions; Playwright reads ledger-owned screenshot allowlist with three baselines. |
| DS-04 | 171-01, 171-02, 171-04 | Reusable ugly-data fixture library covers full stress matrix. | SATISFIED | `StressFixtures` required cases cover the DS-04 matrix; tests verify case union coverage, stable IDs, synthetic-only source, adapters, and ledger round-trip. |

No orphaned Phase 171 requirement IDs were found in `.planning/REQUIREMENTS.md`; DS-01 through DS-04 are all declared in Phase 171 plan frontmatter and accounted for.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| none | - | - | - | No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in phase-owned artifacts. No placeholder/coming-soon stubs were found outside intentional `status: "reserved"` baseline stories required by the plan. |

### Human Verification Required

None. The phase goal is a harness/contract baseline, and the required user-visible route behavior is covered by ExUnit and Playwright semantic/screenshot checks. No `<human-check>` blocks were present in the plans.

### Gaps Summary

No blocking gaps found. The caveat from the broad `mix ci.all` run is noted as residual broad-suite risk, not a Phase 171 gap: after doc-contract fixes were verified by the focused 49-test suite, the remaining timeout occurred in the older `operator-earned-flows.spec.ts` EF1 browser UAT, outside the Phase 171 stress-lab scope. Phase-specific browser lanes and example precommit evidence are green.

---

_Verified: 2026-06-14T22:53:48Z_  
_Verifier: the agent (gsd-verifier)_
