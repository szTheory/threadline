---
phase: 217-repo-hygiene
verified: 2026-09-27T21:30:00Z
status: passed
score: 5/5 must-haves verified
covered_files: [".github/repo-hygiene-allowlist.tsv", ".github/workflows/ci.yml", ".planning/MILESTONE-GUIDE.txt", ".planning/phases/217-repo-hygiene/217-01-PLAN.md", ".planning/phases/217-repo-hygiene/217-01-SUMMARY.md", ".planning/phases/217-repo-hygiene/217-02-PLAN.md", ".planning/phases/217-repo-hygiene/217-02-SUMMARY.md", ".planning/phases/217-repo-hygiene/217-03-PLAN.md", ".planning/phases/217-repo-hygiene/217-03-SUMMARY.md", ".planning/phases/217-repo-hygiene/217-04-PLAN.md", ".planning/phases/217-repo-hygiene/217-04-SUMMARY.md", ".planning/phases/217-repo-hygiene/217-05-PLAN.md", ".planning/phases/217-repo-hygiene/217-05-SUMMARY.md", ".planning/phases/217-repo-hygiene/217-06-PLAN.md", ".planning/phases/217-repo-hygiene/217-06-SUMMARY.md", ".planning/phases/217-repo-hygiene/217-07-PLAN.md", ".planning/phases/217-repo-hygiene/217-07-SUMMARY.md", ".planning/phases/217-repo-hygiene/217-PATTERNS.md", ".planning/phases/217-repo-hygiene/217-RESEARCH.md", ".planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md", ".planning/phases/217-repo-hygiene/217-REVIEW.md", ".planning/phases/217-repo-hygiene/217-VALIDATION.md", "CONTRIBUTING.md", "bin/verify-playwright-fail-fast", "bin/verify-repo-hygiene", "bin/verify-temp-leaks", "mix.exs", "test/threadline/branch_protection_comparison_contract_test.exs", "test/threadline/capture/trigger_migrate_time_errors_test.exs", "test/threadline/capture/trigger_pk_override_test.exs", "test/threadline/ci_attestation_contract_test.exs", "test/threadline/e2e_preflight_contract_test.exs", "test/threadline/getting_started_fixtures_test.exs", "test/threadline/operator_surface/exports_mix_parity_test.exs", "test/threadline/operator_surface/refute_partition_test.exs", "test/threadline/repo_hygiene_contract_test.exs", "test/threadline/repo_hygiene_guard_test.exs", "test/threadline/temp_leak_check_test.exs"]
covered_digest: "v2:sha256:a65b6c322c343fe1ca591c7322d9d1cc2dccdd16812c8e46adfaf1cd5b356eab"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "Family-6 (Claude-encoded project dir) false negative on a single-segment token (CR-01): fixed in 09817a77, reproduced green in scratch fixtures"
    - "Guard green on HEAD, with a durable planning-prose placeholder convention (CONTRIBUTING section, contract test, stderr hint) instead of an exemption: 16edbbd5"
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
advisory:
  - finding: "R2-WR-04: a Linux-encoded Claude project dir name (dash, the Linux home word, dash, <user>, dash, <project>) is not matched by any family, and CONTRIBUTING's new section claims every Claude-encoded project path is a HIT"
    category: other
    reason: "Reproduced in a scratch fixture (exit 0). Pre-existing: family 6 was specified macOS/Windows-only in 217-01. Criterion 2 does not enumerate shapes and the full Linux home form is still caught by family 2. Resolve by adding an anchored Linux variant or narrowing the CONTRIBUTING sentence."
    evidence_status: "reproduced; public-doc overclaim, not a success-criterion failure"
  - finding: "R2-WR-02: widened family-6 regex has no left boundary, so a TitleCase kebab word with the macOS home word in the middle is a HIT"
    category: other
    reason: "Reproduced (exit 1). Fails closed (false positive, not a missed leak); no such text in the tree today. Anchor at a path boundary."
    evidence_status: "reproduced; noise risk only"
  - finding: "R2-WR-01: the allowlist safety net and the script's structural validation accept an ancestor-prefix literal (bare slash, bare macOS home root) that would blanket-cover home paths"
    category: security
    reason: "Hypothetical: the current allowlist holds only runner, cache and tool-install literals, unchanged since faa9c1d9. Hardening for future edits."
    evidence_status: "code reading plus reviewer's scratch fixture; no live violation"
  - finding: "R2-WR-03: a tracked filename containing a newline mis-scopes a hit"
    category: other
    reason: "Zero tracked filenames contain a newline (git ls-files -z check). The header comment overclaims."
    evidence_status: "no live instance"
  - finding: "R2-IN-01 / R2-IN-02: hint contract test is near-vacuous (behavioral test covers it); CONTRIBUTING 'no file is exempt' ignores the allowlist's own literal column"
    category: other
    reason: "Info-level wording and test-strength items."
    evidence_status: "code reading"
human_verification: []
---

# Phase 217: Repo Hygiene Verification Report

**Phase Goal:** The public tree carries no machine-local paths and CI keeps it that way; leaking temp-dir tests are cleaned up; the xref disposition is on record
**Verified:** 2026-09-27T21:30:00Z
**Status:** passed
**Re-verification:** Yes, after gap closure plans 217-06 and 217-07

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 / HYG-01: no tracked file carries an absolute or home-relative machine-local path; the scrub was prefix-only, no history rewrite | ✓ VERIFIED (regression) | `bin/verify-repo-hygiene` exit 0, `3962 tracked text file(s) clean; 8 allowlist entries used, 0 inert`. A case-insensitive whole-word `git grep` for the current account name lists 0 files. The scrub commits are unchanged ordinary forward commits. |
| 2 | SC2 / HYG-02: `bin/` guard, `verify.*` alias in `ci.all`, `verify-repo-hygiene` job in `ci-required`; scans tracked text only; runner/cache allowlist; fails on an unused entry; runtime-built negative fixtures prove red; no real username anywhere | ✓ VERIFIED (previous gap 1 closed) | Family 6 is now `(-<Users>-[A-Za-z0-9._]+)` with no mandatory trailing dash (`bin/verify-repo-hygiene:280`). My own scratch repos, with tokens built at runtime: single segment at end of line gives exit 1 + HIT; single segment followed by `/bar` gives exit 1 + HIT; multi-segment gives exit 1; the placeholder `-Users-<user>-<project>` gives exit 0. `--self-test` prints `ok (6 cases)`. The focused tests `mix test test/threadline/repo_hygiene_guard_test.exs test/threadline/repo_hygiene_contract_test.exs` give **57 tests, 0 failures**. The 217-06 SUMMARY records the red-before-green result (40 tests, 2 failures on the old regex). Wiring: `mix.exs:179,214,256`; `ci.yml:961-980` job, `:1013` in `ci-required` needs. |
| 3 | SC3 / HYG-03: leaking tests use `@tag :tmp_dir`, the out-of-repo test keeps the system temp dir, tree walkers ignore `tmp/`, and a full `mix test` leaves no temp entries | ✓ VERIFIED (regression) | Gap closure touched none of these files (`git diff --stat b4f600b9 HEAD`). All 6 migrated files still have `:tmp_dir` and 0 `System.tmp_dir!` calls. Initial verification ran `bin/verify-temp-leaks` with 0 leftovers. The orchestrator's full `mix test` on HEAD gave 2380 tests, 0 failures. |
| 4 | SC4 / HYG-04: MILESTONE-GUIDE §9a names `compile-connected`, `verify.xref_cycles` is unchanged, there is no runtime-cycle gate, and the AuditTransaction<->AuditAction edge is logged for v1.45 | ✓ VERIFIED (regression) | `mix verify.xref_cycles` prints `No cycles found`. `.planning/MILESTONE-GUIDE.txt:311,314` still carries the label and the edge. |
| 5 | The guard's own gate is green on HEAD, and planning prose has a durable way to describe path shapes without tripping it (no exemption, no allowlist widening) | ✓ VERIFIED (previous gap 2 closed) | The guard exits 0 on HEAD, including the round-2 `217-REVIEW.md`, which uses the placeholder form. CONTRIBUTING.md:88 has `## Writing about machine-local paths` with 9 marker-delimited forms. The contract test runs the real guard: the forms are clean and their concretized twins HIT (non-vacuity). An uncovered HIT prints a stderr hint naming the section; I observed it in scratch runs. The allowlist is unchanged since `faa9c1d9` (empty diff), and the only `exclude` pathspec is the allowlist file itself (pre-existing). |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Gap-closure plan must-haves (217-06, 217-07)

| Must-have | Status | Evidence |
|-----------|--------|----------|
| Single-segment family-6 token HITs; multi-segment still HITs; placeholder clean | ✓ | Scratch fixtures above plus guard tests |
| New test red on the old regex, green on the new | ✓ | 217-06 SUMMARY RED record; the test file is green now |
| Self-test case (f), `ok (6 cases)` | ✓ | Ran it |
| `(.planning/ absent)` label only when nothing under `.planning/` is tracked (WR-01) | ✓ | The real-tree summary has no suffix; the scratch repo prints the suffix |
| The allowlist safety net covers all home-prefix families, with a control (R1-WR-03) | ✓ | Guard tests green; mutation control recorded in the SUMMARY |
| Missing git gives exit 2 `git not found on PATH` (IN-01) | ✓ | `command -v git` check present; test green |
| Colon filenames are scanned and scoped by full path (R1-WR-02) | ✓ | Two tests green; 2 tracked colon filenames exist and the tree scan is clean |
| Every round-1 finding has a non-`open` disposition | ✓ | `217-REVIEW-DISPOSITION.md`: R1-CR-01, R1-WR-01..03 and R1-IN-01 are `fixed`, with commits |
| Prohibitions: no allowlist widening, no `.planning/` exemption, no suppression marker, no real username/path | ✓ (checked) | Allowlist diff empty; no new exclude; username grep 0; guard green |

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `bin/verify-repo-hygiene` | ✓ VERIFIED | Widened family 6, conditional label, git check, SOH record parsing, stderr hint; self-test 6 cases |
| `test/threadline/repo_hygiene_guard_test.exs` | ✓ VERIFIED | Runtime-built fixtures; part of the 57 green tests |
| `test/threadline/repo_hygiene_contract_test.exs` | ✓ VERIFIED | Placeholder doc contract with non-vacuity control |
| `CONTRIBUTING.md` section | ✓ VERIFIED | Present before `## Pull requests` (see advisory R2-WR-04 on one sentence's scope) |
| `.github/repo-hygiene-allowlist.tsv` | ✓ VERIFIED | 8 entries, all runner/cache/tool-install, unchanged |
| `217-REVIEW-DISPOSITION.md` | ✓ VERIFIED | Round 1 all fixed; round 2 recorded `open` (see advisory) |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `mix.exs` `verify.repo_hygiene` (in `ci.all`) | `bin/verify-repo-hygiene` | `Mix.shell().cmd` | ✓ WIRED |
| `ci.yml` `ci-required` | `verify-repo-hygiene` job | `needs:` | ✓ WIRED |
| Guard failure output | CONTRIBUTING heading | stderr hint, pinned by contract test | ✓ WIRED (observed live) |
| Contract test | CONTRIBUTING placeholder list | marker extraction plus real guard run | ✓ WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Real tree clean | `bin/verify-repo-hygiene` | exit 0, 3962 files, 8 used, 0 inert | ✓ PASS |
| Self-test | `bin/verify-repo-hygiene --self-test` | `ok (6 cases)` | ✓ PASS |
| Focused suites | `mix test` on guard and contract tests | 57 tests, 0 failures | ✓ PASS |
| CR-01 single segment, end of line / before slash | scratch repo, header-only allowlist | exit 1, HIT a.md:1 (both) | ✓ PASS |
| Placeholder form stays clean | scratch repo | exit 0 | ✓ PASS |
| Hint printed on HIT | scratch repo stderr | names "Writing about machine-local paths" | ✓ PASS |
| Linux-encoded project dir (R2-WR-04) | scratch repo | exit 0 (not detected) | advisory |
| TitleCase kebab with home word (R2-WR-02) | scratch repo | exit 1 (false positive) | advisory |
| xref disposition gate | `mix verify.xref_cycles` | `No cycles found` | ✓ PASS |
| No username in tree | whole-word `git grep` | 0 files | ✓ PASS |

### Probe Execution

Step 7c: no `scripts/*/tests/probe-*.sh` is declared by this phase; the guard's `--self-test` serves that role and passed.

### Requirements Coverage

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| HYG-01 | 217-04, 217-07 | ✓ SATISFIED | Tree clean; username grep 0 |
| HYG-02 | 217-01, 217-05, 217-06, 217-07 | ✓ SATISFIED | Guard, alias, job and roster wired; CR-01 closed; negative tests green |
| HYG-03 | 217-02 | ✓ SATISFIED | Unchanged since initial verification; full suite green |
| HYG-04 | 217-03 | ✓ SATISFIED | Unchanged; xref gate green |

No orphaned requirements. REQUIREMENTS.md maps exactly HYG-01..04 to Phase 217, and all four are claimed by plans.

### Anti-Patterns Found

No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK` in the gap-closure files (`bin/verify-repo-hygiene`, both repo-hygiene test files, `CONTRIBUTING.md`). The only matches are `mktemp` `XXXXXX` templates.

### Round-2 review findings, weighed against the success criteria

| Finding | Reproduced? | Verdict |
|---------|-------------|---------|
| R2-WR-01 ancestor-prefix allowlist literal | Not live: the current allowlist has no such literal | Hardening. SC2's "allowlists runner/cache paths" holds for the shipped allowlist. Advisory. |
| R2-WR-02 TitleCase kebab false positive | Yes, exit 1 | Fails closed, so it cannot let a leak through. It adds noise risk only, and no such text exists today. Advisory. |
| R2-WR-03 newline filenames | 0 such tracked files | Theoretical. Advisory. |
| R2-WR-04 Linux-encoded Claude dir undetected | Yes, exit 0 | The strongest of the four. It is a real false negative for one shape, but it was never in the guard's specified family set (217-01 defined family 6 as macOS/Windows-encoded). SC2 does not enumerate shapes, and the unencoded Linux home form is caught by family 2. Not scored as a gap; unlike CR-01, the guard never claimed this shape. However, CONTRIBUTING.md:90-93 now publicly claims any Claude-encoded project path is a HIT, which is inaccurate. Recommend a one-line follow-up: an anchored Linux variant, or narrow the sentence. |
| R2-IN-01, R2-IN-02 | Code reading | Info. |

## Gaps Summary

Both previous gaps are closed, confirmed by my own runs rather than the SUMMARYs.

1. **CR-01 is fixed.** Scratch fixture repos with runtime-built tokens show that the single-segment Claude-encoded token now HITs, at end of line and before a slash. The multi-segment form still HITs, and the placeholder form stays clean. The regression is pinned by two guard tests (recorded red on the old regex) and self-test case (f).
2. **The guard is green on HEAD, and the prose fix is durable.** The fix is a placeholder convention with a contract test and a failure-time hint, not an exemption or allowlist widening. The round-2 review report itself passes the guard.

The regression checks on SC1, SC3 and SC4 are clean, and no gap-closure commit touched their files.

The six round-2 review findings stay `open` in the disposition ledger. None breaks a success criterion as written, so they are recorded as advisory, not gaps. The one worth acting on soon is R2-WR-04: CONTRIBUTING overclaims coverage of Linux-encoded Claude project dirs. Before the milestone closes, either add the anchored Linux family (together with the R2-WR-02 left boundary) or set a `deferred`/`skipped` disposition with a reason.

---

_Verified: 2026-09-27T21:30:00Z_
_Verifier: Claude (gsd-verifier)_
