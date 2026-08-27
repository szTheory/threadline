# Phase 195: Validated Adversarial Critic Runner & Panel — Research

**Researched:** 2026-07-03
**Domain:** Anthropic TypeScript SDK (vision + structured output + prompt caching), Krippendorff's α (ordinal, pure Elixir), Phase-194 substrate extension
**Confidence:** HIGH (SDK API shapes verified from claude-api skill); MEDIUM (Krippendorff α formula verified from Wikipedia; Elixir implementation assumed no library)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01: Golden set composition & maintainer verdict format (CRITIC-01)**
Reference existing Tier-A scorecard cells only (no new captures). Verdict format = coarse buckets (good/borderline/bad/broken) + pairwise better/worse+margin(clear/subtle). Every human label cites evidence. Blind test-retest (r1/r2, IDs masked); keep only r1==r2 items. ~50 golden capture cells → ≥20 lens-judgments per critic-bearing lens. `held_out_ids` frozen for Phase-196 true-north.

**D-02: Trust bar & critic↔human agreement metric (CRITIC-03)**
Gate = per-lens Krippendorff's α (ordinal) ≥ 0.67, computed treating maintainer's golden label and critic's median self-consistency score as two raters. Chance-corrected (raw % alone insufficient). Per-lens granularity; every critic-bearing lens clears its own bar. `critic_trust` block in `design-system-ledger.json` per lens: `{alpha, raw_agreement, pairwise_acc, n, ci95, golden_rubric_version, model_id, validated}`. `mix verify.critic_trust` (pure Elixir, async: true, no LLM/network, into ci.all) asserts validated lenses: alpha ≥ 0.67 AND n ≥ 20 AND raw_agreement ≥ 80 AND versions match.

**D-03: Refute-test battery & injected-regression catalog (CRITIC-02)**
Committed hand-authored A/B twins extending footgun.*/reserved_for_phase idiom. ~8 fixtures. Each twin = polished + one injected flaw (must PASS all mechanical gates — partition rule). Binary directional gates (correct rank/sign AND correct lens attribution) + margin gate + metamorphic invariance. Refute set ≠ golden set.

**D-04: Self-consistency N, variance policy & run-cost (RUNNER-02)**
N=3 default, escalate to N=7 on no-majority-band or within ±2 pts of band cut or ≤5 pts from floor/target. Single model = Opus 4.8 only. Unstable → current: null (NEVER 0). Cost control via prompt-cache, scoped runs, Tier-B subset.

**D-05: Per-lens rubric design (CRITIC-04)**
One committed markdown rubric per lens in `e2e/critic/rubrics/<lens>.md`, 2-3 gestalt-only dimensions (13 total across 6 lenses). Every dimension = adversarial pass/fail citing region/selector/mechanical line. Versioning = `<lens>@<semver>+<sha8>`. Poles-only few-shot (rubric + 2 poles) in cached prefix (≥4096 tok). Never embed mid-range golden cells or held_out_ids.

**D-06: Panel orchestration & cube merge (RUNNER-03)**
Each critic = blind, pure cell-writer. 14 lens-cells/page (10 persona + 4 invariant). Veto pipeline: verify.mechanical → token-parity brand veto → on veto write brand_fidelity null+vetoed:true and skip ALL vision calls → else vision critics run. Disagreement preserved (P1-high/P3-low is signal, not noise). Fan-out per (cell × lens-key), one dimension per call, parallel within rubric_version × model_id prefix group.

**D-07: Runner architecture & structured output (RUNNER-01)**
TypeScript CLI under `examples/threadline_phoenix/e2e/critic/`. Modules: run.ts, panel.ts, bundle.ts, prompt.ts, schema.ts, client.ts, cache.ts, scorecard.ts, report.ts, rubrics/, refute.ts. `messages.parse()` + JSON-schema/output_config. Opus 4.8 (do NOT send temperature/top_p/top_k). Per-dimension return: `{lens, score, band, pass, evidence{kind,locator,observation}, rationale}`. LLM scores in `.planning/critic-scores/` — NEVER under `.planning/scorecards/`. Guard: critic never writes under scorecards/.

**D-08: Critic report surface (RUNNER-03/CRITIC-04)**
JSON truth (.planning/critic-scores/), terminal = glance (mix verify.ui_critique), CRITIQUE.md projection = primary reviewable. No dashboard, no LiveView, no HTML, no public API. Betterer idiom (new/fixed/same/regression).

**D-09: Authoring DX — critic label CLI**
TypeScript CLI lane `critic label` inside D-07 runner. Blind r1/r2 rounds; r1.json and r2.json in `.planning/golden/rounds/`. CLI is the only golden-set.json writer. First-run empty state = clean exit 0 with guided path.

**D-10: Score→band mapping & ratchet coupling**
5 bands: fail(0-34), weak(35-54), ok(55-69), strong(70-84), exemplary(85-100). Band-of-median for point score. Band-mode for stability (count(modal band) < ⌈N/2⌉ → unstable). Variance gates on RAW: IQR>10 OR range>15 → unstable. Floor snaps to band lower cut {0,35,55,70,85}.

**D-11: Prompt architecture & anti-sycophancy**
Three strata: system (frozen, adversarial framing) → cached prefix (rubric+reference-bar+2 pole images, ≥4096 tok per lens) → uncached suffix (target screenshot+mechanical evidence+aria snapshot+persona clause). Cite-before-score field order: evidence → observation → pass → band → score. Adaptive thinking display:"summarized" (NOT the omitted default). Downsampled screenshot ~1092px long edge (~1600 tok). No detail knob.

**Locked milestone invariants:**
- No root mix.exs runtime dep — Anthropic SDK is devDependency of `e2e/package.json` ONLY
- `verify.compile_no_optional` still proves threadline stays Phoenix-optional
- No public component / "design-eval" API — dev/maintainer tooling only
- `mix verify.ui_critique` requires `ANTHROPIC_API_KEY`, no-ops without it, EXCLUDED from `mix ci.all`
- No external SaaS visual-diff tool names in committed copy
- Capture/query/auth semantics untouched
- Reference bar: Linear (primary) + Vercel/Stripe/Grafana (secondary/cautionary)

### Claude's Discretion
- Exact JSON/field spelling in golden-set.json, critic_trust, refute manifest, .planning/critic-scores/ files (beyond locked shapes)
- Exact e2e/critic/ file names
- Test-name wording
- Which 3 pages are "lowest-scoring targets" for golden mid-range cells (derive from current ledger scores)
- Exact α-bootstrap CI method (bootstrap vs jackknife, hand-rolled pure Elixir)
- Exact rubric per-dimension wording (decomposition locked in D-05; prose authored at implement time)
- Exact keybindings / terminal-image mechanism for `critic label`

### Deferred Ideas (OUT OF SCOPE)
- Forward-only net-positive gate + auto-apply + first proven improvement (Phase 196)
- Coverage growth to next-lowest pages + v1.37-style adversarial closeout + design-debt register (Phase 197)
- Full multi-theme × multi-breakpoint critic sweep (Phase 195 = curated Tier-B subset only)
- Splitting lenses across cheaper model tiers (rejected, not deferred)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CRITIC-01 | A golden set of hand-labeled Threadline states (known-good primitives + known-bad footgun fixtures) exists with the maintainer's good/bad/rank verdicts. | D-01: `.planning/golden/golden-set.json` structure; pins to 174 committed Tier-A scorecards; r1/r2 blind-round format; `held_out_ids` frozen field |
| CRITIC-02 | The critic passes refute-tests before it may drive the ratchet — scores footgun fixtures low, polished primitives high, prefers known-better A/B, detects injected regression. | D-03: Committed A/B twins extending footgun.*/reserved_for_phase; partition rule (twins PASS mechanical gates); binary directional + margin + metamorphic gates |
| CRITIC-03 | Critic↔human agreement is measured on the golden set and meets a documented threshold (target 75–90%); below threshold blocks automated ratcheting. | D-02: Krippendorff's α ≥ 0.67 per lens; `critic_trust` block schema; `mix verify.critic_trust` pure-Elixir gate; α formula and implementation path documented below |
| CRITIC-04 | Versioned, anchored rubrics exist per lens (one per persona/JTBD + graphic-design + brand), each dimension phrased as an adversarial pass/fail with a written pass condition and a reference-bar anchor. | D-05: `e2e/critic/rubrics/<lens>.md`; 6 lens files; 2–3 dimensions each; semver+sha8 versioning; poles-only few-shot pattern |
| CRITIC-05 | Self-assessment is banned — every score cites a screenshot region/DOM selector or a mechanical output line; a finding that cannot be located is discarded. | D-07/D-11: `evidence{kind,locator,observation}` required in JSON schema; `messages.parse()` enforces at parse layer; cite-before-score field order |
| RUNNER-01 | A Node critic runner in `e2e/critic/` calls Claude vision with JSON-schema structured output, a prompt-cached rubric+anchor prefix, and one dimension per call. | D-07/D-11: TypeScript CLI architecture; `client.messages.parse()` + `output_config.format`; `cache_control: {type: "ephemeral"}` on system prefix; exact token budget path documented |
| RUNNER-02 | The runner performs N-sample self-consistency (median + variance), flags high-variance cells as unstable (not ratcheted), and stamps model id + rubric version on every scorecard. | D-04/D-10: N=3→7 escalation; band-of-median; IQR>10 OR range>15 → unstable; `current:null` NEVER 0; `.planning/critic-scores/` schema |
| RUNNER-03 | The panel runs one critic per persona (P1–P5) + a graphic-design critic + a brand-veto critic; a `--tl-*` token/parity violation vetoes a change before aesthetic scoring. | D-06: 14 lens-cells/page; veto pipeline ordering; mechanical → token-parity veto → vision critics; brand_fidelity null+vetoed on veto |
| RUNNER-04 | `mix verify.ui_critique` wraps the runner as a named entrypoint, requires `ANTHROPIC_API_KEY`, no-ops without it, is excluded from `mix ci.all`, and is documented as local-only under a doc-contract lock. | verify.flake precedent in mix.exs (confirmed); ANTHROPIC_API_KEY no-op pattern; doc-contract lock via stress_ledger_test.exs @forbidden_terms idiom |
| RUNNER-05 | The Anthropic SDK is a `devDependency` of `e2e/package.json` only; `verify.compile_no_optional` still proves root `threadline` stays Phoenix-optional with no new runtime dependency. | e2e/package.json currently only has @playwright/test; adding @anthropic-ai/sdk as devDependency only; verify.compile_no_optional confirmed in ci.all |
</phase_requirements>

---

## Summary

Phase 195 builds a Claude-vision critic panel over the deterministic Phase-194 substrate and — critically — validates it against a hand-labeled golden set before it may drive any ratchet. All major design decisions are locked in D-01..D-11. Research fills five implementation-detail gaps: (1) exact Anthropic TypeScript SDK API shapes (vision, structured output, caching, adaptive thinking), (2) prompt-cache mechanics for Opus 4.8, (3) Krippendorff's α (ordinal) pure-Elixir implementation path, (4) Phase-194 substrate inventory (scorecard JSON shapes, ledger cube, stress_fixtures.ex idioms, mix.exs alias patterns), and (5) the `mix verify.ui_critique` / `verify.critic_trust` wiring contract.

The design is architecturally conservative: the critic runner lives entirely within the existing `e2e/` package (TypeScript, devDependency only), the Elixir CI gate mirrors the existing `stress_ledger_test.exs` pattern, and the nondeterministic LLM scores are physically isolated in `.planning/critic-scores/` separate from the deterministic `.planning/scorecards/` bundles. No new root dependencies, no public API surface, no LiveView changes.

The linchpin risk is Krippendorff's α implementation in pure Elixir. No Hex library exists; a ~60-80 line implementation using the coincidence-matrix formula is straightforward for 2 raters. The other major implementation risk is the prompt-cache 4,096-token minimum: the text-only rubric (~2–2.5k tokens) sits below the floor, so the two pole exemplar images are load-bearing padding — if they are omitted or downsized too aggressively, the cache silently misses and every call pays full input cost.

**Primary recommendation:** Build the TypeScript critic runner as a standalone CLI under `e2e/critic/` (no Playwright entanglement), wire `mix verify.ui_critique` as a `System.cmd` alias mirroring the `verify.example_browser` precedent, implement `mix verify.critic_trust` as a pure-Elixir ExUnit test module mirroring `stress_ledger_test.exs`, and hand-roll the ~70-line Krippendorff's α ordinal computation inline in the trust test.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Vision scoring (screenshot → JSON score) | Node CLI (e2e/critic/) | — | TypeScript owns Anthropic SDK; isolated from Elixir runtime |
| Prompt caching + structured output | Node CLI (e2e/critic/client.ts) | — | SDK feature; cache control must be per-call in TypeScript |
| Brand/token veto (mechanical) | Node CLI (e2e/critic/panel.ts) | Elixir (verify.mechanical) | Veto reads --tl-* tokens from scorecard JSON; no LLM |
| N-sample self-consistency | Node CLI (e2e/critic/client.ts) | — | Must control repeated calls to same SDK client |
| Verdict cache (resume/replay) | Node CLI (e2e/critic/cache.ts) | — | Keyed on cell+dimension+rubric_hash+model_id; fs-level JSON |
| Critic-score persistence | Node CLI (.planning/critic-scores/) | — | Nondeterministic LLM output; never in scorecards/ |
| CRITIQUE.md projection | Node CLI (e2e/critic/report.ts) | — | Reads critic-scores/, generates markdown; mirrors DESIGN-SYSTEM.md generation |
| Golden-set authoring (critic label) | Node CLI (e2e/critic/) | — | Masked IDs, blind rounds, keyboard-driven; same npm package |
| Trust gate (verify.critic_trust) | Elixir (mix alias + ExUnit test) | — | Pure Elixir, no LLM, safe in ci.all; reads critic_trust block from ledger JSON |
| mix verify.ui_critique entry point | Elixir (mix.exs alias) | Node CLI | Alias shells out to npm run critic:score; ANTHROPIC_API_KEY no-op |
| mix ci.all integration | Elixir (mix.exs ci.all list) | — | verify.critic_trust added before verify.mechanical; verify.ui_critique excluded |
| Refute-twin fixtures | Elixir (stress_fixtures.ex) | Node CLI (refute.ts) | Twins defined in stress_fixtures.ex; critic runner reads and scores |
| Ledger cube critic_trust block | JSON (.planning/design-system-ledger.json) | Elixir (verify.critic_trust) | JSON is truth; Elixir guard asserts invariants |
| Golden set JSON | JSON (.planning/golden/golden-set.json) | Elixir (guard test) | Committed oracle; pure-Elixir guard checks cell refs resolve |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@anthropic-ai/sdk` | `0.110.0` [VERIFIED: npm registry] | Anthropic API client — vision, structured output, prompt caching, adaptive thinking | Official Anthropic SDK; the only endorsed integration path; `messages.parse()` enforces schema client-side |
| TypeScript | `^5.x` [ASSUMED] | Type safety for critic CLI; Zod integration | Already in e2e/ via `@playwright/test`; tsconfig.json present |
| `zod` | `^3.x` [ASSUMED] | JSON-schema-backed structured output (`zodOutputFormat`) | Integrated with `@anthropic-ai/sdk/helpers/zod`; one source of truth between schema and runtime |

### Supporting (already present in repo)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@playwright/test` | `^1.52.0` [VERIFIED: package.json] | Existing e2e test infrastructure; NOT used by critic runner directly | Only for Playwright specs; critic runner is a standalone Node CLI |
| ExUnit | OTP/built-in | `mix verify.critic_trust` test module | All CI-gate tests; `async: true`, no LLM, no network |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `messages.parse()` + Zod | Raw `messages.create()` + `JSON.parse()` | `messages.parse()` auto-validates schema client-side and returns typed `parsed_output`; raw parse requires manual validation and error handling |
| Hand-rolled α (pure Elixir) | Python script (called from Elixir) | Python script adds external runtime dep; pure Elixir stays in ci.all without any external process dependency |
| Bootstrap CI (B=1000 resamples) | Jackknife CI | Jackknife is preferred for N<20; bootstrap is adequate for N≥20-50 (phase's target is ≥20 per lens); either is implementable in pure Elixir |

**Installation (e2e/package.json additions):**
```bash
# From examples/threadline_phoenix/e2e/
npm install --save-dev @anthropic-ai/sdk zod
```

**Version verification (confirmed):**
```bash
npm view @anthropic-ai/sdk version
# 0.110.0 (published 2026-07-02)
```

---

## Package Legitimacy Audit

> Run via `gsd_run query package-legitimacy check --ecosystem npm @anthropic-ai/sdk`

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@anthropic-ai/sdk` | npm | 3.5 yrs (created 2023-01-31) | 22.6M/wk | github.com/anthropics/anthropic-sdk-typescript | `SUS` (tool: too-new latest version) | **Approved** — "too-new" flag is for the 2026-07-02 patch release (0.110.0), not the package itself; 22.6M weekly downloads + official Anthropic org + zero postinstall script confirm legitimacy |

**Packages removed due to SLOP verdict:** none

**Packages flagged as suspicious SUS:** `@anthropic-ai/sdk` — tool flagged due to same-day version publication; manually verified as official Anthropic package via github.com/anthropics/anthropic-sdk-typescript. No human checkpoint required.

---

## Architecture Patterns

### System Architecture Diagram

```
mix verify.ui_critique
        │
        ▼  (System.cmd "npm run critic:score" — requires ANTHROPIC_API_KEY)
  e2e/critic/run.ts  ──── CLI scope / orchestration / exit codes
        │
        ├── panel.ts  ───── critic → lens map; veto ordering
        │       │
        │       ├── [1] verify.mechanical (deterministic, $0)
        │       ├── [2] token-parity brand veto (reads scorecard tokens, $0)
        │       │       │
        │       │       ▼ on veto: write brand_fidelity null+vetoed:true → STOP
        │       │
        │       └── [3] vision critics (parallel per cell × dimension)
        │
        ├── bundle.ts ───── reads Tier-B scorecard JSON + .aria.yml + PNG path
        │       │
        │       └── .planning/scorecards/{cell_id}.json  (deterministic, committed)
        │           .planning/scorecards/{cell_id}.aria.yml  (band-2 only)
        │           e2e/artifacts/tier-a/{cell_id}/screenshot.png
        │
        ├── prompt.ts ───── cached prefix builder (≥4096 tok per lens)
        │       │
        │       ├── system: adversarial framing (frozen, shared)
        │       ├── cached prefix: rubrics/<lens>.md + reference-bar + 2 pole images
        │       │      └── cache_control: {type:"ephemeral"} on this block
        │       └── uncached suffix: target screenshot + mechanical lines + aria + persona clause
        │
        ├── client.ts ────── Anthropic SDK; messages.parse(); N-sample loop; retry/backoff
        │       │
        │       └── Anthropic API (claude-opus-4-8, adaptive thinking display:"summarized")
        │
        ├── cache.ts ─────── verdict cache keyed {cell,dim,rubric_hash,model_id} → fs JSON
        │
        ├── scorecard.ts ─── writes per-dimension result to .planning/critic-scores/
        │       │
        │       └── .planning/critic-scores/{cell_id}/{lens}/{dim}.json
        │           (NEVER writes under .planning/scorecards/)
        │
        └── report.ts ────── reads .planning/critic-scores/; emits CRITIQUE.md projection
                │
                └── .planning/CRITIQUE.md  (committed, freshness-tested, diffable)


mix verify.critic_trust  (pure Elixir, ExUnit, async:true — IN ci.all)
        │
        └── reads design-system-ledger.json critic_trust block
                └── asserts per validated lens: alpha ≥ 0.67, n ≥ 20,
                    raw_agreement ≥ 80, versions match current rubric+model
```

### Recommended Project Structure
```
examples/threadline_phoenix/e2e/
├── critic/
│   ├── run.ts              # CLI entry: score | validate | label | rubric
│   ├── panel.ts            # critic→lens map, veto ordering, fan-out
│   ├── bundle.ts           # reads scorecard JSON + screenshot + aria
│   ├── prompt.ts           # cached prefix builder (system + rubric + poles)
│   ├── schema.ts           # Zod schema for per-dimension structured output
│   ├── client.ts           # Anthropic SDK wrapper, N-sample loop, retry
│   ├── cache.ts            # verdict cache (resume/replay, fs JSON)
│   ├── scorecard.ts        # writes to .planning/critic-scores/
│   ├── report.ts           # CRITIQUE.md projection
│   ├── refute.ts           # refute-battery runner
│   ├── label.ts            # critic label CLI (D-09 authoring lane)
│   └── rubrics/
│       ├── hierarchy.md    # rubric@<semver>+<sha8>
│       ├── density.md
│       ├── rhythm.md
│       ├── typography.md
│       ├── color_contrast.md
│       └── brand_fidelity.md
├── package.json            # adds @anthropic-ai/sdk, zod as devDependencies
│                           # adds scripts: critic:score, critic:validate, critic:label
└── playwright.config.ts    # unchanged

.planning/
├── golden/
│   ├── golden-set.json     # committed oracle (D-01)
│   └── rounds/
│       ├── r1.json         # blind round 1 (never read by r2 pass)
│       └── r2.json         # blind round 2
├── critic-scores/          # LLM-scored results (nondeterministic, gitignored?)
│   └── {cell_id}/
│       └── {lens}/
│           └── {dim}.json
└── design-system-ledger.json  # adds critic_trust block (this phase)

test/threadline/operator_surface/
└── critic_trust_test.exs   # mix verify.critic_trust (mirrors stress_ledger_test.exs)
```

### Pattern 1: Structured Output via messages.parse() with Zod
**What:** Use `client.messages.parse()` with `zodOutputFormat()` for type-safe structured responses that auto-validate the schema client-side.
**When to use:** Every per-dimension critic call; the `evidence` and `kind`+`locator` required fields enforce CRITIC-05 at parse time.

```typescript
// Source: claude-api skill — typescript/claude-api/tool-use.md (Structured Outputs section)
import Anthropic from "@anthropic-ai/sdk";
import { z } from "zod";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";

const CriticDimensionSchema = z.object({
  lens: z.enum(["hierarchy", "density", "rhythm", "typography", "color_contrast", "brand_fidelity"]),
  score: z.number().int(),        // SDK strips min/max → clamp to 0-100 client-side
  band: z.enum(["fail", "weak", "ok", "strong", "exemplary"]),
  pass: z.boolean(),
  evidence: z.object({
    kind: z.enum(["region", "selector", "mechanical_line"]),
    locator: z.string(),          // required — enforces CRITIC-05 at schema layer
    observation: z.string(),
  }),
  rationale: z.string(),
});

const client = new Anthropic();

const response = await client.messages.parse({
  model: "claude-opus-4-8",
  max_tokens: 4096,
  thinking: { type: "adaptive", display: "summarized" }, // NOT "omitted" default
  // temperature / top_p / top_k MUST NOT be sent — return 400 on Opus 4.8
  system: [
    {
      type: "text",
      text: FROZEN_ADVERSARIAL_SYSTEM_PROMPT,  // shared across all lenses
    },
  ],
  messages: [
    {
      role: "user",
      content: [
        // Cached prefix: rubric + reference-bar + 2 pole images (≥4096 tok)
        { type: "image", source: { type: "base64", media_type: "image/png", data: polePassImage } },
        { type: "image", source: { type: "base64", media_type: "image/png", data: poleFailImage } },
        {
          type: "text",
          text: rubricText,
          cache_control: { type: "ephemeral" },  // breakpoint after poles+rubric
        },
        // Uncached suffix (per call, volatile)
        { type: "image", source: { type: "base64", media_type: "image/png", data: targetScreenshot } },
        { type: "text", text: mechanicalEvidenceLines },
        { type: "text", text: ariaSnapshot },
        { type: "text", text: personaPassConditionClause },  // LAST, after cache boundary
      ],
    },
  ],
  output_config: {
    format: zodOutputFormat(CriticDimensionSchema),
  },
});

// Clamp score client-side (SDK strips numeric bounds from schema)
const result = response.parsed_output!;
const clampedScore = Math.max(0, Math.min(100, result.score));
```

### Pattern 2: Prompt Cache Verification (Opus 4.8 minimum 4,096 tokens)
**What:** Verify the cache prefix is being hit; detect silent invalidation early.
**When to use:** During development and in dry-run mode; log cache hit ratios per lens sweep.

```typescript
// Source: claude-api skill — typescript/claude-api/README.md (Verifying Cache Hits section)
// After any messages.parse() call:
const usage = response.usage;
console.log(`Cache write: ${usage.cache_creation_input_tokens} tokens (1.25× cost)`);
console.log(`Cache read: ${usage.cache_read_input_tokens} tokens (0.1× cost)`);
console.log(`Uncached: ${usage.input_tokens} tokens (full cost)`);

// If cache_read_input_tokens == 0 on the second identical-prefix call:
// Silent invalidator at work — check for:
// 1. Prefix below 4096-token minimum (text-only rubric is ~2-2.5k; pole IMAGES are required padding)
// 2. Date.now() or UUID injected anywhere in the cached prefix text
// 3. Non-deterministic key ordering in the rubric JSON
// 4. TTL exceeded (5-min default) — batch calls tightly or pre-warm before sweep
```

### Pattern 3: Adaptive Thinking on Opus 4.8
**What:** Use `display: "summarized"` to surface auditable rationale before the JSON.
**When to use:** Every critic call on Opus 4.8. Default is `"omitted"` (empty thinking string) — must opt in.

```typescript
// Source: claude-api skill — typescript/claude-api/README.md (Extended Thinking section)
const response = await client.messages.parse({
  model: "claude-opus-4-8",
  max_tokens: 4096,
  thinking: {
    type: "adaptive",
    display: "summarized",  // REQUIRED to get readable thinking; "omitted" = empty string
    // budget_tokens NOT sent — removed on Opus 4.8, returns 400 if sent
  },
  // ...
});

// Access thinking blocks:
for (const block of response.content) {
  if (block.type === "thinking") {
    // block.thinking contains the summarized reasoning chain
    // Useful for D-11 "cite-before-score" auditability
  }
}
```

### Pattern 4: ESM path resolution (e2e/ is an ESM project)
**What:** `__dirname` is undefined in ES modules — use `import.meta.url`.
**When to use:** Any file I/O in `e2e/critic/` (reading rubrics, writing critic-scores, loading scorecards).

```typescript
// Source: claude-api skill — typescript/claude-api/README.md (Installation section)
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, resolve } from "path";

const here = dirname(fileURLToPath(import.meta.url));
// e.g., resolve(here, "../rubrics/hierarchy.md") for rubric files
// e.g., resolve(here, "../../../../.planning/scorecards") for scorecards
// (matches the existing repoRoot = resolve(process.cwd(), "../../..") convention in playwright.config.ts)
```

### Pattern 5: mix verify.ui_critique alias (mirrors verify.example_browser)
**What:** Shell out to npm via System.cmd with ANTHROPIC_API_KEY passthrough; no-op when key absent.
**When to use:** The alias definition in mix.exs.

```elixir
# Source: mix.exs (verified) — verify_example_browser/1 pattern
# New alias (verify.ui_critique is EXCLUDED from ci.all — mirrors verify.flake)
defp verify_ui_critique(args) do
  key = System.get_env("ANTHROPIC_API_KEY")
  if is_nil(key) || key == "" do
    IO.puts("mix verify.ui_critique: ANTHROPIC_API_KEY not set — skipping (local-only)")
    # clean exit 0 — mirrors the no-op contract (RUNNER-04)
  else
    e2e_dir = Path.join([__DIR__, "examples", "threadline_phoenix", "e2e"])
    script_args = ["run", "critic:score"] ++ args
    System.cmd("npm", script_args,
      cd: e2e_dir,
      env: [{"ANTHROPIC_API_KEY", key}],
      into: IO.stream(:stdio, :line)
    )
  end
end
```

### Pattern 6: Krippendorff's α (ordinal) — pure Elixir
**What:** Compute chance-corrected inter-rater agreement for 2 raters on ordinal data. Formula: α = 1 - Do/De.
**When to use:** Inside `verify.critic_trust` (and the `mix verify.ui_critique` golden-set re-score path) to compute the per-lens trust gate.

```elixir
# Source: [CITED: https://en.wikipedia.org/wiki/Krippendorff%27s_alpha] — coincidence-matrix formula
# This is the pure-Elixir implementation path.

defmodule Threadline.CriticTrust.KrippendorffAlpha do
  @doc """
  Computes Krippendorff's alpha (ordinal) for two raters over a list of {r1_value, r2_value} pairs.
  Values must be comparable (integers or atoms with a defined order).

  Returns {:ok, alpha} or {:error, :insufficient_data} when n < 2 pairable values exist.

  ## Formula (ordinal distance function)
  d(v, v')^2 = (sum_{g=v}^{v'} n_g - (n_v + n_v') / 2)^2
  alpha = 1 - Do / De

  ## Edge cases
  - Perfect agreement: alpha = 1.0
  - All raters use the same single value: De = 0 → return 1.0 (convention: no disagreement possible)
  - Systematic disagreement worse than chance: alpha < 0 (valid; do not clamp)
  """
  def compute(pairs) when is_list(pairs) do
    # Build value frequency map from all observed values across both raters
    all_values = Enum.flat_map(pairs, fn {v1, v2} -> [v1, v2] end)
    freq = Enum.frequencies(all_values)
    sorted_values = Enum.sort(Map.keys(freq))
    n = length(all_values)  # total number of values (= 2 * number of pairs for 2 raters)

    if n < 4, do: {:error, :insufficient_data}

    # Build coincidence matrix o_vv' from pairable values
    # For 2 raters: each pair {v1, v2} contributes 1 to o_{v1,v2} and 1 to o_{v2,v1} (or 2 to o_{vv} if v1==v2)
    coincidences =
      Enum.reduce(pairs, %{}, fn {v1, v2}, acc ->
        if v1 == v2 do
          Map.update(acc, {v1, v2}, 2, &(&1 + 2))
        else
          acc
          |> Map.update({v1, v2}, 1, &(&1 + 1))
          |> Map.update({v2, v1}, 1, &(&1 + 1))
        end
      end)

    # Compute observed disagreement Do
    do_ = compute_disagreement(coincidences, sorted_values, freq, n, :observed)
    # Compute expected disagreement De
    de_ = compute_disagreement(coincidences, sorted_values, freq, n, :expected)

    if de_ == 0.0, do: {:ok, 1.0}, else: {:ok, 1.0 - do_ / de_}
  end

  defp compute_disagreement(coincidences, sorted_values, freq, n, type) do
    pairs = for v <- sorted_values, v2 <- sorted_values, do: {v, v2}
    Enum.reduce(pairs, 0.0, fn {v, v2}, acc ->
      o_vv2 = Map.get(coincidences, {v, v2}, 0)
      e_vv2 =
        if v == v2,
          do: freq[v] * (freq[v] - 1) / (n - 1),
          else: freq[v] * freq[v2] / (n - 1)
      weight = ordinal_distance(v, v2, sorted_values, freq)
      observed_or_expected =
        case type do
          :observed -> o_vv2 * weight
          :expected -> e_vv2 * weight
        end
      acc + observed_or_expected
    end) / 2  # Each pair counted twice in symmetric matrix
  end

  defp ordinal_distance(v, v, _sorted, _freq), do: 0.0
  defp ordinal_distance(v, v2, sorted_values, freq) do
    # Ordinal distance: (sum of n_g from v to v2, inclusive, minus (n_v + n_v2) / 2)^2
    lo = min(v, v2); hi = max(v, v2)
    range_sum =
      sorted_values
      |> Enum.filter(&(&1 >= lo and &1 <= hi))
      |> Enum.reduce(0, &(Map.get(freq, &1, 0) + &2))
    delta = range_sum - (Map.get(freq, lo, 0) + Map.get(freq, hi, 0)) / 2.0
    delta * delta
  end
end
```

**Bootstrap CI95 (optional, for `ci95` field in critic_trust block):**
```elixir
# [ASSUMED] — standard bootstrap; no Elixir library; ~20 lines
def bootstrap_ci(pairs, b \\ 1000, alpha_level \\ 0.05) do
  n = length(pairs)
  alphas =
    1..b
    |> Enum.map(fn _ ->
      sample = Enum.take_random(Stream.cycle(pairs), n)
      case compute(sample) do
        {:ok, a} -> a
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()

  lo_idx = floor(length(alphas) * alpha_level / 2)
  hi_idx = floor(length(alphas) * (1 - alpha_level / 2))
  {Enum.at(alphas, lo_idx), Enum.at(alphas, hi_idx)}
end
```

### Anti-Patterns to Avoid
- **Sending `temperature`, `top_p`, or `top_k` on Opus 4.8:** Returns 400. These parameters are removed — do not send them. Variance is handled by N-sample median.
- **Sending `budget_tokens` on Opus 4.8:** Returns 400. Adaptive thinking does not support budget_tokens on Opus 4.7+.
- **Using `display: "omitted"` (or omitting `display`):** Returns empty thinking string. Must explicitly use `"summarized"` for auditable rationale.
- **Placing persona clause inside the cached prefix:** Requires 5 distinct prefixes (one per persona) = 5× cache misses. The persona clause must be in the uncached suffix (D-06, D-11 confirmed).
- **Setting `current: 0` on unstable cells:** Poisons the `min()` rollup and counts as a regression. Unstable cells must be `null`.
- **Writing to `.planning/scorecards/` from the critic runner:** The scorecards tree is deterministic, committed, gated by `verify.mechanical` in `ci.all`. LLM scores go to `.planning/critic-scores/` only.
- **Under-sizing the cached prefix (below 4,096 tokens):** Text-only rubric is ~2–2.5k tokens, below Opus 4.8's floor. Pole exemplar images are load-bearing padding. Without them, the cache silently misses (`cache_read_input_tokens: 0`) and every call pays full input cost.
- **Averaging persona scores to resolve P1-high/P3-low disagreement:** Persona disagreement is the cube's signal. Preserve it via `min()` rollup; surface the losing cell in rollup evidence. Do not average.
- **Folding refute fixtures into the golden set (D-03 partition rule):** Refute = synthetic extremes for sign/attribution testing. Golden = representative states for human-agreement measurement. Mixing teaches-to-the-test.
- **Calling `messages.create` instead of `messages.parse` for structured output:** `messages.create` returns raw content; schema validation and `parsed_output` require `messages.parse`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON-schema response validation | Custom JSON parser + schema checker | `client.messages.parse()` + `zodOutputFormat()` | SDK auto-validates, provides typed `parsed_output`, handles `null` on parse failure; Zod gives TypeScript types for free |
| Retry on 429/5xx | `setTimeout` retry loop | SDK built-in auto-retry with jitter | SDK handles exponential backoff; manual retry loops frequently mis-handle streaming and partial responses |
| Token counting pre-flight | Manual rough estimate | `client.messages.countTokens()` | Exact server-side count; use for `--dry-run` budget reporting |
| Streaming | `ReadableStream` wrapper | `client.messages.stream()` + `stream.finalMessage()` | Not needed for critic calls (short structured output), but if added: SDK's `.finalMessage()` is the only safe way to get the complete message |
| Schema numeric constraints | Enforcing `score >= 0 && score <= 100` in JSON schema | Clamp client-side post-parse | SDK strips `minimum`/`maximum` from schemas; clamp after `parsed_output` is returned |

**Key insight:** The Anthropic TypeScript SDK handles nearly all production concerns (retry, streaming, schema validation, cache control) — the critic runner's own code should be thin orchestration over the SDK, not a re-implementation of any of these layers.

---

## Runtime State Inventory

> This is a greenfield extension phase — no renames, no rebrand, no migrations. New files and directories only. Omitting this section.

---

## Common Pitfalls

### Pitfall 1: Cache prefix silently below 4,096-token floor
**What goes wrong:** The rubric text alone (~2–2.5k tokens) does not meet Opus 4.8's minimum cacheable prefix. `cache_read_input_tokens` is 0 on every call. All runs pay full input cost (~1.25× write, never 0.1× read). Per D-04: a ~$0.45 scoped run becomes $5+.
**Why it happens:** The floor is not enforced by an error — the API silently treats an under-floor prefix as uncached.
**How to avoid:** Include the two pole exemplar images inside the cached prefix block (they contribute ~1,600 tok each at ~1092px). After the first call, assert `usage.cache_creation_input_tokens > 4096` or log a warning. The pole images are load-bearing: they serve BOTH as anti-flattery calibration (D-05) AND as the padding that clears the floor (D-04).
**Warning signs:** `cache_read_input_tokens === 0` on the 2nd and subsequent calls with identical prefix.

### Pitfall 2: Persona clause in cached prefix = 5× cache misses
**What goes wrong:** If the persona's pass-condition clause is embedded in the cached prefix text, each of the 5 personas requires its own distinct cache entry. The single-prefix-per-lens cost advantage of D-06 is lost.
**Why it happens:** It feels natural to include "For P3 (Compliance Reviewer), pass iff..." in the rubric block. But any difference in the prefix byte stream invalidates cache sharing.
**How to avoid:** Per D-11: the persona clause must be the LAST item in the uncached suffix. The cached prefix contains only the rubric (lens-level), the reference-bar prose, and the two pole exemplar images (persona-agnostic).
**Warning signs:** `cache_creation_input_tokens` roughly equals `input_tokens` across multiple persona calls on the same lens.

### Pitfall 3: Sending temperature/top_p/top_k to Opus 4.8
**What goes wrong:** API returns HTTP 400. Runner exits with error. If not caught, the whole sweep fails.
**Why it happens:** These parameters exist in older model documentation and are natural to include for "controlling variance."
**How to avoid:** Never send `temperature`, `top_p`, or `top_k` in any call to `claude-opus-4-8`. Variance is managed via N-sample median (D-04), not sampling parameters.
**Warning signs:** `Anthropic.BadRequestError` with message about unsupported parameter.

### Pitfall 4: Adaptive thinking left at default "omitted" display
**What goes wrong:** The thinking block is present but `block.thinking` is an empty string. No auditable rationale. CRITIQUE.md output lacks the "why" behind scores.
**Why it happens:** The SDK default for Opus 4.8 is `display: "omitted"`. Not setting the field or setting `display: "omitted"` both produce empty thinking.
**How to avoid:** Explicitly pass `thinking: {type: "adaptive", display: "summarized"}`.
**Warning signs:** Thinking blocks in response.content have `type === "thinking"` but `block.thinking === ""`.

### Pitfall 5: Setting unstable cell to current: 0 instead of null
**What goes wrong:** `0` is a valid score that participates in `min()` rollup as a monotonicity baseline. Any future score > 0 registers as a gain from 0. The floor is poisoned.
**Why it happens:** `0` is the JavaScript/JSON default for numbers; easy to emit accidentally when "score is zero."
**How to avoid:** Per D-04: unstable cells MUST set `current: null`. Validate this in `verify.critic_trust` (assert: no cell with `IQR > 10 OR range > 15 OR no-majority-band` has `current !== null`).
**Warning signs:** `verify.critic_trust` monotonicity guard fails after a rescore; `min()` rollup jumps unexpectedly.

### Pitfall 6: Imbalanced golden set inflating raw agreement (CRIT-3 from PITFALLS.md)
**What goes wrong:** A "report all-bad" critic achieves 92.6% raw co-agreement on a golden set of 90% footguns. `raw_agreement ≥ 80%` passes. The critic learns nothing and blocks no regression.
**Why it happens:** Raw agreement ignores marginal distributions. An always-bad critic on an imbalanced set trivially matches the majority class.
**How to avoid:** Per D-02: the gate is Krippendorff's α ≥ 0.67, not raw %. Raw % is a recorded companion (non-gating). The chance-correction in α exposes the always-bad critic (its α ≈ 0.07 even at 92.6% raw).
**Warning signs:** `raw_agreement` is high but `alpha` < 0.4 — the classic imbalance signature.

### Pitfall 7: Krippendorff's α with De = 0 (all raters use one value)
**What goes wrong:** Division by zero in α = 1 - Do/De.
**Why it happens:** If all golden-set items have the same label (e.g., all "bad" poles, no mid-range), De = 0.
**How to avoid:** Handle the edge case explicitly: if De = 0, return α = 1.0 (convention: if no disagreement is possible, there's no unreliability). Per D-01: the golden set composition intentionally includes pole anchors + A/B pairs + mid-range cells to avoid this; but guard defensively.
**Warning signs:** `Enum.reduce` division by zero in pure-Elixir implementation; `critic_trust.alpha` is `null` or `Infinity`.

### Pitfall 8: Golden set items leaking into rubric few-shot examples (D-05 partition)
**What goes wrong:** Mid-range golden cells embedded in the cached prefix as few-shot examples. The critic is calibrated on the very cells used to measure its agreement — teaches-to-the-test, inflating α.
**Why it happens:** It feels helpful to show mid-range examples alongside poles for calibration.
**How to avoid:** Per D-05: the cached prefix contains ONLY the two pole exemplars (one pass-pole + one fail-pole, committed cell-ids named in the rubric). A pure-Elixir guard asserts `prefix_exemplar_ids ∩ (mid_range ∪ held_out) = ∅`.
**Warning signs:** A rubric file references a cell-id also found in `golden-set.json` under non-pole items.

---

## Code Examples

### Scorecard JSON shape (Phase-194 output, critic runner INPUT)
```json
{
  "schema_version": 1,
  "cell_id": "page.actor.happy__dark-1280",
  "ledger_id": "page.actor.happy",
  "theme": "dark",
  "breakpoint": 1280,
  "capture_tier": "A",
  "band": 1,
  "meta": { "playwright_version": "1.61.1", "device_scale_factor": 1, "viewport": {"width":1280,"height":900}, "color_scheme": "dark" },
  "tokens": { "--tl-color-thread-blue": "#4F8CFF", "--tl-color-stitch-blue": "#4781E6", "--tl-color-signal-cyan": "#4EDFD1" },
  "color_pairs": [{ "selector": "h2.tl-stress__preview-title", "color": "rgb(215,222,234)", "background_color": "rgba(0,0,0,0)", "font_size": "20px", "font_weight": "600" }],
  "mode_b": { "type_size_count": 4, "interactive_control_count": 0, "card_nesting_depth": 0, "scroll_cost": 16.561, "font_sizes": ["13px","14px","16px","20px"] },
  "a11y_summary": { "headings": 1, "landmarks": 0, "interactive_elements": 0 },
  "artifacts": {
    "screenshot": "examples/threadline_phoenix/e2e/artifacts/tier-a/page.actor.happy__dark-1280/screenshot.png",
    "dom": "examples/threadline_phoenix/e2e/artifacts/tier-a/page.actor.happy__dark-1280/dom.html",
    "a11y": "examples/threadline_phoenix/e2e/artifacts/tier-a/page.actor.happy__dark-1280/a11y.json",
    "aria": null
  }
}
```

### design-system-ledger.json critic_trust block (Phase 195 addition)
```json
{
  "critic_trust": {
    "hierarchy": {
      "alpha": 0.71,
      "raw_agreement": 0.83,
      "pairwise_acc": 0.94,
      "n": 24,
      "ci95": [0.55, 0.84],
      "golden_rubric_version": "hierarchy@1.0.0+ab3f1234",
      "model_id": "claude-opus-4-8",
      "validated": true
    },
    "density": {
      "alpha": null,
      "n": 0,
      "validated": false
    }
  }
}
```

### critic-scores file shape (per dimension, nondeterministic output)
```json
{
  "cell_id": "page.actor.happy__dark-1280",
  "lens": "hierarchy",
  "dimension": "entry_point_clarity",
  "model_id": "claude-opus-4-8",
  "rubric_version": "hierarchy@1.0.0+ab3f1234",
  "n": 3,
  "scores_raw": [58, 62, 60],
  "score": 60,
  "band": "ok",
  "band_mode": "ok",
  "iqr": 4,
  "range": 4,
  "stable": true,
  "pass": false,
  "evidence": {
    "kind": "selector",
    "locator": "h2.tl-stress__preview-title, .audit-row__actor",
    "observation": "Two elements of equal visual weight compete for primacy; neither is task-primary for P1 incident response."
  },
  "rationale": "...",
  "scored_at": "2026-07-03T12:00:00Z"
}
```

### golden-set.json item shape
```json
{
  "id": "gs_001",
  "cell_id": "page.actor.happy__dark-1280",
  "kind": "single",
  "lens": "hierarchy",
  "r1": { "verdict": "borderline", "evidence": "Two elements compete: h2.tl-stress__preview-title vs .audit-row__actor", "blind": true },
  "r2": { "verdict": "borderline", "evidence": "Primary action and actor share same font-weight:500, no dominant element", "blind": true },
  "kept": true
}
```

### mix.exs aliases (new aliases for Phase 195)
```elixir
# Source: mix.exs (verified pattern from verify.flake + verify_example_browser)

# In the aliases list:
"verify.ui_critique": &verify_ui_critique/1,      # LOCAL ONLY — excluded from ci.all
"verify.critic_trust": ["test test/threadline/operator_surface/critic_trust_test.exs"],  # into ci.all

# ci.all updated to include verify.critic_trust BEFORE verify.mechanical:
"ci.all": [
  "verify.format", "verify.credo", "compile --warnings-as-errors",
  "verify.compile_no_optional", "verify.test", "verify.threadline",
  "verify.example", "verify.doc_contract",
  "verify.critic_trust",   # NEW — pure Elixir, no LLM, safe in CI
  "verify.mechanical", "verify.example_browser"
]
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `thinking: {type: "enabled", budget_tokens: N}` | `thinking: {type: "adaptive", display: "summarized"}` | Opus 4.7+ (2025) | `budget_tokens` returns 400 on Opus 4.8; adaptive is the correct API |
| `temperature: 0.0` for determinism on Claude | N-sample median (N=3→7); no temperature param | Opus 4.8 (2025) | `temperature` returns 400; stochasticity handled via self-consistency |
| `output_format` (deprecated) | `output_config: {format: {...}}` | SDK 0.x (2025) | Old parameter is deprecated; `output_config` is the current path |
| Raw 80% co-agreement as trust gate | Krippendorff's α ≥ 0.67 (chance-corrected, per lens) | Phase 195 (this phase) | Raw % on imbalanced golden sets is gameable; α is not |

**Deprecated/outdated:**
- `thinking: {type: "enabled", budget_tokens: N}` on Opus 4.8: 400 error
- `temperature`, `top_p`, `top_k` on Opus 4.8: 400 error
- `output_format` (top-level): deprecated; use `output_config.format`
- `__dirname` in ESM TypeScript: ReferenceError; use `dirname(fileURLToPath(import.meta.url))`

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No Hex library for Krippendorff's α exists (neither `ex_stats` nor any other package provides it) | Standard Stack, Pattern 6 | If a library exists, planner should prefer it over hand-rolled; check hex.pm before Wave 0 |
| A2 | TypeScript version in e2e/ is `^5.x` (from tsconfig.json) | Standard Stack | If `^4.x`, some Zod v3 features may not work; check tsconfig.json |
| A3 | Zod v3 (`^3.x`) is not yet in e2e/package.json (only @playwright/test present) | Standard Stack | Need to add as devDependency; if already present at wrong version, may need upgrade |
| A4 | `.planning/critic-scores/` directory does not exist yet (new this phase) | Architecture Patterns | If it exists with prior content, Wave 0 must not overwrite |
| A5 | `@anthropic-ai/sdk` v0.110.0 `messages.parse()` + `output_config.format` API is stable (not beta) | Code Examples | If moved back to beta, beta headers may be required |
| A6 | Bootstrap CI (B=1000) is adequate for N=20–50 (jackknife not required) | Pattern 6 | For N<20 provisional lenses, jackknife is statistically preferred; implement jackknife if any lens has N<25 |

**If this table is empty:** Not applicable — several assumptions exist above.

---

## Open Questions

1. **Zod version in e2e/package.json**
   - What we know: Only `@playwright/test: ^1.52.0` is in the current devDependencies.
   - What's unclear: Whether Zod is already a transitive dependency of Playwright at a usable version, or must be added as a direct devDependency.
   - Recommendation: Add `zod: ^3.x` as an explicit devDependency in Wave 0. Do not rely on transitive resolution.

2. **Bootstrap vs jackknife CI for provisional lenses (N<20)**
   - What we know: D-02 allows provisional lenses (N<20 gets `provisional` flag, blocks ratchet). Bootstrap CI is adequate for N≥20.
   - What's unclear: The `ci95` field in `critic_trust` — is it required even for provisional lenses?
   - Recommendation: Implement bootstrap CI as the default; add a jackknife variant behind a `--ci-method jackknife` flag in `verify.critic_trust`. For the CI gate, `ci95` can be `null` when `n < 20`.

3. **Which 3 pages are "lowest-scoring targets" for golden mid-range cells**
   - What we know: D-01 says derive from current ledger scores at plan time.
   - What's unclear: The current ledger may have `scores.P1.hierarchy.current: null` for all cells (unrated). The runner needs to identify lowest-performing pages from available Phase-194 mechanical scores (not critic scores).
   - Recommendation: The planner should read the current `design-system-ledger.json` at plan time and identify pages with lowest mechanical band scores as proxies. Flag this as a human decision in the Wave 0 task.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | e2e/critic/ TypeScript CLI | ✓ [ASSUMED] | Unknown | — |
| npm | e2e/ package management | ✓ [ASSUMED] | Unknown | — |
| `ANTHROPIC_API_KEY` env var | `mix verify.ui_critique` | ✗ (optional) | — | Clean exit 0; doc-contract-locked no-op (RUNNER-04) |
| `@playwright/test ^1.52.0` | existing e2e/ | ✓ [VERIFIED: package.json] | 1.52.0 | — |
| mix / Elixir / OTP | verify.critic_trust | ✓ [ASSUMED] | Unknown | — |

**Missing dependencies with no fallback:** `ANTHROPIC_API_KEY` — required to run LLM calls, but the design explicitly no-ops without it (this is the feature, not a gap).

**Missing dependencies with fallback:** None.

**Step 2.6 note:** The critic runner is local-only tooling (not CI). Node.js/npm are assumed present on the maintainer's machine given the existing e2e/ Playwright setup. No availability probe was run; if Node.js is absent, the planner should add an install-check task in Wave 0.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/threadline/operator_surface/critic_trust_test.exs` |
| Full suite command | `mix verify.test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CRITIC-01 | golden-set.json references resolve to committed scorecards; r1==r2 for all kept items; every item has non-empty evidence | unit (pure Elixir) | `mix test test/threadline/operator_surface/critic_trust_test.exs` | ❌ Wave 0 |
| CRITIC-02 | Refute twins pass verify.mechanical; refute manifest has committed evidence bundle | unit (Elixir) + manual (critic runner) | `mix verify.mechanical` (deterministic part); `mix verify.ui_critique --refute-only` (LLM part, local) | ❌ Wave 0 |
| CRITIC-03 | critic_trust.alpha ≥ 0.67 per validated lens; n ≥ 20; raw_agreement ≥ 80; versions match | unit (pure Elixir, in ci.all) | `mix verify.critic_trust` | ❌ Wave 0 |
| CRITIC-04 | Rubric hash on disk == stamped hash in critic_trust; each rubric has ≤3 dimensions; poles resolve | unit (pure Elixir) | `mix verify.critic_trust` (rubric guard assertions) | ❌ Wave 0 |
| CRITIC-05 | messages.parse() discards responses with null evidence; schema requires evidence.kind + evidence.locator | TypeScript unit test or integration | `npm run critic:validate` (Node side) | ❌ Wave 0 |
| RUNNER-01 | Critic runner calls messages.parse() with output_config.format; structured output validates | integration (local, LLM) | `mix verify.ui_critique --dry-run` | ❌ Wave 0 |
| RUNNER-02 | N-sample median + variance flags unstable; unstable → null not 0 | TypeScript unit | `npm test` in e2e/ (if test suite added) | ❌ Wave 0 |
| RUNNER-03 | Brand veto fires before vision calls; vetoed cell writes null+vetoed:true; verify.mechanical passes | integration | `mix verify.ui_critique --refute-only` (includes veto-ordering test fixture) | ❌ Wave 0 |
| RUNNER-04 | verify.ui_critique no-ops when ANTHROPIC_API_KEY absent; excluded from ci.all | unit (pure Elixir) | `ANTHROPIC_API_KEY="" mix verify.ui_critique` → exit 0 | ❌ Wave 0 |
| RUNNER-05 | No new root mix.exs deps; compile_no_optional passes | build | `mix verify.compile_no_optional` (existing, already in ci.all) | ✅ existing |

### Sampling Rate
- **Per task commit:** `mix verify.critic_trust` (pure Elixir, fast, in ci.all)
- **Per wave merge:** `mix ci.all` (includes verify.critic_trust before verify.mechanical)
- **Phase gate:** `mix ci.all` green + `mix verify.ui_critique` passes locally (LLM gate, manual) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/threadline/operator_surface/critic_trust_test.exs` — covers CRITIC-01, CRITIC-03, CRITIC-04 (pure Elixir, async: true, no network)
- [ ] `examples/threadline_phoenix/e2e/critic/` directory and module stubs — covers RUNNER-01 through RUNNER-03
- [ ] Add `@anthropic-ai/sdk` and `zod` to `examples/threadline_phoenix/e2e/package.json` devDependencies — covers RUNNER-05
- [ ] Add `"verify.critic_trust"` to `mix.exs` aliases and to `ci.all` list — covers CRITIC-03 CI gate
- [ ] Add `"verify.ui_critique"` to `mix.exs` aliases (excluded from ci.all) — covers RUNNER-04
- [ ] `.planning/golden/` directory + `golden-set.json` skeleton — covers CRITIC-01 structure
- [ ] `.planning/critic-scores/` directory creation + guard test assertion that critic never writes to scorecards/ — covers D-07

---

## Security Domain

> `security_enforcement` is not set to false in config.json — applying.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No user auth surfaces; all dev-tooling only |
| V3 Session Management | No | CLI only; no sessions |
| V4 Access Control | No | Local tool; no multi-user surface |
| V5 Input Validation | Yes (partial) | Zod schema validation on LLM output; schema enforces evidence.locator required |
| V6 Cryptography | No | API key handled by SDK from env var; no custom crypto |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| LLM output injection (malicious content in scorecard JSON passed to API) | Tampering | Zod schema validates all critic output at parse layer; messages.parse() rejects non-conforming responses |
| API key in committed files | Info Disclosure | ANTHROPIC_API_KEY from env var only; SDK reads it automatically; never committed (doc-contract-locked no-op when absent) |
| Scorecard path traversal (untrusted cell_id used to construct file path) | Tampering | Validate cell_id against known ledger entries before constructing paths; never interpolate raw input into fs paths |
| Critic writes to scorecards/ (deterministic bundle corruption) | Tampering | Guard test in critic_trust_test.exs asserts no file under .planning/scorecards/ was modified by the critic runner |
| Prompt injection via scorecard content | Tampering | Mechanical evidence lines are from committed deterministic JSON (trusted); screenshots are binaries; aria.yml from committed capture — not from untrusted user input |

---

## Sources

### Primary (HIGH confidence)
- `claude-api skill (bundled)` — TypeScript SDK README and tool-use.md: messages.parse(), output_config.format, adaptive thinking display:"summarized", prompt caching cache_control, token usage fields, no detail parameter, ESM __dirname, error handling
- `/Users/jon/projects/threadline/mix.exs` (lines 100-130) — verify.flake local-only pattern, ci.all list, verify_example_browser System.cmd pattern
- `/Users/jon/projects/threadline/test/threadline/operator_surface/stress_ledger_test.exs` — pure-Elixir guard template for verify.critic_trust
- `/Users/jon/projects/threadline/.planning/scorecards/page.actor.happy__dark-1280.json` — scorecard JSON schema
- `/Users/jon/projects/threadline/.planning/design-system-ledger.json` — v2 cube structure, scores format
- `/Users/jon/projects/threadline/lib/threadline/operator_surface/stress_fixtures.ex` — footgun.*/reserved_for_phase idiom
- `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts` — cell ID format, repoRoot convention
- `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/playwright.config.ts` — e2e project structure, workers/timeout config
- `npm view @anthropic-ai/sdk` — version 0.110.0, published 2026-07-02, 22.6M weekly downloads
- `gsd_run query package-legitimacy check --ecosystem npm @anthropic-ai/sdk` — SUS (too-new version); manually resolved as official Anthropic SDK

### Secondary (MEDIUM confidence)
- [CITED: https://en.wikipedia.org/wiki/Krippendorff%27s_alpha] — coincidence-matrix formula, ordinal distance function, edge cases (De=0, α<0), 2-rater implementation
- [CITED: https://arxiv.org/pdf/2210.13265] — bootstrap CI adequate for N≥20; jackknife preferred for N<20

### Tertiary (LOW confidence / ASSUMED)
- No Elixir Hex library for Krippendorff's α confirmed by web search (no results found for Elixir implementation) — implementation must be hand-rolled
- Zod version and Node.js version on maintainer machine — assumed compatible; probe in Wave 0

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — SDK version confirmed via npm view; API shapes confirmed from authoritative claude-api skill
- Architecture: HIGH — all patterns derived from locked decisions (D-01..D-11) + verified codebase substrate
- Pitfalls: HIGH — derived from locked decisions + confirmed SDK behavior (400 errors on removed params)
- Krippendorff α formula: MEDIUM — formula confirmed from Wikipedia/academic sources; Elixir implementation assumed no library (web search confirmed no results)
- Bootstrap CI adequacy: MEDIUM — academic sources confirm bootstrap adequate for N≥20

**Research date:** 2026-07-03
**Valid until:** 2026-08-03 (SDK releases frequently; re-check @anthropic-ai/sdk version before implementing)
