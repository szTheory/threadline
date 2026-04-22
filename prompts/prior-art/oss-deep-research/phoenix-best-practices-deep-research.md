Below is a Phoenix-specific, high-signal reference tuned for writing excellent Phoenix code in modern Phoenix/LiveView apps. I’m deliberately avoiding generic Elixir advice and focusing on Phoenix architecture, boundaries, LiveView, routing, supervision, testing, security, and Phoenix-specific anti-patterns.

Effective Phoenix: the defaults to optimize for

1. Treat Phoenix as the web interface, not the center of the system.
Phoenix’s own guides frame contexts as the place where data access and validation are encapsulated, with controllers/LiveViews/templates acting as the web-facing layer around that application code. In practice: controllers, LiveViews, channels, and components should orchestrate HTTP/UI/realtime concerns and call into contexts for feature logic.  ￼

2. Use the generated shape as the baseline unless you have a concrete reason not to.
Phoenix 1.7/1.8 generators encode a lot of current framework opinion: lib/my_app for app/domain code, lib/my_app_web for web code, components/layouts for shared UI structure, verified routes via ~p, CoreComponents, and modern LiveView conventions. Starting close to generator output usually means less framework friction and more upgradeability.  ￼

3. Prefer compile-time guarantees Phoenix gives you.
In Phoenix specifically, that means HEEx templates, function components with attr/3 and slot/3, and verified routes with ~p. Those features push mistakes into compile warnings/errors instead of runtime surprises.  ￼

⸻

Code organization: what “good Phoenix structure” looks like

The boundary

A strong Phoenix codebase usually has this split:
	•	MyApp.* = feature/domain/application modules
	•	MyAppWeb.* = controllers, LiveViews, components, router, endpoint, channel-facing code

That is the shape Phoenix generates and documents. It keeps the web layer replaceable and prevents UI code from becoming your business API.  ￼

Contexts

Phoenix’s official guidance is that contexts centralize functionality related to a feature instead of scattering it across controllers and LiveViews. They are named boundaries, not just folders. Good Phoenix code uses contexts as the app-facing API for the web layer.  ￼

Good Phoenix context rules
	•	One context per cohesive feature area, not one per table.
	•	Name contexts after capability/business boundary (Accounts, Billing, Catalog, Search), not transport/UI.
	•	Let contexts expose feature operations; don’t make controllers/LiveViews compose raw Repo calls.
	•	Co-locate related schemas inside a context when they belong to the same feature boundary. Phoenix’s own context guide uses this pattern.  ￼

Cross-context rule
Phoenix has an explicit guide on cross-context boundaries. The useful takeaway: keep each context internally cohesive, and when a feature spans contexts, compose through explicit boundary functions instead of reaching through internals all over the web layer.  ￼

Web modules

Keep these thin and transport-specific:
	•	Controllers: parse request shape, call a context, choose render/redirect/JSON response.
	•	LiveViews: hold UI state, react to events, coordinate async work, call contexts.
	•	Components: render reusable UI; only make them stateful when lifecycle/event isolation is truly needed.
	•	Router: declarative composition of pipelines/scopes/routes, not business logic.
	•	Channels: socket/realtime transport entry points, not domain cores.  ￼

⸻

Umbrella: anti-pattern or not?

No, umbrella is not an anti-pattern in Phoenix. Phoenix officially supports it with mix phx.new --umbrella, mix phx.new.web, and mix phx.new.ecto. The web generator explicitly says it is for a Phoenix web project that interfaces with the greater umbrella applications. The Elixir team also highlights a production case study (Veeps) using umbrellas to support a service-oriented architecture in a monorepo.  ￼

But umbrella should not be your default reflex.
For most Phoenix apps, a single Phoenix project with well-designed contexts is simpler. Move to an umbrella when you need real application boundaries, such as:
	•	multiple OTP apps with separate responsibilities
	•	multiple releases/deployable subsystems
	•	shared code that genuinely serves multiple apps
	•	stronger compile/dependency boundaries than contexts alone provide

That’s an inference from Phoenix’s official umbrella tooling and the Veeps case study: umbrellas are for meaningful app-level separation, not for “clean architecture theater.”  ￼

Bad reason for umbrella
	•	“I want every context in its own app from day one.”

Good reason for umbrella
	•	“I have a Phoenix web app plus separate worker/service/admin or shared-core apps that should be isolated as OTP applications.”

⸻

Phoenix syntax and UI conventions that are worth standardizing

Prefer function components first

Phoenix.Component says function components are the base abstraction for reusable UI. In Phoenix apps, they should be your default component form. Use LiveComponents only when you need state, events, or lifecycle local to that component.  ￼

Default rule
	•	Phoenix.Component / use MyAppWeb, :html first
	•	Phoenix.LiveComponent only when you need it

Use attr/3 and slot/3 everywhere on public components

Phoenix documents attr/3 and slot/3 specifically to declare component contracts and produce compile-time warnings. For LLM-assisted code, this is especially valuable because it makes misuse visible early.  ￼

Rule
	•	Every reusable component should declare attrs and slots.
	•	Treat undeclared assigns as a smell unless the component is intentionally very low-level.

Use HEEx idiomatically

LiveView’s HEEx docs warn that ordinary local variables in templates disable change tracking, except for variables introduced by block constructs like if, case, and for. So Phoenix-specific best practice is: compute in functions or assigns, not in ad hoc template variables.  ￼

Do
	•	compute in helpers/components
	•	pass assigns intentionally
	•	keep templates mostly declarative

Avoid
	•	<% x = ... %> for display logic in templates
	•	big procedural chunks inside .heex

Prefer ~p verified routes universally

Phoenix explicitly says ~p is the preferred route-generation mechanism with compile-time verification across controllers, tests, and templates. That should be standard.  ￼

Rule
	•	no legacy route helpers in new code unless forced by edge cases
	•	route generation belongs in ~p

⸻

Router, scopes, controllers: effective Phoenix HTTP structure

Router

Phoenix routes are defined in scopes and pipelines, and nested scopes are officially discouraged. That means: keep routing flat and obvious; don’t build a scope maze.  ￼

Router rules
	•	prefer a few clear pipelines (:browser, :api, maybe admin/auth variants)
	•	use scopes for URL/module/pipeline grouping
	•	avoid deeply nested scopes
	•	keep router declarative; no feature logic in pipelines beyond request concerns

Controllers

Phoenix’s controller testing guide is revealing: it treats controllers as integration layers, not the place for exhaustive business rules. That is the right design target.  ￼

Controller rules
	•	deserialize/validate request shape
	•	call one or a few context operations
	•	render or redirect
	•	do not bury business decisions in controllers
	•	keep controller tests broad, not duplicative of context/schema tests  ￼

Scopes and auth-generated structure

Phoenix 1.8 scopes are meant to help tie generated resources to the authenticated/current scope and improve security structure. For modern Phoenix apps, lean into scopes rather than inventing ad hoc auth threading across web modules.  ￼

⸻

LiveView: the biggest Phoenix-specific leverage

Core mental model

A LiveView starts as regular HTTP + HTML, then upgrades to a stateful server process on connect. That gives you progressive enhancement and server-side state. This is the foundation for many best practices below.  ￼

Use LiveView for UI state, not as your domain model

Because LiveViews are long-lived processes, it is tempting to let them become mini-application servers. Resist that. Keep LiveView state about:
	•	current UI state
	•	selected record ids
	•	pagination/sort/filter params
	•	form/changeset state
	•	async/loading state

Call contexts for the actual work. This follows Phoenix’s separation between web-facing code and application code.  ￼

Prefer live navigation correctly

Phoenix LiveView distinguishes:
	•	patch / push_patch for staying on the same LiveView and updating params
	•	navigate / push_navigate for moving to another LiveView in the same session
	•	href / HTTP redirects for full reloads

Phoenix also calls it best practice to use live navigation when the same LiveView has multiple URL states, exposing state through @live_action.  ￼

Rule
	•	URL-worthy UI state belongs in params and handle_params/3
	•	ephemeral local widget state stays in assigns

mount/3 vs handle_params/3

LiveView docs are explicit: load stable data on mount/3; use handle_params/3 only for params expected to change through patching; don’t split responsibility for the same param across both callbacks.  ￼

Forms

Phoenix recommends handling LiveView form changes at the form level with phx-change and submission with phx-submit. That should be your default for real-time validation flows.  ￼

Async work

Modern LiveView has assign_async/3, which starts tasks only when connected and expects explicit {:ok, assigns} / {:error, reason} contracts. For expensive UI loads, this is preferable to hand-rolled ad hoc task state.  ￼

Rule
	•	use assign_async/3 for async page data loading
	•	keep async result state explicit in assigns
	•	never block the LiveView process on slow I/O if you can avoid it

Components in LiveView

Phoenix docs make the distinction clear:
	•	function components = stateless, preferred default
	•	LiveComponents = stateful, same process as parent LiveView, own lifecycle/events

Because LiveComponents run in the same process, they are not concurrency boundaries. Don’t use them thinking they isolate heavy work.  ￼

Streams / large collections

LiveView’s stream support exists specifically so large collections can be managed in the UI without keeping the full collection in server state. For large append/update/remove lists, prefer streams to giant list assigns.  ￼

Common LiveView anti-patterns
	•	loading the same param-derived data in both mount/3 and handle_params/3  ￼
	•	using template-local variables that break change tracking  ￼
	•	defaulting to LiveComponents when function components suffice  ￼
	•	blocking the LiveView process with slow work instead of async/task patterns  ￼
	•	keeping massive collections in assigns instead of streams where appropriate  ￼

⸻

Supervisor trees and process architecture: Phoenix-specific guidance

What Phoenix itself already gives you

Phoenix.Endpoint docs define the endpoint as part of the supervision tree and the boundary where requests start. New Phoenix apps also typically include telemetry, pubsub, repo, and endpoint-related pieces in the application tree.  ￼

Good Phoenix supervision defaults

For a typical Phoenix app, your top-level supervision tree should usually be for infrastructure and long-lived app processes, such as:
	•	Repo
	•	Telemetry supervisor
	•	PubSub
	•	Presence
	•	Endpoint
	•	durable background job system / caches / registries / long-lived workers

That matches Phoenix’s endpoint/telemetry/presence/pubsub model.  ￼

What should not go in the top-level app supervisor

Do not create top-level long-lived processes for ordinary request/LiveView/controller work just because “OTP.” Phoenix already handles request concurrency, and LiveViews already get their own processes. Add supervisors when you have true process-worthy behavior: long-lived state, subscriptions, retries, coordination, or isolation needs. This last sentence is an inference from Phoenix’s existing process model plus endpoint/LiveView docs.  ￼

For your Stripe/OpenSearch Phoenix app specifically

Likely good long-lived supervised children:
	•	PubSub
	•	Presence only if you need user/session presence
	•	Telemetry reporter
	•	background workers for indexing, webhook retries, sync/reconciliation
	•	maybe registries/dynamic supervisors for long-lived per-tenant or per-stream processes if your design truly benefits from process identity

Likely bad choices:
	•	a GenServer per CRUD feature just to “have architecture”
	•	funneling all business logic through singleton processes
	•	making controllers/LiveViews message a central process for routine DB/API work

PubSub

Phoenix channels docs explicitly describe PubSub as application-wide broadcast infrastructure, useful not only for channels but for app development in general, including notifying LiveViews. Use it for cross-process UI invalidation and realtime fan-out; don’t reinvent it.  ￼

Presence

Presence is the Phoenix-native answer for replicated topic presence across a cluster. Use it for online users / collaborative cursors / viewer counts; don’t build your own if Presence matches the need.  ￼

⸻

Phoenix security rules that should be in your project guidelines

Phoenix’s security guide explicitly warns that AI-assisted coding increases the need for security judgment. For LLM project rules, this section matters a lot.  ￼

Always separate authentication from authorization

LiveView’s security model spells out the distinction. In Phoenix apps, especially LiveView apps, verify both identity and access. Being mounted behind an authenticated session is not sufficient authorization.  ￼

Authorize on actions, not just mount

LiveView security guidance says the simplest and safest approach is to authorize whenever there is an action. So for LiveViews: check access on mount and on event handlers / action handlers that change state.  ￼

Never trust params

Live navigation docs explicitly remind you never to trust received params; validate them in handle_params/3. Same principle applies to controller params and LiveView events.  ￼

Prefer generated auth/scopes over custom ad hoc auth plumbing

mix phx.gen.auth and Phoenix 1.8 scopes exist to give you a secure, maintainable foundation. If you dislike parts of the generated system, modify it, but start from it unless you have a strong reason not to.  ￼

Prefer HEEx and Phoenix abstractions over raw string-building

HEEx and Phoenix components reduce a lot of HTML/XSS footguns by design. Stick to the framework’s rendering pipeline.  ￼

⸻

Observability and operational Phoenix

Phoenix has first-class telemetry guidance. Instrument Phoenix-specific behavior and your own feature boundaries with :telemetry, then connect reporters/metrics.  ￼

Phoenix-specific rule set
	•	instrument controller/LiveView/context boundaries for major feature operations
	•	instrument external API boundaries like Stripe/OpenSearch calls
	•	track slow queries and UI interaction bottlenecks
	•	use LiveDashboard/telemetry-driven visibility during development and operations

This is partly direct from Phoenix telemetry docs and partly a straightforward application of those docs to your architecture.  ￼

⸻

Testing: what good Phoenix tests emphasize

Phoenix’s testing docs create a clear hierarchy:
	•	ConnCase for controller/request tests
	•	broad controller tests as integration checks
	•	context/schema tests for detailed rule coverage
	•	LiveView tests for stateful UI lifecycle and behavior  ￼

Controller tests

Phoenix explicitly says not to exhaustively verify every business-rule outcome in controller tests; those belong in context/schema tests. Controllers are integration layers.  ￼

LiveView tests

LiveViewTest is designed around the real lifecycle: disconnected HTML render, then connected process-driven interaction. Good Phoenix tests use that model instead of treating LiveViews like static templates.  ￼

What to standardize
	•	context tests for feature rules and edge cases
	•	controller tests for request/response integration
	•	LiveView tests for URL state, event handling, async rendering, and form flows
	•	component tests where reusable components encode meaningful rendering contracts

⸻

Phoenix-specific anti-patterns to ban in AI-generated code

Architecture anti-patterns
	•	Repo from everywhere: controllers, LiveViews, channels, and components making direct data-layer calls instead of going through contexts. Phoenix contexts exist to centralize feature functionality.  ￼
	•	Context per table: this loses the whole point of Phoenix contexts as feature boundaries.  ￼
	•	Web layer as domain layer: business logic living in controllers/LiveViews. Phoenix testing and context guides push the opposite.  ￼
	•	Umbrella-by-default without app boundaries: Phoenix supports umbrellas, but use them for real OTP/application separation, not as cargo cult architecture.  ￼

Router/controller anti-patterns
	•	deeply nested scopes  ￼
	•	heavy plugs/pipelines doing feature logic instead of request concerns  ￼
	•	controllers duplicating business validation already covered elsewhere  ￼

LiveView anti-patterns
	•	using LiveComponents by default instead of function components  ￼
	•	using mount/3 and handle_params/3 for the same param responsibilities  ￼
	•	putting too much logic in templates / using locals that break change tracking  ￼
	•	blocking work in event handlers instead of async patterns  ￼
	•	storing giant UI collections in assigns instead of streams when appropriate  ￼

Security anti-patterns
	•	authorization only on mount in LiveView  ￼
	•	trusting query/event params without validation  ￼
	•	bypassing generated secure defaults for auth without a strong reason  ￼

⸻

Opinionated “great Phoenix code” rules for LLM context

You could almost drop this into project rules as-is:
	1.	Web code lives in MyAppWeb; feature logic lives in contexts under MyApp.  ￼
	2.	Controllers, LiveViews, channels, and components call contexts; they do not own business logic.  ￼
	3.	Use function components by default; use LiveComponents only for local state/events/lifecycle.  ￼
	4.	Every reusable component declares attr/3 and slot/3.  ￼
	5.	Use HEEx idiomatically: no ad hoc local template variables for derived values.  ￼
	6.	Use ~p verified routes everywhere.  ￼
	7.	Use patch for same-LiveView URL state, navigate for LiveView-to-LiveView transitions, HTTP redirects for full reloads.  ￼
	8.	Load stable data in mount/3; param-driven incremental state in handle_params/3; never split the same param across both.  ￼
	9.	Use form-level phx-change and phx-submit for LiveView forms.  ￼
	10.	Use assign_async/3 for slow UI data loads instead of blocking the LiveView process.  ￼
	11.	Use streams for large, frequently changing collections.  ￼
	12.	Keep router scopes shallow; nested scopes are discouraged.  ￼
	13.	Controller tests are integration tests; detailed rule coverage belongs in context/schema tests.  ￼
	14.	Authorize on action, not only on mount. Never trust params.  ￼
	15.	Supervise long-lived infrastructure/processes, not routine request logic.  ￼
	16.	Use umbrella only when you need real OTP app boundaries; otherwise prefer a single Phoenix app with strong contexts.  ￼

⸻

On Dialyzer / types

Your preference not to use Dialyzer is compatible with writing strong Phoenix code. None of the Phoenix best practices above depend on Dialyzer. Phoenix’s strongest correctness levers here are actually framework-native: verified routes, HEEx, component attrs/slots, generator conventions, scopes, and well-defined context boundaries.  ￼

If you want, next I can turn this into a compact Claude/LLM project rules file with:
	•	required patterns
	•	banned anti-patterns
	•	code review checklist
	•	LiveView/component/controller/context templates for Phoenix.