# Phase 191: Release/Version and Docs Trust Repair - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 191 removes public-version drift and sharpens the adoption path so a stranger can trust the README, Hex install line, evaluator docs, and upgrade story **without maintainer context**. It owns `ADOPT-01`, `ADOPT-02`, and `ADOPT-03`.

The phase reconciles every public version reference to the current `0.9.0` package truth (or explicitly justifies an older example), extends the upgrade guide to cover the 0.6.x→0.9.x adopter era, adds persona-based next-step routing over the **existing** guides, and makes doc-contract tests fail on future install/version/upgrade drift.

**In scope:** README, `guides/*.md`, `mix.exs` (`@version` is SSOT; ExDoc `docs:` config), `release-please-config.json`, `priv/ci/hex_evaluator`, doc-contract tests, and the `verify.doc_contract` / `verify.hex_evaluator` alias wiring — strictly to make current public behavior true and drift-proof.

**Out of scope (redirect to their own phases / deferred):** CI/CD measurement and pipeline efficiency (Phase 192), any guide *body* rewrite beyond version/tense/routing repair, a new standalone "start here"/"where to go next" guide (ADOPT-03 forbids a giant new guide), a full Diátaxis reorganization of guide content, capture/query/auth/semantics behavior changes, and product/UI expansion. This is a **truth-and-wayfinding** phase, not a content or product phase.

</domain>

<decisions>
## Implementation Decisions

Decisions come from four parallel advisor-research streams (version-truth, upgrade-guide shape, persona routing, drift-guard enforcement), each briefed with the concrete in-repo drift facts and the `prompts/` corpus, and each asked to weigh ecosystem lessons (Carbonite, Req, Oban, Ash, Phoenix, Ecto), DX, and pre-1.0 Hex idiom. The four recommendations were reconciled into one coherent set below; the one cross-stream tension (pin granularity × auto-injection × born-red release PRs) is resolved in **D-191-05**.

### Version-Truth Policy (ADOPT-01)

- **D-191-01:** **SSOT is `mix.exs @version` (`"0.9.0"`). Nothing else stores a version literal** except `@version` itself and immutable historical records (CHANGELOG, "landed in X" prose). Every enforced version reference derives from `@version`.
- **D-191-02:** **Install pin = three-segment `~> 0.9.0` everywhere** (not `~> 0.6`, not two-segment `~> 0.9`). `~> 0.9.0` resolves to `>= 0.9.0, < 0.10.0` — it scopes adopters to the current, tested, documented minor, which matches Threadline's own `upgrade-path.md` policy that pre-1.0 minors may carry surface-only breaking changes. Two-segment `~> 0.9` (`>= 0.9.0, < 1.0.0`) would float across future minors that may break; leaving `~> 0.6` advertises a stale, misleading floor. Precedent: Carbonite (Threadline's closest analog — Postgres-trigger audit lib) re-pins to `~> 0.X.0` each release; Req uses the same three-segment pre-1.0 convention. Post-1.0 two-segment (`~> 1.7`) is a v1.0 revisit, not now.
- **D-191-03:** **Taxonomy rule** deciding whether a version reference must equal SSOT or stay pinned:
  - **Version-truth** = "what do I install / what is current?" → MUST bind to `@version`. Enforced by the drift-guard test. Files/lines: `README.md:63`, `guides/getting-started-saas.md:26`, `guides/operator-surface.md:30`, `guides/evaluating-threadline.md:38`, `guides/adoption-evidence-playbook.md:15`, `guides/adoption-pilot-backlog.md:14` (stale hand-typed pin despite the file's auto-managed SSOT line), and the `priv/ci/hex_evaluator` dep.
  - **"Current/SSOT" prose claims** → fix the number to `0.9.0` now. Notably `guides/evaluating-threadline.md:9,11` currently claims **"0.6.0 is the in-repo, doc, and Hex SSOT (`mix.exs @version`)"** — provably false and the single worst trust bug; it must read `0.9.0`. Reframe `getting-started-saas.md:140` off the bare "(0.6.0+)" label.
  - **Historical narrative** = "when did feature X land / how do I upgrade FROM Y?" → **stays pinned** to the version it describes; changing it falsifies the record. Never touch `CHANGELOG.md` (all entries) or `guides/how-threadline-works.md:216-217`. In `guides/upgrade-path.md:5`, change present-tense "0.6.0 **packages**…" → past-tense "**landed in** 0.6.0" so it reads as history, not "current."
- **D-191-04:** **Move the guards in the same commit that changes the pins**, so CI never goes red mid-change: update `test/threadline/adoption_pilot_doc_contract_test.exs:13-16` to assert `~> 0.9.0` (and refute `~> 0.6`/`~> 0.5`), and update `mix verify.hex_evaluator`'s installed dep to `~> 0.9.0`.

### Drift-Guard Enforcement (ADOPT-01 durability + success criterion)

- **D-191-05 (resolved cross-stream tension — born-red avoidance):** Three-segment `~> 0.9.0` contains the full `0.9.0` semver string, which makes it **auto-injectable** by release-please. Therefore:
  - **Prefer auto-injection** for version-truth references, so a `@version` bump propagates without hand edits and the release PR is **not born-red** (a known project pain — see `[[release-runbook]]`). Use release-please **block annotations placed *outside* the code fence** (`<!-- x-release-please-start-version -->` … ` ```elixir {:threadline, "~> 0.9.0"} ``` ` … `<!-- x-release-please-end -->`) so nothing renders inside the copy-paste snippet. To avoid clobbering co-located deps (e.g. `ecto_sql "~> 3.10"`), the wrapped block must contain **only** the isolated `{:threadline, "~> 0.9.0"}` line — the planner isolates each threadline pin into its own minimal fenced block where a snippet currently mixes deps.
  - **For full-version prose claims** (e.g. the evaluating-threadline current-claim line), use the already-proven `<!-- x-release-please-version -->` inline marker + `release-please-config.json` `extra-files` mechanism (currently used only for `guides/adoption-pilot-backlog.md`).
  - **Test-enforcement is the safety net, not the primary mechanism.** Where a pin genuinely cannot be cleanly marked, test-enforcement is the fallback and the minor-release bump is a bounded, documented, mechanical one-liner surfaced by a precise failing message. Patch releases don't change the minor pin, so they stay green by construction.
- **D-191-06:** Add **one central `test/threadline/version_truth_doc_contract_test.exs`** that derives everything from `Threadline.MixProject.project()[:version]` (never hardcodes a version — a test that hardcodes the version is the same drift footgun it guards against). It **globs** `README.md` + `guides/**/*.md` (glob, not allowlist, so a future doc with an install snippet can't slip through) and enforces three families:
  - **Family A — install pins:** every `{:threadline, "~> x.y.z"}` equals the derived three-segment `~> #{major}.#{minor}.0`. (Derive **three-segment** to match D-191-02.)
  - **Family B — current-version prose:** only lines carrying the `x-release-please-version` marker are "live" claims and must contain `@version`. Unmarked prose is historical and ignored by default — the marker is both the release-please injection anchor and the test's enforced-line allowlist.
  - **Family C — upgrade coverage:** delegate to the upgrade-path structural test for theme/bullet checks, but assert here the **derived** "current minor is covered" check (`0.#{minor-1}.x → 0.#{minor}.x` present) since it depends on `@version`. (This currently fails — `upgrade-path.md` stops at `0.5.x → 0.6.x`.)
- **D-191-07:** **Generalize the wiring guard.** Fold `adoption_pilot_doc_contract_test.exs`'s "marker present + file listed in `extra-files`" check into the central test, asserting **every** marker-bearing doc appears in `release-please-config.json` `extra-files` — closing the "added a marker, forgot the config" gap for all docs, not just adoption-pilot. Add `guides/evaluating-threadline.md` to `extra-files` and mark only its **current-claim** line (not the historical "0.6.0 packaged Evidence" line).
- **D-191-08:** Register `version_truth_doc_contract_test.exs` (and the persona-routing test in D-191-13) in the `verify.doc_contract` alias in `mix.exs` so they run under `mix ci.all` — verification stays a product surface.

### Upgrade Guide Shape (ADOPT-02)

- **D-191-09:** **Hybrid shape**, by *extending* the existing `## Upgrade by Threadline minor` section (do not add/rename a locked top-level section — keeps `upgrade_path_doc_contract_test.exs`'s architecture intact). Three parts:
  1. A four-**theme** orientation table mapping each ADOPT-02 theme (storage-schema default, operator surface/theming, release proof lanes, migration expectations) to where it landed and the adopter action.
  2. A per-**minor** "at a glance" spine table (`0.6.x→0.7.x`, `0.7.x→0.8.x`, `0.8.x→0.9.x`) with columns: breaking? / migration required / config touch / nothing-required reassurance.
  3. Per-bump detail bullets, each ≤ ~5 lines, pointing at the `[0.7.0]`/`[0.8.0]`/`[0.9.0]` CHANGELOG anchor for the full list. Per-minor vs theme-only alone each fail half of ADOPT-02; the hybrid satisfies both axes and is independently testable.
- **D-191-10 (bounded depth / anti-bloat):** Each bump documents exactly four things — (1) breaking changes or "None", (2) required migration commands or "None", (3) config changes or "None", (4) an explicit **"nothing required"** reassurance for the `capture-only` and `phoenix-surface` lanes. Because 0.6→0.9 was overwhelmingly surface/DX/proof-lane work with no host-DB migrations, affirmative reassurance is the default answer and the single biggest trust lever (and the most common ecosystem footgun — ambiguous "should I run migrations?"). Depth beyond this defers to the CHANGELOG anchor.
- **D-191-11 (storage-schema migration block):** The only real migration-expectations callout is storage-schema under 0.9.x, phrased per Phase 190 `[[190-CONTEXT]]` **D-190-14**: *"`storage_schema` is frozen at generation time — set it before `mix threadline.install`; changing it later is deliberate migration work (move/recreate Threadline-owned tables, functions, triggers in the new schema and re-run `mix threadline.gen.triggers`), not a runtime config edit."* Keep Threadline-owned `storage_schema` distinct from host `table_schema`/`--schema` (D-190-18/21) so operators don't conflate the two. Existing adopters keep their current schema; only **new** installs pick up the `threadline` default.
- **D-191-12 (CHANGELOG vs upgrade-path division of labor — state it explicitly in the guide):** CHANGELOG = chronological, release-please-generated, **complete** (source of truth for *what shipped*). upgrade-path = curated, adopter-effect-oriented, **incomplete by design** (answers "I'm bumping N→M — must I act, and how?"). Every bump bullet links to its `[x.y.0]` anchor and never restates feature lists. A no-action change lives in CHANGELOG only and appears in the guide only inside a "nothing required" line. The upgrade-path structural doc-contract test asserts the theme axis (each ADOPT-02 keyword present), the per-minor bullets, and a `refute` on aspirational tokens (`coming soon`, `forthcoming`) and on any per-minor bullet lacking a "None"/"nothing required"/explicit action. Respect `semver_adopter_doc_contract_test.exs` — the guide speaks Hex semver only, never product-milestone `v1.3x` labels.

### Persona Routing (ADOPT-03)

- **D-191-13:** **Option C — both, divided by medium.** README `## Start here` holds the **only** persona-routing prose (a compact table); ExDoc `groups_for_extras` holds **structure only** (sidebar lanes). Keep `docs.main: "Threadline"` so the HexDocs landing *is* the README table — one prose source, zero duplication. This avoids the naive "both" drift trap (persona sentences copied into two places) by splitting on *artifact type*: README owns the words, ExDoc owns the sidebar shape.
- **D-191-14:** **Four routing personas: Evaluator / Adopter / Operator / Maintainer.** These are explicitly **distinct** from the operator-surface P1–P5 UI personas locked in `v1.31-PERSONAS-IA.md` / `ia_lock_doc_contract_test.exs` — **do not touch that test or those personas.** Canonical landing (frozen), each with a "then read" next hop:
  - Evaluator → `guides/evaluating-threadline.md` → `how-threadline-works.md` (· `domain-reference.md`)
  - Adopter (first hour) → `guides/getting-started-saas.md` → `production-checklist.md` (· `brownfield-continuity.md`)
  - Operator → `guides/operator-surface.md` → `incident-playbook.md` (· `performance.md`)
  - Maintainer → `CONTRIBUTING.md` → `upgrade-path.md` (· `adoption-pilot-backlog.md`)
- **D-191-15:** README form = a **4-row persona → start-here → then-read table** in `## Start here`; **delete the flat `## Documentation` link dump** (its links are absorbed into the table + the already-deep-linking `## Evidence plane` / `## Operator Surface` sections). This is wayfinding over existing guides — **no new prose guide**.
- **D-191-16:** ExDoc: replace the greedy flat `Reference: ~r{^guides/}` bucket in `mix.exs` `groups_for_extras` with **Evaluate / Adopt / Operate / Maintain** lanes (explicit per-lane file lists so every guide lands in exactly one lane, ordered Evaluate→Adopt→Operate→Maintain), plus retained `Overview` (README), `Integrations` (`~r{^guides/integrations/}`), and `Project` (CONTRIBUTING/CHANGELOG). `groups_for_modules` unchanged.
- **D-191-17:** Add `test/threadline/persona_routing_doc_contract_test.exs` (wired into `verify.doc_contract`): for each of the 4 personas assert (a) README `## Start here` contains the lane label + its canonical landing link, and (b) `Mix.Project.config()[:docs][:groups_for_extras]` contains the four lane keys. Add a `refute` on a standalone `guides/where-to-go-next.md`/`guides/start-here.md` to enforce "no giant new guide."

### Claude's Discretion

Downstream agents may choose exact regex/parsing in the doc-contract tests, per-file isolation of threadline pins into their own fenced blocks (D-191-05), the precise wording of the upgrade-guide theme table and reassurance bullets, and test module/helper organization. They must preserve the locked contracts: `~> 0.9.0` three-segment pins bound to `@version`; version-truth vs historical-narrative taxonomy (never falsify history); born-red-avoiding auto-injection preferred over hand edits; hybrid upgrade shape covering both theme and minor axes with mandatory "nothing required" callouts; Option-C persona routing (README prose + ExDoc structure, one source); no new guide; no scope creep into Phase 192 CI work or guide-body rewrites.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` — Phase 191 goal, success criteria, and v1.39 sequencing.
- `.planning/REQUIREMENTS.md` — `ADOPT-01`, `ADOPT-02`, `ADOPT-03` and v1.39 out-of-scope boundaries.
- `.planning/PROJECT.md` — v1.39 posture (quality-baseline pass, not product/UI expansion) and the 0.6→0.9 / v1.34→v1.39 milestone history that the upgrade guide narrates.
- `.planning/STATE.md` — active phase state; Hex distribution truth (latest `0.9.0`, tag `v0.9.0`).
- `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md` — storage-schema decisions D-190-11..15, 18, 21, 23 that the upgrade-guide storage-schema block (D-191-11) must phrase faithfully.
- `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-CONTEXT.md` — authority hierarchy, triage taxonomy, no-scope-creep rules (executable proof beats stale prose; residuals visible not relabeled green).

### Version Truth, Pins, and Release Automation

- `mix.exs` — `@version` (SSOT), ExDoc `docs:` config (`main`, `extras`, `groups_for_extras`), and the `verify.doc_contract` / `verify.hex_evaluator` / `ci.all` aliases.
- `README.md` — `:63` install pin (version-truth), `## Start here` (persona routing target), `## Documentation` (flat dump to delete), `## Evidence plane` / `## Operator Surface` (already deep-link guides).
- `release-please-config.json` — `extra-files` (currently only `guides/adoption-pilot-backlog.md`); expand per D-191-05/07.
- `.release-please-manifest.json` — release-please version manifest (inspect for wiring).
- `priv/ci/hex_evaluator` — installs `{:threadline, "~> 0.6"}`; move to `~> 0.9.0` (D-191-04).

### Guides in Scope

- `guides/evaluating-threadline.md` — `:9,:11` false "0.6.0 is SSOT" claim (fix to 0.9.0 + mark current-claim line), `:38` pin.
- `guides/getting-started-saas.md` — `:26` pin, `:140` "(0.6.0+)" reframe.
- `guides/operator-surface.md` — `:30` pin; also Operator persona canonical landing.
- `guides/adoption-evidence-playbook.md` — `:15` pin.
- `guides/adoption-pilot-backlog.md` — `:7,:13` auto-managed SSOT lines (0.9.0, leave), `:14` stale hand-typed pin (fix).
- `guides/upgrade-path.md` — extend `## Upgrade by Threadline minor` for 0.6.x→0.9.x (D-191-09..12); tense fix at `:5`; do not rename locked sections.
- `guides/how-threadline-works.md` — `:216-217` historical prose (do NOT touch).
- `CHANGELOG.md` — `[0.6.0]`/`[0.7.0]`/`[0.8.0]`/`[0.9.0]` anchors the upgrade guide links to; immutable history, never edit for version truth.
- Persona "then read" guides: `guides/how-threadline-works.md`, `guides/domain-reference.md`, `guides/production-checklist.md`, `guides/brownfield-continuity.md`, `guides/incident-playbook.md`, `guides/performance.md`, `guides/adoption-pilot-backlog.md`, `CONTRIBUTING.md`, `guides/integrations/`.

### Existing Doc-Contract Tests (pattern to extend / guards to move)

- `test/threadline/adoption_pilot_doc_contract_test.exs` — dynamic `@version` derivation + marker/extra-files wiring guard (the winning pattern to generalize); `:13` pin assertion to update.
- `test/threadline/semver_adopter_doc_contract_test.exs` — Hex-semver-only guard (no product-milestone labels); must keep passing.
- `test/threadline/upgrade_path_doc_contract_test.exs` — upgrade-path structural contract to extend for theme/minor axes.
- `test/threadline/readme_doc_contract_test.exs`, `test/threadline/evaluating_threadline_doc_contract_test.exs`, `test/threadline/getting_started_saas_doc_contract_test.exs`, `test/threadline/how_threadline_works_doc_contract_test.exs`, `test/threadline/exploration_routing_doc_contract_test.exs`, `test/threadline/ia_lock_doc_contract_test.exs` (do NOT touch — operator UI personas), `test/threadline/release_distribution_doc_contract_test.exs`, `test/threadline/release_artifact_contract_test.exs`.
- New: `test/threadline/version_truth_doc_contract_test.exs`, `test/threadline/persona_routing_doc_contract_test.exs`.

### Prompt Corpus and External Primary Sources

- `prompts/threadline-elixir-oss-dna.md` — verification-as-product-surface, doc contracts lock README↔guides↔example, version SSOT + release-please alignment, "docs say A / Hex says B" avoidance, required ExDoc extras incl. upgrade/migration guides, changelog-as-maturity-signal.
- `prompts/audit-lib-domain-model-reference.md` — personas/JTBD (who/what/why) grounding the four routing personas and the capture/semantics/operations layering.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — HexDocs structure, versioning/upgrade-guide conventions, extras/groups.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — deliberate migrations posture (backs D-191-11).
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — Carbonite audit-lib seriousness (explicit prefix/migration, not hidden magic).
- `brandbook/` — newer voice/microcopy reference if any user-facing copy is touched (prefer over old prompt-era brand material).
- Ecosystem primary sources cited by researchers: Carbonite READMEs/Hex (`~> 0.X.0` per-release re-pin), Req (`~> 0.5.0`), Oban per-version upgrade guides + grouped `groups_for_extras`, Ash Diátaxis extras grouping, Phoenix grouped guides + curated upgrade notes, release-please `customizing.md` (block/inline version annotations).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `test/threadline/adoption_pilot_doc_contract_test.exs` already derives `@version Threadline.MixProject.project()[:version]` and guards both the `x-release-please-version` marker and its `extra-files` registration — the exact pattern to centralize (D-191-06/07). Drift happened only because it was applied to 1 of ~30 doc tests.
- `release-please-config.json` `extra-files` + `<!-- x-release-please-version -->` already works on `adoption-pilot-backlog.md` (the only correct doc) — proven mechanism to extend.
- `mix.exs` already exposes `verify.doc_contract` / `verify.hex_evaluator` / `ci.all` aliases and an ExDoc `docs:` block with `main`/`extras`/`groups_for_extras` — the seams for both routing and enforcement.
- `guides/upgrade-path.md` already has the right section skeleton (compatibility matrix, "Upgrade by minor", "What breaks when floors move", release checklist) — only the 0.6→0.9 era content is missing.

### Established Patterns

- Verification is a product surface: named `mix verify.*` / `mix ci.*` entrypoints; new tests must be wired into them (D-191-08).
- Doc contracts lock public adoption promises; hardcoding the version in tests is the anti-pattern — derive from `@version`.
- Release-please owns version bumps; born-red release PRs are a known pain (`[[release-runbook]]`) — auto-injection is preferred over hand-maintained version strings (D-191-05).
- History is immutable: CHANGELOG and "landed in X" prose stay pinned; only "current" claims track `@version`.

### Integration Points

- README `## Start here` (prose) ↔ `mix.exs` `groups_for_extras` (structure) bound by `persona_routing_doc_contract_test.exs`, sharing one source via `docs.main: "Threadline"`.
- `upgrade-path.md` ↔ `CHANGELOG.md` via `[x.y.0]` anchors; division of labor stated in-guide (D-191-12).
- Pin changes must land with their guards (`adoption_pilot_doc_contract_test.exs`, `verify.hex_evaluator`, `priv/ci/hex_evaluator`) in the same commit (D-191-04) so CI stays green.
- `version_truth_doc_contract_test.exs` globs README + guides so future docs are covered without per-doc wiring.

</code_context>

<specifics>
## Specific Ideas

- User requested full subagent-backed research across all four gray areas (architecture/SWE/DevOps/SRE, ecosystem prior art, DX, API-consumer/JTBD, UI/UX where applicable) and a single coherent one-shot recommendation set — delivered via four parallel `gsd-advisor-researcher` agents, reconciled here. Consistent with `[[gsd-research-then-recommend]]`.
- Decisive ecosystem anchors the planner should preserve:
  - **Pin:** Carbonite (direct analog) re-pins `~> 0.X.0` each release; Req uses `~> 0.5.0`. Pre-1.0 three-segment is the honest current-minor signal; post-1.0 two-segment is a v1.0 revisit.
  - **Upgrade guide:** Oban's per-version "Upgrading to vX.Y" skeleton (bump deps → migration command → config → "optional/nothing required"); Carbonite's freeze-at-generation prefix validates D-191-11; Phoenix's curated upgrade notes + complete CHANGELOG validate D-191-12.
  - **Routing:** Oban grouped `groups_for_extras`; Ash Diátaxis lanes; Phoenix grouped guides; Diátaxis (route by reader intent, don't write a new guide).
  - **Drift-guard:** read-`Mix.Project.config()[:version]`-in-tests is idiomatic Elixir; release-please block/inline annotations are the canonical single-SSOT-plus-injection mechanism; hardcoding the version in N places (docs *and* the guarding tests) is the cited footgun.
- Latent drift the guard surfaces immediately: `evaluating-threadline.md:11` falsely claims 0.6.0 is `@version`; `upgrade-path.md` has no current-minor bullet. Fixing these is the acceptance proof the guard works.
- No newer brandbook copy conflict arose (this phase touches routing/version text, not brand copy); if guide microcopy is edited, prefer `brandbook/` over prompt-era brand material.

</specifics>

<deferred>
## Deferred Ideas

- **CI/CD measurement and pipeline efficiency** → Phase 192 (`CI-01..04`). Out of scope here.
- **Guide-body content rewrites** beyond version/tense/routing repair → not this phase; wayfinding and truth only.
- **A standalone "start here"/"where to go next" guide** → forbidden by ADOPT-03; actively `refute`-tested (D-191-17).
- **Full Diátaxis reorganization of guide content** → deferred; Phase 191 only groups existing guides into ExDoc lanes.
- **Post-1.0 two-segment pin convention** (`~> 1.0`) → revisit at the 1.0 release; pre-1.0 stays three-segment (D-191-02).
- **Auto-injecting install pins that share a fenced block with other deps** → planner isolates threadline pins into their own blocks where clean; otherwise those specific pins fall back to test-enforcement (D-191-05). Not a scope expansion, just an implementation choice.
- No todo artifacts matched Phase 191 (`todo.match-phase 191` → 0), so none were folded or reviewed.

### Reviewed Todos (not folded)

None — no todos matched this phase.

</deferred>

---

*Phase: 191-release-version-and-docs-trust-repair*
*Context gathered: 2026-07-02*
