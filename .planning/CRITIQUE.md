<!-- GENERATED — do not hand-edit. Regenerate: npm run critic:score -->
<!-- Baseline: @v1.37 → @HEAD -->
<!-- Last regenerated: 2026-07-18 -->

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
| `refute.rhythm.graded.activity.r1__dark-1280` | ▲ new 28 [fail] | — | — | ▲ new 28 [fail] | — | — | — |
| `refute.rhythm.graded.activity.r2__dark-1280` | ▲ new 69 [ok] | — | — | ▲ new 69 [ok] | — | — | — |
| `refute.rhythm.graded.activity.r3__dark-1280` | ▲ new 70 [strong] | — | — | ▲ new 70 [strong] | — | — | — |
| `refute.rhythm.graded.activity.r4__dark-1280` | ▲ new 69 [ok] | — | — | ▲ new 69 [ok] | — | — | — |
| `refute.rhythm.graded.actor.r1__dark-1280` | ▲ new 25 [fail] | — | — | ▲ new 25 [fail] | — | — | — |
| `refute.rhythm.graded.actor.r2__dark-1280` | ▲ new 34 [fail] | — | — | ▲ new 34 [fail] | — | — | — |
| `refute.rhythm.graded.actor.r3__dark-1280` | ▲ new 69 [ok] | — | — | ▲ new 69 [ok] | — | — | — |
| `refute.rhythm.graded.coverage.r1__dark-1280` | ▲ new 68 [ok] | — | — | ▲ new 68 [ok] | — | — | — |
| `refute.rhythm.graded.coverage.r2__dark-1280` | — | — | — | ~ unstable (IQR 13.0) | — | — | — |
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
| `refute.typography.graded.coverage.r2__dark-1280` | — | — | — | — | ~ unstable (IQR 15.0) | — | — |

---

*Threat boundary: screenshot/DOM content sent to the Anthropic API during local scoring is dev-only tooling.
No production data. Opt-in via `ANTHROPIC_API_KEY`. See CONTRIBUTING.md "Local-only critic" section.*
