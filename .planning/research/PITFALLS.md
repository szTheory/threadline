# Pitfalls Research

**Domain:** Elixir audit platform — PostgreSQL trigger-backed capture + application-level action semantics
**Researched:** 2026-04-22
**Confidence:** HIGH (informed by documented prior-art failures in Logidze, ExAudit, Carbonite, Ruby Audited, PaperTrail; cross-referenced with Elixir/Ecto/PostgreSQL ecosystem patterns)

---

## Critical Pitfalls

### Pitfall 1: PgBouncer Transaction Pooling Kills Session-Local Metadata

**What goes wrong:**
PostgreSQL `SET LOCAL` / `SET` (session variables) are the natural way to propagate actor/context metadata into triggers. Under PgBouncer in **transaction pooling mode** (the default for most cloud deployments), the connection is returned to the pool after each transaction. Session variables set before a transaction are gone by the time the next one starts — and worse, they may bleed into an unrelated session. Triggers read stale or incorrect actor data, producing silently wrong audit records.

**Why it happens:**
Most trigger-backed audit libraries (Logidze, papercups-based approaches) use `pg_catalog.set_config` or `SET LOCAL audit.actor = ...` as a cheap way to thread context through to the trigger without changing the DB schema. This works perfectly under Ecto's default connection ownership model in tests and simple deployments but silently breaks under PgBouncer transaction pooling — which is exactly the production configuration teams adopt for scale.

**How to avoid:**
Design context propagation around the **transaction** as the unit, not the session. Preferred patterns:
- Write actor/context metadata into `audit_transactions` from the application side before or during the transaction (explicit insert, not a connection variable).
- If using `SET LOCAL`, document clearly that this **only works with session pooling** and assert in the install guide that transaction pooling is incompatible unless the PgBouncer `server_reset_query` workaround is in place.
- Provide a `Threadline.Repo` wrapper or `Ecto.Multi` integration that inserts context as a first step in every audited transaction, making the approach pooler-agnostic.

**Warning signs:**
- Integration tests pass but audit records in staging/production are missing actor data or show the wrong actor.
- Audit records are correct in dev (where PgBouncer is absent) but wrong in production.
- Test suite passes because ExUnit's sandbox owns a dedicated connection.

**Phase to address:**
Phase 1 (capture layer design) — the propagation mechanism must be chosen before trigger infrastructure is built, because it determines schema shape.

---

### Pitfall 2: Process-Local Context Stores Break in Async Elixir

**What goes wrong:**
Storing audit context in `Process.put/get` or an ETS table keyed by PID works in synchronous request pipelines but fails silently when work is spawned via `Task.async`, `Task.Supervisor`, `GenServer.cast`, Oban jobs, or Phoenix channels. The spawned process has no access to the parent's dictionary, so captures either miss the actor entirely or crash trying to read missing context.

**Why it happens:**
ExAudit uses a PID-scoped context store. It's a natural Elixir pattern for request-scoped state, and it works for the happy path. The failure mode only appears under async dispatch, which is common in Phoenix applications (background tasks, LiveView async assigns, Oban).

**How to avoid:**
- Do **not** use `Process.put` or ETS-keyed-by-PID for audit context.
- Accept context explicitly as a parameter at all boundaries: `Threadline.with_context(ctx, fn -> ... end)` wrapping an `Ecto.Multi` or a `Repo.transaction`.
- For Oban jobs, inject `AuditContext` via job args or metadata at enqueue time; reconstruct at the job boundary — do not rely on the enqueuing process's context surviving into the worker.
- Document the expected handoff pattern for each integration surface (Plug, Phoenix, Oban, LiveView).

**Warning signs:**
- Audit records from background jobs have nil/anonymous actors even though the job was triggered by a known user action.
- Context works in controller actions but not in `Task.async_stream` pipelines.

**Phase to address:**
Phase 2 (semantics layer) — the `AuditContext` propagation API must encode this constraint, not leave it to callers to figure out.

---

### Pitfall 3: Triggers Don't Automatically Track Schema Changes

**What goes wrong:**
Triggers are installed once against specific tables. When a migration adds a column to an audited table, the trigger still fires — but whether it captures the new column depends on how the trigger was written. If the trigger captures `row_to_json(NEW)` or `to_jsonb(NEW)`, new columns are captured automatically. If it uses explicit column lists (for filtering or performance), the new column is silently omitted. Worse: if a column is dropped and the trigger still references it by name, the migration fails or the trigger errors at runtime.

**Why it happens:**
Database triggers are decoupled from the Ecto migration lifecycle. There's no automatic mechanism in PostgreSQL to invalidate or re-verify triggers when schema changes occur.

**How to avoid:**
- Use `row_to_json(NEW)` / `to_jsonb(NEW)` in the trigger body — capture the whole row, let the application layer filter what to display.
- Provide a `mix threadline.check` task that validates installed triggers match the current schema and warns on drift.
- In `mix threadline.gen.triggers`, emit a comment in the migration explaining that schema changes to audited tables should be followed by `mix threadline.gen.triggers --check`.
- Test trigger behavior after `ALTER TABLE ADD COLUMN` and `ALTER TABLE DROP COLUMN` as part of the test suite.

**Warning signs:**
- A migration fails with an error referencing a trigger function.
- A new column appears in the UI but is absent from the audit history for that row.
- `mix threadline.check` (if built) reports mismatches after migrations run.

**Phase to address:**
Phase 1 (capture layer) — trigger generation strategy determines whether this pitfall exists at all.

---

### Pitfall 4: Conflating AuditTransaction with AuditAction (Conceptual Model Collapse)

**What goes wrong:**
If `AuditTransaction` and `AuditAction` are merged into one concept, the schema and API are forced to handle cases they can't:
- A DB transaction may produce zero actions (batch migration, scheduled cleanup).
- An action may span zero DB transactions (pure read, validation-only event).
- Multiple actions can share one transaction (a cascading update triggered by a parent record change).
- One action can span multiple transactions (a saga/workflow step).

Conflation forces a 1:1 assumption that is wrong in all four cases.

**Why it happens:**
The natural instinct in an Ecto-centric world is "I called Repo.transaction, therefore there's one action." Prior-art libraries (ExAudit, PaperTrail) made this conflation and accumulated workarounds for every edge case that violated the assumption.

**How to avoid:**
- Maintain the strict model: `AuditTransaction` is a DB-level concept (groups row mutations in one RDBMS transaction). `AuditAction` is an application-level concept (groups intent + actor across any number of transactions or none).
- Allow `AuditAction` to be linked to many `AuditTransaction` records, or to none.
- Never use the DB transaction ID as the action ID.
- Encode this as a first-class foreign key relationship: `audit_transactions.action_id nullable -> audit_actions.id`.

**Warning signs:**
- You find yourself adding `is_background_job` or `is_manual_migration` boolean flags to `AuditTransaction`.
- API consumers ask "how do I mark this transaction as not an action?" — that's the conflation smell.

**Phase to address:**
Phase 1 and Phase 2 design — the schema must encode the separation before either layer is built.

---

### Pitfall 5: Actor Model Collapse (Everything Is a User)

**What goes wrong:**
When `ActorRef` is modeled as a simple `user_id` integer foreign key, the following actors become unrepresentable or require hacks:
- **Admin impersonating a user** — who is the actor? (Answer: both, with different roles)
- **Service account / API key** — has no user row
- **Background job** — Oban worker, mix task, scheduler
- **System** — internal trigger, cascade, default value enforcement
- **Anonymous** — unauthenticated request that still changes data

The result is nullable `user_id`, a proliferation of `actor_type` enums that conflict, and queries that break whenever a new actor type is introduced.

**Why it happens:**
Most audit libraries were designed for user-facing web apps where the actor is always `current_user`. The first three "special cases" are usually handled with `nil` and `metadata` blobs. By the time the fourth appears, the model is irretrievably ad hoc.

**How to avoid:**
- Model `ActorRef` as a **polymorphic value type**, not a foreign key: `{type: :user, id: 42}`, `{type: :job, id: "oban:worker:123"}`, `{type: :system}`, `{type: :anonymous, fingerprint: "..."}`.
- Store as a JSONB column `actor` on `audit_transactions` and/or `audit_actions`, not as an integer FK.
- Provide typed constructors: `ActorRef.user(id)`, `ActorRef.job(worker, id)`, `ActorRef.system()`, `ActorRef.anonymous()`.
- Do **not** add a `users` FK constraint that prevents non-user actors.

**Warning signs:**
- `actor_id` is nullable but the field is called `user_id`.
- Tests skip actor assertions because "it's a background job."
- A new actor type requires a schema migration.

**Phase to address:**
Phase 2 (semantics layer schema) — lock `ActorRef` shape before publishing any API surface.

---

### Pitfall 6: audit_changes Table Becoming a Write Bottleneck

**What goes wrong:**
Every INSERT, UPDATE, and DELETE on every audited table appends rows to `audit_changes`. In high-write applications (bulk imports, event processing, batch jobs), the `audit_changes` table becomes the most-written table in the database. This causes lock contention, index bloat (especially on the `table_name` + `record_id` index), and VACUUM pressure.

**Why it happens:**
The central append table model is correct for audit correctness, but it concentrates write load. Applications that don't write heavily in dev/staging are surprised by this in production under load.

**How to avoid:**
- Design `audit_changes` with autovacuum tuning recommendations in the install docs (lower `autovacuum_vacuum_scale_factor`, higher `autovacuum_vacuum_cost_delay`).
- Partition `audit_changes` by time (monthly or weekly) from the start — backfilling a partition scheme onto a hot table is painful. Use PostgreSQL declarative partitioning (`PARTITION BY RANGE (inserted_at)`).
- Include a `mix threadline.gen.partition` task or document the SQL in the setup guide.
- Allow per-table capture toggles so high-volume tables (event logs, sessions) can be opted out selectively.

**Warning signs:**
- VACUUM runs become long-running and block queries.
- `pg_stat_user_tables` shows `audit_changes` with dead tuple count growing faster than VACUUM can handle.
- Replication lag increases on replicas serving the audit table.

**Phase to address:**
Phase 1 (capture layer schema) — partitioning is a schema design decision that cannot be retrofitted without downtime. Document as a recommended install option.

---

### Pitfall 7: JSONB Schema Drift in `changed_data`

**What goes wrong:**
`changed_data` JSONB columns start clean but accumulate historical quirks: column renames mean old records use `old_name` and new records use `new_name`. Column type changes (e.g., integer → UUID) produce heterogeneous data. Deleted columns leave orphaned keys in old records. Consumers write code assuming a stable shape and then break on historical data.

**Why it happens:**
JSONB is deliberately schema-less. This is its strength (no migration needed when schema changes) and its pitfall (callers must handle schema evolution). Most audit libraries don't document how to handle this.

**How to avoid:**
- Capture the PostgreSQL table's schema version or a migration checksum alongside each `audit_changes` record so consumers can detect when the row was captured under a different schema.
- Document the column-rename pattern: application code that relies on `changed_data` must treat the field as a union of all historical shapes, not a fixed schema.
- Do NOT add a JSON Schema validator on write — it would reject valid old-shaped records when re-processing.
- Provide a helper `Threadline.Change.fetch_field(change, :column_name, aliases: [:old_name])` that handles known aliases.

**Warning signs:**
- A query like `audit_changes.changed_data->>'email'` returns nil for old records.
- Consumer code has `case changed_data["user_id"] || changed_data["account_id"] do` pattern multiplying.

**Phase to address:**
Phase 3 (exploration layer) — document the access pattern before building any query helpers, because helpers must account for this.

---

### Pitfall 8: Soft-Delete Tables Producing False "Delete" Audit Events

**What goes wrong:**
Tables that implement soft delete via `deleted_at` timestamp emit an UPDATE event (setting `deleted_at`) that the trigger captures correctly — but consuming code or display logic treats any UPDATE to `deleted_at` as a "deletion." This is the correct capture but incorrect semantic. The inverse also applies: hard-deleting a row on a soft-delete table when cleaning up old data produces a DELETE event that looks like a real deletion to the audit trail.

**Why it happens:**
The trigger correctly captures "what happened at the DB level." The semantic gap is between DB-level events and business-level events. PaperTrail had this problem extensively with Rails soft-delete gems (Paranoia, Discard).

**How to avoid:**
- Threadline's `AuditAction` layer is the right place to attach business semantics (`intent: "member.soft_deleted"`) that disambiguates from DB-level events.
- Document this as a known pattern in the guides: "If your table uses soft delete, use `AuditAction` to attach the correct business intent; do not rely on the trigger event type alone."
- Consider a `virtual_operation` field in `AuditChange` that can be overridden by the action layer (`:soft_delete`, `:restore`, `:hard_purge`).

**Warning signs:**
- Audit timeline shows a "deleted" event for a record that the user can still see (because it's soft-deleted, not gone).
- Support team is confused because the audit trail shows conflicting delete events.

**Phase to address:**
Phase 2 (semantics layer) — `AuditAction.intent` is the override mechanism. Document this pattern early.

---

### Pitfall 9: Migration Ordering Causes Trigger Installation Failures

**What goes wrong:**
`mix threadline.gen.triggers` generates migration files to install triggers. If a developer runs this before the target table's migration has run — or if the trigger migration is numbered earlier than the table creation migration (timestamp ordering) — the trigger installation fails with "relation does not exist."

**Why it happens:**
Ecto migrations are ordered by timestamp. If the trigger generation task is run at project setup time before all application tables exist, or if tables are created after triggers are attempted, ordering breaks.

**How to avoid:**
- `mix threadline.gen.triggers` should verify that the target table exists before generating the migration, and emit a clear error if it does not.
- Generate trigger migrations with timestamps that are 1 second after the table migration's timestamp (inspect the existing migration files to determine this).
- Document in `mix threadline.gen.triggers --help` that it must be run after all target table migrations exist.
- Add a preflight check in the generated migration that raises an informative error if the table is missing at run time.

**Warning signs:**
- `mix ecto.migrate` fails with "could not find trigger target table" in a fresh environment.
- CI migrations pass locally but fail in a clean environment because table creation order differs.

**Phase to address:**
Phase 1 (migration helpers) — the `mix threadline.gen.triggers` task must handle this.

---

### Pitfall 10: Testing Against Triggers Requires Real Database Transactions

**What goes wrong:**
ExUnit's `Ecto.Adapters.SQL.Sandbox` wraps each test in a transaction that is rolled back at the end. PostgreSQL triggers fire within the transaction — but if the test asserts on `audit_changes` rows before the transaction commits, the rows are visible. However, if any test uses `async: true` with the sandbox in shared mode, or if the trigger is defined on a table in a different schema than the sandbox's connection, trigger behavior is inconsistent across test runs.

**Why it happens:**
The sandbox works at the connection level. Triggers are DB-level. The interaction is well-defined but subtly breaks under `async: true` with shared-mode sandbox, or under tests that use multiple repos.

**How to avoid:**
- Use `Ecto.Adapters.SQL.Sandbox` in **ownership mode** (not shared mode) for trigger tests.
- Do not use `async: true` for tests that assert on `audit_changes` rows captured by triggers — the sandbox's ownership model makes the trigger-visible rows appear in a different connection's view.
- Provide a `Threadline.Test.Support` helper that wraps trigger assertions with the correct sandbox expectations.
- Document the testing model explicitly in `CONTRIBUTING.md`.

**Warning signs:**
- Trigger capture tests are flaky when `async: true` is enabled.
- Tests pass in isolation but fail when the full suite runs in parallel.
- `audit_changes` row count assertions fail intermittently.

**Phase to address:**
Phase 1 — write the test support module alongside the trigger infrastructure, not after.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Store actor as bare `user_id` integer FK | Simple joins, FK integrity | Breaks when non-user actors appear; requires migration to polymorphic model | Never — use JSONB `ActorRef` from day one |
| Use `SET LOCAL` for context propagation | Zero schema changes needed | Silently wrong under PgBouncer transaction pooling | Only if documenting this as an explicit limitation and providing an alternative |
| Capture all columns always (no column exclusion) | Simpler trigger logic | Captures passwords, tokens, PII that operators shouldn't see in audit records | OK for v0.1 if documented; add exclusion lists in v0.2 |
| Single `audit_changes` table without partitioning | Simpler schema | Write bottleneck under high volume; painful to add partitioning later | Acceptable for v0.1 if documented with a migration path in docs |
| Conflate transaction ID with action ID | One fewer join | All four conceptual cases (zero actions, multi-action, no-transaction) become unrepresentable | Never — the conceptual damage is irreversible |
| Skip column change filtering (capture all UPDATEs even if nothing changed) | Zero false-negatives | `audit_changes` fills with noise rows for timestamp-update-only writes | Acceptable in v0.1; add `changed_fields` guard in trigger in v0.2 |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| PgBouncer | Using `SET LOCAL` for metadata, assuming session pooling | Use explicit `audit_transactions` insert for metadata; document pooling requirements in install guide |
| Oban | Propagating audit context via caller process state | Inject context via Oban job args or metadata at enqueue time; reconstruct in job worker |
| Ecto.Multi | Not wrapping audit context in the multi's first step | Provide `Threadline.Multi.with_context(multi, ctx)` that prepends context insert as step 1 |
| Phoenix Plug | Setting context in controller assigns without bridging to Repo transaction | Provide `Threadline.Plug` that extracts context from conn and registers it for the transaction |
| Ecto Repo callbacks | Hooking `after_insert/after_update/after_delete` for audit | These run in the application, not the DB — they miss direct SQL writes; triggers are the correct layer |
| Multiple repos | Installing triggers and expecting cross-repo capture | Triggers fire in the repo that owns the connection; each repo must have its own context setup |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| No index on `audit_changes(table_name, record_id)` | Record history lookups are full table scans | Include this compound index in `mix threadline.install` | ~100k rows |
| No time-range index on `audit_changes(inserted_at)` | Date-range queries require sequential scans | Include partial index or range index in install | ~500k rows |
| Fetching full `changed_data` JSONB for list views | Large payloads for list queries | Use `SELECT id, table_name, operation, inserted_at` for lists; lazy-load `changed_data` on detail view | ~10k rows / page |
| No vacuuming tuning on `audit_changes` | Table bloat, VACUUM pressure, slow queries | Document autovacuum settings; recommend partitioning for high-volume tables | ~1M rows/day |
| Trigger per-column comparison in trigger body | Expensive trigger for wide tables | Use `OLD IS DISTINCT FROM NEW` for whole-row change detection; filter at read time | Tables with >50 columns |
| Synchronous audit writes in hot paths | Request latency increases as audit_changes grows | Accept synchronous writes as correct-by-default; document async-write tradeoffs if needed | Not a v0.1 concern |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Capturing password/token columns in `changed_data` | Audit log becomes a credential store; breach of audit trail exposes secrets | Document column exclusion list; in v0.2 add `exclude_columns` option to trigger generator |
| Granting INSERT on `audit_changes` to the application role | Application can tamper with audit records | `audit_changes` and `audit_transactions` should be INSERT-only from the trigger's definer role; application role gets SELECT only |
| No `audit_changes` immutability enforcement | Records can be updated or deleted, destroying the audit trail | Add a `BEFORE UPDATE OR DELETE` trigger on `audit_changes` that raises an exception |
| Storing PII in `actor` JSONB without a redaction path | Data subject deletion requests (GDPR) cannot be fulfilled without mutating audit records | Design `actor` with an `anonymized: true` flag from day one; document redaction as a v0.2 concern but make the flag a v0.1 schema field |
| Trusting application-supplied `actor` without validation | Actor can be spoofed by the application | Document that trigger-level context is as trustworthy as the application — this is application-level auditing, not a security boundary; users needing tamper-proof audit should layer on pgAudit |

---

## "Looks Done But Isn't" Checklist

- [ ] **Trigger coverage:** Verify triggers installed on ALL audited tables — `mix threadline.check` must report any tables in the schema that opted in but have no trigger installed.
- [ ] **PgBouncer safety:** Test context propagation with a PgBouncer instance in transaction pooling mode, not just direct Postgres.
- [ ] **Async context propagation:** Test Oban job audit capture; test `Task.async` spawned from a Phoenix controller.
- [ ] **Actor model completeness:** Verify all six actor types (user, admin, service account, job, system, anonymous) can be expressed and round-tripped through JSONB without data loss.
- [ ] **Immutability enforcement:** Verify that `UPDATE` and `DELETE` on `audit_changes` raise an error, not just "no rows affected."
- [ ] **Schema change resilience:** Run `ALTER TABLE ADD COLUMN` on an audited table; verify the new column appears in subsequent `audit_changes.changed_data` without any trigger reinstallation.
- [ ] **Rollback correctness:** Verify that a rolled-back `Repo.transaction` produces zero rows in `audit_changes`.
- [ ] **Nil change noise:** Verify that an `UPDATE` that sets no column to a new value (UPDATE users SET name = name WHERE id = 1) does NOT produce an `audit_changes` row (requires `OLD IS DISTINCT FROM NEW` guard in trigger).
- [ ] **Mix task idempotency:** `mix threadline.install` run twice must not fail or produce duplicate rows.
- [ ] **Documentation:** README states the PgBouncer constraint, the async context pattern, and the column exclusion limitation before v0.1 ships.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Actor stored as bare user_id (wrong model) | HIGH | Requires schema migration to JSONB actor column; backfill historical rows; update all queries; accept that historical non-user actor records are lost |
| PgBouncer metadata corruption (wrong actors) | MEDIUM | Switch context propagation mechanism; historical records with wrong actors cannot be corrected without knowing the correct actors from another source |
| Missing trigger on a table (gap in coverage) | LOW | Run `mix threadline.gen.triggers --table=foo`; no historical backfill possible for gap period |
| audit_changes without partitioning at high volume | HIGH | Requires table rebuild with partitioning; multi-hour downtime window or online partition migration tool |
| Passwords captured in changed_data | MEDIUM | Add column to exclusion list immediately; if breach risk is present, treat as security incident; cannot redact existing rows without mutating immutable audit records (document this tradeoff) |
| Conflated transaction/action model | HIGH | Requires API redesign, schema migration, and migration of historical data; all consumers must update |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| PgBouncer metadata corruption | Phase 1 (capture design) | Integration test with PgBouncer in transaction pooling mode |
| Process-local context store | Phase 2 (semantics API) | Test context propagation in `Task.async` and Oban jobs |
| Trigger schema drift | Phase 1 (trigger generator) | Test `ALTER TABLE ADD COLUMN` followed by trigger assertion |
| Transaction/action conflation | Phase 1+2 schema | Schema review: confirm separate `audit_transactions` and `audit_actions` tables with nullable FK |
| Actor model collapse | Phase 2 (ActorRef design) | All six actor types round-trip through JSONB without special casing |
| Write bottleneck | Phase 1 (schema design) | Document partitioning; add autovacuum tuning to install guide |
| JSONB schema drift | Phase 3 (exploration layer) | Document and test `fetch_field` with alias handling |
| Soft-delete false deletions | Phase 2 (semantics docs) | Document pattern; test AuditAction.intent override for soft-delete tables |
| Migration ordering failures | Phase 1 (mix task) | `mix threadline.gen.triggers` on table that doesn't exist returns clear error |
| Test sandbox incompatibility | Phase 1 (test support) | `async: true` trigger tests documented and either supported or explicitly prohibited |
| Security: credential capture | Phase 1 (trigger design) | Audit of trigger body for exclusion; add to v0.2 roadmap |
| Immutability enforcement | Phase 1 (schema) | Attempt UPDATE on audit_changes row; expect exception |

---

## Sources

- Logidze README and issue tracker — PgBouncer interaction documented as known limitation
- ExAudit GitHub — ETS/PID-scoped context documented in architecture; async issues raised by community
- Carbonite v0.16.x source — trigger design and Ecto.Multi integration patterns
- Ruby PaperTrail issue archive — association tracking complexity (reason it was eventually extracted)
- Ruby Audited CHANGELOG — YAML storage deprecation and JSONB migration
- PostgreSQL documentation — `SET LOCAL` scope, partitioning, trigger WHEN clauses, autovacuum parameters
- Ecto.Adapters.SQL.Sandbox docs — ownership mode vs. shared mode semantics
- PgBouncer documentation — session vs. transaction vs. statement pooling modes

---
*Pitfalls research for: Threadline — Elixir PostgreSQL trigger-backed audit platform*
*Researched: 2026-04-22*
