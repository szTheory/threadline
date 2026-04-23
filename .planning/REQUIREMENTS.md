# Requirements: Threadline

**Defined:** 2026-04-22  
**Milestone:** v1.1 — GitHub, CI, and Hex  
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.1 Requirements

Scoped to shipping the library from a canonical GitHub repository with CI signal on `main`, then publishing `threadline` **0.1.0** to Hex.

### Repository & hosting

- [x] **REPO-01**: `git remote -v` lists `origin` pointing at the canonical public Git repository URL
- [x] **REPO-02**: `mix.exs` `@source_url` and ExDoc `source_url` match that canonical repository URL
- [x] **REPO-03**: Branch `main` is pushed to `origin` and is the branch CI monitors (`on.push.branches` in `.github/workflows/ci.yml`)

### Continuous integration

- [x] **CI-01**: GitHub Actions workflow `.github/workflows/ci.yml` is present on `main` with stable job keys `verify-format`, `verify-credo`, and `verify-test` (unchanged contract), plus `verify-docs`, `verify-hex-package`, and `verify-release-shape` for release hygiene
- [x] **CI-02**: Latest commit on `main` has a successful Actions run for all jobs in `.github/workflows/ci.yml` on GitHub
- [x] **CI-03**: README documents where to find CI status for contributors (link to Actions and/or a status badge)

### Hex release

- [ ] **HEX-01**: Application version in `mix.exs` is `0.1.0` (no `-dev` suffix) at the commit tagged for release
- [ ] **HEX-02**: `CHANGELOG.md` includes a dated **0.1.0** section describing the initial public release (replacing or tightening the placeholder stub as appropriate)
- [ ] **HEX-03**: Git annotated or lightweight tag `v0.1.0` exists on the release commit and is pushed to `origin`
- [ ] **HEX-04**: Package `threadline` **0.1.0** is published and installable from Hex (`mix hex.info threadline` shows 0.1.0)

## v2 Requirements

Deferred to a later planning milestone (product backlog from v1.0 archive).

### Before-values, tooling, retention, export

See `.planning/milestones/v1.0-REQUIREMENTS.md` § v2 Requirements.

## Out of Scope

| Item | Reason |
|------|--------|
| `mix hex.publish` on pull requests or unauthenticated CI | Publishing runs only from `.github/workflows/hex-publish.yml` on **`push` of SemVer tags `v*.*.*`**, using the **`HEX_API_KEY`** repository secret |
| Product features (BVAL, retention, export, etc.) | Explicitly a distribution / release milestone only |
| Changing CI Elixir/OTP pin | Unless required for Hex or runner breakage; not a goal of v1.1 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REPO-01 | Phase 5 | Done |
| REPO-02 | Phase 5 | Done |
| REPO-03 | Phase 8 | Done |
| CI-01 | Phase 6 / 8 | Done |
| CI-02 | Phase 8 | Done |
| CI-03 | Phase 6 / 8 | Done |
| HEX-01 | Phase 7 | Pending |
| HEX-02 | Phase 7 | Pending |
| HEX-03 | Phase 7 | Pending |
| HEX-04 | Phase 7 | Pending |

**Coverage:**

- v1.1 requirements: 10 total  
- Mapped to phases: 10  
- Unmapped: 0 ✓  
- Pending (traceability): 5 (HEX-01 — HEX-04; REPO-03 and CI-01–CI-03 closed in Phase 8)

---
*Requirements defined: 2026-04-22*  
*Last updated: 2026-04-23 — CI release jobs + tag-triggered Hex publish (`hex-publish.yml`, `HEX_API_KEY`)*
