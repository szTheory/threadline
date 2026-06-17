---
gsd_state_version: 1.0
milestone: v1.37
milestone_name: Operator Surface Design-System Stress Test & Component System
status: ready_to_plan
last_updated: 2026-06-17T20:24:50.924Z
last_activity: 2026-06-17
progress:
  total_phases: 15
  completed_phases: 4
  total_plans: 20
  completed_plans: 20
  percent: 27
stopped_at: Phase 175 complete (4/4) — ready to discuss Phase 176
---

# Project State: Threadline

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-12)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current focus:** Phase 176 — data display & operator patterns

## Current Position

Phase: 176
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-17

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
| Phase 166 P01 | 65min | 5 tasks | 17 files |
| Phase 168 P01 | 25min | 3 tasks | 1 files |
| Phase 170 P01 | 18m | 3 tasks | 5 files |
| Phase 170 P02 | ~9m | 2 tasks | 2 files |
| uat_gap (v1.36 close 2026-06-14) | 169-HUMAN-UAT.md — 1 pending scenario | partial — acknowledged & deferred |
| uat_gap (v1.36 close 2026-06-14) | 170-HUMAN-UAT.md — 1 pending scenario | partial — acknowledged & deferred |
| verification_gap (v1.36 close 2026-06-14) | 170-VERIFICATION.md | human_needed — acknowledged & deferred |
| todo (v1.36 close 2026-06-14) | transaction-page-left-push-desktop (operator-surface layout bug) | pending — carried to backlog |
| todo (v1.36 close 2026-06-14) | coverage-schema-card-declutter (operator-surface cosmetic) | pending — carried to backlog |
| todo (v1.36 close 2026-06-14) | theme-picker-idiomatic-ui (THEME-TOGGLE-01, out of v1 scope per [165-01]) | pending — carried to backlog |
| Phase 174 P06 | 6min | 2 tasks | 2 files |
| Phase 175 P01 | 14min | 2 tasks | 5 files |
| Phase 175 P02 | ~15min | 2 tasks | 4 files |
| Phase 175 P03 | ~30min | 2 tasks | 11 files |
| Phase 175 P04 | ~12min | 2 tasks | 7 files |

## Accumulated Context

### Pending Todos

- **Human gate (after Phase 166, before Phase 167):** light-lane design review — user eyeballs the rendered light surface (status-tint keystone included) before retune effort is spent.
- **Human gate (after Phase 170):** end-of-milestone UAT across dark/light/system modes before closeout.
- **Standing caution (all v1.36 phases):** never stage, edit, or revert the user's uncommitted nav-overhaul lane (~29 files under lib/, examples/, test/), including its 3 pre-existing test failures.

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

### Decisions

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

### Blockers

- None.

## Session Continuity

- **Milestone closeout (2026-05-29):** v1.29 archived; tag `v1.29`; REQUIREMENTS.md removed for fresh next milestone.
- **130.1-02 (2026-05-29):** 130-VALIDATION superseded footnote; Nyquist waivers for 128/129; 130.1-VERIFICATION passed; `mix ci.all` green (744+61 tests).
- **Milestone closeout (2026-06-14):** v1.36 Operator Surface Light Mode archived (ROADMAP + REQUIREMENTS + AUDIT under `milestones/v1.36-*`), PROJECT.md evolved, tag `v1.36`, REQUIREMENTS.md removed for fresh next milestone. Finding F1 resolved — entangled `style.ex` light source committed (`b9f8fc1`); suite green at 912 tests. 6 items acknowledged-deferred (see Deferred Items).
- **175-02 (2026-06-17):** CSP-proof operator shell + runtime theme picker. Removed all 3 inline handlers; rebuilt picker as native radios + Apply button + `:has(:checked)` cue; native `<details>[open]` nav; scroll-padding-top/overscroll/100svh hardening; router doc corrected; theme-toggle ban lifted for a positive CSP guard. Plan-01 CSP RED target now GREEN (9 RED -> 8 RED Wave-0 targets remaining for Plans 03/04). Commits `b0a8c9c`, `25a582d`. Backend untouched (D-09); brand-token parity green.
- **175-03 (2026-06-17):** Internal `UI.page_header/1` + drill-down breadcrumbs. Built the one-`<h1>` page header (reusing existing CSS, zero new token, no public API), adopted it across the operator pages, threaded `[Timeline > …]` location breadcrumbs under `<nav aria-label="Breadcrumb">` into the 3 drill-down pages, relabeled away the bespoke "Investigation path" landmark, and set drill-down `current={nil}` so the single `aria-current="page"` stays on a nav link only. Re-pointed the D-02 doc-contract back-link assertions to the new D-13 breadcrumb root. Both NAV-01 Wave-0 RED targets GREEN; only the 4 Plan-04 PagerTest RED targets remain. Commits `025e9d3`, `3e4b1c7`. style.ex + capture/semantics untouched; brand-token parity green.
- **175-04 (2026-06-17):** Internal `UI.pager/1` + honest cap captions. Built the de-emphasized Older/Newer pager (hide-at-zero, disable-not-hide, capped "10,000+", role=status caption) over the existing keyset engine, adopted it next-only on Timeline (cursor in assign, D-19) and bidirectionally on Actor, added "Showing latest N" cap captions on Exports/Retention (D-20, none on Coverage/Redaction), and documented the `(captured_at, id)` keyset tiebreaker as deferred capture-layer perf debt in query.ex (D-15/Q1; no migration, capture layer untouched). All 4 NAV-02 Wave-0 PagerTest RED targets GREEN; verify.test 1008/0; brand-token parity green; zero new token. Commits `1a230bd`, `ac6f762`.
- **Last Action**: Completed `175-04-PLAN.md` (2026-06-17) — phase 175 all 4 plans done.
- **Next Step**: Verify phase 175 (`/gsd:verify-work` — incl. Playwright `verify.example_browser`).
- **Resume file**: None

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
