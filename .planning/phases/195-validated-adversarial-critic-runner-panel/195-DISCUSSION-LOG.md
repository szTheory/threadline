# Phase 195: Validated Adversarial Critic Runner & Panel - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-03
**Phase:** 195-Validated Adversarial Critic Runner & Panel
**Areas discussed:** Golden set & verdict format, Trust bar & agreement metric, Refute-test battery, Self-consistency N & cost budget (round 1 → D-01..D-04); Per-lens rubric design, Panel orchestration & cube merge, Runner architecture & schema, Critic report surface & JTBD (round 2 → D-05..D-08).

**Method:** Two rounds of deep parallel research (subagents), each round dispatching four `gsd-advisor-researcher` agents grounded in the locked 194/195 decisions + `prompts/`/current-brandbook + external best practice, then synthesized into one coherent set. Round 1 (oracle/trust side) → D-01..D-04. Round 2 (build/DX side) → D-05..D-08, grounded in the round-1 locks so everything coheres. Everything already locked by Phase 194 (critic↔lens map, cube, cell-ids, invariants, reference bar) was carried forward, not re-asked.

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

## Per-lens rubric design (CRITIC-04) — round 2

| Option | Description | Selected |
|--------|-------------|----------|
| Markdown rubric/lens, 2–3 gestalt dimensions (13 total), adversarial pass conditions, prose + 2-pole anchors, per-lens semver+hash | Tight, anchorable, cache-coherent, per-lens auto-invalidation | ✓ |
| One dimension per lens | Too coarse; can't isolate what regressed | |
| Global rubric version | Editing one lens needlessly re-invalidates all → violates per-lens D-02 | |
| Embed mid-range/held-out golden cells as few-shot | Leaks the agreement metric / true-north set | |

**User's choice:** Research-and-recommend → D-05. **Notes:** dimensions target only gestalt the mechanics can't measure (no duplication); poles-only few-shot doubles as anti-flattery anchor + pushes prefix past the 4096-token cache floor.

## Panel orchestration & cube merge (RUNNER-03) — round 2

| Option | Description | Selected |
|--------|-------------|----------|
| Blind cell-writers; brand-veto is mechanical pre-gate that nulls + skips vision; preserve persona disagreement via min() | Honest, no averaging, no poisoning of min() | ✓ |
| Aggregate/average persona critics into one score | Destroys the JTBD divergence the cube exists to expose | |
| Let critics read each other's cells | Re-introduces anchoring/averaging; breaks independence | |
| Write vetoed cell as 0 | Registers as a monotonicity drop; poisons min() | |

**User's choice:** Research-and-recommend → D-06. **Notes:** persona clause sits after the cache boundary so all 5 personas reuse one cached lens prefix; veto and unstable both write null, distinguished by a flag.

## Runner architecture & schema (RUNNER-01) — round 2

| Option | Description | Selected |
|--------|-------------|----------|
| TS CLI in e2e/critic/; messages.parse() structured output; evidence required at schema layer; scores land in SEPARATE .planning/critic-scores/ | Coheres with capture lane; keeps deterministic bundle pristine; CRITIC-05 enforced structurally | ✓ |
| Write LLM scores into the committed .planning/scorecards/ | Churns byte-stable diffs; nondeterministic producer mutates the CI-guarded bundle | |
| Plain JS, no schema-level evidence enforcement | Loses the single-source-of-truth + CRITIC-05 guarantee | |

**User's choice:** Research-and-recommend → D-07. **Notes:** SDK strips numeric bounds → clamp score client-side; verdict cache {cell,dimension,rubric_hash,model_id} gives resumability; guard asserts critic never writes under scorecards/.

## Critic report surface & JTBD — round 2

| Option | Description | Selected |
|--------|-------------|----------|
| Three surfaces: JSON truth + terminal glance + committed CRITIQUE.md projection (primary, reuses DESIGN-SYSTEM.md mechanic); Betterer idiom; symbol+text signals | Reviewable in PRs, accessible, no new surface invented | ✓ |
| Build a LiveView/HTML dashboard | Violates dev/test-only + no-public-surface invariant | |
| Terminal output only | No diffable audit trail for the ratchet decision | |
| Render null as 0 or `—` | "Unknown" reads as "bad"; maintainer ratchets on noise | |

**User's choice:** Research-and-recommend → D-08. **Notes:** each finding suggests a direction, never an auto-fix (that's Phase 196); no-flattery microcopy; unstable/vetoed/untrusted signals are symbol+word+reason, never color-only; deltas always state their baseline.

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
