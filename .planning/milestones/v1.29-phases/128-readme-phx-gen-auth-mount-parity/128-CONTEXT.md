# Phase 128: README + phx-gen-auth Mount Parity - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Close adopter-facing first-hour footguns in README Quick Start and the phx-gen-auth integration guide so evaluators hit no silent config failures and see canonical scope-shaped mount examples. Doc-contract tests lock the fixes. No library API changes, no new product surface, no example-app router changes (sigra-reference lane stays as-is).

</domain>

<decisions>
## Implementation Decisions

### README Quick Start — `ecto_repos` placement (README-01, README-02)

- **D-128-01:** Insert a **new numbered step 2 — "Configure Threadline"** before install; renumber existing steps 2–5 → 3–6. Structural parity with getting-started §2 → §3 is the goal of this phase.
- **D-128-02:** Step 2 content: one-sentence lead-in that Threadline Mix tasks resolve repo from `config :threadline, ecto_repos` (not host `:ecto_repos` alone), then the **literal block** `config :threadline, ecto_repos: [MyApp.Repo]`, then cross-link to [getting-started §2 — Configure Threadline](guides/getting-started-saas.md#configure-threadline) for dual-repo rationale and multi-DB notes.
- **D-128-03:** Do **not** imply `mix threadline.install` validates Threadline repo wiring — install uses host `:ecto_repos` for migration paths; Threadline `:ecto_repos` is required before ops Mix tasks and operator-surface fallbacks.
- **D-128-04:** Reject minimal one-liner-only (Option C) and callout-box-only (Option D) patterns — README map must include the runnable literal, not just a pointer.

### README Quick Start — trigger table SSOT (TRIG-01)

- **D-128-05:** Slim Quick Start trigger step to **`mix threadline.gen.triggers --tables posts`** — same fiction as getting-started §4, example app, WALKTHROUGH, and README step 6 query examples.
- **D-128-06:** Add cross-links in the trigger step to **getting-started §4** (first-table walkthrough SSOT) and **production-checklist §1** (full `expected_tables` inventory + CI coverage gate). Multi-table flag syntax remains discoverable via `mix help threadline.gen.triggers` and task moduledoc — not in README Quick Start.
- **D-128-07:** Remove `--tables users,posts,comments` from README Quick Start — divergent table fiction is the highest copy-paste footgun; cross-link alone does not fix it.

### phx-gen-auth mount `authorize_fn` shape (AUTH-MOUNT-01)

- **D-128-08:** Adopt **"D+A: canonical callback, scope-first user lookup"** — mount uses function reference `authorize_fn: &MyApp.Audit.authorize_operator/1` (same dialect as README, operator-surface, integration-contracts, getting-started §9). Drop inline `fn %{assigns: %{current_user: %{role: "admin"}}} -> :ok` as the primary example.
- **D-128-09:** Inside `MyApp.Audit.authorize_operator/1`, resolve operator user **scope-first**: `assigns[:current_scope].user`, with short `assigns[:current_user]` fallback for Phoenix 1.7 / custom pipelines (mirror guide's existing scope-first `actor_fn` posture).
- **D-128-10:** Admin gate uses **`is_admin: true`** (or equivalent boolean) on the resolved user — not string `role: "admin"` as the primary pattern. Support-lane `{:ok, scope}` shape stays out of phx-gen-auth guide primary snippet; one-line pointer to `guides/integration-contracts.md` and getting-started §9 for advanced shape.
- **D-128-11:** Add `MyApp.Audit` module to phx-gen-auth guide (alongside existing `MyApp.AuditActor`). Do **not** change `examples/threadline_phoenix` router — sigra-reference lane intentionally maps `current_user` in `:operator_browser`.

### Integration test alignment (AUTH-MOUNT-01 proof)

- **D-128-12:** Extract shared `authorize_operator/1` into guide-faithful module (e.g. `Threadline.Integrations.PhxGenAuthReference.Audit` parallel to existing `AuditActor`).
- **D-128-13:** Integration tests prove: admin allow via `current_scope.user` with `is_admin: true`; non-admin deny via scope path; **one optional** legacy fallback test (`current_user` with no scope user) for 1.7 parity; existing Plug smoke unchanged.
- **D-128-14:** Extend `PhxGenAuthFixtures` with `admin_scope_user/0` / `member_scope_user/0` maps under `scope.user`.

### Doc-contract strictness (README-02, AUTH-MOUNT-02)

- **D-128-15:** Two-tier contract model (established in Phase 123 CFG work): **footgun locks** (literal + ordering within scoped section) + **semantic locks** (canonical literals + refutes for known-bad patterns). README and phx-gen-auth are map/lane guides — not full spine walkthroughs.
- **D-128-16 (README):** Add `section_slice("## Quick Start", "## Operator Surface")` helper to `readme_doc_contract_test.exs`. New test locks: literal `config :threadline, ecto_repos: [MyApp.Repo]` present; cross-link `getting-started-saas.md#configure-threadline`; **ordering** `literal_idx < mix threadline.install` within Quick Start slice. Separate TRIG-01 test: `--tables posts` in Quick Start; cross-links to getting-started §4 and production-checklist §1; **refute** `users,posts,comments` in Quick Start slice.
- **D-128-17 (phx-gen-auth):** Update `phx_gen_auth_doc_contract_test.exs` — replace legacy `current_user.role` mount assertion. In surface section slice, assert: `authorize_fn:`, `&MyApp.Audit.authorize_operator/1`, `%{assigns: assigns}`, `assigns[:current_scope]`, `is_admin: true`, `{:error, :unauthorized}`. **Refute** `%{assigns: %{current_user: %{role: "admin"}}}` and keep existing `_, _ ->` refute. Do **not** lock full normalized inline fn block (whitespace brittle).
- **D-128-18:** Integration test literals and doc-contract literals must match — no transition-period dual assertions.

### Claude's Discretion

- Exact step 2 lead-in prose wording (one sentence vs two) as long as dual-key distinction is clear
- Whether step 2 heading is "Configure Threadline" vs "Configure and install" — prefer "Configure Threadline" for getting-started parity; install moves to step 3
- Fixture module naming (`PhxGenAuthReference.Audit` vs extending existing test module)
- Optional lightweight ordering assertion in phx-gen-auth contract (`authorize_fn:` before `assigns[:current_scope]` in surface section)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements and assessment
- `.planning/REQUIREMENTS.md` — README-01, README-02, TRIG-01, AUTH-MOUNT-01, AUTH-MOUNT-02
- `.planning/ROADMAP.md` — Phase 128 success criteria
- `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md` — footgun evidence (README-ECTO, PHX-AUTH-MOUNT)

### Doc SSOT (mirror, do not diverge)
- `guides/getting-started-saas.md` §2 — Configure Threadline (`ecto_repos` literal + ordering)
- `guides/getting-started-saas.md` §4 — Generate triggers for posts (`--tables posts`)
- `guides/getting-started-saas.md` §9 — Mount operator surface (canonical `authorize_fn` callback ref pattern)
- `guides/production-checklist.md` §1 — Capture and triggers (`expected_tables` inventory)
- `guides/integration-contracts.md` — `%{assigns: assigns}` shared callback, export fallback mirror, support-lane scope returns
- `guides/operator-surface.md` — fail-closed mount contract, `:authorize_fn` semantics

### Doc-contract patterns (extend, do not reinvent)
- `test/threadline/getting_started_saas_doc_contract_test.exs` — CFG-02 ordering model (`literal_idx < section_3_idx`)
- `test/threadline/readme_doc_contract_test.exs` — README hub locks, `section_slice` pattern to add
- `test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` — lane guide section order + literal locks to update
- `test/threadline/integrations/phx_gen_auth_integration_test.exs` — proof module to align with guide

### Prior phase precedent
- `.planning/milestones/v1.27-ROADMAP.md` Phase 123 — CFG-01–03 established getting-started `ecto_repos` spine
- `.planning/milestones/v1.27-REQUIREMENTS.md` — CFG requirements marked complete

### Project DNA and vision
- `prompts/threadline-elixir-oss-dna.md` — doc contract tests as adopter claim authority; README points to canonical guide
- `prompts/audit-lib-domain-model-reference.md` — host-owned auth; Threadline does not become auth library
- `CLAUDE.md` — correct-by-default, composable Phoenix integration

### Example reference (sigra lane — do not change in this phase)
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — `my_authorize_fn/1` on `current_user` is intentional for sigra-reference, not phx-gen-auth-reference target

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/threadline/getting_started_saas_doc_contract_test.exs` — `section_slice/3`, `contains_normalized?/2`, CFG ordering test pattern to copy into README contract
- `test/threadline/integrations/phx_gen_auth_integration_test.exs` — existing `AuditActor` module + `PhxGenAuthFixtures` — extend, don't replace
- `test/threadline/readme_doc_contract_test.exs` — existing README hub tests; add Quick Start slice tests here

### Established Patterns
- **README-as-map, getting-started-as-walkthrough** — README declares itself the map (lines 92–96); minimal runnable literals + cross-links, not duplicate long-form fiction
- **Dual `:ecto_repos` keys** — host `config :my_app, ecto_repos` for install paths; `config :threadline, ecto_repos` for `resolve_repo!/0` consumers (getting-started §2 explains)
- **Scope-first actor, callback-ref mount** — Plug uses `current_scope`; mount uses `&Module.callback/1` with `%{assigns: assigns}` arity-1 contract
- **Doc-contract refutes** — lock known-bad patterns (`users,posts,comments` in Quick Start, legacy inline role match) instead of brittle full-block normalization

### Integration Points
- `README.md` Quick Start steps 1–5 → renumber to 1–6 with new config step
- `guides/integrations/phx-gen-auth.md` Surface section → replace mount snippet + add `MyApp.Audit` module
- `phx_gen_auth_doc_contract_test.exs` currently **requires** legacy mount literal — must update in same change set as guide

</code_context>

<specifics>
## Specific Ideas

### Ecosystem lessons applied
- **Oban / LiveDashboard pattern:** config is its own numbered step before commands — Threadline adopts this for `:ecto_repos` (Option A structural parity).
- **Carbonite / pgAudit pattern:** entry docs use one concrete runnable table; scope strategy in walkthrough + ops checklist — `--tables posts` not multi-table README fiction.
- **Rails/Devise / npm packages lesson:** README-only pointers for required config cause GitHub issues and late opaque failures — literal + link beats link-only.
- **Phoenix 1.8 scopes:** phx-gen-auth lane must read `current_scope.user`, not assume separate `current_user` assign.
- **Oban Web / LiveDashboard:** admin mounts use host-owned resolution; Threadline's 1-arity `%{assigns: assigns}` callback is the unified seam.

### Coherent package (all four areas)
1. New README step 2 with `ecto_repos` literal + §2 link
2. README triggers slim to `posts` + §4 + checklist §1 links
3. phx-gen-auth mount → `&MyApp.Audit.authorize_operator/1` with scope-first user lookup inside
4. Doc contracts: scoped ordering for README; semantic literals + refutes for phx-gen-auth; integration test matches guide

</specifics>

<deferred>
## Deferred Ideas

- WALKTHROUGH cwd / row-history URL truth — Phase 129 (WALK-01–03)
- Nyquist 125 finalize + SUMMARY frontmatter — Phase 130 (NYQ-01, PLAN-01)
- Updating sigra example router to scope-first authorize — out of scope; different adopter lane
- Multi-table `--tables` syntax in README — belongs in task help/moduledoc, not Quick Start
- Second phx.gen.auth reference app — v2 requirement; guide + root CI proof sufficient

</deferred>

---

*Phase: 128-readme-phx-gen-auth-mount-parity*
*Context gathered: 2026-05-28*
