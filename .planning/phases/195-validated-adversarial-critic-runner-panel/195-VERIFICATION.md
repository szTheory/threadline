---
phase: 195-validated-adversarial-critic-runner-panel
verified: 2026-08-26T00:00:00Z
status: gaps_found
score: 5/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "mix ci.all stays green (plan 195-01 truth 3; plan 195-04 verification 'ci.all green')"
    status: failed
    reason: >
      verify.test (runs before verify.critic_trust inside ci.all) has 8 failures at HEAD
      that are NOT the pre-existing search_path baseline: 7 StressLedgerTest failures +
      1 LedgerSpliceTest failure. Root cause is phase-195's own commits: 195-03 (099afbaa)
      added kind:"refute" ledger entries with current_score:null that stress_ledger_test's
      frozen entry contract rejects; the D-12 pivot commit (aef9e655) added the
      critic_trust_provenance top-level key and refute.*.graded.* fixtures to
      StressFixtures.all() without registering the graded-twin stories in the ledger or
      updating @top_level_keys; aef9e655 also changed LedgerSplice's error atom from
      :critic_trust_not_found to :object_key_not_found without updating
      ledger_splice_test.exs. Phase 196-02 independently confirmed the identical 8-failure
      count on the pre-196 tree and logged it to its deferred-items.md as a
      "Phase-195 synthetic-oracle fixture-registry gap".
    artifacts:
      - path: ".planning/design-system-ledger.json"
        issue: "entries missing refute.*.graded.* stories referenced by StressFixtures.all(); refute-kind entries violate the frozen entry contract (non-integer current_score, uncontracted kind)"
      - path: "test/threadline/operator_surface/stress_ledger_test.exs"
        issue: "@top_level_keys and entry contract never updated for critic_trust_provenance (195/aef9e655) — nor for 196's critic_panel/mechanical_auto_apply additions"
      - path: "test/threadline/critic_trust/ledger_splice_test.exs"
        issue: "asserts {:error, :critic_trust_not_found}; LedgerSplice now returns {:error, :object_key_not_found} since aef9e655"
    missing:
      - "Register the graded-twin stories in the ledger (or contract them out of the fixture-registry assertion)"
      - "Extend the stress_ledger_test top-level-key and entry-kind contracts to cover the ratified refute/graded/provenance shapes"
      - "Reconcile ledger_splice_test's expected error atom with the generalized LedgerSplice"
deferred:
  - truth: "Full-suite guard integrity restored (stress_ledger + ledger_splice green)"
    addressed_in: "Phase 196 (tracked) / Phase 197 (closeout)"
    evidence: >
      196-02-SUMMARY.md + 196 deferred-items.md record all 8 failures with root-cause
      analysis; Phase 197 roadmap SC: "adversarial closeout confirming the loop can't
      regress the deterministic floor and all invariants hold". NOTE: kept as a real gap
      above (not silently absorbed) because no later phase's roadmap SC names these test
      files explicitly — deferral evidence is tracking-level, not contract-level.
---

# Phase 195: Validated Adversarial Critic Runner & Panel — Verification Report

**Phase Goal:** A local-only Claude-vision critic panel (P1–P5 + graphic-design + brand-veto) exists, cites concrete evidence for every score, runs behind `mix verify.ui_critique`, and is proven trustworthy against a golden set before it may drive any ratchet — Anthropic SDK stays an `e2e` devDependency, root `threadline` gains no runtime dependency.
**Verified:** 2026-08-26
**Status:** gaps_found (core goal achieved; one plan-level must-have — suite-green hygiene — failed)
**Re-verification:** No — initial verification
**Mode note:** Judged against the **ratified D-12 pivot** (commit `aef9e655`, ratified 2026-07-28): trust = synthetic twin oracle + Spearman-ρ ranking gate, not Krippendorff-α human agreement. Substitutions are noted per-truth below, per the dispatch instructions.

## Goal Achievement

### Observable Truths (merged: ROADMAP SC 1–5 + plan must-haves)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 — Oracle with verdicts + versioned anchored per-lens rubrics exist (CRITIC-01, CRITIC-04) | ✓ VERIFIED (ratified substitution) | `.planning/golden/synthetic-set.json`: 144 graded-severity items (`critic_trust_provenance.oracle="synthetic"`, set 195.12.0). `golden-set.json` items is deliberately empty — the hand-labeling lane (`label.ts`, blind r1/r2, `--reconcile` sole writer) exists but the ratified oracle is synthetic (zero labeling, D-12). 6 rubrics in `e2e/critic/rubrics/` with version headers, 13 dimensions (3+2+2+2+2+2 per D-05), Reference bar + Anchors; pole cell-ids resolve to committed `.planning/scorecards/*.json` (spot-checked hierarchy + brand_fidelity poles) |
| 2 | SC2 — Refute-tests + trust threshold gate ratcheting (CRITIC-02, CRITIC-03) | ✓ VERIFIED (ratified substitution) | Deterministic substrate: `.planning/refute/refute-set.json` (7 twins: 6 gestalt + 1 veto_ordering), `refute_partition_test.exs` green (partition rule + golden disjointness), `mix verify.mechanical` green (18 tests). Trust gate: `mix verify.critic_trust` green (22 tests) enforcing ρ≥0.7 ∧ n≥20 per validated lens + rubric-hash freshness + oracle-inventory/held-out guards + panel-membership freeze. Ledger records the ratified panel: brand_fidelity ρ0.926, density ρ0.839, typography ρ0.772, rhythm ρ0.761 `validated:true`; hierarchy ρ0.418 + color_contrast ρ0.698 `validated:false` (advisory — cannot block). The LLM-side refute run was maintainer-ratified at the 195-07 blocking checkpoint (closed 2026-08-26); committed AUC=1.0 on density/brand corroborates polished>flawed separation |
| 3 | SC3 — Evidence-or-discard law (CRITIC-05) | ✓ VERIFIED | `schema.ts`: `evidence{kind: enum(region\|selector\|mechanical_line), locator: z.string().min(1), observation}` REQUIRED, evidence-first field order (cite-before-score, D-11); `messages.parse()` rejects uncited scores structurally. `report.ts`/CRITIQUE.md render cited locators per finding |
| 4 | SC4 — Runner core + N-sample + 7-critic panel + brand-veto ordering (RUNNER-01/02/03) | ✓ VERIFIED | All 7 planned modules (+`gate.ts`/`rubric.ts`/`label_web.ts`/`report_html.ts` from gap work) exist and are substantive; `npx tsc --noEmit` clean. `client.ts`: no temperature/top_p/top_k/budget_tokens, N=3→7 escalation, median + band-of-median + band-mode + IQR>10/range>15 → unstable → **null never 0**, model_id/rubric_version stamping. `panel.ts`: P1–P5 → p{n}.hierarchy+density, graphic-design → all.rhythm/typography/color_contrast, brand-veto → all.brand_fidelity (14 lens-cells/page); veto pipeline mechanical→token-parity→skip-all-aesthetic; precedence vetoed≻unstable≻scored; no persona averaging; min()-losing cell named. `refute.ts`: directional + noise-floor-relative margin + metamorphic gates. Wired: `run.ts` ← npm `critic:*` scripts ← `verify_ui_critique/1` in mix.exs |
| 5 | SC5 — Local-only entrypoint + dependency invariants (RUNNER-04/05) | ✓ VERIFIED | Live-run: `ANTHROPIC_API_KEY="" mix verify.ui_critique` → exit 0 with skip message. `ci.all` list contains `verify.critic_trust` immediately before `verify.mechanical` and does NOT contain `verify.ui_critique`. CONTRIBUTING.md §"Local-only critic (verify.ui_critique)" + "excluded from ci.all" line (same standard as the verify.flake precedent — comment + doc section, no test lock exists for either). e2e package.json: @anthropic-ai/sdk ^0.110.0, zod, typescript, tsx under devDependencies only, **no** `dependencies` block. `mix verify.compile_no_optional` green — root gains no runtime dependency |
| 6 | Plan truth — `mix ci.all` stays green | ✗ FAILED | `verify.test` lane: 8 failures at HEAD (7 StressLedgerTest + 1 LedgerSpliceTest), distinct from the ~11 pre-existing search_path baseline, introduced by 195's own commits (099afbaa refute ledger entries; aef9e655 provenance key + graded fixtures + LedgerSplice error-atom change). See gaps frontmatter |

**Score:** 5/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mix.exs` aliases | verify.ui_critique (local-only) + verify.critic_trust (ci.all) | ✓ VERIFIED | Lines 106–111, 242–272; preferred_env :test; `--` flag passthrough (195-08 fix) present |
| `e2e/package.json` + `tsconfig.json` | SDK toolchain devDeps only | ✓ VERIFIED | 4 required devDeps; critic:score/gate/validate/label/rubric scripts |
| `e2e/critic/rubrics/*.md` ×6 | 13 adversarial dimensions, anchors | ✓ VERIFIED | Headers `<!-- lens \| version 1.0.0 \| sha8: 00000000 -->` — see warning below |
| `e2e/critic/{schema,prompt,bundle,client,scorecard,cache,run,panel,refute,report,label}.ts` | Runner + panel + surfaces | ✓ VERIFIED | All present, substantive, tsc-clean |
| `lib/threadline/critic_trust/{krippendorff_alpha,measure,ledger_splice,rank_metrics}.ex` + `lib/mix/tasks/critic.measure.ex` | Trust measurement writer | ✓ VERIFIED | measure_test + krippendorff_alpha_test green (ledger_splice_test has the 1 error-atom failure — gap #1) |
| `.planning/refute/refute-set.json` | 7-twin manifest | ✓ VERIFIED | 6 gestalt + 1 veto_ordering, lens + direction + class per twin |
| `.planning/golden/{golden-set,synthetic-set,queue}.json` + `rounds/.gitkeep` | Oracle | ✓ VERIFIED | Synthetic oracle 144 items; golden items empty by ratified design; rounds empty (zero-labeling pivot) |
| `.planning/design-system-ledger.json` `critic_trust` block | Measured per-lens trust | ✓ VERIFIED | 9-field D-12 shape (spearman/auc added); 4 validated / 2 advisory |
| `.planning/CRITIQUE.md` | Regenerated projection | ✓ VERIFIED | Generated 2026-07-29, legend (symbol+word+reason, never color-only), baseline in header, freshness-guarded by critic_trust_test (green) |
| `.planning/critic-scores/` | Gitignored LLM output tree | ✓ VERIFIED | 150 local score dirs; `.gitignore` lines 67–69 keep only .gitkeep tracked |
| 195-09 PLAN/SUMMARY | Gap-plan documentation | ℹ️ ABSENT | 195-09 exists only as commits (34753f7c…082105d3) + a ROADMAP checklist line; no PLAN.md/SUMMARY.md in the phase dir. Storybook capture lane (`capture:storybook` script, 24 committed `story.*` scorecards) verified in-code |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `mix ci.all` | critic_trust_test.exs | verify.critic_trust alias, before verify.mechanical | ✓ WIRED (ran green) |
| `verify.ui_critique` | `npm run critic:score` | System.cmd, only when ANTHROPIC_API_KEY present; `--` passthrough | ✓ WIRED (no-op path exercised) |
| rubric bytes | trust invalidation | sha8 recompute in critic_trust_test | ⚠️ WIRED BUT DORMANT — all six rubrics + ledger stamps carry placeholder `00000000`, so the freshness sub-check is vacuous by documented convention; a rubric edit today would NOT auto-invalidate its lens |
| synthetic oracle + critic scores | validated flags | `mix critic.measure` → LedgerSplice → ledger → guard | ✓ WIRED (idempotence + promotion tested in measure_test) |
| refute-set.json | panel/refute gates | refute.ts reads manifest + scorecards; partition guard in CI | ✓ WIRED |
| validated flags | Phase-196 ratchet | critic_panel membership-freeze test (196-01) consumes critic_trust | ✓ WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No-key no-op (RUNNER-04) | `ANTHROPIC_API_KEY="" mix verify.ui_critique` | exit 0, skip message | ✓ PASS |
| Trust gate | `mix verify.critic_trust` | 22 tests, 0 failures | ✓ PASS |
| Mechanical floor | `mix verify.mechanical` | 18 tests, 0 failures | ✓ PASS |
| Root Phoenix-optional (RUNNER-05) | `mix verify.compile_no_optional` | clean compile | ✓ PASS |
| TS type integrity | `npx tsc --noEmit -p e2e/tsconfig.json` | exit 0 | ✓ PASS |
| Critic-trust units + partition | `mix test test/threadline/critic_trust/ refute_partition stress_ledger` | 51 tests, **8 failures** (all in the gap-#1 group; krippendorff/measure/refute_partition all green) | ✗ FAIL (gap #1) |
| LLM lanes (`critic:score/validate`, `run.ts --dry-run`) | not run | — | ? SKIP — maintainer-local/paid per dispatch instructions; already human-ratified at the 195-07 checkpoint |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| CRITIC-01 | 195-07, 195-08 | ✓ SATISFIED (ratified substitution) | Synthetic oracle with verdicts + label.ts human lane + measured trust panel |
| CRITIC-02 | 195-03, 195-06 | ✓ SATISFIED | Refute substrate + partition proof in CI; LLM battery maintainer-ratified |
| CRITIC-03 | 195-04, 195-08 | ✓ SATISFIED (ratified substitution) | ρ-gate replaces α-agreement threshold (α recorded as companion); below-bar lens cannot be validated → cannot block/ratchet |
| CRITIC-04 | 195-02, 195-04 | ✓ SATISFIED | 6 versioned anchored rubrics, 13 adversarial dimensions (sha8 stamping dormant — see warning) |
| CRITIC-05 | 195-05 | ✓ SATISFIED | Required evidence{kind,locator} in schema.ts |
| RUNNER-01 | 195-05 | ✓ SATISFIED | messages.parse + zodOutputFormat, 3-strata cached prefix, one dimension/call |
| RUNNER-02 | 195-05 | ✓ SATISFIED | N=3→7 median/IQR/range, unstable→null, model+rubric stamping |
| RUNNER-03 | 195-06 | ✓ SATISFIED | 7-critic map, veto-before-aesthetic, precedence + blindness |
| RUNNER-04 | 195-01, 195-08 | ✓ SATISFIED | Live no-op proof; excluded from ci.all; CONTRIBUTING lock (flake-precedent standard) |
| RUNNER-05 | 195-01 | ✓ SATISFIED | devDeps-only + compile_no_optional green |

**Orphaned requirements:** none — REQUIREMENTS.md maps exactly these 10 IDs to Phase 195.
**Tracking drift (⚠️):** REQUIREMENTS.md still shows CRITIC-01, CRITIC-05, RUNNER-01, RUNNER-02 as unchecked/"Pending" although the phase (incl. checkpoint close-out 2026-08-26) satisfied them — the traceability table was never updated after 195-05/195-07 closed.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `e2e/critic/label.ts` | 693 | `TODO: wire pair tokens when pair mode is implemented` | ℹ️ Info | Matches the documented, non-gating `pairwise_acc: null` limitation (195-08-C) |
| rubrics + ledger stamps | — | sha8 `00000000` placeholder on all 6 lenses | ⚠️ Warning | Rubric-hash auto-invalidation (plan-04 truth) is dormant until rubrics are stamped; guard code exists and self-documents the convention |

No TBD/FIXME/XXX markers in phase-touched files. No stub implementations found — all critic modules are substantive (panel.ts ~650 lines, critic_trust_test.exs 847 lines).

### Gaps Summary

The phase goal is **achieved in substance** under the ratified D-12 pivot: the 7-critic evidence-citing panel exists and is wired behind `mix verify.ui_critique` (clean no-op without a key, excluded from `ci.all`), the trust machinery is real and measured (4 lenses validated on Spearman-ρ, 2 correctly demoted to advisory), the deterministic refute/partition/trust guards run green in CI, and both dependency invariants hold.

One must-have failed: **`mix ci.all` is not green at HEAD for reasons phase 195 itself introduced.** The D-12 pivot commit (aef9e655) and the refute-fixture work left `stress_ledger_test.exs` and `ledger_splice_test.exs` un-reconciled with the new ledger shape (graded-twin stories unregistered, `critic_trust_provenance` key uncontracted, refute entry kind/score shape uncontracted, LedgerSplice error atom renamed) — 8 failures in `verify.test`, which runs before the critic gates inside `ci.all`. Phase 196-02 independently confirmed and logged these as a Phase-195 gap in its deferred-items.md. This does not undermine the critic/trust machinery (all critic-specific guards are green) but it does break the "CI stays honest" contract the phase's own plans asserted, and it weakens the deterministic ledger guard while Phase 196's gate work is in flight. Recommend a small reconciliation plan (`/gsd-plan-phase --gaps`) or folding the fix into the 196 closeout.

Secondary notes: rubric sha8 stamping is a dormant placeholder (auto-invalidation inactive); REQUIREMENTS.md traceability rows for 4 satisfied IDs were never flipped; gap-plan 195-09 has no PLAN/SUMMARY artifacts (commits + ROADMAP line only).

---

_Verified: 2026-08-26_
_Verifier: Claude (gsd-verifier)_
