# Phase 190: Storage Schema Confidence and Host-Schema Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-01
**Phase:** 190-storage-schema-confidence-and-host-schema-truth
**Areas discussed:** Custom-schema proof bar, Ecto prefix contract, Migration identifier contract, Non-public host-table boundary

---

## Custom-Schema Proof Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal unit/source contracts | Fast contracts for `StorageSchema`, generated SQL strings, and trigger SQL; insufficient for proving DB behavior. | |
| Targeted real `audit` integration proof | Uses PostgreSQL schema isolation and sentinel rows to catch hardcoded-prefix bugs. | |
| Broad operator/example E2E proof | Useful smoke for user-visible paths; too broad/flaky as primary proof. | |
| Layered proof | Combines source contracts, real `audit` DB integration, and narrow operator smoke. | ✓ |

**User's choice:** User selected all gray areas and asked for subagent-backed one-shot recommendations so they would not need to choose manually.
**Notes:** Advisor research recommended layered proof. Source contracts are necessary for SQL/identifier shape, but real PostgreSQL `audit` integration is the gate. Browser/example proof is optional release confidence, not the core authority.

---

## Ecto Prefix Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Global config only | Simple configure-once operator story; poor per-call isolation and can hide missing plumbing. | |
| Per-call override only | Explicit and easy to test; too noisy and surprising for normal Phoenix installs. | |
| Global default plus per-call override | Normal adopters configure once; tests and advanced callers can override explicitly. | ✓ |
| Remove fixed owned schema prefixes | Required implementation step because Ecto query prefix fallback does not override `@schema_prefix`. | ✓ |

**User's choice:** User delegated to the research-backed recommendation.
**Notes:** Advisor research and official Ecto docs converge: query `prefix:` is a fallback when schemas declare `@schema_prefix`, while schema writes can behave differently. Fixed `@schema_prefix "threadline"` creates a split-brain risk under `storage_schema: "audit"`.

---

## Migration Identifier Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Fully quote all validated identifiers | Aligns runtime and generated SQL, avoids case-folding/search-path surprises, supports existing validator shape. | ✓ |
| Lowercase-only supported contract | Simpler SRE story but narrows current public behavior and still needs careful validation/docs. | |
| Ecto.Migration DSL/prefix rewrite | Idiomatic for table/index DDL where possible, but incomplete for functions/triggers/raw SQL. | |

**User's choice:** User delegated to the research-backed recommendation.
**Notes:** Advisor research recommended quoting every validated storage identifier while recommending lowercase snake_case for humans. Ecto.Migration prefix helpers may be future cleanup, but Phase 190 must fix raw SQL.

---

## Non-Public Host-Table Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| First-class support across all surfaces immediately | Best eventual trust story but larger blast radius if interpreted as all-schema/global scanning. | |
| Document public-only surfaces | Fast, but conflicts with existing schema-aware trigger/coverage pieces and weakens adoption trust. | |
| Explicit phased support with tests | Support `support.tickets` across named schema-aware surfaces, keep defaults public, avoid all-schema polling. | ✓ |

**User's choice:** User delegated to the research-backed recommendation.
**Notes:** The codebase is already partially host-schema-aware. The recommendation is to make explicit schema-qualified identity work across trigger generation, coverage, redaction drift, timeline filtering, and continuity readiness, while documenting any duplicate row-history limitation honestly.

---

## Claude's Discretion

- Exact test/module organization.
- Whether a given path uses SQL shape assertions, sentinel rows, or both.
- Whether a small operator LiveView/controller smoke is enough after DB integration proof.
- Exact copy changes, provided they stay operator/JTBD focused and avoid Ecto-prefix jargon.

## Deferred Ideas

- Broad all-schema polling.
- Full Ecto.Migration DSL rewrite.
- Broad browser/example matrix as primary proof.
- Per-request multi-tenant Threadline storage routing.
- Full duplicate host-table row-history disambiguation if it proves too broad for Phase 190.
