# Local Docker DX

Threadline's local Docker setup is for three jobs:

| You want to... | Use this path |
| --- | --- |
| Click through the Phoenix operator demo | `bin/demo-up` |
| Run the library test gate against PostgreSQL | `docker compose up -d` + `DB_PORT=5433 mix ci.all` |
| Keep several local demos running at once | Let each stack use its own Compose project name and host ports |
| Use a friendly local hostname | `bin/demo-up --proxy` when you already run a shared local proxy |

The short version: container ports stay boring and stable, host ports are the
only thing that need to move. Inside Compose, the demo app still talks to
Postgres at `postgres:5432`. From your laptop, `bin/demo-up` prints the actual
browser URLs, sign-in credentials, and cleanup command for the stack it started.
The default path does not require Traefik, Caddy, or port 80.

Read only the section for the job in front of you. The troubleshooting section
is there for the moment Docker says a port or container already exists.

## Try the UI demo

From the repository root:

```bash
bin/demo-up
```

The helper starts the Phoenix demo, PostgreSQL, migrations, and walkthrough
data. It prints the project name, sign-in credentials, and the most useful
routes:

- home
- sign in
- `/audit`
- timeline filtered to the walkthrough correlation id
- evidence
- redaction drift
- trigger coverage

Use the printed sign-in credentials:

```text
admin@example.com / password123456
```

When port `4000` is free, the demo opens at `http://localhost:4000`. If another
project already owns that port, the helper picks another local port and prints
that URL instead.

When you change local code, rerun the same command:

```bash
bin/demo-up
```

If the demo is already running, the helper refreshes that same Compose project,
keeps the same browser port, recreates the Phoenix container, waits for
`/audit`, and then prints the ready URL. When the project image already exists,
the normal refresh skips image rebuilds so style/source edits do not pay Docker
Hub metadata or dependency-fetch costs. You should only need to refresh the
browser after it reports ready.

The helper owns the normal lifecycle:

```bash
bin/demo-up --status
bin/demo-up --logs
bin/demo-up --down
bin/demo-up --build
bin/demo-up --fresh
bin/demo-up --list
```

Use `--build` when the Dockerfile, dependency manifests, or base image choice
changed and you want to rebuild the demo image.

Use `--fresh` when you want to delete the stack's Compose volumes and force
dependencies/build artifacts/database state to be recreated.

`bin/demo-up` prints project-aware follow-up commands. If you start a named
stack, use the printed commands or pass the same `--name` when you ask for
status, logs, cleanup, or a fresh reset.

Use `--list` when you have several Threadline checkouts running and want the
project names, URLs, and cleanup commands for all helper-managed demo stacks.

## Run the test database

For contributor work, the default Compose stack starts only PostgreSQL:

```bash
docker compose up -d
DB_PORT=5433 mix ci.all
```

The host port is `5433` so local PostgreSQL can keep `5432`. The container still
uses PostgreSQL's normal `5432` internally. If you choose another host port,
pass the same value to Mix:

```bash
COMPOSE_PROJECT_NAME=threadline-ci-a THREADLINE_DB_PORT=5434 docker compose up -d
DB_PORT=5434 mix ci.all
COMPOSE_PROJECT_NAME=threadline-ci-a docker compose down --remove-orphans
```

Use the PgBouncer profile only when you are checking transaction-pool topology:

```bash
docker compose --profile pgbouncer up -d
```

The local topology commands live in the contributor guide.

## Run multiple local stacks

Compose scopes its generated containers, networks, and volumes by project name.
That project name is what lets two copies of Threadline, or Threadline plus
another Phoenix demo, run at the same time without sharing resources.

`bin/demo-up` handles the normal case automatically:

- It derives a project name from the checkout path.
- It keeps service-to-service addresses stable inside Docker.
- It searches for free host ports for the browser and database.
- It refreshes an existing same-project demo in place instead of silently
  starting a second copy on a new port.
- It prints project-aware lifecycle commands.
- It labels demo containers so `bin/demo-up --list` can find running stacks.

Use explicit values when you want predictable names or ports:

```bash
bin/demo-up --name threadline-demo-a --demo-port 4100 --db-port 5434
bin/demo-up --name threadline-demo-b --demo-port 4101 --db-port 5435
```

Manual Compose works too:

```bash
COMPOSE_PROJECT_NAME=threadline-demo-a THREADLINE_DEMO_PORT=4100 THREADLINE_DB_PORT=5434 \
  docker compose --profile demo up demo --build
```

If you copy `.env.example` to `.env` in more than one checkout, change
`COMPOSE_PROJECT_NAME` in each checkout. Reusing the same project name means
those checkouts intentionally operate on the same Compose stack.

## Optional friendly hostname

Threadline does not require Traefik, Caddy, or another shared reverse proxy for
the local demo. The default is the lower-maintenance path: bind services to
localhost, choose safe host ports, and print the exact URLs.

If you already run a shared Traefik proxy on a Docker network named `proxy`, use
the opt-in hostname path:

```bash
bin/demo-up --proxy
```

That starts the same demo stack and also joins the Phoenix container to the
external proxy network with Traefik labels for:

```text
http://threadline.localhost
```

The helper still publishes and prints a fallback `127.0.0.1:<port>` URL. That
fallback is useful when the shared proxy is stopped, misconfigured, or already
routing the hostname to another stack.

Use a different friendly host when you want two proxy-routed Threadline demos at
once:

```bash
bin/demo-up --proxy --name threadline-a --proxy-host threadline-a.localhost
bin/demo-up --proxy --name threadline-b --proxy-host threadline-b.localhost
```

Proxy mode is explicit because a shared proxy is shared machine state: it owns
port `80`, reads Docker labels, and commonly has Docker socket access. That can
be a good local-maintainer convenience, but it is not a portable requirement for
an OSS demo.

Do not use `threadline.localhost.dev` for the HTTP demo. The `.dev` TLD is
HTTPS-preloaded in modern browsers, so an HTTP-only Phoenix demo will fail or
redirect unexpectedly unless you also configure local TLS.

Use `.localhost` for friendly local names, such as `threadline.localhost` or
`demo.threadline.localhost`. Do not make `threadline.localhost.test` canonical:
`.test` is reserved, but it does not imply loopback resolution and may require
manual DNS or `/etc/hosts` setup.

Bring-your-own Caddy or nginx is fine, but Threadline's first-class helper mode
targets Traefik because sibling local demos already use Docker labels on the
shared `proxy` network. If you use another proxy, keep the default helper path
as the fallback source of truth and point your proxy at the demo container's
internal port `4000`.

## Troubleshooting

**Port already in use.** Run `bin/demo-up` without fixed ports and let it choose
free ones. For Postgres-only stacks, set a different `THREADLINE_DB_PORT` and
use the same value as `DB_PORT` for Mix.

**A PgBouncer port is busy while starting the demo.** The full demo starts only
Phoenix and PostgreSQL. PgBouncer is still available through its Compose profile,
but a busy PgBouncer host port should not block the normal `/audit` demo.

**The browser URL is not `localhost:4000`.** Trust the URL printed by
`bin/demo-up` or the demo container. The app still listens on port `4000` inside
the container; Docker may publish it on a different host port.

**`bin/demo-up --proxy` says the proxy network is missing.** Start your shared
local proxy first, create the expected external network, or rerun without
`--proxy`. The portable default path does not need the `proxy` network.

**`threadline.localhost` does not load.** Check `bin/demo-up --status` for the
fallback URL and open that first. If the fallback works, inspect your shared
proxy stack: another project may own the hostname, Traefik may not be attached
to the same network, or port `80` may be owned by a different process.

**Cleanup left a demo container running.** Prefer the helper:

```bash
bin/demo-up --down
```

It includes the demo and optional PgBouncer profiles plus the project name
automatically. Some Compose versions omit profiled services from plain
`docker compose down` unless the profile is present.

**The browser still shows old code.** Run `bin/demo-up` again and wait for the
ready message. The demo bind-mounts the checkout, but compiled Elixir state
lives in container volumes, so the helper recreates the Phoenix container before
asking you to refresh the browser. If the Dockerfile or dependencies changed,
run `bin/demo-up --build`. If state still looks stale, run `bin/demo-up --fresh`.

**A copied `.env` makes two checkouts affect each other.** Give each checkout a
different `COMPOSE_PROJECT_NAME`, or use `bin/demo-up` and let it derive one.

**Rebuilds feel slower than expected.** The Dockerfile keeps dependency fetches
ahead of source copies and uses BuildKit caches for Hex/Rebar downloads. The
local demo also uses Compose volumes for container-native `deps` and `_build`
outputs, so the first run for a new project name may still need to populate
those volumes.

The demo Dockerfile intentionally uses Docker/BuildKit's bundled Dockerfile
frontend instead of a `# syntax=docker/dockerfile:*` directive. Pulling that
external frontend before the first build is another Docker Hub network request;
the bundled frontend keeps the local demo less brittle while preserving the
cache mounts on current Docker Compose / BuildKit.

The first build still needs an Elixir base image. The default is
`elixir:1.18-otp-27-slim`; if Docker Hub metadata lookups are flaky and you
already have another compatible image cached, set `THREADLINE_DEMO_BASE_IMAGE`
before running the helper. Once the project image exists, normal `bin/demo-up`
refreshes skip image rebuilds; use `--build` only when you need a rebuild.

```bash
THREADLINE_DEMO_BASE_IMAGE=elixir:1.18-otp-27-slim bin/demo-up
```
