# Phase 11: Backfill / continuity - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **TOOL-02**: a documented **brownfield / continuity** path so operators can enable Threadline capture on **tables that already contain rows** without the library implying **fabricated pre-trigger** history (see `.planning/REQUIREMENTS.md`).

**In scope:** Honest **T₀** semantics, operator entrypoints (Mix + programmatic), how this interacts with **`audit_transactions` / `audit_changes`** and **`Threadline.history/3`**, documentation split (README vs guide), and **automated tests** for at least one brownfield scenario (roadmap SC1–SC3).

**Out of scope:** WAL/CDC, full row-level backfill of “who changed what” before capture existed, retention/redaction, optional **in-audit-stream** marker rows (reserved `op` / new columns) unless a later milestone explicitly scopes them — v1.2 default path does **not** require them.

</domain>

<decisions>
## Implementation Decisions

### T₀ and baseline semantics (reconciled with prior art)

- **D-01 (canonical T₀):** **Strict empty mutation log until the first real trigger-fired row change** on that audited table after capture is installed. **`Threadline.history/3` returns `[]` for a PK until the first post-install `INSERT` / `UPDATE` / `DELETE` that the capture trigger records.** This is the honest story: the database cannot prove **who** changed **what** before capture existed.
- **D-02 (SC3 / moduledoc alignment):** **`AuditChange` rows remain exclusively trigger-generated** for real row lifecycle events (`insert` / `update` / `delete` per existing trigger contract). **No default library path** inserts `AuditChange` rows from Elixir (or migrations pretending to be app DML) that **look identical** to those captures. This preserves `Threadline.Capture.AuditChange` moduledoc truth and roadmap SC3.
- **D-03 (continuity / compliance snapshots):** Operators who need a **point-in-time baseline** artifact (e.g. compliance “state at go-live”) get it **outside `audit_changes`**: documented patterns — **export** (SQL `COPY`, logical dump slice, app-owned JSON), or an **application-owned** table — with explicit wording that this is **not** retroactive audit. **Do not** ship a default “fake first INSERT” snapshot into `audit_changes` (known bad pattern from PaperTrail-style misuse and violates honesty).
- **D-04 (deferred / non-default future):** A **distinguishable in-stream marker** (reserved `op`, `capture_kind`, or similar) **plus** optional `AuditAction`, all written in a **single explicit DB transaction**, is a **valid industry pattern** (Debezium snapshot vs incremental; append-only **BASELINE** events) but **not** the v1.2 default. If product later demands one-store continuity, plan it as an **explicit opt-in** with schema/API work, `history/3` filter semantics, and migration-generated SQL — not as the first shipped path.

### `audit_transactions` linkage and ordering

- **D-05:** **Do not** attach “baseline” meaning by **piggybacking** synthetic rows onto the **next unrelated business transaction** (weak causality, surprising `history/3` and `action_id` groupings). **Do not** create **orphan** or **empty** `audit_transactions` rows solely as a marker — Threadline’s trigger path already creates `audit_transactions` when real writes occur; keep that invariant.
- **D-06:** **Idempotency:** Any Mix/module “continuity” helper must be **safe to re-run** (detect already-enabled / already-documented cutover, log skip reason, exit 0 unless `--strict` validation fails). Guard against **double baselines** if optional metadata tables are added later (unique constraints on `(schema, table_name)` cutover rows).
- **D-07 (PgBouncer / GUC discipline):** Any optional future “adoption transaction” work that sets `actor_ref` must use the **same transaction-scoped GUC patterns** as capture (no new session coupling). Brownfield **documentation** should mention **one explicit `BEGIN…COMMIT`** for any operator-run SQL bundle.

### Operator surface (Mix + modules)

- **D-08:** **Primary human path:** new **`mix threadline.…`** task in the same family as `install`, `gen.triggers`, `verify_coverage` — strong **`@shortdoc`**, **`@moduledoc`**, **`mix help` discoverability**, and **HexDocs “Mix tasks”** group entry alongside siblings.
- **D-09:** **Primary programmatic path:** a **public application module** (name TBD in plan, e.g. `Threadline.Capture.Cutover` or `Threadline.Continuity`) implementing all semantics — accepts **`repo:`** and explicit options; **thin Mix** only parses argv and delegates. Matches **Oban**-style (runtime API + installer tasks) and avoids **“Mix-only”** traps for **releases** (`bin/app eval`), seeds, and umbrellas.
- **D-10:** Support **`--dry-run` / `--explain`** where the task would otherwise perform or recommend writes — print intended steps/SQL; default to safe, copy-paste-disciplined messaging (staged “inspect → act” in docs).
- **D-11:** **Idempotent messaging** consistent with `threadline.install` (already-installed → clear skip + hint), with explicit lines that **no pre-trigger history** will appear in `audit_changes`.

### Documentation architecture

- **D-12:** **Canonical operational narrative** for brownfield lives in **one versioned guide** under `guides/` with a **stable filename** (planner picks final name, e.g. `guides/brownfield-continuity.md`) — **single anchor** linked from README, Mix `@moduledoc`, and `guides/domain-reference.md`. **Add that file to `mix.exs` `docs: extras`** when authored so it appears in HexDocs next to `domain-reference.md`.
- **D-13:** **README** stays **trust + discovery**: 3–6 bullets on what Threadline **does and does not** promise for brownfield; **minimal** safe quickstart; **one prominent link** to the guide — no full option matrix or hazardous copy-paste blocks in README.
- **D-14:** **Warnings** live **adjacent to the lever** (Mix task moduledoc, function that would confuse if misused) **and** a short “read first” box at the top of the guide; avoid duplicating five paragraphs — **link to one subsection**.

### Testing expectations (from roadmap / requirements)

- **D-15:** Integration test: **fixture DB** where a table has rows **before** triggers exist → install capture → assert **no** `audit_changes` for a stable PK until a controlled post-install mutation; then assert **normal** invariants on `audit_changes` / `audit_transactions` (shape, FK, ops).
- **D-16:** Tests must prove the **empty baseline** (or, if a future opt-in marker exists, **distinguishable** behavior) — for v1.2 ship **empty-path** proof first.

### Claude's Discretion

- **Exact** Mix task name (`threadline.continuity` vs `threadline.capture_cutover` vs other), **exact** public module name and option keys, whether a **minimal DB registry table** for cutover metadata ships in v1.2 or **doc-only + optional SQL recipes** suffice for TOOL-02 closure — planner chooses smallest artifact that still meets D-01–D-03 and test bar.
- **Whether** to add a **small first-party metadata table** vs **doc-only** sidecar: trade **DX** (query “when was capture enabled?”) against **migration surface**; either is coherent if D-01–D-02 hold.

### Folded Todos

_None._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — TOOL-02
- `.planning/ROADMAP.md` — Phase 11 goal and success criteria (SC1–SC3)
- `.planning/PROJECT.md` — v1.2 vision, Path B, honest audit, OSS quality bar

### Prior phase context

- `.planning/phases/09-before-values-capture/09-CONTEXT.md` — `changed_from`, trigger-only semantics, no `SET LOCAL` beyond existing GUC read
- `.planning/phases/10-verify-coverage-doc-contracts/10-CONTEXT.md` — `verify_coverage`, doc contracts; explicitly defers TOOL-02 to Phase 11

### Capture contract

- `.planning/milestones/v1.0-phases/01-capture-foundation/gate-01-01.md` — Path B trigger choice
- `lib/threadline/capture/audit_change.ex` — moduledoc: trigger-created rows
- `lib/threadline/capture/trigger_sql.ex` — capture function and transaction grouping
- `lib/threadline/capture/migration.ex` — `audit_*` DDL
- `lib/mix/tasks/threadline.install.ex`, `lib/mix/tasks/threadline.gen.triggers.ex` — existing Mix patterns

### Research

- `.planning/research/SUMMARY.md` — architecture context

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Mix.Tasks.Threadline.*`** — argv, `Mix.raise`, app/repo boot patterns to mirror for a new task.
- **`Threadline.Health.trigger_coverage/1`** — optional cross-link in docs (“verify triggers after cutover”).
- **`Threadline.history/3`**, **`Threadline.Query`** — consumers assume listed `AuditChange` rows are real captures; empty list is valid and honest.

### Established patterns

- **Explicit `repo:`** on APIs — public continuity module must follow suit.
- **Trigger-only `AuditChange`** — strongest invariant for Phase 11.

### Integration points

- **`mix threadline.install` / generated migrations** — any optional metadata table would extend install or a dedicated migration generator.
- **`mix.exs` `docs: extras`** — add new guide path when file exists.

</code_context>

<specifics>
## Specific Ideas

Discussion synthesized **parallel research** (baseline semantics, Mix vs module API, `audit_transactions` linkage, documentation split) with explicit **reconciliation**: strict-empty **`audit_changes`** until first real mutation (honest gap) wins over default synthetic baseline rows in `audit_changes` because of **SC3** and **`AuditChange` moduledoc**; **sidecar / doc-only** baseline for compliance; **thin Mix + fat public module** for DX; **README tease + single `guides/` anchor** for progressive disclosure.

</specifics>

<deferred>
## Deferred Ideas

- **In-stream adoption markers** (reserved `op`, `capture_kind`, dedicated `AuditAction`) — valid later opt-in; not v1.2 default (see D-04).
- **Optional first-party cutover registry table** — planner decides vs doc-only (see Claude's Discretion).

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 11-backfill-continuity*
*Context gathered: 2026-04-23*
