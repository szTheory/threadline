# Project milestones: Threadline

Entries are newest first.

## v1.1 — GitHub, CI, and Hex (shipped 2026-04-23)

**Delivered:** Canonical GitHub `origin` with `@source_url` / docs alignment; GitHub Actions all green on `main` with maintainer-recorded CI-02 proof; **`threadline` 0.1.0** on Hex with dated `CHANGELOG.md` and **`v0.1.0`** on `origin`; Phase 8 closed audit gaps (remote/`main`, live CI, traceability).

**Phases completed:** 5–8 (7 plans).

**Key accomplishments:**

- Locked REPO-01–REPO-03 with CLI-verified evidence and `main` ↔ `origin/main` alignment.
- Landed CI-01–CI-03: stable job keys, release-hygiene jobs, README/CONTRIBUTING CI surfacing, and Nyquist contract tests for the workflow shape.
- Shipped HEX-01–HEX-04: `0.1.0` semver, changelog section, annotated tag pushed, registry-visible package.
- Refreshed Phase 8 verification so `06-VERIFICATION.md`, requirement checklists, and phase summaries agree on live GitHub state.

**Stats:**

- ~58 files touched, ~3.9k insertions in the `v1.0..HEAD` window (distribution + CI + Hex).
- ~2.4k lines of Elixir under `lib/` + `test/` (`wc` on `*.ex` / `*.exs` at close).
- 4 phases, 7 plans, 100% summaries on disk; milestone audit **passed** (2026-04-23).

**Archives:**

- Roadmap: `.planning/milestones/v1.1-ROADMAP.md`
- Requirements: `.planning/milestones/v1.1-REQUIREMENTS.md`
- Milestone audit: `.planning/milestones/v1.1-MILESTONE-AUDIT.md`
- Phase execution tree: `.planning/milestones/v1.1-phases/`

**What is next:** `/gsd-new-milestone` — define v1.2+ product requirements (see v2 backlog in `v1.0-REQUIREMENTS.md` archive).

---

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
