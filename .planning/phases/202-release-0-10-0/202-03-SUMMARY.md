---
phase: 202-release-0-10-0
plan: 03
subsystem: infra
tags: [release, changelog, release-please, hex, documentation, doc-contract]

requires:
  - phase: 202-release-0-10-0
    provides: "Plan 01's storage-schema default flip to `public`, proven non-breaking end-to-end — the fact that makes the 0.10.0 entry's no-breaking-changes claim true rather than asserted"
  - phase: 200-public-surface
    provides: the documented public surface the 0.10.0 entry describes
  - phase: 201-operator-surface
    provides: the two new operator-surface routes the 0.10.x upgrade row documents
provides:
  - "`CHANGELOG-GENERATED.md` — a bot-owned, package-excluded changelog that release-please now writes to instead of the shipped file"
  - "a human-owned `CHANGELOG.md` with a dated 0.10.0 entry that answers breaking changes and required action before the feature tour"
  - "`Threadline.ChangelogContractTest` — the changelog shape and the ownership split under test, with three reproduced failure modes"
  - "a `0.9.x -> 0.10.x` upgrade row enumerating the four remaining adopter actions in wording byte-identical to the changelog entry"
  - "an upgrade guide that states the current storage-schema truth in all three places it appeared"
affects: [202-04 release.yml wiring, 202-05 publish gate, future release entries]

actuals:
  tokens: 8041
  tasks: 3
  commits: 3
  plan_head_before: 8dfb685d270baabfd5c000a0785947b2ff4f3fe4

tech-stack:
  added: []
  patterns:
    - "Ownership split by FILE rather than by convention inside one file: the bot and the human own different paths, so the adjacency case cannot recur through forgetfulness"
    - "Contract tests that assert a non-empty subject list BEFORE asserting anything about a subject, so a pattern that stops matching fails loudly instead of passing vacuously"
    - "Entry-scoped assertions: structural contracts apply to the newest entry only, so a new rule cannot retroactively invalidate published history"

key-files:
  created:
    - CHANGELOG-GENERATED.md
    - test/threadline/changelog_contract_test.exs
  modified:
    - CHANGELOG.md
    - release-please-config.json
    - guides/upgrade-path.md

key-decisions:
  - "release-please's `changelog-path` now names CHANGELOG-GENERATED.md; CHANGELOG.md is fully human-owned and is the file shipped in the tarball"
  - "Published history stays put: earlier bot-written entries remain in CHANGELOG.md because their compare and commit links are what adopters have followed; the generated file is seeded empty-but-headed and accumulates from 0.10.0"
  - "The standing highlights heading is unbracketed (`## Unreleased — highlights`) because the bracket collides with release automation's version-header pattern"
  - "The changelog contract scopes its entry-body assertions to the newest dated entry only, so historical entries are not retroactively invalidated"
  - "The four adopter actions are byte-identical in the changelog and the upgrade guide, verified by a normalized diff rather than by reading"
  - "The stale hex-evaluator prose inherited from 202-02 stays deferred: the false sentences are 2 of the 6 install-pin sites, so correcting them is a release-tooling change, not a documentation edit"

patterns-established:
  - "File-scoped automation ownership, documented in a header comment at the top of BOTH files, following bin/post-publish-distribution-sync's convention"
  - "Changelog section order as an enforced invariant: breaking changes and required action above the feature tour, compared by character offset in a test"

requirements-completed: [RELEASE-04]

coverage:
  - id: D1
    description: "release-please writes to CHANGELOG-GENERATED.md and has no claim on the shipped CHANGELOG.md; the generated file is absent from the tarball and from HexDocs."
    requirement: "RELEASE-04"
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs#release-please owns the generated changelog and has no claim on the human one"
        status: pass
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs#the bot-owned generated changelog is never adopter surface (mix hex.build --unpack)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The 0.10.0 entry leads with human prose, then breaking changes and required action, then the storage-schema default, then the feature tour — and an entry with no human highlights fails rather than passing silently."
    requirement: "RELEASE-04"
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs#the newest release entry opens with human-written highlights"
        status: pass
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs#the newest release entry answers breaking changes and required action before the feature tour"
        status: pass
      - kind: unit
        ref: "reproduced regressions: highlights removed, feature tour moved above breaking changes, bracketed unreleased heading reintroduced — each observed failing, each reverted"
        status: pass
    human_judgment: false
  - id: D3
    description: "No bracketed unreleased-style heading survives anywhere in CHANGELOG.md, and the dated 0.10.0 heading matches a shape bin/verify-release-shape accepts."
    requirement: "RELEASE-04"
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs#no bracketed unreleased-style heading exists anywhere in the human changelog"
        status: pass
      - kind: other
        ref: "bash bin/verify-release-shape (exit 0); heading regex run by hand against CHANGELOG.md yields exactly 1 match for 0.10.0"
        status: pass
    human_judgment: false
  - id: D4
    description: "The upgrade guide states the current storage-schema truth in all three places it appeared, and attributes the no-action outcome to the 0.10.0 change rather than to the 0.6-0.9 era."
    requirement: "RELEASE-04"
    verification:
      - kind: unit
        ref: "test/threadline/upgrade_path_doc_contract_test.exs (17 tests with version_truth, 0 failures)"
        status: pass
      - kind: other
        ref: "grep -nE 'storage.schema|storage_schema' guides/upgrade-path.md — all 7 hits read the current truth; no sentence states the dedicated schema is the default"
        status: pass
    human_judgment: false
  - id: D5
    description: "The 0.9.x -> 0.10.x upgrade row and the 0.10.0 changelog entry enumerate the same four adopter actions in identical words, and Family C of the version-truth contract passes under a simulated next-minor version."
    requirement: "RELEASE-04"
    verification:
      - kind: unit
        ref: "normalized side-by-side diff of the four bullets across CHANGELOG.md and guides/upgrade-path.md — all four identical"
        status: pass
      - kind: unit
        ref: "simulated @version 0.10.0: test upgrade-path.md documents the current-minor coverage 0.9.x -> 0.10.x [L#143] passed"
        status: pass
    human_judgment: false
  - id: D6
    description: "The published tarball's Changelog link resolves to the human-owned file for 0.10.0 and every later version."
    verification: []
    human_judgment: true
    rationale: "Provable only against a published package. Pre-publish evidence is mix.exs's package `links` value plus Plan 02's archive containment assertion, both of which hold; the live claim cannot be verified until 202-05 publishes."

duration: 40 min
completed: 2026-09-22
status: complete
---

# Phase 202 Plan 03: Changelog ownership split and the 0.10.0 entry Summary

**release-please no longer writes the changelog adopters read: its `changelog-path` now names a package-excluded `CHANGELOG-GENERATED.md`, `CHANGELOG.md` became human-owned with a dated 0.10.0 entry that answers "will this break me" and "what must I do" before the feature tour, and a new contract test — proven to fail on all three regressions it guards — keeps that shape and that split from drifting back.**

## Performance

- **Duration:** 40 min
- **Started:** 2026-09-22T14:20:18Z
- **Completed:** 2026-09-22T15:00:21Z
- **Tasks:** 3
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments

- **The vocabulary leak is now structurally impossible, not merely unlikely.** 40 of the 317 releasable subjects since `v0.9.0` trip the archive contract's regexes. Changing one key — `changelog-path` — moves all of them into a file that is absent from `package[:files]`, absent from `docs[:extras]`, and asserted absent from the built archive. History being immutable no longer matters, because the immutable history never reaches the shipped file.
- **The 0.10.0 entry can say "breaking changes: none" honestly.** Zero breaking-change footers and zero bang subjects across the releasable commits, plus Plan 01's end-to-end proof that a 0.9.x-shaped `public`-schema install reads green. The entry says so in those terms rather than asserting it.
- **The four remaining adopter actions are enumerated, not summarized, and are byte-identical across both documents.** Verified by a whitespace-normalized diff, not by reading. An adopter who reads the changelog and the upgrade guide has nothing to reconcile.
- **The upgrade guide stopped misattributing the storage-schema outcome.** All three places that framed the dedicated schema as the default — the era table's row, the migration-expectation section, and the separate `table_schema` paragraph — now state the current truth, and the no-action-required outcome is attributed to the 0.10.0 change.
- **The contract test was proven to fail before it was trusted.** Each of the three regressions it guards was reproduced in the working tree, observed failing with the intended message, and reverted.

## Task Commits

1. **Task 1: Confirm the changelog file-ownership split** — no commit (decision checkpoint; see below)
2. **Task 2: Split changelog ownership and write the 0.10.0 entry** — `291d061a` (docs)
3. **Task 3: Enforce the changelog shape and re-scope the upgrade path** — `c35cb0dc` (test)

**Plan metadata:** the `docs(202-03)` commit carrying this SUMMARY, STATE.md, ROADMAP.md, and REQUIREMENTS.md.

`commits: 3` is measured with `git rev-list --count 8dfb685d..HEAD`, which reports `2` before the metadata commit and `3` after it. The frontmatter records the post-commit value so `/gsd-verify-work` reads the same number from the same instrument.

## Task 1 — decision record

**Confirmation:** auto-approved at **2026-09-22T14:20:18Z**.

The task is a `checkpoint:decision` carrying the default `gate="blocking"`, and auto mode is active (`.planning/config.json`: `mode: yolo`, `workflow.auto_advance: true`). Per the checkpoint protocol the first option is selected, and the planner front-loads the recommended choice: **"Proceed with the file split (the locked D-11 decision)."** The alternative was to halt and re-open the decision with the maintainer.

This is recorded as an auto-selection rather than as a maintainer confirmation, because that is what it was. The task's `<reversibility rating="costly">` was not overridden by a human at the point of execution; it was taken on the strength of the decision already being locked in the phase context. If the maintainer wants a human signature on this specific split before publish, the place to put it is the `production-hex` environment approval, which is the one irreversibility gate a human still owns.

## Files Created/Modified

- `CHANGELOG-GENERATED.md` (new) — bot-owned, title plus an ownership header block written in `bin/post-publish-distribution-sync`'s convention: names release-please as sole owner, names `CHANGELOG.md` as the file adopters read, records that this file is deliberately absent from the package and from HexDocs, and records that generated notes begin at 0.10.0 because earlier generated bodies stay in the human file as published history. Contains no release entry.
- `release-please-config.json` — exactly one value changed: `changelog-path` from `CHANGELOG.md` to `CHANGELOG-GENERATED.md`. `changelog-sections`, `include-v-in-tag`, and `extra-files` untouched; the human changelog's filename appears nowhere in the file.
- `CHANGELOG.md` — ownership comment under the title, the unbracketed standing `## Unreleased — highlights` heading, then the dated `## [0.10.0] - 2026-09-22` entry; the orphaned bracketed block (13 lines, stranded between the 0.7.0 and 0.6.0 entries) deleted from that position and its content folded into the 0.10.0 feature tour.
- `test/threadline/changelog_contract_test.exs` (new) — `Threadline.ChangelogContractTest`, 7 tests, `use ExUnit.Case, async: true`, `@root File.cwd!()`, files read at test time.
- `guides/upgrade-path.md` — three storage-schema statements rewritten, one intro sentence re-scoped, a `0.9.x → 0.10.x` per-minor bullet with the four actions, and a matching at-a-glance row.

## The folded module list: NOT the same enumeration (measured)

The plan required this to be checked rather than assumed. `202-RESEARCH.md` logged it as assumption A3 — that the orphaned block's list and the "~23 modules" figure are the same set.

**They are not.** Measured by comparing `@moduledoc false` presence per file between `v0.9.0` and `HEAD` across `git ls-files 'lib/**/*.ex'`:

- **25** modules that existed at `v0.9.0` with no `@moduledoc false` now carry one.
- The orphaned block enumerated **23** of them — all 12 capture/lifecycle entries and 11 of the 13 operator entries.
- **Two were missing** from the block: `Threadline.OperatorSurface.Live.ActorLive` and `Threadline.OperatorSurface.Live.TransactionLive`. Both had no `@moduledoc` at all at `v0.9.0` (so they were documented) and carry `@moduledoc false` today, verified by reading both revisions of each file.

The 0.10.0 entry therefore ships the **complete list of 25**, not the folded 23, and the required-action bullet says 25. The "~23" figure in the phase context was an undercount by two, not a different set — the block's list is a strict subset of the measured one.

## Family C under a simulated next-minor version

The second of the two measured born-red causes. With `@version` temporarily set to `0.10.0` and `mix release.pins` run once:

```
release.pins: scanned 20 file(s); 6 pin site(s) differ from the derived pin
release.pins: rewrote 6 file(s).

  * test upgrade-path.md documents the current-minor coverage 0.9.x -> 0.10.x [L#143] (0.09ms)
```

Family C **passes**. `@version` and all six rewritten pin files were restored before commit (`git status --short` confirmed no residue).

One test in that file did fail under the simulation, and it is not this plan's cause:

```
1) test every x-release-please-version marked line carries @version and is wired into release-please
   guides/adoption-pilot-backlog.md has an x-release-please-version marked line that does not
   contain the current @version 0.10.0.
```

That is Family B, and the failure is an artifact of the simulation rather than a born-red cause. Those marked lines are owned by release-please and are rewritten **in the release commit** via `extra-files`; a local `@version` edit changes the version without triggering the bot that bumps them. `guides/adoption-pilot-backlog.md` was not touched by this plan. The honest reading is that Family B is green by construction only on a real release commit, and cannot be proven locally by editing `@version` alone.

## Reproduced regressions — the three observed failure messages

Each was injected into the working tree, run, and reverted. `git diff --stat CHANGELOG.md` was empty afterwards.

**1. Human highlights removed from the newest entry:**

```
the newest release entry (## [0.10.0] - 2026-09-22) has no prose between its heading and its
first subsection. A release entry with no human highlights is a failure, not a no-op: the file
that ships in the Hex tarball would open the newest release with a bare section list. Write a
sentence an upgrader can read.
```

**2. Feature tour moved above the breaking-changes section:**

```
the newest release entry puts its feature tour (offset 271) above its breaking-changes /
required-action section (offset 2961). An upgrader's first two questions are "will this break
me" and "what must I do"; answering them after the feature list answers them too late. Move the
breaking-changes and required-action sections above the feature tour.
```

**3. Bracketed unreleased heading reintroduced:**

```
CHANGELOG.md contains a bracketed unreleased-style heading. The bracket is the problem:
release-please's version-header pattern matches on it, so the block is read as a release rather
than as a staging area. Use the unbracketed standing form (`## Unreleased — highlights`) instead.
```

## Verification

| Check | Result |
|---|---|
| `mix test test/threadline/changelog_contract_test.exs` | 7 tests, 0 failures |
| `mix verify.doc_contract` | 134 tests, 0 failures |
| `mix test release_artifact + upgrade_path + version_truth + changelog contracts` | 43 tests, 0 failures |
| `mix test adoption_pilot + guide_graph + public_surface + release_distribution contracts` | 52 tests, 0 failures |
| `bash bin/verify-release-shape` | exit 0 — `Release shape OK for version 0.9.0` |
| 0.10.0 heading vs the `verify-release-shape` regex, run by hand | exactly 1 match |
| Four adopter actions, normalized diff across both documents | all four identical |

`bin/verify-release-shape` asserts a dated heading for the CURRENT `@version` (0.9.0), so at an unbumped version it proves the pre-existing heading still validates and the file was not structurally broken. It does not yet exercise the 0.10.0 heading; the hand-run regex above covers that gap until the bump lands.

## Decisions Made

- **Section order made explicit rather than implied.** The entry uses named `### Breaking changes`, `### Required action`, `### Storage schema default`, `### Added`, `### Changed` headings so the contract can compare character offsets between two named section families rather than guessing at prose structure.
- **The generated-bullet refutation is shape-based, not vocabulary-based.** The contract looks for release-please's commit-link bullet shape (`* subject ([shortsha](…/commit/…))`), not for planning vocabulary — the archive contract already owns vocabulary, and a shape check catches generated drift even when the subjects happen to be clean.
- **`### Added`/`### Changed` and `### Features`/`### Bug Fixes` are both treated as feature-tour sections.** The second pair is release-please's own section vocabulary, so an entry that regains generated headings still trips the ordering rule.
- **The changelog bullet's internal cross-reference was dropped** so the four actions are byte-identical rather than merely equivalent. The pointer it carried ("see Documented surface below") pointed two sections down in the same entry and cost more than it bought.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Two Elixir sigil syntax errors in the new contract test**

- **Found during:** Task 3 (first compile of `changelog_contract_test.exs`)
- **Issue:** `~r{…{7,}…}` closed the sigil on the quantifier's brace, and `~r/^#{1,6}…/` was parsed as string interpolation rather than as a literal `#` repeated 1-6 times. Both were compile errors, so the module asserted nothing.
- **Fix:** switched the first to `~r/…/` with escaped forward slashes; escaped the `#` in the second (`~r/^\#{1,6}…/`).
- **Files modified:** `test/threadline/changelog_contract_test.exs`
- **Verification:** module compiles; 7 tests, 0 failures; all three injected regressions observed failing, which proves the regexes match what they claim to.
- **Committed in:** `c35cb0dc` (part of the Task 3 commit)

**2. [Rule 2 - Missing Critical] The 0.10.0 entry ships 25 modules, not the folded 23**

- **Found during:** Task 2 (the plan-mandated diff of the folded module list)
- **Issue:** the orphaned block's enumeration is two modules short of the measured set. Shipping the folded list verbatim would have told adopters that two modules they may be calling are still a supported surface.
- **Fix:** measured the full set from `git ls-files` against `v0.9.0`, added `Threadline.OperatorSurface.Live.ActorLive` and `Threadline.OperatorSurface.Live.TransactionLive`, and wrote 25 in the required-action bullet.
- **Files modified:** `CHANGELOG.md`, `guides/upgrade-path.md`
- **Verification:** both revisions of both files read directly; the measured count of 25 reproduced from the file list.
- **Committed in:** `291d061a` and `c35cb0dc`

**3. [Rule 1 - Bug] The era table claimed a storage-schema default for an era that had no such seam**

- **Found during:** Task 3 (re-scoping the guide)
- **Issue:** the plan anticipated misattribution — the 0.6-0.9 era framed as having settled the storage-schema question. The actual state was worse: `storage_schema` does not exist at `v0.9.0` at all (`git grep -l storage_schema v0.9.0` returns nothing), so the era table described a default that never shipped in that era.
- **Fix:** the era row now says the seam does not exist before 0.10.0 and points at the 0.9.x → 0.10.x bullet; the migration-expectation row was corrected the same way.
- **Files modified:** `guides/upgrade-path.md`
- **Verification:** `git grep -l "storage_schema" v0.9.0` → no output; `mix test upgrade_path_doc_contract_test.exs` green.
- **Committed in:** `c35cb0dc`

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical)
**Impact on plan:** none widened scope. Two were correctness fixes inside the plan's own files; the third made a test that would otherwise have compiled to nothing actually run. No architectural decision was taken.

## Deferred Issues

**The stale hex-evaluator prose inherited from 202-02 stays deferred.** The orchestrator flagged it for a scope judgment; the judgment is recorded in `deferred-items.md` with its newly measured reason. Short version: the two false sentences are 2 of the 6 install-pin sites `mix release.pins` rewrites, so correcting them truthfully means removing a pin literal and re-measuring the pin inventory — release-tooling work, outside this plan's file list, and not something to do as a side effect of a changelog plan. Owner reassigned to a follow-up with `mix release.pins` in scope.

**The `CriticTrustTest` full-suite intermittent** is untouched and still open. This plan runs no test that reaches it.

## Issues Encountered

- **Family B cannot be proven locally under a simulated bump.** Documented above rather than worked around. It is a property of the simulation, not of the tree.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Ready for 202-04.** The changelog half of the born-red PR is closed: merging the release PR now writes to `CHANGELOG-GENERATED.md`, which no contract scans and no tarball carries.
- **One thing 202-04/05 must not undo:** `release-please-config.json`'s `changelog-path`. It is the single key granting the bot write access to a changelog, and the new contract fails if it is pointed back — but a contract only fails if someone runs it, so the publish gate is the place to be sure it does.
- **At the bump, re-run `bin/verify-release-shape`.** It will then exercise the 0.10.0 heading for real rather than the 0.9.0 one; the heading was hand-checked against its regex but has not been through the gate at a matching `@version`.
- **The standing `## Unreleased — highlights` block is empty and waiting.** The convention only holds if the next phase to land adopter-visible work writes into it.

## Self-Check: PASSED

All five key files verified present on disk. Both task commits (`291d061a`, `c35cb0dc`) verified present in `git log --oneline --all`.

---
*Phase: 202-release-0-10-0*
*Completed: 2026-09-22*
