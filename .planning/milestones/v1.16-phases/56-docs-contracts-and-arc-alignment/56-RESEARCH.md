# Phase 56: Docs, Contracts, and Arc Alignment - Research

**Researched:** 2026-05-05 [VERIFIED: codebase audit]
**Domain:** Documentation contract alignment for shipped investigation APIs plus planning-arc source-of-truth cleanup [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repo-local docs, tests, roadmap, and environment were all inspected directly]

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md`. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md]

### Locked Decisions
- **D-01:** `Threadline.incident_bundle/2` is the canonical transaction
  drill-down story for v1.16 docs. It should be taught as the default answer to
  "show me one transaction incident" across the README-adjacent docs, domain
  reference, quickstart, example README, and incident playbook.
- **D-02:** `Threadline.audit_changes_for_transaction/2`,
  `Threadline.transaction_context/2`, and `Threadline.change_diff/2` remain
  public, stable lower-level building blocks. They should be documented as the
  underlying primitives for advanced/custom composition, not as a co-equal
  first-choice path for new adopters.
- **D-03:** Avoid a dual-canonical story. Docs may explain layering, but they
  should not force new readers to choose between raw composition and the
  packaged incident bundle when one path is clearly the intended default.
- **D-04:** Keep `README.md` concise and library-idiomatic: short value
  proposition, install path, one happy-path snippet, and a compact investigation
  routing map that exposes the modern exploration surface without becoming a
  second domain guide.
- **D-05:** The README should explicitly mention the investigation-surface
  hierarchy: use `Threadline.timeline/2` for smaller eager slices,
  `Threadline.timeline_page/2` for large stable windows, higher-level
  investigation helpers for common support questions, and
  `Threadline.incident_bundle/2` for transaction drill-down.
- **D-06:** Keep semantics details, auth/tenancy caveats, SQL, and richer
  operator examples in the guides and example README, not duplicated in the root
  README.
- **D-07:** Phase 56 should use targeted literal assertions, anchored snippet
  extraction, and a small number of cross-doc invariant checks. This matches the
  existing ExUnit/doc-contract style and provides the best signal-to-noise ratio.
- **D-08:** Lock public contractual truth, not editorial prose. Stable items
  include API names, section anchors, copied router/example snippets, the
  canonical "which API first?" routing, the eager-vs-paged rule, the promoted
  `incident_bundle/2` story, and the host-owned auth/policy honesty lines.
- **D-09:** Do not adopt whole-file snapshots or broad exact-string contracts
  for README/guides/planning docs. They create high-noise CI and freeze harmless
  editorial improvements.
- **D-10:** Do not make doctest/doctest-file the primary Phase 56 strategy.
  They are useful for small pure code examples, but they are a poor fit for the
  prose-heavy, side-effectful guide surfaces involved here.
- **D-11:** `.planning/MILESTONE-ARC.md` remains the single canonical strategic
  recommendation file. It owns the ranked forward arc and rationale.
- **D-12:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, and
  `.planning/STATE.md` should summarize and point to `MILESTONE-ARC.md`, not
  restate the candidate milestone table or duplicate the ranking logic.
- **D-13:** Future planning docs should reference the arc when they inherit or
  override it, but they should copy only the local consequence of that decision,
  not the full strategic table.
- **D-14:** Prefer cohesive, one-shot recommendations that fit the existing
  architecture and project goals. Downstream agents should resolve ordinary
  design/documentation tradeoffs decisively instead of escalating every choice.
- **D-15:** Escalate to the user only for genuinely high-impact product or
  architectural choices that could materially change the project's direction,
  semantics, or trust boundary.
- **D-16:** Preserve least surprise for both maintainers and adopters: one
  canonical public path per common investigation question, explicit layering for
  advanced users, host-owned authorization boundaries, and low-noise drift
  guards.

### Claude's Discretion
- Exact wording of the README routing map, provided it stays concise and points
  readers to the deeper guides for detail.
- Whether to introduce one new narrow cross-doc contract test or extend the
  existing doc-contract files, provided the contract posture above is preserved.
- The exact degree of planning-doc wording refresh in `PROJECT.md` and `STATE.md`,
  provided `MILESTONE-ARC.md` remains the canonical strategic source.

### Deferred Ideas (OUT OF SCOPE)
- Any new investigation API beyond the shipped v1.16 surface.
- New auth/tenancy/policy framework behavior beyond the current host-owned
  boundary.
- UI/operator-surface work or `threadline_web`-style packaging.
- Broader planning-system redesign beyond making `MILESTONE-ARC.md` the
  canonical strategic source and keeping other docs pointer-based.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-04 | README, domain reference, example docs, and contract tests converge on one canonical "which API for which investigation question" story, and the milestone arc records the standing next-milestone order for future planning. [VERIFIED: .planning/REQUIREMENTS.md] | Use a two-step plan: first align the public docs around the hierarchy `timeline/2` -> `timeline_page/2` -> investigation helpers -> `incident_bundle/2`, then lock that story with targeted ExUnit doc-contract assertions plus pointer-style planning-doc invariants. [VERIFIED: README.md, guides/domain-reference.md, guides/getting-started-saas.md, guides/incident-playbook.md, examples/threadline_phoenix/README.md, test/threadline/*doc_contract*_test.exs, .planning/MILESTONE-ARC.md] |
</phase_requirements>

## Summary

Phase 56 is a consolidation slice, not a behavior slice: the shipped truth for the canonical transaction drill-down already exists in `Threadline.incident_bundle/2`, its investigation tests, and the Phoenix example README, but the root README, domain reference, getting-started guide, and incident playbook still expose older raw-composition drill-down paths as first-class stories in different places. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md, test/threadline/investigation_test.exs, examples/threadline_phoenix/README.md, README.md, guides/domain-reference.md, guides/getting-started-saas.md, guides/incident-playbook.md]

The clean planning split already described in the roadmap is correct and should be preserved. Plan `56-01` should be a doc-narrative convergence sweep across the public surfaces. Plan `56-02` should be the dependent lock step: extend the existing doc-contract suite, add one narrow planning-doc invariant guard only if needed, and refresh `PROJECT.md` / `STATE.md` wording so they point at `.planning/MILESTONE-ARC.md` instead of re-explaining the ranked forward arc. [VERIFIED: .planning/ROADMAP.md, .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, .planning/PROJECT.md, .planning/STATE.md, .planning/MILESTONE-ARC.md]

**Primary recommendation:** Treat `Threadline.incident_bundle/2` as the only default transaction-incident answer in user-facing docs, demote `audit_changes_for_transaction/2` / `transaction_context/2` / `change_diff/2` to advanced building blocks, and lock the resulting routing map with targeted literal and cross-doc invariant tests. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, test/threadline/investigation_test.exs, test/threadline/exploration_routing_doc_contract_test.exs]

## Project Constraints (from CLAUDE.md)

- Keep the three-layer boundary explicit: capture owns row mutation persistence, semantics owns action meaning, and exploration owns timelines/diffs/operations. Docs in this phase must not collapse those responsibilities. [VERIFIED: CLAUDE.md]
- Use Threadline domain language consistently: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation`. [VERIFIED: CLAUDE.md]
- Cite the canonical verification entrypoints in docs and planning where relevant: `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. [VERIFIED: CLAUDE.md, mix.exs]
- Favor named Mix aliases over ad-hoc commands because that is an explicit CI/documentation convention in this repo. [VERIFIED: CLAUDE.md, mix.exs]
- Preserve the host-owned auth/policy boundary; the library and docs should not imply Threadline owns tenancy or authorization policy. [VERIFIED: CLAUDE.md, .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md]

## Plan Split Implications

1. `56-01` should touch only narrative-producing files: `README.md`, `guides/domain-reference.md`, `guides/getting-started-saas.md`, `guides/incident-playbook.md`, `guides/production-checklist.md`, and `examples/threadline_phoenix/README.md`. This keeps the canonical wording editable before tests freeze the chosen literals. [VERIFIED: .planning/ROADMAP.md, .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md]
2. `56-02` should consume the final literals from `56-01` and update only drift guards plus planning summaries: existing doc-contract tests under `test/threadline/`, plus `.planning/PROJECT.md` and `.planning/STATE.md`, and optionally one new planning-doc contract if grep-based manual checking feels too weak. [VERIFIED: .planning/ROADMAP.md, test/threadline/readme_doc_contract_test.exs, test/threadline/exploration_routing_doc_contract_test.exs, test/threadline/getting_started_saas_doc_contract_test.exs, test/threadline/incident_playbook_doc_contract_test.exs, test/threadline/example_phoenix_readme_contract_test.exs]
3. Do not mix the two steps into one plan. The current suite asserts exact headings, extracted snippets, and selected literals, so editing tests before the narrative is settled will create avoidable churn. [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs, test/threadline/readme_doc_contract_test.exs, .planning/milestones/v1.15-phases/52-docs-and-contract-alignment/52-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical investigation routing (`timeline/2` vs `timeline_page/2` vs helpers) [VERIFIED: README.md, guides/domain-reference.md] | API / Backend | Database / Storage | The public library API defines which call adopters should make first, but the guidance is constrained by shipped ordering and paging semantics over `AuditChange.captured_at` and `id`. [VERIFIED: guides/domain-reference.md, .planning/milestones/v1.16-phases/53-timeline-paging-contract/53-CONTEXT.md] |
| Canonical transaction drill-down story (`incident_bundle/2`) [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, test/threadline/investigation_test.exs] | API / Backend | Frontend Server (SSR) | The library contract is the source of truth, while the Phoenix example endpoint is only the host rendering/proof surface for that contract. [VERIFIED: examples/threadline_phoenix/README.md, .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] |
| Auth/policy honesty line in incident docs [VERIFIED: guides/getting-started-saas.md, guides/incident-playbook.md, examples/threadline_phoenix/README.md] | Frontend Server (SSR) | API / Backend | The host endpoint enforces the authenticated baseline, while the library remains deliberately auth-agnostic. [VERIFIED: .planning/milestones/v1.15-phases/52-docs-and-contract-alignment/52-CONTEXT.md, examples/threadline_phoenix/README.md] |
| Standing milestone arc source [VERIFIED: .planning/MILESTONE-ARC.md] | CDN / Static | — | The strategic recommendation is a static documentation concern; other planning docs should point at it rather than duplicate its ranked table. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, .planning/PROJECT.md, .planning/STATE.md] |

## Touched File Clusters

### Cluster A: Public adoption and routing docs
- `README.md` [VERIFIED: README.md]
- `guides/domain-reference.md` [VERIFIED: guides/domain-reference.md]
- `guides/getting-started-saas.md` [VERIFIED: guides/getting-started-saas.md]
- `guides/incident-playbook.md` [VERIFIED: guides/incident-playbook.md]
- `guides/production-checklist.md` [VERIFIED: guides/production-checklist.md]
- `examples/threadline_phoenix/README.md` [VERIFIED: examples/threadline_phoenix/README.md]

### Cluster B: Existing doc-contract proof surfaces
- `test/threadline/readme_doc_contract_test.exs` [VERIFIED: test/threadline/readme_doc_contract_test.exs]
- `test/threadline/exploration_routing_doc_contract_test.exs` [VERIFIED: test/threadline/exploration_routing_doc_contract_test.exs]
- `test/threadline/getting_started_saas_doc_contract_test.exs` [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs]
- `test/threadline/incident_playbook_doc_contract_test.exs` [VERIFIED: test/threadline/incident_playbook_doc_contract_test.exs]
- `test/threadline/example_phoenix_readme_contract_test.exs` [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]
- `test/threadline/investigation_test.exs` as shipped API truth for `incident_bundle/2` semantics [VERIFIED: test/threadline/investigation_test.exs]

### Cluster C: Planning-arc pointer docs
- `.planning/MILESTONE-ARC.md` should remain canonical and mostly unchanged unless wording clarity is required. [VERIFIED: .planning/MILESTONE-ARC.md]
- `.planning/PROJECT.md` and `.planning/STATE.md` should be reduced to pointer-style summaries where they still restate candidate future work. [VERIFIED: .planning/PROJECT.md, .planning/STATE.md]
- `.planning/ROADMAP.md` already points to the arc and mainly needs consistency review, not a strategic rewrite. [VERIFIED: .planning/ROADMAP.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Runs the test and Mix tooling used for docs/contracts. | Installed locally and required for all phase verification commands. [VERIFIED: `elixir --version`] |
| Mix | 1.19.5 | Canonical task runner for formatting, tests, and CI aliases. | The repo already exposes named verification aliases through Mix and points contributors at them. [VERIFIED: `mix --version`, mix.exs, CLAUDE.md] |
| ExUnit | bundled with Elixir toolchain [ASSUMED] | Current doc-contract framework. | Every existing contract guard for this phase is already written in ExUnit, so no new test framework is warranted. [VERIFIED: test/threadline/*doc_contract*_test.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Threadline.GettingStartedFixtures` | repo-local helper | Extracts anchored snippets from example code so docs can copy real source blocks. | Use when a doc should stay synchronized with example source, especially router/blog snippets. [VERIFIED: test/support/getting_started_fixtures.ex, test/threadline/getting_started_saas_doc_contract_test.exs] |
| `Threadline.ReadmeQuickstartFixtures` | repo-local helper | Exercises README quickstart API shapes against compiled code. | Use for root README examples that should stay API-truthful without snapshotting the entire file. [VERIFIED: test/support/readme_quickstart_fixtures.ex, test/threadline/readme_doc_contract_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Targeted literal assertions | Whole-file snapshots | Rejected because current phase decisions explicitly forbid noisy snapshot contracts for prose-heavy docs. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md] |
| Existing ExUnit doc-contract files | Doctests / doctest-file | Rejected because the relevant surfaces are prose-heavy and side-effectful, not pure code examples. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md] |
| Pointer summaries in planning docs | Repeating the milestone candidate table in multiple files | Rejected because the project already created `.planning/MILESTONE-ARC.md` specifically to stop strategic duplication drift. [VERIFIED: .planning/MILESTONE-ARC.md, .planning/STATE.md] |

**Installation:** No new dependencies are required for this phase; use the existing project toolchain and aliases. [VERIFIED: mix.exs, test/threadline/*doc_contract*_test.exs]

```bash
mix deps.get
```

## Architecture Patterns

### System Architecture Diagram

```text
Shipped API truth
  (`incident_bundle/2`, paging helpers, auth boundary tests)
        |
        v
Public docs choose one canonical story
  README -> domain reference -> quickstart/playbook -> example README
        |
        v
Focused contract tests lock literals and copied snippets
  readme_doc_contract
  exploration_routing_doc_contract
  getting_started_saas_doc_contract
  incident_playbook_doc_contract
  example_phoenix_readme_contract
        |
        v
Named verification entrypoints
  mix verify.test / mix ci.all

Strategic source of truth
  .planning/MILESTONE-ARC.md
        |
        v
Pointer summaries only
  ROADMAP / PROJECT / STATE
```

### Recommended Project Structure

```text
README.md                              # concise public API entrypoint and routing map
guides/
├── domain-reference.md                # canonical "which API first?" table
├── getting-started-saas.md            # first-hour adopter walkthrough
├── incident-playbook.md               # operator incident scenarios
└── production-checklist.md            # downstream links into routing docs
examples/threadline_phoenix/README.md  # runnable Phoenix proof surface
test/threadline/                       # doc-contract and shipped-API truth tests
.planning/                             # milestone arc plus pointer summaries
```

### Pattern 1: One Canonical Routing Hierarchy
**What:** Teach the exploration surface in a fixed escalation order: eager timeline for small slices, paged timeline for large windows, higher-level helper APIs for common support questions, and `incident_bundle/2` as the default transaction incident story. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, README.md, guides/domain-reference.md]
**When to use:** Everywhere a new adopter asks "which API should I call first?" [VERIFIED: guides/domain-reference.md, .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: README.md + current shipped investigation surface
Threadline.timeline(filters)
Threadline.timeline_page(filters, page_size: 100)
Threadline.incident_bundle(audit_transaction_id, repo: MyApp.Repo)
```

### Pattern 2: Demote Raw Composition to Advanced Building Blocks
**What:** Keep `audit_changes_for_transaction/2`, `transaction_context/2`, and `change_diff/2` documented, but explain them as underlying primitives for custom composition rather than the first default path. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, test/threadline/investigation_test.exs]
**When to use:** Reference docs, advanced examples, and operator deep-dives. [VERIFIED: guides/domain-reference.md, guides/incident-playbook.md]
**Example:**
```elixir
# Source: test/threadline/investigation_test.exs
{:ok, bundle} = Threadline.incident_bundle(txn.id, repo: repo)
raw = Threadline.transaction_context(txn.id, repo: repo)
changes = Threadline.audit_changes_for_transaction(txn.id, repo: repo)
```

### Pattern 3: Anchored Snippet Extraction Over Copied Code
**What:** When a doc block mirrors source code, extract it from the source fixture instead of hand-copying it into tests. [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs, test/support/getting_started_fixtures.ex]
**When to use:** Router wiring and `Blog.create_post/2` snippets in the getting-started guide. [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs]
**Example:**
```elixir
# Source: test/threadline/getting_started_saas_doc_contract_test.exs
assert String.contains?(doc, router_block())
assert String.contains?(doc, blog_block())
```

### Anti-Patterns to Avoid
- **Dual-canonical transaction story:** Avoid teaching raw `audit_changes_for_transaction/2` + `change_diff/2` composition as a co-equal default after `incident_bundle/2` shipped. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, guides/domain-reference.md, guides/incident-playbook.md]
- **README as second domain guide:** Keep top-level docs compact; do not move SQL, auth caveats, or detailed semantics into `README.md`. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, README.md]
- **Planning-table duplication:** Do not restate the forward candidate milestone table in `PROJECT.md` or `STATE.md`; point to `.planning/MILESTONE-ARC.md` instead. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, .planning/PROJECT.md, .planning/STATE.md, .planning/MILESTONE-ARC.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-doc drift detection | A new snapshot test framework | Existing focused ExUnit doc-contract tests | The repo already has working targeted guards on every relevant surface. [VERIFIED: test/threadline/*doc_contract*_test.exs] |
| Snippet synchronization | Manual copy-paste assertions for router/blog blocks | Existing snippet extractors in `test/support/` | Extracted source blocks reduce drift without freezing unrelated prose. [VERIFIED: test/support/getting_started_fixtures.ex, test/threadline/getting_started_saas_doc_contract_test.exs] |
| New transaction incident API | Another wrapper around `incident_bundle/2` for docs | `Threadline.incident_bundle/2` itself | Phase 55 already established the canonical packaged drill-down contract. [VERIFIED: .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md, test/threadline/investigation_test.exs] |
| Strategic planning mirror | A second milestone ranking table in `PROJECT.md` or `STATE.md` | Pointer summaries to `.planning/MILESTONE-ARC.md` | The project explicitly created a single canonical strategic file to stop drift. [VERIFIED: .planning/MILESTONE-ARC.md, .planning/STATE.md] |

**Key insight:** The repo already contains the right primitives for this phase; the work is choosing one canonical story and tightening the existing guards, not inventing new infrastructure. [VERIFIED: .planning/milestones/v1.15-phases/52-docs-and-contract-alignment/52-CONTEXT.md, test/threadline/*doc_contract*_test.exs, test/threadline/investigation_test.exs]

## Common Pitfalls

### Pitfall 1: Leaving `incident_bundle/2` canonical only in the example README
**What goes wrong:** The example app teaches the packaged incident bundle while the root docs still route transaction drill-down through raw composition, so adopters see two "blessed" answers. [VERIFIED: examples/threadline_phoenix/README.md, guides/domain-reference.md, guides/getting-started-saas.md, guides/incident-playbook.md]
**Why it happens:** Phase 55 updated the example proof surface, but Phase 56 is the first explicit cross-doc convergence pass. [VERIFIED: .planning/ROADMAP.md, .planning/STATE.md]
**How to avoid:** Make `incident_bundle/2` the default transaction row in every routing table and incident walkthrough, then mention raw helpers only as advanced composition tools. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md]
**Warning signs:** `audit_changes_for_transaction/2` appears in a "which API first?" table without `incident_bundle/2` beside it, or the README never mentions `incident_bundle/2` at all. [VERIFIED: README.md, guides/domain-reference.md]

### Pitfall 2: Tightening tests before narrative literals are settled
**What goes wrong:** Contract tests fail repeatedly during wording churn because they lock pre-decision phrasing. [VERIFIED: test/threadline/readme_doc_contract_test.exs, test/threadline/getting_started_saas_doc_contract_test.exs]
**Why it happens:** The suite uses exact section markers, literal strings, and extracted snippets by design. [VERIFIED: test/threadline/exploration_routing_doc_contract_test.exs, test/threadline/getting_started_saas_doc_contract_test.exs]
**How to avoid:** Keep `56-01` docs-first and `56-02` locks-second. [VERIFIED: .planning/ROADMAP.md]
**Warning signs:** A plan edits doc tests and public docs in the same early commit before the canonical routing wording is chosen. [VERIFIED: .planning/ROADMAP.md, .planning/milestones/v1.15-phases/52-docs-and-contract-alignment/52-CONTEXT.md]

### Pitfall 3: Letting planning docs re-import the full strategic table
**What goes wrong:** `PROJECT.md` and `STATE.md` start echoing the milestone candidate order, and the next milestone opening has to reconcile duplicated strategy prose again. [VERIFIED: .planning/MILESTONE-ARC.md, .planning/PROJECT.md, .planning/STATE.md]
**Why it happens:** Those files still mention future candidates in narrative form even after the dedicated arc file exists. [VERIFIED: .planning/PROJECT.md, .planning/STATE.md]
**How to avoid:** Keep only local consequences in `PROJECT.md` / `STATE.md`, such as "see `.planning/MILESTONE-ARC.md` for the standing order after v1.16". [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md]
**Warning signs:** Any touched planning doc adds or preserves a ranked candidate milestone list outside `.planning/MILESTONE-ARC.md`. [VERIFIED: .planning/MILESTONE-ARC.md]

## Suggested Doc-Contract Literals / Invariants

1. README should mention the investigation hierarchy explicitly: `Threadline.timeline/2`, `Threadline.timeline_page/2`, higher-level investigation helpers, and `Threadline.incident_bundle/2`. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, README.md]
2. Domain reference routing table should make `incident_bundle/2` the primary answer for "Everything in one DB transaction" and describe `audit_changes_for_transaction/2` / `transaction_context/2` / `change_diff/2` as lower-level composition tools. [VERIFIED: guides/domain-reference.md, .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md]
3. Getting-started guide should show transaction drill-down through `incident_bundle/2`, while still teaching `timeline/2`, `timeline_page/2`, and `as_of/4` for the first-hour operator loop. [VERIFIED: guides/getting-started-saas.md, .planning/REQUIREMENTS.md]
4. Incident playbook should preserve the host-owned auth honesty line and switch the single-transaction drill-down scenario to the bundled contract, not per-change ad-hoc mapping. [VERIFIED: guides/incident-playbook.md, test/threadline/incident_playbook_doc_contract_test.exs]
5. Example README should keep the authenticated-actor baseline plus tenancy/policy disclaimer unchanged while remaining the strongest proof that `incident_bundle/2` is the packaged host path. [VERIFIED: examples/threadline_phoenix/README.md, test/threadline/example_phoenix_readme_contract_test.exs]
6. Planning docs should preserve the literal pointer to `.planning/MILESTONE-ARC.md` and avoid reproducing its candidate order table. [VERIFIED: .planning/ROADMAP.md, .planning/PROJECT.md, .planning/STATE.md, .planning/MILESTONE-ARC.md]

## Code Examples

Verified patterns from the current repo:

### Cross-doc routing contract
```elixir
# Source: test/threadline/exploration_routing_doc_contract_test.exs
assert String.contains?(doc, "## Exploration API routing (v1.10+)")
assert String.contains?(doc, "XPLO-03-API-ROUTING")
assert String.contains?(doc, "Threadline.timeline_page/2")
assert String.contains?(doc, "stable traversal")
```

### Snippet-backed guide contract
```elixir
# Source: test/threadline/getting_started_saas_doc_contract_test.exs
assert String.contains?(doc, router_block())
assert String.contains?(doc, blog_block())
assert String.contains?(doc, "`actor_fn` remains the only actor-authority path")
```

### Shipped incident-bundle truth
```elixir
# Source: test/threadline/investigation_test.exs
assert {:ok, %IncidentBundle{} = result} = Threadline.incident_bundle(txn.id, repo: @repo)
assert result.changes != []
assert result.changes |> hd() |> Map.fetch!(:change_diff)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Transaction drill-down via `audit_changes_for_transaction/2` plus manual `change_diff/2` mapping in docs/example narrative [VERIFIED: guides/domain-reference.md, guides/incident-playbook.md] | Packaged transaction drill-down via `Threadline.incident_bundle/2` [VERIFIED: test/threadline/investigation_test.exs, examples/threadline_phoenix/README.md] | 2026-05-05 in Phase 55 [VERIFIED: .planning/STATE.md, .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md] | Phase 56 should now make that packaged path the default doc story everywhere. [VERIFIED: .planning/ROADMAP.md] |
| Eager-only timeline guidance for investigation windows [VERIFIED: older routing rows preserved in docs] | Explicit eager-vs-paged hierarchy with `timeline_page/2` for stable large windows [VERIFIED: README.md, guides/domain-reference.md, guides/getting-started-saas.md] | 2026-05-05 in Phase 53 [VERIFIED: .planning/STATE.md, .planning/milestones/v1.16-phases/53-timeline-paging-contract/53-CONTEXT.md] | README and routing docs should keep the same hierarchy and avoid offset-paging drift. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md] |
| Strategic ordering held in milestone-opening memory or repeated prose [VERIFIED: .planning/STATE.md] | Dedicated `.planning/MILESTONE-ARC.md` as canonical ranked arc [VERIFIED: .planning/MILESTONE-ARC.md] | 2026-05-05 when v1.16 opened [VERIFIED: .planning/STATE.md] | `PROJECT.md` and `STATE.md` should summarize consequences, not re-import the full ranking logic. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md] |

**Deprecated/outdated:**
- Treating raw transaction composition as the headline public story is now outdated for new adopters because Phase 55 shipped a first-class bundle surface. [VERIFIED: test/threadline/investigation_test.exs, .planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md]
- Repeating milestone candidate ordering outside `.planning/MILESTONE-ARC.md` is now outdated because the repo explicitly created that file to own the recommendation order. [VERIFIED: .planning/MILESTONE-ARC.md, .planning/STATE.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ExUnit is bundled with the installed Elixir toolchain. [ASSUMED] | Standard Stack | Low; verification commands still run through `mix test`, but the planner should not add any dependency-install step based on this claim alone. |

## Open Questions (RESOLVED)

1. **Should planning-doc drift be guarded by one new ExUnit test or by manual verification only?**
   - Resolution: Keep the planning-doc pointer check manual for Phase 56 and enforce it through the plan's explicit `rg` verification step plus the phase-level `mix ci.all` gate. Do not add a new ExUnit invariant unless Phase 56 execution exposes repeated drift that manual verification fails to catch. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, .planning/MILESTONE-ARC.md]
   - Reason: Public-doc drift already has focused ExUnit protection, while the planning-doc requirement is intentionally narrow and internal. A grep-based pointer check preserves the low-noise posture from D-07 through D-13 without adding a new CI surface prematurely. [VERIFIED: test/threadline/*doc_contract*_test.exs, .planning/PROJECT.md, .planning/STATE.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `mix test`, `mix ci.all`, fixture compilation | ✓ | 1.19.5 | — [VERIFIED: `elixir --version`] |
| Mix | All verification aliases | ✓ | 1.19.5 | — [VERIFIED: `mix --version`, mix.exs] |
| PostgreSQL server on localhost:5432 | DataCase-backed doc tests and investigation tests | ✓ | reachable; server accepting connections | For narrative-only checks, run the async no-DB doc tests first; full phase gate still expects Postgres. [VERIFIED: `pg_isready -h localhost -p 5432`] |
| `createdb` CLI | Example/test DB bootstrap when needed | ✓ | PostgreSQL 14.17 | Manual DB creation via equivalent SQL if needed. [VERIFIED: `createdb --version`] |

**Missing dependencies with no fallback:**
- None identified in the current workspace. [VERIFIED: environment probe]

**Missing dependencies with fallback:**
- None identified in the current workspace. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit under Elixir/Mix toolchain. [VERIFIED: test/threadline/*doc_contract*_test.exs, `mix --version`] |
| Config file | none; project uses `mix.exs` aliases and `test/support/` helpers. [VERIFIED: mix.exs, test/support/] |
| Quick run command | `mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` [VERIFIED: test/threadline/*doc_contract*_test.exs] |
| Full suite command | `mix ci.all` [VERIFIED: mix.exs, CLAUDE.md] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOPT-04 | Root README exposes the intended investigation hierarchy, including `incident_bundle/2` and the eager-vs-paged rule. [VERIFIED: .planning/REQUIREMENTS.md, .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md] | doc contract | `mix test test/threadline/readme_doc_contract_test.exs` | ✅ [VERIFIED: test/threadline/readme_doc_contract_test.exs] |
| ADOPT-04 | Domain reference teaches one canonical "which API first?" routing story and keeps the example incident JSON/auth boundary aligned. [VERIFIED: .planning/REQUIREMENTS.md, guides/domain-reference.md] | doc contract | `mix test test/threadline/exploration_routing_doc_contract_test.exs` | ✅ [VERIFIED: test/threadline/exploration_routing_doc_contract_test.exs] |
| ADOPT-04 | Quickstart and incident playbook teach the same host boundary and transaction drill-down story. [VERIFIED: guides/getting-started-saas.md, guides/incident-playbook.md] | doc contract | `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs` | ✅ [VERIFIED: test/threadline/getting_started_saas_doc_contract_test.exs, test/threadline/incident_playbook_doc_contract_test.exs] |
| ADOPT-04 | Example README stays aligned with the direct Sigra path and the bundled incident story. [VERIFIED: examples/threadline_phoenix/README.md] | doc contract | `mix test test/threadline/example_phoenix_readme_contract_test.exs` | ✅ [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs] |
| ADOPT-04 | Documentation only promotes behavior already shipped by `incident_bundle/2`. [VERIFIED: .planning/REQUIREMENTS.md, test/threadline/investigation_test.exs] | behavior regression | `mix test test/threadline/investigation_test.exs` | ✅ [VERIFIED: test/threadline/investigation_test.exs] |
| ADOPT-04 | Planning docs point to `.planning/MILESTONE-ARC.md` without duplicating the candidate order table. [VERIFIED: .planning/REQUIREMENTS.md, .planning/MILESTONE-ARC.md] | manual or new narrow doc contract | `rg -n "MILESTONE-ARC|candidate|v1.17|v1.18|v1.19|v1.20" .planning/PROJECT.md .planning/STATE.md .planning/ROADMAP.md .planning/MILESTONE-ARC.md` | ❌ automated contract file absent [VERIFIED: codebase audit] |

### Sampling Rate
- **Per task commit:** Run the targeted doc suite plus `mix test test/threadline/investigation_test.exs`. [VERIFIED: test/threadline/*doc_contract*_test.exs, test/threadline/investigation_test.exs]
- **Per wave merge:** Run `mix verify.test` if the phase is split across multiple commits or authors. [VERIFIED: mix.exs, CLAUDE.md]
- **Phase gate:** Run `mix ci.all` and a manual planning-doc grep check unless a new planning invariant test is added. [VERIFIED: mix.exs, .planning/MILESTONE-ARC.md]

### Wave 0 Gaps
- [ ] No automated planning-doc invariant currently exists for the `.planning/MILESTONE-ARC.md` pointer discipline. [VERIFIED: codebase audit]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Preserve the existing "authenticated actor required in the example; richer auth remains host-owned" wording consistently across docs. [VERIFIED: guides/getting-started-saas.md, guides/incident-playbook.md, examples/threadline_phoenix/README.md] |
| V3 Session Management | no | This phase does not introduce session behavior. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md] |
| V4 Access Control | yes | Keep tenancy and policy ownership explicitly with the host app; do not imply Threadline provides policy enforcement. [VERIFIED: .planning/milestones/v1.15-phases/52-docs-and-contract-alignment/52-CONTEXT.md, guides/incident-playbook.md] |
| V5 Input Validation | yes | Reuse existing doc statements that invalid override shapes raise `ArgumentError` and avoid docs that suggest permissive coercion. [VERIFIED: guides/getting-started-saas.md] |
| V6 Cryptography | no | No cryptographic surface is changed in this phase. [VERIFIED: .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs imply Threadline owns authorization policy | Elevation of privilege | Repeat the host-owned tenancy/policy disclaimer in every incident-facing surface. [VERIFIED: guides/getting-started-saas.md, guides/incident-playbook.md, examples/threadline_phoenix/README.md] |
| Docs teach a stale raw-composition endpoint shape after the packaged bundle shipped | Tampering | Tie docs back to `test/threadline/investigation_test.exs` and the example README contract so narrative drift fails verification early. [VERIFIED: test/threadline/investigation_test.exs, test/threadline/example_phoenix_readme_contract_test.exs] |
| Planning docs duplicate strategic truth and drift over time | Repudiation | Keep `.planning/MILESTONE-ARC.md` canonical and verify pointer-only summaries in dependent planning docs. [VERIFIED: .planning/MILESTONE-ARC.md, .planning/PROJECT.md, .planning/STATE.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md` - locked decisions, discretion, phase boundary. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - `ADOPT-04` text. [VERIFIED: file read]
- `.planning/ROADMAP.md` - Phase 56 two-plan split. [VERIFIED: file read]
- `.planning/STATE.md` - v1.16 status and phase sequencing. [VERIFIED: file read]
- `.planning/MILESTONE-ARC.md` - canonical strategic arc. [VERIFIED: file read]
- `README.md`, `guides/domain-reference.md`, `guides/getting-started-saas.md`, `guides/incident-playbook.md`, `guides/production-checklist.md`, `examples/threadline_phoenix/README.md` - current doc surfaces and drift points. [VERIFIED: file read]
- `test/threadline/readme_doc_contract_test.exs`, `test/threadline/exploration_routing_doc_contract_test.exs`, `test/threadline/getting_started_saas_doc_contract_test.exs`, `test/threadline/incident_playbook_doc_contract_test.exs`, `test/threadline/example_phoenix_readme_contract_test.exs`, `test/threadline/investigation_test.exs` - existing drift guards and shipped API truth. [VERIFIED: file read]
- `CLAUDE.md` and `mix.exs` - project constraints, aliases, and verification entrypoints. [VERIFIED: file read]
- Local environment probes: `elixir --version`, `mix --version`, `pg_isready -h localhost -p 5432`, `createdb --version`. [VERIFIED: command output]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: research scope stayed inside repo-local primary sources]

### Tertiary (LOW confidence)
- None besides the single ExUnit bundling assumption recorded below. [VERIFIED: assumptions log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The phase uses already-installed repo tooling and existing ExUnit contract infrastructure; both were inspected directly. [VERIFIED: mix.exs, test/threadline/*doc_contract*_test.exs, environment probe]
- Architecture: HIGH - The required split, file clusters, and drift boundaries are explicit in roadmap/context docs and visible in current files. [VERIFIED: .planning/ROADMAP.md, .planning/milestones/v1.16-phases/56-docs-contracts-and-arc-alignment/56-CONTEXT.md, docs audit]
- Pitfalls: HIGH - Each pitfall is grounded in currently divergent doc surfaces or already-established testing patterns. [VERIFIED: README.md, guides/*.md, test/threadline/*doc_contract*_test.exs]

**Research date:** 2026-05-05 [VERIFIED: environment context]
**Valid until:** 2026-06-04 for repo-local planning guidance unless adjacent docs/tests change materially before planning begins. [ASSUMED]
