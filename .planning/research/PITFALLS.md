# Pitfalls Research

**Domain:** Extending trigger-backed audit capture in PostgreSQL  
**Researched:** 2026-04-23  
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Breaking PgBouncer-safe capture

**What goes wrong:** New trigger logic introduces session assumptions or `SET LOCAL` in the hot path.  
**Why it happens:** Before-values tempt `SET` patterns or “cache” state across statements.  
**How to avoid:** Keep all new logic in statement-local trigger body using `OLD`/`NEW` only; continue GUC read-only pattern for actor.  
**Warning signs:** Code review mentions session, “connection-level” flags, or `SET LOCAL` inside `TriggerSQL`.  
**Phase to address:** Phase 9 (Before-values capture)

---

### Pitfall 2: NULL / type surprises for `changed_from`

**What goes wrong:** INSERT/DELETE paths accidentally populate `changed_from`; UPDATE with no row change edge cases; JSON serialization errors.  
**Why it happens:** PL/pgSQL `to_jsonb(OLD)` is easy; semantics vs `changed_fields` alignment is not.  
**How to avoid:** `changed_from` only on UPDATE when option enabled; integration tests for INSERT/DELETE unchanged; document nil vs `{}` policy explicitly.  
**Warning signs:** Tests only cover happy-path single-column update.  
**Phase to address:** Phase 9

---

### Pitfall 3: `verify_coverage` lying in CI

**What goes wrong:** Task checks wrong schema, wrong table list, or passes when triggers point to stale function definition.  
**Why it happens:** Mix task runs without app env or uses defaults that do not match deployed tables.  
**How to avoid:** Require explicit `:repo` or connection config; align with `Health.trigger_coverage/1` semantics; document CI recipe.  
**Warning signs:** Green CI but production missing triggers.  
**Phase to address:** Phase 10 (Verify + doc contracts)

---

### Pitfall 4: Backfill creates false audit history

**What goes wrong:** Synthetic rows look like real captures; compliance teams misread timelines.  
**Why it happens:** Pressure to “have something” in `audit_changes` for old rows.  
**How to avoid:** Explicit marker (`op`, dedicated flag, or separate baseline event) and docs; never silently invent pre-audit mutations.  
**Warning signs:** Helper named “backfill” without documented semantics.  
**Phase to address:** Phase 11 (Backfill / continuity)

---

### Pitfall 5: Doc contract tests that do not compile real snippets

**What goes wrong:** Tests strip context so examples drift from README.  
**Why it happens:** Over-mocking or partial extraction.  
**How to avoid:** Treat README excerpts as compile-checked modules or use `Code.string_to_quoted!` with imports aligned to README.  
**Warning signs:** Tests pass while README `mix` commands are wrong.  
**Phase to address:** Phase 10

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Runtime-only `store_changed_from` flag | Faster first PR | Hard to see from migrations what is enabled | Prefer gen-time option for v1.2 |
| verify_coverage without JSON output | Simpler | Hard to parse in larger monorepos | OK if human table is primary; revisit for machines later |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|-------------------|
| Multi-schema apps | Only search `public` | Respect `search_path` / configurable schema list in task |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Full-row `changed_from` on very wide tables | Table bloat, slow vacuum | Document + optional future column filter | Wide JSON-heavy rows at high churn |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| PgBouncer regression | Phase 9 | Integration tests + trigger SQL review checklist |
| NULL semantics | Phase 9 | INSERT/UPDATE/DELETE matrix in tests |
| verify_coverage accuracy | Phase 10 | Fixture DB missing trigger → non-zero exit |
| Backfill honesty | Phase 11 | Docs + test that synthetic rows are distinguishable |
| Doc drift | Phase 10 | CI fails when README API changes |

## Sources

- Threadline `PROJECT.md` prior-art notes (Logidze, ExAudit, Audited)
- `trigger_sql.ex` implementation review

---
*Pitfalls research for: Threadline v1.2*  
*Researched: 2026-04-23*
