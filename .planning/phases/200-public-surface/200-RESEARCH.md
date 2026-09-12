# Phase 200: Public Surface - Research

**Researched:** 2026-09-11
**Domain:** Elixir/Hex public API, ExDoc information architecture, package hygiene, contributor and GitHub community health
**Confidence:** HIGH for repository state and locked scope; MEDIUM for hosted-service behavior until the required post-merge smoke test

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Public Configuration and Extension Contract

- **D-01:** Establish a curated, explicit public contract for 0.10 rather than documenting every observable implementation detail or redesigning the configuration namespace. Every `:threadline` application-environment key and every Mix alias/task must be inventoried and classified as adopter-public, contributor/maintainer-only, or internal; only the first category becomes a compatibility promise. — **Reversibility:** costly — once 0.10 documents a key or extension seam, removing or changing it requires deprecation and release-note work.
- **D-02:** Treat `:storage_adapter` as a supported global extension point. Public documentation must show `config :threadline, storage_adapter: MyApp.AuditStorage`, the `Threadline.Storage` behavior, the built-in `Threadline.Storage.Local` and optional `Threadline.Storage.S3` adapters, and adapter-module configuration such as `config :threadline, Threadline.Storage.S3, ...`. The cross-adapter `put/2` promise is binary content; Local's existing regular-file-path detection is an adapter-specific convenience, not a portable behavior contract. — **Reversibility:** one-way — publishing an adapter behavior invites adopter implementations that future releases must preserve or deprecate deliberately.
- **D-03:** Resolve the existing `Threadline.Storage.path/1` contradiction narrowly: it is declared optional, so operator export delivery must check whether the callback exists and fall back to `download_url/2` when it does not. Do not add a new `put_file/2` callback, rename existing callbacks, or redesign storage in this phase.
- **D-04:** Treat `:coverage_poll_ms` (default `30_000`), `:export_status_poll_ms` (default `5_000`), and `:retention_poll_ms` (default `5_000`) as supported advanced operator-surface tuning keys. Document them together, distinguish them from worker/cleanup schedules, and state that values are positive integer milliseconds. Keep their current application-environment scope; internal socket assigns are not promoted into public mount options merely because tests or LiveViews can set them.
- **D-05:** Create one canonical public configuration/command reference, reached from the Adopt and Operate paths. It must cover every supported `:threadline` key, public `mix threadline.*` task, and contributor-facing repository alias. It must explicitly distinguish host-adopter tasks from repository-only `mix verify.*`/`mix ci.*` aliases, because dependency aliases do not become host-project aliases.
- **D-06:** Guard the inventory mechanically: derive literal `Application.get_env/3`, `Application.get_env/2`, and `Application.fetch_env*` keys from source; require each to be classified; require every public key/task/alias to appear in the canonical reference; and reject unclassified additions. Use allowlists with set equality and duplicate detection, not a count floor or hand-maintained prose claim.
- **D-07:** Do not introduce a nested `config :threadline, :operator_surface` redesign, façade-only API, new callback family, or compatibility alias in this phase. Those are potentially good future API-design projects, but they are release-scope expansion rather than public-surface cleanup.

#### HexDocs Visibility and Module Taxonomy

- **D-08:** Curate module visibility by adopter call path, return type, or supported extension role—not by whether a module happens to compile under `lib/`. Keep public façades, public structs returned to callers, `Threadline.Storage` and its adapters, integration modules, `Threadline.OperatorSurface.Router`/`Auth`, and Mix tasks adopters actually run. Hide runtime plumbing and maintainer machinery with `@moduledoc false`.
- **D-09:** The six roadmap-confirmed maintainer-only pages are unconditionally hidden: `Threadline.CriticTrust.Measure`, `Threadline.CriticTrust.RankMetrics`, `Threadline.CriticTrust.LedgerSplice`, `Threadline.CriticTrust.KrippendorffAlpha`, `Mix.Tasks.Critic.Measure`, and `Mix.Tasks.Critic.Synth`.
- **D-10:** The initial internal-plumbing audit includes `Threadline.Capture.{Migration, RedactionPolicy, TriggerCaptureConfig, TriggerSQL}`, `Threadline.Export.CleanupTask`, `Threadline.Governance.{ExportJob, Migration, RetentionRun, SavedView}`, `Threadline.Health.CoverageSchemas`, private operator-surface controllers/hooks/session/style/scope/presentation helpers, `Threadline.Policy.RedactionPresenter`, `Threadline.Retention.Pruner`, and `Threadline.Semantics.Migration`. Hide a candidate only after a source/docs/test call-site audit proves no supported adopter call path or public return contract; do not shrink the surface merely to reduce grouping work. Retain `Threadline.Export.Orchestrator` if custom queue adapters require its execution entrypoint.
- **D-11:** Group every remaining generated module page exactly once under six user-oriented groups: `Core API`, `Data Types`, `Configuration & Extension Points`, `Integrations`, `Operator Surface`, and `Mix Tasks`. Use explicit module allowlists so group membership is reviewable. Do not create a miscellaneous/internal group; internal modules should be hidden.
- **D-12:** Add a documentation contract that compares the complete set of ExDoc-visible Threadline application modules with the flattened group lists, rejects missing or duplicate membership, asserts the hidden-module set, and fails when a hidden module is listed. Build docs with warnings treated as failures and retain the unpacked-Hex proof.
- **D-13:** Record newly hidden previously documented 0.9 modules in the unreleased changelog as public-surface clarification. Do not imply that `@moduledoc false` makes callable code private or use documentation hiding as a substitute for a real compatibility decision.
- **D-14:** The unpacked Hex archive gets a zero-allowlist textual planning-vocabulary scan covering module/docs text, comments, identifiers, guides, README, CONTRIBUTING, and CHANGELOG. Phase numbers, milestone literals, decision IDs, and requirement IDs must be rewritten into durable domain or engineering language. Prove the scanner has teeth with a temporary positive control; do not pass by excluding a legitimate shipped public document.

#### Canonical Documentation Homes and Guide Graph

- **D-15:** Make the README extra the HexDocs main page and single intent-led hub (`main: "readme"`, with the extra section labeled `Guides`). Preserve the established sidebar order and routing model: `Overview`, `Integrations`, `Evaluate`, `Adopt`, `Operate`, `Contribute`; preserve the README's four canonical verbs and landings; do not create another start-here/where-next guide. The top-level `Threadline` module remains the API façade, not a second navigation authority.
- **D-16:** Canonical procedure ownership is fixed: `guides/getting-started-saas.md` owns installation and the first-hour adoption sequence; `guides/operator-surface.md` owns operator-surface capabilities, mounting, authorization, and configuration; `guides/local-docker-dx.md` owns local Docker lifecycle/setup/troubleshooting. `examples/threadline_phoenix/README.md`, README, and CONTRIBUTING must point into those owners instead of maintaining competing sequences.
- **D-17:** Controlled repetition is allowed only for audience, intended outcome, prerequisites, a one-sentence safety/support boundary, a public identifier or package coordinate, and a descriptive deep link. Outside the canonical owner, do not repeat ordered procedures, shell command sequences, config/mount blocks, defaults/options tables, or troubleshooting recipes. README may retain a minimal package-coordinate snippet for 30-second orientation, but the executable end-to-end path lives in Getting Started.
- **D-18:** Repair the guide graph by contract, not by adding a giant index page. Each intent-lane landing links to every guide assigned to that lane. Every leaf guide ends with a semantic `Next steps` section that links back to its lane landing and to at least one task-adjacent successor. Validate that every guide has a non-README inbound link and an outbound link, every relative link and anchor resolves, and every referenced module/task/config key exists.
- **D-19:** Put the exact searchable error `(undefined_table) relation "audit_changes" does not exist` in a newcomer-visible `CONTRIBUTING.md` troubleshooting entry. Explain the immediate repository/example-database cause and route to the canonical Docker/setup repair anchor; do not bury the phrase in maintainer history or duplicate the full Docker runbook.
- **D-20:** Make `DESIGN-SYSTEM.md` and `examples/threadline_phoenix/README.md` first-class reachable links from HexDocs without adding them to the Hex archive. Use version-pinned external ExDoc extras or equivalent explicit links: the reference-app README belongs in `Adopt`; the design-system resource belongs in `Contribute`. Preserve the existing six extra-group keys rather than inventing a second navigation taxonomy.
- **D-21:** Keep native ExDoc responsive and light/dark behavior and the existing theme-aware, horizontally scrollable Mermaid hook. Do not build a standalone docs site or custom HexDocs skin. Use the current `brandbook/brand-book.md`, not the stale prompt-era brandbook, as visual/voice authority; retain the theme-aware README `<picture>` and current favicon. Visually verify the docs landing, diagrams, focus order, descriptive link text, and code-block overflow in light, dark, and narrow layouts.
- **D-22:** Public prose speaks in Threadline's stable domain nouns and active verbs, leads with the primary production path, defines unfamiliar terms before using them, and moves optional adapters/advanced operations after the happy path. First paragraphs of public module docs are short summaries suitable for ExDoc listings. Internal chronology and shorthand are replaced with the durable reason or invariant they were trying to preserve.

#### Contributor, Community, and Security Intake

- **D-23:** Rewrite `CONTRIBUTING.md` newcomer-first: communication/routing, setup, focused tests, `mix ci.all`, and pull-request submission come before maintainer-only critic, CI-topology, and release material. Preserve useful maintainer reference material later in the document, but remove every `.planning/` path and phase/decision/requirement identifier. Large behavior or API changes should be discussed first; small fixes and documentation corrections may go directly to a pull request.
- **D-24:** Use three short GitHub YAML issue forms: `01-bug.yml`, `02-feature-request.yml`, and `03-question.yml`, plus `config.yml` with blank issues disabled. Do not enable or route to Discussions until a real responder community exists. Apply only existing `bug`, `enhancement`, and `question` labels; assign nobody automatically.
- **D-25:** The bug form requires a free-text Threadline version or commit, relevant Elixir/OTP/Phoenix/Ecto/PostgreSQL environment, reproduction, observed result, and expected result. Logs, screenshots, and extra context are optional and carry a plain warning to remove secrets, personal data, and production audit records. The feature form asks for the problem/JTBD before a proposed solution; the question form asks for the goal and what was tried. Never use a release-version dropdown, mandatory screenshot, emoji-only cue, placeholder-only instruction, or required code-of-conduct checkbox.
- **D-26:** Add one short `.github/pull_request_template.md` with `Why`, `What changed`, `Verification`, and optional related issue. Include conditional reminders for tests and public docs, not a large universal checklist. Do not require an issue for small fixes. An HTML comment warns authors not to disclose vulnerabilities, secrets, personal data, or production audit data in a public pull request.
- **D-27:** Add root `SECURITY.md` and enable GitHub private vulnerability reporting. Support the latest published minor for security fixes, link to releases rather than hard-code a version table, distinguish vulnerabilities from ordinary bugs/support, request affected version, impact, minimal reproduction, mitigations, and disclosure status, and promise acknowledgment only as soon as practical. Never direct an undisclosed vulnerability to a public issue. Verify the repository setting and maintainer notification path live after merge.
- **D-28:** Adopt Contributor Covenant 3.0 with attribution preserved and scope limited to Threadline's actual GitHub-hosted project spaces. Because no monitored private conduct inbox exists, do not invent an email or misuse Security Advisories: visible repository behavior is moderated by maintainers, while private abuse reports route to GitHub's real Report Abuse mechanism. If a dedicated monitored conduct channel is established later, replace that route explicitly rather than leaving a placeholder.
- **D-29:** Add a community-health contract that asserts the expected files are nonempty and parseable, the three forms and chooser policy exist, labels come from the known set, security/support/conduct destinations stay distinct, and no placeholder, planning vocabulary, stale version options, nonexistent Discussions link, public-security instruction, or maintainer-only credential requirement leaks into the newcomer path. Follow with a live non-maintainer smoke check that GitHub renders the forms and PR template, recognizes the community-health files, and exposes private vulnerability reporting.

### the agent's Discretion

- Exact prose, headings, anchor names, and `Next steps` pairings, provided canonical ownership and the four intent lanes remain unambiguous.
- The final per-module visibility inventory within D-08/D-10's call-path and return-contract criteria, and exact module order inside the six fixed groups.
- How to split the config/module/archive/guide/community contract assertions across test files, provided each check is derived from source and non-vacuous.
- Whether the two external project-resource links use ExDoc URL extras or durable links from already-indexed extras, provided they are version-pinned, visible from HexDocs, classified in the existing lanes, and not added to the tarball.
- Concise adaptation wording around Contributor Covenant enforcement, provided there is no fictional contact channel and security reporting remains separate.

### Deferred Ideas (OUT OF SCOPE)

- A namespaced operator-surface configuration redesign, façade-only public API, or new storage callback family belongs in a future API-design phase with explicit compatibility and deprecation planning.
- A standalone documentation site, custom HexDocs theme, or multi-package docs portal is deferred until Threadline becomes a multi-package ecosystem whose documentation no longer fits one versioned ExDoc surface.
- GitHub Discussions, a separate support forum, and a dedicated private conduct inbox are deferred until each has a real monitored owner and enough traffic to justify another queue.
- Rendered operator copy/DOM/CSS provenance cleanup remains Phase 201; release/version automation and publishing remain Phase 202; Credo/layer-cycle repairs remain Phase 203; structural file splits remain Phase 204.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SURFACE-01 | No published `@moduledoc` or `@doc` contains phase numbers, decision IDs, requirement IDs, or milestone literals. | Archive-first vocabulary contract plus ExDoc-visible-module inventory. |
| SURFACE-02 | The Hex tarball contains no planning vocabulary, including in `mix.exs` comments and identifiers. | Unpacked Hex scan, source-derived token set, and injected positive control. |
| SURFACE-03 | Maintainer-only design-system and critic tooling is absent from the public HexDocs index. | Explicit hidden-module set and external-link-only design-system treatment. |
| SURFACE-04 | Every module page generated by ExDoc appears in a named group. | `Code.fetch_docs/1` visibility discovery compared by set equality with six explicit lists. |
| SURFACE-05 | `DESIGN-SYSTEM.md` and the reference-app README are reachable from HexDocs. | Version-derived external URL extras, assigned to existing Adopt/Contribute lanes. |
| SURFACE-06 | Every guide has at least one outbound link and one inbound link other than the README, and no relative link between docs is broken. | Guide adjacency contract plus warnings-as-errors ExDoc build and rendered anchor checks. |
| SURFACE-07 | Every module, mix alias, and `:threadline` config key referenced by public docs exists, and every supported config key and alias is documented somewhere public. | AST-derived runtime-key/task/alias inventories and reference validation. |
| SURFACE-08 | A contributor who hits the `(undefined_table) relation "audit_changes" does not exist` error finds the fix by searching the error string in the repository's own docs. | Exact-string contract in newcomer troubleshooting, with a link to the Docker owner anchor. |
| SURFACE-09 | Install instructions, operator-surface overview, and local Docker setup each have one canonical home, with other mentions pointing to it. | Owner/caller anti-duplication contract and atomic edits across all callers. |
| SURFACE-10 | `CONTRIBUTING.md` describes a contributor workflow that requires no knowledge of `.planning/`. | Newcomer-first document structure and public-archive planning-vocabulary gate. |
| SURFACE-11 | The repository provides a pull-request template, issue templates, a security policy, and a code of conduct. | Community-health contract, GitHub REST checks, and post-merge non-maintainer smoke. |

Descriptions above are copied from the source-of-truth checklist. [VERIFIED: .planning/REQUIREMENTS.md:45-55]
</phase_requirements>

## Summary

Plan this as a release-contract phase, not a collection of copy edits. The same source inventory must drive three public views: generated HexDocs, the unpacked Hex archive, and the canonical config/command reference. The key architectural move is to make each inventory executable and exhaustive: discover source facts, classify them in explicit disjoint sets, compare with set equality, and then render the approved public subset. This is consistent with the repository's existing source-derived contract style and with the locked decisions. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:20-57] [VERIFIED: test/threadline/release_artifact_contract_test.exs]

The live baseline is materially red. `mix docs --warnings-as-errors` currently reports an unclosed fence, nonexistent extra-file paths, references to hidden modules, and references to undefined functions. The current unpacked package builds successfully and contains 139 files, but an archive scan finds many phase/decision/requirement literals in shipped comments, identifiers, module docs, guides, CONTRIBUTING, and `mix.exs`. These are not cleanup afterthoughts: they should be explicit task inputs and final gates. [VERIFIED: fresh local `mix docs --warnings-as-errors` and `mix hex.build --unpack` probes, 2026-09-11]

No new runtime or documentation dependency is needed. Use the existing ExDoc, Hex, ExUnit, Elixir AST, and `Code.fetch_docs/1` seams; use GitHub itself for the authoritative issue-form/community-profile/private-reporting smoke. This minimizes semver and supply-chain scope while producing strong release evidence. [VERIFIED: mix.exs:35-105] [CITED: https://ex-doc.hexdocs.pm/ExDoc.html] [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html]

**Primary recommendation:** build source-derived red contracts first, implement the public surface in five dependency-aware slices, and make `mix docs --warnings-as-errors` plus an unpacked-archive scan part of the existing release lane.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Public runtime configuration and extension behavior | API / library runtime | Host application config | Threadline owns behavior contracts and defaults; the adopter supplies explicit application config. [VERIFIED: lib/threadline/application.ex:30-95] |
| Public Mix task and repository-alias vocabulary | Build/tooling | Documentation | Task modules ship to adopters; aliases belong to this repository's `Mix.Project` configuration. [VERIFIED: mix.exs:108-187] |
| Module visibility and grouping | Documentation build | API / library runtime | `@moduledoc false` controls documentation visibility, not callable-code privacy or runtime behavior. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html] |
| Guide graph and canonical ownership | Documentation IA | GitHub/HexDocs presentation | Markdown sources own procedures; ExDoc renders and validates the versioned navigation surface. [VERIFIED: mix.exs:375-474] |
| Hex package hygiene | Package/build | Documentation and source | The unpacked archive, not the working tree, is the authoritative consumer artifact. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |
| Contributor and security intake | GitHub repository | Public docs | Root policies and `.github` forms route distinct newcomer, support, conduct, and vulnerability jobs. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates] |
| Visual accessibility of docs | ExDoc HTML | Brand assets/hooks | Preserve native responsive/theme behavior and verify the existing hooks rather than creating a custom site. [VERIFIED: mix.exs:375-485] [VERIFIED: brandbook/brand-book.md]

## Standard Stack

### Core

| Tool | Version in this checkout | Purpose | Why Standard |
|------|--------------------------|---------|--------------|
| Elixir / OTP | `1.17.3` / `27.3.4.15` | AST-based inventories, ExUnit contracts, docs/package tasks | Uses the language's own parser and docs metadata, avoiding regex-only source interpretation. [VERIFIED: local runtime probe, 2026-09-11] |
| ExDoc | `0.40.1` | README main page, extras, URL extras, groups, generated link warnings | It already supports `main`, `extra_section`, external `:url` extras, module/extra groups, and unconditional exclusion of `@moduledoc false` modules. [VERIFIED: mix.lock:17] [CITED: https://ex-doc.hexdocs.pm/ExDoc.html] |
| Hex | `2.5.1` | Build and unpack the exact consumer archive | `mix hex.build --unpack` is the official pre-publish inspection seam. [VERIFIED: local `mix hex.info`, 2026-09-11] [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |
| ExUnit | Elixir-bundled | Deterministic contract tests | Existing repository contracts already use it; no new test framework is justified. [VERIFIED: test/threadline/release_artifact_contract_test.exs] |
| GitHub issue forms/community APIs | Hosted | Newcomer, support, conduct, and security routing | GitHub owns parsing/rendering semantics and exposes community-profile/private-reporting status. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] [CITED: https://docs.github.com/en/rest/metrics/community] |

### Supporting

| Existing component | Purpose | When to use |
|-------------------|---------|-------------|
| `Code.fetch_docs/1` | Discover compiled modules that actually expose module docs | Build the ExDoc-visible set after compilation; distinguish `:hidden` from `:none`. [CITED: https://hexdocs.pm/elixir/Code.html#fetch_docs/1] |
| `Code.string_to_quoted!/2` | Parse `lib/**/*.ex` and `mix.exs` for literal application-env reads and task/alias declarations | Use for source facts where syntax matters; fail on dynamic keys so each dynamic seam is classified explicitly. [CITED: https://hexdocs.pm/elixir/Code.html#string_to_quoted!/2] |
| Existing `test/threadline/release_artifact_contract_test.exs` | Package/extras/group topology | Extend or split beside it; do not create an unrelated packaging harness. [VERIFIED: test/threadline/release_artifact_contract_test.exs] |
| `gh api` and a browser/non-maintainer account | Hosted-state verification | Run only after files land on the default branch; local file tests cannot prove GitHub recognizes them. [CITED: https://docs.github.com/en/rest/metrics/community] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Built-in AST and docs metadata | Regex-only source scans | Regex is useful for archive text but is too brittle for exhaustive source syntax and can silently miss multiline calls. Reject for D-06. [VERIFIED: the current multiline `:export_queue_adapter` calls at `lib/threadline/operator_surface/live/timeline_live.ex:288-293` and `export_status_live.ex:78-83`] |
| Native ExDoc | Custom docs site/theme | More control, but duplicates navigation/theme/accessibility responsibility and violates D-21. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html] |
| External URL extras | Add design/reference-app docs to the Hex package | Packaging would make repository-maintainer/reference-app files consumer payload and violates D-20. ExDoc natively groups URL extras. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html] |
| GitHub live parsing/rendering | Add a YAML library solely for three forms | A parser dependency increases maintenance and still cannot prove GitHub rendering. Use structural local assertions plus hosted smoke. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |

**Installation:** none. This phase should not add dependencies or raise floors. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:9-11]

## Architecture Patterns

### System Architecture Diagram

```text
lib/**/*.ex + mix.exs + guides/**/*.md + root docs + .github/**/*
          │
          ├── AST inventory ──> config keys / Mix tasks / repo aliases
          │                         │
          │                         └── classify: adopter / contributor / internal
          │
          ├── compiled docs metadata ──> visible modules ──> six explicit groups
          │
          ├── Markdown graph ──> lane ownership / inbound / outbound / anchors
          │
          └── package.files ──> mix hex.build --unpack ──> authoritative archive scan
                                                    │
                                                    └── zero planning vocabulary

approved inventories + canonical prose
          │
          ├── mix docs --warnings-as-errors ──> versioned HexDocs preview
          ├── ExUnit contracts ───────────────> deterministic local/CI gate
          └── default-branch merge ───────────> GitHub forms/community/security smoke
```

The diagram deliberately has one fact-discovery layer and multiple projections. Duplicating allowlists independently in prose, ExDoc config, and tests would create exactly the drift this phase is meant to remove. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:20-57]

### Recommended Project Structure

```text
mix.exs                                      # package allowlist, docs main/extras/groups, repository aliases
lib/threadline/**/*.ex                       # public docs and visibility annotations
lib/mix/tasks/threadline*.ex                 # adopter task modules; hidden maintainer task stays classified
guides/configuration-and-commands.md          # recommended canonical public reference (new)
guides/{getting-started-saas,operator-surface,local-docker-dx}.md
README.md                                    # HexDocs main/intent hub
CONTRIBUTING.md                              # newcomer first; maintainer reference later
SECURITY.md
CODE_OF_CONDUCT.md
.github/ISSUE_TEMPLATE/{01-bug,02-feature-request,03-question,config}.yml
.github/pull_request_template.md
test/threadline/public_surface_contract_test.exs
test/threadline/guide_graph_contract_test.exs
test/threadline/community_health_contract_test.exs
test/threadline/release_artifact_contract_test.exs
```

The three proposed contract filenames are recommendations, not existing paths. Keep shared extraction helpers in the smallest test support module that has two or more consumers; do not create a production public-surface framework. [ASSUMED]

### Pattern 1: Discover → classify → compare by exact sets

**What:** Parse source facts, compare them against disjoint explicit category sets, then require the documented public set to equal the approved public category. Reject duplicates, unknowns, and stale allowlist members. [VERIFIED: D-01 and D-06 in .planning/phases/200-public-surface/200-CONTEXT.md:20-26]

**Recommended config inventory:** the current literal runtime keys are exactly `DATA_7C31D8A2_START :ecto_repos, :retention, :exports, :trigger_capture, :verify_coverage, :storage_adapter, :health, :coverage_poll_ms, :operator_surface_embed_fonts, :export_status_poll_ms, :export_queue_adapter, :retention_poll_ms, :operator_surface_embed_scripts, :storage_schema DATA_7C31D8A2_END`. Classify all fourteen as adopter-public because each controls an existing host-facing runtime, build, operator, or verification behavior; additionally classify module-keyed options for `Threadline.Storage.S3`, `Threadline.ExportQueue.Oban`, and a selected custom adapter as supported adapter configuration rather than pretending those dynamic module keys are literal atoms. [VERIFIED: lib/mix/tasks/threadline.policy.show.ex:63; lib/mix/tasks/threadline.verify_coverage.ex:66-103; lib/threadline/application.ex:30-95; lib/threadline/retention.ex:56; lib/threadline/capture/trigger_capture_config.ex:22; lib/threadline/health.ex:110; lib/threadline/health/policy.ex:14; lib/threadline/storage_schema.ex:27; lib/threadline/storage/s3.ex:102-104; lib/threadline/operator_surface/coverage/on_mount.ex:98-99; lib/threadline/operator_surface/fonts.ex:61; lib/threadline/operator_surface/script.ex:45; lib/threadline/operator_surface/live/timeline_live.ex:288-293; lib/threadline/operator_surface/live/export_status_live.ex:78-83,400-401; lib/threadline/operator_surface/live/retention_history_live.ex:379-380]

Dynamic `Application.get_env(:threadline, adapter, [])` reads are intentional extension seams and must be returned by the extractor as a separate “dynamic key expression” class; silently dropping them would falsely prove completeness. [VERIFIED: lib/threadline/application.ex:41-45] The public reference should document built-in adapter-module options and state that custom adapter options are owned by the adopter's module; it should not enumerate test-double module keys. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:21-25]

**Task/alias classification:** derive task names from `Mix.Tasks.*` module names and alias keys from `aliases/0`. Public task pages should include the ten currently documented adopter tasks—install, trigger generation, coverage verification/viewing, continuity, retention purge, export, incident, evidence show, and policy show—while `Mix.Tasks.Threadline.VerifyTopology` remains hidden and its `verify.topology` wrapper remains a contributor/CI topology command. Critic tasks and credentialed critic aliases are maintainer-only. Every other `verify.*`, `test.*`, and `ci.all` alias must be classified as repository-only, even when documented for contributors. [VERIFIED: mix.exs:25-26,108-187; lib/mix/tasks/threadline/verify_topology.ex:1-17; CONTRIBUTING.md:475,563-567]

### Pattern 2: Visibility follows user contracts, not namespaces

**What:** Keep a module visible if a supported adopter calls it, receives its struct, configures it, or implements/uses its behavior. Hide implementation-only modules even if their names sound important. This is the idiomatic library distinction between callable code and intentionally documented API. `@moduledoc false` always excludes a module from ExDoc but does not alter runtime visibility. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html]

**Recommended visible inventory by the six locked groups:**

| Group | Modules to keep visible | Rationale |
|-------|-------------------------|-----------|
| Core API | `Threadline`, `Audit`, `ChangeDiff`, `Continuity`, `Evidence`, `Export`, `Health`, `Investigation`, `Job`, `Plug`, `Query`, `Retention`, `Telemetry` | Public façades and supported entrypoints. [VERIFIED: lib/threadline.ex; lib/threadline/audit.ex; lib/threadline/evidence.ex; lib/threadline/investigation.ex] |
| Data Types | `Capture.AuditChange`, `Capture.AuditTransaction`, `Evidence.Proof`, `Evidence.Subject`, `Governance.EvidenceRecord`, `Investigation.IncidentBundle`, `Investigation.IncidentChange`, `Investigation.LinkedChange`, `Investigation.LinkedTransaction`, `Query.ActorHistoryPage`, `Query.TimelinePage`, `Semantics.ActorRef`, `Semantics.AuditAction`, `Semantics.AuditContext` | Returned structs, accepted values, and domain records callers must inspect. `Evidence.list_*` returns `EvidenceRecord`; query/investigation APIs construct the page and linked structs. [VERIFIED: lib/threadline/evidence.ex:62-160; lib/threadline/query.ex:512-549; lib/threadline/investigation.ex:9-17,25-123] |
| Configuration & Extension Points | `Storage`, `Storage.Local`, `Storage.S3`, `ExportQueue`, `ExportQueue.TaskAdapter`, `ExportQueue.Oban`, `Export.Orchestrator`, `Retention.Policy`, `Health.Policy`, `Verify.CoveragePolicy`, `StorageSchema` | Behaviors, built-in adapters, adapter execution seam, validators, and supported schema/config helpers. Built-in queues call `Export.Orchestrator.run/2`, so it meets D-10's retain condition. [VERIFIED: lib/threadline/export_queue.ex:1-26; lib/threadline/export_queue/task_adapter.ex:20-28; lib/threadline/export_queue/oban.ex:87-97; lib/threadline/storage.ex:1-54] |
| Integrations | `Integrations.Sigra` | Explicit optional integration. [VERIFIED: lib/threadline/integrations/sigra.ex] |
| Operator Surface | `OperatorSurface`, `OperatorSurface.Router`, `OperatorSurface.Auth` | Supported mount and authorization boundary; everything beneath controllers/live/components/hooks/presentation is implementation plumbing unless a public call-site audit proves otherwise. [VERIFIED: lib/threadline/operator_surface.ex; lib/threadline/operator_surface/router.ex; lib/threadline/operator_surface/auth.ex] |
| Mix Tasks | the ten adopter task modules listed above | Host-project commands are a real public interface; repository aliases are documented separately and do not become module pages. [VERIFIED: lib/mix/tasks; mix.exs:108-187] |

**Recommended hidden inventory:** unconditionally hide D-09's six critic modules; after the required call-site assertions, hide all D-10 candidates, the operator-surface presentation/controller/live/component implementation modules currently exposed, and `Mix.Tasks.Threadline.VerifyTopology`. Rewrite public docs that name those internals in durable conceptual language or point at the owning façade/task. Current public guides explicitly name `Capture.Migration`, `Semantics.Migration`, `Capture.TriggerSQL`, `Capture.RedactionPolicy`, `Retention.Pruner`, and `Health.CoverageSchemas`, so hiding must be atomic with those doc edits. [VERIFIED: guides/code-walkthrough.md:48-146; guides/audit-indexing.md:7; guides/how-threadline-works.md:315-333; CONTRIBUTING.md:96]

### Pattern 3: README as hub, guides as canonical owners

**What:** Keep the README skimmable and intent-led. Its four verbs route to lane landings; installation, operator configuration, and Docker procedures live only in their locked owner guides. Leaf pages end in semantic `Next steps` links. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:40-47]

The current guide corpus has 18 Markdown files; seven contain no Markdown links at all: `incident-playbook.md`, `integrations/phx-gen-auth.md`, `integrations/sigra.md`, `local-docker-dx.md`, `operator-surface.md`, `performance.md`, and `upgrade-path.md`. This proves the work is graph repair, not just an index tweak. [VERIFIED: fresh `rg --files` and Markdown-link inventory, 2026-09-11] The validator should hold a single explicit lane→guide assignment map, derive all nodes and edges from it, and assert that each guide occurs exactly once. [VERIFIED: D-18 in .planning/phases/200-public-surface/200-CONTEXT.md:43]

Use `main: "readme"` and `extra_section: "Guides"`. Keep the exact extra group order `DATA_2E8A54C9_START Overview, Integrations, Evaluate, Adopt, Operate, Contribute DATA_2E8A54C9_END`; ExDoc assigns the first matching group, so membership and order both need a contract. [VERIFIED: mix.exs:406-423] [CITED: https://ex-doc.hexdocs.pm/ExDoc.html]

For the two non-package resources, use external URL extras whose URLs interpolate the existing `doc_source_ref/0`, not hard-coded `main` links. The current ref function yields a `v<package-version>` tag for release versions and `main` only for prereleases. Group the reference app URL under Adopt and design system URL under Contribute. Adjust existing release-artifact normalization so URL extras are compared as URLs and never mistaken for package paths. [VERIFIED: mix.exs:355-359,383-423] [CITED: https://ex-doc.hexdocs.pm/ExDoc.html]

### Pattern 4: Optional callback capability check

**What:** Dispatch on callback availability before invocation, preserving the existing error behavior of implementations that do provide `path/1`. The behavior declares the callback optional, yet export delivery currently calls it unconditionally. [VERIFIED: lib/threadline/storage.ex:38-49; lib/threadline/operator_surface/controllers/export_controller.ex:106-122]

**Example:**

```elixir
case function_exported?(storage_adapter, :path, 1) do
  true -> resolve_adapter_path_or_url(storage_adapter, file_id, job)
  false -> resolve_adapter_download_url(storage_adapter, file_id, job)
end
```

The exact helper names are illustrative, but the branch is prescriptive: absence of the optional callback falls back to `download_url/2`; `{:error, :not_local}` retains the same fallback; other `path/1` errors remain errors. Test with a behavior-conforming stub that omits `path/1`, not only with Local and S3. [VERIFIED: D-03 in .planning/phases/200-public-surface/200-CONTEXT.md:22] [CITED: https://hexdocs.pm/elixir/Kernel.html#function_exported?/3]

### Pattern 5: Archive is the vocabulary authority

**What:** Build to a fresh temporary directory, walk every unpacked regular file, scan valid UTF-8 content and path/identifier names, and require zero matches. Derive requirement IDs and milestone tokens from planning source at test time; scan general decision and phase shapes plus embedded identifier forms such as `phase177`. Then inject one forbidden token into the temporary unpack directory and assert the same scanner reports it before cleanup. [VERIFIED: D-14 in .planning/phases/200-public-surface/200-CONTEXT.md:36]

Do not scan only `@moduledoc` text: the live archive offenders include `mix.exs` comments/alias identifiers and implementation comments as well as guides. Do not exclude `CONTRIBUTING.md` or other legitimate packaged text. Binary font files may be skipped only by a documented binary/UTF-8 test, not by path allowlist. [VERIFIED: current package allowlist quote `DATA_43AF71B6_START lib priv/fonts guides brandbook/favicon.svg .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md DATA_43AF71B6_END`, mix.exs:370-372] [VERIFIED: fresh unpacked archive scan, 2026-09-11]

### Pattern 6: Community files are separate queues with separate safety copy

**What:** Bug, feature, question, pull request, vulnerability, and conduct are different jobs. Give each the minimum fields needed to route it; do not turn every intake into one universal checklist. Labels are an executable set contract against existing repository labels. [VERIFIED: D-24 through D-29 in .planning/phases/200-public-surface/200-CONTEXT.md:52-57]

The live repository currently has the exact allowed labels `DATA_A99D5E12_START bug, enhancement, question DATA_A99D5E12_END`; its community profile reports 57% and no issue template, PR template, or code of conduct; private vulnerability reporting returns `{"enabled":false}`. This makes the hosted-state work explicit rather than assumed. [VERIFIED: live GitHub REST probes for `szTheory/threadline`, 2026-09-11]

Local tests should assert file/schema shape and safety copy without hand-rolling a general YAML parser. The authoritative parse/render check is a post-merge GitHub smoke from a non-maintainer account. The community-profile REST endpoint can verify recognition of CONTRIBUTING, issue template, PR template, code of conduct, README, and license; the private-vulnerability-reporting endpoint verifies the separate repository setting. [CITED: https://docs.github.com/en/rest/metrics/community] [CITED: https://docs.github.com/en/rest/repos/repos]

### Anti-Patterns to Avoid

- **Public equals present under `lib/`:** leaks implementation names into semver expectations. Use call-path/return/extension criteria. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:30]
- **Counts as completeness:** `>= N` still permits missing and duplicate inventory members. Use disjoint set equality plus duplicate checks. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:25,34]
- **Regex-only source discovery:** misses multiline or dynamic application-env calls. Parse AST and separately classify dynamic expressions. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex:288-293]
- **Hidden module references left in prose:** ExDoc warns on hidden references; the current build already demonstrates this. Replace with façade/task/domain language. [VERIFIED: fresh docs probe, 2026-09-11]
- **README as runnable second tutorial:** duplicates commands and defaults, creating drift against Getting Started. Keep only package-coordinate orientation and deep links. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:41-42]
- **External extras treated like local paths:** breaks package/extras contracts or accidentally adds repository-only resources to the tarball. Normalize extra entries by type. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html]
- **Version dropdown in bug form:** becomes stale on every release and excludes commit builds. Use free text per D-25. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:53]
- **Security Advisories used for conduct:** confuses abuse moderation with vulnerability disclosure. Keep GitHub Report Abuse and private vulnerability reporting distinct. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:55-56]
- **Local green claimed as GitHub green:** default-branch form recognition and private-reporting settings are hosted state. Require post-merge smoke. [CITED: https://docs.github.com/en/rest/metrics/community]
- **Fixing rendered operator UI in this phase:** belongs to Phase 201 and would expand review surface. Docs visual verification is in scope; operator UI changes are not. [VERIFIED: .planning/ROADMAP.md, Phase 200-201 boundary]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown rendering/autolink resolution | A custom Markdown parser | ExDoc's existing processor and warnings-as-errors | It understands ExDoc module/function references and extras. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html] |
| Hex contents model | A working-tree include/exclude guess | `package.files` plus `mix hex.build --unpack` | The unpacked archive is the artifact consumers receive. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |
| Public-module discovery | Filename heuristics | Compiled module inventory plus `Code.fetch_docs/1` | Nested modules and conditional compilation make filenames insufficient. [CITED: https://hexdocs.pm/elixir/Code.html#fetch_docs/1] |
| Config call parsing | Regex across source | Elixir AST traversal | Correctly represents multiline calls, literals, and dynamic expressions. [CITED: https://hexdocs.pm/elixir/Code.html#string_to_quoted!/2] |
| Docs website/theme | Custom static site/chrome | Native ExDoc plus current minimal hooks | Keeps versioning, search, responsiveness, and light/dark behavior conventional. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html] |
| GitHub issue-form renderer | Local imitation | GitHub issue forms and post-merge smoke | GitHub is the final schema/rendering authority. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| Vulnerability mailbox | Fictional/unmonitored email | GitHub private vulnerability reporting | Gives a real private channel and repository-native triage. [CITED: https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately] |
| Conduct reporting channel | Security Advisory or placeholder | Maintainer moderation for visible behavior plus GitHub Report Abuse | Matches actual available channels without false promises. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:56] |

**Key insight:** public-surface safety comes from projecting one reviewed classification into docs, package, and tests—not from writing three separately plausible descriptions.

## Current-State Findings That Must Shape the Plan

### Documentation build is already red

The fresh warnings-as-errors build reports: an unclosed fence at `guides/domain-reference.md:450`; nonexistent relative paths in `guides/adoption-evidence-playbook.md`; hidden `Threadline.OperatorSurface.Fonts` and `Threadline.OperatorSurface.Live.TimelineLive` references; undefined `Threadline.Query.filter_by_correlation/2`; and unresolved `Ecto.Repo.transaction/1` / `Ecto.Repo.all/2` autolinks. Fix or intentionally reword every warning; do not add warning skips, because D-12 makes warnings release-blocking. [VERIFIED: fresh local `mix docs --warnings-as-errors`, 2026-09-11]

`verify.release` currently invokes plain `MIX_ENV=dev mix docs`, not warnings-as-errors. Change that existing step or add the flag via the task invocation; do not create a second release alias that can drift. [VERIFIED: mix.exs:200-209]

### Current ExDoc grouping is incomplete and uses the wrong taxonomy

The current exact group keys are `DATA_3B7D9FE0_START Core API, Evidence, Integration, Integrations, Operator Surface (Optional In-Tree), Schemas, Mix Tasks DATA_3B7D9FE0_END`, while D-11 locks six different keys. The current lists omit many visible modules and include the hidden `Mix.Tasks.Threadline.VerifyTopology`. Replace this with the six recommended explicit lists and assert exact group-key order as well as membership. [VERIFIED: mix.exs:424-474]

### Storage docs and delivery contradict the behavior

`Threadline.Storage` currently defines `DATA_581C0D77_START @type path_or_content :: String.t() | binary() DATA_581C0D77_END`, and `Local.put/2` interprets an existing binary path as a file to copy. S3 sends its argument as object content, so path semantics are not portable. Rename the public type/documentation around binary content without renaming callbacks; describe Local's path detection as convenience only. [VERIFIED: lib/threadline/storage.ex:13-31; lib/threadline/storage/local.ex:18-34; lib/threadline/storage/s3.ex:21-35]

### Canonical guide ownership currently drifts

README, CONTRIBUTING, and the example README each carry executable setup sequences, and several public guides refer to other guides as code text rather than descriptive links. A known wrong relative link exists at `guides/getting-started-saas.md:345` (`guides/operator-surface.md` from inside `guides/`). Move procedures and their tests atomically: owner content first, callers replaced with purpose-led deep links, then anti-duplication assertions. [VERIFIED: README.md:62-180; CONTRIBUTING.md:1-115; examples/threadline_phoenix/README.md:1-120; guides/getting-started-saas.md:345-380]

### Contributor/community baseline is incomplete

`CONTRIBUTING.md` is 658 lines and places extensive repository/maintainer machinery before pull-request submission; it contains `.planning/` and phase/decision identifiers. `.github` has workflows and a ruleset but no issue forms or PR template; root has no SECURITY or code-of-conduct file. Reorder and preserve useful maintainer material, but remove internal chronology from all packaged prose. [VERIFIED: CONTRIBUTING.md:1-658; current `.github` file inventory, 2026-09-11]

## Public-Surface UX and JTBD Contract

| Persona / job | Entry | Minimum successful flow | What the interface returns |
|---------------|-------|-------------------------|----------------------------|
| Stranger evaluating fit | Hex.pm or HexDocs README | Understand the production problem → choose Evaluate → reach architecture/evaluation guidance | A credible yes/no decision without reading internals. [VERIFIED: prompts/audit-lib-domain-model-reference.md; .planning/phases/200-public-surface/200-CONTEXT.md:40] |
| New adopter seeking first success | README Adopt lane | Reach Getting Started → install/configure/capture/query → choose optional integration only afterward | One runnable path and clear next step. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:40-47] |
| Experienced integrator extending storage/queue | Config/command reference or module search | Find exact behavior, callbacks, built-ins, adapter config, failure semantics | A compatibility-grade contract without provider-side implementation leakage. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:20-26] |
| Operator diagnosing or tuning | Operate lane | Reach operator owner → find auth/mount/config/poll controls → move to incident/performance successor | Operational action plus stated safety boundary. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:23,41-43] |
| First-time contributor | CONTRIBUTING | Choose issue or direct small PR → set up → run focused test → run `mix ci.all` → submit | A reproducible contribution without planning-history knowledge. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:51-54] |
| Security researcher | SECURITY | Distinguish vulnerability from support/conduct → report privately → know requested evidence | A real private disclosure path without invented response SLA. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:55-57] |

Apply eight documentation-design pillars consistently: correctness (source-derived facts), discoverability (intent lanes/searchable identifiers), usability (one canonical procedure), accessibility (focus order, descriptive links, overflow, theme contrast), performance (native static ExDoc, no extra site/runtime), consistency (six lanes/groups and current brand voice), trust/privacy (honest support/security boundaries), and maintainability (exhaustive contracts with positive controls). These are acceptance dimensions, not separate visual redesign tasks. [VERIFIED: brandbook/brand-book.md; prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md; .planning/phases/200-public-surface/200-CONTEXT.md:40-57]

## Common Pitfalls

### Pitfall 1: Tests share the same hand-maintained blind spot

**What goes wrong:** source adds a config key/module/task, while docs and tests both continue to use the same stale allowlist. **Why:** the test compares one manual list to another instead of discovering source facts. **Avoid:** one extractor per fact source; explicit category sets; union equals discovered; pairwise intersections empty; public docs contain exactly public members. **Warning sign:** assertions only count strings or never inspect AST/compiled docs. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:25,34]

### Pitfall 2: Conditional modules distort visibility

**What goes wrong:** a test only checks beam files or only one dependency mode, missing modules conditionally defined when Phoenix/LiveView is present. **Avoid:** run the visibility contract in the normal dev/test dependency set and keep `verify.compile_no_optional` separately for the existing optional-dependency promise; classify the public namespace intentionally. **Warning sign:** module totals differ across local and CI without a stated mode. [VERIFIED: mix.exs:143,160-185; lib/threadline/operator_surface.ex]

### Pitfall 3: Docs warnings are suppressed instead of fixed

**What goes wrong:** hidden/private references and wrong paths remain user-visible as dead or misleading text. **Avoid:** zero skip list for Phase 200 warnings; reword internal concepts and use correct public façades. **Warning sign:** additions to `skip_undefined_reference_warnings_on`. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html]

### Pitfall 4: URL extras break package tests

**What goes wrong:** a helper assumes every `extras` item is a local string, tries to package an external URL, or fails grouping. **Avoid:** normalize local and URL entries independently; require external URLs to use the version-derived source ref; assert they are absent from package files and present in generated navigation. [VERIFIED: mix.exs:355-423] [CITED: https://ex-doc.hexdocs.pm/ExDoc.html]

### Pitfall 5: Archive scan passes vacuously

**What goes wrong:** glob is empty, only selected extensions are scanned, or offenders are added to an allowlist. **Avoid:** assert archive root and expected sentinel files, enumerate all regular files, scan UTF-8 text, assert nonempty scan set, inject a forbidden positive control, and keep zero allowlist. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:36]

### Pitfall 6: Guide graph counts links without validating destinations

**What goes wrong:** a leaf links to itself, only to README, or to an anchor that does not exist. **Avoid:** graph-level assertions for distinct source/destination, non-README inbound, lane return, task-adjacent successor, and warnings-as-errors/rendered-anchor checks. **Warning sign:** a regex only asserts `](` appears once. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:43]

### Pitfall 7: Public configuration prose promises implementation artifacts

**What goes wrong:** socket assigns, test overrides, or dynamic test modules become accidental compatibility guarantees. **Avoid:** keep the classification boundary at host application env and supported behaviors; explicitly say internal socket assigns are not mount options. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:20,23]

### Pitfall 8: Hosted-state requirements are marked complete locally

**What goes wrong:** YAML files exist but GitHub rejects a field, labels do not resolve, or private reporting remains disabled. **Avoid:** local contract first; admin enables private reporting; merge; non-maintainer verifies New Issue chooser/each form/PR template/security path; REST community profile confirms recognition. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] [CITED: https://docs.github.com/en/rest/metrics/community]

## Code Examples

### Exact-set contract shape

```elixir
discovered = discover_literal_threadline_keys()
classified = adopter_public ++ contributor_only ++ internal

assert MapSet.new(classified) == MapSet.new(discovered)
assert length(classified) == MapSet.size(MapSet.new(classified))
assert disjoint?(adopter_public, contributor_only)
assert disjoint?(adopter_public, internal)
assert disjoint?(contributor_only, internal)
```

The function names are illustrative; the properties are mandatory. A dynamic key expression should be a structured discovery result, not thrown away because it is not an atom. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:25]

### ExDoc configuration shape

```elixir
[
  main: "readme",
  extra_section: "Guides",
  source_ref: doc_source_ref(),
  extras: local_extras() ++ external_project_extras(),
  groups_for_extras: extra_groups(),
  groups_for_modules: module_groups()
]
```

Use the existing private functions or similarly small `mix.exs` helpers; do not create runtime modules solely to configure docs. External extras support `:title` and `:url`, and URL values can be grouped. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html]

### Hosted validation commands

```bash
gh api repos/szTheory/threadline/community/profile
gh api repos/szTheory/threadline/private-vulnerability-reporting
gh api repos/szTheory/threadline/labels --paginate --jq '.[].name'
```

These are read-only status checks. Enabling private vulnerability reporting is an admin state change and should be a deliberate execution task/checkpoint, followed by a read-back assertion that the response is `{"enabled":true}`. [CITED: https://docs.github.com/en/rest/metrics/community] [CITED: https://docs.github.com/en/rest/repos/repos]

## State of the Art and Ecosystem Lessons

| Proven pattern | Threadline application | Lesson |
|----------------|------------------------|--------|
| ExDoc supports explicit module/extra groups, URL extras, generated-page main pages, and versioned source refs. | Use native features for the six groups, README main, external project resources, and tag-derived links. | Avoid a custom documentation platform. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html] |
| Hex supports explicit package files and unpacked inspection. | Keep the existing allowlist and scan the unpacked artifact. | “Not in git” and “not in package” are different facts. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |
| Elixir identifies global application configuration as a library coupling risk, with swappable behavior implementations as a legitimate exception. | Curate current keys; keep storage/queue adapter globals; do not grow a new nested namespace now. | Publish the minimum intentional compatibility surface. [CITED: https://hexdocs.pm/elixir/design-anti-patterns.html#application-configuration-for-libraries] |
| Oban and Ecto SQL use explicit ExDoc guide/module group configuration and explicit package files. | Prefer reviewable lists and versioned guides over namespace-derived buckets. | Mature Elixir libraries make docs IA part of release configuration. [CITED: https://github.com/oban-bg/oban/blob/main/mix.exs] [CITED: https://github.com/elixir-ecto/ecto_sql/blob/master/mix.exs] |
| GitHub issue forms have a defined file location/schema, labels must exist, and templates are default-branch behavior. | Keep three short forms, validate labels, and smoke after merge. | Repository files alone do not prove hosted recognition. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| Private vulnerability reporting is a separate repository capability. | SECURITY points researchers there; enable and verify the setting. | A public issue must never be the fallback for undisclosed vulnerabilities. [CITED: https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately] |

The useful cross-ecosystem lesson from successful SDKs is stable routing: tutorials own first success, how-to guides own procedures, reference owns exhaustive options, and policies own sensitive intake. Threadline should emulate that separation without creating multiple sites or duplicating executable sequences. [VERIFIED: prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md] [VERIFIED: prompts/threadline-elixir-oss-dna.md]

## Recommended Plan Decomposition

### Plan 1 — Wave 0 executable inventories and red baselines

Create source-derived helpers/contracts for runtime config keys, tasks, aliases, compiled visible modules, ExDoc group membership, guide graph, archive vocabulary, and community files. Record current red failures, including docs warnings, without relaxing assertions. This plan establishes the reviewable classification tables that later plans consume. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:25,34,36,43,57]

### Plan 2 — Public configuration and extension behavior

Write the canonical config/command reference; classify all runtime keys/tasks/aliases; document storage and queue behaviors/adapters; clarify binary `put/2`; implement only the D-03 optional-callback repair and regression test; document the three poll intervals exactly. Link the reference from both Adopt and Operate. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:20-26]

### Plan 3 — Module taxonomy, ExDoc, and package contract

Audit D-10 call sites, hide confirmed internals and the six unconditional critic modules, create the six exact module groups, switch README main/Guides label, add version-derived URL extras, update changelog, and make docs warnings fatal in the existing release lane. Keep URL-extra normalization and package absence checks in the same slice. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:30-45]

### Plan 4 — Canonical docs, guide graph, and contributor path

Move ordered procedures to the three locked owners, replace caller copies with descriptive deep links, repair all graph edges/anchors/references, add `Next steps`, rewrite stable domain prose, and restructure CONTRIBUTING newcomer-first with the exact database error. Update existing doc contracts atomically. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:41-51]

### Plan 5 — Community/security files and final artifact gates

Add the three issue forms/config, PR template, SECURITY, and Contributor Covenant adaptation; validate schema shape/safety routing/labels; enable private reporting; perform the full unpacked vocabulary scan with positive control; run docs/package/release gates; after default-branch merge, perform the non-maintainer hosted smoke and REST read-backs. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:52-57]

Ordering matters: Plan 1 defines the contracts; Plans 2-4 satisfy them; the archive vocabulary sweep in Plan 5 must run after all shipped prose/code comments change. Community work may execute in parallel with Plans 2-4 until the final hosted/default-branch checkpoint. [ASSUMED]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The three new contract files use the proposed names rather than extending fewer existing files. | Recommended Project Structure | Low; planner may choose a coherent alternative under agent discretion. |
| A2 | Five plans are the right execution granularity. | Recommended Plan Decomposition | Low; dependencies matter more than file count. |
| A3 | A separate non-maintainer browser identity must be supplied through a human checkpoint. | Environment Availability / Validation Architecture | Medium; the hosted smoke cannot be completed from the authenticated owner CLI alone. |

## Open Questions

1. **When can the default-branch GitHub smoke run?**
   - What we know: issue-form/community recognition is default-branch hosted state; private vulnerability reporting is currently disabled. [VERIFIED: live GitHub probes, 2026-09-11]
   - What's unclear: whether the execution workflow merges Phase 200 before its verification gate.
   - Recommendation: planner must include an explicit post-merge human/non-maintainer checkpoint. If merge is outside phase execution, mark only that hosted portion pending rather than claiming SURFACE-11/D-29 complete.

2. **Which exact module candidates survive the final D-10 call-site audit?**
   - What we know: the table above is a source-backed recommendation; `Export.Orchestrator` and all public return structs have clear extension/return roles. [VERIFIED: lib/threadline/export_queue/task_adapter.ex:20-28; lib/threadline/evidence.ex:62-160; lib/threadline/query.ex:512-549]
   - What's unclear: an unknown downstream adopter cannot be observed in-repo.
   - Recommendation: preserve the recommended visible set; hide D-10 candidates only with a test that no public docs/types/specs/runtime returns point to them, and record the clarification in CHANGELOG.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / OTP | Compile, AST, ExUnit, docs/package | ✓ with explicit asdf selection | `1.17.3` / `27.3.4.15` | Use project-supported asdf versions in CI. [VERIFIED: local probe] |
| ExDoc | docs build/preview | ✓ | `0.40.1` | None needed. [VERIFIED: mix.lock:17] |
| Hex | unpacked package proof | ✓ | `2.5.1` | None needed. [VERIFIED: local `mix hex.info`] |
| GitHub CLI | REST status checks | ✓, authenticated as repository owner | `2.95.0` | Browser/API equivalent. [VERIFIED: local `gh auth status` and `gh --version`] |
| Git | source/ref and clean-tree release checks | ✓ | `2.41.0` | None. [VERIFIED: local probe] |
| ripgrep | exploratory/public vocabulary diagnostics | ✓ | `15.2.0` | Elixir file traversal in contracts. [VERIFIED: local probe] |
| Browser with non-maintainer identity | hosted smoke | Not established in CLI | — | Human checkpoint using a signed-out/incognito browser or separate account. [ASSUMED] |

The shell has no automatically selected asdf Elixir version for this checkout; successful probes required `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27`. Planner commands should either use the repository's intended toolchain activation or make these environment values explicit in validation. [VERIFIED: local runtime probes, 2026-09-11]

**Missing dependency with no automated fallback:** a non-maintainer browser identity for the required post-merge smoke. This is a deliberate human verification seam, not a code blocker. [ASSUMED]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit from Elixir `1.17.3`; ExDoc `0.40.1`; Hex `2.5.1` [VERIFIED: local/mix.lock probes] |
| Config file | `test/test_helper.exs` [VERIFIED: test/test_helper.exs] |
| Quick run command | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix test test/threadline/public_surface_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/community_health_contract_test.exs test/threadline/release_artifact_contract_test.exs` [ASSUMED: proposed new paths] |
| Docs gate | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=dev mix docs --warnings-as-errors` [VERIFIED: supported by installed task; fresh probe] |
| Package gate | `tmpdir=$(mktemp -d /tmp/threadline-hex.XXXXXX) && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix hex.build --unpack --output "$tmpdir"` followed by the archive contract [VERIFIED: successful local command probe, 2026-09-11] |
| Full suite command | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 DB_PORT=5433 MIX_ENV=test mix ci.all` [VERIFIED: mix.exs:160-185; CONTRIBUTING.md] |

### Requirements → Test Map

| Req ID | Behavior | Test type | Exact automated seam | File exists? |
|--------|----------|-----------|----------------------|--------------|
| SURFACE-01 | Visible module/function docs contain no planning vocabulary | compiled-doc contract | `mix test test/threadline/public_surface_contract_test.exs --only docs_vocabulary` | ❌ Wave 0 [ASSUMED: proposed test path/tag] |
| SURFACE-02 | Unpacked archive contains zero planning vocabulary | artifact integration | `mix test test/threadline/release_artifact_contract_test.exs` including injected positive control | ✅ extend existing [VERIFIED: test/threadline/release_artifact_contract_test.exs] |
| SURFACE-03 | Six critics and audited internals are hidden; design resource is link-only | compiled-doc/package contract | `mix test test/threadline/public_surface_contract_test.exs --only module_visibility` | ❌ Wave 0 [ASSUMED] |
| SURFACE-04 | Visible modules equal flattened six groups; no duplicates | compiled-doc contract | same `module_visibility` lane plus `mix docs --warnings-as-errors` | ❌ Wave 0 [ASSUMED] |
| SURFACE-05 | External resources reachable and absent from package | docs/package integration | `mix test test/threadline/release_artifact_contract_test.exs` and rendered docs link assertion | ✅ extend existing [VERIFIED: test/threadline/release_artifact_contract_test.exs] |
| SURFACE-06 | Guide graph complete; relative paths/anchors resolve | graph contract + docs integration | `mix test test/threadline/guide_graph_contract_test.exs && MIX_ENV=dev mix docs --warnings-as-errors` | ❌ Wave 0 [ASSUMED] |
| SURFACE-07 | Source-derived keys/tasks/aliases exactly classified/documented; doc refs exist | AST/reference contract | `mix test test/threadline/public_surface_contract_test.exs --only public_inventory` | ❌ Wave 0 [ASSUMED] |
| SURFACE-08 | Exact missing-table error is searchable and points to Docker owner | doc contract | `mix test test/threadline/community_health_contract_test.exs --only contributor_troubleshooting` | ❌ Wave 0 [ASSUMED] |
| SURFACE-09 | Three procedure owners; callers contain links, not duplicate blocks | doc ownership contract | `mix test test/threadline/guide_graph_contract_test.exs --only canonical_owners` | ❌ Wave 0 [ASSUMED] |
| SURFACE-10 | Contributor happy path has no planning dependency/vocabulary | doc/archive contract | community contract plus unpacked scan | ❌ Wave 0 [ASSUMED] |
| SURFACE-11 | Expected community files/schema/routing exist | structural contract + hosted smoke | `mix test test/threadline/community_health_contract_test.exs`; then GitHub REST/browser checklist | ❌ Wave 0; hosted step manual [ASSUMED] |

### Wave 0 Gaps

- [ ] `test/threadline/public_surface_contract_test.exs` — AST inventory, task/alias classes, public-doc vocabulary, compiled visibility, exact six groups.
- [ ] `test/threadline/guide_graph_contract_test.exs` — explicit lane assignment, inbound/outbound/Next steps, owner/caller rules, referenced module/task/config existence.
- [ ] `test/threadline/community_health_contract_test.exs` — file/schema/safety/routing/labels/troubleshooting assertions.
- [ ] Extend `test/threadline/release_artifact_contract_test.exs` — URL-extra normalization, external-resource absence, full UTF-8 archive vocabulary scan, non-vacuity, temporary positive control.
- [ ] Add a storage delivery regression stub/test in the existing export-controller test file for an adapter that implements the behavior without `path/1`. [VERIFIED: test/threadline/operator_surface/controllers/export_controller_test.exs]
- [ ] Fix the current docs-warning baseline before making warnings fatal; all current warnings are real inputs, not accepted baseline debt. [VERIFIED: fresh docs probe]
- [ ] Add the post-merge non-maintainer GitHub checklist to the plan/validation artifact; no local test substitutes for it. [CITED: https://docs.github.com/en/rest/metrics/community]

### Sampling Rate

- **Per task commit:** run the narrow contract file(s) owned by the task, plus storage regression when runtime behavior changes.
- **Per wave merge:** run all four public-surface contract files, `mix compile --warnings-as-errors`, `mix docs --warnings-as-errors`, and the unpacked-package gate.
- **Phase gate:** full `mix ci.all`, explicit `mix docs --warnings-as-errors`, fresh `mix hex.build --unpack`, zero archive vocabulary, and GitHub hosted smoke/read-back after default-branch merge.

### Non-vacuity and positive controls

Every inventory contract must assert its discovery set is nonempty and contains at least one stable sentinel before comparing sets. The archive scanner must be invoked against both the real unpacked directory and a temporary injected offender; guide graph tests must prove they fail for a missing target/anchor fixture; config extraction must include a multiline-call fixture and a dynamic-key fixture. These controls are required to distinguish a correct zero from a broken extractor. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:25,36,43]

### Visual docs acceptance

Generate docs to a temporary output and manually inspect the README landing, sidebar group order, both external project-resource links, Mermaid theme switching, keyboard focus order, descriptive link text, and horizontal code/diagram overflow at wide, narrow, light, and dark settings. Do not alter operator UI/CSS. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:46]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control |
|---------------|---------|------------------|
| V2 Authentication | Indirectly | Do not request credentials in public forms; GitHub authenticates maintainers/reporters. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:53-57] |
| V3 Session Management | No runtime change | No new session behavior in this phase. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:9-11] |
| V4 Access Control | Yes for intake routing | Private vulnerabilities go only to GitHub's private reporting path; public issue/PR routes explicitly reject undisclosed reports. [CITED: https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately] |
| V5 Input Validation | Yes | GitHub issue-form schema plus local structural assertions; no secrets/personal/audit data in public fields. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| V6 Cryptography | No | No cryptographic implementation is introduced. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:9-11] |
| V7 Error Handling / Logging | Yes in docs | Reproduction/log fields warn users to redact secrets, personal data, and production audit records. [VERIFIED: .planning/phases/200-public-surface/200-CONTEXT.md:53-54] |
| V10 Malicious Code | Yes for package hygiene | Explicit package allowlist and archive scan reduce accidental maintainer-tool/internal content exposure. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |

OWASP ASVS is an application-security verification catalog rather than a documentation schema; use the categories as threat lenses here, not as a claim of formal ASVS certification. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Threat Patterns

| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Undisclosed vulnerability posted publicly | Information disclosure | SECURITY and all public templates route privately; enable/read back private reporting. |
| Secrets or production audit records pasted into issue/PR | Information disclosure | Plain, repeated safety warning at optional log/context fields and PR HTML comment. |
| Fake/unmonitored contact promise | Repudiation / availability | Use only real GitHub routes; no invented email/Discussion queue. |
| Internal maintainer topology exposed as consumer contract | Information disclosure / maintainability | Module/config/task classification and archive zero scan. |
| Issue label silently not applied | Integrity/operability | Assert form labels are exactly the live existing set; hosted smoke after merge. |
| Security and conduct queues conflated | Information disclosure / authorization | Separate private vulnerability reporting from visible moderation/GitHub Report Abuse. |

## Project Constraints (from CLAUDE.md)

- Compile with warnings treated as errors and preserve the optional-dependency boundary. [VERIFIED: CLAUDE.md]
- Prefer source-derived contracts and existing verification entrypoints over manual counts. [VERIFIED: CLAUDE.md]
- Preserve the library/host boundary: Threadline is Phoenix-optional and host configuration remains explicit. [VERIFIED: CLAUDE.md]
- Use Threadline's stable audit-domain language and keep the top-level public façades authoritative. [VERIFIED: CLAUDE.md]

No `AGENTS.md`, project-local `.agents/skills`, or `.codex/skills` directory exists in this checkout, so there are no additional project skill directives to carry forward. [VERIFIED: filesystem inventory, 2026-09-11]

## Sources

### Primary repository sources (HIGH confidence)

- `.planning/phases/200-public-surface/200-CONTEXT.md` — D-01 through D-29, discretion, and deferrals.
- `.planning/REQUIREMENTS.md` — SURFACE-01 through SURFACE-11.
- `.planning/ROADMAP.md`, `.planning/STATE.md`, Phase 198/199 contexts — dependency and release boundary.
- `mix.exs`, `mix.lock`, `lib/**/*.ex`, `test/**/*.exs`, `README.md`, `CONTRIBUTING.md`, `guides/**/*.md`, `.github/**/*` — live implementation and public surface.
- `brandbook/brand-book.md`, `prompts/threadline-elixir-oss-dna.md`, `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md`, and applicable prior-art research — project-specific product, documentation, and ecosystem guidance.
- Fresh local compile/docs/package/archive/runtime probes performed 2026-09-11.

### Official documentation (MEDIUM confidence)

- https://ex-doc.hexdocs.pm/ExDoc.html — ExDoc main/extras/groups/URL extras/source refs/visibility/warnings.
- https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html — package files and unpacked inspection.
- https://hexdocs.pm/elixir/design-anti-patterns.html — library application-configuration guidance.
- https://hexdocs.pm/elixir/Code.html — AST and compiled docs APIs.
- https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms — issue-form schema and labels.
- https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates — default-branch template behavior.
- https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately — private vulnerability reporting.
- https://docs.github.com/en/rest/metrics/community — community profile recognition.
- https://docs.github.com/en/rest/repos/repos — private vulnerability reporting status.
- https://owasp.org/www-project-application-security-verification-standard/ — security verification lens.

### Ecosystem comparators (MEDIUM confidence)

- https://github.com/oban-bg/oban/blob/main/mix.exs — explicit extras/groups/package allowlist/source ref.
- https://github.com/elixir-ecto/ecto_sql/blob/master/mix.exs — explicit guides and module grouping.
- https://github.com/ash-project/reactor/blob/main/mix.exs — larger internal-group comparator and maintenance-cost lesson.
- https://github.com/ash-project/igniter/blob/main/mix.exs — README main and explicit groups.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — exact installed versions and existing dependencies were probed; no additions recommended.
- Architecture: HIGH — directly constrained by D-01 through D-29 and current source/tests.
- Public inventory: HIGH for current in-repo call paths; MEDIUM for unknowable external callers, mitigated by preserving public return/extension roles and changelog clarification.
- Pitfalls: HIGH — several are reproduced by the current docs build/archive and locked positive-control rules.
- Hosted GitHub completion: MEDIUM until the post-merge non-maintainer smoke; current REST baseline is verified.

**Research date:** 2026-09-11
**Valid until:** 2026-10-11 for Elixir/ExDoc/Hex guidance; re-check GitHub hosted behavior and repository settings at execution time.
