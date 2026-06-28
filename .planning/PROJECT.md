# Threadline

## What This Is

Threadline is an open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines trigger-backed row-change capture, first-class application action semantics (actor, intent, request/job context), and operator-grade exploration tools. It is built for teams who need audit trails that are hard to bypass, SQL-queryable without blobs, and genuinely useful for support and ops — not just compliance.

## Core Value

Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## Current State

Threadline is in milestone **v1.38 Operator UI Page-by-Page IA & Design-System Polish**, opened on 2026-06-26. Phase 181 established the current `/audit` baseline packet, refreshed stale guardrails, preserved the v1.37 ratchet, and classified remaining full-suite residuals. Phase 182 added the PhoenixStorybook example/dev lane as maintainer-only component documentation in `examples/threadline_phoenix`, with root optional-dependency hygiene preserved and `/audit/__stress` still the canonical runtime stress harness. Phase 183 completed the shell navigation and `/audit` Home orientation pass, with targeted source contracts plus dark/default and system/light browser proof green; broad non-green commands remain classified as inherited or out-of-scope residuals.

The highest-impact page-polish pass now moves from shell/Home into Timeline so operators can investigate cleanly from the improved shell. Coverage follows as the audit-readiness workflow, then detail/governance/export surfaces, with accessibility, motion, docs, and adversarial closeout locking the result. Core capture/query/auth semantics remain out of scope.

## Current Milestone: v1.38 Operator UI Page-by-Page IA & Design-System Polish

**Goal:** Make the operator UI feel deliberate, navigable, and task-led page by page while preserving v1.37's internal design-system substrate and the host-app-friendly library boundary.

**Target features:**
- **Baseline audit and guard repair** — current screenshots, route/selector inventory, stale planning cleanup, and any broken guardrail repair before page edits.
- **PhoenixStorybook example/dev lane** — component/state stories for the existing private operator components without making PhoenixStorybook a root `threadline` dependency or public component API.
- **Shell, home, and Timeline cleanup** — clear nav, page titles, active states, orientation affordances, primary tasks, filters, result states, and responsive behavior.
- **Coverage audit-readiness flow** — schema scope, readiness hierarchy, duplicate remediation, and contextual transitions into Timeline without page-level distraction.
- **Detail, governance, and export surfaces** — transaction, actor, row history, redaction, retention, evidence, and export pages reviewed as coherent operator workflows.
- **A11y, motion, docs, and closeout** — keyboard/focus/reduced-motion checks, visual QA matrix, docs alignment, and an adversarial review that prevents regressions.

## Latest Milestone Shipped: v1.37 Operator Surface Design-System Stress Test & Component System (2026-06-20)

**Goal (achieved):** Turn the frozen-token / class-soup `/audit` operator surface into a systematically audited, internally-componentized design system, verified fractally from foundations through primitives, groups, pages, flows, copy, accessibility, motion, and final adversarial closeout.

**Shipped:**
- **Stress-lab harness and ledger** - `/audit/__stress`, static ugly-data fixtures, scored ledger, `DESIGN-SYSTEM.md` projection, and screenshot ratchet guards.
- **Internal design system** - private primitives, overlays, form controls, data-display helpers, layout/meta-components, and group stories with contract tests and no public component API.
- **Operator shell and data surfaces** - consistent navigation, page headers, breadcrumbs, pager, theme picker, copyable full-value refs, data states, coverage flattening, destructive action confirmation, and page stress coverage.
- **Copy, accessibility, and motion closeout** - brand/domain copy sweep, WCAG/APG source and browser guards, reduced-motion proof, automated accessibility-tree evidence, screenshot regression, residual CI classification, and adversarial review.

**Archives:** `.planning/milestones/v1.37-ROADMAP.md`, `.planning/milestones/v1.37-REQUIREMENTS.md`, `.planning/milestones/v1.37-MILESTONE-AUDIT.md`, `.planning/milestones/v1.37-phases/`

**Next milestone goals:** Superseded by active v1.38 page-by-page operator UI polish.

## Prior shipped milestone: v1.36 Operator Surface Light Mode (2026-06-14)

**Goal (achieved):** Implement decision [165-01] (supersedes dark-only [136-01]): `theme: :dark | :light | :system` host config on `threadline_operator_surface/2`, default `:dark`, rendered server-side as a `data-tl-theme` attribute driving a pure-CSS light token lane — zero JS, zero FOUC, CSP-proof, designed-not-recolored.

**Shipped:**
- **Theme mechanism + host API** — compile-validated `theme:` mount option; `data-tl-theme` on the LiveView roots; scoped `color-scheme`; `:system` via scoped `prefers-color-scheme`; `style.ex` + `style_contract_test.exs` amended source-first (seven light refutes → theme-aware assertions; runtime `theme-toggle` ban retained).
- **45-token light lane** — all 45 color-bearing `--tl-*` tokens (19 seeded from the brand light lane, 26 designed; status tints the keystone decision); the stray shell-nav-inset rgba tokenized.
- **Component retune** — ~9 dark-effect families (glass chrome, drawer scrim/shadow, focus glow, home-card effects, shell-nav inset) + explicit light review of coverage/timeline/diff data-viz surfaces (the Grafana lesson), user-approved live in both modes.
- **Accessibility** — light/system AA contrast mirror with an alpha-aware compositing parser; per-mode focus-ring 3:1 and interaction-state contracts; dark phase-143 contract byte-stable.
- **Verification + docs + brand** — `__light__` screenshot lane (local-only), example app demonstrating `theme: :system`, `theme:` documented under doc-contract; `brandbook/tokens.{json,css}` at full 45-token parity (bidirectional parity test) + dual-mode pressure-test + UI-theming-posture note.

**Archives:** `.planning/milestones/v1.36-ROADMAP.md`, `.planning/milestones/v1.36-REQUIREMENTS.md`, `.planning/milestones/v1.36-MILESTONE-AUDIT.md`

**Next milestone goals:** Define fresh requirements via `/gsd:new-milestone`; otherwise hold per the no-signal default. Candidate carry-forwards: THEME-TOGGLE-01 (runtime theme picker, on adopter demand), the transaction-page desktop layout bug, and operator-surface polish todos.

## Prior shipped milestone: v1.35 Unified Logo & Brand Book v2 (2026-06-12)

**Goal (achieved):** Replace the icon-beside-plain-text logo with a unified, tournament-selected identity and elevate the brandbook into a standalone professional HTML brand book — all text/SVG, self-contained.

**Shipped:**
- **C13 "topstitch-geist" identity** — user-selected through a two-round logo tournament (verbatim feedback, mechanical HC gates); a single stitch arc rising from the word's cut d/l ascenders, pure paths, portable in GitHub's font-less SVG sandbox.
- **Brand book v2** — full 8-asset family (designed light primary, chipless self-flipping favicon, tagline isolated to the `-subtitle` variant), standalone `brandbook/index.html` with misuse gallery, imagery section, and a Dark/Light/System preview toggle; pressure-test 128/150 vs the 79/150 baseline.
- **Product rollout** — operator-surface logo component (on the `var(--tl-*)` contract, `style.ex` untouched), example-app favicon, README `<picture>` dark/light header; 886 tests, zero new failures.
- **Light-mode strategy decided** — decision [165-01] supersedes [136-01]: dark stays default/brand-primary; `theme: :dark | :light | :system` host config approved; no runtime toggle in v1; v1.36 "Operator Surface Light Mode" seeded (SEED-004) with a 5-phase breakdown.

**Archives:** `.planning/milestones/v1.35-ROADMAP.md`, `.planning/milestones/v1.35-REQUIREMENTS.md`, `.planning/milestones/v1.35-MILESTONE-AUDIT.md`, `.planning/milestones/v1.35-phases/`

**Next milestone goals:** v1.36 Operator Surface Light Mode when chosen (seed: SEED-004); otherwise hold per the no-signal default.

## Prior shipped milestone: v1.34 Local Docker Admin UI DX (2026-06-07)

**Goal (achieved):** Make the Docker-backed Phoenix operator demo easy to start, refresh, inspect, stop, and run alongside other local Docker projects without port or cache pain.

**Shipped:**
- **Canonical demo helper** — `bin/demo-up` is the helper-first entrypoint for the seeded `/audit` demo, with project name, credentials, URLs, lifecycle commands, readiness checks, and failure log guidance.
- **Local isolation** — Compose/Dockerfile behavior keeps ports localhost-bound, resources project-scoped, dependencies cache-friendly, PgBouncer opt-in, and rebuilds explicit through `--build`.
- **Lifecycle commands** — `--status`, `--logs`, `--down`, and `--fresh` operate against the same profile-aware Compose project.
- **Reader-first docs** — contributor/example docs explain shortest path, refresh/stop/reset, project-name/port behavior, cleanup, stale-code troubleshooting, and why `.dev` hostnames are rejected.
- **Opt-in friendly host** — shared-proxy mode supports `threadline.localhost` through the external `proxy` network while keeping `127.0.0.1:<port>` as the fallback.

**Archives:** `.planning/milestones/v1.34-ROADMAP.md`, `.planning/milestones/v1.34-REQUIREMENTS.md`

**Next milestone goals:** Hold until `$gsd-new-milestone` defines fresh requirements.

## Prior shipped milestone: v1.33 Brand Review + Direction Selection (2026-06-06)

**Goal (achieved):** Make the v1.32 `brandbook/` artifacts visible, reviewable, and decision-complete before any public README/GitHub/HexDocs/marketing rollout starts.

**Shipped:**
- **Review packet** — Phase 150 inventoried the HTML brandbook, logo assets, visual specimens, tokens, and copy guidance for human review.
- **Light-surface logo role** — `brandbook/logo-primary-light.svg` and usage guidance make README/GitHub/light documentation logo usage explicit.
- **Direction decision** — Phase 151 recorded targeted revisions as the selected path; alternate concepts, public rollout, and runtime UI changes remained out of scope.
- **Targeted cleanup** — Phase 152 rewrote brandbook-facing copy so the artifacts present current Threadline brand truth rather than process history.
- **Verification** — Phase 153 passed JSON/SVG/HTML parsing, direct-open browser, desktop/mobile screenshot, historical scan, binary-exclusion, inventory, and file-size checks.

**Archives:** `.planning/milestones/v1.33-ROADMAP.md`, `.planning/milestones/v1.33-REQUIREMENTS.md`, `.planning/milestones/v1.33-MILESTONE-AUDIT.md`, `.planning/milestones/v1.33-phases/`

**Next milestone goals:** Superseded by v1.34 Local Docker Admin UI DX. Public README rollout, HexDocs brand treatment, landing page, social-card PNG export, and legal/trademark review remain deferred.

## Prior shipped milestone: v1.32 Brand System Foundation (2026-06-05)

**Goal (achieved):** Produce a high-fidelity, source-control-ready Threadline brand system that is strategically pressure-tested, graphically credible, accessible, implementation-ready, and useful for future README/docs/marketing/UI work without changing runtime product UI or public docs in this milestone.

**Shipped:**
- **Process correction** — reverted the premature one-shot brandbook commit, then reopened the work through requirements, roadmap, phases, verification, and audit.
- **Brand source docs** — `brandbook/brand-book.md` and `brandbook/pressure-test.md` capture brand DNA, pressure-test scores, voice, microcopy, artifacts, and QA rules.
- **Source-controlled artifacts** — `brandbook/index.html`, JSON/CSS tokens, SVG logo system, social card, and useful visual specimens.
- **Verification** — JSON/SVG parse checks, browser desktop/mobile checks, image-load checks, contrast checks, file-size check, and binary-exclusion check.

**Archives:** `.planning/milestones/v1.32-ROADMAP.md`, `.planning/milestones/v1.32-REQUIREMENTS.md`, `.planning/milestones/v1.32-MILESTONE-AUDIT.md`

**Next milestone goals:** **Hold** until `$gsd-new-milestone` defines fresh requirements; candidate follow-ups are README/docs rollout, HexDocs theme, or marketing site only if explicitly selected.

## Prior shipped milestone: v1.31 Operator Surface: Insane Polish (2026-06-05)

**Goal (achieved):** A systematic second pass over the entire `/audit` operator surface (the adopter-mounted admin UI, not the demo app), bringing every screen to one consistent, brand-aligned, mobile-first baseline on a hardened BEM + `--tl-*` token design system.

**Shipped:**
- **Baseline evidence and seed enrichment** — Phase 134/135 evidence plus Phase 144 errata close the screenshot audit, state matrix, seed recipes, and persona/IA decisions.
- **Design-system hardening** — Phase 136 plus Phase 144 source-first catalog/freeze work locks the `.tl-*` class catalog, `--tl-*` token contract, operation primitives, and dark-only brand constraints.
- **Operator-surface polish** — Phases 137-139 bring Prove, Find, Home, and grouped navigation to the same primitive and responsive baseline.
- **Earned flows** — Phase 140 ships record-first lookup, correlation paste/deep-link, first-class row history, and Timeline/Evidence export carry-forward.
- **Motion, responsive, accessibility, and regression guard** — Phases 141-143 verify motion governance, 375/768/1280 responsive behavior, accessibility primitives, screenshot diff, and screenshot-regression guard.

**Archives:** `.planning/milestones/v1.31-ROADMAP.md`, `.planning/milestones/v1.31-REQUIREMENTS.md`, `.planning/milestones/v1.31-MILESTONE-AUDIT.md`

**Next milestone goals:** **Hold** until `$gsd-new-milestone` defines fresh requirements; v1.28 External Pilot remains signal-gated.

## Prior shipped milestone: v1.30 Adoption Evidence Automation (2026-05-29)

**Goal (achieved):** Close shift-left automation gaps on the existing help-desk demo journey (WALKTHROUGH §5, Track A golden path, minimal browser E2E) without new fiction or host STG pretense.

**Shipped:**
- **ConnCase §5 + walkthrough tighten** — ✓ Phase 131 (2026-05-29)
- **Playwright gap suite + CI job** — ✓ Phase 132 (2026-05-29)
- **Evaluator playbook + doc contracts** — ✓ Phase 133 (2026-05-29)

**Archives:** `.planning/milestones/v1.30-ROADMAP.md`, `.planning/milestones/v1.30-REQUIREMENTS.md`

**Next milestone (queued):** **Hold** — v1.28 External Pilot only on sustained real-adopter signal.

## Prior shipped milestone: v1.29 First-Hour Parity (2026-05-29)

**Goal (achieved):** Eliminate remaining adopter-facing first-hour footguns and close non-blocking verify/planning debt — without pretending to be a pilot or expanding product surface.

**Shipped:**
- **README + phx-gen-auth mount parity** — ✓ Phase 128 (2026-05-28)
- **WALKTHROUGH truth** — ✓ Phase 129 (2026-05-29): `mix threadline.verify_coverage` from example cwd; navigation-first row history; doc-contract locks
- **Verify/planning hygiene** — ✓ Phase 130 (2026-05-29): Nyquist 125 archived + finalized; SUMMARY frontmatter SSOT; NYQ-01 + PLAN-01 closed
- **Planning metadata hygiene** — ✓ Phase 130.1 (2026-05-29): ROADMAP/REQUIREMENTS authority aligned; Nyquist waivers for 128–129; audit tech debt closed

**Archives:** `.planning/milestones/v1.29-ROADMAP.md`, `.planning/milestones/v1.29-REQUIREMENTS.md`, `.planning/milestones/v1.29-MILESTONE-AUDIT.md`

<details>
<summary>v1.29 planning snapshot (archived)</summary>

**Assessment source:** `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`

</details>

## Prior shipped milestone: v1.27 Distribution & First-Hour Finish

**Goal (achieved):** Close the gap between "library is built in-repo" and "adopter can evaluate and wire the first hour from Hex and docs without maintainer context."

**Shipped:**
- **Hex 0.6.0 distribution truth** — Phase 122 (2026-05-28)
- **First-hour `ecto_repos` config** — Phase 123 (2026-05-28)
- **First-hour doc finish** — Phase 124: IEx-first §6, ADOPT-AUTH contract, `:schemas` reification docs, evidence host-write boundary, four-lane integration-contracts vocabulary
- **Example app `:schemas` demonstration** — Phase 127 (2026-05-28): runnable help-desk schema map on operator mount; integration + doc-contract proof for row-history sub-route (D-14)

**Next milestone (queued):** **Hold** after v1.29 — **v1.28 External Pilot** only on sustained real-adopter signal.

## Prior milestone context: v1.27 planning snapshot

<details>
<summary>v1.27 planning snapshot (archived)</summary>

**Goal:** Close the gap between "library is built in-repo" and "adopter can evaluate and wire the first hour from Hex and docs without maintainer context."

**Target features:**
- **Hex 0.6.0 distribution truth** — ✓ Phase 122 (2026-05-28)
- **First-hour `ecto_repos` config** — ✓ Phase 123 (2026-05-28)
- **First-hour doc finish** — ✓ Phase 124 (2026-05-28)
- **Gap closure** — ✓ Phases 125–127 (authority surfaces, Nyquist sign-off, `:schemas` example demo)

</details>

## Prior milestone shipped: v1.26 Auth Lane Breadth

**Goal (achieved):** Give Phoenix SaaS teams on `phx.gen.auth`-style session auth a first-party cookbook and CI-backed proof for `Threadline.Plug` and operator mount seams — without replacing the Sigra reference app or inventing Threadline-owned auth.

**Shipped:**
- `guides/integrations/phx-gen-auth.md` — host-owned `MyApp.AuditActor`, Plug order, admin `authorize_fn`, explicit non-goals (AUTH-GUIDE-01–03)
- **`phx-gen-auth-reference`** lane in `guides/upgrade-path.md` with four-lane matrix row and honest proof anchors (guide + root tests)
- Root `phx_gen_auth_integration_test.exs` — actor from `current_scope`, 1-arity admin gate, Plug smoke without Sigra (AUTH-PROOF-01–03)
- Getting-started §5/§6 auth-neutral first; README four-lane Start here; evaluator neutrality; doc-contract locks (ADOPT-AUTH-01–03)

**Next milestone (queued):** **Hold** (default) or optional **v1.29 First-Hour Parity** — **v1.28 External Pilot** only on sustained real-adopter signal; v1.22 DEFER trio only on procurement pressure.

## Shipped capabilities (cumulative)
- Mountable in-tree LiveView operator surface (`Threadline.OperatorSurface.Router`) with `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` declared `optional: true`; `Code.ensure_loaded?(Phoenix.LiveView)` gating keeps capture-only adopters Plug-only at install time.
- Shared `/audit` support-lane proof covers the mounted set the repo verifies today: timeline, actor, transaction, support-scoped row history / as-of, and export denial posture through host-owned seams; `mix threadline.incident <transaction_id>` ships transaction parity for no-LiveView operators.
- Mount-time auth contract: host-mount default + optional `:authorize_fn`, fail-closed at compile time unless the scope has `pipe_through`, `:authorize_fn` is supplied, or `:adopter_acknowledges_unauthenticated: true` is explicit; telemetry event `[:threadline, :operator_surface, :authorize]` with `:granted | :denied | :error`; `:authorize_fn` returned scopes are threaded into investigation queries.
- Raw timeline browse at `/audit` ships with full `Threadline.Query.timeline/2` filter parity, URL-as-state via `live_patch`, shared filter validation, and locked filter-vocabulary doc contracts.
- Operators can download the current timeline view as CSV / wrapped JSON / NDJSON with pre-flight match counts, RFC 5987 filenames, sync-or-chunked delivery based on row count, and byte-parity coverage against `mix threadline.export`.
- Read-only policy viewers ship for trigger coverage and redaction drift: `/audit/coverage`, `/audit/policy/redaction`, `mix threadline.health.coverage`, and `mix threadline.policy.show`.
- **(v1.22)** Append-only evidence records via `Threadline.Evidence` — six bounded subjects with stable provenance metadata and machine-readable detail payloads; no host business-policy meaning encoded.
- **(v1.22)** Three-tier proof vocabulary in `Threadline.Evidence.Proof` distinguishing proven facts, inferred posture, and unsupported claims — shared across library, Mix-task, and LiveView surfaces.
- **(v1.22)** Phoenix-optional library API plus Mix-task parity — **canonical:** `mix threadline.evidence.show` with stable JSON contract for CI / procurement / audit handoff.
- **(v1.22)** Mounted `/audit/evidence` LiveView with overview-first drill-down, URL-driven navigation, host-owned auth gate, and truthful mounted fallbacks — no new operator UI family, no Threadline-owned RBAC.
- Doc-contract test locks the macro signature, route literals, auth section, and v1.22 evidence-plane claim (`mix verify.doc_contract`); CHANGELOG, `guides/operator-surface.md`, `guides/how-threadline-works.md`, `guides/upgrade-path.md`, `guides/domain-reference.md`, README, production checklist, and the example app are aligned end-to-end.
- **(v1.26)** `guides/integrations/phx-gen-auth.md` and **`phx-gen-auth-reference`** upgrade-path lane — four-lane adopter self-identification (`capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference`); root integration tests prove Plug + `authorize_fn` without Sigra; first-hour docs treat Sigra as optional peer reference.

> **Evidence CLI errata:** `mix verify.evidence` was planned for early milestones but never shipped; runnable viewer is `mix threadline.evidence.show` only.

## Prior milestone shipped: v1.25 Adopter-Ready Release & First-Hour Truth

**Goal (achieved):** Make the shipped v1.22–v1.24 stack truthfully adoptable from Hex and remove first-hour doc/example friction — without compliance expansion or a second synthetic walkthrough.

**Shipped:**
- **threadline 0.6.0** — CHANGELOG, ExDoc Evidence group, `mix verify.release`, install-snippet SSOT `~> 0.6` across adopter surfaces
- Narrative docs center `Threadline.Audit.transaction/3` in `guides/how-threadline-works.md` with README/getting-started discovery alignment and doc-contract locks
- Example first-hour runbook — `:api` session plugs, Choose your path / Track A–B, Mix task ownership tables; `mix verify.example` green
- Evidence-plane doc authority — split-guide map (no phantom hub), semver-not-milestone adopter prose, `0.5.x → 0.6.x` upgrade bullet
- Evaluator one-pager at `guides/evaluating-threadline.md`; adoption-pilot verify ladder without stale test counts

**Archives:** `.planning/milestones/v1.25-ROADMAP.md`, `.planning/milestones/v1.25-REQUIREMENTS.md`, `.planning/milestones/v1.25-MILESTONE-AUDIT.md`

## Prior milestone shipped: v1.24 Audited Write Path & Adopter Truth

**Goal (achieved):** Package the manual audited-transaction recipe into a first-class library helper, adopt it in the reference app and getting-started guide, and repair reference/doc truth for 0.5.x evaluators — without compliance-platform expansion.

**Shipped:**
- `Threadline.Audit.transaction/3` — actor GUC + domain callback + optional `record_action/2` + `action_id` linkage in one call; PostgreSQL integration tests and doc contracts
- Example app primary write paths (`Blog`, `HelpDesk`, Oban touch) and `guides/getting-started-saas.md` adopt the helper; correlation/audit tests unchanged
- Adopter truth: `evidence_authorize_fn` on sigra-reference mount; adoption-pilot at **0.5.0** / `~> 0.5`; canonical `mix threadline.evidence.show` locked in doc contracts; WALK-03-02 prose fix (WR-110-001)

## Prior milestone shipped: v1.23 Realistic-Demo Walkthrough

**Goal (achieved):** Synthetic first-adopter walkthrough — realistic help-desk reference app, Sigra auth, demo seeds, maintainer runbook, observe-only dry-run, and triage of filed findings.

**Shipped:**
- Five-table help-desk domain in `examples/threadline_phoenix/` with capture, semantics, and operator-surface integration
- Sigra signup/login/session lane; `/audit` via `:operator_browser` + host authorize callbacks
- `mix demo.seed` / `mix demo.reset` with manifest-driven deterministic fiction and hero audit incidents
- `WALKTHROUGH.md` (§0–§5), findings template + classification protocol, Phase 109 dry-run, Phase 110 triage (0001–0003 fixed, RUN-01/02/03 pass on validation re-walk)
- Zero `lib/threadline/**` commits for inventory fixes; `mix ci.all` green at closeout

**Next milestone goals:** _(superseded by v1.24 — see later shipped milestone sections above)_

## Prior latest milestone: v1.22 Policy / Evidence Plane

**Goal (achieved):** Persist durable, append-only evidence records for Threadline-owned governance facts; expose them consistently through Phoenix-optional library APIs, Mix tasks, and a host-gated `/audit/evidence` LiveView; lock the narrow contract in docs and tests — without widening into a compliance platform, auth model, or tenancy model.

**Shipped:**
- Append-only evidence schema and `Threadline.Evidence` public context — six bounded subjects with stable provenance metadata, machine-readable detail payloads, and explicit non-goal language for host business policy.
- Three-tier proof vocabulary (`Threadline.Evidence.Proof`) distinguishing proven facts, inferred posture, and unsupported claims — same verdict language across library, Mix-task, and mounted LiveView surfaces.
- Phoenix-optional library API plus Mix-task parity — **canonical:** `mix threadline.evidence.show` with a stable JSON contract for CI, procurement, and audit handoff.
- Mounted `/audit/evidence` LiveView with overview-first drill-down, URL-driven navigation, host-owned auth gate, and truthful mounted fallbacks — no new operator UI family, no Threadline-owned RBAC.
- Public docs and contract tests lock the narrow evidence-plane claim and the explicit non-goals (no legal hold, no immutable-storage guarantee, no generic compliance pack, no Threadline-owned RBAC/tenancy DSL).
- Phase 99 named rerun bundle (`mix verify.doc_contract` + 5-file evidence-plane seam bundle + `mix verify.example`) locks the contract on the current tree; reran green at closeout (122 tests, 0 failures).
- Verification backfill chain (Phases 100/101/102) closed Phase 95/96/98 verification gaps with current-tree proof and finalized Nyquist validation artifacts.
- Authority surface reconciliation and milestone re-audit (Phase 103) flipped the v1.22 audit to `status: passed` with 12/12 requirements satisfied, `closeout_readiness: green`.

**Next milestone goals:**
- Apply real-adopter pressure on the evidence-plane contract before adding scope. v1.23 framing should start from feedback on the shipped narrow surface, not from speculative compliance-pack design.
- Re-evaluate DEFER-01 (compliance report packs), DEFER-02 (legal hold / approval flows), and DEFER-03 (immutable archive guarantees) only when concrete adopter pressure exists; do not preemptively expand the proof vocabulary.
- Preserve the host-owned auth/tenancy boundary that has held through v1.15 → v1.22.

**Post-close judgment (2026-05-27):**
- Shipping the narrow evidence-plane contract first (rather than a generic compliance pack) was the right move — the rerun bundle is now the authoritative source for the procurement / audit-of-audit claim, and future milestones can build on it instead of re-litigating it.
- The verification backfill pattern (Phases 100/101/102) is now repeatable shape for closing audit gaps without widening scope; capture this as a reusable closeout play.
- D-02 (archive vs. closeout-gate separation) and D-16 (`.planning/`-only boundary on closeout-gate phases) held cleanly through Phase 103 — bake into the standard closeout playbook.

## Prior milestone shipped: v1.21 Scoped Support / Operator Proof (Phases 85-94, 2026-05-25)

**Goal (achieved):** Turn the existing host-owned `scope_query_fn` seam into a truthful, first-party support-safe lane on the shipped `/audit` surface without widening Threadline into an auth, tenancy, or compliance platform.

**Shipped:**
- Narrowed the support-lane claim to the exact current-tree proof set: timeline, actor, transaction, support-scoped row history / as-of, and export denial posture through host-owned seams.
- Coverage and policy surfaces now stay explicit as admin/global or unsupported for support-scoped sessions, with denial and fallback UX aligned across LiveView, HTTP, docs, and tests.
- One canonical `/audit` mount recipe and the example Phoenix app prove admin + support personas honestly on the same host-owned route tree.
- Phases 90-94 backfilled the missing verification chain, refreshed the authority surfaces, and closed all 12 v1.21 requirements on rerun-backed current-tree evidence.

**Archives:** `.planning/milestones/v1.21-REQUIREMENTS.md`, `.planning/milestones/v1.21-ROADMAP.md`, `.planning/milestones/v1.21-MILESTONE-AUDIT.md`.

## Prior milestone shipped: v1.20 Scale and Governance Depth

**Goal (achieved):** Move Threadline from "capturing and reading" into governed lifecycle management: safe retention pruning, actor-owned saved views, background exports, and enterprise adapter seams, all while preserving the zero-intrusion default posture.

**Shipped:**
- Governance migrations plus `Threadline.Storage` and `Threadline.ExportQueue` behaviour seams for retention/export state and backend abstraction.
- Batched retention pruning with run tracking and a Retention History LiveView surface.
- Actor-owned saved views on the default operator mount path with session-first ownership semantics.
- Built-in background export runtime supervision, truthful lifecycle transitions, expiry cleanup, and actor-scoped status visibility.
- Backend-aware export delivery plus configured-path Oban/S3 integration proof and repaired public guidance.
- Repaired current-tree verification and Nyquist closeout artifacts for Phases 75-79 and 84 so the milestone evidence matches the shipped tree.

## Prior milestone shipped: v1.17 — Operator Surface Foundation (Phases 57-63, 2026-05-06)

**Goal (achieved):** Ship a host-usable operator surface — a mountable LiveView surface inside `threadline` (with Phoenix/LiveView as optional deps) that turns the v1.16 investigation contracts into one-click answers for the documented support questions, while preserving the v1.15 host-owns-auth boundary.

**Shipped:**
- **Phase 57** — SURF-02 / SURF-03: `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` declared `optional: true`; `Threadline.OperatorSurface` namespace module with file-scope `Code.ensure_loaded?(Phoenix.LiveView)` gating; `mix verify.compile_no_optional` alias + dedicated stable-id GitHub Actions job lock the regression-protection contract.
- **Phase 58** — SURF-01 / AUTH-01–05 / TELEM-01: `threadline_operator_surface` mount macro with optional `:actor_fn` / `:authorize_fn`; fails closed at compile time without a secure pipeline or explicit acknowledgement flag; `:adopter_acknowledges_unauthenticated: true` raises in test and emits a loud `Logger.warning` in prod; telemetry event `[:threadline, :operator_surface, :authorize]` with `:granted | :denied | :error`; `:authorize_fn`-returned scopes threaded into investigation queries.
- **Phases 59-61** — UI-01 / UI-02 / UI-03: incident drill-down LiveView at `/audit/transactions/:id` rendering `Threadline.incident_bundle/2`; actor window LiveView at `/audit/actors/:kind/:id` rendering `Threadline.actor_history/2` (with `ActorHistoryPage` keyset paging); row history sub-view at `/audit/rows/:table/:pk` rendering `Threadline.history/3` + `Threadline.as_of/4`, reachable from drill-down change rows.
- **Phase 62** — CLI-01 / SURF-04: `mix threadline.incident <transaction_id>` (with `--json`); `examples/threadline_phoenix` mounts the operator surface end-to-end behind a `phx.gen.auth`-style admin pipeline.
- **Phase 63** — DOC-01–04: `operator_surface_doc_contract_test.exs` locks macro signature, route literals, and auth section; `guides/operator-surface.md` covers mount, auth, screens, and the CLI task; README, production checklist, and example app README cross-link the new guide; CHANGELOG entry highlights the optional dependency posture and macro.

**Archives:** `.planning/milestones/v1.17-REQUIREMENTS.md`, `.planning/milestones/v1.17-ROADMAP.md`, `.planning/milestones/v1.17-MILESTONE-AUDIT.md`.

## Prior milestone shipped: v1.15 — Host Integration Completion (Phases 49-52, 2026-05-05)

**Goal (achieved):** Finish the remaining Phoenix host-integration gap so adopters get native request-context wiring, direct Sigra callback composition, and an authenticated incident drill-down baseline without inventing their own glue for the first serious host rollout.

**Shipped:**
- **Phase 49** — PLUG-01/02: native `Threadline.Plug` context overrides hook, additive-only precedence rules, deterministic invalid-shape failures, and aligned docs/tests.
- **Phase 50** — SIGRA-04/05: direct `Threadline.Integrations.Sigra` callback wiring through `Threadline.Plug`, example-app router adoption, and drift guards for the canonical callback pair.
- **Phase 51** — INCIDENT-03/04: authenticated incident drill-down baseline in the Phoenix example app plus incident docs that keep tenancy and richer authorization host-owned.
- **Phase 52** — ADOPT-03: getting-started, Sigra, README, domain-reference, incident-playbook, and adoption-backlog alignment with cross-doc contract coverage.

**Archives:** `.planning/milestones/v1.15-REQUIREMENTS.md`, `.planning/milestones/v1.15-ROADMAP.md`, `.planning/milestones/v1.15-MILESTONE-AUDIT.md`, `.planning/milestones/v1.15-phases/`.

## Prior milestone shipped: v1.14 — Drop-in Production Adopter Slice (Phases 44-48, 2026-05-05)
**Goal (achieved):** Make Threadline genuinely drop-in for a SaaS team running Phoenix + Sigra by closing the actor-mapping mile, publishing realistic operational evidence, shipping the incident playbook/replay path, and packaging the result as `threadline 0.3.0`.

**Shipped:**
- **Phase 44** — SIGRA-01/02/03: `Threadline.Integrations.Sigra`, example-app Sigra wiring, and `guides/integrations/sigra.md` with doc-contract coverage.
- **Phase 45** — PERF-01/02/03: reproducible `bench/` harness, tracked baseline artifacts, `mix verify.bench`, and `guides/performance.md`.
- **Phase 46** — INCIDENT-01/02: `guides/incident-playbook.md`, guarded incident replay script, and smoke/doc-contract coverage.
- **Phase 47** — ADOPT-01/02: SaaS quickstart, fixture-backed snippet extraction, and a maintainer-walked STG example with disclaimer/evidence guards.
- **Phase 48** — REL-01/02/03: `0.3.0` packaging surface, release artifact contract, ExDoc regrouping, and `mix verify.release`.

**Archives:** `.planning/milestones/v1.14-REQUIREMENTS.md`, `.planning/milestones/v1.14-ROADMAP.md`, `.planning/milestones/v1.14-MILESTONE-AUDIT.md`, `.planning/milestones/v1.14-phases/`.

## Prior milestone shipped: v1.13 — Docs Contract Repair (Phases 41–43, 2026-04-26)

**Goal (achieved):** Repair README contract drift on the root project and the Phoenix example so the published docs match the shipped public API surface, and restore the verification artifacts the milestone audit was missing.

**Shipped:**
- **Phase 41** — DOC-01: Root `README.md` aligned with the shipped public API surface; doc-contract test locks the literals.
- **Phase 42** — DOC-02: `examples/threadline_phoenix/README.md` and `examples/README.md` aligned with the runnable Phoenix reference app; doc-contract test extended to cover example install/runbook + historical reconstruction literals.
- **Phase 43** — DOC-03: `41-VERIFICATION.md`, `42-VERIFICATION.md`, and reconciled `v1.13-MILESTONE-AUDIT.md` close the audit evidence gap so DOC-01–03 are counted as verified.

**Archives:** `.planning/milestones/v1.13-REQUIREMENTS.md`, `.planning/milestones/v1.13-ROADMAP.md`, `.planning/milestones/v1.13-MILESTONE-AUDIT.md`, `.planning/milestones/v1.13-phases/`.

## Prior milestone shipped: v1.12 — Temporal Truth & Safety (Phases 38–40, 2026-04-25)

**Goal (achieved):** Provide a stable foundation for point-in-time row reconstruction with map-first reads, opt-in struct reification, and copy-pasteable operator docs.

**Shipped:**
- **Phase 38** — ASOF-01/02/05: snapshot-first `Threadline.as_of/4` with delete and genesis-gap handling.
- **Phase 39** — ASOF-03/04: opt-in struct reification with loose historical loading.
- **Phase 40** — ASOF-06: Time Travel operator docs and Phoenix example walkthrough.

**Archive:** `.planning/milestones/v1.12-REQUIREMENTS.md`, `.planning/milestones/v1.12-ROADMAP.md`.

## Last milestone shipped: v1.11 — Composable incident surface (Phase 37, 2026-04-24)

**Goal (achieved):** Close the integrator **composition** gap with a **two-step HTTP JSON** pattern in the reference Phoenix app: **`POST /api/posts`** returns **`audit_transaction_id`**, then **`GET /api/audit_transactions/:id/changes`** returns ordered changes plus **`change_diff`** maps.

**Shipped:**
- **Phase 37** — COMP-01/02/03: Example incident JSON path in `examples/threadline_phoenix`, `AuditTransactionController`, and `COMP-EXAMPLE-INCIDENT-JSON` doc contract.

## Last milestone shipped: v1.10 — Support-grade exploration primitives (Phases 31–36, 2026-04-24)

**Goal (achieved in-repo):** Turn shipped **capture + semantics + timeline/export** into faster **incident answers** with **small, explicit library APIs** — without new capture semantics or a UI framework.

**Shipped:**

- **Phase 31** — XPLO-01: **`Threadline.ChangeDiff`** + **`Threadline.change_diff/2`** — JSON-serializable field-level projection; documented INSERT/UPDATE/DELETE and `changed_from` absence.
- **Phase 32** — XPLO-02: **`Threadline.Query.audit_changes_for_transaction/2`** + **`Threadline.audit_changes_for_transaction/2`** — stable ordering for one transaction id.
- **Phase 33** — XPLO-03: **`## Exploration API routing (v1.10+)`** in **`guides/domain-reference.md`**, production-checklist cross-link, **`Threadline.ExplorationRoutingDocContractTest`**.

**Non-goals (unchanged):** LiveView operator UI; published **`threadline_web`**; new capture / redaction / retention **semantics**; maintainer-attested third-party STG URLs; **Hex** semver bump unless a **separate** release milestone says so.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** on Hex unchanged unless a release decision is made.

## Last milestone shipped: v1.9 — Production confidence at volume (Phases 28–30, 2026-04-24)

**Goal (achieved in-repo):** Credible **ops-at-volume** narrative for telemetry + **`Threadline.Health`**, a durable **audit indexing** cookbook, and **retention-at-scale** guidance grounded in shipped APIs — **docs-first**.

**Shipped:**

- **Phase 28** — OPS-01, OPS-02: per-event telemetry narrative + **`## Trigger coverage (operational)`** in **`guides/domain-reference.md`**; production checklist cross-links.
- **Phase 29** — IDX-01, IDX-02: **`guides/audit-indexing.md`**, ExDoc extra, doc contract **`test/threadline/audit_indexing_doc_contract_test.exs`**.
- **Phase 30** — SCALE-01, SCALE-02: **`guides/production-checklist.md`** volume / purge cadence H3 + export & support hooks; **`guides/domain-reference.md`** **`## Operating at scale (v1.9+)`** hub; **`README.md`** Maintainer-band discovery paragraph.

**Non-goals (unchanged):** LiveView operator UI; `threadline_web`; new capture/redaction semantics; Hex semver bump unless a separate release decision is made.

## Last milestone shipped: v1.8 — Close the support loop (Phases 25–27, 2026-04-24)

**Goal (achieved in-repo):** Faster **time-to-answer** in production support via shared **timeline + export** vocabulary, **correlation-aware** filtering, **copy-paste operator docs**, and an **example app** slice that proves the correlation path in CI.

**Shipped:**

- **Phase 25** — LOOP-01: `:correlation_id` on timeline/export with strict `audit_actions` join; validation + integration tests.
- **Phase 26** — LOOP-02, LOOP-04: Support incident queries in guides; doc contract anchors.
- **Phase 27** — LOOP-03: Example **`POST /api/posts`** records **`record_action`** in the audited transaction, links **`audit_transactions.action_id`**, **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`**, README correlation + **`export_json`** / **`jq`**.

**Archives:** `.planning/milestones/v1.8-REQUIREMENTS.md`, `.planning/milestones/v1.8-ROADMAP.md`. **Non-goals (unchanged):** LiveView operator UI; `threadline_web` / umbrella; new capture semantics; maintainer-attested third-party STG URLs.

## Last milestone shipped: v1.7 — Reference integration for SaaS (Phases 22–24, 2026-04-24)

**Goal (achieved in-repo):** Give teams a **runnable, minimal Phoenix integration** under **`examples/threadline_phoenix/`** that demonstrates capture and semantics on **HTTP and Oban job paths**, with **`record_action/2`** and cross-links to **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`** (STG rubric) — integrator-owned host evidence unchanged from v1.6.

**Shipped:**

- **Phase 22** — Path-dep example app, install + `gen.triggers` for `posts`, **`mix verify.example`** in **`mix ci.all`**, README runbook.
- **Phase 23** — **`Threadline.Plug`** on `:api` pipeline; **`Blog.create_post/2`** with transaction-local GUC; ConnCase audit path test.
- **Phase 24** — Oban **`PostTouchWorker`**, **`Blog.touch_post_for_job/2`** with **`Threadline.Job`** + **`record_action(:post_title_refreshed_from_queue, …)`**; README **Semantics in jobs** + adoption doc links.

**Archives:** `.planning/milestones/v1.7-REQUIREMENTS.md`, `.planning/milestones/v1.7-ROADMAP.md`.

**Non-goals (unchanged):** LiveView operator UI; new capture/redaction semantics; Hex semver bump unless a separate release decision is made; published `threadline_web` — example stays under **`examples/`**.

## Prior milestone shipped: v1.6 — Host staging / pooler parity (Phase 21, 2026-04-24)

**Goal (achieved in-repo):** Close the gap between **library CI** and **honest host documentation** using integrator-owned templates and evidence pointers — not maintainer attestation of third-party staging.

**Shipped (maintainer affordances):**

- **STG-01** — Fixed-field topology scaffold (`STG-HOST-TOPOLOGY-TEMPLATE`) in **`guides/adoption-pilot-backlog.md`** plus **partial** rationale guidance.
- **STG-02** — Audited HTTP/job path rubric (`STG-AUDITED-PATH-RUBRIC`) with **OK / Issue / N/A / Not run** and **Evidence / pointer** column.
- **STG-03** — Rubric rules (no OK without pointer; **N/A** vs **Not run**; CI vs host labeling); **CONTRIBUTING** `## Host STG evidence (integrators)`; production-checklist intro cross-link; doc contracts in **`test/threadline/ci_topology_contract_test.exs`** and **`test/threadline/stg_doc_contract_test.exs`**.

**Non-goals (unchanged):** New capture semantics, exploration API expansion, LiveView UI, or claiming external pilot environments the library does not control — see **Out of Scope** below and **Future** in **`.planning/milestones/v1.6-REQUIREMENTS.md`** (archived v1.6 scope).

## Shipped milestones

**v1.0** through **v1.13** are complete (**v1.13** shipped 2026-04-26, Phases 41–43). Prior milestones live under **`.planning/milestones/`**. **Living roadmap:** **`.planning/ROADMAP.md`**.

## Requirements

### Validated

- [x] **Microcopy and information architecture sweep (Phase 179)** — Added guard-first rendered copy contracts; relabeled shell/Home IA while preserving routes, atoms, ids, data-testids, and workflows; normalized shared state grammar, investigation/readiness pages, Timeline, Evidence/Exports, Redaction, Retention, and stress-route copy evidence. Requirements COPY-01, COPY-02, COPY-03. Validated in Phase 179 (2026-06-19).
- [x] **Primitive components (Phase 173)** — Extracted class-soup primitive and overlay/disclosure set into internal private function components, each audited in isolation with a full interaction-state matrix and correct a11y semantics. Requirements COMP-01, COMP-02, COMP-03. Validated in Phase 173 (2026-06-16).
- ✓ **Operator surface light mode (Phases 166–170)** — `theme: :dark | :light | :system` host config rendered server-side as `data-tl-theme` over a pure-CSS 45-token light lane (no JS/FOUC, CSP-proof); component retune of the ~9 dark-effect families + data-viz surfaces; light/system WCAG-AA contrast mirror with alpha-aware compositing; `__light__` screenshot lane + `theme:` docs; brand token parity + dual-mode pressure-test. 15/15 requirements (THEME-01–04, TOKEN-01–03, COMP-01/02, A11Y-01/02, EVID-01/02, BRAND-01/02). Validated in v1.36 (2026-06-14).
- [x] **Capture layer (Phase 1)** — Custom `Threadline.Capture` trigger SQL, `mix threadline.install` / `mix threadline.gen.triggers`, integration tests on PostgreSQL, GitHub Actions CI, CONTRIBUTING. Validated in Phase 1: Capture Foundation (2026-04-23).
- [x] **Semantics layer (Phase 2)** — `ActorRef`, `audit_actions` / nullable `audit_transactions.actor_ref`, `record_action/2`, `Threadline.Plug`, `Threadline.Job`, transaction-local GUC bridge for trigger-populated `actor_ref`. Validated in Phase 2: Semantics Layer (2026-04-23).
- [x] **Query + observability (Phase 3)** — `Threadline.Query`, delegators on `Threadline`, health coverage checks, telemetry hooks. Validated in Phase 3: Query & Observability (2026-04-23).
- [x] **Documentation + Hex readiness (Phase 4)** — root `README.md`, `guides/domain-reference.md`, `LICENSE`, `CHANGELOG.md`, ExDoc configuration, capture schema `@moduledoc`, `mix docs` / `mix hex.build` / `mix ci.all` green. Validated in Phase 4: Documentation & Release (2026-04-23).
- [x] **Canonical GitHub hosting (Phase 5)** — `origin` → `github.com/szTheory/threadline`, `@source_url` / package links / README CI badge aligned; `main` tracks `origin/main`; CI workflow monitors `main` only. Validated in Phase 5: Repository & remote (2026-04-22).
- [x] **CI signal on GitHub (Phases 6 & 8)** — `ci.yml` jobs green on `main` with maintainer-recorded proof (`06-VERIFICATION.md`); README / CONTRIBUTING document Actions. Validated in Phase 8: Publish main & verify CI (2026-04-23).
- [x] **Hex package `threadline` 0.1.0** — semver, dated changelog, `v0.1.0` on `origin`, publish to Hex. Validated in Phase 7–8 (2026-04-23).
- [x] **Before-values capture (Phase 9)** — nullable `audit_changes.changed_from`, opt-in per-table trigger SQL via `mix threadline.gen.triggers --store-changed-from`, `AuditChange.changed_from` and `Threadline.history/3` loading. Validated in Phase 9: Before-values capture (2026-04-23).
- [x] **Verify coverage & doc contracts (Phase 10)** — `mix threadline.verify_coverage`, `Threadline.Verify.CoveragePolicy`, CI `verify.threadline` / `verify.doc_contract`, README doc contract fixtures, CONTRIBUTING parity. Validated in Phase 10: Verify coverage & doc contracts (2026-04-23).
- [x] **Backfill / continuity (Phase 11)** — `Threadline.Continuity`, `mix threadline.continuity`, brownfield integration test, `guides/brownfield-continuity.md`, README and HexDocs discovery. Validated in Phase 11: Backfill / continuity (2026-04-23).
- [x] **Redaction at capture (Phase 12)** — `config :threadline, :trigger_capture`, `RedactionPolicy`, `TriggerSQL` exclude/mask, tests and operator docs. Validated in Phase 12 (2026-04-23).
- [x] **Retention + batched purge (Phase 13)** — `Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`, integration tests on PostgreSQL. Validated in Phase 13 (2026-04-23).
- [x] **Export (Phase 14)** — `Threadline.Export`, strict timeline filter validation, `mix threadline.export`, README + domain guide + ExDoc. Validated in Phase 14 (2026-04-23).
- [x] **Onboarding & README (Phase 15)** — `~> 0.2`, quickstart export, doc index links. Validated in Phase 15 (2026-04-23).
- [x] **Production checklist (Phase 16)** — `guides/production-checklist.md`. Validated in Phase 16 (2026-04-23).
- [x] **Timeline/export DX (Phase 17)** — `Threadline.Query.timeline_repo!/2`, validation order, tests. Validated in Phase 17 (2026-04-23).
- [x] **Release 0.2.0 packaging (Phase 18)** — `mix.exs` 0.2.0, CHANGELOG, ExDoc extras + retention in module groups. Validated in Phase 18 (2026-04-23).
- [x] **Adoption operator docs (Phase 19)** — `guides/adoption-pilot-backlog.md`, README + ExDoc extras, domain-reference telemetry operator table, production-checklist cross-links (ADOP-01, ADOP-02, TELEM-01, TELEM-02). Validated in Phase 19 (2026-04-23).
- [x] **ADOP-03 (Phase 20)** — Pilot backlog filled with **OK** / **N/A** + evidence; **AP-ENV.1** triaged to **STG-01**. Validated in Phase 20: First external pilot (maintainer CI evidence pass, 2026-04-23).
- [x] **STG-01 — STG-03 (Phase 21)** — In-repo topology template, audited-path rubric, CONTRIBUTING integrator workflow, production-checklist pointer, doc contract tests. Validated in Phase 21: Host staging & pooler parity (2026-04-24). Integrators still fill matrices with host-specific evidence via fork + PR.
- [x] **REF-01 / REF-02 (Phase 22)** — Canonical `examples/threadline_phoenix/` path-dep app, install + `gen.triggers` for `posts`, dedicated `threadline_phoenix_test`, `mix verify.example` in `ci.all`, CI + doc contracts. Validated in Phase 22: Example app layout & runbook (2026-04-24).
- [x] **REF-03 (Phase 23)** — `Threadline.Plug` on example `:api` pipeline; `Blog.create_post/2` with transaction-local GUC; ConnCase `posts_audit_path_test.exs` proves `audit_changes` + `AuditTransaction.actor_ref`. Validated in Phase 23: HTTP audited path (2026-04-24).
- [x] **REF-04 / REF-05 / REF-06 (Phase 24)** — Oban `PostTouchWorker` + `Blog.touch_post_for_job/2` with `Threadline.Job` and `record_action(:post_title_refreshed_from_queue, …)`; example README **Semantics in jobs** + links to **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`**. Validated in Phase 24: Job path, actions, adoption pointers (2026-04-24).
- [x] **LOOP-01 (Phase 25)** — Optional **`:correlation_id`** on **`Threadline.Query.timeline/2`**, **`timeline_query/1`**, **`export_changes_query/1`**, and **`Threadline.Export`**; strict `AuditAction` join when set; JSON **`action`** object and opt-in CSV **`include_action_metadata`**; integration tests + CHANGELOG. Validated in Phase 25: Correlation-aware timeline & export (2026-04-24).
- [x] **LOOP-02 / LOOP-04 (Phase 26)** — **`guides/domain-reference.md`** + **`guides/production-checklist.md`** **Support incident queries** (five questions, API vs SQL); marker **`LOOP-04-SUPPORT-INCIDENT-QUERIES`**; **`test/threadline/support_playbook_doc_contract_test.exs`**. Validated in Phase 26: Support playbooks & doc contracts (2026-04-24).
- [x] **LOOP-03 (Phase 27)** — **`examples/threadline_phoenix/`** correlation path: **`x-correlation-id`**, **`record_action/2`**, **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`**, README **`timeline`** / **`export_json`** with **`:correlation_id`**. Validated in Phase 27: Example app correlation path (2026-04-24).
- [x] **OPS-01 / OPS-02 (Phase 28)** — **`guides/domain-reference.md`** per-event telemetry narrative + **`## Trigger coverage (operational)`**; **`guides/production-checklist.md`** §1/§6 cross-links; README pointer to **`guides/domain-reference.md#trigger-coverage-operational`**. Validated in Phase 28: Telemetry & health operators' narrative (2026-04-24).
- [x] **IDX-01 / IDX-02 (Phase 29)** — **`guides/audit-indexing.md`** (installed defaults, access patterns vs **`Threadline.Query`** / **`Threadline.Export`** / **`Threadline.Retention`**, tradeoffs, optional DDL framed non-mandatory); ExDoc extra; cross-links from **`guides/domain-reference.md`** and **`guides/production-checklist.md`**; **`test/threadline/audit_indexing_doc_contract_test.exs`**. Validated in Phase 29: Audit table indexing cookbook (2026-04-24).
- [x] **SCALE-01 / SCALE-02 (Phase 30)** — **`guides/production-checklist.md`** volume / purge cadence H3 tied to **`Threadline.Retention.Policy`**, **`Threadline.Retention.purge/1`**, **`mix threadline.retention.purge`**; export §5 + support intro hooks; **`guides/domain-reference.md`** **`## Operating at scale (v1.9+)`** discovery hub; **`README.md`** Maintainer-band pointer. Validated in Phase 30: Retention at scale & discovery (2026-04-24).
- [x] **XPLO-01 (Phase 31)** — **`Threadline.ChangeDiff.from_audit_change/2`** (primary + `:export_compat`), ExDoc matrix for INSERT/UPDATE/DELETE and `before_values` / `prior_state`, **`test/threadline/change_diff_test.exs`**, **`Threadline.change_diff/2`**. Validated in Phase 31: Field-level change presentation (2026-04-24).
- [x] **XPLO-02 (Phase 32)** — **`Threadline.Query.audit_changes_for_transaction/2`**, **`Threadline.audit_changes_for_transaction/2`**, stable order via **`timeline_order/1`**, UUID validation + **`[]`** empty semantics, **`test/threadline/query_test.exs`**. Validated in Phase 32: Transaction-scoped change listing (2026-04-24).
- [x] **XPLO-03 (Phase 33)** — **`guides/domain-reference.md`** **Exploration API routing (v1.10+)**, production-checklist cross-link, **`Threadline.ExplorationRoutingDocContractTest`**. Validated in Phase 33: Operator docs & contracts (2026-04-24).
- [x] **COMP-01 / COMP-02 / COMP-03 (Phase 37)** — Example **`POST /api/posts`** returns **`audit_transaction_id`**; **`GET /api/audit_transactions/:id/changes`** lists changes with **`Threadline.change_diff/2`** maps; **`COMP-EXAMPLE-INCIDENT-JSON`** in **`guides/domain-reference.md`**; **`ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`**. Validated in Phase 37: Example incident JSON path (2026-04-24).
- [x] **ASOF-01 / ASOF-02 / ASOF-05 (Phase 38)** — Map-first reconstruction, deleted-record handling, and genesis-gap errors. Validated in v1.12: Core As-of Reconstruction.
- [x] **ASOF-03 / ASOF-04 (Phase 39)** — Opt-in struct reification and loose casting. Validated in v1.12: Reification & Schema Safety.
- [x] **ASOF-06 (Phase 40)** — Time Travel docs and example walkthrough. Validated in v1.12: Temporal Operator Guides.
- [x] **DOC-01 (Phase 41)** — Root `README.md` aligned with the shipped public API surface; locked by `test/threadline/readme_doc_contract_test.exs`. Validated in v1.13: Docs Contract Repair (2026-04-26).
- [x] **DOC-02 (Phase 42)** — `examples/threadline_phoenix/README.md` and `examples/README.md` aligned with the runnable Phoenix reference app; doc-contract test extended to assert the example surface. Validated in v1.13: Docs Contract Repair (2026-04-26).
- [x] **DOC-03 (Phases 41–42, audit closed in Phase 43)** — Doc-contract tests cover the README and example README literals; `41-VERIFICATION.md`, `42-VERIFICATION.md`, and `v1.13-MILESTONE-AUDIT.md` close the audit evidence gap. Validated in v1.13: Docs Contract Repair (2026-04-26).
- [x] **Investigation table stakes (Phases 53–56)** — `Threadline.timeline_page/2`, public investigation helpers, `Threadline.incident_bundle/2`, focused request-path coverage, and one canonical investigation docs story. Validated in v1.16: Investigation Table Stakes (2026-05-06).
- [x] **Operator Surface Foundation (Phases 57–63)** — Mountable in-tree LiveView with optional Phoenix/LiveView/HTML/PubSub deps, two must-have screens + row history sub-view, fail-closed mount-time auth contract with optional `:authorize_fn` and authorize telemetry, `mix threadline.incident` CLI parity, doc-contract test locking macro signature + route literals + auth section. Validated in v1.17 (2026-05-06).
- [x] **Policy / Evidence Plane (Phases 95–103)** — `Threadline.Evidence` append-only records with stable provenance and machine-readable detail; Phoenix-optional library APIs and Mix-task parity (**canonical:** `mix threadline.evidence.show`); `/audit/evidence` LiveView with host-owned auth gate; three-tier proof vocabulary (`Threadline.Evidence.Proof`); doc contracts lock the narrow claim and explicit non-goals (no legal hold, no immutable storage, no generic compliance pack, no Threadline-owned RBAC/tenancy DSL). Validated in v1.22: EVID-01/02/03, PROOF-01/02/03, SURF-01/02/03, DOC-01/02/03 (2026-05-27).
- [x] **DEMO (Phase 105)** — Help-desk domain in `examples/threadline_phoenix/`: five `binary_id` tables, `HelpDesk.ticket_replied_and_closed/6`, masked `internal_note_body` capture, triggers + `verify_coverage` green, DataCase audit proofs. Validated in Phase 105 (2026-05-27).
- [x] **CHARTER (Phase 104)** — v1.23 override Key Decision and non-goals locked in PROJECT.md and MILESTONE-ARC.md. Validated in v1.23 (2026-05-27).
- [x] **AUTH (Phase 106)** — Sigra signup/login/session in reference app; help-desk-aware `current_user`; `/audit` via `:operator_browser`. Validated in v1.23 (2026-05-27).
- [x] **SEED (Phase 107)** — `mix demo.seed` / `mix demo.reset` with deterministic three-org fiction and hero incidents. Validated in v1.23 (2026-05-27).
- [x] **WALK (Phase 108)** — `WALKTHROUGH.md` runbook and findings protocol. Validated in v1.23 (2026-05-27).
- [x] **RUN (Phase 109)** — Observe-only dry-run; findings captured for Phase 110. Validated in v1.23 (2026-05-27).
- [x] **FIX (Phase 110)** — Findings 0001–0003 fixed; zero v1.24 deferrals; validation re-walk pass. Validated in v1.23 (2026-05-27).
- [x] **AUDIT-TXN-01 / AUDIT-TXN-02 / AUDIT-TXN-03 / AUDIT-TXN-04 (Phase 111)** — `Threadline.Audit.transaction/3` with PostgreSQL integration tests and doc contracts. Validated in v1.24 (2026-05-27).
- [x] **ADOPT-HELPER-01 / ADOPT-HELPER-02 / ADOPT-HELPER-03 (Phase 112)** — Reference app + getting-started adopt helper; correlation-ready integration proof. Validated in v1.24 (2026-05-27).
- [x] **TRUTH-01 / TRUTH-02 / TRUTH-03 / TRUTH-04 / TRUTH-05 (Phase 113)** — `evidence_authorize_fn`, adoption-pilot 0.5.x, evidence CLI naming, WR-110-001 prose, verify gates green. Validated in v1.24 (2026-05-27).
- [x] **REL-01** through **REL-04 (Phase 114)** — 0.6.0 semver, CHANGELOG, ExDoc Evidence group, verify.release, install-snippet SSOT `~> 0.6`. Validated in v1.25 (2026-05-27).
- [x] **NARR-01** through **NARR-03 (Phase 115)** — `guides/how-threadline-works.md`, README, and getting-started aligned on `Audit.transaction/3` as blessed write path; doc-contract tests lock narrative literals and cross-doc discovery order. Validated in v1.25 (2026-05-27).
- [x] **EXAMPLE-01** through **EXAMPLE-04 (Phase 116)** — Example `:api` session plugs before `Threadline.Plug`; README Choose your path / Base install / Track A–B runbook; Mix task reference and ownership tables; doc-contract locks for auth staging and first-hour literals. Validated in v1.25 (2026-05-27).
- [x] **DOC-01** through **DOC-03 (Phase 117)** — Split-guide evidence map (no phantom hub); Hex semver in adopter guides; `0.5.x → 0.6.x` upgrade bullet; incident JSON blessed path; `mix verify.doc_contract` green with exploration_routing + semver_adopter contracts. Validated in v1.25 (2026-05-27).
- [x] **PILOT-01** / **PILOT-02 (Phase 118)** — Adoption-pilot verify ladder without stale test counts; `guides/evaluating-threadline.md` evaluator one-pager with host-owned boundaries and no STG attestation claims. Validated in v1.25 (2026-05-28).
- [x] **AUTH-GUIDE-01** through **AUTH-GUIDE-03 (Phase 119)** — `guides/integrations/phx-gen-auth.md` cookbook with host-owned `MyApp.AuditActor`, Plug order, admin mount, explicit non-goals. Validated in v1.26 (2026-05-28).
- [x] **AUTH-LANE-01** / **AUTH-LANE-02 (Phase 119–120)** — `phx-gen-auth-reference` upgrade-path lane with four-lane matrix row and honest proof anchors. Validated in v1.26 (2026-05-28).
- [x] **AUTH-PROOF-01** through **AUTH-PROOF-03 (Phase 120)** — Root `phx_gen_auth_integration_test.exs` proving Plug actor, 1-arity admin `authorize_fn`, smoke without Sigra. Validated in v1.26 (2026-05-28).
- [x] **ADOPT-AUTH-01** through **ADOPT-AUTH-03 (Phase 121)** — Getting-started §5/§6 auth-neutral first; README four-lane Start here; evaluator neutrality; doc-contract gates. Validated in v1.26 (2026-05-28).
- [x] **DIST-01** through **DIST-03 (Phase 122)** — hex.pm **0.6.0** published via `release.yml`; adoption-pilot Hex row OK; CHANGELOG four-lane upgrade bullet; conditional anti-stale doc contracts. Validated in Phase 122 (2026-05-28).
- [x] **CFG-01** through **CFG-03 (Phase 123)** — `ecto_repos` in getting-started §2 before install; doc-contract ordering lock; production-checklist prerequisite band cross-link. Validated in Phase 123 (2026-05-28).
- [x] **DOC-01** through **DOC-05 (Phase 124)** — IEx-first §6 auth-neutral staging; ADOPT-AUTH strict literals; `:schemas` mount for row history; evidence host-write boundary; integration-contracts four-lane vocabulary aligned with upgrade-path. Validated in Phase 124 (2026-05-28).
- [x] **README-01** / **README-02** / **TRIG-01 (Phase 128)** — README Quick Start `ecto_repos` before install; doc-contract locks; trigger SSOT cross-links. Validated in v1.29 (2026-05-28).
- [x] **AUTH-MOUNT-01** / **AUTH-MOUNT-02 (Phase 128)** — phx-gen-auth scope-first `authorize_fn` mount; integration proof and doc-contract locks. Validated in v1.29 (2026-05-28).
- [x] **WALK-01** / **WALK-02** / **WALK-03 (Phase 129)** — WALKTHROUGH verify cwd and row-history URL truth with doc-contract locks. Validated in v1.29 (2026-05-29).
- [x] **NYQ-01** / **PLAN-01 (Phase 130)** — `125-VALIDATION.md` Nyquist finalized; SUMMARY `requirements-completed` SSOT and v1.27 GAP backfill. Validated in v1.29 (2026-05-29).
- [x] **POLISH-AUDIT (Phase 144 close-gap)** — Phase 144 errata verifies the Phase 134-labeled baseline audit, baseline/final screenshot inventories, and closure artifacts without fabricating a Phase 134 ledger. Validated in v1.31 close-gap audit (2026-06-04).
- [x] **POLISH-DS (Phase 144 close-gap)** — Operation primitive consolidation, `v1.31-DESIGN-SYSTEM.md`, source freeze marker, and style contract tests close the design-system catalog/freeze requirement. Validated in v1.31 close-gap audit (2026-06-04).
- [x] **v1.37 Operator Surface Design-System Stress Test & Component System** — DS, COMP, NAV, DATA, GROUP, PAGE, COPY, A11Y, and MOTION requirements all complete. Archives: `.planning/milestones/v1.37-REQUIREMENTS.md`, `.planning/milestones/v1.37-ROADMAP.md`, `.planning/milestones/v1.37-MILESTONE-AUDIT.md`. Validated in v1.37 closeout (2026-06-20).
- [x] **BASE-01 through BASE-03 (Phase 181)** — Established current rendered `/audit` evidence, refreshed the UI issue inventory, repaired stale guardrails, preserved the v1.37 ratchet, and classified remaining full-suite residuals. Validated in Phase 181 (2026-06-26).
- [x] **STORY-01 through STORY-03 (Phase 182)** — Added PhoenixStorybook only to the Phoenix example app as dev/test maintainer component documentation; preserved the root package boundary, production route absence, private component API posture, and `/audit/__stress` as the authenticated operator-flow stress harness. Validated in Phase 182 (2026-06-27).

### Active

- [x] **SHELL-01 through SHELL-03 (Phase 183)** — Reworked operator shell, home orientation, navigation visibility, active/current state, and mobile IA around user jobs.
- [ ] **TIME-01 through TIME-03 (Phase 184)** — Streamline Timeline filters, investigation flow, result states, copy, and responsive scanning behavior.
- [ ] **COV-01 through COV-03 (Phase 185)** — Clean up Coverage as an audit-readiness workflow with clear schema scope, duplicate remediation, and contextual Timeline affordances.
- [ ] **DETAIL-01 and GOV-01 through GOV-03 (Phase 186)** — Review transaction, actor, row history, redaction, retention, evidence, and export surfaces for coherent task groups and risk-aware actions.
- [ ] **A11Y-01, A11Y-02, MOTION-01, DOC-01, CLOSE-01 (Phase 187)** — Lock accessibility, motion, docs, visual QA, and adversarial closeout evidence.

### Out of Scope

- **SIEM / security information and event management** — different product category, different buyers, different infrastructure
- **Full event sourcing / CQRS** — Threadline captures audit facts; it does not drive application state reconstruction
- **pgAudit replacement** — statement-level DB auditing is a separate concern; Threadline is application-level
- **Data warehouse / CDC pipeline** — WAL/logical replication adds operational surface area (PgBouncer hazards, cloud caveats, cannot be reverted) that is not worth the tradeoff for v0.x
- **Hard LiveView / Phoenix dependency in `threadline` core** — out of scope. The v1.17 operator surface is gated on `phoenix_live_view` as an optional dep so capture-only adopters retain a Plug-only install footprint.
- **Multi-tenant / prefix-scoped capture beyond Ecto prefix support** — defer until basic capture is validated
- **Forced `threadline_web` extraction before version-pressure exists** — out of scope for v1.19. The milestone should define objective extraction triggers first; a package split only makes sense once real adopters create version-matrix or release-cadence pressure.
- **Automated Hex publish from CI** — tag-triggered workflow exists; interactive `mix hex.publish` remains the documented maintainer path for early releases
- **Elixir/OTP version bumps in CI** — unless required for runner or dependency breakage

## Context

**Ecosystem gap:** Carbonite (v0.16.x) is the strongest trigger-backed capture substrate in the Elixir ecosystem but is a library, not a platform — it handles what changed but not who did it or why. PaperTrail and ExAudit fill the action-semantics gap but sacrifice correctness (miss direct Repo/SQL writes). No existing library combines both with operator tooling.

**Key prior-art lessons:**
- Logidze: metadata via connection-local variables misbehaves with PgBouncer if transactions are skipped — Threadline must document this and provide safe propagation patterns
- ExAudit: ETS/PID-scoped context ages poorly in async contexts; avoid process-local context stores
- Ruby Audited: YAML storage caused years of upgrade pain — JSONB with typed columns is the answer
- Ruby PaperTrail: association tracking complexity bloated the core — keep association tracking out of v0.1

**Engineering baseline:** The project follows the same OSS quality bar as sibling libraries (Scrypath, Sigra): `mix verify.*` / `mix ci.*` entrypoints, doc contract tests once public docs exist, stable GitHub Actions job IDs, release automation aligned to Hex publishing workflow.

**Evidence plane posture (2026-05-28):** `Threadline.Evidence` read/write API, Mix-task, and `/audit/evidence` LiveView are shipped; records are **host-written** — lib/ does not auto-populate from retention, health, or export paths. Adopter docs set this expectation explicitly (v1.27 DOC-04).

**First-hour config (2026-05-28):** `config :threadline, ecto_repos: [MyApp.Repo]` documented in getting-started §2 and production-checklist; doc-contract locked (v1.27 CFG-01–03).

**Hex distribution (2026-05-28):** **threadline 0.6.0** published on hex.pm; adoption-pilot and evaluator surfaces honest about version (v1.27 DIST-01–03).

**Path-to-done posture (2026-05-29):** **~92–95% done** for stated narrow audit-platform scope. v1.29 closed remaining first-hour doc footguns and verify/planning hygiene. **Default hold** — no adopter signal today; v1.28 only on sustained signal. Assessment: `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`; roadmap: `.planning/MILESTONE-ARC.md` § Path to done.

**Capture mechanism (closed):** Path B — custom `Threadline.Capture.TriggerSQL` with transaction-row grouping (`txid_current()`), no `SET LOCAL` in the capture path. Formal decision: `.planning/milestones/v1.0-phases/01-capture-foundation/gate-01-01.md` (archived with v1.0).

## Constraints

- **Tech stack**: Elixir ≥ 1.15 / OTP ≥ 26 / PostgreSQL ≥ 14 / Ecto 3.x — align with active Phoenix LTS baseline
- **SQL-native**: no Erlang binary or opaque blob storage; all audit data must be introspectable with plain SQL
- **Correct by default**: capture must not depend on developers remembering to call library functions on every write path
- **OSS quality bar**: named `mix verify.*` / `mix ci.*` entrypoints; honest `mix test` (no silent exclusions); stable GitHub Actions job IDs
- **Capture mechanism**: Path B (custom triggers) — see archived gate-01-01.md; PgBouncer transaction-mode safe
- **No WAL/CDC as primary backend**: logical replication adds operational surface area incompatible with Threadline's "batteries-included" promise at v0.x

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Trigger-backed capture (not application-hook-based) | Harder to bypass than PaperTrail-style opt-in; correctness is the core value | ✓ Validated (Phase 1) |
| Carbonite vs custom (Phase 1 gate) | Carbonite metadata path uses patterns incompatible with D-06; Threadline needs D-05 schema | ✓ Path B: custom `TriggerSQL` (see archived gate-01-01.md) |
| Separate capture vs. semantics models | Actions ≠ changes; transactions ≠ requests; collapsing them is how prior art created gaps | ✓ Good (design principle) |
| JSONB + typed columns, no binary formats | Avoids YAML/Erlang-term upgrade pain documented in Audited and ExAudit | ✓ Good (design principle) |
| Single package `threadline` to start | Avoid premature umbrella/companion split before API is known; revisit after v0.1 | ✓ **0.1.0** shipped on Hex (v1.1) |
| No LiveView UI in v0.1 | Exploration layer matures after capture + semantics prove out | ✓ Good |
| v1.7 reference app under `examples/` | Runnable SaaS-shaped integration without publishing a companion Hex package | ✓ Shipped (Phases 22–24, 2026-04-24) |
| `ChangeDiff` normalizes trigger `op` casing | Lowercase `op` from PostgreSQL trigger paths maps to uppercase INSERT/UPDATE/DELETE in the primary wire map | ✓ Shipped (Phase 34, v1.10) |
| `as_of/4` map-first reconstruction and cast-based reification | Point-in-time reads now support explicit deleted/genesis errors plus opt-in struct loading | ✓ Shipped (Phases 38–40, v1.12) |
| Treat README docs drift as a first-class milestone | README literals are public API; doc-contract tests must lock them so future drift fails CI instead of silently shipping | ✓ Shipped (Phases 41–43, v1.13) |
| Verification artifacts are first-class milestone output | Phase 43 retroactively wrote `*-VERIFICATION.md` to close an audit gap; future phases should land verification evidence alongside SUMMARY.md, not after | ✓ Shipped (Phase 43, v1.13) |
| Investigation workflows before UI breadth | The library already captures and correlates rich audit data, but adopters still need packaged answers to the first support questions before a UI or new adapter layer will feel durable | ✓ Shipped in v1.16 |
| Persist a standing milestone arc in `.planning/MILESTONE-ARC.md` | Future milestone starts should begin from a recorded strategic recommendation, not from memory or a fresh prompt | ✓ Shipped in v1.16 |
| v1.17 operator surface ships in-tree with optional Phoenix/LiveView deps, not as a separate `threadline_web` package | Splitting at v0.3.0 with one maintainer is premature: doubles the release/version-matrix burden when the surface is still small. LiveDashboard / Oban Web / Ash Admin all split *after* the core had hundreds of adopters; Sentry-Elixir keeps Phoenix integrations optional in-tree without a companion. Keeps capture-only adopters Plug-only via `optional: true` deps gated by `Code.ensure_loaded?(Phoenix.LiveView)`. | ✓ Shipped (Phases 57–63, v1.17) |
| Operator surface defaults to host-mounted with optional `:authorize_fn` callback and fails closed at compile time | Pure host-mount (LiveDashboard / Sidekiq Web pattern) leaks the surface when adopters forget the pipeline. Pure callback walks back from v1.15's "host owns auth, Threadline owns the wiring contract." Hangfire's fail-closed default + Oban Web's resolver shape gives the most conservative posture for an audit-trail surface, which is the highest-stakes leak target in the ecosystem. | ✓ Shipped (Phases 57–63, v1.17) |
| v1.18 ships the raw timeline browse with full `Threadline.Query.timeline/2` filter parity (no narrow starter, no saved views) | Narrow starter creates a UI/API filter divergence — operators learn two filter dialects, doc-contract tests have to track both, the CloudTrail/Kibana trajectory of "ship a subset, bolt on the rest later" is well-documented. Saved views drag a tiny new auth model (owner / visibility / sharing) into a lib that has stayed auth-agnostic since v1.15; URL-as-state via `live_patch` + browser bookmarks cover the persistence story for free, which is what GitHub audit log and Oban Web do at scale. Five filters is well below the threshold where saved views become necessary. | ✓ Shipped in v1.18 |
| v1.18 ships exports UI as "download current view" only (sync `iodata` for small windows, chunked stream for large), not queued/Oban-backed | Adding Oban as a hard dep walks back the v1.17 optional-deps win, and storage adapters / file expiry / status pages are platform creep that contradicts "lib not platform." Sidekiq Pro hit memory pain on in-process CSV before adding streaming; Backpex / Linear / GitHub-style sync downloads are the right ceiling at our stage. Queued-with-link-when-ready is what large products (CloudTrail, Sentry, GitHub audit-log) ship after sync hits a wall — Threadline hasn't hit that wall, so the design would be speculative. Revisit in v1.20 once real adopters report row-cap pain on real incidents. | ✓ Shipped in v1.18 |
| v1.18 ships read-only policy admin viewers (coverage dashboard + drift-aware redaction admin); retention admin deferred to v1.19 | Coverage has zero drift risk and the highest operational value (covers the most expensive Threadline failure mode — uncaptured tables) over already-shipped `Threadline.Health.trigger_coverage/1`. Drift-aware redaction admin reconciles `config :threadline, :trigger_capture` against `pg_proc.prosrc`-derived deployed redaction so a config edit without `gen.triggers` rerun cannot silently mislead operators (the Logidze/Carbonite-class footgun). Retention admin's "last purge" requires net-new `audit_retention_runs` capture machinery (`purge/1` writes), which broadens the milestone rather than hardens it; revisit when the capture surface is decided. Read-only ceiling preserves the v1.15 host-owns-auth boundary and avoids the "Purge now" / runtime-policy-edit compliance vector. | ✓ Shipped in v1.18 |
| v1.19 focuses on integration breadth and extraction readiness, not deeper operator product scope | The next leverage point is reducing host-specific glue and tightening proven compatibility claims. Saved views, retention admin capture machinery, queued exports, and mutable policy UI all add product surface or infrastructure without making adoption easier across hosts. `threadline_web` should remain a measured future decision unless real adopter pressure proves otherwise. | — Active (opened 2026-05-07) |
| v1.21 will productize the mount contract, not the auth model | The strongest remaining adoption gap was a truthful scoped support lane on `/audit`. The current tree now proves one host-owned path end to end, and Phase 94 closed the authority and audit surfaces around that proof without inventing RBAC or tenancy DSLs. | ✓ Ready for closeout (2026-05-25) |
| v1.22 will ship a narrow evidence plane, not a compliance platform | The next leverage point is durable proof for policy/governance posture. Append-only evidence records, API/CLI parity, and read-only `/audit` evidence views strengthen enterprise credibility without crossing the host-owned auth/tenancy boundary. | ✓ Shipped (Phases 95-103, v1.22, 2026-05-27) |
| Three-tier proof vocabulary (`proven`, `inferred`, `unsupported`) lives in `Threadline.Evidence.Proof` and is shared across library, Mix, and LiveView surfaces | Procurement and audit-of-audit asks require honest claim language, not just data. Splitting the verdict into proven facts vs. inferred posture vs. explicit unsupported claims kept the contract narrow while still being useful — and prevented the "everything is a proven compliance fact" drift other audit libraries fall into. | ✓ Shipped (Phase 97, v1.22, 2026-05-27) |
| Mounted `/audit/evidence` reuses the existing `/audit` surface and host-owned auth gate; no new operator UI family or Threadline-owned RBAC | Pure read-only views with overview-first drill-down and URL-driven navigation match the support-lane shape established in v1.21, so adopters get one consistent operator vocabulary. A new UI family would have reopened auth scope. | ✓ Shipped (Phase 98, v1.22, 2026-05-27) |
| Verification backfill phases (Phases 100/101/102) are the right pattern for closing audit gaps without widening milestone scope | When a milestone audit surfaces gaps in already-shipped phases, inserting narrow verification-only phases (`.planning/`-only, no doc/code/test edits, named rerun bundle as proof) closes the loop without re-litigating the underlying work. Phase 103 then reconciles the authority surfaces and reruns the audit on the reconciled tree. Reusable closeout play. | ✓ Validated (Phases 100-103, v1.22, 2026-05-27) |
| D-02 archive/closeout-gate separation and D-16 `.planning/`-only boundary held cleanly through Phase 103 | The archive step (`/gsd-complete-milestone`) owns MILESTONE-ARC, PROJECT "Last shipped", MILESTONES, RETROSPECTIVE, and `.planning/milestones/v*` archives. The closeout-gate phase is the proof step, not the archive step. Keeping these separated avoids the "audit closed itself" anti-pattern. | ✓ Validated (Phase 103, v1.22, 2026-05-27) |
| v1.23 deliberately overrides v1.22's "real-adopter feedback first" closeout rule and ships a synthetic-first-adopter walkthrough instead | No real adopter exists at v1.22 close, and the alternative is shipping nothing — a maintainer walking the reference app on a clean clone is the strongest available signal until external pressure arrives. Override scoped to v1.23 only and does not extend evidence subjects, Threadline-owned RBAC/tenancy DSLs, or `lib/` auth code. **Re-engages the v1.22 rule on first sustained real-adopter signal** (live-integration issue, maintainer-confirmed pilot host, or named procurement/security-review/evaluation conversation); drive-by interest routes to `.planning/v1.24-seeds/` rather than re-engaging the rule. | ✓ Shipped (v1.23, 2026-05-27) |
| v1.24 prioritizes audited write-path ergonomics over compliance expansion | Milestone-next-step assessment (~83% done for stated scope): capture+semantics+operator stack is strong; #1 remaining foot-gun is manual transaction recipe for actor GUC + `record_action` + `action_id`. No sustained adopter signal — proceed with helper + reference/doc truth, not DEFER-01/02/03 or another walkthrough. | ✓ Shipped (Phases 111-113, v1.24, 2026-05-27) |
| `Threadline.Audit.transaction/3` is the recommended audited write path | Single helper replaces copy-pasted GUC + `record_action` + `action_id` recipe; reference app and guides prove correlation-ready timelines without weakened tests. | ✓ Shipped (Phases 111-112, v1.24, 2026-05-27) |
| Adopter truth for 0.5.x evaluators lives in example mount + doc contracts | `evidence_authorize_fn`, adoption-pilot version SSOT, canonical evidence CLI, and walkthrough prose aligned to seed fiction — no new Evidence subjects. | ✓ Shipped (Phase 113, v1.24, 2026-05-27) |
| Post-v1.24 assessment prioritizes release truth + first-hour friction over compliance expansion | Repo-grounded done band ~88–92% for stated narrow scope; Hex 0.5.0 lags v1.22–v1.24 stack; largest remaining synthetic wedge is 0.6.0 + narrative doc sync + example README fixes — not DEFER trio without adopter signal. phx.gen.auth breadth queued as v1.26. | ✓ Shipped (v1.25, 2026-05-28) |
| v1.25 ships 0.6.0 + first-hour truth without compliance expansion | Release packaging, narrative/example alignment, evidence-plane doc authority, and optional evaluator one-pager close the synthetic adopter wedge; Nyquist gaps on 115/117/118 are non-blocking tech debt. | ✓ Shipped (Phases 114-118, v1.25, 2026-05-28) |
| v1.26 auth lane breadth closes phx.gen.auth reach without second reference app | Guide + root CI proof pattern beats runnable second example; four-lane matrix complete; Sigra remains optional peer reference. | ✓ Shipped (Phases 119-121, v1.26, 2026-05-28) |
| v1.27 targets distribution + first-hour finish, not external pilot without signal | Post-v1.26 assessment ~90–93% done for stated scope; Hex 0.5/0.6 drift and `ecto_repos` getting-started gap are adopter-facing blockers; external pilot moves to v1.28 on re-engagement trigger. | ✓ Shipped (Phases 122-127, v1.27, 2026-05-28) |
| Post-v1.27 path-to-done: hold default at ~92%; optional v1.29 hygiene; v1.28 signal-gated | Repo inspection confirms core lib shipped, Hex 0.6.0 aligned, getting-started spine complete; remaining footguns are README Quick Start `ecto_repos`, phx-gen-auth mount snippet, WALKTHROUGH cwd/URL — polish not engine. No adopter signal — do not open synthetic product milestones beyond optional thin v1.29. | ✓ Shipped (v1.29, 2026-05-29) |
| v1.29 is the last optional synthetic hygiene pass before hold | First-hour doc parity + Nyquist 125 + WALKTHROUGH truth close adopter-facing footguns without pilot pretense or product expansion. | ✓ Shipped (Phases 128–130.1, v1.29, 2026-05-29) |
| README/GitHub is the deciding surface for brand readiness | The brand can support future landing pages and HexDocs, but OSS adopter trust starts in the repository. Light-surface logo usability is therefore a real requirement, while public rollout remains separate work. | ✓ Shipped (v1.33, 2026-06-06) |
| Brandbook artifacts should present current brand truth, not process history | Planning history belongs in `.planning/`; public-facing source artifacts should read as settled guidance unless a future milestone deliberately reopens the direction. | ✓ Shipped (v1.33, 2026-06-06) |
| v1.34 uses helper-first dynamic localhost ports, not Traefik, for local demo access | `bin/demo-up` gives the best one-command DX without a shared reverse-proxy dependency, Docker socket exposure, port 80/443 ownership, mkcert state, or cross-project naming policy. Traefik can be reconsidered later as an optional shared-proxy integration using `.localhost`, not `.dev`. | — Active (v1.34, 2026-06-06) |
| [165-01] supersedes dark-only [136-01]: dark default, light/system via host `theme:` config, no runtime toggle in v1 | Dark stays the brand and the default (zero adopter behavior change); light/system are real needs met by host configuration, not a runtime UI. The `theme-toggle` ban is retained; a cookie-based upgrade path is documented, not built. | ✓ Validated (v1.36, 2026-06-14) |
| Light theme renders server-side as `data-tl-theme`, pure CSS — no JS, no localStorage, no `<head>` injection | A mounted library must be correct on the dead render (zero FOUC) and survive CSP; localStorage/`<head>`-script theming is structurally wrong for this surface (rejected in 165 research). | ✓ Good (v1.36) |
| Light tokens designed, not recolored; status tints redesigned as one coherent decision | Mechanically inverting dark values produces the "Grafana lesson" — dark-tuned content shipped unreviewed into light. Data-viz-adjacent surfaces got an explicit light review. | ✓ Good (v1.36) |
| Source-first contract: `style.ex` + `style_contract_test.exs` amended in the same wave | The style contract reads `style.ex` directly; amending both together keeps the seven light refutes → theme-aware assertions atomic and the dark phase-143 contract byte-stable. | ✓ Good (v1.36) |
| Entangled `style.ex` light source committed at v1.36 close (resolves audit Finding F1) | COMP-01/02 were built and verified live but their source sat uncommitted in a broader operator-surface working tree; committing it at close (commit `b9f8fc1`, suite green at 912 tests) made the parity gate green on a clean checkout. | ✓ Resolved (v1.36, 2026-06-14) |
| v1.38 scopes PhoenixStorybook to the Phoenix example/dev lane | Storybook is valuable for component/state review, but making it a root dependency or public component API would violate the optional-Phoenix and host-app-friendly library boundary. `/audit/__stress` remains the canonical operator-flow stress harness. | — Active (v1.38, 2026-06-26) |
| v1.38 cleans pages in operator-value order: shell/home/timeline, then coverage, then detail/governance/export | The current user pain is orientation and task flow, not missing primitives. Starting with shell/home/timeline fixes the common path and creates patterns that later pages can adopt without re-litigating the design language. | — Active (v1.38, 2026-06-26) |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (e.g. GSD `phase.complete` / roadmap update after `/gsd-execute-phase` when applicable):

1. Requirements invalidated? → Move to Out of Scope with reason  
2. Requirements validated? → Move to Validated with phase reference  
3. New requirements emerged? → Add to Active  
4. Decisions to log? → Add to Key Decisions  
5. "What This Is" still accurate? → Update if drifted  

**After each milestone** (via `/gsd-complete-milestone`):

1. Full review of all sections  
2. Core Value check — still the right priority?  
3. Audit Out of Scope — reasons still valid?  
4. Update Context with current state  

---
*Last updated: 2026-06-28 — Phase 183 shell navigation and Home orientation complete; Phase 184 Timeline investigation flow is next*
