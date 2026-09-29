# Phase 223: Close v1.43 Audit Debt - Context

**Gathered:** 2026-09-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the three decision items from `.planning/v1.43-MILESTONE-AUDIT.md`:

1. Ship the mint 1.11.0 security fix (already on `main`) as the 0.11.2 patch release.
2. Stop persisting the GitHub token in `release.yml` checkouts, and back that with a
   release-control-plane contract test that has mutation controls (216 CR-01).
3. Leave no `open` row in `217-REVIEW-DISPOSITION.md`.

`mix ci.all` and `bin/verify-repo-hygiene` stay green. There are no new requirements
(SUP-01 and HYG-02 stay satisfied). Every other audit tech-debt item is deferred (see
`<deferred>`).

</domain>

<decisions>
## Implementation Decisions

### A. Mint 1.11.0 release vehicle (maintainer accepted, HIGH-IMPACT)
- **D-01:** Release through a `BEGIN_COMMIT_OVERRIDE` block appended to the body of the
  merged squash PR #60 (merge 3c4ac9b1, which really contains the mint bump). Do not add
  a new or empty `fix(deps):` commit. The lock and CHANGELOG changes are already on
  `main`, so any new "fix" commit would be a fake diff or an unrelated bump. Block text,
  verbatim. The override REPLACES the whole message, so it must keep the `ci:` line, and
  it must contain no `feat` line, which would bump the release to 0.12.0:
  ```
  BEGIN_COMMIT_OVERRIDE
  fix(deps): update mint to 1.11.0 (with hpax 1.1.0) for three security advisories

  ci: repo hygiene, CI economy, deps-only build cache and newest-toolchain lane (v1.43 phases 217-220)
  END_COMMIT_OVERRIDE
  ```
  — **Reversibility:** one-way — once 0.11.2 is published to Hex it cannot be unpublished
  after the Hex window; the PR body edit itself is reversible.
- **D-02:** ROADMAP success criterion 1 is amended to "the mint 1.11.0 fix becomes
  releasable to release-please (commit override on #60)" instead of "a releasable
  `fix(deps):` commit on `main`". The maintainer accepted this on 2026-09-29.
- **D-03:** The version is **0.11.2**. `release-please-config.json` has
  `bump-minor-pre-major: true` and `bump-patch-for-minor-pre-major: false`, so a `fix`
  gives a patch. The manifest on `main` is 0.11.1.
- **D-04:** Sequence. Every push, PR edit, merge and approval needs the maintainer's
  explicit named grant, and the `production-hex` approval is the maintainer's own.
  1. Land the B+C PR (`ci:` squash subject, non-releasable). It merges before the release,
     so the 0.11.2 run is the first live proof of the hardened checkouts (see D-07).
  2. `gh pr edit 60` with the override block.
  3. Trigger release-please with a push to `main`. Merging PR 1 after the edit does this;
     if PR 1 merged first, `gh run rerun` the latest push-triggered Release run.
     `workflow_dispatch` does NOT run the release-please job (`if: github.event_name == 'push'`).
     Expect `chore(main): release 0.11.2`.
  4. Open a `docs(release): date the 0.11.2 changelog entry` PR, following #58. It retitles
     `## Unreleased — highlights` to the dated `[0.11.2]` heading and puts a fresh
     placeholder above it. The release PR's `Release metadata` check fails until this lands.
  5. Merge the release PR with `--match-head-commit`, then the `production-hex` approval,
     publish/smoke, and the distribution-sync PR (per the release runbook).
- **D-05:** Release notes say **three** advisories. The CHANGELOG on `origin/main` is
  right. Local `milestone/v1.43` still says "four", which double-counts
  EEF-CVE-2026-82672: mint 1.10.1 already fixed that one in 0.11.1. Any landing must take
  `main`'s CHANGELOG text and never the milestone branch's.
- **D-06:** Add no new CI guard for "releasable fix swallowed by a non-releasable squash
  subject" (deferred). Instead, add one sentence to CONTRIBUTING's release section: a
  landing PR that carries an adopter-facing Security/Fixed CHANGELOG entry must use a
  releasable squash subject or carry an override block before merge.

### B. release.yml checkout credentials (216 CR-01)
- **D-07:** Default-deny. EVERY `actions/checkout` step in `release.yml` must set
  `persist-credentials: false`, unless its job is in a reasoned allowlist
  `@persisted_checkout_jobs` (a `%{job => reason}` map) with exactly two entries:
  - `dispatch-bootstrap`: a bare `git push origin "$tag"` uses the persisted credential;
    it runs no mix.
  - `distribution-sync`: a bare `git push -u origin "$BRANCH"` uses the persisted
    credential; it runs no mix.

  The fix adds the flag to the target-ref checkouts in `publish-hex` (~:481) and
  `smoke-published` (~:646), and to the `release-please` job checkout (~:63), which needs
  no git auth. The scope is limited to `release.yml` (other workflows are deferred).
- **D-08:** The check runs per checkout step, NOT per job. The sparse pin checkouts
  already set the flag, so a per-job count passes vacuously for `publish-hex` and
  `smoke-published`, and that is how CR-01 escaped.
- **D-09:** Rules, each returned as a tagged error in the style of
  `bootstrap_guard_errors/1`:
  - `checkout-credential-free`: every checkout sets the flag unless its job is allowlisted.
  - `allowlisted-job-runs-no-mix`: no `run:` in an allowlisted job contains `mix `.
  - A stale-allowlist-entry rule, as in `ci_token_permissions_contract_test.exs` ~:356-374.
- **D-10:** Extend `test/threadline/release_control_plane_contract_test.exs` and replace
  its per-job counting block (~:143-161), keeping the sync-specific asserts. Stay
  text-based like the file's own `job_block!/2`. For the step split, borrow
  `job_steps/1` / `yaml_value/2` from `ci_workflow_parity_contract_test.exs`.
- **D-11:** Mutation controls: a data-driven `for` block modelled on
  `ci_token_permissions_contract_test.exs` ~:396-449. Its `mutate!` asserts that the
  anchor exists, then `refute mutated == live`, then asserts the named rule fires.
  Cases:
  1. Strip the flag from the `publish-hex` target checkout.
  2. Strip it from the `smoke-published` target checkout.
  3. Strip it from the sync `ref:` checkout (the existing control).
  4. Add `run: mix deps.get` to `distribution-sync`.
  5. Rename an allowlisted job, which fires the stale rule.
  6. Positive control: adding the flag to an allowlisted job stays green.
- **D-12:** Put a short YAML comment above each newly flagged target checkout in the
  style of release.yml ~:157-160, citing 216 CR-01, so nobody "simplifies" the flag away.

### C. Phase 217 round-2 findings: fix all six, none deferred
Every fix goes in `bin/verify-repo-hygiene` itself, so that CI and anyone running the
guard directly both get it, with a `--self-test` case and/or a guard-test case as the
mutation control.
- **D-13 (R2-WR-01):** A structural check `literal_too_broad` exits 2 when any home or
  temp root starts with an allowlist literal (macOS home, Linux home, both JSON-escaped
  homes, `~/`, `/var/folders/`, `/private/var/folders/`). Tests: self-test case (h), the
  literal `/` exits 2. The guard test adds more literals that must exit 2: `/`, a lone
  backslash, `~`, `~/`, `/var/folders`, and the home-root placeholders. Specific entries
  such as `~/.cache` and the runner home still pass. Background: the coverage rule
  (a literal not ending in `/` also covers `literal + "/..."`) makes a one-character
  literal cover a whole family. The UNUSED rule never catches this, because a broad
  literal is always "used".
- **D-14 (R2-WR-02):** Left-anchor family 6 with
  `(?:(?<![A-Za-z0-9._-])|(?<=[A-Za-z]-))` before the `-<Users>-` token. Tests:
  self-test case (g) and a guard test proving a TitleCase kebab word such as
  `Admin-<Users>-Guide` does not hit, while the R1-CR-01 positives (after a space, after
  `/`, the drive form) still hit. Hits on the real tree: 0 → 0. Rewrite the header
  comment (~:85-90) that says family 6 needs no boundary.
- **D-15 (R2-WR-03):** A pre-scan check. If `git ls-files -z` contains a path with a
  newline, the guard exits 2 with a clear reason. Narrow the header claim (~:15-17) to
  match. Test: self-test case (i), a newline filename plus a phantom-scope allowlist
  entry, exits 2. The researcher reproduced this bypass in a scratch repo with the
  current guard, so it is not hypothetical.
- **D-16 (R2-WR-04):** Option (b): add an anchored Linux-encoded Claude-project family,
  `(?<![A-Za-z0-9._-])(-<home>-[A-Za-z0-9._]+)`, where `<home>` is the Linux home root
  segment. Add the placeholder `` `-home-<user>-<project>` `` to CONTRIBUTING (~:131) and
  to the script header's family list. Measured: 0 hits on the tree anchored, 539 false
  positives unanchored, so the anchor is mandatory. The existing placeholder
  concretization contract test (~:359-397) covers the new placeholder as its mutation
  control. Add self-test case (g'): a Linux-encoded dir fixture exits 1.
  Note: a CI-runner Claude dir (`-home-<runner>-<project>`) would hit. There are 0 today, so
  there is no allowlist entry. If one is ever needed, `forbidden_home_literal?/1` must
  permit the `-home-<runner>` token (the runner account segment) the way it permits the runner home.
- **D-17 (R2-IN-01):** Assert the hint `printf ... Writing about machine-local paths ... >&2`
  line itself. Mutation control: delete that line from the script text, then
  `refute mutated == script`, then `refute Regex.match?`.
- **D-18 (R2-IN-02):** CONTRIBUTING (~:140-141) wording becomes "no file or directory is
  exempt from the scan other than the allowlist's own literal column".
- **D-19:** Housekeeping. The `--self-test` summary changes from `ok (6 cases)` to
  `ok (N cases)`, with N equal to the final case count, and the guard test's assertion
  and test name ("six cases") change with it (`repo_hygiene_guard_test.exs` ~:574-577).
- **D-20:** Disposition file update: hand-edit `217-REVIEW-DISPOSITION.md` in one commit.
  - Set each `R2-*` frontmatter `disposition:` to `fixed`, `open: 0`, `total: 11`, and
    refresh `recorded:`.
  - Set each table row to `fixed` with Source `223-NN Task N <sha>`.
  - Do NOT run the gsd-core code-review-disposition step. It would re-add bare ids as
    `open` rows and flag the `R2-*` rows (see commit f169cb91 for the hand-merge precedent).
  - Verify: `grep -c '| open |'` is 0, and the frontmatter ids match the table.

### Cross-cutting
- **D-21:** B and C land together in one `ci:` PR before the release (D-04). C touches
  files unrelated to B, so there is no ordering constraint inside the PR.
- **D-22:** All planning prose, review reasons and summaries write machine-specific path
  segments as angle-bracket placeholders. After D-16 lands, a Linux-encoded project dir
  in prose will turn the guard red.
- **D-23:** Edits to gate or test scripts (`bin/verify-repo-hygiene`, contract tests) are
  strengthening changes. Name the files in any permission ask: the classifier has
  blocked vaguely described gate edits before.

### Claude's Discretion
- Exact regex spelling, test names, error-message wording, and the split of plans and
  tasks, as long as D-07..D-20 hold.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit and scope
- `.planning/v1.43-MILESTONE-AUDIT.md` — the source of every item; `tech_debt` frontmatter
- `.planning/ROADMAP.md` §Phase 223 — goal and success criteria (SC-1 amended per D-02)
- `.planning/PROJECT.md` — Constraints ("Zero human verification by default")

### Release (A)
- `release-please-config.json`, `.release-please-manifest.json` — bump rules, changelog-sections
- `.github/workflows/release.yml` — release-please job (push-only), `gate-ci-green`, `publish-hex`, `smoke-published`, `distribution-sync`
- `CHANGELOG.md` (on `origin/main`) — the human-owned "Unreleased — highlights" entry (three advisories)
- `CONTRIBUTING.md` — release section (D-06 sentence goes here)
- PR #58 — precedent for the `docs(release): date the … changelog entry` PR
- release-please README, "Overriding merged pull request commit messages" (`BEGIN_COMMIT_OVERRIDE`)

### Checkout credentials (B)
- `.planning/phases/216-ci-platform-currency/216-REVIEW*.md` — CR-01 text
- `test/threadline/release_control_plane_contract_test.exs` — the file to extend
- `test/threadline/ci_token_permissions_contract_test.exs` — allowlist + stale-entry + mutation-control idiom
- `test/threadline/ci_workflow_parity_contract_test.exs` — `job_steps/1`, `yaml_value/2`, the existing sparse-checkout flag check

### Repo hygiene (C)
- `bin/verify-repo-hygiene` — the guard, including `--self-test`
- `test/**/repo_hygiene_guard_test.exs` and the repo-hygiene contract test (placeholder concretization)
- `.planning/phases/217-repo-hygiene/217-REVIEW.md` (round 2) and `217-REVIEW-DISPOSITION.md`
- `CONTRIBUTING.md` §"Writing about machine-local paths"

### Project DNA
- `prompts/threadline-elixir-oss-dna.md` — honest tests, named verify entrypoints, stable CI job ids

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bootstrap_guard_errors/1` and `job_block!/2` in `release_control_plane_contract_test.exs`: an error-list, text-parsed contract style.
- `mutate!` + data-driven `for` mutation block in `ci_token_permissions_contract_test.exs`.
- `bin/verify-repo-hygiene --self-test` fixture cases (currently 6).

### Established Patterns
- Contract tests prove they can fail through mutation controls (`refute mutated == live`, then the named rule fires).
- Allowlists are `%{key => reason}` maps with a stale-entry rule.
- `release.yml` already sets `persist-credentials: false` on the sparse pin checkouts and on both `sync-release-pr-pins` checkouts. The explanatory comment style is at ~:157-160.

### Integration Points
- `mix ci.all` runs the contract tests; the `verify-repo-hygiene` CI job runs the guard directly.
- release-please runs only on push to `main`; the release workflow definition comes from the triggering `main` commit, not from the target ref.

</code_context>

<specifics>
## Specific Ideas

- The researcher's patched-guard dry run (all C fixes applied) printed "4229 tracked text file(s) clean; 8 allowlist entries used, 0 inert" and exited 0, so the fixes do not redden the real tree.
- actions/checkout v6 moves persisted credentials to a file under `$RUNNER_TEMP`, but the token stays readable by same-user processes such as Mix compile-time code. The repo is on v5, where the token sits in `.git/config`. The flag is needed either way.
- #60's squash body holds about 700 bulleted `feat(...)`/`fix(...)` lines. Only the bullets stopped release-please from parsing them as extra commits, which would have forced 0.12.0. Future landing PRs must keep that in mind.

</specifics>

<deferred>
## Deferred Ideas

- A CI guard that fails when the CHANGELOG's Unreleased section has a Security/Fixed entry but no releasable commit exists since the last tag, or a PR-title lint. A mix.lock-driven lint would misfire, because a library's lock does not ship to adopters.
- `persist-credentials: false` default-deny across ALL workflows (zizmor `artipacked` parity; 20 checkouts in ci.yml and elsewhere).
- Converting `dispatch-bootstrap` and `distribution-sync` to explicit-URL pushes so they can drop persisted credentials.
- HYG-03 continuous enforcement of `mix verify.temp_leaks`. Researcher opinion: a `ci.all` leaf with its own stable job id, not folded into the repo-hygiene guard.
- The remaining audit items: 216 WR-01/WR-02, setup-node float and SHA pinning; the 215 deferred-items list; the 218 items; the 221 BASH_ENV advisory; SUMMARY frontmatter bookkeeping.

</deferred>

---

*Phase: 223-close-v1-43-audit-debt*
*Context gathered: 2026-09-29*
