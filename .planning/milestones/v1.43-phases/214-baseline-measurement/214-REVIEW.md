---
phase: 214-baseline-measurement
reviewed: 2026-09-26T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .planning/phases/214-baseline-measurement/tools/check-baseline-complete.py
  - .planning/phases/214-baseline-measurement/tools/check-citations.py
  - .planning/phases/214-baseline-measurement/tools/check-project-baseline.sh
  - .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh
  - .planning/phases/214-baseline-measurement/tools/inert-share.py
  - .planning/phases/214-baseline-measurement/tools/measure-base02.sh
  - .planning/phases/214-baseline-measurement/tools/measure-local.sh
  - .planning/phases/214-baseline-measurement/tools/summarize-ci.py
  - .planning/phases/214-baseline-measurement/tools/verify-phase.sh
findings:
  critical: 0
  warning: 17
  info: 8
  total: 25
status: issues_found
---

# Phase 214: Code Review Report

**Reviewed:** 2026-09-26
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

I reviewed the Phase 214 measurement and verification tools against the committed raw data. I ran only local, read-only commands: `summarize-ci.py` on the raw data, the checkers on their fixtures, the allowlist proof greps, and `git grep`. I did not run any `gh` command.

What I verified as correct:

- **Percentiles.** The nearest-rank math (`rank()`, `-(-q*n // 100)`) is correct ceil arithmetic. So is `fmt_min`'s half-up rounding on tenths.
- **Job rows.** The per-job rows regenerated from `raw/ci` match `214-BASELINE.md` exactly (0 of 38 rows differ).
- **Allowlist proofs.** All 23 allowlist proof commands print nothing at the current HEAD.
- **Run attempts.** No collected run has `attempt > 1`, so the dedup and latest-attempt handling does not change any figure today.
- **GitHub access.** Every `gh` call in the tools is read-only (`run list`, `run view`, `release list`, `pr list/view`, and GET-only `gh api` with no `-f`/`-F`/`--input`/`-X`).

None of the currently published figures is provably wrong, so there is no BLOCKER. The weak point is the checkers. Several can pass vacuously or fail open:

- the citation rule
- the write-gh grep
- the self-tests that only check exit codes
- substring fact matching
- allowlist proofs that are never re-run
- a hex.audit failure that reads as "0 advisories"
- stale facts that survive re-measurement

The measurement scripts also have definitions that disagree with each other: the flake fast-failure duration, the xref "runtime" label, and a tracked-path count that includes the phase's own files.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Write-capable-gh gate misses most write forms and cannot see array-built invocations

**File:** `.planning/phases/214-baseline-measurement/tools/verify-phase.sh:62-63`
**Issue:** `GH_WRITE` only matches a fixed list of subcommands, `--method`, and `-X (POST|...)` with a space. It does not match:
- `gh api -f/-F/--field/--raw-field/--input`, all of which switch `gh api` to POST
- `gh release create/edit/delete/upload`, `gh pr close/edit/review/ready`, `gh run delete`, `gh workflow enable/disable`, `gh secret`, `gh label`, `gh repo`
- `-XPOST`, or a lowercase `-X post`

It also cannot see calls built from an array. `collect-ci-runs.sh:151` runs `gh "${LIST_ARGS[@]}"`, and `measure-base02.sh:47` runs `$cmd`, so the gate never inspects the arguments those calls actually get. The PASS line claims more than the grep can prove.
**Fix:** Build an allowlist instead of a denylist. Every `gh` invocation line must match `gh (run (list|view)|api|release list|pr (list|view))`. Every `gh api` line must not contain `-f|-F|--field|--raw-field|--input|-X|--method`. Array- or variable-built `gh` calls fail the gate unless they carry an explicit `# gh-readonly:` annotation whose argument array is also grepped.

### WR-02: Citation checker lets uncited figures through

**File:** `.planning/phases/214-baseline-measurement/tools/check-citations.py:28,34,57`
**Issue:** I confirmed this with a probe. The line `The suite takes 12-45 minutes, about 1.25 times slower.` plus `Wall grew from 3.1.0 to 1.40 min.` exits 0. Three things cause it:
- The `MM-DD` exemption (`\b\d{2}-\d{2}\b`) removes any hyphenated two-digit range.
- `\bv?1\.\d{2}\b` removes any `1.xx` decimal figure.
- The version pattern removes any `x.y.z`.

Also, one `run NNNNNNNN` or one backticked command anywhere on a line cites every other figure on that line (line 57).
**Fix:** Apply the `MM-DD` exemption only where the context is a date (for example, preceded by `→` or followed by a date-like token). Limit the milestone exemption to `v1.\d\d` or `milestone 1.\d\d`. Require the version exemption to be preceded by `v` or followed by a non-unit word. Document the one-cite-per-line rule explicitly, or require a cite per table cell.

### WR-03: Self-tests and the negative fixture only check exit codes, so a crash counts as success

**File:** `.planning/phases/214-baseline-measurement/tools/check-baseline-complete.py:136-150`; `check-citations.py:70-79`; `verify-phase.sh:51-52`
**Issue:** `incomplete.md` and `uncited.md` are "expected to fail". The `project-bad-streak.md` negative test is wrapped in `run_fails`. All three pass on any non-zero exit: a missing fixture, a Python traceback (`FileNotFoundError` gives exit 1, which I confirmed with `check-baseline-complete.py /nonexistent`), a missing `facts.json`, or a failed `git show ff8e53e9`. So a broken checker still passes its own negative self-test.
**Fix:** Also assert on the reason:
- the expected `INCOMPLETE:`, `uncited figure:`, or `MISSING: flake_fast_fail_first` lines are present
- stderr is empty (no traceback)
- the fixture file exists before it is run

### WR-04: BASE-02 fact checks use unanchored substring matching and have fail-open branches

**File:** `.planning/phases/214-baseline-measurement/tools/check-project-baseline.sh:26-30,40-42,65`
**Issue:**
- `grep -qF -- "$2"` matches substrings. `2 advisories` is satisfied by `12 advisories`, `5 runtime cycles` by `15 runtime cycles`, and `N tracked files` by `1N tracked files`.
- The package loop reads from `< <(jq -r '.root_advisory_packages[]' ...)`. If the key is missing or not an array, jq fails inside the process substitution, the error is ignored, and no package is checked.
- The whole Out-of-Scope re-check is skipped when `^### Out of Scope` is absent from the target. Deleting or renaming the heading therefore turns that check into a silent pass.
**Fix:** Match on word boundaries (`grep -qE -- "(^|[^0-9])$(escape "$2")"`). Assert that `jq -e '.root_advisory_packages | type == "array"'` succeeds before the loop. When the target is `.planning/PROJECT.md`, treat a missing `### Out of Scope` heading as `MISSING` rather than skipping.

### WR-05: `ci_job_ids` silently truncates the job list at any column-0 line

**File:** `.planning/phases/214-baseline-measurement/tools/check-baseline-complete.py:56-57,116-129`
**Issue:** The parser `break`s at the first line matching `^\S` after `jobs:`. That includes a column-0 `# comment`, which is legal YAML inside the `jobs:` map. Every job after such a comment is dropped from the "must have a pull_request and a push row" check. The only guard is for zero parsed ids. Today it parses all 14 jobs, but this is a latent fail-open. Separately, a matrix job only needs one row per event: `verify-test` passes if only `(current)` is reported and `(min)` is missing.
**Fix:** Skip lines matching `^\s*#` and blank lines before the `^\S` break. Cross-check the parsed count against `summarize-ci.workflow_jobs`. Require one row per matrix lane observed in the raw data (for example, reuse `summarize-ci.expected_names`).

### WR-06: Inert-path allowlist "proofs" are never executed by any gate

**File:** `.planning/phases/214-baseline-measurement/tools/inert-share.py:49-62`; `verify-phase.sh:53-54`
**Issue:** `load_allowlist` only checks that the text ` # proof: ` is present. Nothing runs the proof command or checks that its output is empty. `verify-phase.sh` runs only `--self-test`. So "fail-closed, proven allowlist" is enforced only at authoring time. Any entry with a syntactically present but wrong proof is admitted, and drift (a new test that reads `.planning/STATE.md`) is never detected. (All 23 proofs happen to be empty today; I ran them.)
**Fix:** Add a `--verify-proofs` mode that runs each proof (restricted to the `git grep` prefix, via `subprocess` without a shell) and fails on any non-empty output. Call it from `verify-phase.sh`.

### WR-07: Renamed files are classified by their new path only

**File:** `.planning/phases/214-baseline-measurement/tools/inert-share.py:13-14,79-86`
**Issue:** The file lists come from `pulls/<n>/files --jq '.[].filename'`, which drops `previous_filename` for renames. A PR that renames `lib/x.ex` or `test/fixtures/...` into `.planning/research/` is classified as inert, even though it removes a shipped or tested path. This contradicts the documented fail-closed rule.
**Fix:** Collect with `--jq '.[] | .filename, (.previous_filename // empty)'` and classify on the union of both names. Adjust the `changedFiles` count check accordingly (or record renames separately).

### WR-08: Flake fast-failure streak uses `updatedAt - createdAt`, which disagrees with summarize-ci's definition

**File:** `.planning/phases/214-baseline-measurement/tools/measure-base02.sh:44,68`
**Issue:** The BASE-02 streak (the facts published in PROJECT.md) measures duration as `updatedAt - createdAt`. That includes queue time. `updatedAt` also moves whenever the run is touched again: a re-run, log deletion, or an annotation. `summarize-ci.py` `regime()` classifies the same runs by job wall time (first job start to last job end). The two "fast failure < 10 min" definitions can disagree on the same run, so the streak boundaries can differ between the two outputs.
**Fix:** Derive the streak from `raw/ci/runs/<id>.json` with `summarize-ci.run_wall`, the same definition as the regime table. Alternatively, fetch `run_started_at` and use the jobs' `completed_at`. Record which definition is used in `facts.commands`.

### WR-09: `merge_facts` never removes keys, so a re-measurement can leave stale facts that the checker then validates

**File:** `.planning/phases/214-baseline-measurement/tools/measure-base02.sh:35-41,74-75`
**Issue:** `jq '. * $n'` deep-merges. When the streak comes out empty, the step emits only `{"flake_fast_fail_count": 0}`. The old `flake_fast_fail_first/last/_run` keys stay in `facts.json`, and `check-project-baseline.sh` keeps asserting them against PROJECT.md. The same applies to any step whose output keys shrink.
**Fix:** Have each step delete its own key namespace before merging, e.g. `del(.flake_fast_fail_first, .flake_fast_fail_last, ...) * $n`. Alternatively, emit explicit `null` values for every key, which `fact()` (`jq -e`) will then reject.

### WR-10: A failed `mix hex.audit` is recorded as "0 advisories"

**File:** `.planning/phases/214-baseline-measurement/tools/measure-base02.sh:113-118,122-135,175-182`
**Issue:** The script writes the exit code to the text file but never checks it. `parse_audit` returns `[]` for any output without advisory lines. That includes a compile or deps error, a Hex auth or network failure (the script already filters an "authentication session has expired" line), or a missing `mix`. `root_advisory_count` and `bench_high_count` would then silently become 0.
**Fix:** Accept the output only if it contains `Advisories:` (with exit 1) or the explicit no-advisories message (with exit 0). Otherwise exit non-zero and do not merge any facts.

### WR-11: Tracked machine-local path count includes the phase's own files and is not reproducible

**File:** `.planning/phases/214-baseline-measurement/tools/measure-base02.sh:199-212`
**Issue:** `git grep` scans all of `.` at HEAD. At the measured SHA it already counted `214-01/02/03-PLAN.md` (in `raw/base02/tracked-paths-HEAD.txt`, lines 376-378). Re-running at the current HEAD would add `raw/base02/facts.json`, `tools/measure-base02.sh` (its own `PATH_HOME_RE` literal matches `)~/`), `tools/verify-phase.sh` and `214-02-SUMMARY.md` (I confirmed this with `git grep`). So `tracked_path_files_head` goes up every time the measurement is committed.
**Fix:** Exclude the phase directory with a pathspec: `-- . ':!.planning/phases/214-baseline-measurement'`. Record the exclusion in `commands`. Alternatively, report the count both with and without the phase directory.

### WR-12: `xref_runtime_cycles` counts cycles over all edge labels, not runtime-only

**File:** `.planning/phases/214-baseline-measurement/tools/measure-base02.sh:273,281,284`
**Issue:** `mix xref graph --format cycles` without `--label` reports cycles over compile, export and runtime edges together. The fact is named and published as "N runtime cycles" (checked as `"$(fact .xref_runtime_cycles) runtime cycles"`). If the published number is meant to be runtime-only, its label is wrong.
**Fix:** Either use `--label runtime` for the runtime figure, or rename the fact and its PROJECT.md wording to "cycles (all labels)".

### WR-13: The INT/TERM trap in the cold-PLT step lets the script continue, so warm-PLT timings get recorded as "cold"

**File:** `.planning/phases/214-baseline-measurement/tools/measure-local.sh:146-155`
**Issue:** With `trap restore_plt EXIT INT TERM`, a Ctrl-C during the `cold` run kills the child, runs `restore_plt` (the warm PLT goes back into place), and then bash *continues*. `cold_raw` and `mix dialyzer --plt` then run against the restored warm PLT, which `--plt` may also modify. The post-check passes, and `live-dialyzer.json` is written with warm figures under the cold labels.
**Fix:** Use a separate handler for signals: `trap 'restore_plt; exit 130' INT TERM` and `trap restore_plt EXIT`.

### WR-14: The workflow-cost regime counts failures with no measurable wall as ">= 10 min", and crashes on an empty window

**File:** `.planning/phases/214-baseline-measurement/tools/summarize-ci.py:437-444,465-466`
**Issue:** `regime()` returns `"failure (>= 10 min)"` whenever `wall is None`, i.e. no job occupied a runner (startup_failure, workflow file error, all jobs skipped). Those are the fastest failures, yet they are classified as long ones. `timed_out`, `startup_failure` and `action_required` conclusions are also folded into "failure". Separately, `min(runs, ...)` raises `ValueError` if the manifest entry has zero runs (possible with `--min 0`), instead of printing the documented `n=0 — not measured`. Neither case occurs in today's data (the regimes sum to 17+12+2=31).
**Fix:** Add a `"failure (no job ran)"` regime for `wall is None` and keep the other non-success conclusions as separate names. Guard `if not runs:` and print the n=0 row.

### WR-15: `gh run list --limit 200` silently caps windowed collections

**File:** `.planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh:124,153-156`
**Issue:** With `--target 0` or `--target 200` (the documented flake usage), a window with more than 200 matching runs is truncated at the list call, and nothing reports it. `COUNT` looks complete. `measure-base02.sh:44` uses the same cap for the flake streak history, so an older streak start would be cut off silently.
**Fix:** When `length == 200`, either paginate (`gh api` with `created` and page parameters) or `die "list hit --limit; window may be truncated"`.

### WR-16: Cached run files are never invalidated after re-runs, and runner-minutes ignore earlier attempts

**File:** `.planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh:163-164`; `summarize-ci.py:71-73,328-331`
**Issue:** A cached `runs/<id>.json` is reused whenever it exists. If a run was later re-run, the manifest selects it by its new conclusion (for example, `--status success`), but the cached jobs and `attempt` come from the old attempt. The jobs endpoint also returns only the latest attempt, so the runner-minutes for PRs, pushes and releases exclude minutes billed by earlier attempts. That makes them a lower bound, not a total. There are no `attempt > 1` runs in the raw data today, so this is latent.
**Fix:** Refetch when the listed `attempt` differs from the cached `attempt`. For runner-minutes, fetch `runs/<id>/attempts/<n>/jobs` for every attempt and sum them, or label the figure as "latest attempt only".

### WR-17: No gate checks that the doc's figures still match regenerated output

**File:** `.planning/phases/214-baseline-measurement/tools/verify-phase.sh:41-58`
**Issue:** The gate checks that citations are *present* and that `summarize-ci jobs --min 10` succeeds. It never compares the doc's numbers with what the cited commands produce. A hand-edited or stale row in `214-BASELINE.md` passes every check. (I diffed the job rows by hand and they match today. The wall, critical-path, runner-minutes, workflow-cost and inert-share lines were not diffed.)
**Fix:** For every backticked `python3 .../summarize-ci.py ...` or `inert-share.py ...` command in the doc, run it and assert that each output line appears verbatim in the doc.

## Info

### IN-01: "runs on N of M pushed SHAs" counts runs, not SHAs

**File:** `.planning/phases/214-baseline-measurement/tools/summarize-ci.py:385-389`
**Issue:** `len(s)` is the number of runs of that workflow. If a workflow runs twice on one SHA, the text overstates its coverage.
**Fix:** Count distinct SHAs, e.g. `len({r["head_sha"] for r in ...})`.

### IN-02: `expected_names` aliases `names` and `observed`

**File:** `.planning/phases/214-baseline-measurement/tools/summarize-ci.py:182-188`
**Issue:** `observed = names` binds both names to the same set, so the declared names added in the loop are visible to later `any(...)` checks. This is harmless today, but fragile.
**Fix:** Use `observed = set(names)`.

### IN-03: The push unit attributes `workflow_run` runs whatever their trigger

**File:** `.planning/phases/214-baseline-measurement/tools/summarize-ci.py:324,364`
**Issue:** Branch/Community/Environment Protection run on `workflow_run` when CI completes on main. That includes `workflow_dispatch` CI runs on main (there are 6 in the raw data). Their `workflow_run` descendants on a pushed SHA would be counted as push cost, while the dispatch run itself is excluded.
**Fix:** Also collect `triggering_workflow_run`/`workflow_run.event`, and keep only descendants of `push` runs.

### IN-04: The cross-layer xref edge check passes on any co-occurrence of the two files

**File:** `.planning/phases/214-baseline-measurement/tools/measure-base02.sh:278-279`
**Issue:** It is true if both file names appear anywhere in the output, even in different cycles.
**Fix:** Parse the output per cycle block and require both files in the same cycle.

### IN-05: `scrub` substitutes unescaped regexes and the bare username

**File:** `.planning/phases/214-baseline-measurement/tools/measure-local.sh:43-46`; `measure-base02.sh:29-32`
**Issue:** `ROOT` and `HOME` are used as sed regexes without escaping, and a `#` in either path breaks the sed expression. `s#$(whoami)#<user>#g` rewrites every occurrence of a short username inside unrelated tokens in captured test output.
**Fix:** Escape regex metacharacters, and anchor the username replacement to path contexts (`/Users/<name>/`, `/home/<name>/`).

### IN-06: The CI step comparison uses n=1, and the test DB password is hard-coded

**File:** `.planning/phases/214-baseline-measurement/tools/measure-local.sh:64,205`
**Issue:** `ci-test-steps.json` uses a single push run as the CI comparison point. `PGPASSWORD=postgres` is hard-coded (it is the local dev default, so the risk is low).
**Fix:** Label the capture as a single sample, or take the median over the manifest runs. Allow `PGPASSWORD="${PGPASSWORD:-postgres}"`.

### IN-07: The flake timeout awk takes the first `timeout-minutes:` in the job block

**File:** `.planning/phases/214-baseline-measurement/tools/measure-base02.sh:50-54`
**Issue:** If a step-level `timeout-minutes` appears before the job-level one, or the job-level one is removed, the step value is reported as the job timeout.
**Fix:** Match only the job-level indentation: `/^    timeout-minutes:/`.

### IN-08: Release-cycle SHAs miss force-pushed release-please commits

**File:** `.planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh:82-88`
**Issue:** `gh pr view --json commits` returns only the final commit list. release-please force-pushes its branch, so CI runs on superseded head SHAs are not counted, and the release-cycle totals are a lower bound.
**Fix:** Also list `pull_request` runs whose `headBranch` is the release-please branch within the PR's open window, or state the lower-bound caveat in the doc.

---

_Reviewed: 2026-09-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
