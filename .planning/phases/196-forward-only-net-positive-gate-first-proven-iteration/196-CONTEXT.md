---
phase: 196
slug: forward-only-net-positive-gate-first-proven-iteration
name: Forward-Only Net-Positive Gate & First Proven Iteration
date: 2026-07-28
source: Maintainer decisions (validation-arc ratification, not interactive discuss-phase)
requirements: [GATE-01, GATE-02, GATE-03, GATE-04, GATE-05, PROOF-01]
---

# Phase 196 — Context (locked decisions)

## Domain

Turn the **validated** operator-UI critic (Phase 195) into a **forward-only net-positive gate**:
a proposed UI change is accepted only if it moves the targeted lens in the right direction with
**no regression** anywhere on the blocking panel, and only after the deterministic mechanical / a11y
floor still passes. Then prove the loop moves a *real* page — the "first proven iteration."

**Crucial reframing (resolves the pre-planning worry):** GATE-01 was authored as a **relative /
ranking** gate ("improves the targeted lens AND no other lens regresses below floor"), NOT an
absolute-score gate. That is exactly what the synthetic-oracle validation certified the lenses *for*
(they rank well — Spearman ρ — while their absolute scale is compressed — low Krippendorff α). So the
ROADMAP does not need rewriting; Phase 196 only had to **set panel membership** and bind the abstract
GATE requirements to the machinery we already built. See
[[critic-synthetic-oracle-ranking-gate]], [[phase-196-gate-shape-decision-pending]].

## Trust panel (ground truth — `.planning/design-system-ledger.json → critic_trust`)

| lens | ρ (Spearman) | AUC | n | validated | role in gate |
|---|---|---|---|---|---|
| brand_fidelity | 0.93 | 1.00 | 24 | ✅ | **BLOCKING** |
| density | 0.84 | 1.00 | 24 | ✅ | **BLOCKING** |
| typography | 0.77 | 0.92 | 22 | ✅ | **BLOCKING** |
| rhythm | 0.76 | 0.95 | 24 | ✅ | **BLOCKING** |
| color_contrast | 0.698 | 0.80 | 20 | ❌ | advisory (0.002 under line) |
| hierarchy | 0.42 | 0.57 | 24 | ❌ | advisory (near-chance) |

Rule discovered during validation: a lens validates when its degradation is **perceptually separable
and countable**; it ceilings when it asks the critic to grade subtle "goodness."

---

## Locked Decisions

- **[196-D1] GATE-01 is a relative (ranking) gate, not absolute.** Accept a change iff:
  (a) the **targeted** blocking lens improves (Δ direction up), AND
  (b) **no** blocking lens regresses below its ratchet floor, AND
  (c) the deterministic mechanical / a11y guards still pass (see D3), AND
  (d) for shared tokens/primitives, the re-eval is **blast-radius-aware** — every affected
  page/persona cell is re-scored, not just the edited one.
  Compare rank/Δ direction, never absolute thresholds, on the LLM lenses.

- **[196-D2] Blocking panel = the 4 validated lenses (MAINTAINER SIGN-OFF, GATE-04).**
  `brand_fidelity`, `density`, `typography`, `rhythm` **block** (a ranking regression on any = reject).
  `hierarchy` (ρ0.42) and `color_contrast` (ρ0.698) are **advisory only** — reported with an advisory
  badge, **never** auto-block, and their findings must be **verified against ground truth** before any
  human acts on them (they confidently hallucinate specifics — see
  [[critic-advisory-lenses-hallucinate-specifics]]). Panel membership is recorded here as the human
  sign-off GATE-04 requires; changing it later requires a new recorded sign-off.

- **[196-D3] The deterministic mechanical floor is the hard block (GATE-02).**
  `verify.mechanical` (`MechanicalChecker`, Phase 194) is the non-negotiable floor: WCAG contrast +
  off-grid px hard-fails (MODE A) and ratchet floors (MODE B), over committed scorecard JSON, no
  browser/LLM. **Safety-critical contrast is therefore already hard-blocked mechanically** — which is
  *why* the LLM `color_contrast` lens can safely be advisory (D2). Mechanical fixes
  (snap-to-token, fix contrast, remove off-grid px) may **auto-apply strictly behind GATE-01**. The
  "narrow low-risk-structural whitelist" (GATE-02) **starts EMPTY** and may expand **only** via
  explicit spike evidence — no structural auto-apply ships un-spiked this phase.

- **[196-D4] The synthetic twin oracle is the held-out "true-north" set (GATE-03).**
  `.planning/golden/synthetic-set.json` (graded severity ladders, zero human labeling) is scored for
  **validity only** and is **never optimized against**. The loop optimizes the live `route.*` cells
  (the "training" surface); if the critic's ranking on the held-out oracle **diverges** from its
  behavior on the optimized surface, the loop **halts** (Goodhart guard). Keep the two surfaces
  disjoint — the oracle refute cells are not edited by the propose step.

- **[196-D5] Guard-the-guards lives in `verify.critic_trust` (GATE-04).**
  `critic_trust_test.exs` (already in `ci.all`, before `verify.mechanical`) is extended to be the
  append-only guard: it **blocks** silent target-floor drops, fixture/oracle-cell removal, and
  panel-membership changes that lack a recorded human sign-off in the ledger. The ledger is
  append-only; a bump/target/panel change without a new signed ledger entry fails the test.

- **[196-D6] Pixel-diff stays advisory (GATE-05).**
  Screenshot baselines never *are* the quality bar. A baseline **refresh** is permitted only after the
  new render has **already** passed the semantic guards (mechanical floor + blocking-panel no-regress).
  A raw pixel delta never accepts or rejects a change on its own.

- **[196-D7] Proof scope = wired loop + runbook + ONE real ratified improvement (PROOF-01 + "First
  Proven Iteration").** This phase (a) wires the full loop end-to-end
  (capture → critique → propose → re-evaluate → guard), (b) documents it as a repeatable **runbook**,
  and (c) lands **one real, human-ratified improvement on the single weakest `/audit` page** — target
  lens advanced, zero regressions, committed evidence trail. A **mid-phase human-ratification
  checkpoint** gates the real change. This pulls one page's worth of PROOF-02 forward per the phase
  title; the full 2–3-page PROOF-02, adversarial closeout (PROOF-03), and debt register (PROOF-04)
  remain **Phase 197**.

- **[196-D8] Real-UI source = `route.*` cells only.** The loop operates on real seeded `/audit/*`
  routes captured by `operator-page-capture.spec.ts` (route-capture project, `npm run capture:pages`),
  clipped to the main content region. **NOT** `page.*` (stress-lab dev chrome — invalid) and **NOT**
  `story.*` (isolated fixture demos — valid only for component-level lenses, no assembled page).
  See [[critic-real-ui-source-storybook-not-stress-lab]]. The route lane is currently nascent
  (`route.timeline` + `route.timeline.degraded`); the weakest-page proof (D7) expands it.

- **[196-D9] Cost & determinism posture.** The LLM critic stays **local-only and out of CI**
  (`verify.ui_critique` is excluded from `ci.all`; requires `ANTHROPIC_API_KEY`). Only the
  **deterministic** guards (`verify.critic_trust`, `verify.mechanical`) run in CI. LLM re-eval for the
  ranking check is bounded (N=3, escalate to N=7 only on unstable cells; ~$0.015/call) and blast-radius
  scoped — never a full-panel re-score when a change touches one cell.

---

## Canonical References (point the plans here)

- `lib/threadline/operator_surface/mechanical_checker.ex` — deterministic floor (GATE-02). `MechanicalChecker.run/*`.
- `test/threadline/operator_surface/mechanical_checker_test.exs` — `verify.mechanical` gate body.
- `test/threadline/operator_surface/critic_trust_test.exs` — `verify.critic_trust` (GATE-04 guard host).
- `.planning/design-system-ledger.json` — append-only `critic_trust` + ratchet ledger (GATE-04).
- `.planning/golden/synthetic-set.json` — held-out true-north oracle (GATE-03); built by `mix critic.synth`.
- `lib/mix/tasks/critic.measure.ex` — `mix critic.measure --source synthetic` writes `critic_trust`.
- `lib/mix/tasks/critic.synth.ex` — `mix critic.synth` generates the oracle from graded ladders.
- `lib/threadline/operator_surface/stress_fixtures.ex` — `@graded_ladder`, `StressFixtures.all/0` (refute + graded cells).
- `lib/threadline/operator_surface/live/stress_live.ex` — refute/graded cell rendering (`@hierarchy_scale`, `@density_ladder`).
- `examples/threadline_phoenix/e2e/critic/run.ts` — critic runner (score/validate/report); `PERSONA_LENSES` (collapsed to single "all" critic).
- `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` — real `/audit/*` route capture (route-capture project).
- `examples/threadline_phoenix/e2e/package.json` — `capture:pages`, `critic:score`, `critic:report:html`.
- `mix.exs` — `ci.all` pipeline (order: `verify.critic_trust` → `verify.mechanical` → `verify.example_browser`).
- `.planning/CRITIQUE.md` — regenerated projection over gitignored `route.*` cells (uncommitted by design).
- `CONTRIBUTING.md` — "Deterministic tests" + local-only critic key posture.

---

## Scope Fence

**IN:**
- Bind GATE-01..05 to existing machinery; wire the propose → re-evaluate → guard loop end-to-end.
- 4-lens ranking gate + advisory reporting for hierarchy/color_contrast.
- Extend `verify.critic_trust` into the guard-the-guards (GATE-04).
- Held-out-divergence halt using the synthetic oracle (GATE-03).
- Mechanical auto-apply behind the gate (GATE-02); structural whitelist starts empty.
- Runbook doc + ONE real ratified improvement on the weakest `/audit` page (D7).

**OUT (do not do this phase):**
- No absolute-score gate; no optimizing against the held-out oracle.
- `color_contrast` + `hierarchy` do **not** block (advisory only).
- No structural auto-apply without spike evidence (whitelist stays empty otherwise).
- PROOF-02 (2–3 pages), PROOF-03 (adversarial closeout), PROOF-04 (debt register) → **Phase 197**.
- **Invariants (unchanged):** no root runtime dependency; no public component API; dev/test-only;
  LLM stays out of CI; capture / query / auth semantics untouched; brand-token parity green.

---

## Success Criteria (what must be TRUE)

1. **GATE-01** — A change is accepted only if the targeted blocking lens improves AND no blocking lens
   regresses below floor AND mechanical/a11y guards pass; shared-token/primitive edits trigger a
   blast-radius-aware re-eval of all affected cells.
2. **GATE-02** — Mechanical fixes auto-apply strictly behind GATE-01; the structural whitelist is empty
   unless a spike has defined a specific low-risk entry.
3. **GATE-03** — The synthetic oracle is scored for validity only; training-vs-held-out divergence halts
   the loop.
4. **GATE-04** — Ratchet/target/panel-membership changes require a recorded human sign-off in the
   append-only ledger; `verify.critic_trust` fails on a silent target drop or fixture removal.
5. **GATE-05** — Pixel-diff is advisory; a baseline refresh requires the render to have already passed
   the semantic guards.
6. **PROOF-01 (+ First Proven Iteration)** — The full loop is wired end-to-end and documented as a
   runbook, and one real, human-ratified improvement lands on the weakest `/audit` page with the target
   lens advanced, zero regressions, and a committed evidence trail.

---

## Risk Summary

- **R1 — advisory-lens hallucination.** hierarchy/color_contrast confidently invent specifics; they
  never block and their findings are verified vs ground truth before action. (Mitigated by D2/D8.)
- **R2 — rhythm real-page instability.** rhythm is the lowest trusted lens (ρ0.76) and `scroll_cost` is
  non-deterministic jitter on real routes; revert unchanged scorecards after recapture; keep N-escalation
  for unstable route cells.
- **R3 — color_contrast at 0.698.** Just under the line; if a future phase promotes it to blocking, it
  needs re-validation and a GATE-04 sign-off. Not this phase.
- **R4 — auto-apply blast radius.** Mechanical fixes touch shared tokens/primitives; GATE-01's
  blast-radius re-eval is what keeps a "fix" from silently regressing another cell. Mechanical apply is
  deterministic (no LLM); the LLM ranking re-eval is bounded and scoped to affected cells.
- **R5 — LLM cost & non-determinism.** ~$0.015/call, N=3→7; full-panel re-score is the recurring cost.
  Keep LLM local, bounded, blast-radius-scoped; CI stays deterministic.

---

## Claude's Discretion (uncovered — planner/researcher decide)

- Exact module/orchestrator names for the propose → re-evaluate → guard loop and where the runbook lives.
- How to structure the held-out-vs-training divergence check concretely (threshold, halt signal).
- Which single `/audit` page is "weakest" (score the current `route.*` panel to pick it) and which lens
  to target for the proven iteration.
- Whether the propose step is human-authored-then-gated (likely, given no structural auto-apply) vs
  tool-assisted.
