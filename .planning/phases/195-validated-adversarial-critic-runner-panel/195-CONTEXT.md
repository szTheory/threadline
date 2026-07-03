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

These 11 decisions were synthesized from three rounds of parallel research (see DISCUSSION-LOG.md) and locked as one internally-consistent set — **D-01..D-04 the oracle/trust side; D-05..D-08 the build/DX side; D-09..D-11 the authoring/coupling/prompt side.** **Coherence spine:** the golden set is the *oracle*; the trust bar is a *chance-corrected, per-lens gate* computed from it; the refute battery is a *separate adversarial suite* that stress-tests gestalt-only judgment the mechanical layer can't catch; self-consistency + variance-flagging keep the nondeterministic judgment honest and cheap; the rubrics phrase every judgment as an adversarial pass/fail anchored to named systems; the panel writes blind per-cell scores that a projection surfaces to the maintainer. Everything rides the Phase-194 capture cell — persona × lens are judgments over the *same* pixels, never a multiplier on the capture matrix.

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

### D-05: Per-lens rubric design, dimensions & anchoring (CRITIC-04)
- **One committed markdown rubric per lens** (`e2e/critic/rubrics/<lens>.md`), each holding **2–3 gestalt-only dimensions — 13 total across the 6 lenses.** Tight by design: dimension bloat / un-anchorable catch-alls are the #1 rubric footgun (194 D-01). Every dimension is scored in its own vision call ("one dimension per call", RUNNER-01).
- **Each dimension = an adversarial pass/fail the critic tries to FAIL**, with a *written* pass condition, and must cite a region/selector/mechanical line (CRITIC-05) or be discarded. Dimensions target only the **gestalt the mechanics can't measure** (no duplication of px/ratio/count — those are the evidence floor, not the judgment). The decomposition:
  - `hierarchy` (critic-only, highest-stakes): entry-point clarity · scan-path/reading-order · emphasis discipline. *(e.g. entry-point PASSES iff, shown cold, you can name the one element the eye lands on first AND it's what this persona's JTBD needs first; FAIL if ≥2 compete or the primary isn't task-primary.)*
  - `density` (persona-weighted): signal-to-chrome · task-primary prominence. *(FAIL if you can name a control/chrome block whose removal costs the primary task nothing — resists verbosity bias.)*
  - `rhythm`: grouping-by-proximity · vertical-cadence coherence.
  - `typography`: role differentiation · scale-expresses-hierarchy. *(role, not size-count — that's mechanical.)*
  - `color_contrast`: color-as-signal · accent-job discipline. *(every hue maps to a documented job: Thread Blue = interface action, Signal Cyan = correlation, Ember = diff-emphasis not warning.)*
  - `brand_fidelity` (post-veto): designed-not-recolored · register/voice fit. *(FAIL if it reads as a mechanical recolor or drifts to generic-AI/marketing chrome.)*
- **Anchoring WITHOUT scraping:** each rubric carries a `## Reference bar` prose block ("Linear packs primary + secondary metadata per row with one accent doing one job — match that signal-to-chrome"), routed by surface (Linear primary for hierarchy/density/rhythm; Vercel/Stripe for typographic restraint + accent discipline; Grafana cautionary for high-density), plus an `## Anchors` block naming **one pass-pole + one fail-pole golden cell-id** (`primitive.*`/v1.38 vs `footgun.*`). Never a scraped Linear pixel/number (no-network + Goodhart bait).
- **Versioning = per-lens `<lens>@<semver>+<sha8>`.** The `sha8` (hash of the committed rubric bytes) is the machine key = prompt-cache key = D-02 auto-invalidation trigger; semver = human intent (patch=wording, minor=+dimension, major=redefine). **Per-lens, not global** — editing `hierarchy` never forces re-labeling `typography`. A pure-Elixir guard recomputes the hash from disk and asserts stamped == current.
- **Few-shot = the two poles only, embedded in the cached prefix.** Bare rubric prose (~2–2.5k tokens) sits *under* Opus's 4,096-token cache floor (D-04) — the two evidence-annotated poles are load-bearing padding that pushes it over AND serve as the anti-flattery anchor. **Never embed mid-range golden cells** (that's where D-01 measures agreement) or **`held_out_ids`** (Phase-196 true-north). A pure-Elixir guard asserts `prefix_exemplar_ids ∩ (mid_range ∪ held_out) = ∅`. Cached prefix per lens = rubric + reference-bar + 2 poles; only the per-cell screenshot + mechanical evidence is the uncached suffix.

### D-06: Panel orchestration, persona-weighting & cube merge (RUNNER-03)
- **Each critic is a blind, pure cell-writer:** every call targets exactly one `{persona}.{lens}` key on one capture cell and writes only that key — **no critic ever sees another's output** (blindness preserves the "independent judgments over the same pixels" invariant; sibling-reading re-introduces anchoring/averaging).
- **Critic → cell mapping (confirms 194 D-01; 14 lens-cells/page):**

  | Critic | Writes | persona | LLM? |
  |---|---|---|---|
  | P1–P5 (one each) | `p{n}.hierarchy`, `p{n}.density` | p1..p5 | yes |
  | Graphic-design | `all.rhythm`, `all.typography`, `all.color_contrast` | all | yes |
  | Brand-veto | `all.brand_fidelity` | all | **no — mechanical token-parity** (then a brand *gestalt* vision call scores the lens only if the veto passes) |

  = 10 persona lens-cells + 4 invariant = **14/page**. "Persona is a weight, not a ×5 multiplier" is honored *because* hierarchy/density are stored per-persona (P1 and P3 judge the same pixels against different pass conditions), with `min()` as the aggregator — not one score multiplied ×5.
- **Veto pipeline (ordered, per capture cell, before any aesthetic vision call):** (1) run `verify.mechanical` (MODE A + B, deterministic, $0); (2) `--tl-*` token-parity / dark↔light parity **brand veto** (MODE A); (3) **on veto** → write `all.brand_fidelity = {current: null, vetoed: true, evidence: <mechanical line>}` and **skip ALL aesthetic vision calls for that cell** (persona *and* graphic-design) — a change that breaks the brand envelope earns no aesthetic credit and cannot ratchet; (4) **no veto** → vision critics run, then D-04 self-consistency + unstable→`null`, then D-02 trust gate. **Precedence: vetoed (null) ≻ unstable (null) ≻ scored** — veto and unstable BOTH write `null` (distinguished only by the `vetoed` flag) so neither poisons `min()`.
- **Disagreement is PRESERVED, never resolved.** P1-high / P3-low on one page is *signal* (their JTBDs pull opposite ways — v1.31 "design consequence"). Panel-of-judges *aggregation* applies only when judges approximate one ground truth; these personas encode **different objective functions**, so averaging destroys the divergence the cube exists to expose. `min()` rollup already means "only as good as the worst-served persona"; the `min()`-losing `(persona, lens)` cell is named in the rollup evidence ("timeline hierarchy floored by P3=48") so a genuine tradeoff reads as *"you optimized P1 speed and starved P3's proof-narrative,"* not a mushy 68.
- **Fan-out = per (cell × lens-key), one dimension per call,** parallel within a `rubric_version × model_id` prefix group; order calls to keep the cached prefix warm inside the 5-min TTL (pre-warm before the sweep). The **persona pass-condition clause sits AFTER the cached boundary** so all five persona critics reuse one cached lens prefix (persona-in-prefix = 5 distinct prefixes = cache misses + silent sub-4096 un-caching).

### D-07: Runner architecture, structured-output schema & DX (RUNNER-01)
- **A small TypeScript CLI under `examples/threadline_phoenix/e2e/critic/`** (matches the existing `.spec.ts` lane + tsconfig; zod gives one source of truth between schema and runtime). Module sketch: `run.ts` (CLI/scope/orchestration/exit codes) · `panel.ts` (critic→lens map + veto ordering) · `bundle.ts` (reads Tier-B: scorecard JSON + `.aria.yml` + PNG path) · `prompt.ts` (cached prefix >4096 tok + per-dim user turn) · `schema.ts` · `client.ts` (retry/backoff + N-sample median/variance) · `cache.ts` (verdict cache) · `scorecard.ts` (writes critic-scores) · `report.ts` · `rubrics/` · `refute.ts`. Invoked by `mix verify.ui_critique` → `npm run critic:score`, mirroring how `verify.capture` wraps `capture:tier-a`.
- **Structured output via the Anthropic Node SDK** (`messages.parse()` + JSON-schema/`output_config`), **one lens-dimension per call**, Opus 4.8 (`claude-opus-4-8`; `temperature`/`top_p` removed → don't send them). Per-dimension return shape: `{ lens(enum), score(int, clamp 0–100 client-side — SDK strips numeric bounds), band(enum), pass(bool), evidence{ kind: region|selector|mechanical_line, locator, observation } (REQUIRED), rationale }`. **CRITIC-05 is enforced at the schema layer:** `evidence` and its `kind`+`locator` are `required`, so a score without a located citation fails `parse()` and is discarded, not scored.
- **LLM scores land in a SEPARATE `.planning/critic-scores/` tree — NEVER the deterministic `.planning/scorecards/*.json`.** The scorecards are committed deterministic evidence gated by `verify.mechanical` inside `ci.all`; merging nondeterministic median+variance there would churn byte-stable diffs, risk a nondeterministic producer mutating the guarded bundle, and blur provenance. Each critic-score file stamps `model_id`, `rubric_version`, `n`, `band_mode`, `iqr`, `range`, `stable`, `current:null`-when-unstable. **A guard test asserts the critic never writes under `scorecards/`.**
- **DX / reliability:** verdict cache keyed `{cell, dimension, rubric_hash, model_id}` → free resumability + record/replay (don't re-bill completed cells, D-03); SDK auto-retry on 429/5xx + jittered backoff; two-tier N=3→7 escalation (D-04); `--dry-run` prints the ~$0.45/$12/$23 budget bands; missing `ANTHROPIC_API_KEY` → clean exit 0 (RUNNER-04), doc-contract-locked like `verify.flake`.
- **CLI surface (least-surprise, mirrors `capture:tier-a`):** `critic score [--page <ledger_id>] [--lens <lens>] [--theme dark|light] [--changed] [--refute-only] [--update-golden] [--dry-run] [--force]`; plus `critic validate` (refute battery + trust recompute). `--update-golden` rescoring is a *separate reviewed commit*, never auto-green.

### D-08: Critic report surface & maintainer JTBD
- **Three coupled surfaces, one primary.** **JSON is truth** (the `.planning/critic-scores/` SSOT), **the terminal is the glance** (`mix verify.ui_critique` immediate read), and a committed **`CRITIQUE.md` projection is the primary reviewable deliverable** — generated by the *same freshness-tested projection mechanic* that already emits `DESIGN-SYSTEM.md` (194 LEDGER-04): one row per `(page × persona)`, one column per lens, `min()` rollup as the leading column, deltas + flags in-cell. **Do not invent a new surface**; regenerate, never hand-edit (reuse the `stress_ledger_test.exs` "row is a substring of the markdown" freshness guard).
- **Maintainer JTBD** (solo OSS author; P4/P5 mindset — high fluency, periodic + reactive): *"given a UI change, tell me per-lens whether the operator surface got better or worse, with a located reason, so I can decide what to fix before ratcheting (196)."* Terminal serves the act-now loop; `CRITIQUE.md` diffs cleanly in the PR that made the change. Adopt **Betterer's new/fixed/same/regression idiom** (the ratchet idiom this project already cites).
- **Each finding = one located line:** score + band + delta-vs-floor + cited evidence (region/selector/mechanical line) + plain-language "why" + a **suggested direction (NOT an auto-fix — that's Phase 196)**. Microcopy is precise, non-flattering (brand pressure-test doctrine: no praise, cite evidence, actionable). *e.g.* `hierarchy 55 (▽7, below floor 62) — regression. Action and actor share font-weight:500 (.audit-row__action / .audit-row__actor); no dominant element. Direction: reassert action primacy. [critic · N=7]`.
- **Signal design — symbol + word + reason, never color-only** (survives grep, screen readers, monochrome terminals; a legend prints once): `▲`/`▽` + signed delta + `gain`/`regression`; `~ unstable` + reason (`IQR 14`), value shown `null` not 0, excluded from net-positive; `⛔ vetoed` + "not scored" + tripped token; `? untrusted` + "lens not validated (α<0.67)" (number shown, told not to act on it). **"Unknown" must never read as "bad."** A delta always states its baseline in the header (`@v1.37 → @HEAD` or "vs committed floor") — an unstated base is un-reviewable in a PR.
- **Do NOT build:** no dashboard, no LiveView route, no HTML report, no charts, no public "design-eval" API, no binaries, no stored praise/narrative prose (194 invariants + brand doctrine). Text, diffable, terminal-first, local-only.

### D-09: Authoring & maintenance DX — the maintainer's input side
- **One guided TypeScript CLI lane, `critic label`, inside the D-07 runner** (`e2e/critic/`, same zod/npm-script stack) — NOT hand-editing `golden-set.json` (can't mask IDs / enforce blind rounds / review ~120 judgments) and NOT a LiveView labeler (violates no-public-surface / terminal-first). Reads the committed Tier-A scorecard cell, shows its screenshot (OS viewer / iTerm2 inline), **masks ledger_id/persona/prior label behind an ephemeral opaque token**, and prompts keyboard-driven `good/borderline/bad/broken` (or `better/worse`+`clear/subtle` for pairs) + a required evidence string. **Prodigy doctrine:** single-annotator, one decision per screen, keystroke-driven, batched. Microcopy per `pressure-test.md` — no praise, cite evidence, imperative.
- **Authoring CLI surface (mirrors D-07's flag style):** `critic label [--round r1|r2] [--lens] [--page] [--pairs] [--resume]` (guided round) · `--reconcile` (presents only r1≠r2 disagreements → keep/drop/tiebreak) · `--status` (per-lens N vs the ≥20 bar; flags `provisional`/ratchet-blocked lenses) · `--bootstrap` (seeds the queue: 6 poles → A/B pairs → mid-range off the 3 lowest-scoring pages) · `--add <cell-id>` / `--revalidate --lens <l>` (maintenance). `critic rubric bump <lens> [--patch|--minor|--major]` bumps semver, recomputes `sha8`, and **prints the invalidation blast radius** ("hierarchy@1.2.0+ab3f → critic_trust.hierarchy invalidated; 22 judgments need re-score"). `critic rubric lint` (hash==disk, ≤3 dims, poles resolve) + `critic refute --check <fixture>` (runs **only `verify.mechanical`, $0 LLM** — asserts the twin PASSES all gates = the D-03 partition rule).
- **Blind test-retest, ergonomically enforced:** r1 writes to a **separate `.planning/golden/rounds/r1.json` that `--round r2` never reads or displays** (the maintainer physically cannot see round-1 answers — not in CLI, not in `git diff`); r2 re-presents the same cells **reshuffled, IDs re-masked**; `--round r2` refuses until r1 is committed (encourages a time gap; from-memory replay is the honest limit of solo intra-rater consistency); `--reconcile` keeps only agreeing items into `golden-set.json`. **The CLI is the only writer.**
- **First-run empty state:** `critic score` against an empty golden set → **clean exit 0** with a guided path (mirrors the `ANTHROPIC_API_KEY` no-op): "No oracle yet. Run `critic label --bootstrap` — 6 pole anchors queued. Progress 0/50 cells · 0/6 lenses at N≥20." Poles-first builds labeler calibration AND doubles as the D-05 few-shot poles. Never dead-ends, never reads "broken."
- **Maintenance & invariants:** `held_out_ids` are frozen — the CLI **refuses to enqueue** them ("Phase-196 true-north"); `--add` appends 197 coverage; `--revalidate --lens` re-queues only the bumped lens (per-lens semver isolation). Authoring stays **out of `ci.all`** (local, like `verify.ui_critique`); only the pure-Elixir guard runs in CI.

### D-10: Score→band mapping & band↔ratchet↔instability coupling
- **Exactly 5 bands — data-driven, not arbitrary** (the committed ledger clusters into five levels {20,25},{35},{62},{72},{90}). Cut points chosen so the load-bearing baseline **62 sits dead-center of `ok`** and the frozen ratchet path **62→72→90 = ok→strong→exemplary** (each bump crosses a boundary):

  | Band | Range | Committed anchor | Honest semantics |
  |---|---|---|---|
  | `fail` | 0–34 | footguns 20, 25 | broken / footgun poles |
  | `weak` | 35–54 | form-controls 35 | functional, unpolished |
  | `ok` | 55–69 | foundations/pages 62 (midpoint) | meets floor; **not** aspirational |
  | `strong` | 70–84 | best-3 72 | approaching the reference bar |
  | `exemplary` | 85–100 | target 90 | **= Linear-grade** (D-05 primary anchor) |

  `fail` is wide (no resolution needed below `weak`); the operating bands `ok`/`strong`/`exemplary` are tight (15–16pt) because that's where the ratchet lives. A band is **earned by cited evidence** (CRITIC-05); `CRITIQUE.md` prints band + locator, never a vibe.
- **Order of operations (resolves "median band" vs "band of median"):** (1) reported **point score = `median(raw₁..raw_N)`**, reported **band = `band(median(raw))`** — band-*of*-median, one deterministic value, NOT median-of-bands; (2) **stability = band-mode**: quantize each sample, unstable if `count(modal band) < ⌈N/2⌉` (N=3→need ≥2; N=7→need ≥4); (3) **variance gates run on RAW before quantization** — unstable if `IQR(raw) > 10` OR `range(raw) > 15`. Unstable ⇒ `current: null` (never 0), excluded from the 196 net-positive calc.
- **Ratchet coupling = band-step, not raw.** Floor ∈ **{0, 35, 55, 70, 85}** (band lower cuts). A bump fires **iff** `band(median) > band(floor)` AND the cell is stable AND (194/D-02) the lens is `validated:true` AND evidence-on-gain is attached AND — judged lens — a human signoff exists in `ratchet.signoffs`. **New floor = the achieved band's lower cut, not the raw median** (median 74 `strong` bumps floor 55→**70**, not →74). Consequence: within-band jitter (74→72→71, all ≥70) never trips monotonicity, and 62→68 (still `ok`) is **not** a bump. `min()` stays coherent — every floor is a cut on one shared scale.
- **Near-boundary escalation N=3→7** when: no strict majority band at N=3, OR `median(raw)` within **±2 pts of a band cut**, OR within **≤5 pts of the active floor/target** (D-04). At N=7 re-test `⌈7/2⌉=4`; still no majority band OR IQR>10 OR range>15 → **unstable → `current:null`, human-adjudicate.**

### D-11: Prompt architecture & anti-sycophancy / bias hardening
- **One per-lens-per-dimension message in three byte-stable strata** (render order `system → cached-prefix → suffix`):
  - **system (frozen, no per-lens/persona text):** role = "adversarial design critic; your job is to make this dimension FAIL its written pass condition, **default verdict FAIL**"; the evidence law (CRITIC-05 — every claim cites a region/selector/mechanical line or is discarded); "the mechanical layer already measured px/ratios/counts — **judge gestalt only, never re-measure**"; the no-praise rule (brand pressure-test doctrine). Identical across lenses → shared, and the anti-sycophancy framing must precede everything.
  - **cached prefix (`cache_control: ephemeral`, per-lens, ≥4096 tok):** the `<lens>.md` rubric + `## Reference bar` prose + `## Anchors` = **the two pole exemplars as inline annotated images** (not text). Stable per `<lens>@sha8` (the cache key, D-05); the **pole images are the anti-flattery calibration AND the load-bearing padding over the 4096-token floor** (text-only rubric ~2–2.5k tokens would silently un-cache).
  - **uncached suffix (per call):** (1) target screenshot; (2) the mechanical evidence lines (the measured numbers, 194 map); (3) the `.aria.yml` snapshot; (4) **the persona pass-condition clause, LAST** (after the cache boundary so all five P-critics reuse one cached lens prefix — D-06).
- **Cite-before-score by field order:** emit `evidence{kind,locator,observation} → observation → pass(bool) → band → score`. Left-to-right generation forces the model to *locate and quote* before any number exists — "cite first, score second" at the token level, not just by instruction. Instruct: "if you cannot name a concrete locator, discard that finding; if no locatable failure exists, emit `pass:true` with the specific reason it survives." **Adaptive thinking `display:"summarized"`** (not the 4.8 `omitted` default) supplies auditable rationale before the JSON. No temperature knob — variance is handled by D-04's N-sample median.
- **Anti-sycophancy / anti-verbosity:** adversarial pass-condition framing (never "is this good?"); praise-without-a-locator is void; **forced disjunction** — output is a located failure OR an explicit "no failure found + why" (a zero-finding run with no justification is a *failed* run, not a pass); the density dimension's "name a control whose removal costs the task nothing" is the concrete anti-more-chrome lever.
- **Position/order bias:** single-cell scoring is already blind + independent (D-06, no sibling output in context). For D-03 pairwise prefer **two independent blind single-cell scores compared by delta** (position-bias-free) over one A/B prompt; where a true pairwise prompt is used, **swap-and-average and void any verdict that flips under order-swap or paraphrase** (the D-03 metamorphic check).
- **Image & token economics:** pass the screenshot as a base64 `image` block (Anthropic has **no `detail` knob**). **Downsample to ~1092px long edge (~1600 tok); do NOT send 2576px hi-res** — the VLM must not measure pixels (the mechanical lines already carry every number), and hi-res costs ~4784 tok/image for zero gestalt gain. The volatile image sits *after* the cache boundary so it never invalidates the prefix; pole images pay the 1.25× write once per lens sweep; pre-warm + batch inside the 5-min TTL.

### Claude's Discretion
- Exact JSON/field spelling in `golden-set.json`, `critic_trust`, the refute manifest, the `.planning/critic-scores/` files, and `.planning/golden/rounds/*.json` (beyond the locked shapes above); exact `e2e/critic/` file names; test-name wording — planner/executor choose, consistent with existing conventions.
- Which 3 pages are the "lowest-scoring targets" for golden mid-range cells — derive from the current ledger scores at plan time (same call as Phase 194's Band-2 targets).
- The exact α-bootstrap CI method and library (or a hand-rolled pure-Elixir ordinal α) — planner's call; must be deterministic and dependency-light.
- Exact rubric per-dimension wording (the decomposition is locked in D-05; the prose is authored at implement time against the brandbook + reference-bar notes).
- Exact keybindings / terminal-image mechanism for `critic label` (iTerm2 inline vs OS viewer); the concrete `--bootstrap` queue ordering beyond poles-first.

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
- New `.planning/golden/golden-set.json` (oracle) + new `critic_trust` block in `design-system-ledger.json` (gate) + new refute manifest + committed A/B twin fixtures in `stress_fixtures.ex`.
- New `examples/threadline_phoenix/e2e/critic/` TypeScript CLI runner (Anthropic SDK devDependency; `run/panel/bundle/prompt/schema/client/cache/scorecard/report/refute` modules + `rubrics/<lens>.md`) — prompt-cached per-lens rubric prefix (rubric + reference-bar prose + 2 pole exemplar **images**), structured output via `messages.parse()`, one dimension per call, adaptive-thinking `summarized`, ~1092px downsampled screenshot, N-sample median, per-cell stamping.
- New **`critic label` / `critic rubric` / `critic refute --check` authoring lane** in the same CLI + new **`.planning/golden/rounds/r1.json`** (blind-round file the r2 pass never reads). First-run empty state → guided `--bootstrap`.
- New **5-band scale** {`fail` 0–34, `weak` 35–54, `ok` 55–69, `strong` 70–84, `exemplary` 85–100} with floors snapping to lower cuts {0,35,55,70,85}; band-of-median for the point score, band-mode for stability, raw IQR/range for variance — shared by the ledger ratchet, the D-04 unstable rule, and the D-08 report.
- New **`.planning/critic-scores/` tree** — the nondeterministic LLM-score SSOT, physically separate from the deterministic `.planning/scorecards/` bundles (guard asserts the critic never writes under `scorecards/`).
- New **`CRITIQUE.md` projection** — regenerated from `.planning/critic-scores/` via the same freshness-tested mechanic as `DESIGN-SYSTEM.md` (194 LEDGER-04); the primary reviewable report surface.
- New `mix verify.ui_critique` (local, LLM, excluded from `ci.all`) wrapping `npm run critic:score`; new `mix verify.critic_trust` (pure-Elixir, into `ci.all`); versioned markdown rubric files (one per lens) with a hash-freshness guard.

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
