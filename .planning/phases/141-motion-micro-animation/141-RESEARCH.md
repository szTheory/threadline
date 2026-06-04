# Phase 141: motion-micro-animation - Research

**Researched:** 2026-06-04
**Domain:** Operator-surface CSS motion governance, reduced-motion contracts, and focused browser verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Auto-Selected Discussion Decisions

- **D-01:** Treat motion as a design-system contract, not as decorative polish. Every animation must have an explicit trigger, JTBD, and token entry.
- **D-02:** Keep the current motion token scale as authoritative: `--tl-motion-fast: 120ms`, `--tl-motion-base: 180ms`, `--tl-motion-slow: 240ms`, `--tl-motion-stagger: 40ms`, `--tl-motion-distance-sm: 8px`, and `--tl-motion-distance-md: 16px`.
- **D-03:** Reuse existing keyframes (`tl-rise-in`, `tl-thread-draw`, `tl-drawer-in`, `tl-fade-in`, `tl-copy-pulse`) unless research proves a narrow need. Do not add ad-hoc one-off keyframes or literal durations.
- **D-04:** Preserve the signature Signal Cyan thread-draw as the branded motion motif. It may appear only where it clarifies a completed path, primary entry, or evidence/proof progression.
- **D-05:** Keep motion GPU-friendly: `opacity` and `transform` are preferred; layout-affecting motion must remain rare and justified.
- **D-06:** `prefers-reduced-motion: reduce` must cover every animation and transition. Prefer a single scoped blanket plus targeted overrides where visual state would otherwise remain transformed.
- **D-07:** Inventory documentation is a deliverable, not optional commentary. It should live under Phase 141 artifacts and be testable against source names/tokens.
- **D-08:** Avoid broad visual redesign. Phase 141 may refine existing animated surfaces but should not change IA, content hierarchy, route behavior, mobile layouts, or export/row-history semantics.
- **D-09:** Browser verification should use focused motion/reduced-motion assertions, not screenshot baselines or broad responsive matrix checks reserved for later phases.

### the agent's Discretion
No separate discretionary section was present in CONTEXT.md. [VERIFIED: codebase grep]

### Deferred Ideas (OUT OF SCOPE)
## Deferred Beyond Phase 141

- Breakpoint scale and broad mobile-first layout work.
- Final accessibility sweep, focus-order audit, and screenshot-diff guard.
- New earned flows, export workflows, or row-history semantics.
- Cross-app theme customization APIs for motion.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLISH-MOTION | Micro-animation is restrained and purposeful: documented inventory maps each animation to trigger, JTBD, and token; every animation has a research-backed rationale; reduced motion is honored; no gratuitous motion remains. [VERIFIED: `.planning/REQUIREMENTS.md`] | Use an inventory artifact plus source-contract tests for token/keyframe drift, reduced-motion coverage, and browser checks for computed default vs reduced motion. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 141 should treat motion as a governed CSS contract in `lib/threadline/operator_surface/style.ex`, not as a new animation layer. [VERIFIED: `lib/threadline/operator_surface/style.ex`] The current implementation already defines authoritative motion tokens, five named keyframes, several shipped animation surfaces, and a scoped reduced-motion blanket. [VERIFIED: codebase grep] The highest-value work is to make those existing surfaces auditable through a `141-MOTION-INVENTORY.md` artifact and source-contract tests that keep CSS, inventory names, tokens, and reduced-motion coverage aligned. [VERIFIED: codebase grep]

The browser side should stay focused. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] The existing Playwright config globally sets `reducedMotion: "reduce"` for deterministic E2E runs, so a Phase 141-specific spec should explicitly opt into `reducedMotion: "no-preference"` for default-motion assertions and compare it with reduced-motion computed styles. [VERIFIED: `examples/threadline_phoenix/e2e/playwright.config.ts`] Playwright supports configuring test options in `use` and the existing config already uses that pattern. [CITED: https://playwright.dev/docs/test-configuration]

**Primary recommendation:** create `141-MOTION-INVENTORY.md`, extend `style_contract_test.exs` with CSS source guards, and add one focused Playwright motion contract spec that verifies named surfaces under `no-preference` and `reduce`. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Motion tokens and keyframes | Browser / Client | Design-system source | CSS custom properties and `@keyframes` live in the embedded operator-surface stylesheet. [VERIFIED: `lib/threadline/operator_surface/style.ex`] |
| Motion inventory artifact | Planning / Design-system contract | Browser / Client | The artifact documents shipped CSS behavior and is testable against source names and tokens. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| Reduced-motion handling | Browser / Client | Playwright verification | `prefers-reduced-motion` is a CSS media feature and Playwright can emulate user preferences. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion] [CITED: https://playwright.dev/docs/test-configuration] |
| Source-contract tests | Test tier / ExUnit | Browser / Client | Existing contract tests read CSS source and assert token/design-system invariants without rendering a browser. [VERIFIED: `test/threadline/operator_surface/style_contract_test.exs`] |
| Focused browser verification | E2E test tier | Browser / Client | Existing E2E specs use Playwright locators, `getByTestId`, route assertions, and no-overflow helpers. [VERIFIED: `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`] |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists at the project root, so there are no additional project-level directives from that file. [VERIFIED: shell test]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| ExUnit | Elixir 1.19.5 / Mix 1.19.5 runtime | Source-contract tests for CSS tokens, keyframes, inventory coverage, and reduced-motion guardrails. [VERIFIED: `elixir --version`, `mix --version`] | Existing test suite uses ExUnit and current `style_contract_test.exs` already follows the source-read contract pattern. [VERIFIED: codebase grep] |
| CSS custom properties + named `@keyframes` | Browser CSS | Motion token governance and animation implementation. [VERIFIED: `lib/threadline/operator_surface/style.ex`] | Current operator surface already centralizes `--tl-motion-*`, easing tokens, and named keyframes in the stylesheet. [VERIFIED: codebase grep] |
| Playwright Test | 1.60.0 installed in example E2E workspace | Focused browser checks for default and reduced motion computed styles. [VERIFIED: `npm list @playwright/test --depth=0`] | Existing E2E workspace already uses Playwright config/projects and focused operator specs. [VERIFIED: `examples/threadline_phoenix/e2e/playwright.config.ts`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| MDN CSS reference | Current docs accessed 2026-06-04 | Validate `prefers-reduced-motion` and discrete transition behavior. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion] [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-behavior] | Use to justify reduced-motion handling and caution around `content-visibility` / `allow-discrete`. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-behavior] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CSS tokens and keyframes | JavaScript animation library | Do not use; Phase 141 context explicitly forbids external animation dependencies and route/state changes. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| Source-contract tests | Screenshot baselines | Do not use; screenshot-diff infrastructure is deferred to Phase 143. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| Focused Playwright computed-style assertions | Broad responsive matrix | Do not use; broad mobile-first layout is deferred to Phase 142. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |

**Installation:** No new packages should be installed for this phase. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`]

## Package Legitimacy Audit

No external packages are recommended for installation in Phase 141, so the package legitimacy gate is not applicable. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`]

## Architecture Patterns

### System Architecture Diagram

```text
CSS source in style.ex
  -> motion tokens (--tl-motion-fast/base/slow/stagger/distance)
  -> named keyframes (tl-rise-in/thread-draw/drawer-in/fade-in/copy-pulse)
  -> shipped selectors (Home, drawers, copy, journey, policy, retention)
  -> reduced-motion media query

Motion inventory artifact
  -> lists selector, trigger, JTBD/persona, keyframe, token, reduced-motion expectation
  -> source-contract tests verify names/tokens/selectors stay aligned

Focused Playwright spec
  -> default project override: reducedMotion "no-preference"
  -> reduced project/default: reducedMotion "reduce"
  -> computed style assertions for representative surfaces
```

### Recommended Project Structure

```text
.planning/phases/141-motion-micro-animation/
├── 141-CONTEXT.md              # existing phase boundary and locked decisions
├── 141-RESEARCH.md             # this research artifact
└── 141-MOTION-INVENTORY.md     # planned deliverable: source-testable motion inventory

test/threadline/operator_surface/
└── style_contract_test.exs     # extend with motion token/keyframe/inventory contracts

examples/threadline_phoenix/e2e/tests/
└── operator-motion.spec.ts     # add focused computed-style browser verification
```

### Pattern 1: Motion Inventory as Contract

**What:** Add `141-MOTION-INVENTORY.md` with one row per shipped animation or transition family. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`]

**When to use:** Every selector with `animation:`, every named `@keyframes`, and every meaningful transition family that affects visual state should be represented or explicitly justified as a generic control transition. [VERIFIED: codebase grep]

**Required columns:** `Inventory ID`, `Selector`, `Trigger`, `JTBD / Persona`, `Keyframe or transition`, `Token(s)`, `Reduced-motion behavior`, `Rationale`, `Source anchor`. [ASSUMED]

**Initial inventory seeds from current source:** Home card rise, Home primary thread draw, policy details expansion, subview drawer entrance, retention run rise, subview timeline stagger, record/transaction fade, copy pulse, journey thread draw, policy success thread draw, policy chevron rotation, generic control transition. [VERIFIED: codebase grep]

### Pattern 2: Source-Contract CSS Governance

**What:** Extend `style_contract_test.exs` with narrow string/regex tests that parse `style.ex` and reject duration/keyframe drift. [VERIFIED: `test/threadline/operator_surface/style_contract_test.exs`]

**When to use:** Use ExUnit for static invariants: required token names/values, allowed keyframe names, no literal `120ms|180ms|240ms` outside token definitions and approved thread-draw delay, no uninventoryed `animation:` selectors, and one scoped `@media (prefers-reduced-motion: reduce)` block covering `animation-duration`, `animation-delay`, `transition-duration`, and `animation-iteration-count`. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: existing source-contract pattern in test/threadline/operator_surface/style_contract_test.exs
src = File.read!(@style_path)
assert String.contains?(src, "--tl-motion-base: 180ms;")
assert String.contains?(src, "@media (prefers-reduced-motion: reduce)")
refute Regex.match?(~r/animation:\s*[^;]*(?<!var\()180ms/, src)
```

### Pattern 3: Focused Computed-Style Browser Checks

**What:** Add a Playwright spec that inspects computed CSS on representative surfaces instead of taking visual baselines. [VERIFIED: existing Playwright pattern]

**When to use:** Use for behavior that a static source test cannot prove, especially `prefers-reduced-motion` application in a real browser context. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion]

**Example:**

```typescript
// Source: Playwright config supports use options; existing suite uses page locators.
test.use({ reducedMotion: "no-preference" });

const card = page.locator(".tl-home__card").first();
await expect(card).toBeVisible();
await expect
  .poll(() => card.evaluate((el) => getComputedStyle(el).animationName))
  .toContain("tl-rise-in");
```

### Anti-Patterns to Avoid

- **Adding one-off keyframes:** Phase context locks reuse of existing keyframes unless a narrow need is proven. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`]
- **Literal timing drift:** Timings should flow through `--tl-motion-fast`, `--tl-motion-base`, `--tl-motion-slow`, and `--tl-motion-stagger`; the current source has an approved `120ms` thread-draw delay that should be explicitly governed if retained. [VERIFIED: codebase grep]
- **Animating timeline pagination rows:** Current CSS comment says the high-traffic timeline stream is deliberately not animated. [VERIFIED: `lib/threadline/operator_surface/style.ex`]
- **Snapshot-first validation:** Screenshot baselines are out of phase scope. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Motion runtime | Custom JS scheduler or animation lifecycle | Existing CSS tokens/keyframes | Current motion is pure CSS and phase context forbids external animation libraries. [VERIFIED: codebase grep] |
| Reduced-motion detection | Custom JS `matchMedia` plumbing | CSS `@media (prefers-reduced-motion: reduce)` plus Playwright emulation | CSS media feature is the web-standard reduced-motion hook. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion] |
| Browser motion verification | Screenshot diff harness | Playwright computed-style assertions | Phase 143 owns screenshot-diff infrastructure; Playwright already runs focused operator UAT. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| Inventory enforcement | Manual checklist only | ExUnit source-contract checks | Existing project already uses source-contract tests for design-system invariants. [VERIFIED: `test/threadline/operator_surface/style_contract_test.exs`] |

**Key insight:** The implementation risk is not missing animation capability; the risk is unmanaged drift between CSS, rationale, reduced-motion behavior, and test coverage. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Global Reduced Motion Hides Default Motion Regressions

**What goes wrong:** The existing Playwright config sets `reducedMotion: "reduce"` globally, so E2E tests can pass while default-motion styles drift. [VERIFIED: `examples/threadline_phoenix/e2e/playwright.config.ts`]

**Why it happens:** Reduced-motion makes timing deterministic, but it also collapses animation durations. [VERIFIED: codebase grep]

**How to avoid:** Add explicit Phase 141 tests that opt into `reducedMotion: "no-preference"` for default computed-style checks and use the default reduced config for reduced-motion checks. [CITED: https://playwright.dev/docs/test-configuration]

**Warning signs:** Browser tests only assert visibility/navigation and never inspect `animationName`, `animationDuration`, `transitionDuration`, or `transform`. [VERIFIED: codebase grep]

### Pitfall 2: Reduced Motion Shortens But Leaves Transform State Ambiguous

**What goes wrong:** A blanket `animation-duration: 1ms` may still briefly apply transform-based start states, which can be visible or measurable if a test samples too early. [VERIFIED: codebase grep] MDN notes reduced motion should remove, reduce, or replace motion-based animations. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion]

**Why it happens:** Existing keyframes start with transforms for rise/drawer/thread-draw and the blanket does not set `animation-name: none`. [VERIFIED: `lib/threadline/operator_surface/style.ex`]

**How to avoid:** Prefer assertions after visibility settles; add targeted reduced-motion overrides only where a final visual state could remain transformed or visually clipped. [ASSUMED]

**Warning signs:** Reduced-motion browser assertions see `matrix(...)` transforms or `scaleX(0)` on visible thread surfaces after page settle. [ASSUMED]

### Pitfall 3: Layout-Affecting Details Transition Has Browser Nuance

**What goes wrong:** `block-size` plus `content-visibility allow-discrete` can behave differently from transform/opacity motion. [VERIFIED: codebase grep] MDN documents `allow-discrete` as a discrete transition behavior and notes browser support may vary by feature. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-behavior]

**Why it happens:** Details expansion is intentionally a progressive enhancement in current CSS comments. [VERIFIED: `lib/threadline/operator_surface/style.ex`]

**How to avoid:** Keep this as a justified exception in inventory, retain reduced-motion coverage for `.tl-policy__row::details-content`, and avoid adding more layout-affecting transitions. [VERIFIED: codebase grep]

**Warning signs:** Additional `block-size`, `height`, `width`, or positional transitions appear outside the policy details exception. [VERIFIED: codebase grep]

### Pitfall 4: Inventory Drifts from Source

**What goes wrong:** Documentation names an animation that no longer exists or omits a new `animation:` rule. [ASSUMED]

**Why it happens:** Markdown inventory is not automatically tied to CSS selectors unless the source-contract test reads both files. [ASSUMED]

**How to avoid:** Make inventory IDs and selectors source-testable; the test should read both `style.ex` and `141-MOTION-INVENTORY.md`. [ASSUMED]

**Warning signs:** New CSS `animation:` appears without an inventory row in the same PR. [ASSUMED]

## Code Examples

### Source-Contract Inventory Coverage

```elixir
# Source: existing ExUnit source-read style in style_contract_test.exs
@inventory_path ".planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md"

test "motion inventory covers shipped animation selectors" do
  css = File.read!(@style_path)
  inventory = File.read!(@inventory_path)

  for selector <- [".tl-home__card", ".tl-subview", ".tl-copy.is-copied"] do
    assert String.contains?(css, selector)
    assert String.contains?(inventory, selector)
  end
end
```

### Token and Keyframe Allowlist

```elixir
# Source: existing CSS strings in lib/threadline/operator_surface/style.ex
allowed_keyframes = ~w(tl-drawer-in tl-rise-in tl-thread-draw tl-fade-in tl-copy-pulse)
actual_keyframes = Regex.scan(~r/@keyframes\s+([a-z0-9-]+)/, src, capture: :all_but_first) |> List.flatten()
assert Enum.sort(actual_keyframes) == Enum.sort(allowed_keyframes)
```

### Reduced-Motion Browser Assertion

```typescript
// Source: Playwright Test config/use pattern in examples/threadline_phoenix/e2e/playwright.config.ts
test.use({ reducedMotion: "reduce" });

test("operator motion collapses under reduced motion", async ({ page }) => {
  await login(page);
  await page.goto("/audit");

  const duration = await page.locator(".tl-home__card").first().evaluate((el) => {
    return getComputedStyle(el).animationDuration;
  });

  expect(duration).toBe("0.001s");
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Untracked decorative CSS motion | Tokenized, inventory-backed motion contract | Phase 141 target state [VERIFIED: `.planning/ROADMAP.md`] | Planner should prioritize documentation and tests before any CSS changes. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| Pixel screenshots for visual confidence | Computed-style assertions for motion contracts | Phase 141 boundary [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] | Avoids Phase 143 screenshot-diff scope. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| High-frequency row entrance motion | No animation for high-traffic timeline stream | Existing CSS comment [VERIFIED: `lib/threadline/operator_surface/style.ex`] | Preserve scan speed and avoid operational distraction. [VERIFIED: `lib/threadline/operator_surface/style.ex`] |

**Deprecated/outdated:**

- Adding animation libraries for this phase is out of scope; use CSS tokens/keyframes already present. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`]
- Broad screenshot baselines are out of scope until Phase 143. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Inventory should use columns `Inventory ID`, `Selector`, `Trigger`, `JTBD / Persona`, `Keyframe or transition`, `Token(s)`, `Reduced-motion behavior`, `Rationale`, `Source anchor`. | Architecture Patterns | Planner may choose a different artifact shape; risk is low if required mapping remains testable. |
| A2 | Reduced-motion tests should wait for visibility/page settle before sampling computed transforms. | Common Pitfalls | Early sampling could produce flaky assertions. |
| A3 | Markdown inventory drift should be prevented by reading both CSS and inventory from ExUnit. | Common Pitfalls / Code Examples | If planner rejects cross-file contract tests, inventory may become manual-only. |

## Open Questions

1. **Should the approved `120ms` thread-draw delay become a token?**
   - What we know: Current thread-draw usages include `120ms` as a delay while motion token definitions also use `120ms` for `--tl-motion-fast`. [VERIFIED: codebase grep]
   - What's unclear: D-02 locks timing tokens but does not explicitly say whether animation delays must use only `var(--tl-motion-fast)`. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`]
   - Recommendation: Prefer replacing the literal delay with `var(--tl-motion-fast)` or explicitly allowlist that delay in the source-contract test. [ASSUMED]

2. **Should generic control transitions appear as one inventory row or many?**
   - What we know: The CSS has generic transitions for buttons/links/controls and specific motion animations for surfaces. [VERIFIED: codebase grep]
   - What's unclear: The phase asks every animation to be inventoried; generic transition families may be better documented as one reusable pattern. [ASSUMED]
   - Recommendation: Inventory generic control transitions as a single "control feedback transition" row and require all future generic transitions to use `--tl-transition-fast`. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit source-contract tests | Yes [VERIFIED: `elixir --version`] | 1.19.5 | None needed |
| Mix | Test runner | Yes [VERIFIED: `mix --version`] | 1.19.5 | None needed |
| Node.js | Playwright E2E workspace | Yes [VERIFIED: `node --version`] | v22.14.0 | None needed |
| npm | Playwright E2E workspace | Yes [VERIFIED: `npm --version`] | 11.1.0 | None needed |
| @playwright/test | Browser verification | Yes [VERIFIED: `npm list @playwright/test --depth=0`] | 1.60.0 | None needed |
| Context7 CLI | Documentation lookup fallback | No [VERIFIED: `command -v ctx7`] | — | Official web docs used instead |

**Missing dependencies with no fallback:** None. [VERIFIED: environment probes]

**Missing dependencies with fallback:** Context7 CLI is missing; official MDN and Playwright docs were used as fallback. [VERIFIED: environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5; Playwright Test 1.60.0. [VERIFIED: environment probes] |
| Config file | ExUnit uses project Mix config; Playwright config is `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/operator_surface/style_contract_test.exs` [VERIFIED: executed 2026-06-04, 8 tests, 0 failures] |
| Focused browser command | `cd examples/threadline_phoenix/e2e && npm test -- tests/operator-motion.spec.ts --project=desktop-chromium` [ASSUMED] |
| Full suite command | `mix test` plus relevant E2E command when Phoenix example server is running. [ASSUMED] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| POLISH-MOTION | Motion inventory maps selector -> trigger -> JTBD -> token -> reduced-motion behavior. [VERIFIED: `.planning/ROADMAP.md`] | source-contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | Existing file yes; inventory file no, Wave 0. [VERIFIED: codebase grep] |
| POLISH-MOTION | Motion tokens stay authoritative and keyframes stay allowlisted. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] | source-contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | Existing file yes; new tests needed. [VERIFIED: codebase grep] |
| POLISH-MOTION | Reduced motion is honored on representative animated surfaces. [VERIFIED: `.planning/ROADMAP.md`] | browser | `cd examples/threadline_phoenix/e2e && npm test -- tests/operator-motion.spec.ts --project=desktop-chromium` | No, Wave 0. [VERIFIED: codebase grep] |
| POLISH-MOTION | No gratuitous high-frequency motion is added. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] | source-contract | `mix test test/threadline/operator_surface/style_contract_test.exs` | Existing file yes; new tests needed. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/operator_surface/style_contract_test.exs` [VERIFIED: executed 2026-06-04]
- **Per wave merge:** `mix test test/threadline/operator_surface/style_contract_test.exs` plus focused `operator-motion.spec.ts` once created and server is available. [ASSUMED]
- **Phase gate:** Source-contract tests green, focused Playwright motion spec green, and manual check that `141-MOTION-INVENTORY.md` lists every shipped motion surface. [ASSUMED]

### Wave 0 Gaps

- [ ] `.planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` - covers POLISH-MOTION inventory requirement. [VERIFIED: file absent]
- [ ] Additional tests in `test/threadline/operator_surface/style_contract_test.exs` - covers token/keyframe/inventory/reduced-motion source contracts. [VERIFIED: existing file lacks motion-specific tests]
- [ ] `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` - covers focused browser reduced-motion/default-motion assertions. [VERIFIED: file absent]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | Phase does not change auth behavior. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| V3 Session Management | No | Phase does not change sessions. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| V4 Access Control | No | Phase does not change route access or authorization. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| V5 Input Validation | No | Phase does not add input parsing. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| V6 Cryptography | No | Phase does not add cryptography. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |

### Known Threat Patterns for Operator-Surface Motion

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Motion change accidentally alters hidden/visible state | Tampering | Restrict Phase 141 to CSS motion and computed-style assertions; no route/state changes. [VERIFIED: `.planning/phases/141-motion-micro-animation/141-CONTEXT.md`] |
| Motion obscures evidence or delays triage | Denial of Service | Preserve scan density, avoid loops, and keep high-frequency timeline rows unanimated. [VERIFIED: `lib/threadline/operator_surface/style.ex`] |
| Reduced-motion preference ignored | Information Disclosure / DoS user harm | Use `@media (prefers-reduced-motion: reduce)` coverage and browser emulation tests. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion] |

## Sources

### Primary (HIGH confidence)

- `lib/threadline/operator_surface/style.ex` - motion tokens, keyframes, shipped animation selectors, reduced-motion block. [VERIFIED: codebase grep]
- `test/threadline/operator_surface/style_contract_test.exs` - existing source-contract test pattern. [VERIFIED: codebase grep]
- `examples/threadline_phoenix/e2e/playwright.config.ts` - Playwright setup and global reduced-motion configuration. [VERIFIED: codebase grep]
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` and related specs - locator/helper style for focused browser UAT. [VERIFIED: codebase grep]
- `.planning/phases/141-motion-micro-animation/141-CONTEXT.md` - phase boundary and locked decisions. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` - Phase 141 and POLISH-MOTION requirement text. [VERIFIED: codebase grep]
- MDN `prefers-reduced-motion` docs - CSS reduced-motion semantics and user preference behavior. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion]
- MDN `transition-behavior` docs - discrete transition behavior and `allow-discrete`. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-behavior]
- Playwright configuration docs - config `use`, projects, baseURL, and test configuration pattern. [CITED: https://playwright.dev/docs/test-configuration]

### Secondary (MEDIUM confidence)

- Playwright installed package version from local npm workspace. [VERIFIED: `npm list @playwright/test --depth=0`]

### Tertiary (LOW confidence)

- None. [VERIFIED: sources review]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - existing stack is already present and version-probed locally. [VERIFIED: environment probes]
- Architecture: HIGH - phase scope maps directly to current CSS source, ExUnit contract tests, and Playwright E2E setup. [VERIFIED: codebase grep]
- Pitfalls: MEDIUM - local pitfalls are verified; timing/flakiness guidance includes limited assumptions about browser sampling behavior. [VERIFIED: codebase grep] [ASSUMED]

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for local architecture; re-check Playwright and MDN docs if browser verification APIs change. [ASSUMED]
