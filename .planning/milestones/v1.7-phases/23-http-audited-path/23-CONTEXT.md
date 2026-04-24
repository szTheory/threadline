# Phase 23: HTTP audited path - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **REF-03**: the **`examples/threadline_phoenix`** app wires **`Threadline.Plug`** into the **same JSON API pipeline** that serves an audited write; a **controller or context** performs at least one **audited insert or update** on **`posts`** (Phase 22 table choice); proof is **primarily an automated integration test** through the real **Endpoint → Router → plugs → handler** stack, asserting **`audit_changes`** and **audit transaction linkage**. **Out of scope:** Oban / `Threadline.Job` (Phase 24, REF-04), **`record_action/2`** (REF-05), adoption README links (REF-06), **`users`** table / real auth stack, **`PATCH`** unless a later phase explicitly widens the HTTP story.

</domain>

<decisions>
## Implementation Decisions

### Proof strategy (REF-03)
- **D-01:** **Canonical proof = ConnCase (or equivalent) integration test** in `examples/threadline_phoenix` that issues a real **HTTP** request so **`Threadline.Plug`** runs exactly as in production wiring—not `DataCase`-only `Repo.insert`, not a stripped `Plug.Test` pipeline that omits documented plugs.
- **D-02:** Assertions must cover **`audit_changes`** for the mutation **and** linkage to the enclosing **`audit_transactions`** row (transaction id / FK relationship as defined by the installed schema), satisfying REF-03’s “transaction linkage” language.
- **D-03:** **Optional thin README subsection** (curl or httpie) allowed for human copy-paste; if present, treat the **test module as source of truth**—README points at the test file and stays minimal to avoid dual-spec drift. **Do not** satisfy REF-03 with README-only steps unless CI also executes them (not the default).

### HTTP actor (`Threadline.Plug` + capture)
- **D-04:** Use **`plug Threadline.Plug, actor_fn: &…/1`** returning a **synthetic, stable `ActorRef`** (e.g. `ActorRef.service("threadline-phoenix-example")` or namespaced fixture id)—no **`users`** table, no Bearer/API-key secrets in seeds or README, no credential-shaped demo material (carries Phase 22 **D-08** / **D-09** forward).
- **D-05:** **One-line README note** that production replaces `actor_fn` with real resolution (session, token lookup, etc.).
- **D-06:** **Encourage** example requests to send **`x-request-id`** / **`x-correlation-id`** in tests and optional README snippets so **`AuditContext`** teaches **request lineage** alongside **actor**—without implying fake API keys are authentication.

### API surface
- **D-07:** **Single happy path: `POST /api/posts`** (JSON create only) for Phase 23—smallest REST surface, one linear ConnCase story, satisfies “at least one audited insert or update” with an **insert**. **Defer `PATCH` / update HTTP demos** until a product-shaped reason (e.g. pairs with Phase 24 semantics) to avoid premature CRUD templates.

### Layering (GUC + transaction + writes)
- **D-08:** **`Repo.transaction`**, **`set_config('threadline.actor_ref', json, true)`** before first audited statement, and **audited Ecto writes** live in a **Phoenix context module** (e.g. `ThreadlinePhoenix.Blog` / `Posts`)—**not** bloated controllers, **not** in **`Threadline.Plug`** or Endpoint (violates PgBouncer-safe design in `Threadline.Plug` docs).
- **D-09:** **Skinny controller** parses params / returns JSON; passes **`conn.assigns[:audit_context]`** (or equivalent) into the context API so production and tests share one code path.
- **D-10:** **Small private helper or documented local function** for the GUC prelude (`ActorRef.to_map/1` → `Jason.encode!` → `Repo.query!(…, true)`) invoked **only inside** the context’s transaction—optional future extraction to a Hex-level helper is Claude’s discretion; do not introduce magic `Repo` that obscures why raw `Repo.insert` in IEx is unattributed.

### Router / pipeline
- **D-11:** Mount **`Threadline.Plug`** on the **`:api`** pipeline (same pipeline as `POST /api/posts`), preserving Phase 22 **API-first** stance. Order plugs so **`Plug.RequestId`** behavior matches what integrators run in prod if the example enables it—least surprise.

### Claude's Discretion

- Exact **module/function names** for context and controller; **optional** `Ecto.Multi` if the write grows multi-step—still keep `set_config` as first DB effect inside the **same** `Repo.transaction` as all audited steps.
- **README curl** length and whether to include it at all (D-03)—default is test-first, README optional.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/milestones/v1.7-REQUIREMENTS.md` — **REF-03** acceptance text.
- `.planning/ROADMAP.md` — Phase 23 success criterion (HTTP + Plug + proof).
- `.planning/PROJECT.md` — v1.7 goals, HTTP path expectation, non-goals.

### Prior phase lock-in
- `.planning/milestones/v1.7-phases/22-example-app-layout-runbook/22-CONTEXT.md` — example path, `posts` table, API-first, `verify.example`, synthetic fixtures, no `users` yet.

### Library contracts (implementation truth)
- `lib/threadline/plug.ex` — `Threadline.Plug` behavior, **no** `SET` on connection; CTX-03 bridge pattern in `@moduledoc`.
- `test/threadline/capture/trigger_context_test.exs` — transaction-local `threadline.actor_ref` + `set_config(..., true)` contract.

### Operator / domain language
- `guides/domain-reference.md` — **AuditContext** vs capture, **ActorRef**, transaction semantics.
- `prompts/audit-lib-domain-model-reference.md` — bounded context vocabulary for docs and comments.

### Example app integration points
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — current `:api` pipeline (Plug mounts here per D-11).
- `examples/threadline_phoenix/mix.exs` — `verify.example` entry from repo root.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`Threadline.Plug`** and **`Threadline.Semantics.AuditContext`** — request-scoped metadata; `actor_fn` hook is the extension point for D-04.
- **Library tests** — `test/threadline/plug_test.exs`, README doc contract tests compiling router + Plug patterns.
- **Example `ThreadlinePhoenix.Post`** schema and **posts** migrations + triggers from Phase 22.

### Established patterns
- **Dummy-app / nested-example CI** — Rails `test/dummy`–style honesty: **`mix verify.example`** is the non-negotiable gate; integration tests should mirror that stack.
- **Split responsibility** — Plug assigns vs **transaction-local GUC** inside `Repo.transaction` is the core teaching thread (CTX-03).

### Integration points
- **`conn_case.ex`** — extend with HTTP tests hitting **`ThreadlinePhoenixWeb.Endpoint`** so the full plug chain runs.
- **Root `mix.exs`** — `verify.example` already defined; Phase 23 tests live under the example app only unless contracts need extending.

</code_context>

<specifics>
## Specific Ideas

- **Research synthesis (2026-04-24):** Four parallel passes converged on: **(1)** integration test as canonical REF-03 proof with optional minimal README, **(2)** synthetic `ActorRef` via `actor_fn` + optional correlation headers, **(3)** `POST /api/posts` only as tracer bullet, **(4)** context-owned transaction + GUC with skinny controller—coherent with Phoenix 1.7+ conventions, OSS “main cannot rot,” and Threadline’s PgBouncer-safe capture bridge.

</specifics>

<deferred>
## Deferred Ideas

- **`PATCH /api/posts/:id`** and broader CRUD — defer until tied to Phase 24+ semantics or explicit requirement.
- **Real session / API-key auth in the example** — defer until `users` or integrator auth becomes an explicit phase; document replacement of `actor_fn` only.
- **Hex-level `with_audit_transaction/3` helper** — optional later if duplication appears across example + docs; not required for Phase 23.

### Reviewed Todos (not folded)

- None from `gsd-sdk query todo.match-phase 23`.

</deferred>

---

*Phase: 23-http-audited-path*  
*Context gathered: 2026-04-24*
