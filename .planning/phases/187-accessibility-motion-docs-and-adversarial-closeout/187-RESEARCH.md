# Phase 187: Accessibility, motion, docs, and adversarial closeout - Research

**Researched:** 2026-06-30
**Domain:** Phoenix LiveView operator UI accessibility, motion governance, documentation truth, and closeout verification
**Confidence:** HIGH for repo scope; MEDIUM for external standards/docs currency

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Contract Authority And Scope

- **D-187-01:** Treat Phase 187 as a proof and closeout phase over the already-polished v1.38 surfaces, not as another design or product feature phase.
- **D-187-02:** Preserve route paths, stable `data-testid`s, host-owned auth/export gates, feature gates, optional Phoenix/LiveView boundaries, scoped `data-tl-theme`, CSP-friendly behavior, private component boundaries, and all capture/query/auth semantics.
- **D-187-03:** Use targeted evidence for the exact pending requirements: `A11Y-01`, `A11Y-02`, `MOTION-01`, `DOC-01`, and `CLOSE-01`. Do not inflate scope with broad route matrices, new fixtures, or generic audits that are not tied to those requirements.

### Keyboard And APG Proof Envelope

- **D-187-04:** Primary keyboard proof must cover the investigation, readiness, export, and retention workflows end to end: Home launchers, shell nav and skip link, Timeline filters/drawers/rows/pivots, transaction and row-history paths, Coverage schema/remediation, Exports/download affordances, Evidence/Redaction/Retention navigation, and the retention destructive modal.
- **D-187-05:** Focus proof must assert visible, non-obscured focus and focus restoration where relevant, especially skip link to `#tl-main`, mobile shell navigation, Timeline filter/drawer triggers, row-history drawer, export controls, copy controls, and retention modal open/close/Escape paths.
- **D-187-06:** Custom widget proof should be representative and APG-shaped, not exhaustive for its own sake. Dialogs, drawers, dropdown/menu, popover/tooltip, tabs, segmented controls, accordion/disclosure, combobox/listbox, tooltips/popovers, and copy controls should be covered through source contracts and rendered Playwright checks where the current UI actually uses them.
- **D-187-07:** Native controls stay native. Do not role-inflate native `<select>`, `<input>`, `<table>`, links, buttons, details/summary, or forms into custom ARIA widgets.
- **D-187-08:** Accessibility-tree snapshots, role/name assertions, keyboard operation, focus visibility, non-color cues, and source contracts are sufficient proof for this phase. Do not claim real screen-reader certification unless real assistive-technology UAT is explicitly run and recorded.

### Motion Governance And Reduced Motion

- **D-187-09:** `test/threadline/operator_surface/style_contract_test.exs` and the existing motion inventory remain the source-level authority for token-backed motion, approved keyframes, `transition: all` rejection, reduced-motion blanket behavior, and dependency bans.
- **D-187-10:** `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` is the browser authority for computed motion behavior. It should continue to prove default motion and reduced-motion behavior for Home, overlays, dropdowns, popovers, accordions/details, toasts, press feedback, and row-history drawers.
- **D-187-11:** Any Phase 187 motion touch must stay inside existing tokens, keyframes, opacity/transform utilities, and reduced-motion rules. No decorative animation, new keyframes, transition-all, animation libraries, row/card entrance churn, or per-page motion experiments.
- **D-187-12:** Reduced motion should collapse positional transforms and durations while keeping UI visible and usable. Do not use motion proof that only checks source text if a current browser-computed behavior changed.

### Operator Docs Truth Source

- **D-187-13:** Documentation must align to current implementation, not older milestone prose. When docs and source conflict, treat current source plus active tests as the truth and repair docs/contracts.
- **D-187-14:** `guides/operator-surface.md` currently conflicts with source on theme behavior: it says there is no runtime theme toggle, while `lib/threadline/operator_surface/router.ex` and `lib/threadline/operator_surface/components/surface_header.ex` show a runtime server-posted dark/light/system theme picker via `POST {base_path}/theme`, native radios, CSRF, cookie/plug resolution, no JavaScript, and no localStorage. Phase 187 should repair the guide and any pinned doc contracts to describe the implemented runtime theme picker accurately.
- **D-187-15:** Operator docs must also align with the PhoenixStorybook dev lane, `/audit/__stress` authenticated stress route, auth/export gates, Coverage selected-schema behavior, CSP/asset opt-outs, production exclusions, and direct export route authorization boundaries.
- **D-187-16:** Do not broaden docs into marketing or a public component API. Keep docs focused on mount, auth, operator screens, verification, Storybook/stress boundaries, and adopter-safe production guidance.

### Visual QA And Screenshot Boundary

- **D-187-17:** Final visual QA should report the status of existing bounded guards, not create a broad screenshot matrix. The local-only screenshot regression guard currently owns Home, dense Timeline, row-history drawer, Exports, and Retention snapshots.
- **D-187-18:** `/audit/__stress` screenshot status remains ledger/allowlist-driven. Do not silently add screenshot baselines outside `.planning/design-system-ledger.json` ownership.
- **D-187-19:** Use behavioral Playwright assertions for keyboard, focus, overflow, themes, reduced motion, route transitions, and accessible names. Use screenshots only for already-owned stable visual cells or explicitly approved new baselines.
- **D-187-20:** If screenshot or Playwright commands fail, classify each failure with owner and impact. Do not delete baselines, weaken masks, skip tests, or mark broad gates green just to close the milestone.

### Adversarial Closeout

- **D-187-21:** Closeout must record concrete verification evidence: exact commands, pass/fail status, Playwright/screenshot guard status, any residual failure ownership, and why residuals are in or out of phase scope.
- **D-187-22:** Adversarial review should use four lenses: operator under incident pressure, keyboard/assistive-technology user, OSS maintainer/library boundary, and host-app DX/security boundary.
- **D-187-23:** The adversarial review must actively look for regressions in route stability, auth/export gates, CSP posture, optional dependency hygiene, docs truth, focus traps, obscured focus, color-only state, reduced-motion behavior, screenshot churn, and overclaiming accessibility.
- **D-187-24:** Requirements should only be marked complete after evidence exists. Do not close `A11Y-01`, `A11Y-02`, `MOTION-01`, `DOC-01`, or `CLOSE-01` by assertion alone.

### the agent's Discretion
### Claude's Discretion

Downstream agents may choose the exact plan count, task slicing, helper names, test grouping, verification commands, and closeout artifact names. They should prefer amending existing source/doc/browser contracts over creating parallel test lanes, as long as the decisions above and the phase boundary are preserved.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Real assistive-technology UAT remains deferred unless explicitly run. Phase 187 can record accessibility-tree and keyboard evidence, but should not claim screen-reader certification.
- Broad route x theme x viewport screenshot expansion remains deferred unless a future phase explicitly accepts new stable cells and owners.
- New public component API remains deferred to `COMP-PUBLIC-01` or a future explicit milestone.
- Public Storybook distribution remains deferred to `STORY-PUBLIC-01` or a future explicit milestone.
- Runtime destructive redaction remains deferred unless capture/storage semantics are explicitly scoped.
- New UI dependencies, Tailwind/shadcn, animation libraries, and capture/query/auth semantic changes remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| A11Y-01 | Custom controls follow the relevant APG behavior, including keyboard support for menus, tabs, segmented controls, dialogs, drawers, disclosures, tooltips, and copy controls. | Use existing source APG/native contracts plus rendered Playwright role/name/keyboard checks; APG warns that ARIA roles require matching keyboard behavior. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: codebase grep; CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/] |
| A11Y-02 | Keyboard-only users can complete the primary investigation, readiness, export, and retention flows with visible non-obscured focus and correct focus restoration. | Extend the existing `expectNonObscuredFocused` and focus-restoration Playwright paths only where gaps remain; WCAG 2.2 Focus Visible and Focus Not Obscured are the external standards anchor. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: codebase grep; CITED: https://www.w3.org/TR/WCAG22/] |
| MOTION-01 | Motion remains token-backed, fast, transform/opacity-oriented, purposeful, and reduced-motion aware; no new decorative animation or `transition: all` enters the operator surface. | Keep `style_contract_test.exs` as source authority and `operator-motion.spec.ts` as browser computed-style authority; Playwright can emulate reduced motion. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: codebase grep; CITED: https://playwright.dev/docs/api/class-page] |
| DOC-01 | Operator docs match the implementation for runtime theme picker, Storybook dev lane, stress route, mount/auth/export gates, schema selection, CSP expectations, and production exclusions. | Repair `guides/operator-surface.md` theme-picker drift and sharpen doc contracts against source truth for `/theme`, CSRF, no JS/localStorage, Storybook, stress, Coverage, export auth, and production exclusions. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: codebase grep] |
| CLOSE-01 | Final closeout includes current verification evidence, screenshot/Playwright guard status, residual failure ownership if any, and adversarial review across operator, accessibility, OSS maintainer, and host-app DX lenses. | Mirror the Phase 180 closeout shape: tiered proof, command ledger, residual CI classification, and adversarial review with explicit proof boundaries. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md`; VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-ADVERSARIAL-REVIEW.md`] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Treat Threadline as an open-source audit platform for Elixir teams; this phase must not blur Capture, Semantics, and Exploration/operations responsibilities. [VERIFIED: `CLAUDE.md`]
- Preserve canonical domain language such as `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and Correlation. [VERIFIED: `CLAUDE.md`]
- Prefer named verification entrypoints: `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`; phase-specific targeted commands may be used when residual ownership is explained. [VERIFIED: `CLAUDE.md`; VERIFIED: `.planning/phases/186-detail-governance-and-export-surfaces/186-VERIFICATION.md`]
- Keep root Phoenix/LiveView/Oban integrations optional and do not expand optional dependency posture for a proof/docs phase. [VERIFIED: `CLAUDE.md`; VERIFIED: `mix.exs`]
- `AGENTS.md` and project-local `.claude/skills` or `.agents/skills` directories were absent, so no additional project instruction file overrode `CLAUDE.md`. [VERIFIED: shell `ls`/`find`]

## Summary

Phase 187 should be planned as a closeout pass over existing proof lanes, not as a new UI implementation phase. The repository already has a focused browser accessibility harness, source-level APG/native contracts, motion source contracts, computed-style reduced-motion tests, bounded screenshot guards, and a prior Phase 180 closeout pattern. [VERIFIED: codebase grep; VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md`]

The main implementation repair called out by research is documentation drift: `guides/operator-surface.md` says there is no runtime theme toggle, while source and tests show a runtime server-posted `system|light|dark` picker through `POST {base_path}/theme`, CSRF, session/cookie resolution, no JavaScript, and no `localStorage`. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep]

**Primary recommendation:** Plan one narrow docs-contract repair plus one proof/closeout wave that reruns existing targeted source and browser lanes, records screenshot/Playwright status, classifies residuals, and writes a Phase 187 verification plus adversarial closeout artifact. [VERIFIED: `187-CONTEXT.md`; VERIFIED: `.planning/phases/186-detail-governance-and-export-surfaces/186-VERIFICATION.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Keyboard/APG proof | Browser / Client | Frontend Server (LiveView) | Rendered Playwright checks prove user-visible focus and keyboard behavior; LiveView/source contracts pin markup and JS command hooks. [VERIFIED: codebase grep; CITED: https://www.w3.org/WAI/ARIA/apg/] |
| Focus visibility and non-obscured focus | Browser / Client | CSS source contracts | WCAG focus requirements are visual/rendered outcomes, with source CSS preventing focus-ring and scroll-padding regressions. [VERIFIED: codebase grep; CITED: https://www.w3.org/TR/WCAG22/] |
| Motion and reduced motion | Browser / Client | CSS source contracts | Browser computed styles prove actual duration/transform behavior; source contracts prevent forbidden motion primitives and dependencies. [VERIFIED: codebase grep; CITED: https://playwright.dev/docs/api/class-page] |
| Runtime theme picker docs | Frontend Server (SSR/HTTP) | Browser / Client | The picker posts to a Phoenix route, stores session/cookie theme state, and renders native radios without client storage. [VERIFIED: codebase grep; CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html] |
| Direct export authorization boundary | Frontend Server (HTTP controller) | API / Backend | Export links and routes must remain authorized by server/controller/auth plug behavior, not by hidden LiveView controls alone. [VERIFIED: codebase grep; VERIFIED: `187-CONTEXT.md`] |
| Closeout evidence and adversarial review | Repository / CI | Browser / Client | CLOSE-01 is an evidence artifact over commands, residuals, and guard status, backed by source and browser runs. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md`] |

## Standard Stack

### Core

| Library / Standard | Version | Purpose | Why Standard |
|--------------------|---------|---------|--------------|
| Phoenix | locked `1.8.7`; official docs checked at `1.8.8` | Router/controller pipeline, scoped routes, HTTP verb dispatch, session/CSRF surface | Existing operator mount and `/theme` route use Phoenix router/controller boundaries; Phoenix docs describe pipelines/scopes and route dispatch. [VERIFIED: `mix deps`; CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html] |
| Phoenix LiveView | locked `1.1.30`; official docs checked at `1.2.5` | LiveView rendering, bindings, JS focus/show/hide/transition helpers | Existing UI uses LiveView/private function components and JS commands; docs support `JS.focus`, `JS.focus_first`, transitions, bindings, and `on_mount` patterns. [VERIFIED: `mix deps`; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| ExUnit + Mix aliases | Elixir/Mix `1.19.5` local runtime | Source contracts, doc contracts, operator LiveView/controller tests | Existing project verification aliases and source-contract tests are Mix/ExUnit based. [VERIFIED: `mix --version`; VERIFIED: `mix.exs`; VERIFIED: codebase grep] |
| Playwright Test | installed `1.60.0`; npm latest `1.61.1` modified 2026-06-30 | Rendered browser proof for keyboard, focus, aria snapshots, screenshots, reduced motion, and themes | Existing e2e specs use Playwright; official docs support ARIA snapshots, screenshots, keyboard, accessible names, and media emulation. [VERIFIED: `npm ls @playwright/test`; VERIFIED: `npm view @playwright/test`; CITED: https://playwright.dev/docs/aria-snapshots; CITED: https://playwright.dev/docs/test-snapshots] |
| WCAG 2.2 | W3C Recommendation republished 2024-12-12 with errata | Focus visible, focus not obscured, interaction animation, keyboard order, non-color accessibility anchors | External standards anchor for A11Y-02 and proof limits. [CITED: https://www.w3.org/TR/WCAG22/] |
| WAI-ARIA APG | Official WAI APG docs checked 2026-06-30 | Dialog, menu, tabs, accordion/disclosure, combobox, tooltip pattern expectations | External pattern anchor for representative custom-widget contracts and native-control restraint. [CITED: https://www.w3.org/WAI/ARIA/apg/] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| LazyHTML | locked `0.1.11` | Source HTML assertions in test code | Keep for existing source contracts only; do not introduce new parser dependencies. [VERIFIED: `mix deps`; VERIFIED: codebase grep] |
| Credo | locked `1.7.18` | Static checks via `mix verify.credo` | Run if implementation touches Elixir source/test files. [VERIFIED: `mix deps`; VERIFIED: `mix.exs`] |
| PostgreSQL client/server | `psql 14.17`; local `pg_isready` accepting | Example app and e2e backing database | Required by browser proof and example app verification. [VERIFIED: shell `psql --version`; VERIFIED: shell `pg_isready`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing Playwright role/name/keyboard/accessibility-tree checks | `axe-core` / `@axe-core/playwright` | New dependency is out of scope, and axe would not replace keyboard/focus-restoration proof or APG behavior proof. [VERIFIED: `187-CONTEXT.md`; CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/] |
| Existing CSS token/source contracts | Framer Motion, GSAP, animation libraries | Motion libraries are explicitly banned by existing source contracts and phase decisions. [VERIFIED: codebase grep; VERIFIED: `187-CONTEXT.md`] |
| Existing bounded screenshot guard | Broad route x theme x viewport screenshot matrix | Broad screenshot expansion is explicitly deferred and platform-sensitive. [VERIFIED: `187-CONTEXT.md`; CITED: https://playwright.dev/docs/test-snapshots] |
| Doc contract tests | Manual-only docs review | DOC-01 has known drift and should be pinned by executable literals where current source already provides the truth. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep] |

**Installation:**

```bash
# No new packages are recommended for Phase 187.
# If browser binaries are missing, use the existing e2e setup path:
cd examples/threadline_phoenix/e2e
npm ci
npx playwright install chromium
```

**Version verification:**

```bash
mix deps | rg "phoenix|phoenix_live_view|lazy_html|credo"
npm ls @playwright/test --prefix examples/threadline_phoenix/e2e --depth=0
npm view @playwright/test version time.modified repository.url scripts.postinstall --json
```

The locked stack is sufficient; do not upgrade Playwright in this phase. [VERIFIED: `mix deps`; VERIFIED: `npm ls`; VERIFIED: `npm view`; VERIFIED: `187-CONTEXT.md`]

## Package Legitimacy Audit

Phase 187 should install no new external packages. [VERIFIED: `187-CONTEXT.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | Latest package published 2026-06-23; installed lock is `1.60.0` | 40,791,905 weekly downloads for latest | `github.com/microsoft/playwright` | SUS by package-legitimacy seam because latest publish is too new | Existing lock approved for use; planner must add `checkpoint:human-verify` before any install or upgrade. [VERIFIED: `npm ls`; VERIFIED: `npm view`; VERIFIED: package-legitimacy seam] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]
**Packages flagged as suspicious [SUS]:** `@playwright/test` only if Phase 187 proposes a new install or upgrade. [VERIFIED: package-legitimacy seam]

*Packages discovered via WebSearch or training data that have not been verified against an authoritative source are tagged `[ASSUMED]` and the planner must gate each install behind a `checkpoint:human-verify` task.* No such unverified package is recommended here. [VERIFIED: package-legitimacy seam]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 187 requirements
  -> external standards and docs
       -> W3C WCAG 2.2 focus/motion anchors
       -> WAI APG widget/native-control anchors
       -> Playwright and Phoenix docs for supported test/framework APIs
  -> existing source contracts
       -> APG/native markup checks
       -> CSS/motion/theme/doc literal checks
  -> existing Playwright browser lanes
       -> keyboard + focus + accessible names
       -> reduced motion + computed style
       -> bounded screenshot/status checks
       -> example-app PostgreSQL/browser boundary
  -> targeted gap repair
       -> docs-contract repair for runtime theme picker
       -> narrow source/browser amendments only if requirement coverage is missing
       -> no capture/query/auth/export semantic changes
  -> verification evidence
       -> exact commands + pass/fail output
       -> screenshot/Playwright guard status
       -> residual ownership classification
  -> adversarial closeout
       -> operator pressure lens
       -> keyboard/AT lens
       -> OSS maintainer/library boundary lens
       -> host-app DX/security lens
```

This flow mirrors the Phase 180 closeout structure while using the current Phase 181-186 proof lanes. [VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md`; VERIFIED: `.planning/phases/186-detail-governance-and-export-surfaces/186-VERIFICATION.md`]

### Recommended Project Structure

```text
guides/
  operator-surface.md                         # primary DOC-01 repair target
test/threadline/operator_surface/
  theme_doc_contract_test.exs                 # sharpen runtime theme-picker doc literals
  operator_surface_doc_contract_test.exs      # keep broader operator docs pinned
  component_contract_test.exs                 # APG/native source authority
  style_contract_test.exs                     # motion/focus/theme source authority
examples/threadline_phoenix/e2e/tests/
  operator-accessibility.spec.ts              # A11Y-01/A11Y-02 rendered authority
  operator-motion.spec.ts                     # MOTION-01 rendered authority
  operator-screenshot-regression.spec.ts      # bounded screenshot status only
.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/
  187-VERIFICATION.md                         # exact commands, evidence, residuals
  187-ADVERSARIAL-REVIEW.md                   # four-lens closeout review
```

Each path above already exists except the two Phase 187 closeout artifacts, which the implementation plan should create. [VERIFIED: codebase grep; VERIFIED: shell `ls`]

### Pattern 1: Targeted Rendered A11Y Proof

**What:** Use Playwright role/name locators, keyboard actions, focus assertions, non-obscured focus geometry, and ARIA snapshots for sampled structure. [VERIFIED: codebase grep; CITED: https://playwright.dev/docs/aria-snapshots]

**When to use:** Use for A11Y-01/A11Y-02 user-observable paths across Home, shell nav, Timeline filters/pivots, Coverage readiness, Exports, Evidence/Redaction/Retention, row-history drawer, and retention modal. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep]

**Example:**

```typescript
// Source: existing operator-accessibility.spec.ts pattern + Playwright role/keyboard docs
await trigger.press("Enter");
await expect(dialog).toBeVisible();
await expect(dialog).toHaveAccessibleName(/Retention/i);
await expectNonObscuredFocused(dialog.getByRole("button", { name: /Close/i }), page);
await page.keyboard.press("Escape");
await expect(trigger).toBeFocused();
```

### Pattern 2: Source APG Contract Plus Native Restraint

**What:** Assert custom overlays expose the expected dialog/menu/listbox/tabs relationships while native controls remain native. [VERIFIED: codebase grep; CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/]

**When to use:** Use for fast A11Y-01 source coverage before browser tests, especially for custom widgets that are hard to exercise exhaustively in every rendered page. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: existing component_contract_test.exs pattern
assert src =~ ~s(role="dialog")
assert src =~ ~s(aria-modal="true")
refute src =~ ~s(role="grid")
refute src =~ ~s(<select role="combobox")
```

### Pattern 3: Two-Tier Motion Proof

**What:** Source tests reject bad CSS and dependencies; browser tests verify computed durations/transforms under default and reduced-motion media. [VERIFIED: codebase grep; CITED: https://playwright.dev/docs/api/class-page]

**When to use:** Use for any Phase 187 motion touch, and for final MOTION-01 closure even when no source changes are needed. [VERIFIED: `187-CONTEXT.md`]

**Example:**

```typescript
// Source: existing operator-motion.spec.ts pattern + Playwright media emulation docs
await page.emulateMedia({ reducedMotion: "reduce" });
const style = await computedStyle(page.getByTestId("row-history-drawer"));
expectDurationList(style.transitionDuration, "0.001s");
expectIdentityOrNone(style.transform);
```

### Pattern 4: Docs Truth Repair With Doc Contracts

**What:** Repair docs to current source truth and pin important literals in existing doc-contract tests. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep]

**When to use:** Use for DOC-01, especially runtime theme picker, Storybook dev lane, stress route, auth/export gates, Coverage selected-schema behavior, CSP/asset opt-outs, and production exclusions. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep]

**Example:**

```elixir
# Source: recommended extension of theme_doc_contract_test.exs
assert src =~ "runtime"
assert src =~ "POST"
assert src =~ "/theme"
assert src =~ "_csrf_token"
refute src =~ "no runtime theme toggle"
refute src =~ "localStorage"
```

### Pattern 5: Closeout Artifact With Residual Ownership

**What:** Produce a verification report with exact commands, requirement closure, screenshot/Playwright status, and residual classification, plus a separate adversarial review. [VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md`; VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-ADVERSARIAL-REVIEW.md`]

**When to use:** Use for CLOSE-01 after targeted source/browser/docs commands run. [VERIFIED: `.planning/REQUIREMENTS.md`]

### Anti-Patterns to Avoid

- **Adding axe or a new a11y dependency:** The phase decisions prefer existing role/name/keyboard/tree proof and prohibit scope inflation. [VERIFIED: `187-CONTEXT.md`]
- **Role-inflating native controls:** APG says ARIA roles are promises, and current source contracts explicitly keep select/input/table native. [CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/; VERIFIED: codebase grep]
- **Source-only reduced-motion proof after behavior changes:** D-187-12 requires browser-computed proof if current behavior changed. [VERIFIED: `187-CONTEXT.md`]
- **Broad screenshot matrix expansion:** The local screenshot guard is bounded to specific stable cells, and Playwright docs warn screenshots vary by environment. [VERIFIED: `187-CONTEXT.md`; CITED: https://playwright.dev/docs/test-snapshots]
- **Screen-reader certification claims:** APG notes AT interoperability testing is essential, and Phase 187 defers real AT UAT unless explicitly run. [CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/; VERIFIED: `187-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Accessibility behavior proof | Custom DOM scanners or generic aria grep only | Existing Playwright role/name/keyboard/focus helpers plus source contracts | Rendered keyboard and focus behavior cannot be proven by source text alone. [VERIFIED: codebase grep; CITED: https://playwright.dev/docs/api/class-keyboard] |
| APG semantics | Custom pseudo-controls over native elements | Native HTML controls and APG-shaped source assertions | ARIA does not add behavior; it requires the developer to implement expected behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/] |
| Motion runtime | Animation library or page-local keyframes | Existing CSS tokens, approved keyframes, and reduced-motion blanket | Existing contracts ban animation libraries, unapproved keyframes, and `transition: all`. [VERIFIED: codebase grep] |
| Docs truth | One-off prose edits with no tests | Existing doc-contract tests plus focused new literals | DOC-01 has known source/docs drift that should be executable. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep] |
| Export security | LiveView visibility-only gating | Existing controller/auth plug/direct route tests | Direct export routes require server-side authorization even if controls are hidden. [VERIFIED: codebase grep; VERIFIED: `187-CONTEXT.md`] |
| Closeout residuals | Silent test skips or weakened baselines | Residual classification artifact | Prior closeout artifacts classify inherited failures rather than relabeling non-green suites. [VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-RESIDUAL-CI.md`] |

**Key insight:** Phase 187 planning should compose existing proof layers instead of inventing new frameworks; the current risk is unproven requirement closure and doc drift, not missing infrastructure. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Treating APG as a reason to add ARIA everywhere

**What goes wrong:** Native controls become custom widgets with incomplete keyboard behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/]
**Why it happens:** Teams confuse semantic labels with interaction behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/]
**How to avoid:** Preserve native select/input/table/link/button/details/form behavior and only assert APG relationships for actual custom widgets. [VERIFIED: codebase grep]
**Warning signs:** New `role="combobox"` on `<select>`, `role="grid"` on simple tables, or route-wide ARIA additions. [VERIFIED: codebase grep]

### Pitfall 2: Focus tests that only check `toBeFocused`

**What goes wrong:** A focused element can still be hidden under sticky chrome or an overlay. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html]
**Why it happens:** Locator focus state is not the same as visible non-obscured focus. [CITED: https://www.w3.org/TR/WCAG22/]
**How to avoid:** Reuse `expectNonObscuredFocused` and assert focus return after Escape/close paths. [VERIFIED: codebase grep]
**Warning signs:** Tests pass with `toBeFocused` but never inspect bounding boxes, viewport, or overlay coverage. [VERIFIED: codebase grep]

### Pitfall 3: Motion proof that ignores computed behavior

**What goes wrong:** Source contains a reduced-motion block but rendered transforms or transitions still move in the browser. [VERIFIED: codebase grep]
**Why it happens:** CSS cascade, selectors, and LiveView states can differ from literal source expectations. [VERIFIED: codebase grep]
**How to avoid:** Pair source-contract checks with `page.emulateMedia({ reducedMotion: "reduce" })` computed-style checks. [CITED: https://playwright.dev/docs/api/class-page; VERIFIED: codebase grep]
**Warning signs:** MOTION-01 closure cites only `style_contract_test.exs` after changed rendered behavior. [VERIFIED: `187-CONTEXT.md`]

### Pitfall 4: Repairing docs to older milestone prose

**What goes wrong:** Docs keep saying no runtime theme toggle while source implements a runtime server-posted picker. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep]
**Why it happens:** The guide still reflects older pre-picker language. [VERIFIED: codebase grep]
**How to avoid:** Treat source plus active tests as truth and update doc contracts in the same plan. [VERIFIED: `187-CONTEXT.md`]
**Warning signs:** `guides/operator-surface.md` retains "no runtime theme toggle" or contradicts `/theme` route source. [VERIFIED: codebase grep]

### Pitfall 5: Screenshot churn hidden as accessibility closeout

**What goes wrong:** Broad screenshots become noisy baseline churn unrelated to A11Y-01/A11Y-02/MOTION-01/DOC-01/CLOSE-01. [VERIFIED: `187-CONTEXT.md`; CITED: https://playwright.dev/docs/test-snapshots]
**Why it happens:** Visual proof is mistaken for behavioral proof. [VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md`]
**How to avoid:** Report existing bounded screenshot guard status and use behavioral assertions for keyboard/focus/motion. [VERIFIED: `187-CONTEXT.md`]
**Warning signs:** New route x theme x viewport screenshots outside `.planning/design-system-ledger.json`. [VERIFIED: `187-CONTEXT.md`]

### Pitfall 6: Closing accessibility by overclaiming snapshots

**What goes wrong:** Accessibility-tree snapshots are described as screen-reader certification. [VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md`; CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/]
**Why it happens:** Browser accessibility trees are useful but not equivalent to NVDA, VoiceOver, JAWS, Narrator, TalkBack, or human workflows. [VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-ADVERSARIAL-REVIEW.md`; CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/]
**How to avoid:** Use explicit proof-limit language in `187-VERIFICATION.md` and `187-ADVERSARIAL-REVIEW.md`. [VERIFIED: `187-CONTEXT.md`]
**Warning signs:** Phrases like "screen-reader certified" without recorded real AT UAT. [VERIFIED: `187-CONTEXT.md`]

## Code Examples

Verified patterns from official sources and the repository:

### Non-Obscured Focus Assertion

```typescript
// Source: existing operator-accessibility.spec.ts helper; WCAG Focus Not Obscured anchor
const box = await locator.boundingBox();
expect(box).not.toBeNull();
const point = { x: box!.x + box!.width / 2, y: box!.y + box!.height / 2 };
const topElementTag = await page.evaluate(({ x, y }) => {
  const element = document.elementFromPoint(x, y);
  return element?.tagName ?? null;
}, point);
expect(topElementTag).not.toBeNull();
```

[VERIFIED: codebase grep; CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html]

### Reduced Motion Computed Check

```typescript
// Source: existing operator-motion.spec.ts pattern; Playwright media emulation docs
await page.emulateMedia({ reducedMotion: "reduce" });
const drawerStyle = await computedStyle(page.getByTestId("row-history-drawer"));
expectDurationList(drawerStyle.transitionDuration, "0.001s");
expectIdentityOrNone(drawerStyle.transform);
```

[VERIFIED: codebase grep; CITED: https://playwright.dev/docs/api/class-page]

### Runtime Theme Picker Doc Contract

```elixir
# Source: recommended extension of existing theme_doc_contract_test.exs
assert String.contains?(src, "runtime")
assert String.contains?(src, "/theme")
assert String.contains?(src, "_csrf_token")
assert String.contains?(src, "Apply theme")
refute String.contains?(src, "no runtime theme toggle")
refute String.contains?(src, "localStorage")
```

[VERIFIED: codebase grep]

### Closeout Residual Classification Shape

```markdown
| Suite | Result | Classification | Owner |
|-------|--------|----------------|-------|
| Targeted A11Y browser lane | PASS/FAIL | Phase-owned | Phase 187 |
| Broad `mix ci.all` residual | PASS/FAIL | inherited / phase-owned | named prior phase or Phase 187 |
```

[VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-RESIDUAL-CI.md`]

## State of the Art

| Old Approach | Current Approach | When Changed / Verified | Impact |
|--------------|------------------|--------------------------|--------|
| Treat visible focus as enough | Also prove focused components are not hidden behind author-created content | WCAG 2.2 includes Focus Not Obscured Minimum at Level AA; W3C docs checked 2026-06-30 | Phase 187 should keep non-obscured focus geometry checks. [CITED: https://www.w3.org/TR/WCAG22/; VERIFIED: codebase grep] |
| Add ARIA roles for semantics | Prefer native controls and only add ARIA with complete keyboard behavior | WAI APG current guidance checked 2026-06-30 | A11Y-01 source contracts should preserve native restraint. [CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/; VERIFIED: codebase grep] |
| Manual-only accessibility statements | Combine source contracts, Playwright role/name/keyboard checks, and ARIA snapshots with explicit proof limits | Phase 180 established this pattern and Phase 187 context repeats it | Closeout should not claim AT certification without real AT UAT. [VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md`; VERIFIED: `187-CONTEXT.md`] |
| Source-only motion checks | Pair CSS contract tests with browser computed-style reduced-motion checks | Existing Phase 187 context names `operator-motion.spec.ts` as authority | MOTION-01 closure needs both tiers if behavior changed. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep] |
| Docs saying no runtime theme toggle | Docs must describe server-posted runtime theme picker | Source and tests currently implement `/theme` route/form | DOC-01 needs guide and doc-contract repair. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep] |

**Deprecated/outdated:**

- `guides/operator-surface.md` statements that say "no runtime theme toggle" are outdated relative to source. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep]
- Broad screenshot expansion is out of scope for this closeout phase. [VERIFIED: `187-CONTEXT.md`]
- Animation libraries, Tailwind/shadcn, and public component APIs remain out of scope. [VERIFIED: `187-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| - | No `[ASSUMED]` claims are used in this research. | All | Planner can proceed without user confirmation for assumed technical facts. [VERIFIED: self-audit] |

## Open Questions

1. **Should closeout use one artifact or split verification and adversarial review?**
   - What we know: Phase 180 used separate `180-VERIFICATION.md`, `180-RESIDUAL-CI.md`, and `180-ADVERSARIAL-REVIEW.md`. [VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/`]
   - What's unclear: D-187 discretion allows exact artifact names and plan slicing. [VERIFIED: `187-CONTEXT.md`]
   - Recommendation: Use `187-VERIFICATION.md` plus `187-ADVERSARIAL-REVIEW.md`; include residuals in verification unless a non-green broad command needs a standalone residual file. [VERIFIED: `187-CONTEXT.md`; VERIFIED: prior closeout artifacts]

2. **Should Playwright be upgraded to latest?**
   - What we know: Existing lock is `@playwright/test@1.60.0`, latest is `1.61.1`, and package legitimacy flags the latest publish as SUS due recency. [VERIFIED: `npm ls`; VERIFIED: `npm view`; VERIFIED: package-legitimacy seam]
   - What's unclear: No Phase 187 requirement requires a Playwright upgrade. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `187-CONTEXT.md`]
   - Recommendation: Do not upgrade; if a plan proposes an install/upgrade, add `checkpoint:human-verify`. [VERIFIED: package-legitimacy seam]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix/ExUnit source and docs contracts | yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: `elixir --version`] |
| Mix | Project aliases and test commands | yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: `mix --version`] |
| Node.js | Playwright e2e runner | yes | v22.14.0 | None needed. [VERIFIED: `node --version`] |
| npm / npx | Playwright package scripts and browser install | yes | 11.1.0 | None needed. [VERIFIED: `npm --version`; VERIFIED: `npx --version`] |
| PostgreSQL | Example app/e2e data | yes | `psql 14.17`; local server accepting | None needed for current machine. [VERIFIED: `psql --version`; VERIFIED: `pg_isready`] |
| Docker | Optional service/container workflows | yes | 29.5.2 | Local Postgres is already available. [VERIFIED: `docker --version`; VERIFIED: `pg_isready`] |
| System Chromium | External browser binary | broken shim | `/opt/homebrew/bin/chromium` points to missing app | Use Playwright-managed Chromium via existing e2e setup. [VERIFIED: `command -v chromium`; VERIFIED: `chromium --version`; CITED: https://playwright.dev/docs/browsers] |

**Missing dependencies with no fallback:** none found for the recommended plan. [VERIFIED: shell probes]

**Missing dependencies with fallback:**

- System Chromium shim is broken; use Playwright-managed Chromium from the existing e2e package. [VERIFIED: shell probes; CITED: https://playwright.dev/docs/browsers]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Mix for source and doc contracts; Playwright Test for browser proof. [VERIFIED: `mix.exs`; VERIFIED: `examples/threadline_phoenix/e2e/package.json`] |
| Config file | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/theme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs`. [VERIFIED: codebase grep; VERIFIED: `mix.exs`] |
| Browser A11Y command | `mix verify.example_browser -- operator-accessibility.spec.ts`. [VERIFIED: `mix.exs`; VERIFIED: codebase grep] |
| Browser motion command | `mix verify.example_browser -- operator-motion.spec.ts`. [VERIFIED: `mix.exs`; VERIFIED: codebase grep] |
| Full suite command | `mix ci.all`, with residual ownership classified if non-green. [VERIFIED: `mix.exs`; VERIFIED: `187-CONTEXT.md`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| A11Y-01 | APG-shaped custom controls and native-control restraint | source + browser | `mix test test/threadline/operator_surface/component_contract_test.exs && mix verify.example_browser -- operator-accessibility.spec.ts` | yes. [VERIFIED: codebase grep] |
| A11Y-02 | Keyboard-only end-to-end flows with visible non-obscured focus and focus restoration | browser | `mix verify.example_browser -- operator-accessibility.spec.ts` | yes. [VERIFIED: codebase grep] |
| MOTION-01 | Tokenized motion, no `transition: all`, reduced-motion computed collapse | source + browser | `mix test test/threadline/operator_surface/style_contract_test.exs && mix verify.example_browser -- operator-motion.spec.ts` | yes. [VERIFIED: codebase grep] |
| DOC-01 | Docs align with runtime theme picker, Storybook/stress, auth/export, Coverage, CSP, production exclusions | doc contract | `mix test test/threadline/operator_surface/theme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` | yes; theme contract needs sharpening. [VERIFIED: codebase grep; VERIFIED: `187-CONTEXT.md`] |
| CLOSE-01 | Verification evidence, screenshot/Playwright status, residual ownership, adversarial review | artifact + command ledger | `rg -n "A11Y-01|A11Y-02|MOTION-01|DOC-01|CLOSE-01" .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md` plus targeted reruns | no; artifact is Phase 187 output. [VERIFIED: shell `ls`; VERIFIED: `.planning/REQUIREMENTS.md`] |

### Sampling Rate

- **Per task commit:** Run the narrow source/doc test for changed files, then the relevant Playwright file if browser behavior changed. [VERIFIED: `187-CONTEXT.md`; VERIFIED: `mix.exs`]
- **Per wave merge:** Run source/doc quick command plus `mix verify.example_browser -- operator-accessibility.spec.ts operator-motion.spec.ts` when both accessibility and motion are touched. [VERIFIED: `187-CONTEXT.md`; VERIFIED: `mix.exs`]
- **Phase gate:** Run targeted source/doc command, targeted browser A11Y/motion command, screenshot guard status command, and `mix ci.all` or classify broad residuals with owner/impact. [VERIFIED: `187-CONTEXT.md`; VERIFIED: `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-RESIDUAL-CI.md`]

### Wave 0 Gaps

- [ ] Amend `test/threadline/operator_surface/theme_doc_contract_test.exs` to refute stale "no runtime theme toggle" docs and assert current server-posted picker literals. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep]
- [ ] Create `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md` after commands run. [VERIFIED: shell `ls`; VERIFIED: `.planning/REQUIREMENTS.md`]
- [ ] Create `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-ADVERSARIAL-REVIEW.md` or equivalent closeout section after proof exists. [VERIFIED: shell `ls`; VERIFIED: `187-CONTEXT.md`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Preserve host-owned `authorize_fn`, existing auth plugs, and route/controller authorization boundaries. [VERIFIED: codebase grep; VERIFIED: `187-CONTEXT.md`] |
| V3 Session Management | yes | Runtime theme picker writes only allowlisted `system|light|dark` values to session/cookie through CSRF-protected POST. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Direct export download routes remain server-authorized; LiveView visibility is not the enforcement boundary. [VERIFIED: codebase grep; VERIFIED: `187-CONTEXT.md`] |
| V5 Input Validation | yes | Keep existing allowlists for theme modes, stress query params, Coverage schema paths, and export filters; do not widen accepted values in a docs/proof phase. [VERIFIED: codebase grep; VERIFIED: `187-CONTEXT.md`] |
| V6 Cryptography | no new crypto | Do not add cryptography; rely on existing Phoenix/Plug CSRF/session mechanisms and existing `Plug.Crypto.secure_compare/2` retention confirmation where present. [VERIFIED: codebase grep] |

### Known Threat Patterns for Phoenix LiveView Operator Surface

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Direct export route bypass after UI-only hide | Elevation of privilege | Keep controller/auth-plug tests and direct route docs aligned. [VERIFIED: codebase grep; VERIFIED: `187-CONTEXT.md`] |
| CSRF on theme POST | Tampering | Preserve `_csrf_token` hidden input and POST route contract. [VERIFIED: codebase grep] |
| XSS/CSP drift from inline handlers | Tampering | Preserve native theme picker with no inline `onchange`/`onclick`, no JS, and no `localStorage`. [VERIFIED: codebase grep] |
| Overclaiming accessibility certification | Repudiation | Record proof limits and avoid screen-reader certification unless real AT UAT occurs. [VERIFIED: `187-CONTEXT.md`; CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/] |
| Route/test-id churn in closeout | Denial of service / maintenance risk | Preserve stable routes and `data-testid`s; use existing selectors. [VERIFIED: `187-CONTEXT.md`; VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `187-CONTEXT.md` - locked user decisions, known docs drift, proof scope, deferrals. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - A11Y-01, A11Y-02, MOTION-01, DOC-01, CLOSE-01 descriptions and pending traceability. [VERIFIED: codebase grep]
- `CLAUDE.md` - project verification conventions, architecture boundaries, optional dependency posture. [VERIFIED: codebase grep]
- `mix.exs`, `mix deps`, `examples/threadline_phoenix/e2e/package.json`, `npm ls` - project stack, aliases, locked versions. [VERIFIED: shell commands]
- `operator-accessibility.spec.ts`, `operator-motion.spec.ts`, `style_contract_test.exs`, `component_contract_test.exs`, doc-contract tests - existing proof authority. [VERIFIED: codebase grep]
- Phase 180 and Phase 186 verification artifacts - closeout shape and recent residual/proof context. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- W3C WCAG 2.2 Recommendation - focus visible, focus not obscured, focus appearance, keyboard order, interaction animation. [CITED: https://www.w3.org/TR/WCAG22/]
- WAI-ARIA APG - pattern guidance and "No ARIA is better than Bad ARIA" practice. [CITED: https://www.w3.org/WAI/ARIA/apg/; CITED: https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/]
- APG modal dialog, menu button, menubar, tabs, accordion, disclosure, combobox, tooltip patterns. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/; CITED: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/; CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/; CITED: https://www.w3.org/WAI/ARIA/apg/patterns/accordion/; CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/; CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/; CITED: https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/]
- Playwright docs for ARIA snapshots, screenshots, keyboard, locator assertions, and media emulation. [CITED: https://playwright.dev/docs/aria-snapshots; CITED: https://playwright.dev/docs/test-snapshots; CITED: https://playwright.dev/docs/api/class-keyboard; CITED: https://playwright.dev/docs/api/class-locatorassertions; CITED: https://playwright.dev/docs/api/class-page]
- Phoenix/Phoenix LiveView HexDocs for router pipelines/scopes, LiveView Router/session boundaries, JS commands, bindings, and `on_mount`. [CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html; CITED: https://hexdocs.pm/phoenix_live_view/bindings.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Tertiary (LOW confidence)

- None used for recommendations. [VERIFIED: self-audit]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH for installed project versions; MEDIUM for external latest-doc currency because Context7 was unavailable and official web docs were used. [VERIFIED: `mix deps`; VERIFIED: `npm ls`; CITED: official docs URLs above]
- Architecture: HIGH because it is derived from current source, context, and recent phase verification artifacts. [VERIFIED: codebase grep; VERIFIED: `.planning/phases/186-detail-governance-and-export-surfaces/186-VERIFICATION.md`]
- Pitfalls: HIGH for repo-specific pitfalls; MEDIUM for standards-language pitfalls. [VERIFIED: codebase grep; CITED: W3C/WAI/Playwright/Phoenix docs]

**Research date:** 2026-06-30
**Valid until:** 2026-07-30 for repo contracts; re-check Playwright/npm package metadata within 7 days before any install or upgrade. [VERIFIED: `npm view`; VERIFIED: package-legitimacy seam]
