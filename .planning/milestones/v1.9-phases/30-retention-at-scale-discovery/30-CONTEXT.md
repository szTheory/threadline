# Phase 30: Retention at scale & discovery - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **SCALE-01** and **SCALE-02** (`.planning/REQUIREMENTS.md`):

- **SCALE-01:** `guides/production-checklist.md` gains explicit **volume / growth** guidance tied to shipped retention APIs — **`Threadline.Retention.Policy`**, **`Threadline.Retention.purge/1`**, **`mix threadline.retention.purge`** — including **cadence thinking**, **what to monitor** (table growth, purge duration), and **how this connects** to **export**, **timeline**, and **support incident** narratives already documented.

- **SCALE-02:** **README** and/or **`guides/domain-reference.md`** includes a **short discovery pointer** (one paragraph + link) so operators find v1.9 at-scale material without spelunking.

**Out of scope (unchanged):** New retention semantics; LiveView operator UI; duplicating Phase 28 telemetry tables or Phase 29 indexing matrices outside their canonical homes; new doc-contract scope beyond what planning explicitly adds.

</domain>

<decisions>
## Implementation Decisions

Discussion ran **four parallel research subagents** (checklist IA, API surface in checklist, export/timeline/support linkage, discovery hub), then **one maintainer-directed cohesive synthesis** so all choices stay mutually consistent with **Phase 28** (checklist vs domain-reference split) and **Phase 29** (indexing only in `guides/audit-indexing.md`).

### D-1 — Checklist IA for volume / growth (SCALE-01)

- **Use hybrid placement:** add a dedicated **`### Volume, growth, and purge cadence`** **inside** existing **`## 4. Retention and purge`**, **after** the current §4 gate bullets (config, dry-run, `--execute`, batch/backups, link to `audit-indexing.md`).
- **Do not** insert a new numbered top-level section between §4–§7 — avoids renumbering and preserves stable **`#6-observability`** (and related) anchors from Phase 28.
- **Do not** append “volume” only after §7 — breaks the operator story (capacity sits with retention/purge).
- **Rationale:** One operational story under §4; grep-friendly H3; matches Oban/Ecto-style “lifecycle-adjacent” grouping and K8s-style runbooks without splitting purge from growth signals.

### D-2 — Retention API surface in the checklist (SCALE-01)

- **Hybrid (link-aware, not link-only):** Keep **literal** `mix threadline.retention.purge` (dry-run + execute paths) and **`config :threadline, :retention`** next to **gates** and **`MIX_ENV`** where operators type commands.
- **Name once per narrative spine:** **`Threadline.Retention.Policy`** and **`Threadline.Retention.purge/1`** as the **programmatic / automation** entry points — one clear bullet or table-adjacent line, not repeated on every line.
- **Defer semantics** (cutoff clock, empty parents, what rows delete) to **`guides/domain-reference.md`** retention section + HexDocs `Threadline.Retention` — **no second copy** of Phase 13 prose in the checklist.
- **Rationale:** Satisfies REQ “explicit ties to shipped APIs” without triple drift (checklist / domain-reference / `@moduledoc`); matches idiomatic Hex split (extras = gates + when + links; moduledoc = options/returns).

### D-3 — Export, timeline, and support playbooks (SCALE-01)

- **Spine = short prose in §4 under the new H3 (D-1):** 2–3 sentences max stating that **retention bounds the historical corpus** that Q1–Q5, timeline, and export can still see; **golden SQL and filter vocabulary stay in `domain-reference.md`** only.
- **Minimal B-style accents:** add **one sentence** to the **intro** block above **Support incident queries** so incident-first readers see the dependency even if they skip §4.
- Add **one bullet** (or sub-bullet) under **`## 5. Export and investigation`** tying `:from`/`:to`, `max_rows` / streaming, and **correlation** work to “data must still exist after purge windows — align with §4.”
- **Optional refinement:** a **single** short clause in the support **table** for **Q3** and/or **Q4** only (correlation + export parity) — avoid identical footnotes on all five rows.
- **Do not** add a standalone “bridge” H2 (avoids extra anchor churn and mini-spec duplication); **do not** rely on §4-only linkage (incident readers miss it).
- **Rationale:** SRE runbook ↔ playbook linking and AWS Well-Architected-style cross-pillar one-liners; SQL-native Threadline keeps **one home for the decision (§4)**, thin hooks where operators already stand (support, export).

### D-4 — Discovery pointer and hub (SCALE-02)

- **Add a short stable H2 in `guides/domain-reference.md`** — working title **`## Operating at scale (v1.9+)`** — whose body is **orientation + links only** (no new telemetry tables, no indexing DDL).
  - Link to existing **Telemetry** + **Trigger coverage (operational)** anchors.
  - Link to **`guides/audit-indexing.md`** (cookbook).
  - Link to **`guides/production-checklist.md`** with a **stable fragment** to the §4 volume H3 from D-1 (implementer: align heading text and anchor once; prefer explicit HTML `id=` if slug stability across ExDoc/GitHub is uncertain).
- **README:** add **one paragraph** in a **high-visibility** slot (same band as Maintainer checks / operator path — **not** buried below installation only), linking to the **new domain-reference hub** as the **single handoff** for “where v1.9 put hard prod material.”
- **Do not** duplicate Phase 28 narrative or Phase 29 matrices in README; **do not** create a separate composite “v1.9 hub” markdown file unless a later phase explicitly scopes it.
- **Rationale:** Hybrid hub (README routing + domain-reference TOC) matches Oban/Ash-style Hex discovery; one map paragraph avoids CTA fatigue; GitHub- and HexDocs-first readers both get a clear front door.

### D-5 — Cross-cutting coherence

- **Single narrative:** “Install + APIs are necessary but not sufficient → **hub** lists telemetry, indexing cookbook, checklist volume/retention → each topic has **one** canonical depth home.”
- **Implementation order hint:** land **stable §4 H3 title + hub H2 title** early so README and cross-links can target stable fragments; optional **light** doc-contract literal on hub spine later if CI should prove the map did not disappear (default **not** LOOP-04-heavy unless planning expands).

### Claude's Discretion

- Exact subsection titles within the agreed H2/H3 names; minimal Q3/Q4 table wording if optional row tweaks feel noisy on review.
- Whether to add one **marker string** inside the hub (grep/release-notes) after first draft — default **only if** it reduces anchor fragility without duplicating prose.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap

- `.planning/REQUIREMENTS.md` — **SCALE-01**, **SCALE-02**
- `.planning/ROADMAP.md` — v1.9 Phase 30 success criteria (items 5–6)
- `.planning/PROJECT.md` — v1.9 goals, docs-first, non-goals

### Prior phase context (IA constraints)

- `.planning/milestones/v1.9-phases/28-telemetry-health-operators-narrative/28-CONTEXT.md` — checklist vs domain-reference; §6 observability anchors
- `.planning/milestones/v1.9-phases/29-audit-table-indexing-cookbook/29-CONTEXT.md` — `audit-indexing.md` as sole index depth; README one-liner deferred to Phase 30

### Current operator surfaces (edit targets)

- `guides/production-checklist.md` — §4–§6, Support incident queries
- `guides/domain-reference.md` — retention, telemetry, support anchors; new hub H2
- `guides/audit-indexing.md` — linked from checklist + hub, not duplicated
- `README.md` — single discovery paragraph (SCALE-02)

### Code & tasks (behavior must match prose)

- `lib/threadline/retention.ex` — `purge/1`, batching, policy interaction
- `lib/threadline/retention/policy.ex` — validation surface
- `lib/mix/tasks/threadline.retention.purge.ex` — flags, `MIX_ENV`, `--dry-run` / `--execute`
- `lib/threadline/query.ex` / `lib/threadline/export.ex` — timeline/export filters (cross-link accuracy for D-3)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **§4–§6 and Support table** in `guides/production-checklist.md` — extend in place; deep links to `domain-reference.md` already established (Phase 28).
- **`guides/domain-reference.md` retention + telemetry** — canonical semantics for D-2 deferral.
- **`guides/audit-indexing.md`** — retention/delete access patterns; link-only from SCALE-01 checklist body.

### Established patterns

- **Checklist = gates + when + links**; **domain-reference = interpretation + vocabulary**; **cookbook = DDL-shaped optional tuning** (Phases 28–29).

### Integration points

- README → new domain-reference hub → checklist §4 H3 + existing sections; no third copy of telemetry or indexing.

</code_context>

<specifics>
## Specific Ideas

- Research synthesis favored **Oban / Ecto / K8s operator** patterns: lifecycle-adjacent grouping, runbook-to-playbook links, Hex “extras + moduledoc” split.
- Discovery: **README one paragraph + domain-reference hub H2** (not README-only hub — avoids duplicating guide lists; not hub-only in domain-reference without README — misses GitHub-first readers).

</specifics>

<deferred>
## Deferred Ideas

- **New top-level checklist section** renumbering §5–§7 — deferred unless a future phase explicitly accepts anchor migration cost.
- **Standalone `volume-at-scale.md` guide** — only if checklist + hub prove insufficient; not in v1.9 Phase 30 scope.
- **PromQL / vendor dashboards** as canonical in-repo — remains deferred per Phase 28.

</deferred>

---

*Phase: 30-retention-at-scale-discovery*  
*Context gathered: 2026-04-24*
