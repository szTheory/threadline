---
phase: 30-retention-at-scale-discovery
status: clean
reviewed: 2026-04-24
---

# Phase 30 code review (advisory)

## Scope

- `guides/production-checklist.md` — SCALE-01 volume H3, §5 retention hook, support intro
- `guides/domain-reference.md` — SCALE-02 **Operating at scale (v1.9+)** hub
- `README.md` — Maintainer-band discovery paragraph

## Findings

- **Accuracy:** Retention API names and options match `Threadline.Retention.purge/1` @spec and `Mix.Tasks.Threadline.Retention.Purge` moduledoc; `{:error, :disabled}` called out. Export/support wording defers join semantics to domain-reference (D-3).
- **Safety:** Purge prose preserves destructive gates (`enabled: true`, `--dry-run`, prod `--execute`); no new operational commands invented.
- **Navigation:** Hub is links + short orientation only (no telemetry matrices or DDL). Stable fragment `operating-at-scale-v19` via explicit HTML id.

## Recommendation

Ship as-is after local **`mix test`** when Postgres is available.
