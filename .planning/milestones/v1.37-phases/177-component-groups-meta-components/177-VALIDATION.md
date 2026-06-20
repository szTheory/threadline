---
phase: 177
slug: component-groups-meta-components
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-18
---

# Phase 177 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/operator_surface` |
| **Full suite command** | `mix ci.all` (verify.format + verify.credo + verify.test) |
| **Estimated runtime** | ~60–120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface`
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-T1 | 01 | 1 | GROUP-01/02 | T-177-01 | bind offline-anchor + breadcrumbs decisions | investigation | `grep -c 'class="threadline-ui"' …coverage_live.ex …timeline_live.ex` | ✅ (live views) | ⬜ pending |
| 01-T2 | 01 | 1 | GROUP-01/02 | T-177-01 | RED gap-parity + offline-anchor + overlay-utility source asserts | source (RED) | `mix test …/brandbook_token_parity_test.exs …/style_contract_test.exs` | ✅ extend | ⬜ pending |
| 01-T3 | 01 | 1 | GROUP-01/02 | — | RED render asserts for 5 components + breadcrumbs | unit (RED) | `mix test …/ui_test.exs` | ✅ extend | ⬜ pending |
| 02-T1 | 02 | 2 | GROUP-01 | T-177-03 | gap tokens parity across 3 sources | unit | `mix test …/brandbook_token_parity_test.exs` | ✅ | ⬜ pending |
| 02-T2 | 02 | 2 | GROUP-01 | T-177-02 | stack/cluster render + gap-class, no raw margins | unit | `mix test …/ui_test.exs` | ✅ | ⬜ pending |
| 03-T1 | 03 | 3 | GROUP-02 | T-177-04 | data_panel state coordination + delegated focus | unit | `mix test …/ui_test.exs` | ✅ | ⬜ pending |
| 03-T2 | 03 | 3 | GROUP-02 | T-177-05/06 | toolbar disabled-coord + detail_header h2 | unit | `mix test …/ui_test.exs` | ✅ | ⬜ pending |
| 03-T3 | 03 | 3 | GROUP-01 | — | breadcrumbs attr kept + narrow truncation | unit | `mix test …/ui_test.exs …/page_header_test.exs` | ✅ | ⬜ pending |
| 04-T1 | 04 | 4 | GROUP-02 | T-177-07/09 | overlay JS-transition utilities defined + time-synced | source | `mix test …/style_contract_test.exs` | ✅ | ⬜ pending |
| 04-T2 | 04 | 4 | GROUP-01/02 | T-177-08 | offline group on `.threadline-ui.phx-*` (not body/disconnected) | source | `mix test …/style_contract_test.exs` | ✅ | ⬜ pending |
| 05-T1 | 05 | 5 | GROUP-01 | T-177-10 | 12 group stories + live/reference tag | unit | `mix test …/stress_fixtures_test.exs` | ✅ | ⬜ pending |
| 05-T2 | 05 | 5 | GROUP-01 | T-177-10/11 | ledger↔fixtures↔projection parity | unit | `mix test …/stress_ledger_test.exs` | ✅ | ⬜ pending |
| 05-T3 | 05 | 5 | GROUP-01/02 | — | all 12 stories render across matrix + full gate | integration | `mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> The planner fills this map per task. Each meta-component task should carry a component-render/attr test plus a stress-story presence assertion; group state-coordination and motion are verified on the `/audit/__stress` route (see Manual-Only Verifications).

---

## Wave 0 Requirements

- [x] Confirm `test/threadline/operator_surface` test path exists — confirmed (ui_test.exs, stress_fixtures_test.exs, stress_ledger_test.exs, style_contract_test.exs, page_header_test.exs all present)
- [ ] (Plan 01) Resolve the two locked-decision-vs-reality conflicts from RESEARCH.md before building: LiveView root anchor is `.threadline-ui` (NOT body, NEVER `.phx-disconnected`) — all 11 audit live views verified to use it; keep `page_header` breadcrumbs list attr (D-14), do NOT add a slot
- [ ] (Plan 01) Lay down RED scaffolds: gap-token parity, offline-anchor source assert, overlay-utility-class source assert, 5 component render asserts (turned GREEN by Plans 02-04)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Group spacing/hierarchy reads as one coherent unit | GROUP-01 | Visual coherence not assertable in unit tests | View each of the 12 group stories on `/audit/__stress` at 320/375/768/1024/1440 |
| States aligned across children (data_panel coordination) | GROUP-02 | Cross-child visual state requires inspection | Toggle each state (empty/loading/error/stale/no-data/permission/unavailable) on the group stress stories; confirm toolbar disables while loading/error, stale banner sits above live data, permission/unavailable collapses body |
| Motion clarifies transitions; reduced-motion collapses | GROUP-02 | Animation timing/feel requires observation | Observe overlay enter/exit + data-region cross-fade; re-check with `prefers-reduced-motion: reduce` |
| Offline/reconnect banner + action disable | GROUP-01 | Requires socket drop simulation | Drop the LiveView socket mid-session; confirm `phx-loading` reconnect banner (`role=status`) appears and mutating actions disable |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-18 (plan-checker PASS; `wave_0_complete` flips at Wave 0 execution)
