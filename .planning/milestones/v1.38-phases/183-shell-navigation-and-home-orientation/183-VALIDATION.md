---
phase: 183
slug: shell-navigation-and-home-orientation
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-28
---

# Phase 183 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Phoenix.LiveViewTest for source and LiveView contracts; Playwright Test 1.60.0 for browser verification |
| **Config file** | `mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts`, `examples/threadline_phoenix/e2e/run-e2e.sh` |
| **Quick run command** | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/skip_link_test.exs test/threadline/operator_surface/surface_header_csp_test.exs` |
| **Full suite command** | `mix ci.all` plus `mix verify.example_browser_light` for Phase 183 light/system theme proof if the full suite does not include that lane; because Phase 183 touches `examples/threadline_phoenix`, final closeout also runs `cd examples/threadline_phoenix && MIX_ENV=test mix precommit` |
| **Estimated runtime** | Targeted source slice: under 90 seconds; browser lanes depend on example-app and Playwright setup |

---

## Sampling Rate

- **After every task commit:** Run the quick source command for touched shell/Home files; run the targeted Playwright spec when layout, navigation, focus, theme, or Home interaction behavior changes.
- **After every plan wave:** Run `mix verify.threadline` plus the relevant targeted browser lane for the wave.
- **Before `/gsd:verify-work`:** Run `mix ci.all`, `mix verify.example_browser`, `mix verify.example_browser_light`, and `cd examples/threadline_phoenix && MIX_ENV=test mix precommit`, or document any environment failure with the exact failing command and artifact.
- **Max feedback latency:** Keep task-level source feedback under 90 seconds where possible; isolate slower browser evidence to wave and phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 183-W0-01 | TBD | 0 | SHELL-01 | T-183-01 | One global nav remains server-rendered, visible at 768px+, and clearly labeled/openable below 768px without custom drawer JS. | source + browser | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/style_contract_test.exs` and `mix verify.example_browser` with Phase 183 breakpoint assertions | source yes; browser supplement W0 | pending |
| 183-W0-02 | TBD | 0 | SHELL-02 | T-183-02 | Home remains a task-led launcher with Timeline primary, Coverage readiness secondary, proof/governance links specific, and EF1/EF4 validation local. | LiveView + browser | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/copy_contract_test.exs` and `mix verify.example_browser` with Home first-viewport hierarchy assertions | source yes; browser supplement W0 | pending |
| 183-W0-03 | TBD | 0 | SHELL-03 | T-183-03 | Active state, feature gates, skip link, topbar status, and theme form remain accessible and server-owned across dark/light/system and 320-1440px. | source + browser + accessibility | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/skip_link_test.exs test/threadline/operator_surface/surface_header_csp_test.exs test/threadline/operator_surface/style_contract_test.exs`; `mix verify.example_browser`; `mix verify.example_browser_light` | source yes; browser supplement W0 | pending |
| 183-GATE | TBD | final | SHELL-01, SHELL-02, SHELL-03 | T-183-01..03 | Phase closes only when shell/Home source contracts, browser perception lanes, and the example app precommit alias prove navigation, hierarchy, theme, focus, feature-gate, overflow, format, deps.unlock, compile, and app test behavior. | full suite + evidence | `mix ci.all`, `mix verify.example_browser`, `mix verify.example_browser_light`, and `cd examples/threadline_phoenix && MIX_ENV=test mix precommit` | commands exist | pending |

---

## Wave 0 Requirements

- [ ] Decide whether to extend existing Playwright specs or add `examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts`; current files do not contain every Phase 183 perception cell.
- [ ] Add strict browser assertions for 320, 375, 768, 1024, 1280, and 1440px without creating a broad screenshot matrix.
- [ ] Add dark default plus light/system selected-theme, current-state, Home hierarchy, Home error, focus visibility, and no-horizontal-overflow assertions through the existing browser lanes.
- [ ] Preserve the existing source test framework; no new ExUnit or Playwright dependency is required.

Existing infrastructure covers the source-contract and E2E harnesses. Wave 0 creates or tightens the missing Phase 183 browser perception proof.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Home task hierarchy review | SHELL-02 | Browser assertions can prove visibility, order, route behavior, and overflow, but final primary/secondary hierarchy still benefits from maintainer judgment against the UI-SPEC and brandbook. | Review `/audit` at 320, 375, 768, 1024, 1280, and 1440px in dark and system/light. Confirm Timeline is the primary investigation path, Coverage is secondary, proof/governance links are specific, and there are no redundant generic CTAs. |
| Adjacent route shell-boundary triage | SHELL-01, SHELL-03 | Tests can expose shell invariant failures on adjacent pages, but deciding whether a finding is a Phase 183 shell blocker or a Phase 184-186 page-content issue requires scope judgment. | If representative adjacent route checks fail, classify each finding as shell invariant, wrapper-level issue, or deferred page-content polish before applying fixes. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or explicit manual-only rationale.
- [ ] Sampling continuity: no three consecutive implementation tasks can land without targeted source or rendered evidence.
- [ ] Wave 0 covers the missing browser perception cells before shell/Home polish proceeds.
- [ ] No watch-mode flags are used in verification commands.
- [ ] Task feedback latency stays under 90 seconds where possible for source contracts; browser evidence is isolated to wave/phase gates.
- [ ] `mix ci.all`, `mix verify.example_browser`, `mix verify.example_browser_light`, and `cd examples/threadline_phoenix && MIX_ENV=test mix precommit` are green or residual failures are classified in `183-VERIFICATION.md` with evidence they are inherited and unrelated.
- [ ] `nyquist_compliant: true` remains set in frontmatter.

**Approval:** pending
