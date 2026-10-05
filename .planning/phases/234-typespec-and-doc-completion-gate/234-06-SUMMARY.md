---
phase: 234-typespec-and-doc-completion-gate
plan: 06
subsystem: testing
tags: [elixir, dialyzer, typespecs, documentation, ci]
requires:
  - phase: 234-01
    provides: Exact documentation and spec contract gates and frozen rubric
  - phase: 234-02
    provides: Named facade option types and documentation baseline
  - phase: 234-03
    provides: Evidence specs and documented public surface
  - phase: 234-04
    provides: Operations and export specs
  - phase: 234-05
    provides: Typed schema and result data
provides:
  - Five strict Dialyzer warning flags enabled with zero findings and zero ignores
  - Zero-gap documentation/spec gates with ratchets removed
  - Generated exhaustive review input for the fresh-agent D-46 review
  - Green docs build, example verification, and aggregate CI
affects: [phase-234-verification, phase-235-stability-guide, phase-237-api-contract]
actuals:
  tokens: 47453
  tasks: 6
  commits: 7
  plan_head_before: e3ca403789b691452e5813d49d299a5cafaff027
  plan_head_after: 4fc4941b23ae9b190bea8971c551ab558f9a748e
tech-stack:
  added: []
  patterns:
    - Strict Dialyzer warning flags are pinned exactly by a contract test.
    - Documentation review input is rendered from Code.fetch_docs and Code.Typespec metadata.
key-files:
  created:
    - .planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW-INPUT.md
  modified:
    - mix.exs
    - test/support/doc_contract.ex
    - test/threadline/dialyzer_ignore_contract_test.exs
    - test/threadline/doc_spec_coverage_contract_test.exs
    - test/threadline/doc_rubric_contract_test.exs
    - test/threadline/source_size_contract_test.exs
    - lib/threadline.ex
    - lib/threadline/investigation.ex
    - lib/threadline/query.ex
    - lib/threadline/query/cursors.ex
    - lib/threadline/query/transaction_lookup.ex
    - lib/threadline/export.ex
    - lib/threadline/query/export_reads.ex
    - lib/threadline/evidence/proof.ex
    - lib/threadline/operator_surface/presentation.ex
    - lib/threadline/critic_trust/ledger_splice.ex
    - lib/threadline/health/legacy_key_findings.ex
    - lib/threadline/health/trigger_findings.ex
    - lib/threadline/operator_surface/live/stress_live.ex
    - lib/threadline/storage_schema.ex
    - CHANGELOG.md
    - CONTRIBUTING.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - .planning/phases/234-typespec-and-doc-completion-gate/234-RESEARCH.md
key-decisions:
  - "Kept the five strict Dialyzer flags exact and fixed measured findings through accurate return specs; no ignores or @dialyzer attributes were added."
  - "Kept new no_return() annotations on private raise-only helpers. The pre-existing exported RepositoryBoundary.task_error!/3 remains outside the approved edit scope and leaves D-28's plan-wide wording unresolved."
  - "Used a generated review dump as D-46 input; the executor did not grade the docs."
patterns-established:
  - "The documentation and spec gates assert zero gaps without transitional ratchets."
  - "Dialyzer warning configuration is guarded against prohibited :no_* flags and inexact flag sets."
requirements-completed: [SPEC-01, SPEC-03]
coverage:
  - id: D1
    description: Five strict Dialyzer flags are enabled and their measured findings are fixed without ignores.
    requirement: SPEC-02
    verification:
      - kind: integration
        ref: "MIX_ENV=dev mix dialyzer --no-check --missing_return --underspecs --error_handling"
        status: pass
      - kind: unit
        ref: "test/threadline/dialyzer_ignore_contract_test.exs"
        status: pass
    human_judgment: true
    rationale: "D-28's plan-wide no_return wording has one pre-existing exported bang-function exception outside the authorized file list; see the unresolved criterion below."
  - id: D2
    description: Documentation/spec coverage and rubric gates assert zero findings after ratchet removal.
    requirement: SPEC-01
    verification:
      - kind: unit
        ref: "mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs"
        status: pass
      - kind: integration
        ref: "live mutation: remove Threadline.timeline/2 @spec, observe named failure, restore and pass"
        status: pass
    human_judgment: false
  - id: D3
    description: Docs, example app, and aggregate CI complete successfully; D-46 review input is generated.
    verification:
      - kind: integration
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
      - kind: integration
        ref: "mix verify.example"
        status: pass
      - kind: integration
        ref: "HEX_HOME=/tmp/threadline-hex-234-06 NPM_CONFIG_CACHE=/tmp/threadline-npm-cache-234-06 PLAYWRIGHT_BROWSERS_PATH=/tmp/threadline-playwright-browsers-234-06 mix ci.all"
        status: pass
    human_judgment: false
duration: 71min
completed: 2026-10-05
commits: 7
plan_head_before: e3ca403789b691452e5813d49d299a5cafaff027
plan_head_after: 4fc4941b23ae9b190bea8971c551ab558f9a748e
status: halted
---

# Phase 234 Plan 06: Typespec and Doc Completion Gate Summary

**The five strict Dialyzer flags now run at zero findings, the docs/spec gates have no ratchets, and the docs, example, and full CI aggregate pass.**

## Performance

- **Duration:** 71 minutes
- **Started:** 2026-10-05T14:32:17Z
- **Completed:** 2026-10-05
- **Tasks:** 6/6
- **Files modified:** 29 across the seven task commits

## Accomplishments

- Enabled exactly `[:unmatched_returns, :extra_return, :missing_return, :underspecs, :error_handling]`; the full strict Dialyzer run reports zero errors, `.dialyzer_ignore.exs` remains empty, no `@dialyzer` was introduced, and the sealed slice remains warning-free.
- Removed doc/spec ratchet machinery and set the affected gates to zero findings. The measured coverage note is 54 of 92 visible entries across 52 documented modules at the 233 close; the older 129 of 169 figure predates phases 231–233.
- Generated [234-REVIEW-INPUT.md](./234-REVIEW-INPUT.md) from `Threadline.DocContract.review_dump/0`. It includes visible docs/specs/types, moduledoc summaries, hidden-pin reasons, and permanent bare-type rules; the fresh-agent review remains the D-46 verifier's task.
- `MIX_ENV=dev mix docs --warnings-as-errors`, `mix verify.example`, and the final cache-isolated `mix ci.all` exited 0.

## Strict Dialyzer Findings and Fixes

Initial amended-scope baseline: 20 findings, all in the approved file cohorts. They were fixed without changing runtime behavior.

| Finding class | Module/function | Task | Fix |
|---|---|---:|---|
| `missing_range` | `Threadline.row_history/4`, `Threadline.row_history_page/4`, `Threadline.actor_window_page/3`, `Threadline.correlation_bundle_page/3` | 1 | Corrected deprecated facade return ranges to match their actual values. |
| `missing_range` | The same four delegates in `Threadline.Investigation` | 1 | Corrected delegate return ranges. |
| `missing_range` | `Threadline.Query.preload_investigation_context/3` | 1 | Corrected the return range. |
| `contract_supertype` | `Threadline.Query.Cursors.validate_actor_history_page_cursor!/1`, `validate_page_cursor!/1` | 1 | Narrowed specs to actual accepted/returned shapes. |
| `missing_range` | `Threadline.Evidence.Proof.request_subject_ref/1` | 2 | Corrected its spec to the actual subject-reference values. |
| `contract_supertype` | `Threadline.OperatorSurface.Presentation.kinds/0`, `export_readiness_rank/2` | 3 | Narrowed specs to implementation behavior. |
| `contract_supertype` | `Threadline.CriticTrust.LedgerSplice.replace/2`, `replace_provenance/2` | 3 | Narrowed specs to implementation behavior. |
| `no_return` | `Threadline.Health.LegacyKeyFindings.invalid_schema!/1`, `Threadline.Health.TriggerFindings.invalid_schema!/1` | 3 | Added private helper `no_return()` specs. |
| `no_return` | `Threadline.OperatorSurface.Live.StressLive.invalid_ledger_session!/0` | 3 | Added a private helper `no_return()` spec. |
| `no_return` | `Threadline.StorageSchema.invalid_identifier!/3` | 3 | Added a private helper `no_return()` spec. |

Task 2 confirmed `Threadline.Query.TransactionLookup`, `Threadline.Export`, and `Threadline.Query.ExportReads` were already clean under the strict flags. Task 4 pinned the exact flag set and verified zero errors. Tasks 1–3 kept `mix.exs` unchanged until that point.

**D-28 unresolved criterion:** Every new `no_return()` spec from this plan belongs to a private raise-only helper. However, `Threadline.CriticTrust.RepositoryBoundary.task_error!/3` has a pre-existing `@spec ... :: no_return()` and is an exported function in an `@moduledoc false` internal module, used by the Mix task. The plan criterion says no public bang function may have `no_return()`. This module was not named by the strict finding baseline and is outside the amended `files_modified` authorization, so it was not edited. The strict run is green, but the literal plan-wide D-28 criterion is not fully satisfied; this summary does not claim otherwise.

## Documentation Gates and Live Mutation

The coverage, parity, rubric M-checks, hidden/typep-reference, and bare-type gates assert zero findings after removing ratchets. The permanent bare-type allowlist remains closed and each entry retains its rule. The hidden pin is exact and its eight newly hidden entries are recorded in the changelog. `lib/threadline.ex` is pinned to its measured final line count (1351).

The live mutation was performed and restored:

1. Removed the real `@spec` for `Threadline.timeline/2`.
2. Ran `mix test test/threadline/doc_spec_coverage_contract_test.exs`: exit 2; 5 tests, 1 failure, naming `Threadline.timeline/2  missing @spec`.
3. Restored the spec and reran the same command: 5 tests, 0 failures.

`CHANGELOG.md` has the required aggregate Changed line about named types and Dialyzer users. `CONTRIBUTING.md` identifies the two doc/spec contract tests and says `mix verify.test` and `mix ci.all` run them. ROADMAP and REQUIREMENTS retain their original SC text and add the 54-of-92 remeasurement note. Username and absolute-home path checks passed.

## Hidden Surface and Follow-on Handoffs

Modules hidden since the old 129/169 measurement and their decisions:

- `Threadline.Query` and `Threadline.Investigation`: hidden implementation modules behind the facade-only API (Phase 231-02). Their old page types were replaced by `Threadline.Page` in Phase 232; other result types remain visible.
- `Threadline.Query.TransactionLookup`: hidden lookup implementation module introduced in Phase 233-01 to centralize transaction lookup behavior.

Phase 235 stability-guide handoff (D-51): option `@type` names are guaranteed in 1.x; option lists are additive; spec-only changes follow the minor/patch policy with a changelog note; spec narrowings that may create adopter Dialyzer warnings also receive a note.

Phase 237 API-contract handoff (D-53): the eight newly hidden functions are `Threadline.StorageSchema.quote_ident/1`, `qualify/2`, `function/2`, `parse_table_identifier/1`, `qualified_host_table/1`, `host_table_suffix/1`, `Threadline.Evidence.Proof.present_record/1`, and `record_claim_assessment/1`. Keep the closed allowlists closed, and include the Dialyzer note as an unnumbered Notes item.

## Verification

- Focused contract tests: 98 tests, 0 failures; `mix verify.credo` passed with zero issues.
- Live mutation check: red with the named missing `@spec`, then green after restoration.
- `MIX_ENV=dev mix docs --warnings-as-errors`: exit 0.
- `HEX_HOME=/tmp/threadline-hex-234-06 mix verify.example`: exit 0, 130 tests, 0 failures.
- Final aggregate command: `HEX_HOME=/tmp/threadline-hex-234-06 NPM_CONFIG_CACHE=/tmp/threadline-npm-cache-234-06 PLAYWRIGHT_BROWSERS_PATH=/tmp/threadline-playwright-browsers-234-06 mix ci.all`: exit 0. Root suite: 32 properties, 2,986 tests, 0 failures, 3 excluded. Example suite: 130 tests, 0 failures. Strict Dialyzer: 0 errors. Dialyzer slice: 17 tests, 0 failures. Browser projects: 316 passed, 26 skipped, 2 flaky tests passed on retry.
- The final browser run used isolated HEX, npm, and Playwright caches under `/tmp`; temporary Chromium setup succeeded. Earlier sandbox attempts hit cache permission errors and read-only `.git/worktrees` access; the escalated run with temporary cache paths passed.

## Task Commits

1. **Task 1: Facade/query strict Dialyzer cohort** — `daae9752`
2. **Task 2: Lookup/export/proof return-range cohort** — `70766417`
3. **Task 3: Operator/critic/private raise-only helper cohort** — `6a808f03`
4. **Task 4 RED: Pin strict warning flags in a failing contract test** — `9354b60b`
5. **Task 4 GREEN: Enable exact strict warning flags** — `c81ee2b6`
6. **Task 5: Remove ratchets and complete doc/spec gates** — `2f3afdf4`
7. **Task 6: Add exhaustive review input** — `4fc4941b`

## Decisions Made

- Kept the approved five-file expansion to the strict-Dialyzer findings named by the measured run; no finding outside the amended scope required an edit.
- Left `RepositoryBoundary.task_error!/3` untouched because changing its spec or visibility would cross the authorized file scope. This is the sole unresolved plan-wide criterion noted above.
- Reran aggregate CI with temporary cache locations after sandbox cache permissions prevented the default run from completing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Removed absolute paths from the phase research artifact after repository hygiene rejected it.**
- **Found during:** Task 6 aggregate CI.
- **Issue:** `mix ci.all` repository-hygiene check rejected absolute paths in `234-RESEARCH.md`.
- **Fix:** Replaced machine-specific absolute citations with repository-relative paths.
- **Files modified:** `.planning/phases/234-typespec-and-doc-completion-gate/234-RESEARCH.md`.
- **Verification:** Hygiene path scan and final `mix ci.all` passed.
- **Committed in:** `4fc4941b`.

**2. [Rule 1 - Bug] Refined the generated review dump helper to satisfy strict Credo checks.**
- **Found during:** Task 6.
- **Issue:** Initial implementation triggered Credo style findings.
- **Fix:** Simplified rendering with `Enum.map_join/3` and extracted typedoc lookup into a helper.
- **Files modified:** `test/support/doc_contract.ex`.
- **Verification:** `mix verify.credo` passed with zero issues.
- **Committed in:** `4fc4941b`.

**Total deviations:** 2 auto-fixed issues. Both were necessary to pass the plan's repository quality gates.

## Next Phase Readiness

The D-46 review input is ready for fresh-agent review, and phase 235 can use the D-51 stability-policy handoff. All six tasks and their verification ran, but this plan remains **incomplete** because its plan-wide D-28 criterion is unresolved: the pre-existing exported bang-function spec is outside the amended file scope. Do not advance SPEC-02 or mark this plan complete until the maintainer resolves that scope conflict. The orchestrator should restore the temporary `workflow.use_worktrees=false` setting and dispatch-isolation sentinel to their prior values after execution.

## Self-Check: PASSED

- Summary file exists.
- All seven task commit hashes above exist in Git history.
- `plan_head_before` to `plan_head_after` measures seven plan task commits.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-05*
