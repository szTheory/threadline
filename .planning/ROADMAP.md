# Roadmap: Threadline

## Milestones

- ◆ **v1.1 — GitHub, CI, and Hex** — Phases 5–7 (in progress) — requirements: [.planning/REQUIREMENTS.md](REQUIREMENTS.md)
- ✅ **v1.0 MVP** — Phases 1–4 (shipped 2026-04-23) — [full archive](milestones/v1.0-ROADMAP.md)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1–4) — SHIPPED 2026-04-23</summary>

Phase-level specs, success criteria, and plan checklist live in [.planning/milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md). Execution artifacts: [.planning/milestones/v1.0-phases/](milestones/v1.0-phases/).

- [x] Phase 1: Capture Foundation (3/3 plans) — completed 2026-04-23
- [x] Phase 2: Semantics Layer (3/3 plans) — completed 2026-04-23
- [x] Phase 3: Query & Observability (2/2 plans) — completed 2026-04-23
- [x] Phase 4: Documentation & Release (2/2 plans) — completed 2026-04-23

</details>

### v1.1 — GitHub, CI, and Hex (in progress)

Phases **5–7** continue numbering after v1.0. Full requirement text: `.planning/REQUIREMENTS.md`.

| Phase | Name | Goal | Requirements |
| ----- | ---- | ---- | -------------- |
| 5 | Repository & remote | Canonical GitHub `origin`, URLs aligned, `main` pushed | REPO-01 — REPO-03 |
| 6 | CI on GitHub | Actions green on `main`; contributors know where to look | CI-01 — CI-03 |
| 7 | Hex 0.1.0 | Version + changelog + tag + `mix hex.publish` | HEX-01 — HEX-04 |

**Success criteria (summary):**

- **Phase 5:** `git remote -v` and `mix.exs` agree on repo URL; `main` on `origin` matches local release intent.
- **Phase 6:** GitHub Actions run for `main` is all green; README points to CI.
- **Phase 7:** `0.1.0` / `v0.1.0` / Hex package align; maintainer has published to hex.pm.

### Phase 5: Repository & remote
**Goal**: Canonical GitHub `origin`, URLs aligned, `main` pushed to `origin` for release intent.
**Requirements**: REPO-01, REPO-02, REPO-03
**Canonical refs**: `.planning/REQUIREMENTS.md` (v1.1 Repository & hosting), `mix.exs` (`@source_url`)

### Phase 6: CI on GitHub
**Goal**: GitHub Actions green on `main`; contributors know where to look for CI status.
**Requirements**: CI-01, CI-02, CI-03
**Canonical refs**: `.planning/REQUIREMENTS.md` (v1.1 Continuous integration), `.github/workflows/ci.yml`

### Phase 7: Hex 0.1.0
**Goal**: Version, changelog, tag, and Hex publish align for `threadline` **0.1.0**.
**Requirements**: HEX-01, HEX-02, HEX-03, HEX-04
**Canonical refs**: `.planning/REQUIREMENTS.md` (v1.1 Hex release), `CHANGELOG.md`, `mix.exs`

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | ---------- |
| 1. Capture Foundation | v1.0 | 3/3 | Complete | 2026-04-23 |
| 2. Semantics Layer | v1.0 | 3/3 | Complete | 2026-04-23 |
| 3. Query & Observability | v1.0 | 2/2 | Complete | 2026-04-23 |
| 4. Documentation & Release | v1.0 | 2/2 | Complete | 2026-04-23 |
| 5. Repository & remote | v1.1 | 0/? | Context + remote live | — |
| 6. CI on GitHub | v1.1 | 0/? | Not started | — |
| 7. Hex 0.1.0 | v1.1 | 0/? | Not started | — |
