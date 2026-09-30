---
phase: 216-ci-platform-currency
plan: 04
subsystem: ci
tags: [github-actions, node24, release-please, actions-cache, upload-artifact]
status: complete
requires:
  - 216-03 (committed toolchain in every workflow)
provides:
  - googleapis/release-please-action@v5 in its own one-line ci(release) commit
  - actions/cache@v5 (incl. restore/save) and actions/upload-artifact@v7 in every workflow
  - 216-EVIDENCE.md with the pre-landing Release Please rehearsal section
affects:
  - 216-05 (fail-closed Node 24 allowlist test and CONTRIBUTING runbook cite this evidence)
  - 216-06 / 216-07 (fill the placeholder evidence headings)
tech-stack:
  added: []
  patterns:
    - "Action major bumps rehearsed with the exact library version each action release bundles (npx one-shot, --dry-run only)"
key-files:
  created:
    - .planning/phases/216-ci-platform-currency/216-EVIDENCE.md
  modified:
    - .github/workflows/release.yml
    - .github/workflows/ci.yml
    - .github/workflows/browser-full.yml
    - .github/workflows/flake-detection.yml
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/threadline/ci_topology_contract_test.exs
decisions:
  - "Release Please bump landed first as a single-file, single-line commit (numstat 1 1), before the cache/upload bumps"
  - "Synthetic YAML fixtures in ci_workflow_parity_contract_test.exs (lines ~581, ~751) keep their cache@v4 text: they are classifier inputs, not assertions about the real workflows"
metrics:
  duration: ~15 min
  completed: 2026-09-26
  tasks: 2
  files: 7
actuals:
  tokens: 3300
  tasks: 2
  commits: 2
plan_head_before: 0536a5e8a584d73978ff784be2cc386d1d2a351d
---

# Phase 216 Plan 04: Node 24 action majors Summary

Every Node 20 action is gone from the workflows. `googleapis/release-please-action` moved v4 to v5 in its own one-line `ci(release):` commit. Before that commit landed, a dry run of release-please 17.3.0 and 17.6.0 against the real config and manifest produced byte-identical output. Separately, `actions/cache` (including restore/save) moved v4 to v5 and `actions/upload-artifact` moved v4 to v7 across ci, browser-full and flake-detection, and the parity and topology contracts now pin the new refs.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (tracer) | release-please-action v5, rehearsed with both bundled library versions | 21bb7e1b | .github/workflows/release.yml (evidence file staged later, in the metadata commit) |
| 2 | cache v5 / upload-artifact v7 with the contract literals they force | 702d3d5f | ci.yml, browser-full.yml, flake-detection.yml, ci_workflow_parity_contract_test.exs, ci_topology_contract_test.exs |

## Rehearsal (pre-landing)

- origin/main `5e78b2f05d00619e11aa9b29bc8f612087756846`; `npm_config_ignore_scripts=true`; `--dry-run` only; the token was passed only as `$(gh auth token)`.
- `diff /tmp/rp-17.3.0.log /tmp/rp-17.6.0.log` gave `IDENTICAL` (32 lines each). Both logs contain `Found release for path ., v0.11.0`, `No user facing commits found since 8312290d... - skipping` and `Would open 0 pull requests`.
- The logs and the evidence file contain no ANSI escapes and no `gh[po]_` token string.
- Full record: `.planning/phases/216-ci-platform-currency/216-EVIDENCE.md`, section `## Release Please action v5 rehearsal (pre-landing)`. Placeholder headings for plans 06-07 are in place.

## Verification

- Task 1 `<automated>` chain: passed (VERIFY_OK). `git show --numstat` is `1	1	.github/workflows/release.yml`, and the release-please-action@v4 count is 0. The tracer gate re-ran it end to end before expansion.
- Task 2 `<automated>` chain: passed (VERIFY_OK). 18 cache@v5 refs, 3 upload-artifact@v7 refs, 0 v4 refs. The workflow diff has 0 non-ref lines, and HEAD touches exactly the five planned paths.
- `actionlint -shellcheck=` clean; 58 contract tests passed with 0 failures; `mix verify.format` and `mix verify.credo` clean.
- Full `mix test`: 9 properties, 2303 tests, 0 failures, 2 excluded.
- EDGE concurrency: the release.yml change is the single `uses:` line, so no concurrency group, `needs:` or `if:` changed.

## Deviations from Plan

None. The plan ran exactly as written. The line numbers for the test literals had drifted from the plan's estimates (parity test 386-387, topology test 411/421), and those lines were edited.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: .planning/phases/216-ci-platform-currency/216-EVIDENCE.md
- FOUND: 21bb7e1b, 702d3d5f
