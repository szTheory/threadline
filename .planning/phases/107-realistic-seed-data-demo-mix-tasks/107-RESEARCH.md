# Phase 107: Realistic Seed Data + Demo Mix Tasks — Research

**Researched:** 2026-05-27  
**Phase:** 107-realistic-seed-data-demo-mix-tasks  
**Requirements:** SEED-01, SEED-02, SEED-03, SEED-04, SEED-05

## Summary

Phase 107 is greenfield under `examples/threadline_phoenix/`: no `mix demo.*` tasks exist yet. Capture and semantics patterns are proven in `HelpDesk.ticket_replied_and_closed/6` and the hard-delete test in `help_desk_audit_test.exs`. The main engineering work is a **manifest-driven seed pipeline** (frozen `demo_epoch`, fixed UUIDs, anchor context writes, filler transactions, audit timestamp backfill, org-Y retention tail) plus **`mix demo.reset`** using a shared `@demo_tables` list aligned with test truncate SQL.

**Primary recommendation:** Four-plan wave sequence — manifest contract → `delete_reply/3` + reset → seed runner → retention/evidence + contract tests.

---

## Standard Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| Mix tasks | `Mix.Task` in `lib/mix/tasks/demo.seed.ex`, `demo.reset.ex` | SEED-01; separate from `priv/repo/seeds.exs` |
| Implementation | `ThreadlinePhoenix.Demo.{Manifest, Tables, Seed, Reset}` | Keeps tasks thin |
| Auth users | `Accounts.register_user` + confirm (auth_fixtures pattern) | D-107-02a |
| Org/agent | Direct `Repo.insert` + `provision_default_workspace_for_user/2` with `slug:`/`name:` | Multi-org users need **explicit** membership/agent rows — provision is idempotent on **first** org only |
| Capture writes | `HelpDesk.ticket_replied_and_closed/6`, new `delete_reply/3` | No `insert_all` into `audit_*` |
| Filler volume | Per-ticket `Repo.transaction` + GUC + `update_all` meta | No `record_action` on filler |
| Timelines | Post-write SQL backfill on `occurred_at` / `captured_at` | Triggers use `clock_timestamp()` at insert |
| Retention story | `Threadline.Retention.purge/1` + `Evidence.record_*` | Global age cutoff; org Y narrative in evidence `detail` |
| Verification | `mix test` in example app + contract test module | Semantic fingerprint where UUIDs differ |

---

## Architecture Patterns

### Manifest as contract (D-107-01)

- `examples/threadline_phoenix/DEMO-MANIFEST.md` — human-readable literals for Phase 108
- `ThreadlinePhoenix.Demo.Manifest` — module attributes: `demo_epoch`, `demo_last_tuesday`, org/ticket/user UUIDs, correlation ids, evidence `run_id`s
- Accessors: `epoch/0`, `hero_ticket/1`, `org_uuid/1`, etc. — seed and tests import one module

### `:rand.seed(:exsss, {1, 2, 3})` at task start

Filler ticket bodies and non-hero assignees only. Heroes use deterministic UUID v5 or fixed binaries from manifest.

### `delete_reply/3` (new)

Mirror `help_desk_audit_test.exs` delete path:

1. `Repo.transaction`
2. `set_config('threadline.actor_ref', ...)`
3. `Repo.delete!(reply)`
4. `Repo.update_all` on `audit_transactions` where `txid = txid_current()` with org meta

Extract from inline test into `HelpDesk.delete_reply/3` for seed + reuse in contract test.

### `@demo_tables` / `Demo.Tables.truncate_sql/0`

Extend `help_desk_audit_test` list with `posts`, `oban_jobs`, optionally `audit_events`, `users` (only if reset clears Sigra users — **prefer truncating app tables + re-seed users** so `users` included in truncate list per D-107-03).

**Conflict:** Current test truncate omits `users`. Demo reset must clear help-desk + audit + posts; **also truncate `users` and related Sigra session tables** or re-seed overwrites by email. Research: include `users`, `users_tokens`, `audit_events` in `@demo_tables` for clean walkthrough loop.

### Temporal backfill

After all writes, single deterministic pass:

```sql
UPDATE audit_transactions SET occurred_at = $1 WHERE id = $2
```

and matching `audit_changes.captured_at` for rows in those transactions — offsets from manifest map keyed by incident id (e.g. `:acme_4521_close`, `:acme_4518_delete`).

Do **not** rely on `tickets.inserted_at` for `/audit` filters.

### Org Y (offboarded-co)

1. Seed org Y audit rows with `occurred_at` older than retention window (relative to `demo_epoch`)
2. Enable retention in `config/dev.exs` for seed task (`Application.put_env` in task or `config :threadline, retention: [enabled: true, ...]`)
3. `Threadline.Retention.purge(repo: Repo)` once
4. `Evidence.record_retention_run/3`, `record_retention_policy/3`, `record_trigger_coverage/3` with fixed subjects from manifest
5. End state: org Y scoped timeline empty; evidence row findable via `mix threadline.evidence.show`

### Multi-org memberships

`provision_default_workspace_for_user/2` returns existing org when **any** membership exists (`existing_membership_org/1`). For Acme agents who also appear in a third org:

- First org: `provision_default_workspace_for_user(user_id, slug: "acme", name: "Acme")`
- Additional orgs: `Repo.insert` on `OrgMembership` + `Agent` with manifest `user_id`

### Prod guard

Both tasks:

```elixir
if Mix.env() == :prod && System.get_env("DEMO_ALLOW_RESET") != "1" do
  Mix.raise("demo tasks are dev/test only...")
end
```

---

## Don't Hand-Roll

| Problem | Don't build | Use instead |
|---------|-------------|-------------|
| Audit capture | Raw `insert_all` into `audit_*` | Triggers via normal `Repo` writes |
| Walkthrough time | `DateTime.utc_now()` in seed | `Manifest.epoch/0` + offsets |
| Reset | `ecto.reset` as daily loop | `TRUNCATE ... CASCADE` + `demo.seed` |
| Delete semantics | Soft delete | Hard `Repo.delete!` (105 D-04) |
| Per-org retention | Custom purge in `lib/` | Global `Retention.purge/1` + evidence narrative |

---

## Common Pitfalls

1. **Sandbox / first-write capture** — Run seed and contract tests with `Ecto.Adapters.SQL.Sandbox.unboxed_run/2` when mixing fixture inserts with GUC writes (106 lesson).
2. **Single mega-transaction** — 50 tickets in one tx → one `txid`; breaks transaction-grouping demos.
3. **Byte-identical re-seed** — `gen_random_uuid()` on audit rows makes strict UUID equality flaky; prefer semantic contract tests (hero ticket numbers, action names, redaction markers).
4. **REQUIREMENTS.md SEED-04 wording** — Says "drops + migrations"; **CONTEXT D-107-03 overrides** to truncate + reseed (document in README).
5. **Internal note in walkthrough** — Seed masked notes; Phase 108 must not quote plaintext (CAP-03).

---

## Code References

| File | Relevance |
|------|-----------|
| `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` | Extend with `delete_reply/3` |
| `examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_test.exs` | Truncate SQL, close + delete patterns |
| `examples/threadline_phoenix/test/support/help_desk_fixtures.ex` | Template for deterministic attrs |
| `examples/threadline_phoenix/test/support/fixtures/auth_fixtures.ex` | `register_user` + confirm |
| `lib/threadline/retention.ex` | `purge/1` |
| `lib/threadline/evidence.ex` | `record_retention_run/3`, policy, coverage |
| `lib/mix/tasks/threadline.retention.purge.ex` | CLI reference for retention opts |

---

## Validation Architecture

| Requirement | Automated verify | Command / file |
|-------------|------------------|----------------|
| SEED-01 | mix task exists + runs | `cd examples/threadline_phoenix && mix demo.seed` |
| SEED-02 | contract test deterministic heroes | `mix test test/threadline_phoenix/demo_contract_test.exs` |
| SEED-03 | manifest heroes in DB | same contract test |
| SEED-04 | reset truncates + reseeds | `mix demo.reset` in test or script |
| SEED-05 | delete change row + distinct actor | contract test asserts `op == "delete"` on #4518 |

**Quick run:** `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs`  
**Full example suite:** `cd examples/threadline_phoenix && mix test`  
**Estimated runtime:** ~15–45s (DB-heavy)

---

## Plan Structure Recommendation

| Plan | Wave | Delivers |
|------|------|----------|
| 107-01 | 1 | Manifest module, DEMO-MANIFEST.md, DEMO_USERS.md, dev config keys |
| 107-02 | 2 | `delete_reply/3`, `Demo.Tables`, `mix demo.reset` |
| 107-03 | 3 | `mix demo.seed` — personas, anchors, filler, temporal backfill |
| 107-04 | 4 | Org Y retention tail, evidence rows, contract tests, README |

---

## RESEARCH COMPLETE
