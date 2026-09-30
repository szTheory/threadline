---
phase: 218-ci-economy-remove-waste
plan: 02
subsystem: ci
status: complete
tags: [ci, github-actions, issues, econ-02]
requires: ["218-01"]
provides:
  - "bin/upsert-ci-issue --close (action=none | action=close + issue_number=N; ambiguous fails closed)"
  - "deps-health.yml close-on-clean step"
affects: ["218-06", "218-07", "218-08"]
tech-stack:
  added: []
  patterns: ["behaviour-table header on a CI shell script", "fake-gh argv log proving argv-only data flow"]
key-files:
  created: []
  modified:
    - bin/upsert-ci-issue
    - test/threadline/ci_issue_upsert_contract_test.exs
    - .github/workflows/deps-health.yml
    - test/threadline/deps_health_doc_contract_test.exs
decisions:
  - "--close skips `label create` and does not require --title; it reuses the existing issue list + jq startswith filter unchanged"
  - "Close path posts a citing comment before closing, so every automated close is attributable (T-218-04)"
  - "deps-health closes only on classification == 'clean'; outdated, advisory, unknown and an empty/crashed report never close"
  - "Issues #28 and #36 were not closed: the classifier refused both gh issue close calls; handed off to the maintainer or to the --close wiring in 218-06/218-07, verified in 218-08"
metrics:
  duration: "~5 min active + one 183 s full-suite run"
  completed: 2026-09-27
actuals:
  tokens: 3200
  tasks: 2
  commits: 1
plan_head_before: 38e7188483f00d54ed8428aba7c212ee732817f4
plan_head_after: 09a24c5f28dc8b378db00d75eff4ea30a05af852
---

# Phase 218 Plan 02: upsert-ci-issue close-on-green Summary

`bin/upsert-ci-issue --close` comments on the one open tracking issue that matches, then closes it with `--reason completed`. Zero matches is a no-write `action=none`, and more than one match fails closed. `deps-health.yml` now calls it on a `clean` classification. The stale issues #28 and #36 are still open, because the classifier refused the close. They are handed off below.

## What was built

- **`bin/upsert-ci-issue`**
  - New `--close` flag. `--title` is required only in upsert mode.
  - Close mode skips `label create`.
  - Behaviour in close mode:
    - 0 matches: prints `action=none` and writes nothing.
    - 1 match: validates the number against `^[0-9]+$`, runs `issue comment N --body-file F`, then `issue close N --reason completed`, and prints `action=close` and `issue_number=N`.
    - 2 or more matches: dies with `ambiguous marker matched <n> open issues` and exit 1.
  - New header comment with a behaviour table covering both modes.
  - Upsert mode is unchanged.
- **`test/threadline/ci_issue_upsert_contract_test.exs`**
  - The fake gh accepts `issue close` and also writes one argv element per line to `ARGS_LOG`.
  - `fixture/2` takes an optional `root`.
  - New `describe "--close"` with `@describetag :tmp_dir` and five rows: none, close (checks that the comment comes before the close), ambiguous, metacharacter, and required args.
  - The three existing rows are untouched.
- **`.github/workflows/deps-health.yml`**
  - New step `Close the dependency health issue on a clean run`, placed directly after the upsert step, with `if: steps.report.outputs.classification == 'clean'`.
  - It copies `TITLE_PREFIX` and `LABEL` from the upsert step and uses the same `RUN_URL` expression.
  - It writes a one-line body `Clean on <sha> (<event>): <run url>` to a `mktemp` file, removed by a trap.
- **`test/threadline/deps_health_doc_contract_test.exs`**
  - New test: the workflow contains `upsert-ci-issue --close`, and the close step's own `if:` is exactly the `clean` gate.
  - `other_workflow_labels/0` already uses `uniq: true` and skips deps-health.yml itself, so no dedupe change was needed.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 (tracer) | 09a24c5f | ci(218-02): upsert-ci-issue closes a tracking issue when its lane goes green |
| 2 | none | Evidence only. No repository file was changed. |

## Verification

- RED before the implementation. `mix test test/threadline/ci_issue_upsert_contract_test.exs` reported `8 tests, 5 failures`. Every new row failed with `upsert-ci-issue: unknown argument: --close`.
- GREEN after the change:
  - `ci_issue_upsert_contract_test.exs`: 8 tests, 0 failures. The baseline was 3, so the count rose by 5 (at least 4 required).
  - Targeted pair: 24 tests, 0 failures.
- `actionlint -shellcheck=` exits 0. `shellcheck bin/upsert-ci-issue` is clean.
- `mix verify.format` passes. `mix verify.credo` found no issues.
- Full default `mix test`: 9 properties, 2387 tests, 0 failures, 2 excluded.
- Mutation check on the new doc-contract assert: changing the close step gate to `!= 'advisory'` gave 16 tests, 1 failure. The gate was then restored, and the run gave 16 tests, 0 failures.
- Tracer gate: `<verify>` was re-run after the commit and was green (actionlint clean, 24 tests, 0 failures).
- Acceptance checks:
  - `--close) close=1` appears once.
  - `issue close` appears in the script.
  - `grep -c "upsert-ci-issue --close" .github/workflows/deps-health.yml` returns 1.
  - The HEAD file-set check passes and names exactly the four planned files.

## Issue resolution (#28, #36)

Both issues were re-read with `gh issue view` and both were `OPEN`. Each cited run was re-read with `gh run view` before any close attempt:

- #28 "Browser (full project set) is failing" (label `ci-browser-full`). Run 36323594181 returned `{"conclusion":"success","event":"push","headSha":"2a75a795ae2f2d33411112a4a4d4efbbc297183f","workflowName":"Browser (full project set)"}`.
- #36 "Flake Detection: test suite reported unknown" (label `ci-flake`). Run 36302070484 returned `{"conclusion":"success","event":"schedule","headSha":"5e78b2f05d00619e11aa9b29bc8f612087756846","workflowName":"Flake Detection"}`.

I attempted `gh issue close <n> --reason completed --comment "<lane> is green on <sha> (<event>): <run URL>; closing. ..."` for each issue. The classifier refused both calls with this text: `Permission for this action was denied by the Claude Code auto mode classifier. Reason: [External System Writes].` I did not retry by any other route.

- HANDOFF: maintainer closes #28 citing run 36323594181, or the first post-landing green run closes it via --close (verified in 218-08).
- HANDOFF: maintainer closes #36 citing run 36302070484, or the first post-landing green run closes it via --close (verified in 218-08).

For 218-06, 218-07 and 218-08: `--close` finds only open issues whose title starts with the marker and that carry the given label. The browser-full and flake callers must pass the same `TITLE_PREFIX` and `LABEL` as their upsert steps, which are currently `ci-browser-full` and `ci-flake`. Otherwise the auto-close will print `action=none` and leave #28 and #36 open.

## TDD / tracer note

The task is `type="tracer"`, not `tdd="true"`, and the acceptance criteria require HEAD to hold exactly the four planned files. So this is one commit, not a RED/GREEN pair. The RED run shown above was captured before the implementation was written.

## Deviations from Plan

None. The plan was executed as written. The issue closes were refused and handed off, which is a path the plan itself provides.

## Known Stubs

None.

## Threat Flags

None. The close path was already in the plan's threat model:
- T-218-03 is covered by the metacharacter row. It checks that the marker reaches gh as one argv element and that the `$(...)` and backtick forms create no file.
- T-218-04 is covered by posting the comment before the close, and by the ambiguous row failing closed.

## Self-Check: PASSED

- FOUND: bin/upsert-ci-issue (contains `--close) close=1`)
- FOUND: test/threadline/ci_issue_upsert_contract_test.exs (contains `issue close`)
- FOUND: .github/workflows/deps-health.yml (contains `upsert-ci-issue --close`)
- FOUND: test/threadline/deps_health_doc_contract_test.exs
- FOUND commit: 09a24c5f
