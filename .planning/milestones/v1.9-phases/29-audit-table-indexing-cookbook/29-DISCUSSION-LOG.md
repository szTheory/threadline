# Phase 29: Audit table indexing cookbook - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **29-CONTEXT.md**.

**Date:** 2026-04-24  
**Phase:** 29 — Audit table indexing cookbook  
**Areas discussed:** Guide placement & navigation; Baseline vs additive framing; Outline shape; Doc contract strictness  
**Mode:** `[--all]` area selection + parallel **subagent research** + maintainer-requested **cohesive auto-synthesis** (no interactive menus)

---

## Guide placement & navigation

| Option | Description | Selected |
|--------|-------------|----------|
| A | Standalone `guides/audit-indexing.md` + links from domain-reference & production-checklist | ✓ |
| B | Large section only inside `guides/domain-reference.md` | |
| C | Minimal pointer + deep content “elsewhere” (must still be first-class HexDocs) | (partial: thin pointer + A as target) |

**User's choice:** Research-led **Option A**, with **thin pointer** in domain-reference (C’s safe half) — see **29-CONTEXT.md D-1**.

**Notes:** Subagent compared Ecto/Oban/Phoenix/Ash patterns and Rails/Django/Envers/temporal-table doc failures (wiki-only ops, mega-reference). Footguns: duplicate DDL across docs, checklist links into fragile heading anchors without a stable page.

---

## Baseline vs additive framing

| Approach | Description | Selected |
|----------|-------------|----------|
| 1 | Explicit “what install gives you” before recommendations | ✓ (combined) |
| 2 | Jump straight to workload add-ons | |
| 3 | Two-column “shipped / consider adding” per access pattern | ✓ (combined) |

**User's choice:** **Hybrid of (1) + (3)** — not workload-first alone.

**Notes:** Emphasize non-mandatory DDL, redundant btree/GIN footguns, `CREATE INDEX CONCURRENTLY`, `EXPLAIN` / stats. Link migration modules as source of truth.

---

## Outline shape

| Strategy | Description | Selected |
|----------|-------------|----------|
| 1 | Per-table chapters first | (primer only) |
| 2 | Access-pattern chapters first | (deep dives) |
| 3 | Hybrid: short per-table primer + access-pattern deep dives | ✓ |

**User's choice:** **Hybrid (3)** with **“Tables & modules”** boxes and **no repeated** full index definitions across chapters.

---

## Doc contract strictness (IDX-02)

| Level | Description | Selected |
|-------|-------------|----------|
| Light | Marker + few headings | |
| Medium | Marker + outline headings + cross-link asserts | ✓ |
| Heavy | LOOP-04-style many literals / table rows | (reserved for promoted subsections only) |

**User's choice:** **Medium** default; **Heavy** opt-in per subsection with dedicated test + comment.

---

## Claude's Discretion

Exact IDX-02 marker string, exact heading list frozen in tests after first draft, optional README one-liner if it aids discovery without Phase 30 scope bleed.

## Deferred Ideas

- Full LOOP-04 matrix on entire cookbook — deferred unless explicitly promoted.
- Automated index recommendation — out of milestone per REQUIREMENTS.
