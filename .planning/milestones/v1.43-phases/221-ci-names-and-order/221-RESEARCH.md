# Phase 221: CI Names and Order - Research

**Researched:** 2026-09-28
**Domain:** GitHub Actions workflow hygiene (`.github/workflows/ci.yml`) plus ExUnit contract tests that read parsed YAML
**Confidence:** HIGH. Every load-bearing claim below was probed in this session: a scratch worktree ran the real contract suites against a moved ci.yml and a renamed ci.yml, and a `mix run` probe exercised the proposed contract functions against every mutation control.

## Summary

CONTEXT D-01..D-15 hold up against the code, with five corrections and additions the planner needs:

1. **CONTRIBUTING has a quote that CONTEXT missed.** Line 669 says a docs break "shows as a red "Bump rehearsal (next minor)" job".
2. **Three D-02 names do not change.** `Compile without optional deps`, `Dependency audit (all lockfiles)` and `Repo hygiene (no machine-local paths)` stay as they are, so the rename touches 10 job `name:` lines, not 13.
3. **One D-02 name is longer than D-01's "about 40".** `Next-minor release rehearsal (docs + contracts)` is 47 characters. A length contract must allow at least 47 (use 48).
4. **CONTEXT's p50 figures are `statistics.median`, not the project's nearest-rank arithmetic.** With the 219 `summarize-ci.py` arithmetic the numbers are format 17, hex-evaluator 70, bump-rehearsal 151, capture 391 and browser 565 seconds. The **order is identical** under both.
5. **Only 5 of the 10 cited runs are committed** under `219/raw/ci/runs/`. The 221 tool has to collect the other 5.

Both YAML edits are safe against the existing suites. **The order-only move breaks nothing:** in the scratch tree, 71/71 CI-contract tests and 130/130 other ci.yml-reading tests passed. **The D-02 rename breaks exactly 5 tests,** all through literal name anchors: 4 in the parity test (`name: Run test suite`) and 1 in the topology test (the evaluator name at 1099-1100). Across `test/threadline/` that is 2423 tests with 5 failures.

The proposed `ci_order_errors/1` and `required_gate_errors/1` both return `[]` on the live tree and catch every D-10/D-11 mutation control. Moving jobs leaves the parsed maps `==`, which proves every existing map-based contract is blind to order. Only the keyword-list reader can see order.

**Primary recommendation:** Build the contracts on `YamlElixir.read_from_string!(text, maps_as_keywords: true)` with the reversal and guards shown below. Do the move with a chunking script and prove it three ways: parsed `==`, line-multiset equality, and chunk-multiset equality. `git diff --color-moved` does not prove the move, because short lines get recoloured as plain adds and deletes. Then rename in one commit, whose name contract is derived from parsed ci.yml.

## User Constraints (from CONTEXT.md)

<user_constraints>
### Locked Decisions
D-01..D-15 in `.planning/phases/221-ci-names-and-order/221-CONTEXT.md` are locked. Verbatim summary of the load-bearing ones:

- **D-01:** Names lead with the subject and say what is proven. No leading verb ("Run", "Check"). No internal jargon ("Tier A", "lane"). At most about 40 characters. A parenthetical is used only for a lane or scope qualifier.
- **D-02:** The name set (ids are unchanged): verify-release-shape `CHANGELOG matches version`; verify-repo-hygiene `Repo hygiene (no machine-local paths)`; verify-format `Formatting`; verify-deps-audit `Dependency audit (all lockfiles)`; verify-compile-no-optional `Compile without optional deps`; verify-hex-evaluator `Hex package install (rehearsal registry)`; verify-pgbouncer-topology `Tests through PgBouncer (transaction mode)`; verify-credo `Credo (strict)`; verify-bump-rehearsal `Next-minor release rehearsal (docs + contracts)`; verify-dialyzer `Dialyzer (full optional build)`; verify-test `Build and test`, which GitHub posts as `Build and test (min)`, `(current)` and `(latest)`; verify-capture `Capture evidence byte-stable`; verify-example-browser `Example app browser E2E (2 projects)`; ci-required **CI required** (byte-exact, unchanged).
- **D-03:** The evaluator name is false today and gets fixed, along with the step name "Verify Hex-published threadline adopt path". The planner verifies the mode logic.
- **D-04:** `name:` stays the first key under each job id. verify-test's `name:` stays static (no `${{ }}`). Matrix `lane` values are unchanged. Workflow `name: CI` never changes. Other workflows keep their names, except that browser-full may become "Example app browser E2E (all projects)" while its `TITLE_PREFIX` stays. Every name reference is updated in the same commit. Moduledoc prose that cites historical runs stays historical.
- **D-05:** SC-2 is about triage readability, not speed. No success claim may say the reorder makes red faster.
- **D-06:** Order by job-duration p50 over the 10 cited runs; ties are broken by max, then by id. The order is release-shape, repo-hygiene, format, deps-audit, compile-no-optional, hex-evaluator, pgbouncer-topology, credo, bump-rehearsal, dialyzer, test, capture, example-browser, then ci-required last. Re-derive only on a roster change or at a milestone re-measure.
- **D-07:** No `needs:` preflight chain.
- **D-08:** Two commits: an order-only move (parsed maps `==`), then the one-pass rename plus the CONTRIBUTING quotes. Comments travel with their block. The header roster is reordered. `ci-required`'s `needs:` list is untouched.
- **D-09:** `parsed_job_order/1` via `maps_as_keywords: true` with the result reversed. Guard 1: the key set equals the `parsed_jobs/1` keys. Guard 2: a fixture `a,b,c` reads back as `[a,b,c]`. Fail closed on a jobs-level `<<`.
- **D-10:** `ci_order_errors/1`, rules (a) exact order, (b) unknown id means "place it by measured p50", (c) no `needs` key except on ci-required (case-folded), (d) ci-required last. Four mutation controls.
- **D-11:** `required_gate_errors/1` in `ci_workflow_parity_contract_test.exs`, rules gate-if, gate-step, gate-inputs (the `with` keys are exactly `["jobs"]`), gate-jobs-input, gate-name and job-ids (a frozen 14-id `@ci_job_ids`), each with its mutation control, plus a comment positive control. Phase 222 escape hatch as written.
- **D-12:** Out of scope, because they fail closed: `runs-on`, `timeout-minutes`, `permissions`, and workflow-level `paths`/`branches-ignore`/`types`.
- **D-13:** A frozen `NAME_HISTORY` (old name to id) in a 221 tool. Record the rename SHA and the first post-rename run ID. The shipped REMEASURE docs are frozen.
- **D-14:** A small 221 tool regenerates `@time_to_red_order`. Tests never touch the network. A comment above the attribute cites the metric, the runs and the command.
- **D-15:** Land by cherry-picking onto a **new** land branch from main, carrying `d7d44fd1`, `2099d17b`, `9ebd6af5` and `997ad1d0`. Push, PR and dispatch only under an explicit maintainer grant that names each action. Record the PR run ID as the era boundary.

### Claude's Discretion
- The plan split. CONTEXT suggests contracts, then the move, then the rename, then landing.
- Whether `ci_required_block/0` and the release_control_plane split move onto `parsed_job/2`.
- Final evaluator job and step wording, after verifying the mode logic (done below).
- Whether browser-full takes the symmetric name.

### Deferred Ideas (OUT OF SCOPE)
- Contracting workflow-level `on:` filters.
- Renaming non-ci.yml workflows beyond the optional browser-full symmetry.
- Tiered-band ordering (option C).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01 | A contributor can tell from a red check's name what failed, without opening logs. Names rewritten once (including the evaluator name, false on PRs); YAML ordered by time-to-red with no `needs:` chain; ids and `CI required` unchanged; CONTRIBUTING quotes updated in the same commit. | §Name reference inventory (every file and line, and which break); §Ordered parsed-YAML reader; §Order-only move procedure; §Evaluator modes; §Gate-wiring contract; §Measurement tool; §Validation Architecture |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Use `mix verify.*` / `mix ci.*` named entrypoints in CI, docs and plan verification commands.
- **Stable CI job IDs:** keep job `id:` fields immutable and evolve `name:` freely. This phase is exactly that contract.
- **Honest default tests:** never silently exclude suites from `mix test`. New contracts go in the default suite, untagged.
- **Doc contract tests:** README, guides and CONTRIBUTING stay aligned through test assertions. The rename needs a doc-contract test.
- **Zero human verification by default:** automate every check. Hand the maintainer only push, PR and dispatch (D-15).
- `state.begin-phase` takes flags on gsd-core v1.14.0, and STATE.md/ROADMAP.md must be hand-checked after `state.*` handlers.
- From memory (standing rules): never `git add .planning/` wholesale; repo-hygiene now scans tracked `.planning/`, so no home-path shapes or usernames in committed prose or tool output; `ci.all` red at Dialyzer usually means a PLT cache miss; executors must be told not to move protected files or bypass hooks; dispatch CI sequentially; do not `--no-verify`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Check names shown on PRs | CI config (`ci.yml` job `name:`) | GitHub (composes matrix suffix) | GitHub posts `name` + ` (lane)` for a static name with a matrix base axis |
| Job order readability | CI config (YAML key order) | — | D-05: no runtime effect; readers of ci.yml and run sidebar only |
| Order / gate / id pins | ExUnit contract tests (`test/threadline/ci_workflow_parity_contract_test.exs`) | yaml_elixir parser | Parsed-YAML helpers live there (D-11) |
| Doc alignment | CONTRIBUTING.md + doc-contract assertions | — | CLAUDE.md doc-contract convention |
| Time-to-red measurement | `.planning/phases/221-*/tools/` Python (stdlib) + `gh api` GET | committed raw JSON | Tests stay offline (D-14) |
| Required-check identity | `.github/rulesets/main.json`, `bin/verify-branch-protection`, `bin/observe-main-ci` | ci-required `name:` | Byte-exact `CI required`; untouched |

## Standard Stack

No new packages. Everything is in-repo.

| Library / tool | Version (verified) | Purpose |
|---|---|---|
| yaml_elixir | 2.11.0 `[VERIFIED: mix.lock:47 "yaml_elixir": {:hex, :yaml_elixir, "2.11.0", ...}; mix.exs:126 {:yaml_elixir, "~> 2.11.0", only: :test, runtime: false}]` | parse ci.yml (map mode for structure, keyword mode for order) |
| yamerl | 0.10.0 `[VERIFIED: mix.lock:46]` | underlying parser |
| Elixir / OTP (local) | 1.17.3 / OTP 27 `[VERIFIED: elixir --version]` | test runtime |
| Python | 3.14.4 `[VERIFIED: python3 --version]` | 221 tool (stdlib only, like 214/218/219 tools) |
| gh | 2.101.0 `[VERIFIED]`; read-only `gh api .../runs/<id>/jobs` worked this session | collect run JSON |
| jq | 1.7.1 `[VERIFIED]` | only if the collector is reused as a shell script |

## Package Legitimacy Audit

Not applicable. This phase installs no external packages.

## Name Reference Inventory (focus 1)

The current job names, read from ci.yml this session `[VERIFIED: .github/workflows/ci.yml, line of each name:]`:

| id | line | current `name:` (verbatim) | D-02 new | changes? |
|---|---|---|---|---|
| verify-format | 54 | `Check formatting` | `Formatting` | yes |
| verify-credo | 119 | `Run Credo (strict)` | `Credo (strict)` | yes |
| verify-dialyzer | 145 | `Dialyzer (current toolchain)` | `Dialyzer (full optional build)` | yes |
| verify-compile-no-optional | 297 | `Compile without optional deps` | same | **no** |
| verify-test | 334 (after an 18-line comment block; still the first key) | `Run test suite` | `Build and test` | yes |
| verify-hex-evaluator | 506 | `Hex evaluator smoke (threadline from hex.pm)` | `Hex package install (rehearsal registry)` | yes |
| verify-example-browser | 545 | `Example app browser E2E (Playwright)` | `Example app browser E2E (2 projects)` | yes |
| verify-capture | 701 | `Tier A capture lane (byte-stable evidence)` | `Capture evidence byte-stable` | yes |
| verify-pgbouncer-topology | 854 | `PgBouncer transaction topology` | `Tests through PgBouncer (transaction mode)` | yes |
| verify-release-shape | 964 | `Release metadata (version / changelog)` | `CHANGELOG matches version` | yes |
| verify-bump-rehearsal | 974 | `Bump rehearsal (next minor)` | `Next-minor release rehearsal (docs + contracts)` | yes |
| verify-deps-audit | 1025 | `Dependency audit (all lockfiles)` | same | **no** |
| verify-repo-hygiene | 1053 | `Repo hygiene (no machine-local paths)` | same | **no** |
| ci-required | 1086 | `CI required` | same (byte-exact) | **no** |

A step name also changes (D-03): ci.yml:541, `- name: Verify Hex-published threadline adopt path`.

### A. Tests that BREAK on the rename

These are proven by the scratch-tree run: only ci.yml was renamed, and `mix test test/threadline/` gave 2423 tests, 5 failures `[VERIFIED: scratch run]`.

| File:line | What it is | Why it breaks | Fix |
|---|---|---|---|
| `test/threadline/ci_workflow_parity_contract_test.exs:241-242` | `~r/^\s*name: Run test suite\s*$/m` | literal name | Change to `Build and test`, or better, assert the parsed verify-test name equals the new literal and contains no `${{` |
| same file `:445,449-450,453,458,463,473-474,479-480` | "latest lane documented" test: CONTRIBUTING contains `Run test suite (latest)`; composed name; comment-removal control anchored on the ci.yml comment `# "Run test suite (latest)". Keys carried only via \`include\``; mutation anchors `"    name: Run test suite\n"` | literal name in anchors and in the ci.yml comment (ci.yml:317-318 also quotes the old names) | Update all anchors. **Also update the ci.yml verify-test comment at 317-318** (`"Run test suite (min)", "Run test suite (current)" and "Run test suite (latest)"`), or the comment-removal control's `refute uncommented == job` fails |
| same file `:487-489` | CONTRIBUTING List 2 carries `Run test suite (min/current/latest)` | breaks when CONTRIBUTING is edited | Generalise (see the name contract below) |
| same file `:504` | `job_header = "    name: Run test suite\n"`, the anchor for 3 voting-lane mutation controls | the control stops changing input ("control did not change the input") | new name |
| same file `:726-727` | pg-tag control "prefixed beta image as a job container shorthand", anchored on `"    name: Run test suite\n"` | same | new name |
| `test/threadline/ci_topology_contract_test.exs:1099-1100` | "evaluator mode forced to published in ci.yml", anchored on `"  verify-hex-evaluator:\n    name: Hex evaluator smoke (threadline from hex.pm)\n"` | literal name | Make it name-agnostic: replace `"  verify-hex-evaluator:\n    name: "` with `"  verify-hex-evaluator:\n    env:\n      THREADLINE_HEX_EVALUATOR_MODE: published\n    name: "` (same style as the `job-level if` controls at 1086-1095) |

### B. Test text that does NOT break (inline synthetic fixtures). Update it for consistency, per D-04.

- `ci_workflow_parity_contract_test.exs:4590` (`name: Run test suite`), `:4662` (`PgBouncer transaction topology`), `:4755` (`Example app browser E2E (Playwright)`) and `:4785` (`Tier A capture lane (byte-stable evidence)`) are fixture ci.yml fragments for the build-cache rules. They are never compared with live names. The build-cache suite stayed green with the live ci.yml renamed.

### C. Prose (historical run citations). Leave as-is, per D-04.

- `test/threadline/operator_surface/policy_show_mix_test.exs:22` (comment: `` `Run test suite (min)` failing with 102 cascading``)
- `test/threadline/storage_schema_call_site_contract_test.exs:7` (moduledoc: ``CI run 33183920952's `PgBouncer transaction topology` job``)
- `test/threadline/optional_deps_contract_test.exs:8` (the name is unchanged anyway)
- `CHANGELOG-GENERATED.md:65` (commit subject)
- `.planning/STATE.md:420,423`, `.planning/MILESTONES.md`, and the shipped 214/218/219 REMEASURE docs and tools (frozen, D-13)

### D. CONTRIBUTING.md (must change in the rename commit) `[VERIFIED: read CONTRIBUTING.md 30-45, 730-745, 810-850, 875-905; grep for line 669]`

| Line | Current text | Action |
|---|---|---|
| 39 | ``CI also runs a `latest` lane, `Run test suite (latest)`, on the newest stable`` | `Build and test (latest)` |
| **669** (missed by CONTEXT) | `...a docs break now shows as a red "Bump rehearsal (next minor)" job.` | new bump name |
| 739 | ``(23 seconds) measured in the `Run test suite (current)` job of run`` | This is a historical run citation. **Recommend the id form**, "measured in the `verify-test` current-lane job of run", so a retired-name ban can cover all of CONTRIBUTING with no allowlist. The same applies to the ci.yml verify-dialyzer comment at 149 (`"Run test suite (current)" job of run 36258719902`) |
| 821 | ``so `Run test suite (min)` and `Run test suite (latest)` never print it.`` | new names |
| 844 | ``any of these fails `Run test suite`.`` | `Build and test` |
| 883-898 | "Branch protection (maintainers)" roster: **7 bullets only** (format, credo, test ×3, pgbouncer, release-shape) in the form `- <name> (\`<id>\`[ <lane> lane])` | Rewrite to list **all 15 posted checks** (13 jobs, with test ×3) in YAML order, derived and pinned by the name contract |

### E. Non-test code (by exact name)

- `CI required` only: `.github/rulesets/main.json:16`, `bin/verify-branch-protection:25`, `bin/observe-main-ci:88-89`. **Unchanged.**
- No `bin/*`, `scripts/`, `lib/` or `mix.exs` file references any other job name `[VERIFIED: grep over git ls-files excluding .planning/]`. `bin/browser-full-projects` reads ci.yml `--project` flags only.
- `.github/workflows/release.yml:579` (`Smoke test the published release (threadline from hex.pm)`) is **true** there, because release.yml sets `THREADLINE_HEX_EVALUATOR_MODE: published` at :592. Leave it.
- `.github/workflows/browser-full.yml:45`, `name: Example app browser E2E — full project set`. The optional D-04 symmetry rename is safe: `TITLE_PREFIX` at :171/:202 is the pinned string (`browser_full_projects_contract_test.exs:618`), not the job name.
- `branch-protection.yml:27`, `environment-protection.yml:34` and `community-health.yml:38` key on `workflows: ["CI"]`, the workflow name, which is unchanged.

### F. `.planning` measurement tools

- `219/tools/summarize-ci.py` `workflow_jobs()` maps name to id from the **current** ci.yml. Its regexes are `^  ([A-Za-z0-9_-]+):\s*$` and the first `^    name:` after the header. This is why `name:` must stay the first 4-space key (D-04). After the rename, pre-221 run names map to `"?"`.
- `219/tools/remeasure-219.py:104,117-138,125` hardcode `"Run test suite (current)"` and `"Run test suite (min)"`. `218/tools/remeasure-218.py:58,60-62` hardcode `UNRELATED_ADDED` names and `REMOVED_IDS`. All are frozen; do not edit (D-13).
- No test, bin script or workflow invokes these tools `[VERIFIED: grep test/ bin/ mix.exs .github/]`.

### G. Text-scan helpers that assume position or locate by name (focus 5)

| Helper | Assumption | Effect of 221 |
|---|---|---|
| `ci_topology_contract_test.exs:373` `ci_required_block/0` (`String.split(yaml, "\n  ci-required:\n")`, taking the tail) | ci-required is the **last** job (its own comment says so) | Still true. D-10(d) now pins it. Optional: move it onto `parsed_job/2`, but the topology test has no parsed helpers, so leave it |
| `release_control_plane_contract_test.exs:90-93` (same split) | same | same; leave it |
| topology `:573` `ci_required_needs_from/1`, `:585` `workflow_job_ids/1`, `:592` `workflow_job/2` (lowercase-id regexes) | none on order | Unaffected. **Do not** use `workflow_job_ids/1` for new pins (D-09) |
| topology `:619` `workflow_step(yaml, name)` returns the **first** step with that name in the whole file | order-sensitive when a step name repeats across jobs | The callers use unique names (`Live Dialyzer slice proof (fails closed)`, `Report exact PLT cache hit`, `Assert byte-stable regeneration...`), so it is safe after the move |
| topology `:1086-1095,1099` mutation anchors `"  <id>:\n    name: "` | `name:` is the first key | Keep name first (D-04) |
| topology `:731+` header regex `^# Job id contract[^\n]*\n#[^\n]*verify-bump-rehearsal` and `:822` `header_roster/1` (`String.split(line, ", ")`) | roster is **one line**, `, `-separated, on line 2 | Reorder within the single line only |
| parity `:145` `ci_header_comment_keys/0` (whole leading `#` block) | none on order | Unaffected |
| parity `:2106,2118` `workflow_jobs/1`, `workflow_job/2`: a block runs from a header to the next header, so **column-2 comments above a job belong to the previous job's text block** | none on order | After the move, different jobs' text blocks carry different trailing comments. No current rule reads them (proven by the green scratch run) |
| parity `:2141` `composed_check_names/1` (text; `    name:` and `        lane:`) | static name and `lane: [..]` inline list | Keep both shapes |
| topology `:842` `String.contains?(yaml, "# Removed: #{id}")` | whole-file | order-independent |

## Architecture Patterns

### Data flow

```
gh api runs/<id>/jobs (GET, 10 cited runs) ──> 221/raw/ci/runs/<id>.json (committed)
                                                    │
                     221 tool `order` (219 arithmetic, NAME_HISTORY name→id)
                                                    │
                     prints @time_to_red_order literal + cited p50/max table
                                                    │
         (human-free) executor pastes literal into parity test ──> ci_order_errors/1
                                                    │
 ci.yml text ──> maps_as_keywords parse ──> reversed jobs keys ──> order rules (a-d)
            └──> map parse (parse_yaml) ──> parsed_jobs/parsed_job ──> gate rules, @ci_job_ids, name rules
                                                    │
                               ExUnit (default `mix test`, offline) ──> CI verify-test
```

### Pattern 1: Ordered parsed-YAML reader (focus 2), verified

The probe ran `MIX_ENV=test mix run --no-start <probe>` against yaml_elixir 2.11.0 `[VERIFIED: probe output]`:

```
jobs keys as returned: ["d", "c", "b", "a"]        # input order a, b, "c" (quoted), d # trailing comment
reversed:              ["a", "b", "c", "d"]
dup kw:  [{"jobs", [{"a", [{"x", 2}]}, {"a", [{"x", 1}]}]}]   # duplicates survive in keyword mode
dup map: %{"jobs" => %{"a" => %{"x" => 1}}}                   # map mode keeps the FIRST
merge key: [{"jobs", [{"a", [{"y", 2}]}, {"<<1", "x"}]}, ...] # `<<` becomes "<<N", no merge in kw mode
ci.yml order: ["verify-format", "verify-credo", "verify-dialyzer", "verify-compile-no-optional",
 "verify-test", "verify-hex-evaluator", "verify-example-browser", "verify-capture",
 "verify-pgbouncer-topology", "verify-release-shape", "verify-bump-rehearsal",
 "verify-deps-audit", "verify-repo-hygiene", "ci-required"]
set eq: true   (keyword keys == Map.keys of plain parse)
```

The mechanism is in `deps/yaml_elixir/lib/yaml_elixir/mapper.ex` `[VERIFIED: read lines 70-95]`. `maps_aggregator/1` returns `&[{&2, &3} | &1]` (prepend) when `maps_as_keywords` is set, and `&Map.put_new/3` otherwise. `key_for("<<", _)` returns `"<<#{System.unique_integer([:positive, :monotonic])}"`.

Two consequences follow. Guard 1 must also check **no duplicates**, because a set comparison would miss them. And the `<<` guard is a `String.starts_with?(id, "<<")` check.

The helper below goes into `ci_workflow_parity_contract_test.exs`, next to `parse_yaml/1`. It was probed with this exact logic; the live tree returns `[]` after the move.

```elixir
# Job ids in YAML order. The map reader (parse_yaml/1) cannot see order: moving
# jobs leaves the parsed map `==`. yaml_elixir 2.11.0's keyword aggregator
# prepends each pair (deps/yaml_elixir/lib/yaml_elixir/mapper.ex, maps_aggregator/1),
# so the list comes back reversed; the a,b,c fixture test pins that.
defp parsed_job_order(text) do
  parsed =
    try do
      {:ok, YamlElixir.read_from_string!(text, maps_as_keywords: true)}
    rescue
      error -> {:error, Exception.message(error)}
    catch
      kind, reason -> {:error, inspect({kind, reason})}
    end

  with {:ok, doc} when is_list(doc) <- parsed,
       [jobs] when is_list(jobs) <- for({k, v} <- doc, yaml_key(k) == "jobs", do: v) do
    {:ok, jobs |> Enum.map(fn {k, _} -> yaml_key_string(k) end) |> Enum.reverse()}
  else
    {:error, message} -> {:error, "rule=yaml-parse: #{message}"}
    _ -> {:error, "rule=yaml-parse: expected exactly one top-level `jobs` mapping"}
  end
end
```

Do not add `merge_anchors: true` to the keyword parse. `merge_anchors/1` only merges `%{}` maps, so in keyword mode the `"<<N"` key survives, and the fail-closed guard relies on that `[VERIFIED: probe]`.

### Pattern 2: `ci_order_errors/1` (D-10), pure over ci.yml text

```elixir
# Regenerate: python3 .planning/phases/221-ci-names-and-order/tools/time-to-red.py order
# Metric: successful-job duration (completed_at - started_at), nearest-rank p50
# (summarize-ci.py arithmetic), verify-test = its fastest lane; ties by max, then id.
# Runs: 36502353440 36501481301 36487483472 36467068660 36465241600
#       36457705448 36456537357 36455432448 36454272684 36453043277
# Readability only: YAML order has no runtime effect (221 D-05).
@time_to_red_order ~w(verify-release-shape verify-repo-hygiene verify-format verify-deps-audit
                      verify-compile-no-optional verify-hex-evaluator verify-pgbouncer-topology
                      verify-credo verify-bump-rehearsal verify-dialyzer verify-test
                      verify-capture verify-example-browser)

defp ci_order_errors(text) do
  case parsed_job_order(text) do
    {:error, error} ->
      [error]

    {:ok, order} ->
      doc = parsed_doc(text)
      plain = doc |> parsed_jobs() |> Enum.map(&elem(&1, 0))
      expected = @time_to_red_order ++ ["ci-required"]

      guard =
        cond do
          Enum.any?(order, &String.starts_with?(&1, "<<")) ->
            ["rule=order-merge-key: a jobs-level `<<` merge key hides job order"]
          Enum.sort(order) != Enum.sort(plain) or order != Enum.uniq(order) ->
            ["rule=order-reader: keyword and map readings disagree: #{inspect(order)} vs #{inspect(plain)}"]
          true -> []
        end

      unknown =
        for id <- order, id != "ci-required", id not in @time_to_red_order,
            do: "job=#{id} rule=order-unknown: place it by measured p50 (221 D-06)"

      exact =
        if order == expected, do: [],
          else: ["rule=order: expected #{inspect(expected)}, got #{inspect(order)}"]

      last =
        if List.last(order) == "ci-required", do: [],
          else: ["rule=order-last: ci-required must be the last job"]

      needs =
        for {id, job} <- parsed_jobs(doc), id != "ci-required", yaml_field(job, "needs") != :error,
            do: "job=#{id} rule=order-needs: no preflight needs: chain (221 D-07)"

      guard ++ unknown ++ exact ++ last ++ needs
  end
end
```

Probe results for the mutation controls `[VERIFIED: probe]`. "same-map" means the plain parsed map is unchanged:

| Control | Parses | same-map | Errors |
|---|---|---|---|
| verify-format block moved to just above `ci-required:` | yes | **true** | `rule=order` |
| ci-required block moved above verify-repo-hygiene | yes | **true** | `rule=order`, `rule=order-last` |
| `needs:\n  - verify-format` (block) on verify-test | yes | — | `rule=order-needs` |
| `needs: [verify-format]` (flow) on verify-test | yes | — | `rule=order-needs` |
| `"Needs": verify-format` (quoted, case variant) | yes | — | `rule=order-needs` |
| quoted stub `"verify-extra":` appended | yes | — | `order-unknown`, `order`, `order-last` |
| jobs-level `<<: *b` | yes | — | `order-merge-key` (+ unknown, order) |
| fixture `jobs: {a,b,c}` | — | — | reads `["a","b","c"]` |

The move mutation that the probe used works directly on the text (parity `workflow_job/2`):

```elixir
fmt = workflow_job(ci, "verify-format")
moved = ci |> String.replace(fmt, "") |> String.replace("  ci-required:\n", fmt <> "  ci-required:\n")
req = workflow_job(ci, "ci-required")
moved_req = ci |> String.replace(req, "") |> String.replace("  verify-repo-hygiene:\n", req <> "\n  verify-repo-hygiene:\n")
```

Assert `parse_yaml(moved) == parse_yaml(ci)` in the test as well. That line is the proof that only the keyword reader can see order, and it keeps the control honest.

### Pattern 3: `required_gate_errors/1` (D-11)

This is probed logic. Use the file's existing `yaml_get`, `yaml_field`, `yaml_key`, `parsed_job`, `parsed_jobs`, `parse_yaml` and `all_workflows/0`.

```elixir
@ci_job_ids MapSet.new(@time_to_red_order ++ ["ci-required"])   # or a literal 14-id list (D-11 says frozen literal)

defp gate_norm(v) when is_binary(v), do: v |> String.replace(~r/\s+/, "") |> String.downcase()
defp gate_norm(_), do: nil

defp required_gate_errors(yaml_by_path) do
  ci_path = ".github/workflows/ci.yml"
  case parse_yaml(Map.get(yaml_by_path, ci_path, "")) do
    {:error, m} -> ["#{ci_path} rule=yaml-parse: #{m}"]
    {:ok, doc} ->
      job = parsed_job(doc, "ci-required")
      if_expr = gate_norm(yaml_get(job, "if"))
      if_expr = if_expr && if_expr |> String.replace_prefix("${{", "") |> String.replace_suffix("}}", "")
      steps = case yaml_get(job, "steps") do l when is_list(l) -> l; _ -> [] end

      step_errors =
        case steps do
          [%{} = step] ->
            uses = yaml_get(step, "uses")
            with_ = yaml_get(step, "with")
            keys = case with_ do %{} = m -> m |> Map.keys() |> Enum.map(&yaml_key/1) |> Enum.sort(); _ -> [] end
            (if yaml_field(step, "if") == :error and yaml_field(step, "run") == :error, do: [],
               else: ["rule=gate-step: the alls-green step carries `if` or `run`"]) ++
            (if is_binary(uses) and uses =~ ~r/^re-actors\/alls-green@[0-9a-f]{40}$/, do: [],
               else: ["rule=gate-step: the step must `uses:` re-actors/alls-green at a full SHA"]) ++
            (if keys == ["jobs"], do: [],
               else: ["rule=gate-inputs: `with` keys must be exactly [\"jobs\"], got #{inspect(keys)}"]) ++
            (if gate_norm(yaml_get(with_, "jobs")) == "${{tojson(needs)}}", do: [],
               else: ["rule=gate-jobs-input: `jobs` must be ${{ toJSON(needs) }}"])
          _ -> ["rule=gate-step: ci-required must have exactly one step"]
        end

      carriers =
        for {path, text} <- Enum.sort(yaml_by_path), {:ok, d} <- [parse_yaml(text)],
            {id, j} <- parsed_jobs(d), yaml_get(j, "name") == "CI required", do: {path, id}

      name_errors =
        (if yaml_get(job, "name") === "CI required" and yaml_field(job, "strategy") == :error, do: [],
           else: ["rule=gate-name: ci-required must be named exactly `CI required`, with no matrix"]) ++
        (if carriers == [{ci_path, "ci-required"}], do: [],
           else: ["rule=gate-name: exactly one job may be named `CI required`, got #{inspect(carriers)}"])

      ids = doc |> parsed_jobs() |> Enum.map(&elem(&1, 0)) |> MapSet.new()
      id_errors = if ids == @ci_job_ids, do: [],
        else: ["rule=job-ids: ci.yml job ids drifted: #{inspect(MapSet.symmetric_difference(ids, @ci_job_ids) |> Enum.sort())}"]

      (if if_expr == "always()", do: [], else: ["rule=gate-if: ci-required must run `if: always()`"]) ++
        step_errors ++ name_errors ++ id_errors
  end
end
```

Probe results `[VERIFIED: probe]`:

| Control | Result |
|---|---|
| live tree | `[]` |
| delete `if: always()` | `rule=gate-if` |
| `if: ${{ always() }}` (positive) | `[]` |
| step `if: false` | `rule=gate-step` |
| `uses:` replaced with `run: echo ok` | `rule=gate-step` ×2 |
| quoted `"allowed-skips": verify-test` | `rule=gate-inputs` (keys `["allowed-skips","jobs"]`) |
| `jobs: '{}'` | `rule=gate-jobs-input` |
| `# allowed-skips: verify-test` comment (positive) | `[]` |
| second workflow with a `CI required` job | `rule=gate-name` |
| rename `verify-format` → `verify-fmt` in header, key and `needs` | `rule=job-ids` (and `order-unknown`) |

**`@ci_job_ids` note.** D-11 wants a *frozen literal*, not one derived from `@time_to_red_order`. Deriving it would let one edit move both pins together. Write it as its own sorted 14-element `~w(...)` literal.

### Pattern 4: Name contract (SC-1 doc-contract). Recommended; the planner decides the exact shape.

These rules are pure and read parsed YAML plus CONTRIBUTING:

1. `@ci_check_names %{"verify-format" => "Formatting", ...}`, 14 entries. Each parsed `name` must be `===` its entry.
2. verify-test's parsed name contains no `${{`. Its composed names (`composed_check_names/1`) are exactly `["Build and test (min)", "Build and test (current)", "Build and test (latest)"]`.
3. No name starts with `Run `, `Check ` or `Verify ` (D-01 leading-verb ban). An explicit list is needed because `Build and test` starts with a verb-like word that D-02 chose.
4. Every name is ≤ 48 characters. **D-02's `Next-minor release rehearsal (docs + contracts)` is 47**, so a bound of 40 would fail the locked set.
5. No name contains `Tier A` or `lane` (D-01 jargon ban). Note: the composed suffix `(min)` is not the word "lane".
6. `name` is the first key under each job. Check it with the keyword parse: the job's keyword list, reversed, has `"name"` first. The summarize-ci parser and the topology mutation anchors depend on this.
7. CONTRIBUTING's branch-protection roster lists all 15 posted names in YAML order (derived from rules 1-2 plus `parsed_job_order/1`), each followed by `` (`<id>`...) ``.
8. **Retired-name ban:** none of the pre-221 names (`@retired_check_names`: the 10 changed names, plus `Run test suite (min|current|latest)` and `Run test suite`) appears in CONTRIBUTING.md or ci.yml, comments included. This is why the 739 and ci.yml:149/317-318 citations should move to the id form.

Mutation controls: rename one name back to its old value; add a `${{ matrix.lane }}` to the verify-test name; drop one roster bullet; reintroduce `Run test suite (current)` in a CONTRIBUTING line; put `timeout-minutes:` before `name:` on one job.

### Recommended file layout

```
.github/workflows/ci.yml                       # move (commit 1), rename (commit 2)
CONTRIBUTING.md                                # rename commit only
test/threadline/ci_workflow_parity_contract_test.exs
  └─ new describe "job order, names and CI required wiring (DX-01)"
     parsed_job_order/1, ci_order_errors/1, required_gate_errors/1, name rules
test/threadline/ci_topology_contract_test.exs  # 1099-1100 anchor only
.planning/phases/221-ci-names-and-order/
  ├─ tools/time-to-red.py                      # imports 219 summarize-ci.py (importlib), NAME_HISTORY
  ├─ tools/reorder-ci-jobs.py (optional)       # the chunk mover, if the executor wants it tracked
  └─ raw/ci/runs/<10 run ids>.json             # committed; tests and tool stay offline
```

### Anti-patterns

- **Raw-text job scans for new pins,** such as `workflow_job_ids/1` or `^  ([a-z]...):`. Quoted ids and trailing comments bypass them (D-09).
- **Deriving `@ci_job_ids` from the order list.** One edit would move both pins together.
- **Using `git diff --color-moved` as the proof of an order-only move.** See Pitfall 2.
- **Re-sorting on noise.** Credo (78) and PgBouncer (77) are 1 s apart, and bump-rehearsal (151) and Dialyzer (158) 7 s apart. Re-derive only per D-06.

## Order-Only Move Procedure (focus 3), prototyped and verified

This was prototyped in a scratch worktree. It produced a 458/458-line `git diff --stat`. The parsed maps compared `==` and the new order was exactly D-06 `[VERIFIED: scratch run]`.

**Chunk rule.** A chunk is one job header `^  <id>:$`, plus the contiguous **column-2 comment lines and blank lines directly above it**, plus its body up to the next chunk. So:
- The two "Removed: verify-docs / verify-hex-package" tombstones (ci.yml ~950-961) travel with verify-release-shape.
- "Removed: verify-mechanical" and the "Heavy recurring gate" comment (~690-699) travel with verify-capture.
- The load-bearing `if: always()` explanation (~1071-1084) travels with ci-required.
- The 6-space "Removed: trailing `mix verify.mechanical` step" comment (~847-851) stays inside verify-capture's body.
- The `CACHE KEY CONTRACT` comment (ci.yml:66) stays inside verify-format.

verify-bump-rehearsal (1018) and verify-deps-audit (1044) refer to it as "the CACHE KEY CONTRACT **above**". After the move, verify-format sits at position 3, deps-audit at 4 and bump-rehearsal at 9, so "above" stays true.

**Header.** Line 2 (the one-line, `, `-separated roster) is rewritten in D-06 order. Nothing else in the preamble changes.

The script below was prototyped and is stdlib Python:

```python
TARGET = ["verify-release-shape","verify-repo-hygiene","verify-format","verify-deps-audit",
          "verify-compile-no-optional","verify-hex-evaluator","verify-pgbouncer-topology",
          "verify-credo","verify-bump-rehearsal","verify-dialyzer","verify-test",
          "verify-capture","verify-example-browser","ci-required"]
pre, body = text.split("\njobs:\n", 1)
lines = body.split("\n")[:-1]                       # file ends with "\n"
header = re.compile(r"^  ([A-Za-z_][A-Za-z0-9_-]*):\s*$")
lead   = re.compile(r"^(  #.*|\s*)$")               # column-2 comment or blank
starts = [i for i,l in enumerate(lines) if header.match(l)]
chunk_starts = []
for h in starts:
    s = h
    while s > 0 and lead.match(lines[s-1]) and not (chunk_starts and s-1 < chunk_starts[-1]):
        s -= 1
    chunk_starts.append(s)
# slice, strip leading/trailing blank lines per chunk, re-join with one blank line,
# assert sorted(chunk ids) == sorted(TARGET), rewrite header line 2, write back with "\n" ending
```

**Proof (three mechanical checks; run all three):**

```bash
git show HEAD:.github/workflows/ci.yml > /tmp/ci.before.yml
# 1. parsed equality + new order
MIX_ENV=test mix run --no-start -e '
  [a, b] = System.argv()
  p = &YamlElixir.read_from_string!(File.read!(&1))
  true = p.(a) == p.(b)
  IO.puts("parsed maps equal")' /tmp/ci.before.yml .github/workflows/ci.yml
# 2. line multiset: the ONLY differing line is the header roster (line 2)
diff <(sort /tmp/ci.before.yml) <(sort .github/workflows/ci.yml)   # expect exactly one -/+ pair: the "# verify-..." roster
# 3. chunk multiset: re-chunk both files with the same splitter; the {id: chunk text} dicts must be equal
```

Check 2 gave exactly one `<`/`>` pair (the roster line) and a 1115-line file both before and after `[VERIFIED: scratch]`. Check 3 is what proves that comments travelled with their block: a comment attached to the wrong job changes that job's chunk text.

Do **not** use `mix format` or any YAML re-emitter on ci.yml. The repo has no YAML formatter, and re-emitting would drop comments.

## Evaluator Modes (focus 4), verified

`mix.exs:423-463` `[VERIFIED: read]`:
- `System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "rehearsal")`. The **default is `rehearsal`**: `bin/with-rehearsal-registry` "packages THIS tree with `mix hex.build`, serves it from a throwaway signed local registry". It then runs `mix deps.unlock threadline`, `deps.get`, `compile --warnings-as-errors`, `ecto.create`/`migrate` and `mix test` in `priv/ci/hex_evaluator`.
- `"published"` is set "only by release.yml AFTER `mix hex.publish`". It is set at `release.yml:592` (`THREADLINE_HEX_EVALUATOR_MODE: published`).
- ci.yml never sets it. The topology `dominance_errors/3` pins both facts: the default string in mix.exs, and `refute String.contains?(yaml, "THREADLINE_HEX_EVALUATOR_MODE")`.

So on every CI run, including PRs, the job installs **this tree's** package from a local registry. `(threadline from hex.pm)` is false there.

**Final names:**
- Job: `Hex package install (rehearsal registry)` (D-02, 40 characters). This is truthful.
- Step (ci.yml:541): **`Install this tree's package from a local registry and test it`**. It says what the step proves and contains no "Hex-published". release.yml's step (`Verify the just-published threadline adopt path`) stays, because it is true there. No test pins either step name `[VERIFIED: grep]`.

## Measurement Tool (focus 6)

**Verified inputs.** `gh api repos/szTheory/threadline/actions/runs/<id>` for the 10 runs gives `36502353440` push/main; `36501481301`, `36487483472`, `36467068660` and `36465241600` pull_request on land/v1.43-217-218; and `36457705448`…`36453043277` workflow_dispatch on the same branch. All are success, attempt 1 `[VERIFIED: gh api]`. `219/raw/ci/runs/` holds only `36453043277`, `36454272684`, `36455432448`, `36456537357` and `36457705448`; the other five are **missing** `[VERIFIED: ls]`.

**Figures from the 219 arithmetic.** These are nearest-rank p50 `rank = ceil(0.5·n)` over successful jobs with `completed_at - started_at`, as in `summarize-ci.py` `pick`/`rank`/`job_seconds` `[VERIFIED: computed this session]`:

| id (old name) | p50 s | max s | n |
|---|---|---|---|
| verify-release-shape | 8 | 11 | 10 |
| verify-repo-hygiene | 8 | 43 | 10 |
| verify-format | 17 | 23 | 10 |
| verify-deps-audit | 36 | 41 | 10 |
| verify-compile-no-optional | 59 | 61 | 10 |
| verify-hex-evaluator | 70 | 100 | 10 |
| verify-pgbouncer-topology | 77 | 126 | 10 |
| verify-credo | 78 | 83 | 10 |
| verify-bump-rehearsal | 151 | 171 | 10 |
| verify-dialyzer | 158 | 188 | 10 |
| verify-test (min lane, the fastest; current 451, latest 358 with n=3) | 342 | 390 | 10 |
| verify-capture | 391 | 466 | 10 |
| verify-example-browser | 565 | 638 | 10 |

The **order equals D-06**. CONTEXT's 18/71/157/403/568 are `statistics.median` values; the order is the same. Cite the nearest-rank numbers in the attribute comment. verify-test's `latest` lane has only n=3, because it was added mid-window by 220; the "fastest lane" rule makes this irrelevant.

**Tool design.** `.planning/phases/221-ci-names-and-order/tools/time-to-red.py` is stdlib only. It imports `219/tools/summarize-ci.py` through `importlib` (the `remeasure-218.py:66-68` pattern) and does not edit it.

```python
RUNS = [36502353440, 36501481301, 36487483472, 36467068660, 36465241600,
        36457705448, 36456537357, 36455432448, 36454272684, 36453043277]
RENAME_SHA = None          # set in the rename plan: the 221 rename commit on the land branch
ERA_BOUNDARY_RUN = None    # set at landing: first CI run that posts the new names (D-13)
# Frozen: every ci.yml job name ever posted in the measured eras -> stable id.
NAME_HISTORY = {
    # pre-221 (ci.yml as of 3c4ac9b1), each verbatim from the name: line
    "Check formatting": "verify-format",
    "Run Credo (strict)": "verify-credo",
    "Dialyzer (current toolchain)": "verify-dialyzer",
    "Compile without optional deps": "verify-compile-no-optional",
    "Run test suite": "verify-test",                     # matrix: "Run test suite (<lane>)"
    "Hex evaluator smoke (threadline from hex.pm)": "verify-hex-evaluator",
    "Example app browser E2E (Playwright)": "verify-example-browser",
    "Tier A capture lane (byte-stable evidence)": "verify-capture",
    "PgBouncer transaction topology": "verify-pgbouncer-topology",
    "Release metadata (version / changelog)": "verify-release-shape",
    "Bump rehearsal (next minor)": "verify-bump-rehearsal",
    "Dependency audit (all lockfiles)": "verify-deps-audit",
    "Repo hygiene (no machine-local paths)": "verify-repo-hygiene",
    "CI required": "ci-required",
    # removed by 218-04 (copied from remeasure-218.py REMOVED_IDS)
    "Mechanical checker (committed scorecards)": "verify-mechanical",
    "Build ExDoc (dev)": "verify-docs",
    "Hex package tarball": "verify-hex-package",
    # post-221 names are added by the rename plan, in the same commit as the ci.yml rename
}
def job_id(name):
    if name in NAME_HISTORY: return NAME_HISTORY[name]
    for base, jid in NAME_HISTORY.items():
        if name.startswith(base + " ("): return jid   # matrix lane suffix
    return "?"
```

**Subcommands**

- **`collect`.** For each id in `RUNS` that is missing from `raw/ci/runs/`, run `gh api --paginate repos/szTheory/threadline/actions/runs/<id>/jobs?per_page=100` plus a run GET, and write the **219 schema**: `{run_id, attempt, head_sha, event, created_at, conclusion, workflow, jobs:[{id,name,status,conclusion,started_at,completed_at,labels,steps:[{name,conclusion,started_at,completed_at}]}] sorted by id}`. Use GET only, and never write to GitHub.
- **`order`.** Offline. Per id, take the nearest-rank p50 of each posted name through `S.sort_samples`/`S.pick`; a matrix id takes its minimum lane p50, with that lane's max. Sort by `(p50, max, id)`, excluding `ci-required`. Print the table, then the `@time_to_red_order ~w(...)` literal.
- **`check`.** Offline. Read the literal from `test/threadline/ci_workflow_parity_contract_test.exs` with a regex over the `~w(...)` body and exit 1 on drift. This makes regeneration self-verifying without a network call in tests.
- **Self-check (run inside `order`).** Assert that no `"?"` ids appear, and that every post-221 name maps to the same id as its pre-221 counterpart (no collision). The unchanged names map to themselves.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| YAML structure reads | regex over ci.yml | `parse_yaml/1` + `yaml_get`/`yaml_field`/`parsed_job` (existing) | Quoted keys, flow maps, trailing comments (220 re-verification) |
| YAML order | line scan | `maps_as_keywords: true` + reverse + guards | Same bypasses; the order reader must be the parser's |
| Percentiles | new arithmetic | import 219 `summarize-ci.py` (`job_seconds`, `rank`, `pick`, `sort_samples`) | Keeps 214/218/219/221 numbers comparable |
| Composed check names | new composer | `composed_check_names/1` (parity :2141) | Already pinned by the IN-02 fix |
| Mutation harness | new loop | the `{control, mutate, fragment}` loop with `refute mutated == workflows` and the `rule=yaml-parse` guard (parity :642-653) | Consistent fail-closed controls |

## Runtime State Inventory (rename of display names)

| Category | Items Found | Action Required |
|---|---|---|
| Stored data | Committed raw run JSON under `.planning/phases/21{4,8,9}-*/raw/ci/runs/` stores the old `job.name` strings | None (historical). New tool maps names through `NAME_HISTORY` |
| Live service config | GitHub ruleset `main` requires context `CI required` (unchanged). **No other check name is a required context.** Branch protection is verified by `bin/verify-branch-protection` (expects the `["CI required"]` singleton) | None. Do not add new names as required contexts |
| OS-registered state | None: no cron, launchd or systemd entries reference job names `[VERIFIED: grep bin/ scripts/]` | None |
| Secrets/env vars | `THREADLINE_HEX_EVALUATOR_MODE` is keyed by env name, not job name; ci.yml must still never set it | None |
| Build artifacts / caches | Actions cache keys contain no job names (`ubuntu-24.04-<otp>-elixir-<ver>-mix-deps-…`, `build-v1`) | None. The rename does not invalidate caches |
| External observers | `bin/observe-main-ci:88-89` selects `.name == "CI required"`; the `workflow_run: workflows: ["CI"]` consumers key on the workflow name | None |

**Era boundary:** after landing, the GitHub jobs API reports the new names for new runs, and the old names remain in old runs forever. The only mitigation needed is D-13's `NAME_HISTORY` plus the recorded `RENAME_SHA` and `ERA_BOUNDARY_RUN`.

## Common Pitfalls

### Pitfall 1: Rename anchors silently become no-op controls
**What goes wrong:** A mutation whose `String.replace` anchor contains an old name stops changing the input.
**How to avoid:** Every harness asserts `refute mutated == workflows`. The scratch run proved that this is how the 3 affected tests fail (loudly). Prefer name-agnostic anchors such as `"  <id>:\n    name: "`.
**Warning sign:** "control did not change the input".

### Pitfall 2: `git diff --color-moved` is not a proof
**What goes wrong:** Git recolours short, repeated lines (`timeout-minutes: 15`, `MIX_ENV: test`, `env:`) as plain adds and deletes. In the prototype, `--color-moved=dimmed-zebra` still showed non-moved `+`/`-` lines on a provably pure move `[VERIFIED: scratch]`.
**How to avoid:** Prove the move with parsed `==`, the line multiset and the chunk multiset. Use color-moved only as a reviewer aid.

### Pitfall 3: Comment-removal control on the verify-test comment
**What goes wrong:** Parity :453 removes the ci.yml comment line `    # "Run test suite (latest)". Keys carried only via \`include\`` and asserts that the input changed. If the rename updates the name but not that comment (or the reverse), the control breaks.
**How to avoid:** Update ci.yml:316-318 and parity :453 in the same commit.

### Pitfall 4: Duplicate job keys
**What goes wrong:** Map mode keeps the **first** duplicate and keyword mode keeps both, so a set comparison passes.
**How to avoid:** Guard with `order == Enum.uniq(order)` (included above).

### Pitfall 5: Length bound vs the locked names
**What goes wrong:** A literal "≤ 40" contract fails on `Next-minor release rehearsal (docs + contracts)` (47).
**How to avoid:** Bound at 48 and record why.

### Pitfall 6: Red commits on the branch
**What goes wrong:** Writing `ci_order_errors/1` red-first and committing it before the move leaves a red commit.
**How to avoid:** Keep the red-first evidence in the SUMMARY: run the new test before moving and paste the failure output. Then commit the **ci.yml move alone** (the order-only commit D-08 wants), and then the contract (green). The mutation controls keep the "red on old order" proof permanent, because the "ci-required above hygiene" and "format after browser" controls reproduce non-target orders.

### Pitfall 7: Cherry-pick order at landing
**What goes wrong:** `d7d44fd1` rewrites the parity test's parsed-YAML helpers that 221 builds on.
**How to avoid:** Cherry-pick `d7d44fd1` first, then `2099d17b`, `9ebd6af5` and `997ad1d0`, then the 221 commits. ci.yml is identical between `origin/main` (3c4ac9b1) and HEAD `[VERIFIED: git diff --stat origin/main HEAD]`, so the move and the rename apply cleanly. None of the four carry-along commits is on any remote branch `[VERIFIED: git branch -r --contains]`.

### Pitfall 8: Planning prose tripping repo hygiene
**What goes wrong:** The tool, the raw JSON and the SUMMARY are tracked `.planning` files, which `bin/verify-repo-hygiene` scans.
**How to avoid:** No home-path shapes and no username. Run `bin/verify-repo-hygiene` before each commit.

### Pitfall 9: Claiming speed
D-05: no text in the SUMMARY, CONTRIBUTING, CHANGELOG or a commit may say the reorder makes red faster. Put the "Readability only" wording in the attribute comment.

## Code Examples

Everything load-bearing is under Architecture Patterns (reader, order contract, gate contract, mover, proof commands, tool skeleton). The sources are the probes run this session and the existing helpers in `test/threadline/ci_workflow_parity_contract_test.exs:837-907`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Text-regex job/`needs` scans | Parsed-YAML helpers (`parse_yaml`, `parsed_jobs`, …) | d7d44fd1 (220 round 3) | New pins must use the parser. Order needs keyword mode |
| Check names = command wrappers ("Run …") | Subject + proof names (D-01) | this phase | CONTRIBUTING roster and doc contract move with it |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | GitHub rejects or complains about duplicate YAML keys in workflows, so the duplicate guard is belt-and-braces `[ASSUMED]` | Pitfall 4 | None: the guard fails closed anyway |
| A2 | GitHub keeps composing `<name> (<lane>)` for a static name with a base-axis matrix, per the existing IN-02 behaviour and prior live runs `[ASSUMED for the new name; VERIFIED behaviour for the old name via run job names]` | Pattern 4 | A wrong posted name. Caught at landing by comparing the PR run's job names with the expected 15 |
| A3 | Proposed step wording "Install this tree's package from a local registry and test it" is acceptable prose `[ASSUMED]` (the maintainer delegated names to the recs) | Evaluator | Cosmetic |
| A4 | The browser-full symmetric rename is optional and safe `[VERIFIED: TITLE_PREFIX is separate]`. Whether to do it is a discretion call | Inventory E | None |

## Open Questions (RESOLVED)

1. **Should the historical citations at CONTRIBUTING:739 and ci.yml:149 move to the id form?**
   - What we know: D-04 keeps *moduledoc* historical prose. These two are in the files the retired-name ban should cover.
   - Recommendation: move them to the id form (the text stays true), which gives the ban no allowlist.
   - RESOLVED: adopted in 221-03 Task 1. Both citations move to the id form, and the retired-name ban needs no allowlist.
2. **`ci_required_block/0` onto `parsed_job/2`?**
   - Recommendation: no. The topology file has no parsed helpers, and D-10(d) now pins "last". The planner may leave both text splits as they are.
   - RESOLVED: decided in 221-02 Task 1. Both text splits stay as they are, and rule `order-last` pins the assumption they rely on.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/OTP + deps | contracts, probes | ✓ | 1.17.3 / OTP 27 | — |
| Local Postgres | full `mix test` | ✓ (full `test/threadline` ran in scratch) | — | — |
| python3 | 221 tool | ✓ | 3.14.4 | — |
| gh (authenticated, read) | `collect` | ✓ | 2.101.0 | the 5 already-committed runs plus a manual fetch |
| git | move proof, cherry-pick | ✓ | 2.41.0 | — |
| Push/PR/dispatch rights | landing | maintainer grant required | — | none: a checkpoint |

## Validation Architecture

### Test Framework
| Property | Value |
|---|---|
| Framework | ExUnit (Elixir 1.17.3), yaml_elixir 2.11.0 (test-only) |
| Config file | `test/test_helper.exs` (excludes `pgbouncer_topology`, `live_dialyzer`) |
| Quick run command | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/release_control_plane_contract_test.exs` (71 tests today, ~4 s after compile) |
| ci.yml-reader sweep | the quick files plus `browser_full_projects_contract_test.exs ci_sha_gate_contract_test.exs deps_audit_contract_test.exs deps_health_doc_contract_test.exs main_ci_observer_contract_test.exs planning_dependency_contract_test.exs repo_hygiene_contract_test.exs upgrade_path_doc_contract_test.exs branch_protection_comparison_contract_test.exs optional_deps_contract_test.exs` (130 tests, ~14 s) |
| Full suite command | `mix verify.test` (= `mix test`), then `bin/verify-repo-hygiene`, `mix verify.format`, `mix verify.credo`; `mix ci.all` before landing |
| Tool check | `python3 .planning/phases/221-ci-names-and-order/tools/time-to-red.py order` and `... check` (offline) |

### Phase Requirements → Test Map
| SC | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| SC-1 | Every name states what it proves; the evaluator name is truthful; CONTRIBUTING quotes are updated in the same commit | contract + doc-contract | quick command (new name rules 1-8) + `git show --stat <rename sha>` lists both ci.yml and CONTRIBUTING.md | ❌ Wave 0: name rules in the parity test |
| SC-1 (evaluator truth) | ci.yml never sets `THREADLINE_HEX_EVALUATOR_MODE`; mix.exs defaults to rehearsal | contract (existing) | `mix test test/threadline/ci_topology_contract_test.exs` (dominance test) | ✅ |
| SC-2 | YAML order == `@time_to_red_order ++ ["ci-required"]`; no `needs` outside ci-required | contract | quick command (`ci_order_errors/1` + 5 controls + the a,b,c fixture) | ❌ Wave 0 |
| SC-2 (order-only move) | parsed maps `==` before/after; line multiset differs only in header line 2; chunk multiset equal | mechanical (plan verify) | the three proof commands in §Order-Only Move | n/a (commands) |
| SC-2 (order provenance) | the literal equals the tool output from the committed raw JSON | tool | `time-to-red.py check` | ❌ Wave 0 |
| SC-3 | ids unchanged (`@ci_job_ids` frozen literal); `CI required` byte-exact against the ruleset | contract (new + existing :1145) | quick command | partial (the ruleset pin exists) |
| SC-4 | gate-if, gate-step, gate-inputs, gate-jobs-input, gate-name, each with its control; the comment positive control | contract | quick command (`required_gate_errors/1`) | ❌ Wave 0 |
| Landing | PR run posts the 15 expected names | CI observation | `gh api repos/szTheory/threadline/actions/runs/<pr run>/jobs --jq '[.jobs[].name]\|sort'` compared with the expected list | n/a |

### Mutation controls (all must go red; each asserts `refute mutated == input` and no `rule=yaml-parse`)
- **Order:** verify-format moved above `ci-required:`; ci-required moved above verify-repo-hygiene (both parse to an `==` map); `needs:` in block form, flow form and quoted `"Needs"` on verify-test; quoted stub `"verify-extra":`; jobs-level `<<` merge.
- **Gate:** delete `if: always()`; step `if: false`; `uses:` replaced with `run: echo ok`; quoted `"allowed-skips": verify-test`; `jobs: '{}'`; a second workflow whose job is named `CI required`; `verify-format` renamed in header, key and `needs`.
- **Positive controls (must stay green):** `if: ${{ always() }}`; `# allowed-skips: verify-test` comment.
- **Names:** an old name restored on one job; `${{ matrix.lane }}` in the verify-test name; a roster bullet dropped; `Run test suite (current)` reintroduced in CONTRIBUTING; `name:` no longer the first key.

### Sampling Rate
- **Per task commit:** the quick command, plus `bin/verify-repo-hygiene` when a commit touches `.planning`.
- **Per plan:** the ci.yml-reader sweep, plus `mix verify.format` and `mix verify.credo`.
- **Phase gate:** `mix verify.test` fully green, then `mix ci.all` (rebuild the PLT with `mix dialyzer --plt` if it goes red at Dialyzer from a cache miss), then the PR CI run green with the new names.

### Wave 0 Gaps
- [ ] `parsed_job_order/1`, `ci_order_errors/1`, `@time_to_red_order` + comment, the a,b,c fixture test (parity test)
- [ ] `required_gate_errors/1`, `@ci_job_ids` literal, controls (parity test, voting-lanes describe or a new DX-01 describe)
- [ ] name rules + `@ci_check_names` + `@retired_check_names` (parity test), in the rename commit
- [ ] `.planning/phases/221-ci-names-and-order/tools/time-to-red.py` + `raw/ci/runs/*.json` (10 files)

## Security Domain

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2/V3 | no | — |
| V4 Access Control | yes (merge gate) | single required context `CI required`; alls-green pinned by full SHA; `if: always()`; `jobs: ${{ toJSON(needs) }}`; no `allowed-skips`/`allowed-failures` (SC-4 contract) |
| V5 Input Validation | yes (contract inputs) | parse through yamerl; fail closed on parse errors, merge keys and duplicates |
| V14 Config / supply chain | yes | the existing `alls-green@<40-hex>` pin (topology :106) is kept; the new gate-step rule re-asserts it on parsed YAML |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Gate laundering (skip scored as pass) through a deleted `if: always()` or an `allowed-skips` in any spelling | Tampering / Elevation | `required_gate_errors/1` (SC-4) |
| Second job posting `CI required` from another workflow (spoofed context) | Spoofing | gate-name rule over `all_workflows()` |
| Job id rename that silently drops a lane (three-way parity accepts it) | Tampering | frozen `@ci_job_ids` literal |

## Suggested Plan Decomposition

1. **221-01 (wave 1): contracts that are green on today's tree, plus the tool.** Build `required_gate_errors/1` with `@ci_job_ids` and all SC-4 controls. Build `time-to-red.py` (`collect` / `order` / `check`) with `NAME_HISTORY`, and commit the 10 raw run JSONs. All green. Verify with the quick command, then `time-to-red.py order` (its output must equal D-06), then `bin/verify-repo-hygiene`.
2. **221-02 (wave 2): order.** Write `parsed_job_order/1`, `ci_order_errors/1` and `@time_to_red_order` (pasted from the tool). Run them, and capture the red output in the SUMMARY. Move ci.yml with the chunk mover and run the three proofs. **Commit 1** is ci.yml only: the order-only commit (D-08), with the existing suites green (proven in scratch: 71 + 130 tests). **Commit 2** adds the order contract and its controls (green). Then run `time-to-red.py check`.
3. **221-03 (wave 3): the one-pass rename.** One commit containing:
   - ci.yml: 10 names, the evaluator step, and the verify-test comment at 316-318
   - optionally the ci.yml:149 id-form citation
   - CONTRIBUTING: 39, 669, 739, 821, 844 and the full 15-name roster
   - the parity test pins (241-242, 445-489, 504, 726-727; fixtures optional) and topology 1099-1100
   - the name rules
   - `NAME_HISTORY` post-221 entries and `RENAME_SHA`
   - optionally browser-full.yml:45

   Verify with the quick command, the sweep, `mix verify.test` and `bin/verify-repo-hygiene`.
4. **221-04 (wave 4): landing.** A `checkpoint:human-action` for the grant: a new `land/v1.43-221` from `origin/main`, the push, the PR and each dispatch, named explicitly. Cherry-pick `d7d44fd1`, `2099d17b`, `9ebd6af5` and `997ad1d0`, then the 221 code commits, then a `docs(planning)` sync (never `git add .planning/` wholesale). Run `mix ci.all` locally. After the grant, compare the PR run's posted job names with the expected 15, record `ERA_BOUNDARY_RUN` in the tool and the SUMMARY, and dispatch sequentially.

## Sources

### Primary (HIGH)
- `.github/workflows/ci.yml` (read in full at the relevant ranges this session)
- `test/threadline/ci_workflow_parity_contract_test.exs` (1-200, 237-247, 436-670, 830-1065, 2100-2175, 4560-4790)
- `test/threadline/ci_topology_contract_test.exs` (98-118, 360-400, 530-782, 822-850, 980-1186)
- `test/threadline/release_control_plane_contract_test.exs:60-110`
- `mix.exs:415-463`, `mix.lock:46-47`, `deps/yaml_elixir/lib/yaml_elixir/mapper.ex:70-95`
- `CONTRIBUTING.md` (30-45, 669, 730-745, 810-850, 875-905)
- `.planning/phases/219-deps-only-build-cache/tools/summarize-ci.py` (read in full), `collect-ci-runs.sh:155-180`, `218/tools/remeasure-218.py:1-120`
- `gh api` run and job data for the 10 cited runs (read-only)
- The scratch worktree runs (baseline, after the move, after the rename) and the `mix run` probes of the proposed contracts

### Secondary
- `.planning/phases/220-newest-toolchain-lane/220-VERIFICATION.md:39-42,142-144,229` (the advisory reproduced)

## Metadata

**Confidence breakdown:**
- Inventory: HIGH. The grep and the scratch rename run agree.
- Parser behaviour and contracts: HIGH. Probed with the exact logic.
- Order and figures: HIGH. Recomputed from live `gh api` data.
- Name wording: MEDIUM. The names are locked by D-02, and the step wording is a recommendation.

**Research date:** 2026-09-28
**Valid until:** until the next ci.yml roster change or a yaml_elixir bump (the a,b,c fixture guards the latter)
