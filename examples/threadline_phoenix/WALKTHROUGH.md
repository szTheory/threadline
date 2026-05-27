# WALKTHROUGH — Threadline Phoenix maintainer dry-run

> **Audience:** Maintainer executing the Phase 109 dry-run on a clean clone. This is **not** the integrator tutorial — see [`../../guides/getting-started-saas.md`](../../guides/getting-started-saas.md) for wiring Threadline into your own app.

## §0 Before you start

### Who this is for

You are a **maintainer** running the Phase 109 observe-only dry-run. Do not treat this document as `getting-started-saas.md`; that guide targets Phoenix integrators wiring Threadline into their own codebase.

### Prerequisites

- Elixir ~> 1.15 and matching Erlang/OTP
- PostgreSQL with trigger support, reachable before database tasks
- Repository cloned; all commands run from **`examples/threadline_phoenix/`**

Optional: from the repository root, `docker compose up -d postgres` publishes Postgres on port **5433** by default. Set `DB_HOST` / `DB_PORT` to match your environment.

### Recovery

If demo state drifts mid-walk, reset to a clean post-migrate seeded state:

```bash
mix demo.reset
```

### Phase 109 discipline

During the Phase 109 walkthrough run:

- **Observe only** — do not fix typos, code, or docs in-flight
- **Classify at capture** — assign (a/b/c/d) when filing each finding
- **File findings** using [`.planning/v1.23/findings/README.md`](../../.planning/v1.23/findings/README.md) and copy from `TEMPLATE.md`

Even obvious one-line fixes become numbered finding files. Phase 110 triages them.

### Walk literals during the run

**Appendix A** (added in Plan 05) holds all walk-critical literals — credentials, ticket numbers, time anchors, correlation IDs. **Do not open `DEMO-MANIFEST.md` mid-run**; use Appendix A instead.

### Sections in this runbook

| Section | Requirement | Status in this plan |
|---------|-------------|---------------------|
| §0 Before you start | Prerequisites + discipline | This section |
| §1 Clean clone install | WALK-01 bootstrap | Task 2 |
| §2 Onboarding | WALK-01 register + login + first reply | Task 2 |
| §3 Daily use | WALK-02 agent/admin/support flows | Task 2 |
| §4 Operator incidents | WALK-03 four playbooks | Plan 04 |
| §5 Evidence exercises | WALK-04 three exercises | Plan 05 |

---

## §1 Clean clone install

_(Filled in Task 2.)_

---

## §2 Onboarding

_(Filled in Task 2.)_

---

## §3 Daily use

_(Filled in Task 2.)_
