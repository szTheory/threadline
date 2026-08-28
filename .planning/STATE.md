---
gsd_state_version: 1.0
milestone: v1.41
milestone_name: Green, Clean, and Honest
status: executing
stopped_at: Phase 198 executing (7 plans, 5 waves)
last_updated: "2026-08-27T21:44:26.664Z"
last_activity: 2026-08-27
last_activity_desc: Phase 198 execution resumed (wave continue)
state_head: 3071d1bc103abd20bb10b721a115f2bddafe92c8
progress:
  total_phases: 7
  completed_phases: 0
  total_plans: 7
  completed_plans: 5
  percent: 0
---

# Project State: Threadline

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-08-27 after opening v1.41)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current focus:** Phase 198

## Current Position

Phase: 198 — Green Bringup — EXECUTING
Plan: 6 of 7
Status: Executing Phase 198
Last activity: 2026-08-27 — Phase 198 execution resumed (wave continue)

## PROOF-01 outcome (2026-08-26, maintainer-ratified in-session)

- **REJECT (evidence + density)**: three edit variants never beat the noise floor (Δ −1/−2; v3 targeted verdict unstable = VOID per [196-D1]). Edits kept as ordinary unratified UI cleanup (2eca4208) — no signoff claim.
- **ACCEPT (retention + density, pivot)**: duplicated status banner + destructive self-label removed (c6f9355e) → Δ +7 > noise 4.5, no blocking regression, page.retention.happy floor green, oracle stable. First `ratchet.signoffs` forward_only_accept entry + append-only pin (f1610d87).
- Loop hardening: ROUTE_PAGE_TWIN all five routes, dark route-lane maskColor (83db3918).
- Deferred to 197 debt register: verdict cache not screenshot-keyed; score-after-edit overwrites the before pole; Tier-A recapture drift (36k-px fullPage shots vs clipped refute poles); evidence structural density (IA pass).
        Final trust panel (`design-system-ledger.json → critic_trust`): brand_fidelity ρ0.93, density
        ρ0.84, typography ρ0.77, rhythm ρ0.76 = 4 VALIDATED (the blocking panel); color_contrast ρ0.698

        + hierarchy ρ0.42 = advisory (never block; verify vs ground truth — they hallucinate specifics).
        Phase 196 = forward-only net-positive gate, ratified as: GATE-01 RELATIVE/ranking gate on the
        4-lens panel; MechanicalChecker (`verify.mechanical`) = deterministic hard floor, gates on the
        `page.*` Tier-A twin (route.* excluded, mechanical_checker.ex:155); synthetic oracle = held-out
        true-north (GATE-03 divergence halt); GATE-04 guard-the-guards in critic_trust_test.exs
        (`ratchet.signoffs` append-only); GATE-02 mechanical fixes = surface-a-diff this phase (true
        auto-write → 197); PROOF-01 = wire loop + CONTRIBUTING.md runbook + ONE real human-ratified
        improvement on the weakest /audit page (mid-phase checkpoint:decision). Deferred to 197:
        PROOF-02 (2-3 pages), PROOF-03 (adversarial closeout), PROOF-04 (debt register). Locked
        decisions in `196-CONTEXT.md` [196-D1..D9]. ~85% of the phase is WIRING existing machinery.
Last activity: 2026-08-27

Progress: [░░░░░░░░░░] 0% (v1.41 — 0/7 phases complete)

## Performance Metrics

- **Active Milestone**: v1.41 — Green, Clean, and Honest (opened 2026-08-27; roadmap complete — Phases 198-204, coarse granularity, 53/53 requirements mapped, est. 26-33 plans)
- **Last Milestone Shipped**: v1.40 — Automated Operator-UI Critique & Forward-Only Iteration Harness (2026-08-27, Phases 194-197, 28/29 requirements; PROOF-02 ratified shortfall)
- **Prior Milestone Shipped**: v1.39 — Quality Baseline, Schema Confidence, and CI Efficiency (2026-07-03, Phases 189-193, 15/15 requirements)
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
| Phase 166 P01 | 65min | 5 tasks | 17 files |
| Phase 168 P01 | 25min | 3 tasks | 1 files |
| Phase 170 P01 | 18m | 3 tasks | 5 files |
| Phase 170 P02 | ~9m | 2 tasks | 2 files |
| uat_gap (v1.36 close 2026-06-14) | 169-HUMAN-UAT.md — 1 pending scenario | partial — acknowledged & deferred |
| uat_gap (v1.36 close 2026-06-14) | 170-HUMAN-UAT.md — 1 pending scenario | partial — acknowledged & deferred |
| verification_gap (v1.36 close 2026-06-14) | 170-VERIFICATION.md | human_needed — acknowledged & deferred |
| todo (v1.36 close 2026-06-14) | transaction-page-left-push-desktop (operator-surface layout bug) | resolved by Phase 178 |
| todo (v1.36 close 2026-06-14; reframed 2026-06-20) | coverage-schema-card-declutter (operator-surface Coverage IA/schema workflow) | completed as standalone todo; broader Coverage audit-readiness polish now scoped to v1.38 Phase 185 |
| todo (v1.36 close 2026-06-14) | theme-picker-idiomatic-ui (THEME-TOGGLE-01, out of v1 scope per [165-01]) | completed in v1.37 runtime theme picker work |
| deferred [176-05] | T3 redact destructive flow — no runtime redaction backend (codegen-time only); building one would touch the capture layer (v1.37 invariant). Revisit only if a runtime "redact a stored value" op is explicitly scoped without editing capture. | deferred per Task-1 checkpoint (option 1) |
| Phase 174 P06 | 6min | 2 tasks | 2 files |
| Phase 175 P01 | 14min | 2 tasks | 5 files |
| Phase 175 P02 | ~15min | 2 tasks | 4 files |
| Phase 175 P03 | ~30min | 2 tasks | 11 files |
| Phase 175 P04 | ~12min | 2 tasks | 7 files |
| Phase 176 P01 | ~30min | 3 tasks | 9 files |
| Phase 176 P02 | ~40min | 3 tasks | 7 files |
| Phase 176 P03 | ~75min | 3 tasks | 12 files |
| Phase 176 P04 | ~25min | 2 tasks | 5 files |
| Phase 177 P03 | ~5min | 3 tasks | 2 files |
| Phase 177 P04 | ~12min | 2 tasks | 2 files |
| Phase 177 P05 | ~17min | 3 tasks | 7 files |
| Phase 178 P06 | 10m 23s | 3 tasks | 7 files |
| Phase 178 P07 | 8 min | 2 tasks | 1 files |
| Phase 179 P01 | 11m 53s | 3 tasks | 8 files |
| Phase 179 P02 | 8m 9s | 1 tasks | 12 files |
| Phase 179 P03 | 13m 39s | 1 tasks | 12 files |
| Phase 179 P04 | 25min | 1 tasks | 4 files |
| Phase 179 P05 | 28min | 1 tasks | 17 files |
| Phase 179 P06 | 8m | 1 tasks | 5 files |
| Phase 180 P01 | 178m | 2 tasks | 6 files |
| Phase 180 P02 | 10m 27s | 2 tasks | 6 files |
| Phase 180 P03 | 21m 49s | 2 tasks | 5 files |
| Phase 180 P04 | closeout | 3 tasks | guardrail tests + closeout artifacts |
| todo (v1.37 close 2026-06-20) | coverage-schema-card-declutter (functional outcome resolved by Phase 176 and regression-guarded by Phase 180; todo artifact cleanup remains) | completed as todo artifact cleanup; broader Coverage flow polish now scoped to v1.38 Phase 185 |
| todo (v1.37 close 2026-06-20) | operator-shell-nav-ia-and-visibility | completed as post-close todo; broader shell/home polish now scoped to v1.38 Phase 183 |
| todo (v1.37 close 2026-06-20) | demo-login-copy-credentials | completed as post-close demo-login polish |
| Phase 181 P01 | 32 min | 2 tasks | 12 files |
| Phase 181 P02 | 4 min | 1 tasks | 1 files |
| Phase 181-baseline-audit-and-guard-repair P03 | 1028 | 1 tasks | 3 files |
| Phase 181-baseline-audit-and-guard-repair P04 | 7 min | 1 tasks | 8 files |
| Phase 181-baseline-audit-and-guard-repair P05 | 8 min | 1 tasks | 5 files |
| Phase 181-baseline-audit-and-guard-repair P06 | 1h 1m | 1 tasks | 1 files |
| Phase 181-baseline-audit-and-guard-repair P07 | 6 min | 1 tasks | 7 files |
| Phase 181-baseline-audit-and-guard-repair P08 | 4 min | 1 tasks | 2 files |
| Phase 181-baseline-audit-and-guard-repair P09 | 3 min | 1 tasks | 2 files |
| Phase 181-baseline-audit-and-guard-repair P10 | 3 min | 1 tasks | 2 files |
| Phase 181-baseline-audit-and-guard-repair P11 | 29m24s | 2 tasks | 37 files |
| Phase 182 P01 | 7 min | 3 tasks | 6 files |
| Phase 182-phoenixstorybook-example-dev-lane P02 | 7 min | 2 tasks | 5 files |
| Phase 182 P03 | 9 min | 2 tasks | 15 files |
| Phase 182 P04 | 18 min | 3 tasks | 9 files |
| Phase 182 P05 | 7 min | 2 tasks | 4 files |
| Phase 183 P01 | 15 min | 2 tasks | 2 files |
| Phase 183 P02 | 68m | 2 tasks | 9 files |
| Phase 183 P03 | 36m | 1 tasks | 3 files |
| Phase 184 P01 | 10 min | 2 tasks | 6 files |
| Phase 184 P02 | 9 min | 2 tasks | 5 files |
| Phase 184 P03 | 49 min | 2 tasks | 5 files |
| Phase 185 P01 | 19m | 3 tasks | 13 files |
| Phase 187 P01 | 5 min | 2 tasks | 3 files |
| Phase 187 P02 | 35min | 2 tasks | 2 files |
| Phase 187 P03 | 28 min | 2 tasks | 3 files |
| Phase 188 P01 | 5min | 2 tasks | 3 files |
| Phase 188 P02 | 3min | 2 tasks | 2 files |
| Phase 188 P03 | 8 min | 2 tasks | 6 files |
| Phase 189 P01 | 6 min | 3 tasks | 2 files |
| Phase 190 P01 | 8m31s | 3 tasks | 9 files |
| Phase 190 P02 | 8min | 2 tasks | 11 files |
| Phase 190 P03 | 7m17s | 2 tasks | 8 files |
| Phase 190 P04 | 15 min | 2 tasks | 6 files |
| Phase 190 P05 | 9 min | 2 tasks | 5 files |
| Phase 190 P07 | 8 min | 2 tasks | 6 files |
| Phase 190 P08 | 9 min | 2 tasks | 8 files |
| Phase 190 P09 | 9m17s | 2 tasks | 6 files |
| Phase 190 P10 | 7m23s | 3 tasks | 3 files |
| Phase 191 P01 | 12min | 3 tasks | 3 files |
| Phase 191 P02 | ~14min | 3 tasks | 4 files |
| Phase 191 P03 | 22min | 3 tasks | 15 files |
| Phase 192 P02 | 15m | 2 tasks | 2 files |
| Phase 192 P03 | 8min | 3 tasks | 4 files |
| Phase 195 P01 | 4m | 3 tasks | 11 files |
| Phase 195 P02 | 4m | 2 tasks | 6 files |
| Phase 195 P3 | multi-session | 2 tasks | 205 files |
| Phase 195 P04 | 11m | 2 tasks | 7 files |
| Phase 195 P06 | 13m | 2 tasks | 2 files |
| Phase 197 P05 | ~50min | 3 tasks | 4 files |
| uat_gap (v1.40 close 2026-08-27) | 169-HUMAN-UAT.md — 1 pending scenario (archived v1.36) | partial — acknowledged & deferred |
| uat_gap (v1.40 close 2026-08-27) | 170-HUMAN-UAT.md — 1 pending scenario (archived v1.36) | partial — acknowledged & deferred |
| uat_gap (v1.40 close 2026-08-27) | 30-HUMAN-UAT.md — 0 pending scenarios (archived v1.9) | partial — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 197-VERIFICATION.md — PROOF-02 shortfall ratified at phase seal (achieved-with-ratified-gap) | gaps_found — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 170-VERIFICATION.md (archived v1.36) | human_needed — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 109-VERIFICATION.md (archived v1.23) | gaps_found — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 30-VERIFICATION.md (archived v1.9) | human_needed — acknowledged & deferred |
| deferred_items (v1.40 close 2026-08-27) | Phase 196 deferred-items.md — 1 entry (pre-existing full-suite failures: StressLedgerTest fixture-registry gap, LedgerSplice, FormlessPages, Phase06Nyquist, V123Charter) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 197 deferred-items.md — 1 entry (copy_contract eyebrow red from 197-02 = debt rank 2; 3-module doc-contract baseline = debt rank 8; search_path fix confirmed) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 191 deferred-items.md (archived v1.39) — 3 entries (v1_23_charter_doc_contract_test milestone-literal drift) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 181 deferred-items.md (archived v1.38) — 1 entry (root CI residuals: formless coverage, charter drift, example demo-seed) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 182 deferred-items.md (archived v1.38) — 1 entry (example precommit demo-seed/walkthrough failures) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 176 deferred-items.md (archived v1.37) — 3 entries (format-clean drift ×2, card-nesting coverage RED; table converted to heading entries to carry status) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 177 deferred-items.md (archived v1.37) — 1 entry (example demo-seed 60s setup timeout) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 179 deferred-items.md (archived v1.37) — 5 entries (charter doc-contract + example demo-seed/walkthrough residuals per plan 01/03/04/05/06) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 180 deferred-items.md (archived v1.37) — 1 entry (mix precommit demo-seed failures; Status field repurposed, scope note kept) | acknowledged in-file (status: acknowledged) |

## Accumulated Context

### Pending Todos

- No pending todo artifacts remain. The former Coverage, shell/nav, and demo-login todo items were completed or absorbed into the archived v1.38 requirements.
- The next milestone should preserve the standing no-regression rule for operator routes, data-testids, feature gates, capture/query/auth semantics, optional Phoenix dependencies, and host-app-friendly theming unless fresh requirements explicitly change it.

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
- **Milestone v1.37 roadmap created (2026-06-14):** Operator Surface Design-System Stress Test & Component System — phases 171-180 per the approved plan `~/.claude/plans/design-system-stress-test-fancy-gizmo.md`, continued numbering. Largely linear fractal sequence: 171 (harness: `/audit/__stress` + DESIGN-SYSTEM.md v2 + scored ratchet ledger + ugly-data fixtures) → 172 (foundations/tokens, parity-gated) → 173 (primitive + overlay/disclosure components) → 174 (form components + page adoption + contract tests) → 175 (shell/nav + runtime theme picker, THEME-TOGGLE-01) → 176 (data display, flatten card-in-card) → 177 (component groups) → 178 (per-page stress, all 11 pages, kill footguns) → 179 (microcopy + IA sweep) → 180 (WCAG 2.2 AA + guardrails + adversarial closeout). 33/33 requirements mapped. Carried-todo phase tags: `theme-picker-idiomatic-ui`→175, `coverage-schema-card-declutter`→176, `transaction-page-left-push-desktop`→178. Invariants held: no public component API, zero new runtime deps, inline assets, brand-token parity green, capture/semantics untouched, fail-closed auth.
- **Milestone v1.36 roadmap created (2026-06-12):** Operator Surface Light Mode — phases 166–170 per the approved 165 recommendation's pre-decided breakdown: 166 (unfreeze + 45-token light lane + `data-tl-theme` mechanism, contract amended same-wave) → 167 (component retune, largest) → 168 (accessibility AA mirror) ∥ 169 (`__light__` screenshots + example + docs) → 170 (brand alignment + closeout). 15/15 requirements mapped. Human gates: light-lane design review after 166; end-of-milestone UAT after 170.
- **Milestone v1.38 roadmap created (2026-06-26):** Operator UI Page-by-Page IA & Design-System Polish — phases 181-187. Order is baseline guard repair → PhoenixStorybook example/dev lane → shell/home → Timeline → Coverage → detail/governance/export → accessibility/motion/docs/adversarial closeout. 24/24 requirements mapped, with former post-close todo pressure absorbed into phases 183, 185, and prior demo-login polish.
- **Milestone v1.38 archived (2026-06-30):** Operator UI Page-by-Page IA & Design-System Polish shipped with phases 181-188 complete, 24/24 requirements satisfied, and residual CI/screenshot/environment/Nyquist items explicitly classified in the archive audit.
- **Milestone v1.39 roadmap created (2026-07-01):** Quality Baseline, Schema Confidence, and CI Efficiency — phases 189-193. Order is quality audit → storage-schema proof/fixes → release/version docs trust → CI/CD measurement and efficiency → closeout/next-step decision. 15/15 requirements mapped. Invariants held: no new operator product scope, no public component API, no compliance expansion, no synthetic external pilot, no runtime destructive redaction, no WAL/CDC backend, and no broad CI cleverness before measurement.
- **Milestone v1.41 roadmap created (2026-08-27):** Green, Clean, and Honest — phases 198-204 per the approved plan `~/.claude/plans/so-i-don-t-really-have-quirky-wilkinson.md`, continued numbering. Order is green bringup → decouple (dialyxir lands here) → public surface → rendered output → **release 0.10.0 (deliberately mid-milestone: hex.pm has no undo, so publish once the permanent and rendered surfaces are clean, before the invisible internal work)** → real gates → structure. 53/53 requirements mapped, coarse granularity, est. 26-33 plans. Two workloads are deliberately unmeasured at roadmap time — the full-default Credo backlog (measured in 198 Plan 01) and the dialyzer finding count (measured in 199) — with a pre-committed sizing rule for Phase 203 (<150 → one phase; 150-600 → split mechanical from judgment; >600 or one dominating check → adopt defaults with that check as a counted register row plus a named successor milestone). Phase 201's cost depends on 198 Plan 01's mechanical-sensitivity probe. Highest-variance risk: the `min` CI lane (Elixir 1.15 / OTP 26 / pg14 / ubuntu-22.04) has never executed on origin. Invariants: no operator-UI design/IA/visual change, no Tier-A scorecard regeneration, paid critic scoring stays structurally untriggerable, `.planning/` stays tracked, no git history rewrite, no capture/query/auth semantic change, no version-floor bump; `git mv`/`git rm` for every move/removal, one file per commit where contract tests are involved.

### Decisions

- [197-05]: Debt seed #9 re-measured fresh (2026-08-27 full mix test): (undefined_table) count = 0 — the ALTER DATABASE search_path fix is in effect; register row closed-in-environment with a CI reopen-trigger, not an open ~81-failure row.
- [197-05]: copy_contract_test.exs:249 red (stale "Selected schema readiness" pin vs landed 842bd737) discovered and registered rank 2, not auto-fixed (caused by 197-02, out of 197-05 scope); Phase-185 coverage doc-contract copy lock registered rank 5 with owner + concrete trigger.
- [197-05]: GATE-02 true auto-write stays register-as-debt per OQ-1 with trigger N=3 consecutive accepted iterations where the surfaced mechanical diff was applied verbatim with zero human modification.
- [195-02]: Rubric Anchors pole cell-ids use page-level Tier-A scorecard cells (`page.*__theme-breakpoint` format); `footgun.*` and `primitive.*` are conceptual quality labels in the ledger only, not committed scorecard files. All 11 pole cell-ids (pass + fail across 6 lenses) verified against `.planning/scorecards/`. sha8 placeholder `00000000` is intentional — Plan-04 rubric-hash guard recomputes from disk.
- [193-02]: CLOSE-01 clauses 3 & 4 delivered as `193-RISK-REGISTER.md` + `193-NEXT-STEP.md`. Register is a verify-and-refresh of the 189 ledger (rows 1-3 CLOSED by 190/191/192, rows 6-12 preserved) ranked on the adoption/ops/maintainer lens (D-10/D-12); four post-189 residuals folded in with Owner + reopen-trigger — R-A ship-gated D-17/D-19 (rank 1, ops), R-B/WR-01 alt-schema FK-fixture gap (rank 2), R-C charter-test drift (rank 3), R-D ~81 local failures framed as maintainer-friction NOT a regression (rank 4, below R-A/R-B). Next-step is a single HOLD/thin-polish recommendation backed by three converging gates + config policy (`no_auto_new_milestone` → recommends, does not open v1.40) with five armed flip-triggers (EXT-PILOT-01, OBS-01, UI-REG-01, RECONNECT-01 + CI-depth track). No `/gsd-audit-milestone` run, no `v1.39-MILESTONE-AUDIT.md`, no version/tag change (D-01/D-02/D-03). Commits `92fcb932`, `04dd00e8`.
- [192-03]: Release publish-race serialization scoped to the `publish-hex` job (`group: release-publish-${{ github.ref }}`, `cancel-in-progress: false`); the workflow-level `run_id`-embedding no-op group was removed so release-please bookkeeping stays independent of long publishes (D-24). `gate-ci-green` + the idempotency skip remain the real race guards; no `run_id` in the publish group; no `:latest`.
- [192-03]: CONTRIBUTING two lists reconciled without conflating them — List 1 "Stable job keys" table 8→10 (adds `verify-hex-evaluator`, `verify-example-browser`) mirroring the ci.yml header contract (D-25); List 2 branch-protection required checks renamed `Run test suite (verify-test)` → `Run test suite (min)` / `Run test suite (current)` (D-19) while staying a deliberate subset. The GitHub branch-protection reconfig itself is the human step in Plan 04.
- [192-03]: Version support contract made explicit (Elixir 1.15 floor / 1.17.3 current, OTP 26 min / 27 current, PostgreSQL 14 min / 16 current) in README "Supported versions" + a `mix.exs` comment; `elixir: "~> 1.15"` string unchanged — the floor is honored by the CI min lane, never by raising the requirement (D-13/D-14).
- [192-02]: Cache `deps/` (source only) never `_build`; caches change speed only so `mix ci.all` still reproduces CI byte-identically and every gate keeps its teeth (D-06/D-10/D-12). Playwright/npm caches keyed to the e2e subtree lockfile, never folded into the root `mix.lock` key (D-09).
- [192-02]: `verify-test` gains a base-axis `lane: [min, current]` matrix + `include` (elixir/otp/pg/runner), so GitHub posts exactly `Run test suite (min)`/`(current)` (RESEARCH M1 construction A); min lane = 1.15/otp26/pg14/ubuntu-22.04 runs compile-strict + `mix test` only, heavier steps gated `if: matrix.lane == 'current'` (D-15/D-18/D-19). Branch-protection rename is a human-gated step in Plan 04.
- [192-02]: Pinned `edoburu/pgbouncer:v1.25.2-p0` (no `:latest` in ci.yml) + PR-scoped `concurrency` cancelling only superseded pull_request runs (push-to-main and release-PR dispatch land in distinct groups) (D-22/D-23).
- [191-02]: ADOPT-03 routing uses intent VERBS (Evaluate/Adopt/Operate/Contribute), split by medium (Option C): README `## Start here` owns the routing prose (a three-column "I want to... / Start here / Then read" intent table), ExDoc `groups_for_extras` owns the sidebar structure (four matching verb lanes, explicit per-file regexes, all 20 extras in exactly one lane). The flat `## Documentation` dump is replaced (not deleted) by a collapsed `<details>` all-guides index grouped by the four verbs — no new guide (ADOPT-03/D-191-17 refute holds). New `persona_routing_doc_contract_test` asserts the subset (four keys + each README landing) + refutes start-here/where-to-go-next; `release_artifact_contract_test` owns the exact groups-key equality, updated in lockstep so `verify.release` stays green. P1–P5 operator-UI personas + ia_lock untouched.
- [191-01]: The 0.6.x->0.9.x era was surface/DX/proof-lane only (zero host-DB migrations), so the upgrade guide's affirmative "nothing required" is the factually-correct default per bump. The one migration-shaped expectation is storage-schema freeze-at-generation (Phase 190 D-190-14), kept distinct from host `table_schema`. Backport policy (patch on current minor; minor-crossing is deliberate) now stated in both `guides/upgrade-path.md` and `CONTRIBUTING.md`. Structural doc-contract test owns the theme/per-minor axis; version_truth (plan 03) owns the derived current-minor check.
- [v1.39-01]: v1.39 is a consolidation milestone. Recent work already built the demo, brand, light/system theme, design system, and page-by-page UI polish; the next trust risk is quality evidence, schema confidence, docs/version drift, and CI efficiency.
- [v1.39-02]: `storage_schema: "threadline"` remains the respectful default, with `public` requiring explicit opt-in. v1.39 must prove or fix custom-schema behavior before leaning on that posture publicly.
- [v1.39-03]: CI/CD changes must be measured, boring, and reversible. Baseline first; then fix cache/setup/service/release/version-policy gaps without hiding risk.
- [v1.38-01]: PhoenixStorybook is scoped to `examples/threadline_phoenix` for development/design review only. Root `threadline` keeps optional Phoenix/LiveView dependencies, no public component API, and `/audit/__stress` remains the canonical flow stress harness.
- [v1.38-02]: Page cleanup order starts shell/home/timeline, then Coverage, then detail/governance/export, then closeout. This fixes orientation and task flow first and reuses patterns on lower-traffic pages.
- [176-05] (checkpoint, human-approved option 1): T3 destructive pattern ships via "prune now" ONLY this phase; the redact destructive flow is DEFERRED. Redact has no runtime backend (codegen-time only); building one would touch the capture layer (v1.37 invariant violation). Prune is enforced server-side: secure_compare(typed, server-canonical policy name) + authz re-check + scope fail-closed + audit-the-action; client-only `data-confirm` deleted.
- [Phase 174-02]: Extended `<.field>` properties with global attribute pass-through (e.g. `list`, `maxlength`) rather than rigid structs, accommodating existing advanced filter functionality natively.
- [Phase 174-01]: Form components use explicit `name`, `value`, and `errors` rather than requiring `Phoenix.HTML.Form` structs to maintain isolation and independence from Ecto.
- [Phase 174-01]: Form primitives rely entirely on native HTML5 controls rather than custom JS elements for maximum browser compatibility and accessibility.
- [136-01]: Dark-only remains intentional; no `prefers-color-scheme`, no light mode, no theme toggle. *(Superseded by [165-01] in Phase 166 per THEME-04.)*
- [165-01] supersedes [136-01]: dark remains default and brand-primary; light/system are supported via host `theme:` config; no runtime theme toggle in v1; the `theme-toggle` ban remains.
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
- [Phase ?]: [170-01]: full token parity = curated-subset parity (name + value equal in dark + light); brandbook corrected to style.ex, never the reverse
- [Phase ?]: [170-01]: brandbook<->style.ex drift now caught by brandbook_token_parity_test in both directions; pressure-test dim #11 bumped 8->9 (total 128->129)
- [Phase ?]: [170-02]: v1.36 audit doc authored; COMP-01/02 built+verified-live source-uncommitted; closeout pending-uat
- [Phase ?]: [170-02]: REQUIREMENTS COMP-01/02 token 'Verified (source pending)' (table + checkboxes); BRAND-01/02 Complete; archival+version bump -> /gsd-complete-milestone post-UAT
- [Phase 174-05]: search/date/number need no dedicated input clause — the generic input(assigns) default already emits type={@type} + tl-control; documented as passthrough and proven by contract tests.
- [Phase 174-05]: New form components compose existing classes/BEM modifiers (tl-error-summary__*, tl-radio__*, tl-switch, tl-combobox__*) rather than add any new --tl-* token, keeping style.ex untouched and brand-parity green.
- [Phase 174-05]: combobox confines JS to ARIA state via Phoenix.LiveView.JS (popover/dropdown precedent) — CSP-safe, degrades to free-text input, no Alpine, no new runtime deps.
- [Phase 174]: [Phase 174-06]: field_group renders the base tl-filter-group class + legend; timeline call sites pass only the --primary/--advanced modifier and drop the duplicated raw legend.
- [Phase 174]: [Phase 174-06]: formless guard scans each page's own source (not surface_header), excluding the legitimate hidden _csrf_token and theme-picker form without an explicit allowlist.
- [Phase ?]: [175-01]: CSP guard combines specific onclick/onchange refutes + explicit handler list + broad on*= regex (mitigates T-175-01); breadcrumb_test drives the live actor drill-down with a legacy-landmark fallback; skip_link_test follows the Timeline mount live_redirect.
- [175-03]: One internal `UI.page_header/1` (single `<h1>`, `:heading`/`:lede`/`:actions`/`:inner_block` slots, ordered `breadcrumbs`) adopted across the operator pages; reuses existing CSS only (no style.ex change, no new `--tl-*` token, no public API). Drill-down pages (Transaction/Actor/standalone Row history) carry location-based breadcrumbs under `<nav aria-label="Breadcrumb">` rooted at "Timeline" and pass `current={nil}` so the single `aria-current="page"` lives only on a shell nav link (the inlined CSS `[aria-current="page"]` selector pinned by style_contract counts page-wide, so nav must mark nothing current on drill-downs). Timeline command toolbar + Coverage command-center state kept bespoke single-`<h1>` (specialized command structures pinned by timeline_live_test / aria-labelledby). D-02 doc-contract back-link assertions re-pointed to the D-13 breadcrumb root (Rule 3). Both NAV-01 Wave-0 RED targets GREEN; transaction_live/skip_link/CSP locks + brand-token parity green. Commits `025e9d3`, `3e4b1c7`.
- [175-04]: One internal `UI.pager/1` (de-emphasized Older/Newer time-axis controls + a `role="status" aria-live="polite"` range caption) over the EXISTING keyset engine — hide-at-zero (D-16), disable-not-hide on boundaries (D-18), capped "10,000+" deep total (D-17); controls emit the host page's existing next-page/prev-page events (no engine change). Adopted next-only on Timeline (cursor stays in socket assign, D-19) and bidirectionally on Actor; Exports/Retention get honest "Showing latest N" cap captions (D-20), Coverage/Redaction none. `pager_test.exs` (the binding RED target) drove the signature (`shown`/`match_count`/`has_older`/`has_newer`), with optional `older_event`/`newer_event` phx-click attrs for adoption (`newer_event` is `:any` so Timeline passes nil). query.ex documents the `(captured_at, id)` keyset tiebreaker as DEFERRED capture-layer perf debt (D-15/Q1, T-175-10 accepted) — doc note only, no migration, capture layer byte-for-byte untouched. Zero new `--tl-*` token (brand-parity green). All 4 NAV-02 Wave-0 RED targets GREEN; verify.test 1008/0; credo clean. Commits `1a230bd`, `ac6f762`.
- [175-02]: Shell is CSP-proof — all three inline handlers removed (theme onchange, nav onclick, skip-link onclick); theme picker rebuilt as visible native radios + explicit "Apply theme" button + pure-CSS `.tl-theme-picker__option:has(:checked)` non-color cue (zero new tokens); mobile nav is native `<details>` keyed on `[open]`; scroll-padding-top reconciled to the per-row scroll-margin-top token + overscroll-behavior:contain + 100svh; router macro doc corrected; theme-toggle ban lifted in style_contract_test for a positive CSP guard; backend untouched (D-09).
- [176-02]: Built the internal `OperatorSurface.UI` data-display + data-state family: `ref/1` (binds `data-tl-copy={full}` on `<code>` + gated button, never `.title`/`.visible` D-02; zero-JS renders full D-06; `copy_label` required no-default D-07), `kv/1` (tl-kv `<dl>` + required `:item key` slot D-08), `data_table/1` (`:col label` feeds `<th>` + every `<td data-label>` from one source, rows|stream `phx-update=stream`, row_id, row_status `data-status` stripe, `:action` kebab, no ARIA table roles D-09), `loading_state/1` (role=status + aria-busy + spinner + text node D-13), `stale_banner/1` (role=status `tl-alert--warning` strip above data with `as_of` + Retry D-14), `empty_state` variants `no_data`/`permission`/`unavailable` + `role`/`icon`/`focus_heading` (D-15 focus rescue = generated heading id + `tabindex=-1` + `phx-mounted={JS.focus}`, CSP-clean), and `data_state/1` typed-reason dispatcher (distinct role+icon SHAPE+heading per reason; unavailable sub-cases state "not a permissions issue" D-16). `data_state/1` was a Rule-2 add — the Plan-01 `data_state_mapping` wave-0 test calls it; it is now GREEN. `copy_label` required-attr enforcement is a compile WARNING (Phoenix attr semantics), asserted via CaptureIO. 10 stress stories (ref/kv/data_table + 7 data-states) registered with matching `.planning/design-system-ledger.json` + `DESIGN-SYSTEM.md` rows (Rule-3 coupling — ledger test requires registry↔ledger↔projection parity). Zero new `--tl-*` token; brand-parity + style_contract green; no style.ex change. No page migrated (plans 03/04/05). 6 cross-plan Wave-0 scaffolds remain RED by design (1 card-nesting→03, 5 retention T3+ref-copy→05). Commits `d3273d3`, `617eb47`, `8c880a6`, `93a8027`, `9e17e86`. Capture/semantics untouched.
- [176-01]: `Presentation.ref/2` → `%{visible, title, full}` reuses `secondary_ref_value/1` for `full` (no value-extraction rebuild, D-01); `title == full`. `truncate_middle/3` gains additive `:tail_min` (≥N tail chars survive verbatim; no-`:tail_min` path byte-for-byte unchanged so `export_summary/1` is unaffected, D-03). `value_token/1` truncates at 56 keeping full in `:title`. Per-kind `truncate_for/2` (uuid/correlation/arn/actor/hash/path/email/url/timestamp; `:timestamp` never truncates). Source-down glyph is `:cloud_off` (not `:plug`); `archive` reused for pruned. The four MISSING Wave-0 tests use a self-contained tokenizer/regex (no Floki — not a project dep, v1.37 zero-new-dep invariant); `RefCopyContract` lives in `test/support` (only `test/support` is on the compile path). card-nesting regression treats the synthetic `tl-coverage-command` shell as a card-family surface so it is genuinely RED on coverage today (literal card>card alone would false-green). 9 new assertions RED (3 data-state + 1 card-nesting + 5 retention/ref-copy), all turning GREEN in Plans 02/03/05. Commits `989f03c`, `45a788d`, `a4a13fa`, `3503fdc`. Capture/semantics untouched. Pre-existing `ui_test.exs` format drift logged to deferred-items (out of scope).
- [176-04]: Flattened the coverage "schema" command shell — the DATA-05 / `coverage-schema-card-declutter` target. The success branch's hand-rolled `<section class="tl-coverage-command">…<h1 class="tl-page__title">` header is replaced with `UI.page_header` (title + `:lede` + `:actions` Refresh + a NEW optional `:meta` slot carrying `Presentation.checked_label`); all three branches now use page_header. The synthetic `tl-coverage-command` shell is demoted so trust-rail / `tl-summary-grid` metric tiles / remediation / table become direct page-stack `<section>` siblings (D-11 one card boundary per logical unit); `tl-card--metric` tiles kept, `__metrics` modifier dropped (bare `.tl-summary-grid` supplies the margin). Dead `tl-coverage-command__*` CSS deleted from style.ex (base + tablet) with the paired `refute String.contains?(src, "tl-coverage-command")` style_contract lock added in the SAME commit (T-176-08). **Rule-2:** added an optional `:meta` slot to `UI.page_header` (the plan's key_links require it but plan-175's component lacked it; defaults to `[]`, backward-compatible for every other call site). **Rule-3:** swapped the 3 style_contract assertions that pinned the deleted CSS for the refute lock. Task 2 (system-wide nesting sweep) needed NO source change beyond Task 1 — the card-nesting regression test (renders all 11 surfaces, refutes card-under-card) went GREEN the moment the shell flattened; coverage_live.ex was the only card-nester, so the plan stayed disjoint from plan 05 (retention/redaction untouched). Full operator_surface suite 545/5 — down from 6 RED (card-nesting now GREEN); the 5 remaining are the plan-05 retention T3 prune (4) + ref-copy (1) Wave-0 scaffolds. Zero new `--tl-*` token; brand-parity + style_contract green. Commit `157398d`. Capture/semantics untouched.
- [177-03]: Wave-3 meta-components + breadcrumb truncation. Shipped `@doc false` `UI.data_panel/1` (state-coordinating SHELL: a cond maps the generic state atom — ok|loading|empty|no_data|error|permission|unavailable — onto the EXISTING named state family; NO variant= switch, NO reinvented focus logic; `:permission`/`:unavailable`→`data_state(@reason)` collapses the body preserving the lock/cloud_off forensic distinction + delegating focus rescue D-06c; `stale_banner` rendered ABOVE the region as a cond-sibling, never replacing :ok data D-176-14; pager only when :ok), `UI.toolbar/1` (role=search + `aria-disabled` via `to_string/1` so it emits "true"/"false" + `is-disabled` affordance on `tl-cluster`; documents the page's HTML-`disabled`-on-controls enforcement contract, Pitfall 6), and `UI.detail_header/1` (`<h2>` not `<h1>` per D-175-03 + `justify=end` actions cluster + `kv` metadata from `<:metadata key=...>` slots). Reconciled breadcrumbs by KEEPING the `page_header` list attr (D-14, not a slot per D-04 literal) and truncating the current crumb via `.tl-transaction__breadcrumbs-current { max-width: clamp(12ch,50vw,40ch) }` so the header never horizontal-scrolls at 320px. Added `.tl-data-panel`/`__region`(opacity cross-fade on `--tl-motion-fast`, D-10.2)/`__pager` + `.tl-toolbar`/`.tl-detail-header` CSS (no new tokens). **Rule-1 (self-caught):** the first draft added a `@media (min-width:768px)` block + a "~1ms" CSS comment, reddening 4 phase-141/142 StyleContractTest source-governance assertions (exact min-width literal set; ungoverned `\d+ms`); replaced with `clamp()` (no new media literal) and rephrased the comment, returning the suite to the 2 RED-by-design Plan-04 scaffolds (verified identical to baseline `ac78693`). All 7 component RED scaffolds GREEN; ui_test+page_header 64/0; full suite 1071/2 (2 = Plan-04 overlay/offline, by design); warnings-as-errors + format + credo (2113 mods/funs) clean; brand parity 4/0. GROUP-01/GROUP-02 deliberately NOT marked complete (phase-spanning, complete at Plan 05). Zero new dep; no public API; capture/semantics untouched. Commits `1f4d6d7`, `2b082f8`, `19ef009`.
- [177-02]: Wave-2 layout primitives + semantic gap tokens. Added `--tl-gap-inline`/`--tl-gap-stack`/`--tl-gap-section` to all three sources (tokens.css/tokens.json/style.ex) in ONE task so brandbook_token_parity_test never drifted (8/16/32px → --tl-space-2/4/8). Shipped `@doc false` `UI.stack/1` (gap: stack|section|inline|tight, default stack; tight→--tl-space-1/4px) and `UI.cluster/1` (justify: start|between|end, default start) following the card/1 class-list idiom, with `.tl-stack`/`.tl-cluster` CSS owning inter-child spacing via flexbox `gap` over --tl-gap-* tokens (no raw child margins, GROUP-01/D-02). Turned the Plan-01 gap-parity + stack/cluster render RED scaffolds GREEN. data_panel/toolbar/detail_header scaffolds left RED by design (Plan 03 owns them per task scope + verification_note, despite some test-name tags reading "[RED — Plan 02]"). Zero new dep; no public API; capture/semantics untouched; format + credo clean. Commits `8d701e8`, `38005a3`.
- [177-01]: Wave-0 conflict resolution + RED test scaffolds (zero production code). **Conflict 1 (offline anchor):** confirmed by grep that all 11 audit LiveViews render `<div class="threadline-ui">` as their render root, so the offline-group CSS (Plan 04) keys off `.threadline-ui.phx-loading`/`.threadline-ui.phx-error` (the LiveView ROOT), NOT `<body>`, and NEVER `.phx-disconnected` (which doesn't exist in LiveView 1.x — the dropped-socket state re-applies `.phx-loading`). Corrects the literal wording of D-08/UI-SPEC per RESEARCH Pitfall 1; resolves Open Q1 / A2. **Conflict 2 (breadcrumbs):** keep `page_header/1`'s existing `attr(:breadcrumbs, :list)`; do NOT add a same-named `:breadcrumbs` slot (Phoenix forbids attr+slot name collision → compile error). Deliberate deviation from D-04's literal "slot" wording, justified by D-14 discretion (breadcrumbs are location DATA, not arbitrary markup) + RESEARCH Pitfall 4; Plan 03 adds narrow-viewport truncation only. **Token decision:** `--tl-gap-section`→`--tl-space-8` (32px), `--tl-gap-inline`→`--tl-space-2` (8px), `--tl-gap-stack`→`--tl-space-4` (16px) (D-09 / RESEARCH A1). Laid 12 RED scaffolds (3 source/parity in brandbook_token_parity_test + style_contract_test; 9 component renders in ui_test for stack/cluster/data_panel×4/toolbar×2/detail_header) + 1 GREEN breadcrumbs-trail test. Full suite 1071/12 — every failure is a new expected RED scaffold; no pre-existing regression. RED is the deliverable (Plans 02–05 turn green). Zero new dep (v1.37 invariant). Commits `bede897`, `4b7e304`.
- [176-03]: Migrated the display/read-only operator pages onto the Plan-02 components (non-destructive consumer migration; coverage/retention/redaction are plans 04/05 and were NOT touched). Transaction copy footgun closed — transaction id + correlation id + diff before/after cells all bind `data-tl-copy={full}` via `UI.ref/1` (never `.title`/`.visible`/`.text`, D-02); transaction metadata → `UI.kv`; diff cells truncate via `value_token` (max 56) + gated per-cell copy bound to the full value (`diff_full/1`, D-04); timestamps in semantic `<time datetime=exact_time>` UTC (D-22). actor/timeline/evidence/export migrated to `UI.ref` (copy=full) + `UI.kv` (export per-job + both export-context `tl-param-list` retired). Per-page data-state: actor + timeline branch ok-empty into `empty_state variant=never` (first-run, history) vs `no_data` (narrowing filter active, funnel) — distinct icon SHAPE (D-17); evidence `no_data`; export `never`; invalid-actor-ref → `error_state`. **Rule-1 bug:** `UI.ref` used `String.to_existing_atom(kind)` which raised for `:correlation`/`:arn`/`:actor`/`:email` (atoms not interned) — added `Presentation.kinds/0` + `kind_from_string/1` (literal `@ref_kinds`, compile-time interned) and switched `UI.ref` to the safe resolver. **Rule-3:** `UI.ref` can't nest in an `<a>` (button-in-anchor) — copyable ref renders standalone, deep-link demoted to sibling Timeline/Actor affordance. `.tl-secondary-ref` CSS double-truncation removed (`text-overflow:ellipsis` gone, `overflow-wrap:anywhere` kept, D-05) with the paired `style_contract_test` assertion (refute ellipsis + assert wrap) updated in the SAME commit. Zero new `--tl-*` token; brand-parity + style_contract green. 213 targeted tests green; the 6 remaining operator_surface failures are the documented cross-plan Wave-0 RED scaffolds owned by plans 04/05 (1 card-nesting + 5 retention T3/ref-copy). Commits `e1650c8`, `32b0977`, `a798147`. Capture/semantics untouched.
- [Phase ?]: [177-04]: Completed the motion + connection-lifecycle layer — overlay JS-transition utility CLASS selectors + modal/drawer/toast shells (overlay motion now real), every overlay JS.show/hide synced to time: 180 (=--tl-motion-base), toast fade-up via show_toast/2; reconnect/offline group keyed off the LiveView ROOT .threadline-ui.phx-loading/.phx-error (NOT body, NEVER the legacy disconnected class — Pitfall 1) with a warning-tinted role=status banner + [data-tl-mutating] disable + UI.reconnect_banner/1 documenting the mutating-link aria-disabled/tabindex=-1 contract (Pitfall 6). Both Plan-01 style_contract RED scaffolds GREEN; full suite 1071/0; compile/format/credo(2115)/brand-parity clean; zero new keyframes/tokens/deps; capture/semantics untouched. GROUP-01/02 NOT closed (Plan 05). Commits da4a36d, f1695a1.
- [Phase 178]: [178-06] D-11 corrected: LiveView lifecycle classes attach to [data-phx-main]; reconnect CSS scopes into .threadline-ui. — Real-engine socket-drop verification proved the prior .threadline-ui lifecycle-anchor premise false.
- [Phase 178]: [178-06] Real socket-drop proof must assert visible banner and computed mutating-control dimming/restoration, not lifecycle-class detection alone. — The closure bug was masked by tests that observed class flips without asserting visible/computed behavior.
- [Phase 179]: Shell IA relabeling changed only visible group labels — Preserved nav ids, route hrefs, current atoms, data-testids, and destination order for adopter/bookmark stability.
- [Phase 179]: Home uses task-led job titles with existing workflow destinations — Matched Phase 179 IA while keeping Timeline, Coverage, Evidence, Redaction, Retention, Exports, row-history, and correlation workflows unchanged.
- [Phase 179]: Shared state grammar stays in existing UI and Unsupported helpers — Plan 179-02 normalized state, validation, unsupported, and export-denied copy without adding a copy registry, dependency, LiveComponent, route, or new capability.
- [Phase 179]: 179-03 kept actor, transaction, row-history, and coverage copy inside existing page modules. — No route, public API, dependency, LiveComponent, or capability was added.
- [Phase 179]: 179-03 uses covered for table status and need capture for remediation. — This preserves audit-readiness language without overclaiming complete timeline answers or proof that capture is complete.
- [Phase 179]: 179-04 keeps Timeline explanatory copy below filters, result status, investigation checks, export actions, saved views, and rows.
- [Phase 179]: 179-04 Timeline invalid-filter and unknown-table copy names the failed object and next action while preserving parser/audited-table details.
- [Phase 179]: 179-04 e2e assertions were aligned to current shell, retention modal, and seeded Timeline row-history contracts.
- [Phase 179]: Evidence/export copy now reserves proof-history language for append-only history/detail contexts while using Evidence for current state and handoff labels.
- [Phase 179]: Redaction LiveView preserves the shared Drift detected status-label contract while rendering Redaction drift detected as page-level governance copy.
- [Phase 179]: Retention destructive actions consistently name the retention window and permanent pruning consequence.
- [Phase 179]: Phase 179 stress copy evidence was added to existing story ids only; no stress story, ledger id, route, selector, density knob, capability, ledger row, or DESIGN-SYSTEM projection was added. — Preserves COPY-03 and D-17 stability while adding durable copy-state evidence for final Phase 179 terminology.
- [Phase 179]: The component matrix remains available for component/state/foundation stress stories, but page, footgun, and future-reserved screenshot targets stay bounded to preserve the Phase 178 ledger baselines. — Keeps ledger-owned screenshot baselines useful while avoiding screenshot churn from unrelated component stress content.
- [Phase 180]: 180-01: Use existing Playwright operator accessibility spec for rendered-state A11Y-01 proof; no axe scan or new dependency was added.
- [Phase 180]: 180-01: Use shared LiveView JS overlay helpers for focus entry/restoration where possible, with stress-route-only fixtures for missing rendered state coverage.
- [Phase 180]: 180-01: Classify examples/threadline_phoenix mix precommit demo seed failures as inherited/non-owned for this plan.
- [Phase 180]: [Phase 180-02]: APG guardrails stay implementation-specific: custom widgets get specific ARIA popup/relationship hooks, while native select/input/table behavior is asserted instead of role-inflated.
- [Phase 180]: [Phase 180-02]: Tabs and segmented controls use actual rendered selectors for target sizing and non-color selected-state cues; stale selector rules are removed.
- [Phase 180]: [Phase 180-02]: No dependencies, audit frameworks, public routes, public component APIs, or stress-route auth behavior were added.
- [Phase 180]: [Phase 180-03]: MOTION-01 guardrails stay in the existing style contract and operator-motion Playwright harness, preserving enabled press feedback while collapsing reduced-motion behavior without new dependencies.
- [Phase 180]: [Phase 180-04]: Replaced the manual screen-reader checkpoint with Playwright accessibility-tree snapshots and explicit proof limits; no real assistive-technology UAT is claimed.
- [Phase 180]: [Phase 180-04]: Dynamic E2E ports require LiveView origin checks to be disabled in Phoenix test config only; production origin behavior is unchanged.
- [Phase 180]: [Phase 180-04]: Screenshot regression guards now discover current `ticket_replies` seeded rows instead of stale #4521 correlation assumptions, and local desktop/mobile baselines were refreshed from current rendered output.
- [Phase 180]: [Phase 180-04]: Retention destructive modal tests must open the conditionally mounted modal before asserting or submitting `form[phx-submit=prune_now]`.
- [Phase 181]: Plan 01 keeps screenshot evidence tiered: partial Tier C PNGs are committed, failed cells are recorded with owners, and CI screenshot allowlist remains bounded. — This preserves D-181-07/D-181-08 while avoiding a full page x path x theme x viewport pixel matrix.
- [Phase 181]: Plan 01 adds a desktop-1024 responsive viewport row without changing operator routes, data-testids, capture/query/auth semantics, public APIs, or dependencies. — The new row extends the bounded rendered-slice matrix required by D-181-07 and records current stale Timeline discovery failures for repair.
- [Phase 181]: [181-02] 181-03 owns stale E2E/demo-seed discovery and copy assertion repair; Timeline/Coverage page polish remains deferred to 184/185. — Recorded in 181-02-SUMMARY.md key-decisions.
- [Phase 181]: [181-02] 181-04 owns active source-test prose that still says RED today/RED until after the guarded behavior landed. — Recorded in 181-02-SUMMARY.md key-decisions.
- [Phase 181]: [181-02] Local screenshot skips and stress bad-param strings are intentional guards/fixtures, not defects. — Recorded in 181-02-SUMMARY.md key-decisions.
- [Phase 181]: 181-03 replaced stale issue-number/correlation E2E contracts with current ticket_replies table-filter discovery, transaction href navigation, row-history redaction, and DELETE-row actor transaction checks. — Recorded in 181-03-SUMMARY.md after the targeted Playwright suite passed 18/18.
- [Phase 181]: 181-03 kept adjacent stale browser families outside the declared file contract as residual ledger ownership instead of editing out-of-scope files. — Plan 03 files were explicitly limited to operator.spec.ts, operator-screenshots.spec.ts, and 181-GUARD-REPAIR.md.
- [Phase 181-04]: Plan 181-04 repairs active source-test prose and failure messages while preserving executable assertions, route paths, feature gates, public APIs, and production source. — Plan scope is documentation/prose in tests and guard ledger; behavior remains unchanged.
- [Phase 181-05]: Route/export/stress/header boundaries are locked through source contracts rather than rendered UI redesign. — Plan 05 protects server route/auth/export and feature-gate invariants without changing operator IA or layout.
- [Phase 181-05]: Feature-gated nav group IDs are additive semantic hooks only. — Existing destination IDs, hrefs, copy, active-state semantics, and public component API remain unchanged.
- [Phase 181-05]: Root threadline continues to exclude PhoenixStorybook/Storybook and production story/stress routes. — Phase 182 owns example-app dev/test Storybook; root optional Phoenix boundaries stay intact.
- [Phase 181-06]: 181-06 leaves .planning/design-system-ledger.json, DESIGN-SYSTEM.md, stress fixtures, stress route source, and stress tests unchanged because the existing source-contract slice is green.
- [Phase 181-06]: The three bounded screenshot allowlist cells remain page.home.happy, page.timeline.empty, and footgun.transaction-page-left-push-desktop; broader screenshot freshness remains owned by 181-07 through 181-10.
- [Phase 181-baseline-audit-and-guard-repair]: Stress CI screenshots now read `.planning/design-system-ledger.json` `screenshot_allowlist.ci` directly instead of a separate hardcoded allowlist. — Bounded stress screenshot guard stays ledger-backed and matrix-bounded while local packet evidence remains outside CI baselines.
- [Phase 181-baseline-audit-and-guard-repair]: The selected happy/error/permission/boundary stress-state PNGs are local-only planning evidence, not CI `toHaveScreenshot` baselines. — D-181-07 needs Tier C evidence without expanding the accepted Tier B screenshot ratchet.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 08 found all existing operator-screenshot-regression desktop/mobile local PNG baselines current, with no accepted Plan 09 or Plan 10 PNG updates discovered.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 08 preserved the generic chromium local screenshot-regression skip as intentional platform-sensitive guard behavior rather than expanding CI coverage.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 08 re-recorded the example-app mix precommit residual as inherited demo-seed/walkthrough drift, not local screenshot-regression or PNG baseline fallout.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 09 left all four Home/dense Timeline PNG baselines untouched because Plan 08 classified them as current committed local baselines with no accepted update.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 09 did not run --update-snapshots; the bounded Home/dense Timeline subset passed against existing desktop/mobile local baselines.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 09 re-recorded the example-app mix precommit residual as inherited demo-seed/walkthrough drift, not screenshot baseline fallout.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 10 left all six Row-history/Exports/Retention PNG baselines untouched because Plan 08 classified them as current committed local baselines with no accepted update.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 10 did not run --update-snapshots; the bounded Row-history/Exports/Retention subset passed against existing desktop/mobile local baselines.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 10 re-recorded the example-app mix precommit residual as inherited demo-seed/walkthrough drift, not screenshot baseline fallout.
- [Phase 181-baseline-audit-and-guard-repair]: 181-11: Full CI remains red but classified; Phase 181 closes on targeted guard evidence plus residual ownership, not by relabeling red gates as green.
- [Phase 181-baseline-audit-and-guard-repair]: 181-11: The local Tier C screenshot packet is complete planning evidence and does not expand the CI screenshot allowlist.
- [Phase 182]: Plan 182-01 is RED-only by design: it locks executable contracts before package, route, story, or documentation implementation. — Phase 182 implementation is split across later plans, so this plan intentionally commits failing contracts first.
- [Phase 182]: Storybook browser coverage stays bounded to index plus representative primitive/form/state/overlay/data-display/group stories; no screenshot matrix or external visual regression service was added. — D-182-20 requires bounded browser smoke rather than broad screenshot or SaaS visual-regression coverage.
- [Phase 182]: Root optional-dependency hygiene remains protected by source contracts and mix verify.compile_no_optional. — The plan adds tests only and proves no root PhoenixStorybook dependency leakage occurred.
- [Phase 182-02]: PhoenixStorybook remains an example-app dev/test dependency only; production compiles through a no-op router macro fallback when the package is absent.
- [Phase 182-02]: The maintainer Storybook lane is mounted at /dev/storybook outside /audit and outside normal operator navigation.
- [Phase 182-03]: Core Storybook category files use PhoenixStorybook page stories to document multiple private UI functions without promoting a public component API. — Plan 03 covers category pages, not one public component story per exported API; private operator components remain private.
- [Phase 182-03]: Storybook fixtures expose static samples plus an explicit StressFixtures allowlist, with no database, dynamic atom, ledger mirror, or full stress registry navigation. — This preserves D-182-06 and D-182-07 while giving stories representative ugly data.
- [Phase 182-03]: Overlays, Data Display, Groups, and Patterns received index metadata now to satisfy the RED category spine while later plans still own their story content. — The existing RED story contract required the full top-level category spine before Plan 04 and Plan 05 add those stories.
- [Phase 182-04]: Storybook coverage remains curated component documentation; /audit/__stress remains the flow-level stress harness.
- [Phase 182-04]: Groups sample StressFixtures only through an explicit Storybook helper allowlist instead of mirroring the ledger or full registry.
- [Phase 182-04]: The light/system Playwright lane includes Storybook only through operator-storybook.spec.ts and asserts that bounded contract.
- [Phase 182]: Phase 182 closes on targeted Storybook/package/route/story/browser/stress/docs evidence while classifying inherited example demo-seed and broad-suite residuals as non-green. — Plan 05 verification found all targeted Phase 182 gates green, while mix precommit and mix ci.all still include pre-existing residuals outside the Storybook/docs scope.
- [Phase 182]: Storybook remains example-app dev/test maintainer component documentation; /audit/__stress remains the authenticated operator-flow stress harness. — Docs contracts and 182-VERIFICATION.md preserve the root optional dependency and production-route boundaries.
- [Phase 182]: No schema push task was required because Plan 05 modified only docs and planning verification artifacts. — No schema, migration, SQL trigger, config, struct field, CLI flag, decorator, or dataclass-style field changed.
- [Phase 183]: Plan 01 remains RED/proof-only: browser failures are actionable Plan 02 evidence, not production retuning scope. — 183-01 adds the browser perception proof before shell/Home implementation polish and the plan explicitly allows actionable browser failures.
- [Phase 183]: The Phase 183 supplement is admitted to the existing system/light lane rather than adding a new Playwright project or screenshot matrix. — The plan forbids screenshot matrix expansion and requires preserving the THREADLINE_E2E_THEME=system desktop-chromium-light lane.
- [Phase 183]: Plan 183-02 kept native mobile details/summary navigation but moved the single nav panel to a sibling so desktop rail visibility does not depend on closed-details internals. — Chromium keeps non-summary descendants hidden in closed details, which broke the Phase 183 desktop browser proof.
- [Phase 183]: Plan 183-02 forced example e2e compilation before browser runs so THREADLINE_E2E_THEME compile-time router gates match the current lane. — The system/light lane reused stale dark-compiled router artifacts until the runner used mix compile --force.
- [Phase 183]: Phase 183 closes as targeted PASS with classified residuals: dedicated source and browser evidence is green, broad command failures remain non-green and scoped.
- [Phase 183]: Generated light screenshot candidates from broad verification were treated as verification byproducts and not committed as baselines.
- [Phase 183]: No package, schema, public API, route, data-testid, or adjacent page content change was accepted during Phase 183 closeout.
- [Phase 184]: Timeline row-history links are emitted only for rows with exactly one nonblank scalar primary-key value; unsafe identities keep the transaction pivot only.
- [Phase 184]: Timeline export handoff remains canonical-query driven through FilterParams and ExportController rather than duplicating filter semantics in the UI.
- [Phase 184]: The Timeline command surface reports result facts once through the facts/filter summary; duplicate status copy and its dead selector were removed.
- [Phase 184]: Timeline empty states now distinguish first-run, filtered no-data, and future-window copy through private reason helpers instead of a single future-window boolean. — This preserves distinct operator meanings for no captured changes, no matches, and future windows without adding a new component family.
- [Phase 184]: Timeline rows expose full table, actor, correlation, and safe row-id values for copy/title use while preserving transaction and row-history pivots. — Full values must remain available under long real data; direct row history remains gated by the existing safe routeable identity helper.
- [Phase 184]: No fake Timeline stale branch was added; stale/last-good proof remains with shared UI.stale_banner/data-state primitives because Timeline has no dedicated stale assign. — The plan explicitly prohibited fabricating Timeline-only stale states for coverage when no real branch exists.
- [Phase 184-03]: Use a narrow Timeline-only Playwright proof for required viewport/keyboard/copy/export/theme/reduced-motion coverage instead of broad screenshot baselines.
- [Phase 184-03]: Create browser proof correlation data through existing authenticated /api/posts setup rather than relying on stale demo seed correlations.
- [Phase 184-03]: Classify broad-suite residuals honestly while treating targeted Phase 184 source and browser gates as the closeout authority.
- [Phase 185]: Coverage now answers readiness through one selected-schema verdict and keeps table rows as triage/action detail. — Phase 185 COV-01/COV-02 required deleting repeated readiness signals while preserving row actions.
- [Phase 185]: Phase 185 browser proof stays narrow in the existing light/system lane; non-public schema link truth remains owned by deterministic LiveViewTest setup. — The plan prohibited broad screenshot matrices and had no deterministic example non-public schema fixture.
- [Phase 187]: DOC-01 source truth follows the current runtime server-posted theme picker, not older host-only theme prose. — Plan 187-01 repaired the operator guide and doc contracts against router, surface header, theme controller, and auth source truth.
- [Phase 187]: Storybook remains example-app dev/test maintainer tooling; /audit/__stress remains authenticated stress proof, not production public component documentation. — Plan 187-01 preserved optional dependency, production exclusion, private component, and stress route boundaries in docs and doc contracts.
- [Phase 187]: Plan 187-02 closed A11Y-01/A11Y-02 proof gaps with focused test-only coverage; no private UI or CSS repair was needed. — The new source/browser assertions passed against existing product behavior after proof-specific locator corrections.
- [Phase 187]: Plan 187-02 made no MOTION-01 source changes because existing source and browser-computed proof already covered the Phase 187 contract. — style_contract_test.exs and operator-motion.spec.ts passed unchanged for token, keyframe, transition, and reduced-motion requirements.
- [Phase 187]: Phase 187 closeout treats targeted source/browser/stress proof as green while preserving standalone screenshot and broad CI failures as classified residuals; no real screen-reader certification or screenshot stability claim is made from non-green evidence. — CLOSE-01 requires exact evidence, residual ownership, and proof limits rather than assertion-only closure.
- [Phase 188]: 188-01 queued export worker replay reuses FilterParams.parse/1 instead of a second parser — This preserves URL-shaped string-keyed ExportJob.query_params while ensuring from/to are DateTime filters before Threadline.Query runs and invalid params fail closed.
- [Phase 188]: .tl-copy uses explicit transition-property source governance — 188-02 replaced token-only shorthand with color, border-color, background-color, and box-shadow declarations, and StyleContractTest now rejects token-only transition shorthand.
- [Phase 188]: Phase 188 closeout used focused ExUnit/source evidence plus equivalent audit classification; no browser or screenshot proof was added because source contracts covered .tl-copy.
- [Phase 188]: Phase 188 preserves legacy broad CI, screenshot, Hex auth/advisory, and older Nyquist residuals as explicit audit residuals instead of relabeling them green.
- [Phase 189]: Phase 189 routes custom storage-schema proof and fixes to Phase 190 based on public docs plus fixed-prefix source evidence.
- [Phase 189]: Phase 189 treats screenshot, external pilot, and host staging claims as proof-boundary residuals instead of implementation scope.
- [Phase 190]: [190-01]: Generated install migration SQL uses Threadline.StorageSchema quoted identifiers for every validated storage-schema table, function, and drop/index reference touched by SCHEMA-03.
- [Phase 190]: [190-01]: Adopter docs now show storage_schema: "audit" before mix threadline.install and state that generated migration files freeze the configured schema name.
- [Phase 190]: [190-02] Threadline-owned Ecto schemas now rely on Repo prefix options instead of fixed @schema_prefix attributes. — SCHEMA-02 requires configurable storage schemas not to silently read from or write to hardcoded threadline.
- [Phase 190]: [190-02] Storage-schema test support is explicit and test-only; it does not add a production fallback or Repo hook. — Tests should make omitted prefix plumbing visible while later Phase 190 plans wire production Repo operations.
- [Phase 190]: [190-03]: Treat the per-transaction storage_schema option as authoritative for core audit writes, action linkage, audit-transaction lookup, and captured-change metadata.
- [Phase 190]: [190-03]: Query and investigation preloads must pass resolved storage options explicitly so association reads cannot fall back to the default threadline schema.
- [Phase 190]: [190-04]: Queued export and cleanup runtimes resolve storage_schema once per run/state instead of re-reading global config for each Repo operation.
- [Phase 190]: [190-04]: Export downloads resolve configured storage_schema before lookup and preserve actor authorization after the prefix-scoped fetch.
- [Phase 190]: [190-05]: Retention direct runs and pruner runtimes resolve storage_schema from explicit opts with global config as the default. — This preserves the Phase 190 global configured storage contract while making selected-storage sentinel proof deterministic for retention/pruner paths.
- [Phase 190]: [190-05]: Retention and pruner tests use audit/threadline dual-storage sentinels for destructive governance paths. — SCHEMA-01 requires wrong-prefix deletes, counts, inserts, and updates to be caught by tests, not inferred from source strings.
- [Phase 190]: [190-07]: Malformed host table identifiers now fail before SQL generation. — Empty or ambiguous dot segments could collapse into valid-looking identifiers and weaken host-schema trigger confidence.
- [Phase 190]: [190-07]: Continuity readiness treats selected support schema values as host table identity only. — `support.tickets` and `schema: "support"` select the host table for readiness checks without changing Threadline storage-schema reads.
- [Phase 190-08]: Selected redaction schema is host-schema only — Policy CLI and LiveView validate --schema/?schema with CoverageSchemas and pass it only to redaction catalog inspection; Threadline-owned storage_schema remains governed separately by repo opts.
- [Phase 190]: Timeline renders table_schema as host schema so operators do not confuse audited host schemas with Threadline storage_schema.
- [Phase 190]: Non-public row-history links require exact schema-qualified schemas keys such as support.tickets; public rows keep bare-table shorthand.
- [191-03]: ADOPT-01 install/version reconciliation — seven install pins flipped to three-segment ~> 0.9.0 (co-committed with four guard tests, no CI/release reddening); evaluating-threadline.md false 0.6.0 SSOT corrected to 0.9.0 + release-please marker/extra-files wiring (historical lines preserved); version_truth_doc_contract_test derives Families A/B/C from mix.exs @version and is registered in verify.doc_contract. Pre-existing v1_23_charter failure left deferred (charter truth out of this plan's task scope).
- [Phase ?]: [195-01]: verify.ui_critique is local-only (excluded from ci.all, exits 0 when ANTHROPIC_API_KEY absent, RUNNER-04). verify.critic_trust is pure-Elixir in ci.all before verify.mechanical. All 6 critic lenses seed validated:false. critic-scores/ tree is gitignored; .planning/golden/ is committed oracle.

### Blockers

- None.

## Session Continuity

**Last session:** 2026-08-27T18:59:19.504Z
**Stopped at:** Phase 198 context gathered
**Resume file:** .planning/phases/198-green-bringup/198-CONTEXT.md

- **Milestone closeout (2026-05-29):** v1.29 archived; tag `v1.29`; REQUIREMENTS.md removed for fresh next milestone.
- **130.1-02 (2026-05-29):** 130-VALIDATION superseded footnote; Nyquist waivers for 128/129; 130.1-VERIFICATION passed; `mix ci.all` green (744+61 tests).
- **Milestone closeout (2026-06-14):** v1.36 Operator Surface Light Mode archived (ROADMAP + REQUIREMENTS + AUDIT under `milestones/v1.36-*`), PROJECT.md evolved, tag `v1.36`, REQUIREMENTS.md removed for fresh next milestone. Finding F1 resolved — entangled `style.ex` light source committed (`b9f8fc1`); suite green at 912 tests. 6 items acknowledged-deferred (see Deferred Items).
- **175-02 (2026-06-17):** CSP-proof operator shell + runtime theme picker. Removed all 3 inline handlers; rebuilt picker as native radios + Apply button + `:has(:checked)` cue; native `<details>[open]` nav; scroll-padding-top/overscroll/100svh hardening; router doc corrected; theme-toggle ban lifted for a positive CSP guard. Plan-01 CSP RED target now GREEN (9 RED -> 8 RED Wave-0 targets remaining for Plans 03/04). Commits `b0a8c9c`, `25a582d`. Backend untouched (D-09); brand-token parity green.
- **175-03 (2026-06-17):** Internal `UI.page_header/1` + drill-down breadcrumbs. Built the one-`<h1>` page header (reusing existing CSS, zero new token, no public API), adopted it across the operator pages, threaded `[Timeline > …]` location breadcrumbs under `<nav aria-label="Breadcrumb">` into the 3 drill-down pages, relabeled away the bespoke "Investigation path" landmark, and set drill-down `current={nil}` so the single `aria-current="page"` stays on a nav link only. Re-pointed the D-02 doc-contract back-link assertions to the new D-13 breadcrumb root. Both NAV-01 Wave-0 RED targets GREEN; only the 4 Plan-04 PagerTest RED targets remain. Commits `025e9d3`, `3e4b1c7`. style.ex + capture/semantics untouched; brand-token parity green.
- **175-04 (2026-06-17):** Internal `UI.pager/1` + honest cap captions. Built the de-emphasized Older/Newer pager (hide-at-zero, disable-not-hide, capped "10,000+", role=status caption) over the existing keyset engine, adopted it next-only on Timeline (cursor in assign, D-19) and bidirectionally on Actor, added "Showing latest N" cap captions on Exports/Retention (D-20, none on Coverage/Redaction), and documented the `(captured_at, id)` keyset tiebreaker as deferred capture-layer perf debt in query.ex (D-15/Q1; no migration, capture layer untouched). All 4 NAV-02 Wave-0 PagerTest RED targets GREEN; verify.test 1008/0; brand-token parity green; zero new token. Commits `1a230bd`, `ac6f762`.
- **176-01 (2026-06-18):** Presentation core + icon contracts + Wave-0 RED scaffolds. Built `ref/2` (3-face, full == complete value), `truncate_middle/3` `:tail_min` (≥8 tail, default unchanged), per-kind `truncate_for/2`, `value_token/1` truncation (56, full in title); added `eye_off`/`funnel`/`lock`/`cloud_off` glyphs; authored the four MISSING Wave-0 tests (card-nesting D-12, typed-reason→state D-16, T3 fail-closed+audit D-21, ref-copy-equals-full Pitfall 4) all RED against current code with zero new deps. Commits `989f03c`, `45a788d`, `a4a13fa`, `3503fdc`, docs `5c18abf`.
- **176-02 (2026-06-18):** UI data-display + data-state component set. Built `ref/1`, `kv/1`, `data_table/1`, `loading_state/1`, `stale_banner/1`, three new `empty_state` variants, and the `data_state/1` typed-reason dispatcher as pure render functions with per-component contract tests + 10 isolated `/audit/__stress` stories (ledger + DESIGN-SYSTEM parity). Turned the Plan-01 `data_state_mapping` wave-0 RED test GREEN at the component level. ui_test 52/0, stress 33/0, parity+style_contract 37/0; warnings-as-errors clean; format clean. No page migrated. 6 cross-plan Wave-0 scaffolds stay RED by design. Commits `d3273d3`, `617eb47`, `8c880a6`, `93a8027`, `9e17e86`.
- **176-04 (2026-06-18):** Coverage flatten + card-nesting regression GREEN. Replaced the coverage success branch's hand-rolled `tl-coverage-command` header with `UI.page_header` (all 3 branches now use it; added an optional `:meta` slot to page_header for the last-checked line), demoted the command shell to plain page-stack siblings (kept `tl-card--metric` tiles), deleted the dead `tl-coverage-command__*` CSS with a paired style_contract refute lock (T-176-08), and turned the Plan-01 card-nesting Wave-0 RED test GREEN across all 11 surfaces (Task 2 needed no source change beyond Task 1's flatten). Operator_surface suite 545/5 (1 card-nesting RED → GREEN; 5 remaining are plan-05 retention T3 + ref-copy). Zero new token; brand-parity green; capture/semantics untouched. Commit `157398d`.
- **177-01 (2026-06-18):** Wave-0 conflict resolution + RED test scaffolds. Bound both locked-decision-vs-reality conflicts in writing (offline anchor = `.threadline-ui` LiveView root, NOT body/`.phx-disconnected`; keep the breadcrumbs list attr, no slot) and laid 12 RED scaffolds (3 source/parity + 9 component renders) + 1 GREEN breadcrumbs-trail test across the three test files. Full suite 1071/12 — all 12 failures are the new expected RED scaffolds; no pre-existing regression; format clean. Zero production code, zero new dep. Commits `bede897`, `4b7e304`.
- **177-02 (2026-06-18):** Layout primitives + semantic gap tokens. Added the three `--tl-gap-*` tokens parity-first across tokens.css/tokens.json/style.ex, then shipped `UI.stack/1` + `UI.cluster/1` (`@doc false`, card/1 idiom) with `.tl-stack`/`.tl-cluster` flexbox-gap CSS owning the spacing rhythm. Turned the Plan-01 gap-parity + stack/cluster RED scaffolds GREEN (gap-parity 4/0; combined gap+ui 66/7 where the 7 are out-of-scope Plan-03 data_panel/toolbar/detail_header scaffolds). Zero new dep; no public API; format + credo clean; capture/semantics untouched. Commits `8d701e8`, `38005a3`.
- **177-03 (2026-06-18):** Meta-components + breadcrumb truncation. Shipped `UI.data_panel/1` (state-coordinating shell composing the existing state family; stale-above-data; focus delegated; pager only :ok), `UI.toolbar/1` (disabled-coordination on cluster, Pitfall 6 contract), and `UI.detail_header/1` (`<h2>` + kv + actions cluster); reconciled breadcrumbs by keeping the list attr (D-14) + `clamp()` current-crumb truncation. Self-caught + fixed a phase-141/142 StyleContractTest governance regression (new `@media` literal + a `~1ms` comment) within the plan. All 7 component RED scaffolds GREEN; full suite 1071/2 (2 = Plan-04 overlay/offline RED-by-design, identical to baseline); compile/format/credo clean. Commits `1f4d6d7`, `2b082f8`, `19ef009`.
- **177-04 (2026-06-18):** Overlay motion + reconnect/offline group. Defined the previously-missing overlay JS-transition utility CLASS selectors (`.tl-fade-in/out`, `.tl-rise-in/out`, `.tl-slide-in/out-right`, `.opacity-0/100`, `.translate-y-0/4`, `.translate-x-0/full`, `.hidden`) + the modal/drawer/toast SHELLS (all were absent from style.ex) so overlay enter/exit motion is real; synced every overlay `JS.show/hide` to explicit `time: 180` (= `--tl-motion-base`, Pitfall 3) and added a toast fade-up entrance via `show_toast/2`. Built the reconnect/offline group keyed off the LiveView ROOT `.threadline-ui.phx-loading/.phx-error` (NOT body, NEVER the legacy disconnected class — Pitfall 1): warning-tinted `role=status` reconnect banner + `[data-tl-mutating]` pointer-events/opacity disable; added `UI.reconnect_banner/1` documenting the mutating-link `aria-disabled`/`tabindex=-1` contract (Pitfall 6). Self-caught + fixed a `.phx-disconnected` literal in a CSS comment that reddened the offline refute (comments are scanned, same gotcha class as Plan 03's `\d+ms`). Both Plan-01 style_contract RED scaffolds GREEN; full suite 1071/0; compile/format/credo(2115)/brand-parity clean. Zero new keyframes/tokens/deps; no public API; no inline `on*=`; capture/semantics untouched. GROUP-01/02 NOT closed (Plan 05). Commits `da4a36d`, `f1695a1`.
- **177-05 (2026-06-18):** GROUP-01 12-config stress mapping + ledger/projection parity (FINAL plan of phase 177). Remapped `@group_stories` from the 6 reserved baselines to the 12 GROUP-01 configurations as `status:current`/`owner_phase:177` via a `group_story/4` builder carrying a `surface` tag (`:live`|`:reference`) in both data + metadata (D-07; 10 live + 2 reference-only). Absorbed all 6 prior reserved baselines (action-bar/filter-bar/kv-list/pagination/status-strip/timeline-list) — zero orphaned `*.reserved` group ids. Synced `design-system-ledger.json` (12 current group entries 62/62/90, surface in `notes` — no new `@entry_keys`; reconciled `locked_ids`/`minimum_scores`/`required_inventory.groups`) + the DESIGN-SYSTEM.md Groups projection in lockstep; ledger parity GREEN. Added a `stress_router_test` assertion rendering all 12 group ids across 320/375/768/1024/1440 × dark/light/system. Marked GROUP-01 + GROUP-02 complete in REQUIREMENTS.md. Full library suite **1074/0** (1 excluded); verify.format/credo(2129)/compile-warnings-as-errors all clean; zero new dep, no public API, capture/semantics untouched. The only `mix ci.all` failure is a **pre-existing** example-app demo-seed 60s setup timeout (proven unrelated to plan 05 via stashed-baseline run; logged to `deferred-items.md`). Commits `8987793`, `8f62d25`, `9ca8453`, `313e52c`, `2a81604`.
- **Last Action**: Completed Phase 190 with 10/10 plans, passed verification, and recorded storage-schema confidence evidence (2026-07-02).
- **Next Step**: Discuss or plan Phase 191.
- **Resume file**: `.planning/ROADMAP.md`

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
