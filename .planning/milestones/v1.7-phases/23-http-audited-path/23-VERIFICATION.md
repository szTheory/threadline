---
status: passed
phase: 23
verified: "2026-04-24"
---

# Phase 23 — Verification

## Automated

| Check | Result |
|-------|--------|
| `cd examples/threadline_phoenix && mix format` | Pass |
| `MIX_ENV=test DB_HOST=localhost DB_PORT=5433 mix verify.example` (repo root) | Pass — 5 tests, 0 failures |

## Requirements

- **REF-03:** `Threadline.Plug` on example `:api` pipeline; `POST /api/posts` performs audited insert via `Blog.create_post/2` inside `Repo.transaction` with transaction-local `threadline.actor_ref` GUC; `posts_audit_path_test.exs` proves `audit_changes` for `posts` joined to `AuditTransaction` with non-nil `actor_ref` matching the synthetic service account.

## must_haves (from 23-01-PLAN)

| Item | Evidence |
|------|----------|
| Router includes `plug Threadline.Plug` with `actor_fn:` | `router.ex` |
| `POST /api/posts` returns 201 JSON with title/slug | `PostController`, `PostJSON`, ConnCase test |
| `Blog.create_post/2` uses one `Repo.transaction` with GUC then insert | `blog.ex` |
| ConnCase asserts `AuditChange` for `posts` linked to `AuditTransaction` with actor | `posts_audit_path_test.exs` |

## Notes

- Local verification used Postgres on **`DB_PORT=5433`** (docker compose). CI typically provides `postgres` on `localhost` with the expected role.
