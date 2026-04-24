---
status: passed
phase: 22
verified: "2026-04-24"
---

# Phase 22 — Verification

## Automated

| Check | Result |
|-------|--------|
| `env DB_PORT=5433 MIX_ENV=test mix ci.all` | Pass |
| `env DB_PORT=5433 MIX_ENV=test mix verify.example` | Pass |
| `env DB_PORT=5433 MIX_ENV=test mix test` (example tree alone) | Pass |

## Requirements

- **REF-01:** Runnable path-dep example under `examples/threadline_phoenix/` with documented setup, run, and test flows in `examples/threadline_phoenix/README.md` and index in `examples/README.md`.
- **REF-02:** `mix threadline.install`, `mix threadline.gen.triggers`, migrate ordering, and `MIX_ENV` / `Mix.Task.run("app.config", [])` callout mirrored in example README; triggers committed for `posts`.

## Notes

- Local verification used Docker-published Postgres on **`DB_PORT=5433`** per root `docker-compose.yml`; CI uses `DB_HOST=localhost` and the job’s Postgres service.
