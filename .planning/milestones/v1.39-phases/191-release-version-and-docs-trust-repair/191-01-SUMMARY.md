---
phase: 191-release-version-and-docs-trust-repair
plan: 01
subsystem: docs
tags: [upgrade-path, changelog, semver, backport, storage-schema, doc-contract]

# Dependency graph
requires:
  - phase: 190-storage-schema-confidence-and-host-schema-truth
    provides: storage_schema freeze-at-generation decision (D-190-14) phrased in the upgrade guide
provides:
  - upgrade-path.md coverage of the 0.6.x->0.9.x adopter era across four ADOPT-02 themes
  - per-minor at-a-glance spine (0.6->0.7, 0.7->0.8, 0.8->0.9) with mandatory nothing-required callouts
  - storage-schema freeze-at-generation migration expectation, distinct from host table_schema
  - CHANGELOG-vs-upgrade-path division-of-labor note
  - D-191-02a backport-policy sentence in both upgrade-path.md and CONTRIBUTING.md
  - extended structural doc-contract guard (theme axis + per-minor + nothing-required + refuted tokens)
affects: [191-02, 191-03, version_truth_doc_contract, adopter-docs-routing]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hybrid upgrade-guide shape: theme orientation table + per-minor spine table + bounded per-bump bullets"
    - "Structural doc-contract guard owns the theme/per-minor axis; version_truth (plan 03) owns the derived current-minor check"

key-files:
  created:
    - .planning/phases/191-release-version-and-docs-trust-repair/deferred-items.md
  modified:
    - guides/upgrade-path.md
    - CONTRIBUTING.md
    - test/threadline/upgrade_path_doc_contract_test.exs

key-decisions:
  - "0.6.x->0.9.x was surface/DX/proof-lane only — the affirmative 'nothing required' default is factually correct (zero host-DB migrations)"
  - "Storage-schema freeze-at-generation is the one migration-shaped expectation in the era; kept distinct from host table_schema"
  - "Used U+2192 arrows throughout the new content to match the existing 0.5->0.6 bullet; the new test accepts both U+2192 and ASCII"
  - "Backport-policy sentence placed at the end of the compatibility-matrix section (upgrade-path) and as a dedicated maintainer subsection (CONTRIBUTING)"

patterns-established:
  - "Every per-bump bullet documents exactly four things (breaking/migration/config/reassurance) and links a textual [x.y.0] CHANGELOG anchor, never a live #-anchor"
  - "New upgrade test refutes the v1.3x product-milestone label family that semver_adopter's v1.2x guard misses"

requirements-completed: [ADOPT-02]

coverage:
  - id: D1
    description: "upgrade-path.md covers the 0.6.x->0.9.x era across all four ADOPT-02 themes (storage-schema default, operator surface/theming, release proof lanes, migration expectations) plus per-minor bumps with mandatory nothing-required callouts and the storage-schema freeze block"
    requirement: "ADOPT-02"
    verification:
      - kind: unit
        ref: "test/threadline/upgrade_path_doc_contract_test.exs (theme axis + per-minor + nothing-required)"
        status: pass
      - kind: unit
        ref: "test/threadline/semver_adopter_doc_contract_test.exs (no v1.2x / phantom hub)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CONTRIBUTING.md carries the backport-policy sentence consistent with upgrade-path.md"
    requirement: "ADOPT-02"
    verification:
      - kind: manual_procedural
        ref: "mix verify.format && grep -qi 'backport' CONTRIBUTING.md"
        status: pass
    human_judgment: false
  - id: D3
    description: "Structural doc-contract test now fails on future loss of theme/per-minor/nothing-required coverage and refutes aspirational + v1.3x tokens"
    requirement: "ADOPT-02"
    verification:
      - kind: unit
        ref: "test/threadline/upgrade_path_doc_contract_test.exs (3 new tests, 13 total pass)"
        status: pass
    human_judgment: false

# Metrics
duration: 12min
completed: 2026-07-02
status: complete
---

# Phase 191 Plan 01: Extend upgrade-path for the 0.6.x->0.9.x adopter era Summary

**Extended `guides/upgrade-path.md` to cover the 0.6.x->0.9.x era with a four-theme orientation table, a per-minor spine, per-bump bullets whose default answer is an affirmative "nothing required", a storage-schema freeze-at-generation callout, a CHANGELOG-vs-upgrade-path division-of-labor note, and a backport-policy sentence mirrored into CONTRIBUTING.md — all locked by an extended structural doc-contract guard.**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-07-02
- **Tasks:** 3
- **Files modified:** 3 (+1 created: deferred-items.md)

## Accomplishments
- Extended the existing `## Upgrade by Threadline minor` section (no locked `##` heading added or renamed) with the D-191-09 hybrid shape: a four-theme orientation table using the exact ADOPT-02 keywords, a per-minor at-a-glance spine table, and three per-bump detail bullets each documenting breaking/migration/config plus an explicit `nothing required` reassurance for the `capture-only` and `phoenix-surface` lanes.
- Added the storage-schema freeze-at-generation migration expectation (per Phase 190 D-190-14), kept explicitly distinct from host `table_schema`/`--schema`, and mirroring the README Quick Start wording.
- Added the CHANGELOG-vs-upgrade-path division-of-labor note and the D-191-02a backport-policy sentence in the compatibility-matrix framing; mirrored the same backport sentence into `CONTRIBUTING.md`.
- Fixed the line-5 tense so the 0.6.0 claim reads as history, and set up the later-minors framing without introducing any refuted or product-milestone token.
- Extended `upgrade_path_doc_contract_test.exs` with three additive tests (theme axis, per-minor coverage with mandatory nothing-required, and refutes of `coming soon`/`forthcoming`/`v1.3x`); all pre-existing assertions stay green.

## Task Commits

1. **Task 1: Extend guides/upgrade-path.md for the 0.6.x->0.9.x era** - `2215edbf` (docs)
2. **Task 2: Mirror the backport-policy sentence into CONTRIBUTING.md** - `f7879269` (docs)
3. **Task 3: Extend upgrade_path_doc_contract_test.exs to lock the new coverage** - `34206c00` (test)

## Files Created/Modified
- `guides/upgrade-path.md` - Theme table, per-minor spine, per-bump bullets, storage-schema callout, division-of-labor note, backport sentence, line-5 tense fix
- `CONTRIBUTING.md` - Maintainer backport-policy subsection consistent with the guide
- `test/threadline/upgrade_path_doc_contract_test.exs` - 3 new structural tests (theme axis, per-minor, refuted tokens)
- `.planning/phases/191-release-version-and-docs-trust-repair/deferred-items.md` - Logged one pre-existing out-of-scope test failure

## Decisions Made
- Used U+2192 arrows throughout the new content to match the existing 0.5->0.6 bullet; the new per-minor test accepts both U+2192 and ASCII `->` forms so future editors are not boxed in.
- Placed the backport sentence at the end of the compatibility-matrix section (adopter framing) and as a dedicated `## Backport policy (maintainers)` subsection in CONTRIBUTING — both carry the identical patch-on-current-minor / minor-crossing-is-deliberate commitment.
- Kept the storage-schema block phrased to match the README Quick Start (locked by readme_doc_contract_test) rather than restating it, so the two surfaces cannot drift apart.

## Deviations from Plan

None - plan executed exactly as written. No Rule 1-4 auto-fixes were required; the three tasks landed as specified and all in-scope verifications passed on the first run.

## Issues Encountered

- `mix verify.doc_contract` reports 1 failure (110/111 pass): `v1_23_charter_doc_contract_test.exs` asserts PROJECT.md still contains the **v1.38** milestone strings, but PROJECT.md was updated to **v1.39** when the current milestone opened. This is pre-existing drift unrelated to the three 191-01 files (confirmed via `git diff`), so it is out of scope per the SCOPE BOUNDARY rule and logged to `deferred-items.md` for a later Phase 191 plan that owns milestone-charter truth. The plan's own verification targets (`upgrade_path_doc_contract_test`, `semver_adopter_doc_contract_test`, `mix verify.format`) are all green.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- ROADMAP success criterion 2 (upgrade guidance covers 0.6.x->0.9.x across the four themes with per-minor and theme axes, plus the storage-schema migration expectation) is met.
- Plan 03's `version_truth` Family C can read the 0.8.x->0.9.x coverage from this guide; the structural axis stays owned here, the derived current-minor check stays in version_truth_doc_contract_test (no overlap introduced).
- Pre-existing `v1_23_charter_doc_contract_test.exs`/PROJECT.md drift should be picked up by a later 191 plan or a charter-test literal refresh.

## Self-Check: PASSED

All modified/created files exist on disk and all three task commits (`2215edbf`, `f7879269`, `34206c00`) are present in git history.

---
*Phase: 191-release-version-and-docs-trust-repair*
*Completed: 2026-07-02*
