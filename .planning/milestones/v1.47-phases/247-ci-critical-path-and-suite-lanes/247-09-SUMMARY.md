---
phase: 247-ci-critical-path-and-suite-lanes
plan: 09
subsystem: ci
tags: [playwright, operator-evidence, browser-full, github-actions, matrix, node]
status: complete

requires:
  - "247-07 (test:unit wiring and Node-running test tagging)"
provides:
  - "D-07a: operator-ci-evidence.ts --verify inventory --discovered <f>... --executed <f>... receipt (repeatable, node:util parseArgs, flatMap concat, per-file MAX_REPORT_BYTES cap); legacy 4-positional form kept"
  - "D-07a: the receipt script runs under plain node --experimental-strip-types (node:* imports only), so the fan-in job needs no npm ci"
  - "D-07 / Pitfall 1: bin/browser-full-projects resolves --project=${{ matrix.project }} from the enclosing job's strategy.matrix.project list and fails closed on everything else"
affects: ["247-10 (matrix split of verify-example-browser + fan-in receipt job)"]

actuals:
  tokens: 7600
  tasks: 2
  commits: 2
plan_head_before: be29f3c70b449050dae9fd1c723fd6c18e008a13
plan_head_after: a209ccbef0db37e85f7f9ab669e653fb9ae4307b

tech-stack:
  added: []
  patterns:
    - "The receipt CLI is tested by spawning the real script under plain node --experimental-strip-types (NODE_OPTIONS cleared), so the tests also prove the no-tsx runnability"
    - "Workflow matrix values are read by a small indentation-based mapping_entry/2 text parse, with no YAML library"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts
    - examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts
    - bin/browser-full-projects
    - test/threadline/browser_full_projects_contract_test.exs

key-decisions:
  - "247-09: the receipt picks its form from whether any argument after --verify starts with --. The flag form needs exactly two positionals (inventory, receipt) and at least one --discovered and one --executed. parseArgs runs with strict: true, so unknown options are usage errors."
  - "247-09: bin/browser-full-projects fails closed when matrix include:/exclude: rows name a project at all, not only when project is include-only. Those rows can add or remove legs that the text parse does not resolve."
  - "247-09: matrix-resolved names go through the existing if: refusal unchanged, so a matrix flag in a conditional job or step exits 1 like a literal flag."

patterns-established:
  - "A --project value is either a literal [a-z0-9-] name or ${{ matrix.project }}. Any other ${{ }} expression in a --project flag on a mix/npx command line exits 1."

requirements-completed: []  # CI-02 completes with the 247-10 split and its live runs

coverage:
  - id: D1
    description: "The N-file receipt reconciles split legs, fails closed on a dropped leg, a duplicate across files, zero --executed and an oversized file, and keeps the legacy form"
    requirement: CI-02
    verification:
      - kind: unit
        ref: "npm --prefix examples/threadline_phoenix/e2e run test:unit (39 pass / 0 fail; 7 new CLI cases in operator-ci-evidence.test.ts)"
        status: pass
  - id: D2
    description: "The receipt runs under plain node with no tsx"
    requirement: CI-02
    verification:
      - kind: unit
        ref: "node --experimental-strip-types support/operator-ci-evidence.ts prints both usage lines, exit 1; also asserted in the plain-node test case"
        status: pass
  - id: D3
    description: "Matrix resolution and fail-closed rules for bin/browser-full-projects; live derivation unchanged"
    requirement: CI-02
    verification:
      - kind: unit
        ref: "mix test browser_full_projects_contract_test + ci_coverage_doc_contract_test + repo_contract_scope_contract_test + browser_journey_evidence_contract_test (72 tests, 0 failures; 11 new matrix cases)"
        status: pass
      - kind: unit
        ref: "bin/browser-full-projects --list ci on the live tree prints desktop-chromium mobile-chromium"
        status: pass

metrics:
  duration: "~25 min"
  completed: 2026-10-26
---

# Phase 247 Plan 09: N-file receipt and matrix-aware Browser-full derivation Summary

The operator-journey receipt now reconciles one discovered/executed file pair per matrix leg under plain `node --experimental-strip-types`. `bin/browser-full-projects` reads `--project=${{ matrix.project }}` from the job's `strategy.matrix.project` list and exits 1 on any matrix shape it cannot resolve. Both work with today's single browser job, so 247-10 only needs to change ci.yml, its contracts and the docs.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (tracer) | N-file receipt inputs, plain-node runnable | b2c16eef | operator-ci-evidence.ts, operator-ci-evidence.test.ts |
| 2 | `${{ matrix.project }}` resolution, fail closed, 11 contract cases | a209ccbe | bin/browser-full-projects, browser_full_projects_contract_test.exs |

## What changed

**Receipt (D-07a).** `main()` now takes its inputs from `evidenceInputs/1`. The flag form uses `parseArgs` with `multiple: true` for `--discovered` and `--executed`, and requires both lists to be non-empty plus exactly two positionals. The legacy form stays `--verify inv disc exec receipt`. The size cap is checked on every path before any read. Inputs are concatenated with `flatMap`. `validateEvidence`, `uniqueIndex`, the inventory and `jobId: "verify-example-browser"` were not changed. The usage message shows both forms. The script already loaded under plain Node, and it still imports only `node:*` modules.

The new tests spawn the real script with `process.execPath --experimental-strip-types`. They cover: split legs pass and the receipt is written; a dropped mobile leg fails with `required journey was not executed`; the same executed file passed twice fails with `executed report contains duplicate journey identity`; zero `--executed`, zero `--discovered`, a missing receipt, an extra positional and an unknown option are all usage errors; a sparse file over 20 MiB passed as a second `--executed` is rejected; the legacy form passes; running with no arguments prints both usage lines without `ERR_MODULE_NOT_FOUND`. The test file still runs under tsx because of its `.js` sibling import, as the plan allows.

**Resolver (D-07, Pitfall 1).** `body_projects` now returns a `{:expression, text}` marker for each `--project=${{ … }}` on a mix or npx command line. `ci_projects` resolves these markers before the existing `if:` check. `enclosing_job/2` was split out of `job_conditions/2`, so both use the same job lookup. `mapping_entry/2` reads `strategy` → `matrix` → `project` by indentation. Each of these exits 1 with a `.github/workflows/ci.yml job <id>: …` message:

- a `${{ }}` expression other than `matrix.project`
- no `strategy.matrix.project`
- an empty list
- an unparseable value, such as `${{ fromJSON(...) }}`
- `include:` or `exclude:` rows that name a project
- a name outside `[a-z0-9-]`

The header doc's CI paragraph and exit-code list now describe this.

Contract cases (new `describe "matrix resolution"`, built with `mutated_root/3` and `to_matrix_form/2`):

- A: an inline list resolves to CI, and Browser-full is `route-capture`
- A': a block sequence with a comment and a quoted name gives the same result
- B: with `[desktop-chromium]`, mobile-chromium moves to Browser-full
- C, D: `matrix.other` and `env.P` each exit 1
- E: an include-only project exits 1
- F: an empty list exits 1
- an unparseable list, a job with no strategy, and a matrix flag behind a job-level `if:` each exit 1

The literal `--project=desktop-chromium --project=mobile-chromium` mutation anchors were not changed, as the plan requires.

## Verification

- `npm --prefix examples/threadline_phoenix/e2e run test:unit`: 39 pass, 0 fail. The plain-node usage probe passes.
- `mix test` on browser_full_projects, ci_coverage_doc, repo_contract_scope and browser_journey_evidence contracts: 72 tests, 0 failures. Run on an ephemeral `postgres:16` container labelled `dev.threadline.plan=247-09`, removed afterwards.
- `bin/browser-full-projects --list ci` on the live tree prints `desktop-chromium mobile-chromium`.
- `mix verify.format` exits 0; `mix verify.credo` finds no issues.
- Tracer gate: the Task 1 `<verify>` was re-run end-to-end before Task 2 and passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Fail closed on any matrix include:/exclude: row that names a project**
- **Found during:** Task 2
- **Issue:** The plan asked for a refusal on include-only project rows. But `include:` can add a leg and `exclude:` can remove one even when `project:` is also listed, and the text parse does not resolve either. Allowing them would count a project as CI that may not run, or miss one that does.
- **Fix:** Exit 1 whenever an `include:` or `exclude:` entry under `strategy.matrix` mentions `project:`. Case E covers the include-only shape.
- **Files modified:** bin/browser-full-projects
- **Commit:** a209ccbe

**2. [Rule 2] Extra fail-closed cases beyond A-F**
- Added contract cases for an unparseable dynamic list, a matrix flag in a job with no `strategy`, and a matrix flag behind a job-level `if:`. The receipt also got a per-file size-cap test and a test for stray positionals and unknown options. These cover the threat-register mitigations T-247-18 and T-247-19.

No other deviations. ci.yml is unchanged.

## Deferred Issues

- One line in `bin/browser-full-projects` (`rest = binary_part(...)` in `split_gated/1`) was already unformatted before this plan. `bin/` is outside the formatter inputs, so `mix verify.format` does not check it. Left as is because it is out of scope.
- A shell variable passed as a project value (e.g. `--project=$P`) is still not counted and not refused. This was already true before this plan, and no workflow uses it. Logged here only.

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file-access surface. The receipt reads only paths given on the command line, and each path is size-capped.

## Self-Check: PASSED

- FOUND: examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts (parseArgs count 2, jobId line count 1)
- FOUND: bin/browser-full-projects (matrix count 35)
- FOUND: b2c16eef, a209ccbe (ancestors of HEAD)
