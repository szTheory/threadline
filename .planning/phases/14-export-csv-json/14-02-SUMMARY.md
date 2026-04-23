---
phase: 14-export-csv-json
plan: "02"
subsystem: api
tags: [mix-task, docs, ex_doc]

requires:
  - phase: 14-01
    provides: Threadline.Export APIs
provides:
  - mix threadline.export
  - Threadline.export_csv/2 and export_json/2 delegators
  - README + domain guide + ExDoc groups
affects: [operators]

tech-stack:
  added: []
  patterns: ["Mix task delegates only to Export (no Ecto.Query in task)"]

key-files:
  created: [lib/mix/tasks/threadline.export.ex, test/mix/tasks/threadline/export_test.exs]
  modified: [lib/threadline.ex, README.md, guides/domain-reference.md, mix.exs, lib/threadline/query.ex, test/threadline/readme_doc_contract_test.exs]

key-decisions:
  - "Dry-run prints banner with Mix.env, repo, and count before any write."

requirements-completed: [EXPO-01, EXPO-02]

duration: 30min
completed: 2026-04-23
---

# Phase 14 — Plan 14-02 Summary

**Operators can discover export via Mix task, top-level delegators, and docs cross-linked from timeline workflows.**

## Accomplishments

- `Mix.Tasks.Threadline.Export` mirroring retention purge startup pattern.
- `Threadline.export_csv/2`, `Threadline.export_json/2`, ExDoc groups, README + domain guide updates.
- Mix task smoke test and readme contract assertion for `export` + `timeline`.

## Self-Check: PASSED

- `MIX_ENV=test mix help threadline.export` (after `mix compile`)
- `DB_PORT=5433 MIX_ENV=test mix test test/mix/tasks/threadline/export_test.exs test/threadline/readme_doc_contract_test.exs`
