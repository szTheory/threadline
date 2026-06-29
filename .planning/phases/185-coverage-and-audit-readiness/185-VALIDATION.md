---
phase: 185
slug: coverage-and-audit-readiness
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-29
---

# Phase 185 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Mix with Phoenix.LiveViewTest; Playwright `@playwright/test` for example-browser proof |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` |
| **Full suite command** | `mix verify.test`; add `mix verify.example_browser` for the narrow Coverage/mobile lane when browser proof is updated; add `cd examples/threadline_phoenix && mix precommit` as nested app closeout after example e2e edits |
| **Estimated runtime** | ~15 seconds for targeted Mix slice; browser lane varies by local example-app startup |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs`
- **After every plan wave:** Run `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/coverage/on_mount_test.exs`
- **Before `/gsd:verify-work`:** Run the targeted Mix slice as primary sampling, the narrow Coverage/mobile browser lane and `cd examples/threadline_phoenix && mix precommit` as closeout proof, and `mix verify.test` when local residuals allow.
- **Max feedback latency:** 30 seconds for primary targeted Mix sampling; browser and nested app precommit closeout proof are outside the sampling latency budget.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 185-01-01 | 01 | 1 | COV-01 | T-185-01 | Schema names and readiness copy render through HEEx interpolation with no raw HTML | LiveView/source | `mix test test/threadline/operator_surface/live/coverage_live_test.exs` | yes | green |
| 185-01-02 | 01 | 1 | COV-02 | T-185-02 | Removed page-level CTAs cannot imply incomplete coverage data is reliable | LiveView/style | `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/style_contract_test.exs` | yes | green |
| 185-01-03 | 01 | 1 | COV-03 | T-185-03 | Invalid schema URLs preserve the rejected value and do not leak stale public data as selected-schema truth | LiveView/doc | `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` | yes | green |
| 185-01-04 | 01 | 1 | COV-03 | T-185-04 | Non-public Timeline links preserve schema scope with `table_schema=NAME&table=TABLE` only on covered rows | LiveView primary | `mix test test/threadline/operator_surface/live/coverage_live_test.exs` | yes | green |
| 185-01-05 | 01 | 1 | COV-03 | T-185-05 | Mobile schema control, row disclosure, and focus affordances remain reachable without horizontal overflow | Browser closeout proof | `mix verify.example_browser_light tests/operator-coverage-readiness.spec.ts` and `cd examples/threadline_phoenix && mix precommit` after primary Mix sampling | yes | green-with-residual |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `test/threadline/operator_surface/live/coverage_live_test.exs` - add or flip assertions for one verdict, native select, stale timestamp preservation, empty schema copy, and invalid-schema recovery.
- [x] `test/threadline/operator_surface/coverage_doc_contract_test.exs` - update docs/source literals for selected-schema readiness, refresh, and non-public row links.
- [x] `test/threadline/operator_surface/style_contract_test.exs` - retire `tl-trust-rail`/standalone remediation CSS if deleted; add `tl-coverage-verdict` token-backed/mobile rules if introduced.
- [x] `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` - add narrow closeout browser proof for the verdict region, schema select, mobile overflow, focus traversal, row disclosure/copy layout, and public-schema link behavior; admit it to the existing light/system lane.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Manual review may still inspect copy tone and information hierarchy, but it is not the only proof for any requirement.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 120 seconds for the targeted Mix slice.
- [x] `nyquist_compliant: true` set in frontmatter.

## Validation Audit 2026-06-29

| Metric | Count |
|--------|-------|
| Requirements audited | 3 |
| Gaps found | 0 |
| Resolved | 3 |
| Escalated | 0 |

Evidence:
- `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/coverage/on_mount_test.exs test/threadline/operator_surface/formless_pages_test.exs` passed with 117 tests.
- `mix verify.example_browser_light tests/operator-coverage-readiness.spec.ts` passed with 7 tests.
- `cd examples/threadline_phoenix && mix precommit` remains non-green due to inherited demo seed/audit-history residuals documented in `185-VERIFICATION.md`; Phase 185 browser and Mix coverage are green.

**Approval:** approved 2026-06-29
