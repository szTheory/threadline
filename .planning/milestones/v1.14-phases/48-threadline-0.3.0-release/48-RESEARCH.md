# Phase 48: threadline-0.3.0-release - Research

**Researched:** 2026-05-05 [VERIFIED: codebase grep]  
**Domain:** Elixir library release packaging, ExDoc information architecture, and release-surface contract testing for `threadline 0.3.0` [VERIFIED: mix.exs][VERIFIED: CONTRIBUTING.md][VERIFIED: ci.yml]  
**Confidence:** HIGH [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from `.planning/phases/48-threadline-0.3.0-release/48-CONTEXT.md`. [VERIFIED: 48-CONTEXT.md]

### Locked Decisions

### Release Narrative
- **D-01:** Frame `0.3.0` as the **drop-in production adoption release for Phoenix SaaS teams**. Sigra support, the SaaS quickstart, performance baselines, and the incident playbook are supporting proof points, not competing headlines.
- **D-02:** Avoid a feature-bundle story like "Sigra + ops tooling release" as the top-line framing. That is technically true but too ingredient-focused; it undersells the milestone outcome and makes Threadline feel narrower than the project vision.
- **D-03:** Avoid a packaging-only story like "0.3.0 version bump / release refresh." Phase 48 is packaging work, but the release itself should read as the culmination of the v1.14 adopter slice rather than an administrative update.
- **D-04:** The `CHANGELOG.md` `0.3.0` section should open with the adoption claim, then organize bullets under the proof surfaces: SaaS onboarding, Sigra integration, performance evidence, incident response, and upgrade notes.
- **D-05:** Keep the promise narrow and evidence-backed. The wording should emphasize "production adoption candidate" / "drop-in adoption" rather than implying Threadline is already a finished platform product. The release story must not outrun the strength of the shipped guides and tests.

### Release Pre-flight Shape
- **D-06:** `mix verify.release` should be **strict** and **release-scoped**. It is a maintainer pre-flight, not a second `mix ci.all`.
- **D-07:** The alias should fail unless the working tree is clean. Release validation against uncommitted edits is the wrong failure mode for this repo because the taggable tree is the artifact that matters.
- **D-08:** Include only packaging-surface checks in `verify.release`: clean-tree enforcement, release metadata validation, release-surface/doc-contract validation, `MIX_ENV=dev mix docs`, and `mix hex.build`.
- **D-09:** Do **not** include Postgres-dependent or full-suite checks in `verify.release` (`mix verify.test`, `mix verify.topology`, `mix verify.example`, `mix verify.bench`, or `mix hex.publish`). Those stay in CI or the maintainer runbook.
- **D-10:** Introduce a dedicated release-surface contract test that ties together `mix.exs` package files, ExDoc extras, and the guides on disk. This matches the repo's existing doc-contract discipline and protects against drift better than ad hoc grep checks.
- **D-11:** Keep "wait for green CI on `main` before tagging" in `CONTRIBUTING.md` as a runbook step rather than baking remote-state checks into the alias itself.

### README and Docs Routing
- **D-12:** Keep the README compact and library-first, but make the `0.3.0` adopter path more intentional. The README is the package front door, not the full operator handbook.
- **D-13:** Surface **two** high-leverage next reads prominently in the README: `guides/getting-started-saas.md` and `guides/integrations/sigra.md`. These are the highest-signal paths for a new adopter evaluating whether Threadline is genuinely drop-in.
- **D-14:** Do **not** promote `guides/performance.md` and `guides/incident-playbook.md` to equal top-level prominence in the README. Keep them discoverable, but one step deeper as operator follow-on material once the reader has crossed the adoption threshold.
- **D-15:** Preserve the docs layering:
  - README = package front door and minimal API/value routing
  - `guides/getting-started-saas.md` = first-hour adoption path
  - `guides/integrations/sigra.md` = best-supported auth/integration bridge
  - `guides/performance.md` and `guides/incident-playbook.md` = production/operator evidence
- **D-16:** ExDoc grouping should mirror that layering. `Integrations: ~r{^guides/integrations/}` must match before the broader reference bucket so the Sigra guide is not swallowed by a generic guide group.

### Ecosystem / DX Guardrails
- **D-17:** Favor explicit, inspectable release surfaces over clever macros or hidden behavior. This is consistent with Elixir library guidance and with Threadline's existing style: named `mix verify.*` entrypoints, doc-contract tests, and explicit `Plug` wiring.
- **D-18:** Release packaging should continue Threadline's "principle of least surprise" posture:
  - versioned source links should match tags,
  - install snippets must match the published version,
  - docs navigation should reflect actual adoption order,
  - release checks should validate the shipped tree, not a local approximation.
- **D-19:** Use the documentation taxonomy already implied by strong ecosystem packages: tutorial/get-started material up front, targeted how-to guides for concrete integrations, and reference/API material in ExDoc. Do not collapse everything into the README.
- **D-20:** Preserve the project's hard-won differentiators in the release story: SQL-native audit data, transaction-scoped attribution, PgBouncer-safe transaction-local context, and operator-friendly inspection. Those are the "why" behind the adopter framing.

### the agent's Discretion
- Exact final wording of the `0.3.0` headline paragraph in `CHANGELOG.md` and README.
- Whether the README routes to the quickstart from `Start here`, `Quick Start`, or a small dedicated "Next reads" block.
- The exact implementation of the clean-tree check in `mix verify.release` (shell command vs small helper), as long as the failure mode is explicit and maintainer-friendly.
- The exact shape of the release-surface contract test module, provided it enforces `package[:files]` / `docs[:extras]` / guides-on-disk consistency.

### Deferred Ideas (OUT OF SCOPE)
- Add a standalone upgrade guide such as `guides/upgrading-to-0.3.md` if the `CHANGELOG.md` `### Upgrade from 0.2.x` section proves too cramped. Current recommendation: keep the upgrade path in the changelog for `0.x`.
- Broader README expansion for performance and incident-response guides if real adopters still miss those surfaces after `0.3.0`. Current recommendation: do not overload the README yet.
- General GSD workflow change to default toward internal recommendation-first discussion for low/medium-impact choices across the whole system. Captured as a user preference, but out of scope for Phase 48 implementation itself.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | `mix.exs` version bump, dated `CHANGELOG.md` `0.3.0` section with five required subsections, README install snippet `~> 0.3`, and tag/version alignment. [VERIFIED: REQUIREMENTS.md] | Existing version/changelog validator, current README contract, and current release metadata flow define the required edits and validation points. [VERIFIED: bin/verify-release-shape][VERIFIED: README.md][VERIFIED: readme_doc_contract_test.exs] |
| REL-02 | ExDoc extras/module groups refresh, CONTRIBUTING publish runbook, and new `release_artifact_contract_test.exs` tying package files, extras, and guides-on-disk together. [VERIFIED: REQUIREMENTS.md] | `mix.exs` already centralizes package/files and docs/extras; pure-file doc-contract tests are already the house style. [VERIFIED: mix.exs][VERIFIED: sigra_doc_contract_test.exs][VERIFIED: getting_started_saas_doc_contract_test.exs] |
| REL-03 | Strict `mix verify.release` pre-flight running clean-tree checks, `mix docs`, `mix hex.build`, and release-surface checks without becoming part of `mix ci.all`. [VERIFIED: REQUIREMENTS.md] | Existing function-backed aliases (`verify.bench`, `verify.example`), CI separation of docs/package/metadata, and current `mix help` surface show the intended implementation path. [VERIFIED: mix.exs][VERIFIED: ci.yml][VERIFIED: mix help] |
</phase_requirements>

## Summary

Phase 48 is mostly a release-surface consolidation phase, not a feature-delivery phase. The four adopter guides already exist on disk and are already listed in `docs.extras`, but the public release contract is still incomplete because the package version is `0.2.0`, the README still installs `~> 0.2`, the changelog has no `0.3.0` section, `Threadline.Integrations.Sigra` is still grouped under the singular `Integration` bucket, and there is no `verify.release` alias in `mix help`. [VERIFIED: mix.exs][VERIFIED: README.md][VERIFIED: CHANGELOG.md][VERIFIED: mix help]

The strongest implementation pattern is already present in the repo: keep release checks explicit and composable. CI already treats docs build, tarball build, and release-shape metadata as separate jobs, and root `mix.exs` already uses function-backed aliases when a plain alias list is too weak. Phase 48 should mirror that composition locally instead of inventing a second release system. [VERIFIED: ci.yml][VERIFIED: mix.exs]

The main gap is drift detection across three release surfaces that currently evolve independently: `package[:files]`, `docs[:extras]`, and the actual markdown guides on disk. Because `package[:files]` currently includes the entire `guides` directory while `docs[:extras]` is an explicit list, the failure mode is not missing tarball content but missing discoverability in HexDocs. A new pure-file release artifact contract test is the lowest-friction fix. [VERIFIED: mix.exs][VERIFIED: guides listing][RECOMMENDATION][VERIFIED: codebase grep]

**Primary recommendation:** implement Phase 48 with one focused `mix.exs` pass (`@version`, `preferred_envs`, `verify.release`, `groups_for_extras`, `groups_for_modules`), one new pure-file `release_artifact_contract_test.exs`, and one docs pass over `CHANGELOG.md`, `README.md`, and `CONTRIBUTING.md`; keep `verify.release` release-scoped and non-DB. [RECOMMENDATION][VERIFIED: mix.exs][VERIFIED: CONTRIBUTING.md][VERIFIED: ci.yml]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version bump, package metadata, and `mix verify.release` | API / Backend [ASSUMED] | CDN / Static [ASSUMED] | The behavior lives in Elixir/Mix project code and emits artifacts that are later published as docs and tarballs. [VERIFIED: mix.exs] |
| HexDocs guide surfacing and module grouping | CDN / Static [ASSUMED] | API / Backend [ASSUMED] | ExDoc builds static documentation from explicit `extras` and grouping config in `mix.exs`. [VERIFIED: mix.exs][CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] |
| README and changelog routing | CDN / Static [ASSUMED] | API / Backend [ASSUMED] | These are package-facing markdown artifacts consumed on GitHub, Hex, and HexDocs rather than runtime application logic. [VERIFIED: README.md][VERIFIED: CHANGELOG.md] |
| Release artifact drift enforcement | API / Backend [ASSUMED] | CDN / Static [ASSUMED] | The checks run in ExUnit and shell scripts, but they validate static docs and package contents. [VERIFIED: readme_doc_contract_test.exs][VERIFIED: bin/verify-release-shape] |
| Tag/version publish contract | API / Backend [ASSUMED] | CDN / Static [ASSUMED] | GitHub Actions validates the tag against `@version` before publishing package artifacts. [VERIFIED: hex-publish.yml] |

## Project Constraints (from CLAUDE.md)

- Use named `mix verify.*` or `mix ci.*` entrypoints in docs and release guidance instead of ad hoc command lists when an entrypoint exists. [VERIFIED: CLAUDE.md]
- Keep README, guides, and example app aligned via contract tests; docs drift is treated as a first-class failure mode. [VERIFIED: CLAUDE.md]
- Keep stable GitHub Actions job keys unchanged; release research should work with existing `verify-docs`, `verify-hex-package`, and `verify-release-shape` jobs rather than renaming them. [VERIFIED: CLAUDE.md][VERIFIED: ci.yml]
- Treat this phase as packaging and documentation only; do not recommend new capture or semantics behavior. [VERIFIED: ROADMAP.md][VERIFIED: 48-CONTEXT.md]
- Use Threadline domain language consistently in public docs and release notes. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Mix project aliases | project-local [VERIFIED: mix.exs] | Primary release entrypoints (`ci.all`, `verify.*`, future `verify.release`). [VERIFIED: mix.exs] | The repo already uses aliases plus function-backed helpers for complex verification flows. [VERIFIED: mix.exs] |
| ExDoc | locked `0.40.1`, released 2026-01-31 [VERIFIED: mix hex.info ex_doc][CITED: https://hexdocs.pm/ex_doc/changelog.html] | Builds HexDocs and consumes `extras`, `groups_for_extras`, and `groups_for_modules`. [VERIFIED: mix.exs] | ExDoc is the existing documentation pipeline and already supports the grouping options this phase needs. [VERIFIED: mix.exs][CITED: https://hexdocs.pm/ex_doc/changelog.html] |
| ExUnit | bundled with local Elixir `1.19.5` [VERIFIED: mix --version] | Runs pure-file release contract tests without DB dependence. [VERIFIED: performance_doc_contract_test.exs][VERIFIED: sigra_doc_contract_test.exs] | The repo already uses async pure-file ExUnit tests for doc-surface drift guards. [VERIFIED: performance_doc_contract_test.exs][VERIFIED: incident_playbook_doc_contract_test.exs] |
| Git | `2.41.0` locally [VERIFIED: git --version] | Clean-tree enforcement and tag/version workflow. [VERIFIED: hex-publish.yml][VERIFIED: CONTRIBUTING.md] | The release phase explicitly depends on a taggable tree and SemVer tags. [VERIFIED: 48-CONTEXT.md][VERIFIED: CONTRIBUTING.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `bin/verify-release-shape` | project-local [VERIFIED: bin/verify-release-shape] | Validates `@version` and dated changelog heading alignment. [VERIFIED: bin/verify-release-shape] | Use as the first metadata gate inside `verify.release`; extend around it rather than replacing it. [RECOMMENDATION][VERIFIED: bin/verify-release-shape] |
| GitHub Actions `verify-docs` / `verify-hex-package` / `verify-release-shape` jobs | project-local [VERIFIED: ci.yml] | Define current CI release hygiene boundaries. [VERIFIED: ci.yml] | Mirror these checks locally in `verify.release`; do not pull in DB-heavy jobs. [RECOMMENDATION][VERIFIED: ci.yml] |
| `Threadline.MixProject.project/0` | project-local [VERIFIED: mix.exs] | Exposes resolved `package` and `docs` config to a new release artifact test. [VERIFIED: mix.exs] | Use from ExUnit instead of parsing `mix.exs` with brittle regex for list equality checks. [RECOMMENDATION][VERIFIED: mix.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Function-backed `verify.release` helper [RECOMMENDATION][VERIFIED: mix.exs] | Plain alias list [VERIFIED: mix.exs] | A plain alias cannot express clean-tree failure messaging or conditional cleanup as clearly as existing helper functions like `verify.bench/1` and `verify_example/1`. [VERIFIED: mix.exs] |
| Pure-file `release_artifact_contract_test.exs` [RECOMMENDATION][VERIFIED: performance_doc_contract_test.exs] | More shell `grep` checks [ASSUMED] | ExUnit set comparisons are easier to keep deterministic, easier to extend, and consistent with current guide-contract style. [VERIFIED: performance_doc_contract_test.exs][VERIFIED: sigra_doc_contract_test.exs] |
| Explicit ExDoc `Integrations` group before `Reference` [RECOMMENDATION][VERIFIED: 48-CONTEXT.md] | Rely on broad `Reference: ~r{^guides/}` only [VERIFIED: mix.exs] | The current broad regex swallows `guides/integrations/sigra.md`, which weakens the intended docs hierarchy for adopters. [VERIFIED: mix.exs][VERIFIED: 48-CONTEXT.md] |

**Installation:** existing deps only; no new dependency is required for Phase 48. [VERIFIED: mix.exs]
```bash
mix deps.get
```

**Version verification:** [VERIFIED: mix --version][VERIFIED: mix hex.info ex_doc]
```bash
mix --version
mix hex.info ex_doc
```

- Local Mix is `1.19.5` on Erlang/OTP 28. [VERIFIED: mix --version]
- `ex_doc` is locked at `0.40.1`; `mix hex.info ex_doc` reports the recent release date as 2026-01-31. [VERIFIED: mix hex.info ex_doc]

## Architecture Patterns

### System Architecture Diagram

```text
mix.exs
  |
  |-- @version -> doc_source_ref() -> package links / source links
  |-- package[:files] -------------------------------\
  |-- docs[:extras] + groups_for_extras + groups_for_modules \
  |-- aliases() -> verify.release helper                    |
  v                                                        |
bin/verify-release-shape                                   |
  |                                                        |
  v                                                        |
test/threadline/release_artifact_contract_test.exs <-------/
  |
  |-- compare guides/**/*.md on disk
  |-- compare docs extras guide list
  |-- assert package includes guides surface
  |-- assert README / changelog / contributing literals that are release-scoped
  v
mix verify.release
  |
  |-- fail on dirty tree
  |-- run bin/verify-release-shape
  |-- run pure-file release/doc contract tests
  |-- run MIX_ENV=dev mix docs
  |-- run mix hex.build
  v
maintainer runbook in CONTRIBUTING.md
  |
  |-- wait for green CI on main
  |-- tag v0.3.0
  v
.github/workflows/hex-publish.yml
```

### Recommended Project Structure

```text
mix.exs                                   # Version, aliases, ExDoc grouping, package allowlist
README.md                                 # Install snippet + adopter routing
CHANGELOG.md                              # 0.3.0 section + upgrade notes
CONTRIBUTING.md                           # Maintainer publish runbook + verify.release
bin/verify-release-shape                  # Existing metadata validator
test/threadline/
├── readme_doc_contract_test.exs          # README literal checks
├── ci_topology_contract_test.exs         # ci.all exclusions
└── release_artifact_contract_test.exs    # New pure-file release surface test
```

### Pattern 1: Function-Backed Release Alias
**What:** Implement `verify.release` as a helper function in `mix.exs`, matching the repo’s existing `verify.bench` and `verify.example` pattern. [RECOMMENDATION][VERIFIED: mix.exs]  
**When to use:** When the verification flow needs a clean-tree check, explicit subprocesses, or post-step failure messages. [RECOMMENDATION][VERIFIED: mix.exs]  
**Example:**
```elixir
defp verify_release(_args) do
  ensure_clean_tree!()

  commands = [
    "bin/verify-release-shape",
    "mix test test/threadline/release_artifact_contract_test.exs",
    "MIX_ENV=dev mix docs",
    "mix hex.build"
  ]

  Enum.each(commands, fn cmd ->
    case Mix.shell().cmd("bash -lc 'set -euo pipefail && #{cmd}'") do
      0 -> :ok
      status -> Mix.raise("verify.release failed while running #{cmd} (#{status})")
    end
  end)
end
```
Source pattern: [mix.exs](/Users/jon/projects/threadline/mix.exs:52) [VERIFIED: mix.exs]

### Pattern 2: Release Artifact Set Comparison in ExUnit
**What:** Derive `package[:files]` and `docs[:extras]` from `Threadline.MixProject.project/0`, then compare the guide subset against `Path.wildcard("guides/**/*.md")`. [RECOMMENDATION][VERIFIED: mix.exs]  
**When to use:** For REL-02 drift enforcement between package contents, HexDocs discoverability, and actual files on disk. [RECOMMENDATION][VERIFIED: mix.exs]  
**Example:**
```elixir
test "guide files on disk match docs extras allowlist" do
  project = Threadline.MixProject.project()

  extras =
    project[:docs][:extras]
    |> Enum.filter(&String.ends_with?(&1, ".md"))
    |> Enum.filter(&String.starts_with?(&1, "guides/"))
    |> MapSet.new()

  guides_on_disk =
    Path.wildcard("guides/**/*.md")
    |> MapSet.new()

  assert extras == guides_on_disk
  assert "guides" in project[:package][:files]
end
```
Source pattern: [test/threadline/getting_started_saas_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/getting_started_saas_doc_contract_test.exs:38) [VERIFIED: getting_started_saas_doc_contract_test.exs]

### Pattern 3: Changelog Upgrade Block as the Only 0.x Upgrade Guide
**What:** Keep upgrade guidance inside the `CHANGELOG.md` release section rather than spawning a dedicated upgrade guide. [RECOMMENDATION][VERIFIED: REQUIREMENTS.md][VERIFIED: 48-CONTEXT.md]  
**When to use:** For `0.x` releases where the upgrade surface is small and closely tied to the release narrative. [RECOMMENDATION][VERIFIED: REQUIREMENTS.md]  
**Example structure:**
```markdown
## [0.3.0] - 2026-05-05

### Added
### Changed
### Deprecated
### Breaking

### Upgrade from 0.2.x
- Dependencies: no runtime dependency changes.
- Config changes: none.
- Migration steps: none.
- Sigra wiring: use `actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1`.
```
Source requirement: [REQUIREMENTS.md](/Users/jon/projects/threadline/.planning/REQUIREMENTS.md:59) [VERIFIED: REQUIREMENTS.md]

### Anti-Patterns to Avoid

- **Adding `verify.release` to `ci.all`:** `ci.all` is intentionally the repeatable contributor gate, while `verify.release` is a clean-tree maintainer pre-flight that runs artifact-producing commands. [VERIFIED: REQUIREMENTS.md][VERIFIED: 48-CONTEXT.md][VERIFIED: ci_topology_contract_test.exs]
- **Reusing `verify.doc_contract` inside `verify.release`:** `verify.doc_contract` currently points only at `readme_doc_contract_test.exs`, and that test uses `Threadline.DataCase`, so it is not a DB-free release gate. [VERIFIED: mix.exs][VERIFIED: readme_doc_contract_test.exs]
- **Comparing every file under `guides/` without filtering extension:** `guides/.DS_Store` exists locally, so a naive `find guides` equality check will produce false drift. [VERIFIED: guides listing]
- **Leaving Sigra in the broad `Reference` navigation only:** the guide is already on disk and in extras, but without group precedence it is less discoverable than the phase decision requires. [VERIFIED: mix.exs][VERIFIED: 48-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version/changelog alignment | New bespoke parser [ASSUMED] | Existing `bin/verify-release-shape` [VERIFIED: bin/verify-release-shape] | The script already enforces the current dated-heading contract and is wired into CI. [VERIFIED: ci.yml][VERIFIED: bin/verify-release-shape] |
| Release docs consistency | Ad hoc shell `grep` chains [ASSUMED] | Pure-file ExUnit contract test [VERIFIED: performance_doc_contract_test.exs] | ExUnit keeps failure output readable and matches the repo’s established guide-contract style. [VERIFIED: performance_doc_contract_test.exs][VERIFIED: sigra_doc_contract_test.exs] |
| Publish automation | New CI publish path [ASSUMED] | Existing tag-triggered `hex-publish.yml` workflow plus CONTRIBUTING runbook [VERIFIED: hex-publish.yml][VERIFIED: CONTRIBUTING.md] | The project already chose interactive/local publish guidance backed by a tag-triggered workflow and `HEX_API_KEY`. [VERIFIED: REQUIREMENTS.md][VERIFIED: CONTRIBUTING.md] |

**Key insight:** the package already ships the whole `guides/` directory, so the real Phase 48 risk is navigation drift and release-process drift, not missing source inclusion. [VERIFIED: mix.exs][RECOMMENDATION]

## Common Pitfalls

### Pitfall 1: Dirty-tree pre-flight that becomes impossible to rerun
**What goes wrong:** `verify.release` fails on reruns because a previous `mix hex.build` left `threadline-*.tar` in the repo root. [ASSUMED]  
**Why it happens:** The clean-tree guard runs before artifact generation, while `mix hex.build` produces untracked files. [VERIFIED: 48-CONTEXT.md][VERIFIED: ci.yml]  
**How to avoid:** Either delete generated tarballs at the end of the helper or document that `rm threadline-*.tar` is part of the rerun path; do not weaken the pre-flight to ignore arbitrary untracked files. [RECOMMENDATION][VERIFIED: 48-CONTEXT.md]  
**Warning signs:** `git status --short` shows only `threadline-0.3.0.tar` between pre-flight runs. [ASSUMED]

### Pitfall 2: README version bump without contract coverage
**What goes wrong:** `README.md` advertises `~> 0.3`, but no test fails if it drifts back to `~> 0.2` later. [VERIFIED: README.md][VERIFIED: readme_doc_contract_test.exs]  
**Why it happens:** The current README contract asserts API names and guide links, not dependency version literals. [VERIFIED: readme_doc_contract_test.exs]  
**How to avoid:** Add a direct `~> 0.3` assertion to `readme_doc_contract_test.exs` and optionally mirror it in the release artifact contract test. [RECOMMENDATION][VERIFIED: readme_doc_contract_test.exs]  
**Warning signs:** `README.md` changes in a release commit without a corresponding test diff. [RECOMMENDATION][VERIFIED: readme_doc_contract_test.exs]

### Pitfall 3: Broad ExDoc group regex swallowing the Sigra guide
**What goes wrong:** `guides/integrations/sigra.md` renders under the generic reference bucket instead of an integrations bucket. [VERIFIED: mix.exs]  
**Why it happens:** ExDoc groups extras by regex, and the current config has only `Reference: ~r{^guides/}`. [VERIFIED: mix.exs][CITED: https://hexdocs.pm/ex_doc/changelog.html]  
**How to avoid:** Insert `Integrations: ~r{^guides/integrations/}` before `Reference: ~r{^guides/}`. [RECOMMENDATION][VERIFIED: REQUIREMENTS.md][VERIFIED: 48-CONTEXT.md]  
**Warning signs:** `mix.exs` still has just three `groups_for_extras` entries after the phase lands. [VERIFIED: mix.exs]

### Pitfall 4: Changelog section passes metadata script but fails the release contract
**What goes wrong:** `bin/verify-release-shape` passes even though `0.3.0` is missing `### Deprecated`, `### Breaking`, or `### Upgrade from 0.2.x`. [VERIFIED: bin/verify-release-shape][VERIFIED: REQUIREMENTS.md]  
**Why it happens:** The existing script checks only `@version` plus a dated heading. [VERIFIED: bin/verify-release-shape]  
**How to avoid:** Put subsection assertions in the new release artifact test instead of expanding the shell script into a larger markdown parser. [RECOMMENDATION][VERIFIED: bin/verify-release-shape]  
**Warning signs:** Release metadata passes, but the changelog diff only adds one or two subsections. [RECOMMENDATION][VERIFIED: REQUIREMENTS.md]

## Code Examples

Verified patterns and implementation-ready adaptations:

### Existing function-backed alias pattern
```elixir
defp verify_example(_args) do
  cmd =
    "bash -lc 'set -euo pipefail && cd examples/threadline_phoenix && printf \"n\\n\" | mix deps.get && mix compile --warnings-as-errors && mix ecto.create --quiet -r ThreadlinePhoenix.Repo && mix test'"

  case Mix.shell().cmd(cmd, env: [{"MIX_ENV", "test"}]) do
    0 -> :ok
    status -> Mix.raise("verify.example failed (#{status})")
  end
end
```
Source: [mix.exs](/Users/jon/projects/threadline/mix.exs:91) [VERIFIED: mix.exs]

### Existing pure-file guide contract pattern
```elixir
test "performance guide retains required headings" do
  doc = read_rel!(["guides", "performance.md"])

  for heading <- [
        "## Workload Presets",
        "## Throughput Baselines",
        "## Impact on Primary Transactions",
        "## Capture-time cost knobs"
      ] do
    assert String.contains?(doc, heading)
  end
end
```
Source: [test/threadline/performance_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/performance_doc_contract_test.exs:18) [VERIFIED: performance_doc_contract_test.exs]

### Recommended clean-tree helper
```elixir
defp ensure_clean_tree! do
  output = System.cmd("git", ["status", "--porcelain"], stderr_to_stdout: true) |> elem(0) |> String.trim()

  if output != "" do
    Mix.raise("verify.release requires a clean working tree before artifact generation:\\n\\n#{output}")
  end
end
```
Source basis: project already shells out for verification helpers and release policy requires clean-tree failure. [VERIFIED: mix.exs][VERIFIED: 48-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual doc review for package surfaces [ASSUMED] | Pure-file ExUnit doc-contract tests for README and guides [VERIFIED: readme_doc_contract_test.exs][VERIFIED: performance_doc_contract_test.exs] | Present in current repo state on 2026-05-05. [VERIFIED: codebase grep] | Drift becomes a test failure instead of a maintainer memory problem. [VERIFIED: readme_doc_contract_test.exs] |
| Single generic ExDoc guide bucket [VERIFIED: mix.exs] | Regex-based guide grouping with a dedicated `Integrations` bucket ahead of `Reference` [RECOMMENDATION][CITED: https://hexdocs.pm/ex_doc/changelog.html] | Phase 48 target state. [VERIFIED: REQUIREMENTS.md] | Better discoverability for the Sigra guide without changing guide file paths. [VERIFIED: 48-CONTEXT.md] |
| Ad hoc release commands in docs [VERIFIED: CONTRIBUTING.md] | Named `mix verify.release` pre-flight plus existing CI jobs and tag publish workflow [RECOMMENDATION][VERIFIED: REQUIREMENTS.md] | Phase 48 target state. [VERIFIED: ROADMAP.md] | Maintainers get one repeatable local release gate that matches existing CI boundaries. [VERIFIED: ci.yml] |

**Deprecated/outdated:**
- Treating `verify.doc_contract` as the whole documentation contract is outdated for this phase because it currently only targets `readme_doc_contract_test.exs`. [VERIFIED: mix.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `API / Backend` is the best architectural-tier label for Mix/ExUnit release automation in this planner taxonomy. [ASSUMED] | Architectural Responsibility Map | Low; affects planning labels more than implementation. |
| A2 | `verify.release` should clean up generated tarballs or document manual cleanup for reruns. [ASSUMED] | Common Pitfalls / Pattern 1 | Medium; a bad choice makes maintainer reruns annoying or weakens the clean-tree guarantee. |
| A3 | Shell `grep`-based release checks were previously the main fallback before doc-contract tests. [ASSUMED] | State of the Art | Low; historical framing only. |

## Open Questions (RESOLVED)

1. **Should `Threadline.Telemetry` stay in the singular `Integration` module group?**
   - What we know: `mix.exs` currently groups `Threadline.Plug`, `Threadline.Job`, `Threadline.Health`, `Threadline.Continuity`, `Threadline.Telemetry`, and `Threadline.Integrations.Sigra` together under `Integration`. [VERIFIED: mix.exs]
   - Resolution: yes. To satisfy REL-02 with the smallest taxonomy change, move only `Threadline.Integrations.Sigra` into the new plural `Integrations:` group and leave `Threadline.Telemetry` in the existing singular `Integration:` group alongside `Threadline.Plug`, `Threadline.Job`, `Threadline.Health`, and `Threadline.Continuity`. [RESOLVED][VERIFIED: REQUIREMENTS.md][RECOMMENDATION]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `git` | clean-tree check, tagging workflow | ✓ [VERIFIED: command check] | `2.41.0` [VERIFIED: git --version] | — |
| `mix` | `verify.release`, `mix docs`, `mix hex.build` | ✓ [VERIFIED: command check] | `1.19.5` [VERIFIED: mix --version] | — |
| `elixir` | Mix runtime | ✓ [VERIFIED: command check] | `1.19.5` [VERIFIED: mix --version] | — |
| `bash` | existing helper alias pattern | ✓ [VERIFIED: command check] | `5.2.37` [VERIFIED: bash --version] | `sh` possible, but inconsistent with current helpers. [ASSUMED] |
| `docker` | optional full-suite parity via `mix ci.all` with local Postgres stack | ✓ [VERIFIED: command check] | `29.4.0` [VERIFIED: docker --version] | Native local Postgres setup per `CONTRIBUTING.md`. [VERIFIED: CONTRIBUTING.md] |

**Missing dependencies with no fallback:**
- None found for the release-scoped part of Phase 48. [VERIFIED: command check]

**Missing dependencies with fallback:**
- None found. [VERIFIED: command check]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix test runner [VERIFIED: mix help][VERIFIED: existing test files] |
| Config file | `test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/release_artifact_contract_test.exs -x` after the new file exists. [RECOMMENDATION][VERIFIED: existing doc-contract pattern] |
| Full suite command | `mix ci.all` plus CI `verify-docs`, `verify-hex-package`, and `verify-release-shape`. [VERIFIED: ci.yml][VERIFIED: CONTRIBUTING.md] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | `@version`, dated `0.3.0` changelog heading, README install literal, required changelog subsections | unit + shell | `bin/verify-release-shape` and `mix test test/threadline/release_artifact_contract_test.exs` [RECOMMENDATION][VERIFIED: bin/verify-release-shape] | ❌ Wave 0 |
| REL-02 | `docs.extras` / `groups_for_extras` / `groups_for_modules` / package files / guides-on-disk stay aligned | unit | `mix test test/threadline/release_artifact_contract_test.exs` [RECOMMENDATION] | ❌ Wave 0 |
| REL-03 | `verify.release` exists, is discoverable, runs release-only checks, and is excluded from `ci.all` | unit + shell | `mix help | rg 'verify.release'` and `mix test test/threadline/ci_topology_contract_test.exs` after extending it with a `verify.release` exclusion assertion. [RECOMMENDATION][VERIFIED: mix help][VERIFIED: ci_topology_contract_test.exs] | ⚠️ partial |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/release_artifact_contract_test.exs` plus `bin/verify-release-shape` after changelog/version edits. [RECOMMENDATION][VERIFIED: bin/verify-release-shape]
- **Per wave merge:** `MIX_ENV=dev mix docs` and `mix hex.build`. [VERIFIED: ci.yml][VERIFIED: CONTRIBUTING.md]
- **Phase gate:** `mix verify.release` from a clean tree, then normal CI on `main` before tagging. [RECOMMENDATION][VERIFIED: 48-CONTEXT.md][VERIFIED: CONTRIBUTING.md]

### Wave 0 Gaps
- [ ] `test/threadline/release_artifact_contract_test.exs` — new pure-file release surface contract for REL-01 and REL-02. [RECOMMENDATION][VERIFIED: REQUIREMENTS.md]
- [ ] `test/threadline/ci_topology_contract_test.exs` — add a sibling assertion that `ci.all` does not include `verify.release`, mirroring the existing `verify.bench` guard. [RECOMMENDATION][VERIFIED: ci_topology_contract_test.exs]
- [ ] `mix.exs` — add `"verify.release": :dev` to `preferred_envs` so docs generation runs in the same environment as CI `verify-docs`. [RECOMMENDATION][VERIFIED: mix.exs][VERIFIED: ci.yml]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Not in scope for a release-packaging phase. [VERIFIED: ROADMAP.md] |
| V3 Session Management | no [VERIFIED: phase scope] | Not in scope for a release-packaging phase. [VERIFIED: ROADMAP.md] |
| V4 Access Control | no [VERIFIED: phase scope] | Not in scope for a release-packaging phase. [VERIFIED: ROADMAP.md] |
| V5 Input Validation | yes [ASSUMED] | Validate `@version`, changelog heading shape, guide file set, and clean-tree state via `bin/verify-release-shape`, ExUnit assertions, and explicit git checks. [VERIFIED: bin/verify-release-shape][RECOMMENDATION] |
| V6 Cryptography | no [VERIFIED: phase scope] | Use existing `HEX_API_KEY` secret handling in GitHub Actions; Phase 48 should not add new crypto logic. [VERIFIED: hex-publish.yml] |

### Known Threat Patterns for release-packaging automation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong tag/version pair publishes the wrong artifact | Tampering | Keep the existing `hex-publish.yml` tag-to-`@version` equality check and keep `@version` in one canonical line. [VERIFIED: hex-publish.yml][VERIFIED: bin/verify-release-shape] |
| Docs discoverability drift hides shipped guidance | Repudiation | Add `release_artifact_contract_test.exs` comparing extras to `guides/**/*.md` and asserting required README routing literals. [RECOMMENDATION][VERIFIED: REQUIREMENTS.md] |
| Dirty local tree produces an untaggable release pre-flight result | Tampering | Fail `verify.release` before artifact generation when `git status --porcelain` is non-empty. [RECOMMENDATION][VERIFIED: 48-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- [mix.exs](/Users/jon/projects/threadline/mix.exs:1) - current `@version`, aliases, package files, ExDoc extras, and module groups. [VERIFIED: mix.exs]
- [README.md](/Users/jon/projects/threadline/README.md:1) - current install snippet and docs routing. [VERIFIED: README.md]
- [CHANGELOG.md](/Users/jon/projects/threadline/CHANGELOG.md:1) - current release sections and missing `0.3.0` entry. [VERIFIED: CHANGELOG.md]
- [CONTRIBUTING.md](/Users/jon/projects/threadline/CONTRIBUTING.md:1) - existing publish runbook, CI job descriptions, and maintainer checklist. [VERIFIED: CONTRIBUTING.md]
- [.github/workflows/ci.yml](/Users/jon/projects/threadline/.github/workflows/ci.yml:1) - separate `verify-docs`, `verify-hex-package`, and `verify-release-shape` jobs. [VERIFIED: ci.yml]
- [.github/workflows/hex-publish.yml](/Users/jon/projects/threadline/.github/workflows/hex-publish.yml:1) - tag-triggered publish contract. [VERIFIED: hex-publish.yml]
- [bin/verify-release-shape](/Users/jon/projects/threadline/bin/verify-release-shape:1) - current metadata validation behavior. [VERIFIED: bin/verify-release-shape]
- [test/threadline/readme_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/readme_doc_contract_test.exs:1) - current README contract scope. [VERIFIED: readme_doc_contract_test.exs]
- [test/threadline/performance_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/performance_doc_contract_test.exs:1), [test/threadline/getting_started_saas_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/getting_started_saas_doc_contract_test.exs:1), [test/threadline/integrations/sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:1), [test/threadline/incident_playbook_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/incident_playbook_doc_contract_test.exs:1) - existing pure-file guide contract patterns. [VERIFIED: codebase grep]
- [test/threadline/ci_topology_contract_test.exs](/Users/jon/projects/threadline/test/threadline/ci_topology_contract_test.exs:1) - current `ci.all` exclusion guard pattern. [VERIFIED: ci_topology_contract_test.exs]

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html - ExDoc `mix docs` behavior and docs configuration entrypoint. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]
- https://hexdocs.pm/ex_doc/changelog.html - ExDoc support history for `groups_for_extras` / `groups_for_modules` and current 0.40.1 release date. [CITED: https://hexdocs.pm/ex_doc/changelog.html]

### Tertiary (LOW confidence)
- None. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - every recommended tool is already in the repo or already part of the documented release flow. [VERIFIED: mix.exs][VERIFIED: CONTRIBUTING.md][VERIFIED: ci.yml]
- Architecture: HIGH - the phase is narrowly scoped to known files and known CI surfaces, with one new test file and one new alias/helper. [VERIFIED: mix.exs][VERIFIED: ci.yml]
- Pitfalls: HIGH - they are directly grounded in current gaps like missing `verify.release`, narrow README contract scope, and broad ExDoc grouping. [VERIFIED: mix.exs][VERIFIED: readme_doc_contract_test.exs][VERIFIED: 48-CONTEXT.md]

**Research date:** 2026-05-05 [VERIFIED: codebase grep]  
**Valid until:** 2026-06-04 for repo-local implementation planning; re-check before tagging if release is delayed because README/changelog/workflow state may change. [RECOMMENDATION][VERIFIED: current date]
