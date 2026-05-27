# Demo users

> **Public demo credentials — `MIX_ENV` dev/test only.**  
> Do not reuse these passwords in production. Override the shared password with
> `DEMO_SEED_PASSWORD` when running `mix demo.seed` (default documented below).

Entity UUIDs, ticket numbers, and time anchors: [DEMO-MANIFEST.md](./DEMO-MANIFEST.md).

## Credentials

| Email | Password | Org slug | Role | Walkthrough step |
|-------|----------|----------|------|----------------|
| `closer@acme.example.com` | `password123456` | `acme` | agent | WALK-03 — who closed ticket **#4521** |
| `deleter@acme.example.com` | `password123456` | `acme` | agent | WALK-03 / SEED-05 — who deleted reply on **#4518** |
| `support@acme.example.com` | `password123456` | `acme` | support | Daily-use triage samples |
| `support@globex.example.com` | `password123456` | `globex` | support | WALK-02 — non-Acme close samples |
| `support@offboarded-co.example.com` | `password123456` | `offboarded-co` | support | Org Y (pre-offboard history) |
| `admin@example.com` | `password123456` | _(cross-org)_ | operator admin | Cross-org `/audit` and `OperatorUser` scenarios |

Password source: `ThreadlinePhoenix.Demo.Manifest.demo_seed_password/0` reads
`Application.get_env(:threadline_phoenix, :demo_seed_password)` or `DEMO_SEED_PASSWORD`.

## Operator admin

`admin@example.com` is listed in `config/dev.exs` under
`config :threadline_phoenix, ThreadlinePhoenixWeb.OperatorUser, admin_emails`.
Use this account for cross-org operator surfaces without sharing a single org’s agent login.
