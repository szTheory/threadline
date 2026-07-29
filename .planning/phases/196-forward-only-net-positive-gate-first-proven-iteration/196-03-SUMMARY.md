---
phase: 196-forward-only-net-positive-gate-first-proven-iteration
plan: 03
subsystem: testing
tags: [critic, forward-only-gate, tsx, gate-01, gate-02, gate-03, blast-radius, goodhart, advisory-lens]

# Dependency graph
requires:
  - phase: 196-forward-only-net-positive-gate-first-proven-iteration
    plan: 01
    provides: "gate.ts tracer skeleton (blastRadius/mechanicalFloor/rankReeval/verdict), ROUTE_PAGE_TWIN, exported scoreCellLens+LENS_DIMENSIONS, critic_panel ledger baseline (trust_floors)"
  - phase: 195-critic-synthetic-oracle-ranking-gate
    provides: "scoreCellLens/runNSamples primitives (N=3→7 escalation + IQR noise floor), synthetic-set held-out oracle, mix critic.measure --source synthetic"
  - phase: 194-tier-a-mechanical-floor
    provides: "MechanicalChecker + verify.mechanical deterministic MODE-A/B floor over committed page.* scorecards"
provides:
  - "gate.ts full GATE-01 ranking pipeline: blast-radius-aware multi-cell re-eval over the 4 blocking lenses, targeted-up + no-regress accept rule, N-escalation, Δ-vs-IQR only (no absolute threshold)"
  - "gate.ts advisory reporting: hierarchy/color_contrast scored + printed under a 'verify vs ground truth' badge, never fed to the verdict"
  - "gate.ts GATE-03 divergence halt: reads critic_panel.trust_floors + critic_trust[lens].spearman from the committed ledger, HALTs before accept if any blocking lens ρ < floor; live path recomputes via mix critic.measure --source synthetic, dry-run reads the recorded ρ"
  - "gate.ts GATE-02 MODE-A fix-surfacing: MechanicalChecker fixes over the committed page.* twin printed as a suggested diff (surface-a-diff); no source write, no structural auto-apply"
affects: [196-04, 196-05, 196-06, 197]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Blast radius via deterministic re-capture byte-diff over route.*__dark-* cells; unchanged cells drop out (reverts scroll_cost jitter, R2)"
    - "Ranking re-eval fans out over affectedCells × 4 blocking lenses, composing scoreCellLens/runNSamples; before pole read from committed critic-scores snapshot"
    - "Goodhart divergence halt reads recorded ρ vs ledger trust_floors under dry-run ($0), recomputes only on the keyed live path"
    - "Surface-a-diff: MODE-A fixes emitted via a sentinel-prefixed thin `mix run` Elixir reporter, parsed and printed — never written to source"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/critic/gate.ts
    - examples/threadline_phoenix/e2e/critic/run.ts

key-decisions:
  - "Renamed BLOCKING_PANEL → BLOCKING_LENSES and added ADVISORY_LENSES to mirror the plan's naming and 196-D2; advisory lenses are print-only inputs to nothing"
  - "Before pole for the ranking Δ is read from the committed critic-scores snapshot (.planning/critic-scores/<cell>/<lens>/*.json) written by a pre-edit `critic:score` run — the RESEARCH-sanctioned 'reuse scoreCellLens OR the committed critic-scores' composition; the after pole is scoreCellLens on the recaptured cell"
  - "Divergence halt reads the RECORDED ρ under --dry-run and only shells `mix critic.measure --source synthetic` on the keyed live path (guarded by the dry-run early return) — CI never runs the LLM, 196-D9"
  - "MODE-A fixes surfaced via a sentinel-prefixed (`FIX::`) `mix run --no-start -e` reporter so compile noise never contaminates parsed output; no writeFileSync anywhere in gate.ts"

patterns-established:
  - "The 7-step gate pipeline (blast radius → mechanical floor → 4-lens ranking → divergence halt → advisory → surfaced fixes → verdict) with a fully-wired deterministic --dry-run path at $0"

requirements-completed: [GATE-01, GATE-02, GATE-03]

coverage:
  - id: D1
    description: "Full 4-lens blast-radius ranking gate + advisory reporting: dry-run prints the affected-cell set, the 4 blocking lenses re-evaluated, and the advisory lenses reported separately; exits 0 with no key"
    requirement: GATE-01
    verification:
      - kind: e2e
        ref: "cd examples/threadline_phoenix/e2e && npm run critic:gate -- --page route.timeline --lens density --dry-run"
        status: pass
      - kind: static
        ref: "gate.ts defines brand_fidelity/density/typography/rhythm blocking + hierarchy/color_contrast advisory; re-eval composes scoreCellLens/runNSamples; verdict path has no absolute-score threshold; advisory not an input to verdict()"
        status: pass
    human_judgment: false
  - id: D2
    description: "GATE-03 held-out divergence halt + GATE-02 MODE-A fix-surfacing: dry-run prints per-blocking-lens recorded ρ vs trust_floors with HALT/OK and the surface-a-diff plan; no key, no billing"
    requirement: GATE-03
    verification:
      - kind: e2e
        ref: "cd examples/threadline_phoenix/e2e && npm run critic:gate -- --page route.timeline --lens brand_fidelity --dry-run"
        status: pass
      - kind: static
        ref: "gate.ts reads critic_panel.trust_floors from the ledger; `mix critic.measure --source synthetic` guarded by the dry-run early return; no writeFileSync/fs.write in gate.ts; no synthetic-set.json reference"
        status: pass
    human_judgment: false
  - id: D3
    description: "GATE-02 surface-a-diff scope: MODE-A fixes surfaced for the human to apply, no source rewriter and no structural auto-apply"
    requirement: GATE-02
    verification:
      - kind: static
        ref: "surfaceMechanicalFixes prints MODE-A fix hints via a read-only mix reporter; grep -Eq 'writeFileSync|fs.write' gate.ts finds nothing"
        status: pass
    human_judgment: false

# Metrics
duration: ~35min
completed: 2026-07-28
status: complete
---

# Phase 196 Plan 03: Full 4-Lens Blast-Radius Ranking Gate + Divergence Halt + Fix-Surfacing Summary

**`gate.ts` now runs the complete forward-only decision engine — a blast-radius-aware re-eval of every affected route cell on the 4 blocking lenses (targeted-up + no-regress, Δ-vs-IQR only), an advisory report that never gates, a GATE-03 Goodhart divergence halt against the held-out oracle floors, and GATE-02 MODE-A fix-surfacing as a human-applied diff — all with a fully-wired $0 `--dry-run` path.**

## Performance
- **Duration:** ~35 min
- **Tasks:** 2 (both `type="auto"`)
- **Files modified:** 2 (`gate.ts`, `run.ts`)

## Accomplishments
- Expanded the tracer's one-lens/one-cell skeleton into the full GATE-01 ranking gate: `blastRadius` fans over `route.*__dark-*` cells via a deterministic recapture byte-diff (unchanged cells drop out, reverting scroll_cost jitter — R2/Pitfall 2); `rankReeval` fans out over affected cells × the 4 blocking lenses, composing `scoreCellLens`/`runNSamples` (N=3→7), accepting only on targeted-up on the edited cell AND no blocking regression on any affected cell.
- Kept the accept/reject decision strictly relative: it compares Δ against the per-cell IQR noise floor and never an absolute-score threshold (Anti-Pattern / 196-D1).
- Added `advisoryReport` for hierarchy + color_contrast under an "ADVISORY — verify vs ground truth" badge; the advisory result is print-only and is not an input to `verdict()` (196-D2 / Pitfall 3).
- Wired the GATE-03 divergence halt: it reads `critic_panel.trust_floors` and `critic_trust[lens].spearman` from the committed ledger and HALTs (non-zero, before any accept) if any blocking lens ρ falls below its floor (196-D4 Goodhart guard). Under `--dry-run` it reads the recorded ρ ($0, no key); only the keyed live path shells `mix critic.measure --source synthetic` to recompute.
- Wired the GATE-02 MODE-A fix-surfacing: `surfaceMechanicalFixes` runs `MechanicalChecker` over the committed `page.*` twin and prints the located fix strings (snap-to-token / raise-contrast / replace-shadow) as a suggested diff for the human to apply. It writes no source files and performs no structural auto-apply — the whitelist stays empty (196-D3).
- Documented the `--n` / `--dry-run` / advisory behavior in `run.ts`'s `gate` usage help.

## Task Commits
1. **Task 1: Full 4-lens blast-radius ranking gate + advisory reporting** — `d0bb2fff` (feat)
2. **Task 2: GATE-03 held-out divergence halt + GATE-02 MODE-A fix-surfacing** — `d1110a53` (feat)

## Files Modified
- `examples/threadline_phoenix/e2e/critic/gate.ts` — expanded from the tracer skeleton to the full 7-step pipeline: `BLOCKING_LENSES`/`ADVISORY_LENSES`, multi-cell blast-radius diff, multi-cell/multi-lens `rankReeval` with a committed-critic-scores before pole, `divergenceHalt` (dry-run reads recorded ρ, live recomputes), `advisoryReport`, `surfaceMechanicalFixes` (read-only mix reporter), and a `HALT` verdict.
- `examples/threadline_phoenix/e2e/critic/run.ts` — `gate` usage help now documents `--n`, `--dry-run`, and the advisory output.

## Decisions Made
- **Before pole = committed critic-scores snapshot.** The ranking Δ needs a pre-edit "before" and a post-edit "after" of the same cell. Since only one on-disk copy of a `route.*` cell exists at a time and `loadBundle`/`validateCellId` reject non-committed cells, the before pole is read from `.planning/critic-scores/<cell>/<lens>/*.json` (written by a maintainer `critic:score --page <page>` run BEFORE editing), and the after pole is `scoreCellLens` on the recaptured cell. This is the RESEARCH-sanctioned "reuse scoreCellLens OR the committed critic-scores" composition. If no before-snapshot exists, the gate VOIDs with guidance rather than guessing.
- **Divergence halt reads recorded ρ under dry-run, recomputes only live.** The `mix critic.measure --source synthetic` shell sits after the dry-run early return inside `divergenceHalt`, so CI/dry-run never invoke the recompute (196-D9). The floors are read from the committed ledger, never hardcoded.
- **Surface-a-diff via a sentinel reporter.** MODE-A fixes are emitted by a thin `mix run --no-start -e` Elixir snippet that prints `FIX::<selector> :: <fix>` lines; the gate greps those, so compile noise cannot contaminate the output. No `writeFileSync` exists anywhere in `gate.ts`.

## Deviations from Plan
None — plan executed as written. Task 1 renamed the tracer's `BLOCKING_PANEL` constant to `BLOCKING_LENSES` to match the plan's `<action>` wording and added `ADVISORY_LENSES`; this is the plan's own instruction, not a deviation.

## Known Stubs
The keyed (live, `ANTHROPIC_API_KEY`-present) path is implemented and composes the existing primitives, but it is not exercised in this environment (it requires a maintainer API key + a running seeded example app + a browser recapture, and is local-only by design per 196-D9). The verified surface is the deterministic `--dry-run` path (both acceptance invocations) plus the static structure checks. This is the intended posture: the gate's LLM/live path is maintainer-local and never runs in CI; the live path is composed from already-validated primitives (`scoreCellLens`/`runNSamples`, `MechanicalChecker`, `mix critic.measure`). Not a data-wiring gap in the plan's goal (the GATE-01/02/03 decision engine and its $0 dry-run are complete). The first real keyed run lands in 196-05 (first proven iteration).

## Verification
- `npm run critic:gate -- --page route.timeline --lens density --dry-run` → exit 0; prints blast-radius in-scope set, the 4 blocking lenses re-evaluated, and the advisory lenses reported separately.
- `npm run critic:gate -- --page route.timeline --lens brand_fidelity --dry-run` → exit 0; prints the per-blocking-lens divergence comparison (recorded ρ vs `trust_floors`) with HALT/OK and the surface-a-diff plan.
- `npx tsc --noEmit` → exit 0.
- Static: blocking/advisory membership present; `scoreCellLens`/`runNSamples` composed; `trust_floors` read from the ledger; `mix critic.measure` guarded by the dry-run early return; no `writeFileSync`/`fs.write`; no `synthetic-set.json` reference (oracle never optimized).
- `mix verify.critic_trust` → 22 tests, 0 failures (confirms the `critic_panel`/`critic_trust` ledger blocks the gate reads are guard-valid).
- `mix ci.all` is unaffected: `gate.ts`/`run.ts` are TypeScript, outside every `mix` alias (196-D9), so no CI surface changed. (The repo has ~11 pre-existing, unrelated Elixir test failures noted by the orchestrator in files this plan did not touch.)

## Self-Check: PASSED
- `examples/threadline_phoenix/e2e/critic/gate.ts` — FOUND
- `examples/threadline_phoenix/e2e/critic/run.ts` — FOUND
- Commit `d0bb2fff` (Task 1) — FOUND
- Commit `d1110a53` (Task 2) — FOUND

---
*Phase: 196-forward-only-net-positive-gate-first-proven-iteration*
*Completed: 2026-07-28*
