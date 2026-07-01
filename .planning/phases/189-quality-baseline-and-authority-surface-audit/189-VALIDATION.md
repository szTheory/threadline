---
phase: 189
slug: quality-baseline-and-authority-surface-audit
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-01
---

# Phase 189 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Static Markdown validation with `rg`, plus targeted Mix/ExUnit proof only when the audit cites fresh command evidence. |
| **Config file** | `.planning/config.json` |
| **Quick run command** | `test -f .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md && rg -n "Ranked Evidence Ledger|Score|Confidence|Practical consequence|Highest-leverage fix|Owner phase|QUAL-03|Good Enough|N/A|v1.39" .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` |
| **Full suite command** | `git diff --check && rg -n "Blocker|Must fix before publish|Prove before claim|External-owned|Maintenance note|Backlog cleanup|Future seed|Good enough|N/A|SEED-005|reconnect|screenshot|external pilot|host staging|CI/example|Hex|dependency|Nyquist|planning residual" .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` |
| **Estimated runtime** | ~10 seconds for static checks; targeted Mix commands vary by cited evidence. |

---

## Sampling Rate

- **After every task commit:** Run the quick artifact check.
- **After every plan wave:** Run the full static validation command.
- **Before `/gsd:verify-work`:** Full static validation must pass, and every command cited as fresh evidence in the audit must have current output recorded or rerun.
- **Max feedback latency:** 30 seconds for static checks; named Mix proof may exceed this only when a ledger row depends on current runtime evidence.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 189-01-01 | 01 | 0 | QUAL-01 | T-189-01 | Audit rows cite concrete evidence before scoring adoption, release, operations, or maintainer trust. | static artifact | `rg -n "Ranked Evidence Ledger|Score|Confidence|Practical consequence|Highest-leverage fix|Owner phase" .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` | missing W0 | pending |
| 189-01-02 | 01 | 0 | QUAL-02 | T-189-01 | Priority buckets separate must-fix risks from good-enough, maintenance, external-owned, backlog, future, and N/A items. | static artifact | `rg -n "Blocker|Must fix before publish|Prove before claim|External-owned|Maintenance note|Backlog cleanup|Future seed|Good enough|N/A" .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` | missing W0 | pending |
| 189-01-03 | 01 | 0 | QUAL-03 | T-189-02 / T-189-03 | Residuals do not overclaim reconnect, screenshot, external pilot, host staging, CI/example, dependency, or legacy planning proof. | static artifact | `rg -n "SEED-005|reconnect|screenshot|external pilot|host staging|CI/example|Hex|dependency|Nyquist|planning residual" .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` | missing W0 | pending |
| 189-01-04 | 01 | 1 | QUAL-01/02/03 | T-189-01 / T-189-02 / T-189-03 | Any fresh command evidence cited in the audit is reproducible from named commands, not implied by prose. | targeted proof | `mix verify.doc_contract && mix test test/threadline/ci_topology_contract_test.exs test/threadline/adoption_pilot_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs` when those surfaces are cited as current proof | existing | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` - primary artifact for QUAL-01, QUAL-02, and QUAL-03.
- [ ] Static artifact checks above pass against `189-QUALITY-AUDIT.md`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Authority-surface judgment calls preserve scope | QUAL-01/02/03 | Classification quality depends on reading evidence and consequences, not only token presence. | Review each ranked ledger row for evidence refs, practical consequence, highest-leverage fix, priority bucket, route bucket, and owner phase. Confirm no row broadens v1.39 beyond repo-backed authority-surface findings. |
| Fresh command evidence is not overstated | QUAL-01/03 | Commands may prove narrower behavior than a broad release, UI, or adopter claim. | For any command cited as current proof, compare the exact command output to the row's claim and classify broader claims as `Prove before claim`. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for static checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-01
