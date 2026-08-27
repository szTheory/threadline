---
phase: 195-validated-adversarial-critic-runner-panel
plan: "08"
subsystem: critic_trust
tags: [gap-closure, krippendorff-alpha, trust-measurement, ledger-splice, critic-cli, golden-scoping]
dependency_graph:
  requires: [195-04, 195-05, 195-06, 195-07]
  provides: [CRITIC-03, CRITIC-01]
  affects: [design-system-ledger.json, mix critic.measure, mix verify.ui_critique, critic score --golden]
tech_stack:
  added: ["mix critic.measure task", "pure Measure engine", "brace-matched LedgerSplice", "critic score --golden"]
  patterns: [reuse KrippendorffAlpha, IO/pure split, byte-stable idempotent JSON splice, npm -- passthrough]
key_files:
  created:
    - lib/threadline/critic_trust/measure.ex
    - lib/threadline/critic_trust/ledger_splice.ex
    - lib/mix/tasks/critic.measure.ex
    - test/threadline/critic_trust/measure_test.exs
    - test/threadline/critic_trust/ledger_splice_test.exs
  modified:
    - mix.exs
    - examples/threadline_phoenix/e2e/critic/run.ts
    - CONTRIBUTING.md
    - .planning/phases/195-validated-adversarial-critic-runner-panel/195-07-PLAN.md
    - .planning/phases/195-validated-adversarial-critic-runner-panel/195-VALIDATION.md
decisions:
  - "[195-08-A] Trust writer is an Elixir mix task (mix critic.measure), NOT a Node command
    and NOT a verify.* alias: it reuses the tested KrippendorffAlpha engine (no re-port), computes
    the guard's exact sha8 bytes, and — because it MUTATES the committed ledger — is named
    critic.measure, kept out of ci.all, and never git-commits (T-195-24)."
  - "[195-08-B] The ledger is edited via a brace-matched, string-literal-aware splice of ONLY the
    critic_trust object, rendered with fixed lens+field order and the file's exact 2-space nesting.
    Re-running with unchanged inputs is byte-identical (idempotent); an empty golden set reproduces
    the committed skeleton exactly (verified no-op). Never Jason.encode! the whole 14k-line doc."
  - "[195-08-C] α mapping: human broken/bad/borderline/good → 1..4; critic = min() band across a
    lens's stable dims → fail/weak/ok/strong/exemplary → 1/2/3/4/4. raw_agreement = exact-bucket
    match rate; pairwise_acc = null (label CLI does not persist pair margins yet — never gating)."
  - "[195-08-D] Promotion validated:true iff α≥0.67 ∧ n≥20 ∧ raw≥0.80 ∧ model_id==pin ∧ every
    contributing score used the current rubric version (auto-invalidation on rubric/model bump)."
  - "[195-08-E] Fixed the mix verify.ui_critique npm '--' passthrough bug and added critic
    score --golden (scope to labeled golden cells only, T-195-17 committed-cell guard); reconciled
    the runbook across three docs (refute battery = npm run critic:validate, not the mix alias)."
metrics:
  completed: "2026-07-04"
  tasks_completed: 3
  tasks_total: 3
  files_created: 5
  files_modified: 5
status: complete
---

# Phase 195 Plan 08 (gap closure): Trust-Measurement Writer + CLI Reconciliation

Closes the gap found while preparing the 195-07 human-verify checkpoint: the designed
"trust recompute" (labels + scores → measured per-lens `critic_trust` → `validated:true`)
had no implementing command, and three runbook commands did not match the shipped CLI.

## Tasks Completed

| # | Task | Commit |
|---|------|--------|
| 1 | Trust-measurement writer (`mix critic.measure` + `Measure` engine + `LedgerSplice`) + unit tests | `6161a4c1` |
| 2 | mix.exs `--` passthrough fix + `critic score --golden` | `9ddf802d` |
| 3 | Reconcile golden-oracle runbook across 3 docs | `517c8db5` |

## What Was Built

- **`Threadline.CriticTrust.Measure`** — pure engine: golden items + critic scores + rubric
  versions → per-lens `{alpha, raw_agreement, pairwise_acc, n, ci95, golden_rubric_version,
  model_id, validated}` (the guard's exact 8-field key set). Human verdict buckets and the
  critic's `min()` band are placed on a shared 1..4 ordinal scale and fed to the existing
  `KrippendorffAlpha.compute/1` + `bootstrap_ci/3`. `pairwise_acc` is `null` (label CLI does
  not persist pair margins yet).
- **`Threadline.CriticTrust.LedgerSplice`** — brace-matched, string-literal-aware, byte-stable
  replacement of only the `critic_trust` object in the ~14k-line ledger. Idempotent; empty golden
  set → byte-identical no-op (verified).
- **`mix critic.measure`** — thin IO shell: reads golden-set + critic-scores + rubric files,
  calls the engine, splices the ledger, prints a per-lens summary, never commits. Local-only,
  excluded from `ci.all`.
- **mix.exs** — inserted the npm `--` separator so `verify.ui_critique` forwards flags (`--dry-run`
  etc.) instead of npm swallowing them.
- **run.ts `--golden`** — scores exactly the labeled golden `(cell, lens)` pairs (cheap + correct
  for measurement) with a committed-cell path guard (T-195-17); dropped the dead `--changed` line.
- **Runbook** — CONTRIBUTING.md + 195-07-PLAN.md + 195-VALIDATION.md now source `.env` first, use
  `npm run critic:validate` for the refute battery, `critic:score -- --golden` for scoped scoring,
  and `mix critic.measure` for the trust write.

## Verification Results

```
mix compile --warnings-as-errors           clean
mix format --check-formatted               clean
mix test (measure + ledger_splice +
  critic_trust guard + refute_partition)   36 tests, 0 failures
cd e2e && npx tsc --noEmit                  clean
node run.ts score --golden --dry-run       exit 0 (0 cells on empty golden)
mix critic.measure (empty golden)          byte-identical no-op (idempotent)
doc-contract greps                         no stale command; 3 docs carry the real commands
mix ci.all                                 green through verify.critic_trust + verify.mechanical
```

`mix ci.all` stops at `verify.example` on the 8 pre-existing `demo_contract_test` failures — the
local Postgres `search_path` env issue (MEMORY.md), unrelated to this plan (no capture/example
code touched).

## Deviations from Plan

None. `pairwise_acc: null` is a documented, non-gating limitation (label CLI doesn't persist pair
margins) — flagged in the runbook, not a defect in this plan.

## Self-Check: PASSED

- `lib/threadline/critic_trust/measure.ex` — FOUND
- `lib/threadline/critic_trust/ledger_splice.ex` — FOUND
- `lib/mix/tasks/critic.measure.ex` — FOUND
- Commits `6161a4c1`, `9ddf802d`, `517c8db5` — FOUND
- 36 tests, 0 failures — PASSED
- `mix critic.measure` idempotent no-op — PASSED
