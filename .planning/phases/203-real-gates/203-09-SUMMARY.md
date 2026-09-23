---
phase: 203-real-gates
plan: 09
subsystem: code-quality
status: complete
tags: [credo, gate-02, structural-debt, struct-07, register]
requires: [203-08]
provides:
  - "test/threadline/credo_config_contract_test.exs: source-resident, exact-count Credo structural register (Nesting 25, CyclomaticComplexity 16, ceiling 41, historical max 46, successor Phase 204 / STRUCT-07)"
  - "11 test-side structural sites filed in the D-31 form (`# Structural debt: <reason>` directly above the per-line disable)"
  - "STRUCT-07 in REQUIREMENTS.md (bullet, traceability row, coverage 54) and the Phase 204 ROADMAP criterion plus register mirror"
affects: [203-10, 204]
tech-stack:
  added: []
  patterns:
    - "Exact-equality register: scanned per-check disable count must equal the register. One extra or one missing fails, so no slack remains for an unreviewed disable"
    - "Credo-mirroring discovery: Code.string_to_quoted_with_comments/1 plus Credo's own config-comment regex, so string-literal fixtures are invisible to both"
key-files:
  created:
    - test/threadline/credo_config_contract_test.exs
  modified:
    - test/support/getting_started_fixtures.ex
    - test/threadline/dialyzer_ignore_contract_test.exs
    - test/threadline/guide_graph_contract_test.exs
    - test/threadline/operator_surface/card_nesting_regression_test.exs
    - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
    - test/threadline/operator_surface/rendered_output_contract_test.exs
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
decisions:
  - "release_artifact_contract_test.exs:424 (Nesting, depth 4) was NOT filed. The orchestrator's hard rule forbids touching that file, and that rule overrides the plan's files list. The register counts the tree as it is (25/16/41). If the site is filed later, three numbers go up by one: @register Nesting 25 to 26 and @ceiling 41 to 42 in the contract test, plus the ROADMAP mirror and criterion 5"
  - "The contract test assembles its synthetic suppression strings at runtime (\"# \" <> \"credo:\"). The file then holds no literal `credo:disable` text, so the grep-based acceptance counts stay exact"
  - "GATE-02 is left unchecked. The full-default residue is not yet the single Logger finding because of the one blocked site"
metrics:
  duration: "~25 min"
  completed: 2026-09-23
plan_base: 639212df18c96ec29f9746950571b04c48486714
plan_head_before: 639212df18c96ec29f9746950571b04c48486714
actuals:
  tokens: 6900
  tasks: 3
  commits: 8
---

# Phase 203 Plan 09: Test Structural Sites Filed and the Exact-Count Credo Register Summary

This plan filed 11 test-side structural Credo sites in the D-31 form. It added `Threadline.CredoConfigContractTest`, a register that lives in source: exact per-check equality at Nesting 25, CyclomaticComplexity 16, ceiling 41, historical max 46, with Phase 204 / STRUCT-07 named as the successor. It also added STRUCT-07 to REQUIREMENTS and mirrored it into ROADMAP Phase 204. One site, `test/threadline/release_artifact_contract_test.exs:424`, is still live because the orchestrator forbade touching that file.

Plan base SHA: `639212df18c96ec29f9746950571b04c48486714` (also recorded in `.git/gsd-203-09-base`).

## Tally

| Scope | Nesting filed | CyclomaticComplexity filed | Flattened | Unfiled (blocked) |
|---|---|---|---|---|
| lib/ (203-08) | 15 | 15 | 4 (Nesting) | 0 |
| test/ (203-09) | 10 | 1 | 0 | 1 (Nesting) |
| **Total** | **25** | **16** | **4** | **1** |

Before this plan, the live measurement found 12 structural findings, all in test/: Nesting 11 and CyclomaticComplexity 1. That matches the 203-08 hand-off.

## Per-site table (test sites)

The line is the reported construct line at HEAD, directly below its disable.

| Path | Line | Check | Outcome | Reason |
|---|---|---|---|---|
| `test/support/getting_started_fixtures.ex` | 8 | CyclomaticComplexity | filed | cyclomatic complexity 24 — split extract!/2 into anchor scan and snippet checks |
| `test/support/getting_started_fixtures.ex` | 37 | Nesting | filed | end-marker case inside cond inside reduce fn — extract the marker transition |
| `test/threadline/dialyzer_ignore_contract_test.exs` | 452 | Nesting | filed | id-match if inside nested map fns — extract the per-warning rewrite |
| `test/threadline/guide_graph_contract_test.exs` | 225 | Nesting | filed | resolve fn inside if inside the per-node loop — extract next-step target resolution |
| `test/threadline/operator_surface/card_nesting_regression_test.exs` | 190 | Nesting | filed | void? if inside case inside reduce fn — extract the start-tag stack step |
| `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs` | 185 | Nesting | filed | decode case inside reduce_while in else — extract the scorecard load step |
| `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs` | 226 | Nesting | filed | find case inside with — extract the unreferenced-cell lookup |
| `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs` | 262 | Nesting | filed | refute class case inside flat_map fn inside with — extract the refute reference mapper |
| `test/threadline/operator_surface/rendered_output_contract_test.exs` | 443 | Nesting | filed | validate case inside reduce_while in cond — extract the exception validation step |
| `test/threadline/operator_surface/rendered_output_contract_test.exs` | 637 | Nesting | filed | match map inside nested flat_map fns — extract the per-line vocabulary scan |
| `test/threadline/operator_surface/rendered_output_contract_test.exs` | 655 | Nesting | filed | attribute scan inside nested flat_map fns — extract the per-line attribute scan |
| `test/threadline/release_artifact_contract_test.exs` | 424 | Nesting (depth 4) | **NOT filed — blocked** | orchestrator hard rule: do not touch this file |

## Final register

```elixir
@register %{
  Credo.Check.Refactor.Nesting => {25, "Phase 204 / STRUCT-07"},
  Credo.Check.Refactor.CyclomaticComplexity => {16, "Phase 204 / STRUCT-07"}
}
@ceiling 41
@historical_max 46
```

`grep -rn "credo:disable" lib test | grep -v credo_config_contract_test | wc -l` returns 41, which equals `@ceiling`. The ROADMAP mirror uses the same numbers.

## Contract coverage (9 tests, `describe "structural register (GATE-02)"`)

- Real tree validates `:ok`. `@ceiling` equals the register sum and is `<= @historical_max`, `@historical_max == 46`, and the planning-directory self-guard passes.
- An extra disable (n+1) fails, and so does a missing one (n-1). The message carries the ratchet sentence.
- These forms are all rejected: `disable-for-this-file`, `disable-for-lines:3`, `disable-for-previous-line`, nameless, a non-registered check, trailing text, `enable-for-next-line`, `enable-for-rest-of-file`.
- Adjacency: a blank gap fails, as do a wrong prefix, an empty reason, and a missing debt line.
- An empty scan fails. A zero-disable scan validates against a zero register.
- Register shape is enforced: the ceiling must equal the sum, the historical max is checked, the successor must be non-empty, and exactly the two checks must be present.
- Offenders are sorted by `{path, line}`.
- Idempotency holds, and a doubled pair counts as 2.
- Suppression text inside a string literal stays invisible to the scan.

## Verification

- `mix test test/threadline/credo_config_contract_test.exs`: 9 tests, 0 failures
- Affected test files (Task 1 list, including release_artifact_contract_test): 53 tests, 0 failures
- `DB_PORT=5433 mix test` (full): 1711 tests, 0 failures, 1 excluded (the pre-existing `pgbouncer_topology` tag)
- `mix verify.format`: exit 0
- The adjacency acceptance (`grep -B1 ... | grep -c 'Structural debt: '` equals the disable count) passes
- Full-default Credo residue: `["Credo.Check.Warning.MissedMetadataKeyInLoggerConfig","Credo.Check.Refactor.Nesting"]`. **The Task 1 jq gate FAILS on the single blocked site** (`release_artifact_contract_test.exs:424`)
- The Plan 09 docs commit `957730a8` stages exactly `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`

## Commits

| SHA | Message |
|---|---|
| d4a61b2c | refactor(203-09): file structural Credo findings to Phase 204 in test/support/getting_started_fixtures.ex |
| ef1a4c1e | refactor(203-09): file structural Credo findings to Phase 204 in test/threadline/dialyzer_ignore_contract_test.exs |
| b2527a1a | refactor(203-09): file structural Credo findings to Phase 204 in test/threadline/guide_graph_contract_test.exs |
| b1daee6f | refactor(203-09): file structural Credo findings to Phase 204 in test/threadline/operator_surface/card_nesting_regression_test.exs |
| 8e2411a8 | refactor(203-09): file structural Credo findings to Phase 204 in test/threadline/operator_surface/operator_surface_fixture_contract_test.exs |
| 29612279 | refactor(203-09): file structural Credo findings to Phase 204 in test/threadline/operator_surface/rendered_output_contract_test.exs |
| 63cd16ed | refactor(203-09): add Credo structural register contract (GATE-02) |
| 957730a8 | docs(203-09): add STRUCT-07 and mirror the Credo structural register into Phase 204 |

## Deviations from Plan

**1. [Blocked — orchestrator hard rule] `test/threadline/release_artifact_contract_test.exs:424` left unfiled**
- **Found during:** Task 1 live measurement
- **Issue:** The plan lists this file in Task 1. The orchestrator's hard rule says "Do NOT touch release_artifact_contract_test.exs", and the orchestrator rule takes precedence.
- **Effect:** The Task 1 jq residue gate prints `false`: the Logger finding plus this one Nesting finding remain. The register and ROADMAP mirror reflect the tree (Nesting 25, not 26).
- **Resolution needed (maintainer):** Either (a) allow filing it: add two comment lines above line 424, then bump Nesting to 26 and `@ceiling` to 42 in the contract test, and update the ROADMAP mirror and criterion 5 to 42. Or (b) flatten it in Phase 204. Under (b), Plan 10's full-default gate still has to cope with the live finding in the meantime.

**2. [Rule 1 - own code] Flattened the new contract's `config_comments!/2`**
- Its first draft introduced a new Nesting finding (depth 4). It was rewritten with `with` and a `for` comprehension before commit, so the new file adds no structural finding and no disable.

## Known Stubs

None.

## Self-Check: PASSED
