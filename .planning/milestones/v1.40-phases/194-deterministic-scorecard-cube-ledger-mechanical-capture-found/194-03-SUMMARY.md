---
phase: 194-deterministic-scorecard-cube-ledger-mechanical-capture-found
plan: 03
subsystem: testing
tags: [mechanical-checker, wcag, design-system, elixir, exunit, mix-alias, ci-gate, deterministic]

# Dependency graph
requires:
  - phase: 194-01
    provides: "design-system-ledger v2 cube (mechanical_floors {} scaffold) + stress_ledger_test guard"
  - phase: 194-02
    provides: "Tier A capture lane emitting committed RAW-inputs scorecard JSON (color_pairs / element_styles / applied_colors / mode_b) — schema is the checker's input contract"
provides:
  - "Threadline.OperatorSurface.MechanicalChecker — pure-Elixir run/1 + relative_luminance/1 + contrast_ratio/2 computing all 9 mechanical metrics from committed scorecard JSON with no browser/network/LLM (MECH-01, MECH-02)"
  - "MODE-A absolute blockers: WCAG contrast (dark+light, 2.4-gamma piecewise, translucent compositing) + radius/shadow/motion/font-size/spacing token conformance, each emitting a located fix-carrying violation map"
  - "MODE-B ratchet-floor metrics: type-size/interactive-control/card-nesting/scroll-cost/distinct-accent-hue with betterer-style floors + >3 far ceilings (grandfatherable via recorded floor)"
  - "mix verify.mechanical alias (preferred_env :test) folded into ci.all before verify.example_browser — a violation blocks a change with no LLM in the loop (MECH-03)"
  - "mechanical_checker_test.exs — meta-test pinning every LOCKED constant + WCAG unit + MODE-A/B fixture teeth (PASS + injected-violation RED paths)"
affects: [phase-195-cell-rating, phase-196-auto-apply, phase-197-structural]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Capture/assert separation completed: browser emits RAW computed-style inputs (Plan 02); Elixir single-sources every verdict (WCAG 2.4-gamma luminance, hue bucketing, token conformance) at ci.all time with no browser"
    - "MODE-A LOCKED constants as module attributes pinned verbatim by a String.contains? meta-test (brandbook_token_parity idiom) — loosening a constant fails CI"
    - "Betterer-style MODE-B ratchet: absent floor = pass; recorded floor grandfathers a pre-existing >ceiling value; only worsening past the recorded floor fails"
    - "Fixture-driven test teeth: synthetic scorecard JSON written to per-test tmp dirs proves both PASS and RED paths with zero dependency on real captured evidence existing"

key-files:
  created:
    - "lib/threadline/operator_surface/mechanical_checker.ex — the deterministic mechanical gate"
    - "test/threadline/operator_surface/mechanical_checker_test.exs — meta-test + WCAG unit + MODE-A/B teeth (17 tests)"
  modified:
    - "mix.exs — verify.mechanical alias + preferred_env :test + ci.all insertion before verify.example_browser"

key-decisions:
  - "The plan's thread-blue mid-tone example is factually wrong (thread-blue on dark bg is 5.885:1 — it PASSES AA). Used a muted steel mid-tone (110,118,134 -> ~4.15:1) to genuinely prove the dual 4.5/3.0 threshold band; kept a thread-blue sanity assertion (Rule 1)"
  - "mechanical_floors left {} — betterer seeding requires a first committed capture, and .planning/scorecards/ is empty locally (Plan 02 capture is CI-run). Absent floor = pass; the ledger stays byte-identical and the Plan 01 monotonicity guard stays green"
  - "Shadow conformance matches each layer's (x,y,blur) px signature against the 5 token geometries (border/subtle x2/popover/raised); 'none' and zero-radius/zero-spacing pass (absence of styling is conformant)"
  - "Translucent foregrounds are composited over the resolved background; a fully-transparent captured background falls back to the resolved --tl-color-bg token so contrast is still computable"

patterns-established:
  - "Pure-computation utility module (no Phoenix/LiveView guard) reading committed .planning/ JSON — first of its kind in the tree"
  - "verify.* alias that is a plain `test <file>` list (not a Playwright-wrapping function) so it runs in ci.all with no Node/browser cost"

requirements-completed: [MECH-01, MECH-02, MECH-03]

coverage:
  - id: D1
    description: "MechanicalChecker computes token-grid/spacing/type-size/radius/shadow/motion conformance from captured element_styles (MECH-01) with nearest-token fix-carrying violations"
    requirement: MECH-01
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#an off-scale border-radius yields a MODE-A radius violation carrying a nearest-token :fix"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#an off-scale padding yields a MODE-A spacing violation with a nearest-token :fix"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#token scale constants match the style.ex --tl-* SSOT values"
        status: pass
    human_judgment: false
  - id: D2
    description: "MechanicalChecker computes WCAG contrast (dark+light, 2.4-gamma), interactive-control count, card-nesting depth, scroll-cost/bp, and distinct-accent-hue from captured styles (MECH-02)"
    requirement: MECH-02
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#relative luminance endpoints are exact (white = 1.0, black = 0.0)"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#a muted mid-tone on dark bg fails 4.5:1 normal text but passes 3.0:1 non-text (proves 2.4 gamma)"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#a card_nesting_depth of 4 yields a MODE-B far-ceiling violation"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#more than 3 distinct accent hues breaches the MODE-B distinct-accent-hue ceiling"
        status: pass
    human_judgment: false
  - id: D3
    description: "A violation blocks a change via mix verify.mechanical in mix ci.all, independent of any LLM (MECH-03) — verify.mechanical is an alias in preferred_envs and sits in ci.all before verify.example_browser"
    requirement: MECH-03
    verification:
      - kind: command
        ref: "mix verify.mechanical (17 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "mix run -e inspect(ci.all) — verify.mechanical at index 8, immediately before verify.example_browser"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/mechanical_checker_test.exs#MODE-A LOCKED constants appear verbatim in mechanical_checker.ex (loosening 4.5->3.0 produces 2 RED failures, then reverted)"
        status: pass
    human_judgment: false
  - id: D4
    description: "run/1 against the committed .planning/scorecards is clean at phase end"
    requirement: MECH-03
    verification: []
    human_judgment: true
    rationale: "Local .planning/scorecards/ is empty/absent — Plan 02's 120-cell capture could not run locally (pre-existing storage_schema/search_path DB issue; capture is CI-run) and was not fabricated. run/1 over the real dir therefore returns a vacuously-clean {:ok, []} (nothing to check). The checker's teeth are proven deterministically by 12 fixture-driven PASS+RED tests instead. Real-evidence cleanliness must be confirmed in CI once the scorecards are captured and committed."

# Metrics
duration: 20min
completed: 2026-07-03
status: complete
---

# Phase 194 Plan 03: MechanicalChecker Deterministic Ratchet Floor Summary

**Built `Threadline.OperatorSurface.MechanicalChecker` — a pure-Elixir gate that reads the committed Tier A scorecard JSON and computes all 9 mechanical metrics (MODE-A WCAG contrast dark+light via the 2.4-gamma piecewise formula plus radius/shadow/motion/font-size/spacing token conformance; MODE-B type-size/interactive/card-nesting/scroll-cost/distinct-accent-hue with betterer-style floors and >3 far ceilings) — and wired `mix verify.mechanical` into `ci.all` before the browser lane so a violation blocks a change with no LLM in the loop.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-03
- **Tasks:** 3
- **Files created:** 2 · **Files modified:** 1

## Accomplishments
- **Task 1 — MechanicalChecker module (feat).** Created `lib/threadline/operator_surface/mechanical_checker.ex` as a plain utility module (no LiveView guard — pure computation). MODE-A LOCKED constants and the four token scales are module attributes. `relative_luminance/1` and `contrast_ratio/2` are public (verbatim WCAG 2.x, gamma 2.4 — Pitfall 4). `run/1` lists `.planning/scorecards/*.json`, decodes each, and flat-maps MODE-A WCAG (from `color_pairs`, with translucent compositing and a resolved `--tl-color-bg` fallback for transparent backgrounds) + conformance (from `element_styles`) + MODE-B (structural counts + Elixir RGB→HSL ±15° hue bucketing over `applied_colors`), returning `{:ok, []}` or `{:error, violations}` where each violation is a located, actionable, fix-carrying map. Compiles clean under `--warnings-as-errors`; credo `--strict` clean.
- **Task 2 — test suite (test).** Created `mechanical_checker_test.exs` (17 tests, `async: true`, no LiveView guard). Meta-test pins every MODE-A LOCKED constant, the four token scales, and the `2.4` gamma exponent verbatim via `String.contains?` (the brandbook_token_parity lock). WCAG unit tests prove exact luminance endpoints and the dual 4.5/3.0 threshold band. Fixture-driven teeth prove both PASS (all-conformant scorecard → `{:ok, []}`) and RED (off-scale radius/padding, failing contrast, card-nesting >3, distinct-hue >3) paths, plus grandfathering and ratchet-regression semantics — all on synthetic tmp-dir JSON with zero dependency on real captured evidence.
- **Task 3 — ci.all wiring (chore).** Added `"verify.mechanical"` (a plain `test <file>` alias) to `aliases/0`, `preferred_envs` (`:test`), and inserted it into the `ci.all` chain immediately before `verify.example_browser` (fail-fast, pure Elixir). Confirmed the chain order programmatically. `mechanical_floors` left `{}` (documented deferral — no captured scorecards to seed from), keeping the ledger byte-identical and the Plan 01 monotonicity guard green (16/16).

## Task Commits

1. **Task 1: create MechanicalChecker** — `a918524f` (feat)
2. **Task 2: mechanical_checker_test (meta + WCAG + teeth)** — `f2fa0582` (test)
3. **Task 3: wire verify.mechanical into ci.all** — `46a13784` (chore)

## Files Created/Modified
- `lib/threadline/operator_surface/mechanical_checker.ex` — CREATED; the deterministic mechanical gate
- `test/threadline/operator_surface/mechanical_checker_test.exs` — CREATED; 17-test meta + unit + teeth suite
- `mix.exs` — `verify.mechanical` alias + `preferred_env :test` + `ci.all` insertion before `verify.example_browser`

## Decisions Made
- **Thread-blue example was a factual error in the plan.** The plan/PATTERNS claimed thread-blue (79,140,255) on dark bg (11,16,32) fails 4.5:1; it is actually 5.885:1 and correctly passes AA. I proved the intended dual-threshold band with a muted steel mid-tone (110,118,134 → ~4.15:1, which fails 4.5 but passes 3.0) and kept a thread-blue sanity assertion. See Deviations.
- **`mechanical_floors` left empty `{}`.** Betterer-style seeding requires a first committed capture; `.planning/scorecards/` is empty locally (Plan 02's capture is CI-run — pre-existing DB issue, not a regression). Fabricating scorecards or floors was explicitly prohibited. The checker treats an absent floor as pass and only ratchets against recorded floors, so seeding can land later (CI) without any code change.
- **Shadow conformance by (x,y,blur) px signature.** Computed `box-shadow` strings differ from source token names, so I match each shadow layer's leading px triple against the 5 token geometries. `none`, zero radius, and zero spacing pass (absence of styling is conformant).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the WCAG mid-tone example (thread-blue actually passes AA)**
- **Found during:** Task 2 (the WCAG dual-threshold unit test)
- **Issue:** The plan `<behavior>` and 194-PATTERNS asserted `contrast_ratio(thread-blue, dark-bg) < 4.5`. Empirically it is 5.885:1 — thread-blue is a light accent that correctly passes AA on the dark surface, so the assertion is impossible to satisfy with the real 2.4-gamma formula.
- **Fix:** Proved the intended dual 4.5/3.0 threshold band with a muted steel mid-tone (110,118,134 → ~4.15:1) that genuinely fails normal-text and passes non-text; retained a thread-blue sanity assertion (≥4.5) so the light-accent truth is also pinned. The 2.4 gamma is additionally locked by a source-string meta-test.
- **Files modified:** test/threadline/operator_surface/mechanical_checker_test.exs
- **Verification:** 17/17 tests pass; the exact endpoints (white=1.0, black=0.0) plus the mid-tone band prove the piecewise 2.4-gamma formula.
- **Committed in:** `f2fa0582`

**2. [Rule 3 - Blocking] Deferred `mechanical_floors` seeding (no captured scorecards exist)**
- **Found during:** Task 3 (betterer-style floor seeding step)
- **Issue:** Task 3 asks to seed `mechanical_floors` from the first committed capture, but `.planning/scorecards/` is empty (Plan 02 capture blocked locally by the pre-existing storage_schema DB issue; it is CI-run). Fabricating evidence/floors is prohibited.
- **Fix:** Left `mechanical_floors` `{}` (ledger byte-identical). The checker treats absent floors as pass and only ratchets against recorded floors, so CI can seed floors from the real capture later with no code change. Documented as an honest deferral.
- **Files modified:** none (`.planning/design-system-ledger.json` intentionally unchanged)
- **Verification:** Plan 01 monotonicity/floor guard 16/16 green; `mix verify.mechanical` green over the empty scorecards dir.
- **Committed in:** n/a (no ledger change)

---

**Total deviations:** 2 (1 Rule-1 bug fix, 1 Rule-3 honest deferral)
**Impact on plan:** MECH-01/02/03 are fully delivered as pure-Elixir code with proven deterministic teeth. The only gap is real-evidence cleanliness (D4), which is environmental (empty local scorecards), not a code gap.

## Issues Encountered
- **`.planning/scorecards/` is empty locally (NOT a regression).** Plan 02's 120-cell Tier A capture could not run in this environment (pre-existing storage_schema/search_path DB issue — `relation "audit_transactions" does not exist`), so no real scorecard JSON exists to assert over. Per instructions I did not drop/create the DB or fabricate scorecards. Consequently `run/1` over the committed directory is vacuously clean (`{:ok, []}` — nothing to check), and the checker's correctness is proven instead by 12 fixture-driven PASS+RED tests. Once the capture runs in CI and the scorecards are committed, `verify.mechanical`'s integration path asserts over real evidence with no code change.
- **Full `mix ci.all` cannot complete locally** for the same reason (its `verify.example`/`verify.example_browser` steps need the migrated example DB + a browser). The new `verify.mechanical` step itself is fully green and correctly positioned; the wiring is verified by direct chain inspection.
- The ~81 pre-existing local `mix test` failures (same storage_schema issue) were not touched.

## User Setup Required
None — no external service configuration. (A properly-migrated example-app DB is an environment prerequisite for running the Tier A capture and thus for `verify.mechanical` to assert over real scorecards; that is not new configuration introduced by this plan.)

## Next Phase Readiness
- The LOCKED deterministic spine is complete: Plan 01 (cube ledger + guard) + Plan 02 (capture lane) + Plan 03 (mechanical gate) all run in `ci.all` before any nondeterministic score producer exists. MODE-A violations carry the exact fix-map shape Phase 196 will auto-apply; MODE-B structural findings route to Phase 196/197 + human.
- Only open item: run `mix verify.capture` in CI (or a migrated local DB) to generate + commit the 120 scorecards, then confirm `verify.mechanical` is green over real evidence and seed `mechanical_floors` from that first capture.

## Self-Check: PASSED

- `lib/threadline/operator_surface/mechanical_checker.ex` — FOUND
- `test/threadline/operator_surface/mechanical_checker_test.exs` — FOUND (17 tests, 0 failures)
- `mix.exs` — `verify.mechanical` present in aliases + preferred_envs + ci.all (index before verify.example_browser) — verified by chain inspection
- Commits `a918524f`, `f2fa0582`, `46a13784` — all present in git log
- `mix verify.format` clean (whole repo); `mix compile --warnings-as-errors` clean; `mix credo --strict` clean on both new files
- Teeth proven: loosening `@wcag_text_contrast_ratio 4.5 -> 3.0` produced 2 RED failures (meta-test + WCAG gate), then reverted → 17/17 green
- Honest gap recorded: `.planning/scorecards/` empty — real-evidence integration is CI-confirmed, not fabricated

---
*Phase: 194-deterministic-scorecard-cube-ledger-mechanical-capture-found*
*Completed: 2026-07-03*
