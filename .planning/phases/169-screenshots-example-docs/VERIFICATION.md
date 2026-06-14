---
phase: 169-screenshots-example-docs
verified: 2026-06-14T00:00:00Z
status: human_needed
score: 10/10 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Run `mix verify.example_browser_light` against the seeded demo app and confirm 12 `*__light__*1280*.png` durable PNGs are emitted plus the 5 light regression baselines auto-namespaced under desktop-chromium-light."
    expected: "All 12 durable light screenshots and 5 light regression baselines write to disk; dark `__default__` baselines remain untouched. The lane is local-only / CI-skipped (cf0e8e2), so this artifact emission cannot run in CI or this verifier."
    why_human: "Requires a running seeded Phoenix demo app + Playwright browser render; the visual lane is local-only by design and the wiring (not the rendered pixels) is all that is statically verifiable."
---

# Phase 169: screenshots-example-docs Verification Report

**Phase Goal:** Adopters can see, run, and read about the theme option — evidence and documentation cover both modes truthfully.
**Verified:** 2026-06-14
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal decomposes into the three ROADMAP success criteria mapped to EVID-01 (screenshot evidence in both modes, local-only) and EVID-02 (example app runs `theme: :system`; docs + doc-contract lock). Every static must-have is VERIFIED in the codebase. The only item that cannot be machine-verified is the actual local-only PNG emission, which the phase deliberately scoped as a manual/local step (CI-skipped per cf0e8e2) — routed to human verification below.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Light lane (desktop-chromium-light) emits `__light__` durable screenshots for all 12 screens at 1280 | ✓ VERIFIED | `operator-screenshots.spec.ts:48` `laneInfix = testInfo.project.name === "desktop-chromium-light" ? "__light__" : "__default__"`; `:61-62` `case "desktop-chromium-light": return "1280"`; `durableScreenshotNames` Set `:10-23` lists exactly the 12 screens |
| 2 | Dark lane still emits `__default__` baselines unchanged — no rename | ✓ VERIFIED | `__default__` retained as the else branch `:48`; dark `desktop-chromium`/`mobile-chromium` viewport cases `:59-64` unchanged; `grep` confirms `__default__` still present (2 occurrences) |
| 3 | Curated 5-screen regression guard runs under the light project with auto-namespaced baselines | ✓ VERIFIED | `playwright.config.ts:23` testMatch widened to `/operator-(accessibility\|screenshots\|screenshot-regression)\.spec\.ts/`; regression `beforeEach :84` skips only `chromium`, admitting `desktop-chromium-light`; 5 screens guarded: home `:106`, timeline-dense `:113`, row-history `:122`, exports `:134`, retention `:141`; `snapshotPathTemplate :37` `{projectName}` token unchanged |
| 4 | Light visual guard stays CI-skipped (local-only per cf0e8e2) | ✓ VERIFIED | `operator-screenshot-regression.spec.ts:78-81` `test.skip(!!process.env.CI, ...)` intact; light project only registered when `lightLane` env gate true (`playwright.config.ts:13,19`) |
| 5 | Guide documents `theme:` option with all three values `:dark`/`:light`/`:system` and what each renders | ✓ VERIFIED | `guides/operator-surface.md:57-91` "### Theme" subsection: triad `:60-61`, per-value renders `:63-71` (`:dark` default/brand, `:light` forced, `:system` OS-auto pure-CSS no-FOUC) |
| 6 | Guide carries the D-04 daytime recommendation framed as readability/accessibility, never medical eye-strain | ✓ VERIFIED | Guide `:73-79` "`:system` is the documented daytime-use recommendation … readability and accessibility choice … astigmatism"; `grep -ci "eye strain"` = 0 |
| 7 | README points daytime teams to `theme: :system` without changing the canonical mount snippet | ✓ VERIFIED | README `:140-143` additive `:system` pointer paragraph sits OUTSIDE the canonical mount block (`:147-161`, which has no `theme:`); guide canonical mount `:46-51` also clean |
| 8 | New doc-contract test pins `theme:` + `:dark`/`:light`/`:system` + daytime recommendation and passes | ✓ VERIFIED | `theme_doc_contract_test.exs` — 5 individual `File.read! + String.contains?` assertions, `async: true`, no capture_io/Mix-task; passes in targeted run |
| 9 | `readme_doc_contract_test.exs` (root README mount guardian) still passes UNCHANGED | ✓ VERIFIED | Targeted run green; `git diff` shows the file is not in any phase commit |
| 10 | The 3 existing snippet doc-contract tests pass UNCHANGED for the files they guard | ✓ VERIFIED | Targeted 5-file run: 40 tests, 0 failures; none of the 4 existing test files appear in the phase commits |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` | `__light__` durable emit + light viewport mapping | ✓ VERIFIED | Contains `__light__` (2), `desktop-chromium-light` viewport case, 12-screen Set unchanged, no `mobile-chromium-light` |
| `examples/threadline_phoenix/e2e/playwright.config.ts` | Widened testMatch for light project | ✓ VERIFIED | testMatch alternation includes `screenshots` + `screenshot-regression`; lightLane gate / colorScheme / snapshotPathTemplate unchanged |
| `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` | Light project admitted to guard | ✓ VERIFIED | `desktop-chromium-light` admitted via `beforeEach` (only `chromium` skipped); CI-skip intact; 5 screens unchanged |
| `guides/operator-surface.md` | Theme subsection w/ triad + daytime rec | ✓ VERIFIED | Subsection present; clean canonical mount; separate `:system` example block |
| `README.md` | Additive `:system` pointer, snippet unchanged | ✓ VERIFIED | Pointer outside mount block; mount block byte-identical (proven by readme_doc_contract_test) |
| `test/threadline/operator_surface/theme_doc_contract_test.exs` | Literal-pin lock | ✓ VERIFIED | Created; 5 passing assertions mirroring timeline_browse analog |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| playwright.config.ts desktop-chromium-light project | operator-screenshots.spec.ts | widened testMatch regex | ✓ WIRED | `operator-(accessibility\|screenshots\|screenshot-regression)` alternation present (`:23`) |
| operator-screenshots.spec.ts screenshotViewport() | `__light__` durable emit | project-name → 1280 case | ✓ WIRED | `case "desktop-chromium-light": return "1280"` (`:61-62`) feeds the `viewport &&` durable guard (`:43`) |
| theme_doc_contract_test.exs | guides/operator-surface.md | File.read! + String.contains? | ✓ WIRED | `@guide_path "guides/operator-surface.md"` read in all 5 tests; assertions pass |
| README.md theme pointer | guides/operator-surface.md Theme subsection | adopter-facing `:system` link | ✓ WIRED | README `:142` links `guides/operator-surface.md#theme` |

### Data-Flow Trace (Level 4)

Not applicable — phase delivers e2e test/config wiring + documentation + a read-and-pin test. No dynamic-data-rendering artifacts (no components, APIs, or stores) were introduced.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| New doc-contract test + 4 existing contracts pass | `mix test <5 doc-contract files>` | 40 tests, 0 failures | ✓ PASS |
| Guide has no medical eye-strain claim | `grep -ci "eye strain" guides/operator-surface.md` | 0 | ✓ PASS |
| No mobile-light lane introduced | `grep -rc mobile-chromium-light examples/.../e2e/` | none | ✓ PASS |
| No lib/ or mix.exs edits in phase commits | `git show --name-only` over 81ac95b/54c7a32/e00a5cd/04f3663 | no matches | ✓ PASS |
| Light PNG artifact emission | `mix verify.example_browser_light` | NOT RUN — local-only, needs seeded demo + browser | ? SKIP → human |

### Probe Execution

No project probes (`scripts/*/tests/probe-*.sh`) declared or applicable for this docs/e2e-wiring phase. The doc-contract test is the phase's runnable check and was executed (green) above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| EVID-01 | 169-01 | `__light__` lane alongside dark, both modes, local-only CI-skipped | ✓ SATISFIED | Truths 1-4; wiring verified statically; artifact emission is the local-only manual step (human item) |
| EVID-02 | 169-02 | Example app demonstrates `theme: :system`; guide + adopter docs document the option w/ daytime rec; doc-contract lock | ✓ SATISFIED | Truths 5-10; `:system` exercised via env-gated e2e branch the light lane drives; docs + new lock present and green |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | — | — | None. No TBD/FIXME/XXX, no stubs, no hardcoded-empty data, no orphaned artifacts in the 6 phase files. |

### Scope Discipline

All 4 phase commits (81ac95b, 54c7a32, e00a5cd, 04f3663) touch ONLY the 6 declared files. `git show --name-only` confirms no `lib/`, no `mix.exs`, no example-app router, and no nav-overhaul file was staged or committed. The auto-fixed daytime-line reflow (folded into 04f3663) touched only `guides/operator-surface.md`, a declared plan-02 file — consistent with the SUMMARY. The ~30 uncommitted nav-overhaul working-tree files and 3 pre-existing failures are correctly out of scope and were not attributed to this phase (full suite was not run, per instruction).

### Human Verification Required

#### 1. Local-only light screenshot artifact emission

**Test:** Run `mix verify.example_browser_light` against the seeded demo app.
**Expected:** 12 `*__light__*1280*.png` durable PNGs emit to `OPERATOR_SCREENSHOT_DIR`, plus 5 light regression baselines auto-namespaced under `desktop-chromium-light`; dark `__default__` baselines remain untouched.
**Why human:** Requires a running seeded Phoenix demo + Playwright browser render. The lane is local-only / CI-skipped by design (cf0e8e2); only the wiring is statically verifiable, and it is fully verified above. This is the intended manual step the lane exists for, not a gap.

### Gaps Summary

No gaps. Every static must-have across EVID-01 and EVID-02 is VERIFIED with codebase evidence: the light lane emits `__light__` while the dark lane keeps `__default__` (no rename), the 5-screen regression guard is admitted under the light project with the CI-skip posture intact, the guide documents the `theme:` triad with the readability/accessibility daytime recommendation (no medical eye-strain claim), the README `:system` pointer is additive and leaves both canonical mount snippets byte-identical, and the new literal-pin doc-contract test plus the 4 pre-existing contracts pass green (40/40). Scope is clean — only the 6 declared files changed.

The status is `human_needed` solely because the actual light-mode PNG emission is a deliberately local-only step that cannot run in this verifier; the static wiring that produces it is fully verified. There is nothing to remediate.

---

_Verified: 2026-06-14_
_Verifier: Claude (gsd-verifier)_
