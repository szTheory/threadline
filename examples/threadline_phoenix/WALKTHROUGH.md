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
| §5 Evidence exercises | WALK-04 three exercises | This section |

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
- Internal note field on the close reply shows **`[REDACTED]`** in capture — never plaintext internal-note secret text from seed data

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

---

## §5 Evidence plane exercises

Three evidence exercises prove the Threadline evidence plane using seeded rows from **`mix demo.seed`** and live viewer parity on `/audit/evidence`, `/audit/policy/redaction`, and `/audit/coverage`.

**Prerequisites:** WALK-01-03 complete — **`mix demo.seed`** must have run successfully. Org Y retention purge executes **during** `demo.seed` (RetentionTail tail); there is no separate live purge step in this walk. If state drifted, recover with **`mix demo.reset`**.

> **CLI footnote:** REQUIREMENTS and PROJECT prose may reference **`mix verify.evidence`**. The canonical viewer in this repo is **`mix threadline.evidence.show`** — use that command throughout this section.

> **Production sidebar (non-proof):** Hosts may run **`mix threadline.retention.purge --dry-run`** in production planning — that is optional prose only; org Y purge proof here comes from the seeded retention run, not a live purge during Phase 109.

Log in as **`admin@example.com`** / **`password123456`** (Appendix A) for all three exercises unless your mount restricts evidence routes.

Document these fields — not full JSON blobs: **`subject`**, **`subject_ref`** keys, **`summary_status`**, **`claim_assessment.status`**.

#### Step WALK-04-01 — Retention purge evidence (`retention_run`)

**Operator question:** Does org **`offboarded-co`** have a completed retention-run evidence record and an empty operator timeline?

**Prerequisites:** Demo seed loaded (retention tail ran during seed).

**Do:**

1. Open **`http://localhost:4000/audit/evidence`**
2. Filter or locate subject **`retention_run`** with subject ref **`run_id: walk-retention-offboarded-co`**
3. Confirm evidence detail shows org Y offboard narrative
4. Open **`http://localhost:4000/audit`** and scope to org **`offboarded-co`** — confirm timeline is **empty** (negative check)
5. CLI parity from **`examples/threadline_phoenix/`**:

   ```bash
   mix threadline.evidence.show --subject retention_run \
     --subject-ref-json '{"run_id":"walk-retention-offboarded-co"}'
   ```

**Expected outcome:**

- **`subject`:** `retention_run`
- **`subject_ref`:** `run_id` = **`walk-retention-offboarded-co`**; org slug **`offboarded-co`**
- **`summary_status`:** **`completed`**
- **`claim_assessment.status`:** **`proven`** (retention purge narrative matches empty org Y audit footprint)
- Org Y scoped **`/audit`** timeline remains **empty** — no contradiction with evidence detail

**Evidence:**

| Field | Expected |
|-------|----------|
| subject | `retention_run` |
| subject_ref | `run_id` → `walk-retention-offboarded-co` |
| summary_status | `completed` |
| claim_assessment.status | `proven` |

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit/evidence` | Admin | subject `retention_run`, ref `walk-retention-offboarded-co` | evidence detail |
| `/audit` | Cross-org admin | org `offboarded-co` | should return no rows |

**Verify:** Optional — `demo_contract_test.exs` `"offboarded-co audit footprint purged with manifest retention evidence"`.

**If different:** File a finding citing **`WALK-04-01`**; do not fix during Phase 109.

---

#### Step WALK-04-02 — Redaction policy snapshot (`redaction_policy`)

**Operator question:** Does the seeded redaction-policy evidence row show **`inferred_posture`**, and does ticket **#4521** capture corroborate masking?

**Prerequisites:** Demo seed loaded; WALK-03-01 familiarity with #4521 close story.

**Do:**

1. Open **`http://localhost:4000/audit/policy/redaction`**
2. Locate policy snapshot keyed **`walk-demo-redaction-policy`**
3. Note **`claim_assessment.status`** on the policy evidence row
4. CLI parity:

   ```bash
   mix threadline.evidence.show --subject redaction_policy \
     --subject-ref-json '{"policy":"walk-demo-redaction-policy"}'
   ```

   Optional live viewer parity:

   ```bash
   mix threadline.policy.show
   ```

5. Corroborate capture: repeat WALK-03-01 row history on **`/audit/rows/ticket_replies/:pk`** for the #4521 close reply — internal note shows **`[REDACTED]`**, never plaintext secret text

**Expected outcome:**

- **`subject`:** `redaction_policy`
- **`subject_ref`:** `policy` = **`walk-demo-redaction-policy`**
- **`summary_status`:** **`active`**
- **`claim_assessment.status`:** **`inferred_posture`** (posture inferred from trigger capture config, not a live legal-hold proof)
- Ticket **#4521** close reply capture shows **`[REDACTED]`** on masked fields — corroborates the policy narrative

**Evidence:**

| Field | Expected |
|-------|----------|
| subject | `redaction_policy` |
| subject_ref | `policy` → `walk-demo-redaction-policy` |
| summary_status | `active` |
| claim_assessment.status | `inferred_posture` |

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit/policy/redaction` | Admin global | policy `walk-demo-redaction-policy` | policy drift detail |
| `/audit/rows/ticket_replies/:pk` | Org-scoped or admin | #4521 close reply pk | `[REDACTED]` on internal note |

**Verify:** Optional — `demo_contract_test.exs` `"post-demo.seed redaction_policy row matches manifest subject_ref"`.

**If different:** File a finding citing **`WALK-04-02`**; do not fix during Phase 109.

---

#### Step WALK-04-03 — Trigger coverage snapshot (`trigger_coverage`)

**Operator question:** Does the seeded trigger-coverage snapshot show audited tables are covered?

**Prerequisites:** Demo seed loaded.

**Do:**

1. Open **`http://localhost:4000/audit/coverage`**
2. Locate snapshot **`walk-demo-trigger-coverage`**
3. Confirm covered vs uncovered bucket counts match seeded help-desk tables
4. Optional CLI parity from **`examples/threadline_phoenix/`**:

   ```bash
   mix threadline.health.coverage
   ```

   Evidence row CLI:

   ```bash
   mix threadline.evidence.show --subject trigger_coverage \
     --subject-ref-json '{"snapshot":"walk-demo-trigger-coverage"}'
   ```

**Expected outcome:**

- **`subject`:** `trigger_coverage`
- **`subject_ref`:** `snapshot` = **`walk-demo-trigger-coverage`**
- **`summary_status`:** **`snapshot`**
- **`claim_assessment.status`:** **`proven`** (trigger inventory matches on-disk capture state post-seed)
- Help-desk audited tables appear in **covered** buckets; no unexpected **uncovered** surprises on shipped tables

**Evidence:**

| Field | Expected |
|-------|----------|
| subject | `trigger_coverage` |
| subject_ref | `snapshot` → `walk-demo-trigger-coverage` |
| summary_status | `snapshot` |
| claim_assessment.status | `proven` |

**Operator surface:**

| Route | Scope | Filters | Drill-down |
|-------|-------|---------|------------|
| `/audit/coverage` | Admin global | snapshot `walk-demo-trigger-coverage` | per-table trigger buckets |

**Verify:** Optional — `mix verify.threadline` coverage check after fresh migrate.

**If different:** File a finding citing **`WALK-04-03`**; do not fix during Phase 109.

### §5 Checkpoint

| Expected met? | Findings filed? | Blockers |
|---------------|-----------------|----------|
| ☐ WALK-04-01 retention_run completed + empty org Y timeline | ☐ | |
| ☐ WALK-04-02 redaction_policy inferred_posture + #4521 `[REDACTED]` | ☐ | |
| ☐ WALK-04-03 trigger_coverage snapshot proven | ☐ | |

---

## Appendix A — Demo reference

Walk-critical literals copied from **`DEMO-MANIFEST.md`** and **`DEMO_USERS.md`**. Edit the manifest first, then sync this appendix. **Do not open `DEMO-MANIFEST.md` mid-run** — use this section instead.

### Temporal anchors

| Key | UTC instant | Notes |
|-----|-------------|-------|
| `demo_epoch` | `2026-05-27T12:00:00Z` | Frozen “today” for seed backfill and filters |
| `demo_last_tuesday` | `2026-05-20T14:30:00Z` | Operator filters when prose says “last Tuesday” |

### Organizations

| Slug | UUID | Walkthrough role |
|------|------|------------------|
| `acme` | `d99bff6a-063e-5f45-baaf-4f7a9d60ff72` | Primary org — ticket #4521 close, #4518 delete |
| `globex` | `64a4ee60-79d6-566d-8db3-62782aa6a4c2` | Third org — filler and WALK-02 samples |
| `offboarded-co` | `93cba30e-e2d5-5d95-9c50-7023f4c3eda5` | Org Y — retention purge end state (WALK-04) |

### Hero tickets (Acme)

| Number | Story | Primary actor |
|--------|-------|---------------|
| **4521** | Reply + close with masked internal note | `closer@acme.example.com` |
| **4518** | Hard-deleted reply | `deleter@acme.example.com` |

### Users and passwords

Shared demo password: **`password123456`** (override with `DEMO_SEED_PASSWORD` when seeding).

| Email | Password | Org slug | Role | Walkthrough step |
|-------|----------|----------|------|------------------|
| `agent2@acme.example.com` | `password123456` | `acme` | agent | WALK-03-02 — leaving-agent window |
| `closer@acme.example.com` | `password123456` | `acme` | agent | WALK-03-01 — #4521 close |
| `deleter@acme.example.com` | `password123456` | `acme` | agent | WALK-03-04 — #4518 delete |
| `support@acme.example.com` | `password123456` | `acme` | support | Daily-use triage |
| `support@globex.example.com` | `password123456` | `globex` | support | WALK-02 non-Acme samples |
| `support@offboarded-co.example.com` | `password123456` | `offboarded-co` | support | Org Y pre-offboard |
| `admin@example.com` | `password123456` | _(cross-org)_ | operator admin | Cross-org `/audit`, evidence exercises |

### Fixed user IDs (Sigra)

| Persona | Email | Fixed `user_id` (UUID) |
|---------|-------|------------------------|
| Acme closer | `closer@acme.example.com` | `cb1b4a0f-17e6-5afe-a072-5c5a6895ee5b` |
| Acme deleter | `deleter@acme.example.com` | `70dd93dc-140a-5d72-950e-85ab11025f40` |
| Acme agent2 (leaving) | `agent2@acme.example.com` | `33123cc4-da21-5674-b030-e168cee90521` |
| Cross-org admin | `admin@example.com` | `5bbaa26c-b413-5c51-8c9e-88806fd8641d` |
| Acme support | `support@acme.example.com` | `58a977be-58b4-5763-896b-ed62ecd4b3a7` |
| Globex support | `support@globex.example.com` | `2a147e6c-edae-5719-a90a-536faa27ad4e` |
| Offboarded support | `support@offboarded-co.example.com` | `03524474-dab0-59f6-91a0-90a06dc0e549` |

### Correlation IDs

| Key | Value | Used for |
|-----|-------|----------|
| Acme #4521 close | `walk-acme-4521-close` | Semantic correlation on close transaction |

### Evidence subject refs

| Subject | Subject ref key | Value | Expected `claim_assessment.status` |
|---------|-----------------|-------|-----------------------------------|
| `retention_run` | `run_id` | `walk-retention-offboarded-co` | `proven` |
| `retention_policy` | `policy` | `walk-demo-retention-policy` | _(policy row — not WALK-04 focus)_ |
| `redaction_policy` | `policy` | `walk-demo-redaction-policy` | `inferred_posture` |
| `trigger_coverage` | `snapshot` | `walk-demo-trigger-coverage` | `proven` |

---

## Appendix B — Command cheat sheet

Run from **`examples/threadline_phoenix/`** unless noted.

| Command | Purpose |
|---------|---------|
| `mix setup` | `deps.get` → `compile` → `ecto.setup` (no demo fiction) |
| `mix demo.seed` | Load deterministic walkthrough help-desk fiction |
| `mix demo.reset` | Truncate demo tables and re-run `demo.seed` |
| `mix phx.server` | Start Phoenix on `http://localhost:4000` |
| `mix threadline.evidence.show` | Evidence plane viewer (canonical; see §5 footnote) |
| `mix threadline.policy.show` | Redaction policy CLI parity |
| `mix threadline.health.coverage` | Trigger coverage CLI parity |

---

## Further reading (not required for this run)

Optional context after the Phase 109 dry-run — **not** needed mid-walk:

- [`../../guides/getting-started-saas.md`](../../guides/getting-started-saas.md) — integrator first-hour wiring in your own app
- [`README.md`](./README.md) — runnable install contract, operator mount recipe, and test entrypoints
