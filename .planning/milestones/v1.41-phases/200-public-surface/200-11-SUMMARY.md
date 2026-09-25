---
phase: 200-public-surface
plan: 11
subsystem: documentation
tags: [hexdocs, guide-graph, public-api, developer-experience, architecture]
requires:
  - phase: 200-public-surface
    provides: finalized six-group module visibility and README-led canonical documentation owners
provides:
  - connected Evaluate and adoption-planning guide leaves with exact task-slice contracts
  - architecture guides expressed through public facades, tasks, returned types, and stable domain language
  - repaired Markdown paths, anchors, fences, chronology, and source-resolved public references
affects: [200-12, 200-13, 200-14]
actuals:
  tokens: 8233
  tasks: 2
  commits: 2
plan_head_before: 4b521b7ce7f5c089ecf8fda8b5846d641e89bf71
tech-stack:
  added: []
  patterns: [task-owned graph slices, landing-to-leaf routing, terminal Next steps contracts, public-facade architecture prose]
key-files:
  created: []
  modified:
    - CONTRIBUTING.md
    - guides/adoption-evidence-playbook.md
    - guides/adoption-pilot-backlog.md
    - guides/brownfield-continuity.md
    - guides/code-walkthrough.md
    - guides/domain-reference.md
    - guides/evaluating-threadline.md
    - guides/how-threadline-works.md
    - test/threadline/code_walkthrough_doc_contract_test.exs
    - test/threadline/guide_graph_contract_test.exs
    - test/threadline/how_threadline_works_doc_contract_test.exs
    - test/threadline/public_surface_contract_test.exs
key-decisions:
  - "Bound graph and reference-owner tags to the exact plan task slices so tracer verification is independent and non-vacuous."
  - "Architecture prose names public facades, tasks, returned types, and stable domain concepts; generated SQL may illustrate behavior without exposing hidden implementation modules."
  - "Distinct-successor proof is computed from the terminal Next steps section rather than from any outbound link in a guide."
patterns-established:
  - "Task-slice contract: a tagged tracer owns exactly the documents its task can change, while the later aggregate owns the complete 18-guide graph."
  - "Architecture explanation: document public entry points and observable domain behavior, not convenient private implementation modules."
requirements-completed: [SURFACE-01, SURFACE-06, SURFACE-07, SURFACE-09]
coverage:
  - id: D1
    description: "The Evaluate and adoption-planning slice has valid landing routes, terminal lane returns, distinct task successors, source-resolved references, and no planning chronology."
    requirement: SURFACE-06
    verification:
      - kind: integration
        ref: "test/threadline/guide_graph_contract_test.exs --only guide_graph_evaluate"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_evaluate"
        status: pass
    human_judgment: false
  - id: D2
    description: "The architecture guides teach Threadline through public facades and stable domain language while retaining parseable examples and the four-diagram system explanation."
    requirement: SURFACE-01
    verification:
      - kind: integration
        ref: "test/threadline/code_walkthrough_doc_contract_test.exs and test/threadline/how_threadline_works_doc_contract_test.exs"
        status: pass
      - kind: integration
        ref: "test/threadline/guide_graph_contract_test.exs --only guide_graph_architecture"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_architecture"
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 11: Evaluate and Architecture Guide Graph Summary

**Evaluate and architecture readers now traverse task-oriented guide paths whose examples resolve to public Threadline entry points instead of private implementation modules or planning-era language.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-12T10:36:12Z
- **Completed:** 2026-09-12T10:43:43Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Connected the five evaluation and adoption-planning leaves to their locked lane landings, terminal `Next steps`, and distinct adjacent tasks without expanding the 18-guide graph.
- Repaired invalid paths, malformed fences, private test-support references, and planning-era vocabulary in the touched guide slice.
- Recast the architecture walkthrough around public Mix tasks, router/auth/query/retention/evidence facades, returned structs, and generated SQL behavior.
- Strengthened task-local contracts so lane assignment, landing-to-leaf routing, terminal successor semantics, and hidden-module avoidance are executable guarantees.

## Task Commits

Each task was committed atomically:

1. **Task 1: Connect evaluation and adoption-planning guide leaves** — `c0f32f55` (docs)
2. **Task 2: Align architecture guides with public facades** — `db407f26` (docs)

## Files Created/Modified

- `CONTRIBUTING.md` — descriptive lane-landing route to the adoption pilot guide.
- `guides/evaluating-threadline.md` — Evaluate landing routes to all assigned architecture leaves.
- `guides/adoption-evidence-playbook.md` — valid public setup references and terminal task exits.
- `guides/adoption-pilot-backlog.md` — public proof language and contributor-lane exits.
- `guides/brownfield-continuity.md` — durable rationale without planning IDs and an Adopt-lane exit.
- `guides/domain-reference.md` — repaired SQL fences, public proof type, valid links, and architecture exits.
- `guides/code-walkthrough.md` — public tasks, facades, returned types, generated SQL examples, and Evaluate exits.
- `guides/how-threadline-works.md` — public module atlas, stable lifecycle language, and terminal Evaluate exits.
- `test/threadline/guide_graph_contract_test.exs` — exact task slices plus lane, landing, terminal-section, and successor contracts.
- `test/threadline/public_surface_contract_test.exs` — exact public-reference ownership for both Plan 11 slices.
- `test/threadline/code_walkthrough_doc_contract_test.exs` — public-source anchors, parseable examples, and private-module exclusions.
- `test/threadline/how_threadline_works_doc_contract_test.exs` — public-facade and terminal-section assertions with private-module exclusions.

## Decisions Made

- Kept each tracer independently executable by assigning its tags only the files that task owns; complete 18-guide closure remains the later aggregate's responsibility.
- Used generated SQL where trigger behavior is the clearest explanation, but routed generation through public Mix tasks and removed all hidden Elixir module names.
- Preserved canonical ownership: Getting Started owns installation, Operator Surface owns mounting/auth/configuration, and Local Docker DX owns the local environment lifecycle.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Contract bug] Repaired prepared tags that crossed task boundaries**

- **Found during:** Task 1 tracer verification
- **Issue:** `guide_graph_evaluate` validated the whole Evaluate lane, including Task 2 files, while `guide_graph_architecture` validated the Adopt lane. Public-reference tags likewise split Plan 11 documents across unrelated owner tags, preventing an independent tracer proof.
- **Fix:** Mapped both graph and public-reference tags to the exact Task 1 and Task 2 document slices while preserving the complete 18-guide assignment map for later aggregate verification.
- **Files modified:** `test/threadline/guide_graph_contract_test.exs`, `test/threadline/public_surface_contract_test.exs`
- **Verification:** All four Plan 11 tag selections are nonempty and pass.
- **Committed in:** `c0f32f55`

**2. [Rule 2 - Missing critical contract] Made task-oriented graph semantics executable**

- **Found during:** Task 1 tracer implementation
- **Issue:** The prepared helper accepted a successor link anywhere in a document and did not require a lane landing to route to each assigned leaf. This could pass a graph with a dead landing or a terminal section that offered no next task.
- **Fix:** Required exact one-lane assignment, lane-to-leaf routing, a terminal `Next steps` section, a lane return, and a distinct successor inside that terminal section. Converted the contributor landing's pilot path into the descriptive link needed to close that route.
- **Files modified:** `test/threadline/guide_graph_contract_test.exs`, `CONTRIBUTING.md`
- **Verification:** Both focused graph tags and the non-red graph contract pass.
- **Committed in:** `c0f32f55`

---

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 2)

**Impact on plan:** The changes make the intended bounded contracts meaningful without adding a guide, changing a public facade, or expanding runtime/UI scope.

## Issues Encountered

- The plan's trailing `-x` is unsupported by the pinned Mix 1.17.3 runner. As in prior Phase 200 plans, every exact path and tag was run without only that invalid option; all selections were nonempty and green.
- The full warnings-as-errors documentation build still reports warnings in guides owned by later Phase 200 plans. Its output contains no warning for any of the seven Plan 11 guide files, and full-site closure remains assigned to Plans 200-12 and 200-14.

## Known Stubs

None.

## Threat Flags

None. This plan changes documentation and documentation contracts only. It adds no endpoint, authorization path, filesystem behavior, schema, or runtime trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 200-12 can integrate the remaining guide leaves and run complete 18-guide graph and warnings-as-errors closure without reopening Plan 11's public-facade or canonical-owner decisions.
- Plan 200-14 can consume exact lane assignments and terminal-edge semantics for the final aggregate gate.
- No runtime module, public facade name, UI, LiveView, CSS, layout, or rendered product surface changed.

## Self-Check: PASSED

- All twelve task files and both task commits exist.
- Both coverage deliverables classify as fully automated and passing.
- Focused contracts, affected legacy doc contracts, formatting, hidden-reference, whitespace, and Plan 11 warning scans pass on the pinned toolchain.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
