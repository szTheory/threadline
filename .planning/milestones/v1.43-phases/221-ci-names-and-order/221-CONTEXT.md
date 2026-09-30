# Phase 221: CI Names and Order - Context

**Gathered:** 2026-09-29
**Status:** Ready for planning
**Method:** research-then-recommend. Three parallel researchers covered job names, time-to-red order, and the `CI required` gate wiring. The maintainer's standing instruction, "auto follow ur recs", means the whole recommended set was adopted without a confirm round. There are no HIGH-IMPACT picks: no semver, security-model, public-API or scope change.

<domain>
## Phase Boundary

DX-01: a contributor can tell what failed from the name of a red check, without opening logs.

The phase makes four changes to `.github/workflows/ci.yml`, in this order:
1. Reorder the jobs by measured time-to-red, adding no `needs:` preflight.
2. Rewrite every job `name:` once, so each name says what the job proves, and update the CONTRIBUTING quotes in the same commit.
3. Pin job ids and a byte-exact `CI required`.
4. Add a contract that pins the `CI required` gate wiring itself. This is success criterion 4, added from the 220 round-3 verification advisory.

Out of scope:
- Any runtime or speed change. YAML order has no runtime effect (see D-05).
- Workflow-level `on:` filters.
- Other workflows' names, except where D-04 notes otherwise.
- The workflow name `CI`.

</domain>

<decisions>
## Implementation Decisions

### Names (SC-1)
- **D-01: Names lead with the subject and say what is proven.** No leading verb ("Run", "Check"). No internal jargon ("Tier A", "lane"). At most about 40 characters. A parenthetical is used only for a lane or scope qualifier.
  - Peers (Phoenix `mix test (...)`, Req `test`, Django `flake8`) name jobs after the command. That works for thin command wrappers. Threadline's jobs are composite proofs behind `mix verify.*` aliases, so command names would say what ran rather than what broke.
- **D-02: The name set.** ids are unchanged.
  | id | new `name:` |
  |---|---|
  | verify-release-shape | CHANGELOG matches version |
  | verify-repo-hygiene | Repo hygiene (no machine-local paths) |
  | verify-format | Formatting |
  | verify-deps-audit | Dependency audit (all lockfiles) |
  | verify-compile-no-optional | Compile without optional deps |
  | verify-hex-evaluator | Hex package install (rehearsal registry) |
  | verify-pgbouncer-topology | Tests through PgBouncer (transaction mode) |
  | verify-credo | Credo (strict) |
  | verify-bump-rehearsal | Next-minor release rehearsal (docs + contracts) |
  | verify-dialyzer | Dialyzer (full optional build) |
  | verify-test | Build and test, which GitHub posts as `Build and test (min)`, `(current)` and `(latest)` |
  | verify-capture | Capture evidence byte-stable |
  | verify-example-browser | Example app browser E2E (2 projects) |
  | ci-required | **CI required** (byte-exact, unchanged) |
- **D-03: The evaluator name is false today and gets fixed.** `mix verify.hex_evaluator` defaults to `rehearsal` mode (mix.exs around 423-463): it runs `hex.build` and serves the package from a throwaway local registry. Only release.yml sets `published`. So "(threadline from hex.pm)" is false on PRs. The step name "Verify Hex-published threadline adopt path" is false for the same reason and is fixed in the same commit. The planner verifies the mode logic before settling the final wording.
- **D-04: Mechanical rules for the rewrite.**
  - `name:` stays the first key under each job id. Topology mutation strings and the `summarize-ci.py` parser depend on that.
  - verify-test's `name:` stays static, with no `${{ }}`, so that GitHub still composes the `(lane)` suffix and `composed_check_names/1` keeps working.
  - Matrix `lane` values are unchanged, because the `matrix.lane == 'current'` guards depend on them.
  - The workflow `name: CI` must never change. `workflow_run: workflows: ["CI"]` in branch-protection, community-health and environment-protection keys on it.
  - Other workflows keep their names. Exception: browser-full may become "Example app browser E2E (all projects)" for symmetry, but its `TITLE_PREFIX` (pinned in browser_full_projects_contract_test.exs around 618) must not change.
  - Update every name reference in the same commit:
    - CONTRIBUTING's roster (around 883-898) and its `Run test suite (...)` quotes (around 39, 739, 821, 844)
    - the parity test (around 241 and 445-463, plus the inline fixtures around 4662/4755/4785)
    - the topology test mutation around 1099-1100
    - the moduledoc prose that cites historical run names, which stays as historical wording

### Order (SC-2)
- **D-05: SC-2 is about triage readability, not speed. Record this honestly.**
  - GitHub starts jobs without `needs:` in parallel. In run 36502353440 all 15 voting jobs started within about 1 s, except one that waited 36 s for a runner.
  - 15 concurrent jobs is under the Free-plan cap of 20.
  - The PR checks list sorts by state and name, and `CI required` waits for every need.
  - YAML order therefore shows up only when a reader scans ci.yml or the run sidebar. No success claim may say the reorder makes red faster.
- **D-06: Order by job-duration p50** over 10 cited warm post-219 runs: 36502353440, 36501481301, 36487483472, 36467068660, 36465241600, 36457705448, 36456537357, 36455432448, 36454272684, 36453043277. Ties are broken by max, then by id.
  Resulting order:
  1. release-shape (8 s)
  2. repo-hygiene (8)
  3. format (18)
  4. deps-audit (36)
  5. compile-no-optional (59)
  6. hex-evaluator (71)
  7. pgbouncer-topology (77)
  8. credo (78)
  9. bump-rehearsal (157)
  10. dialyzer (158)
  11. test (342, its fastest lane)
  12. capture (403)
  13. example-browser (568)
  14. **ci-required, always last**

  Re-derive the order only on a roster change or at a milestone baseline re-measure. Do not re-sort for noise within a tie band.
- **D-07: No `needs:` preflight chain.** A fast-first chain would delay every slow lane, turn its dependents into `skipped`, and save only about 20 s, and only on red runs. It is pinned by rule D-10(c).
- **D-08: Two commits.** Land the move first, as an order-only commit. Prove it mechanically: parsed-YAML maps before and after compare `==`, and `git diff --color-moved` shows moves only. Then land the one-pass name rewrite and CONTRIBUTING quotes as a separate commit. "Rename once" still holds, and the rename stays reviewable instead of hiding inside about 1,000 moved lines.
  - Comments travel with their block: the `CACHE KEY CONTRACT` comment now inside verify-format, and the header "Job id contract" roster, which is reordered to match.
  - `ci-required`'s `needs:` list is left as it is: zero churn for the gate pins.

### Contracts (SC-2, SC-3, SC-4)
- **D-09: Read job order through ordered parsed YAML, not a raw text scan.** The raw scan is the approach the 220 re-verification retired, because quoted ids and trailing comments bypass it.
  - The reader is `parsed_job_order/1`: `YamlElixir.read_from_string!(yaml, maps_as_keywords: true)`, then the `jobs` keys reversed. yaml_elixir 2.11.0's aggregator prepends, so the list comes back reversed; see `deps/yaml_elixir/lib/yaml_elixir/mapper.ex` around 88-93.
  - Guard 1: the set of keys must equal the plain `parsed_jobs/1` keys.
  - Guard 2: a fixture with `jobs: {a, b, c}` must read back as `[a, b, c]`. This catches a yaml_elixir upgrade that changes the reversal.
  - Fail closed if a jobs-level `<<` merge key appears.
- **D-10: `ci_order_errors/1`**, a pure function in the style of `dialyzer_topology_errors`. Rules:
  - (a) the order equals `@time_to_red_order ++ ["ci-required"]`;
  - (b) an unknown id fails with "place it by measured p50";
  - (c) no job except ci-required has a `needs` key, compared case-folded as `yaml_key/1` does;
  - (d) ci-required is last.

  `ci_required_block/0` (topology) and the `release_control_plane` split already assume (d). The planner may move them onto `parsed_job/2` instead.

  Mutation controls:
  - verify-format moved after example-browser
  - ci-required moved above repo-hygiene
  - `needs: [verify-format]` added to verify-test, in both block and flow spelling
  - a stub quoted `"verify-extra":` job
- **D-11: `required_gate_errors/1`** goes in `ci_workflow_parity_contract_test.exs`, which holds the private parsed-YAML helpers. It is a new test in the voting-lanes describe block, reusing the `{control, mutate, fragment}` harness and its yaml-parse guard. It stays separate from `voting_lane_errors/1`: that function asks whether lanes can fail, this one asks whether the aggregate decides.
  | Rule | Assertion (parsed YAML) | Mutation control |
  |---|---|---|
  | `gate-if` | ci-required `if`, normalized (strip `${{ }}` and whitespace, case-fold), `== "always()"` | delete `if: always()` |
  | `gate-step` | exactly one step; no `if`, no `run`; `uses` matches `^re-actors/alls-green@[0-9a-f]{40}$` | step `if: false`; `uses:` replaced with `run: echo ok` |
  | `gate-inputs` | the `with` key set (via `yaml_key`) is **exactly `["jobs"]`**. The allowlist covers `allowed-skips`/`allowed-failures` in every spelling and any future input | quoted `"allowed-skips": verify-test` |
  | `gate-jobs-input` | `jobs`, normalized, `== "${{tojson(needs)}}"` | `jobs: '{}'` |
  | `gate-name` | parsed name `=== "CI required"`; no `strategy`; exactly one job across `all_workflows()` is named `CI required` | a second workflow with a `CI required` job |
  | `job-ids` (SC-3) | the parsed ci.yml id set `==` a frozen `@ci_job_ids` literal of 14 ids | rename `verify-format` together with its header and `needs` entry, which three-way parity accepts |

  Also add a positive control: `allowed-skips` inside a comment trips nothing.

  Phase 222 escape hatch: if SEED-006 needs `allowed-skips`, widen the allowlist on purpose to `["jobs", "allowed-skips"]`, with the value pinned, and add the new id to `@ci_job_ids` and `@time_to_red_order` in the same commit.

  The two older text-regex `allowed-skips` checks (release_control_plane around 90, topology around 694) stay. They are harmless, and the topology one carries the doc hook.
- **D-12: Out of scope for the gate contract, because these fail closed.** Each leaves the check pending forever and never green: a bad `runs-on` label, `timeout-minutes`, `permissions`, and workflow-level `paths`/`branches-ignore`/`types`.

### Measurement continuity
- **D-13: Name-history alias map.**
  - The 214/219 `summarize-ci.py` tools map `job.name` to id by parsing the *current* ci.yml. `remeasure-218.py` and `remeasure-219.py` hardcode old names.
  - The GitHub jobs API does not expose the YAML id, so after the rename, pre-221 runs would map to `"?"` and silently undercount.
  - Fix: a frozen `NAME_HISTORY` (old name → id) map, following the `REMOVED_IDS` pattern in `remeasure-218.py` around 63, in a 221 tool. It is also usable by 222, which is decided from data that spans the rename.
  - Record the rename commit SHA and the first post-rename run ID as the era boundary.
  - The shipped REMEASURE docs are frozen and are not edited.
- **D-14: A small 221 tool regenerates `@time_to_red_order`** from `gh api .../runs/<id>/jobs`, reusing `summarize-ci.py`'s arithmetic. The tests never touch the network. A comment above the attribute cites the metric, the 10 run IDs and the regenerate command.

### Landing
- **D-15: Land through the established flow.**
  - Cherry-pick 221 onto a **new** land branch cut from main. PR #60's branch is merged and deleted.
  - Carry along `d7d44fd1` (220's parsed-YAML contract, not yet on main) and the three flake fixes (`2099d17b`, `9ebd6af5`, `997ad1d0`).
  - Push, open the PR and dispatch only under an explicit maintainer grant that names each action.
  - The PR CI run must show the new check names. Record its run ID as the era boundary (D-13).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract
- `.planning/ROADMAP.md`, Phase 221: 4 success criteria. SC-4 was added from the 220 round-3 advisory.
- `.planning/REQUIREMENTS.md`, DX-01 (around line 106).
- `.planning/phases/220-newest-toolchain-lane/220-VERIFICATION.md`, round 3: the gate-wiring advisory and its three reproduced vacuous edits.

### CI and contracts
- `.github/workflows/ci.yml`: the header job-id contract, every job, and ci-required (around 1077-1115).
- `test/threadline/ci_workflow_parity_contract_test.exs`: the parsed-YAML helpers (`parse_yaml`, `yaml_field`, `yaml_get`, `parsed_job`, `parsed_jobs`, `yaml_key`), `voting_lane_errors/1`, the mutation harness, and the name pins around 241 and 445-463.
- `test/threadline/ci_topology_contract_test.exs`: the alls-green SHA pin around 106, `ci_required_block/0` around 371, the `allowed-skips` doc hook around 694, the name mutation around 1099-1100, and the ruleset/name pin around 1145.
- `test/threadline/release_control_plane_contract_test.exs`, around 90-93.
- `.github/rulesets/main.json`, `bin/verify-branch-protection`, `bin/observe-main-ci` (around 88-89): `CI required` by name.
- `mix.exs`, around 423-463: the `verify.hex_evaluator` modes.
- `CONTRIBUTING.md`: the roster around 883-898, and quotes around 39, 739, 821 and 844.
- `deps/yaml_elixir/lib/yaml_elixir/mapper.ex`, around 88-93: keyword-order reversal.

### Measurement
- `.planning/phases/219-deps-only-build-cache/tools/summarize-ci.py` and `remeasure-219.py`.
- `.planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py` (the `REMOVED_IDS` pattern around 63).
- The committed run JSON under `.planning/phases/219-deps-only-build-cache/raw/ci/runs/`.

### External
- https://github.com/re-actors/alls-green: `if: always()` and `jobs: ${{ toJSON(needs) }}` are mandatory.
- https://docs.github.com/en/actions/reference/limits: concurrency caps.

</canonical_refs>

<code_context>
## Existing Code Insights

- The mutation-control harness `{control, mutate, fragment}` has a yaml-parse fail-closed guard (since d7d44fd1).
- `composed_check_names/1` (IN-02 fix) derives the posted check names from `name` plus the `lane` axis. It must keep working after the rename.
- `dialyzer_topology_errors/1` is the template for a pure `*_errors/1` contract function.
- The existing `workflow_job_ids/1` raw scan must not be used for new order or id pins (D-09).

</code_context>

<specifics>
## Specific Ideas

- Suggested plan split (the planner decides):
  1. The contracts first: `required_gate_errors/1`, `ci_order_errors/1` (pinned to the *target* order, written red-first), `@ci_job_ids`, and the 221 tool with `NAME_HISTORY`.
  2. The order-only move of ci.yml, which turns the order contract green.
  3. The one-pass rename, with CONTRIBUTING and the test name pins.
  4. Landing under a maintainer grant, with the era-boundary run ID recorded.
- Local gate: the contract files plus a full `mix test`, then `bin/verify-repo-hygiene`.

</specifics>

<deferred>
## Deferred Ideas

- Contracting workflow-level `on:` filters, which is a DX deadlock rather than vacuity: a separate advisory if ever needed.
- Renaming non-ci.yml workflows beyond the optional browser-full symmetry.
- Tiered-band ordering (option C): revisit only if re-measures keep reshuffling slots 6-10.

</deferred>
