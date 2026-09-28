# Phase 219 research: save/restore policy, cache budget and eviction, security (R2)

Researched 2026-09-27. Read-only: no repo edits, no cache deletes. The sources are
listed at the end.

## 0. Measured facts (this repo, now)

- `gh api repos/szTheory/threadline/actions/cache/usage`: **57 entries, 636.9 MB**
  (6.4% of 10 GB).
- The largest entry is the Playwright browsers at **271 MB**
  (`ubuntu-24.04-playwright-17f0…`, main). The next is the npm setup-node cache
  at 15 MB. Each Dialyzer PLT is about 8.3 MB. Each deps entry is 3–5.8 MB.
- **PR-scoped saves already happen today.** The PLT's save runs on every miss,
  so there are entries on `refs/pull/60/merge`, `refs/pull/56/merge` and
  `refs/pull/55/merge`, plus `refs/heads/release-please--branches--main` and
  `refs/heads/land/v1.43-217-218`. PR 60 holds two PLT entries, because its
  mix.exs changed between pushes. The older one was last accessed after it was
  created, so later pushes to the same PR did restore from PR scope. This
  confirms that re-pushes, and not only re-runs, reuse `refs/pull/N/merge`
  entries.
- The resolved key segments render as `OTP-27.3.4.15` and `v1.17.3-otp-27`.
- Local deps-only build sizes, measured on macOS as tar | zstd -3. This
  approximates actions/cache's zstd tar.
  - Root `_build/test/lib` minus `threadline`: 18.7 MB raw, **10.5 MB
    compressed** (41 apps).
  - Root `_build/dev/lib` minus `threadline`: **10.9 MB compressed**.
  - Example `_build/test/lib` minus `threadline` and `threadline_phoenix`:
    **14.6 MB compressed** (57 apps).
- Key-input churn on main over 30 days (main had 19 commits in that window):

  | Input | Commits in 30 days |
  |---|---|
  | mix.lock | 4 |
  | config/ | 2 |
  | mix.exs | **9** (release-please bumps `@version` every release) |
  | example mix.lock | 1 |
  | example config/ | 2 |

- Triggers: nothing uses `pull_request_target` or `issue_comment`.
  - The three `workflow_run` workflows (branch-protection, community-health,
    environment-protection) filter to `branches: [main]`, check out main and
    have no cache steps.
  - release.yml (push main plus dispatch) has **no** actions/cache and no
    `cache:` inputs today.
  - Only ci.yml, flake-detection.yml and browser-full.yml use caches.

## Q1. Which refs save

Scope rules, from the GitHub docs:
- A run can restore caches from its own ref, from the default branch and, for
  a PR, from the base branch.
- A cache saved by a `pull_request` run is created under `refs/pull/N/merge`
  and can only be restored by later runs of that same PR.

The two options only differ on PRs that change a key input themselves (lock,
config, toolchain). Every other PR gets an exact hit from main's scope, so its
save step never runs. `actions/cache/save` also no-ops when the restore matched
exactly.

| | Save on every exact miss (all refs) | Save only on push to main |
|---|---|---|
| A deps-bump PR with k pushes | 1 cold build, then k-1 warm | k cold builds |
| Extra budget | ~50–70 MB per key-changing PR generation (see Q3), gone after 7 days unused | 0 |
| Poisoning surface | None added (PR scope is not visible to main or other PRs) | Same |
| Consistency | Matches the existing PLT, deps, Playwright and setup-node behaviour | A new special case in the contract |

Prior art:
- Swatinem/rust-cache recommends `save-if: github.ref == 'refs/heads/main'`,
  and gradle/setup-gradle defaults `cache-read-only: true` off the default
  branch. Both exist because Rust `target/` and Gradle homes are multi-GB, so
  PR saves evict the main entries everyone needs.
- setup-node and setup-go save on any ref.
- At about 10–15 MB per entry with 9.4 GB free, the Rust/Gradle reason does not
  apply here.

**Recommendation: save on exact miss on every ref, guarded by**
`if: steps.<restore>.outputs.cache-hit != 'true'`. This matches the PLT pattern.
- The save step keeps the default `success()` condition. Never use `always()`
  on it: a failed `deps.compile` must not persist a half-built tree.
- Revisit only if usage passes about 5 GB (see the guard in Q3).

## Q2. Concurrency and save failure

- actions/cache saveImpl.ts catches every error, including the "Unable to
  reserve cache … another job may be creating this cache" error, with
  `utils.logWarning`. It also installs an uncaughtException→warning handler. **A
  save step never fails the job**, so do not add `continue-on-error`. That
  would also collide with the milestone's "no continue-on-error on a voting
  job" invariant and its grep.
- A race only happens when two jobs in one run compute the **same** key. Today
  that could be verify-test(current) against verify-pgbouncer-topology (both
  MIX_ENV=test on the same toolchain), and verify-example-browser against
  verify-capture (the example app).
- The loser's only cost is a warning line and a wasted upload.
- **Recommendation: put a job-profile segment in every key** (for example
  `build-test-suite`, `build-test-pgbouncer`, `build-dev-dialyzer`,
  `example-build-test`) rather than naming one designated writer.
  - It removes the race, and it removes the cross-job "compiled a different dep
    set" risk (Pitfall 7).
  - It costs about 10 MB more per extra profile.
  - If sibling (a) proves two jobs compile byte-identical trees and chooses to
    share one key, the race is harmless. Accept it; do not add a
    `needs:`-ordered writer, which would lengthen the critical path.
- A cancelled PR run (cancel-in-progress) leaves an uncommitted upload
  reservation. That is harmless: the entry is not committed, and the next run
  misses and saves.

## Q3. Eviction math

- Distinct `_build` keys per key-input generation, taking the job set after 218
  with a profile segment:

  | Profile | Compressed size |
  |---|---|
  | test min lane | ~10 MB |
  | test current lane | ~10.5 MB |
  | dev dialyzer | ~11 MB |
  | pgbouncer test, only if cached separately | ~10.5 MB |
  | example test (1 key, or 2 if browser and capture differ) | ~15 MB (or ~30 MB) |

- That is **about 45–75 MB per generation** in main scope.
- Churn:
  - About 6 lock/config changes a month gives about 0.45 MB per day of new main
    entries.
  - The 7-day unused expiry keeps about 1–2 live generations: **≤ 150 MB**.
  - PR-scope generations add about 70 MB per key-changing PR, also gone after 7
    days.
  - Realistic added total: **< 0.5 GB**, for a steady state of **about 1.1 GB of
    10 GB**.
  - LRU eviction (oldest access first) never triggers. Playwright (271 MB,
    accessed daily) is not at risk.
- **Watch-out for sibling (a):** if `mix.exs` enters the `_build` key, every
  release bump (9 commits in 30 days) cold-busts all profiles, on main and on the
  release-please branch. That is a key-shape cost, not a budget one. Hash only
  the deps/config inputs, or accept it knowingly. Unlike the PLT, the `_build`
  key does not need `mix.exs`, because the lock and MIX_ENV fix the deps tree.
  Resolved `only:` or `optional` flags are the one exception, so keep that
  decision explicit.
- **Recommendation: no cleanup workflow.**
  - Rely on the 7-day expiry. A cleanup job would need `actions: write`, which
    widens the token surface for zero budget benefit.
  - Do not buy more than 10 GB.
  - Add a cheap **static guard**: the parity contract test enumerates the
    allowed `_build` key profile segments, an exact set. Any new profile then
    changes the test and forces a budget thought.
  - Optionally, sibling (b)'s measurement records `active_caches_size_in_bytes`
    before and after, as the cited budget proof.

## Q4. Security

- **The PR to main direction is impossible.** A `pull_request` run, from a fork
  or not, writes only to `refs/pull/N/merge`. A push-to-main run can restore
  only from `refs/heads/main`, because main is both its own ref and the default
  branch. Neither main, the release-please branch nor other PRs can ever see a
  PR entry. Fork PRs get a read-only GITHUB_TOKEN but can still save within
  their own merge-ref scope. That is harmless.
- **What can write to main scope:**
  - Any run whose ref is main: ci push, browser-full push/schedule, flake
    schedule/dispatch, deps-health, release.yml.
  - `workflow_run` and `pull_request_target` runs, which execute in the default
    branch context. That is the known cache-poisoning route (Adnan Khan's
    "Cacheract", 2024), used together with a forced >10 GB eviction to plant
    entries under predictable keys.
  - Today no workflow runs untrusted code in main context, so the cache adds no
    new trust boundary. Poisoning main would need merged code or a compromised
    dependency, and either already executes in CI.
  - Cache entries are immutable per key and ref, so an existing key cannot be
    overwritten, only evicted and replanted.
- **Recommended contract assertions**, beyond sibling (c)'s key rules:
  1. release.yml has no `uses: actions/cache` (with or without `/restore` or
     `/save`) and no `^\s*cache(-dependency-path)?:` input on any setup-*
     action. Also refute `restore-keys`.
  2. `verify-compile-no-optional` has no cache step touching `_build`. Its deps
     cache is a separate question for sibling (a).
  3. Generalization: a cache step may appear only in workflows whose `on:`
     triggers are a subset of {push main, pull_request, schedule,
     workflow_dispatch}. Equivalently, no workflow with `pull_request_target`,
     `workflow_run` or `issue_comment` has a cache step. That makes the
     poisoning precondition itself a red test.
  4. The save step has no `always()` or `failure()` condition.
- **Example-app trap (hand to sibling a).** The example depends on
  `{:threadline, path: "../.."}`. `mix deps.compile` in the example compiles
  path deps, so a save after `deps.compile` would capture
  `examples/threadline_phoenix/_build/test/lib/threadline`, which is the code
  under test.
  - Remove both `lib/threadline` and `lib/threadline_phoenix` before the save.
    Alternatively, exclude them with a `!path` pattern in `path:`.
  - Also remove them after restore.

## Q5. Observability and runbook

- **Yes.** Emit one always-run line per cache, next to the existing
  `THREADLINE_DIALYZER_PLT_CACHE=hit|miss`:
  `echo "THREADLINE_BUILD_CACHE=${{ steps.build-restore.outputs.cache-hit == 'true' && 'hit' || 'miss' }}"`
  and `THREADLINE_EXAMPLE_BUILD_CACHE=…`. Also echo the primary key, from the
  `cache-primary-key` output.
  - One line with an exact value is greppable by sibling (b)'s before/after
    tooling, and the contract test can pin it.
  - Use one unconditional step rather than two conditional ones, so the line is
    always present.
- **Runbook.** Put it in CONTRIBUTING.md as a "Dependency build cache" subsection
  next to "### Dialyzer PLT cache and measurement contract" (line ~664). That is
  the file contributors already read, and doc-contract tests already pin it. It
  should contain:
  1. Symptoms: "module X is not available", protocol-consolidation errors that
     clear when the cache is bypassed, or a hit right after a toolchain bump.
  2. Inspect: `gh cache list --key <prefix> --ref refs/heads/main`.
  3. Delete: `gh cache delete <key>` (maintainer, needs `actions: write`), or
     `gh cache delete --all --ref refs/pull/N/merge` for a PR.
  4. Belt and braces: bump a literal version segment in the key (for example
     `-build-v1-` to `-v2-`). A fix that ships through a normal PR needs no
     privileged API call.
  5. Emergency bypass: re-run with the cache step skipped is **not** possible
     without a YAML edit, so the version bump is the documented path.
- Put a literal `v1` segment in the key template from the start.

## Sources

- GitHub docs, "Dependency caching reference": access restrictions, 10 GB limit,
  7-day expiry, LRU eviction, billed overage up to 10 TB, and the poisoning note.
- actions/cache `src/saveImpl.ts`: errors become warnings, and the save is
  skipped on an exact primary-key hit.
- Swatinem/rust-cache README (`save-if`), gradle/actions setup-gradle
  (`cache-read-only` defaults to true off the default branch), actions/setup-node
  and setup-go cache behaviour. These are from knowledge and were not re-fetched.
- Adnan Khan, "The Monsters in Your Build Cache: GitHub Actions Cache Poisoning"
  (2024). From knowledge.
- Live: `gh cache list --limit 100`, the `actions/cache/usage` API, local `du`
  and zstd, and git log churn.
