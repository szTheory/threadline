# Phase 198 Round 11 ref disposition

Observed read-only at `2026-09-09T22:05:00Z` for `szTheory/threadline`.

<!-- schema: phase198-ref-disposition/v2; round: 11 -->
<!-- inventory-sha256: 88888854b44111835d753261eb15332a7c98fae7922d65d0d46e6fc5423a4655 -->
<!-- controls: a97f527e375f4c1909236b7dbdd5fa3fd9b7d2f2|34|46213f9bc0ecbff356058d317c882d5a643ae86f|1040e93d8ae5e79672757f6acbfaeae1e7cb27c6db2d01cb7483c081fd94dcc4|f02c07a558af08ef0d048996463adb29c61dcffd28c940b6562356f2293efcc3|5253096fa066c0e3507f2a91e5a76ef2217191b63d76c90d6344ca2300ac5c1a -->

## Complete preservation packets

The divergent `ci/198-gap-closure` name contains two different objects. They are separate
preservation subjects and receive non-colliding archive paths; branch-name equality is not object
identity.

| Subject | Side | Full SHA | PR | Archive tag | Restore command |
|---|---|---|---:|---|---|
| `local:ci/198-gap-closure@ffcff0d1613381950cfb6baad93e90aee19dcece` | local | `ffcff0d1613381950cfb6baad93e90aee19dcece` | #29 | `archive/ci/198-gap-closure/local-ffcff0d16133` | `git branch ci/198-gap-closure ffcff0d1613381950cfb6baad93e90aee19dcece` |
| `origin:ci/198-gap-closure@f748e43d7e4c1e63a0142569a55f57c7187e5cb1` | origin | `f748e43d7e4c1e63a0142569a55f57c7187e5cb1` | #29 | `archive/ci/198-gap-closure/origin-f748e43d7e4c` | `git branch ci/198-gap-closure f748e43d7e4c1e63a0142569a55f57c7187e5cb1` |
| `origin:ci/198-05-verify@d941ae1050c639121bdb5c1cc6fd8ea13e6cfafc` | origin | `d941ae1050c639121bdb5c1cc6fd8ea13e6cfafc` | none | `archive/ci/198-05-verify/origin-d941ae1050c6` | `git branch ci/198-05-verify d941ae1050c639121bdb5c1cc6fd8ea13e6cfafc` |
| `origin:ci/198-round3@80bf701e7486962e538d16f213874cbba8f24115` | origin | `80bf701e7486962e538d16f213874cbba8f24115` | #30 | `archive/ci/198-round3/origin-80bf701e7486` | `git branch ci/198-round3 80bf701e7486962e538d16f213874cbba8f24115` |
| `origin:ci/198-round4@f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6` | origin | `f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6` | #31 | `archive/ci/198-round4/origin-f433ef3ea6fd` | `git branch ci/198-round4 f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6` |
| `local:ci/198-round5@14f923a71c0901cd5f95fc3a72e0971b05861543` | local | `14f923a71c0901cd5f95fc3a72e0971b05861543` | #32 | `archive/ci/198-round5/local-14f923a71c09` | `git branch ci/198-round5 14f923a71c0901cd5f95fc3a72e0971b05861543` |
| `origin:ci/198-round5@14f923a71c0901cd5f95fc3a72e0971b05861543` | origin | `14f923a71c0901cd5f95fc3a72e0971b05861543` | #32 | `archive/ci/198-round5/origin-14f923a71c09` | `git branch ci/198-round5 14f923a71c0901cd5f95fc3a72e0971b05861543` |
| `local:ci/198-round6@23c16267d11a63858aad23eab63c9fbfc385ef4b` | local | `23c16267d11a63858aad23eab63c9fbfc385ef4b` | #33 | `archive/ci/198-round6/local-23c16267d11a` | `git branch ci/198-round6 23c16267d11a63858aad23eab63c9fbfc385ef4b` |
| `origin:ci/198-round6@23c16267d11a63858aad23eab63c9fbfc385ef4b` | origin | `23c16267d11a63858aad23eab63c9fbfc385ef4b` | #33 | `archive/ci/198-round6/origin-23c16267d11a` | `git branch ci/198-round6 23c16267d11a63858aad23eab63c9fbfc385ef4b` |

<!-- subject: local:ci/198-gap-closure@ffcff0d1613381950cfb6baad93e90aee19dcece|archive/ci/198-gap-closure/local-ffcff0d16133|git branch ci/198-gap-closure ffcff0d1613381950cfb6baad93e90aee19dcece -->
<!-- subject: origin:ci/198-gap-closure@f748e43d7e4c1e63a0142569a55f57c7187e5cb1|archive/ci/198-gap-closure/origin-f748e43d7e4c|git branch ci/198-gap-closure f748e43d7e4c1e63a0142569a55f57c7187e5cb1 -->
<!-- subject: origin:ci/198-05-verify@d941ae1050c639121bdb5c1cc6fd8ea13e6cfafc|archive/ci/198-05-verify/origin-d941ae1050c6|git branch ci/198-05-verify d941ae1050c639121bdb5c1cc6fd8ea13e6cfafc -->
<!-- subject: origin:ci/198-round3@80bf701e7486962e538d16f213874cbba8f24115|archive/ci/198-round3/origin-80bf701e7486|git branch ci/198-round3 80bf701e7486962e538d16f213874cbba8f24115 -->
<!-- subject: origin:ci/198-round4@f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6|archive/ci/198-round4/origin-f433ef3ea6fd|git branch ci/198-round4 f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6 -->
<!-- subject: local:ci/198-round5@14f923a71c0901cd5f95fc3a72e0971b05861543|archive/ci/198-round5/local-14f923a71c09|git branch ci/198-round5 14f923a71c0901cd5f95fc3a72e0971b05861543 -->
<!-- subject: origin:ci/198-round5@14f923a71c0901cd5f95fc3a72e0971b05861543|archive/ci/198-round5/origin-14f923a71c09|git branch ci/198-round5 14f923a71c0901cd5f95fc3a72e0971b05861543 -->
<!-- subject: local:ci/198-round6@23c16267d11a63858aad23eab63c9fbfc385ef4b|archive/ci/198-round6/local-23c16267d11a|git branch ci/198-round6 23c16267d11a63858aad23eab63c9fbfc385ef4b -->
<!-- subject: origin:ci/198-round6@23c16267d11a63858aad23eab63c9fbfc385ef4b|archive/ci/198-round6/origin-23c16267d11a|git branch ci/198-round6 23c16267d11a63858aad23eab63c9fbfc385ef4b -->

Each packet's JSON evidence records ancestry against current HEAD and local `main`, ahead/behind
counts, unique commits, machine-readable numstat, PR identity/head/base/state, rationale, archive
tag, and exact restore command.

## Complete observed namespace

- Local: `ci/198-gap-closure`, `ci/198-round5`, `ci/198-round6`.
- Origin: `ci/198-05-verify`, `ci/198-gap-closure`, `ci/198-round3`, `ci/198-round4`,
  `ci/198-round5`, `ci/198-round6`.

All three local refs and all six origin refs are represented exactly once as side/SHA subjects.
The remote-only `ci/198-05-verify` packet records a null pull-request association rather than
inventing a PR. Shared-SHA local/origin handles remain separate preservation subjects because each
handle has its own retirement path and collision-free archive name.

## Plan 52 supersession

Plan 52 is preserved but superseded as inapplicable because Plan 51 recorded verbatim abort and proved the exact-three scope incomplete.

The Plan-51 abort, an ancestry recommendation, silence, and workflow auto-advance grant no branch,
pull-request, tag, `main`, ruleset, protection, or other mutation authority.

## Maintainer decision

**Status: undecided.** `decision` and `execution` are null and command receipts are empty. This
record offers evidence only and does not imply a choice.
