# Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-03
**Phase:** 194-Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation
**Areas discussed:** Lens taxonomy, Cube migration & floors, Capture matrix (Tier A) & storage, Mechanical gate policy

**Method:** User selected all 4 gray areas and requested deep parallel-subagent research per area (pros/cons/tradeoffs, Elixir/Phoenix idiom, cross-ecosystem lessons, DX, UI/UX/JTBD lenses, brand book) synthesized into one coherent, one-shot recommendation. Four `gsd-advisor-researcher` agents ran in parallel; findings were reconciled into a single internally-consistent set and locked as-is by the user ("Lock all as-is").

---

## Lens taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| A. Minimal-orthogonal craft atoms (6) | Smallest non-opaque set; 4/6 have a deterministic mechanical floor; maps 1:1 to MECH-01/02 + the 7-critic panel; each atom anchorable to Linear | ✓ |
| B. Heuristic-derived (Nielsen 10 + CRAP, ~10) | Proven, citable vocabulary | |
| C. Persona-JTBD-derived (5, one per persona) | Ties to locked P1–P5 | |
| D. Two-tier mechanical-metrics + gestalt-lenses as separate axes (~9+4) | Cleanest measurement story on paper | |

**User's choice:** Option A — 6 lenses `hierarchy · density · rhythm · typography · color_contrast · brand_fidelity`, with `hierarchy`/`density` persona-weighted and the other four persona-invariant. Mechanical metrics from D demoted to *floors under* A's lenses.
**Notes:** Craft/polish deliberately excluded as a lens (emergent; catch-all is the #1 rubric-bloat footgun). Persona is a weight, never a lens ×5 multiplier. Critic×lens matrix committed so Phase-195 rubric authors map onto the frozen 6 lenses. Vocabulary frozen behind a dimension-drift guard.

---

## Cube migration & floors

| Option (migration) | Description | Selected |
|--------|-------------|----------|
| Full replace (drop scalar) | Cleanest end-state, one source of truth | |
| Parallel-additive (keep flat score + add cube) | Smallest guard change; old ratchet untouched | |
| Versioned redefinition (scalar = guard-recomputed min() rollup over sparse `scores`) | One source of truth; scalar survives so minimum_scores/locked_ids/projection unchanged; scalar can't be faked; min() = anti-Goodhart; small diff | ✓ |

| Option (seeding) | Description | Selected |
|--------|-------------|----------|
| Optimistic (all lenses = legacy score) | Non-empty from day one | |
| Literal 0 | Honest floor | |
| Conservative "unrated" (null/0, earned via evidence; hand-label golden set only) | Honest+empty start; every point earned w/ evidence_ref; first critic run legally only-up; ties to 196 held-out/sign-off | ✓ |

**User's choice:** Versioned in-place redefinition (`version` 1→2) with `min()` rollup over a sparse `persona.lens`-keyed `scores` map + `legacy_score`; conservative "unrated" seeding.
**Notes:** Optimistic seeding rejected — it makes the first honest critic measurement register as an illegal monotonicity drop and invites reverse-Goodhart. N/A cells by omission, cross-checked against the capture matrix. Floor bumps for judged lenses need Phase-196 human sign-off (`ratchet.signoffs`).

---

## Capture matrix (Tier A) & storage

| Option (matrix) | Description | Selected |
|--------|-------------|----------|
| Full cartesian (11×7×5×2 = 770) | Total coverage | |
| Smoke-wide + deep-narrow (~120) | Mechanical floor on all 11 pages (happy) + deep on 3 target pages; ~3 min; honors SCOPE-1 | ✓ |
| Targets-only (3 pages, ~72) | Smallest, fully SCOPE-1 | |

| Option (storage) | Description | Selected |
|--------|-------------|----------|
| Commit full bundle (PNG+DOM+a11y+tokens ×120) | Everything inspectable in-repo | |
| Scorecard JSON + aria YAML committed, binaries gitignored+regenerated | Small diffable evidence_ref targets; deterministic regen; plain-git; satisfies LEDGER-03 | ✓ |
| git-lfs for all binaries | Version-controlled images | |

**User's choice:** ~120-cell two-band matrix (66 floor + 54 deep), breakpoints 375/768/1280, dark+light both; commit scorecard JSON + aria YAML, gitignore+regenerate binaries, pixel-diff at existing Tier C allowlist.
**Notes:** Light theme non-negotiable (MECH-02 contrast dark+light). `deviceScaleFactor:1` added for determinism. Cell-id = `{ledger_id}__{theme}-{breakpoint}`. `mix verify.capture` regenerates; `--update` is a separate reviewed commit.

---

## Mechanical gate policy

| Option (split) | Description | Selected |
|--------|-------------|----------|
| All 9 hard blockers on universal thresholds | Simple, maximally strict | |
| Objective hard-fail; heuristics purely advisory (ignored in CI) | No false positives | |
| Two modes: A absolute-hard + B ratchet-floor-hard | Objective gates always right; heuristics gate on regression-below-own-floor; both satisfy MECH-03; no false-positive fatigue | ✓ |

| Option (provenance) | Description | Selected |
|--------|-------------|----------|
| Measure Linear's surfaces → bake numbers in | Aspirational | |
| All hand-set | Full control | |
| Spec/SSOT locked + current-state floor ratchet-down | Objective values unarguable; heuristics start where reality is and only improve | ✓ |

**User's choice:** Two gate modes — MODE A (absolute hard, WCAG + token/spacing/radius/shadow/motion conformance, auto-fixable) and MODE B (ratchet-floor, type-size/control-count/nesting/scroll-cost/accent-hue, tighten-only, 2 structural ones with far ceilings). LOCKED spec constants + RATCHET floors; Linear stays a critic reference, never a CI number.
**Notes:** MODE A set == Phase-196 auto-apply whitelist. Mechanical floors persona-invariant on the `(page × lens)` face. Mechanical→lens map committed. Named entrypoint `mix verify.mechanical` in `mix ci.all`; located, fix-carrying violation messages.

---

## Claude's Discretion
- Exact JSON field spelling within a cell, precise `cube_axes` metadata keys, test-name wording — consistent with existing `stress_ledger_test.exs` style.
- Which 3 pages are the Band-2 "lowest-scoring targets" — derive from current ledger scores at plan time.
- Whether the 3 legacy 1024 Tier C baselines rebaseline to 1280 or stay 1024.

## Deferred Ideas
- Full 11-page × 7-state Tier A sweep (FUT-01, Phase 197).
- loading / pagination-boundary / advanced states in Tier A (Phase 197; Tier B covers interim).
- 320 / 1440 breakpoints as full bundle cells (add only on scroll-cost regression).
- Claude-vision critic panel + golden set + forward-only gate + first proven improvement (Phases 195–197 by design).
