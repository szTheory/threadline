# Phase 30: Retention at scale & discovery - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`30-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 30 — Retention at scale & discovery  
**Mode:** Maintainer requested **all gray areas** + **parallel subagent research** + **one-shot cohesive recommendations** (no interactive option menus).

**Areas covered:** Checklist IA (SCALE-01); Retention API checklist surface (SCALE-01); Export / timeline / support linkage (SCALE-01); Discovery hub (SCALE-02).

---

## 1. Checklist IA for volume / growth

| Option | Description | Selected |
|--------|-------------|----------|
| A | Extend §4 only with bullets | |
| B | New top-level `##` (renumber following sections) | |
| C | Hybrid: `### Volume, growth, and purge cadence` under `## 4. Retention and purge` | ✓ |

**User's choice:** All areas discussed; synthesized choice **C** (subagent recommendation + maintainer merge).  
**Notes:** Preserves `#6-observability` stability; avoids splitting purge from growth under incident load.

---

## 2. Retention API surface in checklist

| Option | Description | Selected |
|--------|-------------|----------|
| Full names everywhere | Repeat modules/tasks on every bullet | |
| Link-first | Minimal names; defer to guides | |
| Hybrid | Gates + literal mix/config; name Policy + `purge/1` once; defer semantics | ✓ |

**User's choice:** **Hybrid** (subagent + alignment with Phase 28 split).  
**Notes:** Meets SCALE-01 explicit API ties without triple drift.

---

## 3. Export, timeline, support linkage

| Option | Description | Selected |
|--------|-------------|----------|
| A | §4 bullets only | |
| B | Heavy §5 + support footnotes | |
| C | New standalone bridge section | |
| D + minimal B | Short §4 (H3) corpus narrative + support intro line + §5 bullet; optional Q3/Q4 table tweak | ✓ |

**User's choice:** **D + minimal B** (subagent recommendation).  
**Notes:** Co-located with D-1 H3 content; no new bridge H2.

---

## 4. Discovery pointer (SCALE-02)

| Option | Description | Selected |
|--------|-------------|----------|
| README only | | |
| Domain-reference only | | |
| README + hub in domain-reference | One README paragraph + short hub H2 with outbound links only | ✓ |

**User's choice:** **README + domain-reference hub** (subagent recommendation).  
**Notes:** Hub is link router only; telemetry and indexing depth stay in canonical files.

---

## Claude's Discretion

- Exact heading strings and optional Q3/Q4 table clauses left flexible per **`30-CONTEXT.md`**.

## Deferred Ideas

- Renumbering production-checklist for a standalone volume section — explicitly deferred in CONTEXT.
