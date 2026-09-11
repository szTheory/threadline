# Phase 199: Decouple - Context

**Gathered:** 2026-09-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every test and CI gate independent of `.planning/`; move the five load-bearing quality datasets into a test-owned fixture tree without changing their meaning or bytes; remove dead tracked artifacts and one-off root scripts with their citations repaired; prove a fresh dependency fetch leaves a clean checkout; extend formatting to the repository's Elixir subprojects and scripts; and establish Dialyzer as a measured, blocking, ratcheting gate before later refactors.

This is repository hygiene and quality-gate work. It does not change capture, query, authentication, operator behavior, UI design/IA/layout/visuals, the Elixir/OTP support floor, or the Hex package's public runtime surface. `.planning/` remains tracked history but is load-bearing on nothing.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Phase Authority

- `.planning/ROADMAP.md` §"Phase 199: Decouple" and the milestone dependency spine/invariants — phase boundary, success criteria, ordering, fixture destination, Dialyzer topology, and no-UI/no-semantic-change constraints.
- `.planning/REQUIREMENTS.md` §"Decouple" — DECOUPLE-01 through DECOUPLE-08 verbatim.
- `.planning/PROJECT.md` §"Current Milestone: v1.41 Green, Clean, and Honest", §"Active", and §"Key Decisions" — project vision, public-library constraints, and the no-vacuous-gate principle.
- `.planning/STATE.md` §"Current Position" and §"Decisions" — current phase state and accumulated constraints.
- `.planning/phases/198-green-bringup/198-CONTEXT.md` — aggregate-gate integration, cache-key precedent, atomic contract-test convention, stale-lock deferral, and the requirement that no gate read new planning artifacts.

### Project Engineering Standards and Research

- `CLAUDE.md` — architecture boundaries, domain language, verification entrypoints, and repository conventions.
- `prompts/threadline-elixir-oss-dna.md` — named verification entrypoints, default-test honesty, nested-fixture cache separation, stable CI identities, and Hex package hygiene.
- `prompts/prior-art/SOURCE-CANONICAL.md` — provenance and precedence for the prior-art research corpus.
- `prompts/prior-art/oss-deep-research/elixir-best-practices-deep-research.md` — assertive boundaries, formatter conventions, explicit dependencies, and typespec/static-analysis ergonomics.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — explicit library inputs, avoidance of global application configuration, optional-dependency and package-content guidance.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Dialyzer/PLT caching, CI gates, exact toolchains, and contributor ergonomics.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — library/application boundary and dependency-direction guidance.

### Fixture Readers, Writers, and Gates

- `mix.exs` — named `verify.*`/`ci.all` aliases, current Dialyzer placeholder config, optional dependencies, and explicit Hex package allowlist.
- `.github/workflows/ci.yml` — direct scorecard shell paths, current-lane topology, aggregate `ci-required` gate, and cache integration point.
- `.gitignore` — current generated-output, scorecard, critic, crash-dump, tarball, and local-scratch policy.
- `.formatter.exs` — current root-only formatter scope.
- `lib/threadline/operator_surface/mechanical_checker.ex` — current implicit repository paths and empty-directory success behavior that D-05/D-07 replace.
- `lib/threadline/critic_trust/measure.ex` — pure critic-trust measurement boundary.
- `lib/mix/tasks/critic.measure.ex` — ledger/golden/critic-score reader-writer behavior.
- `lib/mix/tasks/critic.synth.ex` — synthetic oracle writer behavior.
- `test/threadline/operator_surface/mechanical_checker_test.exs` — real-evidence gate, positive-control idiom, and current vacuous path.
- `test/threadline/operator_surface/critic_trust_test.exs` — ledger/golden/scorecard/critic-score contracts and separation guards.
- `test/threadline/operator_surface/refute_partition_test.exs` — refute/golden/scorecard cross-dataset invariants.
- `test/threadline/operator_surface/stress_ledger_test.exs` — ledger integration and ratchet patterns.
- `examples/threadline_phoenix/e2e/critic/` — TypeScript reader/writer family that must share one anchored path module.
- `examples/threadline_phoenix/e2e/tests/` — Playwright capture writers and reviewed snapshot boundary.

### Hygiene Targets and Proof Surfaces

- `.planning/ARCHIVE-REGISTER.md` — established durable archive/recovery evidence pattern; not a destination for Phase 199 debris.
- `.planning/phases/198-green-bringup/198-04-SUMMARY.md` — identifies the tracked patch script as dead debris.
- `.planning/phases/198-green-bringup/198-41-PLAN.md` — contains the transient handoff citation that must be repaired without falsifying historical execution.
- `test/threadline/readme_doc_contract_test.exs` — disabled assertion to restore against current README truth.
- `README.md` — current canonical wording for the restored assertion.
- `bench/.formatter.exs` — child formatter rules to preserve and extend.
- `examples/threadline_phoenix/.formatter.exs` — example-app formatter/import rules to preserve and extend.
- `CONTRIBUTING.md` — canonical home for the measured Dialyzer cold/cache-hit costs and developer commands.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `MechanicalChecker.run/1` already accepts an explicit `:scorecard_dir`; extend the explicit-input seam rather than creating runtime global configuration.
- Existing tests use `System.tmp_dir!()` fixtures and positive controls, providing the right pattern for isolated malformed/missing/path-traversal and ratchet-teeth tests.
- `mix.exs` uses an explicit Hex `package.files` allowlist, which already excludes `test/`; retain it and prove the unpacked tarball remains clean.
- The MODE-B floor tests provide the tighten-only ceiling idiom for Dialyzer ignores.
- `ci-required` is the single protected aggregate, and Phase 198 already established the same-change roster/topology reconciliation rule.

### Established Patterns

- Named `mix verify.*` and `mix ci.*` commands are contributor-facing product surfaces; CI and docs cite them verbatim.
- A test, not a comment: critical fixture, ignore, citation, packaging, and CI-topology invariants need executable assertions with positive controls.
- Threadline prefers explicit data/function inputs over global configuration and keeps optional Phoenix integrations out of the required runtime dependency tree.
- Git history and named registers preserve audit truth; active HEAD does not retain stale executable debris merely for sentiment.
- Contract-test changes and their source moves remain atomic so bisecting isolates regressions.

### Integration Points

- The fixture migration spans roughly 33 executable/configuration files across runtime Elixir, Mix tasks, ExUnit, TypeScript critic tooling, Playwright capture specs, and CI shell steps; a zero-literal sweep across `lib/`, `test/`, `mix.exs`, `.github/`, `examples/`, `scripts/`, and `bench/` is mandatory.
- The Dialyzer job extends `ci-required.needs`; the CI header, `CONTRIBUTING.md` coverage table, and topology contracts must change with it.
- PLT cache keys reuse Phase 198's exact-toolchain cache convention but must add Elixir/OTP identity and Dialyzer config/dependency invalidation.
- The fresh-clone proof must run independently from the maintainer's current dirty/ignored worktree so shared ignore policy cannot be tuned to one machine.

</code_context>

<specifics>
## Specific Ideas

- The user delegated all four choices and requested a single cohesive recommendation after broad specialist research, adversarial review, comparable-library lessons, and explicit emphasis on developer ergonomics and least surprise.
- The maintainer/contributor JTBD is: run one documented command from a fresh or isolated checkout, have it find exactly the repository-owned evidence it intends to validate, get a fast actionable failure when the evidence or analyzer state is wrong, and never need knowledge of GSD or `.planning/`.
- The library-consumer JTBD is negative but important: installing Threadline from Hex must not expose test-fixture configuration, planning vocabulary, or repository-only filesystem assumptions.
- Relevant design pillars here are correctness, non-vacuity, portability, security/containment, performance and cache predictability, accessibility of diagnostics, maintainability, auditability, and contributor DX. Visual/UI/brand-system decisions do not apply to this phase; the current `DESIGN-SYSTEM.md` remains untouched.
- External research reinforced these choices: Elixir library guidance favors explicit inputs over application-global configuration; Mix provides project-file anchoring and subproject-aware formatting; Hex's explicit package files keep fixtures out of distribution; Dialyxir recommends exact-toolchain PLT caches, specific ignores, and unused-filter checks; Go/Jest/Insta fixture practices favor test-owned committed references plus explicit review of regenerated baselines; Git distinguishes shared generated-output ignores from per-user exclusions.

</specifics>

<deferred>
## Deferred Ideas

- Public planning-vocabulary cleanup and `@moduledoc false` treatment for maintainer-only critic tasks remain Phase 200 / SURFACE scope.
- Structural/layering repairs surfaced by Dialyzer that cannot be made narrowly without architecture changes remain Phase 203 scope, represented meanwhile only by exact justified suppressions under the Phase 199 ceiling.
- The example application's qualified-query/search-path wart remains deferred under the existing no-Tier-A-regeneration constraint.
- No UI, design-system, product, or new consumer-API capability was added; discussion stayed within Phase 199.

</deferred>

---

*Phase: 199-Decouple*
*Context gathered: 2026-09-10*
