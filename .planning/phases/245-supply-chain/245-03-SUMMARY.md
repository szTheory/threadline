---
phase: 245-supply-chain
plan: 03
subsystem: ci
tags: [github-actions, sha-pinning, supply-chain, setup-node, contract-test]
status: complete

requires:
  - phase: 245-02
    provides: tiered dependency-audit gate (deps-health.yml shape this plan pins)
provides:
  - "79 SHA-pinned `uses:` refs across 8 workflows in canonical `owner/repo@<40-hex> # vX.Y.Z` form"
  - "test/threadline/ci_action_pin_contract_test.exs: pin_errors/2 with PIN-SCAN, PIN-PARITY, PIN-FORM, PIN-LOCAL, PIN-DOCKER, PIN-CONSISTENT, NODE-FILE, NODE-PIN"
  - "@node24_or_non_js re-keyed to {action, major}, the major read from the pin comment"
  - "setup-node reads node-version-file: .tool-versions (4 steps)"
  - "release.yml github-script reads RELEASE_SHA from env (D-33)"
affects: [245-04, 245-05]

actuals:
  tokens: 18200
  tasks: 3
  commits: 1
plan_head_before: 810c5d61dcacec6bc527102d3bc17407752c0adb
plan_head_after: b7b8028974d80eb207e0a0eb8881028bc43173b9

tech-stack:
  added: []
  patterns:
    - "Parsed-YAML vs raw-line multiset parity (Enum.frequencies/1) to close regex-bypass YAML forms"
    - "Allowlist keyed {action, major} with the major read from the `# vX.Y.Z` pin comment, so patch/minor re-pins stay green and majors fail closed"
    - "Pin-safe `<action>@` prefix anchors in live-file tests"

key-files:
  created:
    - test/threadline/ci_action_pin_contract_test.exs
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/release.yml
    - .github/workflows/browser-full.yml
    - .github/workflows/flake-detection.yml
    - .github/workflows/branch-protection.yml
    - .github/workflows/community-health.yml
    - .github/workflows/environment-protection.yml
    - .github/workflows/deps-health.yml
    - test/threadline/ci_action_runtime_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/browser_journey_evidence_contract_test.exs
    - test/threadline/flake_classifier_contract_test.exs
    - test/partition_weights.txt
    - CONTRIBUTING.md

decisions:
  - "Runtime contract: a quoted SHA-pinned ref (or any ref without a parseable `@<sha> # vX.Y.Z`) is reported as unpinned, never skipped; PIN-FORM also rejects quoted refs"
  - "ci.yml deps-cache assertion keeps its major check as a regex (`actions/cache@<sha> # v5.x.y`) instead of dropping to a bare prefix"
  - "The alls-green stale comment is reworded (no version) rather than deleted outright, keeping its rationale"
  - "CONTRIBUTING runbook step 5 does not name bin/verify-action-pins yet; that script lands in 245-04"

metrics:
  duration: 45min
  completed: 2026-10-25
---

# Phase 245 Plan 03: SHA-pinned action refs Summary

All 79 workflow `uses:` refs now point at full commit SHAs, each with its exact release tag as a trailing comment, in one atomic commit (D-13). The SHAs were re-resolved through read-only `gh api` calls when the commit was made. `actions/setup-node` reads `.tool-versions`. A new offline contract rejects a tag-only ref, and its mutation controls prove that each rule fires.

## What shipped

- **Pins (D-08, D-09).** 78 tag-only refs plus the alls-green SHA ref (which had a wrong comment) now use the form `owner/repo@<40-hex> # vX.Y.Z`. alls-green carries `# v1.3.0`, and the stale `v1.2.2 / release/v1` comment is gone. No major was bumped. No job `id:` changed, and no `with:` input changed other than node-version.
- **setup-node (D-10).** The three ci.yml steps and the one browser-full.yml step changed `node-version: "22"` to `node-version-file: .tool-versions`.
- **D-33.** release.yml's `Wait for ci.yml success on release SHA` step now sets `env: RELEASE_SHA: ${{ needs.release-ref.outputs.release_sha }}`, and its script reads `process.env.RELEASE_SHA`. The script body contains no `${{`.
- **Pin contract (D-11).** `Threadline.CiActionPinContractTest.pin_errors/2` scans `.github/workflows/*.{yml,yaml}` and `.github/actions/**/action.{yml,yaml}`, plus `.tool-versions`. It returns `rule=` errors sorted by path and then line. It has 20 mutation controls. Five fire PIN-FORM: tag-only checkout, 7-char SHA, no comment, a `# v5` comment, and a quoted ref. Five fire PIN-PARITY: flow-style, quoted key, alias, block scalar, and unparseable YAML. NODE-FILE has 2, NODE-PIN has 2 (missing nodejs line, extra single-token line), PIN-CONSISTENT has 2 (same major with two SHAs, same SHA with two comments), PIN-LOCAL has 1, PIN-DOCKER has 1, and PIN-SCAN has 2 (zero refs, empty file list). There are 3 positive controls: the canonical form, identical refs merging with step order irrelevant, and a docker ref pinned by digest. Against the pre-pin tree, the `@tag :live_tree` test failed on 79 × PIN-FORM and 4 × NODE-FILE, and nothing else fired.
- **Runtime re-key (D-12).** `@node24_or_non_js` is now keyed `{action, major}`, and alls-green is `{"re-actors/alls-green", "v1"} => :composite`. The major comes from `~r/uses:\s*([^\s@"']+)@[0-9a-f]{40}\s+#\s*(v\d+)\.\d+\.\d+/`. A ref without a parseable major is an error. The release-please runbook check reads the major from the comment, and its mutation now bumps the comment to `v6.0.0` with a `refute bumped == original` guard. New controls cover a major bump (red), a patch re-pin (green), a tag-only ref and a SHA with no comment.
- **Anchor fixes.** parity `:713/:722/:730` and topology `:246/:655` now tolerate ` # vX.Y.Z`. The exact `@v5`/`@v7`/`@v1` checks in parity, topology, browser_journey and flake_classifier now match on `<action>@`. The combined-action mutation now changes `actions/cache/restore@` to `actions/cache@`, so it still goes red. The synthetic example-consumer fixture now uses the canonical pinned form with `node-version-file`.
- **Runbook.** CONTRIBUTING step 5 now names `googleapis/release-please-action@<sha>` as matched against the `# vX.Y.Z` comment. The literal `googleapis/release-please-action@v5` is still there.

## Provenance evidence (D-14a, re-resolved 2026-10-25 with read-only `gh api`)

| action | tag | tag object type | commit SHA | floating major -> same commit? |
|---|---|---|---|---|
| actions/checkout | v5.1.0 | commit | fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 | v5 (commit) -> yes |
| erlef/setup-beam | v1.24.1 | commit | 54075bcc5e249e4758d363f27d099f55d843f124 | v1 (annotated tag, dereferenced) -> yes |
| actions/cache (+ /restore, /save) | v5.1.0 | commit | caa296126883cff596d87d8935842f9db880ef25 | v5 (commit) -> yes |
| actions/upload-artifact | v7.0.2 | commit | cf430e030ddbb5b0abf93d22962f4752f3646cd9 | v7 (commit) -> yes |
| actions/setup-node | v5.0.0 | commit | a0853c24544627f65ddf259abe73b1d18a591444 | v5 (commit) -> yes |
| googleapis/release-please-action | v5.0.0 | commit | 45996ed1f6d02564a971a2fa1b5860e934307cf7 | v5 (annotated tag, dereferenced) -> yes |
| actions/github-script | v8.0.0 | commit | ed597411d8f924073f98dfc5c65a23a2325f34cd | v8 (commit) -> yes |
| re-actors/alls-green | v1.3.0 | annotated tag (dereferenced) | b5b5b37504aa4183270bd3d855c52a67f212be35 | no `v1` tag (404), as expected |

All 8 SHAs match the research table. The only difference from RESEARCH is which tag is annotated: for setup-beam and release-please, the *floating major* tags are annotated, while the exact-patch tags are lightweight. Pinning therefore changes no behaviour.

## Remaining `@v` refs under test/ (all synthetic negative or fixture text, none read against live files)

- `ci_workflow_parity_contract_test.exs:2370`: `@root_build_restore_template`, a literal step that controls insert into cache-free jobs.
- `ci_workflow_parity_contract_test.exs:2904-2907, 3118-3120`: synthetic toolchain and cache fixtures. These include `actions/cache@v4`, a negative fixture.
- `ci_workflow_parity_contract_test.exs:4909-4967, 5525, 5578-5663, 5725-5782`: synthetic build-cache and topology fixtures. The build-cache rules match on the `<action>@` prefix, so the tag text inside them does not matter.
- `hex_pin_contract_test.exs:371-430`: synthetic hex-pin fixtures.
- `repo_hygiene_contract_test.exs:159-160`: synthetic "added action" mutations.
- `retry_network_contract_test.exs:688, 922`: the `nick-fields/retry@v3` negative fixtures.

## Verification

- `mix test test/threadline/ci_action_pin_contract_test.exs --exclude live_tree`: 24 tests, 0 failures, 1 excluded. This was run before pinning.
- The Task 3 list of 11 contract files: 341 tests, 0 failures. This run happened before the partition-weight row was added, so the one failure at that point was the expected inventory failure. After the row was added, topology ran 26 tests with 0 failures.
- Full `mix test` on an ephemeral postgres:16: **32 properties, 3381 tests, 0 failures, 3 excluded**. The 3 exclusions are the default `pgbouncer_topology` and `live_dialyzer` tags; `live_tree` is not excluded by default.
- `mix format --check-formatted` OK. `mix verify.credo` found no issues. `bin/verify-repo-hygiene` exited 0. Pre-commit hooks passed.
- actionlint: the same 4 pre-existing shellcheck style or warning findings as HEAD. All of them are in release.yml run scripts that this plan did not touch. No new findings.
- Acceptance greps: 0 tag-only `uses:` lines in workflows, 79 canonical lines, 0 `node-version:` lines, 0 `v1.2.2` in ci.yml, 0 interpolated `const sha = '${{`, and `process.env.RELEASE_SHA` present.

## Deviations from Plan

None that change scope. Minor execution notes:
- The live-tree test was red on NODE-FILE (×4) as well as PIN-FORM before pinning. Both are correct, and both went green with Task 2.
- In the runtime contract, a quoted pinned ref fails closed as "no readable major" rather than naming the action major. Quoted refs are also PIN-FORM violations, so failing closed is the right behaviour.

## Deferred to landing (maintainer hand-offs)

- **D-15:** after these pins reach `main`, the maintainer sets `sha_pinning_required=true`. Read-only check: `gh api repos/szTheory/threadline/actions/permissions --jq .sha_pinning_required`. It must stay `false` until then.
- **D-32:** the push token needs `workflow` scope, because this commit edits `.github/workflows`.
- Expected (RESEARCH Pitfall 5): the first monthly Dependabot actions PR will be majors-only (checkout v7, cache v6, setup-node v7, github-script v9). The `{action, major}` allowlist fails closed on it by design. Handle it as a normal major review.

## Self-Check: PASSED

- FOUND: test/threadline/ci_action_pin_contract_test.exs
- FOUND: commit b7b80289 (ancestor of HEAD)
