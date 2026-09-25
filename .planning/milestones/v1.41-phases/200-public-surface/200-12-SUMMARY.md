---
phase: 200-public-surface
plan: 12
subsystem: documentation
tags: [hexdocs, guide-graph, integrations, accessibility, package-assets]
requires:
  - phase: 200-public-surface
    provides: finalized module visibility, canonical documentation owners, and connected Evaluate/architecture guide slices
provides:
  - public-facade integration contract with source-resolved module, task, alias, and configuration references
  - exact connected 18-guide intent graph with valid paths, anchors, lane returns, and task-adjacent successors
  - native ExDoc presentation verified across theme, viewport, keyboard, external-link, Mermaid, and overflow states
  - packaged light/dark README logo assets for generated documentation
affects: [200-13, 200-14, release-documentation, hexdocs]
actuals:
  tokens: 3368
  tasks: 2
  commits: 4
plan_head_before: 0d957b69fd0899c51e4d38c249ac3ce8d04c9032
tech-stack:
  added: []
  patterns: [public-facade prose, exact intent graph, repository-resource resolution, native ExDoc browser inspection]
key-files:
  created: []
  modified:
    - guides/integration-contracts.md
    - guides/integrations/phx-gen-auth.md
    - guides/integrations/sigra.md
    - guides/getting-started-saas.md
    - test/threadline/integration_contracts_doc_contract_test.exs
    - test/threadline/guide_graph_contract_test.exs
    - mix.exs
    - test/threadline/release_artifact_contract_test.exs
key-decisions:
  - "Integration guidance names supported public facades and outcomes rather than hidden plug/controller implementation modules."
  - "Repository-local external resources may resolve as Markdown targets without becoming additional nodes in the locked 18-guide graph."
  - "README theme assets ship as two explicit Hex package files and are copied through native ExDoc assets; repository-only brand guidance remains outside the archive."
patterns-established:
  - "Terminal integration leaves return to their intent landing and offer a distinct adjacent implementation task."
  - "Native documentation presentation is checked in a real browser through DOM geometry, computed theme state, focus state, and Mermaid rerender output."
requirements-completed: [SURFACE-01, SURFACE-04, SURFACE-05, SURFACE-06, SURFACE-07, SURFACE-09]
coverage:
  - id: D1
    description: "All integration guides use finalized public identifiers and participate in the exact connected 18-node intent graph."
    requirement: SURFACE-06
    verification:
      - kind: integration
        ref: "test/threadline/integration_contracts_doc_contract_test.exs (8 tests)"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_integrations_contract and --only public_doc_refs_integrations_tail"
        status: pass
      - kind: integration
        ref: "test/threadline/guide_graph_contract_test.exs (9 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Native README-led ExDoc preserves ordered guide navigation, version-pinned resources, keyboard focus, responsive overflow, theme switching, Mermaid rendering, and theme-aware logo assets."
    requirement: SURFACE-09
    verification:
      - kind: other
        ref: "MIX_ENV=dev mix docs"
        status: pass
      - kind: automated_ui
        ref: "agent-browser native ExDoc inspection at 1440x1000 and 390x844 in light/dark modes"
        status: pass
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs:70"
        status: pass
    human_judgment: false
duration: 41min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 12: Integration Docs and Native Guide Surface Summary

**Threadline's integration documentation now forms one exact intent graph over public facades, with responsive native ExDoc navigation and working theme-aware README assets.**

## Performance

- **Duration:** 41 min
- **Started:** 2026-09-12T11:17:07Z
- **Completed:** 2026-09-12T11:58:07Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Reconciled Integration Contracts with the supported `Threadline.Plug`, `Threadline.Job`, `Threadline.Audit`, Sigra, Router, and Auth facades while removing hidden implementation references.
- Connected both integration leaves and the Adopt landing so exactly 18 guide nodes have valid lane ownership, non-README inbound/outbound edges, terminal lane returns, distinct successors, paths, and anchors.
- Verified the six native ExDoc guide groups, both version-pinned external resources, visible keyboard focus, dark/light theme state, narrow/wide overflow, and four theme-rerendered Mermaid diagrams in a real browser.
- Fixed the generated README picture so both theme-aware logo variants are present in ExDoc and in the exact Hex package allowlist.

## Task Commits

1. **Task 1: Reconcile the integration contract guide with public facades** — `629860cb` (docs)
2. **Task 2: Connect integration leaves and prove the complete native guide surface** — `5e6b4cc8` (docs)
3. **Task 2 deviation: Ship README logo assets in ExDoc** — `9d6c0c20` (fix)
4. **Task 1 formatting follow-up** — `57478afd` (style)

## Files Created/Modified

- `guides/integration-contracts.md` — public-facade breadth contract and terminal Adopt-lane routes.
- `guides/integrations/phx-gen-auth.md` — terminal Adopt return and adjacent integration/operator tasks.
- `guides/integrations/sigra.md` — terminal Adopt return and adjacent integration/operator tasks.
- `guides/getting-started-saas.md` — complete landing routes to every assigned Adopt guide.
- `test/threadline/integration_contracts_doc_contract_test.exs` — public-facade and graph-exit contract.
- `test/threadline/guide_graph_contract_test.exs` — repository-resource-aware path resolution and ExDoc-compatible underscore anchors.
- `mix.exs` — theme-aware README asset copying and exact packaged logo files.
- `test/threadline/release_artifact_contract_test.exs` — logo packaging and ExDoc asset-map regression contract.

## Decisions Made

- Kept integration prose consumer-shaped: public facades, callback inputs, outcomes, and host responsibilities remain visible; private plug names and source paths do not.
- Treated `DESIGN-SYSTEM.md` and the reference-app README as resolvable repository resources but not graph nodes, preserving the exact 18-guide taxonomy.
- Preserved native ExDoc chrome and all six existing group names. No operator UI, custom docs skin, or new documentation dependency was added.
- Added only the two README logo files to the Hex archive; the design system, example README, brand book, and other repository-only assets remain outside it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Contract bug] Corrected repository-resource and identifier-anchor resolution**

- **Found during:** Task 2 complete graph verification
- **Issue:** The graph helper rejected the version-linked example README as missing and stripped underscores from valid headings such as `correlation_id`.
- **Fix:** Included the two repository resources in link resolution without adding graph nodes, and preserved underscores in normalized headings.
- **Files modified:** `test/threadline/guide_graph_contract_test.exs`
- **Verification:** Full 9-test guide graph passes.
- **Committed in:** `5e6b4cc8`

**2. [Rule 2 - Missing critical graph wiring] Completed the Adopt landing routes**

- **Found during:** Task 2 complete graph verification
- **Issue:** Getting Started did not route to Integration Contracts, Local Docker DX, or Upgrade Path even though all three belong to its lane.
- **Fix:** Added descriptive links to the existing terminal Next steps list.
- **Files modified:** `guides/getting-started-saas.md`
- **Verification:** Exact 18-node graph and persona-routing contracts pass.
- **Committed in:** `5e6b4cc8`

**3. [Rule 2 - Missing critical presentation asset] Shipped the README theme logos**

- **Found during:** Task 2 native ExDoc browser inspection
- **Issue:** The generated README requested `brandbook/logo-primary-light.svg`, but ExDoc had not copied it and the Hex archive did not contain either theme logo, leaving the landing image broken.
- **Fix:** Added native ExDoc asset copying, packaged exactly the light/dark README logos, and added a focused release-artifact contract.
- **Files modified:** `mix.exs`, `test/threadline/release_artifact_contract_test.exs`
- **Verification:** Both generated logo files are nonempty; the browser reports natural width 300 and no failed images; the focused release package test passes.
- **Committed in:** `9d6c0c20`

---

**Total deviations:** 3 auto-fixed (1 Rule 1, 2 Rule 2)

**Impact on plan:** All fixes were necessary to make the exact graph and native presentation claims true. Runtime APIs, operator UI, dependencies, and the locked navigation taxonomy remain unchanged.

## Issues Encountered

- The plan's trailing `-x` option is unsupported by pinned Mix 1.17.3. The same focused commands were run without only that invalid option; every selection was nonempty and green.
- The complete release-artifact suite still reports pre-existing planning vocabulary in `CONTRIBUTING.md`, which Plan 200-13 owns. The focused asset contract passes and the finding is recorded in `deferred-items.md`.
- `mix docs` succeeds but still reports hidden-reference warnings in guides and module docs owned by other Phase 200 plans. Per plan, final warnings-as-errors closure remains Plan 200-14 work.

## Known Stubs

None.

## Threat Flags

None. Changes affect documentation, documentation assets, and test-time validation only; they add no endpoint, authorization path, schema, or runtime file access.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 200-13 can rewrite the remaining contributor-owned archive vocabulary without reopening the guide graph.
- Plan 200-14 can run final warnings-as-errors and unpacked-archive gates against a complete native guide surface.
- No unresolved blocker remains in Plan 200-12.

## Self-Check: PASSED

- All eight implementation/test files and all four task commits exist.
- Both coverage deliverables are backed by passing, nonempty test selections and browser evidence.
- Formatting, exact graph, integration-reference cohorts, focused package-assets contract, docs generation, and generated asset checks pass on the pinned toolchain.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
