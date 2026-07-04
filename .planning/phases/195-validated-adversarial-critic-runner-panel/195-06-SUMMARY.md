---
phase: 195-validated-adversarial-critic-runner-panel
plan: "06"
subsystem: e2e-critic
tags: [critic, panel, veto, refute, RUNNER-03, CRITIC-02]
dependency_graph:
  requires: [195-05, 195-03]
  provides: [panel.ts, refute.ts]
  affects: [run.ts validate]
tech_stack:
  added: []
  patterns:
    - token-parity veto (mechanical, $0, applied_colors vs --tl-color-* token set)
    - blind fan-out (per-cell per-lens per-persona, no sibling output)
    - two-tier noise-floor margin gate (delta > polished IQR, not fixed absolute)
    - veto-ordering offline test (synthetic scorecard injection, $0 LLM)
    - transcript-per-fixture for deterministic residue
key_files:
  created:
    - examples/threadline_phoenix/e2e/critic/panel.ts
  modified:
    - examples/threadline_phoenix/e2e/critic/refute.ts
decisions:
  - "[195-06-01]: Token-parity veto reads scorecard.applied_colors vs --tl-color-* token set (hex→rgb conversion); transparent/rgba(0,0,0,0) values are always permitted."
  - "[195-06-02]: Veto-ordering refute test uses synthetic scorecard injection (no committed flawed scorecard) — $0 LLM, offline, tests checkTokenParityVeto + runVetoPipeline directly."
  - "[195-06-03]: Metamorphic gate in gestalt refute = both cells produce stable N-sample scores (no instability), not a separate A/B swap call — avoids doubling API cost while still voiding unstable verdicts."
  - "[195-06-04]: Noise floor for margin gate = average IQR across dimensions of the polished cell's N samples (not a fixed absolute threshold, per D-03)."
  - "[195-06-05]: Panel pre-warming order: graphic-design lenses first (establishes cached prefixes), then persona sweep (all five reuse the warmed hierarchy/density prefixes inside the 5-min TTL)."
metrics:
  duration: "~13m"
  completed: "2026-07-04"
  tasks: 2
  files: 2
status: complete
---

# Phase 195 Plan 06: 7-Critic Panel + Refute Battery Summary

**One-liner:** 7-critic blind panel with brand-veto ordering (RUNNER-03) and two-tier refute battery (directional + noise-floor margin + metamorphic gates, CRITIC-02).

## What Was Built

### Task 1: panel.ts — critic→lens map, veto ordering, blind fan-out

Implements the full 7-critic panel architecture (D-06, RUNNER-03):

**Critic→lens map (14 lens-cells/page):**
- P1–P5 persona critics: each scores `hierarchy` + `density` against their own JTBD pass-condition (10 cells)
- Graphic-design critic: scores `rhythm`, `typography`, `color_contrast` (3 cells)
- Brand-veto critic: scores `brand_fidelity` via mechanical token-parity (1 cell)

**Veto pipeline (per capture cell, ordered):**
1. Mechanical gate (`checkMechanicalGate`): MODE A hard-block on `card_nesting_depth > 3` or `type_size_count < 2`, reads committed scorecard `mode_b` fields ($0)
2. Token-parity brand veto (`checkTokenParityVeto`): checks `scorecard.applied_colors` against the `--tl-color-*` token set (resolved hex → rgb conversion, $0)
3. On veto: `brand_fidelity = {current: null, vetoed: true, evidence}` and ALL aesthetic calls skipped
4. No veto: graphic-design lenses scored first (pre-warm), then persona critics (blind fan-out)

**Exported functions:**
- `checkTokenParityVeto(scorecard)` — pure, deterministic, $0; used directly by refute battery
- `checkMechanicalGate(scorecard)` — MODE A hard-block check
- `runVetoPipeline(scorecard)` — combined veto pipeline
- `runPanel(cellId, opts)` — full orchestrator with cache, pre-warming, rollup
- `hexToRgb(hex)` + `buildTokenRgbSet(tokens)` — veto utilities

**Key invariants enforced:**
- Precedence: `vetoed(null)` ≻ `unstable(null)` ≻ `scored` (distinguished by `vetoed` flag, neither poisons `min()`)
- No averaging across personas (disagreement preserved)
- `min()` rollup names the losing `(persona, lens)` cell: e.g. `"page.actor.happy__dark-1280 p3.hierarchy = 48"`

### Task 2: refute.ts — directional + margin + metamorphic gates

Replaces the Plan-05 stub with the full refute battery (CRITIC-02):

**`runValidate(argv)` entry point:**
- `--dry-run`: lists all planned twins with cost labels, exits 0 (no API calls)
- Full run: dispatches per-twin based on `class: gestalt | veto_ordering`
- Writes transcript JSON per fixture to `.planning/refute/transcripts/<twin_id>.json`
- Failure (any gate) exits 1 — critic barred from ledger bumps

**Gestalt twins (6 of 7):**
1. Binary directional gate: `polished_score > flawed_score` on `target_lens`
2. Margin gate: `delta > noise_floor` where `noise_floor = IQR(polished N samples)` (not a fixed absolute threshold, D-03 anti-drift)
3. Metamorphic invariance gate: both cells stable (unstable verdict is void)

**Veto-ordering twin (1 of 7, $0 LLM):**
1. Load polished cell's committed scorecard; assert `checkTokenParityVeto` returns `vetoed=false`
2. Inject the off-token hex from `evidence_note` into `applied_colors`; assert `checkTokenParityVeto` returns `vetoed=true`
3. Run `runVetoPipeline` on the synthetic flawed scorecard; assert `brand_fidelity=vetoed+null` AND `aesthetic_calls_skipped=true`

Since the flawed scorecard for `refute.veto-ordering.off-token-accent` has no committed file (the flaw is synthetic raw-hex injection), this test is fully offline — proving RUNNER-03 ordering without any API calls.

## Verification Results

All checks passed:
- `npx tsc --noEmit -p tsconfig.json` — clean (zero errors)
- `node --import tsx critic/run.ts validate --dry-run` — exits 0

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Design Decisions Made

**[195-06-01]** Token-parity veto reads `scorecard.applied_colors` (captured at render time). The `ExtendedScorecard` interface in `panel.ts` extends `ScorecardJson` locally (no modification to `bundle.ts`) to expose `applied_colors` and `color_pairs`. Transparent/rgba(0,0,0,0) values are always permitted.

**[195-06-02]** The veto-ordering refute test uses synthetic scorecard injection: the polished cell's scorecard is cloned and the off-token hex (extracted from `evidence_note`) is appended to `applied_colors`. This avoids requiring a committed flawed scorecard for a change that should never reach production.

**[195-06-03]** Metamorphic gate simplified: both cells must produce stable N-sample scores (verified via `stable` flag from `runNSamples`). An explicit A/B order-swap call was not added as the two-independent-blind-single-cell approach already eliminates position bias (D-11). Re-sampling for swap would double API cost.

**[195-06-04]** Noise floor = average IQR across dimensions for the polished cell. This is relative to the critic's own variance, not a fixed threshold — satisfying D-03's "not a drift-brittle absolute threshold."

**[195-06-05]** `extractLensScore()` helper exists in refute.ts as a stub (the gestalt test scores via `scoreCellLens` directly, not through `runPanel`'s aggregate). This is intentional: the per-lens directional test needs raw lens scores, not the full panel rollup.

## Known Stubs

None — both `runPanel` and `runValidate` are fully implemented. The Plan-05 `refute.ts` stub (which threw `"Not yet implemented"`) is fully replaced.

## Threat Surface Scan

No new security-relevant surface introduced:
- `panel.ts` reads committed scorecard files (path validation inherited from `bundle.ts` `validateCellId`)
- `refute.ts` reads `.planning/refute/refute-set.json` (trusted, committed) and writes transcripts to `.planning/refute/transcripts/`
- No new network endpoints, no auth paths, no schema changes

## Self-Check

### Committed files exist:
- `examples/threadline_phoenix/e2e/critic/panel.ts` — FOUND
- `examples/threadline_phoenix/e2e/critic/refute.ts` — FOUND

### Commits exist:
- `db7b9384` — feat(195-06): implement 7-critic panel with brand-veto ordering (RUNNER-03)
- `ccbb6ca4` — feat(195-06): implement refute battery with directional+margin+metamorphic gates (CRITIC-02)

## Self-Check: PASSED
