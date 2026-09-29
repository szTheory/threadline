---
status: resolved
trigger: "Flake run 36391367194 iter 51: DepsHealthReportTest GITHUB_OUTPUT test got classification=unknown instead of clean"
created: 2026-09-28
updated: 2026-09-28
---

## Current Focus
bug_class: Bohrbug-with-timing-trigger (deterministic race: EPIPE when fake mix exits before printf writes)
reasoning_checkpoint:
  hypothesis: "`printf 'n\\n' | $MIX_BIN deps.get --check-locked` under `set -o pipefail` returns 1 when the fake mix exits before printf writes; BEAM-spawned children inherit SIGPIPE=SIG_IGN so printf gets EPIPE, exits 1, and pipefail makes deps_get_status=1 -> unknown"
  confirming_evidence:
    - "Linux container BEAM stress (unfixed): 413/5000 non-clean; 100% show 'line 238: printf: write error: Broken pipe' and an empty '- fetch exit: 1' section"
    - "System.cmd bash -c 'trap -p SIGPIPE' prints: trap -- '' SIGPIPE"
  falsification_test: "with the pipe replaced by a here-string, the same stress still produces non-clean runs"
  fix_rationale: "a here-string feeds the same 'n' answer without a separate writer process, so the pipeline status is mix's own exit status"
  blind_spots: "cannot see the CI run's report.md (it was not printed); the mechanism is reproduced on Linux on the exact code path, not replayed from the CI artifact"
  candidate_causes:
    - "code: printf|mix pipeline + pipefail (confirmed)"
    - "environment: ETXTBSY on fresh executable (BEAM spawns via erl_child_setup, which never holds the write fd; no ETXTBSY seen in 5000+ Linux runs)"
    - "environment: concurrent removal of $ROOT/tmp (no code path in tests or bin removes it)"
  and_gate: "yes: needs (a) pipefail, (b) mix not reading stdin and exiting fast, (c) SIGPIPE ignored or default; (a)+(b) suffice, (c) only changes 1 vs 141"
next_action: apply here-string fix to bin/deps-health-report and bin/verify-deps-audit, rerun stress

## Symptoms
expected: classification=clean with default fakes
actual: classification=unknown once in 51 full-suite iterations (CI Linux)
errors: assertion ~r/^classification=clean$/m failed
reproduction: intermittent, Flake Detection
started: observed on main 2a75a795

## Eliminated
- hypothesis: OS env mutation / removal of bench or example mix.exs (ruled out by caller)

## Evidence
- checked: flake.log; found: classify-flake-run stderr lines are routine noise every iteration (lines 514-519 etc.), unrelated.

- checked: Linux container (elixir:1.19.5-otp-27, arm64) BEAM stress, 5000 runs conc 32, unfixed script
  found: 413 non-clean, all with 'printf: write error: Broken pipe' at line 238 and empty fetch exit 1
  implication: deps.get pipeline status is the race
- checked: SIGPIPE disposition of BEAM-spawned bash; found: trap -- '' SIGPIPE (ignored)
- checked: same pattern elsewhere; found: bin/verify-deps-audit:326 (pipefail), bin/verify-bump-rehearsal:378 (pipefail, real mix)

## Resolution
root_cause: "printf 'n\\n' | $MIX_BIN deps.get --check-locked under pipefail: printf EPIPE (SIGPIPE ignored in BEAM children) when mix exits before reading stdin -> fetch status 1 -> unknown"
fix: here-string (<<<'n') in bin/deps-health-report and bin/verify-deps-audit; diag() assertion messages; regression test refusing a pipe into $MIX_BIN; separate fix for deps_audit_gate_test global-wildcard isolation flake
verification: Linux BEAM stress 413/5000 bad before, 0/5000 and 0/20000 after; macOS async bin-script group 61 iterations x 309 tests, 0 failures; mutation (restore pipe) -> guard test fails
files_changed: [bin/deps-health-report, bin/verify-deps-audit, test/threadline/deps_health_report_test.exs, test/threadline/deps_audit_gate_test.exs]
oracle_type: specified (classification=clean) + structural guard
commits: [2099d17b, 9ebd6af5]
