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
