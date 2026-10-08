---
phase: 234-typespec-and-doc-completion-gate
plan: 19
subsystem: security
tags: [cloak, hex-audit, encryption, reachability]

# Dependency graph
requires:
  - phase: 234-13
    provides: Fresh independent D-46 evidence and the counted public surface baseline
provides:
  - AST-aware live source guard for the example's GCM-only vault and Cloak.Ecto.Binary field
  - Two accountable, review-dated project-level Hex advisory acknowledgements
  - Evidence-linked T-234-31 and T-234-32 closures, with Plan 15 sign-off still open
affects: [234-15, SPEC-02, phase-234-security]

# Actuals (#2632), measured from the realized task-file diff at summary creation.
actuals:
  tokens: 2931
  tasks: 3
  commits: 3
commits: 3
plan_head_before: a6db609940dc67e5e307bb6ff14fcf7d48c9fd2c
plan_head_after: 4fe262ffa600fa810713912c890261b3b0d178e8

# Tech tracking
tech-stack:
  added: []
  patterns:
    - AST-aware source contracts that require positive live configuration evidence
    - Example-local Hex acknowledgements backed by reachability and review-date metadata

key-files:
  created:
    - test/threadline/cloak_advisory_reachability_contract_test.exs
  modified:
    - examples/threadline_phoenix/mix.exs
    - .planning/phases/234-typespec-and-doc-completion-gate/234-SECURITY.md

key-decisions:
  - "Record only EEF-CVE-2026-95105 and EEF-CVE-2026-94206, each reviewed by 2027-01-06, after live and historical reachability proofs pass."
  - "Keep T-234-26 and SPEC-02 pending for Plan 15's fresh full mix ci.all and final sign-off."

patterns-established:
  - "Advisory reachability guard: assert the live cipher and field AST, then scan non-static example source, migration, seed, and fixture files for affected paths."
  - "Security disposition evidence: close each package finding separately and retain the final phase sign-off as an independent gate."

requirements-completed: [] # SPEC-02 remains pending for Plan 15, as required by this plan.

coverage:
  - id: D1
    description: "The example's live vault and encrypted field remain on the approved GCM/Binary paths, with no scanned CTR or PBKDF2 path."
    verification:
      - kind: unit
        ref: test/threadline/cloak_advisory_reachability_contract_test.exs (4 tests)
        status: pass
    human_judgment: false
  - id: D2
    description: "The example Mix project records exactly the two D-58 advisory IDs with distinct rationale, reachability, and review-by metadata."
    verification:
      - kind: unit
        ref: test/threadline/ignore_advisories_contract_test.exs and test/threadline/cloak_advisory_reachability_contract_test.exs (19 tests)
        status: pass
      - kind: integration
        ref: mix verify.deps_audit (3 lockfiles)
        status: pass
    human_judgment: false
  - id: D3
    description: "T-234-31 and T-234-32 close from separate evidence while T-234-26 and SPEC-02 remain pending."
    verification:
      - kind: other
        ref: Plan 19 security status/count contract check
        status: pass
    human_judgment: false

# Metrics
duration: 18min
completed: 2026-10-06
status: complete
---

# Phase 234 Plan 19: Cloak Advisory Reachability Summary

**GCM-only Cloak reachability contracts and review-dated Hex acknowledgements unblock the example audit while preserving Plan 15 sign-off.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-10-06T15:06:11Z
- **Completed:** 2026-10-06T15:24:29Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added a non-vacuous ExUnit source contract that parses the live vault and encrypted field, requires exactly one AES-GCM default with tag `AES.GCM.V1`, requires `Cloak.Ecto.Binary`, and scans non-static example source/fixture files for CTR, decryptor, and PBKDF2 markers.
- Verified the tracked initial vault at `b50e51e4` used GCM and the specified tracked-history scan found no CTR tag/reader or PBKDF2 path.
- Added only EEF-CVE-2026-95105 and EEF-CVE-2026-94206 to the example's project-level Hex audit configuration, with distinct rationale, reachability, and `~D[2027-01-06]` review dates. No dependency declaration or lockfile changed.
- Closed T-234-31 and T-234-32 separately with evidence. The security register now has 33 threats, 30 closed, 3 open, and `threats_open: 1`; T-234-26 remains open and the register remains draft.

## Verification

- `mix test test/threadline/cloak_advisory_reachability_contract_test.exs` — 4 tests, 0 failures.
- `python3 -c 'import subprocess,sys; p="examples/threadline_phoenix/lib/threadline_phoenix/vault.ex"; s=subprocess.check_output(["git","show","b50e51e4:"+p],text=True); sys.exit(0 if "Cloak.Ciphers.AES.GCM" in s and "AES.GCM.V1" in s and "Cloak.Ciphers.AES.CTR" not in s else 1)'` — pass.
- `python3 -c 'import subprocess,sys; a=["git","log","--all","--oneline","-G","Cloak.Ciphers.AES.CTR|Cloak.Ecto.PBKDF2|AES.CTR.V","--","examples/threadline_phoenix/lib","examples/threadline_phoenix/config","examples/threadline_phoenix/priv"]; r=subprocess.run(a,capture_output=True,text=True); sys.exit(0 if r.returncode==0 and not r.stdout.strip() else 1)'` — pass; no matching tracked history.
- `mix test test/threadline/ignore_advisories_contract_test.exs test/threadline/cloak_advisory_reachability_contract_test.exs` — 19 tests, 0 failures.
- `mix verify.deps_audit` — clean across all 3 lockfiles. The default sandbox could not persist Hex's `~/.hex/cache.ets` (`:eaccess`); the same canonical command passed when rerun with cache-write access.
- `git diff --exit-code -- mix.lock examples/threadline_phoenix/mix.lock bench/mix.lock` — pass; all lockfiles unchanged.
- The Plan 19 `deps/0` comparison against `ee929c12` passed; project dependency declarations remain unchanged.
- The security status/count check passed. `REQUIREMENTS.md` still records SPEC-02 as Pending.

## Task Commits

1. **Task 1: Prove both advisory paths unreachable before acknowledging them** — `ce770f07` (`test(234-19): guard Cloak advisory reachability`)
2. **Task 2: Record only the two accountable example Hex acknowledgements** — `07313784` (`chore(234-19): record accountable Cloak advisory acknowledgements`)
3. **Task 3: Bind advisory threat dispositions to Plan 19 evidence** — `4fe262ff` (`docs(234-19): bind Cloak advisories to reachability evidence`)

## Files Created/Modified

- `test/threadline/cloak_advisory_reachability_contract_test.exs` — live AST and source reachability guard.
- `examples/threadline_phoenix/mix.exs` — two accountable project-level advisory acknowledgements.
- `.planning/phases/234-typespec-and-doc-completion-gate/234-SECURITY.md` — separate evidence-linked findings and reconciled audit counts.

## Decisions Made

- Followed D-58's approved scope: only the two named Hex IDs, no dependency or lockfile changes, and a review date of 2027-01-06.
- Kept T-234-26 open, the security register in draft, and SPEC-02 pending until Plan 15's fresh full `mix ci.all` and final evidence reconciliation.

## Deviations from Plan

None. The Hex cache permission issue affected only the default verification environment; the canonical audit passed after rerunning with write access to the cache.

## Issues Encountered

- The first in-sandbox `mix verify.deps_audit` attempts failed before audit evaluation because Hex could not persist `~/.hex/cache.ets` (`:eaccess`). The canonical audit passed on the authorized cache-write rerun and reported all three lockfiles clean.
- No additional advisory, reachability, dependency graph, or lockfile issue was found.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 19 is complete. Plan 15 is the next and only remaining gap plan for Phase 234; it must run a fresh full `mix ci.all` and finish SPEC-02/T-234-26 sign-off.
- Do not mark Phase 234 complete or start Phase 235 until Plan 15 and the phase verifier pass.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-06*

## Self-Check: PASSED

- `234-19-SUMMARY.md` exists.
- Task commits `ce770f07`, `07313784`, and `4fe262ff` are ancestors of HEAD.
- The latest task commit contains no file deletions.
