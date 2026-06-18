---
phase: 176
slug: data-display-operator-patterns
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-17
validated: 2026-06-18
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
| DATA-01 | Each consuming LiveView copies the full value (no truncated copy) | integration | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ✅ |
| DATA-01 | `data_table` `:col label` emits both `<th>` and `<td data-label>` | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ add |
| DATA-02 | Time renders `<time datetime>` UTC relative+absolute | unit/component | `mix test test/threadline/operator_surface/presentation_test.exs` | ✅ extend |
| DATA-02 | Status pairs color with label/shape (never color alone) | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ |
| DATA-03 | `loading_state`/`stale_banner`/3 variants render correct role/icon/heading | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ add |
| DATA-03 | Each typed `:failed` reason maps to correct state (permission≠no_data≠unavailable) | integration | `mix test test/threadline/operator_surface/data_state_mapping_wave0_test.exs` | ✅ |
| DATA-04 | Kebab renders destructive item last after divider w/ non-color cue | component | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ |
| DATA-04 | T3 handler fails closed on token mismatch / forged id / missing authz; audits action | integration | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` | ✅ |
| DATA-04 | No bulk multi-select present | component/integration | `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs` | ✅ |
| DATA-05 | No card-family class nested under another card-family class per rendered page | regression | `mix test test/threadline/operator_surface/card_nesting_regression_test.exs` | ✅ |
| DATA-05 | `style.ex` no longer contains `text-overflow:ellipsis` on `.tl-secondary-ref` / `tl-coverage-command__*` | contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ update assertions |
| all | Every new/extended unit registered + rendered on `/audit/__stress` across matrix | visual+ledger | `mix verify.operator_stress` + `stress_ledger_test.exs` | ✅ extend stories |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] T3 security test for `retention_history_live` — fail-closed on mismatch/forged-id/no-authz + audits action (DATA-04) — **highest priority; security-critical**. → `retention_history_live_test.exs` GREEN
- [x] Card-nesting regression test across 11 pages (DATA-05, D-12). → `card_nesting_regression_test.exs` GREEN
- [x] Per-page typed-reason → state mapping tests (DATA-03) for each converted page. → `data_state_mapping_wave0_test.exs` GREEN
- [x] `ref` copy-equals-full contract test reused across every consuming LiveView (DATA-01, Pitfall 4). → `transaction_live_test.exs` GREEN
- [x] Stress-story registration + `stress_ledger_test` expectation updates for new components/states. → `stress_ledger_test.exs` / `stress_router_test.exs` GREEN
- [x] `style_contract_test` assertion updates paired with each CSS deletion (so deletion can't silently regress). → `style_contract_test.exs` GREEN

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Screenshot legibility under ugly-data across dark/light/system at 5 viewports | DATA-01..05 | Visual judgment of readability/declutter not fully assertable | Run `mix verify.operator_stress`, eyeball `/audit/__stress` matrix output |
| T3-redact runtime backend existence (Open Question 2) | DATA-04 | Research could not confirm a redact `handle_event` exists; redaction is codegen-time only | `checkpoint:human-verify` before planning/executing any redact handler |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-18 — all automated-testable requirements GREEN; remaining items are genuinely manual (visual legibility) or an explicit recorded deferral (redact T3).

---

## Validation Audit 2026-06-18

| Metric | Count |
|--------|-------|
| Gaps found | 5 |
| Resolved | 5 |
| Escalated | 0 |

All five Wave-0 gaps flagged at draft time (2026-06-17, pre-execution) were closed during phase execution. Re-ran the full Per-Task Map suite at audit time:

- Wave-0 gap closers (`card_nesting_regression`, `data_state_mapping_wave0`, `retention_history_live`, `policy_redaction_live`, `transaction_live`, `style_contract`): **72 tests, 0 failures**.
- Unit/component + stress + parity (`presentation`, `ui`, `stress_ledger`, `stress_router`, `stress_fixtures`, `brandbook_token_parity`): **123 tests, 0 failures**.
- Total at audit: **195 tests, 0 failures**.

No auditor spawn required — zero remaining gaps. The two Manual-Only entries remain manual by nature (screenshot legibility = visual judgment; redact T3 = explicitly deferred by recorded human checkpoint, see `176-VERIFICATION.md` deferred items).
