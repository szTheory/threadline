---
phase: 219-deps-only-build-cache
plan: 01
subsystem: testing
tags: [ci, github-actions, actions-cache, contract-test, exunit, mutation-controls]
status: complete

requires:
  - phase: 216
    provides: "the cache-key contract (runner-led keys, resolved setup-beam outputs) reused via key_value_errors/3"
  - phase: 218
    provides: "the mutation-control idiom and the all-workflow OS-family guard"
provides:
  - "build_cache_errors/2: one pure CACHE-01 contract over %{path => workflow text} plus CONTRIBUTING text"
  - "build_cache_security_errors/1, asserted live now (D-17 subset)"
  - "build_cache_job_errors/3 and tree rules: allowlist, order, keys, save, rm, env, inline"
  - "build_cache_doc_errors/2: ci.yml CACHE KEY CONTRACT comment and CONTRIBUTING section parity"
  - "build_cache_fixture/0 and build_cache_fixture_contributing/0: the shape plan 02 must reach"
  - "build_cache_controls/2 (65 controls, 30 fragments) and build_cache_live_needle_controls/2"
affects: [219-02, 219-03]

actuals:
  tokens: 20217
  tasks: 4
  commits: 4
plan_head_before: b3ce4c5b3fffbca8eb136e97311975af0ae7fcbe
plan_head_after: cdfd29ae6e7c1cddecf211c78ca9bc2d6d18b127

tech-stack:
  added: []
  patterns:
    - "Step classifier over uncommented step text, with step-index windows for contiguity"
    - "Mutation controls as {label, mutated_workflows, mutated_contributing, fragment} tuples asserting a specific rule= fragment"
    - "Needle-minimal mutators (job header + first steps: line, job-level env line) for files a later plan may not edit"

key-files:
  created: []
  modified:
    - test/threadline/ci_workflow_parity_contract_test.exs

key-decisions:
  - "Rule ids carry the literal rule=<id> token at their definition, so each token is greppable at both the rule and its control"
  - "The deps.compile guard gets its own token, rule=compile-guard, with its own control, instead of reusing rule=save-guard"
  - "Restore/save action-version checks (actions/cache/restore@v5, actions/cache/save@v5) report under rule=combined-action; no extra token"
  - "Zero-arity fixture functions stay paren-free (defp build_cache_fixture do) because credo --strict enforces ParenthesesOnZeroArityDefs"
  - "requirements-completed stays empty: plan 01 proves the static contract only; CACHE-01 completes with plans 02 and 03"

patterns-established:
  - "Contract first, YAML second: a pure error function proven on a synthetic fixture before any workflow edit"
  - "Hybrid proof: every live workflow with only ci.yml swapped for the fixture, so controls on files plan 02 cannot edit are proven on live text"

requirements-completed: []

coverage:
  - id: D1
    description: "D-17 security subset (release.yml cache-free, no cache in privileged-trigger workflows, only cache: npm on setup-node) asserted against the live workflows"
    requirement: "CACHE-01"
    verification:
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#the D-17 security subset holds on every live workflow"
        status: pass
  - id: D2
    description: "Fail-closed allowlist, per-job rules and synthetic fixture clean under the full composed function"
    requirement: "CACHE-01"
    verification:
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#the synthetic fixture satisfies every build cache rule"
        status: pass
  - id: D3
    description: "Every D-21 fault proven red with its own rule= fragment on the fixture and on the hybrid map; positive comment control clean"
    requirement: "CACHE-01"
    verification:
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#control: every build cache fault is red on the hybrid map (live workflows, fixture ci.yml)"
        status: pass
  - id: D4
    description: "Every control needle outside <interfaces> proven against the fully live workflows"
    requirement: "CACHE-01"
    verification:
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#live needle: every control outside <interfaces> bites on the fully live workflows"
        status: pass
  - id: D5
    description: "Docs parity (ci.yml comment and CONTRIBUTING section) inside the same function"
    requirement: "CACHE-01"
    verification:
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#docs: the fixture ci.yml comment and CONTRIBUTING section satisfy the doc rules"
        status: pass

duration: 36min
completed: 2026-09-28
---

# Phase 219 Plan 01: Deps-Only Build Cache Contract Summary

**The whole CACHE-01 rule set now exists as one pure function, `build_cache_errors/2`. It is proven clean on a fixture shaped like the plan 02 target, and 65 mutation controls prove it red, each on its own `rule=` fragment. Only the D-17 security subset is asserted against the live workflows.**

## Performance

- **Duration:** about 36 min
- **Started:** 2026-09-28T14:03:39Z
- **Completed:** 2026-09-28T14:40Z
- **Tasks:** 4 of 4
- **Files modified:** 1 (`test/threadline/ci_workflow_parity_contract_test.exs`, +2152 lines)

## Accomplishments

- **Task 1 (tracer): the D-17 security subset, asserted live.**
  - `build_cache_security_errors/1` checks that `release.yml` has no cache, that no `pull_request_target`, `workflow_run` or `issue_comment` workflow has a cache step, and that the only built-in cache is `cache: npm` on setup-node.
  - It matches key-anchored regexes on uncommented lines. A negative test confirms that "runner tool cache", `git diff --cached` and `data.workflow_runs` do not match.
  - It is asserted green against the live workflows, and a control on `publish-hex` proves it red.
- **Task 2: attributes, classifier and per-job rules.**
  - Four module attributes: `@build_cache_jobs` (4 entries, each with `{reason, mode, projects}`), `@build_cache_exclusions` (13 entries), `@build_key_segments` and `@build_key_forbidden`.
  - A step classifier with project attribution.
  - Per-job rules: order and contiguity by step-index window, key segments, forbidden inputs, restore-keys, save key/path/guard, compile guard, continue-on-error, rm (unconditional, env guard, targets), job `MIX_ENV`, cache path env, compiler env, inline and restore-only.
  - Tree rules: allowlist, allowlist-unused, allowlist-project, exclusion-unknown and no-optional-cache. The function fails closed when `ci.yml` is missing.
  - The synthetic fixture is built from the live step skeletons of the four allowlisted jobs.
- **Task 3: mutation controls.**
  - `build_cache_controls/2` holds every D-21 fault: order moves, save faults, one control per key segment and per forbidden input for each project, rm faults, block removals, a clone into capture, a local action, a privileged-trigger workflow and a stale exclusion.
  - The controls run twice: on the fixture, and on the hybrid map (every live workflow, with ci.yml swapped for the fixture).
  - A positive control adds `_build` comment lines and stays `[]`.
  - `build_cache_live_needle_controls/2` proves the nine out-of-`<interfaces>` needles against the fully live workflows today.
- **Task 4: docs parity.** `build_cache_doc_errors/2` covers:
  - the six-space `# CACHE KEY CONTRACT` heading;
  - `build-v1` and the rm literal in the ci.yml comment;
  - the stale sentence, whose needle is assembled by concatenation;
  - the CONTRIBUTING `### Dependency build cache` section: both tables must be set-equal to the attributes, and the section must carry the nine D-19 needles.

  Three doc controls run in both tables.

## Task Commits

1. **Task 1: security contract (tracer)**: `72790694` (test)
2. **Task 2: job rules and fixture**: `8fb4c2cb` (test)
3. **Task 3: mutation controls**: `22d8428f` (test)
4. **Task 4: docs parity**: `cdfd29ae` (test)

TDD evidence: every task was RED first, as a compile error on the undefined functions, and then GREEN. This is a `type: execute` plan with `tdd="true"` tasks, not a `type: tdd` plan.

## Verification

- `mix test` on the four contract files (parity, topology, action runtime, browser-full): 100 tests, 0 failures. The research baseline was 89.
- `mix verify.test`: 2499 tests and 9 properties, 0 failures (3 excluded by the standing tags).
- `mix format --check-formatted` and `mix verify.credo`: clean after every task. The test compile emits no warnings.
- The live `describe "dependency cache contract"` block is byte-identical to the plan base `b3ce4c5b` (diffed).
- No workflow file was edited. `git status --porcelain -- .github/workflows/` is empty.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Zero-arity fixture defs have no parentheses**
- **Found during:** Task 2
- **Issue:** Two acceptance greps expect parentheses. `grep -c 'defp build_cache_fixture('` expects 1, and `build_cache_fixture_contributing()` is written the same way. But `mix verify.credo` (`--strict`) enables `Readability.ParenthesesOnZeroArityDefs`, and the repo has no zero-arity defs with parentheses.
- **Fix:** Both are defined as `defp build_cache_fixture do` and `defp build_cache_fixture_contributing do`. `grep -c 'defp build_cache_fixture do'` prints 1. Call sites use `build_cache_fixture()` as the plan specifies.
- **Commit:** `8fb4c2cb`, `cdfd29ae`

**2. [Rule 2 - Missing critical] Rules without a listed control got one; the compile guard got its own token**
- **Found during:** Tasks 2-3
- **Issue:** The plan says to "apply the same guard rule to the `:deps_compile` step", but lists no control for it. Likewise, `rule=save-path`, `rule=cache-path-env` and `rule=exclusion-unknown` had no control in the D-21 list, so they could have gone silently vacuous.
- **Fix:**
  - Added `rule=compile-guard` with a control that drops the root deps-compile `if:`.
  - Added controls for `save-path` (the example save loses its deps line), `cache-path-env` (`_build/test` instead of the env-scoped path) and `exclusion-unknown` (the fixture's `verify-repo-hygiene` job is removed).
  - Every rule token now has at least one proven-red control: 30 distinct fragments across 65 controls.
- **Commit:** `8fb4c2cb`, `22d8428f`

**3. [Rule 1 - Bug] Rule tokens were not greppable at their definition**
- **Found during:** Task 3 acceptance (`grep -c 'rule=allowlist-project'` expects at least 2)
- **Issue:** Rule ids were passed as bare strings (`"order"`), so the literal `rule=<id>` appeared only in control fragments.
- **Fix:** Every rule definition now passes `"rule=<id>"`, and `build_cache_error/5` interpolates it verbatim. The message shape is unchanged.
- **Commit:** `22d8428f`

**4. [Discretion] Action-version checks report under `rule=combined-action`**
- The plan requires a `_build` save to use `actions/cache/save@v5`, but names no token for that check. The restore and save version checks report as `rule=combined-action` ("use the split restore@v5/save@v5 pair"), so no extra token was added.

## Handoff Notes for Plan 02

- **Step names and ids.** Plan 02 must reproduce every `<interfaces>` step name and id byte for byte. The controls raise `ArgumentError` on a missing needle.
- **The example rm is needled by two regexes.** They expect `rm -rf "examples/threadline_phoenix/_build/${MIX_ENV:?}/lib/threadline" \`, then a newline, then `"examples/threadline_phoenix/_build/${MIX_ENV:?}/lib/threadline_phoenix"`: two quoted paths joined by a backslash continuation.
- **CONTRIBUTING tables.** The first cell of each row must hold exactly one backticked id. Every backticked value in that cell is collected, so a cell like `` `verify-flake` (`flake-detection.yml`) `` would break set-equality. The verify-capture row control removes the first line starting with ``| `verify-capture` |``.
- **The comment heading.** The stale-sentence control inserts after the first line starting with `      # CACHE KEY CONTRACT`.
- **Plan 02 still owns:**
  - the YamlElixir anti-drift assert (D-20);
  - deleting the old `describe "dependency cache contract"` block;
  - flipping the live assert to `build_cache_errors(all_workflows(), read_rel!(["CONTRIBUTING.md"])) == []`.

## Known Stubs

None. The fixture's `echo ok` stub jobs are deliberate test data: each copies a live job header and `steps:` line so the needle mutators can be proven. They are not product stubs.

## Issues Encountered

None. Every gate passed on its first run after each task.

## Next Phase Readiness

The contract exists and is proven. Plan 02 can make the ci.yml, CONTRIBUTING and live-assert changes in one atomic commit against it.

## Self-Check: PASSED

- The test file exists, and all four commits (`72790694`, `8fb4c2cb`, `22d8428f`, `cdfd29ae`) are in `git log`. `git rev-list --count b3ce4c5b..HEAD` = 4.
