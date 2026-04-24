# Phase 25: Correlation-aware timeline & export - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **25-CONTEXT.md**.

**Date:** 2026-04-24
**Phase:** 25 — Correlation-aware timeline & export
**Areas discussed:** Filter semantics (`action_id` null), String validation, Export payload shape, Integration test strategy
**Mode:** User requested **all** areas + parallel subagent research; lead agent synthesized one coherent recommendation set (no conflicting branches left open).

---

## Filter semantics when `:correlation_id` is set

| Option | Description | Selected |
|--------|-------------|----------|
| A — Strict inner join / EXISTS to AuditAction | Exclude rows whose transaction has no linked action or non-matching correlation | ✓ |
| B — Include null `action_id` | OR uncorrelated capture into filtered set | |
| C — Separate scope flag | e.g. `:correlation_scope` strict vs orphans | deferred |

**User's choice:** **A** — locked by LOOP-01 text and reinforced by OTel-style “no link = not in correlated set,” CloudTrail-style honest narrowing, lowest surprise for `correlation_id: "x"`.
**Notes:** Conditional join only when filter present; document empty result sets as “no changes linked to an AuditAction with this correlation.”

---

## String handling for `:correlation_id`

| Option | Description | Selected |
|--------|-------------|----------|
| A — Reject bad values | ArgumentError for type/empty/length | ✓ (composite) |
| B — Treat empty as nil | widen query | |
| C — Trim then validate | ✓ as part of A | ✓ |
| D — Pass-through to SQL | | |

**User's choice:** **Trim (UTF-8), then ArgumentError if empty after trim or >256 UTF-8 bytes; binary type required when key present.** No NFC/NFD by default.
**Notes:** Avoids footgun where `""` matches zero rows while user meant “no filter”; aligns with strict key philosophy in `Threadline.Query`.

---

## Export payload (correlation visible on row)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Always extend JSON + CSV | | |
| B — Filter only | | |
| C — Optional extended CSV, additive JSON | | ✓ (hybrid) |
| D — Other split | | |

**User's choice:** **Additive JSON** (`correlation_id`, `action_id` / nested `action`); **default CSV unchanged**; **opt-in trailing columns** for extended metadata.
**Notes:** Same filter vocabulary should yield self-describing exports for support tickets; CSV stability preserved for ETL.

---

## Integration tests

| Option | Description | Selected |
|--------|-------------|----------|
| Single parity + validation | One JSON id-set parity + validate_timeline_filters test | ✓ |
| Full CSV+JSON matrix | | |
| Split modules only | | |

**User's choice:** **validate_timeline_filters!/1** test for new key + errors; **one** **timeline vs `to_json_document`** sorted-id parity with `:correlation_id`; **CSV** exercised with correlation on at least one path (extended or dedicated smaller test); **no** golden snapshots; **no** `Ecto.Query` struct equality.
**Notes:** JSON chosen for parity assertion to avoid RFC4180/column-order coupling; CSV format remains covered by existing export tests.

---

## Claude's Discretion

- EXISTS vs JOIN implementation detail; JSON nesting shape; exact extended CSV option name.

## Deferred Ideas

- Optional “include orphans” correlation scope — future phase if ever required.
