---
phase: 28
slug: telemetry-health-operators-narrative
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-24
---

# Phase 28 — Validation Strategy

> Documentation phase: validate prose against code and keep CI green.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) |
| **Config file** | `mix.exs`, `config/test.exs` |
| **Quick run command** | `mix compile --warnings-as-errors` |
| **Full suite command** | `mix format --check-formatted && mix compile --warnings-as-errors && mix test` |
| **Estimated runtime** | Project default (full suite) |

---

## Sampling Rate

- **After every task commit:** `mix compile --warnings-as-errors`
- **After every plan wave:** Full suite row above
- **Before `/gsd-verify-work`:** Full suite green
- **Max feedback latency:** Bounded by `mix test` duration on dev machine

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 28-01-01 | 01 | 1 | OPS-01 | T-28-01 | SQL/playbook text uses placeholders; no executable secrets | doc+compile | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 28-01-02 | 01 | 1 | OPS-02 | T-28-02 | Accurate Health / Mix semantics (no false CI claims) | doc+compile | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 28-02-01 | 02 | 2 | OPS-02 | T-28-02 | Same | doc+compile | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 28-02-02 | 02 | 2 | OPS-01 | T-28-01 | Cross-links resolve | grep anchors | `grep -q 'domain-reference.md#' guides/production-checklist.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- Existing ExUnit + Mix infrastructure covers this phase; no Wave 0 install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Markdown anchor resolution | OPS-01 | Renderer-dependent | Open both guides in preview; click new checklist ↔ domain links. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual step
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
