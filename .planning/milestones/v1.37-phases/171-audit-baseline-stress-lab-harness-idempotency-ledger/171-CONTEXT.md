# Phase 171: Audit baseline, stress-lab harness & idempotency ledger - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 171 builds the idempotent design-system audit harness that later v1.37 phases ratchet against: a dev/test-only stress render surface for the operator UI, a living `DESIGN-SYSTEM.md` v2 inventory, a machine-checkable score ledger with a no-regression ratchet, and deterministic ugly-data fixtures. It must not extract the component system yet, implement later UI fixes, alter capture/semantics layers, add runtime dependencies, or expose a new adopter-facing public component API.

</domain>

<decisions>
## Implementation Decisions

### Stress Route Boundary
- **D-01:** Build the stress surface as an internal dev/test-only router/macro, tentatively `Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress/2`, mounted by the example app adjacent to the real `/audit` surface at `/audit/__stress`.
- **D-02:** Do not add a `stress: true` option to `threadline_operator_surface/2`. The main operator router macro remains the adopter-facing mount API; the stress route is internal harness infrastructure.
- **D-03:** The stress route must reuse the real operator shell/auth/theme path as much as practical: host-owned pipeline, authenticated `/audit` scope, `Auth`/coverage `on_mount` behavior, `data-tl-theme`, and the same inline style/component assets.
- **D-04:** The stress route must fail closed in production. Acceptable mechanisms include compile-time omission or compile-time raise under `MIX_ENV=prod`; planning must include tests proving `/audit/__stress` does not exist in production and is not reachable without the example operator auth path.
- **D-05:** Avoid Phoenix route namespace surprises: use scope-local alias hygiene, `as: false` where applicable, and a stress-specific `live_session` name if adding a second `live_session` would collide with `:threadline`.

### Fixture Source Of Truth
- **D-06:** Use a hybrid fixture model. Static library-side stress fixtures are the canonical source for `/audit/__stress`, DS-04 ugly-data coverage, ledger IDs, and stress screenshots.
- **D-07:** Keep the example-app seeded database as a smaller integration truth lane for real routed pages and workflow screenshots. Do not force every stress state through Ecto rows or example seed data.
- **D-08:** Introduce a plain internal fixture/story registry, tentatively `Threadline.OperatorSurface.StressFixtures`, with stable IDs, categories, scenario names, and assigns/story data that later component phases can reuse. This borrows the useful Storybook/PhoenixStorybook "named variations" idea without adding PhoenixStorybook or any runtime dependency.
- **D-09:** The ugly-data matrix must include the DS-04 cases: empty, one, many, long IDs/strings, non-ASCII, high/zero counts, null fields, error/warning/mixed severity, permission-denied, stale, reconnecting, timezone, and pagination boundaries.
- **D-10:** Fixture adapters must be tested so static stress data does not drift away from the shapes consumed by existing LiveViews and future function components.

### Ledger Shape And Ratchet
- **D-11:** Use a machine-readable JSON sidecar as the ratchet source of truth, with `DESIGN-SYSTEM.md` v2 as the human-reviewed projection.
- **D-12:** The JSON ledger should be stable and deterministic: sorted entries, stable IDs, explicit `kind`/`category`, status, current score, target/ratchet score, stress-route path or story key, fixture key, screenshot baseline refs, notes, and ownership/phase metadata where useful.
- **D-13:** Add ExUnit/source-contract coverage for ledger schema, deterministic ordering, generated markdown freshness, and ratchet semantics. A rerun may raise scores but must not silently lower or delete existing scored items.
- **D-14:** Prefer existing project patterns over new infrastructure: use `Jason` for JSON, custom ExUnit failure messages like `brandbook_token_parity_test.exs`, and a small Mix/check helper only if it keeps `DESIGN-SYSTEM.md` generated and fresh.
- **D-15:** Do not use YAML for the ledger; the project has no YAML parser and ad hoc parsing would be worse than JSON. Do not make an Elixir module the canonical ledger source because design audit data should remain a planning/design-system artifact, not app source truth.

### Screenshot Baseline Policy
- **D-16:** Phase 171 should not pixel-baseline the full component x state x theme x viewport matrix immediately. Create the full manifest/registry, then start with a narrow high-signal CI screenshot allowlist that later phases must expand through the ledger.
- **D-17:** CI screenshot comparison should run in a pinned Linux/Playwright environment so visual failures are actionable and not macOS/Linux/font noise. Local broad screenshots may exist as review artifacts, but they are not the canonical ratchet.
- **D-18:** Full-matrix semantic/computed guards should run in CI before broad pixel coverage exists: route presence/gating, fixture registry completeness, stable IDs, required states, theme attributes, focus/role/aria markers where available, and reduced-motion assumptions.
- **D-19:** Pixel baselines must use deterministic fixtures, reduced motion, explicit viewport/theme naming, masks for dynamic values, and a bounded allowlist owned by the JSON ledger. Later phases promote additional stress cells to CI screenshots; removals require an explicit ledger update and rationale.
- **D-20:** Do not introduce external visual services or Storybook-like dependencies in Phase 171. The harness stays inline, Phoenix/LiveView-native, and repo-local.

### Folded Todos
- **D-21:** `theme-picker-idiomatic-ui` is folded into Phase 171 as a known future stress/ledger case only. Phase 171 should reserve stress/ledger slots for the dark/light/system theme-picker states, but implementation remains Phase 175.
- **D-22:** `coverage-schema-card-declutter` is folded into Phase 171 as a known future stress/ledger case only. Phase 171 should represent the coverage card-in-card nesting footgun in the baseline inventory/ledger, but the layout fix remains Phase 176.
- **D-23:** `transaction-page-left-push-desktop` is folded into Phase 171 as a known future stress/ledger case only. Phase 171 should record the desktop-centering issue as a page-level baseline/ledger item, but the fix remains Phase 178.

### the agent's Discretion
The user explicitly asked for advisor-style research and a cohesive one-shot recommendation, so downstream agents should treat the decisions above as locked unless implementation research finds a concrete codebase blocker. Research/planning may refine names and exact file placement, but should preserve the architecture: internal stress mount, static stress fixtures plus seeded integration lane, JSON ratchet source plus markdown projection, and bounded pinned-CI screenshots expanded by ledger.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` - Phase 171 goal, dependencies, success criteria, and v1.37 execution order.
- `.planning/REQUIREMENTS.md` - DS-01 through DS-04 requirements and milestone invariants.
- `.planning/PROJECT.md` - Current milestone description, product posture, and design-system stress-test goal.
- `.planning/STATE.md` - Current phase state, deferred items, carried-todo mappings, and recent v1.36/v1.37 continuity.
- `/Users/jon/.claude/plans/design-system-stress-test-fancy-gizmo.md` - Approved plan of record for v1.37; use as canonical if roadmap summary is ambiguous.

### Operator Surface Code
- `lib/threadline/operator_surface/router.ex` - Current adopter-facing mount macro, route set, auth gating, export sibling routes, and `theme:` option.
- `lib/threadline/operator_surface/auth.ex` - `on_mount` assigns for auth, scope, feature gates, and current static theme handling.
- `lib/threadline/operator_surface/style.ex` - Current inline design-system token/class/motion source.
- `lib/threadline/operator_surface/components/surface_header.ex` - Existing shell/header/nav component and feature-gated navigation shape.
- `lib/threadline/operator_surface/components/icon.ex` - Existing internal icon component.
- `lib/threadline/operator_surface/components/logo.ex` - Existing internal logo component.
- `lib/threadline/operator_surface/components/unsupported_view.ex` - Existing unsupported/fallback component pattern.
- `lib/threadline/operator_surface/live/*.ex` - Existing page-level LiveViews with inline class-heavy HEEx that the stress harness must inventory before later extraction.
- `lib/threadline/operator_surface/presentation.ex` - Shared presentation helpers for operation/status/value labels.

### Example App And Browser Harness
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - Existing `/audit` example mount, auth pipeline, and compile-time light/system E2E theme switch.
- `examples/threadline_phoenix/e2e/playwright.config.ts` - Existing Playwright projects, reduced-motion default, snapshot naming, and conditional light lane.
- `examples/threadline_phoenix/e2e/run-e2e.sh` - Existing E2E server/bootstrap script and theme-lane recompilation behavior.
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` - Existing durable screenshot capture pattern and dynamic-state handling.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` - Existing local screenshot regression guard and masking patterns.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - Existing accessibility browser coverage to extend or mirror for stress states.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - Existing responsive checks relevant to stress viewport policy.
- `mix.exs` - `verify.example_browser`, `verify.example_browser_light`, `ci.all`, and named verification entrypoint patterns.

### Existing Contract Patterns
- `test/threadline/operator_surface/router_test.exs` - Router macro validation and compile-time option tests.
- `test/threadline/operator_surface/gating_test.exs` - Conditional module load pattern.
- `test/threadline/operator_surface/style_contract_test.exs` - Source-contract pattern for CSS/design-system invariants and motion inventory checks.
- `test/threadline/brandbook_token_parity_test.exs` - JSON/CSS/source parity pattern and high-quality failure-message style.
- `.planning/milestones/v1.31-phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` - Prior human-readable inventory guarded by source tests.

### Brand And Product Guidance
- `brandbook/brand-book.md` - Current brand voice, visual principles, dark/light strategy, and banned framing. Supersedes older prompt brand text.
- `brandbook/pressure-test.md` - Current brand QA posture, mechanical gates, token rigor, and dark/light versatility expectations.
- `brandbook/tokens.json` - Current brand token source used by parity tests.
- `brandbook/tokens.css` - CSS token projection used by parity tests.
- `prompts/threadline-elixir-oss-dna.md` - Project DNA: verification as product surface, named `mix verify.*` entrypoints, nested example-app footguns, traceability, and audit-ledger discipline.
- `prompts/audit-lib-domain-model-reference.md` - Product/persona/JTBD guidance for operators, app developers, SRE/platform, security/compliance, and OSS adopters.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` - Current LiveView guidance: thin LiveViews, function components, URL state, streams, async, auth on mount, user-facing behavior tests.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - System-design guidance for Plug/Phoenix/Ecto/LiveView apps and runtime footguns.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` - Elixir OSS library DX guidance: explicit APIs, minimal magic, runtime options, docs/contracts, stable public surface.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - CI/CD guidance for named checks, docs as product, and release-quality gates.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.OperatorSurface.Router.threadline_operator_surface/2`: establishes the secure mounted-router pattern that the stress macro should mirror without becoming a new public option on the main macro.
- `Threadline.OperatorSurface.Auth`: centralizes operator assigns for auth, scope, enabled sections, and theme; the stress route should reuse this path rather than inventing a separate shell.
- `Threadline.OperatorSurface.Components.SurfaceHeader`: current shared shell/navigation component; useful as the first stress story and as the stress-route chrome.
- `Threadline.OperatorSurface.Components.Icon`, `Logo`, `UnsupportedView`: the small current function-component set; should seed the initial inventory before primitive extraction begins.
- `Threadline.OperatorSurface.Style.css/1`: current inline token/class/motion source and the file that existing contract tests already parse directly.
- Existing Playwright helpers in `operator-screenshots.spec.ts` and `operator-screenshot-regression.spec.ts`: login flow, durable screenshot naming, masks for dynamic values, reduced-motion assumptions, and desktop/mobile viewports.

### Established Patterns
- Mounted operator surface uses Phoenix router macros with host-owned pipelines and LiveView `on_mount`; stress routing should follow that pattern and stay fail-closed.
- The project prefers source-contract tests with custom failure messages over unstructured manual review for design-system invariants.
- JSON is already accepted as a source-of-truth format through `brandbook/tokens.json`; YAML is not currently part of the toolchain.
- Browser verification is named through Mix aliases; Phase 171 should add or extend named checks rather than burying one-off commands in docs.
- Existing screenshot regression is local-only because platform-sensitive pixels are noisy; Phase 171 should make CI screenshots pinned and bounded before claiming CI pixel-ratchet coverage.
- LiveView best-practice prompt guidance supports function components with declarative attrs/slots, user-facing behavior tests, streams for large lists, URL state for shareable UI, and auth on mount/event paths.

### Integration Points
- Add the internal stress router/macro under `lib/threadline/operator_surface/` without altering the public `threadline_operator_surface/2` option surface.
- Mount the stress route in `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` inside the authenticated `/audit` scope, adjacent to the existing operator mount.
- Add tests under `test/threadline/operator_surface/` for stress-route gating, production omission/raise behavior, fixture registry completeness, JSON ledger schema/ratchet, and markdown projection freshness.
- Add or extend Playwright specs under `examples/threadline_phoenix/e2e/tests/` for stress-route semantic checks and the initial bounded screenshot allowlist.
- Add `DESIGN-SYSTEM.md` v2 and its JSON ledger in a repo-local location chosen by planning; keep downstream references stable and deterministic.

</code_context>

<specifics>
## Specific Ideas

- Treat `/audit/__stress` as a lab for the operator surface, not as adopter documentation or a host-extensible API.
- Model known future issues as stress/ledger cases early: theme picker states, coverage nested-card clutter, and transaction desktop centering.
- Use stable story IDs that can double as ledger keys and screenshot names.
- Keep UI review aligned with the current brand book: calm, precise, exact, useful, dark/light/system designed rather than recolored, no generic SaaS dashboard feel, no compliance-theater framing.
- Prefer "full manifest, bounded visual ratchet" over "full pixel matrix on day one"; the manifest prevents forgotten coverage, the bounded CI allowlist prevents screenshot sprawl.

</specifics>

<deferred>
## Deferred Ideas

- Implementing the runtime theme picker remains Phase 175.
- Fixing coverage card-in-card nesting remains Phase 176.
- Fixing transaction page desktop centering remains Phase 178.
- Public/host-facing component APIs remain out of scope for v1.37 unless a future milestone explicitly reopens the v1.31 freeze.

</deferred>

---

*Phase: 171-Audit baseline, stress-lab harness & idempotency ledger*
*Context gathered: 2026-06-14*
