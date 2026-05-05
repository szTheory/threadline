# Phase 48: threadline-0.3.0-release - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Package and present the v1.14 adopter slice as `threadline 0.3.0`: version bump, changelog, README install/version routing, ExDoc extras and module grouping, maintainer publish runbook, and a release pre-flight alias that catches packaging drift before tagging. This phase does **not** add new runtime capture or semantics behavior; it turns Phases 44-47 into a coherent, publishable release surface.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<specifics>
## Specific Ideas

- Suggested top-line release sentence: `Threadline 0.3.0 is the drop-in production adoption release for Phoenix SaaS teams: Sigra-ready actor mapping, a first-hour SaaS quickstart, operator incident recipes, and published performance guidance.`
- README routing should bias toward adopter success, not exhaustiveness. A reader should quickly understand:
  - how to install `~> 0.3`
  - where to follow the first working path
  - where to go if they use Sigra
- The release pre-flight should feel like a packaging checksum for humans: "is this exact tree taggable and publishable?" not "does the whole repo pass every test we have?"
- User workflow preference to preserve if helpful in future GSD conversations: for low- and medium-impact packaging/docs decisions, prefer internal recommendation-first synthesis over interactive option picking; only escalate very impactful product-facing choices.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Release Contract
- `.planning/ROADMAP.md` — Phase 48 goal and success criteria.
- `.planning/REQUIREMENTS.md` — REL-01, REL-02, REL-03; the required `0.3.0` release surfaces and exclusions.
- `.planning/STATE.md` — current milestone status and sequencing context for 44 → 48.

### Upstream Phase Outputs Being Packaged
- `.planning/phases/44-sigra-integration-adapter/44-CONTEXT.md` — locked Sigra integration wiring and docs intent.
- `.planning/phases/45-bench-harness-published-baselines/45-VERIFICATION.md` — performance baseline artifact expectations and bench verification posture.
- `.planning/phases/46-incident-playbook-replay-script/46-VERIFICATION.md` — incident playbook and replay-script verification evidence.
- `.planning/phases/47-saas-adopter-onramp/47-CONTEXT.md` — SaaS quickstart positioning, closing links, and doc-contract expectations.

### Release Surfaces to Modify
- `mix.exs` — `@version`, aliases, ExDoc extras, `groups_for_extras`, `groups_for_modules`, package files.
- `CHANGELOG.md` — `0.3.0` section and `### Upgrade from 0.2.x`.
- `README.md` — install snippet and adopter-facing routing.
- `CONTRIBUTING.md` — maintainer publish runbook and `verify.release` guidance.
- `.github/workflows/ci.yml` — existing docs / hex-package / release-shape jobs that define the release hygiene baseline.
- `.github/workflows/hex-publish.yml` — tag-to-version publish contract.
- `bin/verify-release-shape` — current release metadata checker to incorporate into `verify.release`.

### New/Existing Guides That Define the Story
- `guides/getting-started-saas.md` — first-hour adopter path; highest-priority README route target.
- `guides/integrations/sigra.md` — best-supported auth bridge; integration route target.
- `guides/performance.md` — performance evidence used to support the release narrative.
- `guides/incident-playbook.md` — operator-facing incident story used to support the release narrative.
- `guides/production-checklist.md` — operational handoff surface linked from the quickstart.

### Existing Contract Tests and Patterns
- `test/threadline/readme_doc_contract_test.exs` — README literal-locking pattern.
- `test/threadline/getting_started_saas_doc_contract_test.exs` — guide-presence and routing pattern.
- `test/threadline/performance_doc_contract_test.exs` — structure-only contract style for drift-prone evidence docs.
- `test/threadline/integrations/sigra_doc_contract_test.exs` — integration-guide contract style.
- `test/threadline/incident_playbook_doc_contract_test.exs` — operator-guide contract style.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/verify-release-shape` already validates `mix.exs @version` ↔ dated `CHANGELOG.md` alignment; `verify.release` should build on this rather than replacing it.
- The repo already has a strong doc-contract testing idiom (`File.read!` + literal assertions + narrow structural checks). Phase 48 should extend that pattern with a release-artifact contract instead of inventing a different validation style.
- `mix.exs` already separates `ci.all`, `verify.example`, and `verify.bench`; this gives a clear precedent for a narrow, purpose-built `verify.release`.

### Established Patterns
- ExDoc extras and grouping are already first-class in `mix.exs`; Phase 48 is about correcting the information architecture, not introducing ExDoc as a new concept.
- The CI workflow already treats docs build, hex tarball shape, and release metadata as separate concerns. `verify.release` should mirror that composition locally.
- Existing release docs already assume explicit maintainer steps and named gates rather than hidden publish automation.

### Integration Points
- `mix.exs` alias table is the primary insertion point for `verify.release`.
- `CONTRIBUTING.md` maintainer sections are the primary place to document the release pre-flight and tagging flow.
- `README.md` plus its contract test are the primary place to adjust release discoverability without destabilizing deeper guides.
- A new `test/threadline/release_artifact_contract_test.exs` is the natural home for the package-files / docs-extras / guides-on-disk consistency check mandated by REL-02.

</code_context>

<deferred>
## Deferred Ideas

- Add a standalone upgrade guide such as `guides/upgrading-to-0.3.md` if the `CHANGELOG.md` `### Upgrade from 0.2.x` section proves too cramped. Current recommendation: keep the upgrade path in the changelog for `0.x`.
- Broader README expansion for performance and incident-response guides if real adopters still miss those surfaces after `0.3.0`. Current recommendation: do not overload the README yet.
- General GSD workflow change to default toward internal recommendation-first discussion for low/medium-impact choices across the whole system. Captured as a user preference, but out of scope for Phase 48 implementation itself.

</deferred>

---

*Phase: 48-threadline-0.3.0-release*
*Context gathered: 2026-05-05*
