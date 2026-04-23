# Requirements: Threadline

**Defined:** 2026-04-23  
**Milestone:** v1.3 — Production adoption (redaction, retention, export)  
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.3 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase (12–14).

### Redaction (capture-time)

- [x] **REDN-01**: Maintainer can configure **per audited table** which columns are **excluded** from capture (raw values never written to `audit_changes` JSONB fields such as `data_after` / `changed_fields`) using a documented configuration surface consumed by trigger generation (`mix threadline.gen.triggers` or successor).
- [x] **REDN-02**: Maintainer can configure **per audited table** which columns are **masked** at capture time with a **stable placeholder** (documented token); masked columns never persist the raw value in `data_after`, `changed_from` (when enabled), or equivalent JSONB payloads produced by triggers.

### Retention & purge

- [x] **RETN-01**: Maintainer can configure a **retention window** (e.g. maximum age or cutoff timestamp semantics — exact model per phase plan) for `AuditChange` records, scoped and documented so operators know what will be deleted.
- [x] **RETN-02**: Maintainer can run a **batched purge** entrypoint (Mix task and/or public API) that deletes expired `AuditChange` rows according to **RETN-01**, with **configurable batch size** and documented behavior for production use (locks, repeatability, safe re-runs).

### Export

- [x] **EXPO-01**: Caller can obtain a **CSV** representation of a **filtered** set of audit rows (minimum: `AuditChange` rows; filter options aligned with or composed from existing query patterns such as `Threadline.timeline/1` — exact API per phase plan) via a documented public function/module.
- [x] **EXPO-02**: Caller can obtain a **JSON** representation of the **same** filtered set via a documented public function/module, suitable for tooling and one-off investigations.

## Future Requirements

_Deferred past v1.3._

### Onboarding & polish (next milestone candidate)

- Expanded guides, production checklist, example apps, and narrative for “first week in production” without expanding core capture semantics.
- Hex **0.2.0** (or next semver) release packaging and changelog story once v1.3 capabilities are verified and documented.

### Operator UI

- LiveView-based exploration — deferred until export + retention + redaction prove sufficient for API-first adoption (`PROJECT.md` Out of Scope).

## Out of Scope (v1.3)

| Item | Reason |
|------|--------|
| LiveView / rich operator UI | High cost; API + SQL + export first |
| WAL / logical replication as capture backend | Explicit non-goal for v0.x |
| SIEM connectors | Different product category |
| Post-hoc redaction of already-stored audit JSON | v1.3 is trigger-time only; retroactive scrub is a different problem |
| Automated `mix hex.publish` from CI | Maintainer-driven publish remains the path until explicitly replanned |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REDN-01 | Phase 12 | Complete |
| REDN-02 | Phase 12 | Complete |
| RETN-01 | Phase 13 | Complete |
| RETN-02 | Phase 13 | Complete |
| EXPO-01 | Phase 14 | Complete |
| EXPO-02 | Phase 14 | Complete |

**Coverage:**

- v1.3 requirements: 6 total  
- Mapped to phases: 6  
- Unmapped: 0 ✓  

---
*Requirements defined: 2026-04-23*  
*Last updated: 2026-04-23 after milestone v1.3 roadmap creation*
