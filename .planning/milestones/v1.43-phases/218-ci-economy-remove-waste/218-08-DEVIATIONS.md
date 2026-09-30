# 218-08 Deviations (landing fixes for draft PR #60)

Two CI failures on draft PR #60 (branch `land/v1.43-217-218`) were fixed as
Rule 1 deviations. The continuation agent folds this record into
`218-08-SUMMARY.md`. Nothing was pushed.

## 1. [Rule 1 - Bug] Browser-full: refute-capture needs tier-a-capture (run 36359136941)

**Found during:** the Browser-full dispatch on the land branch (run 36359136941).
It failed at `tests/operator-refute-capture.spec.ts:101` with `missing tier-a cell
dir for refute.hierarchy.flattened.polished — run the tier-a-capture lane first`.

**Issue:** `operator-refute-capture.spec.ts` only overwrites `screenshot.png`
inside the `artifacts/tier-a/<cell>` directories. Those directories are
gitignored, and only `tier-a-capture` creates them, in the same checkout. The
spec checks that they exist before it starts. `playwright.config.ts` never
declared the dependency. Before 218-07, Browser-full ran every project, so the
spec passed only because of project ordering. 218-07's partition moved
`tier-a-capture` into ci.yml only, and refute-capture then ran with no cell
directories.

**Proof that the pinned Playwright supports the fix:** `@playwright/test`
1.60.0 is pinned in `package-lock.json`. After the fix, `npx playwright test
--list --project=refute-capture` (run from the e2e dir, which starts no server)
lists `[tier-a-capture] operator-tier-a-capture.spec.ts:405` and then
`[refute-capture] operator-refute-capture.spec.ts:101`. With the four
Browser-full flags, `--list` shows one test each for graded-capture,
refute-capture, route-capture and storybook-capture, plus tier-a-capture. The
dark `tier-a-capture` project emits the `__dark-1280` refute cells the spec
needs (`themeForProject`, BAND_2 refute ledger ids).

**Other projects checked:** graded-capture, route-capture and storybook-capture
each `mkdirSync` their own `artifacts/<lane>/<cell>` directory. None of them
reads another lane's output. A scan of every e2e spec for the `run the
<project> lane first` phrase finds only the refute-capture spec. **No other
undeclared cross-project dependency was found.**

**Fix (TDD on milestone/v1.43):**
- RED `00011bac` `test(218-08): assert refute-capture declares its tier-a-capture dependency`.
  This commit extends `test/threadline/browser_full_projects_contract_test.exs`
  with the following:
  - `--list deps` must equal `["refute-capture tier-a-capture"]`.
  - `--list executed` must equal the Browser-full flag set plus its declared
    dependency closure, and nothing else. A pulled-in project must be a ci.yml
    project.
  - A `@stated_prerequisites` table backed by a spec scan. Every `run the <x>
    lane first` phrase in any e2e spec must be modeled in the table, and the
    table's entries must be phrases that exist.
  - Every stated prerequisite of a Browser-full project that ci.yml owns must
    be a declared dependencies edge.
  - Mutation control: removing `dependencies: ["tier-a-capture"]` while
    refute-capture stays in Browser-full yields exactly one violation, "refute-capture
    needs tier-a-capture".
  - Mutation control: a dependency that names an unregistered project exits non-zero.

  RED run: `mix test test/threadline/browser_full_projects_contract_test.exs`
  ran 25 tests with 6 failures. All 6 were the new dependency tests. The four
  live-repo tests failed because the script had no `--list deps` / `--list
  executed` listing (usage exit 2). The two mutation controls failed on "control
  did not change playwright.config.ts" because no declaration existed yet. The
  19 pre-existing tests stayed green. `gsd check tdd-red-evidence` parses only
  TAP or Surefire output, not ExUnit, so the RED evidence is recorded here in
  prose.
- GREEN `22a4829f` `fix(218-08): declare refute-capture's tier-a-capture Playwright dependency`.
  - `examples/threadline_phoenix/e2e/playwright.config.ts`: `dependencies:
    ["tier-a-capture"]` on refute-capture, with a comment giving the reason.
  - `bin/browser-full-projects`: new `--list deps` (one `<project> <dependency>`
    line per declared edge in a default-region project object, ignoring
    whole-line `//` comments) and `--list executed` (the flag set plus the
    transitive dependency closure). It fails closed (exit 1) when a dependency
    names a project outside the default config. The `--project` flag output is
    unchanged, so the partition stays disjoint and complete.
  - `CONTRIBUTING.md` `## CI Coverage`: one sentence says that a declared
    dependencies edge is the only way a ci.yml project also executes in
    Browser-full. The replaced sentence said "It never repeats a project
    `ci.yml` already runs", which was no longer true. The `tier-a-capture` row's
    Nightly cell now reads "only as `refute-capture`'s dependency".
  - GREEN run: the browser-full contract and `ci_coverage_doc_contract_test.exs`
    ran 28 tests with 0 failures.

**Cost note [inference]:** tier-a-capture now also runs inside Browser-full
before refute-capture. The step keeps `timeout-minutes: 45`. Whether the added
tier-a-capture time fits inside that budget can only be proven by the next
Browser-full run.

## 2. [Rule 1 - Bug] Repo hygiene on main's published `.planning/` snapshot (run 36359132030)

**Issue:** The land branch carries origin/main's old published `.planning/`
snapshot. 217-04's scrub (`ddcea1c8`) changed only the milestone copy, so the
required job "Repo hygiene (no machine-local paths)" failed.

**Fresh derivation (land worktree):** `bin/verify-repo-hygiene` reported 983
HIT lines in 304 files, all under `.planning/`. The list was identical to the
orchestrator's hit-file list. Token shapes: 966 macOS home, 13 home-relative
(10 `.claude`, 1 each `Library`, `.local`, `.codex`), and 4 per-user temp roots.
It also reported `UNUSED allowlist entry .planning/ ~/.hex`, before any rewrite.

**Fix:** 217-04's R1-R7 prefix-only rewrite ran as `perl -i -p <script>`. The
script has no `while(<>)` loop of its own, which avoids the double-consumed-stdin
pitfall that 217-04-SUMMARY records. The exceptions come from the land
worktree's `.github/repo-hygiene-allowlist.tsv` at run time, restricted to
entries scoped `.planning/` or `.`: the runner account for R2, plus `~/.cache`,
`~/.hex`, `~/.claude/gsd-core/`, `~/.claude/get-shit-done/` and
`~/.claude/skills/` for R3.

**Integrity checks (all passed):**
- Preconditions: every listed path is tracked, none had uncommitted edits,
  `.planning/config.json` was not in the list, the index was empty, and the land
  tree was clean.
- Per-file numstat: 304 files, 0 with unequal added and deleted counts. Every
  file's `wc -l` is unchanged.
- Both `.json` files parse.
- A second pass is a no-op (identical `git diff --stat`).
- **Ground truth:** 303 of the 304 files had land HEAD content identical to
  `ddcea1c8^`. For every one of those 303, the rewritten output is byte-identical
  to `ddcea1c8`'s blob, so the rewrite reproduces 217-04 exactly. The remaining
  file, `.planning/STATE.md`, has diverged since then. Its diff contains only
  home-relative plan-path rewrites.
- After the scrub, the guard reports zero HIT lines.
- `git grep -l -I -w -i "$(id -un)"` in the land worktree prints nothing.
- Staged set == the derived list, with no path outside `.planning/`. The commit
  message contains no username.

**Land commit:** `23986942` `docs(planning): scrub machine-local paths from published planning files`.

**Residual blocker (not fixed; needs a scope decision):** the land guard still
exits 1 with a single line, `UNUSED allowlist entry .planning/ ~/.hex`. The
`.planning/ ~/.hex` allowlist entry is used only by milestone-era docs (phase
215 and 217 plans, research and security). Those docs are not in main's old
published snapshot, so on the land tree the entry covers no HIT. The UNUSED line
was already in the orchestrator's CI output, so the scrub cannot clear it. The
constraints forbid weakening the guard or its allowlist, so no edit was made.
Possible resolutions, for the orchestrator or maintainer to choose:
- (a) Drop `.planning/` from the land branch entirely. Every `.planning/`-scoped
  entry then reports inert, which is the guard's designed "public PR-branch
  case". This removes the published planning snapshot from main.
- (b) Land the current milestone `.planning/` state, which is already scrubbed and
  uses the entry. This publishes more planning prose.
- (c) Make a guard or allowlist change, such as scoping the entry to the files
  that cite it. This is a guard-contract decision and is out of this
  executor's remit.

## Cherry-pick onto the land branch

`00011bac` became `de9290f7` and `22a4829f` became `c18f2b2f`. Messages are
preserved and there are no `.planning/` paths.
`git -C <land> diff --name-only milestone/v1.43 -- . ':!.planning'` lists
exactly the six release-bump files: `.release-please-manifest.json`,
`CHANGELOG-GENERATED.md`, `CHANGELOG.md`, `guides/adoption-pilot-backlog.md`,
`guides/evaluating-threadline.md` and `mix.exs`.

## Gate results (main checkout, after GREEN)

- `mix test`: 9 properties, 2466 tests, 0 failures, 3 excluded (exit 0).
- The browser-full and CI Coverage contract tests: 28 tests, 0 failures.
- `actionlint -shellcheck=`: exit 0.
- `mix verify.format`: exit 0.
- `mix verify.credo`: exit 0, no issues.
- `bin/verify-repo-hygiene` (main checkout, after committing this file): see
  the commit that adds this file.

## Not provable locally

- The Browser-full lane itself. The fix is proven by `--list` and the contract
  test; only a CI run executes the Playwright suite.
- Whether Browser-full stays inside its 45-minute step timeout with tier-a-capture added.
- A green "Repo hygiene" job on PR #60 depends on the residual blocker above.

## 3. [Rule 1 - Bug] Flake Detection is sized past its own budget (run 36359135268)

**Found during:** the Flake Detection dispatch on the land branch (run
36359135268, at `0d000785`). It classified `inconclusive` after 16 iterations:
the 55-minute `timeout(1)` budget expired during the 16th suite run. Every
completed run was green ("9 properties, 2460 tests, 0 failures, 3 excluded").

**Issue:** 218-05 sized the lane from 214's figures (run 35967937335, 1698
tests): 288 s cold + 15 x 165 s, about 46 min. The measured figures on the
current 2460-test suite are 268.3 s cold and 206.2-213.5 s per repeat (median
about 209 s), so 1 + 15 runs need about 268 + 15 x 209, roughly 3,403 s or
57 min. That is over the budget. As shipped, every run ends `inconclusive`, and
the close-on-pass path (ECON-02, #36) can never fire.

**Fix (TDD on milestone/v1.43):** the budget and timeouts are unchanged
(55-minute `timeout(1)`, step 58, job 70). Only the repeat count moves, from 15
to 12, which stays inside D-02's bound of 15.
- RED `77f684c1` `test(218-08): assert the flake lane's repeat count fits its timeout budget`.
  It adds `Test 6` to `test/threadline/flake_classifier_contract_test.exs`:
  - Documented per-run ceilings from run 36359135268, rounded up: 269 s cold
    and 214 s per repeat, with 10% headroom kept free under the budget.
  - The repeat count is parsed from the `verify.flake` alias in `mix.exs`, and
    the budget from the workflow's `timeout ... 55m mix verify.flake` line. The
    test asserts that 1 + repeats runs fit the usable budget and that repeats
    stay within 1..15.
  - Doc agreement: the workflow comment, `CONTRIBUTING.md` and the
    `bin/classify-flake-run` header must state the committed count, and the
    workflow must cite run 36359135268.
  - Mutation controls: 15 repeats at a 209 s ceiling is red; rewriting the
    `mix.exs` alias back to 15 is red; 16 repeats trips the D-02 bound.

  RED run: `mix test test/threadline/flake_classifier_contract_test.exs` ran 27
  tests with 2 failures, both new. The sizing test reported `1 + 15 runs need
  3479 s (269 + 15 x 214), over 2970 s (3300 s budget less 10% headroom)`. The
  doc-agreement test failed on the missing run citation. The mutation-control
  test and the 24 existing tests passed.
- GREEN `fbfbcb11` `fix(218-08): size the flake lane at 12 repeats so a pass fits its budget`.
  - `mix.exs`: `verify.flake` is `test --repeat-until-failure 12` (13 runs).
  - `.github/workflows/flake-detection.yml`: the header says "bounded
    12-repeat", and the sizing comment is rewritten from the measured figures:
    269 + 12 x 214 = 2,837 s, about 47 min, about 14% headroom under 55.
  - `CONTRIBUTING.md` and the `bin/classify-flake-run` header state 12. The
    classifier logic does not depend on the count: pass is exit 0, and a
    timeout exit is `inconclusive` whatever the header count.
  - GREEN run: the same file ran 27 tests with 0 failures.

**Why 12 and not 13 or 14:** at the ceilings, 13 repeats need 3,051 s and 14
need 3,265 s. Both fit the raw 3,300 s budget, but with 7.5% and 1% headroom.
12 is the largest count that keeps 10% headroom.

**Cherry-pick onto the land branch:** `77f684c1` became `12eac623` and
`fbfbcb11` became `398e8440`. Messages are preserved and there are no
`.planning/` paths.

**Gate results (main checkout, after GREEN):**
- `mix test`: 9 properties, 2469 tests, 0 failures, 3 excluded (exit 0).
- `actionlint -shellcheck=`: exit 0.
- `mix verify.format`: exit 0.
- `mix verify.credo`: exit 0, no issues.
- `bin/verify-repo-hygiene`: exit 0, 8 allowlist entries used, 0 inert.

**Not provable locally:** that a real Flake Detection run now classifies `pass`
inside the budget. Only the next dispatch or weekly run shows that.
