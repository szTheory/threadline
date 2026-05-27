---
phase: 104
slug: reference-walkthrough-charter-override-decision
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 104 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
>
> **Phase scope is `.planning/`-only.** No code, no tests, no framework runs. All validation is read-based: deterministic grep / exact-string assertions against the two edited files (`PROJECT.md`, `MILESTONE-ARC.md`) plus a human cold-read check against the four ROADMAP success criteria.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — docs-only phase, no test runner involved |
| **Config file** | n/a |
| **Quick run command** | `grep` assertions per task (see Per-Task Verification Map below) |
| **Full suite command** | `bash .planning/phases/104-reference-walkthrough-charter-override-decision/scripts/verify.sh` (planner may inline grep checks into each task instead) |
| **Estimated runtime** | <5 seconds total |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` grep assertion(s) against the modified file.
- **After every plan wave:** Re-grep all edits + read the four ROADMAP success criteria against the live files.
- **Before `/gsd:verify-work`:** All four ROADMAP success criteria readable by inspection.
- **Max feedback latency:** <5 seconds (grep against two `.planning/` files).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD     | TBD  | TBD  | CHARTER-01/02/03 | — | N/A (docs-only) | grep / exact-string match | `grep -Fq '{exact string from D-02/D-03/D-04}' .planning/PROJECT.md` (or MILESTONE-ARC.md) | ✅ existing files | ⬜ pending |

*The planner fills this table after task IDs are known. Every doc-edit task gets at least one `grep -Fq` assertion using a verbatim substring from CONTEXT.md's locked text. No fuzzy matching — exact-string only.*

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] No framework install required — docs-only phase.
- [ ] No fixture files required.

*Existing infrastructure covers all phase requirements: shell, grep, and the two `.planning/` files already exist.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| <2-minute cold-read criterion | CHARTER-03 (ROADMAP success criterion 4) | Subjective reader-comprehension test; no automated proxy exists | Maintainer opens `.planning/PROJECT.md` and `.planning/MILESTONE-ARC.md` from scratch and confirms within 2 minutes that v1.23 is the synthetic-first-adopter milestone, why the v1.22 rule was set aside, and what would re-engage it. Logged as PASS/FAIL in `104-SUMMARY.md` or `104-VERIFICATION.md`. |
| House-style fit of new Key Decisions row | CHARTER-01 | Density / tone match against v1.17–v1.22 precedent is a stylistic judgement | Maintainer reads the new v1.23 row alongside the v1.17/v1.18/v1.19/v1.21/v1.22 rows and confirms voice, density, and structure match. |
| Strategic-thesis paragraph reads coherently after the appended sentence | CHARTER-02 | Prose-flow check; no automated proxy | Maintainer reads the full strategic-thesis paragraph at MILESTONE-ARC.md line 9 and confirms the appended sentence integrates cleanly. |

---

## Validation Sign-Off

- [ ] Every doc-edit task has at least one `grep -Fq` exact-string assertion in `<automated>`.
- [ ] Sampling continuity: each commit re-verifies prior edits remain in place (no overwrite regressions).
- [ ] Wave 0 covers all MISSING references — N/A (no framework needed).
- [ ] No watch-mode flags — N/A.
- [ ] Feedback latency <5 seconds — confirmed (grep against two files).
- [ ] `nyquist_compliant: true` set in frontmatter once the planner fills the Per-Task Verification Map with concrete task IDs and grep assertions.

**Approval:** pending
