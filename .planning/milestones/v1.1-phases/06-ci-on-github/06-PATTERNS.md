# Phase 6 — Pattern map (CI on GitHub)

**Padded phase:** 06  
**Phase directory:** `.planning/phases/06-ci-on-github`

## Files touched (from CONTEXT + RESEARCH)

| File | Role | Closest analog | Notes |
|------|------|----------------|-------|
| `.github/workflows/ci.yml` | CI contract (job keys, triggers, services) | Self — unchanged structure since Phase 5 | Preserve `verify-format`, `verify-credo`, `verify-test` keys verbatim (`06-CONTEXT` D-07). |
| `mix.exs` | `aliases/0` — local parity with CI | `.planning/phases/05-repository-remote/05-01-PLAN.md` (read-only checks) | `ci.all` should mirror CI ordering when extended (`06-RESEARCH.md` Mix table). |
| `README.md` | Contributor CI discovery | Self — v1.0 README already has CI paragraph | Tighten layout vs D-05 (badge row adjacency). |
| `CONTRIBUTING.md` | Deep CI / `act` parity | Self | Optional single `/actions` hub link if gap vs D-05. |

## Code excerpts (contract)

**Job keys** (must not rename):

```yaml
jobs:
  verify-format:
  verify-credo:
  verify-test:
```

**Triggers on `main`** (Phase 5 verified):

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

## Data flow

- **Local:** `mix ci.all` → formatter, credo, tests (`MIX_ENV=test` via `cli/0`).
- **GitHub:** Three parallel jobs; `verify-test` includes `mix compile --warnings-as-errors` then `mix verify.test` with Postgres service.

## PATTERN MAPPING COMPLETE
