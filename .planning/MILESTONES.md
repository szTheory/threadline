# Project milestones: Threadline

Entries are newest first.

## v1.0 MVP (shipped 2026-04-23)

**Delivered:** Trigger-backed row capture (Path B), application semantics (`ActorRef`, `record_action/2`, Plug/Job context), query and telemetry APIs, and release-grade docs with ExDoc/Hex build gates.

**Phases completed:** 1–4 (10 plans).

**Key accomplishments:**

- Closed the capture substrate via `gate-01-01.md` and shipped `Threadline.Capture` triggers with idempotent installer tasks and CI.
- Landed semantics: `AuditAction`, six-way `ActorRef`, transaction-local GUC bridge, `Threadline.Plug`, and `Threadline.Job`.
- Shipped `Threadline.Query` (`history`, `actor_history`, `timeline`), `Threadline.Health.trigger_coverage/1`, and structured `:telemetry` events.
- Published-quality README, `guides/domain-reference.md`, LICENSE, CHANGELOG stub, ExDoc layout, and `mix hex.build` / `mix ci.all` green.

**Stats:**

- ~95 files touched from initial commit to tip (`git diff --stat` range); ~11k insertions in that window.
- ~2.3k lines of Elixir under `lib/` + `test/` (wc on `*.ex` / `*.exs`).
- 4 phases, 10 plans, 100% roadmap summaries on disk at close.

**Archives:**

- Roadmap: `.planning/milestones/v1.0-ROADMAP.md`
- Requirements: `.planning/milestones/v1.0-REQUIREMENTS.md`
- Phase execution tree: `.planning/milestones/v1.0-phases/`

**What is next:** Cut application tag `v0.1.0`, run `mix hex.publish` when ready, then `/gsd-new-milestone` for v1.1 themes (see v2 requirement backlog in archived requirements).

---
