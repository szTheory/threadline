# Phase 104: Reference-Walkthrough Charter & Override Decision - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 104-reference-walkthrough-charter-override-decision
**Areas discussed:** Re-engagement trigger precision, MILESTONE-ARC.md scope of edits, Non-goals home in PROJECT.md, Key Decision row structure

---

## Re-engagement trigger precision

How "first real-adopter signal" should be defined so it can fire honestly or be honestly rejected at the next milestone-arc reread.

| Option | Description | Selected |
|--------|-------------|----------|
| A. Qualitative + concrete examples + "sustained, not drive-by" clause | Define qualitatively, list three concrete shapes (live-integration issue, maintainer-confirmed pilot host, named procurement/security-review/eval conversation), explicit drive-by carve-out, soft signals routed to `.planning/v1.24-seeds/`. | ✓ |
| B. Loose verbatim ROADMAP phrasing | "Any issue, pilot host, or procurement conversation" — maximally inclusive but fires on noise. | |
| C. Strict enumerated list with hard quality bar | Maximally unambiguous; brittle for novel adopter shapes; risks override becoming permanent. | |
| D. Two-tier (amber = noted, green = pauses synthetic work) | Captures noise without losing it; one more rule to maintain. | |

**User's choice:** Option A (with a light D-flavored routing hook for drive-by interest → v1.24 seeds).

**Notes:** User flagged that v1.23's whole premise is "synthetic-but-realistic adoption pressure" because no real adopter exists. Tight enumeration (C) would over-fit the current idea of adoption; loose phrasing (B) would re-litigate every milestone-arc reread. Option A matches in-house Key Decision voice (v1.17 "after hundreds of adopters", v1.18 "once real adopters report row-cap pain") and uses the same `.planning/v1.24-seeds/` routing established for Phase 110.

---

## PROJECT.md Key Decisions row structure

How to encode override + rationale + override-trigger + re-engagement-trigger in the 3-column Key Decisions table.

| Option | Description | Selected |
|--------|-------------|----------|
| A. Single dense row | Pack all four facets into Decision / Rationale / Outcome cells; re-engagement clause bolded as last sentence of Rationale. | ✓ |
| B. Two rows (decision + re-engagement protocol) | Separate immutable decision from evolvable operating rule; no precedent in this table. | |
| C. Row + linked detail block | Scan-friendly; introduces new section to maintain. | |
| D. Cross-doc reliance only | Zero new structure; relies on ROADMAP/REQUIREMENTS consistency. | |

**User's choice:** Option A.

**Notes:** Tyree–Akerman / mature ADR pattern folds revisit-triggers inline rather than splitting. Threadline's v1.18 exports row ("Revisit in v1.20 once real adopters report row-cap pain") is direct in-house precedent. Bolded `**Re-engages…**` clause keeps the trigger operative without fragmenting the record. Density matches v1.17 / v1.18 / v1.21 rows.

---

## v1.23 non-goals home in PROJECT.md

Where the CHARTER-03 non-goals get locked.

| Option | Description | Selected |
|--------|-------------|----------|
| A. Top-level `## Out of Scope` only | Add v1.23 bullets to the durable cross-milestone list; pollutes durable list with release-scoped items. | |
| B. New `**v1.23 non-goals:**` subsection under Current Milestone block | Matches v1.6/v1.7/v1.8 house style; archived with milestone block at v1.23 close. | ✓ |
| C. Both locations | Durability + visibility; duplication risk. | |
| D. Cross-ref to REQUIREMENTS.md | Single source of truth; weakens PROJECT.md as strategic at-a-glance doc. | |

**User's choice:** Option B (with durability hook — durable items get promoted to top-level Out of Scope at v1.23 archive time by `/gsd-complete-milestone`).

**Notes:** v1.6 / v1.7 / v1.8 / v1.9 / v1.10 shipped-milestone blocks in PROJECT.md all end with `**Non-goals (unchanged):**` prose. This is established house style. Top-level `## Out of Scope` stays cross-milestone durable. REQUIREMENTS.md already carries the canonical traceable Out of Scope table — no duplication.

---

## MILESTONE-ARC.md scope of edits

Whether Phase 104 also fixes stale fields (Active-milestone line, v1.22 status, Next-ranked-candidate) or strictly adds the v1.23 row + thesis paragraph and leaves the rest for `/gsd-complete-milestone`.

| Option | Description | Selected |
|--------|-------------|----------|
| A. Minimal (v1.23 row + thesis only) | Strictest D-02/D-16 reading; leaves file actively lying. | |
| B. Targeted fix (status fields + v1.23 row, one commit) | ADR status-field carve-out; matches mature OSS doc-discipline; file is internally consistent after. | ✓ |
| C. Full archive sweep | Conflates Phase 104 with `/gsd-complete-milestone`; violates D-02. | |
| D. Two-commit split | Clearest audit trail; ceremony-heavy for ~5 line edits. | |

**User's choice:** Option B (single commit). Explicit boundary-discipline note (D-05 in CONTEXT.md) records the carve-out rationale so it does not become a precedent that erodes D-02.

**Notes:** ADR community (AWS, Microsoft, Backstage) carves out status-field freshness from narrative restructuring. Threadline's own v1.22 archive demonstrably missed these fields — Phase 104 recovers them rather than letting the file mislead future readers. The option-record table's narrative re-ordering remains archive work.

---

## Claude's Discretion

- Exact past-tense rewording of MILESTONE-ARC.md option-record row 6 "Why" cell — must convey "v1.22 shipped" without restating v1.22 facts already in PROJECT.md.
- Plan structure (single plan vs. multiple atomic plans) is the planner's call; user signaled single-commit framing.

## Deferred Ideas

- Refine "sustained real-adopter signal" further at v1.24 charter time if the boundary is ever tested mid-milestone.
- Promote durable v1.23 non-goals (RBAC/tenancy boundary) to top-level `## Out of Scope` at v1.23 archive time.
- Add a "MILESTONE-ARC.md status-field freshness check" to the `/gsd-complete-milestone` checklist — Phase 104 surfaced that v1.22's archive missed these fields.
