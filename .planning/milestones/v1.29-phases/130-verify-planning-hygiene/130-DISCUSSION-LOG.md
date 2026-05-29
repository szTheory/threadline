# Phase 130: Verify & Planning Hygiene - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 130 — Verify & Planning Hygiene
**Areas discussed:** 125 artifact location, Nyquist 125 evidence, SUMMARY convention scope, gap-closure REQ mapping

---

## 125 artifact location

| Option | Description | Selected |
|--------|-------------|----------|
| Archive at `milestones/v1.27-phases/125-…/` | Matches v1.25 archive; active phases/ stays v1.29-only | ✓ |
| Stub in active `phases/125-…/` | NYQ-01 path unchanged but shipped work looks in-flight | |
| Path update only, no restore | Cannot sign file that doesn't exist | |

**User's choice:** Archive pattern (Option A) — via research synthesis and "create context" confirmation
**Notes:** v1.29 init deleted 122–127 without move; restore from git `46332ef^`. Update NYQ-01 paths in same commit as sign-off.

---

## Nyquist 125 evidence strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh rerun (126-layered) | Tier 1 charter + doc_contract; Tier 2 session-close ci.all | ✓ |
| Attestation-only | Zero cost but disqualified — charter test likely red on current tree | |
| Targeted only, skip ci.all | Incomplete for Phase 130 closeout SC #3 | |

**User's choice:** Fresh rerun with 126 D-17 single session-close `mix ci.all`
**Notes:** Charter test currently locks v1.28 active milestone; v1.29 alignment prerequisite before Tier 1. Retroactive Nyquist backfill note required.

---

## SUMMARY convention scope (PLAN-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Convention + archive + clarify 125–127 | SSOT doc; verbatim 122–124 SUMMARY archive; GAP backfill 125–127 | ✓ |
| Convention only | Leaves v1.27 audit confusion | |
| Full 15-file restore + edit all | Scope creep; 122–124 already correct | |

**User's choice:** Refined Option A
**Notes:** v1.27 audit overstated — only 125–127 had empty arrays. Audit errata on v1.27-MILESTONE-AUDIT.md.

---

## Gap-closure REQ mapping

| Option | Description | Selected |
|--------|-------------|----------|
| GAP-{phase}-{nn} IDs + gap-closure: true | Honest namespace; populates 3-source Source 2 | ✓ |
| Empty + convention note | Already failed v1.27 audit (fell back to provides) | |
| Map to DIST/CFG/DOC | Fake compliance — archive says does not reopen | |

**User's choice:** GAP-* namespace with gap-closure flag
**Notes:** 127 never claims DOC-03. GAP IDs excluded from milestone REQ score. NYQ-01 is Phase 130 not GAP-126.

---

## Claude's Discretion

- Plan split (one vs two plans)
- Exact charter literal strings for v1.29
- Optional 126–127 VALIDATION restore to archive

## Deferred Ideas

- Full v1.27 phase tree restore beyond SUMMARY + 125 proof chain
- gsd-audit-milestone GAP ID tooling
- PROJECT.md duplicate milestone block cleanup
