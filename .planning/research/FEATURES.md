# Features Research — Host staging / pooler parity

**Researched:** 2026-04-23  
**Milestone:** v1.6 (STG-01 follow-up from v1.5)

## Categories

### Table stakes (must be credible for “adoption complete”)

- **Topology honesty** — Written record of **app → ? → Postgres**, pooler product, **pool mode**, and whether staging matches production topology (**yes / no / partial** + why).
- **Representative audited paths** — At least one **HTTP**-scoped write that lands in audit tables with correct **actor / transaction** linkage, and at least one **background job** path (Oban-style async is the documented expectation from v1.5 STG draft).
- **Evidence discipline** — `OK` / `Issue` / `N/A` rows in **`guides/adoption-pilot-backlog.md`** (or integrator-maintained copy) with citations: logs, SQL, redacted config, or GitHub issue links — not assertions.

### Differentiators (Threadline-specific)

- **GUC-safe semantics** — Library already avoids fragile `SET LOCAL` patterns in capture; host proof validates **their** stack still keeps **same transaction** for writes + trigger capture when a pooler is present.
- **CI vs host boundary** — Clear distinction: **`verify-pgbouncer-topology`** proves **library** code through **transaction** PgBouncer; STG proves **integrator** wiring.

### Anti-features / defer

- **Expanding `Threadline.Query` / `Threadline.Export` for pilot convenience** — Explicitly deferred until repeated pilot pain (per `PROJECT.md` Future).
- **In-repo sample Phoenix app** — Still out of scope; guides + backlog remain the vehicle.

## Dependencies on existing product

- **`Threadline.Plug`**, **`Threadline.Job`**, trigger installer, **`mix verify.*`** — already shipped; STG does not require API churn.
