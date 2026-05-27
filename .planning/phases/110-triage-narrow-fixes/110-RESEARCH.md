# Phase 110: Triage + Narrow Fixes — Research

**Researched:** 2026-05-27  
**Phase:** 110 — Triage + Narrow Fixes  
**Status:** Complete

## Summary

Phase 110 executes a **three-wave fix → validate** playbook on a minimal finding inventory (0001 filed; WR-001/WR-002 confirmed pre-registrations). Wave 1 unblocks the §1 gate (landing 500). Wave 2 files numbered findings 0002/0003 and applies **doc-only** fixes plus contract tests — no `lib/threadline/**` changes for current inventory. Wave 3 is a **validation re-walk** (not observe-only) on a fresh clone at `RE_WALK_BASELINE_SHA` post-Wave-2.

The nil-safe `@current_scope` guard in `PageHTML.home/1` is already present in the working tree; Wave 1 is primarily **commit + finding frontmatter + L0/L1 verification**, not greenfield implementation.

## Technical Findings

### Finding 0001 — landing BadMapError

| Item | Detail |
|------|--------|
| Root cause | Logged-out `GET /` renders `PageHTML.home/1` with `@current_scope` nil; template used map access without guard |
| Fix surface | `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/page_html.ex` only |
| Layer | Host app (Sigra scope wiring) — **not** capture/semantics `lib/threadline/` |
| L0 verify | `curl -sS -o /dev/null -w '%{http_code}' http://localhost:4000/` → `200` |

### WR-001 — WALK-03-02 time window (class c → finding 0003)

| Item | Detail |
|------|--------|
| Bug | Prose says 24h ending `demo_epoch` (`2026-05-26T12:00:00Z` … `2026-05-27T12:00:00Z`) |
| Seed truth | `seed_leaving_agent_window/1` stamps txs at `demo_last_tuesday + 1..12 min` (`2026-05-20T14:31:00Z` … `14:42:00Z`) |
| Fix | Align WALK-03-02 window to **`demo_last_tuesday` (`2026-05-20T14:30:00Z`) through `demo_epoch` (`2026-05-27T12:00:00Z`)** — match WALK-03-01 / §4 footnote pattern |
| Contract | Add `describe "SEED-03 leaving agent window"` in `demo_contract_test.exs` asserting ≥1 agent2 audit tx in documented bounds |

### WR-002 — WALK-03-03 CLI flags (class c → finding 0002)

| Item | Detail |
|------|--------|
| Bug | `mix threadline.evidence.show retention_run --subject-ref walk-retention-offboarded-co` — positional args rejected |
| Canonical | `mix threadline.evidence.show --subject retention_run --subject-ref-json '{"run_id":"walk-retention-offboarded-co"}'` (WALK-04-01) |
| Contract | Extend `walkthrough_doc_contract_test.exs` with `--subject retention_run` and `subject-ref-json` literals |

### IN-001 — §0 stale GSD labels (class b, in-budget)

Replace internal “Task 2 / Plan 05” labels in WALKTHROUGH §0 with maintainer-facing section names. Single file, ≤1 plan — fold into Wave 2 plan 110-02.

### Verification ladder (D-110-05)

| Rung | Command / artifact | When |
|------|---------------------|------|
| L0 | `curl` 200; CLI one-liner stderr clean | Per finding fix |
| L1 | `mix ci.all` (repo root) | Before plan complete |
| L2 | Isolated clone + `110-RE-WALK-LOG.md` WALK-01-04→§5 | Plan 110-03 |
| L3 | Full §0–§5 if bootstrap drift on fix SHA | If L2 fails early |

`mix verify.example` runs example-app tests including `demo_contract_test` and `walkthrough_doc_contract_test` (via `ci.all`).

### Deferrals (DEFER-01)

No **(d)** findings at phase start. Create `.planning/v1.24-seeds/` on first deferral per D-110-06a (`TEMPLATE.md`, `README.md`). Over-budget **(b)** → `kind: papercut_deferral` seed.

## Validation Architecture

Nyquist Dimension 8 — per-task automated verification map lives in `110-VALIDATION.md`.

| Property | Value |
|----------|-------|
| Framework | ExUnit (root + `examples/threadline_phoenix`) |
| Quick run | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/walkthrough_doc_contract_test.exs` |
| Full suite | `mix ci.all` (repo root) |
| Estimated quick runtime | ~30–90s (DB sandbox + demo reset) |

**Sampling:** L0 after each fix commit; L1 before marking plan complete; L2 manual re-walk in 110-03.

## Dependencies

- Phase 109 complete — finding 0001 + handoff in `109-SUMMARY.md`
- `108-REVIEW.md` — static repro for filing 0002/0003 without full §4 walk
- No schema migrations expected — **no blocking schema push** for this phase

## Risks

| Risk | Mitigation |
|------|------------|
| Pre-fixing WR before 0001 | Enforce wave order in plans (110-01 before 110-02) |
| Validation re-walk filed as observe-only | 110-03 scope_guard: validation mode, new surprises only |
| Silent `lib/` creep | D-110-04 layer-first gate; expect zero `lib/threadline` commits |

## RESEARCH COMPLETE
