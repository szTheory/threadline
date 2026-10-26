# Phase 227: DB-Backed Property Tests - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-01
**Phase:** 227-db-backed-property-tests
**Areas discussed:** Redaction leak oracle (PROP-04), as_of replay oracle (PROP-06), Retention boundary oracle (PROP-07), Shared harness / mutation evidence / budget

**Mode:** The maintainer asked for research followed by one recommendation, with no questions ("one-shot a perfect set of recommendations so i dont have to think"). Four `gsd-advisor-researcher` agents ran in parallel, one per area, and each verified its claims against the code. Three of them also ran local probes, and each confirmed `lib/` was left untouched. Claude reconciled the four reports into the decisions in CONTEXT.md. No AskUserQuestion was asked.

---

## Redaction leak oracle (PROP-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Raw hostile values only | Reuse 226 hostile generator; substring search | |
| Canary-only | Exact search, narrow value space | |
| Canary wrapped in hostile shapes + structural-only specials + positive controls | Escape-proof canary, structural rules, marker/count controls | ✓ |
| Detection: byte search only / structural only / both | | both + positive controls ✓ |
| Export via real DB entry points + chunked path | vs `format_changes_iodata` over read-back structs (not viable) | ✓ |

**Choice:** D-07 to D-13.
**Conflict resolved:** the harness agent proposed an invisible-sentinel wrapper, and the redaction agent proposed an ASCII canary. The ASCII canary was chosen because its bytes stay the same through JSON escaping and CSV quoting.
**Notable:** one mutant (L401, excluded-column change detection) survives the current suite. It is now a mutation control, and D-13 closes the gap with an example test.

## as_of replay oracle (PROP-06)

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Real mutations + in-memory row model | End-to-end capture+as_of, independent oracle | ✓ |
| (B) Synthetic AuditChange rows, `max_by({captured_at,id})` oracle | Reaches ties, but restates the SQL (Pitfall 3) | |
| (C) Both | B half carries the tautology | |
| Ties: pin / fix with `seq` column / uuidv7 | | pin ✓ (fix deferred to v1.45) |

**Choice:** D-14 to D-17.
**Conflict resolved:** the harness agent suggested (B) with generated-rank ids. That was rejected as tautological. The `ordered_id` helper is kept only for the tie example test.
**Probe:** 9,001 real same-row captures produced 0 ties, with a 38 µs minimum gap.

## Retention boundary oracle (PROP-07)

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Dry-run count + real purge: id sets, byte-identical survivors, dry==real | Oracle from generated facts; catches one-site patches | ✓ |
| (B) Extract shared eligible-changes query | 226 D-01 trap: the mutant flips both sides | |
| (C) Dry-run count only | Survivor check vacuous | |
| Orphaned transactions + small batch sizes in scope | | ✓ |
| resolve_cutoff boundary as a property | Clock moves; flaky | ✗ (example tests instead) |

**Choice:** D-18 to D-22.
**Defect found:** the dry-run transaction count misses the transactions the purge itself orphans. The decision (D-20) is a one-line `fix:` under the D-25 rule, and the maintainer can veto it at plan review.

## Shared harness / mutation evidence / budget

| Option | Description | Selected |
|--------|-------------|----------|
| Key created in the body + per-iteration `after` cleanup | Shrink-safe; exact whole-table oracles | ✓ |
| Generated key / clean once in on_exit / rollback | Collisions, stale rows, hides capture | |
| Plain-function helper module `DbProperty` | vs self-contained copies / CaseTemplate | ✓ |
| `db(20)` for all, measure first; default shrinking steps | | ✓ |
| Harden 226 mutation script in place (awk `[[:space:]]`) | vs unchanged / copy | ✓ |
| Defect gate (fix only if small, reversible, no shape/SQL/migration change) | vs always pin / always fix | ✓ |

**Choice:** D-01 to D-06 and D-23 to D-27.

## Claude's Discretion

- Helper names and arity, `describe` layout, plan and wave split, and whether PROP-04 uses multi-statement transactions.

## Deferred Ideas

- Causal ordering column (`seq` or uuidv7) for `audit_changes`, for v1.45.
- Redaction fails open on misnamed `exclude:`/`mask:` columns. This is a security backlog item to raise with the maintainer.
- Numeric precision loss and timestamptz rendering in `data_after` (capture fidelity).
- `create_trigger/3` direct-API redacted-PK guard gap; the untested global redacted function.
- Items carried from 226: export nil defaults, CSV formula injection, muex, and the weights refresh.
