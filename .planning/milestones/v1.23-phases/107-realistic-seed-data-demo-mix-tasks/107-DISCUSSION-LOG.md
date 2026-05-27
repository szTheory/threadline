# Phase 107: Realistic Seed Data + Demo Mix Tasks - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 107 — Realistic Seed Data + Demo Mix Tasks
**Areas discussed:** All six gray areas (research synthesis; user requested cohesive recommendations without per-option interview)

---

## 1. Walkthrough contract timing

| Option | Description | Selected |
|--------|-------------|----------|
| A — Locked `DEMO-MANIFEST.md` + `Demo.Manifest` in 107; Phase 108 follows | Manifest is SSOT for literals; contract-tested | ✓ |
| B — Seed fiction now; Phase 108 retrofits script | Fast but breaks SEED-03, redaction, Tuesday filters | |
| C — Minimal checklist in CONTEXT only | Subjective SEED-03; no machine check | |

**User's choice:** Option A (via research synthesis — “create context”)
**Notes:** Extends Phase 105 D-01c (Acme + 4521). `demo_epoch` + `demo_last_tuesday` required. Phase 108 writes WALKTHROUGH from manifest, validates against DB.

---

## 2. Sigra login personas

| Option | Description | Selected |
|--------|-------------|----------|
| A — Seeded demo accounts only | Full walkthrough login; no register proof | |
| B — Fixture user_ids; register only | Orphan IDs; no backdated history | |
| C — Hybrid: seeded personas + fresh register for WALK-01 | Matches Phase 106 D-106-01e | ✓ |

**User's choice:** Option C
**Notes:** `DEMO_USERS.md` with dev-only password banner. `Accounts.register_user` + confirm. Explicit `slug:` on provision.

---

## 3. `demo.reset` blast radius

| Option | Description | Selected |
|--------|-------------|----------|
| A — `mix ecto.reset` default | Wipes Sigra sessions; slow daily loop | |
| B — `TRUNCATE CASCADE` + `demo.seed` | Rails `db:seed:replant` analogue | ✓ |
| C — Audited tables only subset | Orphan state risk | |

**User's choice:** Option B; `ecto.reset` as escape hatch
**Notes:** Shared `@demo_tables` with help_desk_audit_test. Fixed UUIDs for session survival. SEED-04 wording: post-migrate equivalent state, not mandatory drop.

---

## 4. Activity synthesis path

| Option | Description | Selected |
|--------|-------------|----------|
| A — All context writes | Best audit; slow; still needs timestamp pass | |
| B — Bulk domain insert only | Wrong `/audit` timelines | |
| C — Hybrid: anchors + GUC filler + audit timestamp backfill | | ✓ |

**User's choice:** Option C
**Notes:** `:rand.seed` for filler only. No `insert_all` into `audit_*`. New `delete_reply/3` for SEED-05 anchor.

---

## 5. Delete incident planting (SEED-05)

| Dimension | Choice | Selected |
|-----------|--------|----------|
| Action atom | Hard DELETE only; defer `:ticket_reply_deleted` | ✓ |
| Time | Fixed `:demo_epoch` + manifest UTC | ✓ |
| Deleter vs closer | Distinct personas; delete on ticket ≠ 4521 | ✓ |

**User's choice:** As above
**Notes:** Phase 108 should add fourth operator incident for delete. Redaction via prior row_history, not delete row.

---

## 6. Org Y offboard / retention seed

| Option | Description | Selected |
|--------|-------------|----------|
| A — Post-purge end state in seed | Evidence + empty org Y audit | ✓ |
| B — Pre-purge; live purge in walkthrough | Non-deterministic; risks Acme data | |
| C — Placeholder docs only | Fails SEED-03 | |

**User's choice:** Option A
**Notes:** `Retention.purge` + `Evidence.record_retention_run` in `demo.seed`. Global purge; org scope in evidence `detail` only.

---

## Claude's Discretion

Listed in CONTEXT.md § Claude's Discretion (exact emails, third org name, `--full` flag, `audit_events` truncate).

## Deferred Ideas

Captured in CONTEXT.md `<deferred>` (soft-delete, per-org purge in lib, live purge as WALK-03 proof, bulk audit insert_all).
