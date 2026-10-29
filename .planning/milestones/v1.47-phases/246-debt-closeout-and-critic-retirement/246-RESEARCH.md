# Phase 246: Debt closeout and critic retirement - Research

**Researched:** 2026-10-25 (HEAD `4f52ef4c`, branch `milestone/v1.47`, worktree `quality-baseline`)
**Domain:** in-repo removal (Elixir + Playwright/TS + CI YAML + live-tree contract tests) and planning-ledger dispositioning
**Confidence:** HIGH for anchors, couplings and counts (each read this session); MEDIUM for predicted browser numbers (derived by counting tests, not run)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Research method: five parallel researchers (removal boundary, restoration tag, register dispositions, 215/223 fix-vs-waive, CI/suite consistency adversarial pass). The maintainer approved the synthesized set with a single confirm on 2026-10-25, including full removal of the mechanical floor.

#### Research corrections to the register (planner must use these, not the register's text)
- **D-00a:** "223 5 WR + 1 IN open" is wrong. WR-01..05 landed via squash #70 (dd780e68). Evidence: `release_control_plane_contract_test.exs:395-400,455`, `.github/workflows/release.yml:787`, `bin/post-publish-distribution-sync:8`, `repo_hygiene_guard_test.exs:97-98,499-500`, `bin/verify-repo-hygiene:494-498`. Only 223 IN-01 is open.
- **D-00b:** 215 WR-07, WR-08, IN-01 and IN-02 were fixed or superseded by 244/245. The 215 row also omitted IN-04, WR-09, WR-10, IN-05, IN-06 and the MIX_EXS/MIX_HOME runtime item (T-215-36).
- **D-00c:** the register omitted these carried items, which still get dispositions: 216 WR-01, WR-02, IN-01, IN-03, IN-04; the 218 items (Dialyzer slice line not quotable from the CI log; Browser-full depending on tier-a-capture; WR-03); the 221 BASH_ENV advisory; ECON-03 (one CI run per release PR still unconfirmed); the 202 critic_trust_test flake correction. 245 IN-01..07 are excluded; they stay in 245's own disposition file.
- **D-00d:** WINDOWS has 60 open rows, 59 from phases 198–202 and row 64 from phase 235. SEED-005 already reads `status: closed` (from #89) but in freeform, without the SEED-006 schema fields.
- **D-00e:** the critic is about 14.1k lines of code and tests plus about 2.3 MB of fixtures (420 scorecard files), not "3k lines".

#### A. Removal boundary (DEBT-02)
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

#### B. Restoration tag (D-4)
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

#### C. Debt register (DEBT-01)
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

#### D. Gate and handoff to 247
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

### Deferred Ideas (OUT OF SCOPE)
- Untangling the degraded timeline twin from v1.46 evidence custody: a follow-up when the UI work reopens (SEED-008).
- 215 IN-04, WR-10, MIX_HOME; 216 WR-01/02; CR-05; clean_checkout; v1.48 small items: routed per D-18/D-19/D-20/D-23.
- 245 IN-01..07 and 245 WR-01: owned by 245-REVIEW-DISPOSITION.md (WR-01 recommended fixed before the 245 landing).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEBT-01 | Every carried-debt row has a disposition; fixed closed, obsolete (incl. stale WINDOWS rows) waived with reason; cheap 215/223 self-test findings fixed | §Debt re-checks (all delegated rows resolved with evidence), §D-16 fix sketches (all 5 D-17-cheap), §WINDOWS mechanics (exact CLI, bucket check 60/60), §Close check (verify-phase.sh design) |
| DEBT-02 | Critic loop removed from main, last commit tagged, suite/CI/docs consistent | §Anchor verification (drift table), §D-09 grep categorisation, §Contract coupling graph and the 4-commit plan, §Landmines CONTEXT missed, §Gate mechanics |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Verify through named entrypoints: `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all`; CI job `id:` fields are immutable (removing a job is allowed; renaming a surviving one is not).
- Honest default tests: never silently exclude suites from `mix test`; `test/test_helper.exs` and docs move together (this phase deletes tests, it adds no excludes).
- Doc contract tests keep README/guides/CONTRIBUTING aligned; every doc edit rides with its contract.
- Zero human verification by default: automate every UAT row; hand the maintainer only push/publish/scope (here: the tag push and the landing merge).
- `state.begin-phase` takes flags on gsd-core v1.14.0 (`--phase 246 --name "…" --plans N`); hand-check STATE.md/ROADMAP.md after `state.*` handlers.
- Capture-layer trigger boundary is untouched by this phase.
- Memory-derived local rules that bind executors: never `git add .planning/` wholesale; WINDOWS.md is re-serialized by gsd-tools writes, so executors log deviations to `deferred-items.md` only (a stray `windows append` re-opens the count); repo-hygiene scans tracked `.planning/` prose, so no home-path shapes or the local username in any committed file; never run Playwright directly for a gate (use `mix verify.example_browser`); never `npx @opengsd/*`; executors must not route around a blocking gate or leave poll loops running.

## Summary

CONTEXT.md is executable with three classes of correction. (1) **Anchor drift is small but real**: most file:line anchors hold at HEAD; the misses are a mis-attributed resurrection guard (it lives at `ci_topology_contract_test.exs:674-695`, not `public_surface_contract_test.exs:681`), the manifest after-count (1 entry, not ~4), the lock count (9 packages leave, not 8), the skip delta (−10, not −34, because `operator-page-capture.spec.ts` stays), and several unlisted edit sites in `stress_fixtures.ex`/`stress_live.ex`. (2) **The contract graph forces a different commit grouping than D-10**: TS critic rubrics are read by `critic_trust_test.exs`, Playwright spec files are loaded by an ExUnit test (`browser_journey_evidence_contract_test.exs` runs `playwright test --list`), `bin/browser-full-projects` resolves `mix verify.capture`'s `--project` flags so the CI job, the alias, all five capture projects and the browser-full contract must move together, and the fixture/ledger/manifest/stress-story set is cross-validated by one contract. The recommended order is four removal commits: C1 critic_trust (Elixir) → C2 TS critic → C3 capture + mechanical + verify-capture → C4 stress stories + fixture corpus. (3) **Landmines CONTEXT missed**: `rendered_output_contract_test.exs:65` pins `@reference_manifest_entry_count 427`; the dialyzer slice contract's negative controls use `lib/threadline/query.ex` as an *unauthorized* origin, which becomes authorized under `query-storage`; Browser-full would run `route-capture` with every test self-skipped once the legacy test is deleted (an orphaned capture lane, against SC4); the ci_topology "removed CI proofs" contract hard-requires `verify-capture` and `mechanical_checker_test.exs` to exist.

All delegated debt re-checks resolve with HEAD evidence: 216 IN-01 fix (test-only, cheap), 216 IN-03 route v1.48 (credential angle, not test-only), 216 IN-04 waive (fix would touch `.github/workflows/`), 215 WR-09 route v1.51 (with WR-10; the WR-09 fix option (a) *is* the WR-10 dedupe), 218 WR-03 waive (locked by the maintainer as 218 D-04; unrelated to REL-02), ECON-03 route v1.48 (`244-REL02-EVIDENCE.md` is `Status: pending`), 221 BASH_ENV close (key spelling banned at `rule=gate-bash-env`, and the comment was reworded to scope it). D-20's WINDOWS buckets were re-derived from the JSON source of truth: exactly the 60 open ids, disjoint, complete.

**Primary recommendation:** plan 4 removal commits in the order C1→C2→C3→C4 (all `chore:`), kept contiguous and free of any non-critic edit so they squash-land as one revertable PR; put D-16 test fixes, the debt register, WINDOWS, seeds and roadmap edits in separate plans after C4; keep the legacy page-capture test (one-line amendment to D-03) so Browser-full is not vacuous.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Critic trust math, critic mix tasks | Repository tooling (lib/, Hex-excluded) | — | Never shipped (`exclude_patterns`); delete with its contracts |
| TS critic runner, labeler, rubrics | Example-app e2e tooling (Node) | npm lockfile | Only Node consumer is `npm test`'s `test:unit` |
| Tier-A/graded/refute/storybook capture | Playwright projects + specs | ci.yml `verify-capture`, mix alias | Project set is derived by `bin/browser-full-projects` from config + ci.yml + mix.exs |
| Mechanical floor | Repository tooling (lib/, Hex-excluded) | committed scorecards + ledger floors | Only consumer of the 420 scorecards besides capture |
| Stress lab refute/graded stories | Operator surface (dev/test-only LiveView) | design-system ledger | Ledger entries round-trip through `StressFixtures` |
| CI topology & roster | `.github/workflows/ci.yml` | parity/topology/browser-full contracts + CONTRIBUTING | Contracts read the live tree |
| Debt dispositions | `.planning/` ledgers | WINDOWS (gsd-tools owned) | Planning-only commits, separate from the critic squash PR |

## Standard Stack

No new libraries. Tooling already present and verified this session:

| Tool | Version | Use in this phase |
|------|---------|-------------------|
| Node / npm | node 22.14.0 (`.tool-versions`), npm 11.1.0 local | `package-lock.json` regeneration [VERIFIED: `node --version`, `npm --version`] |
| `yaml_elixir` | `~> 2.11.0`, `only: :test` | WR-04 job-name read [VERIFIED: mix.exs:127 `{:yaml_elixir, "~> 2.11.0", only: :test, runtime: false}`] |
| Docker + `postgres:16` image | local image present | ephemeral gate DB [VERIFIED: `docker image ls` lists `postgres:16`] |
| python3 | system | one-off ledger prune (round-trip is byte-exact: `json.dumps(d, indent=2, ensure_ascii=False) + "\n"` == file) [VERIFIED: probe returned `True`] |

## Package Legitimacy Audit

This phase **installs no packages**. It removes three devDependencies from `examples/threadline_phoenix/e2e/package.json` (`@anthropic-ai/sdk`, `zod`, `typescript`). No legitimacy gate applies.

| Package | Registry | Verdict | Disposition |
|---------|----------|---------|-------------|
| @anthropic-ai/sdk, zod, typescript (and transitive json-schema-to-ts, @babel/runtime, ts-algebra, standardwebhooks, @stablelib/base64, fast-sha256) | npm | n/a (removal) | REMOVED from lock |

**Packages removed due to [SLOP] verdict:** none. **Packages flagged [SUS]:** none.

## Anchor verification against HEAD 4f52ef4c

Everything not listed below matched CONTEXT exactly. Drift and omissions:

| CONTEXT anchor | Actual at HEAD | Action |
|---|---|---|
| `mix.exs:24-25` (preferred_envs) | `:24-26` — `"verify.mechanical": :test,` `"verify.critic_trust": :test,` `"verify.capture": :test,` | delete all three lines |
| `mix.exs:166-182` | `:166-183` (aliases incl. `"verify.capture": &verify_capture/1,` at :183) | |
| `mix.exs:427-481` | `verify_capture/1` comment+defp `:427-438`; `verify_ui_critique/1` `:447-481`; keep `verify_operator_component_contracts` `:440-445` between them | |
| `mix.exs:577-584` | `exclude_patterns` `:577-585`; also reword comment `:566-576` ("Two of the critic tasks carry a `@shortdoc`…") | |
| `public_surface_contract_test.exs` ":681 resurrection guard" | **not there** — `:681` is `defp task_module`. The guard is `ci_topology_contract_test.exs:674-695` (`test "no workflow references the paid critic API key (GREEN-09 resurrection guard)"`) | reword *that* test |
| `release_artifact_contract_test.exs:26,167-186` | comment `:26-29`; `@maintainer_only_paths` `:165-186`; `@maintainer_only_prefixes` `:189-194`; failure message `:215` | |
| `stress_fixtures.ex:181-290` + refute `assigns_for` | also `assigns_for(%{category: "refute"})` `:363-378`; call sites `:417-418` (`refute_twin_story_maps(), graded_twin_story_maps()`); builders/helpers `:873-966` (`refute_twin_story_maps`, `graded_twin_story_maps`, `graded_rungs`, `graded_stories`, `rung_verdict`, `rung_to_pole`) | all go in C4; file drops from 980 to ~760 lines |
| `stress_live.ex:70` | also `:66-69` comment, `:162` (`<Sections.refute_matrix …>`), `:229-230` (`show_refute_matrix?/1`) | |
| `sections.ex:165-359` | plus alias line `:9` (`alias Threadline.OperatorSurface.Live.StressLive.Refute`) | |
| `playwright.config.ts:26-93` | `:25-94` (5 projects: `tier-a-capture`, `tier-a-capture-light`, `storybook-capture`, `graded-capture`, `refute-capture`); `route-capture` `:95-109` stays, strip its comment `:95-98` | |
| `ci.yml:852-1007` | job `:852-1007` plus `# Removed: verify-mechanical` comment `:842-845`, job lead comment `:847-851`, cache comment `:128-131` naming `verify-capture` | |
| D-04 "manifest 427 → about 4" | manifest today: 420 `scorecards/`, 4 `golden/`, 1 `refute/`, 1 `critic-scores/`, 1 `design-system-ledger.json`. `route-inventory.json`/`source-surface-checklist.json`/README are excluded by name. **After: exactly 1 entry** | |
| D-06 "8 of 44 lock packages" | lock has 44 non-root entries; **9 leave**: `@anthropic-ai/sdk`, `json-schema-to-ts`, `@babel/runtime`, `ts-algebra`, `standardwebhooks`, `@stablelib/base64`, `fast-sha256`, `zod`, `typescript` [VERIFIED: lock `dependencies` graph] | `@types/node` stays (not named in D-06; harmless) |
| D-24 "skip shrinks by about 34" | **−10** (CI mode): 34 is the *whole* capture-spec skip set (4 single-test specs + 13 page-capture tests, × 2 projects), but page-capture stays. Removed: 4 capture tests + the legacy page-capture test, × desktop/mobile | see §Gate |
| D-03 operator-surface-paths fields | also `goldenDir`, `verdictCacheDir`, `critiqueReportPath` (critic outputs); keep `routeScorecardsDir` (page-capture), `ledgerPath`, `fixtureRoot`, `generatedRoot`, `e2eRoot`, `repositoryRoot` | |
| D-03 `operator_surface_fixtures.ex` "drop scorecards!/golden!/critic_scores!" | also `refute!/0` (`test/support/operator_surface_fixtures.ex:27-31`) — its directory is deleted | |
| CONTRIBUTING 223 IN-01 wording ":145" | sentence spans `:144-145` ("It is never for prose, and no\nfile or directory is exempt from the scan other than the allowlist's own literal column.") — assert on whitespace-normalised text | |

## D-09 grep categorisation

**Use a refined pattern** (CONTEXT allows "excluded by the pattern"). The literal pattern hits `critical` in ~15 unrelated files (guides/stability.md, guides/performance.md, guides/upgrade-path.md, WALKTHROUGH.md, example `accounts.ex`, `user_session.ex`, `user_auth.ex`, `operator-accessibility.spec.ts:383`, `ci_workflow_parity_contract_test.exs:2408`, `stability_contract_test.exs:12`, CONTRIBUTING:1001/1117 …):

```bash
git grep -nIiE 'critic([^a]|$)|tier[-_]a|mechanical_checker|verify\.(capture|mechanical|critic_trust|ui_critique)' \
  -- ':!.planning' ':!CHANGELOG.md' ':!CHANGELOG-GENERATED.md' ':!prompts/' ':!bench/baselines/assets/'
```

Every HEAD hit (outside `.planning/`), categorised:

| Category | Files | Owner commit |
|---|---|---|
| **Deleted file** | `lib/mix/tasks/critic.*`, `lib/threadline/critic_trust/*`, `lib/threadline/operator_surface/mechanical_checker{.ex,/*}`, `stress_live/refute.ex`, `e2e/critic/**`, `e2e/critic-before-pole.sh`, `e2e/tsconfig.json`, 4 capture specs, `test/threadline/critic_trust/*`, `critic_trust_test.exs`, `critic_{iteration_runbook_doc,pair_labeling,shell_safety}_contract_test.exs`, `mechanical_checker_test.exs`, `refute_partition_test.exs`, `test/fixtures/dialyzer/critic-tooling.json`, `test/fixtures/operator_surface/{scorecards,golden,refute,critic-scores}/**` | C1–C4 |
| **Edit site** | `mix.exs` (C1: :25,:172-182,:447-481,:577-580; C3: :24,:26,:166-171,:183,:259-261,:427-438,:582), `guides/configuration-and-commands.md` (C1 :141,:161-163; C3 :140,:164), `test/threadline/public_surface_contract_test.exs` (C1 :7-13,:236,:649,:669; C3 :670), `release_artifact_contract_test.exs` (C1 :26,:167-174,:191-192,:215; C3 :179-185,:194; C4 :177), `layer_boundary_contract_test.exs` (C1), `dialyzer_slice_contract_test.exs`, `dialyzer_ignore_contract_test.exs`, `test/fixtures/dialyzer/README.md` (C1), `e2e/package.json` (C2 critic/typecheck/test:unit; C3 capture:*), `e2e/support/operator-surface-paths{,.test}.ts` (C2 critic fields; C3 tierA/scorecards/golden/refute fields), `CONTRIBUTING.md` (C1 :890; C2 :285-556; C3 :557-615,:639,:851,:865-866,:962,:1021,:1109), `.github/workflows/ci.yml` (C3), `.github/workflows/browser-full.yml:2-8` (C3), `bin/browser-full-projects:21,:36` (C3, comment-only), `playwright.config.ts` (C3), `browser_full_projects_contract_test.exs` (C3), `ci_topology_contract_test.exs` (C3 :1262-1440; reword :674-695), `ci_workflow_parity_contract_test.exs` (C3 :107 comment, :4561, :5907), `DESIGN-SYSTEM.md` (C3 Capture Matrix :182-224; C4 Ratchet Rule :5-8, Scorecard Cube :225+), `e2e/.gitignore:5-7` (C3), `source-surface-checklist.json:4626` (C3), `test/partition_weights.txt` (C1 :71-73,:153; C2 :68-70; C3 :170,:178), `stress_fixtures.ex` (C4), `test/support/operator_surface_fixtures.ex` (C4), `operator_surface_fixture_contract_test.exs` (C4), `stress_ledger_test.exs` (C4), `stress_router_test.exs:187` (C4), `design-system-ledger.json` (C4), `manifest.sha256` (C4), `test/fixtures/operator_surface/README.md` (C4), `bin/verify-repo-hygiene:13` (comment reword, any commit) | |
| **Edit site CONTEXT did not anticipate** | `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts:550` ("hide-at-zero is Tier-A-proven"); `test/threadline/operator_surface/component_contract_test.exs:595` ("half is Tier-A-assertable"); `operator-page-capture.spec.ts:12-60,:89,:328` critic comments (D-03 strips "critic comments", but :42 "matches Tier-A" and :89 `mechanical_floors` are easy to miss); `browser_full_projects_contract_test.exs` moduledoc `:18-26` (218-08 history naming tier-a/refute) | comment rewording in C3 |
| **Exemption (keep, list explicitly)** | `.planning/**`; `CHANGELOG*.md`; `.gitignore:64-65` (`/test/generated/operator_surface/critic-scores/`, `/critic-verdict-cache/`) **and** `:69-74` (D-07 — note CONTEXT only exempted the `.planning/critic-*` lines; :64-65 also hit); `bin/verify-clean-checkout:82-85` and `clean_checkout_contract_test.exs:19-25,:38-43` (they probe those very ignore rules and the `critic-scores` prefix-confusion paths; editing them would require dropping .gitignore:64-65, which D-07 keeps); `release_artifact_contract_test.exs:12` and `upgrading_to_0_11_doc_contract_test.exs:13` (`~r/\b(?:ADOPT|COMP|CRITIC|DATA|…)-\d{2,}\b/` — a generic planning-ID leak guard, keep); the reworded `ci_topology_contract_test.exs` ANTHROPIC-key guard; the CONTRIBUTING Retired pointer + removed-proofs bullets that name `archive/ui-critic-loop`, and their doc-contract test | — |
| **Pathspec-excluded false positives** | `prompts/prior-art/from-sigra/*` ("criticized"), `bench/baselines/assets/javascripts/plotly-2.27.0.min.js` (vendored minified JS) | — |

## Contract coupling graph (why D-10 must be regrouped)

| Coupling (evidence) | Consequence |
|---|---|
| `critic_trust_test.exs:16` `@rubrics_dir "examples/threadline_phoenix/e2e/critic/rubrics"`; `critic.measure.ex:12` same | TS rubrics cannot leave before `critic_trust_test`/`critic.measure` → **C1 (Elixir critic_trust) must precede C2 (TS)**, reversing D-10 #1/#2 |
| `browser_journey_evidence_contract_test.exs:48-52` runs `playwright test --list --project=desktop-chromium --project=mobile-chromium` (loads every spec) and `operator-graded-capture.spec.ts:29` evaluates `resolveContainedPath(paths.goldenDir, "synthetic-set.json")` at module load | removing `goldenDir`/`scorecardsDir`/`tierAArtifactsDir`/`refuteDir` from `operator-surface-paths.ts` before the capture specs are deleted breaks ExUnit **and** every browser lane at collection time → those fields go in **C3 with the specs**; C2 removes only critic-only fields |
| `bin/browser-full-projects` counts `--project=` flags "inside the mix.exs function behind any `mix <alias>` a run body calls (today `mix verify.capture` -> verify_capture/1)" (:19-22); contract test `:275` "removing run: mix verify.capture from ci.yml moves both tier-a projects into the output" | removing the `verify-capture` job without deleting the tier-a projects moves them into Browser-full; deleting `tier-a-capture` while `refute-capture` keeps `dependencies: ["tier-a-capture"]` exits 1 ("a declared dependency names a project that is not a default-config project") → **verify-capture job + `verify.capture` alias + all 5 capture projects + specs + browser_full contract + CONTRIBUTING table = one commit (C3)**; merges D-10 #3 and the project half of #4 |
| `ci_topology_contract_test.exs:1335-1356` `removed_proof_errors/3` asserts `{capture != "", "verify-capture is gone from ci.yml"}` and reads `@mechanical_checker_test` (`:1268`, `:1378` `read_rel!`) | the removed-proofs test must be rewritten in the same commit that deletes `verify-capture` and `mechanical_checker_test.exs` (C3) |
| `stress_ledger_test.exs:10` `@synthetic_set_path Path.join(OperatorSurfaceFixtures.golden!(), "synthetic-set.json")` is a **compile-time** call | deleting `golden/` before editing `stress_ledger_test` fails compilation of the test suite |
| `operator_surface_fixture_contract_test.exs:162-185` `validate_corpus` requires `critic-scores/.gitkeep`, `golden/*`, `refute/refute-set.json`, non-empty `scorecards/` and cross-validates ledger↔scorecards↔golden↔refute; `:71` manifest must equal tracked set; ledger itself is a manifest entry | any ledger edit (incl. dropping the 14 `refute.*` entries) forces a manifest regen; ledger refute entries must leave with the refute stories (`stress_ledger_test` "ledger-owned fixture references round-trip through StressFixtures" :256) → **stress stories + ledger + all 4 fixture dirs + manifest + fixture contract = one commit (C4)**; merges D-10 #4 (stories) and #5 |
| `public_surface_contract_test.exs:894-896` scans `DESIGN-SYSTEM.md` for `mix …` references against the live alias inventory; DESIGN-SYSTEM `:193-194` names `mix verify.capture`/`mix verify.mechanical` | Capture Matrix rewrite rides with the alias removal (C3); Scorecard Cube/Ratchet Rule ride with ledger pruning (C4, `stress_ledger_test` `@design_sections` :61-72 and `scorecard_row/2` :507) |
| `public_surface_contract_test.exs:207-224` classifies every discovered alias and validates `guides/configuration-and-commands.md` references | each guide row leaves in the commit that deletes its alias (C1: `verify.critic_trust`, `verify.ui_critique`, `critic.measure`, `critic.synth`; C3: `verify.mechanical`, `verify.capture`) |
| `release_artifact_contract_test.exs:205-210` asserts `File.regular?(path)` for every `@maintainer_only_paths` entry | each path row leaves with its file; `exclude_patterns` leave in the same commit (D-06) |
| `layer_boundary_contract_test.exs:51-56` existence-checks `@allowlist ["lib/mix/tasks/critic.synth.ex"]` | allowlist becomes `[]` in C1 |
| `source_size_contract_test.exs:81-83` "the real tree matches the file exceptions exactly" (pins 980) | any `stress_fixtures.ex` edit must update/remove the exception in the same commit (C4; ~760 lines → remove, and `:63-75` "exactly two" → "exactly one: facade prose") |
| `test/partition_weights.txt` | `bin/ci-test-partitions:88` "(k) a stale weight entry is ignored" — not forced per commit; delete rows with each file anyway |

### Recommended commit plan (all `chore:`; contiguous; no non-critic edits inside)

| # | Subject (suggested) | Contents | Prove green (targeted) |
|---|---|---|---|
| C1 | `chore: retire critic-trust tooling and its Dialyzer slice` | delete `lib/threadline/critic_trust/*`, `lib/mix/tasks/critic.{measure,synth}.ex`, `test/threadline/critic_trust/*`, `operator_surface/critic_trust_test.exs`, `test/fixtures/dialyzer/critic-tooling.json`; mix.exs `:25`, `:172-182` (critic_trust + ui_critique aliases), `:447-481`, exclude `:578,:580` + comment; release_artifact `:26-29,:167-174,:191-192,:215`; public_surface `:7-13,:236,:649,:669`; layer_boundary `:17-19,:28`; guides `:141,:161-163`; dialyzer re-point (below); CONTRIBUTING `:890` ("over the committed critic-tooling fixture"); partition rows `:71-73,:153` | `mix compile --warnings-as-errors && mix test test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/layer_boundary_contract_test.exs test/threadline/dialyzer_ignore_contract_test.exs test/threadline/dialyzer_slice_contract_test.exs && mix verify.dialyzer_slice && mix verify.credo` |
| C2 | `chore: retire the TypeScript critic runner` | delete `e2e/critic/**`, `e2e/critic-before-pole.sh`, `e2e/tsconfig.json`, `critic_{pair_labeling,shell_safety}_contract_test.exs`; replace `critic_iteration_runbook_doc_contract_test.exs` with a retired-pointer doc contract (keeps the doc-contract file count at 37; floor is 30, `bin/verify-bump-rehearsal:556-557`); `package.json` (drop `critic:*`, `typecheck`, `test:unit` → `tsx --test support/operator-surface-paths.test.ts`; devDeps); lock regen; `operator-surface-paths.ts` critic-only fields (`criticRubricsDir`, `criticScoresDir`, `verdictCacheDir`, `refuteTranscriptsDir`, `critiqueReportPath`, `criticReportHtmlPath`, `criticFloorsPath`) and their tests (`:184-205`, `:207-237`, `:324-351` partial, `:353-523`, `:628-778`); CONTRIBUTING `:285-556` → Retired pointer; partition rows `:68-70` | `cd examples/threadline_phoenix/e2e && npm ci --ignore-scripts && npm run test:unit && node_modules/.bin/playwright test --list >/dev/null`; then `mix test test/threadline/browser_journey_evidence_contract_test.exs test/threadline/playwright_fail_fast_contract_test.exs test/threadline/<retired_pointer>_doc_contract_test.exs` |
| C3 | `chore: retire Tier-A capture, the mechanical floor and verify-capture` | delete `mechanical_checker{.ex,/*}`, `mechanical_checker_test.exs`, `refute_partition_test.exs`, `operator-{tier-a,refute,graded,storybook}-capture.spec.ts`; playwright `:25-94`; paths fields `scorecardsDir`/`goldenDir`/`refuteDir`/`tierAArtifactsDir` (+`immutableRoots` → `[ledgerPath]`) and tests; `package.json` `capture:*`; `e2e/.gitignore:5-7`; ci.yml (job, `:2` roster, `:128-131`, `:842-851` rewrite, `:1187,:1227` "thirteen"→"twelve", needs `:1209`, add `# Removed: verify-capture` comment); mix.exs `:24,:26,:166-171,:183,:259-261,:427-438,:582`; release_artifact `:179-185,:194`; public_surface `:670`; guides `:140,:164`; DESIGN-SYSTEM Capture Matrix; all CI contract edits (below); CONTRIBUTING CI sections; browser-full.yml header; `bin/browser-full-projects:21,:36` comments; checklist probes for the 4 deleted specs; un-anticipated comment sites; partition `:170,:178` | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/browser_journey_evidence_contract_test.exs test/threadline/hex_pin_contract_test.exs test/threadline/retry_network_contract_test.exs test/threadline/repo_hygiene_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/operator_surface/operator_evidence_contract_test.exs`; `bin/browser-full-projects --list config` prints `desktop-chromium mobile-chromium route-capture`; `npm run test:unit` |
| C4 | `chore: prune critic stress stories and the fixture corpus` | delete `stress_live/refute.ex`, fixture dirs `scorecards/ golden/ refute/ critic-scores/`; edit `sections.ex:9,:165-359`, `stress_live.ex:66-70,:162,:229-230`, `stress_fixtures.ex:181-290,:363-378,:417-418,:873-966`; ledger prune; manifest (1 line); fixtures README; fixture contract rewrite; `rendered_output_contract_test.exs:65` 427→1 and its controls; `operator_surface_fixtures.ex` (drop `scorecards!`, `golden!`, `refute!`, `critic_scores!`); `stress_router_test.exs:187`; `stress_fixtures_test.exs` trim; `stress_ledger_test.exs` rewrite; DESIGN-SYSTEM Ratchet Rule + Scorecard Cube; source_size exception; release_artifact `:177` (refute.ex) | `mix test test/threadline/operator_surface/ test/threadline/source_size_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/public_surface_contract_test.exs`; `mix verify.operator_stress` (stress spec reads the pruned ledger); `mix verify.example` (stress session boots) |

Then (separate plans, after C4, outside the critic squash): D-16 test fixes (+216 IN-01), the debt register + close-check script, WINDOWS writes (own commit), SEED-005/SEED-008, QUALITY-ROADMAP appends, live planning wording, hand-fixed source disposition rows. Final plan: the D-24 gate.

**Planning for the D-12 squash PR:** the landing branch cherry-picks C1–C4 only; keep them contiguous on `milestone/v1.47` and do not interleave any D-16 or planning commit between them. 216 IN-01's fix edits `ci_workflow_parity_contract_test.exs`, which C3 also edits; land it as its own later commit (different hunks, cherry-pick-safe).

## Per-subsystem edit details

### Dialyzer re-point (C1) — landmine detail
`dialyzer_slice_contract_test.exs` repointed to `query-storage.json` (W03 W04 W33–W40; 5 origins: `lib/threadline/change_diff.ex`, `lib/threadline/continuity.ex`, `lib/threadline/query.ex`, `lib/threadline/query/actor_history_page.ex`, `lib/threadline/storage/local.ex`) [VERIFIED: fixture read]:
- `:16` `"verified slice critic-tooling: 3/40 sealed warnings"` → `"verified slice query-storage: 10/40 sealed warnings"` (denominator is `sealed_run.warning_count` = 40 and stays 40 — the sealed provenance hash `12c1164a…` is unchanged).
- `:27-28` `"3/40 sealed warnings"`, `"3 authorized origins"` → `10/40`, `5 authorized`.
- **Swap the controls:** `:24-25,:197` use `lib/threadline/query.ex` as an *out-of-bound* line; under query-storage it is authorized and would turn the positive controls red. Use a path in no slice for out-of-bound lines (pick one from `export-investigation`/`operator-*`-free files after reading those fixtures), and use `lib/threadline/query.ex` (now authorized) for the "unrecorded live warning" control at `:63-64` (replacing `lib/threadline/critic_trust/measure.ex`). `:44` "origin outside authorized_origins" sets path `lib/threadline/query.ex` → change to a non-query-storage path. `W05` refs (`:33,:42,:52,:73,:104`) → `W03`.
- `dialyzer_ignore_contract_test.exs`: `@fixture_specs` drop `:11`; test name `:25` "five … 40-warning and 22-origin" → four fixtures, 37 warnings, 19 origins; `:33` and `:281-285` expected ids = W03, W04, W06–W40; `:288-289` 40→37, 22→19; `:230` "exactly five fixtures"; `:107-108` README strings; `:236` keep `sealed_run.warning_count == 40` (provenance). README `:3,:7,:28`, steps text.

### TS critic (C2)
- Lock regen (in `examples/threadline_phoenix/e2e`): edit `package.json`, then `npm install --package-lock-only --ignore-scripts --no-audit --no-fund`, then `npm ci --ignore-scripts` to prove it installs. Verify the diff is removal-only: `python3 -c` comparing `packages` keys before/after must equal the 9 names above. CI uses npm from Node 22.14 (npm 10.x); lockfileVersion stays 3 [VERIFIED: lock `lockfileVersion` = 3]. `verify-test` and `verify-example-browser` both `npm ci` and key caches on `hashFiles('examples/threadline_phoenix/e2e/package-lock.json')` — first post-merge runs are cold (D-25 already defers measurement).
- `package.json` scripts after: `test`, `test:headed`, `test:unit` (`tsx --test support/operator-surface-paths.test.ts`), `test:paths` (C3 also drops all `capture:*`).

### CI contract edits (C3) — exact sites
- `ci_workflow_parity_contract_test.exs`: `@time_to_red_order` `:1298-1301` drop `verify-capture`; `@ci_check_names` `:1379`; `@ci_job_ids` `:1747-1767` (comment "the 14 ci.yml job ids" → 13); name-jargon controls `:1175-1178` repoint `rename.("verify-capture", …)` to `verify-example-browser`; `@retired_check_names` `:1392-…` add `"Capture evidence byte-stable"` (recommended so the old check name cannot silently reappear); `@build_cache_jobs` `:2399-2400` and the exact-set assertion `:2633-2636`; `remove_build_cache_section_row(…, "verify-capture")` `:5027-5028` → repoint to `verify-example-browser`; controls `:5093-5097` (`@capture_consumer` `:4901`), `:5372-5377`, `:5390-5395`, `:5437-5445` → repoint to `verify-example-browser` (its consumer step is `Run example Playwright suite`); `build_cache_fixture` `:5482` drop `fixture_example_consumer_job(:capture)`; delete `fixture_consumer_parts(:capture)` `:5891-…`; fixture CONTRIBUTING table row `:5557`; comments `:4561`, `:5813`; consumer regex `:4553` may keep `capture` alternative or drop it.
- `ci_topology_contract_test.exs:1262-1440`: delete `@byte_stable_step`, `@mechanical_checker_test`, the capture checks in `removed_proof_errors/3`, the `checker_test` parameter and its mutation controls; add `"verify-capture"` to `@removed_job_ids` (then `removed_job_checks/2` requires the id gone from keys/header/needs, a `# Removed: verify-capture` comment in ci.yml, and a CONTRIBUTING bullet containing "still caught by" and `` `verify-capture` ``). The `verify-mechanical` bullet's "still caught by `verify-test` … mechanical_checker_test.exs" becomes false — restate it with the D-02 still-caught-by targets. Amend the CONTRIBUTING intro sentence ("A CI proof is removed only when another job catches the same failure class…") to admit a deliberate, recorded coverage cut (D-02), or the section contradicts itself.
- `browser_full_projects_contract_test.exs`: `@live_browser_full ~w(route-capture)`, `@live_ci ~w(desktop-chromium mobile-chromium)`, `@live_deps []`, `@stated_prerequisites %{}`; test names `:117` ("eight"→"three"), `:122`; `:161-186` executed-equals-browser-full; mutation controls that depend on the live refute→tier-a edge (`:317-331`, `:333-347`) and on the live `mix verify.capture` alias (`:275-287`), job-level `if:` on `verify-capture` (`:444-461`), `Regenerate Tier A capture` step text (`:463-497`) → rebuild each on synthetic mutations of the copied inputs (e.g. inject a project + `dependencies` edge, inject a `mix verify.fixture` alias whose defp carries `--project=` flags). Keep the script's mix-alias resolution feature tested.
- `browser_journey_evidence_contract_test.exs:78` → `String.split(test_workflow, "\n  verify-example-browser:\n", parts: 2)`.
- `hex_pin_contract_test.exs:31-34` `@live_pin_count 17` → `16` (comment "ci.yml 11" → 10).
- `retry_network_contract_test.exs:593-595,:610` → "13 … ci.yml 9", `length(wrapper_form) == 12`.
- CONTRIBUTING: CI Coverage `:557-615` (table to 3 projects + light row; prose "four"/"other four"; the dependency-edge paragraph `:582-587`; "flags plus those behind `mix verify.capture`" `:607-608`), needs roster `:639`, job table `:851`, removed-proofs `:857-868`, build-cache table `:962`, shared-key sentence `:1021`, check-name list `:1109`.

### Browser-full one-project shape — landmine
After C3, `bin/browser-full-projects` yields `--project=route-capture` only. In `operator-page-capture.spec.ts` every test except the legacy one self-skips unless `THREADLINE_E2E_EVIDENCE=1` (`:387`, `:419`), and Browser-full never sets it [VERIFIED: grep of browser-full.yml]. Deleting the legacy test (`:434-449`) leaves Browser-full running 0 tests / 12 skipped on every push to main: a vacuous green lane, which is the "orphaned capture project" SC4 forbids. The legacy test is a real render smoke (login, then every inventoried route × 375/768/1280 waits for `#tl-main` visible). It is also the identity of the "Browser-full" nonvoting row in `e2e/support/operator-journey-inventory.json:38`, and `browser_journey_evidence_contract_test.exs:35` requires a nonvoting reason mentioning "Browser-full". **Recommendation: keep the legacy test, strip its critic comments and rename it** (for example "renders every inventoried route at 1280/768/375"); update the checklist probe `state.probe.148e460d0b28` anchor and the journey-inventory titlePath in the same commit. That is a one-line amendment to D-03 and needs a confirm.

### Fixture/ledger prune (C4)
- Ledger: python one-off (`python3 -I`, script kept in scratch, not committed) dropping top-level `critic_trust`, `critic_trust_provenance`, `critic_panel`, `mechanical_auto_apply`, `mechanical_floors`, `ratchet.signoffs`, every entry's `scores`, and the 14 entries whose id starts `refute.`; write with `json.dumps(d, indent=2, ensure_ascii=False) + "\n"` (proven byte-exact round-trip). `cube_axes` (personas/lens weights) only serves the Scorecard Cube and `stress_ledger_test:457`; D-04 does not list it. Recommend dropping it too, as an open question.
- `stress_ledger_test.exs` (533 lines): `@top_level_keys :12-26`, `@entry_keys`, `@synthetic_set_path :10`, `@design_sections :61-72` ("Scorecard Cube", and "Ratchet Rule" if that section goes; keep "Capture Matrix" only if a Tier-C-only section remains), and tests `:121` (ratchet upward), `:150-205` (refute entries), `:240-255` (graded in synthetic set), `:355-364` (Scorecard Cube), `:380-456` (per-cell scores/evidence_ref), `:457-475` (cube_axes), `:476-…` (signoff floors); keep `inventory_row/1` (uses `current_score`/`target_score`, which stay).
- `operator_surface_fixture_contract_test.exs`: synthetic `tracked` map `:16-30`, `require_corpus_entries` `:174-180`, `validate_corpus`/`validate_references`, `ledger_references(%{"mechanical_floors" => …})` `:298`; the live test `:63-74` stays (manifest == tracked, non-vacuous with 1 entry).
- `rendered_output_contract_test.exs:65` `@reference_manifest_entry_count 427` → 1. **Its control `validate_reference_manifest(tl(manifest), tracked)` (`:391`) becomes `validate_reference_manifest([], tracked)`, which returns `{:error, :empty_manifest}` instead of the asserted `:path_set_mismatch`.** Rebuild that control (for example append a synthetic extra manifest row instead of dropping one).
- Manifest regen: `git ls-files -z -- test/fixtures/operator_surface` minus `README.md`, `manifest.sha256`, `route-inventory.json`, `source-surface-checklist.json`, sorted, `"<sha256>  <path>\n"` (`operator_surface_fixture_contract_test.exs:320-345`). After C4 it is one line: `design-system-ledger.json`. Stage the deletions first; the contract reads the git index.

## Debt re-checks delegated to the planner

| Item | HEAD evidence | Recommended disposition |
|---|---|---|
| 216 IN-01 (cache key label never compared with `runs-on`) | still open: `key_value_errors/3` `ci_workflow_parity_contract_test.exs:3724-3741` accepts any `ubuntu-24.04-`/`${{ matrix.runner }}-` lead; `job_toolchain_errors/2` `:3799-3807` has the block in scope. All 28 literal `runs-on:` today are `ubuntu-24.04` (+1 `${{ matrix.runner }}`) | **fix** (test-only, 1 file, ~15–25 lines incl. one mutation control `runs-on: ubuntu-26.04` with an unchanged key → D-17-cheap). Land after C3 as its own commit. If it exceeds 30 net lines when written, waive ("low value: every runs-on is ubuntu-24.04 and resolved OTP/Elixir segments bound the damage") |
| 216 IN-03 (token in argv; GNU-only sed) | still present: `CONTRIBUTING.md:1205` `--token="$(gh auth token)"`, `:1207` `sed "s/\x1b\[[0-9;]*m//g"` | **route → v1.48**: it has a credential angle and is not test-only, so D-17 forbids a waiver. Whether release-please's CLI reads the token from the environment is unverified [ASSUMED] |
| 216 IN-04 (toolchain-pin comment ×3) | still 3 copies: `grep -c 'setup-beam reads .tool-versions from the workspace' release.yml` = 3 (`:142`, `:492`, third) | **waive**: the fix edits `.github/workflows/` (not D-17-cheap); comment drift only |
| 215 WR-09 (deps-health-report suppression mirror has no live proof) | still open: `bin/deps-health-report` has no `--self-test`; `read_global_hex_ignore` duplicated `bin/deps-health-report:170`, `bin/verify-deps-audit:335` | **route → v1.51 with WR-10**: WR-09 fix option (a) *is* the WR-10 dedupe (then `bin/verify-deps-audit --self-test` case (c) proves both). Silent "clean under suppression" is a security-relevant miss, so it cannot be waived |
| 218 WR-03 (`broken-upstream` on dispatch) | unchanged by design: `bin/ci-sha-gate:32-36` "`broken-upstream` is not event-scoped (D-04)…"; pinned by `ci_sha_gate_contract_test.exs:106-110`; 218 deferred-items: "WR-03, maintainer call: … This is left as locked." | **waive** ("locked maintainer decision 218 D-04; the refusal is the designed behavior and is contract-pinned"). D-19's "close if REL-02 observed" test does not apply: WR-03 is about the flake lane, not release PRs. Flag the deviation from D-19's wording |
| ECON-03 (one CI run per release PR, unconfirmed) | `244-REL02-EVIDENCE.md:3` `Status: pending — bound to the first natural release cycle after this phase lands` | **route → v1.48** (same trigger as the REL-02 observation; add to QUALITY-ROADMAP v1.48 per D-23) |
| 221 BASH_ENV advisory | rule present: `ci_workflow_parity_contract_test.exs:1856` `rule=gate-bash-env: no workflow may carry a literal \`BASH_ENV\` key`; the 221 VERIFICATION resolution "reword the gate-bash-env comment to say it covers key-spelled BASH_ENV only" is done at `:1793-1796` ("A lane can still reach `BASH_ENV` through an expression-valued `env:` or a `$GITHUB_ENV` write; that cannot touch the gate…") | **close** |
| 215 WR-07 / IN-01 / IN-02 (D-18 "close") | confirmed: `bin/upsert-ci-issue:10` "1 match, title differs -> issue edit N --title"; close step `deps-health.yml:116-134`; classification via `env: CLASSIFICATION` `:85`; here-strings `grep -q … <<<"$…"` `bin/verify-deps-audit:167,195,217` | close (cite these lines) |
| 231 WR-01 stale disposition row | `231-REVIEW-DISPOSITION.md:10` (frontmatter `id: WR-01`) and table `:32` `\| WR-01 \| warning \| open \| 231-REVIEW.md \|`; fixing commit `d56e807c fix: handle malformed actor references safely (#81)` | hand-edit both to `fixed`, Source `d56e807c (#81)`; check 233/234 disposition files for the same pattern |
| WINDOWS row 7 (CR-05) | `bin/verify-branch-protection` has no `bypass` string; ruleset `:5` `"bypass_actors": [],` | route → v1.48 (D-20 holds) |

D-20 buckets re-derived from the WINDOWS JSON block (`````json` fence, 67 entries): open = 60, ids `1, 3–57, 61–64`; the five D-20 buckets total 21 + 26 + 7 + 5 + 1 = 60, pairwise disjoint, with no open id missing [VERIFIED: python parse of `.planning/WINDOWS.md:86-935`]. Frontmatter today: `open_count: 60`, `waived_count: 1`, `fixed_count: 6`, `total_count: 67`.

## D-16 fix sketches (all D-17-cheap)

| # | Site (verified) | Minimal change | Net lines / files |
|---|---|---|---|
| 215 WR-04 | `deps_health_doc_contract_test.exs:381-386` `refute ruleset =~ "Dependency Health"`; job name `deps-health.yml:43` `name: Daily hex.audit (Mix lockfiles)`; ruleset contexts `[{'context': 'CI required', 'integration_id': 15368}]` | pure helper `required_context_hits(ruleset_json, job_name)` (Jason-decode the ruleset, collect `rules[].parameters.required_status_checks[].context`, return those equal to the name); read the job name with `YamlElixir.read_from_string!(yaml)["jobs"]["deps-health"]["name"]`; assert `[]` live, plus a negative control with a ruleset whose context list includes the job name → non-empty; assert the job name is non-empty (non-vacuity) | ~+18 / 1 |
| 215 WR-05 | `@lockfiles` `:45`; test `:158-166`; helper `canonical_dir_line!/1` `:60-67`; `CANONICAL_DIRS=(. bench examples/threadline_phoenix)` (`bin/deps-health-report:102`) | `lockfiles = canonical_dir_line!(@verify_deps_audit) |> String.split() |> Enum.map(fn "." -> "mix.lock"; d -> d <> "/mix.lock" end)`; assert `length >= 3` | ~+5 / 1 |
| 215 WR-06 | `deps_audit_gate_test.exs:322` `String.trim(log) == "#{root}\|hex.info" or String.contains?(log, "\|hex.info")`; `:637` `_ = pwds`; `:650-652` `String.ends_with?` | exact: assert the log's command column list `== ["hex.info"]` (split each line on `"\|"`, take the command), `refute log =~ "deps.unlock"`; delete `pwds`/`_ = pwds`; `assert dir_pwds == [real_root, Path.join(real_root, "bench"), Path.join(real_root, "examples/threadline_phoenix")]` (confirm `real_root` is already canonical, since macOS temp paths resolve through `/private`) | ~+4 / 1 |
| 215 IN-03 | `deps_health_report_test.exs:947` `refute after_report == nil`; `deps_health_doc_contract_test.exs:362-379` | delete both; rename the now-unused binding at `:938` to `[_, _]` or the warning breaks a `--warnings-as-errors` compile | −20 / 2 |
| 223 IN-01 | `CONTRIBUTING.md:144-145` (D-18 sentence spans a newline); `:1191` (D-06 sentence) | `repo_hygiene_contract_test.exs`: normalise whitespace (`String.replace(contributing, ~r/\s+/, " ")`) and assert it contains "no file or directory is exempt from the scan other than the allowlist's own literal column"; `changelog_contract_test.exs` (reads no CONTRIBUTING today): assert it contains "must merge under a releasable squash subject" and "`BEGIN_COMMIT_OVERRIDE`" | ~+14 / 2 |

## WINDOWS mechanics (read from `~/.claude/gsd-core/bin/lib/broken-windows.cjs`, not invoked)

- Router: `gsd-tools.cjs` `'windows': routeWindows` (`:4858`), subcommands `status | append | waive | fixed` (`:3426-3442`).
- `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows fixed <id>`: exactly one positional (`cmdWindowsMarkFixed`, `:1068-1088`); **takes no reason**, so fixed rows cannot cite the register (the register row carries the evidence).
- `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows waive <id> "<reason>"`: two positionals (`cmdWindowsWaive`, `:1044-1066`); an empty reason throws `windows_waive_reason_empty`; **a reason starting with `--` is parsed as an unknown flag** (`parseArgs`, `:1107-1112`), so start reasons with a word.
- Both call `assertOpen`, so a second call on the same id throws `windows_already_resolved`. A re-run after a partial batch is safe only for the remaining ids. Both take the ledger lock and recompute the frontmatter counts.
- The ledger has **no `routed` status**. Rows 7, 14–17 and 62 are written with `waive` and a reason such as `routed to v1.48 per 246-DEBT-REGISTER.md#W7` (the register disposition stays `routed`).
- Run from the worktree root (`cwd` resolves `.planning/WINDOWS.md`), one call at a time, on a clean WINDOWS.md; then commit WINDOWS.md alone and assert `open_count: 0`. Schedule this task **last** among the planning writes, after every executor that could log a deviation, and re-check `open_count: 0` in the gate.

## D-15 close check (adapting 222's precedent)

Precedent: `.planning/milestones/v1.43-phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh` (275 lines; `set -euo pipefail`; `pass`/`fail`/`run`/`run_out_contains` helpers; `MODE` `""|--close`; read-only, with an `mktemp` scratch removed by trap; `--close` greps SEED frontmatter, REQUIREMENTS lines and a protected-path `git diff`; a machine-path grep (user-home, `/home/<x>` and home-relative shapes; copy the regex from the 222 script itself rather than retyping it into prose) that fails closed on grep exit 2). Its `P=.planning/phases/222-…` literal broke when the phase was archived to `milestones/`. **Derive `P` from `SCRIPT_DIR/..` instead.**

New script: `.planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh --close`, with checks:
1. `246-DEBT-REGISTER.md` exists; its frontmatter `closed`/`waived`/`routed`/`total` counts equal the counts of table rows by disposition column.
2. Every row's disposition ∈ {`closed`, `waived`, `routed`} and its reason cell is non-blank.
3. Every `routed` row's reason matches `v1\.(48|49|50|51)\b|SEED-[0-9]{3}`.
4. WINDOWS: parse the `````json` block (`python3 -I`); zero entries with `status == "open"`, and the frontmatter reads `open_count: 0`.
5. The set of `W<id>` rows equals the 60 ids D-20 enumerates; every non-W id from D-00a..c and D-18/D-19 is present (literal list in the script).
6. The refined D-09 grep's hit set ⊆ a literal allowlist (`file` or `file:regex`) kept in the script.
7. SEED-005 has `status: closed`, `closed_on:`, `closed_during: v1.47 Phase 246`, `closed_reason:`, and no `**Status:** Open`; SEED-008 exists with `reopen_when:`.
8. A machine-path and username grep over the phase directory and the two seeds, failing closed on grep exit 2. Build the username pattern at runtime (`$(id -un)`), never as a literal.

## Gate mechanics (D-24)

- **Ephemeral postgres:16** (245-05 recipe, `245-05-SUMMARY.md:81`): `docker run -d --rm --pull never --label dev.threadline.kind=gate-db --label owner-pid=$$ -e POSTGRES_PASSWORD=postgres -p 127.0.0.1::5432 postgres:16`; read the port with `docker port <id> 5432/tcp`; poll `pg_isready -h 127.0.0.1 -p $PORT` for up to 60 s; `trap 'docker rm -f <id>' EXIT INT TERM`; run `DB_HOST=127.0.0.1 DB_PORT=$PORT CI=true mix ci.all`, logging to a scratch file and then stripping ANSI before grepping. Afterwards assert `docker ps -a --filter label=dev.threadline.kind=gate-db -q | wc -l` is 0. Config reads `DB_HOST`/`DB_PORT` (`config/test.exs:6-7`; the example app's `config/test.exs:16-17`); user/password are `postgres`. Hex must report 2.6.0 (`mix local.hex 2.6.0 --force` if not, as 244 did). A Dialyzer red usually means a PLT cache miss: `mix dialyzer --plt`.
- **Latest recorded browser numbers.** The CI-mode lane inside `CI=true mix ci.all` (desktop + mobile) was `418 passed / 0 failed / 64 skipped` (`245-05-SUMMARY.md:99-103`). The "326/8/16" standalone baseline in memory is stale: no v1.46/v1.47 artifact records a standalone run.
- **Expected after C1–C4** [ASSUMED: derived by counting tests, not run]:
  - CI mode: `418 / 0 / 54` (−10 skips: tier-a, refute, graded, storybook, legacy page-capture × 2). If the legacy test is kept: `418 / 0 / 56`.
  - Standalone `mix verify.example_browser` (no `CI`, all default projects, now `desktop-chromium`, `mobile-chromium`, `route-capture`): `420 passed / 8 failed / 56 skipped` without the legacy test, or `421 / 8 / 58` with it. The screenshot-regression spec adds 10 tests per desktop+mobile pair (8 failing at `:108/:115/:136/:145`, 2 passing at `:101`). `route-capture` adds 12 evidence-only skips.
  - Record the measured numbers, not these predictions.
- **Do not run the bare `mix verify.example_browser` before C3 lands.** With the capture projects still registered, it runs `tier-a-capture`/`graded-capture`/`storybook-capture`, which rewrite the committed `test/fixtures/operator_surface/scorecards/` and dirty the tree. Pre-removal baselines must pass `--project=desktop-chromium --project=mobile-chromium`.
- **Other gate items:** the refined D-09 grep (above), `tools/verify-phase.sh --close`, `bin/verify-repo-hygiene` (exit 0), `mix verify.credo`, and the D-14 tag commands at landing time only.

## Runtime State Inventory

| Category | Items found | Action |
|---|---|---|
| Stored data | about 1,066 machine-local `.planning/critic-*` cache files in the main checkout (none in this worktree); possible local `test/generated/operator_surface/{critic-scores,critic-verdict-cache,reports,refute-transcripts,route-scorecards}/` output; `e2e/artifacts/{tier-a,storybook,graded}/` PNGs | none: all stay ignored (D-07 keeps `.gitignore:64-76`; root `.gitignore` ignores `/examples/threadline_phoenix/e2e/artifacts/` wholesale, so dropping `e2e/.gitignore:5-7` changes nothing) |
| Live service config | GitHub ruleset requires only `CI required` (`main.json` context list); Actions caches keyed on the old `package-lock.json` hash; `ci-browser-full` issue label | none: caches age out (7 days); no ruleset change (D-26). A repo secret named `ANTHROPIC_API_KEY` may exist [ASSUMED: not checked, no `gh` call made]. No workflow references it (guarded), so deleting it is an optional maintainer tidy-up |
| OS-registered state | none: no launchd/cron/pm2 entries reference the critic (it was only ever invoked by hand) | none |
| Secrets/env vars | maintainer-local `ANTHROPIC_API_KEY`, read only by the deleted `verify_ui_critique/1` (`mix.exs:453`) and the TS critic | none (code edit only) |
| Build artifacts | `e2e/node_modules` holds the 9 removed packages until `npm ci`; `_build/test/lib/threadline/ebin` stale beams for deleted modules (Mix prunes them on recompile); `_build/critic-trust-path-tests/` leftover dir (gitignored, under `_build`); `.dialyzer` PLTs are deps-only | run `npm ci --ignore-scripts` after C2; nothing else needed |

## Common Pitfalls

1. **Paths-field removal before spec deletion** breaks `playwright test --list`, and with it ExUnit (`browser_journey_evidence_contract_test`) plus every browser lane. Warning sign: `TypeError … undefined` at collection.
2. **Removing `verify.capture` without the tier-a projects**: `bin/browser-full-projects --list browser-full` silently grows by two projects. Removing `tier-a-capture` while `refute-capture` keeps its dependency edge exits 1.
3. **Manifest regenerated from the working tree instead of the index**: the contract compares against `git ls-files`, so stage deletions first.
4. **Dialyzer slice controls inverting**: `query.ex` changes from out-of-bound to authorized.
5. **`tl(manifest)` with a 1-entry manifest** hits the empty-manifest branch (`rendered_output_contract_test.exs:391`).
6. **Unused binding after deleting `refute after_report == nil`**: rename it, or `--warnings-as-errors` fails.
7. **WINDOWS writes**: `fixed` takes no reason; a `--`-leading reason is rejected; a stray executor `windows append` re-opens the count. Run WINDOWS writes last, alone.
8. **Repo hygiene in prose**: the register, seeds and tag annotation must carry no home-path shapes or the username. Use `<scratch>`-style placeholders and `$(id -un)` only at runtime.
9. **Squash revertability**: any non-critic hunk inside C1–C4 makes `git revert <squash>` restore unrelated code. Keep D-16, IN-01 and planning commits out of the range.
10. **The contradictory "Removed CI proofs" intro**: it claims every removal is still caught elsewhere. Amend it alongside the D-02 bullets.

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | Predicted browser numbers (CI 418/0/54 or 56; standalone 420/8/56 or 421/8/58) | Gate | low: re-measured at the gate; only the "8 failed, same 4 tests × 2" invariant is load-bearing |
| A2 | release-please's CLI can take the token from the environment (the 216 IN-03 fix path) | Debt re-checks | none for this phase (the item is routed) |
| A3 | An `ANTHROPIC_API_KEY` repo secret may exist | Runtime state | none: optional tidy-up |
| A4 | A 216 IN-01 fix fits in ≤30 net lines | Debt re-checks | low: fallback waive reason given |
| A5 | npm 11 locally and npm 10 in CI produce and consume a compatible v3 lock for a removal-only diff | TS critic | low: `npm ci` runs in `verify-test` on the first PR run and fails loudly |

## Open Questions

1. **Keep the legacy page-capture test?** Its deletion leaves Browser-full running only skipped tests and orphans the journey-inventory identity. Recommendation: keep it, renamed and with comments stripped (one-line D-03 amendment). Needs one confirm.
2. **218 WR-03 disposition wording.** D-19 frames it with ECON-03/REL-02, but the evidence says it is a locked maintainer decision unrelated to release PRs. Recommendation: waive with the 218 D-04 reason (or route to v1.48 to follow D-19 literally).
3. **`cube_axes` and the `ratchet.{locked_ids,minimum_scores,resets}`/`ratchet_rule` keys.** Recommendation: drop `cube_axes` with the Scorecard Cube in C4. Keep the ratchet keys if the DESIGN-SYSTEM inventory rows (`current_score`/`target_score`) keep their meaning.
4. **216 IN-01: fix or waive?** Fix if the code stays within D-17. Decide at task time against the 30-line cap.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|---|---|---|---|---|
| Docker + `postgres:16` image | ephemeral gate DB | ✓ | local image present | none needed |
| `pg_isready` | gate readiness poll | ✓ | Homebrew | `docker exec … pg_isready` |
| Node / npm | lock regen, `npm run test:unit` | ✓ | 22.14.0 / 11.1.0 | — |
| Playwright CLI + Chromium | browser lanes, `--list` contract | ✓ | `node_modules/.bin/playwright`; chromium-1200/1212 cached | — |
| Dialyzer PLTs | `verify.dialyzer_slice` | ✓ | `.dialyzer/dialyxir_erlang-27.3.4.15_elixir-1.17.3_deps-dev.plt` | `mix dialyzer --plt` |
| Elixir/OTP | everything | ✓ | `.tool-versions`: elixir 1.17.3-otp-27, erlang 27.3.4.15 | — |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|---|---|
| Framework | ExUnit (Elixir 1.17.3) + Playwright (`@playwright/test` 1.60.0 in lock) + `tsx --test` |
| Config | `test/test_helper.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| Quick run | `mix test <files>` (see the per-commit commands above) |
| Full suite | `CI=true mix ci.all` on an ephemeral postgres:16 |

### Phase Requirements → Test Map
| Req / SC | Behavior | Type | Automated command | Exists? |
|---|---|---|---|---|
| DEBT-02 / SC3 | no live critic references | grep | refined D-09 grep ⊆ allowlist (`tools/verify-phase.sh --close` check 6) | ❌ Wave 0 (script) |
| DEBT-02 / SC3 | restoration tag carries the code | one-off | `git ls-tree -r --name-only archive/ui-critic-loop \| grep -c lib/threadline/critic_trust/` > 0; `git merge-base --is-ancestor archive/ui-critic-loop origin/main`; `git ls-remote --tags origin archive/ui-critic-loop` | landing-time only (D-14) |
| DEBT-02 / SC3 | CONTRIBUTING Retired pointer names the tag | doc contract | `mix test test/threadline/<retired_pointer>_doc_contract_test.exs` | ❌ new (replaces `critic_iteration_runbook_doc_contract_test.exs`) |
| DEBT-02 / SC4 | CI roster/topology consistent | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs` | ✅ (edited) |
| DEBT-02 / SC4 | no orphaned capture project | script + contract | `bin/browser-full-projects --list config` = `desktop-chromium mobile-chromium route-capture`; Browser-full executes ≥1 test (legacy test kept) | ✅ |
| DEBT-02 / SC4 | partition list has no deleted file | script | `awk '{print $2}' test/partition_weights.txt \| grep -v '^#' \| while read f; do [ -e "$f" ] \|\| echo "$f"; done` prints nothing | ❌ add as close-check line |
| DEBT-02 / SC4 | Hex tarball still excludes stress tooling | contract | `mix test test/threadline/release_artifact_contract_test.exs` | ✅ |
| DEBT-02 / SC4 | honest-default docs true | contract | `mix test test/threadline/ci_topology_contract_test.exs` (default-excluded tags) + `mix verify.test` | ✅ |
| DEBT-02 / SC4 | green suite + browser | full | `CI=true mix ci.all`; standalone `mix verify.example_browser` = N/8/M with the same 8 tests | ✅ |
| DEBT-01 / SC1 | every row dispositioned, routes named, WINDOWS 0 open | script | `bash .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh --close` | ❌ Wave 0 |
| DEBT-01 / SC2 | the five cheap findings fixed | unit/contract | `mix test test/threadline/deps_health_doc_contract_test.exs test/threadline/deps_audit_gate_test.exs test/threadline/deps_health_report_test.exs test/threadline/repo_hygiene_contract_test.exs test/threadline/changelog_contract_test.exs` | ✅ (edited) |
| DEBT-01 / SC2 | WR-04 guard is not vacuous | mutation | its negative control (a ruleset context = job name → non-empty) inside the test | ❌ new control |

### Sampling Rate
- **Per commit:** the targeted command in the commit table + `mix compile --warnings-as-errors` + `mix verify.format`.
- **Per wave:** `mix verify.test` on the ephemeral DB.
- **Phase gate:** `CI=true mix ci.all`, standalone `mix verify.example_browser`, the close check, the refined grep, `bin/verify-repo-hygiene`.

### Wave 0 Gaps
- [ ] `.planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh` (close check, incl. the partition-row existence line)
- [ ] the retired-pointer doc contract test (in C2)

## Security Domain

| ASVS Category | Applies | Control |
|---|---|---|
| V14 Configuration / supply chain | yes | the dependency surface shrinks (9 npm packages incl. `@anthropic-ai/sdk` leave); the paid-key resurrection guard stays (`ci_topology_contract_test.exs:674-695`, reworded) |
| V1/V10 Build integrity | yes | `exclude_patterns` removed only together with their files (D-06), so nothing ships in between; `release_artifact_contract_test` proves it against the unpacked tarball |
| V2/V3/V4/V5/V6 | no | no auth, session, access, input or crypto code changes |

| Threat | STRIDE | Mitigation |
|---|---|---|
| A pattern removed before its file, shipping tooling to Hex | Information disclosure | same-commit rule; tarball contract |
| A required-check promotion of the deps-health lane going unseen | Tampering | the WR-04 real guard + negative control |
| A routed credential item (216 IN-03, MIX_HOME T-215-36, WR-09) dropped | Repudiation | route, never waive (D-17); the close check enforces named routes |

## Sources

### Primary (HIGH, read this session)
- Every file:line in the anchor, coupling, debt and fix tables above, read at HEAD `4f52ef4c`
- `~/.claude/gsd-core/bin/lib/broken-windows.cjs:270-310, 1000-1143`; `gsd-tools.cjs:3426-3442, 4858`
- `.planning/WINDOWS.md` JSON block (parsed)
- `.planning/milestones/v1.43-phases/{215,216,218,221,222,223}-*/` review, deferred and verification files
- `.planning/phases/{244-release-flow,245-supply-chain}/` summaries, verification and REL02 evidence

### Secondary / Tertiary
- None. No web sources were needed: the phase is entirely in-repo.

## Metadata

**Confidence:** anchors and couplings HIGH (read); commit plan HIGH (each coupling has a cited contract line); browser predictions MEDIUM (counted, not run).
**Research date:** 2026-10-25. **Valid until:** the next commit that touches ci.yml, playwright.config.ts or the fixture corpus. Re-run the refined grep before planning if HEAD has moved.
