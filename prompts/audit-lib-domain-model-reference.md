# Audit Library Domain Model Reference

_Status: working design brief for product, API, UI, and operations_

## 0) Executive summary

We are not merely building “a UI on top of row-change capture.” We are building a **batteries-included audit platform for Phoenix/Ecto/PostgreSQL**.

The product should combine:

1. **Canonical row-change capture** — hard to bypass, trustworthy, complete.
2. **Action semantics** — who did what, why, in what request/job/session/context.
3. **Excellent exploration** — timelines, diffs, filters, as-of queries, exports, related-events navigation.
4. **Operational confidence** — health checks, retention, redaction, telemetry, coverage checks, upgrade ergonomics.

The likely technical posture is:

- **Carbonite-style trigger-backed capture** as the system of record for database changes.
- A **first-class app-level action/context model** for meaning.
- A **query/UI/operator layer** that makes the system pleasant to live with.

---

## 1) Product thesis

### One-line thesis

> The best audit library for Elixir is the one that is hardest to get wrong, easiest to understand, and easiest to operate.

### Design principles

- **Correct by default**: it should be harder to miss audit capture than to get it right.
- **Context-rich**: row changes alone are not enough; user intent and execution context matter.
- **SQL-native**: operators should be able to inspect and query the data without bespoke decoding magic.
- **Happy-path first**: the 80% case should require almost no ceremony.
- **Escape hatches**: advanced teams need redaction, partitions, exports, and fine-grained policy.
- **Operationally legible**: if capture is degraded, the system should tell you loudly and clearly.
- **Composable**: good Plug/Phoenix/Ecto ergonomics; good background-job ergonomics; good LiveView ergonomics.

### Non-goals

- Not a SIEM.
- Not a full event-sourcing framework.
- Not a replacement for database statement auditing like pgAudit.
- Not primarily a data warehouse change-history product.
- Not tied only to compliance; should also be genuinely useful for support, debugging, and product operations.

---

## 2) Mental model

The domain has **three layers** that should be modeled separately.

### A. Capture layer

Records **what rows changed**.

Questions it answers:

- What table/row changed?
- Which fields changed?
- What was the resulting state?
- What transaction grouped these changes?

### B. Semantics layer

Records **what action happened**.

Questions it answers:

- What user/system/job/operator action occurred?
- Why did it happen?
- Was it interactive, scheduled, or system-initiated?
- Which resources were affected conceptually?

### C. Exploration/operations layer

Makes it usable.

Questions it answers:

- Can I find all changes related to request X or user Y?
- Can I diff the object over time?
- Can I export all activity for tenant Z?
- Is the system healthy, complete, and retaining data correctly?

### Core stance

Do **not** force one primitive to do all three jobs.

- A **change** is not the same thing as an **action**.
- A **transaction** is not the same thing as a **request**.
- A **user** is not always the **actor**.
- A **timeline entry** in the UI may be synthesized from multiple lower-level records.

---

## 3) Ubiquitous language (canonical nouns)

This section defines the terms the library should use consistently in code, docs, UI, and examples.

### Core nouns

#### Audit Transaction
A grouping unit for one database transaction’s audited changes.

Represents:
- one DB transaction,
- optional metadata,
- the canonical parent of one-or-many row changes.

Not necessarily the same as a request or action.

#### Audit Change
A captured mutation of one row in one audited table.

Represents:
- table identity,
- row identity,
- operation kind (`insert`, `update`, `delete`),
- resulting data,
- optional previous values / changed-from info,
- changed field list.

#### Audit Action
A semantic event representing something meaningful at the application level.

Examples:
- `user.invited`
- `member.role_changed`
- `invoice.refunded`
- `api_key.revoked`
- `job.retry_requested`

An action may:
- map to many row changes,
- map to one row change,
- map to zero row changes (for example read-side or administrative actions).

#### Actor
The principal responsible for the action.

Possible actor kinds:
- human user,
- admin,
- support agent,
- service account,
- background job,
- system automation,
- anonymous/public,
- external integration.

#### Subject / Resource
The domain object conceptually affected.

Examples:
- `account`,
- `organization`,
- `member`,
- `invoice`,
- `project`,
- `deployment`,
- `api_key`.

A subject is a **reference**, not necessarily an Ecto schema instance.

#### Request
A user- or API-initiated request boundary.

May carry:
- request ID,
- path/route,
- method,
- remote IP,
- user agent,
- session info,
- auth method,
- tenant,
- origin application.

#### Job
A background execution boundary.

May carry:
- job ID,
- worker/module name,
- queue name,
- attempt number,
- scheduler source,
- parent request/correlation ID.

#### Correlation
An identifier that ties together related records across boundaries.

Used for:
- request tracing,
- job chains,
- external integrations,
- multi-step workflows,
- exports and incident investigation.

#### Reason
A human-meaningful explanation for why an action happened.

Examples:
- `user_request`
- `admin_override`
- `fraud_review`
- `backfill`
- `migration`
- free-text comment: “customer requested account merge”

#### Evidence
Optional extra material that improves explainability.

Examples:
- raw params snapshot,
- policy evaluation result,
- support ticket ID,
- incident ID,
- approval reference,
- external webhook event ID.

#### Timeline Entry
A view-model concept for the UI.

A timeline entry may represent:
- one action,
- one transaction,
- one change,
- a synthesized grouping of related records.

This should **not** be the same thing as a storage model.

#### Snapshot
A reconstructed object state at a point in time.

#### Diff
A human-readable representation of what changed.

#### Redaction Rule
A policy that hides or filters sensitive fields.

#### Retention Policy
Rules for how long audit data is kept and when it is archived or purged.

#### Coverage
A notion of what is and is not under audit.

Examples:
- which tables have triggers,
- which contexts are propagated,
- which routes/actions are instrumented,
- which exports are healthy.

#### Audit Stream / Export Sink
A downstream consumer of audit data.

Examples:
- webhook,
- Kafka topic,
- S3 bucket,
- SIEM,
- data warehouse,
- internal outbox consumer.

---

## 4) Bounded contexts

### 4.1 Capture context

**Responsibility:** canonical persistence of row mutations.

Owns:
- audit transaction creation,
- table trigger registration/config,
- change persistence,
- change-field filtering,
- row identity representation,
- low-level integrity constraints.

Does not own:
- semantic action naming,
- UI grouping,
- authorization for viewing,
- retention policy business decisions.

### 4.2 Context/semantics context

**Responsibility:** identity, intent, request/job provenance, and action meaning.

Owns:
- actor binding,
- tenant binding,
- request/job binding,
- action naming and taxonomy,
- reason/comments,
- correlation IDs,
- extra metadata attachment.

### 4.3 Exploration context

**Responsibility:** query language, filters, projections, timelines, as-of reconstruction, diffing, search, export surfaces.

Owns:
- timeline views,
- object histories,
- actor histories,
- request/correlation drill-down,
- CSV/JSON exports,
- bookmarks/saved views.

### 4.4 Operations context

**Responsibility:** running the system safely.

Owns:
- health checks,
- retention runs,
- purge jobs,
- redaction rollout,
- export delivery status,
- telemetry/metrics,
- coverage checks,
- upgrade/migration checks.

### 4.5 Policy context

**Responsibility:** who can see what and how data is transformed.

Owns:
- field masking,
- row-level access to audit data,
- tenant isolation,
- export restrictions,
- retention by data class,
- legal hold / immutable-hold modes.

---

## 5) Core entities and value objects

This is the recommended conceptual model. It does not imply a specific table layout, but it should shape the public API.

### 5.1 AuditTransaction

**Purpose:** canonical grouping of row changes created in one DB transaction.

**Identity**
- `transaction_id`
- `transaction_xact_id` or equivalent DB transaction identity

**Fields**
- `occurred_at`
- `actor_ref`
- `tenant_ref`
- `context_ref`
- `action_ref` (optional but desirable)
- `kind` / `type`
- `source` (`request`, `job`, `system`, `migration`, `backfill`, `console`)
- `meta` (JSONB)
- `schema_partition` / `prefix`

**Invariants**
- Every audit change belongs to exactly one audit transaction.
- An audit transaction may exist with zero changes in edge cases, but this should be visible and explainable.

### 5.2 AuditChange

**Purpose:** canonical row mutation record.

**Identity**
- `change_id`

**Fields**
- `transaction_id`
- `table_schema`
- `table_name`
- `table_pk` (single or composite normalized identity)
- `op` (`insert`, `update`, `delete`)
- `data_after`
- `changed_fields`
- `data_before_subset` or `changed_from`
- `captured_at`
- `redaction_state`
- `capture_version`

**Invariants**
- Insert: no previous state required.
- Update: `changed_fields` should be non-empty unless explicitly allowed.
- Delete: enough data should remain to identify the deleted resource in the UI.

### 5.3 AuditAction

**Purpose:** semantic application-level audit event.

**Identity**
- `action_id`

**Fields**
- `name` (`member.role_changed`)
- `category` (`security`, `billing`, `membership`, `content`, `system`)
- `verb` (`create`, `update`, `delete`, `grant`, `revoke`, `approve`, `retry`, `login`)
- `actor_ref`
- `subject_refs[]`
- `tenant_ref`
- `context_ref`
- `reason`
- `comment`
- `status` (`attempted`, `succeeded`, `failed`, `partial`)
- `started_at`
- `completed_at`
- `meta`

**Important nuance**
- An action is often what humans want to search first.
- A transaction is often what DB truth wants to group first.
- The product should make both easy to traverse.

### 5.4 AuditContext

**Purpose:** reusable execution context for an action and/or transaction.

**Fields**
- `request_id`
- `correlation_id`
- `session_id` (optional)
- `job_id` (optional)
- `job_attempt`
- `source_kind` (`browser`, `api`, `job`, `cli`, `system`, `migration`)
- `route`
- `http_method`
- `remote_ip`
- `user_agent`
- `auth_mechanism`
- `integration_ref`
- `trace_id` / `span_id`
- `meta`

### 5.5 ActorRef

**Purpose:** stable reference to an actor without forcing one storage model.

**Fields**
- `actor_type` (`user`, `admin`, `service_account`, `job`, `system`, `anonymous`, `integration`)
- `actor_id`
- `display_name`
- `impersonator_ref` (optional)

**Notes**
- Actor is a value object/reference, not necessarily an FK.
- Avoid brittle assumptions that every actor lives in one users table.

### 5.6 SubjectRef

**Purpose:** stable reference to an affected resource.

**Fields**
- `resource_type`
- `resource_id`
- `resource_tenant`
- `display_label`
- `resource_path` / URL hint (optional)

### 5.7 RedactionPolicy

**Purpose:** define how sensitive data is hidden or filtered.

**Fields**
- `policy_name`
- `resource_scope`
- `field_rules[]`
- `mode` (`exclude`, `mask`, `hash`, `tokenize`, `show_last4`, `custom`)
- `applies_to` (`capture`, `query`, `ui`, `export`)
- `version`

### 5.8 RetentionPolicy

**Fields**
- `policy_name`
- `scope`
- `keep_days`
- `archive_before_purge`
- `legal_hold_capable`
- `delete_strategy`
- `redact_instead_of_delete` (optional)

### 5.9 ExportSubscription / Sink

**Fields**
- `sink_name`
- `sink_type`
- `enabled`
- `cursor`
- `delivery_guarantee`
- `format`
- `filter_predicate`
- `failure_policy`

### 5.10 CoverageCheck / HealthCheck

**Fields**
- `check_name`
- `status`
- `severity`
- `last_run_at`
- `details`
- `recommended_action`

### 5.11 SavedView / Bookmark

**Purpose:** important for real operator DX.

**Fields**
- `name`
- `owner_ref`
- `query_definition`
- `visibility`
- `last_used_at`

---

## 6) Entity relationships

### Canonical relationships

- One **AuditTransaction** has many **AuditChanges**.
- One **AuditAction** may link to zero, one, or many **AuditTransactions**.
- One **AuditAction** may link to zero, one, or many **SubjectRefs**.
- One **AuditContext** may be referenced by many **AuditActions** and many **AuditTransactions**.
- One **ActorRef** may appear in many **AuditActions** and **AuditTransactions**.
- One **RetentionPolicy** applies to many audit records by scope.
- One **RedactionPolicy** applies to many resources/fields.

### Recommended linking strategy

Prefer explicit foreign/reference links over heuristic correlation.

Good:
- `action_id` on transaction metadata,
- `context_id` shared between action and transaction,
- `correlation_id` shared across request → jobs → exports.

Bad:
- “guessing” related records only from timestamps.

---

## 7) Canonical verbs / commands

These are the main actions the system and its users perform.

### Capture-time commands

- `open_audit_transaction`
- `bind_audit_context`
- `set_actor`
- `set_subject`
- `record_action`
- `attach_reason`
- `attach_evidence`
- `capture_change`
- `commit_audit_transaction`
- `abort_audit_transaction`

### Query-time commands

- `list_timeline`
- `get_transaction`
- `get_action`
- `get_resource_history`
- `get_actor_history`
- `get_request_history`
- `get_correlation_history`
- `diff_versions`
- `reconstruct_as_of`
- `search_audit`
- `export_audit`

### Operator commands

- `run_health_checks`
- `verify_trigger_coverage`
- `verify_context_propagation`
- `run_retention`
- `run_redaction`
- `pause_export_sink`
- `resume_export_sink`
- `backfill_action_links`
- `reindex_audit`
- `upgrade_audit_schema`

### Admin/policy commands

- `grant_audit_access`
- `restrict_audit_access`
- `create_redaction_policy`
- `create_retention_policy`
- `apply_legal_hold`
- `remove_legal_hold`

---

## 8) Domain events

These are not necessarily all user-visible. They are useful for system design and extension points.

### Core events

- `audit.transaction.opened`
- `audit.transaction.committed`
- `audit.transaction.aborted`
- `audit.change.captured`
- `audit.action.recorded`
- `audit.context.bound`
- `audit.actor.bound`
- `audit.subject.linked`

### Query/UI events

- `audit.view.opened`
- `audit.export.requested`
- `audit.bookmark.saved`

### Operations events

- `audit.export.dispatched`
- `audit.export.failed`
- `audit.retention.completed`
- `audit.redaction.applied`
- `audit.coverage_gap.detected`
- `audit.integrity_violation.detected`
- `audit.trigger_missing.detected`
- `audit.context_missing.detected`
- `audit.upgrade.required`
- `audit.partition.lagging`

### Product-level semantic events

These should be possible and encouraged:
- `security.login.succeeded`
- `security.login.failed`
- `security.mfa.enabled`
- `access.role.granted`
- `access.role.revoked`
- `billing.invoice.refunded`
- `org.member.invited`
- `org.member.removed`
- `content.post.deleted`
- `system.migration.executed`

---

## 9) State machines / lifecycle

### 9.1 Interactive request lifecycle

1. Request enters Plug/Phoenix.
2. Audit context is initialized.
3. Actor is resolved.
4. Correlation/request metadata is bound.
5. App records an `AuditAction` or prepares one lazily.
6. DB transaction starts.
7. Audit transaction row is inserted.
8. Domain writes occur.
9. Trigger-backed changes are captured.
10. Transaction commits or aborts.
11. UI/query layer can now show:
    - action summary,
    - row changes,
    - diff,
    - affected resources,
    - request context.

### 9.2 Background job lifecycle

1. Job is enqueued, ideally with parent correlation data.
2. Job starts and binds audit context.
3. Actor is set to service account/system/original requester.
4. Action is recorded.
5. DB transaction(s) run and changes are captured.
6. Export/notifications may run after commit.

### 9.3 Retention lifecycle

1. Policy selects records in scope.
2. Optional archival/export is confirmed.
3. Purge or redact occurs.
4. Retention run is itself auditable.

### 9.4 Redaction lifecycle

1. Redaction policy is authored/versioned.
2. Policy applies to future capture and/or historical data.
3. Backfill job runs.
4. Redaction changes become visible to query/UI/export.
5. Attempts to reveal original data should fail by design.

---

## 10) Personas

The library should be designed for multiple distinct personas, not just “the app developer.”

### 10.1 Application developer

**Who:** feature engineer building normal product flows.

**What they care about:**
- adding audit with little friction,
- good defaults,
- low cognitive overhead,
- examples that match real Phoenix/Ecto code,
- not having to remember special Repo calls everywhere.

**Primary fear:** “I’ll ship this wrong and silently miss important changes.”

### 10.2 Elixir newcomer / onboarding developer

**Who:** new team member or developer less familiar with Ecto transactions and instrumentation.

**What they care about:**
- simple install,
- clear terminology,
- obvious API,
- visible examples,
- confidence from local dev tooling.

**Primary fear:** “I don’t understand the model well enough to trust myself.”

### 10.3 Senior backend / staff engineer

**Who:** responsible for system architecture and long-term maintainability.

**What they care about:**
- correctness guarantees,
- composability,
- escape hatches,
- migration/upgrade ergonomics,
- predictable data model,
- minimal hidden magic.

**Primary fear:** “This looks easy now but will become an opaque liability.”

### 10.4 Support/admin operator

**Who:** internal operator who needs to answer “what happened?” questions.

**What they care about:**
- searchable timeline,
- actor + subject + request drill-down,
- readable diffs,
- export/share,
- clarity around deletes and redactions.

**Primary fear:** “The data is technically there but impossible to use.”

### 10.5 Security / compliance engineer

**Who:** needs evidence, access controls, retention, integrity, and auditability of the audit system itself.

**What they care about:**
- trustworthiness,
- tamper evidence / strong guarantees,
- access control,
- masking,
- retention/legal hold,
- exportability,
- coverage reporting.

**Primary fear:** “This will not stand up to scrutiny.”

### 10.6 SRE / platform engineer

**Who:** owns production reliability and operational burden.

**What they care about:**
- database overhead,
- metrics,
- backpressure,
- partitioning,
- purge performance,
- migration safety,
- alertable health checks.

**Primary fear:** “Audit will become a silent performance or storage tax.”

### 10.7 Data engineer / analytics consumer

**Who:** wants downstream audit streams.

**What they care about:**
- stable schemas,
- incremental export,
- exactly-once-ish or at-least-once semantics,
- lineage,
- easy filtering.

**Primary fear:** “The stream is inconsistent, duplicate-heavy, or under-specified.”

### 10.8 OSS adopter / maintainer

**Who:** evaluating or contributing to the library.

**What they care about:**
- docs quality,
- principled API design,
- extensibility,
- versioning policy,
- upgrade path,
- idiomatic codebase.

**Primary fear:** “This project is powerful but difficult to contribute to or reason about.”

---

## 11) Jobs To Be Done (JTBD)

### Functional JTBDs

#### For application developers
- When I add auditing to a new schema or workflow, I want a safe default path so I don’t forget crucial wiring.
- When I perform writes inside a normal Ecto transaction, I want audit context to flow naturally.
- When I do background work, I want actor/correlation info to survive async boundaries.

#### For operators/support
- When a customer says “something changed,” I want to find the exact action and affected records quickly.
- When I inspect a timeline, I want one view that is readable by humans, not just database people.
- When something was deleted, I want enough identity/context to understand it after the fact.

#### For security/compliance
- When I need evidence, I want confidence that audited writes were not silently skipped.
- When sensitive fields are present, I want predictable masking/redaction behavior.
- When policy changes, I want to know which records are affected and whether historical data needs treatment.

#### For SRE/platform
- When audit capture degrades, I want actionable alerts and diagnostics.
- When storage grows, I want retention and partition strategies that are built-in.
- When upgrading, I want explicit compatibility guidance and health checks.

### Emotional JTBDs

- Help me **trust** the system.
- Help me **explain** what happened to others.
- Help me **not feel afraid** of adopting the library.
- Help me **recover confidence quickly** when something looks wrong.

### Social JTBDs

- Help a team say: “our audit story is solid.”
- Help engineers look competent during incidents, support calls, and reviews.
- Help teams satisfy enterprise/compliance expectations without bespoke reinvention.

---

## 12) User journeys the library must nail

### Journey 1: 15-minute local success

A developer should be able to:
- install the lib,
- generate migrations,
- enable one table,
- bind actor in Plug,
- perform a write,
- view the resulting timeline locally.

**Success feeling:** “Oh, this just works.”

### Journey 2: First production rollout

A team should be able to:
- enable a few important tables first,
- verify trigger coverage,
- confirm performance impact,
- confirm redaction rules,
- inspect audit entries in a basic UI.

**Success feeling:** “We can roll this out safely.”

### Journey 3: Incident investigation

An operator should be able to:
- search by user/email/resource/request ID,
- open a correlated timeline,
- see the action, actor, and row changes,
- export/share a report.

**Success feeling:** “We can answer what happened.”

### Journey 4: Background job debugging

A developer should be able to:
- trace a job’s action,
- see which request or system event started it,
- inspect retries/attempts,
- identify partial failures.

**Success feeling:** “Async work is not a blind spot.”

### Journey 5: Security review

A security engineer should be able to:
- inspect masking policies,
- view access constraints,
- confirm retention behavior,
- verify audit coverage,
- check health and export status.

**Success feeling:** “This is trustworthy enough to defend.”

---

## 13) Happy path design requirements

### For beginners

The “happy path” should have:
- one installation guide,
- one migration generator story,
- one Plug integration story,
- one Ecto.Multi story,
- one background job story,
- one basic UI/query story.

### Ideal first-run API shape

The library should feel something like:

- `plug Audit.ContextPlug`
- `Audit.with_actor(actor)`
- `Audit.record_action("member.role_changed", ...)`
- `Audit.transaction(meta, fn -> ... end)`
- `Audit.history(Member, id)`
- `Audit.timeline(filters)`

The specific names can vary; the principle is **discoverability and obviousness**.

### Quality-of-life defaults

- infer actor where possible,
- infer tenant where possible,
- infer request metadata in Plug,
- sensible redaction defaults for common fields (`password`, tokens, secrets),
- good default indexes,
- a usable default LiveView/browser,
- helpful error messages when context is missing.

---

## 14) Advanced usage requirements

The system should remain elegant in more difficult environments.

### Multi-tenancy
- tenant-scoped storage/querying,
- tenant-aware resource refs,
- exports per tenant,
- safe cross-tenant operator access patterns.

### Large installations
- partition awareness,
- archiving,
- retention and purge at scale,
- cursor-based exports,
- bounded UI queries,
- index management guidance.

### Async/distributed systems
- correlation propagation across job queues,
- explicit system/service actors,
- retry-aware actions,
- idempotency-friendly export model.

### Highly regulated environments
- immutable or append-only modes where possible,
- access logging for audit views/exports,
- legal hold,
- strong redaction semantics,
- data classification.

### Library extensibility
- custom actor resolver,
- custom subject resolver,
- custom UI labels,
- custom redaction strategies,
- custom export sinks,
- telemetry hooks.

---

## 15) Query model

The query layer is where good libraries often differentiate themselves.

### First-class query dimensions

- by resource type/id,
- by actor,
- by action name/category,
- by tenant,
- by request ID,
- by correlation ID,
- by transaction,
- by time range,
- by changed field,
- by operation kind,
- by source (`request`, `job`, `system`),
- by reason,
- by status,
- by tags/metadata.

### First-class result forms

- timeline feed,
- resource history,
- actor history,
- action detail,
- transaction detail,
- request/correlation trace,
- diff view,
- as-of snapshot,
- export file/stream.

### First-class questions

- “Who changed this?”
- “What did this user do today?”
- “What changed in this request?”
- “Show me all role changes in org X.”
- “Show me all changes touching field `status`.”
- “What did this object look like yesterday at 10:00?”
- “Why was this action performed?”
- “What changed during the backfill/migration?”

### Query design principles

- Results should be meaningful even when data is redacted.
- Links between action ↔ transaction ↔ changes should be one click / one function call away.
- Avoid requiring callers to understand internal table layout for common questions.

---

## 16) UI information architecture

Even if the UI is optional, the library should model data so a great UI is straightforward.

### Recommended screens / views

#### Global timeline
- mixed feed of actions and/or grouped changes,
- filters by actor/resource/action/time,
- tenant-aware,
- bookmarkable.

#### Resource history
- one resource over time,
- action summaries,
- diffs,
- as-of reconstruction,
- related requests/jobs.

#### Action detail
- what happened,
- who initiated it,
- why,
- status,
- affected resources,
- underlying row changes,
- raw metadata.

#### Transaction detail
- transaction metadata,
- exact row changes,
- links to action/context,
- integrity notes.

#### Actor view
- all actions by actor,
- impersonation context,
- tenant and time filters.

#### Request / correlation trace
- all actions and transactions linked to request/correlation,
- useful for async chains and incident investigation.

#### Ops dashboard
- trigger coverage,
- health checks,
- export lag,
- retention runs,
- schema/upgrade status,
- partition/storage growth.

### UX principles

- make the **semantic action** the hero when possible,
- expose raw row changes on demand,
- never hide uncertainty,
- explain redaction clearly,
- deleted resources should remain comprehensible.

---

## 17) Invariants and correctness rules

These should be treated as domain laws.

### Hard invariants

- Every captured row mutation belongs to exactly one audit transaction.
- Audit transaction and row changes must agree on transaction identity.
- A change must identify its source table and row identity.
- Redacted fields must never leak in query/UI/export paths that promise masking.
- Tenant isolation rules apply to audit data as strongly as primary product data.

### Strong desired invariants

- A meaningful action should usually have an actor, subject, and context.
- Background work should usually preserve parent correlation.
- Deletes should retain enough identity for operators to understand what was deleted.
- Audit views/exports themselves may need auditing in high-trust environments.

### Useful soft invariants

- Every user-facing action name should fit a naming convention.
- Action categories should remain finite and documented.
- Metadata should be typed/documented enough to query predictably.

---

## 18) Footguns to design against

This section matters a lot. The library should explicitly defend users from these.

### 18.1 Silent bypass

Risk:
- writes happen outside the expected path,
- developers forget instrumentation,
- bulk/direct SQL escapes app-level hooks.

Design response:
- canonical trigger-backed capture,
- coverage checks,
- docs that distinguish capture guarantees from action instrumentation.

### 18.2 Context loss across async boundaries

Risk:
- actor/request/correlation disappear in jobs/tasks.

Design response:
- explicit job helpers,
- context serialization/propagation APIs,
- warnings when context is unexpectedly absent.

### 18.3 Opaque storage

Risk:
- audit data exists but is painful to inspect.

Design response:
- SQL-friendly JSONB + typed columns,
- first-class query API,
- operator-readable UI.

### 18.4 Deletes that become unintelligible

Risk:
- deleted records lose all recognizable identity.

Design response:
- keep stable subject refs and key identity labels,
- store enough post-delete context for the UI.

### 18.5 Sensitive data leakage

Risk:
- secrets or PII appear in audit records, exports, or diffs.

Design response:
- field filtering/masking,
- redaction policies by capture/query/export stage,
- secure defaults and tests.

### 18.6 Audit becoming a storage/performance liability

Risk:
- write amplification,
- huge history tables,
- expensive indexes,
- painful purges.

Design response:
- sensible defaults,
- partition/retention guidance,
- operator dashboard,
- benchmark docs.

### 18.7 Upgrade friction

Risk:
- schema drift,
- trigger/migration mismatch,
- unclear compatibility.

Design response:
- migration generators,
- versioned compatibility matrix,
- health checks that detect upgrade-required states.

### 18.8 Confusing action vs change semantics

Risk:
- users ask “who deleted this member?” and get a pile of low-level updates.

Design response:
- elevate semantic actions in docs/UI,
- link down to raw row changes instead of forcing raw changes to carry all meaning.

---

## 19) Taxonomy and naming conventions

Naming consistency is part of DX.

### Action naming convention

Recommended:
- `resource.verb`
- or `domain.resource.verb`

Examples:
- `member.invited`
- `member.role_changed`
- `invoice.refunded`
- `security.login.failed`
- `system.backfill.executed`

### Categories

Keep categories finite and explicit:
- `auth`
- `security`
- `access`
- `membership`
- `billing`
- `content`
- `system`
- `data`
- `support`
- `compliance`

### Actor types

- `user`
- `admin`
- `support_agent`
- `service_account`
- `system`
- `integration`
- `job`
- `anonymous`

### Source kinds

- `browser`
- `api`
- `job`
- `cli`
- `migration`
- `backfill`
- `system`

### Statuses

- `attempted`
- `succeeded`
- `failed`
- `partial`
- `suppressed` (rare, explicit)

---

## 20) API surface design guidance

### Public API layers

#### Layer 1: zero-to-one install
- migration generators,
- Plug integration,
- minimal action recording,
- basic query functions.

#### Layer 2: app integration
- action DSL/helpers,
- actor resolvers,
- context helpers,
- job helpers,
- subject helpers.

#### Layer 3: operator/admin
- query builder,
- export API,
- health checks,
- retention/redaction admin APIs.

### Strong ergonomic preferences

- Prefer **explicit but low-friction** over overly magical.
- Favor composable helpers over giant callback DSLs.
- Use domain words consistently: `action`, `change`, `transaction`, `context`, `actor`, `subject`.
- Make logs/errors/docs use the same vocabulary.

### Error message philosophy

Errors should tell the user:
- what is missing,
- whether correctness is degraded,
- how to fix it,
- whether this affects only semantics or also canonical capture.

Example kinds of messages:
- missing actor,
- missing parent transaction,
- missing trigger coverage,
- unsupported resource identity,
- redaction rule conflict,
- export sink lagging.

---

## 21) Operational model

### Health dimensions

- capture health,
- query/index health,
- export health,
- retention health,
- policy health,
- upgrade compatibility health.

### Minimum telemetry

Counters:
- transactions opened,
- changes captured,
- actions recorded,
- redactions applied,
- export successes/failures,
- retention purges.

Gauges:
- export lag,
- partition size,
- storage growth,
- oldest unprocessed export cursor,
- health check failures.

Histograms:
- query latency,
- diff render latency,
- export batch time,
- purge duration,
- capture overhead estimate.

### Health checks worth shipping

- missing trigger coverage,
- action recorded without linked context,
- audit transaction rows with zero changes rate,
- export sink stalled,
- schema version mismatch,
- partition retention overdue,
- redaction backlog.

---

## 22) Security and policy model

### Access control questions

The library should help answer:
- who can read audit data?
- who can export it?
- who can see redacted vs masked fields?
- who can define policies?
- who can see cross-tenant data?

### Policy principles

- Audit data is often **more sensitive** than source data.
- Support users often need summaries, not raw sensitive fields.
- Exports should have independent authorization and tracking.
- Views and exports may themselves deserve audit records.

### Redaction model guidance

Support at least:
- exclude field entirely,
- mask field,
- show token/partial form,
- hash deterministic fingerprint,
- custom renderer for UI/export.

---

## 23) Data lifecycle and retention model

### Storage classes

It is useful to think in classes:
- hot recent audit data,
- warm searchable history,
- cold archived export,
- purged/redacted historical records.

### Retention questions

- How long is each class kept?
- Can some metadata outlive raw diffs?
- What is the legal-hold story?
- How are deletes represented after purge?
- Are action summaries retained longer than row-level payloads?

### Recommended posture

Allow independent retention for:
- action metadata,
- row payloads,
- exports,
- health/ops runs.

That gives users a powerful cost/privacy/control tradeoff space.

---

## 24) Suggested package/module map (conceptual)

This is just one possible decomposition.

- `Audit`
- `Audit.Transaction`
- `Audit.Change`
- `Audit.Action`
- `Audit.Context`
- `Audit.Actor`
- `Audit.Subject`
- `Audit.Query`
- `Audit.Timeline`
- `Audit.Diff`
- `Audit.Redaction`
- `Audit.Retention`
- `Audit.Export`
- `Audit.Health`
- `Audit.Telemetry`
- `Audit.Plug`
- `Audit.Job`
- `Audit.LiveView` or `Audit.Web`

If Carbonite-backed:
- `Audit.Capture.Carbonite`
- `Audit.Capture.Carbonite.Migrations`
- `Audit.Capture.Carbonite.Coverage`

---

## 25) Acceptance criteria for “best-in-class”

A serious contender for “best audit lib in Elixir” should satisfy most of these.

### Developer experience
- A newcomer can get value in under 30 minutes.
- Docs explain the difference between action, transaction, and change clearly.
- The happy path is obvious and idiomatic.
- Background job instrumentation is first-class, not an afterthought.

### Product experience
- Operators can answer common “what happened?” questions without SQL.
- Timelines are readable and diff views are useful.
- Deleted resources remain understandable.

### Reliability/ops
- Teams can detect missing coverage and degraded health.
- Retention and export are built-in concepts.
- Upgrade paths are documented and supported.

### Security/compliance
- Redaction/masking is credible and testable.
- Access to audit data is controllable.
- The system’s own administrative actions are auditable.

### Architecture
- Storage is SQL-native and inspectable.
- The model scales from simple apps to more serious deployments.
- Core abstractions remain stable as features grow.

---

## 26) Anti-patterns to avoid

- Treating audit as only a UI problem.
- Treating audit as only a trigger problem.
- Storing primary query surfaces in opaque serialized blobs.
- Hiding too much behavior in callbacks or magical Repo monkeypatching.
- Conflating request, transaction, and action into one overloaded record.
- Designing only for compliance and forgetting support/debuggability.
- Designing only for developers and forgetting operators/SRE/security.
- Assuming every actor is a user row.
- Assuming every action corresponds to exactly one row change.

---

## 27) Open design questions

These are the highest-value decisions to resolve early.

1. **Canonical public term:** should the top-level concept be `action`, `event`, or `entry`?
2. **Storage split:** should app-level actions live in separate tables from row changes? (Probably yes.)
3. **As-of support:** how much reconstruction should be first-class in v1?
4. **UI product boundary:** core library only, optional admin UI package, or both?
5. **Redaction timing:** capture-time only, query-time only, or both?
6. **Audit-of-audit:** should viewing/exporting audit data generate audit entries?
7. **Multi-repo / multi-database story:** what is explicitly supported?
8. **Backfill story:** how do teams safely introduce auditing to existing tables/workflows?
9. **Policy DSL:** how declarative vs programmable should masking/retention be?
10. **Action taxonomy governance:** how opinionated should naming conventions be?

---

## 28) Compressed LLM context block

Use this section as a high-signal context summary.

### Product identity

- Batteries-included audit platform for Phoenix/Ecto/PostgreSQL.
- Core substrate likely trigger-backed canonical row capture.
- Must also model semantic actions, actors, context, and operator workflows.

### Canonical nouns

- `AuditTransaction`: one DB transaction grouping row changes.
- `AuditChange`: one row mutation.
- `AuditAction`: semantic app-level event.
- `AuditContext`: request/job/correlation metadata.
- `ActorRef`: user/admin/system/service identity.
- `SubjectRef`: affected resource identity.
- `RedactionPolicy`, `RetentionPolicy`, `ExportSink`, `HealthCheck`.

### Canonical verbs

- open transaction, bind context, set actor, record action, capture change, query timeline, diff versions, reconstruct as-of, export, redact, purge, verify coverage.

### Core separations

- action != change
- transaction != request
- actor != user table row
- timeline entry != storage row

### Personas

- application developer,
- onboarding/newcomer,
- senior backend engineer,
- support/admin operator,
- security/compliance,
- SRE/platform,
- data engineer,
- OSS adopter.

### Must-win UX

- easy first-run setup,
- trustworthy capture,
- searchable timeline,
- readable diffs,
- async context propagation,
- good defaults + configurable policy,
- health/retention/export built in.

### Big design risks

- silent bypass,
- async context loss,
- opaque storage,
- unintelligible deletes,
- sensitive-data leakage,
- storage/perf tax,
- upgrade friction,
- confusing semantics.

---

## 29) External precedents to steal from

These are useful product inspirations, not strict implementation constraints.

- **Carbonite-style ideas**: trigger-backed row capture, transaction as the natural audit grouping unit, query/purge/outbox helpers.
- **PaperTrail-style ideas**: first-class `whodunnit`, request-scoped metadata, queryable metadata columns.
- **django-auditlog-style ideas**: actor binding outside request context, masking, practical admin ergonomics.
- **JaVers-style ideas**: strong query shapes, human-readable diffs, object-history exploration.

---

## 30) Final design stance

If we want to be the best option in the ecosystem, the north star is:

> **Make the trustworthy path the easy path; make the advanced path feel intentional, not painful; make the operational path first-class.**

That means:
- canonical capture people can trust,
- semantic actions people can understand,
- query/UI people can actually use,
- operations/policy people can live with.
