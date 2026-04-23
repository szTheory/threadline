# Feature Research

**Domain:** Audit platform for Elixir/Phoenix/Ecto/PostgreSQL
**Researched:** 2026-04-22
**Confidence:** HIGH — based on deep domain model reference, ecosystem analysis, and prior-art lessons from Carbonite, PaperTrail, ExAudit, Logidze, django-auditlog, Ruby Audited, and JaVers

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features any serious audit library must provide. Missing these makes the product feel broken or untrustworthy.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| INSERT/UPDATE/DELETE capture | Core audit promise — "what changed?" | MEDIUM | PostgreSQL trigger-backed; must capture all writes, not just app-layer calls |
| Before/after values per row | Diff view requires it; debugging requires it | MEDIUM | `data_after` + `changed_fields` + optional `changed_from` columns |
| Changed fields list | Operators need to know which fields flipped, not just that a row changed | LOW | Captured at trigger time; avoids full-row payload diffs |
| Row identity preservation | After a delete, operators still need to identify what was deleted | LOW | `table_pk` as normalized identity; identity labels in subject refs |
| Timestamps on every record | "When did this happen?" is the first question anyone asks | LOW | `occurred_at` on `AuditTransaction`; `captured_at` on `AuditChange` |
| Actor tracking | "Who did this?" is the second question | MEDIUM | `ActorRef` model; not just a user FK — must support jobs/system/anonymous |
| SQL-queryable storage | Operators must be able to use plain SQL without Elixir helpers | LOW | JSONB + typed columns; no Erlang binary terms, no YAML |
| Migration helpers | Without these, installation is friction-heavy | LOW | `mix threadline.install` + `mix threadline.gen.triggers` |
| Basic query API | Without Elixir-level queries, adoption stalls | MEDIUM | Resource history, actor history, timeline — the minimal useful query surface |
| Hex package with docs | OSS adopters expect this; no Hex package = not a real library | LOW | `threadline`; `mix hex.docs`; README with working example |

### Differentiators (Competitive Advantage)

These are what make Threadline different from every existing Elixir audit library. Carbonite owns row-change correctness; PaperTrail/ExAudit own ergonomics. Threadline must own both *plus* the semantic layer — that combination is the gap in the ecosystem.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| AuditAction semantic layer | "What did the user *do*?" not just "what rows changed?" — Carbonite has no action model; PaperTrail conflates write with action | HIGH | `AuditAction` entity: name, verb, category, status, actor_ref, subject_refs, reason, correlation |
| First-class ActorRef model | All competitor libs collapse actor to a user FK; this fails for jobs, system, admin, anonymous | MEDIUM | `actor_type` enum + `actor_id`; supports impersonation; is a value object, not an FK |
| Correlation IDs across async boundaries | Job context routinely lost in ExAudit (ETS/PID), Logidze (connection-local); this is the core async footgun in every competitor | HIGH | `correlation_id` + `request_id` + `job_id` on `AuditContext`; explicit Oban helper |
| Trigger coverage health checks | No existing Elixir lib surfaces "this table has no trigger" as a first-class diagnostic | MEDIUM | `mix threadline.verify_coverage`; detects uncovered tables; surfaced as structured health check |
| Capture layer / semantics layer separation | Collapsing them is how prior art created gaps (PaperTrail misses Repo calls; ExAudit misses direct SQL) | HIGH | `AuditTransaction` ≠ `AuditAction`; `AuditChange` ≠ `AuditAction`; they are linked, not merged |
| Oban job helper | Background job context is a first-class concern, not an afterthought | MEDIUM | `Threadline.Job` helper: binds actor, correlation, job metadata; survives async boundaries |
| Reason / comment on actions | "Why did this happen?" is an operator need none of the Elixir libs address | LOW | `reason` atom + optional `comment` string on `AuditAction` |
| Telemetry instrumentation | SREs need counters/gauges without manual wiring | LOW | `:telemetry` events at transaction open/commit, change capture, action record, health check |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| WAL/CDC backend | Captures even direct-SQL writes without triggers | Requires logical replication, raises wal_level (cannot revert on some clouds), PgBouncer hazards, infra dependency — incompatible with "batteries-included" v0.x promise | PostgreSQL trigger-backed capture handles 95%+ of the correctness need without CDC operational surface area |
| Process-local / ETS audit context | ExAudit's model feels simple | Context silently disappears across async tasks, Oban workers, Task.async, GenServers — source of subtle bugs in production | Explicit context structs passed through function arguments or `Threadline.Context.current/0` backed by process dictionary with warning when context is absent |
| Association tracking (has_many etc.) | PaperTrail had it; teams want full object graphs | Added enormous complexity, was eventually extracted to a separate gem; deeply entangles capture with app schema assumptions | Keep v0.1 focused on row-level changes; association traversal is a query-layer concern, not a capture concern |
| LiveView operator UI in v0.1 | Operators want a UI | Premature before the API surface is stable; adds `phoenix_live_view` dependency to the core lib; creates surface area before capture + semantics are proven | Defer to v0.2+; ensure the query API is rich enough to build a UI on top of |
| YAML / Erlang term serialization | Feels natural in Elixir | Ruby Audited's YAML approach caused years of upgrade pain; ExAudit's binary terms are unqueryable from SQL clients | JSONB for flexible fields; typed columns for fixed-shape fields |
| Automatic field exclusion via annotations | Schemas annotate `redact: true` on fields | Creates coupling between app schemas and the audit library; hard to apply to third-party schemas | Explicit redaction policy configuration; field-level exclusion config in `mix threadline.gen.triggers` |
| TRUNCATE capture | Complete capture — no gaps | PostgreSQL triggers do not fire on TRUNCATE by default; workarounds are expensive and fragile | Document TRUNCATE as an explicit gap; expose as a health check warning if TRUNCATE is used on audited tables |

---

## Feature Dependencies

```
[Trigger-backed capture]
    └──requires──> [PostgreSQL trigger installation] (mix threadline.gen.triggers)
    └──requires──> [AuditTransaction table] (mix threadline.install)
    └──requires──> [AuditChange table] (mix threadline.install)

[AuditAction semantics]
    └──requires──> [AuditContext propagation]
                       └──requires──> [ActorRef model]
                       └──requires──> [Plug integration OR Oban job helper]
    └──enhances──> [Trigger-backed capture] (links action_id to transactions)

[Correlation / async context]
    └──requires──> [AuditContext struct]
    └──enhances──> [Oban job helper] (propagates request → job)

[Trigger coverage health checks]
    └──requires──> [Trigger-backed capture]
    └──requires──> [mix threadline.install] (needs schema introspection tables)

[Basic query API]
    └──requires──> [Trigger-backed capture]
    └──enhances──> [AuditAction semantics] (richer timeline when linked)

[Telemetry]
    └──requires──> [Trigger-backed capture] (to have events to emit)

[Redaction / field masking] ──deferred v0.2──> [Trigger-backed capture]
[Retention / purge] ──deferred v0.2──> [Trigger-backed capture]
[Export sinks] ──deferred v0.2──> [AuditAction semantics]
[LiveView operator UI] ──deferred v0.2+──> [Basic query API]
```

### Dependency Notes

- **AuditAction requires AuditContext propagation:** An action without actor/context is just a label. Context propagation (Plug helper, Oban helper) must ship alongside the semantics layer.
- **Correlation requires AuditContext struct:** The correlation ID lives on `AuditContext`; you cannot do async tracing without it.
- **Trigger coverage health checks require install:** The health check queries PostgreSQL system catalogs (`pg_trigger`) to compare against the expected trigger list; this means the schema introspection logic must be packaged with `mix threadline.install`.
- **Query API enhances AuditAction:** The query API works on capture alone, but it becomes much more useful when action links are present — `get_actor_history` can return semantic action names instead of raw row diffs.

---

## MVP Definition

### Launch With (v0.1)

Minimum viable product — what's needed to validate correctness + basic semantics in a real Phoenix app.

- [ ] **Trigger-backed capture** — INSERT/UPDATE/DELETE into `audit_changes` linked to `audit_transactions`; captures `data_after`, `changed_fields`; JSONB storage
- [ ] **`mix threadline.install`** — creates `audit_transactions` and `audit_changes` tables with correct indexes
- [ ] **`mix threadline.gen.triggers`** — installs triggers on specified tables; supports column exclusion
- [ ] **ActorRef model** — `actor_type` + `actor_id` value object; covers user, admin, service_account, job, system, anonymous
- [ ] **Plug integration** — `Threadline.Plug` extracts actor/request context; binds to `AuditContext`; propagates to DB via session variable (PgBouncer-safe pattern)
- [ ] **AuditAction recording** — `Threadline.record_action/2` for semantic events; `name`, `actor_ref`, `reason`, `correlation_id`; links to `AuditTransaction`
- [ ] **Oban job helper** — `Threadline.Job` module for propagating actor/correlation into background workers
- [ ] **Basic query API** — `Threadline.history(schema, id)`, `Threadline.actor_history(actor_ref)`, `Threadline.timeline/1` with basic filters
- [ ] **Trigger coverage health check** — `Threadline.Health.trigger_coverage/0`; surfaces uncovered audited tables
- [ ] **Telemetry events** — `:threadline, :transaction, :committed`, `:threadline, :action, :recorded`, `:threadline, :health, :checked`
- [ ] **README + domain reference** — 15-minute install guide; domain language glossary; CONTRIBUTING skeleton
- [ ] **CI pipeline** — GitHub Actions with `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all`

### Add After Validation (v0.1.x)

Features to add once v0.1 is used in at least one real app and the API surface is stable.

- [ ] **`store_changed_from` / before-values** — trigger option to capture previous field values; needed for true diff views; adds storage cost, so validate demand first
- [ ] **`mix threadline.verify_coverage`** — CLI-level trigger coverage report; extends health check into developer workflow
- [ ] **Backfill helper** — safe way to introduce auditing to an existing table without losing history continuity
- [ ] **Doc contract tests** — README code examples validated by test assertions; keeps docs honest

### Future Consideration (v0.2+)

Features to defer until the capture + semantics layer is proven in production.

- [ ] **Redaction / field masking** — `RedactionPolicy` with exclude/mask/hash modes; requires stable data model before applying
- [ ] **Retention + purge** — `RetentionPolicy`; scheduled purge jobs; legal hold; defer because premature retention deletes are unrecoverable
- [ ] **Export sinks** — CSV/JSON export, Oban-backed outbox; defer until query API is stable
- [ ] **LiveView operator UI** — timeline browser; action detail; actor view; defer until capture + semantics are validated
- [ ] **As-of snapshot reconstruction** — `Threadline.as_of(schema, id, datetime)`; complex to implement correctly; high value but low urgency for v0.1
- [ ] **Multi-tenant prefix scoping** — Ecto prefix support; defer until base capture is validated
- [ ] **Audit-of-audit** — tracking who viewed or exported audit data; very high-trust environments only

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Trigger-backed INSERT/UPDATE/DELETE capture | HIGH | MEDIUM | P1 |
| `mix threadline.install` + `mix threadline.gen.triggers` | HIGH | LOW | P1 |
| ActorRef model | HIGH | LOW | P1 |
| Plug integration for request context | HIGH | LOW | P1 |
| AuditAction semantic recording | HIGH | MEDIUM | P1 |
| Oban job helper | HIGH | MEDIUM | P1 |
| Basic query API (history/timeline) | HIGH | MEDIUM | P1 |
| Trigger coverage health check | MEDIUM | LOW | P1 |
| Telemetry events | MEDIUM | LOW | P1 |
| Correlation ID propagation | HIGH | MEDIUM | P1 |
| `store_changed_from` (before-values) | MEDIUM | MEDIUM | P2 |
| `mix threadline.verify_coverage` CLI | MEDIUM | LOW | P2 |
| Backfill helper | MEDIUM | HIGH | P2 |
| Doc contract tests | MEDIUM | MEDIUM | P2 |
| Redaction / field masking | HIGH | HIGH | P2 |
| Retention + purge | MEDIUM | HIGH | P2 |
| Export sinks (CSV/JSON/outbox) | MEDIUM | HIGH | P3 |
| LiveView operator UI | HIGH | HIGH | P3 |
| As-of snapshot reconstruction | MEDIUM | HIGH | P3 |
| Multi-tenant prefix scoping | MEDIUM | MEDIUM | P3 |
| Audit-of-audit | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for v0.1 launch
- P2: Should have, add post-v0.1 validation
- P3: Nice to have, future consideration (v0.2+)

---

## Competitor Feature Analysis

| Feature | Carbonite | PaperTrail (Elixir) | ExAudit | Our Approach |
|---------|-----------|---------------------|---------|--------------|
| Trigger-backed capture | ✓ Yes | ✗ No (callback-based) | ✗ No (Repo hook) | ✓ Yes — core correctness guarantee |
| Captures direct Repo/SQL writes | ✓ Yes | ✗ No | ✗ No | ✓ Yes — inherits from trigger approach |
| Actor / whodunnit | Partial (metadata on transaction) | ✓ Yes (originator) | ✓ Yes (context) | ✓ Yes — typed ActorRef with multiple actor types |
| Actor types beyond user | ✗ No | ✗ No | ✗ No | ✓ Yes — user/admin/service_account/job/system/anonymous |
| Semantic action events | ✗ No | ✗ No | ✗ No | ✓ Yes — AuditAction with name/verb/category/status |
| Async/job context propagation | ✗ Manual | ✗ Manual | Partial (ETS, fragile) | ✓ Yes — explicit Oban helper; correlation IDs |
| Correlation IDs | ✗ No | ✗ No | ✗ No | ✓ Yes — first-class on AuditContext |
| SQL-queryable storage | ✓ Yes (JSONB) | ✓ Yes | ✗ No (Erlang binary) | ✓ Yes — JSONB + typed columns, no opaque blobs |
| Before-values capture | ✓ Optional | ✓ Yes | ✓ Yes | ✓ Yes — `store_changed_from` option on triggers |
| Migration helpers | ✓ Yes | ✓ Yes | ✓ Yes | ✓ Yes — `mix threadline.install` + `mix threadline.gen.triggers` |
| Trigger coverage checks | ✗ No | N/A | N/A | ✓ Yes — health check + CLI verify |
| Telemetry | ✗ No | ✗ No | ✗ No | ✓ Yes — `:telemetry` events |
| Reason / comment | ✗ No | ✓ Yes (meta) | ✓ Yes (meta) | ✓ Yes — first-class `reason` + `comment` |
| Retention / purge | ✓ Partial (outbox) | ✗ No | ✗ No | P2 (v0.1.x+) |
| Field redaction | ✗ No | ✗ No | ✗ No | P2 (v0.1.x+) |
| Operator UI | ✗ No | ✗ No | ✗ No | P3 (v0.2+) |
| Export sinks | ✓ Partial (outbox) | ✗ No | ✗ No | P3 (v0.2+) |

---

## Sources

- `prompts/audit-lib-domain-model-reference.md` — primary domain model, entities, bounded contexts, personas, JTBD, footguns
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem analysis; Carbonite, PaperTrail, ExAudit, Logidze, django-auditlog, Ruby Audited, JaVers, Audit.NET prior-art lessons
- `prompts/THREADLINE-GSD-IDEA.md` (via PROJECT.md) — project vision, constraints, out-of-scope decisions, key prior-art lessons (PgBouncer, ETS context, YAML storage, association tracking)
- Carbonite v0.16.x library (ecosystem context from prior-art doc)

---

*Feature research for: Threadline — audit platform for Elixir/Phoenix/Ecto/PostgreSQL*
*Researched: 2026-04-22*
