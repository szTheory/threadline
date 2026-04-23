# Feature Research

**Domain:** Application-level audit / change-data capture for Elixir + Postgres teams  
**Researched:** 2026-04-23  
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Provable trigger install | Ops needs to know capture is actually on before trusting audits | LOW–MEDIUM | `Health.trigger_coverage/0` exists; CLI exit code for CI is the missing table stakes piece |
| Stable query shape for history | Support reads `history/2` and expects fields to mean the same thing across versions | MEDIUM | Additive `changed_from` must be `nil` when feature off — no breaking map keys for existing callers |
| Honest docs | README is the first “API” | LOW | Doc contract tests are standard in mature OSS Elixir libs |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Optional before-values on UPDATE | Compliance / support often need “what was it before?” without separate snapshots | MEDIUM–HIGH | Must not regress Path B correctness or pool safety |
| Brownfield backfill story | Most real apps add auditing late | HIGH | Define semantics clearly (e.g. synthetic baseline vs no false history) |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Before-values on every column always | “Just capture everything” | Storage + PII duplication | Opt-in per table / column list in a later iteration; v1.2 starts with boolean `store_changed_from` |
| Automatic retention in same release | “Disk is filling” | Wrong failure mode for first audit release; needs policies + batching | Dedicated RETN milestone |

## Feature Dependencies

```
verify_coverage (TOOL-01)
    └──requires──> stable trigger naming / function contract (already shipped)

Doc contract tests (TOOL-03)
    └──requires──> stable public API modules referenced in README

changed_from (BVAL-01/02)
    └──requires──> migration adding column + TriggerSQL branch for UPDATE
                       └──enhances──> history() / Query layer

Backfill helper (TOOL-02)
    └──requires──> clear AuditChange invariants
    └──conflicts-with──> implying pre-audit history exists without an explicit baseline story
```

### Dependency Notes

- **BVAL before misleading TOOL-02:** Backfill docs and helper should reference the capture schema as it exists after BVAL column lands (even if `changed_from` is null).

## MVP Definition (this milestone slice)

### Launch With (v1.2)

- [ ] Optional `store_changed_from` + `changed_from` persisted for UPDATE when enabled  
- [ ] `Threadline.history/3` returns `changed_from` when column populated  
- [ ] `mix threadline.verify_coverage` with CI-friendly exit status  
- [ ] Doc contract tests for documented code paths  
- [ ] Documented backfill / continuity helper API (exact shape TBD in plan-phase)

### Add After Validation (later)

- [ ] Column-level include/exclude for `changed_from` — when storage/PII audits demand it  
- [ ] Retention / redaction / export — separate milestones  

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| verify_coverage CLI | HIGH | LOW | P1 |
| changed_from optional | HIGH | MEDIUM | P1 |
| Doc contract tests | MEDIUM | LOW | P2 |
| Backfill helper | MEDIUM | HIGH | P2 |

## Competitor Feature Analysis

| Feature | Carbonite / PaperTrail-style | Our Approach |
|---------|------------------------------|--------------|
| Old values | Varies; often app-layer | Trigger `OLD` snapshot into JSONB when opted in |
| “Is auditing on?” | Often manual | Health module + forthcoming Mix task for CI |

## Sources

- Archived `.planning/milestones/v1.0-REQUIREMENTS.md` § v2 (BVAL/TOOL)
- Prior art notes in `PROJECT.md` Context

---
*Feature research for: Threadline v1.2*  
*Researched: 2026-04-23*
