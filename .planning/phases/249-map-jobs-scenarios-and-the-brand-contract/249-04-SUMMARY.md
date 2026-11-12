---
phase: 249-map-jobs-scenarios-and-the-brand-contract
plan: "04"
subsystem: admin-inventory
tags: [operator-jobs, semantic-inventory, phoenix-liveview, proof-mapping, brand-reference]

requires:
  - phase: 249-map-jobs-scenarios-and-the-brand-contract
    provides:
      - "Plan 01 route/resource inventory and semantic-inventory contracts"
  - phase: 249-map-jobs-scenarios-and-the-brand-contract
    provides:
      - "Plan 02 corrected demo calendar, stable identities, and retention boundary"
  - phase: 249-map-jobs-scenarios-and-the-brand-contract
    provides:
      - "Plan 03 coherent seed timestamps, row snapshots, and fixture contracts"
provides:
  - "Ordinary #4521 selection guidance linked to stable seed identities, routes, evidence owners, and return context"
  - "Named ordinary and stress scenarios with source-grounded state criteria and comparison-only baseline links"
  - "Reference-only crosswalk for approved brand roles, assets, consumers, proof gaps, and later owners"
  - "Independent source/claim review with prior findings reconciled and remaining evidence limits preserved"
affects: [249-phase-verification, phase-250, phase-251, phase-252, phase-253, operator-inventory, brand-migration]

actuals:
  tokens: 268753
  reasoning_output_tokens: 150032
  worker_elapsed_s: 7227
  measurement_source: codex-exec-terminal-usage
  tokens_meaning: output_tokens_including_reasoning
  elapsed_meaning: managed_process_including_review_handoff_waits
  tasks: 2
  commits: 4
  plan_head_before: 559082e0d7c31937e7498c360d46eb122c6581a8
  plan_head_after: b18a59a66c9f03c57933bc1f8a72b611fa0c2579

tech-stack:
  added: []
  patterns:
    - "Keep scenario, route-state, and brand maps tied to exact source/proof identities and explicit limitations"
    - "Use an ordinary scenario as a comparison baseline without replacing named stress fixtures"
key-files:
  created:
    - .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-MAPPING-REVIEW.md
    - .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-04-SUMMARY.md
  modified:
    - examples/threadline_phoenix/DEMO-MANIFEST.md
    - examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts
    - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
    - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
    - examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs
key-decisions:
  - "Keep ordinary #4521 selection separate from the named stress fixtures; stress links to it for comparison only."
  - "Keep the approved brand crosswalk reference-only; runtime assets, tokens, and public APIs remain outside this plan."
  - "Leave ADM-05, ADM-06, and ADM-07 addressed but incomplete until phase-level verification resolves their remaining scope."
requirements-completed: []
requirements-addressed: [ADM-05, ADM-06, ADM-07]
coverage:
  - id: D1
    description: "Maintainers can select the ordinary #4521 investigation from stable private seed keys and trace it through the route, evidence, and return-context recipe."
    requirement: ADM-06
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs (10 tests, pass)"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts (included in the 30-test focused Node run, pass)"
        status: pass
      - kind: other
        ref: ".planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-MAPPING-REVIEW.md#eight-question-rubric"
        status: pass
    human_judgment: false
  - id: D2
    description: "Named ordinary and stress scenarios retain separate identities, mapped states, proof owners, and honest comparison limits."
    requirement: ADM-07
    verification:
      - kind: unit
        ref: "./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts (30 tests, pass; run from examples/threadline_phoenix/e2e)"
        status: pass
      - kind: other
        ref: ".planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-MAPPING-REVIEW.md#reconciled-prior-findings"
        status: pass
    human_judgment: false
  - id: D3
    description: "Approved brand roles and supplied assets are cross-referenced to consumers, jobs, proof gaps, and later owners without claiming runtime adoption or rendered acceptance."
    verification:
      - kind: unit
        ref: "./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts (brand crosswalk contract, included in 30 passing tests)"
        status: pass
      - kind: other
        ref: ".planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-MAPPING-REVIEW.md#eight-question-rubric"
        status: pass
    human_judgment: false
duration: 120min27s
completed: 2026-11-12
status: complete
---

# Phase 249 Plan 04: Map jobs, scenarios and the brand contract Summary

**An executable semantic inventory now links ordinary and stress operator journeys, route states, proof owners, and approved brand references.**

## Performance

- **Managed duration:** 120 minutes 27 seconds from launch to terminal exit, including planned independent-review and handoff waits. Terminal usage records 268753 output tokens, including 150032 reasoning tokens; input/cache usage remains in the private managed receipt. These are measured process totals, not a character estimate or a claim of active execution time.
- **Summary authored:** 2026-11-12T05:15:18Z. This is the documentation time, not the plan's terminal timestamp.
- **Tasks:** 2 completed.
- **Files:** 5 source files, the independent review artifact, and this summary.
- **Measured production commits:** 4 from the dispatch-bound starting HEAD through `b18a59a`.

## Accomplishments

- Connected the ordinary Acme #4521 investigation to its stable private seed keys, route and evidence owners, preserved return context, and maintainer selection recipe.
- Completed named ordinary/stress scenario and route-state references, including a comparison-only link from seven stress scenarios to #4521 and explicit proof limitations.
- Added a reference-only crosswalk for all eight approved brand roles and supplied asset families, with consumers, proof gaps, and later phase owners.
- Tightened the route contract so exact source/proof locators and negative controls catch callback drift, missing actor/action proof, and unsupported transaction pagination claims.
- Received a clean independent review at `b18a59a`; the report reconciles earlier findings and keeps ADM-06's unresolved prohibition flags visible.

## Task Commits

1. **Task 1: Trace ordinary #4521 selection from corrected seed through inventory to maintainers' recipe** — `d515b01` (`feat`).
2. **Task 2: Complete named scenarios, brand consumers and independent claim review** — `2bec3d4` (`feat`).

### Review correction commits

- `da1f25e` — linked route-specific states and added ordinary comparison baselines for stress scenarios.
- `b18a59a` — corrected transaction/row source and proof ownership, removed unsupported pagination claims, and added source-drift negative controls.

**Plan metadata:** recorded in the summary commit.

## Files Created/Modified

- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-MAPPING-REVIEW.md` — final independent source/claim review for the exact `b18a59a` source revision.
- `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` — scenario, route-state, comparison-baseline, and brand-reference mappings.
- `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts` — semantic inventory contracts and mutation controls.
- `examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts` — local evidence contract additions.
- `examples/threadline_phoenix/DEMO-MANIFEST.md` and `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` — ordinary selection guidance and its source contract.

## Decisions Made

- Preserve #4521 as the ordinary scenario and use it only as a comparison baseline for named stress data.
- Keep the brand crosswalk tied to `brand/` authorities without copying token constants or claiming runtime migration.
- Keep requirement status partial: ADM-05 through ADM-07 remain pending phase-level verification, and ADM-06's descriptorless prohibition remains flagged-unverified.

## Verification Evidence

- `./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts` — 30 passed, 0 failed on source revision `b18a59a`.
- `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` — 10 passed, 0 failed in the example project.
- `ERL_FLAGS=+S4:4 DB_HOST=127.0.0.1 DB_PORT=60025 MIX_TEST_PARTITION=p24904 mix test test/threadline/operator_surface/operator_evidence_contract_test.exs` — 10 passed, 0 failed against the task-owned PostgreSQL 15.17 partition.
- Independent review — clean on `b18a59a`; all five changed-source digests matched. See [249-MAPPING-REVIEW.md](./249-MAPPING-REVIEW.md).

These checks cover local contracts and source mapping. No browser, visual, accessibility, hosted-CI, release, or human-acceptance result is claimed. The example lockfiles and dependency versions were preserved. No shared PostgreSQL service or public/runtime surface was changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added ordinary comparison baselines to the named stress scenarios.**

- **Found during:** Task 2 independent review.
- **Issue:** Stress populated-state entries did not consistently distinguish their own fixture from the ordinary #4521 example used for comparison.
- **Fix:** Linked each of the seven stress scenarios to #4521 as `comparison-only`, with matching ordinary source/proof ownership and validator controls.
- **Files modified:** `operator-journey-inventory.json`, `operator-route-evidence.test.ts`.
- **Verification:** Focused Node contract suite passed; the final independent report records M-02 resolved.
- **Committed in:** `da1f25e`.

**2. [Rule 1 - Bug] Grounded route states and populated claims in their actual implementation and test owners.**

- **Found during:** Task 2 independent review and follow-up source review.
- **Issue:** Transaction reads were attributed to the wrong callback, paging was overstated, row loading wording conflicted with its N/A state, and actor/action/sorted-value claims lacked their matching proof owners.
- **Fix:** Cited `mount/3` and the actual render branches, removed paging claims, linked separate actor/action and sorted-row owners, and bound validator rules to exact source/proof paths and locators.
- **Files modified:** `operator-journey-inventory.json`, `operator-route-evidence.test.ts`.
- **Verification:** Current focused Node suite passed 30/30; independent review closed M-01 and WR-01 on the same revision.
- **Committed in:** `da1f25e`, completed by `b18a59a`.

**Total deviations:** 2 auto-fixed (Rule 1: 2).
**Impact:** Corrections stayed within the approved mapping and verification scope; runtime code, brand assets, public APIs, and schemas were unchanged.

## Issues Encountered

During a stale second-round handoff, the executor inferred parent ownership from its local `/root` runtime role and started an overlapping independent review. The external parent remained active. Both source-bound finding sets were preserved and consolidated; the final report supersedes the premature M-01 closure, and the external-parent result protocol was restored before final confirmation. The parent recorded a durable ownership rule and explicit active-review acknowledgment for later handoffs. This did not authorize a new user gate or discard useful evidence.

One focused Node invocation failed to launch because of shell command-string quoting, and an early suite run caught misplaced row-source references. Both causes were corrected; the complete focused suite passed afterward. Every invocation and actual exit is preserved in the task-local invocation ledger. No unresolved implementation blocker remains.

## User Setup Required

None.

## Next Phase Readiness

Plan 249-04 is complete and ready for the parent-owned phase verification and shared-artifact reconciliation. The inventory is usable by later route, operations, and brand migration work. ADM-05, ADM-06, and ADM-07 remain addressed but not complete at phase level; in particular, ADM-06's descriptorless prohibition remains flagged-unverified. Later rendered acceptance remains with its owning phases.

---
*Phase: 249-map-jobs-scenarios-and-the-brand-contract*
*Summary authored: 2026-11-12*

## Self-Check: PASSED

- The summary and independent review report exist and contain no machine-local paths.
- All four measured production commits are ancestors of the current HEAD; the count from the dispatch-bound base is 4.
- The review result is clean for `b18a59a`, and all five changed-source digests match the readiness capsule.
- The focused coverage classifier reports all three deliverables auto-covered with no errors.
- The latest focused Node contract suite passed 30/30; the Task 1 and Task 2 focused ExUnit checks each passed 10/10.
