# Phase 210: PK-Agnostic Capture - Discussion Log

> **Audit trail only.** Do not use this log as input to planning, research or execution agents.
> The decisions are captured in CONTEXT.md. This log keeps the alternatives that were considered.

**Date:** 2026-09-25
**Phase:** 210-pk-agnostic-capture
**Areas discussed:** Fallback semantics, trigger body + benchmark, migrate-time validation, `primary_key:` override surface

Mode: advisor (calibration tier `minimal_decisive`) and text mode. Four parallel `gsd-advisor-researcher` agents ran, and their findings were synthesized into one recommendation set. The maintainer replied "auto follow ur recs", which accepted everything, including the two HIGH-IMPACT items (D-11 and D-14..D-18).

---

## Fallback semantics (CAP-04)

| Option | Description | Selected |
|--------|-------------|----------|
| A: Literal legacy + naive loop | A no-arg trigger always writes `{"id": row->>'id'}`. TG_ARGV missing columns store `{"col":null}` | |
| B: Legacy + per-row `pg_index` slow path for non-`id` tables | ARCHITECTURE.md Pattern 1. About 2x per row, and it violates SC5's rule of no catalog lookup in the trigger body | |
| C: Resolve fully or store `{}` | Legacy output is byte-identical on `id` tables, `{}` otherwise. All-or-nothing NULL check on TG_ARGV | ✓ |

**Note:** The trigger-body researcher suggested `jsonb_strip_nulls`, which would allow partial keys. It was overruled in favor of all-or-nothing.

## Trigger body + benchmark (CAP-06)

| Option | Description | Selected |
|--------|-------------|----------|
| FOR loop over TG_ARGV, `to_jsonb` computed once | 0.94–1.01x of baseline (PG 14.17 scratch benchmark) | ✓ |
| `jsonb_object_agg(unnest(TG_ARGV))` | +14–17% (one SPI statement per row) | |
| Single-arg fast path + loop | No measurable gain | |
| Per-table functions read TG_ARGV | One code path | ✓ |
| Inline PK literals into per-table bodies | Forces migrate-time CREATE FUNCTION | |
| New in-server A/B bench + recorded run (not a CI gate) | Bar: ≤ 1.10x of the median. Sensitivity control about 2x | ✓ |
| Reuse `audit_capture_bench.exs` | Dominated by round-trips. Its delete scenario is broken | |

## Migrate-time validation (CAP-03, CAP-05, CONF-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Mask/exclude overlap checked at config (overrides) and in the DO block (detected PKs) | Earliest possible feedback | ✓ |
| Checked only in the DO block | Late feedback | |
| PK type allowlist, refuse the rest (HIGH-IMPACT) | Refuses `timestamptz`/`numeric`/float/json/array/bytea | ✓ |
| Denylist or warn-only | Allows silent empty history | |
| One DO block per table: resolve + validate + `CREATE OR REPLACE TRIGGER` | Verified on PG 14.17 | ✓ |
| Separate validation block + static trigger | Cannot carry catalog-derived args | |

## `primary_key:` override surface (CONF-01, HIGH-IMPACT)

| Option | Description | Selected |
|--------|-------------|----------|
| Config only | One declared identity for reads and writes | ✓ |
| Config + `--primary-key` CLI flag | Lost on regenerate. Invisible to reads | |
| Non-empty list, order kept for emission, set comparison | Deterministic SQL, no false drift | ✓ |
| Also accept a bare string or atom | Ambiguous for `"a,b"` | |
| Refuse the override on a table that has a PK (even when equal) | One rule | ✓ |
| Warn when equal | Silent drift | |
| Literal array in the DO block + exact qualifying-index check | Visible, no catalog cost per row | ✓ |
| Runtime read uses the same config loader | Required for CONF-01's read clause | ✓ |

**User's choice:** "auto follow ur recs". All recommendations were accepted.

## Claude's Discretion

- Helper names and module layout.
- The exact wording of error MESSAGE, DETAIL and HINT.
- The test file layout and the location of the fixture.
- Whether to reject unknown table-entry keys.
- The benchmark's row count.

## Deferred Ideas

- Widening the PK type allowlist (`timestamptz`, `numeric`).
- Capture for tables with no PK and no unique index.
