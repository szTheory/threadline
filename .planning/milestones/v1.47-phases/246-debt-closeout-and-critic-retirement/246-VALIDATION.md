---
phase: "246"
slug: "debt-closeout-and-critic-retirement"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-25"
---

# Phase 246 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 246-RESEARCH.md § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3) + Playwright (`@playwright/test`) + `tsx --test` |
| **Config file** | `test/test_helper.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test <targeted contract files>` (per-commit table in 246-RESEARCH.md) |
| **Full suite command** | `CI=true mix ci.all` on an ephemeral postgres:16 |
| **Estimated runtime** | quick ~30–90 s; full ~10–15 min |

---

## Sampling Rate

- **After every task commit:** targeted `mix test <files>` + `mix compile --warnings-as-errors` + `mix verify.format`
- **After every plan wave:** `mix verify.test` on the ephemeral DB
- **Before `/gsd-verify-work`:** `CI=true mix ci.all`, standalone `mix verify.example_browser` (same 8 screenshot failures), the close check, the refined D-09 grep, `bin/verify-repo-hygiene`
- **Max feedback latency:** 120 seconds for the per-commit loop

---

## Per-Task Verification Map

Filled by the planner/executor per task. Requirement → command map:

| Req / SC | Behavior | Test Type | Automated Command | File Exists | Status |
|----------|----------|-----------|-------------------|-------------|--------|
| DEBT-02 / SC3 | no live critic references | grep | refined D-09 grep ⊆ allowlist (`tools/verify-phase.sh --close`) | ❌ W0 | ⬜ pending |
| DEBT-02 / SC3 | restoration tag carries the code | one-off (landing) | `git ls-tree -r --name-only archive/ui-critic-loop \| grep -c lib/threadline/critic_trust/` > 0; `git merge-base --is-ancestor archive/ui-critic-loop origin/main`; `git ls-remote --tags origin archive/ui-critic-loop` | landing-time (D-14) | ⬜ pending |
| DEBT-02 / SC3 | CONTRIBUTING Retired pointer names the tag | doc contract | `mix test test/threadline/<retired_pointer>_doc_contract_test.exs` | ❌ new | ⬜ pending |
| DEBT-02 / SC4 | CI roster/topology consistent | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs` | ✅ edited | ⬜ pending |
| DEBT-02 / SC4 | no orphaned capture project | script | `bin/browser-full-projects --list config` = `desktop-chromium mobile-chromium route-capture`; Browser-full runs ≥1 non-skipped test | ✅ | ⬜ pending |
| DEBT-02 / SC4 | partition list names no deleted file | script | partition-row existence line in `tools/verify-phase.sh --close` | ❌ W0 | ⬜ pending |
| DEBT-02 / SC4 | Hex tarball exclusions intact | contract | `mix test test/threadline/release_artifact_contract_test.exs` | ✅ | ⬜ pending |
| DEBT-02 / SC4 | green suite + browser | full | `CI=true mix ci.all`; `mix verify.example_browser` | ✅ | ⬜ pending |
| DEBT-01 / SC1 | every row dispositioned, routes named, WINDOWS 0 open | script | `bash .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh --close` | ❌ W0 | ⬜ pending |
| DEBT-01 / SC2 | five cheap findings fixed | contract | `mix test test/threadline/deps_health_doc_contract_test.exs test/threadline/deps_audit_gate_test.exs test/threadline/deps_health_report_test.exs test/threadline/repo_hygiene_contract_test.exs test/threadline/changelog_contract_test.exs` | ✅ edited | ⬜ pending |
| DEBT-01 / SC2 | WR-04 guard is not vacuous | mutation control | negative control inside `deps_health_doc_contract_test.exs` | ❌ new | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh` — close check (blank dispositions, unnamed routes, WINDOWS open rows, refined grep allowlist, partition-row existence)
- [ ] retired-pointer doc contract test (replaces `critic_iteration_runbook_doc_contract_test.exs`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push of `archive/ui-critic-loop` | DEBT-02 | Publish step needs the maintainer's own grant (D-13) | `! git push origin refs/tags/archive/ui-critic-loop` at landing |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
