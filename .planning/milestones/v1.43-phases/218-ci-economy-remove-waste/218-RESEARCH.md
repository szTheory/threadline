# Phase 218: CI Economy: Remove Waste - Research

**Researched:** 2026-09-27
**Domain:** GitHub Actions topology, ExUnit contract tests, `bin/` table-tested scripts (no new packages)
**Confidence:** HIGH for current-state facts (files read this session, API probed read-only); MEDIUM for cost projections (arithmetic on 214 figures)

## Summary

A focused pass over the live code. Every change has a file:line, and most of the plan is already settled by 218-CONTEXT (D-01..D-11). This pass surfaces **seven facts that change the plan**:

1. **D-05's cache-key fix is already done.** Phase 216 (commit `0ed0a5c5`) gave `flake-detection.yml` the resolved-toolchain key. What remains is to widen `os_family_context_errors` from `ci.yml` to every workflow.
2. **The Browser-full set difference is 4 projects, not 6.** CI runs `tier-a-capture` and `tier-a-capture-light` through `mix verify.capture`, whose `--project` flags live in `mix.exs`, not `ci.yml`. A difference against `ci.yml`'s flags alone would keep re-running both capture projects.
3. **Excluding `:live_dialyzer` turns `test/threadline/zero_skips_contract_test.exs` red.** That test pins the exclude list to `pgbouncer_topology` only. It must change in the same commit as `test_helper.exs`.
4. **`verify-docs` and `verify-hex-package` are dominated on the same triggers.** `verify-bump-rehearsal` runs `mix verify.release`, which runs `MIX_ENV=dev mix docs --warnings-as-errors` and `mix hex.build`. `verify-hex-evaluator` builds the tarball from this tree and compiles and tests it. Both run on every ci.yml event. The D-10 verdict is **dominated**.
5. **`RELEASE_PLEASE_TOKEN` is configured.** After ECON-03, `bootstrap-release-pr-ci` will skip its dispatch in this repo.
6. **Both tracking-issue lanes are green now.** Issue #28 has Browser-full nightly run 36296683320 and push run 36323594181. Issue #36 has Flake Detection run 36302070484.
7. **ECON-07 depends on a maintainer push.** The branch is 386 commits ahead of `origin/main` and not pushed. Dispatch and schedule both need the workflow file on the default branch.

**Primary recommendation:**
- Land the three job removals as **one roster commit**, so the roster shrinks once.
- Put every decision in table-tested `bin/` scripts:
  - a new green-SHA/upstream gate;
  - `classify-flake-run` extended with `inconclusive`;
  - `upsert-ci-issue --close`;
  - a new Browser-full project-difference script.
- Make `bin/verify-dialyzer-slice` require Dialyzer's positive completion marker.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Skip/broken-upstream decision | `bin/` script (table-tested) | Workflow YAML (wiring only) | Logic in `bin/`, not YAML. `bin/classify-flake-run` is the precedent. |
| Flake outcome classification | `bin/classify-flake-run` | Workflow issue-body text | Already the classifier seam |
| Issue open/update/close | `bin/upsert-ci-issue` | Workflow `if:` on classification | Single dedup implementation shared by 3 workflows |
| Browser-full project set | `bin/` script that reads `playwright.config.ts`, `ci.yml` and `mix.exs` | ExUnit contract test | The union must be derived, never hand-listed (PITFALLS) |
| PAT-presence guard | `release.yml` job-level `env` expression | Contract test | Secrets cannot appear in `if:` |
| Dialyzer fail-closed | `bin/verify-dialyzer-slice` | ExUnit negative test | The verifier owns "did Dialyzer run" |
| Re-measurement | `.planning` tooling (copied 214 tools) | gh read-only API | Planning artifact, not product |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Already locked upstream (carry forward, do not re-open)**
- The ROADMAP Phase 218 success criteria 1–5 and REQUIREMENTS ECON-01..07 are the contract. The research resolution table (`.planning/research/SUMMARY.md`, "Researcher disagreements, resolved") settles flake cadence, the `verify-mechanical` removal and the Browser-full set difference.
- The milestone's cross-cutting invariants apply to every commit:
  - **Same-commit roster rule.** A roster change updates the `ci.yml` header comment, the job key, CONTRIBUTING's job table and roster, `ci-required` `needs:` and the topology contract test together.
  - **Immutable ids.** Job `id:`s never change, and `CI required` stays byte-exact.
  - **No laundering.** No trigger-level `paths:`, no static `allowed-skips`, no `continue-on-error` on a voting job.
  - **Justified removals.** Every removal carries a "failure class X is still caught by job Y on trigger Z" line.
  - **Explicit staging.** Stage explicit file lists and never `git add .planning/`.

**Flake Detection (ECON-01)**
- **D-01:** **15 repeats** (`--repeat-until-failure 15`). This is sized from measured iteration time in the `flake-detection.yml` header comment, run 35967937335: a 288 s cold first run plus about 165 s per repeat, so about 46 min total.
  - The step timeout is about 55 min and the job timeout about 70 min, so the classify, upload and issue steps always run. The planner may tune these within that shape if a fresh measurement moves the iteration time.
  - Record the arithmetic in the workflow header comment.
- **D-02:** Cadence is weekly (`schedule`) plus `workflow_dispatch`, replacing the 07:00 UTC nightly.
- **D-03:** **Green-SHA skip.** The workflow looks up the head SHA of its own last successful run through `gh api` and skips when HEAD matches.
  - The decision logic lives in a table-tested `bin/` script, following the `bin/classify-flake-run` precedent, not in YAML.
  - Querying past runs is acceptable here. The "no run queries" rule applies only to ECON-03.
  - The same mechanism serves the Browser-full nightly skip (D-07).
- **D-04:** A red CI on the same SHA exits `broken-upstream`. A step timeout is classified as `inconclusive` (budget exhausted, clean so far), never `unknown`, and the report stops claiming "no header".
- **D-05:** Fix the `runner.os`-only cache key to the contract-compliant shape, meaning the resolved OTP/Elixir shape from Phase 216. Widen the anti-regression grep to all workflows.

**Tracking issues and release (ECON-02, ECON-03)**
- **D-06:** `bin/upsert-ci-issue` gains a close-on-green path, covered by a table test. Issues #28 ("Browser (full project set) is failing", OPEN) and #36 ("Flake Detection: test suite reported unknown", OPEN) are resolved by that path or by cited green runs.
- **D-06a:** **ECON-03 guard: dispatch only when no PAT is configured.**
  - `bootstrap-release-pr-ci` dispatches only when `RELEASE_PLEASE_TOKEN` is absent.
  - Secrets cannot appear in `if:`, so PAT presence reaches the job through a step or job output.
  - With a PAT, release-please's own push already triggers the release PR's CI. That is the cause of the double-dispatch pair, runs 36256339043 and 36256344029.
  - The guard is deterministic and never queries runs.
  - The job wiring and the `always()` failed-sync rationale stay. With no PAT, a failed sync must still produce a red run.
  - Extend `test/threadline/release_control_plane_contract_test.exs`.

**Browser-full (ECON-04)**
- **D-07:** On push, Browser-full runs the computed set difference: the Playwright config's projects minus CI's `--project` list, which is `desktop-chromium` and `mobile-chromium` in `ci.yml` today.
  - The list is not hand-maintained.
  - A contract test proves that CI's projects plus Browser-full's equal the full config project set.
  - The nightly uses the D-03 green-SHA skip.

**live Dialyzer (ECON-05), user decision**
- **D-08:** **Move `:live_dialyzer` into `verify-dialyzer` and make it fail closed.**
  - Exclude it from default `mix test` in `test/test_helper.exs`. It is not excluded there today; only `pgbouncer_topology` is.
  - In `verify-dialyzer`, run it after the PLT cache restore.
  - Change `bin/verify-dialyzer-slice` so that a Dialyzer run error turns the test red. That covers a missing or unreadable PLT, the "Could not read PLT file" case, and any other error that `--ignore-exit-status` currently masks into "0 live warnings".
  - A negative test proves the red: a missing PLT must fail, built at runtime rather than by moving the maintainer's PLT.
  - `test_helper`, CONTRIBUTING and the topology test change in the same commit.
  - Background: the test passes vacuously today (214-BASELINE §8, `deferred-items.md` 214-02/214-03). Relocating a vacuous test would save minutes but prove nothing.

**Dominated proofs (ECON-06)**
- **D-09:** Remove the `verify-mechanical` job and `verify-capture`'s trailing "Assert mechanical checker clean over real evidence" step (`ci.yml` around lines 545–586 and 701–702). Keep the `verify.mechanical` alias. Write the "still caught by" line for each removal.
- **D-10:** **Docs and tarball proofs are removed only if the evidence proves them dominated.** For `verify-docs` (about 75 s) and `verify-hex-package` (about 16 s), compare against the `release.yml` `hex.build` path and any other docs build.
  - If another proof dominates on the same triggers, remove it with a "still caught by" line.
  - Otherwise record "checked, not dominated, kept" with the reason.
  - There is no default removal.

**Re-measurement (ECON-07), user decision**
- **D-11:** **Cited dispatch runs plus cadence arithmetic. Do not wait for real scheduled runs.**
  - After the changes land, dispatch each changed workflow once (Flake Detection, Browser-full) and collect at least 5 post-landing ci.yml PR/push runs.
  - Per-run figures cite run IDs.
  - Monthly figures are `measured run × cadence`, labeled `[inference]`.
  - Record runner-minute and critical-path deltas against 214-BASELINE (BASE-01), reusing the 214 tooling (`.planning/phases/214-baseline-measurement/tools/summarize-ci.py`, `collect-ci-runs.sh`).
  - The phase closes without waiting weeks for weekly or nightly samples.

### Claude's Discretion
- Commit and plan granularity. One ECON item per commit or plan is the natural shape, but the roster changes (`verify-mechanical` removal) must be single commits under the roster rule.
- The exact step and job timeout values within D-01's shape.
- Whether to capture `--trace` output of the `:live_dialyzer` test on CI before the move, as the confirming evidence 214 deferred.
- The name and location of the green-SHA skip script.

### Deferred Ideas (OUT OF SCOPE)
- Deps-only `_build` and example-app caching: Phase 219.
- CI job renames and fastest-to-red ordering: Phase 221.
- Change-aware lane skipping (SEED-006): Phase 222. It reuses the ECON-07 numbers.
- Re-checking the ECON-07 projections against real weekly and nightly samples once several weeks accumulate. This could fold into Phase 222's decision record.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ECON-01 | Flake Detection produces a bounded signal: weekly plus dispatch, 10–15 repeats, a step timeout shorter than the job timeout, green-SHA skip, `broken-upstream`, `inconclusive` on timeout, a compliant cache key, and the grep covering all workflows | §F1–F4. The cache key is already compliant (§F4). Use `timeout(1)` exit 124 for a deterministic timeout signal (§F3). |
| ECON-02 | `upsert-ci-issue` closes on green; #28 and #36 resolved | §F5, with green run IDs for both issues |
| ECON-03 | A release PR head gets exactly one CI run through a deterministic PAT guard | §F6. The secret is configured; use a job-level `env` boolean. |
| ECON-04 | Browser-full push runs only non-CI projects, the nightly skips a green SHA, and a union contract test exists | §F7. The difference is 4 projects, not 6. |
| ECON-05 | `:live_dialyzer` is excluded by default and runs only in `verify-dialyzer`, fail-closed | §F8. `zero_skips` must change, and the `test`-twice pitfall applies. |
| ECON-06 | Dominated proofs are removed with "still caught by" lines | §F9. All four candidates are dominated. |
| ECON-07 | Deltas are re-measured against BASE-01 | §F10. The tools are hard-wired to 214's directory, and a push is needed. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Use the named entrypoints (`mix verify.*`, `mix ci.all`), and cite them verbatim.
- Honest default tests: never exclude a suite from `mix test` without updating `test/test_helper.exs` and the docs together.
- Stable CI job IDs: `id:` fields are immutable, while `name:` may evolve.
- Doc contract tests keep README, guides and CONTRIBUTING aligned. Every workflow change lands with its contract test change.
- Zero human verification. The maintainer handles only push, merge, secrets, spend and scope.
- Never `git add .planning/`.
- Hand-check `STATE.md` and `ROADMAP.md` after any `state.*` call.
- Local gotchas from memory:
  - never run playwright directly; use `mix verify.example_browser` or `ci.all`;
  - `ci.all` red at Dialyzer means a PLT cache miss; rebuild with `mix dialyzer --plt`;
  - exactly 8 screenshot failures are pre-existing locally;
  - the repo-hygiene guard scans `.planning/` prose, so never write home paths or the username;
  - a gsd-tools deferred-item write can clobber a dirty `.planning/WINDOWS.md`.

## Findings (current state, verified this session)

### F1. `flake-detection.yml` today (217 lines)
[VERIFIED: .github/workflows/flake-detection.yml, read in full]

**Triggers (lines 17-21):**

```yaml
on:
  workflow_dispatch:
  schedule:
    # 07:00 UTC nightly (after typical US/EU working hours).
    - cron: "0 7 * * *"
```

**Job `verify-flake` (line 28):**
- `timeout-minutes: 180` (line 41), with no step-level timeout.
- `permissions: contents: read, issues: write` (lines 42-44). There is no `actions: read`, which the run query needs.
- The workflow-level `permissions: contents: read` is at lines 23-24.

**Cache key (lines 68-73), already compliant:**

```yaml
key: ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-${{ hashFiles('mix.lock') }}
```

The research ARCHITECTURE.md line 246 ("`${{ runner.os }}-mix-deps-` (flake-detection.yml:74-75)") is **stale**. Commit `0ed0a5c5` (2026-09-26) fixed it, and `grep -rn runner.os .github/` finds nothing.

**Repeat step (lines 94-101).** The step runs:
- `set +e`
- `mix verify.flake 2>&1 | tee flake-detection.log`
- `exit_code="${PIPESTATUS[0]}"`

It then writes `exit_code=` to `GITHUB_OUTPUT` and runs `exit 0`.

**Classify step (lines 114-129):**
- `if: always()` and `env: EXIT_CODE: ${{ steps.repeat.outputs.exit_code }}`.
- It runs `bin/classify-flake-run flake-detection.log`.
- It computes `iterations` with `grep -c 'Running ExUnit with seed:'`.

**Issue step (lines 157-205):**
- `if: always() && steps.classify.outputs.classification != 'pass'`.
- The `*)` arm (lines 180-183) hard-codes: "No \`Running ExUnit with seed:\` header was found…". That is the **false "no header" claim** D-04 names. It fires for every non-broken, non-flaky outcome, including a cancelled run whose `EXIT_CODE` was empty.

**Fail step (lines 210-214):** `if: always() && steps.classify.outputs.classification != 'pass'` → `exit 1`.

**Mix alias.** `mix.exs:188` is `"verify.flake": ["test --repeat-until-failure 50"]`. The workflow header (lines 31-40) says this measured as 51 total runs.

### F2. Classifier and its test
[VERIFIED: bin/classify-flake-run; test/threadline/flake_classifier_contract_test.exs, read in full]

**Behavior table** (script header, lines 20-32). With `EXIT_CODE=0` the result is `pass`. With a non-zero exit code:

| Headers | Classification |
|---|---|
| 0 | `unknown` |
| exactly 1 | `broken` |
| 2 or more | `flaky` |
| empty or non-numeric | `unknown` |

An empty or non-numeric exit code is also `unknown`. The script always exits 0, and it appends `classification=<x>` to `$GITHUB_OUTPUT` when that is set.

**Test style to copy:**
- `System.cmd(@script, [log_path], env: [{"EXIT_CODE", v}])`.
- It asserts `String.trim(output) == "<class>"` and exit status 0.
- It has a GITHUB_OUTPUT append test.
- Tests 2-4 grep the workflow for:
  - the classify step's `if: always()`;
  - the `bin/classify-flake-run` reference, and that the script is executable;
  - the repeat step's `set +e` and `exit_code=`.
- The fixtures use `System.tmp_dir!()`. **New tests should use `@tag :tmp_dir`** (the CONTRIBUTING "Deterministic tests" rule, Phase 217 HYG-03).

### F3. Recommended ECON-01 shape

**Timeout signal: use `timeout(1)`, not only GitHub's step timeout.**
- A GitHub step timeout kills the step before `exit_code=` is written. The classifier then sees an empty `EXIT_CODE` and says `unknown`, which is the exact D-04 bug.
- Wrap the command instead:

  ```bash
  timeout --signal=TERM --kill-after=60s 55m mix verify.flake 2>&1 | tee flake-detection.log
  ```

  `PIPESTATUS[0]` is then `124` on timeout and `exit_code=124` is always written.
- Keep a step `timeout-minutes` (for example 58) as a backstop, and a job `timeout-minutes` of about 70.
- `--repeat-until-failure` stops at the first failure, so exit 124 means "clean so far".
- `timeout` is GNU coreutils, present on `ubuntu-24.04` [ASSUMED: standard image content; locally `command -v timeout` succeeds].

New classifier rows. Keep all the old rows, and never let `inconclusive` or `broken-upstream` fall through to `flaky`:

| EXIT_CODE | headers | UPSTREAM env | → classification |
|---|---|---|---|
| any | any | `broken` | `broken-upstream` (checked first) |
| `124` | ≥1 | — | `inconclusive` (budget exhausted, clean so far) |
| `124` | 0 | — | `unknown`, with the reason "timed out before the suite started" |
| `0` | any | — | `pass` |

Also emit `reason=<text>` to `GITHUB_OUTPUT`, so the issue body states the true cause instead of the hard-coded "no header" line.

**Repeat count.** D-01 requires 15. Recommend changing the alias to `"verify.flake": ["test --repeat-until-failure 15"]`, so local and CI share one named entrypoint. In the same commit, update:
- `CONTRIBUTING.md:179` ("full suite, 50 repeats") and `:182` ("run nightly" → "weekly");
- the `mix.exs:185-187` comment;
- the `bin/classify-flake-run:3` comment.

No test asserts the literal `50`, confirmed by grep.

Header arithmetic to record (D-01): 288 s + 15 × 165 s = 2,763 s ≈ 46 min, which fits a 55 min step and a 70 min job [inference: run 35967937335 figures quoted in `flake-detection.yml:34-39`].

**Cadence (D-02).** Use for example `cron: "0 7 * * 1"` (Monday 07:00 UTC) plus `workflow_dispatch`.

**Green-SHA skip and `broken-upstream` (D-03/D-04).** Use a new table-tested script, for example `bin/ci-sha-gate` (the name is Claude's discretion). The API was probed read-only this session:

```
GET repos/{owner}/{repo}/actions/workflows/{file}/runs?head_sha=<sha>&status=success&per_page=1
  → .total_count > 0  ⇒ this workflow already succeeded on <sha>
```

- Probed on SHA `5e78b2f05d00619e11aa9b29bc8f612087756846`:
  - `flake-detection.yml` returns `total_count: 1` (run 36302070484, event `schedule`);
  - `ci.yml` returns run 36258719902 (`push`, `success`);
  - `browser-full.yml` returns runs 36296683320 (`schedule`) and 36258719891 (`push`).
- The API docs [CITED: docs.github.com/en/rest/actions/workflow-runs, "List workflow runs for a workflow"] give:
  - `workflow_id` accepts the file name;
  - `status` accepts `success`, `failure`, `completed`, `in_progress`, and others;
  - `head_sha` "Only returns workflow runs that are associated with the specified head_sha".
- **Prefer the `head_sha` form** over "newest success's head_sha == HEAD". It is ordering-independent: the docs do not state sort order, so that part is `[ASSUMED]`. It satisfies D-03's intent, "skip an unchanged green SHA".
- Broken-upstream check on `ci.yml` for the same SHA:
  - query `status=success` and `status=failure` counts;
  - **success > 0 ⇒ not broken**, because a re-run went green;
  - failure > 0 and no success ⇒ `broken-upstream`;
  - neither (in progress or none) ⇒ proceed.

Proposed script interface, testable with a fake `gh` exactly like `ci_issue_upsert_contract_test.exs`, which uses `GH_BIN`, `CALL_LOG` and canned JSON:

```
bin/ci-sha-gate --workflow flake-detection.yml --sha "$GITHUB_SHA" --event "$GITHUB_EVENT_NAME" [--upstream ci.yml]
  env: GH_BIN (default gh), GITHUB_REPOSITORY, GITHUB_OUTPUT (optional)
  stdout + GITHUB_OUTPUT:  decision=run|skip|broken-upstream
                           reason=<one line>
  exit 0 on every decision; exit non-zero only on usage error.
  gh/jq error or malformed JSON ⇒ decision=run (fail OPEN to running the proof, never to skipping it)
```

Rules to encode and table-test:
- **`workflow_dispatch` never skips.** It is an explicit request, and ECON-07's dispatch measurement needs a real run.
- **Only `schedule` honors skip.** If skip applied to dispatch, the D-11 dispatch run on an already-green SHA would measure a 10-second skip job.
- `push` (Browser-full) never skips.

Workflow wiring:
- the gate step runs first;
- the repeat step, and every step after it that does work, adds `if: steps.gate.outputs.decision == 'run'`;
- the job needs `permissions: actions: read`.

A job-level `permissions:` block sets unspecified scopes to none [CITED: docs.github.com Actions "Controlling permissions for GITHUB_TOKEN"; ASSUMED wording].

**Conclusions (recommendation).** Weigh these against the head_sha skip query:

| Outcome | Job | Issue |
|---|---|---|
| `skip` | green | no issue action |
| `broken-upstream` | **red** | no issue (CI's own red is the signal) |
| `inconclusive` | **red** | upsert, because the budget is stale |
| `pass` | green | close-on-green |

A green `broken-upstream` or `inconclusive` run would be counted as "success on HEAD", and every later scheduled run on that SHA would skip, which launders an unproven SHA.

PITFALLS.md line 192 suggested that `budget-exhausted-clean` "files nothing and is not a failure". **That conflicts with the head_sha skip**, so this is flagged as an open question (Q1).

### F4. Anti-regression grep (D-05 remainder)
[VERIFIED: test/threadline/ci_workflow_parity_contract_test.exs:733-762, 1263-1270]

- `test "ci.yml never names the OS-family runner context, comments included"` calls `os_family_context_errors(path, yaml)` on **ci.yml only**. `@os_family_context "runner" <> ".os"` is at line 419.
- The cache-key content check already runs over every workflow: `toolchain_contract_errors(all_workflows())` at line 562, and `key_value_errors` at 1222-1238 rejects the OS-family value.
- **Remaining work:** loop `os_family_context_errors/2` over `all_workflows()` (defined at 126-128, glob-derived). Add a control that mutates a non-ci workflow, for example a `flake-detection.yml` comment. This is born green: no workflow names the context today.

### F5. `bin/upsert-ci-issue` and #28 / #36 (ECON-02)
[VERIFIED: bin/upsert-ci-issue, read in full; test/threadline/ci_issue_upsert_contract_test.exs, read in full]

**Interface today:**
- Flags: `--marker --title --body-file --label [--label-description] [--label-color]`, with `GH_BIN` overridable.
- It lists open issues with `--label L --search "M in:title"` and filters with jq `startswith($marker)`:
  - 0 matches → `issue create` and prints `action=create`;
  - 1 match → `issue comment` and prints `action=update`;
  - more than 1 → die "ambiguous marker".

**Tests:** create/update, ambiguous-fails-closed, and metacharacter/malformed-JSON. They use a fake `gh` script that logs argv.

**Callers:**
- `flake-detection.yml:200`
- `browser-full.yml:143`
- `deps-health.yml:87`

`deps_health_doc_contract_test.exs:196` asserts that `deps-health.yml` calls the script.

**Recommended close path:** add `--close`, which requires `--marker`, `--label` and `--body-file` but not `--title`.
- 0 matches → `action=none`, exit 0.
- 1 match → `gh issue comment N --body-file F`, then `gh issue close N --reason completed`, printing `action=close` and `issue_number=N`.
- More than 1 → die "ambiguous", matching the existing fail-closed rule.
- Table-test all three plus argv safety. The fake `gh` must also answer `issue close`.

**Wiring:**
- flake: a new step with `if: always() && steps.classify.outputs.classification == 'pass'`.
- browser-full: a new step with `if: success()`.
- deps-health: close on `clean`. This is optional; ECON-02 says "CI tracking issues", and adding it keeps the three callers symmetric.

**Current issues** (read-only `gh issue view`, this session):

| Issue | Title | Label | State | Comments | Since | Lane status |
|---|---|---|---|---|---|---|
| #28 | "Browser (full project set) is failing" | `ci-browser-full` | OPEN | 16 | 2026-08-28 | Green: schedule 36296683320, push 36323594181 (2026-09-27) |
| #36 | "Flake Detection: test suite reported unknown" | `ci-flake` | OPEN | 11 | 2026-09-13 | Green: 36302070484 (schedule), 36225676728, 36106137910 |

Both titles start with their workflow's `TITLE_PREFIX`, so the close path matches them.

**Resolving them now** (before the new path lands on `main`) means `gh issue close 28 --comment "<cite run>"`. That is a GitHub write. Memory records that `gh pr close` is unproven under the classifier, so treat a block as a maintainer hand-off and do not route around it. The alternative is to let the new close path resolve them on the first green post-landing run, cited in ECON-07.

### F6. `release.yml` `bootstrap-release-pr-ci` (ECON-03)
[VERIFIED: .github/workflows/release.yml:1-260 read; release_control_plane_contract_test.exs:85-196 read]

**Job at lines 185-202:**

```yaml
  bootstrap-release-pr-ci:
    name: Bootstrap CI on Release PR
    ...
    needs: [release-please, sync-release-pr-pins]
    if: always() && github.event_name == 'push' && needs.release-please.outputs.prs_created == 'true'
    permissions:
      actions: write
      contents: read
    steps:
      - name: Dispatch CI on release PR branch
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: gh workflow run ci.yml --ref release-please--branches--main -R "${{ github.repository }}"
```

This drifts from CONTEXT, which gives 189-206; the real range is 185-202.

**PAT uses** are the lines with `secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN`:

| Line | Use |
|---|---|
| 97 | release-please `token:` |
| 173 | sync `PUSH_TOKEN` |
| 224 | dispatch-bootstrap checkout |
| 655 | later jobs |
| 685 | later jobs |

`gh secret list` shows that **`RELEASE_PLEASE_TOKEN` is configured** (created 2026-05-28).

**Test today.** `test "the release PR pin-sync job exists, is scoped, and gates the CI bootstrap"` asserts, for bootstrap, only:
- `~r/^    needs: \[release-please, sync-release-pr-pins\]$/m`
- `~r/^    if: always\(\)/m`

`job_block!/2` isolates a job's YAML.

**Recommended guard.** GitHub's docs say "Secrets cannot be directly referenced in `if:` conditionals. Instead, consider setting secrets as job-level environment variables, then referencing the environment variables to conditionally run steps in the job." [CITED: docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets]. Use a boolean, not the secret value, so the token never enters a process environment:

```yaml
  bootstrap-release-pr-ci:
    ...
    env:
      RELEASE_PAT_CONFIGURED: ${{ secrets.RELEASE_PLEASE_TOKEN != '' }}
    steps:
      - name: Record whether the PAT already fans out CI
        run: echo "::notice::RELEASE_PLEASE_TOKEN configured=${RELEASE_PAT_CONFIGURED}; dispatch only when false"
      - name: Dispatch CI on release PR branch
        if: env.RELEASE_PAT_CONFIGURED != 'true'
        ...
```

- The `secrets` context being usable in `jobs.<id>.env` is `[ASSUMED]`, from the contexts availability table (not fetched).
- `needs:`, the job-level `if: always() …` and `permissions:` stay byte-identical, so the wiring is kept.
- Why it is correct:
  - With the PAT, release-please's API commit and the pin-sync push (`PUSH_TOKEN`, line 173) both fire `pull_request`. Evidence: v0.11.0 run 36256249852 was cancelled on 9d52ab08, and run 36256339043 succeeded on 0745a341, both `pull_request`.
  - Without a PAT, neither fires, and the dispatch stays.
  - An expired PAT fails loudly at the release-please step (`||` picks the non-empty PAT), so `prs_created` is false and bootstrap never runs.

**Test extensions:**
- assert the job-level `RELEASE_PAT_CONFIGURED: ${{ secrets.RELEASE_PLEASE_TOKEN != '' }}`;
- assert the dispatch step carries `if: env.RELEASE_PAT_CONFIGURED != 'true'`;
- assert no `gh run list` or `actions/runs` query appears in the job, which is the "never queries runs" invariant;
- keep the existing `needs`/`always()` asserts;
- add mutation controls in the file's existing style: drop the step `if:` and flip the comparison.

### F7. Browser-full set difference (ECON-04)
[VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:1-160, mix.exs:353-359, ci.yml:516-518, browser-full.yml read in full, ci_coverage_doc_contract_test.exs read in full, CONTRIBUTING.md:458-498]

**Config projects.** `const projects = [...]` at `playwright.config.ts:22-126` names, in the default env:

```
desktop-chromium, mobile-chromium, tier-a-capture, tier-a-capture-light,
storybook-capture, graded-capture, refute-capture, route-capture
```

A ninth, `desktop-chromium-light`, is registered **only** when `THREADLINE_E2E_THEME === "system"` (lines 13 and 103-124, `...(lightLane ? [...] : [])`). CONTRIBUTING:476 states that it is "Not wired into any CI job".

**CI's projects:**
- `ci.yml:518` runs `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`.
- `ci.yml:658-659` `verify-capture` runs `mix verify.capture`.
- `mix.exs:353-359` expands that alias to:

  ```elixir
  defp verify_capture(args),
    do:
      verify_example_browser([
        "--project=tier-a-capture",
        "--project=tier-a-capture-light",
        "operator-tier-a-capture.spec.ts" | args
      ])
  ```

- Both capture projects set `testMatch: /operator-tier-a-capture\.spec\.ts/`, so the spec filter selects nothing extra.

**Correct push difference:** `{storybook-capture, graded-capture, refute-capture, route-capture}`. This matches ARCHITECTURE.md line 69 ("only the 4 projects ci.yml does not run"). CONTEXT D-07's "`desktop-chromium` and `mobile-chromium`" is the verify-example-browser subset only. **Derive CI's set from `ci.yml` flags plus the flags of the mix aliases that `ci.yml` invokes (`verify.capture`).**

**Enumerating config projects: parse the file statically. Do not use `npx playwright test --list`.**
- The contract test runs under plain `mix test` in `verify-test`, where the e2e `node_modules` is not installed. `run-e2e.sh:250-256` does `npm ci` only inside the browser run.
- A static parse is deterministic. It must:
  - take the `name: "..."` entries inside `const projects = [` … `];`;
  - classify the names inside the `lightLane ?` block as env-gated;
  - fail closed if zero names parse, or if any `name:` outside both known regions appears.
- Optionally cross-check at runtime inside `browser-full.yml` after the e2e deps exist. This is not needed for correctness.

**Recommended script.** `bin/browser-full-projects` prints `--project=<x>` lines for (config default set) − (CI set). It exits non-zero when:
- the difference is empty, or
- the parse is empty, or
- `ci.yml` no longer contains `run: mix verify.capture` while the script still counts that alias's projects.

The workflow step becomes:

```bash
mapfile -t projects < <(bin/browser-full-projects)
mix verify.example_browser "${projects[@]}"
```

**Which events run the difference:** recommend **all events** (push, schedule and dispatch).
- `ci.yml` covers `desktop-chromium`, `mobile-chromium` and the tier-a projects on every push to main, so a nightly that reaches the run step (HEAD not yet green) needs only the difference. Running the full set would repeat CI's work, against ECON-04's wording.
- D-07 locks only push, so this is Claude's discretion. State it in the CI Coverage table.
- Nightly: `ci-sha-gate --workflow browser-full.yml` skips on schedule when `browser-full.yml` already succeeded on HEAD.
- Evidence of waste: nightly 36296683320 ran on SHA 5e78b2f0 after push 36258719891 had already passed.

**Contract test (new, or extend `ci_coverage_doc_contract_test.exs`):**
1. The config default set parses non-empty and contains `desktop-chromium`.
2. CI set ∪ Browser-full set == config default set.
3. CI set ∩ Browser-full set == ∅.
4. `browser-full.yml` invokes `bin/browser-full-projects` and carries no literal `--project` flag.
5. Mutation controls:
   - add a fake project to a config copy, which must appear in the Browser-full set;
   - remove `--project=mobile-chromium` from a `ci.yml` copy, which must move `mobile-chromium` into the Browser-full set.

**Doc test impact.** `ci_coverage_doc_contract_test.exs` derives projects with `~r/--project[= ]([a-z0-9-]+)/` over `ci.yml` and `browser-full.yml` only.
- Once Browser-full has no literal flags, it scans only `ci.yml`, which is still non-empty, so the test still passes.
- It never saw the `mix.exs` capture flags. Extend it to take its project list from the new script's union, so the table's rows are checked against the real set.
- **CONTRIBUTING `## CI Coverage` (lines 458-498) must be rewritten in the same commit:**
  - the `main` and `Nightly` columns for `desktop-chromium`, `mobile-chromium` and the tier-a projects now come from CI, not `verify-example-browser-full`;
  - the prose "the full set runs on `main` and nightly" and "The pull-request set and the full set **overlap**" become false.
- Also update:
  - the `browser-full.yml` header (lines 1-16);
  - the step comment at lines 99-104 ("Unrestricted (no per-project flags)…");
  - the issue-body text at lines 131-138.

### F8. `:live_dialyzer` (ECON-05)
[VERIFIED: test/threadline/dialyzer_slice_contract_test.exs:1-150; bin/verify-dialyzer-slice, read in full; test/test_helper.exs, read in full; test/threadline/zero_skips_contract_test.exs:1-100; ci_topology_contract_test.exs:117-200, 376-500; deps/dialyxir/lib/dialyxir/dialyzer.ex:40-122]

**The tagged test.** `dialyzer_slice_contract_test.exs:8-18`:
- `@tag :live_dialyzer` and `@tag timeout: 540_000`;
- it runs `System.cmd(@script, ["--fixture", @fixture])` and asserts:
  - `status == 0`;
  - `output =~ "verified slice critic-tooling: 3/40 sealed warnings"`;
  - `output =~ "0 live warnings"`.
- `@raw_command "MIX_ENV=dev mix dialyzer --no-check --format raw --ignore-exit-status"`.
- The other tests in the file use `--raw-output` synthetic input and stay in the default suite.

**Why it is vacuous.** The verifier has:
- `@dialyzer_args ["dialyzer", "--no-check", "--format", "raw", "--ignore-exit-status"]` (script line 9);
- `raw_output/1` accepts `{output, 0}`;
- `parse_raw_output/1` keeps only lines starting with `"{:warn_"`.

With no PLT, dialyxir prints `:dialyzer.run error: Could not read PLT file .dialyzer/...: no_such_file`, captured in 214 `raw/local/live-dialyzer-cold-raw-dialyzer.txt`. `--ignore-exit-status` then yields exit 0, zero warn lines, and a passing post-hash.

**Fail-closed signal.** dialyxir `1.4.8` (from mix.lock) `Dialyxir.Dialyzer.dialyze/1`:
- on success prints `"done (passed successfully)"`, status 0;
- on warnings prints `"done (warnings were emitted)"`, status 2;
- on an error prints `":dialyzer.run error: " <> msg`, status 1, and **never** prints a `done (` line.

The warm capture ends in:

```
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
done in 0m1.81s
done (passed successfully)
```

**Recommend:**
- require exactly one line matching `^done \((passed successfully|warnings were emitted)\)$`, after stripping ANSI;
- reject any line containing `:dialyzer.run error:`;
- apply the check in **both** modes (live and `--raw-output`);
- keep `@dialyzer_command` unchanged, so the fixture's `post_analysis.command` and the test's `@raw_command` do not churn.

Dropping `--ignore-exit-status` and mapping exit codes {0, 2} is an alternative, but it would change the fixture's pinned command string.

**Test effects of the new check:**
- Existing synthetic `--raw-output` tests must append the marker line in their `run_fixture/2` helper.
- **Negative test, built at runtime:** write, into a `@tag :tmp_dir` file, a raw output containing the `:dialyzer.run error: Could not read PLT file …: no_such_file` line and no `done (` line. Assert exit 1 and a message such as "Dialyzer did not complete". Add a second row with no output at all.
- This runs in the default suite, is fast, and never touches the maintainer's `.dialyzer`.

**`test_helper.exs:4-7` today:**

```elixir
topology_pooler? = System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1"
# Topology tests need PgBouncer + bootstrap DDL; keep them out of default `mix test`.
exclude = if(topology_pooler?, do: [], else: [pgbouncer_topology: true])
ExUnit.configure(exclude: exclude)
```

Add `live_dialyzer: true` in both branches. `verify.topology` runs `Mix.Task.run("test", ["--only", "pgbouncer_topology"] ++ args)` (`lib/mix/tasks/threadline/verify_topology.ex:16`), so the topology lane is unaffected. `--only live_dialyzer` overrides the exclude.

**Blocking disturbance (same commit):** `zero_skips_contract_test.exs:68-84` asserts:

```elixir
expected = if System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1", do: [], else: [{@topology_tag, true}]
assert exclude == expected
```

Its moduledoc says the only sanctioned exclusion is the topology gate. Extend it to exactly two sanctioned environment gates, `live_dialyzer` because it needs a restored PLT, each with its reason. Keep the "no third tag" invariant.

**Running it in `verify-dialyzer`** (ci.yml:137-257, `env: MIX_ENV: dev`, **no Postgres service**):
- `test/test_helper.exs` calls `storage_up` and `repo.start_link()`, and raises without a database. So running the ExUnit test there needs a `postgres:16` service, `DB_HOST: localhost`, and `MIX_ENV=test` on that step.
- The shelled command still uses `MIX_ENV=dev`, reusing the job's restored `.dialyzer` PLT and its dev `_build`.
- Cost from run 36258719902's step timings: test compile about 47 s, container init about 23 s, and dev compile about 59 s, which is what each verify-test lane pays today inside the vacuous test.
- Net effect: about +1.5 min in `verify-dialyzer` against roughly −1 min × 2 in the verify-test lanes. Neither job is on the critical path (browser p50 623 s) [inference: run 36258719902].
- **Option A (literal D-08):** add the service and a step `MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer`, placed after "Analyze and measure with Dialyzer".
- **Option B (cheaper):** a step `bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/critic-tooling.json`. This needs no DB or test compile. The script proves the same thing, but "the test" would no longer be what runs.
- Recommend **A**, because it is what D-08 and ECON-05 lock. B needs a maintainer scope decision (Q2).
- Consider a named alias `verify.dialyzer_slice` with `preferred_envs` `:test`, so CI and `ci.all` cite one entrypoint (CLAUDE.md named-entrypoint rule).

**`ci.all` parity pitfall.** `ci.all` already invokes `"verify.test"` (= `"test"`). A second bare `"test ..."` entry in the same alias chain is a **no-op**: Mix runs a task once per invocation unless it is re-enabled [ASSUMED: Mix.Task run-once semantics]. Use the existing pattern, `"cmd env MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer"` (or the alias through `cmd`), placed after `"cmd env MIX_ENV=dev mix verify.dialyzer"`, so the PLT exists.

**Topology contract** (`dialyzer_topology_errors/3`, ci_topology_contract_test.exs:376-500) pins:
- `timeout-minutes: 9` plus the comment `ceil(252 * 2 / 60) = 9`;
- the step order (deps → compile → `--plt` → save → `--no-check`);
- `ci.all` containing `"cmd env MIX_ENV=dev mix verify.dialyzer"` exactly once;
- the CONTRIBUTING evidence strings.

Changes for the new step:
- Add an order entry after `--no-check`.
- Add an assertion that the live test runs in `verify-dialyzer`, that it runs nowhere else in `ci.yml`, and that `test_helper` excludes it.
- Add a mutation control for each.
- Re-derive the 9-minute timeout honestly if the added step moves the cold figure: 252 s + about 80 s is about 332 s, still under 540 s, but the comment basis changes.
- Update CONTRIBUTING's "Dialyzer PLT cache and measurement contract" (from line 623) in the **same commit** as `test_helper` and the topology test.

**Min-lane note (PITFALLS line 311):** removing the test from `verify-test (min)` drops nothing real, because it ran vacuously there (no PLT). Record that sentence.

**Optional `--trace` capture** (discretion): one CI run of `mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer --trace` in a verify-test lane **before** the change would confirm 214's inference. A local proof (move nothing; a runtime-built negative test) is enough for the fail-closed claim, so this is optional.

### F9. Dominated proofs: verdicts with evidence (ECON-06, D-09, D-10)
[VERIFIED: ci.yml:538-586, 594-702, 779-871, 882-931, 994-1027; mix.exs:153, 286, 376-383, 402-444; bin/with-rehearsal-registry:1-40, 105-175; bin/verify-bump-rehearsal:380-500]

The trigger set for every candidate and every dominator is the same: ci.yml `on: push [main], pull_request [main], workflow_dispatch` (lines 32-41), with **no job-level `if:`** on any of them.

| Proof removed | Failure class | Still caught by (job, trigger) | Evidence |
|---|---|---|---|
| `verify-mechanical` job (ci.yml:538-586, ~87 s) | a committed scorecard breaches MODE-A/MODE-B | `verify-test` min **and** current lanes, on PR, push and dispatch | `mix verify.mechanical` is `["test test/threadline/operator_surface/mechanical_checker_test.exs"]` (mix.exs:153). The comment at mix.exs:148-152 says the file "already runs in `verify.test`". The file is `use ExUnit.Case, async: true` with no tag, so it is in the default suite. |
| `verify-capture` trailing step "Assert mechanical checker clean over real evidence" (ci.yml:701-702) | regenerated evidence breaches a rule | `verify-capture`'s own "Assert byte-stable regeneration" step (ci.yml:690-699), which proves regenerated == committed, **plus** `verify-test` over the committed JSON, same triggers | After a green byte-stable assert, the inputs are byte-identical |
| `verify-docs` (ci.yml:779-805, `MIX_ENV=dev mix docs`, ~75 s) | ExDoc build fails | **`verify-bump-rehearsal`**, same triggers. It runs `mix verify.release` in the throwaway clone. `verify_release/1` (mix.exs:279-288) runs `"MIX_ENV=dev mix docs --warnings-as-errors"`, which is **stricter** than verify-docs' plain `mix docs`. A failing gate sets `GATE_STATUS=1` and the script ends with `exit 1` (bin/verify-bump-rehearsal:410-420, 485-491). | The docs build runs at NEXT minor. The only version-dependent input is `doc_source_ref` = `"v#{@version}"`, a string [inference]. Docs are skipped only when an earlier rehearsal gate has already failed the job (fail-fast, not a masked pass). |
| `verify-hex-package` (ci.yml:807-871, ~16 s) | `hex.build` fails, or the tarball lacks `lib/` | (a) **`verify-bump-rehearsal`**: `mix verify.release` runs `"mix hex.build"`. (b) **`verify-hex-evaluator`**, same triggers: `bin/with-rehearsal-registry` runs `mix hex.build` on this tree (line 116), serves it, and `priv/ci/hex_evaluator` resolves `{:threadline, ">= 0.0.0", repo: "threadline_rehearsal"}`, then compiles and runs its tests. A tarball without a usable `lib/` cannot compile. | Rehearsal mode is the default (`THREADLINE_HEX_EVALUATOR_MODE` unset in ci.yml:393-430). `release.yml`'s `hex.build` runs on release only, so it is **not** the same trigger set and not a dominator. |

**Verdict: all four are dominated. Remove them in one roster commit** (D-09 plus D-10's "if dominated, remove"). Guard the dominance so it cannot rot silently. Add contract assertions that:
- `verify_release/1` still contains `MIX_ENV=dev mix docs --warnings-as-errors` and `mix hex.build`;
- `verify-bump-rehearsal` still runs `mix verify.bump_rehearsal` and is in `ci-required` `needs:` (`test "the bump-rehearsal gate is wired, required, and never skip-listed"` exists at ci_topology_contract_test.exs:653);
- `verify.hex_evaluator` defaults to rehearsal mode.

This matters for Phase 222 (SEED-006): a change-aware skip of `verify-bump-rehearsal` would now also skip the docs proof. Record that coupling in the decision line.

**Legibility cost** (not a coverage loss): a docs break now shows as a red "Bump rehearsal (next minor)", with the gate label "GATE: mix verify.release at X.Y.0" in the log. Phase 221 owns names.

**Everything the roster commit must touch** (grep-verified this session):
- `.github/workflows/ci.yml`:
  - the header roster at line 2;
  - delete the jobs at 538-586, 779-805 and 807-871, and the step at 701-702;
  - fix the `verify-capture` comment at 588-593 ("and (3) MechanicalChecker.run/1 is clean over it");
  - `ci-required` `needs:` lines 1005, 1008 and 1009;
  - the prose "not sixteen" (983) and "all sixteen jobs" (1026) becomes thirteen.
- `CONTRIBUTING.md`:
  - roster at 522, 525 and 526;
  - job table at 615, 617 and 618;
  - the "Branch protection (maintainers)" list at 726-727;
  - "still caught by" lines.
- `test/threadline/ci_topology_contract_test.exs:96-102`: `assert Regex.match?(~r/^  verify-docs:/m, yaml)` must be removed or retargeted.
- `test/threadline/ci_workflow_parity_contract_test.exs`:
  - `assert setup_beam_steps - 1 == 14` (line ~544) becomes **11**. `ci.yml` has 14 uncommented `uses: erlef/setup-beam@` steps today (counted); three jobs are removed.
  - the `verify-docs` controls at lines 324-368 and 553-556 must retarget another single-setup-beam job (for example `verify-credo`).
- `guides/upgrade-path.md:62` names "CI jobs `verify-test` / `verify-docs`", and `test/threadline/upgrade_path_doc_contract_test.exs:125` asserts `` "`verify-docs`" ``. Both change together. This is a published guide: use a `docs:`/`ci:` commit and no planning vocabulary.
- Keep: the `verify.mechanical` alias (mix.exs:153), `guides/configuration-and-commands.md:140`, and `critic_iteration_runbook_doc_contract_test.exs:30` (asserts CONTRIBUTING mentions `mix verify.mechanical`).

**Roster-derivation tests that will self-check** once all edits land: `ci.yml jobs == header comment == CONTRIBUTING List 1` (parity:171-197) and `ci-required's needs: roster matches CONTRIBUTING.md` (topology:589). `.github/rulesets/main.json:16` requires only `"CI required"`, so it is untouched.

### F10. ECON-07 re-measurement tooling
[VERIFIED: .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh:1-200; summarize-ci.py:1-45, 440-525]

- **Both tools derive their data directory from their own location:**
  - `collect-ci-runs.sh:34-38` has `PHASE_DIR="$(dirname "$SCRIPT_DIR")"` and `RAW_DIR="$PHASE_DIR/raw/ci"`;
  - `summarize-ci.py:35-44` has `RAW_DIR = os.path.join(PHASE_DIR, "raw", "ci")` and a hard-coded `SELF = "python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py"`.
- Running them in place would **write post-change runs into 214's frozen evidence** and mix them into the baseline manifest keys (`ci.yml:pull_request`).
- Recommend copying both into `.planning/phases/218-ci-economy-remove-waste/tools/`. Edit only `SELF` (and nothing else), so the raw data lands in 218's `raw/ci/` and every regenerate command cites 218's copy. Diff the copies against 214's to prove there are no logic changes.
- Commands:
  - `collect-ci-runs.sh --workflow ci.yml --event pull_request --target 5 --min 5`, run after at least 5 post-change runs exist. The collector keeps the newest N successful runs, so run it only once the post-landing runs are the newest. `--since YYYY-MM-DD` restricts by date for `workflow-cost` keys only.
  - `--workflow flake-detection.yml --event workflow_dispatch --status any --target 0 --min 1`, and the same for `browser-full.yml`.
  - `summarize-ci.py jobs|wall|critical-path|runner-minutes --unit pr|push|workflow-cost`.
- **Precondition, human-gated:** the changes must reach GitHub.
  - The branch `milestone/v1.43` is 386 commits ahead of `origin/main` and not on the remote (`git ls-remote`). Pushes need the maintainer's direct grant.
  - `workflow_dispatch` "will only trigger a workflow run if the workflow file exists on the default branch", and the dispatched run uses the `--ref` branch's file version [CITED: docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows].
  - `flake-detection.yml` and `browser-full.yml` already exist on `main`, so `gh workflow run flake-detection.yml --ref <pushed branch>` works once the branch is pushed.
  - PR CI runs on the milestone PR count as `pull_request` samples.
- Monthly projections are `measured run × cadence` and labeled `[inference]` (D-11):
  - Flake: 4.3 weeks × dispatch-run minutes, against the 214 figure of 2,940–4,110.
  - Browser-full: nightly skip ≈ 0 on unchanged SHAs; push ≈ difference-run minutes × pushes.

## Recommended Plan Decomposition

Plans that touch the same files must run **sequentially**. Most plans touch `ci.yml`, `CONTRIBUTING.md` or `browser-full.yml`. Memory says worktrees have no `deps`/`_build`, so an Elixir suite cannot run in one. Record the dispatch-isolation sentinel as `none` per plan.

| Plan | Scope | Files | Same-commit bundle | Proof |
|---|---|---|---|---|
| 218-01 | ECON-06 roster cut (one roster commit) | ci.yml, CONTRIBUTING.md, ci_topology/ci_workflow_parity tests, guides/upgrade-path.md + its test, a dominance-pin test | All of F9's list in **one** commit | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/release_control_plane_contract_test.exs` |
| 218-02 | ECON-05 live Dialyzer | bin/verify-dialyzer-slice, dialyzer_slice_contract_test.exs, test_helper.exs, zero_skips_contract_test.exs, ci.yml verify-dialyzer, mix.exs (ci.all, optional alias), CONTRIBUTING, ci_topology test | Commit A: verifier fail-closed + negative test (born red→green). Commit B: test_helper + zero_skips + CONTRIBUTING + topology + ci.yml + ci.all together | `mix test test/threadline/dialyzer_slice_contract_test.exs`; `MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer` (real PLT) |
| 218-03 | ECON-01 + ECON-02 scripts and flake workflow | new bin/ci-sha-gate + test, bin/classify-flake-run + test, bin/upsert-ci-issue `--close` + test, flake-detection.yml, mix.exs `verify.flake` 15, CONTRIBUTING flake prose, parity-test OS-family widening | script + test per commit; workflow wiring after | `mix test test/threadline/flake_classifier_contract_test.exs test/threadline/ci_issue_upsert_contract_test.exs test/threadline/<ci_sha_gate>_test.exs test/threadline/ci_workflow_parity_contract_test.exs` |
| 218-04 | ECON-04 Browser-full | new bin/browser-full-projects + union contract test, browser-full.yml (difference, gate step, close-on-green, `actions: read`), CONTRIBUTING `## CI Coverage`, ci_coverage_doc test | workflow + CI Coverage table + doc test in one commit | `mix test test/threadline/ci_coverage_doc_contract_test.exs test/threadline/<browser_full_projects>_test.exs` |
| 218-05 | ECON-03 release guard | release.yml bootstrap job, release_control_plane_contract_test.exs | one commit | `mix test test/threadline/release_control_plane_contract_test.exs` |
| 218-06 | ECON-07 re-measure + issue resolution | copied tools, raw data, 218-REMEASURE doc; #28/#36 closure evidence | after a **maintainer push checkpoint** | citation checker (reuse 214 `check-citations.py` on the new doc) |

Plan 218-05 is independent of the others (only `release.yml` and its test) and can run in any wave. After every plan, run `mix ci.all` once at the phase gate.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timeout detection | Parsing GitHub step outcomes | `timeout(1)` exit 124 written to `exit_code` | Deterministic and table-testable. A GitHub step timeout kills the step before any output. |
| Run lookup | Paging `gh run list` and sorting | `actions/workflows/{file}/runs?head_sha=&status=` `total_count` | Ordering-independent and a single call |
| Project enumeration | A hand list in YAML | Static parse of `playwright.config.ts` in one `bin/` script | A new project otherwise runs nowhere (PITFALLS) |
| Issue dedup/close | New `gh issue` logic in each workflow | `bin/upsert-ci-issue --close` | One tested implementation |
| Dialyzer success | Counting `{:warn_` lines | dialyxir's `done (…)` completion marker | Zero warn lines is also what an error prints |

## Common Pitfalls

### P1. A green non-proof poisons the green-SHA skip
The skip keys on "this workflow succeeded on HEAD". Any run that concludes success without proving the SHA marks the SHA proven forever. Keep `broken-upstream` and `inconclusive` red, or add a separate proof marker. A skip run concluding green is safe, because it only happens after a real proof.

### P2. Dispatch honoring the skip breaks ECON-07
If `workflow_dispatch` skips a green SHA, D-11's measurement run is a 10-second no-op. Only `schedule` may skip.

### P3. Missing `actions: read`
A job-level `permissions:` block zeroes every unlisted scope. Without `actions: read` the `gh api` call returns 403 and the gate must fail **open** (run), so the skip silently never happens. Assert the permission in the contract test.

### P4. `zero_skips_contract_test.exs` goes red
Adding any exclude tag fails it by design. Change it in the same commit, with the reason.

### P5. `ci.all` runs `test` twice
A bare second `"test ..."` alias entry is a Mix no-op. Use `cmd env MIX_ENV=test mix test …`.

### P6. The capture projects run twice
Deriving CI's set from `ci.yml` flags alone misses `mix verify.capture`'s projects (mix.exs:353-359).

### P7. The setup-beam count literal
`ci_workflow_parity_contract_test.exs` asserts exactly 14 setup-beam steps in `ci.yml`. The roster commit must change it to 11, or it goes red for an unrelated-looking reason.

### P8. Writing into 214's evidence
The 214 tools write next to themselves. Copy them; never run them in place for 218.

### P9. Verifier marker check breaks the synthetic tests
Apply the completion-marker requirement in `--raw-output` mode too, and update `run_fixture/2` to append the marker, or the synthetic positive tests go red.

### P10. The issue body lies
Replace the `*)` arm's hard-coded "No header was found" with per-classification text driven by the classifier's `reason=` output.

### P11. `git add .planning/` and the hygiene guard
Stage explicit files. The re-measure doc must not contain home paths. The 214 manifests already record repo-relative commands.

## Code Examples

Close-on-green step (browser-full). The interface is proposed, not existing:

```yaml
      - name: Close the browser-lane tracking issue on green
        if: success()
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          TITLE_PREFIX: "Browser (full project set) is failing"
          LABEL: ci-browser-full
          RUN_URL: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
        run: |
          set -euo pipefail
          body_file=$(mktemp); trap 'rm -f "$body_file"' EXIT
          printf 'Green on `%s` (%s): %s\n' "$GITHUB_SHA" "$GITHUB_EVENT_NAME" "$RUN_URL" > "$body_file"
          bin/upsert-ci-issue --close --marker "$TITLE_PREFIX" --label "$LABEL" --body-file "$body_file"
```

The `TITLE_PREFIX`/`LABEL` values are quoted from `browser-full.yml:128-129` [VERIFIED].

Fake-`gh` test pattern to copy, from `ci_issue_upsert_contract_test.exs:5-26` [VERIFIED]: a bash script that appends `"$*"` to `$CALL_LOG` and dispatches on `"$1 $2"`, run with `env: [{"GH_BIN", gh}, ...]`. For `ci-sha-gate`, dispatch on `"$1"` = `api` and return canned `{"total_count":N,"workflow_runs":[...]}` keyed by whether argv contains `status=success` or `status=failure`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| gh CLI (authenticated) | issue reads, ECON-07 collection | ✓ | 2.101.0 | — |
| jq | scripts, tools | ✓ | 1.7.1 | — |
| python3 | summarize-ci.py | ✓ | 3.14.4 | — |
| Elixir/OTP per .tool-versions | all tests | ✓ | elixir 1.17.3-otp-27 / erlang 27.3.4.15 | — |
| PostgreSQL (local) | `mix test` | ✓ | `pg_isready` accepting on the default socket | — |
| `.dialyzer` PLT (local) | live `:live_dialyzer` positive run | ✓ | present | `MIX_ENV=dev mix dialyzer --plt` |
| node / npx | browser lane via `mix verify.example_browser` only | ✓ | 22.14.0 | — |
| `timeout` | classifier tests do **not** need it | ✓ | coreutils | the workflow runs on ubuntu-24.04 |
| Pushed branch on GitHub | ECON-07 dispatch and post-landing runs | ✗ | — | **none; maintainer push checkpoint** |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3, OTP 27.3.4.15) with plain contract tests under `test/threadline/` |
| Config file | `test/test_helper.exs` (exclude list; changes in 218-02) |
| Quick run command | `mix test <touched contract test files>` (seconds; no browser) |
| Full suite command | `mix ci.all` (includes Dialyzer and the 2-project browser lane; expect the documented pre-existing screenshot baseline behaviour under `CI=true`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ECON-01 | Classifier rows: `inconclusive` (124 + headers≥1), `broken-upstream`, 124+0 headers → `unknown` with a reason, old rows unchanged | unit (script table) | `mix test test/threadline/flake_classifier_contract_test.exs` | ✅ extend |
| ECON-01 | Gate decisions: schedule+green → skip; dispatch → run; CI failure without success → broken-upstream; gh error/malformed JSON → run | unit (fake gh) | `mix test test/threadline/ci_sha_gate_contract_test.exs` | ❌ Wave 0 |
| ECON-01 | Workflow shape: weekly cron + dispatch; `timeout` wrapper; step timeout < job timeout; `actions: read`; gate `if:` on work steps; always() on classify/upload/issue | contract (YAML grep + mutation controls) | `mix test test/threadline/flake_classifier_contract_test.exs` | ✅ extend |
| ECON-01 | OS-family context absent from **every** workflow | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs` | ✅ extend |
| ECON-02 | `--close`: 0 → none, 1 → comment+close, >1 → fail closed; argv-safe | unit (fake gh) | `mix test test/threadline/ci_issue_upsert_contract_test.exs` | ✅ extend |
| ECON-02 | Flake/browser workflows call `--close` on green | contract | same file or the workflow tests | ✅ extend |
| ECON-02 | #28 and #36 closed, each with a cited green run | evidence (gh read) | `gh issue view 28 --json state`; `gh issue view 36 --json state` | n/a |
| ECON-03 | Job-level PAT boolean env; dispatch step `if: env.RELEASE_PAT_CONFIGURED != 'true'`; needs/always unchanged; no run queries | contract + mutation | `mix test test/threadline/release_control_plane_contract_test.exs` | ✅ extend |
| ECON-04 | CI ∪ BF == config set; CI ∩ BF == ∅; BF has no literal flags; mutation controls | contract | `mix test test/threadline/browser_full_projects_contract_test.exs` | ❌ Wave 0 |
| ECON-04 | CI Coverage table rows match the union | doc contract | `mix test test/threadline/ci_coverage_doc_contract_test.exs` | ✅ extend |
| ECON-05 | Verifier red on the "Could not read PLT" output and on empty output (runtime-built, `@tag :tmp_dir`) | unit | `mix test test/threadline/dialyzer_slice_contract_test.exs` | ✅ extend |
| ECON-05 | Positive live proof with the real PLT | integration (tagged) | `MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer` | ✅ |
| ECON-05 | Exclude list == {topology, live_dialyzer}; verify-dialyzer runs the tagged test after the analysis step; nowhere else; CONTRIBUTING documents it | contract | `mix test test/threadline/zero_skips_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ✅ extend |
| ECON-06 | Roster three-way parity; needs roster; setup-beam count 11; dominance pins (verify.release docs+hex.build, bump rehearsal required, evaluator rehearsal default) | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs` | ✅ extend |
| ECON-07 | Every figure in the re-measure doc cites a run ID or command | doc check | `python3 .planning/phases/218-ci-economy-remove-waste/tools/check-citations.py <doc>` (copy of 214's) | ❌ Wave 0 (copy) |

### Sampling Rate
- **Per task commit:** the touched test files (the Quick run command).
- **Per wave merge:**

  ```
  mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/release_control_plane_contract_test.exs test/threadline/flake_classifier_contract_test.exs test/threadline/dialyzer_slice_contract_test.exs test/threadline/zero_skips_contract_test.exs test/threadline/ci_issue_upsert_contract_test.exs
  ```

- **Phase gate:**
  - `mix test` (full default suite);
  - `mix ci.all`. If it goes red at Dialyzer, suspect a PLT miss and rebuild with `MIX_ENV=dev mix dialyzer --plt`;
  - `bin/verify-repo-hygiene` over the new `.planning` prose.
  - Never invoke playwright directly.

### Wave 0 Gaps
- [ ] `test/threadline/ci_sha_gate_contract_test.exs`: gate decision table (fake `gh`), covers ECON-01 and ECON-04's nightly skip.
- [ ] `test/threadline/browser_full_projects_contract_test.exs`: union/intersection plus mutation controls, covers ECON-04.
- [ ] `.planning/phases/218-ci-economy-remove-waste/tools/`: copies of `collect-ci-runs.sh`, `summarize-ci.py` and `check-citations.py`, with only `SELF` retargeted, covers ECON-07.

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3 Authentication/Session | no | — |
| V4 Access Control | yes (token scopes) | Least-privilege job `permissions:` (`actions: read` only where the gate runs; `issues: write` only on issue steps' jobs); the PAT is never exposed to shell (boolean env) |
| V5 Input Validation | yes | Scripts treat gh JSON as untrusted: jq type checks, numeric validation (the existing `is_integer` idiom), argv-only marker handling (existing metacharacter test) |
| V6 Cryptography | no | — |

| Pattern | STRIDE | Mitigation |
|---------|--------|-----------|
| Secret leakage through env or logs in the bootstrap job | Information disclosure | `${{ secrets.X != '' }}` boolean, never the value |
| Skip laundering (a green non-proof) | Tampering / Repudiation | P1: red on `broken-upstream`/`inconclusive`; fail open to "run" on API error |
| Shell injection through an issue title or marker | Tampering | Keep argv passing; never `eval`; extend the metacharacter test to `--close` |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `timeout` is present on the ubuntu-24.04 image and returns 124 on expiry | F3 | Timeout classification path untested on CI. Mitigation: the dispatch run in ECON-07 (a lower `timeout` in a one-off check), or assert `command -v timeout` in the step. |
| A2 | The `secrets` context is usable in `jobs.<id>.env` expressions | F6 | The guard expression fails to parse. Fallback: a step with `env: PAT: ${{ secrets.RELEASE_PLEASE_TOKEN }}` writes `configured=true/false` to `GITHUB_OUTPUT`. |
| A3 | A job-level `permissions:` block sets unlisted scopes to none | F3/P3 | Without `actions: read` the gate fails open and never skips. The contract test asserts the permission regardless. |
| A4 | A Mix alias invoking `test` twice runs it once | F8/P5 | If wrong, it is harmless: `cmd` form works either way. |
| A5 | The runs API sort order is newest-first | F3 | Avoided by using `head_sha` + `total_count` |
| A6 | A docs build at NEXT minor fails whenever it fails at the current version | F9 | A version-string-only docs failure would escape until release (`release.yml` hex.publish still builds docs) |

## Open Questions (RESOLVED)

1. **Q1: `inconclusive` red or green?**
   - PITFALLS line 192 said "files nothing, not a failure". With D-03's head_sha skip, a green inconclusive run marks the SHA proven.
   - **Resolved recommendation:** red plus an issue upsert, because it signals that the budget is stale. The planner locks this; if the maintainer prefers green, the gate must instead key on a proof artifact.
2. **Q2: Option A vs B for the live test in `verify-dialyzer`.**
   - **Resolved recommendation:** Option A (the literal D-08: ExUnit test, `MIX_ENV=test`, Postgres service), about +1.5 min in a non-critical-path job.
   - Option B (run the verifier script directly) is cheaper but changes what "it" is, so it is a scope call.
3. **Q3: Browser-full event set.**
   - **Resolved recommendation:** the difference on all events. The coverage stays complete because `ci.yml` runs the rest on every push.
   - If the maintainer wants a periodic full-set proof, add a dispatch input `full_set` (default false), not a nightly default.
4. **Q4: Close #28/#36 now or post-landing?**
   - **Resolved recommendation:** attempt `gh issue close` with a cited run now, from the executor, and hand it to the maintainer if the classifier blocks it. Otherwise the first post-landing green run closes them through the new path, cited in ECON-07.

## Sources

### Primary (HIGH confidence)
- Repo files read this session:
  - `.github/workflows/{ci,flake-detection,browser-full,release}.yml`;
  - `bin/{classify-flake-run,upsert-ci-issue,verify-dialyzer-slice,with-rehearsal-registry,verify-bump-rehearsal}`;
  - `test/test_helper.exs`, `mix.exs`, `playwright.config.ts`, `run-e2e.sh`, `CONTRIBUTING.md`;
  - the contract tests named above;
  - `deps/dialyxir/lib/dialyxir/dialyzer.ex`;
  - the 214 BASELINE, deferred items, tools and raw captures.
- Read-only `gh` probes: `gh secret list`, `gh issue view 28/36`, `gh run list` (flake, browser-full), and `gh api .../workflows/{flake-detection,ci,browser-full}.yml/runs?head_sha=5e78b2f0…`.

### Secondary (MEDIUM confidence)
- [CITED] docs.github.com REST "List workflow runs for a workflow": parameters and status values.
- [CITED] docs.github.com "Using secrets in GitHub Actions": no secrets in `if:`; use job-level env.
- [CITED] docs.github.com "Events that trigger workflows": dispatch and schedule require the file on the default branch.

### Tertiary (LOW confidence)
- A1–A6 above.

## Metadata

**Confidence breakdown:**
- Current state and file:line: HIGH (files read; drift from CONTEXT noted: release job 185-202, not 189-206; D-05 key already fixed; 4-project difference).
- Dominance verdicts: HIGH for mechanical; MEDIUM-HIGH for docs/tarball (mechanism read end-to-end; A6 inference).
- Gate/API design: HIGH on the endpoint (probed); MEDIUM on permission semantics (A3).
- Cost deltas: MEDIUM (arithmetic from 214 run IDs).

**Research date:** 2026-09-27
**Valid until:** 2026-10-27, or until `ci.yml`/`mix.exs` change
