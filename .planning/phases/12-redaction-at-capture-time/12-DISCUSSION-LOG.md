# Phase 12: Redaction at capture time - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `12-CONTEXT.md`.

**Date:** 2026-04-23  
**Phase:** 12 — Redaction at capture time  
**Areas discussed:** Configuration surface; Mask placeholder semantics; Exclude + mask + `changed_from`; Trigger / function layout  
**Method:** User requested full-area coverage with parallel subagent research; architect synthesis produced locked recommendations (no interactive per-question log).

---

## Configuration surface

| Option | Description | Selected |
|--------|-------------|----------|
| A | CLI flags only for all policy | |
| B | Application `config/*.exs` as canonical policy | ✓ (primary) |
| C | Dedicated YAML/TOML policy file | Deferred |
| D | Hybrid: config primary + narrow CLI (`--tables`, dry-run, strict) | ✓ (operational) |

**User's choice:** Research-backed unified pick — **config primary** (matches `:verify_coverage` precedent), Mix task loads config, CLI scopes generation and ergonomics without a second full policy language.

**Notes:** Migrations remain the durable contract; no env/vault secrets in mask strings; `MIX_ENV` parity documented for CI.

---

## Mask placeholder semantics

| Option | Description | Selected |
|--------|-------------|----------|
| A | Single library default literal in SQL | ✓ (default) |
| B | Optional per-table override (static literal) | ✓ (optional extension) |
| C | Per-column placeholders | Deferred |
| D | Config-driven override with strict Elixir validation before emit | ✓ |

**User's choice:** Default constant + validated config override at codegen; symmetric application to `NEW`/`OLD` paths.

**Notes:** Avoid dynamic SQL inside triggers for placeholder text; PaperTrail/Audited/Logidze footguns cited as “new column / full snapshot” discipline — Threadline addresses at trigger layer.

---

## Exclude, mask, and `changed_from`

| Rule | Selected |
|------|----------|
| exclude ∩ mask | Hard error at codegen |
| Pipeline | Exclude keys first, then mask |
| `data_after` | Always post-process full-row JSON on INSERT/UPDATE |
| `changed_from` | Same mask/exclude semantics as `data_after` for OLD-derived values |
| json/jsonb columns | Whole-value replace with placeholder (document) |

**User's choice:** Explicit implementable invariants (subagent grounded in `trigger_sql.ex`); Carbonite `excluded_columns` vs filtered columns noted as analogue.

---

## Trigger / function layout

| Option | Description | Selected |
|--------|-------------|----------|
| A | Global function + branching / dynamic SQL | |
| B | Per-table functions for every audited table if any table has rules | |
| C | Per-table only when non-default (redaction and/or `store_changed_from`) | ✓ |
| D | Shared SQL helper + thin per-table wrappers | ✓ (implementation strategy under C) |

**User's choice:** Opt-in per-table functions (same axis as Phase 9); refactor toward shared core to reduce three-way duplication.

---

## Claude's Discretion

Exact config key name; exact default placeholder string; whether `--dry-run` ships in initial PR.

## Deferred Ideas

See `<deferred>` in `12-CONTEXT.md` (YAML policy file, per-column tokens, Carbonite-style no-op updates, deep JSON redaction).
