# Phase 31: Field-level change presentation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`31-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 31 — Field-level change presentation  
**Areas discussed:** Module placement; JSON shape; missing `changed_from` semantics; INSERT/DELETE; mask parity; deterministic ordering  

**Mode:** User selected **all** gray areas; **six parallel subagent research** passes; **one-shot cohesive synthesis** into context (no per-turn interactive menus).

---

## Module & entrypoint placement

| Option | Description | Selected |
|--------|-------------|----------|
| `Threadline.ChangeDiff` (canonical) | Sibling to Export/Query; pure projection | ✓ |
| `Threadline.Query` nested | Mixes fetch and serialize | |
| `Threadline` only | Poor Hexdocs surface long-term | |
| Optional `Threadline` `defdelegate` | Discoverability only | ✓ (optional, minimal) |

**User's choice:** All areas + trust cohesive recommendation set.  
**Notes:** Aligns with Oban/Waffle-style capability modules; Phase 32 keeps Query for listing.

---

## JSON shape contract

| Option | Description | Selected |
|--------|-------------|----------|
| Primary: `schema_version` + `field_changes[]` | String keys, sorted entries, integrator-friendly | ✓ |
| `:export_compat` / `to_export_change_map` | Matches `Threadline.Export` `change_map/1` triple | ✓ |
| Raw triple only | Minimal bytes; pushes merge to every client | (secondary) |

**Notes:** String keys match `change_map/1`; avoid atom-default public maps; document `schema_version` vs export document `format_version`.

---

## Missing / sparse `changed_from` (UPDATE)

| Option | Description | Selected |
|--------|-------------|----------|
| Bare `prior: null` only | Ambiguous vs SQL null | |
| Row `before_values` enum + no invented scalars | Honest epistemic state | ✓ |
| Per-field `prior_state` when sparse gaps | When distinct from capture-off | ✓ (documented matrix) |

---

## INSERT / DELETE

| Option | Description | Selected |
|--------|-------------|----------|
| INSERT: snapshot + empty `field_changes` | Default truth | ✓ |
| INSERT: optional `expand_insert_fields` | Derived “set” entries | ✓ (opt-in) |
| DELETE: row removal only | No pre-image | ✓ |
| DELETE: synthetic field removes | Misleading without stored before | |

---

## Mask / redaction parity

| Option | Description | Selected |
|--------|-------------|----------|
| Pass-through from `%AuditChange{}` only | Parity with export/timeline | ✓ |
| Re-apply policy in Elixir | Drift risk | (defer / non-default) |

**Notes:** **`changed_fields`** drives UPDATE keys; respect mask + `except_columns` asymmetry.

---

## Deterministic ordering

| Option | Description | Selected |
|--------|-------------|----------|
| Lexicographic on field name | Matches SQL `ORDER BY n.key` | ✓ |
| Map iteration order | Flaky | |

---

## Claude's Discretion

Exact string values for closed enums; number of **`Threadline`** delegators after Phase 32.

## Deferred Ideas

- Synthetic diff from raw rows + Elixir policy (non-persisted).
- DELETE field-level removes when/if pre-image capture exists.
