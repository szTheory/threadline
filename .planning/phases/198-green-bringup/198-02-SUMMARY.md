---
phase: 198-green-bringup
plan: 02
subsystem: infra
tags: [gitleaks, trufflehog, secret-scanning, credential-audit, git-history, push-protection]

# Dependency graph
requires: []
provides:
  - Full-history credential scan (2381 commits, two engines) with committed raw reports
  - Dispositioned finding register under the D-29 Class A/B/C rule, verdict PROCEED
  - Re-measured `.planning/` disclosure surface (2175 tracked files, 51 with dollar figures)
  - The D-34 step 4 push gate, satisfied on its credential half and blocked on its authorization half
affects: [198-03 staging-branch push, 198-07 main push, any plan in this phase that pushes to origin]

actuals:
  tokens: 4700
  tasks: 2
  commits: 2

tech-stack:
  added: [gitleaks 8.30.1, trufflehog 3.97.1]
  patterns:
    - "Credential audit as a committed artifact with command provenance, not a runbook claim"
    - "Findings referenced by rule id + path + SHA, never by pasted secret, when the register itself will be published"

key-files:
  created:
    - .planning/audits/198-credential-audit.md
    - .planning/audits/198-gitleaks-history.json
    - .planning/audits/198-gitleaks-worktree.json
    - .planning/audits/198-trufflehog-verified.json
  modified: []

key-decisions:
  - "F-002/F-003 (example app dev/test secret_key_base) classed C (example value), not A — production is env-sourced and the example app has no deployed instance; the judgment call is surfaced at the Task 3 gate rather than settled silently"
  - "Disclosure-surface figures re-measured rather than copied from 198-CONTEXT.md, which had drifted (2159→2175, 49→51) because of this phase's own planning commits"
  - "trufflehog's 0-byte output recorded as an empty result corroborated by run statistics, explicitly not as a failed run"

patterns-established:
  - "Scanner availability is established and recorded before scanning; an absent scanner is an UNAVAILABLE row, never a silent clean read"
  - "--exit-code 0 on the gating scan so a finding cannot abort the sweep before later engines run; the verdict lives in the register, not in an exit code"

requirements-completed: []

coverage:
  - id: D1
    description: "Full-history credential scan across 2381 commits with two independent engines plus an untracked-tree pass and an ever-added-file sweep, raw reports committed"
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "test -f .planning/audits/198-gitleaks-history.json && test -f .planning/audits/198-gitleaks-worktree.json && test -f .planning/audits/198-trufflehog-verified.json && grep -q 'Scans run' .planning/audits/198-credential-audit.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every scanner finding carries a Class A/B/C disposition row with a stated reason, and the phase carries a machine-readable push verdict"
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "grep -qE '^## VERDICT: (PROCEED|ABORT)' .planning/audits/198-credential-audit.md && grep -q '^## Finding register' .planning/audits/198-credential-audit.md"
        status: pass
      - kind: integration
        ref: "grep -riE 'sk-ant-|ghp_|github_pat_|AKIA|BEGIN [A-Z ]*PRIVATE KEY' .planning/audits/198-credential-audit.md returns no match"
        status: pass
    human_judgment: false
  - id: D3
    description: "Classification of F-002/F-003 (example app dev/test secret_key_base) as Class C rather than Class A"
    requirement: GREEN-07
    verification: []
    human_judgment: true
    rationale: "A defensible maintainer could apply a blanket rotate-anything-secret-shaped policy instead. Deliberately surfaced at the Task 3 gate rather than settled by the executor; no test can adjudicate a policy posture."
  - id: D4
    description: "Push protection enabled and the one-way publication of 587 commits of `.planning/` history authorized"
    requirement: GREEN-07
    verification: []
    human_judgment: true
    rationale: "NOT DELIVERED — Task 3 is a gate='blocking-human' decision checkpoint and was not executed. Irreversible and outward-facing; requires explicit human authorization that can never be auto-approved."

# Metrics
duration: 8 min
completed: 2026-08-27
status: halted
---

# Phase 198 Plan 02: Credential Audit and Push Gate Summary

**Two-engine full-history credential scan over 2381 commits found five findings, all Class C, verdict PROCEED — then halted at the blocking-human gate without enabling push protection or authorizing publication.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-08-27T19:55:40Z
- **Completed:** 2026-08-27T20:03:49Z (halted at Task 3)
- **Tasks:** 2 of 3 completed; 1 halted by design
- **Files created:** 4

## Accomplishments

- **Resolved the plan's flagged assumption before scanning.** Neither `gitleaks` nor `trufflehog` was installed — the research phase marked both `[ASSUMED]`. Both formulae were verified to resolve to their genuine upstreams before installing, so no sweep silently read as clean.
- **Ran all four D-28 sweeps** over 2381 commits / 38.42 MB of history, the untracked working tree, verified-mode liveness checks, and the ever-added-then-removed filename sweep — with versions, verbatim command lines, and exit statuses recorded.
- **Dispositioned every finding under D-29** into a five-row register: **A=0, B=0, C=5**. Verdict `## VERDICT: PROCEED`.
- **Confirmed the highest-value negative result:** no `.env`, `.pem`, `id_rsa`, or `.netrc` file was **ever added** in the repository's history. This is precisely what a HEAD-only grep structurally cannot show, and the reason D-28 mandates full history.
- **Halted cleanly at the one-way gate** with nothing pushed and no repository setting changed.

## Task Commits

1. **Task 1: Full-history credential scan** — `c02d02cd` (docs)
2. **Task 2: Finding register and push verdict** — `12b153ed` (docs)
3. **Task 3: One-way decision gate** — NOT EXECUTED (halted, see below)

## Files Created/Modified

- `.planning/audits/198-credential-audit.md` — verdict, five-row finding register, disclosure surface, scan provenance, ever-added sweep
- `.planning/audits/198-gitleaks-history.json` — full-history gitleaks report, redacted
- `.planning/audits/198-gitleaks-worktree.json` — untracked-tree gitleaks report, redacted
- `.planning/audits/198-trufflehog-verified.json` — verified-mode trufflehog output (0 bytes: zero verified findings)

## Findings Summary

| id | file | class | disposition |
|----|------|-------|-------------|
| F-001 | `101-02-SUMMARY.md:118` | C | False positive — regex matched the prose `Key shape constraints:` followed by a backticked **filename** |
| F-002 | `examples/.../config/dev.exs` | C | Example app dev `secret_key_base`; production is env-sourced, no deployed instance |
| F-003 | `examples/.../config/test.exs` | C | Example app test `secret_key_base`; same rationale |
| F-004 | `.env.example` | C | Filename glob hit — Docker host/port template, no secret values |
| F-005 | `...demo-login-copy-credentials.md` | C | Filename glob hit — `credentials` appears in the todo's title |

trufflehog verified mode — the only engine that tests liveness against the issuing provider — returned **zero verified and zero unverified** secrets across the full history.

## Decisions Made

- **F-002/F-003 classed C, not A.** A `secret_key_base` is a real secret *shape*, but these two guard nothing: they are `mix phx.new` output for a bundled example app with no deployed instance, whose `runtime.exs:64` reads `SECRET_KEY_BASE` from the environment and raises if absent, and whose demo login credentials are printed on its own login page by design. Recording a fabricated "rotation" for a value protecting no live surface would put a misleading timestamp in a register that is about to be published. **The judgment call is written into the artifact and surfaced at the Task 3 gate** rather than settled silently — a maintainer applying a blanket rotate-anything policy would be equally defensible, and re-dispositioning to Class A does not change the PROCEED verdict.
- **Disclosure figures re-measured, not copied.** 198-CONTEXT.md states 2159 tracked `.planning/` files and 49 containing dollar figures. Live measurement gives **2175** and **51**. The drift is this phase's own planning commits. Both numbers are recorded side by side with the cause, because citing a stale figure in a published audit is the failure mode the artifact exists to avoid.
- **trufflehog's empty output labelled explicitly.** A 0-byte report is indistinguishable from a crashed scanner by inspection, so the run statistics (17572 chunks, 39244982 bytes, `verified_secrets: 0`) are recorded alongside it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed the two absent scanners**
- **Found during:** Task 1 precondition check
- **Issue:** `gitleaks` and `trufflehog` were both absent from PATH — the plan's `flagged_assumptions` predicted exactly this ("neither was probed as installed during research")
- **Fix:** Verified both Homebrew formulae resolve to genuine upstreams (`github.com/gitleaks/gitleaks`, `github.com/trufflesecurity/trufflehog`) via `brew info --json=v2` before installing, per the package-legitimacy rule. Installed from `homebrew/core`.
- **Verification:** `gitleaks version` → `8.30.1`; `trufflehog --version` → `trufflehog 3.97.1`; both recorded verbatim in the artifact
- **Committed in:** `c02d02cd`
- **Note:** The plan's Task 1 action explicitly authorizes this install path, so this is planned work rather than an unplanned substitution. No alternative or similarly-named package was considered.

**2. [Rule 1 - Bug] Corrected exit-status capture in the sweep runs**
- **Found during:** Task 1
- **Issue:** The first sweep invocations piped scanner output to `tail`, so `$?` reported `tail`'s status, not the scanner's. Recording those numbers as scanner exit statuses would have been a fabricated measurement in an audit artifact.
- **Fix:** Re-ran all four sweeps redirecting to a log file and capturing `$?` directly from the scanner process.
- **Verification:** All four recorded exit statuses are now the scanners' own
- **Committed in:** `c02d02cd`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Neither expands scope. The install was plan-authorized; the exit-status fix protects the artifact's integrity, which is the whole point of the deliverable.

## Issues Encountered

None. Both scanners installed cleanly and all four sweeps completed.

## HALT: Task 3 not executed (by design)

Task 3 is `<task type="checkpoint:decision" gate="blocking-human">`. Per the checkpoint protocol, `gate="blocking-human"` is **never** auto-approved or auto-selected in any mode, including the auto-advance mode active in this project's config. It was not executed.

**Specifically NOT done, and requiring explicit human authorization:**

- GitHub secret scanning and push protection are **NOT enabled**. No repository setting was changed.
- Nothing was pushed. `origin/main` remains `67998e0b`; `main` remains `20d3fead` with 595 unpushed commits.
- `## D-30 authorization` and `## Push protection enabled` in the audit artifact are marked pending.

**Verified at halt:** `git rev-parse origin/main` → `67998e0b29ebe8455d29183c4a71d2837d5b507e` (unchanged, matching CONTEXT.md ground truth).

## Next Phase Readiness

**BLOCKED — and this blocks more than it appears to.** The credential half of the D-34 step 4 gate is satisfied and recorded. The authorization half is not.

Per the plan's `key_links`: this gate covers the **first push of these commits on any ref** — that is **Plan 03's staging-branch push**, not only Plan 07's `main` push, because publishing `.planning/` history is the disclosure event regardless of which branch carries it. **Plan 03 must not run until Task 3 is resolved.**

To unblock, the maintainer must answer the Task 3 decision. On `proceed`: enable secret scanning and push protection via `gh api`, record the returned JSON and the confirmation verbatim in the artifact, then downstream plans may push. On `abort`: the artifact's verdict is overridden to `## VERDICT: ABORT` and no plan pushes.

**Standing invariant for every later plan:** push protection blocking a push is a Class A/B signal. The "allow secret" bypass is forbidden; a blocked push returns to the finding register for disposition.

## Self-Check

- `.planning/audits/198-credential-audit.md` — FOUND
- `.planning/audits/198-gitleaks-history.json` — FOUND
- `.planning/audits/198-gitleaks-worktree.json` — FOUND
- `.planning/audits/198-trufflehog-verified.json` — FOUND
- Commit `c02d02cd` — FOUND
- Commit `12b153ed` — FOUND
- Task 1 automated verify — PASS
- Task 2 automated verify — PASS
- Task 2 no-pasted-secret grep — PASS (no match)
- Task 3 automated verify — NOT RUN (task halted by design; `## Push protection enabled` is present but marked pending, and the `secret_scanning_push_protection` JSON is intentionally absent)
- Nothing pushed to origin — VERIFIED

## Self-Check: PASSED

Passed for the two executed tasks. Task 3's criteria are unmet **by design**, not by failure — hence `status: halted` and `requirements-completed: []`. GREEN-07 is **not** complete: its push-protection and authorization clauses remain open.

---
*Phase: 198-green-bringup*
*Halted at Task 3 (blocking-human gate): 2026-08-27*
