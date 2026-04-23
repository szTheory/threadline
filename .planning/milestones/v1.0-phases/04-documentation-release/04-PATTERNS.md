# PATTERN MAP — Phase 4: Documentation & Release

**Phase:** 4  
**Generated:** 2026-04-22 (plan-phase orchestrator)

---

## New artifacts → closest analog

| Planned path | Role | Analog in repo | Notes |
|--------------|------|----------------|-------|
| `README.md` | GitHub + package front door | `CONTRIBUTING.md` (structure, headings), `lib/threadline/query.ex` @doc examples (`MyApp.Repo`, `users`) | Copy-paste blocks must match existing API examples verbatim (D-10). |
| `guides/domain-reference.md` | ExDoc extra | `prompts/audit-lib-domain-model-reference.md` (distill only; do not copy 1.6MB file) | ASCII diagram in fenced `text` block per CONTEXT D-12. |
| `LICENSE` | Hex metadata | Standard MIT one-file templates | Must match `licenses: ["MIT"]` in `mix.exs`. |
| `CHANGELOG.md` | Release signal | Typical Elixir libs: `[Unreleased]` + `[0.1.0]` stub | CONTEXT D-03. |
| Rich `@moduledoc` on capture schemas | DOC-05 | `lib/threadline/plug.ex`, `lib/threadline/job.ex`, `lib/threadline/health.ex` | Operator-oriented prose + links to install tasks and domain guide. |
| `mix.exs` `docs/0`, `package/0` | Hex + ExDoc | Current `mix.exs` (minimal `docs/0` today) | **Authoritative UX:** `04-CONTEXT.md` D-07 keeps `main: "Threadline"` (overrides RESEARCH.md suggestion of `main: "readme"`). D-06: `source_ref: "main"` until release tags exist. |

---

## Invariants (do not violate)

- `repo:` is explicit on `Threadline.history/3`, `actor_history/2`, `timeline/2` — README must not imply implicit repo.
- PgBouncer story: no `SET` in trigger; GUC via `set_config(..., true)` in same transaction as writes — align with `lib/threadline/plug.ex` @moduledoc and `gate-01-01.md`.

---

## PATTERN MAPPING COMPLETE
