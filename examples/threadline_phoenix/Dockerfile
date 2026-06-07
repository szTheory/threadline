# Keep this Dockerfile on Docker/BuildKit's bundled frontend so the local demo
# does not need to pull docker/dockerfile before the first build. The RUN cache
# mounts below are still supported by current Docker Compose / BuildKit.
#
# The base image is overridable so a maintainer can use an already-cached
# compatible Elixir/OTP image when Docker Hub metadata lookups are flaky.
ARG THREADLINE_DEMO_BASE_IMAGE=elixir:1.18-otp-27-slim
FROM ${THREADLINE_DEMO_BASE_IMAGE} AS demo

# Install system dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    inotify-tools \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Hex and Rebar.
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=dev
ENV DB_HOST=postgres

# The demo app has a path dependency on the repository root. Copy manifests
# before source so source/style edits do not invalidate dependency fetch layers.
WORKDIR /app
COPY mix.exs mix.lock ./
COPY config ./config

WORKDIR /app/examples/threadline_phoenix
COPY examples/threadline_phoenix/mix.exs examples/threadline_phoenix/mix.lock ./
COPY examples/threadline_phoenix/config ./config

RUN --mount=type=cache,target=/root/.hex \
    --mount=type=cache,target=/root/.cache/rebar3 \
    mix deps.get

# Copy source after dependencies. The compose demo bind-mounts the repo root at
# runtime so local root-library edits are visible without rebuilding the image.
WORKDIR /app
COPY . /app

WORKDIR /app/examples/threadline_phoenix
RUN mix compile

EXPOSE 4000

RUN chmod +x /app/examples/threadline_phoenix/entrypoint.sh

ENTRYPOINT ["/app/examples/threadline_phoenix/entrypoint.sh"]
CMD ["mix", "phx.server"]
