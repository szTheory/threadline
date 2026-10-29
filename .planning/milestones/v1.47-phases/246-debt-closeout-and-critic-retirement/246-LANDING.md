---
phase: 246-debt-closeout-and-critic-retirement
artifact: 246-LANDING.md
milestone: v1.47
requirements: [DEBT-01, DEBT-02]
generated: 2026-10-25
---

# Phase 246 · Landing hand-off

This is the maintainer's copy-paste guide for two steps: landing the critic-removal squash PR
and creating and pushing the `archive/ui-critic-loop` tag. No executor in this phase created
or pushed a tag, pushed a branch or opened a PR (D-13). `.planning/ARCHIVE-REGISTER.md` is
unchanged; its row is applied at landing.

## Gate evidence

The D-24 phase gate ran on 2026-10-25 against the final code tree (HEAD `8eb54275`, after
C6). It used an ephemeral `postgres:16` with label `dev.threadline.kind=gate-db`, a random
loopback port and trap removal; the 245-05 recipe is in `<scratch>/gate-246.sh`. Logs were
ANSI-stripped before grepping. Hex reported 2.6.0, so no `mix local.hex` was needed.

| gate step | command | result |
|-----------|---------|--------|
| WINDOWS ledger | `node <home>/.claude/gsd-core/bin/gsd-tools.cjs windows fixed/waive …` (60 calls, commit `602e358f`) | `open_count: 0`; fixed 27, waived 40, total 67 |
| full CI aggregate | `DB_HOST=127.0.0.1 DB_PORT=<port> CI=true mix ci.all` | **exit 0** on run 2 (run 1 was red; see below) |
| standalone browser lane | `DB_HOST=127.0.0.1 DB_PORT=<port> mix verify.example_browser` | **419 passed / 10 failed / 58 skipped** (exit 1, as expected for this lane) |
| D-15 close check (incl. the D-09 grep) | `bash .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh --close` | `verify-phase: all checks passed` |
| repo hygiene | `bin/verify-repo-hygiene` | exit 0 |
| container cleanup | `docker ps -a --filter label=dev.threadline.kind=gate-db -q \| wc -l` | 0 |

**`CI=true mix ci.all`, run 2 (decisive lines):**

```
5565 mods/funs, found no issues.
verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0; 0 non-blocking finding(s))
32 properties, 3328 tests, 0 failures, 3 excluded        (library)
132 tests, 0 failures                                    (example app)
Total errors: 0, Skipped: 0, Unnecessary Skips: 0        (Dialyzer)
17 tests, 0 failures, 16 excluded
  3 flaky
  56 skipped
  415 passed (6.0m)                                      (CI browser lane, 0 failed)
```

The three flaky tests passed on retry:
- `operator-accessibility.spec.ts:1332`, desktop
- `operator-motion.spec.ts:246`, desktop
- `operator-motion.spec.ts:246`, mobile

RESEARCH predicted the CI lane at 418/0/56. The measured 415 passed + 3 flaky = 418 tests
that ran, with 56 skipped, which matches.

**Run 1 was red, and that is how C6 came about.** Run 1 of `ci.all` failed in the browser
lane with 1 failed, 1 flaky, 56 skipped and 416 passed. The failure was
`operator-accessibility.spec.ts:1281` on desktop ("closes the focused menu before its drawer
and recovers from removed or disabled controls"). The toast close button never took focus.
Investigation:
- **Targeted reruns.** The failure reproduced 3 of 3 times at HEAD. It passed at `614cb1fd`,
  the tree before the slices.
- **Bisect.** `1258c014` (C3b) passed; `35243789` (C4) and `61f58954` (C5) failed.
- **Cause.** C4 pruned the stress ledger. That changed the stress page's timing, so the
  drawer's asynchronous `JS.focus` chain landed on `[data-tl-initial-focus]` after the test
  had already called `toastClose.focus()`.
- **Fix.** Commit `8eb54275`
  (`chore: wait for drawer initial focus before focusing the stress toast`, trailer
  `Removal-Slice: C6`) waits for the drawer's initial focus first. It passed 10 of 10
  (`--repeat-each=5`, desktop and mobile).
- **What changed.** The fix touches only the test. No product code, no screenshot baseline and
  no guard changed.

**Standalone `mix verify.example_browser`, run 2:** 419 passed / 10 failed / 58 skipped. The
failures:

| spec | line | desktop-chromium | mobile-chromium |
|------|------|------------------|-----------------|
| `operator-screenshot-regression.spec.ts` | :108 | failed | failed |
| `operator-screenshot-regression.spec.ts` | :115 | failed | failed |
| `operator-screenshot-regression.spec.ts` | :136 | failed | failed |
| `operator-screenshot-regression.spec.ts` | :145 | failed | failed |
| `operator-screenshot-regression.spec.ts` | :101 ("global chrome and Home workflow launchers") | failed | failed |

The first four rows are the 8 known failures (:108/:115/:136/:145 on desktop and mobile).
The two `:101` failures are **not caused by this phase**:
- They also fail on `614cb1fd`, the tree before the slices.
- They also fail on `origin/main` `23178fb0`. There the full-page Home screenshot is 1274 px
  high against the committed 1281 px desktop baseline, and 2048 px against 2013 px on mobile.
- At HEAD the page is 1407 px and 2412 px.
- RESEARCH assumed `:101` passes, but no v1.46/v1.47 artifact had recorded a standalone run.

The real standalone baseline is therefore **10 failures** on this machine: the four known
pairs plus `:101` × 2. Baselines were not regenerated. The `:101` drift is logged in
`deferred-items.md` for SEED-008, where screenshot baselines are owned, and is routed as
register row `UI-HOME-SHOT-101`; SEED-008 Scope now owns the 10-failure threshold. A failure outside
these 10 is a regression. RESEARCH predicted about 421/8/58 standalone; the measured result
is 419/10/58.

D-25 scope held: no partition re-weighting, per-spec timing, browser-project split,
contract-lane tagging, time-to-red or CI wall-time measurement was done (Phase 247).
D-26 scope held: no branch-protection or ruleset change was made.

## Removal squash PR (D-12)

### Prerequisites

**1. Why a landing base is needed.** The nine removal slices were authored on top of the
v1.47 Phase 244 and 245 code commits. `origin/main` at plan time (`23178fb0`, still the local
`origin/main` at hand-off) has neither `b7b80289` nor `6912fa96` as an ancestor
(`git merge-base --is-ancestor` exited 1 for both). The slices edit the same files those
phases edit: `.github/workflows/ci.yml`, `.github/workflows/browser-full.yml`, `mix.exs`,
`CONTRIBUTING.md` and the CI contract tests. C3a's `hex_pin` count change (17 → 16) and the
`retry_network` counts assume that base.

**2. Landing order.**
1. Land the v1.47 work that comes before the first slice (`4b2c3f89`) on main first, in its own
   PR. Alternatively, stack the removal PR on that PR's branch and retarget it to main once the
   base merges.
2. The removal PR stays separate (D-12): one revertable, non-releasable `chore:` squash.
3. v1.47 commits made after the slices (246-05 test fixes, the 246 planning commits, and this
   hand-off) land after the removal PR.

**3. Readiness check.** This check compares content, not SHA ancestry. A squash landing
rewrites SHAs, so an ancestry test on milestone SHAs can never pass. The path set is every
path the nine slices touch: the union of the per-slice file lists, computed now with the
loop below. That gives 528 paths, none under `.planning/`. A plain range diff
`4b2c3f89^..e9a97139` would be wrong, because the six 246-05 `test:` commits sit between C5
and C6, and planning commits sit between C6 and C7 and between C7 and C8. Of the 528 paths, 479 are deletions;
their compacted form is the restore list under the archive tag below. The 49 modified or
added paths are:

```
.github/workflows/browser-full.yml
.github/workflows/ci.yml
CONTRIBUTING.md
DESIGN-SYSTEM.md
bin/browser-full-projects
bin/verify-repo-hygiene
examples/threadline_phoenix/e2e/.gitignore
examples/threadline_phoenix/e2e/package-lock.json
examples/threadline_phoenix/e2e/package.json
examples/threadline_phoenix/e2e/playwright.config.ts
examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts
examples/threadline_phoenix/e2e/support/operator-surface-paths.ts
examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts
guides/configuration-and-commands.md
lib/threadline/operator_surface/live/stress_live.ex
lib/threadline/operator_surface/live/stress_live/sections.ex
lib/threadline/operator_surface/stress_fixtures.ex
mix.exs
test/fixtures/dialyzer/README.md
test/fixtures/operator_surface/README.md
test/fixtures/operator_surface/design-system-ledger.json
test/fixtures/operator_surface/manifest.sha256
test/fixtures/operator_surface/route-inventory.json
test/fixtures/operator_surface/source-surface-checklist.json
test/partition_weights.txt
test/support/operator_surface_fixtures.ex
test/threadline/browser_full_projects_contract_test.exs
test/threadline/browser_journey_evidence_contract_test.exs
test/threadline/ci_coverage_doc_contract_test.exs   (C7, C8)
test/threadline/ci_topology_contract_test.exs
test/threadline/ci_workflow_parity_contract_test.exs
test/threadline/dialyzer_ignore_contract_test.exs
test/threadline/dialyzer_slice_contract_test.exs
test/threadline/hex_pin_contract_test.exs
test/threadline/layer_boundary_contract_test.exs
test/threadline/operator_surface/component_contract_test.exs
test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
test/threadline/operator_surface/rendered_output_contract_test.exs
test/threadline/operator_surface/stress_fixtures_test.exs
test/threadline/operator_surface/stress_ledger_test.exs
test/threadline/operator_surface/stress_router_test.exs
test/threadline/public_surface_contract_test.exs
test/threadline/release_artifact_contract_test.exs
test/threadline/retry_network_contract_test.exs
test/threadline/source_size_contract_test.exs
test/threadline/ui_critic_retirement_doc_contract_test.exs
examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts   (C6)
```

The only added file is `test/threadline/ui_critic_retirement_doc_contract_test.exs`.

Run in bash:

```bash
paths="$(for s in $(git log --reverse --format=%H --grep='^Removal-Slice:'); do git show --name-only --format= "$s"; done | sort -u)"
git fetch origin main
git diff --quiet 4b2c3f89^ origin/main -- $paths   # must exit 0 before the removal PR opens
```

**4. Fallback when main has moved on those paths.**
1. On a local landing branch cut from `origin/main`, cherry-pick the nine slices in the order below.
2. On an ephemeral postgres:16, run `mix compile --warnings-as-errors` and then the union of the
   slices' targeted test files (from plans 246-02..04):

```bash
mix test test/threadline/browser_full_projects_contract_test.exs \
  test/threadline/browser_journey_evidence_contract_test.exs \
  test/threadline/ci_coverage_doc_contract_test.exs \
  test/threadline/ci_topology_contract_test.exs \
  test/threadline/ci_workflow_parity_contract_test.exs \
  test/threadline/dialyzer_ignore_contract_test.exs \
  test/threadline/dialyzer_slice_contract_test.exs \
  test/threadline/hex_pin_contract_test.exs \
  test/threadline/layer_boundary_contract_test.exs \
  test/threadline/operator_surface/operator_evidence_contract_test.exs \
  test/threadline/playwright_fail_fast_contract_test.exs \
  test/threadline/public_surface_contract_test.exs \
  test/threadline/release_artifact_contract_test.exs \
  test/threadline/repo_hygiene_contract_test.exs \
  test/threadline/retry_network_contract_test.exs \
  test/threadline/source_size_contract_test.exs \
  test/threadline/ui_critic_retirement_doc_contract_test.exs
```

   For C6, also run `mix verify.example_browser tests/operator-accessibility.spec.ts:1281
   --project=desktop-chromium --project=mobile-chromium`.

3. Open the PR only when both are green.
4. If a cherry-pick conflicts, stop and re-derive the slices. Do not resolve the conflict by hand.

**5. Measured result at hand-off (2026-10-25, read-only).** This used the local
`origin/main` = `23178fb0`; no fetch was run.
`git diff --quiet 4b2c3f89^ origin/main -- $paths` exited **1: not yet satisfied**, as
expected. `git diff --stat` reports 10 files differ (141 insertions, 2395 deletions):

```
.github/workflows/browser-full.yml
.github/workflows/ci.yml
CONTRIBUTING.md
mix.exs
test/partition_weights.txt
test/threadline/browser_journey_evidence_contract_test.exs
test/threadline/ci_topology_contract_test.exs
test/threadline/ci_workflow_parity_contract_test.exs
test/threadline/hex_pin_contract_test.exs
test/threadline/retry_network_contract_test.exs
```

These are the 244/245 edits that main does not have yet. Prerequisite 2.1 makes the check
pass.

### Removal slices (ordered)

From `git log --reverse --format='%H %s' --grep='^Removal-Slice:'`:

| # | slice | SHA | subject |
|---|-------|-----|---------|
| 1 | C1 | `4b2c3f89f1d596721d36fafab49359d8f2279377` | chore: retire critic-trust tooling and its Dialyzer slice |
| 2 | C2 | `cbb804a6186b15a0a6ede315fe8f2d37001a4ee2` | chore: retire the TypeScript critic runner |
| 3 | C3a | `9ea29dc4c3370a08f6fd64cab10db9f4832393a8` | chore: retire capture projects and the verify-capture job |
| 4 | C3b | `1258c014c847d39201e809afe9aeafe87a6da7d6` | chore: retire the mechanical floor |
| 5 | C4 | `35243789040d234dd721642d52c6aa123483bcd7` | chore: prune critic stress stories and the fixture corpus |
| 6 | C5 | `61f589541675db4cab1cfb40be01f5843953abbf` | chore: remove residual references to the retired UI critic loop |
| 7 | C6 | `8eb5427552a1305fe7cac97c2b2b9af1523484d1` | chore: wait for drawer initial focus before focusing the stress toast |
| 8 | C7 | `f57237d6314bfa63c0fa26e17c46ed0a827bbfea` | chore: describe Browser-full route-capture coverage as the code runs it |
| 9 | C8 | `e9a97139504005c2d8797180b622451e9a5b5d33` | chore: refuse the inverted route-scorecard claim and count curated routes exactly |

The slices are not contiguous in history. Two `.planning/` commits sit between C1..C5
(`00048f2e`, docs 246-02; `c2c20837`, docs 246-03). Between C5 and C6 sit the six 246-05
`test:` commits and the 246-06/246-07 planning commits; between C6 and C7 sit the 246-07
close-out, review, verification and gap-planning commits; between C7 and C8 sit the 246-08
docs, 246-09, round-2 review and re-verification commits. Cherry-pick the nine SHAs by
name, never a range.

C6 was added by plan 246-07. The D-24 gate found `operator-accessibility.spec.ts:1281` red
3/3 after C4. Bisect: `1258c014` (C3b) passed; `35243789` (C4) and `61f58954` (C5) failed.
C4's pruned stress ledger changed the stress page's timing, so the drawer's asynchronous
`JS.focus` chain stole focus back from the toast. C6 makes the test wait for the drawer's
`[data-tl-initial-focus]` first, and it then passed 10/10 (`--repeat-each=5`, desktop and
mobile). C6 must travel with C4, or main goes red.

C7 was added by gap-closure plan 246-08. It corrects the Browser-full coverage wording C3a
introduced (review WR-01: the lane renders the 6 curated operator routes at 1280; the
inventory-wide 1280/768/375 route tests run only in evidence mode) and the job display name
(IN-02), and pins the wording with a spec-derived contract in
`ci_coverage_doc_contract_test.exs`. C7 must travel with C3a, so main never carries the
false description.

C8 was added by gap-closure plan 246-10. It fixes the residual of WR-01: the
`playwright.config.ts` route-capture comment had the scorecard writer the wrong way round. The
curated non-evidence smoke is what writes `route-scorecards/`; evidence mode writes per-width
scorecards under its run root instead. It also adopts R2-WR-01 (the spec-derived phrase is now
"5 curated operator routes plus a degraded Timeline twin at 1280", counting the degraded entry
as a twin, not a sixth route) and R2-WR-02 (a regex denylist that refuses both scorecard
inversions and the paraphrases, over block-scoped sources). C8 must travel with C3a and C7.

**No slice touches `.planning/`** (checked per slice; each printed 0):

```bash
for s in $(git log --reverse --format=%H --grep='^Removal-Slice:'); do
  echo "$s $(git show --name-only --format= "$s" | grep -c '^\.planning/')"
done
```

### Landing-branch recipe

```bash
git fetch origin main
git switch -c land/v1.47-critic-removal origin/main   # after the prerequisites hold
git cherry-pick 4b2c3f89 cbb804a6 9ea29dc4 1258c014 35243789 61f58954 8eb54275 f57237d6 e9a97139
```

- Open one squash PR titled `chore: retire the UI critic loop (DEBT-02)`. It is non-releasable:
  release-please cuts no version for `chore:`.
- Keep it separate from the rest of v1.47.
- Merge it as a squash so that one commit, `<removal-squash-sha>`, is the revert target.

## Archive tag (D-11, D-13)

Do this only after the removal squash has merged on main. The tag must never point at a
`milestone/v1.47` commit. Squash landing leaves those commits unreachable from main, so the
target is the parent of the squash on `origin/main`.

```bash
git fetch origin main
SQUASH=<removal-squash-sha>                  # the merged removal commit on origin/main
PARENT=$(git rev-parse "$SQUASH^")           # <parent-sha>
git merge-base --is-ancestor "$SQUASH" origin/main   # must exit 0
git diff --stat "$PARENT" "$SQUASH"          # paste into the message below
```

Tag message draft (D-31 shape). Save it as `<message-file>` and fill in the two SHAs and the
pasted diffstat:

```
archive: ui-critic-loop (DEBT-02 / D-4)

Archived state: main before <removal-squash-sha>
SHA (target): <parent-sha>
  (the parent of the removal squash on main; the last main commit that carries the
  UI critic loop)
ancestry verification: `git merge-base --is-ancestor <parent-sha> origin/main` exited 0
  => the tag pins a main commit; it never points at a milestone-branch commit.
archive date: YYYY-MM-DD (the tagging date)
requirement: DEBT-02 / D-4 (v1.47 Phase 246; decisions D-11..D-14)

diffstat (git diff --stat <parent-sha> <removal-squash-sha>):
  (paste; about 528 files changed, nearly all deletions)

recommendation: ARCHIVE (retired, restorable).

rationale: The UI critic loop covered the Elixir critic-trust maths and critic mix tasks,
  the TypeScript critic runner and rubrics, the Tier-A/graded/refute/storybook capture
  projects with the verify-capture CI job, the mechanical floor and its scorecard corpus, and
  the critic stress stories. It cost paid LLM spend and CI time, and the operator UI it
  judged is parked until 1.0.0. v1.47 retired it from main in one revertable squash
  (DEBT-02). This tag keeps the last state that had it, so the loop can come back when
  operator-UI work resumes (SEED-008).

restore command:
  primary:  git revert <removal-squash-sha>
  fallback (after later main commits edit the same hunks, so the revert no longer applies):
    git fetch origin refs/tags/archive/ui-critic-loop:refs/tags/archive/ui-critic-loop
    git checkout archive/ui-critic-loop -- \
      examples/threadline_phoenix/e2e/critic-before-pole.sh \
      examples/threadline_phoenix/e2e/critic/ \
      examples/threadline_phoenix/e2e/tests/operator-graded-capture.spec.ts \
      examples/threadline_phoenix/e2e/tests/operator-refute-capture.spec.ts \
      examples/threadline_phoenix/e2e/tests/operator-storybook-capture.spec.ts \
      examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts \
      examples/threadline_phoenix/e2e/tsconfig.json \
      lib/mix/tasks/critic.measure.ex \
      lib/mix/tasks/critic.synth.ex \
      lib/threadline/critic_trust/ \
      lib/threadline/operator_surface/live/stress_live/refute.ex \
      lib/threadline/operator_surface/mechanical_checker.ex \
      lib/threadline/operator_surface/mechanical_checker/ \
      test/fixtures/dialyzer/critic-tooling.json \
      test/fixtures/operator_surface/critic-scores/ \
      test/fixtures/operator_surface/golden/ \
      test/fixtures/operator_surface/refute/ \
      test/fixtures/operator_surface/scorecards/ \
      test/threadline/critic_iteration_runbook_doc_contract_test.exs \
      test/threadline/critic_pair_labeling_contract_test.exs \
      test/threadline/critic_shell_safety_contract_test.exs \
      test/threadline/critic_trust/ \
      test/threadline/operator_surface/critic_trust_test.exs \
      test/threadline/operator_surface/mechanical_checker_test.exs \
      test/threadline/operator_surface/refute_partition_test.exs
    then restore these mix.exs hunks by hand (see `git show archive/ui-critic-loop:mix.exs`):
      the aliases verify.mechanical, verify.critic_trust, verify.ui_critique and verify.capture;
      their preferred-env entries; the helper functions verify_capture/1 and
      verify_ui_critique/1; and the package exclude_patterns entries for lib/mix/tasks/critic.*,
      lib/threadline/critic_trust/ and the mechanical checker. The modified CI, contract,
      fixture and e2e config files (the 48 modified paths in the landing doc list) need the same
      hand merge.
  (inspect without restoring: git show archive/ui-critic-loop)

register: see .planning/ARCHIVE-REGISTER.md
```

The 25 fallback pathspecs cover all 479 files the slices delete. Each directory entry was
deleted in full.

Create the tag and check it locally:

```bash
# hygiene: the message must carry no home-path shapes or the local username
grep -nF -e "$HOME" -e "$(id -un)" <message-file>   # must print nothing
git tag -a archive/ui-critic-loop -F <message-file> <parent-sha>
git cat-file -p archive/ui-critic-loop | head -5
```

Maintainer grant: run this line yourself; no executor pushes. Push this one ref only. Never
use the flag that pushes all tags, because it would publish the local-only `vX.Y` milestone
tags.

```
! git push origin refs/tags/archive/ui-critic-loop
```

## ARCHIVE-REGISTER row

Apply at landing, after the tag exists. Add the row to the `## Archived refs` table in
`.planning/ARCHIVE-REGISTER.md`, using the `:23` column order:

```
| `archive/ui-critic-loop` | `<parent-sha>` | YYYY-MM-DD (tagging date) | DEBT-02 / D-4 critic retirement (v1.47 Phase 246). An annotated **tag pinning a main commit**, not a branch: the parent of the removal squash `<removal-squash-sha>` on main, the last main state that carries the UI critic loop (critic-trust tooling, the TS critic runner, capture projects plus the verify-capture job, the mechanical floor, critic stress stories and the fixture corpus). | **Archive (retired, restorable)**. The loop is retired from main; operator-UI work is parked until 1.0.0 (SEED-008), and this tag is how it comes back. | `git revert <removal-squash-sha>` (fallback: `git checkout archive/ui-critic-loop -- <paths>` plus the hand-restored mix.exs aliases, as in the tag message) |
```

Then change `**Rows: 11.**` to `**Rows: 12.**`. Do not add an `<!-- archive-subject: … -->`
comment line; those belong to the 198 round-11 tooling. In this phase
`.planning/ARCHIVE-REGISTER.md` stays unchanged.

## Landing evidence (D-14)

Run after the tag push. Expected results:

| command | expected |
|---------|----------|
| `git ls-tree -r --name-only archive/ui-critic-loop \| grep -c lib/threadline/critic_trust/` | > 0 (the tag carries the retired code) |
| `git merge-base --is-ancestor archive/ui-critic-loop origin/main` | exit 0 (the tag pins a main commit) |
| `git ls-remote origin refs/tags/archive/ui-critic-loop` | non-empty (the push landed; same check as listing remote tags filtered to this name) |

No CI workflow, contract test or bin script depends on the tag existing. Shallow clones and
forks will not carry it; restoring from one needs
`git fetch origin refs/tags/archive/ui-critic-loop`. The output of
`git grep -n 'archive/ui-critic-loop' -- .github test bin`, run at hand-off, shows only a
reworded guard test name and message and a doc-contract string constant. Neither resolves
the ref:

```
test/threadline/ci_topology_contract_test.exs:681:  test "no workflow references a paid LLM API key (GREEN-09 resurrection guard; retired UI loop, tag archive/ui-critic-loop)" do
test/threadline/ci_topology_contract_test.exs:692:               "archive/ui-critic-loop) must stay structurally unreachable from CI " <>
test/threadline/ui_critic_retirement_doc_contract_test.exs:16:  @restore_tag "archive/ui-critic-loop"
```

Nothing under `.github/` or `bin/` names it. No branch-protection or ruleset change is part of
this landing (D-26). The optional `ci-browser-full` label tidy-up does not apply, because
Browser-full survives (it runs `route-capture`).

## Next

- **Phase 247 owns the D-25 work.** This phase did none of it: partition re-weighting,
  per-spec timing, browser-project splits, contract-lane tags, time-to-red, CI wall-time
  measurement.
- **Restate the browser-baseline memory line** with the measured standalone numbers:
  419 passed / 10 failed / 58 skipped, replacing the stale 326/8/16. The failing set is now 10
  tests, the four known screenshot pairs plus `operator-screenshot-regression.spec.ts:101` ×
  2. `:101` already fails on origin/main (`23178fb0`). A failure outside these 10 is a
  regression. The `:101` baseline belongs to SEED-008 and was not regenerated.
- Maintainer landing steps, in order:
  1. the v1.47 base PR (Prerequisite 2.1);
  2. the removal squash PR;
  3. tag creation, then `! git push origin refs/tags/archive/ui-critic-loop`;
  4. the ARCHIVE-REGISTER row;
  5. the remaining v1.47 commits.
