---
phase: 107-realistic-seed-data-demo-mix-tasks
status: passed
verified: 2026-05-27
score: 26/26
---

# Phase 107 Verification Report

**Phase goal:** Ship `mix demo.seed` and `mix demo.reset` Mix tasks that produce deterministic, ~3-organization × 5-agent × 50-ticket two-week activity so every Phase 108 walkthrough scenario has a real on-disk answer before the walkthrough runs.

**Status:** passed

## Must-Have Verification

### Plan 107-01 — Manifest contract

| # | Must-have | Status | Evidence |
|---|-----------|--------|----------|
| 1 | `DEMO-MANIFEST.md` lists acme, #4521, #4518, offboarded-co, demo_epoch, demo_last_tuesday | ✓ | `DEMO-MANIFEST.md` temporal + org + hero tables |
| 2 | `Demo.Manifest` exposes `epoch/0` and hero UUID accessors | ✓ | `lib/threadline_phoenix/demo/manifest.ex` — `epoch/0`, `org_id/1`, `ticket_number/1`, `user_id/1` |
| 3 | `dev.exs` sets `:demo_epoch` and `:demo_seed_password` | ✓ | `config/dev.exs` lines 101–102; `config/test.exs` mirrors for tests |
| 4 | Artifact: `DEMO-MANIFEST.md` | ✓ | Present; cross-links `DEMO_USERS.md` |
| 5 | Artifact: `demo/manifest.ex` | ✓ | `@hero_close_number 4521`, `@hero_delete_number 4518`; no `DateTime.utc_now/0` in `demo/` tree |

### Plan 107-02 — Reset + delete path

| # | Must-have | Status | Evidence |
|---|-----------|--------|----------|
| 6 | `HelpDesk.delete_reply/3` hard delete with actor GUC and org meta | ✓ | `help_desk.ex` `delete_reply/3`; audit test + contract test |
| 7 | `Demo.Tables.truncate_sql/0` shared with audit tests | ✓ | `demo/tables.ex`; `help_desk_audit_test.exs` imports it |
| 8 | `mix demo.reset` truncates demo tables; prod blocked without `DEMO_ALLOW_RESET=1` | ✓ | `demo_reset_test.exs` (truncate + reseed + prod `System.cmd`) |
| 9 | Artifact: `lib/mix/tasks/demo.reset.ex` | ✓ | `@shortdoc` documents canonical recovery |
| 10 | Artifact: `delete_reply/3` on `help_desk.ex` | ✓ | No `record_action` for `:ticket_reply_deleted` (D-107-05d) |

### Plan 107-03 — Seed pipeline

| # | Must-have | Status | Evidence |
|---|-----------|--------|----------|
| 11 | `mix demo.seed` → 3 orgs, ~50 tickets/org, 14-day spread | ✓ | `Demo.Seed.run/0` pipeline; contract fingerprint `org_count == 3`, `acme_ticket_count >= 45` |
| 12 | Anchor #4521 close + masked internal note + correlation | ✓ | `seed/anchors.ex`; contract tests redaction + `ticket_replied_and_closed` |
| 13 | Anchor #4518 reply deleted by deleter ≠ closer | ✓ | `HelpDesk.delete_reply/3` in anchors; SEED-05 contract test |
| 14 | Filler uses per-ticket transactions without `record_action` | ✓ | `seed/filler.ex` — no `record_action` calls |
| 15 | Temporal backfill from manifest offsets | ✓ | `seed/temporal.ex`; delete tx at `last_tuesday + 2h` |
| 16 | Artifact: `lib/mix/tasks/demo.seed.ex` | ✓ | Separate from `priv/repo/seeds.exs`; prod guard matches reset |
| 17 | Artifact: `demo/seed.ex` orchestrator | ✓ | `:rand.seed(:exsss, {1, 2, 3})` then Personas → Anchors → Filler → Temporal → RetentionTail |

### Plan 107-04 — Retention tail + contracts

| # | Must-have | Status | Evidence |
|---|-----------|--------|----------|
| 18 | `offboarded-co` purged with retention evidence row | ✓ | `seed/retention_tail.ex`; contract test `list_subject_ref_history` + `org_y_audit_change_count == 0` |
| 19 | `demo_contract_test.exs` proves heroes, delete, redaction, idempotent reset | ✓ | 6 tests, 0 failures (2026-05-27) |
| 20 | README documents `mix demo.seed` / `mix demo.reset` | ✓ | `README.md` Demo walkthrough section; root `readme_doc_contract_test.exs` |
| 21 | Artifact: `demo_contract_test.exs` | ✓ | `@moduletag :demo_contract`, `async: false`, `unboxed_run` |
| 22 | Artifact: `README.md` demo section | ✓ | States `ecto.setup` does not run `demo.seed`; `ecto.reset` vs `demo.reset` distinction |

## Requirements Traceability

| ID | Plans | Status | Evidence |
|----|-------|--------|----------|
| SEED-01 | 107-03, 107-04 | ✓ | `lib/mix/tasks/demo.seed.ex` → `Demo.Seed.run/0`; `ecto.setup` alias unchanged (`mix.exs`); `priv/repo/seeds.exs` only inserts sample posts |
| SEED-02 | 107-03, 107-04 | ✓ | Fixed `:rand.seed`; `demo_contract_test` double-`Reset.run/0` semantic fingerprint stable |
| SEED-03 | 107-01, 107-03, 107-04 | ✓ | Manifest literals + DB heroes (#4521 closed, #4518, offboarded-co, globex); actions/redaction/correlation asserted in contract tests |
| SEED-04 | 107-02, 107-04 | ✓ | `Demo.Reset.run/0` truncate + `Seed.run/0`; README + reset tests (CONTEXT D-107-03: truncate+reseed, not `ecto.drop` every time) |
| SEED-05 | 107-02, 107-03, 107-04 | ✓ | `delete_reply/3` + seeded delete on #4518; audit `op == "delete"` with deleter `actor_ref` |

All five requirement IDs match `REQUIREMENTS.md` Phase 107 mapping (marked complete).

## ROADMAP Success Criteria

1. **`mix demo.seed` → ~3 orgs × ~5 agents × ~50 tickets, 14-day activity, deterministic** — **verified.** Pipeline + contract fingerprint; temporal module backdates audit rows (no `utc_now` in demo modules).
2. **`mix demo.reset` canonical recovery** — **verified.** Truncate + reseed; README and `demo_reset_test.exs`.
3. **Phase 108 literals findable (Acme #4521, internal note redaction, org Y)** — **verified.** `DEMO-MANIFEST.md` + contract tests; org Y evidence run `walk-retention-offboarded-co`.
4. **“Who deleted X?” planted record** — **verified.** SEED-05 contract on #4518 `ticket_replies` delete with deleter actor.
5. **Running `mix demo.seed` twice → same state** — **verified (semantic).** ROADMAP prose says “byte-identical”; CONTEXT D-107-07b and plan 04 specify **semantic fingerprint** (trigger UUIDs prevent byte parity). Double-`demo.reset` contract test is the enforced guarantee; bare double-seed without reset is not a documented operator path.

## Scope Guard

- Changes confined to `examples/threadline_phoenix/**` (+ root `readme_doc_contract_test.exs` assertion) — **verified** (plans 01–04 file lists; no `lib/threadline/**` edits in phase deliverables).
- `lib/threadline` read-only — **verified** (`Retention.purge`, `Evidence.*` called from example app only).

## Commands Re-Run (2026-05-27)

```bash
cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_manifest_test.exs \
  test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo_reset_test.exs \
  test/threadline_phoenix/help_desk_audit_test.exs
# 16 tests, 0 failures

cd examples/threadline_phoenix && mix test
# 48 tests, 0 failures

cd /Users/jon/projects/threadline && mix test test/threadline/readme_doc_contract_test.exs
# 16 tests, 0 failures

grep -q "4521" examples/threadline_phoenix/DEMO-MANIFEST.md && \
grep -q "mix demo.seed" examples/threadline_phoenix/README.md && \
grep -q "mix demo.reset" examples/threadline_phoenix/README.md
# exit 0
```

## Human Verification

**Optional (Phase 108):** After `mix demo.seed`, open `/audit` scoped to Acme and visually confirm timeline density (~50 tickets). Not required for Phase 107 closure — CI covers manifest heroes, delete attribution, redaction, reset idempotency, and org Y evidence (per `107-VALIDATION.md` Nyquist note).

## Non-Blocking Findings

| ID | Severity | Summary |
|----|----------|---------|
| NB-107-01 | warning | `mix verify.example` fails `--warnings-as-errors` on unused `import Ecto.Query` in `demo/seed/personas.ex` (example app `mix test` still passes) |
| NB-107-02 | info | ROADMAP success criterion #5 wording (“byte-identical”) differs from implemented semantic-fingerprint idempotency (CONTEXT override) |
| NB-107-03 | info | `SEED-04` in `REQUIREMENTS.md` mentions “drops + migrations”; implementation is truncate + `demo.seed` per D-107-03 — documented in README |

## Gaps

None against phase must-haves or SEED-01–SEED-05. Address NB-107-01 before relying on `mix verify.example` in CI for the example app.
