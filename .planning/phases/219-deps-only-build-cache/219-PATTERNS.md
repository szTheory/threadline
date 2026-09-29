# Phase 219: Deps-Only Build Cache - Pattern Map

**Mapped:** 2026-09-28
**Files analyzed:** 8 (3 modified source/docs, 5 new or copied planning artifacts)
**Analogs found:** 8 / 8 (every analog path below is git-tracked; verified with `git ls-files`)

Line numbers are as of HEAD `6e62d2f5`. They go stale on the first ci.yml edit, so executors should re-grep by the quoted text rather than trust the numbers.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` (E1–E9) | config (CI workflow) | file-I/O (cache restore/save) + batch | same file, Dialyzer PLT split restore/save, lines 181-243 | exact |
| `test/threadline/ci_workflow_parity_contract_test.exs` (replace :382-400, add `build_cache_errors/2`) | test (text contract) | transform (text → error list) | same file: `toolchain_contract_errors/1` :1297-1324, `cache_key_errors/3` :1208-1232, mutation controls :553-613 and :733-781; plus `dialyzer_topology_errors/3` in `test/threadline/ci_topology_contract_test.exs` :402-525 | exact |
| `CONTRIBUTING.md` (new `### Dependency build cache`) | docs (contract-pinned) | n/a | `CONTRIBUTING.md` `### Dialyzer PLT cache and measurement contract` :664-738 | exact |
| `.planning/phases/219-deps-only-build-cache/tools/collect-ci-runs.sh`, `summarize-ci.py`, `check-citations.py`, `fixtures/cited.md`, `fixtures/uncited.md` | utility (measurement) | batch (GitHub API → raw JSON → tables) | `.planning/phases/218-ci-economy-remove-waste/tools/*` (copied by 218-08 from 214) | exact (copy) |
| `.planning/phases/219-deps-only-build-cache/tools/remeasure-219.py` | utility (measurement) | transform (raw JSON → cited markdown rows) | `.planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py` | exact |
| `.planning/phases/219-deps-only-build-cache/219-REMEASURE.md` | docs (evidence record) | n/a | `.planning/phases/218-ci-economy-remove-waste/218-REMEASURE.md` | exact |
| `.planning/phases/219-deps-only-build-cache/raw/ci/**` | data (generated) | file-I/O | `.planning/phases/218-ci-economy-remove-waste/raw/ci/manifest.json` + `runs/<id>.json` | exact (produced by the collector, never hand-written) |

**Not modified (confirmed):** `mix.exs` (the `verify.example` alias at :307-316 needs no change; RESEARCH focus 2), `release.yml`, `flake-detection.yml`, `browser-full.yml`, `ci_action_runtime_contract_test.exs` (already allowlists `actions/cache/restore@v5` and `actions/cache/save@v5` at :17-19).

---

## Pattern Assignments

### `.github/workflows/ci.yml` (config, cache file-I/O)

**Analog:** the same file, verify-dialyzer PLT block (lines 181-243).

**Restore step: id + split action + exact key** (lines 181-187):
```yaml
      - name: Restore Dialyzer PLT
        id: dialyzer-plt-restore
        uses: actions/cache/restore@v5
        with:
          path: .dialyzer
          key: ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-dialyzer-plt-${{ hashFiles('mix.lock') }}-${{ hashFiles('mix.exs') }}
          restore-keys: ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-dialyzer-plt-
```
Copy the shape: `id:`, `actions/cache/restore@v5`, and a runner-led key with the `steps.beam.outputs` segments. **Diverge on one line: the `_build` restore has NO `restore-keys:` line** (D-01, CACHE-01). The PLT's restore-keys are correct only because PLTs update incrementally (ci.yml :96-97 says so).

**Miss-only work step** (lines 196-197):
```yaml
      - name: Build and measure Dialyzer PLT on cache miss
        if: steps.dialyzer-plt-restore.outputs.cache-hit != 'true'
```
This becomes `Compile dependencies on build cache miss` with `if: steps.build-restore.outputs.cache-hit != 'true'` and `run: mix deps.compile`. The example variant uses `--skip-local-deps` and `working-directory: examples/threadline_phoenix`.

**Save step: primary-key hand-off + miss guard** (lines 232-239):
```yaml
      # Save a successfully built/updated PLT before analysis so an analyzer
      # warning cannot discard the expensive, valid cache artifact.
      - name: Save Dialyzer PLT
        if: steps.dialyzer-plt-restore.outputs.cache-hit != 'true'
        uses: actions/cache/save@v5
        with:
          path: .dialyzer
          key: ${{ steps.dialyzer-plt-restore.outputs.cache-primary-key }}
```
Copy this verbatim in shape. Never retype the key, never use `always()`, and never add `continue-on-error` (D-15). The save `path:` must be byte-equal to the restore `path:`.

**Hit report / log marker** (lines 227 and 241-243):
```yaml
          echo "THREADLINE_DIALYZER_PLT_CACHE=miss"
...
      - name: Report exact PLT cache hit
        if: steps.dialyzer-plt-restore.outputs.cache-hit == 'true'
        run: echo "THREADLINE_DIALYZER_PLT_CACHE=hit"
```
RESEARCH recommends (discretion, D-18) putting one always-run echo in the unconditional rm step instead of a separate hit-only step, which would break D-07 contiguity:
`echo "THREADLINE_BUILD_CACHE=${{ steps.build-restore.outputs.cache-hit == 'true' && 'hit' || 'miss' }} key=${{ steps.build-restore.outputs.cache-primary-key }}"`
**Do not reuse the step name `Report exact PLT cache hit`.** `dialyzer_topology_errors` looks it up with `workflow_step(yaml, "Report exact PLT cache hit")` and uses the first match.

**Existing deps cache step: keep it as is and insert around it** (verify-test :382-393):
```yaml
      - name: Cache deps
        uses: actions/cache@v5
        with:
          path: deps
          key: ${{ matrix.runner }}-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-${{ hashFiles('mix.lock') }}
          restore-keys: ${{ matrix.runner }}-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-

      - name: Install dependencies
        run: mix deps.get

      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors
```
The target sequence is: `_build` restore goes BEFORE `Cache deps`; the deps.compile-on-miss, rm and save steps go between `Install dependencies` and `Compile (warnings as errors)`. Keep the `run: mix compile --warnings-as-errors` text byte-identical, because the topology xref-order test pins it (RESEARCH "Existing tests" table).

**Matrix lane guard precedent** (verify-test :401-403, :419-421):
```yaml
      - name: Verify Threadline Phoenix example
        if: matrix.lane == 'current'
        run: mix verify.example
```
The example steps in verify-test carry `if: matrix.lane == 'current'`. The conditional ones become `if: matrix.lane == 'current' && steps.example-build-restore.outputs.cache-hit != 'true'` (Pitfall 2).

**Job-level env block to extend** (verify-example-browser :472-474, verify-capture :582-584):
```yaml
    env:
      DB_HOST: localhost
      DB_PORT: 5432
```
Add `MIX_ENV: test` here (E5/E7, D-09). verify-test (:343-345) and verify-pgbouncer-topology (:695-696) already have it.

**Combined step to split** (verify-pgbouncer-topology :747-755):
```yaml
      - name: Bootstrap test DB (direct Postgres, bypass pooler)
        env:
          DB_HOST: localhost
          DB_PORT: "5432"
          THREADLINE_TOPOLOGY_BOOTSTRAP: "1"
        run: |
          mix deps.get
          mix compile --warnings-as-errors
          mix run priv/ci/topology_bootstrap.exs
```
Split this into `Install dependencies` → `Compile dependencies on build cache miss` → rm → `Compile (warnings as errors)`. Then move `Wait for Postgres and PgBouncer` (:738-745) after the compile. Bootstrap keeps its name, its `env:` block and `run: mix run priv/ci/topology_bootstrap.exs`. There is no save step here (restore-only, D-11).

**Step to delete** (verify-compile-no-optional :302-307): the whole `Cache deps` step. `Install dependencies` and `mix verify.compile_no_optional` stay (E2, D-13).

**Comment to rewrite** (E1, :66-97). Keep the first line's exact prefix `      # CACHE KEY CONTRACT` (6 spaces), because the OS-family mutation control needles on it (parity test :757-762; Pitfall 1). Delete lines 81-88 ("There is currently NO `_build` cache …") and rewrite them in the present tense. Never spell the OS-family expression.

---

### `test/threadline/ci_workflow_parity_contract_test.exs` (test, text transform)

**Analog A: this file's own helpers.** Reuse them; do not duplicate them.

Workflow enumeration (:125-128):
```elixir
  # Every workflow file, keyed by its repo-relative path.
  defp all_workflows do
    Map.new(workflow_files(), &{Path.relative_to(&1, @repo_root), File.read!(&1)})
  end
```

Job and step splitting (:845-882):
```elixir
  defp workflow_jobs(yaml) do
    case String.split(yaml, ~r/^jobs:\n/m, parts: 2) do
      [_, body] ->
        ~r/^  ([a-z][a-z0-9-]+):\n[\s\S]*?(?=^  [a-z][a-z0-9-]+:\n|\z)/m
        |> Regex.scan(body)
        |> Enum.map(fn [block, job_id] -> {job_id, block} end)
      _ -> []
    end
  end

  defp workflow_job(yaml, id) do ... end          # :857

  # Step texts of a job block, split at every 6-space-indented list item. The
  # leading chunk (job header up to the first step) is dropped.
  defp job_steps(block) do
    case Regex.split(~r/^(?=      - )/m, block) do
      [_header | steps] -> steps
      [] -> []
    end
  end

  defp strip_comment_lines(block) do
    block |> String.split("\n") |> Enum.reject(&String.match?(&1, ~r/^\s*#/)) |> Enum.join("\n")
  end
```

Value extraction (:1260-1265). It returns `"|"` for a block scalar, so a `path: |` block needs its own continuation-line reader for the D-20 "restore and save paths match" rule:
```elixir
  defp yaml_value(step, key) do
    case Regex.run(~r/^\s*#{Regex.escape(key)}:[ \t]*(.*?)[ \t]*$/m, step) do
      [_, value] -> value
      nil -> nil
    end
  end
```

**Top-level error-function shape: fail closed on vacuous input, then flat_map per job** (:1297-1324):
```elixir
  defp toolchain_contract_errors(yaml_by_path) do
    Enum.flat_map(yaml_by_path, fn {path, yaml} ->
      jobs = workflow_jobs(yaml)

      cond do
        jobs == [] ->
          ["#{path} has no parseable jobs — the toolchain contract would pass vacuously"]
        Enum.any?(jobs, fn {_id, block} ->
          String.contains?(strip_comment_lines(block), "uses: erlef/setup-beam@")
        end) ->
          Enum.flat_map(jobs, &job_toolchain_errors(path, &1))
        true -> []
      end
    end)
  end
```
`build_cache_errors(yaml_by_path, contributing)` follows this: iterate `{path, yaml}`, then `{job_id, block}`, and build messages as `"#{path} #{job_id} …"`.

**`{bool, message}` rule list → errors idiom** (:1241-1258, `key_value_errors`):
```elixir
  defp key_value_errors(where, field, value) do
    [
      {String.contains?(value, "steps.beam.outputs.otp-version"),
       "#{where} #{field} must carry the resolved OTP (steps.beam.outputs.otp-version)"},
      ...
      {String.starts_with?(value, "ubuntu-24.04-") or
         String.starts_with?(value, "${{ matrix.runner }}-"),
       "#{where} #{field} must lead with the literal runner label"},
      ...
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end
```
Use the same shape for the `@build_key_segments` check: one tuple per segment, with a message naming the file, job, step, rule, reason and fix (D-20).

**Existing save exemption to tighten** (:1219-1224). It accepts ANY step id today:
```elixir
        String.contains?(step, "uses: actions/cache/save@") and
            Regex.match?(
              ~r/^\s*key: \$\{\{ steps\.[a-z0-9_-]+\.outputs\.cache-primary-key \}\}\s*$/m,
              step
            ) ->
          []
```
`build_cache_errors` adds the stricter rule for `_build` saves: the id must equal the matching `_build` restore's `id:`. Leave `cache_key_errors` alone. It still covers the deps/PLT caches, and the new restores already satisfy it (`${{ matrix.runner }}-` or `ubuntu-24.04-` lead, both beam outputs).

**Allowlist-with-reason attribute precedent** (:410-416), the model for `@build_cache_jobs` and the not-cached reasons:
```elixir
  # Cache paths that do not depend on the BEAM are exempt only by being named
  # here with a reason. Any other cache path fails closed unless its key carries
  # both resolved outputs.
  @beam_independent_cache_paths %{
    "~/.cache/ms-playwright" =>
      "Playwright browser binaries are keyed by the e2e npm lockfile and do not depend on the BEAM"
  }
```
And the reason-length test that goes with it (:783-788):
```elixir
    test "the Playwright exemption is the only BEAM-independent cache path, with a reason" do
      assert Map.keys(@beam_independent_cache_paths) == ["~/.cache/ms-playwright"]
      for {_path, reason} <- @beam_independent_cache_paths do
        assert is_binary(reason) and String.length(reason) > 20
      end
```
Suggested shape: `@build_cache_jobs %{{".github/workflows/ci.yml", "verify-test"} => {reason, :save}, {…, "verify-pgbouncer-topology"} => {reason, :restore_only}, …}`. Add a "every entry used" rule.

**Needle-assembly idiom** (:418-422). Build forbidden needles by concatenation, so the test file never contains them literally:
```elixir
  # Assembled so this file's own text never contains the needles it forbids.
  @os_family_context "runner" <> ".os"
```
Apply this to any forbidden literal the new contract bans in the ci.yml comment, e.g. the stale "There is currently NO" sentence (D-21 control) and the `no-optional` profile token, if they would otherwise appear in the test text.

**Mutation-control idiom, single file** (:553-565):
```elixir
      credo_job = workflow_job(live, "verify-credo")

      controls = [
        {"verify-credo id beam removed",
         String.replace(live, credo_job, String.replace(credo_job, "        id: beam\n", ""))}
      ]

      for {control, mutated} <- controls do
        refute mutated == live, "#{control} control did not change the input"
        refute toolchain_contract_errors(%{path => mutated}) == [],
               "#{control} mutation must make the toolchain pin contract fail"
      end
```
The job-scoped replace (`String.replace(live, job, String.replace(job, a, b))`) is the way to mutate one job only, e.g. removing `MIX_ENV` from verify-example-browser, or cloning a cache step into verify-compile-no-optional.

**Mutation-control idiom, multi-file with a fragment assert (the D-21 target shape)** (:742-780):
```elixir
      mutate = fn path, from, to ->
        Map.update!(live, path, &String.replace(&1, from, to, global: false))
      end

      controls = [
        {ci, "cache key built on the OS-family context",
         mutate.(ci, "key: ${{ matrix.runner }}-", "key: ${{ " <> @os_family_context <> " }}-${{ matrix.runner }}-")},
        ...
      ]

      for {path, control, mutated} <- controls do
        refute mutated == live, "#{control} control did not change the input"
        errors = workflows_os_family_context_errors(mutated)
        assert Enum.any?(errors, &String.starts_with?(&1, path <> ":")),
               "#{control} mutation must make the OS-family context check fail for #{path}, " <>
                 "got #{inspect(errors)}"
      end
```
D-21 requires `assert Enum.any?(errors, &String.contains?(&1, fragment))` per control, a `{path, label, mutated, fragment}` tuple. Use `Map.update!` on `all_workflows()` for the release.yml (publish-hex / smoke-published) and flake-detection.yml clones.

**Synthetic workflow fixture precedent (for Plan 01's TDD fixtures)** (:581-586, 603-604):
```elixir
      unknown_cache =
        "jobs:\n  some-job:\n    steps:\n      - uses: actions/checkout@v5\n" <>
          "      - uses: erlef/setup-beam@v1\n        id: beam\n        with:\n" <>
          "          version-file: .tool-versions\n          version-type: strict\n" <>
          "      - uses: actions/cache@v4\n        with:\n          path: ~/.cache/something\n" <>
          "          key: ubuntu-24.04-${{ hashFiles('x.lock') }}\n"
      ...
        {"a new workflow caching an unknown path on a lockfile-only key",
         Map.put(live, ".github/workflows/new.yml", unknown_cache)}
```
Plan 01 builds a minimal correct cached job the same way (a `~S"""` heredoc is fine), proves `build_cache_errors(%{"x.yml" => good}, doc) == []`, and then runs each D-21 mutation on it. The live `describe "dependency cache contract"` block at :382-400 stays untouched until Plan 02.

**Block being replaced in Plan 02** (:382-400):
```elixir
  describe "dependency cache contract" do
    test "ci.yml caches deps + e2e lockfile and never caches _build" do
      ...
      assert String.contains?(yaml, "cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json"), ...
      refute Regex.match?(~r/^\s*path:\s*_build\s*$/m, yaml),
             "ci.yml must NOT cache _build (compile artifacts are not shared across matrix lanes)"
```
The first three asserts may be kept. The `refute … _build` and its message must be deleted (Pitfall 5; the verifier greps that `must NOT cache _build` is gone).

**Test-file boilerplate** (:1-9): `use ExUnit.Case, async: true`, `@repo_root File.cwd!()`, `read_rel!/1`. CONTRIBUTING is read with `read_rel!(["CONTRIBUTING.md"])` (:91, :375).

**Analog B: doc-pinned error function + order check,** `test/threadline/ci_topology_contract_test.exs`.

Signature and ordered positions (:402-417):
```elixir
  defp dialyzer_topology_errors(mix_exs, yaml, contributing) do
    job = workflow_job(yaml, "verify-dialyzer")
    no_optional_job = workflow_job(yaml, "verify-compile-no-optional")
    ...
    order = [
      position(job, "mix deps.get"),
      position(job, "mix compile --warnings-as-errors"),
      ...
      position(job, "- name: Save Dialyzer PLT"),
      ...
    ]
```
Doc-pinning rules inside the same `{bool, msg}` list (:486-498, :522-524):
```elixir
      {String.contains?(contributing, "- `verify-dialyzer`") and
         String.contains?(contributing, "| `verify-dialyzer` | `mix verify.dialyzer`"),
       "CONTRIBUTING must document the aggregate edge and stable job key"},
      {Enum.all?(["THREADLINE_DIALYZER_PLT_CACHE", ...], &String.contains?(contributing, &1)),
       "CONTRIBUTING must document the stable measurement field contract"},
      ...
    ]
    |> Kernel.++(live_slice_checks(mix_exs, yaml, job))
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
```
Order helpers (:629-638):
```elixir
  defp position(source, needle) do
    case :binary.match(source, needle) do
      {position, _length} -> position
      :nomatch -> nil
    end
  end

  defp ordered_positions?(positions) do
    Enum.all?(positions, &is_integer/1) and positions == Enum.sort(positions)
  end
```
**Diverge for D-07.** Byte-position ordering cannot prove *contiguity* or print the observed sequence. D-20 asks for step-index order: classify `job_steps(block)` into atoms (RESEARCH "Classifier sketch": `:restore_build`, `:deps_restore`, `:deps_get`, `:deps_compile`, `:rm_own`, `:save_build`, …). Compare the index sequence, and on failure emit `"… observed #{inspect(classes)}"`. Carry `position`/`ordered_positions?` over only if a byte-order check is useful as a secondary guard. Do not import them across test modules: each test file keeps its own private helpers (both files define `strip_comment_lines` privately).

Mutation plus a CONTRIBUTING mutation (:130-185, :220-224):
```elixir
    for {control, mutated_yaml} <- mutation_controls do
      refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [], ...
    end
    ...
    evidence_without_cold_run = String.replace(contributing, "34642915672", "unlinked-cold-run")
    refute dialyzer_topology_errors(mix_exs, yaml, evidence_without_cold_run) == [], ...
```
Mirror this for docs parity: mutate `contributing` (drop the `gh cache delete` line or the rm literal) and assert the specific fragment.

---

### `CONTRIBUTING.md` (docs, `### Dependency build cache`)

**Analog:** `### Dialyzer PLT cache and measurement contract` (:664-738). The new section goes adjacent to it (before or after, under `## CI parity and \`act\``), ahead of the `Hex publish` pointer paragraph at :740.

**Structure to copy:**
1. Opening paragraph: which jobs, and on what toolchain (:666-671).
2. Key paragraph naming every segment in prose (:673-679):
   > The PLT cache lives at `.dialyzer` and is keyed by the runner image, exact OTP and Elixir versions, and both `mix.lock` and `mix.exs` hashes. A restore prefix may reuse only a PLT from the same runner/OTP/Elixir boundary. On a miss, CI … saves the successfully built PLT … On an exact-key hit, CI skips PLT construction …
3. "The stable log fields are:" bullet list (:694-700):
   ```
   - `THREADLINE_DIALYZER_PLT_CACHE`: exactly `miss` or `hit`.
   ```
   → `- \`THREADLINE_BUILD_CACHE\`: exactly \`hit\` or \`miss\`, followed by \` key=<primary key>\`.` and the same for `THREADLINE_EXAMPLE_BUILD_CACHE`.
4. Evidence subsection with run IDs (:708-726, `#### Authenticated cold/hit evidence`). **Do not add it in Plan 02.** Evidence lives in `219-REMEASURE.md`, and a later CONTRIBUTING pin of run IDs would be a new contract. Leave it out unless the planner deliberately adds it in Plan 03.

**Additional D-19 content not in the analog:** the pinned job list (set-equal to the contract allowlist); why there are no restore-keys (the CargoSense/setup-elixir-project#13 footgun); the literal `rm -rf "_build/${MIX_ENV:?}/lib/threadline"` (Pitfall 8 maps it to SC2's `$MIX_ENV` form); the cache-free jobs with reasons (D-12, D-13); the benign "Unable to reserve cache" save-race warning; and the poisoned-cache runbook (`gh cache list --key … --ref …` → `gh cache delete <key>` with `actions: write` → bump `build-vN` in a PR, noting that a main-scope entry reaches every PR).

**Neighbouring style** (:651-657, the removal-justification section): every exclusion states its reason and names the test that pins it. That is the same discipline D-12 asks for.

---

### `.planning/phases/219-deps-only-build-cache/tools/` (copied tools + fixtures)

**Analog / precedent:** `218-08-PLAN.md` Task 1 (:115-123), which copied 214's tools into 218:
> 1. `cp` the three tools and the two fixtures … keeping the executable bit on `collect-ci-runs.sh`.
> 2. Edit only these lines: in `summarize-ci.py`, the `SELF` string …; in all three tools, usage and docstring lines that name the old path now name the new path; in `check-citations.py`, the phase-number exemption regex …
> 3. Prove it: `diff` each copy against its original. Record the complete diff output in the SUMMARY; only the lines above may differ. Run `… check-citations.py --self-test`.

Source files (tracked): `.planning/phases/218-ci-economy-remove-waste/tools/{collect-ci-runs.sh,summarize-ci.py,check-citations.py,fixtures/cited.md,fixtures/uncited.md}`. **Do not copy `__pycache__/` or `remeasure-218.py`.**

Exact lines to edit:
- `summarize-ci.py:44`: `SELF = "python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py"` → the 219 path.
- `collect-ci-runs.sh:11` (usage comment) → the 219 path. Logic untouched: `PHASE_DIR="$(dirname "$SCRIPT_DIR")"` / `RAW_DIR="$PHASE_DIR/raw/ci"` (:34-36) already self-locate.
- `check-citations.py:5-6` (usage) → the 219 path; `:31` `re.compile(r"\b21[4-8](?:-0\d)?\b")` → `21[4-9]`, plus its `:12` docstring "(214-218)" → "(214-219)".

---

### `.planning/phases/219-deps-only-build-cache/tools/remeasure-219.py` (utility, transform)

**Analog:** `.planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py` (269 lines, read in full).

**Path constants + cross-phase read-only raw** (:45-58):
```python
TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
PHASES_DIR = os.path.dirname(PHASE_DIR)
RAW_218 = os.path.join(PHASE_DIR, "raw", "ci")
RAW_214 = os.path.join(PHASES_DIR, "214-baseline-measurement", "raw", "ci")

SELF = "python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py"

POST_AFTER = "2026-09-27T23:34:00Z"
POST_KEYS = ("ci.yml:pull_request:any:since-2026-09-27",
             "ci.yml:workflow_dispatch:any:since-2026-09-27")
BASE_KEY = "ci.yml:pull_request"
```
→ `RAW_219` (own), `RAW_218` (read-only, `218-ci-economy-remove-waste/raw/ci`, with the same `POST_AFTER` filter for the `post218` set), `RAW_214` (base). Never copy JSON between phases (RESEARCH Open Question 2).

**Import the copied summarizer unchanged** (:67-69):
```python
_spec = importlib.util.spec_from_file_location("summarize_ci", os.path.join(TOOLS_DIR, "summarize-ci.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)
```
Reused arithmetic: `S.ran`, `S.job_seconds`, `S.sort_samples`, `S.pick`, `S.billed_minutes`, `S.fmt_min`, `S.run_wall`, `S.ts`, `S.seconds`, `S.workflow_jobs`, `S.job_id_for` (summarize-ci.py :78-249).

**Named sample sets** (:89-102, `runs_for(name)`). Extend it to `base`, `post218`, `warm`, `cold` (D-23). `warm`/`cold` partition the 219 runs by label.

**Hit/miss labelling from committed step conclusions** (:198-221):
```python
def step_secs(job, name):
    for st in job.get("steps", []):
        if st["name"] == name and st.get("started_at") and st.get("completed_at"):
            return st["conclusion"], S.seconds(st["started_at"], st["completed_at"])
    return None, None

def sub_dialyzer(args):
    ...
            rep, _ = step_secs(j, "Report exact PLT cache hit")
            bconc, bsec = step_secs(j, "Build and measure Dialyzer PLT on cache miss")
            label = "hit" if rep == "success" else "miss"
```
→ the label comes from `step_secs(j, "Compile dependencies on build cache miss")`: `skipped` = hit, `success` = miss (RESEARCH Pattern 1). Do the same with the example step name for the example cache. Label per job, because the root and example caches can differ within one run.

**Cited-row output** (:111-119, :235-250). Every printed row ends with `cmd(sub, sset)` and cites `(run N)` in `pcell`. That keeps the REMEASURE rows citation-clean by construction. The `STEPS` tuple (:224-232) becomes the restore/deps.compile/rm/save/compile steps per cached job (D-24 restore and save cost).

**CLI table** (:253-265): the argparse subparser loop with `--set` choices. Copy it, and add `cache` (per-job hit/miss) and `cache-steps` subcommands.

---

### `.planning/phases/219-deps-only-build-cache/219-REMEASURE.md` (docs, evidence)

**Analog:** `.planning/phases/218-ci-economy-remove-waste/218-REMEASURE.md`.

**Section skeleton** (218 headings): `## 0. Method` / `## 1. Samples` / `## 2. Runner-minutes per ci.yml run` / `## 3. Wall clock and critical path` / `## 4. Per-job attribution` (`### 4a. Per-job p50, base vs post`, `### 4b. … hit / miss labels`) / … / `## 9. Summary of deltas`. Add the D-24 extras: restore/save step cost, a correctness quote, and `gh cache list` sizes.

**Method bullets pattern** (218 :7-15). Name the branch/PR, the first run ID, the copied tools ("differ from the originals only in their self-path strings and in the checker's phase-number exemption"), the exact collector command lines, and the citation-checker command.

**Samples table** (218 :23-32):
```
| Run | Event | Head | Conclusion | Jobs that ran | Jobs not success | Regenerate |
|---|---|---|---|---|---|---|
| run 36359132030 | pull_request | 0d000785 | failure | 15 jobs | CI required, Repo hygiene (no machine-local paths) | `python3 …/remeasure-218.py samples` |
```
→ add hit/miss columns for the root and example caches, plus the cache scope (ref).

**Hit/miss label section** (218 §4b :112-134). Explain the label source, then give a per-run table, then a `hit samples` / `miss samples` p50/p95 table with a `Regenerate` column.

**Summary table** (218 :263-276):
```
| Figure | BASE-01 | Post-change | Delta | Status | Regenerate |
```
→ add a `post218` column (D-24: against 214 AND against 218). `[inference]` rows cite their input runs (218 :278).

**Citation gate:** `python3 .planning/phases/219-deps-only-build-cache/tools/check-citations.py .planning/phases/219-deps-only-build-cache/219-REMEASURE.md` must exit 0. **Hygiene:** no pasted runner home paths or username; use `<home>/…` placeholders (Pitfall 10).

---

## Shared Patterns

### Exact-key split cache (restore id → miss-guarded work → primary-key save)
**Source:** `.github/workflows/ci.yml` :181-243 (verify-dialyzer PLT)
**Apply to:** all 5 cached job-lanes (verify-test current + min, verify-example-browser, verify-capture; pgbouncer restore-only)
```yaml
        id: <x>-restore
        uses: actions/cache/restore@v5
...
        if: steps.<x>-restore.outputs.cache-hit != 'true'
        uses: actions/cache/save@v5
        with:
          path: <same path as restore>
          key: ${{ steps.<x>-restore.outputs.cache-primary-key }}
```
Difference from the source: no `restore-keys:` on any `_build` restore.

### Key segment contract
**Source:** `.github/workflows/ci.yml` :66-79 (CACHE KEY CONTRACT) + parity `key_value_errors` :1241-1258
**Apply to:** every new restore key. Lead with `ubuntu-24.04-` (literal) or `${{ matrix.runner }}-` (verify-test only); `steps.beam.outputs.otp-version` and `elixir-version`; never the OS-family context; never a literal OTP.

### Text-contract error function
**Source:** `ci_workflow_parity_contract_test.exs` `toolchain_contract_errors/1` :1297-1324 + `key_value_errors/3` :1241-1258; `ci_topology_contract_test.exs` `dialyzer_topology_errors/3` :402-525
**Apply to:** `build_cache_errors/2`. Pure, takes `%{path => text}` plus the CONTRIBUTING text, returns `[String.t()]`, uses `{bool, msg}` lists with `Enum.reject(&elem(&1, 0)) |> Enum.map(&elem(&1, 1))`, and fails closed on vacuous input.

### Mutation controls
**Source:** parity :553-565 (single file, job-scoped replace), :742-780 (multi-file `Map.update!` + specific assert), :581-604 (synthetic workflow text); topology :130-224 (YAML + CONTRIBUTING mutations)
**Apply to:** all D-21 controls. Always `refute mutated == live, "#{control} control did not change the input"` first, then assert the specific error fragment.

### Doc–YAML pinning
**Source:** topology :486-520 (CONTRIBUTING needles inside the same error function)
**Apply to:** the ci.yml comment and the CONTRIBUTING `### Dependency build cache` section. Pin the job-list set equality, the rm literal, "no `restore-keys`", `gh cache delete`, `build-v`, and the absence of the "currently NO" sentence.

### Measurement citation discipline
**Source:** 218 tools (`remeasure-218.py` `pcell`/`cmd`, `check-citations.py`) + `218-REMEASURE.md`
**Apply to:** `remeasure-219.py` and `219-REMEASURE.md`. Every digit-bearing line cites `run <8+ digits>` or a backticked `python3`/`gh`/`mix` command.

## Collision Watchlist (existing pins in edited text)

| Pin | Location | Constraint on this phase |
|---|---|---|
| `"      # CACHE KEY CONTRACT"` needle | parity :757-762 | keep that exact 6-space prefix line in the E1 rewrite |
| `"key: ${{ matrix.runner }}-"` needle (first occurrence) | parity :754 | the new verify-test build restore may become the first match, which is still a valid mutation |
| exactly 11 setup-beam steps | parity :545 | add no setup-beam steps |
| `run: mix compile --warnings-as-errors` order before xref and test | topology ~:251-266 | keep the text byte-identical; `run: mix deps.compile` does not contain it |
| `workflow_step(yaml, "Report exact PLT cache hit")` | topology :200, :405 | do not reuse that step name |
| `no_optional_job` must not contain `dialyzer` | topology :482 | unaffected by E2 |
| step names `Compile (warnings as errors)`, `Install dependencies`, `Install root dependencies`, `Run example Playwright suite`, `Regenerate Tier A capture`, `Verify Threadline Phoenix example`, `Bootstrap test DB (direct Postgres, bypass pooler)`, `Topology tests + verify_coverage through PgBouncer` | various contracts | keep byte-identical |
| `--project` flags in `run:` bodies; flag-bearing steps may not carry `if:` | `bin/browser-full-projects` :252-277 | new steps carry no `--project` |

## No Analog Found

None. Every file has a strong in-repo analog. The only new logic without precedent is the **step-index contiguity classifier** (D-07/D-20). The nearest precedent is `ordered_positions?` (byte order). For the atom-class design, use the RESEARCH "Classifier sketch" (219-RESEARCH.md, Code Examples).

## Metadata

**Analog search scope:** `.github/workflows/`, `test/threadline/ci_*_contract_test.exs`, `CONTRIBUTING.md`, `mix.exs`, `.planning/phases/218-ci-economy-remove-waste/{tools,218-REMEASURE.md,218-08-PLAN.md}`
**Files scanned:** 10
**Tracked-source gate:** all named analog paths confirmed via `git ls-files` (ci.yml, both contract tests, CONTRIBUTING.md, 218 tools + fixtures + REMEASURE + raw). No gitignored mirrors referenced. The 218 `tools/__pycache__/` is untracked; exclude it from the copy.
**Pattern extraction date:** 2026-09-28
