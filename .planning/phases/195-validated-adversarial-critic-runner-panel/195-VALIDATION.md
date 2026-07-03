---
phase: 195
slug: validated-adversarial-critic-runner-panel
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-03
---

# Phase 195 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir, existing) + `tsc --noEmit` / `node --import tsx` for the TypeScript critic runner (no new framework install) |
| **Config file** | Existing `mix.exs` (aliases + preferred_envs) + new `examples/threadline_phoenix/e2e/tsconfig.json` (ESM, strict, scoped to `critic/**`) |
| **Quick run command** | `mix verify.critic_trust` (pure-Elixir gate, no network) · `cd examples/threadline_phoenix/e2e && npx tsc --noEmit -p tsconfig.json` (TS type-check) |
| **Full suite command** | `mix ci.all` (includes `verify.critic_trust` before `verify.mechanical`; excludes local-only `verify.ui_critique`) |
| **Estimated runtime** | quick ~5–15s · `tsc --noEmit` ~10s · full `mix ci.all` ~2–4 min |

*Note: `verify.ui_critique` is local-only (needs `ANTHROPIC_API_KEY`, calls the Claude API) and is deliberately excluded from `ci.all` — the `verify.flake` precedent. It no-ops with exit 0 when the key is absent.*

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command (Elixir: `mix verify.critic_trust` or the task-scoped `mix test`; TypeScript: `npx tsc --noEmit -p tsconfig.json`)
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** ~15s (quick) / ~4 min (full `ci.all`)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 195-01-01 | 01 | 1 | RUNNER-05 | T-195-SC / T-195-03 | SDK/toolchain stays an e2e devDependency; no runtime `dependencies` block | config/unit | `cd examples/threadline_phoenix/e2e && node -e "const p=require('./package.json'); const d=p.devDependencies||{}; if(!(d['@anthropic-ai/sdk']&&d.zod&&d.typescript&&d.tsx)) process.exit(1); if((p.dependencies&&Object.keys(p.dependencies).length)) process.exit(2); process.exit(0)"` | ✅ | ⬜ pending |
| 195-01-02 | 01 | 1 | RUNNER-04, RUNNER-05 | T-195-01 / T-195-03 | Local-only critic no-ops (exit 0) without key; root stays Phoenix-optional | integration | `ANTHROPIC_API_KEY="" mix verify.ui_critique && mix verify.compile_no_optional` | ✅ | ⬜ pending |
| 195-01-03 | 01 | 1 | CRITIC-03 | T-195-02 | Trust gate seeds `validated:false`; nothing ratchets pre-Plan-04 | unit | `mix verify.critic_trust && mix test test/threadline/operator_surface/stress_ledger_test.exs` | ✅ | ⬜ pending |
| 195-02-01 | 02 | 1 | CRITIC-04 | T-195-04 | Versioned/anchored adversarial rubrics; cite-before-score | doc/structure | `test $(ls examples/threadline_phoenix/e2e/critic/rubrics/{hierarchy,density,rhythm}.md 2>/dev/null | wc -l) -eq 3 && grep -lq "Reference bar" examples/threadline_phoenix/e2e/critic/rubrics/hierarchy.md && grep -lq "Anchors" examples/threadline_phoenix/e2e/critic/rubrics/hierarchy.md` | ✅ | ⬜ pending |
| 195-02-02 | 02 | 1 | CRITIC-04 | T-195-04 / T-195-05 | 13-dimension set complete; brand_fidelity post-veto | doc/structure | `test $(ls examples/threadline_phoenix/e2e/critic/rubrics/{typography,color_contrast,brand_fidelity}.md 2>/dev/null | wc -l) -eq 3 && grep -lq "Anchors" examples/threadline_phoenix/e2e/critic/rubrics/brand_fidelity.md` | ✅ | ⬜ pending |
| 195-03-01 | 03 | 1 | CRITIC-02 | T-195-07 | Refute twins are committed fixtures (no runtime CSS injection) | unit | `mix compile --warnings-as-errors && grep -c 'refute' lib/threadline/operator_surface/stress_fixtures.ex | grep -qv '^0$'` | ✅ | ⬜ pending |
| 195-03-02 | 03 | 1 | CRITIC-02 | T-195-07 / T-195-08 | Gestalt flaws PASS mechanics (partition); refute disjoint from golden | unit | `mix verify.mechanical && mix test test/threadline/operator_surface/refute_partition_test.exs` | ✅ | ⬜ pending |
| 195-04-01 | 04 | 2 | CRITIC-03 | T-195-13 | Chance-corrected α (De=0→1.0, negative not clamped, insufficient→error) | unit (TDD) | `mix test test/threadline/critic_trust/krippendorff_alpha_test.exs` | ✅ | ⬜ pending |
| 195-04-02 | 04 | 2 | CRITIC-03, CRITIC-04 | T-195-10 / T-195-11 / T-195-12 | Per-lens bar + rubric-hash freshness + golden + disjointness guards | unit | `mix verify.critic_trust && mix ci.all` | ✅ | ⬜ pending |
| 195-05-01 | 05 | 2 | RUNNER-01, CRITIC-05 | T-195-15 | Schema requires located evidence (uncited score discarded, not scored) | type-check | `cd examples/threadline_phoenix/e2e && npx tsc --noEmit -p tsconfig.json` | ✅ | ⬜ pending |
| 195-05-02 | 05 | 2 | RUNNER-02 | T-195-16 / T-195-17 / T-195-18 | N-sample median/variance, unstable→null, writes only under critic-scores/ | type-check | `cd examples/threadline_phoenix/e2e && npx tsc --noEmit -p tsconfig.json` | ✅ | ⬜ pending |
| 195-05-03 | 05 | 2 | RUNNER-01, RUNNER-02 | T-195-14 | Empty-golden / dry-run exit 0 (guided path, never dead-ends) | type-check + smoke | `cd examples/threadline_phoenix/e2e && npx tsc --noEmit -p tsconfig.json && node --import tsx critic/run.ts score --dry-run; test $? -eq 0` | ✅ | ⬜ pending |
| 195-06-01 | 06 | 3 | RUNNER-03 | T-195-19 | Veto skips ALL aesthetic vision calls; vetoed/unstable both null | type-check | `cd examples/threadline_phoenix/e2e && npx tsc --noEmit -p tsconfig.json` | ✅ | ⬜ pending |
| 195-06-02 | 06 | 3 | RUNNER-03, CRITIC-02 | T-195-20 / T-195-21 | Directional + noise-floor-relative margin + metamorphic gates | type-check + smoke | `cd examples/threadline_phoenix/e2e && npx tsc --noEmit -p tsconfig.json && node --import tsx critic/run.ts validate --dry-run; test $? -eq 0` | ✅ | ⬜ pending |
| 195-07-01 | 07 | 3 | CRITIC-01 | T-195-24 | CRITIQUE.md is a regenerated projection (never hand-edited) | type-check + file | `cd examples/threadline_phoenix/e2e && npx tsc --noEmit -p tsconfig.json && test -f ../../../../.planning/CRITIQUE.md` | ✅ | ⬜ pending |
| 195-07-02 | 07 | 3 | CRITIC-01 | T-195-22 / T-195-23 | Blind r1/r2 enforced; CLI sole golden-set writer; held_out refused | type-check + smoke | `cd examples/threadline_phoenix/e2e && npx tsc --noEmit -p tsconfig.json && node --import tsx critic/run.ts rubric lint; test $? -eq 0` | ✅ | ⬜ pending |
| 195-07-03 | 07 | 3 | CRITIC-01 | T-195-25 | Maintainer-local labeling + scoring + trust measurement (see Manual-Only) | manual | *(human checkpoint — see Manual-Only Verifications)* | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements (ExUnit + `tsc`/`tsx`); **no framework install needed**.

The following are existing-infra additions authored inside their plans (not Wave-0 framework stubs):

- `test/threadline/operator_surface/critic_trust_test.exs` — green pure-Elixir trust guard stub seeded in Plan 01 (Task 3), expanded to the full gate in Plan 04 (Task 2).
- `test/threadline/critic_trust/krippendorff_alpha_test.exs` — RED-first TDD edge-case tests written before the α module in Plan 04 (Task 1).
- `test/threadline/operator_surface/refute_partition_test.exs` — partition-rule guard authored in Plan 03 (Task 2).
- `examples/threadline_phoenix/e2e/tsconfig.json` — TS type-check config created in Plan 01 (Task 1); enables `tsc --noEmit` for all `critic/*.ts`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Golden-set labeling, refute proof, and trust measurement (195-07 Task 3) | CRITIC-01 | Requires `ANTHROPIC_API_KEY` + human aesthetic judgment; runs outside CI; rescoring is never auto-green | 1. Ensure `ANTHROPIC_API_KEY` is set locally (never commit it). 2. Seed + blind-label: `cd examples/threadline_phoenix/e2e && npm run critic:label -- --bootstrap`, complete `--round r1`, commit `rounds/r1.json`, then `--round r2` (reshuffled), then `--reconcile`; target ≥20 lens-judgments/critic-bearing lens (`--status` shows the bar; lenses under 20 stay `provisional`). 3. Prove the critic: `mix verify.ui_critique --refute-only` (refute battery must pass). 4. Measure agreement + write `critic_trust`: `mix verify.ui_critique` scoring the golden cells, then the trust recompute (a lens is `validated:true` ONLY if α≥0.67 AND n≥20 AND raw≥80% at current rubric+model). 5. Regenerate: `npm run critic:score` report step → confirm `.planning/CRITIQUE.md` is fresh. 6. Confirm CI stays honest: `mix ci.all` green. Commit golden set, rounds, critic-scores, CRITIQUE.md, and the `critic_trust` block as one reviewed commit. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (195-07 Task 3 is the sole intentional manual human checkpoint — documented above)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — existing ExUnit + tsc/tsx infra)
- [x] No watch-mode flags
- [x] Feedback latency < ~15s quick / ~4 min full
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
