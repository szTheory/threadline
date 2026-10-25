---
phase: 244-release-flow
verified: 2026-10-25T16:20:00Z
status: gaps_found
score: 4/7 must-haves verified
covered_files:
  - ".github/workflows/browser-full.yml"
  - ".github/workflows/ci.yml"
  - ".github/workflows/deps-health.yml"
  - ".github/workflows/flake-detection.yml"
  - ".github/workflows/release.yml"
  - ".planning/phases/244-release-flow/244-01-PLAN.md"
  - ".planning/phases/244-release-flow/244-01-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-02-PLAN.md"
  - ".planning/phases/244-release-flow/244-02-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-03-PLAN.md"
  - ".planning/phases/244-release-flow/244-03-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-04-PLAN.md"
  - ".planning/phases/244-release-flow/244-04-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-05-PLAN.md"
  - ".planning/phases/244-release-flow/244-05-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-06-PLAN.md"
  - ".planning/phases/244-release-flow/244-06-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-07-PLAN.md"
  - ".planning/phases/244-release-flow/244-07-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-REL02-EVIDENCE.md"
  - ".planning/phases/244-release-flow/244-REVIEW.md"
  - "CHANGELOG.md"
  - "CONTRIBUTING.md"
  - "bin/date-release-changelog"
  - "bin/deps-health-report"
  - "bin/retry-network"
  - "bin/verify-bump-rehearsal"
  - "bin/verify-deps-audit"
  - "mix.exs"
  - "release-please-config.json"
  - "test/partition_weights.txt"
  - "test/threadline/ci_workflow_parity_contract_test.exs"
  - "test/threadline/date_release_changelog_test.exs"
  - "test/threadline/deps_audit_gate_test.exs"
  - "test/threadline/deps_health_report_test.exs"
  - "test/threadline/hex_pin_contract_test.exs"
  - "test/threadline/release_control_plane_contract_test.exs"
  - "test/threadline/retry_network_contract_test.exs"
covered_digest: "v3:sha256:e2fc0337d6fbf258f716b63fb77cf5ccfd8cbb0ca6bee7b64dfda9cf88789f17"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "SC4 / REL-04: the cause of the 1.1.0 `deps.get --check-locked` manager-field mismatch is recorded with evidence, and the mismatch cannot recur silently"
    status: failed
    reason: >-
      CONTRIBUTING.md "Why Hex is pinned in CI" (lines 715-730) records Hex version drift as the
      cause and states "An isolated reproduction showed Hex 2.5.1 accepts the `[]` lock and Hex
      2.6.0 rejects it". The phase's own 244-07 reproduction (isolated MIX_HOME/HEX_HOME, fresh
      deps/) shows both 2.5.1 and 2.6.0 reject the a3301bed `[]` lock, and both accept it when
      deps/ already holds plug_crypto 2.2.1. The discriminator is deps/ cache state, not Hex
      version. The recorded cause is therefore contradicted by evidence, and nothing stops a
      `[]` manager list from reaching CI again: a contributor with a populated deps/ passes
      `mix verify.deps_audit` locally and the PR's fresh-deps CI goes red, which is the exact
      1.1.0 failure the phase goal says must not recur.
    artifacts:
      - path: "CONTRIBUTING.md"
        issue: "lines 726-728 assert the falsified Hex-drift cause and a reproduction result that 244-07 could not reproduce"
      - path: "bin/verify-deps-audit"
        issue: "no fresh-deps / manager-list hygiene check; a populated deps/ masks an empty manager list"
    missing:
      - "Rewrite the CONTRIBUTING cause paragraph to the observed mechanism (a fetch from a fresh deps/ rewrites `[]` to `[:mix]`, so --check-locked fails only where deps/ is cold); keep the Hex 2.6.0 pin, described as toolchain determinism rather than the fix"
      - "Add a lock-hygiene check (e.g. in bin/verify-deps-audit or a contract test over the three tracked mix.lock files) that rejects a `:hex` lock entry whose manager list is empty, independent of deps/ state, with a mutation control using the a3301bed plug_crypto 2.2.1 entry"
  - truth: "The phase's changes introduce no regression to the shipped package or to contributor tooling (code review CR-01)"
    status: failed
    reason: >-
      mix.exs `retry_network/0` (lines 278-289) is called from inside `aliases/0`
      (line 227, the "test.setup" alias string), and `project/0` calls `aliases()`, so the
      whitespace/quote guard runs on every project load and Mix.raise-s when the checkout path
      contains whitespace or a quote. Reproduced here: mix.exs copied into
      `<scratch>/cr01/a b/` makes `mix help compile` fail with
      `** (Mix.Error) the checkout path ".../a b/bin/retry-network" contains whitespace or a
      quote` (stack: mix.exs:282 retry_network/0 <- mix.exs:227 aliases/0); the same file in
      `<scratch>/cr01/ab/` and the pre-phase mix.exs (5d83bf24) in `<scratch>/cr01/old b/`
      both load fine. mix.exs ships in the Hex package (`files:` line 561) and Mix evaluates
      project/0 for dependencies, so the next release would break `mix deps.get`/compile for
      any adopter whose project path contains a space, and locks contributors in such paths
      out of every mix task. A release that breaks adopters contradicts the phase goal of a
      clean release flow.
    artifacts:
      - path: "mix.exs"
        issue: "retry_network/0 raises at project load (via aliases/0) for paths with whitespace or quotes"
      - path: "test/threadline/retry_network_contract_test.exs"
        issue: "no test loads mix.exs from a directory whose name contains a space"
    missing:
      - "Resolve the retry-network path lazily (inside a function alias / the fetch helper), passed via env (e.g. RETRY_NETWORK) rather than interpolated into shell text, so nothing is evaluated or refused at project load"
      - "Add a regression test that loads mix.exs (e.g. `mix help compile` or Mix.Project.in_project) from a directory whose name contains a space and asserts success"
deferred:
  - truth: "SC2 / REL-02 observed half: one observed run where a non-releasable merge regenerates the open release PR and fresh pull_request CI runs on the new head with zero human actions (also closes assumption A1: release-please v5 sets prs_created on an always-update refresh)"
    addressed_in: "First natural release cycle after phase 244 lands (244-REL02-EVIDENCE.md procedure; v1.47 milestone close audit or next phase verifier)"
    evidence: "244-REL02-EVIDENCE.md Status: pending; trigger condition (phase landed + open release PR + later non-releasable merge) cannot exist before landing; maintainer rule forbids a throwaway release"
  - truth: "SC1 / REL-01 live half: the real release PR's first CI run is green with the workflow-dated CHANGELOG"
    addressed_in: "First release after phase 244 lands (machine-observable via gh run list on release-please--branches--main)"
    evidence: "Mechanism proven by contract tests and the plain-clone bump rehearsal; the live release PR does not exist yet"
  - truth: "A3: Hex 2.6.0 installs and runs on the verify-test matrix min lane (Elixir 1.15.8 / OTP 26) and latest lane (1.20.4 / OTP 29)"
    addressed_in: "The phase 244 PR's own CI run"
    evidence: "244-06 PLAN flags A3 as confirmed only by the phase PR's CI; local gate ran on Elixir 1.17.3 / OTP 27 only"
---

# Phase 244: Release flow Verification Report

**Phase Goal:** A release takes the landing PR, the release PR and the Hex approval, with no CHANGELOG-dating PR, no hand rebase of a stale release PR, and no red run from a transient fetch or Hex lock drift.
**Verified:** 2026-10-25T16:20:00Z
**Status:** gaps_found
**Re-verification:** No, initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 / REL-01: landing-PR prose under `## Unreleased` is renamed to `## [X.Y.Z] - YYYY-MM-DD` on the release branch by the workflow; no dating PR; release-shape and version-truth contracts pass against the renamed shape | VERIFIED (live first-green release PR deferred to landing) | `release.yml` sync-release-pr-pins: `mix release.pins --check` (l.197) then `run: bin/date-release-changelog` (l.205) then `git add -- README.md guides/ CHANGELOG.md` (l.217). `date_release_changelog_test.exs` runs `bin/verify-release-shape` on the script's output; `release_control_plane_contract_test.exs` `changelog_dating_errors/1` with mutation controls. Targeted run: 239 tests, 0 failures. `bin/verify-bump-rehearsal` l.468-476 runs the production script; 244-07 recorded `Bump rehearsal OK` from a plain clone of d1b7ad6d, and no non-planning file changed between d1b7ad6d and HEAD. |
| 2 | SC2 / REL-02: a non-releasable merge regenerates the stale release PR with a CI-triggering token and fresh CI runs with zero human actions, proven by a contract test and one observed run | DEFERRED (contract half verified; observed run impossible before landing) | `release-please-config.json` has top-level `"always-update": true`; release-please step token `secrets.RELEASE_PLEASE_TOKEN \|\| secrets.GITHUB_TOKEN` (l.107); sync job `if:` keys on `prs_created == 'true'` (l.130); `regenerate_errors/2` with mutation controls passes. Observed run: 244-REL02-EVIDENCE.md `Status: pending` (no release PR open; phase not on main). Assumption A1 rides on this observation. Not counted as verified. |
| 3 | SC3 / REL-03: `mix deps.get` and the hex-evaluator resolve retry with backoff on transient failure; a contract test fails if a test step is wrapped in a retry | VERIFIED | `bin/retry-network mix test` exits 2 with `refusing 'mix test'` (run here). 15 workflow fetches retried: 14 via `bin/retry-network` / `../../bin/retry-network`, publish-hex via the inline `for attempt in 1 2 3` loop (release.yml l.543). Nested fetches in mix.exs (l.227, 293, 306, 368, 496 hex-evaluator) go through `retry_network()` with the compile/ecto/test tail unwrapped. No `uses:` containing `retry`. `retry_network_contract_test.exs`, `deps_audit_gate_test.exs`, `deps_health_report_test.exs` green. Review warnings WR-01..WR-04 weaken the marker list, backoff cap and signal claims but do not defeat the criterion. |
| 4 | SC4 / REL-04: the cause of the 1.1.0 mismatch is recorded with evidence; the mismatch cannot recur silently | FAILED (BLOCKER) | CONTRIBUTING.md l.726-728 records Hex drift and a "2.5.1 accepts" reproduction; the phase's own 244-07 reproduction shows both 2.5.1 and 2.6.0 reject the `[]` lock from a fresh deps/ and both accept it from a populated one. The recorded cause is falsified, and no check stops a `[]` manager list passing locally and turning CI red. See gaps. |
| 5 | All 17 `erlef/setup-beam` steps set `install-hex: false` and are followed by a retried `mix local.hex 2.6.0 --force`; `MIN_HEX` equals the pin (plans 05/06) | VERIFIED (A3 deferred to the phase PR CI) | `grep -c "install-hex: false"`: ci.yml 11, release.yml 3, browser-full 1, flake-detection 1, deps-health 1 = 17; 17 `local.hex 2.6.0` lines; `bin/verify-deps-audit` `MIN_HEX="2.6.0"`; `hex_pin_contract_test.exs` green with its 17-step not-vacuous count. Determinism value stands even though drift is not the 1.1.0 cause. |
| 6 | No regression to the shipped package or contributor tooling (code review CR-01) | FAILED (BLOCKER) | Reproduced: mix.exs in a directory named `a b` fails `mix help compile` with `Mix.Error ... contains whitespace or a quote` from `retry_network/0` <- `aliases/0` (mix.exs:282 <- :227). Pre-phase mix.exs (5d83bf24) in a spaced directory loads fine. mix.exs ships in the Hex package. See gaps. |
| 7 | `CI=true mix ci.all` is green on the phase tree under Hex 2.6.0 (plan 07) | VERIFIED | Orchestrator gate log on ephemeral postgres:16 (`<scratch>/gate-244.log.clean`) read directly: `verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0)`, `32 properties, 3250 tests, 0 failures, 3 excluded`, example app `132 tests, 0 failures`, Dialyzer `Total errors: 0`, Playwright `418 passed`, `ci.all exit=0`. |

**Score:** 4/7 truths verified (0 present, behavior-unverified; 1 deferred to landing)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | REL-02 observed run (and A1) | First natural release cycle after landing | 244-REL02-EVIDENCE.md, Status pending, read-only `gh` procedure recorded |
| 2 | REL-01 live: the release PR's first CI run is green | First release after landing | Contract + rehearsal prove the mechanism |
| 3 | A3: Hex 2.6.0 on min/latest matrix lanes | Phase 244 PR CI | 244-06 must-have flags it as PR-CI-only |

These are machine-observable later, so they are not human-verification items (project rule: zero human verification by default).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bin/date-release-changelog` | Unreleased -> `[X.Y.Z] - DATE` with re-seed | VERIFIED | Wired in release.yml l.205 and bin/verify-bump-rehearsal l.469; behaviour tests green |
| `release-please-config.json` | `always-update: true` | VERIFIED | Top-level JSON boolean; does not name CHANGELOG.md |
| `bin/retry-network` | Allowlisted retry wrapper | VERIFIED | Refusal reproduced; wired in 14 workflow steps, mix.exs, three bin scripts |
| `mix.exs` `retry_network/0` | Wrapper path for nested fetches | STUB-free but DEFECTIVE | Evaluated at project load; raises on spaced paths (CR-01) |
| `test/threadline/hex_pin_contract_test.exs` | Pin contract over all workflows | VERIFIED | Green; 17-step count |
| `bin/verify-deps-audit` | `MIN_HEX="2.6.0"`, retried fetch | VERIFIED (for pin); missing lock-hygiene check (gap) | |
| `CONTRIBUTING.md` | REL-01/02 flow + REL-04 cause | PARTIAL | Release flow l.1101-1103 correct; REL-04 cause l.726-728 falsified |
| `244-REL02-EVIDENCE.md` | Observed-run procedure and status | VERIFIED | 8 sections, Status pending, PAT-expiry item routed |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| release.yml sync-release-pr-pins | bin/date-release-changelog | step after `mix release.pins --check`, stages CHANGELOG.md | WIRED |
| release-please-config.json | release.yml sync job | always-update -> prs_created (A1 unobserved) | WIRED (runtime pending) |
| bin/verify-bump-rehearsal | bin/date-release-changelog | `"$ROOT/bin/date-release-changelog" --root "$CLONE"` | WIRED |
| workflows Install dependencies | bin/retry-network | `run: bin/retry-network mix deps.get` | WIRED |
| mix.exs verify_hex_evaluator | bin/retry-network | `#{retry_network()} mix deps.get && ... mix test` | WIRED (CR-01 defect in the helper) |
| hex_pin_contract_test.exs | bin/verify-deps-audit | MIN_HEX parse vs workflow pins | WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase contract and behaviour tests | `mix test` on the 7 phase test files | 239 tests, 0 failures | PASS |
| Wrapper refuses a test command | `bin/retry-network mix test` | exit 2, `refusing 'mix test'` | PASS |
| mix.exs loads from a spaced path | `mix help compile` in `<scratch>/cr01/a b/` | `Mix.Error ... contains whitespace or a quote` | FAIL |
| Control: no-space path / pre-phase mix.exs in spaced path | `mix help compile` | loads, prints help | PASS (proves regression) |

### Probe Execution

Step 7c: no `scripts/*/tests/probe-*.sh` declared or present for this phase.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|------------|--------|----------|
| REL-01 | 244-01, 02, 07 | SATISFIED (live release PR deferred) | Truth 1 |
| REL-02 | 244-01, 02, 07 | PENDING (contract satisfied; observed run deferred) | Truth 2; REQUIREMENTS.md shows Pending, consistent |
| REL-03 | 244-03, 04, 06, 07 | SATISFIED | Truth 3 (but see CR-01, introduced by the REL-03 nested-fetch work in 244-04) |
| REL-04 | 244-05, 06, 07 | BLOCKED | Truth 4; REQUIREMENTS.md shows Pending, consistent |

All four IDs appear in plan frontmatter; REQUIREMENTS.md maps no other ID to Phase 244. No orphans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| mix.exs | 227, 278-289 | Guard evaluated at project load via alias string interpolation | Blocker | Breaks every mix command (and adopters' deps) on spaced paths |
| CONTRIBUTING.md | 726-728 | Documented cause contradicted by phase evidence | Blocker | Misleads future maintainers; no prevention of the real failure mode |
| bin/retry-network | 117-120 | `Dependency resolution failed` marker never matches Hex output (WR-01) | Warning | Deterministic resolution failures retried 3x |
| bin/retry-network | backoff | No cap on backoff (WR-03); signal claim inaccurate (WR-04) | Warning | Slower failure, not wrong result |
| .github/workflows/release.yml | 210-227 | PUSH_TOKEN in env/URL while hooks run (WR-05, pre-existing) | Warning | Pre-existing |

No unreferenced TBD/FIXME/XXX/TODO/HACK added in the phase diff.

### Human Verification Required

None. Items not yet observable are machine-observable after landing and are recorded as deferred above.

### Gaps Summary

Two blockers, separate root causes:

1. **REL-04 cause is wrong and the failure mode is unguarded.** The phase pinned Hex 2.6.0 everywhere (correctly implemented and contract-tested) on the premise that version drift caused the 1.1.0 red run. The phase's own reproduction falsified that premise: deps/ cache state decides whether `--check-locked` rejects an empty manager list. CONTRIBUTING still states the falsified cause and a reproduction result that did not reproduce, and no check prevents a `[]` lock from passing locally and failing CI. Fix: rewrite the cause, keep the pin as determinism, add a deps-state-independent lock-hygiene check with a mutation control.

2. **CR-01 shipping regression in mix.exs.** The REL-03 nested-fetch helper is evaluated at project load and raises for any path with whitespace or quotes. Because mix.exs ships in the Hex package, releasing this tree would break adopters with spaces in their project path. Fix: resolve the path lazily and pass it via env; add a spaced-path load test.

REL-01, REL-03 and the Hex pin itself are achieved. REL-02's observed run and A3 are deferred to landing / the phase PR's CI, not failures.

---

_Verified: 2026-10-25T16:20:00Z_
_Verifier: Claude (gsd-verifier)_
