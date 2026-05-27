---
id: SEED-001
status: shipped
planted: 2026-05-27
planted_during: milestone-next-step assessment (pre-v1.24 kickoff)
shipped_in: v1.24 — Audited Write Path & Adopter Truth, Phases 111-112
trigger_when: v1.24 planning starts OR first external adopter reports correlation/timeline gaps from missing action_id linkage
scope: Medium
milestone: v1.24
---

# SEED-001: Audited write-path transaction helper

Package `set_config('threadline.actor_ref', …)` + domain writes + `Threadline.record_action/2` + `audit_transactions.action_id` linkage into one documented `Repo`-scoped helper (e.g. `Threadline.Audit.transaction/2`).

## Why This Matters

Every guide and the example app repeat the same manual transaction recipe. Correlation-filtered timeline/export **requires** `action_id` in the same DB transaction — the #1 adoption foot-gun for Phoenix SaaS integrators. A library helper makes "correct by default" match "easy by default" without collapsing capture and semantics models.

## When to Surface

- v1.24 milestone planning (primary)
- External pilot hits "timeline empty for correlation_id" despite headers set

## Non-goals

- Does not automate host auth or tenancy
- Does not replace `Threadline.Plug` / `Threadline.Job` context assignment
- Does not add new Evidence subjects or compliance workflow
