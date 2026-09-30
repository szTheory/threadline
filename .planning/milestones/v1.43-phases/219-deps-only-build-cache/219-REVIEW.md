---
phase: 219-deps-only-build-cache
reviewed: 2026-09-28T17:50:42Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/ci.yml
  - test/threadline/ci_workflow_parity_contract_test.exs
  - CONTRIBUTING.md
  - CHANGELOG.md
  - mix.lock
  - .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 219: Code Review Report

**Reviewed:** 2026-09-28T17:50:42Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

I reviewed the changes since `b3ce4c5b` against the CI-cache risk list: stale or wrong artifacts, first-party code in the cache, key collisions, a save after a failed compile, poisoning, a vacuous contract, and flaky parsing.

**The live `ci.yml` is correct.** I found no defect in the five cached job-lanes:
- Every `_build` restore uses an exact key with no `restore-keys`.
- In each job, the save comes after `mix deps.compile` and the unconditional `rm -rf "_build/${MIX_ENV:?}/lib/threadline"`, and before `mix compile --warnings-as-errors`.
- The save has only the implicit `success()` guard and uses the restore's `cache-primary-key`.
- The root and example keys differ in the `-root-` / `-example-` segment. The min lane differs by its OTP and Elixir versions. The key that pgbouncer shares with the current lane is shared on purpose.

I also checked these runtime assumptions against the source:
- `mix deps.compile --skip-local-deps` exists on 1.17.3.
- The consolidation path sits under `lib/<app>`.
- No root test builds into `examples/threadline_phoenix/_build` before the example restore.
- `run-e2e.sh` exports `MIX_ENV=test`, so the example `_build/test` it uses is the cached one.
- `config/test.exs` reads env vars only for `:threadline` runtime config, so moving the pgbouncer compile out of the bootstrap `env:` is safe.
- `mix deps.update mint` does unlock `hpax` and reaches 1.11.0. I reproduced this in a scratch project, so the CHANGELOG upgrade advice is sound.

**The defects are in the contract test.** It is not vacuous: every listed mutation control bites. But it only validates the first `_build` restore per project and the first contiguous D-07 window. I proved four mutations pass the full `build_cache_errors/2` against the live tree, each producing zero new errors. I ran them from a scratch copy of the test module, now deleted:
1. a second root `_build` save after `mix compile --warnings-as-errors`;
2. a second example save after `mix verify.capture`;
3. a second `_build` restore that carries `restore-keys:` and a non-exact key;
4. a step-level `MIX_ENV: dev` override on the deps compile.

These are exactly the "first-party code cached" and "stale artifacts served" classes the contract claims to guard.

## Warnings

### WR-01: The contract validates only the first `_build` restore and first save window; a later restore with `restore-keys`, or a save after the first-party compile, passes

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1938-1955` (also `1978`, `2060`)

**Issue:** `project_cache_errors/2` finds the first `{:restore_build, project, _}` with `Enum.find_index`. It then checks only that restore:
- `restore_errors/3`: the restore action, `restore-keys`, the key segments and forbidden inputs;
- `order_errors/5`: the `length(expected)`-step window starting at that restore.

`save_errors/3` iterates every save, but it checks only the key, the path and the `if:`, never the position. Nothing counts restores or saves per project. Proven against the live workflows, with zero added errors each time:

- Inserting a copy of `Save deps-only build cache` (same guard, key and path) after `Compile (warnings as errors)` in `verify-test`. That save would archive `_build/test/lib/threadline` (the code under test). Today it would normally no-op with "cache already exists" behind the first save. But if the first save fails to upload or reserve, which actions/cache downgrades to a warning, the second save stores first-party BEAMs under the deps-only key.
- Inserting a second example save after `Regenerate Tier A capture` in `verify-capture`. This has the same failure mode, and it is more likely here because three jobs race on the example key.
- Inserting a second `actions/cache/restore@v5` for `_build/${{ env.MIX_ENV }}` with `key: ubuntu-24.04-otp-x` and `restore-keys: ubuntu-24.04-` after the compile. This is the exact CargoSense#13 stale-artifact footgun that CONTRIBUTING says "a `_build` cache never has". The contract accepts it in any allowlisted job.

**Fix:** Make every restore and save subject to the rules, and pin their count and position:
```elixir
defp project_cache_errors(job, project) do
  restores = for {{:restore_build, ^project, s}, i} <- Enum.with_index(job.steps), do: {s, i}
  saves    = for {{:save_build, ^project, s}, i} <- Enum.with_index(job.steps), do: {s, i}
  count_errors =
    [{length(restores) == 1, "exactly one #{project} `_build` restore"},
     {length(saves) == if(job.mode == :save, do: 1, else: 0),
      "exactly one #{project} `_build` save inside the D-07 window"}]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(fn {_, what} -> build_cache_error({job.path, job.id, "-"}, "rule=cache-count", what, "...", "...") end)
  # ...then run restore_errors/3 over EVERY restore (not just the first)...
  count_errors ++ existing_checks
end
```
Add mutation controls for the three cases above (`rule=cache-count` / `rule=restore-keys`).

### WR-02: A step-level `MIX_ENV` override inside a cached block passes the contract

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:2212-2242`

**Issue:** `job_env_errors/2` checks only that the job header carries a literal `MIX_ENV:`. The contract never looks at step-level `env:` blocks. I added `env:\n  MIX_ENV: dev` to `Compile dependencies on build cache miss` in `verify-test`, and it produced zero errors. With that override:
- the deps compile into `_build/dev`;
- the save archives `_build/test` (still keyed `...-test-...`), which holds nothing useful;
- `mix compile` then builds every dependency cold in test.

Worse, the same override on the consumer or compile step would make those steps read a different tree than the one the key describes. D-09 exists precisely to pin the env that the key and path name. `compiler_env_line?/1` already scans the whole block for compiler flags, so the same scan can cover `MIX_ENV`.

**Fix:** In a cached job, reject any `MIX_ENV:` line other than the job-level one. For example, scan `job_steps(block)` for `~r/^\s+MIX_ENV:/m` on uncommented lines and emit `rule=job-mix-env` ("a step overrides MIX_ENV inside a cached job"). Add a mutation control for it.

### WR-03: The poisoned-cache runbook's durable fix turns the contract red, and the runbook does not say so

**File:** `CONTRIBUTING.md:829-831`; `test/threadline/ci_workflow_parity_contract_test.exs:474`, `484`, `1656`, `1680`

**Issue:** Runbook step 3 says to "bump `build-v1` to `build-v2` in every `_build` key in `.github/workflows/ci.yml` (and here)". The contract hard-codes the literal `build-v1` in four places:
- `@build_key_segments` (`"-build-v1-"`, root and example), so the change fails `rule=key-segment` on every restore;
- `@build_cache_doc_needles`, so it fails `rule=doc-contributing`;
- `ci_cache_comment_errors/1`, so it fails `rule=doc-ci-comment`.

A maintainer following the incident runbook during a poisoned-main-cache incident gets a red `Run test suite` on the fix PR. The runbook never mentions the test file, even though D-04 calls the bump "the durable recovery from a poisoned or wrong entry".

**Fix:** Pull the version into one attribute, `@build_key_version "build-v1"`, and derive the segment and needles from it. Then extend runbook step 3: "...and update `@build_key_version` in `test/threadline/ci_workflow_parity_contract_test.exs`." Optionally add a control that bumps all three texts together and asserts the result is clean.

## Info

### IN-01: The CHANGELOG Unreleased entry now contradicts itself about the scope of the security fix

**File:** `CHANGELOG.md:27-46`

**Issue:** The intro still says the release "refreshes a locked dependency to clear a published security advisory" (singular). The entry now lists two `mint` bullets: "bumped to 1.10.1" and then "bumped to 1.11.0". Four advisories are cleared in total. The file's own header asks entries to "write for an upgrader". An upgrader reads two different target versions for the same package, and the lock ships only 1.11.0.

**Fix:** Merge the bullets into one: "`mint` bumped to 1.11.0 (with `hpax` 1.1.0), fixing EEF-CVE-2026-82672, -91043 (high), -92103 and -94194 ...". Pluralize the intro sentence.

### IN-02: `remeasure-219.py critical-path` crashes on a run with no successful voting job

**File:** `.planning/phases/219-deps-only-build-cache/tools/remeasure-219.py:394-401`

**Issue:** `all219` deliberately keeps failed runs: `runs_219` drops only `cancelled` runs. `sub_critical_path` calls `min(...)` over `jobs` and `max(...)` over `voting` without guarding either. So a run where every non-`ci-required` job failed, or where no job ran, raises `ValueError` and aborts the whole table.

**Fix:** Skip the run when `jobs` or `voting` is empty. Count it separately, for example: `if not jobs or not voting: skipped.append(r["run_id"]); continue`.

### IN-03: The `verify-test` save and compile guards accept a form with no lane guard, which would break the min lane

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:2097-2100`

**Issue:** `cache_miss_guards("verify-test", id)` accepts the bare `steps.<id>.outputs.cache-hit != 'true'` for the example block too. On the min lane the example restore and `deps.get` are skipped, so `cache-hit` is empty and a bare guard evaluates true. The example `deps.compile` would then run against an unfetched tree, and the save would get an empty `key`. It fails loudly rather than silently, but the contract blesses a config that turns `Run test suite (min)` red.

**Fix:** For `{verify-test, :example}`, accept only `matrix.lane == 'current' && steps.example-build-restore.outputs.cache-hit != 'true'`.

### IN-04: The root removal step interpolates `${{ }}` directly into `run:`, unlike the example step

**File:** `.github/workflows/ci.yml:405`, `898`

**Issue:** The root `Remove own build` step splices `steps.build-restore.outputs.*` straight into the shell script. The example step passes the same outputs through `env:` (`EXAMPLE_BUILD_KEY` / `EXAMPLE_BUILD_HIT`). The inputs come from `hashFiles` and the setup-beam outputs, so this is not exploitable today. It is the pattern GitHub's hardening guide warns against, and it is inconsistent within the same phase.

**Fix:** Mirror the example step: pass `BUILD_KEY` / `BUILD_HIT` via `env:` and `echo "THREADLINE_BUILD_CACHE=${state} key=${BUILD_KEY}"`.

---

_Reviewed: 2026-09-28T17:50:42Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
