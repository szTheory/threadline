Below is a distilled, high-signal Ecto / Phoenix / Plug best-practices brief aimed at building an auth library and also at serving as good LLM context.

I biased toward current primary sources: Ecto 3.13.5 docs, Ecto SQL 3.13.5 docs, Phoenix 1.8.5 guides, Phoenix auth docs, and a small number of high-quality ecosystem articles. Where I make a recommendation, it is either directly grounded in those docs or clearly labeled as a synthesis.  ￼

Executive summary

The healthiest way to use Ecto in Phoenix is: keep schemas thin, keep changesets focused on casting/validation/constraint mapping, keep orchestration in context functions, keep cross-row / cross-table invariants in the database plus transactions, compose queries as data, preload explicitly, use Repo.transact/2 or Ecto.Multi for multi-step writes, and lean on the database for correctness rather than trying to re-implement integrity in Elixir. Phoenix’s own context guides also push you toward isolated boundaries where controllers/LiveViews call context APIs instead of poking schemas and repos directly.  ￼

For an auth library specifically, the most important Ecto themes are: model credentials/tokens separately from the user record when appropriate, store security-sensitive invariants in the DB, redact secret fields, avoid lazy assumptions about associations, make token/session revocation transactional, and design for case-insensitive identifiers and concurrent writes. Phoenix’s mix phx.gen.auth notably tracks sessions/tokens in a separate table, invalidates them on password change, and uses case-insensitive email lookup patterns such as citext on PostgreSQL.  ￼

⸻

1) Core mental model: what Ecto is good at

Ecto is deliberately split into four concerns: Repo for persistence, Schema for shape, Query for reading, and Changeset for changing/validating data. That separation is not cosmetic; a lot of good Ecto design comes from preserving it instead of collapsing everything into “model objects” the way ActiveRecord-style systems often do. Queries are composable data structures and do not hit the database until passed to the repo.  ￼

Practical implication: do not build an auth library that treats schemas as all-in-one domain objects with implicit persistence and hidden side effects. Treat schemas as data shapes, changesets as input/change tracking, queries as composable selectors, and context/service functions as the orchestration layer. That maps much better to Ecto’s design than “fat model” ports from Rails/Devise land.  ￼

⸻

2) Architectural best practices

2.1 Put your public API at the context boundary, not on schemas

Phoenix’s guides explicitly position contexts as the public boundary and note that callers such as controllers should not reach into Schema.changeset/2 directly; instead, they should go through context functions like Accounts.create_user/1 or Catalog.create_product/1.  ￼

Best practice
	•	Expose public operations from your auth context, not from schema modules.
	•	Treat changeset/2 functions as implementation details unless you intentionally want them public.
	•	Give the library a narrow, semantic API like:
	•	register_user/1
	•	authenticate/2
	•	issue_session_token/2
	•	revoke_session/1
	•	change_password/2
	•	confirm_identity/2

Anti-pattern
	•	Controllers, plugs, LiveViews, or app code directly calling Repo.insert(User.changeset(...)).
	•	External callers constructing internal schemas/changesets ad hoc.
	•	“Service object” sprawl that bypasses the context boundary and turns every operation into a bespoke transaction script.

2.2 Keep schemas thin

Schemas should describe fields, associations, embeds, maybe a few helpers, but not become the dumping ground for business workflows. Ecto schemas are regular structs for mapping external data, and Phoenix contexts are the preferred place for grouping functionality.  ￼

Good fit for schema modules
	•	field/association/embed declarations
	•	casting & validation helpers
	•	tiny domain-normalization helpers
	•	schema-local changesets for create/update variants

Bad fit
	•	sending emails
	•	auditing side effects
	•	revoking sessions
	•	reaching across multiple aggregates/tables
	•	authorization policy
	•	request-specific branching

2.3 Use explicit boundaries between web layer and data layer

Phoenix’s context docs emphasize isolated boundaries because they reduce coupling as the app grows. In practice, your Plug/Phoenix layer should translate HTTP/session/form concerns into calls on your context, and the context should return domain results or changesets, not conn-specific logic.  ￼

For a library: keep Plug/Phoenix integration optional adapters over a framework-agnostic core. The Ecto/data layer should not depend on controller semantics.

⸻

3) Changeset best practices

3.1 Use changesets for input filtering, casting, validation, and DB constraint translation

That is exactly what Ecto.Changeset is for. Changesets filter/cast params, validate changed fields, and annotate database constraints so DB errors become changeset errors.  ￼

Best practice
	•	Separate changesets by intent:
	•	registration changeset
	•	profile update changeset
	•	password change changeset
	•	token creation changeset
	•	Keep permitted fields explicit.
	•	Normalize fields in the changeset pipeline, for example email downcasing before uniqueness constraints. Ecto docs explicitly show downcasing before unique_constraint/3 if the DB itself is not doing case-insensitive handling.  ￼

Anti-pattern
	•	“One giant changeset” used for create/update/admin/internal/system operations.
	•	Validating fields that were never cast for that use case.
	•	Treating changesets as persistence-independent “form objects” while also stuffing transaction logic into them.

3.2 Let the database own uniqueness and referential integrity

foreign_key_constraint/3 and unique_constraint/3 exist precisely so you can rely on the DB and translate failures into user-facing errors. unsafe_validate_unique/4 exists, but its name is a warning: it can improve UX, but it is not the real guarantee.  ￼

Best practice
	•	Use DB constraints as the source of truth.
	•	Optionally add unsafe_validate_unique/4 for friendlier early feedback, but always pair it with a real unique index + unique_constraint/3.  ￼

Anti-pattern
	•	“Check then insert” uniqueness logic without a unique index.
	•	Treating unsafe_validate_unique/4 as sufficient for race-free correctness.

3.3 Use different changesets for external vs internal data

Ecto docs draw a sharp distinction here: cast_assoc/3 is for receiving external data for the whole association, while put_assoc/4 is for working with already-structured internal data. build_assoc/3 + cast/4 is also explicitly recommended when starting from a known parent and external child params.  ￼

Rule of thumb
	•	Request params → cast/4, cast_assoc/3, cast_embed/3
	•	Internal structs/IDs/domain decisions → put_assoc/4, direct FK assignment, or build_assoc/3

Anti-pattern
	•	Using cast_assoc/3 for every association update even when you already have internal structs.
	•	Using put_assoc/4 to stuff untrusted request data into associations.

3.4 Prefer intent-specific changesets over “optional everything”

Newer Ecto added helpers like changed?/2, field_missing?/2, get_assoc/get_embed, and improved empty-value handling, partly to make complex forms and LiveView flows more expressive. That supports more precise changeset design rather than giant generic pipelines.  ￼

Best practice
	•	Treat registration, password reset, email change, MFA enrollment, invitation acceptance, and admin mutation as distinct write paths.
	•	Use intent-specific changesets even if they target the same schema.

⸻

4) Query best practices

4.1 Build composable queries, not repo calls hidden everywhere

Queries in Ecto are composable and safe. The dynamic queries guide explicitly shows how to separate param processing from query generation using dynamic/2.  ￼

Best practice
	•	Write query-builder functions that return Ecto.Query.
	•	Keep Repo.* at the edges: context functions, repos, adapters.
	•	Compose small scopes:
	•	by_email/2
	•	active_sessions/1
	•	expired_tokens/1
	•	for_tenant/2
	•	confirmed/1

Anti-pattern
	•	Burying Repo.one/Repo.all inside query helpers.
	•	Building giant conditionals with duplicated queries instead of dynamic/2.

4.2 Preload explicitly; Ecto does not lazy load associations

Ecto explicitly notes that it does not lazy load associations, and that lazy loading becomes a source of confusion and performance issues.  ￼

Best practice
	•	Make preloads explicit and intentional.
	•	Return exactly the shape the caller needs.
	•	Be especially strict in library code: avoid returning partially-loaded structs that encourage accidental misuse.

Anti-pattern
	•	Assuming user.sessions or user.identities is available unless preloaded.
	•	Hiding preloads deep in helper functions so callers cannot predict query behavior.

4.3 Use joins/selects when you only need a subset

Ecto supports selecting maps/structs/fields instead of loading whole structs. This helps avoid overfetching. Also note :load_in_query can exclude fields from default “select whole struct” loading, which is useful for heavy or sensitive columns.  ￼

Best practice
	•	Select only what you need in hot paths.
	•	For sensitive or bulky fields, consider load_in_query: false so they are not implicitly pulled in broad selects.  ￼

Anti-pattern
	•	Always Repo.get! full structs with many large fields/embeds when you only need an ID or status.
	•	Returning fully-loaded auth entities with secret-ish operational columns by default.

4.4 Use schemaless operations for bulk work, not per-row changesets

Ecto explicitly supports schema-free bulk operations like insert_all/3, update_all/3, and delete_all/2. These are often the right tool for token cleanup, revocation sweeps, or large backfills.  ￼

Best practice
	•	For bulk revocations / expiry cleanup / maintenance jobs, prefer set-based operations.
	•	Reserve row-by-row changesets for domain writes that need validations/hooks.

Anti-pattern
	•	Iterating and updating thousands of rows one changeset at a time when a single update_all/delete_all would do.

⸻

5) Association best practices

5.1 Use explicit join schemas when the relationship has meaning

Ecto supports plain many_to_many, but once the join has metadata, lifecycle, defaults, auditing, ordering, or constraints, an explicit join schema is usually the healthier design. Ecto’s guides around many-to-many and self-referencing relationships also emphasize stronger naming and structure for maintainability.  ￼

For auth, this often means:
	•	users ↔ identities
	•	users ↔ sessions
	•	users ↔ roles
	•	users ↔ organizations through memberships
	•	users ↔ devices

Anti-pattern
	•	Hiding meaningful security state in a raw many-to-many join table with no schema.

5.2 Preload before cast_assoc updates

Ecto docs are explicit: when updating associated data with cast_assoc/3, the existing association should be preloaded so Ecto can match incoming params against already-loaded data.  ￼

Anti-pattern
	•	Updating nested forms with cast_assoc on stale/unpreloaded parents.

5.3 Prefer direct FK assignment or build_assoc for simple child creation

Ecto docs show that if you have the parent already, build_assoc/3 is often the straightforward choice; or you can simply set the FK directly. put_assoc/4 is better when you are replacing/managing the association as a whole.  ￼

Anti-pattern
	•	Using put_assoc for every child insert when all you needed was user_id.

⸻

6) Transactions and consistency

6.1 Use Repo.transact/2 for multi-step writes; use Ecto.Multi when the operation graph is dynamic or introspection helps

Repo.transaction/2 is deprecated in favor of Repo.transact/2. Ecto docs also explicitly say Ecto.Multi is especially useful when the set of operations is dynamic; for many other cases, regular control flow inside Repo.transact(fn -> ... end) is more straightforward.  ￼

Best practice
	•	Use Repo.transact(fn -> ... end) for simple linear workflows.
	•	Use Ecto.Multi for:
	•	dynamic chains of operations
	•	named step failures
	•	better introspection/testing
	•	clearer dependency wiring across steps

Anti-pattern
	•	Reaching for Ecto.Multi for every two-step operation.
	•	Splitting logically atomic auth workflows across multiple independent repo calls.

Auth examples that should be transactional
	•	register user + create primary identity + create confirmation token
	•	change password + invalidate all active tokens/sessions
	•	magic-link consume + single-use token revoke + session issue
	•	accept invitation + create membership + audit record

6.2 Prefer DB-enforced correctness to app-level “best effort”

Transactions help, but correctness still belongs in the DB when possible: unique indexes, FKs, check constraints, exclusion constraints, partial indexes. Ecto migrations support check and exclusion constraints, partial indexes, and nulls_distinct: false for unique indexes on PostgreSQL 15+.  ￼

Anti-pattern
	•	“We enforce this in app code, so we don’t need a constraint.”
	•	Performing revocation/consumption steps without a transaction or uniqueness guard.

6.3 Use optimistic locking where concurrent editing is plausible

Ecto supports optimistic_lock/3, and stale updates raise Ecto.StaleEntryError.  ￼

Good fit
	•	user profile edits
	•	admin edits of config-like auth records
	•	some security settings records

Less useful
	•	one-shot append-only token/session/event rows

⸻

7) Migration and database design best practices

7.1 Treat migrations as database evolution, not as your domain model

Ecto SQL migrations are about schema changes over time. They support check/exclusion constraints, partial indexes, reversible remove forms, and newer conveniences like add_if_not_exists, while also documenting when those conveniences are not reversible.  ￼

Best practice
	•	Encode data integrity in the DB:
	•	FK constraints
	•	unique indexes
	•	check constraints
	•	partial indexes for stateful uniqueness
	•	Be explicit about reversibility.
	•	Prefer safe multi-step migrations for production changes.

7.2 Use partial indexes and nullable uniqueness intentionally

Ecto’s migration docs explicitly note that normal unique indexes allow multiple NULLs in most databases, and on PostgreSQL 15+ nulls_distinct: false can change that. Otherwise, partial unique indexes are the workaround.  ￼

Auth-relevant examples
	•	unique confirmed email among non-deleted accounts
	•	one active primary identity per provider per user
	•	one non-revoked recovery token of a given kind

7.3 Use database-native case-insensitive identifier handling where possible

Phoenix phx.gen.auth uses citext on PostgreSQL for case-insensitive email lookup.  ￼

Recommendation for an auth lib
	•	Prefer DB-native case-insensitive semantics where supported.
	•	Otherwise normalize aggressively before uniqueness checks.

7.4 Be careful with data migrations and bulk backfills

Fly’s Ecto migration series stresses that bulk changes should be reviewed, efficient, safe to re-run, and ideally not be done ad hoc in a console; repeated operational data migrations may deserve a more observable system than raw Ecto.Migrator.  ￼

Anti-pattern
	•	Huge row-by-row data rewrites in a single deploy migration with no rollback plan.

⸻

8) Embedded schemas, schemaless changes, and form modeling

8.1 Use embedded_schema for non-persisted or cross-table form state

Ecto’s embedded schema guide explicitly recommends embedded schemas for intermediate-state data, forms that map to multiple tables, or entities not backed by a table.  ￼

Great auth use cases
	•	registration wizard state
	•	login challenge state
	•	MFA enrollment confirmation payload
	•	password reset submission
	•	invitation acceptance payload
	•	admin “create user + membership + identity” composite forms

Anti-pattern
	•	Creating fake tables or overloading persisted schemas just to validate temporary UI state.

8.2 Newer Ecto features are especially helpful for complex LiveView forms

Ecto 3.10 added get_assoc, get_embed, field_missing?, changed?, and sort_param/drop_param support for cast_assoc/cast_embed, explicitly called out as helpful for more complex forms, especially embedded within Phoenix.LiveView apps.  ￼

Implication
	•	If your library ships LiveView-ready components, model complex nested state with embeds and use modern changeset helpers instead of hand-rolling diff logic.

⸻

9) Security-sensitive Ecto practices for auth libraries

9.1 Redact secrets in schemas

Ecto supports redact: true on fields, and @schema_redact :all_except_primary_keys to redact broadly. Redacted fields are hidden in inspect output and changesets.  ￼

Use this for
	•	raw passwords
	•	password hashes if you want them hidden in inspect
	•	OTP secrets
	•	recovery secrets
	•	token digests if logging risk matters

9.2 Consider load_in_query: false for sensitive or heavy fields

Ecto supports load_in_query: false, which keeps fields from loading in whole-struct selects by default.  ￼

Great fit
	•	password hash
	•	TOTP secret / WebAuthn credential material
	•	large audit blobs
	•	device attestation data

This is not a security boundary by itself, but it reduces accidental exposure and overfetching.

9.3 Consider :writable on fields for stronger invariants

Ecto 3.13’s schema docs include :writable with :always, :insert, and :never.  ￼

Interesting auth uses
	•	immutable external subject IDs from identity providers
	•	immutable signup origin/provider IDs
	•	fields that should only ever be system-set once

This is newer and easy to overlook; it is one of the more useful modern Ecto features for auth-domain invariants.  ￼

9.4 Track sessions/tokens as first-class rows, not just opaque blobs in cookies

Phoenix’s auth generator tracks sessions and tokens in a separate table and deletes them on password change.  ￼

Recommendation
	•	Model sessions/tokens as data:
	•	user_id
	•	context
	•	inserted_at / expires_at
	•	revoked_at / consumed_at
	•	device/user-agent/IP metadata if desired
	•	This makes revocation, device management, auditability, and invalidation consistent and transactional.

⸻

10) Multi-tenancy and prefixes

Ecto has two major multi-tenant patterns documented: query prefixes (separate schemas/databases) and tenant foreign keys. Prefixes give stronger isolation but are expensive because each tenant needs structure/migrations/versioning; foreign-key tenancy is cheaper and relies on disciplined scoping such as an org_id. Ecto also documents repo hooks like prepare_query/3 and default_options/1 that can help enforce default query options/scoping.  ￼

Recommendation for an auth library
	•	Default to FK-based tenancy unless the app truly needs schema-per-tenant isolation.
	•	Provide a clean tenant-scoping story:
	•	explicit org_id
	•	query helpers/scopes
	•	optional repo hooks for enforcement
	•	Be cautious with prefixes in a library unless you can support tenant migrations and operational complexity well.

⸻

11) Testing best practices

Phoenix’s testing guide and Ecto SQL tooling center on SQL Sandbox-based isolation; Phoenix generators use sandbox owner patterns and concurrent tests where the DB supports it.  ￼

Best practice
	•	Use SQL Sandbox for DB isolation.
	•	Keep context tests mostly integration-level with the DB.
	•	Test changesets for validation semantics.
	•	Test context functions for transactional semantics.
	•	Test race-prone flows around uniqueness/token consumption with DB constraints, not only unit mocks.

Anti-pattern
	•	Over-mocking the repo so you never test actual constraints or transactions.
	•	Treating auth correctness as pure unit logic divorced from database behavior.

⸻

12) Common Ecto anti-patterns

12.1 Porting Rails “fat model” habits directly

Ecto is not ActiveRecord. If you cram queries, persistence, side effects, web concerns, and cross-context orchestration into schema modules, you end up fighting the library.  ￼

12.2 Using exceptions for normal control flow

Elixir’s anti-pattern docs explicitly call out exceptions-for-control-flow as an anti-pattern; prefer tuples and pattern matching. That applies strongly to repo workflows too.  ￼

Bad
	•	Repo.get_by! for “not found” in routine auth lookup paths
	•	rescuing DB exceptions as regular branching

Good
	•	Repo.get_by
	•	{:ok, value} | {:error, reason}
	•	with / case

12.3 Relying on application checks instead of constraints

Especially bad in auth, where concurrency and race conditions are real.  ￼

12.4 Implicit data loading assumptions

Ecto does not lazy load. Returning structs that callers assume are complete is a footgun.  ￼

12.5 Overusing nested writes

cast_assoc and put_assoc are powerful, but deep nested writes can become hard to reason about, especially in auth/security flows. Prefer explicit steps and transactions when invariants matter more than form convenience.  ￼

12.6 Soft delete everywhere by habit

José Valim’s 2024 write-up notes app-level soft delete is error-prone because you must remember to filter every query and account for cascades; DB-level approaches are more robust when soft delete is central to the app.  ￼

Auth-specific note
	•	For sessions/tokens, revocation fields often beat generic “soft delete”.
	•	For users/identities, soft delete may be valid, but design uniqueness/indexing around it carefully.

⸻

13) Recommended defaults for an auth library built on Ecto

This section is synthesis based on the sources above.

Data model shape
	•	users
	•	identities or credentials table separate from users
	•	user_tokens / sessions table separate from users
	•	optional memberships for org scoping
	•	optional audit_events

Grounding: Phoenix auth generator already treats sessions/tokens separately, and Phoenix’s contexts guide itself discusses the benefits of not coupling credentials too tightly to the account.  ￼

API shape

Public API on a context module:
	•	register_user/1
	•	change_user_email/2
	•	change_user_password/2
	•	generate_session_token/1
	•	get_user_by_session_token/1
	•	delete_session_token/1
	•	consume_magic_link_token/1
	•	revoke_all_sessions/1

Ecto style
	•	separate create/update/security changesets
	•	explicit preloads
	•	explicit query builders
	•	Repo.transact/2 for simple workflows
	•	Ecto.Multi for dynamic/multi-step flows
	•	DB constraints everywhere correctness matters
	•	secret fields redacted
	•	consider load_in_query: false and writable: :insert/:never for sensitive/immutable fields

DB style
	•	case-insensitive identifiers
	•	unique indexes for identities/tokens where applicable
	•	partial indexes for active-only uniqueness
	•	FK constraints
	•	check constraints for status/state coherence
	•	set-based cleanup for expired/revoked tokens

⸻

14) LLM-ready distilled guidance block

You could feed this almost verbatim into an implementation assistant:

Use Ecto in its intended split: contexts expose the public API; schemas define data shape; changesets cast/validate/annotate DB constraints; queries are composable data; repos execute at the edges. Do not port ActiveRecord “fat model” design. Use explicit preloads; Ecto does not lazy load. Use cast_assoc/cast_embed for external nested params and put_assoc/direct FK assignment/build_assoc for internal structured data. Rely on DB constraints for truth (unique_constraint, foreign_key_constraint, check constraints, unique indexes, partial indexes); unsafe_validate_unique is only UX sugar. Use Repo.transact/2 for simple atomic workflows and Ecto.Multi when operation graphs are dynamic or named failure points help. Prefer intent-specific changesets over one giant schema changeset. Use embedded_schema for transient or cross-table form state. For auth, model sessions/tokens/identities as first-class tables, redact secrets, consider load_in_query: false for sensitive fields and writable: :insert/:never for immutable fields, and encode case-insensitive identifier semantics in the DB where possible. Test against the real DB with SQL Sandbox; don’t mock away constraints and transactions.  ￼

⸻

15) Highest-value source set

If you want the minimum source bundle to anchor future LLM-assisted work, I would keep these at the top:
	•	Ecto overview + Ecto.Query + Ecto.Changeset + Ecto.Repo docs  ￼
	•	Constraints and Upserts, Embedded Schemas, multi-tenancy guides  ￼
	•	Ecto.Multi docs  ￼
	•	Ecto.Migration docs  ￼
	•	Phoenix “Your First Context” / contexts boundary guides  ￼
	•	Phoenix mix phx.gen.auth docs for auth-specific operational patterns  ￼
	•	Dashbit soft deletes article for nuanced deletion design  ￼

If you want, I can turn this into a second-pass artifact optimized for direct LLM ingestion, like a compact “rules + anti-rules + code patterns” context pack.