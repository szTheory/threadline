# Phase 116: Example First-Hour Fixes - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair `examples/threadline_phoenix/README.md` (and aligned doc-contract tests) so a maintainer or evaluator can clone the example app and reach a **first audited write** without README traps — specifically API auth staging for `POST /api/posts`, unambiguous clean-clone vs `mix demo.seed` paths, and clear ownership of `mix threadline.*` vs `mix ecto.*` vs `mix demo.*` tasks.

**Scope guard (ROADMAP):** Example README, example/root doc-contract tests, `mix verify.example`. **No new domain features**, no Threadline-owned auth product surface, no WALKTHROUGH content expansion beyond shared vocabulary alignment.

**Requirements:** EXAMPLE-01, EXAMPLE-02, EXAMPLE-03, EXAMPLE-04.

**Depends on:** Phase 115 (narrative docs already center `Threadline.Audit.transaction/3`; example README body already uses the helper — this phase is runbook friction only).

</domain>

<decisions>
## Implementation Decisions

### D-116-01: API auth staging for `POST /api/posts` (EXAMPLE-01)

- **D-116-01a:** **Browser Sigra session → cookie curl** is the primary evaluator path (not bare curl, not dev Bearer tokens, not “tests only” as the only story).
- **D-116-01b:** **Router change (minimal):** Add `plug :fetch_session` and `plug :fetch_current_scope` to `pipeline :api` **before** `Threadline.Plug`, so a browser login populates `conn.assigns.current_scope` for `/api/posts` the same way Sigra expects on browser routes (`UserAuth.fetch_current_scope/2` already exists).
- **D-116-01c:** New README subsection **`### Authenticate before the audited API call`** under **Audited HTTP path**, placed **before** the curl example. Content must state:
  - Threadline reads Sigra state from `current_scope` via `Threadline.Integrations.Sigra.actor_ref_from_conn/1`.
  - **This example does not ship API bearer tokens** — host owns auth (align `guides/integrations/sigra.md`).
  - Steps: `mix phx.server` → optional `mix demo.seed` + [DEMO_USERS.md](DEMO_USERS.md) → sign in at `/users/log_in` → copy `_threadline_phoenix_key` cookie → curl with `-b '_threadline_phoenix_key=…'`.
  - **Expected:** `201` + `audit_transaction_id`.
  - **Without session:** `500` + `missing actor` is intentional for this reference lane (capture ran, no actor on conn); hosts should fail earlier with their own `401`/`403` plugs in production.
  - **CI without browser:** `mix test test/threadline_phoenix_web/posts_audit_path_test.exs` (stages scope via `sigra_conn/2` in tests only).
- **D-116-01d:** **Update the curl block** to include `-b '_threadline_phoenix_key=PASTE_FROM_BROWSER'`; remove duplicate unauthenticated-only curl (one canonical block).
- **D-116-01e:** **Sync** `guides/getting-started-saas.md` §6 curl with the same auth staging (dual-contract: one logical changeset per OSS DNA §2).
- **D-116-01f:** **Reject for Phase 116:** dev-only `Authorization: Bearer` demo plug (looks like Threadline ships API auth); full CSRF cookie-jar login script in README (high friction — browser copy is enough); making bare curl the documented happy path.

**Rationale:** Ecosystem pattern (Phoenix, django-auditlog, Carbonite docs): library proves capture **after** host establishes identity on the conn. Bare curl today always 500s — evaluators blame Threadline. WALKTHROUGH already documents cookie curl for browser routes; API pipeline was missing session plugs. Tests already prove HTTP path via `sigra_conn/2` — document the production-shaped HTTP path for humans.

### D-116-02: Clean clone vs walkthrough fiction (EXAMPLE-02)

- **D-116-02a:** Add **`## Choose your path`** decision table immediately after **Prerequisites** (before install body):

  | Goal | Start here | Requires `mix demo.seed`? |
  |------|------------|---------------------------|
  | First audited write (`POST /api/posts`) on migrated DB | **Track A** | **No** |
  | Maintainer walk, seeded operators, `/audit` exercises | **Track B** + [WALKTHROUGH.md](./WALKTHROUGH.md) | **Yes** |
  | Threadline in your own Phoenix app | [getting-started-saas.md](../../guides/getting-started-saas.md) | N/A |

- **D-116-02b:** Restructure install into **`## Base install (all paths)`** (single numbered list) then short **`## Track A — First audited write`** and **`## Track B — Walkthrough fiction`** sections — **not** two fully duplicated install tracks (maintenance cost).
- **D-116-02c:** **Committed-checkout callout** at top of install: migrations already in repo — **skip** `threadline.install` / `gen.triggers` / `sigra.install` on normal clone; generators only for [Regenerating the skeleton](#regenerating-the-skeleton-generator-contract). Align vocabulary with WALKTHROUGH §1 (“skip generators on clean clone”).
- **D-116-02d:** **`## Mix task reference`** table (Task | Runs | Demo fiction?) covering `mix setup`, `ecto.setup`, `ecto.reset`, `demo.seed`, `demo.reset` — single footgun SSOT for `ecto.reset` vs `demo.reset`.
- **D-116-02e:** Terminology: **`priv/repo/seeds.exs` = neutral seeds** (two posts); **`mix demo.seed` = walkthrough fiction** — never use “seed” alone when meaning demo.
- **D-116-02f:** **Keep `## Demo walkthrough data` heading** (root `readme_doc_contract_test.exs` locks it); compress body to pointer to Track B + task reference — avoid a third parallel install story.
- **D-116-02g:** Remove or demote redundant **Installation step 7** (“optional `mix run priv/repo/seeds.exs`”) — document as “redundant if `ecto.setup` ran” in Base install prose only.

**Rationale:** Stripe/Phoenix/Rails pattern — name fiction tasks distinctly (`demo.seed`), state what `ecto.setup` includes, chooser before long prose. Satisfies EXAMPLE-02 without duplicating WALKTHROUGH.

### D-116-03: Task responsibility matrix (EXAMPLE-03)

- **D-116-03a:** **Format:** Option D — dual runbooks (clean clone vs greenfield callout) + appendix **`## Mix task ownership`** table (copy-ready rows below). One short **three-owner** paragraph above the table: **Ecto** = DB + apply SQL; **Threadline** = audit schema/trigger **generators**; **Sigra** = auth **generators**; **this example** = neutral `seeds.exs` + `demo.*` fiction.
- **D-116-03b:** **Clean clone runbook** (this repo): `deps` → `pg_isready` → `ecto.create` (first machine) → `ecto.migrate` → Track A or B fork. **Explicit skip** of generators.
- **D-116-03c:** **Greenfield callout** (your app): pointer to `guides/getting-started-saas.md` + generator order `threadline.install` → `threadline.gen.triggers --tables …` → `ecto.migrate` → Sigra only when adopting sigra-reference lane.
- **D-116-03d:** **Appendix table rows** (minimum set — implement verbatim or tighten wording without losing discriminative “Don’t confuse with” column):

  | Task | Owns | When to run | Don't confuse with |
  |------|------|-------------|-------------------|
  | `mix ecto.create` | Database object | First machine / missing DB | `threadline.install` (files, not DB) |
  | `mix threadline.install` | Migration files: capture function, audit tables | Greenfield / new base migrations | `ecto.migrate`; `ecto.create` |
  | `mix threadline.gen.triggers --tables …` | Per-table trigger migrations; reads `app.config` | After install; same `MIX_ENV` as CI | `threadline.install`; auditing `audit_*` tables |
  | `mix ecto.migrate` | Applies all pending SQL | After any new migration file | Generator tasks (emit only) |
  | `mix sigra.install …` | Sigra auth migrations + modules | Generator-fresh app without committed Sigra migrations | `threadline.*`; **skip on this checkout** |
  | `mix ecto.setup` | create + migrate + `priv/repo/seeds.exs` | Convenience bootstrap | `demo.seed`; does **not** install triggers by itself |
  | `mix demo.seed` | Walkthrough fiction | After migrate; WALKTHROUGH / `/audit` | `ecto.setup`; not auto-run |
  | `mix demo.reset` | Truncate demo tables + re-seed fiction | Walkthrough recovery | `ecto.reset` |
  | `mix ecto.reset` | drop + `ecto.setup` | Schema/trigger recovery | `demo.reset` |
  | `mix setup` | deps + compile + `ecto.setup` | Quick bootstrap after Postgres up | Starting Postgres; `demo.seed` |

- **D-116-03e:** Keep existing **`MIX_ENV` / `app.config`** note adjacent to `gen.triggers` (already in README) — do not bury in table only.

**Rationale:** Carbonite/Oban/Ash teach **library generates → Ecto migrates → app seeds**. Threadline’s two generators are the surprise for Phoenix devs; table + clean-clone callout matches WALKTHROUGH truth.

### D-116-04: Doc-contract locks (EXAMPLE-04)

- **D-116-04a:** **Same commit** as README + getting-started sync: doc change + contract change (OSS DNA §2).
- **D-116-04b:** **`test/threadline/example_phoenix_readme_contract_test.exs`** — new test **API auth staging** with literals including: `Authenticate before`, `fetch_current_scope`, `missing actor`, `DEMO_USERS.md`, `_threadline_phoenix_key`, `does not ship API bearer` (or agreed final phrase). **Refute** passwords in curl section. Keep existing incident/operator tests unchanged.
- **D-116-04c:** **`test/threadline/readme_doc_contract_test.exs`** — extend demo/setup test with: `` `mix ecto.reset` is schema/trigger recovery only ``, `` `mix demo.reset` for the daily walkthrough loop ``, `` `Mix task ownership` `` (or final appendix title), `` `neutral` `` + `` `walkthrough fiction` `` (or agreed pair), committed-checkout **skip** generators phrase.
- **D-116-04d:** **Do not lock:** full curl fences, DEMO passwords, WALKTHROUGH ticket literals, full phx.new flag block.
- **D-116-04e:** **Verification:** `mix verify.doc_contract` + `mix verify.example` green before phase closeout.

### Cross-cutting principles (coherent package)

- **Host-owned auth, Threadline-owned capture:** Docs must never imply Threadline provides login/API tokens; Sigra session (or host equivalent) before `Threadline.Plug` on API routes.
- **Three-layer language:** Capture (triggers + plug) → semantics (`Audit.transaction/3`) → exploration (`/audit`, CLI) — README install matrix stays in capture/setup lane, not operator deep dives.
- **Principle of least surprise:** Evaluator default path = Track A + browser cookie curl; maintainer path = Track B + WALKTHROUGH; greenfield integrators routed to getting-started-saas.
- **Dual README contract:** Root `readme_doc_contract_test.exs` + `example_phoenix_readme_contract_test.exs` split setup vs integration/auth depth (existing pattern).

### Claude's Discretion

- Exact prose/tone within the structures above.
- Decision table column wording if readability improves without losing contract literals.
- Whether to add one shared literal between README and WALKTHROUGH for “does not load demo fiction” (only if exact phrase match chosen).
- Optional POST `401` vs `500` alignment for missing actor (out of scope unless trivial).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 116 goal, success criteria, scope guard
- `.planning/REQUIREMENTS.md` — EXAMPLE-01 through EXAMPLE-04
- `.planning/phases/115-narrative-doc-sync/115-CONTEXT.md` — narrative sync complete; example changes deferred here
- `.planning/phases/114-release-0-6-0-packaging/114-CONTEXT.md` — deferred example README friction
- `.planning/threads/2026-05-27-milestone-next-step-v1.25-assessment.md` — assessment wedge (curl auth, setup confusion)

### Product vision and OSS process
- `prompts/threadline-elixir-oss-dna.md` — doc contracts, dual README changeset, `mix verify.*` entrypoints, canonical host under `examples/`
- `prompts/audit-lib-domain-model-reference.md` — capture vs semantics vs exploration; actor on conn
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — hybrid platform framing; host action context
- `prompts/prior-art/from-sigra/Auth Domain Language — A Field Guide.md` — authentication vs authorization; session semantics

### Runnable targets and guides
- `examples/threadline_phoenix/README.md` — primary edit surface
- `examples/threadline_phoenix/WALKTHROUGH.md` — Track B maintainer path; cookie curl precedent (WALK-01-07 area)
- `examples/threadline_phoenix/DEMO_USERS.md` — demo login credentials (pointer only in README)
- `guides/getting-started-saas.md` — §6 curl sync (EXAMPLE-01 dual-contract)
- `guides/integrations/sigra.md` — Threadline plug after host auth (if present; verify path at plan time)
- `guides/domain-reference.md` — COMP-EXAMPLE-INCIDENT-JSON routing

### Code anchors (implementation truth)
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — `:api` pipeline, `:browser` pipeline
- `examples/threadline_phoenix/lib/threadline_phoenix_web/user_auth.ex` — `fetch_current_scope/2`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_controller.ex` — `missing actor` behavior
- `lib/threadline/integrations/sigra.ex` — `actor_ref_from_conn/1`
- `examples/threadline_phoenix/test/support/conn_case.ex` — `sigra_conn/2`
- `test/threadline/example_phoenix_readme_contract_test.exs` — extend for EXAMPLE-01
- `test/threadline/readme_doc_contract_test.exs` — extend for EXAMPLE-02/03

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `UserAuth.fetch_current_scope/2` — already on `:browser` pipeline; reuse on `:api`
- `ConnCase.sigra_conn/2` — test staging pattern to reference in README (“tests only”)
- `WALKTHROUGH.md` — cookie `-b` pattern for authenticated dev routes
- `readme_doc_contract_test.exs` — already locks `demo.seed` / `does not run demo.seed automatically`

### Established Patterns
- API pipeline: `Threadline.Plug` with Sigra callbacks only (no require_authenticated)
- PostController: fail-closed `missing actor` → 500 (document, don’t hide)
- AuditTransactionController: 401 without actor (document inconsistency if touched later)
- Phase 115: blessed path is `Audit.transaction/3` in guides; example README already aligned on write path prose

### Integration Points
- Router `:api` pipeline — add session plugs before Threadline.Plug
- Root + example doc-contract tests — lock new literals
- `guides/getting-started-saas.md` — second surface for curl auth staging

</code_context>

<specifics>
## Specific Ideas

- **Ecosystem “do right”:** Phoenix session cookie for API after login; Carbonite/Oban “generate then migrate”; Stripe samples separate install from fixtures; Logidze/django-auditlog teach metadata at transaction boundary — Threadline’s `Audit.transaction/3` + Plug is the Elixir equivalent of “with_responsible” / request context.
- **Ecosystem “footguns avoided”:** ExAudit-style process-local context as the only story; Audited YAML blobs; implying `ecto.setup` loads demo fiction; Threadline shipping Bearer auth; bare curl as only HTTP proof.
- **Evaluator golden path (≤15 min):** `mix ecto.migrate` → `mix phx.server` → browser login → one curl with cookie → `201` + `audit_transaction_id` → optional `GET …/changes` — **no** `demo.seed` required for EXAMPLE-01 proof.

</specifics>

<deferred>
## Deferred Ideas

- **Dev-only Bearer demo token** for headless curl — useful automation shim but wrong narrative for v1.25 “host owns auth”; revisit only with explicit adopter demand.
- **POST 401 vs 500 alignment** for missing actor — polish, not first-hour blocker.
- **Full CSRF cookie-jar login script** in README — WALKTHROUGH-level complexity; browser DevTools copy is enough.
- **WALKTHROUGH structural rewrite** — vocabulary alignment only unless drift found during edit.
- **ecto.setup alias dropping seeds.exs** — product change beyond README; document current alias honestly unless separate decision.

</deferred>

---

*Phase: 116-example-first-hour-fixes*
*Context gathered: 2026-05-27*
