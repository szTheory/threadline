# Phase 27 — Technical research

**Question:** What do we need to know to plan **LOOP-03** (example app correlation path) well?

## RESEARCH COMPLETE

---

## Library contracts

- **`Threadline.record_action/2`** — Inserts **`audit_actions`** in the **current** DB transaction when called inside **`Repo.transaction`**, linking to **`audit_transactions`** via **`action_id`** (see `lib/threadline.ex`, `AuditTransaction` moduledoc).
- **Opts** relevant to HTTP path: **`repo:`** (required), **`actor:`** / **`actor_ref:`**, **`correlation_id:`**, **`request_id:`** — all optional except repo/actor (`lib/threadline.ex` `@doc`).
- **`Threadline.Job.context_opts/1`** — Maps **`"correlation_id"`** / **`"job_id"`** from job args to keyword opts; HTTP path should mirror with **`AuditContext`** fields instead of inventing a parallel map shape (`lib/threadline/job.ex`).
- **`Threadline.Semantics.AuditContext`** — Struct fields: **`actor_ref`**, **`request_id`**, **`correlation_id`**, **`remote_ip`** — populated by **`Threadline.Plug`** from headers (`lib/threadline/plug.ex`, `audit_context.ex`).
- **`Threadline.timeline/2`** — Delegates to **`Threadline.Query.timeline/2`**; filters include **`:correlation_id`** with **strict join** to **`audit_actions`** when set (Phase 25 shipped). **`validate_timeline_filters!/1`** must pass before query.

## Example app current state

- **`Blog.create_post/2`** — Sets GUC, inserts **`Post`**, **no** **`record_action`** today (`examples/threadline_phoenix/lib/threadline_phoenix/blog.ex`).
- **`PostController.create/2`** — Resolves **`audit_context`** from **`conn.assigns`**, delegates to **`Blog.create_post/2`** (`post_controller.ex`).
- **`Blog.touch_post_for_job/2`** — **Reference pattern**: GUC → DML → **`Threadline.record_action(..., [repo: Repo, actor: actor_ref] ++ Job.context_opts(args))`** inside the same **`Repo.transaction`** (`blog.ex` L59–76).
- **`PostsAuditPathTest`** — Proves capture + **`AuditTransaction.actor_ref`** for **`POST /api/posts`** with **`x-correlation-id`** header already sent; does **not** assert **`audit_actions`** or timeline correlation filter (`posts_audit_path_test.exs`).

## Implementation risks

- **Ordering:** Call **`record_action`** **after** the audited insert succeeds (same transaction), so the capture transaction exists before semantics link **`action_id`**.
- **Nil correlation:** If header absent, **`record_action`** can omit **`correlation_id:`** or pass **`nil`** — confirm **`AuditAction.changeset`** accepts nil correlation (library tests in `audit_action_test.exs`).
- **Rollback:** On **`record_action`** error, **`Repo.rollback/1`** must unwind the whole transaction (match job path).
- **Test isolation:** Reuse **`ConnCase`**, unique slug per test, **`async: false`** if shared DB assumptions match existing audit test.

## README / doc contract

- **`test/threadline/readme_doc_contract_test.exs`** — Locks **REF-01** substrings (`mix phx.server`, `iex -S mix phx.server`, `mix test`, `ecto.migrate`). Any new guaranteed literal needs a contract line; prefer cross-links and headings without new mandatory literals (**27-CONTEXT D-4**).

## CI entrypoint

- **`mix verify.example`** — Runs example app tests from repo root (`mix.exs` alias). LOOP-03 proof must pass here.

---

## Validation Architecture

Execution feedback for Phase 27 is **automated-first**:

| Dimension | Strategy |
|-----------|----------|
| **1–7** | Standard: each task ends with **`mix compile --warnings-as-errors`** (root) and **`mix verify.example`** where the task touches the example app or library surface used by it. |
| **8 (Nyquist)** | After integration test lands: **no** task ships without a grep-verifiable test assertion or README cross-link called out in plan **`acceptance_criteria`**. |
| **Security sampling** | Correlation values in tests use **synthetic** strings (`System.unique_integer` / fixed test tokens), not secrets. |

**Quick command:** `mix verify.example` (from repository root, **`MIX_ENV=test`** via alias).  
**Full chain:** `mix ci.all` before merge.

---

## Recommendations for planner

1. **One vertical slice:** HTTP create transaction = GUC → insert → **`record_action`** with **`AuditContext`**-sourced opts.
2. **Action name:** Pick one stable atom (e.g. **`:post_created_via_api`**) and use consistently in test grep + README.
3. **Test module:** Either second **`test/...`** in **`posts_audit_path_test.exs`** or dedicated **`posts_correlation_path_test.exs`** with README naming the module explicitly (**27-CONTEXT**).
4. **README:** Replace stale **`action_id`** “future release” paragraph with strict semantics + pointer to test; add **one** **`export_json`** + **`jq`** hint sharing **`filters`** with **`timeline/2`**.
