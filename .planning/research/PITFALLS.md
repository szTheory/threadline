# Pitfalls Research

**Domain:** Supply-chain gating, CI economy, and repo hygiene for a public Elixir Hex library (Threadline 0.11.0, milestone v1.43)
**Researched:** 2026-09-26
**Confidence:** HIGH for repo-observed facts (each was checked by running the command or reading the file in this repo today). MEDIUM for GitHub Actions and Mix behaviour described from documentation and experience. LOW for single-source web claims, which are marked where used.

Phase names below are thematic, because v1.43 has no REQUIREMENTS.md or phase numbers yet:

- **P-Baseline**: measure and record the baseline
- **P-Supply**: advisory fix, audit gate, freshness policy
- **P-Economy**: flake lane, duplicate proofs, release-PR dispatch, Browser-full, `_build` cache, live Dialyzer
- **P-DX**: job names and ordering
- **P-Newest**: newest PostgreSQL/Elixir lane
- **P-TmpDir**: `@tag :tmp_dir` migration
- **P-Hygiene**: PII/local-path guard, forward scrub, xref cycles guard
- **P-Classifier**: SEED-006 change-aware lanes (last)

---

## Findings that change the milestone's own baseline

Re-checking the baseline today turned up four facts that the `## Current Milestone` text does not reflect. Read these before any phase is planned.

1. **There are two advisories, and one is not test-only.** `mix hex.audit` (Hex 2.5.1, exit 1) reports lazy_html 0.1.12 (EEF-CVE-2026-92106, LOW, `only: :test`) and **also mint 1.10.0 (EEF-CVE-2026-82672 / GHSA-rj5m-69wp-cxq9, MEDIUM, HTTP/1 response smuggling)**. mint arrives through `req` (optional runtime dependency, `mix.exs:99`) → finch → mint. Both have fixed releases: lazy_html 0.1.13 (2026-09-25) and mint 1.10.1 (2026-09-19). Calling the advisory set "test-only" is already wrong. [HIGH, observed]
2. **The xref "no cycles" claim holds only for the labelled graph.** `mix xref graph --format cycles --label compile-connected` reports none. Unlabelled `mix xref graph --format cycles` reports **5 cycles**. Two are Ecto association pairs (AuditTransaction↔AuditChange), and three are not: `Threadline`↔`Investigation`, `CriticTrust.RepositoryBoundary`↔`Mix.Tasks.Critic.Measure`, `MechanicalChecker`↔`MechanicalChecker.Contrast`. A fourth pair, `Capture.AuditTransaction`↔`Semantics.AuditAction`, crosses layers, which is the Capture↔Semantics edge v1.41 said it had resolved. It was resolved at compile time only. MILESTONE-GUIDE §9a's line "`mix xref graph --format cycles` is clean as of 2026-09-26" is false as written. [HIGH, observed]
3. **A compile-connected cycle gate already exists.** `verify.xref_cycles` (`--label compile-connected --fail-above 0`) runs in `ci.all` and in both `verify-test` lanes, and `ci_topology_contract_test.exs` guards it. "Add an xref cycles guard" means either nothing new or a *different* gate. [HIGH, observed]
4. **The live-Dialyzer test is untagged in the default suite.** `test/threadline/dialyzer_slice_contract_test.exs` carries `@tag :live_dialyzer` with a 540 s timeout, and `test_helper.exs` excludes only `pgbouncer_topology`. So it runs cold, without the PLT cache, in `verify-test (min)`, `verify-test (current)`, local `ci.all`, and **all 51 iterations of Flake Detection**. [HIGH, observed]

---

## Critical Pitfalls

### Pitfall 1: An audit gate that goes red on a commit nobody changed

**What goes wrong:**
`mix hex.audit` queries live advisory data. A new advisory published overnight turns an unchanged `main` red, blocks every unrelated PR, and can block the release-please PR that would ship the fix. Advisories are time-varying input, while every other gate in `ci-required` is a pure function of the commit.

**Why it happens:**
The gate is treated like `mix format`. The baseline already shows the drift: the milestone text lists one advisory, and the same command today lists two.

**How to avoid:**
- Keep the gate in `ci-required`, fail-closed, but give it a documented, fast escape: `hex: [ignore_advisories: [...]]` in `mix.exs` (Hex 2.5.1+). Each entry carries a comment stating the reason, the reachability claim (test-only, or not reachable), and a review-by date.
- Add a deterministic test that fails when an `ignore_advisories` entry is past its review-by date or no longer matches the lock. Hex only *warns* on a non-matching entry and exits 0, so the ignore list can rot silently.
- Add a scheduled audit on `main` (nightly, same `bin/upsert-ci-issue` dedup pattern, its own label) so a new advisory shows up as an issue before it shows up as a blocked PR.
- Audit **both** lockfiles: root and `examples/threadline_phoenix` (it has its own lock; clean today). `verify-hex-evaluator` and `verify-bump-rehearsal` resolve fresh, so they can pull advisory versions the committed locks never contain. Decide explicitly whether they are in scope.

**Warning signs:**
A red `CI required` on a docs-only PR whose only failing job is the audit. A growing `ignore_advisories` list. A "no match" warning in the gate log.

**Phase to address:** P-Supply

---

### Pitfall 2: The audit gate behaves differently depending on the Hex version

**What goes wrong:**
Advisory data in `hex.audit` and `ignore_advisories` are recent Hex features. The Hex changelog puts `ignore_advisories` and `HEX_IGNORE_ADVISORIES` in 2.5.1 (2026-07-09), and advisory warnings in `deps.get` plus advisory-aware "dependency policies" in resolution in 2.5.0 [LOW, single web source; the `mix help hex.audit` text for 2.5.1 was confirmed locally]. A phase-198 CI log in `.planning/audits/` shows runners on **hex-2.4.2**. On an older Hex the ignore key is unknown config and is silently ignored, or advisories are not checked at all. The gate is then vacuous, or red for a reason that the local run does not reproduce.

**How to avoid:**
- Run the audit in **one** dedicated job, on the current toolchain, not in every matrix lane. The min lane (Elixir 1.15) is not a supply-chain proof.
- Pin and assert the Hex version in that job: install a known Hex, then fail if `mix hex.info` reports lower than 2.5.1. A gate that cannot parse its own allowlist must fail rather than pass.
- Prove the gate is not vacuous (MILESTONE-GUIDE §8): a contract test runs the audit against a fixture lock containing a known-advisory version and asserts a non-zero exit. The gate is not done until that negative test exists.
- Watch for Hex 2.5 "dependency policies" changing resolution between local (2.5.1) and CI (older Hex) → different `mix.lock` results on `deps.update`.

**Warning signs:**
The gate passes in CI and fails locally, or the reverse. The gate log shows no "Ignored" section even though `mix.exs` has entries.

**Phase to address:** P-Supply

---

### Pitfall 3: "Fixing" the advisory by bumping public constraints adopters inherit

**What goes wrong:**
Threadline is a library, so its `mix.lock` is not shipped. Updating the lock fixes Threadline's own CI and nothing for adopters. The tempting overcorrection is to tighten `{:req, "~> 0.7", optional: true}` or add a mint floor so adopters "can't" get mint 1.10.0. That adds a public constraint for a transitive dependency Threadline does not call directly. It also risks raising the declared floor that the min lane (Elixir 1.15 / OTP 26 / PG 14) exists to prove.

**How to avoid:**
- Fix with `mix deps.update lazy_html mint` (lock only). Leave the `mix.exs` requirements alone unless Threadline's own code needs the fixed behaviour.
- Put the lock change through **both** `verify-test` lanes. Upgrades to a NIF package (lazy_html builds precompiled NIFs through `elixir_make`/`cc_precompiler`) are the classic way to break an older OTP.
- Write the freshness policy as a small cadence ("`mix hex.outdated` reviewed at each milestone open; security advisories fixed within the milestone they appear in"), not Dependabot PR churn. That matches the milestone text and Out of Scope.

**Warning signs:**
A `mix.exs` diff in the advisory-fix commit. The min lane fails to compile a NIF.

**Phase to address:** P-Supply

---

### Pitfall 4: A skipped job laundered to green through the aggregate

**What goes wrong:**
`ci-required` uses `re-actors/alls-green` with `if: always()`, which is correct today because nothing is skip-listed. The first `allowed-skips` entry changes the threat model. `allowed-skips` is **static per job and blind to the reason for the skip**. A skip allowed "for docs-only PRs" is equally allowed when:
- the job's `if:` references a misspelled output, so it evaluates `''` → false and the job never runs anywhere, permanently green;
- the job skipped because an upstream in its own `needs:` failed, and that upstream is not in `ci-required`'s `needs:`;
- the classifier job was cancelled or timed out.

**Why it happens:**
The skip decision and the skip permission live in two places that nothing links.

**How to avoid:**
- Write each conditional `if:` fail-closed. Skip only when the output is exactly `'false'`, never when it is not `'true'`: `if: needs.changes.outputs.lib != 'false' || github.event_name == 'push'`. An empty or missing output then runs the job.
- The classifier job must be in `ci-required`'s `needs:` and **never** in `allowed-skips` (MILESTONE-GUIDE §9: "a skip is allowed only when the job deciding the skip is itself required and unskippable").
- Add a step to `ci-required` that re-derives justification: for every `needs.*.result == 'skipped'`, assert the classifier's recorded output named that lane as skippable. A skip the classifier did not order fails the gate.
- Contract test: every upstream of every skip-listed job is itself in `ci-required`'s `needs:`.
- Extend `ci_topology_contract_test.exs` in the same commit as the first `allowed-skips` entry. Its header comment already demands this.

**Warning signs:**
A job with 0 runs in the last N `main` pushes. `allowed-skips` growing past the classifier-gated set.

**Phase to address:** P-Classifier (P-Economy too, if any job becomes conditional earlier)

---

### Pitfall 5: A change classifier that misreads what "docs-only" means in this repo

**What goes wrong:**
Generic path filters treat `*.md` as safe to skip. In Threadline, Markdown **is tested code**: doc-contract tests read `README.md`, `guides/`, `CONTRIBUTING.md` (the `## CI Coverage` roster and job list), and the adoption-pilot backlog markers. A README-only PR can break `verify-test`. Other non-obvious "code" includes `bin/` (verifier scripts shelled out by tests), `.github/` (the topology contract reads the workflows), `.github/rulesets/main.json`, `.tool-versions`, `priv/`, `config/`, `test/support`, `examples/**` (a path dependency on the library, with its own lock), `mix.exs`, and `mix.lock`.

**Why it happens:**
The classifier is written from intuition, not from the suite's actual file reads.

**How to avoid:**
- Classify with an **allowlist of provably inert paths** and send everything else, including unknown and new top-level paths, to the full matrix. Given the Phase-199 decoupling (`ci.all` passes with `.planning/` renamed away), `.planning/**` is realistically the only large inert class. Even there, the PII guard (Pitfall 9) must still run.
- Derive the base robustly and fail closed on edge cases: `pull_request` → merge-base with base; `push` with an all-zero `before` or a force-push → full; `workflow_dispatch` (the release-PR bootstrap) → full; any `git diff` error → full. Count renames and deletions on both sides.
- Put the classifier in a script (`bin/`) with fixture tests in ExUnit, in the same style as `bin/classify-flake-run`, including a mutation-style test that an unknown path yields "full".
- Never skip on push to `main`. The ruleset has `strict_required_status_checks_policy: false`, so the PR run tested a merge ref that may be stale against the squash commit. The push-to-`main` run is the only proof of the real tree.
- Never move the classifier to `pull_request_target` or `workflow_run` to get the diff. Fork PRs would then execute with a write token.

**Warning signs:**
`main` goes red after a PR whose run skipped `verify-test`. The classifier's fixture table has no row for a top-level directory that exists in the repo.

**Phase to address:** P-Classifier

---

### Pitfall 6: Deleting a "duplicate" proof that catches a distinct failure class

**What goes wrong:**
Several apparent duplicates in `ci.yml` differ by input, environment, or trigger:

| Looks duplicate | What actually differs |
|---|---|
| `verify-mechanical` vs the `verify.mechanical` step in `verify-capture` | committed scorecards vs freshly regenerated evidence |
| `verify-dialyzer` vs the live-Dialyzer test in both test lanes | the job is the cached, measured gate; the test checks the sealed critic-tooling slice. The min lane's copy is the only Dialyzer run on OTP 26 (whether that is worth keeping is a decision, not an assumption) |
| Browser-full's `desktop-chromium`/`mobile-chromium` vs the PR browser lane | on push to `main` it is a true duplicate (same SHA, same projects, via ci.yml's push run). Nightly on an unchanged `main` it is also a duplicate unless something time-varying (npm/Playwright cache restore-keys) enters |
| `verify-test (min)` vs `(current)` | different floor promise; never merge them |
| `verify-hex-evaluator` vs `verify-example` | Hex-published artifact vs path dependency |

**Why it happens:**
Duplicates are judged by name, not by writing down the failure class each copy uniquely catches (MILESTONE-GUIDE §8/§9).

**How to avoid:**
- Before each removal, write one line in the phase evidence: "failure class X is still caught by job Y on trigger Z". If you cannot fill in Y and Z, the job is not a duplicate.
- For Browser-full, **do not replace the unrestricted run with a hand-maintained allowlist of the "other" projects**. A new Playwright project would then run in neither lane. Use a set difference (full config project list minus the PR lane's projects), and add a contract test that the PR lane plus Browser-full equals the Playwright config's project set. Update the CONTRIBUTING `## CI Coverage` row in the same commit (`ci_coverage_doc_contract_test.exs` enforces it).
- Do not regenerate screenshot baselines as part of any browser-lane change. Locally, exactly 8 pre-existing failures are expected. A 9th is a real regression. CI (`CI=true`) is 318/0/26 by design.

**Warning signs:**
A removal PR with no "still caught by" line. The CONTRIBUTING roster edited without the topology contract test changing, or the reverse.

**Phase to address:** P-Economy

---

### Pitfall 7: A `_build` cache that serves the wrong compiled artifacts

**What goes wrong:**
The CI cache-key contract in `ci.yml` (Phase 198 D-19) already names the main risks: no `restore-keys` for `_build`, and delete `_build/$MIX_ENV/lib/threadline` before compiling. Additional traps specific to this repo:

- **Profile collision.** `verify-compile-no-optional` (`compile --no-optional-deps`), `verify-dialyzer` (`MIX_ENV=dev`), and `verify-test` (`MIX_ENV=test`) share one `mix.lock` but compile different dependency sets or environments. A key of runner+OTP+Elixir+lock lets the no-optional job restore a `_build` with Phoenix and LiveView compiled. That can false-green the "compiles without optional deps" proof. **Keep `verify-compile-no-optional` cache-free, and put `MIX_ENV` plus a job-profile segment in every `_build` key.**
- **Floating OTP in the key.** Most jobs pass `otp-version: "27.0"`, the current test lane passes `"27"`, and the keys embed that literal. A local run showed OTP `27.3.4.15`. Whatever setup-beam resolves, the key does not record the actual patch version. Use the setup-beam step outputs (resolved versions) in `_build` and PLT keys, not the requested literal.
- **deps/`_build` skew.** The `deps` cache has `restore-keys`, and `_build` must not. A near-miss `deps` restore paired with an exact `_build` hit is impossible by construction only if both keys hash the same lock. Keep them in lockstep.
- **NIF artifacts.** lazy_html's precompiled NIF is downloaded to `~/.cache/elixir_make`, outside `_build`. A cache of it must carry the NIF/OTP version.
- **Never add caches to `release.yml`'s publish path.** It is cache-free today. A cache written by any default-branch workflow can be restored into the publish job, which is the known cache-poisoning route into release artifacts.

**Warning signs:**
`verify-compile-no-optional` gets faster after the cache lands (it should not use it). "Module X is not available" or protocol-consolidation errors that clear on re-run. A cache hit on the first run after an OTP patch bump.

**Phase to address:** P-Economy

---

### Pitfall 8: Re-scoping Flake Detection by only changing its timeout or repeat count

**What goes wrong:**
The baseline shows three regimes: 16 fast failures, 12 cancellations at about 120 min, and 2 greens at 117–136 min. The job now has `timeout-minutes: 180`. Any job-level timeout cancels the job and reports nothing useful. Each full repeat (about 165 s) re-runs deterministic, heavyweight tests: the live-Dialyzer test, file-string contract tests, and `git worktree` tests. They cannot be flaky in the way the lane is hunting, and they dominate cost.

**Why it happens:**
"Repeat the whole suite N times" is the default of `--repeat-until-failure`, and the lane's budget was sized from the flag instead of from the question it answers.

**How to avoid:**
- Decide what the lane is for. If it is intermittency in DB/async/tmp tests, run a **tagged or partitioned subset** (exclude `:live_dialyzer` and pure contract tests by tag) with a fixed repeat count sized from measured per-iteration time to finish in about 60 min.
- Put a **step-level** `timeout-minutes` on the repeat step that is shorter than the job timeout, so the classify, upload, and issue steps always run. Teach `bin/classify-flake-run` a fourth outcome, `budget-exhausted-clean`, that files nothing and is not a failure.
- Fix the 16 "broken" first-iteration failures as their own item. A lane that is deterministically red is not a flake lane.
- Its deps cache key is `runner.os`-only, which the D-19 contract bans in `ci.yml`. The anti-regression grep only covers `ci.yml`. Fix the key and extend the grep to every workflow.
- No automatic retries as a cure (PROJECT.md Out of Scope).

**Warning signs:**
Any run that ends `cancelled`. Iterations per run below the configured count. The same test named in consecutive "flaky" issues (that makes it a deterministic bug).

**Phase to address:** P-Economy (P-TmpDir consumes its output)

---

### Pitfall 9: A PII/local-path guard that is noisy, leaky, or scans the wrong tree

**What goes wrong (observed shapes in this repo):**
- **Binary false positives.** A naive `<home>/` grep over tracked files matches PNG screenshot baselines and `priv/fonts/*.woff2`.
- **Legitimate paths.** Runner paths like `/home/runner/work/_temp/...` in archived CI logs under `.planning/audits/`, `~/.cache/ms-playwright` in workflow cache paths, `$HOME` in `bin/with-rehearsal-registry`.
- **The guard leaking the pattern.** Hard-coding the maintainer's username in the regex or in a test fixture commits exactly the PII the guard exists to keep out.
- **Scanning the working tree.** About 1,066 untracked machine-local critic files under `.planning/` make a working-tree scan red locally and green in CI.
- **Recurrence.** Agent tooling requires absolute paths, so GSD artifacts (STATE.md, research files, verification logs) re-introduce paths every session. A scrub without a local gate regresses within one phase.

**How to avoid:**
- Scan **tracked files only, text only**: `git grep -I -nE ...` (`-I` skips binaries), or `git ls-files` filtered by `git diff --numstat` binary detection.
- Match on shape, not on a name: `/(Users|home)/[A-Za-z0-9._-]+/` with a short generic allowlist (`runner`, `user`, `<user>`, `example`). Add Windows `C:\Users\` for completeness. Build any positive-case fixture at runtime (string concatenation) so the committed test file never contains a real-looking home path.
- Keep scope narrow and deterministic: local absolute home paths, plus optionally hostnames matching `*.local`. Names in `LICENSE` and `mix.exs` package metadata are intentional public attribution. Secrets scanning is a different tool, so don't grow this guard into gitleaks.
- Provide a documented per-line escape (a marker comment) and per-path allowlist, and make the guard **fail on unused allowlist entries** so it cannot rot.
- Run it as `mix verify.no_local_paths` (or similar) inside `ci.all` and as a fast CI job, and it must not depend on `.planning/` existing (`planning_independence_contract_test`).
- Add the negative test: a synthetic tracked-file fixture containing a runtime-built home path must make the guard exit non-zero.

**Warning signs:**
The guard's own source or test contains a real username. Allowlist entries with no justification. The guard passes locally while `git ls-files | xargs grep` still finds hits.

**Phase to address:** P-Hygiene

---

### Pitfall 10: A forward scrub that rewrites receipts, stages untracked files, or reports false completion

**What goes wrong:**
295 tracked `.planning/` files hold 978 home-path occurrences. Risks:
- `git add .planning/` stages the 1,066 untracked critic files. That publishes machine-local data, the opposite of the goal.
- A blanket regex rewrites content inside archived receipts, CI logs, and JSON (escaped `\/` forms). That breaks MILESTONE-GUIDE §8 ("do not rewrite historical receipts to look cleaner") and invalidates any recorded checksum over those files.
- "No history rewrite" means the paths remain in git history. The scrub protects the tip of `main` only. That holds only while milestone branches land by **squash PR** and milestone tags stay local (existing rule). A direct push of the milestone branch would publish the unscrubbed history.
- Executor subagents told "make the guard green" route around it: they add allowlist entries or move files (known behaviour).

**How to avoid:**
- Generate the file list with `git grep -l -I` on tracked files. Stage exactly that list (`git add -- <files>`). Assert before and after that `git status --porcelain` shows no new `A` entries outside the list.
- Replace **only the path prefix**: repo root → repo-relative, other home paths → `<home>/...` or `<home>/...`. Never alter surrounding text. Add a short note in the scrub commit on what was normalized.
- Check whether any tracked hash, lock, or evidence bundle covers a scrubbed file before rewriting it.
- Scrub first, then land the guard in the same phase, so the guard starts green on a clean baseline and not with 295 allowlist entries.
- Dispatch prompts must forbid touching the allowlist and the untracked critic tree, with a halt clause.

**Warning signs:**
Scrub diff lines that change more than a path prefix. The staged file count differs from the grep count. New `??` → `A` transitions under `.planning/`.

**Phase to address:** P-Hygiene

---

### Pitfall 11: An xref "cycles" gate that is either duplicate or unpassable

**What goes wrong:**
Adding `mix xref graph --format cycles --fail-above 0` without a label fails immediately on the 5 runtime cycles. Two are Ecto `belongs_to`/`has_many` pairs, which are idiomatic and should not be contorted away. Adding another compile-connected gate duplicates `verify.xref_cycles`.

**How to avoid:**
- Keep `verify.xref_cycles` (compile-connected, 0) as is.
- If an all-cycles guard is wanted, make it a **ratchet**: fail above the current count (5), or better, an explicit allowlist of cycle member sets where each entry has a reason ("Ecto association"). New cycles then fail while existing ones are named.
- Treat `Capture.AuditTransaction`↔`Semantics.AuditAction` as a layer-direction finding (CLAUDE.md: capture must not depend on semantics), not as allowed noise. Either fix it or record it as v1.44 debt with a reason.
- Correct MILESTONE-GUIDE §9a's "clean" claim in the same change.

**Warning signs:**
A requirement text saying "no cycles" without naming the label.

**Phase to address:** P-Hygiene

---

### Pitfall 12: A newest-version lane that is red from day one or red for good

**What goes wrong:**
A floating "latest" lane changes under an unchanged commit. The repo compiles with `--warnings-as-errors`, and newer Elixir releases keep adding type-checker warnings, so a newest-Elixir lane is likely red on arrival. Newer PostgreSQL major images change defaults (auth method, data directory layout in the official image). The PgBouncer topology job pins an image and must not silently drift with the newest lane. If the lane is required, it blocks releases on upstream churn. If it is optional and nobody watches it, it becomes permanent red noise that teaches people to ignore red.

**How to avoid:**
- **Pin exact versions** in the "newest" lane and bump them deliberately in a dedicated commit. "Newest" means "newest we have verified", not "whatever is latest tonight".
- Before wiring it in, run it once. If it is red, fix the findings or record each one. Do not land it red.
- Make it one lane of the existing `verify-test` matrix only if it is green and pinned. Otherwise run it scheduled/non-required with the dedup-issue pattern. Either choice must be reflected in CONTRIBUTING `## CI Coverage` and the topology contract in the same commit.
- Adding a matrix `lane` value changes the emitted check names (`Run test suite (<lane>)`). Branch protection uses only `CI required`, so this is safe, but the contract tests and CONTRIBUTING list the names.
- PROJECT.md lists "Elixir/OTP version bumps in CI" as Out of Scope. The milestone's newest lane is an *added* lane, not a bump of `current`. Keep it that way.

**Warning signs:**
The lane's tracking issue stays open for more than one milestone. `continue-on-error: true` appears anywhere.

**Phase to address:** P-Newest

---

### Pitfall 13: Migrating every temp-dir test to `@tag :tmp_dir`

**What goes wrong:**
There are 46 `System.tmp_dir` uses. ExUnit's `:tmp_dir` puts directories under `<project>/tmp/<module>/<test>`, **inside the git worktree** (`tmp/` is gitignored). Tests that rely on being *outside* the repository change meaning. `clean_checkout_contract_test` runs `git worktree add` into a temp path and then `git status --porcelain --untracked-files=all` at the repo root. Any test that runs `git` in a temp directory before `git init` would now walk up into the Threadline repo. Also, `:tmp_dir` wipes the directory at test *start*, not end. Long test names become long path components.

**How to avoid:**
- Migrate only tests the flake lane or CI history names as flaky, or that collide under `async: true`. Leave the git-isolation and "outside the repo" tests on `System.tmp_dir!()` plus `unique_integer` (they already use that).
- For each migrated test, check it does not shell out to `git` or `mix` with the temp directory as the working directory without its own `git init` / `mix.exs`.
- Tests that start listeners should keep their paths short (Unix socket path limit is about 104–108 bytes).

**Warning signs:**
A migrated test passes alone and fails in `ci.all`. `git status` in the repo shows unexpected entries after a test run.

**Phase to address:** P-TmpDir

---

## Moderate Pitfalls

### Release-PR double dispatch removed in the wrong direction
`bootstrap-release-pr-ci` exists because a release-please PR opened with `GITHUB_TOKEN` triggers no `pull_request` CI. The double run appears when a PAT is configured (so `pull_request` fires) **and** the dispatch fires. Removing the dispatch unconditionally leaves the release PR with no CI when no PAT is present, which is exactly the silence its `always()` comment guards against. Make the dispatch conditional on the PAT's absence, or on no CI run already existing for the head SHA. The decision must key on head SHA, the same key `gate-ci-green` uses. **Phase:** P-Economy.

### Live-Dialyzer fix that violates "honest default tests"
Excluding `:live_dialyzer` in `test_helper.exs` to save minutes is the right *kind* of change, but CLAUDE.md requires updating `test_helper.exs` and docs together, and the check must still run once, in the PLT-cached `verify-dialyzer` job or an equivalent. The existing test "Dialyzer is one blocking local and current-lane CI path with an exact measured PLT cache" must be edited in the same commit. Decide consciously whether the OTP 26 Dialyzer run on the min lane is being dropped. **Phase:** P-Economy.

### "Fastest likely failure first" implemented with `needs:` chains
Chaining heavy jobs behind `verify-format` saves minutes but lengthens the critical path. It also hides test results behind a lint failure (two round trips for the contributor), and produces "skipped" heavy jobs that `alls-green` must treat as failures (it does, as long as they are not skip-listed). Prefer ordering steps within jobs (compile → xref → test is already right) and keep fast lint jobs parallel. Gate only the costliest browser and capture lanes behind compile, if measurement shows a win. **Phase:** P-DX.

### Renaming jobs across contract surfaces
Job `name:` may change and `id:` may not. But `ci_topology_contract_test.exs`, CONTRIBUTING's roster, the ruleset byte-exact check on `CI required`, and `verify-example-browser`'s "byte-identical name" comment all read names. Rename in one commit that touches all of them. Never rename `CI required`. **Phase:** P-DX.

### Measuring the baseline once and optimizing against it forever
v1.41 found a "never re-measured red baseline". Re-measure after each economy change (per-job durations, runner-minutes per PR and per push, critical path) and cite run IDs. Runner cost and wall-clock time are separate metrics (SEED-006 notes). **Phase:** P-Baseline, then every P-Economy change.

---

## Minor Pitfalls

- **Stale local `public.threadline_capture_changes()` masks CI failures.** Any cache or `_build` change validated only locally can pass because of it. Reproduce CI-only results by renaming it away first. **Phase:** P-Economy.
- **`ci.all` red at Dialyzer is usually a local PLT cache miss** (`mix dialyzer --plt`), not a regression caused by cache-key work. **Phase:** P-Economy.
- **Never run Playwright directly.** Without an app server it produces about 45 spurious failures. Use `mix verify.example_browser`. **Phase:** P-Economy (Browser-full re-scope).
- **`.tool-versions` must pin erlang and elixir**, or bare `mix` fails. The working tree currently has an untracked `.tool-versions`. Decide whether to track it, because the newest-lane work will want a local way to switch. **Phase:** P-Newest.
- **Push and merge are classifier-blocked for agents.** A direct user grant unblocks `git push`. `gh pr merge` and the `production-hex` approval stay with the maintainer. Plan the release patch handoff accordingly. **Phase:** closeout.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `ignore_advisories` entry with no expiry | Unblocks CI today | Silent permanent acceptance of a vulnerability | Only with a reason, a reachability claim, and a review-by date enforced by a test |
| `continue-on-error: true` on the newest lane | Lane can land red | Red becomes invisible noise | Never |
| `_build` cache with `restore-keys` | More cache hits | Stale compiled artifacts, false greens | Never (already banned in ci.yml) |
| Flake lane bounded only by job timeout | Simple | Cancelled runs report nothing | Never; use a step timeout plus a budget-exhausted classification |
| Allowlisting the 295 files in the path guard instead of scrubbing | Guard lands green immediately | The allowlist becomes the policy | Never |
| All-cycles xref gate at `--fail-above 5` without naming cycles | Ratchet in one line | A new cycle can replace a fixed one unnoticed | Short-term only; move to a named-cycle allowlist |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Hex advisories | Assuming the runner's Hex matches local | Pin and assert Hex ≥ 2.5.1 in the audit job |
| re-actors/alls-green | Adding `allowed-skips` without skip justification | Classifier required and never skipped; `ci-required` checks each skip against classifier output |
| setup-beam | Cache keys from requested version literals | Keys from resolved-version step outputs |
| actions/cache | Sharing `_build` across MIX_ENV or `--no-optional-deps` profiles | Profile and env segments in the key; no cache for no-optional |
| GitHub `pull_request` trust | Using `pull_request_target`/`workflow_run` to get diff context | Plain `pull_request` with `git diff` against merge-base; fail to full |
| release-please | Dispatching CI unconditionally when a PAT also triggers it | Dispatch only if no run exists for the head SHA |
| ExUnit `:tmp_dir` | Assuming it is outside the repo | It is `<project>/tmp/...`; keep git-isolation tests on the system temp dir |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Deterministic heavy tests inside repeat-until-failure | 165 s per iteration, cancellations | Exclude by tag from the flake subset | Already broken (12 cancellations) |
| Cold Dialyzer PLT in both test lanes | About 9-minute budget test inside a 20-minute job | Run once, in the PLT-cached job | Now; grows with deps |
| Browser-full on every push plus nightly | About 17 min per push and 14 min per night for mostly duplicate projects | Set difference versus PR lane, contract-tested | Now |
| Concurrent-job cap on a 15-job matrix | PR waits on queued jobs | Measure the queue time separately from the run time | When several PRs overlap |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Treating mint 1.10.0 as "test-only" | Response-smuggling advisory in an optional runtime dependency path | Lock bump; document that adopters resolve their own mint |
| Caches restored into the publish job | Cache poisoning into a Hex release | Keep `release.yml` publish path cache-free; add a contract assertion |
| Guard test fixture containing a real home path | The guard leaks what it protects | Build fixtures at runtime |
| Pushing the milestone branch rather than squash | Publishes unscrubbed `.planning/` history | Squash PR only; tags stay local |

## UX Pitfalls (contributor DX)

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Audit gate named "Run hex audit" | Contributor can't tell it's not their change | Name it for the outcome, e.g. "Dependency advisories (hex.audit)", and print how to acknowledge an advisory |
| Classifier-skipped jobs with no explanation | "Why didn't tests run?" | The classifier writes a step summary: changed paths → lanes selected → reason |
| Flake issue says "flaky" for a budget timeout | False alarms | Separate `budget-exhausted-clean` outcome |

## "Looks Done But Isn't" Checklist

- [ ] **Audit gate:** negative test proves it fails on a known-advisory fixture; Hex version asserted; example lock audited.
- [ ] **Advisory fix:** `mix hex.audit` exits 0 on root **and** example; mint fixed too, not only lazy_html; min lane green.
- [ ] **`_build` cache:** `verify-compile-no-optional` does not restore it; keys include MIX_ENV and resolved OTP/Elixir; `rm -rf _build/$MIX_ENV/lib/threadline` present.
- [ ] **Flake lane:** a run completes, not cancelled, with classification output; `runner.os` key fixed; anti-regression grep covers all workflows.
- [ ] **Duplicate removal:** every removed proof has a "still caught by job/trigger" line; Playwright project union contract-tested.
- [ ] **Path guard:** scans tracked text files only; no real username anywhere in the guard; unused allowlist entries fail; runs without `.planning/`.
- [ ] **Scrub:** staged count equals grep count; zero `??` → `A` transitions; prefix-only diff.
- [ ] **xref:** requirement names the label; §9a corrected; Capture↔Semantics runtime cycle dispositioned.
- [ ] **Classifier:** fixture tests include unknown path → full, dispatch → full, zero-SHA push → full; `main` push never skips; `ci-required` verifies each skip.
- [ ] **Every CI topology change:** CONTRIBUTING roster, `ci_topology_contract_test.exs`, and `ci-required` `needs:` changed in one commit.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| New advisory blocks release | LOW | Add a dated `ignore_advisories` entry with reachability reason, ship, then fix in the next patch |
| Poisoned `_build` cache | LOW | Bump a key version segment; delete caches with `gh cache delete` |
| Laundered skip discovered | MEDIUM | Remove the `allowed-skips` entry (fail-closed), re-run `main`, audit runs since the change for untested merges |
| Scrub staged untracked files | MEDIUM | Unstage before commit; if committed locally, amend before any push (tags and branch are local) |
| Newest lane permanently red | LOW | Re-pin to the last green version, file the findings, bump deliberately later |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Stale baseline (mint, xref, live Dialyzer) | P-Baseline | Baseline doc re-derived from commands with outputs cited |
| Time-varying audit gate / ignore rot | P-Supply | Expiry test plus scheduled `main` audit with issue upsert |
| Hex-version-dependent gate | P-Supply | Hex version assertion plus negative fixture test |
| Public constraint overcorrection | P-Supply | Advisory commit touches `mix.lock` only; both lanes green |
| Coverage laundering via duplicate removal | P-Economy | "Still caught by" lines; Playwright union contract |
| `_build` cache poisoning or profile collision | P-Economy | No-optional job has no cache step (contract test); key grep |
| Flake lane budget and design | P-Economy | One completed classified run; iterations = configured count |
| Release-PR double dispatch | P-Economy | Release PR shows exactly one CI run per head SHA, with or without PAT |
| Live Dialyzer duplication | P-Economy | Test excluded by tag with docs updated; runs once in the cached job |
| Job naming and ordering | P-DX | Topology and ruleset contract tests green; no `needs:` chain added without measurement |
| Newest lane noise | P-Newest | Pinned versions; landed green; CONTRIBUTING row present |
| tmp_dir semantics | P-TmpDir | Only named flaky tests migrated; git-isolation tests untouched |
| Path guard noise and leak | P-Hygiene | Negative test; `git grep -I` scope; no username in the repo |
| Scrub staging and receipts | P-Hygiene | Staged = grep list; prefix-only diff |
| xref gate shape | P-Hygiene | Named-cycle allowlist or ratchet; §9a corrected |
| Skip laundering and misclassification | P-Classifier | Fixture-tested classifier; `ci-required` skip justification step |

## Sources

- Repo, observed 2026-09-26 [HIGH]: `.github/workflows/{ci,flake-detection,browser-full,release}.yml`, `.github/rulesets/main.json`, `mix.exs` aliases, `test/test_helper.exs`, `test/threadline/{ci_topology_contract,dialyzer_slice_contract,clean_checkout_contract}_test.exs`, `.gitignore`; command output from `mix hex.audit`, `mix hex.info lazy_html|mint`, `mix deps.tree`, `mix xref graph --format cycles` (with and without `--label compile-connected`), `git grep` path counts.
- `mix help hex.audit` (Hex 2.5.1, local) [HIGH]: `ignore_advisories`/`ignore_retirements`; non-matching entries only warn.
- Hex changelog (github.com/hexpm/hex CHANGELOG.md) [LOW, single source]: 2.5.0 advisory warnings in `deps.get` and dependency policies; 2.5.1 ignore configs.
- hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html; Elixir Forum "How do you use mix hex.audit in your CIs?" [LOW].
- `.planning/PROJECT.md` (Current Milestone, Out of Scope), `.planning/MILESTONE-GUIDE.txt` §8, §9, §9a, §13, `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md`.
- Maintainer memory (project-specific gotchas): PLT cache miss, Playwright direct-run, 8 pre-existing screenshot failures, stale public capture function, executor precondition workarounds, push/merge classifier block, milestone tags stay local.
- GitHub Actions behaviour (skipped required checks count as passing; cache scope by ref; `pull_request_target` trust) [MEDIUM, documentation plus the repo's own D-09/D-10 comments].

---
*Pitfalls research for: v1.43 Supply Chain, CI Economy and Repo Hygiene*
*Researched: 2026-09-26*
