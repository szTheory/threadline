---
phase: 196-forward-only-net-positive-gate-first-proven-iteration
plan: 02
subsystem: testing
tags: [critic, forward-only-gate, elixir, exunit, ledger, guard-the-guards, gate-02, gate-04, gate-05, append-only]

# Dependency graph
requires:
  - phase: 196-forward-only-net-positive-gate-first-proven-iteration
    plan: 01
    provides: critic_panel ledger baseline (trust_floors/oracle_inventory), ratchet.signoffs [] append-only home, panel-membership freeze clause
  - phase: 195-critic-synthetic-oracle-ranking-gate
    provides: synthetic-set oracle (144 items), critic_trust validated flags
  - phase: 194-tier-a-mechanical-floor
    provides: committed page.* Tier-A scorecards + verify.mechanical floor
provides:
  - "GATE-04 no-silent-target-drop guard: trust_floors + ratchet.minimum_scores frozen against a committed baseline; a downward move (or id removal) fails unless a matching target_change/ratchet_bump signoff records the exact new value"
  - "GATE-04 no-fixture-removal guard: synthetic oracle item count + held_out_ids non-shrinking unless a fixture_removal signoff records it"
  - "GATE-04 append-only signoffs pin: every known-good ratchet.signoffs entry must remain present"
  - "GATE-02 empty structural whitelist: mechanical_auto_apply.structural_whitelist [] unless a structural_whitelist_add signoff exists"
  - "GATE-05 semantic-guard stamp: every screenshot_allowlist.ci entry gated behind a fresh clean semantic_guard_stamp over a committed page.* mechanical twin"
affects: [196-03, 196-04, 196-05, 196-06, 197]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Frozen module-constant baseline + append-only signoff cross-check as the deterministic GATE-04 guard-the-guards idiom (no browser/LLM/network)"
    - "semantic_guard_stamp.scorecard_ref points at the committed page.* mechanical twin (never the gitignored route.*/footgun cell) — the GATE-05 landmine avoidance from Plan 01's ROUTE_PAGE_TWIN pattern"
    - "scorecard_resolves? tolerates the __theme-viewport.json Tier-A capture naming via Path.wildcard fallback"

key-files:
  created: []
  modified:
    - test/threadline/operator_surface/critic_trust_test.exs
    - .planning/design-system-ledger.json

key-decisions:
  - "semantic_guard_stamp.scorecard_ref uses the page.* mechanical twin of each allowlist entry (page.home.happy / page.timeline.happy / page.transaction.happy), not the entry's own ledger_id — 2 of 3 ci entries (page.timeline.empty, footgun.transaction-page-left-push-desktop) have no committed page.* scorecard under their own id, and the acceptance node-check + GATE-05 landmine both require a committed page.* twin"
  - "Froze the full ratchet.minimum_scores map (120 ids) as @baseline_minimum_scores rather than a single scalar floor — minimum_scores holds heterogeneous floors (20/25/35/62/72), so only an exact per-id snapshot detects a silent single-id drop"
  - "no-silent-drop clause also fails on id REMOVAL (is_number assertion), not just downward moves — deleting a ratchet floor is the same tampering vector as lowering it"

# Metrics
duration: ~25min
completed: 2026-07-28

status: complete
---

# Phase 196 Plan 02: Guard-the-Guards — Silent Quality-Bar Tampering Blocked in CI Summary

**Four additive, pure-Elixir, vacuous-safe clauses in `critic_trust_test.exs` — backed by two append-only ledger blocks — that make a silent trust-floor/target drop, a synthetic-oracle fixture removal, an un-spiked structural auto-apply whitelist, and an un-stamped screenshot-baseline refresh each turn `verify.critic_trust` red, while the honest committed ledger stays green.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-28
- **Tasks:** 2
- **Files modified:** 2 (0 created, 2 modified)

## Accomplishments

- **GATE-04 no-silent-target-drop (196-D5):** froze `@baseline_trust_floors` (the 4 blocking-lens floors) and `@baseline_minimum_scores` (the full committed 120-id ratchet snapshot). Any current value below its baseline — or the removal of a guarded id — fails unless a matching `target_change`/`ratchet_bump` signoff records the exact new value. Silent quality-bar erosion is now impossible in CI.
- **GATE-04 no-fixture-removal (196-D4):** the synthetic true-north oracle can only shrink behind a recorded `fixture_removal` signoff — item count never drops below `oracle_inventory.synthetic_item_count` (144) and every recorded `held_out_id` stays present.
- **GATE-04 append-only enforcement:** pinned `@known_signoffs` ([]) so every previously-committed `ratchet.signoffs` entry must remain — sign-offs are never rewritten or dropped.
- **GATE-02 empty structural whitelist (196-D3):** seeded `mechanical_auto_apply.structural_whitelist: []` and a clause asserting it stays empty unless a `structural_whitelist_add` signoff exists — no un-spiked structural auto-apply ships this phase.
- **GATE-05 semantic-guard stamp (196-D6):** added a `semantic_guard_stamp` to each `screenshot_allowlist.ci` entry (pointing at its committed page.* mechanical twin) and a clause requiring every ci entry to carry a stamp resolving to a real committed scorecard with clean `mechanical_ok` + `blocking_panel_no_regress`. A pixel-baseline refresh can never become the quality bar on a raw pixel delta alone.
- All clauses are pure JSON reads + `File.exists?`/`Path.wildcard` — deterministic, CI-safe, no browser/LLM/network (196-D9). All are vacuous-safe on today's honest ledger.

## Task Commits

Each task was committed atomically:

1. **Task 1: GATE-04 append-only guards — no silent target/floor drop, no oracle removal** — `5eb3a3f9` (test)
2. **Task 2: GATE-02 empty structural whitelist + GATE-05 semantic-guard stamp** — `80c74c44` (feat)

## Files Created/Modified

- `test/threadline/operator_surface/critic_trust_test.exs` — added `@baseline_trust_floors`, `@baseline_minimum_scores`, `@known_signoffs`; four new clauses (no-silent-trust-floor-drop, no-silent-minimum_scores-drop, no-fixture-removal, append-only-signoffs-pin) for Task 1 and two (structural-whitelist-empty, semantic-guard-stamp) for Task 2; helpers `signoff_records_drop?/4`, `signoff_records_removal?/2`, `signoff_targets?/2`, `scorecard_resolves?/1`.
- `.planning/design-system-ledger.json` — additive/append-only: new top-level `mechanical_auto_apply.structural_whitelist: []`; `semantic_guard_stamp` added to each of the 3 `screenshot_allowlist.ci` entries (existing bytes untouched — the diff added only new keys plus the trailing comma on each entry's last prior field).

## Decisions Made

- **`semantic_guard_stamp.scorecard_ref` = the page.* mechanical twin, not the entry's own ledger_id.** Only `page.home.happy` has a committed page.* scorecard under its own id; `page.timeline.empty` and `footgun.transaction-page-left-push-desktop` do not (and the footgun id is not even `page.*`). Both the plan's acceptance node-check (`/^page\./` for every ci entry) and the GATE-05 landmine (tie to the committed page.* twin, never the gitignored route.*/footgun cell) require a page.* twin, so the twins are `page.home.happy` → `page.home.happy`, `page.timeline.empty` → `page.timeline.happy`, `footgun.transaction-page-left-push-desktop` → `page.transaction.happy`. All three are in `mechanical_floors` and already pass `verify.mechanical`, so each seed stamp is honest.
- **Froze the full 120-id `ratchet.minimum_scores` map** as `@baseline_minimum_scores` (heterogeneous floors 20/25/35/62/72) rather than a scalar — only an exact per-id snapshot detects a silent single-id drop.
- **Removal counts as a drop.** The no-silent-drop clauses assert `is_number(current)`, so deleting a floor id (not just lowering it) also trips the guard — deletion is the same tampering vector.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `scorecard_ref` must be the page.* mechanical twin, not the literal ledger_id**
- **Found during:** Task 2 (ledger seed + Clause D)
- **Issue:** The plan `<action>` says seed `scorecard_ref` with "the entry's `ledger_id`, which is a committed `page.*` id such as `page.home.happy`." That holds only for entry 1. Entry 2's ledger_id `page.timeline.empty` has no committed scorecard, and entry 3's `footgun.transaction-page-left-push-desktop` is not `page.*` and has no scorecard — so a literal-ledger_id stamp would (a) fail the plan's own acceptance node-check requiring every `scorecard_ref` to match `/^page\./`, and (b) fail Clause D's `File.exists?` resolution, red at seed time.
- **Fix:** Seeded each stamp's `scorecard_ref` with the committed page.* mechanical twin (the same ROUTE_PAGE_TWIN idea Plan 01 established): `page.timeline.empty` → `page.timeline.happy`, `footgun.transaction-page-left-push-desktop` → `page.transaction.happy`. This is exactly what the plan's GATE-05 landmine warning and its node-check demand.
- **Files modified:** `.planning/design-system-ledger.json`
- **Verification:** node acceptance check exits 0 (all ci `scorecard_ref` are `page.*`); `verify.critic_trust` green.
- **Committed in:** `80c74c44` (Task 2 commit)

**2. [Rule 3 - Blocking] `scorecard_resolves?` tolerates the `__theme-viewport.json` capture naming**
- **Found during:** Task 2 (Clause D)
- **Issue:** The plan's Clause D says the stamp "resolves to an existing committed scorecard under `@scorecards_dir` (File.exists?)". A bare `File.exists?("<ref>.json")` never resolves — committed Tier-A scorecards are named `<ref>__<theme>-<viewport>.json` (e.g. `page.home.happy__dark-1280.json`), not `<ref>.json`.
- **Fix:** `scorecard_resolves?/1` accepts either the exact `<ref>.json` or any `<ref>__*.json` via `Path.wildcard` — matching the real committed capture naming while keeping the check pure/deterministic.
- **Files modified:** `test/threadline/operator_surface/critic_trust_test.exs`
- **Committed in:** `80c74c44` (Task 2 commit)

**Total deviations:** 2 auto-fixed (both blocking). Both are the minimal changes required to satisfy the plan's own acceptance criteria (page.* node-check) and the real committed-scorecard naming. No scope creep; ledger edits stay additive/append-only.

## Verification Evidence

Scratch tamper demonstrations (each reverted before/after commit via `git checkout`), confirming every clause turns the guard red on tampering and green on the honest ledger:

| Tamper | Clause exercised | Result |
|--------|------------------|--------|
| `critic_panel.trust_floors.brand_fidelity` 0.85 → 0.60, no signoff | no-silent-trust-floor-drop (GATE-04, 196-D5) | FAIL (red) |
| `synthetic-set.json` items 144 → 100, no signoff | no-fixture-removal (GATE-04, 196-D4) | FAIL (red) |
| `structural_whitelist` → `["snap-to-token"]`, no signoff | structural-whitelist-empty (GATE-02, 196-D3) | FAIL (red) |
| `semantic_guard_stamp.scorecard_ref` → non-existent cell | semantic-guard-stamp (GATE-05, 196-D6) | FAIL (red) |
| remove a `semantic_guard_stamp` entirely | semantic-guard-stamp (GATE-05, 196-D6) | FAIL (red) |
| honest ledger, signoffs [] | all four clauses | PASS (green) — vacuous-safe |

Gate results on the committed tree:
- `mix verify.critic_trust` — **22 tests, 0 failures**
- `mix verify.mechanical` — **18 tests, 0 failures**
- `mix verify.format` — clean
- `mix verify.credo` — no issues (2690 mods/funs)
- `grep -Eq "System.cmd|:httpc|HTTPoison"` on the test file — no network/shell calls introduced

## Known Stubs

None. Both clauses are real deterministic guards backed by committed ledger data; no placeholders, no data-wiring gaps. The clauses are vacuous-safe (not stubbed) — they pass on the honest baseline and fire on tampering, which is the intended design.

## Issues Encountered

The full `mix test` suite shows **11 pre-existing failures**, all in files this plan never touched and all confirmed present on the pre-196-02 tree (`HEAD~2`) — this plan introduced **zero** new failures (verified: `stress_ledger_test.exs` + `critic_trust/` = 8 failures both before and after my additive ledger edit). Breakdown: 6 `StressLedgerTest` (Phase-195 `refute.*.graded.*` fixture-registry gap — the ledger is missing graded-twin stories `StressFixtures.all()` references), 1 `LedgerSpliceTest`, 1 `FormlessPagesTest` (`policy_redaction_live.ex`), 1 `Phase06NyquistCIContractTest` (`ci.yml` job-key parity), 1 `V123CharterDocContractTest` (`PROJECT.md` framing). Logged to `deferred-items.md`; out of scope per the executor scope boundary (unrelated pre-existing failures are recorded, not fixed).

The local test-DB search_path env issue (~81 undefined-audit-table failures) did **not** appear — the orchestrator's search_path fix held.

## Next Phase Readiness

- **Plan 03** (blast-radius fan-out + real recapture diff + GATE-03 divergence halt) reads the `trust_floors` this plan now guards against silent drop — the guard-the-guards floor is in place.
- **Wave 4** baseline data (populated golden items, real signoffs, held_out_ids) will exercise these clauses non-vacuously; the append-only signoff schema (`kind`/`after`/target-id fields) and `@known_signoffs` pin are ready for the first real signed entry.
- No blockers.

## Self-Check: PASSED

- `test/threadline/operator_surface/critic_trust_test.exs` — FOUND (modified)
- `.planning/design-system-ledger.json` — FOUND (modified, additive)
- `.planning/phases/196-.../deferred-items.md` — FOUND
- Commit `5eb3a3f9` (Task 1) — FOUND
- Commit `80c74c44` (Task 2) — FOUND

---
*Phase: 196-forward-only-net-positive-gate-first-proven-iteration*
*Completed: 2026-07-28*
