---
phase: 200-public-surface
plan: 09
subsystem: documentation
tags: [readme, hexdocs, canonical-guides, phoenix-example, developer-experience]
requires:
  - phase: 200-public-surface
    provides: source-derived documentation references and canonical configuration/command reference
provides:
  - README-led four-intent hub with one canonical adopter path
  - canonical first-hour procedure with optional integrations deferred until after first success
  - Phoenix reference-app proof index linked to exact setup, operator, and Docker owners
  - strict caller, anchor, package-coordinate, and public-reference contracts
affects: [200-10, 200-11, 200-12, 200-13, 200-14]
actuals:
  tokens: 19707
  tasks: 2
  commits: 3
plan_head_before: a8c3695b3e65608fafeb9081b66aeb1be4148b7a
tech-stack:
  added: []
  patterns: [canonical procedure ownership, routing-only callers, source-linked example proof, positive-control documentation contracts]
key-files:
  created: []
  modified:
    - README.md
    - guides/getting-started-saas.md
    - examples/threadline_phoenix/README.md
    - test/threadline/readme_doc_contract_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - test/threadline/example_phoenix_readme_contract_test.exs
    - test/threadline/persona_routing_doc_contract_test.exs
    - test/threadline/guide_graph_contract_test.exs
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/local_docker_dx_contract_test.exs
key-decisions:
  - "README retains the four exact intent lanes and theme-aware brand asset while Quick Start carries only the current package coordinate and descriptive links into canonical adoption references."
  - "The Phoenix example README is a proof index: source, test, support, and dependency evidence stay local, while runnable install, operator, and Docker procedures live in their canonical guides."
  - "Only Threadline task and repository-alias namespaces participate in Threadline public-reference validation; ordinary Mix ecosystem commands remain owned by their respective tools."
patterns-established:
  - "Caller contract: routing surfaces may carry audience, outcome, prerequisites, safety boundaries, package coordinates, and descriptive links, but no duplicate runnable procedure fences."
  - "Example proof contract: every canonical-owner link resolves its path and anchor, package coordinates agree with mix.exs, and each example claim points to existing source or test evidence."
requirements-completed: [SURFACE-06, SURFACE-07, SURFACE-09]
coverage:
  - id: D1
    description: "README preserves four-intent routing and theme-aware branding while delegating the complete install and first-hour sequence to Getting Started."
    requirement: SURFACE-09
    verification:
      - kind: integration
        ref: "test/threadline/guide_graph_contract_test.exs#installation and first-hour commands live only in Getting Started"
        status: pass
      - kind: integration
        ref: "test/threadline/readme_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/persona_routing_doc_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Getting Started owns the full numbered first-hour procedure, links the canonical configuration reference, and moves optional auth-specific paths after first success."
    requirement: SURFACE-06
    verification:
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_adopt_core"
        status: pass
      - kind: unit
        ref: "test/threadline/getting_started_saas_doc_contract_test.exs#optional reference paths follow the complete numbered first-hour path"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Phoenix example routes to valid anchors in all three canonical owners and retains source-resolved package, behavior, and test proof without a competing setup block."
    requirement: SURFACE-07
    verification:
      - kind: integration
        ref: "test/threadline/example_phoenix_readme_contract_test.exs"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_example"
        status: pass
    human_judgment: false
duration: 28min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 09: Canonical Adopter Path Summary

**README now routes one adopter into a single first-hour owner, while the Phoenix example exposes source-backed proof without repeating setup, mount, or Docker procedures.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-09-12T08:37:41Z
- **Completed:** 2026-09-12T09:05:27Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Reduced README Quick Start to the current package coordinate and descriptive Adopt links while preserving the four exact verbs, their canonical landings, and the theme-aware brand asset.
- Kept Getting Started as the sole runnable first-hour owner, repaired same-directory links, connected the canonical configuration reference, and moved optional authentication paths after the complete numbered flow.
- Replaced the 550-line example runbook with a concise proof index whose three canonical-owner anchors, package coordinates, source links, and executable-test links are validated mechanically.

## Task Commits

1. **Task 1: Make Getting Started the single runnable first-hour owner** — `b6e65c42` (docs)
2. **Task 2: Turn the example README into linked proof, not a second setup guide** — `2717d8b2` (docs)
3. **Task 1 acceptance follow-up: Defer optional auth paths until after first success** — `9043a033` (docs)

## Files Created/Modified

- `README.md` — four-intent HexDocs hub with package-only Quick Start orientation.
- `guides/getting-started-saas.md` — canonical numbered first-hour procedure, repaired guide links, and post-success optional paths.
- `examples/threadline_phoenix/README.md` — example-specific source, dependency, support, and test proof index.
- `test/threadline/readme_doc_contract_test.exs` — routing-only README and example expectations.
- `test/threadline/getting_started_saas_doc_contract_test.exs` — first-hour ordering, canonical-reference, and successor contracts.
- `test/threadline/example_phoenix_readme_contract_test.exs` — dependency, owner-anchor, proof-link, and duplicate-procedure protection.
- `test/threadline/guide_graph_contract_test.exs` — routed-caller procedure ownership at runnable-fence granularity.
- `test/threadline/persona_routing_doc_contract_test.exs` — theme-aware README brand-asset protection.
- `test/threadline/public_surface_contract_test.exs` — Threadline-owned command namespace validation.
- `test/threadline/local_docker_dx_contract_test.exs` — Docker owner-link contract for the example caller.

## Decisions Made

- Preserved README as the single four-intent hub; no new start-here guide or navigation taxonomy was introduced.
- Kept the current package coordinate visible for 30-second orientation, but removed configuration, migration, trigger, query, and example runbook copies from non-owner surfaces.
- Treated the external example as proof rather than onboarding: exact dependency declarations, implementation files, focused tests, and honest support boundaries remain discoverable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Contract bug] Scoped public command validation to Threadline-owned namespaces**

- **Found during:** Task 1 public-reference verification
- **Issue:** The source-derived reference checker treated ordinary ecosystem commands such as `mix deps.get`, `mix ecto.migrate`, and `mix phx.server` as unknown Threadline repository aliases.
- **Fix:** Restricted task checks to `threadline.*` and repository-alias checks to `verify.*`, `ci.*`, and `test.*`, leaving commands owned by Mix, Ecto, and Phoenix outside Threadline's compatibility inventory.
- **Files modified:** `test/threadline/public_surface_contract_test.exs`
- **Verification:** `public_doc_refs_adopt_core` and `public_doc_refs_example` each select one test and pass.
- **Committed in:** `b6e65c42`

**2. [Rule 2 - Missing critical contract] Replaced literal-count ownership with scoped runnable-procedure proof**

- **Found during:** Task 1 canonical-owner verification
- **Issue:** The prepared tracer counted every command mention across unfinished later-plan guides, so it rejected valid reference mentions without proving whether README or the example contained a duplicate runnable procedure.
- **Fix:** Bound the tracer to this plan's callers and executable fences, then added an example-contract positive control that proves an injected ordered setup block is rejected.
- **Files modified:** `test/threadline/guide_graph_contract_test.exs`, `test/threadline/example_phoenix_readme_contract_test.exs`
- **Verification:** `canonical_owner_tracer` selects one test and passes; the example contract's positive-control test passes.
- **Committed in:** `b6e65c42`, `2717d8b2`

**3. [Rule 1 - Documentation ordering] Moved optional authentication material after the first-hour path**

- **Found during:** Final acceptance audit after Task 2
- **Issue:** Sigra-specific runnable wiring and curl staging still appeared before the primary numbered first-hour path was complete, contrary to the plan's primary-path-first requirement.
- **Fix:** Removed the duplicate optional recipes and added concise post-path links to the phx.gen.auth and Sigra owners plus the Phoenix proof index.
- **Files modified:** `guides/getting-started-saas.md`, `test/threadline/getting_started_saas_doc_contract_test.exs`
- **Verification:** The complete Getting Started contract and both plan gates pass after the follow-up commit.
- **Committed in:** `9043a033`

---

**Total deviations:** 3 auto-fixed (2 Rule 1, 1 Rule 2)

**Impact on plan:** The fixes make the ownership tests non-vacuous and align the final information architecture with the locked primary-path ordering. No runtime API, operator UI, dependency, package contents, or new navigation surface changed.

## Issues Encountered

- The plan's trailing `-x` is unsupported by the pinned Mix 1.17.3 task runner, as established by earlier Phase 200 plans. Every specified path and tag was run without only that invalid option, preserving fail-fast shell behavior and selecting nonzero tests.

## Known Stubs

None.

## Threat Flags

None. This plan changes documentation and documentation contracts only; it adds no endpoint, auth path, schema, file-access primitive, or runtime trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 200-10 can make the Operator Surface the sole mount/auth/configuration owner without competing example or README setup material.
- Plans 200-11 and 200-12 can complete the remaining 18-guide graph while preserving the established README hub and owner/caller split.
- No blocker remains for this plan.

## Self-Check: PASSED

- All ten modified files exist on disk.
- Task commits `b6e65c42`, `2717d8b2`, and `9043a033` exist after the persisted `plan_head_before`; the measured count is 3.
- Both task gates, all three dedicated doc contracts, the example contract, and the adjacent Docker contract pass on the committed tree.
- Format, whitespace, stub, and threat-surface scans pass.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
