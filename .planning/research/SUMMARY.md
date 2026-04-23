# Project Research Summary

**Project:** Threadline  
**Domain:** Elixir + PostgreSQL application-level audit capture (Path B triggers)  
**Researched:** 2026-04-23  
**Confidence:** HIGH

## Executive Summary

v1.2 extends the existing **custom trigger** architecture rather than introducing WAL/CDC or session-heavy patterns. **Before-values** should be implemented as an **optional** JSONB column populated from `OLD` on UPDATE only, keeping the capture path free of `SET LOCAL` and preserving the transaction-scoped `txid` grouping already shipped. **Maintainer tooling** should build on `Threadline.Health.trigger_coverage/1` with a **CI-friendly Mix task**, add **doc contract tests** to lock README examples to the public API, and treat **backfill** as a documentation-first contract with explicit semantics so operators are never misled about pre-audit history.

The roadmap should land **capture + query correctness first** (Phase 9), then **verify + doc contracts** (Phase 10), then **brownfield backfill** (Phase 11) so CI and docs stay honest before encouraging bulk adoption workflows.

## Key Findings

### Recommended Stack

Stay on **Elixir ≥ 1.15**, **PostgreSQL ≥ 14**, **Ecto 3.x**. No new runtime dependencies are required: before-values are a **nullable JSONB column** plus PL/pgSQL changes; verification uses catalog queries and existing health logic patterns.

### Expected Features

**Must have (table stakes):**

- CI-usable **coverage verification** for “is capture actually installed?”  
- **Additive** `changed_from` behavior that does not break existing `history/2` callers  

**Should have (competitive):**

- **Optional** before-values for UPDATE — aligns with archived BVAL vision  
- **Doc contract tests** — OSS quality bar already referenced in PROJECT engineering baseline  

**Defer (later milestones):**

- Retention, redaction, export, LiveView UI  

### Architecture Approach

Centralize trigger changes in **`Threadline.Capture.TriggerSQL`**, schema in **`mix threadline.install`** migrations, and read APIs in **`Threadline.Query` / `Threadline` delegators**. Surface new fields on **`AuditChange`** Ecto schema. Add Mix tasks next to existing **`threadline.gen.triggers`**.

### Critical Pitfalls

1. **Session / `SET LOCAL` in triggers** — avoid; stay PgBouncer-safe.  
2. **Ambiguous `changed_from` semantics** — define INSERT/DELETE = nil; UPDATE-only population.  
3. **`verify_coverage` false positives/negatives** — require explicit repo/schema/table configuration; test failure modes.  
4. **Backfill that invents history** — document explicit baseline / marker strategy.  
5. **Doc tests that do not track README** — compile or parse real excerpts.

## Implications for Roadmap

### Phase 9: Before-values capture

**Rationale:** Schema + trigger + query are one vertical slice; everything else assumes correct rows on disk.  
**Delivers:** Migration, `TriggerSQL` UPDATE branch, `gen.triggers` option wiring, `AuditChange` field, `history` returning `changed_from` when present.  
**Addresses:** BVAL-01, BVAL-02  
**Avoids:** Pitfalls 1–2  

### Phase 10: Verify coverage & doc contracts

**Rationale:** Low coupling to backfill; raises adoption confidence immediately after capture work.  
**Delivers:** `mix threadline.verify_coverage`, doc contract tests in CI.  
**Addresses:** TOOL-01, TOOL-03  
**Avoids:** Pitfalls 3, 5  

### Phase 11: Backfill / continuity helper

**Rationale:** Depends on stable capture schema and honest operator story.  
**Delivers:** Documented API + tests for introducing capture to existing tables without false history.  
**Addresses:** TOOL-02  
**Avoids:** Pitfall 4  

### Phase Ordering Rationale

BVAL first (data plane), then verification/docs (guardrails), then backfill (brownfield narrative).

### Research Flags

- **Phase 11:** Highest product ambiguity — plan-phase should lock **exact** helper API and semantics of synthetic vs replayed rows.  
- **Phase 9:** Confirm whether `changed_from` is **full OLD row** vs **only keys in `changed_fields`** during `/gsd-discuss-phase` (tradeoff: storage vs clarity).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new external services |
| Features | MEDIUM–HIGH | Backfill semantics need user-visible spec in plan-phase |
| Architecture | HIGH | Matches existing modules |
| Pitfalls | HIGH | Well-trodden in audit systems |

**Overall confidence:** HIGH for Phases 9–10; MEDIUM for Phase 11 until semantics locked.

### Gaps to Address

- **Exact `store_changed_from` UX:** CLI flag shape on `gen.triggers` vs migration-only — decide in discuss-phase.  
- **verify_coverage table discovery:** argv-only vs module attribute vs `Application` config — decide in plan-phase with CI example.

## Sources

### Primary (HIGH confidence)

- `lib/threadline/capture/trigger_sql.ex`, `lib/threadline/capture/audit_change.ex`, `lib/threadline/query.ex`  
- `.planning/PROJECT.md` constraints  

### Secondary (MEDIUM confidence)

- Archived v1.0 requirements v2 section (BVAL / TOOL intent)

---
*Research completed: 2026-04-23*  
*Ready for roadmap: yes*
