# Phase 246: Debt closeout and critic retirement - Context

**Gathered:** 2026-10-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 246 leaves main clean and stable for Phase 247 to measure:

- **DEBT-01:** every item of the 2026-10-24 carried-debt register, plus the pre-existing carried items the register omitted, has a recorded disposition (closed / waived with reason / routed to a named milestone or seed). The cheap 215/223 CI self-test findings are fixed. The WINDOWS ledger has zero open rows.
- **DEBT-02:** the parked UI-critic loop, including its deterministic mechanical floor (MechanicalChecker, Tier-A capture, the `verify-capture` CI job), is removed from main. An annotated `archive/ui-critic-loop` tag marks the last main commit carrying it. Suite, CI topology and docs stay consistent.

Out of scope (Phase 247): partition re-weighting, per-spec timing, the per-project browser split, contract-lane tagging, time-to-red re-derivation, and the measured CI gates. Also out of scope: the operator UI itself (parked until 1.0.0, not removed), and the 245 review findings (handled in 245-REVIEW-DISPOSITION.md).

</domain>

<decisions>
## Implementation Decisions

Research method: five parallel researchers (removal boundary, restoration tag, register dispositions, 215/223 fix-vs-waive, CI/suite consistency adversarial pass). The maintainer approved the synthesized set with a single confirm on 2026-10-25, including full removal of the mechanical floor.

### Research corrections to the register (planner must use these, not the register's text)
- **D-00a:** "223 5 WR + 1 IN open" is wrong. WR-01..05 landed via squash #70 (dd780e68). Evidence: `release_control_plane_contract_test.exs:395-400,455`, `.github/workflows/release.yml:787`, `bin/post-publish-distribution-sync:8`, `repo_hygiene_guard_test.exs:97-98,499-500`, `bin/verify-repo-hygiene:494-498`. Only 223 IN-01 is open.
- **D-00b:** 215 WR-07, WR-08, IN-01 and IN-02 were fixed or superseded by 244/245. The 215 row also omitted IN-04, WR-09, WR-10, IN-05, IN-06 and the MIX_EXS/MIX_HOME runtime item (T-215-36).
- **D-00c:** the register omitted these carried items, which still get dispositions: 216 WR-01, WR-02, IN-01, IN-03, IN-04; the 218 items (Dialyzer slice line not quotable from the CI log; Browser-full depending on tier-a-capture; WR-03); the 221 BASH_ENV advisory; ECON-03 (one CI run per release PR still unconfirmed); the 202 critic_trust_test flake correction. 245 IN-01..07 are excluded; they stay in 245's own disposition file.
- **D-00d:** WINDOWS has 60 open rows, 59 from phases 198–202 and row 64 from phase 235. SEED-005 already reads `status: closed` (from #89) but in freeform, without the SEED-006 schema fields.
- **D-00e:** the critic is about 14.1k lines of code and tests plus about 2.3 MB of fixtures (420 scorecard files), not "3k lines".

### A. Removal boundary (DEBT-02)
- **D-01: Delete (critic-only).**
  - `lib/mix/tasks/critic.{measure,synth}.ex` and `lib/threadline/critic_trust/*`
  - `lib/threadline/operator_surface/mechanical_checker{.ex,/*}`
  - `lib/threadline/operator_surface/live/stress_live/refute.ex`
  - `examples/threadline_phoenix/e2e/critic/**` and `e2e/critic-before-pole.sh`
  - `operator-{tier-a,refute,graded,storybook}-capture.spec.ts` and their Playwright projects (`playwright.config.ts:26-93`, keeping `route-capture`)
  - `e2e/tsconfig.json`, which only includes `critic/**`
  - tests: `test/threadline/critic_trust/*`, `operator_surface/critic_trust_test.exs`, `critic_{iteration_runbook_doc,pair_labeling,shell_safety}_contract_test.exs`, `operator_surface/{mechanical_checker,refute_partition}_test.exs`
  - fixtures: `test/fixtures/operator_surface/{scorecards,golden,refute,critic-scores}/` and `test/fixtures/dialyzer/critic-tooling.json`
  - mix aliases `verify.mechanical`, `verify.critic_trust`, `verify.ui_critique`, `verify.capture` and their helper functions (`mix.exs:24-25,166-182,427-481`)
  - the ci.yml `verify-capture` job (`ci.yml:852-1007`) and its `ci-required.needs` entry
  - graded and refute stress stories: `sections.ex:165-359`, `stress_fixtures.ex:181-290` and the refute `assigns_for` clause, `graded_stories` at `stress_live.ex:70`
  - Reversibility: reversible, restorable from the `archive/ui-critic-loop` tag (D-09).
- **D-02: Removing the mechanical floor and `verify-capture` is a deliberate coverage cut.** Record it under the existing "Removed CI proofs and what still catches them" convention (CONTRIBUTING plus `ci_topology_contract_test.exs:1260-1454`), with "still caught by" bullets:
  - contrast and token checks: `style_contract_test.exs:1096-1123`
  - accessibility: `operator-accessibility.spec.ts`
  - byte-stable stress-lab regeneration: retired, not replaced (UI parked until 1.0.0)
- **D-03: Keep, trimming the critic bits out.**
  - stress lab: `stress_live.ex`, `sections.ex`, `paths.ex`, `stress_fixtures.ex`, `stress_router.ex`
  - Storybook and `operator-storybook.spec.ts`
  - `operator-accessibility`, `operator-stress` and `operator-component-contracts` specs
  - `operator-page-capture.spec.ts` and the `route-capture` project, used by the v1.46 evidence lane. Delete only its legacy "emits the real operator-page evidence bundle" test (:433-449) and the critic comments.
  - the degraded timeline twin (`DEGRADE_CSS`, `route.timeline.degraded`), which is tangled with v1.46 evidence custody. Strip critic comments only.
  - `route-inventory.json` and `source-surface-checklist.json`. Prune the checklist's anchors to deleted capture specs.
  - `operator-surface-paths.ts` and its test. Remove the `critic*`, `tierA*`, `refute*` and `scorecards*` fields.
  - the screenshot baselines
  - stress router tests, `stress_fixtures_test` (trim refute/graded cases), `operator_surface_fixtures.ex` (drop `scorecards!/golden!/critic_scores!`), `operator_surface_fixture_contract_test.exs`
- **D-04: `design-system-ledger.json` stays.** `ThreadlineStressSession` raises without it, and `operator-stress.spec.ts` reads `entries` and `screenshot_allowlist`. Drop:
  - `critic_trust`, `critic_trust_provenance`, `critic_panel`
  - `mechanical_auto_apply`, `mechanical_floors`
  - `ratchet.signoffs`
  - per-entry `scores`
  - the 14 `refute.*` entries

  Rewrite `stress_ledger_test.exs` (:13-19, :71-167, :462-523) to match. Regenerate `manifest.sha256` (427 entries down to about 4) and the fixtures README in the same commit as the fixture deletions.
- **D-05: Browser-full survives with exactly one project (`route-capture`).** Do not delete `browser-full.yml`. Update `@live_deps`, `@stated_prerequisites`, the CONTRIBUTING project table (:560-615, enforced by `ci_coverage_doc_contract_test.exs`) and `browser_full_projects_contract_test.exs` to the one-project shape. This also closes the 218 "Browser-full depends on tier-a-capture" item.
- **D-06: Landmines (each must be handled in the same commit as its deletion).**
  - `package.json:20`: `test:unit` runs `critic/label.test.ts`, and `npm test` runs it on every browser lane, including the required one. Drop the `capture:*` and `critic:*` scripts and `typecheck`. Drop the devDeps `@anthropic-ai/sdk`, `zod` and `typescript` (8 of 44 lock packages leave). Regenerate `package-lock.json`. Keep `tsx` and `@playwright/test`.
  - Dialyzer: re-point the live slice proof (`dialyzer_slice_contract_test.exs:5,16,26,64`, `mix verify.dialyzer_slice`) to a surviving slice such as `query-storage.json`. Delete `critic-tooling.json`, and restate the ignore partition (`dialyzer_ignore_contract_test.exs:11,25-34` and `test/fixtures/dialyzer/README.md:7,28`) with the new counts. Do not keep it as a sealed exemption.
  - CI job roster: remove `verify-capture` from:
    - the `ci.yml:2` roster and the "thirteen jobs" comment
    - `@ci_job_ids`, `@time_to_red_order` (delete the id only, no re-measure) and `@ci_check_names` in `ci_workflow_parity_contract_test.exs`, plus every other site the consistency research listed
    - `ci_topology_contract_test.exs`
    - the `browser_journey_evidence_contract_test.exs:78` split anchor
    - the `retry_network` and `hex_pin` live counts
    - the CONTRIBUTING job lists
  - Package exclusions: remove the critic `exclude_patterns` (`mix.exs:577-584`, keeping the `release.pins` line) in the same commit as the files. Removing a pattern first would ship the files. Update `release_artifact_contract_test.exs:26,167-186`.
  - Update the matching contracts: `public_surface_contract_test.exs:7-13,236,649,669-670` (keep the :681 resurrection guard, reworded), `layer_boundary_contract_test.exs:17,28`, and `source_size_contract_test.exs:54-67` (the `stress_fixtures.ex` 980-line exception goes once it is under 800; the "exactly two exceptions" test changes).
  - Edit `clean_checkout_contract_test.exs` and `bin/verify-clean-checkout:81-86` together if needed. Clean up the comments in `bin/browser-full-projects` and `bin/verify-repo-hygiene:13`.
  - Delete only the `test/partition_weights.txt` rows for deleted files (`:68-73,153,170,178` and others). Keep sort order. No re-weighting (that is 247).
- **D-07: The `.gitignore:64-76` `.planning/critic-*` entries stay.** About 1,066 machine-local cache files still exist. Un-ignoring them dirties the tree and trips `bin/verify-repo-hygiene`. Drop only the `e2e/.gitignore` capture-artifact entries (`artifacts/{tier-a,storybook,graded}`).
- **D-08: Docs.**
  - CONTRIBUTING's critic section (:285-556, about 270 lines) becomes a 3-line "Retired: restore from `archive/ui-critic-loop`" pointer. A doc-contract assertion checks the pointer names the tag.
  - Strip the Ratchet Rule, the critic evidence tiers and the Scorecard Cube from `DESIGN-SYSTEM.md`.
  - Remove the dead alias rows from `guides/configuration-and-commands.md:139-164`. It ships to HexDocs, and its alias-inventory sentence is contract-enforced.
  - Remove the `mix.exs:259-261` comment.
  - Live planning files: in `.planning/UI-MILESTONE-PREFLIGHT.md:246` and `MILESTONE-GUIDE` :111/:301, "parked" becomes "retired, tag `archive/ui-critic-loop`". The PROJECT.md:909 decision row is marked done.
  - Historical `.planning/` phase records, `CRITIQUE.md`, `CHANGELOG.md` and `CHANGELOG-GENERATED.md` stay untouched. No `## Unreleased` entry, because the critic was never adopter-facing and the tarball code is unchanged.
- **D-09: The "no live references" check** (success criterion 3) is `git grep -iE 'critic|tier-a|tier_a|mechanical_checker|verify\.(capture|mechanical|critic_trust|ui_critique)'`. It may hit only:
  - `.planning/` history
  - `CHANGELOG*.md`
  - the `.gitignore` `.planning/critic-*` entries
  - the CONTRIBUTING "Retired" pointer and its doc-contract test
  - the reworded resurrection guard

  The plans enumerate this exemption list explicitly. False positives such as "critical" in `guides/stability.md` are excluded by the pattern or listed.
- **D-10: Commits.** Use one green commit per subsystem. The contracts read the live tree, so every deletion carries its own reference edits.
  1. TS critic, `package.json`, lock, tsconfig and paths test
  2. `critic_trust`, the critic mix tasks, aliases, guides, public-surface, release-artifact, layer-boundary and the Dialyzer re-point
  3. Mechanical floor, Tier-A, the `verify-capture` job, scorecards, and the CI contract and count edits
  4. The refute/graded capture specs and projects, stress refute/graded stories, the Browser-full one-project shape, and the journey row and CONTRIBUTING tables
  5. Fixture and ledger pruning, the manifest, and the partition row-deletes

  The planner may merge or reorder these where contracts force it. Use non-releasable prefixes only (`chore:`/`refactor:`/`test:`).
  - Reversibility: reversible.

### B. Restoration tag (D-4)
- **D-11: An annotated tag named `archive/ui-critic-loop`, following D-31 in `.planning/ARCHIVE-REGISTER.md`.** It cannot collide with release-please (`include-v-in-tag`, `v*` only). `release.yml` triggers only on a push to main or on dispatch with a `^v\d+\.\d+\.\d+$` guard. ci.yml has no tag trigger, and there are no tag rulesets. The tag message follows D-31: the SHA, ancestry, diffstat, date, DEBT-02/D-4, the rationale, the restore recipe (primary `git revert <removal-squash-sha>`; fallback `git checkout archive/ui-critic-loop -- <full path list>` plus the hand-restored mix.exs aliases), and a pointer to ARCHIVE-REGISTER.md. Add one register row. Keep home paths and the username out of the annotation (repo-hygiene lesson).
- **D-12: Target the parent of the removal squash commit on main,** not a milestone-branch commit, which a squash landing leaves unreachable. **Land the critic removal as its own non-releasable `chore:` squash PR**, separate from other v1.47 work, so the restore is one clean revert. The tag is created at land time, after the merge, because the message needs the real squash SHA. That makes it a landing hand-off step, not executor work during 246 execution.
  - Reversibility: costly. Once pushed, a public tag should not be moved.
- **D-13: Pushing the tag needs the maintainer's own grant.** Push the explicit refspec `git push origin refs/tags/archive/ui-critic-loop`. Never `--tags`, which would publish the local-only milestone tags. Pushing is consistent with the 15 `archive/*` tags already on origin; the local-only rule covers milestone tags only. Give the maintainer a ready-to-copy `! git push origin refs/tags/archive/ui-critic-loop`.
  - Reversibility: one-way. A published tag gets cached and fetched by clones.
- **D-14: No CI or contract test depends on the tag existing.** Shallow checkouts, forks, and runs before the push would fail at random. Verify with one-off commands recorded in VERIFICATION or landing evidence:
  - `git ls-tree -r --name-only archive/ui-critic-loop | grep -c lib/threadline/critic_trust/` is greater than 0
  - `git merge-base --is-ancestor archive/ui-critic-loop origin/main`
  - after the push, `git ls-remote --tags origin archive/ui-critic-loop` is non-empty

  The durable guard is the D-08 doc-contract assertion on the CONTRIBUTING pointer.

### C. Debt register (DEBT-01)
- **D-15: One canonical `246-DEBT-REGISTER.md` in the phase directory,** in the shape of 197-DESIGN-DEBT-REGISTER.md / 193-RISK-REGISTER.md.
  - Frontmatter carries counts by disposition.
  - One row per expanded item. Columns: id | item | source file | evidence (file:line or commit) | disposition (`closed`, `waived` or `routed`) | reason or route.
  - Rows cover the register rows, the D-00c omitted items and every WINDOWS row (as `W<id>` anchors).
  - A mechanical close check in the style of 222's `verify-phase.sh --close` fails if any disposition is blank, if a `routed` row names no v1.48/v1.49/v1.50/v1.51 or seed id, or if WINDOWS shows open rows.
- **D-16: Five 215/223 findings get fixed (all test-only; nothing under `.github/`, `bin/` or critic code).**
  1. **215 WR-04:** `deps_health_doc_contract_test.exs:381-386` refutes the workflow name, not the job name (`Daily hex.audit (Mix lockfiles)`, `deps-health.yml:43`), so it can never fail. Read the job `name:` from the yaml, refute a match against `.github/rulesets/main.json` `required_status_checks[].context`, and add a negative control. This is the only finding that hides a real failure mode: a silent promotion of the lane to a required check.
  2. **215 WR-05:** derive `@lockfiles` (:45, :158-166) from `CANONICAL_DIRS` via the existing `canonical_dir_line!/1`.
  3. **215 WR-06:** in `deps_audit_gate_test.exs`, compare expanded paths with `==` instead of `ends_with?` (:650), drop the dead `_ = pwds` (:637), make the hex.info log assertion exact (:322), and add `refute log =~ "deps.unlock"`.
  4. **215 IN-03:** delete the vacuous `refute after_report == nil` (`deps_health_report_test.exs:947`) and the never-failing "not in ci-required needs" test (`deps_health_doc_contract_test.exs:362-379`). WR-04 becomes the real guard.
  5. **223 IN-01:** add `String.contains?` assertions for the D-18 wording (`CONTRIBUTING.md:145`, in `repo_hygiene_contract_test.exs`) and the D-06 wording (`:1191`, in `changelog_contract_test.exs`).
- **D-17: The mechanical definition of "cheap"** is all of the following: 30 or fewer net added lines; at most 2 files; nothing under `.github/workflows/` or `.github/rulesets/`; no `bin/*` behaviour change; at most one new test group; no new dependency. Deleting a vacuous test is always cheap. An item with a credential or injection angle that fails these rules is routed, never waived.
- **D-18: The other 215/216 findings.**
  - **Close as fixed:** 215 WR-01, WR-03, WR-07, IN-01, IN-02 (cite 244/245); 216 CR-01; 216 SHA pinning, setup-node float, IN-02, IN-05 (cite 245 SC2).
  - **Waive:**
    - 215 WR-08: superseded by the exact, contract-tested Hex 2.6.0 pin (`hex_pin_contract_test.exs`)
    - 215 IN-05 and IN-06: low value
    - 216 IN-01, IN-03, IN-04: planner re-checks each; waive with a reason unless D-17-cheap and test-only
  - **Route:**
    - 215 IN-04 (`deps-health-report:443` truncation breaks a code fence; a `bin` change) → v1.49
    - 215 WR-10 (duplicated `read_global_hex_ignore`) → v1.51
    - MIX_EXS/MIX_HOME T-215-36 (security angle) → v1.48
    - 215 WR-09 → planner re-checks; waive or route
    - 216 WR-01 and WR-02 → v1.49
- **D-19: The other register rows.**
  - **Close:** 231 WR-01, 234 WR-01, 233 WR-01, gen.triggers `down`, partition weights, bench compile, 217 R1/R2 (all 11).
  - **Close, waived as an anti-feature:** gen.backfill / `:invalid_config` (229-CONTEXT:16).
  - **Route → v1.48:** 233 IN-01 (`not_found_error.ex:31`), 234 WR-02 (grouped-alias scanner gap), 231 IN-01 plus the incident_replay session config.
  - **Route → v1.49:** the clean_checkout tmp collision.
  - **Waive:** `verify.temp_leaks` (opt-in by design), v1.42 guide IN-01/02 (historical prose).
  - **Waive as obsolete with DEBT-02:** the 218 Dialyzer-slice-line item and the 202 critic_trust_test flake.
  - **Close via D-05:** the 218 Browser-full dependency on tier-a-capture.
  - **218 WR-03 and ECON-03:** the planner re-checks. Close if satisfied by 244 REL-02's observed run; otherwise route to v1.48.
  - **221 BASH_ENV advisory:** close if 221's required_gate_errors bans it (it reportedly does); otherwise waive with a reason.
  - **Hand-fix stale source disposition rows** such as 231-REVIEW-DISPOSITION.md WR-01. The Source cell cites the fixing commit (223 D-20 precedent). Never run the gsd-core disposition step over them (it drops reused ids).
- **D-20: WINDOWS ledger to zero open.**
  - 21 rows are fixed: 1, 3, 4, 5, 6, 8, 10–13, 18–23, 31, 42, 53, 56, 63.
  - 26 obsolete process/bookkeeping rows are waived: 24–30, 32, 33, 35, 36, 39, 41, 43–46, 48–52, 54, 55, 57, 64.
  - 7 critic and flake rows are waived as obsolete with DEBT-02: 9, 34, 37, 38, 40, 47, 61.
  - 5 screenshot-baseline rows (14–17, 62) are routed to the new UI-carry seed (D-22).
  - **Row 7 (CR-05) is still real.** `bin/verify-branch-protection` never diffs `bypass_actors` against `.github/rulesets/main.json:5`. Routed to v1.48.
  - The planner re-verifies each classification against HEAD before writing.
  - **Mechanics:** write only through `gsd-tools windows fixed <id>` and `windows waive <id> "<reason>"` (the owner is `broken-windows.cjs`; the JSON block is the source of truth and the table re-renders on every write). Run on a clean WINDOWS.md, one call at a time, with reasons citing `246-DEBT-REGISTER.md#W<id>`. Never hand-edit the table. Commit WINDOWS.md alone. Executors must not touch it otherwise.
- **D-21: SEED-005 moves to the SEED-006 schema:**
  - `status: closed`
  - `closed_on`
  - `closed_during: v1.47 Phase 246`
  - `closed_reason: shipped; Overlay.reconnect_banner mounted at ui/page.ex:295, data-tl-mutating wired at script.ex:58,101` (cite file:line; "Phase 178" cannot be verified from git)
  - the body's stale "Status: Open" line corrected
- **D-22: Plant SEED-008 as the operator-UI carry,** covering DR-243-01, typography, the Redaction copy (`policy_redaction_live.ex:450-454`) and the 8 screenshot-regression baselines (WINDOWS 14–17, 62). Its `reopen_when` is: the maintainer brings UI feedback, or the 1.0.0 UI work opens. This gives "parked with UI" a named route.
- **D-23: Make routes durable where the next milestone looks.** Append the routed items to the per-milestone candidate lists in `.planning/research/QUALITY-ROADMAP-2026-10-24.md` (v1.48 "Small items" already holds three of them; add CR-05, MIX_HOME, ECON-03 if routed; v1.49 gets 216 WR-01/02, clean_checkout and 215 IN-04; v1.51 gets 215 WR-10). Add a "Disposition (246)" pointer to its register table. Leave the original findings text intact.

### D. Gate and handoff to 247
- **D-24: Phase gate.**
  - `CI=true mix ci.all` on an ephemeral postgres:16
  - one `mix verify.example_browser` run to re-record the healthy browser baseline as "N passed / 8 failed / M skipped". The 8 failures all live in `operator-screenshot-regression.spec.ts` (:108/:115/:136/:145 × desktop/mobile), so they must stay identical. The skip count shrinks by about 34, because the self-skipping capture specs are gone.
  - the D-09 grep
  - the D-15 close check
  - `bin/verify-repo-hygiene` (grep the username and home-path shapes out of agent prose before committing)
- **D-25: Leave for 247:** partition re-weighting and the ≤1.15 ratio, per-spec timing, the per-project browser split, `:repo_contract` lane tagging, time-to-red re-derivation, and the ≤9 min median gate. 247 measures only after the new `package-lock.json` hash has warmed the npm and Playwright caches.
- **D-26: No branch-protection change.** The ruleset requires only `CI required`, which aggregates through `needs:`. Optional maintainer tidy-up: retire the `ci-browser-full` issue label only if Browser-full ever goes (it does not, per D-05).

### Claude's Discretion
- Exact commit grouping and order within D-10, where the contracts force merges.
- Wording of waiver reasons, the CONTRIBUTING "Retired" pointer and the "still caught by" bullets.
- Which surviving Dialyzer slice to re-point to (default `query-storage.json`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and decision sources
- `.planning/ROADMAP.md` §Phase 246: goal, success criteria 1–4, and the ordering note (246 before 247)
- `.planning/REQUIREMENTS.md`: DEBT-01, DEBT-02
- `.planning/research/QUALITY-ROADMAP-2026-10-24.md` §Carried-debt register and the milestone candidate lists (routing targets, D-23)
- `.planning/PROJECT.md:62,909`: the D-4 decision row
- `.planning/MILESTONE-ARC.md`: D-4

### Restoration tag
- `.planning/ARCHIVE-REGISTER.md`: the D-31 archive-tag convention and register format
- `release-please-config.json`, `.github/workflows/release.yml:10-13,~297`: tag-trigger safety

### Debt sources
- `.planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md`: full 215 finding text (the original REVIEW was overwritten)
- `.planning/milestones/v1.43-phases/215-supply-chain-gate/215-REVIEW.md`: WR-09/WR-10/IN-05/IN-06
- `.planning/milestones/v1.43-phases/223-close-v1-43-audit-debt/223-REVIEW.md`, `-REVIEW-DISPOSITION.md`, `-REVIEW-FIX.md`
- `.planning/milestones/v1.43-phases/216-*/216-REVIEW.md` and `deferred-items.md`; `218-*/deferred-items.md`
- `.planning/milestones/v1.45-phases/231-*/231-REVIEW-DISPOSITION.md`, `233-*/233-REVIEW.md`; the v1.45 audit is in git at 22254954
- `.planning/WINDOWS.md` (gsd-tools owned; `~/.claude/gsd-core/bin/lib/broken-windows.cjs`)
- `.planning/seeds/SEED-005-reconnect-banner-shell-mount.md`, `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md` (closure schema)
- `.planning/phases/245-supply-chain/245-VERIFICATION.md`, `245-01-SUMMARY.md`: closure citations
- Shape precedents: 197-DESIGN-DEBT-REGISTER.md, 193-RISK-REGISTER.md, and 222's `verify-phase.sh --close` (find under `.planning/milestones/`)

### Consistency surface
- `CONTRIBUTING.md:285-556` (critic section), `:560-615` (project table), and the "Removed CI proofs and what still catches them" section
- `.github/workflows/ci.yml:2,852-1007,1208-1235`; `.github/workflows/browser-full.yml`; `bin/browser-full-projects`
- `test/threadline/ci_workflow_parity_contract_test.exs`, `ci_topology_contract_test.exs`, `browser_full_projects_contract_test.exs`, `release_artifact_contract_test.exs`, `public_surface_contract_test.exs`, `dialyzer_slice_contract_test.exs`, `dialyzer_ignore_contract_test.exs`, `source_size_contract_test.exs`, `layer_boundary_contract_test.exs`, `operator_surface_fixture_contract_test.exs`, `stress_ledger_test.exs`
- `examples/threadline_phoenix/e2e/package.json`, `playwright.config.ts`, `support/operator-surface-paths{,.test}.ts`
- `mix.exs:24-25,166-182,259-261,427-481,566-584`
- `DESIGN-SYSTEM.md`, `guides/configuration-and-commands.md:139-164`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `canonical_dir_line!/1` (`deps_health_doc_contract_test.exs:60-67`): derives `@lockfiles` for WR-05.
- YamlElixir parsed-workflow helpers in the parity contracts: read the job `name:` for WR-04.
- The gsd-tools `windows fixed|waive` verbs: the only safe WINDOWS writer.

### Established Patterns
- Contracts read the live tree, so a deletion and its reference edits must land in one commit.
- The "Removed CI proofs and what still catches them" convention requires a still-caught-by bullet for every removed CI proof.
- Hand-edited review dispositions cite the fixing commit in the Source cell (223 D-20).
- Archive tags follow D-31 (annotated, `archive/<name>`, register row).
- Seed closure follows the SEED-006 schema (`closed_*`, `reopen_when`).

### Integration Points
- `ci-required.needs` and the frozen `@ci_job_ids` list (14 entries now, 13 after this phase).
- The Hex package `exclude_patterns` and `release_artifact_contract_test`.
- `npm test`, which runs `test:unit` before Playwright in every browser lane (`run-e2e.sh:508`).

</code_context>

<specifics>
## Specific Ideas

- Restore recipe primary: `git revert <removal-squash-sha>`; fallback: `git checkout archive/ui-critic-loop -- <paths>`, then restore the mix.exs aliases by hand.
- Maintainer hand-off line: `! git push origin refs/tags/archive/ui-critic-loop`
- Memory follow-up after the gate: restate the browser baseline memory ("326/8/16", "318/0/26") as the newly measured N/8/M.

</specifics>

<deferred>
## Deferred Ideas

- Untangling the degraded timeline twin from v1.46 evidence custody: a follow-up when the UI work reopens (SEED-008).
- 215 IN-04, WR-10, MIX_HOME; 216 WR-01/02; CR-05; clean_checkout; v1.48 small items: routed per D-18/D-19/D-20/D-23.
- 245 IN-01..07 and 245 WR-01: owned by 245-REVIEW-DISPOSITION.md (WR-01 recommended fixed before the 245 landing).

</deferred>

---

*Phase: 246-debt-closeout-and-critic-retirement*
