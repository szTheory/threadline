---
phase: 194-deterministic-scorecard-cube-ledger-mechanical-capture-found
plan: 02
subsystem: testing
tags: [playwright, tier-a-capture, scorecard, wcag, design-system, e2e, elixir, mix-alias]

# Dependency graph
requires:
  - phase: 194-01
    provides: "design-system-ledger v2 cube (cube_axes, mechanical_floors, ratchet.signoffs, per-entry 14-cell scores) + stress_ledger_test guard"
provides:
  - "operator-tier-a-capture.spec.ts — deterministic Playwright capture lane driving /audit/__stress, emitting per-cell RAW-inputs scorecard JSON + deep-band #tl-main ARIA YAML + gitignored binaries (MECH-04)"
  - "Tier A projects (tier-a-capture / tier-a-capture-light, deviceScaleFactor:1) + capture:tier-a npm script + mix verify.capture runner (both themes, 120 cells, not in ci.all)"
  - "StressFixtures @viewports gains 1280 so /audit/__stress?viewport=1280 is accepted"
  - "DESIGN-SYSTEM.md ## Capture Matrix documenting Tier A/B/C with the explicit page × state × breakpoint × theme matrix (MECH-05), guard-asserted; Tier C ci allowlist pinned at exactly 3"
affects: [194-03-mechanical-checker, phase-195-cell-rating]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Browser captures RAW inputs only (resolved --tl-* tokens, color_pairs, element_styles, applied_colors, mode_b structural counts); WCAG/hue/conformance verdicts computed in Elixir (Plan 03) — single-sourced gamma-2.4 formula"
    - "Byte-stable committed evidence: no wall-clock timestamp, pinned playwright_version, sorted sets, 2-space JSON + trailing newline; determinism stack = deviceScaleFactor:1 (project-level) + global reducedMotion:reduce + scale:css + dynamicMasks + #tl-main aria subtree + DB-free fixtures"
    - "Cell-id = {ledger_id}__{theme}-{breakpoint}; deep-band (Band 2) additionally commits <cell-id>.aria.yml"
    - "One capture test per colorScheme project loops all 60 cells after a single login (2 logins total)"

key-files:
  created:
    - "examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts — the 120-cell Tier A capture spec"
  modified:
    - "lib/threadline/operator_surface/stress_fixtures.ex — @viewports gains 1280"
    - "test/threadline/operator_surface/stress_fixtures_test.exs — viewport-matrix assertion updated to include 1280"
    - "examples/threadline_phoenix/e2e/playwright.config.ts — tier-a-capture + tier-a-capture-light projects (deviceScaleFactor:1)"
    - "examples/threadline_phoenix/e2e/package.json — capture:tier-a script"
    - ".gitignore + examples/threadline_phoenix/e2e/.gitignore — artifacts/tier-a"
    - "mix.exs — verify.capture alias (both projects) + preferred_env :test"
    - "DESIGN-SYSTEM.md — ## Capture Matrix (Tier A/B/C)"
    - "test/threadline/operator_surface/stress_ledger_test.exs — Capture Matrix @design_sections + Tier C ci length-3 assertion"

key-decisions:
  - "verify.capture runs BOTH tier-a projects (dark+light), not the single --project=tier-a-capture the PATTERNS suggested — a single project yields only 60 cells and cannot satisfy the 120-cell gate"
  - "Omitted the captured_at wall-clock timestamp from the committed scorecard (RESEARCH schema showed it) to honor byte-stable regeneration; replaced with a deterministic meta block"
  - "Band 2 permission state maps to the ledger `permission` audit path (page.<page>.permission); Band 2 pages = transaction/coverage/retention per locked decision 1"
  - "Tier C 1024 baselines kept at 1024 (not rebaselined to 1280) and bounded at exactly 3 — guard-asserted in Elixir"

patterns-established:
  - "Capture/assert separation: browser writes committed diffable JSON evidence at capture time; Elixir asserts over that JSON at ci.all time with no browser"
  - "verify.capture mirrors verify_operator_stress/1 but prepends both --project flags + the spec file, delegating to verify_example_browser/1"

requirements-completed: [MECH-05]

coverage:
  - id: D1
    description: "StressFixtures @viewports includes 1280 so /audit/__stress?viewport=1280 resolves; two Tier A Playwright projects (project-level deviceScaleFactor:1) + capture:tier-a npm script + both gitignore entries"
    requirement: MECH-04
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/stress_fixtures_test.exs#theme modes and viewport matrix are fixed"
        status: pass
      - kind: e2e
        ref: "npx playwright test --list --project=tier-a-capture operator-tier-a-capture.spec.ts (config parses, 1 test discovered per project)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Tier A capture lane emits a complete per-cell evidence bundle (screenshot + DOM + raw a11y + resolved --tl-* tokens + RAW color/style inputs + mode_b counts + meta) driven from /audit/__stress; 120 committed scorecard JSON (66 Band-1 + 54 Band-2) + 54 deep-band aria.yml; byte-stable regeneration"
    requirement: MECH-04
    verification: []
    human_judgment: true
    rationale: "The 120-cell capture could NOT be executed in this local environment — mix verify.capture failed during example-app seeding (mix demo.seed) with 'relation audit_transactions does not exist', the pre-existing storage_schema/search_path issue documented in project memory. Per instructions I did not drop/create the DB or fabricate scorecards. The spec + config + runner are complete and the spec transpiles and lists correctly under both projects; execution must be confirmed where the audit migrations are present (CI, which already runs verify.example_browser green). No scorecards exist yet, so byte-stability is unproven."
  - id: D3
    description: "DESIGN-SYSTEM.md ## Capture Matrix documents Tier A (deterministic, 120 cells, CI-gated) / Tier B (LLM sample, local) / Tier C (3 pixel baselines, advisory) with the enumerated page × state × breakpoint × theme matrix; guard asserts the section is present and the Tier C ci allowlist stays bounded at 3"
    requirement: MECH-05
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/stress_ledger_test.exs#DESIGN-SYSTEM projection contains deterministic inventory sections"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/stress_ledger_test.exs#screenshot allowlist references real ledger entries and named review dimensions (Tier C ci length == 3)"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-03
status: complete
---

# Phase 194 Plan 02: Tier A Deterministic Capture Lane Summary

**Authored the deterministic Playwright Tier A capture lane (operator-tier-a-capture.spec.ts) that drives /audit/__stress and emits per-cell RAW-inputs scorecard JSON + deep-band #tl-main ARIA YAML under a documented, guard-asserted Tier A/B/C matrix — with WCAG/hue/conformance math deliberately left to Elixir (Plan 03). The 120-cell capture could not be executed in this local environment due to the pre-existing example-app DB seeding issue and was not fabricated.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-07-03T09:12Z
- **Completed:** 2026-07-03T09:37:07Z
- **Tasks:** 3 (Task 2 code complete; its capture execution blocked locally)
- **Files created:** 1 · **Files modified:** 9

## Accomplishments
- **Task 1 — scaffolding (verified).** Added `1280` to `StressFixtures.@viewports` (Pitfall 3) and updated the fixtures guard assertion; confirmed `stress_live.ex` `@viewport_allowlist` already derives from `StressFixtures.viewports()` (no code change). Added `tier-a-capture` + `tier-a-capture-light` Playwright projects with **project-level** `deviceScaleFactor:1` (never global — Pitfall 5), the `capture:tier-a` npm script, and both `artifacts/tier-a` gitignore entries. Guard + fixtures suites stay green; config parses.
- **Task 2 — capture lane (code complete; execution blocked locally).** Authored `operator-tier-a-capture.spec.ts`: per cell it navigates `/audit/__stress?story=&theme=&viewport=`, resizes per breakpoint, and emits gitignored binaries (PNG `scale:"css"` + DOM + raw a11y) plus a **committed RAW-inputs** scorecard (resolved `--tl-*` tokens, `color_pairs`, `element_styles`, `applied_colors`, `mode_b` structural counts using the locked card-selector set, `a11y_summary`, `artifacts`), and for Band 2 a committed `#tl-main` `ariaSnapshot()` (Pitfall 6). No WCAG/hue/conformance verdicts in the browser (Pitfall 4). Wired `mix verify.capture` to run **both** theme projects. The spec transpiles and lists 1 test per project; the actual 120-cell run failed at example-app seeding (see Issues).
- **Task 3 — tiered matrix documented + guarded (verified).** Added `## Capture Matrix` to `DESIGN-SYSTEM.md` enumerating Tier A (Band 1 = 11 pages × happy × 3 bp × 2 themes = 66; Band 2 = {transaction,coverage,retention} × {empty,error,permission-denied} × 3 bp × 2 themes = 54; total 120), Tier B (LLM sample, local, Phase 195), Tier C (3 pixel baselines at 1024, advisory). Extended the guard: `"Capture Matrix"` in `@design_sections` + a Tier C `ci` length-3 assertion. 16/16 guard tests green.

## Task Commits

1. **Task 1: viewport + Playwright projects + gitignore scaffolding** — `3f69edfd` (feat)
2. **Task 2: author capture spec + verify.capture runner** — `d472f2b6` (feat)
3. **Task 3: document + guard the tiered Capture Matrix** — `19dbf282` (feat)

## Files Created/Modified
- `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts` — CREATED; the 120-cell Tier A capture lane
- `lib/threadline/operator_surface/stress_fixtures.ex` — `@viewports` gains 1280
- `test/threadline/operator_surface/stress_fixtures_test.exs` — viewport-matrix assertion updated
- `examples/threadline_phoenix/e2e/playwright.config.ts` — two tier-a projects (deviceScaleFactor:1)
- `examples/threadline_phoenix/e2e/package.json` — `capture:tier-a` script
- `.gitignore`, `examples/threadline_phoenix/e2e/.gitignore` — `artifacts/tier-a`
- `mix.exs` — `verify.capture` alias (both projects) + `preferred_env :test`
- `DESIGN-SYSTEM.md` — `## Capture Matrix` (Tier A/B/C)
- `test/threadline/operator_surface/stress_ledger_test.exs` — Capture Matrix section + Tier C length-3 guard

## Decisions Made
- **verify.capture runs both theme projects.** The PATTERNS analog (`--project=tier-a-capture` only) would produce just 60 cells; the plan's own Task 2 gate wants 120, so the alias prepends both `--project` flags + the spec file.
- **No wall-clock timestamp in committed scorecards.** The RESEARCH schema listed `captured_at`, but a live timestamp breaks the "second `mix verify.capture` leaves `git diff` empty" must-have. Replaced with a deterministic `meta` block (pinned `playwright_version`, `device_scale_factor`, `viewport`, `color_scheme`).
- **Band 2 uses the ledger `permission` audit path** for "permission-denied"; pages = transaction/coverage/retention per locked decision 1.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Pulled the `mix verify.capture` alias forward from Task 3 into Task 2, and made it run BOTH tier-a projects**
- **Found during:** Task 2 (its `<verify>` is literally `mix verify.capture`)
- **Issue:** The alias lived in Task 3's scope, but Task 2 cannot self-verify without it; and the PATTERNS single-project form yields only 60 cells, not 120.
- **Fix:** Added `verify.capture` (delegating to `verify_example_browser/1` with `--project=tier-a-capture --project=tier-a-capture-light operator-tier-a-capture.spec.ts`) + `preferred_env :test` in the Task 2 commit; kept it out of `ci.all`.
- **Files modified:** mix.exs
- **Verification:** `mix help verify.capture` resolves; alias compiles.
- **Committed in:** `d472f2b6`

**2. [Rule 3 - Blocking] Updated the fixtures viewport-matrix assertion**
- **Found during:** Task 1
- **Issue:** `stress_fixtures_test.exs` pins `viewports() == [320,375,768,1024,1440]`; adding 1280 to `@viewports` would fail it.
- **Fix:** Updated the assertion to include 1280 (keeps the guard suite green).
- **Files modified:** test/threadline/operator_surface/stress_fixtures_test.exs
- **Verification:** `mix test .../stress_fixtures_test.exs` 13/13 green.
- **Committed in:** `3f69edfd`

**3. [Rule 2 - Correctness] Omitted `captured_at` for byte-stability** — see Decisions. Committed in `d472f2b6`.

---

**Total deviations:** 3 auto-fixed (2 blocking, 1 correctness)
**Impact on plan:** All three are necessary to satisfy the plan's own gates (120-cell verify, green guard suite, byte-stable regeneration). No scope creep.

## Issues Encountered
- **The 120-cell capture could not be executed locally (NOT a regression).** `mix verify.capture` runs the full `run-e2e.sh` setup (compile example app → `ecto.create`/`migrate` → `demo.reset`/`demo.seed` → start server → capture). Seeding failed with `** (Postgrex.Error) ERROR 42P01 (undefined_table) relation "audit_transactions" does not exist` — the pre-existing local **storage_schema/search_path** issue recorded in project memory (audit tables not migrated in this local DB). Per the verification requirement and that memory note, I did **not** drop/create the DB and did **not** fabricate scorecard files. Consequently `.planning/scorecards/` is empty and byte-stability is unproven **here**. The lane is CI-ready: the spec transpiles and lists correctly under both projects, and prior phases run `verify.example_browser` green in CI where the audit migrations exist. Recommended next step: run `mix verify.capture` in an environment with a properly-migrated example DB (CI or a fixed local DB) to generate + commit the 120 scorecards.
- Elixir verification that does not need the browser is all green: `mix compile --warnings-as-errors` (clean), `mix format --check-formatted` (clean, whole repo), `mix test` on the two guard files (29/29). The ~81 pre-existing local `mix test` failures (same storage_schema issue) were not touched.

## User Setup Required
None - no external service configuration required. (A properly-migrated example-app DB is required to run the capture; that is an environment prerequisite, not new configuration this plan introduces.)

## Next Phase Readiness
- **MECH-05 is fully delivered and guarded** (tiered matrix documented + asserted). **MECH-04's lane code is complete** but its evidence artifacts (120 scorecards + 54 aria.yml) are not yet generated — Plan 03 (`mix verify.mechanical`) reads `.planning/scorecards/*.json`, so the capture must be executed (CI or fixed local DB) before Plan 03 has inputs to assert over.
- No blockers to Plan 03's checker-module authoring; it can be built against the committed scorecard schema documented here and generate its own fixture JSON for unit tests.

## Self-Check: PASSED

- `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts` — FOUND (lists 1 test/project under both tier-a projects)
- Commits `3f69edfd`, `d472f2b6`, `19dbf282` — all present in git log
- `mix test .../stress_ledger_test.exs` 16/16 green (incl. Capture Matrix section + Tier C length-3); `.../stress_fixtures_test.exs` 13/13 green
- `mix compile --warnings-as-errors` clean; `mix format --check-formatted` clean
- Honest gap recorded: `.planning/scorecards/` empty — 120-cell capture blocked by local DB seeding, not fabricated

---
*Phase: 194-deterministic-scorecard-cube-ledger-mechanical-capture-found*
*Completed: 2026-07-03*
