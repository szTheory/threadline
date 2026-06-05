---
phase: 135-seed-enrichment-ia-lock-in
plan: "03"
subsystem: demo-seed
tags: [seed, demo, variety-pack, audit, in-window, op-mix, saved-view]
dependency_graph:
  requires: ["135-01"]
  provides: ["seed_variety_pack/1 in anchors.ex", "DELETE branch in filler.ex", "SavedView rows in exports.ex", "D-13 assertion in demo_contract_test.exs"]
  affects: ["demo seed pipeline", "Timeline 24h default window", "audit op diversity", "actor kind diversity"]
tech_stack:
  added: []
  patterns: ["four-step seed idiom (Repo.transaction + set_actor_guc! + stamp_org_meta! + current_audit_transaction_id! + put_timestamp)", "wall-clock-relative in-window timestamps", "deterministic rem(number, 10) op-mix branch"]
key_files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex
    - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
decisions:
  - "Membership role change backdated outside 24h window (D-05 compatible) — D-13's ≥1 UPDATE satisfied by ticket/ticket_replies in-window updates instead"
  - "agent2 used for membership role flip (guaranteed agent→support change so Ecto sends SQL UPDATE and trigger fires)"
  - "SavedView actor_ref uses type: :user (not :admin) to match what Timeline queries at mount"
metrics:
  duration: "8 minutes"
  completed_date: "2026-06-03"
  tasks: 3
  files_modified: 4
---

# Phase 135 Plan 03: In-Window Variety Pack + Filler DELETE Branch + SavedView Data Summary

Seed enrichment core deliverable: variety pack placing ~5 INSERT / 4 UPDATE / 2 DELETE in the default 24h Timeline window, a 10% DELETE branch in the filler corpus, SavedView data for admin, and a green D-13 assertion.

## One-liner

In-window variety pack with all non-human actor kinds (service_account/job/system/anonymous), ticket_replies rich before→after + [REDACTED] diff, corpus DELETE branch shifting op-mix to ~55/35/10, and 2 deterministic SavedView rows for admin actor_ref.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | seed_variety_pack/1 + D-13 assertion | 878f5e9 | anchors.ex, demo_contract_test.exs |
| 2 | Filler corpus DELETE branch (D-11) | 1ffd0ae | filler.ex |
| 3 | SavedView rows for admin (F-204) | 912919f | exports.ex |

## What Was Built

### Task 1: seed_variety_pack/1 (anchors.ex)

Added `seed_variety_pack/1` with 9 sub-functions implementing D-12 mutation stories:

1. **Reply edited** (`seed_variety_reply_edit`): service_account INSERT + user UPDATE on `ticket_replies` → rich before→after diff with `internal_note_body` [REDACTED] (D-12.1/D-14). 1h ago.
2. **Ticket reopened/re-triaged** (`seed_variety_ticket_reopen`): job/oban-retention-purge reopens ticket (status closed→open) + human reassignment UPDATE. 2h ago.
3. **Membership role change** (`seed_variety_membership_role_change`): system/trigger-backfill flips agent2 role from agent→support. Intentionally backdated 7 days past epoch (outside 24h window) to respect D-05 constraint.
4. **Reply hard-delete** (`seed_variety_reply_delete`): anonymous INSERT + user DELETE of ticket_replies row. 4h ago.
5. **Ticket delete** (`seed_variety_ticket_delete`): system/trigger-backfill deletes duplicate ticket. 5h ago.
6. **Zendesk sync INSERT** (`seed_variety_zendesk_sync`): service_account inbound ticket sync. 6h ago.
7. **Stale sweep** (`seed_variety_stale_sweep`): job/oban-retention-purge closes stale ticket. 3.5h ago.
8. **Backfill correction** (`seed_variety_backfill`): system/trigger-backfill marks ticket in_progress. 2.75h ago.
9. **Anonymous public form** (`seed_variety_anon_submission`): anonymous ticket submission INSERT. 5.5h ago.

D-13 assertion added to `demo_contract_test.exs` as `describe "D-13 in-window variety guarantee"` — asserts ≥1 update AND ≥1 delete in the 24h window.

### Task 2: Filler DELETE branch (filler.ex)

Changed `insert_filler_ticket/4` to use `status_roll = rem(number, 10)`:
- `0` (~10%): DELETE branch — INSERT ticket then `Repo.delete!` in same transaction
- `1..3` (~30-35%): closed UPDATE (existing behavior)
- else (~55-60%): in_progress UPDATE (existing behavior)

Corpus op-mix shifted from ~95% INSERT toward ~55/35/10. `Support.random_days_ago_timestamp()` preserved — filler stays epoch-relative.

### Task 3: SavedView rows (exports.ex)

Added 2 deterministic SavedView rows for admin actor_ref (`%ActorRef{type: :user, id: Manifest.user_id(:admin)}`):
- "Recent deletes" — filters: `%{"op" => "delete"}`
- "Closed this week" — filters: `%{"table" => "tickets", "status" => "closed"}`

Both seeded via `Repo.insert_all` with `on_conflict: {:replace, [...]}` and UUIDv5 IDs under `saved_view/` namespace. Render defers to Phase 139.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed passing `support_id` string instead of `support_agent` struct**
- **Found during:** Task 1 — first test run
- **Issue:** `seed_variety_pack/1` was passing `support_id` (string) where `seed_variety_membership_role_change/3` expected an `Agent` struct
- **Fix:** Changed `|> seed_variety_membership_role_change(acme, support_id)` to `|> seed_variety_membership_role_change(acme, support_agent)`
- **Files modified:** anchors.ex
- **Commit:** 878f5e9 (fixed inline before commit)

**2. [Rule 1 - Bug] Membership role change: no-op UPDATE when role already "support"**
- **Found during:** Task 1 — second test run
- **Issue:** Originally used `support_acme` user who already has "support" role. Ecto skips SQL UPDATE when no fields change → no trigger fires → `stamp_org_meta!` panics with "expected exactly one audit transaction, got 0"
- **Fix:** Switched to `agent2` who has "agent" role by default, guaranteeing a real role change
- **Files modified:** anchors.ex
- **Commit:** 878f5e9 (fixed inline before commit)

**3. [Rule 2 - Missing critical functionality] Membership role change moved outside 24h window**
- **Found during:** Task 1 — third test run
- **Issue:** The D-05 test asserts `in_window_count == 0` for org_memberships. Adding an in-window membership change broke this test. D-13's ≥1 UPDATE is already satisfied by ticket/ticket_replies in-window updates from stories 1-2.
- **Fix:** Backdated membership role change to `DateTime.add(Manifest.epoch(), -7, :day)` — outside 24h window
- **Files modified:** anchors.ex
- **Commit:** 878f5e9 (fixed inline before commit)

## Verification Results

- `mix test test/threadline_phoenix/demo_contract_test.exs` — **11 tests, 0 failures** ✓
- `grep -c "seed_variety_pack" anchors.ex` — **2** ✓
- `grep -c "Support.set_anonymous_actor_guc!" anchors.ex` — **2** ✓
- `grep -c "Manifest.actor_id" anchors.ex` — **7** (≥3 required) ✓
- `grep -c "Repo.delete!" filler.ex` — **1** ✓
- `grep -c "rem(number, 10)" filler.ex` — **2** ✓
- No `DateTime.utc_now` in filler.ex ✓
- `grep -c "SavedView" exports.ex` — **3** (≥2 required) ✓

## Known Stubs

None — all variety pack mutations produce real audit_changes. SavedView data is intentionally data-only (render defers to Phase 139 by design, not a stub).

## Self-Check: PASSED

All task files confirmed present. All 3 commits verified:
- 878f5e9: feat(135-03): seed_variety_pack/1 + D-13 assertion
- 1ffd0ae: feat(135-03): filler corpus DELETE branch
- 912919f: feat(135-03): SavedView rows for admin
