# Phase 47: saas-adopter-onramp - Research

**Researched:** 2026-05-05 [VERIFIED: codebase grep]  
**Domain:** Elixir doc-contract testing, ExDoc guide surfacing, and Phoenix example-backed onboarding docs [VERIFIED: codebase grep]  
**Confidence:** HIGH [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from `.planning/phases/47-saas-adopter-onramp/47-CONTEXT.md`. [VERIFIED: codebase grep]

### Locked Decisions

### Doc-Contract Extraction Strategy
- **D-01:** Marker-based extraction. Use language-agnostic line-comment markers `# doc: start: <anchor>` and `# doc: end: <anchor>` in `examples/threadline_phoenix/` Elixir source files. The fixture reads the file, slices by anchor pair, and the doc-contract test asserts `String.contains?(guide_md, extracted_block)` per anchor. Confirmed in pre-discussion `DISCUSSION.md`; no AST parsing, no regex extraction.
- **D-02:** **Marker scope is Elixir source only.** Extracted blocks come from `.ex` / `.exs` files in `examples/threadline_phoenix/` (notably `lib/threadline_phoenix_web/router.ex` for the `:api` pipeline + actor_fn wireup, and `lib/threadline_phoenix/blog.ex` if a transaction snippet is shown). No HEEX, no JSON. The example app is API-only (no `--no-html` already), so this is sufficient for ADOPT-01.

### Anchor Naming & Convention
- **D-03:** **Anchor format = kebab-case-descriptive** (e.g. `# doc: start: router-pipeline-actor-fn`, `# doc: start: blog-create-post-transaction`). Reads naturally inline, easy to grep, no coupling to step numbers — guide reorganization doesn't force source-file edits.
- **D-04:** **Two assertion styles coexist intentionally.** Marker-extracted blocks for Elixir wiring (router pipeline, transaction snippet); `String.contains?` literal asserts for bash commands (`mix threadline.install`, `mix threadline.gen.triggers --tables posts`), the dep line (`{:threadline, "~> 0.3"}`), and curl shapes. Mirrors the existing `readme_doc_contract_test.exs` pattern for non-extracted literals — no need to overgeneralize.
- **D-05:** **`{:covered, _}` health-check literal stays asserted independently** (per ADOPT-01 wording) — not extracted from source, because it's a pattern-match shape the adopter copies verbatim, not a literal block in the example app.

### Fixture Module Contract
- **D-06:** Fixture module path: **`test/support/getting_started_fixtures.ex`**. Loaded via existing `elixirc_paths(:test)` mechanism in `mix.exs` (same as `data_case.ex`, `repo.ex`, `readme_quickstart_fixtures.ex`). Sibling, not subdirectory.
- **D-07:** Fixture exposes a generic `extract!(file, anchor)` function (or `extract/2` returning `{:ok, block} | {:error, reason}`). **Hard-fails on missing or unbalanced anchor pairs** — raises with a descriptive error message naming the file and anchor. Matches DISCUSSION.md's stated intent: any unmirrored mutation in the example app instantly fails CI.
- **D-08:** Fixture is `use ExUnit.Case, async: true` style (no DB) — pure file read. Matches the codebase pattern from `stg_doc_contract_test.exs`, `audit_indexing_doc_contract_test.exs`, `incident_playbook_doc_contract_test.exs`. NOT `Threadline.DataCase` (only `readme_doc_contract_test.exs` uses that, and only because it calls live DB fixtures).
- **D-09:** No explicit anchor manifest — fixture's `extract!/2` is called per-anchor from the doc-contract test's individual assertions. If the test references `extract!(file, "foo")` and `foo` is missing, the assertion fails loud. Manifest layer would be cosmetic.

### Step 6 ("First Audited Write") Demo Shape
- **D-10:** **Curl against running `phx.server`** is the primary demo path. Adopter runs `mix phx.server` (one paragraph in the guide), then a curl shape against `POST /api/posts` (the route the example app already ships and tests in `posts_audit_path_test.exs`, `posts_correlation_path_test.exs`). Returns 201 with `audit_transaction_id`. Operator-style demonstration; matches what the example proves end-to-end.
- **D-11:** **`Threadline.Health.trigger_coverage/1` runs in IEx after the curl** — separate `iex -S mix` session (or stays in a pre-started `iex -S mix phx.server`). Adopter evaluates `Threadline.Health.trigger_coverage(repo: ThreadlinePhoenix.Repo)` and sees `{:covered, _}`. The `{:covered, _}` shape literal is the locked doc-contract assertion per ADOPT-01.
- **D-12:** **Steps 7–8 stay in the same IEx session as step 6's coverage check, threading the bound values** (`audit_transaction_id`, `post_id`). `Threadline.timeline/2` (step 7), then `Threadline.change_diff/2` and `Threadline.as_of/4` (step 8) reuse the bindings — demonstrates correlation flowing across reads end-to-end. Doc-contract still asserts each call literal independently; the guide reads as one continuous session.
- **D-13:** **Correlation id literal: `demo-corr`**. Reuse the value already in `examples/threadline_phoenix/README.md` and `posts_correlation_path_test.exs`. One vocabulary across guide, example, and tests — no new literal to maintain.

### STG-02 Walked Example Structure (ADOPT-02)
- **D-14:** **New appended sub-section under `## STG audited write paths (STG-02)`**. Heading: `### Example: ExampleCloud walkthrough (maintainer-walked)`. The existing placeholder matrix stays as-is (integrator template); the walked example sits beside it with its own filled-in matrix. Clear separation between template and example, easy to lock with doc-contract assertions.
- **D-15:** **`<!-- ADOPT-EXAMPLE-DISCLAIMER -->` HTML comment banner** sits above the new sub-section's matrix, with a short paragraph clarifying that the column is maintainer-walked CI evidence and not third-party endorsement. Comment-style banner (HTML comment) is invisible in rendered Markdown but greppable in source.
- **D-16:** **Realistic mix of statuses** — 3–4 rows showing OK, Issue, and N/A statuses (e.g., `POST /api/posts` OK, an example Oban job OK, an `Issue`-flagged path with a tracked gap, and one `N/A` with an objective justification). Matches the guide's stated tone ("honest labels, not a scorecard"). Plain uniform-OK rows would contradict the guide's existing philosophy.
- **D-17:** **Evidence pointers are mixed CI job names + test paths.** OK rows cite either: (a) a real CI job name (e.g., `verify-pgbouncer-topology`, `verify-test`), (b) a real in-repo test path (e.g., `test/threadline_phoenix_web/posts_audit_path_test.exs`), or (c) a real `mix` command (e.g., `mix verify.threadline`). Rule from the guide's existing prose: in-repo CI artifacts only, never third-party staging URLs.
- **D-18:** **No real third-party product names appear in the walked example.** Use only fictional placeholders (`ExampleCloud`, `GenericPooler`). The existing guide's vocabulary already has the placeholder convention.

### Doc-Contract Assertions (Both Artifacts)

**For `test/threadline/getting_started_saas_doc_contract_test.exs` (new):**
- **D-19:** Assertions per ADOPT-01:
  - The eight section headings appear verbatim (one assertion per heading).
  - The literal `mix threadline.gen.triggers --tables posts` appears (the most-skipped step is locked).
  - The `{:covered, _}` health-check assertion shape appears.
  - The dep line `{:threadline, "~> 0.3"}` appears.
  - For each Elixir block extracted via marker: `String.contains?(guide_md, getting_started_fixtures.extract!("...", "anchor"))`.
  - Each of the six closing-pointer-block links appears as a literal AND `File.exists?` per target file path is true (six pairs, six files: `production-checklist.md`, `incident-playbook.md`, `performance.md`, `integrations/sigra.md`, `brownfield-continuity.md`, `adoption-pilot-backlog.md`). Order is editorial — NOT locked.
  - Closing block uses **adoption-likelihood ordering** (production-checklist → integrations/sigra → incident-playbook → performance → brownfield-continuity → adoption-pilot-backlog), with a one-line blurb per link. Order is not asserted, but is the editorial convention captured for the planner.

**For `test/threadline/stg_doc_contract_test.exs` (extended):**
- **D-20:** Four new assertions per ADOPT-02 Success Criterion 5:
  1. `<!-- ADOPT-EXAMPLE-DISCLAIMER -->` banner is present in `adoption-pilot-backlog.md`.
  2. The new walked-example sub-section contains at least one row with `OK` status.
  3. At least one walked-example row's evidence cell contains an in-repo pointer (matches `verify-pgbouncer-topology` OR `test/`).
  4. The walked-example sub-section does NOT contain a curated denylist of real third-party product names. Suggested denylist: `aws`, `gcp`, `azure`, `heroku`, `fly.io`, `supabase`, `rds`, `cloud sql`. Planner should refine the list during implementation.

### Closing Pointer Block (Step 8 / End of Guide)
- **D-21:** **Six links + short blurb each**, ordering by adoption likelihood (D-19 above). Literal and target-file existence asserted; order and blurb wording are editorial and not locked by the test.

### Claude's Discretion
- Exact wording of section headings, blurbs, and prose paragraphs (the contract locks specific literals — everything else is open).
- Exact path lists in the walked-example matrix beyond "at least one OK + at least one in-repo pointer + 3–4 rows total".
- The exact denylist of forbidden third-party product names in the ADOPT-02 assertion (planner can refine D-20.4).
- Whether `Blog.create_post/2` gets a marker pair (likely yes — the transaction body is a copy-pasteable pattern adopters need to see), versus only `router.ex`.
- ExDoc `extras:` ordering and group placement in `mix.exs` for the new guide (downstream of Phase 48's release packaging anyway).

### Deferred Ideas

- **`Threadline.Plug` `:context_overrides_fn` option** (carried from Phase 44 D-11) — would replace the two-plug pattern with native wiring. Still deferred. The new quickstart pre-empts adopter expectations by referencing `SigraContextPlug` per Phase 44 D-12.
- **Worked impersonation walkthrough** — deferred to v1.15 SIGRA-stretch (Phase 44 deferred ideas).
- **`mix threadline.gen.guide` mix task** — a future "scaffold a getting-started for X-stack" task could templatize the marker extraction pattern. Out of scope here; raise as a separate phase if `getting-started-saas` succeeds and other framework guides are wanted.
- **ExDoc group reorganization for the new guide** — the Phase 48 release scope owns ExDoc `extras:` reordering and any broader grouping cleanup. Phase 47 only needs the new guide present and buildable; it should not mix release-wide docs IA churn into the adopter quickstart work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-01 | `guides/getting-started-saas.md` ships as an ExDoc extra with eight locked steps, marker-extracted Elixir blocks, the trigger command literal, the `{:covered, _}` literal, and six closing links. [VERIFIED: codebase grep] | Example-app anchors, fixture contract, ExDoc update point, and validation map below define the implementation path. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| ADOPT-02 | `guides/adoption-pilot-backlog.md` gains one maintainer-walked STG example with fictional placeholders, a disclaimer marker, in-repo evidence pointers only, and contract assertions. [VERIFIED: codebase grep] | Existing STG matrix structure, CI evidence sources, and extension strategy for `stg_doc_contract_test.exs` below define the implementation path. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 47 should reuse the project’s existing guide-contract pattern instead of inventing a new docs system: plain markdown in `guides/`, pure `ExUnit.Case` tests that read files directly, and a small helper in `test/support/` when compile-checked or extracted examples are needed. The only genuinely new mechanism is marker extraction from Elixir source in `examples/threadline_phoenix/`, and the repo already has the right extension point for that because `test/support` is compiled in `:test` and `mix test` already acts as the enforcement path for every guide contract except the README-specific alias. [VERIFIED: codebase grep]

The quickstart should anchor itself on the existing Phoenix reference flow, not a hypothetical host app: `router.ex` already contains the Sigra pre-plug plus `Threadline.Plug` callback wiring, `Blog.create_post/2` already contains the single-transaction audited write path, and the example README plus request-path tests already prove the curl, correlation, timeline, and `as_of/4` story that ADOPT-01 wants to shorten into a 30-minute path. [VERIFIED: codebase grep]

ExDoc implications are small but real: Phase 47 must add `guides/getting-started-saas.md` to `mix.exs` `docs.extras`, and `mix docs` in CI will fail if the file is missing or malformed. ExDoc still treats extras as an explicit list and groups extras via `groups_for_extras`; since the current config already routes every `guides/` file into `Reference`, the phase can add the guide without restructuring groups. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

**Primary recommendation:** Implement Phase 47 as one new guide, one new pure-file fixture, one new async doc-contract test, one extension of `stg_doc_contract_test.exs`, and minimal marker additions in `router.ex` plus `blog.ex`; do not change CI topology or add AST/regex extraction. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Quickstart guide rendering in HexDocs | CDN / Static [ASSUMED] | Frontend Server (SSR) [ASSUMED] | The deliverable is a static markdown guide surfaced by ExDoc extras rather than a runtime endpoint. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Example audited write walkthrough (`POST /api/posts`) | API / Backend [VERIFIED: codebase grep] | Database / Storage [VERIFIED: codebase grep] | The behavior is implemented by Phoenix request handling plus `Repo.transaction/1`, trigger capture, and action linking. [VERIFIED: codebase grep] |
| Coverage check (`Threadline.Health.trigger_coverage/1`) | Database / Storage [VERIFIED: codebase grep] | API / Backend [VERIFIED: codebase grep] | The guide call is an Elixir API over catalog state and configured expected tables. [VERIFIED: codebase grep] |
| Doc-contract drift guard | API / Backend [ASSUMED] | CDN / Static [ASSUMED] | Enforcement lives in ExUnit test code reading source files and markdown before docs are published. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_unit/ExUnit.html] |
| STG matrix example evidence | CDN / Static [ASSUMED] | API / Backend [ASSUMED] | The artifact is documentation, but its proof points come from CI jobs and test paths in the repository. [VERIFIED: codebase grep] |

## Project Constraints (from CLAUDE.md)

- Use the Threadline three-layer language precisely: capture, semantics, and exploration/operations are separate responsibilities. [VERIFIED: codebase grep]
- Use project domain terms consistently: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation`. [VERIFIED: codebase grep]
- Prefer named verification entrypoints such as `mix verify.*` and `mix ci.all` in docs and CI references. [VERIFIED: codebase grep]
- Keep README, guides, and example app aligned with doc-contract assertions; docs drift is treated as a first-class failure mode. [VERIFIED: codebase grep]
- Do not assume a different capture mechanism for this phase; Phase 47 is documentation and contract work on top of the current example/reference flow. [VERIFIED: codebase grep]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / ExUnit | 1.19.5 local runtime [VERIFIED: codebase grep] | Test harness for guide contracts and fixtures. [VERIFIED: codebase grep] | The repo’s pure documentation tests use `use ExUnit.Case, async: true` and run under `mix test`. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_unit/ExUnit.html] |
| ExDoc | locked `0.40.1`, latest published 2026-01-31 [VERIFIED: hex package manager] | Publishes `guides/getting-started-saas.md` as a docs extra and validates doc build shape in CI. [VERIFIED: codebase grep] | The root project already uses `docs: docs()` with explicit `extras` and CI runs `mix docs`. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Phoenix example app | `phoenix ~> 1.8.5` in `examples/threadline_phoenix/mix.exs` [VERIFIED: codebase grep] | Supplies the authoritative router, transaction, and request flow snippets for the quickstart. [VERIFIED: codebase grep] | ADOPT-01 explicitly requires guide blocks to come from the shipped example app. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `test/support` compiled fixtures | project-local `elixirc_paths(:test)` [VERIFIED: codebase grep] | Hosts `getting_started_fixtures.ex` so extraction code is reusable across assertions. [VERIFIED: codebase grep] | Use for any doc contract that needs helper code but no DB setup. [VERIFIED: codebase grep] |
| `Threadline.ReadmeQuickstartFixtures` pattern | project-local [VERIFIED: codebase grep] | Existing precedent for fixture-backed docs validation. [VERIFIED: codebase grep] | Use as the shape reference for module placement and helper naming, but not for extraction strategy. [VERIFIED: codebase grep] |
| CI jobs `verify-test` and `verify-docs` | project-local [VERIFIED: codebase grep] | Enforce tests and doc builds in GitHub Actions. [VERIFIED: codebase grep] | Rely on `verify-test` for new guide contract coverage and `verify-docs` for ExDoc build correctness. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Marker extraction [VERIFIED: codebase grep] | AST extraction [VERIFIED: codebase grep] | Rejected by the phase context because the guide needs partial pipeline blocks and mixed doc shapes, not only full Elixir AST nodes. [VERIFIED: codebase grep] |
| Marker extraction [VERIFIED: codebase grep] | Regex-only extraction [VERIFIED: codebase grep] | Rejected by the phase context because it is brittle against formatting and local code motion. [VERIFIED: codebase grep] |
| Pure `ExUnit.Case` file-read test [VERIFIED: codebase grep] | `Threadline.DataCase` [VERIFIED: codebase grep] | `DataCase` is unnecessary here because the new guide contract does not need DB fixtures; the repo only uses `DataCase` for README fixture checks that execute live code paths. [VERIFIED: codebase grep] |

**Installation:** [VERIFIED: codebase grep]
```bash
mix deps.get
```

**Version verification:** [VERIFIED: codebase grep]
```bash
mix hex.info ex_doc
```

- `ex_doc` is locked at `0.40.1` in `mix.lock` and `mix hex.info ex_doc` reports `0.40.1` as the locked version with release date `2026-01-31`. [VERIFIED: codebase grep]
- The `mix.exs` dependency constraint remains `{:ex_doc, "~> 0.34", only: :dev, runtime: false}`, so Phase 47 should not change the dependency line unless release work explicitly pulls that into scope. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
examples/threadline_phoenix source
  | 
  |-- router.ex (:api pipeline, SigraContextPlug, Threadline.Plug)
  |-- blog.ex (Repo.transaction, record_action, audit_transaction_id)
  v
test/support/getting_started_fixtures.ex
  |
  |-- extract!(file, anchor)
  |     |- find start marker
  |     |- find end marker
  |     |- return exact inner block
  v
test/threadline/getting_started_saas_doc_contract_test.exs
  |
  |-- read guide markdown
  |-- assert headings + literals
  |-- assert extracted blocks are present verbatim
  |-- assert closing links exist on disk
  v
CI `mix verify.test`
  |
  |-- fails on docs/source drift
  v
`guides/getting-started-saas.md` + `mix docs`
  |
  |-- ExDoc extras list
  v
Published static docs
```

### Recommended Project Structure

```text
guides/
├── getting-started-saas.md          # New adopter quickstart guide
└── adoption-pilot-backlog.md        # Existing STG matrix, extended with walked example

test/
├── support/
│   └── getting_started_fixtures.ex  # Marker extractor
└── threadline/
    ├── getting_started_saas_doc_contract_test.exs
    └── stg_doc_contract_test.exs

examples/threadline_phoenix/
└── lib/
    ├── threadline_phoenix_web/router.ex
    └── threadline_phoenix/blog.ex
```

### Pattern 1: Pure File-Read Guide Contract
**What:** Use `ExUnit.Case`, read markdown from disk, and assert required literals or structural markers with `String.contains?/2`. [VERIFIED: codebase grep]  
**When to use:** For guide contracts that do not require a database or executing application code. [VERIFIED: codebase grep]  
**Example:**
```elixir
defmodule Threadline.StgDocContractTest do
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "adoption pilot backlog retains STG template and rubric markers" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  end
end
```
Source: [test/threadline/stg_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/stg_doc_contract_test.exs:1) [VERIFIED: codebase grep]

### Pattern 2: Fixture-Backed Docs Validation
**What:** Put helper code in `test/support`, let `elixirc_paths(:test)` compile it, and call the helper from a doc-contract test. [VERIFIED: codebase grep]  
**When to use:** When literals alone are not enough and the contract needs extracted or compile-checked snippets. [VERIFIED: codebase grep]  
**Example:**
```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]

defmodule Threadline.ReadmeQuickstartFixtures do
  def trigger_coverage_call do
    Threadline.Health.trigger_coverage(repo: Threadline.Test.Repo)
  end
end
```
Source: [mix.exs](/Users/jon/projects/threadline/mix.exs:44) and [test/support/readme_quickstart_fixtures.ex](/Users/jon/projects/threadline/test/support/readme_quickstart_fixtures.ex:23) [VERIFIED: codebase grep]

### Pattern 3: Quickstart Anchored to Example Request Path
**What:** Reuse the existing example app’s request path, correlation path, and README vocabulary to keep the new guide consistent with already-tested flows. [VERIFIED: codebase grep]  
**When to use:** For steps 5 through 8 of the quickstart. [VERIFIED: codebase grep]  
**Example:**
```elixir
pipeline :api do
  plug(:accepts, ["json"])
  plug(ThreadlinePhoenixWeb.SigraContextPlug)
  plug(Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1)
end
```
Source: [examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:4) [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **AST extraction for snippets:** The phase has already rejected this and the current anchor targets are partial code regions rather than whole compile units. [VERIFIED: codebase grep]
- **Regex-only snippet mining:** It is harder to make failures legible and easier to break with formatting or harmless code movement. [VERIFIED: codebase grep][ASSUMED]
- **DB-backed guide tests for ADOPT-01:** The guide contract only needs file reads and extracted source blocks; adding DB setup would slow CI and violate the repo’s existing pure-guide pattern. [VERIFIED: codebase grep]
- **New example literals that diverge from the example README/tests:** The repo already standardizes on `demo-corr`, `POST /api/posts`, and the current Sigra-based `actor_fn` callback. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Snippet synchronization | A custom parser or AST walker [VERIFIED: codebase grep] | A tiny marker extractor in `test/support/getting_started_fixtures.ex` [VERIFIED: codebase grep] | The phase has already locked markers, and the scope only needs exact line slices from Elixir files. [VERIFIED: codebase grep] |
| Doc publication | A custom markdown indexer [ASSUMED] | Existing ExDoc `extras` support [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | ExDoc already publishes markdown guides and the repo already uses it in CI. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| STG evidence validation | A bespoke table parser [ASSUMED] | Simple `String.contains?/2` plus a narrow regex for denylist/evidence checks [VERIFIED: codebase grep] | Existing guide tests in this repo all validate structure with direct string assertions and light regex. [VERIFIED: codebase grep] |

**Key insight:** The repo’s docs quality bar comes from small, explicit contracts close to the files they protect, not from generalized documentation infrastructure. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Markers That Drift or Collide
**What goes wrong:** The extractor returns the wrong block or crashes unclearly because an anchor name is duplicated, missing, or only one boundary is present. [ASSUMED]  
**Why it happens:** Marker extraction is string-slice based, so uniqueness and balanced boundaries are the integrity mechanism. [VERIFIED: codebase grep][ASSUMED]  
**How to avoid:** Enforce descriptive kebab-case anchor names, one start/end pair per anchor, and raise with file + anchor in `extract!/2`. [VERIFIED: codebase grep]  
**Warning signs:** A code move in `router.ex` or `blog.ex` suddenly fails the guide test while the guide text itself is unchanged. [ASSUMED]

### Pitfall 2: Editing the Wrong Source of Truth
**What goes wrong:** A maintainer updates the guide prose or code block manually instead of updating `examples/threadline_phoenix/` first. [ASSUMED]  
**Why it happens:** The repo has both a library README contract and an example app README, so there are multiple doc surfaces with overlapping concepts. [VERIFIED: codebase grep]  
**How to avoid:** Treat `examples/threadline_phoenix/` as the source of truth for extracted Elixir blocks and only lock non-source literals directly in the guide test. [VERIFIED: codebase grep]  
**Warning signs:** The guide block differs from `router.ex` or `Blog.create_post/2` but the example tests still pass. [ASSUMED]

### Pitfall 3: Assuming `verify.doc_contract` Covers All Guide Contracts
**What goes wrong:** A planner assumes the new guide contract must be added to the `verify.doc_contract` alias to run in CI. [VERIFIED: codebase grep]  
**Why it happens:** The alias name suggests global guide coverage, but it currently runs only `test/threadline/readme_doc_contract_test.exs`. [VERIFIED: codebase grep]  
**How to avoid:** Plan validation around `mix verify.test` for the new doc-contract test, and treat alias expansion as optional cleanup unless the team wants a broader doc-only entrypoint. [VERIFIED: codebase grep]  
**Warning signs:** The new test passes under `mix test` but is omitted from a maintainer’s doc-only local command. [ASSUMED]

### Pitfall 4: Over-rotating ExDoc Grouping in the Same Phase
**What goes wrong:** The phase turns into a release-information-architecture cleanup instead of shipping the adopter quickstart. [VERIFIED: codebase grep]  
**Why it happens:** `mix.exs` currently has one broad `Reference` group for guides, and Phase 48 already owns broader ExDoc reorganization. [VERIFIED: codebase grep]  
**How to avoid:** Add the guide to `extras` now and leave group reordering beyond “buildable and visible” to Phase 48 unless implementation proves a blocker. [VERIFIED: codebase grep]  
**Warning signs:** The plan includes unrelated changes to module grouping or release-shape tests. [ASSUMED]

## Code Examples

Verified patterns from official and in-repo sources:

### Marker Extraction Contract Shape
```elixir
guide = File.read!("guides/getting-started-saas.md")
router_block = Threadline.GettingStartedFixtures.extract!(
  "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
  "router-pipeline-actor-fn"
)

assert String.contains?(guide, router_block)
```
Source: phase decision pattern plus repo-wide `String.contains?` guide tests. [VERIFIED: codebase grep]

### Example Audited Write Anchor Candidate
```elixir
Repo.transaction(fn ->
  Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])

  case Repo.insert(Post.changeset(%Post{}, attrs)) do
    {:ok, post} ->
      opts = [
        repo: Repo,
        actor: actor_ref,
        correlation_id: audit_context.correlation_id,
        request_id: audit_context.request_id
      ]

      case Threadline.record_action(:post_created_via_api, opts) do
```
Source: [examples/threadline_phoenix/lib/threadline_phoenix/blog.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix/blog.ex:32) [VERIFIED: codebase grep]

### ExDoc Extra Registration Pattern
```elixir
docs: [
  extras: [
    "README.md",
    "guides/performance.md",
    "guides/getting-started-saas.md"
  ],
  groups_for_extras: [
    Overview: ~r/README/,
    Reference: ~r{^guides/}
  ]
]
```
Source: root docs config pattern plus ExDoc extras/groups docs. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| README-only contract alias as the named doc entrypoint [VERIFIED: codebase grep] | Multiple guide-specific contract tests under `test/threadline/` enforced by `mix test`, with README still singled out by `verify.doc_contract`. [VERIFIED: codebase grep] | Already true in the current repo state as of 2026-05-05. [VERIFIED: codebase grep] | Phase 47 can follow the newer per-guide test convention without needing CI topology changes. [VERIFIED: codebase grep] |
| Manually maintained example snippets in docs [ASSUMED] | Source-backed snippets via fixture extraction, locked by CI. [VERIFIED: codebase grep] | This phase introduces it for the SaaS quickstart. [VERIFIED: codebase grep] | The guide becomes harder to let drift silently, at the cost of maintaining markers in source. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Regex or AST extraction for this phase’s quickstart blocks is outdated for the locked scope because the phase has explicitly standardized on marker extraction. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Documentation delivery maps cleanly to the `CDN / Static` tier in the responsibility table. | Architectural Responsibility Map | Low; only affects planning language, not implementation. |
| A2 | Marker extraction will likely fail most often from duplicate/unbalanced anchors rather than line-ending issues or encoding issues. | Common Pitfalls | Low; extractor error messages still need to be robust either way. |
| A3 | The STG example can be validated sufficiently with string assertions plus a small denylist regex, without needing markdown table parsing. | Don't Hand-Roll / Common Pitfalls | Medium; if implementation gets more structural than expected, tests may need a slightly stronger parser. |

## Open Questions

Resolved during planning:

1. **`mix verify.doc_contract` scope**
   - Resolution: Leave coverage under `mix verify.test` for Phase 47. Do not widen `mix verify.doc_contract` in this phase because guide-contract alias cleanup is outside the shallow Phase 47 scope. [VERIFIED: codebase grep]

2. **`Blog.create_post/2` marker size**
   - Resolution: Anchor the smallest contiguous block that still explains “same transaction + action link + returned audit transaction id.” This minimizes future marker churn while preserving the copy-pasteable audited-write pattern required by ADOPT-01. [VERIFIED: codebase grep][ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | test/doc build validation | ✓ [VERIFIED: codebase grep] | 1.19.5 [VERIFIED: codebase grep] | — |
| `elixir` | ExUnit and `mix docs` | ✓ [VERIFIED: codebase grep] | 1.19.5 [VERIFIED: codebase grep] | — |
| PostgreSQL client tools (`pg_isready`, `createdb`, `psql`) | example-app and full test validation | ✓ [VERIFIED: codebase grep] | `createdb`/`psql` 14.17 [VERIFIED: codebase grep] | For pure guide-contract iteration, run only file-read tests. [VERIFIED: codebase grep] |
| Local PostgreSQL server | full suite / example flows | ✓ [VERIFIED: codebase grep] | accepting on `:5432` [VERIFIED: codebase grep] | For pure doc-contract iteration, no DB is required. [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:**
- None found for planning or for pure guide-contract implementation. [VERIFIED: codebase grep]

**Missing dependencies with fallback:**
- None. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_unit/ExUnit.html] |
| Config file | `test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs` [ASSUMED] |
| Full suite command | `mix verify.test` and `mix docs` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOPT-01 | Eight-step quickstart guide stays aligned with example source, literals, and closing links. [VERIFIED: codebase grep] | unit / doc-contract [VERIFIED: codebase grep] | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` [ASSUMED] | ❌ Wave 0 [VERIFIED: codebase grep] |
| ADOPT-02 | STG walked example includes disclaimer, allowed placeholders, and in-repo evidence pointers only. [VERIFIED: codebase grep] | unit / doc-contract [VERIFIED: codebase grep] | `mix test test/threadline/stg_doc_contract_test.exs` [VERIFIED: codebase grep] | ✅ [VERIFIED: codebase grep] |
| ADOPT-01 | New guide builds under ExDoc once added to `extras`. [VERIFIED: codebase grep] | smoke [ASSUMED] | `mix docs` [VERIFIED: codebase grep] | ✅ existing docs job [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/stg_doc_contract_test.exs` [ASSUMED]
- **Per wave merge:** `mix verify.test` [VERIFIED: codebase grep]
- **Phase gate:** `mix verify.test` plus `mix docs` before `/gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `test/threadline/getting_started_saas_doc_contract_test.exs` — covers ADOPT-01. [VERIFIED: codebase grep]
- [ ] `test/support/getting_started_fixtures.ex` — marker extractor shared fixture. [VERIFIED: codebase grep]
- [ ] Optional alias decision: decide whether `mix verify.doc_contract` should remain README-only or include the new guide contract indirectly via additional explicit test files. [VERIFIED: codebase grep][ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: codebase grep] | This phase documents existing actor wiring but does not introduce new auth code. [VERIFIED: codebase grep] |
| V3 Session Management | no [VERIFIED: codebase grep] | Session behavior remains in the example app and prior Sigra work. [VERIFIED: codebase grep] |
| V4 Access Control | no [VERIFIED: codebase grep] | The phase adds docs/tests only; no new protected endpoints are introduced. [VERIFIED: codebase grep] |
| V5 Input Validation | yes [ASSUMED] | Validate marker names, file paths, and denylist checks inside the fixture/tests; fail loud on malformed markers. [VERIFIED: codebase grep][ASSUMED] |
| V6 Cryptography | no [VERIFIED: codebase grep] | No cryptographic changes are in scope. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs overstating host evidence as maintainer proof | Spoofing [ASSUMED] | Keep the `<!-- ADOPT-EXAMPLE-DISCLAIMER -->` banner and only use fictional vendor names with in-repo evidence pointers. [VERIFIED: codebase grep] |
| Silent docs drift from example app | Tampering [ASSUMED] | Marker extraction plus CI doc-contract tests on every code change. [VERIFIED: codebase grep] |
| Future file/path drift breaking docs publication | Denial of service [ASSUMED] | Keep the guide in `guides/`, register it in ExDoc `extras`, and rely on `mix docs` CI. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |

## Sources

### Primary (HIGH confidence)

- Codebase inspection in `/Users/jon/projects/threadline` — `mix.exs`, `mix.lock`, `test/test_helper.exs`, `config/test.exs`, `test/threadline/*doc_contract*`, `test/support/readme_quickstart_fixtures.ex`, `examples/threadline_phoenix/*`, `guides/adoption-pilot-backlog.md`, `.planning/phases/47-saas-adopter-onramp/*`. [VERIFIED: codebase grep]
- ExDoc official docs: https://hexdocs.pm/ex_doc/ExDoc.html — extras, grouping, and docs generation behavior. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- ExUnit official docs: https://hexdocs.pm/ex_unit/ExUnit.html — `ExUnit.Case`, async usage, and `mix test` integration. [CITED: https://hexdocs.pm/ex_unit/ExUnit.html]
- Hex package versions for ExDoc: https://hex.pm/packages/ex_doc/versions and local `mix hex.info ex_doc`. [CITED: https://hex.pm/packages/ex_doc/versions][VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- ExDoc task docs snapshot: https://hexdocs.pm/ex_doc/0.39.3/Mix.Tasks.Docs.html — confirms extras/group ordering details consistent with current ExDoc docs. [CITED: https://hexdocs.pm/ex_doc/0.39.3/Mix.Tasks.Docs.html]

### Tertiary (LOW confidence)

- None. All phase-shaping claims above were either verified in the repo or cited from official docs. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - local dependency pins, CI config, and official ExDoc/ExUnit docs all align. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- Architecture: HIGH - the relevant files and flows already exist in the example app and existing guide tests. [VERIFIED: codebase grep]
- Pitfalls: MEDIUM - the major risks are clear from the chosen marker strategy, but exact failure modes inside the new extractor still depend on implementation details. [VERIFIED: codebase grep][ASSUMED]

**Research date:** 2026-05-05 [VERIFIED: codebase grep]  
**Valid until:** 2026-06-04 for repo-local structure; re-check ExDoc/Hex package currency after 30 days. [CITED: https://hex.pm/packages/ex_doc/versions][ASSUMED]
