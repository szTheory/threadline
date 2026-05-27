# Phase 109: Maintainer Walkthrough Dry-Run - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 109-maintainer-walkthrough-dry-run
**Areas discussed:** All 6 gray areas (user requested `--all` with subagent research + one-shot recommendations)

---

## Clean clone setup

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh `git clone` to isolated temp dir | Truest RUN-01 cold start; matches WALKTHROUGH §0 + v1.14 isolated verify precedent | ✓ |
| Git worktree at pinned SHA | Acceptable maintainer shortcut; same semantics as clone | (fallback) |
| Dedicated branch on dev tree | Fast but not clean — rejects false confidence | |
| Full Docker ephemeral environment | Hides laptop install pain; OTel-demo pattern wrong for Hex lib | |

**User's choice:** Auto-selected all areas; research synthesized into D-109-01 (fresh clone primary, worktree acceptable shortcut, dev tree rejected).

**Notes:** Path dep requires cloning repo root. Pin `WALK_BASELINE_SHA` before walk. Current dirty main tree must not be used for §1–§5 execution.

---

## Known review warnings (WR-001 / WR-002)

| Option | Description | Selected |
|--------|-------------|----------|
| Proceed observe-only; file as findings | Honors scope guard; validates protocol end-to-end | ✓ (refined) |
| Pre-register + walk + confirm (Option C) | Execution log distinguishes expected vs surprise; still file 0001/0002 | ✓ |
| Narrow 108.x doc fix before walk | Cleaner pass but erodes observe/fix separation | |
| Skip affected steps | Violates RUN-02; loses WR-002 CLI evidence | |

**User's choice:** Option C — pre-register in `109-EXECUTION-LOG.md`, walk verbatim, file 0001 (WR-001 → a) and 0002 (WR-002 → c) with empirical evidence, continue walking.

**Notes:** RUN-02 partial failure on first pass is valid Phase 109 outcome. Phase 110 fixes doc + demo_contract gap.

---

## Environment & Postgres bootstrap

| Option | Description | Selected |
|--------|-------------|----------|
| Strict §1 body only | §0 becomes decorative; false (a) on compose :5433 | |
| Permissive — §0 in-scope (Option B) | Entire WALKTHROUGH.md is RUN-01 authority | ✓ |
| README/compose escape hatch | Violates D-108-01b self-containment | |
| Full containerized walk | v1.24 seed; not RUN-01 today | |

**User's choice:** D-109-02 — two blessed paths (local :5432 or compose + `export DB_PORT=5433`); Appendix B Mix-only; environment ambiguity → (c) not (a).

---

## Hard blocker vs partial walk

| Option | Description | Selected |
|--------|-------------|----------|
| Strict STOP on any hard blocker | Loses independent §4/§5 signal after §1 passes | |
| Tiered skip | Good breadth but needs formal gate rules | |
| Always continue | Junk cascade if §1 seed fails | |
| Checkpoint-gated (Option D) | §1 hard gate; §4 incidents independent | ✓ |

**User's choice:** D-109-04 — infrastructure unanswerable → STOP; outcome unanswerable → finding + continue; WR-001 must not block WALK-03-01/03-04.

---

## Finding capture cadence

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate MVP at "If different" | Best FINDINGS-02 compliance; per-step contract | ✓ |
| Batch at section checkpoints | Memory decay; deferred classification risk | |
| Hybrid — MVP at trigger + checkpoint review | Balances friction and signal | ✓ |
| Single end batch | Unacceptable on multi-hour walk | |

**User's choice:** D-109-05 — MVP file at each "If different"; checkpoint tables review-only; `109-WALK-CHECKPOINT.json` for resume.

---

## Audit trail for scope guard

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated branch in main repo | Weak without isolation; dirty main confounds | |
| Clean clone + import findings (Option B) | Strongest proof; v1.14 precedent | ✓ |
| Execution log only | Insufficient when main has parallel edits | |
| Worktree + pre-commit hook | Surprising new tooling; bypassable | |

**User's choice:** D-109-06 — B+C: isolated clone at pinned SHA + `109-EXECUTION-LOG.md` + git path-filter verification in `109-VERIFICATION.md`.

---

## Claude's Discretion

- Exact temp clone path naming
- Optional `scripts/verify-phase-109-scope.sh` vs inline verification
- Screenshot policy under `findings/assets/`
- Second walk against remote `main` if unpushed

## Deferred Ideas

- Full containerized walk → v1.24 seed
- Pre-commit hook enforcement → rejected
- Pre-fix WR-001/WR-002 → rejected (file as findings)
- `mix verify.phase_109_scope` alias → optional post-109 if reused
