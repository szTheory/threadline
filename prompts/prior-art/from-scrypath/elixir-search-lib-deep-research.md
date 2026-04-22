I dug through the recent docs, releases, ecosystem integrations, and Elixir-adjacent tooling. My bottom-line take is:

Build this as an Ecto/Postgres-first projection library with first-class Oban integration, versioned index/collection aliases, strong Telemetry/OpenTelemetry hooks, and an adapter boundary for search engines. For the first engine, I would lean Typesense-first if your top priority is low self-hosted ops overhead plus OSS high availability. I would make Meilisearch the second adapter because it has the larger public OSS footprint, stronger current momentum, and a very polished cloud story, but its self-hosted HA/scaling story is now tied more closely to Enterprise/Cloud-era features and its Prometheus endpoint is still marked experimental.  ￼

The opportunity is real. As of April 15, 2026, I did not find a dominant, battle-tested Elixir equivalent to Searchkick/Scout for Ecto/Phoenix. Meilisearch’s official SDK page lists many official clients and framework integrations, but not Elixir; Typesense’s client page likewise lists official libraries for a few languages and says everything else can use any HTTP library, but again not an official Elixir client. The current Elixir options are small community clients such as meilisearch-ex, ex_typesense, and a very new ex_meilisearch, which tells me the adapter layer is still open terrain rather than a solved ecosystem standard.  ￼

The precedent to study, and what each one teaches

Searchkick is still the DX benchmark. It has active maintenance into 2026, supports queue-based reindexing, and explicitly recommends pushing changed IDs into a queue and bulk reindexing for performance. It also documents zero-downtime deployment patterns around reindexing and feature/schema changes. That is the “gold standard feel” you want Elixir developers to get.  ￼

Laravel Scout is the best architectural benchmark. It is driver-based, automatically syncs model changes, supports Meilisearch and Typesense, and also ships a built-in database engine for MySQL/Postgres because, for many apps, “no extra infrastructure” is the right answer. That is a huge clue for your library design: keep the abstraction boundary clean, and seriously consider a Postgres-only local/dev/small-app driver even if your flagship story is external search.  ￼

Django Haystack is the warning label. Its docs explicitly say signal-driven realtime indexing increases CPU/I/O load, and the project moved away from tightly coupling index definitions directly to framework signals. That is the exact footgun to avoid in Elixir: don’t make “magic callbacks everywhere” your default architecture.  ￼

meilisearch-rails and typesense-rails are especially valuable because they show the actual integration wrinkles once a library hits production users: eager-loading hooks for reindexing, background job delete races, zero-downtime reindex APIs, custom primary keys, shared-index collision handling, pagination integration, and schema/DSL ergonomics. Meilisearch’s Rails integration is more mature publicly right now; Typesense’s Rails gem is newer, explicitly a fork of algolia-rails, and is still in RC territory, but it already mirrors several patterns you’ll want.  ￼

Meilisearch vs Typesense for your exact goals

1) Popularity, momentum, and likely trajectory

By public OSS signals, Meilisearch is bigger right now: its GitHub repo showed 57.1k stars and the latest release v1.42.1 on April 14, 2026. It also has a visibly aggressive 2026 product cadence, including a March 2026 roadmap post and an April 13–17, 2026 launch week centered on scaling, security, and tooling.  ￼

Typesense is smaller but still very active: its repo showed 25.6k stars, the current major line is 30.x, and its docs were updated in March 2026. It has a long-running cloud product, a public roadmap link, and official docs that are unusually strong on production operations, clustering, and testing.  ￼

My read: Meilisearch has more momentum and broader “mindshare” right now; Typesense has the stronger “boring production system” vibe for self-hosters. That is not a knock on Meili. It is just a different product center of gravity.  ￼

2) Self-hosted ops burden and HA

If your north star is “simple, hands-off, low babysitting, no Elasticsearch trauma,” Typesense has the cleaner OSS self-host story today. The docs describe it as a single self-contained binary with no runtime dependencies, and its HA story is documented in OSS terms: 3-node minimum for one-node fault tolerance, Raft clustering, reads/writes on any node with forwarding to the leader, and clear recovery guidance.  ￼

Meilisearch is also easy to start as a single node, and its Cloud option is explicitly recommended for most users because it handles provisioning, scaling, backups, updates, and monitoring. But the docs for replication say that replicated HA requires Enterprise Edition v1.37+, and the repo/docs now clearly distinguish MIT Community Edition from enterprise-licensed features. That makes Meili’s self-hosted HA story more nuanced than Typesense’s if you want fully OSS clustering.  ￼

So the practical decision is:
	•	If you expect many users to self-host on a few VMs / k8s nodes and want OSS HA: Typesense fits better.  ￼
	•	If you expect many users to use a managed service and you want maximum momentum + polished cloud UX: Meilisearch is very compelling.  ￼

3) Observability and runtime introspection

Typesense exposes metrics.json, stats.json, and a health/debug endpoint. The metrics include CPU, RAM, disk, network, and allocator-level memory details; the docs point to a community Prometheus exporter rather than a built-in Prometheus endpoint. That is a very usable ops story, just a bit more DIY for Prometheus.  ￼

Meilisearch exposes /stats, which includes DB size, document counts, last update time, and per-index isIndexing; it also has task webhooks and a log streaming route. It does have a /metrics endpoint in Prometheus format, but the docs still mark it experimental.  ￼

Operationally, that means I would trust Typesense’s built-in ops endpoints sooner for self-hosted SRE dashboards, while I would treat Meilisearch task webhooks + /stats as the most stable core signals and /metrics as “use with caution until the experimental label disappears.”  ￼

4) Write path and indexing behavior

This is one of the most important differences for your library design.

Typesense’s docs are unusually explicit: use updated_at, soft deletes or deleted-ID tracking, and bulk import with action=upsert. For high write volume, they recommend a buffer table/queue in the primary DB and a scheduled job every 5–10 seconds to bulk import, because bulk writes are far more CPU-efficient than per-document writes. They also say to cap concurrent bulk imports relative to CPU count. That maps almost perfectly onto Postgres + Oban + batch flusher.  ￼

Meilisearch processes many operations asynchronously as tasks, supports batching, task monitoring, and task webhooks, and its large import docs emphasize batch sizing, compression, progress monitoring, and error recovery. The docs also explicitly say to configure settings before bulk import, otherwise you can end up paying for extra reindex work.  ￼

The implication for your library is strong: default to async + batch-oriented indexing no matter which engine you support. Synchronous per-row HTTP writes should be a test/dev mode, not your production default.  ￼

5) Multi-tenancy and SaaS fit

For SaaS, both engines have a good story, but they differ in flavor.

Typesense leans toward single collection + scoped search keys. The docs explicitly say that for multi-tenant data in one collection, you should embed the logged-in user’s filter in scoped keys and never expose the parent search key.  ￼

Meilisearch has tenant tokens and search rules for document-level access control. Its 2026 roadmap also shows a clear future bet on cheap per-tenant indexes in Cloud via “serverless indexes,” but that is a future cloud feature, not the default self-host posture today.  ￼

For your library, I would make the default multitenancy model: shared index/collection + tenant_id filter + per-tenant search credentials. Per-tenant indexes should be a deliberate opt-in for isolation, compliance, or extremely large tenants.  ￼

6) Licensing

This matters more than many library authors admit.

Meilisearch now has a clearly separated licensing model: Community Edition is MIT, while enterprise-only features are under commercial/BUSL-style terms. Typesense’s server repo is GPL-3.0. That does not automatically make one better than the other, but it does affect what some users and companies are comfortable standardizing on.  ￼

If your audience is heavily startup/SaaS and mostly consuming a managed service, this may not block adoption. If your audience includes conservative infra teams who care deeply about engine licensing, surface this prominently in your docs.  ￼

My recommended architecture for the Elixir library

1) Design center: Postgres is the source of truth

Treat search as a projection, not the source of truth. Persist business data in Postgres, then atomically enqueue indexing work in the same transaction using Ecto.Multi plus Oban job insertion. Ecto gives you transaction composition with Ecto.Multi, and Oban explicitly guarantees jobs inserted in the same transaction only trigger after a successful commit.  ￼

That means your library should be built around invariants like:
	•	a committed DB transaction eventually produces an index update,
	•	a rolled-back DB transaction produces no index update,
	•	a failed index update is retriable and observable,
	•	reindex/swap is atomic from the application’s perspective.

Those are the right invariants for spec-driven design in this space.  ￼

2) Do not make “magic callbacks on every schema” the main architecture

You can offer a use MyLib.Searchable macro for ergonomics, but the safe core should be explicit orchestration from the context layer. Haystack’s caution on signal coupling and load is real, and Ecto already gives you explicit transactional tools. prepare_changes/2 exists and runs inside the repo operation, but I would use it sparingly; for most production code, an explicit Ecto.Multi integration is clearer, more DDD-friendly, and less surprising.  ￼

So I would expose something like:

Ecto.Multi.new()
|> Ecto.Multi.insert(:product, Product.changeset(%Product{}, attrs))
|> Search.Multi.enqueue_upsert(:product_index, ProductSearch, fn %{product: p} -> p end)
|> Repo.transaction()

That respects bounded contexts much better than “every repo write globally emits indexing side effects.”

3) Separate schema declaration from search projection

This is where a lot of libraries go wrong. Do not make the Ecto schema itself the only place where search logic lives.

Better pattern:
	•	Ecto schema remains the domain/persistence model.
	•	Search projection module defines:
	•	collection/index name
	•	ID strategy
	•	preload/query strategy for backfills
	•	serialization
	•	filterable/sortable/faceted fields
	•	tenant strategy
	•	engine-specific options

That lets you preserve DDD boundaries and keep cross-context coupling out of your Ecto models. It also gives you room for multiple projections per schema later, which meilisearch-rails already supports conceptually via multiple indexes.  ￼

4) Versioned index/collection names plus an alias

This should be non-negotiable. Typesense’s docs explicitly recommend collection aliases for schema changes and reindex/swap workflows, and typesense-rails exposes zero-downtime reindexing. Searchkick also documents zero-downtime deployment concerns around reindexing.  ￼

So your library should always think in terms of:
	•	physical index/collection: products_2026_04_15_153000
	•	logical alias: products_current

Application reads and writes target the alias. Reindex builds a new physical target, backfills, validates counts, then swaps alias. That is the right primitive for deploy safety.

5) Make batching a first-class primitive

Do not model production indexing as “one Oban job = one HTTP document update” unless the user explicitly opts into strict realtime. Searchkick recommends queueing IDs and bulk reindexing. Typesense explicitly recommends buffer tables and bulk import for high-volume writes. Meilisearch emphasizes batched imports and task monitoring.  ￼

So I would have two write paths:
	•	hot path: enqueue record IDs / operations into a Postgres-backed outbox or Oban queue;
	•	flush path: worker groups pending ops by projection and engine, materializes latest state from Postgres, then bulk upserts/deletes.

That gets you idempotency, deduping, and better throughput.

Recommended Phoenix/Ecto/Oban integration

The most idiomatic default for this ecosystem is:
	•	Ecto.Multi for app data + search enqueue in one transaction,  ￼
	•	Oban unique jobs for dedupe, since uniqueness applies at insertion time and prevents duplicate enqueues,  ￼
	•	Oban workers for async flush/reindex jobs, with Oban telemetry attached for job lifecycle observability,  ￼
	•	Repo telemetry events and your own custom telemetry for projection serialization, engine requests, retries, and alias swaps.  ￼

I would make Oban the first-class queue integration, but probably not the only theoretical one. Architecturally, use a queue behaviour/port and ship MyLib.Queue.Oban as the blessed adapter. That keeps the library clean while still being maximally idiomatic for Postgres/Phoenix apps. Oban’s “fewer dependencies” and transactional control are exactly why it is the right default here.  ￼

Supervisor tree and runtime shape

I would keep the runtime small and boring:
	•	Finch/Req HTTP pool(s) for engine clients. meilisearch-ex already shows a Phoenix-supervisor pattern with named Finch and named Meilisearch clients. Typesense’s docs say its client libraries are thin wrappers over HTTP, which is another signal to keep your adapter runtime simple.  ￼
	•	Oban supervisor.
	•	Telemetry/OTel setup at application start.
	•	Optional poller for engine health/task reconciliation.
	•	Optional backfill coordinator / task supervisor for full reindex jobs.

I would not put a lot of bespoke GenServers in here unless they own real state. Most of the system should be: DB transaction → durable queue → stateless workers → engine.

Observability, monitoring, and admin UI

This library should feel first-class in Phoenix apps, so instrument it heavily.

Phoenix already centers on :telemetry; Ecto emits repo events; Oban emits lifecycle events for jobs and plugins. Phoenix LiveDashboard supports metrics and custom dashboard pages. Oban Web gives you a realtime embedded LiveView admin surface for background job activity. OpenTelemetry packages exist for Phoenix and Ecto, and the OpenTelemetry Erlang/Elixir guide shows the Phoenix/Ecto setup path. PromEx can expose Phoenix metrics cleanly.  ￼

So my recommended admin story is:
	•	Primary admin UI: your own Phoenix LiveDashboard custom page + Oban Web.
	•	Secondary admin UI: engine-native dashboards/tools for manual inspection.

That means:
	•	Oban Web for queue depth, failures, retries, worker latency.  ￼
	•	LiveDashboard custom page for:
	•	current alias target,
	•	last successful flush,
	•	indexing lag,
	•	failed batch count,
	•	engine health,
	•	document count divergence,
	•	last reindex status.  ￼
	•	Engine-specific health:
	•	Typesense: metrics.json, stats.json, debug.  ￼
	•	Meilisearch: /stats, task webhooks, logs stream, maybe /metrics if you accept experimental status.  ￼

On engine-native UIs: Meilisearch Cloud has a built-in web interface and analytics; Meilisearch also has a self-hosted mini-dashboard, but it is intentionally minimal. Typesense Cloud has an admin dashboard with team accounts and RBAC. I did not find an equally central official self-hosted Typesense dashboard in the docs; the emphasis is more on API endpoints and Cloud UI.  ￼

The biggest footguns to avoid
	1.	Calling the search engine inside the request transaction.
This couples user latency and DB correctness to an external HTTP dependency. Use transactional enqueue, not transactional indexing.  ￼
	2.	Assuming callback-driven “realtime” sync is free.
Haystack explicitly warns that signal-based indexing increases system load. Treat realtime as a tradeoff, not the default virtue.  ￼
	3.	Per-document writes at scale.
Typesense says bulk import is much more efficient than single-document writes and recommends a buffer-table approach for high-volume systems. Searchkick also recommends queueing IDs and reindexing in bulk.  ￼
	4.	Delete jobs that reload a row after it has already been deleted.
Meilisearch Rails calls this out directly: background delete jobs can hit RecordNotFound; the safe path is to delete from the index by ID without reloading the DB row.  ￼
	5.	N+1 serialization during backfills.
Meilisearch Rails explicitly provides an eager-loading import scope. Your projection modules need a preload/query hook.  ￼
	6.	Shared-index ID collisions.
If multiple schemas share an index/collection, prefix IDs with type/context. Meilisearch Rails documents this exact issue.  ￼
	7.	Hiding schema/settings changes behind a “transparent” update.
Meilisearch requires filterable/sortable attributes to be configured and the settings task completed before those queries work; Typesense recommends aliases for schema evolution. Build explicit reindex/swap workflows.  ￼
	8.	Letting auto-schema or over-indexing waste RAM.
Typesense docs specifically recommend predefined schema when possible and keeping display-only fields out of indexed schema or marked unindexed to save memory.  ￼
	9.	Weak retry/backoff under write pressure.
Typesense warns about client-side timeouts, retry storms, and 503s under heavy write load or startup/recovery. Build exponential backoff + jitter and circuit-breaking into the adapter.  ￼
	10.	Underestimating upgrade friction.
Meilisearch’s update docs say DBs are only compatible with the version that created them and describe dump-based migration; the config docs also warn dumpless upgrades are not currently atomic. Always pin versions and rehearse upgrade paths in CI.  ￼

Spec-driven / test-driven approach I would use

Write the library around a contract test suite that every adapter must pass.

Core adapter contracts should cover:
	•	create physical index/collection
	•	apply settings/schema
	•	bulk upsert
	•	bulk delete
	•	search
	•	alias create/swap
	•	count/stats fetch
	•	health fetch
	•	partial failure semantics
	•	idempotent retry behavior

Then build tests in four layers:
	1.	Pure unit tests for DSL/config/projection serialization/query option normalization.
	2.	Integration tests for Ecto + Postgres + Oban + engine, because the queue/database boundary is the real integration surface. Oban’s own docs explicitly frame queues as the integration point and provide test helpers.  ￼
	3.	Contract tests against real engine containers. Typesense’s docs explicitly recommend E2E tests with real instances in GitHub Actions and also document Testcontainers-based integration testing.  ￼
	4.	Failure-path tests for engine down, lagging/not-ready, delete-after-row-removal, alias swap rollback, retry dedupe, and batch partial failures. Typesense and Meilisearch docs both give you enough operational edge cases to make these real rather than hypothetical.  ￼

Given your testing preferences, I would keep the specs flat and explicit:
	•	minimal nesting,
	•	setup inline unless it is truly repetitive,
	•	helper functions for obvious boilerplate only,
	•	very little before setup,
	•	no overly clever shared examples except for adapter contract suites.

For CI/CD, I would run:
	•	Elixir/OTP matrix,
	•	Postgres matrix if you claim version support,
	•	engine matrix for supported Typesense and Meilisearch versions,
	•	static analysis (format, Credo, Dialyzer),
	•	integration tests with Docker service containers,
	•	local reproducibility with act,
	•	release smoke test that boots a sample Phoenix app against the engine.

That is exactly the kind of project where Dockerized integration tests pay off.

What I would actually build as v1

If this were my library, v1 would be:
	•	use MyLib.Searchable or explicit projection modules
	•	Postgres/Ecto source-of-truth model
	•	first-class Oban integration
	•	Typesense adapter first
	•	versioned collections + alias swap
	•	bulk flusher
	•	full reindex/backfill command
	•	per-tenant filtering and signed search credentials
	•	rich Telemetry events
	•	LiveDashboard page + Oban Web docs
	•	great failure messages and upgrade docs

And I would make these explicitly non-goals for v1:
	•	hidden global callbacks on every repo write
	•	pretending all engines have identical feature sets
	•	auto-magic schema migration without alias swap
	•	full-blown search UI helpers
	•	vector/RAG abstraction across engines

You can add Meilisearch as v1.1/v2 once the core adapter contract is solid.

My concrete recommendation

For this project, given your stated priorities, I would do this:

Architecture bet:
Postgres + Ecto + Oban + Telemetry as the permanent spine.

Product bet:
Phoenix-first, Ecto-general second. Optimize the happy path for Phoenix SaaS apps.

Engine bet:
Ship Typesense first for the “simple self-hosted ops + OSS HA + clean production docs” story. Add Meilisearch second for the “larger momentum, stronger cloud, bigger public ecosystem” story.  ￼

DX bet:
Be more like Searchkick/Scout on ergonomics, but more explicit like Ecto/Oban on transactions and failure handling.  ￼

Ops bet:
Make Oban Web + LiveDashboard the primary admin plane, and engine dashboards secondary.  ￼

Testing bet:
Adapter contract suite + real-service integration tests in Docker/GitHub Actions from day one.  ￼

If you want, next I can turn this into a concrete library blueprint: module layout, behaviours, public API, supervision tree, telemetry event names, Oban job taxonomy, and a spec/test matrix.