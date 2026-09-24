---
phase: 202-release-0-10-0
verified: 2026-09-22T22:10:00Z
status: passed
score: 5/5 roadmap success criteria verified; 44/46 merged must-haves verified (2 plan-level truths FAILED as worded, intent now met — override suggested)
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/phases/202-release-0-10-0/202-01-PLAN.md
  - .planning/phases/202-release-0-10-0/202-01-SUMMARY.md
  - .planning/phases/202-release-0-10-0/202-02-PLAN.md
  - .planning/phases/202-release-0-10-0/202-02-SUMMARY.md
  - .planning/phases/202-release-0-10-0/202-03-PLAN.md
  - .planning/phases/202-release-0-10-0/202-03-SUMMARY.md
  - .planning/phases/202-release-0-10-0/202-04-PLAN.md
  - .planning/phases/202-release-0-10-0/202-04-SUMMARY.md
  - .planning/phases/202-release-0-10-0/202-05-PLAN.md
  - .planning/phases/202-release-0-10-0/202-05-SUMMARY.md
  - .planning/phases/202-release-0-10-0/202-06-PLAN.md
  - .planning/phases/202-release-0-10-0/202-06-SUMMARY.md
  - .planning/phases/202-release-0-10-0/202-07-PLAN.md
  - .planning/phases/202-release-0-10-0/202-07-SUMMARY.md
  - .planning/phases/202-release-0-10-0/202-08-PLAN.md
  - .planning/phases/202-release-0-10-0/202-08-SUMMARY.md
  - .planning/phases/202-release-0-10-0/202-09-PLAN.md
  - .planning/phases/202-release-0-10-0/202-09-SUMMARY.md
  - .planning/phases/202-release-0-10-0/202-10-PLAN.md
  - .planning/phases/202-release-0-10-0/202-10-SUMMARY.md
covered_digest: "v1:sha256:5b147ab98e0da1b4af56997e3201487c3daf65f124281746bf73bb2fffb32ab5"
# NOTE: shipped code was verified at origin/main 53b5d71a (detached checkout), which is NOT
# the local planning branch; impl files are therefore not fingerprinted against ROOT.
behavior_unverified: 0
overrides_applied: 2
gaps:
  - truth: "202-05: The release pull request is green by construction on the first CI run after the update — both measured born-red causes are closed before the run, not patched after it."
    status: failed
    reason: "Historically false and cannot become true retroactively. The first CI run on the regenerated release PR (run 35765331006 at b4aa566e) was 12 pass / 4 fail: six install pins still read ~> 0.9.0 because nothing in the release flow ran `mix release.pins`, plus a changelog-contract seed assertion that release-please falsifies on every release PR. Fixed after the fact by PR #44 (sync-release-pr-pins job + changelog test correction); #26 then went 16/16 at 2f5248b9 (run 35781240139). The INTENT — future release PRs are green by construction — is now true on origin/main (sync job proven on its first real run; bump-rehearsal CI job green at 53b5d71a simulating 0.10.0 -> 0.11.0 including release-please's CHANGELOG-GENERATED.md write)."
    artifacts:
      - path: ".github/workflows/release.yml"
        issue: "sync-release-pr-pins did not exist at the time of the first release-PR run; added by PR #44 (8c6b8c6b)"
    missing:
      - "No code change required. Maintainer acceptance via an `overrides:` entry (suggested YAML in the report body), OR reword the plan truth to the forward-looking invariant it is now proven to satisfy."
  - truth: "202-10 (backstop): The gate would have caught all three of the born-red causes found at Phase 202 Task 1."
    status: failed
    reason: "False as worded, by the executor's own measurement (202-10-SUMMARY 'Where the plan was wrong'): bin/verify-bump-rehearsal catches BR-5 (direct negative control) and BR-4 (runs mix verify.release with --warnings-as-errors) but NOT BR-3 (Dialyzer unknown_function) — the rehearsal runs no Dialyzer. BR-3 was red at the current version and is caught on every PR by the separate `verify-dialyzer` job, which is a member of `ci-required` (ci.yml needs list). The rehearsal also failed to foresee the two causes that made #26 red on its first run (see gap 1). Intent (a born-red defect fails a required check on the PR that introduces it) holds for the composite required check, not for this gate alone."
    artifacts:
      - path: "bin/verify-bump-rehearsal"
        issue: "Covers 2 of the 3 named causes; BR-3 covered by verify-dialyzer instead"
    missing:
      - "No code change required. Maintainer acceptance via an `overrides:` entry, OR reword the truth to 'the required check (verify-bump-rehearsal + verify-dialyzer) would have caught all three'."
overrides:
  - must_have: "The release pull request is green by construction on the first CI run after the update — both measured born-red causes are closed before the run, not patched after it."
    reason: "First release-PR run (35765331006) was red; fixed by PR #44 (sync-release-pr-pins + changelog test). Forward invariant proven: #26 16/16 at 2f5248b9, release commit fully bot-authored, bump-rehearsal CI green at 53b5d71a. Historical event cannot be re-run."
    accepted_by: "szTheory (maintainer, via AskUserQuestion in the release session)"
    accepted_at: "2026-09-22T22:20:00Z"
  - must_have: "The gate would have caught all three of the born-red causes found at Phase 202 Task 1."
    reason: "verify-bump-rehearsal catches BR-4 and BR-5; BR-3 (Dialyzer) is caught on every PR by verify-dialyzer, also a ci-required member. Intent (born-red defects fail a required check on the introducing PR) holds for the composite gate."
    accepted_by: "szTheory (maintainer, via AskUserQuestion in the release session)"
    accepted_at: "2026-09-22T22:20:00Z"
---

# Phase 202: Release 0.10.0 Verification Report

**Phase Goal:** PR #26 is merged and threadline 0.10.0 is published to hex.pm with a public surface that Phases 200 and 201 already made clean, every version-bearing literal managed by release automation so a version bump needs no hand edits, and a changelog a human can read.
**Verified:** 2026-09-22T22:10Z
**Status:** passed — both overrides accepted by the maintainer 2026-09-22 (originally gaps_found: both gaps are plan-level over-claims whose intent is now met. The phase goal and all five roadmap success criteria are VERIFIED against live evidence. See "Gaps Summary".)
**Re-verification:** No. This is the initial verification.
**Codebase verified:** origin/main `53b5d71a` (detached checkout `.../scratchpad/prbranch`); release tag `v0.10.0` -> `3d148435`.

## Goal Achievement

### Roadmap Success Criteria (the contract)

| # | Truth | Status | Evidence (independently gathered) |
|---|-------|--------|-----------------------------------|
| SC1 | Threadline 0.10.0 is live on hex.pm with clean, grouped HexDocs (RELEASE-01) | VERIFIED | `hex.pm/api/packages/threadline`: `latest_stable_version=0.10.0`, inserted `2026-09-22T21:46:35Z`, `has_docs=true`, no retirement, checksum `70994bb8…` (matches publish log line "Package published … (70994bb8…)"). `threadline.hexdocs.pm/0.10.0/` HTTP 200, ExDoc v0.40.1. Sidebar `sidebar_items-85894A6E.js`: 42 modules, **0 ungrouped** (Core API 13, Data Types 14, Configuration & Extension Points 11, Operator Surface 3, Integrations 1). 10 tasks, all `Mix.Tasks.Threadline.*`, with no `release.pins` or critic tasks. Extras are all grouped except the auto-generated `api-reference`. No critic/stress/mechanical/design-system module on the index. The publish job's "Generating docs…" step emitted no threadline warnings (the only two warnings are in the `phoenix` dep's compile). Published tarball downloaded from repo.hex.pm and unpacked: 131 files, only `CHANGELOG.md` (no `CHANGELOG-GENERATED.md`), no critic, release.pins, stress or mechanical files, and **zero** matches for `D-\d{2,}`, requirement IDs, or `v1.4x` literals. |
| SC2 | Every version-bearing line is managed by release automation, so a version bump requires no hand edits, enforced by `version_truth_doc_contract_test.exs` (RELEASE-02) | VERIFIED (true **now**, and was ticked before it was true) | **Empirical proof from the real release:** the squash-merged release commit `3d148435` touches exactly 9 files, and both constituent commits were produced by automation. `689b8d34` was created at 20:33:39Z inside the Release Please job of release run 35780709941 (20:30:18–20:33:42) and touches manifest, mix.exs, CHANGELOG-GENERATED.md and the two `x-release-please-version` lines. `2f5248b9` was authored by `github-actions[bot]` and pushed by the `Sync install pins on Release PR` job of the same run (20:33:45–20:35:04); it touches README + 5 guides, which are the six pins. The attestation row was rewritten by the `distribution-sync` bot (PR #45, commit `aa349ba4`, `github-actions[bot]`). **No human edit landed in the version bump.** Structurally, `release.yml` `sync-release-pr-pins` runs `mix release.pins` and `--check` on `release-please--branches--main` whenever `prs_created`, and stages only `README.md guides/`. `release-please-config.json` extra-files lists only the two SSOT prose lines, and no pin file appears there. `version_truth_doc_contract_test.exs` has Family A (pins = derived `~> x.y.0`), Family B (marked lines carry @version and are registered), B-inverse (no pin line carries a release-please marker, D-06) and Family C (upgrade coverage). A grep of the whole tree at 53b5d71a for `0.10.0`/`0.9.x` literals finds each one automation-owned or classified as illustrative in the CONTRIBUTING.md "Version-bearing lines and who owns them" table (one extra, `bin/verify-clean-checkout`'s `threadline-0.10.0.tar` gitignore probe path, has been illustrative since Phase 200 and stays correct after a bump). Forward proof: the `Bump rehearsal (next minor)` CI job at 53b5d71a = **success** (simulates 0.10.0→0.11.0 including extra-files, `mix release.pins` and release-please's CHANGELOG-GENERATED.md write). Caveat (Info): a minor release still requires a human-*authored* upgrade-path row (Family C fails loudly without it). That is adopter-facing content, not a version substitution, per D-05 and RELEASE-BLOCKERS "Not automatable, and it should not be". |
| SC3 | The Hex evaluator smoke validates the newly published release, not its predecessor (RELEASE-03) | VERIFIED | Smoke job 106951511254 log: env `THREADLINE_HEX_EVALUATOR_MODE: published`, `THREADLINE_PUBLISHED_VERSION: 0.10.0`; resolution block `New: … threadline 0.10.0` then `* Getting threadline (Hex package)`; `6 tests, 0 failures`. `priv/ci/hex_evaluator/mix.exs` has no version literal; its dep is `{:threadline, "== " <> System.fetch_env!("THREADLINE_PUBLISHED_VERSION"), repo: "hexpm"}` in published mode and `repo: "threadline_rehearsal"` by default. `mix.lock` is untracked (`git ls-files` shows no lock file) and gitignored (`.gitignore:97`). **Fail-closed probe run by me:** `env -u THREADLINE_PUBLISHED_VERSION THREADLINE_HEX_EVALUATOR_MODE=published mix deps` → exit 1, `System.EnvError … "THREADLINE_PUBLISHED_VERSION" … not set` at `mix.exs:59`. |
| SC4 | The 0.10.0 changelog entry opens with human-written highlights above the generated commit list (RELEASE-04) | VERIFIED | `CHANGELOG.md` at 53b5d71a: its HUMAN-OWNED header comment is followed by `## Unreleased — highlights` (unbracketed) and then `## [0.10.0] - 2026-09-22`, which opens with a prose highlight paragraph, then `### Breaking changes` (**None**, with reasons), `### Required action` (the four D-16 actions), `### Storage schema default`, and only then `### Added`. The generated commit list lives in bot-owned `CHANGELOG-GENERATED.md` (`changelog-path` in release-please-config.json), and the published tarball does not ship it. hex.pm `meta.links.Changelog = …/blob/v0.10.0/CHANGELOG.md` returns HTTP 200. The ordering is enforced by `changelog_contract_test.exs` (7 tests: highlights-first, breaking/required-action before feature tour, no generated bullets in the human entry, no bracketed unreleased heading, release-please has no claim on CHANGELOG.md), which runs inside CI's `verify-test` (1693 tests, 0 failures at 3d148435). |
| SC5 | Release-shape and post-publish distribution-sync checks pass against the published tarball (RELEASE-05) | VERIFIED | Release run 35787338837 (`success`, sha 3d148435): Publish job log `Release shape OK for version 0.10.0`, `Saved to threadline-0.10.0.tar`, `Package published …`, `Hex.pm lists threadline 0.10.0`. Timeline: publish 21:45:18–21:46:40 → smoke 21:46:42–21:47:44 → distribution-sync 21:47:47–21:48:00. `distribution-sync` has `needs: [release-ref, publish-hex, smoke-published]` plus an explicit `needs.smoke-published.result == 'success'` guard. The sync opened PR #45 (`aa349ba4`, bot), which was merged as `53b5d71a`. At 53b5d71a the attestation row reads `latest is **0.10.0** (tag **v0.10.0**) … actions/runs/35787338837`. Publish approval: `production-hex` approved by `szTheory` ("Release 0.10.0 from 3d148435"). |

**Goal clause "PR #26 is merged":** VERIFIED. `gh pr view 26` → MERGED 2026-09-22T21:33:11Z, merge commit `3d148435`. CI at that commit (run 35787338903): 16/16 success, `1693 tests, 0 failures, 1 excluded`.
**Goal clause "public surface Phases 200/201 already made clean":** VERIFIED against the published artifact (tarball vocabulary scan and HexDocs grouping above).

### Plan must-haves (merged; roadmap SCs above take precedence)

| Plan | Truth (abridged) | Status | Evidence |
|------|------------------|--------|----------|
| 01 | Unconfigured (0.9.x-shaped `public`) install captures + reads back on 0.10.0 | VERIFIED | Smoke job ran `legacy_public_schema_test.exs` (4 tests: no storage_schema configured / resolves to public / tables physically in public, no threadline schema / trigger-written row reads back unprefixed) against the **real hex.pm artifact**. Log shows `"Legacy public schema"` inserts; `6 tests, 0 failures`. The published tarball has `@default "public"` (`lib/threadline/storage_schema.ex:22`). |
| 01 | Rehearsal mode resolves from THIS tree's tarball | VERIFIED | `mix.exs` default mode → `repo: "threadline_rehearsal"`; `bin/with-rehearsal-registry` present; CI `Hex evaluator smoke` success at 53b5d71a |
| 01 | No threadline version literal in hex_evaluator tracked source | VERIFIED | Only explanatory comments at mix.exs:47-48; no requirement, no lock |
| 01 | Installer recommends a dedicated schema when unconfigured | VERIFIED | `threadline.install.ex:26,71-80` `recommend_dedicated_storage_schema/0` |
| 01 | Repo suite and example app are unaffected by the flip | VERIFIED | `config/test.exs:50` and `examples/threadline_phoenix/config/config.exs:16` set `storage_schema: "threadline"`; CI 1693/0 and example 117/0 |
| 01 | (backstop) Published mode hard-fails when the version is unset | VERIFIED | Probe run by me: exit 1 with System.EnvError |
| 02 | Minor bump pins produced by `mix release.pins` with no hand edit | VERIFIED | `2f5248b9` (bot) is the only writer of the six pins in the release |
| 02 | Patch-zero no-op / empty-file no-op / idempotent | VERIFIED | `--check` step in sync job; rehearsal `--check` → 0 differ (CI success) |
| 02 | No pin line carries a release-please marker (test-enforced) | VERIFIED | `version_truth_doc_contract_test.exs:112` |
| 02 | Hex archive has no maintainer tooling | VERIFIED | Published tarball unpacked: none present |
| 02 | (backstop) Version-bearing lines classified in writing | VERIFIED | CONTRIBUTING.md:655-674 table; my own grep of README/guides/CONTRIBUTING found no unclassified literal |
| 03 | Highlights before generated list; breaking/required action first; ordering test-enforced; empty highlights fail | VERIFIED | See SC4; `changelog_contract_test.exs:82,99` |
| 03 | Human and generated changelogs in separate files | VERIFIED | `changelog-path: CHANGELOG-GENERATED.md` |
| 03 | 0.10.0 entry: no breaking, no storage action, four adopter actions | VERIFIED | CHANGELOG.md lines 35-80; upgrade-path.md:115-125 |
| 03 | No heading collides with version-header regex except dated releases | VERIFIED | `## Unreleased — highlights` unbracketed; test at :136 |
| 03 | (backstop) Changelog link resolves to the human file | VERIFIED | hex meta link → `blob/v0.10.0/CHANGELOG.md`, HTTP 200 |
| 04 | Env-protection deletion goes red | VERIFIED (wiring + live runs) | `bin/verify-environment-protection`; `environment-protection.yml` runs success at 18:16, 20:41, 21:44Z |
| 04 | Sync waits on smoke; smoke not in ci-required; allowed-skips/failures empty | VERIFIED | release.yml:564-568; ci.yml ci-required needs list (no smoke-published), no `allowed-skips:`/`allowed-failures:` keys |
| 04 | Every publish-gate member satisfiable pre-publish; approval documented as confirmation; recovery runbook written | VERIFIED | release.yml publish-hex needs; CONTRIBUTING.md:711-735 (revert window, retire + same-day patch, removal unavailable) |
| 04 | (backstop) Smoke resolves just-published version | VERIFIED | Smoke log (SC3) |
| 05 | 0.10.0 live, HexDocs grouped, no build warnings | VERIFIED | SC1 |
| 05 | **Release PR green by construction on the first CI run after the update** | **FAILED** | First run 35765331006 at b4aa566e: 12/4. See gap 1 |
| 05 | Publish preceded by explicit human confirmation; no autonomous push/merge/publish | VERIFIED | Deployment approval by szTheory with comment; SUMMARY records named authorizations for #43/#44/#26 |
| 05 | Smoke green in published mode before attestation | VERIFIED | SC5 timeline |
| 05 | Release-shape passes against the published version with a dated heading | VERIFIED | `Release shape OK for version 0.10.0` in publish-hex log |
| 05 | (backstop) Recovery procedure usable under pressure | VERIFIED (to the extent it can be) | Runbook exists (CONTRIBUTING.md:711-735). It was not needed, because no recovery was triggered (0.10.0 is not retired). No further check is possible. Recorded as Info, not a human item, because the release it guarded has already shipped cleanly. |
| 06 | Dialyzer 0 errors; version read at runtime; no ignore entry | VERIFIED | CI `Dialyzer (current toolchain)` success at 53b5d71a and at 3d148435 |
| 07 | `mix docs --warnings-as-errors` exits 0; entry still names modules; no visibility change | VERIFIED | Bump rehearsal runs `verify.release` (docs WAE) → success in CI; CHANGELOG names 25 modules; `c:Threadline.Storage.put/2` qualified |
| 08 | Critic-trust scratch dirs unique across runs, cleaned | VERIFIED | CI verify-test 1693/0 on 3 successive main runs |
| 09 | README pin assertion derived from the shared `target_pin_version/0` | VERIFIED | `release.pins.ex:119 def target_pin_version`; bump rehearsal green |
| 10 | Born-red defect fails a check on the introducing PR; rehearsal at next minor; trace-free; fail-closed | VERIFIED | `verify-bump-rehearsal` in ci-required needs (ci.yml:941), success at 53b5d71a |
| 10 | **(backstop) Gate would have caught all three Task-1 born-red causes** | **FAILED as worded** | 2/3 (BR-3 not covered by this gate). See gap 2 |

**Score:** all 5 roadmap SCs verified; 44/46 merged must-haves verified; 0 present-but-behavior-unverified.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| RELEASE-01 | 01, 05, 06, 07, 08, 09, 10 | 0.10.0 on hex.pm with clean, grouped HexDocs | SATISFIED | SC1. REQUIREMENTS.md still shows `[ ]` / Pending, so the orchestrator should update it |
| RELEASE-02 | 02, 09, 10 | Every version-bearing line managed by release automation | SATISFIED (now) | SC2. Ticked Complete before PR #44 made it true. It is true on origin/main, proven by the real release commit being 100% bot-authored |
| RELEASE-03 | 01, 04 | Evaluator smoke validates the newly published release | SATISFIED | SC3 |
| RELEASE-04 | 03 | Changelog entry opens with human highlights above the generated list | SATISFIED | SC4 |
| RELEASE-05 | 04, 05 | Release-shape + distribution-sync pass against the published tarball | SATISFIED | SC5. REQUIREMENTS.md still shows `[ ]` / Pending, so the orchestrator should update it |

No orphaned requirements: REQUIREMENTS.md maps exactly RELEASE-01..05 to Phase 202, and every ID appears in at least one plan's `requirements:`.

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| release-please (PR create/update) | six doc pins | `sync-release-pr-pins` → `mix release.pins` → bot push | WIRED (proven: 2f5248b9) |
| release-ref version | smoke `THREADLINE_PUBLISHED_VERSION` | release.yml:521 env → hex_evaluator `== version` | WIRED (proven: log) |
| publish-hex | smoke-published | distribution-sync | `needs:` + result guards | WIRED (proven: timeline) |
| `changelog-path` | CHANGELOG-GENERATED.md | release-please-config.json | WIRED (release commit wrote 136 lines there, 0 to CHANGELOG.md) |
| `package[:files]`/`exclude_patterns` | published tarball | `mix hex.build` | WIRED (tarball inspected) |
| `Threadline.StorageSchema @default` | read paths | `get/1` | WIRED (legacy-public test green on published artifact) |

### Behavioral Spot-Checks / Live Evidence

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 0.10.0 latest on hex | `curl hex.pm/api/packages/threadline` | latest_stable 0.10.0 | PASS |
| HexDocs grouping | fetch sidebar_items-85894A6E.js | 42/42 modules grouped | PASS |
| Tarball clean | download repo.hex.pm tarball, grep | 0 vocab hits, no GENERATED/critic/pins | PASS |
| Smoke resolved published 0.10.0 | `gh run view … --job 106951511254 --log` | `threadline 0.10.0` from Hex, 6/0 | PASS |
| Published mode fails closed | `env -u THREADLINE_PUBLISHED_VERSION THREADLINE_HEX_EVALUATOR_MODE=published mix deps` | exit 1, EnvError | PASS |
| Release commit bot-authored | `gh api commits/689b8d34`, `gh pr view 26 --json commits` | release-please job + github-actions[bot] | PASS |
| Main CI at 3d148435 | run 35787338903 | 16/16, 1693/0 | PASS |
| Main CI at 53b5d71a | run 35789879500 | in progress at 22:05Z; 11 jobs completed success (incl. Bump rehearsal, Dialyzer, Hex evaluator smoke, Build ExDoc, Hex package tarball, Release metadata), 4 still running | PASS so far (non-blocking) |

### Probe Execution

Step 7c: no `scripts/*/tests/probe-*.sh` declared or present for this phase. Not applicable.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `mix.exs` (`ci.all` alias) | 184-192 | `verify.doc_contract` is a silent no-op inside `ci.all` (Mix runs `test` once per VM; no `Mix.Task.reenable`) | Warning | Local aggregate is weaker than it reads. No coverage lost (the 134 tests run inside verify.test's 1693), and CI runs them as separate jobs. Open follow-up D2, not covered by Phase 203's SCs. Needs a backlog item. |
| `bin/verify-bump-rehearsal` | 192 | `XXX` | Info | mktemp template, not a debt marker |
| repo settings | — | `main` has no branch protection (per 202-05 SUMMARY) | Info | Out of scope for 202 (GREEN-08 territory); the maintainer gate was the only thing holding a red release PR |

No TBD/FIXME/unreferenced debt markers in phase-modified files.

### Human Verification Required

None. Every success criterion was checked against a live API, log, artifact, or local probe.

### Gaps Summary

**The phase goal is achieved.** PR #26 is merged, 0.10.0 is live on hex.pm with fully grouped HexDocs and a clean tarball, the smoke job proved the exact published version installs (including a legacy `public`-schema host), distribution-sync attested only after the smoke, and the changelog is human-owned with breaking changes and required action first. RELEASE-02 is true **now**: the actual 0.10.0 version bump contained zero human edits, and the next-minor rehearsal is green in CI.

Both gaps share one root cause. **The release-PR born-red prevention was over-claimed at execution time.** Both are historical/plan-wording failures with no code change outstanding:

1. **202-05 "green by construction on the first CI run"**: false. The first run was red (12/4) and needed PR #44. It can never become true retroactively. Its forward-looking intent is now proven.
2. **202-10 backstop "would have caught all three born-red causes"**: false as worded (2/3). BR-3 is caught by the separately required `verify-dialyzer` job instead.

These are real FAILED must-haves under the rules, so the status cannot be `passed` without maintainer acceptance. **This looks intentional/superseded.** To accept, add to this file's frontmatter:

```yaml
overrides:
  - must_have: "The release pull request is green by construction on the first CI run after the update — both measured born-red causes are closed before the run, not patched after it."
    reason: "First release-PR run (35765331006) was red; fixed by PR #44 (sync-release-pr-pins + changelog test). Forward invariant proven: #26 16/16 at 2f5248b9, release commit fully bot-authored, bump-rehearsal CI green at 53b5d71a. Historical event cannot be re-run."
    accepted_by: "{maintainer}"
    accepted_at: "{ISO timestamp}"
  - must_have: "The gate would have caught all three of the born-red causes found at Phase 202 Task 1."
    reason: "verify-bump-rehearsal catches BR-4 and BR-5; BR-3 (Dialyzer) is caught on every PR by verify-dialyzer, also a ci-required member. Intent (born-red defects fail a required check on the introducing PR) holds for the composite gate."
    accepted_by: "{maintainer}"
    accepted_at: "{ISO timestamp}"
```

Non-blocking follow-ups: D2 `ci.all` doc_contract no-op (Warning; not scheduled in any later phase); REQUIREMENTS.md RELEASE-01/05 checkboxes and traceability still say Pending; main CI run 35789879500 at 53b5d71a was still in progress at verification time (all 11 completed jobs green).

---

_Verified: 2026-09-22T22:10Z_
_Verifier: Claude (gsd-verifier)_

## Addendum (2026-09-24, Phase 205): verified on the milestone branch

The v1.41 milestone audit (`.planning/v1.41-MILESTONE-AUDIT.md`, finding F1) found that this report's evidence came from origin/main 53b5d71a, not the milestone branch. At the time, the branch did not contain Phase 202's shipped release commits. Phase 205 (plan 205-01) merged origin/main 471ebf6e (v0.10.1) into `fix/branch-protection-actions-capability` as one merge commit. The values below are copied from `.planning/phases/205-release-reconciliation/205-01-SUMMARY.md`, not re-derived.

| Check | Result on the milestone branch |
|-------|--------------------------------|
| Merge commit | `0d8ced0cc0af86d30fed6d973543305318e541b6`, parents `ca99ff7c` (pre-merge HEAD) and `471ebf6e` (origin/main, v0.10.1) |
| Follow-ups | `849707e2` (installer test credo alias), `8f846b74` (sync-pins contract test), `486a1392` (bump-rehearsal CI row wording) |
| `git merge-base --is-ancestor v0.10.0 HEAD` | exit 0 |
| `git merge-base --is-ancestor v0.10.1 HEAD` | exit 0 |
| `git rev-list --count HEAD..origin/main` | 0 |
| `mix.exs` | `@version "0.10.1"` |
| `MIX_ENV=dev mix release.pins --check` | exit 0: scanned 20 files, 0 pin sites differ, derived `~> 0.10.0` |
| `release.yml` `sync-release-pr-pins` job | present, and pinned by the new test in `test/threadline/release_control_plane_contract_test.exs` (proven RED against the pre-merge release.yml) |
| Changelog contract | green (runs inside the bump-rehearsal gate chain; the #44 correction is merged) |
| `mix verify.bump_rehearsal` | exit 0: `Bump rehearsal OK: a 0.10.1 -> 0.11.0 release commit passes every doc-contract test` (closes audit F2) |
| `mix verify.release`, clean clone at `486a1392` | exit 0: 38 tests, 0 failures, builds threadline 0.10.1 |
| Full `DB_PORT=5433 mix test` at `486a1392` | 1787 tests, 0 failures, 1 excluded |

RELEASE-02 and RELEASE-05 now hold on the milestone branch. The frontmatter above, including the `NOTE: shipped code was verified at origin/main 53b5d71a` comment, is historical and deliberately unchanged.
