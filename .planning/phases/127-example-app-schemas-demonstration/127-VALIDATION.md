---
phase: 127
slug: example-app-schemas-demonstration
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-28
updated: 2026-05-28
---

# Phase 127 — Validation Strategy

> Runnable `:schemas` demonstration in the example app; doc SSOT parity via router mount markers.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` (`verify.doc_contract`); `examples/threadline_phoenix/mix.exs` |
| **Quick run command** | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs` |
| **Full suite command** | `mix verify.doc_contract` |
| **Estimated runtime** | ~20–60s targeted |

---

## Sampling Rate

- **After 127-01 commit:** `mix verify.doc_contract` (mount snippet parity)
- **After 127-02 commit:** Example operator surface test + `mix verify.doc_contract`
- **Before phase complete:** All per-task rows ✅ green

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 127-01-01 | 01 | 1 | ROADMAP SC #1 | T-127-01 | Mount includes `:schemas` for help-desk tables only | integration | `rg 'schemas:' examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | ✅ | ⬜ pending |
| 127-01-02 | 01 | 1 | ROADMAP SC #2 | T-127-02 | §9 + README mount blocks match router markers | doc contract | `mix verify.doc_contract` | ✅ | ⬜ pending |
| 127-02-01 | 02 | 2 | ROADMAP SC #3 | T-127-03 | History sub-route reifies row without schema error | integration | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs` | ✅ | ⬜ pending |
| 127-02-02 | 02 | 2 | ROADMAP SC #3 | T-127-04 | D-14 mount map locked in doc contract | doc contract | `mix test test/threadline/example_phoenix_schemas_mount_contract_test.exs` | ⬜ W0 | ⬜ pending |
| 127-02-03 | 02 | 2 | Gap closure | — | Phase verification artifact records evidence | artifact | Manual checklist in `127-VERIFICATION.md` | ⬜ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing `operator_surface_test.exs` covers operator auth boundary
- [x] `help_desk_audit_test.exs` proves capture path for tickets/ticket_replies
- [x] Doc contract infrastructure (`GettingStartedFixtures.extract!/2`)

*No new Wave 0 files required — extend existing tests.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| WALKTHROUGH human row-history walk | Operator UX | Automated test uses shipped history sub-route, not shorthand URL | Optional spot-check `/audit/transactions/:id/history/ticket_replies/:pk` in dev |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual row
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] `127-VERIFICATION.md` created with passed status
- [ ] `nyquist_compliant: true` set in frontmatter after green bundle

**Approval:** pending
