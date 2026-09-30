# Phase 219: Deps-Only Build Cache - Context

**Gathered:** 2026-09-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Test jobs stop recompiling dependencies on every run. The cache must never serve a stale or wrong artifact (CACHE-01).

Two caches are added:
- a deps-only `_build` cache for the root project;
- a deps-only cache for the example app (`examples/threadline_phoenix`).

The phase also covers:
- extending the parity contract test so every rule is machine-enforced;
- documenting the live design in `ci.yml` and CONTRIBUTING;
- recording a before/after measurement against the Phase 214 baseline and the Phase 218 re-measure.

Not in this phase:
- caching the dev-env jobs (credo, dialyzer);
- the hex-evaluator, bump-rehearsal, flake-detection or browser-full caches;
- a composite setup action;
- renames (Phase 221);
- change-aware skipping (Phase 222).

</domain>

<decisions>
## Implementation Decisions

### Already locked upstream (carry forward, do not re-open)
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

### Key shape
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

### Step order and removal (the correctness core)
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

### Coverage
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

### Save policy, budget, security
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

### Observability, docs, contract
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

### Measurement (success criterion 4)
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract
- `.planning/ROADMAP.md` §"Phase 219: Deps-Only Build Cache" (~line 254) and "Cross-cutting invariants" (~line 38)
- `.planning/REQUIREMENTS.md` — CACHE-01

### Discuss-phase research (locked inputs, with evidence and line refs)
- `.planning/phases/219-deps-only-build-cache/discuss-research/r1-key-correctness.md`: Mix source verification (config tracking, consolidation location, path-dep behaviour), key globs, and prior art (Ash, CargoSense/setup-elixir-project#13, Swatinem/rust-cache)
- `.planning/phases/219-deps-only-build-cache/discuss-research/r2-save-policy.md`: measured cache usage, entry sizes, key-input churn, scope/security rules, runbook
- `.planning/phases/219-deps-only-build-cache/discuss-research/r3-coverage-measure.md`: per-job compile split (run 36364354586), coverage table, example-app design, measurement plan, expected deltas
- `.planning/phases/219-deps-only-build-cache/discuss-research/r4-contract-tests.md`: contract design, the full mutation-control list, docs pinning, composite-action analysis

### Milestone research
- `.planning/research/STACK.md` §2 "CI economy stack — Deps-only `_build` cache" (partly superseded; see correction below)
- `.planning/research/PITFALLS.md` Pitfall 7. **Correction:** bullet 3, "deps/`_build` skew — keep them in lockstep", is superseded by r1 §5. The deps cache keeps its `restore-keys`; a near-miss `deps/` with an exact `_build` hit can only cost compile time, never produce a wrong artifact.
- `.planning/research/ARCHITECTURE.md` row 9, anti-pattern 3, and the "No composite action" note. **Correction:** its critical-path row says the current lane is "unchanged" by this cache. It gains the most (about −115 s).

### Code and docs touched
- `.github/workflows/ci.yml`: the CACHE KEY CONTRACT comment (~66-96), the Dialyzer PLT split restore/save precedent (~181-243), and the verify-test, verify-pgbouncer-topology, verify-example-browser, verify-capture and verify-compile-no-optional jobs
- `.github/workflows/release.yml` (must stay cache-free), `flake-detection.yml`, `browser-full.yml`
- `test/threadline/ci_workflow_parity_contract_test.exs` (the dependency cache contract block ~382-400; the save-key check ~1216-1224)
- `test/threadline/ci_topology_contract_test.exs` (`dialyzer_topology_errors(..., contributing)` precedent)
- `test/threadline/ci_action_runtime_contract_test.exs`
- `CONTRIBUTING.md` (the "Dialyzer PLT cache and measurement contract" section, ~line 664)
- `mix.exs` (`preferred_envs` ~17-29; the `verify.example` alias ~307-316), `examples/threadline_phoenix/mix.exs` (`{:threadline, path: "../.."}` ~line 42)
- `.planning/phases/214-baseline-measurement/` (baseline doc and tools)
- `.planning/phases/218-ci-economy-remove-waste/218-REMEASURE.md`, `tools/`, `218-PATTERNS.md` (mutation-control pattern)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Dialyzer PLT split restore/save** (ci.yml ~181-243): the exact template for restore id, `cache-primary-key` save, `cache-hit != 'true'` guard and the hit-report line.
- **Parity contract helpers** (`all_workflows`, `workflow_jobs`, `job_steps`, `strip_comment_lines`, `yaml_value`, `key_value_errors`) and the `String.replace` mutation idiom.
- **214/218 measurement tools** (collector, citation checker, remeasure script) under the phase `tools/` directories.

### Established Patterns
- Keys lead with the runner label (a literal, or `matrix.runner`), then the resolved `steps.beam.outputs` OTP and Elixir.
- Contract tests pair docs with YAML through one error function that takes the CONTRIBUTING text.
- Every removal or exclusion carries a stated reason (218's "still caught by" discipline). Here, each allowlist entry and each excluded job has one.

### Integration Points
- **verify-test matrix** (ci.yml ~315-420): both lanes compile root; the current lane also runs `verify.example`.
- **verify-pgbouncer-topology** (~691-777): combined deps.get+compile `run: |` at ~753-754.
- **verify-example-browser** (~462) and **verify-capture** (~578): these compile the example app only. They also restore the root deps cache and run a root `deps.get` they don't use; that is out of scope (see Deferred).
- **verify-dialyzer's** final step overrides `MIX_ENV: test` (~284-287). It isn't cached this phase, so there's no interaction.

</code_context>

<specifics>
## Specific Ideas

- The prior-art footgun this design avoids is CargoSense/setup-elixir-project#13. A `_build` near-miss restore after a lock bump failed every PR until someone purged the caches by hand. The fix was the same as here: exact `_build`, `restore-keys` kept only for `deps/`.
- Phoenix, LiveView, Ecto and Oban cache `deps` and `_build` together, keyed on the OS family and `**/mix.lock`, with `restore-keys`. That is exactly the shape Threadline's contract rejects; don't copy it.
- Before relying on consolidation-inside-the-app-dir for the example app on the min lane (Elixir 1.15.8), confirm it. r1 verified it for root in Mix source; the example only builds on the current lane, so this is a low-risk confirmation.

</specifics>

<deferred>
## Deferred Ideas

- Dev-env `_build` cache for verify-credo and verify-dialyzer: one dev key, about −2 billed min per run. Revisit with 221/222 data.
- Restore-only `_build` cache for flake-detection.yml (about 1.5 % gain) and browser-full.yml.
- Remove the unused root deps restore and root `deps.get` from verify-example-browser and verify-capture. That is waste removal outside CACHE-01; candidate for a later economy pass.
- A composite `setup-elixir` action across all ~14 copies. Reconsider once, after Phase 221 (D-22).
- Playwright cache key keyed on the resolved `@playwright/test` version, without restore-keys (STACK.md note). Not a `_build` concern.

</deferred>

---

*Phase: 219-deps-only-build-cache*
*Context gathered: 2026-09-28*
