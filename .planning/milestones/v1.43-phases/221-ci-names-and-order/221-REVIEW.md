---
phase: 221-ci-names-and-order
reviewed: 2026-09-29T15:12:54Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/browser-full.yml
  - CONTRIBUTING.md
  - guides/evaluating-threadline.md
  - guides/adoption-evidence-playbook.md
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - .planning/phases/221-ci-names-and-order/tools/time-to-red.py
  - .planning/phases/221-ci-names-and-order/tools/reorder-ci-jobs.py
findings:
  critical: 0
  warning: 6
  info: 7
  total: 13
status: issues_found
---

# Phase 221: Code Review Report

**Reviewed:** 2026-09-29T15:12:54Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

The scope was `git diff 9ca43996..HEAD` over the seven source paths, plus the two 221 tools. The order contract (`parsed_job_order/1` and `ci_order_errors/1`) is solidly fail-closed. Duplicate job ids trip `order-reader`, jobs-level merge keys trip `order-merge-key`, and `needs` fails in block, flow, quoted, case-varied and merge-key (`<<: {needs: [...]}`) spellings. Each of these was re-probed. The alls-green wiring rules in `required_gate_errors/1` hold for the spellings the plan listed. `time-to-red.py check` reproduces the pinned literal: it exits 0 with "time-to-red order matches".

Four holes were proven by calling the real contract functions, copied unmodified apart from `defp` to `def`, from a scratch script outside the repo:

- A verify-test `strategy.matrix.exclude` passes every contract. GitHub would then post a different set of checks than the roster claims, and the latest lane would be silently dropped.
- A second workflow can post a `CI required` check through an expression-valued `name:`, and the uniqueness rule does not see it.
- The evaluator doc rule is line-local, so any hard-wrapped hex.pm claim passes it.
- Two gate sub-rules (the SHA pin, and the gate's own name or strategy) have no mutation control that isolates them.

On truthfulness, one ci.yml comment still says the browser job's name is "byte-identical to its pre-split value", and the pinned `Dependency audit (all lockfiles)` name overstates what the job audits.

No BLOCKER: every hole needs a deliberate edit to exploit, and today's ci.yml is correct. This follows the 220 convention, which filed contract bypasses as WARNING.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: A verify-test `matrix.exclude` drops a lane, and no contract notices (name-static, roster, voting lanes)

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1322` (`name_static_errors/2`), `:1388` (`posted_check_names/2`), `:2910` (`composed_check_names/1`). The ci.yml anchor is `.github/workflows/ci.yml:597`.

**Issue:** `name_static_errors/2` and `roster_errors/3` derive the posted verify-test names from `composed_check_names/1`. That function reads the raw `lane: [...]` line and never considers `strategy.matrix.exclude`. Take this valid-YAML edit:

```yaml
        lane: [min, current, latest]
        exclude:
          - lane: latest
```

With it, GitHub runs and posts only `Build and test (min)` and `Build and test (current)`. The `latest` lane disappears, but `ci-required` still sees `verify-test` as a success. Probed against the real functions, all of the following return `[]`, and `composed_check_names` still returns all three names:

- `check_name_errors/2`
- `voting_lane_errors/1`
- `required_gate_errors/1`
- `ci_order_errors/1`
- `verify_test_matrix_errors/3`

A grep of `test/` finds no reader that handles a matrix `exclude`. So the CONTRIBUTING claim at `CONTRIBUTING.md:906`, that the parity test "keeps this list equal to the names GitHub posts, so it cannot drift", is false for this spelling. This is the phase 220 lesson again: a raw-text reader that a valid YAML spelling routes around.

**Fix:** Derive the posted names from the parsed matrix and fail closed on any shape the contract does not model:

```elixir
matrix = yaml_get_in(parsed_job(parsed_doc(ci_text), "verify-test"), ["strategy", "matrix"])

extra_keys =
  (matrix || %{}) |> Map.keys() |> Enum.map(&yaml_key/1) |> Kernel.--(["lane", "include"])

if extra_keys != [] do
  ["job=verify-test rule=name-static: unmodelled matrix keys #{inspect(extra_keys)} " <>
     "(exclude changes the posted names)"]
end
```

Add a mutation control that inserts `exclude: [{lane: latest}]` and expects `rule=name-static`, or a new `rule=matrix-shape`.

### WR-02: A second workflow can post `CI required` through an expression-valued `name:` (gate-name uniqueness bypass)

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1709-1731`

**Issue:** `gate_name_errors/3` counts carriers with `yaml_get(other, "name") == "CI required"`, which is plain string equality on the raw scalar. A job in any other workflow with `name: ${{ 'CI required' }}` or `name: ${{ format('CI {0}', 'required') }}` posts a check run named exactly `CI required`, but is not counted. Both spellings were probed: `required_gate_errors/1` returns `[]` with such a `zz-spoof.yml` added.

`.github/rulesets/main.json` pins the context by name only (`{ "context": "CI required" }`, with no `integration_id`). A spoof check is therefore the threat this rule exists to stop, and it only catches the literal spelling. The spoof control at `:714` uses the literal name, so it cannot notice the gap.

**Fix:** Treat any job name that contains `${{` in a non-ci.yml workflow as a potential carrier. Flag it if it mentions `ci` and `required` case-insensitively, or, stricter, ban expression-valued job names in other workflows outright. Add a control that uses `name: ${{ 'CI required' }}`. Separately, consider pinning `integration_id` for the GitHub Actions app in the ruleset. That does not stop same-app spoofs, but it closes non-Actions status posters.

### WR-03: Gate mutation controls share `rule=gate-step` / `rule=gate-name`, so the SHA-pin and own-name/strategy sub-rules are untested

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:693-715` (controls), `:1669-1686` (`gate_step_shape_errors/1`), `:1709-1731` (`gate_name_errors/3`)

**Issue:** Each control asserts only that a fragment appears somewhere in the error list:

- `step if: false` fires the `if`/`run` guard.
- `uses replaced by run` fires the same guard (a `run` key is present) and the pin.
- `second CI required job` fires only the `unique` half of gate-name.

If the `pin` branch of `gate_step_shape_errors/1` were deleted, both gate-step controls would stay green. `uses: re-actors/alls-green@release/v1` would then pass, which is a mutable tag on the sole required-check decision. The same is true for the `own` branch of `gate_name_errors/3`: no control renames the gate or adds a `strategy` to it. Both sub-rules do work today; a probe of a tag pin and of a gate `strategy` reported the expected errors. But no control proves that each branch is live, which is the standard the phase set for SC-4.

**Fix:** Give each branch a distinct fragment, such as `rule=gate-pin`, `rule=gate-step-guard`, `rule=gate-name-own` and `rule=gate-name-unique`. Then add controls for the following, each asserting its own fragment:
- `uses: re-actors/alls-green@release/v1`
- `uses: evil/alls-green@<40 hex>`
- a `strategy: {matrix: {x: [1]}}` added to ci-required

### WR-04: `evaluator_doc_errors/1` is line-local, so any hard-wrapped hex.pm claim passes

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1457-1472`

**Issue:** The rule fires only when the evaluator token and `hex.pm` appear on the same physical line. The repo's Markdown is hard-wrapped, so the natural way the false claim comes back splits it across lines. For example:

```
- `mix verify.hex_evaluator` resolves threadline
  from hex.pm, not a path dep.
```

Probed: `evaluator_doc_errors/1` returns `[]` for that addition. The rule also misses the claim phrased without the literal task token ("the Hex evaluator", `hex_evaluator`) or the host ("the public Hex registry", `hexpm`). The single control appends a one-line claim, so it cannot notice the gap.

**Fix:** Scan per paragraph, or over a sliding window of 2-3 joined lines, instead of per line. Widen the tokens to `~r/hex[ _.-]?evaluator/i` and `~r/hex\.?pm|public hex registry/i`. Add a wrapped-claim control.

### WR-05: ci.yml comment says the browser job's name is "byte-identical to its pre-split value", but 221 renamed it

**File:** `.github/workflows/ci.yml:1045-1047`

**Issue:** The comment inside `verify-example-browser` reads: "This job's `name:` is byte-identical to its pre-split value on purpose — GitHub matches required checks on NAME, and this job stays inside `ci-required`'s needs list and continues to vote." Plan 03 changed the name from `Example app browser E2E (Playwright)` to `Example app browser E2E (2 projects)`, which the name contract pins. So the comment is now false.

It also tells a reader that renaming the job would break a name-matched required check. The job is not a required context; only `CI required` is. That is the misconception DX-01's rename relied on being absent. `name_retired_errors/3` scans ci.yml comments only for quoted retired names, so it cannot catch this paraphrase.

**Fix:** Replace the sentence. For example: "The branch-protection context is `CI required` alone. This job's `name:` is free to change, and is pinned only by the 221 name contract (`@ci_check_names`); it votes through `ci-required`'s needs list."

### WR-06: `Dependency audit (all lockfiles)` is pinned as the truthful name, but the job audits only the three Mix lockfiles

**File:** `.github/workflows/ci.yml:162`, `test/threadline/ci_workflow_parity_contract_test.exs` (`@ci_check_names`, `"verify-deps-audit"`), `CONTRIBUTING.md:893`

**Issue:** D-01 says a name says what the job proves, and SC-1 pins every name byte-exact. `bin/verify-deps-audit` audits `.`, `bench` and `examples/threadline_phoenix` with `mix hex.audit`. The tracked `examples/threadline_phoenix/e2e/package-lock.json` is never audited: `git grep "npm audit"` outside `.planning` finds nothing. A green `Dependency audit (all lockfiles)` therefore claims npm coverage that does not exist. The name predates 221, but 221 re-certified and froze it (NAME_HISTORY lists it as unchanged), and CONTRIBUTING's own job table at `:656` names exactly three `mix.lock` files.

**Fix:** Rename the job to `Dependency audit (Mix lockfiles)`, or `(root, bench, example)`. Update `@ci_check_names`, the CONTRIBUTING roster and `NAME_HISTORY` in one commit, and record the second era boundary. Alternatively, add an `npm audit --omit=dev` step for the e2e lock so the name becomes true.

## Info

### IN-01: The `name-verb` rule is a three-word denylist, and two pinned names lead with verbs

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1340-1344`

**Issue:** D-01 says "No leading verb". `name_verb_errors/2` rejects only `Run `, `Check ` and `Verify `, while the pinned set includes `Build and test` and `Compile without optional deps`. `Build and test` also names what ran rather than what is proven, which is the exact contrast D-01 draws with peer projects. The rule is redundant with `name-exact` for existing ids, so this is a wording and honesty issue, not a gap.

**Fix:** Either record the D-02 exception in the rule's comment ("Build/Compile are allowed as subject nouns here") or rename, for example `Test suite` or `Tests (compile, xref, suite)`.

### IN-02: `required_gate_errors/1` silently skips sibling workflows that do not parse

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1712`

**Issue:** `{:ok, doc} <- [parse_yaml(text)]` drops unparseable non-ci.yml files from the `CI required` carrier scan. Probed: adding a broken `zz-broken.yml` gives `[]`. The suite as a whole stays closed, because `voting_lane_errors/1` reports `rule=yaml-parse` for every workflow. Still, `required_gate_errors/1` is not self-contained fail-closed the way its comment and the ci.yml-only yaml-parse control suggest.

**Fix:** Emit `rule=yaml-parse` for any unparseable workflow inside `gate_name_errors/3`, and add a control for it.

### IN-03: `rule=order-reader` has no mutation control

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1197-1211`

**Issue:** No control in `moving or chaining jobs turns the order contract red (D-10)` reaches the reader-disagreement or duplicate-id branch. The branch works: a probe with a duplicated `verify-format` block reports `rule=order-reader`. But deleting the branch would leave every test green, because a duplicate also trips `rule=order:`.

**Fix:** Add a "duplicate job id" control that asserts `rule=order-reader`.

### IN-04: `parsed_job_order/1` and `parsed_job_keywords/1` duplicate the keyword-mode read

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1143-1160`, `:1429-1446`

**Issue:** The two functions repeat the same try/rescue/catch and the same `with` over the top-level `jobs` entry. A future fix to one, such as memoizing like `parse_yaml/1` or changing the jobs-key match, can miss the other.

**Fix:** Implement `parsed_job_order/1` as `parsed_job_keywords/1 |> map keys |> Enum.reverse()`.

### IN-05: `time-to-red.py job_id/1` applies the lane-suffix fallback to every name, not just matrix names

**File:** `.planning/phases/221-ci-names-and-order/tools/time-to-red.py:146-152`

**Issue:** `name.startswith(base + " (")` is tried for every `NAME_HISTORY` base. A future job named, say, `Formatting (docs)` or `Credo (strict) (umbrella)` would be attributed to an existing id instead of returning `?`. That defeats `compute_order`'s exit-1 guard on unknown names and silently merges two jobs' samples.

**Fix:** Restrict the fallback to the matrix bases:

```python
MATRIX_BASES = ("Run test suite", "Build and test")
for base in MATRIX_BASES:
    if name.startswith(base + " ("):
        return NAME_HISTORY[base]
```

### IN-06: `time-to-red.py` era-boundary metadata: stale comment, and a RENAME_SHA on a deleted branch

**File:** `.planning/phases/221-ci-names-and-order/tools/time-to-red.py:53-62`

**Issue:** The `MAIN_MERGE_SHA` comment still says it is "Set in the first planning sync after the maintainer squash-merges", but plan 04 set it at landing.

`RENAME_SHA` (`327165f0…`) is a land-branch commit. 221-04 records the remote branch as deleted, and locally it is reachable only through the stale `remotes/origin/land/v1.43-221` ref. After a `git fetch --prune` and a gc it will not resolve. The squash on main (`67572c12`) and the milestone-branch commit (`194eee6a`) are the durable anchors.

**Fix:** Update the comment. Also record `194eee6a` as the durable milestone-branch rename SHA next to `RENAME_SHA`, or note that `RENAME_SHA` is informational and may not resolve.

### IN-07: `reorder-ci-jobs.py prove` never checks the resulting order, and assumes `jobs:` is the last top-level key

**File:** `.planning/phases/221-ci-names-and-order/tools/reorder-ci-jobs.py:50-56`, `:113-149`

**Issue:** `prove` checks only content equality: the line multiset and the `{id: chunk}` dict. An `apply` that wrote chunks in the wrong order would still "prove". The order is enforced elsewhere by `ci_order_errors/1`, so this is only a tool-honesty gap.

Separately, `split_jobs/1` treats everything after `\njobs:\n` as job chunks. A top-level key after `jobs:` would be absorbed into the last chunk and moved with it without warning.

**Fix:** In `prove`, assert `list(chunks(after)) == TARGET`. In `split_jobs`, fail if any line after `jobs:` starts at column 0 with a non-comment character.

---

_Reviewed: 2026-09-29T15:12:54Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
