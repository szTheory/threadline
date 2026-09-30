# Phase 219: Deps-Only Build Cache - Research

**Researched:** 2026-09-28
**Domain:** GitHub Actions dependency caching for Mix `_build` (CI config + text-based ExUnit contract tests + CI measurement)
**Confidence:** HIGH for the edit map, contract seams and Mix behaviour (read in source this session); MEDIUM for measurement expectations (inference, n=1 log split)

## Summary

The discuss-phase research (r1–r4) already settled the design: key shape, Mix semantics, the save policy, the budget and the contract design. D-01..D-26 lock it. This document covers what the planner still needs:
- the exact current text and line numbers of every edit point;
- how the example-app build inside `mix verify.example` and `run-e2e.sh` interacts with a pre-populated deps-only `_build`;
- every existing test that pins text in the jobs being edited;
- the measurement tool seam;
- a Nyquist test map.

The re-checks confirmed the discuss research:
- **`--force` does not reach deps.** Elixir 1.17.3 `deps.loadpaths.ex:87` calls `Mix.Tasks.Deps.Compile.compile(compile)` with no options.
- **`--skip-local-deps` exists** on 1.17.3 (`deps.compile.ex:38`, `:46`, `:352`) and on 1.15.8.
- **The example's env-driven config is not a dep-compile input.** `THREADLINE_E2E` only configures `:threadline`/`:threadline_phoenix` or is read in `runtime.exs`, and both apps are removed before every compile.
- **The resolved key segments render as `OTP-27.3.4.15` and `v1.17.3-otp-27`** (live `gh cache list`).
- **Cache usage** is 57 entries, 636,919,006 bytes (live `gh api .../actions/cache/usage`).

No job is added, removed or renamed, so the same-commit roster rule does not trigger.

Four facts are not visible from CONTEXT, and each would bite the executor:
1. **Example steps in the matrix need a lane guard.** In `verify-test` they must carry `if: matrix.lane == 'current'`, so the save `if:` becomes a conjunction. The contract must accept `matrix.lane == 'current' && steps.<id>.outputs.cache-hit != 'true'` on the example save and deps.compile steps, and still reject `always()`, `failure()` and `||`.
2. **The OS-family mutation needle must survive.** An existing control mutates the literal `      # CACHE KEY CONTRACT` line in ci.yml and asserts `mutated != live`. The D-19 comment rewrite must keep that exact 6-space-indented prefix line.
3. **Check D-17 at the key-line level, not as a substring.** `release.yml` contains the substrings `cache` ("runner tool cache", `git diff --cached`) and `workflow_run` (`data.workflow_runs`, line 364). The rules must use key-anchored regexes on uncommented lines and must parse the `on:` block.
4. **`verify-pgbouncer-topology` has a step in the way.** Its `Wait for Postgres and PgBouncer` step sits between `Cache deps` and the combined compile step, so it must move to keep D-07 contiguity.

**Primary recommendation:** Use three plans.
1. The pure `build_cache_errors/2` function, with fixture-driven mutation controls. The live `_build` refute stays untouched, so the tree stays green.
2. One atomic commit containing: all YAML edits, the no-optional deps-cache removal, the ci.yml comment rewrite, the CONTRIBUTING `### Dependency build cache` section, and the flip of the live assertion to `build_cache_errors(all_workflows(), contributing) == []`.
3. The measurement: copy the 218 tools, add `remeasure-219.py`, a push/dispatch checkpoint under the maintainer grant, then `219-REMEASURE.md`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Already locked upstream (carry forward, do not re-open)
- ROADMAP Phase 219 success criteria 1–4 and REQUIREMENTS CACHE-01 are the contract:
  - split `actions/cache/restore@v5` + `actions/cache/save@v5`;
  - exact keys;
  - no `restore-keys` on any `_build` cache;
  - the project's own build is removed;
  - `verify-compile-no-optional` and the `release.yml` publish path stay cache-free;
  - the parity contract test asserts all of it;
  - the before/after measurement cites run IDs.
- The milestone's cross-cutting invariants apply to every commit:
  - **Same-commit roster rule.** Any add, remove or rename of a `verify-*` job updates `ci.yml`, CONTRIBUTING's job table and roster, `ci-required` `needs:` and the topology contract test in the same commit.
  - Job `id:`s are immutable, and `CI required` stays byte-exact.
  - **No laundering:** no trigger-level `paths:`, no static `allowed-skips`, no `continue-on-error` on a voting job.
  - Stage explicit file lists. Never `git add .planning/`.
- The Phase 216 cache-key contract (ci.yml, D-19) still applies:
  - the runner label is a literal;
  - the OTP and Elixir segments come from `steps.beam.outputs.*`;
  - the OS-family context value is never used. The anti-regression grep now covers all workflows (218 D-05).

#### Key shape
- **D-01: Root key.**

  ```
  ubuntu-24.04-otp-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-build-v1-root-${{ env.MIX_ENV }}-full-${{ hashFiles('mix.lock') }}-${{ hashFiles('config/**/*.exs') }}
  ```

  - In the verify-test matrix, `${{ matrix.runner }}` leads instead of the literal runner label.
  - The planner may adjust separators but must keep every segment.
- **D-02: Example key.** Same shape, with `example` in place of `root`:

  ```
  …-build-v1-example-${{ env.MIX_ENV }}-full-${{ hashFiles('examples/threadline_phoenix/mix.lock') }}-${{ hashFiles('examples/threadline_phoenix/config/**/*.exs') }}
  ```

  - **Leave out the root `mix.lock`.** The example resolves every dependency from its own lock. Threadline itself is a path dep and is always removed (D-07). Including the root lock would force a cold build on the critical-path job at every root dependency bump.
  - Leave out root `config/`, because the example never loads it.
- **D-03: Config stays in the key; `mix.exs` does not.**
  - Config is included because Mix only tracks `Application.compile_env` reads (value-based). A dependency that calls `Application.get_env` or `System.get_env` at compile time is invisible to Mix, so the key is the only guard.
  - `runtime.exs` is included for glob simplicity. Config changed in 2 of 479 commits on main, so the cost is small.
  - `mix.exs` changes in about 22 of 479 commits, because release-please bumps `@version`. The lock plus MIX_ENV already fix the dependency tree, and `build-v1` is the fallback.
  - Never use `**/mix.lock`: it picks up the bench, fixture and regenerated hex_evaluator locks.
- **D-04: A literal `build-v1` version segment exists from the start.**
  - Bumping it in a normal PR is the durable recovery from a poisoned or wrong entry. It is reviewable, and it needs no privileged `gh cache delete`.
  - Ash uses the same approach (`build-3`).
- **D-05: `full` is currently the only profile value.**
  - `no-optional` is a reserved token that the contract test forbids, because the no-optional job never caches.
- **D-06: Things that stay out of the key:**
  - `.tool-versions`: redundant with the resolved outputs, and its `nodejs` line would cause false misses;
  - Hex and rebar3 versions;
  - `--warnings-as-errors`, which never reaches deps.

  The full resolved OTP version is required, because Mix records only the OTP major version per dep.

#### Step order and removal (the correctness core)
- **D-07: Every cached project runs a contiguous sequence of named steps:**
  1. restore `_build`;
  2. restore deps (for the example, cache `examples/threadline_phoenix/deps` together with its `_build/test/lib`);
  3. `mix deps.get`;
  4. `mix deps.compile`, only when the `_build` restore missed. The example uses `--skip-local-deps`;
  5. `rm -rf` the project's own directories, unconditionally;
  6. save with the matching restore's `cache-primary-key`, `if: cache-hit != 'true'`;
  7. `mix compile …`.

  The removal comes before both the save and the compile:
  - `deps.compile` builds the example's path dep (the code under test) and recreates a stub `lib/threadline/.mix`. Removing before the save keeps it out of the cache.
  - Removing before the compile means a restored stale copy can never be served.
- **D-08: What to remove.**
  - Root: `rm -rf "_build/${MIX_ENV:?}/lib/threadline"`. The consolidated protocols and the root build records live inside that folder on Elixir 1.15.8, 1.17.3 and 1.20.2 (verified in Mix source). There is no `_build/$ENV/.mix`.
  - Example: `examples/threadline_phoenix/_build/test/lib/threadline` and `.../lib/threadline_phoenix`.
  - The `:?` form makes an unset MIX_ENV fail loudly instead of silently removing nothing.
- **D-09: Every cached job sets a literal job-level `MIX_ENV`.**
  - Today five jobs leave it unset: format, credo, no-optional, example-browser and capture. In those, `_build/$MIX_ENV/…` becomes `_build//…`, and `preferred_envs` can compile into `_build/test`.
  - The cache path is env-scoped: `_build/${{ env.MIX_ENV }}`.
- **D-10: Split the combined `deps.get`/`compile` shell steps into separate named steps** where a cached job needs them:
  - the `run: |` step in `verify-pgbouncer-topology`;
  - the example build, which `mix verify.example` runs inside one bash string (mix.exs ~307-316) and which needs explicit pre-steps.

  The failing-prone compile and test steps stay separately named in the CI UI.

#### Coverage
- **D-11: The smallest honest set: 3 keys used by 5 job-lanes.**

  | Job | Cache |
  |---|---|
  | `verify-test` current lane | root test key and example key; saves on a miss |
  | `verify-test` min lane | its own root test key, from its own setup-beam outputs; saves on a miss |
  | `verify-pgbouncer-topology` | restore only, of the current lane's root test key; no save |
  | `verify-example-browser` | example key only; saves on a miss. The root project is never compiled here |
  | `verify-capture` | example key only; saves on a miss |

  - pgbouncer's restore-only adds no key and removes a save race.
  - The example-key jobs can race to save the same key. The loser gets a harmless "cache already exists / unable to reserve" warning, which is documented in CONTRIBUTING (D-19).
- **D-12: Explicitly not cached,** with reasons recorded in the contract allowlist and CONTRIBUTING:
  - verify-credo and verify-dialyzer: dev env, not test jobs, off the critical path, and dialyzer switches env mid-job;
  - format, deps-audit, repo-hygiene and release-shape: they compile nothing;
  - hex-evaluator: its lock is gitignored and regenerated each run, so no exact key is possible;
  - bump-rehearsal: it builds in a throwaway clone;
  - flake-detection.yml and browser-full.yml: off the PR path.
- **D-13: `verify-compile-no-optional` also loses its existing `deps` cache.**
  - This makes success criterion 3 ("contain no cache step") literally true, so the verifier and contract can check it without interpretation.
  - The cost is about 3 s of dependency fetching.

#### Save policy, budget, security
- **D-14: Save on an exact miss on every ref (PRs included), guarded by `cache-hit != 'true'`.** This mirrors the Dialyzer PLT.
  - Only a PR that changes a lock or config misses; every other PR gets an exact hit from main's scope.
  - A deps-bump PR with k pushes pays one cold build instead of k.
  - A `pull_request` save is scoped to `refs/pull/N/merge` and can never be restored on main.
- **D-15: The save step never uses `always()` and never gets `continue-on-error`.**
  - A failed `deps.compile` is never saved.
  - actions/cache already downgrades save errors to warnings.
- **D-16: No cleanup workflow, no paid cache tier; rely on the 7-day expiry.**
  - Measured: 57 entries using 637 MB (6.4 % of 10 GB).
  - The new entries are about 10.5 MB (root test) and about 14.6 MB (example), zstd-compressed.
  - Steady state is about 1.1 GB, so least-recently-used eviction never threatens the PLT or Playwright entries.
- **D-17: Security rules. Each is also a contract rule:**
  - `release.yml` contains no `actions/cache*` step, no `restore-keys` and no `cache:`/`cache-dependency-path:` input anywhere in the file;
  - no workflow triggered by `pull_request_target`, `workflow_run` or `issue_comment` has any cache step;
  - cached jobs never set `ERL_COMPILER_OPTIONS`, `ELIXIR_ERL_OPTIONS`, `CC` or `CFLAGS`. rust-cache hashes these for the same reason; we forbid them instead.

#### Observability, docs, contract
- **D-18: Each cached job reports one line per cache**, following the `THREADLINE_DIALYZER_PLT_CACHE` precedent: `THREADLINE_BUILD_CACHE=hit|miss key=<primary-key>` and `THREADLINE_EXAMPLE_BUILD_CACHE=hit|miss key=…`.
  - Measurement labels samples from this line.
  - A hit-only `Report exact … cache hit` step, mirroring the PLT, is acceptable if simpler.
- **D-19: Rewrite the `ci.yml` CACHE KEY CONTRACT comment (~lines 66-96) in the present tense to describe the live design.**
  - Delete "There is currently NO `_build` cache".
  - Keep the OS-family expression unspelled, because the guard scans comments.
  - Add a CONTRIBUTING `### Dependency build cache` section next to the "Dialyzer PLT cache and measurement contract" section. It covers:
    - what is cached, and the pinned job list;
    - the key segments;
    - why there are no restore-keys, and why the removal step exists;
    - which jobs are cache-free, and why;
    - the benign save-race warning;
    - a poisoned-cache runbook: symptoms → `gh cache list --key … --ref …` → `gh cache delete <key>` (maintainer, `actions: write`) → durable fix by bumping `build-vN` in a PR. It notes that a poisoned main-scope entry reaches every PR.
- **D-20: The contract stays text-based inside `test/threadline/ci_workflow_parity_contract_test.exs`.**
  - One pure `build_cache_errors(yaml_by_path, contributing)` replaces the existing "dependency cache contract" block (~:382-400).
  - It reuses the file's helpers (`all_workflows`, `workflow_jobs`, `job_steps`, `strip_comment_lines`, `yaml_value`, `key_value_errors`).
  - It scans all workflows. A step counts as a `_build` cache if any uncommented line mentions `_build`, including inside a `path: |` block.
  - It asserts:
    - a fail-closed `{workflow, job}` allowlist with a reason per entry, where every entry must be used;
    - step order by step index and contiguity (D-07);
    - required key segments, from one `@build_key_segments` attribute;
    - no `restore-keys`, and no combined `actions/cache@` for `_build`;
    - the save uses the matching restore id's `cache-primary-key`, plus the `cache-hit != 'true'` guard, and restore and save paths match. This tightens the current check, which accepts any step id;
    - the removal step is unconditional and uses `${MIX_ENV:?}`;
    - a job-level literal `MIX_ENV`;
    - no cache in verify-compile-no-optional;
    - D-17's security rules;
    - the only built-in `cache:` allowed is `cache: npm` on setup-node;
    - the ci.yml comment and CONTRIBUTING section stay aligned. This follows the precedent of `dialyzer_topology_errors(..., contributing)`.
  - One YamlElixir anti-drift assert checks that the parsed step count equals the regex step count per cached job.
  - Each error message names the file, job, step, rule, the reason and the fix. Order errors print the observed sequence.
- **D-21: About 18 mutation controls, each asserting its specific error fragment,** not just `errors != []`. They include:
  - dropping the removal, or moving it after the compile or after the save;
  - adding `restore-keys`;
  - moving the save after the compile;
  - a literal save key, or another restore's key;
  - dropping or flipping the save `if:`;
  - removing each key segment in a loop;
  - a combined `actions/cache@`;
  - removing job-level MIX_ENV;
  - cloning a cache into no-optional, into release.yml (publish-hex / smoke-published) and into flake-detection.yml;
  - a block-scalar path;
  - the two example-removal faults;
  - `cache:` on setup-beam;
  - re-inserting the stale comment sentence.

  Add one positive control: extra `_build` comment lines leave the errors empty.
- **D-22: Stay inline; no composite action.**
  - The contracts read literal job text.
  - `ci_action_runtime_contract_test.exs` classifies `./` action refs as `:needs_decision`.
  - The removal step should show as its own step in the CI UI.
  - Reconsider a composite once, after Phase 221, across all ~14 setup-beam/deps/build copies.

#### Measurement (success criterion 4)
- **D-23: Copy the 218 tools into `219-deps-only-build-cache/tools/`, following the 218-08 precedent, and add a `remeasure-219` script** with sample sets `base` (214), `post218`, `warm` and `cold`.
  - Samples are labelled from the D-18 log line or the hit-only step in committed job JSON, so the record doesn't depend on logs that expire.
  - Split `mix deps.compile` into its own step (D-07), so the saving shows directly in per-step figures.
- **D-24: `219-REMEASURE.md` mirrors `218-REMEASURE.md` and adds:**
  - Method;
  - Samples, with a hit/miss column per cache and the cache scope;
  - runner-minutes;
  - wall clock and critical path;
  - per-job p50 against 214 and against 218;
  - restore and save step cost (the cold-miss penalty);
  - a correctness quote: a warm run compiles no deps but does recompile threadline (root and example);
  - `gh cache list` sizes against the 10 GB budget;
  - a summary table.

  Every figure cites a run ID, and the citation checker passes.
- **D-25: Samples: at least 2 cold and at least 8 warm.**
  - Take them organically from PR and push runs first. The first run in any scope is cold, so no cache deletion is needed.
  - **Maintainer-approved spend:** `workflow_dispatch` top-ups on the landing branch are allowed to reach 8 warm samples, roughly 7 runner-hours at most (approved 2026-09-28).
  - Dispatches and pushes still follow the standing grant rule: ask up front for a grant that names the branch and each dispatch.
- **D-26: Expected effect, which is an inference to be confirmed, not asserted.**
  - The critical path drops about 76 s (−12 %); Browser E2E stays critical.
  - Test (current) drops about 115 s.
  - Capture drops about 73 s, Test (min) about 38 s, PgBouncer about 38 s.
  - About −5 billed runner-min per run.
  - A miss adds about 3–6 s per saving job.
  - If a job's measured warm saving is noise-level, record that; do not quietly drop the job.

### Claude's Discretion
- Exact separators and ordering of key segments, as long as every D-01/D-02 segment is present and the contract's `@build_key_segments` matches.
- Whether D-18 is an always-run echo step or a hit-only step, as long as each sample can be labelled hit or miss from the committed JSON.
- Plan and wave split, and how the contract rewrite is sequenced against the YAML edits. Keep the contract green at every commit.

### Deferred Ideas (OUT OF SCOPE)
- Dev-env `_build` cache for verify-credo and verify-dialyzer: one dev key, about −2 billed min per run. Revisit with 221/222 data.
- Restore-only `_build` cache for flake-detection.yml (about 1.5 % gain) and browser-full.yml.
- Remove the unused root deps restore and root `deps.get` from verify-example-browser and verify-capture. That is waste removal outside CACHE-01; candidate for a later economy pass.
- A composite `setup-elixir` action across all ~14 copies. Reconsider once, after Phase 221 (D-22).
- Playwright cache key keyed on the resolved `@playwright/test` version, without restore-keys (STACK.md note). Not a `_build` concern.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CACHE-01 | Test jobs restore a deps-only `_build` cache and a separate example-app cache. The keys are exact: runner, resolved OTP/Elixir, MIX_ENV, profile, lock and config. There are no restore-keys. The project's own build is removed before compiling. `verify-compile-no-optional` and the release publish path stay cache-free. [VERIFIED: .planning/REQUIREMENTS.md:90-93] | The edit map (per-job skeletons below); the contract seams (existing helpers, collisions with the existing controls); example-build interaction (Mix source); measurement seam (218 tools, raw JSON step labels). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- The canonical entrypoints are `mix verify.format`, `mix verify.credo` (`credo --strict`), `mix verify.test` and `mix ci.all`. Cite them verbatim. [VERIFIED: mix.exs:129-130, 219-251]
- `mix compile --warnings-as-errors` must stay green.
- **Stable CI job IDs:** never change a job `id:`; the `name:` may evolve. Nothing in this phase renames or adds a job.
- **Honest default tests:** do not silently exclude suites from `mix test`.
- **Doc contract tests:** CONTRIBUTING and ci.yml stay aligned through assertions. D-20 makes `build_cache_errors/2` take the CONTRIBUTING text.
- **Capture layer / trigger boundary:** not touched.
- **Zero human verification by default:** automate the verification. Hand only push, dispatch, spend and scope to the maintainer. D-25 has already approved the dispatch spend, but a named grant is still needed per branch and per dispatch.
- **Never `git add .planning/`.** Stage explicit file lists. Tracked `.planning/` prose must not contain concrete home paths or the username, or the repo-hygiene guard fails `ci.all`.
- **GSD state:** `state.begin-phase` requires `--phase/--name/--plans` flags on gsd-core v1.14.0. Hand-check STATE.md afterwards.
- **Local gate gotchas** (from memory):
  - A `ci.all` failure at Dialyzer usually means a PLT cache miss. Rebuild with `mix dialyzer --plt`.
  - Never run Playwright directly; use `mix verify.example_browser`.
  - The local `threadline_test` database may hold a stale `public.threadline_capture_changes()` that masks unqualified-reference failures. This phase touches no SQL, so it is irrelevant here.
  - `.tool-versions` must pin erlang and elixir.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cache restore/save, key composition | CI workflow (`.github/workflows/ci.yml`) | GitHub Actions cache service | Keys and paths are workflow text; actions/cache@v5 does storage and scoping |
| Deps-only artifact correctness (rm own build, deps.compile on miss) | CI workflow steps | Mix (deps.loadpaths / deps.compile semantics) | Mix reconciles deps status; the workflow guarantees first-party code is never cached or restored |
| Rule enforcement | ExUnit contract test (`test/threadline/ci_workflow_parity_contract_test.exs`) | — | Text-based contract over all workflows, with mutation controls |
| Operator documentation / runbook | CONTRIBUTING.md + ci.yml comment | Contract test (doc parity) | Docs are pinned by the same error function |
| Measurement | `.planning/phases/219-*/tools/` (Python, stdlib) | GitHub API (`gh`) raw JSON | Offline arithmetic over committed raw job JSON |

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `actions/cache/restore` | `@v5` | Exact-key restore exposing `cache-hit` and `cache-primary-key` outputs | Already used for the Dialyzer PLT. Classified `:node24` in the runtime contract: `{"actions/cache/restore", "v5"} => :node24` [VERIFIED: test/threadline/ci_action_runtime_contract_test.exs:18] |
| `actions/cache/save` | `@v5` | Save only on miss, reusing the restore's primary key | Same: `{"actions/cache/save", "v5"} => :node24` [VERIFIED: ci_action_runtime_contract_test.exs:19] |
| Mix `deps.compile --skip-local-deps` | Elixir 1.17.3 (current lane; the example builds only there) | Compile only fetchable deps on an example miss, so the path dep `threadline` is never compiled into the save | The option is documented at `deps.compile.ex:38` and implemented by `reject_local_deps/2` at `:351-357` [VERIFIED: Elixir 1.17.3 Mix source]. It also exists in 1.15.8 (`:38`, `:347`) [VERIFIED: v1.15.8 source clone] |
| `yaml_elixir` | `~> 2.11.0` (lock 2.11.0), `only: :test, runtime: false` | D-20 anti-drift parse only | [VERIFIED: mix.exs:123, mix.lock:47] Probed this session: `YamlElixir.read_from_file(".github/workflows/ci.yml")` parses under `MIX_ENV=test mix run --no-start`. Top-level keys are `["concurrency", "jobs", "name", "on", "permissions"]`, and `on` is a string key. Parsed step counts today: verify-test 10, verify-pgbouncer-topology 6, verify-example-browser 9, verify-capture 10, verify-compile-no-optional 5 |

No new packages are installed. The **Package Legitimacy Audit** is not applicable: this phase adds no npm, Hex or PyPI dependencies. The GitHub Actions used are already in the repo and pinned by the runtime contract.

## Package Legitimacy Audit

Not applicable. No external packages are installed. `actions/cache/restore@v5` and `actions/cache/save@v5` are already present in ci.yml (lines 183 and 236) and allowlisted in `ci_action_runtime_contract_test.exs:17-19`.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram (one cached job, cold vs warm)

```
checkout ──> setup-beam (id: beam; resolved otp/elixir outputs)
   │
   ▼
[restore _build]  key = runner-otp-X-elixir-Y-build-v1-<root|example>-$MIX_ENV-full-<lock#>-<config#>
   │ cache-hit? ────────────── yes (warm) ─────────────┐
   │ no (cold)                                          │
   ▼                                                    │
[restore deps (existing; root keeps restore-keys)]      │
   ▼                                                    │
mix deps.get  (reconciles near-miss deps/, marks refetched deps for recompile)
   ▼                                                    │
mix deps.compile  (ONLY on miss; example: --skip-local-deps)  (skipped on hit)
   ▼                                                    ▼
rm -rf own build dirs  (UNCONDITIONAL; echoes THREADLINE_*BUILD_CACHE=hit|miss key=…)
   ▼
[save _build]  (ONLY on miss; key = restore's cache-primary-key; never always())
   ▼
mix compile … / mix verify.example / run-e2e.sh  (deps.loadpaths: deps ok → only first-party compiles)
```

### Exact edit map (ci.yml, as of HEAD c47634ec)

All line numbers were read from `.github/workflows/ci.yml` this session.

| # | Job / area | Current lines | Current text (verbatim excerpt) | Edit |
|---|---|---|---|---|
| E1 | CACHE KEY CONTRACT comment in verify-format | 66-97 | `      # CACHE KEY CONTRACT (Phase 198, D-19) — read before adding any cache.` … `      # There is currently NO \`_build\` cache in this workflow — only \`deps\` and` (81) … `      # Unlike \`_build\`, PLT \`restore-keys\` ARE correct: PLTs update` (96) | Rewrite in the present tense (D-19). **Keep the first line starting `      # CACHE KEY CONTRACT`** (see Pitfall 1). Delete the "currently NO" sentence. Do not spell the OS-family expression. |
| E2 | verify-compile-no-optional `Cache deps` | 302-307 | `      - name: Cache deps` / `        uses: actions/cache@v5` / `          path: deps` … | Delete the step (D-13). Leave `Install dependencies` (309-310) and the compile step (312-313). |
| E3 | verify-test root block | after setup-beam 365-371; before the comment at 373-381 and `Cache deps` at 382-387; `Install dependencies` 389-390; `Compile (warnings as errors)` 392-393 | `      - name: Compile (warnings as errors)` / `        run: mix compile --warnings-as-errors` | Insert the root `_build` restore before `Cache deps`. Insert the deps.compile-on-miss, rm and save steps between 390 and 392. The job already has `MIX_ENV: test` at job level (343-345). |
| E4 | verify-test example block | after `Ensure threadline_phoenix_test database exists…` 405-417; before `Verify Threadline Phoenix example` 419-421 | `      - name: Verify Threadline Phoenix example` / `        if: matrix.lane == 'current'` / `        run: mix verify.example` | Insert 5 example steps immediately before 419, each guarded `if: matrix.lane == 'current'` (the rm may be unconditional; see Pattern 3). |
| E5 | verify-example-browser env | 472-474 | `    env:` / `      DB_HOST: localhost` / `      DB_PORT: 5432` | Add `MIX_ENV: test` (D-09). |
| E6 | verify-example-browser example block | after the DB step 521-530; before the comment at 532-545 and `Run example Playwright suite` at 546-548 | `        run: mix verify.example_browser --project=desktop-chromium --project=mobile-chromium` | Insert 5 example steps after 530 and before the 532 comment, so the Playwright step directly follows the save. Keep the 532-545 comment attached to the Playwright step. |
| E7 | verify-capture env | 582-584 | `    env:` / `      DB_HOST: localhost` / `      DB_PORT: 5432` | Add `MIX_ENV: test`. |
| E8 | verify-capture example block | after the DB step 631-640; before `Regenerate Tier A capture` 642-643 | `      - name: Regenerate Tier A capture` / `        run: mix verify.capture` | Insert 5 example steps before 642. |
| E9 | verify-pgbouncer-topology | `Cache deps` 731-736; `Wait for Postgres and PgBouncer` 738-745; `Bootstrap test DB (direct Postgres, bypass pooler)` 747-755 with `run: \|` body `mix deps.get` / `mix compile --warnings-as-errors` / `mix run priv/ci/topology_bootstrap.exs` | — | Insert the restore-only step before `Cache deps`. Split the bootstrap `run:` into `Install dependencies` → `Compile dependencies on build cache miss` → rm → `Compile (warnings as errors)`. **Move `Wait for Postgres and PgBouncer` after the compile** (Pitfall 3). The bootstrap keeps its `env:` block and `mix run priv/ci/topology_bootstrap.exs`. Job-level `MIX_ENV: test` exists (695-696). |

**Untouched:** verify-format (except the comment), verify-credo, verify-dialyzer, verify-hex-evaluator, verify-release-shape, verify-bump-rehearsal, verify-deps-audit, verify-repo-hygiene and ci-required. Also `release.yml`, `flake-detection.yml` and `browser-full.yml`.

The setup-beam count stays at 11, which the test asserts: `assert setup_beam_steps - 1 == 11` [VERIFIED: ci_workflow_parity_contract_test.exs:545].

### Pattern 1: Root block (verify-test; the literal runner variant for other jobs)

```yaml
# Values from D-01/D-07/D-08; step names and ids are Claude's-discretion suggestions.
      - name: Restore deps-only build cache
        id: build-restore
        uses: actions/cache/restore@v5
        with:
          path: _build/${{ env.MIX_ENV }}
          key: ${{ matrix.runner }}-otp-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-build-v1-root-${{ env.MIX_ENV }}-full-${{ hashFiles('mix.lock') }}-${{ hashFiles('config/**/*.exs') }}

      - name: Cache deps            # existing step, unchanged (keeps restore-keys; r1 §5)
        ...

      - name: Install dependencies  # existing
        run: mix deps.get

      - name: Compile dependencies on build cache miss
        if: steps.build-restore.outputs.cache-hit != 'true'
        run: mix deps.compile

      - name: Remove own build (never cached, never reused)
        run: |
          echo "THREADLINE_BUILD_CACHE=${{ steps.build-restore.outputs.cache-hit == 'true' && 'hit' || 'miss' }} key=${{ steps.build-restore.outputs.cache-primary-key }}"
          rm -rf "_build/${MIX_ENV:?}/lib/threadline"

      - name: Save deps-only build cache
        if: steps.build-restore.outputs.cache-hit != 'true'
        uses: actions/cache/save@v5
        with:
          path: _build/${{ env.MIX_ENV }}
          key: ${{ steps.build-restore.outputs.cache-primary-key }}

      - name: Compile (warnings as errors)   # existing, text unchanged
        run: mix compile --warnings-as-errors
```

**The D-18 recommendation (discretion):** put the always-run log line in the unconditional rm step.
- The line then always prints, once per cache, without adding a step that breaks D-07 contiguity.
- Label each sample in committed JSON from the `Compile dependencies on build cache miss` step conclusion: `skipped` is a hit and `success` is a miss. Raw job JSON records every step's `name` and `conclusion` [VERIFIED: 218 raw/ci/runs/36364354586.json has `steps[].name/conclusion/started_at/completed_at`].
- This satisfies "labelable from committed JSON" with no hit-only step.
- The `${{ … && 'hit' || 'miss' }}` expression is GitHub's standard ternary idiom [ASSUMED].

**Rendered key segments.** The resolved outputs render as `OTP-27.3.4.15` and `v1.17.3-otp-27`. For example, a live key is `ubuntu-24.04-OTP-27.3.4.15-elixir-v1.17.3-otp-27-mix-deps-8965a0…` [VERIFIED: `gh cache list --limit 8`, this session]. With D-01's `-otp-` label, the key renders `…-otp-OTP-27.3.4.15-…`. That is harmless, and the separators are discretion, so keeping D-01 verbatim is simplest.

### Pattern 2: pgbouncer (restore only; same rendered key as the verify-test current lane)

In pgbouncer, use the literal `ubuntu-24.04-otp-…-build-v1-root-${{ env.MIX_ENV }}-full-…`. With `runner: "ubuntu-24.04"` [VERIFIED: ci.yml:340], `.tool-versions` and `MIX_ENV: test`, it renders byte-identical to the current lane's key.

The sequence is: restore (id `build-restore`) → `Cache deps` → `Install dependencies` → `Compile dependencies on build cache miss` → `Remove own build …` (echo plus rm) → `Compile (warnings as errors)` → `Wait for Postgres and PgBouncer` → `Bootstrap test DB (direct Postgres, bypass pooler)` (`run: mix run priv/ci/topology_bootstrap.exs`, env block kept). There is **no save**, so the contract allowlist entry must carry a `restore_only` flag.

The compile step needs no extra env:
- root `config/test.exs` reads `THREADLINE_PGBOUNCER_TOPOLOGY`/`DB_HOST`/`DB_PORT` only into `:threadline` runtime config values;
- `lib/` has no `compile_env`;
- the only `System.get_env` in compiled paths sits inside a function body (`lib/mix/tasks/threadline/verify_topology.ex:9`) [VERIFIED: grep this session].

Moving the compile out of the env-carrying bootstrap step therefore changes nothing Mix tracks. Mix tracks config file mtimes and `compile_env` values, not arbitrary env [CITED: r1 §Q1, Mix source].

### Pattern 3: Example block (browser, capture, verify-test current)

```yaml
      - name: Restore example deps and deps-only build cache
        id: example-build-restore
        # verify-test only: if: matrix.lane == 'current'
        uses: actions/cache/restore@v5
        with:
          path: |
            examples/threadline_phoenix/deps
            examples/threadline_phoenix/_build/${{ env.MIX_ENV }}
          key: ubuntu-24.04-otp-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-build-v1-example-${{ env.MIX_ENV }}-full-${{ hashFiles('examples/threadline_phoenix/mix.lock') }}-${{ hashFiles('examples/threadline_phoenix/config/**/*.exs') }}

      - name: Install example dependencies
        working-directory: examples/threadline_phoenix
        run: mix deps.get

      - name: Compile example dependencies on cache miss
        if: steps.example-build-restore.outputs.cache-hit != 'true'
        working-directory: examples/threadline_phoenix
        run: mix deps.compile --skip-local-deps

      - name: Remove example app's own build (never cached, never reused)
        run: |
          echo "THREADLINE_EXAMPLE_BUILD_CACHE=${{ steps.example-build-restore.outputs.cache-hit == 'true' && 'hit' || 'miss' }} key=${{ steps.example-build-restore.outputs.cache-primary-key }}"
          rm -rf "examples/threadline_phoenix/_build/${MIX_ENV:?}/lib/threadline" \
                 "examples/threadline_phoenix/_build/${MIX_ENV:?}/lib/threadline_phoenix"

      - name: Save example deps and deps-only build cache
        if: steps.example-build-restore.outputs.cache-hit != 'true'
        uses: actions/cache/save@v5
        with:
          path: |
            examples/threadline_phoenix/deps
            examples/threadline_phoenix/_build/${{ env.MIX_ENV }}
          key: ${{ steps.example-build-restore.outputs.cache-primary-key }}
```

**In verify-test:**
- The restore, Install, Compile and Save steps get `matrix.lane == 'current'`. The two conditional ones become `if: matrix.lane == 'current' && steps.example-build-restore.outputs.cache-hit != 'true'`. A skipped restore leaves `cache-hit` empty, and `'' != 'true'` is true, so without the lane guard the save would run on the min lane with an empty key.
- The rm step can stay unconditional. `rm -rf` on absent paths succeeds, and `MIX_ENV` is set at job level.
- The contract must accept the `matrix.lane == 'current' && ` prefix exactly and nothing else (no `always()`, no `failure()`, no `||`).
- In the verify-test **matrix** job, lead the example key with `${{ matrix.runner }}`. The existing `key_value_errors` requires `ubuntu-24.04-` or `${{ matrix.runner }}-` [VERIFIED: parity test:1247-1249]. The rendered strings are equal.

**Why the rm path uses `${MIX_ENV:?}` rather than the D-08 literal `_build/test`:** it matches the env-scoped cache path. MIX_ENV is `test` in every example job (job-level in verify-test, and job-level after E5/E7). `run-e2e.sh` also hard-exports it: `export MIX_ENV=test` [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh:16].

**Prefer `working-directory:` over `cd`** for the deps.get and deps.compile steps. The contract classifier can then read the project from `yaml_value(step, "working-directory")`. Keep the rm step at the repo root with full paths, so its text contains the literal example paths the contract pins.

### How the pre-populated example `_build` interacts with the existing consumers (focus 2)

- **`mix verify.example`** runs `bash -lc 'set -euo pipefail && cd examples/threadline_phoenix && printf "n\n" | mix deps.get && mix compile --warnings-as-errors && mix ecto.create --quiet -r ThreadlinePhoenix.Repo && mix test'` with `MIX_ENV=test` [VERIFIED: mix.exs:307-316].
  - After the pre-steps, its `deps.get` finds `deps/` and the lock converged (a no-op fetch).
  - Its `compile` runs `deps.loadpaths`. `partition/3` puts a dep into the compile list only if `Mix.Dep.compilable?(dep) or (Mix.Dep.ok?(dep) and local?(dep))` [VERIFIED: 1.17.3 deps.loadpaths.ex:97-99]. So only the path dep `threadline` (local) and any not-ok dep compile, then `threadline_phoenix`.
  - **No double work.** The only repeat is the ~1 s deps.get convergence check. `mix.exs` needs **no** change.
- **`run-e2e.sh`** runs `mix deps.get --only test`, then `touch lib/threadline_phoenix_web/router.ex`, then `mix compile --force` [VERIFIED: run-e2e.sh `cd "$EXAMPLE"` block].
  - `--force` does **not** reach deps. `deps_check/2` calls `Mix.Tasks.Deps.Compile.compile(compile)` with no options [VERIFIED: 1.17.3 deps.loadpaths.ex:87].
  - Dep compiles triggered from a parent run with `["--from-mix-deps-compile", "--no-warnings-as-errors", "--no-code-path-pruning"]` [VERIFIED: deps.compile.ex:165].
  - `--force` recompiles only `threadline_phoenix`, plus `threadline` because local deps are always handed to the compiler.
- **Does the `--only test` fetch set match the cached set?** Yes for `_build`.
  - The example has exactly one env-scoped dep, `{:phoenix_storybook, "~> 1.2.0", only: [:dev, :test]}` [VERIFIED: examples/threadline_phoenix/mix.exs:58]. No dev-only deps.
  - An unfiltered `mix deps.get` in the pre-step fetches a superset of `deps/`, and `deps.compile` under `MIX_ENV=test` compiles exactly the test-env closure. That is the same closure `run-e2e.sh` compiles.
  - `deps.get` never deletes, so `--only test` afterwards is a no-op.
- **Env-driven example config is not a dep-compile input.**
  - `THREADLINE_E2E` is read in `config/test.exs:80`, where it selects `:threadline, :trigger_capture` tables, and in `runtime.exs:26` (Oban, logger and endpoint runtime config) [VERIFIED: grep this session].
  - Both first-party apps are removed before every compile, and `runtime.exs` is not a compile-staleness input (r1 §Q1).
  - So the pre-steps need no `THREADLINE_E2E=1`, and the three example consumers can share one key.
- **Min lane / Elixir 1.15.8:** the example never builds there (`if: matrix.lane == 'current'`, ci.yml:420), and browser/capture read `.tool-versions`. The CONTEXT "confirm 1.15.8 consolidation for the example" item is therefore moot for the example. For root, r1 verified consolidation inside the app dir in 1.15.8 source (`project.ex` L805-812).

### Recommended plan and commit sequencing (keeps the contract green at every commit)

1. **Plan 01 — contract function, fixture-proven (TDD).**
   - Add `build_cache_errors/2` plus its private classifier, the `@build_cache_jobs` allowlist (`%{{path, job} => {reason, :save | :restore_only}}`), `@build_key_segments`, and the not-cached reasons.
   - Test it against **synthetic workflow text** built in the test (a minimal correct job, then each D-21 mutation on that text).
   - Leave the live `describe "dependency cache contract"` refute (382-400) untouched. It is still true, so the tree stays green.
   - Credo `--strict` must pass on the new code. Keep the functions small, with one clause per rule, to avoid the complexity and nesting checks.
2. **Plan 02 — one atomic commit: YAML + docs + live flip.** E1–E9, the CONTRIBUTING `### Dependency build cache` section, and the replacement of the 382-400 block with the live assertion `build_cache_errors(all_workflows(), contributing) == []`, the live mutation controls and the YamlElixir anti-drift assert.
   - This must be one commit. The old refute goes red the moment a `_build` path exists (Pitfall 5 shows why its regex under-matches anyway), and the docs parity is part of the same function.
   - Run the full local gate before committing.
3. **Plan 03 — measurement.**
   - Copy the tools and write `remeasure-219.py` (autonomous).
   - Checkpoint: the maintainer pushes the landing branch or PR and grants named dispatches (D-25).
   - Collect, then write `219-REMEASURE.md` and pass the citation checker.

Branch fact for Plan 03:
- PR #60 (`land/v1.43-217-218`) is still **OPEN**. origin/main is at `2a75a795 chore(main): release 0.11.1 (#56)` [VERIFIED: `gh pr list`, `git log origin/main`].
- So 218 is not on main yet, and main holds no `build-v1` entry. Every pre-merge run in a new ref scope is cold on its first run.
- Where 219 lands (stacked on #60, appended to #60, or after it merges) is a maintainer decision to raise at the checkpoint. See Open Questions.

### Anti-Patterns to Avoid
- **Copying the Phoenix/Ecto/Oban shape.** They cache `deps` + `_build` together, key on the OS family and `**/mix.lock`, and use `restore-keys`. The contract rejects exactly that [CITED: r1 §Q6].
- **Gating the rm on anything.** It must run on hit and on miss.
- **Relying on the consumer alias to remove the build.** `mix verify.example` and `run-e2e.sh` cannot remove it: the save happens in the workflow before they run.
- **A composite action.** Out of scope (D-22).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Save-on-miss with the exact same key | Recomputing the key string in the save step | `key: ${{ steps.<restore-id>.outputs.cache-primary-key }}` + `if: steps.<id>.outputs.cache-hit != 'true'` | This is the PLT precedent [VERIFIED: ci.yml:234-239]. A retyped key drifts |
| Stale-dep detection | Custom mtime or hash checks | Mix `deps.loadpaths` status (`compile.fetch` markers, `:lockmismatch`, compile_env value check) | Verified reconciliation in r1 §Q5 |
| Cache eviction or cleanup | A cleanup workflow with `actions: write` | 7-day expiry + `build-vN` bump (D-04, D-16) | No budget pressure (637 MB of 10 GB) |
| Mutation harness | A new mutation framework | The existing `String.replace` + `refute mutated == live` idiom, with specific-fragment asserts (D-21) | Precedent at parity test :258-295, :482-533, :579-611 |
| Measurement arithmetic | New percentile code | Import the copied `summarize-ci.py` (as `remeasure-218.py` does) | 218-08 precedent; the reproducibility of the base figures is already proven |

## Common Pitfalls

### Pitfall 1: Rewriting the CACHE KEY CONTRACT comment breaks an unrelated mutation control
**What goes wrong:** The test "no workflow names the OS-family runner context, comments included" builds its control as `mutate.(ci, "      # CACHE KEY CONTRACT", "      # e.g. " <> @os_family_context <> "\n      # CACHE KEY CONTRACT")`, then asserts `refute mutated == live` [VERIFIED: ci_workflow_parity_contract_test.exs:757-762, 773]. If the rewritten comment no longer contains a line starting with exactly six spaces and `# CACHE KEY CONTRACT`, the control silently fails to mutate and the test goes red.
**How to avoid:** Keep the heading line, for example `      # CACHE KEY CONTRACT (Phase 198 D-19, Phase 219 CACHE-01) — …`. Also keep it because `flake-detection.yml:99` ("Key shape follows the CACHE KEY CONTRACT in ci.yml.") and ci.yml:833/859 refer to it by name.

### Pitfall 2: The matrix lane guard vs. the "save `if:` is exactly the cache-hit guard" rule
**What goes wrong:** A contract that requires `if:` to equal `steps.X.outputs.cache-hit != 'true'` rejects the verify-test example save, which needs a `matrix.lane == 'current' && ` prefix. Without that prefix, the save runs on the min lane with an empty key.
**How to avoid:** Accept exactly two forms, `steps.<id>.outputs.cache-hit != 'true'` and `matrix.lane == 'current' && steps.<id>.outputs.cache-hit != 'true'`, and reject everything else. Add a mutation control for `always() && …`.

### Pitfall 3: pgbouncer's Wait step breaks D-07 contiguity
**What goes wrong:** `Wait for Postgres and PgBouncer` (738-745) sits between `Cache deps` and the combined bootstrap `run:`. Splitting in place leaves a non-mix step inside the block.
**How to avoid:** Move Wait after `Compile (warnings as errors)` and before Bootstrap. The DB is only needed by the bootstrap `mix run`.

### Pitfall 4: Substring security checks false-positive on release.yml
**What goes wrong:**
- `release.yml` contains "runner tool cache" (comments at 130, 447, 612), `git diff --cached` (179, 711) and `data.workflow_runs` (364) [VERIFIED: grep this session].
- A substring `cache` or `workflow_run` check therefore flags a clean file.
- The mutation control "clone a cache into release.yml" would then pass for the wrong reason.

**How to avoid:**
- Match `^\s*(-\s+)?uses:\s*actions/cache` and `^\s*(cache|cache-dependency-path|restore-keys):` on `strip_comment_lines` text.
- Take trigger names from the parsed `on:` block: text between `^on:` and the next top-level key, or the YamlElixir `"on"` map.
- Match env keys as `^\s*(ERL_COMPILER_OPTIONS|ELIXIR_ERL_OPTIONS|CC|CFLAGS):`. A substring `CC` would hit words like `ACCESS`.

### Pitfall 5: The old `_build` refute is line-exact
The old refute is `refute Regex.match?(~r/^\s*path:\s*_build\s*$/m, yaml)` [VERIFIED: parity test:398-399]. `path: _build/${{ env.MIX_ENV }}` does not match `_build\s*$`, and a `path: |` block does not match either. So a naive YAML-first commit might not go red here, and the tree would carry a stale, misleading assertion ("ci.yml must NOT cache _build").
**How to avoid:** Plan 02 must delete it explicitly. The verifier should grep that `never caches _build` is gone.

### Pitfall 6: `hashFiles` on a glob that matches nothing returns an empty string
**What goes wrong:** A typo in `config/**/*.exs` silently drops the config guard, and the key stays "exact" but config-blind. `hashFiles` returns `''` when nothing matches [ASSUMED from GitHub docs knowledge].
**How to avoid:**
- In Plan 03, assert the rendered key from the D-18 log line: two 64-hex segments after `-full-`.
- Root `config/` holds `config.exs` and `test.exs`, and example `config/` holds `config.exs dev.exs prod.exs runtime.exs test.exs` [VERIFIED: ls this session].
- That `**` also matches zero directories (i.e. `config/config.exs`) is [ASSUMED] and is proven by the first run's rendered key.

### Pitfall 7: Setting MIX_ENV=test at job level in browser/capture
**What changes:** The root `mix verify.example_browser` alias used to run in `dev`, because the alias is absent from `preferred_envs`, whose entries include `"verify.capture": :test` and `"verify.example": :test` but no `verify.example_browser` [VERIFIED: mix.exs:11-30]. It now loads root `config/test.exs`.
**Why it is safe:**
- `mix verify.capture` already runs in `:test` with the identical job env and is green (post-218 runs).
- Function aliases do not compile the root project.
- `run-e2e.sh` exports `MIX_ENV=test` regardless.

**Warning sign:** A red `Run example Playwright suite` whose log shows a root config error. Revert only the env line and investigate.

### Pitfall 8: ROADMAP SC2 literal vs the D-08 form
SC2 says "`_build/$MIX_ENV/lib/threadline` is removed". The workflow uses `"_build/${MIX_ENV:?}/lib/threadline"`, so a verifier grepping the SC literal misses it. Have CONTRIBUTING and the ci.yml comment state that the rm is `rm -rf "_build/${MIX_ENV:?}/lib/threadline"` (the `$MIX_ENV` form with a fail-loud guard), so the mapping is explicit.

### Pitfall 9: Cancelled PR runs and the save race
- `cancel-in-progress` is true for `pull_request` [VERIFIED: ci.yml:48-50]. Rapid pushes cancel runs before their saves, and a cancelled run is not a valid cold or warm sample.
- In a cold run, three jobs race to save the example key. The losers log "Unable to reserve cache" as a **warning**, not a failure. The measurement must not treat those warnings as errors.

### Pitfall 10: Repo-hygiene on planning prose
`219-REMEASURE.md`, SUMMARY and VERIFICATION prose must not paste log lines that contain runner home paths. Placeholder them as `<home>/…`, and grep for the username before committing.

## Existing tests that pin text in the edited jobs (must stay green or change in the same commit)

| Test (file:line) | What it pins | Impact |
|---|---|---|
| `ci_workflow_parity_contract_test.exs:382-400` `describe "dependency cache contract"` | `actions/cache@v5` present; `path: deps` present; npm `cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json`; refute `path: _build` | **Replace** in Plan 02 (D-20). The first three asserts are still true and may be kept inside the new describe |
| parity `:545` | exactly 11 setup-beam steps | unchanged |
| parity `:549-551` `toolchain_contract_errors(all_workflows())` → `cache_key_errors/3` `:1208-1232` | every cache restore key must lead with `ubuntu-24.04-` or `${{ matrix.runner }}-` and carry both beam outputs; a save is exempt when its key is `${{ steps.<any>.outputs.cache-primary-key }}` | new restore keys satisfy it; new saves are exempt. `yaml_value(step,"path")` returns `|` for block paths, which is harmless (not in the Playwright exemption, so the key is still checked) |
| parity `:733-781` OS-family test | control needles `"key: ${{ matrix.runner }}-"` (first occurrence) and `"      # CACHE KEY CONTRACT"` | first: the new build restore key in verify-test also matches, still a valid mutation. Second: **Pitfall 1** |
| parity `:305-372` verify-test setup-beam controls | the `"legacy matrix-value deps key"` needle is the deps key prefix | unaffected (the build key has a different prefix) |
| `ci_topology_contract_test.exs:~251-266` xref ordering in the verify-test block | `position(block, "run: mix compile --warnings-as-errors")` < `run: mix verify.xref_cycles` < `run: mix verify.test` | keep the root compile step text byte-identical. The new `run: mix deps.compile` does not contain `run: mix compile` |
| topology `:~235` | `yaml` contains `run: mix verify.example`, `- name: Verify Threadline Phoenix example` | keep |
| topology `:19-29` pgbouncer | contains `mix verify.topology`, `priv/ci/topology_bootstrap.exs`, `THREADLINE_PGBOUNCER_TOPOLOGY: "1"`, `POOL_MODE: transaction` | keep them in the bootstrap and topology steps |
| topology `dialyzer_topology_errors` `:402-491` | verify-dialyzer text; `no_optional_job` must not contain `dialyzer` | unaffected (E2 removes only the deps cache). Do not reuse the step name `Report exact PLT cache hit`. New log markers `THREADLINE_BUILD_CACHE=`/`THREADLINE_EXAMPLE_BUILD_CACHE=` do not collide with the `THREADLINE_DIALYZER_*` needles |
| topology `:852-920` verify-capture | the byte-stable step, no mechanical step | unaffected |
| `browser_full_projects_contract_test.exs` + `bin/browser-full-projects` | counts `--project` flags in ci.yml `run:` bodies, and refuses flags in a step with `if:` | new steps carry no `--project`, and the `if:` refusal applies only to flag-bearing steps [VERIFIED: bin/browser-full-projects:252-277]. The controls replace `run: mix verify.example_browser --project=…`, `- name: Regenerate Tier A capture\n` and `  verify-capture:\n    name: `; keep those texts |
| `ci_action_runtime_contract_test.exs:17-19` | `actions/cache`, `actions/cache/restore` and `actions/cache/save` at v5 are `:node24` | no change |
| `ci_coverage_doc_contract_test.exs` | the `--project` sets and the browser-full job | unaffected |

**Roster rule:** not triggered. No `verify-*` job is added, removed or renamed. The header roster, List 1, `ci-required` `needs:` and the job names are untouched.

**Step-name contracts:** keep these names byte-identical:
- `Compile (warnings as errors)`, `Install dependencies`, `Install root dependencies`
- `Run example Playwright suite`, `Regenerate Tier A capture`, `Verify Threadline Phoenix example`
- `Bootstrap test DB (direct Postgres, bypass pooler)`, `Topology tests + verify_coverage through PgBouncer`

The flake_classifier test pins `- name: Compile (warnings as errors)` in **flake-detection.yml**, not ci.yml [VERIFIED: flake_classifier_contract_test.exs:539-601].

## Code Examples

### Contract seams to reuse (verbatim signatures read this session)
```elixir
# test/threadline/ci_workflow_parity_contract_test.exs
defp all_workflows                      # :126 — %{rel_path => text}, globbed .yml/.yaml
defp workflow_jobs(yaml)                # :845 — [{job_id, block}] (2-space job keys)
defp workflow_job(yaml, id)             # :857
defp job_steps(block)                   # :866 — split at ~r/^(?=      - )/m, header dropped
defp strip_comment_lines(block)         # :873
defp trimmed_lines(text)                # :880
defp yaml_value(step, key)              # :1260 — first `key:` line value (block scalars return "|")
defp key_value_errors(where, field, v)  # :1241 — runner-led, beam outputs, no OS family, no literal OTP
defp cache_key_errors(path, job_id, s)  # :1208 — save exemption regex at :1219-1223 accepts ANY step id
```
The mutation idiom: `controls = [{label, String.replace(live, a, b)}]`, then `refute mutated == live`, then (per D-21) `assert Enum.any?(errors, &String.contains?(&1, fragment))`. The OS-family test at :775-779 already asserts specific output (`String.starts_with?(&1, path <> ":")`), so it is the closest existing precedent for fragment asserts.

### Classifier sketch (suggested; planner owns the final shape)
```elixir
# Classify each uncommented step of a job, then assert contiguity by index.
defp step_class(step) do
  s = strip_comment_lines(step)
  cond do
    s =~ ~r{uses:\s*actions/cache/restore@} and s =~ "_build" -> :restore_build
    s =~ ~r{uses:\s*actions/cache/save@} and s =~ "_build" -> :save_build
    s =~ ~r{uses:\s*actions/cache@} and s =~ "_build" -> :combined_build   # always an error
    s =~ ~r{uses:\s*actions/cache@} and yaml_value(s, "path") == "deps" -> :deps_restore
    s =~ ~r/\brm -rf\b[^\n]*_build\// -> :rm_own
    s =~ ~r/^\s*run:\s*mix deps\.get\s*$/m -> :deps_get
    s =~ ~r/^\s*run:\s*mix deps\.compile\b/m -> :deps_compile
    true -> :other
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `deps`+`_build` in one `actions/cache@` with `restore-keys` (Phoenix/Ecto/Oban) | Exact `_build` key, no restore-keys; `deps/` keeps restore-keys | CargoSense/setup-elixir-project#13 [CITED: r1 §Q6] | Avoids the "dependency does not match requirement" outage loop |
| Combined `actions/cache` for build artifacts | Split `restore`/`save` with a `cache-primary-key` hand-off | actions/cache v3+ sub-actions; already used for the PLT in this repo | Save before tests, save only on miss |
| "There is currently NO `_build` cache" (ci.yml:81) | Live design documented in the present tense | Phase 219 | Comment + CONTRIBUTING pinned by contract |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `hashFiles('config/**/*.exs')` matches `config/config.exs` (`**` matches zero directories) and returns `''` when nothing matches | Pitfall 6 | Config silently leaves the key. Caught by Plan 03's rendered-key check (the 64-hex segment must be present) |
| A2 | The `${{ cond && 'hit' \|\| 'miss' }}` expression idiom renders as expected in `run:` | Pattern 1 | Wrong log label only; the JSON label (deps.compile step conclusion) is independent |
| A3 | Actions `cache-hit` is `''` when its restore step was skipped, so the lane guard is required | Pattern 3 | Without the guard, the min lane would try a save with an empty key (a warning, not a failure, but noise and a contract hole). Keeping the guard is safe either way |
| A4 | D-26 deltas (−76 s critical path, and so on) | inherited | Recorded as [inference] until 219-REMEASURE measures them |
| A5 | Save-race losers produce warnings, not failures (actions/cache saveImpl) | Pitfall 9 | From r2 (read saveImpl.ts). If wrong, a cold run shows a red save step. Visible in the first cold run |

## Open Questions (RESOLVED)

1. **Landing branch for the measurement (Plan 03 checkpoint).**
   - What we know: PR #60 (217–218) is still OPEN, and main lacks the 218 changes and any `build-v1` entry.
   - What's unclear: whether 219 stacks on `land/v1.43-217-218` (appended to #60) or goes on a new `land/v1.43-219` branch after #60 merges.
   - Recommendation: the checkpoint asks the maintainer for one named branch, a PR, and N named `gh workflow run ci.yml --ref <branch>` dispatches (D-25 approves ≤7 runner-hours). The first PR run and the first dispatch are the ≥2 cold samples. Later runs in each scope are warm.
   - **RESOLVED (dispositioned):** the landing branch is a maintainer push/scope decision, so the plans do not pick it. Plan 03 Task 2 is a blocking `checkpoint:human-action` that presents options (a) append to #60, (b) stack on `land/v1.43-217-218`, (c) merge #60 then branch from `main`, and resumes only on the maintainer's named branch, PR number and dispatch count.
2. **The `post218` sample set.**
   - What we know: 218-REMEASURE's post set is 8 runs from `.planning/phases/218-*/raw/ci`, with `POST_AFTER = "2026-09-27T23:34:00Z"` [VERIFIED: remeasure-218.py:61].
   - Recommendation: `remeasure-219.py` reads the 218 raw data read-only, with the same filter (never copy the JSON), exactly as `remeasure-218.py` reads 214's raw data via `RAW_214`.
   - **RESOLVED (adopted):** Plan 03 Task 1 implements it: `RAW_218` read-only with 218's `POST_AFTER`/`POST_KEYS`, no JSON copied, a git-status gate proving the 218 directory is untouched, and the `post218` figures checked against 218-REMEASURE.md §2 and §4a.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | contract tests, local gate | ✓ | 1.17.3 (OTP 27) via `.tool-versions` | — |
| PostgreSQL | `mix test` (test_helper migrates on boot) | ✓ | localhost:5432 and :5433 accepting | — |
| `gh` (authenticated) | cache list, run collection, dispatch | ✓ | `gh cache list` and `gh api …/cache/usage` worked this session | — |
| python3 | measurement tools | ✓ | (218 tools ran in 218-08) | — |
| Node + Playwright | only `mix ci.all`'s final browser step | ✓ per memory (use `mix verify.example_browser`, never raw playwright) | — | — |
| GitHub-hosted CI (cache hits) | SC1/SC4 runtime proof | only after push | — | none: needs the maintainer's push/dispatch grant |

Baseline probe: `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/browser_full_projects_contract_test.exs` gives **89 tests, 0 failures in 18.7 s** (this session).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3), text/regex contracts + YamlElixir 2.11.0 anti-drift; Python stdlib tools for measurement |
| Config file | `test/test_helper.exs` (default excludes `pgbouncer_topology`, `live_dialyzer`) |
| Quick run command | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/browser_full_projects_contract_test.exs` (~20 s) |
| Full suite command | `mix verify.test` then `mix ci.all` at phase close; plus `mix verify.format`, `mix verify.credo`, `bin/verify-repo-hygiene` |

### Phase Requirements → Test Map
| Req / Decision | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CACHE-01 / SC1 / D-01, D-02, D-05 | Every `_build` restore key carries all `@build_key_segments`; `no-optional` token forbidden; per-segment deletion loop fails | contract + mutation | `mix test test/threadline/ci_workflow_parity_contract_test.exs` | ✅ file; ❌ new describe (Plan 01/02) |
| SC1 / D-14, D-15 | Split restore/save only; no `restore-keys`; save key = matching restore id's `cache-primary-key`; `if:` is the exact guard (±lane prefix); no `always()`; restore and save paths equal | contract + mutation | same | ❌ Wave 0 (Plan 01) |
| SC2 / D-07, D-08 | rm step present, unconditional, `${MIX_ENV:?}`; contiguous order restore→deps→get→compile→rm→save→compile; example rm names both apps | contract + mutation (order errors print the observed sequence) | same | ❌ Plan 01 |
| D-09 | Cached job has a literal job-level `MIX_ENV`; path `_build/${{ env.MIX_ENV }}` | contract + mutation | same | ❌ Plan 01 |
| SC3 / D-13 | verify-compile-no-optional has zero cache steps | contract + mutation (clone into no-optional) | same | ❌ Plan 01 |
| SC3 / D-17 | release.yml: no cache step, restore-keys or `cache:` key; no cache in `pull_request_target`/`workflow_run`/`issue_comment` workflows; no compiler env in cached jobs | contract + mutation (publish-hex, smoke-published, flake-detection clones) | same | ❌ Plan 01 |
| D-20 allowlist | Fail-closed `{workflow, job}` allowlist; every entry used; restore-only flag for pgbouncer | contract + mutation (build cache in verify-format / flake-detection) | same | ❌ Plan 01 |
| D-20 built-in caches | Only `cache: npm` on setup-node | contract + mutation (`cache: true` on setup-beam) | same | ❌ Plan 01 |
| D-19 docs | ci.yml comment has no "currently NO"; CONTRIBUTING section names the rm, "no `restore-keys`", `gh cache delete`, `build-v`, and the allowlisted job ids (set equality) | doc contract + mutation | same | ❌ Plan 02 |
| D-20 anti-drift | YamlElixir parsed step count == `job_steps` count per cached job | unit | same | ❌ Plan 02 |
| D-21 positive control | extra `# _build` comment lines keep errors `[]` | unit | same | ❌ Plan 01 |
| Regression guard | existing parity, topology, runtime, browser-full contracts stay green | contract | quick run command above | ✅ |
| SC1 runtime (a hit really restores; deps not recompiled; threadline is recompiled) | warm log shows no `==> <dep>` lines and a fresh threadline compile; `THREADLINE_BUILD_CACHE=hit` | CI evidence (manual-only until pushed: needs GitHub cache service) | `gh run view --repo szTheory/threadline --job <id> --log` (grep) — recorded in 219-REMEASURE §correctness | ❌ Plan 03 |
| SC4 | before/after with run IDs; citation checker passes | tool | `python3 .planning/phases/219-deps-only-build-cache/tools/check-citations.py .planning/phases/219-deps-only-build-cache/219-REMEASURE.md` and `--self-test` | ❌ Plan 03 |

### Sampling Rate
- **Per task commit:** the quick run command (~20 s), plus `mix format --check-formatted`.
- **Per plan merge:** `mix verify.test`, `mix verify.credo`, `bin/verify-repo-hygiene`.
- **Phase gate:** `mix ci.all` green locally. Required on the pushed branch: all 15 ci.yml jobs green, with at least 1 cold and 1 warm run before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] The `build_cache_errors/2` function and its synthetic-fixture tests in `test/threadline/ci_workflow_parity_contract_test.exs` (Plan 01).
- [ ] `.planning/phases/219-deps-only-build-cache/tools/` — copies of 218's `collect-ci-runs.sh`, `summarize-ci.py`, `check-citations.py` (exemption widened `21[4-8]` → `21[4-9]`), `fixtures/{cited,uncited}.md`; new `remeasure-219.py` (Plan 03).
- No framework install needed.

**Which success criteria need a push or dispatch (maintainer grant, D-25):**
- SC1's runtime half: real restore and save behaviour, and the rendered key.
- SC4 entirely.

SC2 and SC3, and SC1's static half, are fully provable locally by the contract.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (CI trust boundary) | GitHub cache ref scoping; `permissions: contents: read` [VERIFIED: ci.yml:42-43]; no `actions: write` cleanup job |
| V5 Input Validation | no | — |
| V6 Cryptography | no | — |
| V10/V14 Build & supply-chain integrity | yes | Exact keys, no `_build` restore-keys, rm of first-party code, cache-free release.yml, contract-enforced |

### Known Threat Patterns for GitHub Actions caches

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cache poisoning via default-branch-context workflows (`pull_request_target`/`workflow_run`/`issue_comment`) | Tampering | D-17 contract: no cache step in such workflows. Today the three `workflow_run` workflows have no cache [VERIFIED: grep `on:` blocks] |
| Stale or wrong compiled artifact served (near-miss restore) | Tampering / integrity | No `restore-keys` on `_build`; full OTP in key; `build-vN` bump |
| First-party code under test cached and replayed | Tampering / integrity | Unconditional rm before save and compile (D-07/D-08) |
| Release built from a cache | Elevation / integrity | release.yml cache-free (contract) |
| Compiler-env injection changing dep BEAMs without key change | Tampering | D-17 env denylist in cached jobs |
| Secrets in cache | Information disclosure | `_build/<env>/lib/<dep>` and `deps/` hold no secrets; `HEX_API_KEY` is used only in release.yml |

## Sources

### Primary (HIGH confidence)
- `.github/workflows/ci.yml` (full read, lines 1-930), `release.yml`, `flake-detection.yml:96-108`, `browser-full.yml` (grep).
- `test/threadline/ci_workflow_parity_contract_test.exs` (full read, 1325 lines).
- `ci_topology_contract_test.exs` (:1-300, :395-540, :600-660, :775-850).
- `ci_action_runtime_contract_test.exs:17-19`, `browser_full_projects_contract_test.exs:400-600`, `bin/browser-full-projects:1-300`.
- `mix.exs:1-40, 123, 129-130, 219-383`; `examples/threadline_phoenix/mix.exs`, `config/test.exs:60-100`, `runtime.exs:20-40`, `e2e/run-e2e.sh`; `config/test.exs`; `CONTRIBUTING.md:631-767`.
- Elixir 1.17.3 Mix source: `deps.loadpaths.ex:60-130`, `deps.compile.ex:36-46, 165, 340-360`. Elixir 1.15.8 `deps.compile.ex:38, 46, 347`.
- Live: `gh cache list --limit 8`, `gh api repos/szTheory/threadline/actions/cache/usage`, `gh pr list`, and a YamlElixir parse probe.
- `.planning/phases/218-ci-economy-remove-waste/`: `218-REMEASURE.md` §0-4, `tools/check-citations.py`, `tools/remeasure-218.py:1-120`, `218-08-PLAN.md` (the tool-copy precedent), `raw/ci/runs/36364354586.json` (step schema).

### Secondary (MEDIUM confidence)
- Discuss research r1–r4: Mix source line refs, actions/cache saveImpl behaviour, prior art. Re-used, not re-derived.

### Tertiary (LOW confidence)
- Assumptions A1–A3 (GitHub expression and hashFiles semantics, from training knowledge).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; actions already allowlisted.
- Architecture / edit map: HIGH — every line read this session.
- Contract collisions: HIGH — every pinning test read.
- Pitfalls: HIGH for 1-5, 7-9 (read in source); MEDIUM for 6 (hashFiles semantics assumed).
- Measurement: MEDIUM — the tool seam is verified; the deltas are inference until measured.

**Research date:** 2026-09-28
**Valid until:** 2026-10-28, or until ci.yml changes (line numbers go stale on any edit)
