<!-- GENERATED — do not hand-edit. Regenerate: npm run critic:score -->
<!-- Baseline: @v1.37 → @HEAD -->
<!-- Last regenerated: 2026-07-29 -->

# CRITIQUE.md — Adversarial Critic Projection

> Generated from `.planning/critic-scores/` by `report.ts`.
> Never hand-edit — regenerate with `npm run critic:score`.
> Freshness-tested: every scored cell must have a row here (see `critic_trust_test.exs`).

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ▲ new {score} [band] | New score — no prior floor for this cell/lens. |
| ▲ +N {score} [band] | Gain — score N points above the committed floor. |
| {score} [band] same | Same band as prior floor — no meaningful change. |
| ▽ -N {score} [band] | Regression — score N points below the committed floor. |
| ~ unstable (IQR N) | Unstable — high variance across self-consistency samples. Score is null (never 0); excluded from rollup and Phase-196 net-positive calculation. Re-run or human-adjudicate. |
| ⛔ vetoed (locator...) | Brand/token veto tripped before aesthetic scoring. No aesthetic score recorded for this cell. The cited mechanical line is the evidence. |
| ? N [band] (untrusted) | Lens not yet validated (α < 0.67 or n < 20 golden judgments). Number shown for reference; do not use for ratchet decisions or floor bumps. |
| — | Not yet scored. Run `npm run critic:score` to populate. |

**Stability rule:** `~ unstable` cells show null, never 0. An unstable cell that scores 0 would poison the `min()` rollup and illegally register as a regression — null is the correct sentinel.

**"Unknown" is not "bad":** unscored (—) and unstable (~) cells are information gaps, not failures. Only a scored `fail` or `weak` band is a signal to act on.

**Rollup (leading column):** `min()` across all scored, stable, non-vetoed lens scores for the cell. A single weak lens floors the entire rollup — the same discipline as the scorecard cube.

---

## Baseline

Baseline: @v1.37 → @HEAD (delta vs committed critic floors from prior scoring run; `▲ new` = no prior floor).

Reference bar: Linear (primary) — one accent per job, primary + secondary metadata in one clear scan path.
Vercel/Stripe (typographic restraint + accent discipline). Grafana (cautionary — high-density footgun).

---

## Score Table

One row per scored cell. Columns: `rollup` = min() across all lenses; per-lens = min() across dimensions.
Betterer idiom: `▲ new` (first score), `▲ +N` (gain), `same` (no change), `▽ -N` (regression).
Per finding: score + band + delta vs floor + cited evidence locator + suggested direction (not an auto-fix).

| cell_id | rollup | hierarchy | density | rhythm | typography | color_contrast | brand_fidelity |
|---------|--------|-----------|---------|--------|------------|----------------|----------------|
| `refute.brand_fidelity.graded.actor.r1__dark-1280` | ▲ new 4 [fail] | — | — | — | — | — | ▲ new 4 [fail] |
| `refute.brand_fidelity.graded.actor.r2__dark-1280` | ▲ new 12 [fail] | — | — | — | — | — | ▲ new 12 [fail] |
| `refute.brand_fidelity.graded.actor.r3__dark-1280` | ▲ new 26 [fail] | — | — | — | — | — | ▲ new 26 [fail] |
| `refute.brand_fidelity.graded.actor.r4__dark-1280` | ▲ new 29 [fail] | — | — | — | — | — | ▲ new 29 [fail] |
| `refute.brand_fidelity.graded.coverage.r1__dark-1280` | ▲ new 4 [fail] | — | — | — | — | — | ▲ new 4 [fail] |
| `refute.brand_fidelity.graded.coverage.r2__dark-1280` | ▲ new 18 [fail] | — | — | — | — | — | ▲ new 18 [fail] |
| `refute.brand_fidelity.graded.coverage.r3__dark-1280` | ▲ new 38 [weak] | — | — | — | — | — | ▲ new 38 [weak] |
| `refute.brand_fidelity.graded.coverage.r4__dark-1280` | ▲ new 38 [weak] | — | — | — | — | — | ▲ new 38 [weak] |
| `refute.brand_fidelity.graded.evidence.r1__dark-1280` | ▲ new 4 [fail] | — | — | — | — | — | ▲ new 4 [fail] |
| `refute.brand_fidelity.graded.evidence.r2__dark-1280` | ▲ new 18 [fail] | — | — | — | — | — | ▲ new 18 [fail] |
| `refute.brand_fidelity.graded.evidence.r3__dark-1280` | ▲ new 24 [fail] | — | — | — | — | — | ▲ new 24 [fail] |
| `refute.brand_fidelity.graded.evidence.r4__dark-1280` | ▲ new 28 [fail] | — | — | — | — | — | ▲ new 28 [fail] |
| `refute.brand_fidelity.graded.export.r1__dark-1280` | ▲ new 4 [fail] | — | — | — | — | — | ▲ new 4 [fail] |
| `refute.brand_fidelity.graded.export.r2__dark-1280` | ▲ new 18 [fail] | — | — | — | — | — | ▲ new 18 [fail] |
| `refute.brand_fidelity.graded.export.r3__dark-1280` | ▲ new 22 [fail] | — | — | — | — | — | ▲ new 22 [fail] |
| `refute.brand_fidelity.graded.export.r4__dark-1280` | ▲ new 78 [strong] | — | — | — | — | — | ▲ new 78 [strong] |
| `refute.brand_fidelity.graded.retention.r1__dark-1280` | ▲ new 4 [fail] | — | — | — | — | — | ▲ new 4 [fail] |
| `refute.brand_fidelity.graded.retention.r2__dark-1280` | ▲ new 18 [fail] | — | — | — | — | — | ▲ new 18 [fail] |
| `refute.brand_fidelity.graded.retention.r3__dark-1280` | ▲ new 29 [fail] | — | — | — | — | — | ▲ new 29 [fail] |
| `refute.brand_fidelity.graded.retention.r4__dark-1280` | ▲ new 82 [strong] | — | — | — | — | — | ▲ new 82 [strong] |
| `refute.brand_fidelity.graded.timeline.r1__dark-1280` | ▲ new 4 [fail] | — | — | — | — | — | ▲ new 4 [fail] |
| `refute.brand_fidelity.graded.timeline.r2__dark-1280` | ▲ new 18 [fail] | — | — | — | — | — | ▲ new 18 [fail] |
| `refute.brand_fidelity.graded.timeline.r3__dark-1280` | ▲ new 22 [fail] | — | — | — | — | — | ▲ new 22 [fail] |
| `refute.brand_fidelity.graded.timeline.r4__dark-1280` | ▲ new 22 [fail] | — | — | — | — | — | ▲ new 22 [fail] |
| `refute.color_contrast.graded.actor.r1__dark-1280` | ▲ new 15 [fail] | — | — | — | — | ▲ new 15 [fail] | — |
| `refute.color_contrast.graded.actor.r2__dark-1280` | ▲ new 24 [fail] | — | — | — | — | ▲ new 24 [fail] | — |
| `refute.color_contrast.graded.actor.r3__dark-1280` | ▲ new 24 [fail] | — | — | — | — | ▲ new 24 [fail] | — |
| `refute.color_contrast.graded.actor.r4__dark-1280` | — | — | — | — | — | ~ unstable (IQR 27.0) | — |
| `refute.color_contrast.graded.coverage.r1__dark-1280` | ▲ new 18 [fail] | — | — | — | — | ▲ new 18 [fail] | — |
| `refute.color_contrast.graded.coverage.r2__dark-1280` | ▲ new 27 [fail] | — | — | — | — | ▲ new 27 [fail] | — |
| `refute.color_contrast.graded.coverage.r3__dark-1280` | — | — | — | — | — | ~ unstable (IQR 35.0) | — |
| `refute.color_contrast.graded.coverage.r4__dark-1280` | ▲ new 24 [fail] | — | — | — | — | ▲ new 24 [fail] | — |
| `refute.color_contrast.graded.diff.r1__dark-1280` | ▲ new 16 [fail] | — | — | — | — | ▲ new 16 [fail] | — |
| `refute.color_contrast.graded.diff.r2__dark-1280` | ▲ new 22 [fail] | — | — | — | — | ▲ new 22 [fail] | — |
| `refute.color_contrast.graded.diff.r3__dark-1280` | ▲ new 26 [fail] | — | — | — | — | ▲ new 26 [fail] | — |
| `refute.color_contrast.graded.diff.r4__dark-1280` | ▲ new 22 [fail] | — | — | — | — | ▲ new 22 [fail] | — |
| `refute.color_contrast.graded.evidence.r1__dark-1280` | ▲ new 13 [fail] | — | — | — | — | ▲ new 13 [fail] | — |
| `refute.color_contrast.graded.evidence.r2__dark-1280` | ▲ new 22 [fail] | — | — | — | — | ▲ new 22 [fail] | — |
| `refute.color_contrast.graded.evidence.r3__dark-1280` | ▲ new 24 [fail] | — | — | — | — | ▲ new 24 [fail] | — |
| `refute.color_contrast.graded.evidence.r4__dark-1280` | ▲ new 29 [fail] | — | — | — | — | ▲ new 29 [fail] | — |
| `refute.color_contrast.graded.retention.r1__dark-1280` | ▲ new 18 [fail] | — | — | — | — | ▲ new 18 [fail] | — |
| `refute.color_contrast.graded.retention.r2__dark-1280` | ▲ new 24 [fail] | — | — | — | — | ▲ new 24 [fail] | — |
| `refute.color_contrast.graded.retention.r3__dark-1280` | — | — | — | — | — | ~ unstable (IQR 26.0) | — |
| `refute.color_contrast.graded.retention.r4__dark-1280` | — | — | — | — | — | ~ unstable (IQR 16.0) | — |
| `refute.color_contrast.graded.status.r1__dark-1280` | ▲ new 12 [fail] | — | — | — | — | ▲ new 12 [fail] | — |
| `refute.color_contrast.graded.status.r2__dark-1280` | ▲ new 22 [fail] | — | — | — | — | ▲ new 22 [fail] | — |
| `refute.color_contrast.graded.status.r3__dark-1280` | ▲ new 22 [fail] | — | — | — | — | ▲ new 22 [fail] | — |
| `refute.color_contrast.graded.status.r4__dark-1280` | ▲ new 16 [fail] | — | — | — | — | ▲ new 16 [fail] | — |
| `refute.density.graded.activity.r1__dark-1280` | ▲ new 28 [fail] | — | ▲ new 28 [fail] | — | — | — | — |
| `refute.density.graded.activity.r2__dark-1280` | ▲ new 26 [fail] | — | ▲ new 26 [fail] | — | — | — | — |
| `refute.density.graded.activity.r3__dark-1280` | ▲ new 42 [weak] | — | ▲ new 42 [weak] | — | — | — | — |
| `refute.density.graded.activity.r4__dark-1280` | ▲ new 67 [ok] | — | ▲ new 67 [ok] | — | — | — | — |
| `refute.density.graded.actor.r1__dark-1280` | ▲ new 24 [fail] | — | ▲ new 24 [fail] | — | — | — | — |
| `refute.density.graded.actor.r2__dark-1280` | ▲ new 28 [fail] | — | ▲ new 28 [fail] | — | — | — | — |
| `refute.density.graded.actor.r3__dark-1280` | ▲ new 74 [strong] | — | ▲ new 74 [strong] | — | — | — | — |
| `refute.density.graded.actor.r4__dark-1280` | ▲ new 80 [strong] | — | ▲ new 80 [strong] | — | — | — | — |
| `refute.density.graded.coverage.r1__dark-1280` | ▲ new 24 [fail] | — | ▲ new 24 [fail] | — | — | — | — |
| `refute.density.graded.coverage.r2__dark-1280` | ▲ new 22 [fail] | — | ▲ new 22 [fail] | — | — | — | — |
| `refute.density.graded.coverage.r3__dark-1280` | ▲ new 74 [strong] | — | ▲ new 74 [strong] | — | — | — | — |
| `refute.density.graded.coverage.r4__dark-1280` | ▲ new 74 [strong] | — | ▲ new 74 [strong] | — | — | — | — |
| `refute.density.graded.evidence.r1__dark-1280` | ▲ new 28 [fail] | — | ▲ new 28 [fail] | — | — | — | — |
| `refute.density.graded.evidence.r2__dark-1280` | ▲ new 24 [fail] | — | ▲ new 24 [fail] | — | — | — | — |
| `refute.density.graded.evidence.r3__dark-1280` | ▲ new 69 [ok] | — | ▲ new 69 [ok] | — | — | — | — |
| `refute.density.graded.evidence.r4__dark-1280` | ▲ new 74 [strong] | — | ▲ new 74 [strong] | — | — | — | — |
| `refute.density.graded.exports.r1__dark-1280` | ▲ new 22 [fail] | — | ▲ new 22 [fail] | — | — | — | — |
| `refute.density.graded.exports.r2__dark-1280` | ▲ new 24 [fail] | — | ▲ new 24 [fail] | — | — | — | — |
| `refute.density.graded.exports.r3__dark-1280` | ▲ new 74 [strong] | — | ▲ new 74 [strong] | — | — | — | — |
| `refute.density.graded.exports.r4__dark-1280` | ▲ new 76 [strong] | — | ▲ new 76 [strong] | — | — | — | — |
| `refute.density.graded.retention.r1__dark-1280` | ▲ new 28 [fail] | — | ▲ new 28 [fail] | — | — | — | — |
| `refute.density.graded.retention.r2__dark-1280` | ▲ new 22 [fail] | — | ▲ new 22 [fail] | — | — | — | — |
| `refute.density.graded.retention.r3__dark-1280` | ▲ new 66 [ok] | — | ▲ new 66 [ok] | — | — | — | — |
| `refute.density.graded.retention.r4__dark-1280` | ▲ new 77 [strong] | — | ▲ new 77 [strong] | — | — | — | — |
| `refute.hierarchy.graded.activity.r1__dark-1280` | ▲ new 63 [ok] | ▲ new 63 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.activity.r2__dark-1280` | ▲ new 71 [strong] | ▲ new 71 [strong] | — | — | — | — | — |
| `refute.hierarchy.graded.activity.r3__dark-1280` | ▲ new 63 [ok] | ▲ new 63 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.activity.r4__dark-1280` | ▲ new 66 [ok] | ▲ new 66 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.actor.r1__dark-1280` | ▲ new 67 [ok] | ▲ new 67 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.actor.r2__dark-1280` | ▲ new 74 [strong] | ▲ new 74 [strong] | — | — | — | — | — |
| `refute.hierarchy.graded.actor.r3__dark-1280` | ▲ new 74 [strong] | ▲ new 74 [strong] | — | — | — | — | — |
| `refute.hierarchy.graded.actor.r4__dark-1280` | ▲ new 66 [ok] | ▲ new 66 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.coverage.r1__dark-1280` | ▲ new 60 [ok] | ▲ new 60 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.coverage.r2__dark-1280` | ▲ new 76 [strong] | ▲ new 76 [strong] | — | — | — | — | — |
| `refute.hierarchy.graded.coverage.r3__dark-1280` | ▲ new 68 [ok] | ▲ new 68 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.coverage.r4__dark-1280` | ▲ new 68 [ok] | ▲ new 68 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.evidence.r1__dark-1280` | ▲ new 68 [ok] | ▲ new 68 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.evidence.r2__dark-1280` | ▲ new 76 [strong] | ▲ new 76 [strong] | — | — | — | — | — |
| `refute.hierarchy.graded.evidence.r3__dark-1280` | ▲ new 68 [ok] | ▲ new 68 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.evidence.r4__dark-1280` | ▲ new 77 [strong] | ▲ new 77 [strong] | — | — | — | — | — |
| `refute.hierarchy.graded.exports.r1__dark-1280` | ▲ new 66 [ok] | ▲ new 66 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.exports.r2__dark-1280` | ▲ new 76 [strong] | ▲ new 76 [strong] | — | — | — | — | — |
| `refute.hierarchy.graded.exports.r3__dark-1280` | ▲ new 64 [ok] | ▲ new 64 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.exports.r4__dark-1280` | ▲ new 66 [ok] | ▲ new 66 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.retention.r1__dark-1280` | ▲ new 61 [ok] | ▲ new 61 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.retention.r2__dark-1280` | ▲ new 74 [strong] | ▲ new 74 [strong] | — | — | — | — | — |
| `refute.hierarchy.graded.retention.r3__dark-1280` | ▲ new 68 [ok] | ▲ new 68 [ok] | — | — | — | — | — |
| `refute.hierarchy.graded.retention.r4__dark-1280` | ▲ new 74 [strong] | ▲ new 74 [strong] | — | — | — | — | — |
| `refute.rhythm.graded.activity.r1__dark-1280` | ▲ new 28 [fail] | — | — | ▲ new 28 [fail] | — | — | — |
| `refute.rhythm.graded.activity.r2__dark-1280` | ▲ new 69 [ok] | — | — | ▲ new 69 [ok] | — | — | — |
| `refute.rhythm.graded.activity.r3__dark-1280` | ▲ new 70 [strong] | — | — | ▲ new 70 [strong] | — | — | — |
| `refute.rhythm.graded.activity.r4__dark-1280` | ▲ new 69 [ok] | — | — | ▲ new 69 [ok] | — | — | — |
| `refute.rhythm.graded.actor.r1__dark-1280` | ▲ new 25 [fail] | — | — | ▲ new 25 [fail] | — | — | — |
| `refute.rhythm.graded.actor.r2__dark-1280` | ▲ new 34 [fail] | — | — | ▲ new 34 [fail] | — | — | — |
| `refute.rhythm.graded.actor.r3__dark-1280` | ▲ new 69 [ok] | — | — | ▲ new 69 [ok] | — | — | — |
| `refute.rhythm.graded.actor.r4__dark-1280` | ▲ new 70 [strong] | — | — | ▲ new 70 [strong] | — | — | — |
| `refute.rhythm.graded.coverage.r1__dark-1280` | ▲ new 68 [ok] | — | — | ▲ new 68 [ok] | — | — | — |
| `refute.rhythm.graded.coverage.r2__dark-1280` | ▲ new 69 [ok] | — | — | ▲ new 69 [ok] | — | — | — |
| `refute.rhythm.graded.coverage.r3__dark-1280` | ▲ new 76 [strong] | — | — | ▲ new 76 [strong] | — | — | — |
| `refute.rhythm.graded.coverage.r4__dark-1280` | ▲ new 74 [strong] | — | — | ▲ new 74 [strong] | — | — | — |
| `refute.rhythm.graded.evidence.r1__dark-1280` | ▲ new 28 [fail] | — | — | ▲ new 28 [fail] | — | — | — |
| `refute.rhythm.graded.evidence.r2__dark-1280` | ▲ new 34 [fail] | — | — | ▲ new 34 [fail] | — | — | — |
| `refute.rhythm.graded.evidence.r3__dark-1280` | ▲ new 71 [strong] | — | — | ▲ new 71 [strong] | — | — | — |
| `refute.rhythm.graded.evidence.r4__dark-1280` | ▲ new 76 [strong] | — | — | ▲ new 76 [strong] | — | — | — |
| `refute.rhythm.graded.exports.r1__dark-1280` | ▲ new 25 [fail] | — | — | ▲ new 25 [fail] | — | — | — |
| `refute.rhythm.graded.exports.r2__dark-1280` | ▲ new 32 [fail] | — | — | ▲ new 32 [fail] | — | — | — |
| `refute.rhythm.graded.exports.r3__dark-1280` | ▲ new 70 [strong] | — | — | ▲ new 70 [strong] | — | — | — |
| `refute.rhythm.graded.exports.r4__dark-1280` | ▲ new 68 [ok] | — | — | ▲ new 68 [ok] | — | — | — |
| `refute.rhythm.graded.retention.r1__dark-1280` | ▲ new 61 [ok] | — | — | ▲ new 61 [ok] | — | — | — |
| `refute.rhythm.graded.retention.r2__dark-1280` | ▲ new 38 [weak] | — | — | ▲ new 38 [weak] | — | — | — |
| `refute.rhythm.graded.retention.r3__dark-1280` | ▲ new 68 [ok] | — | — | ▲ new 68 [ok] | — | — | — |
| `refute.rhythm.graded.retention.r4__dark-1280` | ▲ new 69 [ok] | — | — | ▲ new 69 [ok] | — | — | — |
| `refute.typography.graded.activity.r1__dark-1280` | ▲ new 44 [weak] | — | — | — | ▲ new 44 [weak] | — | — |
| `refute.typography.graded.activity.r2__dark-1280` | ▲ new 61 [ok] | — | — | — | ▲ new 61 [ok] | — | — |
| `refute.typography.graded.activity.r3__dark-1280` | ▲ new 74 [strong] | — | — | — | ▲ new 74 [strong] | — | — |
| `refute.typography.graded.activity.r4__dark-1280` | ▲ new 66 [ok] | — | — | — | ▲ new 66 [ok] | — | — |
| `refute.typography.graded.actor.r1__dark-1280` | ▲ new 41 [weak] | — | — | — | ▲ new 41 [weak] | — | — |
| `refute.typography.graded.actor.r2__dark-1280` | ▲ new 64 [ok] | — | — | — | ▲ new 64 [ok] | — | — |
| `refute.typography.graded.actor.r3__dark-1280` | ▲ new 74 [strong] | — | — | — | ▲ new 74 [strong] | — | — |
| `refute.typography.graded.actor.r4__dark-1280` | ▲ new 75 [strong] | — | — | — | ▲ new 75 [strong] | — | — |
| `refute.typography.graded.coverage.r1__dark-1280` | ▲ new 40 [weak] | — | — | — | ▲ new 40 [weak] | — | — |
| `refute.typography.graded.coverage.r2__dark-1280` | ▲ new 66 [ok] | — | — | — | ▲ new 66 [ok] | — | — |
| `refute.typography.graded.coverage.r3__dark-1280` | ▲ new 63 [ok] | — | — | — | ▲ new 63 [ok] | — | — |
| `refute.typography.graded.coverage.r4__dark-1280` | ▲ new 44 [weak] | — | — | — | ▲ new 44 [weak] | — | — |
| `refute.typography.graded.evidence.r1__dark-1280` | — | — | — | — | ~ unstable (IQR 21.0) | — | — |
| `refute.typography.graded.evidence.r2__dark-1280` | ▲ new 64 [ok] | — | — | — | ▲ new 64 [ok] | — | — |
| `refute.typography.graded.evidence.r3__dark-1280` | ▲ new 62 [ok] | — | — | — | ▲ new 62 [ok] | — | — |
| `refute.typography.graded.evidence.r4__dark-1280` | ▲ new 68 [ok] | — | — | — | ▲ new 68 [ok] | — | — |
| `refute.typography.graded.exports.r1__dark-1280` | — | — | — | — | ~ unstable (IQR 23.0) | — | — |
| `refute.typography.graded.exports.r2__dark-1280` | ▲ new 65 [ok] | — | — | — | ▲ new 65 [ok] | — | — |
| `refute.typography.graded.exports.r3__dark-1280` | ▲ new 64 [ok] | — | — | — | ▲ new 64 [ok] | — | — |
| `refute.typography.graded.exports.r4__dark-1280` | ▲ new 66 [ok] | — | — | — | ▲ new 66 [ok] | — | — |
| `refute.typography.graded.retention.r1__dark-1280` | ▲ new 40 [weak] | — | — | — | ▲ new 40 [weak] | — | — |
| `refute.typography.graded.retention.r2__dark-1280` | ▲ new 58 [ok] | — | — | — | ▲ new 58 [ok] | — | — |
| `refute.typography.graded.retention.r3__dark-1280` | ▲ new 63 [ok] | — | — | — | ▲ new 63 [ok] | — | — |
| `refute.typography.graded.retention.r4__dark-1280` | ▲ new 64 [ok] | — | — | — | ▲ new 64 [ok] | — | — |
| `route.timeline.degraded__dark-1280` | ▲ new 4 [fail] | ▲ new 6 [fail] | ▲ new 8 [fail] | ~ unstable (IQR 27.0) | ▲ new 12 [fail] | ▲ new 4 [fail] | ▲ new 66 [ok] |
| `route.timeline__dark-1280` | ▲ new 12 [fail] | ▲ new 12 [fail] | ▲ new 23 [fail] | ~ unstable (IQR 16.0) | ▲ new 42 [weak] | ▲ new 18 [fail] | ▲ new 77 [strong] |
| `story.foundations.index__dark-1280` | ▲ new 12 [fail] | ▲ new 22 [fail] | ▲ new 12 [fail] | ▲ new 22 [fail] | ▲ new 66 [ok] | ▲ new 24 [fail] | ▲ new 29 [fail] |
| `story.overlays.modal__dark-1280` | ▲ new 28 [fail] | ▲ new 62 [ok] | ▲ new 28 [fail] | ▲ new 64 [ok] | ▲ new 64 [ok] | ▲ new 72 [strong] | ▲ new 61 [ok] |
| `story.patterns.operator_patterns__dark-1280` | ▲ new 18 [fail] | ▲ new 18 [fail] | ▲ new 18 [fail] | ▲ new 66 [ok] | ▲ new 65 [ok] | ~ unstable (IQR 24.0) | ▲ new 74 [strong] |
| `story.primitives.button__dark-1280` | ▲ new 12 [fail] | ▲ new 18 [fail] | ▲ new 12 [fail] | ▲ new 29 [fail] | ▲ new 63 [ok] | ▲ new 24 [fail] | ▲ new 69 [ok] |

---

*Threat boundary: screenshot/DOM content sent to the Anthropic API during local scoring is dev-only tooling.
No production data. Opt-in via `ANTHROPIC_API_KEY`. See CONTRIBUTING.md "Local-only critic" section.*
