# Requirements: Threadline

**Defined:** 2026-05-07
**Milestone:** v1.19 — Integration Breadth
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Milestone goal:** Broaden adoption reach through reusable host/framework integration patterns, an honest support matrix, canonical secure mount/runbook patterns, and a documented `threadline_web` extraction-readiness decision — without adding new hard deps, without teaching Threadline an auth model, and without expanding into deeper operator-product scope.

## v1.19 Requirements

### INTEG — Adapter contracts and host wiring

- [x] **INTEG-01**: Threadline publishes one stable adapter contract for actor extraction, additive context overrides, optional dependency behavior, and operator-surface composition across `Threadline.Plug`, `Threadline.Job`, and `Threadline.Integrations.*`.
- [x] **INTEG-02**: At least one first-party breadth path ships as a reusable `Threadline.Integrations.*` reference integration that materially reduces host glue while keeping the host framework as a soft dependency.
- [x] **INTEG-03**: The operator surface has a documented and tested host-owned access pattern for router pipeline checks, LiveView mount checks, and optional scoped investigation queries, without introducing a Threadline-owned user or role model.

### COMPAT — Support matrix and verification honesty

- [x] **COMPAT-01**: Threadline documents a narrow support matrix that names only proven combinations for Plug-only installs, Phoenix operator-surface installs, and the current Sigra-backed reference path.
- [x] **COMPAT-02**: Verification and CI entrypoints exercise the claimed breadth story, including compile-without-optional-deps and the named surface/reference-path combinations, so docs do not promise ranges that the repo does not prove.
- [x] **COMPAT-03**: Example-app and guide dependency pins, install steps, and compatibility wording are refreshed to the currently supported Phoenix/Sigra lines with explicit caveats where support differs by host stack.

### ADOPT — Mount recipes and runbooks

- [x] **ADOPT-08**: Threadline ships canonical mount recipes for secure admin and support-read-only operator-surface installs, including router placement, `live_session` / mount-auth expectations, and first verification steps.
- [x] **ADOPT-09**: The canonical reference path is proven end to end in docs and the example app, and every recommended surface-first workflow names the equivalent Mix-task or CLI fallback for capture-only adopters.

### PKG — Packaging-boundary decision

- [x] **PKG-01**: Threadline defines an explicit `threadline_web` extraction-readiness scorecard based on objective triggers such as version-matrix pressure, release-cadence divergence, and repeated adopter glue.
- [x] **PKG-02**: v1.19 closes with a documented package-boundary decision — expected default: stay in-tree for now — with README, guides, module-grouping/package contracts, and migration-path wording aligned to that decision.

## Future Requirements

- **RETN-ADMIN-01**: Retention admin viewer with "last purge" and run-history visibility — deferred until `audit_retention_runs`-style capture machinery exists and there is evidence that this belongs in the product surface rather than only in Mix-task workflows.
- **VIEWS-01**: Saved views or shared bookmarks inside the operator surface — deferred because it would introduce ownership/visibility state into a library that has stayed auth-agnostic since v1.15.
- **EXPO-QUEUE-01**: Queued or scheduled exports with status pages and storage adapters — deferred until real adopters report that sync-or-chunked current-view exports are insufficient.
- **WEB-PKG-02**: Actual `threadline_web` extraction — deferred unless the v1.19 scorecard shows clear version-pressure or release-cadence pressure.
- **GOV-01**: Mutable policy or governance UI (retention edits, redaction edits, purge controls) — deferred beyond v1.19; the read-only ceiling remains firm.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New required runtime dependencies in `threadline` | v1.19 should broaden adoption through contracts and examples, not by widening the dependency graph. |
| Threadline-owned auth model, roles, or saved-view ownership | Breaks the v1.15+ host-owns-auth boundary and pulls product-state concerns into the core library. |
| Forced `threadline_web` extraction during this milestone | The right deliverable is an evidence-based scorecard and decision, not a package split driven by aesthetics. |
| Retention admin capture machinery | Requires net-new write-side surface (`audit_retention_runs`-style history) and broadens scope away from integration breadth. |
| Queued exports, scheduled exports, or storage-adapter workflows | Add Oban/storage/platform concerns without solving the current adoption bottleneck. |
| Mutable policy UI or destructive operator actions | The read-only ceiling stays intact; runtime policy mutation and purge controls are compliance-sensitive and remain outside v1.19. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INTEG-01 | Phase 69 | Complete |
| COMPAT-01 | Phase 69 | Complete |
| COMPAT-02 | Phase 73 | Complete |
| INTEG-02 | Phase 70 | Complete |
| COMPAT-03 | Phase 73 | Complete |
| ADOPT-09 | Phase 73 | Complete |
| INTEG-03 | Phase 73 | Complete |
| ADOPT-08 | Phase 73 | Complete |
| PKG-01 | Phase 74 | Complete |
| PKG-02 | Phase 74 | Complete |

**Coverage at roadmap open:**
- v1.19 requirements: 10 total
- Mapped to phases: 10/10 ✓
- Unmapped: 0

## Notes

- Phase numbering continues from v1.18; v1.19 starts at **Phase 69** (no `--reset-phase-numbers`).
- Research for this milestone recommends no new hard deps, retention of the current optional Phoenix/LiveView posture, and explicit honesty about which host-stack combinations are actually proven.
- The expected closeout outcome is **stay in-tree for now** unless real adopter evidence justifies opening a later extraction milestone.
