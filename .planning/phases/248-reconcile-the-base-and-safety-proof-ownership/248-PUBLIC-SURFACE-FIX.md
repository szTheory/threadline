# Phase 248-04 public-surface proof follow-up

## Scope and source changes

The public reference ownership test had two repeated costs in the same aggregate check. It rebuilt `reference_inventory/0` once for each of 80 subjects, and each helper call separately invoked `discovered_mix_tasks/0` twice, reparsing the same source set. The check now builds one inventory for the aggregate subject set. Each `reference_inventory/0` invocation still recomputes from source, but it materializes the Mix task list once and reuses it for `modules` and `tasks`. There is no persistent cache, no new abstraction or dependency, and all subjects, owners, changelog exceptions, reference assertions and negative controls remain intact.

The source-derived measurement used the current `source_files/0` and public subject-selection rules: 134 source files and 80 aggregate subjects (28 local extras plus 52 visible module-doc subjects). Before the change, building visible module-doc subjects performed one source AST parse pass; then the aggregate loop ran 80 inventories, each with two Mix-task passes and one environment-key pass. That is 241 passes, or 32,294 source-file AST parses. Afterward, subject discovery still performs one Mix-task pass and the single inventory performs one Mix-task plus one environment-key pass: 3 passes, or 402 source-file AST parses. This is a source-derived traversal count, not a runtime profiler. It does not attribute every millisecond of the suite timeout to those scans.

The doc-only correction addresses independent review finding WR-01 in heading 15. The host pipelines now live on `scope "/admin"`, enclosing `threadline_operator_surface "/audit"`; the ignored `pipe_through` mount option is removed. The repository, authorization callback, scope transformer, coverage callback and mount path are unchanged. No product/router code or permanent literal-mirroring test changed.

The test change is commit `6843856f` (diff SHA-256 `b7c15dd8fbb0684bf63820aeeb56a11d564053dd866945b486bed09961d1de4a`); the guide correction is separate commit `2c6c6152` (diff SHA-256 `a3101e7aa61a8c2150b292493148d6e5a44fe2afe85d611d112cbcf17ae65541`). The pre-change source hashes were `d6d2e3f77f0f615f77f61aa32ab20d1f670d770b56578bae5d35068c13acba8b` for the test and `6dcda3d9119165902f349ac4894cd7f96dcf356acc46db0850444dedbdb13d6d` for the guide. The checked sources were `bba1c502e1506784ef83c01e88be01a9f74e455d9313dc2e279718a49951f187` and `9cab1ffa01d5f84436c6bd01cf22b7791980038b327e7f7b6db3de257395b325`, respectively.

## Focused verification

| Check | Result | Log SHA-256 |
|---|---|---|
| Before-edit `MIX_ENV=test mix verify.test test/threadline/public_surface_contract_test.exs:511 --seed 587264` | Exit 0; 47 tests, 0 failures, 46 excluded; selected test 15.3s ExUnit, 17s wall | `44ad3632a05049929b38952bc2f8ab53d875bbc0435bc41ff550c20fbcc4131b` |
| After-edit same selected test and seed | Exit 0; 47 tests, 0 failures, 46 excluded; selected test 0.6s ExUnit, 1s wall | `4fe420a67cb7bd522345798aa97298d2137f63386b07a2ecb5358b4cf039590f` |
| Complete affected `public_surface_contract_test.exs` once | Exit 0; 47 tests, 0 failures; 6.7s ExUnit, 7s wall | `35592c0bf8d0706b57e9bbe3f8cd5fd4376d8255864a46155115b93caa3c4726` |
| Focused walkthrough and operator-surface doc contracts | Exit 0; 14 tests, 0 failures; 0.06s ExUnit, 1s wall | `450a21dc2cc9114229262708d481497bf78a62ab99e4362dad2dd0176b36ce27` |
| `mix verify.format` | Exit 0; 1s wall | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| Candidate inventory validator `--check-inventory --self-test` | Exit 0; all 15 checks passed | `110fcd973d26c6caaa829d1010280a0f595ee357a4c18853df9c1e97a0fc7d26` |
| Temporary router compile probe | Exit 0; all 16 corrected-scope routes include both `:browser` and `:require_admin`; the old mount-option form fails that same pipeline check | `0bbc38fddaa1fefed0b8b431436fd42c21a2224acb31edbc6ed839373e2e90c4` |

The temporary probe compiled minimal host pipelines and callback stubs around the actual guide snippet. Phoenix's `routes/1` representation omits pipeline data, so the probe reads each compiled route through `Phoenix.Router.route_info/4`. The first probe version incorrectly assumed `routes/1` exposed that field; it was corrected without changing repository source. The throwaway script and probe output are retained privately.

## One root-suite invocation and its diagnosis

The one permitted root command was `MIX_ENV=test THREADLINE_PROPERTY_SCALE=5 mix verify.test --seed 587264`, bounded to 15 minutes with a 60-second termination grace. It exited 2 after 421 seconds: 32 properties, 3,400 tests, 1 failure, and 3 existing exclusions. The sole failure was `CleanCheckoutContractTest` at `test/threadline/clean_checkout_contract_test.exs:140`: its `git worktree add` fixture was denied permission to create a temporary registration under shared Git metadata (`Operation not permitted`). The complete root log SHA-256 is `051cf446a030fa6c3952a559cdd8254dde790e7f963a3e900739cd9f031d8947`.

As a narrow diagnostic, that exact test passed with the necessary scoped Git metadata access: 9 tests, 0 failures, 8 excluded; 2.9s ExUnit and 5s wall. Its own cleanup block removes the uniquely named temporary worktree. The original root invocation remains a failure; the narrow pass does not convert it into a root pass. No second root invocation was run.

## Latest full-repeat result and status

The one user-approved full repeat on source `baa3a27d56bf6047d791f709aa78d1692d8294c9` is terminal and failed. The portable result is [248-POSTFIX-REPEAT-RECEIPT.json](248-POSTFIX-REPEAT-RECEIPT.json): wrapper exit 1, actual suite exit 2, capture/tee exit 0, 1,932 seconds of the 3,300-second budget, scale 5, max-cases 36, five clean runs followed by a 60-second timeout in iteration 6 at seed `587264`; the unchanged classifier returned `flaky`. The exact test was `all local, external, and module-doc subjects have one exact owner` at line 511. Its stack reached `source_env_reads/0`, then `reference_inventory/0`, from the per-subject loop. Raw repeat log SHA-256: `ab90c462e3df5c95a43f026e152f45c8d7aaa21eaee8c8847fbef6d425071478`.

The selected pre-edit baseline passed, but that does not erase the real repeat timeout. The test and documentation fixes have bounded current-source evidence above. The root suite remains failed for its shared Git metadata permission issue. No fresh canonical run, repeat, verify-flake invocation, or substitute repeated-root loop was performed. Plan 248-04 remains halted and ADM-04 incomplete because there is no passing nine-run receipt; the user's repeat grant is consumed. Independent review of these changes is pending. The task-owned PostgreSQL service was left untouched for the parent to manage; the shared service was not modified.

## Protected identities

The production router (`lib/threadline/operator_surface/router.ex`, SHA-256 `6dad6c1939e6915b1f147a5bccf4cff60a20dd0b31b6eae7dfe106ca099bb2a9`), operator script (`lib/threadline/operator_surface/script.ex`, `168baaa726aa1ab4f846af78bb2f11864e575dc70c1fe17d3aee16c80f47985a`), all four dependency locks, and package version `1.1.0` remained unchanged. The exact lock hashes are preserved in the portable repeat receipt.
