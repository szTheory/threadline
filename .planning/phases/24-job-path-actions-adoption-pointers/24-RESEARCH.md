# Phase 24 — Technical research

**Phase:** 24 — Job path, actions, adoption pointers  
**Question:** What do we need to know to plan REF-04–REF-06 well?

## RESEARCH COMPLETE

---

## 1. Oban + Phoenix + Ecto (example app)

- **Dependency:** Add `{:oban, "~> 2.19"}` (or current stable 2.x) to `examples/threadline_phoenix/mix.exs`; run `mix deps.get` under the example app.
- **Application:** Start Oban under `ThreadlinePhoenix.Application` **after** `Repo` (Oban needs `Ecto.Repo`): `{Oban, Application.fetch_env!(:threadline_phoenix, Oban)}` or inline opts.
- **Config:** `config :threadline_phoenix, Oban, repo: ThreadlinePhoenix.Repo, queues: [threadline_audit: 10], plugins: []` — dedicated queue name matches **24-CONTEXT D-01**.
- **Testing:** `Oban.Testing` (use `use Oban.Testing, repo: MyApp.Repo` in the test module or test helper) + `Oban.insert!/1` + `Oban.Testing.perform_job/1` (or `perform_job/2`) exercises the real `perform/2` path (**D-05**).
- **Sandbox:** Example `test/test_helper.exs` sets `Sandbox.mode(Repo, :manual)`; `DataCase` uses `start_owner!(Repo, shared: not tags[:async])`. Worker tests should **`use DataCase, async: false`** so the owner shares the connection with `perform_job` (same BEAM process in default Oban testing).

## 2. Job args + `Threadline.Job`

- **Contract:** `actor_ref` as string-key map from `ActorRef.to_map/1`; optional `"correlation_id"` string (**D-04**).
- **`job_id`:** Merge `"job_id" => to_string(job.id)` inside `perform/2` from `%Oban.Job{}` before `context_opts/1` — enqueue time has no DB id (**D-04**).
- **`context_opts/2`:** Maps `"correlation_id"` and `"job_id"` to keyword list for `record_action/2` (`lib/threadline/job.ex`).

## 3. Audited mutation + GUC (parity with Phase 23)

- **Pattern:** Mirror `ThreadlinePhoenix.Blog.create_post/2`: `Repo.transaction/1` → first statement `set_config('threadline.actor_ref', $1::text, true)` → then DML (**D-07**).
- **Table:** Mutate **`posts` only** — `Repo.get!/2` + `Post.changeset/2` + `Repo.update/2` (e.g. change **title** for a deterministic test slug) (**D-03**).
- **Context module:** Add a **named function** on `Blog` (or adjacent context) that performs **all DB work**; worker **only** parses args, merges `job_id`, calls context (**D-02**).

## 4. `Threadline.record_action/2` in the same transaction

- **Ordering:** After capture-relevant DML in the **same** `Repo.transaction/1`, call `Threadline.record_action(:<intent_atom>, [repo: Repo, actor: actor_ref] ++ Threadline.Job.context_opts(args))` (**D-11**).
- **Intent atom:** Pick one domain-meaningful atom (e.g. `:post_title_refreshed_from_queue`) — avoid `:test` (**D-12**).
- **`action_id` FK:** Optional for v1.7; if not wired, README note one sentence per **D-14**.

## 5. Assertions (REF-04 / REF-05)

- **Capture:** Query `Threadline.Capture.AuditChange` joined to `AuditTransaction` for `table_name == "posts"` after job runs.
- **Semantics:** Query `Threadline.Semantics.AuditAction` for `job_id` matching `to_string(job.id)` and name matching `Atom.to_string(intent_atom)`.
- **Linkage:** Assert `audit_transactions` row exists for the update; document if `action_id` on transaction is nil (**D-09**, **D-14**).

## 6. README adoption (REF-06)

- **Links:** From `examples/threadline_phoenix/README.md`, relative paths `../../guides/production-checklist.md` and `../../guides/adoption-pilot-backlog.md` (**D-15**).
- **Integrator-owned sentence:** Host-class STG matrix filled by integrator; library CI proves patterns only (**D-16**).
- **Doc contracts:** If adding anchors, extend `test/threadline/stg_doc_contract_test.exs` only if repo already asserts those headings (**D-17**).

## 7. Risks / pitfalls

- **GUC outside transaction:** Triggers will not see actor — must stay inside the same `Repo.transaction` as DML.
- **Missing actor in args:** `actor_ref_from_args/1` returns `{:error, :missing_actor_ref}` — worker should return `{:error, reason}` so Oban can retry/discard per policy.
- **Oban not started:** Tests that only call `perform/2` manually miss supervision/config bugs — prefer `perform_job`.

---

## Validation Architecture

Phase verification is **Mix / ExUnit** in the example app, gated from the repo root by **`mix verify.example`** (same harness as Phase 22–23).

| Dimension | Strategy |
|-----------|----------|
| **Automated proof** | New test module under `examples/threadline_phoenix/test/` using `DataCase` + `Oban.Testing`; asserts DB rows for capture + semantics. |
| **CI parity** | `MIX_ENV=test mix verify.example` from repository root (optionally `DB_HOST` / `DB_PORT` for compose). |
| **Sampling** | After each plan wave: `cd examples/threadline_phoenix && mix test path/to/file` then full `verify.example` before merge. |
| **Manual** | None required for REF-04–REF-06 if automated path stays green. |

Nyquist: every task in PLAN files must include `<read_first>`, concrete `<action>`, and grep-verifiable `<acceptance_criteria>`; verification blocks reference `mix verify.example` where appropriate.
