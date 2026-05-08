# Roadmap: Threadline

## Active Milestone

### v1.19 — Integration Breadth

**Status:** Planned
**Phases:** 69-72 (continuing from v1.18's last phase, no `--reset-phase-numbers`)
**Granularity:** coarse (per `.planning/config.json`)
**Coverage:** 10/10 v1.19 requirements mapped

**Goal:** Broaden adoption reach through reusable host/framework integration patterns, a narrower and more honest support matrix, canonical secure mount/runbook patterns, and a documented `threadline_web` extraction-readiness decision — without adding new hard deps, without teaching Threadline an auth model, and without drifting into deeper operator-product scope.

#### Phases

- [ ] **Phase 69: Integration Contracts & Support Matrix** — Freeze the reusable adapter contract, define the named support matrix, and wire verification/CI expectations so Threadline only claims combinations the repo actually proves
- [ ] **Phase 70: Sigra/Phoenix Reference Integration Refresh** — Refresh the current Sigra-backed reference path and example/docs/package wording to match the supported Phoenix/Sigra lines while keeping Sigra a soft dependency
- [ ] **Phase 71: Mount Recipes & Access Tiers** — Ship canonical admin and support-read-only mount/runbook patterns for the operator surface, including router/live-session/auth-hook placement and CLI fallback parity
- [ ] **Phase 72: Packaging Boundary Scorecard & Closeout** — Define objective `threadline_web` extraction triggers, align package/docs/module-group contracts, and close the milestone with an explicit stay-in-tree or extract-later decision

#### Phase Details

##### Phase 69: Integration Contracts & Support Matrix

**Goal**: Threadline has one stable breadth contract and one honest compatibility story before adding more host-specific examples or package-boundary rhetoric.
**Depends on**: Phase 68 (v1.18 close — shipped operator surface, upgrade-path docs, and optional-deps posture)
**Requirements**: INTEG-01, COMPAT-01, COMPAT-02
**Success Criteria**:
1. Threadline documents one reusable adapter contract covering actor extraction, additive context overrides, optional dependency behavior, and operator-surface composition across `Threadline.Plug`, `Threadline.Job`, and `Threadline.Integrations.*`.
2. The project names a narrow support matrix for Plug-only installs, Phoenix operator-surface installs, and the current Sigra-backed reference path; wording distinguishes "supported" from merely "plausible."
3. Verification/CI entrypoints prove the named breadth story, including compile-without-optional-deps and the claimed surface/reference-path combinations, so docs and package metadata cannot outrun evidence.
**UI hint**: no

##### Phase 70: Sigra/Phoenix Reference Integration Refresh

**Goal**: The current highest-leverage reference path is up to date, soft-loaded, and no longer implies stale or overly broad compatibility claims.
**Depends on**: Phase 69 (contract and matrix must exist before the reference path is refreshed against them)
**Requirements**: INTEG-02, COMPAT-03, ADOPT-09
**Success Criteria**:
1. At least one first-party breadth path ships as a reusable `Threadline.Integrations.*` reference integration that materially reduces host glue while keeping the host framework as a soft dependency.
2. Example-app and guide pins, install steps, and compatibility wording are refreshed to the currently supported Phoenix/Sigra lines with explicit caveats wherever support differs by host stack.
3. The canonical reference path is proven end to end in docs and the example app, and the recommended surface-first flow names the equivalent Mix-task or CLI fallback for capture-only adopters.
**UI hint**: no

##### Phase 71: Mount Recipes & Access Tiers

**Goal**: Adopters can copy one secure pattern for admin access and one secure pattern for support-read-only access without Threadline owning auth or roles.
**Depends on**: Phase 69 (contract/matrix) and Phase 70 (reference-path refresh)
**Requirements**: INTEG-03, ADOPT-08
**Success Criteria**:
1. The operator surface has a documented and tested host-owned access pattern for router pipeline checks, LiveView mount checks, and optional scoped investigation queries, without introducing a Threadline-owned user or role model.
2. Threadline ships canonical mount recipes for secure admin and support-read-only installs, including router placement, `live_session` / mount-auth expectations, and first verification steps.
3. Every recommended surface-first mount recipe points to an equivalent non-surface fallback path so capture-only adopters retain full operator parity where the product already supports it.
**UI hint**: no

##### Phase 72: Packaging Boundary Scorecard & Closeout

**Goal**: Close v1.19 with an evidence-based package-boundary decision and aligned docs/package contracts instead of speculative extraction pressure.
**Depends on**: Phases 69-71
**Requirements**: PKG-01, PKG-02
**Success Criteria**:
1. Threadline defines an explicit `threadline_web` extraction-readiness scorecard based on objective triggers such as version-matrix pressure, release-cadence divergence, and repeated adopter glue.
2. README, guides, module groups, release/package contracts, and migration-path wording all align to the closeout decision — expected default: stay in-tree for now.
3. The milestone closes with a clear recorded answer to "why not split yet?" or, if evidence unexpectedly justifies it, a concrete follow-on extraction milestone instead of an ad-hoc package move.
**UI hint**: no

#### v1.19 Sequencing Rationale

- **Phase 69 must come first** because Threadline should not broaden its host story before freezing the contract and compatibility language that every later phase depends on.
- **Phase 70 follows immediately** because the current Sigra/Phoenix path is the highest-leverage real host integration already near the codebase; refreshing it against the contract is the fastest way to prove the breadth story with honest caveats.
- **Phase 71 comes after the reference refresh** so mount recipes and access-tier runbooks are written from a proven path instead of speculative patterns.
- **Phase 72 closes the milestone** because the `threadline_web` decision only becomes credible after the adapter contract, reference integration, and mount/runbook burden are visible in one milestone's worth of evidence.
- **The optional-deps posture remains a release gate throughout** — every breadth change must preserve compile-without-optional-deps and avoid introducing new hard runtime dependencies.

## Milestones

- 📋 **v1.19 — Integration Breadth** — Phases 69-72 (active) — [requirements](REQUIREMENTS.md)
- ✅ **v1.18 — Adoption and Policy Hardening** — Phases 64-68 (shipped 2026-05-07) — [requirements](milestones/v1.18-REQUIREMENTS.md) · [audit](milestones/v1.18-MILESTONE-AUDIT.md) · [archive](milestones/v1.18-ROADMAP.md)
- ✅ **v1.17 — Operator Surface Foundation** — Phases 57-63 (shipped 2026-05-06) — [requirements](milestones/v1.17-REQUIREMENTS.md) · [archive](milestones/v1.17-ROADMAP.md)
- ✅ **v1.16 — Investigation Table Stakes** — Phases 53-56 (shipped 2026-05-06) — [requirements](milestones/v1.16-REQUIREMENTS.md) · [archive](milestones/v1.16-ROADMAP.md)
- ✅ **v1.15 — Host Integration Completion** — Phases 49-52 (shipped 2026-05-05) — [requirements](milestones/v1.15-REQUIREMENTS.md) · [archive](milestones/v1.15-ROADMAP.md)
- ✅ **v1.14 — Drop-in Production Adopter Slice** — Phases 44-48 (shipped 2026-05-05) — [requirements](milestones/v1.14-REQUIREMENTS.md) · [archive](milestones/v1.14-ROADMAP.md)
- ✅ **v1.13 — Docs Contract Repair** — Phases 41-43 (shipped 2026-04-26) — [archive](milestones/v1.13-ROADMAP.md)
- ✅ **v1.12 — Temporal Truth & Safety** — Phases 38-40 (shipped 2026-04-25) — [archive](milestones/v1.12-ROADMAP.md)

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 69. Integration Contracts & Support Matrix | 0/0 | Pending | — |
| 70. Sigra/Phoenix Reference Integration Refresh | 0/0 | Pending | — |
| 71. Mount Recipes & Access Tiers | 0/0 | Pending | — |
| 72. Packaging Boundary Scorecard & Closeout | 0/0 | Pending | — |

See `.planning/MILESTONE-ARC.md` for the forward-looking ranked recommendation order beyond the active milestone.
