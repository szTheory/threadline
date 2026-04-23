# Phase 14: Export (CSV & JSON) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `14-CONTEXT.md` — this log preserves alternatives considered.

**Date:** 2026-04-23  
**Phase:** 14 — Export (CSV & JSON)  
**Areas discussed:** Filter API parity, Row shape & JSON stability, Large exports & streaming, Operator surfaces (Mix vs API-only)  
**Mode:** User selected **all** areas and requested parallel **research subagents** + single synthesized recommendation set.

---

## 1. Filter API parity

| Option | Description | Selected |
|--------|-------------|----------|
| A — Mirror `timeline/2` | Same `filters` + `opts`, same `:repo` resolution | ✓ |
| B — Caller `Ecto.Query` / stream | Maximum flexibility, dual semantics risk | |
| C — Hybrid + extension hook | Timeline + optional query extension | |

**User's choice:** Research synthesis + explicit user instruction to optimize for least surprise and EXPO “same logical filter.”  
**Notes:** Prior art (PaperTrail/Audited scopes, Carbonite query builders, Logidze SQL-first) reinforced **one blessed filter contract** for app code. Recommendation: **A** with **shared internal query builder** (D-01–D-04 in CONTEXT). Raw `Ecto.Query` public input deferred.

---

## 2. Row shape & JSON stability

| Option | Description | Selected |
|--------|-------------|----------|
| Flat-only CSV | All scalar columns | |
| Hybrid CSV + JSON cells | Stable scalars + JSON strings for blobs | ✓ |
| Top-level JSON array only | `[{...}]` without metadata | |
| Versioned wrapper + `changes` | `format_version`, `generated_at`, array | ✓ |
| Separate txn fetch API | Avoid join duplication | |
| Single-join embed txn | Slim `transaction` object per row | ✓ |

**User's choice:** Synthesis favoring ops (spreadsheets + `jq`) + stable headers + **NDJSON** sibling format for pipelines.  
**Notes:** Footguns called out: CSV escaping, Excel cell limits on huge JSONB, map key order in tests, DELETE `data_after` nil.

---

## 3. Large exports & streaming

| Option | Description | Selected |
|--------|-------------|----------|
| `Repo.all` + encode | Simple, OOM risk | Default for tiny only |
| `Repo.stream` + long txn | Low memory, pool/timeout footguns | Documented advanced |
| Keyset pages + `Stream` | Short txns, resumable feel | ✓ (primary streaming story) |
| Hard cap / truncation metadata | Predictable cost, honest UX | ✓ (default API) |

**User's choice:** **Bounded default** with explicit `truncated?` style metadata; **keyset pagination stream** for library consumers; **long `Repo.stream`** optional with strong warnings (Plug timeouts, pool starvation, JSONB row size).

---

## 4. Operator surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| API only | Minimal surface | |
| API + argv Mix task | Parity with retention / continuity | ✓ |
| API + Mix + stdin JSON | Dynamic filters | Deferred |
| IEx recipes only | Docs-only | Supplement, not primary |

**User's choice:** **Public module as source of truth** + **thin `mix threadline.export`** delegating to it; stdin JSON deferred to avoid spec/support burden in v1.3.

---

## Claude's Discretion

Exact atoms for `max_rows`, module naming, nested vs flat `transaction` keys, optional “minimal CSV” profile, and whether a `Repo.stream` helper ships in code vs docs-only in v1.3.

## Deferred Ideas

See `<deferred>` in `14-CONTEXT.md` (public `Ecto.Query` export, stdin JSON, dynamic CSV headers, optional `timeline_query/1`).
