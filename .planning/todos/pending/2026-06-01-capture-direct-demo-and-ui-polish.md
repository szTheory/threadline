---
created: 2026-06-01T17:59:55.660Z
title: Capture direct demo and UI polish
area: planning
files:
  - docker-compose.yml
  - examples/threadline_phoenix/Dockerfile
  - examples/threadline_phoenix/entrypoint.sh
  - examples/threadline_phoenix/README.md
  - examples/threadline_phoenix/config/dev.exs
  - examples/threadline_phoenix/lib/threadline_phoenix_web/endpoint.ex
  - examples/threadline_phoenix/priv/repo/seeds.exs
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/operator_surface/live/
  - lib/threadline/operator_surface/components/
  - test/threadline/operator_surface/
---

## Problem

Two direct commits landed while the project was in Hold mode rather than inside an active GSD milestone:

- `253bec3 Add containerized Phoenix demo` — adds `docker compose up demo --build` support for the Phoenix reference app, including Postgres dependency wiring, Dockerfile/entrypoint, host binding, LiveView socket routing, README quick start, and idempotent seeds.
- `f23a9cc Polish operator surface design system` — refactors the embedded Operator Surface CSS into scoped `--tl-*` tokens and `.tl-*` BEM blocks, then migrates LiveView/component markup and tests.

The code is committed and verified, but the planning authority surfaces still describe Hold / post-v1.30 state and do not yet decide whether this work should be recorded as direct Hold-mode hardening, a seed for the next milestone, or a docs/changelog update.

## Solution

During the next planning hygiene pass, decide how to reflect these commits in GSD:

- update `STATE.md` / `ROADMAP.md` direct-work notes if this is Hold-mode hardening;
- consider a short `PROJECT.md` capability note if the Docker demo is now part of adopter evaluation;
- decide whether CHANGELOG or release notes need an unreleased entry for the operator-surface polish and containerized demo;
- keep v1.28 external-pilot gating unchanged unless real adopter signal appears.
