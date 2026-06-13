---
gsd_state_version: 1.0
milestone: v1.36
milestone_name: Operator Surface Light Mode
status: executing
last_updated: "2026-06-13T01:05:49.009Z"
last_activity: 2026-06-13 -- Phase 166 planning complete
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 1
  completed_plans: 0
  percent: 0
---

# Project State: Threadline

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-12)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current focus:** v1.36 Operator Surface Light Mode — Phase 166 (`unfreeze-token-lane-mechanism`) planned and ready to execute

## Current Position

Phase: 166 of 166–170 (planned)
Plan: 1 of 1 ready
Status: Ready to execute
Progress: [░░░░░░░░░░] 0/5 phases
Last activity: 2026-06-13 -- Phase 166 planning complete

## Performance Metrics

- **Last Milestone Shipped**: v1.35 — Unified Logo & Brand Book v2 (2026-06-12)
- **Scope completion (assessment)**: **~92–95%** for stated narrow audit-platform scope (band: near-done)
- **Hex distribution**: in-repo and hex.pm latest **0.9.0** (tag `v0.9.0`, published 2026-06-03; prior `v0.8.0` 2026-06-03, `v0.7.0` 2026-05-30)
- **Path-to-done thread**: `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`
- **Posture thread**: `.planning/threads/2026-05-29-post-v1.29-posture.md`
- **v1.28 pilot readiness**: `.planning/threads/2026-05-29-v1.28-pilot-readiness.md`

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| external-pilot | v1.28 pilot unblockers | **Deferred** until sustained real-adopter signal |
| post-v1.29 | Hold mode | **Superseded** by v1.31 polish milestone (2026-06-03) |
| v1.22 DEFER | COMPLIANCE-PACK, LEGAL-HOLD, IMMUTABLE-ARCHIVE | Deferred until procurement pressure |
| host-class | STG-01 host staging depth | Integrator-owned; v1.28 when signal |
| Pow / bearer auth lane | On explicit demand only | Not planned |
| Phase 135-seed-enrichment-ia-lock-in P01 | 3m | 3 tasks | 4 files |
| Phase 135 P02 | 2m | 2 tasks | 3 files |
| Phase 135 P03 | 8m | 3 tasks | 4 files |
| Phase 135 P04 | 5m | 2 tasks | 2 files |
| Phase 144 P02 | 2m16s | 2 tasks | 5 files |
| Phase 144 P03 | 3m47s | 2 tasks | 4 files |
| Phase 144 P04 | 15min | 3 tasks | 8 files |
| Phase 160 P01 | 45min | 4 tasks | 10 files |
| Phase 159 P02 | 35min | 3 tasks | 1 files |
| Phase 159 P03 | 9min | 2 tasks | 1 files |
| Phase 161 P01 | 68min | 4 tasks | 29 files |
| Phase 162 P01 | 17min | 3 tasks | 16 files |
| Phase 162 P02 | 16min | 2 tasks | 5 files |
| Phase 162 P03 | 16min | 3 tasks | 10 files |
| Phase 164 P01 | 10min | 2 tasks | 3 files |
| Phase 163 P01 | 25min | 5 tasks | 6 files |

## Accumulated Context

### Pending Todos

- Execute Phase 166 (`unfreeze-token-lane-mechanism`) with `/gsd-execute-phase 166`.
- **Human gate (after Phase 166, before Phase 167):** light-lane design review — user eyeballs the rendered light surface (status-tint keystone included) before retune effort is spent.
- **Human gate (after Phase 170):** end-of-milestone UAT across dark/light/system modes before closeout.
- **Standing caution (all v1.36 phases):** never stage, edit, or revert the user's uncommitted nav-overhaul lane (~29 files under lib/, examples/, test/), including its 3 pre-existing test failures.
- **Phase 166 atomicity:** `style.ex` and `style_contract_test.exs` must land in the SAME wave — the contract test reads `style.ex` directly, so the refute flips and the `color-scheme: light` introduction are inseparable (else `mix verify.test` is red between commits).

### Roadmap Evolution

- Phase 130.1 inserted after Phase 130: Address tech debt: planning metadata hygiene (URGENT)
- Milestone v1.29 archived 2026-05-29
- **Post-v1.30 direct-PR work (2026-05-30, no milestone):**
  - **0.7.0 release** — unblocked the stuck release-please PR; fixed `bin/verify-release-shape` to accept release-please's CHANGELOG heading; published `v0.7.0` to Hex. Fixed the operator-surface timeline crash on `?correlation_id=` (`FilterParams` `String.to_existing_atom` → compile-time allowlist) that had kept the v1.30 Playwright job red.
  - **Release-pipeline hardening** — generalized `bin/post-publish-distribution-sync` (was 0.5→0.6-pinned); added `workflow_dispatch` to `ci.yml` so "Bootstrap CI on Release PR" stops failing.
  - **Test determinism** — fixed the ~40% retention-pruner flake + a telemetry cross-contamination flake; added `test/support/async_helpers.ex`, `mix verify.flake`, and a nightly **Flake Detection** workflow. See `CONTRIBUTING.md` "Deterministic tests".
- **Direct-PR work (2026-06-03, no milestone):**
  - **Operator surface** — first-class positioning + accessibility pass (#16); deterministic evidence `record_*` export assertions (#18).
  - **0.8.0 + 0.9.0 cuts** — published to Hex via release-please.
  - **Release-please born-red root-cause fix (#22)** — every release PR was born red because release-please bumped `mix.exs` but not the adoption-pilot guide, failing `adoption_pilot_doc_contract_test`. Fixed via `extra-files` + `x-release-please-version` annotation so the SSOT line is bumped atomically in the release commit (green by construction, no manual prep). `bin/post-publish-distribution-sync` now owns only the post-publish Hex row; a guard test enforces the wiring. See memory `release-runbook` and `CONTRIBUTING.md`.
- **Milestone v1.31 opened (2026-06-03):** Hold superseded by a non-signal-gated polish milestone. Ten POLISH-* phases were planned in a fully pre-decided order: measure → enrich → systematize → apply (least-iterated first) → hub → flows → motion → responsive → sweep.
- Phase 144 added: Close gap: POLISH-AUDIT and POLISH-DS
- **v1.31 closeout hygiene (2026-06-05):**
  - The pending "Capture direct demo and UI polish" todo is resolved: the Docker demo is documented in `examples/threadline_phoenix/README.md`, operator-surface polish was absorbed by v1.31, and release notes already cover the automated operator-surface/design-system gate.
  - Phase 135 and Phase 137 HUMAN-UAT records are terminal `status: complete`; their checks are automated by `operator-phase-135-uat.spec.ts` and `operator-prove-mobile.spec.ts` under `mix verify.example_browser`, so no human UAT remains.
- **Milestone v1.33 opened (2026-06-05):** Brand Review + Direction Selection reviews the existing v1.32 `brandbook/` artifacts before public rollout. Phase 150 added `logo-primary-light.svg` after browser preview showed the dark primary logo was too pale on white README/GitHub surfaces.
- **Phase 152 targeted revisions complete (2026-06-06):** Human review selected stand-alone brandbook truth cleanup. `brandbook/` now presents the current brand system without refresh/audit backstory framing.
- **Phase 153 UI-SPEC approved (2026-06-06):** Verification closeout design contract created and checked across copywriting, visuals, color, typography, spacing, and registry safety.
- **Phase 153 verification and closeout complete (2026-06-06):** Current-tree JSON/SVG/HTML parse, direct-open browser, desktop/mobile screenshots, historical-frame scan, binary exclusion, file inventory, and file-size evidence passed. v1.33 is archive-ready with public rollout and legal/trademark work deferred.
- **Milestone v1.33 archived (2026-06-06):** Roadmap, requirements, audit, and phase history are archived under `.planning/milestones/`; fresh requirements are needed before public rollout work.
- **Milestone v1.34 opened (2026-06-06):** Local Docker Admin UI DX focuses on helper-first `bin/demo-up`, localhost-bound dynamic ports, Compose project isolation, cache-friendly Docker behavior, printed `/audit` URLs, lifecycle commands, and docs. Traefik/subdomain routing is deferred; `.localhost` is the future-safe hostname family if proxy support is later added.
- **v1.34 implementation complete (2026-06-06):** `bin/demo-up` now supports project-aware lifecycle commands, `--build`, no-build refreshes when a project image exists, port validation, optional public host, and clearer failure guidance. Compose/Dockerfile now support an overridable demo base image, bundled Dockerfile frontend, `ca-certificates`, localhost-bound ports, project-scoped volumes, and pinned PgBouncer. Docs cover helper-first DX, multi-stack ports, cleanup, cache behavior, and deferred proxy/subdomain routing.
- **Milestone v1.35 roadmap created (2026-06-11):** Unified Logo & Brand Book v2 — phases 159–163 per the approved plan `~/.claude/plans/have-to-compare-it-lexical-shore.md`. 159 (audit+research) ∥ 160 (glyph pipeline) → 161 (tournament, human checkpoint rounds, user picks winner) → 162 (brand book v2 + UAT) → 163 (optional product rollout, decision-gated). 28/28 requirements mapped; operator surface `style.ex` frozen in all core phases.
- **Milestone v1.35 shipped + archived (2026-06-12):** C13 topstitch-geist identity, brand book v2, product rollout, and light-mode strategy decision [165-01] (supersedes [136-01]; v1.36 seeded via SEED-004). Archives under `.planning/milestones/v1.35-*`.
- **Milestone v1.36 roadmap created (2026-06-12):** Operator Surface Light Mode — phases 166–170 per the approved 165 recommendation's pre-decided breakdown: 166 (unfreeze + 45-token light lane + `data-tl-theme` mechanism, contract amended same-wave) → 167 (component retune, largest) → 168 (accessibility AA mirror) ∥ 169 (`__light__` screenshots + example + docs) → 170 (brand alignment + closeout). 15/15 requirements mapped. Human gates: light-lane design review after 166; end-of-milestone UAT after 170.

### Decisions

- [136-01]: Dark-only remains intentional; no `prefers-color-scheme`, no light mode, no theme toggle. *(To be superseded by [165-01] in Phase 166 per THEME-04 — the approved recommendation is the unfreeze; the ledger entry lands with the same-wave contract amendment.)*
- [136-01]: Lift muted/status contrast and make hover/focus/disabled states explicit through shared `--tl-*` tokens before per-screen polish.
- **130.1-02 (2026-05-29):** Nyquist waivers for doc-only phases 128–129; 130-VALIDATION superseded footnote; `mix ci.all` green at closeout.
- **130-02 (2026-05-28):** SUMMARY SSOT at `conventions/summary-frontmatter.md`; GAP IDs for 125–127 only; single `mix ci.all` in 130-VERIFICATION.
- **130-01 (2026-05-29):** Phase 125 archived under `milestones/v1.27-phases/`; `125-VALIDATION.md` finalized after Tier 1 green.
- **128-02 (2026-05-28):** phx-gen-auth mount uses `&MyApp.Audit.authorize_operator/1` with scope-first lookup and `is_admin: true` gate.
- **v1.29 posture (2026-05-29):** Hold for milestones; pre-pilot hardening: `mix verify.hex_evaluator`, WALKTHROUGH ConnCase tests; pilot pack queued.
- Full decision log: `.planning/PROJECT.md` Key Decisions table.
- [Phase ?]: Generalize actor helpers
- [Phase ?]: D-05 fix: setup rows actor-attributed and backdated
- [Phase ?]: D-06: named actor literals in Manifest
- [135-03]: Membership role change backdated outside 24h window (D-05 compatible); D-13 UPDATE satisfied by ticket/ticket_replies in-window mutations
- [135-03]: agent2 used for role flip to guarantee Ecto sends real SQL UPDATE (trigger fires)
- [135-03]: SavedView actor_ref uses type: :user (matches Timeline mount query for admin)
- [135-04]: D-03: Recipe table in DEMO-MANIFEST.md backed by demo_manifest_contract_test.exs; 24 rows covering all operator-surface screen states
- [135-04]: D-04 deferred: Coverage fully-covered/all-empty state noted as Phase-138-owned (trigger-registration dependent, not seed-reachable)
- [135-04]: demo_manifest_contract_test.exs kept separate from demo_manifest_test.exs (different concerns: doc vs module)
- [Phase 144]: Operation badge semantics stay in Presentation as pure helpers; no Phoenix component/public UI API expansion.
- [Phase 144]: Unknown operations use string-safe normalization with an empty modifier and uppercase fallback label; no String.to_atom/1.
- [Phase 144-03]: The v1.31 design-system freeze is source-first: style.ex and style_contract_test.exs govern the catalog.
- [Phase 144-03]: Phase 144 documents the local .tl-* and --tl-* system without Tailwind, build tooling, light/system theme support, external dependencies, or a public component API.
- [Phase 144-04]: POLISH-AUDIT and POLISH-DS are closed by Phase 144 verification while preserving the original roadmap-owner assignments.
- [Phase 150]: README/GitHub is the deciding surface for brand readiness; use `logo-primary-light.svg` on light documentation/repo surfaces and keep `logo-primary.svg` for dark/high-signal surfaces.
- [Phase 151]: Targeted revisions selected; alternate logo concepts, public rollout, and runtime UI changes remain out of scope.
- [Phase 152]: Brandbook-facing artifacts should present current brand truth; process history belongs in `.planning/`.
- [Phase 153]: Verification closeout UI remains static brandbook evidence only; no runtime UI, registry, component library, build pipeline, or committed raster export batch.
- [v1.34]: Helper-first dynamic localhost ports are canonical for local demo DX; Traefik is deferred and `.dev` hostnames are rejected for HTTP local demos.
- [v1.34]: Normal `bin/demo-up` refresh skips image rebuilds when the project image exists; `--build` is explicit for Dockerfile/dependency/base-image changes, and `--fresh` remains the volume-reset path.
- [v1.34]: Demo Dockerfile uses Docker/BuildKit's bundled frontend and installs `ca-certificates`; the base image is overridable via `THREADLINE_DEMO_BASE_IMAGE`.
- [v1.35]: Rollout to product surfaces (logo.ex, example-app favicon, README header) is an optional final phase (163), decided at that checkpoint with the winner in hand.
- [v1.35]: Seed drift is free exploration — round 1 may use OFL-safe typefaces and palette shifts; tokens/product UI change only if the winner demands it.
- [v1.35]: Hard logo constraints — no background chips on marks, logotype optically close to the mark, no subtitle in the primary lockup (separate `-subtitle` variant), user always picks the winner (never auto-selected).
- [v1.35]: All logo SVGs are pure paths (fontkit glyph-outline pipeline); zero `<text>` elements anywhere in candidates or final assets.
- [Phase 160]: Overlay baseline alignment via zero half-leading: line-height = (ascent-descent)*scale so live-text and SVG baselines coincide at ascent*scale
- [Phase 160]: Phase scripts reuse existing installs via module.createRequire anchored at the owning dir (fontkit via NODE_PATH, Playwright via e2e dir)
- [Phase 159]: 159-02: GitHub SVG sandbox verified empirically (default-src 'none'; style-src 'unsafe-inline'; sandbox) — pure-path SVGs are the only portable wordmark form; inline-CSS adaptive SVGs (Zig pattern) viable
- [Phase 159]: 159-02: Six technique names locked as Phase 161 motif vocabulary; gradient-dependence and gimmick-dependence (moz://a) named as paired antipatterns
- [Phase 159-03]: Motif distinctness defined at the (technique, letterform hook) pair level — 8 candidates need 8 distinct pairs; no technique repeats within a lane
- [163-01]: User opted IN at the rollout checkpoint ("Roll out now"); C13 shipped to logo.ex, example-app admin favicon, and the README header — style.ex untouched (freeze exception covers logo.ex only)
- [163-01]: logo.ex wordmark renders as pure brandbook paths; one non-rendering display=none `<text>` compat node preserves the in-flight nav-overhaul lane's header test contract until that lane lands (brand assets themselves stay zero-`<text>`)
- [Phase 159-03]: GAP-09/UP-08 raster export descoped to SOCIAL-PNG-01 (future); trademark descoped to human review; all other audit items routed to LOGO-*/TOUR-*/BOOK-* requirements
- [Phase 161]: 161-01: strategy matrix doubles Stroke continuation + Continuous-line mark (different hooks); all six BRIEF techniques used across 3/3/1/1 lanes
- [Phase 161]: 161-01: candidate ink uses currentColor with at most one flat accent (#4781E6 blue / #D9A03F gold); monos generated by color substitution only
- [Phase 161]: 161-01: BRIEF double-l-verticals hook mapped to the adjacent d/l ascender pair (no literal ll in Threadline)
- [Phase ?]: 162-01: Stitch arc stays #4781E6 on dark and light; #4F8CFF remains UI accent; #4781E6 recorded as additive stitch-blue raw token in plan 02
- [Phase ?]: 162-01: favicon uses Ink #0F1728 default strokes with internal prefers-color-scheme dark flip to Fog #D7DEEA (standalone equivalent of C13 currentColor design)
- [Phase ?]: 162-01: tagline outlined at 0.24em (240-unit) tracking, justified to wordmark ink edges; examples pruned to readme-header + docs-page
- [Phase ?]: 162-02: Brand book clear space = half cap height for lockups, quarter-size for mark/favicon; minimums 120px lockups / 180px subtitle / 16px mark+favicon (wordmark legibility governs)
- [Phase ?]: 162-02: Stitch Blue #4781E6 added additively to tokens (raw stitch-blue + semantic logo-arc, both lanes); #4F8CFF stays the interface accent; operator-surface values untouched
- [Phase ?]: 162-02: Misuse specimens live only as inline SVG in index.html; index.html inlines all 8 assets via shared pure-path defs; zero network under file://
- [Phase ?]: 162-03 pressure-test rerun
- [Phase 164]: Brand imagery specimens: pure-path linework with HTML labels over the SVG; Thread Blue carries the followable line, Signal Cyan the change ticks, Stitch Blue stays exclusive to the mark's arc

### Blockers

- None.

## Session Continuity

- **Milestone closeout (2026-05-29):** v1.29 archived; tag `v1.29`; REQUIREMENTS.md removed for fresh next milestone.
- **130.1-02 (2026-05-29):** 130-VALIDATION superseded footnote; Nyquist waivers for 128/129; 130.1-VERIFICATION passed; `mix ci.all` green (744+61 tests).
- **Last Action**: Phase 166 planning artifacts created — CONTEXT, UI-SPEC, RESEARCH, PATTERNS, VALIDATION, and 166-01-PLAN are ready (2026-06-12 local / 2026-06-13 UTC)
- **Next Step**: Execute Phase 166 with `/gsd-execute-phase 166` (atomic opening wave: unfreeze + token lane + mechanism + same-wave contract amendment)
- **Resume file**: None

## Operator Next Steps

- Execute Phase 166 with `/gsd-execute-phase 166`
- Human gate after Phase 166: light-lane design review before Phase 167 retune effort
