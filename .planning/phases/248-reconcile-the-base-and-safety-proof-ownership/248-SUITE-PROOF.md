# Phase 248-04 suite and integration proof

This ledger records the local setup repair and all bounded checks for Plan 248-04. It does not claim hosted CI, live issue closure, a scheduled dependency-health receipt, publication, or release readiness. Full machine logs remain in private execution metadata; this tracked artifact keeps the relevant command output and failure detail without machine-local paths.

## Source and dependency identities

| Evidence point | Source revision | Identity |
|---|---|---|
| Before-setup discovery reproduction | `0b36bfc0baff94e27dc0a4f40ca189c982901409` | Playwright CLI absent in this executor worktree; E2E `node_modules` was not removed or renamed. |
| Workflow setup contract RED | `0b36bfc0baff94e27dc0a4f40ca189c982901409` | Targeted contract failed because the existing `verify-flake` job had no gated Node/npm setup. |
| Workflow setup repair | `450320d71373909fa297a3e95822bc8c0ad7fc49` | Added the two gated setup steps and the scoped regression. |
| Final focused contract repair | `cb1f5fa0daeaaf7eb7bc27fa23c5eeadb22ebfb1` | Updated the walkthrough source anchor and excerpt count to match the Phase 248-02 public-mount correction. |
| Integrated Credo and release repair | `2495891863f5a0fbaab8800a787d668daeb67625` | Extracted a private helper without changing callback behavior; added the unshipped `brand` source directory to release exclusions. |

The setup used Node `v22.14.0` from `.tool-versions` and npm `10.9.2`. `npm --prefix examples/threadline_phoenix/e2e ci` installed the existing lockfile's 10 packages with zero reported vulnerabilities. The E2E lock SHA-256 remained `b6a4ce7846424aa819a7b6e74aad244442cfdb5b7ad10d2d84916bf15babbcdd`. Mix lock hashes at final evidence time are: root `00e6393a22730830470a8253a3cbbd49ca4adc8fd8768573516f58e592502e00`, bench `70392fba94a8798e746db0c7b8b2861b267c6922758fd5dc27240e4dcec3427a`, and example `d3f34675157bd1d18e38d026aa0d89279dd2e46a4e55a5c82e0827f1ed5b3bff`. Locked Mix dependency resolution completed without changing `mix.lock`.

## Attributed missing-CLI reproduction and repair

An initial invocation could not start ExUnit because the locked Mix dependencies were not available locally. After `mix deps.get --check-locked` completed with the launch-supplied temporary Hex cache, the single pre-setup ExUnit reproduction ran while the Playwright CLI was still absent:

```text
mix test test/threadline/browser_journey_evidence_contract_test.exs --seed 876664
exit 2; elapsed 27s
8 tests, 2 failures
```

Both failures were the real Playwright discovery assertions, which reported the expected missing-CLI installation guidance. The test still exercises the actual voting Playwright projects and preserves the required `--list` assertions.

The new setup regression failed on the original workflow at `test/threadline/browser_journey_evidence_contract_test.exs:223` (9 tests, 1 failure). It passed after the workflow repair (9 tests, 0 failures; 8 intentionally excluded). The same seeded browser evidence file then passed against installed locked dependencies (9 tests, 0 failures). The four existing action-pin, workflow-parity, flake-classifier and property-scale contracts also passed (134 tests, 0 failures).

The `verify-flake` job now has only the copied, pinned `actions/setup-node` step (`a0853c24544627f65ddf259abe73b1d18a591444`) and `npm ci` step before the unchanged repeat. Both use the existing `steps.gate.outputs.decision == 'run'` condition. Node selection comes from `.tool-versions`; npm cache and working directory use the existing E2E lock path. Job IDs, triggers, tags, repeats, property scale, 55-minute budget, 60-second termination grace, classifier, output reporting, and both real Playwright discovery checks remain unchanged.

Independent review found that the walkthrough contract still named the pre-248-02 router implementation and expected 14 Elixir excerpts. The accepted repair updates that anchor to the current explicit public-mount acknowledgement, updates the exact count to 15 while keeping the 12–18 bound and the minimum of 12 abbreviated excerpts, and marks one function snippet as omitting its surrounding module context. The final targeted check passed both affected modules:

```text
MIX_ENV=test mix test test/threadline/code_walkthrough_doc_contract_test.exs test/threadline/browser_journey_evidence_contract_test.exs --seed 876664
16 tests, 0 failures (exit 0)
mix format --check-formatted
exit 0
```

The later independent review also accepted two narrow integrated-gate repairs. The private `normalize_authorize_fn/2` implementation now delegates placeholder-capture normalization to a separate private helper; public callback and authorization behavior are unchanged. `release-please-config.json` now excludes the unshipped source-only `brand/` directory. The relevant checks passed:

```text
MIX_ENV=test mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs test/threadline/query/scope_fail_closed_test.exs test/threadline/release_artifact_contract_test.exs
105 tests, 0 failures (exit 0)
mix format --check-formatted — exit 0
mix compile --warnings-as-errors — exit 0
mix credo --strict — exit 0; 5745 mods/funs, no issues
MIX_ENV=test mix test test/threadline/operator_surface/router_test.exs
17 tests, 0 failures (exit 0)
```

The 105-test invocation surfaced a clause-grouping compile warning, so the helper was moved below the existing `normalize_authorize_fn/2` clauses. The follow-up warnings-as-errors compile, strict Credo run, and router test passed without that warning. The focused release-artifact contract also passed in the 105-test invocation.

## Bounded corrected repeat

The first `mix verify.flake` invocation exited before ExUnit because the local shell was in `MIX_ENV=dev`; the workflow job itself sets `MIX_ENV=test`. Its actual result was exit 1, elapsed 1 second, capture exit 0, and classifier `unknown` because no suite header was present (log SHA-256 `95363686cea6655a114734d8b95ee14e57a11ae8885e930dcb5234c20e1de483`). After diagnosing that mismatch, one corrected repeat was launched at source revision `450320d71373909fa297a3e95822bc8c0ad7fc49` with `MIX_ENV=test`, property scale 5, the unchanged 55-minute timeout and TERM/60-second kill grace. The real captured suite exit was 2, capture/tee exit was 0, elapsed time was 376 seconds, and the unchanged classifier returned `broken` with reason `failed on the first iteration` (complete log SHA-256 `50e8f0c20d2e530f01f5d86387d90c6e668ad4c853cc269a1f779bb65dc459bd`).

```text
Finished in 374.8 seconds
32 properties, 3400 tests, 6 failures, 3 excluded
```

Only one suite iteration completed; the required nine-run receipt does not exist. The six failures were:

1. The walkthrough source-anchor assertion referenced the removed `has_auth_fn? = Keyword.has_key?(...)` implementation.
2. The walkthrough excerpt contract expected 14 blocks but found 15.
3. A dependency-health test subprocess exceeded its 60-second test timeout.
4. A clean-checkout contract could not create its temporary linked worktree because the shared Git worktree store is outside this executor's write permissions (`git worktree add` exit 128).
5. A Playwright fail-fast contract could not write to the inherited npm cache (`EPERM`).
6. A release-artifact contract found the tracked `brand/` directory was not included in the configured release exclusion set.

The two walkthrough assertions were fixed and the affected contract now passes. Three narrow diagnostics were run without another full repeat:

| Failure observed in the repeat | Focused diagnostic | Result |
|---|---|---|
| Dependency-health subprocess exceeded 60 seconds | `mix test test/threadline/deps_health_report_test.exs:737` | Pass, 6.6s (60 tests, 59 excluded). The failure is load-sensitive in the full iteration; its precise cause remains unknown. |
| Linked-worktree fixture could not write shared Git metadata | `mix test test/threadline/clean_checkout_contract_test.exs:140` under narrow automatic approval | Pass, 1.0s (9 tests, 8 excluded); the test removed its temporary worktree. |
| Playwright fail-fast smoke hit npm-cache `EPERM` | `npm_config_cache=<private temporary directory> MIX_ENV=test mix test test/threadline/playwright_fail_fast_contract_test.exs` | Timed out at its 60s ExUnit limit (exit 2). The retained npm debug log shows the pinned `npm exec` package fetch/extraction completed and exited 0. A separate default-cache browser install then failed with `EPERM` creating Playwright's cache lock. The pinned Chromium and headless shell were subsequently installed into task-local private storage. In the final canonical test stage the fail-fast contract passed as part of the complete root suite; the earlier timeout was not reproduced, though its precise triggering stage remains unproven. |

The repeat failure remains unchanged by these focused retests. The health timeout passed only in isolation, and the linked-worktree permission error passed only with narrow elevation; neither changes the actual repeat's six failures or its `broken` classification. The release-artifact mismatch was fixed in `24958918` and its contract passed. With the package and browser caches isolated to task-local private storage, the final canonical test stage passed the Playwright fail-fast contract; no assertion or timeout was changed. The earlier timeout's exact stage remains unproven. The explicit no-additional-full-repeat stop remains active.

## Canonical integration and preserved-candidate validation

The first canonical invocation stopped at formatting. After the formatter issue was fixed, a second invocation on the assembled candidate reached strict Credo and found excess nesting in the router callback. The accepted helper extraction and release exclusion were committed at `24958918`. A third invocation then exposed two local prerequisites: the sandbox denied the clean-checkout test's temporary write under shared Git metadata, and the live Dialyzer slice had no generated PLT. Both are preserved here rather than treated as passing evidence.

```text
mix ci.all — first invocation: exit 1, stopped at format in 1s
mix ci.all — source cb1f5fa0: exit 8, stopped at strict Credo
mix ci.all — source 24958918 in sandbox: exit 2
  root suite: 3400 tests, 1 failure; CleanCheckoutContractTest could not create
  its temporary linked worktree under shared .git metadata (EPERM)
  example suite: 132 tests, 0 failures
  live Dialyzer slice: missing local PLT; no_such_file
```

The first invocation stopped in the first alias step; it did not run remaining checks. The second stopped at Credo before running later checks:

```text
MIX_ENV=test npm_config_cache=<private temporary directory> mix ci.all
exit 8; elapsed 2s
5744 mods/funs, found 1 refactoring opportunity
Function body is nested too deep (max depth is 2, was 3).
lib/threadline/operator_surface/router.ex:189
```

After diagnosing those prerequisites, `MIX_ENV=dev mix dialyzer --plt` completed successfully and built the local PLT. Playwright's pinned Chromium was installed into task-local private storage. The independent review had explicitly authorized the necessary canonical rerun after diagnosed source/environment repairs. The final command ran on `2495891863f5a0fbaab8800a787d668daeb67625` with task-local npm/browser caches and Git metadata access for the temporary fixture; it completed with real exit 0 and no alias step omitted:

```text
mix ci.all — exit 0
strict Credo: 5745 mods/funs, no issues
dependency audit: 3 lockfiles clean, 0 non-blocking findings
repository hygiene: 4801 tracked text files clean; all 8 allowlist entries used
xref: no cycles
root suite: 32 properties, 3400 tests, 0 failures, 3 existing exclusions
coverage: 1/1 expected tables covered, 0 gated findings (1 non-gated warning)
example suite: 132 tests, 0 failures
Dialyzer: 0 errors, 0 skipped; live slice 17 tests, 0 failures, 16 excluded
Playwright: desktop-chromium and mobile-chromium; 418 passed, 56 skipped
```

The full output was captured; its SHA-256 is `555b92f890eacfb29662e0cd4575c29b4be6672266d6b88898fb007d4f2135d5`. The earlier environment-failing invocation remains separately retained as evidence and is not folded into this passing result.

The required phase-local validator was rerun after the final canonical integration and passed:

```text
python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-inventory --self-test
PASS: inventory verification (15 checks)
```

It confirms the 31 preserved path/blob identities, brand-source identities, isolation provenance, and all six negative inventory controls. The accepted router helper and release exclusion do not change the preserved candidate inventory, brand source identities, or lock inputs.

## Review and outstanding limits

The independent review report is copied to [248-WORKFLOW-REVIEW.md](248-WORKFLOW-REVIEW.md) and matches its recorded SHA-256 `3f52c5b352ebb42fd843afef9c11cea404ac192705173cfb6272d1fbb48294a4`. It found no remaining workflow/router/release source defect and retains one blocker: the required nine-run corrected repeat has no passing receipt, and the no-retry stop remains active. The final canonical integration and inventory checks pass, but they cannot replace that repeat criterion.

Local evidence cannot close issues #61 or #90, provide the scheduled clean dependency-health receipt, hosted post-fix CI, minimum Elixir/OTP execution, or REL-01. No push, dispatch, issue update, merge, publication, version change, or Phase 249 work occurred. ADM-04 remains blocked because the nine-run repeat acceptance is unresolved; its owner must explicitly authorize a future bounded repeat before another attempt.

## Corrective formatter follow-up — 2026-11-11

The renewed repeat receipt is recorded portably in [248-RENEWED-REPEAT-RECEIPT.json](248-RENEWED-REPEAT-RECEIPT.json). It is bound to source `8311dc64ac4b7f0b686e27de41839899803139c7`, source test SHA-256 `214d5ada2b1f6e1eefa2623d2c60d44b05c5a4817034ce7c6233010002c746b5`, and raw-log SHA-256 `053a996abfade63a34883cce8986bf3c6b947a21e27be80f7af0a9d3beadb7a1`. The actual suite exit was 2, capture exit 0, elapsed time 2,611 seconds of 3,300, and classifier `flaky` (`passed 6 time(s) then failed on iteration 7`). The seventh run timed out at seed `500886` inside recursive wildcard expansion in `FormatterTopologyContractTest`. This is genuine failure evidence. No further repeat is authorized.

The bounded remediation is documented in [248-FORMATTER-FIX.md](248-FORMATTER-FIX.md). Commit `2b00c6bea83e42fe8843b2b8d7767f7ffbe13df4` changes only the formatter contract test; source SHA-256 is `fa1ce02fa3494cb8bcad8126e06c80d20fedf4de949e67dcc358f012732f277a`. Within each `ownership_errors/2` invocation, it now builds ordered `{owner, owned_files(owner)}` pairs once and reuses them across candidate paths. It recomputes sets per invocation, preserving changed configs and duplicate owner records/order. Static work across the representative, overlap, and uncovered calls fell from 70 owner-set builds / 168 wildcard expansions to 15 / 36. No synthetic glob was narrowed, and all existing assertions, representative paths, async behavior, timeout, tags, and coverage remain unchanged.

The single allowed standalone baseline (`MIX_ENV=test mix test test/threadline/formatter_topology_contract_test.exs --seed 500886`) passed before the edit: 1 test, 0 failures, 0.8 seconds ExUnit time and 2 seconds wall time. The identical focused command passed after the edit: 1 test, 0 failures, 0.2 seconds ExUnit time and 1 second wall time. `mix verify.format` exited 0 in 3 seconds. A standalone pass does not erase the repeat failure or prove behavior under suite load. Source evidence supports repeated recursive scans, but not that they alone consumed all 60 seconds; no environment or machine-load cause is inferred.

The one authorized canonical `mix ci.all` on commit `2b00c6bea83e42fe8843b2b8d7767f7ffbe13df4` exited 1 after 438 seconds (complete log SHA-256 `cbb6bc2998f9193d4aa809d03bfc159024c99ce206dcded3d807bbaef6b2da0e`). Credo passed with 5,745 functions and no issues; all three Mix lockfiles audited cleanly; repository hygiene passed for 4,804 tracked text files; xref found no cycles. The root suite passed 3,400 tests, 0 failures, and 3 existing exclusions in 409.4 seconds. The threadline coverage check completed with 1/1 expected tables covered, no gated finding, and one non-gated warning. The alias then failed during `verify.example` setup with PostgreSQL `FATAL 53300 (too_many_connections)` while trying to create/ensure `threadline_phoenix_test`. The later Dialyzer, live slice, and browser stages were not reached.

A read-only post-run snapshot reported `max_connections=100`, 30 idle connections across three other databases, and five sessions without a database. It was collected after `mix ci.all` exited and therefore does not identify connection occupancy or owners at failure time. No clients or processes were terminated. The concrete precondition for a future separately authorized canonical run is verified task-local PostgreSQL capacity with no overlapping DB-heavy suites; no pool size or test scope was changed here.

After the canonical command, `python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-inventory --self-test` passed all 15 checks. Current lock hashes still match the prior ledger: root `00e6393a22730830470a8253a3cbbd49ca4adc8fd8768573516f58e592502e00`, bench `70392fba94a8798e746db0c7b8b2861b267c6922758fd5dc27240e4dcec3427a`, example `d3f34675157bd1d18e38d026aa0d89279dd2e46a4e55a5c82e0827f1ed5b3bff`, and E2E `b6a4ce7846424aa819a7b6e74aad244442cfdb5b7ad10d2d84916bf15babbcdd`. Package version remains `1.1.0`; the commit modifies no product or lockfile source.

**Current acceptance remains blocked.** The prior successful canonical result on `2495891863f5a0fbaab8800a787d668daeb67625` is retained as historical evidence for that source identity. The current formatter-fix candidate's canonical command did not finish all stages, and there is still no passing nine-run receipt. Plan 248-04 remains halted and ADM-04 incomplete. No additional repeat or canonical run was launched.

## Corrective clipboard-proof follow-up — 2026-11-11

The later isolated canonical run on source `ab65c0147ad7bf58e7d3b2394c55514868c2bec5` exited 0 in 1,427 seconds. The root suite passed 3,400 tests / 0 failures / 3 excluded; the example suite passed 132 / 0; Dialyzer reported 0 errors and the live slice passed 17 / 0. Browser evidence was **417 first-attempt passes, one retry-passed desktop clipboard flake, and 56 configured skips**. This is not a clean 418-pass result. Its full log SHA-256 is `a6bffa528adf26a6a9e29020bc2d6483418b3eb833fdaaafc9be9013eed9d52b`; the portable canonical receipt SHA-256 is `4b0c7b90db52201ec399b1fb5c850ffa505f7d2abb7eb22e8e405ab8a7160462`.

Before later Playwright runs, the original first-attempt error context was preserved with SHA-256 `15a579cc832e6a755b9a1f47d022ab2d3cb52e88b9118f002abb6e1ab730e7e2`, in a private snapshot whose manifest hash is `7ff79e0bc66aaf00ef6e95594931709dd2123b261aa1df9ac8324a087dbf7099`. The error context shows the copy button was not focused at the 15-second assertion. Trace and screenshot were disabled, so this record does not establish the focus-loss chronology or root cause.

The one-line change in `operator-route-states.spec.ts` waits for `[data-phx-main]` to report `phx-connected` after direct navigation, before locating or clicking the copy control. The original test file SHA-256 was `ac1c6341555fb021a1b0176eb7785692adc71bcc33e6304e5341fabb7639b4d1`. The checked source SHA-256 was `ac640f7ba157c04976cfa917805e50bc5cd1a4c6843b51065ea749af69e9b5a7`; it was committed unchanged as `ac260b47cc642d0a62cdca30e07ea6bfc863e1db`, with diff SHA-256 `78d5bdc42db62b354cba9f3a2509dfa74f7c3b4aa8bf1949093707808b68e675`. Test wrappers recorded base HEAD `ab65c0147ad7bf58e7d3b2394c55514868c2bec5`; no source edit occurred between the bounded checks and commit.

The target case passed six bounded invocations (three desktop and three mobile, `--retries=0`, `--repeat-each=3`). One run of the complete affected spec passed 41 tests and had 11 configured skips total across both projects (`--retries=0`). The root discovery contract passed 9 tests / 0 failures, and the candidate inventory validator passed all 15 checks. Exact command, elapsed time, and individual log hashes are in [248-CLIPBOARD-PROOF.md](248-CLIPBOARD-PROOF.md). The local browser runs used task-owned PostgreSQL 15.17, the supported DB floor; this does not establish the full minimum/current/latest CI matrix. The task-owned service remains running for the parent to stop; the shared service was unchanged.

The assertion establishes the contract only after LiveView reports `phx-connected`; it does not cover a pre-connect copy attempt or prove why the original focus assertion failed. No fresh canonical run, full-root repeat, or broad browser run followed this change. The nine-run acceptance remains failed and no further repeat is authorized. Plan 248-04 stays halted and ADM-04 incomplete; the bounded clipboard proof does not replace the missing nine-run receipt. See [248-CLIPBOARD-PROOF.md](248-CLIPBOARD-PROOF.md) for the full evidence record.
