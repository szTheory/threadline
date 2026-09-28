---
phase: 215-supply-chain-gate
plan: 05
subsystem: ci
tags: [hex, mix, supply-chain, deps-audit, bash, exunit]

requires:
  - phase: 215-supply-chain-gate
    provides: bin/verify-deps-audit (per-PR gate), test/threadline/deps_audit_gate_test.exs, test/threadline/deps_audit_contract_test.exs, test/threadline/ignore_advisories_contract_test.exs, CONTRIBUTING.md freshness policy (215-01..04)
provides:
  - bin/verify-deps-audit refuses a non-empty global Hex ignore_advisories/ignore_retirements (mix hex.config, any HEX_HOME) before any audit call
  - bin/verify-deps-audit fetches with deps.get --check-locked, so a mix.lock/mix.exs mismatch fails the gate instead of being silently re-resolved and audited
  - test/threadline/deps_audit_contract_test.exs rejects HEX_HOME / MIX_HOME / hex.config ignore_ / HEX_IGNORE_* in any workflow, with a non-vacuous matcher
  - test/threadline/ignore_advisories_contract_test.exs moduledoc no longer overclaims scope
  - CONTRIBUTING.md states both new gate rules
affects: [215-06, future-supply-chain-work]

actuals:
  tokens: 6939
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Neutral mix.exs-free tmp dir for a `mix hex.config KEY` query that would otherwise pick up a project's own accountable config"
    - "Joining a multi-line-wrapped Elixir inspect() answer into one value before comparing it to a clean sentinel"
    - "deps.get --check-locked as the mechanism to make a gate audit the committed lock, never a re-resolved one"

key-files:
  created: []
  modified:
    - bin/verify-deps-audit
    - test/threadline/deps_audit_gate_test.exs
    - test/threadline/deps_audit_contract_test.exs
    - test/threadline/ignore_advisories_contract_test.exs
    - CONTRIBUTING.md

key-decisions:
  - "CR-01: refuse a non-empty global mix hex.config ignore_advisories/ignore_retirements rather than isolate HEX_HOME — refusal is source-agnostic and surfaces the misconfiguration instead of silently masking it and paying a cold-fetch cost on every run"
  - "The hex.config query runs from a fresh mktemp -d \"$ROOT/tmp/deps-audit-hex-config.XXXXXX\" dir (removed via trap + explicit rm) because running it inside a project also merges that project's own accountable hex: [ignore_advisories: ...] entry"
  - "WR-02: mix deps.get --check-locked instead of a post-hoc git diff on mix.lock — fails the fetch itself rather than detecting drift after the fact"
  - "Real Hex's `mix hex.config KEY` answer for a long ignore list wraps across multiple output lines; the parser joins from the first bracket-starting line through the rest of the output into one value instead of taking only the last non-empty line (found live against the verifier's own 4-advisory-id repro command, fixed same-commit)"
  - "Erlang's System.cmd :env option silently drops a zero-length env value (treats it as unset) — the offline gate test's \"hex.config prints nothing\" cases use a literal __NOOUTPUT__ sentinel the fake mix interprets specially, since a true empty-string value cannot be delivered through that API"

requirements-completed: [SUP-02, SUP-03]

coverage:
  - id: D1
    description: "CR-01 closed: a non-empty global Hex ignore_advisories/ignore_retirements (any HEX_HOME) is refused before any deps.get/hex.audit call, naming the key"
    requirement: SUP-02
    verification:
      - kind: unit
        ref: "test/threadline/deps_audit_gate_test.exs#a non-empty global hex.config ignore_advisories exits non-zero before any audit call, naming the key"
        status: pass
      - kind: unit
        ref: "test/threadline/deps_audit_gate_test.exs#a non-empty global hex.config ignore_retirements exits non-zero before any audit call, naming the key"
        status: pass
      - kind: integration
        ref: "bin/verify-deps-audit --self-test (case c, real Hex)"
        status: pass
      - kind: manual_procedural
        ref: "verifier's own CR-01 repro command (4-advisory-id HEX_HOME ignore against the vulnerable fixture), re-run live"
        status: pass
    human_judgment: false
  - id: D2
    description: "The global-ignore query fails closed on unreadable/unparseable/non-zero hex.config output and tolerates a leading warning line before a clean []"
    requirement: SUP-02
    verification:
      - kind: unit
        ref: "test/threadline/deps_audit_gate_test.exs (six fail-closed tests + the warning-tolerance test)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The query runs from a neutral, mix.exs-free tmp dir outside every audited directory, removed afterwards"
    requirement: SUP-02
    verification:
      - kind: unit
        ref: "test/threadline/deps_audit_gate_test.exs#the hex.config query runs from a neutral, mix.exs-free dir under tmp/, removed afterwards"
        status: pass
    human_judgment: false
  - id: D4
    description: "WR-02 closed: deps.get --check-locked fails a dir whose mix.lock no longer matches mix.exs and skips that dir's hex.audit; aggregation across dirs is preserved"
    requirement: SUP-02
    verification:
      - kind: unit
        ref: "test/threadline/deps_audit_gate_test.exs#a lock that no longer matches mix.exs fails via --check-locked and skips that dir's hex.audit"
        status: pass
      - kind: unit
        ref: "test/threadline/deps_audit_gate_test.exs#lock drift in the 1st of 3 dirs is aggregated: dirs two and three still run hex.audit"
        status: pass
      - kind: integration
        ref: "bin/verify-deps-audit --self-test (case d, real Hex, byte-identical lock proven via cmp)"
        status: pass
    human_judgment: false
  - id: D5
    description: "No workflow file can reintroduce the bypass unnoticed: contract test rejects HEX_HOME/MIX_HOME/hex.config ignore_/HEX_IGNORE_* with a proven non-vacuous matcher"
    requirement: SUP-02
    verification:
      - kind: unit
        ref: "test/threadline/deps_audit_contract_test.exs#forbidden_hex_surface/1 is non-vacuous: finds every token in a synthetic positive, nothing in a benign snippet"
        status: pass
      - kind: unit
        ref: "test/threadline/deps_audit_contract_test.exs#no workflow file references the Hex/Mix-home or global-ignore suppression surface (CR-01)"
        status: pass
    human_judgment: false
  - id: D6
    description: "ignore_advisories_contract_test.exs moduledoc no longer overclaims scope; CONTRIBUTING.md states both new gate rules"
    requirement: SUP-03
    verification:
      - kind: unit
        ref: "test/threadline/ignore_advisories_contract_test.exs and deps_health_doc_contract_test.exs full suite (unchanged, still green)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Clean tree stays green: gate reports 3 lockfile(s) audit clean, self-test reports all four red cases, full mix test 0 failures, format/compile clean"
    verification:
      - kind: integration
        ref: "mix verify.deps_audit; bin/verify-deps-audit --self-test; mix test; mix format --check-formatted; mix compile --warnings-as-errors"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-09-27
status: complete
---

# Phase 215 Plan 05: Close CR-01 and WR-02 in the required supply-chain gate Summary

**`bin/verify-deps-audit` now refuses a non-empty global Hex `ignore_advisories`/`ignore_retirements` (any `HEX_HOME`) via `mix hex.config`, and fetches with `deps.get --check-locked` so a drifted `mix.lock` fails instead of being silently re-resolved and audited — both proven offline and against real Hex, with the workflow contract test and SUP-03 moduledoc updated to match.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-09-27T00:04:00Z (approx, from state)
- **Completed:** 2026-09-27T00:59:00Z (approx)
- **Tasks:** 3 (Task 1 tracer, Tasks 2-3 auto)
- **Files modified:** 5

## Accomplishments

- Closed CR-01: `bin/verify-deps-audit` reads Hex's effective `ignore_advisories`/`ignore_retirements` via `mix hex.config` from a neutral, mix.exs-free `$ROOT/tmp/deps-audit-hex-config.XXXXXX` dir, right after the Hex version floor and before any per-directory audit call, and dies on anything other than a clean `[]` — fail-closed on unreadable/unparseable/non-zero output, tolerant of a leading warning line, and joining a real Hex answer that wraps across multiple output lines (found live against the verifier's own 4-advisory-id repro command).
- Closed WR-02: the per-directory fetch is now `mix deps.get --check-locked`, so a `mix.lock` that no longer matches `mix.exs` fails that directory and skips its `hex.audit` instead of silently re-resolving and auditing a different lock. Aggregation across the three canonical directories is preserved.
- `bin/verify-deps-audit --self-test` now proves four cases against real Hex: (a) vulnerable lock red, (b) old Hex red, (c) global Hex ignore red, (d) lock drift red with the committed lock left byte-identical (`cmp`).
- `test/threadline/deps_audit_contract_test.exs` gained `forbidden_hex_surface/1`, a single-regex matcher (proven non-vacuous on synthetic positive/negative fixtures) that scans every workflow file for `HEX_IGNORE_ADVISORIES`, `HEX_IGNORE_RETIREMENTS`, `HEX_HOME`, `MIX_HOME`, and `hex.config ignore_` — the full CR-01 suppression surface, not just the two env vars the old test caught.
- `test/threadline/ignore_advisories_contract_test.exs`'s moduledoc no longer claims to see "exactly the ids Hex itself uses"; it states the test covers project-level `hex:` config only and names `bin/verify-deps-audit`'s runtime refusal (proven by `deps_audit_gate_test.exs` and `--self-test`) as the guard for the client-level surface.
- `CONTRIBUTING.md`'s freshness-policy gate paragraph states both new rules: the global-config refusal and `--check-locked`.

## Task Commits

Each task was committed atomically (Task 1 is `type="tracer" tdd="true"`, so it carries a RED test commit and a GREEN implementation commit; Task 2 is the same TDD shape; Task 3 is a single test/doc commit):

1. **Task 1 RED** — `157ce719` test(deps-audit): reproduce global hex.config ignore bypass (CR-01)
2. **Task 1 GREEN** — `dec5b84b` ci(deps-audit): refuse global hex.config advisory/retirement ignores (CR-01)
3. **Task 2 RED** — `78f8ddd9` test(deps-audit): reproduce silent lock re-resolution (WR-02)
4. **Task 2 GREEN** — `a73373f1` ci(deps-audit): audit the committed lock via deps.get --check-locked (WR-02)
5. **Task 3** — `8a7cceba` test(deps-audit): reject Hex home/config overrides in workflows and correct ignore-contract scope

**Plan metadata:** (this commit, following this SUMMARY)

_Tracer feedback gate: after Task 1's GREEN commit, auto mode (`workflow.auto_advance: true`) re-ran the tracer's `<automated>` verify end-to-end (`mix test` for the gate test file, `mix verify.deps_audit`, `bin/verify-deps-audit --self-test`, and the no-leftover-tmp-dir check) — all passed, so expansion into Task 2 proceeded with no checkpoint._

## Files Created/Modified

- `bin/verify-deps-audit` — new `read_global_hex_ignore` / `refuse_global_hex_ignores` functions; `deps.get --check-locked`; self-test cases (c) and (d); updated header comments and success message
- `test/threadline/deps_audit_gate_test.exs` — `hex.config` and `deps.get` responders in `fake_mix/1` (with a `__NOOUTPUT__` sentinel worked around Erlang's inability to pass a true empty-string env value); 8 new tests for the global-ignore refusal and 2 new tests for lock drift; updated exact-calls and canonical-dirs tests
- `test/threadline/deps_audit_contract_test.exs` — `forbidden_hex_surface/1` helper, a non-vacuity test, and a live workflow scan replacing the narrower HEX_IGNORE_*-only test
- `test/threadline/ignore_advisories_contract_test.exs` — corrected moduledoc paragraph (no code change)
- `CONTRIBUTING.md` — freshness-policy gate paragraph states `--check-locked` and the global-config refusal

## Decisions Made

See `key-decisions` in the frontmatter. The most consequential mid-execution ones:

- **Real Hex wraps long `hex.config` answers across multiple lines.** The plan's specified parser ("take the last non-empty line") worked for every fact verified during planning (short 2-id lists) but broke on the verifier's own 4-advisory-id repro command, which Hex's `inspect/1`-style formatter wraps across two lines at ~80 columns. Fixed in the same commit by joining from the first bracket-starting line through the rest of the output, verified against the exact repro command from the plan's acceptance criteria.
- **Erlang's `System.cmd` `:env` option drops a zero-length value entirely** (confirmed empirically: `[{"KEY", ""}]` makes `KEY` unset in the child, not set-to-empty). The plan's fake-mix design ("unset-only default expansion so an UNSET var prints `[]` while a var set to the empty string prints nothing") is unreachable from Elixir's test harness for the empty-string case. Substituted a literal `__NOOUTPUT__` sentinel that `fake_mix` interprets specially, preserving the same test intent (fail closed on no output) without depending on an environment behavior the test runtime cannot produce.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the global-ignore value parser to handle a real multi-line-wrapped `hex.config` answer**
- **Found during:** Task 1, acceptance-criteria verification (the verifier's own CR-01 repro command with 4 advisory ids)
- **Issue:** The plan's specified "take the last non-empty line" parsing broke when Hex wrapped a long ignore list across two output lines, causing the gate to report "could not read global Hex config" instead of the correct "global Hex config sets ignore_advisories to [...]" refusal message — a false negative in the failure classification (still a refusal, but the wrong one, which would confuse whoever reads it).
- **Fix:** `read_global_hex_ignore` now finds the first non-blank line that (after trim) starts with `[` and joins that line through the rest of the output into one value, squeezing whitespace, before comparing to `[]`.
- **Files modified:** bin/verify-deps-audit
- **Verification:** Re-ran the plan's exact acceptance-criteria repro command (4-id `HEX_HOME` ignore against a copied vulnerable fixture); now prints the correct `global Hex config sets ignore_advisories to [...]` message and exits non-zero without ever printing `audit clean`.
- **Committed in:** dec5b84b (Task 1 GREEN commit — found and fixed before that commit, so no separate fix commit was needed)

**2. [Rule 3 - Blocking] Substituted a sentinel for "hex.config prints nothing" test cases**
- **Found during:** Task 1, while getting the offline gate tests green
- **Issue:** The plan's fake-mix design relies on an env var explicitly set to the empty string producing empty program output, distinct from an unset var (which should default to `[]`). Empirically, Elixir's `System.cmd(:env)` option (and the underlying Erlang port `env` option) drops a zero-length value from the child's environment entirely — it is indistinguishable from unset — so this specific test scenario cannot be constructed the way the plan described.
- **Fix:** Added a literal `__NOOUTPUT__` sentinel value that `fake_mix`'s `hex.config` responder checks for and, when matched, prints nothing for that key (instead of relying on empty-string env passthrough). The two "prints nothing" tests set this sentinel instead of an empty string. The unset-defaults-to-`[]` behavior (used everywhere else) is untouched.
- **Files modified:** test/threadline/deps_audit_gate_test.exs
- **Verification:** Both "hex.config KEY printing nothing fails closed" tests pass; the rest of the fake-mix behavior (unset → `[]`, non-list word, non-zero exit, warning-line tolerance) is unaffected.
- **Committed in:** 157ce719 (Task 1 RED commit, discovered and fixed while iterating on the RED tests before committing)

---

**Total deviations:** 2 auto-fixed (1 bug found via acceptance-criteria verification, 1 blocking issue in the test harness itself).
**Impact on plan:** Both fixes were necessary for the plan's own stated proofs to actually hold (the verifier's exact repro command, and the offline fail-closed test matrix) — no scope creep beyond what CR-01/WR-02 required.

## Issues Encountered

None beyond the two deviations above, both resolved before their respective commits.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Both `215-VERIFICATION.md` gaps (CR-01, WR-02) are closed in the required `verify-deps-audit` gate, proven offline (`mix test`) and against real Hex (`--self-test`), with no lockfile or `mix.exs` constraint changes (`git diff 0812bddb` over all committed locks and `.github/workflows/ci.yml` is empty).
- `mix test` is green at 2283 tests (up from 2270 baseline before this plan; 0 failures, 2 excluded), `mix format --check-formatted` and `mix compile --warnings-as-errors` are clean.
- Ready for 215-06 (the remaining gap-closure plan) or phase re-verification.

---
*Phase: 215-supply-chain-gate*
*Completed: 2026-09-27*

## Self-Check: PASSED

- Files verified present: `bin/verify-deps-audit`, `test/threadline/deps_audit_gate_test.exs`, `test/threadline/deps_audit_contract_test.exs`, `test/threadline/ignore_advisories_contract_test.exs`, `CONTRIBUTING.md`, this SUMMARY.md.
- Commits verified present in `git log`: `157ce719`, `dec5b84b`, `78f8ddd9`, `a73373f1`, `8a7cceba`, `67dc18e0`.
- All task `<acceptance_criteria>` and the plan-level `<verification>` block re-run and passing at commit time (see task-by-task verification runs above; full `mix test` at 2283/0 failures).
