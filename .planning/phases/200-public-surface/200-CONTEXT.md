# Phase 200: Public Surface - Context

**Gathered:** 2026-09-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Threadline's pre-release public surface deliberate and trustworthy: the Hex archive, generated HexDocs, public module and configuration contracts, guide graph, contributor path, and GitHub community-health files must be accurate, navigable, and free of internal planning vocabulary before 0.10.0 is published.

This phase may make a narrow behavior-preserving repair when the existing documented contract and implementation directly contradict each other, such as honoring an optional storage callback. It does not redesign the runtime API, introduce new product capabilities, change operator UI/IA/layout/visuals or rendered copy, publish 0.10.0, raise version floors, revive paid critic tooling, or restructure implementation modules for their own sake. Rendered-output cleanup belongs to Phase 201; version and release automation belong to Phase 202; deeper architecture work belongs to Phases 203-204.

</domain>

<decisions>
## Implementation Decisions

### Public Configuration and Extension Contract

- **D-01:** Establish a curated, explicit public contract for 0.10 rather than documenting every observable implementation detail or redesigning the configuration namespace. Every `:threadline` application-environment key and every Mix alias/task must be inventoried and classified as adopter-public, contributor/maintainer-only, or internal; only the first category becomes a compatibility promise. — **Reversibility:** costly — once 0.10 documents a key or extension seam, removing or changing it requires deprecation and release-note work.
- **D-02:** Treat `:storage_adapter` as a supported global extension point. Public documentation must show `config :threadline, storage_adapter: MyApp.AuditStorage`, the `Threadline.Storage` behavior, the built-in `Threadline.Storage.Local` and optional `Threadline.Storage.S3` adapters, and adapter-module configuration such as `config :threadline, Threadline.Storage.S3, ...`. The cross-adapter `put/2` promise is binary content; Local's existing regular-file-path detection is an adapter-specific convenience, not a portable behavior contract. — **Reversibility:** one-way — publishing an adapter behavior invites adopter implementations that future releases must preserve or deprecate deliberately.
- **D-03:** Resolve the existing `Threadline.Storage.path/1` contradiction narrowly: it is declared optional, so operator export delivery must check whether the callback exists and fall back to `download_url/2` when it does not. Do not add a new `put_file/2` callback, rename existing callbacks, or redesign storage in this phase.
- **D-04:** Treat `:coverage_poll_ms` (default `30_000`), `:export_status_poll_ms` (default `5_000`), and `:retention_poll_ms` (default `5_000`) as supported advanced operator-surface tuning keys. Document them together, distinguish them from worker/cleanup schedules, and state that values are positive integer milliseconds. Keep their current application-environment scope; internal socket assigns are not promoted into public mount options merely because tests or LiveViews can set them.
- **D-05:** Create one canonical public configuration/command reference, reached from the Adopt and Operate paths. It must cover every supported `:threadline` key, public `mix threadline.*` task, and contributor-facing repository alias. It must explicitly distinguish host-adopter tasks from repository-only `mix verify.*`/`mix ci.*` aliases, because dependency aliases do not become host-project aliases.
- **D-06:** Guard the inventory mechanically: derive literal `Application.get_env/3`, `Application.get_env/2`, and `Application.fetch_env*` keys from source; require each to be classified; require every public key/task/alias to appear in the canonical reference; and reject unclassified additions. Use allowlists with set equality and duplicate detection, not a count floor or hand-maintained prose claim.
- **D-07:** Do not introduce a nested `config :threadline, :operator_surface` redesign, façade-only API, new callback family, or compatibility alias in this phase. Those are potentially good future API-design projects, but they are release-scope expansion rather than public-surface cleanup.

### HexDocs Visibility and Module Taxonomy

- **D-08:** Curate module visibility by adopter call path, return type, or supported extension role—not by whether a module happens to compile under `lib/`. Keep public façades, public structs returned to callers, `Threadline.Storage` and its adapters, integration modules, `Threadline.OperatorSurface.Router`/`Auth`, and Mix tasks adopters actually run. Hide runtime plumbing and maintainer machinery with `@moduledoc false`.
- **D-09:** The six roadmap-confirmed maintainer-only pages are unconditionally hidden: `Threadline.CriticTrust.Measure`, `Threadline.CriticTrust.RankMetrics`, `Threadline.CriticTrust.LedgerSplice`, `Threadline.CriticTrust.KrippendorffAlpha`, `Mix.Tasks.Critic.Measure`, and `Mix.Tasks.Critic.Synth`.
- **D-10:** The initial internal-plumbing audit includes `Threadline.Capture.{Migration, RedactionPolicy, TriggerCaptureConfig, TriggerSQL}`, `Threadline.Export.CleanupTask`, `Threadline.Governance.{ExportJob, Migration, RetentionRun, SavedView}`, `Threadline.Health.CoverageSchemas`, private operator-surface controllers/hooks/session/style/scope/presentation helpers, `Threadline.Policy.RedactionPresenter`, `Threadline.Retention.Pruner`, and `Threadline.Semantics.Migration`. Hide a candidate only after a source/docs/test call-site audit proves no supported adopter call path or public return contract; do not shrink the surface merely to reduce grouping work. Retain `Threadline.Export.Orchestrator` if custom queue adapters require its execution entrypoint.
- **D-11:** Group every remaining generated module page exactly once under six user-oriented groups: `Core API`, `Data Types`, `Configuration & Extension Points`, `Integrations`, `Operator Surface`, and `Mix Tasks`. Use explicit module allowlists so group membership is reviewable. Do not create a miscellaneous/internal group; internal modules should be hidden.
- **D-12:** Add a documentation contract that compares the complete set of ExDoc-visible Threadline application modules with the flattened group lists, rejects missing or duplicate membership, asserts the hidden-module set, and fails when a hidden module is listed. Build docs with warnings treated as failures and retain the unpacked-Hex proof.
- **D-13:** Record newly hidden previously documented 0.9 modules in the unreleased changelog as public-surface clarification. Do not imply that `@moduledoc false` makes callable code private or use documentation hiding as a substitute for a real compatibility decision.
- **D-14:** The unpacked Hex archive gets a zero-allowlist textual planning-vocabulary scan covering module/docs text, comments, identifiers, guides, README, CONTRIBUTING, and CHANGELOG. Phase numbers, milestone literals, decision IDs, and requirement IDs must be rewritten into durable domain or engineering language. Prove the scanner has teeth with a temporary positive control; do not pass by excluding a legitimate shipped public document.

### Canonical Documentation Homes and Guide Graph

- **D-15:** Make the README extra the HexDocs main page and single intent-led hub (`main: "readme"`, with the extra section labeled `Guides`). Preserve the established sidebar order and routing model: `Overview`, `Integrations`, `Evaluate`, `Adopt`, `Operate`, `Contribute`; preserve the README's four canonical verbs and landings; do not create another start-here/where-next guide. The top-level `Threadline` module remains the API façade, not a second navigation authority.
- **D-16:** Canonical procedure ownership is fixed: `guides/getting-started-saas.md` owns installation and the first-hour adoption sequence; `guides/operator-surface.md` owns operator-surface capabilities, mounting, authorization, and configuration; `guides/local-docker-dx.md` owns local Docker lifecycle/setup/troubleshooting. `examples/threadline_phoenix/README.md`, README, and CONTRIBUTING must point into those owners instead of maintaining competing sequences.
- **D-17:** Controlled repetition is allowed only for audience, intended outcome, prerequisites, a one-sentence safety/support boundary, a public identifier or package coordinate, and a descriptive deep link. Outside the canonical owner, do not repeat ordered procedures, shell command sequences, config/mount blocks, defaults/options tables, or troubleshooting recipes. README may retain a minimal package-coordinate snippet for 30-second orientation, but the executable end-to-end path lives in Getting Started.
- **D-18:** Repair the guide graph by contract, not by adding a giant index page. Each intent-lane landing links to every guide assigned to that lane. Every leaf guide ends with a semantic `Next steps` section that links back to its lane landing and to at least one task-adjacent successor. Validate that every guide has a non-README inbound link and an outbound link, every relative link and anchor resolves, and every referenced module/task/config key exists.
- **D-19:** Put the exact searchable error `(undefined_table) relation "audit_changes" does not exist` in a newcomer-visible `CONTRIBUTING.md` troubleshooting entry. Explain the immediate repository/example-database cause and route to the canonical Docker/setup repair anchor; do not bury the phrase in maintainer history or duplicate the full Docker runbook.
- **D-20:** Make `DESIGN-SYSTEM.md` and `examples/threadline_phoenix/README.md` first-class reachable links from HexDocs without adding them to the Hex archive. Use version-pinned external ExDoc extras or equivalent explicit links: the reference-app README belongs in `Adopt`; the design-system resource belongs in `Contribute`. Preserve the existing six extra-group keys rather than inventing a second navigation taxonomy.
- **D-21:** Keep native ExDoc responsive and light/dark behavior and the existing theme-aware, horizontally scrollable Mermaid hook. Do not build a standalone docs site or custom HexDocs skin. Use the current `brandbook/brand-book.md`, not the stale prompt-era brandbook, as visual/voice authority; retain the theme-aware README `<picture>` and current favicon. Visually verify the docs landing, diagrams, focus order, descriptive link text, and code-block overflow in light, dark, and narrow layouts.
- **D-22:** Public prose speaks in Threadline's stable domain nouns and active verbs, leads with the primary production path, defines unfamiliar terms before using them, and moves optional adapters/advanced operations after the happy path. First paragraphs of public module docs are short summaries suitable for ExDoc listings. Internal chronology and shorthand are replaced with the durable reason or invariant they were trying to preserve.

### Contributor, Community, and Security Intake

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Phase Authority

- `.planning/ROADMAP.md` §"Phase 200: Public Surface" — phase goal, success criteria, known offenders, and fixed boundary with Phases 201-204.
- `.planning/REQUIREMENTS.md` §"Public Surface" and §"Out of Scope" — SURFACE-01 through SURFACE-11 and milestone prohibitions.
- `.planning/PROJECT.md` §"Current Milestone: v1.41 Green, Clean, and Honest", §"Active", and §"Key Decisions" — public-library posture, optional dependency boundary, and product vision.
- `.planning/STATE.md` §"Current Position" and §"Decisions" — current progress and carried project decisions.
- `.planning/phases/199-decouple/199-CONTEXT.md` — explicit-input posture, Hex fixture exclusion, contributor-without-`.planning/` JTBD, and source-derived gate patterns.
- `.planning/phases/198-green-bringup/198-CONTEXT.md` — tarball/public-vocabulary deferrals, executable-contract standard, and release-gate constraints.

### Project Research and Domain Authority

- `prompts/prior-art/SOURCE-CANONICAL.md` — precedence for the prompt research corpus.
- `prompts/threadline-elixir-oss-dna.md` — canonical host, golden-path-guide, doc-contract, packaging, release, and contributor-DX patterns.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — idiomatic public API, configuration, behavior, ExDoc, Hex packaging, and deprecation guidance.
- `prompts/prior-art/oss-deep-research/elixir-best-practices-deep-research.md` — Elixir naming, supervision, errors, typespec, and maintainability guidance.
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md` — Ecto integration and adopter ergonomics.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` — Phoenix library and documentation conventions.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — host/library boundary and dependency-direction guidance.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — current documentation architecture, conceptual spine, intent-lane lock, prose/diagram standards, and source-backed contracts.
- `prompts/audit-lib-domain-model-reference.md` §10-13, §20, §24-26 — personas, JTBDs, happy path, public API layers, module map, and best-in-class criteria.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — cross-ecosystem audit-library lessons and recurring adoption footguns.
- `CLAUDE.md` — architecture boundaries, domain language, verification entrypoints, and repository conventions.

### Current Brand and Documentation Authority

- `brandbook/brand-book.md` — current public voice, light/dark asset roles, typography, diagrams, microcopy, and README/docs blueprint; supersedes old prompt brandbooks.
- `brandbook/README.md` — asset inventory and current logo defaults.
- `DESIGN-SYSTEM.md` — the required design-system resource that must become reachable from HexDocs without becoming a packaged consumer guide.
- `README.md` — current intent routing, duplicated Quick Start, and future HexDocs main-page source.
- `CONTRIBUTING.md` — current contributor, CI, local setup, critic, and release content to reorder and scrub.
- `guides/getting-started-saas.md` — canonical install/first-hour adoption owner.
- `guides/operator-surface.md` — canonical optional operator-surface owner.
- `guides/local-docker-dx.md` — canonical local Docker owner.
- `examples/threadline_phoenix/README.md` — reference-app entrypoint to link from HexDocs and deduplicate against canonical guides.

### Code and Contract Surfaces

- `mix.exs` — Hex package allowlist, alias inventory, ExDoc extras/groups, version-pinned source links, and current planning-vocabulary offenders.
- `lib/threadline/storage.ex` — public adapter behavior and optional `path/1` contract.
- `lib/threadline/storage/local.ex` — built-in local adapter and its adapter-specific path convenience.
- `lib/threadline/storage/s3.ex` — optional S3 adapter and module-keyed configuration pattern.
- `lib/threadline/operator_surface/controllers/export_controller.ex` — current optional-callback contradiction and download path.
- `lib/threadline/operator_surface/coverage/on_mount.ex` — documented coverage polling configuration and precedence pattern.
- `lib/threadline/operator_surface/live/export_status_live.ex` — export-status polling key.
- `lib/threadline/operator_surface/live/retention_history_live.ex` — retention-history polling key.
- `test/threadline/release_artifact_contract_test.exs` — existing package/extras/groups contract and unpacked archive harness.
- `test/threadline/persona_routing_doc_contract_test.exs` — locked intent verbs, canonical landings, and no-new-wayfinding-guide assertions.
- `test/threadline/version_truth_doc_contract_test.exs` — source-derived public version truth pattern.
- `test/threadline/readme_doc_contract_test.exs` — current README public-copy contract to update without reintroducing duplication.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `mix.exs` already has an explicit Hex `package.files` allowlist and version-derived `source_ref`; extend those rather than inventing a packaging or version-link system.
- `test/threadline/release_artifact_contract_test.exs` already unpacks the built archive and checks guide/extras/group topology; it is the natural home or sibling pattern for zero-vocabulary and exhaustive-group checks.
- `test/threadline/persona_routing_doc_contract_test.exs` already locks Evaluate/Adopt/Operate/Contribute and forbids redundant start-here guides.
- The documentation suite already uses source-derived and nonempty-glob assertions; reuse that style for config, alias, module, guide-link, and community-file inventories.
- `Threadline.Storage` is already a documented behavior with Local and S3 implementations, so the public extension seam exists; Phase 200 clarifies and verifies it rather than designing a new one.

### Established Patterns

- Public docs are organized by reader intent while module docs are organized by conceptual role; these are complementary, not competing taxonomies.
- Critical conventions are executable contracts with positive controls, not comments or count floors.
- The package keeps optional Phoenix/LiveView and storage integrations optional, and repository-only tooling must not appear as adopter configuration.
- Current brand authority uses calm, exact senior-engineer prose, light surfaces for documentation, a theme-aware README logo, and no unverified claims.
- The canonical example app proves adoption but does not become a second owner of installation, operator, or Docker instructions.

### Integration Points

- `mix.exs` is the convergence point for package contents, ExDoc main/extras/groups, module taxonomy, aliases, source refs, and docs hooks.
- Public-vocabulary cleanup spans `lib/`, `mix.exs`, README, CONTRIBUTING, CHANGELOG, and every packaged guide; the archive itself is the authoritative scan target.
- Canonical-home edits cross README, three owner guides, the example README, and contributor docs, so their contracts must move atomically with the prose.
- Community-health work adds root policies and `.github/ISSUE_TEMPLATE/`/PR-template files while preserving the existing workflow and ruleset files.

</code_context>

<specifics>
## Specific Ideas

- The user selected all four gray areas, explicitly delegated the decisions, and requested one cohesive recommendation after parallel specialist research, cross-ecosystem comparison, adversarial footgun review, and consideration of the entire applicable `prompts/` corpus.
- The design lenses applied were correctness, public-contract clarity, learnability, discoverability, accessibility, performance, security/privacy, compatibility, maintainability, operability, auditability, contributor burden, and brand consistency. Runtime UI/graphic redesign was intentionally excluded; documentation navigation, readable code/diagrams, focus behavior, narrow layouts, and light/dark presentation remain relevant.
- Persona/JTBD priority is: a new adopter can identify the one safe path and reach working code quickly; an experienced integrator can find exact extension/config contracts without guessing; an operator can reach the right operational guide; a contributor can reproduce and verify a change without `.planning/`; a security reporter can disclose privately; and a maintainer can evolve internals without accidental semver promises.
- Ecosystem lessons applied: Ecto and Phoenix keep first-run material concrete and beginner-friendly; Oban demonstrates explicit extension contracts and deliberate module grouping; Ash demonstrates the value of strong documentation taxonomy but also the maintenance cost of a larger multi-surface docs ecosystem; Sentry and other SDKs demonstrate why configuration/support/security routing must be explicit; successful cross-language projects separate tutorials/how-to/reference without duplicating executable instructions.
- Footguns explicitly rejected: documenting every `Application.get_env` read as public, hiding useful return structs merely to shrink the index, a miscellaneous module bucket, README/guide/example command drift, version dropdowns in issue forms, mandatory giant intake checklists, public vulnerability reports, invented email addresses, an unmonitored Discussions queue, custom docs chrome, and a pre-release API redesign disguised as documentation cleanup.

</specifics>

<deferred>
## Deferred Ideas

- A namespaced operator-surface configuration redesign, façade-only public API, or new storage callback family belongs in a future API-design phase with explicit compatibility and deprecation planning.
- A standalone documentation site, custom HexDocs theme, or multi-package docs portal is deferred until Threadline becomes a multi-package ecosystem whose documentation no longer fits one versioned ExDoc surface.
- GitHub Discussions, a separate support forum, and a dedicated private conduct inbox are deferred until each has a real monitored owner and enough traffic to justify another queue.
- Rendered operator copy/DOM/CSS provenance cleanup remains Phase 201; release/version automation and publishing remain Phase 202; Credo/layer-cycle repairs remain Phase 203; structural file splits remain Phase 204.

</deferred>

---

*Phase: 200-Public Surface*
*Context gathered: 2026-09-11*
