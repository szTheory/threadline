# Phase 47: saas-adopter-onramp - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-03
**Phase:** 47-saas-adopter-onramp
**Areas discussed:** Anchor convention, Step 6 demo shape, STG column character, Pointer-block enforcement

---

## Anchor convention

### Q1: Non-extractable literal handling

| Option | Description | Selected |
|--------|-------------|----------|
| Literal-asserted only | `String.contains?` on bash/literal directly; marker-extraction reserved for Elixir source. Two patterns coexist intentionally. | ✓ |
| Route everything through fixtures | Even bash literals flow through `install_command/0`-style helpers — uniform but more boilerplate. | |
| You decide | — | |

**User's choice:** Literal-asserted only (Recommended)
**Notes:** Aligns with `readme_doc_contract_test.exs` precedent.

### Q2: Anchor naming format

| Option | Description | Selected |
|--------|-------------|----------|
| kebab-case-descriptive | e.g. `router-pipeline-actor-fn` — natural, no step coupling. | ✓ |
| step-numbered (`gs05`, `gs07`) | Anchors carry guide step numbers — traceable, brittle to reorganization. | |
| snake_case_function-style | Matches Elixir identifier convention. | |

**User's choice:** kebab-case-descriptive (Recommended)

### Q3: Extractor strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Hard-fail at test load | `extract!/2` raises on missing/unbalanced anchor pairs; instant CI failure. | ✓ |
| Soft-fail with descriptive error | Return `{:error, reason}`; tests assert success and surface a friendly diff. | |
| Anchor-list manifest at top of fixture | Module attribute + setup test asserts existence; explicit anchor surface. | |

**User's choice:** Hard-fail at test load (Recommended)

### Q4: Fixture module location

| Option | Description | Selected |
|--------|-------------|----------|
| `test/support/getting_started_fixtures.ex` | Sibling to `readme_quickstart_fixtures.ex`, `data_case.ex`. | ✓ |
| `test/support/doc_contract/getting_started_fixtures.ex` | New subdirectory groups doc-contract fixtures. | |
| `test/threadline/getting_started_saas_fixtures.exs` | Co-located with test — breaks `test/support/` convention. | |

**User's choice:** `test/support/getting_started_fixtures.ex` (Recommended)

---

## Step 6 demo shape

### Q1: Audited write demonstration

| Option | Description | Selected |
|--------|-------------|----------|
| Curl against running phx.server | Mirrors what example app already proves end-to-end (router + plug + Blog.create_post). | ✓ |
| IEx Repo.transaction walkthrough | No phx.server; tighter loop but inverts abstraction order. | |
| Both — IEx primary, curl callout | Two surfaces to keep aligned with doc-contract test. | |

**User's choice:** Curl against running phx.server (Recommended)

### Q2: Trigger coverage check location

| Option | Description | Selected |
|--------|-------------|----------|
| IEx after the curl | `iex -S mix` and run `Threadline.Health.trigger_coverage(repo: ...)` returning `{:covered, _}`. | ✓ |
| Embedded in controller response | Curl response carries coverage shape; couples step to controller change. | |
| Post-curl SQL probe | `select count(*) from audit_changes` — doesn't exercise the named API. | |

**User's choice:** IEx after the curl (Recommended)

### Q3: Steps 7–8 session continuity

| Option | Description | Selected |
|--------|-------------|----------|
| Same IEx session, threaded values | Bound `audit_transaction_id`/`post_id` flow across reads — demonstrates correlation. | ✓ |
| Fresh self-contained blocks per step | Easier to skip around; values never visibly flow together. | |
| IEx for 7, link out for 8 | Defers `as_of` to incident-playbook — but the goal explicitly names "first as_of". | |

**User's choice:** Same IEx session, threaded values (Recommended)

### Q4: Correlation id literal

| Option | Description | Selected |
|--------|-------------|----------|
| `demo-corr` | Reuse value from existing example README + `posts_correlation_path_test.exs`. | ✓ |
| `first-audited-write` (semantic) | More descriptive; introduces a new literal. | |
| `$(uuidgen)` placeholder | Realistic but not pinnable as a literal. | |

**User's choice:** `demo-corr` (Recommended)

---

## STG column character

### Q1: Walked example layout

| Option | Description | Selected |
|--------|-------------|----------|
| New appended sub-section under STG-02 | Existing matrix as integrator template; walked example sits beside it. | ✓ |
| Replace placeholder row in-place | Tighter visually; mixes template + example in same table. | |
| Side-by-side: blank template + walked example | Two adjacent matrices; maximum clarity, more vertical real estate. | |

**User's choice:** New appended sub-section under STG-02 (Recommended)

### Q2: Row-mix character

| Option | Description | Selected |
|--------|-------------|----------|
| Realistic mix — OK + Issue + N/A | 3–4 rows, varied statuses; matches guide's "honest labels" tone. | ✓ |
| Uniform OK rows | Cleaner template; contradicts guide's stated philosophy. | |
| Single representative OK row | Tightly scoped; probably too thin for "fully-walked". | |

**User's choice:** Realistic mix — OK + Issue + N/A (Recommended)

### Q3: Evidence pointer flavor

| Option | Description | Selected |
|--------|-------------|----------|
| Mix of CI job names + test paths | Cites `verify-pgbouncer-topology`, test file paths, and `mix verify.threadline`. | ✓ |
| Test paths only | Uniform shape; loses the `verify-pgbouncer-topology` precedent. | |
| CI job names only | Consistent with job-id convention but opaque to host engineers. | |

**User's choice:** Mix of CI job names + test paths (Recommended)

### Q4: stg_doc_contract_test extension assertions

| Option | Description | Selected |
|--------|-------------|----------|
| Disclaimer + 1 OK + in-repo pointer + no real product names | Four assertions matching ADOPT-02 verbatim. | ✓ |
| Above + assert `ExampleCloud` and `GenericPooler` | Stronger placeholder-vocabulary lock. | |
| Banner + denylist only | Lighter; doesn't enforce the "fully-walked" intent. | |

**User's choice:** Disclaimer + 1 OK + in-repo pointer + no real product names (Recommended)

---

## Pointer-block enforcement

### Q1: Enforcement strength

| Option | Description | Selected |
|--------|-------------|----------|
| Literal + `File.exists?` per link | `String.contains?` on each link literal AND assert file existence per target. | ✓ |
| Literal-only | `String.contains?` per link only — won't catch target-file rename. | |
| Literal + `File.exists?` + non-empty content | Above plus `byte_size > 0` per target — over-engineering. | |

**User's choice:** Literal + `File.exists?` per link (Recommended)

### Q2: Pointer block format

| Option | Description | Selected |
|--------|-------------|----------|
| Short blurb per link | `- [Production checklist](production-checklist.md) — operator checks before...`. | ✓ |
| Bare links list | No blurb — tighter; less hand-holding post-30-min onramp. | |
| Grouped by audience (operator vs developer) | Two sub-headings; introduces grouping vocabulary the test would have to lock. | |

**User's choice:** Short blurb per link (Recommended)

### Q3: Closing-block ordering

| Option | Description | Selected |
|--------|-------------|----------|
| Adoption likelihood | production-checklist → integrations/sigra → incident-playbook → performance → brownfield-continuity → adoption-pilot-backlog. | ✓ |
| Alphabetical | Trivially reproducible; loses curatorial signal. | |
| REQUIREMENTS.md order | Matches ADOPT-01 listing; mechanical, drift-free. | |

**User's choice:** Adoption likelihood (Recommended)

### Q4: Order-locking in test

| Option | Description | Selected |
|--------|-------------|----------|
| Presence only | Each link present + each target file exists — order is editorial. | ✓ |
| Order-locked via single substring | One verbatim block assertion — brittle to wording edits. | |
| Order-locked via index comparison | `String.split` indices; more test code, rarely worth it. | |

**User's choice:** Presence only (Recommended)

---

## Claude's Discretion

- Exact wording of the eight section headings (only specific literals are locked).
- Exact wording of pointer-block blurbs.
- Exact path list in the walked example matrix beyond the 3–4 row + 1 OK + 1 in-repo pointer floor.
- The exact denylist of forbidden third-party product names in the ADOPT-02 assertion (planner can refine during implementation).
- Whether `Blog.create_post/2` gets a marker pair in addition to `router.ex`.
- ExDoc `extras:` ordering and group placement (downstream of Phase 48).

---

## Deferred Ideas

- `Threadline.Plug` `:context_overrides_fn` option — carried from Phase 44 D-11.
- Worked impersonation walkthrough — v1.15 SIGRA-stretch.
- `mix threadline.gen.guide` mix task — speculative scaffolding utility.
- ExDoc group reorganization — Phase 48 scope.
- Anchor-list manifest in the fixture — only if anchor count grows past ~5.
- IEx/curl mix variation for step 6 — re-open only if 30-min budget feels strained.
