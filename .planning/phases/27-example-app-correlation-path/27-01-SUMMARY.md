---
phase: 27-example-app-correlation-path
plan: 01
subsystem: testing
tags: [threadline, phoenix, correlation, record_action, timeline]

requires: []
provides:
  - HTTP POST /api/posts path links capture transactions to semantic actions for strict :correlation_id filters
  - Integration test ThreadlinePhoenixWeb.PostsCorrelationPathTest under mix verify.example
  - README subsection documenting operator contract and export_json + jq
affects: []

tech-stack:
  added: []
  patterns:
    - "After record_action in the same Repo.transaction as audited writes, set audit_transactions.action_id via txid_current() so Threadline.Query strict correlation join matches"

key-files:
  created:
    - examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/blog.ex
    - examples/threadline_phoenix/README.md

key-decisions:
  - "Link capture using Repo.update_all on AuditTransaction where txid == fragment(\"txid_current()\") after a successful record_action, because Phase 25 timeline correlation requires audit_transactions.action_id."

patterns-established:
  - "Example-app HTTP create mirrors Oban path semantics (GUC → DML → record_action) and completes the linkage required for :correlation_id on timeline/export."

requirements-completed: [LOOP-03]

duration: 25min
completed: 2026-04-24
---

# Phase 27: Example app correlation path — Plan 01 summary

**LOOP-03 shipped:** the Phoenix example records **`post_created_via_api`** in the same transaction as the audited **`posts`** insert, links **`audit_transactions.action_id`**, and proves **`Threadline.timeline/2`** with **`:correlation_id`** via CI plus README cross-links.

## Performance

- **Tasks:** 3
- **Files touched:** 3

## Accomplishments

- **`Blog.create_post/2`** calls **`Threadline.record_action/2`** with **`correlation_id`**, **`request_id`**, actor, and repo; updates the capture transaction row for **`txid_current()`** so strict filters apply.
- **`PostsCorrelationPathTest`** exercises headers → HTTP 201 → non-empty timeline for the same correlation id.
- **README** adds the correlation/timeline/export contract, **`export_json`** NDJSON sample with **`jq`**, removes stale “future **`action_id`**” language, and points to the new test module by name.

## Task commits

1. **27-01-01** — `Blog.create_post/2` semantics + linkage — `b22ed34`
2. **27-01-02** — integration test — `86e32f3`
3. **27-01-03** — README updates — `f1bfa4d`

## Deviations

- Plan frontmatter **`files_modified`** did not list the **`AuditTransaction`** link step; it is required for **`Threadline.Query`** strict **` :correlation_id`** semantics (join on **`at.action_id == aa.id`**) and is implemented entirely in **`blog.ex`**.

## Verification

- `mix format`
- `mix compile --warnings-as-errors`
- `MIX_ENV=test DB_HOST=127.0.0.1 DB_PORT=5433 mix verify.example`
- `MIX_ENV=test DB_HOST=127.0.0.1 DB_PORT=5433 mix verify.doc_contract`

## Self-Check: PASSED

- Acceptance checks from **`27-01-PLAN.md`** satisfied for **`blog.ex`**, test module, and README.
