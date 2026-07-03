# Technology Stack — Automated Adversarial LLM UI/UX Critique & Forward-Only Iteration Harness

**Project:** Threadline v1.40 (operator surface `/audit`)
**Researched:** 2026-07-02
**Mode:** Ecosystem / STACK
**Overall confidence:** HIGH on the Claude API surface and the capture pipeline (verified against repo + the bundled `claude-api` reference); MEDIUM on the LLM-as-visual-judge reliability numbers (recent-but-academic sources) and on exact third-party dep versions (verify at install).

---

## TL;DR Recommendation

Build the critic loop as a **local/on-demand Node lane inside the existing `examples/threadline_phoenix/e2e/` toolchain**, not a new root dependency and not a blocking CI gate. Reuse the deterministic Playwright capture you already ship (screenshots × pages × states × breakpoints × themes), add DOM + accessibility-tree + design-token dumps to each captured "evidence bundle," and feed those bundles to **`claude-opus-4-8`** (vision) via the **`@anthropic-ai/sdk`** with **structured outputs (JSON-schema-constrained)**, **prompt caching** (stable rubric + few-shot anchors + tokens), and the **Message Batches API** for the full overnight matrix. One critic per persona/JTBD plus one dedicated graphic-design critic, each a versioned rubric. Aggregate N samples per bundle (self-consistency), write scored verdicts back into the **existing `.planning/design-system-ledger.json` ratchet**, and enforce forward-only via the existing `stress_ledger_test.exs`. Human confirms any score drop; the LLM never fails CI on its own.

This mirrors exactly how the repo already treats the dark/`__light__` screenshot lanes: **local-only, evidence-producing, ratchet-guarded — never a born-red gate.**

---

## Recommended Stack

### Model (the critic brain)

| Technology | Version / ID | Purpose | Why |
|------------|--------------|---------|-----|
| **Claude Opus 4.8** | `claude-opus-4-8` | Vision-capable design/UX critic | Most capable Opus-tier model; native vision; **1M-token context** (fits the whole rubric + anchor set + tokens + DOM + a11y tree + several screenshots in one call); **structured outputs GA**; **prompt caching**; **Batch API** support. Non-negotiable default per the `claude-api` skill. |
| (fallback for cost) | `claude-sonnet-4-6` | Cheaper pre-screen / triage pass | $3/$15 vs $5/$25 per MTok; use only if the matrix gets large and you want a coarse first pass. Keep the authoritative scoring on Opus 4.8 so ratchet numbers stay comparable across runs. |

**High-resolution vision matters here.** Opus 4.7+ raised the max image resolution to **2576px on the long edge** (up from 1568px), and returned coordinates map 1:1 to pixels — no scale-factor math. This is automatic on 4.8 (no beta header). It directly improves spacing-rhythm / alignment / typographic-scale judgments, which are exactly the graphic-design critic's job. Cost caveat: a full-res image can consume up to ~4784 image tokens (≈3× the old cap), so control image size deliberately (see Capture Pipeline).

**Determinism note (important):** on Opus 4.8 `temperature`, `top_p`, `top_k` are **removed** (they 400). You cannot "turn down temperature" for a more deterministic judge. Reproducibility therefore comes from: (1) JSON-schema-constrained output, (2) a frozen, versioned rubric + anchor prefix, (3) prompt caching keeping that prefix byte-identical, and (4) **self-consistency aggregation across N samples** rather than trusting a single call. See Reliability & Determinism.

### API features to use (all first-party Claude API)

| Feature | How | Why for this loop |
|---------|-----|-------------------|
| **Structured outputs** | `output_config: {format: {type:"json_schema", schema: RUBRIC_SCHEMA}}`, or `client.messages.parse()` with a Zod schema | Guarantees every critic returns the same machine-scorable shape (per-criterion score, evidence pointer, severity, suggested fix). GA on Opus 4.8. Eliminates parse/retry glue. Note: **incompatible with citations** and with assistant prefill — use system-prompt instructions, not prefill. |
| **Prompt caching** | `cache_control: {type:"ephemeral"}` on the last stable block (rubric + anchors + `brandbook/tokens.json` + the `style.ex` token/BEM contract) | The rubric+anchors+tokens prefix is identical for every page/state/theme in the matrix. Cache it once; each bundle only pays for the volatile suffix (its own screenshots + DOM + a11y). ~0.1× read cost. Order: `tools → system → messages`; keep volatile per-bundle content after the breakpoint. |
| **Message Batches** | `client.messages.batches.create([...])`, poll, key results by `custom_id` | The full matrix (11 pages × states × 2–3 breakpoints × 2 themes × N personas × N samples) is a large, non-latency-sensitive job — perfect for Batch (50% cheaper, runs async/overnight). Results are unordered → key by `custom_id = <bundle>__<persona>__<sample>`. |
| **Adaptive thinking** | `thinking: {type:"adaptive"}` (optionally `display:"summarized"` to capture the critic's reasoning as evidence) | Lets the model reason about visual hierarchy before scoring. `display:"summarized"` gives you a human-readable rationale to store alongside the score. |
| **Effort** | `output_config: {effort: "high"}` | A visual-judgment task is intelligence-sensitive; use `high` (or `xhigh` for the graphic-design critic). Don't default to `max` — diminishing returns and slower. |

### Invocation runtime (example/dev-only — NOT a root dep)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **`@anthropic-ai/sdk`** | latest `^0.9` (the release shipping `messages.parse` + `betaZodTool` + `scope_id`; ≥ 0.88) | TypeScript client for the critic runner | The `e2e/` lane is already Node/TypeScript. Reuse it. **Add it as a `devDependency` of `examples/threadline_phoenix/e2e/package.json` only** — never a root `mix.exs` dep; the root package must stay Phoenix-optional with no new runtime deps. Verify the exact current version at install. |
| **`zod`** | `^3` | Typed critic schema (drives structured outputs) | Define the rubric response schema once in Zod; the SDK converts it to the API's json_schema. Client-side validation catches drift. |
| **`@playwright/test`** | `^1.52.0` (already pinned) | Deterministic capture — already in the repo | No change. Reuse the existing `capture()` helper, projects, and `snapshotPathTemplate`. |
| **Node** | ≥ 20 LTS | Runtime for the critic script | Already required by Playwright. |

### Ledger / ratchet (already shipped — reuse, do not rebuild)

| Artifact | Role in v1.40 |
|----------|---------------|
| `.planning/design-system-ledger.json` | Extend each entry with `critic_scores` (per-persona + graphic-design) and a `rubric_version`. `current_score`/`ratchet_score` become LLM-fed. |
| `DESIGN-SYSTEM.md` | Stays the projected view; add critic columns. |
| `test/threadline/operator_surface/stress_ledger_test.exs` | The forward-only enforcer — extend to assert critic scores never regress below `ratchet_score` (with a noise band; see below). |
| `lib/threadline/operator_surface/live/stress_live.ex` + `stress_fixtures.ex` | The `/audit/__stress` fixtures are the **known-bad calibration anchors** (footguns already scored 25/35). Their target-90 fixed states are the **known-good anchors**. This is the single most valuable pre-existing asset for critic calibration. |

---

## Critic Invocation & Integration

**Recommended: a hybrid, with a Node runner as the workhorse and Claude Code subagents as the interactive lane.**

### Primary — Node critic runner in `e2e/critic/`, wrapped by a `mix verify.*` alias

Structure:

```
examples/threadline_phoenix/e2e/
  critic/
    rubrics/
      graphic-design.v1.json      # spacing rhythm, alignment, hierarchy,
                                  # typographic scale, density, elegance,
                                  # low-clunk/low-scroll, discoverability
      persona-<jtbd>.v1.json      # one per user persona/JTBD
    anchors/                      # few-shot known-good / known-bad bundles
    run-critics.ts                # reads evidence bundles -> Claude -> verdicts.json
    aggregate.ts                  # N-sample self-consistency -> scored ledger delta
```

- `run-critics.ts` uses `@anthropic-ai/sdk`, loads the frozen rubric + anchors + `brandbook/tokens.json` + the `style.ex` token/BEM contract as a **prompt-cached system prefix**, then submits one Batch request per (bundle × persona × sample).
- A thin alias — e.g. `mix verify.ui_critique` — shells out to the Node runner so it fits the project's "named entrypoints" DNA and is citable verbatim in docs. Per the OSS DNA, **document it as a local-only lane and explicitly keep it OUT of `mix ci.all`** (same posture as `mix verify.example_browser_light`). This preserves "honest default tests": nothing heavy or nondeterministic hides inside the default suite.
- Output is committed as `verdicts.json` + a ledger delta; a human reviews and applies the ratchet bump.

**Why a Node script and not a Mix task calling the API:** the capture pipeline, screenshot lanes, and a11y evidence are already Node/Playwright; the evidence bundles are produced there. Keeping the critic in the same process avoids a second HTTP client, a second auth path, and — critically — a **new Elixir runtime dependency in the root package.** An Elixir Mix task would force an HTTP/JSON client into a library that ships to Hex as Phoenix-optional. Reject that.

### Secondary — Claude Code subagents / slash-command for interactive iteration

For hands-on "improve this page now" loops, a Claude Code subagent can `Read` the committed PNGs (vision) + DOM + a11y JSON directly and critique against the same rubric files — zero infra, immediate feedback while editing `style.ex`/`ui.ex`. Use this for exploratory design passes; use the Node Batch runner for the reproducible, scored, ledger-updating matrix. Same rubric files feed both, so verdicts stay comparable.

### Why LLM calls stay LOCAL / on-demand (not a blocking CI gate)

1. **Nondeterminism.** No temperature control on Opus 4.8; even with schema + caching + aggregation there is residual variance. A born-red gate on a stochastic scorer produces flaky CI — the exact anti-pattern the repo's flake-detection DNA fights.
2. **Cost.** Every push would spend real API tokens across a large image matrix. The repo already keeps the screenshot lanes local-only for analogous reasons.
3. **Precedent.** The dark/`__light__` screenshot regression lanes are already local-only with committed baselines; the critic lane inherits that boundary cleanly.
4. **The deterministic guard already exists.** `stress_ledger_test.exs` (pure, fast, offline) is what runs in CI and enforces the ratchet on the *committed* scores. The LLM produces evidence and proposed scores locally; the deterministic ratchet is the gate. This is the honest split: **CI verifies the ledger; the LLM feeds the ledger.**

---

## Deterministic Capture Pipeline

Build directly on the existing `operator-screenshots.spec.ts` / `operator-stress.spec.ts` / `operator-accessibility.spec.ts` lanes. The `capture()` helper already emits fullPage PNGs with `__default__`/`__light__` lane infixes and viewport suffixes (`1280`/`375`) into `OPERATOR_SCREENSHOT_DIR` — extend it to emit a **complete evidence bundle** per (page × state × breakpoint × theme):

```
<bundle-id>/
  screenshot.png          # existing fullPage capture (or section crops — see below)
  dom.html                # await page.content()  (rendered HTML)
  a11y.json               # accessibility tree (see note)
  tokens.json             # the resolved --tl-* values in scope (from brandbook/tokens.json)
  meta.json               # url, viewport, theme, story_id, fixture_key, ledger id
```

Matrix dimensions (all already parameterized in the repo):
- **Pages:** the 11 `/audit` pages + the `/audit/__stress` stories (footgun + component fixtures).
- **States:** the ugly-data / empty / dense / permission-denied / stale / null-field states already enumerated in `stress_fixtures.ex` and the ledger.
- **Breakpoints:** 375 (mobile) / 1280 (desktop); add 768 if the tablet flows need coverage.
- **Themes:** dark (`__default__`) and `__light__` via the existing `desktop-chromium-light` project (`colorScheme: "light"`, `THREADLINE_E2E_THEME=system`).

**Accessibility-tree capture:** `page.accessibility.snapshot()` is deprecated in modern Playwright. Prefer **ARIA snapshots** (`await page.locator('body').ariaSnapshot()` / `toMatchAriaSnapshot`), which are stable and already the direction of the a11y specs. The a11y tree is cheap, high-signal text that materially improves discoverability/self-documenting and hierarchy judgments — feed it alongside the screenshot.

**Image-token control (do this deliberately):**
- Full-page screenshots of long pages can be very tall → huge image-token cost and diluted focus. Two mitigations: (a) keep the fixed-viewport captures (375/1280) and let the critic score "above the fold" density/low-scroll explicitly; (b) additionally emit **per-section crops** (header, primary table, filters, detail panel) so the graphic-design critic gets focused evidence for alignment/spacing rhythm without a 4784-token full-page image each time.
- Cap the long edge at ≤2576px; downsample above that (it's the model's max anyway).

**Determinism knobs already in place to keep:** `reducedMotion: "reduce"`, `workers: 1`, `waitForLoadState("networkidle")`, deterministic seeds (`mix demo.seed`). These make the *inputs* reproducible so that run-to-run score variance is attributable to the model, not the capture.

---

## Prior Art / Tools (with tradeoffs)

| Tool / Approach | What it does | Tradeoffs for Threadline |
|-----------------|--------------|--------------------------|
| **Playwright `toHaveScreenshot()`** (built-in) | Pixel-diff regression baselines | Already in use. Catches *unintended* pixel change; says nothing about *design quality*. Keep for regression; it is orthogonal to the critic. |
| **BackstopJS** (OSS, MIT) | Pixel/perceptual visual regression | Free, no quality judgment, another runner to own. Skip — Playwright already covers this. |
| **Lost Pixel** (OSS + cloud) | Visual regression, some AI triage | Adds a service dependency; regression not critique. Skip. |
| **Applitools Visual AI** | Structure-aware ("Visual AI") diff, fewest false positives | Best-in-class *diff*, but it's a paid, closed, hosted regression product — not a rubric-scored design critic, and it adds vendor lock-in and per-snapshot cost. Not aligned with the source-first, self-hosted, OSS posture. |
| **Percy AI Review Agent** | Pixel diff + separate AI layer flags likely-noise | Same category (regression triage), paid/hosted. Skip. |
| **Chromatic** | Storybook-native pixel diff | The repo has a PhoenixStorybook example/dev lane, but Chromatic is JS-Storybook-oriented and pixel-only (no AI critique). Not worth the coupling. |
| **Playwright MCP / Playwright Test Agents** | Let an LLM drive the browser + read DOM/a11y | Useful pattern for *agentic exploration* (exercise controls, observe state transitions — which the UX-judge research says is needed for behavior-aligned judgments). Consider for the persona critics' interactive lane later; not required for the static scored matrix. |
| **MLLM-as-UI-Judge / rubric-guided eval (research)** | Prompt a vision LLM with per-instance visual rubrics | This is the core recommended approach. Rubric-guided eval raises agreement with UX experts to ~77–87% and anchors scores to verifiable checks rather than free-form vibes. Confirms: **rubrics + anchors, not open-ended "rate this UI."** |
| **CritiqueCrew / multi-perspective critique (research)** | Orchestrate several persona critics | Validates the one-critic-per-persona + dedicated design-critic architecture the milestone envisions. |

**Net:** the commercial visual-AI tools solve *regression triage*, which Playwright already covers for Threadline. None of them do rubric-scored, persona-driven *design critique* wired into a monotonic ratchet — that's bespoke, and the research literature says build it with rubric-guided multimodal prompting + evidence collection. Build, don't buy.

---

## Reliability & Determinism Techniques

Apply all of these; they compound:

1. **JSON-schema-constrained output** (`output_config.format`). Every critic returns: `overall_score` (0–100), `criteria[]` each with `{name, score, weight, evidence, severity, suggested_fix}`, and `confidence`. No prose scores to parse.
2. **Per-persona weighted rubrics, versioned.** The graphic-design rubric encodes the milestone's explicit dimensions (spacing rhythm, alignment, visual hierarchy, typographic scale, density, elegance-vs-accidental, low-clunk/low-scroll, discoverable/self-documenting). Persona rubrics encode each JTBD. Stamp every verdict with `rubric_version`; a rubric change resets comparability (record a ratchet reset with rationale, per the existing ledger rule).
3. **Few-shot calibration anchors.** Use the stress harness: footgun fixtures (already scored 25/35) as **known-bad**, their target-90 fixed states as **known-good**. Include 1–2 of each in the cached prefix so the model's scale is pinned to Threadline's own artifacts, not an abstract 0–100. This is the highest-leverage reliability move and it's already sitting in `stress_fixtures.ex`.
4. **Self-consistency / ensemble.** Run N=3–5 samples per bundle (adaptive thinking varies the reasoning path). Aggregate: **median** score, plus **agreement** (variance/IQR). High-variance items are flagged for human review, not auto-scored — the research explicitly warns MLLM judges are sensitive to position bias and single-shot noise.
5. **Position-bias mitigation.** When comparing two states (e.g., before/after), randomize order across samples and/or score each independently rather than "which is better, A or B."
6. **Evidence pointers, not just scores.** Require each criterion to cite concrete evidence (a selector, a token, a screenshot region). Forces grounded judgments and gives humans an auditable trail — matching the repo's "SQL-native / no opaque blobs" and audit-evidence ethos.
7. **Prompt caching keeps the judge stable.** The rubric + anchors + tokens prefix must be byte-identical run to run (sort JSON keys, no timestamps in the prefix) or you both lose cache hits *and* perturb the judge. Verify `cache_read_input_tokens > 0`.
8. **Monotonic ratchet with a noise band.** The ledger score may only rise. Because the judge is stochastic, only **ratchet up** when the new median exceeds the prior by more than the measured agreement band; **never auto-ratchet down** — a score drop opens a human review item (the LLM is advisory on regressions, the deterministic screenshot lane catches literal visual regressions).

---

## Cost & Local-vs-CI Boundary

- **Batch API = 50% discount** on the whole matrix; it's async, so run it overnight / on demand. This is the right tool because the matrix is large and not latency-sensitive.
- **Prompt caching** collapses the dominant cost: the rubric+anchors+tokens prefix (potentially tens of thousands of tokens) is written once and read at ~0.1× for every bundle in the run.
- **Image tokens dominate the variable cost** — control them via fixed viewports + section crops (above). Full-page 2576px images at ~4784 tokens each add up across hundreds of bundles.
- **Boundary (explicit):**
  - **Local / on-demand:** all Claude API calls, the Node critic runner, `mix verify.ui_critique`, verdict generation, proposed ledger deltas. Requires `ANTHROPIC_API_KEY`; gate it behind an env check so it no-ops without a key (like `OPERATOR_SCREENSHOT_DIR`).
  - **CI (deterministic, offline, free):** `stress_ledger_test.exs` enforcing the ratchet on committed scores; the existing Playwright screenshot-regression + a11y-contract + `style_contract_test.exs` lanes. CI never calls the API.
  - Keep `mix verify.ui_critique` **out of `mix ci.all`** and document it as local-only in CONTRIBUTING + the guide, honoring the "honest default tests / no hidden heavy suites" DNA.

---

## Integration Points

- **Capture:** extend `capture()` in `operator-screenshots.spec.ts` to emit the full evidence bundle (screenshot + `page.content()` DOM + `ariaSnapshot()` a11y + tokens + meta). Reuse `OPERATOR_SCREENSHOT_DIR`, the lane infixes, and viewport suffixes.
- **Fixtures/anchors:** pull known-good/known-bad from `stress_fixtures.ex` via `/audit/__stress?story=...` (already the ledger's `stress_path`).
- **Tokens:** feed `brandbook/tokens.json` and the `style.ex` token/BEM contract as the cached design-language reference so the critic scores against Threadline's actual system, not generic taste.
- **Ledger:** write critic scores into `.planning/design-system-ledger.json` (`current_score`, `ratchet_score`, new `critic_scores`, `rubric_version`); reproject `DESIGN-SYSTEM.md`.
- **Enforcement:** extend `stress_ledger_test.exs` to assert critic scores never fall below ratchet (with noise band).
- **Named entrypoint:** add `mix verify.ui_critique` (local-only), documented under the doc-contract so README/guides/CONTRIBUTING stay aligned (per the doc-contract DNA), and explicitly excluded from `mix ci.all`.

---

## What NOT to Add

- **No new root (`mix.exs`) runtime dependency.** No Elixir HTTP/JSON/LLM client in the library. The Anthropic SDK lives only in `examples/threadline_phoenix/e2e/package.json` as a `devDependency`. Root stays Phoenix-optional.
- **No public component API and no new operator-UI family** — v1.40 is evaluation/iteration tooling, not product surface. Storybook stays example/dev-only.
- **No blocking CI gate on LLM output.** No born-red API-dependent job; no API key required to run the default suite or `mix ci.all`.
- **No commercial visual-AI SaaS** (Applitools/Percy/Chromatic/Lost Pixel). Playwright already covers pixel regression; the critic is bespoke and self-hosted, matching the OSS/source-first posture.
- **No second capture stack.** Do not introduce Puppeteer, a headless-shot microservice, or a separate DOM scraper — everything comes from the existing Playwright lanes.
- **No unversioned rubric drift.** Never change a rubric without bumping `rubric_version` and recording a ratchet reset rationale; otherwise scores stop being comparable and the "monotonic" guarantee is a fiction.
- **No single-shot scoring.** Do not ratchet on one API call; aggregate N samples and gate on the agreement band.
- **No `temperature`/`top_p`/prefill** in the request (they 400 on Opus 4.8); no citations combined with structured outputs (400).

---

## Sources

Repo (HIGH confidence — inspected directly):
- `examples/threadline_phoenix/e2e/playwright.config.ts`, `tests/operator-screenshots.spec.ts`, `tests/operator-accessibility.spec.ts`, `tests/operator-stress.spec.ts`, `package.json`
- `.planning/design-system-ledger.json`, `DESIGN-SYSTEM.md`, `test/threadline/operator_surface/stress_ledger_test.exs`, `lib/threadline/operator_surface/{style.ex,live/stress_live.ex,stress_fixtures.ex}`
- `prompts/threadline-elixir-oss-dna.md`, `.planning/PROJECT.md`, `CLAUDE.md`

Claude API (HIGH confidence — bundled `claude-api` skill reference, cached 2026-06-04):
- Model IDs/pricing/context, structured outputs (`output_config.format`), prompt caching, Message Batches, adaptive thinking/effort, Opus 4.7+ high-resolution vision (2576px / ~4784 image tokens), removal of `temperature`/`top_p`/prefill on Opus 4.8.
- Structured Outputs GA: https://platform.claude.com/docs/en/build-with-claude/structured-outputs ; https://tessl.io/blog/anthropic-brings-structured-outputs-to-claude-developer-platform-making-api-responses-more-reliable/

LLM-as-visual-judge research (MEDIUM confidence — recent academic):
- MLLM as a UI Judge: https://arxiv.org/html/2510.08783v1
- Rubrics across the LLM landscape: https://arxiv.org/pdf/2606.08625
- UXBench (actionability of LLM UX critiques): https://arxiv.org/pdf/2606.16262
- CritiqueCrew (multi-perspective critique): https://arxiv.org/pdf/2602.01796
- WebVR (human-aligned visual rubrics): https://arxiv.org/pdf/2603.13391

Tooling landscape (MEDIUM confidence — verify versions/pricing at adoption):
- Playwright Test Agents: https://playwright.dev/docs/test-agents
- Playwright MCP visual testing: https://testdino.com/blog/playwright-mcp-visual-testing
- Visual regression tools 2026 (Percy/Chromatic/Applitools/Lost Pixel/BackstopJS): https://percy.io/blog/visual-regression-testing-tools ; https://delta-qa.com/en/blog/chromatic-vs-percy-comparison-2026/ ; https://www.lost-pixel.com/
- AI QA workflow for UI regressions: https://autonomyai.io/technology/building-a-qa-workflow-with-ai-agents-to-catch-ui-regressions/
