# Architecture: Automated UI/UX Evaluation & Forward-Only Iteration Harness (v1.40)

**Domain:** Adversarial multi-lens LLM critique + monotonic (forward-only) design-iteration loop for the `/audit` operator LiveView surface
**Researched:** 2026-07-02
**Confidence:** HIGH on repo substrate (direct inspection); MEDIUM-HIGH on the LLM-judge determinism design (cross-checked against current LLM-as-judge literature)

> Design goal: an example/dev-only harness that captures the current operator UI, runs an adversarial multi-lens Claude-vision critique, proposes a change, re-evaluates it, and lands the change **only if** the target score improves and **no** other page/persona/lens/accessibility/screenshot baseline regresses — all recorded in Threadline's existing scored ledger idiom. It must not touch capture/query/auth, must not add root runtime deps, must not create a public component API, and must keep LLM calls out of CI.

This report reads the existing substrate as the load-bearing constraint. The single most important finding: **almost every mechanical piece already exists** (scored ledger with an enforced monotonic ratchet, `/audit/__stress` fixture harness, Playwright dark/light lanes with committed snapshots, accessibility-tree evidence, DESIGN-SYSTEM.md projection, storybook lane). v1.40 is overwhelmingly an **integration + a thin new critic runner**, not a greenfield build. The temptation to build a parallel evaluation system must be resisted; the ratchet already exists and is guarded by `stress_ledger_test.exs`.

---

## Loop Components

The loop is **capture → critique → propose → re-evaluate → guard**. Concrete components, with what runs where:

### 1. Capture (Node/Playwright, extends existing lanes)
- **What:** Deterministic screenshots + accessibility-tree JSON + DOM/computed-style snapshots for every cell of the capture matrix (page × state × breakpoint × theme).
- **Where it runs:** The existing Playwright harness in `examples/threadline_phoenix/e2e/`, driven by `run-e2e.sh` which already boots `mix phx.server` (MIX_ENV=test, seeded via `mix demo.reset`/`mix demo.seed`), waits for readiness, and runs `playwright test`.
- **How:** Reuse `/audit/__stress?story=<id>&theme=<t>&viewport=<w>` — the `StressLive` surface already renders any ledger story deterministically with ugly-data fixtures (`stress_fixtures.ex`), masks dynamic content (`time`, `[data-dynamic="true"]`, `stress-run-id`), and runs with `reducedMotion: "reduce"`. Capture writes artifacts to a run directory (the existing `OPERATOR_STRESS_SCREENSHOT_DIR` env hook, `operator-stress.spec.ts:55`, is the exact pattern to generalize).
- **Output:** A `capture manifest` (JSON) listing every artifact path keyed by `{ledger_id, theme, viewport}`, plus the raw PNGs and a11y-tree JSON.

### 2. Critic runner (Node script calling Claude vision — NEW, the only substantial new code)
- **What:** For each capture cell (or each page-level composite), sends the screenshot(s) + a **locked rubric** + the accessibility-tree evidence to Claude vision, once per **lens/persona**, and parses a **structured JSON scorecard** back.
- **Where it runs:** `examples/threadline_phoenix/e2e/critic/` as a standalone Node/TypeScript script (sibling to `tests/`), invoked **locally / on-demand only** — never in CI (see Local-vs-CI Boundary). It reads the capture manifest, calls the Anthropic API, writes scorecards.
- **Lenses (adversarial, multi-lens):** each lens is a distinct rubric+system-prompt pair, e.g. `visual-hierarchy`, `information-density`, `accessibility-contrast`, `operator-task-efficiency`, `brand-consistency`, `error-state-clarity`. Personas (`admin`, `support`) select which pages/states are in-scope and which rubric weights apply.
- **Determinism controls (critical — see Ratchet Design):** temperature 0, locked/versioned rubric text, anchored scale (each 0–100 band has concrete evidence descriptors), **N-sample majority/median vote** per (cell × lens), and the model returns *evidence citations* (which DOM element / region drove the score), not just a number.
- **Output:** `scorecard.json` per (cell × lens × persona) with `{score, band, findings[], evidence_refs[], severity}`.

### 3. Proposer (human-in-the-loop + Claude, operating on `style.ex`/`ui.ex`)
- **What:** Turns ranked findings into a concrete source change. Because the design system is **source-first in `style.ex`** and guarded by `style_contract_test.exs`, proposals are edits to `style.ex`/`ui.ex`/presentation, not runtime tweaks.
- **Where it runs:** In the developer's normal editing loop (Claude Code / the maintainer). The harness does **not** auto-commit source changes. This respects the invariant that a human signs off on the score bump.
- **Output:** A working-tree diff to `lib/threadline/operator_surface/**`.

### 4. Re-evaluate (re-run Capture + Critic on the proposed tree)
- **What:** Same capture + critic pipeline on the changed tree, producing `after` scorecards.
- **Where:** Same lanes/scripts. Produces a `before/after` delta report.

### 5. Guard / ratchet updater (Elixir `mix` task + ExUnit contract — extends existing ledger)
- **What:** Compares `after` vs the committed ledger. Enforces: target score **improved**, and **no other** ledger entry, screenshot baseline, or accessibility assertion **regressed**. Only then does the maintainer bump `current_score`/`ratchet_score` in `.planning/design-system-ledger.json` (with the human sign-off note in `notes`).
- **Where it runs:** The **existing** `stress_ledger_test.exs` already enforces the monotonic ratchet, locked IDs, and minimum scores in pure Elixir with no LLM. v1.40 extends it with a "score bump requires evidence" assertion (score bump entries must reference a committed scorecard artifact). The screenshot regression guard (`operator-screenshot-regression.spec.ts`, local-only, CI-skipped) and the CI stress-allowlist screenshots (`operator-stress.spec.ts` reading `screenshot_allowlist.ci`) are the pixel guards. `mix ci.all` runs the deterministic guards.
- **Output:** Pass/fail; on pass, the maintainer commits the ledger bump + committed evidence artifacts as review evidence.

**Loop summary table:**

| Stage | Runtime | Location | New or reuse |
|---|---|---|---|
| Capture | Node/Playwright | `e2e/` (extends `operator-stress.spec.ts`) | Reuse + generalize |
| Critic | Node + Claude vision API | `e2e/critic/` (NEW) | **New (only substantial new code)** |
| Propose | Human + Claude Code | `lib/.../operator_surface/**` (`style.ex`/`ui.ex`) | Reuse source-first system |
| Re-evaluate | Node/Playwright + Claude | `e2e/` + `e2e/critic/` | Reuse |
| Guard | Elixir ExUnit + `mix` + Playwright pixel guard | `stress_ledger_test.exs`, `mix ci.*`, screenshot specs | Reuse + thin extension |

---

## Placement vs Invariants

The invariants force a clean split. The organizing rule: **anything that calls an LLM, or is nondeterministic, lives in `examples/threadline_phoenix/e2e/` and is never in `mix ci.all`. Anything deterministic and committed can live in the root but must be dev/test-gated exactly like the existing `__stress` route.**

| Piece | Placement | Rationale (invariant) |
|---|---|---|
| Capture matrix runner | `examples/threadline_phoenix/e2e/tests/` (extend `operator-stress.spec.ts`) | Node/Playwright is already example/dev-only; no root dep. |
| Critic runner (Claude vision) | `examples/threadline_phoenix/e2e/critic/` (NEW dir) | LLM calls must be local/on-demand, never CI, never a root dep. |
| Rubric definitions | Committed JSON/MD under `e2e/critic/rubrics/` **and** mirrored into `.planning/` for review provenance | Rubrics are the "locked" determinism anchor; version them like the ledger. |
| Scorecards / findings / before-after | Committed under `.planning/design-evidence/` (evidence idiom) | Committed review evidence, human-readable, matches ledger-projection pattern. |
| The scored ledger | `.planning/design-system-ledger.json` (EXISTING) | Already the SSOT; do not fork it. |
| Ratchet enforcement | `test/threadline/operator_surface/stress_ledger_test.exs` (EXISTING, extend) | Pure Elixir, deterministic, already in `mix test` → `ci.all`. |
| `/audit/__stress` route | `lib/threadline/operator_surface/stress_router.ex` (EXISTING) | Already dev/test-gated: `:prod` → CompileError, `:omit` supported. **The precedent for any new dev-only route.** |
| Stress fixtures | `lib/threadline/operator_surface/stress_fixtures.ex` (EXISTING, extend) | `@moduledoc false`, no public API; extend with new states/personas as private. |
| A new `mix` task (e.g. `mix threadline.design.ratchet`) | Root `mix.exs` alias, **dev/test env only**, deterministic (reads ledger + artifacts, no LLM) | Named `verify.*`/`ci.*` entrypoint convention; must not require LLM. |
| Claude API key / network | Only in `e2e/critic/` local runs | No network in CI guards; no secret in root. |

**What is a `mix` task vs Node script vs committed artifact:**
- **`mix` task (Elixir, deterministic):** ratchet verification, ledger↔fixture round-trip, DESIGN-SYSTEM.md projection freshness, "score bump has evidence" check. These join `mix verify.*` and run in `ci.all`.
- **Node script (nondeterministic / LLM / browser):** capture, critic vision calls, before/after diffing. These are invoked via `run-e2e.sh`-style wrappers and a new **local-only** `mix verify.design_critique` alias that shells to Node (mirroring `verify.operator_stress`) but is **excluded from `ci.all`** (like `verify.flake`).
- **Committed artifact:** the ledger, DESIGN-SYSTEM.md, rubric files, screenshot baselines, and the frozen scorecards/finding registers that justify each score bump.

---

## Reuse Map

Exact extension points — **reuse, do not reinvent**:

### Scored ledger — `.planning/design-system-ledger.json`
- Already has: `entries[]` with `current_score`/`target_score`/`ratchet_score`/`status`/`owner_phase`, a `ratchet` block (`locked_ids`, `minimum_scores`, `resets`), `ratchet_rule`, `required_inventory`, `screenshot_allowlist.{ci,local_review}`, `version`.
- **Extend with:** per-entry `lens_scores` (a sub-object of lens→score so a page's composite score and per-lens scores both ratchet), and a `persona` tag on page entries. Add `evidence_ref` pointing at the committed scorecard that justifies the current score. Keep the existing top-level key contract test (`@top_level_keys`) updated in lockstep.

### Ratchet enforcement — `test/threadline/operator_surface/stress_ledger_test.exs`
- Already enforces: upward-only scores unless an explicit `ratchet.resets` entry + `reset_rationale`; locked IDs present; `minimum_scores` floors; fixture round-trip; DESIGN-SYSTEM.md freshness per row; screenshot allowlist integrity; banned-term hygiene (it **forbids** `Chromatic`, `Percy`, `Applitools`, `PhoenixStorybook`, `Tailwind`, `immutable ledger` in the ledger/markdown — the v1.40 harness must stay first-party and not name external SaaS visual-diff tools in committed ledger copy).
- **Extend with:** (a) if `lens_scores` added, assert each lens is monotonic vs its ratchet; (b) assert any entry whose `current_score` rose since the prior commit carries an `evidence_ref` to a committed scorecard; (c) keep the `@forbidden_terms` list — do **not** introduce SaaS visual-diff tool names.

### `/audit/__stress` harness — `stress_router.ex` + `live/stress_live.ex` + `stress_fixtures.ex`
- Already: dev/test-gated macro (`:prod`→CompileError), URL-param driven (`story`, `theme`, `viewport`, `category`, `status`), renders any ledger story from fixtures, category/status/theme/viewport allowlists derived from `StressFixtures`.
- **Reuse as the capture source of truth.** The critic captures `/audit/__stress?story=…` cells. No new rendering surface needed. Add new persona/state fixtures to `stress_fixtures.ex` (private) if lenses need states not yet represented.

### Screenshot lanes — `operator-stress.spec.ts`, `operator-screenshot-regression.spec.ts`, `playwright.config.ts`
- Already: dark projects (`chromium`, `desktop-chromium` 1280×900, `mobile-chromium`/Pixel5) + conditional `desktop-chromium-light` when `THREADLINE_E2E_THEME=system`; committed snapshots under `*-snapshots/`; `maxDiffPixelRatio` + dynamic masks; CI-skipped platform-sensitive regression guard; a CI-safe allowlist lane reading `screenshot_allowlist.ci` from the ledger; `OPERATOR_STRESS_SCREENSHOT_DIR` for local evidence capture.
- **Reuse for capture + as the pixel regression guard.** The "no screenshot baseline regresses" half of the ratchet is *already implemented* — the critic just must not be allowed to land a change that fails these specs.

### Accessibility-tree evidence — `operator-accessibility.spec.ts`
- Already: a rendered-state coverage matrix (modal, drawer, dropdown, tabs, disclosure, combobox, error-summary, permission/unavailable/alert, stale/status, table/list, shell nav, mobile nav) exercised against `__stress` + live pages.
- **Reuse as the accessibility lens's deterministic ground truth.** The a11y lens should *combine* the deterministic axe/tree assertions (guard) with the LLM contrast/hierarchy critique (advisory). The deterministic half is the regression floor.

### DESIGN-SYSTEM.md projection
- Already: a deterministic table projection of the ledger, freshness-tested per row. **Reuse as the human-facing scorecard index.** Extend the projection generator to add a lens-score column and a "latest critique" link.

### PhoenixStorybook lane — `operator-storybook.spec.ts`, example router `/dev/storybook`
- Already: example/dev-only stories for private components; a bounded storybook smoke in the light lane.
- **Reuse as a secondary capture source** for component-level (not page-level) lenses. Optional; page/state cells via `__stress` are the primary matrix.

### `brandbook/tokens.{json,css}` parity
- Already: bidirectional parity test vs `style.ex` 45-token light lane. **Reuse as the brand-consistency lens's ground truth** — the LLM brand lens is advisory on top of the deterministic token parity guard.

### Mix aliases — `mix.exs`
- Already: `verify.operator_stress`, `verify.example_browser`, `verify.example_browser_light`, `verify.flake` (opt-in, excluded from `ci.all`), `verify.phase177_uat`. **The `verify.flake` pattern (defined, useful, deliberately not in `ci.all`) is the exact template** for a local-only `verify.design_critique`.

---

## Capture Matrix

Given the current inventory (from `required_inventory` in the ledger and the fixtures):

- **Pages (11):** `home`, `timeline`, `transaction`, `actor`, `row-history`, `coverage`, `redaction`, `retention`, `evidence`, `exports`, `shell`.
- **States (7 core, per `page.*.<state>` ledger cells):** `happy`, `empty`, `loading`, `error`, `permission`, `advanced`(dense), `boundary`. Plus the richer `state.*` fixtures (`many`, `null-fields`, `mixed-severity`, `timezone-boundary`, `pagination-boundary`, `stale-reconnecting`, `unavailable-*`) for stress lenses.
- **Breakpoints (5):** 320, 375, 768, 1024, 1440 (from `StressFixtures.viewports`; Playwright projects currently pin 1280/Pixel5 + 1024 snapshots).
- **Themes (2 primary, 3 total):** `dark` (default/brand-primary), `light`, `system`. Dark + light are the evaluation lanes; `system` is affordance-only (per `playwright.config.ts` comment).

**Full matrix = 11 × 7 × 5 × 2 ≈ 770 cells** — too large to LLM-critique every cell on every run. **Tiered strategy (mirrors the existing Tier A structural / Tier B sample / Tier C screenshot split already in the ledger notes):**

| Tier | Scope | Cadence | Guard type |
|---|---|---|---|
| **Tier A — structural** | All 770 cells rendered; deterministic checks only (no overflow, a11y tree, token parity, DOM contract) | Every `ci.all` (deterministic, no LLM) | Hard guard |
| **Tier B — LLM critique sample** | A curated per-page representative set: each page × {happy, one adverse state} × {dark, light} × {mobile 375, desktop 1024} ≈ 11×2×2×2 = 88 cells | Local/on-demand, per iteration | Advisory + score bump |
| **Tier C — pixel baseline** | The `screenshot_allowlist.ci` set (currently 3, expandable) | CI (allowlist) + local regression guard | Hard guard |

Start Tier B smaller: the existing `selectedTierCStressStories` (`page.home.happy`, `state.unavailable-down`, `state.permission-denied`, `state.pagination-boundary`) is the proven seed. Grow the LLM sample page-by-page as confidence in rubric stability grows.

---

## Forward-Only Ratchet Design

The ratchet **already exists and is enforced** (`stress_ledger_test.exs`): scores only rise unless an explicit `ratchet.resets` entry with `reset_rationale` is recorded; `locked_ids` can't vanish; `minimum_scores` are floors. v1.40 layers the *gate* on top.

### Gate: a proposed change lands only if ALL hold
1. **Target improves:** the targeted entry's `current_score` (and/or its targeted `lens_scores`) increases in the after-critique.
2. **No score regression anywhere:** every other entry's after-score ≥ its committed `ratchet_score` (existing ratchet test enforces the committed side; the critic's before/after report must show no other cell dropped a band).
3. **No pixel regression:** `operator-stress.spec.ts` allowlist screenshots + local `operator-screenshot-regression.spec.ts` pass.
4. **No accessibility regression:** `operator-accessibility.spec.ts` coverage matrix + axe assertions pass.
5. **Deterministic guards green:** `mix ci.all` (format, credo, `style_contract_test`, ledger test, doc-contract, example browser).
6. **Human sign-off:** the maintainer commits the ledger score bump with the evidence reference — the LLM never writes the ledger.

### Determinism strategy (LLM nondeterminism is the core risk)
The literature is unambiguous here and matches the harness's needs:
- **Temperature 0** for all scoring calls.
- **Locked, versioned rubrics** with **anchored scoring bands** — each 0–100 band defined by concrete, checkable evidence descriptors (not vague adjectives). This is the RULERS/"locked rubric + evidence-anchored" pattern. Store rubric text as committed files; a rubric change is a `ratchet.resets`-style event requiring rationale.
- **Evidence-grounded output:** the model must cite the region/DOM element driving each finding, so scores are auditable, not opaque.
- **N-sample majority/median vote** per (cell × lens): query the judge k times (e.g. k=3–5), take the median score / majority band. Self-consistency across samples is the reliability signal; if variance across samples exceeds a threshold, flag the cell as "unstable — do not ratchet" rather than trusting a single number.
- **Score bumps are quantized to bands** (e.g. 62→72→90 as the ledger already uses) not raw LLM integers, so sub-band LLM jitter never moves the ratchet.
- **The LLM is advisory; deterministic tests are authoritative.** No score bump lands without the deterministic guards passing. The LLM can *propose* a bump; humans + deterministic guards *ratify* it. This is the single most important architectural stance: **the nondeterministic critic can never regress the deterministic floor.**

This keeps the committed ledger a stable, monotonic, reviewable artifact even though an LLM informs it.

---

## Evidence / Artifact Model

Expressed in Threadline's existing ledger/evidence idiom (append-only, provenance-tagged, human-readable, committed as review evidence — the same philosophy as `Threadline.Evidence` and the DESIGN-SYSTEM.md projection):

| Artifact | Format | Location | Committed? |
|---|---|---|---|
| **Scorecard** (per cell × lens × persona) | JSON `{score, band, lens, persona, findings[], evidence_refs[], samples[], model, rubric_version}` | `.planning/design-evidence/<date>/scorecards/` | Yes (frozen review evidence) |
| **Ranked findings register** | Markdown table (severity-ranked, page-grouped) | `.planning/design-evidence/<date>/FINDINGS.md` | Yes |
| **Before/after screenshots** | PNG pairs | `.planning/design-evidence/<date>/before-after/` (or referenced from Playwright snapshots) | Yes for the sign-off set |
| **Design-debt register** | Markdown, mirrors ledger `status: reserved`/low-score entries with owner + reopen trigger (same shape as the v1.39 residual-risk register) | `.planning/design-evidence/DESIGN-DEBT.md` | Yes |
| **Scored ledger** | JSON | `.planning/design-system-ledger.json` (EXISTING) | Yes (SSOT) |
| **DESIGN-SYSTEM.md projection** | Markdown table | root (EXISTING) | Yes |
| **Rubrics** | JSON/MD, versioned | `e2e/critic/rubrics/` | Yes |
| **Raw capture manifest + PNGs + a11y trees** | JSON + PNG | run dir under `OPERATOR_STRESS_SCREENSHOT_DIR` | Only the sign-off subset; bulk is gitignored |

Provenance on every scorecard (`model`, `rubric_version`, `sample count`, `timestamp`) mirrors `Threadline.Evidence`'s stable-provenance discipline. The **design-debt register** reuses the exact "owner + reopen-trigger per item" pattern from the v1.39 phase-193 residual-risk register — a proven, in-repo idiom.

---

## Local-vs-CI Boundary

This is the invariant-defining line. **LLM calls are local/on-demand; only deterministic guards run in CI.**

### CI (`mix ci.all`, GitHub Actions) — deterministic only, no network, no LLM
- `verify.format`, `verify.credo`, `verify.compile_no_optional`, `verify.test` (includes `stress_ledger_test.exs` → the ratchet), `verify.threadline`, `verify.example`, `verify.doc_contract`, `verify.example_browser` (the CI screenshot allowlist lane reading `screenshot_allowlist.ci`, plus a11y coverage).
- **Add:** a deterministic `mix` verification that (a) ledger is monotonic + evidence-referenced, (b) DESIGN-SYSTEM.md fresh, (c) design-debt register consistent with ledger. Pure Elixir, no LLM.
- Stable job IDs preserved; expensive jobs still run on `main` even under path filters (existing convention).

### Local / on-demand only — never in CI
- `e2e/critic/` Claude-vision runner (needs `ANTHROPIC_API_KEY`, network, nondeterministic).
- A new `mix verify.design_critique` alias shelling to the Node critic — **defined but excluded from `ci.all`**, exactly like `verify.flake` and `verify.operator_stress`'s local-review posture.
- `operator-screenshot-regression.spec.ts` (already `test.skip(!!process.env.CI, …)` — platform-sensitive pixels stay local).

**The boundary in one sentence:** CI proves *nothing regressed* (pixels, a11y, ledger monotonicity, source contracts); the local LLM loop proposes *what to improve next* and produces the evidence that justifies a human-ratified score bump. CI never depends on an LLM being reachable or deterministic.

---

## Suggested Build Order (dependency-ordered)

Phase-shaped, with dependencies. Each phase is independently shippable and leaves the tree green.

**Phase A — Ledger schema extension for lenses + evidence (foundation).**
Extend `.planning/design-system-ledger.json` with `lens_scores`, `persona`, and `evidence_ref`; extend `stress_ledger_test.exs` to enforce lens monotonicity + "score bump needs evidence"; regenerate DESIGN-SYSTEM.md projection. Pure Elixir, deterministic, lands in `ci.all`.
*Depends on:* nothing. *Risk:* low. *Unblocks:* everything downstream that writes scores.

**Phase B — Capture matrix generalization (Node/Playwright).**
Generalize `operator-stress.spec.ts` capture to emit a full capture manifest (Tier A structural cells + a configurable Tier B sample) with a11y trees, driven by the existing `OPERATOR_STRESS_SCREENSHOT_DIR` hook and `run-e2e.sh`. No LLM yet.
*Depends on:* A (for cell IDs). *Risk:* low-med (matrix size / runtime — mitigate with tiering). *Unblocks:* C.

**Phase C — Rubrics + critic runner (the new code).**
Author locked, anchored, versioned rubrics per lens under `e2e/critic/rubrics/`; build the `e2e/critic/` Claude-vision runner with temperature 0, k-sample median vote, evidence-cited structured output, variance-flagging. Wire a local-only `mix verify.design_critique` (excluded from `ci.all`). Uses the current Claude vision model — **confirm exact model id / vision input format / pricing against the Claude API skill before coding, do not hardcode from memory.**
*Depends on:* A, B. *Risk:* med-high (LLM determinism — mitigated by the ratchet stance: advisory only). *Unblocks:* D, E.

**Phase D — Evidence & scorecard artifact model.**
Scorecard/findings/design-debt writers in the ledger/evidence idiom; before/after diff report; commit the sign-off evidence set. Extend DESIGN-SYSTEM.md projection with lens columns + latest-critique links.
*Depends on:* A, C. *Risk:* low. *Unblocks:* E.

**Phase E — Full loop + gate wiring + one proven iteration.**
Wire capture→critic→propose→re-evaluate→guard end to end; run one real iteration on the weakest page (lowest ledger score) to prove the gate: improve a target, show no regressions, ratify a human-signed score bump, land the evidence. Document the runbook.
*Depends on:* A–D. *Risk:* med (integration). *Unblocks:* routine use.

**Phase F — Coverage growth + closeout.**
Grow the Tier B LLM sample page-by-page from the seed set; add pages to the CI screenshot allowlist as they stabilize; residual design-debt register + reopen triggers; adversarial review that the loop can't regress the deterministic floor.
*Depends on:* E. *Risk:* low.

Ordering rationale: the **deterministic ledger/guard spine (A)** must exist before any nondeterministic producer, so the LLM can never precede the guard. Capture (B) precedes critic (C) because the critic consumes captures. Evidence (D) precedes the full gate (E) because the gate references committed evidence. Coverage growth (F) is deliberately last so rubric stability is proven on a small set first.

---

## Integration Risks

| Risk | Severity | Mitigation |
|---|---|---|
| **LLM nondeterminism corrupts the monotonic ledger** | High | LLM is strictly advisory; deterministic `stress_ledger_test.exs` + pixel/a11y guards are authoritative; score bumps are band-quantized, human-ratified, evidence-referenced, temperature 0, k-sample median. |
| **Capture matrix runtime explosion (770 cells × k samples × API cost)** | Med-High | Tiering: deterministic Tier A everywhere, LLM Tier B on a curated sample, pixel Tier C on the allowlist. Grow the sample incrementally. |
| **Accidental root runtime dep / public API creep** | High | All LLM/Node code stays in `examples/.../e2e/`; new routes/fixtures stay `@moduledoc false` + dev/test-gated exactly like `stress_router.ex`; no component API exported. `verify.compile_no_optional` still guards Phoenix-optional. |
| **CI depends on LLM/network** | High | `verify.design_critique` excluded from `ci.all` (the `verify.flake` precedent); CI screenshot lane reads only the committed `screenshot_allowlist.ci`. |
| **Ledger banned-term guard rejects committed copy** | Low | The existing `@forbidden_terms` bans naming external SaaS visual-diff tools and `immutable ledger` in ledger/markdown — keep critique copy first-party and avoid those terms. |
| **`style_contract_test.exs` / source-first design system fights proposals** | Med | Proposals edit `style.ex`/`ui.ex` source (the intended surface); the contract test is a *feature* here — it forces proposals through the guarded source, preventing runtime hacks. |
| **Rubric drift silently changes scores over time** | Med | Version rubrics; treat a rubric change as a `ratchet.resets`-class event with rationale; store `rubric_version` on every scorecard. |
| **`system` theme false-confidence** | Low | Follow the existing `playwright.config.ts` discipline: evaluate dark + light explicitly; treat `system` as affordance-only. |
| **Screenshot baselines platform-sensitive** | Med | Reuse the existing pattern: local regression guard is CI-skipped; only the stable allowlist runs in CI; masks for dynamic content already defined. |

---

## Key File References

- Ratchet/ledger SSOT: `.planning/design-system-ledger.json` (entries, `ratchet.{locked_ids,minimum_scores,resets}`, `ratchet_rule`, `required_inventory`, `screenshot_allowlist.{ci,local_review}`, `version`)
- Ratchet enforcement: `test/threadline/operator_surface/stress_ledger_test.exs` (monotonic scores, locked IDs, minimum scores, fixture round-trip, projection freshness, `@forbidden_terms`)
- Projection: `DESIGN-SYSTEM.md`
- Stress harness: `lib/threadline/operator_surface/stress_router.ex` (dev/test gate), `lib/threadline/operator_surface/live/stress_live.ex` (URL-param story/theme/viewport), `lib/threadline/operator_surface/stress_fixtures.ex` (fixtures, `@viewports`, `@theme_modes`, `@required_cases`)
- Design-system source: `lib/threadline/operator_surface/style.ex` (+ `style_contract_test.exs`), `lib/threadline/operator_surface/ui.ex`, `presentation.ex`
- Capture/guards: `examples/threadline_phoenix/e2e/playwright.config.ts` (dark projects + conditional light lane), `run-e2e.sh` (boot/seed/serve/run), `tests/operator-stress.spec.ts` (`OPERATOR_STRESS_SCREENSHOT_DIR`, ledger-driven allowlist, viewport list), `tests/operator-screenshot-regression.spec.ts` (CI-skipped pixel guard, masks), `tests/operator-accessibility.spec.ts` (rendered-state a11y coverage matrix), `tests/operator-storybook.spec.ts`
- Storybook lane: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (`/dev/storybook`, `threadline_operator_surface_stress("/__stress", …)`)
- Aliases: `mix.exs` (`verify.operator_stress`, `verify.example_browser{,_light}`, `verify.flake` [defined-but-excluded-from-`ci.all` precedent], `ci.all`)
- Token parity: `brandbook/tokens.{json,css}`
- Evidence-idiom precedents: `Threadline.Evidence` (append-only, provenance); v1.39 phase-193 residual-risk register (owner + reopen-trigger shape)

---

## Sources

- Repo inspection (HIGH confidence): all files above, read directly 2026-07-02.
- LLM-as-judge determinism (MEDIUM-HIGH, cross-checked): locked/anchored rubrics, evidence-grounded scoring, temperature 0, self-consistency / k-sample majority-median vote.
  - [Rulers: Locked Rubrics and Evidence-Anchored Scoring for Robust LLM Evaluation (arXiv)](https://arxiv.org/html/2601.08654v1)
  - [Rubric-Based Evaluations & LLM-as-a-Judge — Methodologies, Biases, and Empirical Validation (Adnan Masood)](https://medium.com/@adnanmasood/rubric-based-evals-llm-as-a-judge-methodologies-and-empirical-validation-in-domain-context-71936b989e80)
  - [Evaluating Scoring Bias in LLM-as-a-Judge (arXiv)](https://arxiv.org/html/2506.22316v2)
  - [LLM-as-a-Judge: How to Build Reliable, Scalable Evaluation (Comet)](https://www.comet.com/site/blog/llm-as-a-judge/)
