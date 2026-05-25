# Phase 92: Phase 87 Verification Backfill - Research

**Researched:** 2026-05-25  
**Domain:** Verification backfill for the canonical `/audit` mount recipe and example-app adopter proof on the current tree [VERIFIED: codebase grep, targeted test runs]  
**Confidence:** HIGH [VERIFIED: codebase grep, targeted test runs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Verification proof bar
- **D-01: Phase 92 should use a layered adopter-proof bar.** Do not close `ADOPT-01` and `ADOPT-02` with docs-only or test-only evidence.
- **D-02: Public contract proof is mandatory.** The canonical `/audit` recipe and example-host story must agree across `guides/getting-started-saas.md`, `examples/threadline_phoenix/README.md`, `guides/operator-surface.md`, and `guides/upgrade-path.md` where applicable.
- **D-03: Runnable example-host proof is mandatory.** Phase 92 must prove the shared `/audit` router recipe on the example Phoenix app, including the same-tree admin/support posture and admin-only export denial for support users.
- **D-04: Named rerun surfaces are part of the proof bar.** Verification should close through stable entrypoints already used by the repo such as `mix verify.doc_contract`, `mix verify.example`, and their CI jobs, not through one-off shell commands hidden only in the artifact.
- **D-05: Keep the proof bar adopter-facing.** Phase 92 is about proving the canonical recipe and example-host path; it should rely on upstream Phase 91 for row-history/as-of scope closure rather than re-expanding into deeper query proof unless the canonical recipe/example claim specifically depends on it.

### Truth-first drift handling
- **D-06: Use hybrid truth-first drift handling.** Repair inline when a mismatch is local, non-controversial, and fully provable on the current tree in the same pass.
- **D-07: Narrow the claim immediately when proof is weaker than intent.** If the current tree cannot honestly prove some part of the Phase 87 recipe/example story during this phase, mark that part narrower rather than preserving the older implementation aspiration.
- **D-08: Separate authority-surface reconciliation only when milestone truth changes.** If fixing or narrowing the claim requires updates to `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, or requirement status, treat that as explicit authority-surface work rather than burying it inside ordinary doc cleanup.
- **D-09: Respect Threadline’s claim taxonomy.** Anything not proven on the current tree should be treated as `unclaimed` or narrower, not implicitly supported because the architecture intends it.
- **D-10: Do not let Phase 92 absorb Phase 93 concerns.** Export fallback copy, unsupported-shell UX nuance, and broader denial ergonomics belong to the denial/fallback backfill unless they directly block truthful closure of the canonical recipe/example proof.

### Verification artifact shape
- **D-11: Use the existing split artifact pattern.** Phase 92 should produce `87-VERIFICATION.md` and `87-VALIDATION.md`, not a single omnibus verification document.
- **D-12: `87-VERIFICATION.md` owns the verdicts.** It should state phase goal, exact claim boundary, `ADOPT-01` / `ADOPT-02` closure status, canonical `/audit` recipe proof, example-host proof, caveats, and explicit “not closed here” boundaries.
- **D-13: `87-VALIDATION.md` owns the rerunnable evidence map.** It should capture requirement-to-command mapping, named verify aliases, CI discoverability, any Nyquist-style sampling notes, and final sign-off against the current tree.
- **D-14: Keep public docs/tests as product authority and `.planning/` as maintainer evidence.** The artifact records why the claim is true; it does not become the primary public contract adopters must read first.

### Locked upstream product posture
- **D-15: Keep one canonical `/audit` tree.** The original Phase 87 decision remains locked: admin and support personas share one host-owned route tree with narrower support capability on the same mount.
- **D-16: Keep auth, scope, and tenancy host-owned.** The canonical seams remain `authorize_fn`, `scope_query_fn`, and `export_authorize_fn`; no Threadline-owned policy DSL or support-role abstraction should be introduced.
- **D-17: Preserve least surprise for Phoenix adopters.** The recipe should continue to look like idiomatic Phoenix composition: host auth in front, mount macro inside one route scope, explicit server-authoritative export auth, and stable example proof.
- **D-18: Favor DX that is copy-pasteable and rerunnable.** The same files that teach the recipe should be the ones contract tests and example-host verification actually prove.

### Claude's Discretion
- Exact selection of command/test subsets, as long as the layered adopter-proof bar is satisfied.
- Exact wording for truth narrowing or inline repair, as long as the final claim matches the current tree.
- Exact section names inside `87-VERIFICATION.md` and `87-VALIDATION.md`, as long as verdicts and evidence remain clearly separated.

### Deferred Ideas (OUT OF SCOPE)
- A heavier machine-readable evidence bundle or automated verification manifest system
- Any new Threadline-owned auth/tenant/role DSL
- A second support-specific route tree or broader support product mode
- Broader denial/fallback UX refinement beyond what is necessary to keep Phase 92 truthful
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-01 | Threadline ships one canonical `/audit` mount recipe showing admin and support personas on the same host-owned route tree. | The current public contract already teaches one shared `/audit` tree in `guides/getting-started-saas.md`, `guides/operator-surface.md`, `guides/upgrade-path.md`, and the example README; Phase 92 needs to re-verify that these stay aligned and then artifact that proof explicitly in `87-VERIFICATION.md` and `87-VALIDATION.md`. [VERIFIED: codebase grep, targeted doc-contract test run] |
| ADOPT-02 | The example Phoenix app proves the canonical support lane with host-owned `scope_query_fn` narrowing and admin-only export posture. | The example router, README, and nested example tests already encode the required support-lane proof, and `mix verify.example` passed on the current tree; Phase 92 needs to cite that named proof path and close the missing artifact chain rather than inventing a new execution path. [VERIFIED: codebase grep, `mix verify.example`] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep Threadline’s three-layer architecture distinct; this phase verifies the exploration/operations adoption surface and should not drift into capture-layer redesign or semantics-layer expansion. [CITED: CLAUDE.md]
- Prefer named verification entrypoints over ad-hoc shell sequences in docs and maintainer artifacts. [CITED: CLAUDE.md]
- Use the repo’s canonical verification surfaces where they fit: `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. [CITED: CLAUDE.md]
- Keep domain language exact: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation` are distinct concepts. [CITED: CLAUDE.md]
- Keep auth, role meaning, and tenancy host-owned; this phase must reinforce `authorize_fn`, `scope_query_fn`, and `export_authorize_fn`, not introduce a Threadline-owned policy DSL. [CITED: CLAUDE.md]
- If execution later touches GSD phase-state helpers, use positional `gsd-sdk query state.begin-phase` arguments. [CITED: CLAUDE.md]

## Summary

Phase 92 is a verification-backfill phase with unusually little architecture risk and a very clear evidence gap. The current tree already contains the canonical shared `/audit` recipe, the example-host router proof, the example-host support/export tests, the public doc-contract assertions, and the named rerun surfaces `mix verify.doc_contract` and `mix verify.example`. I verified `mix verify.doc_contract` and `mix verify.example` both pass on the current tree. [VERIFIED: codebase grep, `mix verify.doc_contract`, `mix verify.example`]

The real planning work is to convert that existing proof into the explicit Phase 87 maintainer artifact chain that does not exist today. The Phase 87 directory has plans and summaries, but no `87-VERIFICATION.md` or `87-VALIDATION.md`. Later backfill phases already established the artifact split and the planner should copy that pattern rather than inventing a new one. [VERIFIED: directory listing, prior phase artifacts]

The one operational trap worth planning around is proof context. The example test file `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` does prove the right behavior, but it does not compile when run from the root app because `ThreadlinePhoenixWeb.ConnCase` only exists in the nested example project. The honest rerunnable proof is `mix verify.example`, which compiles and tests the example app in its own project context and passed in this session. [VERIFIED: root-run compile failure, `mix verify.example`]

**Primary recommendation:** Plan Phase 92 as two narrow steps: first re-verify the current-tree public contract plus named example proof through `mix verify.doc_contract` and `mix verify.example`; then write `87-VERIFICATION.md` and `87-VALIDATION.md` in the Phase 87 directory, updating requirement/roadmap/state authority surfaces only if the verified claim boundary changes. [VERIFIED: context + codebase grep + targeted test runs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Teach the canonical `/audit` mount recipe | Public docs | Example app | The first-hour recipe lives in `guides/getting-started-saas.md` and is backed by the example router snippet extracted into doc-contract tests. [VERIFIED: codebase grep] |
| Enforce one shared admin/support route tree | Frontend Server (Phoenix router / LiveView host) | API / Backend | The actual mount lives in `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` and passes host-owned auth/scope/export callbacks into the operator surface. [VERIFIED: codebase grep] |
| Prove support-scope narrowing and export denial on the example host | Example app test tier | Public docs | `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` exercises scoped transaction visibility and support export denial, while README/doc-contract tests describe the same lane. [VERIFIED: codebase grep] |
| Provide stable rerun surfaces for adopters and maintainers | Mix aliases / CI | Planning artifacts | `mix verify.doc_contract`, `mix verify.example`, and CI jobs under `.github/workflows/ci.yml` are the durable proof entrypoints; `87-VALIDATION.md` should point to them rather than replace them. [VERIFIED: mix.exs, ci.yml] |
| Record closure of `ADOPT-01` and `ADOPT-02` | Planning / Authority surfaces | — | Requirement state remains pending until Phase 92 writes the verification evidence and updates requirement bookkeeping honestly. [VERIFIED: REQUIREMENTS.md, ROADMAP.md, STATE.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | `1.19.5` locally; project requires `~> 1.15` [VERIFIED: `mix --version`, `mix.exs`] | Runs the verification aliases and ExUnit suites for this phase. [VERIFIED: mix.exs] | Phase 92 is entirely expressed through existing Mix aliases, test files, and Markdown artifacts; no alternate tooling is needed. [VERIFIED: codebase grep] |
| Phoenix | `1.8.7` on the root lane and `1.8.5` in the example app [VERIFIED: `mix.lock`, `examples/threadline_phoenix/mix.lock`] | Owns the router-level `/audit` mount and example-host proof context. [VERIFIED: codebase grep] | The canonical mount recipe and example proof are both Phoenix-hosted concerns. [VERIFIED: codebase grep] |
| Phoenix LiveView | `1.1.30` on the root lane and `1.1.28` in the example app [VERIFIED: `mix.lock`, `examples/threadline_phoenix/mix.lock`] | Provides the mounted operator surface the docs and example host are proving. [VERIFIED: codebase grep] | The public contract is specifically about the shipped LiveView-backed operator surface under `/audit`. [VERIFIED: guides + codebase grep] |
| ExUnit | bundled with Elixir `1.19.5` [VERIFIED: `mix --version`] | Enforces doc-contract and example-host proof. [VERIFIED: targeted test runs] | Every current proof surface for this phase is already encoded as ExUnit tests or Mix aliases that call ExUnit. [VERIFIED: mix.exs, test tree] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Ecto / Ecto SQL | `3.13.5` [VERIFIED: `mix.lock`, `examples/threadline_phoenix/mix.lock`] | Supports the example host’s scoped query proof and test fixtures. [VERIFIED: example test code] | Use indirectly through the existing example app; Phase 92 should not add new Ecto proof unless the canonical claim drifts. [VERIFIED: context + codebase grep] |
| Sigra | `0.2.5` in the example app [VERIFIED: `examples/threadline_phoenix/mix.lock`, README] | Defines the narrower `sigra-reference` host lane that `mix verify.example` proves. [VERIFIED: upgrade-path guide + example README] | Use only as the example-host proof context, not as the authority for the broader `phoenix-surface` lane. [VERIFIED: docs + context] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mix verify.example` | Run `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` from the root app | Reject this. The root app cannot compile the example `ConnCase`, so the proof is not rerunnable from that context. [VERIFIED: root-run compile failure] |
| Existing doc-contract suite plus example proof | One new bespoke verification script | Reject this. The repo already has named aliases and CI jobs, and Phase 92 is explicitly told to close through those stable surfaces. [VERIFIED: mix.exs, ci.yml, CONTEXT.md] |
| Split `87-VERIFICATION.md` + `87-VALIDATION.md` | One omnibus evidence file | Reject this. Phases 89 and 91 already established the split pattern, and Phase 92 locks it in D-11 to D-13. [VERIFIED: prior phase artifacts, CONTEXT.md] |

**Installation:** No new dependencies are recommended. Reuse the current repo stack and the existing example-app dependency tree. [VERIFIED: mix.exs, mix.lock, example lock]

**Version verification:** The recommended stack here is the repo-locked stack already in use. Root versions were verified from `mix.lock` and example-host versions from `examples/threadline_phoenix/mix.lock`; the current local runtime is Elixir/Mix `1.19.5`. [VERIFIED: `mix --version`, locks]

## Architecture Patterns

### System Architecture Diagram

```text
maintainer verification run
  -> mix verify.doc_contract
     -> guides/getting-started-saas.md
     -> guides/operator-surface.md
     -> guides/upgrade-path.md
     -> examples/threadline_phoenix/README.md
     -> root doc-contract tests
  -> mix verify.example
     -> examples/threadline_phoenix router + support-lane tests
     -> nested example Phoenix app context
  -> compare verdicts
     -> 87-VERIFICATION.md (claim boundary + requirement verdicts)
     -> 87-VALIDATION.md (commands actually used + Nyquist map)
  -> if truth changed
     -> REQUIREMENTS.md / ROADMAP.md / STATE.md updates
```

The planner should keep the proof chain layered in that order: public contract, runnable example-host proof, then artifact/bookkeeping closure. [VERIFIED: CONTEXT.md, codebase grep, targeted test runs]

### Recommended Project Structure

```text
.planning/phases/87-canonical-mount-recipe-and-example-app-proof/
├── 87-VERIFICATION.md   # new verdict artifact for ADOPT-01 / ADOPT-02
├── 87-VALIDATION.md     # new evidence map / commands-used artifact
├── 87-01-PLAN.md        # original implementation plan
├── 87-02-PLAN.md        # original implementation plan
└── 87-0*-SUMMARY.md     # original execution summaries
guides/
├── getting-started-saas.md
├── operator-surface.md
└── upgrade-path.md      # public authority surfaces
examples/threadline_phoenix/
├── README.md
├── lib/threadline_phoenix_web/router.ex
└── test/threadline_phoenix_web/operator_surface_test.exs
test/threadline/
├── getting_started_saas_doc_contract_test.exs
├── example_phoenix_readme_contract_test.exs
├── operator_surface_doc_contract_test.exs
└── upgrade_path_doc_contract_test.exs
```

### Pattern 1: Public recipe proof must use the existing doc-contract chain
**What:** The canonical `/audit` story is already locked through root doc-contract tests against the public guides and the example README. [VERIFIED: codebase grep, targeted doc-contract test run]  
**When to use:** Use this as the first proof band for `ADOPT-01`. [VERIFIED: CONTEXT.md]  
**Example:**
```elixir
assert String.contains?(doc, "support operators return an opaque host-owned scope")
assert String.contains?(doc, "export_authorize_fn")
assert String.contains?(doc, "`scope_query_fn` narrows timeline, actor, transaction,")
assert String.contains?(doc, "row-history, and as-of queries to that scope")
```
Source: `test/threadline/getting_started_saas_doc_contract_test.exs` [VERIFIED: codebase grep]

### Pattern 2: Example-host proof must run in the nested example project
**What:** The example host is proven by the root alias `mix verify.example`, which changes into `examples/threadline_phoenix`, gets deps, compiles, creates the example test DB, and runs that app’s tests. [VERIFIED: mix.exs, `mix verify.example`]  
**When to use:** Use this as the mandatory runnable proof band for `ADOPT-02`. [VERIFIED: CONTEXT.md]  
**Example:**
```elixir
defp verify_example(_args) do
  cmd =
    "bash -lc 'set -euo pipefail && cd examples/threadline_phoenix && printf \"n\\n\" | mix deps.get && mix compile --warnings-as-errors && mix ecto.create --quiet -r ThreadlinePhoenix.Repo && mix test'"

  case Mix.shell().cmd(cmd, env: [{"MIX_ENV", "test"}]) do
    0 -> :ok
    status -> Mix.raise("verify.example failed (#{status})")
  end
end
```
Source: `mix.exs` [VERIFIED: codebase grep]

### Pattern 3: The canonical mount remains one shared `/audit` scope
**What:** The example router already shows the exact one-tree composition Phase 92 needs to verify. [VERIFIED: codebase grep]  
**When to use:** Use this snippet as the artifact anchor for `87-VERIFICATION.md`. [VERIFIED: docs + router grep]  
**Example:**
```elixir
scope "/audit" do
  pipe_through([:browser, :operator_auth])

  threadline_operator_surface("/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
    repo: ThreadlinePhoenix.Repo
  )
end
```
Source: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` [VERIFIED: codebase grep]

### Pattern 4: Copy the modern split artifact format
**What:** Later verification-backfill phases already established how Threadline writes a verdict artifact and a separate validation artifact. [VERIFIED: prior phase artifacts]  
**When to use:** Use the Phase 89 and Phase 86 backfill files as the format analogs for the new Phase 87 artifacts. [VERIFIED: prior phase artifacts]  
**Example:** Frontmatter in `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md` and `.planning/phases/86-scoped-read-path-closure/86-VALIDATION.md`. [VERIFIED: prior phase artifacts]

### Anti-Patterns to Avoid
- **Docs-only closure:** Passing doc-contract tests without rerunning `mix verify.example` would violate the locked layered proof bar. [VERIFIED: CONTEXT.md]
- **Root-running example tests:** `MIX_ENV=test mix test examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` fails to compile because `ThreadlinePhoenixWeb.ConnCase` is not loaded in the root app. [VERIFIED: root-run compile failure]
- **Reopening Phase 91 scope proof:** Phase 92 should consume the already-closed row-history/as-of truth from Phase 91, not expand into fresh query-scoping work unless the canonical recipe claim itself becomes false. [VERIFIED: CONTEXT.md, Phase 91 artifacts]
- **Treating `.planning/` as adopter-facing authority:** The verification artifacts explain the proof; they do not replace the guides, router snippet, or example README as the public contract. [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Example-host rerun path | A new root-only wrapper or ad-hoc command list | `mix verify.example` | The alias already encodes the required nested project context and passed in this session. [VERIFIED: mix.exs, `mix verify.example`] |
| Public recipe verification | New prose-only checklist | Existing doc-contract tests plus `mix verify.doc_contract` | The repo already enforces these exact guide and README claims through tests. [VERIFIED: mix.exs, targeted doc-contract test run] |
| Artifact format | A new verification schema | The split pattern from Phases 89 and 91 | The planner can copy a known-good structure and keep evidence consistent across milestones. [VERIFIED: prior phase artifacts] |
| Support-lane auth modeling | A Threadline role/tenant abstraction | Host-owned `authorize_fn`, `scope_query_fn`, and `export_authorize_fn` | The project intentionally keeps role and tenancy meaning in the host app. [CITED: CLAUDE.md][VERIFIED: CONTEXT.md] |

**Key insight:** Phase 92 is mostly about proving and packaging an existing truth, not adding a new capability. The safest plan is to reuse the repo’s current public-test-example-artifact chain exactly as it already exists. [VERIFIED: codebase grep, targeted test runs]

## Common Pitfalls

### Pitfall 1: Using the wrong proof context for the example app
**What goes wrong:** A plan tries to run the example operator-surface test file directly from the root project. [VERIFIED: root-run compile failure]  
**Why it happens:** The file is visible from the root repo, but its `ConnCase` and app environment live only inside the nested example project. [VERIFIED: codebase grep, root-run compile failure]  
**How to avoid:** Treat `mix verify.example` as the only standard rerun surface for example-host proof. [VERIFIED: mix.exs, `mix verify.example`]  
**Warning signs:** Commands mention `mix test examples/threadline_phoenix/test/...` from the repo root. [VERIFIED: root-run compile failure]

### Pitfall 2: Closing `ADOPT-01` and `ADOPT-02` from docs alone
**What goes wrong:** The planner uses passing doc-contract tests as the whole evidence story. [VERIFIED: CONTEXT.md]  
**Why it happens:** The docs are already aligned today, so it is tempting to stop there. [VERIFIED: targeted doc-contract test run]  
**How to avoid:** Always pair public doc proof with runnable example-host proof and the named rerun surfaces. [VERIFIED: CONTEXT.md, `mix verify.example`]  
**Warning signs:** `87-VERIFICATION.md` lists guide files but not `mix verify.example`, example router proof, or example test behavior. [VERIFIED: context requirements]

### Pitfall 3: Accidentally absorbing Phase 93 denial/fallback work
**What goes wrong:** Export UX fallback, unsupported-state nuance, or broader denial ergonomics get pulled into this phase. [VERIFIED: CONTEXT.md]  
**Why it happens:** Support export denial is adjacent to the canonical route proof. [VERIFIED: CONTEXT.md, example test code]  
**How to avoid:** Keep Phase 92 limited to the truth already claimed: same-tree route shape, scope narrowing, and admin-only export posture; broader denial UX remains Phase 93. [VERIFIED: CONTEXT.md]  
**Warning signs:** Plans start editing unsupported-view copy or broader fallback docs outside the proof needed for `ADOPT-01` / `ADOPT-02`. [VERIFIED: CONTEXT.md]

## Code Examples

Verified patterns from the current tree:

### Named example-host proof entrypoint
```elixir
"verify.example": &verify_example/1,
```
Source: `mix.exs` [VERIFIED: codebase grep]

### Example-host support-lane proof cases
```elixir
test "support user only sees transactions scoped to their organization", %{conn: conn} do
  {:ok, visible_tx} = create_post_for_org("support-org-1", "support-visible")
  {:ok, hidden_tx} = create_post_for_org("support-org-2", "support-hidden")
  ...
end

test "support user cannot export from the shared operator surface", %{conn: conn} do
  ...
  export_conn =
    get(conn, "/audit/exports/changes.csv?from=2020-01-01T00:00&to=2099-01-01T00:00")

  assert response(export_conn, 403) == "forbidden"
end
```
Source: `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase implementation summaries without explicit backfilled verdict/evidence artifacts | Split `*-VERIFICATION.md` and `*-VALIDATION.md` artifacts for later-phase closure [VERIFIED: prior phase artifacts] | Established by the recent verification backfill phases on 2026-05-25 [VERIFIED: file timestamps / artifact presence] | Phase 92 should close Phase 87 through explicit verdict and validation artifacts, not only the original 87 summaries. [VERIFIED: directory listings, CONTEXT.md] |
| Narrowed support-lane row-history wording | Proven support-scoped row-history/as-of on the current tree [VERIFIED: Phase 86 artifacts, current docs/tests] | Phase 91 backfill on 2026-05-25 [VERIFIED: 86-VERIFICATION.md, 86-VALIDATION.md] | Phase 92 can rely on that upstream truth and does not need to re-litigate row-history proof unless the adopter recipe no longer matches it. [VERIFIED: CONTEXT.md, Phase 91/86 artifacts] |

**Deprecated/outdated:**
- Root-running the example test file as if it were a normal root ExUnit target: this is not a valid rerun surface for Phase 92 proof. [VERIFIED: root-run compile failure]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. All material claims in this research were verified in-session or cited from repo artifacts / official docs. | — | — |

## Open Questions (RESOLVED)

1. **Should Phase 92 update authority surfaces beyond `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`?**
   - What we know: The current public docs and example proof passed as-is, and requirement status is still pending. [VERIFIED: targeted test runs, REQUIREMENTS.md]
   - Resolution: Default to no broader authority edits. Execution should update `.planning/PROJECT.md` only if the current-tree re-verification uncovers a real contradiction between the verified claim boundary and the milestone thesis under D-08; otherwise the authority-surface follow-up is limited to Phase 87 artifacts plus any requirement/status bookkeeping that changes with the verdict. [VERIFIED: CONTEXT.md, current passing proof runs]
   - Status: RESOLVED.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | `mix verify.doc_contract`, `mix verify.example`, artifact planning commands | ✓ [VERIFIED: command probe] | `1.19.5` [VERIFIED: `mix --version`] | — |
| `elixir` | ExUnit / Mix runtime | ✓ [VERIFIED: command probe] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| PostgreSQL client/server | Example app DB creation and test execution | ✓ [VERIFIED: `psql --version`, `pg_isready`] | client `14.17`; local server accepting on `:5432` [VERIFIED: probes] | — |
| Node / npm | Not required for Phase 92 proof directly, but present in the repo environment | ✓ [VERIFIED: command probe] | Node `v22.14.0`, npm `11.1.0` [VERIFIED: probes] | Not needed |

**Missing dependencies with no fallback:**
- None for the current Phase 92 verification path. [VERIFIED: command probes, successful test runs]

**Missing dependencies with fallback:**
- None. [VERIFIED: command probes]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Mix alias verification + example-host nested app tests [VERIFIED: mix.exs, test tree] |
| Config file | `mix.exs`, `config/test.exs`, `.github/workflows/ci.yml` [VERIFIED: codebase grep] |
| Quick run command | `MIX_ENV=test mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs --max-failures 1` [VERIFIED: successful run] |
| Full suite command | `mix verify.example` and `mix verify.doc_contract` [VERIFIED: mix.exs; `mix verify.example` run; doc-contract subset run] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOPT-01 | Public docs teach one canonical shared `/audit` recipe with host-owned auth/scope/export seams. [VERIFIED: docs + doc-contract tests] | doc-contract | `mix verify.doc_contract` | ✅ [VERIFIED: files + successful run] |
| ADOPT-02 | The example Phoenix app proves scoped support visibility and admin-only export denial on the shared `/audit` tree. [VERIFIED: example router + example tests] | nested integration | `mix verify.example` | ✅ [VERIFIED: mix.exs, example tests, successful run] |

### Sampling Rate
- **Per task commit:** rerun the doc-contract subset after guide/README/router-proof edits. [VERIFIED: repo test layout]
- **Per wave merge:** rerun `mix verify.example` after any example-host or example README truth change. [VERIFIED: mix.exs, example proof layout]
- **Phase gate:** both the doc-contract subset and `mix verify.example` green before writing `87-VALIDATION.md` sign-off. [VERIFIED: CONTEXT.md]

### Wave 0 Gaps
- None in test infrastructure. Existing doc-contract and example-host proof coverage already covers the required public and runnable proof surfaces. [VERIFIED: codebase grep, targeted test runs]
- Missing maintainer artifacts are the actual gap: `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VERIFICATION.md` and `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VALIDATION.md` do not exist yet. [VERIFIED: directory listing]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: docs + example router/tests] | Host browser/auth pipeline in front of `/audit`, plus shared `authorize_fn` on the mounted surface. [VERIFIED: guides + router] |
| V3 Session Management | no [VERIFIED: phase scope] | Session mechanics are not the implementation focus of this verification-backfill phase. [VERIFIED: CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: requirements + example tests] | Host-owned `scope_query_fn` narrows support reads; `export_authorize_fn` keeps export admin-only. [VERIFIED: docs, router, example tests] |
| V5 Input Validation | yes [VERIFIED: router/docs/test surface] | Existing route and callback contracts are validated by doc-contract and example-host tests; Phase 92 should not weaken those seams while updating proof artifacts. [VERIFIED: codebase grep, targeted test runs] |
| V6 Cryptography | no [VERIFIED: phase scope] | No cryptographic controls are introduced or changed in this phase. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Support user reaches unscoped records on the shared `/audit` tree | Information Disclosure | Keep scope host-owned through `scope_query_fn` and prove the same shared-tree posture in docs plus example-host tests. [VERIFIED: requirements, docs, example tests] |
| Support user accesses export endpoints despite read-only posture | Elevation of Privilege | Keep `export_authorize_fn` server-authoritative and prove HTTP `403` denial in the example host. [VERIFIED: example tests, docs] |
| Adopters copy an outdated multi-tree or DSL-heavy recipe | Tampering / Design drift | Keep one canonical shared-tree recipe across guides, README, router snippet, and doc-contract tests. [VERIFIED: docs + tests] |
| Maintainers claim closure without replayable evidence | Repudiation | Record commands actually used in `87-VALIDATION.md` and point to named Mix/CI surfaces. [VERIFIED: CONTEXT.md, prior phase artifact pattern] |

## Sources

### Primary (HIGH confidence)
- Local codebase: `mix.exs`, `.github/workflows/ci.yml`, `guides/getting-started-saas.md`, `guides/operator-surface.md`, `guides/upgrade-path.md`, `examples/threadline_phoenix/README.md`, `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`, `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`, and the root doc-contract tests — current proof surfaces and rerun commands checked directly. [VERIFIED: codebase grep, targeted test runs]
- `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md` and `89-VALIDATION.md` — artifact format analogs. [VERIFIED: file read]
- `.planning/phases/86-scoped-read-path-closure/86-VERIFICATION.md` and `86-VALIDATION.md` — recent current-tree backfill analog showing verdict + validation split. [VERIFIED: file read]
- Official Phoenix LiveView testing docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html — confirms LiveView test primitives are the standard proof mechanism for mounted routes. [CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- Official Ecto docs: https://hexdocs.pm/ecto/Ecto.html — confirms Ecto is the standard official query layer in this stack. [CITED: hexdocs.pm/ecto/Ecto.html]
- Official Elixir ExUnit docs: https://hexdocs.pm/elixir/ExUnit.html — confirms ExUnit is the standard built-in test framework. [CITED: hexdocs.pm/elixir/ExUnit.html]

### Secondary (MEDIUM confidence)
- Official Hex package pages for versions referenced by the docs and example-host lane: https://hex.pm/packages/phoenix , https://hex.pm/packages/phoenix_live_view , https://hex.pm/packages/ecto , https://hex.pm/packages/phoenix_html , https://hex.pm/packages/phoenix_pubsub . [CITED: hex.pm package pages]

### Tertiary (LOW confidence)
- None. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended tooling is the current repo stack and was verified from local lockfiles / runtime probes. [VERIFIED: locks, command probes]
- Architecture: HIGH - the proof chain is explicit in the current docs, example router, tests, and prior backfill artifacts. [VERIFIED: codebase grep, file reads]
- Pitfalls: HIGH - the main failure mode (`mix test` on the example file from root) was reproduced directly, and the docs-only closure risk is locked by context. [VERIFIED: root-run compile failure, CONTEXT.md]

**Research date:** 2026-05-25  
**Valid until:** 2026-06-24 for repo-local planning assumptions; rerun proof commands if the public docs, example app, or Mix aliases change before planning. [VERIFIED: current tree scope]
