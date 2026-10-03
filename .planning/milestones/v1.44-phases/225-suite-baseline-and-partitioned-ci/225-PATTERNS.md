# Phase 225: Suite Baseline and Partitioned CI - Pattern Map

**Mapped:** 2026-09-30
**Files analyzed:** 12 (new/modified, per CONTEXT D-01..D-20 and RESEARCH Wave-0 Gaps)
**Analogs found:** 11 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|---------------|
| `bin/ci-test-partitions` (new) | utility (CI entrypoint script) | batch / event-driven (spawns + aggregates) | `bin/verify-deps-audit` | exact (named template in D-09) |
| `mix.exs` alias `verify.test_partitioned` (new) | config (Mix alias) | request-response (shells to script) | `mix.exs` `verify_bench_compile/1` / `verify_deps_audit/1` function aliases | exact |
| `config/test.exs:10` (edit) | config | CRUD (DB name resolution) | same file, same line (D-04) — no separate analog needed | exact |
| `.github/workflows/ci.yml` `verify-test` job (edit) | config (CI workflow) | batch | same file, `verify-dialyzer` job's timing/self-test steps | role-match |
| `test/threadline/ci_topology_contract_test.exs` (edit — extend `mutation_controls`) | test (contract/mutation) | transform (pure checker over text) | same file, Dialyzer `mutation_controls` block (~L119-219) | exact |
| `test/threadline/ci_workflow_parity_contract_test.exs` (edit — literal pins) | test (contract) | transform | same file, `@every_lane_steps` + mutation-control fixtures (~L511-604, L2005-2009, L5640-5689) | exact |
| `.github/workflows/flake-detection.yml` (edit — resize budget) | config (CI workflow) | batch | same file, L36-53/L139 (unchanged topology, new constants) | exact |
| `test/threadline/flake_classifier_contract_test.exs` (edit — Test 6 sizing) | test (contract) | transform | same file, `sizing_violations/4` (~L749-846) | exact |
| `test/support/telemetry_helpers.ex` (new) | utility (test support) | event-driven (telemetry forwarding) | `test/support/async_helpers.ex` | role-match (style/doc/on_exit template); no direct telemetry-filter analog exists |
| `test/threadline/operator_surface/auth_test.exs` (edit — async: true + helper) | test | event-driven | same file's current `setup`/`:telemetry.attach` block (~L24-67) | exact (self is the "before" state) |
| `test/threadline/operator_surface/export_auth_plug_test.exs` (edit) | test | event-driven | same file's current `setup` block (~L15-30) | exact |
| `test/threadline/operator_surface/theme_auth_plug_test.exs` (edit) | test | event-driven | same file's current `setup` block (~L11-26) | exact |
| `test/threadline/health/trigger_findings_non_owner_test.exs` (edit — role-name collision fix, Pitfall 3) | test | CRUD (DDL against Postgres) | same file, line 11 (role-name construction) | exact |
| `CONTRIBUTING.md` (edit — telemetry rule L181, ci-required roster / CI job table, Deterministic tests) | config (doc) | transform | same file, "Deterministic tests" (L158-190) and "`ci-required` needs: roster" (L546+) | exact |
| `225-BASELINE.md` (new) | utility (doc) | transform (citation-checked) | prior phases' `NNN-BASELINE.md`/`EVIDENCE.md` pattern + `check-citations.py` | role-match |
| `.planning/phases/225-.../tools/check-citations.py` (new, copied) | utility (script) | transform | `.planning/milestones/v1.43-phases/222-seed-006-.../tools/check-citations.py` | exact (explicit copy target) |
| `.planning/phases/225-.../tools/ci-job-timing.sh` (new) | utility (script) | transform (reads gh API, computes proxy) | `.planning/milestones/v1.43-phases/219-deps-only-build-cache/tools/collect-ci-runs.sh` + `summarize-ci.py` | role-match |

## Pattern Assignments

### `bin/ci-test-partitions` (new)

**Analog:** `bin/verify-deps-audit` (repo root, tracked)

**Header/doc + seam pattern** (lines 1-58):
```bash
#!/usr/bin/env bash
# <header doc: what this proves, modes, --self-test cases, the seam>
#
# Seam: MIX_BIN (default `mix`) lets tests substitute a fake `mix` binary to
# exercise this script's behavior fully offline. Never used by real callers.

set -euo pipefail

die() {
  printf 'verify-deps-audit: %s\n' "$*" >&2
  exit 2
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
MIX_BIN="${MIX_BIN:-mix}"
```
`bin/ci-test-partitions` copies this exact shape: `set -euo pipefail`, a `die()` helper prefixed with the script's own name, `SCRIPT_DIR`/`ROOT` resolution, and a documented test-only env-var seam (name it per D-10, e.g. `THREADLINE_CI_TEST_PARTITIONS_SELF_TEST_INJECT_FAILURE` or similar — Claude's Discretion) — "Never used by real callers" is the exact phrasing to reuse.

**`--self-test` mode pattern** (lines 92-200): `verify-deps-audit --self-test` does setup in a throwaway dir under gitignored `tmp/` (`mkdir -p "$ROOT/tmp"`, `mktemp -d "$ROOT/tmp/deps-audit-self-test.XXXXXX"`, `trap cleanup ... EXIT`), runs the real script with a deliberately-broken input, asserts non-zero exit AND asserts the failure reason is the *right* one (not vacuous red — e.g. `grep -q 'Advisories:'`), then prints one final `ok` line summarizing every case and `exit 0`. `bin/ci-test-partitions --self-test` follows this: inject one failing partition via the documented seam, assert non-zero exit, assert every OTHER partition's log shows it passed (not vacuous — the self-test must prove the SPECIFIC failing partition is what turned the gate red), then assert `--self-test` with the seam unset (or no injected failure) exits zero.

**Never-bare-`wait` aggregation pattern** (from RESEARCH Code Examples, not literally in `verify-deps-audit` but derived from its `FAILURES=()` aggregation idiom, lines 315-362):
```bash
FAILURES=()
for d in "${DIRS[@]}"; do
  ...
  if [ "$deps_get_status" -ne 0 ]; then
    FAILURES+=("FAIL $d: ...")
    continue
  fi
  ...
done
if [ ${#FAILURES[@]} -gt 0 ]; then
  printf '%s\n' "${FAILURES[@]}"
  exit 1
fi
```
`bin/ci-test-partitions` mirrors this "aggregate across N, never fail-fast on the first, print all failures, then exit 1" shape but for background PIDs instead of a directory loop:
```bash
pids=()
for i in $(seq 1 "$N"); do
  MIX_TEST_PARTITION="$i" mix test --partitions "$N" --no-compile --no-deps-check \
    > "partition-${i}.log" 2>&1 &
  pids+=("$!")
done

fail=0
for i in "${!pids[@]}"; do
  wait "${pids[$i]}" || fail=1
done
```
Never a bare `wait` (always returns 0) or `a & b & wait` (returns only the last job's status) — this is the exact bug class D-09 names and the runtime self-test control exists to catch.

---

### `mix.exs` — `verify.test_partitioned` alias (new)

**Analog:** same file, `verify_bench_compile/1` and `verify_deps_audit/1` (lines 262-297, 285-297)

**Function-alias pattern** (lines 130-131, 189, 285-290):
```elixir
defp aliases do
  [
    ...
    "verify.deps_audit": &verify_deps_audit/1,
    ...
  ]
end

defp verify_deps_audit(_args) do
  case Mix.shell().cmd("bin/verify-deps-audit") do
    0 -> :ok
    status -> Mix.raise("verify.deps_audit failed (#{status})")
  end
end
```
`"verify.test_partitioned": &verify_test_partitioned/1` follows this exact shape — a function alias (not a plain `["cmd ..."]` list) that shells to `bin/ci-test-partitions`, per RESEARCH Pattern 2's explicit instruction that D-12 requires the script be the single source of truth called by both CI and the alias. Place the new alias entry directly after `"verify.test": ["test"]` (line 143) so both are visually adjacent, and add a one/two-line comment above it in the same voice as the `verify_bench_compile` comment (lines 181-183: "Per-PR proof that ... (SUITE-0N): ... wired into ci.all right after ...").

**`cli/0` `preferred_envs` pattern** (lines 7-31): `"verify.test": :test` is already present at line 17. If the new alias needs its own explicit env (it inherits `mix test`'s `:test` env via the underlying `mix test` call either way, but be explicit per this file's own convention of listing every alias that touches `Threadline.Test.Repo`), add `"verify.test_partitioned": :test` alongside it.

**`ci.all` stays on `verify.test`, never the partitioned alias** (line 237, D-08): do not touch this line — `ci.all` keeps running unpartitioned `verify.test`, only `ci.yml`'s `Run tests` step in `verify-test` changes to the new alias.

---

### `test/threadline/ci_topology_contract_test.exs` — extend `mutation_controls` (D-10 shape control)

**Analog:** same file, the Dialyzer topology `mutation_controls` list and pure checker (lines 119-336, read in full)

**mutation_controls tuple-list + loop pattern** (lines 130-198):
```elixir
mutation_controls = [
  {"PLT timing command",
   String.replace(
     yaml,
     "/usr/bin/time -v -o \"$time_file\" mix dialyzer --plt",
     "mix dialyzer --plt"
   )},
  ...
]

for {control, mutated_yaml} <- mutation_controls do
  refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [],
         "#{control} mutation must make the Dialyzer topology contract fail"
end

for marker <- [
      "THREADLINE_DIALYZER_PLT_CACHE=",
      ...
    ] do
  mutated_yaml = String.replace(yaml, marker, "THREADLINE_BROKEN_MARKER=")

  refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [],
         "removing stable marker #{marker} must make the topology contract fail"
end
```
The new partition-gate checker (e.g. `partition_topology_errors/2`, taking `ci.yml` text and `mix.exs` text) follows this exact `{label, mutated_text}` tuple-list + `refute checker(mutated) == []` loop shape. Per D-10, assert:
- the `Run tests` step in `verify-test` exists and its `run:` invokes the committed script/alias, not inline `&`/`wait`
- that step occurs after `Compile (warnings as errors)` (reuse the `:binary.match/2` position-comparison idiom at lines 76-95, e.g. `{pos_compile, _} = :binary.match(yaml, "mix compile --warnings-as-errors")`)
- a step literally named `Prove the gate goes red (failing partition)` exists (or wherever Claude's Discretion places it) and its `run:` invokes `bin/ci-test-partitions --self-test`

Mutation inputs: rename the self-test step away, replace the script invocation with inline `a & b & wait` shell text, move the partition step before compile — each must go red via `refute ... == []`.

**Leave-untouched instruction:** do NOT touch `test "the sole required-check decision pins alls-green immutably"` (lines 106-117) — D-10 explicitly says leave it alone.

**Pure-checker-function signature pattern** (referenced, not shown — `dialyzer_topology_errors/3` is called at line 124 and defined further in the file past the read window): a function that takes committed-file text as arguments (never shells out, never does I/O beyond the `File.read!` already done by the caller) and returns `[]` on the real files, a non-empty list of string errors otherwise.

---

### `test/threadline/ci_workflow_parity_contract_test.exs` — update literal `mix verify.test` pins (Pitfall 1)

**Analog:** same file — treat as self-referential edit, not a cross-file analog

**The pin that MUST change** (lines 2005-2009):
```elixir
@every_lane_steps [
  {"Compile (warnings as errors)", "mix compile --warnings-as-errors"},
  {"Verify no compile-connected xref cycles", "mix verify.xref_cycles"},
  {"Run tests", "mix verify.test"}
]
```
→ becomes `{"Run tests", "mix verify.test_partitioned"}`. This is `every_lane_step_errors/1`'s guard that the step exists, has no `if:` key, runs the exact command, and uses the default shell.

**Pins to re-read in context before touching (deliberate mutation-input text, NOT stale):**
- Line 511: `run_tests = "      - name: Run tests\n        run: mix verify.test\n"` — a fixture constant used to build synthetic `ci.yml` text for other mutation controls (lane-skip, unable-to-fail, quoted-if, space-before-colon variants at lines ~554-604, and shell-override controls at ~620-626). Update this fixture's `mix verify.test` to `mix verify.test_partitioned` ONLY if the surrounding mutation controls are proving something about the (new) live command; if a control is proving e.g. "any command is unable to fail once wrapped in `|| true`", the literal command text inside the mutation itself (line 565's `mix verify.test || true`) is fine to leave as a generic example UNLESS it must match `run_tests` byte-for-byte to `refute`/`assert` against it (grep-diff each one; this file's own comment at ~2002-2007 explains the taxonomy of skip/unable-to-fail/shell mutations).
- Line 5689 (`fixture_verify_test/0`, full synthetic `verify-test` job block, ~5640-5689): a baseline fixture used elsewhere in the file. Update its `run: mix verify.test` to match the new real command, since it is asserted to equal a parsed real job elsewhere.

**How to avoid blind find-replace:** grep the file for every literal `mix verify.test` occurrence (8 hits per RESEARCH Pitfall 1), and re-read each in its local `test "..."` block before deciding whether it represents (a) the live `ci.yml` expectation → update, or (b) mutation-input text deliberately testing a DIFFERENT failure class (skip, unable-to-fail, shell override) where only the *base* string changing to the new command matters, not the mutation's shape.

---

### `.github/workflows/flake-detection.yml` + `test/threadline/flake_classifier_contract_test.exs` Test 6 (D-11 resize)

**Analog:** same test file, Test 6 describe block (lines 749-847, read in full)

**Sizing-constant + pure-arithmetic pattern** (lines 756-790):
```elixir
@cold_first_run_ceiling_s 269
@repeat_ceiling_s 214
@headroom_percent 10

defp flake_repeats(mix_exs) do
  [_, n] = Regex.run(~r/"verify\.flake":\s*\["test --repeat-until-failure (\d+)"\]/, mix_exs)
  String.to_integer(n)
end

defp budget_seconds(yaml) do
  [_, minutes] =
    Regex.run(~r/timeout --signal=TERM --kill-after=60s (\d+)m mix verify\.flake/, yaml)

  String.to_integer(minutes) * 60
end

defp sizing_violations(repeats, cold_s, repeat_s, budget_s) do
  needed = cold_s + repeats * repeat_s
  usable = div(budget_s * (100 - @headroom_percent), 100)

  [
    {repeats >= 1 and repeats <= 15, "repeats (#{repeats}) must stay within D-02's bound of 15"},
    {needed <= usable, "1 + #{repeats} runs need #{needed} s ..."}
  ]
  |> Enum.reject(&elem(&1, 0))
  |> Enum.map(&elem(&1, 1))
end
```
After re-measuring post-SUITE-03 per-iteration time (D-11), update `@cold_first_run_ceiling_s` and `@repeat_ceiling_s` to the new cited figures (with a fresh comment citing the new run ID, mirroring the existing comment at lines 750-755 that cites run `36359135268`). Keep `sizing_violations/4`'s structure unchanged — it's a pure function over four numbers, already correctly shaped for re-derivation.

**Doc-consistency assertion pattern** (lines 802-812): the workflow comment, `CONTRIBUTING.md`, and the classifier itself must all state the same repeat count and run ID — `assert yaml =~ "run 36359135268"` becomes the new run ID once D-11's re-measurement lands. Mirror this for whatever the new cited run is.

**Mutation-control pattern for sizing** (lines 814-846): `sizing_violations(15, @cold_first_run_ceiling_s, 209, budget)` (the old/reverted shape) must show `"over"` in its output; a `reverted` mix.exs with the old repeat count must also be caught. Keep this shape, updating literal numbers to match the phase's fresh figures.

---

### `test/support/telemetry_helpers.ex` (new)

**Analog:** `test/support/async_helpers.ex` (style/doc/`on_exit` template — no direct telemetry-filter precedent exists in this repo)

**Module doc + helper-function style** (lines 1-33):
```elixir
defmodule Threadline.AsyncHelpers do
  @moduledoc """
  Determinism helpers for tests that touch background processes, timers, or
  PostgreSQL advisory locks. Imported by `Threadline.DataCase`.
  ...
  """

  import ExUnit.Assertions

  @doc """
  Polls `fun` until it returns a truthy value or `:timeout` ms elapse.
  ...
  """
  @spec assert_eventually((-> any()), keyword()) :: any()
  def assert_eventually(fun, opts \\ []) when is_function(fun, 0) do
    ...
  end
```
`test/support/telemetry_helpers.ex` (as `Threadline.Test.TelemetryHelpers`, per D-16's exact contract) follows this: a `@moduledoc` explaining the problem it solves (VM-global telemetry handlers cross-contaminating concurrently-running `async: true` tests), a `@doc` + `@spec` per public function, and registration via `ExUnit.Callbacks.on_exit/1` for cleanup — mirroring `with_advisory_lock_held/3`'s `try/after` and `stop_named_process!/1`'s cleanup-on-exit idiom (lines 61-77, 85-101).

**D-16's required contract** (from CONTEXT/RESEARCH, not from an existing file since none exists yet): `attach_telemetry!(events)` attaches a handler whose config holds `test_pid` and a fresh `ref`; the handler forwards `{event, ref, measurements, metadata}` only when `self() == test_pid` or `test_pid in Process.get(:"$callers", [])`; returns `ref`; registers `on_exit(fn -> :telemetry.detach(ref_or_handler_id) end)`. Use `:telemetry.attach_many/4` (plural param name in D-16's own spec implies the list form). Treat RESEARCH's sketch (Code Examples section) as a contract-level illustration only, not copy-paste — validate the exact `:telemetry` v1.2 handler-config semantics when implementing.

**Current `async: false` shape being replaced** (the "before" state in all three SUITE-03 files — `auth_test.exs` lines 24-67, `export_auth_plug_test.exs` lines 15-30, `theme_auth_plug_test.exs` lines 11-26):
```elixir
setup do
  pid = self()
  handler_id = "export_auth_plug_test_#{System.unique_integer()}"

  :telemetry.attach(
    handler_id,
    [:threadline, :operator_surface, :authorize],
    fn name, measurements, metadata, _config ->
      send(pid, {:telemetry_event, name, measurements, metadata})
    end,
    nil
  )

  on_exit(fn -> :telemetry.detach(handler_id) end)
  :ok
end
```
This per-test unique-handler-id pattern already avoids handler-ID collisions across tests — the NEW problem it does NOT solve is cross-test event delivery (any concurrently running `async: true` test emitting the same event name still reaches this handler). The replacement wires `attach_telemetry!/1` into `setup` in place of this block, then each test's `assert_received {:telemetry_event, [...], %{result: :granted}, _meta}` becomes `assert_receive {[...], ^ref, %{result: :granted}, _meta}` (matching the returned `ref`).

**D-19 module header comments to remove:**
- `auth_test.exs` lines 2-6 ("async: false — this module attaches a process-global :telemetry handler ...")
- `export_auth_plug_test.exs` lines 4-7 (same pattern)
- `theme_auth_plug_test.exs` — no header comment currently present at lines 1-4 (only `@moduledoc false`); no removal needed there, just flip `async: false` → `async: true` at line 4.

**D-17 mutation control (new test, in one of the three files or a small new test module):** spawn an unrelated process (not a `$callers` child), have it emit the same telemetry event, assert the handler filter does NOT deliver it to the test process; assert the test's own emission IS delivered. If the `self()`/`$callers` filter is removed, this test must go red.

---

### `test/threadline/health/trigger_findings_non_owner_test.exs` — role-name collision fix (Pitfall 3)

**Analog:** same file, line 11 (self-referential edit)

**Current construction:**
```elixir
role = "threadline_findings_probe_#{System.unique_integer([:positive])}"
```
**D-04-mirroring fix** (per RESEARCH's concrete recommendation): append the partition env var alongside the existing unique integer, same style as `config/test.exs:10`'s own `#{System.get_env("MIX_TEST_PARTITION")}` interpolation:
```elixir
role =
  "threadline_findings_probe_#{System.get_env("MIX_TEST_PARTITION", "0")}_#{System.unique_integer([:positive])}"
```
This is a one-line fix; fold it into the D-12 atomic gate commit (or a tiny preceding commit) since `CREATE ROLE` is cluster-wide and `System.unique_integer/1` is per-BEAM-VM, so concurrent partition processes can otherwise collide on the same role name (Postgres `42710 duplicate_object`).

---

### `CONTRIBUTING.md` — telemetry rule replacement (D-19) + roster/job-table + Deterministic-tests updates

**Analog:** same file, "Deterministic tests" section (lines 158-200) and "`ci-required` needs: roster" (lines 546-575)

**Current telemetry bullet to replace** (within the "Rules of thumb" list, ~line 181-183):
```markdown
- **Telemetry tests are `async: false`.** `:telemetry` handlers are
  process-global; an `async: true` module that attaches a handler will receive
  events emitted by *any* concurrently-running test for the same event name.
```
Replace with the narrower D-19 rule: async is allowed when the test uses `attach_telemetry!/1` (from `test/support/telemetry_helpers.ex`) and emits in-process; keep a version of the old warning for tests that emit from other processes (spawned/Task-based emitters still need `async: false` or explicit filtering).

**CI job table row to update** (line 650):
```markdown
| `verify-test` | compile `--warnings-as-errors` + `mix verify.xref_cycles` + `mix verify.test` (Postgres service) |
```
→ update `mix verify.test` to `mix verify.test_partitioned` (and optionally note the partition count/DB-per-partition scheme), mirroring how this table already documents each job's step sequence.

**`ci-required` needs: roster** (lines 552-570): the `verify-test` bullet stays as a job id — no change needed there (D-12 keeps job `id:`s unchanged) — but the prose around it (lines 546-551, explaining what the aggregate proves) may need a one-line addendum if the partition step's self-test becomes a documented sub-step of `verify-test`; keep the roster's job-id list itself untouched.

**"Reproduce / prove determinism" block** (lines 197-200) already documents `mix verify.flake` as "full suite, 12 repeats" — D-11 requires this exact string (`"full suite, #{repeats} repeats (fresh seed each)"`, per `flake_classifier_contract_test.exs:810`) to track the new repeat count if D-11's re-measurement changes it.

---

### `.planning/phases/225-.../225-BASELINE.md` + `tools/check-citations.py` (D-14b)

**Analog:** `.planning/milestones/v1.43-phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py` (+ its `fixtures/cited.md`, `fixtures/uncited.md`)

**Copy-and-widen pattern** (lines 1-40 of the source, read in full):
```python
#!/usr/bin/env python3
"""check-citations.py - every figure in a baseline doc must cite a run or a command.
...
"""
EXEMPT = [
    re.compile(r"\b\d{4}-\d{2}-\d{2}\b"),            # ISO date
    re.compile(r"\b\d{2}-\d{2}\b"),                  # MM-DD
    re.compile(r"\bp(?:50|95)\b"),                   # percentile tokens
    re.compile(r"\bphase\s+(?:21[4-9]|22[0-2])\b", re.IGNORECASE),  # "phase NNN" wording (214-222)
    re.compile(r"\b(?:21[4-9]|22[0-2])(?=\s+[A-Z]+-\d\d\b)"),  # phase number immediately before a requirement/decision ID
    re.compile(r"\b[A-Z]+-\d\d\b"),                  # requirement IDs
    re.compile(r"\b(?:21[4-9]|22[0-2])-0\d\b"),      # phase/plan numbers with a plan suffix (222-01)
    re.compile(r"\b(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b"),  # hex SHAs
    re.compile(r"\bv?\d+\.\d+\.\d+\b"),              # x.y.z versions
    re.compile(r"\bv?1\.\d{2}\b"),                   # milestone versions like 1.43
]
```
D-14b names this file exactly as the copy source. Copy the whole 98-line script plus `fixtures/` verbatim into `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py`, then widen the three `21[4-9]|22[0-2]` regex fragments (lines with the `"phase NNN"`, `"NNN D-XX"`, and `"NNN-0N"` comments) to cover 224-230, e.g. `21[4-9]|22[0-9]|230`. Keep the `--self-test` invocation working (`python3 .../225-.../tools/check-citations.py --self-test`) — the doc header at the top of the file names its own usage string; update that comment's path to the 225 phase dir too.

### `.planning/phases/225-.../tools/ci-job-timing.sh` (new, D-14a)

**Analog:** `.planning/milestones/v1.43-phases/219-deps-only-build-cache/tools/collect-ci-runs.sh` (+ `summarize-ci.py` in the same dir)

**Header/flags/read-only pattern** (lines 1-33):
```bash
#!/usr/bin/env bash
# collect-ci-runs.sh — READ-ONLY collector for the Phase 214 CI baseline (BASE-01).
#
# Lists GitHub Actions runs with `gh run list` and fetches each run's jobs with a
# default-GET `gh api .../actions/runs/<id>/jobs` call (latest attempt only).
# ... It never writes to GitHub: no dispatch, re-run, cancel, push, PR/issue
# comment, and no HTTP method override.
#
# Usage (from the repo root):
#   bash .planning/phases/219-deps-only-build-cache/tools/collect-ci-runs.sh \
#     --workflow ci.yml --event pull_request [--target 20] [--min 10]
set -euo pipefail

REPO="szTheory/threadline"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE_DIR="$(dirname "$SCRIPT_DIR")"
```
`ci-job-timing.sh` (or `.py`, planner's choice) follows the same "READ-ONLY, `gh api .../actions/runs/<id>/jobs`, `set -euo pipefail`, phase-local `tools/` dir, `SCRIPT_DIR`/`PHASE_DIR` resolution" shape, but computes the D-14a proxy (`sum of ceil(job_seconds/60)` over the three `Build and test (...)` jobs) for a given run ID, and the `Run tests` step's own `started_at`/`completed_at` delta, for both "before" and "after" run IDs — so the formula can't drift between citations. It stays in the phase's own `tools/` dir (not promoted to `bin/`), per the 192/219 precedent RESEARCH cites.

## Shared Patterns

### Bash script skeleton (all new `bin/`/phase-`tools/` scripts)
**Source:** `bin/verify-deps-audit` lines 1-58 (header doc, `set -euo pipefail`, `die()`, `SCRIPT_DIR`/`ROOT`, documented env-var seam)
**Apply to:** `bin/ci-test-partitions`, `.planning/phases/225-.../tools/ci-job-timing.sh`

### Mix function-alias wiring a committed script
**Source:** `mix.exs` lines 189, 285-290 (`verify_deps_audit/1` calling `bin/verify-deps-audit` via `Mix.shell().cmd/1`, raising with the exit status on failure)
**Apply to:** the new `verify.test_partitioned` alias calling `bin/ci-test-partitions`

### Contract-test mutation-control loop
**Source:** `test/threadline/ci_topology_contract_test.exs` lines 130-198 (`{label, mutated_text}` tuples + `refute checker(mutated) == []` loop; pure checker takes committed-file text, never shells out)
**Apply to:** the new partition-topology mutation controls (D-10) appended to the same file

### Sizing/budget pure-arithmetic function + regex extraction
**Source:** `test/threadline/flake_classifier_contract_test.exs` lines 756-790 (`sizing_violations/4`, `flake_repeats/1`, `budget_seconds/1` — regex-extract committed constants from `mix.exs`/`.github/workflows/flake-detection.yml` text, then pure arithmetic)
**Apply to:** the D-11 re-derivation; keep the function signatures, only update the three cited constants and the run-ID comment

### Telemetry-handler test setup, cleaned up via `on_exit`
**Source:** `test/threadline/operator_surface/{auth,export_auth_plug,theme_auth_plug}_test.exs` current `setup` blocks (per-test unique handler id, `:telemetry.attach`, `on_exit(fn -> :telemetry.detach(handler_id) end)`)
**Apply to:** `test/support/telemetry_helpers.ex`'s `attach_telemetry!/1`, which centralizes this pattern and adds the process-identity filter (D-16)

### Determinism-helper module doc/spec style
**Source:** `test/support/async_helpers.ex` lines 1-33, 79-101 (problem-statement `@moduledoc`, per-function `@doc`+`@spec`, cleanup via `on_exit`/`try-after`)
**Apply to:** `test/support/telemetry_helpers.ex`

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/support/telemetry_helpers.ex`'s process-identity filter logic itself (the `self() == test_pid or test_pid in Process.get(:"$callers", [])` check) | utility | event-driven | No existing file in this repo filters `:telemetry` handler delivery by emitting-process identity; `deps/telemetry/src/telemetry_test.erl` is cited in RESEARCH as reference-only (its ref-tagging alone is insufficient per D-16) and is a dependency, not a repo analog. Build from the CONTEXT/RESEARCH-specified contract directly. |

## Metadata

**Analog search scope:** `bin/`, `mix.exs`, `.github/workflows/`, `test/threadline/*_contract_test.exs`, `test/support/`, `test/threadline/operator_surface/`, `test/threadline/health/`, `CONTRIBUTING.md`, `.planning/milestones/v1.43-phases/{219,222}*/tools/`
**Files scanned:** 17 read in full or targeted ranges (all confirmed git-tracked via `git ls-files`)
**Pattern extraction date:** 2026-09-30
