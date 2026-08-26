---
phase: 196-forward-only-net-positive-gate-first-proven-iteration
plan: 06
subsystem: ui
tags: [operator-surface, liveview, retention, evidence, density, forward-only-gate, ratchet-signoff]

requires:
  - phase: 196-forward-only-net-positive-gate-first-proven-iteration (plan 05)
    provides: first candidate edit (evidence density) + before-score snapshot
provides:
  - PROOF-01 completed — one real, human-ratified, gate-ACCEPTED improvement (route.retention, density, delta +7 > noise 4.5)
  - First real `ratchet.signoffs` entry (forward_only_accept) + its append-only pin in critic_trust_test
  - Gate tooling fixes discovered by running the loop for real (ROUTE_PAGE_TWIN map, route-lane maskColor, refute pole re-emit recovery)
affects: [operator-surface, design-system-ledger, phase 197 debt register]

actuals:
  tokens: multi-session
  tasks: 2
  commits: 5

tech-stack:
  added: []
  patterns: ["Forward-only accept records an append-only forward_only_accept signoff mirrored into @known_signoffs (GATE-04 pin)"]

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - lib/threadline/operator_surface/live/evidence_live.ex
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - test/threadline/operator_surface/critic_trust_test.exs
    - .planning/design-system-ledger.json
    - examples/threadline_phoenix/e2e/critic/gate.ts
    - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts

key-decisions:
  - "The evidence+density candidate (196-05, commits f6c40b6c/2eca4208) was honestly REJECTED by the gate across three variants (delta within noise; v3 targeted-lens verdict unstable = VOID per 196-D1). Maintainer ratified the REJECT and pivoted PROOF-01 to route.retention+density; evidence edits kept as ordinary UNRATIFIED UI cleanup (tests+floor green, no signoff claim)."
  - "route.retention accepted iteration (c6f9355e): removed the success/warning status banner that duplicated the stat cards' status/failure count, and the 'Retention window destructive action' self-label beside an icon-marked danger button — the type-to-confirm prune modal owns the destructive warning at point of action. Gate ACCEPT: density delta +7 > noise 4.5, no blocking regression, page.retention.happy floor green, held-out oracle rho holds."
  - "First ratchet.signoffs entry is kind=forward_only_accept with before-panel snapshot (brand 80 / density 32 / typography 67 / rhythm 68) and gate evidence; pinned append-only in @known_signoffs (f1610d87)."
  - "Gate defect fixed mid-loop (83db3918): ROUTE_PAGE_TWIN still held only the 196-01 tracer entry, so every non-timeline route fail-closed at the mechanical-floor step; all five CONTRIBUTING route↔twin rows are now registered. Route-lane maskColor switched from Playwright's default #FF00FF to the dark surface token (mask-contamination class from 195)."
  - "Tier-A recapture is NOT reproducible in this environment (systematic drift: identical scroll_cost shifts across unrelated cells; fullPage stress-lab shots ~36k px tall clobbered the clipped refute pole PNGs — recovered via capture:refute). The drifted scorecards were reverted; floors gate committed cells. Deferred to 197 debt register alongside the verdict-cache screenshot-hash defect."

patterns-established:
  - "Ratify only from clean before/after: bust the verdict cache before every re-score; before pole = critic-scores written BEFORE the edit (a post-edit score run silently overwrites it)"
  - "An honest REJECT is a valid loop outcome: three rejected evidence variants + one accepted retention iteration prove the gate discriminates rather than rubber-stamps"

requirements-completed: [PROOF-01]

coverage:
  - id: D1
    description: "Maintainer re-ran the gate and ratified accept/reject (REJECT for evidence, ACCEPT for retention pivot) with genuine before/after scores"
  - id: D2
    description: "Evidence trail committed: source diffs + signoff; route.* scorecards and CRITIQUE.md stay uncommitted by design"
  - id: D3
    description: "Append-only ratchet.signoffs entry recorded because a bar moved (density +7); guards re-asserted (critic_trust 22/0, mechanical 18/0)"
---

# 196-06 — PROOF-01 ratification: first gate-ACCEPTED improvement

## What happened

1. **Evidence candidate rejected honestly.** The 196-05 edit (and two strengthened
   variants) never moved density beyond the IQR noise floor (Δ −1/−2, v3 verdict
   unstable = VOID). The maintainer ratified the REJECT; the edits stay as ordinary
   unratified cleanup (2eca4208) — all deterministic gates green, no signoff claim.
2. **Pivot ratified → route.retention + density (before 32).** The critic's verified
   defect was pure content duplication. Removing the duplicated status banner and the
   destructive self-label (c6f9355e) produced **ACCEPT: Δ +7 > noise 4.5**, zero
   blocking regressions, floor green, oracle stable.
3. **Signoff + pin.** First `ratchet.signoffs` entry (forward_only_accept) appended to
   the ledger and pinned append-only in `critic_trust_test.exs` (f1610d87).
4. **Loop hardening en route** (83db3918): five route↔twin rows in `ROUTE_PAGE_TWIN`,
   dark maskColor for route captures.

## Verification

- `verify.critic_trust` 22/0, `verify.mechanical` 18/0, retention LiveView tests 21/0,
  evidence LiveView tests 13/0, compile --warnings-as-errors, format, credo green.
- `mix ci.all`: green except the pre-existing 3-module doc-contract baseline
  (V123Charter/FormlessPages/Phase06Nyquist — out of scope, tracked since 195-10).

## Deferred to Phase 197 (debt register)

- Critic verdict cache not keyed on screenshot hash (stale-verdict hazard; manual rm workaround).
- `critic:score` after an edit overwrites the gate's before pole in `.planning/critic-scores/`.
- Tier-A recapture drift (scroll_cost jumps, ~36k px fullPage stress-lab shots vs clipped refute poles).
- Evidence page structural density (six one-row sections paying full section scaffolding) — needs an IA pass, not chrome removal.
