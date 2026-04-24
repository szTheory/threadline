# Phase 20 — First external pilot

**Milestone:** v1.5  
**Requirement:** ADOP-03  
**Context:** [20-CONTEXT.md](20-CONTEXT.md) (decisions D-01–D-13)

## Objective

One **external** host completes a **credible** pilot (see **Environment bar** below), updates [`guides/adoption-pilot-backlog.md`](../../../guides/adoption-pilot-backlog.md) on **`main`** via merge, triages every **`Issue`** row, and satisfies **ADOP-03** traceability in [`.planning/REQUIREMENTS.md`](../../REQUIREMENTS.md).

## Environment bar (from context)

- **Not sufficient:** pilot only on **pure local dev** (no pooler / unrealistic job + HTTP paths).
- **Minimum:** **shared staging** (or production-like) with **connection topology class matching production** (especially **PgBouncer transaction vs session** documented and matched when prod uses PgBouncer).
- **Paths to prove:** at least **one HTTP audited write** and **one job path** (Oban/async) where jobs apply.
- If staging cannot match prod pooler: record **`Issue`** or **`N/A`** with explicit **false-confidence risk** and a tracked follow-up.

## Task checklist (maintainer + host)

1. **Preflight** — Confirm distribution rows (Hex version, `{:threadline, "~> 0.2"}`, `mix deps.get`) per backlog **Distribution preflight**; host records status + evidence.
2. **Walk checklist** — Host runs [`guides/production-checklist.md`](../../../guides/production-checklist.md); for each backlog section 1–7, set **`OK` / `Issue` / `N/A` / `Not run`** with evidence or stable links (D-01–D-03, D-07).
3. **Topology row** — Explicit note: app → pooler? → Postgres; **PgBouncer mode** if any; “matches prod: yes/no/partial” (D-05–D-06).
4. **Evidence PR** — Open PR updating `guides/adoption-pilot-backlog.md` (host or maintainer after private handoff); ensure **merge to `main`** for canonical record (D-01–D-02).
5. **Triage `Issue` rows** — For each: GitHub issue **or** scoped v1.6 requirement **or** reclassify to OK/N/A with rationale (D-08). Use **`AP-<section>.<row>`** IDs and the issue body shape in **D-10**; labels **`adoption-pilot`**, **`triage`**, area, severity (D-09–D-11).
6. **Prioritized table** — Add rows for discovered gaps; link out to issues; P0/P1 per backlog legend.
7. **Maintainer review** — Review merged backlog for redaction, link stability, and triage completeness (D-12).
8. **Close ADOP-03** — Set ADOP-03 to **Complete** in **REQUIREMENTS.md** traceability; on `main`, run **`/gsd-execute-phase 20`** so verification and roadmap completion run; then milestone close per project habit (D-12).

## Success criteria

1. Merged **`guides/adoption-pilot-backlog.md`** reflects pilot with **at least one** section **`OK` or `Issue`** + evidence (or issue link), per ADOP-03.
2. Every **`Issue`** row has a **GitHub** or **v1.6** link, or was reclassified with evidence (D-08).
3. **REQUIREMENTS.md** updated; no dangling **`Issue`** without an exit.
4. Environment meets **Environment bar** above (D-04–D-06).

## Risks

- **PgBouncer transaction mode** — false confidence if pilot bypasses transaction pooling (see CONTEXT + PROJECT.md).

## Verification

- Maintainer sign-off on merged backlog + triage links.
- Optional: `mix verify.doc_contract` if backlog/README anchors change.

## GSD execute-phase preflight

- **`gsd-sdk query state.begin-phase`** — use **positional** arguments: `gsd-sdk query state.begin-phase 20 first-external-pilot 1`. A `--phase` / `--name` flag form **corrupts** `.planning/STATE.md` with some `gsd-sdk` builds.
- Run **`/gsd-execute-phase 20`** only after **ADOP-03** evidence exists on `main` (checklist + `REQUIREMENTS.md`); earlier runs should expect **`gaps_found`** in `20-VERIFICATION.md`, not phase completion.
