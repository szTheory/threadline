# Pitfalls — Adding host staging / pooler proof

**Researched:** 2026-04-23

## Integration pitfalls

1. **Conflating CI green with host staging** — `verify-pgbouncer-topology` validates **library** paths; STG-01 exists because **AP-ENV.1** required honest host remainder. **Prevention:** Use **matches prod: partial** when CI covers a class of behavior but not full host topology.

2. **Transaction pooling without transaction discipline** — Holding DB connections across `await` boundaries, long HTTP idle, or pool checkout misuse can split logical “request” across DB transactions → missing or fragmented audit context. **Prevention:** Document actual Repo usage; align with Ecto **sandbox** vs prod pool settings in evidence.

3. **Job process not using `Threadline.Job`** — Async work that uses bare `Repo.insert` without actor bridge yields **anonymous** or wrong actor in audit. **Prevention:** STG-02 explicitly requires a **job path** proof with correct semantics.

4. **PgBouncer `statement` / wrong pool mode** — Some hosts run statement pooling (incompatible with many session features). Claiming “PgBouncer” without mode is misleading. **Prevention:** Record **POOL_MODE** (or vendor equivalent).

5. **Redacted evidence that cannot be reproduced** — Screenshots without versions, SQL without `app_version` / migration IDs. **Prevention:** Tie evidence to **`threadline`** semver and app commit SHA in backlog notes.

## Phase placement

- **Pitfalls 1–2** → addressed in **Phase 21** planning copy / checklist wording (docs).  
- **Pitfalls 3–5** → acceptance criteria for **STG-02**, **STG-03** verification.
