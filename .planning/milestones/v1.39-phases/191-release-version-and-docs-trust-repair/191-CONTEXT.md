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

Decisions come from four parallel advisor-research streams (version-truth, upgrade-guide shape, persona routing, drift-guard enforcement), each briefed with the concrete in-repo drift facts and the `prompts/` corpus, and each asked to weigh ecosystem lessons (Carbonite, Req, Oban, Ash, Phoenix, Ecto), DX, and pre-1.0 Hex idiom. The recommendations were reconciled into one coherent set below.

**Validation round (2026-07-02):** three of these decisions — pin granularity (D-191-02), injection/born-red mechanism (D-191-05), and persona routing (D-191-13..17) — were then **adversarially pressure-tested** by three further researchers instructed to overturn them. Outcomes, folded in below: **D-191-02 REAFFIRMED** (+ new backport-policy refinement D-191-02a); **D-191-05 OVERTURNED** at the source level (release-please's generic updater has no sticky `major.minor.0` scope — injecting the *pin* born-reds every *patch* release; pins are now test-enforced-only, prose stays injected); **D-191-13..17 OVERTURNED (targeted)** — persona *nouns* → intent *verbs* (Evaluate/Adopt/Operate/Contribute), and the flat index is *replaced with a collapsed `<details>` index* rather than deleted.

### Version-Truth Policy (ADOPT-01)

- **D-191-01:** **SSOT is `mix.exs @version` (`"0.9.0"`). Nothing else stores a version literal** except `@version` itself and immutable historical records (CHANGELOG, "landed in X" prose). Every enforced version reference derives from `@version`.
- **D-191-02:** **Install pin = three-segment `~> 0.9.0` everywhere** (not `~> 0.6`, not two-segment `~> 0.9`). `~> 0.9.0` resolves to `>= 0.9.0, < 0.10.0` — it scopes adopters to the current, tested, documented minor, which matches Threadline's own `upgrade-path.md` policy that pre-1.0 minors may carry surface-only breaking changes. Two-segment `~> 0.9` (`>= 0.9.0, < 1.0.0`) would float across future minors that may break; leaving `~> 0.6` advertises a stale, misleading floor. Precedent: Carbonite (Threadline's closest analog — Postgres-trigger audit lib) re-pins to `~> 0.X.0` each release (currently `~> 0.16.1`); Req uses the same three-segment pre-1.0 convention. Post-1.0 two-segment (`~> 1.7`) is a v1.0 revisit, not now. **Validation:** adversarial review confirmed 0.6→0.9 had *no host-breaking change* (all surface/DX/proof-lane work) — so the tight pin is prospective insurance (SemVer-0.x license to break + an operator-surface public contract that *did* move floors at 0.4.0), not retrospective necessity; `mix.lock` is the real currency control, and the pin only constrains what a *deliberate* `mix deps.update` may select. Two-segment `~> 0.9` is also **not** release-please-injectable (no full semver token on the line) — a second reason to keep three-segment.
- **D-191-02a (backport policy — new, from validation):** Close the tight-pin's only real gap (a fix that lands *only* in a future minor would be missed by a `~> 0.9.0` pin on auto-update) with an explicit maintainer commitment: **"Security and critical fixes are backported as patch releases on the current minor (e.g. `0.9.1`), which any `~> 0.9.0` pin picks up automatically; crossing a minor stays a deliberate, changelog-reading act."** State this once in `guides/upgrade-path.md` and once in `CONTRIBUTING.md`. This converts the theoretical risk into policy so an install-once audit adopter is never stranded on an unpatched line by the pin alone.
- **D-191-03:** **Taxonomy rule** deciding whether a version reference must equal SSOT or stay pinned:
  - **Version-truth** = "what do I install / what is current?" → MUST bind to `@version`. Enforced by the drift-guard test. Files/lines: `README.md:63`, `guides/getting-started-saas.md:26`, `guides/operator-surface.md:30`, `guides/evaluating-threadline.md:38`, `guides/adoption-evidence-playbook.md:15`, `guides/adoption-pilot-backlog.md:14` (stale hand-typed pin despite the file's auto-managed SSOT line), and the `priv/ci/hex_evaluator` dep.
  - **"Current/SSOT" prose claims** → fix the number to `0.9.0` now. Notably `guides/evaluating-threadline.md:9,11` currently claims **"0.6.0 is the in-repo, doc, and Hex SSOT (`mix.exs @version`)"** — provably false and the single worst trust bug; it must read `0.9.0`. Reframe `getting-started-saas.md:140` off the bare "(0.6.0+)" label.
  - **Historical narrative** = "when did feature X land / how do I upgrade FROM Y?" → **stays pinned** to the version it describes; changing it falsifies the record. Never touch `CHANGELOG.md` (all entries) or `guides/how-threadline-works.md:216-217`. In `guides/upgrade-path.md:5`, change present-tense "0.6.0 **packages**…" → past-tense "**landed in** 0.6.0" so it reads as history, not "current."
- **D-191-04:** **Move the guards in the same commit that changes the pins**, so CI never goes red mid-change: update `test/threadline/adoption_pilot_doc_contract_test.exs:13-16` to assert `~> 0.9.0` (and refute `~> 0.6`/`~> 0.5`), and update `mix verify.hex_evaluator`'s installed dep to `~> 0.9.0`.

### Drift-Guard Enforcement (ADOPT-01 durability + success criterion)

- **D-191-05 (OVERTURNED by source-level validation — split the mechanism by reference type):** The original plan preferred auto-injecting *all* version-truth references (including pins) via release-please block annotations. Reading release-please's `src/updaters/generic.ts` overturned this: the updater's `VERSION_REGEX` requires **three segments** and the `version` scope always writes the **full `major.minor.patch`** — there is **no scope that yields a sticky `major.minor.0`**. So injecting the *pin* would rewrite `~> 0.9.0` → `~> 0.9.1` on a **patch** release (`0.9.0→0.9.1`), while the drift-guard (D-191-06 Family A) derives `~> 0.9.0` → **born-red on every patch release** (the common case) — the exact inverse of the goal. `{literal ~> 0.9.0 pin, pin-injection, .0-derivation}` is an irreconcilable triangle; the member to drop is **pin-injection**. Resolution, split by reference type:
  - **Full-version PROSE claims** (the "current/SSOT" lines, the adoption-pilot SSOT line, the evaluating-threadline current-claim line, any "Hex latest is X"): **auto-inject** — reaffirmed. Use the proven `<!-- x-release-please-version -->` inline marker (or block markers **outside** any code fence) + the file registered in `release-please-config.json` `extra-files`. Born-red-proof by identity: enforced set (marker lines) ≡ injected set (marker lines in extra-files), both write/expect the full `@version`. Patch and minor both green by construction. This is exactly the working `adoption-pilot-backlog.md` mechanism.
  - **Install PINS** `{:threadline, "~> 0.9.0"}`: **test-enforced only — never marker-injected.** D-191-06 Family A globs README + `guides/**/*.md` and asserts every pin equals the derived three-segment `~> #{major}.#{minor}.0` (sticky `.0`). **Patch releases are green by construction** (pin stays `~> 0.9.0`, derivation stays `~> 0.9.0`, no injection). **Minor releases** (rare, and already human-in-the-loop because D-191-09's upgrade-guide extension must be written for that release) bump the `.0` pins in the same PR; the failing Family A message names the exact edit — a bounded one-liner, scoped to minors only, never patches.
  - **Dropped from the plan:** "prefer auto-injecting the pin via block annotations" and "isolate each threadline pin into its own minimal fenced block." Both are unnecessary — co-located deps here are all two-segment (e.g. `ecto_sql "~> 3.10"`) which `VERSION_REGEX` never matches, and the actual README/getting-started snippets already show `threadline` alone. **Keep the natural multi-dep snippets untouched**; no markers enter any deps fence, so least-surprise is preserved with zero DX cost.
  - **Rejected alternatives:** a custom `mix` sync task, a CI grep-guard, or an auto-fix bot commit all push a commit onto the `release-please--branches--main` branch — the stale/force-update fragility the release runbook already documents (`[[release-runbook]]`) — to solve a *rare, already-human-gated* minor bump. The derive-test's precise failure message **is** the guard.
- **D-191-06:** Add **one central `test/threadline/version_truth_doc_contract_test.exs`** that derives everything from `Threadline.MixProject.project()[:version]` (never hardcodes a version — a test that hardcodes the version is the same drift footgun it guards against). It **globs** `README.md` + `guides/**/*.md` (glob, not allowlist, so a future doc with an install snippet can't slip through) and enforces three families:
  - **Family A — install pins:** every `{:threadline, "~> x.y.z"}` equals the derived three-segment `~> #{major}.#{minor}.0`. (Derive **three-segment** to match D-191-02.) The `.0` derivation is load-bearing: it is exactly what keeps **patch** releases green-by-construction (pin and derivation both stay `~> 0.9.0` through `0.9.x`), per the D-191-05 split. Pins are **not** injected — this test is their sole enforcement.
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
- **D-191-12a (backport policy placement — from validation):** The `guides/upgrade-path.md` extension must include the D-191-02a backport-policy sentence (patch-backport on the current minor; minor-crossing is deliberate). It fits naturally near the compatibility matrix / "which lane you are on" framing and reinforces why the `~> 0.9.0` pin is safe. Mirror the same sentence in `CONTRIBUTING.md`.

### Routing (ADOPT-03) — validated: intent verbs, not persona nouns

Adversarial validation kept the four-way cut, Option-C medium split, and canonical landings, but **overturned the persona-*noun* framing** (it contradicted the decision's own verb-labeled sidebar, is unidiomatic for Elixir libs — Oban/Phoenix/Ash all use intent/topic-grouped extras, none use persona-noun tables — and collided with the locked operator-UI persona P4 "Audit Operator"). It also softened the "delete the flat index" move.

- **D-191-13:** **Option C — both, divided by medium.** README `## Start here` holds the **only** routing prose (an intent table); ExDoc `groups_for_extras` holds **structure only** (sidebar lanes). Keep `docs.main: "Threadline"` so the HexDocs landing *is* the README — one prose source, zero duplication. Split on *artifact type*: README owns the words, ExDoc owns the sidebar shape.
- **D-191-14 (reframed to intent VERBS):** Four routing lanes: **Evaluate / Adopt / Operate / Contribute** (verbs, not the nouns Evaluator/Adopter/Operator/Maintainer). Rationale: the *jobs* are genuinely distinct (Evaluate = "does it fit, no code yet" vs Adopt = "install + capture one write" — do **not** merge; Integrator folds into **Adopt** as a second hop, not a fifth lane; a would-be contributor is not yet a "Maintainer", so the verb **Contribute** is the honest label). Verbs also disambiguate from the locked operator-UI P4 "Audit Operator" persona. Still **distinct** from and **must not touch** the P1–P5 UI personas in `v1.31-PERSONAS-IA.md` / `ia_lock_doc_contract_test.exs`. Canonical landing (frozen) + "then read" next hop:
  - Evaluate → `guides/evaluating-threadline.md` → `how-threadline-works.md`
  - Adopt → `guides/getting-started-saas.md` → `production-checklist.md`
  - Operate → `guides/operator-surface.md` → `incident-playbook.md`
  - Contribute → `CONTRIBUTING.md` → `guides/adoption-pilot-backlog.md` (release/distribution — **not** `upgrade-path.md`, which is adopter-facing and moves to the Adopt lane)
- **D-191-15 (softened — replace, don't delete):** README `## Start here` = a 3-column **"I want to… / Start here / Then read"** intent table (row copy from D-191-14). **Replace** the flat `## Documentation` dump with a collapsed `<details><summary>All guides</summary>` index grouped by the four verbs — this preserves GitHub-reader discoverability of the ~10 guides not in the table (audit-indexing, local-docker-dx, adoption-evidence-playbook, domain-reference, etc.) while staying a shorter next-step path. A `<details>` index is **not** a new prose guide, so ADOPT-03 and the D-191-17 `refute` still hold. **Label, don't rewrite:** the Adopt row says "Wire it into a Phoenix app" (the `getting-started-saas.md` body stays SaaS-titled — guide-body renames are out of Phase 191 scope).
- **D-191-16 (verb lanes):** Replace the greedy flat `Reference: ~r{^guides/}` bucket in `mix.exs` `groups_for_extras` with **Evaluate / Adopt / Operate / Contribute** lanes (explicit per-lane file lists, every extra in exactly one lane), plus retained `Overview` (README) and `Integrations` (`~r{^guides/integrations/}`). Lane placement of note: `upgrade-path.md` → **Adopt**; `adoption-evidence-playbook.md` → **Operate**; `CONTRIBUTING.md` + `adoption-pilot-backlog.md` + `CHANGELOG.md` → **Contribute** (replaces the old `Project` bucket). Sidebar lane names now **equal** the README column intents — removing the locked design's README-noun ≠ sidebar-verb inconsistency. `groups_for_modules` unchanged.
- **D-191-17:** Add `test/threadline/persona_routing_doc_contract_test.exs` (wired into `verify.doc_contract`): for each of the four **verb** lanes assert (a) README `## Start here` contains the lane label + its canonical landing link, and (b) `Mix.Project.config()[:docs][:groups_for_extras]` contains the four lane keys (`Evaluate`/`Adopt`/`Operate`/`Contribute`) — a cleaner contract than the noun version because the same four labels now hold on both surfaces. `refute` a standalone `guides/where-to-go-next.md`/`guides/start-here.md`.
- **D-191-18 (row microcopy — brand voice):** Table/one-liner copy follows `brandbook/brand-book.md` voice (active, plainspoken, boundaries explicit, no "powerful/seamless", no exclamation marks) and names concrete surfaces. Reference copy: Evaluate — "See what Threadline proves in-repo, and what you must prove in staging."; Adopt — "Install, capture one real write, and mount the operator surface in the first hour."; Operate — "Investigate row changes, actor history, and evidence in the `/audit` console."; Contribute — "Set up the repo, run `mix ci.all`, and follow the contribution gate." Planner may refine but must keep the voice and the concrete-surface anchors.

### Claude's Discretion

Downstream agents may choose exact regex/parsing in the doc-contract tests, the precise wording of the upgrade-guide theme table / reassurance bullets / backport sentence, the exact `<details>` index formatting, and test module/helper organization. They must preserve the locked contracts: `~> 0.9.0` three-segment pins bound to `@version`; **pins test-enforced only, prose claims auto-injected** (D-191-05 — never marker-inject a pin; keep natural multi-dep snippets); version-truth vs historical-narrative taxonomy (never falsify history); the D-191-02a backport policy; hybrid upgrade shape covering both theme and minor axes with mandatory "nothing required" callouts; Option-C routing with **intent-verb lanes** (Evaluate/Adopt/Operate/Contribute) matching README ↔ sidebar; replace-not-delete the flat index; no new guide; do not touch the P1–P5 operator-UI personas; no scope creep into Phase 192 CI work or guide-body rewrites.

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
- `README.md` — `:63` install pin (test-enforced, not injected), `## Start here` (intent-table target), `## Documentation` (`:187-204` flat dump to **replace** with a collapsed `<details>` index, not delete), `## Evidence plane` / `## Operator Surface` (already deep-link guides).
- `release-please-config.json` — `:17-19` `extra-files` (currently only `guides/adoption-pilot-backlog.md`); expand **only** for full-version prose-claim files (D-191-07). **Do NOT add pin snippets** — the generic updater has no sticky `.0` scope and would born-red every patch release (D-191-05).
- `.release-please-manifest.json` — release-please version manifest (inspect for wiring).
- `priv/ci/hex_evaluator` — installs `{:threadline, "~> 0.6"}`; move to `~> 0.9.0` (D-191-04).

### Guides in Scope

- `guides/evaluating-threadline.md` — `:9,:11` false "0.6.0 is SSOT" claim (fix to 0.9.0 + mark current-claim line), `:38` pin.
- `guides/getting-started-saas.md` — `:26` pin, `:140` "(0.6.0+)" reframe.
- `guides/operator-surface.md` — `:30` pin; also Operator persona canonical landing.
- `guides/adoption-evidence-playbook.md` — `:15` pin.
- `guides/adoption-pilot-backlog.md` — `:7,:13` auto-managed SSOT lines (0.9.0, leave), `:14` stale hand-typed pin (fix).
- `guides/upgrade-path.md` — extend `## Upgrade by Threadline minor` for 0.6.x→0.9.x (D-191-09..12); add the D-191-02a/12a backport-policy sentence; tense fix at `:5`; do not rename locked sections. Adopt-lane guide in the routing sidebar.
- `CONTRIBUTING.md` — Contribute-lane canonical landing (D-191-14); add the mirrored D-191-02a backport-policy sentence.
- `brandbook/brand-book.md` — voice + UX-microcopy source for the D-191-18 routing-table row copy (prefer over old prompt-era brand material).
- `guides/how-threadline-works.md` — `:216-217` historical prose (do NOT touch).
- `CHANGELOG.md` — `[0.6.0]`/`[0.7.0]`/`[0.8.0]`/`[0.9.0]` anchors the upgrade guide links to; immutable history, never edit for version truth.
- Routing "then read" + `<details>`-index guides: `guides/how-threadline-works.md`, `guides/domain-reference.md`, `guides/production-checklist.md`, `guides/brownfield-continuity.md`, `guides/integration-contracts.md`, `guides/incident-playbook.md`, `guides/performance.md`, `guides/audit-indexing.md`, `guides/adoption-evidence-playbook.md`, `guides/local-docker-dx.md`, `guides/adoption-pilot-backlog.md`, `guides/integrations/`.

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
- Release-please owns version bumps; born-red release PRs are a known pain (`[[release-runbook]]`). Source-validated split (D-191-05): **prose** full-version claims are auto-injected (born-red-proof); **pins** are test-enforced with `.0` derivation (patch releases green by construction; never inject a pin — the generic updater has no sticky `.0` scope and would born-red every patch).
- History is immutable: CHANGELOG and "landed in X" prose stay pinned; only "current" claims track `@version`.

### Integration Points

- README `## Start here` (prose) ↔ `mix.exs` `groups_for_extras` (structure) bound by `persona_routing_doc_contract_test.exs`, sharing one source via `docs.main: "Threadline"`.
- `upgrade-path.md` ↔ `CHANGELOG.md` via `[x.y.0]` anchors; division of labor stated in-guide (D-191-12).
- Pin changes must land with their guards (`adoption_pilot_doc_contract_test.exs`, `verify.hex_evaluator`, `priv/ci/hex_evaluator`) in the same commit (D-191-04) so CI stays green.
- `version_truth_doc_contract_test.exs` globs README + guides so future docs are covered without per-doc wiring.

</code_context>

<specifics>
## Specific Ideas

- User requested full subagent-backed research across all four gray areas (architecture/SWE/DevOps/SRE, ecosystem prior art, DX, API-consumer/JTBD, UI/UX where applicable) and a single coherent one-shot recommendation set — delivered via four parallel `gsd-advisor-researcher` agents, reconciled here. Consistent with `[[gsd-research-then-recommend]]`. On a follow-up `--update` pass the user asked to **adversarially pressure-test** the three most opinionated decisions (pin granularity, injection/born-red, routing) — three more researchers reaffirmed D-191-02 (+ backport refinement) and overturned D-191-05 (source-level) and D-191-13..17 (verbs + collapsed index). This CONTEXT reflects the post-validation decisions.
- Validation evidence worth preserving for the planner:
  - **release-please `generic.ts` (read at source):** `VERSION_REGEX` requires three segments; `version` scope always writes full `major.minor.patch`; no scope yields a sticky `major.minor.0`; replacement is per-line first-match-only; two-segment tokens (`~> 3.10`) never match, so wrapping a natural deps block does not clobber co-located two-segment deps. This is the proof behind the D-191-05 pins-are-test-enforced split.
  - **Carbonite currently pins `~> 0.16.1`** (re-pinned each release) — the live precedent for three-segment. Req (`~> 0.5.0` while latest is 0.6.1) and PaperTrail (`~> 0.14.3` while at 1.0.0) are the *stale three-segment* cautionary tales that Threadline's auto-injected prose + globbing pin test prevent.
  - **CHANGELOG audit 0.6→0.9:** zero host-breaking changes (surface/DX/proof-lane only); the one real surface-only floor move was 0.4.0 (Phoenix/LiveView dep ranges) — so tight-pin is prospective insurance, and D-191-10's "nothing required" default is factually correct.
  - **Routing idiom:** Oban/Phoenix/Ash `groups_for_extras` are intent/topic lanes; none use a persona-noun table — backs the verb reframe (D-191-14).
- Decisive ecosystem anchors the planner should preserve:
  - **Pin:** Carbonite (direct analog) re-pins `~> 0.X.0` each release; Req uses `~> 0.5.0`. Pre-1.0 three-segment is the honest current-minor signal; post-1.0 two-segment is a v1.0 revisit.
  - **Upgrade guide:** Oban's per-version "Upgrading to vX.Y" skeleton (bump deps → migration command → config → "optional/nothing required"); Carbonite's freeze-at-generation prefix validates D-191-11; Phoenix's curated upgrade notes + complete CHANGELOG validate D-191-12.
  - **Routing:** Oban grouped `groups_for_extras`; Ash Diátaxis lanes; Phoenix grouped guides; Diátaxis (route by reader intent, don't write a new guide).
  - **Drift-guard:** read-`Mix.Project.config()[:version]`-in-tests is idiomatic Elixir; release-please block/inline annotations are the canonical single-SSOT-plus-injection mechanism; hardcoding the version in N places (docs *and* the guarding tests) is the cited footgun.
- Latent drift the guard surfaces immediately: `evaluating-threadline.md:11` falsely claims 0.6.0 is `@version`; `upgrade-path.md` has no current-minor bullet. Fixing these is the acceptance proof the guard works.
- The routing-table row copy (D-191-18) is user-facing brand microcopy — follow `brandbook/brand-book.md` voice (active, plainspoken, boundaries explicit, concrete surfaces named), preferring it over prompt-era brand material.

</specifics>

<deferred>
## Deferred Ideas

- **CI/CD measurement and pipeline efficiency** → Phase 192 (`CI-01..04`). Out of scope here.
- **Guide-body content rewrites** beyond version/tense/routing repair → not this phase; wayfinding and truth only.
- **A standalone "start here"/"where to go next" guide** → forbidden by ADOPT-03; actively `refute`-tested (D-191-17).
- **Full Diátaxis reorganization of guide content** → deferred; Phase 191 only groups existing guides into ExDoc lanes.
- **Post-1.0 two-segment pin convention** (`~> 1.0`) → revisit at the 1.0 release; pre-1.0 stays three-segment (D-191-02).
- **Auto-injecting install pins** → decided against (D-191-05, source-validated): pins are test-enforced only, never marker-injected. Revisit only if release-please ships a sticky `major.minor.0` updater scope.
- No todo artifacts matched Phase 191 (`todo.match-phase 191` → 0), so none were folded or reviewed.

### Reviewed Todos (not folded)

None — no todos matched this phase.

</deferred>

---

*Phase: 191-release-version-and-docs-trust-repair*
*Context gathered: 2026-07-02*
