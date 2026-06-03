---
phase: 135-seed-enrichment-ia-lock-in
reviewed: 2026-06-03T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex
  - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs
  - test/threadline/ia_lock_doc_contract_test.exs
  - examples/threadline_phoenix/DEMO-MANIFEST.md
findings:
  critical: 2
  warning: 2
  info: 3
  total: 7
status: issues_found
---

# Phase 135: Code Review Report

**Reviewed:** 2026-06-03
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 135 introduces the variety-pack seed cluster (D-11/D-12), non-human actor support across `set_actor_guc!`, SavedView seeding, and the IA lock-in doc contract tests. The determinism invariants (UUID v5 namespace, frozen epoch, PRNG seed at `seed.ex:16`) are correctly structured and not violated by this phase. The in-window variety timestamps appropriately use `DateTime.utc_now()` as intended.

Two blockers surfaced: the documented `mix demo.reset && mix demo.seed` chain will crash at `seed_memberships` because `Seed.run()` is not idempotent when memberships already exist, and the DEMO-MANIFEST.md describes a seeded operation ("membership delete") that the code does not perform.

---

## Critical Issues

### CR-01: `mix demo.reset && mix demo.seed` crashes — `current_audit_transaction_id!` raises on second seed run

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex:105-113` and `:128-136`

**Issue:** `seed_memberships/1` wraps each membership + agent upsert in a `Repo.transaction` and unconditionally calls `Support.current_audit_transaction_id!/0` at the end. That function queries `audit_transactions WHERE txid = txid_current()` using `Repo.one!`. On a second `Seed.run()` call (i.e., after `mix demo.reset` has already seeded data and `mix demo.seed` is run again per the documented one-command story), `ensure_membership!/3` and `ensure_agent!/3` both find existing rows and return them without any DB write. No DML fires, no audit trigger fires, no `audit_transaction` row is created for that `txid`. `Repo.one!` then raises `Ecto.NoResultsError`, crashing the seed.

The DEMO-MANIFEST states the canonical entrypoint is `mix demo.reset && mix demo.seed`. Because `mix demo.reset` internally calls `Demo.Seed.run()` after truncating, `mix demo.seed` runs Seed a second time on an already-populated database, hitting this crash.

**Fix:** Guard `current_audit_transaction_id!` calls with a check that at least one insert actually occurred. The cleanest approach is to return `nil` from a helper when no audit transaction exists for the current txid, then no-op in `put_timestamp` when `tx_id` is `nil`:

```elixir
# In seed_memberships, replace the unconditional call:
tx_id = Support.current_audit_transaction_id_if_exists()
# and only call put_timestamp when non-nil:
if tx_id, do: Support.put_timestamp(acc, tx_id, setup_ts), else: acc
```

Add to `Support`:
```elixir
def current_audit_transaction_id_if_exists do
  Repo.one(
    from(at in AuditTransaction,
      where: at.txid == fragment("txid_current()"),
      select: at.id
    )
  )
end
```

Alternatively, track whether an insert occurred inside the transaction and only call the id-retrieval if DML was performed.

---

### CR-02: DEMO-MANIFEST.md documents "membership delete" but the seed performs a role UPDATE

**File:** `examples/threadline_phoenix/DEMO-MANIFEST.md:68` and `:104`

**Issue:** Two rows in the State recipes table incorrectly describe the seeded operation on `org_memberships`:

- **Line 68** (op filter — deletes only row): `"Shows reply hard-delete, ticket delete, membership delete"` — the membership operation is a **role UPDATE** (`agent` → `support`), not a DELETE.
- **Line 104** (trigger-backfill named actor row): `"Backfill correction + ticket/membership deletes (2.75h ago, 5h ago)"` — again states "membership delete" when the code performs an UPDATE.

Additionally, the membership role change is backdated to `epoch - 7 days` (line 346 of `anchors.ex`), placing it outside the 24h Timeline window entirely. A walkthrough operator following the "op filter — deletes only" state recipe would not see a membership change at all — the manifest's description is doubly wrong (wrong operation type and wrong window presence).

This is a contract defect: the `DemoManifestContractTest` tests do not assert the operation type for the membership story, so no existing test catches this mismatch.

**Fix:** Update both lines in DEMO-MANIFEST.md to accurately describe what is seeded:

```markdown
# Line 68 — correct description:
| Timeline | op filter — deletes only | `admin@example.com` | `/audit/timeline?op=delete` | Shows reply hard-delete (ticket_replies), ticket delete (tickets); membership role change is UPDATE backdated outside window |

# Line 104 — correct description:
| `:system` | `trigger-backfill` | `:trigger_backfill` | Backfill correction UPDATE (ticket 5007, 2.75h ago) + ticket DELETE (ticket 5004, 5h ago); membership role change is epoch-backdated (outside window) |
```

---

## Warnings

### WR-01: Dead code — `anon_insert_tx_id_ref` / `make_ref()` left in production seed path

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex:358-359`

**Issue:** Two lines are development scaffolding that was never removed:

```elixir
anon_insert_tx_id_ref = make_ref()
_ = anon_insert_tx_id_ref
```

The `_ = ...` suppresses the "unused variable" compiler warning but the `make_ref()` call is entirely inert. This pattern signals an incomplete refactor — the variable name suggests a ref was intended to hold the anonymous insert's tx_id for some purpose that was abandoned.

**Fix:** Delete both lines. They are unreferenced and serve no purpose.

---

### WR-02: Misleading variable name `closer_agent_id` assigned from `support_agent.user_id`

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex:282`

**Issue:**

```elixir
closer_agent_id = to_string(support_agent.user_id)
```

The variable is named `closer_agent_id` but is derived from `support_agent`, not from the closer. It is then used at line 303 as the actor for the ticket reassignment step. A reader maintaining this file will expect `closer_agent_id` to identify the closer persona — the mismatch will cause confusion when tracing the walkthrough story (Story 2, ticket reopen/re-triage).

**Fix:** Rename to match the actual source:

```elixir
support_agent_id = to_string(support_agent.user_id)
# ...
Support.set_actor_guc!(support_agent_id)
```

---

## Info

### IN-01: Vacuous `refute is_nil` assertions after `Repo.one!`

**File:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:66` and `:97`

**Issue:** Both call sites fetch a result via `Repo.one!` and then immediately assert `refute is_nil(result)`. `Repo.one!` raises `Ecto.NoResultsError` when no rows match, so the bound variable can never be `nil` at the assertion site. The `refute is_nil` is never reachable as a meaningful check.

```elixir
action = Repo.one!(from a in AuditAction, ...)  # raises if nil
refute is_nil(action)                           # vacuous

reply_change = Repo.one!(from ac in AuditChange, ...)  # raises if nil
refute is_nil(reply_change)                            # vacuous
```

**Fix:** Remove both `refute is_nil` lines. If the intent is to assert presence of the queried row, `Repo.one!` already enforces that. If the intent is to assert a specific field value, assert the field directly.

---

### IN-02: Agent2 UUID hardcoded in test rather than derived from a shared constant

**File:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:109`

**Issue:**

```elixir
agent2_id = "33123cc4-da21-5674-b030-e168cee90521"
```

The UUID for agent2 is hardcoded as a string literal. This UUID is computed from the `threadline.demo` namespace and the name `"user/agent2@acme.example.com"` (matching the `@extra_personas` entry in `Personas`). `Manifest.user_id/1` does not accept `:agent2` (it is not in `@user_emails`), so a shared accessor does not currently exist.

If the email for agent2 in `@extra_personas` is ever changed, the test UUID silently drifts and the leaving-agent-window test would start failing (or silently pass on a count of 0 if the actor_ref filter no longer matches).

**Fix:** Expose the extra-persona UUID computation through `Manifest` or a test helper so the test and the seed stay in sync:

```elixir
# In Manifest (or a test support module):
def extra_user_id(email) do
  UUID.format(UUID.v5_binary(@demo_namespace_bin, "user/#{email}"))
end
```

Then in the test:
```elixir
agent2_id = ThreadlinePhoenix.Demo.Manifest.extra_user_id("agent2@acme.example.com")
```

---

### IN-03: D-13 test does not assert INSERT count; manifest promises ≥5 in-window INSERTs

**File:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:302-325`

**Issue:** The D-13 test asserts `≥1 UPDATE` and `≥1 DELETE` in the 24h window but does not assert `≥1 INSERT`. The DEMO-MANIFEST state recipes row for "default (op variety)" promises "5 INSERT / 4 UPDATE / 2 DELETE". A regression that broke in-window INSERT seeding (e.g., all zendesk-sync or anon-submission tickets already existing via `on_conflict: :nothing`) would go undetected.

**Fix:** Add an INSERT assertion alongside UPDATE and DELETE:

```elixir
for op <- ["insert", "update", "delete"] do
  count = Repo.one!(from ac in AuditChange, ...)
  assert count >= 1, "expected ≥1 #{op} in default 24h window, got #{count}"
end
```

---

_Reviewed: 2026-06-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
