# Phase 110: Triage + Narrow Fixes - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Apply the fix-vs-defer rule from FINDINGS-01 to every finding under `.planning/v1.23/findings/`: ship **(a)** breakage, in-budget **(b)** DX papercuts, and **(c)** doc gaps in this milestone; route **(d)** design gaps and over-budget **(b)** papercuts to `.planning/v1.24-seeds/` with rationale. No scope widening beyond what findings (and confirmed 108-REVIEW pre-registrations) justify.

Scope guard: `examples/` and `guides/` freely; `lib/threadline/**` only for **(a)** findings with concrete walkthrough evidence pointing at library code; every `lib/` commit cites finding ID + walk step + layer (capture | semantics | exploration).

Requirements: FIX-01, FIX-02, FIX-03, DEFER-01.

**Phase 110 complete ≠ RUN green on first pass.** Completion means every filed finding is fixed or explicitly deferred; a **validation re-walk** on a post-fix isolated clone attests RUN-01/02/03 (109 stopped at §1 gate with one **(a)** finding).

</domain>

<decisions>
## Implementation Decisions

### Fix ordering — three-wave playbook (D-110-01)

- **D-110-01a:** **Wave 1 (plan 110-01):** Fix **only finding 0001** (`landing-500-badmap`) — nil-safe `@current_scope` in `PageHTML.home/1` (or equivalent host wiring). Commit message cites `finding 0001` / `WALK-01-04`. Update finding frontmatter: `status: fixed`, `fixed_in: <sha>`. Run **L0** smoke (`curl` → 200; logged-out home ConnCase if present) + **L1** `mix ci.all`.
- **D-110-01b:** **Wave 2 (plan 110-02):** After Wave 1 green, **promote WR-001 / WR-002 via confirmed pre-registration** — create finding files **0002** (WR-002) and **0003** (WR-001) with Evidence = 108-REVIEW reproduction + minimal post-0001 spot-check (CLI stderr one-liner; optional 5-minute WALK-03-02 filter check). **Do not** re-walk broken CLI/prose solely to re-prove what 108-REVIEW already documented — Phase 109 observe discipline is satisfied; Phase 110 triage uses review-grade static repro plus spot-check.
- **D-110-01c:** **Wave 2 fixes (same plan):** WR-002 **(c)** — replace WALK-03-03 step 5 with canonical `mix threadline.evidence.show --subject … --subject-ref-json '…'` from WALK-04-01; extend `walkthrough_doc_contract_test` if literals added. WR-001 **(c)** — align WALK-03-02 operator window to **`demo_last_tuesday` → `demo_epoch`** (do **not** move seed timestamps); add `demo_contract_test` describe for agent2 rows in documented bounds. Optional same-plan **IN-001** maintainer-voice cleanup in `WALKTHROUGH.md` §0 (≤1 narrow plan budget).
- **D-110-01d:** **Wave 3 (plan 110-03 or re-walk sub-plan):** **Validation re-walk** on fresh isolated clone at `RE_WALK_BASELINE_SHA` (post-Wave-2 SHA). Resume from **WALK-01-04** through §5 (L2 minimum); full §0–§5 (L3) if bootstrap drift appears on fix SHA. Log in `110-RE-WALK-LOG.md`. **Validation mode** — fixes already landed; file **new** findings only for surprises. **Not** a second observe-only Phase 109 pass.
- **D-110-01e:** **Reject** batch-fixing WR items before 0001 (blocks honest §1 gate narrative). **Reject** partial re-walk from §2 without re-proving WALK-01-04 on fix SHA. **Reject** walking broken WR steps in validation re-walk on purpose.

### Pre-registered findings WR-001 / WR-002 (D-110-02)

- **D-110-02a:** Treat 108-REVIEW WR-001/WR-002 as **confirmed pre-registrations** in Wave 2 — not silent edits (Option A) and not blocked until full re-walk (Option C).
- **D-110-02b:** File as **0002** (WR-002, class **c**) and **0003** (WR-001, class **c** — prose contradicts seed; operator wrong-answer symptom but fix surface is docs + contract test only). Include `Classification note: Pre-registered 108-REVIEW WR-00N; reproduced 108-REVIEW; Phase 109 blocked before WALK-03-0N.`
- **D-110-02c:** WR-001 fix: **doc-only**, anchor window to `demo_last_tuesday` (`2026-05-20T14:30:00Z`) through `demo_epoch` — consistent with WALK-03-01 / §4 footnote. WR-002 fix: **doc-only**, match §5 flag style. No `lib/` changes.
- **D-110-02d:** After Wave 2, mark 0002/0003 `status: fixed` with `fixed_in:` SHAs. Validation re-walk confirms RUN-02/03 and catches **new** surprises only.

### (b) DX papercut budget — “≤1 narrow plan” (D-110-03)

- **D-110-03a:** **Primary unit = one GSD plan file** (`110-NN-PLAN.md`). A **(b)** finding ships in Phase 110 only if **all** gates pass:

  | Threshold | Limit |
  |-----------|-------|
  | Plan files | **1** |
  | Tasks per plan | **≤3** |
  | Files touched | **≤5**, under `examples/`, `guides/`, or `.planning/` only |
  | `lib/threadline/**` | **0** (unless reclassified **(a)**) |
  | New capabilities | **0** (no Evidence subjects, migrations, operator features) |
  | Verification | Existing `mix verify.*` / `mix ci.all`; doc-contract extension OK in same plan |
  | Commits | **1–2 atomic**, each citing finding ID(s) |

- **D-110-03b:** **Moderate bundling:** multiple **(b)** findings may share one plan only if they share **one bounded objective** (e.g. “WALKTHROUGH maintainer voice cleanup”). Do **not** batch unrelated surfaces (UI label + manifest accessor + new contract suite).
- **D-110-03c:** **30-second triage checklist** after classifying **(b):** (1) reclassify? (2) `lib/` or cross-repo coupling? → defer (3) one plan title without “and also”? (4) ≤3 tasks, ≤5 files? (5) new verify alias needed? → defer
- **D-110-03d:** **IN-001** (stale GSD labels in WALKTHROUGH §0): **fix in Phase 110** — single-file voice cleanup; fold into Wave 2 plan if combined objective stays within gates; else standalone 110-04.
- **D-110-03e:** **IN-002 / IN-003 / IN-004** from 108-REVIEW: route separately — WR-001 contract test belongs with 0003 **(c)** plan; manifest accessor / multi-file work defer if over budget.

### `lib/` touch bar (D-110-04)

- **D-110-04a:** **Moderate policy** (ROADMAP FIX-01) with **layer-first gate** — run checklist before any `lib/threadline/**` edit:

  1. Classification **(a)** with Expected/Actual/Evidence filled
  2. Stack trace or wrong audit answer originates in **`lib/threadline/`** (not `examples/`, Sigra, host HEEx)
  3. Failure = crash, wrong answer, or security regression
  4. Repro is walkthrough-faithful (WALK-NN-NN, clean clone, cited SHA)
  5. Fix **repairs** shipped capture/semantics/exploration — not new auth/RBAC/tenancy DSL/Evidence subject
  6. Minimal diff; commit cites `finding NNNN`, walk step, layer

- **D-110-04b:** **0001 disposition:** fix in **`examples/threadline_phoenix/` only** — nil `@current_scope` is host-owned Sigra/landing wiring (Rails engine analogue: host app owns layout/landing; library owns `/audit` mount). **Zero `lib/` commits** expected for current inventory.
- **D-110-04c:** **Explicit rejects for Phase 110 `lib/`:** nil landing scope, signup polish, help-desk domain bugs, “default auth plug in Threadline,” speculative library gaps without walk evidence.

### Post-fix verification ladder (D-110-05)

- **D-110-05a:** **L0 — per-fix smoke:** immediately after each fix commit (`curl` 200 for 0001; CLI one-liner for WR-002; optional filter spot-check for WR-001). Satisfies **FIX-01** for that finding.
- **D-110-05b:** **L1 — CI gate:** `mix ci.all` before marking any Phase 110 plan complete.
- **D-110-05c:** **L2 — validation re-walk (required for v1.23 RUN acceptance):** fresh clone at post-Wave-2 SHA; `110-RE-WALK-LOG.md`; WALK-01-04 → §5. Promote to **L3** full §0–§5 if §0–§3 bootstrap differs on fix SHA or L2 fails early in §1.
- **D-110-05d:** **110-SUMMARY.md must record re-walk status** (FIX_SHA, ladder rung, RUN-01/02/03 matrix, WR confirmation, new finding IDs) — operational requirement beyond ROADMAP criterion #5 (seeds list).
- **D-110-05e:** **Two-layer verification model** (OSS DNA): ExUnit/contract tests = CI gate; maintainer WALKTHROUGH = RUN acceptance. Neither replaces the other.

### Seed deferral authoring (D-110-06)

- **D-110-06a:** Create `.planning/v1.24-seeds/` with **`TEMPLATE.md`** and **`README.md`** index on first deferral.
- **D-110-06b:** **Template shape:** minimal YAML frontmatter + `## Rationale` (one paragraph) + `## When this seed should surface` + `## Source findings` table. Optional `## Breadcrumbs` (≤5 bullets) for model-touching **(d)** gaps only.
- **D-110-06c:** **Numbering:** independent `SEED-001`… sequence in `.planning/v1.24-seeds/` (not `.planning/seeds/` until promotion). Filename: `SEED-NNN-slug.md`. Finding `deferred_to: SEED-NNN` (ID only).
- **D-110-06d:** **Frontmatter keys:** `id`, `slug`, `kind` (`design_gap` | `papercut_deferral`), `status: dormant`, `deferred_from_milestone: v1.23`, `source_findings`, `source_steps`, `deferred_on`, `trigger_when` (one-line for README index).
- **D-110-06e:** **Triage workflow:** process findings in ID order; **(d)** always → seed; over-budget **(b)** → seed with `kind: papercut_deferral`; update finding `status: deferred`; append README row; list in **110-SUMMARY.md § Deferred v1.24 seeds**. Do **not** edit REQUIREMENTS.md v2 during Phase 110 — seeds are v2 intake.
- **D-110-06f:** **Trigger discipline** (Phase 104 / Nyquist DNA): concrete signals (“first sustained real-adopter legal-hold proof request”) not “when we have time.” Drive-by interest → seeds, not override re-engagement.

### Claude's Discretion

- Exact plan split (110-02 vs 110-04) if IN-001 bundling exceeds task budget
- Whether to add `scripts/verify-phase-110-scope.sh` vs inline verification in `110-VERIFICATION.md`
- Optional `(b) budget rubric` subsection in `.planning/v1.23/findings/README.md` mirroring D-110-03a
- Screenshot assets under `findings/assets/` — never required

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contracts & requirements

- `.planning/ROADMAP.md` § Phase 110 — goal, success criteria, scope guard
- `.planning/REQUIREMENTS.md` — FIX-01, FIX-02, FIX-03, DEFER-01; Out of Scope; v2 deferrals (LEGAL-HOLD, COMPLIANCE-PACK)
- `.planning/phases/104-reference-walkthrough-charter-override-decision/104-CONTEXT.md` — synthetic adopter override, v1.24-seeds routing, observe/fix separation
- `.planning/phases/108-walkthrough-script-finding-capture-protocol/108-CONTEXT.md` — WALKTHROUGH architecture, findings protocol, D-108-05 fix-vs-defer
- `.planning/phases/108-walkthrough-script-finding-capture-protocol/108-REVIEW.md` — WR-001, WR-002, IN-001..IN-004 pre-registrations
- `.planning/phases/109-maintainer-walkthrough-dry-run/109-CONTEXT.md` — clean clone, hard gates, WR pre-registration, scope guard proof
- `.planning/phases/109-maintainer-walkthrough-dry-run/109-SUMMARY.md` — finding inventory, RUN partial status, WALK_BASELINE_SHA

### Findings & deferrals (execution surface)

- `.planning/v1.23/findings/README.md` — 4-question classifier + routing table
- `.planning/v1.23/findings/TEMPLATE.md` — finding file format
- `.planning/v1.23/findings/0001-landing-500-badmap.md` — sole filed finding at Phase 110 start
- `.planning/v1.24-seeds/TEMPLATE.md` — create during Phase 110 on first deferral (per D-110-06a)

### Walkthrough & example app

- `examples/threadline_phoenix/WALKTHROUGH.md` — RUN authority; WR-001/002 fix targets
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/page_html.ex` — 0001 fix surface
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — WR-001 contract extension target
- `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` — WR-002 literal lock
- `examples/threadline_phoenix/AGENTS.md` — host-owned `current_scope` guidance

### Vision, OSS DNA, ecosystem lessons

- `prompts/threadline-elixir-oss-dna.md` — named `mix verify.*`, doc contracts, honest tests, deferred validation triggers
- `prompts/audit-lib-domain-model-reference.md` — capture vs semantics vs exploration layers; layer-first `lib/` gate
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — hybrid row+action model; Carbonite/PaperTrail/ExAudit lessons; SIEM operator affordances
- `prompts/THREADLINE-GSD-IDEA.md` — project vision and constraints
- `CLAUDE.md` — domain language, verification entrypoints, three-layer architecture

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **0001 fix:** uncommitted nil-guard already in `page_html.ex` — commit as Wave 1 with finding reference
- **`mix ci.all` / `mix verify.*`:** L1 gate after fixes (root `mix.exs` aliases)
- **`demo_contract_test.exs`:** extend for WR-001 agent2 window semantics (closes IN-004 gap)
- **`walkthrough_doc_contract_test.exs`:** extend for WR-002 CLI literal
- **108-REVIEW stderr/literal evidence:** static repro for 0002/0003 filing without full §4 walk

### Established Patterns

- **Three-wave fix → validate:** unblock §1 → triage known doc gaps with finding files → validation re-walk (K8s runbook: fix blocker → re-run readiness probe)
- **Confirmed pre-registration:** 108-REVIEW → numbered finding + spot-check → fix (release QA: known-issue → tracked defect)
- **ExUnit + maintainer UAT:** contract tests lock literals/seed; WALKTHROUGH proves procedure (WR-001 slipped because layer 2 lacked window describe)
- **Isolated clone at pinned SHA:** Phase 48/109 pattern for `RE_WALK_BASELINE_SHA`
- **v1.24-seeds namespace:** separate from `.planning/seeds/` global strategic seeds (Phase 104 routing)

### Integration Points

- Finding frontmatter `fixed_in` / `deferred_to` ↔ commit SHAs / SEED IDs
- `110-SUMMARY.md` ↔ ROADMAP criterion #5 deferred seed list + RUN matrix
- `110-RE-WALK-LOG.md` ↔ RUN-01/02/03 acceptance attestation
- Phase 110 closeout → v1.23 milestone archive / v1.24 planning intake from `v1.24-seeds/README.md`

</code_context>

<specifics>
## Specific Ideas

- **Kubernetes runbook:** fix the blocking failure, then re-run readiness from step 1 — don't mutate cluster state during audit (Phase 109 observe-only).
- **SIEM detection validation:** labeled test cases (WR-001/002) are tuned in triage phase, not re-run broken during validation re-walk.
- **Stripe test mode:** frozen `demo_epoch` / `demo_last_tuesday` fiction — WR-001 fixes prose to match seed, not vice versa.
- **Carbonite vs host app:** library trigger/query vs example landing/auth — 0001 is host wiring, not capture bug.
- **PaperTrail footgun:** app-layer versioning misses writes if developers skip API — Threadline's walkthrough exists precisely because CI substring tests ≠ procedure semantics.
- **Nyquist / validation debt:** deferred seeds need `trigger_when` + pointer — never silent drops (OSS DNA).

### Coherent execution playbook (one-shot)

1. **110-01:** Commit 0001 fix → L0 + L1 → update finding 0001.
2. **110-02:** File 0002/0003 from 108-REVIEW + spot-check → fix WALKTHROUGH + contract tests + IN-001 voice → L0 + L1 → update findings.
3. **110-03:** Isolated clone at post-110-02 SHA → `110-RE-WALK-LOG.md` WALK-01-04→§5 → file new findings only → fix if any **(a)** → optional L3.
4. **110-SUMMARY:** all findings fixed/deferred; deferred seeds table; RUN matrix; `lib/` commit audit (expect zero for current inventory).

</specifics>

<deferred>
## Deferred Ideas

- **Full containerized walk (app + db in compose)** — v1.24 seed if validation re-walk surfaces integrator demand
- **`mix verify.phase_110_scope` alias** — optional if verification script reused across milestones
- **Generous (b) papercut sweep** — batch all 108-REVIEW infos in one plan (rejected — scope creep vector)
- **Pre-fix WR before 0001** — rejected; §1 gate narrative must stay honest
- **Second observe-only Phase 109 pass** — rejected; use validation re-walk instead

### Reviewed Todos (not folded)

(none — `todo.match-phase` unavailable; no pending todos matched)

</deferred>

---

*Phase: 110-triage-narrow-fixes*
*Context gathered: 2026-05-27*
