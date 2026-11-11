# Formatter topology contract remediation review

**Status:** Clean for the reviewed one-file diff; no source findings.

**Scope:** `test/threadline/formatter_topology_contract_test.exs`, comparing baseline `8311dc64ac4b7f0b686e27de41839899803139c7` with commit `2b00c6bea83e42fe8843b2b8d7767f7ffbe13df4`.

## Source identities

- Current file SHA-256: `fa1ce02fa3494cb8bcad8126e06c80d20fedf4de949e67dcc358f012732f277a`
- Committed one-file diff SHA-256: `8885df7e0c9b073f241a248c7bbcb0585ea02578765c384112a35ad90929178b`
- Baseline file SHA-256: `214d5ada2b1f6e1eefa2623d2c60d44b05c5a4817034ce7c6233010002c746b5`

## Review

The diff precomputes an ordered list of `{owner, owned_files(owner)}` once per `ownership_errors/2` call, then checks each path with `MapSet.member?/2`. It preserves the owner list rather than reducing it to a map, so original order and duplicate owner records remain observable. Each invocation computes from the owners passed to it; the overlap and uncovered negative controls therefore see their separately modified configs.

The diff changes no representative paths, expected owners, exact overlap/uncovered assertions, tags, async setting, or timeout. The exact single-owner assertion remains over all 12 representative paths. The overlap control still expects root and bench ownership; the uncovered control still expects no owner.

The static traversal count falls from 70 to 15 `owned_files/1` builds and from 168 to 36 input-pattern wildcard expansions per test call. This is consistent with the source structure: 12 representative paths repeat all five owners' input walks, while the two one-path negative controls each need only one owner-set build per owner.

The overlap control retains `bench/**/*.exs`, which can walk the nested bench dependency/build directories. After this change it performs that recursive synthetic walk once for the overlap invocation instead of once per owner for every candidate path. The pattern still represents a real overlap for `bench/audit_capture_bench.exs`; the single recursive walk is not a material residual defect based on this diff and the focused result. A nonrecursive pattern could reduce it further, but that is optional and not warranted as required work by the available evidence.

The author’s focused logs report the unchanged test passing once at 0.8 seconds before and once at 0.2 seconds after, plus a passing format check. These are single observations, not a whole-suite timing guarantee. I ran no tests or commands. The one canonical `mix ci.all` is still running, so this review does not claim its result. The latest full repeat remains flaky after six passes and a seventh-run timeout; the explicit no-further-repeat stop remains in force. The source-backed repeated-wildcard mechanism is addressed, but the earlier timeout’s full cause is not proven.
