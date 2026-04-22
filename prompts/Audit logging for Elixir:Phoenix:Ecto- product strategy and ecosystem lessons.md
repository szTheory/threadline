Audit logging for Elixir/Phoenix/Ecto: product strategy and ecosystem lessons

Here’s the doc I’d use as the working brief.

Audit logging for Elixir/Phoenix/Ecto: product strategy and ecosystem lessons

Your instinct is good, with one important adjustment: the best product is probably not “Carbonite, but with a UI.” The better framing is a hybrid audit platform for Phoenix/Ecto: Carbonite as the row-change source of truth, plus a first-class action/context layer, plus a batteries-included query/UI/ops layer. Also, your note is slightly dated: Carbonite’s docs currently show v0.16.1, not v0.15.2.  ￼

The key product insight

Most audit systems are trying to solve at least three different jobs:

* Row-change auditing: “what rows changed, exactly?” Carbonite is strong here because it uses PostgreSQL triggers, keeps a central changes table, ties changes to a transaction record, and supports query/outbox helpers.  ￼
* User-action auditing: “what did the user/operator/job do, and why?” Elixir discussion around auditing repeatedly points out that this is often better captured at the controller/service/API layer, because a single user action may touch many rows and tables and should carry request/user/IP/auth context. Hex.pm and Bytepack-style audit logs lean into this action-centric model with fields like action, audit context, and params.  ￼
* Compliance / DB activity auditing: “what statements were executed, including access patterns?” pgAudit is built for this, but it writes to PostgreSQL logs and is a different product category from in-app audit history.  ￼

That distinction matters because the libraries people love usually do one of these extremely well, while the libraries people complain about usually blur them together and leave awkward gaps.  ￼

Recommendation

Build on Carbonite, but ship a hybrid system. Carbonite is the best substrate in Elixir today if your main promise is “don’t miss writes.” But the winning product layer above it should add:

1. request/job/actor context propagation,
2. action-level audit records,
3. excellent browsing/querying,
4. redaction/masking and retention controls,
5. operator tooling for upgrades, health checks, and exports.  ￼

I would not start with WAL/CDC as the primary backend. Debezium and Bemi show why CDC is attractive, especially for direct-SQL capture and polyglot ecosystems, but they also show the extra operational surface area: transaction-log plumbing, metadata enrichment, logical replication setup, replication privileges, WAL volume growth, and cloud-provider caveats. In Neon’s case, enabling logical replication changes wal_level to logical, restarts computes, and cannot be reverted.  ￼

Elixir landscape

Carbonite: best core for correctness

Carbonite’s model is strong: triggers capture INSERT/UPDATE/DELETE into a central changes table, each change links to a transactions record, metadata can ride on the transaction, and the library includes migration helpers, query helpers, Ecto.Multi integration, and an outbox abstraction. It also has practical features like excluded columns, filtered columns, and store_changed_from, plus support for custom/composite primary keys and multiple audit schemas via carbonite_prefix.  ￼

The rough edges are exactly where a product can win. TRUNCATE is not captured. Metadata propagation is still something the app has to do deliberately. Upgrades can require host-app migrations. Empty transactions can happen. Outbox processing has caveats around ordering and duplicate processing on exceptions. Testing has bypass/override modes and extra SQL costs that teams have to understand.  ￼

Conclusion: Carbonite is a great engine, not yet the complete product.  ￼

PaperTrail for Elixir: explicit and ergonomic, but easier to miss writes

Elixir’s PaperTrail creates versions when you call PaperTrail.insert/update/delete, does so in one transaction, and supports origin, originator, meta, prefix, and strict_mode. That is a very understandable API, and the relational version model is much more query-friendly than opaque patch blobs.  ￼

The tradeoff is structural: if developers call plain Repo APIs or write direct SQL, those changes are not automatically versioned. That gives it a nicer happy path than trigger-based systems, but a weaker correctness guarantee.  ￼

ExAudit: drop-in feel, but more opaque and less future-proof

ExAudit’s selling point is strong DX on day one: it plugs into your Ecto repo, hooks mutating repo functions, tracks history, supports revert, and can track associated entities from a single repo call.  ￼

The costs show up later. Its custom context is tied to processes/PIDs and stored via ETS; docs call out that if repo functions run outside the conn process you may need to pass data manually. Its patch field is stored as an Erlang binary format, which is convenient for reconstruction but poor for SQL-native introspection and querying. It is also much less recently maintained than Carbonite or Elixir PaperTrail.  ￼

Conclusion: ExAudit is good evidence that easy onboarding matters, but also good evidence that opaque storage and process-local context age poorly.  ￼

Manual action logs in Elixir: essential companion, not substitute

The Bytepack/Hex.pm pattern is worth stealing directly: action-oriented audit records with a context object, action name, and params, tied to who did it and when. That is excellent for “user clicked X,” “admin invited Y,” or “billing job retried payout Z.” It is not enough, by itself, for “prove every row mutation was captured.”  ￼

What other ecosystems got right

Ruby PaperTrail

Ruby PaperTrail’s strongest ideas are still excellent: first-class whodunnit, request-scoped helpers, and queryable metadata columns so you do not have to deserialize blobs just to search by actor/reason. It also models versions in a way that supports reification/history well.  ￼

Its warnings are just as valuable. Callback order can make global enable/disable approaches fragile, and association tracking was extracted to a separate gem after enough issues accumulated. That is a big lesson: do not hide too much magic in lifecycle callbacks around associations.  ￼

Audited (Rails)

Audited gets a lot right from a product perspective: simple model-level setup, current-user tracking, as_user blocks, comments, max_audits, selective callbacks, and automatic filtering of encrypted attributes as [FILTERED].  ￼

Its cautionary lesson is serialization and upgrade friction. Historically it defaulted to YAML storage, and real users hit painful deserialization/configuration issues during framework/security changes. That is a strong argument for JSONB + typed columns + minimal magic, not YAML or opaque terms.  ￼

Logidze

Logidze is one of the strongest “steal ideas, not architecture” examples. It uses triggers, gives a decent browsing API, and has lovely app-facing helpers like with_meta and with_responsible.  ￼

But it also documents several nasty footguns: connection-local metadata can misbehave with PgBouncer if you skip transactions, after_commit work can miss metadata, deleting a row loses its history unless you soft-delete, and storing audit history with the record can bloat rows and slow queries.  ￼

Django auditlog

django-auditlog shows what a very practical batteries-included package looks like: field masking, correlation IDs, request middleware for actor binding, background-job helpers like set_actor, and disable blocks for fixtures/maintenance.  ￼

Its limitations are also classic signal-based limitations: many-to-many is not automatic by default and can get noisy, and the system is intentionally optimized for fast/simple change summaries rather than full version control semantics.  ￼

django-simple-history

django-simple-history is great evidence that users value as_of queries, cleanup commands, and multi-database/operator docs, not just “capture happened.” It also exposes where signal-based approaches crack: bulk operations and queryset updates do not automatically save history, and certain ORM expression patterns like F() are problematic.  ￼

Hibernate Envers

Envers contributes one very important design lesson: a global revision / transaction-centric mental model is powerful, and audit strategy matters. Its default strategy favors writes but can make historical queries slower; ValidityAuditStrategy writes more but makes reads and partitioning friendlier by storing validity intervals. It also supports custom revision entities/listeners for username/IP-style metadata.  ￼

JaVers

JaVers is probably the best source of ideas for your UI/query experience. It emphasizes human-friendly diffs, snapshots, and “shadows” that reconstruct historical object graphs, and it stores snapshots as JSON while reusing unchanged snapshots to save space.  ￼

Audit.NET

Audit.NET is a good model for extensibility and operations: a clear AuditScope lifecycle, DI-friendly factories, multiple creation policies, many integrations, and OpenTelemetry support. That is a strong template for how your Elixir library should think about pluggable sinks, exporters, and observability.  ￼

The complaints people keep running into

The recurring complaints are surprisingly consistent across ecosystems:

* Missed writes because the audit path is opt-in or callback-based. Bulk APIs, direct SQL, background jobs, or plain repo calls bypass auditing in many hook/signal systems.  ￼
* Context propagation is fragile. PID-local, thread-local, or connection-local metadata is easy to lose across async boundaries, pooling, or callbacks.  ￼
* Opaque storage kills query UX. YAML, binary patches, and opaque blobs make operator introspection and ad hoc querying miserable. Queryable metadata columns and JSONB age much better.  ￼
* Delete semantics are often bad. Some systems make deletes awkward to reason about; others, like Logidze’s record-local history, lose history with the record unless you soft-delete.  ￼
* Audit data volume becomes an ops problem. pgAudit can generate huge log volume; WAL/CDC increases infra complexity and log traffic; record-local history can bloat hot tables.  ￼
* Upgrades and schema drift hurt trust. Trigger/migration systems need good migration helpers and upgrade stories; callback gems have their own framework-upgrade pain.  ￼

Product principles for “the best Elixir audit library”

This is the product shape I would target:

1) Separate capture from meaning

Use Carbonite for canonical row capture, but add a first-class Audit Action layer for semantic events like user.invited, invoice.refunded, or member.role_changed. Link actions to Carbonite transaction IDs, request IDs, and affected records. That mirrors the real split people keep discovering in production.  ￼

2) Make context propagation delightful

You want the equivalent of PaperTrail’s whodunnit, Logidze’s with_meta/with_responsible, django-auditlog’s middleware and set_actor, and Audit.NET’s scoped lifecycle — but for Plug/Phoenix/Ecto. Context should include actor, actor type, request ID, correlation ID, IP, user agent, reason, source, and job metadata.  ￼

3) Store data for humans and SQL

Prefer typed columns plus JSONB for flexible metadata. Avoid YAML and opaque binary patch formats as the primary query surface. Make actor/reason/request ID searchable without deserializing anything.  ￼

4) Build the operator experience in from day one

You want retention jobs, cleanup commands, migration health checks, trigger coverage checks, redaction policies, export to SIEM/data lake, and OpenTelemetry hooks. The successful mature libraries all expose some version of these operational affordances.  ￼

5) Optimize the happy path, but keep escape hatches

The install story should feel closer to ExAudit/Audited on day one, while correctness stays closer to Carbonite. Then add advanced controls for masking, excluded columns, multi-tenancy/prefixes, backfills/data migrations, outbox/export, and background jobs.  ￼

Concrete product thesis

I would position this as:

“The batteries-included audit platform for Phoenix/Ecto on PostgreSQL.”

Not just:
“A UI for Carbonite.”

That gives you room to own four layers:

* Capture layer: Carbonite integration, migration generators, trigger coverage checks, filtered/excluded columns, composite PK handling.  ￼
* Context layer: Plug/job helpers for actor/reason/request metadata, action records, background-job propagation.  ￼
* Explore layer: query API, diff views, “as of” views, related-changes navigation, actor/request/record search, CSV/JSON export, LiveView browser. Inspiration here is JaVers + PaperTrail + Django admin-style history.  ￼
* Operations layer: retention, purging, health checks, outbox processing/export, OTel, and optional pgAudit/SIEM integration for compliance-heavy shops.  ￼

LLM build brief

Goal: build the best audit platform for Elixir/Phoenix/Ecto on PostgreSQL: impossible-to-miss row capture, excellent request/job/user context, and a first-class operator/developer browsing experience. This should feel native to Ecto/Phoenix, require minimal ceremony on the happy path, and remain debuggable and queryable under stress.  ￼

Non-negotiables: trigger-based capture for canonical row history; first-class action/context records; queryable metadata columns; JSONB-friendly storage; masking/redaction; background-job context propagation; multi-tenant support; retention/export/OTel hooks; good upgrade/migration ergonomics.  ￼

Things to avoid: callback-only capture, opaque binary/YAML storage as the main query interface, connection-local context leaks, record-local history that disappears on delete, and product messaging that confuses app audit history with compliance/database activity logs.  ￼

Strategic call: ship Carbonite-first and Postgres-first. Keep your public API abstract enough that a CDC backend could exist later, but do not let that possibility drag v1 into replication/infra complexity.  ￼

My main conclusion is: yes, Carbonite is the right foundation — but the winning lib is the one that makes Carbonite feel like PaperTrail + Audited + JaVers + django-auditlog for Phoenix, without inheriting their worst footguns.

I can turn this into a concrete package/API spec next.