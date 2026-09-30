# Phase 218: CI Economy: Remove Waste - Pattern Map

**Mapped:** 2026-09-27
**Files analyzed:** 27 (4 new, 23 modified)
**Analogs found:** 26 / 27 (all analog paths verified git-tracked with `git ls-files`)

All paths are repo-relative. Line numbers were read on 2026-09-27 at HEAD `8cf9d051`.

**One correction to RESEARCH.md.** F6 says `bootstrap-release-pr-ci` sits at `release.yml:185-202`. The live file has it at **lines 189-206**: the job key is at 189, `needs:` at 197, the job `if:` at 198 and the `gh workflow run` at 206. CONTEXT's 189-206 is correct.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `bin/ci-sha-gate` (NEW; name at Claude's discretion) | utility (decision script) | request-response (gh api → decision) | `bin/upsert-ci-issue` (GH_BIN seam, jq on untrusted JSON) + `bin/classify-flake-run` (behavior-table header, GITHUB_OUTPUT append, always exit 0) | exact (composite) |
| `test/threadline/ci_sha_gate_contract_test.exs` (NEW) | test (fake-gh table) | request-response | `test/threadline/ci_issue_upsert_contract_test.exs` + `@tag :tmp_dir` from `test/threadline/repo_hygiene_guard_test.exs` | exact |
| `bin/browser-full-projects` (NEW) | utility (static parse / set difference) | transform (file-I/O) | `bin/compare-required-contexts` (pure set decision, exit-code contract) + `bin/verify-playwright-fail-fast` (`THREADLINE_PLAYWRIGHT_E2E` root seam) | role-match |
| `test/threadline/browser_full_projects_contract_test.exs` (NEW) | test (union contract + mutation controls) | transform | `test/threadline/ci_coverage_doc_contract_test.exs` (project regex, anti-vacuous assert) + `ci_workflow_parity_contract_test.exs:171-197` (MapSet three-way parity) + `:568-611` (mutation-control loop) | exact (composite) |
| `bin/classify-flake-run` (MOD) | utility | transform | itself (lines 20-35 table, 63-97 branches) | exact |
| `test/threadline/flake_classifier_contract_test.exs` (MOD) | test | transform | itself | exact |
| `bin/upsert-ci-issue` (MOD, `--close`) | utility | request-response | itself (lines 7-31) | exact |
| `test/threadline/ci_issue_upsert_contract_test.exs` (MOD) | test | request-response | itself | exact |
| `bin/verify-dialyzer-slice` (MOD, fail-closed) | utility (Elixir script) | transform | itself (`main/1` with-chain 13-31, `raw_output/1` 271-282, `parse_raw_output/1` 284-300) | exact |
| `test/threadline/dialyzer_slice_contract_test.exs` (MOD) | test | transform | itself (`run_fixture/2` 158-181) + `@tag :tmp_dir` convention | exact |
| `test/test_helper.exs` (MOD) | config | — | itself (lines 3-7) | exact |
| `test/threadline/zero_skips_contract_test.exs` (MOD) | test | — | itself (lines 68-84) | exact |
| `.github/workflows/flake-detection.yml` (MOD) | config (workflow) | batch/event-driven | itself + `browser-full.yml` issue step | exact |
| `.github/workflows/browser-full.yml` (MOD) | config (workflow) | batch/event-driven | itself + `flake-detection.yml` step-output idioms | exact |
| `.github/workflows/deps-health.yml` (MOD, optional close) | config (workflow) | event-driven | its own upsert step (lines 87-91) | exact |
| `.github/workflows/release.yml` (MOD, PAT guard) | config (workflow) | event-driven | itself (lines 189-206) | exact |
| `.github/workflows/ci.yml` (MOD: roster cut + verify-dialyzer live step) | config (workflow) | batch | itself (`verify-dialyzer` 137-257; `verify-mechanical` services block 545-586 as the Postgres-service template) | exact |
| `test/threadline/release_control_plane_contract_test.exs` (MOD) | test | — | itself (lines 122-195, `job_block!/2`) | exact |
| `test/threadline/ci_topology_contract_test.exs` (MOD) | test | — | itself (`dialyzer_topology_errors/3` 376-493, controls 117-199, bump-rehearsal 653-698) | exact |
| `test/threadline/ci_workflow_parity_contract_test.exs` (MOD) | test | — | itself (`os_family_context_errors/2` 1263-1270, test 733-762, setup-beam count 543-545, docs control 553-556) | exact |
| `test/threadline/ci_coverage_doc_contract_test.exs` (MOD) | test | — | itself | exact |
| `test/threadline/upgrade_path_doc_contract_test.exs` (MOD, line 125) | test | — | itself | exact |
| `guides/upgrade-path.md` (MOD, line 62) | docs | — | itself | exact |
| `CONTRIBUTING.md` (MOD: roster, job table, CI Coverage, flake prose, Dialyzer contract) | docs | — | itself | exact |
| `mix.exs` (MOD: `verify.flake` 15, `ci.all` live dialyzer entry, optional alias) | config | — | itself (lines 185-188, 207-233) | exact |
| `.planning/phases/218-ci-economy-remove-waste/tools/{collect-ci-runs.sh,summarize-ci.py,check-citations.py}` (NEW copies) | utility | batch | `.planning/phases/214-baseline-measurement/tools/*` (tracked) | exact (copy; retarget `SELF` only) |
| `.planning/phases/218-ci-economy-remove-waste/218-REMEASURE.md` (NEW) | docs (evidence) | — | `.planning/phases/214-baseline-measurement/214-BASELINE.md` | role-match |

## Pattern Assignments

### `bin/ci-sha-gate` (utility, request-response) — NEW

**Analogs:** `bin/upsert-ci-issue` for the gh seam and JSON handling, and `bin/classify-flake-run` for the header, output and exit discipline.

**Header/behavior-table idiom** (`bin/classify-flake-run:1-40`). Write the rationale and a full behavior table as the script's leading comment, and state which arm is the default:
```bash
#!/usr/bin/env bash
# GREEN-11 / D-35 / CR-01 / CR-02 (198-11): classify a `mix verify.flake`
# ...
# Behavior table:
#   exit code 0,              any header count      -> pass
#   exit code non-zero,       0 headers              -> unknown (...)
# ...
# `unknown` is the default arm of every branch below. `flaky` is reachable ONLY by the
# explicit `headers -ge 2` check — never as a fall-through `else`.
set -uo pipefail
```
For the gate, `run` is the default arm (fail OPEN). `skip` is reachable only through an explicit `event == schedule && success_count > 0` check. `broken-upstream` is reachable only through `failure > 0 && success == 0` on the upstream workflow.

**GH_BIN seam + argv parsing + die** (`bin/upsert-ci-issue:1-22`):
```bash
set -euo pipefail
die() { printf 'upsert-ci-issue: %s\n' "$*" >&2; exit 1; }
GH_BIN=${GH_BIN:-gh}
marker="" title="" body_file="" label="" ...
while [ "$#" -gt 0 ]; do
  case "$1" in
    --marker) marker=${2-}; shift 2 ;;
    ...
    *) die "unknown argument: $1" ;;
  esac
done
[ -n "$marker" ] || die "--marker is required"
command -v "$GH_BIN" >/dev/null 2>&1 || die "GH_BIN not found: $GH_BIN"
```
Only usage errors may `die` here. A gh or jq failure must degrade to `decision=run`, so wrap each call as `out=$("$GH_BIN" api ... 2>/dev/null) || out=""`. Do not let `set -e` abort.

**Untrusted JSON through jq with type checks** (`bin/upsert-ci-issue:25-26`):
```bash
matches=$(printf '%s' "$issues" | jq -c --arg marker "$marker" '[.[] | select((.title | type) == "string" and (.title | startswith($marker)))]') || die "issue list returned malformed JSON"
count=$(printf '%s' "$matches" | jq 'length')
```
The gate should use `jq -r 'if (.total_count|type)=="number" then .total_count else empty end'`, then validate the count as an integer with `is_integer` (`bin/classify-flake-run:53-61`, copy verbatim). An empty or non-integer count means `decision=run` with a `reason=` naming the malformed response.

**Integer validator to copy verbatim** (`bin/classify-flake-run:53-61`):
```bash
is_integer() {
  case "$1" in
    '' | '-' ) return 1 ;;
    -* ) case "${1#-}" in *[!0-9]* ) return 1 ;; * ) return 0 ;; esac ;;
    *  ) case "$1"      in *[!0-9]* ) return 1 ;; * ) return 0 ;; esac ;;
  esac
}
```

**Output + GITHUB_OUTPUT append + always exit 0** (`bin/classify-flake-run:93-99`):
```bash
echo "$classification"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "classification=$classification" >> "$GITHUB_OUTPUT"
fi

exit 0
```
Emit two lines on stdout, `decision=<x>` and `reason=<one line>`, in the `key=value` shape of `upsert-ci-issue`'s `printf 'action=create\nissue_number=%s\n'` (line 28), and append the same lines to `$GITHUB_OUTPUT`.

**API shape** (RESEARCH F3, probed): `"$GH_BIN" api "repos/$GITHUB_REPOSITORY/actions/workflows/$workflow/runs?head_sha=$sha&status=success&per_page=1"`. Return `.total_count`, and run a second call with `status=failure` for the upstream check.

---

### `test/threadline/ci_sha_gate_contract_test.exs` (test, fake-gh table) — NEW

**Analog:** `test/threadline/ci_issue_upsert_contract_test.exs` (whole file, 76 lines). The fixture location comes from the `@tag :tmp_dir` convention.

**Fake gh script pattern** (`ci_issue_upsert_contract_test.exs:5-28`). Swap `System.tmp_dir!()` for the ExUnit `tmp_dir`:
```elixir
  defp fixture(list_json) do
    root = Path.join(System.tmp_dir!(), "ci_upsert_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    log = Path.join(root, "calls")
    ...
    File.write!(gh, """
    #!/usr/bin/env bash
    set -eu
    printf '%s\n' "$*" >> "$CALL_LOG"
    if [ "$1 $2" = "issue list" ]; then cat "$LIST_JSON"; exit 0; fi
    ...
    exit 9
    """)

    File.chmod!(gh, 0o755)
    on_exit(fn -> File.rm_rf!(root) end)
    %{gh: gh, log: log, state: state, body: body}
  end
```
For the gate, dispatch on `"$1" = "api"`. Return the contents of `$SUCCESS_JSON` when `"$*"` contains `status=success`, and `$FAILURE_JSON` when it contains `status=failure`. Add a mode that exits non-zero, to model a 403 or network error, and one that prints `not-json`.

**Invocation with env seams** (`ci_issue_upsert_contract_test.exs:30-46`):
```elixir
    System.cmd(@script, [...args...],
      env: [{"GH_BIN", f.gh}, {"CALL_LOG", f.log}, {"LIST_JSON", f.state}],
      stderr_to_stdout: true
    )
```

**tmp_dir convention** (`test/threadline/repo_hygiene_guard_test.exs:10-19`; rule text at `CONTRIBUTING.md:165-172`):
```elixir
  use ExUnit.Case, async: true
  @moduletag :tmp_dir

  defp fixture_repo!(tmp_dir, files) do
    root = Path.join(tmp_dir, "repo_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
```
Test signature: `test "...", %{tmp_dir: tmp_dir} do`. No `on_exit` cleanup is needed under `tmp_dir`.

**Table rows to cover** (RESEARCH F3):
- schedule with success > 0 gives `skip`;
- `workflow_dispatch` with success > 0 gives `run`;
- push gives `run`;
- upstream failure > 0 with success == 0 gives `broken-upstream`;
- upstream success > 0 with failure > 0 gives `run`;
- a gh non-zero exit gives `run`;
- malformed JSON gives `run`;
- a missing `--workflow` is a non-zero usage error.

Also add a GITHUB_OUTPUT append row, copied from `flake_classifier_contract_test.exs:146-165`.

**Workflow-reachability asserts** (step-isolation idiom, `flake_classifier_contract_test.exs:174-176`):
```elixir
      [_, after_classify] = String.split(yaml, "Classify broken vs flaky", parts: 2)
      classify_step_body = after_classify |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()
```
Use it to assert:
- `flake-detection.yml` and `browser-full.yml` each call `bin/ci-sha-gate`;
- each carries `actions: read` in the job `permissions:` (P3);
- work steps carry `if: steps.gate.outputs.decision == 'run'`.

---

### `bin/browser-full-projects` (utility, transform) — NEW

**Analogs:** `bin/compare-required-contexts` (header rationale plus the exit-code contract) and `bin/verify-playwright-fail-fast` (the root-override env seam).

**Header + exit-code contract** (`bin/compare-required-contexts:1-29`):
```bash
#!/usr/bin/env bash
#
# compare-required-contexts — decide whether a branch's LIVE required status-check
# contexts are exactly the expected set.
#
# WHY THIS IS A SEPARATE SCRIPT
# ... Splitting the pure decision out makes every edge drivable from fixtures with no network,
# ... This is the same shape as
# `bin/classify-flake-run`, which `flake_classifier_contract_test.exs` drives directly.
#
# USAGE
#   compare-required-contexts <expected-context> [<expected-context>...] < rules.json
# exit 0 — ...
# exit 1 — they differ ...; reason on stderr.
# exit 2 — usage or unreadable input.

set -euo pipefail
```

**Root override seam for fixtures** (`bin/verify-playwright-fail-fast:3-4`):
```bash
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
E2E=${THREADLINE_PLAYWRIGHT_E2E:-"$ROOT/examples/threadline_phoenix/e2e"}
```
Give the script one root override, for example `THREADLINE_BROWSER_FULL_ROOT`, which defaults to the repo root. It reads three files relative to that root: `examples/threadline_phoenix/e2e/playwright.config.ts`, `.github/workflows/ci.yml` and `mix.exs`. The contract test then copies all three into `tmp_dir` and mutates them.

**Parse targets** (live files):
- **Config default set.** Take the `name: "..."` entries between `const projects = [` (`playwright.config.ts:22`) and `];` (`:124`), excluding the `...(lightLane` block (`:103`, `desktop-chromium-light` at `:106`), which is env-gated.
- **CI set, `ci.yml` flags.** Line 518 is `run: mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`. The regex in use is `~r/--project[= ]([a-z0-9-]+)/` (`ci_coverage_doc_contract_test.exs:42`).
- **CI set, alias flags.** `ci.yml:659` runs `run: mix verify.capture`. Its flags come from `mix.exs:353-359`:
  ```elixir
  defp verify_capture(args),
    do:
      verify_example_browser([
        "--project=tier-a-capture",
        "--project=tier-a-capture-light",
        "operator-tier-a-capture.spec.ts" | args
      ])
  ```

Fail closed on each of these:
- an empty config parse;
- an empty difference;
- `ci.yml` no longer running `mix verify.capture` while the alias's projects are still counted;
- a `name:` found outside the known regions.

Output one `--project=<x>` line per project, sorted.

---

### `test/threadline/browser_full_projects_contract_test.exs` (test, union contract) — NEW

**Analogs:** `ci_coverage_doc_contract_test.exs` and `ci_workflow_parity_contract_test.exs`.

**Anti-vacuous derive + moduledoc voice** (`ci_coverage_doc_contract_test.exs:1-25, 63-71`):
```elixir
  test "the workflow scan finds Playwright project flags at all" do
    projects = projects_in_workflows()

    assert projects != [],
           "no `--project` flags found across #{inspect(@workflow_paths)} — the derive " <>
             "source for the CI Coverage contract is broken. Without this assertion the " <>
             "test below would pass vacuously ..."
  end
```

**MapSet parity with drift-direction messages** (`ci_workflow_parity_contract_test.exs:185-197`):
```elixir
      assert MapSet.equal?(jobs, header),
             "ci.yml jobs vs header comment drift: " <>
               "only-in-jobs=#{inspect(MapSet.difference(jobs, header) |> Enum.sort())} " <>
               "only-in-header=#{inspect(MapSet.difference(header, jobs) |> Enum.sort())}"
```
Apply it to `CI ∪ BF == config` and to `MapSet.intersection(ci, bf) == MapSet.new()`.

**Mutation-control loop** (`ci_workflow_parity_contract_test.exs:579-611`):
```elixir
      mutate = fn path, from, to -> Map.update!(live, path, &String.replace(&1, from, to)) end
      controls = [
        {"flake-detection deps key led by the OS-family context value",
         mutate.(flake, "key: ubuntu-24.04-", "key: ${{ " <> @os_family_context <> " }}-")},
        ...
      ]

      for {control, mutated} <- controls do
        refute mutated == live, "#{control} control did not change the input"

        refute toolchain_contract_errors(mutated) == [],
               "#{control} mutation must make the toolchain pin contract fail"
      end
```
In this test, a mutation writes the mutated copy into `tmp_dir` and runs the script with the root override. The expected results are:
- a fake project added to the config appears in the output;
- dropping `--project=mobile-chromium` from the `ci.yml` copy moves `mobile-chromium` into the output;
- emptying the config makes the script exit non-zero.

**Real-subprocess tmp_dir precedent that copies the Playwright config** (`test/threadline/playwright_fail_fast_contract_test.exs:6-43`):
```elixir
  @tag :tmp_dir
  test "...", %{tmp_dir: tmp_dir} do
    clean_e2e = Path.join(tmp_dir, "e2e")
    File.mkdir_p!(clean_e2e)
    File.cp!(Path.join(@e2e, "playwright.config.ts"), Path.join(clean_e2e, "playwright.config.ts"))
    ...
    assert {output, 0} =
             System.cmd(@script, [], env: [{"THREADLINE_PLAYWRIGHT_E2E", clean_e2e}], stderr_to_stdout: true)
```
Also assert that `browser-full.yml` invokes `bin/browser-full-projects` and contains no literal `--project` flag.

---

### `bin/classify-flake-run` (MOD) + `test/threadline/flake_classifier_contract_test.exs` (MOD)

**Branch structure to extend** (`bin/classify-flake-run:63-91`). Insert the new arms before the existing chain and keep the `else classification="unknown"` default:
```bash
EXIT_CODE_RAW="${EXIT_CODE:-}"

if ! is_integer "$EXIT_CODE_RAW"; then
  ...
  classification="unknown"
else
  ...
  if [ "$EXIT_CODE_RAW" = "0" ]; then
    classification="pass"
  elif ! is_integer "$headers_raw"; then
    classification="unknown"
  elif [ "$headers_raw" -eq 0 ]; then
  ...
```
- Check `UPSTREAM=broken` first, which gives `broken-upstream`.
- Exit `124` with at least one header gives `inconclusive`. Exit `124` with 0 headers gives `unknown` with the reason "timed out before the suite started".
- Add a `reason=` output next to `classification=` (lines 95-97).
- Update the behavior table in the header (lines 20-35) and the line-3 comment ("50" becomes "15").

**Test row style** (`flake_classifier_contract_test.exs:52-69`):
```elixir
  defp run_classifier(log_path, exit_code_env) do
    env = case exit_code_env do nil -> []; value -> [{"EXIT_CODE", value}] end
    System.cmd(@script, [log_path], env: env, stderr_to_stdout: false)
  end

    test "exit code 0, any header count -> pass" do
      log = fixture_log(3)
      {output, exit_status} = run_classifier(log, "0")
      assert exit_status == 0
      assert String.trim(output) == "pass"
    end
```
- The script now prints `reason`, so switch the assertions to line-based ones such as `output =~ ~r/^inconclusive$/m`, or keep the classification alone on stdout and put the reason in GITHUB_OUTPUT only. Pick one and keep the old six rows green.
- Every new row carries a `refute ... == "flaky"` (the CR-02 idiom, line 105).
- Move the fixtures from `System.tmp_dir!()` (lines 31-50) to `@tag :tmp_dir` (HYG-03).

**Workflow-shape asserts to add**, using the same split idiom as Tests 2-4 (lines 167-225):
- a weekly cron plus `workflow_dispatch`;
- `timeout --signal=TERM` inside the "Repeat the suite until failure" body;
- a step `timeout-minutes` below the job `timeout-minutes`;
- `always()` on the classify, upload and issue steps;
- the close-on-green step calls `bin/upsert-ci-issue --close`.

---

### `bin/upsert-ci-issue` (MOD, `--close`) + its test

**Extend the arg loop and the `case "$count"`** (`bin/upsert-ci-issue:7-31`). Add `--close) close=1; shift ;;`, and relax only the `--title` requirement when `close=1` (line 19). In close mode:
- skip `label create` (line 23), or keep it; it is harmless;
- reuse the list and jq filter exactly (lines 24-26);
- 0 matches: `printf 'action=none\n'`;
- 1 match: reuse the number validation from line 29 (`grep -Eq '^[0-9]+$' || die`), then `issue comment "$number" --body-file`, then `issue close "$number" --reason completed`, and print `action=close\nissue_number=%s\n`;
- `*`: `die "ambiguous marker matched $count open issues"`, unchanged.

**Test additions:**
- The fake gh gains `if [ "$1 $2" = "issue close" ]; then exit 0; fi` (after line 21).
- Add three rows: none, close (assert the log contains `issue comment 41` and then `issue close 41`, in order), and ambiguous. Add one metacharacter row in `--close` mode, following lines 67-75.

**Workflow callers.** Each gets a sibling "Close ... on green" step that reuses the caller's `TITLE_PREFIX`/`LABEL` env:
- `flake-detection.yml:159-208`;
- `browser-full.yml:122-147`;
- `deps-health.yml:87-91`.

The exact YAML is in RESEARCH "Code Examples".

---

### `bin/verify-dialyzer-slice` (MOD, fail-closed) + `test/threadline/dialyzer_slice_contract_test.exs` (MOD)

**Insert the check into the existing `with` chain** (`bin/verify-dialyzer-slice:13-31`). Add a `:ok <- completed_run(raw_output)` clause between `raw_output(options)` and `parse_raw_output`. The `{:error, message}` arm already gives stderr plus `System.halt(1)`:
```elixir
    with {:ok, options} <- parse_options(argv),
         {:ok, fixture} <- load_fixture(options.fixture),
         {:ok, contract} <- validate_fixture(fixture),
         {:ok, raw_output} <- raw_output(options),
         {:ok, live_warnings} <- parse_raw_output(raw_output),
         :ok <- verify_live_warnings(contract, live_warnings) do
      ...
    else
      {:error, message} ->
        IO.puts(:stderr, "dialyzer slice verification failed: #{message}")
        System.halt(1)
    end
```
- Match the private-helper style of `parse_raw_output/1` (lines 284-300): `String.split("\n")` then filter.
- Strip ANSI, require exactly one line matching `^done \((passed successfully|warnings were emitted)\)$`, and reject any `:dialyzer.run error:` line.
- Keep `@dialyzer_command` and `@dialyzer_args` (lines 8-9) byte-identical.

**Test helper to amend** (`dialyzer_slice_contract_test.exs:158-181`). `run_fixture/2` writes `raw` verbatim. Append `"done (passed successfully)\n"` inside the helper so the existing synthetic positives stay green (P9).
- The helper currently writes under `_build/dialyzer-slice-contract/<n>` with `on_exit` cleanup.
- New negative tests should use `@tag :tmp_dir` and write the raw file there.
- The module is `async: false` (line 2); keep it.
- Negative rows:
  - raw output `":dialyzer.run error: Could not read PLT file .dialyzer/x.plt: no_such_file\n"` with no `done (` line gives `{output, 1}`, with output matching "did not complete";
  - empty raw output gives `{_, 1}`.
- Do not touch the maintainer's `.dialyzer`.

The tagged live test (lines 8-18) is unchanged. It only moves lanes.

---

### `test/test_helper.exs` (MOD) + `test/threadline/zero_skips_contract_test.exs` (MOD)

**Exclude list today** (`test/test_helper.exs:3-7`):
```elixir
topology_pooler? = System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1"

# Topology tests need PgBouncer + bootstrap DDL; keep them out of default `mix test`.
exclude = if(topology_pooler?, do: [], else: [pgbouncer_topology: true])
ExUnit.configure(exclude: exclude)
```
Add `live_dialyzer: true` to both branches with a one-line reason comment in the same voice ("needs a restored `.dialyzer` PLT; runs in `verify-dialyzer`").

**Invariant to widen, same commit** (`zero_skips_contract_test.exs:68-84`):
```elixir
    expected =
      if System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1",
        do: [],
        else: [{@topology_tag, true}]

    assert exclude == expected, ...
```
- Add `@live_dialyzer_tag :live_dialyzer` beside `@topology_tag` (line 25).
- `expected` becomes `[{@live_dialyzer_tag, true}]` or `[{@topology_tag, true}, {@live_dialyzer_tag, true}]`. Match the order `test_helper` builds.
- Update the moduledoc's "Two invariants" item 2 (lines 16-18) to name exactly two sanctioned environment gates and keep "no third tag".

---

### `.github/workflows/ci.yml` (MOD)

**Roster cut (one commit).** Remove the following:
- `verify-mechanical`, `verify-docs` and `verify-hex-package` from the line-2 header roster;
- the `verify-mechanical` job with its preceding comment (lines 538-586);
- the `verify-docs` job (779-805) and the `verify-hex-package` job (807-871);
- the `verify-capture` trailing step (lines 701-702):
  ```yaml
      - name: Assert mechanical checker clean over real evidence
        run: mix verify.mechanical
  ```
- clause "(3) MechanicalChecker.run/1 is clean over it" in the comment at 588-593;
- the three `needs:` entries (1005, 1008 and 1009 in the list starting at 997).

Also fix the prose "not sixteen" (983) and "all sixteen jobs" (1026).

**Live Dialyzer step in `verify-dialyzer` (lines 137-257).** Place it after the "Analyze and measure with Dialyzer" step (225-257), so it follows the PLT restore/build and save.
- The job today has `env: MIX_ENV: dev` and **no services**.
- Copy the Postgres `services:` block and `DB_HOST`/`DB_PORT` env verbatim from any DB job, for example the `verify-mechanical` block at 548-566, captured before deletion:
  ```yaml
    env:
      DB_HOST: localhost
      DB_PORT: 5432
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
  ```
- The step overrides `MIX_ENV` at step level: `env: MIX_ENV: test`, with `run: mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer`, or the named alias if one is added.
- Keep the job's `timeout-minutes: 9` comment derivation honest (lines 140-142), or re-derive it. The topology test pins both the literal and the formula.

---

### `.github/workflows/flake-detection.yml` (MOD)

**Step idioms to preserve:**
- The **repeat step** (lines 94-102) keeps `set +e`, `PIPESTATUS[0]` and the `exit_code=` write. Wrap the command as `timeout --signal=TERM --kill-after=60s 55m mix verify.flake 2>&1 | tee flake-detection.log`.
- **Classify** (116-131) keeps `if: always()` and `EXIT_CODE` from step outputs. Add `UPSTREAM: ${{ steps.gate.outputs.decision == 'broken-upstream' && 'broken' || '' }}`, or equivalent wiring.
- The **issue step** `case` (171-184) gains `inconclusive` and `broken-upstream` arms. The `*)` arm should print `${REASON}` from the classifier and drop the hard-coded "No `Running ExUnit with seed:` header was found" sentence (P10).
- The **fail step** (213-217) stays `always() && != 'pass'` (red on inconclusive and broken-upstream, P1). It must not fire on `skip`. Gate it on `steps.gate.outputs.decision != 'skip'`, or make classify emit `skip`.

**Header comment arithmetic** replaces lines 31-41 in the same measured-evidence voice: "288 s + 15 × 165 s = 2,763 s ≈ 46 min; step 55, job 70". Also change the trigger comment at lines 20-21 (nightly becomes weekly) and the prose at lines 1-5 ("Opt-in / nightly").

**Job permissions** (42-44) gain `actions: read`.

---

### `.github/workflows/browser-full.yml` (MOD)

- The run step (100-105) becomes a projects step plus a run step. Replace the "Unrestricted (no per-project flags)" comment:
  ```bash
  mapfile -t projects < <(bin/browser-full-projects)
  mix verify.example_browser "${projects[@]}"
  ```
- Add the gate step first. Work steps get `if: steps.gate.outputs.decision == 'run'`, and the permissions block (40-44) gains `actions: read`.
- The failure issue step (122-147) keeps `if: failure()`. Add the close step with `if: success()` (and `decision == 'run'`, so a skip run does not comment).
- Rewrite the header (1-16) and the issue-body prose (134-142), which say "whole Playwright project set".

---

### `.github/workflows/release.yml` (MOD, lines 189-206) + `test/threadline/release_control_plane_contract_test.exs` (MOD)

**Live job** (`release.yml:189-206`):
```yaml
  bootstrap-release-pr-ci:
    name: Bootstrap CI on Release PR
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    # After the pin sync, so the dispatched run tests the release PR's final head.
    # always(): a failed pin sync must still produce a (red) CI run on the release
    # PR. ...
    needs: [release-please, sync-release-pr-pins]
    if: always() && github.event_name == 'push' && needs.release-please.outputs.prs_created == 'true'
    permissions:
      actions: write
      contents: read
    steps:
      - name: Dispatch CI on release PR branch
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: gh workflow run ci.yml --ref release-please--branches--main -R "${{ github.repository }}"
```
- Add a job-level `env: RELEASE_PAT_CONFIGURED: ${{ secrets.RELEASE_PLEASE_TOKEN != '' }}` and a step `if: env.RELEASE_PAT_CONFIGURED != 'true'`.
- `needs:`, `if:` and `permissions:` stay byte-identical.

**Test idioms** (`release_control_plane_contract_test.exs`):
- `job_block!/2` (lines 184-195) isolates the job.
- Assertions are regexes anchored at 4-space job-level indent: `~r/^    needs: \[release-please, sync-release-pr-pins\]$/m` (lines 170-172).
- The mutation-control idiom, from lines 150-160:
  ```elixir
    mutated = String.replace(sync, "ref: release-please--branches--main\n          persist-credentials: false\n", "ref: release-please--branches--main\n")
    refute mutated == sync, "the credential-free checkout control did not change the input"
    refute checkout_count.(mutated) == credential_free.(mutated), "..."
  ```
- Add controls that drop the step `if:` and flip `!=` to `==`. Add `refute bootstrap =~ ~r/gh run list|actions\/runs/`, the never-queries-runs invariant.

---

### `test/threadline/ci_topology_contract_test.exs` (MOD)

- **`verify-docs` job-id assert.** Lines 96-102 carry `assert Regex.match?(~r/^  verify-docs:/m, yaml)`. Remove the assert or retarget it to a surviving job.
- **Dominance pins.** Model them on the bump-rehearsal test (lines 653-698: `workflow_job/2`, `String.contains?`, and messages that name the consequence). Add assertions that:
  - `mix.exs` `verify_release/1` (279-288) still contains `"MIX_ENV=dev mix docs --warnings-as-errors"` and `"mix hex.build"`;
  - the evaluator defaults to rehearsal mode.
- **Dialyzer live-test pins.** Add them as new `{bool, message}` tuples inside `dialyzer_topology_errors/3` (376-493). Add a position entry to the `order` list (383-391) after `THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=`. Add mutation controls to the list at 126-162.
  - The pins should cover:
    - the `--only live_dialyzer` step exists in `verify-dialyzer`;
    - it appears in no other job;
    - the `test_helper` exclusion is present;
    - `ci.all` carries the `cmd env MIX_ENV=test mix test ... --only live_dialyzer` entry exactly once, after `"cmd env MIX_ENV=dev mix verify.dialyzer"`.
  - Use `ci_all_entries/1` (495-500).
  - `workflow_step/2` (541-549) isolates a step by name.

---

### `test/threadline/ci_workflow_parity_contract_test.exs` (MOD)

- **Widen the OS-family check** (test at 733-762, helper at 1263-1270). Loop `os_family_context_errors(path, yaml)` over `all_workflows()` (126-128). Add a control that injects `"      # e.g. " <> @os_family_context` into the `flake-detection.yml` entry of the map (the `Map.update!` mutate idiom at 579).
- **setup-beam count** (543-545): `assert setup_beam_steps - 1 == 14` becomes `== 11`, and the message text "(13 file-fed, 1 matrix-fed)" becomes "(10 file-fed, 1 matrix-fed)".
- **`verify-docs` controls** at 553-556 (`docs_job = workflow_job(live, "verify-docs")`) and around 324-368 (the moved beam-step control): retarget both to `verify-credo`.
- Three-way roster parity (171-197) self-checks once `ci.yml` and CONTRIBUTING List 1 agree.

---

### `test/threadline/ci_coverage_doc_contract_test.exs` (MOD)

- `projects_in_workflows/0` (40-45) scans `@workflow_paths` for literal `--project` flags. Once Browser-full has none, extend it to take `System.cmd("bin/browser-full-projects", [])` output plus the CI set, so the rows of the `## CI Coverage` table are checked against the real union, including `mix.exs` capture projects.
- Keep the anti-vacuous test (63-71) and the table-row regex `~r/^\|\s*`#{Regex.escape(project)}`\s*\|/m` (81).

---

### `mix.exs` (MOD)

- Line 188: `"verify.flake": ["test --repeat-until-failure 50"]` becomes `15`. Rewrite the comment at 185-187 ("Opt-in / nightly" becomes weekly).
- `ci.all` (207-233): add `"cmd env MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer"` immediately after `"cmd env MIX_ENV=dev mix verify.dialyzer"` (227). This follows the `cmd env` precedent on that line and at 232 (P5: a bare second `test` is a Mix no-op).
- If a named alias is added, register it in `preferred_envs` (lines 11-22), as done for `"verify.mechanical": :test`.
- Keep `verify.mechanical` (153). Update the comment at 352 ("CI gates the committed scorecard JSON via verify.mechanical"): it now runs inside `verify.test`.

---

### `CONTRIBUTING.md`, `guides/upgrade-path.md`, `test/threadline/upgrade_path_doc_contract_test.exs`

These are text edits pinned by tests:
- CONTRIBUTING roster (~522-526), job table (~615-618), branch-protection list (~726-727) and `## CI Coverage` (458-498);
- flake prose at 179-184 ("full suite, 50 repeats", "run nightly");
- the Dialyzer contract section (from ~623);
- `guides/upgrade-path.md:62` names "CI jobs `verify-test` / `verify-docs`", and `upgrade_path_doc_contract_test.exs:125` asserts `` "`verify-docs`" ``. Change both together, with no planning vocabulary in the published guide.

---

### ECON-07 tools (NEW copies)

**Source:** `.planning/phases/214-baseline-measurement/tools/` (tracked: `collect-ci-runs.sh`, `summarize-ci.py`, `check-citations.py`).
- Copy them to `.planning/phases/218-ci-economy-remove-waste/tools/`.
- The collector's data directory is derived from its own location (`collect-ci-runs.sh:34-38`, `PHASE_DIR="$(dirname "$SCRIPT_DIR")"`), so the copy writes into 218's `raw/ci/` without edits.
- In `summarize-ci.py:35-44`, retarget only the hard-coded `SELF = "python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py"` string.
- Prove the copies carry no logic change with `diff`.

## Shared Patterns

### Decision logic in `bin/`, wiring in YAML
**Source:** `bin/classify-flake-run:5-9` ("A runbook is an assertion; a script is proof") and `bin/compare-required-contexts:6-19`.
**Apply to:** `ci-sha-gate`, `browser-full-projects`, `classify-flake-run`, `upsert-ci-issue --close`, `verify-dialyzer-slice`.
- Scripts are executable (`flake_classifier_contract_test.exs:196-201` asserts the `0o111` mode bit).
- Scripts print `key=value` and append to `$GITHUB_OUTPUT` when set.

### Fake external binary via env seam
**Source:** `ci_issue_upsert_contract_test.exs:5-28` (`GH_BIN` + `CALL_LOG`) and `playwright_fail_fast_contract_test.exs` (`THREADLINE_PLAYWRIGHT_E2E`).
**Apply to:** all new script tests. Never hit the network or the real repo state.

### Scratch files: `@tag :tmp_dir`
**Source:** `CONTRIBUTING.md:165-172` and `repo_hygiene_guard_test.exs:10-11`.
**Apply to:** every new fixture. Build fake paths at runtime by concatenation (`repo_hygiene_guard_test.exs:57-64`) so no home-path literal lands in source.

### Mutation controls prove a contract is not vacuous
**Source:** `ci_workflow_parity_contract_test.exs:579-611`, `ci_topology_contract_test.exs:126-167` and `release_control_plane_contract_test.exs:150-160`.
**Apply to:** every new YAML or roster assertion. Each control first asserts `refute mutated == live`, then asserts that the contract fails.

### Needles assembled at runtime
**Source:** `ci_workflow_parity_contract_test.exs:418-422` (`@os_family_context "runner" <> ".os"`) and `zero_skips_contract_test.exs:27-41`.
**Apply to:** any test that forbids a literal the test file itself would contain.

### Job and step isolation helpers
**Source:**
- `workflow_job/2` (`ci_workflow_parity_contract_test.exs:838-843`, `ci_topology_contract_test.exs:514`);
- `job_steps/1` (parity 847-852);
- `workflow_step/2` (topology 541-549);
- `job_block!/2` (release test 184-195);
- the split idiom `String.split(yaml, "<step name>", parts: 2)` plus `~r/\n\s{6}- name:/` (flake test 174-176).

**Apply to:** all workflow-shape assertions. Reuse the helper local to the test file you are extending. Do not create a shared module.

### Anti-laundering invariants
**Source:** `release_control_plane_contract_test.exs` ("the required check launders nothing", lines 89-112) and `ci_topology_contract_test.exs:653-698`.
**Apply to:** the roster cut. No `allowed-skips`, no job-level `if:` on a `ci-required` member, no `continue-on-error`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.planning/phases/218-ci-economy-remove-waste/218-REMEASURE.md` | evidence doc | — | Only a partial analog exists (`214-BASELINE.md` structure). Its figures must come from the copied tools and cite run IDs, with projections labeled `[inference]`, verified by the copied `check-citations.py`. |

No existing script queries `gh api .../actions/workflows/.../runs`. That API shape comes from RESEARCH F3. The script scaffolding itself has full analogs.

## Metadata

**Analog search scope:** `bin/`, `test/threadline/*_contract_test.exs`, `test/test_helper.exs`, `.github/workflows/`, `mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts`, `CONTRIBUTING.md`, `.planning/phases/214-baseline-measurement/tools/`
**Files scanned:** ~30
**Pattern extraction date:** 2026-09-27
