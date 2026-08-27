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
  - The D-34 step 4 push gate, SATISFIED on both halves — credential audit complete and maintainer authorization recorded
  - Recorded D-30 authorization to publish `.planning/` history (one-way, maintainer-confirmed)
  - GitHub secret scanning and push protection verified enabled on szTheory/threadline
  - The standing D-29 invariant for every later plan: a blocked push is a Class A/B signal, the allow-secret bypass is forbidden
affects: [198-03 staging-branch push, 198-07 main push, any plan in this phase that pushes to origin]

actuals:
  tokens: 7400
  tasks: 3
  commits: 5

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
  - "F-002/F-003 (example app dev/test secret_key_base) classed C (example value), not A — production is env-sourced and the example app has no deployed instance; surfaced at the Task 3 gate rather than settled silently, and CONFIRMED there: Class C stands, neither value rotated"
  - "D-30 authorization taken: maintainer confirmed publication of `.planning/` history at the blocking-human gate; the confirmation is recorded verbatim in the audit artifact rather than paraphrased"
  - "Push protection recorded honestly as ALREADY enabled before the PATCH (GitHub public-repo default) — the PATCH ran and succeeded as a no-op confirmation, and the plan claims no credit for enabling what was already on"
  - "Disclosure-surface figures re-measured rather than copied from 198-CONTEXT.md, which had drifted (2159→2175, 49→51) because of this phase's own planning commits"
  - "trufflehog's 0-byte output recorded as an empty result corroborated by run statistics, explicitly not as a failed run"

patterns-established:
  - "Scanner availability is established and recorded before scanning; an absent scanner is an UNAVAILABLE row, never a silent clean read"
  - "--exit-code 0 on the gating scan so a finding cannot abort the sweep before later engines run; the verdict lives in the register, not in an exit code"

requirements-completed: [GREEN-07]

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
    rationale: "A defensible maintainer could apply a blanket rotate-anything-secret-shaped policy instead. Deliberately surfaced at the Task 3 gate rather than settled by the executor; no test can adjudicate a policy posture. RESOLVED at that gate on 2026-08-27: Class C stands, neither value rotated. The rationale is recorded in the artifact under '## D-30 authorization' so a later reader can re-open the call on the reasoning, not on a bare verdict."
  - id: D4
    description: "The one-way publication of `.planning/` history authorized by the maintainer at a recorded checkpoint (D-30)"
    requirement: GREEN-07
    verification: []
    human_judgment: true
    rationale: "Irreversible and outward-facing; requires explicit human authorization that can never be auto-approved. DELIVERED — the gate was resolved by the maintainer and the confirmation is recorded verbatim under '## D-30 authorization' in .planning/audits/198-credential-audit.md. human_judgment stays true because the deliverable IS a human decision; no test can attest to it and a verifier should read the recorded confirmation rather than trust a green check."
  - id: D5
    description: "GitHub secret scanning and push protection live on szTheory/threadline before any push of these commits"
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "gh api repos/:owner/:repo --jq .security_and_analysis reports secret_scanning=enabled and secret_scanning_push_protection=enabled"
        status: pass
      - kind: integration
        ref: "grep -q '^## Push protection enabled' .planning/audits/198-credential-audit.md && grep -q '\"secret_scanning_push_protection\"' .planning/audits/198-credential-audit.md"
        status: pass
    human_judgment: false
  - id: D6
    description: "This plan pushed nothing — the gate is recorded but no commit reached origin on any ref"
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "git log origin/main..main is non-empty (606 commits); git rev-parse origin/main unchanged at 67998e0b"
        status: pass
    human_judgment: false

# Metrics
duration: 11 min
completed: 2026-08-27
status: complete
---

# Phase 198 Plan 02: Credential Audit and Push Gate Summary

**Two-engine full-history credential scan over 2381 commits found five findings, all Class C, verdict PROCEED — and the maintainer's one-way authorization to publish `.planning/` history is now recorded, with secret scanning and push protection verified live and nothing pushed.**

## Performance

- **Duration:** 11 min of executor time (8 min for Tasks 1–2, 3 min for Task 3), excluding the wall-clock wait at the blocking-human gate
- **Started:** 2026-08-27T19:55:40Z
- **Halted at gate:** 2026-08-27T20:03:49Z
- **Gate resolved / resumed:** 2026-08-27T20:15:04Z
- **Completed:** 2026-08-27T20:16Z
- **Tasks:** 3 of 3 completed
- **Files created:** 4; **modified:** 1 (this summary)

## Accomplishments

- **Resolved the plan's flagged assumption before scanning.** Neither `gitleaks` nor `trufflehog` was installed — the research phase marked both `[ASSUMED]`. Both formulae were verified to resolve to their genuine upstreams before installing, so no sweep silently read as clean.
- **Ran all four D-28 sweeps** over 2381 commits / 38.42 MB of history, the untracked working tree, verified-mode liveness checks, and the ever-added-then-removed filename sweep — with versions, verbatim command lines, and exit statuses recorded.
- **Dispositioned every finding under D-29** into a five-row register: **A=0, B=0, C=5**. Verdict `## VERDICT: PROCEED`.
- **Confirmed the highest-value negative result:** no `.env`, `.pem`, `id_rsa`, or `.netrc` file was **ever added** in the repository's history. This is precisely what a HEAD-only grep structurally cannot show, and the reason D-28 mandates full history.
- **Halted cleanly at the one-way gate** with nothing pushed and no repository setting changed — then **resumed after the maintainer resolved it**, and recorded the `proceed` authorization verbatim.
- **Verified secret scanning and push protection are live** on `szTheory/threadline`, and recorded the honest finding that **both were already enabled before the PATCH** (GitHub's public-repo default), so the plan claims no credit for enabling them.
- **Wrote the standing D-29 invariant into the published artifact** so every later plan inherits it: a blocked push is a Class A/B signal, and the "allow secret" bypass is forbidden.
- **Still pushed nothing.** `origin/main` remains `67998e0b`; 606 commits remain unpushed. The gate is now open; walking through it is Plan 03's job.

## Task Commits

1. **Task 1: Full-history credential scan** — `c02d02cd` (docs)
2. **Task 2: Finding register and push verdict** — `12b153ed` (docs)
3. **Task 3: One-way decision gate — authorization and push protection** — `475246b7` (docs)

**Plan metadata:** `85a2fb8c` (halt record), plus the commit updating this summary to its completed form.

## Files Created/Modified

- `.planning/audits/198-credential-audit.md` — verdict, five-row finding register, disclosure surface, scan provenance, ever-added sweep
- `.planning/audits/198-gitleaks-history.json` — full-history gitleaks report, redacted
- `.planning/audits/198-gitleaks-worktree.json` — untracked-tree gitleaks report, redacted
- `.planning/audits/198-trufflehog-verified.json` — verified-mode trufflehog output (0 bytes: zero verified findings)

Modified in Task 3:

- `.planning/audits/198-credential-audit.md` — `## D-30 authorization` (maintainer confirmation verbatim, timestamp, F-002/F-003 rider) and `## Push protection enabled` (verbatim `gh api` JSON, the already-enabled disclosure, the standing D-29 invariant)

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

None blocking. Both scanners installed cleanly, all four sweeps completed, and the `gh api` PATCH succeeded on the first attempt.

One discrepancy worth recording rather than smoothing over: **the earlier halt record stated that secret scanning and push protection were "NOT enabled", and the remote said otherwise.** Both were already `enabled` when Task 3 read the repository. The halt record's claim was accurate about the plan's own actions — it had changed no setting — but it was never a verified read, and it was written as though it were a statement about the world. Task 3 corrected it in the artifact and here. The lesson is narrow and worth keeping: in an audit artifact, "we did not do X" and "X is not the case" are different claims and must not be written in the same sentence.

## Task 3: the blocking-human gate, halted then resolved

Task 3 is `<task type="checkpoint:decision" gate="blocking-human">`. Per the checkpoint protocol, `gate="blocking-human"` is **never** auto-approved or auto-selected in any mode, including the auto-advance mode active in this project's config. The first execution therefore halted at it rather than proceeding — that halt was correct behavior, not a failure.

**The gate was then resolved by the maintainer** and this plan resumed to complete Task 3.

**Decision: `proceed`.** Publication of `.planning/` history is authorized, and secret scanning with push protection is to be enabled. The maintainer's reply is recorded verbatim in the audit artifact under `## D-30 authorization` — not paraphrased, because a paraphrase of a one-way authorization is the wrong artifact to leave behind.

**The one open judgment call was resolved as part of the same answer.** The maintainer delegated the F-002/F-003 call (the example app's `dev.exs` / `test.exs` `secret_key_base` literals). **Class C stands; neither value was rotated.** They guard nothing — a bundled example app with no deployed instance, production sourcing `SECRET_KEY_BASE` from the environment at `runtime.exs:64`, and demo login credentials printed on the page by design. Rotating would have stamped a misleading "rotated on 2026-08-27" incident row into a register about to be published, describing something that was never an exposure. The PROCEED verdict and class counts (**A=0 rotated 0 · B=0 · C=5**) are unchanged.

**Push protection — the honest version.** Both settings verify as `enabled`, satisfying the gate. But a read taken **before** the PATCH already returned `secret_scanning: enabled` and `secret_scanning_push_protection: enabled`. GitHub enables both by default on public repositories, and this repo has been public throughout. The PATCH was run as the plan specifies and succeeded, but **as a no-op confirmation, not a state change.** This is recorded plainly in the artifact and corrects, in the honest direction, the earlier halt record's line that the settings were "NOT enabled" — that line was true about what the plan had *done* but was never a verified read of the remote. No credit is claimed for turning on something already on.

**Nothing was pushed, and no other repository setting was touched.** `secret_scanning_non_provider_patterns`, `secret_scanning_validity_checks`, and `dependabot_security_updates` remain `disabled` and are out of scope for this plan. No branch, PR, tag, or release was created.

**Verified after Task 3:** `git rev-parse origin/main` → `67998e0b29ebe8455d29183c4a71d2837d5b507e` (unchanged); `git log origin/main..main` → **606 commits**, non-empty, exactly as the plan's verification requires.

## Next Phase Readiness

**UNBLOCKED.** Both halves of the D-34 step 4 gate are now satisfied and recorded: the credential audit ran over full history with two engines and every finding is dispositioned, and the maintainer's one-way authorization is on the record.

Per the plan's `key_links`, this gate covers the **first push of these commits on any ref** — Plan 03's staging-branch push as much as Plan 07's `main` push, because publishing `.planning/` history is the disclosure event regardless of which branch carries it. **Plan 03 may now proceed.**

**Standing invariant inherited by every later plan in this phase:** push protection blocking a push is a **Class A/B signal**. The "allow secret" bypass is **forbidden** — not clicked, not invoked, not flagged around. A blocked push returns to `.planning/audits/198-credential-audit.md`'s finding register for disposition under D-29 before any retry. Class A rotates before the retry; Class B aborts the phase.

## Self-Check

- `.planning/audits/198-credential-audit.md` — FOUND
- `.planning/audits/198-gitleaks-history.json` — FOUND
- `.planning/audits/198-gitleaks-worktree.json` — FOUND
- `.planning/audits/198-trufflehog-verified.json` — FOUND
- Commit `c02d02cd` — FOUND
- Commit `12b153ed` — FOUND
- Commit `475246b7` — FOUND
- Task 1 automated verify — PASS
- Task 2 automated verify — PASS
- Task 2 no-pasted-secret grep — PASS (no match, re-run after the Task 3 edits)
- Task 3 automated verify (`## Push protection enabled` + `"secret_scanning_push_protection"` present) — PASS
- `## D-30 authorization` heading present with verbatim confirmation and timestamp — PASS
- `gh api repos/:owner/:repo --jq .security_and_analysis` shows both settings `enabled` — PASS
- `git log origin/main..main` non-empty (606) — PASS, nothing pushed
- STATE.md and ROADMAP.md untouched — VERIFIED (`git status --short` showed only the audit artifact before commit)

## Self-Check: PASSED

All three tasks executed and verified. `status: complete`, `requirements-completed: [GREEN-07]` — the requirement's scan, disposition, push-protection, and authorization clauses are all now closed.

---
*Phase: 198-green-bringup*
*Halted at Task 3 (blocking-human gate) 2026-08-27T20:03:49Z; gate resolved and plan completed 2026-08-27*
