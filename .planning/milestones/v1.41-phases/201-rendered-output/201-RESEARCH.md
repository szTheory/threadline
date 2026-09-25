# Phase 201: Rendered Output - Research

**Researched:** 2026-09-13
**Domain:** Phoenix LiveView rendered-output hygiene, behavior-first test selectors, and zero-visual-change verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Browser Metadata Boundary

- **D-01:** Treat the roadmap's `grep -rn 'data-jtbd'` as a concrete minimum probe, not as a narrowing of RENDER-02. Remove the complete co-located planning taxonomy from all seven affected rendered nodes: `data-earned-flow="EF*"`, `data-persona="P*"`, and `data-jtbd="J*"`. Leaving either sibling taxonomy behind would preserve the same provenance leak under a different attribute name.
- **D-02:** Do not replace the removed taxonomy with a parallel metadata scheme by default. Migrate tests to behavior-first selectors: existing form IDs, routes and outcomes, roles, labels, visible actions, and existing task-oriented `data-testid` values. A new neutral `data-testid` is permitted only when a selector audit proves that no unique semantic or existing stable selector can express the behavior.
- **D-03:** LiveView tests should use `Phoenix.LiveViewTest` selector/form helpers rather than raw HTML substring assertions where the migration naturally touches an assertion. Playwright tests should prefer role, label, text, and stable task selectors over CSS selectors encoding implementation or roadmap taxonomy.

### Stress-Harness Vocabulary

- **D-04:** `/audit/__stress` remains a dev/test-only maintainer and OSS-contributor tool. Its primary job is to select, reproduce, compare, capture, and verify named UI states across themes and viewports; it is not an adopter-facing operator workflow and must not be rewritten as one in this phase.
- **D-05:** Retain durable testing language and exact artifact correlation where it serves that job: stable story IDs, fixture keys, ledger IDs and schema values, cohort identifiers, `Ledger item`, `Origin cohort`, `Refute Twin`, graded-ladder terminology, and rung terminology. Pair machine identifiers with plain-language scenario copy where needed for orientation.
- **D-06:** Remove or permanently reject project-management chronology and opaque roadmap taxonomies from browser-owned copy and metadata: phase/milestone numbers, decision/requirement IDs, `Owner phase`, `J*`, `EF*`, `P*`, `DATA-*`, and equivalent planning provenance. Stable non-rendered fixture keys and engineering terms are not banned merely for being technical.
- **D-07:** Preserve the stress harness's existing authorization, dev/test-only availability, production fail-closed behavior, sanitized synthetic fixtures, DOM structure, classes, styling, dark/light/system behavior, and responsive behavior. Readable maintainer vocabulary must not broaden access or introduce production audit data.

### Already-Landed Cleanup

- **D-08:** Accept, attribute, and guard the rendered-copy and emitted-CSS cleanup that arrived with the Phase 200 integration. Granular commit `5752e357` owns the CSS provenance-comment cleanup; granular commit `1a5fbef2` owns the rendered stress-copy/cohort cleanup; their relevant blobs are byte-identical in integration commit `18fe87f5` and remain unchanged at discussion time.
- **D-09:** Do not revert and replay those correct changes, manufacture inverse commits, squash them again, or rewrite history for phase-number ownership. Treat current HEAD as Phase 201's implementation baseline, record the attribution in durable verification evidence, and implement only the residual inventory.
- **D-10:** The already-landed visible labels are accepted as the final copy for this phase. Planning may verify and guard them but must not reopen their wording, IA, layout, component structure, or visual treatment absent a newly discovered RENDER violation.

### Regression Proof and Release Handoff

- **D-11:** Add an exhaustive, source-derived, zero-allowlist contract over Threadline-owned shipped LiveView templates and emitted CSS for the forbidden attributes and static planning-vocabulary classes. Add representative rendered-output coverage and a synthetic positive control proving the guard fails on a seeded offender. Do not rely only on assertions at today's known locations or on a count floor.
- **D-12:** Scope static-copy checks to Threadline-owned templates, fixtures, and emitted assets. Do not scan or reject arbitrary actor names, row values, audit metadata, or other host-supplied content merely because it contains text resembling `Phase 2`, `D-04`, or another forbidden pattern.
- **D-13:** Produce bounded, one-time pre/post structural evidence for every touched rendered surface. After excluding text nodes and the explicitly removed nonvisual attributes, node count, tags, classes, IDs, and nesting must remain identical. Do not create a permanent whole-DOM snapshot corpus that freezes incidental LiveView markup.
- **D-14:** Preserve the mechanical floor with byte hashes of the unchanged committed operator-surface fixture/scorecard corpus and `mix verify.mechanical` against that unmodified corpus. The Phase 198 probe proved that the checker is blind to text content and width, so it is necessary floor evidence but not sufficient layout evidence.
- **D-15:** Use the existing desktop/mobile responsive, overflow, accessibility, and screenshot checks as the layout/visual complement. Do not generate new screenshot baselines, regenerate Tier-A scorecards, introduce pixel-baseline churn, or invoke any paid/LLM critic path.
- **D-16:** Keep implementation changes atomic and independently revertible, following the milestone rule that source and affected contract tests move together and contract-heavy changes remain bisectable. Rename the remaining roadmap-named historical test files to durable behavior names; do not broaden this into a repository-wide cleanup of non-rendered historical comments.
- **D-17:** Phase 202 receives a browser surface that is clean by construction: the source/output guard is green, the residual attribute inventory is zero, accepted landed cleanup is ratified, normalized structure is unchanged, the mechanical floor is green on unchanged fixtures, and no forbidden recapture or critic path ran.

### the agent's Discretion

- Exact behavior-first selector chosen at each affected test site, following the priority in D-02 and adding a new `data-testid` only with a documented uniqueness gap.
- Exact contract-test module/file placement, positive-control fixture shape, and static-pattern implementation, provided the guard is exhaustive, source-derived, zero-allowlist, non-vacuous, and independent of `.planning/` at runtime.
- Exact normalized structural-signature representation and evidence artifact name, provided it compares the required node/tag/class/ID/nesting shape and excludes only text plus the explicitly removed attributes.
- Exact durable filenames for the remaining roadmap-named tests and the number of plans, provided history is preserved with `git mv` and the cleanup/proof tiers remain independently bisectable.

### Deferred Ideas (OUT OF SCOPE)

- A fully adopter-facing stress laboratory or broader stress-harness IA/copy redesign would require its own future UI phase if the harness is ever promoted into a supported product surface.
- Runtime per-operator theme switching remains demand-gated under the existing brand/theme decision and is unrelated to this zero-visual-change cleanup.
- Repository-wide removal of historical identifiers from non-rendered test descriptions, comments, fixtures, and maintainer artifacts remains outside Phase 201; only the roadmap-named filenames and browser/emitted surfaces are in scope.
- No Plug, Ecto, database, capture/query/auth, public-API, or new operator capability was added; discussion stayed within the fixed phase boundary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RENDER-01 | No operator page renders a phase number, decision ID, or internal taxonomy label in visible text. | Source-derived static-copy guard, representative rendered-output cases, and accepted stress-copy regression assertions. [VERIFIED: .planning/REQUIREMENTS.md:57-60] |
| RENDER-02 | No rendered DOM carries planning-provenance attributes. | Exact seven-node residual inventory, behavior-first selector map, zero-allowlist source/output guard, and positive controls. [VERIFIED: .planning/REQUIREMENTS.md:59-61] |
| RENDER-03 | The emitted CSS contains no phase or milestone provenance comments. | Render and scan `Threadline.OperatorSurface.Style.css/1`; ratify the already-landed CSS blob and seed a bad CSS comment as a positive control. [VERIFIED: .planning/REQUIREMENTS.md:60-62] |
| RENDER-04 | Attribute-only and comment-only removals are proven not to move the mechanical floor, passing against an unmodified scorecard set. | Pre/post corpus manifest bytes plus `mix verify.mechanical`; the current corpus contract already proves non-vacuity and mutation sensitivity. [VERIFIED: .planning/REQUIREMENTS.md:61-63] |
| RENDER-05 | Any text change that does move a measured value is absorbed by narrowing the check or by a registered, counted whitelist entry with a stated expiry — never by regenerating a capture that this environment cannot reproduce. | Treat the accepted text cleanup as landed baseline, expect zero new exceptions, and make any contingency an explicit max-three registry with node, delta, rationale, and expiry; no capture command is permitted. [VERIFIED: .planning/REQUIREMENTS.md:62-64] |
| RENDER-06 | No operator page's element structure, layout, or visual appearance changes — only text content and non-visual attributes. | Normalized pre/post structure receipts plus the existing desktop/mobile responsive, overflow, accessibility, and screenshot assertions without baseline updates. [VERIFIED: .planning/REQUIREMENTS.md:63-64] |
</phase_requirements>

## Summary

Phase 201 is a residual cleanup-and-proof phase, not a copy or UI redesign. The current source contains exactly 21 planning attributes across seven nodes in five LiveViews: two Start panels, two Export context sections, one Evidence handoff link, the Row History shell root, and one Timeline handoff link. The forbidden attribute names and verbatim values are `data-earned-flow="EF1"`, `data-earned-flow="EF2"`, `data-earned-flow="EF3"`, `data-earned-flow="EF4"`, `data-persona="P1"`, `data-persona="P2"`, `data-persona="P3"`, `data-jtbd="J1"`, `data-jtbd="J2"`, `data-jtbd="J4"`, and `data-jtbd="J6"`. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex:222-268] [VERIFIED: lib/threadline/operator_surface/live/export_status_live.ex:188-255] [VERIFIED: lib/threadline/operator_surface/live/evidence_live.ex:359-369] [VERIFIED: lib/threadline/operator_surface/live/row_history_live.ex:40-57] [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex:786-797]

The Phase 200 CSS and stress-copy cleanup must not be replayed. The accepted browser labels now read verbatim `Ledger item`, `Origin cohort`, `Refute Twin — design principle under test`, `Primitives Matrix`, `Data Display`, and `Data States`; existing tests reject the older phase-owned labels. [VERIFIED: lib/threadline/operator_surface/live/stress_live.ex:221-245] [VERIFIED: lib/threadline/operator_surface/live/stress_live.ex:369-370] [VERIFIED: lib/threadline/operator_surface/live/stress_live.ex:463-493] [VERIFIED: test/threadline/operator_surface/stress_router_test.exs:360-381] Repository history inspection found the relevant CSS blob identical from `5752e357` through `18fe87f5` and HEAD, and the stress LiveView/fixture blobs identical from `1a5fbef2` through `18fe87f5` and HEAD. [VERIFIED: git object inspection, 2026-09-13]

Planning should separate two independently bisectable implementation slices: first introduce the exhaustive contract and capture bounded pre-edit structural/corpus evidence; then remove each source attribute together with its LiveView and Playwright selector migration and durable file renames, followed by post-edit structural, mechanical, and browser verification. [ASSUMED] There is no justified new `data-testid`: existing form IDs, task IDs, accessible names, and destinations cover all affected behavior. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex:222-268] [VERIFIED: lib/threadline/operator_surface/live/export_status_live.ex:188-255] [VERIFIED: test/threadline/operator_surface/live/row_history_live_test.exs:195-205]

**Primary recommendation:** Build a source-derived, positive-controlled zero-vocabulary contract first; preserve a one-time normalized pre-edit receipt; remove only the 21 attributes and migrate tests to existing behavioral selectors; then prove unchanged fixture bytes, unchanged structure, and unchanged browser behavior without executing any capture, snapshot-update, or paid critic command. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Static LiveView copy and DOM attribute hygiene | Frontend Server (LiveView) | Browser / Client | HEEx emits the affected markup; browser tests verify the delivered contract. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex:222-268] |
| Emitted CSS provenance hygiene | Frontend Server (component render) | CDN / Static | `Style.css/1` emits a `<style>` block consumed as browser CSS. [VERIFIED: lib/threadline/operator_surface/style.ex:1-20] |
| Selector migration | Browser / Client tests | Frontend Server tests | Playwright exercises user-visible semantics while LiveViewTest verifies server-rendered behavior. [CITED: https://playwright.dev/docs/locators] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Normalized structural proof | Frontend Server tests | Browser / Client | LazyHTML can normalize rendered fragments; the existing browser lane complements structure with responsive and screenshot checks. [VERIFIED: deps/lazy_html/lib/lazy_html.ex:47-76] [VERIFIED: deps/lazy_html/lib/lazy_html.ex:116-153] |
| Mechanical-floor integrity | Repository verification tooling | Browser / Client | The deterministic gate reads the committed fixture corpus and runs before the browser lane in `ci.all`. [VERIFIED: mix.exs:124-128] [VERIFIED: mix.exs:177-186] |
| Stress authorization boundary | Frontend Server routing | Browser / Client | Stress is omitted when configured `:omit`, raises in `:prod`, and otherwise mounts existing Auth and Coverage hooks. The verbatim states are `:omit` and `:prod`; the production error is `Threadline stress surface is dev/test-only`. [VERIFIED: lib/threadline/operator_surface/stress_router.ex:5-43] |

## Project Constraints

No root `AGENTS.md` exists. The example application subtree is governed by `examples/threadline_phoenix/AGENTS.md`; after example-app changes run its `mix precommit` alias, retain existing Phoenix routing/auth patterns, and use deterministic tests rather than sleeps. [VERIFIED: examples/threadline_phoenix/AGENTS.md:1-15] [VERIFIED: examples/threadline_phoenix/AGENTS.md:63-78]

The repository separates capture, semantics, and exploration/operations responsibilities; this phase belongs entirely to the exploration/operations surface and must not modify capture or semantics. [VERIFIED: CLAUDE.md:9-17] Use canonical named verification entrypoints, especially verbatim `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. [VERIFIED: CLAUDE.md:30-64]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard Here |
|----------------|---------|---------|-------------------|
| Elixir / ExUnit | `1.17.3` in the available ASDF runtime; project constraint `~> 1.15` | Source contracts, rendered-output assertions, structural helpers | Existing project runtime and test framework; no new dependency. [VERIFIED: environment probe, 2026-09-13] [VERIFIED: mix.exs:33-45] |
| Phoenix LiveView / LiveViewTest | `1.2.11` lock | Render affected surfaces and use semantic `element`, `form`, `has_element?`, `render_submit` helpers | Existing optional integration and current test API. [VERIFIED: mix.lock:34] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| LazyHTML | `0.1.12` lock, test-only | Parse fragments and produce normalized trees for one-time structural comparison | Already installed in the test environment; `to_tree/2` supports sorted attributes and skipped whitespace nodes. [VERIFIED: mix.exs:101-105] [VERIFIED: mix.lock:21] [VERIFIED: deps/lazy_html/lib/lazy_html.ex:116-153] |
| Playwright | `1.60.0` lock | Existing desktop/mobile behavior, accessibility, overflow, and screenshot verification | Existing e2e harness; user-facing locators are the official priority. [VERIFIED: examples/threadline_phoenix/e2e/package-lock.json:491-498] [CITED: https://playwright.dev/docs/locators] |
| Git + SHA-256 manifest | Git `2.41.0`; `shasum` `6.02` available | Preserve renames and prove the committed fixture corpus is byte-identical | Existing fixture contract derives and validates tracked evidence entries. [VERIFIED: environment probe, 2026-09-13] [VERIFIED: test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:50-84] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Phoenix `1.8.13` | lock | Host example app and LiveView routing | Only for the existing example/browser integration. [VERIFIED: mix.lock:32] |
| Existing mechanical checker | repository source | Deterministic scorecard-floor proof | Run against the unchanged source-owned corpus after every implementation wave. [VERIFIED: mix.exs:124-128] |
| Existing screenshot baselines | committed Playwright snapshots | Visual-regression complement | Run normal assertions in the same environment; never update baselines in this phase. [CITED: https://playwright.dev/docs/test-snapshots] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing semantic selectors | New replacement provenance attributes | Rejected by D-02; it would reproduce the leak with different names. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] |
| LazyHTML normalized tree | Permanent full-DOM snapshots | Rejected by D-13; whole-DOM snapshots freeze incidental LiveView markup. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] |
| Existing screenshot assertions | New or regenerated pixel baselines | Rejected by D-15 and environment-sensitive rendering guidance. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] [CITED: https://playwright.dev/docs/test-snapshots] |
| Existing dependencies | New HTML/parser/test packages | Unnecessary; the current stack already exposes the required render, selector, and tree APIs. [VERIFIED: mix.exs:84-105] [VERIFIED: deps/lazy_html/lib/lazy_html.ex:47-153] |

**Installation:** None. Phase 201 should add no external package. [VERIFIED: existing dependency inventory in mix.exs:84-105]

## Package Legitimacy Audit

Not applicable: the recommended plan installs no package and uses only the repository's locked dependencies. [VERIFIED: mix.exs:84-105]

**Packages removed due to [SLOP] verdict:** none.  
**Packages flagged as suspicious [SUS]:** none.

## Current Residual Inventory

| Surface | Node(s) | Planning attributes to remove verbatim | Existing behavior selector |
|---------|---------|-----------------------------------------|----------------------------|
| Start | Record lookup panel | `data-earned-flow="EF1"`, `data-persona="P2"`, `data-jtbd="J4"` | `#tl-record-lookup`, labeled fields, `Open row history`. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex:222-257] |
| Start | Correlation lookup panel | `data-earned-flow="EF4"`, `data-persona="P1"`, `data-jtbd="J1"` | `#tl-correlation-lookup`, labeled input, `Open Timeline`. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex:263-275] |
| Exports | Timeline context | `data-earned-flow="EF3"`, `data-persona="P3"`, `data-jtbd="J6"` | `data-testid="timeline-export-context"` and outcome assertions. [VERIFIED: lib/threadline/operator_surface/live/export_status_live.ex:188-229] |
| Exports | Evidence context | `data-earned-flow="EF3"`, `data-persona="P3"`, `data-jtbd="J6"` | `data-testid="evidence-export-context"` and route/context assertions. [VERIFIED: lib/threadline/operator_surface/live/export_status_live.ex:248-255] |
| Evidence | Carry link | `data-earned-flow="EF3"`, `data-persona="P3"`, `data-jtbd="J6"` | role `link`, name `Carry to Exports`, and `/audit/exports?...` destination. [VERIFIED: lib/threadline/operator_surface/live/evidence_live.ex:350-369] |
| Row History | Shell root | `data-earned-flow="EF2"`, `data-persona="P1"`, `data-jtbd="J2"` | existing `data-testid="row-history-drawer"`, single H1, breadcrumb, and history content. [VERIFIED: lib/threadline/operator_surface/live/row_history_live.ex:40-64] [VERIFIED: test/threadline/operator_surface/live/row_history_live_test.exs:195-208] |
| Timeline | Carry link | `data-earned-flow="EF3"`, `data-persona="P3"`, `data-jtbd="J6"` | role `link`, name `Carry to Exports`, and canonical destination/query. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex:786-797] |

The direct ExUnit assertions to migrate are in five files; they currently assert the three-value tuples rather than only behavior. [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs:287-291] [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs:442-449] [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs:511-520] [VERIFIED: test/threadline/operator_surface/live/export_status_live_test.exs:256-270] [VERIFIED: test/threadline/operator_surface/live/export_status_live_test.exs:364-377] [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs:235-251] [VERIFIED: test/threadline/operator_surface/live/row_history_live_test.exs:195-208] [VERIFIED: test/threadline/operator_surface/live/timeline_live_test.exs:954-970]

Four Playwright specs currently locate the same behavior by `data-earned-flow`; the same files already contain the forms, names, routes, outcomes, and task IDs needed to replace those locators. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts:26-44] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts:79-94] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts:121-135] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts:196-214] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts:184-211] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts:208-223] [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:435-449]

## Architecture Patterns

### System Architecture Diagram

```text
Threadline-owned HEEx + Style.css/1
        |
        +--> source-derived zero-vocabulary contract -- offender? --> fail with file/pattern
        |                                              |
        |                                              +--> clean
        |
        +--> LiveView render scenarios --> normalized element tree
        |                               (drop text/comments and only the 3 removed attrs)
        |                                      |
        |                          pre-edit hash/count == post-edit hash/count?
        |                                      |
        |                                no --> fail   yes --> receipt
        |
        +--> browser output --> role/label/action tests --> desktop/mobile layout checks
        |
        +--> emitted CSS --> comment-vocabulary scan --> zero offenders

Committed operator-surface fixture corpus
        +--> manifest byte comparison --> unchanged? --> mix verify.mechanical
                                                   |
                                                   +--> browser complement

Capture / snapshot-update / paid critic boundaries: forbidden; never enter these branches.
```

The flow deliberately combines source coverage, representative output coverage, normalized structure, corpus integrity, and existing browser behavior because no single layer proves all six requirements. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]

### Recommended Project Structure

```text
test/threadline/operator_surface/
├── rendered_output_contract_test.exs       # exhaustive static/output/CSS guard + positive controls
├── rendered_structure_support.ex           # narrow test-only canonicalizer if extraction improves reuse
└── operator_surface_fixture_contract_test.exs  # existing immutable-corpus proof

.planning/audits/
└── 201-rendered-output-evidence.md          # one-time hashes/counts/commands; no DOM snapshot corpus

examples/threadline_phoenix/e2e/tests/
└── operator-shell-home.spec.ts              # durable git-moved behavior name
```

These exact new names are recommendations within the agent's discretion rather than existing paths. [ASSUMED]

### Pattern 1: Source-Derived Zero-Ignore Guard

**What:** Derive the owned input set from shipped `lib/threadline/operator_surface/live/*.ex`, the stress fixture/render sources, and the emitted `Style.css/1` output. Use two explicit lanes: exact forbidden attribute tokens may be checked directly in owned template source, while visible-vocabulary checks must inspect render-capable static copy or representative rendered output rather than ordinary Elixir/HEEx comments. Assert the inventory is nonempty and contains sentinel owned files; collect every offender and require exact `[]`; then seed each forbidden class in a synthetic string to prove the matcher fails. [ASSUMED]

**When to use:** For RENDER-01 through RENDER-03 and as the release handoff in D-17. The guard must not read `.planning/` at runtime and must not inspect arbitrary adopter data. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]

**Example:**

```elixir
# Source: repository pattern plus D-11/D-12; proposed implementation
@forbidden_attributes ["data-earned-flow", "data-persona", "data-jtbd"]

owned_sources = Path.wildcard("lib/threadline/operator_surface/live/*.ex")
assert owned_sources != []
assert "lib/threadline/operator_surface/live/start_live.ex" in owned_sources
assert scan_owned_sources(owned_sources) == []

for offender <- @forbidden_attributes do
  refute scan_fragment(~s(<div #{offender}="seed"></div>)) == []
end
```

The verbatim attribute names above come from current source: `data-earned-flow`, `data-persona`, and `data-jtbd`. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex:222-268]

### Pattern 2: Behavior-First Selector Migration

**What:** Replace taxonomy lookups with the most user-facing unique selector already present: form ID plus label/action for Start, existing task IDs for export contexts, link role/name plus destination for handoffs, and the existing Row History task ID and content. [CITED: https://playwright.dev/docs/locators]

**When to use:** At every test that currently asserts or locates an EF/P/J attribute. Do not add a test ID unless the migration proves a uniqueness gap. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]

**Example:**

```typescript
// Source: https://playwright.dev/docs/locators; adapted to existing repository selectors
const form = page.locator("#tl-record-lookup");
await expect(form.getByLabel("Table")).toBeVisible();
await expect(form.getByLabel("Record id")).toBeVisible();
await form.getByRole("button", { name: "Open row history" }).click();
```

The verbatim existing values are `#tl-record-lookup`, `Table`, `Record id`, and `Open row history`. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex:236-255]

### Pattern 3: Normalized One-Time Structural Receipt

**What:** Before source edits, render the seven affected scenarios and store only a canonical signature/hash and element count. Parse with `LazyHTML.from_fragment/1`, convert with `LazyHTML.to_tree(sort_attributes: true, skip_whitespace_nodes: true)`, recursively discard text and comments, discard only `data-earned-flow`, `data-persona`, and `data-jtbd`, retain tag, sorted class tokens, ID, and ordered element-child structure, then compare with post-edit renders. [ASSUMED]

**When to use:** Once in the implementation sequence, for D-13/RENDER-06. Commit the compact receipt, not complete rendered HTML. [VERIFIED: deps/lazy_html/lib/lazy_html.ex:47-76] [VERIFIED: deps/lazy_html/lib/lazy_html.ex:116-153]

**Example:**

```elixir
# Source: deps/lazy_html/lib/lazy_html.ex:47-153; proposed canonicalization skeleton
html
|> LazyHTML.from_fragment()
|> LazyHTML.to_tree(sort_attributes: true, skip_whitespace_nodes: true)
|> normalize_elements(drop_attributes: [
  "data-earned-flow",
  "data-persona",
  "data-jtbd"
])
|> :erlang.term_to_binary()
|> then(&:crypto.hash(:sha256, &1))
```

The three quoted values are the complete removed-attribute set in the current seven-node inventory. [VERIFIED: lib/threadline/operator_surface/live/start_live.ex:222-268] [VERIFIED: lib/threadline/operator_surface/live/export_status_live.ex:188-255] [VERIFIED: lib/threadline/operator_surface/live/evidence_live.ex:359-369] [VERIFIED: lib/threadline/operator_surface/live/row_history_live.ex:40-57] [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex:786-797]

### Pattern 4: Immutable Mechanical Corpus

**What:** Record the current `test/fixtures/operator_surface/manifest.sha256` bytes and tracked-corpus tree hash before implementation; compare after implementation; run the corpus contract and `mix verify.mechanical` without altering fixtures or scorecards. [VERIFIED: test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:5-74] [VERIFIED: mix.exs:124-128]

**When to use:** After each implementation wave and at the phase gate. The manifest paths are relative to the corpus directory, so direct `shasum -a 256 -c manifest.sha256` must run from `test/fixtures/operator_surface`. [VERIFIED: test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:65-74]

### Pattern 5: History-Preserving Durable Renames

Use `git mv` and update exact consumers in the same commit. Recommended mappings are `phase06_nyquist_ci_contract_test.exs` → `ci_workflow_parity_contract_test.exs`, `forward_only_gate_doc_contract_test.exs` → `critic_iteration_runbook_doc_contract_test.exs`, and `operator-shell-home-phase183.spec.ts` → `operator-shell-home.spec.ts`; update module names, `verify.doc_contract`, and the light-lane `testMatch`. [ASSUMED] The current exact consumer values are `test/threadline/forward_only_gate_doc_contract_test.exs` in `verify.doc_contract` and `/operator-shell-home-phase183\.spec\.ts/` in the Playwright light lane. [VERIFIED: mix.exs:108-117] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:103-115]

### Anti-Patterns to Avoid

- **Replacing EF/P/J with another provenance scheme:** violates D-02 and preserves the leak. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]
- **Counting known offenders:** a count floor can pass when one offender is replaced by another; use a complete input inventory, zero matches, and positive controls. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]
- **Scanning ordinary source comments or arbitrary rendered actor/row values:** the former broadens D-16 into repository-history cleanup and the latter censors adopter data; exact attribute-token checks may scan owned source, but visible-vocabulary checks must distinguish render-capable static copy from comments and host values. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]
- **Treating mechanical success as layout proof:** the executed Phase 198 audit found text and width mutations invisible to the mechanical checker; browser and structural proof remain required. [VERIFIED: .planning/audits/198-mechanical-sensitivity.md]
- **Refreshing pixels or scorecards to make a gate pass:** this destroys the fixed reference needed by RENDER-04/05 and violates D-15. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]
- **Replaying the landed cleanup:** current blobs already contain accepted final copy/CSS; only residual work should change. [VERIFIED: git object inspection, 2026-09-13]
- **Repo-wide chronology cleanup:** only rendered/emitted surfaces and the roadmap-named filenames are in scope. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML parsing | Regex-based DOM parser | Existing LazyHTML tree API | It already represents tags, attributes, comments, and children and can sort attributes/skip whitespace. [VERIFIED: deps/lazy_html/lib/lazy_html.ex:116-153] |
| LiveView interactions | Raw HTML substring-only interaction harness | `Phoenix.LiveViewTest` `element`, `form`, `has_element?`, and render helpers | These existing APIs describe element/form behavior. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Browser selectors | CSS selectors coupled to taxonomy | Playwright role, label, text, task IDs, and destinations | Official guidance prioritizes user-facing semantics and uses test IDs as an explicit fallback. [CITED: https://playwright.dev/docs/locators] |
| Pixel evidence | New screenshot framework or baseline corpus | Existing Playwright screenshot assertions | Screenshot output varies by environment; the committed same-environment baselines are the only permitted complement. [CITED: https://playwright.dev/docs/test-snapshots] |
| Fixture integrity | Ad-hoc file list or regenerated floor | Existing tracked manifest and fixture contract | It is nonempty, derived from tracked entries, and changes when tracked bytes change. [VERIFIED: test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:50-108] |
| Authorization | New stress access switch | Existing StressRouter/Auth/Coverage mounts | Existing router already omits, fails closed in production, or mounts the authorized session. [VERIFIED: lib/threadline/operator_surface/stress_router.ex:5-43] |

**Key insight:** This phase is an invariant-preserving deletion. Use existing renderers, parsers, selectors, fixtures, and gates; new abstraction is justified only for the narrow zero-vocabulary matcher and structural canonicalizer. [ASSUMED]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None: the scoped values are static HEEx attributes/copy, CSS comments, and test filenames; no database key, collection, ID, or user ID is being renamed. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] | No data migration. Keep arbitrary audit data outside the static-copy scanner. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] |
| Live service config | None: no externally stored dashboard/workflow/configuration is in the phase boundary. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] | No service patch. |
| OS-registered state | None found; the affected paths are library/test sources and Playwright specs, not service/unit registrations. [VERIFIED: repository path inventory, 2026-09-13] | No re-registration. |
| Secrets/env vars | No secret or environment-variable name is renamed. The existing local-only `ANTHROPIC_API_KEY` critic path is explicitly out of `ci.all` and forbidden for this phase. The verbatim key is `ANTHROPIC_API_KEY`. [VERIFIED: mix.exs:129-140] | Do not invoke the critic; no secret migration. |
| Build artifacts / installed packages | Two durable renames have explicit consumers: the doc-contract filename in `mix.exs` and the Playwright spec regex in `playwright.config.ts`. The third `phase06` test is discovered conventionally. No snapshot filename is tied to the historical spec. [VERIFIED: mix.exs:108-117] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:103-115] [VERIFIED: repository file inventory, 2026-09-13] | Use `git mv`, update module names/explicit references, and run the test discovery commands. No package reinstall or snapshot migration. |

## Common Pitfalls

### Pitfall 1: Guarding Only `data-jtbd`

**What goes wrong:** `data-earned-flow` or `data-persona` survives on the same rendered node.  
**Why it happens:** The roadmap grep is mistaken for the complete requirement.  
**How to avoid:** Treat all three verbatim attribute names as one atomic tuple and require zero matches across the derived source inventory and representative output. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]  
**Warning signs:** A test still contains `EF*`, `P*`, or `J*` solely to find UI behavior. [VERIFIED: current coupled tests cited in Current Residual Inventory]

### Pitfall 2: Proving Source but Not Output—or Output but Not Source

**What goes wrong:** A representative render misses an unvisited branch, or a source regex misses generated emitted CSS semantics.  
**Why it happens:** One evidence layer is asked to be exhaustive across incompatible representations.  
**How to avoid:** Derive all owned source inputs, render emitted CSS directly, cover representative LiveView branches, and seed positive controls. [ASSUMED]  
**Warning signs:** The guard can pass with an empty glob or has no seeded failure case.

### Pitfall 3: Structural Equality Includes Removed Attributes or Text

**What goes wrong:** The required cleanup itself makes the signature differ, or accepted text changes turn structural proof into a content snapshot.  
**Why it happens:** Raw HTML is compared rather than an explicit element-shape model.  
**How to avoid:** Discard text/comments and exactly the three removed attributes; retain tags, IDs, normalized classes, child order/nesting, and element count. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]  
**Warning signs:** The receipt stores complete HTML or excludes additional attributes that could hide behavior changes.

### Pitfall 4: Running Manifest Verification from the Wrong Directory

**What goes wrong:** `shasum` reports missing files even though the manifest is valid.  
**Why it happens:** Manifest paths are rooted at `test/fixtures/operator_surface`, not repository root.  
**How to avoid:** Run `(cd test/fixtures/operator_surface && shasum -a 256 -c manifest.sha256)` or use the existing fixture contract. [VERIFIED: test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:65-74]  
**Warning signs:** Every manifest entry reports missing while the ExUnit fixture contract is green.

### Pitfall 5: Following Stale Roadmap Locations Literally

**What goes wrong:** The plan deletes work already landed, expects a removed `ia_lock` test, or edits stale line numbers.  
**Why it happens:** Roadmap notes predate Phases 199/200 integration.  
**How to avoid:** Treat HEAD plus D-08–D-10 as the baseline; residual inventory is seven nodes, 21 attributes, affected tests, and three current filename candidates. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] [VERIFIED: repository inventory, 2026-09-13]  
**Warning signs:** Any task reintroduces old stress copy, edits CSS only to reproduce the existing blob, or references `ia_lock_doc_contract_test.exs`.

### Pitfall 6: Accidental Recapture or Paid Critic Execution

**What goes wrong:** Baselines or floor inputs change, making the no-change proof circular and potentially spending external API credit.  
**Why it happens:** Capture projects and the local critic live beside safe verification aliases.  
**How to avoid:** Keep an explicit denied-command list in plans and reviews. Safe gates include `mix verify.mechanical`, targeted `mix test`, normal desktop/mobile browser tests, and `mix ci.all`; forbidden paths include `mix verify.capture`, `mix verify.ui_critique`, `npm run capture:tier-a`, other `capture:*` scripts, `npm run critic:score`, `npm run critic:gate`, and Playwright `--update-snapshots`. [VERIFIED: mix.exs:124-140] [VERIFIED: mix.exs:161-186] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:25-102]  
**Warning signs:** Fixture/scorecard/snapshot diffs appear, a capture Playwright project is selected, or `ANTHROPIC_API_KEY` is requested.

## Code Examples

### LiveViewTest Form/Outcome Assertion

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
view
|> form("#tl-correlation-lookup", %{
  "correlation" => %{"correlation_id" => "incident 42/alpha"}
})
|> render_submit()
```

The verbatim values `#tl-correlation-lookup`, `correlation`, `correlation_id`, and `incident 42/alpha` are already exercised in the current test. [VERIFIED: test/threadline/operator_surface/live/start_live_test.exs:511-522]

### Export Context Assertion

```elixir
# Source: existing repository task selector
assert has_element?(view, ~s([data-testid="timeline-export-context"]))
```

The verbatim task value is `timeline-export-context`. [VERIFIED: lib/threadline/operator_surface/live/export_status_live.ex:188-195]

### Behavior-Oriented Handoff Locator

```typescript
// Source: https://playwright.dev/docs/locators
const carry = page.getByRole("link", { name: "Carry to Exports" }).first();
await expect(carry).toHaveAttribute("href", /\/audit\/exports\?/);
await carry.click();
```

The verbatim link name is `Carry to Exports`, and both affected sources navigate to `/audit/exports?...`. [VERIFIED: lib/threadline/operator_surface/live/evidence_live.ex:359-369] [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex:786-797]

### CSS Positive Control

```elixir
# Source: D-11 positive-control requirement; proposed test fixture
assert css_vocabulary_offenders("/* Phase 999 */ .threadline-ui {}") != []
assert css_vocabulary_offenders(rendered_threadline_css()) == []
```

`Phase 999` is synthetic test input, not an in-repo product value. [ASSUMED]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Planning taxonomy as browser test hooks | Accessible/task behavior selectors | Phase 201 locked decision | Test intent survives roadmap churn and browser DOM no longer leaks planning provenance. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] |
| Raw/known-location offender assertions | Source-derived zero-ignore guard with positive controls | Phase 201 locked decision | New owned templates and emitted assets enter the contract automatically. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] |
| Permanent raw DOM snapshots | One-time normalized structural receipt | Phase 201 locked decision | Proves element shape without freezing LiveView internals. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] |
| Treat mechanical score as full visual proof | Mechanical floor plus structural and browser complements | Phase 198 sensitivity result / Phase 201 | Text/width blindness is handled honestly. [VERIFIED: .planning/audits/198-mechanical-sensitivity.md] |
| Phase-owned stress headings | `Primitives Matrix`, `Data Display`, `Data States` | Granular commit `1a5fbef2`, integrated by `18fe87f5` | Accepted durable maintainer copy is already the baseline. [VERIFIED: lib/threadline/operator_surface/live/stress_live.ex:369-370] [VERIFIED: lib/threadline/operator_surface/live/stress_live.ex:463-493] [VERIFIED: git object inspection, 2026-09-13] |

**Deprecated/outdated:**

- Roadmap line references and the `ia_lock` rename item are stale relative to HEAD; inventory current files rather than executing the old list mechanically. [VERIFIED: .planning/ROADMAP.md:630-635] [VERIFIED: repository inventory, 2026-09-13]
- The former mechanical-corpus absence hazard documented during Phase 198 is no longer current: the existing fixture contract requires a nonempty tracked manifest and validates it. [VERIFIED: test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:65-75]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Use two independently bisectable implementation slices after a contract/evidence setup slice, with targeted checks per task and the full affected render/browser set per wave. | Summary / Validation Architecture | Planner may choose more plans or a different cadence, but ordering must still capture pre-edit evidence before mutation. |
| A2 | Recommended new paths/names and their derived quick commands: `rendered_output_contract_test.exs`, optional `rendered_structure_support.ex`, `201-rendered-output-evidence.md`, `ci_workflow_parity_contract_test.exs`, `critic_iteration_runbook_doc_contract_test.exs`, and `operator-shell-home.spec.ts`. | Architecture Patterns / Validation Architecture | Exact paths may change; explicit consumers and `git mv` preservation remain mandatory. |
| A3 | A narrow LazyHTML canonicalizer can render/capture all seven current scenarios through existing test fixtures without a new dependency; the Wave 0 receipt/helper can implement the required comparison. | Architecture Patterns / Validation Architecture / Open Questions | If fixture reuse is awkward, executor must still produce the same bounded pre/post fields by another existing test-only path. |
| A4 | A combined source/output/CSS matcher can be made exhaustive and non-vacuous without inspecting host-supplied data; render-capable copy can be distinguished from ordinary source comments. | Architecture Patterns / Pitfalls / Validation Architecture | Poor scoping could miss branches, reject adopter content, or broaden into historical-comment cleanup; positive controls and sentinel inventory are required. |
| A5 | Synthetic CSS string `/* Phase 999 */` is an appropriate positive control. | Code Examples | Any unambiguously forbidden synthetic value is acceptable. |
| A6 | New abstraction should be limited to the narrow matcher/canonicalizer, and an evidence schema should assert zero exceptions or a bounded valid registry if needed. | Don't Hand-Roll / Validation Architecture | Executor could over-engineer the phase or leave evidence informal. |
| A7 | Only the post-change run can determine whether any measured value moves; current evidence predicts zero entries. | Open Questions | A movement would require the locked narrow-check-or-bounded-registry contingency. |
| A8 | Research remains valid through 2026-10-13 if HEAD does not change. | Metadata | Any intervening render/test change requires re-inventory. |

## Open Questions — RESOLVED

1. **Should the structural receipt helper remain local to the contract test or live in `test/support`?**
   - What we know: LazyHTML is already test-only and the evidence is one-time, not a permanent snapshot suite. [VERIFIED: mix.exs:101-105] [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]
   - RESOLVED disposition: keep the helper private in `test/threadline/operator_surface/rendered_output_contract_test.exs`; only move it to test support if execution demonstrates a second real caller. The evidence is one-time, LazyHTML is already test-only, and no current second consumer exists, so a production abstraction is not justified. [VERIFIED: mix.exs:101-105] [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]

2. **Will any measured value move after residual work?**
   - What we know: residual implementation is attribute removal and test/filename migration; accepted text/CSS cleanup is already at baseline, and the Phase 198 probe found text/width invisible to the mechanical checker. [VERIFIED: repository inventory, 2026-09-13] [VERIFIED: .planning/audits/198-mechanical-sensitivity.md]
   - RESOLVED disposition: expect zero measured movement and an explicit zero-entry registry because the residual implementation is attribute/test-identity only and the accepted copy/CSS blobs are already fixed. Final deterministic execution remains the deciding evidence; only real measured movement may enter the bounded registry, with exact stable node ID, numeric before/after/delta, rationale, and expiry. Never recapture. [VERIFIED: .planning/audits/198-mechanical-sensitivity.md] [VERIFIED: .planning/ROADMAP.md:623-626]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Erlang | Mix/LiveView tests | ✓ via ASDF | `27` / ERTS `15.2.3` | Prefix commands with `ASDF_ERLANG_VERSION=27.3`. [VERIFIED: environment probe, 2026-09-13] |
| Elixir / Mix | Contracts and gates | ✓ via ASDF | `1.17.3` / Mix `1.17.3` | Prefix commands with `ASDF_ELIXIR_VERSION=1.17.3-otp-27`; bare `mix` is not selected by the current untracked `.tool-versions`. [VERIFIED: environment probe, 2026-09-13] |
| Node / npm | Playwright | ✓ | Node `v22.14.0`, npm `11.1.0` | — [VERIFIED: environment probe, 2026-09-13] |
| Playwright | Browser verification | ✓ | `1.60.0` | Use existing desktop/mobile projects only. [VERIFIED: environment probe, 2026-09-13] [VERIFIED: examples/threadline_phoenix/e2e/package-lock.json:491-498] |
| PostgreSQL | Example/test integration | ✓ | accepting connections on local test socket/port | Existing test helper owns setup. [VERIFIED: environment probe, 2026-09-13] |
| Docker | Optional local infrastructure | ✓ | server `29.5.2` | Not required by targeted phase checks. [VERIFIED: environment probe, 2026-09-13] |
| Git / shasum | rename and byte proof | ✓ | Git `2.41.0`, shasum `6.02` | — [VERIFIED: environment probe, 2026-09-13] |

**Missing dependencies with no fallback:** none. [VERIFIED: environment probe, 2026-09-13]

**Missing dependencies with fallback:** the untracked `.tool-versions` does not select Elixir; use the exact ASDF environment prefix and do not edit the user's file as part of this phase. [VERIFIED: environment probe, 2026-09-13]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Elixir `1.17.3`; Playwright `1.60.0`. [VERIFIED: environment probe, 2026-09-13] |
| Config file | Root `mix.exs`; browser `examples/threadline_phoenix/e2e/playwright.config.ts`. [VERIFIED: mix.exs:108-188] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:1-124] |
| Quick run command | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/threadline/operator_surface/rendered_output_contract_test.exs` [ASSUMED] |
| Full suite command | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix ci.all` [VERIFIED: CLAUDE.md:49-54] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RENDER-01 | No static planning vocabulary in operator-visible copy | source contract + representative LiveView integration | `... mix test test/threadline/operator_surface/rendered_output_contract_test.exs test/threadline/operator_surface/stress_router_test.exs` | ❌ Wave 0 contract; stress test exists. [VERIFIED: test/threadline/operator_surface/stress_router_test.exs:360-381] |
| RENDER-02 | No planning attributes in owned source or rendered DOM; behavior survives selector migration | source/output contract + LiveView + e2e | `... mix test test/threadline/operator_surface/live/{start_live_test,export_status_live_test,evidence_live_test,row_history_live_test,timeline_live_test}.exs` then targeted browser command below | ❌ Wave 0 contract; behavior tests exist. [VERIFIED: current residual test inventory] |
| RENDER-03 | Emitted CSS has no phase/milestone comments | component render contract + positive control | `... mix test test/threadline/operator_surface/rendered_output_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` | ❌ Wave 0 contract; style contract exists. [VERIFIED: repository test inventory, 2026-09-13] |
| RENDER-04 | Fixture bytes and mechanical floor unchanged | integrity + deterministic gate | `... mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs && ... mix verify.mechanical` | ✅ [VERIFIED: test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:65-84] [VERIFIED: mix.exs:124-128] |
| RENDER-05 | Zero recapture; zero expected exceptions or bounded registered exception | contract + evidence review | same RENDER-04 command plus evidence artifact assertion that manifest hashes are unchanged and exception registry is empty/valid | ❌ Wave 0 evidence schema. [ASSUMED] |
| RENDER-06 | Normalized structure equal; desktop/mobile layout/accessibility/screenshots green | structural integration + e2e | targeted LiveView command plus targeted browser command below | ❌ Wave 0 structural receipt; existing e2e specs. [VERIFIED: current test inventory] |

Use this targeted LiveView command after selector/source edits:

```bash
ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test \
  test/threadline/operator_surface/live/start_live_test.exs \
  test/threadline/operator_surface/live/export_status_live_test.exs \
  test/threadline/operator_surface/live/evidence_live_test.exs \
  test/threadline/operator_surface/live/row_history_live_test.exs \
  test/threadline/operator_surface/live/timeline_live_test.exs \
  test/threadline/operator_surface/stress_router_test.exs \
  test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
```

This exact pre-change command completed with verbatim result `147 tests, 0 failures` on 2026-09-13. [VERIFIED: executed test output, 2026-09-13]

Use this targeted browser command after Playwright selector/filename edits:

```bash
ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 \
mix verify.example_browser \
  --project=desktop-chromium \
  --project=mobile-chromium \
  operator-earned-flows.spec.ts \
  operator-home-nav-mobile.spec.ts \
  operator-shell-home.spec.ts \
  operator-responsive-mobile-first.spec.ts
```

Before the rename, the equivalent command using `operator-shell-home-phase183.spec.ts` completed with verbatim result `60 passed` after `19 tests, 0 failures` in the e2e unit preflight on 2026-09-13. [VERIFIED: executed test output, 2026-09-13]

### Sampling Rate

- **Per task commit:** targeted new contract plus the directly affected LiveView test file; run `mix verify.mechanical` whenever source markup/CSS changes. [ASSUMED]
- **Per wave merge:** all seven affected render scenarios and both browser projects for the four selector-coupled specs. [ASSUMED]
- **Phase gate:** `mix ci.all` green, example-app `mix precommit` green after its changes, corpus manifest byte-identical, structural receipt equal, and git diff contains no fixture/scorecard/snapshot changes. [VERIFIED: CLAUDE.md:49-64] [VERIFIED: examples/threadline_phoenix/AGENTS.md:3-6]

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/rendered_output_contract_test.exs` — source-derived static/output/CSS guard, representative renders, non-vacuity sentinels, and positive controls. [ASSUMED]
- [ ] A narrow structural canonicalizer (private helper first) and pre-edit receipt for all seven affected nodes. [ASSUMED]
- [ ] `.planning/audits/201-rendered-output-evidence.md` with landed-commit blob attribution, pre/post normalized hashes/counts, fixture manifest hash, exact safe commands/results, exception count, and explicit statement that no forbidden path ran. [ASSUMED]
- [ ] Update exact test discovery references after the two consumed `git mv` operations. [VERIFIED: mix.exs:108-117] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:103-115]

No framework install is needed. [VERIFIED: Standard Stack]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes, preserve-only | Existing operator Auth mount remains untouched; this phase adds no auth path. [VERIFIED: lib/threadline/operator_surface/stress_router.ex:28-40] |
| V3 Session Management | yes, preserve-only | Existing LiveView session wiring remains untouched; structural and browser checks detect accidental markup/routing drift. [VERIFIED: lib/threadline/operator_surface/stress_router.ex:28-40] |
| V4 Access Control | yes | Keep verbatim production fail-close state `:prod` and error `Threadline stress surface is dev/test-only`, plus existing Auth/Coverage on-mount hooks. [VERIFIED: lib/threadline/operator_surface/stress_router.ex:17-40] |
| V5 Input Validation | yes | Scan only Threadline-owned static inputs/assets; never reject host actor names, row values, or audit metadata based on phase-like text. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] |
| V6 Cryptography | no new cryptography | Use existing SHA-256 manifest/hash mechanisms; do not introduce custom cryptographic behavior. [VERIFIED: test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:50-84] |

### Known Threat Patterns for Phoenix LiveView Rendered Cleanup

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Internal planning metadata disclosed in DOM or CSS | Information Disclosure | Exhaustive owned-source/output/CSS zero-match guard with seeded failures. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] |
| Stress route becomes available in production or loses auth hooks | Elevation of Privilege | Preserve and test the existing omit/prod/auth branches. [VERIFIED: lib/threadline/operator_surface/stress_router.ex:16-43] |
| Evidence is made green by changing the reference corpus | Tampering / Repudiation | Compare tracked byte manifest pre/post and reject fixture, scorecard, or baseline diffs. [VERIFIED: test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:50-108] |
| Host-supplied content resembling `Phase 2` is blocked | Denial of Service / Integrity | Keep static vocabulary matching bounded to Threadline-owned templates, fixtures, and emitted assets. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md] |
| Paid/local critic invoked unintentionally | Information Disclosure / Cost abuse | Do not run `verify.ui_critique` or critic npm scripts; `ci.all` intentionally contains only deterministic critic trust. [VERIFIED: mix.exs:129-140] [VERIFIED: mix.exs:177-186] |

## No-Recapture / No-Paid-Critic Boundary

Allowed verification commands are normal targeted `mix test`, `mix verify.mechanical`, existing desktop/mobile Playwright projects, example `mix precommit`, and `mix ci.all`. [VERIFIED: CLAUDE.md:30-64] [VERIFIED: mix.exs:161-186] [VERIFIED: examples/threadline_phoenix/AGENTS.md:3-6]

The plan must explicitly deny all of the following:

- `mix verify.capture` and any `capture:*` npm script or capture-only Playwright project. [VERIFIED: mix.exs:139-140] [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:25-102]
- Playwright `--update-snapshots` or any committed PNG baseline change. [CITED: https://playwright.dev/docs/test-snapshots]
- `mix verify.ui_critique`, `npm run critic:score`, `npm run critic:gate`, or any paid/LLM critic path. [VERIFIED: mix.exs:129-140] [VERIFIED: test/threadline/forward_only_gate_doc_contract_test.exs:21-30]
- Any edit to `test/fixtures/operator_surface/` or regenerated Tier-A scorecard used to absorb this cleanup. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]

## Sources

### Primary (HIGH confidence)

- Current Threadline source and tests cited inline — exact residual values, selectors, routing guards, dependency locks, aliases, and fixture integrity behavior. [VERIFIED: repository files opened 2026-09-13]
- `.planning/phases/201-rendered-output/201-CONTEXT.md` — D-01 through D-17, discretion, and scope boundary. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]
- `.planning/REQUIREMENTS.md:57-64` and `.planning/ROADMAP.md:616-635` — requirement wording and phase gate. [VERIFIED: .planning/REQUIREMENTS.md:57-64] [VERIFIED: .planning/ROADMAP.md:616-635]
- `.planning/audits/198-mechanical-sensitivity.md` — executed mechanical sensitivity matrix. [VERIFIED: .planning/audits/198-mechanical-sensitivity.md]
- Git object inspection of `5752e357`, `1a5fbef2`, `18fe87f5`, and HEAD — landed cleanup attribution and byte identity. [VERIFIED: git object inspection, 2026-09-13]
- Executed pre-change ExUnit, mechanical, corpus-manifest, and desktop/mobile browser probes — baseline health. [VERIFIED: executed test output, 2026-09-13]

### Secondary (MEDIUM confidence)

- [Phoenix.LiveViewTest official docs](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html) — semantic element/form interaction APIs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- [Playwright locators official docs](https://playwright.dev/docs/locators) — locator priority. [CITED: https://playwright.dev/docs/locators]
- [Playwright visual comparisons official docs](https://playwright.dev/docs/test-snapshots) — environment sensitivity of screenshot output. [CITED: https://playwright.dev/docs/test-snapshots]

### Tertiary (LOW confidence)

- None; implementation recommendations not yet proven are isolated in the Assumptions Log. [VERIFIED: Assumptions Log]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — every recommended tool is already locked or installed; no package addition. [VERIFIED: mix.exs:84-105] [VERIFIED: mix.lock:21-34]
- Architecture: HIGH — driven by locked decisions and current render/test topology; only exact helper/file placement remains discretionary. [VERIFIED: .planning/phases/201-rendered-output/201-CONTEXT.md]
- Pitfalls: HIGH — grounded in the current residual inventory, executed Phase 198 audit, and current aliases/config. [VERIFIED: .planning/audits/198-mechanical-sensitivity.md] [VERIFIED: mix.exs:124-186]

**Research date:** 2026-09-13  
**Valid until:** 2026-10-13 (stable repository-local phase research; re-inventory if HEAD changes before planning). [ASSUMED]
