---
phase: 244-release-flow
verified: 2026-10-25T17:10:00Z
status: passed
score: 6/7 must-haves verified (1 deferred to landing, not failed)
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
  - ".planning/phases/244-release-flow/244-08-PLAN.md"
  - ".planning/phases/244-release-flow/244-08-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-09-PLAN.md"
  - ".planning/phases/244-release-flow/244-09-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-10-PLAN.md"
  - ".planning/phases/244-release-flow/244-10-SUMMARY.md"
  - ".planning/phases/244-release-flow/244-REL02-EVIDENCE.md"
  - ".planning/phases/244-release-flow/244-REVIEW-DISPOSITION.md"
  - ".planning/phases/244-release-flow/244-REVIEW.md"
  - "CHANGELOG.md"
  - "CONTRIBUTING.md"
  - "bin/date-release-changelog"
  - "bin/deps-health-report"
  - "bin/retry-network"
  - "bin/verify-bump-rehearsal"
  - "bin/verify-deps-audit"
  - "bin/verify-lock-hygiene"
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
covered_digest: "v3:sha256:c6154a381c3c26eef4f4768f9ea7ec53750c2af891dee549a478ce207ce5a62b"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/7
  gaps_closed:
    - "SC4 / REL-04: the cause of the 1.1.0 `deps.get --check-locked` manager-field mismatch is recorded with evidence, and the mismatch cannot recur silently"
    - "The phase's changes introduce no regression to the shipped package or to contributor tooling (code review CR-01)"
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "SC2 / REL-02 observed half: one observed run where a non-releasable merge regenerates the open release PR and fresh pull_request CI runs on the new head with zero human actions (also closes assumption A1: release-please v5 sets prs_created on an always-update refresh)"
    addressed_in: "First natural release cycle after phase 244 lands (244-REL02-EVIDENCE.md procedure; v1.47 milestone close audit or next phase verifier)"
    evidence: "244-REL02-EVIDENCE.md `Status: pending`; the trigger (phase on main + open release PR + later non-releasable merge) cannot exist before landing; maintainer rule forbids a throwaway release. Machine-observable via the recorded read-only gh procedure."
  - truth: "SC1 / REL-01 live half: the real release PR's first CI run is green with the workflow-dated CHANGELOG"
    addressed_in: "First release after phase 244 lands (machine-observable via gh run list on release-please--branches--main)"
    evidence: "Mechanism proven by contract tests and the plain-clone bump rehearsal; the live release PR does not exist yet"
  - truth: "A3: Hex 2.6.0 installs and runs on the verify-test matrix min lane (Elixir 1.15.8 / OTP 26) and latest lane (1.20.4 / OTP 29)"
    addressed_in: "The phase 244 PR's own CI run"
    evidence: "244-06 PLAN flags A3 as confirmed only by the phase PR's CI; the local gate ran one toolchain only"
advisory:
  - finding: "R2-WR-01: CONTRIBUTING.md:717/754, bin/verify-deps-audit:64 and the hex_pin_contract_test moduledoc say CI and local run one Hex version, but MIN_HEX is a floor (version_ge), so a newer local Hex passes"
    category: other
    reason: "Prose overstates local enforcement of the pin. It does not touch the recorded 1.1.0 cause or the deps/-independent prevention, and CI itself is pinned exactly (17/17 steps). Resolve by Option B wording (CI exactly 2.6.0, local refuses older) or by enforcing equality. Recommended before landing; cheap."
    evidence_status: "reproduced by round-2 review (code reading of bin/verify-deps-audit:247); does not defeat a must-have"
  - finding: "R2-WR-02: bin/verify-lock-hygiene exits 1 (crash) instead of 2 on a non-string version in a violating entry, and a malformed later lock in a multi-lock call hides an earlier violation"
    category: other
    reason: "Wrong diagnosis and exit code in edge cases, but every case is still non-zero, so the gate fails closed; bin/verify-deps-audit passes one lock per call, so the ordering case cannot occur in the gate."
    evidence_status: "reproduced by round-2 review; fails closed; does not defeat a must-have"
  - finding: "R2-WR-03: the nested-fetch contract pins the `$RETRY_NETWORK` name and the env pairing, not the binding in retry_network_env/1"
    category: other
    reason: "Future-regression protection is weaker than the test header claims. The current binding is correct (mix.exs:280 `Path.join(__DIR__, \"bin/retry-network\")`) and the gate exercised it (an unset or wrong variable would exit 127 in verify.bench_compile / verify.example, which passed). Fix: pin the function body plus an `env` mutation control."
    evidence_status: "reproduced by round-2 review; present code is correct; does not defeat a must-have"
---

# Phase 244: Release flow Verification Report

**Phase Goal:** A release takes the landing PR, the release PR and the Hex approval, with no CHANGELOG-dating PR, no hand rebase of a stale release PR, and no red run from a transient fetch or Hex lock drift.
**Verified:** 2026-10-25T17:10:00Z
**Status:** passed (3 items deferred to landing; 3 advisory warnings)
**Re-verification:** Yes, after gap closure (plans 244-08, 244-09, 244-10)

## Prior gaps

| Prior gap | Status | Evidence (checked here, not taken from SUMMARYs) |
|-----------|--------|---------------------------------------------------|
| SC4 / REL-04: cause recorded with evidence; mismatch cannot recur silently | **CLOSED** | (1) CONTRIBUTING.md "Why Hex is pinned in CI" (l.715-760) now records the observed mechanism: cold `deps/` fetch rewrites `[]` to the declared manager, warm `deps/` fetches nothing, Hex 2.5.1 and 2.6.0 behave the same; the pin is described as toolchain determinism, "The pin did not fix the 1.1.0 red run". `git grep "2.5.1 accept"` outside `.planning/` finds nothing; ci.yml's pin comment was corrected too. (2) New `bin/verify-lock-hygiene` parses the lock with `Code.string_to_quoted` (no `Code.eval*`) and rejects any `:hex` entry with `[]` managers. Run here: all 4 tracked locks, 134 `:hex` entries, exit 0; the a3301bed root `mix.lock` (`git show a3301bed:mix.lock`) exits 1 naming `plug_crypto 2.2.1`; the f7fdcaca lock exits 0. No fetch, no `deps/` read, so cold/warm cannot change the verdict. (3) Wired: `bin/verify-deps-audit` l.334 runs it per audited directory before `deps.get --check-locked` and aggregates into `FAILURES`, so `mix verify.deps_audit` (in `ci.all`) and the CI `verify-deps-audit` job fail on it. A warm-fetch test (`deps_audit_gate_test.exs:567`) proves a successful fetch cannot mask `[]`. |
| CR-01: no regression to the shipped package or contributor tooling | **CLOSED** | `mix.exs` `"test.setup"` is now `[&test_setup_fetch/1, "test"]` (l.226); `retry_network_env/1` (l.279-281) is called only inside task functions; all five fetches expand `"$RETRY_NETWORK"` in the child shell (l.286, 296, 309, 371, 499); nothing in `project/0`/`aliases/0` validates a path. Reproduced here: copied `mix.exs` + `.tool-versions` into `<scratch>/verif244/a b`, `.../q"x` and ``.../t`y``; `mix help compile` exits 0 in each. Contract tests include a spaced-path load test and an eager-guard mutation control (`retry_network_contract_test.exs:1330`). `package/0` `files:` unchanged in the gap-closure diff. |

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 / REL-01: Unreleased renamed to `## [X.Y.Z] - YYYY-MM-DD` on the release branch by the workflow; no dating PR; release-shape and version-truth contracts pass | VERIFIED (live first-green release PR deferred) | Regression check: `release.yml` l.205 `run: bin/date-release-changelog` unchanged (no `.github` change in 08-10 except a ci.yml comment); `date_release_changelog_test.exs`, `release_control_plane_contract_test.exs` green in the 267-test run below. |
| 2 | SC2 / REL-02: stale release PR regenerated with a CI-triggering token, fresh CI, zero human actions; contract test + one observed run | DEFERRED (contract half verified) | `release-please-config.json` l.4 `"always-update": true` unchanged; contract tests green. Observed run: `244-REL02-EVIDENCE.md` `Status: pending`; cannot exist before landing. Not counted in the score. |
| 3 | SC3 / REL-03: `mix deps.get` and hex-evaluator resolve retry with backoff; a contract test fails if a test step is wrapped | VERIFIED | Prior evidence holds; 244-09 kept the 5 nested fetches behind `"$RETRY_NETWORK"` with compile/ecto/test tails unwrapped (mix.exs l.296, 309, 371, 499). `bin/retry-network` WR-01/03/04 fixes landed in 3c08524b. The gate's verify.bench_compile and verify.example ran these scripts green, which also shows `RETRY_NETWORK` is bound to an executable. `retry_network_contract_test.exs` green. |
| 4 | SC4 / REL-04: cause recorded with evidence; mismatch cannot recur silently | VERIFIED | See Prior gaps row 1. |
| 5 | All 17 `erlef/setup-beam` steps set `install-hex: false` and are followed by a retried `mix local.hex 2.6.0 --force`; `MIN_HEX` equals the pin | VERIFIED (A3 deferred) | Counts re-taken: `install-hex: false` and `local.hex 2.6.0` are each ci 11 + release 3 + browser-full 1 + flake-detection 1 + deps-health 1 = 17. `MIN_HEX="2.6.0"` (bin/verify-deps-audit l.65). `hex_pin_contract_test.exs` green. Plan-08 prohibition (pin unchanged) holds. |
| 6 | No regression to the shipped package or contributor tooling (CR-01) | VERIFIED | See Prior gaps row 2. |
| 7 | `CI=true mix ci.all` green on the combined tree | VERIFIED | Gate log (`<scratch>/244-10/gate-244-gaps.log.clean`) read directly: `verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0)` (l.10), `32 properties, 3278 tests, 0 failures` (l.282), example `132 tests, 0 failures` (l.345), `Total errors: 0` (l.375), Playwright `417 passed`, `1 flaky`, no failed line (l.1076-1079), `ci.all exit=0` (l.1080). `git diff 3c08524b..HEAD` outside `.planning/` is empty, so the gated tree equals HEAD. The hygiene step prints only on failure; its success is shown by the absence of any `lock hygiene exited` line plus my direct run over all tracked locks. |

**Score:** 6/7 truths verified (0 present, behavior-unverified; 1 deferred to landing)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | REL-02 observed run (and A1) | First natural release cycle after landing | 244-REL02-EVIDENCE.md `Status: pending`, read-only `gh` procedure recorded |
| 2 | REL-01 live: release PR's first CI run green | First release after landing | Contract tests + bump rehearsal prove the mechanism |
| 3 | A3: Hex 2.6.0 on min/latest matrix lanes | Phase 244 PR CI | 244-06 must-have flags it as PR-CI-only |

All three are machine-observable after landing, so none is a human-verification item (project rule: zero human verification by default).

### Advisory: round-2 review warnings (judgment calls)

| # | Finding | Defeats a must-have? | Reasoning |
|---|---------|----------------------|-----------|
| R2-WR-01 | "one Hex version" prose vs the `MIN_HEX` floor | No (advisory WARNING) | SC4 asks for the cause recorded with evidence and for non-silent recurrence. The cause paragraph is correct and the prevention is Hex-version-independent. CI is pinned exactly, so CI cannot drift. The false sentence is about local enforcement of a determinism measure. A newer local Hex is a dev-machine mismatch that PR CI catches before release, not a release-run red. Still a doc inaccuracy that this phase introduced, so fix it before landing (Option B wording is a two-line change). |
| R2-WR-02 | lock-hygiene exit-code contract (crash exits 1; multi-lock ordering) | No (advisory WARNING) | Every reproduced case still exits non-zero, so the gate fails closed. The gate passes one lock per call, so the ordering case cannot happen there. The diagnosis is wrong, but nothing passes that should fail. |
| R2-WR-03 | contract pins the env-var name, not its binding | No (advisory WARNING) | The truth "all 5 nested fetches run through bin/retry-network" holds on the current code (l.280 binds the real path; the gate exercised it). The weakness is that a future mutation of `retry_network_env/1` could remove retries without a red test. Silent breakage needs an executable stand-in; a typo exits 127. This is a hardening item, not a present defect. |

### REL-04 wording judgment

REQUIREMENTS/ROADMAP read: "cause ... is verified. If Hex version drift is the cause, CI pins the Hex version, so the lock mismatch cannot recur silently." The conditional's premise turned out false, and the cause (cold vs warm `deps/` with a `[]` manager list) is now verified and recorded with a reproduction. The requirement's intent clause, "cannot recur silently", is met by a mechanism that fits the real cause: a static check in `ci.all` and in required CI that `deps/` state cannot mask. The pin is kept anyway for determinism. **SC4 is met in substance.** REQUIREMENTS.md still lists REL-04 as Pending (l.14, l.58), so the state step should flip it to Complete. Optionally, a wording note in REQUIREMENTS can record that the cause was deps/ state, not Hex drift.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bin/verify-lock-hygiene` | deps/-independent `[]` manager check | VERIFIED | 135 lines, parse-only, wired from verify-deps-audit l.334; mutation and control reproduced here |
| `bin/verify-deps-audit` | per-dir hygiene call before fetch, aggregated | VERIFIED | l.329-341 |
| `test/threadline/deps_audit_gate_test.exs` | live-tree, mutation control, warm-deps tests | VERIFIED | a3301bed/f7fdcaca entries l.517-553, warm-fetch test l.567; green |
| `CONTRIBUTING.md` | corrected REL-04 cause and pin rationale | VERIFIED (R2-WR-01 advisory on l.717/754) | l.715-760 |
| `mix.exs` | lazy `retry_network_env/1`, function alias, `"$RETRY_NETWORK"` | VERIFIED | l.226, 279-281, five fetch scripts |
| `test/threadline/retry_network_contract_test.exs` | spaced-path load + eager-guard mutant, alias rule, marker and cap tests | VERIFIED | l.1201-1339; green |
| `bin/retry-network` | real marker, delay cap, base bound, corrected header | VERIFIED | per round-2 review table, tests green |
| `244-REVIEW-DISPOSITION.md` | R1 findings dispositioned | VERIFIED | R1: 4 fixed, 6 deferred with rationale; R2 rows open (advisory, see above) |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| bin/verify-deps-audit | bin/verify-lock-hygiene | `"$SCRIPT_DIR/verify-lock-hygiene" "$resolved/mix.lock"` in the per-dir loop | WIRED |
| mix.exs verify.deps_audit / ci.yml verify-deps-audit job | bin/verify-deps-audit | existing wiring (ci.all l.~241) | WIRED |
| mix.exs task functions | bin/retry-network | `Mix.shell().cmd(cmd, env: retry_network_env(...))` + `"$RETRY_NETWORK" mix deps.get` | WIRED (exercised by gate) |
| retry_network_contract_test wrapper regexes | mix.exs fetch lines | `"$RETRY_NETWORK"` regex | WIRED (binding not pinned: R2-WR-03) |
| release.yml sync job | bin/date-release-changelog | l.205 | WIRED (unchanged) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase test files | `mix test` on the 7 phase contract/behaviour files | 267 tests, 0 failures | PASS |
| Live locks clean | `bin/verify-lock-hygiene $(git ls-files '*mix.lock')` | 4 locks, 134 entries clean, exit 0 | PASS |
| a3301bed lock rejected | `bin/verify-lock-hygiene <a3301bed mix.lock>` | exit 1, names `plug_crypto 2.2.1` | PASS |
| f7fdcaca lock accepted | `bin/verify-lock-hygiene <f7fdcaca mix.lock>` | exit 0, 46 entries | PASS |
| mix.exs loads from special-char paths | `mix help compile` in `a b`, `q"x`, ``t`y`` | exit 0 in each | PASS |

### Probe Execution

Step 7c: no `scripts/*/tests/probe-*.sh` declared or present for this phase.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|------------|--------|----------|
| REL-01 | 244-01, 02, 07 | SATISFIED (live release PR deferred) | Truth 1 |
| REL-02 | 244-01, 02, 07 | Contract SATISFIED; observed run DEFERRED | Truth 2; REQUIREMENTS.md Pending is consistent |
| REL-03 | 244-03, 04, 06, 07, 09, 10 | SATISFIED | Truth 3, CR-01 closed |
| REL-04 | 244-05, 06, 07, 08, 10 | SATISFIED (in substance; see wording judgment) | Truth 4; REQUIREMENTS.md still says Pending and needs updating |

All four IDs appear in plan frontmatter. REQUIREMENTS.md maps no other ID to Phase 244, so there are no orphans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| CONTRIBUTING.md / bin/verify-deps-audit / hex_pin_contract_test.exs | 717, 754 / 64 / 3 | Prose claims equality; code enforces a floor (R2-WR-01) | Warning (advisory) | Doc accuracy |
| bin/verify-lock-hygiene | 48, 36-62 | Exit-code contract edge cases (R2-WR-02) | Warning (advisory) | Fails closed; wrong diagnosis |
| test/threadline/retry_network_contract_test.exs | 978, 1255-1263 | Binding of RETRY_NETWORK unpinned (R2-WR-03) | Warning (advisory) | Future regression could pass |
| bin/verify-deps-audit | 340 | FAIL line blames `[]` for every status (R2-IN-01) | Info | |
| mix.exs | 190-194 | Stale verify.deps_audit comment (R2-IN-03) | Info | |

No TBD/FIXME/XXX/TODO/HACK added in the gap-closure diff (`ffbaf4c4..HEAD`, non-planning).

### Human Verification Required

None. The deferred items are machine-observable after landing.

### Gaps Summary

Both prior blockers are closed, with evidence reproduced here. The REL-04 cause is now recorded as what the phase's own reproduction showed (`deps/` state, not Hex version). A static, `deps/`-independent lock-hygiene check now runs in `ci.all` and in required CI, and it rejects the exact a3301bed entry. CR-01 is fixed: `mix.exs` loads from paths containing a space, `"` or a backtick, and a mutation-controlled test guards it. The combined tree passed the full gate, and HEAD equals the gated tree outside `.planning/`.

What remains is deferred to landing (REL-02 observed run, REL-01 live release PR, A3 matrix lanes), plus three advisory round-2 warnings. None of the three defeats a must-have. R2-WR-01 is a doc inaccuracy this phase introduced and should be fixed before landing, but it does not reopen SC4.

---

_Verified: 2026-10-25T17:10:00Z_
_Verifier: Claude (gsd-verifier)_
