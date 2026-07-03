# Phase 195: Validated Adversarial Critic Runner & Panel - Context

**Gathered:** 2026-07-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a **local-only Claude-vision critic panel** over the deterministic capture/scorecard substrate shipped in Phase 194, and — the linchpin — **prove it trustworthy against a hand-labeled golden set before it may drive any ratchet.** The panel is one critic per persona (P1–P5) + a graphic-design critic + a brand-veto critic; each score cites concrete evidence (screenshot region / DOM selector / mechanical output line) or is discarded; the runner runs behind `mix verify.ui_critique`; and validation (refute-tests + a documented critic↔human agreement bar) gates whether the critic is allowed to feed the Phase-196 forward-only gate.

**Requirements:** CRITIC-01..05, RUNNER-01..05 (see `.planning/REQUIREMENTS.md`).

**In scope:** the golden set + maintainer verdict format; versioned anchored per-lens rubrics; the Node critic runner in `e2e/critic/` (Claude vision, JSON-schema structured output, prompt-cached rubric+anchor prefix, one dimension per call, N-sample self-consistency, model-id+rubric-version stamped); the 7-critic panel with brand/token veto ordering; the refute-test battery; the trust-bar gate (`critic_trust` block + `mix verify.critic_trust`); `mix verify.ui_critique` as the local-only named entrypoint.

**Out of scope (later phases):** the forward-only net-positive gate + auto-apply + first proven improvement (196); coverage growth + adversarial closeout + debt register (197).

**Locked milestone invariants (do not revisit — carried from Phase 194):** No root `mix.exs` runtime dep — the Anthropic SDK is a `devDependency` of `examples/threadline_phoenix/e2e/package.json` ONLY; `verify.compile_no_optional` still proves `threadline` stays Phoenix-optional. No public component / "design-eval" API — dev/maintainer tooling only. `mix verify.ui_critique` requires `ANTHROPIC_API_KEY`, no-ops without it, is EXCLUDED from `mix ci.all`, and is documented local-only under a doc-contract lock (the `verify.flake` precedent). Capture/query/auth semantics untouched. Reference bar: **Linear (primary)** + Vercel/Stripe/Grafana (secondary/cautionary). No external SaaS visual-diff tool names in committed copy.

**Locked from Phase 194 (build ON these, do not re-derive):**
- **Critic↔lens map (194 D-01, FROZEN):** persona critics P1–P5 → score `hierarchy` + `density`; graphic-design critic → `rhythm` / `typography` / `color_contrast`; brand-veto critic → `brand_fidelity`. **Persona is a weight, never a lens ×5 multiplier.** The 6 lenses are frozen: `hierarchy · density · rhythm · typography · color_contrast · brand_fidelity`.
- **Cube & evidence:** sparse `page × persona × lens` scorecard cube (14 lens-cells/page); `min()` rollups; conservative-`unrated` seeding; evidence-on-gain; cell-id `{ledger_id}__{theme}-{breakpoint}`; committed diffable scorecard JSON in `.planning/scorecards/` (174 already committed); gitignored regenerable PNGs.
- **Score scale:** 0–100 with anchored evidence bands; bumps quantized to bands (existing ledger uses 25 / 62→72→90).
- **Mechanical layer already catches** token-grid/WCAG/control-count/card-nesting/scroll-cost/type-size/accent violations (MODE A hard-block, MODE B ratchet-floor). **The critic judges GESTALT only.** Brand/token veto fires before aesthetic scoring (RUNNER-03).

</domain>

<decisions>
## Implementation Decisions

These 4 decisions were synthesized from parallel research across all four gray areas (see DISCUSSION-LOG.md) and locked as one internally-consistent set. **Coherence spine:** the golden set is the *oracle*; the trust bar is a *chance-corrected, per-lens gate* computed from it; the refute battery is a *separate adversarial suite* that stress-tests gestalt-only judgment the mechanical layer can't catch; self-consistency + variance-flagging keep the nondeterministic judgment honest and cheap. Everything rides the Phase-194 capture cell — persona × lens are judgments over the *same* pixels, never a multiplier on the capture matrix.

### D-01: Golden set composition & maintainer verdict format (CRITIC-01)
- **Reference existing artifacts, never new captures.** The golden set is a single committed `.planning/golden/golden-set.json` whose items *pin* to already-committed Tier-A scorecard cells (`.planning/scorecards/*.json`), the real `footgun.*` fixtures (poles), polished `primitive.*`/v1.38 pages (poles), and **real git before/after A/B pairs** (`page.X@v1.37` vs `@HEAD`). Synthetic degradations are reserved for the refute battery (D-03), NOT the golden set.
- **Verdict format — coarse buckets + pairwise, never fine pointwise.** Maintainer labels `good/borderline/bad/broken` buckets and, for pairs, `better/worse` + `margin` (`clear`/`subtle`). Humans are noisy at 1–100 pointwise and reliable at buckets/ranks — a pointwise "agreement %" would mostly measure the labeler's own noise.
- **Every human label cites evidence** (a region / DOM selector / mechanical line) — CRITIC-05 applies to the oracle too, or the item is discarded.
- **Blind test-retest makes solo labels defensible.** Label each item twice with IDs masked (`relabel.r1`/`r2`, `blind: true`); keep only items whose two rounds agree (intra-rater consistency = the solo analog of inter-rater agreement).
- **Sizing (see reconciliation below): ~50 golden capture cells → ≥20 lens-judgments per critic-bearing lens.** Each golden cell is labeled on *all* its applicable lenses (persona × lens = judgments over the same pixels), so one cell contributes to multiple lens sample-counts. Composition: ~6 pole anchors (3 footguns + 3 polished, dark+light where contrast/brand differ), ~15 real A/B pairs (≥2 per lens; ≥1 persona-conflict pair), ~12+ mid-range cells across the 3 lowest-scoring target pages (so agreement is measured off the easy poles), plus `held_out_ids` (frozen true-north slice for Phase 196, never rubric-tuned) and `model_pin`/`rubric_rev` provenance.
- **Guard test** (pure Elixir) asserts: every referenced cell resolves to a committed scorecard; every item has non-empty evidence; `r1 == r2` (mismatches dropped).

### D-02: Trust bar & critic↔human agreement metric (CRITIC-03)
- **Gate = per-lens Krippendorff's α (ordinal) ≥ 0.67**, computed treating the maintainer's golden label and the critic's *median* self-consistency score as two raters over each lens's applicable golden cells. Chance-corrected so the imbalanced golden set (footguns ≈ all-fail, primitives ≈ all-pass) can't inflate the number — the documented trap is raw-92.6% co-existing with κ-0.07 ("always-bad" critic passes a raw bar, learns nothing). α exposes it.
- **Committed companions (recorded, NOT gating):** `raw_agreement ≥ 80%` (this is the roadmap's "75–90%" documented threshold — **80%, not 90%**: at N≈30–50 the 95% CI is ±0.12–0.20 so 90% is false precision that pressures overfitting the validator; human–human ceilings on subjective design sit at α≈0.67–0.80) and `pairwise_acc ≥ 0.90` on the clear-margin A/B + injected pairs.
- **Granularity = per-lens; every critic-bearing lens clears its own bar** (mirrors the cube's `min()` discipline — no global aggregate pass, no averaging a weak lens into passing). `hierarchy` is critic-only (no mechanical backstop) → highest-stakes gate. Validate at the **lens** the ratchet acts on, not per-critic (P1–P5 all feed hierarchy+density; per-critic splitting fragments N).
- **Block mechanism = per-lens hard gate.** A new `critic_trust` block in `design-system-ledger.json` holds per lens `{alpha, raw_agreement, pairwise_acc, n, ci95, golden_rubric_version, model_id, validated}`. `mix verify.critic_trust` (pure Elixir, `async: true`, no LLM/no network — mirrors `stress_ledger_test.exs`; folded into `ci.all`) asserts: for any lens with `validated: true` → `alpha ≥ 0.67 AND n ≥ 20 AND raw_agreement ≥ 80 AND golden_rubric_version == <current> AND model_id == <current>`. Phase-196 permits a judged-lens floor bump only if that lens's `validated == true`.
- **Re-validation on rubric/model bump is automatic.** Every scorecard already stamps `rubric_version` + `model_id`; the guard fails if a lens ratchets under a rubric/model version newer than the one it was validated at → a rubric/model bump auto-invalidates that lens's trust until the golden set is re-scored and α recomputed (silent-loosening protection).

### D-03: Refute-test battery & injected-regression catalog (CRITIC-02)
- **Committed hand-authored A/B twins**, extending the `footgun.*` / `reserved_for_phase` idiom in `stress_fixtures.ex` (reject runtime CSS-injection as the primary mechanism — a second non-deterministic mutation path, and it bypasses the `verify.mechanical` proof below). ~8 fixtures is trivially hand-authorable.
- **The partition rule (load-bearing):** every VLM refute-regression must PASS all mechanical gates (MODE A + MODE B). Doubled padding jumps token-step to token-step (16→32, both on-grid); the nested card stays under the depth-3 ceiling; the mis-jobbed accent uses a real `--tl-*` token in the wrong job. **If a flaw trips mechanics, it is a mechanical refute-test, not a critic one** (no duplication of the deterministic layer).
- **Catalog (each twin = polished + one injected flaw):** doubled section padding → `rhythm`; card-wrapping-a-section → `density` (+ brand card-rule); flattened hierarchy (equal weights/sizes) → `hierarchy` (purest VLM test, no mechanical backstop); type-scale collapse (2 sizes 1px apart, count under floor) → `typography`; mis-jobbed accent (Ember as default action) → `brand_fidelity`; chrome bloat (redundant help copy) → `density` (resists verbosity bias); off-token raw-hex accent → **veto-ordering test** (trips token-parity veto → critic emits NO aesthetic score, confirming RUNNER-03 ordering).
- **Pass bars = two-tier:** binary directional gates (correct rank/sign AND correct lens attribution with located evidence) that ALL must pass, plus a **margin gate** — A/B delta and footgun-vs-polished gap must exceed the critic's measured noise floor (not a drift-brittle absolute threshold).
- **Metamorphic invariance check:** a verdict that flips under A/B order-swap or microcopy paraphrase is **void** (guards positional/verbosity false-passes).
- **Refute set ≠ golden set** (separate manifests): golden measures human agreement on representative states; refute measures sign/attribution on synthetic extremes. Never fold refute fixtures into the agreement metric (no teaching-to-the-test). Wired into `mix verify.ui_critique` as a gate on the critic (fail → critic barred from writing any ledger bump); CI asserts the deterministic *residue* — each refute fixture renders, passes `verify.mechanical`, has a committed evidence bundle + last-known transcript.

### D-04: Self-consistency N, variance policy & run-cost (RUNNER-02)
- **Two-tier N: first pass N=3, escalate to N=7 only on cells with no strict majority band or sitting ~≤5 pts from a floor/target boundary.** Self-consistency plateaus fast (Wang et al.); Opus 4.8 removed `temperature`/`top_p`/`top_k` (they 400), so variance is inherent stochasticity — small and cheap to average out.
- **Single model — Opus 4.8 (`claude-opus-4-8`) for every judged lens**, stamped per scorecard. Do NOT split lenses across Sonnet/Haiku: gestalt judgment (hierarchy/density/brand feel) is exactly where cheaper tiers regress, and a mixed model set fractures the one-model-id-per-rubric reproducibility lock. Brand-veto is mechanical token-parity → $0 LLM.
- **Variance/instability rule (on the 0–100 scale, before band-quantization):** flag a cell **unstable → not ratcheted** when band-mode < ⌈N/2⌉ (no strict majority band — the primary rule, and the escalation trigger) OR raw IQR > 10 OR min–max range > 15. **An unstable cell keeps `current: null` — NEVER 0** (0 would illegally register as a monotonicity drop and poison the `min()` rollup); it is excluded from the Phase-196 net-positive calc (neither gain nor regression) and surfaces as "re-run or human-adjudicate."
- **Cost control is structural, not model-downgrade:** prompt-cache the rubric+anchor prefix (locked); scope runs to changed cells + their shared-token blast radius; operate on the curated **Tier B** subset locally. Budget: ~$12 (full sweep, 1 theme/bp) → ~$23 (× dark+light) → ~$0.45 (scoped single change). **Footgun: the cache prefix must exceed Opus's 4,096-token minimum or it silently won't cache** (`cache_read_input_tokens: 0`) and every call pays full input — pad/verify the prefix; also watch the 5-min cache TTL on slow sequential sweeps (batch tightly / pre-warm).

### Reconciliation (the one cross-decision tension resolved)
- **Per-lens N (D-02) vs golden-set size (D-01):** the trust metric wants **≥20 labeled judgments per critic-bearing lens** for α stability; a ~40-item set tagged one-lens-per-item gives only ~7/lens. **Resolution:** label each golden capture cell on *all* its applicable lenses (persona × lens are judgments over the same pixels — the cube's core invariant), landing **~50 golden cells → ~120+ lens-judgments**, ≥20 per critic-bearing lens. A lens that cannot reach N≥20 gets a `provisional` flag that blocks *that lens's* ratchet until it does (never a silent pass).

### Rubric authoring (CRITIC-04) — coherence note
- Rubrics are **versioned, committed, one per lens**, each dimension phrased as an adversarial pass/fail with a written pass condition + a reference-bar anchor (Linear primary; Vercel/Stripe/Grafana secondary by surface). The **anchor is a textual descriptor + a committed reference note, never a scraped Linear number** (scraping violates no-network + is Goodhart bait). `rubric_version` is stamped on every scorecard and is the cache-key + the auto-invalidation trigger in D-02. Exact rubric on-disk format (markdown vs JSON) and dimension wording = planner's call, consistent with the `stress_ledger_test.exs` / brandbook idiom.

### Claude's Discretion
- Exact JSON field spelling in `golden-set.json`, `critic_trust`, and the refute manifest (beyond the locked shapes above); precise Node runner module layout under `e2e/critic/`; test-name wording — planner/executor choose, consistent with existing conventions.
- Which 3 pages are the "lowest-scoring targets" for golden mid-range cells — derive from the current ledger scores at plan time (same call as Phase 194's Band-2 targets).
- The exact α-bootstrap CI method and library (or a hand-rolled pure-Elixir ordinal α) — planner's call; must be deterministic and dependency-light.
- Rubric on-disk format (markdown vs JSON) and per-dimension wording.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap (locked scope)
- `.planning/REQUIREMENTS.md` — CRITIC-01..05, RUNNER-01..05 (this phase); GATE/PROOF (Phase 196/197, for coherence — the trust gate must genuinely block the 196 ratchet).
- `.planning/ROADMAP.md` — Phase 195 goal + 5 success criteria; dependency spine (critic must be validated before it drives the ratchet); Phase 196 GATE-03/04 (held-out true-north + human sign-off) this phase seeds.
- `.planning/PROJECT.md` — milestone goal, locked decisions, reference bar, "code computes the number / VLM judges the gestalt" split.

### The Phase-194 substrate being extended (READ FIRST)
- `.planning/phases/194-deterministic-scorecard-cube-ledger-mechanical-capture-found/194-CONTEXT.md` — **the frozen cube model**: 6-lens taxonomy, critic↔lens map, cell-ids, evidence storage, MODE A/B mechanical catalog + mechanical→lens map + veto ordering, 0–100 anchored bands, `ratchet.signoffs`. Everything in this phase builds on it.
- `.planning/design-system-ledger.json` — `version: 2` cube; adds the new `critic_trust` block this phase.
- `test/threadline/operator_surface/stress_ledger_test.exs` — the pure-Elixir guard idiom `mix verify.critic_trust` mirrors (monotonicity, key-set, `ratchet.resets`, forbidden terms).
- `.planning/scorecards/*.json` — 174 committed Tier-A scorecards; the golden set pins to these cell-ids.

### Research (methodology grounding)
- `.planning/research/SUMMARY.md` — the linchpin framing (validate the critic before it drives anything), determinism-without-temperature (finding #5), N-sample self-consistency.
- `.planning/research/PITFALLS.md` — CRIT-3/4/5/7 (veto ordering, VLM mis-measures pixels, verbosity bias), FWD-2 (held-out true-north, Goodhart-on-the-validator).
- `.planning/research/ARCHITECTURE.md` — 0–100 anchored bands, N-sample median vote, band quantization.

### Personas & brand (rubric anchoring source)
- `.planning/milestones/v1.31-PERSONAS-IA.md` — personas P1–P5 + JTBD J1–J11 (P1 Incident Responder, P2 Support Agent, P3 Compliance Reviewer, P4 Audit-Operator/SRE, P5 Adopter Dev); the per-persona rubric authority.
- `brandbook/brand-book.md` — **CURRENT** brand book (radius ≤8px cap, "cards for repeated items not sections", 5-accent "two blues two jobs" palette, "color as signal not decoration") — anchors the graphic-design + brand-veto rubrics and the refute fixtures. **Prefer over `prompts/Threadline Brand Book.txt`.**
- `brandbook/pressure-test.md` — the "self-assessment is banned; every score cites a mechanical output" doctrine (CRITIC-05 lineage).

### Capture lane + runner substrate
- `lib/threadline/operator_surface/stress_fixtures.ex` + `.../live/stress_live.ex` — DB-free fixture surface; the `footgun.*` / `reserved_for_phase` idiom the refute twins extend.
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` + `playwright.config.ts` + `package.json` — capture lane, determinism helpers, and the `e2e/` package where the Anthropic SDK devDependency + `e2e/critic/` runner land.
- `mix.exs` — the `verify.flake` alias (`mix.exs:109`) is the local-only / excluded-from-`ci.all` precedent for `verify.ui_critique`.

### Engineering conventions
- `prompts/threadline-elixir-oss-dna.md` — named `mix verify.*`/`ci.*` entrypoints, honest-default tests, doc-contract locks.
- Claude API: Opus 4.8 = `claude-opus-4-8` ($5/$25 per MTok, vision GA, temperature/top_p removed, prompt-cache 0.1× read / 1.25× write, 5-min TTL, **4,096-token minimum cacheable prefix**). Verify against live docs / `claude-api` skill, not memory.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`stress_ledger_test.exs` guard mechanics** — the pure-Elixir monotonicity/key-set/`ratchet.resets` idiom is the template for `mix verify.critic_trust` (reads the committed `critic_trust` block, no LLM → safe in `ci.all`).
- **174 committed scorecards + the cube** (`.planning/scorecards/`, `design-system-ledger.json` v2) — the golden set references these cell-ids; the runner writes lens scores onto the same cells.
- **`footgun.*` / `reserved_for_phase` fixtures in `stress_fixtures.ex`** — the poles for the golden set and the base for the refute twins; already byte-stable via the Phase-194 capture determinism.
- **`verify.flake` local-only lane** (`mix.exs`) — the exact precedent for `verify.ui_critique` (requires an env var, no-ops without, excluded from `ci.all`, doc-contract-locked).
- **`e2e/package.json` + Playwright lane** — where the Anthropic SDK devDependency and the `e2e/critic/` Node runner attach; capture already emits the Tier-B curated subset the critic reads.

### Established Patterns
- **Committed diffable JSON + pure-Elixir freshness/monotonicity guard** — golden set, `critic_trust`, and refute manifest all follow the ledger's small-diffable-text pattern (no binaries; `File.exists?` for refs).
- **Named `mix verify.*` entrypoints** — `verify.ui_critique` (local, LLM) + `verify.critic_trust` (CI, pure-Elixir) follow the convention; only the pure-Elixir one folds into `ci.all`.
- **Mechanical / LLM split** — mechanical checkers are the ratchet floor and the CRITIC-05 evidence substrate; the critic judges gestalt only and never re-tests what mechanics catch.

### Integration Points
- New `.planning/golden/golden-set.json` (oracle) + new `critic_trust` block in `design-system-ledger.json` (gate) + new refute manifest + fixtures in `stress_fixtures.ex`.
- New `examples/threadline_phoenix/e2e/critic/` Node runner (Anthropic SDK devDependency, prompt-cached rubric prefix, structured output, N-sample median, per-cell stamping).
- New `mix verify.ui_critique` (local) + `mix verify.critic_trust` (into `ci.all`); versioned rubric files (one per lens).

</code_context>

<specifics>
## Specific Ideas

- **Report TWO agreement numbers, not one fuzzy %:** pole-bucket accuracy (must be ~100% — the critic MUST nail clear-cut cases) and the chance-corrected per-lens α (the real trust gate) + raw-80% companion. A single pointwise % at N≈40 carries a ±0.15 CI and would report the labeler's noise.
- **The oracle is held to the same bar as the critic:** every human golden label cites a region/selector or is discarded (CRITIC-05 both directions); blind test-retest is what makes one maintainer's labels defensible.
- **Reference-anchoring, not adjectives:** rubrics anchor to Linear (primary) via textual descriptors + committed reference notes — never a scraped number (no-network + Goodhart bait).
- **Unstable ≠ bad:** a high-variance cell is "unknown" → `current: null`, excluded from the net-positive calc; scoring it 0 poisons the `min()` rollup.

</specifics>

<deferred>
## Deferred Ideas

- **The forward-only net-positive gate + auto-apply + first proven improvement** — Phase 196 (this phase only *validates* the critic; it does not wire it to drive changes). The `held_out_ids` true-north slice and `model_pin` drift-anchor are seeded here for 196.
- **Coverage growth to the next-lowest pages + v1.37-style adversarial closeout + design-debt register** — Phase 197.
- **Full multi-theme × multi-breakpoint critic sweep** — deferred; Phase 195 critiques the curated Tier-B subset locally (cost + focus). Full sweep economics documented in D-04 for when 197 expands coverage.
- **Splitting lenses across cheaper model tiers** — considered and rejected (gestalt judgment regresses on cheaper tiers; breaks the one-model-id reproducibility lock). Revisit only if cost becomes prohibitive at 197 scale.

None of the above are scope creep — they are the explicitly-sequenced later phases of v1.40.

</deferred>

---

*Phase: 195-Validated Adversarial Critic Runner & Panel*
*Context gathered: 2026-07-03*
