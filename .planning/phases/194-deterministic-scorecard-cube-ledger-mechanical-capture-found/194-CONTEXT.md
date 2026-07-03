# Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation - Context

**Gathered:** 2026-07-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the shipped design-system ledger (`.planning/design-system-ledger.json`, guarded by `test/threadline/operator_surface/stress_ledger_test.exs`) from a single opaque score per entry into an independently-ratcheted `page × persona × lens` **scorecard cube**; land **deterministic mechanical checkers** as the ratchet floor; and build a **tiered Playwright capture lane** emitting per-cell evidence bundles from `/audit/__stress`. The entire deterministic spine runs inside `mix ci.all` with **no LLM and no network**, so any nondeterministic score producer built later (Phase 195+) can never precede or corrupt the guard.

**Requirements:** LEDGER-01..05, MECH-01..05 (see `.planning/REQUIREMENTS.md`).

**In scope:** the cube schema + per-lens monotonicity guard + evidence-referenced bumps; the 9-metric deterministic checker set; the tiered capture matrix + evidence-bundle emission; the `DESIGN-SYSTEM.md` per-lens projection.

**Out of scope (later phases):** the Claude-vision critic runner/panel + golden set (195); the forward-only net-positive gate + auto-apply + first proven improvement (196); coverage growth + adversarial closeout + debt register (197). No LLM call, no network, no root runtime dependency, no public component API — all invariants below hold.

**Locked milestone invariants (do not revisit):** No root `mix.exs` runtime dep (Anthropic SDK is an `e2e` devDependency only; `verify.compile_no_optional` still proves `threadline` stays Phoenix-optional). No public component / "design-eval" API — dev/maintainer tooling only. Dev/test-only, fail-closed harness (`/audit/__stress` raises in `:prod`). LLM calls excluded from `mix ci.all`. Capture/query/auth semantics untouched. No external SaaS visual-diff tool names in committed ledger copy (`@forbidden_terms`: Chromatic/Percy/Applitools/Lost Pixel, `PhoenixStorybook`, `Tailwind`, `immutable ledger`). SCOPE-1: prove the harness by improving the 2–3 lowest-scoring pages, not a full 11-page sweep. Reference bar: **Linear (primary)** + Vercel/Stripe/Grafana (secondary/cautionary).

</domain>

<decisions>
## Implementation Decisions

These 4 decisions were synthesized from parallel research (see DISCUSSION-LOG.md) and locked as one internally-consistent set. The **coherence spine**: `page × persona × lens` is the *scoring* cube; `page × state × breakpoint × theme` is the *capture* matrix. **Persona and lens are judgments over the same captured pixels — they never multiply the capture matrix.** Mechanical checkers are persona-invariant and attach to the `(page × lens)` face. Every score is earned against committed evidence; the headline number is a recomputed `min()` so nothing can be averaged away or hand-faked.

### D-01: Lens taxonomy — 6 frozen lenses
- **The committed lens vocabulary (cube's 3rd axis), in this fixed order:** `hierarchy` · `density` · `rhythm` · `typography` · `color_contrast` · `brand_fidelity`. JSON keys are stable snake_case strings; the Elixir SSOT is `@lenses ~w(hierarchy density rhythm typography color_contrast brand_fidelity)a` (atoms internally, strings at the JSON boundary).
- **Persona-weighted lenses (stored per P1–P5):** `hierarchy`, `density` — the two dimensions where "what's good" genuinely changes by JTBD (P1 change/actor-first; P3 verdict-first; P2 plain/low-density; etc.).
- **Persona-invariant lenses (stored once at `persona: "all"`):** `rhythm`, `typography`, `color_contrast`, `brand_fidelity`.
- **Result: 14 lens-cells per page, not 30** (sparse cube). Making the invariant lenses per-persona would 5×-duplicate identical scores.
- **Craft / polish / aesthetics is deliberately NOT a lens** — it's emergent from the specific lenses. An un-anchorable catch-all dimension is the #1 rubric-bloat footgun.
- Each lens carries a `method` tag: `hierarchy` = **critic-only** (no mechanical floor); `density`/`rhythm`/`typography`/`color_contrast` = `mechanical+critic`; `brand_fidelity` = `mechanical-veto+critic`.
- **Critics ≠ lenses.** The 7 Phase-195 critics map ONTO the 6 lenses (commit this matrix so 195 rubric authors don't invent a parallel vocabulary): persona critics P1–P5 → score `hierarchy`+`density`; graphic-design critic → `rhythm`/`typography`/`color_contrast`; brand-veto critic → `brand_fidelity`. **Persona is a weight, never a lens ×5 multiplier.**
- The 6-lens vocabulary is **frozen** behind a dimension-drift guard: adding/removing a lens later is a human-ratified score-bar change (ties to GATE-04).

### D-02: Cube migration & floor seeding
- **Migration — versioned in-place redefinition (`version` 1 → 2), NOT parallel-additive, NOT scalar-dropping full-replace.** Keep the `current_score` / `ratchet_score` / `target_score` field *names* but redefine them as **guard-recomputed `min()` rollups** over a new sparse per-cell `scores` map. Add a top-level `cube_axes` block declaring personas + lens metadata (`slug`, `method`/`kind`, `authority`, reference `anchor`). Preserve the old opaque number only as `legacy_score` provenance. **One source of truth (the cells); the scalar cannot be hand-edited to fake progress — the guard recomputes and asserts it.** `min()` (not mean) is the anti-Goodhart aggregate: an entry is only as good as its weakest lens.
- **Cell keys — compound `persona.lens` dotted strings** (mirrors the existing `page.home.happy` ID idiom); guard iterates a flat sorted-key map (no recursion). Sparsity by **omission** — a cell exists iff the capture matrix declares `(page, persona, lens)` applicable; the guard cross-checks presence against `cube_axes` + the capture matrix so omission is audited, not silent.
- **Seeding — conservative "unrated".** Every newly-split cell is born `current: null, floor: 0, status: "unrated"`. The opaque pre-cube score is **NEVER propagated into any cell floor** (that would be an un-earned baseline that makes the first honest critic measurement register as an illegal monotonicity *drop*). Real scores are earned: `current > floor` requires a present, `File.exists?`-true `evidence_ref` (LEDGER-03, betterer-style); floor bumps for judged lenses require Phase-196 human sign-off recorded in an append-only `ratchet.signoffs` block. Hand-labeling is reserved for the golden/held-out anchors only (Phase 195).
- **Guard invariants (all at-rest, pure Elixir, `async: true`, no LLM/no network — LEDGER-05):** (1) rollup integrity — recomputed `min()` equals stored scalar; (2) per-cell monotonicity `cell.current >= cell.floor` unless the compound key is in `ratchet.resets` with `reset_rationale`; (3) evidence-on-gain; (4) axis validity against `cube_axes`; (5) floor-bump authority — mechanical/`auto` lenses may ratchet in CI, judged/`signoff` lenses may not.
- **Projection (LEDGER-04):** `DESIGN-SYSTEM.md` regenerates as one row per `(entry × persona)`, one column per lens, rollup scalar as a leading column; unrated cells render `—`; freshness-tested per present cell (same "row is substring of markdown" mechanic as today). Fixed column order = the lens order in D-01; never sort dynamically.

### D-03: Capture matrix (Tier A) & evidence storage
- **Tier A matrix — smoke-wide / deep-narrow ≈ 120 cells.** Band 1 (floor smoke): **all 11 pages × `happy` × 3 breakpoints × 2 themes = 66 cells** — a cheap mechanical floor on every page so a shared-token regression anywhere is caught. Band 2 (deep): **the 3 lowest-scoring target pages × {empty, error, permission-denied} × 3 bp × 2 themes = 54 cells** — depth only where SCOPE-1 improvement happens.
- **Breakpoints:** mobile **375** / tablet **768** / desktop **1280** px (≥3 points required for the scroll-cost curve). 320 kept as a cheap overflow-only assertion, not a bundle cell; 1440 dropped (redundant with 1280). Note: 3 existing Tier C baselines are 1024 — either one-time rebaseline to 1280 or keep 1024 for those 3 only (planner's call).
- **Themes: dark + light, both, non-negotiable** — MECH-02 WCAG contrast is defined dark+light; light was seeded v1.36.
- **Growth path:** Phase 197 promotes Band 2 to all 7 states and expands the deep band to the next-lowest pages. Full 11×7 sweep stays deferred.
- **Evidence storage — `evidence_ref` points to a small COMMITTED, diffable artifact, never a binary.** Commit per-cell **scorecard JSON** (`.planning/scorecards/<cell-id>.json`: computed mechanical metrics + a11y summary counts + resolved `--tl-*` token snapshot + meta) and, for the deep band, **aria-snapshot YAML** (`<cell-id>.aria.yml` via `locator.ariaSnapshot()`). **Gitignore + deterministically regenerate** all full-res PNG / DOM HTML / raw a11y JSON binaries (live under a gitignored `examples/threadline_phoenix/e2e/artifacts/tier-a/<cell-id>/`). Determinism holds because fixtures are DB-free + `reducedMotion:reduce` + masked dynamics + `scale:"css"` + **`deviceScaleFactor:1`** → byte-stable.
- **Pixel-diff stays at the existing tiny Tier C allowlist** (advisory; a baseline refresh requires the new render to pass semantic guards first — GATE-05). **Plain git, no LFS.**
- **Cell-id = `{ledger_id}__{theme}-{breakpoint}`** (e.g. `page.timeline.empty__dark-1280`), reusing the existing `stress-<slug>-<theme>-<viewport>` convention. `evidence_ref` value = repo-relative path resolving like the existing `desktopSnapshotPath()` helper.
- **Regeneration entrypoint:** `mix verify.capture` → `npm run capture:tier-a` regenerates the gitignored bundle identically; a `--update` flag rewrites committed scorecards as a *separate, reviewed* commit (never auto-"regenerate to green").

### D-04: Mechanical gate policy — two modes (both satisfy MECH-03)
- **Do NOT frame as "hard-blocker vs advisory."** Frame as two gate MODES; "advisory" never means "ignored" (that violates MECH-03), and heuristics never hard-fail on an arbitrary *universal* number (the false-positive fatigue that gets gates disabled).
- **MODE A — absolute hard blocker (spec/SSOT threshold, identical everywhere, auto-fixable):** WCAG contrast (text **4.5:1**, large ≥24px/≥18.66px-bold **3:1**, non-text/UI **3:1**, **dark + light independently**) + token-grid / spacing-on-scale / radius / shadow / motion **conformance** against `style.ex`. A violation fails `mix ci.all` outright. **This set == the exact Phase-196 auto-apply whitelist** (checker emits the fix — nearest token / nearest scale step / nearest passing-contrast token / strip off-grid px).
- **MODE B — ratchet-floor hard gate (threshold = the page's own committed current-state floor, tighten-only):** type-size count, interactive-control count, card-nesting depth, scroll-cost/breakpoint, distinct-accent-hue. Regression *below the committed floor* fails CI; "bad but not worse" passes and feeds the lens score for the critic to push down over time. The two structural ones (**card-nesting depth**, **distinct-accent-hue**) also carry a far brand-anchored **absolute ceiling (>3)** where no legit `/audit` layout lands. Not auto-fixed (structural — needs critic + human).
- **Threshold provenance:** MODE A = **LOCKED spec constants** (WCAG ratios; `--tl-*` token sets from `style.ex`) — immutable, pinned by a meta-test (extends `brandbook_token_parity` idiom); may never be loosened. MODE B = **RATCHET floors** in a new `mechanical_floors` block in `design-system-ledger.json`, monotonic via the existing guard (loosening needs `ratchet.resets` + `reset_rationale` + human sign-off). **Linear is the Phase-195 critic's reference bar, NEVER a committed CI number** (scraping it violates no-network + is Goodhart bait). The 2 far ceilings are the only hand-set values, justified by the brand book.
- **Mechanical → lens map (each mechanical output line is the deterministic evidence floor a lens score cites — CRITIC-05 substrate):** `rhythm` ← spacing/radius/shadow/motion conformance; `typography` ← type-size count (+ size-is-a-token conformance = MODE A); `color_contrast` ← WCAG (+ distinct-accent-hue); `density` ← interactive-control count / card-nesting depth / scroll-cost; `brand_fidelity` ← `--tl-*` token-parity **veto** (fires before aesthetic scoring, RUNNER-03); `hierarchy` ← no mechanical floor (critic-only).
- **Mechanical floors are persona-invariant** — they live on the `(page × lens)` face with theme/breakpoint as qualifiers, NOT persona-multiplied. Persona weighting is the critic's job (Phase 195).
- **Named entrypoint:** `mix verify.mechanical`, folded into `mix ci.all`. Reads the Tier-A evidence-bundle JSON (no browser at assert time). Every violation emits a **located, actionable, fix-carrying** message (selector + observed value + expected token + fix + `[metric · MODE]`).

### Claude's Discretion
- Exact JSON field spelling within a cell (beyond the locked shape), the precise `cube_axes` metadata keys, and test-name wording — planner/executor choose, consistent with the existing `stress_ledger_test.exs` style.
- Which 3 pages are the "lowest-scoring targets" for Band 2 — derive from the current ledger scores at plan time.
- Whether the 3 legacy 1024 Tier C baselines rebaseline to 1280 or stay 1024.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap (locked scope)
- `.planning/REQUIREMENTS.md` — LEDGER-01..05, MECH-01..05 (this phase); CRITIC/RUNNER/GATE/PROOF (downstream, for coherence).
- `.planning/ROADMAP.md` — Phase 194 goal + 4 success criteria; cross-cutting invariants; dependency spine; Phase 195/196 (GATE-02 auto-apply, GATE-03/04 guard-the-guards + held-out true-north) that this phase's decisions must stay coherent with.
- `.planning/PROJECT.md` — milestone goal, locked decisions, reference bar.
- `.planning/research/SUMMARY.md` — the "code computes the number, VLM judges the gestalt" split; `.planning/research/PITFALLS.md` and `.planning/research/FEATURES.md` if present (Goodhart, pixel-diff-advisory, severity model).

### The ledger + its guard (the artifact being extended)
- `.planning/design-system-ledger.json` — current flat schema (`version: 1`, 130 entries, dotted-key IDs) to migrate to `version: 2`.
- `test/threadline/operator_surface/stress_ledger_test.exs` — the current ratchet/projection-freshness guard to extend (monotonicity, exact key-set, sorted entries, `ratchet.resets` + `reset_rationale`, `locked_ids`, `minimum_scores`, forbidden terms).
- `DESIGN-SYSTEM.md` — the projection that must regenerate with per-lens columns.

### Tokens & brand anchors (mechanical thresholds source)
- `lib/threadline/operator_surface/style.ex` — the `--tl-*` token SSOT (spacing/type/radius/shadow/motion/accent sets) that MODE-A conformance checks against.
- `test/threadline/brandbook_token_parity_test.exs` — the LOCKED-constant meta-test idiom to reuse for threshold pinning.
- `brandbook/brand-book.md` — **current** brand book (radius ≤8px UI cap, "cards for repeated items not sections in cards", 5-accent "two blues two jobs" palette, "color as signal not decoration", 3:1 logo-arc floor) that anchors the MODE-B ceilings. **Prefer over `prompts/Threadline Brand Book.txt`.**

### Capture lane (the substrate to extend)
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` — existing capture spec (`desktopSnapshotPath`/`ciScreenshotAllowlist`/`dynamicMasks` helpers to reuse).
- `examples/threadline_phoenix/e2e/playwright.config.ts` — desktop project, light lane, `reducedMotion`.
- `lib/threadline/operator_surface/stress_fixtures.ex` + `lib/threadline/operator_surface/live/stress_live.ex` — the DB-free page/story/state surface driven by `/audit/__stress`.

### Engineering conventions
- `prompts/threadline-elixir-oss-dna.md` — named `mix verify.*`/`ci.*` entrypoints, honest-default tests, stable CI job IDs, doc-contract tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`stress_ledger_test.exs` guard mechanics** — monotonicity + `ratchet.resets`/`reset_rationale` + `locked_ids` + projection-freshness are extended, not replaced. The per-cell monotonicity + floor-bump-signoff logic reuses this exact shape.
- **`brandbook_token_parity_test.exs`** — the "value must equal `style.ex`" meta-test idiom is the template for pinning MODE-A LOCKED thresholds.
- **Playwright helpers** in `operator-stress.spec.ts` (`desktopSnapshotPath`, `ciScreenshotAllowlist`, `dynamicMasks`, `OPERATOR_STRESS_SCREENSHOT_DIR` env) — reused by the Tier-A capture lane.
- **`/audit/__stress` + `StressFixtures`** — the DB-free static fixture surface (11 pages × 7 paths, 5 viewports, 3 themes already modeled) is the capture source; fail-closed in `:prod`.

### Established Patterns
- **Dotted-key IDs** (`page.home.happy`, `foundation.color`) — the `persona.lens` compound cell keys follow this grammar for least surprise.
- **Committed JSON ledger + markdown projection + freshness guard** — the cube keeps this exact pattern (small diffable text, git = history, `File.exists?` for evidence refs; no inlined blobs — respects the `immutable ledger` / no-external-blob `@forbidden_terms`).
- **Named `mix verify.*` entrypoints folded into `mix ci.all`** — new `verify.mechanical` and `verify.capture` follow suit.

### Integration Points
- New `cube_axes` + per-entry `scores` map + `legacy_score` + `mechanical_floors` + `ratchet.signoffs` blocks in `design-system-ledger.json`.
- New `.planning/scorecards/<cell-id>.json` + `.aria.yml` committed evidence targets; gitignored `examples/threadline_phoenix/e2e/artifacts/tier-a/`.
- `mix verify.mechanical` reads Tier-A bundle JSON; `mix verify.capture` wraps `npm run capture:tier-a`.

</code_context>

<specifics>
## Specific Ideas

- **Anti-Goodhart is load-bearing throughout:** `min()` rollup (not mean), conservative-unrated seeding (first honest measure is legal), evidence-on-gain, LOCKED-vs-RATCHET threshold tiers, guard-the-guards sign-off, and Linear-as-critic-reference-not-CI-number all compose into one stance — the metric starts honest and empty and every point is earned.
- **The capture/scoring separation is the key invariant:** persona × lens are judgments over the *same* captured pixels — one capture cell → many lens scores referencing the same `evidence_ref`. Never let persona/lens multiply the capture matrix.
- **Reference-anchoring rubric practice (adopt from UICrit/UIST 2024):** every finding cites a screenshot region / DOM selector or is discarded — the CRITIC-05 substrate the mechanical output lines provide.

</specifics>

<deferred>
## Deferred Ideas

- **Full 11-page × 7-state Tier A sweep** — deferred (FUT-01); Phase 197 grows coverage. Phase 194 stays smoke-wide/deep-narrow per SCOPE-1.
- **loading / pagination-boundary / advanced states in Tier A** — deferred to 197 (proven live by Tier B in the interim).
- **320 / 1440 breakpoints as full bundle cells** — deferred; 320 stays a cheap overflow-only assertion, add only if a scroll-cost regression demands it.
- **The Claude-vision critic panel, golden set, forward-only gate, and first proven improvement** — Phases 195–197 by design; Phase 194 builds only the deterministic spine that must precede any nondeterministic producer.

None of the above are scope creep — they are the explicitly-sequenced later phases of v1.40.

</deferred>

---

*Phase: 194-Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation*
*Context gathered: 2026-07-03*
