# Adoption evidence playbook

Use this playbook when you need **CI-class** confidence that Threadline works end-to-end before a real host pilot. It links the evaluator ladder, the help-desk demo app, automated proofs, and host-owned STG templates.

This is **not** a substitute for integrator-owned staging evidence. See [evaluating-threadline.md](evaluating-threadline.md) for the CI-class vs host-class boundary.

## Quick ladder

1. **Contributor gate** — from repo root with Postgres up:

   ```bash
   DB_PORT=5433 MIX_ENV=test mix ci.all
   ```

2. **Hex install smoke** — `mix verify.hex_evaluator` (depends on `{:threadline, "~> 0.6"}` from hex.pm, not a path dep).

3. **Reference app (ConnCase)** — `mix verify.example` runs `examples/threadline_phoenix` tests including:
   - `walkthrough_happy_path_test.exs` — WALKTHROUGH §1–§4
   - `walkthrough_evidence_test.exs` — WALKTHROUGH §5
   - `track_a_golden_path_test.exs` — first audited write without `demo.seed`
   - `threadline_evidence_show_example_test.exs` — `mix threadline.evidence.show` on seeded fiction

4. **Browser gaps (optional)** — `mix verify.example_browser` runs Playwright against `mix phx.server` + `mix demo.seed` fiction.

## Demo app tracks

Canonical app: [`examples/threadline_phoenix/`](../examples/threadline_phoenix/).

| Track | Audience | Requires `mix demo.seed`? | Proof |
|-------|----------|---------------------------|-------|
| **A** | First audited write on migrated DB | **No** | `track_a_golden_path_test.exs`, README Track A |
| **B** | Maintainer walk / operator surface | **Yes** | [WALKTHROUGH.md](../examples/threadline_phoenix/WALKTHROUGH.md), walkthrough `*_test.exs` |

**Tour in five minutes (Track B):**

```bash
cd examples/threadline_phoenix
mix setup
mix demo.seed
mix phx.server
```

Then sign in as `admin@example.com` / `password123456` (see [DEMO_USERS.md](../examples/threadline_phoenix/DEMO_USERS.md)) and open:

- `/audit` — timeline + correlation filter (`walk-acme-4521-close`)
- `/audit/evidence` — retention_run, redaction_policy, trigger_coverage rows
- `/audit/policy/redaction` — drift posture (admin)
- `/audit/coverage` — trigger coverage dashboard (admin)

Recover drift with `mix demo.reset`.

## Host pilot templates (integrator-owned)

When you move beyond CI-class proof, copy scaffolds from [adoption-pilot-backlog.md](adoption-pilot-backlog.md):

- **`STG-HOST-TOPOLOGY-TEMPLATE`** — app → pooler → Postgres chain
- **`STG-AUDITED-PATH-RUBRIC`** — HTTP + job paths with OK / Issue / N/A / Not run

Fill these in **your** repo or fork. Maintainers review modesty and redaction only.

## What this playbook does not claim

- Production topology in your environment
- Your auth/tenancy model
- Legal/compliance sign-off
- External pilot outcomes (see v1.28 signal-gated pilot pack in `.planning/threads/2026-05-29-v1.28-pilot-readiness.md`)

## Related docs

- [evaluating-threadline.md](evaluating-threadline.md) — evaluator mental model
- [getting-started-saas.md](getting-started-saas.md) — wire Threadline into your app
- [operator-surface.md](operator-surface.md) — `/audit` mount contract
- [production-checklist.md](production-checklist.md) — host checklist shape
