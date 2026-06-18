---
phase: 177
slug: component-groups-meta-components
status: draft
nyquist_compliant: false
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
| _populated by planner_ | | | GROUP-01 / GROUP-02 | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> The planner fills this map per task. Each meta-component task should carry a component-render/attr test plus a stress-story presence assertion; group state-coordination and motion are verified on the `/audit/__stress` route (see Manual-Only Verifications).

---

## Wave 0 Requirements

- [ ] Confirm `test/threadline/operator_surface` test path exists or stub a `ui_test.exs` / `stress_fixtures_test.exs`
- [ ] Resolve the two locked-decision-vs-reality conflicts from RESEARCH.md before building (LiveView root vs body `.phx-*` classes; `page_header` breadcrumbs attr-vs-slot)

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
