---
phase: 23-http-audited-path
plan: "01"
subsystem: api
tags: [phoenix, threadline, plug, ecto, audit, conn_case]

requires:
  - phase: 22-example-app-layout-runbook
    provides: threadline_phoenix example app, verify.example, posts schema + triggers
provides:
  - HTTP POST /api/posts with Threadline.Plug and Blog.create_post/2 (GUC + transaction)
  - ConnCase proof posts_audit_path_test.exs
affects:
  - phase-24-oban-actions

tech-stack:
  added: []
  patterns:
    - "Transaction-local set_config('threadline.actor_ref', …, true) before audited Repo.insert"
    - "Threadline.Plug on :api pipeline; actor_fn returns synthetic service_account ref"

key-files:
  created:
    - examples/threadline_phoenix/lib/threadline_phoenix/blog.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_controller.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex
    - examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/error_json.ex
    - examples/threadline_phoenix/README.md

key-decisions:
  - "422 changeset errors return JSON via ErrorJSON.translate_changeset/1 from PostController"

patterns-established:
  - "Example AuditActor.from_conn/1 returns constant service_account; production replaces actor_fn"

requirements-completed: [REF-03]

duration: 25min
completed: 2026-04-24
---

# Phase 23: HTTP audited path — Plan 23-01 summary

**Example Phoenix API exposes POST /api/posts with Threadline.Plug, Repo.transaction-scoped GUC, and ConnCase proof that audit_changes link to audit_transactions carrying the service actor.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-04-24 (session)
- **Completed:** 2026-04-24
- **Tasks:** 4
- **Files modified:** 8 paths (5 new, 3 updated)

## Accomplishments

- `Blog.create_post/2` sets `threadline.actor_ref` with `set_config(..., true)` then inserts inside one `Repo.transaction/1`.
- `:api` pipeline runs `Threadline.Plug` with `AuditActor.from_conn/1`; `PostController` + `PostJSON` return 201 JSON.
- `posts_audit_path_test.exs` asserts `AuditChange` for `posts` joins `AuditTransaction` with expected `ActorRef`.
- README documents the path, canonical test file, production `actor_fn` note, and curl with `x-request-id`.

## Task commits

1. **Task 23-01-01 — Blog** — `29e5f03` (feat)
2. **Task 23-01-02 — Plug + HTTP** — `fb2f250` (feat)
3. **Task 23-01-03 — ConnCase test** — `0a920e5` (test)
4. **Task 23-01-04 — README** — `12f5e49` (docs)

## Files created/modified

- `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` — audited insert API
- `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` — synthetic actor
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — plug + route
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_controller.ex` — create action
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_json.ex` — JSON shape
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/error_json.ex` — `translate_changeset/1`
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` — REF-03 proof
- `examples/threadline_phoenix/README.md` — operator notes

## Decisions made

- Changeset errors use `ErrorJSON.translate_changeset/1` and `json/2` instead of a separate `render("422.json", …)` clause — keeps ErrorJSON as the single formatter for error maps.

## Deviations from plan

None — plan executed as written (router uses `post "/posts", …` to satisfy plan grep acceptance).

## Issues encountered

- Local `verify.example` on default `localhost:5432` failed (host Postgres role `postgres` missing); **`MIX_ENV=test DB_PORT=5433 mix verify.example`** against compose Postgres succeeded.

## Next phase readiness

- Phase 24 (Oban / `record_action`/ adoption links) can build on the same example app; no Oban code added here.

## Self-Check: PASSED

- Key files from `key-files.created` exist under `examples/threadline_phoenix/`.
- `git log --oneline --grep=23-01` shows task commits.
- Plan `<verification>`: `cd examples/threadline_phoenix && mix format`; `MIX_ENV=test DB_HOST=localhost DB_PORT=5433 mix verify.example` from repo root — **PASS** (5 tests, 0 failures).

---
*Phase: 23-http-audited-path*
*Completed: 2026-04-24*
