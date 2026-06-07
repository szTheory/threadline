defmodule Threadline.LocalDockerDxContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defp read!(path), do: File.read!(path)

  test "demo helper has stable syntax, lifecycle commands, and route inventory" do
    assert {_output, 0} = System.cmd("bash", ["-n", "bin/demo-up"])

    helper = read!("bin/demo-up")

    assert String.contains?(helper, "Usage: bin/demo-up [options]")
    assert String.contains?(helper, "--name NAME")
    assert String.contains?(helper, "--status")
    assert String.contains?(helper, "--logs")
    assert String.contains?(helper, "--down")
    assert String.contains?(helper, "--build")
    assert String.contains?(helper, "--fresh")
    assert String.contains?(helper, "--proxy")
    assert String.contains?(helper, "--proxy-host HOST")
    assert String.contains?(helper, "--proxy-network NAME")
    assert String.contains?(helper, "--list")

    assert String.contains?(helper, "validate_port_or_auto")
    assert String.contains?(helper, "choose_port demo")
    assert String.contains?(helper, "choose_port postgres")
    refute String.contains?(helper, "choose_port pgbouncer")
    assert String.contains?(helper, "require_proxy_network")
    assert String.contains?(helper, "docker network inspect")

    assert String.contains?(helper, "demo_image_exists")
    assert String.contains?(helper, "build_flag=\"--no-build\"")
    assert String.contains?(helper, "build_flag=\"--build\"")
    assert String.contains?(helper, "docker-compose.proxy.yml")
    assert String.contains?(helper, "THREADLINE_DEMO_PUBLIC_URL")
    assert String.contains?(helper, "THREADLINE_DEMO_FALLBACK_URL")

    assert String.contains?(
             helper,
             "docker image inspect \"${COMPOSE_PROJECT_NAME}-demo:latest\""
           )

    assert String.contains?(
             helper,
             "compose --profile demo up -d \"$build_flag\" --force-recreate demo"
           )

    assert String.contains?(
             helper,
             "compose --profile demo --profile pgbouncer down --remove-orphans"
           )

    assert String.contains?(
             helper,
             "docker compose \"${compose_args[@]}\" --profile demo logs -f demo"
           )

    assert String.contains?(helper, "admin@example.com / password123456")
    assert String.contains?(helper, "/users/log_in")
    assert String.contains?(helper, "/audit/timeline?correlation_id=walk-acme-4521-close")
    assert String.contains?(helper, "bin/demo-up --name ${COMPOSE_PROJECT_NAME}")
    assert String.contains?(helper, "THREADLINE_DEMO_PUBLIC_HOST")
  end

  test "compose file keeps demo resources isolated and localhost-bound by default" do
    compose = read!("docker-compose.yml")

    assert String.contains?(compose, "profiles: [\"demo\"]")
    assert String.contains?(compose, "profiles: [\"pgbouncer\"]")
    assert String.contains?(compose, "THREADLINE_DEMO_BASE_IMAGE")
    assert String.contains?(compose, "THREADLINE_DEMO_PUBLIC_URL")

    assert String.contains?(
             compose,
             "${THREADLINE_DEMO_HOST:-127.0.0.1}:${THREADLINE_DEMO_PORT:-4000}:4000"
           )

    assert String.contains?(
             compose,
             "${THREADLINE_DB_HOST:-127.0.0.1}:${THREADLINE_DB_PORT:-5433}:5432"
           )

    assert String.contains?(
             compose,
             "${THREADLINE_PGBOUNCER_HOST:-127.0.0.1}:${THREADLINE_PGBOUNCER_PORT:-6432}:5432"
           )

    assert String.contains?(compose, "edoburu/pgbouncer:v")
    refute String.contains?(compose, "edoburu/pgbouncer:latest")
    refute String.contains?(compose, "container_name:")
    assert String.contains?(compose, "dev.threadline.kind=demo")
    assert String.contains?(compose, "dev.threadline.managed-by=bin/demo-up")
    assert String.contains?(compose, "dev.threadline.root=${THREADLINE_CHECKOUT_ROOT:-}")
    assert String.contains?(compose, "dev.threadline.url=${THREADLINE_DEMO_URL:-}")

    assert String.contains?(
             compose,
             "dev.threadline.fallback-url=${THREADLINE_DEMO_FALLBACK_URL:-}"
           )

    for volume <- [
          "demo_example_deps",
          "demo_example_build",
          "demo_root_deps",
          "demo_root_build"
        ] do
      assert String.contains?(compose, volume)
    end
  end

  test "proxy override is opt-in and targets the shared Traefik localhost path" do
    proxy = read!("docker-compose.proxy.yml")

    assert String.contains?(proxy, "traefik.enable=true")
    assert String.contains?(proxy, "traefik.docker.network=${THREADLINE_PROXY_NETWORK:-proxy}")

    assert String.contains?(
             proxy,
             "traefik.http.routers.${THREADLINE_PROXY_ROUTER:-threadline}.rule=Host(`${THREADLINE_PROXY_HOST:-threadline.localhost}`)"
           )

    assert String.contains?(
             proxy,
             "traefik.http.services.${THREADLINE_PROXY_ROUTER:-threadline}.loadbalancer.server.port=4000"
           )

    assert String.contains?(proxy, "threadline_proxy")
    assert String.contains?(proxy, "external: true")
    assert String.contains?(proxy, "name: ${THREADLINE_PROXY_NETWORK:-proxy}")
    refute String.contains?(proxy, "container_name:")
  end

  test "Dockerfile preserves dependency layers ahead of source copies" do
    dockerfile = read!("examples/threadline_phoenix/Dockerfile")

    assert String.contains?(dockerfile, "bundled frontend")
    assert String.contains?(dockerfile, "ARG THREADLINE_DEMO_BASE_IMAGE=elixir:1.18-otp-27-slim")
    assert String.contains?(dockerfile, "FROM ${THREADLINE_DEMO_BASE_IMAGE} AS demo")
    refute String.contains?(dockerfile, "# syntax=docker/dockerfile")
    assert String.contains?(dockerfile, "ca-certificates")
    assert String.contains?(dockerfile, "COPY mix.exs mix.lock ./")

    assert String.contains?(
             dockerfile,
             "COPY examples/threadline_phoenix/mix.exs examples/threadline_phoenix/mix.lock ./"
           )

    assert String.contains?(dockerfile, "--mount=type=cache,target=/root/.hex")
    assert String.contains?(dockerfile, "--mount=type=cache,target=/root/.cache/rebar3")
    assert String.contains?(dockerfile, "mix deps.get")
    assert String.contains?(dockerfile, "COPY . /app")
  end

  test "entrypoint prints a full public URL when proxy mode provides one" do
    entrypoint = read!("examples/threadline_phoenix/entrypoint.sh")

    assert String.contains?(
             entrypoint,
             "THREADLINE_DEMO_PUBLIC_URL:-http://${host}:${port}"
           )
  end

  test "docs lock the helper-first Docker demo and proxy boundary" do
    guide = read!("guides/local-docker-dx.md")
    env = read!(".env.example")
    example_readme = read!("examples/threadline_phoenix/README.md")
    walkthrough = read!("examples/threadline_phoenix/WALKTHROUGH.md")

    assert String.contains?(guide, "bin/demo-up")
    assert String.contains?(guide, "Compose project name")
    assert String.contains?(guide, "project-aware follow-up commands")
    assert String.contains?(guide, "bin/demo-up --build")
    assert String.contains?(guide, "bin/demo-up --list")
    assert String.contains?(guide, "bin/demo-up --proxy")
    assert String.contains?(guide, "normal refresh skips image rebuilds")
    assert String.contains?(guide, "does not require Traefik")
    assert String.contains?(guide, "http://threadline.localhost")
    assert String.contains?(guide, "threadline.localhost.dev")
    assert String.contains?(guide, ".dev")
    assert String.contains?(guide, ".localhost")
    assert String.contains?(guide, "threadline.localhost.test")
    assert String.contains?(guide, "Docker socket access")
    assert String.contains?(guide, "shared `proxy` network")
    assert String.contains?(guide, "busy PgBouncer host port should not block")
    assert String.contains?(guide, "bundled Dockerfile")
    assert String.contains?(guide, "external frontend")
    assert String.contains?(guide, "THREADLINE_DEMO_BASE_IMAGE")

    assert String.contains?(env, "COMPOSE_PROJECT_NAME=threadline")
    assert String.contains?(env, "THREADLINE_DEMO_PUBLIC_HOST=localhost")
    assert String.contains?(env, "THREADLINE_DEMO_PUBLIC_URL=")
    assert String.contains?(env, "THREADLINE_DEMO_BASE_IMAGE=elixir:1.18-otp-27-slim")
    assert String.contains?(env, "THREADLINE_PROXY_HOST=threadline.localhost")
    assert String.contains?(env, "THREADLINE_PROXY_NETWORK=proxy")

    assert String.contains?(example_readme, "bin/demo-up")
    assert String.contains?(example_readme, "The demo does not need a shared local proxy")
    assert String.contains?(example_readme, "bin/demo-up --proxy")
    assert String.contains?(example_readme, "http://threadline.localhost")
    assert String.contains?(walkthrough, "It prints")
    assert String.contains?(walkthrough, "threadline.localhost")
    assert String.contains?(walkthrough, "Local Docker DX guide")
  end
end
