# Phase 8 — Technical research: Publish main & verify CI

**Phase:** 8 — Publish main & verify CI  
**Gathered:** 2026-04-23  
**Question answered:** What do we need to know to plan gap closure for REPO-03, CI-01–CI-03?

## Executive summary

Phase 8 is **operations and evidence alignment**, not feature code. The v1.1 milestone audit (`.planning/v1.1-MILESTONE-AUDIT.md`) shows: **`origin/main` lags local `main`**, **CI-02** (green GitHub Actions for the same SHA as `origin/main`) is unsatisfied, and **REQUIREMENTS.md** checkboxes / traceability rows are out of sync with in-repo evidence for CI-01 and CI-03. Phase 6 summaries used the label **CI-02** for *local* `mix ci.all` parity while `REQUIREMENTS.md` defines **CI-02** as a **live GitHub** success — that ambiguity must be resolved in documentation, not by redefining the requirement.

## Phase boundary (from ROADMAP + audit)

**In scope**

- Push `main` to `origin` until `git rev-parse main` equals `git rev-parse origin/main` after fetch (**REPO-03**).
- Obtain and record a green **`ci.yml`** run for that SHA with jobs **`verify-format`**, **`verify-credo`**, **`verify-test`** all succeeding (**CI-02** per REQUIREMENTS).
- Confirm **CI-01** contract still holds (workflow file unchanged unless broken); update REQUIREMENTS / traceability to reflect verified truth (**CI-01** alignment).
- Confirm **CI-03** contributor documentation still matches Actions URL and job keys; update REQUIREMENTS checkboxes (**CI-03** alignment).
- Reconcile **06-01-SUMMARY.md** / **06-02-SUMMARY.md** frontmatter so they do not claim canonical **CI-02** completion while **06-VERIFICATION.md** leaves live CI-02 open.

**Out of scope**

- Hex publish, version bumps, tags (**Phase 7**, **HEX-***).
- CI workflow definition changes unless a push proves the workflow is broken (unlikely).

## Authoritative references

| Artifact | Role |
|----------|------|
| `.planning/REQUIREMENTS.md` | REQ definitions and checkboxes |
| `.planning/v1.1-MILESTONE-AUDIT.md` | Gap list and integration IDs |
| `.planning/phases/06-ci-on-github/06-VERIFICATION.md` | Maintainer SHA / run URL placeholders for CI-02 |
| `.github/workflows/ci.yml` | Job keys and `main` triggers (CI-01) |
| `README.md`, `CONTRIBUTING.md` | CI-03 evidence paths |

## Technical notes

### Git / REPO-03

- Standard close-out: `git fetch origin main` then `git push origin main` (requires network + credentials).
- Verification: after push, `git rev-parse main` and `git rev-parse origin/main` must match.

### GitHub Actions / CI-02

- Repository from audit: `szTheory/threadline` (confirm with `git remote get-url origin`).
- Preferred automation: GitHub CLI — `gh run list --repo … --workflow=ci.yml --branch=main --limit 5` then `gh run view RUN_ID --json conclusion,headSha,url` until `conclusion` is `success` and `headSha` matches `origin/main`.
- UI alternative: open Actions tab, confirm all three jobs green on the commit matching `origin/main`.

### CI-01 / CI-03

- No code change expected; **grep-based acceptance** from Phase 6 still applies. Phase 8 only updates **human-facing checklists** once evidence is refreshed after push.

### Traceability / SUMMARY correction

- **06-01** should claim **CI-01** and *local CI parity related to CI-02 reproducibility* but not list canonical **CI-02** in `requirements-completed` until GitHub proof exists (or use explicit wording in `provides` vs REQ IDs).
- **06-02** should not list **CI-02** in `requirements-completed` until closed; it correctly delivered **CI-03** and maintainer checklist *structure*.

## Risks

| Risk | Mitigation |
|------|------------|
| Push rejected (permissions, branch protection) | Plan marks push task `autonomous: false`; capture error in SUMMARY. |
| Actions failing on pushed HEAD | Stop checklist updates; file failure evidence; do not mark CI-02 satisfied. |
| Stale audit numbers (e.g. “19 commits ahead”) | Plans use commands that compute drift at execution time, not hard-coded SHAs. |

---

## Validation Architecture

This phase is **mostly manual / network-bound** with **automated spot-checks** where possible.

| Dimension | Approach |
|-----------|----------|
| **Automated** | `grep` CI-01 job keys and `main` triggers; `MIX_ENV=test mix ci.all` optional health check before/after push (no DB schema changes). |
| **Manual / maintainer** | Git push; wait for Actions; paste SHA and run URL into `06-VERIFICATION.md`; `gh` JSON confirmation. |
| **Documentation** | REQUIREMENTS checkboxes and traceability table; SUMMARY frontmatter YAML. |

**Nyquist:** Sampling is thin because there is little code churn — each plan wave ends with deterministic greps plus one documented human gate (CI-02).

---

## RESEARCH COMPLETE

Plans can proceed with: (1) push + REPO-03 proof, (2) GitHub CI-02 capture + REQUIREMENTS + Phase 6 artifact reconciliation.
