# Phase 47: saas-adopter-onramp - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship two adopter-facing artifacts plus their drift guards:

1. **`guides/getting-started-saas.md`** — eight-step SaaS quickstart whose code blocks for the Phoenix wiring are extracted via marker anchors from `examples/threadline_phoenix/` source. Goal: a SaaS team going from `mix.exs` install to first `as_of` in under thirty minutes against the shipped reference app (ADOPT-01).

2. **`guides/adoption-pilot-backlog.md`** — extended with one fully-walked maintainer example sub-section under `## STG audited write paths (STG-02)`, using fictional placeholders (`ExampleCloud`, `GenericPooler`), an explicit `<!-- ADOPT-EXAMPLE-DISCLAIMER -->` banner, and evidence pointers limited to in-repo CI artifacts (ADOPT-02).

Both artifacts get paired doc-contract tests:
- New `test/threadline/getting_started_saas_doc_contract_test.exs` (async ExUnit.Case) backed by `test/support/getting_started_fixtures.ex` (a marker-based file extractor).
- Extended `test/threadline/stg_doc_contract_test.exs` with four new assertions covering the walked example.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/REQUIREMENTS.md` — ADOPT-01 (lines 35) and ADOPT-02 (line 36); locks the eight steps, the `mix threadline.gen.triggers <table>` literal, the `{:covered, _}` health-check shape, the closing pointer block target list, and the four ADOPT-02 contract assertions.
- `.planning/ROADMAP.md` — Phase 47 success criteria (1–5); criterion 3 mandates target-file existence for the closing block; criterion 4 mandates the marker-extraction pattern.
- `.planning/phases/47-saas-adopter-onramp/DISCUSSION.md` — pre-discuss design note locking marker-based extraction with `# doc: start: <anchor>` over AST parsing or regex.

### Guide Targets (existing on disk; closing-pointer-block targets)
- `guides/production-checklist.md` — operator readiness checklist; closing-block target.
- `guides/incident-playbook.md` — five canonical incident scenarios; closing-block target (Phase 46 output).
- `guides/performance.md` — published baseline numbers; closing-block target (Phase 45 output).
- `guides/integrations/sigra.md` — Sigra integration adapter guide; closing-block target (Phase 44 output).
- `guides/brownfield-continuity.md` — historical capture for established Postgres deployments; closing-block target.
- `guides/adoption-pilot-backlog.md` — STG matrix host (this phase modifies it); closing-block target AND ADOPT-02 surface.

### Example App (extraction source)
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — `:api` pipeline with `Threadline.Plug` + `actor_fn` wireup. Anchor candidate: `router-pipeline-actor-fn`.
- `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` — `create_post/2` `Repo.transaction` body (GUC + insert + `record_action`). Anchor candidate: `blog-create-post-transaction`.
- `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` — Sigra-delegating `actor_fn` callback.
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` — proves `POST /api/posts` capture path; reusable as evidence-pointer in the ADOPT-02 walked example.
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs` — pins `demo-corr` correlation literal (D-13).
- `examples/threadline_phoenix/README.md` — current `as_of` walkthrough and curl shape (lines 99–172); style precedent for the new guide's IEx blocks and curl invocation.
- `examples/threadline_phoenix/mix.exs` — the example app's deps (note: example uses `{:threadline, path: "../.."}`, NOT `{:threadline, "~> 0.3"}` — the version-pinned literal in the guide is asserted independently, not extracted from the example).

### Existing Doc-Contract Test Patterns
- `test/threadline/incident_playbook_doc_contract_test.exs` — closest pattern: `use ExUnit.Case, async: true`, `File.read!`, `String.contains?`, plus regex/structural assertions per scenario. Phase 46 sibling.
- `test/threadline/stg_doc_contract_test.exs` — pattern for the doc this phase extends; `read_rel!/1` helper convention.
- `test/threadline/audit_indexing_doc_contract_test.exs`, `test/threadline/exploration_routing_doc_contract_test.exs`, `test/threadline/performance_doc_contract_test.exs`, `test/threadline/support_playbook_doc_contract_test.exs` — same pattern; consistent codebase idiom.
- `test/threadline/readme_doc_contract_test.exs` — counter-example: uses `Threadline.DataCase` because it calls DB fixtures. ADOPT-01 test should NOT follow this case — pure file-read.
- `test/support/readme_quickstart_fixtures.ex` — different pattern (compile-checked function mirrors), NOT a marker extractor. New `getting_started_fixtures.ex` introduces a new fixture style.

### Phase 44 Decisions That Apply Here
- `.planning/phases/44-sigra-integration-adapter/44-CONTEXT.md` — D-12 commits the example app's `:api` pipeline to the two-plug pattern (`SigraContextPlug` + `Threadline.Plug, actor_fn: ...`). The router pipeline block extracted in Phase 47 reflects that wiring.
- `.planning/phases/44-sigra-integration-adapter/44-SPEC.md` — locked semantics for actor_fn behavior; the quickstart's actor_fn line `&Threadline.Integrations.Sigra.actor_ref_from_conn/1` is from this phase.

### Project Standards
- `CLAUDE.md` (project) — domain language, three-layer architecture, named verification entrypoints (`mix verify.*`, `mix ci.all`).
- `prompts/threadline-elixir-oss-dna.md` — doc-contract-test discipline: README/guides/example app stay aligned via test assertions; honest default tests; stable CI job IDs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`String.contains?(File.read!(path), literal)`** — universal codebase doc-contract idiom; reuse verbatim.
- **`@repo_root File.cwd!()` + `read_rel!/1` helper** in `stg_doc_contract_test.exs` — copy this helper convention into `getting_started_saas_doc_contract_test.exs` for path-relative reads.
- **`elixirc_paths(:test)` in root `mix.exs`** — already loads `test/support/*.ex`; new fixture module slots in with no `mix.exs` change.
- **`examples/threadline_phoenix/README.md`** existing curl block (lines 167–172) and as_of walkthrough (lines 99–127) — style template for the new guide's voice.

### Established Patterns
- **Pure file-read fixture pattern** with `File.read!` + `String.contains?` — every Threadline doc-contract test follows this. Marker extraction is new but additive: `extract!(path, anchor) -> String.t()` plugs in cleanly because callers still pass the result to `String.contains?`.
- **`use ExUnit.Case, async: true`** for pure-file doc-contract tests — codebase consensus (5 of 6 existing doc-contract tests).
- **Doc-contract literal locking** — README, guides, and example app are kept aligned via test assertions on specific literals (not whole-file diffs). Aligns with `prompts/threadline-elixir-oss-dna.md`.
- **HTML-comment markers in markdown** (`<!-- LIVE-JOIN-WARNING -->`, `<!-- ADOPT-EXAMPLE-DISCLAIMER -->`) — invisible in rendered output, greppable in source. Established in `incident-playbook.md` and the existing rubric.

### Integration Points
- **New file:** `guides/getting-started-saas.md` — must be added to root `mix.exs` `extras:` block for ExDoc.
- **New file:** `test/threadline/getting_started_saas_doc_contract_test.exs` — async, no DB.
- **New file:** `test/support/getting_started_fixtures.ex` — `extract!/2` helper.
- **New markers in:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (and likely `blog.ex`) — adds `# doc: start:` / `# doc: end:` comment pairs around copy-pasteable blocks.
- **Modified:** `guides/adoption-pilot-backlog.md` — append new `### Example: ExampleCloud walkthrough` sub-section + banner.
- **Modified:** `test/threadline/stg_doc_contract_test.exs` — add four assertions for ADOPT-02.
- **Possibly modified:** `examples/threadline_phoenix/README.md` — only if the new guide reuses fragments verbatim and the existing example README diverges. Not required by the contract.

</code_context>

<specifics>
## Specific Ideas

- The fixture's `extract!/2` is the smallest viable contract. Suggested signature: `extract!(relative_path :: String.t(), anchor :: String.t()) :: String.t()`. Implementation: read the file, split on `# doc: start: <anchor>` and `# doc: end: <anchor>`, return the inner body trimmed of leading/trailing newlines. Raise with a descriptive error if either marker is missing or the body is empty.
- **Anchor candidates** for the planner to lock: `router-pipeline-actor-fn` (the `pipeline :api` block in router.ex), `blog-create-post-transaction` (the Repo.transaction body), and possibly `audit-actor-callback` (the actor_fn delegating to `Threadline.Integrations.Sigra`). Two to three anchors total.
- The walked example matrix should include at least one row pointing at `verify-pgbouncer-topology` (already CI-asserted in `ci_topology_contract_test.exs`) so the in-repo pointer assertion has an obvious anchor.
- Closing-block adoption-likelihood ordering: `production-checklist` → `integrations/sigra` → `incident-playbook` → `performance` → `brownfield-continuity` → `adoption-pilot-backlog`. Sigra ranks high because step 5's actor_fn callback already references `Threadline.Integrations.Sigra.actor_ref_from_conn/1`.
- The `<!-- ADOPT-EXAMPLE-DISCLAIMER -->` banner paragraph should explicitly say the column is maintainer-walked CI evidence, NOT third-party endorsement, AND that hosts using ExampleCloud or any real cloud must produce their own STG-01 host-class evidence.

</specifics>

<deferred>
## Deferred Ideas

- **`Threadline.Plug` `:context_overrides_fn` option** (carried from Phase 44 D-11) — would replace the two-plug pattern with native wiring. Still deferred. The new quickstart pre-empts adopter expectations by referencing `SigraContextPlug` per Phase 44 D-12.
- **Worked impersonation walkthrough** — deferred to v1.15 SIGRA-stretch (Phase 44 deferred ideas).
- **`mix threadline.gen.guide` mix task** — a future "scaffold a getting-started for X-stack" task could templatize the marker extraction pattern. Out of scope here; raise as a separate phase if `getting-started-saas` succeeds and other framework guides are wanted.
- **ExDoc group reorganization for the new guide** — the Phase 48 release scope owns ExDoc `extras:` ordering and `groups_for_extras:` placement. Phase 47 just adds the file; Phase 48 surfaces it.
- **Anchor-list manifest in the fixture** — option C from the strictness question. Deferred unless the anchor count grows past ~5; current scope (2–3 anchors) doesn't justify the extra layer.
- **Per-step IEx vs curl mix variations** — option C from the step-6 question (lead-with-IEx + curl callout). Deferred: simpler to commit to one demo path. Re-open only if 30-min budget feels strained during writing.

</deferred>

---

*Phase: 47-saas-adopter-onramp*
*Context gathered: 2026-05-03*
