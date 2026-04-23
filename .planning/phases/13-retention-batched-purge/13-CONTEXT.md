# Phase 13: Retention & batched purge - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators bound audit table growth with a **documented retention model** (RETN-01) and a **safe, repeatable batched purge** (RETN-02): configurable batch size, idempotent re-runs, explicit behavior for `audit_transactions` vs `audit_changes`, and operator docs (cron, monitoring). Out of scope: export (phase 14), capture-time redaction (phase 12), legal-hold / pause hooks (defer unless product explicitly schedules), WAL/CDC.

</domain>

<decisions>
## Implementation Decisions

### Retention clock (“expired” definition)

- **D-01 — Primary expiry field is `AuditChange.captured_at`:** Eligibility for purge is based on **per-change** capture time in the database (`timestamptz`), not `AuditTransaction.occurred_at`. This matches `Threadline.Query.timeline/1` and `history/3`, which filter and order on `captured_at` — one clock for API, runbooks, and purge.

- **D-02 — Document edge cases explicitly:** Long transactions can produce **multiple** `captured_at` values under one `txid`; retention is row-level, not “whole txn expires as one instant” unless a later phase adds that policy. Cutoff construction uses **DB-consistent** time (e.g. parameter bound in SQL); document inclusive/exclusive semantics relative to `timeline(:from / :to)` so operators do not get off-by-one surprises.

- **D-03 — `occurred_at` is secondary:** Use `AuditTransaction.occurred_at` for **transaction-scoped** APIs (`actor_history/2`, ordering), not as the default RETN-01 knob. If triggers are ever aligned so `occurred_at` reflects true commit semantics, that remains **documentation / future txn-granular policy** unless explicitly replanned.

### Policy scope (RETN-01)

- **D-04 — v1.3 default is a single global window:** One documented retention interval applied to all `audit_changes` rows (same relation Threadline owns). Minimizes config matrix, test surface, and operator surprise (“we keep row-level audit for N days”).

- **D-05 — Extension path without breaking shape:** Purge implementation accepts a **resolved policy struct** or optional predicate hook so **per-table** (and later per-tenant) overrides can layer on the **same** delete primitive without a second job implementation. v1.3 may only pass the global window; do not ship per-table in v1.3 unless plan explicitly pulls it in.

- **D-06 — Defer per-schema and per-tenant retention** until capture carries stable, query-efficient discriminators and product need justifies the policy matrix.

- **D-07 — Policy lives in application config:** Same family as Phase 12 — `config :threadline, …` (and `runtime.exs` in releases). Document resolution order once (global default → future overrides). Avoid hidden `Repo` or magic `Application.get_env` inside hot loops; resolve once per job invocation.

### `audit_transactions` after change purge

- **D-08 — Default: remove empty parent rows:** After batched deletion of eligible `audit_changes`, run a **batched second pass** (or coordinated end-of-batch step) to delete `audit_transactions` that have **no remaining** `audit_changes`. Rationale: FK is `audit_changes.transaction_id REFERENCES audit_transactions(id) ON DELETE CASCADE` (parent delete removes children, not the reverse); child-only purge **otherwise leaves orphans**, which inflate `actor_history/2` and contradict “change-backed audit” mental model.

- **D-09 — Optional compat flag:** `delete_empty_transactions: false` (or equivalent) for transitional brownfield only; default **`true`**. Document inconsistency if disabled.

- **D-10 — Batch transaction boundaries:** Prefer **short** transactions per batch (changes pass, then parents pass, or documented interleaving) — avoid one long transaction for the whole retention run to limit lock contention with capture inserts.

### Operator surface & DX (RETN-02)

- **D-11 — Canonical implementation is a public API:** e.g. `Threadline.Retention.purge/1` (exact module name for planner) taking **required** `repo:` plus `batch_size`, cutoff / policy reference, optional `dry_run:`, `max_batches:`, returning a **structured summary** (`%{deleted_changes:, deleted_transactions:, batches:, …}`) for tests, Oban, and IEx.

- **D-12 — Thin Mix task delegates to that API:** e.g. `mix threadline.retention.purge` — mirror patterns from `Mix.Tasks.Threadline.Gen.Triggers` and `VerifyCoverage`: `Mix.Task.run("app.config", [])`, resolve repo (multi-repo override flag), `Application.ensure_all_started` / repo start as needed, argv for `--batch-size`, `--dry-run`, `--max-batches`, optional cutoff override that **only tightens** retention vs config (see D-14).

- **D-13 — Oban/cron should call the API, not spawn Mix per tick:** Mix for human runbooks, bootstrap, CI; application workers use the module to avoid boot cost and ease secrets.

- **D-14 — Conservative defaults in prod:** Require explicit configuration to enable destructive purge in production **or** a documented `--execute` / `--force` gate so a mis-copied staging cron cannot empty prod silently.

- **D-15 — Observability:** Emit structured logs (or optional `:telemetry` events) per batch: cutoff used, rows deleted, scope label (`:global`), duration — operators debug from logs.

### Claude's Discretion

- Exact module/task names and config key path (`:retention` vs nested under existing keys); choice between CTE vs subquery for batched deletes on target PostgreSQL versions; whether `dry_run` returns SQL or counts-only in v1.3.

### Folded Todos

_None._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — RETN-01, RETN-02
- `.planning/ROADMAP.md` — Phase 13 goal and success criteria (docs, multi-batch tests, referential behavior)

### Prior phase context

- `.planning/phases/12-redaction-at-capture-time/12-CONTEXT.md` — Config idioms, Mix + explicit `repo`, operator docs expectations

### Capture and query contracts

- `.planning/milestones/v1.0-phases/01-capture-foundation/gate-01-01.md` — Path B, PgBouncer-safe capture (purge is ops-layer but must not undermine operator trust in the same deployment story)
- `lib/threadline/query.ex` — `timeline/2` filters on `captured_at`; `actor_history/2` on `AuditTransaction`
- `lib/threadline/capture/audit_change.ex` — Schema fields and semantics
- `lib/threadline/capture/audit_transaction.ex` — Relationships
- `priv/repo/migrations/20260101000000_threadline_audit_schema.exs` — FK `ON DELETE CASCADE` direction (parent delete removes children)

### Mix task precedents

- `lib/mix/tasks/threadline.gen.triggers.ex` — `app.config`, `MIX_ENV` expectations
- `lib/mix/tasks/threadline.verify_coverage.ex` — Repo resolution and application startup for DB tasks

### Operator docs (update in implementation phase)

- `README.md` — Cross-link retention/purge when shipped
- `guides/domain-reference.md` — Retention semantics alongside domain model

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Threadline.Query`** — `timeline/2` already uses `captured_at` filters; purge should stay aligned.
- **Mix tasks** under `lib/mix/tasks/threadline.*` — Established patterns for config load and DB access.
- **`audit_changes_captured_at_idx`** — Supports retention predicates on `captured_at` without full table scan when used correctly.

### Established patterns

- **Explicit `repo:`** on public APIs (`Threadline.Query`) — retention API must match.
- **Codegen / ops split** — Phase 12: policy in config + Mix; Phase 13: retention policy in config + Mix + public purge module.

### Integration points

- Host **`config/*.exs`** and optional **Oban** worker calling the public purge API.
- **PostgreSQL** — Set-based batched `DELETE`; index-friendly predicates.

</code_context>

<specifics>
## Specific Ideas

Parallel research synthesis (2026-04-23): Prior art (Audited/PaperTrail, Carbonite, Logidze, Rails/Laravel/Django CLI patterns) consistently favors **row-level or insert-time clocks** for TTL-style pruning unless the product is explicitly transaction-centric; **thin CLI + fat library module** matches Ecto’s Migrator vs `mix ecto.*` split; **orphan transaction shells** are a common footgun when only child rows are pruned — default parent cleanup keeps `actor_history` honest; **global-first retention** reduces matrix bugs while preserving a **predicate-shaped** API for per-table later.

</specifics>

<deferred>
## Deferred Ideas

- **Legal / compliance holds** — pause or exempt rows from automated purge; app-layer or future phase.
- **Per-table / per-tenant retention policies** — extension on same purge primitive (D-05); not default v1.3 unless scoped in plan.
- **Whole-transaction-or-nothing expiry** — hybrid clock rules; only if legal/product mandates.
- **Deep integration with export (phase 14)** — “export then purge” playbooks documented cross-phase.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 13-retention-batched-purge*  
*Context gathered: 2026-04-23*
