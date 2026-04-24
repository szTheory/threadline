---
phase: 30-retention-at-scale-discovery
status: human_needed
verified: 2026-04-24
---

# Phase 30 verification

## Goal (from roadmap)

**SCALE-01 / SCALE-02:** Retention-at-scale operator narrative in **`guides/production-checklist.md`**, plus README + **`guides/domain-reference.md`** discovery for v1.9 at-scale material.

## must_haves (from plans)

| Item | Evidence |
|------|----------|
| SCALE-01 — §4 H3 + API names + cadence/monitoring | `guides/production-checklist.md` — `### Volume, growth, and purge cadence` inside `## 4. Retention and purge`; literals `Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`; link `domain-reference.md#retention-phase-13` |
| SCALE-01 — §5 export hook | Same file under `## 5. Export and investigation` — bullet tying `:from`/`:to`, `max_rows`, `Threadline.Export.stream_changes/2`, correlation to retained data + `domain-reference.md#export-phase-14` |
| SCALE-01 — support intro | `## Support incident queries` — sentence with `#4-retention-and-purge` |
| SCALE-02 — domain hub | `guides/domain-reference.md` — `## Operating at scale (v1.9+)`, links to `#telemetry-operator-reference`, `#trigger-coverage-operational`, `audit-indexing.md`, `production-checklist.md#4-retention-and-purge` |
| SCALE-02 — README | `README.md` — paragraph after `## Maintainer checks` with `guides/domain-reference.md` and **Operating at scale (v1.9+)** |

## Automated checks

- `mix format` — executed
- `mix compile --warnings-as-errors` — **passed**
- Plan acceptance greps from **30-01-PLAN.md** and **30-02-PLAN.md** — **passed**
- **`mix test`** — **not executed** (PostgreSQL `threadline_test` not provisioned in verifier environment)

## human_verification

1. **Full test suite** — With Postgres available per `config/test.exs`, run **`mix test`** (or project parity gate **`DB_PORT=5433 MIX_ENV=test mix ci.all`**). Doc-only diff is expected to be green; this confirms doc-contract modules and integration tests still pass.

## Gaps

None against plan must_haves; automated suite confirmation awaits the human step above.
