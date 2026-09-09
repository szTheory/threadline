# Phase 198 Round 10 ref disposition

Observed read-only at `2026-09-09T17:58:29Z` for `szTheory/threadline`.

<!-- inventory-sha256: fca235d9eeaac4dd89e44adf9c0b474b77f3e7a0f0cc8f4697dba0adcc99f73b -->
<!-- controls: a97f527e375f4c1909236b7dbdd5fa3fd9b7d2f2|34|46213f9bc0ecbff356058d317c882d5a643ae86f|1040e93d8ae5e79672757f6acbfaeae1e7cb27c6db2d01cb7483c081fd94dcc4|f02c07a558af08ef0d048996463adb29c61dcffd28c940b6562356f2293efcc3|5253096fa066c0e3507f2a91e5a76ef2217191b63d76c90d6344ca2300ac5c1a -->

## Pinned subjects

| Branch | PR | Local SHA | Remote / PR-head SHA | Head → base | Recommendation |
|---|---:|---|---|---|---|
| `ci/198-gap-closure` | #29 | `ffcff0d1613381950cfb6baad93e90aee19dcece` | `f748e43d7e4c1e63a0142569a55f57c7187e5cb1` | `ci/198-gap-closure` → `main` | **retire** |
| `ci/198-round5` | #32 | `14f923a71c0901cd5f95fc3a72e0971b05861543` | `14f923a71c0901cd5f95fc3a72e0971b05861543` | `ci/198-round5` → `main` | **retire** |
| `ci/198-round6` | #33 | `23c16267d11a63858aad23eab63c9fbfc385ef4b` | `23c16267d11a63858aad23eab63c9fbfc385ef4b` | `ci/198-round6` → `main` | **retire** |

<!-- target: ci/198-gap-closure|29|ffcff0d1613381950cfb6baad93e90aee19dcece|f748e43d7e4c1e63a0142569a55f57c7187e5cb1|f748e43d7e4c1e63a0142569a55f57c7187e5cb1|main|retire -->
<!-- target: ci/198-round5|32|14f923a71c0901cd5f95fc3a72e0971b05861543|14f923a71c0901cd5f95fc3a72e0971b05861543|14f923a71c0901cd5f95fc3a72e0971b05861543|main|retire -->
<!-- target: ci/198-round6|33|23c16267d11a63858aad23eab63c9fbfc385ef4b|23c16267d11a63858aad23eab63c9fbfc385ef4b|23c16267d11a63858aad23eab63c9fbfc385ef4b|main|retire -->

Every local and remote target tip is reachable from both the observed current HEAD and local
`main`. Each unique-commit list and machine-readable numstat is empty. The local and remote tips
of `ci/198-gap-closure` differ, but the local tip is the newer preserved object and the remote tip
is already in its history. The evidence therefore recommends retirement for all three without
discarding unique work. Exact merge bases, ahead/behind counts, empty unique-commit identities,
diffstats, rationales, and restore commands are in the joined JSON inventory.

## Complete `ci/198-*` universe

- Local: exactly the three decision targets.
- Remote: six refs — the three targets plus `ci/198-05-verify`, `ci/198-round3`, and
  `ci/198-round4`.

This is a material scope conflict for Plan 52: its decision authority names only the three targets,
while its final predicate requires the complete remote `ci/198-*` set to be empty. No selection at
this checkpoint authorizes deleting the three extra remote refs. The inventory records the full
set instead of laundering it into a three-ref assumption.

## Stable external controls

- `origin/main`: `a97f527e375f4c1909236b7dbdd5fa3fd9b7d2f2`
- PR #34: OPEN, draft, `phase-199/scroll-cost-cause-fix` → `main`, head
  `46213f9bc0ecbff356058d317c882d5a643ae86f`
- Effective rules plus classic-protection digest: `1040e93d8ae5e79672757f6acbfaeae1e7cb27c6db2d01cb7483c081fd94dcc4`
- Required contexts: exactly `["CI required"]`; digest
  `f02c07a558af08ef0d048996463adb29c61dcffd28c940b6562356f2293efcc3`
- Worktree identity list (path + branch, deliberately excluding mutable HEAD): one worktree;
  digest `5253096fa066c0e3507f2a91e5a76ef2217191b63d76c90d6344ca2300ac5c1a`

The observed active branch, active tip, upstream, and upstream tip are provenance only. They are
not decision authority or a cross-plan equality control; Plan 51's own commit must advance the
active local tip before Plan 52 starts.

## Maintainer decision

**Status: decided — abort (`2026-09-09T18:20:16Z`).** No recommendation, auto-advance setting,
silence, D-39 disposition, or branch ancestry constitutes mutation authority.

The maintainer's verbatim response was:

> abort

`abort` grants no mutation authority. All local branches, remote refs, pull requests, tags,
`origin/main`, rulesets, and protection settings remain outside this plan's authority.

<!-- maintainer-decision-json
{
  "option": "abort",
  "verbatim": "abort",
  "recorded_at": "2026-09-09T18:20:16Z",
  "inventory_sha256": "fca235d9eeaac4dd89e44adf9c0b474b77f3e7a0f0cc8f4697dba0adcc99f73b",
  "subjects": [
    {
      "branch": "ci/198-gap-closure",
      "pr": 29,
      "local_sha": "ffcff0d1613381950cfb6baad93e90aee19dcece",
      "remote_sha": "f748e43d7e4c1e63a0142569a55f57c7187e5cb1",
      "head": "ci/198-gap-closure",
      "base": "main",
      "head_sha": "f748e43d7e4c1e63a0142569a55f57c7187e5cb1"
    },
    {
      "branch": "ci/198-round5",
      "pr": 32,
      "local_sha": "14f923a71c0901cd5f95fc3a72e0971b05861543",
      "remote_sha": "14f923a71c0901cd5f95fc3a72e0971b05861543",
      "head": "ci/198-round5",
      "base": "main",
      "head_sha": "14f923a71c0901cd5f95fc3a72e0971b05861543"
    },
    {
      "branch": "ci/198-round6",
      "pr": 33,
      "local_sha": "23c16267d11a63858aad23eab63c9fbfc385ef4b",
      "remote_sha": "23c16267d11a63858aad23eab63c9fbfc385ef4b",
      "head": "ci/198-round6",
      "base": "main",
      "head_sha": "23c16267d11a63858aad23eab63c9fbfc385ef4b"
    }
  ]
}
-->

The decision applies only to the exact three pinned `(branch, PR, local SHA, remote SHA, PR head
SHA, base)` subjects above. It grants no authority over PR #34, `origin/main`, CI required,
rulesets, protection, the three extra remote `ci/198-*` refs, or D-39.
