---
phase: 176
slug: data-display-operator-patterns
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-17
---

# Phase 176 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `176-RESEARCH.md` → Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (e2e screenshot matrix) |
| **Config file** | `test/test_helper.exs`; `mix.exs` aliases |
| **Quick run command** | `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/presentation_test.exs` |
| **Full suite command** | `mix verify.test` (and `mix ci.all` for the full gate) |
| **Style/parity gates** | `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/brandbook_token_parity_test.exs` |
| **Stress/ledger gates** | `mix test test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/stress_fixtures_test.exs` |
| **Visual matrix** | `mix verify.operator_stress` (Playwright `operator-stress.spec.ts`, 5 viewports × dark/light/system) |
| **Estimated runtime** | ~60s ExUnit quick; full `mix ci.all` several minutes incl. Playwright |

---

## Sampling Rate

- **After every task commit:** quick run of the touched `*_test.exs` (e.g. `presentation_test`, `ui_test`) + `mix verify.format`.
- **After every plan wave:** `mix verify.test` + `style_contract_test` + `brandbook_token_parity_test` + stress ledger tests.
- **Before `/gsd:verify-work`:** `mix ci.all` green + `mix verify.operator_stress` (screenshot matrix).
- **Max feedback latency:** ~60 seconds (quick ExUnit subset).

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | `truncate_middle` guarantees ≥8-char tail; middle-truncates per type | unit | `mix test test/threadline/operator_surface/presentation_test.exs` | ✅ extend (`:tail_min` cases) |
| DATA-01 | `ref/1` binds `data-tl-copy={full}`, not `.title`/`.visible`, for a long value | unit/component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ add `ref` describe |
| DATA-01 | Each consuming LiveView copies the full value (no truncated copy) | integration | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ✅ extend / ❌ others W0 |
| DATA-01 | `data_table` `:col label` emits both `<th>` and `<td data-label>` | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ add |
| DATA-02 | Time renders `<time datetime>` UTC relative+absolute | unit/component | `mix test test/threadline/operator_surface/presentation_test.exs` | ✅ extend |
| DATA-02 | Status pairs color with label/shape (never color alone) | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ |
| DATA-03 | `loading_state`/`stale_banner`/3 variants render correct role/icon/heading | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ add |
| DATA-03 | Each typed `:failed` reason maps to correct state (permission≠no_data≠unavailable) | integration | `mix test test/threadline/operator_surface/live/...` | ❌ W0 (per affected page) |
| DATA-04 | Kebab renders destructive item last after divider w/ non-color cue | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ |
| DATA-04 | T3 handler fails closed on token mismatch / forged id / missing authz; audits action | integration | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` | ❌ W0 (security-critical) |
| DATA-04 | No bulk multi-select present | component/integration | grep-style assertion in page test | ❌ W0 |
| DATA-05 | No card-family class nested under another card-family class per rendered page | regression | new test (D-12) across 11 pages | ❌ W0 |
| DATA-05 | `style.ex` no longer contains `text-overflow:ellipsis` on `.tl-secondary-ref` / `tl-coverage-command__*` | contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ update assertions |
| all | Every new/extended unit registered + rendered on `/audit/__stress` across matrix | visual+ledger | `mix verify.operator_stress` + `stress_ledger_test.exs` | ✅ extend stories |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] T3 security test for `retention_history_live` — fail-closed on mismatch/forged-id/no-authz + audits action (DATA-04) — **highest priority; security-critical**.
- [ ] Card-nesting regression test across 11 pages (DATA-05, D-12).
- [ ] Per-page typed-reason → state mapping tests (DATA-03) for each converted page.
- [ ] `ref` copy-equals-full contract test reused across every consuming LiveView (DATA-01, Pitfall 4).
- [ ] Stress-story registration + `stress_ledger_test` expectation updates for new components/states.
- [ ] `style_contract_test` assertion updates paired with each CSS deletion (so deletion can't silently regress).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Screenshot legibility under ugly-data across dark/light/system at 5 viewports | DATA-01..05 | Visual judgment of readability/declutter not fully assertable | Run `mix verify.operator_stress`, eyeball `/audit/__stress` matrix output |
| T3-redact runtime backend existence (Open Question 2) | DATA-04 | Research could not confirm a redact `handle_event` exists; redaction is codegen-time only | `checkpoint:human-verify` before planning/executing any redact handler |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
</content>
</invoke>
