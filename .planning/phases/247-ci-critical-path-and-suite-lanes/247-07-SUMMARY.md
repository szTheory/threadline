---
phase: 247-ci-critical-path-and-suite-lanes
plan: 07
subsystem: ci
tags: [exunit-tags, contract-tests, lane-scope, github-actions, node]
status: complete

requires:
  - "247-06 (THREADLINE_TEST_SCOPE filter, scope rows, Threadline.RepoContractScopeContractTest)"
provides:
  - "D-09a no-dodging: tagged files are scanned for invocation-shaped toolchain markers, including calls to and aliases of modules defined under lib/ (computed at test time) and runs of mix-running bin/ scripts"
  - "D-09b no-unclassified: every test/**/*_contract_test.exs is tagged or an @exempt key; exempt keys must exist and must not be tagged"
  - "Node direction: every test file that runs Node is tagged"
  - "63 files tagged `@moduletag :repo_contract` (58 contracts + 5 non-contract test files), 58 @exempt rows"
  - "ci.yml: the two verify-test Node steps run on the current lane only"
affects: ["Land B", "247 CI-03 measurement"]

actuals:
  tokens: 13600
  tasks: 3
  commits: 4
plan_head_before: fc9c2d8caa36495d30eae847313f7600ffbf8e18
plan_head_after: 58a7cd3d23c25147d9529a045e81558162adccc6

tech-stack:
  added: []
  patterns:
    - "Library references are scanned with string literals, heredocs and comments blanked out. Fixed markers and bin-script checks still read the raw source."
    - "Mutation controls are in-memory sources at synthetic paths (test/fake/...), so they never touch or match real files"

key-files:
  created: []
  modified:
    - test/threadline/repo_contract_scope_contract_test.exs
    - .github/workflows/ci.yml
    - test/threadline/browser_journey_evidence_contract_test.exs
    - "61 test files, one added tag line each"

key-decisions:
  - "247-07: deps_audit_gate_test stays untagged (exempt). It calls Mix.Project.config() to list runtime deps, which the denylist flags, and the marker was not weakened."
  - "247-07: ci_topology_contract_test stays untagged (exempt). It sources bin/verify-bump-rehearsal, a mix-running script, for its guarded parser, and the bin-script marker cannot tell a guarded source from a run. It costs 124 ms on min/latest."
  - "247-07: cloak_advisory_reachability_contract_test (not in RESEARCH's table) is exempt. It parses the example's sources with the Code AST."
  - "247-07: browser_journey_evidence and operator_surface/operator_evidence were tagged in the Task 1 commit, because the node-direction rule is live from Task 1."
  - "247-07: lib-module scans ignore strings, heredocs and comments; a bin-script line counts only when it builds or runs the path; `bash -n` syntax checks are not runs. Each tuning has a positive and a negative mutation control."

patterns-established:
  - "A new contract test file must be tagged or exempted with a reason in the same commit, or the scope contract fails"

requirements-completed: []  # CI-03 also needs CI-timed weights and the ratio over 3 live runs (later plans)

coverage:
  - id: D1
    description: "D-09a, D-09b, node direction and exemption hygiene are live on the real tree, and each direction has mutation controls"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "test/threadline/repo_contract_scope_contract_test.exs (15 tests: 6 from 247-06, 4 live D-09, 5 D-09 control tests covering 33 in-memory cases)"
        status: pass
  - id: D2
    description: "Node steps current-only, pinned by browser_journey_evidence"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "test/threadline/browser_journey_evidence_contract_test.exs; actionlint clean"
        status: pass
  - id: D3
    description: "Toolchain-scope run and full suite on ephemeral postgres:16"
    requirement: CI-03
    verification:
      - kind: integration
        ref: "THREADLINE_TEST_SCOPE=toolchain mix verify.test_partitioned: `63 repo-contract files run on the current lane only`, 206 files, 4 partitions with 0 failures, exit 0. mix verify.test: 32 properties, 3361 tests, 0 failures, 3 excluded"
        status: pass
  - id: D4
    description: "min/latest skip the tagged files and install no Node on GitHub Actions"
    requirement: CI-03
    verification:
      - kind: other
        ref: "backstop: first CI run of Land B"
        status: unknown

duration: 50min
completed: 2026-10-26
---

# Phase 247 Plan 07: CI-03 classification Summary

**Every contract test file is now either tagged `@moduletag :repo_contract` or listed in an `@exempt` map with a one-line reason. Tagged files are proven free of toolchain markers, and every Node-running test is tagged. As a result, the min and latest lanes skip 63 files (about 103 s of raw local weight) and no longer install Node.**

BASE: `fc9c2d8caa36495d30eae847313f7600ffbf8e18`

## Performance

- **Duration:** about 50 min
- **Completed:** 2026-10-26
- **Tasks:** 3 (4 commits: Task 3 is split into batch C and ci.yml, as the plan orders)
- **Files modified:** 63

## Accomplishments

- The scope contract gained these public pure functions: `dodging_offenders/2`, `unclassified/3`, `exemption_errors/3`, `node_offenders/2`, `lib_modules/1`, `tagged?/1` and `test_sources/0`. Every needle is assembled at runtime, and the file passes its own scan.
- Live rules: no-dodging, no-unclassified, node-direction and exemptions (exempt paths exist, are not tagged, and have a one-line reason). The glob guard and the lib-module set are both checked to be non-empty.
- Mutation controls: 13 positive dodging cases (mix/elixir processes, Repo, a lib alias, a multi-alias, a lib call, a top-level `Threadline.f(` call, a DB case template, compiled docs, a Mix task call, a Mix project call, and running clean-checkout or demo-up). 7 negative cases (a test-support call, quoted text, a quoted call, a heredoc call, a comment, a `bash -n` check, a `File.read!` of a script path). Plus untagged-is-safe, a near-miss tag, unclassified, missing or also-tagged exemptions, and 3 node-runner cases.
- ci.yml: `if: matrix.lane == 'current'` sits directly under `- name:` on both Node steps, above `uses:` and `working-directory:`. The comment now explains why.

## Final classification counts

| | Count | Notes |
|---|---|---|
| Tagged files | 63 | 58 `*_contract_test.exs` + `date_release_changelog`, `deps_health_report`, `repo_hygiene_guard`, `temp_leak_check`, `verify_action_pins` |
| Raw weight of tagged files | 103,246 ms | sum from `test/partition_weights.txt` (RESEARCH estimated about 102 s) |
| `@exempt` rows | 58 | the RESEARCH Exempt table (55) + deps_audit_gate, ci_topology, cloak_advisory_reachability |
| Contract files | 115 | 58 tagged + 57 exempt; no file left unclassified |
| Repo-contract count line | `63 repo-contract files run on the current lane only` | from the toolchain-scope run |

The none-of-six check (public_surface, release_artifact, dialyzer_slice, clean_checkout, retry_network, zero_skips) returns 0 tagged. There are 0 combined or per-test tag forms.

## Task Commits

1. **Task 1: contract plus batch A** (20 of 21 tagged, plus 2 Node files): `070a9635` (test)
2. **Task 2: batch B plus marker tuning** (18 tagged; operator_evidence was already tagged): `7644105c` (test)
3. **Task 3a: batch C plus live D-09b** (21 tagged): `e22050a8` (test)
4. **Task 3b: Node current-only**: `58a7cd3d` (ci)

## Verification evidence

| Check | Result |
|---|---|
| scope, zero_skips, ci_topology, browser_journey_evidence, ci_workflow_parity, ci_action_pin, ci_action_runtime | 142 tests, 0 failures |
| Every touched test file, run per batch | 412, 205 and 213 tests, 0 failures |
| `THREADLINE_TEST_SCOPE=toolchain mix verify.test_partitioned` (ephemeral postgres:16) | 63 dropped; 206 files; 692/642/583/641 tests, 0 failures; exit 0 |
| `mix verify.test` (ephemeral postgres:16) | 32 properties, 3361 tests, 0 failures, 3 excluded |
| `mix verify.format`, `mix verify.credo` | clean |
| `actionlint .github/workflows/ci.yml` | clean |
| `git diff BASE..HEAD -- test/test_helper.exs` | empty |
| Batch loops A, B and C | exit 0 |

Under toolchain scope, the partition max/min wall ratio was 1.89 locally. Weights are balanced to within 1 ms. The wall spread comes from setup time on a 4-way local run, and the ratio target itself is CI-03's later live measurement.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Two Node files tagged in Task 1**
- **Found during:** Task 1
- **Issue:** The node-direction rule, which the plan makes live in Task 1, flagged `browser_journey_evidence` (in no batch) and `operator_surface/operator_evidence` (batch B) as untagged Node runners.
- **Fix:** Both were tagged in the Task 1 commit after passing the dodging scan.
- **Commit:** 070a9635

**2. [Rule 1 - Bug] Marker tuning, recorded per the plan**
- **incident_playbook_doc:** it asserts guide text such as `"Threadline.as_of("`. Lib-module scans now blank out strings, heredocs and comments. Real calls, aliases and the fixed markers are unaffected, and controls cover both directions.
- **local_docker_dx:** it runs `bash -n bin/demo-up` (a syntax check that runs nothing) and `read!("bin/demo-up")`. A bin-script line now counts only when it is a `System.cmd`, a `Path.join`/`Path.expand`, or an attribute or variable bound to a bare string. `bash -n` lines are excluded.
- **Commit:** 7644105c

**3. [Rule 2 - Correctness] Stricter than the plan in two places**
- `StorageSchemaCase` (a test-support DB case template) was added beside the two case-template markers. `import`/`require`/`use` of a lib module count like `alias`.
- Exempt keys may be any `*_test.exs`, not only contracts, so that `deps_audit_gate_test` can be recorded.

**4. [Classification] Not tagged despite RESEARCH**
- `deps_audit_gate_test` (2,960 ms, a Tag A candidate) and `ci_topology_contract_test` (124 ms, Tag B) were flagged by the contract and are exempt with reasons. No marker was weakened to admit them.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: test/threadline/repo_contract_scope_contract_test.exs, .github/workflows/ci.yml, test/threadline/browser_journey_evidence_contract_test.exs
- FOUND commits: 070a9635, 7644105c, e22050a8, 58a7cd3d
- Ephemeral container `dev.threadline.plan=247-07` removed; no background shells left.
