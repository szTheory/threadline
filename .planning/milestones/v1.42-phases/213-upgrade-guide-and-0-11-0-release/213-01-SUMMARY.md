---
phase: 213-upgrade-guide-and-0-11-0-release
plan: 01
subsystem: docs
tags: [changelog, exdoc, doc-contract, upgrade-guide, postgres-triggers]

requires:
  - phase: 210-pk-agnostic-capture
    provides: primary-key resolution, refused-type list, ArgumentError on bad history/as_of keys
  - phase: 211-read-side-agreement
    provides: row-history index, history/as_of semantics
  - phase: 212-detection-and-adopter-twins
    provides: trigger_findings/1 codes, trigger_coverage/1 disabled/replica rule
  - phase: 209-collision-free-emission
    provides: the shared-capture-function fix and its exact mechanism
provides:
  - guides/upgrading-to-0.11.md (six-step upgrade procedure, marker-wrapped backfill and rollback-cleanup SQL, D-04 facts)
  - CHANGELOG.md Security section for the shared-capture-function issue
  - guides/upgrade-path.md 0.10.x -> 0.11.x entry
  - doc-contract tests pinning all of the above
affects: [213-02 (extracts and executes the guide's marker-wrapped SQL against real PG), 213-03 (release lane, CHANGELOG retitle)]

actuals:
  tokens: 9300
  tasks: 3
  commits: 4
  plan_head_before: 46f662e3

tech-stack:
  added: []
  patterns:
    - "Doc-contract tests extract guide content by literal HTML-comment marker strings (String.split, no Markdown parser) rather than regex-parsing Markdown, matching the plan's own extraction contract for plan 213-02."
    - "Adopter-facing guide/CHANGELOG prose is written domain-first with zero phase/decision/requirement vocabulary, verified by a banned-shapes scan copied from release_artifact_contract_test.exs."

key-files:
  created:
    - guides/upgrading-to-0.11.md
    - test/threadline/upgrading_to_0_11_doc_contract_test.exs
  modified:
    - mix.exs
    - test/threadline/guide_graph_contract_test.exs
    - guides/getting-started-saas.md
    - guides/upgrade-path.md
    - test/threadline/upgrade_path_doc_contract_test.exs
    - README.md
    - CHANGELOG.md
    - test/threadline/changelog_contract_test.exs
    - test/threadline/public_surface_contract_test.exs

key-decisions:
  - "Guide's Step 1 describes bumping the :threadline dependency in prose, without an {:threadline, \"~> 0.11\"} Elixir tuple literal — that exact shape matches the version-truth Family A install-pin regex and mix release.pins's rewrite regex, both scoped to the CURRENT mix.exs @version (0.10.2); writing it literally would either fail the pin contract now or get silently rewritten back to ~> 0.10.0 by release.pins."
  - "Security note placed as its own ### Security heading directly before ### Breaking changes in CHANGELOG.md's Unreleased block, per the plan's placement instruction and Keep-a-Changelog-adjacent convention; no existing repo precedent for this heading, so this is the first one."
  - "New guide's backfill batch pattern documents idempotence and safe-to-rerun/overlap semantics from the plan's live-verified RESEARCH.md properties, without re-deriving them independently."

requirements-completed: []

coverage:
  - id: D1
    description: "Adopter-facing guides/upgrading-to-0.11.md exists, is registered in mix.exs ExDoc extras + Adopt lane, the 19-node guide graph, and routed from the Adopt landing (getting-started-saas.md)"
    verification:
      - kind: unit
        ref: "test/threadline/upgrading_to_0_11_doc_contract_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/guide_graph_contract_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/release_artifact_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Guide documents the six-step upgrade procedure (bump deps, regenerate triggers together for shared-function pairs, migrate, row-history index, verify coverage with finding-code fix table, optional backfill) in the dependency-forced order"
    verification:
      - kind: unit
        ref: "test/threadline/upgrading_to_0_11_doc_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Marker-wrapped, guarded, idempotent backfill SQL (single-column and composite) and rollback-cleanup SQL, using the text (->>) arrow only, with unrecoverable rows (DELETE, redacted keys) explicitly named"
    verification:
      - kind: unit
        ref: "test/threadline/upgrading_to_0_11_doc_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "guides/upgrade-path.md carries the required 0.10.x -> 0.11.x per-minor entry linking the new guide; README.md links it from the Adopt list"
    verification:
      - kind: unit
        ref: "test/threadline/upgrade_path_doc_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "CHANGELOG.md's Unreleased block carries an accurate ### Security section (detection, fix, rows-already-captured statement) for the shared-capture-function issue, positioned before the feature tour"
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
    human_judgment: true
    rationale: "Security note wording accuracy against the 209 mechanism was checked against source (trigger_findings.ex, legacy_function_upgrade_test.exs moduledoc, gen.triggers moduledoc) during authoring, but an incidence/overstatement judgment call benefits from a second read before this ships in a public release."
  - id: D6
    description: "No shipped prose added by this plan contains phase numbers, decision IDs, requirement IDs, or milestone literals"
    verification:
      - kind: unit
        ref: "test/threadline/upgrading_to_0_11_doc_contract_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/release_artifact_contract_test.exs"
        status: pass
    human_judgment: false

duration: 1h5min
completed: 2026-09-26
status: complete
---

# Phase 213 Plan 01: Upgrade Guide and 0.11.0 Release Summary

**New guides/upgrading-to-0.11.md ships the full 0.10.x -> 0.11.0 procedure with marker-wrapped, live-SQL-verified backfill and rollback-cleanup blocks, registered in all three guide-graph enforcement points, plus a new CHANGELOG Security section disclosing the phase-209 shared-capture-function issue accurately.**

## Performance

- **Duration:** ~1h5min
- **Started:** 2026-09-26T~12:10Z
- **Completed:** 2026-09-26T13:16:04Z
- **Tasks:** 3
- **Files modified:** 11 (2 created, 9 modified)

## Accomplishments
- `guides/upgrading-to-0.11.md`: twelve locked `##` sections covering the dependency-forced six-step procedure, a finding-code fix table, marker-wrapped single-column and composite backfill SQL, a marker-wrapped rollback-cleanup `DO $$` block, and every D-04 adopter fact
- Registered the new guide in `mix.exs` ExDoc extras + Adopt regex, the guide-graph contract's Adopt lane (node count 18 -> 19), and routed it from the Adopt landing (`getting-started-saas.md`)
- `guides/upgrade-path.md` gained the required `0.10.x -> 0.11.x` per-minor entry linking the new guide (satisfies version-truth Family C once `@version` moves to 0.11.x)
- `CHANGELOG.md`'s Unreleased block gained a `### Security` section, placed before `### Breaking changes`, stating impact, that already-captured rows are not rewritten, detection (`mix threadline.health.coverage`), and the fix
- Five doc-contract test files extended or created, all pinning the new content, with a banned-vocabulary scan (phase/decision/requirement/milestone literals) copied from `release_artifact_contract_test.exs`

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): register the guide end to end** - `3526b023` (feat)
2. **Task 2: backfill SQL, D-04 facts, rollback cleanup, upgrade-path entry** - `e97a84e6` (feat)
3. **Task 3: CHANGELOG security note** - `f8063e36` (feat)

**Plan metadata:** (this commit, docs)

## Files Created/Modified
- `guides/upgrading-to-0.11.md` - New satellite upgrade guide (twelve sections, backfill/rollback SQL)
- `test/threadline/upgrading_to_0_11_doc_contract_test.exs` - New doc contract pinning headings, commands, markers, D-04 facts, vocabulary hygiene
- `mix.exs` - ExDoc extras + Adopt regex registration
- `test/threadline/guide_graph_contract_test.exs` - Adopt lane + node-count bump (18 -> 19)
- `guides/getting-started-saas.md` - Adopt landing routes to the new guide
- `guides/upgrade-path.md` - `0.10.x -> 0.11.x` per-minor entry + at-a-glance row
- `test/threadline/upgrade_path_doc_contract_test.exs` - Pins the new entry and link
- `README.md` - Adopt guide list link
- `CHANGELOG.md` - `### Security` section under Unreleased
- `test/threadline/changelog_contract_test.exs` - Pins the Security section's position and content, keyed on the `0.11.0` block by heading (dated or standing Unreleased), not on "newest"
- `test/threadline/public_surface_contract_test.exs` - Local-extra ownership list/count fix (Rule 3, see Deviations)

## Decisions Made
- Wrote the dependency-bump instruction in prose rather than an `{:threadline, "~> 0.11"}` literal, to avoid colliding with `version_truth_doc_contract_test.exs` Family A (which requires every such literal to equal the CURRENT `@version`-derived pin, `~> 0.10.0`, until release) and with `mix release.pins`'s identical rewrite regex, which would otherwise silently flip the guide's forward-looking pin back to the current one.
- Placed the Security section as the first subsection under `## Unreleased -- highlights`, before `### Breaking changes`, per the plan's instruction; there was no existing repo precedent for a `### Security` heading to match against.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Guide's regenerate-together sentence had a line-wrap that broke the pinned literal**
- **Found during:** Task 1, first test run
- **Issue:** The bolded together-regeneration sentence wrapped across a markdown line break, turning the required space into a newline and breaking the doc-contract's exact-substring assertion.
- **Fix:** Kept the sentence on one line.
- **Files modified:** `guides/upgrading-to-0.11.md`
- **Committed in:** `3526b023` (part of Task 1 commit)

**2. [Rule 3 - Blocking] Guide's Step 1 install-pin literal broke version-truth Family A**
- **Found during:** Task 2, full targeted test run
- **Issue:** `{:threadline, "~> 0.11"}` in the guide matched `version_truth_doc_contract_test.exs`'s install-pin regex, which asserts every such literal across README + guides equals the CURRENT `@version`-derived pin (`~> 0.10.0` while `@version` is `0.10.2`). It would also have been silently rewritten back to `~> 0.10.0` by `mix release.pins`, corrupting the forward-looking instruction.
- **Fix:** Rewrote Step 1 as prose ("Raise your host `mix.exs` `:threadline` requirement so it resolves to the `0.11` line...") without the matched tuple literal.
- **Files modified:** `guides/upgrading-to-0.11.md`
- **Committed in:** `e97a84e6` (part of Task 2 commit)

**3. [Rule 3 - Blocking] Pre-existing `public_surface_contract_test.exs` broke by the new guide**
- **Found during:** Full `mix test` run before the final metadata commit
- **Issue:** `test/threadline/public_surface_contract_test.exs`'s `@local_reference_owners` map and its `length(local) == 22` assertion hard-code every ExDoc local extra; the new guide added a 23rd extra with no owner entry, failing "all local, external, and module-doc subjects have one exact owner."
- **Fix:** Added `guides/upgrading-to-0.11.md` to `public_doc_refs_adopt_core` (alongside `upgrade-path.md`) and bumped the count assertion to 23.
- **Files modified:** `test/threadline/public_surface_contract_test.exs`
- **Verification:** `mix test test/threadline/public_surface_contract_test.exs` (38 tests, 0 failures), then the full `mix test` suite (2203 tests, 0 failures)
- **Committed in:** `f8063e36` (part of Task 3 commit)

---

**Total deviations:** 3 auto-fixed (1 bug, 2 blocking)
**Impact on plan:** All three were necessary to keep the guide's content correct and the pre-existing test suite green. No scope creep — no new production code or features beyond what the plan specified.

## Issues Encountered
None beyond the deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `guides/upgrading-to-0.11.md`'s marker-wrapped backfill and rollback-cleanup SQL blocks are ready for plan 213-02 to extract (by the same literal marker strings) and execute against a real-PG fixture.
- REL-02 stays unticked in `REQUIREMENTS.md` per the dispatch instruction; 213-02 provides the real-PG proof that completes it.
- `guides/upgrade-path.md`'s `0.10.x -> 0.11.x` entry is in place now, ahead of release-please's version bump, so the release PR born-red risk (Pitfall 5 in 213-RESEARCH.md) is pre-empted.
- Full `mix test` suite: 2203 tests, 0 failures (confirmed after all three tasks, on this plan's final tree).

---
*Phase: 213-upgrade-guide-and-0-11-0-release*
*Completed: 2026-09-26*

## Self-Check: PASSED
All claimed files (`guides/upgrading-to-0.11.md`, `test/threadline/upgrading_to_0_11_doc_contract_test.exs`) and task commit hashes (`3526b023`, `e97a84e6`, `f8063e36`) verified present.
