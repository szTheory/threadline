# Phase 24: Job path, actions, adoption pointers - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **24-CONTEXT.md** — this log preserves alternatives considered.

**Date:** 2026-04-24  
**Phase:** 24 — Job path, actions, adoption pointers  
**Mode:** `[--all]` — all gray areas selected; user requested **one-shot research-backed recommendations** via parallel subagents (no interactive Q/A turns).

**Areas covered:** Oban + audited write (REF-04) · Job test harness · `record_action/2` placement (REF-05) · README adoption links (REF-06)

---

## 1. Oban + audited write shape (REF-04)

| Option | Description | Selected |
|--------|-------------|----------|
| A | HTTP enqueues job → integration proves full path | |
| B | Test-only `Oban.insert` + worker `perform` | |
| C | Dedicated tiny audited table | |
| D | Hybrid (HTTP optional + test-first proof) | ✓ (resolved: **test-first canonical**, HTTP optional **deferred**) |

**Research highlights:** Rails/Sidekiq and Spring async show **footgun: implicit request context in worker** → explicit serialized **`actor_ref`** at enqueue. Oban ecosystem favors **`Oban.Testing.perform_job`**. GUC must be **re-set inside job transaction** (no cross-process inheritance).

**User's choice:** Delegated to synthesized plan — **D-05** locks **no new HTTP route**; canonical proof = **example automated test** through **`perform_job`**.

**Notes:** `Threadline.Job` has **no** `run/3` helper; implementation uses **context + `Repo.transaction` + `set_config`** explicitly.

---

## 2. Test strategy for jobs

| Option | Description | Selected |
|--------|-------------|----------|
| Direct `Worker.perform` | Fastest, skips Oban contract | |
| `Oban.Testing.perform_job` | Real perform path, good DX | ✓ |
| Full supervision + drain | Highest fidelity, slower | Optional only (**D-10**) |

**Research highlights:** Sandbox **{:shared, self()}** or explicit **`allow`** prevents flaky ownership; **`verify.example`** should run worker specs **in the same gate** as ConnCase.

**User's choice:** Synthesized — **`perform_job` + shared sandbox** default.

---

## 3. `record_action/2` placement (REF-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Same worker + same txn | Audited rows + `record_action` | ✓ |
| HTTP-only `record_action` | Splits from job story | |
| Job action-only (no row change) | Under-teaches capture | |

**Research highlights:** Phoenix idioms = **thin worker**, **fat context**; pedagogy = **one story** “command → facts + intent”; footgun = **`record_action` outside** transaction that holds GUC if capture actor must align (document ordering).

**User's choice:** Synthesized — **same worker**, **`job_id` merged from `%Oban.Job{}`**, README **“Semantics in jobs”** subsection.

---

## 4. README adoption pointers (REF-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Single “Operating in production” block | Low nav cost | ✓ (acceptable) |
| Split Production vs Adoption | Clearer roles | ✓ (either per **D-15**) |
| Thin links only | Lowest drift | ✓ |

**Research highlights:** Strong OSS (Oban, Phoenix) keeps **README = orientation**, **guides = obligations**; avoid maintainer **certification** tone; use **integrator-active** voice for STG.

**User's choice:** Synthesized — **two relative guide links + one integrator-owned sentence**.

---

## Claude's Discretion

- Worker naming, field mutated on **`posts`**, Oban minor config details (**24-CONTEXT.md**).

## Deferred Ideas

- HTTP route that enqueues Oban jobs — deferred (see **24-CONTEXT.md** `<deferred>`).
