# Phase 202 — measured release blockers (2026-09-22)

Produced before planning, by simulating the 0.10.0 bump locally rather than
reasoning about it: `@version` was temporarily set to `0.10.0` and the version
and release-artifact contracts were run against the real tree.

## What PR #26 is actually failing on

PR #26 (`chore(main): release 0.10.0`, open since 2026-06-26) is **born red**, not
stale-red. Its last CI run (`34759027709`, 2026-09-13) reported three failures.
Re-measured at current HEAD under a simulated bump:

| Failure | Status now | Cause |
|---|---|---|
| `VersionTruthDocContractTest` — install pins | **REAL** | 6 pins across README + 5 guides still read `~> 0.9.0`; the bump makes the derived pin `~> 0.10.0` |
| `VersionTruthDocContractTest` — upgrade coverage | **REAL** | `guides/upgrade-path.md` has no `0.9.x -> 0.10.x` row |
| `ReleaseArtifactContractTest` — planning vocabulary | **STALE — now passes** | Fixed by the Phase 200 vocabulary sweep, which landed after that CI run |

The two real failures are structural: both files must change **in the same commit
as the `mix.exs` bump**, or the release PR is red the moment it is opened.

## The trap in the obvious fix

Success Criterion 2 says every version-bearing line is "managed by release
automation, so a version bump requires no hand edits". The obvious implementation
— add `<!-- x-release-please-version -->` to the six pin lines and register their
files in `extra-files` — **is wrong, and would reintroduce born-red on the next
patch release.**

`version_truth_doc_contract_test.exs` derives the expected pin as
`major.minor.**0**` on purpose:

> a tight `.0` derivation keeps patch releases green by construction
> because `~> 0.9.0` covers all of 0.9.x

release-please's generic updater writes the **full** version onto a marked line.
So for a 0.10.1 patch release it would write `{:threadline, "~> 0.10.1"}` while
the contract still derives `~> 0.10.0` — red again, and additionally wrong for
adopters, since `~> 0.10.1` does not admit 0.10.0.

**A pin line must bump on minor/major releases and hold still on patch
releases.** The generic updater has no such mode. Planning must resolve this
rather than assume the marker works; candidate directions, none yet evaluated:

- component markers (`x-release-please-major` / `-minor`) if they can target the
  right digits inside a compound `~> x.y.z` string
- a custom release-please updater
- generating the pins from `@version` at doc-build time so no literal exists
- narrowing SC2 to "no hand edits **for patch releases**" and accepting a scripted
  minor-release step, with the contract as the enforcement

## Not automatable, and it should not be

The `0.9.x -> 0.10.x` upgrade row is adopter-facing prose stating what a user must
do when crossing the minor. It cannot be generated from a version number. Note the
contract accepts "nothing required" as a valid answer — but whether that is TRUE
for 0.10.0 is a judgement over everything since Phase 180 and must be established,
not assumed.

## Verified adjacent facts

- The merge base is fine: `gh pr view 26` reports the PR open with one commit; its
  redness is content, not conflict.
- `.release-please-manifest.json` is `0.9.0`; `mix.exs` `@version` is `0.9.0`.
- `extra-files` currently registers only `guides/adoption-pilot-backlog.md` and
  `guides/evaluating-threadline.md`, whose markers sit on prose lines, not pins.
- hex.pm has no undo. This phase's dependency note already says publish only once;
  the born-red analysis above is the cheap part to get wrong first.
