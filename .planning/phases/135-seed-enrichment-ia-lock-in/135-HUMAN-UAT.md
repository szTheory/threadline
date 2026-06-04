---
status: partial
phase: 135-seed-enrichment-ia-lock-in
source: [135-VERIFICATION.md]
started: 2026-06-03T22:00:00Z
updated: 2026-06-03T22:00:00Z
---

## Current Test

[awaiting human testing — browser/render confirmations]

> Note: these are operator-surface **render** confirmations. Phase 135 delivers the seed DATA + recipes + IA lock (all automated-verified, 4/4 must-haves). The per-screen render fixes these items exercise deliberately DEFER to phases 136–143, which will capture these exact screenshots. Reachability recipes are in `examples/threadline_phoenix/DEMO-MANIFEST.md` (`## State recipes`).

## Tests

### 1. In-window variety visible above the fold in Timeline
expected: After `mix demo.reset && mix demo.seed`, log in as `admin@example.com`, open `/audit/timeline` (default 24h window). At least one UPDATE row and one DELETE row are visible above the fold; non-human actor labels (service_account/zendesk-sync, job/oban-retention-purge, system/trigger-backfill, anonymous) appear in the actor column.
result: [pending]

### 2. Reply-edit rich diff + [REDACTED]
expected: Open the in-window reply-edit transaction (ticket 5001, ~1h ago). The `body` field shows a before→after diff; `internal_note_body` renders masked as `[REDACTED]`.
result: [pending]

### 3. Empty scoped Timeline for offboarded-co
expected: Log in as `support@offboarded-co.example.com`, open `/audit/timeline`. The scoped Timeline renders an honest empty state (not a crash).
result: [pending]

### 4. Permission-edge on admin-only Coverage
expected: Log in as `support@acme.example.com`, navigate to `/audit/coverage` (admin-only). Access is denied / unauthorized state renders (not a crash).
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
