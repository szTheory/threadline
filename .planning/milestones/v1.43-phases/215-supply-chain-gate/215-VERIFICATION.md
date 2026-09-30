---
phase: 215-supply-chain-gate
verified: 2026-09-27T01:30:00Z
status: passed
score: 7/7 truths verified
covered_files: [".github/workflows/ci.yml", ".github/workflows/deps-health.yml", ".planning/REQUIREMENTS.md", ".planning/phases/215-supply-chain-gate/215-01-PLAN.md", ".planning/phases/215-supply-chain-gate/215-01-SUMMARY.md", ".planning/phases/215-supply-chain-gate/215-02-PLAN.md", ".planning/phases/215-supply-chain-gate/215-02-SUMMARY.md", ".planning/phases/215-supply-chain-gate/215-03-PLAN.md", ".planning/phases/215-supply-chain-gate/215-03-SUMMARY.md", ".planning/phases/215-supply-chain-gate/215-04-PLAN.md", ".planning/phases/215-supply-chain-gate/215-04-SUMMARY.md", ".planning/phases/215-supply-chain-gate/215-05-PLAN.md", ".planning/phases/215-supply-chain-gate/215-05-SUMMARY.md", ".planning/phases/215-supply-chain-gate/215-06-PLAN.md", ".planning/phases/215-supply-chain-gate/215-06-SUMMARY.md", ".planning/phases/215-supply-chain-gate/215-REVIEW.md", ".planning/phases/215-supply-chain-gate/deferred-items.md", "CHANGELOG.md", "CONTRIBUTING.md", "bench/mix.lock", "bin/deps-health-report", "bin/verify-deps-audit", "mix.exs", "mix.lock", "test/fixtures/deps_audit/vulnerable_lock/mix.exs", "test/fixtures/deps_audit/vulnerable_lock/mix.lock", "test/threadline/deps_audit_contract_test.exs", "test/threadline/deps_audit_gate_test.exs", "test/threadline/deps_health_doc_contract_test.exs", "test/threadline/deps_health_report_test.exs", "test/threadline/ignore_advisories_contract_test.exs"]
covered_digest: "v1:sha256:17dc6fce7f6394bbce6f89fc38e62c34be0b46ec1e07c31015ba2bc0a1d66976"
overrides_applied: 0
behavior_unverified: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/7
  gaps_closed:
    - "CR-01: bin/verify-deps-audit and bin/deps-health-report now refuse a non-empty global Hex ignore_advisories/ignore_retirements (read via `mix hex.config <key>` from a neutral, mix.exs-free tmp dir), fail closed on unreadable/unparseable/non-zero output, and this is proven by 8 new offline gate tests, 6+ new offline report tests, a real-Hex self-test case (c) in bin/verify-deps-audit, and this verifier's own independent re-run of the exact CR-01 repro command against both scripts."
    - "WR-02: both scripts now fetch with `mix deps.get --check-locked`, so a mix.lock that no longer matches mix.exs fails that directory's audit instead of being silently re-resolved; proven by offline drift tests, self-test case (d) with a byte-identical-lock check, and this verifier's own independent scratch-project reproduction (gate exits 1, `--check-locked` named, lock byte-identical afterwards)."
  gaps_remaining: []
  regressions: []
deferred: []
advisory: []
---

# Phase 215: Supply Chain Gate Verification Report

**Phase Goal:** No lockfile in the repo carries a known advisory, and CI stops any PR that would introduce one, without a Dependabot PR flood
**Verified:** 2026-09-27T01:30:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (plans 215-05, 215-06; prior gaps_found report at git commit `0812bddb`)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix hex.audit` exits 0 for root, `bench`, `examples/threadline_phoenix`; no mix.exs constraint change since prior verification | ✓ VERIFIED | `git diff 0812bddb -- '*.lock' mix.exs bench/mix.exs examples/threadline_phoenix/mix.exs .github/` is empty — no lockfile, mix.exs constraint, or workflow file has changed since the prior gaps_found verification. `mix verify.deps_audit` (live re-run) → `3 lockfile(s) audit clean (Hex 2.5.1)`. |
| 2 | A releasable `fix(deps):` commit carries a CHANGELOG line for the mint advisory | ✓ VERIFIED (regression check) | Unchanged since prior verification (no diff on CHANGELOG.md's Security section per the empty diff above; carried forward). |
| 3 | `mix verify.deps_audit` runs the unused-lock check + `hex.audit` over all three lockfiles, asserts Hex >= 2.5.1, and is wired into a required `verify-deps-audit` CI job | ✓ VERIFIED | Live re-run: `mix verify.deps_audit` → exit 0, `3 lockfile(s) audit clean (Hex 2.5.1)`. `.github/workflows/ci.yml` unchanged since prior verification (empty diff above) — job still has no `if:`/`continue-on-error`, still in `ci-required`'s `needs:`. |
| 4 | A negative fixture test proves the gate exits non-zero on a known-vulnerable lock and on an old Hex | ✓ VERIFIED | Live re-run: `bin/verify-deps-audit --self-test` → `verify-deps-audit self-test: ok (vulnerable lock red, old Hex red, global Hex ignore red, lock drift red)`, exit 0. Two new real-Hex cases (c) and (d) now included per plan 215-05. |
| 5 | A test fails when a `hex: [ignore_advisories: ...]` entry lacks a reason, reachability claim, or unexpired review-by date | ✓ VERIFIED | `mix test test/threadline/ignore_advisories_contract_test.exs` passes as part of the 86-test combined run below (0 failures). Moduledoc corrected per 215-05 to no longer overclaim scope (verified: `grep -c 'sees exactly the ids Hex itself uses' test/threadline/ignore_advisories_contract_test.exs` = 0; the client-config surface is now named as guarded by `bin/verify-deps-audit`'s runtime refusal instead). |
| 6 | A weekly, non-required `deps-health.yml` runs `hex.audit`+`hex.outdated` over all three lockfiles and upserts a single `ci-deps`-labelled issue; CONTRIBUTING states the batched freshness policy, no Dependabot | ✓ VERIFIED | `.github/workflows/deps-health.yml` and `bin/upsert-ci-issue` unchanged since prior verification (`git diff 0812bddb -- .github/workflows/deps-health.yml bin/upsert-ci-issue` empty). CONTRIBUTING.md's freshness-policy section now additionally states the `--check-locked` and global-suppression-classifies-`unknown` rules (215-06). `mix test test/threadline/deps_health_doc_contract_test.exs test/threadline/deps_health_report_test.exs` pass as part of the 86-test run below. |
| 7 | CI stops any PR that would introduce a known advisory, AND the committed lock is what actually gets audited (the phase goal's accountability invariant; previously FAILED as CR-01/WR-02) | ✓ VERIFIED | Both gaps independently re-reproduced by this verifier and confirmed CLOSED — see "Independent Re-Reproduction" below. |

**Score:** 7/7 truths verified (up from 6/7 in the prior gaps_found report)

### Independent Re-Reproduction of the Prior Gaps (CR-01, WR-02)

This verifier reran the exact prior gaps_found reproductions independently, in scratch directories under `/Users/<user>/.claude/jobs/77cf1bdd/tmp/` (deleted after use; the repo's own `tmp/` was also confirmed empty afterwards and is gitignored).

**CR-01 — CONFIRMED CLOSED, both scripts:**

```
cp test/fixtures/deps_audit/vulnerable_lock/{mix.exs,mix.lock} $T/
(cd tmp && HEX_HOME=$T/h mix hex.config ignore_advisories \
  'EEF-CVE-2026-54892,EEF-CVE-2026-8468,EEF-CVE-2026-56813,EEF-CVE-2026-56814')
  => confirmed the fixture's 4-advisory-id global ignore is set and wraps
     across two output lines when queried back (real multi-line Hex answer,
     the exact shape 215-05's SUMMARY reports fixing the parser for)

HEX_HOME=$T/h bin/verify-deps-audit $T
  => exit 2, "verify-deps-audit: global Hex config sets ignore_advisories to
     [...] ... Suppressing a hex.audit finding through Hex client config is
     not accountable. Remove it (mix hex.config ignore_advisories --delete)..."
  => NO "audit clean" anywhere in the output — the gate never reached hex.audit

HEX_HOME=$T/h bin/deps-health-report $T/out
  => classification=unknown
  => report.md: "**Hex advisory suppression is active — no audit was
     trusted:** global Hex config sets ignore_advisories to [...] ..."
  => every per-dir section reads "skipped (Hex advisory suppression active)"
```

Both the required per-PR gate and the weekly informational lane now refuse the global Hex config bypass before any audit call, matching the plan's `must_haves.truths` for both 215-05 and 215-06.

**WR-02 — CONFIRMED CLOSED, `bin/verify-deps-audit` (the script the reproduction targets — it is the one that accepts an arbitrary target directory; `bin/deps-health-report` always audits the fixed canonical dirs and has no such argument, so its WR-02 fix was instead independently confirmed via its own offline test suite, see below):**

```
cp test/fixtures/deps_audit/vulnerable_lock/{mix.exs,mix.lock} $T/
# edited mix.exs: {:plug, "== 1.19.1"} -> {:plug, "~> 1.19.2"}  (a genuine,
# independently-produced drift, not reused from any fixture in the repo)

HEX_IGNORE_ADVISORIES= HEX_IGNORE_RETIREMENTS= bin/verify-deps-audit $T
  => Resolution completed; plug 1.19.1 => 1.19.5 (real Hex resolution ran)
  => "** (Mix) Your mix.lock is out of date and must be updated without the
     --check-locked flag"
  => "FAIL $T: deps.get --check-locked exited 1 (the committed mix.lock
     must match mix.exs; this gate audits the committed lock, never a
     re-resolved one — re-lock locally and commit mix.lock)"
  => exit 1

cmp $T/mix.lock $T/mix.lock.before => IDENTICAL (byte-for-byte)
```

The gate refuses the drifted directory and the committed lock is left untouched, even though Hex's resolver was willing to silently upgrade it. For `bin/deps-health-report`, this verifier ran its own offline `mix test` proof directly (`test committed lock (WR-02) a drifted lock in bench -> unknown, bench's audit/outdated skipped, root and example still run hex.audit` and `... every fetch on a default run carries --check-locked`) — both pass, 0 failures, confirming the same `--check-locked` mechanism and per-dir skip/aggregation behavior 215-06's plan specifies.

### Regression Check (Truths 1-6, no scope drift)

- `git diff 0812bddb -- '*.lock' mix.exs bench/mix.exs examples/threadline_phoenix/mix.exs .github/` — **empty**. No lockfile, mix.exs dependency constraint, or workflow file has changed since the prior gaps_found verification; all changes are confined to `bin/verify-deps-audit`, `bin/deps-health-report`, their test files, CONTRIBUTING.md, and `.planning/phases/215-supply-chain-gate/deferred-items.md`/REVIEW.md, exactly as both gap-closure plans' `<prohibitions>` require.
- No workflow job id, `if:`, `continue-on-error`, or `ci-required` `needs:` entry changed.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bin/verify-deps-audit` | Per-PR gate script, now closing CR-01/WR-02 | ✓ VERIFIED — `refuse_global_hex_ignores` (before the per-dir loop, after the Hex floor), `deps.get --check-locked`; live-clean, live-self-test (4 cases), independently re-reproduced by this verifier |
| `bin/deps-health-report` | Weekly report script, now closing CR-01/WR-02 | ✓ VERIFIED — `SUPPRESSION_REASON` check (before the loop), `deps.get --check-locked`; independently re-reproduced (CR-01) and offline-test-confirmed (WR-02) by this verifier |
| `test/threadline/deps_audit_gate_test.exs` | Offline gate tests, extended for CR-01/WR-02 | ✓ VERIFIED — passes as part of the 86-test combined run |
| `test/threadline/deps_audit_contract_test.exs` | Workflow contract, extended to `forbidden_hex_surface/1` | ✓ VERIFIED — `grep -rlE 'HEX_HOME\|MIX_HOME\|hex\.config[[:space:]]+ignore_\|HEX_IGNORE_(ADVISORIES\|RETIREMENTS)' .github/workflows/` returns nothing; test passes |
| `test/threadline/ignore_advisories_contract_test.exs` | Corrected moduledoc scope | ✓ VERIFIED — overclaim removed, passes |
| `test/threadline/deps_health_report_test.exs` | Weekly report tests, extended for CR-01/WR-02 | ✓ VERIFIED — passes |
| `test/threadline/deps_health_doc_contract_test.exs` | CONTRIBUTING doc contract | ✓ VERIFIED — passes |
| `CONTRIBUTING.md` | States both new gate rules for both lanes | ✓ VERIFIED — `awk '/^## Dependency freshness policy/{f=1} f' CONTRIBUTING.md \| grep -c check-locked` = 2 (gate + weekly-lane sentences) |
| `.planning/phases/215-supply-chain-gate/deferred-items.md` | Every non-promoted review finding tracked | ✓ VERIFIED — 11 WR/IN entries + MIX_EXS/MIX_HOME observation + preserved pre-existing bench entry, each with a status |
| `.github/workflows/ci.yml` / `deps-health.yml` | Required / weekly jobs, untouched by gap closure | ✓ VERIFIED — no diff since `0812bddb` |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| `bin/verify-deps-audit` `refuse_global_hex_ignores` | Hex's actual effective global config | `mix hex.config <key>` from a neutral, mix.exs-free `$ROOT/tmp/...` dir, before the per-dir loop | ✓ WIRED — independently re-reproduced, exits non-zero, no `audit clean` |
| `bin/verify-deps-audit` per-dir fetch | committed `mix.lock` | `deps.get --check-locked` | ✓ WIRED — independently re-reproduced, exits 1 on drift, lock byte-identical afterwards |
| `bin/deps-health-report` `SUPPRESSION_REASON` check | Hex's effective global config + env vars | same mechanism, before the loop | ✓ WIRED — independently re-reproduced, classifies `unknown`, names the reason |
| `bin/deps-health-report` per-dir fetch | committed `mix.lock` | `deps.get --check-locked` | ✓ WIRED — offline test-confirmed (drift in 1 of 3 dirs classifies `unknown` for that dir only; aggregation preserved) |
| `test/threadline/deps_audit_contract_test.exs` `forbidden_hex_surface/1` | every `.github/workflows/*.yml` | live scan for `HEX_HOME`/`MIX_HOME`/`hex.config ignore_`/`HEX_IGNORE_*` | ✓ WIRED — non-vacuous (proven on synthetic positive/negative), zero hits on real workflows |
| Two scripts' suppression checks | each other (cannot silently diverge) | drift-guard test asserting the literal key-order string in both files | ✓ WIRED — test passes; **however see WR-215-09/WR-215-10 in Advisory below: no *behavioral* real-Hex proof anchors the weekly-lane copy independently of the gate's self-test** |

### Behavioral Spot-Checks / Re-run Evidence

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Gate clean on real tree | `mix verify.deps_audit` | "3 lockfile(s) audit clean (Hex 2.5.1)", exit 0 | ✓ PASS |
| Gate self-test (4 cases against real Hex) | `bin/verify-deps-audit --self-test` | "ok (vulnerable lock red, old Hex red, global Hex ignore red, lock drift red)", exit 0 | ✓ PASS |
| CR-01 re-repro, required gate | `HEX_HOME=<scratch> bin/verify-deps-audit <scratch vulnerable-lock copy>` | exit 2, refusal names `ignore_advisories`, no `audit clean` | ✓ PASS (gap closed) |
| CR-01 re-repro, weekly lane | `HEX_HOME=<same scratch> bin/deps-health-report <out>` | `classification=unknown`, report names the reason, all dirs `skipped` | ✓ PASS (gap closed) |
| WR-02 re-repro, required gate | scratch fixture copy with drifted `mix.exs`; `bin/verify-deps-audit <scratch>` | exit 1, names `--check-locked`, `cmp` shows lock byte-identical | ✓ PASS (gap closed) |
| WR-02, weekly lane (offline, since the script takes no target-dir argument) | `mix test test/threadline/deps_health_report_test.exs` (drift + check-locked tests) | both tests pass | ✓ PASS (gap closed) |
| Targeted phase test files | `mix test test/threadline/deps_audit_gate_test.exs test/threadline/deps_audit_contract_test.exs test/threadline/ignore_advisories_contract_test.exs test/threadline/deps_health_report_test.exs test/threadline/deps_health_doc_contract_test.exs` | 86 tests, 0 failures | ✓ PASS |
| Full regression suite | `mix test` | "9 properties, 2293 tests, 0 failures, 2 excluded" | ✓ PASS |
| Format / compile | `mix format --check-formatted && mix compile --warnings-as-errors` | clean, no output | ✓ PASS |
| No lockfile/constraint/workflow drift since prior verification | `git diff 0812bddb -- '*.lock' mix.exs bench/mix.exs examples/threadline_phoenix/mix.exs .github/` | empty | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| SUP-01 | 215-01 | `mix hex.audit` clean for all three lockfiles, lock-only fix, CHANGELOG entry | ✓ SATISFIED | Unchanged, re-confirmed clean (Truths 1-2) |
| SUP-02 | 215-02, 215-05, 215-06 | CI fails a PR introducing an advisory via `verify-deps-audit` job, with no bypass | ✓ SATISFIED | Job exists, required, and its accountability guarantee now holds against both the env-var and global-config suppression surfaces and against a re-resolved/drifted lock (Truths 3-4, 7; both prior gaps independently re-reproduced as closed) |
| SUP-03 | 215-03, 215-04, 215-05, 215-06 | `hex_audit_ignores/0` accountability convention, enforced live+synthetic, and now the sole legitimate suppression path | ✓ SATISFIED | Convention/test still pass (Truth 5); the global Hex config bypass that previously defeated this invariant (CR-01) is now refused in both lanes, closing the accountability gap the prior verification found |
| SUP-04 | 215-04, 215-06 | Weekly non-required deps-health lane + CONTRIBUTING freshness policy, now also closing CR-01/WR-02 in that lane | ✓ SATISFIED | Truth 6; the lane can no longer report `clean`/`outdated` under an active suppression or a re-resolved lock |

No orphaned requirements: REQUIREMENTS.md maps exactly SUP-01..04 to Phase 215, all four appear in plan frontmatter (215-01..06).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| No `TBD`/`FIXME`/`XXX` markers found in phase-modified files | — | — | — | Debt-marker gate: clean |
| (see Advisory below) `bin/deps-health-report` | ~124-209 | CR-01 mirror logic proven only via offline fake `mix`, not a real-Hex self-test of its own (WR-215-09, from 215-REVIEW.md) | ⚠️ Warning | Non-blocking — weekly lane is informational/non-required; the required gate's own real-Hex self-test remains the load-bearing proof; recorded, not promoted |
| (see Advisory below) `bin/verify-deps-audit` / `bin/deps-health-report` | duplicated ~45-line function | Duplicated Hex-config-parsing logic invites future drift between the two scripts (WR-215-10) | ⚠️ Warning | Non-blocking — a drift-guard test asserts the key-literal string is present in both files today; does not assert semantic equivalence |

No unreferenced `TBD`/`FIXME`/`XXX` markers found in any file this phase modified.

### Advisory (New Findings from 215-REVIEW.md's Incremental Pass)

The gap-closure incremental review (`215-REVIEW.md`, 0 critical / 2 warning / 2 info) raised four new findings not present in the original phase review. None of them let a vulnerable committed lockfile pass the required gate — all are maintainability/robustness observations on the fix itself:

| # | Finding | Category | Why not a gap |
|---|---------|----------|----------------|
| 1 | WR-215-09: `bin/deps-health-report`'s CR-01 mirror has no live proof against real Hex (only offline fake-`mix` tests; the required gate's `--self-test` case (c) is the only real-Hex anchor) | maintainability | The weekly lane is explicitly non-required/informational (SC4); this verifier independently re-ran the CR-01 repro against `bin/deps-health-report` live (against real Hex, not a fake) and it correctly classified `unknown` — so the mirror does work against real Hex today, even without a dedicated `--self-test` mode of its own |
| 2 | WR-215-10: ~45-line `read_global_hex_ignore` duplicated verbatim across both scripts, inviting silent divergence on a future edit | maintainability | A drift-guard test exists (key-literal string in both files) but only checks a substring, not semantic equivalence — a real but non-blocking future-maintenance risk, not a present defect |
| 3 | IN-215-05: a hypothetical future Hex client emitting a bracket-led warning line could cause a false-positive refusal (fails in the safe direction — blocks a green run, not a bypass) | robustness | Fails closed/safe by construction; not exploitable to pass a vulnerable lock |
| 4 | IN-215-06: self-test case (d)'s drift-by-string-substitution could silently no-op against a future fixture edit | test fragility | Reviewer confirmed it is not live today (reran self-test successfully); would only degrade a future test's teeth, not today's gate |

None of these are promoted to gaps. They are the kind of finding this verifier would flag as advisory even outside re-verification mode, since they concern the gap-closure delta itself; recording them here for visibility rather than silently dropping them.

### Human Verification Required

None. Every truth was checked with a live re-run command, direct code inspection, or an independent scratch-directory reproduction of both prior gaps against real Hex; nothing here requires visual, real-time, or external-service judgment beyond what has already been covered.

### Gaps Summary

None. Both truths that failed in the prior verification (`0812bddb`) — CR-01 (global Hex `ignore_advisories`/`ignore_retirements` bypass) and WR-02 (silent re-resolution of a drifted `mix.lock`) — are independently confirmed closed by this verifier in both the required per-PR gate (`bin/verify-deps-audit`) and the weekly informational lane (`bin/deps-health-report`), using fresh scratch-directory reproductions of the exact commands the prior verification used (not merely re-reading the SUMMARY's claims). No lockfile, `mix.exs` dependency constraint, or workflow file has changed since the prior verification. The full test suite is green at 2293 tests / 0 failures (up from the prior 2270-test baseline), `mix format --check-formatted` and `mix compile --warnings-as-errors` are clean, and the working tree was left exactly as found (no leftover scratch directories, no lockfile diffs).

The phase goal — "No lockfile in the repo carries a known advisory, and CI stops any PR that would introduce one, without a Dependabot PR flood" — is achieved: the lockfiles are genuinely advisory-clean, the required CI job is wired and now closes both the accountable-suppression bypass and the re-resolved-lock bypass the prior verification found, the weekly lane matches the same guarantees without being required, and no Dependabot version-update PRs exist.

---

_Verified: 2026-09-27T01:30:00Z_
_Verifier: Claude (gsd-verifier)_
