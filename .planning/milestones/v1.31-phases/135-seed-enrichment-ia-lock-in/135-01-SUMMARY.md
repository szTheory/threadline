---
phase: 135-seed-enrichment-ia-lock-in
plan: "01"
subsystem: demo-seed
tags: [actor-ref, demo-seed, d-05-fix, d-06, d-07, tdd]
dependency_graph:
  requires: []
  provides: [Support.set_actor_guc!/2, Support.set_anonymous_actor_guc!/0, Manifest.actor_id/1, D-05-fix]
  affects: [demo_contract_test, personas.ex, support.ex, manifest.ex]
tech_stack:
  added: []
  patterns: [Repo.transaction + set_actor_guc! + current_audit_transaction_id! + put_timestamp four-step idiom, Enum.reduce ctx threading, TDD RED/GREEN/REFACTOR]
key_files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex
    - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
decisions:
  - "D-07: set_actor_guc! accepts kind param defaulting to :user; set_anonymous_actor_guc!/0 handles :anonymous separately (no id)"
  - "D-05: seed_memberships rewritten as Enum.reduce threading ctx; each org's inserts wrapped in Repo.transaction with :admin actor + backdate 21d before epoch"
  - "D-06: Manifest.actor_id/1 stores bare actor ID strings; kind supplied at call site"
metrics:
  duration: "3m"
  completed: "2026-06-03T23:03:42Z"
  tasks_completed: 3
  files_changed: 4
---

# Phase 135 Plan 01: Generalize Actor Helpers + D-05 Fix + Named Actor Literals Summary

**One-liner:** Actor-kind-generalized GUC helpers (D-07), named non-human actor literals in Manifest (D-06), and D-05 root-cause fix giving persona/setup rows a real `:admin` actor backdated 21 days before epoch.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Generalize Support actor helpers to all ActorRef kinds (D-07) | 9fa676b | support.ex |
| 2 | Add named non-human actor literals to Manifest (D-06) | 37fd4de | manifest.ex |
| 3 (RED) | Add failing D-05 persona setup actor attribution tests | fe0962e | demo_contract_test.exs |
| 3 (GREEN) | Fix D-05 — persona/setup rows get :admin actor + backdate | 098e8a8 | personas.ex |
| style | Apply mix format to demo_contract_test.exs | 1051702 | demo_contract_test.exs |

## What Was Built

**Task 1 — Support helper generalization (D-07):**
- `set_actor_guc!/1` → `set_actor_guc!(actor_id, kind \\ :user)` with guard `kind in [:user, :admin, :service_account, :job, :system]`
- New `set_anonymous_actor_guc!/0` builds `ActorRef.new(:anonymous)` (no id) — `:anonymous` cannot share the `/2` path
- `audit_context/2` renamed param to `actor_id`, reads `kind: Keyword.get(opts, :kind, :user)` and calls `ActorRef.new(kind, actor_id)`
- All existing single-arg callers in anchors.ex and filler.ex continue to compile unchanged via `:user` default

**Task 2 — Named actor literals (D-06):**
- Module attributes: `@actor_zendesk_sync "zendesk-sync"`, `@actor_oban_retention_purge "oban-retention-purge"`, `@actor_trigger_backfill "trigger-backfill"`
- Accessor `Manifest.actor_id/1` for `:zendesk_sync`, `:oban_retention_purge`, `:trigger_backfill`
- Bare ID strings only; kind is supplied at `Support.set_actor_guc!(Manifest.actor_id(:zendesk_sync), :service_account)` call sites in Plan 03

**Task 3 — D-05 fix + contract test (TDD):**
- RED: two failing tests asserting (a) ≥1 org_memberships AuditChange has non-null `actor_ref` on its transaction, and (b) 0 org_memberships setup rows fall inside the default 24h window
- GREEN: `seed_memberships/1` rewritten from `Enum.each` to `Enum.reduce` threading `ctx`; each org's membership+agent inserts wrapped in `Repo.transaction` with `Support.set_actor_guc!(admin_id, :admin)`; `Support.current_audit_transaction_id!()` + `Support.put_timestamp(acc, tx_id, setup_ts)` with `setup_ts = DateTime.add(Manifest.epoch(), -21, :day)`
- `Support` alias added to personas.ex
- `DateTime.utc_now()` is absent from personas.ex (setup rows are epoch-backdated only)

## Verification

```
cd examples/threadline_phoenix && mix compile --warnings-as-errors   # exit 0
cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo_manifest_test.exs   # 15 tests, 0 failures
```

## Deviations from Plan

None — plan executed exactly as written.

The formatter (`mix format`) reformatted two existing `fragment/2` where-clauses in `demo_contract_test.exs` (pre-existing long lines, not introduced by this plan). Committed as a separate `style` commit to keep the diff honest.

## TDD Gate Compliance

- RED gate: commit `fe0962e` — `test(135-01): add failing D-05 persona setup actor attribution tests (RED)`
- GREEN gate: commit `098e8a8` — `feat(135-01): fix D-05 — persona/setup rows get :admin actor + backdate 21d before epoch (GREEN)`
- REFACTOR: no refactor needed; code is clean as written

## Known Stubs

None. All three changes are wired: Support helpers call `ActorRef.new` and the GUC query; Manifest attributes resolve at compile time; personas.ex actively uses them during seed.

## Threat Flags

None — no new runtime code paths, routes, auth logic, or production attack surface. All changes are demo seed code and one test.

## Self-Check: PASSED

- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex` — FOUND
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex` — FOUND
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex` — FOUND
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — FOUND
- commit 9fa676b — FOUND
- commit 37fd4de — FOUND
- commit fe0962e — FOUND
- commit 098e8a8 — FOUND
