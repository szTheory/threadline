# Phase 94: authority-surface-reconciliation-and-closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `94-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 94-authority-surface-reconciliation-and-closeout
**Areas discussed:** Authority hierarchy, Claim wording scope, Closeout bar, Deferred cleanup boundary

---

## Authority hierarchy

| Option | Description | Selected |
|--------|-------------|----------|
| Split authority by concern | `ROADMAP.md` as active contract, milestone audit as closeout gate, `STATE.md` as execution snapshot, `PROJECT.md` as narrative | ✓ |
| Audit-led SSOT | Promote milestone audit to single source of milestone truth | |
| Contract-plus-state | Keep roadmap central and treat audit as supporting findings | |
| Narrative-led current-state | Let `PROJECT.md` carry current truth with other files supporting | |

**User's choice:** One-shot recommendation accepted; use split authority by concern.
**Notes:** This matched Phase 80 precedent, Phase 89 context, and the repo's established distinction between public contract/proof surfaces and maintainer truth surfaces.

---

## Claim wording scope

| Option | Description | Selected |
|--------|-------------|----------|
| Exact proven-set claim in each authority surface | Repeat one exact clause naming the mounted support-visible set and export posture | ✓ |
| Bounded summary + exact set only in `guides/upgrade-path.md` | Keep top-level surfaces lighter and rely on the matrix guide for specifics | |
| Persona/capability matrix | Introduce a support/admin/denied matrix across docs | |
| Broad “support-safe `/audit` lane” wording | Use high-level shorthand without enumerating exact proven pages | |

**User's choice:** One-shot recommendation accepted; use one exact proven-set clause.
**Notes:** The coherent recommendation was to name timeline, actor, transaction, support-scoped row history / as-of, and export denial posture directly, while keeping coverage/policy admin-global or unsupported for support scopes.

---

## Closeout bar

| Option | Description | Selected |
|--------|-------------|----------|
| Authority-only reconciliation + re-audit | Reconcile the most stale authority files and rerun the milestone audit | |
| Bounded truth-bundle closeout | Reconcile authority surfaces, refresh active traceability files where truth changes, then rerun the audit | ✓ |
| Full release-closeout sweep | Expand Phase 94 into broader release/RC readiness work | |

**User's choice:** One-shot recommendation accepted; use bounded truth-bundle closeout.
**Notes:** This keeps proof and active planning surfaces moving together and closes `DOC-01` / `DOC-02` honestly instead of relying on audit prose alone.

---

## Deferred cleanup boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Authoritative-only reconciliation | Touch only milestone-truth surfaces and leave stale narrative docs alone | |
| Authoritative reconciliation + targeted stale-narrative patch | Reconcile truth surfaces and make one narrow crash-course-doc correction | ✓ |
| Broad public-doc sweep | Expand Phase 94 into a larger doc-refresh pass | |
| Planning-only reconciliation with explicit defer note | Fix planning truth only and record the public-doc drift for later | |

**User's choice:** One-shot recommendation accepted; reconcile the authority layer and include one narrow patch to `guides/how-threadline-works.md`.
**Notes:** The selected approach preserves layered authority, avoids broad editorial churn, and prevents a first-time reader from hitting stale future-tense claims about already-shipped governance/export capabilities.

---

## the agent's Discretion

- Exact phrase choice for the repeated proven-set claim
- Exact sequencing of roadmap/requirements/state/project/audit updates
- Exact framing of the narrow `guides/how-threadline-works.md` correction

## Deferred Ideas

- Audit-led single-file milestone SSOT
- Persona/capability matrix expansion
- Broad public-doc sweep
- Full release-closeout / RC-style operational pass
- Turning `guides/how-threadline-works.md` into a contract or support-matrix authority
