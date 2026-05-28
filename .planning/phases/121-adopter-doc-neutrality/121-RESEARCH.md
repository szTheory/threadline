# Phase 121: Adopter Doc Neutrality — Research

**Researched:** 2026-05-27
**Status:** Complete

## Question

What must Phase 121 change so first-hour docs are auth-neutral by default while both reference lanes remain discoverable and locked by doc contracts?

## Summary

Phase 121 is a **doc + doc-contract** slice: no `lib/` changes, no example-app auth swap. The main gap is `guides/getting-started-saas.md` §5, which opens with Sigra-primary prose and a hero fence using `Threadline.Integrations.Sigra`. README Start here still lists **three** lanes and an isolated Sigra bullet. Evaluator guide links upgrade-path but not phx-gen-auth. `phx_gen_auth_doc_contract_test.exs` was explicitly deferred from Phase 120; `mix.exs` `verify.doc_contract` does not yet include it or `sigra_doc_contract_test.exs`.

## Current State (gaps)

| Artifact | Gap vs ADOPT-AUTH |
|----------|-------------------|
| `getting-started-saas.md` §5 | Sigra callbacks as default narrative; Sigra plug fence is hero |
| `getting-started-saas.md` §6 | Inline curl with `_threadline_phoenix_key` reads as universal path |
| `getting-started-saas.md` Next reads | Sigra integration only; no phx-gen-auth link |
| `README.md` Start here | Three-lane literal; separate "Using Sigra" bullet |
| `evaluating-threadline.md` | No phx guide / `phx-gen-auth-reference` / neutrality sentence |
| `phx_gen_auth_doc_contract_test.exs` | Missing (deferred from 120) |
| `getting_started_saas_doc_contract_test.exs` | `assert String.contains?(doc, router_block())` on **whole** guide |
| `mix.exs` | `verify.doc_contract` omits phx (and sigra) integration contracts |

## Shipped anchors to preserve

- `guides/integration-contracts.md` — generic plug SSOT (`MyApp.Audit`, host callbacks)
- `guides/integrations/phx-gen-auth.md` — marker `<!-- PHX-GEN-AUTH-03-INTEGRATION-GUIDE -->`, `MyApp.AuditActor`, 1-arity authorize
- `guides/upgrade-path.md` — four-lane matrix + detection strings (locked in 120)
- `test/threadline/upgrade_path_doc_contract_test.exs` — **do not duplicate** matrix row asserts in new tests
- `GettingStartedFixtures.extract!(..., "router-pipeline-actor-fn")` — reuse for optional Sigra subsection only

## Recommended plan split

| Plan | Wave | Delivers | Requirements |
|------|------|----------|----------------|
| 121-01 | 1 | Getting-started §5/§6 neutrality, Next reads, upgrade-path intro alignment | ADOPT-AUTH-01 |
| 121-02 | 2 | README + evaluating discovery; phx doc contract; contract test updates; `mix.exs` alias | ADOPT-AUTH-02, ADOPT-AUTH-03 |

**Dependency:** 121-02 phx contract literals assume 121-01 did not rewrite phx guide (unchanged). Getting-started contract updates can span both plans; prefer 121-01 for `getting_started_saas_doc_contract_test.exs` neutrality asserts tied to §5/§6 copy.

## Implementation notes

### §5 rewrite pattern

1. Opening: host establishes identity → `Threadline.Plug` with host `actor_fn` / `context_overrides_fn`
2. Primary fence from `integration-contracts.md`:

   ```elixir
   plug Threadline.Plug,
     actor_fn: &MyApp.Audit.actor_ref_from_conn/1,
     context_overrides_fn: &MyApp.Audit.audit_context_overrides_from_conn/1
   ```

3. One sentence: phx guide uses `MyApp.AuditActor` — same callbacks, rename freely
4. Lane pointer bullets → phx guide, sigra guide (optional), upgrade-path matrix
5. Optional subsection with stable marker `<!-- getting-started-sigra-reference-fence -->` containing `router_block()` excerpt; label **sigra-reference example app only**
6. `refute` `Threadline.Integrations.Sigra` in §5 body before optional subsection

### §6 pattern

- Generic authenticate contract + small lane table (phx | sigra | upgrade-path)
- Move curl to `<details>` titled **Runnable curl — sigra-reference example app only**
- Link `examples/threadline_phoenix/README.md` for cookie staging SSOT

### phx_gen_auth_doc_contract_test.exs (~12–18 asserts)

Mirror `sigra_doc_contract_test.exs` **structure**, not scale (~55):

- Marker + title + lane honesty strings
- Section order: Prerequisites → Plug → Surface → Reference semantics → Non-goals → Lane and proof
- Host-owned literals: `MyApp.AuditActor`, scope-first `current_scope`, 1-arity authorize fence
- Proof path: `phx_gen_auth_integration_test.exs`, `mix verify.test`
- Refutes: `Sigra`, `forthcoming`, 2-arity `_, _ ->` in authorize fence

### README / evaluating literals

Replace three-lane string with four lanes including `phx-gen-auth-reference`. Grouped bullet:

**Phoenix auth (reference lanes, pick one):** phx-gen-auth.md · sigra.md — neither required.

Evaluator: add phx link, `` `phx-gen-auth-reference` ``, neutrality sentence; label Track A as **sigra-reference**.

### upgrade-path intro (D-121-24)

"Who this guide is for" already mentions phx on line 12; verify bullet list names all four structural lanes explicitly (capture-only, phoenix-surface, phx-gen-auth-reference, sigra-reference) — small copy fix only.

## Risks

| Risk | Mitigation |
|------|------------|
| Doc contract fails before doc copy lands | Plan order: 121-01 docs before 121-01 contract asserts; 121-02 registers phx contract after guide stable |
| Hex/docs strip `<details>` | Fallback `### Runnable curl (sigra-reference example app only)` per D-121 discretion |
| Over-claiming phx as default | Order supported lanes first; `reference` not `supported`; no "default Phoenix path" |
| Duplicating matrix locks | Do not add matrix row asserts outside `upgrade_path_doc_contract_test.exs` |

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (doc-contract + integration) |
| **Config file** | `mix.exs` aliases `verify.doc_contract`, `verify.test` |
| **Quick run** | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` |
| **Full doc contract** | `mix verify.doc_contract` |
| **Full CI-class** | `mix ci.all` (when Postgres available) |
| **Estimated runtime** | doc_contract ~30–90s; full ci.all minutes |

**Per-plan verify:**

- 121-01: `mix test test/threadline/getting_started_saas_doc_contract_test.exs` green after contract + guide edits
- 121-02: `mix verify.doc_contract` and `mix test test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` green

**Manual-only:** Visual read of §5/§6 on hexdocs rendering if `<details>` used — optional spot-check, not blocking.
