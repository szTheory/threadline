---
phase: 200-public-surface
plan: 04
subsystem: documentation
tags: [exdoc, hexdocs, public-api, module-visibility, release-contract]
requires:
  - phase: 200-public-surface
    provides: source-derived visibility, public-reference, and archive contracts
  - phase: 200-public-surface
    provides: canonical configuration and command reference
  - phase: 200-public-surface
    provides: documented storage and queue extension contracts
provides:
  - six-role ExDoc module taxonomy seeded with supported adopter contracts
  - hidden documentation status for all six maintainer-only critic modules
  - README-led HexDocs navigation with version-pinned external project resources
  - warnings-as-errors release documentation step and durable maintainer command naming
affects: [200-05, 200-06, 200-07, 200-08, 200-09, 200-12, 200-13, 200-14]
actuals:
  tokens: 10515
  tasks: 2
  commits: 4
plan_head_before: d573ade606f7cf6c9835c81b770ee15aac571f43
tech-stack:
  added: []
  patterns: [explicit ExDoc allowlists, compiled-doc visibility proof, version-derived URL extras, README-led documentation]
key-files:
  created:
    - examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts
  modified:
    - mix.exs
    - DESIGN-SYSTEM.md
    - guides/configuration-and-commands.md
    - lib/threadline/critic_trust/measure.ex
    - lib/threadline/critic_trust/rank_metrics.ex
    - lib/threadline/critic_trust/ledger_splice.ex
    - lib/threadline/critic_trust/krippendorff_alpha.ex
    - lib/mix/tasks/critic.measure.ex
    - lib/mix/tasks/critic.synth.ex
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
key-decisions:
  - "The public module skeleton uses the six locked user-role groups and exactly ten adopter Mix tasks; maintainer critics and VerifyTopology are excluded."
  - "Repository-only project resources are native ExDoc URL extras derived from doc_source_ref/0, not Hex package files or a custom documentation site."
  - "The planning-specific browser alias and spec name became the durable operator_component_contracts contract with every internal reference updated atomically."
patterns-established:
  - "Visibility contract: supported call paths, returned types, configuration seams, and extension roles are explicitly grouped; maintainer machinery uses @moduledoc false."
  - "External-resource contract: URL, title, intent lane, version ref, and package absence are checked together in one non-vacuous test."
requirements-completed: [SURFACE-01, SURFACE-02, SURFACE-03, SURFACE-04, SURFACE-05, SURFACE-07]
coverage:
  - id: D1
    description: "All six critic modules are hidden and the public façade is present in the exact six-group ExDoc skeleton."
    requirement: SURFACE-03
    verification:
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only module_visibility_tracer"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "HexDocs now starts at the README, retains the six intent lanes, links both repository resources at the package version, and keeps them outside package.files."
    requirement: SURFACE-05
    verification:
      - kind: integration
        ref: "mix test test/threadline/release_artifact_contract_test.exs --only url_extras"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only public_doc_refs_external_design"
        status: pass
    human_judgment: false
  - id: D3
    description: "The release lane treats documentation warnings as failures and the maintainer browser contract uses durable purpose-based naming."
    requirement: SURFACE-02
    verification:
      - kind: other
        ref: "mix.exs contains MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only command_reference"
        status: pass
      - kind: other
        ref: "npm run typecheck --prefix examples/threadline_phoenix/e2e"
        status: pass
    human_judgment: false
duration: 36min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 04: Public Module and HexDocs Skeleton Summary

**Six explicit ExDoc module groups now expose adopter contracts while hiding critic internals, and README-led HexDocs links repository resources through version-pinned, package-external entries.**

## Performance

- **Duration:** 36 min
- **Started:** 2026-09-12T07:55:03Z
- **Completed:** 2026-09-12T08:31:22Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments

- Hid the six mandatory critic modules from generated documentation and replaced planning chronology in their packaged source with durable trust-system rationale.
- Replaced the old namespace-oriented module buckets with the six locked user-role groups, retaining public façades, returned structs, supported extension seams, Sigra, operator entrypoints, and exactly ten adopter Mix tasks.
- Made the README the ExDoc landing page, labeled extras as Guides, added the configuration reference, and linked the Phoenix reference app and design system through version-derived URLs in the existing Adopt and Contribute lanes.
- Made the existing release documentation command fail on warnings and renamed the planning-specific browser alias/spec to a stable purpose-based contract without a compatibility alias.

## Task Commits

1. **Task 1: Prove a hidden critic and public façade through compiled docs** — `4c7496ea`
2. **Task 2: Configure README-led HexDocs and version-pinned external resources** — `a484e4ce`
3. **Task 1 acceptance follow-up: Enforce group order, unique façade, and exact adopter-task membership in the tracer** — `5f9f95fc`

## Files Created/Modified

- `mix.exs` — six module groups, README main, Guides section, external URL extras, warnings-as-errors release step, and durable alias naming.
- `lib/threadline/critic_trust/measure.ex`, `lib/threadline/critic_trust/rank_metrics.ex`, `lib/threadline/critic_trust/ledger_splice.ex`, and `lib/threadline/critic_trust/krippendorff_alpha.ex` — hidden maintainer modules with durable source rationale.
- `lib/mix/tasks/critic.measure.ex` and `lib/mix/tasks/critic.synth.ex` — hidden maintainer Mix tasks and chronology-free local output language.
- `DESIGN-SYSTEM.md` — valid repository command references and durable evidence terminology.
- `guides/configuration-and-commands.md` — renamed maintainer browser contract and non-autolinking descriptions for hidden tasks.
- `test/threadline/public_surface_contract_test.exs` — exact owner scope and alias classification for this plan.
- `test/threadline/release_artifact_contract_test.exs` — URL-extra/package-absence contract plus assertions aligned to the six-group taxonomy.
- `examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts` — purpose-named browser contract replacing the planning-specific filename.
- `examples/threadline_phoenix/e2e/playwright.config.ts` and `test/threadline/operator_surface/component_contract_test.exs` — renamed browser-contract call sites.

## Decisions Made

- Followed the research inventory exactly for the initial public skeleton; later plans may only hide their audited conditional cohorts, not invent a miscellaneous group or expose component internals.
- Used ExDoc's native URL-extra shape with the repository URL as the matching source and `doc_source_ref/0` as the version authority; neither external resource entered `package.files`.
- Chose `verify.operator_component_contracts` because it describes the targeted browser job's stable responsibility across responsive components, motion, and reconnect behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical contract] Added the missing non-vacuous URL-extra verification tag**

- **Found during:** Task 2 verification preparation
- **Issue:** The planned `--only url_extras` command selected no prepared test, so the package-external/version-pinned promise had no runnable gate.
- **Fix:** Added a tagged contract that checks README/Guides configuration, exact lane order, both version-derived URLs, titles, lane assignment, and package absence.
- **Files modified:** `test/threadline/release_artifact_contract_test.exs`
- **Verification:** The tagged command selects one test and passes.
- **Committed in:** `a484e4ce`

**2. [Rule 1 - Contract bug] Restored exact ownership for the external design reference slice**

- **Found during:** Task 2 public-reference verification
- **Issue:** `public_doc_refs_external_design` also selected the example README even though Plan 200-09 owns that document through its dedicated example tag.
- **Fix:** Scoped the design owner to `DESIGN-SYSTEM.md`; the example owner remains unchanged.
- **Files modified:** `test/threadline/public_surface_contract_test.exs`
- **Verification:** The external-design tag selects one test and passes without laundering the later example work.
- **Committed in:** `a484e4ce`

**3. [Rule 1 - Compatibility tests] Updated existing release assertions for URL tuples and the new taxonomy**

- **Found during:** Task 2 adjacent-contract review
- **Issue:** Existing helpers treated every extra as a local path and legacy assertions required removed module-group keys.
- **Fix:** Filtered local guide extras explicitly and updated the affected assertions to the six-role group contract.
- **Files modified:** `test/threadline/release_artifact_contract_test.exs`
- **Verification:** The focused URL, tracer, command-reference, compile, format, and TypeScript checks all pass.
- **Committed in:** `a484e4ce`

**4. [Rule 1 - Acceptance gap] Strengthened the tracer to enforce every stated taxonomy invariant**

- **Found during:** Final acceptance-criteria audit
- **Issue:** The prepared tracer proved the façade and hidden critic set but did not itself fail on group key/order drift, duplicate façade membership, or a changed adopter-task set.
- **Fix:** Added exact six-key order, unique façade, and ordered ten-task assertions to the same tagged tracer.
- **Files modified:** `test/threadline/public_surface_contract_test.exs`
- **Verification:** The strengthened tracer selects one test and passes from the committed tree.
- **Committed in:** `5f9f95fc`

**Total deviations:** 4 auto-fixed (3 Rule 1, 1 Rule 2)

**Impact on plan:** The fixes make the planned release contracts executable and preserve exact cross-plan ownership; they introduce no runtime API, operator UI, dependency, or package-content expansion.

## Issues Encountered

- The plan's trailing `-x` remains unsupported by the pinned Mix 1.17.3 runner. The same paths and tags were run without only that invalid flag, with each command selecting exactly one test.
- A normal `mix docs` build succeeds and proves the URL-extra configuration is accepted by ExDoc. Warnings remain in documents and module cohorts explicitly owned by later Phase 200 plans; the release alias now correctly makes those warnings blocking at final release verification.

## Known Stubs

None.

## Threat Flags

None. The change adjusts documentation visibility and static repository links only; it adds no endpoint, authentication path, file-write path, schema, or runtime trust boundary.

## User Setup Required

None.

## Next Phase Readiness

- Plans 200-05 through 200-08 can now audit and hide their bounded internal cohorts against a stable six-group skeleton.
- Plans 200-09 onward can repair the canonical guide graph and remaining warning owners while preserving the README-led navigation and package-external resources.
- No public UI/component API or custom documentation skin was introduced.

## Self-Check: PASSED

- All 14 created, renamed, or modified plan files exist at their expected final paths.
- Task commits `4c7496ea`, `a484e4ce`, and `5f9f95fc` exist after the persisted `plan_head_before` base; the measured count at this summary refresh is 4, including the superseded first metadata commit.
- The tracer, URL-extra, external-design, and command-reference tags each select one test and pass.
- Elixir warnings-as-errors compilation, root formatting, TypeScript typecheck, diff whitespace, stale-identifier scan, and stub review pass.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
