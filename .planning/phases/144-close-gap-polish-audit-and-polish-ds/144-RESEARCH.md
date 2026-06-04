# Phase 144: Close gap: POLISH-AUDIT and POLISH-DS - Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView operator-surface design-system closure and GSD traceability repair
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Baseline Audit Ledger Closure

- **D-01:** Close `POLISH-AUDIT` through an explicit Phase 144 closure/errata record that verifies the existing Phase 134-labeled baseline artifacts against the original Phase 134 success criteria.
- **D-02:** Do not fabricate a missing Phase 134 execution history. If any Phase 134 backfill artifact is created, it must be labeled as reconstructed/verified during Phase 144, not as original in-time phase work.
- **D-03:** Preserve the original roadmap intent that Phase 134 produced the baseline for downstream phases. Do not rewrite history so the baseline concept appears to have originated in Phase 144.
- **D-04:** Bind the closure record to concrete evidence: `v1.31-UI-AUDIT.md`, the 24 baseline screenshots, the 24 final screenshots, `143-SCREENSHOT-DIFF.md`, `143-AUDIT-CLOSURE.md`, and the milestone audit gap.
- **D-05:** Update requirement/roadmap/state traceability only enough to make the closure legible: `POLISH-AUDIT` is satisfied by Phase 144 verification of Phase 134 baseline artifacts.

### Design-System Freeze Contract

- **D-06:** Close `POLISH-DS` with source-first final consolidation followed by documentation and freeze, not documentation-only freeze of accidental drift.
- **D-07:** Keep the architecture aligned with the existing Phoenix-optional mounted operator surface: BEM `.tl-*` classes and `--tl-*` tokens in `lib/threadline/operator_surface/style.ex`; no Tailwind, no build step, no light/system theme, no external design-system dependency.
- **D-08:** Finish the missing design-system source of truth at `.planning/milestones/v1.31-DESIGN-SYSTEM.md`. It must catalog canonical, deprecated, and consolidated `.tl-*` classes; token scales; status/verdict/operation color semantics; action hierarchy; empty/error states; table/responsive rules; copy affordances; drawer/subview patterns; motion; focus/accessibility rules; and anti-patterns.
- **D-09:** The token freeze must be explicit and test-backed. Strengthen `test/threadline/operator_surface/style_contract_test.exs` with narrow source contracts for the frozen token/class catalog rather than broad brittle screenshot/prose assertions.
- **D-10:** Final source consolidation should be narrow and compatibility-preserving. Prefer consolidating status/verdict/chip roles, value/KV/diff/copy primitives, and docs/tests over introducing a public Phoenix component API.
- **D-11:** A formal reusable component API is deferred. Phoenix function components with attrs/slots are idiomatic when reusable markup becomes public API, but Phase 144 should not turn the mounted `/audit` surface into a general UI component library.

### Ecosystem And Prompt-Corpus Guidance

- **D-12:** Treat verification as a product surface. Three-source traceability should align: requirements checkbox, verification record, and summary/frontmatter evidence.
- **D-13:** Keep Threadline native to Phoenix/Ecto/PostgreSQL: explicit docs, SQL-readable operator language, stable `mix verify.*` entrypoints, and example-app/browser proof over hidden ceremony.
- **D-14:** Preserve the Threadline brand promise: "follow what happened." The close-gap artifacts should make baseline evidence, design-system contracts, and final UI deltas followable without maintainer memory.
- **D-15:** Use persona/JTBD artifacts to explain why existing primitives and flows are frozen, not to add new flows. Phase 140 already shipped the earned flow set.
- **D-16:** Accessible dark-first behavior is part of the design system. The catalog must encode contrast, focus-visible, ARIA/non-color status encoding, reduced motion, and least-surprise hover/focus/disabled states as normative rules.

### Folded Todos

- **Capture direct demo and UI polish** (`2026-06-01-capture-direct-demo-and-ui-polish.md`) is folded as context only. The relevant baseline is now the v1.31 polish milestone and Phase 144 should reconcile remaining audit/design-system deltas without widening product scope.

### the agent's Discretion

Downstream planner may choose exact plan slicing, but should bias to:

- one audit-ledger closure slice for `POLISH-AUDIT`;
- one design-system source/catalog/freeze slice for `POLISH-DS`;
- one verification/metadata slice that reruns the milestone audit and updates requirement status cleanly.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- A formal public Phoenix component API for Threadline operator primitives. Useful later if the UI primitives become a host-facing extension surface, but too broad for Phase 144.
- Light/system theme support. Explicitly out of scope for v1.31 and contrary to the locked dark-first brand.
- New earned flows beyond EF1-EF5. Existing Phase 140 flow set remains authoritative.
- Broader true-empty/scoped seed variants (`F-205`) and snapshot delta-highlighting (`F-1004`) remain future product enhancements, not blockers for this close-gap phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLISH-AUDIT | Objective baseline screenshot set plus `v1.31-UI-AUDIT.md` state matrix, touchpoint inventory, ranked findings, and downstream traceability. [VERIFIED: `.planning/REQUIREMENTS.md`] | Phase 144 should create a Phase 144 closure/errata verification that proves the existing Phase 134-labeled audit artifacts satisfy the original Phase 134 success criteria, without inventing a missing Phase 134 execution record. [VERIFIED: `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-CONTEXT.md`, `.planning/v1.31-MILESTONE-AUDIT.md`] |
| POLISH-DS | Token scales formalized, `.tl-*` class catalog documented in `v1.31-DESIGN-SYSTEM.md`, shared primitives unified, and token scale frozen. [VERIFIED: `.planning/REQUIREMENTS.md`] | Phase 144 should finish source-first consolidation in `style.ex` / `presentation.ex`, create the catalog/freeze doc, strengthen `style_contract_test.exs`, then re-verify Phase 136/Phase 144 closure. [VERIFIED: `.planning/phases/136-design-system-hardening/136-VERIFICATION.md`, `lib/threadline/operator_surface/style.ex`, `test/threadline/operator_surface/style_contract_test.exs`] |
</phase_requirements>

## Summary

Phase 144 is a traceability and contract-completion phase, not a new UI feature phase. The milestone audit found `POLISH-AUDIT` orphaned because the Phase 134 ledger/verification record is absent, even though the baseline audit doc and screenshot corpus exist; it found `POLISH-DS` unsatisfied because Phase 136 verification is partial, `v1.31-DESIGN-SYSTEM.md` is missing, and the token/class freeze is not test-backed. [VERIFIED: `.planning/v1.31-MILESTONE-AUDIT.md`]

The implementation should be source-first and narrow: verify the existing baseline artifacts as Phase 144 errata, finish the local `.tl-*` / `--tl-*` design-system catalog from actual source, add freeze contracts to `style_contract_test.exs`, and update requirement/roadmap/state traceability only enough to make the closure auditable. [VERIFIED: `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-CONTEXT.md`, `lib/threadline/operator_surface/style.ex`, `test/threadline/operator_surface/style_contract_test.exs`]

**Primary recommendation:** Plan three slices: audit-ledger errata closure, design-system source/catalog/freeze, and final verification/metadata/milestone-audit rerun. [VERIFIED: `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-CONTEXT.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Baseline audit closure | Planning/docs | Browser proof | The gap is missing phase-ledger verification, while the evidence is planning docs plus baseline/final screenshots. [VERIFIED: `.planning/v1.31-MILESTONE-AUDIT.md`] |
| Design-system token/class freeze | Library source | Tests/docs | Tokens/classes are emitted by `Threadline.OperatorSurface.Style`; freeze belongs in source contracts and catalog docs. [VERIFIED: `lib/threadline/operator_surface/style.ex`, `test/threadline/operator_surface/style_contract_test.exs`] |
| Primitive consolidation | Library source | LiveView call sites | Shared presentation helpers and CSS primitives already serve polished screens; changes should consolidate local classes/helpers, not introduce backend or route behavior. [VERIFIED: `lib/threadline/operator_surface/presentation.ex`, `lib/threadline/operator_surface/style.ex`] |
| Screenshot evidence | Example Phoenix browser tier | Planning/docs | Durable capture/regression specs live in the Phoenix example E2E suite and write evidence into `.planning/milestones`. [VERIFIED: `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts`, `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts`] |
| Requirement traceability | Planning/docs | Verification commands | Threadline planning convention uses requirements, verification, and summary frontmatter as aligned evidence. [VERIFIED: `.planning/conventions/summary-frontmatter.md`, `prompts/threadline-elixir-oss-dna.md`] |

## Project Constraints (from AGENTS.md)

No root `AGENTS.md` exists in `/Users/jon/projects/threadline`; only `examples/threadline_phoenix/AGENTS.md` was found. [VERIFIED: `rg --files -g 'AGENTS.md'`]

If Phase 144 edits or runs work under `examples/threadline_phoenix`, honor these subtree directives: use `mix precommit` when all changes are done; use the existing `Req` library for HTTP requests and avoid `httpoison`, `tesla`, and `httpc`; follow Phoenix 1.8 LiveView/layout/input/icon guidance; avoid `String.to_atom/1` on user input; use `start_supervised!/1` in tests; avoid `Process.sleep/1` in tests. [VERIFIED: `examples/threadline_phoenix/AGENTS.md`]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.7 | Example host and Phoenix integration substrate. [VERIFIED: `mix deps`] | Existing project dependency; no new web framework is needed. [VERIFIED: `mix deps`, `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-CONTEXT.md`] |
| Phoenix LiveView | 1.1.30 locked locally; official docs currently show 1.1.31. [VERIFIED: `mix deps`; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] | Mounted operator surface rendering and optional future function-component API. [VERIFIED: codebase grep; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] | Official docs define reusable HEEx function components with attrs/slots; Phase 144 should not introduce a public component API unless later scope changes. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html; VERIFIED: 144-CONTEXT.md] |
| ExUnit | Mix 1.19.5 / Elixir toolchain | Source contract and operator-surface tests. [VERIFIED: `mix --version`, `mix.exs`] | Existing `style_contract_test.exs` already verifies token, motion, responsive, and accessibility contracts. [VERIFIED: `test/threadline/operator_surface/style_contract_test.exs`] |
| Playwright `@playwright/test` | 1.60.0 installed in example E2E tree | Browser screenshot capture and regression guard. [VERIFIED: `npm ls --depth=0`] | Existing specs capture the durable 24-image matrix and representative regression snapshots. [VERIFIED: `operator-screenshots.spec.ts`, `operator-screenshot-regression.spec.ts`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| PostgreSQL client/server | `psql` 14.17 client available | Example app database for browser verification. [VERIFIED: environment probe] | Needed when rerunning `mix verify.example_browser` or screenshot capture. [VERIFIED: `mix.exs`, `operator-screenshots.spec.ts`] |
| GSD SDK | available via `gsd-sdk query` | Phase init, milestone audit, commit helper. [VERIFIED: `gsd-sdk query init.phase-op 144`] | Use for final milestone-audit rerun and optional docs commit. [VERIFIED: GSD init output] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Local `.tl-*` / `--tl-*` catalog | Tailwind, shadcn, CSS-in-JS, external design-system dependency | Explicitly forbidden for Phase 144 and would widen architecture/build scope. [VERIFIED: 144-CONTEXT.md] |
| Source-contract tests | Broad screenshot/prose assertions | Context locks narrow source contracts because screenshots are better as representative regression guards, not token freeze contracts. [VERIFIED: 144-CONTEXT.md, `style_contract_test.exs`] |
| Public Phoenix component API | Function components with attrs/slots | Officially idiomatic for reusable markup, but locked as deferred because Phase 144 is closing the mounted operator-surface contract, not exposing a UI library. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html; VERIFIED: 144-CONTEXT.md] |

**Installation:** No external packages should be installed for Phase 144. [VERIFIED: 144-CONTEXT.md, `mix deps`, `examples/threadline_phoenix/e2e/package.json`]

## Package Legitimacy Audit

No new external packages are recommended or required. Package legitimacy gate is not applicable. [VERIFIED: 144-CONTEXT.md, local dependency inventory]

## Architecture Patterns

### System Architecture Diagram

```text
Milestone audit gap report
  -> Phase 144 plan
    -> Audit ledger closure
       -> verify v1.31-UI-AUDIT.md
       -> verify 24 baseline PNGs + 24 final PNGs
       -> bind 143 screenshot diff + audit closure
       -> produce Phase 144 errata/closure proof
    -> Design-system closure
       -> inspect style.ex + presentation.ex consumers
       -> narrow primitive consolidation, if source drift remains
       -> write v1.31-DESIGN-SYSTEM.md catalog/freeze
       -> strengthen style_contract_test.exs
    -> Verification / traceability
       -> run focused ExUnit contracts
       -> run relevant browser/screenshot guard
       -> update REQUIREMENTS / ROADMAP / STATE truthfully
       -> rerun milestone audit until POLISH-AUDIT and POLISH-DS pass
```

### Recommended Project Structure

```text
.planning/
├── milestones/
│   ├── v1.31-UI-AUDIT.md              # existing Phase 134-labeled baseline evidence
│   ├── v1.31-DESIGN-SYSTEM.md         # create/finalize in Phase 144
│   └── v1.31-screenshots/{baseline,final}/
├── phases/144-close-gap-polish-audit-and-polish-ds/
│   ├── 144-RESEARCH.md
│   ├── 144-*-PLAN.md
│   ├── 144-*-SUMMARY.md               # use requirements-completed, hyphenated
│   ├── 144-AUDIT-ERRATA.md            # recommended closure artifact
│   └── 144-VERIFICATION.md
lib/threadline/operator_surface/
├── style.ex                           # token/class source of truth
└── presentation.ex                    # shared display helpers
test/threadline/operator_surface/
└── style_contract_test.exs            # freeze contracts
```

### Pattern 1: Errata Closure, Not History Fabrication

**What:** Create a Phase 144 closure artifact that says the Phase 134 baseline artifacts were reconstructed/verified during Phase 144, then map `POLISH-AUDIT` closure to that proof. [VERIFIED: 144-CONTEXT.md]

**When to use:** Use when evidence exists but the original phase ledger/verification record is missing. [VERIFIED: `.planning/v1.31-MILESTONE-AUDIT.md`]

**Example:**

```markdown
## Phase 144 Audit Errata

This is not an original Phase 134 execution record. It verifies during Phase 144
that the existing Phase 134-labeled baseline artifacts satisfy the original
Phase 134 success criteria.
```

### Pattern 2: Source-First Design-System Freeze

**What:** Inventory actual `--tl-*` tokens and `.tl-*` classes from `style.ex`, reconcile narrow source drift, document canonical/deprecated/consolidated classes in `v1.31-DESIGN-SYSTEM.md`, then freeze with tests. [VERIFIED: `style.ex`, `style_contract_test.exs`, 144-CONTEXT.md]

**When to use:** Use because the Phase 136 gap is missing catalog/freeze evidence, not lack of an external design-system package. [VERIFIED: `136-VERIFICATION.md`]

**Example:**

```elixir
# Source-contract style: narrow frozen contract, not prose/screenshot parsing.
for token <- [
  "--tl-color-bg: #0B1020;",
  "--tl-control-height: 40px;",
  "--tl-motion-fast: 120ms;"
] do
  assert String.contains?(src, token), "missing frozen token #{token}"
end
```

### Pattern 3: Preserve Phoenix-Optional Boundary

**What:** Keep operator UI CSS under `.threadline-ui`, emitted by `Threadline.OperatorSurface.Style`, with Phoenix LiveView optionality intact. [VERIFIED: `style.ex`]

**When to use:** Always in Phase 144; no backend schema, route, build, Tailwind, light-mode, or public component-library expansion is allowed. [VERIFIED: 144-CONTEXT.md]

### Anti-Patterns to Avoid

- **Retroactive Phase 134 fiction:** Do not create files that pretend to be original Phase 134 execution history. [VERIFIED: 144-CONTEXT.md]
- **Documentation-only token freeze:** Do not declare `POLISH-DS` complete without source contracts proving the frozen catalog. [VERIFIED: 136-VERIFICATION.md, 144-CONTEXT.md]
- **Component API expansion:** Official Phoenix function components are useful for public reusable markup, but Phase 144 defers that API. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html; VERIFIED: 144-CONTEXT.md]
- **LiveComponent for DOM-only reuse:** Phoenix docs say to prefer function components and avoid LiveComponents merely for code organization. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html]
- **New product or demo behavior:** New routes, backend queries, schemas, demo business logic, earned flows, Tailwind, light mode, and theme toggles are out of scope. [VERIFIED: 144-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token/class extraction | A one-off manual list from memory | `rg -o -- "--tl-[a-z0-9-]+"` and `.tl-*` grep over `style.ex` / operator surface | The catalog must reflect source truth, not recollection. [VERIFIED: local grep] |
| Visual regression contract | New screenshot diff engine | Existing Playwright `toHaveScreenshot` guard | The guard is already wired through `mix verify.example_browser`. [VERIFIED: `operator-screenshot-regression.spec.ts`, `mix.exs`] |
| Source freeze harness | New test framework | Existing ExUnit `style_contract_test.exs` helpers | Current tests already parse CSS sections, media layers, color contrast, motion inventory, and selectors. [VERIFIED: `style_contract_test.exs`] |
| Public UI component library | New Phoenix components/API | Local `.tl-*` classes and `presentation.ex` helpers | Component API is deferred; source consolidation can stay compatibility-preserving. [VERIFIED: 144-CONTEXT.md] |

**Key insight:** The hard problem is provenance discipline: close the two gaps with evidence and contracts, not with fresh product surface area. [VERIFIED: `.planning/v1.31-MILESTONE-AUDIT.md`, 144-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Satisfying POLISH-AUDIT by Rewriting History

**What goes wrong:** A planner creates a fake Phase 134 ledger or marks Phase 134 as executed after the fact. [VERIFIED: 144-CONTEXT.md]
**Why it happens:** The milestone audit names Phase 134 as missing, which invites reconstruction instead of errata. [VERIFIED: `.planning/v1.31-MILESTONE-AUDIT.md`]
**How to avoid:** Label any closure artifact as Phase 144 verification of Phase 134-labeled baseline evidence. [VERIFIED: 144-CONTEXT.md]
**Warning signs:** New files under a fabricated `134-*` directory without "reconstructed/verified during Phase 144" language. [ASSUMED]

### Pitfall 2: Freezing Drift Instead of Source Truth

**What goes wrong:** `v1.31-DESIGN-SYSTEM.md` documents the current visual state but tests do not prevent token/class drift. [VERIFIED: 136-VERIFICATION.md]
**Why it happens:** The existing Phase 136 doc was a UI spec, not a final catalog/freeze. [VERIFIED: `136-UI-SPEC.md`, `136-VERIFICATION.md`]
**How to avoid:** Inventory actual `--tl-*` and `.tl-*` names; codify canonical/deprecated/consolidated classes and token scales; add narrow ExUnit source contracts. [VERIFIED: local grep, 144-CONTEXT.md]
**Warning signs:** `POLISH-DS` marked complete without new assertions in `style_contract_test.exs`. [ASSUMED]

### Pitfall 3: Broad Browser Proof Where Source Contracts Are Needed

**What goes wrong:** Planner leans on screenshots to prove token freeze. [VERIFIED: 144-CONTEXT.md]
**Why it happens:** Phase 143 screenshot guard is strong, but it guards representative UI output rather than class/token catalog completeness. [VERIFIED: `143-VERIFICATION.md`, `operator-screenshot-regression.spec.ts`]
**How to avoid:** Use screenshots for regression confidence and source tests for freeze contracts. [VERIFIED: 144-CONTEXT.md]
**Warning signs:** No tests asserting frozen token scale, semantic color map, or canonical primitive families. [ASSUMED]

### Pitfall 4: Underscore `requirements_completed` Frontmatter

**What goes wrong:** New Phase 144 summaries repeat Phase 136's deprecated underscore field. [VERIFIED: `136-01-SUMMARY.md`, `.planning/conventions/summary-frontmatter.md`]
**Why it happens:** Historical files contain both styles. [VERIFIED: codebase grep]
**How to avoid:** Use hyphenated `requirements-completed` in new SUMMARY frontmatter. [VERIFIED: `.planning/conventions/summary-frontmatter.md`]
**Warning signs:** `rg 'requirements_completed' .planning/phases/144-*` matches after execution. [ASSUMED]

## Code Examples

### Source Inventory Commands

```bash
rg -o -- "--tl-[a-z0-9-]+" lib/threadline/operator_surface/style.ex | sort -u
rg -o "\\.tl-[a-zA-Z0-9_-]+" lib/threadline/operator_surface/style.ex lib/threadline/operator_surface -g '*.ex' | sort -u
```

These commands found token scales for color, typography, spacing, radius, shadow, z-index, controls, breakpoints, motion, focus, table, drawer, and responsive primitives. [VERIFIED: local grep]

### Existing Freeze Test Shape

```elixir
src = File.read!("lib/threadline/operator_surface/style.ex")

assert String.contains?(src, "color-scheme: dark;")
refute String.contains?(src, "prefers-color-scheme")
refute String.contains?(src, "color-scheme: light")
```

The existing contract suite already uses direct source assertions; extend this style for the final token/class catalog. [VERIFIED: `test/threadline/operator_surface/style_contract_test.exs`]

### Phoenix Component Boundary

```elixir
attr :name, :string, required: true
slot :inner_block, required: true
```

Phoenix function components support declared attributes and slots with compile-time validation, but Phase 144 should only document this as a deferred future direction, not implement it. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html; VERIFIED: 144-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Original Phase 134 ledger required for baseline proof | Phase 144 errata verification of existing Phase 134-labeled artifacts | Phase 144 discuss decision, 2026-06-04 | Avoids fabricated history while closing `POLISH-AUDIT`. [VERIFIED: 144-CONTEXT.md] |
| Phase 136 partial token foundation | Source-first final consolidation + catalog + freeze | Phase 144 discuss decision, 2026-06-04 | Closes `POLISH-DS` without new UI architecture. [VERIFIED: 144-CONTEXT.md] |
| Broad visual confidence only | Source contracts plus representative Playwright screenshot guard | Phases 141-143 | Keeps token/motion/responsive/a11y drift testable while preserving browser evidence. [VERIFIED: `style_contract_test.exs`, `143-VERIFICATION.md`] |
| `requirements_completed` underscore alias | `requirements-completed` hyphenated SSOT | Phase 130 convention | New summaries must use hyphenated frontmatter. [VERIFIED: `.planning/conventions/summary-frontmatter.md`] |

**Deprecated/outdated:**
- `requirements_completed` in new SUMMARY frontmatter: deprecated alias; use `requirements-completed`. [VERIFIED: `.planning/conventions/summary-frontmatter.md`]
- Tailwind / CSS-in-JS / build-step design-system migration for v1.31: explicit non-goal. [VERIFIED: `.planning/REQUIREMENTS.md`, 144-CONTEXT.md]
- Light/system theme or theme toggle: explicit non-goal. [VERIFIED: `.planning/REQUIREMENTS.md`, 144-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Warning signs listed for pitfalls are predictive indicators rather than verified failures in the repo. | Common Pitfalls | Planner may add unnecessary grep checks, but checks are low-cost. |

## Open Questions

1. **Should Phase 144 update Phase 136's `136-VERIFICATION.md` or create only `144-VERIFICATION.md`?**
   - What we know: The context says close via Phase 144 and do not fabricate Phase 134 history; milestone audit says close `POLISH-DS` then re-run Phase 136 verification or equivalent requirement evidence. [VERIFIED: 144-CONTEXT.md, `.planning/v1.31-MILESTONE-AUDIT.md`]
   - What's unclear: Whether the project wants a modified historical Phase 136 verification or a Phase 144 superseding verification note.
   - Recommendation: Prefer a Phase 144 verification that explicitly supersedes the partial Phase 136 status for `POLISH-DS`, with a short errata note in `136-VERIFICATION.md` only if the planner needs strict cross-file audit compatibility. [ASSUMED]

2. **How detailed should deprecated/consolidated `.tl-*` catalog entries be?**
   - What we know: The required doc must mark canonical, deprecated, and consolidated classes with usage rules and anti-patterns. [VERIFIED: 144-CONTEXT.md]
   - What's unclear: Whether every historical class needs line-by-line migration notes or family-level cataloging is enough.
   - Recommendation: Catalog by primitive families and include exact class lists for frozen public/internal classes; do not create busy per-selector prose unless a class is deprecated or consolidated. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Mix / Elixir / OTP | ExUnit and Mix verification aliases | yes | Mix 1.19.5, OTP 28 | None needed. [VERIFIED: environment probe] |
| Node.js | Playwright E2E tests | yes | v22.14.0 | None needed. [VERIFIED: environment probe] |
| npm | Playwright package scripts | yes | 11.1.0 | None needed. [VERIFIED: environment probe] |
| PostgreSQL client | Example app DB/browser verification | yes | psql 14.17 | Use configured DB host/port if local service differs. [VERIFIED: environment probe, `mix.exs`] |
| Playwright | Screenshot capture/regression | yes | `@playwright/test` 1.60.0 installed | Existing `mix verify.example_browser`. [VERIFIED: `npm ls --depth=0`, `mix.exs`] |
| Graphify | Optional graph context | no | disabled | Use explicit file/codebase research. [VERIFIED: `gsd-tools graphify status`] |
| Context7 CLI | Optional docs lookup fallback | no | not found | Official HexDocs via web. [VERIFIED: environment probe; CITED: HexDocs URLs] |

**Missing dependencies with no fallback:** None found for planning; actual browser verification still needs a running example app and database service when executing. [VERIFIED: `mix.exs`, E2E specs]

**Missing dependencies with fallback:** Graphify and Context7 are unavailable/disabled; local code inspection plus official HexDocs covered the needed research. [VERIFIED: tool probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5; Playwright `@playwright/test` 1.60.0. [VERIFIED: `mix --version`, `npm ls`] |
| Config file | ExUnit standard Mix project; Playwright config under `examples/threadline_phoenix/e2e`. [VERIFIED: `mix.exs`, E2E package] |
| Quick run command | `DB_PORT=5433 mix test test/threadline/operator_surface/style_contract_test.exs` [VERIFIED: `136-VERIFICATION.md`, `143-VERIFICATION.md`] |
| Full suite command | `mix verify.example_browser` plus focused operator-surface ExUnit tests; final milestone gate should rerun the milestone audit. [VERIFIED: `mix.exs`, `.planning/v1.31-MILESTONE-AUDIT.md`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| POLISH-AUDIT | Baseline evidence has 24 baseline PNGs, 24 final PNGs, audit doc, screenshot diff, and closure registry bound to Phase 144 errata. | doc/contract + filesystem | `find .planning/milestones/v1.31-screenshots/{baseline,final} -type f -name '*.png'` and `rg 'F-101|F-903|baseline|final' ...` | yes for evidence; Wave 0 should add errata artifact. [VERIFIED: local find, 143 docs] |
| POLISH-DS | Frozen token/class catalog matches source and forbids drift to Tailwind/light mode/ad-hoc primitives. | unit/source contract | `DB_PORT=5433 mix test test/threadline/operator_surface/style_contract_test.exs` | yes, needs new freeze cases. [VERIFIED: `style_contract_test.exs`] |
| POLISH-DS | Representative polished browser surfaces remain stable after any source consolidation. | browser regression | `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-screenshot-regression.spec.ts` | yes. [VERIFIED: `operator-screenshot-regression.spec.ts`] |

### Sampling Rate

- **Per task commit:** `DB_PORT=5433 mix test test/threadline/operator_surface/style_contract_test.exs` for source/catalog/freeze edits. [VERIFIED: existing verification files]
- **Per wave merge:** Add focused operator-surface ExUnit tests if presentation helpers change; run screenshot regression guard if CSS affects browser output. [VERIFIED: `style_contract_test.exs`, `operator-screenshot-regression.spec.ts`]
- **Phase gate:** Run `mix verify.example_browser`, verify 24 baseline + 24 final screenshots still exist, update `144-VERIFICATION.md`, then rerun milestone audit. [VERIFIED: `mix.exs`, `.planning/v1.31-MILESTONE-AUDIT.md`]

### Wave 0 Gaps

- [ ] `.planning/milestones/v1.31-DESIGN-SYSTEM.md` — required design-system catalog/freeze artifact. [VERIFIED: missing from `.planning/milestones` listing]
- [ ] `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-AUDIT-ERRATA.md` or equivalent — recommended explicit `POLISH-AUDIT` closure artifact. [VERIFIED: 144-CONTEXT.md]
- [ ] New tests in `test/threadline/operator_surface/style_contract_test.exs` — frozen token/class catalog, semantic status map, and canonical primitive families. [VERIFIED: 144-CONTEXT.md, existing test file]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no new auth work | Preserve existing Phoenix example login/browser tests; no Phase 144 auth changes. [VERIFIED: E2E specs, 144-CONTEXT.md] |
| V3 Session Management | no new session work | No new routes/session behavior. [VERIFIED: 144-CONTEXT.md] |
| V4 Access Control | no new access-control work | Do not add backend queries/routes; preserve existing mounted operator surface boundaries. [VERIFIED: 144-CONTEXT.md] |
| V5 Input Validation | yes, if touching source helpers | Preserve existing no-`String.to_atom/1` user input rule; source-contract tests should not parse untrusted input. [VERIFIED: `examples/threadline_phoenix/AGENTS.md`] |
| V6 Cryptography | no | No crypto in scope. [VERIFIED: 144-CONTEXT.md] |

### Known Threat Patterns for Phoenix/LiveView Operator UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Broken access control from new routes/queries | Elevation of privilege | Add no new routes/backend queries in Phase 144; preserve mounted surface behavior. [VERIFIED: 144-CONTEXT.md] |
| Accessibility status conveyed by color only | Information disclosure / usability failure under a11y constraints | Encode labels, borders, shape, and contrast in the design-system catalog and source tests. [VERIFIED: `143-VERIFICATION.md`, `style_contract_test.exs`] |
| Visual regression hides evidence drift | Tampering / repudiation of UI evidence | Keep screenshot regression guard and durable screenshot matrices. [VERIFIED: `operator-screenshot-regression.spec.ts`, `143-SCREENSHOT-DIFF.md`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-CONTEXT.md` - locked decisions, scope boundaries, canonical refs.
- `.planning/v1.31-MILESTONE-AUDIT.md` - blocking gap source for `POLISH-AUDIT` and `POLISH-DS`.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - milestone requirements, phase mapping, current project state.
- `.planning/milestones/v1.31-UI-AUDIT.md` - baseline state matrix and finding inventory.
- `.planning/phases/136-design-system-hardening/136-UI-SPEC.md`, `136-VERIFICATION.md`, `136-01-SUMMARY.md` - partial design-system status and original contract.
- `.planning/phases/143-accessibility-consistency-sweep-regression/143-SCREENSHOT-DIFF.md`, `143-AUDIT-CLOSURE.md`, `143-VERIFICATION.md` - final screenshot and audit closure proof.
- `lib/threadline/operator_surface/style.ex`, `lib/threadline/operator_surface/presentation.ex`, `test/threadline/operator_surface/style_contract_test.exs` - current token/class/helper/test source truth.
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts`, `operator-screenshot-regression.spec.ts` - screenshot capture/regression proof.
- `examples/threadline_phoenix/AGENTS.md` - subtree project constraints.
- `prompts/threadline-elixir-oss-dna.md`, `prompts/Threadline Brand Book.txt`, audit strategy prompt corpus - local project strategy/brand/DX guidance.

### Secondary (MEDIUM confidence)

- Phoenix LiveView official HexDocs `Phoenix.Component` - function components, attrs, slots. https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- Phoenix LiveView official HexDocs `Phoenix.LiveComponent` - prefer function components; avoid LiveComponents solely for code organization. https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html

### Tertiary (LOW confidence)

- None used as authoritative basis. All implementation recommendations are codebase-verified, context-locked, or official-doc cited.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing deps and versions were verified locally; no new packages recommended.
- Architecture: HIGH - phase scope is locked by context and the codebase has clear existing ownership boundaries.
- Pitfalls: HIGH for documented audit/design-system gaps; LOW only for predictive warning signs.

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for local planning artifacts; re-check dependency versions and official docs if this phase is delayed beyond 30 days.
