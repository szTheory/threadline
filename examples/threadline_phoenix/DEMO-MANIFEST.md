# Demo manifest

Single source of truth for walkthrough literals in the Threadline Phoenix reference app.
Programmatic accessors live in `ThreadlinePhoenix.Demo.Manifest`; demo credentials are in
[DEMO_USERS.md](./DEMO_USERS.md).

UUIDs are **UUID v5** under namespace `threadline.demo` (`4ac3a105-a7ce-5aee-9cee-eef531ea363c`),
with per-entity names such as `org/acme` or `user/closer@acme.example.com`.

## Temporal anchors

| Key | UTC instant | Notes |
|-----|-------------|-------|
| `demo_epoch` | `2026-05-27T12:00:00Z` | Frozen “today” for seed backfill and filters |
| `demo_last_tuesday` | `2026-05-20T14:30:00Z` | Operator filters when prose says “last Tuesday” (7 days before epoch) |

Configured in `config/dev.exs` as `:demo_epoch` and `:demo_seed_password`.

## Organizations

| Slug | UUID | Walkthrough role |
|------|------|------------------|
| `acme` | `d99bff6a-063e-5f45-baaf-4f7a9d60ff72` | Primary org — ticket #4521 close, #4518 delete |
| `globex` | `64a4ee60-79d6-566d-8db3-62782aa6a4c2` | Third org — filler and WALK-02 samples |
| `offboarded-co` | `93cba30e-e2d5-5d95-9c50-7023f4c3eda5` | Org Y — retention purge end state (WALK-04) |

## Hero tickets (Acme)

| Number | Story | Closer / actor |
|--------|-------|----------------|
| **4521** | Reply + close with masked internal note | `closer@acme.example.com` |
| **4518** | Hard-deleted reply (SEED-05) | `deleter@acme.example.com` |

## Users (Sigra)

| Persona | Email | Fixed `user_id` (UUID) |
|---------|-------|------------------------|
| Acme closer | `closer@acme.example.com` | `cb1b4a0f-17e6-5afe-a072-5c5a6895ee5b` |
| Acme deleter | `deleter@acme.example.com` | `70dd93dc-140a-5d72-950e-85ab11025f40` |
| Cross-org admin | `admin@example.com` | `5bbaa26c-b413-5c51-8c9e-88806fd8641d` |
| Acme support | `support@acme.example.com` | `58a977be-58b4-5763-896b-ed62ecd4b3a7` |
| Globex support | `support@globex.example.com` | `2a147e6c-edae-5719-a90a-536faa27ad4e` |
| Offboarded support | `support@offboarded-co.example.com` | `03524474-dab0-59f6-91a0-90a06dc0e549` |

See [DEMO_USERS.md](./DEMO_USERS.md) for passwords and walkthrough step mapping.

## Correlation and evidence

| Key | Value | Used for |
|-----|-------|----------|
| Acme #4521 close | `walk-acme-4521-close` | Semantic correlation on close transaction |
| Org Y retention evidence | `walk-retention-offboarded-co` | `Threadline.Evidence` run id / subject ref |
| Redaction policy snapshot | `walk-demo-redaction-policy` | WALK-04 exercise 2; `claim_assessment.status` expected `inferred_posture` |

Evidence `subject_ref` for org Y purge names `offboarded-co` and org UUID `93cba30e-e2d5-5d95-9c50-7023f4c3eda5`
(see Phase 108 WALK-04 and `mix threadline.evidence.show`).

## State recipes

How to reach every meaningful operator-surface state from the enriched seed — no re-seeding, no `--profile` flags.

**One-command story:** `mix demo.reset && mix demo.seed` is the only seed entrypoint. States are _reached_ (log in as X, open path Y, apply filter Z), never re-seeded. No `--profile` flag is used or needed.

| Screen | State | Login | Filter / Path | Notes |
|--------|-------|-------|---------------|-------|
| Timeline | default (op variety, non-human actors above fold) | `admin@example.com` | `/audit/timeline` (default 24h window) | In-window variety pack: 5 INSERT / 4 UPDATE / 2 DELETE; all non-human actor kinds visible |
| Timeline | op filter — updates only | `admin@example.com` | `/audit/timeline?op=update` | Shows ticket reopened, ticket_replies edit, role change |
| Timeline | op filter — deletes only | `admin@example.com` | `/audit/timeline?op=delete` | Shows reply hard-delete (ticket_replies), ticket delete (tickets); membership role change is UPDATE backdated outside 24h window — not visible here |
| Timeline | empty (future-date filter) | `admin@example.com` | `/audit/timeline?from=2030-01-01` | No records match; empty-state copy visible |
| Timeline | dense (wide date range) | `admin@example.com` | `/audit/timeline?from=2026-01-01` | Filler corpus: ~50 tickets/org across INSERT/UPDATE/DELETE |
| Timeline | scoped (org-filtered) | `support@acme.example.com` | `/audit/timeline` | Scoped via `scope_operator_query/3`; only Acme rows |
| Timeline | empty (scoped purged org) | `support@offboarded-co.example.com` | `/audit/timeline` | `offboarded-co` is purged-empty (`RetentionTail` hard-asserts zero audit footprint); honest empty scoped Timeline |
| Transactions | default | `admin@example.com` | `/audit/transactions/:id` (any tx from Timeline) | |
| Transactions | rich diff (before→after + [REDACTED]) | `admin@example.com` | Open tx for reply-edit story (1h ago in Timeline) | `ticket_replies` is the only table with `store_changed_from: true` + `mask: ["internal_note_body","body"]` |
| Actor | default | `admin@example.com` | `/audit/actors/:actor_ref` | |
| Actor | non-human actor row | `admin@example.com` | Filter by `service_account`, `job`, or `system` in Timeline, open Actor | service_account/zendesk-sync, job/oban-retention-purge, system/trigger-backfill all in-window |
| Actor | anonymous actor | `admin@example.com` | Filter by `actor_kind=anonymous` in Timeline | Public-form ticket submission cluster; renders as muted "unknown" (deliberate, not a bug) |
| Row History | default | `admin@example.com` | `/audit/transactions/:id/history/:table/:record_id` | |
| Row History | before→after diff + [REDACTED] | `admin@example.com` | Row history for the edited `ticket_replies` row | Shows multi-field before/after; `internal_note_body` shows `[REDACTED]` |
| Coverage | default (gaps present) | `admin@example.com` | `/audit/coverage` | 12 uncovered tables visible |
| Coverage | scoped | `support@acme.example.com` | `/audit/coverage` | Returns `{:error, :unauthorized}` — admin-only screen; permission-edge state |
| Coverage | fully-covered / all-empty | — | — | **DEFERRED to Phase 138** — depends on trigger registration + schema introspection (`Health.trigger_coverage`), not org rows; cannot be produced seed-only (D-04) |
| Evidence | default | `admin@example.com` | `/audit/evidence` | |
| Evidence | scoped / permission-edge | `support@acme.example.com` | `/audit/evidence` | Returns `{:error, :unauthorized}` — admin-only screen |
| Exports | default | `admin@example.com` | `/audit/exports` | |
| Exports | scoped / permission-edge | `support@acme.example.com` | `/audit/exports` | Returns `{:error, :unauthorized}` — admin-only screen |
| Redaction | default | `admin@example.com` | `/audit/redaction` | `ticket_replies` masked fields visible; dev.exs policy drift config in place |
| Retention | default | `admin@example.com` | `/audit/retention` | Org Y purge run visible |
| Home | default (with SavedViews) | `admin@example.com` | `/audit` | 2 SavedView rows seeded: "Recent deletes" + "Closed this week" (render → Phase 139) |
| Home | scoped | `support@acme.example.com` | `/audit` | Scoped via `my_authorize_fn/1` |

**Permission-edge summary:** Any support login (`support@<org>.example.com`) can reach scoped Timeline/Transactions/Actor/Row History for their org. Admin-only screens (Coverage, Evidence, Exports, Policy) return `{:error, :unauthorized}` for the same login — this is the permission-edge state for free, no new code needed (D-02).

**Empty / purged org:** `support@offboarded-co.example.com` reaches an honest empty scoped Timeline because `offboarded-co` is the retention-purge end state — `RetentionTail.assert_org_y_audit_empty!/1` hard-asserts zero audit footprint. No seed variant needed.

## Named actor literals

Non-human actors seeded by the variety pack (Plan 03). All are small, named, in-window clusters demonstrable without looking synthetic.

| Kind | Actor ID | `Manifest.actor_id/1` key | Activity seeded |
|------|----------|--------------------------|-----------------|
| `:service_account` | `zendesk-sync` | `:zendesk_sync` | Inbound ticket sync INSERT + UPDATE upserts (1h ago, 6h ago) |
| `:job` | `oban-retention-purge` | `:oban_retention_purge` | Ticket reopen + stale-ticket sweep (2h ago, 3.5h ago) |
| `:system` | `trigger-backfill` | `:trigger_backfill` | Backfill correction UPDATE (ticket 5007, 2.75h ago) + ticket DELETE (ticket 5004, 5h ago); membership role change is epoch-backdated UPDATE (outside 24h window) |
| `:anonymous` | _(no id)_ | — | Public ticket-submission form cluster; renders as muted "unknown" (deliberate) (5.5h ago, 4h ago) |

`Manifest.actor_id/1` returns the bare actor ID string; the `:kind` is supplied at the call site:

```elixir
Support.set_actor_guc!(Manifest.actor_id(:zendesk_sync), :service_account)
Support.set_actor_guc!(Manifest.actor_id(:oban_retention_purge), :job)
Support.set_actor_guc!(Manifest.actor_id(:trigger_backfill), :system)
Support.set_anonymous_actor_guc!()   # :anonymous — no id
```
