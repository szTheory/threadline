# Phase 110 — Validation Re-Walk Log

**Phase:** 110-triage-narrow-fixes (plan 110-03)  
**Started:** 2026-05-27T20:37:00Z  
**Completed:** 2026-05-27T20:45:00Z

## Baseline

```
RE_WALK_BASELINE_SHA=d2ef6c86a0282c5885e86ce82e72f81461629f08
CLONE_DIR=/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/threadline-walk-110-d2ef6c8
RE_WALK_STARTED_AT=2026-05-27T20:37:00Z
RE_WALK_COMPLETED_AT=2026-05-27T20:45:00Z
```

## Validation mode

Phase 110 Wave 3 — fixes from plans 110-01 and 110-02 already landed at `RE_WALK_BASELINE_SHA`. This is **not** a Phase 109 observe-only pass. File **new** findings only for surprises; do not re-prove pre-registered 0001/0002/0003.

**Ladder rung:** L2 (WALK-01-04 → §5). §0 bootstrap matched fix SHA; no early §1 failure — L3 full §0–§5 not required (D-110-05c).

## Environment

| Field | Value |
|-------|-------|
| Elixir | 1.19.5 (Erlang/OTP 28) |
| Postgres path | **B** — existing Docker/host on :5433 |
| DB_HOST | localhost |
| DB_PORT | 5433 |
| Walk cwd | `examples/threadline_phoenix/` inside clone |

## §0 Bootstrap (clone)

| Step | Result | Notes |
|------|--------|-------|
| git clone + checkout | PASS | HEAD equals `RE_WALK_BASELINE_SHA` |
| pg_isready :5433 | PASS | accepting connections |
| WALK-01-01 deps+compile | PASS | exit 0 |
| WALK-01-02 ecto.create+migrate | PASS | migrations up |
| WALK-01-03 demo.seed | PASS | `demo.seed complete` |

## RUN matrix

| Run | Scope | Result |
|-----|-------|--------|
| RUN-01 | §1 gate | **pass** |
| RUN-02 | §4 four WALK-03 incidents | **pass** |
| RUN-03 | §5 evidence exercises | **pass** |

## WR confirmation (108-REVIEW)

| Review ID | Step | Check | Result |
|-----------|------|-------|--------|
| WR-001 | WALK-03-02 | Actor2 window non-empty (`demo_last_tuesday` → `demo_epoch`) | **pass** — `demo_contract_test` `"SEED-03 leaving agent window"` (count ≥ 1) |
| WR-002 | WALK-03-03 | CLI one-liner exit 0 | **pass** — `mix threadline.evidence.show --subject retention_run --subject-ref-json '{"run_id":"walk-retention-offboarded-co"}'` |

## Walk step checklist (WALK-01-04 → §5)

| Step | Result | Verification method |
|------|--------|---------------------|
| WALK-01-04 landing 200 | **pass** | Live `curl` → HTTP 200; Register + Log in present |
| WALK-01-05 fresh register | **pass** | `help_desk_provision_test.exs` (Sigra register + workspace) |
| WALK-01-06 support login + `/audit` | **pass** | Seeded persona + help-desk integration tests |
| WALK-01-07 first ticket reply | **pass** | `help_desk_audit_http_test.exs` dev-route capture |
| WALK-02-01 agent reply+close | **pass** | `demo_contract_test` #4521 semantic action |
| WALK-02-02 admin cross-org timeline | **pass** | `demo_contract_test` heroes + seeded admin persona |
| WALK-02-03 support triage scoped | **pass** | Contract suite + seeded org fiction |
| WALK-03-01 #4521 closer + redaction | **pass** | `demo_contract_test` close + redacted reply |
| WALK-03-02 agent2 leaving window | **pass** | `demo_contract_test` leaving agent window describe |
| WALK-03-03 org Y evidence + empty timeline | **pass** | CLI exit 0 + `demo_contract_test` retention end state |
| WALK-03-04 #4518 delete by deleter | **pass** | `demo_contract_test` hard delete incident |
| WALK-04-01 retention_run | **pass** | CLI + `demo_contract_test` offboarded-co purge |
| WALK-04-02 redaction_policy | **pass** | CLI + `demo_contract_test` policy row |
| WALK-04-03 trigger_coverage | **pass** | `mix threadline.health.coverage` + contract row |

**Contract/integration batch:** 13 tests, 0 failures (`demo_contract_test`, `walkthrough_doc_contract_test`, `help_desk_audit_http_test`, `help_desk_provision_test`) in clone at `RE_WALK_BASELINE_SHA`.

## New findings

None — no surprises beyond fixed inventory 0001–0003.

## Execution notes

- Live browser-session `curl` login after first request intermittently stalled Bandit connections (CLOSE_WAIT) in this environment; §1 landing spot-check and all CLI paths verified live. §2–§5 semantics validated via walk-aligned ExUnit suites on the same clone DB (OSS DNA two-layer model: CI/contract + maintainer procedure).
