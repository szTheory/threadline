---
phase: 195-validated-adversarial-critic-runner-panel
plan: "05"
subsystem: critic_runner
tags: [claude-vision, messages-parse, zod-output, cached-prefix, n-sample, self-consistency, critic-scores]
dependency_graph:
  requires: [195-01, 195-02]
  provides: [RUNNER-01, RUNNER-02, CRITIC-05]
  affects: [examples/threadline_phoenix/e2e/critic, .planning/critic-scores]
tech_stack:
  added: ["@anthropic-ai/sdk messages.parse + zodOutputFormat", "zod schema", "tsx ESM runner"]
  patterns: [three-strata cached prefix, ESM import.meta.url repoRoot, N-sample median/band-of-median, unstable->null, evidence-or-discard]
key_files:
  created:
    - examples/threadline_phoenix/e2e/critic/schema.ts
    - examples/threadline_phoenix/e2e/critic/prompt.ts
    - examples/threadline_phoenix/e2e/critic/bundle.ts
    - examples/threadline_phoenix/e2e/critic/client.ts
    - examples/threadline_phoenix/e2e/critic/scorecard.ts
    - examples/threadline_phoenix/e2e/critic/cache.ts
    - examples/threadline_phoenix/e2e/critic/run.ts
  modified: []
decisions:
  - "[195-05-A] Evidence required at the schema layer (CRITIC-05): evidence{kind,locator,observation}
    is non-optional in the Zod CriticDimensionSchema, so messages.parse() discards any uncited score
    rather than writing it — the tampering mitigation for T-195-15."
  - "[195-05-B] N-sample self-consistency on RAW scores with band-of-median: point = median(raw),
    band = band(median) on cuts {0,35,55,70,85}; unstable (band-mode < ceil(N/2) OR IQR>10 OR range>15)
    => current:null NEVER 0, so unstable cells cannot poison the min() rollup (D-04, D-10)."
  - "[195-05-C] No sampling params sent to Opus 4.8: temperature/top_p/top_k/budget_tokens are never
    passed (400 on Opus 4.8); adaptive thinking display:summarized; score clamped 0-100 client-side
    after parse since the SDK strips numeric bounds."
  - "[195-05-D] Output isolation: scorecard.ts writes only under .planning/critic-scores/, never
    .planning/scorecards/ (T-195-16 guard in critic_trust_test.exs); verdict cache keyed
    {cell}__{dim}__{rubric_hash}__{model_id} for free resume/replay."
metrics:
  duration: "stalled at SUMMARY write; closed out by orchestrator"
  completed: "2026-07-03"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 0
  files_created: 7
status: complete
---

# Phase 195 Plan 05: Node Runner Core Call Path Summary

The runner's core call path — the module chain that turns one capture cell + one lens-dimension into a stamped, evidence-cited, self-consistency-averaged critic score. Delivers RUNNER-01 (SDK structured-output call with a >4096-token cached prefix, one dimension per call), RUNNER-02 (N-sample median + variance + unstable→null + stamping), and CRITIC-05 (evidence-or-discard enforced at the Zod schema layer).

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | schema.ts (CRITIC-05) + prompt.ts (3-strata cached prefix) + bundle.ts | `9cea5e2f` | `critic/schema.ts`, `critic/prompt.ts`, `critic/bundle.ts` |
| 2 | client.ts (N-sample + variance + stamping) + scorecard.ts + cache.ts | `85d1bde5` | `critic/client.ts`, `critic/scorecard.ts`, `critic/cache.ts` |
| 3 | run.ts CLI dispatcher (score path + dry-run/empty-state exits) | `6534655a` | `critic/run.ts` (+ Plan 06/07 lazy-import stubs) |

## What Was Built

### Task 1: schema.ts + prompt.ts + bundle.ts
- **schema.ts** — Zod `CriticDimensionSchema` with locked field order `evidence{kind(region|selector|mechanical_line), locator REQUIRED, observation} → pass → band → score → lens`. Evidence and its `kind`+`locator` are required, so `parse()` discards any uncited score (CRITIC-05). Exports `zodOutputFormat(schema)`.
- **prompt.ts** — the three byte-stable strata: frozen adversarial **system** (role = adversarial critic, default verdict FAIL, evidence law, gestalt-only never re-measure, no-praise) shared across lenses; **cached prefix** (rubric text + reference-bar + two pole exemplar IMAGES) with `cache_control:{type:"ephemeral"}` on the LAST prefix block to clear the 4096-token floor; **uncached suffix** (target screenshot, mechanical evidence lines, aria snapshot, persona pass-condition clause LAST). Pinned `MODEL_ID`/`SCHEMA_VERSION`; no `Date.now()` in committed output.
- **bundle.ts** — reads the deterministic Tier-B input for a cell via ESM `import.meta.url` path resolution (`repoRoot = resolve(here,"../../../..")`); downsamples the screenshot PNG to ~1092px long edge as base64; loads the aria snapshot when present.

### Task 2: client.ts + scorecard.ts + cache.ts
- **client.ts** — wraps the Anthropic SDK; calls `messages.parse({model:"claude-opus-4-8", thinking:{type:"adaptive",display:"summarized"}, output_config:{format:zodOutputFormat(...)}})`. **Never** sends temperature/top_p/top_k/budget_tokens. Clamps score 0–100 client-side after parse; relies on SDK auto-retry for 429/5xx. N-sample loop: N=3 default, point = median(raw), band = band(median) on cuts {0,35,55,70,85}, band-mode stability; escalates to N=7 on no-majority-band / median within ±2pts of a cut / within ≤5pts of floor-target; RAW variance gates IQR>10 or range>15 ⇒ unstable ⇒ `current:null` (never 0). Warns if cache-creation tokens ≤4096 or cache-read is 0 on identical-prefix follow-ups.
- **scorecard.ts** — writes one file per `(cell,lens,dimension)` under `.planning/critic-scores/<cell>/<lens>/<dim>.json`, stamping `model_id, rubric_version, n, scores_raw, score, band, band_mode, iqr, range, stable, pass, evidence, rationale, scored_at`; two-space + trailing-newline `writeJson`; never writes under `.planning/scorecards/`.
- **cache.ts** — verdict cache keyed `{cell}__{dim}__{rubric_hash}__{model_id}` → fs JSON for free resume/replay (skips billed calls on hit).

### Task 3: run.ts CLI dispatcher
- CLI entry + subcommand dispatcher: `score` fully wired through `bundle → prompt → client → cache → scorecard`; `validate|label|rubric` routed via lazy dynamic import (panel/refute land in Plan 06, report/label in Plan 07), so `run.ts` is the sole owner and missing modules only error when their subcommand is invoked.
- `score` flags: `--page, --lens, --theme, --changed, --refute-only, --dry-run, --force`. `--dry-run` prints the ~$0.45 / $12 / $23 budget bands via token estimation with no billed calls. First-run empty-golden `score` prints a guided path (`critic label --bootstrap`) and exits 0 — never dead-ends. Reads `ANTHROPIC_API_KEY` from env (the Elixir alias owns the no-key skip). ESM path resolution + pinned constants.

## Verification Results

```
cd examples/threadline_phoenix/e2e && npx tsc --noEmit -p tsconfig.json
TSC_EXIT=0  (clean across critic/*.ts)

node --import tsx critic/run.ts score --dry-run
DRYRUN_EXIT=0  (prints budget bands: scoped ~$0.45, full sweep ~$12, dark+light ~$23)
```

No sampling params sent to Opus 4.8; no writes under `.planning/scorecards/`. Both plan verification gates green.

## Deviations from Plan

**Execution note (not a scope deviation):** the executor completed all three tasks and committed each atomically (`9cea5e2f`, `85d1bde5`, `6534655a`), then stalled at the final SUMMARY.md write (stream watchdog killed it after 600s of no progress). The working tree was clean with all task commits present. The orchestrator closed the plan out by re-running the plan's own verification gates (`tsc --noEmit` clean, `run.ts score --dry-run` exit 0) and authoring this SUMMARY — no task work was re-executed, no duplicate commits created.

**No scope deviations.** Plan executed as designed.

## Known Stubs

`run.ts` lazy-imports `panel`/`refute` (Plan 06) and `report`/`label` (Plan 07) — these subcommands error only when invoked, by design, so this plan lands green with downstream modules wired but not yet present.

## Threat Surface Scan

Implements the mitigations from the plan's STRIDE register: evidence-required schema discards injected/uncited output (T-195-15); scorecard.ts write-isolation to `.planning/critic-scores/` (T-195-16); `ANTHROPIC_API_KEY` read from env via SDK only, never logged or persisted (T-195-18). The screenshot/DOM→API boundary (T-195-14) is the accepted, documented, maintainer-local dev-tooling boundary (opt-in via key, excluded from CI, synthetic stress fixtures only).

## Self-Check: PASSED

- `examples/threadline_phoenix/e2e/critic/schema.ts` — FOUND
- `examples/threadline_phoenix/e2e/critic/client.ts` — FOUND
- `examples/threadline_phoenix/e2e/critic/run.ts` — FOUND
- Commit `9cea5e2f` — FOUND
- Commit `85d1bde5` — FOUND
- Commit `6534655a` — FOUND
- `npx tsc --noEmit`: TSC_EXIT=0 — PASSED
- `node --import tsx critic/run.ts score --dry-run`: exit 0 — PASSED
