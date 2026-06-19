---
phase: 179
slug: microcopy-information-architecture-sweep
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-19
---

# Phase 179 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `179-RESEARCH.md` § Validation Architecture. This phase is a
> guard-first editorial refactor: rendered copy contracts prove brand/domain
> language, and targeted browser specs prove shell/Home IA remains usable.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest for rendered copy contracts; Playwright for browser nav/accessibility checks |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Quick ExUnit ~30-90s; full suite including browser ~2-5 min |

---

## Sampling Rate

- **After every task commit:** Run the touched cluster's ExUnit subset plus `test/threadline/operator_surface/copy_contract_test.exs` once Wave 0 creates it.
- **After every plan wave:** Run `mix test test/threadline/operator_surface/` and any touched targeted Playwright specs.
- **Before `/gsd:verify-work`:** `mix ci.all` must be green.
- **Max feedback latency:** ~90 seconds for the quick ExUnit sample.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {populated by planner} | — | 0 | COPY-01 | V4/V5 | Banned vocabulary, generic state copy, exclamation marks, and title-case state leaks fail before copy edits and stay green after fixes | rendered unit/source contract | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/ui_test.exs` | ❌ W0 | ⬜ pending |
| {populated by planner} | — | 0 | COPY-02 | — | Primary UI uses plain operator nouns and keeps exact Threadline model names only in allowed advanced/error/tooling contexts | rendered unit contract | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/live` | ❌ W0 | ⬜ pending |
| {populated by planner} | — | 1 | COPY-03 | route-stability | Shell/Home IA labels change without route, `href`, `data-testid`, `current` atom, or bookmarked path churn | ExUnit + Playwright | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/start_live_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-home-nav-mobile.spec.ts` | ✅ existing tests / ❌ W0 guard | ⬜ pending |
| {populated by planner} | — | 1 | COPY-01/COPY-02 | V4/V5 | Permission, unavailable, redacted, pruned, stale, destructive, and validation copy names the object/consequence and uses severity-appropriate roles | rendered unit contract | `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs` | ✅ existing tests / ❌ assertion updates | ⬜ pending |
| {populated by planner} | — | 2 | COPY-02/COPY-03 | — | Evidence/Exports/Redaction/Retention copy avoids broad proof language except proof-history contexts and preserves direct evidence/export handoff links | ExUnit + Playwright | `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-prove-mobile.spec.ts tests/operator-earned-flows.spec.ts` | ✅ existing tests / ❌ assertion updates | ⬜ pending |
| {populated by planner} | — | 2 | COPY-03 | route-stability | Timeline remains dense and URL-recoverable: filters/results/actions stay first, advanced filter disclosure opens from active params, copyable refs keep full values | ExUnit + Playwright | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/pager_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts tests/operator-stress.spec.ts` | ✅ existing tests / ❌ assertion updates | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/copy_contract_test.exs` — guard-first rendered/source contract for COPY-01, COPY-02, and COPY-03.
- [ ] Copy-contract guards cover: retired `Find / Verify / Prove` primary IA labels, broad proof language outside allowed proof-history contexts, visible CamelCase model names in primary UI, exclamation marks, explicit title-case state leaks, and generic state text.
- [ ] Copy-contract guards include allowlists for operation badges (`INSERT`, `UPDATE`, `DELETE`), evidence verdicts (`Proven`, `Inferred`, `Unsupported`), exact model/code tokens in advanced/error/tooling contexts, and non-UI technical terms such as CSP-proof/phone-proof.
- [ ] Existing assertions in `surface_header_test.exs`, `start_live_test.exs`, `ui_test.exs`, affected `live/*_test.exs`, and targeted Playwright specs are ready to update with the same task that changes visible copy.
- [ ] Verify whether `UI.error_summary/1` already provides focus behavior for multi-field validation summaries; if absent, add a minimal rendered/browser assertion in the relevant task.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Editorial judgment on whether a lede or trust rail changes operator judgment | COPY-01/COPY-03 | Some wording quality is contextual and not fully machine-checkable | Optional reviewer spot-check only; automated contracts remain the blocking gate |

All route stability, copy bans, role mapping, full-value copy affordances, and browser nav checks should be automated.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
