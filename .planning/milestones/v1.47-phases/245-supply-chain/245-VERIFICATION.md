---
phase: 245-supply-chain
verified: 2026-10-25T21:30:00Z
status: passed
score: 4/4 must-haves verified (roadmap success criteria; every non-backstop plan truth verified, 2 backstop truths handed to landing)
covered_files:
  - ".github/dependabot.yml"
  - ".github/workflows/branch-protection.yml"
  - ".github/workflows/browser-full.yml"
  - ".github/workflows/ci.yml"
  - ".github/workflows/community-health.yml"
  - ".github/workflows/deps-health.yml"
  - ".github/workflows/environment-protection.yml"
  - ".github/workflows/flake-detection.yml"
  - ".github/workflows/release.yml"
  - ".planning/phases/245-supply-chain/245-01-PLAN.md"
  - ".planning/phases/245-supply-chain/245-01-SUMMARY.md"
  - ".planning/phases/245-supply-chain/245-02-PLAN.md"
  - ".planning/phases/245-supply-chain/245-02-SUMMARY.md"
  - ".planning/phases/245-supply-chain/245-03-PLAN.md"
  - ".planning/phases/245-supply-chain/245-03-SUMMARY.md"
  - ".planning/phases/245-supply-chain/245-04-PLAN.md"
  - ".planning/phases/245-supply-chain/245-04-SUMMARY.md"
  - ".planning/phases/245-supply-chain/245-05-PLAN.md"
  - ".planning/phases/245-supply-chain/245-05-SUMMARY.md"
  - ".tool-versions"
  - "CONTRIBUTING.md"
  - "bin/deps-audit-tier"
  - "bin/deps-health-report"
  - "bin/upsert-ci-issue"
  - "bin/verify-action-pins"
  - "bin/verify-deps-audit"
  - "release-please-config.json"
  - "test/fixtures/deps_audit/sarif/advisory_plug.json"
  - "test/fixtures/deps_audit/sarif/clean.json"
  - "test/fixtures/deps_audit/sarif/denied_plug.json"
  - "test/fixtures/deps_audit/sarif/plug_1_20_0.json"
  - "test/fixtures/deps_audit/sarif/retired_plug.json"
  - "test/fixtures/deps_audit/sarif/unparseable_fingerprint.json"
  - "test/fixtures/deps_audit/sarif/vulnerable_lock.json"
  - "test/fixtures/deps_audit/vulnerable_lock/README.md"
  - "test/partition_weights.txt"
  - "test/threadline/browser_journey_evidence_contract_test.exs"
  - "test/threadline/ci_action_pin_contract_test.exs"
  - "test/threadline/ci_action_runtime_contract_test.exs"
  - "test/threadline/ci_issue_upsert_contract_test.exs"
  - "test/threadline/ci_topology_contract_test.exs"
  - "test/threadline/ci_workflow_parity_contract_test.exs"
  - "test/threadline/dependabot_config_contract_test.exs"
  - "test/threadline/deps_audit_gate_test.exs"
  - "test/threadline/deps_health_doc_contract_test.exs"
  - "test/threadline/deps_health_report_test.exs"
  - "test/threadline/flake_classifier_contract_test.exs"
  - "test/threadline/verify_action_pins_test.exs"
covered_digest: "v3:sha256:0bc02ceef6db677db18b3325c1601e8caadc1c74972f9c1edd902a210407d472"
behavior_unverified: 0
overrides_applied: 0
landing_handoffs: # Post-landing observations (D-28, D-31, D-32). They need a push to main, which is a maintainer-only action under CLAUDE.md, so they are hand-offs and not human_needed items.
  - item: "GitHub accepts .github/dependabot.yml and opens one grouped github-actions PR (covers the two 245-05 backstop truths: idempotent single grouped PR, GitHub-side serialization)"
    why_not_now: "Dependabot reads the default branch only; the config is not on main yet. Pre-landing evidence: exactly one update entry, one group with patterns [\"*\"], pinned by dependabot_config_contract_test."
  - item: "Issue #61 (currently OPEN, titled 'Dependency health: outdated') is retitled by the next non-clean run and closed by the first clean run"
    why_not_now: "The new classifier and workflow run only after landing on main (D-28: never close #61 by hand)."
  - item: "Maintainer enables sha_pinning_required (read-only check today: false)"
    why_not_now: "D-15: only after the pins are on main. Repository setting change = maintainer action."
  - item: "The first grouped Dependabot PR may be red on the {action, major} runtime allowlist by design"
    why_not_now: "Expected behaviour (RESEARCH Pitfall 5); never loosen the allowlist to green it."
warnings:
  - id: WR-01
    finding: "Renamed Hex dependency (`hex:` option) would be tiered non-blocking: dat_closure stores deps.tree app names, dat_tier greps the SARIF Hex package name"
    impact: "Latent fail-open against SUP-03 / the goal's 'advisories that reach adopters block'. Not live: no root dep uses `hex:` and no root mix.lock entry has app != package (checked). No test covers it."
    recommendation: "Fix before landing (map app -> Hex package from mix.lock, or fail closed on a mismatch) plus a gate test that must exit 1."
  - id: WR-02
    finding: "Live closure test re-implements the bash parser; nested deps.tree glyph parsing is pinned only by the network self-test"
    impact: "A future regex drift in dat_closure could drop transitive runtime deps from the closure with the offline suite green."
  - id: WR-03
    finding: "D-29 doc contract checks RANK_NAMES is a subset of the documented classes, not equality"
    impact: "Doc drift only; no effect on the gate."
---

# Phase 245: Supply chain — Verification Report

**Phase Goal:** Security fixes arrive as PRs without routine version noise, every action reference is immutable, and only advisories that reach adopters block the release lane.
**Verified:** 2026-10-25
**Status:** passed (with 3 open review warnings; WR-01 is recommended for fixing before landing)
**Re-verification:** No. This is the initial verification.

**SUP-01 wording note:** Plan 245-01 reworded SUP-01 and roadmap SC1 per D-01. The new scope is actions-only, monthly, grouped Dependabot version updates with a 7-day cooldown. Hex is excluded because Dependabot does not serve Hex security updates; Hex coverage comes from SUP-03 and SUP-04. I judged SUP-01 against the reworded text in REQUIREMENTS.md line 18 and ROADMAP Phase 245 SC1. Under that reading, the goal clause "security fixes arrive as PRs" is met in two ways: for actions, one grouped PR a month; for Hex, the tiered gate and the deps-health issue, not PRs.

## Goal Achievement

### Observable Truths (roadmap success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `.github/dependabot.yml` keeps SHA-pinned actions current through one grouped monthly version-update PR with a 7-day cooldown, with no mix or npm entry, pinned by a contract test | VERIFIED | File read: `version: 2`, one `github-actions` entry, `directory: "/"`, `interval: monthly`, `cooldown.default-days: 7`, one group (`applies-to: version-updates`, `patterns: ["*"]`), `prefix: ci`, `include: scope`. No mix, npm, ignore, allow, target-branch or labels. `.github/dependabot.yaml` is absent. `dependabot_config_contract_test.exs` checks the live file. It derives the releasable set from release-please-config.json and has mutation controls for: a mix entry, a fix prefix, a target-branch, limit 0, an ignore rule, a composite outside `/`, empty derive sets, and a positive reorder control. All pass. |
| 2 | Every third-party `uses:` is a full commit SHA with a version comment, setup-node reads `.tool-versions`, and a contract test rejects a tag-only ref with a negative control | VERIFIED | A grep for any `uses:` line that does not match `@<40 hex> # vX.Y.Z` found 0 of 79. All 4 setup-node steps (ci.yml:684, 889, 1052; browser-full.yml:103) use `node-version-file: .tool-versions`, and none has `node-version:`. `.tool-versions` has `nodejs 22.14.0`. `ci_action_pin_contract_test.exs` has 20 mutation controls, starting with "tag-only checkout ref fires rule=PIN-FORM". Provenance check: `bin/verify-action-pins` (read-only gh) printed `8 pin(s) match their tags`, exit 0. |
| 3 | A test pins both audit tiers: a shipped runtime advisory fails required CI; a dev/test/bench/example-only advisory files or updates an issue and leaves the release lane green | VERIFIED (see WR-01) | `bin/deps-audit-tier` `dat_role`/`dat_closure`/`dat_tier` reads the `--only prod` closure, and the bench and example dirs are always non-blocking. `verify-deps-audit` is a `needs:` of `ci-required` (ci.yml:1213). The gate tests cover cases 1-11: a runtime advisory blocks with exit 1; dev-only ex_doc, bench benchee and example plug are non-blocking with exit 0 and `::warning::`; retirements are tiered the same way; D-19 ambiguous shapes fail closed. The live self-test against real Hex SARIF printed `ok (vulnerable lock red, ..., test-only advisory non-blocking)`. The live `mix verify.deps_audit` printed `3 lockfile(s) audit clean (Hex 2.6.0; 0 non-blocking finding(s))`. Non-blocking findings still raise the deps-health class to `advisory`, which opens or updates the `ci-deps` issue (deps_health_report_test "bench plug ... Non-blocking; class stays advisory"). |
| 4 | Scheduled deps-health opens or updates an issue for advisory, retirement or unknown, and closes only when clean; the classifier is tested | VERIFIED | `RANK_NAMES=(clean unknown retirement advisory)`. `rank_of` maps any unrecognised name to unknown. The classifier never invokes `hex.outdated`; the only mentions are in comments. deps-health.yml has a daily cron, push to main on exactly six lock/mix paths, and workflow_dispatch. Upsert runs on `!= 'clean'`, close on `== 'clean'`, and the fail step on `!= 'clean'` through `env:`. Concurrency is `deps-health` with `cancel-in-progress: false`. Permissions are `contents: read` plus `issues: write`, and the report step has GH_TOKEN for the pin check. `deps_health_report_test.exs` covers clean, retirement, advisory, missing SARIF, fetch failure, precedence, pin mismatch and tier sections. `upsert-ci-issue` retitles in update mode, covered by tests at lines 105 and 121. |

**Score:** 4/4 roadmap truths verified (0 present-but-behavior-unverified).

The plan-level must_haves from 245-01..05 were merged in. Each one I checked held in code or tests: the shared SARIF library and its fingerprint regex, the single EXIT trap, no retry-network wrapping, no `issues: write` on the gate job, unchanged cloak ignores, `release.yml` reading `RELEASE_SHA` via `env:` (line 394) and `process.env.RELEASE_SHA` (line 397), verify-action-pins only in deps-health (no ci.yml reference), the fake `VERIFY_ACTION_PINS_BIN` in offline tests, and the CONTRIBUTING D-06, D-07, D-15 and D-16 policy text (lines 660-773). The two 245-05 truths tagged `verification: backstop` concern GitHub-side Dependabot behaviour (a single grouped PR on re-scan, serialized runs). Presence of config cannot prove them. They can only be seen after the config is on main, which needs a maintainer push, so they are recorded under `landing_handoffs` and are not human verification items. This follows the project's zero-human-verification rule.

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `.github/dependabot.yml` | VERIFIED | Substantive and pinned by the contract test |
| `bin/deps-audit-tier` | VERIFIED | Sourced by both `verify-deps-audit` and `deps-health-report` |
| `bin/verify-deps-audit` | VERIFIED | Wired through `mix verify.deps_audit` and `--self-test` in the ci.yml `verify-deps-audit` job, which feeds `ci-required` |
| `bin/deps-health-report` | VERIFIED | Wired through the deps-health.yml report step |
| `bin/verify-action-pins` | VERIFIED | Called by deps-health-report through `VERIFY_ACTION_PINS_BIN`, and ran live (exit 0) |
| `bin/upsert-ci-issue` | VERIFIED | Upsert and close steps in deps-health.yml |
| Contract tests (8 files) | VERIFIED | 259 tests, 0 failures (re-run by verifier, seed 350303) |

### Key Link Verification

| From | To | Status |
|------|----|--------|
| deps-health-report / verify-deps-audit | deps-audit-tier | WIRED (sourced; both consumers' tests exercise it) |
| ci.yml verify-deps-audit | ci-required (alls-green) | WIRED (ci.yml:1213) |
| deps-health.yml | upsert-ci-issue | WIRED (`!= 'clean'` upsert, `== 'clean'` close) |
| deps-health-report | verify-action-pins | WIRED (a non-zero exit raises the class to unknown; tested) |
| ci_action_runtime_contract_test | `# vX.Y.Z` comments | WIRED ({action, major} key read from the comment) |
| dependabot contract | release-please-config.json and workflow `LABEL:` values | WIRED (derived; an empty derive set fails closed) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase contract suites | `mix test` on the 8 phase-245 test files | 259 tests, 0 failures | PASS |
| Pins equal their tags | `bin/verify-action-pins` | `8 pin(s) match their tags` | PASS |
| Live tiered gate | `mix verify.deps_audit` | `3 lockfile(s) audit clean (Hex 2.6.0; 0 non-blocking finding(s))` | PASS |
| Both tiers against real Hex | `bin/verify-deps-audit --self-test` | `ok (vulnerable lock red, old Hex red, global Hex ignore red, lock drift red, test-only advisory non-blocking)` | PASS |
| Lint | `mix verify.credo` | no issues | PASS |
| sha_pinning_required | `gh api repos/szTheory/threadline/actions/permissions` | `false` (expected per D-15) | PASS |

I did not re-run full `CI=true mix ci.all`, to protect the shared local postgres. The executor's 245-05 gate (exit 0 at 20d7bec0 on an ephemeral postgres:16) stands as the full-suite evidence, and my targeted re-runs agree with it.

### Probe Execution

No `scripts/*/tests/probe-*.sh` files are declared or present for this phase. The phase's runnable checks (`--self-test`, `verify-action-pins`) were run above.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| SUP-01 (reworded per D-01) | 245-01, 245-05 | SATISFIED | SC1 evidence above |
| SUP-02 | 245-03, 245-04, 245-05 | SATISFIED | SC2 evidence above |
| SUP-03 | 245-02, 245-05 | SATISFIED (latent WR-01 caveat) | SC3 evidence above |
| SUP-04 | 245-01, 245-04, 245-05 | SATISFIED | SC4 evidence above |

Every SUP-0x ID mapped to Phase 245 in REQUIREMENTS.md (lines 18-21, 59-62) is claimed by at least one plan. None is orphaned.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `bin/deps-audit-tier` `dat_closure`/`dat_tier` | App-name closure compared with a Hex-package-name finding (WR-01) | Warning | Latent fail-open for `hex:`-renamed runtime deps. Not reachable with today's root tree (no `hex:` option; every lock app equals its package). |
| `test/threadline/deps_audit_gate_test.exs` live closure test | Parser re-implemented in Elixir (WR-02) | Warning | Nested deps.tree parsing is not pinned offline |
| `test/threadline/deps_health_doc_contract_test.exs` | Subset check, not equality (WR-03) | Warning | Doc drift only |
| IN-01..IN-07 (review) | Minor robustness and doc accuracy | Info | None affects a must-have |

No TBD, FIXME or XXX debt markers appear in any non-planning file changed in the phase range.

### Human Verification Required

None. The post-landing observations are in `landing_handoffs` (frontmatter): they need a maintainer push or a settings change, and CLAUDE.md routes those to the maintainer, not to UAT.

### Gaps Summary

No blocking gaps. All four roadmap success criteria hold in the codebase and are backed by passing tests and live runs, not by SUMMARY claims. The most important open item is WR-01. The goal promises that only advisories reaching adopters block, and the converse must also hold: an advisory that does reach adopters must block. That converse fails silently for any future runtime dep declared with `hex: :other_name`. Nothing in the tree triggers this today, so it is a warning and not a failed truth. The fix is small and testable, so I recommend closing it (with a must-exit-1 gate test) before the phase lands.

---

_Verified: 2026-10-25_
_Verifier: Claude (gsd-verifier)_
