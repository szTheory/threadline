# Phase 211: Read-Side Agreement - Discussion Log

> Audit trail only. Downstream agents read CONTEXT.md, not this file.

**Date:** 2026-09-25
**Mode:** advisor (minimal_decisive). Three parallel gsd-advisor-researcher agents produced the recommendations. The maintainer instructed "auto follow your recommendations", so each area was locked without a per-area question.

## Areas and outcomes

| Area | Options researched | Locked pick |
|------|--------------------|-------------|
| Composite-key argument shape | (1) scalar, or keyword/map keyed by schema field; (2) the same plus a loaded struct | (1). Struct deferred as a stale-struct correctness risk (D-01..D-03) |
| Encoding parity | (A) render in Elixir; (B) PostgreSQL `::text` cast | Neither as proposed. The orchestrator verified on PG that `::text` diverges for timestamp (`T` vs space, DateStyle-dependent). Locked `to_jsonb(CAST($n AS type)) #>> '{}'`, which mirrors the write path byte for byte (D-04..D-06) |
| Row-history index delivery | (1) install template plus `mix threadline.gen.row_history_index`; (2) copy-paste guide only | (1) (D-09..D-13) |

## Corrections applied to research
- The index researcher assumed a single-column `table_pk`. After Phase 210, `table_pk` can be composite, but it is still tens of bytes, so the conclusion (no key-size risk) holds.
- The encoding researcher's `::text` proposal was replaced after a live PG check (see D-04).
- Composite-shape research keyed by schema field; a mapping back from `primary_key:` override column names was added (D-02).

## Deferred
- Loaded-struct id argument
- Composite-key operator history pages (UI parked until 1.0.0)
