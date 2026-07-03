---
phase: 194-deterministic-scorecard-cube-ledger-mechanical-capture-found
verified: 2026-07-03T00:00:00Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
# Both former CI-pending items were shifted left into automated gates (2026-07-03).
# The Tier A capture executed against a migrated example DB; 120 scorecards + 54
# aria.yml committed, byte-stable; MechanicalChecker.run/1 is {:ok, []} over the
# real evidence; mechanical_floors seeded. See 194-UAT.md (both tests pass).
automated_verification:
  - test: "MECH-04 — Tier A capture emits 120 byte-stable evidence bundles from /audit/__stress."
    covered_by: "CI job verify-capture (.github/workflows/ci.yml) — regenerates the lane on a fresh migrated DB and asserts the 120 json + 54 aria.yml count AND byte-stable regeneration (git status --porcelain .planning/scorecards/ empty). Local: mix verify.capture. Genesis evidence committed in f0990a2f; byte-stability proven twice locally."
  - test: "Capture→check E2E clean over real evidence + mechanical_floors seeded."
    covered_by: "CI job verify-mechanical + the real-evidence gate in mechanical_checker_test.exs — asserts MechanicalChecker.run/1 == {:ok, []} over the committed scorecards on every run (mix verify.mechanical). mechanical_floors seeded with 600 values via measure_mode_b/1; stress_ledger_test 16/16 + mechanical_checker_test 18/18 green."
    follow_up: "A capture-scoping defect (the /audit/__stress harness sidebar chrome leaked into evidence, producing 120 spurious 1:1 WCAG findings) was found and fixed in ab2fb7f7 — the real product surface is fully conformant. LEDGER-02/03 committed-teeth recommendation from the notes below still applies at Phase 195 when cells are first rated."
---

# Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation — Verification Report

**Phase Goal:** The design-system ledger records an independently-ratcheted `page × persona × lens` scorecard cube, deterministic mechanical checkers act as the ratchet floor, and a tiered Playwright capture lane emits complete per-cell evidence bundles from `/audit/__stress` — the entire deterministic spine runs inside `mix ci.all` with no LLM and no network.
**Verified:** 2026-07-03
**Status:** human_needed (PASS-WITH-CI-PENDING)
**Re-verification:** No — initial verification

## Goal Achievement

The deterministic spine (ledger cube + guards + mechanical checker + `ci.all` wiring) is fully delivered and independently re-verified locally. The one behavior that cannot be observed here — the Tier A capture actually emitting its 120-cell evidence bundle — is code-complete but unexecuted due to a documented local DB limitation, and must be confirmed in CI. No requirement is FAILED; no stub, missing artifact, or unwired link was found.

### Observable Truths (per requirement)

| #  | Requirement | Truth | Status | Evidence |
|----|-------------|-------|--------|----------|
| 1  | LEDGER-01 | Ledger records a `page × persona × lens` scorecard cube per entry, each lens independent | VERIFIED | `.planning/design-system-ledger.json` `version: 2`; 130 entries, each with a sorted 14-cell `scores` map (`P1.hierarchy`…`all.brand_fidelity`) + `legacy_score`; `cube_axes` with 5 personas + 6 lenses in frozen order. Guard `cube_axes declares the frozen lens order and every entry carries the valid cell set` (line 328) passes. Verified via Node inspection: 0 entries missing scores/legacy_score, 0 wrong cell counts. |
| 2  | LEDGER-02 | `stress_ledger_test.exs` fails any lens cell below its floor without a ratchet reset + rationale | VERIFIED (guard present + correct; teeth manually proven — see Notes) | Guard `per-cell scores can only ratchet upward unless the entry has an explicit reset` (lines 281-302) asserts `current < floor ⇒ id ∈ ratchet.resets AND non-empty reset_rationale`. Real assertion logic, not a stub. Vacuously green at rest (all cells unrated); teeth demonstrated by inject-then-revert during execution. |
| 3  | LEDGER-03 | A score increase without a `File.exists?`-true `evidence_ref` fails the ratchet test | VERIFIED (guard present + correct; vacuous at rest — see Notes) | Guard `a score increase carries a File.exists?-true evidence_ref for every cited cell` (lines 304-326): for entries where `current_score > ratchet_score`, asserts `evidence_ref` is a non-empty cell-keyed map and every path `File.exists?`. Real logic. Never fires at rest (all `current_score == ratchet_score`). |
| 4  | LEDGER-04 | `DESIGN-SYSTEM.md` projects per-lens columns, freshness-tested per row | VERIFIED | `## Scorecard Cube` present (DESIGN-SYSTEM.md:225), 385 projected rows (77 page-kinds × 5 personas), frozen 6-lens column order. Guard `Scorecard Cube projection is fresh for every page-entry × persona row` (line 235) passes; pre-existing inventory freshness (line 224) unbroken. |
| 5  | LEDGER-05 | Ledger + guards run inside `mix ci.all` deterministically — async:true, pure filesystem, no LLM, no network | VERIFIED | `stress_ledger_test.exs` `use ExUnit.Case, async: true`; pure `File`/`Jason` reads. Grep for HTTP/LLM/network/System.cmd/Port in guard + checker: NONE. Runs green standalone (16/16). (Full `ci.all` chain can't complete locally — env DB limitation — but the guard step itself is confirmed green + wired.) |
| 6  | MECH-01 | Deterministic checker computes token-grid/spacing/type-size/radius/shadow/motion conformance from captured styles | VERIFIED (code + committed teeth; real-evidence E2E CI-pending) | `mechanical_checker.ex` `check_conformance/1` → radius/shadow/motion/font-size/spacing violations from `element_styles`, each carrying a nearest-token `:fix`. Token scales pinned to `style.ex` SSOT by meta-test (line 37). Committed RED fixtures: off-scale radius (line 125), padding (line 143). |
| 7  | MECH-02 | Deterministic checker computes WCAG contrast (dark+light), interactive-control count, card-nesting depth, scroll-cost/bp, distinct-accent-hue | VERIFIED (code + committed teeth; real-evidence E2E CI-pending) | `relative_luminance/1` (2.4-gamma piecewise, pinned by meta-test line 53), `contrast_ratio/2`, translucent compositing; MODE-B `check_mode_b/1` reads structural counts + computes distinct-accent-hue via RGB→HSL ±15° bucketing. Committed teeth: white=1.0/black=0.0 (line 64), mid-tone dual-threshold (line 77), card-nesting >3 (line 177), >3 distinct hues (line 224). |
| 8  | MECH-03 | Mechanical checks act as ratchet-floor gates blocking a change independently of any LLM, via `mix verify.mechanical` folded into `mix ci.all` | VERIFIED | `mix.exs`: `verify.mechanical` alias (line 100), `preferred_env :test` (line 16), inserted into `ci.all` at line 121 immediately before `verify.example_browser` (line 124). `mix help verify.mechanical` resolves. Meta-test pins LOCKED constants (loosening 4.5→3.0 produces RED per summary). Pure Elixir — no LLM/network. |
| 9  | MECH-04 | Playwright capture lane emits a complete evidence bundle per cell (screenshot + DOM + ARIA + resolved `--tl-*` tokens + meta) from `/audit/__stress`, byte-stable | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Capture spec is a complete real implementation (385 lines): drives `/audit/__stress`, resolves all `--tl-*` tokens via `getComputedStyle`, emits `color_pairs`/`element_styles`/`applied_colors`/`mode_b`, `#tl-main` `ariaSnapshot()`, gitignored binaries + committed scorecards. BUT lane never executed — `.planning/scorecards/` absent (0/120); byte-stability unproven. Blocked by documented local DB env limitation. CI-pending. |
| 10 | MECH-05 | Capture is tiered and documented (Tier A/B/C) with an explicit page × state × breakpoint × theme matrix | VERIFIED | `## Capture Matrix` (DESIGN-SYSTEM.md:182) documents Tier A (Band 1 = 66 + Band 2 = 54 = 120), Tier B (LLM sample, Phase 195), Tier C (3 pixel baselines, advisory) with the enumerated matrix. Guard adds `"Capture Matrix"` to `@design_sections` + asserts Tier C `ci` allowlist == 3 (line 191). |

**Score:** 9/10 requirements verified locally (1 present, behavior-unverified — MECH-04).

### Locally re-run deterministic checks (all confirmed green)

| Check | Command | Result |
|-------|---------|--------|
| Format | `mix format --check-formatted` | exit 0 (clean) |
| Ledger guard | `mix test .../stress_ledger_test.exs` | 16 tests, 0 failures |
| Mechanical checker | `mix test .../mechanical_checker_test.exs` | 17 tests, 0 failures |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.planning/design-system-ledger.json` | v2 cube: cube_axes, mechanical_floors {}, ratchet.signoffs [], 130 entries × 14-cell scores + legacy_score | ✓ VERIFIED | Confirmed via Node inspection; scalars untouched, cells born unrated |
| `test/threadline/operator_surface/stress_ledger_test.exs` | v2 attrs + 5 cube guards + freshness + `valid_cell_keys/1` | ✓ VERIFIED | 16 blocks incl. rollup-integrity, per-cell monotonicity, evidence-on-gain, axis validity, floor-bump authority; `Lost Pixel` added to `@forbidden_terms` |
| `DESIGN-SYSTEM.md` | `## Scorecard Cube` + `## Capture Matrix` | ✓ VERIFIED | Both sections present; 385 cube rows; Tier A/B/C documented |
| `lib/threadline/operator_surface/mechanical_checker.ex` | run/1 + relative_luminance/1 + contrast_ratio/2 + MODE-A/B, LOCKED constants | ✓ VERIFIED | 650 lines pure Elixir; no network/LLM/browser; substantive |
| `test/threadline/operator_surface/mechanical_checker_test.exs` | meta-test + WCAG unit + MODE-A/B teeth | ✓ VERIFIED | 17 tests incl. committed RED fixtures + constant-pinning meta-test |
| `mix.exs` | verify.mechanical alias + ci.all wiring + verify.capture | ✓ VERIFIED | All present; verify.mechanical before verify.example_browser in ci.all |
| `examples/.../operator-tier-a-capture.spec.ts` | 120-cell Tier A capture lane | ⚠️ code-complete, unexecuted | Real 385-line spec; produces no output yet (see MECH-04) |
| `.planning/scorecards/*.json` | 120 committed scorecards | ✗ ABSENT | 0/120 — blocked by local DB env limitation; CI-pending |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| `mix ci.all` | `verify.mechanical` | alias chain (mix.exs:121, before verify.example_browser) | ✓ WIRED |
| `verify.mechanical` | `mechanical_checker_test.exs` | `["test test/.../mechanical_checker_test.exs"]` | ✓ WIRED |
| `MechanicalChecker.run/1` | `.planning/scorecards/*.json` | `File.ls` + `Jason.decode!` (no browser) | ✓ WIRED (reads real committed JSON; dir empty locally) |
| capture spec | `.planning/scorecards/` | `writeFileSync` per cell | ⚠️ code present, never invoked |
| `verify.capture` | both tier-a projects | `verify_example_browser([--project=tier-a-capture --project=tier-a-capture-light ...])` | ✓ WIRED (not in ci.all, by design) |

### Determinism Constraint (verification task 4)

Confirmed: `grep` over `mechanical_checker.ex` + `stress_ledger_test.exs` for `HTTPoison|Finch|Req|Tesla|:httpc|System.cmd|Port.open|Node|OpenAI|anthropic|claude|http` → **NONE**. Both suites are `async: true`, pure `File`/`Jason`/arithmetic. The WCAG gamma-2.4 formula is single-sourced in Elixir and pinned by the meta-test; the browser (Plan 02) deliberately emits RAW inputs only. No LLM, no network anywhere in the assert path.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| (all phase files) | TBD/FIXME/XXX debt markers | — | NONE found |
| (checker + capture spec) | TODO/HACK/PLACEHOLDER/"not yet implemented" | — | NONE found |

### Notes / Recommendations (not gaps)

1. **LEDGER-02 / LEDGER-03 teeth are transient, not committed.** Both guards are present, correct, and passing, but at rest they iterate over an all-unrated ledger (`current: null`, `current_score == ratchet_score`), so their RED branches never execute against live data. The teeth were proven by inject-then-revert during execution (documented in 194-01-SUMMARY) but no permanent negative regression test was committed. This contrasts with `mechanical_checker_test.exs`, which DID commit fixture-driven RED tests. **Recommendation (Phase 195+, when cells are first rated):** add committed synthetic-fixture RED tests for per-cell monotonicity and evidence-on-gain so the guards' teeth survive regression, matching the mechanical checker's rigor. Not a blocker — the enforcement code is real and reviewed.

2. **`mechanical_floors` intentionally left `{}`.** Betterer-style seeding requires the first real capture; correctly deferred to CI (documented honest deferral). The checker treats absent floors as pass, so seeding lands later with no code change.

### Gaps Summary

No FAILED requirements, no stubs, no unwired links, no debt markers. The deterministic spine — the phase's load-bearing "guard-before-producer" intent — is fully delivered and locally verified (9/10 requirements green; format + both guard suites re-run clean).

The single open item is **MECH-04**: the Tier A capture lane is code-complete and reviewed but has never executed, so its 120 evidence bundles do not yet exist and byte-stability is unproven. This is blocked by a **pre-existing local storage_schema/search_path DB limitation** (`relation "audit_transactions" does not exist` during example-app seeding), explicitly documented in project memory and honestly recorded in both 194-02 and 194-03 SUMMARYs — **not a code defect introduced by this phase**. The dependent capture→check E2E (`verify.mechanical` `{:ok, []}` over real evidence + `mechanical_floors` seeding) is likewise CI-pending.

**Verdict: PASS-WITH-CI-PENDING** (status `human_needed`). The phase code is complete and the deterministic guards are verified; two behavioral confirmations require CI (or a migrated local DB) before the ledger checkboxes should be marked done: (1) the Tier A capture executes and byte-stably produces 120 scorecards, and (2) `verify.mechanical` runs clean over that real evidence with `mechanical_floors` seeded.

---

_Verified: 2026-07-03_
_Verifier: Claude (gsd-verifier)_
