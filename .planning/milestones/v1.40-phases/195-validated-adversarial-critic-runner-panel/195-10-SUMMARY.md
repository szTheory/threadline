---
phase: 195-validated-adversarial-critic-runner-panel
plan: 10
subsystem: testing
tags: [exunit, design-system-ledger, refute-twins, synthetic-oracle, ci, traceability]

requires:
  - phase: 195-validated-adversarial-critic-runner-panel
    provides: "Ratified D-12 ledger shape (099afbaa refute-twin entries; aef9e655 critic_trust_provenance + graded ladder + generalized LedgerSplice)"
provides:
  - "StressLedgerTest reconciled with the ratified ledger: 18 tests green (was 16 with 7 failures) — contracts extended, never weakened"
  - "Explicit refute sub-contract: null current/legacy score (D-04 null-never-0), ratchet_score 0, ratchet-leak exclusions (locked_ids/minimum_scores/signoffs)"
  - "Positive graded-story registry guard against .planning/golden/synthetic-set.json (144 stories ↔ 144 cell_id prefixes, verified 1:1)"
  - "LedgerSpliceTest green on the generalized :object_key_not_found atom (+ replace_provenance sibling assertion)"
  - "REQUIREMENTS.md traceability current for all 10 Phase-195 IDs (CRITIC-01/05, RUNNER-01/02 flipped Complete)"
  - "verify.format lane restored (pre-existing unformatted stress_live.ex from paused 196 work)"
affects: [196-forward-only-gate, ci, design-system-ledger, requirements-traceability]

actuals:
  tokens: 6100
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Extend-never-weaken guard reconciliation: new ledger shapes are contracted IN with positive sub-contracts, not exempted out"
    - "Registry hand-off: dev/test-only oracle fixtures register in synthetic-set.json, product fixtures in the ledger — each side has a positive guard"

key-files:
  created: []
  modified:
    - test/threadline/operator_surface/stress_ledger_test.exs
    - test/threadline/critic_trust/ledger_splice_test.exs
    - .planning/REQUIREMENTS.md
    - lib/threadline/operator_surface/live/stress_live.ex

key-decisions:
  - "Refute-kind null scores got a dedicated POSITIVE sub-contract test (D-04 null-never-0 + ratchet-leak exclusions) instead of a silent exemption"
  - "Graded-ladder stories moved to a synthetic-set.json registry guard (1:1 with 144 oracle cell_ids); binary twins stay ledger-registered"
  - "Latent nil-ordering bug fixed: evidence_ref score-increase filter now requires is_integer(current_score) (nil > 0 is true under Elixir term ordering)"
  - "Pre-existing verify.format red (stress_live.ex, paused 196 commits) auto-fixed as a whitespace-only style commit — Rule 3, blocks the plan's ci.all-green truth"

patterns-established:
  - "Guard reconciliation via extension: exact-match assertions survive; new keys/kinds are added to the contracted vocabulary with their own invariants"

requirements-completed: []

coverage:
  - id: D1
    description: "StressLedgerTest extended to the ratified D-12/196 ledger shape (top-level keys, refute kind, refute sub-contract, graded synthetic-set guard, nil-safe evidence_ref)"
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface/stress_ledger_test.exs (18 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "LedgerSpliceTest reconciled with the generalized :object_key_not_found atom, replace_provenance strengthened"
    verification:
      - kind: unit
        ref: "mix test test/threadline/critic_trust/ledger_splice_test.exs (5 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "REQUIREMENTS.md traceability flipped for CRITIC-01/05, RUNNER-01/02 (8 scoped lines; GATE-*/PROOF-* untouched)"
    verification:
      - kind: other
        ref: "grep acceptance checks in Task 3 (checkbox + table-row counts == 1 each; GATE-01 still Pending)"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-08-26
status: complete
---

# Phase 195 Plan 10: Suite-Green Reconciliation Summary

**Extended (never weakened) the two frozen deterministic guards to the ratified D-12 ledger shape — 8 target failures → 0, ledger byte-untouched, traceability current for all 10 Phase-195 IDs**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-08-26T15:34:39Z
- **Completed:** 2026-08-26T15:42:30Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- `mix test stress_ledger_test.exs ledger_splice_test.exs` → 23 tests, 0 failures (was 21 tests, 8 failures at 0e07f6d8)
- Contracts extended deliberately: exact-match `@top_level_keys` gains `critic_panel`/`critic_trust_provenance`/`mechanical_auto_apply`; `refute` joins `@allowed_kinds` with an explicit sub-contract (null current/legacy score per D-04, ratchet_score 0, integer target, status current, owner_phase 195, and no leakage into `ratchet.locked_ids`/`minimum_scores`/`signoffs`)
- Fixed a latent nil-ordering bug: the evidence_ref score-increase comprehension now requires `is_integer(current_score)` (Elixir term ordering makes `nil > 0` true — null refute scores masqueraded as score increases)
- Graded-ladder stories (144) get a positive registry guard against `.planning/golden/synthetic-set.json` cell_id prefixes (`{story_id}__`), verified 1:1 before authoring; the 14 binary refute twins stay ledger-registered with unchanged round-trip assertions
- LedgerSpliceTest expects the generalized `{:error, :object_key_not_found}` and additionally asserts `replace_provenance/2` returns the same atom on an absent block
- REQUIREMENTS.md: CRITIC-01, CRITIC-05, RUNNER-01, RUNNER-02 flipped to `[x]`/Complete (verifier-backed); GATE-*/PROOF-* rows untouched
- `.planning/design-system-ledger.json` and `DESIGN-SYSTEM.md` byte-unchanged (git diff empty) — only the guards moved
- Full suite: 1380 tests, 3 failures — all in the pre-existing baseline modules (V123CharterDocContractTest, FormlessPagesTest, Phase06NyquistCIContractTest); zero StressLedgerTest/LedgerSpliceTest failures. `mix verify.format` and `mix verify.credo` both green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend stress_ledger_test contracts to the ratified D-12/196 ledger shape** - `998915d8` (test)
2. **Task 2: Reconcile ledger_splice_test with the generalized error atom** - `a21a2869` (test)
3. **Deviation fix: format pre-existing unformatted stress_live.ex** - `c117a8a3` (style)
4. **Task 3: Flip verifier-confirmed traceability rows** - `4da4b4e9` (docs)

## Files Created/Modified

- `test/threadline/operator_surface/stress_ledger_test.exs` - 18 tests; extended top-level-key/kind vocabularies, refute sub-contract, graded synthetic-set guard, nil-safe evidence_ref filter, kind guards on 4 score-shape tests
- `test/threadline/critic_trust/ledger_splice_test.exs` - absent-block test expects `:object_key_not_found`; sibling `replace_provenance/2` assertion added
- `.planning/REQUIREMENTS.md` - 8 scoped lines: CRITIC-01/05 + RUNNER-01/02 checkboxes and traceability rows → Complete
- `lib/threadline/operator_surface/live/stress_live.ex` - whitespace-only `mix format` pass (deviation; no logic change)

## Decisions Made

- Refute entries are contracted IN with a positive sub-contract test rather than blanket-exempted — the null-score allowance is asserted (D-04 null-never-0) and explicitly barred from every ratchet surface
- Graded stories' registry is the synthetic oracle set, not the ledger (D-12); both sides now carry a guard so neither registry can silently drop fixtures

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Formatted pre-existing unformatted `stress_live.ex`**
- **Found during:** Task 3 (verify.format acceptance criterion)
- **Issue:** `lib/threadline/operator_surface/live/stress_live.ex` was committed unformatted during the paused Phase 196 work (84195c9e lineage), turning the `verify.format` lane of `ci.all` red — directly blocking this plan's "ci.all stays green" truth and Task 3's `mix verify.format exits 0` criterion
- **Fix:** `mix format` on that single file; whitespace-only, no logic change
- **Files modified:** lib/threadline/operator_surface/live/stress_live.ex
- **Verification:** `mix verify.format` exits 0; full suite unchanged apart from the documented baseline
- **Committed in:** c117a8a3 (separate style commit)

---

**Total deviations:** 1 auto-fixed (Rule 3 blocking)
**Impact on plan:** Necessary to restore the ci.all-green truth the plan exists to close. No scope creep.

## Issues Encountered

- The local full-suite baseline is now 3 failures (doc-contract modules only), not the ~11 documented — the search_path DB fix from the memory note has evidently been applied locally. The 3 remaining are exactly the pre-existing modules named in the plan's baseline list; out of scope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The failed 195-VERIFICATION truth "`mix ci.all` stays green" is restored: verify.test carries only the pre-existing doc-contract baseline; verify.format/credo green; both deterministic guards green
- Phase 196 remains paused at the PROOF-01 checkpoint (196-05 Task-1 human-action) — untouched by this plan, resume path unchanged

## Self-Check: PASSED

- test/threadline/operator_surface/stress_ledger_test.exs: FOUND
- test/threadline/critic_trust/ledger_splice_test.exs: FOUND
- Commits 998915d8, a21a2869, c117a8a3, 4da4b4e9: FOUND in git log
- git diff .planning/design-system-ledger.json DESIGN-SYSTEM.md: empty

---
*Phase: 195-validated-adversarial-critic-runner-panel*
*Completed: 2026-08-26*
