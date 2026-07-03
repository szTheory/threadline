# Roadmap: Threadline

## Milestones

- 🚧 **v1.40 Automated Operator-UI Critique & Forward-Only Iteration Harness** - Phases 194-197 (in progress, opened 2026-07-02)
- [x] **v1.39 Quality Baseline, Schema Confidence, and CI Efficiency** - Phases 189-193 (shipped 2026-07-03). Archive: `.planning/milestones/v1.39-ROADMAP.md`
- [x] **v1.38 Operator UI Page-by-Page IA & Design-System Polish** - Phases 181-188 (shipped 2026-06-30). Archive: `.planning/milestones/v1.38-ROADMAP.md`
- [x] **v1.37 Operator Surface Design-System Stress Test & Component System** - Phases 171-180 (shipped 2026-06-20). Archive: `.planning/milestones/v1.37-ROADMAP.md`
- [x] **v1.36 Operator Surface Light Mode** - Phases 166-170 (shipped 2026-06-14). Archive: `.planning/milestones/v1.36-ROADMAP.md`
- [x] **v1.35 Unified Logo & Brand Book v2** - Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- [x] **v1.34 Local Docker Admin UI DX** - Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`

## 🚧 v1.40 Automated Operator-UI Critique & Forward-Only Iteration Harness (In Progress)

**Milestone Goal:** Make evaluating and improving the `/audit` operator UI fast and *monotonic* — an adversarial multi-lens critic panel (per-persona/JTBD + graphic-design + brand veto) over deterministic capture, feeding the existing design-system ledger's ratchet so award-winning, on-brand, Linear-grade improvements land and regressions are blocked — with far less human review time. ~80% integration on shipped substrate (ledger + `stress_ledger_test.exs` ratchet, `/audit/__stress`, Playwright dark/light lanes, a11y evidence, `style.ex` tokens, brand pressure-test, locked personas P1–P5); new work = the scorecard cube, one critic runner, and the net-positive gate.

**Dependency spine (non-negotiable):** the deterministic ledger/scorecard cube (Phase 194) must precede any nondeterministic score producer, and critic **validation & golden set (Phase 195) must land before the forward-only automated ratchet/gate (Phase 196)** — an un-validated critic driving a ratchet just optimizes toward a broken oracle. Reference bar: **Linear (primary)** + Vercel/Stripe/Grafana-cautionary (secondary, surface-specific).

**Cross-cutting invariants (hold in every phase's constraints):**

- No root `mix.exs` runtime dependency — the Anthropic SDK is an `examples/threadline_phoenix/e2e` `devDependency` only; `verify.compile_no_optional` still proves root `threadline` stays Phoenix-optional.
- No public component / "design-eval" API; the harness is dev/maintainer tooling.
- Dev/test-only, fail-closed harness (the `/audit/__stress` pattern — raises in `:prod`).
- LLM calls excluded from `mix ci.all`; CI verifies only the committed deterministic ledger/guards.
- Capture / query / auth semantics untouched.
- No external SaaS visual-diff tool names in committed ledger copy (the ledger `@forbidden_terms` guard: Chromatic/Percy/Applitools/Lost Pixel, `PhoenixStorybook`, `Tailwind`, `immutable ledger`).
- Scope discipline: **build + validate the harness, then PROVE it by improving the 2–3 lowest-scoring pages — not a full 11-page sweep.** Every phase advances real fixtures on the actual `/audit` surface (or produces real evidence from it), never "harness built" alone (SCOPE-1 guard).

### Phases

- [x] **Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation** - Extend the ledger to a `page × persona × lens` cube with per-lens monotonicity + evidence-referenced bumps, and land deterministic mechanical checkers + a tiered evidence-capture matrix — all in `mix ci.all`, no LLM, no network.
- [ ] **Phase 195: Validated Adversarial Critic Runner & Panel** - Author the golden set + versioned anchored rubrics, build the local-only `e2e/critic/` Claude-vision panel (per-persona + graphic-design + brand-veto), and prove it against the golden set (refute-tests + 75–90% human agreement) before it may drive anything — with no new root runtime dep.
- [ ] **Phase 196: Forward-Only Net-Positive Gate & First Proven Iteration** - Wire the full loop (capture → critique → propose → re-evaluate → guard) behind a full-panel net-positive gate with auto-apply + Goodhart/guard-the-guards protections, and prove it end-to-end with one real human-ratified improvement on the weakest page.
- [ ] **Phase 197: Coverage Growth, Adversarial Closeout & Design-Debt Register** - Drive real ratified improvement across the 2–3 lowest-scoring operator pages, run a v1.37-style multi-lens adversarial closeout confirming the loop can't regress the deterministic floor and all invariants hold, and register residual design-debt with owner + reopen-trigger.

## Phase Details

### Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation

**Goal**: The design-system ledger records an independently-ratcheted `page × persona × lens` scorecard cube, deterministic mechanical checkers act as the ratchet floor, and a tiered Playwright capture lane emits complete per-cell evidence bundles from `/audit/__stress` — the entire deterministic spine runs inside `mix ci.all` with no LLM and no network, so any nondeterministic producer built later can never precede or corrupt the guard.
**Depends on**: Nothing (first phase of v1.40)
**Requirements**: LEDGER-01, LEDGER-02, LEDGER-03, LEDGER-04, LEDGER-05, MECH-01, MECH-02, MECH-03, MECH-04, MECH-05
**Success Criteria** (what must be TRUE):

  1. The ledger records a `page × persona × lens` scorecard cube per entry (replacing the single opaque score), each lens tracked independently, and `stress_ledger_test.exs` fails any lens score that drops below its committed floor without an explicit ratchet reset + rationale and any score increase lacking an `evidence_ref` to a committed scorecard artifact. (LEDGER-01, LEDGER-02, LEDGER-03)
  2. The `DESIGN-SYSTEM.md` projection regenerates with per-lens columns and stays freshness-tested per row, and the ledger plus all its guards run deterministically inside `mix ci.all` with no LLM call and no network. (LEDGER-04, LEDGER-05)
  3. Deterministic checkers compute, from real `/audit` source/computed styles, the full mechanical metric set — token-grid conformance, spacing-on-scale, type-size count, radius/shadow/motion token conformance, WCAG contrast (dark + light), interactive-control count, card-nesting depth, scroll-cost per breakpoint, and distinct-accent-hue count — and a violation blocks a proposed change independently of any LLM judgment. (MECH-01, MECH-02, MECH-03)
  4. The Playwright capture lane emits a complete evidence bundle per cell (screenshot + rendered DOM + ARIA/a11y tree + resolved `--tl-*` tokens + meta) driven from `/audit/__stress`, under a documented and explicit tiered matrix — Tier A deterministic (all cells, CI) / Tier B LLM sample (curated subset, local) / Tier C pixel allowlist (CI) across page × state × breakpoint × theme. (MECH-04, MECH-05)

**Plans**: 3 plans (3 waves — guard-before-producer spine)

- [x] 194-01-PLAN.md — Ledger v1→v2 scorecard-cube migration + guard extension + DESIGN-SYSTEM per-lens projection (Wave 1; LEDGER-01..05)
- [x] 194-02-PLAN.md — Tier A Playwright capture lane + committed evidence bundles + tiered matrix doc (Wave 2; MECH-04, MECH-05)
- [x] 194-03-PLAN.md — MechanicalChecker (WCAG + MODE-A/B) + verify.mechanical folded into ci.all (Wave 3; MECH-01, MECH-02, MECH-03)

### Phase 195: Validated Adversarial Critic Runner & Panel

**Goal**: A local-only Claude-vision critic panel (one critic per persona P1–P5 + a graphic-design critic + a brand-veto critic) exists, cites concrete evidence for every score, runs behind `mix verify.ui_critique`, and is *proven trustworthy* against a hand-labeled golden set (refute-tests + documented 75–90% human agreement) before it is allowed to drive any ratchet — all while the Anthropic SDK stays an `e2e` devDependency and root `threadline` gains no runtime dependency.
**Depends on**: Phase 194
**Requirements**: CRITIC-01, CRITIC-02, CRITIC-03, CRITIC-04, CRITIC-05, RUNNER-01, RUNNER-02, RUNNER-03, RUNNER-04, RUNNER-05
**Success Criteria** (what must be TRUE):

  1. A golden set of hand-labeled Threadline states (known-good primitives + known-bad footgun fixtures) with the maintainer's good/bad/rank verdicts exists, and versioned anchored per-lens rubrics (one per persona/JTBD + graphic-design + brand) phrase each dimension as an adversarial pass/fail with a written pass condition and a reference-bar anchor (Linear primary; Vercel/Stripe/Grafana secondary by surface). (CRITIC-01, CRITIC-04)
  2. The critic passes its refute-tests — scores footgun fixtures low, polished primitives high, prefers the known-better of a curated A/B pair, and detects an injected regression (e.g. doubled padding, added nested card) — and its critic↔human agreement on the golden set meets the documented threshold; below threshold blocks automated ratcheting. (CRITIC-02, CRITIC-03)
  3. Self-assessment is banned: every score cites a screenshot region/DOM selector or a mechanical output line, and a finding that cannot be located is discarded. (CRITIC-05)
  4. A Node critic runner in `examples/threadline_phoenix/e2e/critic/` calls Claude vision with JSON-schema structured output, a prompt-cached rubric+anchor prefix, and one dimension per call; performs N-sample self-consistency (median + variance), flags high-variance cells as unstable/not-ratcheted, and stamps model id + rubric version on every scorecard; the panel runs one critic per persona (P1–P5) + a graphic-design critic + a brand-veto critic, and a `--tl-*` token / parity violation vetoes a change before aesthetic scoring. (RUNNER-01, RUNNER-02, RUNNER-03)
  5. `mix verify.ui_critique` wraps the runner as a named entrypoint, requires `ANTHROPIC_API_KEY`, no-ops without it, is excluded from `mix ci.all`, and is documented as local-only under a doc-contract lock; the Anthropic SDK is a `devDependency` of `e2e/package.json` only and `verify.compile_no_optional` still proves root `threadline` stays Phoenix-optional with no new runtime dependency. (RUNNER-04, RUNNER-05)

**Plans**: 7 plans (3 waves)
**Wave 1**

- [x] 195-01-PLAN.md — Foundations, named entrypoints & CI wiring (RUNNER-04, RUNNER-05) [wave 1]
- [x] 195-02-PLAN.md — Versioned anchored per-lens rubrics (CRITIC-04) [wave 1]
- [ ] 195-03-PLAN.md — Refute-twin fixtures & partition proof (CRITIC-02) [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 195-04-PLAN.md — Trust gate: Krippendorff α + full guards (CRITIC-03, CRITIC-04) [wave 2]
- [ ] 195-05-PLAN.md — Node runner core call path (RUNNER-01, RUNNER-02, CRITIC-05) [wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 195-06-PLAN.md — Panel orchestration, veto & refute battery (RUNNER-03, CRITIC-02) [wave 3]
- [ ] 195-07-PLAN.md — Report projection, authoring lane & local validation (CRITIC-01) [wave 3]

### Phase 196: Forward-Only Net-Positive Gate & First Proven Iteration

**Goal**: The validated critic feeds a forward-only gate that accepts a change only if it improves the targeted lens with no regression anywhere across the full panel; mechanical fixes plus a narrow spike-proven low-risk-structural whitelist auto-apply strictly behind that gate; Goodhart, silent-loosening, and pixel-diff-as-quality-bar are all blocked; and the whole loop is wired end-to-end, documented as a runbook, and proven by one real human-ratified improvement on the weakest `/audit` page.
**Depends on**: Phase 195 (critic must be validated before it drives the ratchet)
**Requirements**: GATE-01, GATE-02, GATE-03, GATE-04, GATE-05, PROOF-01
**Success Criteria** (what must be TRUE):

  1. A change is accepted only if it improves the targeted lens AND no other page/persona/lens score regresses below floor AND all mechanical / a11y / screenshot guards pass — via a full-panel, blast-radius-aware re-eval for shared tokens/primitives. (GATE-01)
  2. Mechanical fixes auto-apply (snap-to-token, fix contrast, remove off-grid px) and a narrow, spike-defined low-risk-structural whitelist may also auto-apply, both strictly behind GATE-01. (GATE-02)
  3. A held-out "true-north" fixture set is scored for validity only and never optimized against (training-vs-held-out divergence halts the loop); score-bar changes (ratchet bumps, target changes, panel-membership changes) require human sign-off recorded in the append-only ledger with a guard-the-guards test blocking silent target drops or fixture removal; and pixel-diff stays advisory — a screenshot baseline refresh requires the new render to have already passed the semantic guards. (GATE-03, GATE-04, GATE-05)
  4. The full loop (capture → critique → propose → re-evaluate → guard) is wired end-to-end and documented as a repeatable runbook, and is proven by one real, human-ratified improvement on the lowest-scoring page — target lens advanced with no regressions and a committed evidence trail. (PROOF-01)

**Plans**: TBD
**UI hint**: yes

### Phase 197: Coverage Growth, Adversarial Closeout & Design-Debt Register

**Goal**: The loop drives real, ratified improvement on the 2–3 lowest-scoring operator pages (proving it changes the actual UI, not just the tooling), a v1.37-style multi-lens adversarial closeout confirms the loop cannot regress the deterministic floor and every invariant holds, and residual design-debt is registered with owner + reopen-trigger.
**Depends on**: Phase 196
**Requirements**: PROOF-02, PROOF-03, PROOF-04
**Success Criteria** (what must be TRUE):

  1. Real, ratified improvement is landed on the 2–3 lowest-scoring operator pages — each targeted lens advanced toward its `target_score` with no regressions — proving the loop drives real UI change, not just tooling. (PROOF-02)
  2. A v1.37-style multi-lens adversarial closeout confirms the loop cannot regress the deterministic floor and all invariants hold — no root runtime dep, no public API, dev/test-only, LLM out of CI, capture/query/auth untouched. (PROOF-03)
  3. A residual design-debt register lists remaining items with owner + reopen-trigger, in the v1.39 risk-register shape. (PROOF-04)

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 194 → 195 → 196 → 197

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 194. Scorecard-Cube Ledger & Mechanical Capture Foundation | v1.40 | 3/3 | ✅ Complete | 2026-07-03 |
| 195. Validated Adversarial Critic Runner & Panel | v1.40 | 2/7 | In Progress|  |
| 196. Forward-Only Net-Positive Gate & First Proven Iteration | v1.40 | 0/TBD | Not started | - |
| 197. Coverage Growth, Adversarial Closeout & Design-Debt Register | v1.40 | 0/TBD | Not started | - |

## Prior Milestones

<details>
<summary>v1.39 Quality Baseline, Schema Confidence, and CI Efficiency (Phases 189-193) - SHIPPED 2026-07-03</summary>

Repo-evidence quality-risk ranking followed by high-confidence fixes to the three weakest surfaces: configurable PostgreSQL `storage_schema` behavior proven end-to-end for a custom `audit` schema (capture/query/evidence/governance/retention/export/operator, quoted migration identifiers, dual-schema integration test), release/docs version truth reconciled to `0.9.0` behind a drift-guard test with an extended 0.6.x→0.9.x upgrade path, and measured CI/CD efficiency work (caches, min/current compatibility matrix, concurrency, pinned PgBouncer) behind contract guards. Closed with 15/15 requirements traceability and a ranked residual-risk register (owner + reopen-trigger per item). No product/UI scope expansion, no version bump/Hex publish. Archive: `.planning/milestones/v1.39-ROADMAP.md`.

</details>

<details>
<summary>v1.38 Operator UI Page-by-Page IA & Design-System Polish (Phases 181-188) - SHIPPED 2026-06-30</summary>

Baseline guard repair, PhoenixStorybook example/dev lane, shell/Home orientation, Timeline investigation flow, Coverage readiness, detail/governance/export surface polish, accessibility/motion/docs closeout, and Phase 188 audit-gap closure for queued export replay, `.tl-copy` motion, GOV-02 traceability, and v1.38 evidence. Archive: `.planning/milestones/v1.38-ROADMAP.md`.

</details>

<details>
<summary>v1.37 Operator Surface Design-System Stress Test & Component System (Phases 171-180) - SHIPPED 2026-06-20</summary>

Internal component system, `/audit/__stress`, design-system ledger, shell/navigation/theme picker, page stress coverage, microcopy/IA normalization, WCAG/APG/motion guardrails, accessibility-tree evidence, and adversarial closeout. Archive: `.planning/milestones/v1.37-ROADMAP.md`.

</details>

<details>
<summary>v1.36 Operator Surface Light Mode (Phases 166-170) - SHIPPED 2026-06-14</summary>

`theme: :dark | :light | :system` host config and pure-CSS light/system lanes. Archive: `.planning/milestones/v1.36-ROADMAP.md`.

</details>
