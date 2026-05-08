# Phase 68: Lifecycle Ergonomics - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v1.18 adoption-and-policy-hardening loop by making the documented first-hour path actually mount the now-shipped operator surface end-to-end, by adding a real upgrade-path / compatibility-policy document for the optional Phoenix/LiveView/HTML/PubSub posture, and by retiring the long-carried repo-wide format-drift blocker in an explicit, auditable way. This phase is documentation- and verification-heavy. It does not add new product capabilities, new operator-surface screens, or new CI infrastructure.

</domain>

<decisions>
## Implementation Decisions

### First-Hour Onboarding Architecture

- **D-59: `guides/getting-started-saas.md` is the canonical first-hour walkthrough.** It should become the one primary adopter narrative from install through a mounted operator surface behind the admin pipeline. The current guide stops at capture + IEx investigation; Phase 68 extends that happy path so an adopter reaches the shipped surface end-to-end.
- **D-60: `README.md` stays short and skimmable.** It remains the entry map plus a short "1-minute mount" pointer, not the full walkthrough. Keep value prop, install/dependency line, the high-signal mount snippet, and hard links to the canonical guide and operator-surface docs.
- **D-61: `examples/threadline_phoenix/README.md` stays the runnable reference-app contract, not the primary narrative.** It remains the proof-by-example surface tied to the in-repo app and path-dependency details. Downstream docs may extract verbatim snippets from it, but should not make it the canonical user-facing onboarding path.
- **D-62: Do not create two equal first-hour flows.** Capture-only vs surface-mounted is a real distinction, but the primary first-hour story in Phase 68 should be the surface-mounted path because ADOPT-05 explicitly closes that gap. Capture-only should be explained as a secondary branch or note, not as a parallel top-level onboarding architecture.
- **D-63: Duplicate only high-signal snippets, not whole walkthrough prose.** Acceptable verbatim duplication across docs: dependency block, `threadline_operator_surface "/audit"` mount block, and possibly the `mix threadline.install` / `mix threadline.gen.triggers` / `mix ecto.migrate` command trio. The long-form prose, caveats, and first-hour sequence stay canonical in `guides/getting-started-saas.md`.

### Upgrade-Path Documentation Shape

- **D-64: Create a new canonical guide at `guides/upgrade-path.md`.** This file owns the optional-deps version matrix, "which track am I on?" detection, upgrade-by-Threadline-minor guidance, break-symptom explanations when Phoenix/LiveView floors move, and the surface-only deprecation/removal policy.
- **D-65: Keep `guides/operator-surface.md` focused on mount/auth/screens, not lifecycle policy.** It should link to `guides/upgrade-path.md` for compatibility/support policy rather than growing into a mixed install + policy + release-history document.
- **D-66: `README.md` is discovery only for upgrade material.** It may mention that the operator surface is optional and link to the upgrade-path guide, but must not become the authority for compatibility or deprecation policy.
- **D-67: The upgrade-path guide information architecture is locked at a high level.** It should contain these sections:
  1. `Who this guide is for`
  2. `How to tell which track you are on`
  3. `Supported compatibility matrix`
  4. `Upgrade by Threadline minor`
  5. `What breaks when Phoenix/LiveView floors move`
  6. `Surface-only deprecation and removal policy`
  7. `Release checklist for adopters`
  8. `Canonical references`

### Compatibility Matrix + Support Policy

- **D-68: The compatibility matrix should be explicit but small.** Threadline should document a narrow, supported-and-tested matrix by dependency family/range, not broad "Phoenix 1.7+" claims and not an overbuilt per-minor/per-feature ledger it cannot honestly maintain.
- **D-69: Support language must distinguish capture-only from surface-mounted clearly.**
  - Capture-only mode: supported with no optional Phoenix deps and enforced by `mix verify.compile_no_optional`.
  - Surface-mounted mode: supported only for the exact dependency ranges Threadline declares and CI-covers in this release.
  - Anything outside the listed ranges is not claimed, even if it may work.
- **D-70: The matrix source of truth is declared deps + CI coverage, not aspirational compatibility.** `mix.exs` and the locked docs/tests define what is supported. Do not write compatibility claims that exceed actual dependency declarations or verification coverage.
- **D-71: Adopt a conservative surface-only public contract policy.** Public surface includes:
  - router macro and documented options
  - documented mount/auth pattern
  - documented operator-surface routes
  - required optional-dep ranges
  - parity Mix task names/flags
  - stable machine-readable enums and literals already locked by tests
- **D-72: Surface-only deprecations require overlap.** Deprecate in docs + changelog first, then remove no earlier than the next Threadline minor after at least one released overlap window. Exceptions are allowed only for security issues, upstream hard incompatibility, or undocumented internals.

### ADOPT-07 Closeout Posture

- **D-73: Keep ADOPT-07 explicit, but narrow it to blocker retirement rather than assumed formatter churn.** As of 2026-05-07, local `mix verify.format` and `mix ci.all` are green. Phase 68 should therefore treat ADOPT-07 as evidence capture, CI-contract confirmation, and stale-planning cleanup unless the drift reappears.
- **D-74: Do not broaden ADOPT-07 into generic CI cleanup.** Warning cleanup, unrelated invariant tightening, or opportunistic workflow changes are separate work if needed. Phase 68 should retire the known blocker cleanly without reopening scope.
- **D-75: The closeout must be auditable.** Phase 68 should update roadmap/requirements/state wording so they stop implying an unresolved repo-wide formatter problem, and it should write explicit validation/verification artifacts showing the blocker is gone and job-ID / `ci.all` topology contracts remain intact.

### Downstream Decision Policy

- **D-76: Bias toward researched defaults over repeated user arbitration.** For this phase, downstream researcher/planner/executor agents should choose the strongest coherent recommendation by default and only escalate decisions back to the user when they are truly high-impact, project-philosophy-changing, or hard-to-reverse.
- **D-77: Phase 68 should preserve "one obvious path" UX.** Wherever documentation could branch or multiply, prefer one canonical source and one canonical flow, with secondary branches clearly subordinate. This applies to onboarding, compatibility docs, and milestone closeout artifacts.

### the agent's Discretion

- Exact wording of the first-hour walkthrough prose, as long as it ends with an actually mounted surface and keeps host-owned auth caveats explicit.
- Exact table columns / phrasing for the compatibility matrix, as long as the matrix stays small, explicit, and tied to declared/tested ranges.
- Whether the upgrade-path guide includes a per-minor mini-table, bullets, or short subsections under `Upgrade by Threadline minor`, as long as it does not imply unsupported precision.
- Exact naming of any new Phase 68 doc-contract test files, validation artifacts, or verification artifact filenames.

</decisions>

<specifics>
## Specific Ideas

- The first-hour story should likely flow: add dependency -> install schema -> generate triggers -> wire `Threadline.Plug` -> wire admin pipeline + `threadline_operator_surface "/audit"` -> run app -> visit `/audit` -> then continue to timeline / coverage / redaction / incident workflow references.
- The upgrade-path guide should answer the adopter question "Am I capture-only or surface-mounted?" explicitly instead of making users infer it from deps or mounted routes.
- The compatibility matrix should use "supported and CI-covered" language, not broad "should work with" language.
- The deprecation policy should speak only about the optional surface contract; it should not blur into general Threadline library API policy unless a future phase chooses to unify them.
- ADOPT-07 should record the concrete date **2026-05-07** for the green local `mix verify.format` and `mix ci.all` runs, then update the stale blocker language in planning artifacts accordingly.
- The user preference for this phase and similar GSD discussions is: default to well-researched, least-surprise recommendations and only ask for arbitration on unusually consequential decisions. Downstream agents should treat that as active guidance here.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract and planning artifacts
- `.planning/ROADMAP.md` §"Phase 68: Lifecycle Ergonomics" — goal, success criteria, sequencing rationale, and current ADOPT-05/06/07 wording.
- `.planning/REQUIREMENTS.md` lines containing `ADOPT-05`, `ADOPT-06`, and `ADOPT-07` — the requirement contract that Phase 68 must satisfy.
- `.planning/PROJECT.md` §"Lifecycle ergonomics" and current milestone summary — higher-level project intent for onboarding, optional-deps policy, and CI honesty.
- `.planning/STATE.md` current-focus and tech-debt entries referencing repo-wide format drift — the stale blocker language this phase is expected to retire cleanly.

### Existing docs to extend or keep scoped
- `README.md` — current quickstart / operator-surface pointers; must remain the short entry map.
- `guides/getting-started-saas.md` — canonical first-hour narrative to extend so it actually mounts the surface end-to-end.
- `guides/operator-surface.md` — canonical mount/auth/screens guide; should stay focused on operator-surface usage, not absorb lifecycle policy.
- `examples/threadline_phoenix/README.md` — runnable example contract and snippet source for reference-app-backed docs.
- `CHANGELOG.md` — should carry deprecation / compatibility movement notes that link back to the upgrade-path guide.
- `guides/upgrade-path.md` — new canonical target for compatibility matrix and upgrade/deprecation policy.

### Existing test / fixture contracts
- `test/threadline/getting_started_saas_doc_contract_test.exs` — first-hour walkthrough contract; Phase 68 should extend this to assert the mount snippet and mounted path are present where required.
- `test/threadline/operator_surface_doc_contract_test.exs` — README/operator-surface guide contract; extend for new links or policy pointers as needed.
- `test/threadline/readme_doc_contract_test.exs` — root README contract; keep the entry-map posture intact.
- `test/threadline/example_phoenix_readme_contract_test.exs` — runnable example README contract.
- `test/support/getting_started_fixtures.ex` — extraction-backed snippet source; use it rather than duplicating drifting code blocks manually.
- `test/threadline/operator_surface/gating_test.exs` — optional-deps / surface gating behavior reference.
- `test/threadline/ci_topology_contract_test.exs` — stable CI job topology contract.
- `test/threadline/phase06_nyquist_ci_contract_test.exs` — `ci.all` ordering/contract reference.

### Verification and compatibility anchors
- `mix.exs` — source of truth for declared deps, aliases, and `mix verify.compile_no_optional` / `mix ci.all`.
- `.github/workflows/ci.yml` — stable job IDs and CI topology Phase 68 must preserve.
- `mix verify.compile_no_optional` — behavioral proof of the capture-only compatibility story.
- Local validation on **2026-05-07**: `mix verify.format` and `mix ci.all` both passed; planner should treat this as current evidence when shaping ADOPT-07.

### External ecosystem references
- Phoenix LiveDashboard router/install docs — example of a concise mount path with install docs separate from broader ecosystem history: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html
- Oban Web installation docs — example of a single install path with separate auth/customization guidance: https://oban.pro/docs/web/installation.html
- Oban upgrade guide — example of explicit compatibility movement and upgrade-specific guidance: https://hexdocs.pm/oban/v2-0.html
- Laravel Horizon docs — example of mounted-surface docs keeping authorization near install while upgrade/runtime policy lives in dedicated sections: https://laravel.com/docs/10.x/horizon
- Elixir compatibility/deprecations — model for explicit, durable compatibility/deprecation policy language: https://hexdocs.pm/elixir/compatibility-and-deprecations.html
- Sentry Elixir docs / repo — example of optional integration setup separated from the core README: https://github.com/getsentry/sentry-elixir

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The repository already uses doc-contract tests heavily; Phase 68 should extend that posture rather than introduce freeform docs with no invariants.
- `GettingStartedFixtures.extract!/2` already supports snippet extraction from real example code, which is the preferred anti-drift mechanism for shared code blocks.
- `mix verify.compile_no_optional` is already the ideal proof point for the capture-only story; no new compatibility proving mechanism is needed for that side of the matrix.
- `.github/workflows/ci.yml` already publishes stable `jobs:` keys and `mix ci.all` already exercises the release gate; ADOPT-07 should preserve, not redesign, that contract.

### Established Patterns
- Threadline prefers canonical docs backed by source-reading tests over prose-only promises.
- Root `README.md` is currently an entry surface, not a monolithic handbook; Phase 68 should preserve that ergonomics.
- The example Phoenix app is already treated as a runnable contract rather than a throwaway demo. Docs should extract from it, not fork away from it.
- Prior phases increasingly lock public UI/task literals with doc-contract tests. Phase 68 should apply the same discipline to compatibility/policy language.

### Integration Points
- Extend `guides/getting-started-saas.md` with the operator-surface mount path and first-hour mounted flow.
- Add `guides/upgrade-path.md` and link it from `README.md` and `guides/operator-surface.md`.
- Extend existing doc-contract tests and add a focused upgrade-path doc-contract test that locks matrix headers, capture-only vs surface-mounted wording, and deprecation-policy literals.
- Update planning/state artifacts so ADOPT-07 reflects blocker retirement rather than a presumed remaining formatter sweep.
- Add Phase 68 validation / verification artifacts that record the green formatter + CI state and unchanged CI topology.

</code_context>

<deferred>
## Deferred Ideas

- A fully global GSD/workflow policy change to always prefer researched defaults across all future phases — capture this as a broader workflow preference, but do not expand Phase 68 beyond documenting the preference for this phase unless separately scoped.
- A larger library-wide API compatibility policy unifying core API and optional surface policy — out of scope here; Phase 68 should focus on the optional UI posture only.
- Broader CI/warning cleanup now that `mix ci.all` is green — separate work if desired; do not smuggle it into ADOPT-07.
- Separate top-level onboarding guides for capture-only and surface-mounted adopters — only revisit if the two tracks diverge materially in future milestones.

</deferred>

---

*Phase: 68-lifecycle-ergonomics*
*Context gathered: 2026-05-07*
