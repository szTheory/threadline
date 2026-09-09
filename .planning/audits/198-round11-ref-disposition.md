# Phase 198 Round 11 ref disposition

Observed read-only at `2026-09-09T21:50:00Z` for `szTheory/threadline`.

<!-- schema: phase198-ref-disposition/v2; round: 11 -->
<!-- inventory-sha256: 0fa62da0b11e2150ec47b1c8dcc2ce318e2c4a9aa7dd74a4a8f71766b4635446 -->
<!-- controls: a97f527e375f4c1909236b7dbdd5fa3fd9b7d2f2|34|46213f9bc0ecbff356058d317c882d5a643ae86f|1040e93d8ae5e79672757f6acbfaeae1e7cb27c6db2d01cb7483c081fd94dcc4|f02c07a558af08ef0d048996463adb29c61dcffd28c940b6562356f2293efcc3|5253096fa066c0e3507f2a91e5a76ef2217191b63d76c90d6344ca2300ac5c1a -->

## Tracer preservation packets

The divergent `ci/198-gap-closure` name contains two different objects. They are separate
preservation subjects and receive non-colliding archive paths; branch-name equality is not object
identity.

| Subject | Side | Full SHA | PR | Archive tag | Restore command |
|---|---|---|---:|---|---|
| `local:ci/198-gap-closure@ffcff0d1613381950cfb6baad93e90aee19dcece` | local | `ffcff0d1613381950cfb6baad93e90aee19dcece` | #29 | `archive/ci/198-gap-closure/local-ffcff0d16133` | `git branch ci/198-gap-closure ffcff0d1613381950cfb6baad93e90aee19dcece` |
| `origin:ci/198-gap-closure@f748e43d7e4c1e63a0142569a55f57c7187e5cb1` | origin | `f748e43d7e4c1e63a0142569a55f57c7187e5cb1` | #29 | `archive/ci/198-gap-closure/origin-f748e43d7e4c` | `git branch ci/198-gap-closure f748e43d7e4c1e63a0142569a55f57c7187e5cb1` |

<!-- subject: local:ci/198-gap-closure@ffcff0d1613381950cfb6baad93e90aee19dcece|archive/ci/198-gap-closure/local-ffcff0d16133|git branch ci/198-gap-closure ffcff0d1613381950cfb6baad93e90aee19dcece -->
<!-- subject: origin:ci/198-gap-closure@f748e43d7e4c1e63a0142569a55f57c7187e5cb1|archive/ci/198-gap-closure/origin-f748e43d7e4c|git branch ci/198-gap-closure f748e43d7e4c1e63a0142569a55f57c7187e5cb1 -->

Each packet's JSON evidence records ancestry against current HEAD and local `main`, ahead/behind
counts, unique commits, machine-readable numstat, PR identity/head/base/state, rationale, archive
tag, and exact restore command.

## Complete observed namespace

- Local: `ci/198-gap-closure`, `ci/198-round5`, `ci/198-round6`.
- Origin: `ci/198-05-verify`, `ci/198-gap-closure`, `ci/198-round3`, `ci/198-round4`,
  `ci/198-round5`, `ci/198-round6`.

Task 1 intentionally traces the divergent name first; Task 2 expands one packet per remaining
side/SHA subject without changing this complete live-universe observation.

## Plan 52 supersession

Plan 52 is preserved but superseded as inapplicable because Plan 51 recorded verbatim abort and proved the exact-three scope incomplete.

The Plan-51 abort, an ancestry recommendation, silence, and workflow auto-advance grant no branch,
pull-request, tag, `main`, ruleset, protection, or other mutation authority.

## Maintainer decision

**Status: undecided.** `decision` and `execution` are null and command receipts are empty. This
record offers evidence only and does not imply a choice.
