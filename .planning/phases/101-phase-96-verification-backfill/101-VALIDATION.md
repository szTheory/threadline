---
phase: 101
slug: phase-96-verification-backfill
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 101 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) + Ecto/PostgreSQL via `Threadline.DataCase` + ripgrep (`rg`) for structural and artifact greps |
| **Config file** | `mix.exs`, `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` |
| **Full suite command** | Same as quick run — the focused bundle IS the authority per D-05 |
| **Estimated runtime** | ~10–30 seconds warm |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`
- **After every plan wave:** Run the same focused bundle plus the two structural greps (band-4 negative grep and band-1 closed-set grep on `lib/threadline/evidence.ex`)
- **Before `/gsd:verify-work`:** Focused bundle green, both grep assertions pass, artifact greps on `96-VERIFICATION.md` and `96-VALIDATION.md` show all required markers
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 101-01-* | 01 | 1 | PROOF-01 | — | Closed write-set + list-vs-singular read shape + mechanical defaults + Phoenix-optional boundary still hold on the current tree | integration + structural grep | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` and `rg -n '^\s*(import\|alias\|require\|use)\s+(Plug\|Phoenix)\.\|Process\.(put\|get)\(\|Logger\.metadata\(\|:ets\.' lib/threadline/evidence.ex` | ✅ | ⬜ pending |
| 101-02-* | 02 | 2 | PROOF-01 | — | `96-VERIFICATION.md` + finalized `96-VALIDATION.md` exist with required band markers and `## Commands Actually Used` section | artifact grep | `rg -n 'Current-tree preflight\|PROOF-01\|Not closed here\|Result: PASS' .planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md` and `rg -n '^phase: 96\|^nyquist_compliant: true\|## Commands Actually Used\|evidence_test\.exs' .planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` | ❌ W0 (created/finalized in 101-02) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*The per-task verification map will be expanded by the planner when each task's exact ID is assigned. The two rows above bound the authoritative sampling bundle: anything 101-01 / 101-02 does must satisfy at least one row above.*

---

## Wave 0 Requirements

- [ ] `.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md` — to be created in 101-01 (D-01..D-04, D-09, D-11..D-14, D-18)
- [ ] `## Commands Actually Used` section in `96-VALIDATION.md` — to be added in 101-02 (D-16)
- [ ] `## Phase Boundary Guard` section in `96-VALIDATION.md` — to be added in 101-02

*No code/test gaps: the focused-bundle tests, the implementation module, the schema, the subject inventory, and the grep target all exist on the current tree at planning time. Phase 101 is verification-backfill — code is not modified beyond smallest literal-truth repair (D-15).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Prose accuracy of the band statements in `96-VERIFICATION.md` matches the source-of-truth contract | PROOF-01 | Prose claims (e.g., "no generic public writer exists", "every public function requires `repo:` opt") are summarized assertions; the automated grep + test commands prove the underlying facts but the prose summarizing them is human-authored | Reviewer reads `96-VERIFICATION.md` end-to-end and confirms each band's prose matches the cited grep/test outputs |

*All band-level proofs are automated via grep + ExUnit; only the prose summary review is manual.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter (flipped after sign-off)

**Approval:** pending
