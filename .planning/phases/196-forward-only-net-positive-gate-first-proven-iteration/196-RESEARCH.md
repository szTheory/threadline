# Phase 196: Forward-Only Net-Positive Gate & First Proven Iteration — Research

**Researched:** 2026-07-28
**Domain:** Integration/wiring over shipped substrate (Elixir mechanical floor + TS LLM critic + append-only ledger) — NOT a greenfield stack
**Confidence:** HIGH (every claim below is traced to a read file; net-new vs. exists is marked per item)

<user_constraints>
## User Constraints (from 196-CONTEXT.md — SSOT, verbatim)

### Locked Decisions
- **[196-D1] GATE-01 is a relative (ranking) gate, not absolute.** Accept iff (a) the *targeted* blocking lens improves (Δ up), (b) *no* blocking lens regresses below its ratchet floor, (c) deterministic mechanical/a11y guards still pass, (d) shared-token/primitive edits trigger a **blast-radius-aware** re-eval of *every* affected cell. Compare rank/Δ direction, never absolute thresholds, on the LLM lenses.
- **[196-D2] Blocking panel = the 4 validated lenses.** `brand_fidelity`, `density`, `typography`, `rhythm` **block**. `hierarchy` (ρ0.42) + `color_contrast` (ρ0.698) are **advisory only** — reported with a badge, never auto-block, findings verified vs ground truth before any human acts (they hallucinate specifics). Panel membership recorded in CONTEXT is the GATE-04 human sign-off; changing it requires a new recorded sign-off.
- **[196-D3] Deterministic mechanical floor is the hard block (GATE-02).** `verify.mechanical` is non-negotiable. Mechanical fixes (snap-to-token, fix contrast, remove off-grid px) may auto-apply **strictly behind GATE-01**. The structural whitelist **starts EMPTY** and expands **only** via explicit spike evidence — no structural auto-apply ships un-spiked this phase.
- **[196-D4] Synthetic twin oracle is the held-out true-north (GATE-03).** `.planning/golden/synthetic-set.json` scored for **validity only**, **never optimized against**. Loop optimizes live `route.*` cells (training surface). If ranking on held-out oracle diverges from behavior on optimized surface → **halt** (Goodhart). Keep surfaces disjoint; oracle refute cells are not edited by propose.
- **[196-D5] Guard-the-guards lives in `verify.critic_trust` (GATE-04).** `critic_trust_test.exs` extended to append-only guard: **blocks** silent target-floor drops, fixture/oracle-cell removal, panel-membership changes lacking a recorded sign-off. Ledger append-only; a bump/target/panel change without a new signed entry fails the test.
- **[196-D6] Pixel-diff stays advisory (GATE-05).** Screenshot baselines never *are* the bar. A refresh is permitted only after the new render **already** passed the semantic guards (mechanical floor + blocking-panel no-regress). A raw pixel delta never accepts/rejects alone.
- **[196-D7] Proof scope = wired loop + runbook + ONE real ratified improvement (PROOF-01).** (a) wire full loop end-to-end, (b) document as repeatable runbook, (c) land one real human-ratified improvement on the single weakest `/audit` page — target lens advanced, zero regressions, committed evidence trail. A **mid-phase human-ratification checkpoint** gates the real change. Full PROOF-02/03/04 remain Phase 197.
- **[196-D8] Real-UI source = `route.*` cells only.** Loop operates on real seeded `/audit/*` routes via `operator-page-capture.spec.ts` (`npm run capture:pages`), clipped to main content. NOT `page.*` (stress-lab chrome — invalid) and NOT `story.*` (isolated demos). Route lane is nascent (`route.timeline` + `route.timeline.degraded`); weakest-page proof expands it.
- **[196-D9] Cost & determinism posture.** LLM critic stays **local-only, out of CI** (`verify.ui_critique` excluded from `ci.all`; needs `ANTHROPIC_API_KEY`). Only deterministic guards (`verify.critic_trust`, `verify.mechanical`) run in CI. LLM re-eval bounded (N=3→7 on unstable; ~$0.015/call) and blast-radius scoped.

### Claude's Discretion (uncovered)
- Exact module/orchestrator names for propose → re-evaluate → guard, and where the runbook lives.
- Concrete divergence-check structure (threshold, halt signal).
- Which single `/audit` page is weakest (score the route.* panel to pick) and which lens to target.
- Whether propose is human-authored-then-gated (likely, given no structural auto-apply) vs tool-assisted.

### Deferred Ideas (OUT OF SCOPE — Phase 197)
- Absolute-score gate; optimizing against the held-out oracle.
- `color_contrast` + `hierarchy` blocking.
- Structural auto-apply without spike evidence (whitelist stays empty).
- PROOF-02 (2–3 pages), PROOF-03 (adversarial closeout), PROOF-04 (debt register).
- **Invariants (unchanged):** no root runtime dep; no public component API; dev/test-only; LLM out of CI; capture/query/auth untouched; brand-token parity green.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support (grounding) |
|----|-------------|------------------------------|
| GATE-01 | Change accepted only if targeted lens improves AND no blocking lens regresses below floor AND mechanical/a11y guards pass; blast-radius-aware for shared tokens | Reuse `refute.ts scoreCellLens` (two-blind-score + noise-floor delta) as the per-cell re-eval primitive; blast radius derived from deterministic re-capture diff; mechanical floor from Elixir `MechanicalChecker` via the Tier-A `page.*` twin. NET-NEW orchestrator. |
| GATE-02 | Mechanical fixes auto-apply behind GATE-01; spike-defined structural whitelist (starts empty) | MODE-A violations already carry actionable `fix:` strings (`mechanical_checker.ex:269-406`). Whitelist = new **empty** ledger array + guard. Auto-apply executor is NET-NEW; scope minimally. |
| GATE-03 | Held-out synthetic oracle scored for validity only; training-vs-held-out divergence halts | `mix critic.measure --source synthetic` + `RankMetrics.spearman` already compute ρ on the held-out set. Divergence-halt = compare recomputed ρ to recorded `critic_trust[lens].spearman` floor. NET-NEW halt wiring. |
| GATE-04 | Ratchet/target/panel changes require recorded sign-off in append-only ledger; guard-the-guards fails on silent drop/removal | Extend `critic_trust_test.exs`. `ratchet.signoffs` (currently `[]`) is the append-only sign-off home. NET-NEW: `critic_panel` baseline block + frozen-constant + baseline-delta guards. |
| GATE-05 | Pixel-diff advisory; baseline refresh requires semantic guards passed first | `screenshot_allowlist.{ci,local_review}` in ledger + Tier-C PNG baselines. NET-NEW: `semantic_guard_stamp` precondition per allowlist entry, asserted by a guard test. |
| PROOF-01 | Full loop wired + runbook + one ratified improvement on weakest page | Expand `ROUTES` in `operator-page-capture.spec.ts`; score via `critic:score --page route.*`; runbook → **CONTRIBUTING.md** maintainer section. NET-NEW gate orchestrator + one real source edit. |
</phase_requirements>

## Summary

Phase 196 is ~85% **wiring over shipped substrate**, not new invention. Every heavy primitive already exists and was traced in this session:

- The **deterministic mechanical floor** is `Threadline.OperatorSurface.MechanicalChecker.run/1` (`lib/threadline/operator_surface/mechanical_checker.ex`). It returns `{:ok, []}` or `{:error, violations}` where each violation is a *located, actionable, fix-bearing map* — MODE-A (WCAG contrast, radius/shadow/motion/font-size/spacing conformance) and MODE-B (ratchet floors: type-size, interactive-control, card-nesting, scroll-cost, distinct-accent-hue). It **deliberately excludes `route.*` and `story.*`** from its jurisdiction (`mechanical_checker.ex:143-156`).
- The **LLM ranking critic** is the TS runner (`examples/threadline_phoenix/e2e/critic/`). `refute.ts scoreCellLens` already scores one cell on one lens (median of dims, stable flag, IQR noise floor), and `testGestaltTwin` already implements a **two-cell ranking comparison with a directional + noise-floor-margin + metamorphic gate** — this is structurally identical to the GATE-01 accept/reject decision.
- The **held-out oracle + ranking metric** already exist: `mix critic.synth` builds `synthetic-set.json`; `mix critic.measure --source synthetic` computes per-lens ρ via `Threadline.CriticTrust.RankMetrics.spearman/2` and writes the `critic_trust` block.
- The **append-only ledger** (`.planning/design-system-ledger.json`) already has `ratchet.signoffs: []` (the empty sign-off home), `ratchet.minimum_scores` (floors), `screenshot_allowlist.{ci,local_review}`, and a `critic_trust` block whose `validated` flags **already match D2's panel exactly** (brand_fidelity/density/rhythm/typography = `true`; hierarchy/color_contrast = `false`).
- The **guard-the-guards test** is `test/threadline/operator_surface/critic_trust_test.exs`, already in `ci.all` before `verify.mechanical`.

**The genuine net-new work is small and well-bounded:** (1) a *propose → re-evaluate → guard* orchestrator (lives in the TS critic runner, local-only, since the ranking re-eval is LLM); (2) three additive guard clauses in `critic_trust_test.exs` (target-drop, fixture-removal, panel-membership) backed by a new `critic_panel` baseline block; (3) a divergence-halt that recomputes held-out ρ and compares to the recorded floor; (4) a `semantic_guard_stamp` precondition on screenshot-allowlist entries; (5) expand the `route.*` capture set and land one real improvement.

**Primary recommendation:** Build the gate as a new TS subcommand (`critic gate` / `gate.ts`) that composes existing primitives (`scoreCellLens`, deterministic re-capture, `RankMetrics`), and enforce every *durable* invariant (panel membership, floors, oracle inventory, screenshot-refresh precondition) as **additive deterministic assertions in `critic_trust_test.exs`** so CI stays LLM-free. The LLM only ever *proposes/ranks locally*; the ledger is what CI guards.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Deterministic mechanical/a11y floor (GATE-01c, GATE-02) | Elixir (`MechanicalChecker`, `verify.mechanical`) | — | Pure arithmetic over committed JSON; runs in CI; the hard block |
| LLM ranking re-eval (GATE-01a/b, blast radius) | TS critic runner (local-only) | Elixir `RankMetrics` for ρ math | Nondeterministic + paid → must stay out of CI (D9) |
| Propose → re-evaluate → guard orchestration (GATE-01) | TS critic runner (new `gate.ts`) | Elixir mechanical + human ratify | Composes LLM re-eval + deterministic floor; human authors the edit (D3/discretion) |
| Held-out divergence halt (GATE-03) | Elixir `critic.measure` + new compare | TS gate reads the halt signal | ρ math is Elixir; recompute + threshold compare |
| Guard-the-guards / sign-off ledger (GATE-04) | Elixir `critic_trust_test.exs` (CI) | ledger JSON as SSOT | Must be deterministic + block silently — belongs in CI test |
| Screenshot-refresh precondition (GATE-05) | Elixir guard test over ledger stamp | Playwright Tier-C pixel (advisory) | Semantic stamp is deterministic; pixel stays advisory |
| Real UI improvement (PROOF-01) | Operator-surface source (`style.ex`/templates) | — | Presentation-only; no component API / capture change (invariant) |

## Standard Stack (existing machinery — use these, do not rebuild)

### Core (already shipped)
| Module / File | Purpose | Phase-196 role |
|---------------|---------|----------------|
| `lib/threadline/operator_surface/mechanical_checker.ex` | Deterministic MODE-A/MODE-B floor; `run/1` → `{:ok,[]}`|`{:error,violations}`; `measure_mode_b/1` public | GATE-01c hard block, GATE-02 fix source |
| `test/threadline/operator_surface/mechanical_checker_test.exs` | `verify.mechanical` gate body; pins MODE-A constants (never loosen) | GATE-02 floor assertion |
| `test/threadline/operator_surface/critic_trust_test.exs` | Guard-the-guards host; in `ci.all` **before** `verify.mechanical` | GATE-04 extension point |
| `.planning/design-system-ledger.json` | Append-only ledger: `ratchet.{minimum_scores,resets,signoffs}`, `screenshot_allowlist`, `critic_trust`, `critic_trust_provenance` | GATE-04/05 SSOT |
| `lib/threadline/critic_trust/rank_metrics.ex` | `spearman/2`, `auc/1` (tie-aware, dependency-light) | GATE-01 rank compare, GATE-03 divergence |
| `lib/mix/tasks/critic.synth.ex` | Builds `synthetic-set.json` from `StressFixtures` graded ladder | GATE-03 held-out oracle |
| `lib/mix/tasks/critic.measure.ex` | `--source synthetic` writes `critic_trust` (never auto-commits) | GATE-03 recompute |
| `examples/…/e2e/critic/refute.ts` | `scoreCellLens` (blind median + IQR noise floor); `testGestaltTwin` (directional+margin+metamorphic) | GATE-01 re-eval primitive (the accept/reject shape already exists) |
| `examples/…/e2e/critic/run.ts` | Subcommand dispatcher: `score` / `validate` / `label` / `rubric` / `report` | Add `gate` subcommand here |
| `examples/…/e2e/critic/panel.ts` | `checkTokenParityVeto`, `checkMechanicalGate` (light MODE-A subset), `runVetoPipeline`, `runPanel` | Pre-aesthetic veto ordering (RUNNER-03) |
| `examples/…/e2e/tests/operator-page-capture.spec.ts` | Real `/audit/*` capture (`route-capture` project); `ROUTES` array | Expand for weakest-page proof |

### Supporting
| Item | Purpose | When to use |
|------|---------|-------------|
| `npm run capture:pages` | Deterministic re-capture of `route.*` cells (no LLM) | Blast-radius detection (diff scorecards before/after) |
| `npm run critic:score -- --page route.<x>` | Score one page's cells on the 4 blocking lenses | GATE-01 re-eval + weakest-page ranking |
| `mix verify.critic_trust` / `mix verify.mechanical` | The two deterministic CI gates | GATE-04/GATE-02 enforcement |
| `CONTRIBUTING.md` §"Local-only critic" (lines 116-228) | Existing maintainer-only critic runbook home | PROOF-01 runbook extends this section |

**Alternatives considered:** Putting the gate orchestrator in Elixir was rejected — the ranking re-eval is inherently LLM (local-only, D9), and Elixir would have to shell to the TS runner anyway. Keep the LLM orchestration in TS; keep the *durable invariants* in Elixir CI tests.

**Version verification:** No new packages. TS runner uses `@anthropic-ai/sdk@^0.110.0` (already a `devDependency` of `e2e/package.json`, RUNNER-05). Root `threadline` stays Phoenix-optional (`verify.compile_no_optional`). No `npm install` / `mix deps` change required — **skip Package Legitimacy Audit (no external packages added).**

## Architecture Patterns

### System Architecture Diagram — the wired loop (PROOF-01)

```
  [human authors a UI edit]              [shared token edit?]
   on the weakest /audit page                    │
            │                                     ▼
            ▼                         ┌───────────────────────────┐
   ┌──────────────────┐   re-capture  │ BLAST RADIUS (deterministic)│
   │ capture:pages    │──────────────▶│ diff new route.* scorecards │
   │ (Playwright,     │   ALL route    │ vs committed → changed set  │
   │  no LLM, $0)     │   cells        └───────────┬───────────────┘
   └──────────────────┘                            │ affected cells only
                                                    ▼
            ┌───────────────── GATE-01 (accept/reject) ─────────────────┐
            │                                                            │
            ▼ (c) DETERMINISTIC FLOOR        ▼ (a)(b) LLM RANKING (local)│
   ┌─────────────────────────┐      ┌────────────────────────────────┐  │
   │ MechanicalChecker.run    │      │ scoreCellLens(before)/(after)  │  │
   │ over the Tier-A page.*    │      │ on 4 BLOCKING lenses           │  │
   │ twin (verify.mechanical)  │      │ Δ_target > noise_floor(IQR)?   │  │
   │ MODE-A hard + MODE-B floor │      │ Δ_other  ≥ −noise on each?     │  │
   └───────────┬─────────────┘      └───────────────┬────────────────┘  │
               │ {:error} → REJECT                   │ regress → REJECT   │
               └───────────────┬─────────────────────┘                    │
                               ▼ both pass                                 │
            ┌──────────── GATE-03 divergence halt (Goodhart) ────────────┐│
            │ mix critic.measure --source synthetic → ρ_heldout          ││
            │ ρ_heldout[lens] < recorded floor?  → HALT loop             ││
            └──────────────────────┬─────────────────────────────────────┘│
                                   ▼ no divergence                         │
            ┌─── ADVISORY (never blocks) ───┐   ┌─── GATE-05 (pixel) ───┐  │
            │ hierarchy + color_contrast    │   │ pixel diff = advisory │  │
            │ reported, verify vs ground    │   │ baseline refresh only │  │
            │ truth before human acts       │   │ after semantic pass   │  │
            └───────────────────────────────┘   └───────────────────────┘  │
            └─────────────────────────┬──────────────────────────────────┘
                                      ▼
                       [MID-PHASE HUMAN RATIFICATION CHECKPOINT]
                                      ▼
        commit evidence trail  +  append ratchet.signoffs entry (if bar changed)
                                      ▼
              GATE-04 guard-the-guards (verify.critic_trust, CI) re-asserts
```

### Pattern 1: Reuse `scoreCellLens` two-blind-score + noise-floor margin as the GATE-01 primitive
**What:** `refute.ts:216 scoreCellLens(cellId, lens, dims)` returns `{score, stable, iqr}`. `testGestaltTwin` already computes `delta = polished − flawed` and gates on `delta > 0` (directional), `delta > noiseFloor(IQR)` (margin), and `both stable` (metamorphic).
**When to use:** GATE-01 accept/reject is the *same computation* with "before" and "after" captures of the same route cell instead of "polished"/"flawed" twins. Targeted lens must clear `Δ > noise_floor`; every other blocking lens must satisfy `Δ ≥ −noise_floor` (no regression beyond the critic's own noise band).
**Example:**
```typescript
// Source: examples/threadline_phoenix/e2e/critic/refute.ts:329-356 (existing gate shape)
const directionalGate = delta > 0 ? pass : fail;            // targeted lens up
const marginGate      = delta > polished.iqr ? pass : fail; // beyond noise floor
const metamorphicGate = polished.stable && flawed.stable;   // instability voids
```

### Pattern 2: Blast radius via deterministic re-capture diff (no LLM guesswork)
**What:** After an edit, run `npm run capture:pages` (deterministic, $0). Any `route.*` scorecard whose JSON bytes changed vs. the committed/prior copy is *in the blast radius*; the LLM re-scores only those.
**When to use:** Satisfies D1(d) "blast-radius-aware" concretely and cheaply. A shared `style.ex --tl-*` token edit changes many cells' `element_styles`/`applied_colors` → many cells re-score; a page-local template edit changes one → one cell re-scores. This is derivable from artifacts, not from static analysis of "which primitive is shared."

### Pattern 3: The route.* → page.* twin resolves the mechanical-floor jurisdiction gap
**What:** `MechanicalChecker.list_scorecards` **excludes `route.*`** (`mechanical_checker.ex:155`), so `verify.mechanical` cannot gate a route cell directly. But every `/audit/*` route has a Tier-A `page.*` twin in `mechanical_floors` (e.g. `route.timeline` ↔ `page.timeline.happy`). The real UI edit changes *both* renderings, so the deterministic floor gates the change via the committed `page.*` scorecard in CI.
**When to use:** This is how GATE-01c ("mechanical/a11y guards pass") is satisfied *in CI* for a route improvement without committing the gitignored, non-byte-stable `route.*` scorecard. **Make this twin mapping explicit in the plan.**

### Anti-Patterns to Avoid
- **Running the LLM in CI.** D9 + Out-of-Scope table forbid it. Everything the gate decides via LLM is local; CI only re-asserts the recorded ledger.
- **Using absolute LLM scores as a bar.** D1/CONTEXT: the lenses rank well (ρ) but compress their absolute scale (low α). Only compare Δ direction vs. the per-cell noise floor.
- **Letting advisory lenses influence accept/reject.** hierarchy/color_contrast are ρ≤0.698 and hallucinate specifics — report only, verify vs ground truth.
- **Committing `route.*` scorecards or `CRITIQUE.md` as CI evidence.** `.gitignore:61` excludes `route.*.json`; CRITIQUE.md is an uncommitted projection. Evidence trail = the real source diff + critic-scores summary in the runbook/ledger.
- **Treating the TS `checkMechanicalGate` as the floor.** It only checks `card_nesting_depth>3` and `type_size_count<2` (`panel.ts:213-238`) — a *pre-aesthetic veto*, NOT the full floor. The authoritative floor is the Elixir `MechanicalChecker`.

## Per-Requirement Recommended Approach

### GATE-01 — Forward-only ranking gate (NET-NEW orchestrator over existing primitives)
**Where it lives:** New `examples/threadline_phoenix/e2e/critic/gate.ts`, dispatched by a new `case "gate":` in `run.ts` (mirrors the `validate` lazy-import pattern, `run.ts:457-473`). Local-only, LLM, out of CI.
**Concrete flow:**
1. Input: the target page ledger id (e.g. `route.timeline`) + the targeted blocking lens.
2. Snapshot the *before* critic scores for the affected cells on all 4 blocking lenses (reuse `scoreCellLens` or the committed critic-scores).
3. Human applies the edit; run `npm run capture:pages` → **blast radius** = changed `route.*` scorecards (Pattern 2).
4. Deterministic floor (Pattern 3): assert `mix verify.mechanical` green on the affected `page.*` twin(s). `{:error}` → REJECT.
5. LLM re-eval: `scoreCellLens(after)` on the 4 blocking lenses for each affected cell. Accept iff `Δ_target > noise_floor` AND `∀ blocking lens: Δ ≥ −noise_floor`. Escalate N=3→7 on any unstable cell (D9); an unstable targeted-lens verdict is *void*, not a pass.
6. Advisory lenses (hierarchy, color_contrast) scored + printed with an advisory badge; never gate.
**Reuse, do not rebuild:** `scoreCellLens`, `runNSamples` (N-escalation + IQR already implemented), `RankMetrics` if you prefer ρ over paired-Δ for multi-cell blast radius.
**Landmine:** rhythm is the weakest blocking lens (ρ0.76) and `scroll_cost` is non-deterministic jitter on live routes (R2). Keep N-escalation for route cells; revert unchanged scorecards after recapture to avoid jitter-driven false regressions.

### GATE-02 — Mechanical auto-apply behind the gate; whitelist starts EMPTY
**Exists:** MODE-A violations already emit exact fixes: `snap <metric> <v> -> nearest token` (`mechanical_checker.ex:393-406`), `raise contrast to >= X:1 …` (`:269-281`), `replace box-shadow with a --tl-shadow-* token` (`:318-333`). These *are* "the exact Phase-196 auto-apply whitelist" (module docstring line 15).
**Net-new (minimal):**
- Represent the structural whitelist as a new **empty** ledger block, e.g. `"mechanical_auto_apply": {"structural_whitelist": []}`, plus a guard clause in `critic_trust_test.exs` asserting it is `[]` unless a `ratchet.signoffs` entry of kind `structural_whitelist_add` exists (D3: expands only via spike + sign-off).
- The mechanical *fix* application for this phase should be scoped conservatively. Given D3 ("no structural auto-apply un-spiked") and the discretion note ("propose is likely human-authored-then-gated"), recommend: **the propose step surfaces MODE-A fixes as a suggested diff; the human applies; GATE-01 re-eval + `verify.mechanical` then gate it.** A fully automated source-rewriter for `style.ex` is higher-risk and not required by the wording ("may auto-apply") — keep it out unless a plan explicitly spikes it.
**Deliverable:** empty-whitelist representation + guard + the fix-surfacing path wired into `gate.ts`.

### GATE-03 — Held-out divergence halt (Goodhart guard)
**Exists:** `synthetic-set.json` is the held-out true-north (graded severity rungs, `critic.synth.ex`). `critic.measure --source synthetic` computes per-lens ρ via `RankMetrics.spearman`. The two surfaces are already disjoint: propose edits `route.*`; the oracle is `refute.*`-prefixed graded cells never touched by propose. Contamination is already guarded (`critic_trust_test.exs:281-328` — held-out and pole disjointness).
**Concrete divergence metric + halt:**
- After an iteration (or before accepting), re-run `mix critic.measure --source synthetic` and read `critic_trust[lens].spearman` (recomputed on the held-out oracle).
- Define a **trust floor** per blocking lens (recorded in the new `critic_panel` block, see GATE-04). Halt condition: `ρ_heldout[lens] < trust_floor[lens]` for any blocking lens (recommend floor = the recorded validated ρ minus a small tolerance, e.g. `0.05`, but never below the `0.7` validation bar the existing test enforces at `critic_trust_test.exs:102`).
- **Halt signal:** `gate.ts` runs the recompute and exits non-zero ("loop halted — held-out ρ diverged") before any accept; the maintainer investigates. Because the recompute is LLM (local), the *floor value* is what CI guards (GATE-04). Keep the oracle **never optimized against** — do not add route cells to the synthetic set, do not edit refute rungs to chase ρ.
**Landmine:** the current recorded held-out ρ values are `brand_fidelity 0.93 / density 0.84 / typography 0.77 / rhythm 0.76` — rhythm/typography sit close to the 0.7 bar, so a modest divergence tolerance is correct; too tight and legitimate route iterations will false-halt.

### GATE-04 — Guard-the-guards (the core deterministic deliverable)
**Host:** `test/threadline/operator_surface/critic_trust_test.exs` (already in `ci.all` before `verify.mechanical`, `mix.exs:130-135`). It currently guards *block shape*, the *per-validated-lens statistical bar*, provenance, rubric-hash freshness, golden structure, held-out/pole disjointness, and critic-scores/scorecards separation. It does **NOT** yet guard silent target-floor drops, fixture removal, or panel-membership changes — **these are the three GATE-04 extension points.**
**Represent the sign-off (append-only):** `ratchet.signoffs` is currently `[]`. Each entry:
```json
{ "kind": "target_change | panel_membership | fixture_removal | ratchet_bump | structural_whitelist_add",
  "date": "2026-07-…", "actor": "maintainer",
  "before": <value>, "after": <value>,
  "rationale": "…", "evidence_ref": ".planning/…" }
```
**Add a committed baseline block** `critic_panel` (the "recorded human sign-off" SSOT that D2 says CONTEXT records):
```json
"critic_panel": {
  "blocking": ["brand_fidelity","density","typography","rhythm"],
  "advisory": ["hierarchy","color_contrast"],
  "trust_floors": {"brand_fidelity":0.88,"density":0.80,"typography":0.72,"rhythm":0.72},
  "oracle_inventory": {"synthetic_item_count": <N>, "held_out_ids": [...]},
  "signoff_ref": "196-CONTEXT.md#196-D2"
}
```
**Three new deterministic guard clauses (all vacuous-safe, mirroring existing idioms):**
1. **Panel-membership freeze.** Add frozen test constants `@blocking_panel ~w(brand_fidelity density typography rhythm)` / `@advisory_panel ~w(hierarchy color_contrast)`. Assert `critic_panel.blocking == @blocking_panel` AND `critic_panel.advisory == @advisory_panel` AND that each blocking lens has `critic_trust[lens].validated == true` and each advisory `== false`. Changing membership requires editing the frozen constant *and* an appended `panel_membership` signoff — assert a matching signoff exists whenever the constant differs from a stored prior (see clause pattern in existing `@critic_lenses` freeze at `:60-68`).
2. **No silent target/floor drop.** Assert every `critic_panel.trust_floors[lens]` and every `ratchet.minimum_scores[id]` is `>=` the value in the most-recent `ratchet.signoffs` `before/after` chain — i.e. a *downward* move must be justified by a signoff whose `after` equals the new value. Simplest robust form: the guard fails if any current floor is below a committed baseline floor unless a `ratchet_bump`/`target_change` signoff records that exact drop.
3. **No fixture/oracle-cell removal.** Assert `synthetic-set.json` item count `>= critic_panel.oracle_inventory.synthetic_item_count` and every recorded `held_out_id` is still present, unless a `fixture_removal` signoff records it. (Guards D4's "never delete the true-north set silently.")
**Append-only enforcement:** assert `length(ratchet.signoffs)` never decreases by pairing it with a committed count, or (cleaner) assert every prior signoff object is still a subset of the current array — the existing test style compares against frozen expectations, so pin the known-good signoffs.
**Why this is safe for CI:** all clauses are pure JSON reads + File.exists? (no browser/LLM), exactly like the current test file.

### GATE-05 — Pixel-diff advisory; refresh gated by semantic guards
**Exists:** `screenshot_allowlist.{ci,local_review}` (ledger) lists baseline PNGs by `{ledger_id, story_id, theme, viewport, baseline_ref}`. Route PNGs are gitignored + non-byte-stable (`.gitignore:56-61`), so pixel there is inherently advisory/local.
**Net-new:** add a `semantic_guard_stamp` to each allowlist entry (or a sibling block keyed by `baseline_ref`):
```json
{ "baseline_ref":"stress-page-timeline-…png", "mechanical_ok": true,
  "blocking_panel_no_regress": true, "scorecard_ref":"page.timeline.happy__dark-1024",
  "stamped_at":"…", "evidence_ref":"…" }
```
**Guard clause in `critic_trust_test.exs`:** for every `screenshot_allowlist.ci` entry, assert a non-stale `semantic_guard_stamp` exists whose `scorecard_ref` resolves to a committed scorecard AND whose mechanical verdict *recomputes clean* by calling `MechanicalChecker.run(scorecard_dir: …)` (or `measure_mode_b/1`) over that cell. A refresh therefore *cannot* land without the semantic guards having produced a fresh clean stamp — the pixel delta never accepts/rejects on its own. Keep the actual pixel comparison in the Playwright/Tier-C lane as advisory output only.
**Landmine:** don't tie the stamp to the gitignored `route.*` cell (non-deterministic) — tie it to the committed `page.*` twin so CI can recompute it.

### PROOF-01 — Wire the loop, write the runbook, land one improvement
**(a) Wire end-to-end:** expand `ROUTES` in `operator-page-capture.spec.ts:84-87` from `[route.timeline, route.timeline.degraded]` to the candidate weakest pages (D8 names timeline/coverage/retention/actors/evidence; the `mechanical_floors` inventory confirms these `page.*` twins all exist: home, timeline, coverage, actor, evidence, exports, redaction, retention, row-history, shell, transaction). Then `critic:score --page route.<x>` → `critic gate` → mechanical twin + LLM ranking → divergence halt → advisory report.
**(b) Runbook location — RECOMMENDATION:** extend **`CONTRIBUTING.md`** (it already owns the maintainer-only critic section, lines 116-228: setup, synthetic-oracle validation, refute battery, key posture). Add a "Forward-only gate — run one iteration" subsection there. **Do NOT put it in `guides/`** — `guides/*` are ExDoc-published *adopter* docs (getting-started, evaluating, incident-playbook); the critic is dev/maintainer tooling and must not leak into published hex docs. Add a doc-contract test (existing idiom, `verify.doc_contract`) pinning the canonical commands so the runbook cannot drift.
**(c) First proven iteration:**
1. Score the current `route.*` panel on the 4 blocking lenses → pick the single lowest-scoring page and its weakest blocking lens (discretion; must be data-driven, not assumed).
2. Human authors ONE real improvement to that `/audit` page in operator-surface presentation (no component API / capture change — invariant).
3. Re-capture + re-score → prove `Δ_target > noise_floor` and no blocking regression; `verify.mechanical` green on the `page.*` twin.
4. **Mid-phase human-ratification checkpoint** (D7) gates the change.
5. Commit the evidence trail: the source diff, the critic-scores summary, an appended `ratchet.signoffs` entry if any bar changed, and the runbook update. (`route.*` scorecards + CRITIQUE.md stay uncommitted by design.)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-cell lens scoring + stability | New scorer | `refute.ts scoreCellLens` + `client.ts runNSamples` | N-escalation, IQR noise floor, stable flag already implemented |
| Rank/Δ comparison | New stats | `RankMetrics.spearman/2`, `auc/1` | Tie-aware, tested, dependency-light |
| Deterministic floor | New checker | `MechanicalChecker.run/1` / `measure_mode_b/1` | WCAG + token conformance + MODE-B ratchets already exact |
| Held-out oracle | New fixture set | `mix critic.synth` + `synthetic-set.json` | Zero-labeling graded ladder, already disjoint-guarded |
| Blast radius | Static "shared primitive" analysis | Re-capture diff of `route.*` scorecards | Empirical, $0, captures real DOM/token propagation |
| Sign-off ledger | New file | `ratchet.signoffs` (append-only, currently `[]`) | Ledger is already the append-only SSOT |

**Key insight:** the two hardest things (validated ranking + deterministic floor) are done. Resist re-implementing them in the gate; compose them.

## Runtime State Inventory (this phase edits ledger + adds guards — audit the durable state)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `.planning/design-system-ledger.json` — `ratchet.signoffs:[]`, `ratchet.minimum_scores`, `screenshot_allowlist`, `critic_trust` (validated flags already match D2). `synthetic-set.json` (held-out oracle, `held_out_ids:[]` currently). | Additive edits only (new `critic_panel`, `mechanical_auto_apply.structural_whitelist:[]`, `semantic_guard_stamp`). Never rewrite existing bytes (append-only). |
| Live service config | None — no external service holds Phase-196 state. | None. |
| OS-registered state | None. | None — verified: gate is local CLI + CI test. |
| Secrets/env vars | `ANTHROPIC_API_KEY` (local-only, never committed; `CONTRIBUTING.md:136`). `DEMO_SEED_PASSWORD`/`password123456` for route capture login. | None — code reads env only. |
| Build artifacts | `route.*` PNGs + `route.*.json` (gitignored, regenerable, `.gitignore:56-61`); `.planning/critic-scores/*` (gitignored); `CRITIQUE.md` (uncommitted projection). | Regenerate via `capture:pages` / `critic:score`; never commit as CI evidence. |

## Common Pitfalls

### Pitfall 1: Mechanical floor cannot see `route.*` cells
**What goes wrong:** You wire GATE-01c to `verify.mechanical` over a `route.*` improvement and it silently checks nothing — `list_scorecards` rejects `route.*`/`story.*` (`mechanical_checker.ex:155`).
**How to avoid:** Gate the deterministic floor on the `page.*` Tier-A twin of the same page (Pattern 3). Make the route↔page twin mapping explicit in the plan/runbook.
**Warning signs:** a route "improvement" passes with zero mechanical violations reported even though the page grid changed.

### Pitfall 2: rhythm/scroll-cost jitter on live routes → false regression
**What goes wrong:** `scroll_cost` (page height ÷ viewport) is non-deterministic on live-data routes; rhythm is ρ0.76 (weakest blocking lens). A recapture flips it and GATE-01 false-rejects.
**How to avoid:** N-escalate route cells (N=3→7, already supported); revert unchanged scorecards after recapture (R2); compare Δ vs the per-cell IQR noise floor, never absolute.
**Warning signs:** a blocking regression appears only on rhythm and only for scroll-cost, not reproduced on re-run.

### Pitfall 3: Advisory-lens hallucination treated as fact
**What goes wrong:** hierarchy/color_contrast invent specifics (an invented hex that exists nowhere — see memory `critic-advisory-lenses-hallucinate-specifics`). A human "fixes" a fabricated finding.
**How to avoid:** advisory lenses never gate; every advisory finding is verified vs ground truth (the committed scorecard/DOM) before action (D2/R1).

### Pitfall 4: Optimizing the held-out oracle to "fix" a divergence halt
**What goes wrong:** ρ_heldout drops; the tempting fix is to edit the synthetic rungs or add route cells to the oracle — destroying the Goodhart guard.
**How to avoid:** the oracle is scored for validity ONLY (D4). A divergence halt means investigate the *critic/route change*, never the oracle. `critic_trust_test.exs` disjointness guards already fight contamination — keep them.

### Pitfall 5: Silent ledger tampering slips through because the guard is missing
**What goes wrong:** someone lowers a `minimum_scores` floor or drops a synthetic item; CI stays green because no guard checks it (today's gap).
**How to avoid:** land the three GATE-04 clauses (target-drop, fixture-removal, panel-membership) with the `critic_panel` baseline + `ratchet.signoffs` requirement. This is the phase's central deterministic deliverable — do not defer it.

## State of the Art (project-internal — the validation pivot)

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-labeled golden set + Krippendorff α ≥ 0.67 human agreement (CRITIC-01/03, 195-07 checkpoint) | Synthetic twin oracle + Spearman ρ ranking gate (zero human labeling) | Phase 195 pivot (commit aef9e655; thread 2026-07-27) | GATE-01 is *ranking*, not absolute; α is reported-only (`critic_trust_test.exs:108`) |
| Persona fan-out p1–p5 per lens | Single "all" critic per lens (`PERSONA_LENSES.all`, `run.ts:64`) | 2026-07-28 divergence probe | ~5× cheaper; validation == deployment |

**Deprecated/outdated:** the α ≥ 0.67 threshold as a *gate* (now ρ ≥ 0.7 is the bar, `critic_trust_test.exs:102`); the `CONTRIBUTING.md:132` line still says "α ≥ 0.67" — flag as a doc-drift to fix while touching the runbook.

## Validation Architecture

`workflow.nyquist_validation` is not disabled → this section applies. Every gate must be **deterministically verifiable in CI without the LLM.**

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) + Playwright (e2e, local) |
| Config file | `mix.exs` aliases (`verify.*`, `ci.all`); `e2e/playwright.config.ts` |
| Quick run | `mix verify.critic_trust` (pure Elixir, no browser/LLM) |
| Full suite | `mix ci.all` (order: … → `verify.critic_trust` → `verify.mechanical` → `verify.example_browser`) |
| Local-only (excluded from CI) | `mix verify.ui_critique`, `npm run critic:*`, `npm run capture:*` |

### Phase Requirements → Test Map
| Req | Behavior | Test type | Automated command | Exists? |
|-----|----------|-----------|-------------------|---------|
| GATE-01 | Gate accepts only on target-up + no blocking regress + floor pass | integration (local LLM) + unit (mechanical) | `npm run critic -- gate --page route.<x> --lens <l>` (local); `mix verify.mechanical` (CI floor) | ❌ Wave 0 (`gate.ts` net-new) |
| GATE-02 | Structural whitelist empty unless signed off | unit | `mix verify.critic_trust` (new clause) | ❌ Wave 0 |
| GATE-03 | Held-out ρ ≥ recorded floor; divergence halts | unit (floor recorded) + local (recompute) | `mix verify.critic_trust` (floor guard); `mix critic.measure --source synthetic` (local recompute) | ⚠️ recompute exists; halt wiring ❌ |
| GATE-04 | Silent target-drop / fixture-removal / panel-change fails | unit | `mix verify.critic_trust` (3 new clauses) | ❌ Wave 0 (core deliverable) |
| GATE-05 | Baseline refresh requires fresh clean semantic stamp | unit | `mix verify.critic_trust` (stamp guard) | ❌ Wave 0 |
| PROOF-01 | Loop runs end-to-end; one improvement lands; runbook pinned | integration (local) + doc-contract | full loop (local) + `mix verify.doc_contract` | ❌ Wave 0 |

### Sampling rate
- **Per task commit:** `mix verify.critic_trust` (fast, deterministic).
- **Per wave merge:** `mix verify.critic_trust && mix verify.mechanical`.
- **Phase gate:** `mix ci.all` green; the one real improvement's `page.*` twin passes `verify.mechanical`; mid-phase human ratification recorded.

### Wave 0 Gaps
- [ ] `gate.ts` (+ `run.ts` `case "gate"`) — the propose→re-eval→guard orchestrator (GATE-01).
- [ ] `critic_trust_test.exs` — 3 GATE-04 clauses + GATE-02 whitelist clause + GATE-05 stamp clause (all vacuous-safe until data lands).
- [ ] Ledger additive blocks: `critic_panel`, `mechanical_auto_apply.structural_whitelist:[]`, `semantic_guard_stamp` per allowlist entry.
- [ ] Divergence-halt compare in `gate.ts` reading `mix critic.measure --source synthetic` output.
- [ ] Expanded `ROUTES` in `operator-page-capture.spec.ts` for the weakest-page candidates.
- [ ] `CONTRIBUTING.md` runbook subsection + `verify.doc_contract` pin (and fix the stale α line).

## Security Domain

`security_enforcement` not disabled → included, but scope is dev/test tooling with a locked boundary.

| ASVS category | Applies | Standard control |
|---------------|---------|------------------|
| V5 Input Validation | yes | Ledger/scorecard JSON is `Jason.decode!` over *committed, maintainer-authored* files; guard tests already reject path traversal (golden cell → committed scorecard, `critic_trust_test.exs:259`; `scorecard.ts` FORBIDDEN_ROOT guard). New guards must keep File.exists?/resolve checks. |
| V6 Cryptography | no (advisory) | sha8 rubric-hash is integrity-only (not security crypto); leave as-is. |
| Secrets | yes | `ANTHROPIC_API_KEY` env-only, never committed/written (`CONTRIBUTING.md:136`). Route-capture uses a seeded demo password — test-only. |

| Threat pattern | STRIDE | Mitigation |
|----------------|--------|------------|
| Silent quality-bar tampering (drop a floor / remove a fixture) | Tampering / Repudiation | GATE-04 append-only `ratchet.signoffs` + guard-the-guards (the whole point of this phase) |
| LLM nondeterminism leaking into CI | (availability/integrity) | D9: LLM strictly local; CI asserts recorded ledger only |
| Path traversal via crafted cell_id | Tampering | Existing committed-scorecard resolution guards; extend to new blocks |

**Invariant to re-verify at closeout (PROOF-03 is Phase 197, but keep green now):** no root runtime dep (`verify.compile_no_optional`), no public component API, dev/test-only, LLM out of CI, capture/query/auth untouched, brand-token parity green.

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | Runbook belongs in `CONTRIBUTING.md`, not `guides/` (guides = ExDoc-published adopter docs) | PROOF-01 | LOW — if maintainer prefers a `docs/` file, trivial to relocate; either way keep it out of published hex docs |
| A2 | Divergence tolerance ~0.05 below recorded ρ (never below the 0.7 bar) | GATE-03 | MEDIUM — too tight false-halts rhythm/typography (ρ0.76/0.77); the exact number is a maintainer knob, confirm at plan time |
| A3 | Auto-apply for this phase = surface MODE-A fixes as a suggested diff (human applies), not an automated `style.ex` rewriter | GATE-02 | LOW — D3 says "may auto-apply" + "no un-spiked structural"; conservative reading is safe. If maintainer wants automated mechanical rewrite, that's a spike |
| A4 | `critic_panel` trust_floor values (0.88/0.80/0.72/0.72) are placeholders | GATE-04 | MEDIUM — planner/maintainer must set real floors from the recorded ρ at sign-off time |
| A5 | The weakest page is data-driven (must score the route.* panel), not pre-known | PROOF-01 | LOW — flagged as discretion; do not hard-code a page |

## Open Questions

1. **Exact divergence threshold + halt semantics (GATE-03).**
   - Known: recompute via `critic.measure --source synthetic`; compare to recorded ρ floor.
   - Unclear: absolute Δ vs. crossing the 0.7 bar; whether halt is per-lens or panel-aggregate.
   - Recommendation: per-blocking-lens floor in `critic_panel.trust_floors`; halt if any drops below its floor; tolerance a maintainer knob (A2). Confirm at plan.
2. **Automated mechanical-fix application vs. human-applied (GATE-02).**
   - Known: fixes are exact and located; whitelist empty.
   - Unclear: does "auto-apply" mean the tool rewrites source, or surfaces a diff?
   - Recommendation: surface-a-diff this phase (A3); reserve automated rewrite for a future spike.
3. **How much of the route panel to capture for the weakest-page pick (PROOF-01).**
   - Known: D8 names timeline/coverage/retention/actors/evidence; all have `page.*` twins.
   - Unclear: score all five (cost ~5×$0.45) or a cheaper subset first.
   - Recommendation: capture + score the five candidates on the 4 blocking lenses (~$2–3), pick lowest; bounded per D9.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/ExUnit | `verify.critic_trust`, `verify.mechanical` (CI + local) | ✓ (project) | 1.15 floor / 1.17.3 | — |
| Node + Playwright | `capture:pages`, gate re-capture (local) | ✓ (e2e) | Playwright 1.61.1 pinned | — |
| `@anthropic-ai/sdk` | LLM re-eval (local) | ✓ devDependency | ^0.110.0 | dry-run works without key |
| `ANTHROPIC_API_KEY` | LLM scoring/gate (local only) | maintainer-provided | — | gate no-ops / dry-run; CI never needs it (D9) |
| Seeded example app (`mix demo.seed`, DB_PORT 5433) | route capture login | ✓ via `run-e2e.sh` | — | — |

**No missing blocking dependencies.** LLM key is intentionally maintainer-local; its absence degrades to dry-run, never blocks CI.

## Sources

### Primary (HIGH confidence — read this session)
- `lib/threadline/operator_surface/mechanical_checker.ex` — floor semantics, MODE-A/B, route.* exclusion (`:155`), fix strings
- `test/threadline/operator_surface/critic_trust_test.exs` — current guards + GATE-04 extension points
- `.planning/design-system-ledger.json` — `ratchet.signoffs:[]`, `minimum_scores`, `screenshot_allowlist`, `critic_trust` (validated flags match D2), `cube_axes`
- `lib/threadline/critic_trust/rank_metrics.ex` — spearman/auc
- `lib/mix/tasks/critic.{synth,measure}.ex` — oracle build + ρ recompute
- `examples/…/e2e/critic/{run,refute,scorecard,panel}.ts` — subcommands, `scoreCellLens`, veto pipeline, `checkMechanicalGate`
- `examples/…/e2e/tests/operator-page-capture.spec.ts` — `ROUTES`, capture bundle shape
- `examples/…/e2e/package.json`, `mix.exs` (aliases/`ci.all`), `CONTRIBUTING.md`, `.gitignore`, `.planning/{REQUIREMENTS,ROADMAP,STATE}.md`, `196-CONTEXT.md`

### Secondary (MEDIUM — project memory)
- `critic-synthetic-oracle-ranking-gate`, `critic-advisory-lenses-hallucinate-specifics`, `critic-real-ui-source-storybook-not-stress-lab`, `phase-196-gate-shape-decision-pending`, `critic-persona-fanout-redundant`

## Metadata

**Confidence breakdown:**
- Existing machinery / where things live: HIGH — every file read directly this session
- GATE-04 guard design: HIGH on extension points, MEDIUM on exact baseline-block schema (planner refines)
- GATE-03 threshold: MEDIUM — mechanism certain, numeric tolerance is a maintainer knob
- GATE-02 auto-apply depth: MEDIUM — wording permits either reading; conservative recommended

**Research date:** 2026-07-28
**Valid until:** ~2026-08-27 (stable internal substrate; re-verify if the ledger schema or critic runner changes)
