<!-- GENERATED — do not hand-edit. Regenerate: npm run critic:score -->
<!-- Baseline: @v1.37 → @HEAD -->
<!-- Last regenerated: 2026-07-04 -->

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

*(No scores yet. Run `critic label --bootstrap` then `npm run critic:score` to populate.)*


---

*Threat boundary: screenshot/DOM content sent to the Anthropic API during local scoring is dev-only tooling.
No production data. Opt-in via `ANTHROPIC_API_KEY`. See CONTRIBUTING.md "Local-only critic" section.*
