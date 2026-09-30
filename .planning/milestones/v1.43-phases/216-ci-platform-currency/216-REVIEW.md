---
phase: 216-ci-platform-currency
reviewed: 2026-09-27T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/deps-health.yml
  - .github/workflows/flake-detection.yml
  - .github/workflows/release.yml
  - .tool-versions
  - CONTRIBUTING.md
  - bin/verify-bump-rehearsal
  - test/threadline/ci_action_runtime_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/release_control_plane_contract_test.exs
findings:
  critical: 1
  warning: 2
  info: 5
  total: 8
status: issues_found
---

# Phase 216: Code Review Report

**Reviewed:** 2026-09-27
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Scope: the diff `35d7ee8c..HEAD` for the listed files. That covers the `.tool-versions` pin read through `erlef/setup-beam` strict mode, the Node 24 action majors, the cache keys built from resolved outputs, the min lane moving to ubuntu-24.04, the 216-08 `.toolchain-pin` fix, and four contract test files. All 63 contract tests pass locally.

The toolchain wiring itself is correct:
- Every job that reads `steps.beam.outputs.*` declares `id: beam`.
- The matrix row that sets no toolchain source renders as an empty input.
- The mutation controls genuinely fail when their input changes, and each control asserts that its input actually changed.
- The 216-08 fix works. actions/checkout empties a workspace root that has no `.git`, so `.toolchain-pin/` is removed before the target-ref checkout, and nothing else reads the root `.tool-versions`.

The main concern is credential hygiene in `release.yml`. The phase added `persist-credentials: false` to the harmless sparse pin checkout in `publish-hex` and `smoke-published`. It did not add the flag to the checkout that goes on to compile third-party dependencies. In `smoke-published`, that checkout persists a token with inherited `contents: write`. The new credential contract covers only `sync-release-pr-pins`, so it cannot catch this. The remaining findings are doc drift and contract checks that are weaker than they claim to be.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `smoke-published` persists a `contents: write` token into `.git/config`, then compiles third-party Hex code

**File:** `.github/workflows/release.yml:34-37, 562-627` (also `451-453`); `test/threadline/release_control_plane_contract_test.exs:143-161`
**Issue:**
- `smoke-published` has no job-level `permissions:` block, so it inherits the workflow-level `contents: write`, `pull-requests: write` and `issues: write` (lines 34-37).
- Its target-ref checkout (lines 616-618) leaves `persist-credentials` at the default `true`. That writes the GITHUB_TOKEN into `.git/config` as an extraheader.
- The next steps run `mix verify.hex_evaluator`, which fetches and compiles `threadline` and its dependencies from hex.pm. Any dependency's compile-time code can read `.git/config` and push commits or tags, or edit PRs and issues.

This is exactly the threat the `sync-release-pr-pins` comment (lines 150-153) and 202-REVIEW WR-01 describe. Phase 216 rewrote this block of steps: it added `persist-credentials: false` to the sparse pin checkout, which runs no code, and left it off the checkout that does. `publish-hex` (lines 451-453) has the same pattern, with a `contents: read` token held during `mix deps.get` / `mix hex.build`.

The new contract (`checkout_count == credential_free`) is scoped to `sync-release-pr-pins` alone. It cannot catch either job, and the parity test's `sparse_errors` checks only the sparse checkouts. The gap was there before this phase, but the phase touched these exact steps and added a contract that implies the rule is enforced.
**Fix:**
```yaml
  smoke-published:
    ...
    permissions:
      contents: read
    steps:
      ...
      - uses: actions/checkout@v5
        with:
          ref: ${{ needs.release-ref.outputs.checkout_ref }}
          persist-credentials: false
```
Do the same for the `publish-hex` target-ref checkout. Then widen the release control-plane assertion to every release.yml job that runs `mix`. For each of `sync-release-pr-pins`, `publish-hex` and `smoke-published`, require `checkout_count.(job) == credential_free.(job)`, and add a mutation control per job.

## Warnings

### WR-01: CONTRIBUTING hard-codes the pinned versions with no contract tying them to `.tool-versions`

**File:** `CONTRIBUTING.md:23-24, 31, 563, 581-582`
**Issue:** The phase makes `.tool-versions` the single source of the current-lane toolchain. CONTRIBUTING still repeats the literal values in five places: `27.3.4.15`, `1.17.3`, `1.17.3-otp-27` and `22.14.0`. No test reads `.tool-versions` and checks the prose against it. The only other `27.3.4.15` in `test/` is a mutation-control literal in the parity test. At the next pin bump, CI will silently run a different build from the one the docs name. That breaks the project's "doc contract tests keep README/guides aligned" convention (CLAUDE.md, CI & Verification Conventions).
**Fix:** Add an assertion to `ci_workflow_parity_contract_test.exs`: parse the `erlang` and `elixir` values from `.tool-versions` (reusing `tool_versions_errors/1`'s parser), then assert that every `OTP 27.x…` / `Elixir 1.x…` version mentioned in CONTRIBUTING's Requirements, `verify-dialyzer` row and Dialyzer paragraph equals those values. Include a mutation control that bumps `.tool-versions` text only. Alternatively, drop the literals from the prose and point readers to the file.

### WR-02: The Release Please runbook contract is weaker than CONTRIBUTING step 4 says

**File:** `test/threadline/ci_action_runtime_contract_test.exs:124-158`; `CONTRIBUTING.md:778-781`
**Issue:** Step 4 says "a contract test fails if the action major in `release.yml` and this section disagree", but the checks are much looser:
- `String.contains?(section, "googleapis/release-please-action@v#{major}")` is a substring test, so `@v5` is also satisfied by `@v50` or `@v5x`.
- A section that names both an old and a new major passes. Bumping to v6 and mentioning `@v6` anywhere in the section, while leaving `Last rehearsal (…) @v5 (release-please 17.6.0)` untouched, passes.
- The library-version check (`release-please(?: |@)\d+\.\d+\.\d+`) is satisfied by the stale record, so "update the rehearsal record in the same change" is not enforced.
- `Regex.run` inspects only the first `release-please-action@vN` in release.yml, so a second ref at a different major is never compared.
**Fix:** Parse the `Last rehearsal` line specifically and assert that its `googleapis/release-please-action@vN` equals the major in release.yml, using a word boundary (`@v#{major}\b`). Use `Regex.scan` over release.yml and require exactly one distinct major. Add a mutation control that changes release.yml to v6 and appends `@v6` elsewhere in the section, and confirm that the stale `Last rehearsal` line still fails the test.

## Info

### IN-01: The cache-key contract accepts any `ubuntu-24.04-` prefix regardless of the job's `runs-on`

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1222-1236, 1250-1260`
**Issue:** `key_value_errors/3` requires keys to start with the literal `ubuntu-24.04-` (or `${{ matrix.runner }}-`), but never compares that label with the job's `runs-on:`. `runner_image_errors/2` bans only `ubuntu-22.04`, so a job moved to `ubuntu-latest` or `ubuntu-26.04` keeps a key that misnames its image and still passes. The resolved OTP/Elixir segments limit the damage.
**Fix:** In `job_toolchain_errors/2`, extract the job's `runs-on:` value and require each key's leading label to equal it (or to be `${{ matrix.runner }}` when `runs-on` is `${{ matrix.runner }}`).

### IN-02: `.tool-versions` pins Node 22.14.0, but CI floats on `"22"`

**File:** `.tool-versions:1`; `.github/workflows/ci.yml:470, 626`; `.github/workflows/browser-full.yml:73`
**Issue:** CONTRIBUTING admits this, but the pinned Node line is not the source CI uses, so the browser lane and a local asdf shell can differ.
**Fix:** Use `node-version-file: .tool-versions` on `actions/setup-node@v5` (it supports asdf files), or drop `nodejs` from `.tool-versions`.

### IN-03: The runbook snippet puts the GitHub token on the command line and uses a GNU-only sed escape

**File:** `CONTRIBUTING.md:770-772`
**Issue:** `--token="$(gh auth token)"` puts the token in the process argv, where `ps` shows it to other local users. The snippet's claim that the token is "never written anywhere" is true of disk, not of process listings. Separately, `sed "s/\x1b\[...//g"` does not interpret `\x1b` on BSD/macOS sed (the maintainer's platform), so the ANSI strip silently does nothing there.
**Fix:** Pass the token through the environment if the release-please CLI reads one (for example `GITHUB_TOKEN`). For the strip, use `perl -pe 's/\e\[[0-9;]*m//g'` or `sed $'s/\x1b\\[[0-9;]*m//g'`.

### IN-04: The same 9-line toolchain-pin comment is copied three times

**File:** `.github/workflows/release.yml:127-135, 428-436, 593-601`
**Issue:** The three copies will drift the next time the rationale changes.
**Fix:** Keep the full comment once, on `sync-release-pr-pins`, and have the other two jobs refer to it ("see the toolchain-pin note on sync-release-pr-pins").

### IN-05: The Node 24 allowlist verifies floating major tags, and one runs next to the Hex publish key

**File:** `test/threadline/ci_action_runtime_contract_test.exs:13-24`; `.github/workflows/release.yml:445`
**Issue:** The "verified by fetching that ref's action.yml" note applies to moving tags (`erlef/setup-beam@v1`, `actions/*@vN`). The allowlist cannot detect a retag. Only `re-actors/alls-green` is pinned to a SHA, yet the third-party `erlef/setup-beam@v1` runs in `publish-hex`, the job that later holds `HEX_API_KEY`. This predates the phase and is noted for awareness.
**Fix:** Consider pinning third-party actions in release jobs to full commit SHAs, with a `# vN` comment, and extending the allowlist to accept SHA refs.

---

_Reviewed: 2026-09-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
