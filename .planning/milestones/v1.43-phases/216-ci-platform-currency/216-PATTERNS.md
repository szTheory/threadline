# Phase 216: CI Platform Currency - Pattern Map

**Mapped:** 2026-09-26
**Files analyzed:** 11 (1 new test, 1 newly-tracked file, 9 modified)
**Analogs found:** 11 / 11. Every file is either a self-analog (an edit in place with an existing idiom) or has a strong in-repo analog.

All analog paths below are git-tracked source (checked with `git ls-files`). `.tool-versions` is currently untracked but **not** gitignored (`git check-ignore -v .tool-versions` prints nothing), so `git add .tool-versions` works as-is and needs no `.gitignore` edit.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.tool-versions` (track, content unchanged) | config | file-I/O (read by asdf + setup-beam) | n/a (becomes the SSOT) | n/a |
| `.github/workflows/ci.yml` | config (CI workflow) | batch / request-response | self (14 setup-beam steps, 14 BEAM cache keys) | exact (self) |
| `.github/workflows/browser-full.yml` | config (CI workflow) | batch | `ci.yml` `verify-example-browser` job (lines 417-527) | exact |
| `.github/workflows/flake-detection.yml` | config (CI workflow) | batch | `ci.yml` `verify-format` job (lines 53-105) | exact |
| `.github/workflows/deps-health.yml` | config (CI workflow) | batch | `ci.yml` `verify-deps-audit` job (lines 911-948, no cache) | exact |
| `.github/workflows/release.yml` | config (CI workflow) | event-driven (ref-switching jobs) | self, `sync-release-pr-pins` (lines 110-170) | role-match (new toolchain-first checkout, no in-repo sparse-checkout precedent) |
| `bin/verify-bump-rehearsal` | utility (shell script) | file-I/O | self, lines 234-243 (delete block) | exact (self) |
| `CONTRIBUTING.md` | doc (doc-contract-tested) | n/a | self, lines 22-42, 563, 579-583, 753-756 | exact (self) |
| `test/threadline/ci_topology_contract_test.exs` | test (static contract) | transform (YAML text → error list) | self, `dialyzer_topology_errors/3` (lines 114-188, 365-482) | exact (self) |
| `test/threadline/ci_workflow_parity_contract_test.exs` | test (static contract) | transform | self (lines 112-123 `workflow_files/0`, 251-270 cache describe) + `ci_topology_contract_test.exs` classifier idiom | exact |
| `test/threadline/ci_action_runtime_contract_test.exs` (NEW) | test (static contract) | transform | `ci_topology_contract_test.exs` (`workflow_paths/0` + `dialyzer_topology_errors/3` + mutation controls) and `deps_audit_contract_test.exs` (`forbidden_hex_surface/1` + synthetic positive/benign test) | exact |

## Pattern Assignments

### `test/threadline/ci_action_runtime_contract_test.exs` (NEW, test, transform)

**Primary analog:** `test/threadline/ci_topology_contract_test.exs`
**Secondary analog:** `test/threadline/deps_audit_contract_test.exs` (pure scanner + synthetic positive/benign fixture test)

**Module header / imports** (`ci_topology_contract_test.exs` lines 1-12). No aliases, no shared helpers across test modules. Each contract file carries its own private helpers (`deps_audit_contract_test.exs` lines 15-16 state this as convention: "Local private helpers only — deliberately does not import from other test modules").
```elixir
defmodule Threadline.CiTopologyContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end
```
New module name suggestion: `Threadline.CiActionRuntimeContractTest` (matches the `Ci...` casing of the topology file; note parity uses `CIWorkflowParity...`, so either casing has precedent).

**Workflow glob, both extensions, non-vacuous** (`ci_topology_contract_test.exs` lines 252-260 + 271-275):
```elixir
  # Globs BOTH extensions on purpose. GitHub Actions honours .yaml as well as
  # .yml, so a guard that only globbed .yml could be defeated by a rename.
  defp workflow_paths do
    @repo_root
    |> Path.join(".github/workflows/*.{yml,yaml}")
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, @repo_root))
    |> Enum.sort()
  end
...
    refute paths == [],
           "found no workflow files to scan — the glob is broken, and a broken glob " <>
             "would launder a false pass for this guard"
```

**Pure classifier returning an error list** (`ci_topology_contract_test.exs` lines 365, 380-382, 479-482). The shape is a list of `{boolean, message}` tuples, then reject the true ones and keep the messages:
```elixir
  defp dialyzer_topology_errors(mix_exs, yaml, contributing) do
    ...
    [
      {mix_exs =~ ~s("verify.dialyzer": ["dialyzer --no-check"]),
       "verify.dialyzer must be the stable local no-check command"},
      ...
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end
```
For `node20_errors(yaml_by_path)`, the natural shape is `Enum.flat_map` over `{path, yaml}` and scanned `uses:` refs, emitting one message per ref that is not in the allowlist. Each message names path + ref + the remedy ("fetch its action.yml, confirm runs.using is node24 or composite/docker, then add it here").

**Live assertion + mutation controls** (`ci_topology_contract_test.exs` lines 119-156):
```elixir
    assert dialyzer_topology_errors(mix_exs, yaml, contributing) == []

    mutation_controls = [
      {"PLT timing command",
       String.replace(yaml, "/usr/bin/time -v -o \"$time_file\" mix dialyzer --plt", "mix dialyzer --plt")},
      ...
    ]

    for {control, mutated_yaml} <- mutation_controls do
      refute dialyzer_topology_errors(mix_exs, mutated_yaml, contributing) == [],
             "#{control} mutation must make the Dialyzer topology contract fail"
    end
```
For the runtime test, feed synthetic snippets instead of `String.replace` on live YAML, so the controls stay valid after the bumps land. RESEARCH Pattern 4 lists them: `uses: actions/cache@v4`, `uses: googleapis/release-please-action@v4`, `uses: some-org/new-action@v1`, `  - uses: actions/upload-artifact@v4`.

**Synthetic positive/benign fixture test** (`deps_audit_contract_test.exs` lines 93-131). This is the idiom for proving the scanner regex itself is non-vacuous:
```elixir
  defp forbidden_hex_surface(text) do
    ~r/HEX_IGNORE_ADVISORIES|HEX_IGNORE_RETIREMENTS|HEX_HOME|MIX_HOME|hex\.config\s+ignore_/
    |> Regex.scan(text)
    |> List.flatten()
    |> Enum.uniq()
  end

  test "forbidden_hex_surface/1 is non-vacuous: finds every token in a synthetic positive, nothing in a benign snippet" do
    positive = """
    jobs:
      verify-deps-audit:
        ...
    """
    found = forbidden_hex_surface(positive)
    ...
    assert forbidden_hex_surface(benign) == []
  end
```

**Comment-line stripping** (`ci_topology_contract_test.exs` lines 531-536, same helper duplicated in `deps_audit_contract_test.exs` lines 61-66). Use it so a commented-out `uses:` never counts:
```elixir
  defp strip_comment_lines(block) do
    block
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
    |> Enum.join("\n")
  end
```

**Two-direction / stale-entry idiom** (`ci_topology_contract_test.exs` lines 558-581: `missing_from_docs = actual -- documented`, `undocumented_extra = documented -- actual`, plus the `length(actual) >= 10` non-vacuity floor at 562). Mirror it for "every allowlist entry is used somewhere" (stale allowlist entries fail) and "live scan found > 0 refs".

**Existing SHA-pin assertion to stay consistent with** (`ci_topology_contract_test.exs` lines 101-112): alls-green is asserted as `~r|uses: re-actors/alls-green@[0-9a-f]{40}$|m`. The allowlist entry `{"re-actors/alls-green", "b5b5b37504aa4183270bd3d855c52a67f212be35"}` must match the exact SHA in ci.yml.

**Live `uses:` inventory to allowlist (verified by grep today):** `actions/checkout@v5`, `erlef/setup-beam@v1`, `actions/setup-node@v5`, `actions/github-script@v8` (release.yml:312), `re-actors/alls-green@<sha>`. After the bumps: `actions/cache@v5`, `actions/cache/restore@v5`, `actions/cache/save@v5`, `actions/upload-artifact@v7`, `googleapis/release-please-action@v5`.

---

### `test/threadline/ci_topology_contract_test.exs` (MODIFY, test)

**Analog:** self. Edit in place. Exact lines that hard-code old literals (RESEARCH Pitfall 4, confirmed by Read):

| Line | Current | Change to |
|---|---|---|
| 139-144 | mutation control `"same-toolchain restore boundary"`: `String.replace(yaml, "ubuntu-24.04-otp27.0-elixir1.17.3-dialyzer-plt-", "ubuntu-24.04-dialyzer-plt-")` | strip the resolved-output segment, e.g. replace `"ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-dialyzer-plt-"` with `"ubuntu-24.04-dialyzer-plt-"` |
| 394-395 | `{String.contains?(job, ~s(elixir-version: "1.17.3")), "verify-dialyzer must pin Elixir 1.17.3"}` | `id: beam` + `version-file: .tool-versions` + `version-type: strict` present, with no `elixir-version:` / `otp-version:` |
| 396 | `{String.contains?(job, ~s(otp-version: "27.0")), "verify-dialyzer must pin OTP 27.0"}` | (merged into the row above) |
| 400-401 | `uses: actions/cache/restore@v4` | `@v5` (lands with the Node 24 bump plan, not the toolchain plan) |
| 405-406 | `"ubuntu-24.04-otp27.0-elixir1.17.3-dialyzer-plt-"` | contains `steps.beam.outputs.otp-version` and `steps.beam.outputs.elixir-version` |
| 410-411 | `uses: actions/cache/save@v4` | `@v5` (Node 24 plan) |

Also add a mutation control that puts `otp-version: "27.0"` back into the verify-dialyzer setup-beam step and asserts non-empty errors.

**Do not touch** the CONTRIBUTING evidence assertions at lines 460-478 (`"34642915672"`, `"20260907.300.1"`, etc.). Those pin the dated historical receipt that must survive. The `workflow_job/2` and `workflow_step/2` helpers (lines 503-518) are reusable for isolating the dialyzer job's setup-beam block.

**Step-isolation helper** (lines 510-518). It splits steps at `- name:` or `- uses:`. The new setup-beam steps begin `- id: beam` (Pattern 1), so a step splitter keyed on `- (?:name:|uses:)` will **not** split at them. Either put `id: beam` below `uses:` (i.e. `- uses: erlef/setup-beam@v1` then `id: beam`), which keeps the existing splitter working, or extend the lookahead to `- (?:name:|uses:|id:)`. Flag this to the planner. The step-ordering choice affects every regex that assumes steps start with `- name:`/`- uses:`, including the verify-test checkout regex at line 243 (`~r/^      - uses: actions\/checkout@v5\n        with:\n          fetch-depth: 0\s*$/m`), which must keep matching.

---

### `test/threadline/ci_workflow_parity_contract_test.exs` (MODIFY, test)

**Analog:** self, plus the classifier idiom from `ci_topology_contract_test.exs`.

**Existing glob helper to reuse** (lines 112-123):
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

**Existing all-workflows loop to mirror** (lines 199-207, `:latest` guard):
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

**Line that goes red and must change in the same commit as the cache bump** (lines 255-256):
```elixir
      assert String.contains?(yaml, "actions/cache@v4"),
             "ci.yml must use actions/cache@v4 for the deps cache"
```
Change it to `@v5` in the Node 24 plan. Lines 258-268 (`path: deps`, e2e lockfile, no `_build`) stay.

**Matrix assertions already present** (lines 232-241). `lane: [min, current]` and `name: Run test suite` must keep matching. The new min-runner/current-version-file assertions go in this same `describe "verify-test matrix construction"` block.

**New describe blocks to add** (RESEARCH Pattern 5), each as a pure `*_errors(yaml_by_path)` function with a live `== []` assertion plus mutation controls:
1. `.tool-versions` tracked and parseable. Tracked-file check idiom from `test/threadline/removed_artifact_contract_test.exs` line 181 / `planning_dependency_contract_test.exs` line 16:
   ```elixir
   {tracked, 0} = System.cmd("git", ["ls-files", "-z"], cd: root)
   ```
   Or the narrower `System.cmd("git", ["ls-files", "--error-unmatch", "--", ".tool-versions"], cd: @repo_root, stderr_to_stdout: true)` with status `0` (status/stderr idiom from `clean_checkout_contract_test.exs` lines 48-54).
2. Every `erlef/setup-beam` step: `id: beam`, `version-type: strict`, then either `version-file: .tool-versions` with no `otp-version:`/`elixir-version:`, or the verify-test matrix-expression form.
3. The min row's runner is `ubuntu-24.04`. No `ubuntu-22.04` in any `runs-on:`/`runner:`.
4. Every `actions/cache*` step with `path: deps` or `path: .dialyzer`: `key:` and `restore-keys:` contain both `steps.beam.outputs.otp-version` and `steps.beam.outputs.elixir-version`, and none of `otp27`, `"27.0"`, `runner.os`. The explicit exemption is `path: ~/.cache/ms-playwright` (ci.yml:466-470, 620-624; browser-full.yml:84-88).
5. Mutation controls: revert one key to `ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-`, and put `otp-version: "27.0"` back into one step.

**`runner.os` naming caveat:** the ci.yml CACHE KEY CONTRACT comment (lines 65-72) says "An anti-regression grep asserts that expression appears nowhere in this file, which is why it is not spelled out here". In test source, build the needle by concatenation like `ci_topology_contract_test.exs` lines 7-8 / 270 do (`"runner" <> ".os"`), in case a future grep scans test files. No existing test asserts `runner.os` absence (grep found none), so the comment's claim becomes true once this assertion lands.

---

### `.github/workflows/ci.yml` (MODIFY, config)

**Analog:** self. Current non-matrix block shape (verify-format, lines 58-63 + 94-99; identical in verify-credo 112-124, verify-dialyzer 141-153, verify-compile-no-optional 258-270, verify-example-browser 447-463, verify-mechanical 553-563, verify-capture 601-617, verify-pgbouncer-topology 720-730, verify-docs 769-779, verify-hex-package 794-804):
```yaml
      - uses: actions/checkout@v5

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17.3"
          otp-version: "27.0"
...
      - name: Cache deps
        uses: actions/cache@v4
        with:
          path: deps
          key: ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-${{ hashFiles('mix.lock') }}
          restore-keys: ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-
```
Target: RESEARCH Pattern 1 (`id: beam`, `version-file: .tool-versions`, `version-type: strict`; key `ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-${{ hashFiles('mix.lock') }}`).

**Setup-beam-only jobs (no deps cache, keep it that way):** verify-hex-evaluator (403-406), verify-bump-rehearsal (897-900), verify-deps-audit (922-925).

**PLT cache block** (lines 155-161, 208-213):
```yaml
      - name: Restore Dialyzer PLT
        id: dialyzer-plt-restore
        uses: actions/cache/restore@v4
        with:
          path: .dialyzer
          key: ubuntu-24.04-otp27.0-elixir1.17.3-dialyzer-plt-${{ hashFiles('mix.lock') }}-${{ hashFiles('mix.exs') }}
          restore-keys: ubuntu-24.04-otp27.0-elixir1.17.3-dialyzer-plt-
...
      - name: Save Dialyzer PLT
        if: steps.dialyzer-plt-restore.outputs.cache-hit != 'true'
        uses: actions/cache/save@v4
        with:
          path: .dialyzer
          key: ${{ steps.dialyzer-plt-restore.outputs.cache-primary-key }}
```
Precedent for a hyphenated step output in dot syntax: `steps.dialyzer-plt-restore.outputs.cache-hit` (line 171). The save step reuses `cache-primary-key`, so only the restore key changes.

**verify-test matrix** (lines 278-301, 325-343). Current:
```yaml
        include:
          - lane: min
            elixir: "1.15"
            otp: "26"
            pg: "14"
            runner: "ubuntu-22.04"
          - lane: current
            elixir: "1.17.3"
            otp: "27"
            pg: "16"
            runner: "ubuntu-24.04"
    runs-on: ${{ matrix.runner }}
...
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: ${{ matrix.elixir }}
          otp-version: ${{ matrix.otp }}
...
          key: ${{ matrix.runner }}-otp${{ matrix.otp }}-elixir${{ matrix.elixir }}-mix-deps-${{ hashFiles('mix.lock') }}
          restore-keys: ${{ matrix.runner }}-otp${{ matrix.otp }}-elixir${{ matrix.elixir }}-mix-deps-
```
Target: RESEARCH Pattern 2. The checkout at 322-324 (`- uses: actions/checkout@v5` / `with:` / `fetch-depth: 0`) must stay byte-shaped for the topology regex at ci_topology_contract_test.exs:243.

**Comments that must change with the edits** (present-tense accuracy; no GSD IDs in new text):
- Lines 65-75 CACHE KEY CONTRACT. "For non-matrix jobs the runner/OTP/Elixir segments are the literals that job already pins above; for the verify-test matrix they come from the matrix values." Rewrite to say the segments come from `steps.beam.outputs.*`. The existing "(Phase 198, D-19)" / "PHASE 199" tokens are pre-existing. Do not add new ones.
- Lines 279-285 (verify-test header: "ubuntu-22.04 proving the declared floor").
- Lines 330-337 (D-19 bug history naming ubuntu-22.04 and `1.15 / otp 26 / ubuntu-22.04`). Keep it as history but make it read correctly, because `! grep -rn 'ubuntu-22.04' .github/workflows/*.yml` is a validation row. The history must therefore be reworded without that literal (e.g. "the older 22.04 image").

**Artifact upload** (lines 510-521): `uses: actions/upload-artifact@v4` → `@v7`. Inputs `name`, multi-line `path`, `if-no-files-found: warn`, `retention-days: 14` are unchanged.

---

### `.github/workflows/browser-full.yml` (MODIFY)

**Analog:** `ci.yml` verify-example-browser (same shape). Current lines 63-88 and 108:
```yaml
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17.3"
          otp-version: "27.0"
...
        uses: actions/cache@v4
          key: ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-${{ hashFiles('mix.lock') }}
          restore-keys: ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-
...
        uses: actions/cache@v4            # playwright, key unchanged (exempt)
...
        uses: actions/upload-artifact@v4  # line 108 → @v7
```

### `.github/workflows/flake-detection.yml` (MODIFY)

**Analog:** `ci.yml` verify-format. Current lines 65-75 and 135. This is the only key built on the OS-family value:
```yaml
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17.3"
          otp-version: "27.0"

      - name: Cache deps
        uses: actions/cache@v4
        with:
          path: deps
          key: ${{ runner.os }}-mix-deps-${{ hashFiles('mix.lock') }}
          restore-keys: ${{ runner.os }}-mix-deps-
```
Replace it with the Pattern 1 key (the job runs `ubuntu-24.04`, line 30). Line 135 is `actions/upload-artifact@v4` → `@v7`. Note for planner: Phase 218 later adds an all-workflows grep for this key shape, so it should not redo the key.

### `.github/workflows/deps-health.yml` (MODIFY)

**Analog:** `ci.yml` verify-deps-audit (setup-beam, no cache). Lines 38-43:
```yaml
      - uses: actions/checkout@v5

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17.3"
          otp-version: "27.0"
```
Only the setup-beam step changes. Do not add a cache.

### `.github/workflows/release.yml` (MODIFY)

**Analog:** self. Three ref-switching jobs:
- `sync-release-pr-pins` (lines 127-139). This job is contract-tested (`release_control_plane_contract_test.exs` lines 122-158: `persist-credentials: false` regex `~r/^\s+persist-credentials: false$/m`, `needs: release-please`, `run: mix release.pins\n`, concurrency group, single `PUSH_TOKEN:`):
  ```yaml
      # persist-credentials: false keeps the token out of .git/config. The steps
      # below fetch and COMPILE every dependency (`mix release.pins` is a Mix task),
      # and any dependency's compile-time code could otherwise read a persisted
      # credential. The token is supplied to the push step alone.
      - uses: actions/checkout@v5
        with:
          ref: release-please--branches--main
          persist-credentials: false

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17.3"
          otp-version: "27.0"
  ```
- `publish-hex` (lines 410-417): `ref: ${{ needs.release-ref.outputs.checkout_ref }}` then setup-beam `"1.17.3"`/`"27.0"`.
- `smoke-published` (lines 557-564): same shape as publish-hex.

Target: RESEARCH Pattern 3. Put a toolchain-first checkout (`sparse-checkout: .tool-versions`, `sparse-checkout-cone-mode: false`, `persist-credentials: false`), then setup-beam `id: beam` + `version-file` + strict, then the existing target-ref checkout unchanged. There is **no in-repo precedent** for `sparse-checkout` (grep of `.github/` found none), so the planner should rely on RESEARCH A2 plus actionlint.

`job_block!/2` in `release_control_plane_contract_test.exs` (lines 165-175) splits at the next two-space job key, so adding steps inside a job cannot break it. `persist-credentials: false` then appears twice in `sync-release-pr-pins`. The existing regex only asserts presence (`=~`), so it still passes. The single-`PUSH_TOKEN:` count is unaffected.

**Release Please step** (lines 92-99). This is the only change in its own `ci:` commit:
```yaml
      - name: Run Release Please
        id: release
        if: steps.release-preflight.outputs.should_run == 'true'
        uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
```
→ `@v5`, and the `with:` block stays unchanged. No existing test references `release-please-action@` (grep of the release contract test found none), so the bump commit can stay single-file. The new runtime contract test (landing after it, per RESEARCH "prefer T2 first") then allowlists `@v5`.

---

### `bin/verify-bump-rehearsal` (MODIFY, utility)

**Analog:** self. Delete lines 234-243 once `.tool-versions` is tracked, because `git clone --no-local` (line 227) then carries it:
```bash
# `.tool-versions` is deliberately untracked in this repository, so the clone
# does not inherit it and an asdf-managed shell would resolve a different (or
# no) Elixir inside /tmp. Copy it across when it exists so the rehearsal runs on
# the same toolchain as the tree it is rehearsing. In CI the file is absent and
# `erlef/setup-beam` has already pinned the toolchain on PATH, so this is a
# no-op there.
if [[ -f "$ROOT/.tool-versions" ]]; then
  cp "$ROOT/.tool-versions" "$CLONE/.tool-versions"
  printf '    copied the untracked .tool-versions into the throwaway tree\n'
fi
```
If it were left in place, the `cp` would overwrite the clone's committed file with the working-tree copy, which silently rehearses uncommitted toolchain edits. That is an actual failure class for deleting it, not just tidiness. No test references this block (RESEARCH grep: none). Surrounding style: `step`/`fail` helpers and `printf '    ...'` indentation (lines 223-232).

---

### `CONTRIBUTING.md` (MODIFY, doc)

**Analog:** self. Sections:
- **Lines 22-24**, requirements: `- Elixir 1.15+ (CI uses 1.17.3)` / `- OTP 26+ (CI uses OTP 27.0)`. Update to the committed pin (27.3.4.15).
- **Lines 30-42**, the "intentionally does **not** commit a `.tool-versions` file" paragraph plus the "local `.tool-versions` you leave uncommitted" advice. Rewrite: the file pins the CI current lane, and the floor stays proven by the min lane. The asdf env-override names are ASSUMED (RESEARCH A3), so verify them before writing.
- **Line 563**, the job table row for `verify-dialyzer`: "strict full-build analysis on Elixir 1.17.3 / OTP 27.0". Update it. The topology test asserts only `| \`verify-dialyzer\` | \`mix verify.dialyzer\`` (ci_topology_contract_test.exs:448), so the trailing prose is free to change.
- **Lines 579-583**, the present-tense lane sentence: "on the exact current lane: Ubuntu 24.04, Elixir 1.17.3, and OTP 27.0". Update it.
- **Lines 608-637**, "Authenticated cold/hit evidence (2026-09-11)", including "resolving to Erlang/OTP 27.0.1". **Do not edit.** It is a historical receipt, and ci_topology_contract_test.exs:460-478 pins its tokens.
- **Lines 753-756**, "Ongoing releases (0.6.1+)". Add an "Upgrading the Release Please action" `###` subsection after it (before `### Recovery / dry-run` at 758), in a separate `docs:` commit. Existing heading style: `### Title`, numbered steps, bold filenames, backticked commands.

Doc-contract anchors that must keep matching: `| Job key | Purpose |` table (parity test lines 150-164), `### \`ci-required\` needs: roster` (topology line 332), `Run test suite (min)` / `(current)` strings (parity lines 243-248).

---

## Shared Patterns

### Pure classifier + mutation controls (the "never tautological" idiom)
**Source:** `test/threadline/ci_topology_contract_test.exs` lines 114-188 (test) and 365-482 (classifier)
**Apply to:** every new assertion in the runtime, parity and topology tests.
The live tree must yield `[]`, and each synthetic or `String.replace`-mutated input must yield non-empty errors, with a named control message: `"#{control} mutation must make the ... contract fail"`.

### Workflow enumeration by glob (both extensions, refuse empty)
**Source:** `ci_topology_contract_test.exs` lines 252-260; `ci_workflow_parity_contract_test.exs` lines 112-123; `deps_audit_contract_test.exs` lines 76-86
**Apply to:** the runtime test and all "every workflow" parity assertions. Never hardcode filenames (parity lines 106-111 explain why).

### Job / step block isolation
**Source:** `ci_topology_contract_test.exs` `workflow_job/2` (503-508) and `workflow_step/2` (510-518); `release_control_plane_contract_test.exs` `job_block!/2` (165-175); `deps_audit_contract_test.exs` `job_block/2` (29-40)
**Apply to:** per-job setup-beam and cache-key checks. Mind the `- id: beam` step-start caveat above.

### Comment stripping before scanning
**Source:** `strip_comment_lines/1` (topology 531-536, deps_audit 61-66)
**Apply to:** the `uses:` scanner and the `ubuntu-22.04` / `runner.os` absence scans.

### Self-referential needle concatenation
**Source:** `ci_topology_contract_test.exs` lines 7-8 (`"verify." <> "doc_contract"`) and 270 (`"ANTHROPIC" <> "_API_KEY"`)
**Apply to:** literals the tests forbid (`runner.os`, `ubuntu-22.04`, `cache@v4`), so grep-based repo gates do not trip on test source.

### Actionable failure messages
**Source:** every assertion in `ci_topology_contract_test.exs` / `release_control_plane_contract_test.exs`. Messages state the consequence ("...launders a red gate into a green merge") and not only the expectation.
**Apply to:** all new assertions. They must carry no GSD phase/plan/requirement IDs in new text (MILESTONE-GUIDE §8). Existing IDs in old comments are pre-existing.

### Workflow step shape
**Source:** ci.yml throughout. Blank line between steps, `- name:` for named steps, bare `- uses:` for checkout/setup, 6-space step indent, 8-space `with:`.
**Apply to:** all workflow edits. Keep `- uses: actions/checkout@v5` bare where tests match it by regex (verify-test, topology line 243).

## No Analog Found

| File / construct | Role | Data Flow | Reason |
|---|---|---|---|
| release.yml toolchain-first sparse checkout (Pattern 3) | config | event-driven | No `sparse-checkout` anywhere in `.github/`. Use RESEARCH Pattern 3 + actionlint, and verify on the first release-path run (maintainer `workflow_dispatch dry_run: true`). |
| verify-test matrix with an empty-string `version-file` row (Pattern 2) | config | batch | No matrix row in the repo omits a key consumed by `with:`. RESEARCH A1 plus its fallback (explicit current-row pins + parity assertion against parsed `.tool-versions`). |

## Metadata

**Analog search scope:** `test/threadline/*_contract_test.exs`, `.github/workflows/*.yml`, `bin/verify-bump-rehearsal`, `CONTRIBUTING.md`
**Files scanned:** 12 (4 CI/release contract tests fully read or excerpted, clean_checkout / removed_artifact tests excerpted for the git idiom, 5 workflows grepped and excerpted, CONTRIBUTING, bin script)
**Pattern extraction date:** 2026-09-26
