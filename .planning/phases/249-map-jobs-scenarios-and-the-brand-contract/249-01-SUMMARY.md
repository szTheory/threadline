---
phase: 249-map-jobs-scenarios-and-the-brand-contract
plan: "01"
subsystem: admin-inventory
tags: [phoenix-liveview, route-inventory, operator-surface, proof-ownership]
requires: []
provides:
  - "A source-grounded map for eleven LiveViews, five HTTP seams, and five shared resources"
  - "Focused declaration and semantic-inventory contracts with adversarial mutation controls"
affects: [249-02, 249-03, 249-04]
actuals:
  tokens: 191945
  reasoning_output_tokens: 122071
  worker_elapsed_s: 3908
  measurement_source: codex-exec-terminal-usage
  tokens_meaning: output_tokens_including_reasoning
  tasks: 2
  commits: 4
plan_head_before: fc6afadfcb0634f5df78e52e52d5220e08ef420c
plan_head_after: dd6bd58b561e4b32e32de97c2494d011cdc75974
tech-stack:
  added: []
  patterns:
    - "Stable semantic surface identities reconcile to independently declared router paths"
    - "Proof references state ownership and limitations separately from execution receipts"
key-files:
  created:
    - .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-01-01-red-evidence.json
    - .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-01-02-red-evidence.json
  modified:
    - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
    - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
    - examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts
key-decisions:
  - "Keep the existing inventory and structural fixture as the only registries; reconcile eleven LiveViews and five independently discovered HTTP declarations by stable IDs."
  - "Keep transaction and drawer routes separate when they share TransactionLive, and preserve all existing voting rows and reasons."
  - "Record authentication, surface capability, organization scope, support disposition, and no-page HTTP behavior as separate facts."
  - "Treat E2E and source-contract references as proof owners with explicit limitations; no browser or visual acceptance is claimed."
  - "Record brand assets, embedded fonts, conditional PhoenixStorybook, HelpDesk writes, and mailbox preview as shared resources or dev tools, not user jobs."
requirements-completed: [ADM-05]
coverage:
  - id: D1
    description: "The Acme #4521 Home-to-Timeline-to-transaction-to-row-history route slice has source, actor, correlation, dynamic record, and return-context references."
    requirement: ADM-05
    verification:
      - kind: unit
        ref: "tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts"
        status: pass
    human_judgment: false
  - id: D2
    description: "All declared LiveView and HTTP surfaces have job/action/state owners, access boundaries, eight U1 dispositions, and resource references."
    requirement: ADM-05
    verification:
      - kind: unit
        ref: "tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/operator_surface/operator_evidence_contract_test.exs"
        status: pass
    human_judgment: false
duration: 65min8s
completed: 2026-11-11
status: complete
---

# Phase 249 Plan 01: Map jobs, scenarios, and the brand contract Summary

**Acme #4521 source-backed investigation links and a 16-surface Admin inventory with separate access boundaries, proof-owner limits, and eight U1 state categories.**

## Performance

- **Duration:** Worker lifetime 3,908 seconds (65 minutes 8 seconds), measured by the managed launcher. Worktree creation and dependency cloning preceded worker launch and are excluded.
- **Started:** 2026-11-12T00:18:21.242413+00:00 (worker launch).
- **Completed:** 2026-11-12T01:23:29.235458+00:00 (worker terminal exit).
- **Tasks:** 2
- **Files modified:** 5, including two RED-evidence records
- **Task commits:** 4 (two RED/GREEN pairs)

## Accomplishments

- Mapped all eleven LiveViews and five HTTP seams (theme POST, CSV, JSON, NDJSON, and completed-job download) in the existing semantic inventory. All routes have stable identities, job/action/state descriptions, production source locators, proof-owner references, and access facts.
- Kept transaction and transaction-history drawer as separate routes sharing `TransactionLive`. The Acme #4521 chain retains the seeded actor and correlation, dynamically resolved `ticket_replies` record ID, and origin-specific return context.
- Added eight U1 state dispositions per surface, including empty, loading, error, populated, partial, overflow, zero/one/many, and long-text/Unicode cases. HTTP endpoints carry explicit no-page-renderer reasons.
- Added explicit dispositions for shared brand assets, embedded fonts, conditional PhoenixStorybook, example HelpDesk writes, and mailbox preview. Runtime assets, fonts, public APIs, schemas, and rendered behavior were not changed.
- Strengthened the existing reconciler to check all 16 declaration identities, route patterns and HTTP method/path pairs, renderer/source/proof locators, support dispositions, U1 coverage, the degraded Timeline state, and resource references. Mutation checks cover missing and duplicate IDs, reordered inputs, bad locators, wrong access, missing U1 coverage, and invalid resource references.
- Preserved the 34 existing voting rows, voting project identities, nonvoting reasons, the structural route fixture, and the source-surface checklist.

## Task Commits

1. **Task 1 RED:** `cb221f6e` — `test(249-01): add failing investigation inventory contract`
2. **Task 1 GREEN:** `88d7ab97` — `feat(249-01): map the Acme 4521 investigation route slice`
3. **Task 2 RED:** `6dce9221` — `test(249-01): require all operator declaration identities`
4. **Task 2 GREEN:** `dd6bd58b` — `feat(249-01): map all operator surfaces and state owners`

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-01-01-red-evidence.json` — validated RED evidence for the investigation route contract.
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-01-02-red-evidence.json` — validated RED evidence for all 16 declaration identities.
- `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` — route, job, action, state, access, proof-owner, and resource mapping.
- `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts` — semantic reconciliation and adversarial mutation contracts.
- `examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts` — preserved and extended the RED-evidence contract from Task 1.

## Verification and Invocation Log

- `npm ci` in the E2E project completed successfully; the package lock remained unchanged.
- Task 1 RED Node contract exited 1 on the intended missing-investigation assertion (22/23 passed). The first evidence classification rejected the escaped `#` spelling; the target name was corrected to match TAP output and the classifier returned `RED_EVIDENCE_OK`.
- Task 1 GREEN Node contracts exited 0 (23/23).
- Task 2 RED Node contract exited 1 on the intended missing-surface assertion (23/24 passed); `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Task 2 GREEN attempts 1 and 2 exited 1 (23/25) because two owner locators named the wrong E2E files. Attempt 3 also exited 1: a correction script ran from the E2E directory with a root-relative path, so it wrote nothing and the previous locator failures remained. The paths were corrected from the repository root.
- The next GREEN Node invocation exited 0 (25/25), followed by a final post-action-map invocation that also exited 0 (25/25). Both ran `tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts`.
- The root source contract passed twice: `mix test test/threadline/operator_surface/operator_evidence_contract_test.exs` reported 10 tests, 0 failures. The final run verified the live-evidence flags were unset and confirmed the task-owned PostgreSQL instance at `127.0.0.1:60025`, version 15.17, capacity 100, partition `p24901`, with `ERL_FLAGS=+S4:4`.
- One final preflight assertion exited 2 before tests because it compared the server version without the ` (Homebrew)` suffix. After matching the full version string, preflight and the root contract passed. No test ran during the failed preflight.
- `gsd_run check evaluation-scope --plan "249-01" --commits-only --raw` resolved all four task commits. The final self-check confirmed all expected files exist, each task commit is an ancestor of HEAD, and the worktree is clean.

The task-owned PostgreSQL receipt also recorded earlier setup stops due to shared-memory attachment and slot availability, a connection attempt without a password, and later successful owner-scoped connection/capacity checks. The recovery only touched the task-owned unattached segment; no shared database or service was stopped or changed.

## Decisions Made

- Semantic route identity is reconciled independently against the structural fixture and router declarations; the inventory remains the single existing semantic map.
- Proof locators identify owners and preserve their limitations. Passing source contracts prove the mapping and declarations, not fresh browser, accessibility, or visual behavior.
- Support read access does not imply export, evidence, coverage, policy, or retention permission; host authentication, surface capability, and organization scope remain separate fields.

## Parent Receipt Reconciliation

After terminal exit, the parent replaced estimated duration/token metrics with the managed worker receipt and corrected the next inventory owner to Plan 04. Task source and passing checks are unchanged; no new runtime receipt is implied.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- Early Node RED evidence needed TAP-normalized test naming; corrected evidence passed the classifier.
- Initial GREEN runs exposed stale E2E owner paths; corrected references and reran the focused contracts successfully.
- The first final PostgreSQL identity comparison was too strict about the version suffix; corrected the preflight check before rerunning the contract.
- No runtime, package, schema, or public API issue remained.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 04 can extend this same inventory. The mapped proof references remain ownership links only; later plans retain responsibility for scenario and rendered acceptance.

## Self-Check: PASSED

- All five plan-owned changed files exist.
- All four task commits are present on this branch and precede the summary commit.
- Focused Node and root source contracts passed; no shared planning files were edited.

---
*Phase: 249-map-jobs-scenarios-and-the-brand-contract*
*Completed: 2026-11-11*
