---
phase: "06"
slug: ci-on-github
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-23
---

# Phase 06 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Local developer machine ↔ GitHub Actions | CI truth vs local `mix ci.all` must agree on compile strictness and job semantics. | Build/config signals; no production secrets in this phase. |
| Public docs (README, CONTRIBUTING) ↔ canonical repository | URLs and job names must point at `szTheory/threadline` and stable workflow keys. | Public URLs; maintainer-run `gh` proof deferred to CI-02 human checklist. |
| Planning artifacts ↔ implementation | `06-VERIFICATION.md` records how maintainers confirm live Actions without badge-only trust. | Operational evidence placeholders. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-06-01-01 | Tampering (config drift) | `.github/workflows/ci.yml` | mitigate | Stable `jobs:` keys `verify-format`, `verify-credo`, `verify-test`; contract enforced by plan greps and verified in repo. | closed |
| T-06-01-02 | Repudiation / false assurance | GitHub Actions triggers | mitigate | `push` and `pull_request` scoped to `branches: [main]` in `ci.yml`. | closed |
| T-06-01-03 | Inconsistency | `mix.exs` aliases | mitigate | `"ci.all"` runs `compile --warnings-as-errors` before `verify.test`, matching `verify-test` job order. | closed |
| T-06-02-01 | Spoofing / misdirection | `README.md`, `CONTRIBUTING.md` | mitigate | URLs include `github.com/szTheory/threadline` and Actions paths per plan; verified by grep/read. | closed |
| T-06-02-02 | Repudiation (wrong maintainer record) | `06-VERIFICATION.md` | mitigate | Document requires literals `ci.yml`, `verify-format`, `verify-credo`, `verify-test`, and specified `gh` commands. | closed |

*Status: open · closed*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-23 | 5 | 5 | 0 | gsd-secure-phase (Phase 06) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-23
