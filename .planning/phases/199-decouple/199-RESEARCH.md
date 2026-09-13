# Phase 199: Decouple - Research

**Researched:** 2026-09-10
**Domain:** Repository-owned test evidence, Mix/Playwright path isolation, clean-checkout hygiene, and Dialyzer adoption
**Confidence:** HIGH for repository architecture; MEDIUM for current external-tool details; LOW for the not-yet-measured Dialyzer backlog and CI cost

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Fixture Topology and Ownership

- **D-01:** Use one domain-scoped mirror rooted at `test/fixtures/operator_surface/`: `design-system-ledger.json`, `scorecards/`, `golden/`, `refute/`, and `critic-scores/`. Preserve the established dataset vocabulary rather than introducing new `baselines/`, `oracles/`, or per-test copies. This is the least-surprising migration for a corpus shared by ExUnit, Mix tasks, TypeScript tools, Playwright, and CI. — **Reversibility:** costly — changing topology later would repeat the coordinated path migration across more than 30 executable/configuration readers and their cross-dataset joins.
- **D-02:** Move every tracked corpus entry with `git mv` and preserve filename, relative structure, JSON/YAML bytes, line endings, ordering, IDs, and cross-references. Record a before/after SHA-256 manifest so the move cannot silently become evidence regeneration.
- **D-03:** Treat `design-system-ledger.json`, `scorecards/**`, reviewed `golden/**`, and `refute/refute-set.json` as immutable committed evidence. `critic-scores/` remains the required moved dataset root but contains ignored, nondeterministic local output except for its tracked skeleton. Other reports, verdict caches, screenshots, and temporary work remain generated outputs under precise producer-owned ignored paths, not committed baselines.
- **D-04:** Ordinary tests are read-only over committed fixtures. Regeneration occurs only through named maintainer commands, writes through a sibling temporary file followed by rename, and always ends in an explicit diff/review. No test run or CI gate may silently accept or rewrite changed fixture bytes.
- **D-05:** Required committed evidence is non-vacuous: a missing root, missing required file, malformed structured file, or zero eligible committed scorecards is a hard failure that names the resolved path and recovery command. An intentionally empty human labeling queue may remain a guided no-op where emptiness is part of its schema; the committed scorecard, synthetic, refute, and ledger gates may not.
- **D-06:** Keep the existing scorecard-versus-critic-output separation guard and add containment checks so IDs or dimensions cannot escape their assigned roots. String-prefix containment is insufficient; use `Path.safe_relative/2` or equivalent normalized `path.relative` logic and reject symlink/path-traversal escapes.

### Evidence-Reader Contract

- **D-07:** Shipped/pure library code receives filesystem-backed evidence explicitly. In particular, `MechanicalChecker` must accept its scorecard corpus and mechanical floors as inputs and must not default to a repository-relative `test/fixtures/` path. Threadline consumers must never inherit a hidden dependency on files excluded from Hex.
- **D-08:** Put thin repository-owned path adapters only at execution edges: ExUnit/test support, maintainer Mix tasks, e2e TypeScript tooling, and CI shell steps. Do not create a global resolver in the runtime namespace, use `Application` environment as a fixture service locator, or add compile-time configuration.
- **D-09:** Resolve defaults from stable source anchors, never the caller's current directory: Mix tooling anchors from `Mix.Project.project_file/0`; TypeScript tooling anchors from `import.meta.url`; test helpers expose the fixture root explicitly. Commands must work from the repository root, a nested directory where the tool supports it, and an isolated worktree.
- **D-10:** Optional maintainer CLI overrides use explicit `--fixture-root` and/or `--output-root` flags with precedence `flag > deterministic default`. Do not use ambient environment variables as the primary contract. Normalize and validate any override before reading or writing.
- **D-11:** Immutable input roots and generated-output roots may never alias. Maintainer writers must reject a target inside `scorecards/`, `golden/`, `refute/`, or the ledger unless the named operation is explicitly the canonical regeneration path for that corpus.
- **D-12:** Failures are task-oriented developer UX: say which dataset is unavailable or invalid, show the fully resolved path, name whether the command is repository-only, and provide one exact next command. Maintainer-only tasks invoked from an installed Hex dependency must fail clearly rather than exposing repository layout as adopter configuration.

### Deletion, Citation Repair, and Clean-Checkout Hygiene

- **D-13:** Use surgical deletion, not an archive junk drawer or tombstone layer. After confirming no executable consumer remains, remove the tracked stale backup, handoff, and one-off scripts with `git rm`; Git history is the recovery mechanism. Initial evidence identifies `.planning/ROADMAP.md.bak`, `.planning/HANDOFF.json`, `update_roadmap.rb`, and `fix_tests.exs` as candidates.
- **D-14:** Repair citations in the same logical change as deletion. When a historical plan cited a then-live transient artifact, preserve truth with a minimal addendum stating that the artifact existed at execution time and was superseded/removed in Phase 199, while routing any current dependency to durable summary or ratification evidence. Do not rewrite history to pretend the transient artifact never existed, and do not leave a live-input citation to a missing path.
- **D-15:** Re-enable the assertion that `fix_tests.exs` commented out, but assert README's current canonical wording rather than restoring obsolete copy. Demonstrate the repaired assertion's teeth with a deliberate temporary mutation before recording the passing targeted test.
- **D-16:** Before deleting any candidate, record its purpose, last meaningful use, superseding evidence, and recovery commit/SHA in the removal commit or phase summary. The post-change check must find no runtime/CI/Mix consumer and no active documentation citation for any removed path.
- **D-17:** Shared `.gitignore` entries are for universally generated repository output, not individual workstation preferences. Use anchored producer-owned patterns; do not add broad extensions or directories that can hide reviewed fixtures, source, or snapshot baselines. Ignoring is not a secrecy or CI-retention control.
- **D-18:** Treat the Playwright `e2e/artifacts/` tree as generated and ignored while keeping reviewed `tests/**-snapshots/` baselines trackable. Keep explicit ignores for Playwright `test-results/`, `playwright-report/`, and `blob-report/`. Root-anchor Hex build tarballs instead of using a broad directory pattern that could hide source.
- **D-19:** Prove DECOUPLE-05 in a disposable fresh clone, not by laundering the maintainer's current untracked files into shared ignores. Run `mix deps.get --check-locked` and require exact empty `git status --porcelain=v1 --untracked-files=all`; include generated artifacts, crash dumps, build tarballs, and e2e output in the probe. Current operator-local scratch and `.tool-versions` do not become shared policy merely because they exist locally.
- **D-20:** Configure root formatting with child-project-aware subdirectories for `bench/` and `examples/threadline_phoenix/`, plus root `scripts/**/*.{ex,exs}` inputs. Preserve each child's own formatter/import rules; extend child inputs where needed (including bench root scripts and example Storybook/priv scripts) and avoid overlapping parent inputs with formatter subdirectories.
- **D-21:** The contract is about tracked repository content: no tracked one-off patch/migration executable remains at the root. Ignored untracked maintainer scratch is not deleted or promoted by this phase without separate ownership evidence.

### Dialyzer Bootstrap and Ratchet

- **D-22:** Add Dialyxir as a dev/test-only, non-runtime dependency and make Dialyzer blocking in Phase 199. Do not use an advisory warm-up period: the reason it lands now is to typecheck Phases 201, 203, and 204 before their refactors merge.
- **D-23:** Bootstrap with narrow fixes plus a strict ignore ratchet. Fix every small, clearly correct finding in Phase 199. A finding whose correct fix requires the architecture work reserved for Phase 203 may be temporarily ignored only after exact triage; a generated broad warning snapshot is forbidden.
- **D-24:** Configure all nine optional applications explicitly in the PLT: `:phoenix`, `:phoenix_live_view`, `:phoenix_html`, `:phoenix_pubsub`, `:oban`, `:ex_aws`, `:ex_aws_s3`, `:hackney`, and `:sweet_xml`, in addition to required tooling applications such as `:mix` and `:ex_unit`. Analyze the full build only; retain the independent no-optional-dependencies compile lane.
- **D-25:** Retain Dialyxir's default `:unknown` signal and enable `:unmatched_returns` and `:extra_return`. Unknown calls indicate incomplete PLT coverage; discarded tagged results and impossible declared returns can expose correctness defects and must not be globally muted.
- **D-26:** `.dialyzer_ignore.exs` may contain only strict `{file, warning_description}` entries, one entry per suppression, each immediately preceded by a rationale comment. No regex, file-wide tuple, warning-class tuple, wildcard, or copied broad baseline is allowed. Each rationale names why the warning is irreducible, any upstream issue/version, and a concrete removal trigger.
- **D-27:** The initial ceiling equals the count of individually approved strict entries after triage and can only decrease. An executable contract checks parseability, exact entry shape, one rationale per entry, no duplicate/broad filters, count at or below the committed ceiling, and no unused filters; include a positive control proving that an extra or broadened entry fails.
- **D-28:** Add a stable `verify-dialyzer` CI job on the exact current Elixir/OTP lane only, include it unconditionally in `ci-required.needs`, and update the CI header roster, contributor coverage table, and topology contracts in the same change. Add the same blocking analyzer command to local `mix ci.all` so local and CI contracts do not diverge.
- **D-29:** Cache PLTs outside `_build` and ignore only the PLT files/hashes. Key by runner/OS, exact OTP, exact Elixir, `mix.lock`, and `mix.exs`; restore only below the same runner/OTP/Elixir prefix. Separate restore, build, analysis, and save behavior so an analysis warning does not throw away an otherwise valid newly built PLT.
- **D-30:** Measure a true cache-miss PLT build and first analysis on the current CI image, then measure a cache-hit run separately. Document commit/SHA, runner image, OTP/Elixir, dependency/config hashes, wall time, and peak memory in `CONTRIBUTING.md`; do not estimate or fold dependency download time into the PLT number. Derive the job timeout from the measured cold run with explicit headroom.

### the agent's Discretion

- Exact helper/module filenames and whether the small path adapters expose a struct or plain functions.
- Whether canonical fixture writers require an explicit `--update-fixtures` flag in addition to the named regeneration command.
- Exact failure-message prose, provided it names the dataset, resolved path, repository-only status, and recovery action.
- Exact Dialyzer PLT cache directory, ignore-ceiling constant location, CI timeout, and number of plans, provided D-22 through D-30 remain true.
- Whether a short README inside `test/fixtures/operator_surface/` documents ownership and regeneration. A concise README is preferred if it prevents future mixing of immutable and generated data.

### Deferred Ideas (OUT OF SCOPE)

- Public planning-vocabulary cleanup and `@moduledoc false` treatment for maintainer-only critic tasks remain Phase 200 / SURFACE scope.
- Structural/layering repairs surfaced by Dialyzer that cannot be made narrowly without architecture changes remain Phase 203 scope, represented meanwhile only by exact justified suppressions under the Phase 199 ceiling.
- The example application's qualified-query/search-path wart remains deferred under the existing no-Tier-A-regeneration constraint.
- No UI, design-system, product, or new consumer-API capability was added; discussion stayed within Phase 199.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DECOUPLE-01 | `mix ci.all` passes with `.planning/` renamed away, proving no gate reads the planning directory. | Source-anchored edge adapters, a zero-literal executable sweep, and a disposable-clone end-to-end proof. |
| DECOUPLE-02 | All five load-bearing datasets live under `test/fixtures/`, moved with `git mv`, with every reader updated in the same commit and none of them entering the Hex tarball. | Atomic move topology, SHA-256 manifest method, non-vacuity contracts, and Hex unpack inspection. |
| DECOUPLE-03 | Dead planning artifacts are removed with `git rm` and no register or doc cites a path that no longer exists. | Candidate history inventory, citation-repair pattern, and post-delete reference sweep. |
| DECOUPLE-04 | The repository root contains no one-off migration or patch scripts, and the test assertion one of them silently disabled is enabled and passing. | Root-script inventory and the exact disabled README assertion location. |
| DECOUPLE-05 | A fresh clone plus `mix deps.get` leaves `git status` clean — generated artifacts, crash dumps, build tarballs and e2e artifacts are all ignored. | Producer-owned ignore patterns and a disposable-clone exact-status protocol. |
| DECOUPLE-06 | `mix format --check-formatted` covers `bench/`, `scripts/`, and the example app, not only `lib/`, `test/` and `config/`. | Mix formatter subdirectory rules and current formatter gaps. |
| DECOUPLE-07 | `mix dialyzer` runs as part of `ci.all` with all optional dependencies in the PLT, and its documented cold-build cost is measured rather than estimated. | Dialyxir configuration, cache-stage architecture, CI measurement protocol, and roster integration map. |
| DECOUPLE-08 | Dialyzer's ignore file contains only specific, individually-commented entries under a committed ceiling that can only be lowered. | Strict ignore-file syntax, comment-aware contract test, unused-filter enforcement, and positive controls. |
</phase_requirements>

## Summary

Phase 199 should be planned as four coupled proof systems, not as a cleanup grab bag: repository-owned evidence, deletion/citation integrity, clean-checkout/formatter coverage, and a blocking Dialyzer ratchet. The current tree has 366 tracked scorecard JSON files, 54 tracked ARIA YAML files, four tracked golden-tree entries, one refute manifest, one critic-score skeleton, and one ledger; 30 executable/configuration files contain the old evidence vocabulary. [VERIFIED: repository `git ls-files` and `rg` inventory, 2026-09-10]

The fixture move is the highest atomicity boundary. `MechanicalChecker` currently defaults to `".planning/scorecards"` and `".planning/design-system-ledger.json"`, accepts an empty or absent directory as success, and loads floors implicitly; Mix tasks and TypeScript readers likewise embed planning paths. The move must therefore change the contract, not merely strings: pure library code receives corpus data explicitly, repository adapters resolve stable roots, required evidence fails non-vacuously, and writers validate containment and root separation. [VERIFIED: `lib/threadline/operator_surface/mechanical_checker.ex:67-99,138-169`; `lib/mix/tasks/critic.measure.ex:46-68,115-141`; `examples/threadline_phoenix/e2e/critic/run.ts:38-42`; `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts:20-28`]

Dialyzer adoption needs two plans or two waves. First add Dialyxir, build the full optional-dependency PLT, capture the exact warning set, fix narrow defects, approve only irreducible strict ignores, and commit the resulting ceiling. Then wire the stable CI job and obtain two real measurements: a first exact-key cache miss and an exact-key rerun/cache hit. The finding count, initial ceiling, timeout, cold time, hit time, and peak memory do not exist yet and must not be guessed. [ASSUMED]

**Primary recommendation:** Land five plans in order: (1) atomic fixture contract/move, (2) deletion plus citation repair, (3) ignore/formatter/fresh-clone hygiene, (4) Dialyxir baseline and strict triage, and (5) CI cache/measurement/documentation plus the final `.planning/`-absent `mix ci.all` proof. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Immutable evidence ownership | Test / repository tooling | CI | Evidence is test-owned and excluded from the shipped package; CI reads it through repository adapters. [VERIFIED: `mix.exs:332-342`] |
| Mechanical evaluation | Pure library code | ExUnit edge | `MechanicalChecker` computes in memory, but filesystem discovery belongs at the test/task edge. [VERIFIED: `lib/threadline/operator_surface/mechanical_checker.ex:92-102,171-177`] |
| Fixture regeneration | Maintainer Mix task / Playwright edge | Test fixture tree | Writers are repository-only commands; ordinary tests remain readers. [VERIFIED: `lib/mix/tasks/critic.synth.ex:38-97`; `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts:107-110`] |
| TypeScript evidence paths | E2E tooling | Playwright tests | A shared ESM path module anchored at `import.meta.url` should own fixture/output roots. [VERIFIED: existing ESM configuration is `"type": "module"` in `examples/threadline_phoenix/e2e/package.json:1-5`; adapter choice is locked by D-09] |
| Fixture containment | Repository edge adapters | Filesystem | Override values and IDs are untrusted path material and must be normalized before IO. [CITED: https://hexdocs.pm/elixir/1.15.7/Path.html#safe_relative_to/2] |
| Dialyzer analysis | Mix quality gate | GitHub Actions cache | Local and CI invoke the same blocking alias; CI owns exact-toolchain PLT reuse and measurement. [VERIFIED: current alias chain is centralized in `mix.exs:87-157`; CI aggregate extension point is `.github/workflows/ci.yml:753-768`] |
| Hex contents | Package build | CI contract | `package.files` is the inclusion boundary and unpack inspection is the release proof. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |

## Project Constraints (from CLAUDE.md)

- Preserve the three-layer architecture and do not move repository fixture resolution into capture, semantics, or exploration runtime behavior. [VERIFIED: `CLAUDE.md:10-18`]
- Use the canonical commands `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`; contributor docs and CI cite named entrypoints. [VERIFIED: `CLAUDE.md:34-48`]
- Keep CI job IDs stable; expensive-job path filtering, if ever used, must still execute on `main`; doc contracts change with docs. [VERIFIED: `CLAUDE.md:50-57`]
- Do not change capture/query/auth semantics, product behavior, UI structure/layout/visuals, or the Elixir/OTP floor in this phase. [VERIFIED: `.planning/ROADMAP.md:56-67,471-493`]
- Use positional arguments if any `gsd-sdk query state.begin-phase` call is required. [VERIFIED: `CLAUDE.md:65-68`]

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Current CI: `1.17.3`; supported floor `~> 1.15` | Formatter, ExUnit, Mix aliases, path APIs | Existing project contract; no floor bump. The source says verbatim `elixir: "~> 1.15"`. [VERIFIED: `mix.exs:36-41`; current lane quoted below from `.github/workflows/ci.yml:175-179`] |
| Erlang/OTP | Current CI: `27.0`; floor lane: `26` | Dialyzer runtime and PLT identity | PLTs are toolchain-specific; CI already pins both lanes. [VERIFIED: `.github/workflows/ci.yml:170-179`] |
| ExUnit | Built into the pinned Elixir toolchain | Contract, positive-control, and fixture tests | Existing test framework; no package is needed. [VERIFIED: `test/threadline/operator_surface/mechanical_checker_test.exs:1-4`] |
| Dialyxir | `~> 1.4` (registry latest observed `1.4.8`, published 2026-09-05) | Mix interface to Dialyzer, PLT management, strict ignore formatting | Official project installation contract is `{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}`. [CITED: https://github.com/jeremyjh/dialyxir#installation] [VERIFIED: `mix hex.info dialyxir`, 2026-09-10] |
| Node.js | CI `22` | ESM path adapters and Playwright tooling | Existing CI lane; no Node change. [VERIFIED: `.github/workflows/ci.yml:332-336`] |
| Playwright | Locked package `1.60.0` | Capture/regeneration and e2e proof | Existing lockfile version; no upgrade in Phase 199. [VERIFIED: `examples/threadline_phoenix/e2e/package-lock.json:491-493,602-604`] |

The exact in-repo current-lane values are quoted verbatim: `elixir: "1.17.3"`, `otp: "27"`, `pg: "16"`, `runner: "ubuntu-24.04"`. [VERIFIED: `.github/workflows/ci.yml:175-179`]

The optional PLT additions are quoted verbatim from the dependency source of truth: `:phoenix`, `:phoenix_live_view`, `:phoenix_html`, `:phoenix_pubsub`, `:oban`, `:ex_aws`, `:ex_aws_s3`, `:hackney`, and `:sweet_xml`; add `:mix` and `:ex_unit` as the tooling applications required by D-24. [VERIFIED: `mix.exs:72-80`]

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `Path.safe_relative_to/2` | Available since Elixir 1.14 | Reject absolute paths, `..` escape, and symlink escape from a trusted root | Every Elixir override or ID-derived filesystem path. [CITED: https://hexdocs.pm/elixir/1.15.7/Path.html#safe_relative_to/2] |
| `Code.string_to_quoted_with_comments/2` | Available since Elixir 1.13 | Parse `.dialyzer_ignore.exs` while retaining comment line metadata | Ignore-file contract test. [CITED: https://hexdocs.pm/elixir/1.15/Code.html#string_to_quoted_with_comments/2] |
| Node `path.relative` plus `realpathSync` | Built in | Lexical containment plus symlink-aware canonicalization | TypeScript reader/writer boundaries. The `realpathSync` addition is necessary because lexical `path.relative` alone cannot prove a symlink stays under the root. [ASSUMED] |
| `mix hex.build --unpack` | Hex 2.5.1 docs | Inspect actual package contents | Fixture-exclusion proof. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |
| `/usr/bin/time -v` | Ubuntu runner utility | Record wall time and peak RSS separately for PLT build and analysis | CI cold/hit measurement job. [ASSUMED] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Test-owned fixtures | `priv/` | Rejected by D-01/D-07 because repository-only evidence must not enter the runtime package. |
| Explicit edge adapters | Application env or compile-time config | Rejected by D-08; would make a repository concern global runtime configuration. |
| Strict ignore tuples | Regex, file-wide, or warning-class ignores | Rejected by D-26; those shapes suppress future unrelated warnings. |
| Separate PLT restore/build/save/analyze | One `mix dialyzer` step behind `actions/cache` | Rejected by D-29 because an analysis failure can prevent saving a correctly built PLT and destroy the next-run speedup. |

**Installation:**

```elixir
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
```

This exact dependency shape is the Dialyxir project's documented installation form. [CITED: https://github.com/jeremyjh/dialyxir#installation]

## Package Legitimacy Audit

The GSD legitimacy seam was invoked and rejected `hex` because it currently accepts only `npm`, `pypi`, or `crates`; therefore it cannot emit an `OK/SUS/SLOP` verdict for a Hex package. [VERIFIED: `gsd-tools query package-legitimacy check --ecosystem hex dialyxir` output, 2026-09-10]

| Package | Registry | Age / release | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|---------------|-----------|-------------|---------|-------------|
| `dialyxir` | Hex | Latest observed `1.4.8`, 2026-09-05 | 202,440 last 7 days; 90,996,931 all time | `github.com/jeremyjh/dialyxir` | Not scored by GSD seam (Hex unsupported) | Approved from official project docs plus Hex registry; pin `~> 1.4`. [VERIFIED: `mix hex.info dialyxir`, 2026-09-10] [CITED: https://github.com/jeremyjh/dialyxir] |

**Packages removed due to `[SLOP]` verdict:** none; no verdict was available for Hex. [VERIFIED: legitimacy command output above]

**Packages flagged as suspicious `[SUS]`:** none; no verdict was available for Hex. [VERIFIED: legitimacy command output above]

## Architecture Patterns

### System Architecture Diagram

```text
Committed evidence under test/fixtures/operator_surface/
  ├─ ledger + scorecards + golden + refute (immutable inputs)
  └─ critic-scores/.gitkeep (generated-output root skeleton)
                 │
                 ├── ExUnit test helper ──► explicit paths/data ──► pure checker
                 ├── Mix task adapter ────► explicit paths ──────► maintainer reader/writer
                 ├── ESM path adapter ────► explicit paths ──────► critic + Playwright tools
                 └── CI shell variables ──► exact roots ─────────► non-vacuity/drift checks
                                      │
                         containment + input/output separation
                                      │
                         pass / actionable hard failure

Source tree + full optional dependency graph
                 │
      PLT restore ─► PLT build on miss ─► PLT save ─► blocking analysis
                 │                                      │
                 └──────── exact toolchain/cache key ────┘
                                                        │
                                               ci-required aggregate
```

This split keeps filesystem ownership at repository execution edges and keeps shipped computation independent of files excluded from Hex. [VERIFIED: the current package inclusion allowlist is quoted verbatim as `~w(lib priv/fonts guides brandbook/favicon.svg .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)` in `mix.exs:340-342`]

### Recommended Project Structure

```text
test/
├── fixtures/
│   └── operator_surface/
│       ├── README.md                    # ownership, immutable/generated split, commands
│       ├── design-system-ledger.json   # immutable committed evidence
│       ├── scorecards/                 # immutable JSON + ARIA YAML
│       ├── golden/                     # reviewed/synthetic oracle inputs
│       ├── refute/                     # committed refute manifest
│       └── critic-scores/               # .gitkeep + ignored local outputs
└── support/
    └── operator_surface_fixtures.ex     # test-only explicit path adapter

lib/mix/tasks/
├── critic.measure.ex                    # repository-only Mix edge
└── critic.synth.ex                      # canonical regeneration edge

examples/threadline_phoenix/e2e/
├── support/operator-surface-paths.ts    # ESM source-anchored roots + containment
├── critic/                              # imports the shared adapter
└── tests/                               # imports the shared adapter

.dialyzer/                               # local/cache PLTs only; not in Hex allowlist
.dialyzer_ignore.exs
```

The helper filenames are discretionary; the ownership boundaries and exact fixture root are locked. [ASSUMED]

### Pattern 1: Explicit Evidence Inputs, Repository Defaults at Edges

**What:** Change `MechanicalChecker.run/1` so the committed-corpus path and mechanical floors are required explicit inputs; let test support and Mix tasks discover repository defaults. [VERIFIED: the current hidden defaults are `@scorecards_dir ".planning/scorecards"` and `@ledger_path ".planning/design-system-ledger.json"` in `lib/threadline/operator_surface/mechanical_checker.ex:67-68`, and `run/1` consumes them at lines 92-95]

**When to use:** Any pure or shipped module that needs filesystem-backed evidence.

**Example:**

```elixir
fixture_root = Threadline.Test.OperatorSurfaceFixtures.root!()
floors = fixture_root |> Path.join("design-system-ledger.json") |> File.read!() |> Jason.decode!() |> Map.fetch!("mechanical_floors")

MechanicalChecker.run(
  scorecard_dir: Path.join(fixture_root, "scorecards"),
  mechanical_floors: floors
)
```

The fixture values in this example are quoted from D-01; the adapter name is discretionary. [ASSUMED]

### Pattern 2: Stable Source Anchors

**What:** For Mix tasks, derive `repo_root = Mix.Project.project_file() |> Path.dirname()` and validate that a project file exists; for ESM, derive from `dirname(fileURLToPath(import.meta.url))`. [CITED: https://hexdocs.pm/elixir/Mix.Project.html#project_file/0]

**When to use:** Maintainer commands that promise deterministic defaults independent of caller CWD.

**Example:**

```elixir
defp repo_root! do
  case Mix.Project.project_file() do
    nil -> Mix.raise("repository-only task: no Mix project file is loaded")
    project_file -> project_file |> Path.dirname() |> Path.expand()
  end
end
```

`Mix.Project.project_file/0` returns the current project's defining file or `nil`. [CITED: https://hexdocs.pm/elixir/Mix.Project.html#project_file/0]

### Pattern 3: Non-vacuous Read Contracts

**What:** Validate in this order: resolved root exists; required named files exist; JSON/YAML parses; scorecard glob contains at least one eligible committed JSON; cross-dataset references resolve; then evaluate. Each failure includes the dataset, absolute path, repository-only status, and one recovery command. [VERIFIED: current `list_scorecards/1` converts every `File.ls/1` error to `[]` and `run/1` consequently returns `{:ok, []}` in `lib/threadline/operator_surface/mechanical_checker.ex:96-101,138-161`; D-05 requires the opposite]

**When to use:** Every committed ledger, scorecard, synthetic, and refute gate. The human queue is the only intentionally-empty exception under D-05.

### Pattern 4: Atomic Writers and Root Separation

**What:** Canonical writers encode to a sibling temporary file, flush/close, rename over the target, then print the exact review command. Noncanonical writers reject immutable roots; generated output must resolve under `critic-scores/` and outside every immutable root. [VERIFIED: current synth writes directly with `File.write!(@out, ...)` at `lib/mix/tasks/critic.synth.ex:86-87`, and critic measure writes the ledger directly at `lib/mix/tasks/critic.measure.ex:64-69`; both need the D-04 atomic-write contract]

**When to use:** Synthetic oracle regeneration, ledger splice, labeling reconciliation, capture scorecard regeneration, critic outputs, and report outputs.

### Pattern 5: Strict Ignore Ratchet

**What:** Keep `.dialyzer_ignore.exs` a literal list of exact `{file, warning_description}` tuples. A contract test parses AST plus comments, rejects all other node shapes, requires the immediately preceding comment to contain an irreducibility reason and removal trigger, rejects duplicates, asserts count `<= ceiling`, and runs Dialyxir with unused-filter checking. [CITED: https://github.com/jeremyjh/dialyxir#elixir-term-format]

**When to use:** Only after exact triage has proved a warning cannot be narrowly fixed before Phase 203.

Use `mix dialyzer --format ignore_file_strict` only as a candidate generator; never paste the whole output as an approved baseline. The official strict formatter emits `{file, warning_description}` entries, whereas the non-strict formatter groups by file and warning type. [CITED: https://github.com/jeremyjh/dialyxir#elixir-term-format]

### Pattern 6: Save a Valid PLT Before Analysis

**What:** CI stages are restore → dependency fetch/compile → conditional `mix dialyzer --plt` on cache miss → cache save → timed `mix dialyzer --no-check` analysis. Exact-key hits skip the build and run the same timed analysis. [CITED: https://github.com/jeremyjh/dialyxir#continuous-integration]

**When to use:** The unconditional `verify-dialyzer` job on the current lane.

Recommended cache identity: runner label + exact OTP + exact Elixir + `hashFiles('mix.lock')` + `hashFiles('mix.exs')`; restore prefixes stop before dependency/config hashes but never before runner/OTP/Elixir. This exact identity is locked by D-29 and extends the existing cache precedent. [VERIFIED: `.github/workflows/ci.yml:65-99`]

### Anti-Patterns to Avoid

- **Search-and-replace only:** It preserves hidden default IO and vacuous success. Replace the contract and centralize edge roots. [VERIFIED: `lib/threadline/operator_surface/mechanical_checker.ex:67-99,138-169`]
- **`process.cwd()` for E2E repository paths:** Five capture/stress specs currently derive paths from caller CWD; D-09 requires `import.meta.url`. [VERIFIED: `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts:20-28`; repository `rg` inventory]
- **Lexical prefix checks:** `/root/scorecards-evil` passes a string-prefix test; symlinks can escape lexical roots. Use safe relative/canonicalized containment. [CITED: https://hexdocs.pm/elixir/1.15.7/Path.html#safe_relative_to/2]
- **Generated warning snapshot:** Broad output copied into the ignore file hides later warnings and violates D-26/D-27. [CITED: https://github.com/jeremyjh/dialyxir#elixir-term-format]
- **Parent formatter inputs overlapping child subdirectories:** Mix documents selection as unspecified. [CITED: https://mix.hexdocs.pm/1.13.0/Mix.Tasks.Format.html]
- **Using `.gitignore` to sanitize one workstation:** D-19 requires a fresh-clone probe and preserves `.tool-versions`/operator scratch as local state. [VERIFIED: current worktree has untracked `.tool-versions`, `.planning/agent-history.json`, and `.planning/state.json`; `git status --short`, 2026-09-10]
- **Changing the full-build Dialyzer gate to no-optional:** The project intentionally compiles two different module sets; no-optional remains a separate compile lane. [VERIFIED: `mix.exs:121-143`; optional dependencies are quoted at `mix.exs:72-80`]

## Component Responsibilities

| Component | Responsibility | Must Not Own |
|-----------|----------------|--------------|
| `Threadline.OperatorSurface.MechanicalChecker` | Pure evaluation of supplied scorecards/floors | Repository discovery, `.planning`, `test/fixtures`, Mix project lookup, Application env |
| Test support adapter | Exact committed fixture root and named dataset paths for ExUnit | Runtime public API |
| Mix task path adapter | Project-file anchor, CLI override precedence/validation, repository-only errors, atomic writes | Ambient env lookup as primary configuration |
| TypeScript path adapter | `import.meta.url` anchor, immutable/generated roots, containment and alias rejection | `process.cwd()` assumptions |
| CI shell | Exact fixture variables, non-vacuity, byte-drift and package checks | A second independent dataset vocabulary |
| Ignore contract test | Syntax/comment/ceiling/duplicate/broad-filter/unused-filter enforcement | Deciding which warnings are acceptable |
| `verify-dialyzer` job | Exact current toolchain, PLT cache, measurement, blocking analysis | Minimum-lane analysis or optional-dependency removal |

All responsibility assignments implement D-07 through D-12 and D-22 through D-30. [VERIFIED: user constraints]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Elixir traversal containment | String prefix or custom `..` stripping | `Path.safe_relative_to/2` | It rejects absolute, above-root, and symlink escapes. [CITED: https://hexdocs.pm/elixir/1.15.7/Path.html#safe_relative_to/2] |
| Dialyzer task/PLT lifecycle | Shelling directly to Erlang `dialyzer` | Dialyxir | It supplies Mix compilation, project PLTs, formatters, filters, and unused-filter checks. [CITED: https://github.com/jeremyjh/dialyxir] |
| Ignore extraction | Ad hoc warning-output regex | Dialyxir `ignore_file_strict` formatter plus repository approval contract | The official formatter emits granular file/description tuples. [CITED: https://github.com/jeremyjh/dialyxir#elixir-term-format] |
| Ignore comment parsing | Fragile line counting alone | `Code.string_to_quoted_with_comments/2` plus AST shape validation | The built-in parser returns AST and comment locations. [CITED: https://hexdocs.pm/elixir/1.15/Code.html#string_to_quoted_with_comments/2] |
| Hex fixture exclusion | Trusting `.gitignore` | Explicit `package.files` plus `mix hex.build --unpack` inspection | Hex package contents follow package configuration, not the conceptual ownership of a directory. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |
| Fixture copies | Per-test copies or regenerated baselines | One domain-scoped committed corpus | Cross-dataset IDs and floors must remain joined; D-01 forbids vocabulary forks. |

**Key insight:** The hard problem is maintaining one evidence identity across five readers and three execution environments; custom path discovery or duplicated fixtures multiplies the number of authorities and makes a green gate less meaningful. [ASSUMED]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Tracked filesystem corpus: 366 JSON + 54 ARIA scorecards, four golden-tree entries, one refute file, one ledger, one critic-score skeleton. Local `critic-scores/` currently occupies about 1.7 MB and is generated output. [VERIFIED: `git ls-files`, extension count, and `du -sh`, 2026-09-10] | Data migration: `git mv` every tracked entry and preserve relative names/bytes. Code edit: redirect all readers/writers. Local generated critic scores may move or be regenerated; do not commit them. |
| Live service config | None found: repository workflows, Docker configuration, and scripts contain file paths, but no external service configuration was found that stores these fixture roots. [VERIFIED: repository `rg` over `.github/`, `scripts/`, `bin/`, Compose files, and example tooling, 2026-09-10] | None. CI YAML path references are source edits, not live-service mutations. |
| OS-registered state | None found in `launchctl` or running Docker container names for Threadline/critic/operator tooling. [VERIFIED: local `launchctl list` and `docker ps` probes, 2026-09-10] | None. |
| Secrets/env vars | No environment variable name containing `THREADLINE`, `CRITIC`, `FIXTURE`, or `ANTHROPIC` was present in the local environment probe. The code's `ANTHROPIC_API_KEY` controls paid scoring, not fixture location. [VERIFIED: environment-name-only probe and `mix.exs:259-269`] | No rename. Do not introduce a fixture-root env contract. |
| Build artifacts / installed packages | `examples/threadline_phoenix/e2e/artifacts/` occupies about 625 MB locally; `_build`, `deps`, Playwright reports, Hex tarballs, crash dumps, and future PLTs are generated. [VERIFIED: `du -sh` and `.gitignore:1-69`, 2026-09-10] | Ignore exact producer roots; preserve snapshot baselines; place PLTs outside `_build` and outside package allowlist. Run the clean-clone proof. |

The canonical post-migration question is answered: after repository paths change, no database, external service, OS registration, or secret key needs migration; only tracked corpus files and local generated filesystem outputs carry the old location. [VERIFIED: inventory above]

## Common Pitfalls

### Pitfall 1: Vacuous Green on Missing Evidence

**What goes wrong:** A missing directory becomes an empty list and `{:ok, []}`. [VERIFIED: `lib/threadline/operator_surface/mechanical_checker.ex:96-101,138-161`]

**Why it happens:** Filesystem discovery and evaluation share one permissive function.

**How to avoid:** Separate `load_required_corpus!/1` from pure evaluation and test missing root, missing required file, malformed JSON/YAML, and zero eligible scorecards.

**Warning signs:** Tests named “empty/absent ... returns `{:ok, []}`”; the current test contains that exact behavior at `test/threadline/operator_surface/mechanical_checker_test.exs:117-123`. [VERIFIED: same file/lines]

### Pitfall 2: Stable Root, Unstable Caller

**What goes wrong:** Commands pass from the e2e directory but fail from root, nested directories, worktrees, or direct `tsx` execution.

**Why it happens:** Capture specs use `resolve(process.cwd(), "../../..")`, while critic modules mostly use `import.meta.url`. [VERIFIED: `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts:20-24`; `examples/threadline_phoenix/e2e/critic/run.ts:38-42`]

**How to avoid:** One ESM adapter anchored at its own module URL; all test and critic modules import it.

**Warning signs:** Any `process.cwd()` in a repository evidence path after the migration.

### Pitfall 3: Writer Escapes or Aliases Immutable Inputs

**What goes wrong:** A crafted cell ID, lens, dimension, or override writes outside `critic-scores/`, or an output override points at committed scorecards/golden/refute evidence.

**Why it happens:** `resolve(root, userSegment)` normalizes traversal but does not itself assert containment.

**How to avoid:** Canonicalize the trusted root, compute a safe relative path, reject absolute/`..`/symlink escape, and compare canonical roots to reject aliases. [CITED: https://hexdocs.pm/elixir/1.15.7/Path.html#safe_relative_to/2]

**Warning signs:** `startsWith(root)` or `String.starts_with?(path, root)` containment.

### Pitfall 4: Fixture Move Changes Evidence

**What goes wrong:** Formatter, JSON encoder, line-ending normalization, or regeneration changes bytes during relocation.

**Why it happens:** Copy/rewrite is used instead of `git mv`, or a canonical writer runs during the move.

**How to avoid:** Generate a sorted manifest keyed by dataset-relative path before the move; after `git mv`, regenerate with the new prefix stripped and require an exact diff. Record both manifests/digests in Phase 199 evidence, but never make a gate read that planning artifact. [ASSUMED]

**Warning signs:** Content diffs inside renamed files or changed scorecard counts.

### Pitfall 5: Package Exclusion Is Inferred, Not Proved

**What goes wrong:** Test evidence enters the Hex tarball despite living under a test-looking path, or a future allowlist broadening includes it.

**Why it happens:** The plan checks `mix.exs` text but not the built artifact.

**How to avoid:** Keep the explicit allowlist and inspect the unpacked tarball for zero `test/fixtures/operator_surface` entries. Hex documents `--unpack` for this purpose. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html]

**Warning signs:** Only asserting that `test` is absent from the `package.files` string.

### Pitfall 6: Formatter Ownership Overlap

**What goes wrong:** Parent and child formatter configs both match a child file, so rule selection is unspecified.

**Why it happens:** Root inputs expand to `bench/**` or `examples/**` while also declaring those directories as subdirectories.

**How to avoid:** Root `subdirectories` owns `bench` and `examples/threadline_phoenix`; root inputs add only `scripts/**/*.{ex,exs}` outside them. Extend child inputs locally. [CITED: https://mix.hexdocs.pm/1.13.0/Mix.Tasks.Format.html]

**Warning signs:** The same path matches both parent `inputs` and a child `.formatter.exs`.

### Pitfall 7: PLT Cache Is Lost on the First Real Warning

**What goes wrong:** The expensive PLT build succeeds, analysis finds a warning and fails, and the post-job cache never saves; every retry is cold.

**Why it happens:** One combined `mix dialyzer` step precedes a monolithic cache save.

**How to avoid:** Build on miss, save immediately, then analyze. D-29 explicitly requires the separation.

**Warning signs:** `actions/cache@v4` wrapped around a single analysis step or cache save ordered after analysis.

### Pitfall 8: The Ratchet Counts Entries but Does Not Validate Their Shape

**What goes wrong:** A contributor stays below the ceiling by replacing several strict tuples with one regex/file-wide tuple.

**Why it happens:** Only `length(ignore_entries) <= ceiling` is asserted.

**How to avoid:** Assert AST shape, comments, uniqueness, no broad forms, count, and unused filters; positive-control an extra entry and a broadened entry.

**Warning signs:** `Code.eval_file` plus a count assertion with no source/comment inspection.

### Pitfall 9: “Fresh Clone” Is the Maintainer's Dirty Tree

**What goes wrong:** Shared ignores are expanded until the current workstation looks clean, hiding unrelated source or reviewed artifacts.

**Why it happens:** The proof runs in place.

**How to avoid:** Clone committed HEAD into a disposable directory, run `mix deps.get --check-locked`, then require exact empty `git status --porcelain=v1 --untracked-files=all`. [VERIFIED: D-19]

**Warning signs:** New ignores for `.tool-versions`, `.planning/state.json`, or personal scratch solely because they are locally untracked.

### Pitfall 10: Deletion Falsifies Historical Inputs

**What goes wrong:** Removing `.planning/HANDOFF.json` leaves `198-41-PLAN.md` looking like it can still read a live file, or rewriting the plan pretends it never did.

**Why it happens:** Citation cleanup is treated as string deletion.

**How to avoid:** Add a minimal historical note to the plan and point present-day readers to its durable summary/ratification evidence. [VERIFIED: `.planning/phases/198-green-bringup/198-41-PLAN.md:90,103`]

**Warning signs:** A post-delete `rg` hit without a supersession annotation, or no recovery SHA in the removal summary.

### Pitfall 11: Timing Includes Dependency Download

**What goes wrong:** The documented “PLT cost” is actually dependency/network cost and produces a meaningless timeout.

**Why it happens:** The timer wraps the whole job.

**How to avoid:** Time PLT build and analysis steps separately after dependencies; record cache-hit output separately and derive timeout from the cold analyzer sequence with headroom. [VERIFIED: D-30]

## Code Examples

### Dialyxir Project Configuration

```elixir
dialyzer: [
  plt_local_path: ".dialyzer",
  plt_core_path: ".dialyzer",
  plt_add_apps: [
    :mix,
    :ex_unit,
    :phoenix,
    :phoenix_live_view,
    :phoenix_html,
    :phoenix_pubsub,
    :oban,
    :ex_aws,
    :ex_aws_s3,
    :hackney,
    :sweet_xml
  ],
  flags: [:unmatched_returns, :extra_return],
  ignore_warnings: ".dialyzer_ignore.exs",
  list_unused_filters: true
]
```

Dialyxir documents `plt_add_apps`, additional `flags`, term ignore files, and `list_unused_filters`; it retains `:unknown` unless `remove_defaults: [:unknown]` is explicitly set, which this phase must not do. [CITED: https://github.com/jeremyjh/dialyxir]

Every application value in the example is quoted verbatim from D-24 and `mix.exs:72-80`; the `.dialyzer` directory is a discretionary recommendation. [VERIFIED: `mix.exs:72-80`] [ASSUMED]

### Strict Ignore Entry

```elixir
[
  # Irreducible until upstream example/version is fixed; remove when <trigger> is true.
  {"lib/example.ex", "Function example/1 has no local return."}
]
```

The tuple shape is the official strict format; the rationale/removal-trigger rule is Threadline's D-26 addition. [CITED: https://github.com/jeremyjh/dialyxir#elixir-term-format]

### Elixir Containment

```elixir
case Path.safe_relative_to(candidate, trusted_root) do
  {:ok, relative} -> Path.join(trusted_root, relative)
  :error -> Mix.raise("path escapes trusted fixture root: #{Path.expand(candidate)}")
end
```

`Path.safe_relative_to/2` rejects absolute paths, traversal above the trusted root, and symlinks that point above it. [CITED: https://hexdocs.pm/elixir/1.15.7/Path.html#safe_relative_to/2]

### Formatter Topology

```elixir
[
  subdirectories: ["bench", "examples/threadline_phoenix"],
  inputs: [
    "{mix,.formatter,.credo}.exs",
    "{config,lib,test}/**/*.{ex,exs}",
    "scripts/**/*.{ex,exs}"
  ]
]
```

Child configurations remain independent; root inputs intentionally do not overlap child directories. [CITED: https://mix.hexdocs.pm/1.13.0/Mix.Tasks.Format.html]

The child paths and root scripts pattern are quoted from D-20. [VERIFIED: user constraint D-20]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Dialyxir broad `{file, warning_type}` ignore generation | `--format ignore_file_strict` emits `{file, warning_description}` | Available in current 1.4 docs | Enables one-warning suppressions and a meaningful ratchet. [CITED: https://github.com/jeremyjh/dialyxir#elixir-term-format] |
| Project PLT in `_build` | `plt_local_path` outside `_build`, cached in CI | Current Dialyxir guidance | Clean builds can reuse analysis state without `_build` cache coupling. [CITED: https://github.com/jeremyjh/dialyxir#continuous-integration] |
| One formatter config matching everything | Parent `subdirectories` with independent child `.formatter.exs` | Supported by current Mix docs | Preserves child import rules and removes ambiguous ownership. [CITED: https://mix.hexdocs.pm/1.13.0/Mix.Tasks.Format.html] |
| Planning-owned test evidence | Test-owned committed corpus with explicit readers | Phase 199 locked design | `.planning/` remains history but is not executable input. [VERIFIED: D-01 through D-09] |

**Deprecated/outdated:**

- `plt_file` is deprecated for local use; prefer `plt_local_path`. [CITED: https://github.com/jeremyjh/dialyxir#plt]
- Broad ignore generators are valid Dialyxir features but are forbidden for this project's ratchet. [CITED: https://github.com/jeremyjh/dialyxir#elixir-term-format] [VERIFIED: D-26]
- CWD-relative evidence paths are incompatible with the locked worktree/nested-directory contract. [VERIFIED: D-09]

## Removal Inventory

| Candidate | Purpose / last meaningful use | Superseding evidence | Recovery identity |
|-----------|-------------------------------|----------------------|-------------------|
| `.planning/ROADMAP.md.bak` | Stale v1.21 roadmap backup; last changed 2026-05-24. [VERIFIED: file read and `git log --follow`, 2026-09-10] | Current `.planning/ROADMAP.md` and archived milestone records. [VERIFIED: repository paths] | Last commit `cd6cd4b8442bea5ad3e67739fa93741523d6187f`. [VERIFIED: git log] |
| `.planning/HANDOFF.json` | Paused direct-work handoff last changed 2026-08-30; historical Plan 198-41 cites it. [VERIFIED: `.planning/HANDOFF.json:1-18`; `198-41-PLAN.md:90,103`] | `198-41-SUMMARY.md` and later Phase-198 terminal evidence. [VERIFIED: files exist] | Last commit `60f75f56d32b1e421f8d9817b397e1bd7604acf4`. [VERIFIED: git log] |
| `update_roadmap.rb` | Nine-line one-off replacing the first `**Plans**: TBD`; last changed 2026-05-24. [VERIFIED: `update_roadmap.rb:1-9`] | Current roadmap phase records. [VERIFIED: `.planning/ROADMAP.md`] | Last commit `cd6cd4b8442bea5ad3e67739fa93741523d6187f`. [VERIFIED: git log] |
| `fix_tests.exs` | One-off multi-file patch that commented out a README assertion; last changed 2026-05-29. [VERIFIED: `fix_tests.exs:1-20`] | Current source plus restored `readme_doc_contract_test`; Phase-198 summary already calls it tracked debris. [VERIFIED: `.planning/phases/198-green-bringup/198-04-SUMMARY.md:292`] | Last commit `db94c492003e369b0bd39862fb2e4ba84b6f8b64`. [VERIFIED: git log] |

The disabled assertion is quoted verbatim: `# assert String.contains?(readme, "stays in-tree for now")`. Restore the assertion against README's current canonical compatibility wording, not that obsolete phrase. [VERIFIED: `test/threadline/readme_doc_contract_test.exs:110-125`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Five plans are the least-surprising split. | Summary | Planner may split further to keep the atomic fixture change reviewable. |
| A2 | `.dialyzer/` is the best PLT directory outside `_build` and package allowlists. | Project structure / code example | A different precise root may fit CI permissions better. |
| A3 | Node containment should pair `path.relative` with canonical `realpathSync`. | Supporting stack | Nonexistent-output handling may need parent canonicalization rather than direct realpath. |
| A4 | `/usr/bin/time -v` is present on the exact GitHub-hosted Ubuntu image. | Supporting stack | The measurement step may need GNU `time` installation or a shell timestamp/RSS alternative. |
| A5 | The initial Dialyzer warning count, strict-ignore ceiling, cold/hit duration, memory, and timeout are unknown until execution. | Summary / open questions | The Dialyzer plan must contain a measurement/triage checkpoint and cannot pre-fill values. |
| A6 | A short fixture README and the suggested helper filenames are preferable. | Project structure | Naming may change without affecting locked architecture. |

## Open Questions (RESOLVED)

1. **RESOLVED — What is the exact first full-build Dialyzer warning set?**
   - Plan-backed answer: Plan 199-13 captures the first full-build output before any source edit, records every warning in `199-DIALYZER-TRIAGE.md`, applies narrow correctness fixes, and permits only exact Phase-203-bound suppressions. The warning count is execution-derived and is never guessed or replaced by a broad snapshot.

2. **RESOLVED — What ceiling and timeout should be committed?**
   - Plan-backed answer: Plan 199-13 sets the ceiling to the execution-derived count of individually approved strict entries after triage. Plan 199-14 sets the CI timeout from the authenticated cold-run measurement with documented headroom. Both numbers are evidence-derived during execution and the ceiling is tighten-only thereafter.

3. **RESOLVED — How will the real cache-miss/cache-hit run be triggered?**
   - Plan-backed answer: Plan 199-14 first uses the authenticated GitHub CLI to push the committed topology and trigger a cache-miss run, then reruns the identical commit for the exact-key hit. If authentication or push authority is unavailable, execution creates a blocking human-action checkpoint with the exact branch/workflow commands; after the maintainer action, the executor retrieves both run IDs and records immutable URLs, SHA, hashes, timings, and peak RSS before documentation can pass.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Exact current Elixir | Local baseline parity | ✗ | Required `1.17.3`; installed asdf versions are `1.19.5`/`1.20.2` variants | Use the pinned CI image for authoritative measurement; install exact local version for implementation verification. [VERIFIED: command probe, 2026-09-10] |
| Exact current OTP | Dialyzer PLT identity | ✓ partial | Required `27.0`; installed `27.3.4.15` | CI remains authoritative for D-30. [VERIFIED: command probe and `.github/workflows/ci.yml:175-179`] |
| Node.js | TypeScript/Playwright | ✓ | `22.14.0`; CI major `22` | — [VERIFIED: command probe; `.github/workflows/ci.yml:332-336`] |
| npm | E2E dependencies | ✓ | `11.1.0` | — [VERIFIED: command probe] |
| Docker | Optional exact-image/local services | ✓ | `29.5.2` | GitHub-hosted services for authoritative CI. [VERIFIED: command probe] |
| PostgreSQL client | Local DB probes | ✓ | `14.17` | CI Postgres 16 service for current lane. [VERIFIED: command probe; `.github/workflows/ci.yml:175-191`] |
| Git | moves, deletes, fresh clone | ✓ | `2.41.0` | — [VERIFIED: command probe] |
| Dialyxir | Dialyzer gate | ✗ in project | No `mix.lock` entry | Add official `~> 1.4` dev/test dependency. [VERIFIED: `mix.lock` scan] |

**Missing dependencies with no fallback:** none for planning; exact local Elixir 1.17.3 is needed for parity if the executor does not rely on CI. [ASSUMED]

**Missing dependencies with fallback:** exact current toolchain and Dialyxir baseline can be executed on the pinned CI image after the dependency lands. [ASSUMED]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit from Elixir 1.17.3 current lane; Playwright for E2E path/capture behavior. [VERIFIED: `.github/workflows/ci.yml:175-179,297-382`] |
| Config file | `test/test_helper.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: files exist] |
| Quick run command | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs -x` [ASSUMED] |
| Full suite command | `mix ci.all` [VERIFIED: `mix.exs:138-156`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DECOUPLE-01 | No executable gate reads `.planning/`; full aggregate passes without it | source contract + E2E smoke | targeted zero-literal contract, then disposable clone with `.planning` renamed and `mix ci.all` | ❌ Wave 0 contract; final E2E proof |
| DECOUPLE-02 | Five datasets moved byte-identically and excluded from Hex | fixture + packaging contract | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs -x`; `mix hex.build --unpack` inspection | ❌ Wave 0; existing release artifact tests can be extended |
| DECOUPLE-03 | Removed paths have no active citation | source/doc contract | `mix test test/threadline/removed_artifact_contract_test.exs -x` | ❌ Wave 0 |
| DECOUPLE-04 | Root one-off scripts absent and README assertion restored | doc contract | `mix test test/threadline/readme_doc_contract_test.exs -x` | ✅ extend existing file |
| DECOUPLE-05 | Fresh dependency fetch leaves exact clean status | disposable-clone integration | `mix deps.get --check-locked` then `test -z "$(git status --porcelain=v1 --untracked-files=all)"` | ❌ Wave 0 script/plan proof |
| DECOUPLE-06 | Root formatter delegates to both children and covers scripts | source contract + formatter | `mix format --check-formatted` | ✅ framework; ❌ topology contract |
| DECOUPLE-07 | Full-build Dialyzer blocks locally/CI and PLT lists all apps | source contract + CI | `mix dialyzer --list-unused-filters`; CI `verify-dialyzer` | ❌ Wave 0 |
| DECOUPLE-08 | Strict ignores/comments/ceiling/unused filters cannot broaden | unit + positive control | `mix test test/threadline/dialyzer_ignore_contract_test.exs -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run the one focused contract file changed plus `mix verify.format`. [VERIFIED: project named-entrypoint convention in `CLAUDE.md:34-57`]
- **Per wave merge:** Run `mix verify.test`, the relevant maintainer/E2E command, and `mix dialyzer --list-unused-filters` after Dialyxir lands. [ASSUMED]
- **Phase gate:** Disposable committed-tree clone: run `mix deps.get --check-locked`, assert clean status, rename `.planning/`, run `mix ci.all`, restore/remove via trap, and assert clean status again. Then inspect the unpacked Hex tarball and execute the real CI cold/hit measurements. [ASSUMED]

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs` — dataset presence, parseability, non-vacuity, cross-dataset joins, immutable/generated separation, and zero old executable literals.
- [ ] `test/threadline/operator_surface/mechanical_checker_test.exs` — reverse the current absent-directory success contract; require explicit floors and scorecard input.
- [ ] `test/threadline/dialyzer_ignore_contract_test.exs` — parseability, exact tuple shape, immediate rationale, duplicate/broad-filter rejection, ceiling, positive controls.
- [ ] `test/threadline/removed_artifact_contract_test.exs` — tracked root-script and active-citation absence.
- [ ] Formatter topology contract — root subdirectories plus child-specific input coverage without overlap.
- [ ] Fresh-clone/`.planning`-absent plan proof — use a disposable clone; do not make CI depend on planning artifacts.

Wave 0 tests may be committed red only within an explicitly staged TDD plan; the atomic fixture move itself must not leave main with half-migrated readers. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

ASVS 5.0 is the current standard; its file-path control is V5.3.2, which requires trusted/generated path data or strict validation/sanitization to prevent traversal and file inclusion. [CITED: https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.flat.json]

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| Authentication | no | No auth or identity behavior changes in Phase 199. [VERIFIED: phase boundary] |
| Session management | no | No session state changes. [VERIFIED: phase boundary] |
| Access control | no product change | Maintainer-only commands remain repository-only; no consumer authorization surface is added. [VERIFIED: D-12] |
| V5 File Handling / V5.3.2 File Storage paths | yes | Trusted source anchors, explicit roots, safe-relative/canonical containment, symlink/traversal tests, and immutable/output separation. [CITED: OWASP ASVS 5.0 V5.3.2 URL above] |
| Cryptography | yes, integrity only | Use SHA-256 tooling for before/after byte manifests; do not invent cryptography. [VERIFIED: D-02] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `cell_id`/lens/dimension traversal writes outside output root | Tampering / Information disclosure | Normalize, safe-relative check, canonical root comparison, reject symlinks; positive controls for `../`, absolute paths, and symlink escapes. [CITED: OWASP ASVS 5.0 V5.3.2] |
| Generated output aliases immutable evidence | Tampering | Reject equal/nested canonical roots except the named canonical regeneration command. [VERIFIED: D-11] |
| Missing fixture root yields green gate | Tampering / Repudiation | Required-root/file/count/parse failures with resolved path and recovery command. [VERIFIED: D-05] |
| Stale or cross-toolchain PLT produces misleading analysis | Tampering / Repudiation | Key on runner + exact OTP/Elixir + lock/config hashes; keep `:unknown`; no no-optional analysis. [VERIFIED: D-24, D-25, D-29] |
| Broad ignore suppresses new findings | Tampering / Repudiation | Strict tuple AST contract, comments/removal triggers, ceiling, duplicate checks, unused-filter failure, positive controls. [VERIFIED: D-26, D-27] |
| Test evidence leaks into Hex | Information disclosure / package integrity | Explicit package allowlist plus unpacked-artifact negative assertion. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |

## Recommended Plan Shape

1. **Fixture contract and atomic move:** Add edge adapters, make `MechanicalChecker` explicit/non-vacuous, update all Elixir/TypeScript/CI readers and writers, `git mv` all five roots, compare SHA manifests, run cross-dataset and Hex-exclusion contracts. This is one atomic source/data transition even though it spans many files. [ASSUMED]
2. **Removal and citation repair:** Inventory/recovery table, restore the README assertion with a failing mutation control, add the historical HANDOFF supersession note, `git rm` four candidates, and run zero-consumer/zero-active-citation contracts. [ASSUMED]
3. **Clean clone and formatter topology:** Tighten anchored ignore patterns, ignore the whole generated e2e artifact root while protecting snapshots, root-anchor tarballs/crash outputs as required, configure formatter subdirectories/child inputs, and execute the fresh-clone exact-status proof. [ASSUMED]
4. **Dialyxir baseline and ratchet:** Add dependency/config, build full PLT, seal warning output, fix narrow findings, triage Phase-203 residue, write only approved strict entries, set exact ceiling, and pass ignore positive controls plus unused-filter analysis. [ASSUMED]
5. **CI job, measurements, and final proof:** Add stable `verify-dialyzer`, separate cache stages, extend header/rosters/contracts/`ci.all`, push measurement SHA, record cold miss and hit rerun, derive timeout, update CONTRIBUTING, then run the `.planning`-absent full gate in a disposable clone. [ASSUMED]

Plan 5 depends on Plan 4; Plans 2 and 3 can be reviewed independently after Plan 1, but the final gate waits for all four. [ASSUMED]

## Sources

### Primary (HIGH confidence repository sources)

- `199-CONTEXT.md` — D-01 through D-30, discretion, deferred scope.
- `.planning/REQUIREMENTS.md` — DECOUPLE-01 through DECOUPLE-08.
- `.planning/ROADMAP.md` — dependency spine, invariants, Phase-199 criteria.
- `mix.exs` — dependency graph, aliases, package allowlist, current Dialyzer placeholder.
- `.github/workflows/ci.yml` — exact toolchain, cache precedent, fixture paths, aggregate roster.
- Fixture readers/writers and contract tests listed in CONTEXT.md — current IO semantics and vacuity.

### Secondary (MEDIUM confidence official external docs)

- https://github.com/jeremyjh/dialyxir — installation, PLT, CI cache, defaults, flags, strict ignores, unused filters.
- https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html — package inclusion and unpack inspection.
- https://mix.hexdocs.pm/1.13.0/Mix.Tasks.Format.html — formatter inputs/subdirectories ownership.
- https://hexdocs.pm/elixir/1.15.7/Path.html#safe_relative_to/2 — traversal and symlink-safe relative paths on the supported floor.
- https://hexdocs.pm/elixir/1.15/Code.html#string_to_quoted_with_comments/2 — AST/comment-aware parsing on the supported floor.
- https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.flat.json — current ASVS file-path requirement.

### Tertiary (LOW confidence / execution-dependent)

- Recommended helper filenames, five-plan split, `.dialyzer/` root, GNU time availability, initial warning count, ceiling, timings, memory, and timeout are marked `[ASSUMED]` and must be resolved by implementation measurements.

## Metadata

**Confidence breakdown:**

- Standard stack: MEDIUM — official Dialyxir and Mix docs are current, and the Hex registry reports 1.4.8; the GSD legitimacy seam does not support Hex.
- Architecture: HIGH — derived from locked decisions and direct reads of every major in-repo reader/writer boundary.
- Pitfalls: HIGH for current vacuity/CWD/package/CI topology; MEDIUM for proposed Node symlink implementation details.
- Dialyzer findings and performance: LOW — deliberately unmeasured until the real current-lane run.

**Research date:** 2026-09-10
**Valid until:** 2026-10-10 for architecture; re-check Dialyxir registry/docs at execution because 1.4.8 was published five days before research.
