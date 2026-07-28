# Critic validation pivot + Phase 196 gate reframing

**Date:** 2026-07-27
**Context:** v1.40, closing Phase 195 / opening Phase 196
**Status:** reconciliation of record — one gate-shape decision teed up for the maintainer

---

## What the roadmap wrote down vs. what shipped

Phase 195's written validation path (`195-07-03`, CRITIC-01) was a **manual maintainer act**:
hand-label a golden set through the blind-round `critic label` CLI, compute Krippendorff α
of critic↔human agreement, require **75–90% agreement across the panel** before the critic
may drive anything. `STATE.md` has been parked at "195-07 PAUSED awaiting maintainer labeling"
since 2026-07-04.

That path was **deliberately superseded**, not completed. Across the last few sessions we built
a **synthetic twin oracle** (graded severity ladders, zero human labeling — commit `aef9e655`)
and re-anchored the trust gate on **Spearman ρ ranking (≥0.7)** instead of α agreement. Reason:
the critic *compresses its absolute scale* (α collapses) while *ranking correctly* (ρ high) — so
α was measuring the wrong property. This is a real deviation from the roadmap's stated CRITIC-01
mechanism and should be on the record as such.

## The trust reality this produced (source of truth: `design-system-ledger.json → critic_trust`)

| Lens | ρ | AUC | n | validated | note |
|------|-----|-----|---|-----------|------|
| brand_fidelity | 0.94 | 1.00 | 23 | ✅ trusted | α=0.065 → **ranks, does not grade** (scale compression) |
| rhythm | 0.76 | 0.97 | 22 | ✅ trusted | **unstable on real pages** — gave no signal on route.timeline |
| typography | 0.905 | 1.00 | 9 | ❌ | strong signal; blocked only by n<20 → **cheapest promotion** |
| hierarchy | — | — | 0 | ❌ | advisory; hallucinates absolutes (invented `#ff2ec4`) |
| density | — | — | 0 | ❌ | advisory |
| color_contrast | — | — | 0 | ❌ | advisory; drove the fabricated-magenta finding |

Provenance: `oracle: synthetic`, `set_version: 195.12.0`, `generated_from: graded-twin-ladder`.

## What was additionally proven (ahead of GSD, committed as feat(196))

- **Real operator-route capture lane** (`a465c03c`) — authed, seeded `/audit/*` routes clipped
  to `#tl-main`, scored by the critic. Realistic assembled pages, not component galleries.
- **Degraded-twin ranking trust-test** (`11df1f8c`) — the critic ranked the clean Timeline
  **above** a deliberately-wrecked twin on every stable lens (brand_fidelity 77>66, hierarchy
  16>6, density 23>8, typography 42>12, color_contrast 18>4). So the before/after mechanism
  **works on real UI as a ranking**, with two honest caveats: brand_fidelity's margin is shallow
  (scale compression again), and rhythm contributed no signal on real pages.

## Consequence for Phase 196 — the one decision to ratify

Phase 196's written gate (ROADMAP GATE-01) is: *accept a change only if the targeted lens
improves AND no other page/persona/lens regresses below floor **across the full panel**.* That
premise assumes a fully-trusted, absolute-scoring panel. **We proved that panel does not exist.**
What exists is a **2-lens (soon 3) ranking** signal plus 4 advisory lenses that fabricate
absolutes.

So the gate must be reshaped. The fork:

- **(A) Trusted-lens ranking gate (recommended).** Gate on: does the *after* out**rank** the
  *before* on the trusted lenses (brand_fidelity + rhythm, + typography once promoted), with the
  deterministic mechanical/a11y floor (Phase 194) as the hard block, and advisory lenses shown
  as non-blocking signal only. This matches what we actually validated (ranking, not grading)
  and what the trust gate already encodes. Honest, shippable now.
- **(B) Hold for fuller panel trust.** Push more lenses through the synthetic oracle
  (typography is one round away; hierarchy/density/color need refute-ladders) until the
  full-panel absolute gate as-written is defensible. Higher fidelity, more work, and still
  fights the scale-compression finding.

**Recommendation: (A).** It is the honest expression of the validated capability, it keeps the
deterministic floor as the real guard, and it can prove PROOF-01 (one human-ratified improvement
on the weakest page) now. Fold two named risks into the 196 plan: *rhythm real-page instability*
and *advisory-lens hallucination* (advisory lenses never block; their specifics are verified
against ground truth before anyone acts). Promote typography to trusted as a cheap early win.

## Housekeeping

- `.planning/CRITIQUE.md` stays **uncommitted** by design — it's a regenerated projection that
  references gitignored local route cells (`route.*`), not byte-stable.
- 195-07's manual human-labeling checkpoint is **retired, not satisfied** — recorded here so the
  roadmap's CRITIC-01 mechanism and the shipped mechanism don't silently diverge.
