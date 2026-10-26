# Phase 246: Debt closeout and critic retirement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-10-25
**Phase:** 246-debt-closeout-and-critic-retirement
**Areas discussed:** Removal boundary, Restoration tag, Register disposition, 215/223 fix-vs-waive, CI/suite consistency

Method: research-then-recommend (CLAUDE.md). Five parallel researchers, one per cluster, the last being an adversarial consistency pass. The output was one synthesized recommendation set with a single confirm.

---

## Single confirm

| Option | Description | Selected |
|--------|-------------|----------|
| Lock all (Recommended) | A–D as stated, including full removal of MechanicalChecker, Tier-A and the required `verify-capture` job, recorded as a coverage retirement | ✓ |
| Lock, keep mech floor | Keep MechanicalChecker, Tier-A and `verify-capture`; only the LLM critic, refute/graded and the critic fixtures go | |
| Discuss first | Talk through items before locking | |

**User's choice:** Lock all.

## Alternatives considered and rejected

- **Restoration container:** an archive branch (mutable; D-31 already retired the backup-branch pattern), a tag on a milestone-branch commit (unreachable after the squash), a separate repo (overkill for parked code), a lightweight tag (no rationale), and a local-only tag (defeats restorability).
- **Browser-full:** deleting the workflow was rejected in favour of keeping the one surviving `route-capture` project.
- **Dialyzer:** keeping `critic-tooling.json` as a sealed exemption was rejected in favour of re-pointing the slice and restating the counts.
- **Recording dispositions:** editing the research table in place, or only per-source disposition files, was rejected in favour of a canonical 246-DEBT-REGISTER.md plus durable pointers.
- **WINDOWS:** hand-editing the table was rejected because gsd-tools re-renders it.

## Claude's Discretion

- The commit grouping within D-10, the wording of waivers and pointers, and the Dialyzer slice target.

## Deferred Ideas

- Untangling the degraded twin (SEED-008); routed items per D-18 to D-23; 245 findings stay in 245's disposition.
