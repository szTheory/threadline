# R4 — Phase 219 contract-test + docs design (research, read-only)

Scope: how the CACHE-01 rules get asserted, mutation-proven, and documented.
Siblings own key shape (a), save policy/budget (b), job coverage/measurement (c).
Line numbers are as of branch milestone/v1.43 @ d3682dab.

## 0. Ground truth found

- `test/threadline/ci_workflow_parity_contract_test.exs` (1325 lines):
  - `describe "dependency cache contract"` :382-400 is the refutation to replace:
    `refute Regex.match?(~r/^\s*path:\s*_build\s*$/m, yaml)` (:398). Note it is
    line-exact: `path: _build/test`, `path: |\n  _build`, or an example-app path
    would all slip past it today.
  - Reusable private helpers already in this module: `all_workflows/0` :126,
    `workflow_jobs/1` :846, `workflow_job/2` :858, `job_steps/1` :867 (splits a job
    at 6-space `- ` items → ordered step texts), `strip_comment_lines/1` :874,
    `trimmed_lines/1`, `yaml_value/2` :1260, `cache_key_errors/3` :1210,
    `key_value_errors/3` :1238 (runner-led, resolved OTP/Elixir, no OS-family,
    no literal OTP), `toolchain_contract_errors/1` :1295 (walks every job of every
    workflow; vacuity guard "no parseable jobs").
  - `cache_key_errors` already exempts an `actions/cache/save@` step whose key is
    `${{ steps.<ANY>.outputs.cache-primary-key }}` (:1216-1224) — it does not check
    that `<ANY>` is the matching restore step's id. The new contract must.
  - Mutation-control idiom: `controls = [{label, String.replace(live, a, b)}]`,
    then `refute mutated == live` + `refute errors(mutated) == []` (:464-534,
    :536-566, :568-611; Map.update! over `all_workflows()` for other files).
  - OS-family guard widened in 218 to all workflows, comments included:
    `workflows_os_family_context_errors/1` :1281, test :733. Needles are
    assembled (`"runner" <> ".os"`) so the test file never contains them.
- `ci_topology_contract_test.exs` `dialyzer_topology_errors(mix_exs, yaml, contributing)`
  :402 is the precedent for (1) ORDER via `position/2` + `ordered_positions?/1`
  (:629-638) and (2) a contract function that takes CONTRIBUTING text as an input.
  Its PLT split restore/save assertions (:437-455: separate restore/save actions,
  stable id, save key = restore's `cache-primary-key`, `cache-hit != 'true'`) are the
  exact template for the `_build` split.
- Parsing: every CI contract test is text/regex + `strip_comment_lines`. `yaml_elixir`
  (~> 2.11, test-only, mix.exs:123) is used only by community_health_render and
  deps_health_report tests.
- Workflows with caches today: ci.yml (deps in 8 jobs, PLT, Playwright, setup-node
  `cache: npm`), browser-full.yml, flake-detection.yml (deps). **release.yml has no
  cache step of any kind** (jobs: release-please, sync-release-pr-pins,
  bootstrap-release-pr-ci, dispatch-bootstrap, release-ref, gate-ci-green,
  publish-hex, smoke-published, distribution-sync).
- Traps the contract must encode (not visible from the locked text):
  1. **MIX_ENV unset in some jobs.** verify-credo, verify-format,
     verify-compile-no-optional, verify-example-browser, verify-capture declare no
     job-level `MIX_ENV`. `rm -rf _build/$MIX_ENV/lib/threadline` there expands to
     `_build//lib/threadline` — a silent no-op, while `preferred_envs` (mix.exs:17-29)
     may compile into `_build/test`. A cached job must declare a literal job-level
     `MIX_ENV`, the key must carry `${{ env.MIX_ENV }}`, and the rm should use
     `${MIX_ENV:?}` so it fails loudly at runtime.
  2. **Step-level MIX_ENV override.** verify-dialyzer is `MIX_ENV: dev` but its last
     step runs `MIX_ENV: test` (ci.yml:284-287). Harmless iff the cache path is
     env-scoped (`_build/${{ env.MIX_ENV }}`) and the override comes after save.
  3. **Example app path dep.** `examples/threadline_phoenix/mix.exs:42`
     `{:threadline, path: "../.."}`; `mix deps.compile` in the example compiles
     threadline itself into `examples/threadline_phoenix/_build/test/lib/threadline`
     (confirmed present locally). So an example deps-only save would **contain the
     code under test** unless the rm (of both `lib/threadline` and
     `lib/threadline_phoenix`) runs **before save**, not only before compile.
     Also `verify.example` (mix.exs:307-316) does deps.get + compile in one bash
     string, so the workflow needs explicit pre-steps for the example block.
  4. **Combined run steps.** verify-pgbouncer-topology does `mix deps.get` and
     `mix compile` in one `run: |` (ci.yml:753-754) — no place to put restore/save/rm
     between them. Contract should require deps.get / deps.compile as their own steps
     in a cached job.
  5. **Roadmap vs requirement wording on no-optional.** SC3: "contain no cache
     step"; CACHE-01: "stay cache-free". verify-compile-no-optional has a `deps`
     cache today (ci.yml:302-307). ARCHITECTURE.md row 9 even proposed caching it
     under a separate key segment (superseded). Decide and record in 219-CONTEXT:
     either remove its deps cache (literal) or pin the reading "no `_build` cache"
     — otherwise the verifier will flag it. Recommendation: literal compliance is
     cheapest to verify (drop the deps cache there; ~seconds of deps.get), OR record
     the narrower reading as a decision. Pick one explicitly.

## Q1. Parsing approach — RECOMMENDATION: text-based, step-list ordering, in the parity file

Use the existing text helpers, not YamlElixir, for the contract itself:
- Consistency: every sibling CI contract (parity, topology, runtime, release control
  plane) is text-based; mutation controls are `String.replace` on the live text and
  re-run the same function. A YAML-parse contract would need a second mutation idiom.
- Comment robustness is already solved: `job_steps(strip_comment_lines(job))`
  drops the CACHE KEY CONTRACT comment (which mentions `_build` and the rm command)
  before classification. The OS-family guard is the only rule that deliberately
  scans comments.
- Ordering: classify each step of a cached job into one atom
  (`:restore_build | :deps_get | :deps_compile | :save_build | :rm_own | :mix_other | :other`)
  and compare **step indices**, not byte offsets (topology's `position/2` works but
  byte offsets are fooled by a comment or a later step that repeats a needle).
- Recommended order rule (fail-closed, easiest to explain): the five steps are
  **contiguous** in exactly `restore → deps.get → deps.compile → save → rm`, and no
  step before `restore` runs `mix` (other than `local.hex/rebar`). Contiguity means
  there is nothing between save/rm and "compile" to reason about: any later `run:`
  (aliases like `mix verify.credo`, bin scripts that shell out to mix) is after rm by
  construction. For the example block, contiguous
  `restore → deps.get+deps.compile → rm(both apps) → save` (see trap 3).
- One cheap YamlElixir anti-drift assert: for each cached job, the parsed
  `length(steps)` equals `length(job_steps(...))`. Proves the regex splitter still
  sees every step (guards against an indentation change making the contract vacuous).
- Placement: rewrite `describe "dependency cache contract"` in
  ci_workflow_parity_contract_test.exs (SC3 names "the parity contract test", and the
  private helpers live there). One pure function
  `build_cache_errors(yaml_by_path, contributing)` → `[String.t()]`, asserted `== []`.
- Legible messages: every error names file, job, step name, the rule, why, and the
  fix, e.g.
  `ci.yml verify-test: step "Restore deps build" declares restore-keys: — a partial
  restore across a changed mix.lock serves stale compiled deps. Delete the line
  (CONTRIBUTING "Deps-only build cache").`
  Order errors print the observed sequence:
  `verify-test cache steps run [restore, deps.get, save, deps.compile, rm]; expected
  contiguous [restore, deps.get, deps.compile, save, rm]`.

## Q2. Assertions (all over `all_workflows()`, comments stripped)

Detection: a step is a build-cache step if it `uses: actions/cache(/restore|/save)?@`
and its uncommented text contains `_build` anywhere (not only a single-line `path:`),
so `path: |` block scalars cannot hide it.

Per workflow/job:
1. **Placement allowlist** — `@build_cache_jobs %{{path, job} => reason}` (fail-closed,
   like `@beam_independent_cache_paths`); any build-cache step elsewhere errors, and
   every allowlist entry must be used (ci_action_runtime "every allowlist entry is
   used" pattern). Entries come from sibling (c)'s job list.
2. **Denylist** (explicit, belt-and-braces, own message):
   - `.github/workflows/release.yml`: **no `actions/cache*` step at all, whole file**
     (true today, zero cost, covers publish-hex, release-ref, gate-ci-green,
     smoke-published without arguing what "publish path" means).
   - `verify-compile-no-optional`: no build-cache step (plus no cache at all if the
     literal reading of SC3 is chosen — trap 5).
3. **Split only**: build caches use `actions/cache/restore@v5` + `actions/cache/save@v5`;
   a combined `actions/cache@` naming `_build` errors.
4. **No `restore-keys:`** on any build-cache step (restore or save).
5. **Restore has an `id:`**; save key is exactly
   `${{ steps.<that restore id>.outputs.cache-primary-key }}`; save `if:` is exactly
   `steps.<that id>.outputs.cache-hit != 'true'`; save `path:` == restore `path:`.
6. **Key segments** (restore key), from one module attribute `@build_key_segments` so
   sibling (a)'s final shape is edited in one place: runner-led (existing
   `key_value_errors`), `steps.beam.outputs.otp-version`, `...elixir-version`,
   `${{ env.MIX_ENV }}`, the profile token (a's choice), `hashFiles('mix.lock')`,
   the config hash (a's choice, e.g. `hashFiles('config/**')`); example block uses
   `examples/threadline_phoenix/mix.lock` and its config glob. Plus a version token
   if (a)/(b) adopt a `build-vN` bump segment (makes the runbook's "bump" path real).
   Key must also differ from every deps/PLT key (no accidental cross-path collision).
7. **Env**: cached job declares a literal job-level `MIX_ENV:`; restore `path:` is
   `_build/${{ env.MIX_ENV }}` (env-scoped); no step-level `MIX_ENV:` override
   before the save step.
8. **rm step**: named step, `run:` contains
   `rm -rf "_build/${MIX_ENV:?}/lib/threadline"` (or the locked literal
   `rm -rf _build/$MIX_ENV/lib/threadline` — pick one exact string); unconditional
   (no `if:` — must run on hit AND miss). Example rm removes both
   `examples/threadline_phoenix/_build/test/lib/threadline` and `.../lib/threadline_phoenix`.
9. **Order**: contiguous block per Q1; setup-beam before restore (already covered by
   `beam_ordering_errors`); deps.get / deps.compile are standalone steps.
10. **No built-in caching of builds**: any `cache:` input in any workflow must be
    `cache: npm` on `actions/setup-node` with a `cache-dependency-path:`;
    a `cache:` input on setup-beam or anywhere else errors (future-proofs against
    an action gaining a build cache).
11. **Docs parity**: the ci.yml CACHE KEY CONTRACT comment no longer contains
    "currently NO `_build` cache"; CONTRIBUTING's build-cache section exists, names
    the rm command, "no `restore-keys`", `gh cache delete`, and lists exactly the
    allowlisted cached job ids (MapSet equality, like the List 1 roster test).

## Q3. Mutation controls (each: `refute mutated == live`, then assert the *specific*
error fragment appears — stronger than 218's `refute errors == []`, because with ~15
rules a mutation could trip an unrelated rule and still "pass")

On ci.yml (verify-test block unless noted):
1. delete the rm step → "must remove _build/.../lib/threadline"
2. move rm after the first compile/run step → order error
3. insert `restore-keys: <prefix>` under the build restore → restore-keys error
4. move save below `Compile` → order error
5. save key → literal key string → "must reuse cache-primary-key"
6. save key → `steps.dialyzer-plt-restore.outputs.cache-primary-key` → "wrong restore id"
7. drop save `if:` / flip `!=` to `==` → guard error (two controls)
8. for each `@build_key_segments` entry, delete it from the key → segment error (loop)
9. replace restore/save pair with one `actions/cache@v5` → split error
10. remove job-level `MIX_ENV:` → env error
11. put `if:` on rm step → unconditional error
12. clone the build restore step into verify-compile-no-optional → denylist error
13. `Map.update!(all, "release.yml", ...)` inserting an `actions/cache/restore@v5`
    step into publish-hex, and a second into smoke-published → release error
14. `Map.update!(all, "flake-detection.yml", ...)` add a build cache (or verify-format
    in ci.yml) → allowlist error
15. block-scalar path `path: |\n            _build/test` in an unlisted job → detected
16. example block: drop `lib/threadline_phoenix` from rm; move example rm after save
17. `setup-beam` gains `cache: true` → built-in cache error
18. re-insert "There is currently NO `_build` cache" in the ci.yml comment; delete the
    CONTRIBUTING runbook's `gh cache delete` line → docs errors
Positive control: add `      # _build note` comment lines to verify-format → errors
stay `[]` (proves comment-robustness is real, not assumed).

## Q4. Docs — RECOMMENDATION: yes, rewrite the comment; yes, add a CONTRIBUTING section; pin both from the same contract function

- ci.yml comment (:66-96): replace "There is currently NO `_build` cache … If one is
  ever added, two rules apply" with the live design in present tense: split
  restore/save, exact key segments, no restore-keys, env-scoped path, contiguous
  order, rm before compile (and before save for the example), cache-free no-optional
  and release.yml, pointer to CONTRIBUTING. Keep it short; the 199 PLT paragraph is
  historical and can shrink. Keep the OS-family needle out (guard scans comments).
- CONTRIBUTING: new `### Deps-only build cache` under "CI parity and `act`", next to
  "Dialyzer PLT cache and measurement contract". Contents: what is cached (deps-only
  `_build/<env>` + example `_build/test`), which jobs (list — pinned), the key
  segments, why no restore-keys and why the rm, which jobs are deliberately
  cache-free and why, and a **poisoned-cache runbook**:
  1. symptom (failure that disappears on a cold run / "works locally");
  2. confirm: rerun with the cache bypassed or `gh cache list --key <prefix>`;
  3. evict: `gh cache delete <key>` (or by id; `--all` as last resort) — maintainer,
     needs actions:write;
  4. durable fix / audit trail: bump the key version segment in a PR (if (a)/(b)
     adopt one) so every lane goes cold once;
  5. note that PR-scoped caches are only visible to that PR; a poisoned main-branch
     entry affects all PRs.
- Doc contract: warranted and conventional (OSS DNA "doc contract tests"; topology's
  `dialyzer_topology_errors(..., contributing)` already pins the PLT section). Do it
  inside `build_cache_errors(yaml_by_path, contributing)` — not a separate
  `*_doc_contract_test.exs` (that filename pattern is swept into
  verify-bump-rehearsal's doc-contract run, which is fine but unnecessary).

## Q5. Composite action — RECOMMENDATION: stay inline

- Every contract helper is job-block text; a local `./.github/actions/*` action moves
  the load-bearing text into action.yml and forces: an action.yml parser path, a
  "cached job uses the action with the right inputs" rule, and a
  ci_action_runtime change (`./` refs are classified `:needs_decision` today, :72).
- The rm step is the single most important safety line; inline it is a visible,
  separately-timed step in the job's CI UI ("Remove own build"), and restore hit/miss
  is visible per step. In a composite it is a collapsed sub-step.
- The contiguity rule + mutation controls make copy-paste drift fail CI with a fix
  message, which removes the main argument for a composite (drift).
- `verify.example` and act parity stay readable.
- Revisit only as one deliberate consolidation after the roster settles (post-221),
  folding setup-beam + deps + build cache (all ~14 copies) at once, with the contract
  rewritten once — not piecemeal in 219.
