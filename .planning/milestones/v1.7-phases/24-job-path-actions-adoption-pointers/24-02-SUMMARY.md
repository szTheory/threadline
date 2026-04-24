---
phase: 24
plan: 24-02
status: complete
---

# Plan 24-02 Summary: README — semantics in jobs + adoption doc links

## Outcome

- Extended **`examples/threadline_phoenix/README.md`** with **`## Semantics in jobs`** (capture vs `record_action/2`, `PostTouchWorker` / `Blog.touch_post_for_job/2`, link to **`Threadline.Job`** at `../../lib/threadline/job.ex`).
- Added **`## Documentation & production adoption`** with links to **`../../guides/production-checklist.md`** and **`../../guides/adoption-pilot-backlog.md`**, explicit integrator-owned staging/host evidence sentence, and a short note on optional future **`audit_transactions.action_id`** tightening.

## Verification

- README acceptance greps from plan
- `cd examples/threadline_phoenix && mix format`
- `MIX_ENV=test mix verify.example` from repository root
