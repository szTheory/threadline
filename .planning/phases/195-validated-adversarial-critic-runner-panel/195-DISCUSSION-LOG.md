# Phase 195: Validated Adversarial Critic Runner & Panel - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-03
**Phase:** 195-Validated Adversarial Critic Runner & Panel
**Areas discussed:** Golden set & verdict format, Trust bar & agreement metric, Refute-test battery, Self-consistency N & cost budget

**Method:** User selected all 4 gray areas and requested deep parallel research (subagents) per area — pros/cons/tradeoffs, Elixir/Phoenix ecosystem idioms, lessons from analogous libs/apps, DX/UX and design lenses, `prompts/`+current-brandbook grounding — then one coherent, cohesive recommendation set. Four `gsd-advisor-researcher` agents ran in parallel; findings synthesized into D-01..D-04 with one cross-decision reconciliation. Everything already locked by Phase 194 (critic↔lens map, cube, cell-ids, invariants, reference bar) was carried forward, not re-asked.

---

## Golden set & verdict format (CRITIC-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Reference existing artifacts (scorecards + footguns + git A/B), coarse buckets + pairwise, blind test-retest, one JSON file | Low-friction solo oracle; defensible via intra-rater consistency | ✓ |
| Label all 120 Tier-A capture cells | Re-derives the cube by hand; unmaintainable for one person | |
| Fine-grained 1–100 human pointwise labels | High human variance; agreement % would measure labeler noise | |
| Purely synthetic known-bad primitives | Gameable/unrepresentative; kept only for refute-tests | |
| Per-lens verdict on every item × 6 lenses × 5 personas × 2 themes | ~840-label combinatorial explosion | |

**User's choice:** Research-and-recommend → adopted the referenced-artifact + coarse-bucket/pairwise + blind test-retest design, single `.planning/golden/golden-set.json`.
**Notes:** Report TWO numbers (pole-bucket ~100% + pairwise 75–90%). `held_out_ids` + `model_pin` seed Phase-196 true-north/drift-anchor. Every human label cites evidence (CRITIC-05 both directions).

---

## Trust bar & agreement metric (CRITIC-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-lens Krippendorff's α (ordinal) ≥ 0.67 as gate; raw ≥80% + pairwise ≥0.90 as recorded companions | Chance-corrected; resists the raw-92%/κ-0.07 inflation trap on the imbalanced set | ✓ |
| Raw % per-lens concordance as the gate | Interpretable but inflates on imbalanced golden set; rewards constant-guessing | |
| Spearman/Kendall on A/B pairs only | Validates ordering but no absolute calibration; used as a companion | |
| Cohen's κ | 2-rater only; unstable under skew; no missing-data support for sparse cube | |

**User's choice:** Research-and-recommend → α≥0.67 per-lens hard gate in `critic_trust` block, asserted by pure-Elixir `mix verify.critic_trust` (in `ci.all`); committed companions raw≥80% / pairwise≥0.90.
**Notes:** 80% not 90% (statistically indistinguishable at N≈40; 90% invites overfitting the validator). Rubric/model bump auto-invalidates a lens until re-scored. `hierarchy` (critic-only) is the highest-stakes gate.

---

## Refute-test battery (CRITIC-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Committed hand-authored A/B twins in `stress_fixtures.ex`; every twin passes mechanical gates; directional + margin pass bars; metamorphic invariance check | Deterministic, reviewable, proves the flaw is gestalt-only via `verify.mechanical` | ✓ |
| Runtime CSS-injection mutations | Second non-deterministic path; bypasses `style.ex` token auditing → kills the mechanical-passthrough proof | |
| Fold refute fixtures into the golden set | Contaminates the agreement metric; enables teaching-to-the-test | |

**User's choice:** Research-and-recommend → committed twins, 7-row catalog covering all 6 lenses + a veto-ordering row, separate manifest from the golden set.
**Notes:** Partition rule (mechanically-caught flaws are mechanical tests, not critic ones). Metamorphic transform (A/B swap + paraphrase) voids unstable verdicts. Fail → critic barred from any ledger bump; CI asserts the deterministic residue.

---

## Self-consistency N & cost budget (RUNNER-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Two-tier N (3→7 on no-majority/near-boundary); single Opus 4.8; band-majority + IQR/range variance rule; unstable→null; cache + changed-cell scoping | Cheap, stable, reproducible; ~$12–23 full / ~$0.45 scoped | ✓ |
| Fixed high N (e.g. 7 everywhere) | Wastes budget past the self-consistency plateau | |
| Split lenses across Sonnet/Haiku to cut cost | Gestalt judgment regresses on cheaper tiers; breaks one-model-id reproducibility lock | |
| Score unstable cells as 0 | Illegally registers as a monotonicity drop; poisons `min()` rollup | |

**User's choice:** Research-and-recommend → two-tier N, single Opus 4.8, `current: null` on instability, structural cost control.
**Notes:** Pricing verified against live docs. Footgun: cache prefix must exceed Opus's 4,096-token minimum or it silently won't cache; watch 5-min TTL on slow sweeps. Critic reads the curated Tier-B subset locally.

---

## Claude's Discretion

- Exact JSON field spelling in `golden-set.json` / `critic_trust` / refute manifest; Node runner module layout under `e2e/critic/`; test-name wording.
- Which 3 pages are the lowest-scoring golden mid-range targets (derive from live ledger at plan time).
- α-bootstrap CI method / library (or hand-rolled dependency-light pure-Elixir ordinal α); must be deterministic.
- Rubric on-disk format (markdown vs JSON) and per-dimension wording.

## Deferred Ideas

- Forward-only net-positive gate + auto-apply + first proven improvement — Phase 196 (this phase only validates the critic).
- Coverage growth + v1.37-style adversarial closeout + design-debt register — Phase 197.
- Full multi-theme × multi-breakpoint critic sweep — deferred; 195 critiques the curated Tier-B subset locally.
- Splitting lenses across cheaper model tiers — considered and rejected; revisit only if 197-scale cost demands it.
