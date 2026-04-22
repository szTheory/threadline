Below is a current, opinionated LiveView report tuned for AI/LLM-assisted implementation, based on the latest Phoenix and LiveView docs I could verify today. As of April 15, 2026, the current docs show Phoenix 1.8.5 and Phoenix LiveView 1.1.28. LiveView 1.1 introduced several important shifts worth treating as the modern baseline: colocated hooks/JS, keyed comprehension improvements, <.portal>, JS.ignore_attributes/1, official JS type annotations, Phoenix.LiveView.Debug, and a LiveViewTest move from Floki to LazyHTML.  ￼

1) The modern default mental model

The most important architectural stance is: LiveView is your web interface, not your domain layer. Phoenix’s own contexts guidance still points to contexts as the place that centralizes data access and validation, while LiveViews remain orchestration and presentation. In practice, that means a LiveView should mostly: load state, call context APIs, react to events, update assigns/streams, and render components. Business rules, authorization-sensitive data fetching, and side effects should live in contexts or dedicated application services beneath them.  ￼

For DDD-style work, Phoenix’s idiom is contexts first, not “everything is a LiveView”. Phoenix explicitly treats contexts as API boundaries, and the current guides recommend not over-optimizing names too early: choose clear context names, let the domain emerge, and refactor boundaries as the model becomes clearer. That maps well to bounded contexts: Accounts, Billing, Catalog, Support, Workspace, and so on. LiveViews should depend on those boundaries instead of becoming mini-applications with their own rule sets.  ￼

A strong current default is:
	•	Contexts own rules and data access
	•	LiveViews own screen/session/UI state
	•	Function components own reusable markup
	•	LiveComponents are used only when a component truly needs local state + event handling
	•	JS hooks are the exception, not the default
	•	URL/query params own shareable UI state
	•	Streams own large/volatile collections
	•	Async APIs own slow work
	•	PubSub owns real-time fanout
	•	Telemetry owns visibility

That is the most idiomatic direction the official docs point to today.  ￼

2) Architecture: what scales best

The most scalable LiveView architecture is usually thin LiveViews over explicit context APIs. A good LiveView is more like a controller with state than like a domain object. It should call things such as Catalog.list_products(scope, filters), Billing.create_invoice(scope, attrs), Support.subscribe_ticket(scope, ticket_id), instead of embedding queries and domain branching inline. Phoenix’s contexts/scopes docs strongly reinforce this direction, including generated examples that pass a current_scope into context functions and keep resource filtering in the context layer.  ￼

That leads to a useful rule for teams and LLMs:

Never let LiveViews become the source of truth for authorization or multi-tenant filtering.
Phoenix’s current security and scopes docs are explicit that authorization belongs on mount and handle_event, and that database CRUD must be properly scoped. Generators in Phoenix 1.8 now lean into scopes, including current_scope patterns and scoped context APIs. For multi-tenant or per-user systems, make scope an explicit first argument in the context API and carry it everywhere important.  ￼

A practical file/module shape that ages well:
	•	MyApp.<Context> for boundary APIs
	•	MyApp.<Context>.<Entity> for schemas/value objects
	•	MyAppWeb.<Feature>Live.<Screen> for LiveViews
	•	MyAppWeb.CoreComponents + feature component modules for reusable UI
	•	optional MyApp.<Context>.<UseCase> modules for heavier workflows
	•	optional MyApp.<Context>.Subscriptions or similar for PubSub/event fanout

This keeps LiveView codebase growth sane and gives LLMs clearer edit targets.

3) Function components vs LiveComponents

One of the clearest current recommendations is: prefer function components over LiveComponents. The official Phoenix.LiveComponent docs say exactly that: function components have a smaller surface area, and LiveComponents should only be introduced when you truly need encapsulated event handling and extra state. Avoid using LiveComponents just for code organization.  ￼

That means the default UI composition should be:
	•	Function components for buttons, cards, forms, tables, panels, modals, headers, lists, empty states
	•	LiveComponents only for widgets that have meaningful internal lifecycle/state, such as a complex editor, upload widget, inline row editor, or component-specific event loop

Also lean into attr and slot declarations aggressively. Modern Phoenix component APIs are much safer and more LLM-friendly when they use declarative attrs/slots, because compile-time validation catches misuse, missing slots, and bad assigns. HEEx debug annotations and debug attributes are also now first-class helpers for tracing where markup came from.  ￼

4) URL state is first-class state

A big current best practice is to put shareable, recoverable, user-meaningful UI state in the URL. LiveView’s deployment/recovery guide explicitly recommends query params for things like tabs and similar view state, using patch-based navigation and handle_params/3 instead of ephemeral server-only toggles. That improves resilience during reconnects/deploys, supports copy/paste URLs, and reduces unnecessary server state.  ￼

So prefer:
	•	filters, sort, pagination cursor/page
	•	tab/view mode
	•	selected resource IDs
	•	modal/edit/new routes
	•	search query
	•	date ranges

Use <.link patch={...}> / push_patch for same-LiveView state changes, and <.link navigate={...}> / push_navigate for moving between LiveViews in the same session. patch updates the current LiveView with minimal diffs and preserves scroll; navigate dismounts the current LiveView and mounts the next.  ￼

A very good default is:
if the user would expect Back/Forward, bookmarking, or collaboration to work, it belongs in the URL.

5) Streams are the modern answer for big collections

For list-heavy screens, the modern default is streams, not giant assigns. LiveView’s docs now explicitly position streams as a way to manage large collections without keeping the whole collection in server state, and stream items are freed from socket state immediately after render. That is a major scalability lever.  ￼

Use streams for:
	•	large tables
	•	chat/message feeds
	•	activity/event logs
	•	infinite scrolling
	•	search result lists
	•	live-updating collections from PubSub

Important stream rules and footguns:
	•	The immediate parent must have phx-update="stream" and a unique DOM id.
	•	Each rendered stream item must use the computed stream DOM id.
	•	Do not mutate or prefix those generated DOM ids.
	•	Non-stream items inside a stream container need their own unique ids and have quirks: they can be added/updated but not cleanly removed once rendered, even on reset.
	•	When prepending multiple items with at: 0, LiveView inserts one by one, so reverse the list first if you want intuitive order.
	•	limit is enforced client-side after connection; on the initial disconnected render you should only load what you actually want shown.  ￼

This is a place where outdated advice often lingers. In 2026, for large dynamic lists, reach for streams first.

6) Async is now standard, not exotic

For slow I/O or expensive computation, current LiveView encourages async operations with assign_async/3, start_async/3, and stream_async/3. The docs explicitly frame async work as the way to give users a working UI quickly while background fetches run.  ￼

Recommended usage pattern:
	•	Use assign_async for loading one or a few values into assigns.
	•	Use start_async when you want custom handle_async/3 handling.
	•	Use stream_async when the result is a collection destined for a stream.
	•	Show loading/failed/result states via AsyncResult or <.async_result>.
	•	Use render_async/2 in tests so the test waits for completion.  ￼

Important footguns:
	•	Do not capture the whole socket inside async tasks. The docs call out that passing the socket copies the whole socket struct into the task process and can be expensive. Pull just the data you need first.  ￼
	•	send_update/3 from inside assign_async is tricky because the async code runs in another process; when you truly need it, explicitly send the update to the parent LiveView process.  ￼
	•	If tasks need explicit supervision, use the :supervisor option with a Task.Supervisor.  ￼

7) Forms: the most important UX surface

Current LiveView form guidance is still extremely important and still often implemented badly by AI-generated code. The official guidance is to use phx-change and phx-submit, and in general handle changes at the form level, not scattered per input. .form plus to_form/1 is the idiomatic baseline.  ￼

Strong best practices:
	•	Keep one authoritative changeset/form state on the server.
	•	Use form-level phx-change for validation.
	•	Use phx-submit for commits.
	•	Prefer explicit validation states and inline errors.
	•	Use debounce/throttle intentionally for noisy fields.  ￼

Current UX guidance that matters a lot:
	•	The JS client is the source of truth for current input values, and LiveView has built-in protections to avoid clobbering in-progress edits during round trips.
	•	On phx-submit, inputs are set readonly, submit buttons are disabled, and loading classes are applied.
	•	LiveView has automatic form recovery after reconnect/remount for forms with phx-change and an id; complex wizards may need custom phx-auto-recover.  ￼

For modern UX, always design and test under latency. LiveView’s docs explicitly recommend using the built-in latency simulator because localhost hides real interaction problems.  ￼

8) JS: keep it small, but use the modern tools

The modern LiveView stance is not “never use JS.” It is “use the smallest correct amount of JS, and use LiveView-native tools first.”

Preferred order:
	1.	HEEx + server state
	2.	Phoenix.LiveView.JS commands
	3.	client hooks
	4.	larger custom JS only when necessary

Phoenix.LiveView.JS is especially valuable because its operations are DOM-patch aware and survive server patches better than ad hoc client code. Use it for show/hide, transitions, toggles, attribute/class changes, focus flows, dispatching DOM events, and customized pushes/loading states.  ￼

What changed recently and should influence new code:
	•	Colocated hooks and colocated JS in LiveView 1.1 are great for small snippets that belong next to the component they support.
	•	Hook names beginning with a dot get namespaced by module, which helps avoid global collisions.
	•	LiveView 1.1 added official JS type annotations, making hook authoring much nicer in editors.
	•	<.portal> gives an idiomatic solution for teleporting UI like tooltips/dialog content outside clipping containers.
	•	JS.ignore_attributes/1 is now the recommended answer when browser-managed attributes such as open on <dialog>/<details> should not be stomped by patches.  ￼

So in 2026, an idiomatic UI often means: server-rendered HTML + JS commands + tiny colocated hooks, not a blanket ban on client logic.

9) Real-time updates and PubSub

LiveView scales best when it reacts to system changes instead of polling or duplicating domain logic. Phoenix’s scopes docs show generated LiveViews subscribing to scoped PubSub topics and then re-streaming updated context data. That is still a good model: contexts publish domain events; LiveViews subscribe per scope/resource and update their own assigns/streams.  ￼

A practical pattern:
	•	Context performs command and persists state.
	•	Context publishes event (created/updated/deleted, or a richer domain event).
	•	LiveView receives handle_info.
	•	LiveView updates targeted streams/assigns.

This gives you cleaner separation than having LiveViews own mutations and broadcast logic directly.

10) Security: the two most common LiveView mistakes

The first common mistake is assuming the router pipeline is enough. It is not. LiveView’s security docs explicitly say LiveViews need their own checks. Protect regular routes with plugs, but also validate session/auth on mount, typically via on_mount hooks and live_session, and enforce authorization again in events that mutate state.  ￼

The second common mistake is letting CRUD ignore scope. Phoenix 1.8’s scopes guidance is one of the biggest practical upgrades for secure code generation: keep a current_scope struct, pass it into context APIs, and let the data layer filter by scope. That materially reduces broken access control risk.  ￼

For LLM workflows, a good hard rule is:

No context function that reads or mutates user data should be added without an explicit scope/auth story.

11) Error handling philosophy

Current LiveView docs still recommend an assertive Elixir style: expected user-facing failures should be rendered as state/errors, while truly unexpected failures can raise. In other words, invalid form input is expected; impossible state transitions are not.  ￼

In practice:
	•	Render expected failures in-form or as flash.
	•	Raise or use bang-functions for invariant violations.
	•	Convert async failures into explicit UI states instead of crashing the user experience.
	•	Keep mutation logic idempotent where reasonable, because reconnects and retries are part of the model.  ￼

12) Testing: current best practice

The testing story has improved, and your tests should reflect the current APIs rather than old patterns.

Current best practices:
	•	Test contexts separately with DataCase.
	•	Test LiveViews as behavior/UI state machines, not as giant rendered snapshots.
	•	Use live/2, element/3, form/3, render event helpers, and focused assertions on visible behavior.
	•	Use render_async/2 whenever async work is in play.
	•	Expect stricter DOM/component id correctness: LiveView 1.1 raises by default when LiveViewTest detects duplicate DOM or LiveComponent ids.
	•	If you upgraded from older tests, note that LiveViewTest moved from Floki to LazyHTML, so Floki-specific selectors no longer apply; use modern selectors or text_filter patterns instead.  ￼

The most important testing heuristic is:
assert user-observable outcomes and URL/state transitions, not implementation details of assigns.

13) Observability and debugging

At minimum, instrument three layers:
	•	Phoenix request/socket telemetry
	•	LiveView lifecycle telemetry
	•	your own domain/context telemetry around important operations

Phoenix’s telemetry guide remains the foundation, and LiveView ships logging/instrumentation for mount, handle_params, and handle_event lifecycles for both LiveViews and LiveComponents.  ￼

A good production-ready observability setup should track:
	•	mount timing
	•	handle_event timing by event name / LiveView module
	•	DB query timings
	•	PubSub fanout counts
	•	async task durations/failures
	•	reconnect/crash rate
	•	stream-heavy screens and payload sizes where relevant

For debugging, there are now several very useful official tools:
	•	window.liveSocket.enableDebug() for client-side payload/lifecycle logs
	•	latency simulation for UX testing
	•	Phoenix.LiveView.Debug for runtime introspection of connected LiveViews and LiveComponents
	•	HEEx debug annotations / debug attributes in dev to trace rendered markup to source lines  ￼

Those are extremely valuable in AI-assisted workflows because they shorten the “why is this rendering/patching strangely?” loop.

14) Supervisor-tree guidance

LiveView itself gives you one process per connected LiveView, which is powerful but makes it easy to misuse the process model. The safest pattern is:
	•	Let LiveViews own session/UI process state
	•	Let Task.Supervisor own background tasks
	•	Let your application supervision tree own long-lived services
	•	Let contexts call those services rather than starting ad hoc background processes in the LiveView itself

For async helpers, prefer the built-in async APIs and pass a :supervisor when you need explicit task supervision. For component updates from background work, follow the documented pattern of sending updates back through the LiveView process.  ￼

One subtle but important process lesson: don’t use LiveView as a job system. LiveView processes are for interactive state, not durable background workflows.

15) Deployment/reconnect resilience

The official deployment guide is unusually important for LiveView apps. Reconnects happen; deploys happen; node shifts happen. The state that survives best is:
	•	URL state
	•	persisted domain state
	•	recoverable form state
	•	derived UI state that can be reconstructed on mount

That guide explicitly recommends query params, DB persistence for relevant cross-device state, and relying on form recovery. If you have irreducibly complex transient state, you need an explicit recovery strategy, not wishful thinking.  ￼

Also consider static_changed?/1 patterns or equivalent UX for “a new version is available, reload” flows on long-lived pages. The official docs still support that mechanism.  ￼

16) Outdated patterns to actively avoid

These are the big ones I would now consider “likely outdated” or at least no longer preferred:
	•	Using LiveComponents for ordinary markup reuse instead of function components.  ￼
	•	Keeping large collections as ordinary assigns when streams fit.  ￼
	•	Handling shareable UI state via handle_event instead of patch/handle_params.  ￼
	•	Writing lots of custom hook JS for UI toggles that Phoenix.LiveView.JS can handle more simply.  ￼
	•	Putting auth checks only in plugs and not in mount/event handling.  ￼
	•	Capturing the socket into async tasks.  ￼
	•	Relying on old Floki-specific selectors in LiveViewTest.  ￼
	•	Treating LiveView as the place where business rules live.  ￼

17) What “idiomatic LiveView” looks like in 2026

A modern idiomatic feature usually looks like this:

A scoped route enters a live_session, on_mount establishes auth/common assigns, mount loads fast essentials and starts slow async work, handle_params owns URL-driven view state, context APIs own all real rules and filtering, large lists are streams, the template is composed from function components with declarative attrs/slots, only stateful widgets become LiveComponents, tiny JS interactions use Phoenix.LiveView.JS, small feature-specific client code is colocated when needed, PubSub fans domain changes back into the view, and telemetry/debug hooks make behavior explainable.  ￼

18) LLM-ready build rules

If you want this report to be maximally useful as “LLM context,” I would encode these as hard rules for code generation:
	1.	Use contexts as the only domain/data boundary.
	2.	Pass current_scope into context functions for protected data.
	3.	Prefer function components; require justification for LiveComponents.
	4.	Put shareable UI state in URL params and handle with handle_params/3.
	5.	Use streams for large or live-updating collections.
	6.	Use assign_async / start_async / stream_async for slow work.
	7.	Never capture the whole socket inside async tasks.
	8.	Use .form + to_form/1 + form-level phx-change / phx-submit.
	9.	Use Phoenix.LiveView.JS before custom hooks.
	10.	Use colocated hooks/JS only for small component-local behavior.
	11.	Enforce auth on mount and authz again on mutating events.
	12.	Test contexts separately and LiveViews via user-facing behavior.
	13.	Use render_async/2 in async tests.
	14.	Instrument lifecycle + domain events with telemetry.
	15.	Design every screen to survive reconnects/deploys.

19) Bottom line

If I had to compress the current consensus into one sentence:

The best modern Phoenix LiveView architecture is thin, scoped, URL-driven, stream-first, async-friendly, function-component-heavy, context-centered, and aggressively observable.  ￼

I can turn this into a tighter copy-paste “LLM system prompt / coding standard” for Phoenix LiveView teams next.