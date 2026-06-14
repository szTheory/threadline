---
phase: 168-accessibility-verification
plan: 02
subsystem: testing
tags: [accessibility, e2e, playwright, light-mode, operator-surface, color-scheme]

# Dependency graph
requires:
  - phase: 166-light-token-lane
    provides: 45-token dual-lane (light root + system @media branch) + data-tl-theme mechanism
  - phase: 168-accessibility-verification (plan 01)
    provides: source-first proof the light/system token math clears AA (this plan proves the runtime affordances render correctly under the light lane)
provides:
  - Env-gated example operator mount theme (THREADLINE_E2E_THEME -> :system | default :dark) via compile-time if/else
  - desktop-chromium-light Playwright project (colorScheme "light") re-running operator-accessibility.spec.ts verbatim
  - run-e2e.sh recompile guard so the compile-time theme gate reflects each invocation
affects: [169-appearance-proof, accessibility, e2e]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Compile-time env gate selecting a literal :theme atom (macro requires literal + single mount)"
    - "Surgical git apply --cached to commit one hunk of a file with unrelated uncommitted changes"
    - "Playwright colorScheme emulation re-running an existing spec verbatim across a second project"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - examples/threadline_phoenix/e2e/run-e2e.sh

key-decisions:
  - "D-01 reconciled via RESEARCH option 3 (env-gate), but implemented as a COMPILE-TIME if/else rather than a runtime expression: the threadline_operator_surface macro validates `theme` as a literal atom (router.ex:67) and reserves the :threadline live_session/pipeline (one mount per router), so a runtime System.get_env value or a second mount cannot compile. The env selects which single branch compiles."
  - "Default lane stays :dark (no env) — existing dark e2e/demo behavior byte-unchanged; :system only when THREADLINE_E2E_THEME=system. No Phase-169 bleed (default not flipped)."
  - "Doc-marked operator-surface-mount snippet kept token-identical inside the else branch; the 3 mount-snippet doc-contract tests normalize whitespace, so the re-indentation is invisible to them (verified: 19 doc-contract tests green)."
  - "run-e2e.sh touches router.ex before mix compile because System.get_env at compile time is NOT tracked as a recompilation trigger — without the touch, switching dark<->light lanes would reuse a stale compiled router."
  - "Mount kept inside the existing [:browser, :operator_browser, :operator_auth] pipeline — no new unauthenticated route (T-168-02)."
  - "Committed via surgical `git apply --cached` of only the mount hunk: the user's uncommitted nav-overhaul auth refactor in the same router.ex file was NOT staged or modified (standing caution honored)."

requirements: [A11Y-02]
status: complete
---

# 168-02 — Light-lane e2e affordance proof (A11Y-02 part 2)

## What was built

Plan 01 proved the token **math** is accessible in both lanes (source-first). This plan proves
the **affordances actually render** correctly when the operator surface is served in the light lane.

1. **Env-gated mount theme** (`router.ex`, Task 1). The example `/audit` operator mount now selects
   its theme lane at compile time:
   - no env → `:dark` (unchanged default),
   - `THREADLINE_E2E_THEME=system` → `:system` (light branch under `prefers-color-scheme: light`).

   Mechanism: a compile-time `if/else` — because the mount macro requires a **literal** `:theme`
   atom (`router.ex:67`) and reserves the `:threadline` live_session/pipeline (one mount per router),
   neither a runtime expression nor a second mount can compile. Only the env-selected branch's route
   registration executes.

2. **Light Playwright project** (`playwright.config.ts`, Task 2). `desktop-chromium-light`
   (`colorScheme: "light"`) re-runs the existing `operator-accessibility.spec.ts` **verbatim** — no
   forked spec, no new assertions.

3. **Recompile guard** (`run-e2e.sh`). Touches `router.ex` before `mix compile` so the compile-time
   `THREADLINE_E2E_THEME` gate reflects each invocation (the OS-env read is not a mix recompile
   trigger).

## Verification

- **Both lanes compile** under `mix compile --force --warnings-as-errors`: default `:dark` and
  `THREADLINE_E2E_THEME=system` → `:system` (the literal-atom macro gate accepts both branches).
- **Affordance suite green under light** — `desktop-chromium-light` ran `operator-accessibility.spec.ts`:
  **4 passed** (focus box-shadow ≠ none; skip link / nav `aria-current`; Timeline filters + Actor
  segments + Retention danger `data-confirm`; row-history dialog `aria-modal` + visible focus; chip
  border non-`0px`/non-`none`). No horizontal overflow.
- **Pitfall-1 false-pass DEFEATED** (throwaway probe, then deleted): served root computed
  `data-tl-theme="system"`, `background = rgb(247,249,252)` (`#F7F9FC`, the **light** `bg` token —
  dark would be `#0B1020`), `color = rgb(15,23,40)` (`#0F1728` dark ink on light). The surface was
  genuinely light, not a dark default that happened to pass.
- **Doc-contract tests green** — 19 tests across the 3 mount-snippet contracts
  (`example_phoenix_schemas_mount_contract_test`, `example_phoenix_readme_contract_test`,
  `getting_started_saas_doc_contract_test`) + the fixtures test pass; the `if/else` re-indentation is
  invisible to their whitespace-normalizing matchers.

## Standing-caution compliance (nav-overhaul lane)

- `router.ex` carried the user's uncommitted nav auth-refactor. Only the operator-mount hunk was
  staged (surgical `git apply --cached`); the nav refactor and untracked `error_html.ex` remain
  uncommitted and byte-unchanged. `playwright.config.ts` and `run-e2e.sh` were clean before this plan.
- `operator-accessibility.spec.ts` (nav-modified) was **re-run verbatim**, never edited.

## Commits

- `6c2645d` feat(168-02): env-gate example operator mount theme for light-lane e2e
- `addb70e` test(168-02): add colorScheme light Playwright project + recompile guard

## Notes / residual

- The `colorScheme: "light"` project is wired in `playwright.config.ts` but is only meaningful when
  paired with `THREADLINE_E2E_THEME=system` (so the mount serves `:system`). The CI/`mix verify.example_browser`
  invocation for the light lane must export that env (the recompile guard then makes it take effect).
- Phase 169 owns the appearance/screenshot proof and the user-facing `theme: :system` demonstration
  lane — explicitly out of scope here (behavior/affordance proof only).
- The 3 pre-existing nav-lane e2e failures are unrelated to this plan and were not touched.

## Self-Check: PASSED
