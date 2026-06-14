# Phase 169: screenshots-example-docs - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 169 makes the light theme option **visible, runnable, and documented** —
the *evidence + documentation* proof for the dual-lane token system shipped in
Phases 166–168. It invents no tokens, colors, or layout (those are locked and
human-reviewed). Three deliverables (EVID-01, EVID-02):

1. **EVID-01 — `__light__` screenshot lane.** Add a light screenshot lane beside
   the existing dark (`__default__`) durable baselines, driven by the Phase-168
   light plumbing (`THREADLINE_E2E_THEME=system` → `desktop-chromium-light`
   Playwright project under Playwright `colorScheme: light`). Local-only — the
   visual guard stays CI-skipped per `cf0e8e2`.
2. **EVID-02 part 1 — example app runs `theme: :system` end-to-end.** The example
   app mounts the operator surface with `theme: :system` (already env-gated for the
   light lane) and runs the operator-surface e2e under the light lane.
3. **EVID-02 part 2 — docs + doc-contract lock.** `guides/operator-surface.md` and
   at least one adopter-facing doc document the `theme:` option with the daytime-use
   recommendation, and a doc-contract test locks the new option literal.

This phase proves **appearance/documentation**; Phase 168 already proved
**behavior/affordance** in both modes. No theme-toggle UI (carried 165-01 ban).

**Hard boundary — do NOT touch the uncommitted nav-overhaul lane** (~29 modified
files in `git status`: `app.html.heex`, `page_controller.ex`, live views,
`style.ex`, `surface_header.ex`, the operator e2e specs, etc., incl. its
pre-existing test failures). It is unrelated WIP and out of bounds for this phase.

</domain>

<decisions>
## Implementation Decisions

### Light screenshot lane — mechanism & naming (EVID-01)
- **D-01: Reuse the Phase-168 light plumbing; do not build a new lane.** Drive the
  light screenshots through the existing `desktop-chromium-light` Playwright project
  (gated by `THREADLINE_E2E_THEME=system`, run via `mix verify.example_browser_light`
  / `run-e2e.sh --project=desktop-chromium-light`, rendered under Playwright
  `colorScheme: light` against the `[data-tl-theme="system"]` branch). Minimal wiring:
  widen that project's `testMatch` (currently scoped to `operator-accessibility.spec.ts`)
  to also include `operator-screenshots.spec.ts`; emit the `__light__` suffix when in
  the light lane; teach `screenshotViewport()` the `desktop-chromium-light` project
  name (→ `1280`). This mirrors 168 D-01 (zero new example-app footprint, reuses the
  proven `:system` light render path).
- **D-02: Keep `__default__` for the dark lane; add `__light__` beside it — no rename.**
  48 committed `*__default__*` baselines + planning-doc references would churn for zero
  functional benefit, and the asymmetry correctly encodes "dark is primary, light is the
  opt-in variant." Renaming `__default__` → `__dark__` for symmetry is **deferred** until
  a real multi-mode-CI demand exists.

### Light screenshot coverage (EVID-01)
- **D-03: Full durable screen set, desktop-only.** Capture all 12 durable screens
  (actor, coverage, evidence, exports, home, redaction, retention, row-history,
  timeline, timeline-dense, timeline-empty, transaction) in light at desktop `1280`
  only — reusing the single existing `desktop-chromium-light` project (NO new
  `mobile-chromium-light` project). Also mirror the curated **5-screen regression
  guard** (home, timeline-dense, row-history, exports, retention) in the light lane
  (desktop). Mobile-light is **deferred**: Phase 168's affordance re-run + the
  responsive specs already proved layout is mode-independent, so doubling the mobile
  baseline matrix adds little evidence. This satisfies success-criterion-1's "screen
  set in both modes" (modes = dark+light, not viewports).

### Adopter theme recommendation (EVID-02 part 2)
- **D-04: Lead with `theme: :system` as the documented daytime-use recommendation.**
  Truthful framing anchored to the implementation: `:dark` is the omitted default and
  brand-primary; `:system` auto-follows the OS via pure-CSS
  `@media (prefers-color-scheme: light)` (no JS, no FOUC, first-paint correct on the
  dead render); `:light` forces light regardless of OS. Recommend `:system` for teams
  whose operators work in bright/daytime environments, with `:dark` (default) and
  `:light` as explicit overrides. Frame light as a **readability/accessibility** choice
  (small dense audit text; ~30–50% of users have astigmatism), **NOT** a medical
  eye-strain claim (per 165 research lessons). Reuse the settled precedent phrasing:
  *"Dark stays the default and the brand; `:system` becomes the documented daytime-use
  recommendation."*

### Docs surface & doc-contract lock (EVID-02 part 2)
- **D-05: Keep the canonical mount snippet dark-default; document `theme:` separately,
  lock with a new literal-pin test.** Do NOT add `theme:` to the marked
  `# doc: start: operator-surface-mount` snippet — it is the dark-default adopter
  example and 3 existing snippet doc-contract tests
  (`getting_started_saas_doc_contract_test.exs`, `example_phoenix_readme_contract_test.exs`,
  `example_phoenix_schemas_mount_contract_test.exs`) assert it verbatim; mutating it
  would churn those docs and contradict "dark is the default." Instead:
  - Add a **"Theme" subsection** to `guides/operator-surface.md` (near the 1-Minute
    Mount / options area) documenting `theme:` (`:dark` default | `:light` | `:system`),
    what each renders, and the D-04 `:system` daytime recommendation.
  - Add a **one-line `theme: :system` pointer** to an adopter-facing doc (README's
    existing "dark, branded admin surface" line ~126 is the natural spot) so "adopter-facing
    docs document the `theme:` option" is satisfied beyond the guide.
  - **Lock** with a NEW doc-contract test (literal-pin pattern matching the existing
    `operator_surface/*_doc_contract_test.exs` family — `String.contains?` on the guide)
    asserting the guide documents the `theme:` literal + `:dark`/`:light`/`:system` + the
    daytime recommendation.
  - The example app continues to **demonstrate `theme: :system`** via its env-gated e2e
    branch (`router.ex` `THREADLINE_E2E_THEME == "system"`), which the light screenshot
    lane exercises end-to-end — satisfying success-criterion-2 without changing the
    human-visible demo default (stays dark).

### Claude's Discretion
- Exact suffix-selection mechanism in `operator-screenshots.spec.ts` (env check
  `THREADLINE_E2E_THEME === "system"` vs `testInfo.project.name === "desktop-chromium-light"`),
  provided the dark lane keeps emitting `__default__` and the light lane emits `__light__`.
- Whether the light regression guard reuses the existing `operator-screenshot-regression.spec.ts`
  under the light project vs a parameterized variant, provided the same 5 screens are guarded
  and the lane stays CI-skipped.
- Exact heading/placement of the new "Theme" subsection in `guides/operator-surface.md`
  and the precise daytime-recommendation wording, provided it carries the D-04 framing
  (readability/accessibility, not medical) and the precedent one-liner.
- Exact form of the new doc-contract test (separate file vs assertions appended to an
  existing operator-surface doc-contract test), provided it pins the `theme:` literal +
  all three values + the daytime recommendation and matches the literal-pin pattern.

### Reviewed Todos (not folded)
The `todo.match-phase` matcher surfaced the same 3 operator-surface seeds Phase 168
already reviewed-and-deferred (keyword overlap "light/phase/167/mode") — none are
screenshots/docs scope:
- `coverage-schema-card-declutter.md` — structural UI de-clutter; future polish phase.
- `theme-picker-idiomatic-ui.md` (`THEME-TOGGLE-01`) — blocked by the [165-01] theme-toggle
  ban; demand-gated.
- `transaction-page-left-push-desktop.md` — theme-independent desktop layout bug; not
  evidence/docs work.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope & Requirements
- `.planning/ROADMAP.md` §"Phase 169: screenshots-example-docs" — goal, EVID-01/EVID-02,
  3 success criteria, dependency (167, overlaps 168), execution order.
- `.planning/REQUIREMENTS.md` — EVID-01, EVID-02 definitions (lines 34–35).
- `.planning/STATE.md` — decision [165-01] (dark default/brand-primary; light/system via
  host `theme:` config; no runtime toggle; theme-toggle ban); v1.36 continuity; the
  standing nav-overhaul caution.

### Light-mode strategy & daytime-recommendation precedent
- `.planning/milestones/v1.35-phases/165-light-mode-strategy/165-LIGHT-MODE-RECOMMENDATION.md`
  — the formal adopter messaging: `:system` as the documented daytime-use recommendation
  (lines 36, 40–42, 67); the "readability/accessibility not medical" framing source.

### Screenshot lane — source contracts (the files this phase wires)
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` — durable capture;
  `durableScreenshotNames` (12 screens, lines 10–23); `__default__` suffix + viewport
  gating (lines 41–62); `OPERATOR_SCREENSHOT_DIR`. **This is where the `__light__` suffix
  and light viewport mapping land.**
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` — curated
  5-screen `toHaveScreenshot` regression guard; CI-skip (`!!process.env.CI`, the cf0e8e2
  local-only posture). The light regression mirror is added here.
- `examples/threadline_phoenix/e2e/playwright.config.ts` — Playwright projects;
  `desktop-chromium-light` (lines ~13, 19–31) currently `testMatch`-scoped to
  `operator-accessibility.spec.ts` only. **Widen its testMatch to include the screenshots
  spec.** Snapshot path template (line ~37).
- `examples/threadline_phoenix/e2e/run-e2e.sh` — `THREADLINE_E2E_THEME=system` gate +
  router recompile (lines ~94–99, 152–159); targets `--project=desktop-chromium-light`.
- `mix.exs` — `verify.example_browser` (dark) / `verify.example_browser_light` (light,
  sets `THREADLINE_E2E_THEME=system`) aliases (lines ~87–88, 145–186); `ci.all` includes
  only the dark alias (light is opt-in/local).

### Theme option — implementation truth (for accurate docs)
- `lib/threadline/operator_surface/router.ex` — `theme:` acceptance + compile-time
  validation `:dark | :light | :system`, default `:dark` (lines ~52–72).
- `lib/threadline/operator_surface/auth.ex` — `normalize_theme/1` → `data-tl-theme`
  socket assign (lines ~14, 177–179).
- `lib/threadline/operator_surface/style.ex` — dark base (`:178`), `[data-tl-theme="light"]`
  lane (`:188–237`), `@media (prefers-color-scheme: light) [data-tl-theme="system"]`
  branch (`:239–289`). Confirms `:system` = OS-auto, `:light` = forced, `:dark` = default.

### Docs + doc-contract mechanism (the lock this phase adds)
- `guides/operator-surface.md` — target adopter guide; currently has **no** `theme:`/dark/
  light/`:system` mention. 1-Minute Mount section (lines ~12–53) is where the new "Theme"
  subsection slots.
- `README.md` — adopter-facing; "dark, branded admin surface" line (~126) is the spot for
  the one-line `:system` daytime pointer; mount snippet (~140–156).
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — the
  `# doc: start: operator-surface-mount` marked snippet (dark-default, ~198–218) that MUST
  stay clean; the separate `THREADLINE_E2E_THEME == "system"` `:system` mount branch
  (~177–195) that demonstrates the option for e2e.
- `test/support/getting_started_fixtures.ex` — `extract!/2` doc-contract snippet-extraction
  mechanism (`# doc: start:`/`# doc: end:` + normalized assertion).
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` and
  `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` — the literal-pin
  doc-contract pattern to mirror for the new `theme:` lock.
- `test/threadline/getting_started_saas_doc_contract_test.exs`,
  `test/threadline/example_phoenix_readme_contract_test.exs`,
  `test/threadline/example_phoenix_schemas_mount_contract_test.exs` — the 3 existing snippet
  tests that assert the canonical mount verbatim. **Do NOT churn these** (D-05).

### Prior-phase context (carried forward)
- `.planning/phases/168-accessibility-verification/168-CONTEXT.md` — D-01 colorScheme:light
  precedent; the deferred handoff explicitly naming this phase's `__light__` lane +
  example-app `:system` demonstration; the nav-overhaul caution; the same 3 reviewed todos.
- `.planning/phases/167-component-retune/167-UI-SPEC.md` / `LIGHT-REVIEW.md` — the
  human-reviewed light lane this phase screenshots (no re-derivation).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`desktop-chromium-light` Playwright project + `THREADLINE_E2E_THEME=system` gate +
  `mix verify.example_browser_light`** (Phase 168) — the entire light render path already
  exists; EVID-01 only widens its `testMatch` and adds the `__light__` suffix. No new
  example-app mount, no new mix alias needed.
- **`operator-screenshots.spec.ts` durable-capture harness** — the `__default__`/viewport
  naming + `OPERATOR_SCREENSHOT_DIR` gating is the single chokepoint to teach `__light__`.
- **`operator-screenshot-regression.spec.ts` 5-screen guard + masks** — reusable verbatim
  under the light project for the light regression mirror.
- **Doc-contract harness** — `GettingStartedFixtures.extract!/2` (snippet) + the
  `operator_surface/*_doc_contract_test.exs` literal-pin family give a ready pattern to lock
  the `theme:` literal without inventing test infrastructure.

### Established Patterns
- **Local-only visual lane** (cf0e8e2): screenshot/regression baselines are CI-skipped
  (platform-sensitive); the light lane inherits this — no CI cost, no CI baseline churn.
- **Compile-time theme gating** (168): the example router selects the lane via
  `System.get_env("THREADLINE_E2E_THEME")` at compile time + `run-e2e.sh` forced recompile;
  the light screenshot run rides the same gate.
- **Doc-contract literal-pin** (coverage/timeline/policy/exports doc-contract tests): assert
  exact strings present in source/guides via `String.contains?` — the model for the `theme:`
  lock.

### Integration Points
- All light render plumbing is in the **example app e2e layer + `mix.exs` aliases**; the
  only library-side touch is documentation (`guides/operator-surface.md`) + a new test.
  `style.ex`/`router.ex`/`auth.ex` are **read-only references** here (no source edits — the
  token lane and theme option already exist and are locked).

</code_context>

<specifics>
## Specific Ideas

- The example app's **human-visible demo default stays dark**; `:system` is exercised only
  through the env-gated e2e/screenshot lane. This keeps the demo's headline behavior
  unchanged while still demonstrating the option (success-criterion-2) and producing the
  light evidence (EVID-01).
- The daytime recommendation must reuse the **settled precedent phrasing** and frame light
  as readability/accessibility — never a medical eye-strain claim (165 lessons explicitly
  warn the eye-strain evidence is softer than the readability evidence).
- The new `theme:` doc lock is **additive** — it must not modify the 3 existing snippet
  doc-contract tests or the canonical dark-default mount snippet.

</specifics>

<deferred>
## Deferred Ideas

- **Mobile-light screenshot lane** (`mobile-chromium-light` project, 12 screens × 375 in
  light) — deferred; 168 already proved responsive layout is mode-independent. Revisit only
  if a light-specific mobile regression surfaces.
- **Rename `__default__` → `__dark__`** for dark/light naming symmetry — deferred until a
  real multi-mode-CI demand makes the 48-baseline churn worthwhile.
- **Brandbook `tokens.json`/`tokens.css` 45-token parity + the settled-truth "UI theming
  posture" note (dark-primary, light supported via host config)** — **Phase 170**
  (BRAND-01/BRAND-02).

### Reviewed Todos (not folded)
- `coverage-schema-card-declutter.md` — structural UI de-clutter; not evidence/docs scope.
- `theme-picker-idiomatic-ui.md` (`THEME-TOGGLE-01`) — blocked by the [165-01] theme-toggle
  ban; demand-gated, not this phase.
- `transaction-page-left-push-desktop.md` — theme-independent desktop layout bug; not
  evidence/docs scope.

</deferred>

---

*Phase: 169-screenshots-example-docs*
*Context gathered: 2026-06-14*
