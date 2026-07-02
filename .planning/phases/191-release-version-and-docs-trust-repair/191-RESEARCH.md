# Phase 191: Release/Version and Docs Trust Repair - Research

**Researched:** 2026-07-02
**Domain:** Elixir/Hex docs-contract integrity — version-truth reconciliation, upgrade-guide extension, ExDoc routing, release-please wiring
**Confidence:** HIGH (every claim verified against the live repo this session via Read/grep)

<user_constraints>
## User Constraints (from CONTEXT.md)

CONTEXT.md is the reconciled output of four advisor-research streams + three adversarial-validation passes. **Do not re-open D-191-01..18.** This research grounds them in the live repo; it does not re-litigate.

### Locked Decisions (verbatim summary — full text in 191-CONTEXT.md)
- **D-191-01:** SSOT is `mix.exs @version` (`"0.9.0"`). Nothing else stores a version literal except `@version` and immutable history. Every enforced version reference derives from `@version`.
- **D-191-02 / 02a:** Install pin = three-segment `~> 0.9.0` everywhere (not `~> 0.6`, not two-segment `~> 0.9`). Backport policy: security/critical fixes ship as patch releases on the current minor; crossing a minor is deliberate.
- **D-191-03:** Version-truth taxonomy — *version-truth* lines bind to `@version`; *"current/SSOT" prose* fixed to `0.9.0` now; *historical narrative* stays pinned (never falsify history — never edit CHANGELOG or "landed in X" prose).
- **D-191-04:** Move guards in the SAME commit as the pins so CI never goes red mid-change.
- **D-191-05 (source-validated split):** Full-version PROSE claims → auto-inject via `<!-- x-release-please-version -->` marker + `extra-files`. Install PINS → **test-enforced only, NEVER marker-injected** (release-please's generic updater has no sticky `major.minor.0` scope and would born-red every patch release).
- **D-191-06:** One central `test/threadline/version_truth_doc_contract_test.exs` deriving from `@version`; globs `README.md` + `guides/**/*.md`; three families (A install pins, B current-version prose, C upgrade coverage).
- **D-191-07:** Generalize the marker/extra-files wiring guard to ALL marked docs. Add `guides/evaluating-threadline.md` to `extra-files` and mark only its current-claim line.
- **D-191-08:** Register both new tests in the `verify.doc_contract` alias.
- **D-191-09..12a:** Extend the existing `## Upgrade by Threadline minor` section (hybrid shape: theme table + per-minor spine + bounded per-bump bullets with mandatory "nothing required" callouts). Storage-schema block phrased per Phase 190 D-190-14. State CHANGELOG-vs-upgrade-path division of labor. Add backport sentence.
- **D-191-13..18:** Routing = Option C (README prose + ExDoc structure), **intent VERBS** (Evaluate/Adopt/Operate/Contribute), README `## Start here` intent table, **replace** (not delete) the flat `## Documentation` dump with a collapsed `<details>` all-guides index, four verb lanes in `groups_for_extras`, new `persona_routing_doc_contract_test.exs`, brand-voice microcopy.

### Claude's Discretion
Exact regex/parsing in the doc-contract tests, precise wording of the upgrade-guide theme table / reassurance bullets / backport sentence, exact `<details>` index formatting, test module/helper organization. Must preserve all locked contracts above.

### Deferred Ideas (OUT OF SCOPE)
- CI/CD measurement & pipeline efficiency → Phase 192 (CI-01..04).
- Guide-*body* content rewrites beyond version/tense/routing repair.
- A standalone "start here"/"where to go next" guide → forbidden by ADOPT-03, `refute`-tested (D-191-17).
- Full Diátaxis reorganization of guide content.
- Post-1.0 two-segment pin convention.
- Auto-injecting install pins → decided against (D-191-05).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-01 | Public install snippets, evaluator docs, upgrade guidance, README, adoption backlog, and package metadata agree on current `0.9.0` truth (or older lines explicitly justified) | Version-Truth Reference Ledger (§Grounding) enumerates all 7 stale `~> 0.6` pins + the one false SSOT claim + their guards. Central `version_truth_doc_contract_test.exs` (Family A/B) enforces durably. |
| ADOPT-02 | Upgrade guidance covers 0.6.x→0.9.x adopter effects (storage-schema default, operator surface/theming, release proof lanes, migration expectations) | `upgrade-path.md` gap confirmed (stops at 0.5.x→0.6.x). Locked section headings, refuted tokens, and CHANGELOG anchors documented so the extension extends without breaking `upgrade_path_doc_contract_test.exs`. |
| ADOPT-03 | README + ExDoc routing give a shorter next-step path without a giant new guide | ExDoc extras inventory (17 guides) + lane-assignment table; README preservation-literal list; `release_artifact_contract_test.exs` groups collision flagged. |
</phase_requirements>

## Summary

This is a **truth-and-wayfinding** phase, not a product or content phase. All decisions are locked in CONTEXT; the planner's risk is entirely *execution fidelity* — specifically, **not missing any of the test guards that must move in the same commit as the doc edits**, and **not dropping test-locked literals when reshaping the README**.

The most important research finding is a **correction to CONTEXT's D-191-04**: CONTEXT names only `adoption_pilot_doc_contract_test.exs:13-16` and `verify.hex_evaluator` as guards to move alongside the pin flip. In reality **four** test files assert `{:threadline, "~> 0.6"}` and will redden when the pins become `~> 0.9.0`:

1. `adoption_pilot_doc_contract_test.exs:13` (named in CONTEXT ✓)
2. `getting_started_saas_doc_contract_test.exs:33-34` (**NOT in CONTEXT — drift**)
3. `operator_surface_doc_contract_test.exs:58-60` (**NOT in CONTEXT — drift**)
4. `release_artifact_contract_test.exs:86` (**NOT in CONTEXT — drift**)

Additionally, `release_artifact_contract_test.exs:40-44` asserts the `groups_for_extras` keys **exactly equal** `[:Overview, :Integrations, :Reference, :Project]` — the D-191-16 verb-lane replacement breaks this and must be updated in the same change.

Every file/line CONTEXT cites was verified accurate (line numbers have NOT drifted). CHANGELOG anchors `[0.6.0]`/`[0.7.0]`/`[0.8.0]`/`[0.9.0]` all exist. There is exactly **one** `x-release-please-version` marker in the whole repo today (`adoption-pilot-backlog.md:7`) — the proven mechanism to generalize.

**Primary recommendation:** Plan around a single atomic "pin-flip + guard-move" commit that touches all 7 pins AND all 4 guard tests AND the two `groups_for_extras`-dependent tests together; then layer the new central test, the upgrade-guide extension, and the routing reshape as separately-verifiable units. Treat the README reshape as the highest-risk edit because of the ~18 test-locked literals it must preserve.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version SSOT | `mix.exs @version` | — | D-191-01; single literal, everything derives |
| Version-truth enforcement | ExUnit doc-contract tests (`version_truth_...`) | `mix verify.doc_contract` alias | Tests are the product surface; pins are test-enforced only |
| Full-version prose freshness | release-please (`extra-files` + marker) | central test Family B | Auto-injected, born-red-proof by identity |
| Install-pin freshness | ExUnit Family A (glob + derive) | manual minor-bump edit | NEVER injected (no sticky `.0` scope) |
| Adopter upgrade narrative | `guides/upgrade-path.md` prose | `CHANGELOG.md` anchors | Guide = curated/incomplete; CHANGELOG = complete/chronological |
| Reader routing (words) | `README.md ## Start here` | — | D-191-13 Option C: README owns prose |
| Reader routing (structure) | `mix.exs docs[:groups_for_extras]` | ExDoc HexDocs sidebar | D-191-13: ExDoc owns sidebar shape |

## Grounding: Version-Truth Reference Ledger

Every version reference in scope, verified at the live line this session. "Guard" = the test that will redden if the doc changes without a matching test edit.

| # | File:Line | Current text (verbatim) | D-191 class | Required action | Existing guard test |
|---|-----------|-------------------------|-------------|-----------------|---------------------|
| 1 | `README.md:63` | `{:threadline, "~> 0.6"}` (single-dep fence) | version-truth pin | → `~> 0.9.0` | `release_artifact_contract_test.exs:86` (verify.release) + NEW Family A |
| 2 | `guides/getting-started-saas.md:26` | `{:threadline, "~> 0.6"}` (fence) | version-truth pin | → `~> 0.9.0` | **`getting_started_saas_doc_contract_test.exs:33-34`** + NEW Family A |
| 3 | `guides/operator-surface.md:30` | `{:threadline, "~> 0.6"}` (fence) | version-truth pin | → `~> 0.9.0` | **`operator_surface_doc_contract_test.exs:58-60`** + NEW Family A |
| 4 | `guides/evaluating-threadline.md:38` | `depends on \`{:threadline, "~> 0.6"}\` from hex.pm` (prose) | version-truth pin | → `~> 0.9.0` | NEW Family A only |
| 5 | `guides/adoption-evidence-playbook.md:15` | `depends on \`{:threadline, "~> 0.6"}\` from hex.pm` (prose) | version-truth pin | → `~> 0.9.0` | NEW Family A only |
| 6 | `guides/adoption-pilot-backlog.md:14` | `\| App depends on \`{:threadline, "~> 0.6"}\` \| OK \|` (table cell) | version-truth pin | → `~> 0.9.0` | **`adoption_pilot_doc_contract_test.exs:13`** + NEW Family A |
| 7 | `priv/ci/hex_evaluator/mix.exs:27` | `{:threadline, "~> 0.6"},` (real dep) | version-truth pin (NOT globbed) | → `~> 0.9.0`; refresh `mix.lock` | Enforced by `mix verify.hex_evaluator` running (fetches from hex.pm) |
| 8 | `guides/evaluating-threadline.md:9` | `## What Threadline 0.6.0 packages` (heading) | current/historical (ambiguous) | see note below | `evaluating_threadline_doc_contract_test.exs:32,35` |
| 9 | `guides/evaluating-threadline.md:11` | `Threadline **0.6.0** is the in-repo, doc, and Hex SSOT (\`mix.exs @version\`)` | **false current claim** | → `0.9.0` + add `<!-- x-release-please-version -->` marker | NEW Family B; add to `extra-files` (D-191-07) |
| 10 | `guides/evaluating-threadline.md:13` | `0.6.0 packages Evidence, ... landed in-repo after **0.5.0**` | **historical — DO NOT change** | leave verbatim | `evaluating_threadline_doc_contract_test.exs:35` requires this line to survive |
| 11 | `guides/getting-started-saas.md:140` | `### Recommended path (0.6.0+)` (heading) | historical label | reframe off bare "(0.6.0+)" (D-191-03) | none |
| 12 | `guides/upgrade-path.md:5` | `Threadline **0.6.0** packages Evidence ... that landed in-repo after **0.5.0**` | historical, present-tense | tense fix "packages" → "landed in 0.6.0" | none directly; `semver_adopter` guards v1.2x only |
| 13 | `guides/adoption-pilot-backlog.md:7` | `Distribution preflight below reflects the **0.9.0** tree ... <!-- x-release-please-version -->` | current claim (ALREADY correct + marked) | **leave** — this is the reference pattern | `adoption_pilot_doc_contract_test.exs:26-45` |

**Note on rows 8–10 (the subtle one):** `evaluating_threadline_doc_contract_test.exs` asserts the guide contains both `"0.6.0"` (line 32) and `"0.6.0 packages Evidence"` (line 35). The **historical line 13** satisfies both. So the planner can safely change line 11's SSOT claim to `0.9.0` (and optionally reframe the line-9 heading) **provided line 13 is preserved verbatim**. If line 13 were also changed, that existing test would break. Flag this to the executor explicitly.

**SSOT confirmed:** `mix.exs:4` → `@version "0.9.0"`. `.release-please-manifest.json` → `"." : "0.9.0"`. Hex latest = `0.9.0` (per adoption-pilot-backlog.md attestation, tag `v0.9.0`). No drift.

## Co-Commit Guard Inventory (the load-bearing correction to D-191-04)

Flip pins and their guards **together** (D-191-04) or CI/release goes red. Complete inventory:

| Guard file | Line(s) | Current assertion | Change needed | Runs under |
|------------|---------|-------------------|---------------|------------|
| `adoption_pilot_doc_contract_test.exs` | 9 (test name), 13, 14 | asserts `"~> 0.6"`, refutes `"~> 0.5"` | assert `"~> 0.9.0"`; add refute `"~> 0.6"`; update test-name string | `ci.all` (in verify.doc_contract) |
| `getting_started_saas_doc_contract_test.exs` | 33, 34 | asserts `{:threadline, "~> 0.6"}`, refutes `~> 0.5` | assert `~> 0.9.0`; keep/refresh refutes | `ci.all` (in verify.doc_contract) |
| `operator_surface_doc_contract_test.exs` | 58, 59, 60 | asserts `{:threadline, "~> 0.6"}`, refutes `~> 0.5`, `~> 0.3.0` | assert `~> 0.9.0`; refutes stay valid | `ci.all` (in verify.doc_contract) |
| `release_artifact_contract_test.exs` | 86 | asserts README contains `{:threadline, "~> 0.6"}` | assert `~> 0.9.0` | `mix verify.release` only (NOT ci.all) |
| `release_artifact_contract_test.exs` | 40–44 | `groups_for_extras` keys **==** `[:Overview,:Integrations,:Reference,:Project]` | update to new verb-lane key list (D-191-16) | `mix verify.release` only |
| `priv/ci/hex_evaluator/mix.exs` + `mix.lock` | 27 | `{:threadline, "~> 0.6"}` | `~> 0.9.0` + regenerate lock | `mix verify.hex_evaluator` |
| `mix.exs` `verify.hex_evaluator` | — | shells into `priv/ci/hex_evaluator`, runs its tests | no alias edit; the subproject dep flip is the change | — |

**Timing nuance:** guards 1–3 redden in per-PR `ci.all`; guards 4–5 (`release_artifact`) redden only at `mix verify.release` (release time), so a green PR could still break the release. Update all in one commit regardless. This mirrors the `[[release-runbook]]` born-red history.

**`~> 0.9.0` substring safety:** `"~> 0.9.0"` does not contain `"~> 0.6"`, `"~> 0.5"`, or `"~> 0.3.0"`, so existing `refute` lines stay valid after the flip. Verified.

## Central Test Design Facts (`version_truth_doc_contract_test.exs`)

### The winning pattern to centralize (from `adoption_pilot_doc_contract_test.exs`)

```elixir
# Source: test/threadline/adoption_pilot_doc_contract_test.exs (verified this session)
@version Threadline.MixProject.project()[:version]          # derive, never hardcode

# wiring guard (lines 26-45): find marked line by prefix, assert marker + extra-files
ssot_line =
  @guide |> File.read!() |> String.split("\n")
  |> Enum.find(&String.starts_with?(&1, "Distribution preflight below reflects the "))
assert String.contains?(ssot_line, "x-release-please-version")
config = File.read!("release-please-config.json")
assert String.contains?(config, "extra-files") and String.contains?(config, @guide)
```

Generalize this: instead of one hardcoded guide + one prefix, **glob** and derive.

### Family A — install pins (test-enforced only, per D-191-05/06)
- Glob `README.md` + `Path.wildcard("guides/**/*.md")` (glob, NOT an allowlist — a future doc with an install snippet can't slip through).
- Match the **raw file text** with a regex like `~r/\{:threadline,\s*"~>\s*([\d.]+)"\}/` — the pin appears in **code fences (rows 1-3), prose (rows 4-5), AND a markdown table cell (row 6)**, so do NOT parse fences; scan raw text.
- Assert every captured pin `== "#{major}.#{minor}.0"` derived from `@version` (three-segment, sticky `.0`). For `0.9.0` → expect `~> 0.9.0`.
- **Why `.0` is load-bearing:** patch releases (`0.9.0`→`0.9.1`) keep the derived expectation at `~> 0.9.0` and the pins at `~> 0.9.0` → green by construction, no injection. Only rare minor bumps require a one-line pin edit (already human-gated by the upgrade-guide extension).
- **Exclude `priv/`** (real dep, enforced by `verify.hex_evaluator` execution) and `examples/` (path dep) — the README+guides glob already excludes them.

### Family B — current-version prose (marker = allowlist)
- Only lines carrying `x-release-please-version` are "live" claims; each must contain `@version`. Unmarked prose is historical and ignored.
- Today exactly **one** marked line exists (`adoption-pilot-backlog.md:7`); Phase 191 adds a second (`evaluating-threadline.md:11`). Both must contain `0.9.0`.
- Fold in D-191-07 wiring: assert every marker-bearing doc appears in `release-please-config.json` `extra-files`.

### Family C — upgrade coverage (depends on `@version`)
- Derive "current minor covered": assert `0.#{minor-1}.x → 0.#{minor}.x` present in `upgrade-path.md` (for `0.9.0` → `0.8.x → 0.9.x`). **This currently FAILS** — the guide stops at `0.5.x → 0.6.x`. Fixing it is the acceptance proof the guard works.
- Delegate theme/bullet structural checks to the existing `upgrade_path_doc_contract_test.exs`.

### Wiring
- Add `version_truth_doc_contract_test.exs` AND `persona_routing_doc_contract_test.exs` to the `verify.doc_contract` alias string in `mix.exs:82` (currently lists 18 test files; becomes 20). The alias is one long space-joined string on line 82 — append the two new relative paths.

## ExDoc Routing Grounding (D-191-16)

### Current `groups_for_extras` (mix.exs:279-284) — to REPLACE
```elixir
groups_for_extras: [
  Overview: ~r/README/,
  Integrations: ~r{^guides/integrations/},
  Reference: ~r{^guides/},          # greedy flat bucket — replace
  Project: ~r/(CONTRIBUTING|CHANGELOG)/   # replace with Contribute
]
```

### Exhaustive extras inventory (mix.exs:257-278) — 20 extras, ALL verified present
Every guide file on disk is already in `extras` (grep confirmed zero missing). The four verb lanes must partition the **15 top-level guides**; `Overview` (README) and `Integrations` (2 files) stay. Suggested lane assignment consistent with D-191-14/16 canonical landings:

| Lane (verb) | Guides (explicit per-lane list; each extra in exactly one lane) |
|-------------|----------------------------------------------------------------|
| Overview | `README.md` |
| Evaluate | `guides/evaluating-threadline.md`, `guides/how-threadline-works.md`, `guides/domain-reference.md` |
| Adopt | `guides/getting-started-saas.md`, `guides/production-checklist.md`, `guides/brownfield-continuity.md`, `guides/integration-contracts.md`, `guides/local-docker-dx.md`, `guides/upgrade-path.md` |
| Operate | `guides/operator-surface.md`, `guides/incident-playbook.md`, `guides/performance.md`, `guides/audit-indexing.md`, `guides/adoption-evidence-playbook.md` |
| Contribute | `CONTRIBUTING.md`, `guides/adoption-pilot-backlog.md`, `CHANGELOG.md` |
| Integrations | `guides/integrations/sigra.md`, `guides/integrations/phx-gen-auth.md` (regex `~r{^guides/integrations/}` retained) |

*(Lane placement of note per D-191-16: `upgrade-path.md` → Adopt; `adoption-evidence-playbook.md` → Operate; CONTRIBUTING/adoption-pilot-backlog/CHANGELOG → Contribute. Above lists 15 guides + 2 integrations + README = 18 grouped extras + CHANGELOG/CONTRIBUTING; confirm counts sum to all 20 extras before finalizing. This exact split is Claude's-discretion refinement — the planner may adjust which lane holds a borderline guide, but every extra must land in exactly one lane and the four verb keys must be spelled `Evaluate`/`Adopt`/`Operate`/`Contribute`.)*

### Collision: `release_artifact_contract_test.exs:40-44`
```elixir
# Source: test/threadline/release_artifact_contract_test.exs:40 (verified)
assert Keyword.keys(docs_config()[:groups_for_extras]) == [:Overview, :Integrations, :Reference, :Project]
```
This is an **exact-equality** assertion on the key list — it breaks the moment `Reference`/`Project` are replaced. Update to the new key order (e.g. `[:Overview, :Integrations, :Evaluate, :Adopt, :Operate, :Contribute]`). Keep this consistent with `persona_routing_doc_contract_test.exs` (D-191-17), which asserts the four verb keys are **present** (subset) — the two tests must agree. Line 51's `Integrations == [Threadline.Integrations.Sigra]` is a `groups_for_modules` check and is unaffected.

## README Reshape Preservation Literals (D-191-15 — highest execution risk)

`readme_doc_contract_test.exs` greps the **whole README** for many literals. Replacing the flat `## Documentation` dump (lines 187-204) and reshaping `## Start here` (lines 21-30) into an intent table + `<details>` all-guides index **must not drop** any of these. No test guards the `## Documentation` heading itself (grep confirmed), so the heading may go — but every link/sentence below must survive somewhere in the README:

- Guide links (asserted README-wide): `how-threadline-works.md`, `getting-started-saas.md`, `domain-reference.md`, `upgrade-path.md`, `evaluating-threadline.md`, `production-checklist.md`, `adoption-pilot-backlog.md`, `integrations/phx-gen-auth.md`, `integrations/sigra.md`, `performance.md`, `incident-playbook.md` (test lines 45,52-55,62,66-68,74,132,137).
- Sentences: `"which public API first?"` (51); the lane matrix line `canonical \`capture-only\`, \`phoenix-surface\`, \`phx-gen-auth-reference\`, and \`sigra-reference\` matrix` (57-60); `Phoenix auth (reference lanes, pick one)` (63).
- Refutes: NOT `Using Sigra:` (64); NOT `| Lane | Claim type |` in README (86-99) — so the intent table must use the `I want to… / Start here / Then read` header, never the upgrade-path matrix header; NOT `mix threadline.evidence.show`.
- **Scoped test (lines 76-83):** the `## Start here` … `## Evidence plane` slice must contain `evaluating-threadline.md`. The Evaluate row naturally satisfies this.

**Watch-outs:** the current `## Start here` bullets (lines 27-28) carry the lane-matrix sentence and the `Phoenix auth (reference lanes, pick one)` line. These do not map cleanly to the four verb rows — relocate them into the `<details>` index or adjacent prose so their literals survive. The `<details>` index is not a new guide (ADOPT-03 / D-191-17 `refute` on `where-to-go-next.md`/`start-here.md` still holds).

## Upgrade-Guide Extension Grounding (ADOPT-02)

- **Gap confirmed:** `upgrade-path.md` "Current guidance by minor" (line 79) lists only `0.5.x → 0.6.x` (line 81) and `0.3.x -> 0.4.x` (line 82). No 0.6→0.7, 0.7→0.8, 0.8→0.9. Extend **within** the existing `## Upgrade by Threadline minor` section (line 68) — do NOT add/rename a top-level section.
- **Locked section headings** `upgrade_path_doc_contract_test.exs:5-17` asserts must all remain: `## Who this guide is for`, `## How to tell which lane you are on`, `## Supported compatibility matrix`, `## Upgrade by Threadline minor`, `## What breaks when Phoenix/LiveView floors move`, `## Packaging Boundary Scorecard`, `## Surface-only deprecation and removal policy`, `## Release checklist for adopters`, `## Canonical references`. The theme table + per-minor spine table are **additive inside** existing sections; the compatibility matrix header string (line 24 of the test) and its exact Phoenix version strings are locked verbatim — do not disturb.
- **Scoped 0.5→0.6 assertion** `upgrade_path_doc_contract_test.exs:165-180` scopes between `## Upgrade by Threadline minor` and `## What breaks when Phoenix` and requires `0.5.x → 0.6.x` (arrow char `→` U+2192 or ASCII `->`), `Threadline.Audit.transaction/3`|`Threadline.Evidence`, `CHANGELOG.md`, and `[0.6.0]` — all **within that scope**. New 0.6→0.9 bullets land in the same scope; keep the existing 0.5→0.6 bullet.
- **Refuted tokens** the new content must avoid: `forthcoming` (test lines 86,97), `Phoenix 1.7+` (71). D-191-12 adds `refute` on `coming soon` and on any per-minor bullet lacking a "None"/"nothing required"/explicit action — the new upgrade test must enforce the mandatory reassurance callout.
- **CHANGELOG anchors — all present (verified):** `CHANGELOG.md` has `## [0.9.0](compare/v0.8.0...v0.9.0)`, `## [0.8.0] - date`, `## [0.7.0](compare/v0.6.0...v0.7.0)`, `## [0.6.0] - date`. **Heading format is inconsistent** — `[0.9.0]`/`[0.7.0]` are compare-link headings, `[0.8.0]`/`[0.6.0]` are plain. The existing guide references anchors textually (backtick `[0.6.0]`, not a live markdown `#anchor` link), so the inconsistency is harmless for textual references; if the planner adds live `#`-anchor links, generated slugs will differ between the two heading forms — prefer textual `[x.y.0]` references to match the existing style.
- **`semver_adopter_doc_contract_test.exs` guards only `v1.2[0-9]`** (verified line 12: `~r/v1\.2[0-9]/`). It does **NOT** catch `v1.3x`. The milestone the upgrade guide narrates is v1.34→v1.39, so it is tempting to write those labels — D-191-12 forbids product-milestone labels (Hex semver only). The existing test will **not** catch a `v1.39` slip; the executor must avoid it manually, and the planner may optionally extend the new upgrade test to `refute ~r/v1\.3[0-9]/`. This guide's adopter paths (README, getting-started-saas, how-threadline-works, upgrade-path, adoption-pilot-backlog) are already in `@adopter_paths`.
- **Storage-schema block (D-191-11):** phrase per Phase 190 D-190-14 — `storage_schema` frozen at generation time; changing later is deliberate migration work; keep Threadline-owned `storage_schema` distinct from host `table_schema`. The README Quick Start already carries the canonical wording (`readme_doc_contract_test.exs:247-279` locks it) — mirror that phrasing for consistency; do not contradict it.

## CONTRIBUTING.md (D-191-02a / 12a backport sentence)

- `CONTRIBUTING.md` present (244 lines). Grep for `backport`/`patch release`/`current minor` → **zero hits**. The backport-policy sentence is a genuinely new addition (mirror the one added to `upgrade-path.md`). No existing test guards this text, so add a small assertion if durability is wanted (Claude's discretion).

## release-please Wiring Facts

- `release-please-config.json:17-19` `extra-files` currently lists **only** `{"type": "generic", "path": "guides/adoption-pilot-backlog.md"}`. D-191-07 adds `guides/evaluating-threadline.md`. **Do NOT add any pin-bearing file for pin injection** — the generic updater has no sticky `.0` scope (D-191-05); it would rewrite `~> 0.9.0`→`~> 0.9.1` on a patch release and born-red the derive-test. Only full-version **prose-claim** files (with a marker) belong in `extra-files`.
- `.release-please-manifest.json` = `{".": "0.9.0"}` — consistent, no change needed.
- The generic updater replaces the **first three-segment match on the marked line only** — so `evaluating-threadline.md:11` must carry the full `0.9.0` (three segments) and the marker on the same line for injection to work.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version currency in tests | Hardcoded `"0.9.0"` in the new test | `@version Threadline.MixProject.project()[:version]` | A test that hardcodes the version is the same drift footgun it guards (D-191-06) |
| "did we cover every doc with a pin?" | Allowlist of files | `Path.wildcard("guides/**/*.md")` glob | Future docs with snippets can't slip through (D-191-06) |
| Keeping prose version fresh | Custom `mix` sync task / CI grep-guard / auto-fix bot | release-please `x-release-please-version` marker + `extra-files` | Custom commits push to `release-please--branches--main` → the stale/force-update fragility the runbook documents (D-191-05 rejected alternatives) |
| Keeping the pin fresh | Marker-injecting the pin | Family A derive-test | Generic updater has no sticky `.0` scope — would born-red every patch (D-191-05) |

## Common Pitfalls

### Pitfall 1: Flipping a pin without its guard
**What goes wrong:** Change `guides/getting-started-saas.md:26` to `~> 0.9.0`; `ci.all` immediately reddens at `getting_started_saas_doc_contract_test.exs:33`.
**Why it happens:** CONTEXT's D-191-04 lists only `adoption_pilot` + `hex_evaluator`; three more guards exist.
**How to avoid:** Use the Co-Commit Guard Inventory table. One atomic commit for all 7 pins + 4 guard tests + the groups-key test.
**Warning signs:** A "docs-only" commit that touches no `test/` files while flipping pins.

### Pitfall 2: Rewriting the historical `evaluating-threadline.md:13` line
**What goes wrong:** Sweeping "0.6.0"→"0.9.0" edits hit line 13; `evaluating_threadline_doc_contract_test.exs:35` reddens.
**How to avoid:** Only lines 9 (heading, optional) and 11 (false SSOT claim) change. Line 13 ("0.6.0 packages Evidence … landed in-repo after 0.5.0") is protected history — leave verbatim.
**Warning signs:** A global find-replace of "0.6.0" across the file.

### Pitfall 3: Dropping a test-locked README literal during the routing reshape
**What goes wrong:** Replacing `## Documentation` and the `## Start here` bullets loses the `Phoenix auth (reference lanes, pick one)` line or a guide link; `readme_doc_contract_test.exs` reddens.
**How to avoid:** Check every edit against the README Preservation Literals list before committing.
**Warning signs:** `mix verify.doc_contract` failing on a README assertion after the reshape.

### Pitfall 4: Forgetting `release_artifact_contract_test.exs` (release-time only)
**What goes wrong:** PR is green (`ci.all` doesn't run `release_artifact`), but `mix verify.release` fails on the pin (line 86) or the groups-key equality (lines 40-44).
**How to avoid:** Update `release_artifact_contract_test.exs` in the same commit even though it's not in `ci.all`. Optionally run `mix verify.release` locally before finishing.
**Warning signs:** Green PR, red release runbook.

### Pitfall 5: Writing product-milestone labels in the upgrade guide
**What goes wrong:** "In v1.39 the storage-schema default changed…" — `semver_adopter` only catches `v1.2x`, so `v1.39` sails through to published docs.
**How to avoid:** Use Hex versions only (`0.9.0`). Consider adding `refute ~r/v1\.3[0-9]/` to the new upgrade test.

## Runtime State Inventory

This is a docs/config/test phase — no stored data, live-service config, OS-registered state, secrets, or build artifacts carry a renamed string. The one runtime-ish artifact:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no datastore holds a version literal | none |
| Live service config | release-please config (`extra-files`) + manifest — both in git | code edit only (add `evaluating-threadline.md`) |
| OS-registered state | None | none |
| Secrets/env vars | None | none |
| Build artifacts | `priv/ci/hex_evaluator/mix.lock` (+ `_build`, `deps`) becomes stale after the `~> 0.9.0` pin flip | regenerate lock (`mix deps.update threadline` in that subproject); `verify.hex_evaluator` fetches `0.9.0` from hex.pm |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `~> 0.9.0` is installable because threadline `0.9.0` is published on hex.pm | Ledger row 7, Runtime State | If 0.9.0 were not on hex.pm, `verify.hex_evaluator` would fail. Mitigated: adoption-pilot-backlog.md attests "latest is 0.9.0, tag v0.9.0" (verified in-repo), consistent with STATE.md. LOW risk. |
| A2 | The suggested per-lane guide split sums to all 20 extras with each in exactly one lane | ExDoc Routing Grounding | Miscount would leave a guide ungrouped in the sidebar. Planner must recount against the mix.exs extras list before finalizing. LOW risk (list is enumerated). |
| A3 | release-please generic updater behavior (three-segment VERSION_REGEX, no sticky `.0`) is as CONTEXT's source-read describes | Central Test / release-please Wiring | This drives the pins-are-test-enforced split. CONTEXT read `generic.ts` at source; not re-verified this session. If wrong, the injection strategy would differ. Treated as CONTEXT-locked (D-191-05). LOW-MEDIUM. |

## Open Questions

1. **Should the `evaluating-threadline.md:9` heading change?**
   - What we know: Line 11 (SSOT claim) must become `0.9.0`. Line 9 heading `## What Threadline 0.6.0 packages` reads as historical-ish.
   - What's unclear: Whether "0.6.0" in the heading is a "current" claim or a "what 0.6.0 packaged" historical claim.
   - Recommendation: Leave the heading as historical OR reframe to remove the version; either way keep line 13 verbatim so `evaluating_threadline_doc_contract_test.exs:35` stays green. Low stakes; executor's call.

2. **Does the new upgrade test refute `v1.3x` labels?**
   - What we know: `semver_adopter` only guards `v1.2x`. The narrated milestone is v1.34→v1.39.
   - Recommendation: Add `refute ~r/v1\.3[0-9]/` (or broaden the shared semver guard) so the product-milestone ban is actually enforced for the era this guide covers.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/mix (repo toolchain) | all `mix verify.*` | ✓ (repo's own) | `~> 1.15` per mix.exs | — |
| hex.pm reachability | `verify.hex_evaluator` fetching `threadline 0.9.0` | assumed ✓ | 0.9.0 published | none — needed to prove the Hex install lane |
| PostgreSQL | `ci.all` (DataCase tests incl. `readme_doc_contract_test`) | repo-standard `DB_PORT=5433` | — | — |

*(No new external dependencies introduced by this phase — no `mix deps.get` additions.)*

## Sources

### Primary (HIGH confidence — verified in the live repo this session)
- `mix.exs` — `@version "0.9.0"` (:4); `verify.doc_contract` alias (:81-83, 18 tests); `groups_for_extras` (:279-284); `extras` (:257-278); `verify.hex_evaluator` (:201-209).
- `README.md` — pin :63; `## Start here` :21-30; `## Documentation` :187-204; test-locked literals throughout.
- `release-please-config.json` — `extra-files` :17-19 (only adoption-pilot-backlog.md).
- `.release-please-manifest.json` — `{".":"0.9.0"}`.
- `priv/ci/hex_evaluator/mix.exs:27` — `{:threadline, "~> 0.6"}`.
- Guides — `evaluating-threadline.md:9,11,13,38`; `upgrade-path.md:5,68,79,81-83`; `getting-started-saas.md:26,140`; `operator-surface.md:30`; `adoption-evidence-playbook.md:15`; `adoption-pilot-backlog.md:7,14`.
- `CHANGELOG.md` — anchors `[0.9.0]`, `[0.8.0]`, `[0.7.0]`, `[0.6.0]` (heading format inconsistency noted).
- Tests — `adoption_pilot_doc_contract_test.exs` (full), `upgrade_path_doc_contract_test.exs` (full), `semver_adopter_doc_contract_test.exs` (full), `readme_doc_contract_test.exs` (full), `getting_started_saas_doc_contract_test.exs:33-34`, `operator_surface_doc_contract_test.exs:58-60`, `evaluating_threadline_doc_contract_test.exs:29-35`, `release_artifact_contract_test.exs:40-44,86`, `exploration_routing_doc_contract_test.exs`, `ia_lock_doc_contract_test.exs`, `release_distribution_doc_contract_test.exs:8,13`.

### Secondary (from CONTEXT — locked, not re-verified this session)
- release-please `generic.ts` VERSION_REGEX / no-sticky-`.0` behavior (CONTEXT source-read, D-191-05).
- Ecosystem precedents: Carbonite `~> 0.16.1` re-pin, Req `~> 0.5.0`, Oban/Ash/Phoenix `groups_for_extras` intent lanes.

## Metadata

**Confidence breakdown:**
- Version-truth ledger & guard inventory: HIGH — every line read directly.
- ExDoc lane split: HIGH on inventory/collision; MEDIUM on exact per-lane placement (Claude's discretion).
- Upgrade-guide structural constraints: HIGH — test read in full.
- release-please injection mechanics: MEDIUM — relies on CONTEXT's source-read (A3).

**Research date:** 2026-07-02
**Valid until:** 2026-07-16 (docs move with each edit; re-verify line numbers if the phase starts after other doc work lands)
</content>
</invoke>
