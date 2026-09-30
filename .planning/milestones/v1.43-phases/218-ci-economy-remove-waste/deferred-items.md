# Phase 218 deferred items

## From 218-04

- **CONTRIBUTING.md `## Branch protection (maintainers)` still lists six per-job checks under "require these checks on `main`".** Plan 218-04 removed only the `verify-docs` and `verify-hex-package` lines and added the sentence saying the only required status check is `CI required`. The surviving list (format, credo, the two test lanes, pgbouncer topology, release shape) now reads as contradicting that sentence: live protection and `.github/rulesets/main.json` require only `CI required`. Rewriting the list is out of 218-04's scope. It is a doc-truth fix for a later plan (candidate: Phase 221, which owns CI names and legibility).
  status: acknowledged

## From 218-08

- **The live Dialyzer slice line is not visible in the CI log.** `mix verify.dialyzer_slice` runs the `:live_dialyzer` ExUnit test, which captures `bin/verify-dialyzer-slice` output through `System.cmd` and only asserts on it. A green `verify-dialyzer` job therefore prints `17 tests, 0 failures, 16 excluded`, not `verified slice critic-tooling: 3/40 sealed warnings; ... 0 live warnings` (run 36359132030). The pass still proves both strings were printed, because the test asserts them and the verifier now fails closed. To make the line quotable from CI, the alias (or the CI step) could also run `bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/critic-tooling.json` directly, or the test could `IO.puts` the verifier output. This is a code change that needs a push, so it is out of 218-08's measurement scope. Candidate: Phase 221 (CI legibility).
- **Browser-full's per-push cost is measured from a dispatch run, and the push-to-main unit is an [inference].** The first post-merge push to main measures both (`python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py runner-minutes --unit push` after collecting with `--head-sha`).
  status: acknowledged

## From 218 verification

- **`clean_checkout_contract_test.exs` temp-dir name collision (pre-existing, phase 200).** In one full run during verification it failed once: a temp dir left over from 2026-09-24 collided with a name built from `System.unique_integer`, which restarts in every VM. Rerunning the file passed. The fix is one line: add a random or monotonic-time component to the name, or clean the dir up before use. This is a flake source, so it belongs with the CI flakiness work (see `.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md`).
- **Browser-full still runs `tier-a-capture` as `refute-capture`'s declared dependency** (218-08 deviation 1). The overlap is documented and pinned. A later cleanup could make `refute-capture` create its own cell directories.
- **WR-03, maintainer call:** D-04 applies `broken-upstream` to every event, including manual dispatch. The reviewer suggested scoping it to `schedule`. This is left as locked.
  status: acknowledged
