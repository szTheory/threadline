---
phase: 253-inclusive-integration-docs-package-and-release-readiness
plan: "01"
subsystem: testing
tags: [phoenix, retention, runner, readiness, controlled-clipboard]
requires:
  - phase: 252
    provides: "Accepted exact-target preview and typed-confirmation behavior"
provides:
  - "Runner-generated post-schema real-worker bootstrap with fail-closed readiness"
  - "Current mounted blank-confirmation/focus/cancel/touch proof against the owned store"
affects: ["253-02", "253-03", "253-09"]
tech-stack:
  added: []
  patterns: ["Execute the actual generated launch seam with prepared dependencies", "Separate runner delegation contracts from receipt ownership guards"]
key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/run-e2e.sh
    - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
key-decisions:
  - "Keep test.exs Retention disabled; enable the supervised worker only after migrated host startup"
  - "Ordinary paths leave confirmation empty and use controlled clipboard doubles before activity"
requirements-completed: [ADM-26, ADM-28, ADM-32, ADM-33]
requirements-partial: []
actuals:
  tokens: null
  executor_usage: null
  managed_executor_exit: 1
  tasks: 1
status: complete
completed: 2026-11-13
coverage:
  - id: runner-readiness
    description: "Generated actual launch starts the supervised exact Repo/schema/sleep worker and withholds browser execution for missing/mismatched readiness"
    verification:
      - kind: unit
        ref: "support/operator-evidence-manifest.test.ts#ordinary runner lifecycle forwards arguments and removes only ignored export files"
        status: pass
      - kind: integration
        ref: "threadline-253-pair-app-02.json and threadline-253-pair-after-start-materialization.json"
        status: pass
    human_judgment: false
  - id: mounted-safe-confirmation
    description: "Mounted preview, blank required submit, focus trap/return, cancellation and included375px touch path preserve the named persisted rows"
    verification:
      - kind: e2e
        ref: "operator-route-states.spec.ts#Retention confirmation focus and cancel preserve state; Chromium touch navigation works"
        status: pass
      - kind: integration
        ref: "threadline-253-pair-after-first-browser.json"
        status: pass
    human_judgment: false
---

# Plan01 — Worker-ready ordinary browser startup

**Final contribution:** independent goal verification passes5/5 roadmap truths and9/9 requirements with current required CI green. This plan contribution is complete at the named evidence boundaries. Historical pending checkpoints below preserve original failures and provenance; [final verification](253-VERIFICATION.md) and [CI results](253-CI-RESULTS.md) control the current result. REL-01 remains separate and no release/merge authority is inferred.

The existing runner now generates its final no-start Mix bootstrap after migration/reset, starts the real host app and supervised Pruner, verifies its exact target/options and seeded row invariance, and requires the validated readiness marker plus existing listener/VM/mount checks before browser execution. The disabled test default remains unchanged. Private Export housekeeping options preserve the seeded old running job; this is not default-cleanup proof.

## Actual proof

The changed lifecycle owner passes27 cases with no skips; missing/mismatched marker controls stop before npm test. The separate existing preview-receipt owner passes its4 pure receipt/process guards; its existing opt-in live-preview case remains skipped and is not claimed. The existing two root Retention owners pass56 tests. Exact generated Python and Elixir parse, then the generated launch and its actual validator execute against the owned p253pair store. Real worker snapshot is ThreadlinePhoenix.Repo/schema threadline/sleep0 under the library supervisor; all named audit/action/operation rows remain byte-identical to their pre-start snapshots:147transactions,239changes,3actions,5ExportJobs,4RetentionRuns.

The mounted desktop declaration passes1/1 with retries0/skips0/flakes0/unexpected0 and includes a375×900 controlled touch context. It observes ready preview, blank submit causing no run, actual initial focus/trap, Escape/Keep cancellation and return to persistent preview opener. Full named persisted row hashes remain unchanged after browser activity. GSD's required tracer feedback reran the same27/56/1 checks successfully before expansion. No native clipboard or full-browser/whole-root result is claimed.

Raw managed receipts and original logs retain basenames threadline-253-runner-contract-red-01, runner-contract-green-01/02, preview-stop-guards-01, retention-guards-01, bootstrap-parse-01, runner-preview-list-01, runner-preview-01 and tracer-*; app/row custody is in pair-app-01/02, pair-before-materialization, pair-after-start-materialization and pair-after-first-browser. These are private artifacts, not committed machine-local links.

## Task commits

- RED: fb0d2a48 — actual named target fails on observed phx.server argv versus the required generated Mix bootstrap.
- GREEN: 9887dc2e — runner bootstrap/marker, truthful CLI seam contracts and explicit selected local clipboard mode.

## Deviations and retained failures

The standalone executor again performed intake without source edits; its exit1, exact output-volume/runtime metrics and original log remain. Parent continues the same supported GSD worktree, with no replacement executor/research or renewed stopped window. The initial implementation attempt used a nested heredoc unsupported by the local shell parsing boundary; current quoted Python launch and generated Elixir both parse. Its failed full contract run also exposed an obsolete preview-stop fixture that always invoked a refusing fake validator while claiming actual ownership acceptance. The runner tests now assert truthful delegation/exit/state preservation, and the unchanged dedicated receipt tests exercise real positive/mismatched process/source/port/database guards. No production ownership check was removed.

The original intended RED is machine-classified RED_EVIDENCE_OK with one actual named assertion failure and no setup/parser error. Classification was recorded late, after the first unsuccessful implementation attempt, before any GREEN acceptance; this ordering deviation is retained rather than presented as an earlier gate. The first real startup reached its marker but the sandbox denied ps ownership inspection; the helper stopped only its own app. The second narrowly permitted startup passed. No browser ran against the failed startup.

## Limits and next action

This completes only the runner tracer. ADM-26/28/32/33 receive partial contributions; complete inclusive jobs, current inventories/package gates and required exact-candidate CI remain pending. No routine human UAT or new external authority follows. Continue253-02 in this same checkout. Independent source/security/UI review and final goal belong to253-10/11. Retained run retrospective remains in progress.

## Self-Check: PASSED

All required task and tracer checks have fresh successful receipts at the committed implementation bytes. No declared phase-wide requirement is marked complete here.

Duration from managed launch through parent continuation at summary: 25.1minutes; model token usage unavailable.
