# Requirements: Threadline v1.39 Quality Baseline, Schema Confidence, and CI Efficiency

**Defined:** 2026-07-01
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Source:** User `$gsd-new-milestone` prompt on software-quality evaluation, CI/CD performance, PostgreSQL schema hygiene, recent work recap, repository audit, and targeted external research.

**Milestone goal:** Make Threadline's adoption trust boundary current, measured, and durable by ranking software-quality risks, hardening configurable PostgreSQL storage-schema behavior, repairing release/docs drift, and improving CI/CD efficiency without hiding risk.

**Invariants:** no new operator product scope, no public component API, no root PhoenixStorybook dependency, no compliance-platform expansion, no external pilot without real signal, no runtime destructive redaction, no WAL/CDC backend, no clever CI topology before measurement, and no capture/query/auth semantic change unless needed to make existing published behavior truthful.

## v1 Requirements

### Quality Baseline

- [x] **QUAL-01**: Maintainers can read a repo-evidence software-quality audit that identifies the weakest quality dimensions, scores confidence, explains practical consequences, and ranks the highest-leverage fixes.
- [x] **QUAL-02**: The audit separates must-fix adoption/operations/maintainer risks from good-enough, low-priority, or N/A dimensions; it does not flatten every checklist item into generic consulting advice.
- [x] **QUAL-03**: Open residuals and seeds that affect quality trust are triaged, including SEED-005 reconnect/offline banner, screenshot-regression confidence, external pilot boundaries, host staging ownership, and known CI/example-app residuals.

### Storage Schema Confidence

- [ ] **SCHEMA-01**: A custom non-default `storage_schema`, using `audit` or an equivalent schema name, is proven end to end across Threadline-owned capture, query, evidence, governance, and operator-relevant paths, or uncovered gaps are fixed in the same milestone.
- [x] **SCHEMA-02**: Ecto schema prefix behavior is proven or corrected so configurable storage schemas do not silently read from or write to the hardcoded `threadline` prefix.
- [x] **SCHEMA-03**: Generated migration SQL quotes validated storage-schema identifiers consistently, or the supported identifier contract is narrowed, documented, and test-locked.
- [ ] **SCHEMA-04**: Non-public host-table support for continuity, policy/redaction inspection, and operator coverage is either implemented to match existing schema flags or explicitly documented and test-locked as intentionally public-only.

### Adoption and Release Docs

- [ ] **ADOPT-01**: Public install snippets, evaluator docs, upgrade guidance, README, adoption backlog, and package metadata agree on the current `0.9.0` package truth, or any older pinned line is explicitly justified.
- [ ] **ADOPT-02**: Upgrade guidance covers adopter-visible changes from the 0.6.x through 0.9.x era, including storage-schema default, operator surface/theming, release proof lanes, and migration expectations.
- [ ] **ADOPT-03**: README and ExDoc guide routing give evaluators, first-hour adopters, operators, and maintainers a shorter next-step path without creating a giant new guide.

### CI/CD Efficiency and Trust

- [ ] **CI-01**: The current CI/CD pipeline has a recorded baseline for PR/main wall-clock time, critical path, repeated setup/dependency cost, browser lane cost, cache state, and flaky/rerun signals using local or GitHub evidence where available.
- [ ] **CI-02**: Low-risk cache/setup improvements reduce repeated dependency/build work without restoring incompatible `_build` artifacts, hiding warnings, or making local reproduction harder.
- [ ] **CI-03**: PgBouncer image pinning, release concurrency, branch-protection docs, CI job names, and local `mix ci.*` expectations are aligned and testable.
- [ ] **CI-04**: Min/current Elixir, OTP, and PostgreSQL compatibility policy is explicit, and CI implements only the compatibility lanes that protect the stated support contract without blowing up PR feedback.

### Closeout

- [ ] **CLOSE-01**: v1.39 closes with requirements traceability, verification evidence, before/after CI data or explicit no-measure rationale, ranked remaining risks, and a clear recommendation for v1.40 or hold.

## Future Requirements

Deferred unless the v1.39 audit or real adopter pressure shows they materially reduce adoption, operations, or maintainer risk.

### External Adoption Proof

- **EXT-PILOT-01**: Run a real external adopter pilot with a named host and issue/PR feedback loop.

### Operational Observability

- **OBS-01**: Add richer telemetry metadata, runbook guidance, and operational diagnostics if the quality audit finds production debuggability is a top risk.

### UI Regression Confidence

- **UI-REG-01**: Promote screenshot-regression evidence to a stable release-quality lane if visual regressions remain a serious trust risk after v1.38.

### Operator Connectivity UX

- **RECONNECT-01**: Implement an operator reconnect/offline banner from SEED-005 if the quality audit classifies it as a trust-impacting UI failure mode.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New operator pages or workflows | v1.38 just shipped page-by-page polish; v1.39 is quality consolidation unless a fix is needed for existing truth. |
| Public component API or public Storybook | Would widen the library support contract and optional-Phoenix boundary before adopter pressure exists. |
| Compliance packs, legal hold, immutable archive guarantees | High support burden; defer until procurement or adopter signal. |
| External pilot without real signal | The project should not invent a synthetic pilot after repeated signal-gated decisions. |
| Runtime destructive redaction | Requires capture/storage semantics work and was explicitly deferred. |
| WAL/CDC backend | Violates the current custom-trigger/PgBouncer-safe capture decision and adds operational surface area. |
| Broad CI matrix/sharding before measurement | Optimization must follow baseline evidence and preserve trustworthy gates. |
| Version bump or Hex publish | v1.39 can repair release/docs trust, but cutting a new package is separate unless the fixes demand it. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| QUAL-01 | Phase 189 | Complete |
| QUAL-02 | Phase 189 | Complete |
| QUAL-03 | Phase 189 | Complete |
| SCHEMA-01 | Phase 190 | Pending |
| SCHEMA-02 | Phase 190 | Complete |
| SCHEMA-03 | Phase 190 | Complete |
| SCHEMA-04 | Phase 190 | Pending |
| ADOPT-01 | Phase 191 | Pending |
| ADOPT-02 | Phase 191 | Pending |
| ADOPT-03 | Phase 191 | Pending |
| CI-01 | Phase 192 | Pending |
| CI-02 | Phase 192 | Pending |
| CI-03 | Phase 192 | Pending |
| CI-04 | Phase 192 | Pending |
| CLOSE-01 | Phase 193 | Pending |

**Coverage:**

- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-07-01*
*Last updated: 2026-07-01 after v1.39 milestone initialization*
