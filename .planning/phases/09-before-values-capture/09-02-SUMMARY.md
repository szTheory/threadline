---
phase: 09-before-values-capture
plan: "02"
subsystem: database
tags: [ecto, postgres, exunit, readme]

key-files:
  created:
    - test/threadline/capture/trigger_changed_from_test.exs
  modified:
    - lib/threadline/capture/audit_change.ex
    - lib/threadline/query.ex
    - lib/threadline.ex
    - test/threadline/query_test.exs
    - README.md

key-decisions:
  - "`Query.history/3` stays a plain `repo.all/2` on `AuditChange` with no narrowing `select`."
  - "BVAL-02 covered by `query_test` row load plus `Threadline.history/3` documentation."

requirements-completed: [BVAL-01, BVAL-02]

duration: —
completed: 2026-04-23
---

# Phase 9 — Plan 09-02 summary

**Ecto and API surface now carry `changed_from`; integration tests and README document the opt-in capture path.**

## Accomplishments

- `AuditChange` schema and changeset include `:changed_from`.
- `history/3` documentation states full-row loading including `changed_from`.
- `trigger_changed_from_test.exs` covers global off, per-table on, `--except-columns` behavior, and INSERT/DELETE nulls.
- README subsection documents fresh install, `ALTER TABLE`, and exact Mix flag spellings.

## Task commits

Delivered with plan 09-02 scope in repository history (`feat(09-02)`).

## Self-Check: PASSED

- `MIX_ENV=test mix compile` — PASS.
- Full `mix ci.all` — NOT RUN here (PostgreSQL required); mandatory before merge.

## Deviations

- None.
