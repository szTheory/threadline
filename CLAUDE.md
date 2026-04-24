# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Threadline

Threadline is an open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines trigger-backed row-change capture, rich action semantics (actor/intent/context), and operator-grade exploration. The Hex package name is `threadline`.

## Architecture — Three Layers

The codebase is organized around three separate layers. Do not conflate their responsibilities:

- **Capture layer** — canonical persistence of row mutations via PostgreSQL triggers. Owns audit transactions, change records, trigger registration, and integrity. Does not own action naming, UI grouping, or retention policy.
- **Semantics layer** — application-level action events binding actor, intent, correlation IDs, request/job provenance, and reason. Actions are not changes; transactions are not requests; users are not always the actor.
- **Exploration/operations layer** — timelines, diffs, filters, as-of queries, exports, health checks, retention, redaction, coverage, and telemetry. This layer matures after capture + semantics prove out.

See `prompts/audit-lib-domain-model-reference.md` for the full domain model, entity definitions, and bounded contexts.

## Domain Language

Use these terms consistently in code, docs, and APIs:

- **AuditTransaction** — groups row changes from one DB transaction (not the same as a request or action)
- **AuditChange** — one row mutation in one audited table
- **AuditAction** — a semantic application-level event (e.g. `member.role_changed`)
- **AuditContext** — execution context (request, job, correlation, route, IP, auth)
- **ActorRef** — stable reference to who did it (user, admin, service account, job, system, anonymous)
- **Correlation** — ties related records across request/job/integration boundaries

## Build & Development Commands

```bash
# Dependencies
mix deps.get

# Compile
mix compile --warnings-as-errors

# Tests
mix test                    # full suite
mix test test/path_test.exs # single file
mix test test/path_test.exs:42  # single test by line

# Formatting & linting
mix format
mix format --check-formatted
mix credo --strict          # if adopted

# Verification entrypoints (canonical — cite these in CI and docs)
mix verify.format
mix verify.credo
mix verify.test
mix ci.all                  # runs all verification steps
```

## CI & Verification Conventions

These come from the project's OSS DNA (`prompts/threadline-elixir-oss-dna.md`):

- **Named entrypoints**: prefer `mix verify.*` / `mix ci.*` aliases over ad-hoc commands. Contributors and CI cite these verbatim.
- **Honest default tests**: never silently exclude heavy suites from `mix test` without updating `test/test_helper.exs` and docs together.
- **Stable CI job IDs**: keep job `id:` fields immutable in GitHub Actions workflows. Evolve `name:` freely.
- **Path filters + main**: expensive jobs still run on `main` even when PRs are path-filtered.
- **Doc contract tests**: README, guides, and example app README stay aligned via test assertions.

## Key Design Constraints

- Correct by default — harder to miss capture than to enable it.
- SQL-native — operators query audit data with plain SQL, no opaque blobs.
- Composable — idiomatic Plug, Phoenix, Ecto, Oban, and LiveView integration.
- Capture mechanism TBD — evaluate Carbonite and alternatives; do not assume one approach.
- Not a SIEM, not event sourcing, not a pgAudit replacement, not a data warehouse product.

## GSD / local planning

When running **`gsd-sdk query state.begin-phase`**, use **positional** arguments (`phase`, `slug`, `plan_count`). Flag-style `--phase` / `--name` invocations can corrupt `.planning/STATE.md` depending on `gsd-sdk` version. Phase 20 details: `.planning/phases/20-first-external-pilot/PLAN.md` (GSD execute-phase preflight).

## Reference Documents

- `prompts/audit-lib-domain-model-reference.md` — full domain model, entities, bounded contexts, API shapes
- `prompts/threadline-elixir-oss-dna.md` — engineering habits and quality bar from sibling projects
- `prompts/THREADLINE-GSD-IDEA.md` — project vision, constraints, and first milestone intent
- `prompts/Threadline Brand Book.txt` — naming, voice, visual direction
- `prompts/prior-art/` — ecosystem research (Elixir/Phoenix/Ecto best practices, auth domain, CI/CD patterns)
