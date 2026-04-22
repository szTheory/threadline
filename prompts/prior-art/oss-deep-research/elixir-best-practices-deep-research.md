Below is a high-signal Elixir-specific best-practices brief aimed at library authors, especially for something like an OpenSearch/Stripe client where you care about API design, supervision, concurrency, ergonomics, docs, and long-term maintainability.

I’m optimizing for “effective Elixir” rather than generic software advice, and I’m explicitly not assuming Dialyzer is part of your workflow. Where typespecs still help without Dialyzer, I call that out.

⸻

Effective Elixir for library authors

1) Core mindset

Elixir’s center of gravity is:
	•	modules/functions for code organization
	•	processes for runtime properties
	•	pattern matching and guards for assertive control flow
	•	data transformation over object state
	•	OTP abstractions when you truly need concurrency, lifecycle, fault isolation, or shared mutable process state  ￼

That one principle drives a lot of the “right shape” of good Elixir code:
	•	don’t hide plain computation behind a GenServer
	•	don’t add processes unless you need concurrency / ownership / failure boundaries
	•	don’t return vague or overloaded shapes
	•	don’t use macros when functions/behaviours/protocols are enough  ￼

⸻

2) API design: what idiomatic Elixir APIs look like

Prefer explicit, stable return shapes

One of the official design anti-patterns is alternative return types: functions whose options drastically change the return type. Elixir’s guidance is to prefer separate functions per return shape instead of one option-driven function that sometimes returns one thing and sometimes another.  ￼

Good

@spec get(index(), id()) :: {:ok, document()} | {:error, error()}
def get(index, id), do: ...

@spec get!(index(), id()) :: document()
def get!(index, id), do: ...

Avoid

def get(index, id, opts \\ [])
# sometimes {:ok, doc}
# sometimes doc
# sometimes nil
# sometimes :error depending on opts

Strong rule for library APIs

For public APIs, pick one of these patterns and stay consistent:
	•	{:ok, value} | {:error, reason}
	•	value | nil only when absence is ordinary and not diagnostic
	•	non-bang + bang pair: foo/1 and foo!/1  ￼

For HTTP/client libraries, the first pattern is usually best.

⸻

Prefer assertive matching over defensive ambiguity

The official anti-pattern docs push assertive programming: when something is expected, say so with pattern matching and guards. Using vague logic that allows unexpected values to propagate as nil or “some fallback” is considered a smell.  ￼

Good

%{host: host, port: port} = config

Good when optional

timeout = opts[:timeout]

Avoid

host = config[:host]
port = config[:port]
# nil leaks downstream even though both were required

The official map-access guidance is:
	•	use map.key when a key must exist
	•	use map[:key] when it is optional or dynamic  ￼

Also prefer exhaustive matches on tuples instead of a catch-all _ branch when the domain is known; wildcard fallbacks can hide future bugs.  ￼

⸻

Use atoms/tuples/structs to model domain states, not piles of booleans

The official docs call out boolean obsession and primitive obsession:
	•	multiple booleans for overlapping state should often be atoms or tagged tuples
	•	excessively passing around raw strings/ints/maps for a rich concept should often become a struct or composite type  ￼

For a Stripe/OpenSearch client, that means preferring domain values like:

{:ok, %Response{status: 200, body: body, headers: headers}}
{:error, {:http_error, status, body}}
{:error, {:transport_error, reason}}
{:error, {:decode_error, reason}}

instead of:

%{ok: false, retriable: true, failed: true, code: 500, body: "..."}

or “return a raw map everywhere”.

⸻

Keep multi-clause functions about one thing

Multi-clause functions are idiomatic, but the official anti-pattern docs warn against using clauses to group unrelated business rules under the same function name.  ￼

Use multiple clauses when they are truly the same operation over different shapes:

def encode(%Request{} = req), do: ...
def encode(requests) when is_list(requests), do: ...

Avoid:

def handle(:create, ...), do: ...
def handle(:delete, ...), do: ...
def handle(:refresh_token, ...), do: ...

when those are really separate public operations.

⸻

3) Syntax and code-shape conventions that matter

Let mix format win

Elixir officially recommends using the formatter; it gives you a consistent community style and reduces noise in review. mix new generates .formatter.exs, and mix format is the standard workflow.  ￼

For LLM rules, this should be hard law:
	•	always produce formatter-compatible code
	•	never bikeshed whitespace or alignment
	•	prefer community-default formatting over custom style

⸻

Follow standard naming conventions

Elixir’s official naming conventions doc exists specifically to align with language/community practice.  ￼

Practical rules:
	•	modules: MyLib.HTTP.Client
	•	functions/variables/files: snake_case
	•	predicates: end in ?
	•	dangerous/raising variants: end in !
	•	behaviours: noun or role modules
	•	exceptions: end in Error (community style guide)  ￼

For client libraries, this usually leads to:
	•	MyLib.Client
	•	MyLib.Request
	•	MyLib.Response
	•	MyLib.Error
	•	MyLib.Transport
	•	MyLib.Credentials
	•	MyLib.OpenSearch
	•	MyLib.Stripe

⸻

Parentheses: use them for function defs with args, and usually for non-DSL calls

The community Elixir style guide recommends:
	•	use parentheses when a def has arguments
	•	omit them when it has none  ￼

That is a good baseline for libraries. In public-facing library code, prefer clarity over DSL cleverness.

Good

def request(method, path, opts) do
  ...
end

def child_spec do
  ...
end

Also: avoid no-paren call chains that become visually ambiguous, especially around pipelines and nested calls. The community guide explicitly warns about ambiguous forms and recommends using bare variables as the first pipeline stage.  ￼

⸻

Pipelines: use them to express left-to-right transformation, not everything

The community style guide recommends using |> for chains, but avoiding a one-step pipeline.  ￼

Good heuristic:

Use pipelines for:
	•	linear data transformations
	•	building request payloads
	•	decoding/normalizing/validating sequences

Avoid pipelines for:
	•	branching-heavy logic
	•	steps that conceptually operate on different subjects
	•	long chains with many anonymous functions
	•	one-off calls

Good

params
|> normalize_params()
|> encode_query()
|> append_to_url(base_url)

Avoid

params |> normalize_params()


⸻

Prefer pattern matching and guards over nested if

Official docs say Elixir developers generally prefer pattern matching and guards, using case and function definitions, and only falling back to if/cond when the logic does not fit patterns/guards.  ￼

That means:
	•	function heads + guards first
	•	case for tagged unions / tuple results
	•	with for happy-path pipelines of {:ok, ...} / {:error, ...}
	•	if for actual boolean conditions
	•	cond only when you truly have multiple unrelated predicates

⸻

Use and/or/not when operands are booleans

Official anti-pattern guidance: if you expect booleans, prefer and/or/not over truthiness operators &&/||/!. This is especially important around Erlang interop because Erlang returns atoms like :undefined or :error, which are truthy in Elixir.  ￼

Good

if is_binary(key) and byte_size(key) > 0 do
  ...
end

Avoid

if is_binary(key) && byte_size(key) > 0 do
  ...
end


⸻

Keep comments sparse; make names/docs carry meaning

Official anti-pattern guidance warns about comments overuse.  ￼

So:
	•	don’t comment obvious code
	•	comment non-obvious invariants, protocols, gotchas, external API quirks
	•	explain why, not what
	•	prefer precise names + docs over line-by-line narration

For LLM rules: “remove comments that restate the code”.

⸻

4) Error handling

Do not use exceptions for ordinary control flow

Official guidance is explicit: prefer case and pattern matching over try/rescue for routine flow, and library authors should expose APIs that let callers handle errors without relying on exception control flow.  ￼

For a client library:
	•	transport failure, invalid credentials, 404, rate limit, decode failure: not exceptions by default
	•	programmer misuse or invariant break: exception is fine
	•	offer foo!/n as ergonomic raising variants

Good

case Transport.request(req, state) do
  {:ok, response} -> decode_response(response)
  {:error, reason} -> {:error, reason}
end

Avoid

try do
  Transport.request!(req, state)
rescue
  _ -> {:error, :request_failed}
end

Elixir officially documents three error mechanisms—errors, throws, exits—and they each have specific semantics; don’t blur them into one catch-all “error handling system”.  ￼

⸻

Define exception types cleanly when you do use exceptions

defexception creates exceptions as structs implementing the Exception behaviour.  ￼

Good practice:
	•	exceptions for truly exceptional cases or bang APIs
	•	module names ending in Error
	•	lowercase messages without trailing punctuation (community guide)  ￼

⸻

5) Behaviours, protocols, and extension points

Behaviours are the default extension mechanism for libraries

Official typespec docs describe behaviours as the way to separate the generic part from the specific implementation via callbacks. @impl makes implementations explicit and compiler-checked.  ￼

For a library, behaviours are usually the best fit for things like:
	•	transport adapter
	•	serializer / decoder
	•	credential provider
	•	retry strategy
	•	signer
	•	telemetry hook adapter
	•	clock or backoff source for testing

Use behaviours when callers swap implementations by module.

Example design:

defmodule MyLib.Transport do
  @callback request(MyLib.Request.t(), keyword()) ::
              {:ok, MyLib.Response.t()} | {:error, term()}
end

Then:

config[:transport].request(req, opts)

This is one of the most battle-tested Elixir library patterns.

Use @impl

Mark callback implementations with @impl BehaviourModule. The docs note this improves maintainability and warns on mistakes.  ￼

Prefer narrow behaviours

The Kernel docs explicitly recommend narrow behaviours and suggest optional callbacks if there is a natural entry point.  ￼

So prefer:
	•	request/2
over
	•	one giant behaviour with 12 unrelated callbacks

Use optional callbacks sparingly

Optional callbacks are supported via @optional_callbacks, and the official docs recommend Code.ensure_loaded?/1 plus function_exported?/3 when using them.  ￼

Use this only when the lifecycle naturally supports it.

⸻

Protocols: use for polymorphism over data types, not as a generic plugin system

Official docs: protocols are for polymorphism where behavior varies by data type.  ￼

That means protocols are a good fit for:
	•	encoding a request body from different payload types
	•	converting a value into headers / query params / iodata
	•	canonicalizing “document-like” data structures

Protocols are not the best default for “user can plug in a transport backend by module name”; behaviours are better there.

Protocol rule of thumb

Use a protocol when the axis of extension is:

“Given a value of some type, how do I do X with it?”

Use a behaviour when the axis of extension is:

“Given a module implementing this role, let it perform X.”

⸻

Macros: last resort

Official docs are blunt: macros are harder to write than functions and are bad style when not necessary. Official anti-pattern docs warn about large code generation and compile-time dependency hazards.  ￼

For libraries, default order should be:
	1.	plain functions
	2.	structs + protocols
	3.	behaviours
	4.	macros only if syntax abstraction is truly needed

Avoid macros for:
	•	convenience wrappers around functions
	•	configuration that could just be data
	•	large generated APIs
	•	compile-time registration unless there is a clear win

The anti-pattern docs also warn that macros add compile-time dependencies, and misuse can trigger broad recompilation cascades or untracked dependencies. mix xref is explicitly recommended for diagnosing this.  ￼

⸻

6) Processes, GenServers, Tasks, and supervisors

Golden rule: if you don’t need a process, don’t start one

The official GenServer docs say it directly: a GenServer must model runtime characteristics and must never be used for code organization.  ￼

Good reasons for a process in a library:
	•	connection ownership
	•	rate limiter / token bucket state
	•	background refresh of credentials
	•	serialization around shared resource access
	•	retry scheduler / queue
	•	cache owner
	•	subscription / streaming lifecycle
	•	failure isolation

Bad reasons:
	•	“this module has many functions so let’s put them behind a server”
	•	“I want OO-style encapsulation”
	•	“it feels more enterprise”

⸻

Keep process interfaces centralized

Official anti-pattern docs call out scattered process interfaces: if raw GenServer.call/cast, Agent.get/update, etc. are spread across the app, maintenance gets harder and bugs get easier. Wrap the process behind a proper module API.  ￼

Good

MyLib.Cache.put(cache, key, value)
MyLib.Cache.get(cache, key)

Avoid

Agent.get(cache, ...)
Agent.update(cache, ...)
GenServer.call(cache, ...)

all over the codebase.

⸻

Don’t send giant terms to processes

Official anti-pattern docs emphasize that messages are copied between processes due to BEAM’s share-nothing model. Capturing a big variable in a spawned function copies it too.  ￼

For library design:
	•	extract just what the task/process needs before spawn
	•	pass IDs / small structs / iodata, not giant request contexts
	•	be careful with closures over large state

Good

headers = req.headers
body = req.body
Task.start(fn -> send_metrics(headers, body) end)

Avoid

Task.start(fn -> send_metrics(req) end)

when req contains much more than needed.

⸻

Start long-lived processes under supervision

Official docs explicitly say, in practice, new processes should be started inside supervisors, and unsupervised long-running processes are an anti-pattern.  ￼

So:
	•	library-owned persistent workers: supervised
	•	ephemeral throwaway work: task or supervised task
	•	avoid ad hoc spawn for durable work

⸻

Use the right OTP abstraction

Plain function

Use when there is no runtime state or process concern.  ￼

Task

Use for one-off concurrent work. Official docs note that Task.async must be awaited, and async tasks link caller and task; if that linkage is undesirable, use supervised tasks instead.  ￼

Task.Supervisor

Use for dynamic task supervision. Official docs note it can become a bottleneck and may need partitioning if heavily used.  ￼

GenServer

Use for owned mutable process state, coordination, or lifecycle.  ￼

Supervisor

Use for mostly static child trees.  ￼

DynamicSupervisor

Use when children are started on demand and numerous; docs note it is optimized for dynamic children and can handle very large numbers.  ￼

⸻

Supervisor tree best practices

Official supervisor docs say supervisors provide fault tolerance and encapsulate startup/shutdown. Strategies are :one_for_one, :one_for_all, and :rest_for_one; defaults include max_restarts: 3 within max_seconds: 5.  ￼

Practical strategy choices
	•	:one_for_one: default for most libraries
	•	:rest_for_one: when later children depend on earlier ones
	•	:one_for_all: only when children are tightly coupled and should restart together  ￼

Child restart semantics matter

Supervisor docs define:
	•	:permanent — always restart
	•	:transient — restart only on abnormal exit
	•	:temporary — never restart  ￼

For libraries:
	•	connection pool manager / credential refresher: often :permanent
	•	one-shot task-like child: :temporary
	•	worker where normal completion is expected: maybe :transient

Static vs dynamic children

Official docs say regular Supervisor is for mostly static children; DynamicSupervisor is the specialized tool for on-demand children.  ￼

Don’t over-supervise

Not every helper needs its own process or subtree. Keep the tree shallow until there is a clear lifecycle reason.

⸻

Name registration: prefer explicit names and registries, not global atom sprawl

Elixir’s supervision docs show :via tuples for registry-based naming, and built-in behaviours support it.  ￼

For libraries:
	•	avoid forcing a single global process name unless the library is truly singleton-oriented
	•	accept name: / registry: / via: options where appropriate
	•	make it possible to run multiple independent clients in one VM

This is especially important for reusable libraries.

⸻

7) Data modeling

Use structs for stable domain entities

Structs give compile-time field checks and defaults.  ￼

Use structs for public, stable concepts like:
	•	Request
	•	Response
	•	Error
	•	Config
	•	Credentials
	•	BulkOperation

This gives stronger APIs than loose maps.

But don’t build monster structs

Official anti-pattern guidance warns that structs with 32+ fields change internal representation and can have higher memory cost.  ￼

So:
	•	small focused structs are great
	•	giant “everything bagel” config/result structs are not

Break them up.

⸻

Validate at boundaries

Official library guidelines say Elixir programs should validate data as close to the end user as possible; this avoids defensive code deep inside the library.  ￼

For a client library:
	•	validate config on startup / client construction
	•	validate request options in boundary functions
	•	normalize internal shapes once
	•	assume normalized shapes inside the core

That is very idiomatic Elixir.

⸻

8) Documentation and tests

Documentation is first-class

Official docs say Elixir treats documentation as a first-class citizen, and doctests help keep examples accurate.  ￼

For public library APIs, document:
	•	purpose
	•	return shapes
	•	important invariants
	•	examples
	•	option defaults
	•	edge cases
	•	bang vs non-bang behavior

Best practice for docs
	•	every public module: @moduledoc
	•	every public function: @doc
	•	examples for core workflows
	•	doctests for small pure/public examples  ￼

⸻

Typespecs can still be worth it even if you skip Dialyzer

Official docs explicitly say Elixir is dynamically typed and typespecs do not affect compiler optimization/behavior, but they are still useful because they provide documentation and support tools like ExDoc.  ￼

Given your preference, the pragmatic stance is:

Worth keeping
	•	@type / @opaque for major public data types
	•	@spec for major public APIs
	•	@callback for behaviours
	•	@typedoc for important domain concepts  ￼

Easy to skip
	•	exhaustive private/internal specs everywhere
	•	over-precise spec work that does not improve docs or extension points

For libraries, @opaque is especially useful when you want a public type with hidden representation.  ￼

⸻

ExUnit style

Official library guidelines recommend tests and doctests; ExUnit is the built-in framework. Async tests should not be used when touching global application environment, which the official guides call out explicitly.  ￼

Good rules:
	•	pure/unit tests: async: true
	•	tests mutating app env / global resources: not async
	•	assert on full return shapes
	•	for pattern-returning APIs, pattern match in assertions
	•	use doctests for small public examples, not full integration suites  ￼

⸻

9) Erlang/OTP guidance that directly matters for Elixir

Learn OTP design principles; they are upstream of idiomatic Elixir concurrency

Erlang’s official OTP design principles define how to structure code in terms of processes, modules, and directories. That thinking directly informs Elixir’s supervision/process model.  ￼

For Elixir library work, the Erlang ideas that matter most are:
	•	supervision trees are the normal starting point for fault-tolerant runtime structure
	•	processes are isolated failure domains
	•	choose restart strategy intentionally
	•	use OTP behaviours instead of ad hoc message loops  ￼

⸻

Interop with Erlang directly; don’t build pointless wrappers

Official Elixir docs explicitly discourage simply wrapping Erlang libraries and encourage interfacing with Erlang code directly.  ￼

For your library that means:
	•	use Erlang modules directly when they are the right tool
	•	don’t write cosmetic wrapper layers unless they create real Elixir value

Examples likely relevant in client libraries:
	•	:crypto
	•	:public_key
	•	:ssl
	•	:telemetry is Elixir, but many low-level pieces around networking/crypto are Erlang/OTP land
	•	:ets if you need in-memory tables with ownership semantics  ￼

Also, anything outside :kernel / :stdlib must be listed in extra_applications if needed.  ￼

⸻

10) Library-specific best practices for an SDK/client

Separate pure request construction from side-effecting transport

A very idiomatic Elixir split is:
	•	pure modules to build/normalize/sign/encode requests
	•	transport behaviour/module to perform IO
	•	response decoder modules to classify results
	•	optional supervised runtime client only when you need persistent state

This lets most of the library stay pure/testable and keeps OTP only where it pays off. This follows the general Elixir guidance of modules/functions for organization and processes for runtime properties.  ￼

⸻

Offer both stateless and supervised entry points when appropriate

For many SDKs, the cleanest design is:
	•	a stateless API that accepts config/client explicitly
	•	an optional supervised client for pooled/shared runtime state

Example shape:

MyLib.request(client, req)
MyLib.Client.start_link(opts)

That keeps the library composable and avoids forcing global process architecture.

⸻

Make dependencies injectable via behaviours

For AI-assisted codegen and maintainability, define narrow behaviours for things you may swap:
	•	HTTP transport
	•	signer
	•	JSON codec
	•	retry/backoff
	•	time source
	•	idempotency key generator

This is the most Elixir-native way to get flexibility without macro magic.  ￼

⸻

Keep public API small and layered

Public modules should feel like:
	•	a small top-level façade
	•	strongly named submodules for advanced use
	•	no giant god module

For example:
	•	MyLib
	•	MyLib.Client
	•	MyLib.Request
	•	MyLib.Response
	•	MyLib.Transport
	•	MyLib.Error
	•	MyLib.OpenSearch.Query
	•	MyLib.Stripe.Webhook

This works well with Elixir’s module-oriented organization.

⸻

11) Anti-patterns to explicitly ban in project rules

These are the biggest high-value bans for Elixir library code:

Hard bans
	•	using GenServer for code organization instead of runtime state/concurrency  ￼
	•	adding processes outside supervision for long-lived work  ￼
	•	using exceptions for normal control flow  ￼
	•	option flags that radically change return types  ￼
	•	macros when functions/behaviours/protocols would do  ￼
	•	scattered raw GenServer.call/cast or Agent usage across modules  ￼
	•	sending/capturing large structs/maps into spawned processes/tasks unnecessarily  ￼
	•	dynamic map access for required keys (map[:key] when key is required)  ￼
	•	catch-all _ branches that hide evolving return domains  ￼

Strong discouragements
	•	booleans encoding multi-state domains  ￼
	•	giant structs with 32+ fields  ￼
	•	over-commenting obvious code  ￼
	•	broad behaviours with too many unrelated callbacks  ￼
	•	wrapping Erlang modules just to “make them look more Elixiry” without real value  ￼

⸻

12) What I would encode as LLM project rules

Here’s the distilled version I’d actually feed into an LLM.

Elixir project rules
	•	Organize code with modules and functions; use processes only for runtime properties like state ownership, concurrency, coordination, isolation, and lifecycle.
	•	Prefer pure functions and explicit data transformation.
	•	Public APIs should return stable, explicit tagged tuples; avoid options that change return type.
	•	Use pattern matching and guards aggressively; prefer assertive code over vague defensive fallbacks.
	•	Use map.key for required keys and map[:key] only for optional/dynamic access.
	•	Prefer case / with / function clauses over exception-driven control flow.
	•	Use behaviours for pluggable modules; keep them narrow; mark callbacks with @impl.
	•	Use protocols only when dispatch varies by data type.
	•	Avoid macros unless syntax abstraction is truly necessary; prefer functions first.
	•	Keep long-lived processes under supervision; use Supervisor for static trees and DynamicSupervisor for on-demand children.
	•	Use Task for one-off concurrent work; always respect linking/await semantics; use Task.Supervisor when supervision is needed.
	•	Never spread raw GenServer.call/cast across the codebase; wrap process interaction in a module API.
	•	Avoid copying large terms into tasks/processes; extract only the needed data first.
	•	Use small focused structs for public domain entities; avoid giant structs.
	•	Validate at boundaries, not deep in the internals.
	•	Use mix format; align with standard Elixir naming and formatting.
	•	Treat docs as part of the API; document public modules/functions and include doctestable examples.
	•	Typespecs are optional for static analysis, but still useful for docs, behaviours, and opaque public types.

Specific anti-pattern bans
	•	GenServer as OOP object
	•	option-driven alternative return types
	•	exceptions for routine failures
	•	boolean soup
	•	giant god modules
	•	macros for convenience only
	•	unsupervised long-running processes
	•	vague wildcard matches over known tuple domains
	•	dynamic required-key access
	•	large closure capture into tasks/processes

⸻

13) My opinionated take for your use case

For an OpenSearch/Stripe Elixir library, the most idiomatic architecture is probably:
	•	mostly stateless core
	•	public structs for request/response/error/config
	•	behaviour-based transport abstraction
	•	optional supervised runtime pieces only for:
	•	connection reuse/pooling integration
	•	background credential refresh
	•	rate limiting / backoff coordination
	•	stream/subscription lifecycle
	•	non-bang APIs returning {:ok, _} | {:error, _}
	•	bang variants only where ergonomic
	•	minimal macro use, probably none
	•	protocols only if you want data-type-based encoding/serialization extensibility
	•	typespecs for public surface + behaviours + opaque types, even if you skip Dialyzer  ￼

If you want, next I can turn this into a tight “Claude Code / Cursor rules” file in a compact checklist format with DO / DON’T / examples.