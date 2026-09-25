# Phase 199: Decouple - Pattern Map

**Mapped:** 2026-09-10
**Files analyzed:** 47 source/config/test surfaces plus 427 tracked fixture entries
**Analogs found:** 16 / 16 logical file groups (2 are partial compositions; see "No Complete Analog")

## File Classification

The fixture corpus is one atomic move even though it contains 427 tracked files. The TypeScript readers are likewise one adapter migration: every listed reader imports one shared path authority rather than retaining local constants.

| New/Modified File | Role | Data Flow | Closest Tracked Analog | Match Quality |
|---|---|---|---|---|
| `test/fixtures/operator_surface/{design-system-ledger.json,scorecards/**,golden/**,refute/**,critic-scores/.gitkeep}` | test fixture | file-I/O / immutable evidence | Existing files at the corresponding `.planning/` paths | exact move |
| `test/fixtures/operator_surface/README.md` | documentation/config | file-I/O ownership contract | `DESIGN-SYSTEM.md` plus maintainer-command prose in `CONTRIBUTING.md` | role-match |
| `test/support/operator_surface_fixtures.ex` | test utility | file-I/O / request-response | `test/threadline/phase198_ref_disposition_contract_test.exs:4-7` | exact anchor, role-match API |
| `lib/threadline/operator_surface/mechanical_checker.ex` | service/utility | transform over explicit file inputs | Same file `run/1` seam at lines 92-102 | exact |
| `lib/mix/tasks/critic.measure.ex`, `lib/mix/tasks/critic.synth.ex` | maintainer task/service | file-I/O / transform | Their current option parsing, decode, splice, and reporting structure | exact role |
| `examples/threadline_phoenix/e2e/support/operator-surface-paths.ts` | utility | file-I/O / transform | `examples/threadline_phoenix/e2e/critic/run.ts:26-42`; `critic/cache.ts:18-27` | exact anchor |
| `examples/threadline_phoenix/e2e/critic/{bundle,gate,label,label_web,panel,prompt,refute,report,report_html,rubric,run,scorecard}.ts` | utility/service | file-I/O / transform | Shared imports already used by the critic family in `run.ts:26-36` | exact topology |
| `examples/threadline_phoenix/e2e/tests/{operator-graded-capture,operator-page-capture,operator-storybook-capture,operator-stress,operator-tier-a-capture}.spec.ts` | integration test/writer | file-I/O / event-driven | Critic ESM anchoring in `critic/run.ts:26-42` | role-match |
| `test/threadline/operator_surface/{mechanical_checker,critic_trust,refute_partition,stress_ledger,stress_router}_test.exs`, `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` | test | file-I/O / transform | Existing synthetic-fixture and cross-corpus contract structure | exact |
| `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs` | contract test | file-I/O / transform | `refute_partition_test.exs:39-87`, `mechanical_checker_test.exs:104-135`, CI capture contract at `ci.yml:523-560` | exact composition |
| `test/threadline/removed_artifact_contract_test.exs`; `test/threadline/readme_doc_contract_test.exs` | contract test | file-I/O / transform | `phase198_ref_disposition_contract_test.exs:103-216`; current README contract at lines 110-124 | role-match |
| `.formatter.exs`, `bench/.formatter.exs`, `examples/threadline_phoenix/.formatter.exs`; formatter-topology contract (recommended `test/threadline/formatter_topology_contract_test.exs`) | config + contract test | batch / transform | Existing child formatter configs; `ci_topology_contract_test.exs:230-328` for bidirectional config/docs derivation | role-match |
| `.gitignore`; disposable-clone proof harness (recommended `bin/verify-clean-checkout`) | config + utility | batch / file-I/O | `ci.yml:689-729` disposable archive inspection and `mix.exs:126-137` fresh setup alias | partial composition |
| `mix.exs`, `mix.lock`, `.dialyzer_ignore.exs`, `test/threadline/dialyzer_ignore_contract_test.exs` | config + contract test | batch / static analysis | MODE-B locked ceiling test in `mechanical_checker_test.exs:20-34`; frozen ratchets in `critic_trust_test.exs:30-45` | role-match |
| `.github/workflows/ci.yml`, `test/threadline/ci_topology_contract_test.exs`, `CONTRIBUTING.md` | CI config + contract + docs | batch / event-driven | Exact aggregate and roster implementation at `ci.yml:741-782` and `ci_topology_contract_test.exs:230-328` | exact |
| `.planning/phases/198-green-bringup/198-41-PLAN.md`; Phase 199 summary/removal inventory | historical citation/docs | file-I/O / transform | Immutable-receipt/citation discipline in `phase198_ref_disposition_contract_test.exs:103-216` | role-match |
| Delete `.planning/ROADMAP.md.bak`, `.planning/HANDOFF.json`, `update_roadmap.rb`, `fix_tests.exs` | tracked artifact removal | file-I/O | Git history plus `.planning/ARCHIVE-REGISTER.md` recovery-identity convention | role-match |

The old fixture literals also occur in `CONTRIBUTING.md`, `DESIGN-SYSTEM.md`, `lib/threadline/critic_trust/measure.ex`, and `lib/threadline/operator_surface/live/stress_live.ex`; these are modifications in the atomic reader migration, not separate path authorities.

## Pattern Assignments

### Fixture-path adapters: `test/support/operator_surface_fixtures.ex`

**Analog:** `test/threadline/phase198_ref_disposition_contract_test.exs:4-7`

**Stable source anchor:**

```elixir
@root Path.expand("../..", __DIR__)
@inventory Path.join(@root, ".planning/audits/198-round10-ref-disposition.json")
@decision Path.join(@root, ".planning/audits/198-round10-ref-disposition.md")
```

Copy the `__DIR__`-anchored shape, but expose named functions such as `root!/0`, `ledger!/0`, `scorecards!/0`, `golden!/0`, `refute!/0`, and `critic_scores!/0`. Do not copy `test/support/getting_started_fixtures.ex`'s compile-time `File.cwd!/0`; D-09 explicitly rejects caller-CWD roots.

The helper is a test edge only. `MechanicalChecker` receives its resolved scorecard directory and decoded floors; it must not import the helper or know `test/fixtures`.

### TypeScript path adapter: `e2e/support/operator-surface-paths.ts`

**Analog:** `examples/threadline_phoenix/e2e/critic/run.ts:26-42`

**Imports and anchor:**

```typescript
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");
const goldenSetPath = resolve(repoRoot, ".planning/golden/golden-set.json");
```

Move this responsibility into one module and export the new `test/fixtures/operator_surface` roots. All critic modules and five capture specs import it. Preserve each consumer's business logic; remove `process.cwd()` and independently-computed repository roots.

**Containment analog:** `examples/threadline_phoenix/e2e/critic/cache.ts:58-72`

```typescript
function cacheKey(cellId: string, dimension: string, rubricHash: string, modelId: string,
  screenshotHash: string): string {
  const safe = (s: string) => s.replace(/[^a-zA-Z0-9._-]/g, "_");
  return `${safe(cellId)}__${safe(dimension)}__${safe(rubricHash)}__${safe(modelId)}__${safe(screenshotHash)}`;
}

function cachePath(key: string): string {
  return resolve(verdictCacheDir, `${key}.json`);
}
```

This is the closest existing ID-derived-path pattern, but sanitization alone is not the Phase 199 contract. The adapter must additionally use `path.relative` and canonicalized roots (`realpathSync`, canonicalizing the existing parent for new outputs), reject absolute/`..` relative results and symlink escapes, and reject generated-output roots that equal or nest inside immutable roots.

**Positive control analog for aliases/symlinks:** `test/threadline/phase198_ref_disposition_contract_test.exs:138-169` creates canonical copies and symlink aliases, then requires the strict verifier to reject both aliases. Reuse that testing shape for traversal, absolute-path, symlink-escape, and immutable/output-alias cases.

### Pure checker: `lib/threadline/operator_surface/mechanical_checker.ex`

**Analog:** its existing explicit seam at lines 92-102.

```elixir
def run(opts \\ []) do
  dir = Keyword.get(opts, :scorecard_dir, @scorecards_dir)
  floors = Keyword.get(opts, :mechanical_floors) || load_floors()

  violations =
    dir
    |> list_scorecards()
    |> Enum.flat_map(&check_scorecard(&1, floors))

  if violations == [], do: {:ok, []}, else: {:error, violations}
end
```

Keep the option-driven data flow and arithmetic pipeline. Remove repository defaults (`@scorecards_dir`, `@ledger_path`, `load_floors/0`), require `:scorecard_dir` and `:mechanical_floors`, and make missing/empty corpus errors explicit. The shipped module remains pure with respect to repository discovery.

**Error-handling delta:** current `list_scorecards/1` at lines 138-161 maps every `File.ls/1` error to `[]`; replace that fail-open branch with a tagged/task-oriented error naming the expanded path and recovery command. Parsing should retain fail-closed behavior rather than rescuing malformed JSON into an empty corpus.

### Non-vacuity and positive-control tests

**Primary analog:** `test/threadline/operator_surface/refute_partition_test.exs:39-50`

```elixir
assert File.exists?(@refute_manifest),
       "#{@refute_manifest} not found — run plan 195-03 Task 2 to create it"

m = manifest()

assert is_binary(m["version"]) and m["version"] != ""
assert is_list(m["items"]) and length(m["items"]) > 0,
       "#{@refute_manifest} items must be a non-empty array"
```

**Synthetic teeth analog:** `mechanical_checker_test.exs:104-135`

```elixir
dir = write_fixtures([passing_scorecard()])
assert MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: %{}) == {:ok, []}

off = put_in(passing_scorecard(), ["element_styles"], [element_style(%{"border_radius" => "10px"})])
dir = write_fixtures([off])
assert {:error, violations} = MechanicalChecker.run(scorecard_dir: dir, mechanical_floors: %{})
assert Enum.find(violations, &(&1.metric == "border_radius"))
```

Reverse the obsolete lines 117-123 absent-directory success assertion. The new fixture contract should test, in order: root exists, named files exist, JSON/YAML parse, eligible committed scorecards are non-empty, paired ARIA/JSON and cross-dataset references resolve, generated and immutable roots are distinct, and Hex contents exclude the corpus.

The CI shell analog at `.github/workflows/ci.yml:523-560` already demonstrates a nonzero count, paired-file completeness, a byte-drift check, and a recovery command. Port its behavior to the new root; do not pin a brittle absolute count.

### Maintainer writers: `critic.measure.ex`, `critic.synth.ex`, and TS capture/score writers

**Task topology analog:** `lib/mix/tasks/critic.measure.ex:42-85`

```elixir
use Mix.Task
alias Threadline.CriticTrust.{LedgerSplice, Measure}

def run(argv) do
  {:ok, _} = Application.ensure_all_started(:crypto)
  source = parse_source(argv)
  golden = read_golden(source)
  scores = read_scores()
  block = Measure.build_block(golden, scores, read_rubric_versions())

  with {:ok, t1} <- LedgerSplice.replace(File.read!(ledger_path), block),
       {:ok, t2} <- LedgerSplice.replace_provenance(t1, provenance_for(source, golden)) do
    # atomic writer goes here
    print_summary(block, source)
  else
    {:error, reason} -> Mix.raise("critic.measure: could not splice ledger block (#{inspect(reason)})")
  end
end
```

Preserve `OptionParser.parse/2`, `Mix.raise/1`, decode/transform/reporting, and the pure `Measure`/`LedgerSplice` calls. Add `--fixture-root`/`--output-root` with `flag > Mix.Project.project_file()` default precedence and repository-only diagnostics.

**Atomic replacement primitive analog:** `test/threadline/phase198_zero_human_uat_contract_test.exs:243-278` uses `File.rename!/2` and verifies that missing, renamed, copied, and byte-mutated evidence is rejected. There is no production sibling-temp writer to copy verbatim. Implement the narrow composition mandated by D-04: encode bytes, create a uniquely named sibling temp, write/open-and-sync/close, `File.rename!/2` over the target, clean the temp on failure, and print the exact `git diff -- <target>` review command. Apply the same sibling-temp/rename topology with Node `renameSync`.

The current direct writes in `critic.measure.ex:64-69`, `critic.synth.ex:86-87`, `critic/cache.ts:46-48`, and `critic/scorecard.ts:68-70` are targets to replace, not analogs to preserve.

### Artifact and citation contracts

**Analog:** `test/threadline/phase198_ref_disposition_contract_test.exs:103-216`

The contract first validates canonical inventory against live state, then copies canonical artifacts into a unique `System.tmp_dir!()` directory, introduces path/symlink/content mutations, and asserts strict rejection. Copy that test architecture for `removed_artifact_contract_test.exs`: derive tracked root executables, assert the four exact removals are absent, scan active executable/doc surfaces for live citations, and positive-control the scanner with a temporary document containing one removed path.

**Doc assertion analog:** `test/threadline/readme_doc_contract_test.exs:110-124`

```elixir
readme = File.read!("README.md")
assert String.contains?(readme, "current support claims, stay with")
assert contains_normalized?(readme, "rather than inferring broader compatibility from the README")
```

Re-enable the disabled assertion using README's current canonical compatibility wording. Prove its teeth by applying the contract helper to a deliberately mutated temporary string/file, not by modifying README during a normal test.

For `198-41-PLAN.md`, append a minimal historical note: the handoff existed at execution time, was superseded/removed in Phase 199, and current evidence is the durable `198-41-SUMMARY.md`/terminal record. Do not erase the historical citation.

### Child formatter topology

**Analogs:** `.formatter.exs:1-3`, `bench/.formatter.exs:1-2`, `examples/threadline_phoenix/.formatter.exs:1-5`.

```elixir
# root
[inputs: ["{mix,.formatter,.credo}.exs", "{config,lib,test}/**/*.{ex,exs}"]]

# bench child
[inputs: ["{mix,.formatter}.exs", "{config,lib,test,scripts}/**/*.{ex,exs}"]]

# example child
[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}", "priv/*/seeds.exs"]
]
```

Root should add `subdirectories: ["bench", "examples/threadline_phoenix"]` and `scripts/**/*.{ex,exs}` while leaving child paths out of root `inputs`. Extend bench root scripts and example Storybook/priv scripts in their owning child config, preserving `import_deps` and migration subdirectories.

For a topology contract, copy the derive-and-compare style of `ci_topology_contract_test.exs:230-328`: parse root subdirectories and each input set, expand representative paths, require each planned file to have exactly one owner, and positive-control an overlapping pattern.

### Clean-clone proof and ignore policy

**Closest analogs:** `.github/workflows/ci.yml:689-729` and `mix.exs:126-137`.

The Hex job uses `mktemp -d`, inspects the actual artifact, reports actionable errors, and removes the temporary directory on every branch. `test.setup` centralizes the dependency preparation command used by a fresh checkout. Combine those conventions in `bin/verify-clean-checkout`: clone committed HEAD into a disposable directory, run `mix deps.get --check-locked`, then require exact empty output from `git status --porcelain=v1 --untracked-files=all`. Add probes for crash dumps, root Hex tarballs, PLT files/hashes, and all `e2e/artifacts/`, while explicitly proving `tests/**-snapshots/` remains trackable.

Update `.gitignore` with root-anchored producer paths. Existing lines 50-69 show the right narrow style for Playwright and critic output, but Phase 199 broadens only `/examples/threadline_phoenix/e2e/artifacts/` and moves critic-score ignores to `/test/fixtures/operator_surface/critic-scores/*` with a `.gitkeep` exception. Root-anchor `/threadline-*.tar`, `/threadline-*/`, `/erl_crash.dump`, and the chosen PLT filenames/hashes; do not ignore `.tool-versions` or operator scratch.

### Dialyzer config and strict ignore ceiling

**Config insertion point:** `mix.exs:32-84` already centralizes `project/0`, optional dependencies, and the placeholder `dialyzer: [plt_add_apps: [:mix]]`. Add Dialyxir beside Credo/ExDoc as `only: [:dev, :test], runtime: false`, keep the nine optional apps plus `:mix` and `:ex_unit` in `plt_add_apps`, retain default `:unknown`, add `:unmatched_returns` and `:extra_return`, point at the external PLT root and `.dialyzer_ignore.exs`, and enable unused-filter checking.

**Tighten-only analog:** `mechanical_checker_test.exs:20-34` pins ceiling constants verbatim; `critic_trust_test.exs:30-45` freezes baseline maps and allows upward tightening while making lowering explicit.

```elixir
for {constant, value} <- [
      {"@mode_b_card_nesting_ceiling", "3"},
      {"@mode_b_distinct_accent_hue_ceiling", "3"}
    ] do
  assert String.contains?(source, "#{constant} #{value}"),
         "#{@checker_path} must declare #{constant} #{value}"
end
```

Use the same source-contract posture for a committed `@ignore_ceiling`: parse `.dialyzer_ignore.exs` with `Code.string_to_quoted_with_comments/2`; accept only literal `{binary_file, binary_description}` tuples; require one immediately preceding rationale with irreducibility reason and removal trigger; reject regex/file/warning-class/wildcard entries and duplicates; require `length(entries) <= @ignore_ceiling`; and invoke `mix dialyzer --list-unused-filters` separately. Positive-control both an appended strict entry (ceiling breach) and a broadened entry (shape breach).

### CI aggregate integration and PLT cache

**Aggregate analog:** `.github/workflows/ci.yml:741-782`

```yaml
ci-required:
  name: CI required
  if: always()
  needs:
    - verify-format
    # existing jobs...
  steps:
    - name: Decide whether all needed jobs succeeded
      uses: re-actors/alls-green@b5b5b37504aa4183270bd3d855c52a67f212be35
      with:
        jobs: ${{ toJSON(needs) }}
```

Add stable `verify-dialyzer` to the header roster and unconditionally to `needs`. Preserve `if: always()` and the pinned aggregate action. Update the `CONTRIBUTING.md` roster in the same commit; `ci_topology_contract_test.exs:290-328` already proves both drift directions and a non-vacuous minimum.

**PLT cache-key analog:** `.github/workflows/ci.yml:65-99`

```yaml
- name: Cache deps
  uses: actions/cache@v4
  with:
    path: deps
    key: ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-${{ hashFiles('mix.lock') }}
    restore-keys: ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-
```

The adjacent contract comment explicitly requires the PLT key to add `hashFiles('mix.exs')` and permits near-miss PLT restore only below the same runner/OTP/Elixir prefix. Structure the job as checkout/setup/deps → restore PLT → conditional `mix dialyzer --plt` → save PLT → timed `mix dialyzer --no-check`. Saving before analysis is load-bearing: warnings must not discard a valid newly-built PLT.

Add the same blocking analyzer command to `mix.exs:138-156`'s `ci.all`. Do not add Dialyzer to the no-optional lane.

Record cold-build and cache-hit measurements in `CONTRIBUTING.md` only after real current-lane runs: commit SHA, `ubuntu-24.04`, OTP `27.0`, Elixir `1.17.3`, `mix.lock`/`mix.exs` hashes, wall time, peak RSS, and run links. The measured cold sequence determines timeout plus explicit headroom.

## Shared Patterns

### Stable Roots and Explicit Inputs

**Sources:** `phase198_ref_disposition_contract_test.exs:4-7`, `critic/run.ts:26-42`, `mechanical_checker.ex:92-102`

- Test code anchors with `__DIR__`; Mix tasks anchor with `Mix.Project.project_file/0`; ESM anchors with `import.meta.url`.
- Flags override deterministic defaults. No application environment and no caller CWD.
- Runtime/pure modules receive paths or decoded data and never discover repository fixtures.

### Fail-Closed Evidence UX

**Sources:** `refute_partition_test.exs:39-50`, `ci.yml:523-560`

- Validate existence, parseability, nonzero eligible count, and joins before evaluation.
- Every failure names the dataset, absolute resolved path, repository-only status, and one exact recovery command.
- The human labeling queue is the only intentionally empty corpus.

### Immutable Inputs, Generated Outputs, Atomic Writes

**Sources:** `critic/scorecard.ts:24-27,68-94`, `phase198_zero_human_uat_contract_test.exs:243-278`

- Immutable ledger/scorecard/golden/refute paths and generated critic-score/output roots never alias.
- Resolve and canonicalize before I/O; test `../`, absolute paths, prefix-confusion names, and symlinks.
- Writers use same-directory temp plus rename and leave ordinary tests read-only.

### Contract Tests with Teeth

**Sources:** `mechanical_checker_test.exs:104-135`, `phase198_ref_disposition_contract_test.exs:138-216`, `ci_topology_contract_test.exs:290-328`

- Test a valid fixture, then mutate exactly one protected property and require failure.
- Derive both sides of rosters/contracts from source and compare in both directions.
- Add a non-vacuity floor so a broken parser cannot return an empty set and pass.

### Named Local/CI Entrypoints

**Source:** `mix.exs:87-156`

Keep contributor commands behind `verify.*` aliases and keep `ci.all` aligned with blocking CI. Maintainer-only mutation commands stay outside `ci.all`.

## No Complete Analog

| File/Concern | Closest Tracked Source | Missing Piece Planner Must Specify |
|---|---|---|
| Atomic fixture writer | `phase198_zero_human_uat_contract_test.exs:243-278` | No production sibling-temp + fsync + rename helper exists; implement and test the D-04 composition explicitly. |
| Disposable clean-clone proof | `.github/workflows/ci.yml:689-729`; `mix.exs:126-137` | No current command clones committed HEAD and asserts exact all-untracked cleanliness; add a bounded harness with cleanup/trap. |
| Symlink-safe TypeScript output containment | `critic/cache.ts:58-72`; `phase198_ref_disposition_contract_test.exs:138-169` | Existing sanitizer and `startsWith` guard are insufficient; add `path.relative` plus canonical parent/root checks. |
| Dialyzer ignore parser | MODE-B ceiling contracts in `mechanical_checker_test.exs:20-34` | No ignore file exists yet; use the research-specified AST/comments contract, not `Code.eval_file` plus count alone. |

## Tracked-Source Gate

All analog paths named above returned non-empty output from `git ls-files -- <path>`. No `.gsd` capability mirror, dependency directory, `_build` artifact, or ignored runtime copy is cited. The planned fixture destination does not exist yet; its source corpus is tracked at the five `.planning/` roots and contains 427 entries.

## Metadata

**Analog search scope:** `lib/`, `test/`, `examples/threadline_phoenix/`, `bench/`, `scripts/`, `bin/`, `.github/`, root Mix/formatter/ignore/docs files

**Executable old-path readers found:** 30

**Strong analog families used:** 5 — explicit input/anchors, evidence contracts, mutation/atomic primitives, formatter/config topology, CI aggregate/cache

**Pattern extraction date:** 2026-09-10
