# Phase 20: first-external-pilot - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>
## Phase Boundary

Execute **ADOP-03**: one **external** host team runs [`guides/production-checklist.md`](../../../guides/production-checklist.md), records **`OK` / `Issue` / `N/A` / `Not run`** plus **evidence** (logs, SQL, PR, or issue links) in [`guides/adoption-pilot-backlog.md`](../../../guides/adoption-pilot-backlog.md), and triages every **`Issue`** row into a **GitHub issue** or a **scoped v1.6 requirement** with a stable link back. Update [`.planning/REQUIREMENTS.md`](../../REQUIREMENTS.md) traceability when satisfied.

This phase is **process and evidence**, not new library APIs or LiveView. In-repo code changes are limited to **documentation / backlog table updates** and **planning artifacts** unless a pilot-proven defect requires a hotfix (out of normal scope for v1.5).

</domain>

<decisions>
## Implementation Decisions

### Evidence workflow (where outcomes live)

- **D-01:** The **system of record** for ADOP-03 is the **canonical** [`guides/adoption-pilot-backlog.md`](../../../guides/adoption-pilot-backlog.md) on **`main`** after merge. Prefer a **PR** (host or maintainer) that updates matrix rows; **fork-only** is acceptable only as a **draft** on the path to merge.
- **D-02:** **Large or sensitive** evidence (long logs, full SQL traces) goes in **GitHub issues** (or maintainer-reviewed attachments); the backlog **Evidence** column holds **short redacted snippets + stable links**. **Gists** are optional supplements, not the sole narrative. **Private host packet → maintainer PR** is allowed when policy forbids direct host PR, but the **merged** guide must reflect final `OK` / `Issue` / `N/A` states.
- **D-03:** Do **not** treat Slack/email alone as completion; rows in the shipped guide must reflect reality. Avoid **unstable** or **internal-only** URLs in the public file.

### Pilot environment bar (credibility for trigger + GUC semantics)

- **D-04:** **Pure local dev** (single long-lived `iex`, no pooler, no realistic job runner) is **insufficient** as the only environment for this pilot—it **overfits** session semantics and under-tests **PgBouncer transaction mode** and **job transactions**.
- **D-05:** **Minimum credible bar:** a **host-owned shared environment** (staging or production-like) where the app hits PostgreSQL through the **same connection topology class as production**—especially **PgBouncer mode** (transaction vs session) **documented and matched** when production uses PgBouncer. Exercise at least **one HTTP write path** and **one job path** (Oban/async) where jobs are in scope, per checklist sections 1–2.
- **D-06:** If staging **cannot** match prod pooler mode, record **`Issue`** or **`N/A` with explicit false-confidence risk** and either add a **small prod-like pooler** slice or track a **follow-up canary**—do not imply parity without evidence.
- **D-07:** ADOP-03 requires **at least one** section with **`OK` or `Issue`** plus evidence—not a fully green matrix.

### Triage and issue hygiene

- **D-08:** Every **`Issue`** row must resolve to **exactly one** of: (a) **GitHub issue** (reproducible library defect or doc bug), (b) **scoped v1.6 requirement** (product intent, acceptance criteria, owner—link from backlog), or (c) **reclassified** to **`OK` / `N/A`** with evidence if it was **host misconfiguration** or **internal policy** (no Threadline issue).
- **D-09:** Use **stable backlog IDs** in titles and links—pattern **`AP-<section>.<row>`** aligned to checklist sections (e.g. `AP-3.2` for section 3, second row). Reuse the same ID when promoting a line into the **Prioritized issues** table.
- **D-10:** New GitHub issues from the pilot should follow a **short template**: backlog ID + row anchor + versions (`threadline`, Elixir/OTP, PostgreSQL) + PgBouncer notes + current vs expected + redacted repro + duplicate-check checkbox. Labels: **`adoption-pilot`**, **`triage`**, area (`capture`, `semantics`, `redaction`, `retention`, `export`, `observability`, `continuity`, `docs`), severity **`priority:p0` / `priority:p1`** per backlog guidance.
- **D-11:** Maintainer **first triage response** states reproducibility (reproduced / needs info / not a bug) and removes **`triage`** or requests the **single smallest** missing artifact—avoid opaque “audit failed” narratives without queries or versions.

### Completion and verification

- **D-12:** **Verification:** host integrator sign-off + maintainer review of the **merged** backlog update; **REQUIREMENTS.md** ADOP-03 row set to **Complete**; then **`/gsd-transition`** or project milestone close per habit.
- **D-13:** **Cohesion with v1.5 intent:** no API expansion in this phase; pilot pain feeds **issues / v1.6 requirements** only—consistent with **integrator-led** sequencing in [`.planning/PROJECT.md`](../../PROJECT.md).

### Claude's Discretion

- None for this pass — user delegated to the **recommended package** above (research-synthesized).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- [`.planning/REQUIREMENTS.md`](../../REQUIREMENTS.md) — **ADOP-03** acceptance wording and traceability table
- [`.planning/ROADMAP.md`](../../ROADMAP.md) — Phase 20 goal and milestone **v1.5** scope
- [`.planning/PROJECT.md`](../../PROJECT.md) — Vision, **PgBouncer / Logidze** lesson, integrator-led v1.5, OSS quality bar

### Operator and pilot artifacts

- [`guides/adoption-pilot-backlog.md`](../../../guides/adoption-pilot-backlog.md) — Matrix to fill; distribution preflight; prioritized issues table
- [`guides/production-checklist.md`](../../../guides/production-checklist.md) — Source checklist for section mapping
- [`guides/domain-reference.md`](../../../guides/domain-reference.md) — Telemetry anchor (section **Telemetry (operator reference)**) for observability rows

### Existing phase plan (replan after this context)

- [`.planning/phases/20-first-external-pilot/PLAN.md`](PLAN.md) — Prior objective/success criteria; **replace or extend** after `/gsd-plan-phase 20` so tasks align with decisions **D-01–D-13**

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **[`guides/adoption-pilot-backlog.md`](../../../guides/adoption-pilot-backlog.md)** — Pre-structured tables for **Distribution preflight**, **Checklist walkthrough** (sections 1–7), **In-repo parity**, and **Prioritized issues**; hosts edit Status/Evidence columns in place.
- **[`guides/production-checklist.md`](../../../guides/production-checklist.md)** — Section headings map 1:1 to backlog groups (capture, actor bridge, redaction, retention, export, observability, brownfield).
- **Library surfaces the pilot exercises** (for planner cross-links, not new code in this phase): `Threadline.Plug`, `Threadline.Job`, `Threadline.Health.trigger_coverage/1`, retention purge mix tasks, export/timeline filters—documented in guides and ExDoc.

### Established patterns

- **Hex package** ships `guides/` in the tarball; hosts consume **`{:threadline, "~> 0.2"}`** per distribution preflight row.
- **CI truth:** in-repo `mix ci.all` / PostgreSQL integration tests prove library behavior; **pilot** proves **host topology** (pooler, jobs, realistic transactions)—backlog already states CI does not replace the host pilot.

### Integration points

- **GitHub** — Issues receive triaged `Issue` rows; labels and templates should match **D-09–D-11**.
- **[`.planning/REQUIREMENTS.md`](../../REQUIREMENTS.md)** — ADOP-03 checkbox and traceability table updated on completion.

</code_context>

<specifics>
## Specific Ideas

- Research synthesis (parallel agents) favored: **merged PR to canonical backlog** + **GitHub issues for depth**; **staging acceptable** if **pooler/job parity** with production is explicit; **AP-* IDs** and **repro-first** triage matching small OSS Elixir norms (Oban/Req-style structured issues).
- **Non-goals for this phase:** new capture semantics, LiveView UI, umbrella split—per PROJECT / REQUIREMENTS out-of-scope lists.

</specifics>

<deferred>
## Deferred Ideas

- **GitHub issue forms / `.github/ISSUE_TEMPLATE`** for `adoption-pilot` — helpful hardening; not required to satisfy ADOP-03 if maintainers paste the template manually until a follow-up phase.
- **Automated Hex publish** — remains out of scope per REQUIREMENTS.

### Reviewed Todos (not folded)

- None from `todo.match-phase` for phase 20.

</deferred>

---

*Phase: 20-first-external-pilot*  
*Context gathered: 2026-04-23*
