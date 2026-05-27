# Phase 107: Realistic Seed Data + Demo Mix Tasks - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `mix demo.seed` and `mix demo.reset` under `examples/threadline_phoenix/` only. Produce deterministic ~3-organization × 5-agent × 50-ticket help-desk activity spanning ~14 days (with realistic audit gaps) so every Phase 108 walkthrough scenario has a real on-disk answer before the walkthrough script is written.

Requirements: SEED-01, SEED-02, SEED-03, SEED-04, SEED-05. `lib/` is read-only. Demo tasks live under `examples/threadline_phoenix/lib/mix/tasks/` — deliberately separate from `priv/repo/seeds.exs` so adopters do not conflate demo fiction with their own seed scaffolding.

Phase 108 writes `WALKTHROUGH.md` **from** the locked demo manifest shipped in this phase — not the other way around.

</domain>

<decisions>
## Implementation Decisions

### Demo manifest as contract (D-107-01)

- **D-107-01a:** Ship **`examples/threadline_phoenix/DEMO-MANIFEST.md`** plus **`ThreadlinePhoenix.Demo.Manifest`** module attributes as the **single source of truth** for walkthrough literals (org slugs, UUIDs, ticket numbers, user emails, incident timestamps, evidence `run_id`s). Phase 108 copies prose from this file; Phase 109 dry-run validates against it.
- **D-107-01b:** Manifest defines **`demo_epoch`** (frozen “today” for the milestone, e.g. `~U[2026-05-27 12:00:00Z]`) and derived **`demo_last_tuesday`** (absolute UTC instant for operator time filters). Human walkthrough text may say “last Tuesday” but must footnote manifest dates — **no** `DateTime.utc_now()` / `Date.utc_today()` inside `demo.seed`.
- **D-107-01c:** Locked hero entities (minimum): org **`acme`**, ticket **`number: 4521`** (Phase 105 D-01c); separate ticket for delete story (e.g. **`4518`**); org **`offboarded-co`** (org Y); fixed Sigra `user_id` strings and display names for closer vs deleter.
- **D-107-01d:** Post-seed **contract test** asserts manifest heroes exist and WALK-critical audit rows exist (close on #4521, hard delete on reply, retention evidence for org Y).

**Rationale:** SEED-03 and ROADMAP Phase 108 dependency require answers before scripting. Retrofit-walkthrough-to-random-seed fails RUN-02 and redaction stories (internal notes are masked, not quotable).

### Sigra personas — hybrid (D-107-02)

- **D-107-02a:** **`mix demo.seed` creates real Sigra users** via `Accounts.register_user` + email confirm (same path as test fixtures), with documented demo password (`password123456` default or `DEMO_SEED_PASSWORD` env override).
- **D-107-02b:** Ship **`examples/threadline_phoenix/DEMO_USERS.md`** — table of email, password, org slug, role, and which walkthrough step uses each account. Banner: public demo credentials, **`MIX_ENV=dev` / `:test` only**.
- **D-107-02c:** All seeded personas use **`HelpDesk.provision_default_workspace_for_user/2`** with explicit **`slug:`** and **`name:`** (106 D-106-01e) — no random `org-*` slugs for heroes; upsert by email/slug on re-run.
- **D-107-02d:** **WALK-01 onboarding** keeps a **fresh register** path (any new email) to prove auto-provision — additive to seeded fiction, not a replacement for Acme/support/admin personas.
- **D-107-02e:** Global admin via existing **`OperatorUser` `admin_emails`** config; seed **`admin@example.com`** for cross-org admin scenarios.

**Rationale:** Phase 107 depends on real users with real memberships (ROADMAP). Register-only cannot produce two-week backdated audit history. Phase 106 locked hybrid auto-provision + demo seed.

### `demo.reset` blast radius (D-107-03)

- **D-107-03a:** Default **`mix demo.reset`** = **`TRUNCATE … CASCADE`** on a maintained **`@demo_tables`** list, then **`mix demo.seed`**. Same data state as fresh migrate + demo seed without dropping schema.
- **D-107-03b:** **`@demo_tables`** includes at minimum: `ticket_replies`, `tickets`, `agents`, `org_memberships`, `organizations`, `audit_changes`, `audit_transactions`, `audit_actions`, `posts`, `oban_jobs`. Optionally `audit_events` (Sigra auth audit) if stale login noise confuses walkthrough. **Share the list** with `help_desk_audit_test` truncate SQL to avoid drift.
- **D-107-03c:** Document **`mix ecto.reset`** (or `mix demo.reset --full` if implemented) as **schema/trigger recovery** escape hatch — not the daily walkthrough loop.
- **D-107-03d:** **Fixed UUIDs** for demo orgs/users in manifest so truncate+reseed preserves Sigra sessions when cookies still valid (`active_organization_id` matches re-seeded org).
- **D-107-03e:** Both **`demo.seed`** and **`demo.reset`** **raise** in `:prod` unless explicit override env (e.g. `DEMO_ALLOW_RESET=1`).

**Rationale:** Rails `db:seed:replant` analogue for fast iteration; literal `ecto.reset` every recovery is harsh DX and wipes sessions. SEED-04 intent is recoverable walkthrough state, not mandatory `ecto.drop` on every run.

### Activity synthesis — hybrid layers (D-107-04)

- **D-107-04a:** Pin **`:rand.seed(:exsss, {1, 2, 3})`** at task start; PRNG drives **filler only**. Hero entities use **deterministic UUIDs** (e.g. UUID v5 from namespace + `"acme/ticket/4521"`) and stable slugs/numbers.
- **D-107-04b:** **Anchor layer (~15–25 transactions)** — real context writes with capture + semantics:
  - Acme **#4521**: `HelpDesk.ticket_replied_and_closed/6` with masked `internal_note_body`, fixed **`correlation_id`** (e.g. `"walk-acme-4521-close"`).
  - **SEED-05 delete**: new **`HelpDesk.delete_reply/3`** — GUC `threadline.actor_ref` → `Repo.delete!` → org `meta` on transaction (mirror Phase 105 delete test); **hard DELETE only**, no `:ticket_reply_deleted` unless Phase 108 draft proves need.
  - Leaving-agent **24h window**: 8–15 txs same `ActorRef` `{:user, user_id}`.
  - WALK-02 samples: additional `ticket_replied_and_closed` in non-Acme orgs.
- **D-107-04c:** **Filler layer (~125 tickets)** — per-ticket `Repo.transaction`: GUC actor → insert ticket (light updates OK) → `update_all` org `meta` on `audit_transactions` — **no** `record_action` on filler (avoids action-catalog noise).
- **D-107-04d:** **Temporal layer (required)** — after all writes, deterministic **audit timestamp backfill** updating `audit_transactions.occurred_at` and `audit_changes.captured_at` from manifest offsets relative to `demo_epoch`. Triggers use `clock_timestamp()` at write time; domain `inserted_at` alone does **not** move `/audit` timelines.
- **D-107-04e:** **Do not** bulk `insert_all` into `audit_*` for walkthrough data (bench pattern only). **Do not** insert 50 tickets in one transaction (one `txid` breaks transaction-grouping story).

**Rationale:** Threadline value prop is trustworthy capture on stories that matter; filler supplies volume and org-scoped timeline density without fake audit tables.

### Delete incident — SEED-05 (D-107-05)

- **D-107-05a:** **Hard DELETE** on `ticket_replies` only; deleter is a **named Acme agent** with fixed Sigra `user_id`, **distinct** from #4521 closer.
- **D-107-05b:** Delete target on **separate ticket** (manifest e.g. **#4518**) — do not conflate with WALK-03 #1 close+note on #4521.
- **D-107-05c:** “What was the note?” = **prior** `row_history` with **`[REDACTED]`** masked field — not plaintext on delete row (105 D-03d, CAP-03). Phase 108 must add a **fourth operator incident** for delete (“who deleted reply on ticket #4518 in Acme last Tuesday?”) — not in current WALK-03 three-utterance list alone.
- **D-107-05d:** Defer **`:ticket_reply_deleted`** `record_action` unless Phase 108 requires semantic action name or strict correlation on delete path; `actor_ref` on delete transaction is sufficient per Phase 105 proof.

### Org Y offboard — post-purge end state (D-107-06)

- **D-107-06a:** **`demo.seed` ends with org Y already offboarded** — audit footprint for org Y purged, governance + evidence rows document the purge. Walkthrough does **not** depend on live `mix threadline.retention.purge` for the compliance answer (optional WALK-04 prose only).
- **D-107-06b:** Seed pipeline tail: backdate org Y audit **older than** retention window; Acme/third org **within** window → enable retention in task env → **`Threadline.Retention.purge/1`** once → **`Threadline.Evidence.record_retention_run/3`** with **fixed** `subject_ref` / `detail` naming `offboarded-co` + org UUID + `deleted_changes` → seed WALK-04 **`retention_policy`** and **`trigger_coverage`** snapshots in same pass.
- **D-107-06c:** **`Retention.purge/1` is global by age** — org Y story is **host narrative in evidence `detail`**, not per-org purge in `lib/`. Do not extend retention semantics in `lib/` (v1.23 non-goals).
- **D-107-06d:** Operator proof path: `/audit/evidence` + **`mix threadline.evidence.show`** with fixed JSON `subject_ref`; scoped timeline for org Y expected **empty** after purge (negative check documented in manifest).

### Idempotency and verification (D-107-07)

- **D-107-07a:** Hero rows **upsert** by email, org slug, `(organization_id, number)`; `provision_default_workspace_for_user` idempotency for first org per user (106).
- **D-107-07b:** **Primary idempotency guarantee:** `mix demo.reset` → identical post-migrate fiction state. Second `mix demo.seed` without reset should converge (SEED-02); strict byte-identical audit UUIDs may use **semantic fingerprint** tests where trigger `gen_random_uuid()` prevents byte parity.
- **D-107-07c:** Example README documents: `mix demo.seed`, `mix demo.reset`, link `DEMO_USERS.md` + `DEMO-MANIFEST.md`; `ecto.setup` does **not** auto-run demo seed.

### Claude's Discretion

- Exact third org slug/name and filler ticket bodies.
- Whether `demo.reset` exposes `--full` flag vs documenting raw `mix ecto.reset`.
- `login_via_sigra` alignment for demo password in tests.
- Exact manifest email local-parts and display names (must stay stable once published).
- Whether to truncate `audit_events` in `@demo_tables`.
- Minor jitter table for filler `captured_at` offsets within the 14-day window.

### Folded Todos

(none — `todo.match-phase` unavailable / no matches)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contracts

- `.planning/ROADMAP.md` § Phase 107 — goal, success criteria, scope guard, SEED requirements
- `.planning/REQUIREMENTS.md` — SEED-01 through SEED-05, WALK-03 utterances (Phase 108), Out of Scope
- `.planning/phases/105-help-desk-domain-expansion-in-reference-app/105-CONTEXT.md` — org UUID meta (D-01), semantic actions (D-02), redaction mask (D-03), hard delete (D-04), agent↔user_id (D-06)
- `.planning/phases/106-sigra-auth-lane-in-reference-app/106-CONTEXT.md` — `provision_default_workspace_for_user/2` (D-106-01), hybrid seed (D-106-01e), test pyramid (D-106-04)
- `.planning/phases/104-reference-walkthrough-charter-override-decision/104-CONTEXT.md` — v1.23 synthetic adopter, `lib/` read-only, reference-app posture

### Example app (implementation surface)

- `examples/threadline_phoenix/README.md` — install path; must cite demo tasks after Phase 107
- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` — extend with `delete_reply/3`; existing `ticket_replied_and_closed/6`
- `examples/threadline_phoenix/test/support/help_desk_fixtures.ex` — org → membership → agent chain
- `examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_test.exs` — truncate SQL precedent for `@demo_tables`
- `examples/threadline_phoenix/test/support/auth_fixtures.ex` — `register_user` + confirm pattern for seeded users

### Threadline library (read-only in 107)

- `lib/threadline/retention.ex` — `Retention.purge/1` (global age cutoff; writes `threadline_retention_runs`)
- `lib/threadline/evidence.ex` — `record_retention_run/3`, `record_retention_policy/3`, `record_trigger_coverage/3`
- `guides/domain-reference.md` — actor window, row history, delete semantics
- `guides/evidence-plane.md` — evidence subjects and operator paths

### Vision, ecosystem lessons, OSS DNA

- `prompts/threadline-elixir-oss-dna.md` — honest verification, canonical example host, doc contracts
- `prompts/audit-lib-domain-model-reference.md` — capture vs semantics; one action per business operation
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — django-auditlog masking/set_actor; Logidze soft-delete footguns; missed writes on bulk bypass

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ThreadlinePhoenix.HelpDesk` — `provision_default_workspace_for_user/2`, `ticket_replied_and_closed/6`, `get_membership_role/2`
- `help_desk_fixtures.ex` — extend into `Demo` seed builders with **fixed attrs**, not random Faker
- `help_desk_audit_test.exs` — `@truncate_sql` template for `@demo_tables`
- `auth_fixtures.ex` / `conn_case.ex` `login_via_sigra/2` — align demo password with HTTP login proofs
- `priv/repo/seeds.exs` — stays minimal (two blog posts); do not add walkthrough volume here

### Established Patterns

- Org scope: `audit_transactions.meta` `%{"organization_id" => uuid_string}` only (105 D-01a)
- Actor identity: `ActorRef.new(:user, sigra_user_id)` — not `agents.id` (105 D-06c)
- One `record_action` per close transaction: `:ticket_replied_and_closed` (105 D-02)
- Internal notes: **mask** + `store_changed_from` — walkthrough proves redaction, not recovery (105 D-03d)
- Bench `insert_all` into audit tables — performance tests only, not walkthrough seeds

### Integration Points

- `lib/mix/tasks/demo.seed.ex` / `demo.reset.ex` — SEED-01 entrypoints
- `lib/threadline_phoenix/demo/{manifest,seed,reset}.ex` — task implementation modules
- `config/dev.exs` — `:demo_epoch`, `:demo_seed_password`, retention enabled for seed task window
- Phase 108 `WALKTHROUGH.md` imports literals from `DEMO-MANIFEST.md`
- Phase 108 should use `mix threadline.evidence.show` as canonical CLI (add thin alias if `mix verify.evidence` name required)

</code_context>

<specifics>
## Specific Ideas

- **Incident pack model:** SIEM sample searches written against an ingest manifest — `DEMO-MANIFEST.md` is that manifest for v1.23.
- **Stripe test clock:** frozen `demo_epoch` + deterministic offsets for all timeline filters; no sleeping 14 days.
- **Coherent package:** manifest → fixed UUIDs → truncate+reseed → anchor context writes → audit timestamp pass → evidence row for org Y.
- Phase 108 **must not** quote internal note plaintext in expected outputs — only attribution, timing, and redaction proof.
- Third operator incident in WALK-03 is **evidence-plane** org Y purge; fourth incident (add in 108) is **delete attribution** SEED-05.

</specifics>

<deferred>
## Deferred Ideas

- `:ticket_reply_deleted` and expanded help-desk action catalog — only if Phase 108 draft proves trigger-only delete insufficient
- Live `mix threadline.retention.purge` as proof path for org Y — defer to WALK-04 optional “how you’d run in prod” prose
- Per-org retention purge in `lib/` — v1.24 / design gap if pressured
- Soft-delete on `ticket_replies` — explicitly rejected in Phase 105
- Bulk `insert_all` into `audit_*` for walkthrough fiction
- Auto-run `demo.seed` from `ecto.setup` — adopters opt in explicitly

### Reviewed Todos (not folded)

(none)

</deferred>

---

*Phase: 107-realistic-seed-data-demo-mix-tasks*
*Context gathered: 2026-05-27*
