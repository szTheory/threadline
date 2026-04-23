---
status: passed
phase: "04"
verified_at: 2026-04-23
---

# Phase 4 verification

## Must-haves

| Requirement | Evidence |
|-------------|----------|
| DOC-01 README install path (≤15 min prepared env) | `README.md` documents `{:threadline, "~> 0.1"}`, `mix threadline.install`, migrate, `mix threadline.gen.triggers`, Plug quick start, and explicit `repo:` requirement for query APIs. |
| DOC-02 Domain vocabulary | `guides/domain-reference.md` defines AuditTransaction, AuditChange, AuditAction, AuditContext, ActorRef, Correlation with tiers and diagram; linked from README. |
| DOC-03 PgBouncer + GUC | README subsection + Quick start use `set_config('threadline.actor_ref', $1::text, true)`; aligns with `Threadline.Plug` @moduledoc. |
| DOC-05 Public schema docs | `@moduledoc` added/expanded on `Threadline.Capture.AuditTransaction` and `Threadline.Capture.AuditChange`; `AuditAction` moduledoc enriched. |
| Hex-ready tree | `mix.exs` uses `source_ref: "main"` until tag exists; `package/0` includes `guides/`; `MIX_ENV=dev mix docs`, `mix hex.build`, and `mix ci.all` all exit 0 (2026-04-23). |

## Automated checks

- `mix compile --warnings-as-errors` — pass
- `mix ci.all` — pass (78 tests)
- `MIX_ENV=dev mix docs` — pass (ExDoc autolink warnings for `Ecto.Repo.*` only)
- `mix hex.build` — pass

## Human verification

- None required for automated exit criteria; maintainer still performs `mix hex.publish` manually per D-01.

## Gaps

- None.
