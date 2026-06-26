# Phase 181: Baseline audit and guard repair - Research

**Researched:** 2026-06-26  
**Domain:** Phoenix LiveView operator surface baseline audit, Playwright guard repair, design-system ratchet preservation  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Baseline Evidence Shape

- **D-181-01:** Phase 181 baseline evidence is an audit packet, not a screenshot dump. Every `/audit` page should be mapped to its operator JTBD, current route/rendering evidence, screenshot coverage, stale selectors/tests, issue taxonomy, and guard disposition.
- **D-181-02:** The audit packet should produce planner-consumable artifacts:
  - `181-BASELINE-AUDIT.md` - page/JTBD matrix, visible issues, risk taxonomy, ownership by later phase.
  - `181-SCREENSHOT-INVENTORY.md` - current screenshot status, viewport/theme coverage, local/CI distinction, stale or missing baselines.
  - `181-GUARD-REPAIR.md` - stale selector/test/source-contract findings and any repairs performed.
  - `181-VERIFICATION.md` - evidence that BASE-01, BASE-02, and BASE-03 are satisfied.
- **D-181-03:** Use a consistent issue taxonomy so findings do not become unowned prose:
  - JTBD/IA drift
  - stale selector or copy contract
  - screenshot or ledger drift
  - accessibility/focus/motion proof gap
  - route/auth/feature-gate invariant gap
  - later-phase polish follow-up

### Guard Repair Boundary

- **D-181-04:** Phase 181 uses a bounded repair-now policy. It should patch broken guardrails immediately when the change restores an existing invariant or accepted v1.37 contract.
- **D-181-05:** Allowed now:
  - update stale E2E selectors to current stable `data-testid`, role, URL, or rendered behavior;
  - retire removed contracts only with rationale and replacement/owner;
  - repair `/audit/__stress` fixtures, ledger rows, `DESIGN-SYSTEM.md`, screenshot allowlist references, and projection freshness without lowering ratchets;
  - add focused source-contract tests for routes, feature gates, stable IDs, optional dependencies, auth/export/stress boundaries, and no-production stress/story exposure;
  - restore missing semantic guard hooks only when additive and non-redesign, such as a missing `data-testid`, `aria-current`, or feature-gated nav assertion.
- **D-181-06:** Deferred to later phases:
  - Shell/Home/Timeline/Coverage visual hierarchy, CTA strategy, IA, copy polish, layout redesign, motion polish, and design-approved screenshot rebaselining;
  - route path changes or `data-testid` renames/removals unless a later phase records and verifies the breaking change;
  - capture/query/auth semantic changes, public component API, root PhoenixStorybook dependency, production Storybook/stress route, Tailwind/shadcn migration, and runtime destructive redaction.

### Audit Matrix Strictness

- **D-181-07:** Use a tiered matrix rather than a full pixel snapshot explosion.
  - **Tier A - source/CI contracts:** enforce full registry/manifest truth for 11 pages x 7 paths, themes `dark|light|system`, viewports `320|375|768|1024|1440`, ledger freshness, story/fixture parity, route/auth gates, feature gates, and no score backslide.
  - **Tier B - rendered CI slices:** run representative Chromium checks, baseline-free where possible, for overflow/nav/header behavior across all real `/audit` pages at 320 and 1440; include Shell/Home/Timeline/Coverage at 375/768/1024 and keep dark plus existing light/system coverage where already supported.
  - **Tier C - local/human packet:** capture/review all 11 real pages at desktop 1280 and mobile 375, plus light desktop for Shell/Home/Timeline/Coverage and selected stress stories for happy/error/permission/boundary states.
- **D-181-08:** Keep the existing bounded screenshot CI allowlist unless a later page phase promotes specific cells. Full page x path x theme x viewport pixel baselines are too costly and flaky for the baseline phase; CI-allowlist-only is too weak to satisfy BASE-01.

### Operator Context, JTBD, and Design Contract

- **D-181-09:** v1.38 page plans should use a compact operator-context contract, not a new broad research reset. The context contract includes personas/JTBD, who/what/where/when/why, canonical nouns, UI events/verbs, page/JTBD matrix, design pillars, and guardrails.
- **D-181-10:** Primary personas:
  - Incident/support operator - needs to find what changed and explain it under pressure.
  - Audit-readiness/security/platform operator - needs to know whether capture is complete enough to trust.
  - Governance/export operator - needs evidence, retention/redaction posture, and handoff artifacts.
  - Adopting developer/maintainer - needs the mounted UI to be Phoenix-native, debuggable, optional-dependency friendly, and stable across host apps.
- **D-181-11:** Core JTBD:
  - Find what happened.
  - Verify capture readiness.
  - Inspect evidence/governance safely.
  - Export/share current evidence.
  - Maintain the UI without public component or dependency leakage.
- **D-181-12:** Canonical domain language for the UI and planning: Audit Action, Audit Transaction, Audit Change, Actor, Subject, Request, Job, Correlation, Coverage, Evidence, Redaction, Retention, Export, Saved View, Timeline Entry, Diff, Snapshot.
- **D-181-13:** Canonical UI verbs/events: filter, scan, open, copy, compare, refresh, remediate, queue export, download, confirm destructive action, return.
- **D-181-14:** Design pillars for v1.38 page work:
  - task-led orientation;
  - semantic-first raw-on-demand detail;
  - dense but scannable data;
  - explicit trust state;
  - accessible native-first interaction;
  - composed Threadline brand across dark/light/system;
  - purposeful motion and performance;
  - Phoenix/LiveView-native maintainer DX.
- **D-181-15:** Hide backend implementation details from operators unless the detail is necessary for remediation, proof, or performance constraints. Prefer operator language first; expose technical anchors as secondary raw detail, copyable refs, commands, or docs links.
- **D-181-16:** Current brand truth comes from `brandbook/brand-book.md`, not older prompt-era brand text when they conflict. The operator surface remains dark-primary with fully shipped light/system lanes via host config and cookie-based runtime picker, no localStorage, no JS theming, and no decorative consumer-app effects.

### Page/JTBD Matrix

| Surface | Primary JTBD | Phase Owner |
|---------|--------------|-------------|
| Shell/global nav | Know where I am, what destinations exist, and what is currently active | 183 |
| Home `/audit` | Pick the right operator job without reading an info dump | 183 |
| Timeline | Filter, scan, open transaction/row history, and export current view | 184 |
| Coverage | Answer whether one schema is audit-ready and what to fix next | 185 |
| Transaction detail | Explain one transaction and its changed rows | 186 |
| Row history | Reconstruct one row's history/as-of context | 186 |
| Actor detail | Understand what one actor did and where to go next | 186 |
| Evidence | Inspect proof records without implying broader compliance theater | 186 |
| Exports | Prepare or retrieve current-view handoff artifacts safely | 186 |
| Redaction | Understand redaction posture without offering unscoped destructive runtime redaction | 186 |
| Retention | Review retention/prune consequences with type-to-confirm safety | 186 |
| Stress route `/audit/__stress` | Maintainer-only component/page/fixture ratchet evidence | 181, 182, 187 |

### the agent's Discretion
The user explicitly asked for a one-shot, research-backed recommendation set and did not want piecemeal choices. Downstream planning may choose exact file splits and task sequencing, but must preserve the decisions above.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- PhoenixStorybook implementation belongs to Phase 182.
- Shell/Home orientation and nav polish belong to Phase 183.
- Timeline workflow polish belongs to Phase 184.
- Coverage audit-readiness polish belongs to Phase 185.
- Detail/governance/export page polish belongs to Phase 186.
- Accessibility/motion/docs/adversarial closeout belongs to Phase 187.
- Public component API, root Storybook dependency, runtime destructive redaction, Tailwind/shadcn migration, and production stress/story routes remain out of scope for v1.38 unless a later milestone explicitly reopens them.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BASE-01 | Maintainers can see a current rendered audit of every `/audit` page, with stale tests and stale selectors identified before page polish begins. [VERIFIED: .planning/REQUIREMENTS.md] | Use the D-181 audit packet, existing `operator-screenshots.spec.ts`, `operator-screenshot-regression.spec.ts`, `operator-phase-178-uat.spec.ts`, route/source scans, and a stale-comment/selector grep pass. [VERIFIED: codebase grep] |
| BASE-02 | The design-system ledger, `DESIGN-SYSTEM.md`, screenshot allowlist, and E2E suites continue to ratchet upward without lowering scores or silently dropping stories. [VERIFIED: .planning/REQUIREMENTS.md] | Use `stress_ledger_test.exs`, `stress_fixtures_test.exs`, `stress_router_test.exs`, `operator-stress.spec.ts`, and the existing bounded screenshot allowlist. [VERIFIED: codebase grep] |
| BASE-03 | The milestone preserves a compact research/decision record for PhoenixStorybook, `/audit/__stress`, nav IA, motion, accessibility, and operator JTBD tradeoffs. [VERIFIED: .planning/REQUIREMENTS.md] | Link `181-CONTEXT.md`, `.planning/research/v1.38-operator-ui-page-polish.md`, v1.37 Phase 178/179/180 closeout artifacts, W3C APG/WCAG, Playwright, Phoenix LiveView, and PhoenixStorybook docs from the plan and packet. [VERIFIED: codebase grep] [CITED: https://www.w3.org/WAI/ARIA/apg/] |
</phase_requirements>

## Project Constraints (from CLAUDE.md and examples/threadline_phoenix/AGENTS.md)

- The codebase has capture, semantics, and exploration/operations layers; Phase 181 belongs to the exploration/operations guardrail layer and must not change capture or semantics behavior. [VERIFIED: CLAUDE.md]
- Use Threadline domain language consistently: AuditTransaction, AuditChange, AuditAction, AuditContext, ActorRef, and Correlation remain distinct concepts. [VERIFIED: CLAUDE.md]
- Prefer named verification aliases such as `mix verify.*` and `mix ci.all` over ad hoc commands when documenting CI-facing checks. [VERIFIED: CLAUDE.md]
- The root package keeps Phoenix/LiveView optional; verify optional-dependency boundaries with existing source tests and `mix verify.compile_no_optional` when dependency-facing files change. [VERIFIED: mix.exs]
- The Phoenix example app says to run `mix precommit` when done with all example-app changes, and it prefers `Req` over `:httpoison`, `:tesla`, or `:httpc` for HTTP work. [VERIFIED: examples/threadline_phoenix/AGENTS.md]
- Phoenix v1.8 guidance in the example app requires `Layouts.app` wrapping, proper authenticated `live_session` placement for `current_scope`, no direct `<.flash_group>` outside layouts, built-in `<.icon>` usage, and imported `<.input>` usage when available. [VERIFIED: examples/threadline_phoenix/AGENTS.md]
- Elixir test guidance forbids `Process.sleep/1` synchronization and recommends `start_supervised!/1`, process monitors, or `:sys.get_state/1` for deterministic tests. [VERIFIED: examples/threadline_phoenix/AGENTS.md]

## Summary

Phase 181 should plan a baseline packet plus bounded guard repair, not redesign. The existing stack already has the right primitives: 130 ledger entries, 77 page stories for 11 pages x 7 paths, a bounded CI screenshot allowlist, local screenshot baselines, source contracts for ledger/story/projection freshness, Playwright rendered accessibility/motion/stress checks, and prior v1.37 verification artifacts. [VERIFIED: codebase grep] [VERIFIED: mix test]

The most important planning move is to separate evidence lanes: Tier A source contracts prove manifest/ratchet/route truth, Tier B representative Chromium checks prove current rendered behavior without broad pixel churn, and Tier C local/human screenshots create the full current rendered audit packet. [VERIFIED: 181-CONTEXT.md] [CITED: https://playwright.dev/docs/test-snapshots]

**Primary recommendation:** Use existing Threadline guardrails and `examples/threadline_phoenix/e2e/run-e2e.sh`; create the four Phase 181 audit packet artifacts; repair stale selectors/comments/contracts only when they restore accepted v1.37/v1.38 invariants; do not add or upgrade packages. [VERIFIED: codebase grep] [VERIFIED: npm registry]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Baseline page/JTBD audit packet | Planning/documentation | Browser / Client | The packet is a planner artifact, while rendered evidence comes from browser snapshots and semantic Playwright assertions. [VERIFIED: 181-CONTEXT.md] |
| Stable route and feature-gate truth | Frontend Server (Phoenix router/LiveView) | API / Backend | Mounted LiveViews, `live_session`, `on_mount`, export auth, and feature gates live in Phoenix routing/auth boundaries. [VERIFIED: lib/threadline/operator_surface/router.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| `/audit/__stress` registry and ledger parity | Frontend Server (LiveView/source contracts) | Planning/documentation | Stress stories are synthetic DB-free LiveView fixtures tied to `.planning/design-system-ledger.json` and `DESIGN-SYSTEM.md`. [VERIFIED: lib/threadline/operator_surface/stress_fixtures.ex] |
| Screenshot baseline and rendered overflow checks | Browser / Client | Planning/documentation | Playwright owns screenshots, viewport checks, masks, and current rendered evidence; docs record local/CI distinction. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts] [CITED: https://playwright.dev/docs/test-snapshots] |
| Accessibility and motion proof | Browser / Client | CSS/source contracts | Playwright proves sampled role/name/focus/computed motion; ExUnit source contracts guard token and APG-like invariants. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts] [CITED: https://www.w3.org/TR/WCAG22/] |
| Design-system ratchet | Planning/documentation | Frontend Server | Ledger and docs are planning artifacts, while `StressFixtures` and tests enforce story/projection/source consistency. [VERIFIED: test/threadline/operator_surface/stress_ledger_test.exs] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 with Erlang/OTP 28 | Root ExUnit/source contracts and Mix aliases | Installed locally and used by `mix test`, `mix verify.*`, and `mix ci.all`. [VERIFIED: elixir --version] |
| Phoenix | Locked 1.8.7; registry latest 1.8.8 | Example app router/server and mounted operator surface | Existing example app is Phoenix 1.8; do not upgrade in Phase 181. [VERIFIED: mix hex.info phoenix] |
| Phoenix LiveView | Locked 1.1.30; registry latest 1.2.3 | Operator LiveViews, `live_session`, `on_mount`, function components | Current code and tests are built on optional LiveView boundaries. [VERIFIED: mix.lock] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| Playwright Test | Installed 1.60.0; registry latest 1.61.1 | Browser semantics, screenshots, accessibility-tree, motion, stress checks | Existing E2E harness uses `@playwright/test`; repair selectors in place instead of upgrading. [VERIFIED: npm registry] [VERIFIED: npm ls] |
| Threadline stress ledger | 130 entries; 77 page stories | Ratchet, required inventory, screenshot allowlist, fixture/story parity | Existing source contracts enforce no silent deletion or score backslide. [VERIFIED: .planning/design-system-ledger.json] |
| `examples/threadline_phoenix/e2e/run-e2e.sh` | Repo script | Example app bootstrap, demo seed, free-port server, Playwright run | Use this instead of hand-running Phoenix/Playwright setup steps. [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `lazy_html` | Locked 0.1.11 | HTML parsing/querying in tests | Use where existing tests already parse HTML structurally; avoid adding new parsers. [VERIFIED: mix hex.info lazy_html] |
| PhoenixStorybook | Registry latest 1.2.0; not installed | Future example-app component story lane | Link context only in Phase 181; implementation belongs to Phase 182. [CITED: https://hexdocs.pm/phoenix_storybook/setup.html] |
| WAI-ARIA APG | Current W3C guide | Widget role/state/keyboard reference | Use for audit rationale and proof-gap classification, not as a new dependency. [CITED: https://www.w3.org/WAI/ARIA/apg/] |
| WCAG 2.2 | W3C Recommendation | Focus, target size, reduced-motion-related criteria | Use to classify a11y/focus/motion proof gaps and avoid overclaiming AT behavior. [CITED: https://www.w3.org/TR/WCAG22/] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing Playwright screenshots | Full page x path x theme x viewport CI pixel matrix | Too flaky/costly for baseline; use Tier C local packet plus bounded CI allowlist. [VERIFIED: 181-CONTEXT.md] |
| Existing semantic Playwright assertions | Axe or another accessibility dependency | Phase 180 intentionally added no a11y dependency; current proof is role/name/focus/accessibility-tree bounded. [VERIFIED: 180-VERIFICATION.md] |
| `/audit/__stress` for operator-flow evidence | PhoenixStorybook as replacement | Storybook documents components; stress route proves authenticated operator flows and ledger ratchet. [VERIFIED: 181-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_storybook/setup.html] |
| Existing source contracts | External visual service such as Chromatic/Percy/Applitools | Current tests explicitly ban those terms in stress/ledger surfaces; adding them contradicts v1.37 constraints. [VERIFIED: test/threadline/operator_surface/stress_ledger_test.exs] |

**Installation:**
```bash
# Phase 181 installs no new packages.
# Keep the existing lockfiles and run existing verification commands.
```

**Version verification:** Versions above were checked with `elixir --version`, `mix hex.info`, `npm ls @playwright/test`, `npm view @playwright/test`, and `npx playwright --version` on 2026-06-26. [VERIFIED: local commands]

## Package Legitimacy Audit

Phase 181 should not install external packages. [VERIFIED: 181-CONTEXT.md]

| Package | Registry | Age / Currentness | Downloads / Source Repo | Verdict | Disposition |
|---------|----------|-------------------|--------------------------|---------|-------------|
| `@playwright/test` | npm | Installed 1.60.0 published 2026-05-11; latest 1.61.1 modified 2026-06-26 | 41,891,083 weekly downloads; `github.com/microsoft/playwright` | Existing package; latest flagged `SUS` by GSD seam because too-new | Keep locked; if any plan upgrades Playwright, add a human checkpoint. [VERIFIED: npm registry] |
| `phoenix_storybook` | Hex | Latest 1.2.0 released 2026-06-11 | 7,677 last-7-day downloads; `github.com/phenixdigital/phoenix_storybook` | Not checked by GSD package-legitimacy seam because seam supports npm/pypi/crates only | Do not install in Phase 181; Phase 182 must run a fresh Hex-specific check. [VERIFIED: mix hex.info phoenix_storybook] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy check]  
**Packages flagged as suspicious [SUS]:** `@playwright/test` latest only; no Phase 181 install or upgrade should occur. [VERIFIED: package-legitimacy check]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 181 inputs
  |
  v
CONTEXT + REQUIREMENTS + v1.37 artifacts + current code/tests
  |
  v
Audit packet builder
  |--> Page/JTBD matrix -> 181-BASELINE-AUDIT.md
  |--> Screenshot lane inventory -> 181-SCREENSHOT-INVENTORY.md
  |--> Stale guard scan + repairs -> 181-GUARD-REPAIR.md
  |--> Requirement proof map -> 181-VERIFICATION.md
  |
  v
Verification
  |--> Tier A: ExUnit source contracts for ledger/routes/style/copy/stress
  |--> Tier B: Playwright rendered checks via run-e2e.sh
  |--> Tier C: local screenshot packet with OPERATOR_SCREENSHOT_DIR
  |
  v
Later phases 183-187 consume owned findings without reopening baseline scope
```

### Recommended Project Structure

```text
.planning/phases/181-baseline-audit-and-guard-repair/
├── 181-RESEARCH.md              # this planner input
├── 181-BASELINE-AUDIT.md        # page/JTBD matrix and issue taxonomy
├── 181-SCREENSHOT-INVENTORY.md  # CI/local screenshot coverage and stale baselines
├── 181-GUARD-REPAIR.md          # stale selector/source-contract findings and repairs
├── 181-VERIFICATION.md          # BASE-01..03 evidence
└── screenshots/                 # optional local Tier C packet output, ignored if generated
```

### Pattern 1: Repair selectors by semantic intent first

**What:** Prefer `getByRole`, `getByLabel`, and URL/rendered behavior for user-facing semantics; use `getByTestId` when the stable ID itself is the contract. [CITED: https://playwright.dev/docs/locators]  
**When to use:** Apply this to stale E2E selectors in `examples/threadline_phoenix/e2e/tests/*.spec.ts`. [VERIFIED: codebase grep]

```typescript
// Source: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
await expect(page.getByRole("heading", { name: "Retention window" })).toBeVisible();
await expect(page.getByRole("button", { name: "Run retention prune" }).last()).toBeVisible();
```

### Pattern 2: Keep pixel screenshots bounded and masked

**What:** Use Playwright `toHaveScreenshot` only for intentionally bounded baselines; mask dynamic content such as time and generated IDs. [CITED: https://playwright.dev/docs/test-snapshots]  
**When to use:** Apply to stress CI allowlist and local screenshot regression, not the full page/path/theme matrix. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts]

```typescript
// Source: examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
await expect(preview).toHaveScreenshot(item.baseline_ref, {
  maxDiffPixelRatio: 0.01,
  mask: dynamicMasks(page),
});
```

### Pattern 3: Enforce ledger -> fixture -> projection parity

**What:** Treat `.planning/design-system-ledger.json` as source of truth; verify every story resolves through `StressFixtures`, and every ledger row appears in `DESIGN-SYSTEM.md`. [VERIFIED: test/threadline/operator_surface/stress_ledger_test.exs]  
**When to use:** Any Phase 181 ledger/doc/screenshot repair must update JSON first, projection second, and tests third. [VERIFIED: DESIGN-SYSTEM.md]

```elixir
# Source: test/threadline/operator_surface/stress_ledger_test.exs
for story <- StressFixtures.all() do
  assert Map.has_key?(by_id, story.ledger_id)
  assert by_id[story.ledger_id]["story_id"] == story.id
end
```

### Pattern 4: Record stale guard retirement with owner and replacement

**What:** If a test or selector references a removed contract, either update it to the current stable behavior or retire it in `181-GUARD-REPAIR.md` with rationale and later-phase owner. [VERIFIED: 181-CONTEXT.md]  
**When to use:** Use this for stale `RED today`, stale #4521-style seed assumptions, old copy strings, or retired feature-gate names. [VERIFIED: rg stale scan]

### Anti-Patterns to Avoid

- **Baseline as redesign:** Do not improve Shell/Home/Timeline/Coverage visual hierarchy in this phase; assign findings to later phase owners. [VERIFIED: 181-CONTEXT.md]
- **Dependency churn:** Do not upgrade Phoenix, LiveView, Playwright, or add PhoenixStorybook/axe/visual services in Phase 181. [VERIFIED: mix.lock] [VERIFIED: npm registry]
- **Ratchet lowering:** Do not reduce `current_score`, remove locked IDs, or shrink screenshot allowlists without explicit reset rationale. [VERIFIED: test/threadline/operator_surface/stress_ledger_test.exs]
- **Screenshot-only evidence:** Do not use screenshots as proof for route/auth/a11y/motion contracts; pair them with source and semantic browser checks. [VERIFIED: 180-VERIFICATION.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser bootstrap | Custom Phoenix server scripts | `examples/threadline_phoenix/e2e/run-e2e.sh` | It already chooses a free port, resets/seeds demo data, installs Chromium, and cleans exports. [VERIFIED: run-e2e.sh] |
| Visual regression engine | Manual pixel diff or external service | Playwright `toHaveScreenshot` with masks and bounded allowlist | Existing guard and official docs support this directly. [VERIFIED: operator-stress.spec.ts] [CITED: https://playwright.dev/docs/test-snapshots] |
| Component/story registry | New JSON/schema system | `Threadline.OperatorSurface.StressFixtures` + ledger | Current tests enforce story IDs, fixture keys, themes, viewports, and ledger parity. [VERIFIED: stress_fixtures_test.exs] |
| Accessibility claim framework | New certification/audit layer | APG/WCAG references plus existing Playwright role/name/focus snapshots | Phase 180 explicitly bounds automated proof and does not claim real AT UAT. [VERIFIED: 180-AUTOMATED-A11Y-EVIDENCE.md] [CITED: https://www.w3.org/WAI/ARIA/apg/] |
| Auth/feature-gate proof | Browser-only login assertions | Router/Auth/ExportAuth source contracts plus rendered checks | LiveView `on_mount` and separate export controller auth are server boundaries. [VERIFIED: router.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| Full audit taxonomy prose | Free-form issue notes | D-181 issue taxonomy | Later phases need owned, filterable categories. [VERIFIED: 181-CONTEXT.md] |

**Key insight:** Phase 181 is a truth-preservation phase; custom tooling adds more contracts to audit, while the repo already has the substrate needed to prove current rendered truth. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Green tests with stale RED wording
**What goes wrong:** Comments or failure messages still say "RED today" after a prior phase made the test green. [VERIFIED: rg stale scan]  
**Why it happens:** Wave-0 tests were promoted but prose was not updated. [VERIFIED: test/threadline/operator_surface/stress_fixtures_test.exs]  
**How to avoid:** Add a guard-repair pass over `RED today`, `RED until`, `removed`, and old phase-owner wording; repair comments when tests are current. [VERIFIED: rg stale scan]  
**Warning signs:** Current targeted tests pass while assertion messages describe old failure states. [VERIFIED: mix test]

### Pitfall 2: Confusing Storybook and stress route responsibilities
**What goes wrong:** A plan may try to replace `/audit/__stress` with PhoenixStorybook or expose story routes in production. [VERIFIED: 181-CONTEXT.md]  
**Why it happens:** Both are "story" surfaces, but only the stress route proves authenticated operator-flow fixture and ledger evidence. [VERIFIED: stress_router_test.exs]  
**How to avoid:** Phase 181 links Storybook research/context only; Phase 182 implements example-app dev/test Storybook separately. [CITED: https://hexdocs.pm/phoenix_storybook/setup.html]  
**Warning signs:** Root `mix.exs` gains `phoenix_storybook`, or production router exposes a story/stress route. [VERIFIED: stress_router_test.exs]

### Pitfall 3: Full screenshot matrix explosion
**What goes wrong:** CI becomes slow/flaky by snapshotting every page x path x theme x viewport. [VERIFIED: 181-CONTEXT.md]  
**Why it happens:** BASE-01 asks for current rendered truth, but pixel baselines are only one evidence type. [VERIFIED: 181-CONTEXT.md]  
**How to avoid:** Keep Tier A full source/manifest matrix, Tier B representative rendered checks, and Tier C local packet screenshots. [VERIFIED: 181-CONTEXT.md]  
**Warning signs:** Plans add dozens or hundreds of new committed PNG baselines in CI. [VERIFIED: operator-stress.spec.ts]

### Pitfall 4: Lowering ratchets to make stale docs pass
**What goes wrong:** A ledger/doc repair silently lowers `current_score`, removes a locked ID, or drops a story. [VERIFIED: stress_ledger_test.exs]  
**Why it happens:** Projection drift is easier to silence than to fix correctly. [VERIFIED: stress_ledger_test.exs]  
**How to avoid:** Update ledger JSON first, regenerate/repair `DESIGN-SYSTEM.md`, and run stress ledger/fixture/router tests. [VERIFIED: DESIGN-SYSTEM.md]  
**Warning signs:** `ratchet.resets`, `locked_ids`, or `minimum_scores` change without explicit rationale. [VERIFIED: .planning/design-system-ledger.json]

### Pitfall 5: Overclaiming accessibility evidence
**What goes wrong:** Browser accessibility-tree snapshots are described as real screen-reader certification. [VERIFIED: 180-AUTOMATED-A11Y-EVIDENCE.md]  
**Why it happens:** Playwright ARIA snapshots are useful but not equivalent to NVDA, VoiceOver, JAWS, Narrator, TalkBack, or human AT UAT. [VERIFIED: 180-AUTOMATED-A11Y-EVIDENCE.md]  
**How to avoid:** Label proof as automated browser evidence and record real AT UAT as a residual gap unless run. [CITED: https://www.w3.org/TR/WCAG22/]  
**Warning signs:** `181-VERIFICATION.md` claims screen-reader support without a named real AT run. [VERIFIED: 180-AUTOMATED-A11Y-EVIDENCE.md]

### Pitfall 6: Running light lane against the wrong compiled theme
**What goes wrong:** A light/system check passes against stale dark-compiled router code or runs dark projects against a system mount. [VERIFIED: run-e2e.sh]  
**Why it happens:** The example router selects `:system` at compile time via `THREADLINE_E2E_THEME=system`. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]  
**How to avoid:** Use `mix verify.example_browser_light` or `THREADLINE_E2E_THEME=system ./examples/threadline_phoenix/e2e/run-e2e.sh ...`. [VERIFIED: mix.exs]  
**Warning signs:** `desktop-chromium-light` appears in default dark runs or light assertions run without `THREADLINE_E2E_THEME=system`. [VERIFIED: playwright.config.ts]

## Code Examples

### Current screenshot packet capture

```bash
# Source: examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
OPERATOR_SCREENSHOT_DIR=.planning/phases/181-baseline-audit-and-guard-repair/screenshots \
  ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshots.spec.ts
```

### Current bounded stress screenshot guard

```bash
# Source: mix.exs
mix verify.operator_stress
```

### Current source-contract ratchet slice

```bash
# Source: targeted research verification run
mix test \
  test/threadline/operator_surface/stress_ledger_test.exs \
  test/threadline/operator_surface/stress_fixtures_test.exs \
  test/threadline/operator_surface/stress_router_test.exs \
  test/threadline/operator_surface/surface_header_test.exs \
  test/threadline/operator_surface/style_contract_test.exs
```

### Stale guard scan

```bash
# Source: research grep pass
rg -n "RED today|RED until|removed contract|stale selector|#4521|not-real|test\\.skip|skip\\(" \
  test/threadline/operator_surface examples/threadline_phoenix/e2e/tests lib/threadline/operator_surface
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Screenshot dump as audit | Audit packet with JTBD, route/render evidence, stale selectors, taxonomy, and guard disposition | Phase 181 decisions on 2026-06-26 | Planner can assign findings to phases 183-187 without re-auditing. [VERIFIED: 181-CONTEXT.md] |
| Broad pixel proof | Tiered source/rendered/local evidence | Phase 181 decisions on 2026-06-26 | Preserves BASE-01 without CI snapshot explosion. [VERIFIED: 181-CONTEXT.md] |
| Component-only story thinking | Stress route for authenticated operator-flow ratchet; Storybook later for example-app component docs | v1.38 research and Phase 181 context | Prevents Storybook from replacing auth/route/page-state proof. [VERIFIED: .planning/research/v1.38-operator-ui-page-polish.md] |
| Manual a11y checkpoint | Playwright role/name/focus/accessibility-tree evidence with explicit AT limits | Phase 180 closeout on 2026-06-20 | Useful automation stays honest about real screen-reader gaps. [VERIFIED: 180-AUTOMATED-A11Y-EVIDENCE.md] |

**Deprecated/outdated:**
- `RED today` / `RED until` comments in currently green tests are stale planning noise and should be audited in guard repair. [VERIFIED: rg stale scan] [VERIFIED: mix test]
- Hard-coded old demo seed assumptions such as historical #4521 references caused prior residual CI drift; Phase 180 replaced some screenshot discovery with current `ticket_replies` discovery. [VERIFIED: 180-RESIDUAL-CI.md]
- Root Storybook dependency, production stress/story routes, Tailwind/shadcn migration, and runtime destructive redaction remain out of scope. [VERIFIED: 181-CONTEXT.md]

## Assumptions Log

All claims in this research were verified from the codebase, local commands, GSD seams, or cited official documentation. [VERIFIED: codebase grep]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None | — | — |

## Open Questions (RESOLVED)

1. **Should Phase 181 run full `mix ci.all`, or keep verification targeted?**  
   What we know: Phase 180 recorded inherited `mix ci.all` residuals from docs/demo seed, while Phase 181 targeted source-contract slices passed 133 tests during research. [VERIFIED: 180-RESIDUAL-CI.md] [VERIFIED: mix test]  
   Prior uncertainty: Whether those inherited residuals are still present today was not rechecked with full `mix ci.all` because that command runs the full example/browser path. [VERIFIED: research command log]
   Resolution: Phase 181 uses targeted task and wave gates first, then the closeout plan runs full `mix ci.all`; if it is non-green, `181-VERIFICATION.md` must classify exact inherited residuals with evidence they are unrelated to Phase 181. [VERIFIED: 181-CONTEXT.md]

2. **How much stale Wave-0 prose should be repaired?**  
   What we know: Multiple current-green tests still contain old "RED today" or "RED until" wording. [VERIFIED: rg stale scan]  
   Prior uncertainty: Some wording lives in historical explanatory comments and may not affect behavior. [VERIFIED: codebase grep]
   Resolution: Repair active source/test comments, failure messages, test names, and selector prose that can mislead future planners; leave historical phase docs unchanged, and record retained historical references with rationale in `181-GUARD-REPAIR.md`. [VERIFIED: 181-CONTEXT.md]

3. **Where should generated screenshot packet files live?**  
   What we know: `operator-screenshots.spec.ts` writes durable screenshots only when `OPERATOR_SCREENSHOT_DIR` is set. [VERIFIED: operator-screenshots.spec.ts]  
   Prior uncertainty: Whether Phase 181 wants committed images, untracked local evidence, or markdown inventory links only. [VERIFIED: 181-CONTEXT.md]
   Resolution: Default to `181-SCREENSHOT-INVENTORY.md` plus optional local `screenshots/` output for the Tier C packet; generated packet PNGs may stay local, and committed PNG changes are limited to accepted bounded CI/local baseline updates that are recorded in the inventory with command, project, surface, viewport, and rationale. [VERIFIED: 181-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | ExUnit source contracts | yes | Elixir 1.19.5 / Mix 1.19.5 | None needed. [VERIFIED: elixir --version] |
| Erlang/OTP | Elixir runtime | yes | OTP 28 | None needed. [VERIFIED: elixir --version] |
| Node.js | Playwright E2E | yes | v22.14.0 | None needed. [VERIFIED: node --version] |
| npm | Playwright install/run | yes | 11.1.0 | None needed. [VERIFIED: npm --version] |
| Playwright CLI | Browser tests | yes | 1.60.0 | Use `npm ci` via `run-e2e.sh` if missing. [VERIFIED: npx playwright --version] |
| PostgreSQL / `pg_isready` | Example app E2E seed | yes | `/tmp:5432 accepting connections`, psql 14.17 | Docker or local Postgres config. [VERIFIED: pg_isready] |
| Docker | Optional local services | yes | 29.5.2 | Local Postgres is already accepting connections. [VERIFIED: docker info] |
| ripgrep | Stale selector/source scans | yes | 15.1.0 | `grep` fallback. [VERIFIED: rg --version] |
| git | Status/commit/docs | yes | 2.41.0 | None needed. [VERIFIED: git --version] |

**Missing dependencies with no fallback:** none found. [VERIFIED: local commands]  
**Missing dependencies with fallback:** none found. [VERIFIED: local commands]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Elixir 1.19.5; Playwright Test 1.60.0. [VERIFIED: elixir --version] [VERIFIED: npx playwright --version] |
| Config file | `mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_router_test.exs` [VERIFIED: mix test] |
| Full suite command | `mix ci.all` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BASE-01 | Current rendered audit of all `/audit` pages and stale selector/test inventory | Browser + docs | `OPERATOR_SCREENSHOT_DIR=.planning/phases/181-baseline-audit-and-guard-repair/screenshots ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshots.spec.ts` plus stale grep | yes for E2E spec; packet docs are Wave 0. [VERIFIED: operator-screenshots.spec.ts] |
| BASE-02 | Ledger, projection, screenshot allowlist, and E2E ratchet stay fresh without score backslide | Unit + browser | `mix test test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_router_test.exs && mix verify.operator_stress` | yes. [VERIFIED: mix test] |
| BASE-03 | Compact research/decision context is linked for Storybook, stress, nav IA, a11y, motion, and personas | Docs/source | `rg -n "PhoenixStorybook|/audit/__stress|APG|WCAG|operator JTBD|persona|motion" .planning/phases/181-baseline-audit-and-guard-repair/*.md` after artifacts are written | docs are Wave 0. [VERIFIED: 181-CONTEXT.md] |

### Sampling Rate

- **Per task commit:** Run the relevant targeted ExUnit file plus the stale grep for files touched. [VERIFIED: mix test]
- **Per wave merge:** Run the source-contract slice and targeted Playwright specs for touched browser behavior. [VERIFIED: codebase grep]
- **Phase gate:** Run `mix ci.all` or record exact inherited residuals in `181-VERIFICATION.md`; do not close with ambiguous red CI. [VERIFIED: 180-RESIDUAL-CI.md]

### Wave 0 Gaps

- [ ] `.planning/phases/181-baseline-audit-and-guard-repair/181-BASELINE-AUDIT.md` - covers BASE-01 page/JTBD matrix. [VERIFIED: 181-CONTEXT.md]
- [ ] `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md` - covers BASE-01 and BASE-02 screenshot lanes. [VERIFIED: 181-CONTEXT.md]
- [ ] `.planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md` - covers BASE-01 stale selectors/tests and BASE-02 ratchet repairs. [VERIFIED: 181-CONTEXT.md]
- [ ] `.planning/phases/181-baseline-audit-and-guard-repair/181-VERIFICATION.md` - covers BASE-01..03 final evidence. [VERIFIED: 181-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Preserve host-owned auth, `authorize_fn`, `on_mount`, and stress route auth; do not make browser checks the only proof. [VERIFIED: router.ex] |
| V3 Session Management | yes | Keep server-resolved theme/session behavior and LiveView test-only origin override scoped to test config. [VERIFIED: run-e2e.sh] |
| V4 Access Control | yes | Preserve separate coverage/evidence/policy/export authorize callbacks and fail-closed stress/prod route behavior. [VERIFIED: stress_router_test.exs] |
| V5 Input Validation | yes | Keep allowlist-normalized stress query params and avoid `String.to_atom` on untrusted params. [VERIFIED: stress_router_test.exs] |
| V6 Cryptography | yes | Do not hand-roll crypto; existing destructive retention confirmation uses `Plug.Crypto.secure_compare` and is out of scope except guard truth. [VERIFIED: 178-VERIFICATION.md] |

### Known Threat Patterns for Phoenix LiveView operator surfaces

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stress/story route exposed in production | Information Disclosure / Elevation of Privilege | Compile-time stress route fail-closed checks and no production story route. [VERIFIED: stress_router_test.exs] |
| Browser-only auth proof misses server route drift | Elevation of Privilege | Pair Playwright login checks with router/auth/export source tests. [VERIFIED: router_test.exs] |
| Stale selector false pass | Tampering / Repudiation | Repair selectors to current role/name/testid/URL contracts and record retired contracts. [CITED: https://playwright.dev/docs/locators] |
| Unsafe param-to-atom conversion | Denial of Service | Keep allowlists and refute `String.to_atom` in stress source. [VERIFIED: stress_router_test.exs] |
| Screenshot packet leaks dynamic or sensitive data | Information Disclosure | Mask dynamic elements and keep local review screenshots scoped; commit only intentional baselines. [VERIFIED: operator-screenshot-regression.spec.ts] |
| Accessibility overclaim | Repudiation | Record automated proof boundaries and avoid claiming real AT UAT. [VERIFIED: 180-AUTOMATED-A11Y-EVIDENCE.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/181-baseline-audit-and-guard-repair/181-CONTEXT.md` - locked phase scope, audit packet shape, tiered matrix, personas/JTBD, deferred boundaries. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - BASE-01, BASE-02, BASE-03 and v1.38 invariants. [VERIFIED: codebase grep]
- `CLAUDE.md` and `examples/threadline_phoenix/AGENTS.md` - project constraints and Phoenix/Elixir conventions. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/*`, `test/threadline/operator_surface/*`, and `examples/threadline_phoenix/e2e/tests/*` - current guardrail implementation. [VERIFIED: codebase grep]
- Targeted research verification: 88 source-contract tests passed, and 45 additional old Wave-0 guard tests passed. [VERIFIED: mix test]

### Secondary (MEDIUM confidence)

- Playwright locators official docs - role/label/testid locator guidance. [CITED: https://playwright.dev/docs/locators]
- Playwright visual comparisons official docs - `toHaveScreenshot` and diff options. [CITED: https://playwright.dev/docs/test-snapshots]
- Phoenix LiveView Router and Component docs - `live_session`, `on_mount`, attrs, and slots. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]
- PhoenixStorybook docs - setup, router, assets, sandboxing, stories/variations. [CITED: https://hexdocs.pm/phoenix_storybook/setup.html]
- W3C APG and WCAG 2.2 - accessibility patterns and current success criteria. [CITED: https://www.w3.org/WAI/ARIA/apg/] [CITED: https://www.w3.org/TR/WCAG22/]

### Tertiary (LOW confidence)

- None used as authoritative support. [VERIFIED: research protocol]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions came from local lockfiles, local commands, npm registry, and Hex info. [VERIFIED: npm registry] [VERIFIED: mix hex.info]
- Architecture: HIGH - phase boundaries and guard ownership came from CONTEXT.md plus current source/tests. [VERIFIED: 181-CONTEXT.md]
- Pitfalls: HIGH - derived from current grep findings, green targeted tests, and prior v1.37 verification artifacts. [VERIFIED: rg stale scan] [VERIFIED: mix test]
- External docs: MEDIUM - official docs were fetched via web fallback because Context7 CLI was unavailable. [CITED: official docs]

**Research date:** 2026-06-26  
**Valid until:** 2026-07-03 for Playwright/PhoenixStorybook registry currentness; 2026-07-26 for repo-internal architecture unless Phase 181 changes the guardrails. [VERIFIED: npm registry] [VERIFIED: mix hex.info]
