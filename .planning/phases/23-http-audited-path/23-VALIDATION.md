---
phase: 23
slug: http-audited-path
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-24
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phoenix ConnCase) |
| **Config file** | `examples/threadline_phoenix/config/test.exs` |
| **Quick run command** | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/` |
| **Full suite command** | `MIX_ENV=test mix verify.example` (from repo root) |
| **Estimated runtime** | ~30–90 seconds (deps + compile + DB on cold run) |

---

## Sampling Rate

- **After every task commit:** `cd examples/threadline_phoenix && MIX_ENV=test mix test` (or file-scoped path if only one module touched)
- **After every plan wave:** `MIX_ENV=test mix verify.example` from repo root
- **Before `/gsd-verify-work`:** `MIX_ENV=test mix ci.all` green locally when feasible
- **Max feedback latency:** 120 seconds (cold nested compile)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 23-01-01 | 01 | 1 | REF-03 | T-23-02 | GUC only inside txn | unit | `mix test test/threadline_phoenix/` (Blog) | ⬜ W0 | ⬜ pending |
| 23-01-02 | 01 | 1 | REF-03 | T-23-01 / — | Plug does not set DB session vars | integration | `mix test test/threadline_phoenix_web/` | ⬜ W0 | ⬜ pending |
| 23-01-03 | 01 | 1 | REF-03 | — | Synthetic actor only | integration | `mix test test/threadline_phoenix_web/posts_audit_path_test.exs` | ⬜ W0 | ⬜ pending |
| 23-01-04 | 01 | 1 | REF-03 | — | README only | doc | `grep` per plan acceptance | ⬜ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers Phase 23 — **no Wave 0 stubs** (example app and `verify.example` from Phase 22).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Optional curl/httpie | REF-03 optional path | README-only if not wired to CI | If README adds curl, human copy-paste once; **test module remains canonical** per D-03. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or dependency on 23-01-04
- [ ] Sampling continuity: HTTP test runs after router/context/controller tasks
- [ ] No watch-mode flags in verify commands
- [ ] `nyquist_compliant: true` set in frontmatter when execution completes

**Approval:** pending
