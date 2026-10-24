# Phase 237: Upgrade Guide and 1.0.0 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-07
**Phase:** 237-Upgrade Guide and 1.0.0
**Areas discussed:** Upgrade path and CHANGELOG coverage, Release-please 1.0.0 rehearsal and landing

---

## Upgrade path and CHANGELOG coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Stable change IDs in invisible HTML comments with exact-set contract | Keeps prose hand-written and human-owned while making omissions and duplicate mappings fail closed. | ✓ |
| Infer mapping from Markdown headings and prose | Avoids markers but couples tests to wording and can miss semantic mismatches. | |
| Structured manifest and generated guide steps | Makes the inventory explicit but creates another source of truth and is a poor fit for detailed adopter instructions. | |
| 0.11-only preflight plus seven 1.0 steps | Summarize the three 0.12.0 required actions for 0.11 adopters; 0.12 adopters skip them. State no 1.0 trigger regeneration is required. | ✓ |
| Link only to the 0.12 change list | Shorter, but the adopter would have to discover and reconstruct the required action. | |
| Force every reader through all earlier release guides | More complete than needed and makes a 0.12 adopter repeat work. | |

**Auto-selected recommendation:** Stable IDs with exact set checks; one conditional 0.11 preflight, then the seven required 1.0 steps. No 1.0 step requires trigger regeneration.

---

## Release-please 1.0.0 rehearsal and landing

| Option | Description | Selected |
|--------|-------------|----------|
| Extend the disposable-clone rehearsal to target committed 1.0.0 candidate HEAD | Validate feat! subject, exactly one Release-As: 1.0.0 footer, config flag off, exact simulated target, and existing artifact gates without external writes. | ✓ |
| Use a separate Release Please staging repository | Closer to the live action, but adds a maintained staging repo, token scope, and environment drift. | |
| Rely on the release PR after merging | Gives live action evidence but cannot prove the version before merge. | |

**Auto-selected recommendation:** Extend the existing helper, describe it accurately as a local artifact rehearsal, and use the generated release PR/run as the live Release Please evidence. Keep push, merge, and production-hex publication behind separate explicit maintainer grants.

## the agent's Discretion

- Exact change-ID spelling and test module placement.
- Guide wording and headings within the locked seven-step structure.
- Isolated method for rehearsing the candidate squash, without external release actions.

## Deferred Ideas

None.

