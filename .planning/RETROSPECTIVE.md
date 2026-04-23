# Project retrospective

*Living document updated after each milestone.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-04-23  
**Phases:** 4 | **Plans:** 10

### What was built

- PostgreSQL trigger-backed capture with grouped transactions and PgBouncer-safe context propagation.
- First-class audit semantics and request/job context without ETS or process dictionary stores.
- Operator-facing query helpers, trigger coverage health checks, and telemetry instrumentation.
- README-first onboarding, domain reference guide, and Hex-ready packaging.

### What worked

- Strict phase ordering (capture → semantics → query → docs) kept each slice independently verifiable.
- A single research gate (`01-01`) de-risked the highest-uncertainty decision early.

### What was inefficient

- Requirements checkboxes lagged the roadmap briefly; closing the milestone required reconciling traceability with shipped code.

### Patterns established

- `mix verify.*` / `mix ci.*` as the default quality entrypoints.
- Trigger naming prefix (`threadline_audit_%`) as the contract between SQL generation and health checks.

### Key lessons

1. Treat REQUIREMENTS.md traceability as part of “done” for each phase, not only at milestone close.
2. Keep capture logic out of `SET LOCAL` in the trigger path; document PgBouncer constraints in user-facing docs early.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: single focused execution wave through Phase 4.
- Notable: Phase directories archived under `milestones/v1.0-phases/` to cap `.planning/` growth.

---

## Milestone: v1.1 — GitHub, CI, and Hex

**Shipped:** 2026-04-23  
**Phases:** 4 | **Plans:** 7

### What was built

- Canonical GitHub hosting with `origin`, aligned package URLs, and `main` pushed for CI and releases.
- GitHub Actions contract plus release-hygiene jobs; maintainer-recorded green runs on `main`.
- Public **`threadline` 0.1.0** on Hex with `v0.1.0` tag and changelog alignment.
- Phase 8 audit closure: live CI-02 proof, traceability, and verification docs reconciled.

### What worked

- Treating **CI-02** as “green on GitHub for `origin/main`,” not only local `mix ci.all`, avoided false “done” states.
- Adding Phase 8 explicitly absorbed audit gap-closure without destabilizing Phases 5–7 scope.

### What was inefficient

- `STATE.md` and `PROJECT.md` lagged briefly behind Hex publish; milestone close required one more documentation pass.

### Patterns established

- Phase `*-VERIFICATION.md` holds **run id + SHA** literals for Nyquist and human audit replay.
- Tag-triggered Hex publish workflow separate from PR CI keeps secrets off untrusted builds.

### Key lessons

1. Close the loop on **remote vs local** (`origin/main` SHAs) before calling distribution requirements “done.”
2. Keep **REQUIREMENTS.md** traceability updates in the same change set as verification refreshes.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: focused waves through CI, Hex, then push/verify.
- Notable: Phase directories archived to `milestones/v1.1-phases/` at close.

---

## Cross-milestone trends

### Process evolution

| Milestone | Phases | Key change |
| --------- | ------ | ---------- |
| v1.0 | 4 | Established GSD phase + plan workflow for Threadline |
| v1.1 | 4 | Shipped OSS distribution: GitHub + Actions + Hex **0.1.0** |

### Cumulative quality

| Milestone | Tests | Notes |
| --------- | ----- | ----- |
| v1.0 | Growing integration + unit suite | `mix ci.all` required green at each close |
| v1.1 | + workflow/Nyquist contract tests | CI jobs extended for docs, Hex tarball, release shape |

### Top lessons (verified across milestones)

1. v1.0 — treat REQUIREMENTS traceability as part of phase “done,” not only at milestone close.
2. v1.1 — verify **GitHub truth** (SHAs, Actions runs) alongside local green builds.
