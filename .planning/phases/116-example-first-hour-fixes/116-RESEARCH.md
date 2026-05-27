# Phase 116: Example First-Hour Fixes — Research

**Researched:** 2026-05-27  
**Phase:** 116-example-first-hour-fixes  
**Requirements:** EXAMPLE-01, EXAMPLE-02, EXAMPLE-03, EXAMPLE-04  
**Status:** Ready for planning

---

## 1. Executive summary

Phase 116 closes the **first-hour friction wedge** identified in the v1.25 assessment: evaluators follow `examples/threadline_phoenix/README.md`, run the documented bare `curl` for `POST /api/posts`, and get **`500 missing actor`** — then blame Threadline instead of recognizing missing host auth. The fix is not a new auth product; it is **runbook truth** plus one **minimal router change** so browser Sigra login can populate `current_scope` on API routes the same way it already does on browser routes.

**What planners must internalize:**

| Area | Current gap | Phase 116 fix (from 116-CONTEXT) |
|------|-------------|----------------------------------|
| **EXAMPLE-01** | `:api` pipeline has `Threadline.Plug` but no `fetch_session` / `fetch_current_scope`; README curl has no cookie | Add session plugs before `Threadline.Plug`; document browser login → `_threadline_phoenix_key` cookie curl; sync `guides/getting-started-saas.md` §6 |
| **EXAMPLE-02** | Install steps imply generators on every clone; `demo.seed` vs `ecto.setup` vs neutral `seeds.exs` blurred | `## Choose your path` table + Track A/B fork after shared Base install; compress `## Demo walkthrough data` to pointer |
| **EXAMPLE-03** | Generator tasks listed as step 4–5 on every clone despite committed migrations | Clean-clone runbook skips generators; greenfield callout + `## Mix task ownership` appendix table |
| **EXAMPLE-04** | Doc contracts lock demo tasks but not auth staging or task-ownership literals | Extend both contract test files in same commit as README/guide edits |

**Critical implementation surprise (discovered in research):** Adding `fetch_current_scope` to `:api` will **break existing API integration tests** that use `sigra_conn/2` direct assign staging — plugs run at dispatch and overwrite pre-set `current_scope` with `nil` when no session token exists. Plan 01 must bundle a **test helper fix** (session-token path) or test migration; `mix verify.example` will catch this.

**Scope guard holds:** No WALKTHROUGH expansion, no Bearer demo plug, no POST 401 polish, no `ecto.setup` alias change — README honesty only unless product decision filed separately.

---

## 2. Current state analysis

### 2.1 Router — API pipeline missing session staging

```115:125:examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
  pipeline :api do
    # doc: start: router-pipeline-actor-fn
    plug(:accepts, ["json"])

    plug(Threadline.Plug,
      actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
      context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
    )

    # doc: end: router-pipeline-actor-fn
  end
```

Contrast `:browser` pipeline (lines 9–18): includes `plug :fetch_session` and `plug :fetch_current_scope`.

**Endpoint** already configures session cookie storage:

```7:12:examples/threadline_phoenix/lib/threadline_phoenix_web/endpoint.ex
  @session_options [
    store: :cookie,
    key: "_threadline_phoenix_key",
    signing_salt: "FFK2KECj",
    same_site: "Lax"
  ]
```

`Plug.Session` runs at endpoint level, but **pipeline `fetch_session` is still required** for `get_session/2` and `fetch_current_scope/2` to see login state on API routes.

**Actor resolution chain:**

1. `Threadline.Plug` → `Sigra.actor_ref_from_conn/1`
2. `actor_ref_from_conn/1` reads `conn.assigns[:current_scope]` (via `Map.get(conn.assigns, :current_scope)`)
3. `UserAuth.fetch_current_scope/2` populates that assign from `:user_token` session key (or remember-me cookie `_threadline_phoenix_user_remember_me`)

Without session plugs on `:api`, a browser login at `/users/log_in` sets the session cookie, but **`POST /api/posts` never loads it** → `actor_ref_from_conn/1` returns `nil` → `Blog.create_post/2` returns `{:error, :missing_actor}` → **500**.

### 2.2 PostController — intentional fail-closed behavior

```24:28:examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_controller.ex
        case Blog.create_post(audit_context, attrs, organization_id: organization_id) do
          {:error, :missing_actor} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{errors: %{detail: "missing actor"}})
```

Document this as **reference-lane truth** (capture ran, semantics rejected missing actor), not a bug to hide. `AuditTransactionController` uses 401 for drill-down — inconsistency is known deferred polish (116-CONTEXT deferred).

### 2.3 README — friction hotspots

| Section | Problem | Requirement |
|---------|---------|-------------|
| **Installation (steps 1–7)** | Steps 4–5 run `threadline.install`, `gen.triggers`, `sigra.install` unconditionally; contradicts committed-checkout reality documented in WALKTHROUGH §1 | EXAMPLE-02, EXAMPLE-03 |
| **Step 7** | Redundant `mix run priv/repo/seeds.exs` after `ecto.setup` (alias already runs seeds) | EXAMPLE-02 |
| **Demo walkthrough data** | Partially correct (`does not run demo.seed automatically`, ecto.reset vs demo.reset) but sits mid-doc without chooser | EXAMPLE-02 |
| **Audited HTTP path + curl (L338–346)** | Bare curl, no auth prerequisite; contradicts Sigra integration story | EXAMPLE-01 |
| **No task ownership matrix** | Generators vs migrate vs demo tasks scattered | EXAMPLE-03 |

**Already correct (Phase 115 carryover — do not regress):**

- `Threadline.Audit.transaction/3` blessed write path prose in Audited HTTP section
- Incident JSON, operator surface, correlation sections
- `mix ecto.reset` vs `mix demo.reset` one-liner (lines 113–114) — contract will lock these phrases

### 2.4 WALKTHROUGH alignment (vocabulary only)

WALKTHROUGH §1 WALK-01-02 already states the committed-checkout truth:

> On a **generator-fresh** skeleton only … This repo ships those migrations — **skip generators on a normal clean clone**.

WALKTHROUGH §2 WALK-01-07 documents cookie curl for dev help-desk route (`-b "your_session_cookie"`). Phase 116 brings README API curl to the same pattern using `_threadline_phoenix_key`.

**Do not restructure WALKTHROUGH** — optional shared literal alignment only if exact phrase chosen during implementation.

### 2.5 Tests — current proof paths

| Test file | Auth staging | Will break after router change? |
|-----------|--------------|--------------------------------|
| `posts_audit_path_test.exs` | `sigra_conn/2` direct assign | **Yes** — `fetch_current_scope` overwrites assign |
| `posts_correlation_path_test.exs` | `sigra_conn/2` | **Yes** |
| `posts_incident_json_path_test.exs` | `sigra_conn/2` | **Yes** |
| `help_desk_audit_http_test.exs` | browser/session path | Likely OK |
| `sigra_auth_flow_test.exs` | `init_test_session` + HTTP login | OK |

`ConnCase.sigra_conn/2` (lines 49–76) assigns `:current_scope` and `:sigra_session` in private **before** dispatch. Once `:api` runs `fetch_current_scope`, those assigns are replaced unless a valid `:user_token` exists in session.

**Mitigation pattern already in tree:** `ConnCaseHelpers.log_in_user/2` sets `init_test_session` + `put_session(:user_token, token)`. Plan should either:

- Enhance `sigra_conn/2` to create/use a fixture user + session token while preserving custom `user_id` in scope, **or**
- Migrate API path tests to `login_via_sigra/3` / `log_in_user/2` + real user fixture

README will document CI path as `mix test test/threadline_phoenix_web/posts_audit_path_test.exs` with note that tests stage scope via `sigra_conn/2` **in tests only** — after fix, that helper must remain functional.

### 2.6 Doc-contract tests — current locks

**`test/threadline/example_phoenix_readme_contract_test.exs`** (6 tests):

- Sigra callback pair, incident auth boundary, operator surface story, router compile-time checks
- **Missing:** API auth staging literals (EXAMPLE-01)

**`test/threadline/readme_doc_contract_test.exs`**:

- `"example README documents demo seed and reset tasks"` locks `## Demo walkthrough data`, `mix demo.seed`, `does **not** run demo.seed automatically`
- **Missing:** `Mix task ownership`, `neutral` + `walkthrough fiction`, committed-checkout skip generators, ecto.reset/demo.reset recovery phrases (partially present in README but not all locked per D-116-04c)

**`test/threadline/getting_started_saas_doc_contract_test.exs`**:

- Locks §1–§9 headings and integration blocks
- **Missing:** auth staging literals for §6 curl (D-116-01e dual-contract — plan must decide whether to extend this file or rely on grep in plan verify steps)

### 2.7 Getting-started sync (dual-contract)

`guides/getting-started-saas.md` §6 (lines 117–125) mirrors the example README bare curl today. Phase 115 centered the Elixir `Audit.transaction/3` block but left curl unauthenticated. EXAMPLE-01 requires **same auth staging story** for greenfield integrators: host establishes identity on conn before `Threadline.Plug`; example uses Sigra session cookie, integrator uses their auth equivalent.

### 2.8 Verification entrypoints

From root `mix.exs`:

- **`mix verify.doc_contract`** — runs 11 contract test files including both README contract files and `getting_started_saas_doc_contract_test.exs`
- **`mix verify.example`** — `cd examples/threadline_phoenix && mix deps.get && mix compile --warnings-as-errors && mix ecto.create && mix test` (full example suite)
- **`mix ci.all`** — includes both

Phase closeout: both `verify.doc_contract` and `verify.example` green (EXAMPLE-04, D-116-04e).

### 2.9 Mix task ground truth (example app)

From `examples/threadline_phoenix/mix.exs`:

```elixir
setup: ["deps.get", "compile", "ecto.setup"],
"ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
"ecto.reset": ["ecto.drop", "ecto.setup"],
```

- **`priv/repo/seeds.exs`** — two neutral posts (`Synthetic note A/B`), no help-desk fiction
- **`mix demo.seed`** — walkthrough fiction (`lib/mix/tasks/demo.seed.ex`, `lib/threadline_phoenix/demo/seed.ex`)
- **`mix demo.reset`** — truncate demo tables + re-seed (`lib/mix/tasks/demo.reset.ex`)

Document honestly: `ecto.setup` runs neutral seeds, **never** demo fiction.

---

## 3. Implementation approach per requirement

### EXAMPLE-01 — API auth staging for `POST /api/posts` curl

**Code (D-116-01b):** In `router.ex` `:api` pipeline, insert **before** `Threadline.Plug`:

```elixir
plug(:fetch_session)
plug(:fetch_current_scope)
```

Import already present: `import ThreadlinePhoenixWeb.UserAuth` (line 4).

**README (D-116-01c, D-116-01d):** Under `## Audited HTTP path`, add **`### Authenticate before the audited API call`** before curl block:

- Threadline reads Sigra via `Threadline.Integrations.Sigra.actor_ref_from_conn/1` from `current_scope`
- **Does not ship API bearer tokens** — host owns auth (pointer to `guides/integrations/sigra.md`)
- Steps: `mix phx.server` → optional `mix demo.seed` + DEMO_USERS.md → `/users/log_in` → copy `_threadline_phoenix_key` from DevTools → curl with `-b '_threadline_phoenix_key=PASTE_FROM_BROWSER'`
- Expected: `201` + `audit_transaction_id`
- Without session: `500` + `missing actor` is intentional
- CI: `mix test test/threadline_phoenix_web/posts_audit_path_test.exs` (tests stage via `sigra_conn/2`)

**Update canonical curl** — single block with `-b` flag; remove bare-only duplicate.

**Getting-started sync (D-116-01e):** Add equivalent auth subsection before §6 curl; adapt wording for greenfield host ("sign in on your app's login route") while preserving cookie-staging pattern for those copying the reference app literally.

**Reject:** Bearer demo plug, CSRF login script, bare curl as happy path.

**Test fix (research addition):** Update `sigra_conn/2` or API path tests so `mix verify.example` stays green after router change — non-optional part of EXAMPLE-01 implementation.

### EXAMPLE-02 — Clean clone vs walkthrough fiction

**Structure (D-116-02a–g):**

1. After `## Prerequisites`, add **`## Choose your path`** decision table (Track A / Track B / getting-started pointer)
2. Replace monolithic `## Installation` with:
   - **`## Base install (all paths)`** — single numbered list: deps → pg_isready → ecto.create → ecto.migrate → (optional) ecto.setup; **committed-checkout callout** skipping generators
   - **`## Track A — First audited write`** — phx.server → login → cookie curl → optional GET changes; **no demo.seed**
   - **`## Track B — Walkthrough fiction`** — pointer to WALKTHROUGH.md + `mix demo.seed` / `mix demo.reset`
3. Keep **`## Demo walkthrough data`** heading (root contract lock); compress body to Track B pointer + task reference cross-link
4. Add **`## Mix task reference`** summary table (Task | Runs | Demo fiction?) — footgun SSOT
5. Terminology: **`priv/repo/seeds.exs` = neutral seeds**; **`mix demo.seed` = walkthrough fiction** — never bare "seed" for demo
6. Remove/demote Installation step 7 redundant seeds callout

**Align vocabulary** with WALKTHROUGH §1 "skip generators on clean clone" without duplicating WALKTHROUGH steps.

### EXAMPLE-03 — Generator/migration task clarity

**Format (D-116-03a–e):** Option D from context:

- Short three-owner paragraph: **Ecto** (DB + apply SQL), **Threadline** (audit generators), **Sigra** (auth generators), **example app** (neutral seeds + demo.*)
- **Clean-clone runbook** in Base install (skip generators)
- **Greenfield callout** box → `guides/getting-started-saas.md` + generator order
- **`## Mix task ownership`** appendix with verbatim table from D-116-03d (minimum 10 rows)
- Keep existing **`MIX_ENV` / `app.config`** note adjacent to `gen.triggers` in Regenerating the skeleton section — not table-only

**Regenerating the skeleton** section remains the home for greenfield generator commands; Base install must not repeat them as required steps.

### EXAMPLE-04 — Doc-contract locks + verification

**Same commit rule (D-116-04a):** README + getting-started + contract tests together (OSS DNA §2 dual-contract).

**`example_phoenix_readme_contract_test.exs` (D-116-04b)** — new test `"example README documents API auth staging for POST /api/posts"`:

| Literal | Purpose |
|---------|---------|
| `Authenticate before` | subsection title |
| `fetch_current_scope` | plug name |
| `missing actor` | unauthenticated expectation |
| `DEMO_USERS.md` | login pointer |
| `_threadline_phoenix_key` | session cookie key |
| `does not ship API bearer` (or final phrase) | host-owned auth boundary |

**Refute:** passwords embedded in curl section.

**Keep unchanged:** incident/operator/router tests.

**`readme_doc_contract_test.exs` (D-116-04c)** — extend `"example README documents demo seed and reset tasks"` or add sibling test:

| Literal | Purpose |
|---------|---------|
| `` `mix ecto.reset` is schema/trigger recovery only `` | ecto.reset semantics |
| `` `mix demo.reset` for the daily walkthrough loop `` | demo.reset semantics |
| `Mix task ownership` | appendix title |
| `neutral` + `walkthrough fiction` | seed terminology pair |
| committed-checkout skip generators phrase | clean-clone truth |

**Do not lock:** full curl fences, DEMO passwords, WALKTHROUGH ticket literals, phx.new flag block.

**Optional third contract:** Extend `getting_started_saas_doc_contract_test.exs` with §6 auth literals if dual-contract parity desired — recommend at minimum one shared literal (`Authenticate before` or `_threadline_phoenix_key`) in getting-started test to prevent drift.

---

## 4. File-by-file change map

| File | Change type | Requirement(s) | Notes |
|------|-------------|----------------|-------|
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | **Edit** | EXAMPLE-01 | Add `fetch_session`, `fetch_current_scope` to `:api` pipeline |
| `examples/threadline_phoenix/README.md` | **Major restructure** | EXAMPLE-01–03 | Chooser, Base install, Tracks A/B, auth subsection, curl, task tables, compress Demo section |
| `guides/getting-started-saas.md` | **Edit** | EXAMPLE-01 | §6 auth staging + curl `-b` sync |
| `examples/threadline_phoenix/test/support/conn_case.ex` | **Edit** | EXAMPLE-01, EXAMPLE-04 | Fix `sigra_conn/2` for session-plug compatibility OR document migration to `log_in_user` |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_*_test.exs` | **Maybe edit** | EXAMPLE-04 | Only if conn_case fix insufficient |
| `test/threadline/example_phoenix_readme_contract_test.exs` | **Edit** | EXAMPLE-04 | New API auth staging test |
| `test/threadline/readme_doc_contract_test.exs` | **Edit** | EXAMPLE-04 | Extend demo/setup/ownership literals |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | **Optional edit** | EXAMPLE-01, EXAMPLE-04 | §6 auth literals — recommended for dual-contract |
| `examples/threadline_phoenix/WALKTHROUGH.md` | **No structural change** | — | Vocabulary alignment only if exact phrase match chosen |
| `guides/integrations/sigra.md` | **Read-only cross-link** | EXAMPLE-01 | Already documents plug-after-auth; link from README auth subsection |

**Out of scope (explicit):** `post_controller.ex`, `user_auth.ex` logic, new Mix tasks, Bearer plug, WALKTHROUGH rewrite, root `README.md` (unless cross-link drift found).

---

## 5. Risks and mitigations

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| R-116-01 | `fetch_current_scope` on `:api` breaks `sigra_conn/2` tests | **High** | Bundle conn_case fix in Plan 01; run `mix verify.example` before Plan 02 |
| R-116-02 | README restructure breaks existing doc-contract literals (`## Demo walkthrough data`, `mix threadline.install` in REF-01 test) | Medium | Keep locked headings; update REF-01 test only if install section moves literals — `mix threadline.install` must remain somewhere (Regenerating skeleton + ownership table) |
| R-116-03 | Dual-contract drift between example README and getting-started §6 | Medium | Same commit; optional getting_started contract extension |
| R-116-04 | Evaluator copies wrong cookie (remember-me vs session key) | Low | Document `_threadline_phoenix_key` explicitly; mention DevTools Application → Cookies |
| R-116-05 | Track A/B duplication maintenance | Low | D-116-02b forbids two full install tracks — shared Base install only |
| R-116-06 | Implying Threadline ships API auth | Medium | Literal lock `does not ship API bearer`; reject Bearer plug |
| R-116-07 | `mix verify.example` slow/flaky on dirty deps | Low | Standard phase verify; no change to verify alias |
| R-116-08 | Router doc fence `router-pipeline-actor-fn` used by getting-started contract | Low | Session plugs go **outside** doc fence OR extend fence to include them — planner must check `GettingStartedFixtures.extract!` block still matches |

---

## 6. Verification commands

Run from **repository root** unless noted.

### Phase closeout (required)

```bash
# Doc contracts (EXAMPLE-04)
mix verify.doc_contract

# Example app compile + full test suite (EXAMPLE-04)
mix verify.example
```

### Targeted during implementation

```bash
# Example README contract (new + existing)
mix test test/threadline/example_phoenix_readme_contract_test.exs

# Root README / example demo task contract
mix test test/threadline/readme_doc_contract_test.exs

# Getting-started dual-contract (if extended)
mix test test/threadline/getting_started_saas_doc_contract_test.exs

# HTTP audit path proof (README CI pointer)
cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/posts_audit_path_test.exs

# Full example suite
cd examples/threadline_phoenix && MIX_ENV=test mix test
```

### Manual golden path (Track A — ≤15 min evaluator check)

```bash
cd examples/threadline_phoenix
mix deps.get && mix compile
pg_isready -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}"
mix ecto.create   # first machine only
mix ecto.migrate
mix phx.server    # separate terminal
# Browser: http://localhost:4000/users/log_in (register if needed)
# Copy _threadline_phoenix_key cookie
curl -sS -X POST "http://localhost:4000/api/posts" \
  -H "content-type: application/json" \
  -H "x-request-id: $(uuidgen)" \
  -H "x-correlation-id: demo-corr" \
  -b '_threadline_phoenix_key=PASTE' \
  -d '{"post":{"title":"Hello","slug":"hello-demo-slug"}}'
# Expect 201 + audit_transaction_id in JSON
```

**Negative check:** Same curl without `-b` → `500` + `"missing actor"`.

---

## 7. Validation Architecture

Nyquist validation map: each requirement gets **automated contract or integration proof** plus **manual golden path** where human browser steps are involved.

### EXAMPLE-01 — API auth staging

| Layer | Mechanism | File / command |
|-------|-----------|----------------|
| **Unit/integration** | Router compiles with session plugs; API tests pass with actor on transaction | `posts_audit_path_test.exs`, `mix verify.example` |
| **Doc contract** | Literal grep locks for auth subsection vocabulary | `example_phoenix_readme_contract_test.exs` (new test) |
| **Dual-contract** | Getting-started §6 mirrors auth story | `getting-started-saas.md` + optional `getting_started_saas_doc_contract_test.exs` |
| **Manual UAT** | Browser login → cookie curl → 201 | Track A golden path above |
| **Negative proof** | Bare curl → 500 missing actor documented + manually verifiable | README prose + manual curl |

### EXAMPLE-02 — Clean clone vs demo.seed

| Layer | Mechanism | File / command |
|-------|-----------|----------------|
| **Doc contract** | `## Demo walkthrough data`, `does not run demo.seed automatically`, Track chooser literals | `readme_doc_contract_test.exs` |
| **Doc contract** | `neutral` + `walkthrough fiction` terminology | `readme_doc_contract_test.exs` |
| **Cross-doc** | WALKTHROUGH §1 skip-generators vocabulary aligned | Manual diff review (no WALKTHROUGH contract expansion) |
| **Manual UAT** | Track A path completes without `mix demo.seed` | Golden path |
| **Manual UAT** | `mix ecto.setup` does not create hero tickets | No #4521 without demo.seed |

### EXAMPLE-03 — Task responsibility clarity

| Layer | Mechanism | File / command |
|-------|-----------|----------------|
| **Doc contract** | `Mix task ownership`, ecto.reset vs demo.reset phrases, skip generators on clone | `readme_doc_contract_test.exs` |
| **Doc contract** | REF-01 retains `mix threadline.install` + `gen.triggers` somewhere | `readme_doc_contract_test.exs` `"example README carries runbook literals for REF-01"` |
| **Manual UAT** | Clean clone: migrate only, no generator commands | Base install checklist |
| **Manual UAT** | Greenfield reader routed to getting-started-saas | Chooser table row 3 |

### EXAMPLE-04 — Verification green after changes

| Layer | Mechanism | File / command |
|-------|-----------|----------------|
| **CI gate** | Full doc contract suite | `mix verify.doc_contract` |
| **CI gate** | Example app compile + tests | `mix verify.example` |
| **Regression** | Existing example contract tests unchanged pass | `example_phoenix_readme_contract_test.exs` (6 existing + 1 new) |

**Validation debt:** None expected — all requirements have automated or scripted proof paths. Browser cookie copy remains manual UAT (acceptable for first-hour docs; WALKTHROUGH uses same pattern).

---

## 8. Plan split recommendation

**Recommend 2 plans, 2 waves** — mirrors Phase 115 split (code/doc surface first, then broader doc restructure + contracts).

### Plan 116-01 — API auth staging (Wave 1)

**Requirements:** EXAMPLE-01 (primary), EXAMPLE-04 (partial)

| Task cluster | Files |
|--------------|-------|
| Router session plugs | `router.ex` |
| Fix test helper compatibility | `conn_case.ex`, possibly `posts_*_test.exs` |
| README auth subsection + curl | `README.md` (Audited HTTP section only) |
| Getting-started §6 sync | `getting-started-saas.md` |
| Example doc contract auth test | `example_phoenix_readme_contract_test.exs` |
| Optional getting-started contract | `getting_started_saas_doc_contract_test.exs` |

**Verify before Plan 02:** `mix verify.example`, `mix test test/threadline/example_phoenix_readme_contract_test.exs`

**Depends on:** Phase 115 complete (narrative aligned)

### Plan 116-02 — First-hour runbook clarity (Wave 2)

**Requirements:** EXAMPLE-02, EXAMPLE-03, EXAMPLE-04 (remainder)

| Task cluster | Files |
|--------------|-------|
| README restructure (chooser, Base install, Tracks A/B, task tables, Demo compression) | `README.md` |
| Root doc contract extensions | `readme_doc_contract_test.exs` |
| REF-01 literal audit after restructure | same |

**Verify at phase closeout:** `mix verify.doc_contract`, `mix verify.example`

**Depends on:** 116-01 (curl/auth section anchors Track A; avoid merge conflicts by doing structural README work after auth subsection landed)

### Alternative (single plan)

Viable if team prefers one PR — total touch surface ~8 files, ~200–350 LOC doc delta, ~4 LOC code. **Downside:** Large README diff mixed with router change complicates review. **Recommend 2 plans** for atomic commits and clearer review boundaries.

### Wave diagram

```
Wave 1: 116-01 (router + auth docs + example auth contract + test fix)
           │
           ▼
Wave 2: 116-02 (README restructure + root doc contract + full verify)
```

---

## Canonical references for planners

- `.planning/phases/116-example-first-hour-fixes/116-CONTEXT.md` — binding decisions D-116-01 through D-116-04
- `.planning/phases/115-narrative-doc-sync/115-01-PLAN.md` — plan YAML frontmatter format reference
- `prompts/threadline-elixir-oss-dna.md` §2 — dual-contract same commit
- `examples/threadline_phoenix/WALKTHROUGH.md` §1 WALK-01-02 — skip generators precedent
- `guides/integrations/sigra.md` — plug callback wire-up

---

*Research complete — ready for `/gsd-plan-phase 116`*
