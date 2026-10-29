---
phase: 245-supply-chain
plan: 05
subsystem: ci
tags: [dependabot, github-actions, supply-chain, contract-test, phase-gate]
status: complete

requires:
  - phase: 245-03
    provides: "SHA-pinned `owner/repo@<40-hex> # vX.Y.Z` refs and the `{action, major}` runtime allowlist"
  - phase: 245-04
    provides: "bin/verify-action-pins (network pin-to-tag proof run by deps-health)"
provides:
  - ".github/dependabot.yml: one github-actions entry at /, monthly, cooldown.default-days 7, one catch-all group, `ci(deps):` titles"
  - "test/threadline/dependabot_config_contract_test.exs: pure `dependabot_errors/2` checker, 13 rule ids, 17 text mutation controls + 3 context controls + 1 benign positive control"
  - "D-06 doc guards flipped: CONTRIBUTING states the Dependabot role and the no-Hex reason; deps_health_doc_contract asserts them and that dependabot.yml exists (and dependabot.yaml does not)"
  - "D-07 merge policy in CONTRIBUTING (never auto-merge; release.yml PRs need verify-release-shape + verify-bump-rehearsal first; a major bump is handled through the allowlist, never by ignoring)"
  - "Phase gate green: CI=true mix ci.all on ephemeral postgres:16 (re-run), hygiene, credo, deps-audit self-test, verify-action-pins"
affects: [246, 247]

actuals:
  tokens: 9500
  tasks: 3
  commits: 2
plan_head_before: 50a2d2212700cd1bc962d9f9c2bc782d9f927370
plan_head_after: 20d7bec0aa2f58fddde201371f8540e0e2d172d5

tech-stack:
  added: []
  patterns:
    - "A pure checker takes the config text plus a context map (derived releasable types, workflow labels, tracked files), so context-derived rules get mutation controls as well"
    - "Each derive source that finds nothing fails closed under the rule it feeds"

key-files:
  created:
    - .github/dependabot.yml
    - test/threadline/dependabot_config_contract_test.exs
    - .planning/phases/245-supply-chain/deferred-items.md
  modified:
    - test/partition_weights.txt
    - test/threadline/deps_health_doc_contract_test.exs
    - CONTRIBUTING.md

decisions:
  - "Added a `commit-message` rule (include must be scope) beyond the plan's rule list, so the `ci(deps):` title shape from D-02 is pinned too"
  - "The groups rule requires the group's keys to be exactly applies-to + patterns, which also bans update-types and exclude-patterns (D-03 prohibition)"
  - "D-06 supersedes v1.43 decision T-215-19 (215-SECURITY.md: dependabot.yml/.yaml absent, asserted by test)"

metrics:
  duration: 75min
  completed: 2026-10-25
---

# Phase 245 Plan 05: Grouped monthly Dependabot for SHA-pinned actions, plus the phase gate Summary

`.github/dependabot.yml` now asks Dependabot for one grouped monthly `ci(deps):` pull request covering GitHub Actions only, with a 7-day cooldown. A pure-checker contract pins that shape: each of its 13 rules has a mutation control proving it fires. The D-06 doc guards and the D-07 merge policy changed in the same commit as the config. The full local phase gate is green.

## What shipped

- **Config (D-02, D-03).** This is the RESEARCH "Recommended file", copied verbatim: a header comment, `version: 2`, and a single entry with `github-actions` at `"/"`, `interval: monthly`, `cooldown.default-days: 7`, group `github-actions` (`applies-to: version-updates`, `patterns: ["*"]`) and `commit-message: {prefix: ci, include: scope}`. It has no mix or npm entry, no target-branch, labels, allow, ignore, rebase-strategy or PR limit.
- **Contract (D-05).** `Threadline.DependabotConfigContractTest` (async) checks the config with `dependabot_errors(text, ctx)`. Every violation is a `.github/dependabot.yml [updates[i]] rule=<id>: ...` string. The rules are:
  - `yaml-parse`, `version`
  - `ecosystems`: the {ecosystem, directory} set must be exactly `[{"github-actions", "/"}]`; `directories:` lists are expanded
  - `interval`, `cooldown` (integer >= 7), `groups`
  - `prefix-releasable`: the releasable set is derived with Jason from `release-please-config.json` `changelog-sections` where `hidden != true`
  - `commit-message`, `target-branch`, `pr-limit`, `forbidden-keys`
  - `labels`: must be disjoint from every workflow `LABEL:`, which is derived by regex
  - `composite-outside-root`: from `git ls-files`

  The controls are 17 text mutations, among them the four D-05 requires (a mix entry, prefix `fix`, a `target-branch`, limit 0) plus npm, a second directory, prefix `deps`, a dropped include, weekly, cooldown 3, a second group, update-types, a `ci-deps` label, ignore, rebase-strategy, version 1 and unparseable YAML. Three more mutate the context: a composite action outside root, an empty derived label set and an empty derived releasable set. One benign control reorders keys inside the entry and must stay `[]`. 23 tests in total. Weight row `439 test/threadline/dependabot_config_contract_test.exs` was measured with `--slowest-modules` and is in sorted position.
- **D-06 doc guards (same commit as the config, 450c5cc3).** In CONTRIBUTING, the sentence "This repository does not use Dependabot version-update pull requests." and the alerts sentence are replaced by the new Dependabot paragraph. The release-train paragraph is unchanged. `deps_health_doc_contract_test` now asserts `one grouped monthly pull request`, `does not support Hex security updates`, `mix verify.deps_audit` and `never auto-merge`. Its file test is now `.github/dependabot.yml exists and is the only Dependabot config`, and its moduledoc describes the new mandatory terms. **This supersedes v1.43 decision T-215-19 (`215-SECURITY.md`: "`.github/dependabot.yml`/`.yaml` absent, asserted by test").**
- **D-07 merge policy (CONTRIBUTING).** Claude or the maintainer may merge a grouped actions PR only when:
  - required CI is green
  - the 7-day cooldown has elapsed
  - for a PR that touches `release.yml`, `bin/verify-release-shape` and `bin/verify-bump-rehearsal` were run first

  Never auto-merge. A major bump fails the `{action, major}` allowlist (`ci_action_runtime_contract_test.exs`) on purpose. It is handled by checking `runs.using` and adding the allowlist entry, never by ignoring the update.

## Phase gate (D-30, D-31)

The gate script lives in the session scratchpad (`<scratch>/gate-245.sh`). It runs `docker run -d --rm --pull never` with labels `dev.threadline.kind=gate-db` and `owner-pid`, on `postgres:16` and a random loopback port. It waits up to 60s for `pg_isready`, tears down with a trap on EXIT/INT/TERM, and runs with `DB_HOST`/`DB_PORT` and `CI=true`.

**Run 1 (`<scratch>/gate-245.log.clean`): real exit 2.** The only red was one library test: `TriggerRerunPropertyTest` (`test/threadline/capture/trigger_rerun_property_test.exs:24`), with an orphan trigger `threadline_audit_trp_405` left after 5 successful runs (seed 825295, 3432 tests, 1 failure). Every other lane was green. Phase 245 does not touch capture code. To check whether it was real:
- the same seed on a fresh postgres:16 gave 0 failures
- the file alone passed 5 of 5 times
- a separate full `mix test` gave 0 failures

That makes it an intermittent flake. It is logged in `deferred-items.md`.

**Run 2 (`<scratch>/gate-245-r2.log.clean`): real exit 0.** Decisive lines:

```
5898 mods/funs, found no issues.
verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0; 0 non-blocking finding(s))
32 properties, 3432 tests, 0 failures, 3 excluded        (library)
132 tests, 0 failures                                    (example app)
Total errors: 0, Skipped: 0, Unnecessary Skips: 0        (Dialyzer)
17 tests, 0 failures, 16 excluded
  64 skipped
  418 passed (6.1m)                                      (Playwright browser lane, 0 failed)
```

The browser lane is now 418 passed / 0 failed / 64 skipped, not the 318/26 in the older note. That is because the lane has grown. It has no failures.

Standalone checks after the gate:
- `bin/verify-repo-hygiene`: exit 0 (4943 files clean)
- `mix verify.credo`: exit 0, `found no issues`
- `bin/verify-deps-audit --self-test`: exit 0, `verify-deps-audit self-test: ok (...)`
- `bin/verify-action-pins`: exit 0, `8 pin(s) match their tags`
- `docker ps -a --filter label=dev.threadline.kind=gate-db -q | wc -l`: 0

Before the Task 1+2 commit, the default `mix test` on postgres:16 gave 3432 tests, 0 failures.

## Tracer feedback gate

Auto mode is active (`workflow.auto_advance=true`). Task 1's `<verify>` is automated only. It was re-run end to end: the contract and topology tests gave 49 tests and 0 failures once the weight row was added. Expansion then went ahead.

## Deferred to landing (not gaps)

1. **GitHub accepts `dependabot.yml`.** After merge, check read-only with `gh run list --repo szTheory/threadline --event dynamic --limit 5`. A good result is no Dependabot config error, then either the first grouped PR or a "no updates" status (RESEARCH A3).
2. **#61** gets retitled by its next deps-health run and closes on the first clean run. Check with `gh issue view 61 --json state,title` (D-28).
3. **Maintainer sets `sha_pinning_required=true`** once the pins are on `main`. Check with `gh api repos/szTheory/threadline/actions/permissions --jq .sha_pinning_required` (D-15).
4. **The first grouped Dependabot PR will contain only major bumps** (checkout v7, cache v6, setup-node v7, github-script v9). It will be red on the `{action, major}` allowlist by design. Treat it as a major review: check each new major's `runs.using` and add the allowlist entries. Never loosen the allowlist and never add ignore rules (RESEARCH Pitfall 5).
5. **Landing order:** Phase 244 lands in its own PR first, then 245 separately. The push token needs `workflow` scope because `.github/` files change (D-32).

## Deviations from Plan

- **[Rule 1] Credo readability fix after the Task 1+2 commit.** The `tail` I piped credo through hid its exit code, so commit 450c5cc3 went in with one `[R]` finding (more than 3 escaped quotes in the ecosystems message). Follow-up commit 20d7bec0 switches that string to `~s(...)`. Credo is clean now. The D-06 same-commit rule still holds: the config and the doc guards are both in 450c5cc3.
- **[Rule 2] Extra rule `commit-message`, and stricter `groups` keys.** These pin the D-02 `include: scope` and the D-03 update-types ban, which were otherwise only enforced by grep.
- **Gate re-run.** Run 1 was red on an unrelated flake that does not reproduce. Per the scope boundary it was logged, not fixed, and the gate was re-run once, green. No contract, tier rule or allowlist was loosened.
- Gate script detail: the `select version(), inet_server_port()` line went to the wrapper's stdout, which was discarded, not to the log. The container was the `postgres:16` image, pulled with `--pull never`.

## Maintainer hand-offs

- Items 1 to 5 above. Nothing was pushed, no PR was opened, and no repository setting changed.
- Optional: look into the `TriggerRerunPropertyTest` flake (`deferred-items.md`).

## Known Stubs

None.

## Threat Flags

None. The new files are a GitHub-side config and an offline test.

## Self-Check: PASSED

- Files exist: .github/dependabot.yml, test/threadline/dependabot_config_contract_test.exs, .planning/phases/245-supply-chain/deferred-items.md
- Commits reachable from HEAD: 450c5cc3, 20d7bec0
