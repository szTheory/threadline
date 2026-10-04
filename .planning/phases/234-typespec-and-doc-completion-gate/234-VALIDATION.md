---
phase: "234"
slug: "typespec-and-doc-completion-gate"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-04"
---

# Phase 234 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) + dialyxir 1.4.8 + ExDoc 0.40.1 |
| **Config file** | `test/test_helper.exs`, `mix.exs` (`dialyzer:`), `.dialyzer_ignore.exs` |
| **Quick run command** | `mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/facade_naming_contract_test.exs` |
| **Full suite command** | `mix verify.test`; phase gate `mix ci.all` (incl. Dialyzer) |
| **Estimated runtime** | quick ~5 seconds; full suite several minutes; cold Dialyzer PLT rebuild ~9 min |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan:** `mix verify.dialyzer` and `MIX_ENV=dev mix docs --warnings-as-errors`
- **After every plan wave:** Run `mix verify.test`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green; D-46 exhaustive agent review recorded in VERIFICATION.md
- **Max feedback latency:** ~10 seconds (quick command)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 234-01-* | 01 | 1 | SPEC-01 | — | N/A | unit | `mix test test/threadline/doc_spec_coverage_contract_test.exs` | ❌ W0 | ⬜ pending |
| 234-02-* | 02 | 2 | SPEC-03, SPEC-02 | D-15/D-17 | unknown option keys raise `ArgumentError` | unit | `mix test test/threadline/facade_naming_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs` | ✅ | ⬜ pending |
| 234-03..05-* | 03–05 | 2 | SPEC-01, SPEC-02 | — | N/A | unit | `mix test test/threadline/doc_spec_coverage_contract_test.exs` | ❌ W0 | ⬜ pending |
| 234-06-* | 06 | 3 | SPEC-02 | — | N/A | static | `MIX_ENV=dev mix verify.dialyzer` + `mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

(The planner refines the task IDs; the rows above follow the D-47 plan shape.)

---

## Wave 0 Requirements

- [ ] `test/threadline/doc_spec_coverage_contract_test.exs` — SPEC-01 gate + vacuity sentinels + mutation control; part of SPEC-02 (bare-type lint, option-key parity)
- [ ] `234-SPEC-RUBRIC.md` — written rubric committed before any doc/spec write (consumed by the D-46 review)
- [ ] `test/partition_weights.txt` — weight line for the new gate test file

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Specs/docs "say something real" (no bare `term()`/`any()` where a shape exists) | SPEC-02 | Judgment call — handled by **agent review** (not a human) against `234-SPEC-RUBRIC.md` per D-46 | Agent reviews all ~92 entries and records the pass in VERIFICATION.md |

*Zero human verification: the judgment row is automated by agent review.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
