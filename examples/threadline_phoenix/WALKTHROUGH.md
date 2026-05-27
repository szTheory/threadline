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
| §4 Operator incidents | WALK-03 four playbooks | This section |
| §5 Evidence exercises | WALK-04 three exercises | Plan 05 |

---

## §1 Clean clone install

Run every command from **`examples/threadline_phoenix/`**. PostgreSQL must already be running and reachable before database steps.

#### Step WALK-01-01 — Dependencies and compile

**Operator question:** Is the example app compiled with current Hex deps?

**Prerequisites:** Elixir ~> 1.15, Erlang/OTP, clone checked out.

**Do:**

1. Install dependencies and compile:

   ```bash
   mix deps.get
   mix compile
   ```

   Shortcut equivalent: `mix setup` runs `deps.get`, `compile`, and `ecto.setup` — use only after you understand the explicit steps below; it does **not** load demo fiction.

**Expected outcome:**

- `mix compile` exits 0 with no warnings-as-errors failures
- `_build/` and `deps/` present

**Verify:** Optional — `MIX_ENV=test mix test --only demo_contract` after WALK-01-03.

**If different:** File a finding citing `WALK-01-01`; do not fix during Phase 109.

---

#### Step WALK-01-02 — Database create, Threadline schema, migrate

**Operator question:** Does a fresh database have Threadline capture, Sigra auth, and help-desk tables?

**Prerequisites:** WALK-01-01 complete; Postgres reachable.

**Do:**

1. Confirm Postgres is up:

   ```bash
   pg_isready -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}"
   ```

2. Create the application database (first time on this machine):

   ```bash
   mix ecto.create
   ```

3. Apply committed migrations (includes Threadline audit schema, help-desk tables, and Sigra auth):

   ```bash
   mix ecto.migrate
   ```

   On a **generator-fresh** skeleton only (not this committed checkout), you would also run `mix threadline.install`, `mix threadline.gen.triggers --tables posts`, and `mix sigra.install Accounts User users --no-live --no-organizations --no-passkeys --no-admin --yes` before migrate. This repo ships those migrations — skip generators on a normal clean clone.

**Expected outcome:**

- `mix ecto.migrate` exits 0
- Help-desk tables (`organizations`, `tickets`, `ticket_replies`, …) exist
- Threadline triggers installed on audited tables

**Verify:** Optional — `mix verify.threadline` coverage check passes.

**If different:** File a finding citing `WALK-01-02`; STOP if migrations fail — recovery may require `mix ecto.reset` then repeat from WALK-01-02.

---

#### Step WALK-01-03 — Load demo walkthrough fiction

**Operator question:** Does the database contain deterministic three-org help-desk activity for later scenarios?

**Prerequisites:** WALK-01-02 complete.

**Do:**

```bash
mix demo.seed
```

**Expected outcome:**

- Command exits 0
- ~3 organizations, ~5 agents per org, ~50 tickets per org with two-week backdated activity
- Hero tickets **#4521** (closed) and **#4518** (delete story) exist in org Acme
- Seeded evidence rows for retention and trigger coverage (see §5 in Plan 05)

**Verify:** Optional contract tests — `MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs` (heroes, redaction, reset idempotency).

**If different:** File a finding citing `WALK-01-03`; run `mix demo.reset` and retry once before STOP.

---

#### Step WALK-01-04 — Start server and confirm landing

**Operator question:** Does the reference app boot and show the walkthrough entry point?

**Prerequisites:** WALK-01-03 complete.

**Do:**

1. Start Phoenix:

   ```bash
   mix phx.server
   ```

2. Open **`http://localhost:4000`** in a browser.

**Expected outcome:**

- Server listens on port 4000 without crash
- Help-desk landing shows **ThreadlinePhoenix** heading with **Register** and **Log in** links when logged out
- No 500 on `/`

**Verify:** Human — page renders; optional smoke: `curl -sS -o /dev/null -w '%{http_code}' http://localhost:4000/` returns `200`.

**If different:** File a finding citing `WALK-01-04`; STOP if server cannot start.

### §1 Checkpoint

| Expected met? | Findings filed? | Blockers |
|---------------|-----------------|----------|
| ☐ WALK-01-01 compile green | ☐ | |
| ☐ WALK-01-02 migrate green | ☐ | |
| ☐ WALK-01-03 demo.seed green | ☐ | |
| ☐ WALK-01-04 localhost:4000 landing | ☐ | |

---

## §2 Onboarding

Sigra auth and help-desk provisioning prove the reference app's first-hour operator path. Credentials for seeded personas live in **Appendix A** — not `DEMO-MANIFEST.md` mid-run.

#### Step WALK-01-05 — Fresh registration

**Operator question:** Can a new user sign up and receive a help-desk workspace?

**Prerequisites:** WALK-01-04 complete; server running.

**Do:**

1. Open **`http://localhost:4000/users/register`**
2. Register with **any new email** (e.g. `walkthrough-new@example.com`) and password (minimum 12 characters)
3. Complete email confirmation via **`http://localhost:4000/dev/mailbox`** if prompted
4. Confirm you land signed in on **`http://localhost:4000/`** with an **Open audit surface** link

**Expected outcome:**

- Registration succeeds without 500
- New user has auto-provisioned help-desk organization membership (agent role)
- Home page shows signed-in email

**Verify:** Optional — `test/threadline_phoenix/help_desk_provision_test.exs` covers provisioning idempotency.

**If different:** File a finding citing `WALK-01-05`.

---

#### Step WALK-01-06 — Seeded support login

**Operator question:** Can a demo support persona log in with manifest credentials?

**Prerequisites:** WALK-01-05 complete or logged out.

**Do:**

1. Log out if still signed in (`POST /users/log_out` via UI or new session)
2. Open **`http://localhost:4000/users/log_in`**
3. Log in as **`support@acme.example.com`** / **`password123456`** (Appendix A)

**Expected outcome:**

- Login succeeds; session persists across reload
- Home shows signed-in support email
- **`http://localhost:4000/audit`** loads for support role (org-scoped read-only)

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit` | Support org-scoped timeline | table, time window | → `/audit/transactions/:id` |
| `/audit/actors/:kind/:id` | Support org-scoped actor history | actor, time window | → transaction drill-down |
| `/audit/rows/:table/:pk` | Support org-scoped row history | table, pk | as-of sub-view |

**Verify:** Human — `/audit` renders timeline without 403.

**If different:** File a finding citing `WALK-01-06`.

---

#### Step WALK-01-07 — First ticket reply (help-desk surface)

**Operator question:** Can support close a ticket through the help-desk dev surface with audit capture?

**Prerequisites:** WALK-01-06 — logged in as `support@acme.example.com`.

**Do:**

1. Pick an **open** Acme ticket from seeded data (any filler ticket not #4521 or #4518 — numbers in Appendix A)
2. Submit a reply+close via the dev help-desk route (browser devtools or `curl` with session cookie):

   ```bash
   # Replace TICKET_UUID and ORG_UUID from Appendix A open-ticket row
   curl -sS -X POST "http://localhost:4000/dev/help_desk/ticket_reply" \
     -H "content-type: application/json" \
     -b "your_session_cookie" \
     -d '{"organization_id":"ORG_UUID","ticket_id":"TICKET_UUID","body":"First walkthrough reply"}'
   ```

3. Note the returned **`audit_transaction_id`**

**Expected outcome:**

- HTTP 200 with JSON `audit_transaction_id`
- Ticket status becomes **closed** in help-desk data
- Audit transaction carries support user's `actor_ref` and org meta

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit/transactions/:id` | Org-scoped | transaction id from step 3 | row changes for `tickets` + `ticket_replies` |

**Verify:** Optional — `test/threadline_phoenix/help_desk_audit_http_test.exs` proves dev-route capture with Sigra session.

**If different:** File a finding citing `WALK-01-07`.

### §2 Checkpoint

| Expected met? | Findings filed? | Blockers |
|---------------|-----------------|----------|
| ☐ WALK-01-05 fresh register | ☐ | |
| ☐ WALK-01-06 seeded support login | ☐ | |
| ☐ WALK-01-07 first ticket reply captured | ☐ | |

---

## §3 Daily use

Daily operator flows use seeded personas and the mounted `/audit` surface. When prose says **"last Tuesday"**, use manifest anchor **`demo_last_tuesday`** = **`2026-05-20T14:30:00Z`** — not wall-clock-relative filters.

#### Step WALK-02-01 — Agent reply and close

**Operator question:** Can an agent persona reply and close a sample ticket with semantics linked?

**Prerequisites:** WALK-01-04 server running; demo seed loaded.

**Do:**

1. Log out; log in as **`closer@acme.example.com`** / **`password123456`**
2. Select an open Acme filler ticket (Appendix A)
3. POST to **`/dev/help_desk/ticket_reply`** with reply body and close (same shape as WALK-01-07)
4. Open **`http://localhost:4000/audit/transactions/{audit_transaction_id}`**

**Expected outcome:**

- Transaction shows updates on **`tickets`** and insert on **`ticket_replies`**
- Linked semantic action **`ticket_replied_and_closed`** present
- Actor matches closer persona

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit/transactions/:id` | Agent org-scoped | transaction id | row-level diff |
| `/audit` | Agent org-scoped | `table: tickets` | → transaction |

**Verify:** Optional — `demo_contract_test.exs` "ticket_replied_and_closed action on #4521 close transaction".

**If different:** File a finding citing `WALK-02-01`.

---

#### Step WALK-02-02 — Admin recent activity

**Operator question:** Can cross-org admin browse recent audit activity?

**Prerequisites:** Demo seed loaded.

**Do:**

1. Log out; log in as **`admin@example.com`** / **`password123456`**
2. Open **`http://localhost:4000/audit`**
3. Apply a time filter window including **`demo_last_tuesday`** (`2026-05-20T14:30:00Z`) through **`demo_epoch`** (`2026-05-27T12:00:00Z`) — values in Appendix A
4. Scan timeline for Acme help-desk table activity (`tickets`, `ticket_replies`)

**Expected outcome:**

- Admin sees **cross-org** timeline (not limited to one org slug)
- Recent seeded activity visible including hero close/delete windows
- Export and coverage/policy surfaces available to admin (may open `/audit/coverage`, `/audit/policy/redaction`)

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit` | Cross-org admin | `from`, `to`, `table`, `correlation_id` | → `/audit/transactions/:id` |
| `/audit/actors/:kind/:id` | Cross-org admin | actor ref, time window | actor history |
| `/audit/coverage` | Admin global | schema (optional) | trigger coverage buckets |
| `/audit/evidence` | Admin (when authorized) | subject, subject_ref | evidence detail |

**Verify:** Human — timeline lists multi-org rows; admin not 403 on `/audit`.

**If different:** File a finding citing `WALK-02-02`.

---

#### Step WALK-02-03 — Support triage

**Operator question:** Can org-scoped support triage tickets without cross-org leakage?

**Prerequisites:** Demo seed loaded.

**Do:**

1. Log out; log in as **`support@acme.example.com`** / **`password123456`**
2. Open **`http://localhost:4000/audit`**
3. Filter timeline to **`table: tickets`** for org Acme activity
4. Attempt to narrow to Globex-only ticket numbers (Appendix A) — confirm support scope excludes other orgs
5. Confirm export HTTP routes return **403** for support role

**Expected outcome:**

- Support sees **Acme-scoped** rows only on `/audit`
- Globex/offboarded-co hero rows not visible in support timeline
- Export affordances denied (HTTP 403 on direct export URL)

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit` | Support read-only, org-scoped | `table`, time window | → transaction (org-scoped) |
| `/audit/rows/tickets/:pk` | Support org-scoped | ticket pk | row history / as-of |

**Verify:** Human — no Globex org rows visible; export denied.

**If different:** File a finding citing `WALK-02-03`.

### §3 Checkpoint

| Expected met? | Findings filed? | Blockers |
|---------------|-----------------|----------|
| ☐ WALK-02-01 agent reply+close captured | ☐ | |
| ☐ WALK-02-02 admin cross-org timeline | ☐ | |
| ☐ WALK-02-03 support triage scoped | ☐ | |

---

## §4 Operator incidents

Four atomic incident playbooks — one manifest hero each. When prose says **"last Tuesday"**, use **`demo_last_tuesday`** = **`2026-05-20T14:30:00Z`** (Appendix A) — not wall-clock-relative filters.

Answers use only the shipped **`/audit`** operator surface and documented **`mix threadline.*`** CLI — no raw SQL, no IEx, no `Repo.all/2`.

#### Step WALK-03-01 — Who closed #4521 and what did the internal note say?

**Operator question:** Who closed ticket **#4521** in Acme last Tuesday, and was the internal note captured without leaking plaintext?

**Prerequisites:** WALK-01-03 demo seed loaded; server running. Log in as **`support@acme.example.com`** or **`admin@example.com`** / **`password123456`** (Appendix A).

**Do:**

1. Open **`http://localhost:4000/audit`**
2. Apply filter **`correlation_id: walk-acme-4521-close`**
3. Narrow time window to include **`demo_last_tuesday`** (`2026-05-20T14:30:00Z`) through **`demo_epoch`** (`2026-05-27T12:00:00Z`)
4. Open the matching transaction drill-down **`/audit/transactions/:id`**
5. Inspect row changes on **`tickets`** (status → closed) and **`ticket_replies`** (close reply insert)
6. Open row history for the close reply on **`/audit/rows/ticket_replies/:pk`** and confirm sensitive fields

**Expected outcome:**

- Transaction actor is **`closer@acme.example.com`** (not deleter or support)
- Semantic action **`ticket_replied_and_closed`** linked on the close transaction
- Hero ticket **#4521** shows **closed** status in help-desk context
- Internal note field on the close reply shows **`[REDACTED]`** in capture — never plaintext `WALKTHROUGH-INTERNAL-SECRET-4521`

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit` | Support org-scoped or admin cross-org | `correlation_id: walk-acme-4521-close`, `from`/`to` anchored to `2026-05-20T14:30:00Z` | → `/audit/transactions/:id` |
| `/audit/transactions/:id` | Org-scoped or admin | transaction id from timeline | row changes on `tickets`, `ticket_replies` |
| `/audit/rows/ticket_replies/:pk` | Org-scoped or admin | table pk from transaction | prior values / redaction on `body` or masked columns |

**Verify:** Optional — `demo_contract_test.exs` describes `"ticket_replied_and_closed action on #4521 close transaction"` and `"close reply insert is redacted on #4521"`.

**If different:** File a finding citing `WALK-03-01`; do not fix during Phase 109.

---

#### Step WALK-03-02 — Leaving agent activity window

**Operator question:** Agent **`agent2@acme.example.com`** is leaving — what did they touch in the last 24 hours before offboard?

**Prerequisites:** Demo seed loaded. Log in as **`admin@example.com`** / **`password123456`**.

**Do:**

1. Open **`http://localhost:4000/audit/actors/user/33123cc4-da21-5674-b030-e168cee90521`** (Appendix A — `agent2@acme.example.com` user id)
2. Set time window **last 24 hours** ending at **`demo_epoch`** (`2026-05-27T12:00:00Z`) — i.e. **`from`** = `2026-05-26T12:00:00Z`, **`to`** = `2026-05-27T12:00:00Z`
3. Alternatively: cross-org **`/audit`** timeline with actor filter for **`agent2@acme.example.com`** and the same window
4. Scan the actor history list for Acme help-desk tables (`tickets`, `ticket_replies`)

**Expected outcome:**

- Actor history lists seeded leaving-agent window activity (multiple ticket/reply mutations attributed to **`agent2@acme.example.com`**)
- Rows span Acme org only for this persona — not cross-org admin noise
- Each entry drill-downs to a transaction with **`agent2@acme.example.com`** as actor

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit/actors/user/:id` | Cross-org admin | user id `33123cc4-da21-5674-b030-e168cee90521`, 24h window ending `demo_epoch` | → `/audit/transactions/:id` |
| `/audit` | Cross-org admin | actor ref for `agent2@acme.example.com`, same time window | → transaction drill-down |

**Verify:** Human — actor history non-empty for the 24h window; actor email matches **`agent2@acme.example.com`**.

**If different:** File a finding citing `WALK-03-02`.

---

#### Step WALK-03-03 — Org Y retention purge proof

**Operator question:** Prove org **`offboarded-co`** was retention-purged after offboard — audit footprint gone but evidence row exists.

**Prerequisites:** Demo seed loaded (retention tail runs during `mix demo.seed`). Log in as **`admin@example.com`**.

**Do:**

1. Open **`http://localhost:4000/audit/evidence`**
2. Locate evidence subject **`retention_run`** with subject ref **`walk-retention-offboarded-co`**
3. Confirm summary status / narrative references org Y offboard
4. Open **`http://localhost:4000/audit`** and filter timeline to org **`offboarded-co`** activity (org slug / meta as available on mounted filters)
5. Optional CLI parity: `mix threadline.evidence.show retention_run --subject-ref walk-retention-offboarded-co` from `examples/threadline_phoenix/`

**Expected outcome:**

- Evidence record **`walk-retention-offboarded-co`** present with **`proven`**-grade retention purge narrative for **`offboarded-co`**
- Org Y scoped timeline on **`/audit`** is **empty** (negative check — no audit rows remain for offboarded org)
- No contradiction between evidence detail and empty operator timeline

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit/evidence` | Admin | subject `retention_run`, ref `walk-retention-offboarded-co` | evidence detail |
| `/audit` | Cross-org admin | org-scoped to `offboarded-co` / org UUID `93cba30e-e2d5-5d95-9c50-7023f4c3eda5` | should return no rows |

**Verify:** Optional — `demo_contract_test.exs` describes `"offboarded-co audit footprint purged with manifest retention evidence"`.

**If different:** File a finding citing `WALK-03-03`.

---

#### Step WALK-03-04 — Who deleted the reply on #4518?

**Operator question:** Who deleted the reply on ticket **#4518** in Acme last Tuesday, and what did the note contain before delete?

**Prerequisites:** Demo seed loaded. Log in as **`support@acme.example.com`** or **`admin@example.com`**.

**Do:**

1. Open **`http://localhost:4000/audit`**
2. Filter timeline to **`table: ticket_replies`** and time window including **`demo_last_tuesday`** (`2026-05-20T14:30:00Z`)
3. Locate **DELETE** operation on a reply row tied to hero ticket **#4518** (distinct from #4521 close story)
4. Open delete transaction **`/audit/transactions/:id`** — confirm actor **`deleter@acme.example.com`**
5. Open **prior row history** for the deleted reply pk on **`/audit/rows/ticket_replies/:pk`** — inspect state before delete
6. Confirm sensitive reply fields show masking where policy applies

**Expected outcome:**

- Delete transaction actor is **`deleter@acme.example.com`** — not **`closer@acme.example.com`**
- Hero ticket **#4518** delete story is separate from **#4521** close (different ticket, actor, and transaction)
- Prior row history shows the reply existed before delete with expected body content
- Sensitive fields in capture/history show **`[REDACTED]`** or policy masking — not leaked secrets

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit` | Support org-scoped or admin | `table: ticket_replies`, `from`/`to` including `2026-05-20T14:30:00Z`, op DELETE | → `/audit/transactions/:id` |
| `/audit/transactions/:id` | Org-scoped or admin | delete transaction id | actor = deleter |
| `/audit/rows/ticket_replies/:pk` | Org-scoped or admin | reply pk from delete change | prior row history / as-of before delete |

**Verify:** Optional — `demo_contract_test.exs` describes `"hard delete on ticket_replies for #4518 by deleter not closer"`.

**If different:** File a finding citing `WALK-03-04`.

### §4 Checkpoint

| Expected met? | Findings filed? | Blockers |
|---------------|-----------------|----------|
| ☐ WALK-03-01 #4521 closer + `[REDACTED]` note | ☐ | |
| ☐ WALK-03-02 agent2 24h actor window | ☐ | |
| ☐ WALK-03-03 org Y evidence + empty timeline | ☐ | |
| ☐ WALK-03-04 #4518 delete by deleter | ☐ | |
