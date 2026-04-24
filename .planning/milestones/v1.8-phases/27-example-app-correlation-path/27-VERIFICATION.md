---
phase: 27
status: passed
verified: 2026-04-24
---

# Phase 27 verification — Example app correlation path

## Goal (from roadmap)

Deliver LOOP-03: example app demonstrates HTTP **`x-correlation-id`** through audited write, **`record_action`**, and retrieval with **`:correlation_id`** on **`Threadline.timeline/2`**, with README aligned.

## Must-haves (from 27-01-PLAN)

| Criterion | Evidence |
|-----------|----------|
| **`Blog.create_post/2`** calls **`record_action`** in same transaction as insert, with repo, actor, correlation/request ids | `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` — transaction wraps GUC, insert, **`Threadline.record_action(:post_created_via_api, …)`**, then **`AuditTransaction`** update via **`txid_current()`** |
| Integration test under **`mix verify.example`** | **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`** — HTTP POST with correlation header → **`Threadline.timeline`** non-empty |
| README operator contract, **`export_json`**, **`jq`**, cross-link test, REF-01 literals | `examples/threadline_phoenix/README.md` — new **Correlation** section; doc contract test passes |
| **`requirements_addressed: [LOOP-03]`** | Plan frontmatter + summary |

## Automated checks run

- `mix format`
- `mix compile --warnings-as-errors`
- `MIX_ENV=test DB_HOST=127.0.0.1 DB_PORT=5433 mix verify.example`
- `MIX_ENV=test DB_HOST=127.0.0.1 DB_PORT=5433 mix verify.doc_contract`

## Human verification

None required — behavior covered by integration test and doc contracts.

## Gaps

None.

## Score

**LOOP-03:** satisfied for scoped example-app slice (HTTP create path).
