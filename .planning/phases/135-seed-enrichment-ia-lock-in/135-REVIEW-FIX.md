---
phase: 135-seed-enrichment-ia-lock-in
fixed_at: 2026-06-03T23:50:00Z
review_path: .planning/phases/135-seed-enrichment-ia-lock-in/135-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 135: Code Review Fix Report

**Fixed at:** 2026-06-03T23:50:00Z
**Source review:** `.planning/phases/135-seed-enrichment-ia-lock-in/135-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 7
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: `mix demo.reset && mix demo.seed` crashes — `current_audit_transaction_id!` raises on second seed run

**Files modified:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex`, `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex`, `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex`
**Commits:** `610361c`, `c24203d`
**Applied fix:**

The fix required two rounds. First, `seed_memberships` in `personas.ex` was updated to use a new nil-safe `current_audit_transaction_id/0` (added to `support.ex` using `Repo.one` instead of `Repo.one!`), guarding `put_timestamp` with `if tx_id`.

Second, during verification it was discovered that three variety pack stories in `anchors.ex` also crash on the second run:
- `seed_variety_membership_role_change`: membership already "support" on second run; guarded with `membership.role != "support"` check
- `seed_variety_zendesk_sync`: `on_conflict: :nothing` produces no DML on second run; switched to nil-safe `stamp_org_meta/1` (added to `support.ex`) + `current_audit_transaction_id/0` with nil guard on `put_timestamp`
- `seed_variety_anon_submission`: same `on_conflict: :nothing` pattern; same nil-safe fix applied

`mix demo.reset && mix demo.seed` now exits 0 (confirmed).

### test: CR-01 regression guard

**Files modified:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs`
**Commit:** `e7e4fbe`
**Applied fix:** Added a regression test in the "SEED-02 idempotency" describe block: `"Seed.run/0 twice in sequence (reset-then-seed) does not raise"` calls `Seed.run()` a second time in an `unboxed_run` context and asserts `:ok` is returned without error.

### CR-02: DEMO-MANIFEST.md documents "membership delete" but the seed performs a role UPDATE

**Files modified:** `examples/threadline_phoenix/DEMO-MANIFEST.md`
**Commit:** `708008e`
**Applied fix (fallback):** Corrected lines 68 and 104 in DEMO-MANIFEST.md to accurately describe the seeded operation. The preferred fix (implementing an in-window membership DELETE) was evaluated and rejected because it would violate the D-05 test invariant that asserts `in_window_count == 0` for `org_memberships`. The FALLBACK path was taken:

- Line 68 ("op filter — deletes only"): replaced "membership delete" with a clear note that the membership change is an UPDATE backdated outside the 24h window and not visible in the deletes filter
- Line 104 (trigger-backfill row): replaced "ticket/membership deletes" with accurate description: backfill correction UPDATE (ticket 5007, 2.75h ago) + ticket DELETE (ticket 5004, 5h ago); membership role change is epoch-backdated UPDATE (outside window)

### WR-01: Dead code — `anon_insert_tx_id_ref` / `make_ref()` left in production seed path

**Files modified:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex`
**Commit:** `28741a6`
**Applied fix:** Deleted both lines (`anon_insert_tx_id_ref = make_ref()` and `_ = anon_insert_tx_id_ref`) from `seed_variety_reply_delete/3`. Neither line served any purpose.

### WR-02: Misleading variable name `closer_agent_id` assigned from `support_agent.user_id`

**Files modified:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex`
**Commit:** `28741a6`
**Applied fix:** Renamed `closer_agent_id` to `support_agent_id` in `seed_variety_ticket_reopen/3` at the assignment site and the usage site (`Support.set_actor_guc!(support_agent_id)`). The variable derives from `support_agent.user_id`, not from the closer.

### IN-01: Vacuous `refute is_nil` assertions after `Repo.one!`

**Files modified:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs`
**Commit:** `e7e4fbe`
**Applied fix:** Removed both vacuous `refute is_nil` lines (after `Repo.one!` calls that already enforce presence by raising). The first was replaced with `assert action.name == "ticket_replied_and_closed"` — a meaningful field assertion. The second (after `reply_change`) was removed entirely since the encoded assertion below it is the meaningful check.

### IN-03: D-13 test does not assert INSERT count; manifest promises ≥5 in-window INSERTs

**Files modified:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs`
**Commit:** `e7e4fbe`
**Applied fix:** Extended the D-13 test from `for op <- ["update", "delete"]` to `for op <- ["insert", "update", "delete"]`. The test name was updated to "default 24h window contains ≥1 INSERT, ≥1 UPDATE, and ≥1 DELETE". The assertion and message pattern are unchanged.

## Verification Results

1. `mix demo.reset && mix demo.seed` — **EXIT 0** (CR-01 proof)
2. `mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs` — **20 tests, 0 failures**
3. `mix compile --warnings-as-errors` — **EXIT 0**
4. `mix format` — ran; out-of-scope files reverted with `git checkout --`
5. `git status --short` — **clean** (only untracked `.review-fix-recovery-pending.json` sentinel, removed during cleanup)

## Commit Log (all fix commits on `main`)

| Commit | Finding | Description |
|--------|---------|-------------|
| `610361c` | CR-01 | Guard seed_memberships against no-DML re-seed crash |
| `e7e4fbe` | CR-01 regression + IN-01 + IN-03 | Regression test + test improvements |
| `708008e` | CR-02 | Correct DEMO-MANIFEST membership operation descriptions |
| `28741a6` | WR-01 + WR-02 | Remove dead ref scaffolding and rename misleading variable |
| `c24203d` | CR-01 (variety pack) | Extend idempotency to variety pack no-DML stories |

---

_Fixed: 2026-06-03T23:50:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
