Below is a high-signal guide for writing an Elixir open-source library that feels native to the ecosystem, with emphasis on library UX, public API design, code organization, integration ergonomics, Phoenix friendliness where relevant, and anti-patterns to avoid. I’m intentionally skipping generic Elixir/Phoenix advice and focusing on what makes an OSS library feel first-class to Elixir users. The recommendations are grounded primarily in the official Elixir/HexDocs guidance, ExDoc/Hex docs, and ecosystem standards like Telemetry and Plug.  ￼

Executive summary: what Elixir library users expect

A top-tier Elixir OSS library usually has these traits:
	•	a small, explicit, stable public API
	•	non-raising + raising variants where failure is routine vs exceptional
	•	data-first APIs over magical DSLs/macros
	•	runtime options passed explicitly, not hidden global config
	•	clear supervision / child_spec story if processes are involved
	•	excellent docs with copy-pasteable examples, guides, and integration notes
	•	easy observability via Logger and preferably Telemetry
	•	predictable namespacing, no namespace squatting
	•	minimal compile-time coupling
	•	backwards-compatible evolution with a disciplined deprecation story
	•	Hex package hygiene: metadata, docs, changelog, slim package contents, sane dependency bounds.  ￼

For your use case—an OpenSearch client library for Elixir—that means: explicit request/response structs or maps, low-magic transport/client abstractions, validated options, optional supervision, first-class error types, good docs for Phoenix integration, stable Telemetry events, and a careful split between core client, transport, and integration helpers. This is exactly the kind of library where Elixir consumers care a lot about API clarity and operational ergonomics.  ￼

⸻

1) Design the public API like an Elixir library, not like a port of another language SDK

Prefer explicit functions over “SDK object magic”

Elixir users generally want APIs they can read locally. The official library guidance strongly prefers clarity over implicit behavior, and warns against unnecessary macros and hidden code injection. A library should not force users into a DSL when plain modules/functions are enough.  ￼

For an OpenSearch lib, prefer shapes like:

OpenSearch.search(client, index, query, opts \\ [])
OpenSearch.get_document(client, index, id, opts \\ [])
OpenSearch.index_document(client, index, document, opts \\ [])

over a highly stateful, opaque fluent interface.

Make the happy path obvious

The first thing people should see is the minimum viable flow:

client = OpenSearch.Client.new(base_url: "...", api_key: "...")
{:ok, resp} = OpenSearch.search(client, "products", %{query: %{match_all: %{}}})

That should work without needing a supervisor, app config, macros, or Phoenix-specific setup.

Keep return types stable

The official anti-pattern docs explicitly call out alternative return types based on options as a smell. A function whose options drastically change what it returns is hard to reason about. Prefer separate functions for separate result shapes.  ￼

Bad:

OpenSearch.search(client, query, raw: true)
# raw: true => %HTTP.Response{}
# raw: false => {:ok, %OpenSearch.Response{}}

Better:

OpenSearch.search(client, query)
OpenSearch.search_raw(client, query)

Use Elixir’s bang convention correctly

The naming conventions docs are explicit: foo! means the failure case raises, usually as a raising variant of a tuple-returning function. Non-bang variants are preferred when callers want pattern matching. Invalid argument shape/type may still raise regardless.  ￼

For a client library, that usually means:

{:ok, result} | {:error, exception} = OpenSearch.search(...)
result = OpenSearch.search!(...)

This is table stakes.

Do not force exception-driven control flow

Official Elixir guidance tells library authors to provide APIs that do not require users to rescue exceptions for expected failures. The recommended pattern is non-raising tuple APIs, with bang functions layered on top. A common convention is {:ok, result} and {:error, Exception.t()}.  ￼

For an OpenSearch lib, network failures, auth failures, 404s, 409s, timeouts, and serialization issues should all be representable without rescue.

⸻

2) Make the library explicit about configuration

Avoid global application config as the primary interface

Official Elixir docs say that for libraries used by other developers, it is generally recommended to avoid the application environment because it is effectively global storage. The older official library guidelines go further: reserve app env for truly global concerns and, if you must configure, prefer runtime configuration over compile-time configuration.  ￼

For your library, prefer:

client = OpenSearch.Client.new(
  base_url: "...",
  transport: OpenSearch.Transport.Finch,
  json: Jason,
  retry: [...]
)

over:

config :opensearch, base_url: ...

App config can exist as a convenience layer, but should not be the only or primary path.

Never read other apps’ config directly

The Application docs explicitly warn not to directly read another application’s environment and explain recompilation hazards if you do.  ￼

So do not bake in assumptions like:

Application.fetch_env!(:finch, ...)
Application.fetch_env!(:jason, ...)

Instead, accept adapters/modules/options explicitly.

Avoid compile-time configuration unless absolutely necessary

Compile-time config increases brittleness and recompilation coupling. For an OSS lib, this is especially painful because users combine many deps and expect fast iteration. The docs recommend runtime env over compile-time env in libraries.  ￼

Validate options cleanly

For libraries with keyword-list options, NimbleOptions is a strong ecosystem-standard fit. Its docs explicitly position it as a standard API for keyword-list options, with schema validation and automatic doc generation. It supports compile-time schema validation via new!/1 in a module attribute and doc generation via docs/1.  ￼

That makes it ideal for:
	•	client options
	•	transport options
	•	retry/backoff config
	•	request options
	•	plugin/hook options

This is especially useful for OSS because it turns option handling into a documented contract instead of loose convention.

⸻

3) Prefer modules and functions for organization; use processes only when runtime behavior demands it

The official guidance is blunt: do not use processes for code organization. Processes should model runtime properties like concurrency, shared mutable state, resource ownership, restart/shutdown logic, etc. The process anti-pattern docs say libraries should avoid imposing specific behavior like parallelization when possible and instead let callers decide.  ￼

For an OpenSearch library:

Usually core request building should be pure

Things like:
	•	URL construction
	•	query/body encoding
	•	header calculation
	•	response decoding
	•	error normalization

should mostly be plain functions.

Add processes only for real runtime concerns

Processes may make sense for:
	•	connection pooling via a transport dependency
	•	optional worker/supervisor wrappers
	•	circuit breakers / rate limiters / streaming coordination
	•	background sniffing / node discovery, if you support that

But do not make the entire client require a GenServer just to issue requests.

If you expose a process, centralize its interface

The process anti-pattern docs specifically warn against scattered process interfaces: don’t spread direct GenServer.call/3, GenServer.cast/2, Agent.get, etc. throughout the codebase. Centralize access behind one module.  ￼

So if you have OpenSearch.ConnectionPool, callers should use your wrapper functions, not raw GenServer messages.

Never spawn long-running unsupervised processes

Official guidance says long-running processes should live in a supervision tree so users control initialization, restarts, and shutdown.  ￼

If you need background workers, give users a child spec.

⸻

4) Have a clean supervision and child_spec story

Elixir users expect process-based libraries to integrate nicely into supervision trees. use GenServer defines a child_spec/1, and supervisors rely on child specs to start modules cleanly. The docs emphasize this as standard ecosystem behavior.  ￼

For a library, that means:

Either be pure and require no supervision

Best when possible.

Or provide a first-class supervised component

Example shape:

children = [
  {OpenSearch.Client, name: MyApp.OpenSearch, base_url: "...", ...}
]

And document:
	•	whether it is optional
	•	what state it owns
	•	how it restarts
	•	whether multiple instances are supported
	•	how naming works

Prefer modern child specs

Supervisor.Spec is deprecated. Use modern module-based child specs / Supervisor.child_spec/2.  ￼

Be careful with default names

Avoid hidden globals like registering everything under __MODULE__ unless that’s truly what users want. Library consumers often want multiple clients/clusters.

⸻

5) Keep the namespace clean and predictable

Official library guidance says your library should keep modules in its own namespace and avoid defining modules inside another library’s namespace. If your OTP app is :my_lib, modules should be MyLib.*. If you are extending another library, don’t squat inside its namespace.  ￼

For your project, that means things like:
	•	OpenSearch
	•	OpenSearch.Client
	•	OpenSearch.Transport
	•	OpenSearch.Error
	•	OpenSearch.API.Search
	•	OpenSearch.Response
	•	OpenSearch.Telemetry

Not:
	•	Elastic.*
	•	Finch.OpenSearch
	•	Plug.OpenSearch unless it is literally a separate Plug integration package you own under your namespace

This matters more in Elixir than many ecosystems because the BEAM only loads one module of a given name.

⸻

6) Be conservative with use, macros, and DSLs

This is one of the biggest OSS-library-specific themes in the official docs.

Do not expose use MyLib if import or normal calls are enough

The official library guidelines explicitly call out use MyLib that only imports/aliases functions as an anti-pattern. use can run arbitrary code and obscures impact; import or direct calls are clearer.  ￼

If you do expose use, document exactly what it injects

The official guidance recommends a @moduledoc admonition block—a “nutrition facts” summary of what use SomeModule does to public API, such as setting a behaviour or defining a child_spec/1.  ￼

Avoid macros unless they are genuinely necessary

The official docs say macros should be a last resort, explicit is better than implicit, and generated code should be minimal. Also, if you must use a macro, it should not be the only interface.  ￼

For an OpenSearch library, macros are probably unnecessary except maybe for optional DSL sugar. If you add DSLs, keep the function API canonical.

Watch compile-time dependency explosions

The meta-programming anti-pattern docs are especially relevant to library authors. Macros can accidentally create compile-time dependencies and large recompilation graphs. The docs explicitly discuss Macro.expand_literals/2 and recommend mix xref trace to debug dependency type.  ￼

This is a big deal for OSS libs because users hate dependencies that slow every compile.

Avoid large code generation

Again per the official anti-pattern docs: generating large amounts of code in macros slows compile and bloats artifacts.  ￼

⸻

7) Behaviours are good; make them narrow

Elixir users like behaviours when they represent a real extension point: transport adapters, serializers, auth providers, retry policies, sniffers, etc.

The official docs around behaviours and optional callbacks show the right tools: @callback, @optional_callbacks, @impl, and runtime checks with Code.ensure_loaded?/1 + function_exported?/3 for optional callbacks. The Kernel docs also recommend narrow behaviours with the minimum callbacks needed, and suggest optional callbacks over broad defoverridable-heavy designs when appropriate.  ￼

Good behaviour candidates for your library
	•	OpenSearch.Transport
	•	OpenSearch.JSON
	•	OpenSearch.RetryStrategy
	•	OpenSearch.Auth
	•	OpenSearch.Serializer

Keep callbacks minimal

Bad:

@callback init(...)
@callback prepare(...)
@callback encode(...)
@callback request(...)
@callback decode(...)
@callback handle_error(...)
@callback cleanup(...)

Good:

@callback request(method, url, headers, body, opts) ::
  {:ok, status, headers, body} | {:error, Exception.t()}

Then compose behavior with regular functions around it.

Avoid defoverridable-heavy “frameworky” base modules

That pattern often feels magical, broad, and fragile in libraries. Narrow behaviour + normal functions is usually friendlier.

Given your preference to avoid Dialyzer-heavy workflows: I’d still use @callback and a modest number of @specs where they clarify extension points and docs, but I would not center the project around elaborate typespec engineering. In Elixir OSS, specs as documentation for public contracts are useful even if you do not want a type-system-centric culture. The official language tooling around callbacks/specs exists independently of Dialyzer.  ￼

⸻

8) Errors should be first-class and pleasant to work with

Use custom exceptions for library-specific failures

The Elixir docs recommend tuple APIs plus exceptions as values for {:error, exception}. defexception is the standard way to define them.  ￼

For an OpenSearch lib, a clean error hierarchy is a major UX win:
	•	OpenSearch.Error
	•	OpenSearch.TransportError
	•	OpenSearch.APIError
	•	OpenSearch.DecodeError
	•	OpenSearch.ConfigError
	•	OpenSearch.TimeoutError

Make errors structured, not just strings

Expose relevant fields like:
	•	status
	•	error type
	•	reason
	•	index
	•	request id / opaque id
	•	cause
	•	body snippet

That makes both pattern matching and logging better.

Phoenix / Plug nicety

If any exceptions could reasonably bubble into web apps, consider supporting Plug.Exception so exceptions can be status-code aware. Plug’s protocol exists exactly for this.  ￼

This is not mandatory for every client library, but it is a polished touch if you expect use in Phoenix controllers/jobs/background pipelines where a library exception may surface in request handling.

⸻

9) Documentation is not “nice to have”; it is a core feature

Official Elixir docs explicitly say documentation is treated as a first-class citizen, and library authors are expected to provide complete API docs with examples for modules, types, and functions.  ￼

For OSS library docs, include four layers

1. README: fastest time-to-success
Should answer in under a minute:
	•	what problem this solves
	•	install
	•	minimal example
	•	optional supervision
	•	common auth modes
	•	Phoenix note
	•	link to full guides

2. API docs: precise reference
Every public module/function should have docs that explain:
	•	intent
	•	arguments
	•	options
	•	return value
	•	errors
	•	examples
	•	whether it allocates/spawns/logs/emits telemetry

3. Guides / extras
ExDoc supports extras and grouping for extras/modules/functions. This is excellent for OSS libs with more than a tiny API.  ￼

Ideal extras for your library:
	•	Getting Started
	•	Client Configuration
	•	Authentication
	•	Querying and Indexing
	•	Error Handling
	•	Telemetry / Observability
	•	Phoenix Integration
	•	Testing
	•	Upgrade / Migration Guides

4. Changelog / upgrade notes
Hex package defaults include CHANGELOG*, and Hex publish/docs workflows make versioned docs easy. Maintain a real changelog and versioned migration notes.  ￼

Use ExDoc well

ExDoc supports :source_url, :homepage_url, :main, :extras, groups for extras/modules/functions, and version-specific source links via :source_ref. That last one is especially useful so docs for version X link to code for version X, not just main.  ￼

Treat examples as part of the API contract

Doctest-able examples and short real examples matter a lot in Elixir. The writing docs guide shows how docs are attached with module attributes and examples.  ￼

⸻

10) Package like a serious Hex dependency

Hex package quality is part of library UX.

Fill in Hex metadata

Hex build config supports package metadata like :description, :licenses, :links, :files, and optionally :name.  ￼

At minimum:
	•	accurate description
	•	SPDX-ish license entry
	•	GitHub/source link
	•	changelog link
	•	docs link/homepage

Keep package contents tight

Hex defaults include useful files like lib, priv, .formatter.exs, mix.exs, README*, LICENSE*, CHANGELOG*, src, c_src, Makefile*. Use :files / :exclude_patterns intentionally.  ￼

Do not ship giant test fixtures or accidental junk.

Test publish shape locally

mix hex.publish --dry-run and mix hex.build --unpack are there for inspecting exactly what you are shipping.  ￼

Remember docs are part of the release artifact

Hex will build/publish docs, and docs can be updated independently. This lowers friction for shipping doc fixes.  ￼

⸻

11) Dependency policy matters more for libraries than apps

Official library guidelines call out two important points:
	•	dependencies only needed for dev/test should be scoped with :only
	•	optional dependencies should be marked :optional
	•	libraries should compile cleanly without optional deps, and the docs explicitly recommend testing with mix compile --no-optional-deps --warnings-as-errors
	•	your library’s mix.lock is ignored by host projects, so CI should account for resolution differences.  ￼

For your project:

Keep the mandatory dependency set small

Ideal mandatory deps are few and boring.

Prefer optional integrations

If you support Finch, Req, Tesla, Jason, MIME tweaks, Phoenix integration, telemetry metrics exporters, etc., keep many of those optional or isolated.

CI should test realistic host conditions

Because the host ignores your lockfile, you want compatibility-minded dependency constraints and CI that exercises the range you claim to support.

⸻

12) Observability is a library feature

Use Logger sparingly and structurally

Logger supports structural logging and metadata. Library logs should be:
	•	low volume
	•	diagnostic, not chatty
	•	safe for production
	•	free of secret leakage
	•	easy to correlate with metadata.  ￼

Do not log full request bodies, credentials, or giant response payloads by default.

Emit Telemetry events for stable instrumentation points

Telemetry is specifically for libraries to emit events, and telemetry_test exists because maintaining stable telemetry events is important for library authors.  ￼

For an OpenSearch lib, strong candidate events:
	•	[:opensearch, :request, :start]
	•	[:opensearch, :request, :stop]
	•	[:opensearch, :request, :exception]

Measurements:
	•	total time
	•	encode time
	•	decode time
	•	maybe retry count

Metadata:
	•	method
	•	path or route template
	•	cluster name / client name
	•	status
	•	request id
	•	retry strategy / attempt
	•	error type

The exact event schema should be documented and treated as a compatibility surface.

Don’t make logging the only observability path

In Elixir, good libs generally separate:
	•	return values for control flow
	•	exceptions for failure values
	•	logs for diagnostics
	•	telemetry for instrumentation

⸻

13) Data modeling: use structs where they add meaning

The official anti-pattern docs warn against “primitive obsession”: when structured domain data is modeled as raw strings/numbers everywhere instead of richer composite types.  ￼

For an OpenSearch library, plain maps are fine for arbitrary query DSL payloads because OpenSearch itself is map/JSON-shaped. But there are places where structs improve the API:

Good struct candidates:
	•	OpenSearch.Client
	•	OpenSearch.Request
	•	OpenSearch.Response
	•	OpenSearch.Error
	•	maybe OpenSearch.BulkItemResult

Avoid forcing structs for user-authored query bodies unless they materially simplify something. Elixir users often prefer plain maps for JSON-like request payloads.

Rule of thumb:
	•	transport/control plane: structs are good
	•	OpenSearch DSL payloads: maps are usually better

⸻

14) Be deliberate about API layers

A polished Elixir OSS lib often has a thin vertical architecture:

Layer 1: public façade

Stable, user-friendly functions.

Layer 2: request building / normalization

Pure functions.

Layer 3: transport adapter behaviour

Swappable, testable.

Layer 4: response/error normalization

Pure functions.

Layer 5: optional integrations

Phoenix, Plug, Finch child specs, telemetry helpers, etc.

This helps keep the public API stable while internal pieces evolve.

For OpenSearch, a good split is often:
	•	OpenSearch — public API
	•	OpenSearch.Client — client/config struct
	•	OpenSearch.Transport — behaviour
	•	OpenSearch.Transport.Finch — adapter
	•	OpenSearch.Request / OpenSearch.Response
	•	OpenSearch.Error
	•	OpenSearch.Telemetry
	•	OpenSearch.Testing or test helpers

This feels very idiomatic to Elixir users.

⸻

15) Phoenix friendliness without Phoenix coupling

The user asked for library best practices, with Phoenix only if applicable. For a general-purpose client lib, the right move is:

Be Phoenix-friendly, not Phoenix-dependent

Good:
	•	works in plain Mix app
	•	good docs for using inside Phoenix app supervision tree
	•	exceptions optionally implement Plug.Exception
	•	examples show use in controllers, LiveView async tasks, Oban jobs

Bad:
	•	requires Phoenix
	•	hides important behavior in framework glue
	•	assumes a web lifecycle

Avoid copying conn/socket/large structs into spawned tasks

The process anti-pattern docs warn against sending unnecessary data between processes and note that closures capture referenced variables, which can copy way more data than intended.  ￼

So if docs show async usage in Phoenix, demonstrate extracting only the data needed before the task.

⸻

16) Compatibility and evolution strategy

Keep interfaces narrow so future changes are survivable

Narrow behaviours, explicit functions, and stable event/error contracts make semver easier.

Prefer additive growth

Instead of changing a function’s return shape or option semantics, add a new function or new metadata field.

Deprecate gently

NimbleOptions can help with deprecated/renamed options. ExDoc and docs metadata can mark new APIs as since:.  ￼

Maintain versioned source links and docs

ExDoc source_ref tied to the package version is a real quality-of-life win.  ￼

⸻

17) Anti-patterns to avoid in an Elixir OSS library

This is the “rules for LLM context” section.

API / syntax anti-patterns
	•	one function whose options radically change return type
	•	only raising APIs, no tuple-returning variant
	•	booleans encoding multiple semantic states when atoms would be clearer
	•	giant catch-all options keyword lists with undocumented keys
	•	function names that violate bang semantics
	•	hiding main behavior behind use when functions would do.  ￼

library architecture anti-patterns
	•	primary config via global app env
	•	reading other apps’ config directly
	•	processes used for code organization
	•	unsupervised long-lived processes
	•	scattering raw GenServer/Agent interaction across modules
	•	making parallelism / runtime model mandatory instead of optional.  ￼

macro / compile anti-patterns
	•	exposing use MyLib for trivial imports
	•	undocumented use
	•	macro-only interface
	•	large code generation
	•	compile-time dependencies that should be runtime
	•	dynamic module name construction that breaks dependency tracking.  ￼

packaging anti-patterns
	•	weak Hex metadata
	•	no docs on HexDocs
	•	no changelog
	•	oversized release tarball
	•	hard required deps for optional integrations
	•	CI that only passes with your lockfile.  ￼

docs anti-patterns
	•	README-only docs
	•	API docs with no examples
	•	no guide for supervision/config/error handling
	•	no explanation of what use injects
	•	source links pointing only at main, not the tagged release.  ￼

operational anti-patterns
	•	logs as the only diagnostic surface
	•	unstable or undocumented telemetry events
	•	secret leakage in logs/errors
	•	forcing rescue-based error handling.  ￼

⸻

18) Practical “gold standard” checklist for your OpenSearch library

Use this as condensed LLM guidance.

Public API
	•	stable top-level functions
	•	explicit client argument or named client
	•	foo/.. + foo!/.. pairing where appropriate
	•	return {:ok, result} / {:error, exception}
	•	separate functions for materially different result shapes

Configuration
	•	explicit runtime options first
	•	app env only as optional convenience
	•	no direct reads of other apps’ config
	•	option validation with NimbleOptions or equivalent
	•	defaults obvious and documented

Processes
	•	pure core where possible
	•	supervision only for real runtime concerns
	•	long-lived processes always superviseable
	•	proper child_spec
	•	no hidden globally registered singleton unless clearly opt-in

Extensibility
	•	narrow behaviours
	•	optional callbacks where appropriate
	•	no broad defoverridable framework base unless truly justified
	•	adapters/modules passed explicitly

Errors
	•	library-specific exceptions
	•	structured fields
	•	tuple APIs plus raising variants
	•	optional Plug.Exception support if web-facing exceptions matter

Docs
	•	README with 30-second quickstart
	•	HexDocs API reference
	•	guides/extras for configuration, telemetry, Phoenix integration, testing
	•	examples everywhere
	•	changelog and migration notes
	•	source links pinned to release tags

Packaging
	•	strong Hex metadata
	•	minimal package contents
	•	dry-run publish checks
	•	optional deps marked optional
	•	compile/test without optional deps
	•	dependency bounds maintained realistically

Observability
	•	Telemetry start/stop/exception events
	•	stable event schema
	•	telemetry_test coverage
	•	structured Logger metadata
	•	no secret/large-payload dumping by default

Compile/runtime hygiene
	•	avoid macros unless necessary
	•	if use exists, document all public effects
	•	minimize compile-time deps
	•	use mix xref trace when macro-heavy code appears
	•	no dynamic module-name tricks that hide deps

⸻

19) My strongest opinionated recommendations for your specific project

For an Elixir OpenSearch OSS library, I would strongly favor this posture:
	1.	Core package should be plain and explicit: functions + client struct + transport behaviour.
	2.	No mandatory GenServer client. Let pure request APIs exist. Add supervised client/pool only as an opt-in layer.
	3.	Treat JSON query bodies as maps, not a custom DSL.
	4.	Use NimbleOptions for option validation and generated option docs.
	5.	Have a disciplined error taxonomy and bang/non-bang pairs.
	6.	Emit Telemetry from day one and test it.
	7.	Document Phoenix integration, but don’t depend on Phoenix.
	8.	Avoid macro DSLs unless they unlock something truly compelling.
	9.	Use behaviours only for genuine extension points like transport/auth/retry.
	10.	Design docs as part of the product, not afterthought.

That combination will make the library feel like it belongs in the Elixir ecosystem rather than feeling like a translated Ruby/JS/Java client.

If you want, I can turn this into a compact “Claude code project rules” spec next: terse, imperative, and optimized for LLM context windows.