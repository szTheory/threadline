---
phase: 07-hex-0-1-0
plan: "01"
subsystem: release
tags: [hex, mix, changelog, docker, postgres]

requires:
  - phase: "05–06"
    provides: "Green CI contract and canonical origin"
provides:
  - "Test DB listens on configurable DB_PORT (default 5432) for Docker Compose on alternate host port"
  - "Evidence that HEX-01/HEX-02 greps and gold-bar commands through docs and hex.build pass in this environment"
affects:
  - "07-02 (tag/publish) depends on release-ready commit and Hex auth"

tech-stack:
  added: []
  patterns:
    - "Use DB_PORT=5433 with docker compose when host PostgreSQL already owns 5432"

key-files:
  created: []
  modified:
    - "config/test.exs"
    - "docker-compose.yml"

key-decisions:
  - "Map Compose PostgreSQL to host port 5433 by default so `mix test` can target Docker without stopping local Postgres."

requirements-completed:
  - "HEX-01"
  - "HEX-02"

duration: 25min
completed: 2026-04-23
---

# Phase 7 Plan 01: Release tree — version and changelog (summary)

**Release tree for 0.1.0 is present on branch; local CI and Hex build validated; Hex dry-run requires maintainer authentication.**

## Performance

- **Duration:** ~25 min (orchestrated inline)
- **Completed:** 2026-04-23
- **Tasks:** 5/6 executable in this environment; Task 6 blocked on Hex auth (see below)

## Accomplishments

- Confirmed **HEX-01**: `@version "0.1.0"` in `mix.exs`; no `0.1.0-dev` on the version line.
- Confirmed **HEX-02**: dated `## [0.1.0] - 2026-04-23` with four factual `### Added` bullets; no bare `## [0.1.0]` stub line.
- **`MIX_ENV=test mix ci.all`**: passes with Postgres from Docker when **`DB_PORT=5433`** matches Compose (host Postgres was already bound to 5432).
- **`MIX_ENV=dev mix deps.get`** / **`mix docs`**: exit 0 (Hex CLI prompted for token refresh; answered `n` — public deps only).
- **`mix hex.build`**: exit 0; package lists `lib/` and expected paths; Changelog link uses `v0.1.0` ref.

## Task commits

1. **Task 3 (infra for Task 3 acceptance)** — `test(07-01): configurable DB_PORT and Compose host mapping` (see git log).

Tasks 1–2 required **no code edits** (tree already matched plan). Tasks 4–5 produced **no tracked code changes** (docs output under `doc/` is not part of this commit set).

## Commands run (representative)

```bash
grep -F '@version "0.1.0"' mix.exs
grep -E '^## \[0\.1\.0\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$' CHANGELOG.md
DB_PORT=5433 MIX_ENV=test mix ci.all
printf 'n\n' | MIX_ENV=dev mix deps.get
printf 'n\n' | MIX_ENV=dev mix docs
printf 'n\n' | mix hex.build
```

`mix hex.build --unpack` wrote a **`threadline-0.1.0/`** directory listing `lib/`, `guides/`, `mix.exs`, `CHANGELOG.md`, etc. (artifact removed from the working tree after inspection.)

## Authentication gates

### Hex (Task 6 — `mix hex.publish --dry-run`)

- **Symptom:** `mix hex.publish --dry-run` exits with *No authenticated user found. Run `mix hex.user auth`* when the CLI cannot refresh credentials non-interactively.
- **Maintainer action:** Run **`mix hex.user auth`** (or export **`HEX_API_KEY`**) in a trusted environment, then re-run **`mix hex.publish --dry-run`** on this commit.
- **Verification after auth:** exit code 0, no upload.

**No** `git tag` and **no** real **`mix hex.publish`** (without `--dry-run`) were run in this plan.

## Deviations from plan

1. **[Rule 3 — environment]** Task 6 dry-run — Hex requires an authenticated user; non-interactive session cannot complete `mix hex.publish --dry-run` without maintainer credentials. **Fix:** authenticate locally, re-run dry-run, update this SUMMARY Self-Check to PASSED if desired.

## Self-Check: FAILED

- Task 6 acceptance (`mix hex.publish --dry-run` exit 0) **not** met in this environment pending Hex authentication.
- Tasks 1–5 acceptance checks were run and passed as documented.

## Next

- Ready for **Plan 07-02** after Task 6 is satisfied on the same release-ready commit (or proceed to 07-02 preflight if maintainer accepts dry-run done out-of-band).
