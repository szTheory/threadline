# Phase 220: Newest-Toolchain Lane - Pattern Map

**Mapped:** 2026-09-28
**Files analyzed:** 12 (3 CI/contract/doc surfaces with multiple sub-edits, 6 D-08 lib/test fixes, 2 conditional findings/process docs, 1 example-app-adjacent doc)
**Analogs found:** 12 / 12 (all files being modified already exist; this phase extends, not creates)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `.github/workflows/ci.yml` (`verify-test` matrix, `include` rows) | config (CI workflow) | batch/CRUD-of-config | itself — the existing `min`/`current` `include` rows (same file, lines ~316-340) | exact (self-extend) |
| `.github/workflows/ci.yml` (verify-test header comment, cache comment ~381-388) | config/docs-in-code | transform (prose) | itself — existing header comment block (lines 315-325) | exact |
| `test/threadline/ci_workflow_parity_contract_test.exs` (roster + `latest_row_errors/2`) | test (contract) | request-response (assert on parsed YAML) | `min_row_errors/2` / `current_row_errors/1` (same file, lines 1327-1364) | exact |
| `test/threadline/ci_workflow_parity_contract_test.exs` (D-15 no-continue-on-error scan) | test (contract) | request-response | `continue_on_error_errors/2` in the build-cache contract (lines 2202-2212) + its controls (lines 3118-3139) | exact |
| `test/threadline/ci_workflow_parity_contract_test.exs` (D-16 no-beta-pg allowlist) | test (contract) | request-response | `workflow_files/0` + `all_workflows/0` glob-driven scan (lines 111-125) and the existing `:latest`-tag substring ban (lines 204-211) | exact |
| `test/threadline/ci_workflow_parity_contract_test.exs` (D-17 doc-contains assertions) | test (contract) | request-response | existing "CONTRIBUTING List 2 carries both composed required-check names" test (lines 374-378) | exact |
| `CONTRIBUTING.md` (toolchain, lanes, cache table, required-checks list) | config/docs | transform (prose) | itself — sections already covering min/current lanes (lines 23-37, 659-660, 745-758, 870-885) | exact |
| `README.md` (support statement, line ~102) | config/docs | transform (prose) | itself — existing "Supported versions" line | exact |
| `mix.exs` (support-contract comment, ~38-41) | config | transform (prose) | itself — existing comment block | exact |
| `lib/mix/tasks/threadline.incident.ex` (unused `require Logger`, line 38) | utility (mix task) | request-response (CLI) | n/a — trivial dead-code removal, no analog needed | exact (self) |
| `test/support/migration_harness.ex` (unused `require Logger`, line 16) | test (support/utility) | file-I/O (migration harness) | n/a — trivial dead-code removal | exact (self) |
| `lib/threadline/critic_trust/ledger_splice.ex` (bitstring pin, line ~85) | utility (transform) | transform (byte-scan parser) | n/a — restructure in place with `binary_part/3`, no cross-file analog | exact (self) |
| `lib/threadline/operator_surface/live/export_status_live/components.ex` (dead clause, line ~173) | component (LiveView function component) | request-response | n/a — trivial dead-clause removal | exact (self) |
| `lib/threadline/operator_surface/live/evidence_live.ex` (dead clause, line ~438) | controller (LiveView) | request-response | n/a — trivial dead-clause removal | exact (self) |
| `lib/threadline/operator_surface/live/actor_live.ex` (always-true condition, line ~233) | component (LiveView template) | request-response | n/a — trivial always-true simplification | exact (self) |
| `.planning/phases/220-newest-toolchain-lane/220-FINDINGS.md` (conditional, D-12) | docs (findings record) | transform | `.planning/phases/219-deps-only-build-cache/219-REMEASURE.md` (shape: run IDs, measured numbers, verbatim citations) | role-match |
| `.planning/MILESTONE-GUIDE.txt` (D-18 checklist line) | config/docs | transform | itself — existing checklist-style lines (around line 199 region) | exact |

## Pattern Assignments

### `.github/workflows/ci.yml` — `verify-test` matrix (D-03, D-06)

**Analog:** the file's own `min`/`current` rows, lines 316-340.

**Header comment pattern** (lines 315-325, to extend for a third lane):
```yaml
  verify-test:
    # Base axis `lane` drives the check-name suffix → GitHub posts exactly
    # "Run test suite (min)" and "Run test suite (current)". Keys carried only
    # via `include` (elixir/otp/pg/runner) do NOT append to that suffix, so the
    # static `name:` yields the two documented required checks (D-15/D-19,
    # RESEARCH M1 construction A). Min lane = Elixir 1.15.8 / OTP 26.2.5.21
    # (exact floor build, strict) / pg14 on ubuntu-24.04 proving the declared
    # floor; current lane = the committed .tool-versions build, the full
    # payload. Each row sets exactly one toolchain source — the min row its
    # explicit pins, the current row `version-file` — because setup-beam errors
    # when both are set and an absent matrix key renders as an empty input.
    name: Run test suite
```
Per D-13/220-CONTEXT, this comment gets a third sentence describing the `latest` row (newest stable, explicit pins, no `version-file`, votes on every run per D-07).

**Matrix rows pattern** (lines 326-340, to append a third `include` entry):
```yaml
    strategy:
      fail-fast: false
      matrix:
        lane: [min, current]
        include:
          - lane: min
            elixir: "1.15.8"
            otp: "26.2.5.21"
            pg: "14"
            runner: "ubuntu-24.04"
          - lane: current
            version-file: ".tool-versions"
            pg: "16"
            runner: "ubuntu-24.04"
```
Per D-03: append (do not insert between) a `- lane: latest` row with explicit `elixir`/`otp` pins (re-verified at execution time), `pg: "18.6"`, `runner: "ubuntu-24.04"`, and no `version-file` — mirroring the `min` row's shape exactly (explicit pins, no version-file), not the `current` row's shape. Preserve `lane: latest` with the space (D-03's `:latest` substring-ban note).

Update `lane: [min, current]` to `lane: [min, current, latest]` — this literal string is also pinned by the contract test at `ci_workflow_parity_contract_test.exs` (regex `~r/^\s*lane:\s*\[min,\s*current\]\s*$/m`, line ~236), so both the workflow file and that regex must change together.

**Cache comment pattern** (lines 375-388, per D-06):
```yaml
      # THE bug this key shape fixes (D-19): an older key led with the
      # OS-family context value of the runner, which resolves to the literal
      # string `Linux` on every ubuntu image and carries no OTP or Elixir at
      # all. The min lane, then on an older ubuntu image, and the current lane
      # therefore shared ONE cache entry ...
```
D-06: "3 keys / 5 job-lanes" language elsewhere becomes "4 keys / 6 job-lanes" — update this comment's counting language plus the CONTRIBUTING cache-table prose (below) and the contract-test reason string around line 441 if literal counts appear there.

**Payload steps — do not touch for `latest`** (lines 419-425, 429-488):
```yaml
      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors

      - name: Verify no compile-connected xref cycles
        run: mix verify.xref_cycles

      - name: Run tests
        run: mix verify.test

      - name: Verify Threadline trigger coverage
        if: matrix.lane == 'current'
        run: mix verify.threadline
```
Per D-05: the `latest` row automatically gets only the unconditional steps (compile, xref, `verify.test`) because every step past `Verify Threadline trigger coverage` already guards on `if: matrix.lane == 'current'`. No new `if:` guards need to be added anywhere — `latest` simply doesn't match `== 'current'`. Do not add `latest`-specific conditionals.

---

### `test/threadline/ci_workflow_parity_contract_test.exs` — roster + pin-shape (D-13, D-14)

**Analog:** `min_row_errors/2` / `current_row_errors/1`, lines 1327-1364; `verify_test_matrix_errors/2`, lines 1298-1324.

**Roster/count pattern to extend from 2→3 rows** (lines 1298-1311):
```elixir
defp verify_test_matrix_errors(yaml, mix_exs) do
  rows = verify_test_rows(workflow_job(yaml, "verify-test"))
  by_lane = Map.new(rows, &{&1["lane"], &1})

  count_errors =
    if length(rows) == 2 and Map.keys(by_lane) |> Enum.sort() == ["current", "min"],
      do: [],
      else: [
        "verify-test must have exactly two include rows (min, current), found " <>
          inspect(Enum.map(rows, & &1["lane"]))
      ]
  ...
  count_errors ++
    source_errors ++
    min_row_errors(by_lane["min"], elixir_floor(mix_exs)) ++
    current_row_errors(by_lane["current"])
end
```
Per D-13: `length(rows) == 2` → `== 3`, sorted keys `["current", "min"]` → `["current", "latest", "min"]`, and append `++ latest_row_errors(by_lane["latest"], by_lane["current"])` (fed the current row so "strictly newer" can be checked, per D-14).

**Literal-pin pattern (`min_row_errors`) — do NOT copy verbatim for `latest`**:
```elixir
defp min_row_errors(row, floor) do
  ...
  [
    {row["otp"] == "26.2.5.21", "min row must pin otp: \"26.2.5.21\""},
    {row["elixir"] == "1.15.8", "min row must pin elixir: \"1.15.8\""},
    ...
  ]
  |> Enum.reject(&elem(&1, 0))
  |> Enum.map(&("verify-test " <> elem(&1, 1)))
end
```
This is the *wrong* template to copy literally (Common Pitfall #2 in RESEARCH.md) — `min`'s pins are a support promise and hard-coded. `latest`'s pins move every re-pin cycle (D-18) and must be checked for **shape/ordering only**.

**Shape-checking pattern to follow instead (`current_row_errors`)**:
```elixir
defp current_row_errors(row) do
  [
    {row["version-file"] == ".tool-versions",
     "current row must set version-file: \".tool-versions\""},
    {row["runner"] == "ubuntu-24.04", "current row must run on ubuntu-24.04"},
    {row["pg"] == "16", "current row must use pg 16"},
    {not Map.has_key?(row, "otp") and not Map.has_key?(row, "elixir"),
     "current row must not carry otp/elixir pins"}
  ]
  |> Enum.reject(&elem(&1, 0))
  |> Enum.map(&("verify-test " <> elem(&1, 1)))
end
```
New `latest_row_errors/2` (D-14) should combine both idioms: use the `{predicate, message}` tuple-list + reject/map shape from both functions, but write **regex/comparison predicates** (not `==` literal comparisons) for the pins:
```elixir
defp latest_row_errors(nil, _current), do: ["verify-test has no latest row"]

defp latest_row_errors(row, current_row) do
  otp_ok? = Regex.match?(~r/^\d+\.\d+(\.\d+){0,2}$/, row["otp"] || "")
  elixir_ok? = Regex.match?(~r/^\d+\.\d+\.\d+$/, row["elixir"] || "")
  pg_ok? = Regex.match?(~r/^\d+(\.\d+)?$/, row["pg"] || "")
  # "strictly newer" comparisons against current_row's otp/pg majors and
  # elixir minor, per D-14 — derive from `current_row["pg"]` etc.
  [
    {not Map.has_key?(row, "version-file"), "latest row must not set version-file"},
    {row["runner"] == "ubuntu-24.04", "latest row must run on ubuntu-24.04"},
    {otp_ok?, "latest row otp must match ^\\d+\\.\\d+(\\.\\d+){0,2}$, got #{inspect(row["otp"])}"},
    {elixir_ok?, "latest row elixir must match ^\\d+\\.\\d+\\.\\d+$ (no x/-rc/-otp), got #{inspect(row["elixir"])}"},
    {pg_ok?, "latest row pg must match ^\\d+(\\.\\d+)?$, got #{inspect(row["pg"])}"}
    # + strictly-newer-than-current checks
  ]
  |> Enum.reject(&elem(&1, 0))
  |> Enum.map(&("verify-test " <> elem(&1, 1)))
end
```

**Mutation-control pattern to extend** (lines 251-296, `controls` list inside the `"each lane installs one exact toolchain"` test):
```elixir
controls = [
  {"min row also given version-file", ...},
  {"current row also given an OTP pin", ...},
  ...
  {"a third matrix row",
   String.replace(
     yaml,
     current_row,
     ~s(          - lane: extra\n            version-file: ".tool-versions"\n) <> current_row
   )}
]

for {control, mutated} <- controls do
  refute mutated == yaml, "#{control} control did not change the input"
  refute verify_test_matrix_errors(mutated, mix_exs) == [],
         "#{control} mutation must make the verify-test matrix contract fail"
end
```
Per D-14's 5 mutation controls (`version-file` added, `otp: "29"`, `elixir: "1.20.0-rc.1"`, `pg: "16"` not-newer, runner `22.04`), append `{label, mutated}` tuples following this exact `String.replace` + `refute mutated == yaml` + `refute ... == []` idiom. Note: `"a third matrix row"` becomes a **fourth**-row control per D-13.

---

### `test/threadline/ci_workflow_parity_contract_test.exs` — D-15 no-`continue-on-error` fail-closed scan

**Analog:** `continue_on_error_errors/2`, lines 2202-2212 (build-cache contract), and its controls, lines 3118-3139.

**Core scan pattern**:
```elixir
defp continue_on_error_errors(job, window) do
  for {_class, _project, step} <- window,
      Regex.match?(~r/^\s*continue-on-error:/m, strip_comment_lines(step)) do
    build_cache_error(
      where(job, step),
      "rule=continue-on-error",
      "a step inside a cache block carries `continue-on-error:`",
      "a failed dependency compile must never reach the save (D-15)",
      "remove `continue-on-error:`"
    )
  end
end
```
D-15 needs a **repo-wide** version of this (every job in every workflow, not scoped to a cache window), plus a `ci-required.needs` set-equality check and an `allowed-failures` scan in the `ci-required` job block specifically. Model the whole-file scan on `strip_comment_lines/1` (line 1210) + the glob-driven `workflow_files/0` (line 112) so it covers all files, not just `ci.yml`.

**Mutation-control pattern for job/step/matrix-expression/`allowed-failures` forms**:
```elixir
for name <- [@root_deps_compile, @root_save] do
  ci_control(ctx, "continue-on-error on #{name}", "rule=continue-on-error", fn text ->
    edit_step(
      text,
      "verify-test",
      name,
      &add_line_after(&1, "        if: ", "        continue-on-error: true")
    )
  end)
end
```
D-15's 5 controls (job-level in `verify-test`; step-level on "Run tests"; matrix-expression form `continue-on-error: ${{ matrix.lane == 'latest' }}`; `allowed-failures:` in `ci-required`; a positive control with the word only in a comment staying green) follow this `add_line_after`/`edit_step` idiom, or a simpler `String.replace` per the roster-control style above — pick whichever the existing helpers (`edit_step`, `insert_step_after`, `replace_in_step`) already support without new plumbing.

---

### `test/threadline/ci_workflow_parity_contract_test.exs` — D-16 no-beta-PostgreSQL allowlist

**Analog:** the existing `:latest`-tag substring ban, lines 204-211, plus `workflow_files/0` / `all_workflows/0`, lines 111-125.

**Existing narrow ban to generalize**:
```elixir
describe "workflow image pinning" do
  test "no workflow file pins a service image to the mutable :latest tag" do
    for path <- workflow_files() do
      refute String.contains?(File.read!(path), ":latest"),
             "#{Path.relative_to(path, @repo_root)} must not pin any image to the " <>
               "rolling :latest tag"
    end
  end
end
```
D-16 needs a **positive allowlist regex scan** (not a substring-ban) across every `postgres:<tag>` occurrence, resolving `${{ matrix.pg }}` expressions through parsed `include` rows (the file already has `postgres:${{ matrix.pg }}` at `ci.yml:348`, plus 7 literal `postgres:16` occurrences across `ci.yml`, `browser-full.yml`, `flake-detection.yml`, `release.yml`, `docker-compose.yml`). Use `all_workflows/0`'s `{path, content}` map plus `verify_test_rows/1`-style parsing (line 1358) to resolve the matrix expression, then regex-match every literal `postgres:<tag>` against `^\d+(\.\d+)?$`.

**Live occurrences to enumerate for the scan/controls** (confirmed via grep this session):
```
.github/workflows/ci.yml:160    postgres:16   (verify-hex-evaluator)
.github/workflows/ci.yml:348    postgres:${{ matrix.pg }}   (verify-test, resolves to 14/16/18.6)
.github/workflows/ci.yml:500,546,696,847,975   postgres:16  (other jobs)
.github/workflows/browser-full.yml:62   postgres:16
.github/workflows/flake-detection.yml:66   postgres:16
.github/workflows/release.yml:596   postgres:16
docker-compose.yml:3   postgres:16
```
D-16's 3 controls (`pg: "19beta1"` in the latest row, `postgres:18rc1` in `browser-full.yml`, `postgres:devel` in `release.yml`) are `String.replace` mutations against these exact literal strings.

---

### `test/threadline/ci_workflow_parity_contract_test.exs` — D-17 doc-contains assertions

**Analog:** lines 374-378 (existing, verified live this session):
```elixir
test "CONTRIBUTING List 2 carries both composed required-check names" do
  ...
  assert String.contains?(doc, "Run test suite (min)")
  assert String.contains?(doc, "Run test suite (current)")
end
```
Extend with `assert String.contains?(doc, "Run test suite (latest)")` — same test, one more assertion, per D-13's "doc assertion around lines 374-378 also requires 'Run test suite (latest)'". CONTRIBUTING's required-checks list itself (lines 877-882) needs the matching new bullet line added in the same style as the existing 6 bullets there.

---

### `CONTRIBUTING.md` — cache table (D-06/D-17)

**Analog:** the existing cache table, lines 751-757:
```markdown
| Job | Build cache | Saves on miss |
| --- | --- | --- |
| `verify-test` | root on both lanes; example on the current lane only | yes |
| `verify-pgbouncer-topology` | root, restoring the current lane's key | no, restore only |
| `verify-example-browser` | example | yes |
| `verify-capture` | example | yes |
```
Per D-06/D-17: "root on both lanes" → "root on every lane" (verify-test's `verify-test` row); the surrounding prose ("3 keys / 5 job-lanes") becomes "4 keys / 6 job-lanes".

**Toolchain section pattern** (lines 23-37, already quoted above under README) — CONTRIBUTING's own toolchain section (same content block, lines ~23-37) needs a one-line note that the CI `latest` lane additionally proves the newest stable Elixir/OTP/PG, without changing the "supported floor" or "current" language.

---

## Shared Patterns

### Fail-closed contract-test idiom (applies to D-14, D-15, D-16)
**Source:** `test/threadline/ci_workflow_parity_contract_test.exs`, general shape used throughout (e.g. `min_row_errors/2` lines 1329-1345, `continue_on_error_errors/2` lines 2202-2212, `verify_test_matrix_errors/2` lines 1300-1324).
**Apply to:** every new contract check in this phase.
```elixir
# Each *_errors function: returns [] on success, a list of human-readable
# error strings on failure. Callers assert `... == []` for the pass case and
# `refute ... == []` (or assert a specific error substring) for each mutation
# control. Errors are {predicate, message} tuples filtered with
# Enum.reject(&elem(&1, 0)) |> Enum.map(&elem(&1, 1)) OR built as list
# comprehensions over parsed steps/rows.
```

### Mutation-control idiom (applies to D-14, D-15, D-16 controls)
**Source:** lines 251-296 (`verify-test matrix construction` describe block) and lines 3100-3139 (build-cache controls).
```elixir
controls = [
  {"label describing the mutation", String.replace(yaml, needle, replacement)},
  ...
]

for {control, mutated} <- controls do
  refute mutated == yaml, "#{control} control did not change the input"
  refute verify_test_matrix_errors(mutated, mix_exs) == [],
         "#{control} mutation must make the ... contract fail"
end
```
Every one of D-14/D-15/D-16's named controls should be a `{label, mutated}` tuple in this exact idiom — never a bespoke assertion outside the loop.

### Glob-driven (not hardcoded) file enumeration
**Source:** `workflow_files/0`, lines 111-125.
```elixir
defp workflow_files do
  paths =
    @repo_root
    |> Path.join(".github/workflows/*.{yml,yaml}")
    |> Path.wildcard()
    |> Enum.sort()

  refute paths == [],
         "found no workflow files to scan — a broken glob would launder a false pass here"

  paths
end
```
D-16's "scan every `postgres:<tag>` image across all `workflow_files()` plus `docker-compose.yml`" must literally call this existing helper (add `docker-compose.yml` as one more explicit path), not re-glob independently — this is the exact function CONTEXT.md's D-16 cites.

### `ci-required` extension-point — do not touch
**Source:** `.github/workflows/ci.yml`, lines 1071-1101.
```yaml
ci-required:
  name: CI required
  if: always()
  needs:
    - verify-format
    ...
    - verify-test          # already covers the whole matrix incl. the new latest row
    ...
  steps:
    - name: Decide whether all needed jobs succeeded
      uses: re-actors/alls-green@b5b5b37504aa4183270bd3d855c52a67f212be35
      with:
        jobs: ${{ toJSON(needs) }}
```
Per D-04/D-07: `latest` votes automatically because `verify-test` (the whole job key, whole matrix) is already in `needs:`. No `allowed-skips` entry needed since `latest` runs unconditionally (no job-level `if:`). Do not edit this block.

### 219's execution/commit discipline (process pattern, not code)
**Source:** `.planning/phases/219-deps-only-build-cache/219-02-PLAN.md` (`<executor_safety>`, task structure).
- Never `git add .planning/` or `git add .`; stage the explicit `files_modified` list only.
- Blocking gates (contract tests, `mix verify.test`, `mix verify.credo`, `bin/verify-repo-hygiene`, `actionlint`): STOP and report on failure, never weaken a rule/control to force green.
- `actionlint -shellcheck= .github/workflows/ci.yml` is the verify step for any `ci.yml` edit — reuse this exact command.
- D-10 (this phase) additionally requires the spike-branch dispatch (`gh workflow run ci.yml --ref spike/220-latest`) with the run ID cited, and requires an explicit maintainer grant naming the branch before any push/dispatch — per project memory, a bare "go" is not sufficient consent for push/PR/dispatch actions.

## No Analog Found

None. Every file in scope already exists and is being extended in place; this phase adds no new source files, only new rows/functions/lines inside existing ones.

## Metadata

**Analog search scope:** `.github/workflows/`, `test/threadline/ci_workflow_parity_contract_test.exs`, `CONTRIBUTING.md`, `README.md`, `mix.exs`, the 6 D-08 `lib/`/`test/support/` files, `.planning/phases/219-deps-only-build-cache/`.
**Files scanned:** `ci.yml` (~1100 lines, targeted reads), `ci_workflow_parity_contract_test.exs` (~3100+ lines, targeted reads via grep-then-offset), `CONTRIBUTING.md` (targeted sections), `README.md`, `mix.exs`, all 6 D-08 files, `219-02-PLAN.md`.
**Pattern extraction date:** 2026-09-28
