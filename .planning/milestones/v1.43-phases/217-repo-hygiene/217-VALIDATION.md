---
phase: "217"
slug: "repo-hygiene"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-27"
---

# Phase 217 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3-otp-27) + bash guard scripts under `bin/` |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test <guard contract test> <migrated tmp_dir test files>` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~30 seconds quick; full `ci.all` several minutes |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the files the task touched (guard test, migrated test files, or `git grep -I` scrub check)
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd-verify-work`:** `mix ci.all` green, plus the HYG-03 "no new system-temp entries after full `mix test`" check
- **Max feedback latency:** 60 seconds for the quick command

---

## Per-Task Verification Map

Filled by the planner from the PLAN.md `<automated>` commands. Per-requirement anchors from RESEARCH.md:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| HYG-01 | No tracked file contains a machine-local path | contract | the HYG-02 guard run against the tree, plus `git grep -l -I` of the pattern returning nothing | ✅ (guard lands in the same phase) | ⬜ pending |
| HYG-02 | Guard scans tracked text only, allowlists runner/cache paths, fails on an unused allowlist entry, goes red on runtime-built fixtures | unit/contract | `mix test` on the new guard contract test + guard `--self-test` | ❌ W0 | ⬜ pending |
| HYG-03 | 7 files use `@tag :tmp_dir`; tree walkers ignore `tmp/`; full `mix test` leaks nothing into the system temp dir | integration | `mix test` on the 7 files + snapshot/diff of `System.tmp_dir!()` around a full `mix test` | ❌ W0 (leak-check script) | ⬜ pending |
| HYG-04 | `verify.xref_cycles` unchanged, no runtime-cycle gate, §9a and the v1.45 observation are on record | verification | `mix xref graph --format cycles --label compile-connected` (0) and unlabelled (5) plus `git diff` on `mix.exs` alias | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New guard contract test file (HYG-02) with runtime-built fixtures, so no literal username appears in committed source
- [ ] A "no leaked system-temp entries after full `mix test`" check (HYG-03)

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
