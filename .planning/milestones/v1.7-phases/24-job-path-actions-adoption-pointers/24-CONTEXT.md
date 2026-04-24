# Phase 24: Job path, actions, adoption pointers - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **REF-04**, **REF-05**, and **REF-06** in **`examples/threadline_phoenix/`**:

- **REF-04** — Oban worker performs a **real audited row mutation** (trigger capture) using **`Threadline.Job`** for **serializable actor + job context** from args; **automated test** proves **capture linkage** and **job-scoped semantics** (actor + job lineage), not README-only proof.
- **REF-05** — At least one **`Threadline.record_action/2`** for a **representative intent**, with a **short operator-facing note** (README subsection and/or adjacent comment) explaining **when actions add value vs row-capture alone**.
- **REF-06** — Example **README** links **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`**, with an explicit **integrator-owned** line for host-class STG evidence (library CI does not certify third-party staging).

**Out of scope for Phase 24:** New HTTP routes beyond Phase 23’s **`POST /api/posts`** (no REST expansion to “enqueue job” unless a later phase requires it); **`users`** / real auth; new audited tables unless strictly necessary (prefer **`posts`**); LiveView; Hex semver policy.

</domain>

<decisions>
## Implementation Decisions

### Oban + audited write (REF-04)

- **D-01:** Add **Oban** to the example **`mix.exs`** and start it under **`ThreadlinePhoenix.Application`** with a **dedicated queue** for the reference worker(s)—idiomatic Phoenix/Ecto; keeps `mix test` / **`verify.example`** honest.
- **D-02:** Implement **one** worker module under **`lib/threadline_phoenix/workers/`** (exact module name: Claude’s discretion) whose responsibility is: **deserialize args** → **`Threadline.Job.actor_ref_from_args/1`** → delegate **all DB work** to a **Phoenix context** function—**never** fat `perform/2` with raw `Repo` only (carries Phase 23 **D-08** / **D-09** forward).
- **D-03:** **Mutate `posts` only** (title/slug fields available today)—**same audited table** as the HTTP path so operators and tests can **compare HTTP vs job** attribution without a second domain story.
- **D-04:** Job args are **JSON-serializable string-key maps**: at minimum **`"actor_ref"`** per **`ActorRef.to_map/1`**, optional **`"correlation_id"`**. For **`job_id`** in `Threadline.Job.context_opts/1`, merge **`"job_id" => to_string(job.id)`** inside `perform/2` from the **`%Oban.Job{}`** struct before building `record_action` opts (enqueue-time id is unavailable—**least surprise** vs stuffing fake ids in tests).
- **D-05:** **Canonical REF-04 proof = example-app automated test**, not curl/README: **`Oban.insert`** + **`Oban.Testing.perform_job/1`** (or current equivalent) so the **real Oban → `perform/2` path** runs—matches ecosystem default over hand-calling `perform/2` and avoids **Rails/Sidekiq-style** “implicit request context in worker” footguns.
- **D-06:** **Do not require a new public HTTP route** for Phase 24. Production pattern is documented in prose: controllers/contexts **enqueue** with **`actor_ref`** serialized from the same **`ActorRef`** model as **`Threadline.Plug`**—without expanding Phase 23’s **single POST** API surface (principle of least surprise; teaching stays one HTTP tracer + one job tracer).
- **D-07:** Inside the context’s **`Repo.transaction`**, apply the **same GUC prelude** as Phase 23 (**`set_config('threadline.actor_ref', …, true)`** before first audited statement) for **trigger-backed `actor_ref`**; jobs do **not** inherit connection state from HTTP—**re-set in the job transaction** (CTX / pooler-safe story).

### Test harness & CI (REF-04)

- **D-08:** Use **`Ecto.Adapters.SQL.Sandbox`** in **`{:shared, self()}`** (or the example’s established **`DataCase`** equivalent) for the **worker integration test module** so Oban’s execution process can use the sandbox checkout—avoids intermittent **ownership** failures seen when jobs run in **Sidekiq/async** stacks without explicit context bridges.
- **D-09:** Assertions must cover **`audit_changes`** for the job-driven mutation **and** **`audit_transactions`** linkage **and** semantic lineage where REF-05 applies (**`job_id`** / correlation on **`audit_actions`** when `record_action` is used)—satisfying REF-04’s “actor/job linkage” language without a second fake harness.
- **D-10:** **Optional** follow-up test using **queue drain / supervision** only if the worker adopts **uniqueness**, **cron**, or plugins where **`perform_job`** is insufficient—**default no** for v1.7 (speed + **YAGNI**).

### `record_action/2` (REF-05)

- **D-11:** Use the **same Oban worker + same transaction** as the audited row write: after capture-relevant statements (still inside the **same** `Repo.transaction` when ordering is clear), call **`Threadline.record_action/2`** with **`repo:`**, **`actor:`** from **`Threadline.Job.actor_ref_from_args`**, and **`Threadline.Job.context_opts(args_with_job_id)`**—this is the **library-moduledoc** pattern and matches **successful OSS** “one story: command → facts” pedagogy vs splitting unrelated demos.
- **D-12:** Pick one **domain-intent atom** that matches the mutation (e.g. post title/slug touch from queue—**not** a generic `:test`**) so README and operators read **product language**, not framework noise.
- **D-13:** Add a **short README subsection** (anchor-friendly heading, e.g. **“Semantics in jobs”**, 3–6 sentences): **row capture** = durable **what changed**; **`record_action/2`** = **why / intent** for operators when diffs are insufficient—link **`Threadline.Job`** on Hexdocs / in-repo **`lib/threadline/job.ex`** as secondary pointer.
- **D-14:** **Strict `action_id` FK wiring** between capture bundle and **`audit_actions`** is **not required** for v1.7 unless already trivial in the example schema—if omitted, **one sentence** in the note must say **linkage can be tightened later** so learners do not assume actions always join to the same transaction row.

### README adoption pointers (REF-06)

- **D-15:** Add a compact **“Documentation & production adoption”** section (single block is acceptable; **split** into **Production checklist** vs **Pilot / STG evidence** if readability wins) with **relative links** from the example README to **`../../guides/production-checklist.md`** and **`../../guides/adoption-pilot-backlog.md`**—**thin README**, no duplicated checklist bodies (**Oban/Phoenix pattern**: orientation in README, obligations in guides).
- **D-16:** Include **one explicit integrator-owned sentence**: **host-class** topology and STG matrix rows are **filled and evidenced by the integrator** (fork/PR per **`CONTRIBUTING.md`**)—library **CI proves patterns**, not external staging URLs (**v1.6 / v1.7 honest positioning**).
- **D-17:** If anchor URLs are used, keep them **covered by existing doc contract tests** where the repo already locks STG headings—avoid anchor-only links with no machine check.

### Claude's Discretion

- Exact **worker module name**, **intent atom**, and **which `posts` field** to mutate for the demo (minimal schema today: **title** / **slug** only).
- **Oban config** details (queues, repo, plugins, **crontab** empty)—standard Oban 2.x Phoenix layout.
- Whether to add a **second sentence** cross-linking **`CONTRIBUTING.md`** host STG section vs keeping REF-06 limited to the two guide files.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/milestones/v1.7-REQUIREMENTS.md` — **REF-04**, **REF-05**, **REF-06** acceptance text.
- `.planning/ROADMAP.md` — Phase 24 success criteria (Oban + `record_action` + README links).
- `.planning/PROJECT.md` — v1.7 job path + semantics + integrator-owned STG goals.

### Prior phase lock-in

- `.planning/milestones/v1.7-phases/22-example-app-layout-runbook/22-CONTEXT.md` — example path, `posts`, `verify.example`, synthetic actors, CI harness.
- `.planning/milestones/v1.7-phases/23-http-audited-path/23-CONTEXT.md` — Plug on `:api`, context-owned **GUC + transaction**, ConnCase proof, **no** Oban/`record_action` in Phase 23.

### Library contracts

- `lib/threadline/job.ex` — **`actor_ref_from_args/1`**, **`context_opts/2`**; serializable args contract (**CTX-05**).
- `lib/threadline.ex` — **`record_action/2`** options (`:job_id`, `:correlation_id`, `:repo`, `:actor`).
- `lib/threadline/plug.ex` — PgBouncer-safe pattern (no `SET` on connection); parity teaching with job path.
- `test/threadline/job_test.exs` — expected args shapes and **string keys**.

### Operator language & adoption artifacts

- `guides/production-checklist.md` — jobs + `record_action` rows integrators expect.
- `guides/adoption-pilot-backlog.md` — **STG** audited-path rubric; topology/evidence language.
- `guides/domain-reference.md` — **AuditAction** vs capture, telemetry hooks.
- `CONTRIBUTING.md` — host STG evidence workflow (if cross-referenced from example README).

### Doc / CI contracts (if links or anchors are asserted)

- `test/threadline/stg_doc_contract_test.exs` — STG doc shape locks (when REF-06 ties to anchors).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`examples/threadline_phoenix`** — `ThreadlinePhoenix.Post`, existing migrations/triggers for **`posts`**, **`ThreadlinePhoenix.Blog`** (or equivalent) context pattern from Phase 23 for **transaction + GUC + audited insert**.
- **`Threadline.Job`** — pure map helpers; **no** `Threadline.Job.run/3`; workers compose **`Repo.transaction` + GUC + Ecto** + optional **`record_action/2`** explicitly.
- **Root `mix.exs`** — **`verify.example`** alias; Phase 24 tests must remain inside the example app so the gate cannot rot.

### Established patterns

- **Phase 23** — **`ConnCase`** + real **`Endpoint`** for HTTP; Phase 24 mirrors **real stack** discipline using **`Oban.Testing`** + **`SQL.Sandbox`** sharing for jobs.
- **Library job tests** — `test/threadline/job_test.exs` documents **args** contracts; example tests show **end-to-end** usage.

### Integration points

- **`ThreadlinePhoenix.Application`** — add **Oban** to supervision tree.
- **`test/support/data_case.ex`** (or sibling) — extend or duplicate sandbox policy for **worker integration** modules.
- **Example `mix.exs`** — new **`{:oban, ...}`** dependency aligned with Phoenix 1.7+ ecosystem.

</code_context>

<specifics>
## Specific Ideas

- **Subagent research synthesis (2026-04-24):** Four passes converged on: **(1)** **`posts`-only** job mutation + **no new HTTP route** for enqueue, with **enqueue-from-context** described in README; **(2)** **`Oban.Testing.perform_job`** + **Sandbox {:shared, self()}** as default proof path; **(3)** **same worker + same transaction** for audited write + **`record_action/2`** aligned with **`Threadline.Job` moduledoc**; **(4)** **thin README** with two guide links + **integrator-owned STG** sentence, mirroring strong OSS split (README orientation / guides obligations). Cross-stack lesson: **context is data at enqueue time**, rehydrated in **`perform`**—never implicit process actor.

</specifics>

<deferred>
## Deferred Ideas

- **HTTP-triggered enqueue** (`POST` that only enqueues)—defer until a phase wants **full request → async** story; Phase 24 stays **job test + documented pattern**.
- **Second audited table** “for teaching isolation”—unnecessary while **`posts`** stays the single domain tracer.
- **`Oban.drain_queue` / plugin-heavy tests**—add only when uniqueness/cron forces it (**D-10**).

### Reviewed Todos (not folded)

- None from `gsd-sdk query todo.match-phase 24`.

</deferred>

---

*Phase: 24-job-path-actions-adoption-pointers*  
*Context gathered: 2026-04-24*
