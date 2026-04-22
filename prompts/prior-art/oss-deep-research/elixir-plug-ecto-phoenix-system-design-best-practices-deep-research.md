Here is the opinionated 2026 field guide I would want sitting next to me while designing and operating Elixir / Plug / Ecto / Phoenix systems in production.

I’m optimizing for the current stack shape as of April 2026: Elixir 1.19.x docs are current, OTP 28.x is the active stable line, Phoenix is at 1.8.5, LiveView at 1.1.28, Ecto at 3.13.5, Plug at 1.19.1, and Bandit 1.10.x is the default Phoenix server since Phoenix 1.7.11. Phoenix’s current releases guide also assumes dns_cluster as the out-of-the-box service discovery story, and LiveView 1.1.x picked up useful 2025 improvements like stream_async/4 and better change tracking behavior.  ￼

The big rules are these. Use processes to model runtime concerns, not to organize code. Keep durable truth in Postgres, not in clustered process state. Use ETS for fast node-local derived state, not for shared truth. Reach for persistent_term only for near-static read-mostly data. Avoid central GenServers in hot paths; shard with Registry and PartitionSupervisor. Keep websocket and LiveView payloads small and state shallow. Watch queue_time, mailbox growth, and memory before “optimizing.” Treat distributed Erlang as a private-network feature, not an internet-exposed one. Build for graceful drain, observability, and idempotent recovery.  ￼

1. The right BEAM mental model

A process is not a class, object, repository, service layer, or namespace. The Elixir docs are explicit: use a process only to model runtime properties like concurrency, shared resource access, and failure isolation. Using GenServers as a code-organization trick creates bottlenecks and makes your app slower and harder to evolve. Modules and pure functions should do most of your architectural work; processes should be where coordination or isolation is actually needed.  ￼

The second rule is that message passing is not free. Between processes on the same node, messages are copied except for ref-counted binaries and literals; across nodes, terms are encoded to the external format, sent over TCP, then decoded. Shared subterm structure is also lost on copy, which can make a value much larger in the receiving process than it looked in the sender. This is one of the most common hidden performance footguns in Elixir code that casually captures large maps, sockets, or state into tasks and callbacks.  ￼

The third rule is mailbox discipline. Selective receive on long mailboxes is expensive, because the queue must be searched until a match is found. The Erlang efficiency guide specifically calls out the common optimized pattern of sending a request with a fresh monitor/reference and receiving only replies tagged with that reference; the VM can optimize that path. For many-to-one bursty send patterns, message_queue_data: :off_heap can help, and OTP 25 improved that path, but this is profiling territory, not a blanket setting.  ￼

Also: never create atoms from untrusted input. Atoms are not garbage-collected, and the emulator exits when the atom limit is exhausted. Use *_to_existing_atom when you truly need atom conversion for a closed set.  ￼

2. How to structure Phoenix/OTP applications

A good default application tree is boring:

MyApp.Application
├─ MyAppWeb.Telemetry
├─ MyApp.Repo
├─ MyApp.Cluster          # dns_cluster or libcluster strategy wrapper
├─ {Phoenix.PubSub, ...}
├─ {Registry, ...}
├─ {PartitionSupervisor, child_spec: DynamicSupervisor, ...}
├─ {PartitionSupervisor, child_spec: Task.Supervisor, ...}
├─ MyApp.CacheSupervisor  # owns ETS tables / cache workers
└─ MyAppWeb.Endpoint

Phoenix’s telemetry docs recommend a dedicated telemetry supervisor/module. Registry is explicitly a local, decentralized, scalable process registry, and both DynamicSupervisor and Task.Supervisor are documented as single processes that can become bottlenecks, with PartitionSupervisor as the built-in answer.  ￼

That leads to the most important structural advice: do not funnel hot application traffic through one named GenServer. Use a single GenServer only when you genuinely need serialization around one resource. If you need many dynamic workers, partition the supervisor. If you need name-based routing, use Registry with partitions. If you need parallel one-off work, use partitioned task supervisors. The built-in docs now make this guidance much more explicit than older community advice did.  ￼

For libraries, be even stricter. A library should usually expose functions first and let the application decide whether those functions run inline, in tasks, behind queues, or under supervision. Elixir’s process anti-pattern guide specifically says libraries should not impose parallelization or process structure when modules/functions would do.  ￼

3. Where state should live

Keep a very sharp distinction between durable truth, ephemeral truth, and derived state.

Durable truth belongs in Postgres. User records, money, inventory, business workflow state, permissions, and anything that must survive crashes or be shared consistently across nodes should live there. Ecto’s changeset docs are blunt that database constraints are the safe, race-free validation boundary; application validations run first, but constraints are the correctness layer.  ￼

Process state is for ownership and coordination. Use it when one process should own a socket, a connection, a rate-limited resource, a state machine, or a single actor-like workflow. Do not use process state as your global cache or app-wide database.  ￼

ETS is for fast local derived state. It is node-local, not remotely accessible from other nodes, and disappears with the node. That makes it excellent for in-node caches, indexes, rate-limit counters, dedup windows, or subscription maps where rebuild-on-crash is acceptable. It makes it bad as a cross-node source of truth.  ￼

persistent_term is for very small amounts of near-static, extremely hot read-mostly data: dispatch tables, immutable config blobs, lookup maps that change rarely. Reads are constant-time, lock-free, and avoid heap copying, but writes copy the hash table and updates/deletes can trigger a global GC scan across the system. It is explicitly “not a general replacement for ETS.”  ￼

Redis is for shared external ephemeral state. Keep Redis when you need cross-node shared cache/TTL semantics, a central pubsub backbone without distributed Erlang, interoperability with non-BEAM services, or operational separation from the app nodes. Replace Redis with ETS when the data is okay to be node-local, derived, and rebuilt, and when the latency and simplicity win matters more than cluster-wide visibility. ETS docs tell you the local-only part; Phoenix PubSub docs tell you Redis remains the official option when you do want a shared external adapter.  ￼

4. ETS, done properly

ETS is one of the biggest advantages of the BEAM, and one of the easiest ways to accidentally build a memory leak.

For hot tables on modern OTP, use the concurrency knobs intentionally. OTP 25 introduced {write_concurrency, auto} and enabled decentralized_counters by default for that mode; the ETS docs recommend combining write and read concurrency for heavy bursty read/write patterns, and say it is “almost always a good idea” to combine write concurrency with decentralized counters. The catch is memory overhead: the docs explicitly warn it can become especially large when write_concurrency and read_concurrency are combined.  ￼

That means the practical rule is: turn on ETS concurrency options for genuinely hot tables, then measure memory. Do not cargo-cult read_concurrency: true, write_concurrency: true/auto onto every table. On small or lightly contended tables, you pay memory for nothing.  ￼

Another subtle footgun: if you enable decentralized_counters, some :ets.info/1 and :ets.info/2 operations, especially around size and memory, become much slower. That means scraping those values too often in production can perturb the very system you are trying to observe.  ￼

My practical ETS rubric is: cache rows or rendered fragments in ETS only when a cache miss is cheap enough to rebuild, cache invalidation is clear, and stale data on one node for a brief period is acceptable. If you need cache coherence guarantees across nodes, switch back to Redis or the database.  ￼

5. Clustering and distributed Erlang

Cluster only when the feature actually needs it. Plenty of Phoenix systems scale perfectly well as stateless web nodes plus Postgres plus a queue, with no BEAM clustering at all. Clustering adds operational surface area, network topology assumptions, and failure modes.  ￼

When you do cluster, use the current defaults. Phoenix’s releases guide now points to dns_cluster as the out-of-the-box DNS service discovery option. That is the best default on platforms where instances can resolve one another over private DNS. Use libcluster when you need other strategies, especially Kubernetes-specific ones like DNS headless-service lookup, DNS SRV, or the Kubernetes API strategy.  ￼

Do not treat Erlang cookies as real security. The distributed Erlang docs say the cookie handshake is not cryptographically secure, and node-to-node traffic is cleartext by default. Use private networking at minimum, and TLS distribution when you need strong security. Never expose dist ports casually to the public internet.  ￼

Operationally, keep node naming and discovery in rel/env.sh.eex / release config, not sprinkled through app code. The releases docs and Elixir config docs both point to runtime.exs, env.sh.eex, and release-time config providers as the right places for deployment-specific config.  ￼

6. Phoenix, Plug, and the HTTP edge

For a typical Phoenix 1.8 app, use Bandit by default unless you have a Cowboy-specific reason not to. Bandit is the default Phoenix server since 1.7.11, supports HTTP/1, HTTP/2, and WebSockets, and its docs emphasize correctness with strong protocol-conformance testing.  ￼

At the edge, get three things right early: request correlation, proxy awareness, and TLS posture. Plug.RequestId adds request IDs to Logger metadata and recommends including them in production log formatting. Plug.SSL forces HTTPS and HSTS, with 301 for GET/HEAD and 307 otherwise. Behind a reverse proxy or load balancer, Phoenix endpoint :url should reflect the external :scheme, and Plug.SSL rewrite_on should only be used when the proxy actually strips and sets the forwarded headers correctly.  ￼

Set body limits intentionally. Plug’s default parsers read in 1 MB chunks with an overall default 8 MB limit. That is sane for many apps, but not for every API, ingest path, or upload surface. Oversized-body behavior should be a deliberate product/security decision, not an inherited default.  ￼

Also remember that Phoenix’s endpoint docs now expose websocket transport knobs like :check_origin, :fullsweep_after, :compress, and :subprotocols. :check_origin defaults to true, and that default is correct for browser-facing systems. Only relax it when you explicitly understand the client class you are serving.  ￼

7. Realtime, Channels, PubSub, Presence, LiveView

Channels are still the right abstraction for high-fanout soft realtime. Phoenix’s channels guide still describes them as handling communication with and between millions of connected clients, and the JS docs remind you that a single socket connection multiplexes many channels, each backed by isolated concurrent server processes.  ￼

Authenticate sockets in connect/3, not lazily after join. Phoenix’s current channels guide shows Phoenix.Token.verify/4 against connect_info[:auth_token], and explicitly says token authentication is preferable for long-running, transport-agnostic connections. That is the right baseline. Keep browser check_origin enabled and treat cross-site websocket hijacking as a real threat, not a theoretical one.  ￼

Keep channel payloads small. With the default serializers, Phoenix sends JSON text frames; binary frames happen only if the client sends an ArrayBuffer, and only over the WebSocket transport. Large payloads multiply CPU costs in serialization, network, and mailbox pressure. Phoenix PubSub’s fastlane support is specifically designed so channel broadcasts to many subscribers can be encoded once and written directly to sockets.  ￼

For Presence, use it exactly for what it is: ephemeral replicated presence state. Phoenix’s docs describe it as transparently replicating process info across the cluster, with no single point of failure and self-healing behavior. That makes it ideal for “who is online,” typing indicators, cursor presence, and similar collaborative metadata. It does not make it your billing ledger or entitlement system.  ￼

Phoenix PubSub’s default distributed adapter is still the built-in PG2-based adapter, and its docs call out an easy production footgun: pool_size must be the same across the whole cluster, so do not derive it from System.schedulers_online/0 on heterogeneous machines. The docs also give a safe migration path with broadcast_pool_size when changing pool size in a running cluster. Use the Redis adapter when you want PubSub without distributed Erlang or when you want an external shared transport.  ￼

LiveView is excellent when the UI benefits from server ownership of state, but do not forget the cost model: after the initial HTML response, connected LiveViews become stateful server-side processes. LiveComponents run inside the LiveView process and the current docs explicitly say to prefer function components over live components, and to avoid live components merely for code organization. Use streams for large collections, because streams let you manage large client-side collections without keeping the full collection server-side. Use assign_async/3, start_async/3, and now stream_async/4, but never capture the full socket into async closures; the docs warn that doing so copies the whole socket to the task process and can be very expensive. Also note hibernate_after defaults to 15 seconds.  ￼

8. Ecto and Postgres in production

Use Postgres as the durable arbiter, and let Ecto give you observability instead of guesswork. Ecto.Repo defaults pool_size to 10; pool_count multiplies total connections and routes queries randomly across pools without regard to instantaneous availability, so you can hit a saturated pool while others are idle. Tune that only from measured contention, not intuition. The telemetry emitted on query events includes idle_time, queue_time, query_time, decode_time, and total_time. queue_time is the canary: if it is rising, the app is waiting for DB connections before it is even talking to Postgres.  ￼

Related: DBConnection’s queue controls are often misunderstood. The docs expose :queue_target with a default of 50 ms and :queue_interval with a default of 2000 ms. Those are backpressure controls. When wait times are persistently above target, the pool starts adapting and later dropping work rather than letting latency explode forever. That means blindly increasing pool sizes can simply move the bottleneck to the database server.  ￼

Put correctness in database constraints. Ecto’s changeset docs say constraints are the safe, data-race-free means of checking user input. One important footgun: deferred constraints are not surfaced back as {:error, changeset}; they raise at transaction end. Build your transaction/error handling accordingly.  ￼

Run migrations once per deploy, not from every app node “just in case.” Phoenix’s releases guide shows the release task path, and Ecto’s migration docs say migration_lock exists specifically to throttle multiple nodes to run migrations one at a time. On Postgres you can use :pg_advisory_lock; it can be a better fit for some operational setups. For concurrent index operations, follow Ecto’s documented rules: disable the DDL transaction and migration lock for that migration and run it in isolation.  ￼

One underrated hardening move is separate repos for separate duties. Ecto.Repo supports :read_only, which removes write APIs entirely from that repo module. For replica-backed read paths or analytics sidecars, that can eliminate a whole class of accidental writes.  ￼

For tests, remember the sandbox nuance: PostgreSQL supports concurrent SQL Sandbox tests; MySQL does not and may deadlock under concurrent sandbox tests.  ￼

9. Releases, deploys, 12-factor, graceful operations

In 2026, the default production artifact is still a release. Elixir’s config/release docs say config/runtime.exs runs on every boot, rel/env.sh.eex is where OS-level runtime environment setup belongs, and config providers are the mechanism for loading external config during boot. Phoenix’s releases guide reinforces that runtime config should be centralized there, and says libraries should never read environment variables directly.  ￼

That aligns cleanly with 12-factor. The still-relevant parts for Phoenix are: config in the environment, strict separation of build/release/run, stateless processes, port binding, disposability, dev/prod parity, logs as event streams, and admin tasks as one-off processes. Phoenix releases plus runtime.exs and release commands map very naturally to that model.  ￼

If you containerize, follow Phoenix’s own generated guidance and prefer Debian/Ubuntu-based images over Alpine for production releases; the current docs explicitly say this avoids DNS resolution issues seen in production. That is one of those “sounds minor until it pages you at 2 a.m.” bits of advice worth just accepting.  ￼

Graceful shutdown matters more on Phoenix than on many stacks because you often have long-lived sockets. The current Phoenix endpoint docs say the endpoint :drainer waits for ongoing requests during shutdown, and that socket connections run their own drainer before the HTTP drainer. Build your deploy process around SIGTERM, readiness changes, and drain time, not around “kill fast and let the load balancer sort it out.”  ￼

10. Observability you should consider non-optional

Start a telemetry module early in the supervision tree. Phoenix’s metrics guide explicitly recommends a telemetry supervision tree/module, and Phoenix / Plug / Ecto / LiveView / Bandit all emit useful telemetry events. Plug.Telemetry is required for full Phoenix request tracing, and opentelemetry_phoenix explicitly notes that for Bandit you should call OpentelemetryPhoenix.setup(adapter: :bandit) and install the Bandit/Cowboy-specific OTel package to capture the full request lifecycle. opentelemetry_ecto also links preload tasks back to the initiating span.  ￼

LiveDashboard is still worth running internally. The current docs call out Home, OS Data, and Metrics pages, and the metrics guide shows how to wire Phoenix, Ecto, and VM metrics via :telemetry_poller. This is especially useful for catching queue-time spikes, memory growth, scheduler pressure, and deployment regressions before you need a full incident response.  ￼

Logs should be structured and correlatable. At minimum: request ID, trace/span ID, node name, user/account IDs when available, and domain-specific identifiers like job ID, order ID, or tenant ID. Plug.RequestId already gets you partway there. Treat logs as a stream of events for search and correlation, not as a pile of human prose.  ￼

11. The footguns I would hammer into an LLM prompt

Do not introduce a GenServer just to hold a map and expose get/put/update APIs; that is code organization by process and creates a serial bottleneck.  ￼

Do not capture socket, giant assigns, or large state maps inside tasks, async streams, or spawned closures unless you have measured the copy cost. Messages and spawned closures copy data, and lost sharing can amplify the size dramatically.  ￼

Do not leave long-running processes unsupervised. Elixir’s anti-pattern guide calls out the visibility and control problems directly.  ￼

Do not use ETS as a distributed cache and then act surprised when nodes disagree or lose data on restart. ETS is local.  ￼

Do not use persistent_term as a mutable cache. Reads are brilliant; writes are costly and can trigger global GC effects.  ￼

Do not disable websocket origin checks in production browser apps because “it fixed the error.” Phoenix defaults :check_origin to true for a reason.  ￼

Do not trust forwarded headers unless your proxy strips and rewrites them, and your app is configured accordingly.  ￼

Do not set Phoenix PubSub pool_size from System.schedulers_online/0 across heterogeneous cluster nodes. The docs explicitly warn against it.  ￼

Do not “solve” DB contention by just increasing pool_count. It multiplies connections and can still route traffic into busy pools. Watch queue_time first.  ￼

Do not run migrations opportunistically from every web node on boot. Run them deliberately, once.  ￼

Do not expose distributed Erlang on untrusted networks and assume cookies are enough. They are not.  ￼

Do not call list_to_atom/1 or binary_to_atom/2 on user input.  ￼

12. My opinionated defaults for greenfield Phoenix systems

Use Elixir 1.19 on OTP 28, Phoenix 1.8, LiveView 1.1, Ecto 3.13, Plug 1.19, and Bandit unless a concrete requirement pushes you elsewhere. Start with no clustering unless the feature really needs cross-node PubSub/Presence or BEAM-native messaging. When clustering is needed, start with dns_cluster; move to libcluster only for platform-specific discovery needs. Keep durable truth in Postgres. Use ETS for hot local caches and indexes. Use persistent_term only for rarely changing global lookup/config data. Partition dynamic supervisors and task supervisors before they become bottlenecks. Keep Phoenix endpoint config and all runtime env handling in runtime.exs / release config. Turn on telemetry, LiveDashboard, request IDs, and OpenTelemetry on day one, not after the first outage.  ￼

For AI-assisted development specifically, the highest-value steering rule is this: ask the model to justify every new process, every new cache, every new shared state container, and every new piece of distributed coordination. In Elixir, the fastest way to get into trouble is not “using too little OTP”; it is adding concurrency, indirection, and state placement without a crisp runtime reason. The current official docs across Elixir, Phoenix, Ecto, and OTP all point in that same direction.  ￼

A strong next artifact here would be a condensed one-page checklist or a starter application.ex / endpoint.ex / runtime.exs template tuned to these defaults.