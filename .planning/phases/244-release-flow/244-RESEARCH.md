# Phase 244: Release flow - Research

**Researched:** 2026-10-24
**Domain:** GitHub Actions release automation (release-please v5 + release.yml), Hex/Mix dependency tooling, CHANGELOG ownership contracts
**Confidence:** HIGH on repo facts and the REL-04 cause, MEDIUM on the exact `prs_created` behaviour under `always-update` (the one claim only an observed run can close)

<user_constraints>
## User Constraints (from CONTEXT.md)

No CONTEXT.md exists for this phase. The maintainer chose to plan without discuss-phase.
This research therefore makes and justifies the open decisions (see "Decisions made here").

### Locked Decisions
None from CONTEXT.md. Locked inputs come from `.planning/REQUIREMENTS.md` (REL-01..REL-04), the Phase 244 roadmap success criteria, and CLAUDE.md.

### Claude's Discretion
All mechanism choices (rename mechanism, rebase mechanism, retry wrapper, Hex pin mechanism, test shapes).

### Deferred Ideas (OUT OF SCOPE)
Phase 245 owns SHA-pinning of actions, Dependabot, and the tiered deps-audit gate (SUP-01..04). Phase 244 must not add new `uses:` references (see Phase 245 interactions).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Release workflow renames `## Unreleased` to `## [X.Y.Z] - YYYY-MM-DD` on the release branch; first release-PR CI is green; no dating PR | `bin/date-release-changelog` run inside `sync-release-pr-pins`; contract updates listed below |
| REL-02 | Stale release PR (release-please "unchanged") is refreshed with a CI-triggering token; CI reruns with no human action | `"always-update": true` in `release-please-config.json`, plus the PAT that already exists (`RELEASE_PLEASE_TOKEN`) |
| REL-03 | `mix deps.get` and the hex-evaluator resolve retry with backoff; test steps are never retried | `bin/retry-network` shell wrapper + `retry_network_contract_test.exs` |
| REL-04 | Cause of the 1.1.0 `--check-locked` mismatch verified; pin Hex in CI if drift is the cause | Cause reproduced below; pin Hex 2.6.0 via `install-hex: false` + `mix local.hex 2.6.0 --force` |
</phase_requirements>

## Summary

The 1.1.0 release took four PRs because three things were manual: the CHANGELOG heading was dated by a separate PR (#87), the stale release PR (#86) was not refreshed after that non-releasable merge, and the release PR's first CI run (22:29Z) was red because `bin/verify-release-shape` could not find a dated `## [1.1.0]` heading. The release workflow already has everything needed to fix this: `RELEASE_PLEASE_TOKEN` exists as a repo secret and is demonstrably a CI-triggering token (release-branch pushes produce `pull_request` CI runs, for example run 40054042788), and the `sync-release-pr-pins` job already checks out the release branch, edits docs, and pushes with that PAT after every release-please create/update.

Recommendation in one line: add `"always-update": true` to `release-please-config.json` so release-please regenerates the release PR on current `main` after every push (this is the "rebase", done by the PAT), extend the existing `sync-release-pr-pins` job with one deterministic step that renames `## Unreleased — highlights` to `## [X.Y.Z] - date` (re-seeding the standing block), wrap only `mix deps.get`-class fetches in a small `bin/retry-network` shell wrapper, and pin Hex 2.6.0 in every workflow job. REL-04 was verified by experiment: the 1.1.0 failure was a `mix.lock` whose `plug_crypto` entry carried an empty manager list `[]`; Hex 2.5.1 (the version the maintainer's machine has) accepts that under `--check-locked`, Hex 2.6.0 (what unpinned CI installed, released 2026-10-23T11:57Z) rejects it.

**Primary recommendation:** One regenerate mechanism (`always-update`), one rename script (`bin/date-release-changelog`, bash + perl, no BEAM), one retry script (`bin/retry-network`, shell), one Hex pin (2.6.0, uniform across jobs); every one gets a contract test with mutation controls, following the repo's existing pattern.

## Project Constraints (from CLAUDE.md)

- Prefer named `mix verify.*` / `mix ci.*` entrypoints; cite them verbatim (`mix verify.test`, `mix verify.release`, `mix verify.bump_rehearsal`, `mix verify.deps_audit`, `mix ci.all`).
- Honest default tests: never silently exclude a suite from `mix test`.
- Stable CI job IDs: do not rename job `id:` fields in workflows (names may change). Therefore keep `sync-release-pr-pins` as the job id even though it will also date the changelog.
- Doc contract tests: README, guides and CONTRIBUTING stay aligned by test assertions. CONTRIBUTING "Ongoing releases" (CONTRIBUTING.md:1063-1066) must be updated in the same change.
- Zero human verification by default: automate verification; hand the maintainer only secrets/spend/push/scope.
- `state.begin-phase` needs flags with gsd-core v1.14.0; hand-check STATE.md/ROADMAP.md after `state.*` calls.
- Never `git add .planning/` wholesale; never run `npx` for `@opengsd` packages (orchestrator instruction).
- Executors route around preconditions: planner prompts must forbid editing protected files to pass a gate.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release PR creation/refresh | release-please (GitHub Action, PAT) | `release-please-config.json` | Release-please owns the branch contents; `always-update` makes it regenerate on current main |
| Changelog heading rename | `release.yml` job `sync-release-pr-pins` (script `bin/date-release-changelog`) | contract tests | Must happen on the release branch, after release-please's force-push, before CI's final run |
| CI trigger on release PR head | `RELEASE_PLEASE_TOKEN` PAT pushes | `bootstrap-release-pr-ci` dispatch (PAT-absent fallback only) | GITHUB_TOKEN pushes do not fan out workflows |
| Network retry | `bin/retry-network` (shell) | `mix.exs` alias for hex-evaluator, `bin/` scripts | Repo-local, testable offline, no new third-party action |
| Hex version pin | each workflow job (`install-hex: false` + pin step) | `bin/verify-deps-audit` floor | Hex has no version input in setup-beam |
| Shape enforcement | ExUnit contract tests + `bin/verify-release-shape` | `mix verify.bump_rehearsal` | Existing pattern: contracts parse workflows/YAML and carry mutation controls |

## Standard Stack

No new external packages. Everything is already in the repo or the runner image.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| googleapis/release-please-action | v5 (`@v5` at release.yml:105; v5.0.0 published 2026-04-22) | Opens/updates release PR | Already in use. Bundles release-please ^17.6.1 which supports `always-update` [CITED: raw.githubusercontent.com/googleapis/release-please-action/main/package.json, schemas/config.json "always-update"] |
| erlef/setup-beam | v1 (latest tag v1.24.1) | Toolchain + `install-hex` input | Has `install-hex` (default true) and `install-rebar`, no Hex version input [CITED: setup-beam action.yml] |
| Hex | 2.6.0 (released 2026-10-23T11:57:00Z) | Pinned package manager | The version CI ran when 1.1.0 went green [VERIFIED: `gh api repos/hexpm/hex/releases`, CI log "creating /home/runner/.mix/archives/hex-2.6.0", run 40028641095] |
| bash + perl | runner image | `bin/date-release-changelog`, `bin/retry-network` | `bin/verify-bump-rehearsal` already uses perl for the same CHANGELOG edit |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `always-update: true` | `gh pr update-branch --rebase` in a new job | Rebase replays the dated-changelog commit onto a main that may have edited `## Unreleased` -> conflict; does not re-run pin sync; needs its own staleness detection (`compare` API behind_by). Rejected. |
| `bin/retry-network` shell | `nick-fields/retry` action | New third-party `uses:` (Phase 245 would have to SHA-pin it), applies to steps not to the inner `deps.get` inside `mix verify.hex_evaluator`, and makes "wrap a test step" a one-line mistake. Rejected. |
| Mix task for the rename (like `release.pins`) | Bash+perl script | A new `lib/mix/tasks/*.ex` needs `exclude_patterns` in mix.exs:547-555, an entry in `@maintainer_only_paths` (release_artifact_contract_test.exs:166-190) and source-size accounting. A `bin/` script needs none of that. |
| Date the section at publish time | Date on release branch | Post-merge dating needs another PR, which is exactly what REL-01 removes. |

**Installation:** none. (`mix local.hex 2.6.0 --force` is the pin; no package install.)

**Version verification:** `mix local.hex 2.6.0 --force` and `mix local.hex 2.5.1 --force` both install into an isolated `MIX_HOME` on this machine's Elixir 1.17.3/OTP 27 [VERIFIED: experiment this session, output `* creating .../archives/hex-2.6.0`].

## Package Legitimacy Audit

No external packages are installed by this phase. The seam `gsd_run query package-legitimacy check` was not needed.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | - | - | - | - | - | - |

**Packages removed due to [SLOP]:** none
**Packages flagged [SUS]:** none
`nick-fields/retry` was considered and rejected on design grounds; it is not recommended and not verified.

## Evidence Base (facts the plan rests on)

### E1. How the CHANGELOG is produced today
- `CHANGELOG.md` is human-owned: release-please's `changelog-path` is `CHANGELOG-GENERATED.md` [VERIFIED: release-please-config.json]. Verbatim: `"changelog-path": "CHANGELOG-GENERATED.md",`. The test `changelog_contract_test.exs` asserts that and refutes any mention of `CHANGELOG.md` in the config.
- The standing staging block is, verbatim from CHANGELOG.md:19-21: `## Unreleased — highlights` then `_Nothing yet for the next release._`. Note the REQ text says `## Unreleased`; the literal heading in the repo is `## Unreleased — highlights` with an em dash. The rename script must match that literal (and may also accept bare `## Unreleased`).
- Tests hard-depend on the standing heading existing after a release: `upgrading_to_1_0_doc_contract_test.exs:50` (`heading_section!(content, ~r/^## Unreleased — highlights$/, @changelog_path)` flunks if absent) and `guides/upgrade_path_contract_test.exs:253`. `changelog_contract_test.exs` refutes bracketed `[Unreleased]` headings (`@bracketed_unreleased_regex`). Therefore the rename must **re-seed** a fresh `## Unreleased — highlights` / `_Nothing yet for the next release._` block above the new dated heading.
- 1.1.0 history: landing PR #85 (`land/v1.46`, merged 2026-10-23T22:27Z) -> release PR #86 (`chore(main): release 1.1.0`, merged 2026-10-24T02:53Z) -> dating PR #87 (`docs/date-1.1.0-changelog`, commit 28af5d3d, adds `## [1.1.0] - 2026-10-23` and the `1.0.x → 1.1.x` upgrade-path row in guides/upgrade-path.md) -> distribution sync PR #88. 1.0.1 followed the same shape (#81, #82, #83, #84).
- Release PR #86's first CI run (run 40033918741, head a38b6e31, 22:29Z) was **red**; its "CHANGELOG matches version" job failed (`bin/verify-release-shape` needs `## [1.1.0] - date`) and `Build and test (current)` failed at `test/threadline/version_truth_doc_contract_test.exs:160` (the `1.0.x -> 1.1.x` upgrade-path coverage derived from CHANGELOG headings) [VERIFIED: `gh run view 40033918741 --log-failed`]. This is the REL-01 born-red defect.

### E2. Why the release PR went stale
- After the non-releasable merge #87, release run 40038808445 logged `✔ PR https://github.com/szTheory/threadline/pull/86 remained the same`, and `Sync install pins on Release PR` and `Bootstrap CI on Release PR` were **skipped** (`prs_created` false) [VERIFIED: gh run view 40038808445 --log].
- Mechanism in release-please source: `createOrUpdatePullRequest` picks `this.alwaysUpdate ? updateExistingPullRequest : maybeUpdateExistingPullRequest`; the latter returns `undefined` ("remained the same") when only the body is compared and unchanged [CITED: github.com/googleapis/release-please/blob/main/src/manifest.ts lines 1048-1062, 1090-1104].
- Config docs: `always-update`: "if true, always update existing pull requests when changes are added ... instead of only when the release notes change ... can be useful if pull requests must not be out-of-date with the base branch" [CITED: release-please docs/manifest-releaser.md]. Schema: `"always-update": {"description": "Always update the pull request with the latest changes. Defaults to `false`.", "type": "boolean"}` [CITED: schemas/config.json:130].

### E3. The CI-triggering token already exists and works
- `gh secret list` shows `RELEASE_PLEASE_TOKEN` (updated 2026-05-28T15:14:58Z) and `HEX_API_KEY` [VERIFIED: gh secret list]. **No maintainer handoff for a secret is needed.**
- release.yml uses it at the release-please step (`token: ${{ secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN }}`, release.yml:105-109) and in the pin-sync push (`PUSH_TOKEN`, release.yml:183).
- Proof it fans out CI: `pull_request` CI runs exist for pushes to `release-please--branches--main`: run 40054042788 (head a4fcf36a, success), 40033918741, 40033779611 (cancelled, superseded) [VERIFIED: gh run list --branch release-please--branches--main]. Release PR #86 had two bot commits (`chore(main): release 1.1.0` 9ce21ca8 and `chore(release): sync documented install pins to @version` a4fcf36a). An intermediate cancelled run on the first push is expected: ci.yml concurrency cancels superseded `pull_request` runs (ci.yml concurrency block).
- Residual risk: a fine-grained PAT can expire. release.yml already says an expired PAT "fails loudly at the release-please step". Not a Phase 244 change, but record the expiry date in the maintainer-handoff list if the executor can read it (it cannot via API; flag as open question Q2).

### E4. Where `mix deps.get` and the hex-evaluator resolve run
- `run: mix deps.get` step lines: ci.yml:156, 203, 305, 369, 479, 689, 770, 864, 888, 1023, 1047; browser-full.yml:120; flake-detection.yml:127; release.yml:170 (sync job), release.yml:492 (publish-hex) [VERIFIED: grep -n "mix deps.get" .github/workflows/*.yml].
- Nested fetches: `mix.exs` `verify_hex_evaluator` builds `steps = "printf \"n\\n\" | mix deps.get && mix compile --warnings-as-errors && mix ecto.create --quiet -r HexEvaluator.Repo && mix ecto.migrate --quiet && mix test"` (mix.exs:~470) and runs it as one `bash -lc` chain, so the CI step `run: mix verify.hex_evaluator` (ci.yml:248) contains **tests**. Retry must therefore sit inside that chain around `mix deps.get` only, never around the CI step. Other nested fetches: mix.exs:226 (`test.setup`), :272, :285, :345 (`verify_example`), `bin/verify-bump-rehearsal:461`, `bin/verify-deps-audit:331` (`deps.get --check-locked`), `bin/deps-health-report:243`, `bin/verify-clean-checkout:61`, `bin/verify-planning-independent:114`.
- 13 workflow files contain 17 `erlef/setup-beam` uses (ci.yml 12, release.yml 3, browser-full 1, deps-health 1, flake-detection 1; one ci.yml use is the matrix lane at ci.yml:659-661).

### E5. REL-04: the 1.1.0 `--check-locked` failure (verified cause)
- Failing run: **40028641095** (`pull_request`, branch `land/v1.46`, head a3301bed `fix(deps): update bandit and plug_crypto for new advisories`, 2026-10-23T21:41Z), job "Dependency audit (Mix lockfiles)" id 120671240310. Log, three times: `** (Mix) Your mix.lock is out of date and must be updated without the --check-locked flag`, then `FAIL .: deps.get --check-locked exited 1 ...` (also `bench`, `examples/threadline_phoenix`) [VERIFIED: gh run view 40028641095 --log --job 120671240310].
- The diff that fixed it: commit f7fdcaca `fix(deps): restore plug_crypto build manager in locks`, verbatim one-line change in `mix.lock`, `bench/mix.lock`, `examples/threadline_phoenix/mix.lock`: `"2.2.1", "bd1d03...", [], [], "hexpm", "4417cc..."` became `"2.2.1", "bd1d03...", [:mix], [], "hexpm", "4417cc..."` [VERIFIED: git show f7fdcaca; git show a3301bed]. The offending field is the 5th tuple element, the **manager list**: `[]` instead of `[:mix]`. hex.pm metadata for plug_crypto 2.2.1 says `"build_tools":["mix"]` [VERIFIED: curl https://hex.pm/api/packages/plug_crypto/releases/2.2.1].
- CI toolchain: `.tool-versions` = `nodejs 22.14.0 / erlang 27.3.4.15 / elixir 1.17.3-otp-27` [VERIFIED: cat .tool-versions]; setup-beam ran `mix local.hex --force` with **no version**, creating `hex-2.6.0` [VERIFIED: run 40028641095 log]. Hex 2.6.0 was published 2026-10-23T11:57:18Z, ~10 hours before the failing run; Hex 2.5.4 was 2026-10-20 [VERIFIED: gh api repos/hexpm/hex/releases].
- Local toolchain: `<home>/.mix/archives/` holds only `hex-2.5.1` on the maintainer machine [VERIFIED: ls <home>/.mix/archives].
- **Reproduction (this session, isolated `HEX_HOME`/`MIX_HOME` in the scratchpad, minimal project with `{:plug_crypto, "2.2.1"}` and the `[]` lock entry from a3301bed):**
  - Hex 2.6.0, `mix deps.get --check-locked` -> `** (Mix) Your mix.lock is out of date and must be updated without the --check-locked flag`.
  - Hex 2.5.1, same lock, same command -> `All dependencies are up to date`.
  - Fresh `mix deps.get` and `mix deps.update` under **both** versions write `[:mix]`, not `[]`.
- **Conclusion (HIGH):** The *rejection* is Hex-version dependent (2.5.1 accepts a lock whose manager list is `[]`, 2.6.0 rejects it), so the failure was invisible to a local 2.5.1 run and appeared only in CI, where Hex floated to latest. Neither Hex version produces `[]` through `deps.get`/`deps.update` in the reproduction, so the malformed entry most likely came from a hand- or tool-edited lock line, not from Hex. Both facts justify the same fix: pin Hex in CI so behaviour is deterministic, and raise the local floor so a stale local Hex is told to upgrade. State this honestly in the RESEARCH/verification record: "drift explains why it surfaced only in CI; the producer of `[]` is unreproduced (ASSUMED hand edit)".
- Existing gate: `bin/verify-deps-audit:61` `MIN_HEX="2.5.1"` and `bin/verify-deps-audit:148`/`:244` (`requires Hex >= $MIN_HEX, found ...`); tests `test/threadline/deps_audit_gate_test.exs:116,182,445` fake Hex 2.5.1 and assert `requires Hex >= 2.5.1`.

## Decisions made here (one recommendation each)

### D-1 (REL-01): rename in `sync-release-pr-pins` via `bin/date-release-changelog`
- **Where:** a new step in the existing `sync-release-pr-pins` job (release.yml:120-197), after `mix release.pins --check` (release.yml:176) and before the commit/push step; add `CHANGELOG.md` to the staged paths (release.yml:188 currently `git add -- README.md guides/`). Rename the commit subject (still `chore(release):`, non-releasable) to cover both, e.g. `chore(release): sync install pins and date the changelog`; the sync test (`release_control_plane_contract_test.exs:138-188`) does not pin the commit message, but grep before changing.
- **Why here:** the job already (a) runs after every release-please create/update, which force-pushes the branch and drops earlier commits (so it must be re-applied every time; the job's own header comment says so), (b) checks out the release branch credential-free (216 CR-01) and (c) pushes with the PAT, which fires CI on the final head. A separate job would add a second push and a second CI cycle.
- **Script contract (`bin/date-release-changelog`, bash+perl, no BEAM, `set -euo pipefail`):**
  - Version: from `mix.exs` `@version` on the release branch (same grep as `bin/verify-release-shape`).
  - Date: first `## [VER](compare-link) (YYYY-MM-DD)` heading in `CHANGELOG-GENERATED.md` (release-please wrote it on this branch; single source, deterministic across reruns), fallback `date -u +%F`, override `--date`.
  - Transform: replace the line `## Unreleased — highlights` (also accept bare `## Unreleased`) with `## [VER] - DATE`, and prepend a fresh `## Unreleased — highlights\n\n_Nothing yet for the next release._\n\n`.
  - Fail loudly (exit non-zero, message naming the landing-PR rule) when the Unreleased body is empty or only the placeholder, because the release PR would otherwise be born red with no prose. If a real body also contains the placeholder line, drop the placeholder.
  - Idempotent: if `## [VER] - ` already exists and the Unreleased block is placeholder-only, exit 0 without writing (safe on rerun and on patch/no-op paths).
  - `--check` mode (no write, non-zero if it would change) and `--self-test` are optional; ExUnit fixtures are the primary proof.
- **Upgrade-path row:** stays human-authored in the landing PR. It does not need renaming: `version_truth_doc_contract_test.exs:160-176` derives `X.Y.x -> X.Y'.x` from the **previous release minor found in CHANGELOG `^## \[` headings** and the bumped `@version`; after the rename the new `[1.2.0]` heading is same-minor and is skipped, so the guide row `1.1.x → 1.2.x` written in the landing PR is exactly what the contract wants on the release branch. On main before the release PR, @version is still 1.1.0, so the row for the *next* minor does not conflict.
- **Date semantics to document:** the date is the day release-please last regenerated the PR (UTC), which can precede the merge day (1.1.0 was dated 2026-10-23, merged 2026-10-24T02:53Z). This matches the old hand-dated behaviour and is acceptable; note it in CONTRIBUTING.
- **Why not the `x-release-please-version` / extra-files route:** the config test refutes any mention of `CHANGELOG.md` in release-please config keys (changelog_contract_test.exs, "release-please owns the generated changelog and has no claim on the human one"). Keeping the rename out of release-please preserves the RELEASE-04 ownership split; the file is edited by a workflow script, not by release-please.
- **Rehearsal parity (mandatory):** `bin/verify-bump-rehearsal:383-399` currently synthesises a stand-in dated heading with perl. Per the memory rule ("a rehearsal step not mirrored by the real release is a lie") change it to: if CHANGELOG has no `## [NEXT]` heading, seed stand-in prose under `## Unreleased — highlights` (when still placeholder) and then run the **real** `bin/date-release-changelog`, so the rehearsal exercises the production script. Header comment at `bin/verify-bump-rehearsal:42-46` ("a human writes it during the release plan") must be updated.

### D-2 (REL-02): `"always-update": true` in `release-please-config.json`
- **What it does:** every push to main while a release PR is open makes release-please force-push the release branch regenerated on current `main`; the action then reports `prs_created` true, so the existing chain fires: `sync-release-pr-pins` (pins + changelog date) -> push with the PAT -> `pull_request` CI on the new head; `bootstrap-release-pr-ci` stays the PAT-absent fallback only (ECON-03 guard unchanged).
- **Why this over `gh pr update-branch --rebase`:** (1) it is the documented feature for exactly "PRs must not be out-of-date with the base branch"; (2) a regenerated branch needs no conflict handling, whereas rebasing the dated-changelog commit conflicts whenever a non-releasable merge touched the `## Unreleased` block (for example a `docs:` prose fix); (3) pins and date are re-applied by the existing job, so the branch is always internally consistent; (4) one mechanism instead of a second job with its own staleness detection.
- **Cost:** one extra release-PR CI run per main push while a release PR is open (the same count a rebase would cost). It only applies while a release PR exists (releasable commits pending).
- **Confidence note (MEDIUM):** that the v5 action sets `prs_created` true for an `always-update` refresh follows from `updateExistingPullRequest` returning the PR (manifest.ts) and from the action defining `prs_created` as "created or updated"; it has not been observed in this repo. The observed run (below) is the closer.
- **Contract test (release_control_plane_contract_test.exs additions):** config has `"always-update": true` (decode JSON, as `changelog_contract_test.exs` already does); the release-please step token is still `RELEASE_PLEASE_TOKEN || GITHUB_TOKEN` (pins the CI-triggering token); `sync-release-pr-pins` `if:` still keys on `needs.release-please.outputs.prs_created == 'true'`; positive control (flip `always-update` to false -> rule fires).
- **Observed run (success criterion 2):** needs an open release PR and then a non-releasable merge, neither of which exists now (1.1.0 is released; no open PRs at baseline 07610840). Plan an evidence-capture task that fires on the first natural opportunity and records: the release run id showing no "remained the same" line for the PR, the new head SHA of `release-please--branches--main`, and the `pull_request` CI run id on that SHA (`gh run list --branch release-please--branches--main`). If no natural releasable commit lands during v1.47, the planner should carry REL-02's observed-run criterion to milestone close rather than create a throwaway release. See Open Question Q1.

### D-3 (REL-03): `bin/retry-network` shell wrapper, deps.get only
- Contract: `bin/retry-network [--attempts N] -- COMMAND...`; default 3 attempts, delays 5s then 15s (base 5, factor 3) plus small jitter, delays overridable by `RETRY_NETWORK_BASE_DELAY` (set `0` in tests); each attempt gets `printf 'n\n'` on stdin because every Hex fetch in this repo already declines the interactive re-auth prompt (mix.exs:343 comment and `<<<'n'` at bin/verify-deps-audit:331); do **not** retry (fail immediately) when the output contains deterministic markers: `mix.lock is out of date`, `Unchecked dependencies`, `Dependency resolution failed`. Everything else retried, which keeps the classifier small and avoids a brittle list of transient error strings.
- Call sites to convert: every workflow `run: mix deps.get` (E4), the `printf "n\n" | mix deps.get` inside `verify_hex_evaluator` (mix.exs:~470) -> `bin/retry-network mix deps.get`, `bin/verify-bump-rehearsal:461`, `bin/verify-deps-audit:331` and `bin/deps-health-report:243` (these two run `deps.get --check-locked`; wrapped, the deterministic-marker rule makes a lock mismatch fail on the first attempt), and the Hex pin install `mix local.hex 2.6.0 --force` (network fetch from builds.hex.pm).
- **Never retried:** `mix test`, `mix verify.test`, `mix verify.hex_evaluator` as a CI step, `mix ci.all`, `mix verify.example_browser`, playwright.
- **Contract test `retry_network_contract_test.exs` (new):** (1) rule A: scan `.github/workflows/*.yml` (parsed with YamlElixir like the existing contracts), `mix.exs`, `bin/*`, `scripts/` — any occurrence of `retry-network` must be followed by `mix deps.get` / `mix local.hex` (allowlist), nothing else; (2) rule B: no workflow step uses a retry action (`nick-fields/retry`, `wretry`, `Wandalen`) and no step `run:` containing `retry-network` also contains a test command (`mix test`, `verify.test`, `ci.all`, `playwright`); (3) rule C: every workflow `mix deps.get` step goes through the wrapper (so a future unwrapped fetch fails the contract); (4) mutation controls per repo convention: wrap `mix test` -> rule fires, add `uses: nick-fields/retry@v3` -> rule fires, unwrap a `deps.get` -> rule fires; (5) behaviour tests that execute `bin/retry-network` against a fake command that fails N times then succeeds (backoff delay 0), a deterministic-marker failure that must not retry, and exit-code propagation.
- **Collision check:** `release_control_plane_contract_test.exs` `mix_invocation?` treats `mix` at a command position as an invocation; `bin/retry-network mix deps.get` puts `mix` after a non-separator word, so it is not flagged as a bare mix call. The `allowlisted-job-runs-no-mix` rule applies to `distribution-sync`, which has no deps.get, so no conflict. `ci_topology_contract_test.exs:784` uses `position(job, "mix deps.get")` substring matching (still matches). `ci_workflow_parity_contract_test.exs` fixtures at lines 5546, 5587, 5794 embed `run: mix deps.get` as inline YAML fixtures, but the live-tree rules that read the real ci.yml must be checked by running the file after the edit (planner: run the full parity file as the first verification, not last).

### D-4 (REL-04): pin Hex 2.6.0 everywhere; raise the audit floor to the pin
- **Pin mechanism:** in every job with `erlef/setup-beam`, add `install-hex: false` to the `with:` block and add a step after it: `run: bin/retry-network mix local.hex 2.6.0 --force`. (`mix local.hex VERSION --force` verified; setup-beam has no Hex version input, only `install-hex` [CITED: setup-beam action.yml].) Do not touch the `uses:` line, so Phase 245's SHA-pinning is unaffected.
- **Why not leave `install-hex` on and pin after:** double install and a window where an unpinned Hex ran first; one fewer network fetch with `install-hex: false`.
- **Why 2.6.0 not 2.5.1:** it is the version CI ran when the stricter check caught a real defect, it is current, and the failure class is "Hex got stricter". Pinning to 2.5.1 would re-hide the defect class. Hex 2.6.0 ran green on the Elixir 1.17.3/OTP 27 jobs after the lock fix (run 40054042788 on a4fcf36a is success) [VERIFIED: gh run list]. The `latest` lane (Elixir 1.20.4/OTP 29.1.1) and the matrix `min` lane also installed Hex 2.6.0 via setup-beam in run 40033918741; confirm they stay green in the phase's own CI run.
- **Release-job edge:** the `sync-release-pr-pins` job reads the toolchain from a sparse checkout at `.toolchain-pin` (release.yml header comment, git 2.55 sparse-checkout regression run 36319430805). Its Hex pin step is a literal, so it does not depend on the checked-out ref.
- **Local drift guard:** change `bin/verify-deps-audit:61` `MIN_HEX="2.5.1"` to the pin and update the three asserting strings and fakes (`bin/verify-deps-audit:148`, `test/threadline/deps_audit_gate_test.exs:116,182,445`, CONTRIBUTING.md:665 and :732, mix.exs:190). `mix ci.all` then tells a maintainer on an older Hex to run `mix local.hex 2.6.0`, closing the local-vs-CI gap that hid this defect. Note this makes `ci.all` fail on the maintainer's current Hex 2.5.1 until they upgrade: call it out in the plan summary.
- **Contract test (`hex_pin_contract_test.exs`, new, or a section of the retry test):** every job containing `erlef/setup-beam` sets `install-hex: false` and has exactly one `mix local.hex <VERSION> --force` step; all VERSIONs identical; VERSION equals `MIN_HEX` in `bin/verify-deps-audit`; mutation controls (drop `install-hex: false`; change one job's version).
- **Evidence record:** the plan's SUMMARY should cite run 40028641095, commits a3301bed and f7fdcaca, Hex 2.6.0 release time, and the reproduction table above. The record satisfies "cause recorded with evidence".

### D-5: file/test change inventory (what existing tests must accept)
| Test / script | Needs |
|---|---|
| `bin/verify-release-shape` | No change. It already accepts `## [VER] - date`. It is the proof that the renamed shape is valid. |
| `test/threadline/changelog_contract_test.exs` | No change expected: newest dated entry will be the renamed one (first `@dated_entry_regex` match), needs human prose + Breaking/Required before feature tour (the landing PR author's job). Add one test or fixture-driven assertion that a renamed fixture still satisfies those shape rules. |
| `test/threadline/version_truth_doc_contract_test.exs` (Family C) | No change; the renamed shape satisfies `previous_release_minor!` (skips same-minor) given the guide row is in the landing PR. |
| `test/threadline/upgrading_to_1_0_doc_contract_test.exs:50`, `guides/upgrade_path_contract_test.exs:253` | Pass only if the standing `## Unreleased — highlights` is re-seeded. Reason for the re-seed in the script contract. |
| `test/threadline/release_control_plane_contract_test.exs:138-188` (sync job) | Extend: runs `bin/date-release-changelog`; step precedes the commit; `git add` includes `CHANGELOG.md`; keep `PUSH_TOKEN` bound once and `persist-credentials: false` rules (the script runs no mix and holds no token, so the 216 CR-01 rules stay valid). |
| `test/threadline/release_distribution_doc_contract_test.exs` and CONTRIBUTING | Update CONTRIBUTING.md:1063-1066 ("Ongoing releases") and the CHANGELOG.md header comment (lines 3-10, "release-please has no write access to it") to say the release workflow renames the Unreleased block; check that doc contract for any asserted sentence before editing. |
| `bin/verify-bump-rehearsal` | Mirror: call the real script (see D-1). |
| New: `test/threadline/date_release_changelog_test.exs` | Fixture-driven (System.cmd on a temp tree, like `deps_audit_gate_test.exs`): happy path; empty placeholder fails; idempotent rerun; date from CHANGELOG-GENERATED; bare `## Unreleased`; output passes `bin/verify-release-shape` against a fixture `mix.exs`. |

## Architecture Patterns

### System Architecture Diagram

```
 landing PR (feat:/fix:/perf:/deps: squash subject)
   carries: prose under "## Unreleased — highlights" + upgrade-path row
        |
        v  merge
      main ---------------- push ----------------+
        |                                        |
        v                                        v
   ci.yml (push)                         release.yml: release-please job
                                         (PAT token; config: always-update=true)
                                                 |
                       open release PR? --no--> (nothing releasable: stop)
                                 | yes
                                 v
              force-push release-please--branches--main (regenerated on current main)
              => outputs.prs_created=true   [PAT push => pull_request CI starts (cancelled later)]
                                 |
                                 v
              sync-release-pr-pins (needs release-please; prs_created=='true')
                1. mix release.pins           (docs install pins)
                2. mix release.pins --check
                3. bin/date-release-changelog (Unreleased -> [X.Y.Z] - date; reseed block)
                4. git add README.md guides/ CHANGELOG.md; commit; push with PAT
                                 |
                                 v
              pull_request CI on final head -> green (release-shape, version-truth pass)
                                 |
                          bootstrap-release-pr-ci: dispatch CI only if PAT absent (ECON-03)
                                 |
              maintainer merges release PR --> tag --> gate-ci-green --> publish-hex
                                              (production-hex approval) --> smoke --> distribution-sync
```

### Recommended file layout (additions only)
```
bin/date-release-changelog          # REL-01 (bash+perl, no BEAM)
bin/retry-network                   # REL-03 (shell)
release-please-config.json          # + "always-update": true  (REL-02)
test/threadline/date_release_changelog_test.exs
test/threadline/retry_network_contract_test.exs
test/threadline/hex_pin_contract_test.exs     # may merge into retry test
.github/workflows/*.yml             # install-hex: false + pin step; wrapped deps.get
```

### Pattern: deterministic idempotent bot edit on a force-pushed branch
**What:** any edit on the release branch must be recomputable from the branch alone, because release-please force-pushes and drops earlier commits. **When:** every step in `sync-release-pr-pins`. The rename is recomputable from mix.exs + CHANGELOG.md + CHANGELOG-GENERATED.md only.

### Anti-Patterns to Avoid
- **Rebasing the release branch yourself:** conflicts with the dated-heading commit and diverges from release-please's own bookkeeping.
- **Writing `CHANGELOG.md` through release-please `extra-files`:** violates the RELEASE-04 ownership contract.
- **Retrying a step instead of a command:** hides flakes in tests (explicitly forbidden by REL-03).
- **Wrapping `mix verify.hex_evaluator`:** it contains `mix test`.
- **Letting the date step be a silent no-op on empty prose:** the failure belongs in the release PR where the maintainer will see it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Keeping the release PR current with main | A custom staleness detector + rebase job | release-please `always-update` | Built-in, regenerates deterministically, already PAT-authenticated |
| Detecting transient vs permanent fetch errors | A catalogue of Hex error strings | Retry-all with a tiny deterministic-marker denylist | Hex/network error text is not a stable interface |
| Hex version pinning | A custom installer | `mix local.hex VERSION --force` | Verified to work; `install-hex: false` is the setup-beam switch |
| CI-triggering token | A new GitHub App/PAT | Existing `RELEASE_PLEASE_TOKEN` | Already provisioned and proven to fan out CI |
| Workflow shape checks | Regex over raw YAML only | YamlElixir parsed steps + raw text for ordering (existing pattern in release_control_plane/ci_workflow_parity tests) | Matches repo conventions, includes mutation controls |

## Runtime State Inventory

Not a rename/refactor/migration phase. State is limited to repo workflow files and an existing secret.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None - verified: no datastore references the changed identifiers | none |
| Live service config | GitHub repo secret `RELEASE_PLEASE_TOKEN` (exists); branch protection requires `CI required` (unchanged) | none (verify PAT expiry, Q2) |
| OS-registered state | None | none |
| Secrets/env vars | `RELEASE_PLEASE_TOKEN`, `HEX_API_KEY` names unchanged | none |
| Build artifacts | None; a leftover `release-please--branches--main` ref from released 1.1.0 is harmless | none |

## Common Pitfalls

### Pitfall 1: Rename deletes the standing block and later tests flunk
**What goes wrong:** after the rename, `## Unreleased — highlights` is gone; `upgrading_to_1_0_doc_contract_test.exs:50` flunks and `upgrade_path_contract_test.exs:253` loses its source section.
**How to avoid:** re-seed the standing block in the same edit; unit-test it.

### Pitfall 2: Release PR red because prose is missing
**What goes wrong:** a landing PR with a `fix:` subject but only the placeholder yields no `## [X.Y.Z]` heading; verify-release-shape and version-truth go red (this is what happened to run 40033918741).
**How to avoid:** the script fails with an explicit message; CONTRIBUTING states the rule; the CHANGELOG header says what to write. The release PR stays visibly red, which is the correct signal.

### Pitfall 3: A third-party action or composite action hides test retries
**How to avoid:** rule B in the retry contract; no composite action (tests also assert `erlef/setup-beam` inline in each job).

### Pitfall 4: Pin step ordering
`mix local.hex 2.6.0 --force` must precede the first `mix` call that touches Hex in a job (for example `mix verify.deps_audit` in `verify-deps-audit` has no deps.get step). Put it immediately after setup-beam in every job; contract rule: pin step index is directly after the setup-beam step.

### Pitfall 5: Release PR first run is cancelled, not green
The first push by release-please starts a CI run on the intermediate head; the sync push supersedes it (`cancel-in-progress` for `pull_request`). "First CI run green" in success criterion 1 means the run on the final head. Say so in verification so the cancelled run is not mis-read as failure (as the stale red check was mis-read before).

### Pitfall 6: `ci.all` goes red locally after raising MIN_HEX
The maintainer machine has Hex 2.5.1. Plan a note and the one-line fix (`mix local.hex 2.6.0 --force`); the executor must not "fix" the gate by lowering the floor.

### Pitfall 7: Workflow edits collide with Phase 245
Phase 244 and 245 both edit `ci.yml` and `release.yml`; the roadmap sequences them. Finish 244 workflow edits in one atomic commit set before 245 starts.

## Code Examples

### Release config (REL-02)
```json
{
  "release-type": "elixir",
  "always-update": true,
  "packages": { ".": { "changelog-path": "CHANGELOG-GENERATED.md" } }
}
```
`always-update` is a top-level manifest option [CITED: release-please schemas/config.json:130]. Keep every other existing key; do not name `CHANGELOG.md` anywhere in this file.

### Sync job step ordering (REL-01), shape only
```yaml
      - name: Rewrite install pins from the bumped @version
        run: mix release.pins
      - name: Confirm the pin writer is now idempotent
        run: mix release.pins --check
      - name: Date the CHANGELOG from the Unreleased block
        run: bin/date-release-changelog
      # push step: git add -- README.md guides/ CHANGELOG.md
```

### Hex pin + retry (REL-03/04), shape only
```yaml
      - uses: erlef/setup-beam@v1
        id: beam
        with:
          version-file: .tool-versions
          version-type: strict
          install-hex: false
      - name: Pin Hex (CI and local must agree)
        run: bin/retry-network mix local.hex 2.6.0 --force
      - name: Install dependencies
        run: bin/retry-network mix deps.get
```

### hex-evaluator chain (REL-03), shape only (mix.exs)
```elixir
steps =
  "bin/retry-network mix deps.get && mix compile --warnings-as-errors && " <>
    "mix ecto.create --quiet -r HexEvaluator.Repo && mix ecto.migrate --quiet && mix test"
```
(`bin/retry-network` supplies the `n` on stdin per attempt, replacing `printf "n\n" |`.) The `mix test` tail stays outside any retry.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-dated CHANGELOG PR after each release | Release workflow renames the Unreleased block on the release branch | This phase | 4 PRs -> 3 (landing, release, Hex approval) |
| Manual delete-branch + rerun for stale release PR | `always-update` regeneration | This phase | Zero human action |
| Floating Hex via `mix local.hex --force` | Pinned Hex | This phase | Deterministic lock checks |
| `bootstrap-release-pr-ci` dispatch on every release PR | Dispatch only when PAT absent (ECON-03, already landed) | Phase 218 | Unchanged here |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The v5 action sets `prs_created` true when `always-update` refreshes an existing PR (inferred from `updateExistingPullRequest` returning the PR and the action's "created or updated" description) | D-2 | If false, sync job would not run on refresh; fallback is to key the sync job on "open release PR exists" via a `gh pr list --head` check. Close with the observed run. |
| A2 | The `[]` manager entry in a3301bed was a hand/tool edit, not produced by Hex | E5 | Low: the pin and floor fix hold regardless; only the narrative changes |
| A3 | Hex 2.6.0 is also fine on the matrix `min` lane Elixir version | D-4 | Low: the lane installed 2.6.0 via setup-beam in run 40033918741 without a Hex error visible in the retrieved log excerpt; confirm in the phase's own CI |
| A4 | Retry-all-but-deterministic-markers is an acceptable classifier (3 markers) | D-3 | Low: worst case a permanent error is retried twice (about 20 s) |
| A5 | The wrapper's default 3 attempts / 5s,15s delays are sufficient for typical hex.pm blips | D-3 | Low: tunable by env/flag |
| A6 | `gh` read access and PAT presence reflect the maintainer's real PAT scopes (contents + pull-requests + workflows) | E3 | Medium: CI fan-out is proven by runs, but `always-update` force-push uses the same scopes release-please already used, so risk is low |

## Open Questions (RESOLVED)

1. **How is the REL-02 observed run produced without a throwaway release?**
   - Known: needs an open release PR plus a later non-releasable merge; none exist now. Remote mutation is out of scope for research.
   - Recommendation: the plan includes an evidence-capture task bound to the first natural releasable change in v1.47 (or milestone close), listing exact `gh` commands. If none occurs, the maintainer decides at close whether to accept the contract test plus a recorded dry reasoning, or authorise a deliberate `fix:` for the observation. Do not create a release solely to observe it unless the maintainer asks.
   - **RESOLVED (planning, 2026-10-24):** deferred to the first natural release cycle after this phase lands. 244-07 Task 2 writes `244-REL02-EVIDENCE.md` with the exact read-only `gh` commands, pass conditions and `Status: pending`; no throwaway release. The contract half is proven in 244-01.
2. **PAT expiry date.** `gh secret list` shows only the update date (2026-05-28). Fine-grained PATs usually expire; ask the maintainer once whether and when it expires (a single question, no decision needed). Out of 244's code scope.
   - **RESOLVED (planning, 2026-10-24):** routed as a maintainer-owned item. 244-07 records it in `244-REL02-EVIDENCE.md` ("Maintainer-owned items") and in the SUMMARY handoff list. An expired PAT fails loudly at the release-please step (release.yml comment near l.212), so it cannot silently strand a release PR. Agents cannot read the expiry date.
3. **Heading literal.** REQ text says `## Unreleased`; the repo literal is `## Unreleased — highlights`. This research keeps the literal and tolerates the bare form. If the maintainer wants the shorter heading, that is a separate contract migration (three tests reference the em-dash form), not part of REL-01.
   - **RESOLVED (planning, 2026-10-24):** keep the em-dash literal `## Unreleased — highlights` (U+2014). bin/date-release-changelog also accepts bare `## Unreleased` on input and always re-seeds the em-dash form; 244-01 adds a byte-level test.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` CLI (authenticated) | evidence capture, run inspection | yes | not probed | - |
| `RELEASE_PLEASE_TOKEN` secret | REL-02 CI trigger | yes (listed 2026-05-28) | fine-grained PAT | `bootstrap-release-pr-ci` dispatch (exists) |
| Hex 2.6.0 / 2.5.1 installable via `mix local.hex VERSION` | REL-04 pin | yes | verified both | - |
| Elixir 1.17.3 / OTP 27 locally | contract tests | yes via asdf | Mix 1.17.3 | - |
| bash, perl on runners and macOS | scripts | yes | - | - |
| deps/ and _build in the research worktree | running `mix test` | no | - | execute in a tree with deps (executor concern) |

**Missing with no fallback:** none. The executor must run mix commands in a checkout with `deps/` and `_build/` (this worktree has none; per project memory, do not run `ci.all` from a bare worktree).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3 / OTP 27 per `.tool-versions`) |
| Config file | `test/test_helper.exs`; contract tests are ordinary files under `test/threadline/` |
| Quick run command | `mix test test/threadline/release_control_plane_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs` |
| Full suite command | `mix verify.test` (named entrypoint); full gate `mix ci.all` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | Script renames Unreleased, reseeds block, fails on empty prose, idempotent, date from generated log | unit (System.cmd fixtures) | `mix test test/threadline/date_release_changelog_test.exs` | no, Wave 0 |
| REL-01 | Renamed fixture satisfies release shape | script | `bin/verify-release-shape` against a fixture tree (inside the unit test) | script exists; test is Wave 0 |
| REL-01 | Sync job runs script before commit and stages CHANGELOG.md | contract | `mix test test/threadline/release_control_plane_contract_test.exs` | yes (extend) |
| REL-01 | Renamed CHANGELOG still passes shape/ordering/version-truth contracts | contract | `mix test test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` | yes |
| REL-01 | Rehearsal mirrors the real script | integration | `mix verify.bump_rehearsal` | yes (modify) |
| REL-02 | `always-update` true; PAT token on release-please step; sync `if:` on `prs_created` | contract | `mix test test/threadline/release_control_plane_contract_test.exs` | yes (extend) |
| REL-02 | Observed refresh run | manual-equivalent evidence | `gh run list --workflow release.yml`, `gh run list --branch release-please--branches--main` recorded in VERIFICATION | evidence task |
| REL-03 | Retry only wraps deps.get/local.hex; no test step retried; all deps.get wrapped | contract + behaviour | `mix test test/threadline/retry_network_contract_test.exs` | no, Wave 0 |
| REL-04 | Hex pin uniform in all jobs; equals audit floor | contract | `mix test test/threadline/hex_pin_contract_test.exs test/threadline/deps_audit_gate_test.exs` | no / yes (modify) |
| REL-04 | Pinned Hex rejects the `[]` manager lock | script | `mix verify.deps_audit` under Hex 2.6.0 | yes |
| All | Workflow parity/topology unaffected | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/ci_token_permissions_contract_test.exs` | yes |

### Sampling Rate
- **Per task commit:** the quick run command above plus the one test file the task touched.
- **Per wave merge:** `mix verify.test`, `mix verify.credo`, `mix verify.format`, `bin/verify-repo-hygiene`.
- **Phase gate:** `mix ci.all` green (after local `mix local.hex 2.6.0 --force`); the phase PR's own CI green (all jobs, including `Build and test (min|current|latest)` on the pinned Hex); then `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/threadline/date_release_changelog_test.exs` - REL-01 script behaviour
- [ ] `test/threadline/retry_network_contract_test.exs` - REL-03 rules A-C + behaviour + mutation controls
- [ ] `test/threadline/hex_pin_contract_test.exs` - REL-04 uniform pin
- [ ] Red-first order (repo convention): write each contract before the workflow/script edit that satisfies it, with its mutation controls
- Framework install: none needed.

## Security Domain

`security_enforcement` is not disabled in the examined config; included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | - |
| V3 Session Management | no | - |
| V4 Access Control | yes (CI token scope) | Job-scoped `permissions:` (default `contents: read`); pinned by `ci_token_permissions_contract_test.exs`. Phase 244 adds no new write grants: the date step runs in a job that already has `contents: write`. |
| V5 Input Validation | yes | The script reads only repo files (`mix.exs`, CHANGELOG*) and must quote variables; version must match `^[0-9]+\.[0-9]+\.[0-9]+$` before use in a perl regex (inject via `ENV`, not interpolation, as `bin/verify-bump-rehearsal` does) |
| V6 Cryptography | no | Hex verifies the downloaded archive; never disable checks |
| V14 Config / supply chain | yes | No new `uses:`; pin Hex version; keep `persist-credentials: false` on checkouts that compile deps (216 CR-01) |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PAT readable by dependency compile-time code | Information disclosure | Keep `PUSH_TOKEN` bound only in the push step's env (existing test asserts exactly one binding); the new script runs before and needs no token |
| Shell injection via version/date in perl or git commands | Tampering | Version regex gate; pass values through environment variables |
| Third-party retry action as new supply-chain surface | Tampering | Shell wrapper only; contract forbids retry actions |
| Floating Hex version | Tampering/Repudiation | Pinned and uniform; floor check in `bin/verify-deps-audit` |
| Retry masking a real failure | Repudiation | Deterministic-marker no-retry rule; test steps never retried |

## Interactions with Phase 245 (Supply chain)

- Phase 244 adds **zero new `uses:` references** (wrapper and script are repo files), so 245's SHA-pin contract has nothing new to chase and Dependabot's `github-actions` ecosystem sees no new action.
- The `uses: erlef/setup-beam@v1` lines are not edited by 244 (only the `with:` block and a following step), so 245's pin-by-SHA rewrite of those lines does not conflict textually.
- The sync job's `release.yml` edits (new step, `git add` path, commit message) and the release-please config are in 244; 245's SUP-03 builds on a green release lane, which 244 delivers. Land all 244 workflow edits first, as the roadmap sequences.
- 245's tiered audit gate edits `bin/verify-deps-audit`; 244 only changes `MIN_HEX` and the fetch line. Order is fixed (244 first), so 245 rebases onto the new floor string.
- If 245 later introduces a composite action to centralise setup, the per-job pin step from 244 becomes the natural content of it; the hex pin contract should assert behaviour (uniform pin) rather than literal step text to survive that.

## Sources

### Primary (HIGH confidence)
- Repo files read this session: `.github/workflows/release.yml` (job layout, lines cited above), `ci.yml`, `release-please-config.json`, `.release-please-manifest.json` (`".": "1.1.0"`), `CHANGELOG.md`, `bin/verify-release-shape`, `bin/verify-bump-rehearsal`, `bin/verify-deps-audit`, `mix.exs`, `test/threadline/{changelog,version_truth_doc,release_control_plane,release_artifact,upgrading_to_1_0_doc}_contract_test.exs`, `test/threadline/guides/upgrade_path_contract_test.exs`, CONTRIBUTING.md.
- GitHub run logs via gh: runs 40028641095 (REL-04 failure), 40033918741 (born-red release PR), 40038808445 ("remained the same"), 40054042788 (PAT fan-out success); commits a3301bed, f7fdcaca, 28af5d3d; PRs #85-#89; `gh secret list`.
- Experiment: isolated Hex 2.5.1 vs 2.6.0 behaviour against the `[]`-manager lock (scratchpad `hexexp/`).
- hex.pm API for plug_crypto 2.2.1; `gh api repos/hexpm/hex/releases` (2.6.0 date).

### Secondary (MEDIUM confidence)
- release-please source `src/manifest.ts` and `src/github.ts`, `docs/manifest-releaser.md`, `schemas/config.json`; release-please-action README (outputs `prs_created` "created or updated", PAT guidance); `action.yml` of release-please-action and erlef/setup-beam (inputs).

### Tertiary (LOW confidence)
- None relied upon.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new packages; every tool already in use or verified by experiment.
- Architecture: HIGH for REL-01/03/04, MEDIUM for REL-02 (`prs_created` under `always-update` inferred from source, closed by the observed run).
- Pitfalls: HIGH - each tied to an observed run or an existing contract.

**Research date:** 2026-10-24
**Valid until:** 2026-11-07 (fast-moving: Hex releases weekly in October 2026; re-verify the pin version and release-please-action major before execution)
