# Phase 68: Lifecycle Ergonomics - Research

**Researched:** 2026-05-07 [VERIFIED: system date]
**Domain:** Documentation-contract hardening, optional-dependency lifecycle policy, and auditable blocker retirement for the operator surface rollout [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md; .planning/REQUIREMENTS.md]
**Confidence:** HIGH [VERIFIED: codebase and planning artifacts directly define the scope]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)

- A fully global GSD/workflow policy change to always prefer researched defaults across all future phases — capture this as a broader workflow preference, but do not expand Phase 68 beyond documenting the preference for this phase unless separately scoped.
- A larger library-wide API compatibility policy unifying core API and optional surface policy — out of scope here; Phase 68 should focus on the optional UI posture only.
- Broader CI/warning cleanup now that `mix ci.all` is green — separate work if desired; do not smuggle it into ADOPT-07.
- Separate top-level onboarding guides for capture-only and surface-mounted adopters — only revisit if the two tracks diverge materially in future milestones.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-05 | First-hour onboarding revisit across `guides/getting-started-saas.md`, `README.md`, and `examples/threadline_phoenix/README.md`; path must mount the operator surface end-to-end; doc-contract test extended. [VERIFIED: .planning/REQUIREMENTS.md] | Canonical-doc split, snippet-reuse rules, exact target files, and existing snippet anchors/tests are identified below. [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md; test/threadline/getting_started_saas_doc_contract_test.exs; examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] |
| ADOPT-06 | Add upgrade-path docs for optional Phoenix/LiveView/HTML/PubSub posture; lock matrix headers and policy literals in tests. [VERIFIED: .planning/REQUIREMENTS.md] | Compatibility guidance is constrained to declared optional deps, current lock resolution, and CI coverage, with a dedicated guide and dedicated doc-contract test recommended. [VERIFIED: mix.exs; mix.lock; .github/workflows/ci.yml; .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md] |
| ADOPT-07 | Retire the repo-wide format-drift blocker audibly and cleanly without changing CI topology. [VERIFIED: .planning/REQUIREMENTS.md] | Evidence already shows `mix verify.format` and `mix ci.all` green on 2026-05-07, so planning should focus on validation artifacts and stale planning-language cleanup rather than speculative code churn. [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md; mix.exs; .github/workflows/ci.yml; .planning/STATE.md] |
</phase_requirements>

## Summary

Phase 68 is a documentation-and-contract phase, not a feature phase. The smallest coherent split is three slices: one canonical onboarding rewrite centered in `guides/getting-started-saas.md`, one dedicated lifecycle-policy doc centered in a new `guides/upgrade-path.md`, and one closeout slice that updates planning/state/verification artifacts to retire the stale format-drift blocker language without redesigning CI. [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md; .planning/ROADMAP.md; .planning/REQUIREMENTS.md]

The repo already has the technical surface that ADOPT-05 and ADOPT-06 need to document: the example Phoenix app mounts `threadline_operator_surface "/"` inside an `/audit` scope behind `:browser` plus `:admin_auth`, the root README already carries a short mount snippet, and the current guide/test posture is doc-contract-first with snippet extraction from the example app. Planning should therefore reuse that infrastructure instead of inventing new examples, new mount patterns, or new CI jobs. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex; README.md; test/threadline/getting_started_saas_doc_contract_test.exs; test/support/getting_started_fixtures.ex]

ADOPT-07 is no longer a formatter-sweep discovery task. The phase context explicitly records 2026-05-07 local green runs for `mix verify.format` and `mix ci.all`, while stale blocker language still remains in `.planning/STATE.md` and older milestone artifacts. The planner should treat that as an artifact-reconciliation problem: capture current evidence, preserve stable job IDs and alias topology, and update active-planning text so it no longer claims an unresolved repo-wide blocker. [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md; .planning/STATE.md; .planning/ROADMAP.md; mix.exs; .github/workflows/ci.yml]

**Primary recommendation:** Plan Phase 68 as three plans: `ADOPT-05 onboarding docs + existing contract extensions`, `ADOPT-06 upgrade-path guide + new focused contract test + changelog/ExDoc wiring`, and `ADOPT-07 evidence + planning/state cleanup + verification artifacts`. [VERIFIED: codebase structure and locked context]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical first-hour walkthrough that ends at a mounted operator surface | Frontend Server (SSR/router docs) | Browser / Client | The behavior being taught is router/pipeline/mount wiring in Phoenix, while the browser is only the consumer of `/audit` after mount. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex; guides/getting-started-saas.md] |
| Optional-deps compatibility matrix and upgrade-path policy | Build / Dependency Boundary | Frontend Server (operator-surface consumers) | The source of truth is dependency declarations, current lock resolution, and CI coverage rather than runtime UI behavior alone. [VERIFIED: mix.exs; mix.lock; .github/workflows/ci.yml] |
| Repo-wide format-blocker retirement | Build / CI | Planning / Documentation | The executable truth is `mix verify.format`, `mix ci.all`, and stable GitHub job IDs; the remaining work is updating planning artifacts to match that truth. [VERIFIED: mix.exs; .github/workflows/ci.yml; .planning/STATE.md] |

## Project Constraints (from CLAUDE.md)

- Keep the three-layer boundary explicit: capture, semantics, and exploration/operations must not be conflated in docs or recommendations. [VERIFIED: CLAUDE.md]
- Use the canonical verification entrypoints verbatim: `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all`, and `mix verify.compile_no_optional`. [VERIFIED: CLAUDE.md; mix.exs]
- Preserve stable GitHub Actions `jobs:` IDs; evolve names if needed, not IDs. [VERIFIED: CLAUDE.md; .github/workflows/ci.yml]
- Treat doc-contract tests as first-class invariants for README/guides/example docs. [VERIFIED: CLAUDE.md; existing test files under `test/threadline/*doc_contract*`] 
- Preserve the optional-deps posture for the operator surface; capture-only adopters must continue compiling cleanly without Phoenix/LiveView. [VERIFIED: CLAUDE.md; mix.exs]

## Standard Stack

### Core
| Library / Artifact | Version / Range | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | Project floor `~> 1.15`; local environment `1.19.5`; CI pin `1.17.3` [VERIFIED: mix.exs; `elixir --version`; .github/workflows/ci.yml] | Runtime and docs/test execution | All phase validation commands run through Mix/ExUnit, so docs and policy must stay honest against the supported Elixir floor and the CI-pinned runner. [VERIFIED: mix.exs; .github/workflows/ci.yml] |
| Phoenix operator-surface deps | Declared optional ranges: `phoenix ~> 1.7`, `phoenix_live_view ~> 1.0`, `phoenix_html ~> 4.0`, `phoenix_pubsub ~> 2.1` [VERIFIED: mix.exs] | Surface-mounted adopter track | ADOPT-06 must document only these declared ranges, not broader ecosystem guesses. [VERIFIED: mix.exs; .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md] |
| Doc-contract tests | ExUnit file-read/source-read tests in `test/threadline/*doc_contract*` [VERIFIED: `ls test/threadline`; specific test files] | Locks public docs to shipped behavior | This is already the house style for docs drift prevention and is the right mechanism for ADOPT-05/06. [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs; test/threadline/operator_surface_doc_contract_test.exs; test/threadline/readme_doc_contract_test.exs] |

### Supporting
| Library / Artifact | Version / Resolution | Purpose | When to Use |
|---------|---------|---------|-------------|
| Current lock resolution for surface-mounted track | Phoenix `1.8.7`, LiveView `1.1.30`, HTML `4.3.0`, PubSub `2.2.0` [VERIFIED: mix.lock] | Concrete “current CI-resolved stack” row in the compatibility guide | Use as the tested resolution row, but do not imply a broader matrix than the repo actually exercises. [VERIFIED: mix.lock; .github/workflows/ci.yml] |
| `mix verify.compile_no_optional` | Alias present in `mix.exs`; dedicated CI job `verify-compile-no-optional` [VERIFIED: mix.exs; .github/workflows/ci.yml] | Proof for capture-only support | Use as the capture-only support claim and detection guidance in `guides/upgrade-path.md`. [VERIFIED: mix.exs; .github/workflows/ci.yml] |
| Example Phoenix app snippet anchors | `router-pipeline-actor-fn`, `blog-create-post-transaction` [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex; examples/threadline_phoenix/lib/threadline_phoenix/blog.ex] | Anti-drift snippet extraction | Reuse for ADOPT-05 where possible; add a new mount anchor if the guide needs verbatim router-mount extraction. [VERIFIED: test/support/getting_started_fixtures.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New `guides/upgrade-path.md` | Expand `guides/operator-surface.md` | Rejected because locked decision D-65 keeps operator-surface docs focused on mount/auth/screens and pushes lifecycle policy into a dedicated guide. [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md] |
| Dedicated doc-contract test for upgrade policy | Extend only `operator_surface_doc_contract_test.exs` | Possible, but weaker: compatibility matrix headers and deprecation literals are a separate contract surface and deserve a focused invariant file. [VERIFIED: current test file scope; locked discretion on naming in 68-CONTEXT] |
| Additional CI matrix job | Keep current CI topology and document evidence | Current requirement and context explicitly forbid broadening ADOPT-07 into generic CI cleanup; preserve stable job IDs and current topology. [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md; .github/workflows/ci.yml] |

**Installation:** No new runtime dependencies are required for Phase 68; the phase should only add docs/tests/artifacts and may need to add `guides/upgrade-path.md` to ExDoc extras. [VERIFIED: mix.exs; scope in .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Example app router/docs source
        |
        v
guides/getting-started-saas.md (canonical walkthrough)
        | \
        |  \__ README.md (entry map + short mount pointer)
        |     
        \____ examples/threadline_phoenix/README.md (runnable contract)
                |
                v
      Doc-contract tests assert shared literals/snippets
                |
                v
      mix verify.test / mix ci.all keep docs + examples aligned

mix.exs optional dep declarations + mix.lock current resolution + ci.yml jobs
                |
                v
      guides/upgrade-path.md (compatibility matrix + policy)
                |
                v
      Focused upgrade doc-contract test + changelog/reference links

2026-05-07 green verify evidence + current ci topology
                |
                v
      68-VERIFICATION.md / 68-VALIDATION.md + STATE/ROADMAP wording cleanup
```

### Recommended Project Structure
```text
guides/
├── getting-started-saas.md   # Canonical first-hour narrative
├── operator-surface.md       # Mount/auth/screens only
└── upgrade-path.md           # New lifecycle policy + compatibility guide

examples/threadline_phoenix/
└── README.md                 # Runnable reference-app contract

test/threadline/
├── getting_started_saas_doc_contract_test.exs
├── operator_surface_doc_contract_test.exs
├── readme_doc_contract_test.exs
├── example_phoenix_readme_contract_test.exs
└── phase68_upgrade_path_doc_contract_test.exs  # recommended new focused contract
```

### Pattern 1: Canonical Guide + Short README + Runnable Example
**What:** Keep one canonical onboarding story in `guides/getting-started-saas.md`, keep `README.md` as a short discovery surface, and keep the example README as the runnable contract. [VERIFIED: D-59 through D-63 in 68-CONTEXT; current README/operator docs]
**When to use:** For ADOPT-05 and any future public-doc update that spans README + guide + example. [VERIFIED: existing doc topology]
**Example:**
```elixir
# Source: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
scope "/audit" do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    repo: ThreadlinePhoenix.Repo
end
```
[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]

### Pattern 2: Derive Compatibility Claims from Declarations + Proof, Not Lore
**What:** Document only two tracks: capture-only and surface-mounted. The guide should bind capture-only claims to `mix verify.compile_no_optional`, and surface-mounted claims to the declared optional ranges in `mix.exs` plus the current lock/CI-resolved stack. [VERIFIED: mix.exs; mix.lock; .github/workflows/ci.yml; D-68 to D-70]
**When to use:** In `guides/upgrade-path.md`, changelog release notes, and any README/operator-surface cross-links. [VERIFIED: 68-CONTEXT; CHANGELOG.md]
**Example:**
```text
Track              Declared support                     Proof
Capture-only       No optional Phoenix deps            mix verify.compile_no_optional
Surface-mounted    phoenix ~> 1.7                      CI/tested on current lock resolution
                   phoenix_live_view ~> 1.0
                   phoenix_html ~> 4.0
                   phoenix_pubsub ~> 2.1
```
[VERIFIED: mix.exs; mix.lock; .github/workflows/ci.yml]

### Pattern 3: Treat ADOPT-07 as Evidence Reconciliation
**What:** Update validation artifacts and active planning docs to match the now-green formatter/CI reality, while preserving the established CI job topology and alias order. [VERIFIED: 68-CONTEXT D-73..75; mix.exs; ci.yml; .planning/STATE.md]
**When to use:** For the closeout slice only. [VERIFIED: ADOPT-07 scope]
**Example:**
```bash
mix verify.format
mix ci.all
```
[VERIFIED: mix.exs; CLAUDE.md]

### Anti-Patterns to Avoid
- **Two equal onboarding flows:** Do not create separate top-level “capture-only quickstart” and “surface-mounted quickstart” guides for this phase. Keep capture-only as a subordinate note inside the canonical walkthrough or upgrade guide. [VERIFIED: D-62; D-77 in 68-CONTEXT]
- **Aspirational compatibility claims:** Do not write “Phoenix 1.7+” or “works with LiveView majors broadly” unless that exact range is both declared and CI-covered. [VERIFIED: D-68..70; mix.exs; ci.yml]
- **Policy sprawl in `guides/operator-surface.md`:** Keep mount/auth/screens there, and link out to `guides/upgrade-path.md` for lifecycle policy. [VERIFIED: D-64..66 in 68-CONTEXT]
- **Reopening CI design:** ADOPT-07 is not permission to add jobs, change job IDs, or broaden the release gate. [VERIFIED: D-74..75; .github/workflows/ci.yml]

## Exact Artifact Changes the Planner Should Expect

### Docs
- `guides/getting-started-saas.md` must become the canonical install-to-mounted-surface story and explicitly reach the mounted operator surface after the existing capture/investigation steps. [VERIFIED: D-59; current guide ends at IEx investigation]
- `README.md` must stay short, keep the high-signal mount snippet, and add only discovery links/pointers to the canonical walkthrough and upgrade-path guide. [VERIFIED: D-60; current README structure]
- `examples/threadline_phoenix/README.md` must stay runnable-contract-first and mirror the mounted-surface posture without becoming the main narrative. [VERIFIED: D-61; current example README]
- `guides/operator-surface.md` must link to `guides/upgrade-path.md` rather than absorb compatibility/deprecation policy. [VERIFIED: D-65]
- `guides/upgrade-path.md` should be created and wired into ExDoc extras plus README/operator-surface/changelog references. [VERIFIED: D-64..67; mix.exs docs extras currently omit this file]
- `CHANGELOG.md` should carry surface-only compatibility/deprecation notes so doc policy and release history do not diverge. [VERIFIED: D-72; current changelog already carries operator-surface release notes]

### Tests
- Extend `test/threadline/getting_started_saas_doc_contract_test.exs` to assert the mounted-surface endpoint and shared mount snippet/literals in the canonical walkthrough. [VERIFIED: ADOPT-05 text; current test scope]
- Extend `test/threadline/readme_doc_contract_test.exs` to keep README in entry-map posture while adding the new upgrade-path link and first-hour pointer. [VERIFIED: current README contract scope]
- Extend `test/threadline/example_phoenix_readme_contract_test.exs` to lock the example README’s mounted-surface references without changing its “runnable contract” role. [VERIFIED: current example README test scope]
- Extend `test/threadline/operator_surface_doc_contract_test.exs` only for cross-link assertions, not for the whole compatibility matrix. [VERIFIED: current test is small and route/auth-focused]
- Add one new focused upgrade-policy contract test, preferably `test/threadline/upgrade_path_doc_contract_test.exs` or equivalent, to lock matrix headers, track-detection language, and deprecation-policy literals. [VERIFIED: ADOPT-06 requirement; naming left to discretion in 68-CONTEXT]

### Planning / State / Validation Artifacts
- Update `.planning/STATE.md` to retire the live blocker wording in `Todos`, `Blockers`, and `Deferred Items`. [VERIFIED: .planning/STATE.md]
- Update `.planning/ROADMAP.md` success-criteria and phase text only if needed to reflect blocker retirement wording rather than an unresolved future sweep. [VERIFIED: .planning/ROADMAP.md]
- Update `.planning/REQUIREMENTS.md` status/checkmarks when the phase closes; do not rewrite the requirement intent. [VERIFIED: .planning/REQUIREMENTS.md]
- Write `68-VERIFICATION.md` and `68-VALIDATION.md` that explicitly record the 2026-05-07 green `mix verify.format` / `mix ci.all` evidence and unchanged CI topology. [VERIFIED: D-75; current phase output conventions across `.planning/phases/*`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shared doc snippets | Fresh manual copies of router/blog snippets in multiple docs | `GettingStartedFixtures.extract!/2` and example-app anchors | The repo already has anti-drift extraction infrastructure; duplicating by hand reintroduces doc drift. [VERIFIED: test/support/getting_started_fixtures.ex; test/threadline/getting_started_saas_doc_contract_test.exs] |
| Compatibility policy | Ecosystem-wide support guesses | `mix.exs` declared ranges + `mix.lock` current resolution + `ci.yml` coverage statements | This is the only evidence base allowed by the locked context. [VERIFIED: D-68..70; mix.exs; mix.lock; .github/workflows/ci.yml] |
| ADOPT-07 proof | New CI jobs or ad hoc shell contracts | Existing aliases/tests plus phase verification docs | The requirement is evidence capture and wording cleanup, not CI redesign. [VERIFIED: D-73..75; mix.exs; ci.yml] |

**Key insight:** Phase 68 should reuse existing contract infrastructure aggressively; the highest-risk failure mode is not missing code, it is publishing support-policy language or onboarding prose that drifts away from the example app and the real CI contract. [VERIFIED: current repo patterns and locked context]

## Common Pitfalls

### Pitfall 1: Canonical-flow drift
**What goes wrong:** The guide, README, and example README each teach slightly different “first hour” stories. [VERIFIED: current docs diverge in depth and intent]
**Why it happens:** The repo intentionally has three docs surfaces with different jobs, but only one of them should own the long-form narrative. [VERIFIED: D-59..63]
**How to avoid:** Put the full sequence in `guides/getting-started-saas.md`, keep README to pointers/snippets, and keep the example README runnable-contract-first. [VERIFIED: D-59..63]
**Warning signs:** Duplicate prose paragraphs or separate “quickstart” sections growing in README and example README. [VERIFIED: current structure]

### Pitfall 2: Over-claiming support
**What goes wrong:** Docs say “Phoenix 1.7+” or imply multiple major/minor combinations are supported. [VERIFIED: ADOPT-06 risk from locked context]
**Why it happens:** The declared optional dependency ranges are broader than one exact lock resolution, and it is easy to turn that into aspirational marketing. [VERIFIED: mix.exs; mix.lock]
**How to avoid:** Separate “declared range” from “current CI-resolved proof row” and explicitly state that anything outside documented rows is unclaimed. [VERIFIED: D-68..70]
**Warning signs:** Support tables without a “proof” column or text that says “should work.” [VERIFIED: best-fit risk from current scope]

### Pitfall 3: Treating ADOPT-07 as open-ended cleanup
**What goes wrong:** The plan expands into warning cleanup, CI refactors, or unrelated formatting churn. [VERIFIED: D-74]
**Why it happens:** Historical planning artifacts still mention a repo-wide format blocker, so the phase can look larger than it now is. [VERIFIED: .planning/STATE.md; older milestone artifacts]
**How to avoid:** Lock the scope to evidence capture, topology confirmation, and stale-language cleanup unless fresh formatter drift is reproduced during execution. [VERIFIED: D-73..75]
**Warning signs:** Proposed edits to `.github/workflows/ci.yml` job IDs or `mix.exs` alias order without a newly reproduced failure. [VERIFIED: ci.yml; mix.exs]

### Pitfall 4: Mixing lifecycle policy into mount docs
**What goes wrong:** `guides/operator-surface.md` becomes a long install/history/policy handbook. [VERIFIED: D-65]
**Why it happens:** The operator surface is where adopters first look, so policy details naturally accrete there. [VERIFIED: current guide role]
**How to avoid:** Keep operator-surface.md concise and link to `guides/upgrade-path.md` for lifecycle policy. [VERIFIED: D-64..66]
**Warning signs:** Matrix tables or deprecation policy prose added directly under the mount/auth sections. [VERIFIED: desired boundary]

## Code Examples

Verified patterns from shipped sources:

### Mounted surface behind admin pipeline
```elixir
# Source: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
scope "/audit" do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    repo: ThreadlinePhoenix.Repo
end
```
[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]

### Capture-only proof command
```bash
# Source: mix.exs / .github/workflows/ci.yml
mix verify.compile_no_optional
```
[VERIFIED: mix.exs; .github/workflows/ci.yml]

### CI topology proof commands
```bash
# Source: mix.exs / phase context
mix verify.format
mix ci.all
```
[VERIFIED: mix.exs; .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| README-heavy onboarding with guide ending at capture/IEx | One canonical guide should now reach mounted operator-surface usage; README remains an entry map | Phase 68 target state after v1.17/64-67 surface completion [VERIFIED: README.md; guides/getting-started-saas.md; ROADMAP.md] | Reduces ambiguity about the “first successful hour” path. [VERIFIED: D-59..63] |
| Implicit optional-deps posture spread across README/operator docs | Dedicated upgrade-path guide with explicit track detection, support matrix, and deprecation policy | Locked in Phase 68 context [VERIFIED: D-64..67] | Makes support claims auditable and testable. [VERIFIED: ADOPT-06 requirement] |
| ADOPT-07 treated as formatter cleanup backlog | ADOPT-07 narrowed to evidence + wording cleanup because local `mix verify.format` and `mix ci.all` were green on 2026-05-07 | 2026-05-07 context decision [VERIFIED: D-73 in 68-CONTEXT] | Keeps the closing slice small and auditable. [VERIFIED: D-74..75] |

**Deprecated/outdated:**
- “Repo-wide format drift still blocks `mix ci.all`” as current active-state language is outdated for active planning once Phase 68 captures the 2026-05-07 evidence and updates `.planning/STATE.md`. [VERIFIED: .planning/STATE.md; 68-CONTEXT]

## Assumptions Log

All material claims in this research were verified from the codebase or official docs in this session. [VERIFIED: sources list below]

## Open Questions (RESOLVED)

1. **Should the upgrade-path contract live in a brand-new test file or inside `operator_surface_doc_contract_test.exs`?**
   - What we know: ADOPT-06 needs matrix-header and policy-literal locking, and the current operator-surface contract test is intentionally small. [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs; .planning/REQUIREMENTS.md]
   - Resolution: Use a new focused test file so lifecycle-policy invariants stay isolated from route/auth invariants. The planner has now chosen `test/threadline/upgrade_path_doc_contract_test.exs` as the canonical contract surface. [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-02-PLAN.md]

2. **Does the canonical guide need a new extractable snippet anchor for the mounted operator-surface block?**
   - What we know: Existing extraction helpers cover router API-pipeline and blog transaction snippets, but not the `/audit` mount block itself. [VERIFIED: test/support/getting_started_fixtures.ex; examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]
   - Resolution: Add a dedicated anchor in the example router so the canonical guide and any secondary doc reuse the same extracted mount snippet rather than hand-copying it. This is the path chosen by the planner for 68-01. [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-01-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `mix test`, `mix verify.format`, `mix ci.all` | ✓ | 1.19.5 [VERIFIED: `elixir --version`] | — |
| Mix | All phase validation commands | ✓ | 1.19.5 [VERIFIED: `mix --version`] | — |
| PostgreSQL CLI (`createdb`, `pg_isready`) | Example-app and full-suite verification paths | ✓ | `createdb 14.17`; local Postgres accepting on `localhost:5432` [VERIFIED: `createdb --version`; `pg_isready -h localhost -p 5432`] | Could still run pure doc-contract subsets without DB, but not `mix ci.all`. [VERIFIED: current test mix] |
| Git | Verification artifact provenance / clean diff inspection | ✓ | 2.41.0 [VERIFIED: `git --version`] | — |

**Missing dependencies with no fallback:** None found. [VERIFIED: local probes above]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit under Mix [VERIFIED: test files; mix.exs] |
| Config file | `mix.exs` aliases + default ExUnit project setup; no dedicated `test.exs` config file needed for this phase’s doc-contract slice [VERIFIED: mix.exs] |
| Quick run command | `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/phase06_nyquist_ci_contract_test.exs -x` [VERIFIED: file list; mix test usage from CLAUDE.md] |
| Full suite command | `mix ci.all` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOPT-05 | Canonical first-hour path reaches mounted surface and keeps README/example roles distinct | doc-contract | `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs -x` | ✅ existing tests, but assertions need extension [VERIFIED: test files] |
| ADOPT-06 | Upgrade-path guide locks matrix headers, track-detection language, and policy literals | doc-contract | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs -x` | ❌ new file required [VERIFIED: no such file in `test/threadline`] |
| ADOPT-07 | CI alias/job topology stays intact while blocker language is retired and evidence is recorded | mixed: contract + verification artifact | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/phase06_nyquist_ci_contract_test.exs -x && mix verify.format && mix ci.all` | ✅ topology tests exist; planning-artifact evidence is manual/doc-driven [VERIFIED: current files; mix.exs] |

### Sampling Rate
- **Per task commit:** Run the relevant doc-contract subset for the touched doc slice. [VERIFIED: existing test granularity]
- **Per wave merge:** Run all Phase 68 doc/topology tests plus `mix verify.format`. [VERIFIED: ADOPT-07 scope]
- **Phase gate:** `mix ci.all` green and phase verification artifacts updated before `/gsd-verify-work`. [VERIFIED: mix.exs; current workflow conventions]

### Wave 0 Gaps
- [ ] `test/threadline/upgrade_path_doc_contract_test.exs` — new focused invariant for ADOPT-06 matrix/policy literals. [VERIFIED: no current file]
- [ ] `guides/upgrade-path.md` — new canonical lifecycle-policy doc. [VERIFIED: file absent in current guides list]
- [ ] `68-VERIFICATION.md` / `68-VALIDATION.md` — explicit ADOPT-07 evidence capture and blocker-retirement record. [VERIFIED: phase artifact convention]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Docs must continue to show host-owned authenticated admin pipeline before surface mount. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex; guides/operator-surface.md] |
| V3 Session Management | no | This phase does not introduce session logic; it only documents existing host-owned routing posture. [VERIFIED: phase scope] |
| V4 Access Control | yes | `threadline_operator_surface` examples must remain behind `pipe_through` + `:authorize_fn` guidance and fail-closed copy. [VERIFIED: README.md; guides/operator-surface.md; operator_surface_doc_contract_test.exs] |
| V5 Input Validation | yes | Compatibility/support claims must be constrained to declared/verified ranges; do not accept unsupported matrix claims in docs. [VERIFIED: D-68..70] |
| V6 Cryptography | no | No crypto changes are in scope. [VERIFIED: phase scope] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mounting the operator surface without an authenticated admin path | Elevation of Privilege | Preserve fail-closed docs/examples and auth contract wording in README/operator-surface guide/quickstart. [VERIFIED: guides/operator-surface.md; README.md; example router] |
| Support-policy overclaim causing unsafe/unsupported upgrades | Tampering | Restrict compatibility matrix to declared optional ranges plus CI-covered proof rows and note unclaimed combinations explicitly. [VERIFIED: D-68..70; mix.exs; mix.lock; ci.yml] |
| Stale blocker language causing maintainers to treat CI as still broken | Repudiation | Record dated verification evidence and update active planning artifacts to match current green status. [VERIFIED: D-73..75; STATE.md] |

## Sources

### Primary (HIGH confidence)
- `/.planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md` - locked decisions, exact scope, and ADOPT-07 posture. [VERIFIED: local file]
- `/.planning/REQUIREMENTS.md` - ADOPT-05/06/07 contract text. [VERIFIED: local file]
- `/.planning/ROADMAP.md` - phase success criteria and sequencing rationale. [VERIFIED: local file]
- `/.planning/STATE.md` - stale blocker language still needing cleanup. [VERIFIED: local file]
- `/mix.exs` - optional dependency ranges, aliases, ExDoc extras, and `ci.all` contract. [VERIFIED: local file]
- `/.github/workflows/ci.yml` - stable job IDs and CI topology. [VERIFIED: local file]
- `/README.md`, `/guides/getting-started-saas.md`, `/guides/operator-surface.md`, `/examples/threadline_phoenix/README.md` - current doc topology and required target docs. [VERIFIED: local files]
- `/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` and `/examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` - canonical snippet sources and mounted-surface wiring. [VERIFIED: local files]
- `/test/threadline/getting_started_saas_doc_contract_test.exs`, `/test/threadline/operator_surface_doc_contract_test.exs`, `/test/threadline/readme_doc_contract_test.exs`, `/test/threadline/example_phoenix_readme_contract_test.exs`, `/test/threadline/ci_topology_contract_test.exs`, `/test/threadline/phase06_nyquist_ci_contract_test.exs` - current invariant coverage. [VERIFIED: local files]

### Secondary (MEDIUM confidence)
- Elixir compatibility and deprecations: https://hexdocs.pm/elixir/compatibility-and-deprecations.html - deprecation-overlap policy reference for conservative public-contract guidance. [CITED: https://hexdocs.pm/elixir/compatibility-and-deprecations.html]
- Phoenix LiveDashboard router docs: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html - precedent for concise mount macro docs separate from broader lifecycle history. [CITED: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html]
- Oban upgrade guide: https://hexdocs.pm/oban/v2-0.html - precedent for explicit upgrade-path docs when dependency posture changes. [CITED: https://hexdocs.pm/oban/v2-0.html]

### Tertiary (LOW confidence)
- None. [VERIFIED: no low-confidence-only claims used]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all support-policy inputs come directly from `mix.exs`, `mix.lock`, and `ci.yml`. [VERIFIED: local files]
- Architecture: HIGH - the phase is doc/test/planning scoped and the locked context is unusually explicit about boundaries. [VERIFIED: 68-CONTEXT; ROADMAP]
- Pitfalls: HIGH - current docs/tests/planning artifacts already show the drift vectors this phase must close. [VERIFIED: local files]

**Research date:** 2026-05-07 [VERIFIED: system date]
**Valid until:** 2026-06-06 for codebase-derived planning guidance, or until optional dependency declarations / CI topology change. [VERIFIED: scope stability assessment]
