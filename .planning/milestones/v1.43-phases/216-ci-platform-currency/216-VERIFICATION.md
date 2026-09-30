---
phase: 216-ci-platform-currency
verified: 2026-09-27T15:10:00Z
status: passed
score: 3/3 roadmap success criteria verified (plan must-have truths 43/43 verified)
covered_files:
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/deps-health.yml
  - .github/workflows/flake-detection.yml
  - .github/workflows/release.yml
  - .planning/phases/216-ci-platform-currency/216-01-PLAN.md
  - .planning/phases/216-ci-platform-currency/216-01-SUMMARY.md
  - .planning/phases/216-ci-platform-currency/216-02-PLAN.md
  - .planning/phases/216-ci-platform-currency/216-02-SUMMARY.md
  - .planning/phases/216-ci-platform-currency/216-03-PLAN.md
  - .planning/phases/216-ci-platform-currency/216-03-SUMMARY.md
  - .planning/phases/216-ci-platform-currency/216-04-PLAN.md
  - .planning/phases/216-ci-platform-currency/216-04-SUMMARY.md
  - .planning/phases/216-ci-platform-currency/216-05-PLAN.md
  - .planning/phases/216-ci-platform-currency/216-05-SUMMARY.md
  - .planning/phases/216-ci-platform-currency/216-06-PLAN.md
  - .planning/phases/216-ci-platform-currency/216-06-SUMMARY.md
  - .planning/phases/216-ci-platform-currency/216-07-PLAN.md
  - .planning/phases/216-ci-platform-currency/216-07-SUMMARY.md
  - .planning/phases/216-ci-platform-currency/216-08-PLAN.md
  - .planning/phases/216-ci-platform-currency/216-08-SUMMARY.md
  - .tool-versions
  - CONTRIBUTING.md
  - bin/verify-bump-rehearsal
  - test/threadline/ci_action_runtime_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/release_control_plane_contract_test.exs
covered_digest: "v2:sha256:2bdb086af360fec1e3c10bec1916764accba73382347b44d92376a227dc5f978"
behavior_unverified: 0
overrides_applied: 0
escalations:
  - finding: "CR-01: release.yml smoke-published target-ref checkout persists the workflow-level contents:write GITHUB_TOKEN into .git/config, then compiles third-party Hex code (publish-hex has the same shape with a contents:read token)"
    disposition: "Out of PLAT-01..03 scope; not a phase-216 gap. Pre-existing at 35d7ee8c. Plan 216-03 and 216-08 explicitly prohibited changing target-ref checkout inputs. Not tracked in deferred-items.md or any later roadmap phase, so it needs a maintainer scope decision now (quick fix or backlog seed)."
    severity: security follow-up (review-rated critical)
---

# Phase 216: CI Platform Currency Verification Report

**Phase Goal:** CI runs exactly the toolchain the repo commits to, on non-deprecated actions and runner images
**Verified:** 2026-09-27T15:10:00Z
**Status:** passed (with one out-of-scope security escalation; see below)
**Re-verification:** No. This is the initial verification. No prior VERIFICATION.md existed.

## Goal Achievement

### Roadmap Success Criteria (the contract)

| # | Criterion | Status | Evidence (verifier-run, not SUMMARY) |
|---|-----------|--------|--------------------------------------|
| 1 | `.tool-versions` tracked. Non-matrix jobs use setup-beam `version-file` + `version-type: strict`. A CI log shows resolved OTP = pin, no 27.0.1. Every cache key interpolates resolved outputs. Topology and parity contracts assert the pins. | VERIFIED | `git ls-files .tool-versions` shows the file is tracked. It was added in 8642610e and holds `erlang 27.3.4.15` / `elixir 1.17.3-otp-27`. Every non-matrix `erlef/setup-beam@v1` step in ci.yml, browser-full, flake-detection and deps-health is `id: beam` + `version-file: .tool-versions` + `version-type: strict`, and the 3 release jobs use `.toolchain-pin/.tool-versions`. The only `otp-version:`/`elixir-version:` inputs are the matrix step's `${{ matrix.* }}`. All deps/PLT keys are `ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-...` or `${{ matrix.runner }}-...`, and the PLT save reuses `cache-primary-key`. The only exemption is the Playwright key (OD-4, named in `@beam_independent_cache_paths`). I re-fetched main CI run 36320746124 (3d8ab205, success) log myself: `14 Installing Erlang/OTP OTP-27.3.4.15 - built on amd64/ubuntu-24.04`, `1 ... OTP-26.2.5.21 - built on amd64/ubuntu-24.04`, `OTP-27.0.1` count 0, and Elixir only `v1.17.3-otp-27` (14) / `v1.15.8-otp-26` (1). Contract tests: 63 tests, 0 failures across the four contract files. |
| 2 | Grep-based contract finds no Node 20 action (`cache@v5`, `upload-artifact@v7`, `release-please-action@v5`). The release-please bump is its own commit, with a recorded rehearsal through the runbook. | VERIFIED | `ci_action_runtime_contract_test.exs` scans `.github/workflows/*.{yml,yaml}` (it refuses an empty glob) against a fail-closed allowlist, with a stale-entry rule and mutation controls. I independently fetched every allowlisted `{action, ref}` action.yml through `gh api`: all are `node24`, except alls-green (SHA-pinned), which is `composite`. Own commit: `21bb7e1b` (milestone branch) and `4dc227bf` (publicly visible in PR #55's commit list, numstat `+1 -1 .github/workflows/release.yml`), with the diff `@v4` to `@v5` only. Rehearsal: pre-landing dry-run of 17.3.0 vs 17.6.0 was IDENTICAL against 5e78b2f0 (216-EVIDENCE.md). The runbook subsection `### Upgrading the Release Please action` in CONTRIBUTING records it and is doc-contract-tested. The live half ran too: Release runs 36320746183 (3d8ab205) and 36323594205 (2a75a795, the 0.11.1 publish) are success, download `release-please-action@v5`, and have 0 Node 20 lines (re-checked). |
| 3 | The min lane runs on a supported image (not `ubuntu-22.04`), and a green CI run ID shows lazy_html's OTP 26 NIF resolving there. | VERIFIED | The ci.yml min row has `runner: "ubuntu-24.04"`, `otp: "26.2.5.21"`, `elixir: "1.15.8"`, and no ubuntu-22.04 label exists in any workflow (the only `22.04` is inside a ci.yml comment, with no `ubuntu-` prefix). Green run 36320746124, `Run test suite (min)` job lines (re-fetched): `Image: ubuntu-24.04`, `Installing Erlang/OTP OTP-26.2.5.21 - built on amd64/ubuntu-24.04`, `Downloading precompiled NIF to .../lazy_html-nif-2.16-x86_64-linux-gnu-0.1.13.tar.gz`, and no `from source` line. The PR run 36318716184 shows the same (per the evidence file, conclusion success confirmed). |

### Plan must-have truths (merged, 216-01..08)

| Plan | Truths | Status | Notes |
|------|--------|--------|-------|
| 01 | 11 (incl. EDGE empty/ordering/parallel + 1 `backstop`) | VERIFIED | The backstop "interrupted job never saves a partial entry" is verified by direct observation of the upstream mechanism, not by presence alone. The `actions/cache@v5` action.yml (fetched) has `post: dist/save/index.js` with `post-if: "success()"`, and no workflow sets `save-always`. The `Save Dialyzer PLT` step's `if:` has no status function, so the implicit `success()` applies, gated on an exact-key miss. The `bin/verify-bump-rehearsal` copy block was removed. The CONTRIBUTING dated 27.0.1 receipt (run 34642915672) is kept. |
| 02 | 7 | VERIFIED | Matrix step, floor pins, runner, keys, `verify_test_matrix_errors/2`, `runner_image_errors/2` and the OS-family whole-file check are all present, and their tests pass. |
| 03 | 8 | VERIFIED | The toolchain-first checkout in all 3 release jobs was later amended by 08 to `path: .toolchain-pin`. The contract is fed every workflow. deps-health and release gained no cache. |
| 04 | 4 | VERIFIED | Own commit numstat is exactly `1 1`. There are no `@v4` action refs in any workflow. |
| 05 | 4 | VERIFIED | The allowlist test, stale-entry rule, runbook subsection and runbook doc contract are all present. The contract is weaker than the prose claims (WR-02, below). |
| 06 | 8 | VERIFIED | Negative controls on 36258719902 are recorded (12 × 27.0.1, 22.04 image, 12 Node 20 lines). The post-push checks are all PASS, and I re-checked the main-SHA equivalents myself. |
| 07 | 6 | VERIFIED | See the "Honesty of the 216-07 record" section. |
| 08 | 6 | VERIFIED | `.toolchain-pin` isolation is in all 3 jobs, and the target-ref checkouts are byte-identical to pre-phase (`ref:` only, no `path:`). The Release 36320746183 sync job log shows `path: .toolchain-pin`, `Parsing .tool-versions file at .toolchain-pin/.tool-versions`, and OTP 27.3.4.15, and the job succeeded. Publish-hex and smoke on 36323594205 both installed OTP 27.3.4.15. |

**Score:** 3/3 roadmap criteria, 0 present-but-behavior-unverified.

### Honesty of the 216-07 record (criterion 2, "recorded rehearsal")

- The first landing SHA ff346b1a has explicit `FAIL release-conclusion` / `FAIL sync-pins` lines, and they were not edited away. I confirmed Release run 36319430805 = failure, with the jobs `Release Please success`, `Sync install pins on Release PR failure`.
- The failure came from 216-03's sparse-checkout design (git 2.55 `sparse-checkout disable` leaves `core.sparseCheckout` set). It did not come from the release-please v5 bump: the v5 action job itself succeeded on ff346b1a and created release PR #56.
- Gap plan 216-08 fixed it, and the 7-check PASS block is scoped to 3d8ab205, whose Release run 36320746183 is success with the sync job green.
- The full publish chain on v5 (36323594205) then succeeded end to end.

This honestly satisfies "recorded rehearsal through the release runbook": the pre-landing dry-run plus the post-landing live run with the runbook's step-5 checks. The regression it exposed was in the toolchain-pin wiring (PLAT-01), and it was closed inside the phase.

### Squash landing vs "lands in its own commit"

- Main received the phase as squash ff346b1a, so on main the bump is not a standalone commit.
- Plan 216-04 defined the truth as "own commit on the milestone branch" before landing, and OD-2 spelled out the squash consequence. The maintainer chose squash.
- The standalone commit is publicly inspectable as 4dc227bf in PR #55's commit list, verified via `gh api`.

I accept this as VERIFIED. It was a recorded maintainer landing decision, not an executor shortcut.

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `.tool-versions` | VERIFIED | Tracked; 3 lines match the pre-phase untracked content |
| `.github/workflows/ci.yml` | VERIFIED | 13 non-matrix file-form steps + 1 strict matrix step; resolved-output keys; cache@v5 / upload-artifact@v7 |
| `.github/workflows/release.yml` | VERIFIED | release-please-action@v5; `.toolchain-pin` in sync-release-pr-pins / publish-hex / smoke-published |
| `.github/workflows/{browser-full,flake-detection,deps-health}.yml` | VERIFIED | File-form strict setup-beam; resolved keys (deps-health has no cache) |
| `test/threadline/ci_workflow_parity_contract_test.exs` | VERIFIED | Toolchain pin contract, matrix, runner-image, OS-family, toolchain_source (with pin isolation) |
| `test/threadline/ci_topology_contract_test.exs` | VERIFIED | Dialyzer contract re-pinned (version-file strict, resolved PLT prefix, literal-pin mutation control) |
| `test/threadline/ci_action_runtime_contract_test.exs` | VERIFIED | Node 24 allowlist + runbook contract |
| `test/threadline/release_control_plane_contract_test.exs` | VERIFIED | sync-release-pr-pins checkouts are credential-free (scoped to that job only; see CR-01) |
| `CONTRIBUTING.md` | VERIFIED | Toolchain policy + `### Upgrading the Release Please action` |
| `bin/verify-bump-rehearsal` | VERIFIED | The `.tool-versions` copy block was removed |
| `216-EVIDENCE.md` | VERIFIED | Rehearsal, negative controls, post-push, post-landing, and regression sections |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `.tool-versions` | ci.yml setup-beam | `version-file` + `strict` | WIRED (the log shows the exact pin installed) |
| `id: beam` step | every deps/PLT key | `steps.beam.outputs.*` | WIRED (the ordering classifier passes) |
| matrix rows | verify-test setup-beam | `matrix.version-file/otp/elixir` | WIRED (the run shows both lanes' exact builds) |
| release toolchain checkout | setup-beam | `.toolchain-pin/.tool-versions` | WIRED (Release 36320746183 / 36323594205 logs) |
| release.yml action major | CONTRIBUTING runbook | `release_please_runbook_errors/2` | WIRED (loose; WR-02) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Contract suites pass | `mix test` on the 4 contract files | 63 tests, 0 failures | PASS |
| CI resolves the exact pins, min on 24.04, NIF download | `gh run view 36320746124 --log` + perl ANSI strip + grep | as in criterion rows 1 and 3 | PASS |
| Allowlist is truthful | `gh api repos/<a>/contents/action.yml?ref=<r>` for 10 refs | all node24/composite | PASS |
| Release on v5, pin isolation in publish/smoke | `gh run view 36323594205 --log` | v5 download; OTP 27.3.4.15 in publish + smoke; 0 Node 20 lines | PASS |
| The regression happened as recorded | `gh run view 36319430805 --json jobs` | sync job failure; Release Please success | PASS (record honest) |
| Interrupted-save backstop | `gh api repos/actions/cache/contents/action.yml?ref=v5` | `post-if: "success()"`; no `save-always` in the repo | PASS |

### Probe Execution

SKIPPED: the phase declares no `scripts/*/tests/probe-*.sh`. Its evidence is run-log based and was re-checked above.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|-------------|--------------|--------|----------|
| PLAT-01 | 01, 02, 03, 06, 07, 08 | SATISFIED | Criterion 1. REQUIREMENTS.md still shows `[ ]` / Pending, so a tracker update is needed. |
| PLAT-02 | 04, 05, 06, 07 | SATISFIED | Criterion 2. The tracker still shows Pending. |
| PLAT-03 | 02, 06 | SATISFIED | Criterion 3. The tracker still shows Pending. |

No orphaned requirement IDs: REQUIREMENTS.md maps exactly PLAT-01..03 to Phase 216.

### Prohibitions (judged with deterministic evidence, not left as flags)

| Prohibition | Evidence | Result |
|-------------|----------|--------|
| No toolchain version change | `.tool-versions` at 8642610e = pre-phase content; min row = 26.2.5.21 / 1.15.8 | Held |
| No job-id / `Run test suite` / lane-axis rename | ci.yml diff has no job-key or `name:` removals; `lane: [min, current]` unchanged; required checks green | Held |
| Dated 27.0.1 Dialyzer receipt untouched | CONTRIBUTING:613, 621-622 intact | Held |
| Target-ref checkout inputs, permissions, concurrency, needs, if, secrets unchanged in release.yml | Filtered diff shows only relocated `ref:` lines (identical text) and new pin steps | Held |
| No action bumped beyond the named majors | checkout@v5, setup-node@v5, github-script@v8 unchanged | Held |
| Bump commit is not folded, and `with:`/token/id are unchanged | 21bb7e1b / 4dc227bf numstat `1 1` | Held |
| Push/merge/publish only under the maintainer's direct grant | Recorded in 216-EVIDENCE.md (push gate and landing brief) | Held (as recorded) |
| No `ubuntu-latest` / `ubuntu-26.04` for the min lane | min `runner: "ubuntu-24.04"` | Held |

### Anti-Patterns Found

No TBD/FIXME/XXX/TODO/HACK was added in the phase diff (`35d7ee8c..HEAD` over the product files).

| File | Line | Finding | Severity | Impact |
|------|------|---------|----------|--------|
| `.github/workflows/release.yml` | 34-37, 562-618 (also 451-453) | CR-01: `smoke-published` target checkout persists the token under inherited `contents: write` while it compiles Hex deps. `publish-hex` has the same shape with `contents: read`. | Escalation (security, out of scope) | Not a PLAT-01..03 truth. See below. |
| `CONTRIBUTING.md` | 23-24, 31, 563, 581-582 | WR-01: pin literals are repeated in the prose with no contract to `.tool-versions` | Warning | Docs can drift on the next pin bump. CI itself cannot drift. |
| `test/threadline/ci_action_runtime_contract_test.exs` | 124-158 | WR-02: runbook contract is a substring check; a stale `Last rehearsal` line can pass | Warning | Weakens the "rehearsal record stays current" guard. It does not negate the rehearsal that was recorded. |
| `test/threadline/ci_workflow_parity_contract_test.exs` | 1222-1260 | IN-01: key label not compared with `runs-on:` | Info | |
| `.tool-versions` / setup-node | | IN-02: Node pinned 22.14.0, but CI floats on `"22"` (deferred OD-5) | Info | Already in deferred-items.md |

### CR-01 scope decision (explicit, not dropped)

**Verdict: outside PLAT-01..03 and not a phase-216 gap. It still needs a maintainer scope decision now.**

- **Pre-existing.** `git show 35d7ee8c:.github/workflows/release.yml` shows smoke-published's single checkout as `ref: ${{ needs.release-ref.outputs.checkout_ref }}`, with no `persist-credentials: false` and no job `permissions:`.
- **Not reachable under the phase's rules.** Plans 216-03 and 216-08 explicitly prohibited changing the target-ref checkout inputs and any `permissions:` line. Fixing CR-01 inside this phase would have broken a stated prohibition. PLAT-01..03 cover toolchain, action runtime and runner image, not credential hygiene.
- **The phase made it more visible, not worse.** It added a credential-free pin checkout beside the credential-persisting one, and a `sync-release-pr-pins`-only credential contract that a reader may take as release-wide.
- **Not tracked anywhere.** It is not in `deferred-items.md` and not in any later roadmap phase (217-219 grep: no credential/permissions item). Without action it will be lost.

Recommended: a `/gsd-quick` security fix now, since the next Hex publish runs this job. The fix:

1. Add `permissions: contents: read` to `smoke-published`.
2. Add `persist-credentials: false` to the target checkouts in `smoke-published` and `publish-hex`.
3. Widen the release control-plane credential assertion to all three mix-running jobs, with per-job mutation controls.

Alternatively, record it as a backlog seed.

### Human Verification Required

None. Every truth was discharged with verifier-run evidence (tests, re-fetched run logs, upstream action.yml). The CR-01 item is a scope decision for the maintainer, not a verification step.

### Gaps Summary

- **Goal achieved.** CI installs exactly the committed `.tool-versions` build (OTP 27.3.4.15 / Elixir 1.17.3-otp-27) in every non-matrix job across all workflows, and the release jobs read the pin from the workflow commit through an isolated `.toolchain-pin` checkout.
- **Min lane.** It runs the exact floor build (OTP 26.2.5.21 / Elixir 1.15.8) on ubuntu-24.04 and downloads the lazy_html NIF 2.16 artifact.
- **Actions.** Every action ref is verified Node 24 or composite, guarded by a fail-closed contract. The bump shipped through a real release (0.11.1) on release-please-action v5.
- **Regression handled.** The one post-landing regression (sparse checkout on git 2.55) is recorded honestly and was closed in-phase by 216-08.
- **Open items (non-blocking).** WR-01/WR-02 contract-tightness warnings, the untracked CR-01 security follow-up, and the stale REQUIREMENTS.md checkboxes for PLAT-01..03.

---

_Verified: 2026-09-27T15:10:00Z_
_Verifier: Claude (gsd-verifier)_
