---
phase: 200-public-surface
plan: 08
subsystem: documentation
tags: [exdoc, public-api, module-visibility, operator-surface, changelog]
requires:
  - phase: 200-public-surface
    provides: six-role ExDoc skeleton and source-derived visibility/reference contracts
  - phase: 200-public-surface
    provides: audited visibility decisions for critic, capture, governance, delivery, and authorization cohorts
provides:
  - final exact six-group equality for every packaged ExDoc-visible module
  - audit-backed hidden visibility for remaining operator implementation helpers
  - durable public Router documentation with unchanged mount behavior
  - explicit changelog record for every 0.9 module removed from generated documentation
affects: [200-11, 200-12, 200-14, 201-rendered-output]
actuals:
  tokens: 6040
  tasks: 2
  commits: 2
plan_head_before: 773f072e1d9eee5ca4ea3fc3d9c5508f07ef9a8f
tech-stack:
  added: []
  patterns: [consumer-contract visibility audit, packaged-source compiled inventory, documentation-only compatibility clarification]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/exports/filename.ex
    - lib/threadline/operator_surface/exports/filter_params.ex
    - lib/threadline/operator_surface/presentation.ex
    - lib/threadline/operator_surface/scope.ex
    - lib/threadline/operator_surface/script.ex
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/operator_surface/components/surface_header.ex
    - test/threadline/public_surface_contract_test.exs
    - CHANGELOG.md
key-decisions:
  - "Filename, FilterParams, Scope, Script, and SurfaceHeader are implementation modules behind public facades; Presentation remains hidden and Router remains the supported public mount contract."
  - "The exact visibility inventory is derived from compiled modules whose source lives under lib/, excluding test-support modules that are never packaged or rendered by HexDocs."
  - "The existing six explicit mix.exs groups already matched the final audited public set, so the plan preserved them without cosmetic churn."
  - "The changelog names all 23 modules documented in 0.9 that are now hidden and states that documentation visibility does not change runtime callability."
patterns-established:
  - "Compiled visibility contracts filter by packaged source before exact-set comparison, so MIX_ENV=test support modules cannot distort the consumer surface."
  - "Public Router documentation describes routes and authorization through supported callbacks and outcomes rather than hidden controller or plug names."
requirements-completed: [SURFACE-01, SURFACE-02, SURFACE-03, SURFACE-04, SURFACE-05, SURFACE-07]
coverage:
  - id: D1
    description: "Remaining operator implementation helpers are hidden while Router stays public with source-accurate mount documentation and unchanged behavior."
    requirement: SURFACE-03
    verification:
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only module_visibility_operator_helpers"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_module_operator_helpers"
        status: pass
      - kind: integration
        ref: "focused router, filename, filter, presentation, scope, and header suites (88 tests)"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every packaged visible module appears exactly once in the six explicit groups, and the changelog records the complete documentation-visibility clarification with valid references."
    requirement: SURFACE-04
    verification:
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only module_visibility"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_changelog"
        status: pass
      - kind: other
        ref: "bounded Plans 200-04 through 200-08 vocabulary scan over 40 owned files"
        status: pass
      - kind: other
        ref: "tag-derived check that all 23 previously documented 0.9 modules are named in CHANGELOG.md"
        status: pass
    human_judgment: false
duration: 33min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 08: Final Module Visibility and Changelog Summary

**Threadline's packaged module surface now equals six explicit ExDoc groups exactly, with operator internals hidden behind a durable public Router contract and every 0.9 visibility change recorded honestly.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-09-12T09:56:10Z
- **Completed:** 2026-09-12T10:29:54Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Audited the remaining operator cohort by call path, return type, configuration, and extension role; hid filename, filter, scope, script, and surface-header implementation modules while retaining `Threadline.OperatorSurface.Router` as the supported mount seam.
- Rewrote Router's public documentation around stable routes, callbacks, authorization, and host-router behavior without naming hidden controllers or plugs; no executable route or render code changed.
- Made the full visibility contract compare only compiled modules sourced from packaged `lib/` files, then proved that every visible module appears exactly once in the existing six groups and no hidden module is grouped.
- Added an Unreleased clarification naming all 23 modules that had pages in the 0.9 documentation and are now hidden, while explicitly preserving their runtime callability and supported façade behavior.
- Removed stale planning chronology and the nonexistent `mix verify.evidence` command reference from the changelog, and proved the bounded source/document vocabulary owners through Plan 200-08 are clean.

## Task Commits

1. **Task 1: Audit remaining operator helpers and preserve the public Router** — `bc26be63` (docs)
2. **Task 2: Reconcile final module groups and changelog against audit evidence** — `e25415d8` (docs)

## Files Created/Modified

- `lib/threadline/operator_surface/exports/filename.ex` — hidden internal export filename formatter.
- `lib/threadline/operator_surface/exports/filter_params.ex` — hidden shared HTTP/LiveView filter parser with durable invariant comments.
- `lib/threadline/operator_surface/presentation.ex` — preserved hidden status/copy presentation helper and removed release chronology from source docs.
- `lib/threadline/operator_surface/scope.ex` — hidden query-scope dispatch helper behind public Query and Router options.
- `lib/threadline/operator_surface/script.ex` — hidden embedded copy-helper implementation behind the public configuration and operator guide.
- `lib/threadline/operator_surface/router.ex` — retained public mounting contract with concise source-accurate documentation and chronology-free scope comments.
- `lib/threadline/operator_surface/components/surface_header.ex` — hid the internal header component missed by the original bounded cohort.
- `test/threadline/public_surface_contract_test.exs` — limited compiled visibility discovery to packaged `lib/` sources so test helpers cannot enter the HexDocs inventory.
- `CHANGELOG.md` — documented all 0.9 visibility clarifications, removed planning labels, and repaired a stale command reference.

`mix.exs` required no change: its six explicit allowlists already matched the final audit once the remaining implementation modules were hidden.

## Decisions Made

| Module cohort | Consumer-contract evidence | Documentation result |
| --- | --- | --- |
| Filename and filter helpers | Called by Threadline controllers, LiveViews, and export orchestration; no supported direct adopter call or return contract | Hidden |
| Presentation, scope, and script helpers | Internal rendering, scoping, and asset implementation behind public facades, Router options, and configuration | Hidden |
| SurfaceHeader | Rendered only through Threadline's private UI and exercised by internal tests/stress fixtures | Hidden |
| Router | Imported directly by host Phoenix routers and owns the supported mount/options contract | Public and grouped |

The audit changes documentation metadata, comments, and changelog prose only. No function body, callback, route, option, status code, response, DOM, CSS, copy behavior, or public return shape changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical visibility] Hid the omitted SurfaceHeader implementation module**

- **Found during:** Task 1 exact visibility audit
- **Issue:** `Threadline.OperatorSurface.Components.SurfaceHeader` was still ExDoc-visible even though its only production consumer is Threadline's private UI layer; leaving it visible would prevent exact six-group equality or force an internal component into the public contract.
- **Fix:** Added `@moduledoc false` after confirming all call sites are Threadline-owned rendering, stress, or test code.
- **Files modified:** `lib/threadline/operator_surface/components/surface_header.ex`
- **Verification:** Full `module_visibility` equality and 88 focused operator tests pass.
- **Committed in:** `bc26be63`

**2. [Rule 1 - Contract bug] Excluded test-support modules from the packaged visibility inventory**

- **Found during:** Task 1 exact visibility audit
- **Issue:** Under `MIX_ENV=test`, `:application.get_key(:threadline, :modules)` includes modules compiled from `test/support/`, although those modules are absent from the Hex package and generated docs.
- **Fix:** Kept compiled-module discovery but filtered by each module's compiler source path under `lib/` before comparing against the six groups.
- **Files modified:** `test/threadline/public_surface_contract_test.exs`
- **Verification:** The contract reports no missing, duplicate, extra, or hidden group member; every bounded owner tag remains nonempty and green.
- **Committed in:** `bc26be63`

**3. [Rule 1 - Stale public reference] Repaired the historical verify.evidence command mention**

- **Found during:** Task 2 changelog reference verification
- **Issue:** A historical note formatted the removed `verify.evidence` alias as a runnable `mix` command, so the source-derived reference checker correctly reported a nonexistent public alias.
- **Fix:** Kept the historical comparison but described it as the earlier alias while preserving `mix threadline.evidence.show` as the runnable command.
- **Files modified:** `CHANGELOG.md`
- **Verification:** `public_doc_refs_changelog` selects one test and passes.
- **Committed in:** `e25415d8`

**Total deviations:** 3 auto-fixed (2 Rule 1, 1 Rule 2)

**Impact on plan:** The fixes close direct release-contract gaps without widening the public API or touching operator runtime/rendered behavior. The two unlisted files are limited to module documentation metadata and the test-only source-derived inventory.

## Issues Encountered

- The plan's trailing `-x` is unsupported by the pinned Mix 1.17.3 runner, as established by earlier Phase 200 plans. Each exact path/tag command was run without only that invalid option; every selection executed one nonempty test and passed.
- The six `mix.exs` group lists needed no textual update because Plan 200-04's skeleton already matched the final retained public set after this audit.

## Known Stubs

None.

## Threat Flags

None. This plan narrows generated documentation visibility and modifies no network endpoint, authorization behavior, file-access path, schema, dependency, or runtime trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 200-11 and 200-12 can update public guides against the final module surface without depending on hidden helper names.
- Plans 200-15 through 200-18 retain ownership of the remaining bounded source-vocabulary cohorts.
- Plan 200-14 can run the complete public-document, source, archive, docs, package, and hosted gates after every remaining owner finishes.

## Self-Check: PASSED

- All nine modified task files and this summary exist.
- Task commits `bc26be63` and `e25415d8` are present after the recorded plan base.
- The coverage classifier reports both plan decision points automatically covered and passing.
- The only stub-pattern match is intentional changelog language describing database placeholder metadata; no implementation stub, skipped test, or unrun verification remains.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
