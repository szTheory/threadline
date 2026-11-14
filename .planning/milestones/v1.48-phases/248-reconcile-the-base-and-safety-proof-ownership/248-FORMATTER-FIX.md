# Phase 248-04 formatter timeout remediation

## Attribution

The renewed repeat receipt is a real failure: source `8311dc64ac4b7f0b686e27de41839899803139c7`, seed `500886`, true suite exit 2, capture exit 0, 2,611 seconds elapsed, and classifier `flaky` after six clean runs and a seventh timeout. The timeout stack enters `ownership_errors/2` through `owned_files/1` and `Path.wildcard/2` while checking the synthetic overlap case. The immutable receipt is [248-RENEWED-REPEAT-RECEIPT.json](248-RENEWED-REPEAT-RECEIPT.json); its complete raw log remains private and is bound by SHA-256 `053a996abfade63a34883cce8986bf3c6b947a21e27be80f7af0a9d3beadb7a1`.

The source confirms repeated recursive expansion inside the ownership check. It does not prove those scans alone consumed the full 60-second timeout, and this report assigns no environment or machine-load cause.

## Change

`ownership_errors/2` now builds an ordered list of `{owner, owned_files(owner)}` once at the start of each invocation and checks every candidate against those local sets. The function recomputes them on each invocation, preserving the overlap and uncovered controls' modified configurations. It retains the list, including duplicate owner records and their order; no persistent cache or new abstraction was added.

The test keeps all 12 representative paths, the exact single-owner / overlap / uncovered assertions, the synthetic `bench/**/*.exs` overlap input, `async: true`, the 60-second timeout, existing tags, and suite coverage.

Across the three existing `ownership_errors/2` calls, static inspection counts 70 owner-set builds and 168 input-pattern wildcard expansions before the change, versus 15 builds and 36 expansions after it. These counts describe source traversals; they do not predict runtime or establish that the remediation alone will avoid every future timeout.

## Focused verification

At seed `500886`, the standalone pre-change file passed: 1 test, 0 failures, 0.8 seconds ExUnit time (2 seconds wall time). The same file after the change passed: 1 test, 0 failures, 0.2 seconds ExUnit time (1 second wall time). `mix verify.format` exited 0 in 3 seconds. These standalone measurements do not erase the repeat failure or substitute for running under suite load.

The code-only fix is commit `2b00c6bea83e42fe8843b2b8d7767f7ffbe13df4`; the source SHA-256 is `fa1ce02fa3494cb8bcad8126e06c80d20fedf4de949e67dcc358f012732f277a`. The commit changes only `test/threadline/formatter_topology_contract_test.exs`.

## Canonical candidate result and remaining blocker

The one authorized `mix ci.all` run on that commit exited 1 after 438 seconds. Its root suite passed 3,400 tests with 0 failures and 3 existing exclusions in 409.4 seconds. Credo, the three-lock audit, repository hygiene, xref, and the threadline coverage check also completed. The alias then stopped in `verify.example`: PostgreSQL returned `FATAL 53300 (too_many_connections)` while the example test helper tried to ensure its test database existed. Dialyzer, its live slice, and browser stages were not reached in this invocation.

A read-only post-run snapshot showed `max_connections = 100` and 30 idle sessions across three other databases, plus five sessions without a database. This snapshot was taken after the failed command exited; it does not establish the connection count or client ownership at failure time. No process or database client was terminated. The concrete precondition for any separately authorized canonical rerun is a task-local or otherwise verified PostgreSQL instance with adequate available connections and no overlapping DB-heavy suites.

The candidate inventory validator then passed all 15 checks. All four dependency lockfiles retain their recorded hashes, and package version remains `1.1.0`. No full repeat, additional full canonical run, or test-scope/resource change is authorized here. Plan 248-04 remains halted and ADM-04 incomplete because the renewed repeat did not produce nine clean runs.
