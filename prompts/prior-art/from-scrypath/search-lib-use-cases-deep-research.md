I made a clean, citation-free brief you can drop into LLM coding sessions here: elixir_search_lib_research_brief.md￼

My sourced take after digging through the ecosystem:

1) The real gap

The gap in Elixir is not “there is no search client.” The real gap is “there is no Ecto-aware projection + sync + reindex layer with great DX.” That distinction matters because today there is a community Typesense Elixir client, and it already supports indexing/searching Ecto-backed schemas; Meilisearch still does not list an official Elixir SDK, while meilisearch-ex is a community API client. What’s still missing is the Searchkick / Scout layer: declarative schema integration, automatic lifecycle sync, background-safe deletes, reindex orchestration, and multi-tenant-aware ergonomics.  ￼

A quick popularity snapshot helps size the landscape: Searchkick is at 6.7k stars; algoliasearch-rails 419; meilisearch-rails 355; django-elasticsearch-dsl 1.1k; django-haystack 3.8k. On the Elixir side, meilisearch-ex is 49 stars, ex_typesense 47, and algoliax 66. That backs up the intuition that Elixir has pieces, but not yet a category-defining integration layer.  ￼

2) Best reference implementations

Searchkick is the benchmark for developer experience. Its value is not just search quality; it compresses adoption into “put one declaration on the model and go.” It ships misspellings, synonyms, autocomplete, “did you mean,” personalization, and zero-downtime reindexing, and it supports multiple sync strategies: inline, async, queue, and manual. That is the closest thing to the product shape you want. Its weakness is just as important: association changes are not auto-synced; users must wire callbacks manually.  ￼

Laravel Scout is the cleanest architectural template. It is intentionally driver-based, attaches to models with a trait, uses observers to keep indexes in sync, strongly encourages queues, exposes an explicit projection hook with toSearchableArray, supports conditional updates with searchIndexShouldBeUpdated, and even allows per-model engine selection via searchableUsing. Scout also ships database and collection engines, which is interesting not because you should copy them in v1, but because it shows a clean split between “common model integration” and “engine adapter.”  ￼

Meilisearch Rails and AlgoliaSearch Rails are the best operational teachers. They both cover background queue integration, conditional indexing, shared indexes, and the ugly-but-real delete race where the DB row is gone before the async delete job runs. Both projects explicitly recommend bypassing ORM reloads and deleting directly from the index in that case. Meilisearch Rails also makes the association problem explicit with touch / after_touch, which is a strong signal that dependency propagation should be a first-class concept in your API, not an undocumented edge case.  ￼

Hibernate Search is the best source of “serious indexing system” ideas. The two ideas worth stealing are: mass indexing is a first-class workflow with batching / parallelism / multi-tenant support, and reindex dependencies are explicit enough to say “reindex when the relation pointer changes, but not when the associated object mutates” via ReindexOnUpdate.SHALLOW. That is far beyond what most Rails-style libs do, but it is exactly the kind of correctness model that would make an Elixir library feel unusually production-grade.  ￼

Haystack is the cautionary tale. It won adoption as a modular, backend-agnostic abstraction, but Open edX’s own architecture note says the Haystack layer was ripped out because it became an obstacle to upgrades and efficient use of Elasticsearch. That is the clearest warning against over-generalizing your adapter API.  ￼

3) What to copy

Copy the one-line schema declaration pattern. Searchkick and Scout both win because the first mile is tiny: one macro/trait on the model, and the rest feels native. For Elixir, that means use MyApp.Searchable on an Ecto schema should be the canonical entry point.  ￼

Copy the multiple sync strategies idea. Searchkick’s inline / async / queue / manual split is excellent product design because different workloads want different consistency/performance tradeoffs. Phoenix apps will want at least :inline, :oban, :manual, and probably a :bulk mode for migrations / imports.  ￼

Copy the explicit projection hook. Scout’s toSearchableArray, Algoliax’s build_object, and Searchkick’s search_data all make one thing clear: field lists alone are not enough. A serious library needs an explicit “project Ecto row -> search document” hook.  ￼

Copy the idea that reindexing is a product surface, not a maintenance script. Searchkick exposes reindex workflows; Meilisearch Rails has reindex!; Typesense documents alias-based zero-downtime schema changes with dual writes and alias cutover; Meilisearch documents swap-index workflows. Your Elixir lib should treat rebuild/cutover/cleanup as first-class APIs.  ￼

Copy the escape hatch pattern. Scout allows per-model engines, Meilisearch Rails exposes the underlying index object, and Typesense explicitly frames many SDKs as thin wrappers over HTTP. Your common API should cover the 80% case, but every adapter must expose raw engine options for the last 20%.  ￼

4) What to avoid

Do not hide association propagation behind magical promises. Searchkick says related updates are not auto-synced; Meilisearch Rails requires explicit touch / after_touch. Your library should make dependencies declarative, maybe with something like depends_on: or reindex_related:. Silent staleness is worse than explicit ceremony.  ￼

Do not make async delete jobs reload the source row. Meilisearch Rails and AlgoliaSearch Rails both call out the RecordNotFound problem. Delete jobs need enough payload to remove the document directly from the index after the DB commit.  ￼

Do not market index prefixes alone as your “multi-tenancy solution.” Meilisearch’s official guidance for shared-index SaaS scenarios is tenant tokens with embedded filters; Typesense’s equivalent is scoped API keys with embedded filter_by. Prefixes are still useful for env/app partitioning, but they are not authorization.  ￼

Do not flatten Meilisearch and Typesense into a fake universal engine. Meilisearch has async task queues, task statuses, batched async writes, and atomic index swaps; Typesense’s zero-downtime story is alias-based and explicitly involves dual writes during schema changes. A common core is good; pretending the engines are the same is not.  ￼

Do not treat settings as cheap metadata changes. Meilisearch explicitly warns that changing searchable/filterable/sortable attributes, stop words, synonyms, or typo tolerance can trigger a full reindex, and recommends configuring settings before loading documents. That means your DSL should separate “settings change” from ordinary sync and should be able to say “this change requires reindex.”  ￼

5) Product strategy I would recommend

Position it as: “Searchkick DX for Elixir, Scout-style architecture, adapter-specific power, Oban-native operations.” That is sharper than “client for Meilisearch/Typesense,” and it describes the real job the library does.  ￼

Architecturally, model the system around projection + synchronization, not “search requests.” In practice that means: Ecto row is source of truth; search_document/1 builds a derived read model; Oban transports indexing work; adapters translate a common contract into backend-native operations; reindex is a separate orchestration workflow. That mirrors what the best libraries expose implicitly, while staying honest about engine differences.  ￼

For multi-tenancy, I would use two layers: index_prefix for environment/app partitioning, and tenant_scope for data isolation. On Meilisearch, that should map to tenant tokens / filtered searches; on Typesense, to scoped API keys / embedded filter_by.  ￼

I would also return both raw hits and hydrated records. Search libraries that only return ORM rows hide ranking/facet metadata; libraries that only return raw hits make app integration clumsy. Your result type should keep both. Meilisearch Rails’ federated search metadata and Scout’s raw-results-oriented design both point in that direction.  ￼

6) JTBD / personas

Phoenix SaaS engineer: “I already have Ecto schemas and Oban. I want search by adding a small declaration, not by designing an indexing subsystem.” This persona values low setup friction, eventual-consistency defaults, and safe reindex tooling. Searchkick and Scout both succeed because they serve exactly this job.  ￼

Admin/backoffice engineer: “I need fast search over users, orders, accounts, or tickets with filters and sort, and I need it to map back to my normal Ecto flows.” This persona wants typo tolerance, filterable/sortable fields, and hydration back into app records. Meilisearch and Typesense both support this well at the engine level; the missing piece is the Elixir integration layer.  ￼

Marketplace/catalog engineer: “I need user-facing search for products, listings, or content.” This persona cares about autocomplete, relevance tuning, facets, synonyms, typo tolerance, and zero-downtime rebuilds after search schema changes. Searchkick is especially strong here, and Typesense/Meilisearch both have credible modern engine capabilities for it.  ￼

Multi-tenant platform engineer: “I need shared infrastructure, but tenant-safe search access.” This persona wants tenant scoping, scoped credentials, and a clean mental model for authorization. Official docs from both Meilisearch and Typesense show that this is a first-class use case, so your lib should acknowledge it directly instead of leaving it as “you can prefix index names.”  ￼

Platform/infra engineer: “I need rebuilds, retries, observability, and no 2am surprises.” This persona cares less about query sugar and more about idempotency, job payload design, bulk import, cutover, and progress tracking. Hibernate Search is the best external reference for this operator persona.  ￼

7) Domain language I’d standardize on

Core nouns: searchable schema, source record, projection, document, document id, backend, logical index, physical index/collection, alias, settings, sync job, batch, reindex plan, tenant scope, scoped credentials, raw hit, hydrated result, facet counts, drift, cutover. These terms fit the common ground across Searchkick/Scout/Meilisearch/Typesense without hiding backend-specific concepts.  ￼

Verbs: project, upsert, delete, enqueue, sync, backfill, reindex, rebuild, swap, alias, search, facet, filter, sort, hydrate, scope, reconcile. These verbs map cleanly to actual engine operations and operational workflows.  ￼

Events: source_inserted, source_updated, source_deleted, sync_requested, upsert_enqueued, delete_enqueued, sync_succeeded, sync_failed, settings_changed, settings_reindex_required, reindex_started, reindex_completed, alias_swapped, tenant_scope_applied, search_executed. This is the event vocabulary I’d use in Telemetry, logs, and docs. It mirrors the real lifecycle exposed by engine docs and the better ORM integrations.  ￼

8) My recommended v1

The v1 feature bar should be: use Searchable on Ecto schemas, explicit projection hook, :inline | :oban | :manual sync modes, insert/update/delete sync, safe async delete semantics, bulk backfill, zero-downtime reindex, small common query API, raw-hit + hydrated-record results, index_prefix, tenant_scope, and Telemetry. That would already cover the biggest unmet need in Phoenix SaaS apps.  ￼

The things I would not put in v1 are analytics, vector search, hybrid retrieval, federated search sugar, or heavy UI helpers. Searchkick got big partly because it nailed the boring operational core first; the same is true of Scout. Get declaration, sync, query, and reindex right before adding search-adjacent extras.  ￼

My blunt synthesis: build Scout’s architecture, target Searchkick’s delight, learn operations from Meilisearch Rails + AlgoliaSearch Rails, borrow dependency/reindex ideas from Hibernate Search, and avoid Haystack’s over-abstraction trap. That feels like the highest-probability path to a genuinely important Elixir OSS library.  ￼

If you want, next I can turn this into a concrete API/design spec for the Elixir library itself: modules, behaviours, Oban jobs, adapter contracts, Telemetry events, and the exact public DSL.