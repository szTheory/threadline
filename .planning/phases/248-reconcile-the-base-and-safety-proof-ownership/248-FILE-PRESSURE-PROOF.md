# Phase 248 Plan 04: File-Pressure Follow-up

**Status:** bounded local remediation complete; Plan 248-04 halted and ADM-04 incomplete.

## Latest repeat failure

The single user-approved nine-run invocation is terminal and failed on pre-fix source `10442d31a8c7df50111effe1614c99bf5e7e87ee`. It completed three clean runs, then five asynchronous contracts timed out at 60 seconds in iteration 4 with seed `579775`. The suite exited 2, wrapper exited 1, capture exited 0, elapsed time was 1,582.26 seconds, and the classifier returned `flaky`. The portable failure record is [248-INVENTORY-REPEAT-RECEIPT.json](248-INVENTORY-REPEAT-RECEIPT.json). The raw log digest is `2e0c0cae2fe0138ae75650fa47beb2a0b6c47694abfdd09f3f80bd23d31c3ae1`.

The five failures were the RepoContractScope negative fixture loop, FormatterTopology owner check, RemovedArtifact live scan, StorageSchemaCallSite real-tree sweep, and StorybookBoundary allowed-terms scan. Their caller stacks ended in `gen_server.call` / `file.call` while waiting on `File.read!`, `Path.wildcard`, or `getcwd`. The stacks do not prove a single stalled operation or an exclusive cause. The repeat grant is consumed; no further full repeat, `verify.flake`, repeat-until-failure, substitute repeated root loop, or fresh canonical/browser run is authorized here.

## Source deviation and measured traversal changes

Only these test files changed in source commit `eaedaf5e1a92c9fd797f37fefaffad14b5376e8e`:

| File | Change | Static before → after |
| --- | --- | --- |
| `test/threadline/repo_contract_scope_contract_test.exs` | Compute the existing library-module inventory once inside each 13-body positive and 9-body negative fixture test, then pass it to `flagged?/2`. Direct single-fixture controls keep a fresh default inventory. Other live-tree inventory calls remain unchanged. | The two loops plus two direct controls: 24 → 4 inventory builds. With 133 current library `.ex` files: 3,192 → 532 source reads. |
| `test/threadline/storage_schema_call_site_contract_test.exs` | Capture `File.cwd!/0` once before the result loop and use lexical `Path.relative_to/2`, preserving the path strings and real-tree coverage. | Before: R `getcwd` requests for R discovered results. After: 1 request per sweep; saves R−1. R was not separately measured. |
| `test/threadline/formatter_topology_contract_test.exs` | Build ordered baseline `{owner, owned_files(owner)}` pairs once. Rebuild only the root owner for the synthetic `bench/**/*.exs` overlap and only the `bench` owner for the uncovered mutation. | 15 → 7 owner-set builds and 36 → 17 wildcard expansions; saves 8 builds and 19 expansions per invocation. |

The changes retain all 22 fixture bodies, two direct fixture controls, all 12 formatter representative paths, exact expected overlap/uncovered assertions, all five formatter roots and input globs, duplicate owner records/order, async settings, timeout, tags and suite coverage. No persistent cache, dependency, product source, runtime behavior or global test setting changed.

## Verification

| Check | Source / conditions | Result |
| --- | --- | --- |
| Focused three-file suite | Pre-commit working-tree content at HEAD `10442d31`, later committed unchanged as `eaedaf5e`; seed `579775`, scale 5, max-cases 36 | Exit 0; 38 tests, 0 failures; 1.36 seconds. Private log SHA-256 `2f4fb9012178dda47d957bab3650db3e9739818fa1628b3bea84c34b0c504a6b`. |
| `mix verify.format` | Same pre-commit working-tree content | Exit 0; 0.66 seconds. |
| `mix verify.credo` | Same pre-commit working-tree content; strict repository check | Exit 0; 5,746 modules/functions, no issues; 2.98 seconds. |
| Candidate inventory validator | `verify-candidate-baseline.py --check-inventory --self-test` | Exit 0; all 15 checks passed. Private log SHA-256 `110fcd973d26c6caaa829d1010280a0f595ee357a4c18853df9c1e97a0fc7d26`. |
| One ordinary root invocation with the existing observer | Clean `eaedaf5e`; seed `579775`, scale 5, max-cases 36; 15-minute limit plus 60-second termination grace | Exit 0 in 234.24 seconds; 32 properties, 3,400 tests, 0 failures, 3 exclusions. This is one bounded root result, not nine-run acceptance. |

The first focused invocation also passed 38/0 in 1.58 seconds but emitted a compiler warning that `flagged?/2`'s fresh default was unused. The direct single-fixture controls were then routed through that fresh-default helper, and the source was formatted. The first `mix verify.format` check reported only those formatting differences; after formatting, the final focused suite, format check and strict Credo all passed. This targeted correction does not change the full-repeat result.

Before the root invocation, the pre-edit observer log, event stream, sample stream, launch record and result were snapshotted read-only. Their manifest SHA-256 is `d75dc28aef61849c5346cb7ef5aa9c9c30b6944c84bb8daa911f75a0d48bf653`. The before/after root log SHA-256 values are `5aa9b8cd46a4d1222efeb01b9a2d34793c1301bd761977b8aeb8a05973b5976a` and `1159b3e8b7f50e123ae88346f02a8530a42a368e627c7e88bcd9ab4b2ae9b7e3`; event streams are `15fe7bd571ea3c4f50ee2715161ad61c8a73cacc2fa6940750699328a2c9c5c9` and `2e51cbe5aeb55b3565e85de0aac69f24e283e5a14f1926ecbef8c77d435cc783`; sample streams are `ea209025a13e8a26b357e8be7722d3ac4020ef23d6cb09b732343a6da1b903c1` and `550c5c252d6fc66bb0a9a41dbf43a42b1bcc02c886fa86cc619cbeb90ceb4187`.

| Same test in the single pre/post root observations | Before source `10442d31` | After source `eaedaf5e` |
| --- | ---: | ---: |
| RepoContractScope negative fixture loop | 28,461.283 ms | 3,853.692 ms |
| FormatterTopology representative ownership | 15,214.834 ms | 4,034.521 ms |
| RemovedArtifact live repository scan | 17,988.418 ms | 5,495.839 ms |
| StorageSchemaCallSite real-tree sweep | 21,127.519 ms | 4,797.088 ms |
| StorybookBoundary allowed-terms scan | 14,529.359 ms | 537.299 ms |

These are paired single observations under the same seed, scale, max-cases and observer method, not repeated measurements or a guarantee that the timeout cannot recur. The observer sampled the file server 1,075 times before and 928 times after; peak queued calls were 47 and 37, with maximum sample costs of 19 ms and 3 ms. The sampled stacks and reductions changed and the queue drained. This supports reduced request pressure in the observed root run, but does not establish exclusive causation or prove every timeout was caused by the three repeated scans.

The 20 source identities recorded for the failed repeat were rechecked; only the authorized formatter test hash changed among those entries. Runtime/router/script, lockfiles, package version and browser inventory stayed unchanged. No source outside the three listed tests changed.

## Remaining blocker and handoff

The full repeat still has five timeouts and no nine-run pass. ADM-04 remains incomplete. The independent review of this source commit and task-owned PostgreSQL lifecycle belong to the parent. The prior canonical alias remains historical with one retry-passed browser case; this follow-up ran no canonical alias or browser suite. Do not infer phase completion or advance Phase 249.
