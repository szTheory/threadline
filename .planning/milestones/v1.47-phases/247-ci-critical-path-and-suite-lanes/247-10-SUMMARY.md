---
phase: 247-ci-critical-path-and-suite-lanes
plan: 10
subsystem: ci
tags: [github-actions, matrix, playwright, fan-in, operator-evidence, supply-chain]
status: complete

requires:
  - "247-08 (CI-01 observation: per-leg timeout inputs, split design numbers)"
  - "247-09 (N-file receipt CLI under plain node; matrix-aware bin/browser-full-projects)"
provides:
  - "D-07: verify-example-browser (id unchanged) is a fail-fast: false matrix on project [desktop-chromium, mobile-chromium], static name `Example app browser E2E`, posting `Example app browser E2E (desktop-chromium)` and `Example app browser E2E (mobile-chromium)`"
  - "D-07a: verify-example-browser-receipt (`Browser journey receipt`) fan-in: needs the legs, no if:, two same-run download-artifact v8.0.2 steps, plain-node N-file reconcile, receipt artifact operator-ci-evidence-<run_id>; in ci-required needs with no allowed-skips"
  - "D-07c: per-leg Playwright step 9 min < job 12 min, arithmetic in the ci.yml comment; maxFailures: 5 noted as per leg"
  - "Contracts moved atomically: composed check names per axis, retired `(2 projects)` name, exact-list needs exemption, 14 job ids, time-to-red order, per-leg literals, matrix-list mutation anchors, node24 entry for download-artifact v8"
affects: ["247-11 (non-vacuous split assertions + full CI=true mix ci.all gate)", "247-13 (Land B2; first live split runs, possible actions: read grant)"]

actuals:
  tokens: 11700    # chars/4 over the realized diff (git diff 6211285a..e8df648b)
  tasks: 2
  commits: 1
plan_head_before: 6211285a077e13a9be51c1491e4bed053c06c75d
plan_head_after: e8df648b2a70835074f46277459a4a5a5e657b44

tech-stack:
  added:
    - "actions/download-artifact@9000827ccba6bdab643e8b6fd33ac0654aef8333 # v8.0.2 (node24)"
  patterns:
    - "A matrix job's posted check names are composed from (static name, one base axis); the parity contract's composed_check_names/2 and posted_lanes/2 take the axis as a parameter and keep their fail-closed :error fallbacks"
    - "Fan-in over matrix legs: per-leg artifacts carry the matrix value in both artifact and file name, the fan-in downloads by two disjoint patterns with merge-multiple, and fails on zero files"

key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-10-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/threadline/browser_journey_evidence_contract_test.exs
    - test/threadline/browser_full_projects_contract_test.exs
    - test/threadline/ci_action_runtime_contract_test.exs
    - CONTRIBUTING.md
    - examples/threadline_phoenix/e2e/playwright.config.ts

key-decisions:
  - "247-10: the receipt job uses a plain shallow checkout with persist-credentials: false, not the planned sparse checkout. The toolchain source rule in ci_workflow_parity_contract_test treats every sparse checkout as the `.tool-versions`-only pin shape; widening that rule would loosen an existing contract, and a depth-1 checkout costs seconds."
  - "247-10: the fan-in reconcile step reads the legs directory through an env var (LEGS_DIR) and builds --discovered/--executed args with a nullglob bash loop that exits 1 when either glob is empty."
  - "247-10: the needs exemption is a module attribute @needs_exemptions compared with List.wrap/1, so the scalar `needs: verify-example-browser` equals the one-element list and any other value (or any other job's needs) still reports rule=order-needs."
  - "247-10: the ci-required header comment says thirteen jobs, and the ci.yml top-of-file job-id list includes verify-example-browser-receipt (the header-comment parity test requires it)."

patterns-established:
  - "@composed_name_jobs lists {job id, base axis, exact composed names}; name_static_errors/2 iterates it, so a future matrix job adds one row"

requirements-completed: []  # CI-02 completes after 247-11's gate and the live split runs (247-13)

coverage:
  - id: D1
    description: "Matrix legs + fan-in receipt in ci.yml with every pinned literal, roster and doc moved in one commit"
    requirement: CI-02
    verification:
      - kind: unit
        ref: "mix test ci_topology + ci_workflow_parity + browser_journey_evidence + browser_full_projects + ci_coverage_doc + ci_action_pin + ci_action_runtime + ci_token_permissions + repo_contract_scope contracts (213 tests, 0 failures, ephemeral postgres:16)"
        status: pass
      - kind: unit
        ref: "bin/browser-full-projects --list ci prints `desktop-chromium mobile-chromium` on the split tree"
        status: pass
      - kind: unit
        ref: "20 further CI-adjacent contract files (ci_sha_gate, main_ci_observer, measure_main_ci, playwright_fail_fast, verify_action_pins, release_ci_gate, zero_skips, source_size, ...): 317 tests, 0 failures"
        status: pass
      - kind: lint
        ref: "actionlint .github/workflows/ci.yml exit 0; mix format --check-formatted; mix credo --strict on the edited test files; bin/verify-repo-hygiene exit 0"
        status: pass
  - id: D2
    description: "Supply-chain provenance for the new download-artifact pin"
    requirement: CI-02
    verification:
      - kind: unit
        ref: "bin/verify-action-pins exit 0: `verify-action-pins: 9 pin(s) match their tags` (8 distinct pins before this plan; the 9th is actions/download-artifact v8.0.2 9000827ccba6bdab643e8b6fd33ac0654aef8333)"
        status: pass

metrics:
  duration: "~45 min"
  completed: 2026-10-26
---

# Phase 247 Plan 10: Browser E2E split per Playwright project with a receipt fan-in Summary

`verify-example-browser` now runs as two parallel matrix legs, one per CI Playwright project. A new `verify-example-browser-receipt` job downloads both legs' evidence and reconciles every required operator journey in one receipt. Every contract, roster and doc that pinned the old single-job shape moved in the same commit.

## What changed

**ci.yml, `verify-example-browser`** (job id unchanged):
- `name: Example app browser E2E`, `strategy.fail-fast: false`, `matrix.project: [desktop-chromium, mobile-chromium]`, with a comment explaining how the base axis composes the check-name suffix (the verify-test precedent).
- Timeouts from 247-OBSERVATION.md "CI-02 split design inputs": `Run example Playwright suite` step 9 min, job 12 min. The comment shows the arithmetic (365 s projected / 389 s worst-case leg step; 540 s step + 62 s setup + ~60 s upload = 662 s < 720 s) and the 450 s re-raise trigger. It also says `maxFailures: 5` now applies per leg.
- The legs run `mix verify.example_browser --project=${{ matrix.project }}` and `playwright test --list --project=${{ matrix.project }}`. File and artifact names carry the project: `operator-ci-executed-<project>-<run_id>`, `operator-ci-discovered-<project>-<run_id>`, `browser-timings-<project>-<run_id>` (slow-specs `--label <project>`), and `example-browser-e2e-diagnostics-<project>`.
- The leg no longer reconciles. It uploads its executed report and discovered list (v7.0.2, `if-no-files-found: error`, 14 days).
- The cache save stays unguarded by leg.

**ci.yml, `verify-example-browser-receipt`** (new, placed directly after the legs): `name: Browser journey receipt`, `needs: verify-example-browser`, `timeout-minutes: 5`, no `if:`. It runs checkout, `setup-node` (no cache), and two `actions/download-artifact@9000827… # v8.0.2` steps (`operator-ci-executed-*-<run_id>`, `operator-ci-discovered-*-<run_id>`, `merge-multiple: true`, into `<runner.temp>/legs`). Next comes a nullglob arg-building loop that fails on zero files, then `node --experimental-strip-types support/operator-ci-evidence.ts --verify` and the `operator-ci-evidence-<run_id>` receipt upload. The job is in `ci-required.needs` with no `allowed-skips`. The "twelve" comments now say "thirteen".

**Contracts:**
- `ci_workflow_parity_contract_test`: `@ci_check_names` (browser → `Example app browser E2E`, receipt → `Browser journey receipt`), new `@verify_example_browser_check_names` and `@composed_name_jobs`, and the retired `Example app browser E2E (2 projects)`. Also `@needs_exemptions` (exact list) in `order_needs_errors/1`, `@ci_job_ids` 13 → 14, and `@time_to_red_order` with the receipt after the browser job. `composed_check_names/2`, `posted_lanes/2` and `matrix_row_lanes/3` take the axis, and the `:error` fallbacks are unchanged. `name_static_errors/2` and `posted_check_names/2` gain the browser clause, and the browser fixture moved to the matrix shape.
- `browser_journey_evidence_contract_test`: the leg literals are now in their `${{ matrix.project }}` forms with the per-leg artifact names. The reconcile, download-pattern and receipt assertions moved to the receipt job block. The timings rules and their mutations use the per-leg names, and `browser_job_block` stops at the receipt job.
- `browser_full_projects_contract_test`: the old literal-flag anchors now mutate the matrix list (drop mobile, add route-capture, 9-min step anchor, backslash-continued matrix flag). The 247-09 matrix block now rewrites the live inline list; its "no strategy.matrix" control removes the live strategy block.
- `ci_action_runtime_contract_test`: `{"actions/download-artifact", "v8"} => :node24` (action.yml at the pin reads `using: 'node24'`).

**Docs:** in CONTRIBUTING, the branch-protection roster now lists the two composed names plus the receipt, and the `ci-required` needs roster gains the receipt. The CI Coverage text explains the legs and the receipt, and the job-key table has a receipt row. playwright.config.ts gets the per-leg `maxFailures` note, with `workers: 1` unchanged.

## Task 2: provenance

`bin/verify-action-pins` (read-only GitHub API) exited 0 with `verify-action-pins: 9 pin(s) match their tags`. HEAD~1 had 8 distinct pins, so the 9th, `actions/download-artifact v8.0.2 9000827ccba6bdab643e8b6fd33ac0654aef8333`, is verified. A direct `gh api repos/actions/download-artifact/git/ref/tags/v8.0.2` also resolved to that commit. No file changed, so there is no Task 2 commit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Receipt job checkout is shallow, not sparse**
- **Found during:** Task 1 (contract run)
- **Issue:** The toolchain source rule (`toolchain_source_errors/3`) requires every sparse `actions/checkout` to be the `.tool-versions`-only pin: `sparse-checkout: .tool-versions`, `sparse-checkout-cone-mode: false`, `persist-credentials: false`. The planned `sparse-checkout: examples/threadline_phoenix/e2e/support` failed three assertions. A non-cone sparse checkout with both paths would still fail the exact-line check.
- **Fix:** A plain depth-1 checkout with `persist-credentials: false`. The contract is unchanged, and the ci.yml comment records why.
- **Files modified:** .github/workflows/ci.yml
- **Commit:** e8df648b

**2. [Rule 3 - Blocking] ci.yml header job-id list**
- **Found during:** Task 1
- **Issue:** The header-comment parity test requires the top-of-file job-id list to equal the jobs.
- **Fix:** Added `verify-example-browser-receipt` to the header list. CONTRIBUTING's job-key table got its row.
- **Commit:** e8df648b

**3. [Rule 1 - Bug] Identity control in the 247-09 matrix block**
- **Found during:** Task 1
- **Issue:** With the live tree already in matrix form, `to_matrix_form/1` with the default list returned the input unchanged, and `mutated_root` correctly rejects a no-op control.
- **Fix:** That test now runs against the live root. It asserts `to_matrix_form(live) == live` and that the live strategy/inline-matrix anchors are present.
- **Commit:** e8df648b

**Scope note:** the commit touches 7 files, not 9. `ci_topology_contract_test.exs` and `ci_coverage_doc_contract_test.exs` were "update only if pinned" and needed no change: their browser pins are the `mix.exs` ci.all alias and the project table, and both stayed green.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register. T-247-21 is still open by design: if the first live run returns 403 on the same-run download, 247-13 adds a job-scoped `actions: read` with a `@job_read_grants` entry.

## Next

247-11 adds the mutation-controlled split assertions (matrix == votingProjects, the exact needs exemption control, receipt-unconditional, matrix-fail-fast, leg-artifact-name) and runs the full `CI=true mix ci.all` gate.

## Self-Check: PASSED
- FOUND: .github/workflows/ci.yml (`verify-example-browser-receipt:` x1, `- verify-example-browser-receipt` x1, download-artifact v8.0.2 pin x2, retired name x0 in non-comment lines and in CONTRIBUTING, literal `--project=desktop-chromium --project=mobile-chromium` x0)
- FOUND: commit e8df648b on HEAD
