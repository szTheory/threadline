# Brownfield continuity with Threadline capture

This guide describes how to adopt Threadline on **PostgreSQL tables that already contain rows** while keeping the audit story honest.

## Semantics (T0)

**T0** means `audit_changes` stays **empty** for a table until the **first** `INSERT`, `UPDATE`, or `DELETE` that runs **after** Threadline’s capture trigger is installed. Existing rows have **no** implied history in `audit_changes`.

Until that first audited write, **`Threadline.history/3`** may return **`[]`** for a primary key even when the row existed long before capture — the database cannot prove who changed what before triggers existed.

Do **not** fabricate `AuditChange` rows to “fill in” pre-capture history; that would break honesty and the trigger-only contract documented on `Threadline.Capture.AuditChange`.

## Operator checklist

1. Install the Threadline audit schema (`mix threadline.install`) and run `mix ecto.migrate`.
2. Generate triggers for the tables you want audited (`mix threadline.gen.triggers --tables ...`) and migrate.
3. Run [`mix threadline.verify_coverage`](https://hexdocs.pm/threadline/Mix.Tasks.Threadline.VerifyCoverage.html) so configured tables report as covered.
4. Review cutover messaging with `mix threadline.continuity --dry-run`, then validate a specific table with `mix threadline.continuity --table your_table` (or call `Threadline.Continuity` from application code).

## Compliance snapshot

If you need a **point-in-time baseline** at go-live, keep it **outside** `audit_changes`: use an export (`COPY`, logical dump slice), or an **application-owned** table. That baseline is **not** a substitute for retroactive audit — Threadline will not invent trigger-backed history for the pre-capture era (see CONTEXT **D-03**).

## PgBouncer / transactions

When you run operator SQL bundles (install DDL, trigger deploy, verification), prefer a **single explicit `BEGIN…COMMIT`** so catalog changes and optional GUC publishing stay in one database transaction, matching transaction-scoped capture semantics (CONTEXT **D-07**).
