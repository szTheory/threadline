---
phase: 203-real-gates
plan: 10
subsystem: code-quality
status: complete
tags: [credo, gate-01, gate-02, gate-05, config, contract-test]
requires: [203-09]
provides:
  - ".credo.exs: credo 1.7.18 scaffolding copied verbatim, `strict: true`, and `checks: %{extra: [3 deltas], disabled: []}` over the 69 embedded defaults"
  - "test/threadline/credo_config_contract_test.exs: describe \"config shape (GATE-01)\" next to the Plan 09 register"
affects: [204]
tech-stack:
  added: []
  patterns:
    - "Credo config as deltas: `extra:` re-parameterizes default checks by module key. With no `enabled:` key the embedded default set stays whole, and `disabled: []` means nothing is silently dropped"
    - "The contract reads deps/credo/.credo.exs at test time. A Credo bump fails the header-version assertion until the scaffolding is re-diffed"
key-files:
  created: []
  modified:
    - .credo.exs
    - test/threadline/credo_config_contract_test.exs
decisions:
  - "D-09 Logger finding is resolved by the check's `metadata_keys:` param in .credo.exs, not by Logger env config. The keys are deleted_changes, deleted_transactions, batch, total_changes, and total_transactions, re-verified at lib/threadline/retention.ex:181"
  - "D-26 params assertion as annotated: delta keys must be in Mod.param_names() ++ @credo_builtin_params [:category, :exit_status, :files, :priority, :tags], and that pinned list must be a subset of Credo.Check.Params.builtin_param_names(). A synthetic misspelled key (exit_statuss) is rejected"
  - "The new contract test aliases Credo.Check.Params, because the live gate itself flagged the nested reference as AliasUsage. The rebuilt gate caught this on its first run"
metrics:
  duration: "~40 min"
  completed: 2026-09-23
plan_head_before: e8e4b04edd4ee1cc892bb033f28e8b541f457995
actuals:
  tokens: 2400
  tasks: 2
  commits: 2
---

# Phase 203 Plan 10: Live Credo Gate as Upstream Scaffolding plus Three Deltas Summary

`.credo.exs` no longer uses `enabled: [2 checks]`, which replaced Credo's defaults and linted almost nothing. It is now credo 1.7.18's scaffolding copied verbatim, with `strict: true` and three `extra:` deltas (TagTODO advisory, ModuleDoc ignore lists cleared, and Logger metadata keys). `mix credo --strict` runs 69 checks and reports 0 issues. A config-shape contract locks the file against regression, and the whole phase passed locally through `mix ci.all`.

## Final gate numbers

- credo: 0 issues, 69 checks (484 findings under full defaults at phase start; Plan 09 register n/m: Nesting 26, CyclomaticComplexity 16, ceiling 42, historical max 46)
- dialyzer: Total errors: 0 (`MIX_ENV=dev mix dialyzer --no-check`, and again inside ci.all)
- xref compile-connected cycles: 0 (`mix verify.xref_cycles` prints "No cycles found")
- `mix credo info --strict --verbose --format json | jq '.config.checks | length'` returns 69, the same as upstream's embedded `enabled:` length. No extra entry added or duplicated a check.

## Tasks

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Rebuild .credo.exs as upstream scaffolding plus deltas | 9a2633c2 | .credo.exs |
| 1 | Pin the Credo config shape in the contract test | b5e24ce6 | test/threadline/credo_config_contract_test.exs |
| 2 | Phase-end proof (verification only, no code change) | none | none |

## TDD Gate Compliance

- RED: I added the config-shape describe block and ran it against the old `.credo.exs`. There were 3 failures, all expected: the `checks` keys included `:enabled`, the header regex did not match, and the AST walk found an `:enabled` key. The params, upstream, and alias tests passed from the start, as they should, because they read only upstream Credo and mix.exs.
- GREEN: after the rebuild, 15 tests and 0 failures.
- Commit order follows the plan's action (d): the `.credo.exs` commit comes first and the test commit second.

## ci.all log excerpt (`DB_PORT=5433 mix ci.all`, exit 0, log at /tmp/p203-10-ci-all.log)

```
Analysis took 0.6 seconds (0.05s to load, 0.5s running 69 checks on 288 files)
3202 mods/funs, found no issues.
No cycles found
1717 tests, 0 failures, 1 excluded
117 tests, 0 failures
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
STORY_VERDICT: PASS ... (critic_trust / mechanical)
  26 skipped
  318 passed (3.1m)
EXIT=0
```

Format, credo, compile --warnings-as-errors, xref_cycles, compile_no_optional, test, threadline, example, doc_contract, dialyzer, critic_trust, and mechanical all passed. The browser lane passed 318 with 26 skipped.

`ci.all` runs the browser lane with `CI=true`, and `operator-screenshot-regression.spec.ts` skips itself under that flag. So I measured the screenshot baseline separately with `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-screenshot-regression.spec.ts`. It showed **8 failed and 2 passed**, exactly the known set: `:108` dense Timeline, `:115` row-history drawer, `:136` Exports readiness, and `:145` Retention safety, each on desktop-chromium and mobile-chromium. Home passed on both projects. There was no ninth failure and no name changed. Baselines were not regenerated.

The known `clean_checkout_contract_test.exs:255` timeout did not appear.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The new contract test tripped the live gate's AliasUsage check**
- **Found during:** Task 1 (c), on the first `mix credo --strict`
- **Issue:** `Credo.Check.Params.builtin_param_names()` was a nested module reference in the new test.
- **Fix:** added `alias Credo.Check.Params` in the test. I added no delta or disable.
- **Files modified:** test/threadline/credo_config_contract_test.exs (folded into b5e24ce6)

**2. [Rule 1 - Acceptance grep] Why-comments reworded**
- **Issue:** my first why-comments named `Design.TagFIXME` and `AliasUsage`, which broke the acceptance greps requiring `grep -c TagFIXME` = 0 and `grep -c AliasUsage` = 0.
- **Fix:** reworded them as "FIXME tags stay blocking at their upstream default" and "low-priority alias findings are otherwise hidden". Behavior did not change.

Otherwise the plan ran as written. No refactor commits for ModuleDoc were needed, because clearing the ignore lists produced 0 new findings. The `test/support/repo.ex` moduledoc predicted by D-24 had already landed in 203-07 (fbff2a4b).

## Deferred follow-up

- **`.git-blame-ignore-revs`**: add the pure-mechanical `refactor(203-03)` through `refactor(203-09)` commits, but only once their SHAs are final on origin/main. A squash-merge or rebase would invalidate these local SHAs. The candidate local SHAs below are **provisional**:
  - 203-03 (alias sweep): 64a82c81 7e00059d cc0b89eb f62d6002 da0f13cb 94cb0cbd 0111d1a3 363e0c7f 5f7ab174 4c920206 cac01506 c0e97e16 3bccea12 dff51f7f be53ee18 f7a348ff bad65243 41ecf0fa 4f9180b5 ff1e2972 50a3105c 5cce5915
  - 203-04 (alias sweep): 7a62e7b4 8fd13a06 b58be3bb 9ece3a2b adc4ea78 e7ad0968 0da44bf9
  - 203-05 (alias sweep): 1b31fcbc b6c72979 d11c1c85
  - 203-06 (mechanical): 2414bd6a 3be71d5c bbad1706 86572545 6cf8c112 0906d8d7 2139baf8 16dac822 f8664624 b711fcfa 9ece59ab d8d6b48d 25b98ba9 1874ae19 0663f317 06c8a155 aa6835d6 ada260f2 a08e0daa 58a2961b f71339a0 d351c714 a8fdcc51 a5cb75a6 2569f012. The `@type t` additions (bba48f2d 02317082 f73f0ae9) are excluded because they are API additions, not pure mechanical changes.
  - 203-07 (mechanical): f1459883 02eae7c4 6fc7affc 5f4d914a fc32929b 5679ad6c e234d4f6 274f86af e09a4ecc 486ba9c1 163fa31a adb28d08 0232df37 fbff2a4b. The contract addition a514be36 is excluded.
  - 203-08 and 203-09 (comment-only structural filing): 40f6df19 590dfe8c b173d49e e8532413 85a139c3 d5175fdb f3653ab2 40b3d11e dc956ae4 534f9c9b 31d7488e c909c65f c44b4aab bfc5d6b9 0b2aa239 b19ce9fe f82ddf5c 05bc005d c0c8fd8c 583e9c3a 117762c4 473cf425 7628712e 149fa6da 1ee89a25 99525a7e c85e2b98 e1fcabc9 29612279 8e2411a8 b1daee6f b2527a1a ef1a4c1e d4a61b2c. The flatten commits and the register contract commit are excluded.
- **A-GATE-04 (Elixir 1.15 min lane):** the proof that the `@compile` deletion and the xref step work on the 1.15 minimum lane is still pending the first CI run. Locally only the 1.17.3/OTP 27 toolchain was exercised.

## Known Stubs

None.

## Threat Flags

None. T-203-19 through T-203-23 are mitigated as planned: the AST `:enabled` walk, the `disabled == []` check, the header-version and upstream ≥ 69 checks, the env-independent `metadata_keys:`, and a halt-only policy (no gate relaxation).

## Self-Check: PASSED

- .credo.exs, test/threadline/credo_config_contract_test.exs present; commits 9a2633c2, b5e24ce6 found.
